# Agent 3: Test-First Safety Advocate

## Philosophy

Migration must never produce a state where tests pass but the system is silently broken. Every intermediate commit must be independently valid. Assume nothing — verify everything.

---

## Decision 1: Frontmatter Strategy

Keep it minimal. Migrate `description` and `allowed-tools` as-is. Do not add new frontmatter fields speculatively — unknown fields risk silent parse failures. Add `argument-hint` only where commands already document their argument signature in prose; extract it explicitly, do not invent it. The migration itself is not the time to enrich metadata.

---

## Decision 2: File Splitting Strategy

Do not split files unless forced. Splitting is the highest-risk operation: it fragments core reference counts (breaking `core-include-refs.sh`) and multiplies the surface area for cross-reference rot. For files over 200 lines, first audit whether the length comes from inline reference content (examples, tables) that could move to a companion file in the skill directory — keeping SKILL.md as the single authoritative entrypoint. If splitting is unavoidable, the split must be reflected in test expectations *before* the split lands, not after. Never split and fix tests in the same commit.

---

## Decision 3: Cross-Reference Update Strategy

Enumerate every reference before touching a single file. The known list: 25 tests, 3 core files, CLAUDE.md, 1 docs file. Each reference must be categorized: functional (will break at runtime) or informational (will break test assertions). Update functional references first, informational last. After each category, run the full test suite. No batching across categories.

For `xref-command-count.sh` specifically: understand its grep pattern before any CLAUDE.md edit. If it greps for `commands/` as a literal string, the CLAUDE.md section update must happen atomically with the test update that adjusts the expected count.

---

## Decision 4: Test Migration Approach

Tests are the ground truth. Update test path variables (`$REPO_ROOT/commands/` → `$REPO_ROOT/skills/`) only after the corresponding skill files exist at the new paths. Never update a test to expect a file that does not yet exist — this inverts the safety guarantee.

For logic tests (`xref-command-count.sh`, `core-include-refs.sh`): read the test script source before migrating anything it touches. These tests contain embedded assumptions (file counts, grep patterns, directory variables) that are not obvious from filenames alone.

Order for each command: (1) create skill file, (2) verify test passes with both paths present, (3) delete command file, (4) verify test still passes.

---

## Decision 5: Migration Ordering

1. Update all tests to use a configurable path variable (no content changes yet) — tests still pass against `commands/`
2. Migrate one low-risk command (no cross-references, under 100 lines) as a dry run
3. Run full test suite — establish baseline
4. Migrate remaining commands in dependency order: commands referenced by other commands last
5. Update CLAUDE.md and core files simultaneously with their corresponding test assertions
6. Delete `commands/` only after 100% test pass rate on the new structure

Hard rule: no commit with a failing test. No exceptions.
