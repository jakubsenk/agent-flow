# Adversarial Verification Review -- Cycle 0

Target: `skills/implement-feature/SKILL.md` (5 changes for subtask persistence + YOLO docs)

---

## 1. Correctness (weight: 0.4)

### 1a. SINGLE_PASS state writes -- field names vs schema

**Lines 195-196 (DISABLED path):**
```
Update `state.json`: set `decomposition.status` to `"completed"`, `decomposition.decision` to `"SINGLE_PASS"`, `decomposition.strategy` to `null`.
```

Schema check (`state/schema.md`):
- `decomposition.status` -- exists (line 186, type string, Step Status Enum). CORRECT.
- `decomposition.decision` -- exists (line 187, type string or null, values `DECOMPOSE` or `SINGLE_PASS`). CORRECT.
- `decomposition.strategy` -- exists (line 189, type string or null, values `squash` or `per-subtask`). Setting to `null` for SINGLE_PASS is consistent. CORRECT.

**Lines 242-243 (AUTO fallthrough):**
Same three fields with same values. CORRECT.

**Verdict:** All field names and values match the schema. PASS.

### 1b. Step 6h fields vs schema

**Line 327-332:**
The instruction says: update `.claude/decomposition/{ISSUE-ID}.yaml` with `status`, `commit_hash`, `restore_point`. These are subtask-level fields. The schema defines `decomposition.subtasks` as `object[]` (line 188) but does NOT explicitly define per-subtask sub-fields in the schema document. The plan's own verification checklist (line 143) acknowledges this: "schema doc update would be ideal but is non-breaking since the field is typed as `object[]`."

**Line 332:**
`state.json` update: "find the matching subtask in `decomposition.subtasks` by `id`, set its `status` to `"completed"` and `commit_hash` to the new commit SHA."

The schema says `decomposition.subtasks` is `object[]`. The instruction references matching by `id` field. The subtask objects are "mirrors decomposition YAML" per schema line 188. The YAML at line 238 mentions `status: "pending"`, `commit_hash: null`, `restore_point: null` as runtime fields. So `id` must exist for the matching to work, but is never explicitly listed as a required subtask field in this file.

**FINDING (MINOR):** The `id` field used for matching in Step 6h ("find the matching subtask in `decomposition.subtasks` by `id`") is not explicitly established as a required field in the subtask schema. It is implied by the architect's YAML output and the `{subtask-id}` in the commit message, but there is no instruction ensuring subtask objects have an `id` field. If the architect produces a task tree without `id` fields (e.g., using `name` or index only), the Step 6h matching instruction would be ambiguous.

**FINDING (MINOR):** Step 6h updates `state.json` with `status` and `commit_hash` but NOT `restore_point`. The YAML update includes all three fields. This is an asymmetry. The `restore_point` in state.json could be useful for resume logic. However, state/schema.md does not define a `restore_point` sub-field for subtask objects, so omitting it from state.json is arguably correct (it lives only in the YAML file). Not a bug, but a design inconsistency between the two persistence stores.

### 1c. Atomic write protocol references

All four new state.json update instructions end with "Follow atomic write protocol from `core/state-manager.md`." This is consistent with every other state write in the file and across `fix-ticket/SKILL.md`. CORRECT.

### 1d. mkdir placement

**Line 238:**
```
**Save task tree:** Create `.claude/decomposition/` if it does not exist (`mkdir -p .claude/decomposition/`). Write the full task tree...
```

The mkdir is immediately before the YAML write, inside the DECOMPOSE branch (after plan approval, before state.json update). This is the correct location -- it only runs when decomposition is chosen, and it runs before the first file write to that directory.

**Cross-check with fix-ticket:** `fix-ticket/SKILL.md` line 171 says "Save task tree to `.claude/decomposition/{ISSUE-ID}.yaml`" WITHOUT mkdir. This is the SAME gap that was fixed in implement-feature but was NOT fixed in fix-ticket. The plan acknowledges this as out-of-scope (line 152). This is NOT a bug in the fix -- it is a known gap in a different file.

### 1e. YOLO documentation accuracy

**Line 13:**
```
If `$ARGUMENTS` contains `--yolo`, activate YOLO mode: skip duplicate check (--description mode), auto-approve decomposition plan, auto-approve result display, auto-publish after successful pipeline. Note: unmapped acceptance criteria will BLOCK in YOLO mode (not skip).
```

Cross-check against actual YOLO behavior in the file:
- Skip duplicate check: Line 124 ("In YOLO mode: skip the duplicate check entirely"). ACCURATE.
- Auto-approve decomposition plan: Line 236 ("If `--yolo` -> auto-approve"). ACCURATE.
- Auto-approve result display: Line 357 ("If `--yolo` -> auto-create PR"). ACCURATE.
- Auto-publish: Same line 357. ACCURATE.
- Unmapped AC BLOCK: Line 214 ("If mode is YOLO -> Block"). ACCURATE.

**Cross-check with Rules section (line 428):**
```
Confirmation points: Step 0c (card creation, `--description` mode only), Step 5 (decomposition plan approval + AC coverage check), Step 9 (PR creation). All other steps run autonomously. `--yolo` auto-approves all except unmapped AC (which blocks).
```

This correctly enumerates the three confirmation points and YOLO's behavior on each. ACCURATE.

**FINDING (MINOR):** The preamble says "auto-approve result display" while the Rules section says "Step 9 (PR creation)." These describe the same step but with slightly different framing. Line 357 says "If `--yolo` -> auto-create PR" and Step 9 is titled "Display result." The preamble phrase "auto-approve result display" could be read as "auto-approve the display of results" (trivial) rather than "auto-approve the PR creation that follows the result display." The fix-ticket preamble (line 16) uses "Auto-publish after successful pipeline" which is clearer. This is a wording nit, not a functional issue.

**FINDING (MINOR):** Step 0c line 133: "If NOT --yolo mode: display the card preview and ask user to confirm." But the preamble does NOT mention skipping this confirmation. The preamble says "skip duplicate check" but card creation confirmation is a separate step. Actually, reading more carefully -- in YOLO mode, line 142 says "If confirmed (or --yolo): create issue in tracker." So YOLO does skip the card creation confirmation too. The preamble lists "skip duplicate check (--description mode)" but not "skip card creation confirmation (--description mode)." This is a documentation gap in the preamble -- it under-reports what YOLO skips in --description mode. However, since the Rules section at line 428 says "Step 0c (card creation, `--description` mode only)" and "`--yolo` auto-approves all", the behavior IS correctly specified in Rules.

**Correctness dimension score: 0.85** -- All field names, values, and protocol references are correct. Minor issues with `id` field assumption and one under-reported YOLO skip in the preamble.

---

## 2. Spec Alignment (weight: 0.2)

### 2a. Consistency with fix-ticket/SKILL.md

| Aspect | implement-feature | fix-ticket | Consistent? |
|--------|-------------------|------------|-------------|
| DISABLED path state write | YES (line 196) | NO (line 156 -- no state write) | NO -- known gap, out of scope |
| AUTO fallthrough state write | YES (line 243) | NO (line 158+ -- no explicit fallthrough state write) | NO -- known gap, out of scope |
| mkdir before YAML write | YES (line 238) | NO (line 171) | NO -- known gap, out of scope |
| Per-subtask status update | YES (lines 327-332) | NO (line 196 -- "Save commit_hash and restore_point to the task tree") | NO -- known gap, out of scope |
| YOLO preamble | YES (line 13) | YES (line 16) | YES |

The fix-ticket file still has all four gaps that were fixed in implement-feature. The plan explicitly acknowledges this (line 142, 152). These are NOT bugs in this fix -- they are follow-up work. But they represent a divergence between the two pipelines.

**FINDING (MEDIUM):** The fix creates a pattern asymmetry between the two primary pipeline files. An LLM executor that has seen fix-ticket's terse "Save commit_hash and restore_point to the task tree" might interpret implement-feature's more detailed Step 6h as requiring different behavior, when in fact both should behave identically. This increases the risk of inconsistent behavior if both pipelines are used in the same project.

### 2b. Match with phase-6 plan

Checking each task from `final.md`:

| Plan Task | Description | Implemented? | Matches plan? |
|-----------|-------------|-------------|---------------|
| Task 1 | SINGLE_PASS state write for DISABLED | YES (line 196) | YES |
| Task 2 | SINGLE_PASS state write for AUTO fallthrough | YES (lines 242-243) | YES |
| Task 3 | mkdir before task tree write | YES (line 238) | YES |
| Task 4 | Per-subtask status + state.json in Step 6h | YES (lines 327-332) | PARTIAL (see below) |
| Task 5 | YOLO preamble | YES (line 13) | YES |

**Task 4 deviation from plan:** The plan's "New text concept" (lines 90-98) includes explicit shell variable capture:
```
Record the commit hash: `commit_hash = $(git rev-parse HEAD)`.
Record the restore point: `restore_point = $(git rev-parse HEAD~1)`.
```

The actual implementation (lines 327-332) does NOT include these shell commands. Instead it says "Set `commit_hash` to the new commit SHA" and "Set `restore_point` to the commit SHA before this subtask (HEAD~1 or branch creation point for first subtask)." This is semantically equivalent but less explicit. An LLM executor might not know how to obtain the commit SHA without the shell command hint. However, since this is a markdown specification for an LLM (not executable code), the description-level instruction is arguably sufficient. MINOR deviation.

**Spec alignment score: 0.80** -- All five tasks implemented, minor plan deviations, known asymmetry with fix-ticket is acknowledged.

---

## 3. Robustness (weight: 0.15)

### 3a. Edge case: state.json doesn't exist yet

`core/state-manager.md` line 25: "If file does not exist, initialize from schema template." This means the new state writes will work even if called before the initial state.json creation at step 0 (MCP pre-flight). However, Step 5 runs AFTER step 0, so state.json should always exist by then. No issue.

### 3b. Edge case: .claude/decomposition/ directory already exists

`mkdir -p` is idempotent. No issue.

### 3c. Edge case: FORCE mode with no architect output

If `decompose_mode = FORCE` but the architect agent blocks (fails to produce a task tree), the flow goes to Block handler (step X). The new state writes at lines 196 and 242-243 are ONLY reached for DISABLED and AUTO-no-decompose paths, not for FORCE-but-blocked. The FORCE-blocked case sets state via the Block handler (line 417). CORRECT.

### 3d. LLM confusion risk

**FINDING (LOW):** Lines 195-196 are formatted as a single continuous paragraph:
```
If `decompose_mode = DISABLED` -> single-pass (step 6 directly).
Update `state.json`: set `decomposition.status` to "completed"...
```

The state update instruction is on the very next line with no bullet, header, or indent to visually separate it from the conditional. An LLM executor might parse this as "if DISABLED, go to step 6, and THEN update state.json" (i.e., do the update at step 6, not here) OR "update state.json regardless of the condition above." The intended reading is "if DISABLED: do both things (set state AND go to step 6)."

Compare with fix-ticket line 156: "If `decompose_mode = DISABLED` -> skip to step 4d (pre-fix hook)." -- there is no state update at all, so no ambiguity exists there (though it's a bug in fix-ticket).

The same formatting concern applies to lines 242-243 (AUTO fallthrough). These two lines are indented at the same level as the DECOMPOSE block above them, which could cause an LLM to misinterpret the scope.

**FINDING (LOW):** The Step 6h state.json instruction says "find the matching subtask in `decomposition.subtasks` by `id`." If a subtask lacks an `id` field (e.g., architect used `name` or integer index), the matching instruction fails silently. There is no fallback (e.g., "by `id`, or by array index if `id` is absent").

**Robustness score: 0.75** -- Core edge cases are handled by upstream contracts. Minor formatting ambiguity and id-matching fragility.

---

## 4. Security (weight: 0.25)

### 4a. Injection risks in markdown instructions

All new text is static specification language. There are no string interpolations in the new text that could lead to injection. The existing patterns (e.g., `{ISSUE-ID}` in file paths) are unchanged.

The `mkdir -p .claude/decomposition/` instruction is a fixed path with no user-controlled input. No injection risk.

The state.json writes use field-path notation (dot notation), not raw JSON construction. The state-manager contract handles serialization. No injection risk.

### 4b. File path traversal

The `.claude/decomposition/{ISSUE-ID}.yaml` path uses `ISSUE-ID` which comes from the issue tracker. If a tracker returns a malicious ID (e.g., `../../etc/passwd`), the path could traverse. However, this is a pre-existing pattern, not introduced by this fix. The ISSUE-ID is validated at step 0 (MCP pre-flight) which creates `.ceos-agents/{ISSUE-ID}/` -- if that succeeds without traversal, the same ID used in `.claude/decomposition/{ISSUE-ID}.yaml` is equally safe/unsafe.

### 4c. State file poisoning

No new attack surface. The state.json is written by the pipeline itself, not by external input. The subtask `id` field comes from the architect agent (internal), not from user input.

**Security score: 0.95** -- No new security risks introduced. Pre-existing ISSUE-ID path traversal concern is out of scope.

---

## 5. Devil's Advocate: Failure Scenarios

### Scenario 1: Subtask `id` field mismatch between YAML and state.json

The architect generates a task tree with subtasks. The YAML file stores subtask objects with certain field names. Step 6h says "find the matching subtask in `decomposition.subtasks` by `id`." If the architect uses a field like `task_id` or `subtask_id` instead of `id`, the matching silently fails. The subtask's `status` never gets updated to `"completed"` in state.json. Downstream, the `depends_on` check ("Verify that all depends_on have status completed") reads from the YAML file, not state.json, so the pipeline might still work -- but state.json becomes permanently stale for that subtask, breaking `/resume-ticket` and `/status` reporting.

**Likelihood:** LOW (architect agent output format is controlled by the prompt, which specifies the YAML structure at line 238).
**Impact:** MEDIUM (resume and status reporting break, but pipeline completes).

### Scenario 2: Race condition between YAML and state.json writes in Step 6h

Step 6h updates two separate files: `.claude/decomposition/{ISSUE-ID}.yaml` and `state.json`. If the pipeline crashes between the two writes (e.g., Claude session timeout), the YAML file is updated but state.json is not (or vice versa). On resume, the two stores disagree about subtask completion status.

**Likelihood:** LOW (both writes happen in the same LLM turn).
**Impact:** LOW-MEDIUM (resume logic would need to reconcile, which it currently does not explicitly handle).

### Scenario 3: DISABLED path state write executed but step 6 execution alters decomposition state

Lines 195-196 set `decomposition.decision` to `"SINGLE_PASS"` and `decomposition.status` to `"completed"` before step 6 runs. If step 6 (single-pass fixer) encounters a `NEEDS_DECOMPOSITION` signal from the fixer agent (not applicable to implement-feature, but the pattern exists in fix-ticket step 5), the decomposition state would need to be re-opened from `"completed"` back to `"in_progress"`. However, implement-feature does NOT have the NEEDS_DECOMPOSITION escape hatch (only fix-ticket does at line 235). So this scenario is NOT applicable to this file. But if someone copies this pattern to fix-ticket without awareness of NEEDS_DECOMPOSITION, the state would be prematurely marked completed.

**Likelihood:** N/A for this file (only relevant if pattern is ported to fix-ticket).
**Impact:** MEDIUM (state inconsistency if the scenario materializes).

---

## Summary

| Check | Result |
|-------|--------|
| 1a. SINGLE_PASS field names vs schema | PASS |
| 1b. Step 6h fields vs schema | PASS (minor: `id` assumption) |
| 1c. Atomic write protocol references | PASS |
| 1d. mkdir placement | PASS |
| 1e. YOLO documentation accuracy | PASS (minor: under-reports one skip) |
| 2a. Consistency with fix-ticket | KNOWN GAP (out of scope) |
| 2b. Match with phase-6 plan | PASS (minor deviation in Task 4) |
| 3a. state.json existence | PASS |
| 3b. Directory already exists | PASS |
| 3c. FORCE-blocked edge case | PASS |
| 3d. LLM confusion risk | LOW RISK |
| 4a. Injection risks | PASS |
| 4b. Path traversal | PRE-EXISTING (not introduced) |
| 4c. State poisoning | PASS |
