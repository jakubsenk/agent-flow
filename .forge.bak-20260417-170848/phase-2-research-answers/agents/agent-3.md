# Research Answers: Work Item 4 — LOW Documentation Fixes (Agent 3)

## Q4.1: Where does "Fix verification" appear in core/fix-verification.md? Exact lines.

The phrase "Fix verification" (with capital F) appears on **line 26** as part of the failure comment template:

```
[ceos-agents] ❌ Fix verification failed.
```

That is the only instance of "Fix verification" in the file. The heading on line 1 reads `# fix-verification` (lowercase, matching the filename). Line 5 uses "verify" generically. No other occurrence of the exact string "Fix verification" exists in the file.

**Issue:** The failure comment on line 26 uses bug-fix-centric language ("Fix verification failed"). This same `core/fix-verification.md` is invoked by `skills/implement-feature/SKILL.md` (feature pipeline) and `skills/fix-bugs/SKILL.md`. When running after a feature PR merge, emitting "Fix verification failed" is misleading — there was no "fix" involved.

**Current text (line 26):**
```
[ceos-agents] ❌ Fix verification failed.
```

**Proposed replacement:**
```
[ceos-agents] ❌ Verification failed.
```

Additionally, the success comment on line 21 reads:
```
[ceos-agents] ✅ Fix verified. Verify command: `{command}`. Output: {first 500 chars}.
```

**Proposed replacement (line 21):**
```
[ceos-agents] ✅ Verified. Verify command: `{command}`. Output: {first 500 chars}.
```

---

## Q4.2: What other files reference core/fix-verification.md by name?

Three active skill files (outside backup directories) reference `core/fix-verification.md` by name:

1. **`skills/fix-ticket/SKILL.md`** (line 603):
   ```
   Follow `core/fix-verification.md` for post-merge verification.
   ```

2. **`skills/fix-bugs/SKILL.md`** (line 622):
   ```
   Follow `core/fix-verification.md` for post-merge verification.
   ```

3. **`skills/implement-feature/SKILL.md`** (line 627):
   ```
   Follow `core/fix-verification.md`. If Build & Test → Verify exists in Automation Config:
   ```

Additionally, **`docs/plans/roadmap.md`** (line 608) references it in a planned fix entry:
```
- `core/fix-verification.md`: Use mode-neutral language ("Verification" not "Fix verification")
```

---

## Q4.3: What is the forward reference in core/state-manager.md and what does it describe?

The forward reference appears in the **Resume Process** section, lines 41-43:

```markdown
2. If state.json does not exist:
   - Fall back to heuristic detection (see resume-ticket.md existing logic)
   - Return resume_point from heuristic with reduced context
```

The phrase **"(see resume-ticket.md existing logic)"** is the forward reference. It describes the fallback behavior when no state.json file exists: the state-manager is supposed to apply heuristic detection that lives in `resume-ticket.md` (i.e., `skills/resume-ticket/SKILL.md`) to determine where the pipeline was interrupted, and return a resume point with reduced context (no AC, no iteration counts).

The problem: `core/state-manager.md` is a reusable contract that is imported by callers. Referencing "resume-ticket.md existing logic" as an external dependency creates a forward-reference loop — the contract borrows its own fallback definition from one of its callers (resume-ticket is a skill, not a core contract). This makes the contract incomplete and fragile: readers cannot understand state-manager in isolation, and the referenced heuristic logic lives in a skill layer above the core layer.

---

## Q4.4: What heuristic detail should be inlined to replace the forward reference?

The heuristic logic is fully defined in `skills/resume-ticket/SKILL.md` under **"Heuristic Detection (Fallback)"** (lines 36-70). The key table is:

| Checkpoint | Signal | Skips |
|-----------|--------|---------|
| `DECOMPOSE_PARTIAL` | `.claude/decomposition/{ISSUE-ID}.yaml` exists + some subtask completed | Triage + analysis + completed subtasks |
| `FRESH` | No branch, no `[ceos-agents]` or `[CLAUDE-agents]` comments | Nothing — full pipeline runs |
| `POST_TRIAGE` | Comment `[ceos-agents] Triage completed.` or `[CLAUDE-agents] Triage completed.` exists | Triage |
| `POST_ANALYSIS` | Branch exists (per branch naming from config) + triage comment | Triage + code-analyst |
| `POST_FIX` | Branch with commits above base branch | Triage + code-analyst + fixer |
| `POST_REVIEW` | Branch + reviewer approval comment | Triage + code-analyst + fixer + reviewer |
| `PUBLISHED` | Open PR exists for branch | Entire pipeline — just display status |

Detection priority logic:
```
if PR exists for branch → PUBLISHED
else if .claude/decomposition/{ISSUE-ID}.yaml exists → DECOMPOSE_PARTIAL
else if branch has commits above base → POST_FIX (or POST_REVIEW if reviewer approval comment)
else if branch exists + triage comment → POST_ANALYSIS
else if triage comment exists → POST_TRIAGE
else → FRESH
```

**Proposed replacement for the forward reference in core/state-manager.md:**

Replace lines 41-43:
```markdown
2. If state.json does not exist:
   - Fall back to heuristic detection (see resume-ticket.md existing logic)
   - Return resume_point from heuristic with reduced context
```

With the inlined version:
```markdown
2. If state.json does not exist:
   - Fall back to heuristic detection by reading issue tracker comments, branch state, and git log:
     - PR open for branch → `PUBLISHED`
     - `.claude/decomposition/{ISSUE-ID}.yaml` exists → `DECOMPOSE_PARTIAL`
     - Branch with commits above base → `POST_FIX` (or `POST_REVIEW` if reviewer approval comment present)
     - Branch exists + `[ceos-agents] Triage completed.` comment → `POST_ANALYSIS`
     - `[ceos-agents] Triage completed.` comment only → `POST_TRIAGE`
     - Otherwise → `FRESH`
   - Return resume_point from heuristic with reduced context (no AC list, no iteration counts)
```

---

## Q4.5: What fields exist in state/schema.md e2e_test section vs what should exist?

**Current state (lines 225-226 of state/schema.md):**

In the full schema example JSON:
```json
"e2e_test": {
  "status": "pending"
}
```

In the field definitions table (lines 225-226):
```
| `e2e_test` | object | Yes | — | E2E-test-engineer phase state. |
| `e2e_test.status` | string | Yes | `"pending"` | Phase status. See Step Status Enum. |
```

Only `status` is defined. Compare this to the `test` section which has `attempts`, `max_attempts`, and `last_result` fields — these make test resumability and metrics possible.

**What should exist:** By parity with the `test` section and the e2e-test-engineer agent behavior (up to 3 retry attempts, PASS/FAIL/BLOCK verdicts), the e2e_test section should track:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `e2e_test.status` | string | Yes | `"pending"` | Phase status. See Step Status Enum. |
| `e2e_test.attempts` | integer | Yes | `0` | Number of completed E2E test attempts. |
| `e2e_test.max_attempts` | integer | Yes | `3` | Maximum allowed attempts (from retry limits). |
| `e2e_test.last_result` | string or null | No | `null` | Most recent E2E test outcome: `PASSED` or `FAILED`. |
| `e2e_test.framework` | string or null | No | `null` | E2E framework used (e.g., `"playwright"`, `"cypress"`). |

At minimum, `attempts`, `max_attempts`, and `last_result` are needed — they mirror the `test` section exactly and are required for resume logic and metrics.

**Proposed addition to the JSON schema example:**
```json
"e2e_test": {
  "status": "pending",
  "attempts": 0,
  "max_attempts": 3,
  "last_result": null
}
```

---

## Q4.6: Which triage.* and code_analysis.* fields are reused across modes?

By reading `state/schema.md` and cross-referencing the pipeline modes described, the following fields appear in state.json for all pipeline modes (bug-fix, feature, scaffold) that go through triage/spec-analyst and code-analyst phases:

**triage.* fields reused across modes:**
- `triage.status` — used in all modes
- `triage.acceptance_criteria` — written by triage-analyst (bug), spec-analyst (feature), spec-writer (scaffold); read by fixer, reviewer, acceptance-gate, test-engineer in all modes
- `triage.complexity` — used in all modes (complexity estimate determines acceptance-gate trigger)
- `triage.ac_source` — explicitly documents which mode wrote the AC: `"triage-analyst"` (bug), `"spec-analyst"` (feature), `"spec-writer"` (scaffold)

**triage.* fields that are bug-fix-specific:**
- `triage.severity` — only populated in bug-fix mode
- `triage.reproduction_steps` — only populated in bug-fix mode (UI bugs)

**triage.* fields that are feature/scaffold-specific:**
- `triage.area` — used only in bug-fix mode (affected system area), not written by spec-analyst

**code_analysis.* fields reused across modes:**
- `code_analysis.status` — used in all modes
- `code_analysis.affected_files` — used in bug-fix and feature modes (code-analyst runs in both)
- `code_analysis.estimated_diff_lines` — used in bug-fix and feature modes
- `code_analysis.risk` — used in bug-fix mode; may not be populated in feature/scaffold mode (no explicit code-analyst step in scaffold)

**Note:** The schema does not document which fields apply to which modes. The `ac_source` field's description (line 178) is the only field that explicitly documents mode-dependent behavior.

---

## Q4.7: Where should the mode-reuse note be placed in state/schema.md?

The mode-reuse note should be placed in **two locations** in `state/schema.md`:

1. **After the `triage` section header in the field definitions table** (currently at line 171), before the first `triage.*` row. A note like:

   > **Note:** `triage.*` fields are populated by different agents depending on mode: `triage-analyst` (bug-fix), `spec-analyst` (feature), `spec-writer` (scaffold). Fields `severity`, `area`, and `reproduction_steps` are bug-fix-mode-only. `acceptance_criteria`, `complexity`, and `ac_source` are reused across all modes. Downstream agents (reviewer, acceptance-gate) use `ac_source` to locate the authoritative AC list.

2. **In the full schema example JSON comment block** (currently lines 64-72), adding a comment or note indicating that `triage.*` and `code_analysis.*` appear in all pipeline modes but some fields are mode-specific.

Most natural location is **immediately after line 171** (the `triage` row header in the definitions table), as a block-quote or italicized note before the individual field rows begin.

---

## Q4.8: Where does NEEDS_DECOMPOSITION appear in core/fixer-reviewer-loop.md?

NEEDS_DECOMPOSITION appears in **three locations** in `core/fixer-reviewer-loop.md`:

**Line 21** (Process, step 3):
```
3. If fixer output contains `## NEEDS_DECOMPOSITION` → return `NEEDS_DECOMPOSITION` immediately. Only allowed once per ticket; caller enforces the limit.
```

**Line 36** (Output Contract table):
```
| `NEEDS_DECOMPOSITION` | Fixer's decomposition rationale (passed through) |
```

**Line 44** (Failure Handling):
```
- `NEEDS_DECOMPOSITION` → returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md` and `skills/fix-ticket/SKILL.md` step 5).
```

---

## Q4.9: Does "once per ticket" apply uniformly across all 3 callers?

**No, it does not apply uniformly.** The claim on line 21 of `core/fixer-reviewer-loop.md` — "Only allowed once per ticket; caller enforces the limit" — is only partially accurate across the three callers:

**Caller 1: `skills/fix-ticket/SKILL.md`** (lines 452-457)
- Step 3: "If this ticket has already been decomposed once → Block ('Decomposition limit (1) reached')"
- **Enforces the "once per ticket" limit correctly** via an explicit check before re-running architect.

**Caller 2: `skills/fix-bugs/SKILL.md`** (lines 470-475)
- Step 3: "If this bug has already been decomposed once → Block handler (step X)"
- **Enforces the "once per ticket" limit correctly** — same pattern as fix-ticket.

**Caller 3: `skills/implement-feature/SKILL.md`** (lines 482-484)
- The handler branches on mode:
  - Decomposition mode (subtask loop): "Block the current subtask with reason 'Subtask scope exceeds fixer capacity. The architect's decomposition may need refinement.'" — this always blocks, so the limit is effectively enforced by blocking on the first signal.
  - Single-pass mode: "Block the issue with reason 'Feature scope exceeds single-pass fixer capacity.'" — again, blocks immediately.
- **Behavior is equivalent (always block) but the mechanism is different.** There is no explicit "has already been decomposed" guard because implement-feature's NEEDS_DECOMPOSITION handling always blocks rather than retrying via architect. The "once per ticket" concept does not cleanly apply in decomposition mode (where the unit is a subtask, not the whole ticket).

**Additionally**, line 44 of `core/fixer-reviewer-loop.md` in the Failure Handling section only references `skills/fix-ticket/SKILL.md step 5` as the canonical caller — it omits `fix-bugs` and `implement-feature`:

```
- `NEEDS_DECOMPOSITION` → returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md` and `skills/fix-ticket/SKILL.md` step 5).
```

**This is a documentation gap.** The reference should acknowledge all three callers and note their different enforcement strategies.

**Proposed replacement for line 44:**
```
- `NEEDS_DECOMPOSITION` → returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md`). Enforcement varies by caller: `fix-ticket` and `fix-bugs` each enforce a one-decomposition-per-ticket limit (Block if already decomposed); `implement-feature` always Blocks (decomposition mode Blocks the subtask; single-pass mode Blocks the issue).
```

**Summary table:**

| Caller | "Once per ticket" enforced? | Mechanism |
|--------|---------------------------|-----------|
| `fix-ticket` | Yes | Explicit check: "already decomposed once → Block" |
| `fix-bugs` | Yes | Explicit check: "already decomposed once → Block handler" |
| `implement-feature` | Effectively yes (by always blocking) | No counter; always Blocks on signal, regardless of iteration |

The "caller enforces the limit" statement on line 21 of fixer-reviewer-loop.md is correct in outcome but imprecise: implement-feature does not enforce a counter-based limit — it enforces a zero-tolerance policy (always Block).
