# Phase 8 -- Verification

## Persona

You are a QA engineer verifying the scaffold MCP chicken-and-egg fix. You check structural correctness, contract compliance, backward compatibility, and edge cases.

## Context

The implementation modified `skills/init/SKILL.md`, `skills/scaffold/SKILL.md`, and `docs/reference/skills.md`. You must verify these changes are correct, complete, and do not break anything.

## Verification Checklist

### V1: Structural Correctness

- [ ] `skills/init/SKILL.md` frontmatter is valid YAML (name, description, allowed-tools, disable-model-invocation, argument-hint)
- [ ] `skills/init/SKILL.md` argument-hint includes all 3 new params
- [ ] `skills/init/SKILL.md` has Step 0 before Step 1
- [ ] `skills/init/SKILL.md` Step 1 has conditional skip logic
- [ ] `skills/scaffold/SKILL.md` frontmatter is unchanged
- [ ] `skills/scaffold/SKILL.md` Step 0-MCP has Configure option
- [ ] `skills/scaffold/SKILL.md` Step 0-MCP YOLO mode updated
- [ ] Heading levels are consistent in both files

### V2: Backward Compatibility

- [ ] Init without `--tracker-type` still reads from CLAUDE.md (Step 1 is conditional, not deleted)
- [ ] Init `--update` flag still works
- [ ] Init Step 1b (.mcp.json.example) detection still works
- [ ] Scaffold Step 0-INFRA is unchanged
- [ ] Scaffold Step 0-MCP "Continue without" and "Abort" options are preserved
- [ ] Scaffold Step 4b-replaced (.mcp.json.example generation) is unchanged
- [ ] All existing scaffold modes (Interactive, YOLO with checkpoint, Full YOLO) still work

### V3: Contract Compliance

- [ ] No new required Automation Config sections
- [ ] No changes to core/mcp-detection.md contract
- [ ] No changes to core/config-reader.md contract
- [ ] No changes to state/schema.md
- [ ] No new agent definitions
- [ ] All 6 tracker types supported (youtrack, github, jira, linear, gitea, redmine)

### V4: Cross-Reference Integrity

- [ ] Init references `docs/reference/trackers.md` for defaults
- [ ] Scaffold references `/ceos-agents:init` (namespaced)
- [ ] Docs reference matches actual init parameter names
- [ ] No broken cross-references introduced

### V5: Edge Case Coverage

- [ ] `--tracker-type` without `--tracker-instance`: uses default from trackers.md
- [ ] `--sc-remote` alone (no tracker params): works for SC-only MCP setup
- [ ] `--tracker-type` + `--update`: update mode with override source values
- [ ] Scaffold with `--issue` + no MCP: triggers configure flow, then downgrades (issue discarded per existing Step 0-MCP step 5)
- [ ] Scaffold resume after restart: Step 0-MCP re-runs, MCP now available, continues
- [ ] Scaffold with `--infra later`: Step 0-MCP is skipped entirely (no change to this path)

### V6: Test Suite

- [ ] Run `./tests/harness/run-tests.sh` -- all existing tests pass
- [ ] New structural tests added and passing
- [ ] No test regressions

### V7: Versioning

- [ ] Verify the correct version bump level (PATCH for behavior fix, or MINOR if new optional CLI params count as a feature)
- [ ] CHANGELOG entry drafted

## Verification Process

1. Read each modified file fully
2. Compare with pre-modification versions (use git diff)
3. Run the test suite
4. Check each V1-V7 item
5. Report any failures with specific details

## Output

Write verification report to `.forge/phase-8-verify/report.md`:
- Summary: PASS/FAIL with count
- Per-section results
- Any findings that need fixing before completion
