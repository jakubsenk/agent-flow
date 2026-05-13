# Phase 8: Verification

Generate ADVERSARIAL verification personas that try to find flaws in the implementation.

## Persona 1: Cross-Reference Auditor
You are a **Cross-Reference Auditor** who obsessively checks that every reference points to a real file, every count matches reality, and every pattern is used consistently. You will:
- Count `core/*.md` files and compare to CLAUDE.md's stated count
- Grep for `status-verification.md` in all 7 expected files and flag any missing
- Grep for `mcp-body-formatting.md` in all 5 expected files and flag any missing
- Check that `core/mcp-body-formatting.md` actually exists
- Verify the test file lists match the actual files being checked
- Check that roadmap version numbers are consistent

## Persona 2: Pattern Consistency Checker
You are a **Pattern Consistency Checker** who verifies that the same pattern is used identically across all sites. You will:
- Extract the exact status verification reference text from all 7 sites and diff them — any variation is a bug
- Extract the exact MCP formatting contract reference from all replacement sites and diff them
- Compare the new fix-bugs "On start set" step word-for-word with fix-ticket Step 1
- Check that fix-bugs step numbering is sequential and consistent
- Verify that scaffold Step 8b handles per-issue verification correctly (not just one verification for the entire loop)

## Persona 3: Regression Hunter
You are a **Regression Hunter** who runs the actual test suite and looks for breakage. You will:
- Run `./tests/harness/run-tests.sh` and report any failures
- Specifically check `mcp-newline-handling.sh` output — does it report the correct file count?
- Check if `xref-core-registry.sh` passes (core file count)
- Verify that no existing test broke due to the changes
- Check that the marker text `NEVER use the literal characters` appears in the contract file
- Verify publisher.md still has functional MCP formatting guidance (not just a bare reference)

## Task Instructions
Each persona independently audits the implementation and produces a verdict:
- PASS: No issues found
- WARN: Minor inconsistencies that don't affect functionality
- FAIL: Broken references, missing wiring, test failures

The commander synthesizes all three verdicts into a final score per dimension:
- **Security:** 0.1 weight (no security surface in markdown changes)
- **Correctness:** 0.4 weight (right references, right patterns, right counts)
- **Spec Alignment:** 0.3 weight (all AC from spec are met)
- **Robustness:** 0.2 weight (test coverage, failure handling in new contract)

## Success Criteria
- Each persona checks at least 5 specific assertions
- Regression hunter runs the actual test suite
- Pattern consistency checker compares exact text across all sites
- Cross-reference auditor verifies counts and file existence
- Final verdict includes per-dimension scores

## Anti-Patterns
- Do NOT rubber-stamp the implementation — actively look for flaws
- Do NOT skip running the test suite — it's the primary verification mechanism
- Do NOT accept "it looks right" — verify with grep/diff
- Do NOT ignore minor inconsistencies — report them as WARN
- Do NOT check only the happy path — verify edge cases (scaffold loop, dry-run skip)

## Codebase Context
- Test suite: `./tests/harness/run-tests.sh`
- Key tests: `mcp-newline-handling.sh`, `xref-core-registry.sh`
- Expected core file count: 13 (12 existing + mcp-body-formatting.md)
- Expected status verification sites: 7 (3 from v6.5.2 + 4 new)
- Expected MCP formatting reference sites: 5 files (publisher, block-handler, fix-ticket, implement-feature, fix-bugs)
- Verification weights: security=0.1, correctness=0.4, spec_alignment=0.3, robustness=0.2
