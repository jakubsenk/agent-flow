# Devil's Advocate Review: Scaffold Infrastructure Integration

**Reviewer:** Devil's Advocate (adversarial failure analysis)
**Target:** `commands/scaffold.md` (Steps 0-INFRA, 0-MCP, 4, 4d, 4e, Final Report)
**Design doc:** `docs/plans/2026-03-27-scaffold-infrastructure-design.md`

---

## Scenario 1: User Says tracker=ready but Provides Wrong Credentials

### Failure Path

1. **Step 0-INFRA:** User selects tracker = "ready", provides type `youtrack`, instance `https://mycompany.youtrack.cloud`, project `PROJ`. All stored as in-memory variables. No validation here — this is purely data collection. `tracker_effective_status = "ready"`.

2. **Step 0-MCP:** The command scans for `mcp__*` tools matching the expected package (`@vitalyostanin/youtrack-mcp`). Suppose the MCP server IS configured in the session (globally or project-level) — so step 2 passes. Then step 4 fires: "attempt to list issues from declared project (1 result)." Here the credentials matter.

   **Sub-case A: MCP server exists but token is for a different instance/project.** The query targets `PROJ` at `mycompany.youtrack.cloud` but the token belongs to `othercompany.youtrack.cloud`. The MCP call will fail (401/403 or project-not-found). Step 0-MCP handles this: "FAIL -> same downgrade prompt as step 3." User gets the offer: `Continue without tracker? [Y/n/Abort]`. If Y, `tracker_effective_status = "downgraded"`. Pipeline continues safely.

   **Sub-case B: MCP server exists, token is valid for the right instance, but project key is wrong (e.g., `PROJJ` typo).** The query "list issues from declared project" will fail (project not found). Same handling as Sub-case A.

   **Sub-case C: MCP server exists, token works, project exists, but the user has read-only access (no issue creation permission).** The Step 0-MCP connectivity check is "query 1 issue" — which is a READ operation. This **will succeed**. The system records `tracker_effective_status = "ready"`. Later at Step 4e, when the command tries to CREATE issues, the MCP call will fail with a 403/permission error.

### Does the Implementation Handle It?

- Sub-cases A and B: **Yes.** Step 0-MCP connectivity check catches these and offers downgrade.
- Sub-case C (read-only permissions): **Partially.** Step 4e has a partial failure accumulator pattern (lines 422-431 of scaffold.md): individual epic failures are logged as WARN and the pipeline continues. So the scaffold won't crash. But the user gets `Created 0/5 tracker issues` without a clear explanation that the root cause is insufficient permissions — the error message will be whatever the MCP server returns, which may be cryptic.

### Missing: No Write-Permission Pre-Flight

The connectivity check at Step 0-MCP only tests READ access. There is no "canary write" (e.g., create a test issue and immediately delete it) to verify CREATE permissions before reaching Step 4e, which may be 10-30 minutes into the scaffold.

### Severity: P2

The pipeline does not crash — Step 4e gracefully degrades. But the user wastes significant time believing tracker integration will work, only to find at Step 4e that all issue creation fails. A P2 because the data loss is zero (spec files are fine, code is fine) and the user can create issues manually later, but the UX is poor.

### Recommendation

Add an optional write-permission check to Step 0-MCP step 4 for tracker: after the read query succeeds, attempt to create a test issue (title: `[ceos-agents] connectivity test`, immediately close/delete it). If creation fails, warn the user about insufficient permissions at the point where they can still make an informed decision.

---

## Scenario 2: Crash Between Step 4d (Push) and Step 4e (Create Issues)

### Failure Path

1. **Step 4c:** Git init + commit succeeds. The repository has `spec/`, CLAUDE.md, skeleton code, all committed.
2. **Step 4d:** Push to remote succeeds. Code is now on the remote repository. `state.json` is updated.
3. **CRASH** — session terminates (network drop, OOM, user Ctrl+C, Claude Code timeout).
4. **Step 4e never runs.** No tracker issues are created. Spec files have no issue ID references.

### Is This Recoverable?

**State analysis at crash point:**
- Remote repo: has full scaffold (spec, code, CLAUDE.md with auto-filled config)
- Local repo: identical to remote (push succeeded)
- Tracker: zero issues — completely empty
- `state.json`: last write was during Step 4c or 4d. The top-level `status` is `"running"`.
- `spec/epics/*.md`: exist but have no issue ID reference comments

**Recovery via `/resume-ticket`:** The `/resume-ticket` command reads `state.json` and finds the first step with status `"in_progress"` or `"pending"` after all `"completed"` steps. But scaffold.md does NOT write a state.json entry specifically for Step 4d or Step 4e. Looking at the state updates in scaffold.md:

- Step 0: `status: "running"`, `pipeline: "scaffold"`
- Step 1: `triage.status = "completed"` (reused for spec phase)
- Step 3: `code_analysis.status = "completed"` (reused for scaffolder)
- Step 5: `decomposition.status = "completed"`
- Step 7: `fixer_reviewer.*` and `test.*` updates per subtask
- Step 9: `status = "completed"`

**There is no `state.json` field for Steps 4, 4d, or 4e.** The resume logic has no way to know that Step 4d completed but Step 4e did not. If the user re-runs `/scaffold`, State Detection (line 42-47) will see "Existing project with CLAUDE.md" and offer `/implement-feature` instead — which is wrong because the tracker issues were never created.

### Does the Implementation Handle It?

**No.** There is no recovery path for this specific gap. The user would need to:
1. Manually create tracker issues from spec/epics files
2. Manually write issue ID references back into spec files
3. Or delete everything and re-scaffold (losing any customization)

### Severity: P1

This is a data consistency issue. The remote repo exists, the code is pushed, but the project management layer (tracker) is completely disconnected from the specification. The spec/epics files — the "single source of truth" per CLAUDE.md line 704 — are missing their tracker links. Any subsequent `/implement-feature --issue` call requires tracker issues that don't exist.

The probability is moderate (crashes do happen, especially in long-running scaffold pipelines with Full YOLO mode), and the manual recovery is tedious (recreating all epic/sub-issue hierarchies by hand).

### Recommendation

1. **Add state tracking for Steps 4d and 4e.** Write `push.status` and `tracker_issues.status` fields to state.json at the start and end of these steps. This enables resume-ticket to detect the gap.
2. **Add a standalone recovery command or flag.** Something like `/scaffold --link-issues` that reads existing spec/epics, creates tracker issues, and writes the references back. This would also be useful for the `later -> ready` upgrade path.
3. **Alternative: reorder 4e before 4d.** Create tracker issues (local operation via MCP) before pushing. If 4e succeeds and 4d crashes, the issues exist and spec files have references; re-pushing is trivial. If 4e fails and 4d never runs, the user has spec files without links but hasn't pushed yet — cleaner state.

---

## Scenario 3: --issue Flag with MCP Server Not Configured

### Failure Path

1. User runs: `/scaffold --issue PROJ-42`
2. **Flag Parsing:** `issue_id = "PROJ-42"`, no description provided.
3. **Step 0-INFRA:** The `--issue` flag triggers auto-set: `tracker_effective_status = "ready"`. The tracker question is skipped. Only the SC question is asked. BUT: the tracker type, instance, and project key are NOT collected via interactive prompts because the `--issue` flag auto-skips the tracker question.

   **Problem:** The `--issue` auto-set at line 66 says "Auto-set tracker = ready" and "Skip the tracker question." But the tracker details (type, instance URL, project key) are collected ONLY when tracker = "ready" (lines 68-71). If the tracker question is skipped entirely, these details are never collected.

   Wait — re-reading more carefully: line 66 says "Skip the tracker question" (the (a)/(b) choice), but lines 68-71 say "If tracker = ready: Collect details." The `--issue` flag sets tracker to "ready", so the detail collection at lines 68-71 SHOULD still run. The skip only applies to the (a)/(b) binary choice, not the detail collection.

   **Assumption:** Detail collection runs. User provides: type = `gitea`, instance = `gitea.internal`, project = `myproject`.

4. **Step 0-MCP:** Checks for MCP server matching `forgejo-mcp`. Scanner finds NO `mcp__*` tools matching this package — the MCP server is not configured in the current session.

5. **Step 0-MCP step 3:** "MCP server for gitea not detected in current session." Offers: `Continue without tracker? [Y/n/Abort]`.

6. **If user selects Y (continue without):** `tracker_effective_status = "downgraded"`.

7. **Now Step 0-MCP step 5 fires:** "If `--issue` flag was provided and tracker MCP verification fails:" — sets `tracker_effective_status = "downgraded"`, discards the `--issue` input source, falls back to asking for a project description.

8. **Step 1:** No `--issue` input source, no `--spec`, no `--template`, no description. The fallback at line 35-36 kicks in: "If no project description AND no --spec AND no --template AND no --issue AND not --no-implement: Ask user for project description."

### Does the Implementation Handle It?

**Yes, but with a confusing UX.** The implementation correctly handles the technical failure path: MCP not available -> downgrade -> discard --issue -> fall back to description prompt. The user gets a working scaffold.

However, there is an ordering ambiguity between Step 0-MCP step 3 (generic downgrade prompt) and Step 0-MCP step 5 (--issue-specific fallback). Step 3 fires first (it iterates over all "ready" services). When step 3 downgrades the tracker, step 5's condition "tracker MCP verification fails" is already true. The user sees TWO prompts about the same failure:
- First: "MCP server for gitea not detected. Continue without tracker? [Y/n/Abort]"
- Then: "Could not reach tracker to fetch issue PROJ-42. Please describe your project instead."

This is redundant but not harmful.

**More concerning: Full YOLO mode.** In YOLO mode, step 3 auto-downgrades without prompt. Step 5 then fires and discards `--issue`. The user explicitly passed `--issue PROJ-42` expecting to scaffold from that issue, and the system silently discards it with only a display message. In YOLO mode, the user may not see the message before the pipeline continues. The system proceeds to ask for a project description — but in Full YOLO mode, there is no interactive prompt. So we hit the condition at line 35-36: no description, no --issue (discarded), no --spec, no --template. The system asks for a project description, but YOLO mode is supposed to minimize stops.

### Severity: P1

In YOLO mode specifically, the `--issue` discard creates a dead-end: the system needs a project description but YOLO mode discourages interactive prompts. The implementation does say "Ask user for project description" (line 36), which would work even in YOLO mode (it's a missing required input, not a quality gate). But the user experience is poor — they typed `--issue PROJ-42` expecting automation and instead get asked to type a description.

In Interactive/checkpoint modes, severity is P2 (confusing double-prompt but functional).

### Recommendation

1. **Consolidate the --issue MCP failure into a single user-facing message.** If `--issue` is provided and tracker MCP is unavailable, skip the generic downgrade prompt (step 3) and go directly to the --issue-specific fallback (step 5). One message instead of two.
2. **For YOLO mode with --issue and no MCP:** Consider blocking with a clear error instead of silently downgrading: "Cannot scaffold from --issue PROJ-42: tracker MCP server not available. Configure the MCP server and retry, or run without --issue." This respects the user's explicit intent.

---

## Additional Checks

### Step Ordering Dependencies

| Dependency | Validated? | Risk |
|---|---|---|
| Step 0-INFRA must run before Step 0-MCP | Yes — text says "Runs immediately after Step 0-INFRA" and lists required in-memory values | Low |
| Step 0-MCP must complete before Step 0 (Mode Selection) | Yes — "Moves after Step 0-INFRA and Step 0-MCP" per design doc | Low |
| Step 4 depends on in-memory values from Step 0-INFRA | Yes — "Required in-memory values" block present (line 363) | Low |
| Step 4d depends on Step 4c (git init + commit) | **Implicit only.** Step 4d runs `git remote add origin` and `git push`, which require a git repo. Step 4c runs `git init`. No explicit "Required: Step 4c completed" guard. If Step 4c fails (e.g., `git add .` on an empty directory), Step 4d would fail with a confusing git error. | **Medium risk** |
| Step 4e depends on spec/epics/ existing | Yes — guard clause at line 412: "spec/epics/ directory does not exist or is empty" | Low |
| Step 5 depends on spec/epics/ AND skeleton code | Implicit — no guard clause. If Step 3 (skeleton) was skipped or failed and cleanup removed files, Step 5 would attempt to read spec/epics and format specs against a non-existent codebase | **Medium risk** |

### "Required in-memory values" Block Audit

| Consumption Point | Block Present? | Values Listed | Gap? |
|---|---|---|---|
| Step 0-MCP (line 104) | Yes | `tracker_type`, `tracker_instance`, `tracker_effective_status`, `sc_effective_status` | Missing: `tracker_project` — needed for connectivity check "list issues from declared project" |
| Step 4 (line 363) | Yes | All 7 variables | No gap |
| Step 4d (line 389) | Yes | `sc_remote`, `sc_base_branch`, `sc_effective_status` | No gap |
| Step 4e (line 406) | Yes | `tracker_type`, `tracker_instance`, `tracker_project`, `tracker_effective_status` | No gap |
| Step L5b (line 214) | Yes | `sc_remote`, `sc_base_branch`, `sc_effective_status` | No gap |
| Step L6 (line 229) | Yes | `tracker_effective_status`, `sc_effective_status`, `sc_remote` | No gap |
| Final Report (line 610) | Yes | `tracker_type`, `tracker_instance`, `tracker_project`, `sc_remote`, `tracker_effective_status`, `sc_effective_status` | No gap |

**Finding:** Step 0-MCP's "Required in-memory values" block (line 104) lists `tracker_type`, `tracker_instance`, `tracker_effective_status`, `sc_effective_status` but does NOT list `tracker_project`. However, Step 0-MCP step 4 says "attempt to list issues from declared project (1 result)" — which requires the project key. The value IS collected at Step 0-INFRA (line 83) and stored in-memory, so it IS available. The omission from the "Required" documentation block is a documentation bug, not a functional bug. **Severity: P2 (documentation).**

### Step 4e Partial Failure and Spec File Consistency

**Scenario:** 5 epics, 3 created successfully, epic 4 fails, epic 5 never attempted (or also fails).

**Analysis of the accumulator pattern (lines 422-434):**

1. Epic 1: created -> issue ID written back to `spec/epics/01-auth.md` (in-memory, not yet committed)
2. Epic 2: created -> issue ID written back to `spec/epics/02-api.md`
3. Epic 3: created -> issue ID written back to `spec/epics/03-ui.md`
4. Epic 4: FAIL -> logged as WARN, continue
5. Epic 5: created -> issue ID written back to `spec/epics/05-deploy.md` (the accumulator continues past failures)

After iteration, the commit at line 427 runs: `git add spec/ && git commit -m "chore: link spec epics to tracker issues"`

**This commits a mixed state:** spec files 01, 02, 03, and 05 have issue ID references, but spec file 04 does not. The spec/ folder is internally inconsistent.

**Is this a problem?** For downstream agents (architect, fixer), the missing issue ID in epic 04 is invisible — they read the spec content, not the tracker links. For `/implement-feature --issue`, the user would need to manually create the missing issue for epic 04 or skip it. The message "Remaining epics can be linked later via /implement-feature" (line 431) is slightly misleading — `/implement-feature` does not have a "link existing spec epic to tracker" mode.

**Severity: P2.** The spec content is consistent; only the tracker metadata is partial. Functional impact is low. The misleading recovery guidance is the main UX issue.

---

## Summary

| # | Scenario | Handled? | Severity | Key Gap |
|---|----------|----------|----------|---------|
| 1 | Wrong credentials (read-only permissions) | Partially — Step 4e degrades gracefully but no write-permission pre-flight | P2 | No canary-write check at Step 0-MCP |
| 2 | Crash between Step 4d and Step 4e | No — no state tracking, no recovery command | P1 | No state.json fields for 4d/4e; no re-link command |
| 3 | --issue with missing MCP server | Yes — technically correct but UX is poor (double prompt, YOLO dead-end) | P1 | YOLO + --issue + no MCP = confusing silent discard |

| Additional Finding | Severity |
|---|---|
| Step 0-MCP "Required in-memory values" omits `tracker_project` | P2 (documentation) |
| Step 4e partial failure commits mixed tracker-link state | P2 (UX/consistency) |
| Step 4d has no explicit guard that Step 4c succeeded | P2 (implicit dependency) |
| Step 5 has no explicit guard that Step 3 skeleton exists | P2 (implicit dependency) |
| "Remaining epics can be linked later via /implement-feature" is misleading | P2 (misleading guidance) |

---

## Score: 0.72 / 1.0

**Rationale:** The implementation handles the common happy paths well and has thoughtful degradation (the accumulator pattern, the downgrade mechanism, the "later"/"ready"/"downgraded" three-state model). The MCP pre-flight at Step 0 is a significant improvement over the old post-hoc approach. However, two P1 issues represent real failure modes that users will encounter: the crash-recovery gap between 4d/4e (no state tracking, no recovery command) and the --issue + YOLO + no-MCP dead-end. The P2 issues are legitimate but tolerable for a v5.5.0 release with follow-up fixes planned.

The score reflects: solid architecture (0.8 base), minus the P1 crash-recovery gap (-0.05), minus the P1 YOLO --issue UX issue (-0.03). P2 items collectively account for an additional small deduction.
