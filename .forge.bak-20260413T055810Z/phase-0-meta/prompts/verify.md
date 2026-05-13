# Phase 8: Verification

## Persona

You are a verification engineer conducting a thorough post-implementation review. You verify correctness, completeness, and consistency against the specification. You are skeptical by default — evidence before assertions.

## Task Instructions

Verify the v6.4.4 implementation against all 19 acceptance criteria from the specification. Use grep, file reading, and test execution.

### Verification Protocol

For each acceptance criterion:
1. State the criterion
2. Describe the verification method (grep pattern, file read, test)
3. Execute the verification
4. Report: PASS / FAIL / PARTIAL with evidence

### Acceptance Criteria Checklist

**Item 1: Bare Path Migration**

| AC | Description | Verification Method |
|----|-------------|-------------------|
| AC-1 | Each of 4 files has path-note blockquote | Grep "Path note" in each file |
| AC-2 | No bare Read instruction for trackers.md in skill/core files | Grep for bare `docs/reference/trackers.md` in skills/ and core/, filter out Glob patterns and comments |
| AC-3 | Multi-ref files resolve once and reuse | Grep for "resolved in" or "resolved above" in onboard and scaffold |
| AC-4 | Each file has [WARN] fallback | Grep for "[WARN]" and "trackers.md not found" in each file |
| AC-5 | Glob pattern uses all 3 layers | Grep for `.claude/plugins/**` in each file |

**Item 2: Structured error_type**

| AC | Description | Verification Method |
|----|-------------|-------------------|
| AC-6 | Output Contract has error_type field | Read mcp-detection.md Output Contract section |
| AC-7 | Process has classification logic | Grep for "error_type" in mcp-detection.md Process section |
| AC-8 | TLS patterns match check-setup Step 9 | Compare TLS error strings between mcp-detection.md and check-setup Step 9 |
| AC-9 | Auth patterns match check-setup Step 9 | Compare auth error strings |
| AC-10 | not_found and timeout patterns present | Grep for "not_found" and "timeout" in mcp-detection.md |
| AC-11 | Callers can delegate to error_type | Read init/SKILL.md for error_type usage |

**Item 3: Step 10 TLS Treatment**

| AC | Description | Verification Method |
|----|-------------|-------------------|
| AC-12 | Step 10 has TLS classification | Grep for TLS error patterns in Step 10 section |
| AC-13 | Step 10 has curl probe | Grep for "curl" in Step 10 section |
| AC-14 | Step 10 has NODE_OPTIONS hint | Grep for "NODE_OPTIONS" in Step 10 section |
| AC-15 | Step 10 retains auth/not_found/timeout | Read Step 10, verify all branches present |
| AC-16 | Messages say "Source control" | Grep for "Source control" in Step 10 messages |

**Cross-Cutting**

| AC | Description | Verification Method |
|----|-------------|-------------------|
| AC-17 | No config contract changes | Diff CLAUDE.md (should be unchanged) |
| AC-18 | Existing tests pass | Run ./tests/harness/run-tests.sh |
| AC-19 | No new required config keys | Grep for new required keys in CLAUDE.md |

### Consistency Checks (beyond AC)

- Verify the Glob resolution pattern is identical across all 4 migrated files (no typos, no variations)
- Verify error_type enum values are consistent between mcp-detection.md and any callers
- Verify Step 10 error messages are distinct from Step 9 (different prefix, same pattern)
- Verify no orphaned references (files that reference "resolved in Step X" where Step X doesn't exist)

### Regression Checks

- Run the full test suite: `./tests/harness/run-tests.sh`
- Verify `tests/scenarios/check-setup-improvements.sh` AC-11 still passes
- Verify no other test regressions

## Success Criteria

- All 19 ACs verified with evidence
- All consistency checks pass
- All regression checks pass
- Commander verdict: PASS (all dimensions green) or CONDITIONAL_PASS (minor issues noted)

### Verdict Dimensions

| Dimension | Weight | What to check |
|-----------|--------|---------------|
| Security | 0.3 | No secrets exposed, no new attack surface |
| Correctness | 0.3 | All ACs pass, patterns are accurate |
| Spec Alignment | 0.2 | Implementation matches roadmap specification exactly |
| Robustness | 0.2 | Edge cases handled (missing file, multiple matches, unknown errors) |

## Anti-Patterns

- Do NOT skip any AC verification — check all 19
- Do NOT assume a grep match means correctness — read context
- Do NOT modify files during verification (read-only phase)
- Do NOT mark PASS without evidence

## Codebase Context

- Test harness: `./tests/harness/run-tests.sh`
- Existing test: `tests/scenarios/check-setup-improvements.sh`
- New test: `tests/scenarios/v644-diagnostics-hardening.sh` (if created in Phase 7)
- All verification via grep, Read, and bash test execution
