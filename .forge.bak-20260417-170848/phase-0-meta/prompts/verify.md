# Phase 8: Verification — v6.7.2 Pipeline Consistency & Dedup

## Personas

### Adversarial Reviewer 1: Content Loss Hunter
{{PERSONA_1}}: You are a **content loss hunter** who obsessively verifies that refactoring operations preserve ALL original content. Your goal is to find any tracker type, edge case, or protocol detail that was lost during extraction. You diff the original inline content against the extracted contract line by line.

### Adversarial Reviewer 2: Cross-Reference Integrity Auditor
{{PERSONA_2}}: You are a **cross-reference integrity auditor** who traces every `core/*.md` reference to verify the target file exists, the referenced section exists, and the delegation provides all required inputs. You also verify that removed inline content leaves no orphaned references.

### Adversarial Reviewer 3: Behavioral Equivalence Tester
{{PERSONA_3}}: You are a **behavioral equivalence tester** who verifies that the refactored pipeline produces identical behavior to the original. You trace execution paths through the delegation to confirm that no step is skipped, no condition is lost, and no error handling path is altered.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Perform adversarial verification of all changes from Phase 7. Each reviewer independently evaluates ALL acceptance criteria.

### Verification Checklist

**WI-1: Tracker Subtask Extraction**

- [ ] `core/tracker-subtask-creator.md` contains ALL 6 tracker types (youtrack, jira, linear, redmine, github, gitea)
- [ ] Core contract contains the Jira nested sub-task guard
- [ ] Core contract contains the idempotency check (YAML-first, state.json fallback)
- [ ] Core contract contains the GitHub/Gitea checklist (post-loop sentinel check)
- [ ] Core contract contains the dual store write pattern
- [ ] Core contract contains the `core/mcp-body-formatting.md` reference
- [ ] Core contract contains the Per-Tracker Issue Creation Parameters table with all 6 rows
- [ ] Core contract contains the Issue Description Template
- [ ] Each skill provides ALL required input values in the delegation
- [ ] No inline pseudocode remains in any of the 3 skills (search for "FOR EACH subtask")
- [ ] The triple gate logic in the core contract matches the original exactly

**WI-2: Webhook Format Alignment**

- [ ] implement-feature step 10a uses `issue_id` (not `issue`)
- [ ] implement-feature step 10a uses `pr_url` (not `pr`)
- [ ] implement-feature step 10a includes `timestamp`
- [ ] implement-feature step 10a includes `--max-time 5 --retry 0`
- [ ] implement-feature step X webhook uses `issue_id` (not `issue`)
- [ ] implement-feature step X webhook includes `timestamp`
- [ ] implement-feature step X webhook includes `--max-time 5 --retry 0`
- [ ] No other webhook call sites were accidentally modified

**WI-3: Block Handler Inline Removal**

- [ ] implement-feature step X does NOT contain "Set issue state to Blocked"
- [ ] implement-feature step X does NOT contain "Add Block comment"
- [ ] implement-feature step X contains "Follow `core/block-handler.md`"
- [ ] implement-feature step X still has the state.json update instruction
- [ ] No other block handler references in fix-ticket or fix-bugs were changed

**WI-4: Doc Fixes**

- [ ] `core/fix-verification.md` title uses "Verification" (not "Fix verification")
- [ ] `core/state-manager.md` does not reference `resume-ticket.md` in Resume Process
- [ ] `state/schema.md` e2e_test has `verdict`, `result_path`, `attempts` fields with types and defaults
- [ ] `state/schema.md` has inline note about triage/code_analysis field reuse
- [ ] `core/fixer-reviewer-loop.md` lists fix-ticket, fix-bugs, implement-feature near NEEDS_DECOMPOSITION

**Cross-cutting**

- [ ] CLAUDE.md says "15 shared pipeline pattern contracts" (was 14)
- [ ] No docs/ files still reference "14 core contracts" or "14 shared pipeline pattern contracts"
- [ ] The fix-bugs contributor note comment is preserved
- [ ] No step numbers in surrounding content were inadvertently changed

### Dimension Weights

| Dimension | Weight | Focus |
|-----------|--------|-------|
| Correctness | 0.35 | Content preservation, no data loss in extraction |
| Spec alignment | 0.30 | All 12 AC met exactly as specified |
| Robustness | 0.20 | Cross-reference integrity, no orphaned references |
| Security | 0.15 | No injection vectors introduced (webhook format changes) |

## Success Criteria
{{SUCCESS_CRITERIA}}:
- All checklist items verified with evidence (grep output or file content)
- Each adversarial reviewer provides an independent PASS/FAIL verdict per AC
- Any FAIL includes exact file path, line number, and description of the issue
- Commander produces a weighted score across all dimensions

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. Rubber-stamping without actually reading the files
2. Checking only positive cases (file exists) without negative cases (inline code removed)
3. Trusting that the extraction is correct without diffing against the original
4. Skipping cross-reference verification
5. Not checking for accidental changes to unrelated sections of large files

## Codebase Context
{{CODEBASE_CONTEXT}}:
- The 3 skill files are large: verify that ONLY the targeted sections changed
- Use `grep -c` to count occurrences of patterns that should appear exactly once or zero times
- The core/tracker-subtask-creator.md should be ~180-200 lines
- Total files modified: ~10 + 1 new file
- Run existing test suite (`tests/harness/run-tests.sh`) as a regression check
