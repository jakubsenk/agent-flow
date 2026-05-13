# v6.5.2 Implementation Plan — Redmine + Publisher Fixes

**Version:** v6.5.2 (PATCH)
**Total tasks:** 15
**Estimated total lines changed/added:** ~220
**Critical path length:** 4 layers (L0 → L1 → L2 → L3)
**Date:** 2026-04-15

---

## Task Graph

### T-001 — docs/reference/trackers.md (Format Change)

- **File:** `docs/reference/trackers.md`
- **Description:** Modify 4 locations in this file: (1) Replace the Redmine row in the State Transition Syntax table from `status:{name}` to `status_id:{id}` format. (2) Replace the Redmine note blockquote after the State Transition Syntax table with the expanded version that explains numeric IDs, common defaults, the `GET /issue_statuses.json` lookup, and marks `status:{name}` as legacy/unreliable. (3) Replace the Redmine row in the On Start Set Defaults table from `status:In Progress` to `status_id:2`. (4) Replace the Redmine row in the Validation Rules table to accept both `status_id:{id}` (preferred) and `status:{name}` (legacy).
- **Dependencies:** none
- **Parallel group:** L0
- **Estimated lines:** ~15 changed
- **AC mapping:** AC1, AC2, AC5

**Exact changes:**

Line 27 — State Transition Syntax table, Redmine row:
```
OLD: | redmine | `status:{name}` | `status:In Progress` | `status:Closed` |
NEW: | redmine | `status_id:{id}` | `status_id:2` | `status_id:5` |
```

Line 29 — Redmine note blockquote:
```
OLD: > **Redmine note:** The `status:{name}` format is an LLM convention. The LLM translates this to the appropriate Redmine API call (e.g., `status_id=2` for "In Progress"). Status name-to-ID mapping depends on the Redmine instance configuration.
NEW: > **Redmine note:** The `status_id:{id}` format uses the numeric ID from your Redmine instance. Common defaults: 1=New, 2=In Progress, 3=Resolved, 4=Feedback, 5=Closed, 6=Rejected. Verify your instance's IDs via `GET /issue_statuses.json`. The legacy `status:{name}` format (e.g., `status:In Progress`) is accepted but unreliable — it depends on LLM translation at runtime, which may fail silently. Use `status_id:{id}` for deterministic behavior.
```

Line 51 — On Start Set Defaults table, Redmine row:
```
OLD: | redmine | `status:In Progress` |
NEW: | redmine | `status_id:2` |
```

Line 73 — Validation Rules table, Redmine row:
```
OLD: | redmine | Must contain `project_id=` | `status:{name}` | Any URL |
NEW: | redmine | Must contain `project_id=` | `status_id:{id}` or `status:{name}` (legacy) | Any URL |
```

---

### T-002 — core/status-verification.md (NEW Advisory Contract)

- **File:** `core/status-verification.md` (CREATE)
- **Description:** Create a new advisory core contract for post-update status verification. The contract specifies: after any status-set MCP call, read back the issue state using the tracker's get-issue MCP tool, compare to the expected value, and log the result. All failure modes (mismatch, network error, timeout, permission error, unparseable response, tool unavailable) produce WARN log entries only — the pipeline NEVER blocks on verification failure. Includes Input Contract table (issue_id, expected_state, tracker_type), 3-step Process (read back, compare, verdict), Output Contract (log only), Constraints (5 NEVER rules), and Failure Handling table (5 modes). Full content specified in `design.md` Section 1.
- **Dependencies:** none
- **Parallel group:** L0
- **Estimated lines:** ~55 new
- **AC mapping:** AC3, AC4

---

### T-003 — skills/onboard/SKILL.md (Redmine ID Collection Sub-Step)

- **File:** `skills/onboard/SKILL.md`
- **Description:** In the Fresh Mode section, Step 2 (Issue Tracker), insert a new conditional sub-step 6a between item 6 (State transitions) and item 7 (On start set). This sub-step fires only when tracker type is `redmine`. It displays guidance text with common Redmine status ID defaults (1=New, 2=In Progress, etc.), a curl command for the user to run in a separate terminal to look up their instance's IDs, and accepts 4 numeric IDs interactively (In Progress, Blocked, For Review, Done/Closed) with defaults. The entered IDs are used to compose the State transitions value in `status_id:{id}` format. If the user presses Enter for all, the defaults from trackers.md are used. No allowed-tools change required.
- **Dependencies:** T-001 (references trackers.md format)
- **Parallel group:** L1-A
- **Estimated lines:** ~20 added
- **AC mapping:** AC5

---

### T-004 — agents/publisher.md (Newline Constraint + Verification Wiring)

- **File:** `agents/publisher.md`
- **Description:** Three additions: (a) In the Constraints section, add a new NEVER constraint after the existing "NEVER include 'Generated with Claude Code' footer" line: `NEVER use the literal characters \n in any MCP tool parameter that accepts multi-line text (PR description, issue comments). Always use actual line breaks (real newlines) in the string. The MCP tool receives the parameter value as-is — escaped sequences are rendered literally, not as newlines.` (b) In Process Step 6 (Create Pull Request), after the Description bullet, add inline reinforcement: `Use real line breaks between sections — NEVER use the literal characters \n as line separators.` (c) In Process Step 7 (Update Issue Tracker), after the existing status-set instruction, add: `After the status-set MCP call, follow core/status-verification.md to verify the transition succeeded.`
- **Dependencies:** T-002 (references status-verification.md)
- **Parallel group:** L1-B
- **Estimated lines:** ~8 added
- **AC mapping:** AC3, AC4, AC6

---

### T-005 — core/block-handler.md (Newline Instruction + Verification Wiring)

- **File:** `core/block-handler.md`
- **Description:** Two changes: (a) In Process Step 4 (Post block comment), after the block comment template, add: `When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters \n as line separators.` (b) In Process Step 2 (Set issue state), modify the existing text to append: `After the status-set MCP call, follow core/status-verification.md to verify the transition succeeded.`
- **Dependencies:** T-002 (references status-verification.md)
- **Parallel group:** L1-B
- **Estimated lines:** ~5 changed/added
- **AC mapping:** AC3, AC4, AC7

---

### T-006 — skills/fix-ticket/SKILL.md (Newline Instruction + Verification Wiring)

- **File:** `skills/fix-ticket/SKILL.md`
- **Description:** Two changes: (a) In Step 4b-tracker, after the Issue Description Template and its bullets (after the line `- The "Parent issue:" line is always present.`), add: `When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters \n as line separators.` (b) In Step 1 (Set issue tracker), modify the existing text to append: `After the status-set MCP call, follow core/status-verification.md to verify the transition succeeded.`
- **Dependencies:** T-002 (references status-verification.md)
- **Parallel group:** L1-B
- **Estimated lines:** ~5 changed/added
- **AC mapping:** AC3, AC4, AC6

---

### T-007 — examples/configs/redmine-oracle-plsql.md (Template Update)

- **File:** `examples/configs/redmine-oracle-plsql.md`
- **Description:** Three changes: (1) In the Issue Tracker section table, replace `State transitions` value from `In Progress: \`status:In Progress\`, Blocked: \`status:Blocked\`, For Review: \`status:For Review\`, Done: \`status:Closed\`` to `In Progress: \`status_id:2\`, Blocked: \`status_id:4\`, For Review: \`status_id:4\`, Done: \`status_id:5\``. Replace `On start set` value from `\`status:In Progress\`` to `\`status_id:2\``. (2) Replace the existing TODO comment about status names with a strengthened version mentioning numeric IDs and common defaults. (3) In the commented-out Feature Workflow section, replace `On start set` from `\`status:In Progress\`` to `\`status_id:2\``.
- **Dependencies:** T-001 (references trackers.md format)
- **Parallel group:** L1-A
- **Estimated lines:** ~8 changed
- **AC mapping:** AC1, AC5

---

### T-008 — examples/configs/redmine-rails.md (Template Update)

- **File:** `examples/configs/redmine-rails.md`
- **Description:** Two changes plus one addition: (1) In the Issue Tracker section table, replace `State transitions` value to `status_id:{id}` format (same pattern as T-007). Replace `On start set` value from `\`status:In Progress\`` to `\`status_id:2\``. (2) Add a TODO comment after the Issue Tracker table (currently missing): verify status IDs match instance + verify tracker_id for Bug tracker.
- **Dependencies:** T-001 (references trackers.md format)
- **Parallel group:** L1-A
- **Estimated lines:** ~8 changed/added
- **AC mapping:** AC1, AC5

---

### T-009 — skills/check-setup/SKILL.md (Legacy Format WARN)

- **File:** `skills/check-setup/SKILL.md`
- **Description:** In the Per-tracker validation section (Step 3a), after the existing validation bullet "Apply the state transition format check to the State transitions value", add a new bullet: `Redmine legacy format check: If Type is redmine and any State transitions value matches status:{name} (without status_id:), emit: [WARN] Redmine state transition uses legacy text format (status:{name}). Recommend converting to status_id:{id} format — run /ceos-agents:migrate-config or edit manually. See trackers.md Redmine note for ID lookup instructions.`
- **Dependencies:** T-001 (references trackers.md validation rules)
- **Parallel group:** L1-A
- **Estimated lines:** ~4 added
- **AC mapping:** AC2

---

### T-010 — skills/implement-feature/SKILL.md (Newline Instruction)

- **File:** `skills/implement-feature/SKILL.md`
- **Description:** In Step 5a, after the Issue Description Template and its bullets (after the line `- The "Parent issue:" line is always present.`), add: `When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters \n as line separators.`
- **Dependencies:** none (no verification wiring, newline-only)
- **Parallel group:** L2
- **Estimated lines:** ~2 added
- **AC mapping:** AC6

---

### T-011 — skills/fix-bugs/SKILL.md (Newline Instructions x2)

- **File:** `skills/fix-bugs/SKILL.md`
- **Description:** Two additions: (a) In Step X (Block handler), Step 4 (Add Block comment), after the block comment template (around line 657), add: `When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters \n as line separators.` (b) In Step 3b-tracker, after the Issue Description Template and its bullets (after the line `- The "Parent issue:" line is always present.`, around line 371), add: `When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters \n as line separators.`
- **Dependencies:** none (newline-only, no verification wiring)
- **Parallel group:** L2
- **Estimated lines:** ~4 added
- **AC mapping:** AC7

---

### T-012 — skills/migrate-config/SKILL.md (Deprecated Pattern Rule)

- **File:** `skills/migrate-config/SKILL.md`
- **Description:** Two additions: (a) In Step 3 (Check for deprecated patterns), after the existing two deprecated patterns, add a new bullet for Redmine `status:{name}` format detection with interactive conversion to `status_id:{id}`. The rule displays a prompt accepting 4 numeric IDs (In Progress, Blocked, For Review, Done/Closed) with defaults. If user provides IDs, rewrites each `status:{name}` to `status_id:{id}` in State transitions and On start set. If user skips, leaves unchanged and logs WARN. (b) In Step 4 (Generate migration report), add a new row to the Deprecated Patterns Found example table: `| Redmine \`status:{name}\` format | Convert to \`status_id:{id}\` (interactive) |`.
- **Dependencies:** none (independent skill)
- **Parallel group:** L2
- **Estimated lines:** ~25 added
- **AC mapping:** AC2

---

### T-013 — tests/scenarios/mcp-newline-handling.sh (NEW Test)

- **File:** `tests/scenarios/mcp-newline-handling.sh` (CREATE)
- **Description:** Create a new regression test following the existing harness conventions (set -euo pipefail, FAIL counter, fail() function, PASS/FAIL output). The test asserts that all 5 vulnerable files contain the newline instruction marker text `NEVER use the literal characters`. Files checked: (1) `agents/publisher.md`, (2) `core/block-handler.md`, (3) `skills/fix-ticket/SKILL.md`, (4) `skills/implement-feature/SKILL.md`, (5) `skills/fix-bugs/SKILL.md`. Each file is checked for existence first, then grepped for the marker. Exit with FAIL=1 if any file is missing the instruction. Full script content specified in `design.md` Section 8.
- **Dependencies:** T-004, T-005, T-006, T-010, T-011 (all 5 files must have the marker)
- **Parallel group:** L3
- **Estimated lines:** ~30 new
- **AC mapping:** AC6, AC7

---

### T-014 — CLAUDE.md (Core Count Update)

- **File:** `CLAUDE.md`
- **Description:** In the Repository Structure section, replace `- \`core/\` — 11 shared pipeline pattern contracts` with `- \`core/\` — 12 shared pipeline pattern contracts`.
- **Dependencies:** T-002 (new core contract must exist)
- **Parallel group:** L3
- **Estimated lines:** ~1 changed
- **AC mapping:** AC8 (implicit)

---

### T-015 — docs/plans/roadmap.md (Roadmap Update)

- **File:** `docs/plans/roadmap.md`
- **Description:** Three changes: (a) Update the header `Current version: v6.5.1` to `Current version: v6.5.2`. (b) Move the `## PLANNED — v6.5.2 (Redmine + Publisher Fixes)` section to DONE position (after `## DONE — v6.5.1`), renaming it to `## DONE — v6.5.2 (Redmine + Publisher Fixes)`. Update content to reflect actual implementation: list all 15 files, reference the new `core/status-verification.md` contract, note deferred items. (c) Add 3 deferred items to the existing `## PLANNED — v6.6.0 (Pipeline Hardening)` section: "Status Verification — Remaining Call Sites" (4 files), "MCP Body Formatting Contract" (new core + 5 refs), "fix-bugs On start set Step" (1 file, MINOR). (d) Add 2 NOT PLANNED items: "config-reader Redmine Normalization" and "Onboard Wizard MCP Access", both with rejection rationale.
- **Dependencies:** All other tasks complete (this summarizes the release)
- **Parallel group:** L3
- **Estimated lines:** ~50 changed/added
- **AC mapping:** AC8

---

## Dependency Layers

### Layer 0 — Foundation (no dependencies)

| Task | File | Rationale |
|------|------|-----------|
| **T-001** | `docs/reference/trackers.md` | Single source of truth for tracker formats. L1 files (onboard, check-setup, templates) reference this. |
| **T-002** | `core/status-verification.md` | New advisory contract. L1 files (publisher, block-handler, fix-ticket) reference this. |

**Parallelization:** T-001 and T-002 can run simultaneously (zero overlap).

---

### Layer 1 — Primary Changes (depend on Layer 0)

| Task | File | Depends On | Rationale |
|------|------|------------|-----------|
| **T-003** | `skills/onboard/SKILL.md` | T-001 | Reads trackers.md for Redmine format/defaults. |
| **T-004** | `agents/publisher.md` | T-002 | References `core/status-verification.md` in Step 7. |
| **T-005** | `core/block-handler.md` | T-002 | References `core/status-verification.md` in Step 2. |
| **T-006** | `skills/fix-ticket/SKILL.md` | T-002 | References `core/status-verification.md` in Step 1. |
| **T-007** | `examples/configs/redmine-oracle-plsql.md` | T-001 | Uses `status_id:{id}` format from trackers.md. |
| **T-008** | `examples/configs/redmine-rails.md` | T-001 | Uses `status_id:{id}` format from trackers.md. |
| **T-009** | `skills/check-setup/SKILL.md` | T-001 | Reads trackers.md Validation Rules for format check. |

**Parallelization:** All 7 tasks (T-003 through T-009) can run simultaneously — they modify different files with no cross-dependencies.

**Sub-groups within L1:**
- **L1-A** (depends on T-001 only): T-003, T-007, T-008, T-009
- **L1-B** (depends on T-002 only): T-004, T-005, T-006

---

### Layer 2 — Independent Changes (no L0/L1 dependencies, but logically follow)

| Task | File | Depends On | Rationale |
|------|------|------------|-----------|
| **T-010** | `skills/implement-feature/SKILL.md` | none | Newline instruction only, no verification wiring. |
| **T-011** | `skills/fix-bugs/SKILL.md` | none | Newline instructions only, no verification wiring. |
| **T-012** | `skills/migrate-config/SKILL.md` | none | Independent deprecated-pattern rule. No reference to L0 files. |

**Parallelization:** All 3 tasks can run simultaneously. They also have no true dependency on L0/L1 — they are placed in L2 for logical ordering only. If maximum parallelism is desired, they can run in parallel with L1 tasks.

**Note:** T-010 and T-011 technically have zero dependency on any other task. They are placed in L2 rather than L0 because they are conceptually part of the same newline-instruction sweep as T-004/T-005/T-006, and running them alongside L1 reduces cognitive overhead for the executor.

---

### Layer 3 — Post-Implementation (depend on all content tasks)

| Task | File | Depends On | Rationale |
|------|------|------------|-----------|
| **T-013** | `tests/scenarios/mcp-newline-handling.sh` | T-004, T-005, T-006, T-010, T-011 | Tests that all 5 files contain the newline marker. Must run after all 5 are modified. |
| **T-014** | `CLAUDE.md` | T-002 | Core count 11 → 12 after new contract exists. |
| **T-015** | `docs/plans/roadmap.md` | All (T-001 through T-014) | Summarizes the release — must reflect all implemented changes. |

**Parallelization:** T-013 and T-014 can run simultaneously. T-015 should run last (or at least after T-013 and T-014 are confirmed).

**Post-L3 gate:** Run `./tests/harness/run-tests.sh` to validate all existing tests still pass, plus the new T-013 test. This is a blocking gate before commit.

---

## Parallelization Opportunities — Visual Summary

```
TIME →

L0:  [T-001 trackers.md]  [T-002 status-verification.md]
      ─────────────────────────────────────────────────────
L1:  [T-003 onboard]  [T-007 redmine-plsql]  [T-008 redmine-rails]  [T-009 check-setup]
     [T-004 publisher]  [T-005 block-handler]  [T-006 fix-ticket]
      ─────────────────────────────────────────────────────
L2:  [T-010 implement-feature]  [T-011 fix-bugs]  [T-012 migrate-config]
      ─────────────────────────────────────────────────────
L3:  [T-013 test]  [T-014 CLAUDE.md]
     [T-015 roadmap]
      ─────────────────────────────────────────────────────
GATE: ./tests/harness/run-tests.sh
```

**Maximum parallelism per layer:**
- L0: 2 parallel tasks
- L1: 7 parallel tasks (all independent files)
- L2: 3 parallel tasks (all independent files)
- L3: 2 parallel (T-013 + T-014), then 1 sequential (T-015)

**Aggressive parallelism option:** L2 tasks (T-010, T-011, T-012) have no actual dependency on L0/L1. They can be dispatched alongside L1, giving a maximum of 10 simultaneous tasks after L0 completes.

---

## Execution Summary

| Metric | Value |
|--------|-------|
| Total tasks | 15 |
| New files | 2 (core/status-verification.md, tests/scenarios/mcp-newline-handling.sh) |
| Modified files | 13 |
| Estimated total lines added/changed | ~220 |
| Critical path length | 4 layers + test gate |
| Maximum parallel width | 10 (L1 + L2 combined) |
| Minimum serial steps | 4 (L0 → L1 → L3 → gate) |

### Risk Notes

1. **T-001 (trackers.md)** is the highest-value task — it fixes the root cause of Bug 1. All downstream Redmine behavior depends on this format change being correct.
2. **T-002 (status-verification.md)** is the only new core contract. The existing test `xref-core-registry.sh` dynamically counts `core/*.md` files and compares to CLAUDE.md — **T-014 (CLAUDE.md count update) MUST happen before the test gate** or the test will fail.
3. **T-013 (new test)** uses a grep marker (`NEVER use the literal characters`) — ensure all 5 files use this exact phrasing (they do per the design.md specification).
4. **T-015 (roadmap)** involves moving a section from PLANNED to DONE and adding items to two other sections — careful not to corrupt adjacent sections.
