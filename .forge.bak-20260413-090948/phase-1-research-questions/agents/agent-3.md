# Agent 3 Research Output — RQ-5 and RQ-6

## RQ-5: State schema consumers of `triage.acceptance_criteria`

**Answer:**

Six files in the active codebase read or write `triage.acceptance_criteria`. No file references `ac_source` (the field does not exist yet). The field is written by three different pipelines:

1. `skills/fix-ticket/SKILL.md` — writes triage-analyst AC list
2. `skills/fix-bugs/SKILL.md` — writes triage-analyst AC list (per-bug loop)
3. `skills/implement-feature/SKILL.md` — writes spec-analyst AC list (field explicitly noted as "reused")
4. `skills/scaffold/SKILL.md` — writes total AC count (not full AC list)
5. `skills/resume-ticket/SKILL.md` — reads `triage.acceptance_criteria` to restore AC for downstream agents on resume
6. `core/fixer-reviewer-loop.md` — receives `acceptance_criteria` as an input parameter (sourced from state by the calling skill)
7. `state/schema.md:167` — defines the field (current definition has no dual-provenance note)

**Evidence (file:line):**

| File | Line(s) | Role |
|------|---------|------|
| `skills/fix-ticket/SKILL.md` | 145 | Writes `triage.acceptance_criteria` from triage-analyst output |
| `skills/fix-bugs/SKILL.md` | 121, 124 | Writes `triage.acceptance_criteria` from triage-analyst output (per-bug loop) |
| `skills/implement-feature/SKILL.md` | 180, 182 | Writes `triage.acceptance_criteria` from spec-analyst (documents "field reused") |
| `skills/scaffold/SKILL.md` | 434 | Writes total AC count to `triage.acceptance_criteria` (field reused for spec-writer phase) |
| `skills/resume-ticket/SKILL.md` | 24–25 | Reads `triage.acceptance_criteria` and `triage.complexity` to restore state on resume |
| `core/fixer-reviewer-loop.md` | 13 | Input contract includes `acceptance_criteria` list — supplied by calling skill from state |
| `state/schema.md` | 167 | Field definition: `"Full AC text items, preserved for resume."` — no dual-provenance note |

**No consumer reads `ac_source`** — the field does not exist in any file.

**Impact on plan:**

Adding `triage.ac_source` is **safe — no existing consumer will break**. The field is additive. Consumers that read `triage.acceptance_criteria` do not inspect sibling fields on the `triage` object; they pass AC directly as context strings to Task calls. The only breaking concern would be if a consumer conditionally branched on the absence of `ac_source`, which none do.

Required edits when adding `ac_source`:

1. `state/schema.md` — add `triage.ac_source` row after `triage.acceptance_criteria` row (line 167), also update `triage.acceptance_criteria` description to note dual provenance.
2. `skills/fix-ticket/SKILL.md` line 145 — add `write triage.ac_source = "triage-analyst"` alongside the existing AC write.
3. `skills/fix-bugs/SKILL.md` line 124 — add `write triage.ac_source = "triage-analyst"` alongside the existing AC write.
4. `skills/implement-feature/SKILL.md` line 182 — add `write triage.ac_source = "spec-analyst"` alongside the existing AC write.
5. `skills/scaffold/SKILL.md` line 434 — optionally add `write triage.ac_source = "spec-writer"` for the scaffold pipeline.
6. `skills/resume-ticket/SKILL.md` — no change needed (reads AC, does not branch on source).
7. `core/fixer-reviewer-loop.md` — no change needed (receives AC as parameter, does not touch state directly).

---

## RQ-6: Block-handler smoke-check invocation path in implement-feature

**Answer:**

In `skills/implement-feature/SKILL.md`, the smoke-check step is **Step 6d-smoke** (line 471). The block handler is invoked with:

```
agent = smoke-check
Step = 6d-smoke
```

This is the exact string used for the `agent` parameter in the Block handler call. The step label is `6d-smoke`.

In `skills/fix-ticket/SKILL.md`, the equivalent step is **Step 7a** (line 483). The block handler there uses:

```
agent = smoke-check
step = post-review smoke check
```

So the two pipelines use *different step label strings* for the same logical smoke-check block:
- implement-feature: `Step = 6d-smoke`
- fix-ticket: `step = post-review smoke check`

**Evidence (file:line):**

| File | Line(s) | Content |
|------|---------|---------|
| `skills/implement-feature/SKILL.md` | 471 | `#### 6d-smoke. Smoke check (build + test)` |
| `skills/implement-feature/SKILL.md` | 476 | `Block handler (step X) with agent = smoke-check, Step = 6d-smoke, Reason = Build command failed...` |
| `skills/implement-feature/SKILL.md` | 477 | `Block handler (step X) with agent = smoke-check, Step = 6d-smoke, Reason = Existing tests failed...` |
| `skills/fix-ticket/SKILL.md` | 483 | `### 7a. Smoke check (post-review)` |
| `skills/fix-ticket/SKILL.md` | 488 | `Block context: agent = smoke-check, step = post-review smoke check, detail = build error output.` |
| `skills/fix-ticket/SKILL.md` | 490 | `Block context: agent = smoke-check, step = post-review smoke check, detail = test error output.` |
| `core/block-handler.md` | 21 | Rollback trigger list: `fixer`, `reviewer`, or `test-engineer` only |
| `agents/rollback-agent.md` | 25–26 | Allowlist: `fixer`, `test-engineer`, `e2e-test-engineer`, `reviewer` |

**Key finding — rollback allowlist:**

`core/block-handler.md` line 21 triggers rollback only when `agent_name` is `fixer`, `reviewer`, or `test-engineer`. `agents/rollback-agent.md` line 26 has a matching allowlist: `fixer`, `test-engineer`, `e2e-test-engineer`, `reviewer`.

`smoke-check` is **not in either allowlist**. This is intentional — smoke-check blocks do not trigger rollback because the smoke-check runs *after* the fixer-reviewer loop has already been approved. At that point, a rollback would undo approved changes. The block is terminal — the skill proceeds to step X (block handler) without rollback.

**Impact on plan:**

If the plan adds `smoke-check` to the rollback-agent allowlist, this would be a **behavioral change** that may be undesirable:

- In implement-feature, the smoke-check (step 6d-smoke) runs after fixer↔reviewer APPROVE. Rolling back here would discard approved code.
- In fix-ticket, the smoke-check (step 7a) runs after the fixer-reviewer loop. Same concern.

The correct approach is to **not add `smoke-check` to the rollback allowlist**. If the plan is adding `smoke-check` as a new value to some other list (e.g., the `core/block-handler.md` no-rollback list for documentation clarity), that is safe and recommended. The current state is already correct — `smoke-check` is implicitly excluded from rollback by its absence from both lists.

If the plan needs to add `smoke-check` to the block-handler's explicit no-rollback documentation (step 1 of `core/block-handler.md`), the exact string to match is `smoke-check` (used as the `agent_name` value in both pipelines). The step labels differ: implement-feature uses `6d-smoke`, fix-ticket uses `post-review smoke check`.
