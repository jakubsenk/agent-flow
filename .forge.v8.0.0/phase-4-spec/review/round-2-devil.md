# Phase 4 Spec — Devil's Advocate Review (Round 2)

**Reviewer role:** Adversarial — independent re-examination from scratch
**Date:** 2026-04-27
**Round 1 weighted aggregate:** 2.95 (FAIL — 3 BLOCKERs, 9 MAJORs, 5 MINORs, 2 NITs)
**Artifacts reviewed (current state after revision-1):**
- `.forge/phase-4-spec/final/requirements.md`
- `.forge/phase-4-spec/final/design.md`
- `.forge/phase-4-spec/final/formal-criteria.md`

**Round 2 protocol:** Re-examine independently. Do NOT carry forward Round 1 findings. Check each Round 1 issue afresh. Compute finding IDs and check for stuck-loop semantics per stopping criterion #2.

---

## Round 1 Fix Verification (rapid-scan, no carry-forward)

Before adversarial new findings, I verify each Round 1 finding was genuinely resolved:

| R1 ID | Issue | Status in current spec |
|-------|-------|------------------------|
| f-a1b2c3 (BLOCKER) | `[meta]` table undefined keys | FIXED — REQ-OVR-003 now declares `[meta]` as "free-form table — all sub-keys accepted without validation... EXEMPT from unknown-key rejection." AC-DOC-002 verifies the exemption is documented. |
| f-b3c4d5 (BLOCKER) | `{total}` ambiguous for conditional steps | FIXED — REQ-MODE-007 now defines `{total}` as "physical file count at SKILL.md authoring (static literal, NOT runtime scan)"; conditional steps ARE counted; counter skips NN when step not triggered. |
| f-c5d6e7 (BLOCKER) | Silent step override near-miss | FIXED — REQ-STEPS-003a is a new full requirement covering zero-padding, case-fold, underscore-hyphen near-miss, with WARN log and fall-through to default. |
| f-d7e8f9 (MAJOR) | idempotent-regen vs preview-prompt contradiction | FIXED — REQ-SETUP-004 now says "idempotent regen IS subject to the preview prompt, NOT auto-applied"; REQ-SETUP-005 says preview requirement applies uniformly to all write paths. |
| f-e9f0a1 (MAJOR) | test-engineer non-rename case unspecified | FIXED — REQ-MIG-003a added with explicit handling: test-engineer.md → normal conversion; e2e-test-engineer.md → merged into test-engineer.toml with `[applies-when --e2e=true]` sentinel. |
| f-f1a2b3 (MAJOR) | /pipeline-status reader logic undefined | FIXED — REQ-AGT-008 added with full 4-case deduplication logic including WARN for inconsistent values. |
| f-c4d5e6 (MAJOR) | `//` comment injection into Markdown table | FIXED — REQ-MIG-002 step 4 now specifies HTML comment `<!-- migrated v7→v8 by /migrate-config -->` placed "on its own line **immediately ABOVE the `### Pipeline Profiles` heading**". |
| f-d6e7f8 (MAJOR) | Ctrl+C / SIGTERM atomicity unspecified | FIXED — REQ-MODE-008a added with 4 sub-bullets: atomic write-to-temp+rename, last_completed_step not advanced on interrupt, re-execution on resume, prohibition on trap-handler state writes. |
| f-e8f9a0 (MAJOR) | CLAUDE.md update target missing | FIXED — REQ-DOC-014 added covering CLAUDE.md Architecture section, all pipeline descriptions, Scaffold Pipeline section, and Model Selection table. |
| f-f0a1b2 (MAJOR) | brainstorm heuristic unspecified | FIXED — REQ-MODE-009a provides full formal specification with regex patterns, word count condition, technical-term condition, and 4 boundary scenarios. |
| f-a2b3c4 (MAJOR) | pipeline.md CREATE vs UPDATE ambiguity | FIXED — REQ-DOC-009 now says "SHALL contain a NEW file" with explicit verification note "(verified via filesystem inspection on 2026-04-27 to NOT exist)". |
| f-b4c5d6 (MAJOR) | email whitelist domain-allowlist weakness | FIXED — AC-INV-EMAIL-001 now uses token extraction + per-token whitelist check covering all TLDs and subdomains. |
| f-c6d7e8 (MAJOR) | /scaffold row description stale | FIXED — REQ-DOC-006 now explicitly requires /scaffold row to NOT reference interactive a/b/c prompt and SHALL describe flag-based modes. |
| f-d8e9f0 (MINOR) | frontmatter-extraction missing from grep | FIXED — AC-INV-PERM-001 specifies frontmatter extraction via awk or sed before running grep; grep runs ONLY on extracted frontmatter block. |
| f-e0f1a2 (MINOR) | line limit 150 vs design intent 120 | FIXED — AC-STEPS-001 now specifies ≤ 120 lines with explicit reasoning; 120 is the hard max matching design intent. |
| f-f2a3b4 (MINOR) | no AC for REQ-OVR-007 provenance log | FIXED — AC-OVR-008 added as dedicated provenance-log AC with 3-run scenario (toml-only / md-only / no-overlay). |
| f-a4b5c6 (MINOR) | /resume-ticket re-dispatch mapping missing | FIXED — REQ-AGT-006 now has full mapping table and explicit language about dispatching v8 merged agent. |
| f-b6c7d8 (MINOR) | step-override-example sibling placeholder ambiguous | FIXED — REQ-DOC-011 now explicitly says "NO sibling placeholder file SHALL be required" with inline-content approach specified. |
| f-c8d9e0 (MINOR) | AC-CT-002 lacks `*/steps/*` exclusion | FIXED — AC-CT-002 now uses `-not -path '*/steps/*'` with explicit rationale. |
| f-d1e2f3 (MINOR) | mode flag mutual exclusion pseudocode misleading | FIXED — design.md Section 5.1 now shows explicit GOT_YOLO/GOT_STEP_MODE boolean flags with rationale. |
| f-e3f4a5 (NIT) | line number optional — AC gap | FIXED — REQ-OVR-004 now parenthetical "(line number is OPTIONAL because some TOML 1.0 parsers do not surface line numbers; AC verification of the line-number conditional is per AC-OVR-004)". |
| f-a6b7c8 (NIT) | count arithmetic ambiguous | FIXED — REQ-AGT-001 now contains explicit formula "(formula: each merge eliminates 1 net agent — 2 old agents collapse into 1 new agent = −1 per merge × 3 merges = −3 total; 21 − 3 = 18)". |

**All 22 Round 1 findings verified as addressed.** No stuck-loop signal detected.

---

## Verdict

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
    "correctness": 4,
    "completeness": 4,
    "security": 4,
    "maintainability": 4,
    "robustness": 3,
    "weighted_aggregate": 3.90,
    "pass": true
  },
  "overall_verdict": "PASS",
  "confidence": 0.85,
  "findings": [
    {
      "id": "f-r2a1b2",
      "severity": "MINOR",
      "criterion": "robustness",
      "location": "requirements.md REQ-SETUP-006 vs REQ-NF-005",
      "description": "REQ-SETUP-006 mandates symlink escape detection using '`readlink -f` or equivalent'. REQ-NF-005 requires all test scenarios to run on POSIX bash, Git Bash (Windows MINGW), AND macOS bash 3.2 without errors. On macOS with the system bash 3.2 and standard BSD coreutils, `readlink -f` is NOT available — it is a GNU coreutils extension. The 'or equivalent' qualifier delegates resolution to Phase 6, but no equivalent is named. The bash scenario `tests/scenarios/v8-setup-agents-scope.sh` (AC-SETUP-008) must implement this check portably. Phase 5 TDD may not account for this gap when generating the scenario template.",
      "recommendation": "Amend REQ-SETUP-006 to specify the portable fallback: 'WHEN `readlink -f` is unavailable (macOS without GNU coreutils), THE skill SHALL use `python3 -c \"import os,sys; print(os.path.realpath(sys.argv[1]))\"` as equivalent, or SHALL detect the platform and skip symlink verification with a `[WARN]` log \"Symlink escape detection skipped: readlink -f not available on this platform.\"' This removes the Phase 6 ambiguity and satisfies REQ-NF-005."
    },
    {
      "id": "f-r2b3c4",
      "severity": "MINOR",
      "criterion": "robustness",
      "location": "requirements.md REQ-MODE-009a — regex portability vs REQ-NF-005",
      "description": "REQ-MODE-009a specifies formal regex patterns for the vague-description heuristic that use `\\b` (word boundary anchor) and `(?:^|\\s)` look-around syntax. The `\\b` word boundary is NOT defined in POSIX ERE (IEEE Std 1003.1). While GNU grep, bash 4.x `[[ =~ ]]`, and most modern implementations support `\\b`, BusyBox (embedded Linux) and macOS bash 3.2 (which REQ-NF-005 requires support for) do NOT guarantee `\\b` in ERE mode. Phase 5 TDD will generate test scenarios using these regex patterns in bash `[[ =~ ]]` or grep -E; if run on macOS bash 3.2 or BusyBox, the patterns may silently fail to match (treating `\\b` as a literal 'b' or producing parse errors). The 4 required boundary scenarios (REQ-MODE-009a sub-bullets) would produce false test results on these platforms.",
      "recommendation": "Add a portability note to REQ-MODE-009a: 'Phase 5 TDD scenario implementations SHALL test the heuristic via the plugin's natural invocation path (skill dispatch), NOT by directly evaluating the regex in bash ERE. Direct regex tests using `\\b` in `[[ =~ ]]` SHALL include a guard: `if [[ $(bash --version | head -1) =~ version\\ [4-9] ]]; then ... fi` OR SHALL implement `\\b` as `(^|[^[:alnum:]_])` for portable ERE replacement.' Alternatively, specify that the regex is evaluated by the plugin's chosen TOML-parser runtime (Python/Node/etc.) which has full PCRE support, making POSIX portability of the bash scenario irrelevant for the regex test itself."
    },
    {
      "id": "f-r2c5d6",
      "severity": "MINOR",
      "criterion": "correctness",
      "location": "formal-criteria.md AC-INV-DOC-ENUM-001 — intersection semantics",
      "description": "AC-INV-DOC-ENUM-001 states: 'agent_set ∩ across all 5 files == EXACT set of 18 names... (allowing files that don't enumerate agents at all to opt out, e.g., skills.md may legitimately not list agents — the union check applies only to files that DO present agent tables).' The set-intersection (∩) operator is logically incorrect here: if any of the 5 files does NOT enumerate agents (i.e., its agent set is empty or absent), the intersection of sets across all 5 files would be ∅ (empty set). The 'opt-out' caveat contradicts the intersection operator. The correct logical operation is: 'FOR EACH file in the 5 that DOES enumerate agents in tabular form, the extracted name set SHALL equal the canonical 18-name set.' The verification scenario `tests/scenarios/v8-invariant-doc-enumeration-parity.sh` must decide how to detect which files 'enumerate agents' — this heuristic is left entirely to the scenario author, making the AC non-deterministic. A Phase 8 verification agent could interpret the 'opt-out' differently than Phase 5 TDD.",
      "recommendation": "Replace the ∩ formulation with an explicit per-file assertion: 'WHEN a file in the 5-file set contains any Markdown table with a row matching an agent name pattern `^\\|\\s*(analyst|fixer|reviewer|...)`, THEN the complete set of agent names extracted from all such tables in that file SHALL equal exactly the 18-name canonical set.' Add a per-file exclusion table to the AC: 'skills.md: does NOT enumerate agents (verified by grep — skip); docs/reference/agents.md: MUST enumerate all 18 (verified by extraction + diff).' This makes the AC deterministic."
    },
    {
      "id": "f-r2d7e8",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "formal-criteria.md — missing AC for REQ-NF-001 legacy Skip stages backward compat",
      "description": "REQ-NF-001 states v8.0.0 SHALL operate correctly on v7.0.0 projects WITHOUT requiring /migrate-config --to-v8 first, citing REQ-MIG-006 for legacy Skip stages mapping. REQ-MIG-006 deprecation matrix row: '`Skip stages: [code-analyst]` | Accepted + [WARN] log + mapped to `analyst-impact`'. However, no AC directly tests that `Skip stages: [code-analyst]` (a legacy v7 value, used directly in v8 without any migration having run) is accepted by the v8 pipeline with a [WARN] log. AC-NF-001 tests v7 `.md` overlay compatibility at pipeline execution level (PR or block) — it does NOT specifically test legacy Skip stages. AC-MIG-005 tests that `/migrate-config --to-v8` CONVERTS the value — but that presupposes migration has run. The gap: a consuming project in v8.0.0 that has never run migration and has `Skip stages: [code-analyst]` in CLAUDE.md will rely on the runtime alias, which is untested by any current AC.",
      "recommendation": "Add AC-NF-001a: 'WHEN `/fix-ticket {ID}` is invoked on a project with `### Pipeline Profiles → Skip stages: [code-analyst]` in CLAUDE.md (v7 legacy value, no migration run), THEN the pipeline SHALL skip the analyst impact phase AND emit `[WARN] Stage name code-analyst deprecated; use analyst-impact (removed v9.0.0)`. VERIFIED BY bash scenario `tests/scenarios/v8-nf-legacy-skip-stages-compat.sh`.' This closes the backwards compat test gap for the Skip stages alias path."
    },
    {
      "id": "f-r2e9f0",
      "severity": "NIT",
      "criterion": "correctness",
      "location": "requirements.md Section 7 OQ-B.1 resolution text vs REQ-MODE-009a",
      "description": "The OQ-B.1 resolution says: 'v8.0.0 inherits this trigger without modification. If post-v8.0.0 telemetry shows trigger false-positive rate > 20%... B2 re-opening criterion applies.' But REQ-MODE-009a immediately below formally DEFINES the heuristic with brand-new regex patterns explicitly labeled 'the AUTHORITATIVE minimum set'. These two statements are in tension: 'inherits without modification' implies the existing implementation in scaffold/SKILL.md is the ground truth; 'AUTHORITATIVE minimum set' in REQ-MODE-009a implies the spec IS the ground truth. If the current scaffold/SKILL.md heuristic differs from the REQ-MODE-009a regex patterns (e.g., uses different technical term keywords or a different word-count boundary), Phase 6 implementor has conflicting guidance on which is canonical.",
      "recommendation": "Update OQ-B.1 resolution text to: 'v8.0.0 FORMALIZES this trigger via REQ-MODE-009a. The regex patterns in REQ-MODE-009a are the authoritative spec; the existing scaffold/SKILL.md implementation SHALL be updated to conform to REQ-MODE-009a in Phase 7. Any behavioral difference between the current implementation and REQ-MODE-009a is a Phase 7 defect to fix, not a spec conflict.' This eliminates the 'inherits without modification' ambiguity."
    }
  ]
}
```

---

## Czech Adversarial Elaboration (≤350 slov)

Spec prošel zásadní revizí — všechny 3 BLOCKERy a 9 MAJORů z Round 1 jsou opraveny, a to substantivně, ne jen kosmeticky. REQ-STEPS-003a (near-miss override), REQ-MODE-008a (SIGTERM atomicita), REQ-MODE-009a (formální heuristika), REQ-AGT-008 (pipeline-status reader logic), REQ-MIG-003a (test-engineer special case), REQ-DOC-014 (CLAUDE.md update) — to jsou reálné přídavky, ne jen přeformulování.

**Nová čistá Round 2 naleziště (4 MINORy + 1 NIT):**

1. **f-r2a1b2: `readlink -f` macOS portabilita (MINOR)** — REQ-SETUP-006 specifikuje `readlink -f` pro symlink escape detection. Na macOS bez GNU coreutils tento příkaz neexistuje. REQ-NF-005 explicitně vyžaduje macOS bash 3.2 kompatibilitu. Implementátor Phase 6 dostane konfliktní instrukce bez jasného fallbacku.

2. **f-r2b3c4: `\b` regex v REQ-MODE-009a (MINOR)** — POSIX ERE nedefinuje `\b` word boundary. BusyBox a macOS bash 3.2 ho nepodporují spolehlivě. Phase 5 TDD generuje testy pro tyto patterny, ale jejich spuštění na non-GNU platformách může produkovat falešné výsledky. Řešení: specifikovat, že regex se evaluuje v runtime pluginu (Python/Node), ne v bash ERE.

3. **f-r2c5d6: AC-INV-DOC-ENUM-001 intersection bug (MINOR)** — AC říká `agent_set ∩ across all 5 files` ale zároveň říká "files that don't enumerate agents opt out." Set intersection přes soubory bez agent tabulky = ∅. Logická chyba: `∩` by mělo být nahrazeno per-file podmíněnou asercí. Phase 8 verification scenario může toto špatně implementovat.

4. **f-r2d7e8: Chybějící AC pro legacy Skip stages (MINOR)** — REQ-NF-001 zaručuje backwards compat pro `Skip stages: [code-analyst]` v8 runtime alias. Žádný AC ale specificky netestuje tento path — AC-NF-001 testuje `.md` overlay compat, AC-MIG-005 testuje migraci. Mezera: project bez migrace s legacy Skip stages hodnotou v8 je nepokrytý.

5. **f-r2e9f0: OQ-B.1 "inherits without modification" vs REQ-MODE-009a (NIT)** — Drobný textový konflikt: OQ-B.1 říká "inherits without modification," ale REQ-MODE-009a deklaruje "AUTHORITATIVE minimum set" nových regex patterns. Šablona pro Phase 7 implementaci je nejednoznačná.

**Verdikt: PASS.** Weighted aggregate 3.90. Všechny Tier 3 kritéria nad minimem. Spec je implementovatelný. Round 1 BLOCKERy byly odstraněny beze stop. Nové náleziště jsou MINORy (opravitelné v Phase 5 TDD nebo Phase 6 plan bez spec revision), jeden NIT. Gate 2 user approval je odporučen bez nutnosti Phase 4 spec revision.
