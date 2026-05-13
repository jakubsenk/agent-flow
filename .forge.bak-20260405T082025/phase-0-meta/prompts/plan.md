# Phase 6 — Implementation Plan

## Persona
{{PERSONA}}: Senior Implementation Planner specializing in multi-file coordinated changes. Expert in dependency ordering, parallel execution opportunities, and risk-minimized edit sequences for markdown-based plugin systems.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Create a detailed implementation plan for ceos-agents v6.3.1. The plan must specify exact edits (old text → new text) for each file, ordered to minimize risk and maximize parallelism.

### Task Decomposition

```
Task 1: UNCLEAR handler in analyze-bug     [independent]
Task 2: UNCLEAR path in fix-bugs           [independent]
Task 3: Cross-stack Playwright detection    [depends on Task 5 for test validation]
Task 4: Test grep fragility fixes           [independent from Task 3 content-wise]
Task 5: Cross-stack test assertions         [depends on Task 3]
Task 6: Changelog entry                     [depends on Tasks 1-5]
Task 7: Version bump                        [depends on Task 6]
```

### Parallel Execution Groups

**Group A (can run in parallel):**
- Task 1: Edit `skills/analyze-bug/SKILL.md`
- Task 2: Edit `skills/fix-bugs/SKILL.md`

**Group B (can run in parallel after Group A):**
- Task 3: Edit `agents/scaffolder.md` (Batch 7 cross-stack detection)
- Task 4: Edit `tests/scenarios/scaffolder-e2e-batch.sh` (grep fragility fixes)
- Task 5: Edit `tests/scenarios/scaffolder-e2e-batch.sh` (new cross-stack assertions) — same file as Task 4, so serialize with Task 4

**Group C (sequential, after Group B):**
- Task 6: Add changelog entry to `CHANGELOG.md`
- Task 7: Version bump via `/ceos-agents:version-bump` skill

### Detailed Edit Plan

#### Task 1: `skills/analyze-bug/SKILL.md`
**Location:** After step 3 (line 24), before step 4 (line 25)
**Edit:** Insert step 3a — UNCLEAR handler

```markdown
3a. If triage returns UNCLEAR:
   - Instruct the triage-analyst to post a Block Comment to the issue tracker:
     ```
     [ceos-agents] 🔴 Pipeline Block
     Agent: triage-analyst
     Step: Triage
     Reason: Bug report is unclear — {specific missing information from triage quality gate}
     Detail: {quality gate failure details}
     Recommendation: Clarify the bug report and re-run /ceos-agents:analyze-bug
     ```
   - Display to user: "Bug $ARGUMENTS is UNCLEAR. Block comment posted to tracker."
   - Stop. Do NOT proceed to step 4.
```

#### Task 2: `skills/fix-bugs/SKILL.md`
**Location:** Step 2, line 108
**Edit:** Replace the UNCLEAR bullet with explicit block comment instruction

Old: `- Unclear → record as UNCLEAR, continue with next (in dry-run do not write to the issue tracker)`
New: `- Unclear → post Block Comment to issue tracker (Agent: triage-analyst, Step: Triage, Reason: unclear bug report — {quality gate failures}), record as UNCLEAR, continue with next bug. In dry-run mode: record as UNCLEAR only, do NOT write to tracker.`

#### Task 3: `agents/scaffolder.md`
**Location:** Batch 7 section (lines 67-76)
**Edit:** Replace JS-only detection with multi-ecosystem detection table and language-aware generation

#### Task 4+5: `tests/scenarios/scaffolder-e2e-batch.sh`
**Edit:** Replace fragile grep patterns + add new cross-stack assertions (see TDD phase for exact assertions)

#### Task 6: `CHANGELOG.md`
**Edit:** Add v6.3.1 entry after the v6.3.0 entry

#### Task 7: Version bump
**Action:** Run `/ceos-agents:version-bump` or manually update plugin.json + marketplace.json

### Verification Plan
1. Run `tests/harness/run-tests.sh` after all edits
2. Verify all 39+ tests pass
3. Manually verify the section-aware grep works correctly (Batch 7 only, not Batch 6)

## Success Criteria
{{SUCCESS_CRITERIA}}:
- All 4 files edited with exact changes as specified
- No edits outside the 4 specified files (plus CHANGELOG.md and version files)
- Test suite passes after all changes
- Changelog entry follows project conventions
- Version bump is PATCH (6.3.0 → 6.3.1)

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT edit agent definitions (only skill definitions and the scaffolder agent)
- Do NOT create new files
- Do NOT change the step numbering in fix-bugs (it has many cross-references)
- Do NOT add version bump to the same commit as content changes (separate commit per project convention)
- Do NOT forget to run the test suite before committing

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Commit convention: (1) content changes + changelog in same commit, (2) version-bump as separate commit, (3) tag
- Test harness: `./tests/harness/run-tests.sh`
- Version files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- CHANGELOG.md follows Keep a Changelog format
