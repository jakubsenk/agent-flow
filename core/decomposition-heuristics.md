# Decomposition Heuristics

## Purpose

Determine whether a ticket should be decomposed into subtasks before the fixer-reviewer loop begins.

> **Scope note:** This contract applies to the bug-fix pipeline only. The feature pipeline uses a different decomposition approach (architect-driven, see `skills/implement-feature/SKILL.md` Step 5).

## Input Contract

| Field | Type | Notes |
|-------|------|-------|
| decompose_flag | enum | `FORCE` / `DISABLED` / `AUTO` — from `--decompose` / `--no-decompose` flags |
| code_analyst_output | object | Fields: `risk` (LOW/MEDIUM/HIGH), `affected_files` (integer), `estimated_diff_lines` (integer), `independent_changes` (integer) |

Flag parsing from `$ARGUMENTS`:
- `--decompose` (without `--no-decompose`) → `FORCE`
- `--no-decompose` → `DISABLED`
- Neither → `AUTO`

## Process

1. If `decompose_flag = DISABLED` → return `SINGLE_PASS`.
2. If `decompose_flag = FORCE` → return `DECOMPOSE`.
3. If `decompose_flag = AUTO`: evaluate analyst impact output against thresholds (any match → DECOMPOSE):
   - `risk == HIGH`
   - `affected_files >= 4`
   - `estimated_diff_lines > 60 AND affected_files >= 3`
   - `independent_changes >= 2`
   - No threshold met → return `SINGLE_PASS`.

## Output Contract

| Result | Meaning |
|--------|---------|
| `DECOMPOSE` | Run architect agent, build task tree, execute per-subtask (see `skills/fix-bugs/SKILL.md` decomposition steps) |
| `SINGLE_PASS` | Skip decomposition, proceed directly to pre-fix hook and fixer-reviewer loop |

## Failure Handling

- Missing or incomplete `code_analyst_output` fields → treat missing numeric fields as 0, missing `risk` as LOW → default to `SINGLE_PASS` (safe fallback).
- If `decompose_flag` is unrecognised → treat as `AUTO`.
