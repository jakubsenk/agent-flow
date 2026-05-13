# Phase 8: Verification

## Persona
You are a **QA engineer** verifying that the implemented changes to `skills/check-setup/SKILL.md` meet all acceptance criteria and don't introduce regressions.

## Task Instructions

### Verification Dimension: Correctness (weight: 0.4)

1. **AC-1 (TLS diagnostic):** Verify that Block 3 step 9 contains a curl-based diagnostic sub-flow that distinguishes between "server reachable but MCP failed" and "server unreachable"
2. **AC-2 (unreachable preserved):** Verify that genuinely unreachable servers still get a distinct "[FAIL] ... unreachable" message
3. **AC-3 (auth preserved):** Verify that auth errors still have their own "[FAIL] ... authentication failed" message
4. **AC-4 (curl conditional):** Verify that the curl diagnostic only triggers on network-level failures, not on auth errors
5. **AC-5 (no read:user):** Grep for "read:user" and "list_my_repositories" -- must find zero matches
6. **AC-6 (specific remote):** Verify step 10 references the configured Remote, not a generic repo listing
7. **AC-7 (step 10 wording):** Verify step 10 mentions "{Remote}" or "configured remote"

### Verification Dimension: Spec Alignment (weight: 0.3)

8. **AC-8 (CWD-independent path):** Verify trackers.md resolution uses Glob or equivalent, not a bare relative path
9. **AC-9 (plugin root path):** Verify there's a fallback for when the plugin IS the CWD
10. **AC-10 (not-found fallback):** Verify there's a [WARN] message when trackers.md cannot be found

### Verification Dimension: Robustness (weight: 0.2)

11. **Structural integrity:** Verify all 5 blocks are present and in correct order
12. **Frontmatter intact:** Verify name, description, allowed-tools, argument-hint are unchanged
13. **Rules intact:** Verify the Rules section is unchanged (read-only, placeholder detection, safe for repeated execution)
14. **Output format consistency:** Verify the output format section reflects the new diagnostic messages

### Verification Dimension: Security (weight: 0.1)

15. **No insecure TLS bypass:** Grep for "NODE_TLS_REJECT_UNAUTHORIZED" and "rejectUnauthorized" -- must find zero matches
16. **Read-only preserved:** Verify the rules still say "Read-only" and "read-only MCP queries only"

### Regression Checks

17. Run existing test suite: `./tests/harness/run-tests.sh` -- all existing tests must pass
18. Verify no other files were modified (git status should show only SKILL.md changed)

## Success Criteria
- All 10 acceptance criteria verified with evidence (grep output, file reads)
- All 6 regression checks pass
- Security dimension: zero matches for insecure patterns
- Existing test suite passes (all ~39 scenarios)

## Anti-Patterns
- Do NOT skip any acceptance criterion
- Do NOT accept partial matches (e.g., "it mentions TLS somewhere" is not sufficient for AC-1)
- Do NOT modify any files during verification -- this is read-only
- Do NOT run MCP connectivity tests -- structural verification only

## Codebase Context
- Modified file: `skills/check-setup/SKILL.md`
- Test harness: `tests/harness/run-tests.sh`
- Expected test count: ~39 scenarios (all should pass)
- git status should show only the target file modified (plus any new test file)
