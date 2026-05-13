# Phase 2 Research Answers — Agent 2

Date: 2026-04-13
Scope: RQ-4 (fix-bugs NEEDS_DECOMPOSITION), RQ-5 (State schema consumers), RQ-6 (smoke-check rollback)

---

## RQ-4: fix-bugs NEEDS_DECOMPOSITION — Validation and Comparison

### Phase 1 Claim to Validate
> fix-bugs has its own handler at line 434, NOT delegating to fix-ticket. Both are maintained in parallel.

**VALIDATED. Confirmed correct.**

### Evidence

#### fix-bugs handler (skills/fix-bugs/SKILL.md, lines 434–439)

```
If fixer output contains `## NEEDS_DECOMPOSITION`:
  1. Authoritative revert: git checkout . && git clean -fd (safety net — fixer's self-revert is best-effort and not guaranteed)
  2. If decompose_mode = DISABLED → Block handler (step X)
  3. If this bug has already been decomposed once → Block handler (step X)
  4. Run architect for decomposition
  5. Continue with subtask execution (step 3c)
```

Note: step 3c in fix-bugs (browser reproduction) is the numbering used for the subtask loop, confirmed by the surrounding step context. Step 5 in fix-bugs references architect decomposition continuing at step 3c (which is the subtask execution step).

#### fix-ticket handler (skills/fix-ticket/SKILL.md, lines 447–452)

```
If fixer output contains `## NEEDS_DECOMPOSITION`:
  1. Authoritative revert: git checkout . && git clean -fd (safety net — fixer's self-revert is best-effort and not guaranteed)
  2. If decompose_mode = DISABLED → Block ("Fixer needs decomposition but --no-decompose was set")
  3. If this ticket has already been decomposed once → Block ("Decomposition limit (1) reached")
  4. Run architect agent for decomposition (same as step 4b with FORCE)
  5. Continue with subtask execution (step 4c)
```

#### implement-feature handler (skills/implement-feature/SKILL.md, Step 6b, lines 445–453)

```
#### 6b. Fixer

Run the fixer agent (Task tool, model: opus):
- Context: architectural design + subtask scope + acceptance criteria
- After completion: run Build command

If build fails → fixer fixes it (max Build retries attempts).
If build still fails → proceed to step X.
```

**No NEEDS_DECOMPOSITION branch exists.** The signal falls through silently.

Also confirmed by core/fixer-reviewer-loop.md line 44:
> "NEEDS_DECOMPOSITION → returned to caller; caller handles decomposition logic (see core/decomposition-heuristics.md and skills/fix-ticket/SKILL.md step 5)."

The core contract explicitly names only fix-ticket as the reference implementation. implement-feature is not mentioned.

### Exact Differences Table

| Attribute | fix-ticket (Step 5) | fix-bugs (Step 4) | implement-feature (Step 6b) |
|-----------|--------------------|--------------------|------------------------------|
| Handler exists | YES | YES | **NO** |
| Authoritative revert step | YES: `git checkout . && git clean -fd` | YES: `git checkout . && git clean -fd` | N/A |
| DISABLED guard | YES: Block("Fixer needs decomposition but --no-decompose was set") | YES: Block handler (step X) — less specific message | N/A |
| Already-decomposed guard | YES: Block("Decomposition limit (1) reached") | YES: Block handler (step X) — less specific message | N/A |
| Architect invocation | YES: "same as step 4b with FORCE" (step 4b contains full architect logic) | YES: "Run architect for decomposition" (no reference to fix-ticket's step) | N/A |
| Continuation target | step 4c (subtask execution) | step 3c (subtask execution in fix-bugs numbering) | N/A |
| Message specificity | Specific Block messages with reason text | Generic "Block handler (step X)" | N/A |

### Key Difference: fix-ticket is more explicit
fix-ticket's handler at lines 449–450 provides specific Block reason strings:
- `"Fixer needs decomposition but --no-decompose was set"`
- `"Decomposition limit (1) reached"`

fix-bugs at lines 436–437 simply says `"Block handler (step X)"` without reason strings. This is a minor documentation gap in fix-bugs but not a functional difference.

### What implement-feature's Handler Should Look Like

The feature pipeline operates in both single-pass mode (no decomposition) and decomposition mode (multiple subtasks from architect). NEEDS_DECOMPOSITION from a feature subtask has a different semantic than from a bug:

- **In single-pass mode:** Fixer is trying to implement the full feature at once and encounters it's too large. This is analogous to fix-ticket's NEEDS_DECOMPOSITION handler — except the implement-feature pipeline ALREADY went through an architect step (Step 4). The architect already decomposed or decided SINGLE_PASS. A NEEDS_DECOMPOSITION from fixer in single-pass mode contradicts the architect's earlier SINGLE_PASS decision.
- **In decomposition mode (already decomposed subtasks):** NEEDS_DECOMPOSITION from a fixer handling a subtask signals that the subtask itself is too large. But subtasks are already architect-defined scopes. Allowing re-decomposition within a subtask is inappropriate — it would exceed the decomposition limit and create unpredictable nesting.

**Recommended handler for implement-feature Step 6b (after fixer runs):**

```
If fixer output contains `## NEEDS_DECOMPOSITION`:
  1. Authoritative revert: git checkout . && git clean -fd
  2. If already in decomposition mode (subtask loop) → Block handler (step X) with reason: "Fixer requested further decomposition within a subtask — not supported. Reduce subtask scope in architect design."
  3. If in single-pass mode:
     a. If this feature has already been decomposed once → Block ("Decomposition limit (1) reached")
     b. If decompose_mode = DISABLED → Block ("Fixer needs decomposition but --no-decompose was set")
     c. Otherwise → run architect agent for decomposition (same as step 5), continue with subtask execution (step 6 decomposition mode)
```

**Why different from fix-ticket?** The feature pipeline runs the architect BEFORE fixer. In single-pass mode (SINGLE_PASS decision at step 5), the architect already saw the full feature and decided it was single-pass. A NEEDS_DECOMPOSITION from fixer is valid only if the architect analysis was FORCE-skipped via `--no-decompose`. In practice the safest option is to **always Block in implement-feature** when fixer emits NEEDS_DECOMPOSITION, with a recommendation to re-run with `--decompose` flag or adjust the architect output.

---

## RQ-5: State Schema — Full Consumer Graph

### Phase 1 Claim to Validate
> Phase 1 found 6 consumers of acceptance_criteria. Adding ac_source is safe.

**VALIDATED AND DEEPENED. Confirmed safe. Found 8 actual consumers (some are the same file at multiple points).**

### ac_source Confirmation

Grepping `ac_source` across entire repo returns exactly 3 results — all in docs/plans files:
- `docs/plans/implement-feature-agent-audit-REVIEW.md:266` — recommended addition: "Add `triage.ac_source` field"
- `docs/plans/implement-feature-agent-audit-REVIEW.md:287` — matrix: "MEDIUM ✓ (no ac_source field)"
- `docs/plans/review-report-response.md:266` — same recommendation (duplicate file)

**`ac_source` does not exist anywhere in the schema or any skill/agent/core file. Safe to add.**

### triage.acceptance_criteria Field Definition

From `state/schema.md` line 167:
```
| `triage.acceptance_criteria` | string[] | No | `[]` | Full AC text items, preserved for resume. |
```

JSON example at line 64:
```json
"acceptance_criteria": [],
```

### Complete Consumer Graph

| File | Location | Operation | Notes |
|------|----------|-----------|-------|
| `skills/fix-ticket/SKILL.md` | Line 143, 145 | WRITE | After triage step: "write triage AC list to `triage.acceptance_criteria`" |
| `skills/fix-bugs/SKILL.md` | Line 121, 124 | WRITE | After triage: "write `triage.acceptance_criteria`" |
| `skills/implement-feature/SKILL.md` | Line 180, 182 | WRITE | After spec-analyst: "write spec-analyst AC list to `triage.acceptance_criteria`" — with comment "(field reused for spec-analyst AC)" |
| `skills/scaffold/SKILL.md` | Line 434 | WRITE | After spec-writer: "write total AC count to `triage.acceptance_criteria`" — note: writes count, not full list |
| `skills/resume-ticket/SKILL.md` | Line 24 | READ | "Triage acceptance criteria from `triage.acceptance_criteria`" — used to restore AC for downstream agents |
| `core/fixer-reviewer-loop.md` | Line 13 | READ (input contract) | `acceptance_criteria` listed as input; note says "AC list from triage-analyst output" — outdated for feature pipeline |
| `state/schema.md` | Lines 64, 167 | DEFINITION | Schema definition and description |
| `tests/scenarios/pipeline-state-writes.sh` | Lines 23, 41 | READ (test assertion) | Asserts both fix-ticket and implement-feature write `triage.acceptance_criteria` |
| `docs/plans/implement-feature-agent-audit-REVIEW.md` | Lines 185–186 | DOCUMENTATION | Notes dual provenance issue — "field reused" acknowledged but not formalized |

### WRITE consumers (would set ac_source):
1. `skills/fix-ticket/SKILL.md` — source = `"triage-analyst"`
2. `skills/fix-bugs/SKILL.md` — source = `"triage-analyst"`
3. `skills/implement-feature/SKILL.md` — source = `"spec-analyst"`
4. `skills/scaffold/SKILL.md` — source = `"spec-writer"` (also writes count instead of full list — separate issue)

### READ consumers (would use ac_source for routing/display):
1. `skills/resume-ticket/SKILL.md` — could display source in resume summary
2. `core/fixer-reviewer-loop.md` — could use source to fix outdated note "from triage-analyst output"

### Impact Assessment: Would Adding ac_source Break Anything?

**No breakage.** `triage.acceptance_criteria` is `No / []` (optional, array). Adding a sibling optional field `triage.ac_source` with a string value is a pure additive change. No consumer reads the schema strictly; all are string-matching LLM-driven agents that would simply ignore unknown fields.

Schema version stays `"1.0"` — the versioning policy (CLAUDE.md) states MAJOR applies to "breaking change in agent output format contract." Adding an optional state field with no format contract impact is at most a MINOR (new optional config/schema key). Since it's in state.json (runtime, not config contract), no version bump is required at all.

### Which consumers SHOULD write ac_source:
Only the 4 WRITE consumers above. READ consumers should not set it — they are consumers of the AC list for downstream dispatch, not the source of truth.

Recommended schema addition to `state/schema.md`:
```
| `triage.ac_source` | string or null | No | `null` | Agent that populated acceptance_criteria: "triage-analyst", "spec-analyst", or "spec-writer". |
```

---

## RQ-6: Smoke-Check Rollback — Intentional Exclusion Validation

### Phase 1 Claim to Validate
> smoke-check is INTENTIONALLY excluded from rollback triggers — adding it would be wrong.

**PARTIALLY CORRECT. The exclusion is documented behavior, but "intentional" is too strong — it is a design gap that follows from a correct principle (smoke-check blocks on code that already passed the fixer-reviewer loop), not an explicit design decision to exclude it.**

### Evidence

#### core/block-handler.md, Step 1 (lines 21–22)

```
1. **Rollback:** If the blocking agent is `fixer`, `reviewer`, or `test-engineer` → dispatch `ceos-agents:rollback-agent` (Task tool, model: haiku). Context: `Agent: {agent_name}. Step: {step_name}. Reason: {reason}. Detail: {detail}. Recommendation: {recommendation}. Execution context: CWD (no worktree).`
   Do NOT rollback on block from `triage-analyst` or `code-analyst` — no git changes to revert.
```

The block-handler only triggers rollback for: `fixer`, `reviewer`, `test-engineer`. It explicitly excludes `triage-analyst`, `code-analyst`. It does NOT mention `smoke-check` at all — neither included nor explicitly excluded.

#### agents/rollback-agent.md, Process Step 1 (lines 24–28)

```
- If the blocking agent is `triage-analyst`, `code-analyst`, `spec-analyst`, `architect`, or `stack-selector` → STOP. Do nothing.
- If the blocking agent is `fixer`, `test-engineer`, `e2e-test-engineer`, or `reviewer` → proceed with rollback.
- If the blocking agent is `publisher` → STOP. Do nothing.
- If the blocking agent is `scaffolder` → STOP. Do nothing.
```

The rollback-agent proceeds on: `fixer`, `test-engineer`, `e2e-test-engineer`, `reviewer`. **`smoke-check` is not in either list.** The rollback-agent would fall through to... nothing. There is no "else → proceed" branch — it only proceeds on explicit match.

**Practical result when smoke-check blocks:** rollback-agent receives `agent = "smoke-check"`. Step 1 checks: not in read-only list, not in execute list, not publisher, not scaffolder. The rollback-agent outputs nothing useful — effectively a silent no-op rollback.

#### implement-feature smoke-check (SKILL.md, lines 471–478)

```
#### 6d-smoke. Smoke check (build + test)

After fixer↔reviewer approval, verify the codebase still builds and existing tests pass before proceeding to test-engineer.

1. Read `Build command` and `Test command` from Automation Config.
2. Run Build command via Bash. If it fails → Block handler (step X) with `agent = smoke-check, Step = 6d-smoke, Reason = Build command failed after fixer↔reviewer approval`.
3. Run Test command via Bash. If it fails → Block handler (step X) with `agent = smoke-check, Step = 6d-smoke, Reason = Existing tests failed after fixer↔reviewer approval`.
4. Both pass → continue to step 6e.
```

The skill explicitly names `agent = smoke-check` in the block context. It calls Block handler (step X). The block handler will then call rollback-agent with `agent_name = "smoke-check"` — which has no matching case.

#### fix-ticket smoke-check (SKILL.md, lines 483–492, step 7a)

```
### 7a. Smoke check (post-review)

Run Build command and Test command from Automation Config to verify the codebase is sound after the fixer-reviewer loop.

1. Run Build command. If fails → proceed to Block handler (step X).
   Block context: agent = `smoke-check`, step = `post-review smoke check`, detail = build error output.
2. Run Test command (existing tests only — test-engineer has not run yet). If fails → proceed to Block handler (step X).
   Block context: agent = `smoke-check`, step = `post-review smoke check`, detail = test error output.
```

Same pattern in fix-ticket — `agent = smoke-check` directed to block handler.

fix-bugs smoke-check (lines 470–479, step 6a): same identical pattern.

### What SHOULD Happen When Smoke-Check Blocks?

The smoke-check fires after `fixer↔reviewer APPROVE`. The fixer has already made code changes. The reviewer approved them. The Build step (Step 6/5 in fix-ticket/fix-bugs, before reviewer) may have passed. But the post-reviewer smoke-check found a regression.

**The code is in a broken state** with fixer commits applied. Rollback IS appropriate here. The fixer's changes need to be reverted, just like a fixer block.

However, rollback-agent's step 1 would silently no-op because `smoke-check` is not in its execute list. The block comment still gets posted to the tracker (step 4 of block-handler runs regardless), but git state is NOT reverted.

**Verdict: This is a GENUINE GAP, not intentional design.**

Evidence that it is NOT intentional:
1. The block-handler says "Do NOT rollback on block from `triage-analyst` or `code-analyst` — **no git changes to revert**." The rationale given for the exclusion is "no git changes." That rationale does NOT apply to smoke-check, which runs after fixer has made changes.
2. The rollback-agent's constraint says "NEVER rollback if called after a read-only agent block (triage-analyst, code-analyst, spec-analyst, architect, stack-selector)." smoke-check is not read-only — it runs after code-modifying agents.
3. The review-report-response.md explicitly calls this out as CRQ-4 (P0 issue) in the audit: "add smoke-check to rollback trigger lists."

**The exclusion is an omission, not a design decision.**

### Fix Required

Two files need updating:

**1. core/block-handler.md, Step 1** — expand rollback trigger list:
```
If the blocking agent is `fixer`, `reviewer`, `test-engineer`, or `smoke-check` → dispatch rollback-agent.
```

**2. agents/rollback-agent.md, Process Step 1** — add smoke-check to execute list:
```
If the blocking agent is `fixer`, `test-engineer`, `e2e-test-engineer`, `reviewer`, or `smoke-check` → proceed with rollback.
```

The rationale: smoke-check blocks only after fixer has made commits. Those commits need to be reverted. The smoke-check itself makes no code changes — it is an execution agent in the sense that it verifies post-fixer state. The git state at smoke-check failure is identical to the git state at fixer failure from a rollback perspective.

### Comparison: implement-feature vs fix-ticket smoke-check

Both skills use identical behavior: `agent = smoke-check`, block handler (step X). Both have the same gap — rollback-agent receives `smoke-check` and falls through. The gap is consistent across all three pipelines (fix-ticket, fix-bugs, implement-feature).

### Final Verdict

Phase 1 claim was **partially wrong**. The exclusion is:
- **Documented behavior** (smoke-check isn't in the rollback trigger lists)
- **Not intentional design** (it is an omission — the rationale for other exclusions doesn't apply to smoke-check)
- **A genuine gap** that should be fixed: when smoke-check blocks, git state has fixer commits that need to be reverted

The correct fix is to add `smoke-check` to rollback trigger lists in both `core/block-handler.md` and `agents/rollback-agent.md`. This is a safe, targeted fix that follows the existing architecture.

---

## Summary Table

| RQ | Phase 1 Claim | Validation Result | Key Finding |
|----|---------------|-------------------|-------------|
| RQ-4 | fix-bugs has own handler, parallel maintenance | CONFIRMED | implement-feature has NO handler — undefined behavior when fixer emits NEEDS_DECOMPOSITION during feature subtask |
| RQ-5 | 6 consumers, adding ac_source safe | CONFIRMED + DEEPENED | 4 WRITE consumers (should set ac_source), 2 READ consumers. scaffold.SKILL.md writes count not full list — separate issue. Zero risk to add ac_source. |
| RQ-6 | smoke-check exclusion is intentional | PARTIALLY WRONG | Exclusion is an omission, not design intent. Rollback-agent silently no-ops when smoke-check blocks. Fix: add smoke-check to rollback trigger lists in core/block-handler.md and agents/rollback-agent.md. |
