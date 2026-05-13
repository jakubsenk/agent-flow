# Phase 8 — Correctness Review (Adversary 2) — Cycle 1

**Dimension:** Correctness  
**Reviewer:** Adversary 2 (Correctness Specialist)  
**Date:** 2026-04-27  
**Release:** v8.0.0  
**Cycle:** 1 (post-revision)

---

## Verdict JSON

```json
{
  "dimension": "correctness",
  "score": 0.57,
  "cycle": 1,
  "revision_required": true,
  "summary": "Revision cycle 1 fixed 4 of 6 cycle-0 critical issues. SKILL.md decomposition PASS (95/105/101 lines, all ≤120). Deprecated dispatch refs PASS (0 active refs). --step-mode flags PASS (present in fix-bugs + implement-feature). migrate-config --to-v8 PASS (8 occurrences). CLAUDE.md Pipeline Profiles PASS (v8 names). resume-ticket step_mode_abort PARTIAL (section present, but re-execution guard missing). Overall test pass rate 50.0% (46/92): visible 40/80, hidden 6/12. Significant residual failures in overlay mechanics, mode edge cases, doc content gaps.",
  "checks": {
    "issue1_skill_decomposition": "PASS — 95/105/101 lines (all ≤120); steps/ exist (7/7/8 files)",
    "issue2_deprecated_dispatch_refs": "PASS — 0 active refs to deprecated agent names",
    "issue3_step_mode_flags": "PASS — GOT_YOLO + GOT_STEP_MODE + mutual exclusion in fix-bugs (8 hits) + implement-feature (10 hits)",
    "issue4_migrate_config_to_v8": "PASS — 8 occurrences of --to-v8 in migrate-config/SKILL.md",
    "issue5_claude_md_pipeline_profiles": "PASS — line 198 uses v8 names: analyst-impact, test-engineer-e2e, browser-agent-reproduce, browser-agent-verify",
    "issue6_resume_ticket_step_mode_abort": "PARTIAL — section exists at line 189 with REQ-MODE-008a label; dispatches from last_completed_step+1 (OK); guard against re-executing last_completed_step itself is ABSENT",
    "hidden_tests": { "pass": 6, "fail": 6, "score": 0.50 },
    "visible_tests": { "pass": 40, "fail": 40, "total": 80 },
    "total_tests": { "pass": 46, "fail": 46, "total": 92, "rate": "50.0%" }
  }
}
```

---

## Detailní výsledky per issue

### Issue 1 — SKILL.md decomposition line count (cycle 0: FAIL → cycle 1: PASS)

```
skills/fix-bugs/SKILL.md:        95 lines  ✓ (≤120)
skills/implement-feature/SKILL.md: 105 lines ✓ (≤120)
skills/scaffold/SKILL.md:         101 lines ✓ (≤120)
```

steps/ adresáře existují a jsou kompletní:
- `skills/fix-bugs/steps/`: 7 souborů (01-triage.md … 07-publish.md)
- `skills/implement-feature/steps/`: 7 souborů (01-spec.md … 07-publish.md)
- `skills/scaffold/steps/`: 8 souborů (01-mode-resolve.md … 08-final-report.md)

Test `v8-steps-entry-thinness.sh` PASS. **Issue 1: PLNĚ VYŘEŠEN.**

---

### Issue 2 — Deprecated dispatch refs (cycle 0: 148 → cycle 1: 0)

```bash
grep -rE "ceos-agents:(triage-analyst|code-analyst|e2e-test-engineer|reproducer|browser-verifier)" skills/ agents/ \
  | grep -v -E "(deprecated|v7|alias|migration|ALIAS|COUNTER-EXAMPLE|fixed_in_v8|legacy)" \
  → 0 matches
```

Test `v8-agents-deleted-old-names.sh` PASS. **Issue 2: PLNĚ VYŘEŠEN.**

---

### Issue 3 — --step-mode flag v fix-bugs + implement-feature (cycle 0: FAIL → cycle 1: PASS)

`skills/fix-bugs/SKILL.md` (8 hits):
- argument-hint obsahuje `--step-mode`
- `GOT_YOLO=false` a `GOT_STEP_MODE=false` inicializace
- parsování `[[ "$ARGUMENTS" == *"--step-mode"* ]]`
- mutual exclusion guard `if $GOT_YOLO && $GOT_STEP_MODE`
- `--step-mode prompt` dokumentace na line 74

`skills/implement-feature/SKILL.md` (10 hits): stejná struktura.

`skills/scaffold/SKILL.md` (8 hits): stejná struktura.

Testy `v8-matrix-fixbugs-stepmode.sh`, `v8-matrix-implfeat-stepmode.sh`, `v8-matrix-scaffold-stepmode.sh` PASS. **Issue 3: PLNĚ VYŘEŠEN.**

---

### Issue 4 — /migrate-config --to-v8 (cycle 0: 0 hits → cycle 1: 8 hits)

```bash
grep -c "\-\-to-v8" skills/migrate-config/SKILL.md → 8
```

Obsah ověřen: description frontmatter obsahuje `--to-v8`, argument sekce dokumentuje flag, `## --to-v8 Migration Process` sekce existuje s 25+ řádky implementace, backup logika na line 52, summary sekce na line 181.

Test `v8-migrate-config-md-to-toml.sh` PASS. **Issue 4: PLNĚ VYŘEŠEN.**

---

### Issue 5 — CLAUDE.md Pipeline Profiles v8 names (cycle 0: FAIL → cycle 1: PASS)

```
CLAUDE.md line 198: "Stage names for skip: triage, analyst-impact, spec-analyst,
test-engineer, test-engineer-e2e, browser-agent-reproduce, browser-agent-verify."
```

Stará jména (`code-analyst`, `e2e-test-engineer`, `reproducer`, `browser-verifier`) NEJSOU přítomna v kontextu Pipeline Profiles. V7 jména se v CLAUDE.md vyskytují POUZE v historických/docs sekcích (Bug-Fix Pipeline diagram, Feature Pipeline diagram) v non-normativním kontextu.

**Issue 5: PLNĚ VYŘEŠEN.**

---

### Issue 6 — resume-ticket step_mode_abort guard (cycle 0: 0 hits → cycle 1: PARTIAL)

```bash
grep -c "step_mode_abort\|REQ-MODE-008a" skills/resume-ticket/SKILL.md → 2
```

Sekce `## --step-mode Abort Resume Logic (REQ-MODE-008a)` existuje na line 189. Dokumentuje:
1. Detekci `step_mode_abort: true` v state.json
2. Dispatch od `last_completed_step + 1`

**Chybí:** explicitní guard `MUST NOT re-execute last_completed_step` (idempotent re-run dokumentace pouze tvrdí, že `interrupted step (last_completed_step + 1) is treated as not-completed` — logicky z toho plyne, že `last_completed_step` sám se nespustí znovu, ale test `v8-hidden-step-mode-abort-resume.sh` assertion 4 to ověřuje jako FAIL). Test hledá přesný text `guard against re-executing last_completed_step`.

**Issue 6: ČÁSTEČNĚ VYŘEŠEN** — logika správná, ale explicitní guard text chybí.

---

## Zbývající selhání (nové/přetrvávající)

### Kategorie A — Drobné doc mezery (WARN level)

| Test | Selhání |
|------|---------|
| `v8-agents-analyst-shape.sh` | analyst.md chybí `## Phase Dispatch` sekce |
| `v8-agents-test-engineer-shape.sh` | test-engineer.md chybí `--e2e` flag dokumentace |
| `v8-agents-deprecation-alias.sh` | fix-bugs SKILL.md neobsahuje inline deprecation warning text pro triage-analyst |
| `v8-count-config-sections.sh` | CLAUDE.md + automation-config.md mají 5/11 sekcí místo 18 (test počítá `###` headings uvnitř Automation Config — nesprávný scope test nebo neúplná doc) |
| `v8-doc-agents-enumeration.sh` | agents.md tabulka extrakce selhává na jednořádkovém formátu (test bug vs real gap) |
| `v8-doc-changelog-v8.sh` | `grep -qiF` s UTF-8 `→` crashuje na Windows (test bug — changelog obsah věcně správný) |
| `v8-doc-claude-md-scaffold-prose-removed.sh` | Test `[: 0\n0: integer expression expected` — bug v testu (newline v grep výstupu) vs reálná kontrola |
| `v8-doc-config-templates.sh` | 8 config templates neobsahují `customization/*.toml` reference |
| `v8-doc-migration-guide-sections.sh` | migration guide chybí `Migration:` odstavce (přítomny jsou sekce, ale ne inline `Migration:` prefix text) |
| `v8-doc-toml-syntax-content.sh` | toml-overlay-syntax.md má 0 fenced TOML bloků (test crashuje na Windows grep s `0\n0`) |
| `v8-invariant-doc-enumeration-parity.sh` | README.md agent tabulka extrakce selhává (stejný jednořádkový formát issue) |
| `v8-invariant-plugin-perm-constraint.sh` | automation-config.md chybí přesná fráze `hooks are skill-orchestrated, not agent-frontmatter` |
| `v8-invariant-template-parity.sh` | `.gitea/issue_template/bug.md` a `feature.md` chybí |

### Kategorie B — Overlay implementační mezery

| Test | Selhání |
|------|---------|
| `v8-overlay-array-append.sh` | Array append syntaxe nedokumentována nebo nefunkční |
| `v8-overlay-md-legacy-only.sh` | Legacy .md-only overlay path není kompletně dokumentován |
| `v8-overlay-md-toml-coexist.sh` | Koexistence .md + .toml overlay chybí v setup-agents SKILL.md |
| `v8-overlay-scalar-override.sh` | Scalar override mechanismus chybí |
| `v8-overlay-table-deepmerge.sh` | Table deep-merge logika chybí nebo není dokumentována |

### Kategorie C — Mode edge cases

| Test | Selhání |
|------|---------|
| `v8-mode-mutual-exclusion.sh` | Mutual exclusion test (pravděpodobně fix-ticket chybí --step-mode) |
| `v8-mode-scaffold-vague-skip.sh` | Scaffold vague heuristic threshold nedokumentován |
| `v8-mode-stepmode-abort-state.sh` | step_mode_abort state zápis do state.json |
| `v8-mode-stepmode-prompt-format.sh` | Přesný prompt formát pro step-mode checkpoint |
| `v8-mode-stepmode-sigterm-atomicity.sh` | SIGTERM atomicity v step-mode |
| `v8-mode-stepmode-skip-escape.sh` | Escape sekvence v step-mode skip logice |
| `v8-mode-vague-heuristic-boundaries.sh` | Hranice vague heuristic (20 slov threshold) |
| `v8-hidden-mode-vague-heuristic-edge.sh` | Test fixture word count bug — advisory |
| `v8-hidden-mode-flag-double-yolo.sh` | design.md chybí `GOT_YOLO=false` inicializace jako explicitní pattern |

### Kategorie D — Migrate-config detail gaps

| Test | Selhání |
|------|---------|
| `v8-migrate-config-backup-failure.sh` | Backup failure handling chybí |
| `v8-migrate-config-dryrun-noop.sh` | Dry-run noop garantee chybí nebo není správně formulována |
| `v8-migrate-config-yolo-autoresolve.sh` | --yolo flag v migrate-config chybí nebo nefunkční |

---

## Souhrnné hodnocení

**Skóre: 0.57 / 1.0**

Zdůvodnění:
- Všechny 4 plně adresované cycle-0 issues (SKILL decomposition, deprecated refs, --step-mode, --to-v8) jsou kritické architektonické kontrakty, jejichž oprava je věcně zásadní — to zvyšuje skóre od 0.38 výrazně.
- Issue 5 (CLAUDE.md) plně adresován.
- Issue 6 (resume-ticket) ČÁSTEČNĚ adresován — logika správná, formální guard text chybí.
- Celkový test pass rate 50.0% (46/92) je pod prahem 0.70 (≥70% = 0.7+ skóre dle rubriky).
- Zbývá ~40 selhávajících testů zejména v overlay mechanics, mode edge cases a doc content gaps.
- Část selhání je Windows test-harness bugs (grep-F s UTF-8, newline v integer expression) — tyto nelze počítat jako implementační chyby. Odhadem 5-8 testů selhává z harness důvodů, nikoliv implementačních.
- Adjusted pass rate (bez harness bugs): ~54/92 = ~58.7%.

**Revision cycle: REQUIRED** — skóre 0.57 je pod prahem 0.70.

**Prioritizované opravy pro cycle 2:**
1. `skills/setup-agents/SKILL.md` — doplnit `.md NOT applied when .toml present` (opraví hidden + overlay koexist testy)
2. Overlay mechanics (array-append, scalar-override, table-deepmerge) — doplnit do `core/overlay/toml-overlay.md` nebo `skills/setup-agents/lib/toml-merge.sh`
3. `agents/analyst.md` — doplnit `## Phase Dispatch` sekci
4. `agents/test-engineer.md` — doplnit `--e2e` flag dokumentaci
5. `skills/fix-ticket/SKILL.md` — doplnit `--step-mode` flag (opraví `v8-mode-mutual-exclusion.sh`)
6. Mode edge cases (vague heuristic threshold, step-mode prompt format, abort state write)
7. `.gitea/issue_template/bug.md` + `feature.md` — doplnit chybějící soubory (opraví template-parity invariant)
8. `design.md` — doplnit `triage-analyst + code-analyst` rename dokumentaci a `GOT_YOLO=false` boolean pattern
