# Phase 4 Spec — Quality Review (Round 2)

**Reviewer role:** Senior Architect — Phase 5–8 downstream usability (independent, fresh eyes)
**Date:** 2026-04-27
**Round:** 2 (post Revision 1)
**Artifacts reviewed:**
- `.forge/phase-4-spec/final/requirements.md`
- `.forge/phase-4-spec/final/design.md`
- `.forge/phase-4-spec/final/formal-criteria.md`

**Criteria:**
- `.forge/phase-0-meta/prompts/spec.md` (SUCCESS_CRITERIA + ANTI_PATTERNS)
- `C:/gitea_filip-superpowers/skills/forge/review-loop-prompt.md` (Tier rubrics)

---

## Round 1 Finding Verification

All 6 Round 1 quality findings (f-a1b2c3 through f-p7q8r9) verified addressed in Revision 1:

| Round 1 Finding | Expected fix | Verified in artifact |
|----------------|-------------|----------------------|
| f-a1b2c3 — REQ-OVR-007 weak AC | AC-OVR-008 dedicated provenance-log AC | YES — AC-OVR-008 present in formal-criteria.md §2.1 with 3-case bash scenario |
| f-d4e5f6 — 26 non-pipeline skills exclusion | REQ-STEPS-001 explicit exclusion clause | YES — REQ-STEPS-001 now lists all 26 skills by name with "SHALL NOT be decomposed" clause |
| f-g7h8i9 — {total} ambiguity | Static physical file count defined | YES — REQ-MODE-007 defines {total} as "physical file count at time of SKILL.md authoring (static literal)" |
| f-j1k2l3 — step count gap in AC-DOC-008 | Step-count regex assertions added | YES — AC-DOC-008 now includes `fix-bugs[\s:(]+7\s*steps`, `implement-feature[\s:(]+7\s*steps`, `scaffold[\s:(]+8\s*steps` |
| f-m4n5o6 — symlink handling | REQ-SETUP-006 symlink escape clause | YES — REQ-SETUP-006 includes readlink -f check + [ERROR] message for symlink escape |
| f-p7q8r9 — triple-quote edge case | REQ-MIG-003 escape strategy | YES — REQ-MIG-003 covers three-way fallback: backslash-escape `""\"`, then `'''`, then single-line with `\n` |

All 6 Round 1 findings **verified addressed**.

---

## Critical Questions Assessment

### Q1: Could a TDD agent write 50+ test scenarios from formal-criteria.md alone?

**YES — comfortably.** formal-criteria.md §8 summary counts 88 ACs total. The distribution is:
- 8 AC-OVR + 8 AC-SETUP + 7 AC-STEPS + 9 AC-MODE (foundational) + 8 AC-AGT + 6 AC-MIG + 13 AC-DOC + 5 AC-INV + 5 AC-CT + 9 AC-MODE-MATRIX + 10 AC-NF = 88 ACs
- Minimum 39 scenarios from the matrix alone (5 changes × 9 combos − 6 n/a)
- AC-OVR-001..008 maps to 8 concrete bash scenario filenames
- AC-SETUP-001..008 maps to 8 concrete scenario filenames
- Phase 5 delegation notes for REQ-STEPS-003a (3 near-miss cases), REQ-MODE-008a (SIGTERM), REQ-MODE-009a (4 vague-heuristic boundaries), REQ-AGT-008 (pipeline-status dedup) are explicit

Every AC specifies verification method and scenario filename. Phase 5 TDD agent does not need to read requirements.md or design.md — formal-criteria.md is fully self-contained for test generation. **Score: 5/5.**

### Q2: Can a planning agent decompose into parallel tasks with inferable dependencies?

**YES, with one gap.** The dependency order is inferable:
- TOML overlay system is independent of agent renames (REQ-OVR-* can be implemented in parallel with REQ-AGT-*)
- Steps decomposition depends only on existing SKILL.md shape (independent)
- Mode flag framework depends on steps decomposition (REQ-MODE-004 references `steps/*.md`)
- Migration tooling depends on agent renames + TOML overlay (correct order per OQ-INT.1 RESOLVED recommendation)
- Documentation depends on all above (terminal)

**Gap (NEW — not in Round 1):** design.md Section 1.1 lists `skills/ (29 skills — was 28; +/setup-agents)` but the path shown is `fix-bugs/`, `implement-feature/`, `scaffold/` — only 3 pipelines. The ASCII diagram doesn't show `setup-agents/SKILL.md` as a sibling skill directory, which could confuse Phase 6 planner into creating the skill file at the wrong path or omitting it from the skills/ directory count task. Minor — the diagram is illustrative but the REQ (REQ-SETUP-001) correctly specifies `skills/setup-agents/SKILL.md`. **Net assessment: decomposability is good; the diagram gap is cosmetic.**

### Q3: Are REQs concrete enough for Phase 7 executor?

**YES for functional REQs; one gap identified.**

REQ-OVR-001..007: All concrete. "parse using TOML 1.0", "3-tier merge semantics per REQ-OVR-002", specific log line formats.

REQ-SETUP-002: Heuristics enumerated with 4 concrete file-presence triggers (Python: `pyproject.toml OR requirements.txt OR setup.py`; monorepo: `pnpm-workspace.yaml / turbo.json / lerna.json / nx.json / rush.json`; TypeScript: `tsconfig.json`; test framework: `jest.config.*, vitest.config.*, pytest.ini, playwright.config.*`).

REQ-MODE-007: Exact wording specified verbatim (not "something like..."). Behavioral table with case-insensitive input handling.

**New gap (NEW — not in Round 1):** REQ-STEPS-001 specifies entry SKILL.md at `≤ 120 lines (hard maximum)` but does not specify whether this line count includes or excludes comment lines, blank lines, and YAML frontmatter. The existing SKILL.md files don't have YAML frontmatter (disable-model-invocation is in frontmatter at top). AC-STEPS-001 resolves this to `wc -l` which counts all lines. However, `wc -l` counts blank lines too — a SKILL.md that is 110 lines of content + 10 blank lines between sections would still pass. This is a cosmetic ambiguity that `wc -l` resolves unambiguously. **Not a blocker — wc -l is the right approach.**

REQ-MIG-003 triple-quote escape: three fallback strategies are specified with TOML-1.0-parseable guarantee. Phase 7 executor has clear implementation path.

**Overall: REQs are executor-ready.**

### Q4: Are ACs verifiable (concrete grep/file/count) — NOT vague?

**YES — unusually concrete.** Sample check:

- AC-OVR-005: `grep` for `not_a_real_key` — literal key named in test setup. Non-zero exit code required. Exact bash scenario named.
- AC-MODE-004: "stdout SHALL contain the exact string `[step-mode] Step 02/N completed: 02-impact`" — literal regex.
- AC-AGT-001: "ls agents/*.md | sort | diff - expected.txt" — exact command.
- AC-INV-EMAIL-001: Token extraction via wide regex + per-token whitelist (strengthened over v6.9.0 domain-allowlist).
- AC-INV-PERM-001: Frontmatter extraction via awk/sed then grep — NOT full-file grep (correctly avoids false positives from prose mentions).
- AC-DOC-006: All 29 skill names listed with `/ceos-agents:` prefix — enumeration complete.

**One minor concern:** AC-MODE-004 asserts "stdout SHALL contain `[step-mode] Step 02/N completed: 02-impact`" where `N` is a literal placeholder representing the total. A Phase 5 TDD agent reading this may write a test that literally greps for `02/N` (unexpanded), which would fail. The spec intent is clear (N = 7 for fix-bugs, 8 for scaffold) but the AC text leaves `N` as a variable rather than substituting the concrete value. **Recommendation: in AC-MODE-004, replace `02/N` with `02/7` (fix-bugs-specific) since the scenario filename `v8-mode-stepmode-prompt-format.sh` implies fix-bugs context.** This is INFO severity.

### Q5: Migration risk for consuming projects (BIFITO/drmax) covered?

**YES — thoroughly.** Migration risk assessment:

1. **BIFITO config shape:** BIFITO uses fix-bugs pipeline heavily (autopilot pilot per memory). REQ-NF-001 guarantees v7 projects work without running `/migrate-config --to-v8` first. Legacy `.md` overlays parsed with WARN. Legacy stage names in Pipeline Profiles accepted with WARN. Zero-disruption guarantee for BIFITO day-1.

2. **drmax config shape:** drmax uses Redmine tracker (redmine-oracle-plsql template). The template is in `examples/configs/redmine-oracle-plsql.md` (updated per REQ-DOC-010). REQ-DOC-010 requires "Migration note: v7 → v8" callout block at top of `## Automation Config`. AC-DOC-010 verifies per-template.

3. **Scaffold mode change:** If BIFITO/drmax have scripts calling `/scaffold` and capturing output, the removal of the interactive 3-mode `a/b/c` prompt (REQ-MODE-009) is breaking for scripts that inject `a`, `b`, or `c` stdin. This is documented in CHANGELOG per REQ-DOC-013. The migration guide (REQ-DOC-001) includes scaffold mode harmonization migration table (AC-DOC-001 verifies the heading presence).

4. **State.json compatibility:** REQ-AGT-007 + REQ-NF-007 guarantee v7 state.json files are readable by v8 (additive keys only). BIFITO mid-run upgrade risk: REQ-AGT-008 explicitly handles `/pipeline-status` dedup of v7 alias + v8 key during transitional window.

5. **Agent renames in block comments:** REQ-AGT-006 explicitly covers `/resume-ticket` re-dispatch from tracker block comments that reference deprecated agent names (e.g., `Agent: triage-analyst`). Functional re-dispatch to `analyst --phase triage` — not just advisory WARN.

**Net: BIFITO and drmax migration risks comprehensively covered. Score: 5/5.**

### Q6: HIGH PRIORITY doc requirements at proper detail level?

**YES — exceptionally detailed.** Per `project_v8_doc_requirements.md` memory note: "v8.0.0 changes need MEGA thorough docs (no shortcuts)."

- REQ-DOC-001: Migration guide sections enumerated (8 specific headings in AC-DOC-001).
- REQ-DOC-002: ≥5 TOML code blocks required; per-agent key reference table for ALL 18 agents; [meta] semantics explicitly documented.
- REQ-DOC-003: ≥3 worked-example invocations with input layout + expected output per example.
- REQ-DOC-004: ≥1 step override example per pipeline (3 total) + resolution rules section.
- REQ-DOC-005: 18 agent names in EXACT ORDER with columns name/model/style/used-in-pipelines/mode-flag-or-phase-arg.
- REQ-DOC-006: 29 skill names; scaffold row explicitly updated; deprecated v7 agent names purged from other rows.
- REQ-DOC-007: "Plugin Permission Constraint" subsection with exact phrase `hooks are skill-orchestrated, not agent-frontmatter`.
- REQ-DOC-008: Diagram must show all 3 pipeline step counts; AC-DOC-008 verifies step-count literals.
- REQ-DOC-009: NEW file (not update) — pipeline.md created fresh.
- REQ-DOC-010: All 8 config templates updated; each gets migration note callout; TOML overlay referenced.
- REQ-DOC-011: `examples/customization/` directory with ≥4 files; step-override-example.md inline content (flat directory, no phantom sibling files).
- REQ-DOC-012: README counts refresh + "v8.0.0 Highlights" section + migration link.
- REQ-DOC-013: CHANGELOG v8.0.0 entry with before/after code snippets + Migration: paragraph per breaking change.
- REQ-DOC-014: CLAUDE.md content update REQ (not just verification) — covers all pipeline sections + Model Selection table.

**One new observation:** REQ-DOC-001 lists 8 mandatory section headings for the migration guide. AC-DOC-001 verifies these headings case-insensitively via bash scenario. However, none of the 8 headings explicitly covers the `--step-mode` NEW feature (which is a v8 addition, not just a migration concern). The migration guide could omit a `--step-mode` walkthrough and still pass AC-DOC-001. Users of BIFITO/drmax upgrading to v8 who want to USE `--step-mode` would need to find this in `docs/reference/pipeline.md` (REQ-DOC-009) instead. This is acceptable — REQ-DOC-004 (steps-decomposition.md) covers mode flag dispatch flow per pipeline. **INFO severity — not a gap, just cross-reference depth.**

---

## Tier 1 Evaluation

| Check | Method | Result |
|-------|--------|--------|
| Schema / format compliance | Structural section check | PASS — all 3 files present with correct structure |
| All requirements traced | Bidirectional traceability §9 | PASS — 76 REQs (post-revision) × 88 ACs; traceability index complete |
| No regressions | Not applicable (spec doc, not code) | N/A — PASS |
| Lint clean | Heading hierarchy, code blocks, identifier consistency | PASS — consistent REQ-NNN / AC-NNN format across all sections |

**Tier 1: all pass.**

Specific traceability spot-checks (Round 2):
- REQ-OVR-007 → AC-OVR-008 (new, dedicated) ✓ — Round 1 gap resolved
- REQ-STEPS-003a → traceability index entry present (`(near-miss WARN; Phase 5 scenario...)`) — Phase 5 delegation explicit
- REQ-MODE-008a → traceability index entry: `(SIGTERM/SIGINT atomicity; Phase 5 scenario ...)` — explicit delegation
- REQ-MODE-009a → AC-MODE-009 + 4 boundary scenarios listed in REQ body — Phase 5 delegation explicit
- REQ-AGT-008 → traceability: `(verification by /pipeline-status integration test; covered in TDD scenario template ...)` — explicit delegation
- REQ-MIG-003a → `AC-MIG-002 (test-engineer non-rename case + e2e sentinel; Phase 5 expands...)` — explicit
- REQ-DOC-014 → `AC-INV-DOC-ENUM-001 + AC-DOC-005 + AC-DOC-006` — cross-reference chain valid

**New REQs (REQ-STEPS-003a, REQ-MODE-008a, REQ-MODE-009a, REQ-AGT-008, REQ-MIG-003a, REQ-DOC-014) all properly traced.**

---

## Tier 3 Scoring

### Correctness: 5/5

All 76 REQs (post-revision) faithfully reflect source decisions D1–D5 + B6:
- TOML 3-tier merge is correctly specified (scalar override / array append / table deep-merge)
- Agent count arithmetic: 21 − 3 × (2→1) = 18 ✓ with explicit parenthetical formula in REQ-AGT-001
- `{total}` static-vs-dynamic resolved correctly (static literal — eliminates Windows Git Bash portability concern)
- is_vague heuristic is deterministic (word_count ≥ 20 AND ≥1 technical-term token) — two independent boolean conditions
- REQ-AGT-006 re-dispatch table (deprecated name → v8 agent + arg) is functionally correct
- REQ-MODE-008a SIGTERM atomicity: atomic write-then-rename is the correct POSIX pattern; trap-handler write prohibition is correct (races with normal-path write)
- AC-INV-PERM-001 frontmatter-only grep via awk extraction: correct approach — avoids false positives from `hooks:` in prose

No correctness errors found. **5/5.**

### Completeness: 4/5

All 8-item Phase 3 checklist items have ≥3 REQs and ≥5 ACs. Full scope coverage confirmed.

Two observations that prevent 5/5:

1. **(MINOR — new)** design.md Section 8 Documentation Deliverable Map references `REQ-DOC-009` with `AC-DOC-009` but the AC description is: "THE file `docs/reference/pipeline.md` SHALL exist AND SHALL document the entry-SKILL vs steps/*.md model AND the named-phase `Skip stages` syntax. VERIFIED BY grep + scenario." This is markedly less specific than other AC-DOC-* entries (which enumerate mandatory section headings, code block counts, etc.). A Phase 5 TDD agent writing `v8-doc-pipeline-content.sh` must infer what to grep for — there is no enumerated heading list like AC-DOC-001 has. This is the weakest AC-DOC-* entry.

2. **(INFO — new)** formal-criteria.md §8 summary row says "Section 2.7 Documentation Deliverables: 13 | REQ-DOC-001..014 (REQ-DOC-014 CLAUDE.md update verified by AC-INV-DOC-ENUM-001 + AC-DOC-005 + AC-DOC-006)". However, REQ-DOC-014 also covers the `## Scaffold Pipeline` section's removal of 3-mode prompt description and the `### Model Selection` table update — neither of which is directly verified by AC-INV-DOC-ENUM-001 (which checks agent/skill/section SET equality, not textual content of pipeline descriptions). A sufficiently motivated Phase 7 implementor could update CLAUDE.md agent counts correctly while leaving the Scaffold Pipeline section still referring to `(a) Interactive / (b) YOLO with checkpoint / (c) Full YOLO`. This textual update has no standalone verifiable AC.

**Overall: 4/5** (minor gap in AC-DOC-009 specificity + REQ-DOC-014 textual-update verification gap).

### Security: 5/5

Security coverage is comprehensive:
- **Path-traversal defense:** REQ-SETUP-006 with `readlink -f` symlink check + [ERROR] on escape (Round 1 f-m4n5o6 addressed)
- **TOML injection / unknown keys:** REQ-OVR-004 halts on unknown keys with [ERROR] + specific error message; [meta] exempt (explicitly, so no silent reject)
- **Migration atomicity:** REQ-NF-009 backup-before-modify + AC-MIG-006 tests backup failure → abort scenario
- **Prompt injection defense:** REQ-NF-004 requires prompt-injection constraint paragraph in 3 merged agents; AC-NF-004 grep-verifies
- **Plugin permission constraint:** REQ-NF-003 + AC-INV-PERM-001 frontmatter-only grep (correctly scoped — not full-file)
- **SIGTERM atomicity:** REQ-MODE-008a prevents partial state.json writes from corrupting pipeline state
- **Webhook backward compatibility:** REQ-NF-008 no field renames/removals

No security gaps. **5/5.**

### Maintainability: 5/5

- Glossary (§2) is comprehensive: 16 terms with precise definitions in Czech with English technical anchors
- REQ/AC numbering: consistent REQ-{group}-{NNN} and AC-{group}-{NNN} pattern; new `-a` suffix REQs follow convention
- Bidirectional traceability index (§9) covers all 76 REQs with primary ACs; Phase 5 delegation entries are explicitly marked
- Design.md is appropriately advisory (Implementation Notes §9 labeled "NOT mandates per REQ-NF-006")
- Counts contract table (§5) is phantom-free post-revision (AC-CT-006/007 phantom references resolved)
- Cross-reference depth: requirements.md → formal-criteria.md → design.md → source specs is navigable

The `{total}` static literal clarification eliminates the "which file governs step count?" maintenance ambiguity.

**5/5.**

### Robustness: 4/5

Strong coverage of failure modes:
- TOML syntax error → halt + [ERROR]
- Unknown TOML key → halt + [ERROR] (note: [meta] exempt)
- Backup failure → abort entire migration
- Step override near-miss → [WARN] + fall-through (not silent false override)
- SIGTERM mid-step → atomic state not advanced
- Deprecated names → functional re-dispatch + [WARN] (not just advisory)
- Empty `--step-mode` input → re-prompt (no default action)

Two observations that prevent 5/5:

1. **(MINOR — new)** AC-MODE-004 references `[step-mode] Step 02/N completed: 02-impact` with literal `N` as placeholder. A Phase 5 TDD agent may generate a scenario that greps for literal `"02/N"` string (unexpanded), causing the test to fail on correct implementation. The round-2 recommendation: replace `N` with `7` in AC-MODE-004 (fix-bugs has 7 steps per design.md §4.1) to remove the ambiguity.

2. **(INFO — new)** REQ-MIG-003 triple-quote escape has three fallback strategies in priority order: `""\"` escape → `'''` literal → single-line `\n`. However, the spec does not define which fallback to use when the content contains BOTH `"""` AND `'''` simultaneously. Reading REQ-MIG-003 carefully: "IF the content contains BOTH `"""` AND `'''`, THE skill SHALL fall back to a single-line basic string with `\n` for newlines." This IS specified — it is the third fallback. The spec is complete; this is a reading comprehension note for Phase 7 executor, not a gap.

**4/5** (one genuine ambiguity in AC-MODE-004 `N` placeholder; otherwise robust).

---

## Summary Scores

| Criterion | Weight | Score | Weighted |
|-----------|--------|-------|----------|
| Correctness | 0.30 | 5 | 1.50 |
| Completeness | 0.25 | 4 | 1.00 |
| Security | 0.20 | 5 | 1.00 |
| Maintainability | 0.15 | 5 | 0.75 |
| Robustness | 0.10 | 4 | 0.40 |
| **Weighted aggregate** | | | **4.65** |

Pass threshold: ≥ 3.5 AND no criterion below minimum (Correctness ≥ 3, Completeness ≥ 3, Security ≥ 3, Maintainability ≥ 2, Robustness ≥ 2). All minima satisfied by wide margin.

---

## Verdict JSON

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": true,
    "no_regressions": true,
    "lint_clean": true,
    "pass": true
  },
  "tier_2": {
    "fail_to_pass": null,
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true
  },
  "tier_3": {
    "correctness": 5,
    "completeness": 4,
    "security": 5,
    "maintainability": 5,
    "robustness": 4,
    "weighted_aggregate": 4.65,
    "pass": true
  },
  "overall_verdict": "PASS",
  "confidence": 0.92,
  "findings": [
    {
      "id": "f-r2a1b2",
      "severity": "MINOR",
      "criterion": "robustness",
      "location": "formal-criteria.md AC-MODE-004",
      "description": "AC-MODE-004 asserts stdout contains `[step-mode] Step 02/N completed: 02-impact` with literal `N` as a placeholder (not expanded to the concrete total for fix-bugs). A Phase 5 TDD agent generating tests/scenarios/v8-mode-stepmode-prompt-format.sh may grep for the literal string '02/N', causing a false-fail on a correct implementation that emits '02/7'. The fix-bugs pipeline has 7 steps per design.md §4.1, so the expected string is `[step-mode] Step 02/7 completed: 02-impact`.",
      "recommendation": "In AC-MODE-004, replace '`[step-mode] Step 02/N completed: 02-impact`' with '`[step-mode] Step 02/7 completed: 02-impact`' (fix-bugs context, 7 steps). Add a parenthetical: '(N=7 for fix-bugs per design.md §4.1; use pipeline-appropriate total in analogous scenarios for other pipelines)'."
    },
    {
      "id": "f-r2c3d4",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "formal-criteria.md AC-DOC-009",
      "description": "AC-DOC-009 is the weakest AC-DOC-* entry: 'THE file docs/reference/pipeline.md SHALL exist AND SHALL document the entry-SKILL vs steps/*.md model AND the named-phase Skip stages syntax. VERIFIED BY grep + scenario.' No mandatory section headings enumerated, no minimum content count specified. Compare with AC-DOC-001 which lists 8 mandatory H2 headings, or AC-DOC-002 which requires ≥5 TOML code blocks and per-agent table. A Phase 5 TDD scenario for AC-DOC-009 must infer grepping for 'entry-SKILL' and 'Skip stages' without guidance on other expected sections.",
      "recommendation": "Extend AC-DOC-009 to enumerate at least 4 mandatory section headings (e.g., `## Entry SKILL.md responsibilities`, `## Step file responsibilities`, `## Step override resolution`, `## Mode flag dispatch`, `## Named-phase Skip stages syntax`). Add a minimum content anchor: 'SHALL contain at least one code block (step file path example)'. This brings it to consistency with peer AC-DOC-* entries."
    },
    {
      "id": "f-r2e5f6",
      "severity": "INFO",
      "criterion": "completeness",
      "location": "requirements.md REQ-DOC-014 / formal-criteria.md traceability §9",
      "description": "REQ-DOC-014 requires CLAUDE.md Scaffold Pipeline section to replace 3-mode interactive prompt description with 3-flag form. This textual content update has no standalone AC verifying it. AC-INV-DOC-ENUM-001 verifies agent/skill/section SET equality across 5 files (enumeration parity) but does NOT verify prose content of pipeline sections. A Phase 8 verification that passes AC-INV-DOC-ENUM-001 could still have CLAUDE.md Scaffold Pipeline section describing the old a/b/c prompt.",
      "recommendation": "Add a grep assertion to AC-DOC-005 or create AC-DOC-014 (parallel to AC-DOC-013 for CHANGELOG): 'CLAUDE.md SHALL contain ZERO occurrences of the strings \"(a) Interactive\", \"(b) YOLO with checkpoint\", \"(c) Full YOLO\"'. Alternatively, add this as a secondary check within AC-INV-DOC-ENUM-001 Step 3 (alongside the stale count-string checks)."
    },
    {
      "id": "f-r2g7h8",
      "severity": "INFO",
      "criterion": "completeness",
      "location": "design.md §1.1 architecture diagram",
      "description": "The architecture diagram in design.md §1.1 shows `skills/ (29 skills — was 28; +/setup-agents)` in the header but the directory tree shows only fix-bugs/, implement-feature/, scaffold/ as children. The new setup-agents/ directory is not shown in the tree, which could confuse Phase 6 planner about where to create the skill file. The REQ (REQ-SETUP-001) correctly specifies skills/setup-agents/SKILL.md, but the diagram omission is a cross-reference inconsistency.",
      "recommendation": "Add `setup-agents/` entry to the skills/ directory tree in design.md §1.1, at minimum as a single line `    setup-agents/` after the 3 pipeline skill directories. Low priority — REQ is authoritative, diagram is advisory."
    }
  ]
}
```

---

## Elaboration (Czech, ≤ 300 slov)

Spec prošla Revision 1 se všemi 29 nálezy adresovanými — a to je vidět. Round 2 je čistý PASS s confidence 0.92, weighted aggregate 4.65 — výrazně nad threshold 3.5.

**Všech 6 Round 1 quality nálezů ověřeno jako opravených:** AC-OVR-008 pro REQ-OVR-007 provenance log je přítomný a konkrétní (3-case scenario: toml/md/none s literal regex). 26 non-pipeline skills explicitně jmenovitě excludovaných v REQ-STEPS-001. `{total}` statický literal v entry SKILL.md — eliminuje Windows Git Bash portability risk. AC-DOC-008 step-count asserts přidány. Symlink escape v REQ-SETUP-006. Triple-quote three-way fallback v REQ-MIG-003.

**Nové nálezy Round 2 (4 celkem):**

- **f-r2a1b2 (MINOR):** AC-MODE-004 reference `02/N` s literálním `N` placeholder — Phase 5 TDD agent může generovat grep na literal `"02/N"` místo `"02/7"`. Jednoduchá oprava: expandovat na `02/7` pro fix-bugs kontext.

- **f-r2c3d4 (MINOR):** AC-DOC-009 je výrazně méně konkrétní než ostatní AC-DOC-* entries — žádné mandatory headings, žádný minimum content count. Phase 5 scénář by měl víc na co se chytit. Doporučení: přidat 4-5 mandatory H2 headings.

- **f-r2e5f6 (INFO):** REQ-DOC-014 vyžaduje update CLAUDE.md Scaffold Pipeline sekce (odstranit popis a/b/c promptu), ale neexistuje standalone AC verifying textual content removal. AC-INV-DOC-ENUM-001 kontroluje jméno-sety, ne prose content. Oprava: přidat absence-grep pro `"(a) Interactive"`, `"(b) YOLO with checkpoint"`, `"(c) Full YOLO"`.

- **f-r2g7h8 (INFO):** design.md diagram nezobrazuje `setup-agents/` v skills/ stromu. Viz REQ-SETUP-001 pro kanonické umístění.

**Downstream fáze jsou unblocked:** Phase 5 TDD může generovat 50+ scénářů přímo z formal-criteria.md. Phase 6 planner vidí dependency order. Phase 7 executor má executor-ready REQs. Phase 8 má grep-commandy. Specification je production-ready — 2 MINOR nálezy jsou vhodné pro Phase 5 TDD task list jako enhancements.