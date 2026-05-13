# Implementation Plan — v6.7.2 Pipeline Consistency & Dedup

## Overview

10 modified files, 1 new file. Net ~310-line reduction. 12 acceptance criteria, 5 visible test scripts + 1 hidden regression test. All changes are PATCH-level (behavioral equivalence except documented bug corrections).

---

## Dependency Graph

```
Group A (doc fixes)          Group B (core contract)
  A1  A2  A3  A4               B1
  |   |   |   |                 |
  v   v   v   v                 v
  (independent)          +----- C1  C2  C3 -----+  (Group C: skill refactors)
                         |                       |
                         v                       v
                    (independent)          D1  D2  D3  (Group D: cleanup, depends on C3)
                                            |   |   |
                                            v   v   v
                                          E1  E2      (Group E: cross-cutting)
```

Groups A and B start in parallel. Group C starts after B1. Group D starts after C3 (D1/D2/D3 can also run in parallel). Group E is last.

---

## Group A: Independent Documentation Fixes (WI-4)

No dependencies. All 4 tasks can run in parallel with each other and with Group B.

### Task A1: Mode-Neutral Language in fix-verification.md

| Field | Value |
|-------|-------|
| **ID** | A1 |
| **Title** | Mode-neutral language in `core/fix-verification.md` |
| **Files** | `core/fix-verification.md` (L5, L21, L26) |
| **Dependencies** | None |
| **Design reference** | WI-4 Fix 1, Fix 2, Fix 3 |
| **Complexity** | S |

**Exact changes (3 edits):**

1. **L5 (Purpose line):** Replace `confirm the fix works` with `confirm the changes work`
2. **L21 (success comment):** Replace `Fix verified` with `Verified`
3. **L26 (failure comment):** Replace `Fix verification failed` with `Verification failed`

**Verification:**
```bash
# AC-8 checks:
grep "confirm the changes work" core/fix-verification.md          # >= 1 match
grep -c "Fix verified" core/fix-verification.md                    # 0
grep -c "Fix verification failed" core/fix-verification.md        # 0
grep "Verified" core/fix-verification.md                           # >= 1 match
grep "Verification failed" core/fix-verification.md                # >= 1 match
```
Test script: `.forge/phase-5-tdd/tests/ac8-12-doc-fixes.sh` (AC-8 section)

---

### Task A2: Inline Heuristic in state-manager.md

| Field | Value |
|-------|-------|
| **ID** | A2 |
| **Title** | Replace forward reference with inline heuristic table in `core/state-manager.md` |
| **Files** | `core/state-manager.md` (L38-43 replaced with L38-52) |
| **Dependencies** | None |
| **Design reference** | WI-4 Fix 4 |
| **Complexity** | M |

**Exact changes:**

Replace the Resume Process section (L38-43):
```markdown
### Resume Process
1. Read state.json. If exists:
   - Find the first step with status "in_progress" or "pending" after all "completed" steps
   - Return resume_point (step name) and resume_context (triage AC, complexity, iteration counts)
2. If state.json does not exist:
   - Fall back to heuristic detection (see resume-ticket.md existing logic)
   - Return resume_point from heuristic with reduced context
```

With the expanded version containing the 6-checkpoint table (see design.md WI-4 Fix 4 "After" block). Key elements:
- 6 rows: `PUBLISHED`, `DECOMPOSE_PARTIAL`, `POST_REVIEW`, `POST_FIX`, `POST_ANALYSIS`, `POST_TRIAGE`
- Table columns: Checkpoint, Signal, Skips
- Final line includes `(no AC list, no iteration counts)` qualifier
- Zero references to `resume-ticket.md`

**Verification:**
```bash
# AC-9 checks:
grep -c "resume-ticket" core/state-manager.md                          # 0
grep "PUBLISHED" core/state-manager.md                                  # >= 1
grep "POST_TRIAGE" core/state-manager.md                                # >= 1
grep -cE "^\| (PUBLISHED|DECOMPOSE_PARTIAL|POST_REVIEW|POST_FIX|POST_ANALYSIS|POST_TRIAGE)" core/state-manager.md  # 6
```
Test script: `.forge/phase-5-tdd/tests/ac8-12-doc-fixes.sh` (AC-9 section)

---

### Task A3: e2e_test Schema Parity in state/schema.md

| Field | Value |
|-------|-------|
| **ID** | A3 |
| **Title** | Add `verdict`, `result_path`, `attempts` to e2e_test in `state/schema.md` |
| **Files** | `state/schema.md` (L104-106 JSON example; L225-226 field table) |
| **Dependencies** | None |
| **Design reference** | WI-4 Fix 5 |
| **Complexity** | S |

**Exact changes (2 edits):**

1. **JSON example (L104-106):** Replace:
   ```json
   "e2e_test": {
     "status": "pending"
   },
   ```
   With:
   ```json
   "e2e_test": {
     "status": "pending",
     "verdict": null,
     "result_path": null,
     "attempts": 0
   },
   ```

2. **Field definition table (after L226):** Insert 3 new rows after `e2e_test.status`:
   ```markdown
   | `e2e_test.verdict` | string or null | No | `null` | E2E test outcome: `PASSED` or `FAILED`. |
   | `e2e_test.result_path` | string or null | No | `null` | Path to the E2E test result file (if stored). |
   | `e2e_test.attempts` | integer | No | `0` | Number of E2E test attempts executed. |
   ```

**Verification:**
```bash
# AC-10 checks:
grep '"verdict"' state/schema.md                  # >= 1
grep '"result_path"' state/schema.md              # >= 1
grep '"attempts"' state/schema.md                 # >= 1
grep "e2e_test\.verdict" state/schema.md          # >= 1
grep "e2e_test\.result_path" state/schema.md      # >= 1
grep "e2e_test\.attempts" state/schema.md         # >= 1
```
Test script: `.forge/phase-5-tdd/tests/ac8-12-doc-fixes.sh` (AC-10 section)

---

### Task A4: Complete Caller Reference in fixer-reviewer-loop.md

| Field | Value |
|-------|-------|
| **ID** | A4 |
| **Title** | Expand NEEDS_DECOMPOSITION reference to list all 3 callers |
| **Files** | `core/fixer-reviewer-loop.md` (L44) |
| **Dependencies** | None |
| **Design reference** | WI-4 Fix 6 |
| **Complexity** | S |

**Exact changes:**

Replace L44:
```markdown
- `NEEDS_DECOMPOSITION` → returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md` and `skills/fix-ticket/SKILL.md` step 5).
```

With:
```markdown
- `NEEDS_DECOMPOSITION` → returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md`). Callers: `skills/fix-ticket/SKILL.md` step 5 (revert + re-decompose, max 1), `skills/fix-bugs/SKILL.md` step 4 (revert + re-decompose per-bug, max 1), `skills/implement-feature/SKILL.md` step 6b (block current subtask or block issue in single-pass).
```

**Verification:**
```bash
# AC-11 checks:
grep -A 10 "NEEDS_DECOMPOSITION" core/fixer-reviewer-loop.md | grep "fix-ticket"           # match
grep -A 10 "NEEDS_DECOMPOSITION" core/fixer-reviewer-loop.md | grep "fix-bugs"             # match
grep -A 10 "NEEDS_DECOMPOSITION" core/fixer-reviewer-loop.md | grep "implement-feature"    # match
```
Test script: `.forge/phase-5-tdd/tests/ac8-12-doc-fixes.sh` (AC-11 section)

---

## Group B: Core Contract Creation (WI-1 step 1)

No dependencies. Can start in parallel with Group A.

### Task B1: Create `core/tracker-subtask-creator.md`

| Field | Value |
|-------|-------|
| **ID** | B1 |
| **Title** | Create the 15th core contract: `core/tracker-subtask-creator.md` |
| **Files** | `core/tracker-subtask-creator.md` (NEW) |
| **Dependencies** | None |
| **Design reference** | WI-1 "New File: core/tracker-subtask-creator.md" (full verbatim content in design.md) |
| **Complexity** | L |

**Exact changes:**

Create the file with the **exact content** specified in design.md under "New File: `core/tracker-subtask-creator.md`". The content is provided verbatim in the design document (the block between the triple backticks from L148 to L357 of design.md).

**Required sections (in order):**
1. `# Tracker Subtask Creator` (title)
2. `## Purpose` — one-sentence description
3. `## Input Contract` — 9-row, 3-column table (Field, Type, Notes)
4. `## Process` — contains Triple Gate + Subtask Creation Loop pseudocode
5. `## Per-Tracker Issue Creation Parameters` — 6-row table (YouTrack, Jira, Linear, Redmine, GitHub, Gitea)
6. `## Issue Description Template` — template block + conditional rules + mcp-body-formatting reference (paragraph form)
7. `## Output Contract` — bullet list with success_count, failure_count, created_issues, YAML commit note, "Pipeline continues regardless" statement
8. `## Failure Handling` — 4 failure scenarios

**Key content to verify:**
- All 6 tracker types present (youtrack, jira, linear, redmine, github, gitea)
- Idempotency pattern: YAML-first check, state.json fallback
- Jira nested sub-task guard
- GitHub/Gitea checklist post-loop
- Dual-store persistence (YAML + state.json)
- `yaml_path` and `state_json_path` fields present
- `success_count`, `failure_count`, `created_issues` in Output Contract
- "Pipeline continues regardless" statement
- mcp-body-formatting reference in paragraph form (not list-item)

**Verification:**
```bash
# AC-1 checks:
test -f core/tracker-subtask-creator.md
grep "^## Purpose$" core/tracker-subtask-creator.md
grep "^## Input Contract$" core/tracker-subtask-creator.md
grep "^## Process$" core/tracker-subtask-creator.md
grep "^## Output Contract$" core/tracker-subtask-creator.md
grep "^## Failure Handling$" core/tracker-subtask-creator.md

# AC-2 checks (Input Contract table):
# 9 rows, 3 columns, all 9 field names present

# Regression (hidden test) checks:
grep -i "youtrack" core/tracker-subtask-creator.md
grep -i "jira" core/tracker-subtask-creator.md
grep -i "linear" core/tracker-subtask-creator.md
grep -i "redmine" core/tracker-subtask-creator.md
grep -i "github" core/tracker-subtask-creator.md
grep -i "gitea" core/tracker-subtask-creator.md
grep "yaml_path" core/tracker-subtask-creator.md
grep "state_json_path\|state\.json" core/tracker-subtask-creator.md
grep -i "checklist" core/tracker-subtask-creator.md
grep -i "jira.*sub.task\|sub.task.*jira" core/tracker-subtask-creator.md
grep "success_count" core/tracker-subtask-creator.md
grep "failure_count" core/tracker-subtask-creator.md
grep "created_issues" core/tracker-subtask-creator.md
grep -i "pipeline continues regardless" core/tracker-subtask-creator.md
```
Test scripts: `.forge/phase-5-tdd/tests/ac1-core-contract-structure.sh`, `.forge/phase-5-tdd/tests-hidden/regression-no-content-loss.sh`

---

## Group C: Skill Refactors — Caller Delegation (WI-1 steps 2-4)

**Depends on:** B1 (the core contract must exist before callers can reference it).

All 3 tasks in Group C can run in parallel with each other.

### Task C1: Refactor `skills/fix-ticket/SKILL.md` step 4b-tracker

| Field | Value |
|-------|-------|
| **ID** | C1 |
| **Title** | Replace inline tracker subtask logic with delegation stub in fix-ticket |
| **Files** | `skills/fix-ticket/SKILL.md` (L207-388 replaced with ~5 lines) |
| **Dependencies** | B1 |
| **Design reference** | WI-1 "Caller Replacement: skills/fix-ticket/SKILL.md step 4b-tracker" |
| **Complexity** | M |

**Exact changes:**

Replace the entire step 4b-tracker block (from `### 4b-tracker. Create tracker subtasks` through the mcp-body-formatting reference, ~180 lines) with:

```markdown
### 4b-tracker. Create tracker subtasks

Follow `core/tracker-subtask-creator.md`.

Required in-memory values: `ISSUE_ID`, `tracker_type`, `tracker_project`, `tracker_effective_status`, `decomposition_decision`, `create_tracker_subtasks_config`, subtask list, YAML path (`.claude/decomposition/{ISSUE-ID}.yaml`), state.json path (`.ceos-agents/{ISSUE-ID}/state.json`).
```

**Negative checks (must NOT be present after edit):**
- `FOR EACH subtask` — inline pseudocode removed
- `MCP Tool Pattern` — Per-Tracker table removed
- `{subtask.scope}` — Issue Description Template removed

**Verification:**
```bash
# AC-3 checks:
grep "tracker-subtask-creator.md" skills/fix-ticket/SKILL.md         # match
grep -c "FOR EACH subtask" skills/fix-ticket/SKILL.md                # 0
grep -ci "MCP Tool Pattern" skills/fix-ticket/SKILL.md               # 0
grep -c "{subtask\.scope}" skills/fix-ticket/SKILL.md                # 0
```
Test script: `.forge/phase-5-tdd/tests/ac2-4-skills-delegate.sh` (fix-ticket section)

---

### Task C2: Refactor `skills/fix-bugs/SKILL.md` step 3b-tracker

| Field | Value |
|-------|-------|
| **ID** | C2 |
| **Title** | Replace inline tracker subtask logic with delegation stub in fix-bugs |
| **Files** | `skills/fix-bugs/SKILL.md` (L224-406 replaced with ~5 lines) |
| **Dependencies** | B1 |
| **Design reference** | WI-1 "Caller Replacement: skills/fix-bugs/SKILL.md step 3b-tracker" |
| **Complexity** | M |

**Exact changes:**

Replace the entire step 3b-tracker block (from `### 3b-tracker. Create tracker subtasks` through the mcp-body-formatting reference, ~180 lines) with:

```markdown
### 3b-tracker. Create tracker subtasks

Follow `core/tracker-subtask-creator.md`.

Required in-memory values: `ISSUE_ID`, `tracker_type`, `tracker_project`, `tracker_effective_status`, `decomposition_decision`, `create_tracker_subtasks_config`, subtask list, YAML path (`.claude/decomposition/{ISSUE-ID}.yaml`), state.json path (`.ceos-agents/{ISSUE-ID}/state.json`).
```

**Negative checks (same as C1):**
- `FOR EACH subtask` — 0
- `MCP Tool Pattern` — 0
- `{subtask.scope}` — 0

**Verification:**
```bash
# AC-3 checks:
grep "tracker-subtask-creator.md" skills/fix-bugs/SKILL.md           # match
grep -c "FOR EACH subtask" skills/fix-bugs/SKILL.md                  # 0
grep -ci "MCP Tool Pattern" skills/fix-bugs/SKILL.md                 # 0
grep -c "{subtask\.scope}" skills/fix-bugs/SKILL.md                  # 0
```
Test script: `.forge/phase-5-tdd/tests/ac2-4-skills-delegate.sh` (fix-bugs section)

---

### Task C3: Refactor `skills/implement-feature/SKILL.md` step 5a

| Field | Value |
|-------|-------|
| **ID** | C3 |
| **Title** | Replace inline tracker subtask logic with delegation stub in implement-feature |
| **Files** | `skills/implement-feature/SKILL.md` (L266-448 replaced with ~5 lines) |
| **Dependencies** | B1 |
| **Design reference** | WI-1 "Caller Replacement: skills/implement-feature/SKILL.md step 5a" |
| **Complexity** | M |

**Exact changes:**

Replace the entire step 5a block (from `### 5a. Create tracker subtasks` through the mcp-body-formatting reference, ~180 lines) with:

```markdown
### 5a. Create tracker subtasks

Follow `core/tracker-subtask-creator.md`.

Required in-memory values: `ISSUE_ID`, `tracker_type`, `tracker_project`, `tracker_effective_status`, `decomposition_decision`, `create_tracker_subtasks_config`, subtask list, YAML path (`.claude/decomposition/{ISSUE-ID}.yaml`), state.json path (`.ceos-agents/{ISSUE-ID}/state.json`).
```

**Negative checks (same as C1/C2):**
- `FOR EACH subtask` — 0
- `MCP Tool Pattern` — 0
- `{subtask.scope}` — 0

**Verification:**
```bash
# AC-3 checks:
grep "tracker-subtask-creator.md" skills/implement-feature/SKILL.md  # match
grep -c "FOR EACH subtask" skills/implement-feature/SKILL.md        # 0
grep -ci "MCP Tool Pattern" skills/implement-feature/SKILL.md       # 0
grep -c "{subtask\.scope}" skills/implement-feature/SKILL.md        # 0
```
Test script: `.forge/phase-5-tdd/tests/ac2-4-skills-delegate.sh` (implement-feature section)

---

## Group D: implement-feature Cleanup + fix-bugs Webhook/Block Alignment (WI-2 + WI-3)

**Depends on:** C3 (implement-feature must have its step 5a already refactored to avoid merge conflicts with adjacent steps). D1, D2, D3 can run in parallel with each other.

### Task D1: Replace implement-feature step X inline block handler (WI-3)

| Field | Value |
|-------|-------|
| **ID** | D1 |
| **Title** | Replace 25-line inline block handler with 4-line delegation in implement-feature |
| **Files** | `skills/implement-feature/SKILL.md` (L642-666 replaced with 4 lines) |
| **Dependencies** | C3 (same file; line numbers shift after C3) |
| **Design reference** | WI-3 "skills/implement-feature/SKILL.md step X" |
| **Complexity** | M |

**Exact changes:**

Replace the block handler step X (from `### X. Block handler` through the `Update state.json` line at L666 — the version with inline rollback/status-set/comment/webhook) with:

```markdown
### X. Block handler

Follow `core/block-handler.md` for the block protocol.

Update `state.json`: set top-level `status` to `"blocked"`, write `block` object with `{agent, step, reason, detail, recommendation}`. Follow atomic write protocol from `core/state-manager.md`.
```

**IMPORTANT:** After C3 runs, line numbers will have shifted significantly (~180 lines removed from step 5a). The step X heading (`### X. Block handler`) is the anchor — search for it by heading text, not by line number.

**Negative checks (must NOT be present in step X after edit):**
- `rollback` — 0 (handled by core)
- `curl` — 0 (handled by core)
- Numbered steps `1.` through `6.` — 0 (old inline pattern)
- `status.*set` or `set.*status` — 0 (handled by core)
- Total non-blank lines in step X <= 5

**Verification:**
```bash
# AC-7 checks:
awk '/^### X\./,/^##/' skills/implement-feature/SKILL.md | grep -c "core/block-handler.md"  # >= 1
awk '/^### X\./,/^##/' skills/implement-feature/SKILL.md | grep -c "state\.json"            # >= 1
awk '/^### X\./,/^##/' skills/implement-feature/SKILL.md | grep -v "^### X\." | grep -v "^##" | grep -c '[^[:space:]]'  # <= 5
# AC-4 (cumulative, after D1+D2):
grep -c "curl" skills/implement-feature/SKILL.md                                              # 0
```
Test script: `.forge/phase-5-tdd/tests/ac7-block-handler-delegation.sh`

---

### Task D2: Replace implement-feature step 10a webhook (WI-2)

| Field | Value |
|-------|-------|
| **ID** | D2 |
| **Title** | Replace inline curl webhook with core contract delegation in implement-feature step 10a |
| **Files** | `skills/implement-feature/SKILL.md` (step 10a, L617-623 before C3 shift) |
| **Dependencies** | C3 (same file; line numbers shift after C3) |
| **Design reference** | WI-2 "skills/implement-feature/SKILL.md step 10a" |
| **Complexity** | S |

**Exact changes:**

Replace step 10a (anchor: `#### 10a. Post-publish hook + webhook`) — the version containing an inline `curl` command and deviant JSON keys — with:

```markdown
#### 10a. Post-publish hook + webhook

Follow `core/post-publish-hook.md` for hook execution and webhook firing.
```

**Deviations being corrected:**
- Removes `curl` command (missing `--max-time 5 --retry 0` flags)
- Removes deviant `"issue"` key (canonical is `"issue_id"`)
- Removes deviant `"pr"` key (canonical is `"pr_url"`)
- Removes missing `timestamp` field

**Verification:**
```bash
# AC-4 (cumulative):
grep -c "curl" skills/implement-feature/SKILL.md  # 0
# AC-5 (deviant key check):
grep -E '"issue"[[:space:]]*:' skills/implement-feature/SKILL.md | grep -v '"issue_id"'  # 0 matches
```
Test script: `.forge/phase-5-tdd/tests/ac5-6-webhook-alignment.sh` (implement-feature section)

---

### Task D3: fix-bugs step 8b pointer + step X block handler delegation (WI-2)

| Field | Value |
|-------|-------|
| **ID** | D3 |
| **Title** | Replace fix-bugs step 8b with pointer note; replace step X with delegation + 4 addenda |
| **Files** | `skills/fix-bugs/SKILL.md` (step 8b L610-618; step X L667-710) |
| **Dependencies** | C2 (same file; line numbers shift after C2, but 8b and X are far from 3b-tracker) |
| **Design reference** | WI-2 "skills/fix-bugs/SKILL.md step 8b" and "skills/fix-bugs/SKILL.md step X" |
| **Complexity** | M |

**Exact changes (2 edits in same file):**

**Edit 1 — Step 8b (anchor: `### 8b. Webhook`):**

Replace the step 8b block (containing inline `curl` and JSON payload) with:

```markdown
### 8b. Webhook — PR created

Handled by `core/post-publish-hook.md` (invoked in step 8a above). No additional action needed.
```

**Edit 2 — Step X (anchor: `### X. Block handler`):**

Replace the 8-step inline block handler (containing numbered steps 1-8, inline curl, deviant keys) with:

```markdown
### X. Block handler

Follow `core/block-handler.md` for the block protocol.

**Skill-specific context:**
- Rollback execution context: `{worktree_path}` (parallel mode) or `CWD` (sequential mode). Pass this in the rollback-agent Task context string.
- State path: `.ceos-agents/{ISSUE-ID}/state.json` (per-issue, not per-run).
- Block counter: After core block protocol completes, increment `block_count`. If `Max blocked per run` is not `unlimited` and `block_count >= Max blocked per run`:
  - Display: "Max blocked per run ({N}) reached. Remaining {M} bugs skipped."
  - Skip to step 9 (Summary) — DO NOT process remaining bugs.
- Continue with next bug.
```

**Negative checks after both edits:**
- Step 8b: no `curl`, no `"event"` JSON key, contains `core/post-publish-hook.md` and `step 8a`
- Step X: no `curl`, no numbered steps `1.`-`6.`, contains `core/block-handler.md`, contains `Skill-specific context`, exactly 4 top-level bullet points (`^- `)

**Verification:**
```bash
# AC-5 checks (step 8b):
awk '/^### 8b\./,/^###/' skills/fix-bugs/SKILL.md | grep -c "core/post-publish-hook.md"  # >= 1
awk '/^### 8b\./,/^###/' skills/fix-bugs/SKILL.md | grep -c "curl"                       # 0
awk '/^### 8b\./,/^###/' skills/fix-bugs/SKILL.md | grep -c '"event"'                    # 0

# AC-6 checks (step X):
awk '/^### X\./,/^##/' skills/fix-bugs/SKILL.md | grep -c "core/block-handler.md"        # >= 1
awk '/^### X\./,/^##/' skills/fix-bugs/SKILL.md | grep -ci "Skill-specific context"      # >= 1
awk '/^### X\./,/^##/' skills/fix-bugs/SKILL.md | grep -v "^### X\." | grep -v "^##" | grep -c "^- "  # 4
awk '/^### X\./,/^##/' skills/fix-bugs/SKILL.md | grep -c "curl"                         # 0
```
Test script: `.forge/phase-5-tdd/tests/ac5-6-webhook-alignment.sh` (AC-5 and AC-6 sections)

---

## Group E: Cross-Cutting Updates

**Depends on:** All of Groups A-D (these are final touches after all content changes).

### Task E1: Update CLAUDE.md Core Contract Count

| Field | Value |
|-------|-------|
| **ID** | E1 |
| **Title** | Update core contract count from 14 to 15 in CLAUDE.md |
| **Files** | `CLAUDE.md` (L27) |
| **Dependencies** | B1 (contract must exist), all tasks (count reflects final state) |
| **Design reference** | WI-Cross "CLAUDE.md" |
| **Complexity** | S |

**Exact changes:**

Replace:
```
- `core/` — 14 shared pipeline pattern contracts
```
With:
```
- `core/` — 15 shared pipeline pattern contracts
```

**Verification:**
```bash
# AC-12 checks:
grep -c "15 shared pipeline pattern contracts" CLAUDE.md   # 1
grep -c "14 shared pipeline pattern contracts" CLAUDE.md   # 0
```
Test scripts: `.forge/phase-5-tdd/tests/ac8-12-doc-fixes.sh` (AC-12 section), `.forge/phase-5-tdd/tests-hidden/regression-no-content-loss.sh`

---

### Task E2: Roadmap Entry for YOLO Latent Bug

| Field | Value |
|-------|-------|
| **ID** | E2 |
| **Title** | Add YOLO latent bug entry to roadmap BACKLOG section |
| **Files** | `docs/plans/roadmap.md` (BACKLOG section, ~L741) |
| **Dependencies** | None (can technically run earlier, placed in E for organizational clarity) |
| **Design reference** | WI-Cross "Roadmap Entry" |
| **Complexity** | S |

**Exact changes:**

Add a new subsection in the BACKLOG section (after the existing "Document Sharding with Selective Loading" entry, before the `---` separator leading to EXPLORING):

```markdown
### fix-bugs YOLO References (Latent Bug)
**Source:** v6.7.2 audit
- fix-bugs: YOLO references inherited from fix-ticket but --yolo flag not supported (latent, no user impact until --yolo is added to fix-bugs)
```

**Verification:**
```bash
grep -i "yolo" docs/plans/roadmap.md | grep -i "fix-bugs"   # >= 1 match (beyond existing ones)
```
Test: `.forge/phase-5-tdd/tests/ac8-12-doc-fixes.sh` "Roadmap entry exists" cross-cutting check

---

## Execution Summary

| Group | Tasks | Parallelism | Depends On | Files Touched |
|-------|-------|-------------|------------|---------------|
| A | A1, A2, A3, A4 | All 4 parallel | None | `core/fix-verification.md`, `core/state-manager.md`, `state/schema.md`, `core/fixer-reviewer-loop.md` |
| B | B1 | Single task | None | `core/tracker-subtask-creator.md` (NEW) |
| C | C1, C2, C3 | All 3 parallel | B1 | `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md` |
| D | D1, D2, D3 | All 3 parallel | C3 (D1, D2), C2 (D3) | `skills/implement-feature/SKILL.md`, `skills/fix-bugs/SKILL.md` |
| E | E1, E2 | Both parallel | All above | `CLAUDE.md`, `docs/plans/roadmap.md` |

**Total tasks:** 12
**Total files:** 1 new + 9 modified = 10 files
**Critical path:** B1 -> C3 -> D1 (longest dependency chain)
**Maximum parallelism:** 5 tasks (A1+A2+A3+A4+B1 in first wave)

---

## Test Execution Order

After all tasks complete, run the full test suite:

```bash
# Individual AC test scripts (in any order):
.forge/phase-5-tdd/tests/ac1-core-contract-structure.sh     # AC-1, AC-2 (B1)
.forge/phase-5-tdd/tests/ac2-4-skills-delegate.sh           # AC-3, AC-4 (C1-C3, D2)
.forge/phase-5-tdd/tests/ac5-6-webhook-alignment.sh         # AC-5, AC-6 (D2, D3)
.forge/phase-5-tdd/tests/ac7-block-handler-delegation.sh    # AC-7 (D1)
.forge/phase-5-tdd/tests/ac8-12-doc-fixes.sh                # AC-8 through AC-12 (A1-A4, E1)

# Hidden regression test:
.forge/phase-5-tdd/tests-hidden/regression-no-content-loss.sh  # REQ-1.3 functional equivalence (B1, E1)

# Full existing test suite (must remain green):
./tests/harness/run-tests.sh
```

---

## Risk Notes

1. **Line number drift:** Tasks C1/C2/C3 each remove ~180 lines from their respective files. Tasks D1/D2 operate on the same file as C3 (`skills/implement-feature/SKILL.md`), so they MUST use heading anchors (`### X. Block handler`, `#### 10a.`) rather than line numbers for their search targets.

2. **Task D3 also shares a file with C2** (`skills/fix-bugs/SKILL.md`). Steps 8b and X are far downstream from step 3b-tracker (L610+ vs L224-406), so line drift is predictable but still requires heading-based anchoring.

3. **No behavioral changes.** Every replacement must produce identical pipeline behavior. The only "bug fixes" are in implement-feature (deviant webhook keys, unconditional rollback) — these are explicitly documented deviations being corrected per the requirements.

4. **Content of `core/tracker-subtask-creator.md` (B1) is provided verbatim** in design.md. The implementation agent should copy it exactly rather than regenerating from requirements.
