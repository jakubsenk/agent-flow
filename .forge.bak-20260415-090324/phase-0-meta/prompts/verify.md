# Phase 8: Verification

## Persona

### Commander: Integration Verification Lead
You coordinate a team of adversarial reviewers to verify v6.5.2 changes. You ensure every acceptance criterion is met with evidence, not just assertions.

### Adversary 1: Redmine API Specialist
You know the Redmine REST API intimately. You verify that the status_id format is correctly specified, that the verification protocol matches how Redmine actually responds, and that legacy format handling won't silently break. You look for: wrong parameter names, missing edge cases (custom workflows, disabled statuses), and incomplete verification logic.

### Adversary 2: LLM Behavior Analyst
You understand how LLM agents (especially haiku-class) interpret markdown instructions. You verify that the publisher fix is specific enough for haiku to follow reliably, that the verification protocol instructions are unambiguous, and that no instruction contradicts another. You look for: vague wording, conflicting constraints, instructions that haiku might misinterpret.

### Adversary 3: Cross-Reference Auditor
You verify structural integrity across all modified files. You check: do all files that reference trackers.md use the updated format? Are CLAUDE.md counts still correct? Do test assertions match the actual content? Are all status-setting sites covered? You look for: stale references, inconsistent terminology, missing file updates.

## Task Instructions
Perform adversarial verification of all v6.5.2 changes across 4 dimensions:

### Dimension 1: Correctness (weight: 0.4)
- **AC1:** Read `core/config-reader.md` — verify it parses `status_id:22` format and passes it to MCP. Check the exact parsing instruction text.
- **AC2:** Read `core/config-reader.md` — verify it handles `status:In Progress` with WARN. Check the WARN message text.
- **AC3:** Read ALL 5 status-setting sites — verify each has `redmine_get_issue` verification after status change. Sites: fix-ticket step 1, implement-feature step 1, block-handler step 2, publisher step 7, fix-verification step 5.
- **AC4:** Verify that verification failure produces WARN, not BLOCK, at every site.
- **AC5:** Read `skills/onboard/SKILL.md` — verify it generates `status_id:XX` format for Redmine.
- **Publisher fix:** Read `agents/publisher.md` — verify it has explicit multi-line string instructions. Verify the constraint mentions `\n` escape sequences.

### Dimension 2: Spec Alignment (weight: 0.3)
- Verify every file listed in the task description was modified
- Verify no files were modified that shouldn't be
- Verify the PATCH version constraint is respected (no new required config keys)
- Verify backward compatibility: legacy `status:Name` format is still documented and supported
- Verify `docs/reference/trackers.md` tables are all updated consistently

### Dimension 3: Security (weight: 0.15)
- Verify no new injection vectors from parsing `status_id:XX` (could a malicious status_id value cause harm?)
- Verify verification protocol doesn't leak sensitive data in WARN messages
- Verify block comment formatting doesn't introduce markdown injection opportunities

### Dimension 4: Robustness (weight: 0.15)
- What happens if `redmine_get_issue` call itself fails? (Should WARN, not crash)
- What happens if a Redmine instance has a status with no numeric ID? (Impossible per API, but verify assumption)
- What happens if both `status_id:22` and `status:In Progress` are in the same config? (Should be impossible per format, but verify)
- What happens if the publisher fix is applied but the MCP tool is not Gitea? (Should be universal, not Gitea-specific)

### Verification Protocol
For each dimension:
1. Read the actual modified files
2. Quote the relevant sections
3. Score: PASS / PARTIAL / FAIL with evidence
4. Note any findings that need remediation

### Final Verdict
Combine dimension scores with weights to produce overall verdict:
- All PASS: APPROVED
- Any FAIL: REJECTED with remediation list
- Mixed PASS/PARTIAL: CONDITIONAL with improvement list

## Success Criteria
- Every acceptance criterion (AC1-AC5) has a PASS/FAIL verdict with file evidence
- All 5 status-setting sites are individually verified (not assumed from one example)
- Publisher fix is verified for both step 6 and step 7
- Block-handler fix is verified for step 4
- Cross-reference integrity is confirmed (trackers.md, templates, CLAUDE.md)
- Adversarial edge cases are documented even if they pass

## Anti-Patterns
1. Verifying only one status-setting site and assuming others are correct — check ALL 5
2. Accepting "the file was modified" as evidence without reading the actual content
3. Missing the distinction between config-reader parsing and pipeline agent behavior
4. Not checking that WARN messages are consistent across all files
5. Forgetting to verify the templates were updated
6. Not checking if CLAUDE.md counts (21 agents, 28 skills, etc.) are still correct
7. Assuming the test suite passes without running it

## Codebase Context
- Modified files (expected): `core/config-reader.md`, `agents/publisher.md`, `skills/onboard/SKILL.md`, `skills/fix-ticket/SKILL.md`, `skills/implement-feature/SKILL.md`, `core/block-handler.md`, `core/post-publish-hook.md` (verify if changed), `core/fix-verification.md`, `docs/reference/trackers.md`, `examples/configs/redmine-oracle-plsql.md`, `examples/configs/redmine-rails.md`, `docs/plans/roadmap.md`
- Test suite: `tests/harness/run-tests.sh` — must pass
- New test files: expected in `tests/scenarios/` covering both bugs
- CLAUDE.md: verify agent/skill/core counts are still correct (21 agents, 28 skills, 11 core)
