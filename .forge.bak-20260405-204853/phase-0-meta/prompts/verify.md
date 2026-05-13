# Phase 8: Verification

## Persona
{{PERSONA}}: Senior QA Engineer and Plugin Architect specializing in cross-cutting change verification, structural validation of markdown-based plugins, and regression detection.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Verify the implementation of the Decomposition Subtask Tracker Creation feature (v6.4.0). Run comprehensive checks across all modified files to ensure correctness, consistency, and completeness.

### Verification Protocol

#### Dimension 1: Correctness (weight: 0.3)

1. **State schema correctness**
   - Read `state/schema.md` and verify `tracker_id` field exists in Subtask Object Fields table
   - Verify field type is `string or null`, default is `null`
   - Verify description mentions tracker type formats

2. **Config contract correctness**
   - Read `CLAUDE.md` and verify `Create tracker subtasks` appears in Decomposition row
   - Verify default value is `true`
   - Verify the row format is consistent with other optional section rows

3. **Step correctness (per skill)**
   For each of implement-feature, fix-ticket, fix-bugs:
   - Verify the new step exists at the correct location (after decomposition decision, before subtask execution)
   - Verify guard clause has 3 conditions (SINGLE_PASS, config false, MCP unavailable)
   - Verify all 6 tracker types are listed with correct parent-link parameters
   - Verify GitHub/Gitea checklist approach is specified
   - Verify idempotency guard checks tracker_id
   - Verify partial failure handling (WARN, never block)
   - Verify state.json update (tracker_id writeback)

#### Dimension 2: Spec Alignment (weight: 0.2)

1. **User requirements coverage**
   - Item (1): New step exists in all 3 pipelines
   - Item (2): All 6 tracker types supported with correct mechanisms
   - Item (3): Idempotence implemented (tracker_id check + title match)
   - Item (4): State schema updated with tracker_id
   - Item (5): Config key added with default true
   - Item (6): Docs updated (skills.md, pipelines.md, auto-config.md, CHANGELOG, roadmap)

2. **Pattern fidelity to scaffold Step 4e**
   - Verify the new step follows scaffold Step 4e patterns where applicable
   - Verify deviations are intentional and documented (e.g., checklist vs standalone for GitHub/Gitea)

#### Dimension 3: Robustness (weight: 0.2)

1. **Cross-skill consistency**
   - Extract the new step text from all 3 skills
   - Compare: guard clauses must be identical (except step number references)
   - Compare: tracker tables must be identical
   - Compare: idempotency guards must be identical
   - Compare: partial failure handling must be identical
   - Compare: state update patterns must be identical

2. **Edge case coverage**
   - What happens when decomposition is SINGLE_PASS? (step skipped)
   - What happens when config key is false? (step skipped)
   - What happens when MCP is unavailable? (step skipped)
   - What happens when one subtask creation fails? (WARN, continue)
   - What happens on resume with partial tracker_ids? (idempotency guard)
   - What happens for GitHub/Gitea when parent body is empty? (creates Subtasks section)

3. **Step numbering integrity**
   - Verify no existing step numbers were broken
   - Verify references to subsequent steps are updated if needed
   - Verify decomposition subtask execution still references correct step numbers

#### Dimension 4: Security (weight: 0.3)

1. **No security concerns** — pure markdown plugin, no runtime code, no credentials
2. **Verify no sensitive data in tracker issue descriptions** — subtask scope and files are not sensitive
3. **Verify no breaking changes** — config key is optional with default true

### Verification Commands

```bash
# Run full test suite
./tests/harness/run-tests.sh

# Structural checks
grep -c "Create [Tt]racker [Ss]ubtasks" skills/implement-feature/SKILL.md
grep -c "Create [Tt]racker [Ss]ubtasks" skills/fix-ticket/SKILL.md
grep -c "Create [Tt]racker [Ss]ubtasks" skills/fix-bugs/SKILL.md
grep "tracker_id" state/schema.md
grep "Create tracker subtasks" CLAUDE.md
grep "6.4.0" CHANGELOG.md
grep "6.4.0" .claude-plugin/plugin.json
```

## Success Criteria
{{SUCCESS_CRITERIA}}:
- [ ] All 4 verification dimensions pass
- [ ] Cross-skill consistency verified (no drift between 3 skills)
- [ ] All 6 user items confirmed implemented
- [ ] Test suite passes
- [ ] No regression in existing functionality
- [ ] Version is 6.4.0 in plugin.json

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT approve with surface-level checks — read the actual content
- Do NOT skip cross-skill consistency comparison
- Do NOT assume correctness from grep matches alone — verify content quality
- Do NOT skip the test suite run
- Do NOT accept broken step numbering

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Test suite: `tests/harness/run-tests.sh` (must pass)
- 3 skill files to verify: implement-feature, fix-ticket, fix-bugs
- State schema: state/schema.md Subtask Object Fields table
- Config contract: CLAUDE.md optional sections table
- Version files: .claude-plugin/plugin.json, .claude-plugin/marketplace.json
- CHANGELOG: CHANGELOG.md (v6.4.0 entry at top)
- Roadmap: docs/plans/roadmap.md (feature moved to DONE)
