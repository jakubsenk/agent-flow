# Phase 5 TDD — Compliance Review Round 1

**Reviewer:** Phase 5 Spec Compliance Reviewer (Sonnet 4.6)
**Date:** 2026-04-27
**Artifact:** `.forge/phase-5-tdd/tests/` (71 visible) + `.forge/phase-5-tdd/tests-hidden/` (12 hidden)
**Spec:** `.forge/phase-4-spec/final/formal-criteria.md` (94 ACs)

---

## JSON Verdict

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": false,
    "no_regressions": true,
    "lint_clean": true,
    "pass": false
  },
  "tier_2": {
    "fail_to_pass": {"passed": null, "failed": null, "total": null},
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true
  },
  "tier_3": {
    "correctness": 3,
    "completeness": 3,
    "security": 4,
    "maintainability": 4,
    "robustness": 3,
    "weighted_aggregate": 3.35,
    "pass": false
  },
  "overall_verdict": "REVISION_NEEDED",
  "confidence": 0.87,
  "findings": [
    {
      "id": "f-a1b2c3",
      "severity": "MAJOR",
      "criterion": "requirements_traced",
      "location": "coverage-report.md §2.2 — AC-SETUP-002, AC-SETUP-003, AC-SETUP-008",
      "description": "AC-SETUP-002 and AC-SETUP-003 are covered only by a documentation-grep test (v8-doc-setup-agents-examples.sh) which checks guide prose, NOT by the functional scenario files v8-setup-agents-python.sh and v8-setup-agents-monorepo.sh explicitly named in formal-criteria.md. AC-SETUP-008 (no file outside customization/ modified) has NO adequate test — coverage-report maps it to v8-setup-agents-preserve.sh but that file contains zero scope-isolation assertions.",
      "recommendation": "Add v8-setup-agents-python.sh (mock pyproject.toml project + invoke /setup-agents + grep analyst.toml for Python/PEP 8), v8-setup-agents-monorepo.sh (mock pnpm-workspace.yaml project), and v8-setup-agents-scope.sh (sha256sum baseline of all files outside customization/ before/after /setup-agents run). These are functional invocations, not doc-grep tests."
    },
    {
      "id": "f-b3c4d5",
      "severity": "MAJOR",
      "criterion": "requirements_traced",
      "location": "coverage-report.md §2.4 — AC-MODE-007",
      "description": "AC-MODE-007 (resume-ticket starts from step 05 after step_mode_abort with last_completed_step=04) is covered ONLY by hidden adversarial test v8-hidden-step-mode-abort-resume.sh. formal-criteria.md explicitly names a VISIBLE scenario v8-mode-stepmode-resume.sh for this AC. Routing a visible AC exclusively to a hidden test violates the 80/20 split intent: hidden tests are for adversarial EDGE CASES of already-visible-tested behavior, not for primary AC coverage.",
      "recommendation": "Add visible test v8-mode-stepmode-resume.sh covering the happy-path resume (mock state.json with pause_reason=step_mode_abort + last_completed_step=04 → verify resume-ticket step dispatch starts at 05). The hidden test can remain as the adversarial off-by-one guard variant."
    },
    {
      "id": "f-c5d6e7",
      "severity": "MAJOR",
      "criterion": "requirements_traced",
      "location": "formal-criteria.md REQ-MODE-009a / traceability index line 451",
      "description": "REQ-MODE-009a requires 4 boundary scenarios for the vague-description heuristic (exactly 19 words = vague, exactly 20 words = not vague, non-tech words, tech terms). formal-criteria.md traceability index explicitly mentions 'Phase 5 v8-mode-vague-heuristic-boundaries.sh'. No such file exists and the partial coverage via v8-mode-scaffold-vague-skip.sh does not exercise all 4 boundaries.",
      "recommendation": "Add v8-mode-vague-heuristic-boundaries.sh with all 4 boundary cases: 19-word vague, 20-word technical, short all-tech, and long all-generic descriptions."
    },
    {
      "id": "f-d7e8f9",
      "severity": "MODERATE",
      "criterion": "correctness",
      "location": "tests/v8-overlay-scalar-override.sh, v8-matrix-fixbugs-yolo.sh, v8-matrix-implfeat-yolo.sh, v8-matrix-scaffold-yolo.sh, v8-mode-mutual-exclusion.sh",
      "description": "Multiple tests violate AP3 (test-implementation coupling) by asserting specific internal variable names: v8-matrix-fixbugs-yolo.sh asserts grep for 'MODE=\"yolo\"' in SKILL.md; v8-mode-mutual-exclusion.sh asserts grep for 'GOT_YOLO' as a boolean variable pattern. These are implementation details from design.md §5.1, not observable outputs. An implementer could use any variable naming convention that produces the correct behavior. These assertions will cause false failures against correct alternative implementations.",
      "recommendation": "Replace implementation-detail assertions with observable-output assertions: e.g., assert that '--yolo' argument parsing produces zero gate prompts in a simulated run OR assert that the SKILL.md documents the exclusion behavior (which is already present via other assertions in the same test). Remove or downgrade the GOT_YOLO/MODE=\"yolo\" grep assertions to INFO-only notes."
    },
    {
      "id": "f-e9f0a1",
      "severity": "MODERATE",
      "criterion": "correctness",
      "location": "coverage-report.md §Phase 7 Integration Notes — REPO_ROOT resolution",
      "description": "Coverage report claims 'All tests use $(cd \"$(dirname \"$0\")/../../..\" && pwd) — 3 levels up'. Actual test code universally uses 2 levels up: REPO_ROOT=\"$(cd \"$(dirname \"$0\")/../..\" && pwd)\". At current staging location (.forge/phase-5-tdd/tests/) 2-level-up resolves to C:/gitea_ceos-agents/.forge (WRONG). After Phase 7 move to tests/scenarios/ 2-level-up resolves to the repo root (CORRECT). This is not a functional bug post-move, but: (1) the coverage report documentation is factually wrong about level count; (2) tests referencing $REPO_ROOT/agents/ etc. will silently fail or behave unexpectedly if run before Phase 7 move.",
      "recommendation": "Correct coverage report to state 2 levels. Add a note that tests are NOT runnable from the .forge staging location — they require Phase 7 placement at tests/scenarios/ first. Optionally add a guard at test start: if [[ $REPO_ROOT == */.forge* ]]; then echo 'ERROR: Run from tests/scenarios/, not .forge staging'; exit 2; fi"
    },
    {
      "id": "f-f1a2b3",
      "severity": "MODERATE",
      "criterion": "completeness",
      "location": "coverage-report.md §7 — AC-NF-008",
      "description": "AC-NF-008 (webhook payload schema has NO renamed fields between v7 and v8; new fields additive only) is explicitly VERIFIED BY bash scenario tests/scenarios/v8-nf-webhook-backcompat.sh per formal-criteria.md. That file does not exist. Coverage report maps it to v8-nf-state-additive-readable.sh with note 'webhook backcompat advisory'. The AC is not advisory — it is a SHALL requirement with an explicit scenario name. The state-additive test does not diff core/post-publish-hook.md against a v7.0.0 baseline.",
      "recommendation": "Add v8-nf-webhook-backcompat.sh that greps core/post-publish-hook.md for the canonical v7 payload field names (pr_url, issue_id, etc.) asserting they are still present in v8, AND checks no v7-named field has been renamed."
    },
    {
      "id": "f-g2h3i4",
      "severity": "MINOR",
      "criterion": "robustness",
      "location": "tests/v8-invariant-plugin-perm-constraint.sh:40 and tests/v8-steps-naming-convention.sh:29",
      "description": "Two tests use bash process substitution < <(find ...) which is a bashism (not in POSIX sh), but is available in bash 4+ and Git Bash on Windows. The spec requires POSIX bash portability. While #!/usr/bin/env bash is present and Git Bash supports <(), the harness invokes scripts with 'bash --posix' per AC-NF-005 claim. Under bash --posix mode, process substitution is disabled.",
      "recommendation": "Replace < <(find ...) with while IFS= read -r line; do ...; done < <(find ...) approach protected by a bash version check, or alternatively use a temp file as intermediate: find ... > \"$TMPDIR/filelist.txt\" && while IFS= read -r line; do ... done < \"$TMPDIR/filelist.txt\". The temp-file approach is fully POSIX-compatible."
    },
    {
      "id": "f-h4i5j6",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "coverage-report.md — visible/hidden split",
      "description": "Visible/hidden split is 85.5%/14.5%, slightly outside the TDD prompt target of '~80%/~20%'. This is within-spec per TDD prompt (says 'within spec'). However, the hidden test count of 12 provides minimal adversarial coverage for 9 scope categories. Only 1-2 hidden tests per scope area; some scope areas (documentation deliverables — 14 ACs, counts contract — 5 ACs) have NO adversarial hidden tests at all.",
      "recommendation": "Minor: consider adding 2-3 more hidden tests targeting doc enumeration adversarial cases (19-agent list in agents.md, missing section in CHANGELOG, stale count string reintroduction). This is not blocking but improves Phase 8 adversarial coverage."
    }
  ]
}
```

---

## Elaborace (Czech)

### Celkový verdikt: REVISION_NEEDED

Test suite Phase 5 je kvalitní základ s dobrou strukturou, správným bash syntaxem (0 chyb v `bash -n` přes všech 83 souborů), správným použitím `$REPO_ROOT`, `mktemp -d` + `trap` cleanup, a `jq` + `sha256sum` portabilními fallbacky. Tier 1 format-compliance je skoro celý splněn — ale `requirements_traced` padá kvůli třem skupinám problémů.

### Kritické problémy (MAJOR — blocker pro PASS)

**1. AC-SETUP-002/003 — doc-only namísto funkční coverage**
formal-criteria.md explicitně jmenuje `v8-setup-agents-python.sh` a `v8-setup-agents-monorepo.sh` jako ověřovací scénáře. Phase 5 místo nich použila doc-grep test (`v8-doc-setup-agents-examples.sh`) který ověřuje pouze že průvodce *popisuje* Python heuristiku, nikoliv že `/setup-agents` *funguje* se skutečným `pyproject.toml`. Coverage report to navíc přiznává: "Phase 7 should add functional invocation scenarios." To je ale přesouvání Phase 5 povinnosti do Phase 7 — Phase 7 je implementace, ne oprava TDD.

**AC-SETUP-008 — chybí test vůbec**
`v8-setup-agents-scope.sh` neexistuje a `v8-setup-agents-preserve.sh` neobsahuje žádné scope-isolation assertion (sha256sum baseline mimo `customization/`). AC-SETUP-008 je de facto nepokrytý.

**2. AC-MODE-007 — viditelné AC v hidden testu**
`v8-hidden-step-mode-abort-resume.sh` pokrývá hlavní happy-path AC-MODE-007 (resume starts at step 05). Skrytý test je určen pro adversarial edge cases, nikoliv pro primární pokrytí. formal-criteria.md explicitně jmenuje `v8-mode-stepmode-resume.sh` jako viditelný scénář.

**3. REQ-MODE-009a — 4 boundary případy**
Traceability index v formal-criteria.md explicitně říká "Phase 5 `v8-mode-vague-heuristic-boundaries.sh`". Soubor neexistuje a `v8-mode-scaffold-vague-skip.sh` pokrývá pouze jeden případ (≥20 tech slov = skip brainstorm), nikoliv všechny 4 hranice (19 slov, 20 slov, kratší variace).

### Střední problémy (MODERATE — opravit ale neblokující pokud Tier 1 fixed)

**AP3 porušení (implementation coupling):** Testy `v8-matrix-*-yolo.sh` a `v8-mode-mutual-exclusion.sh` grep pro `MODE="yolo"` a `GOT_YOLO` — interní proměnné z design.md §5.1. Implementátor může použít jiné názvosloví a testy selžou false-positive.

**REPO_ROOT documentation mismatch:** Coverage report říká "3 úrovně nahoru" ale kód používá 2. Správně to funguje až po Phase 7 přesunu — do té doby REPO_ROOT ukazuje do `.forge/`, nikoliv do repo rootu.

**AC-NF-008 slabé pokrytí:** webhook backcompat má explicitně pojmenovaný scénář v spec ale v Phase 5 chybí.

### Pozitiva (důvod proč score není níž)

- Bash syntax: 100% clean přes všech 83 souborů
- Invariant testy (license, email, template parity, plugin permission): výborné — frontmatter extraction via `awk '/^---$/{c++; next} c==1'` přesně dle AC-INV-PERM-001 specifikace
- Doc enumeration testy: plná iterace přes skutečné soubory, ne jen `grep "21 agents"` (AP1 splněn)
- Skryté testy: quality adversarial edge cases (CRLF/LF mismatch, rename collision, malformed TOML recovery, symlink rejection) — žádný leakage do viditelných názvů
- Security: žádný `rm -rf` na absolutních cestách, žádné síťové volání, temp dirs s proper cleanup

### Požadované opravy pro Round 2

1. Přidat `v8-setup-agents-python.sh` — funkční test s mock `pyproject.toml`
2. Přidat `v8-setup-agents-monorepo.sh` — funkční test s mock `pnpm-workspace.yaml` + 2 package.json
3. Přidat `v8-setup-agents-scope.sh` — sha256sum baseline + after assertion
4. Přidat `v8-mode-stepmode-resume.sh` — viditelný happy-path pro AC-MODE-007
5. Přidat `v8-mode-vague-heuristic-boundaries.sh` — 4 boundary cases pro REQ-MODE-009a
6. Přidat `v8-nf-webhook-backcompat.sh` — diff core/post-publish-hook.md field names
7. Opravit `MODE="yolo"` / `GOT_YOLO` assertions → behavioral/doc grep místo impl-coupling
8. Opravit coverage-report.md: "3 levels up" → "2 levels up" + add staging location warning

---

**REVIEW_END phase=5 round=1 verdict=REVISION_NEEDED**
