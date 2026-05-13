# Phase 8 — Verify

## Context

All edits from the implementation plan have been applied across 10 files. This phase performs comprehensive verification.

## Verification Steps

### Step 1: Test Harness

Run the test harness and compare against baseline:

```bash
cd C:/gitea_ceos-agents && ./tests/harness/run-tests.sh
```

**Pass criteria:** Same or better pass count as baseline. No new failures.

### Step 2: Structural Integrity (per file)

For each modified file, verify:

#### Agents (5 files)

| File | Frontmatter | Section Order | Mode-Branch | Bug-Language |
|------|-------------|---------------|-------------|--------------|
| `agents/fixer.md` | name, description, model, style | Goal, Expertise, Process, Constraints | Step 1 + Step 5 | "triage analysis", "impact report", "root cause", "reproduce the bug" |
| `agents/reviewer.md` | name, description, model, style | Goal, Expertise, Process, Constraints | Step 1 + Step 4 | "bug report", "triage analysis", "impact report", "Root cause" |
| `agents/test-engineer.md` | name, description, model, style | Goal, Expertise, Process, Constraints | Step 1 + Step 3 | "bug report", "regression test" (in bug mode branch) |
| `agents/e2e-test-engineer.md` | name, description, model, style | Goal, Expertise, Process, Constraints | Step 1 | "bug report" (in bug mode branch) |
| `agents/rollback-agent.md` | name, description, model, style | Goal, Expertise, Process, Constraints | N/A | N/A |

#### Core Contracts (3 files)

| File | Purpose | Input Contract | Process | Output Contract | Failure Handling |
|------|---------|---------------|---------|----------------|-----------------|
| `core/fixer-reviewer-loop.md` | Present | Updated with discriminated union | Present | Present | Updated with implement-feature ref |
| `core/block-handler.md` | Present | Present | Updated with smoke-check | Present | Present |
| `core/decomposition-heuristics.md` | Updated with scope note | Present | Present | Updated with feature note | Present |

#### Skill (1 file)

| File | Change | Verified |
|------|--------|---------|
| `skills/implement-feature/SKILL.md` | Mode prefix in 6b, 6d, 6e | Check exact string "Mode: feature-implementation" |
| | NEEDS_DECOMPOSITION handler in 6b | Check handler has: revert, decompose_mode check, Block |
| | Step 6h compensating note | Check reviewer file:line evidence instruction |

#### State Schema (1 file)

| File | Change | Verified |
|------|--------|---------|
| `state/schema.md` | `triage.ac_source` field added | Check field definition exists |
| | `triage.acceptance_criteria` description updated | Check dual-provenance note |
| | JSON example updated | Check `ac_source: null` in example |

### Step 3: Cross-Pipeline Safety

Verify that bug-fix pipeline and scaffold pipeline are not affected:

1. **Bug-fix vocabulary check:**
   ```bash
   cd C:/gitea_ceos-agents
   grep -c "triage analysis" agents/fixer.md    # Must be >= 1
   grep -c "impact report" agents/fixer.md      # Must be >= 1
   grep -c "root cause" agents/fixer.md         # Must be >= 1
   grep -c "reproduce the bug" agents/fixer.md  # Must be >= 1
   grep -c "bug report" agents/reviewer.md      # Must be >= 1
   grep -c "bug report" agents/test-engineer.md # Must be >= 1
   grep -c "bug report" agents/e2e-test-engineer.md # Must be >= 1
   ```

2. **No removals check:**
   - `git diff` shows no lines starting with `-` that contain bug-fix vocabulary (triage analysis, impact report, root cause, bug report)
   - Exception: lines that are being replaced with expanded versions (old line removed, new line added with same content plus feature branch)

3. **Scaffold pipeline check:**
   - Verify `skills/scaffold/SKILL.md` was NOT modified
   - Verify scaffold's dispatch of fixer/reviewer (if any) does not conflict with mode-branch logic

### Step 4: Mode Signal Consistency

Verify the exact mode signal string is consistent across all files:

```bash
cd C:/gitea_ceos-agents
grep -r "Mode: feature-implementation" agents/ skills/ core/
```

Expected matches:
- `agents/fixer.md` — Step 1 mode-branch
- `agents/fixer.md` — Step 5 mode-branch
- `agents/reviewer.md` — Step 1 mode-branch
- `agents/test-engineer.md` — Step 1 mode-branch
- `agents/e2e-test-engineer.md` — Step 1 mode-branch
- `skills/implement-feature/SKILL.md` — Steps 6b, 6d, 6e

### Step 5: Smoke-Check Rollback Consistency

```bash
cd C:/gitea_ceos-agents
grep "smoke-check" core/block-handler.md agents/rollback-agent.md
```

Both files must mention `smoke-check` in their rollback trigger lists.

### Step 6: NEEDS_DECOMPOSITION Handler Completeness

Read `skills/implement-feature/SKILL.md` and verify the handler includes:
1. Authoritative revert command (`git checkout . && git clean -fd`)
2. `decompose_mode = DISABLED` check with Block
3. Already-decomposed subtask check with Block
4. Single-pass escalation to architect
5. State.json update

Compare against `skills/fix-ticket/SKILL.md` step 5 pattern for consistency.

### Step 7: Final Diff Review

```bash
cd C:/gitea_ceos-agents
git diff --stat
git diff
```

Review the full diff for:
- Unintended changes
- Formatting inconsistencies
- Missing edits from the plan
- Extra edits not in the plan

## Verdict

After all steps pass:
- **PASS:** All verification checks passed. Changes are safe to commit.
- **FAIL:** List failing checks. Identify root cause. Recommend fix.
