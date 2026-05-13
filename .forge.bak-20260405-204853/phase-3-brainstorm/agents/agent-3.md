# Agent 3: The Skeptic -- Risk Analysis & Failure Modes

## 1. Step Placement

### Risk Analysis

The proposed placement (5a / 4b-tracker / 3b-tracker -- between decomposition decision and execution loop) looks clean on paper but has several hidden failure modes.

**MCP server latency and downtime.** The MCP server is a remote dependency. If the server is slow or temporarily unavailable at exactly this step, the user has already approved the decomposition plan and is waiting for execution to start. The pipeline hangs at a point where the user's mental model says "my plan was approved, code should be writing now." There is no progress indicator built into the MCP call -- each subtask creation is a synchronous blocking call via the Task tool.

Worse: the pipeline already verified MCP at Step 0 (mcp-preflight). If the MCP server goes down between preflight and this new step, the user gets a confusing failure after an earlier success signal. The time gap between Step 0 and this new step could be 5-15 minutes (triage + code-analyst + architect + user approval), which is plenty of time for a flaky connection to drop.

**Race conditions with parallel worktrees (fix-bugs).** The research decisions assume this step runs per-bug in fix-bugs. In worktree mode (Variant A), multiple bugs can reach the decomposition step simultaneously. Each bug creates subtask issues under its own parent, so there is no direct conflict. But the `tracker_effective_status` gate is a pipeline-wide variable -- if one worktree's MCP call fails and triggers a "tracker unavailable" condition, it could affect the shared state assumption. The current architecture evaluates `tracker_effective_status` once at Step 0. If the MCP server goes down mid-batch, some worktrees succeed and some fail, creating an inconsistent batch state. The accumulator pattern handles this at the individual level, but the user sees a confusing mix.

**YOLO mode interaction.** In YOLO mode, the decomposition plan is auto-approved. The user expects zero interaction. But if subtask creation partially fails (3 of 5 created), the WARN-and-continue policy means the pipeline proceeds. Later, when the user looks at the tracker, some subtasks have issues and some do not. In YOLO mode, this discrepancy is never surfaced to the user until they happen to look. This is a silent data quality problem.

**Resume-ticket gap.** The DECOMPOSE_PARTIAL checkpoint in resume-ticket reads `.claude/decomposition/{ISSUE-ID}.yaml` and continues from the next unfinished subtask. But if the pipeline failed between "approve decomposition" and "finish tracker creation step" (say 2 of 5 issues created), the resume needs to handle two concerns: (a) continue creating tracker issues for subtasks 3-5, and (b) continue executing subtasks. The current resume logic has no concept of a "tracker creation" checkpoint -- it goes straight to subtask execution. The new step needs its own resume awareness, or tracker issues for subtasks 3-5 will never be created.

### Recommended Approach

The proposed placement is correct, but add:
1. A timeout per MCP call (5 seconds per subtask issue creation, matching scaffold's pattern).
2. A specific resume checkpoint field in state.json: `decomposition.tracker_creation_status` with values `pending | in_progress | completed | partial`. On resume, if this field is `in_progress` or `partial`, re-run the tracker creation step before entering the execution loop.
3. In YOLO mode, display a summary after tracker creation: `"Created {N}/{M} tracker sub-issues."` even though we do not pause for confirmation.

### Rating
| Dimension | Score |
|-----------|-------|
| Simplicity | 3/5 |
| Consistency | 4/5 |
| UX | 3/5 |
| Maintainability | 3/5 |

**Biggest risk:** Resume-ticket does not know about the new "tracker creation" phase, causing orphaned subtasks (some with tracker issues, some without) after a crash during this step.

---

## 2. GitHub/Gitea Checklist (Parent Issue Body)

### Risk Analysis

The decision to use a checklist in the parent issue body for GitHub/Gitea is pragmatically correct (no native sub-issues), but the implementation is where things break.

**Malformed parent issue body.** The step needs to read the parent issue body, append a markdown checklist, and write it back. What if the body already contains a checklist? What if the body is empty? What if the body uses HTML instead of markdown? The "read-modify-write" pattern on a free-form text field is inherently fragile. The step must either append at the end (risking visual confusion with existing content) or insert at a known anchor point (requiring the body to have a specific structure it may not have).

**Concurrent edits (TOCTOU).** Between reading the body and writing it back, another process (or a human) may edit the issue. This is a classic time-of-check-time-of-use race. MCP servers do not provide atomic compare-and-swap on issue bodies. The last write wins. If a human is editing the issue description at the same time (adding notes, clarifying requirements), the pipeline could overwrite their changes.

For fix-bugs with parallel worktrees: if two bugs share the same parent issue (unlikely but possible in certain tracker configurations), both worktrees could try to update the same issue body simultaneously.

**Body size limits.** GitHub has a 65,536 character limit on issue bodies. Gitea also has limits (configurable, default 1MB). For a decomposition with 7 subtasks, each checklist line is approximately 50-100 characters -- this is negligible. But the read-modify-write pattern means the pipeline reads the entire body. If the body is already large (detailed spec, screenshots, embedded images), the MCP call to update could fail silently or truncate content.

**Checklist format ambiguity.** The research says: `- [ ] [{subtask_title}](#{issue_url_or_number})`. But what does `issue_url_or_number` refer to? If we create standalone issues for each subtask (GitHub/Gitea fallback), we have issue numbers. But wait -- we are creating the checklist BEFORE the subtask issues exist? Or are we creating subtask issues as standalone issues AND adding them to the checklist? The research decision says the subtasks are "ephemeral execution steps, not independent work items" (RQ-2), which contradicts creating standalone issues. The checklist approach means:
- Option A: Checklist items are plain text (no linked issues). Simple, but no navigation to actual tracker issues.
- Option B: Create standalone issues AND add them to the checklist. Doubles the complexity and reverses the "ephemeral" design intent.

This ambiguity is unresolved. The research says "use checklist in parent issue" but the scaffold Step 4e creates standalone issues for GitHub/Gitea. The decomposition flow needs to pick one.

**Idempotency on checklists.** If we append a checklist and then the pipeline resumes, how do we know the checklist was already appended? The YAML-first approach (RQ-3) stores `tracker_issue_id` in the YAML. But for a checklist, there is no issue ID to store -- it is text in a body. We would need a sentinel marker in the body (e.g., `<!-- ceos-agents:decomposition-checklist -->`) to detect prior insertion. This deviates from the YAML-first approach and introduces a second idempotency mechanism.

### Recommended Approach

For GitHub/Gitea, use Option A: plain-text checklist in parent issue body, no standalone subtask issues. Mark the section with a sentinel HTML comment for idempotency. Store `tracker_issue_id: "checklist"` (a sentinel value, not a real ID) in the YAML to indicate the checklist was created. Accept that GitHub/Gitea gets a degraded experience compared to YouTrack/Jira/Linear.

Specifically:
1. Read parent issue body.
2. Check for `<!-- ceos-agents:decomposition -->` sentinel. If present, skip.
3. Append the checklist block (with sentinel) at the end of the body.
4. Write the body back.
5. Store `tracker_issue_id: "checklist-appended"` in YAML for each subtask.

Do NOT attempt concurrent-edit protection. Document that the pipeline may overwrite concurrent human edits. This is acceptable because (a) it is rare, (b) the pipeline adds content, it does not remove content, and (c) the alternative (locking) is not supported by any MCP server.

### Rating
| Dimension | Score |
|-----------|-------|
| Simplicity | 2/5 |
| Consistency | 3/5 |
| UX | 3/5 |
| Maintainability | 2/5 |

**Biggest risk:** Read-modify-write race on the issue body overwrites concurrent human edits, causing data loss. No MCP server provides atomic compare-and-swap.

---

## 3. Shared Pattern vs Inline

### Risk Analysis

The research mentions extracting a shared pattern (similar to `core/block-handler.md` or `core/fixer-reviewer-loop.md`). The question is whether this step should be a new `core/tracker-subtask-creator.md` or inline in each of the 3 skills.

**Case for shared pattern (core/ file):**
- Three skills (implement-feature, fix-ticket, fix-bugs) need identical logic.
- The scaffold Step 4e is similar but not identical (it creates epics + stories, not decomposition subtasks).
- A shared pattern avoids triple maintenance.

**Risks of shared pattern:**
- **Coupling.** The three skills currently have no shared tracker-creation pattern. Adding one creates a dependency. If the shared pattern changes (e.g., adding a new parameter), all three skills must be updated. But they reference it, not include it -- the LLM re-reads the pattern each invocation. So the coupling is at the document level, not code level. This is acceptable.
- **Over-abstraction.** The scaffold Step 4e handles epics and stories with complex hierarchy. The decomposition flow handles flat subtasks with a parent. These are different enough that a shared pattern trying to cover both would become over-general. The risk is a pattern that is too abstract to be useful, requiring each skill to pass 15 parameters.
- **Drift.** If scaffold Step 4e evolves independently (e.g., adding label support, story point estimation), the shared pattern may not track those changes. We end up with two tracker-creation patterns: one for scaffold (inline) and one for decomposition (shared). This is arguably worse than having the decomposition logic inline in each skill.

**Risks of inline:**
- **Triple maintenance.** Any bug in the tracker creation logic must be fixed in 3 places. History shows this plugin has had sync issues between fix-ticket and fix-bugs before (they are structurally similar but separately maintained).
- **Inconsistency.** Over time, someone patches one skill and forgets the other two. The three skills diverge in how they create tracker issues.

**The real question: how much logic is there?** If the tracker creation step is 15-20 lines of pseudocode (iterate subtasks, call MCP, handle failure, write YAML), inlining is fine -- the duplication cost is low. If it is 50+ lines with complex error handling, GitHub/Gitea checklist fallback, Jira sub-task detection, and idempotency -- shared pattern wins.

Based on the scaffold Step 4e (which is approximately 50 lines of spec text with the accumulator pattern, per-tracker parent parameter table, idempotency guards, back-reference writing, and partial failure handling), the decomposition version will be at least 30-40 lines. That is above my threshold for inlining.

### Recommended Approach

Create `core/tracker-subtask-creator.md` as a shared pattern. It handles ONLY decomposition subtask creation (not scaffold epics/stories). It takes a narrow input contract:
- Parent issue ID
- Subtask list (from YAML)
- Tracker type
- Tracker capabilities (from `docs/reference/trackers.md` Sub-Issue Capabilities table)

Each skill references the pattern with `Follow core/tracker-subtask-creator.md`.

But do NOT try to merge this with scaffold Step 4e. They serve different purposes. Accept that there are two tracker-creation flows: one for scaffold (hierarchical epics/stories) and one for decomposition (flat subtasks under a parent). Trying to unify them would create an over-abstracted monster.

### Rating
| Dimension | Score |
|-----------|-------|
| Simplicity | 3/5 |
| Consistency | 5/5 |
| UX | 4/5 |
| Maintainability | 4/5 |

**Biggest risk:** The shared pattern and scaffold Step 4e drift apart over time, creating two subtly different tracker-creation implementations that confuse future maintainers.

---

## 4. Idempotency

### Risk Analysis

The YAML-first approach (write `tracker_issue_id` to YAML immediately after each creation, check on resume) sounds robust. But there are several edge cases.

**Write succeeds, creation did not actually happen.** MCP servers return a response, but what if the response indicates success while the tracker actually had a transient failure? This is unlikely but possible with eventual consistency (e.g., Linear uses a async event-driven architecture). The YAML would contain a `tracker_issue_id` that refers to a non-existent issue. On resume, the idempotency guard says "already created" and skips it. The subtask has a phantom tracker issue forever.

Mitigation: The lightweight verification (RQ-13, MCP return check only) is correct. Do not add read-back verification -- the cost-benefit ratio is poor. Accept the phantom issue risk as extremely unlikely. If it happens, the user can manually fix it.

**Stale `tracker_issue_id` after issue deletion.** A user or admin deletes the tracker issue manually (maybe it was a test, maybe they cleaned up). The YAML still has the `tracker_issue_id`. The pipeline thinks it exists. This is a permanent ghost reference. There is no mechanism to detect this because we explicitly decided against tracker-side queries for idempotency (RQ-3).

This is acceptable for the same reason: the YAML is the source of truth for the pipeline's internal state. If a user deletes tracker issues externally, they are stepping outside the pipeline's domain. We cannot and should not protect against this.

**Partial write scenario.** The research says "write `tracker_issue_id` into YAML immediately after each successful creation." But RQ-11 says "single commit after the entire creation loop completes." What if we create issues 1-3, write them to YAML, crash before creating issue 4, and the YAML was never committed? On resume, the YAML file on disk has issues 1-3 marked with `tracker_issue_id`, but the git state may have reverted (depending on what happened).

Wait -- the YAML file is uncommitted at this point. If the pipeline crashes and the user runs `git checkout .` or `git clean` before resuming, the in-progress YAML is lost. The committed YAML (from the decomposition approval step) has all `tracker_issue_id: null`. On resume, all subtask issues would be recreated as duplicates.

This is a real risk. The mitigation is:
1. The resume-ticket flow reads the on-disk YAML first (not the committed YAML). If the file exists and has tracker_issue_ids, respect them.
2. But `git stash` or `git checkout .` (common user reactions to a failed pipeline) would destroy the uncommitted YAML changes.
3. The state.json dual-write (RQ-5) provides a backup. Even if the YAML is reverted, state.json (in `.ceos-agents/`) is not under git and would survive. But state.json is also a non-committed file that could be manually deleted.

**Eventual consistency in tracker APIs.** Most trackers (YouTrack, Jira, GitHub, Gitea) are strongly consistent for their REST APIs -- a successful create returns immediately and subsequent reads reflect it. Linear is the exception (GraphQL mutations may have eventual consistency). However, since we are not doing read-back verification (RQ-13), this does not matter. We trust the MCP return value.

### Recommended Approach

The YAML-first approach is correct, but add one safety net:
1. After each successful subtask issue creation, write `tracker_issue_id` to BOTH the YAML file AND state.json immediately (not just YAML). This is the RQ-5 dual-write.
2. On resume, check state.json FIRST (since it survives `git checkout .`), then fall back to YAML.
3. If state.json says issue was created but YAML does not (user reverted git), trust state.json and re-populate the YAML from state.json data.

This reverses the priority from "YAML-first" to "state.json as authoritative backup." The YAML is for human readability and git history; state.json is for machine-reliable resume.

Document clearly: "If you `git clean -fd` AND delete `.ceos-agents/`, tracker issues for already-created subtasks will be recreated as duplicates on resume. This is an unrecoverable scenario."

### Rating
| Dimension | Score |
|-----------|-------|
| Simplicity | 3/5 |
| Consistency | 4/5 |
| UX | 3/5 |
| Maintainability | 3/5 |

**Biggest risk:** User runs `git checkout .` after a crash, destroying uncommitted YAML with tracker_issue_ids. Resume creates duplicate tracker issues. State.json is the only defense, and it can also be deleted.

---

## 5. Config Key

### Risk Analysis

The decision: `Create tracker subtasks` | Default: `enabled` | Values: `enabled`, `disabled`.

**Upgrading from v6.3.x to v6.4.0.** Users who have never seen this config key will suddenly get new behavior: decomposition creates tracker issues. This is a behavioral change on upgrade. The research argues this is safe because the feature is gated by `tracker_effective_status == "ready"` -- projects without tracker integration are unaffected. This is true, but projects WITH tracker integration get unsolicited new issues in their tracker.

Consider: a team using ceos-agents with YouTrack upgrades from v6.3.3 to v6.4.0. They run `implement-feature` with decomposition. Previously, decomposition was a local-only operation. Now, 5 new YouTrack issues appear under the parent. Some teams would welcome this. Others would be confused: "Where did these issues come from? Who created them? Are they duplicates of the parent?"

The CHANGELOG documentation (RQ-6) mitigates this, but only if users read the CHANGELOG. Most users do not.

**`enabled` but no tracker configured.** The gating on `tracker_effective_status == "ready"` handles this cleanly. If there is no tracker, the step is skipped. But what about partial configurations? A user has a tracker configured for reading (queries work) but no write permissions. The MCP preflight (Step 0) checks read access. The write canary in `core/mcp-preflight.md` is mentioned but the research says "no separate write check needed" (RQ-14). So the pipeline reaches the tracker creation step, tries to create an issue, fails, and logs a WARN. First issue creation fails, second fails, all fail. The user sees "Created 0/5 tracker sub-issues (5 failures)." This is technically handled by the accumulator, but the UX is poor -- the pipeline spent time attempting 5 doomed MCP calls.

**The `disabled` value is not discoverable.** A user who does not want this feature must know to add `| Create tracker subtasks | disabled |` to their Automation Config. Unless they read the CHANGELOG or reference docs, they will not know this key exists. The feature activates silently.

### Recommended Approach

Change the default to `disabled` for the initial release (v6.4.0). This is a departure from the research decision (RQ-6) but is safer for upgrades:
- Users who want the feature explicitly opt in: `| Create tracker subtasks | enabled |`
- No surprise tracker issues on upgrade
- The feature is documented in CHANGELOG as "new optional feature" rather than "new default behavior"

I know this contradicts the existing convention ("every optional key defaults to the active behavior"). But the existing convention applies to keys that enhance analysis or gating (pipeline profiles, browser verification, acceptance gate thresholds). Those features add checks and quality gates -- they never create new external artifacts. Creating tracker issues is a write operation with external side effects. The convention should not apply blindly.

If the team insists on `enabled` as default (to match convention), then at minimum: the first time the step runs for a project, display a one-time notice: `"[ceos-agents v6.4.0] Decomposition now creates tracker sub-issues. To disable: add '| Create tracker subtasks | disabled |' to your Automation Config."` And respect `--dry-run` -- never create tracker issues in dry-run mode.

### Rating (with `disabled` default)
| Dimension | Score |
|-----------|-------|
| Simplicity | 4/5 |
| Consistency | 3/5 |
| UX | 4/5 |
| Maintainability | 4/5 |

### Rating (with `enabled` default, per research decision)
| Dimension | Score |
|-----------|-------|
| Simplicity | 4/5 |
| Consistency | 5/5 |
| UX | 2/5 |
| Maintainability | 4/5 |

**Biggest risk:** Users upgrading from v6.3.x to v6.4.0 get unsolicited tracker issues in their issue tracker with no opt-in. This damages trust in the automation pipeline.

---

## 6. Partial Failure

### Risk Analysis

The decision: WARN-and-continue with accumulator pattern, matching scaffold Step 4e.

**ALL subtask creations fail.** The accumulator displays "Created 0/5 tracker sub-issues (5 failures)." The pipeline continues to the execution loop. All subtasks execute locally without tracker issues. At the end, the PR is created. The parent issue has no visibility into what subtasks were done. This is functionally identical to v6.3.x behavior (no tracker issues), so it is not a regression. But the user requested this feature, saw it try and fail 5 times, and got no value. The pipeline wasted time and generated 5 warnings.

Should 100% failure escalate to BLOCK? Consider: if ALL creations fail, the likely cause is systemic (MCP server down, write permissions revoked, rate limiting). The failures are not random -- they are correlated. Continuing the pipeline will not fix the tracker issue. The user should be informed that something is fundamentally wrong.

But blocking is also wrong. The tracker issue creation is a visibility feature, not a functional prerequisite. The code can still be written, reviewed, tested, and published without tracker issues. Blocking on a visibility feature would be hostile.

**Rate limiting.** YouTrack and Jira both have API rate limits. Creating 7 issues in rapid succession (one per subtask) could trigger rate limiting. The MCP server may return HTTP 429. The accumulator treats this as a per-issue failure. But the first failure could predict all subsequent failures. Creating 7 individual MCP calls with no backoff means 7 rate-limit errors in a row, wasting time and potentially triggering a longer cooldown.

**Webhook interaction.** The research does not mention firing a webhook on tracker creation failure. But the block-handler fires a webhook on `issue-blocked`. If tracker creation partially fails (3/5), should a webhook be fired? Currently, no -- the step does not block. But a monitoring system would want to know. This is a missing notification path.

**GitHub/Gitea checklist failure.** For GitHub/Gitea, the "creation" is a single operation (update parent issue body with checklist). If this single operation fails, the result is "Created 0/5 tracker sub-issues (1 failure)" -- misleading, because it was one API call, not 5. The accumulator message assumes per-subtask granularity that does not apply to the checklist approach.

### Recommended Approach

Use WARN-and-continue for individual failures, but add a threshold escalation:
1. Individual failure: log WARN, continue to next subtask. (Matches scaffold Step 4e.)
2. After all attempts complete: if `failures == total` (100% failure rate), escalate to a prominent warning (not BLOCK):
   ```
   [ceos-agents] All {N} tracker sub-issue creations failed.
   Likely cause: tracker write access unavailable or rate-limited.
   Pipeline continues without tracker sub-issues.
   To retry later: run /ceos-agents:resume-ticket {ISSUE-ID}
   ```
3. Never BLOCK on tracker creation failure. The execution loop is the core value; tracker issues are supplementary.
4. For GitHub/Gitea checklist: treat the single update operation as one atomic action. Display "Checklist update: {succeeded|failed}" instead of "Created N/M."
5. Add a brief delay between MCP calls (200ms) to reduce rate-limiting risk. This adds 1-2 seconds total for a 7-subtask decomposition -- negligible.

### Rating
| Dimension | Score |
|-----------|-------|
| Simplicity | 4/5 |
| Consistency | 4/5 |
| UX | 4/5 |
| Maintainability | 4/5 |

**Biggest risk:** Rate limiting from the tracker API causes all creations to fail, and the pipeline continues as if nothing happened. The user does not realize their tracker integration is misconfigured until they look at the tracker and find no subtasks.

---

## Cross-Cutting Concerns

### Field Name Decision

The research identifies the `tracker_id` vs `tracker_issue_id` naming conflict. This is a spec-phase decision, but my strong recommendation: use `tracker_issue_id`. The existing `tracker_id` references in Redmine context (11 hits in the codebase) refer to the issue TYPE (Bug=1, Feature=2), not to an issue's unique identifier. Using `tracker_id` for a subtask's issue identifier would create a semantic collision that will confuse anyone reading the YAML or state.json. The roadmap entry (line 447) predates this analysis and should be corrected.

### Test Coverage Gap

None of the 6 areas above address testing. The existing test harness (`tests/`) validates skill definitions and agent definitions via regex/structure checks. But there is no mechanism to test the MCP interaction (creating issues, updating bodies). The new feature is entirely MCP-dependent. If someone breaks the MCP call format in a future edit, no test will catch it. This is a pre-existing gap, not specific to this feature, but it becomes more critical because this feature adds write operations.

### Dry-Run Mode

The research does not address how `--dry-run` interacts with tracker creation. Fix-ticket and implement-feature both have dry-run modes that stop before side effects. The tracker creation step must also be skipped in dry-run mode. This is obvious but must be explicitly stated in the spec.

### Decomposition YAML Schema Change

Adding `tracker_issue_id` to the subtask schema changes the YAML format. Existing YAML files from v6.3.x decompositions will not have this field. The resume flow must handle `tracker_issue_id` being absent (treat as null) -- this is the default `null` value specified in RQ-3. But the state.json schema (state/schema.md) needs to be updated to document the new field. This is a MINOR version bump because it is additive (new optional field).
