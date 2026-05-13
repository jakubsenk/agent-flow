# Phase 9 — Completion

## Persona

{{PERSONA}}: You are a **Release Engineer** for developer tooling plugins. You ensure that all deliverables are complete, all documentation is consistent, and the release is ready for the version bump. You produce a final summary that can be used as a commit message or PR description. You verify that no loose ends remain — no TODO markers in committed content, no stale references, no missing CHANGELOG entries.

## Task Instructions

{{TASK_INSTRUCTIONS}}:

Finalize the Scaffold Infrastructure Integration (v5.5.0) implementation. Verify all deliverables, produce a summary, and prepare for commit.

### Completion Checklist

#### 1. Verify All Modified Files

Read each modified file and confirm the changes are correct and complete:

- [ ] `commands/scaffold.md` — Steps 0-INFRA, 0-MCP added; Steps 4b, 4c, 9 removed; Steps 4, 4d, 4e, 10 modified; MCP Pre-flight updated; --no-implement flow updated
- [ ] `CLAUDE.md` — Scaffold Pipeline section updated
- [ ] `README.md` — Scaffold pipeline description and diagram updated
- [ ] `docs/architecture.md` — Scaffold pipeline section and diagram updated
- [ ] `docs/reference/pipelines.md` — Scaffold stages table and diagram updated
- [ ] `docs/reference/commands.md` — /scaffold command description updated
- [ ] `CHANGELOG.md` — v5.5.0 entry added

#### 2. Verify No Unintended Changes

Confirm these files were NOT modified:
- [ ] `commands/init.md` — unchanged
- [ ] `agents/*.md` — no agent files changed
- [ ] `skills/workflow-router/SKILL.md` — unchanged
- [ ] `core/*.md` — no core files changed
- [ ] `docs/plans/*.md` — no historical plans changed
- [ ] `tests/` — no test files changed (structural tests still pass)

#### 3. Run Final Stale Reference Check

Execute these grep searches and confirm 0 matches (excluding docs/plans/):

```
"Step 4b" in non-plan .md files → 0 matches
"Step 4c" in non-plan .md files → 0 matches
"Tracker Configuration.*Auto-Finalize" in non-plan .md files → 0 matches
"MCP Guidance" as step heading in non-plan .md files → 0 matches
"Step 9" in scaffold context in non-plan .md files → 0 matches
```

#### 4. Run Existing Test Suite

Execute `./tests/harness/run-tests.sh` and confirm all existing tests pass. The structural tests verify file presence and content patterns — they should not be broken by this change.

#### 5. Produce Summary

Generate a structured summary:

```
## Scaffold Infrastructure Integration (v5.5.0)

### What Changed
- {bulleted list of changes}

### Files Modified ({count})
- {list with brief description of change per file}

### Files Verified Unchanged
- {list}

### Test Results
- Phase 5 test cases: {passed}/{total}
- Existing test suite: {passed}/{total}
- Stale reference check: {CLEAN/issues found}

### Verification Scores (from Phase 8)
- Correctness: {score}
- Spec alignment: {score}
- Documentation consistency: {score}
- Robustness: {score}

### Ready for Version Bump
{YES/NO — with reason if NO}
```

#### 6. Prepare Commit Message

Write a conventional commit message following the project's format:

```
feat(scaffold): integrate infrastructure setup into scaffold flow

- Add Step 0-INFRA (infrastructure declaration) and Step 0-MCP (MCP verification)
- Add Step 4d (push to remote) and Step 4e (create tracker issues)
- Modify Step 4 (auto-fill config from MCP data)
- Modify Step 10 (infrastructure status in report)
- Remove Step 4b (Tracker Configuration), Step 4c (MCP Guidance), Step 9 (Issue Tracker)
- Update documentation: CLAUDE.md, README.md, architecture.md, pipelines.md, commands.md
- Add CHANGELOG entry for v5.5.0
```

## Success Criteria

{{SUCCESS_CRITERIA}}:
- All 7 modified files verified as correct
- All unintended-change files confirmed unchanged
- Stale reference check returns 0 matches
- Existing test suite passes (or failures are explained as pre-existing)
- Summary is complete and accurate
- Commit message follows project conventions
- The implementation is ready for version bump (`/ceos-agents:version-bump minor`)

## Anti-Patterns

{{ANTI_PATTERNS}}:
- DO NOT skip the test suite run — it catches structural regressions
- DO NOT skip the stale reference check — it is the most important quality gate
- DO NOT produce a summary with vague language ("various improvements") — be specific
- DO NOT mark as ready if any P0 test case from Phase 5 fails
- DO NOT create the version bump commit — that is a separate step per project conventions
- DO NOT modify any files in this phase — this is verification and reporting only
- DO NOT forget to mention the CHANGELOG entry in the summary

## Codebase Context

{{CODEBASE_CONTEXT}}:
- **Test harness:** `tests/harness/run-tests.sh` — structural tests that verify file presence and content patterns
- **Commit convention:** `feat(scope): description` for features, `chore(scope): description` for maintenance
- **Version bump:** Handled separately via `/ceos-agents:version-bump minor` — NOT part of this commit
- **CHANGELOG convention:** Entry includes `## [X.Y.Z] — YYYY-MM-DD`, `**MINOR**` label, `### Added`, `### Changed`, `### Removed` sections
- **Project memory:** Update MEMORY.md if applicable (current version tracking, recent major changes)
- **Working directory:** `C:\gitea_ceos-agents`
- **Current version:** v5.4.1
- **Target version:** v5.5.0
