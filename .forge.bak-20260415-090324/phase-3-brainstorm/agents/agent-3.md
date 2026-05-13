# Persona 3: Skeptical QA Engineer

**Perspective:** I have seen many "simple fixes" break production. Every assumption about v6.5.2 needs stress-testing. The research is thorough, but the proposed solutions carry risks that have not been surfaced yet.

---

## Bug 1: Redmine Status Transitions — Challenge

### Challenge 1: Custom status names and IDs across instances

The research correctly identifies that status IDs are instance-specific. But the problem is deeper than "ask the user for IDs during onboard."

Consider: a Redmine instance where the admin has created custom statuses. The default Redmine installation ships with statuses like "New" (id=1), "In Progress" (id=2), "Resolved" (id=3), "Feedback" (id=4), "Closed" (id=5), "Rejected" (id=6). But many organizations customize these heavily. A real-world Redmine might have:

- "Acknowledged" (id=7) instead of "In Progress"
- "QA Review" (id=12) instead of "For Review"
- "Won't Fix" (id=15) instead of "Rejected"
- No "Blocked" status at all — they use a custom field or priority flag

If we switch to `status_id:22`, the user must know that `22` means "In Progress" in their specific instance. The onboard wizard cannot verify this (no MCP access). The migrate-config tool cannot verify this (it would need MCP access to call `GET /issue_statuses.json`). And the templates (`redmine-oracle-plsql.md`, `redmine-rails.md`) cannot provide correct default IDs because there ARE no universal defaults.

**Risk:** We trade one kind of silent failure (LLM failing to resolve `status:In Progress`) for another (user entering the wrong numeric ID, which silently sets the issue to the wrong status — potentially worse because it actively corrupts data instead of just failing to update).

### Challenge 2: `status_id:22` means different things in different instances

This is the corollary of Challenge 1, but worth stating explicitly. If we put `status_id:2` in templates as a "default," users who copy the template without verifying will have their issues set to whatever status ID 2 happens to be in their instance. In the default Redmine installation, `status_id:2` is "In Progress." But in a customized instance, `status_id:2` could be "Cancelled" or "Deployed" or anything else.

The current `status:In Progress` format at least communicates intent — even when the LLM fails to resolve it, the failure is an omission (status not updated) rather than a commission (status set to the wrong value). With `status_id:22`, the failure mode is silent data corruption.

**Question:** Is a silent no-op (current behavior when LLM fails to resolve) actually worse than silent wrong-status-set (new behavior when user enters wrong ID)?

### Challenge 3: Post-set verification via `redmine_get_issue` can fail

The research (E1) confirms no post-set verification exists anywhere in the pipeline. Introducing it is a new pattern. But what happens when the verification call itself fails?

Scenarios:
- **Network timeout:** The `redmine_update_issue` succeeded, but `redmine_get_issue` times out. The pipeline sees "verification failed" and... does what? Retries? Blocks? The update actually worked.
- **Permission mismatch:** The MCP server's API key has write permissions (can update issues) but limited read permissions (some Redmine configurations restrict issue visibility by role). The update works, but the read-back returns a 403.
- **Race condition:** Between the `update_issue` and `get_issue` calls, another user or automation changes the status. The read-back shows a different status than what was set. Is this a verification failure or an expected concurrent edit?
- **Redmine response caching:** Some Redmine instances behind reverse proxies cache GET responses. The read-back returns the old status because the cache has not been invalidated yet.

All of these are real-world scenarios. The research says "introduce verification" but does not specify the failure policy. If verification failure = WARN (log and continue), it adds complexity for no actionable benefit. If verification failure = BLOCK, it creates false-positive blocks that require human intervention for infrastructure issues unrelated to the actual status update.

### Challenge 4: The legacy `status:In Progress` path might work on some MCP implementations

The `trackers.md` note says: "The `status:{name}` format is an LLM convention. The LLM translates this to the appropriate Redmine API call."

Here is what we have NOT verified: whether some Redmine MCP server implementations actually DO handle the name-to-ID resolution internally. The `mcp-server-redmine` package is not part of this repository. Different versions of the MCP server may have different capabilities:

- **Version A:** Accepts only `status_id` (numeric). `status:In Progress` silently fails or errors.
- **Version B:** Accepts `status_id` (numeric) OR resolves `status` (name) internally. `status:In Progress` works correctly.
- **Version C:** Accepts a `status` parameter with the name, separate from `status_id`. Both work but through different code paths.

If Version B or C exists in the wild, users running those MCP servers have working pipelines today. Our fix to switch to `status_id:{id}` would still work for them, but the "legacy WARN" path that keeps accepting `status:{name}` would be unnecessary noise — their setup is not broken.

**Risk:** We assume the MCP server cannot resolve names, but we have not tested this. The bug report might originate from one specific MCP server version, not a universal problem.

### Challenge 5: Race conditions between set and verify

Even if verification works perfectly in isolation, consider the multi-agent pipeline context:

- `fix-ticket` Step 1 sets status to "In Progress"
- User (human) simultaneously opens the Redmine web UI and manually changes status to "Feedback"
- Verification reads back "Feedback" instead of "In Progress"
- Pipeline treats this as a verification failure

In a batch run (`fix-bugs` processing 10 issues), race conditions are more likely because the pipeline processes issues over minutes or hours. A human might react to a status change partway through.

This is a low-probability event, but the verification pattern must have a defined response. If we WARN, we create log noise. If we BLOCK, we halt the pipeline on a human-initiated action that is not a bug.

---

## Bug 2: Publisher Literal `\n` — Challenge

### Challenge 1: Some MCP tools might handle `\n` correctly

The research identifies 5 vulnerable call sites. But "vulnerable" assumes the MCP tool receiving the parameter treats `\n` as a literal two-character sequence. What if some MCP tools (or some versions of MCP tools) perform their own unescaping?

Specifically:
- **Gitea MCP server (`forgejo-mcp`):** The bug report likely originates from Gitea PR descriptions. Does the Gitea MCP tool's `create_pull_request` accept `\n` in the `body` parameter and render it as literal `\n`? Almost certainly yes — this is the reported bug.
- **GitHub MCP server (`@modelcontextprotocol/server-github`):** GitHub's API accepts markdown in PR body. Does the GitHub MCP server unescape `\n`? Possibly — GitHub's API client libraries often handle this.
- **YouTrack MCP server:** YouTrack uses its own markup format. Does its MCP server handle `\n` differently?

If we add an instruction "always use real newlines, never use `\n` escape sequences" to the publisher, this applies to ALL tracker types, not just Gitea. We need to be certain this instruction does not break PR descriptions or comments for trackers where the MCP tool was handling `\n` correctly via unescaping.

**Risk:** Fixing the Gitea case could theoretically break the GitHub or YouTrack case if those MCP tools expect or prefer `\n` escaping. (I assess this as low probability, but non-zero and untested.)

### Challenge 2: The instruction might change behavior for non-Gitea MCP tools

The publisher agent is tracker-agnostic. Its Step 6 creates PRs through whatever MCP server matches the configured source control type. The instruction "use real newlines in multi-line MCP parameters" would apply to:

- `mcp__gitea__create_pull_request` (the bug target)
- `mcp__github__create_pull_request` (possibly already working)
- Other source control MCP servers

And the block-handler instruction would apply to:
- `mcp__redmine__create_issue_comment` (block comments)
- `mcp__youtrack__*` (block comments)
- `mcp__jira__*` or `mcp__atlassian__*` (block comments)

Each of these MCP tools has its own API backend with different markdown/text handling. A universal instruction is simpler but riskier than a per-tracker instruction.

### Challenge 3: Haiku model reliability for formatting instructions

The publisher uses `model: haiku`. The research (section 5, bullet 4) correctly flags this risk, but I want to push harder on it.

Haiku is the least capable model in the pipeline. Adding nuanced formatting instructions ("use real newlines when passing multi-line strings to MCP tool parameters, but do not add extra whitespace or indentation that would break markdown formatting") creates a complex instruction that haiku may not follow consistently.

Consider the failure modes:
- **Haiku ignores the instruction entirely:** We are back to the current bug. No regression, but no fix either.
- **Haiku over-corrects:** Instead of `\n`, it adds excessive blank lines, or wraps the entire body in a code block, or adds markdown artifacts.
- **Haiku follows the instruction inconsistently:** Some PRs get correct formatting, others do not. Inconsistent behavior is harder to debug than consistent failure.

The instruction must be absolutely unambiguous for haiku. "When constructing the PR description body for the MCP create-PR call, build the description as a single multi-line string value with actual line breaks between sections. Do NOT use backslash-n (`\n`) as a substitute for line breaks." This is the level of explicitness required.

### Challenge 4: Regression risk for non-Redmine trackers

The subtask description templates (call sites #4 and #5 in the research) are used for creating tracker issues, not PRs. These go through different MCP tools:

- `mcp__youtrack__create_issue` — `description` parameter
- `mcp__jira__create_issue` — `description` parameter
- `mcp__redmine__create_issue` — `description` parameter
- `mcp__github__create_issue` — `body` parameter

If we add the newline instruction to these call sites too, we change behavior for ALL trackers at once. The research says these are "vulnerable," but we have no bug reports from YouTrack, Jira, or Linear users about literal `\n` in issue descriptions. We might be fixing a non-problem for those trackers while introducing formatting inconsistencies.

**Principle:** Fix what is broken. Do not fix what is not reported as broken, especially in a PATCH version.

---

## My Proposed Solution: Minimal-Risk, Maximum-Certainty

### Philosophy

The safest fix addresses only confirmed broken behavior, adds no new patterns that could introduce new failure modes, and keeps backward compatibility without requiring user action.

### Bug 1 Solution: Dual-Format Config with LLM-Instruction Strengthening

**Do NOT switch the canonical format to `status_id:{id}`.** This is the highest-risk change proposed by the other approaches, and it trades one class of silent failure for another (wrong numeric ID).

Instead:

**Step 1 — Strengthen the LLM instruction at each call site (5 files, ~6 lines each).**

At every status-setting call site, add a Redmine-specific instruction block:

```markdown
If tracker Type is `redmine` and the state value uses `status:{name}` format:
1. Call the Redmine MCP server to list available statuses
2. Find the status whose name matches `{name}` (case-insensitive)
3. Use the resolved numeric `status_id` in the update call
4. If no matching status is found: log `[WARN] Redmine status '{name}' not found in available statuses. Skipping state transition.` and continue
```

This keeps the human-readable `status:{name}` format in configs, resolves at runtime where MCP access IS available (all 5 call sites have MCP access — unlike the onboard wizard), and handles the "status not found" case gracefully.

**Step 2 — Add `status_id:{id}` as an OPTIONAL alternative format.**

Update `trackers.md` to document both formats:

```
| redmine | `status:{name}` or `status_id:{id}` | `status:In Progress` or `status_id:2` | `status:Closed` or `status_id:5` |
```

Update the Redmine note:

```
> **Redmine note:** Two formats are supported. `status:{name}` is resolved at runtime by querying the Redmine API for available statuses. `status_id:{id}` bypasses resolution and uses the numeric ID directly. Use `status_id:{id}` if your Redmine instance has custom status names that do not match the defaults, or if you want to avoid the runtime lookup.
```

Update the Validation Rules row to accept both patterns:

```
| redmine | Must contain `project_id=` | `status:{name}` or `status_id:{id}` | Any URL |
```

**Step 3 — NO post-set verification.**

Do not introduce a read-back verification pattern. The failure modes of verification (network timeouts, permission mismatches, race conditions, caching) outweigh the benefits. The current fire-and-forget pattern is consistent across all trackers. If the MCP call fails, MCP servers already return errors that the LLM can observe and report.

If verification is truly needed later, it should be introduced as its own minor version feature with its own `core/` contract, not tacked onto a PATCH fix.

**Step 4 — Update config templates to show both formats.**

In `redmine-oracle-plsql.md` and `redmine-rails.md`, keep the `status:{name}` format but add TODO comments showing the `status_id:{id}` alternative:

```
| State transitions | In Progress: `status:In Progress`, Blocked: `status:Blocked`, For Review: `status:For Review`, Done: `status:Closed` |
<!-- Alternative if name-based resolution fails: In Progress: `status_id:2`, Blocked: `status_id:7`, For Review: `status_id:4`, Done: `status_id:5` -->
<!-- Verify YOUR instance's IDs: GET /issue_statuses.json -->
```

**Step 5 — No changes to onboard wizard.**

The onboard wizard already reads from `trackers.md`. Since `trackers.md` now documents both formats, the wizard will emit `status:{name}` by default (the first format listed). Users who need `status_id:{id}` can manually edit after onboard, guided by the TODO comments in the template. This is acceptable for a PATCH version.

**Step 6 — No changes to migrate-config.**

Since `status:{name}` remains valid, existing configs do not need migration. The runtime resolution (Step 1) handles legacy configs automatically. Migrate-config changes can be deferred to a future MINOR version if `status_id:{id}` ever becomes the preferred format.

**Why this is safer than the other approaches:**

- No new pattern (verification) with untested failure modes
- No breaking change to canonical format
- No user action required for existing configs
- Runtime resolution happens where MCP IS available (call sites, not wizard)
- Graceful degradation: if status list call fails, WARN and continue (same as current fire-and-forget behavior but with explicit logging)
- The `status_id:{id}` alternative exists for users who need it, but is opt-in

**What could go wrong:**

- The Redmine MCP server might not expose a "list statuses" tool. In that case, the resolution instruction becomes a no-op and falls back to current behavior. This is acceptable — the user can switch to `status_id:{id}` format.
- Haiku (publisher) might not reliably follow the multi-step resolution instruction. This is why the instruction must include the explicit fallback: "If no status list tool is available, pass the `status:{name}` value as-is and log a WARN."
- Adding per-call-site resolution instructions for Redmine is a form of tracker-type branching. This is true, but it is a single `if tracker type is redmine` block at 5 call sites, not an architectural change. It is pragmatic, not systemic.

### Bug 2 Solution: Explicit Newline Instruction in Publisher and Block-Handler Only

**Do NOT create a centralized `core/mcp-encoding.md` contract.** This is over-engineering for a PATCH fix. The problem is specific: the haiku-model publisher generates `\n` literals in multi-line MCP parameters.

**Step 1 — Add a Constraints entry to `agents/publisher.md`.**

Add a single, unambiguous constraint:

```markdown
- NEVER use the literal characters `\n` to represent line breaks in PR descriptions or issue comments passed to MCP tools — always use actual line breaks (newlines) in the string value. MCP tools pass the value as-is to the API; escaped `\n` will appear as literal text in the rendered output.
```

This is placed in Constraints (not Process) because constraints are NEVER rules — the format haiku is most likely to follow consistently. The instruction is negative ("NEVER use `\n`") rather than positive ("use real newlines"), which is more robust for instruction-following because it gives a specific pattern to avoid.

**Step 2 — Add the same constraint to `core/block-handler.md`.**

Block-handler is called by skills, not a standalone agent, but it posts multi-line comments to issue trackers. Add the same instruction to its Process step 4:

```markdown
4. **Post block comment** to the issue tracker.
   Use actual line breaks in the comment text, NOT escaped `\n` sequences.
```

**Step 3 — Do NOT change the subtask description call sites (#4 and #5).**

The subtask description templates in `fix-ticket` and `implement-feature` create issue descriptions, not PR descriptions. There are no bug reports about literal `\n` in subtask descriptions. These call sites are executed by the orchestrating skill (sonnet model), not by the publisher (haiku model). Sonnet is more reliable at formatting.

Changing these call sites has no confirmed benefit and introduces risk of unintended formatting changes in tracker issue descriptions across all 6 supported trackers. Apply the principle: fix what is broken, leave what works.

**Step 4 — No centralized encoding contract.**

A `core/mcp-encoding.md` would need to be referenced from every agent and skill that makes MCP calls. This is a significant cross-cutting change for a PATCH version. If a pattern emerges (more MCP formatting bugs in the future), introduce the contract in a MINOR version.

**What could go wrong:**

- Haiku might still occasionally generate `\n` despite the NEVER constraint. This is a model reliability issue, not a fixable code issue. The constraint makes the correct behavior explicit; if haiku violates it, the same PR will look wrong and the human reviewer will catch it. No worse than current state.
- The constraint applies to ALL MCP tools (not just Gitea). If a future MCP tool somehow expects `\n` escaping, this constraint would conflict. This is extremely unlikely — MCP tools pass structured parameters, not shell-escaped strings — but the constraint could be narrowed to "when passing multi-line text to MCP tool string parameters" if needed.

---

## Risk Comparison Matrix

| Approach | Bug 1 Risk | Bug 2 Risk | Backward Compat | Scope |
|----------|-----------|-----------|-----------------|-------|
| Option A (trackers.md format change to `status_id`) | HIGH: wrong IDs silently corrupt data; all templates need IDs; onboard needs rework | N/A | BREAKING for existing configs | Large |
| Option B (per-call-site runtime resolution) | LOW-MED: MCP list-statuses might not exist; adds tracker branching | N/A | SAFE: `status:{name}` stays valid | Medium |
| Option C (config-reader normalization) | MED: config-reader needs MCP access it does not have | N/A | SAFE: transparent to consumers | Medium (architectural) |
| Verification pattern | MED-HIGH: verification failures introduce false-positive blocks; new untested pattern | N/A | N/A (additive) | Large (new contract) |
| Centralized encoding contract | N/A | LOW-MED: cross-cutting change; affects all MCP call sites | N/A (additive) | Large |
| **My proposal (dual-format + per-site resolution; publisher constraint only)** | **LOW: graceful degradation; opt-in `status_id`; no new patterns** | **LOW: targeted fix; haiku-optimized NEVER rule** | **SAFE: zero changes for existing users** | **Small-Medium** |

---

## Summary of Edge Cases I Am Most Worried About

1. **Wrong numeric ID in config** — `status_id:2` meaning "Cancelled" in a customized Redmine, applied silently across 10 issues in a `fix-bugs` batch run. This is worse than the current bug.
2. **Verification false positives** — network flake between `update_issue` and `get_issue` blocks the pipeline on an issue that was actually updated correctly. Requires human intervention for a non-issue.
3. **MCP server does not expose status listing** — runtime resolution instruction becomes dead code. Acceptable if we have the `status_id:{id}` opt-in alternative.
4. **Haiku ignoring the newline constraint** — possible but no worse than current state. The NEVER rule in Constraints is the strongest signal we can give a haiku model.
5. **Fixing subtask descriptions that are not broken** — changing behavior for 6 trackers when only 1 (Gitea) has a confirmed bug. Risk/reward is unfavorable.
