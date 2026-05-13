# Phase 8: Verification

## Persona

### Commander: Pipeline Hardening Verification Lead
You coordinate a team of adversarial reviewers to verify v6.7.0 changes. You ensure every acceptance criterion is met with evidence, not just assertions. You verify cross-file consistency across all 15+ modified files.

### Adversary 1: Prompt Injection Security Specialist
You specialize in LLM prompt injection attacks. You verify that the marker format is consistent across ALL files, that the NEVER constraint is present in ALL specified agents, that no agent is missing the protection, and that the markers themselves cannot be trivially bypassed. You look for: inconsistent marker text, missing agents, missing skills, marker injection vectors.

### Adversary 2: State Schema Integrity Auditor
You verify state schema changes are complete and consistent. You check that `plugin_version` appears in the schema table, the JSON example, the state-manager initialization, and resume-ticket's comparison logic. You look for: missing schema fields, incomplete JSON examples, version comparison edge cases (null version, missing plugin.json).

### Adversary 3: Cross-Reference Consistency Checker
You verify structural integrity across all modified files. You check: does CLAUDE.md say "14 shared pipeline pattern contracts"? Does `core/external-input-sanitizer.md` exist and have the correct structure? Do ALL 5 skills reference it? Do ALL 5 agents have the constraint? Does the xref-core-registry test still pass? You look for: stale counts, missing references, inconsistent terminology.

## Task Instructions
Perform adversarial verification of all v6.7.0 changes across 4 dimensions:

### Dimension 1: Security (weight: 0.3)
- Read `core/external-input-sanitizer.md` — verify it exists and defines the marker protocol
- Verify marker text is exactly `--- EXTERNAL INPUT START ---` / `--- EXTERNAL INPUT END ---`
- Read ALL 5 agents — verify EACH has the NEVER constraint with marker reference
- Read ALL 5 skills — verify EACH references `core/external-input-sanitizer.md`
- Check: could the markers be injected into issue content to confuse the LLM? (Document risk)
- Check: are there agents that receive external content but are NOT in the constraint list? (e.g., acceptance-gate, architect)

### Dimension 2: Correctness (weight: 0.3)
- Read `state/schema.md` — verify `plugin_version` is in BOTH the table and the JSON example
- Read `core/state-manager.md` — verify initialization instruction reads from `.claude-plugin/plugin.json`
- Read `skills/resume-ticket/SKILL.md` — verify version comparison is present with WARN
- Verify version comparison is major-only (not full semver)
- Verify WARN message format matches the specification
- Verify version mismatch never blocks (WARN only)

### Dimension 3: Spec Alignment (weight: 0.2)
- Verify every file listed in the task description was modified
- Verify no files were modified that shouldn't be
- Verify CLAUDE.md core count is 14 (not 13)
- Verify core contract follows existing structure (Purpose, Input, Process, Output, Failure)
- Verify agent constraint follows existing NEVER pattern
- Verify state schema field follows existing table format

### Dimension 4: Robustness (weight: 0.2)
- What happens if `.claude-plugin/plugin.json` does not exist? (state-manager should handle gracefully)
- What happens if `plugin_version` is null in state.json on resume? (resume-ticket should skip comparison)
- What happens if external content is empty? (sanitizer should pass through)
- What happens if markers appear in legitimate issue content? (Document risk level)
- Does the xref-core-registry test pass with the new core contract?
- Do both new test files pass?

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
- All 5 agents are individually verified for NEVER constraint (not assumed from one example)
- All 5 skills are individually verified for sanitizer reference
- State schema verified in both table format and JSON example
- CLAUDE.md count verified
- Cross-reference integrity confirmed (xref-core-registry test)
- Edge cases documented even if they pass

## Anti-Patterns
1. Verifying only one agent and assuming others are correct — check ALL 5
2. Accepting "the file was modified" as evidence without reading the actual content
3. Not checking the JSON example in state/schema.md (only checking the table)
4. Forgetting to verify that the core contract has ALL required sections (Purpose, Input, Process, Output, Failure)
5. Not running the test suite to confirm existing tests still pass
6. Assuming the marker format cannot be injected — document the risk explicitly

## Codebase Context
- Modified files (expected):
  - NEW: `core/external-input-sanitizer.md`
  - NEW: `tests/scenarios/prompt-injection-protection.sh`, `tests/scenarios/plugin-version-tracking.sh`
  - Modified: `agents/triage-analyst.md`, `agents/code-analyst.md`, `agents/fixer.md`, `agents/reviewer.md`, `agents/spec-analyst.md`
  - Modified: `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/resume-ticket/SKILL.md`, `skills/scaffold/SKILL.md`
  - Modified: `state/schema.md`, `core/state-manager.md`, `CLAUDE.md`, `docs/plans/roadmap.md`
- Test suite: `tests/harness/run-tests.sh` — must pass
- Existing xref-core-registry.sh test validates core count and references
- CLAUDE.md line 27 should say "14 shared pipeline pattern contracts" after changes
