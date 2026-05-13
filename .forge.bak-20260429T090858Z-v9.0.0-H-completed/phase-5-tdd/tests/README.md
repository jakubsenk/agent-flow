# Phase 5 TDD — Visible Test Scenarios

Forge run: `forge-2026-04-28-001` | Sub-projekt H: Agent I/O Contracts (v9.0.0)

## How to invoke

These scenarios are staged here during Phase 5. After Phase 7 copies them to `tests/scenarios/`,
invoke via the standard harness:

```bash
# Run all tests (from repo root)
./tests/harness/run-tests.sh

# Run one specific scenario
./tests/harness/run-tests.sh v9-output-contract-completeness
```

Direct invocation from this staging directory will EXIT 1 with the `.forge` REPO_ROOT guard error
by design — that guard prevents accidentally running tests against the wrong working tree.

## File list

| Scenario | Purpose | AC-H-* covered |
|----------|---------|----------------|
| `v9-output-contract-shape.sh` | Per-agent: if Output Contract present, assert Inputs + Outputs table format correct | AC-H-003, AC-H-014 |
| `v9-output-contract-completeness.sh` | Hard gate: EVERY agent must have `## Output Contract` | AC-H-001, AC-H-004 |
| `v9-output-contract-position.sh` | Assert Output Contract sits between last Process and Constraints | AC-H-002 |
| `v9-output-contract-polymorphic-split.sh` | 4 polymorphic agents must have per-phase H3 sub-blocks | AC-H-010..H-014 |
| `v9-xref-outputs-skill-references.sh` | Every backtick-quoted `## Heading` in Outputs tables must appear in ≥1 skill file | AC-H-033 |
| `v9-agents-must-be-dispatched.sh` | Every agent must be dispatched by ≥1 skill (catches orphan defect) | AC-H-034, AC-H-040 |
| `v9-frontmatter-completeness-v9-roster.sh` | 17-agent roster, 4 frontmatter fields (replaces stale 21-name scenario) | AC-H-082 |
| `v9-section-order-with-output-contract.sh` | 17-agent Goal→Expertise→Process→[Output Contract]→Constraints (replaces stale 21-name scenario) | AC-H-080, AC-H-081 |
| `v9-read-only-agents-v9-roster.sh` | 9 read-only agents no write-tool phrases (replaces stale v7 names) | AC-H-083 |
| `v9-versioning-policy-amendment.sh` | CLAUDE.md Versioning Policy has new MAJOR clause + clarification paragraph | AC-H-060, AC-H-061 |
| `v9-cross-file-invariants-amendment.sh` | CLAUDE.md Cross-File Invariants has 4 invariants (was 3) | AC-H-062, AC-H-063, AC-H-064 |
| `v9-migration-guide-exists.sh` | migration-v8-to-v9.md exists with 4 required H2 sections and content | AC-H-070..H-073 |
| `v9-plugin-version-bumped.sh` | plugin.json + marketplace.json both read "9.0.0" | AC-H-100, AC-H-101 |
| `v9-changelog-v9-entry.sh` | CHANGELOG.md has v9.0.0 entry with "Sub-projekt H" sub-section | AC-H-102 |
| `v9-customization-backward-compat.sh` | Override injector unchanged; no reserved heading collisions | AC-H-020, AC-H-120 |
| `v9-dispatch-idiom-strict.sh` | No legacy prose dispatch idiom in any skill | AC-H-050 |

## AC-H-* coverage map

All 36 spec-defined AC IDs that are bash-testable are covered:

| AC-H range | Covered by | Notes |
|------------|-----------|-------|
| AC-H-001 | v9-output-contract-completeness.sh | Hard gate |
| AC-H-002 | v9-output-contract-position.sh | Position invariant |
| AC-H-003, AC-H-014 | v9-output-contract-shape.sh | Table structure |
| AC-H-004 | v9-output-contract-completeness.sh | Reserved heading guard |
| AC-H-010..H-013 | v9-output-contract-polymorphic-split.sh | 4 polymorphic agents |
| AC-H-014 | v9-output-contract-shape.sh + polymorphic-split | Per-sub-block shape |
| AC-H-020 | v9-customization-backward-compat.sh | Injector unchanged |
| AC-H-021 | v9-customization-backward-compat.sh | Overlay still appended |
| AC-H-033 | v9-xref-outputs-skill-references.sh | Xref invariant |
| AC-H-034 | v9-agents-must-be-dispatched.sh | Orphan prevention |
| AC-H-040..H-043 | v9-agents-must-be-dispatched.sh + v9-output-contract-completeness.sh | Stack-selector deletion |
| AC-H-050 | v9-dispatch-idiom-strict.sh | Idiom harmonization |
| AC-H-060, AC-H-061 | v9-versioning-policy-amendment.sh | CLAUDE.md Versioning Policy |
| AC-H-062..H-064 | v9-cross-file-invariants-amendment.sh | 4th invariant |
| AC-H-070..H-073 | v9-migration-guide-exists.sh | Migration guide |
| AC-H-080, AC-H-081 | v9-section-order-with-output-contract.sh | Updated section-order |
| AC-H-082 | v9-frontmatter-completeness-v9-roster.sh | Updated frontmatter |
| AC-H-083 | v9-read-only-agents-v9-roster.sh | Updated read-only |
| AC-H-100, AC-H-101 | v9-plugin-version-bumped.sh | Version files |
| AC-H-102 | v9-changelog-v9-entry.sh | Changelog entry |
| AC-H-120 | v9-customization-backward-compat.sh | BC matrix |

### AC IDs covered only by hidden tests (tests-hidden/)

| AC-H | Hidden scenario | Reason held back |
|------|----------------|-----------------|
| AC-H-003 (adversarial) | v9-output-contract-malformed-cell.sh | Empty-cell edge case Phase 7 won't see |
| AC-H-004, AC-H-073 (adversarial) | v9-output-contract-collision-with-customization.sh | Collision detection validation |
| AC-H-010..H-013 (adversarial) | v9-output-contract-polymorphic-missing-phase.sh | Half-implementation catch |
| AC-H-033 (adversarial) | v9-xref-skill-with-no-agents.sh | Direction test |
| AC-H-040..H-043 (adversarial) | v9-stack-selector-deleted.sh | Comprehensive deletion check |
| REQ-H-100/H-101 (f-602b8e) | v9-deprecated-agent-name-hard-error.sh | Hard-error behavioral check |

### AC IDs not directly testable by bash

| AC-H | Reason | Indirect coverage |
|------|--------|------------------|
| AC-H-021, AC-H-110 | Manual diff protocol per design.md §8 — injector is append-only by code inspection | v9-customization-backward-compat.sh covers injector unchanged + no reserved headings |
| AC-H-103 | `git tag -l v9.0.0` — git state not inspectable as a portable harness scenario | Release process verification (manual) |
| AC-H-044 | Agent count in CLAUDE.md agents enumeration line — covered partially by v9-frontmatter-completeness-v9-roster.sh agent count check | Inspectable via CLAUDE.md grep |
| AC-H-051 | Dispatch model matches frontmatter — requires per-dispatch cross-check against frontmatter; complex Phase 8 spot-check | v9-dispatch-idiom-strict.sh ensures strict form; model values are Phase 8 manual check |
| AC-H-052 | "No agents/ paths in harmonization commit" — git history inspection | Phase 8 manual |
| AC-H-090..H-093 | Doc-count drift (README.md, docs/reference/ agent counts) — grep-based but NFR-DOC-001 scope is broad | Phase 7 Tier A tasks per design.md §9 |
| AC-H-111 | v8-*.sh scenarios still pass — runs existing harness | Phase 8 harness regression run |

## Expected v8.0.0 baseline (what FAILS now)

| Scenario | v8.0.0 outcome | Reason |
|----------|---------------|--------|
| v9-output-contract-shape.sh | SKIP | No ## Output Contract sections exist — every agent hits SKIP-guard |
| v9-output-contract-completeness.sh | FAIL | No agent has ## Output Contract |
| v9-output-contract-position.sh | SKIP | Same SKIP-guard |
| v9-output-contract-polymorphic-split.sh | SKIP | Same SKIP-guard |
| v9-xref-outputs-skill-references.sh | PASS | 0 declarations → 0 xrefs checked → trivially passes |
| v9-agents-must-be-dispatched.sh | FAIL | stack-selector.md exists with zero dispatch references |
| v9-frontmatter-completeness-v9-roster.sh | FAIL | stack-selector.md present (18 agents, not 17) |
| v9-section-order-with-output-contract.sh | FAIL | stack-selector.md present |
| v9-read-only-agents-v9-roster.sh | FAIL | stack-selector.md present |
| v9-versioning-policy-amendment.sh | FAIL | CLAUDE.md not yet amended |
| v9-cross-file-invariants-amendment.sh | FAIL | Only 3 invariants in CLAUDE.md |
| v9-migration-guide-exists.sh | FAIL | docs/guides/migration-v8-to-v9.md does not exist |
| v9-plugin-version-bumped.sh | FAIL | plugin.json reads "8.0.0" |
| v9-changelog-v9-entry.sh | FAIL | No v9.0.0 changelog entry |
| v9-customization-backward-compat.sh | PASS | Injector unchanged; no reserved headings (this is a baseline-green guard) |
| v9-dispatch-idiom-strict.sh | FAIL | 7 prose-idiom dispatch occurrences exist in v8.0.0 skills |

## Expected v9.0.0 target (all should PASS)

After Phase 7 implementation completes and tests are moved to `tests/scenarios/`, all 16 scenarios
exit 0 (PASS). The `v9-output-contract-shape.sh` SKIP-guard fires during transition only; after
all 17 agents have ## Output Contract, it exits 0.

## Design notes

1. **Polymorphic-split scenario** uses a helper function `check_polymorphic()` that extracts the
   `## Output Contract` section via awk range-match, then greps for H3 sub-block headings and
   table headers. The all-skip-77 detection uses arithmetic sum (77*4=308) to distinguish "all
   agents still at v8 baseline" from "some checked, some skipped."

2. **xref scenario** handles parameterized headings (e.g., `## Sprint Plan: {sprint_name}`) by
   stripping `{...}` tokens and grepping the prefix. Fully-variable headings (e.g., `## {Epic Title}`)
   are excluded. This resolves review finding f-1f9b7a without requiring the spec to be revised.

3. **Position scenario** anchors to the LAST `## Process` line (using `tail -1` not `head -1`),
   addressing review finding f-d2e44f for browser-agent whose Process headings are `## Process: Phase X`.

4. **v9-customization-backward-compat.sh** is intentionally GREEN on v8.0.0 (it is a baseline guard,
   not a red-phase test). Its purpose is to catch regressions: if Phase 7 accidentally breaks the
   injector or adds reserved headings to agent files, this scenario turns RED.

## Assumption flagged for reviewer

**ASSUMPTION-1 (polymorphic H3 format):** The spec (design.md §1.2) shows H3 sub-blocks titled
`### Output Contract — Phase: {name}`. The test uses literal grep for `### Output Contract — Phase: triage`
etc. If Phase 7 uses a different prefix (e.g., `### Phase: triage` without the "Output Contract"
prefix), these tests will FAIL. The spec is normative here — Phase 7 must match the literal heading.

**ASSUMPTION-2 (xref search scope):** The xref scenario searches `skills/**/SKILL.md` and files
matching `skills/**/steps/*.md`. If Phase 7 adds skill content in a differently-named subdirectory
(e.g., `skills/foo/substeps/`), the xref check may produce false negatives for headings only
referenced there. The spec's search scope (design.md §3.5) is binding.

**ASSUMPTION-3 (v9-customization-backward-compat.sh on v8.0.0):** This scenario is expected PASS
on v8.0.0 because the override injector is already unchanged and no examples use reserved headings.
If some existing example file contains `## Project-Specific Instructions`, this assumption breaks.
Current codebase scan shows no such collision.
