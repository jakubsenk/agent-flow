# Devil's Advocate Review (Adversary 4) — v8.0.0 Phase 8 Robustness

```json
{
  "dimension": "robustness",
  "weight": 0.2,
  "score": 0.32,
  "verdict": "FAIL — REVISION CYCLE REQUIRED",
  "summary": "v8.0.0 release has structural integrity failures that 3 other reviewers missed. Test harness shows 69 FAIL / 217 PASS / 15 SKIP (PASS rate 71.9%). 13 dispatch sites in fix-bugs/fix-ticket/implement-feature/scaffold still call deleted v7 agents (triage-analyst, code-analyst). /migrate-config has NO --to-v8 flag despite CHANGELOG promising it. fix-bugs and implement-feature SKILL.md lack --step-mode entirely. CHANGELOG self-contradicts on core count (16 vs 17). Phase 4 spec final/ folder contains stale v7.0.0 content (title literally says 'for v7.0.0'). Hidden test v8-hidden-mode-flag-double-yolo asserts design.md has GOT_YOLO=false — design.md is v7 content with NO such pattern (test FAILs). Devil's advocate triggers FAIL gate."
}
```

## Klíčová zjištění (Czech, ≤400 words)

### 1. CRITICAL — Pipeline runtime se rozbije (13 dispatch sites volají smazané agenty)
`grep -c "subagent_type='ceos-agents:triage-analyst'..."` ve `skills/`:
- `skills/fix-bugs/SKILL.md`: 5 sites volajících **triage-analyst, code-analyst** (smazané v T-003)
- `skills/fix-ticket/SKILL.md`: 5 sites
- `skills/implement-feature/SKILL.md`: 2 sites
- `skills/scaffold/SKILL.md`: 1 site

`agents/triage-analyst.md` neexistuje (CHANGELOG sám říká "deleted"). Při prvním dispatchi pipeline FAILuje s "agent not found". Aliasing v `core/aliases/agents-rename-aliases.md` pokrývá jen `Skip stages` parsing + tracker comments, NE Task() dispatch sites. Jediný funkční pipeline path je ten, kde dispatch sites byly přepsány — to se nestalo.

### 2. CRITICAL — `/migrate-config --to-v8` neexistuje
CHANGELOG.md:220-223 inzeruje `/migrate-config --to-v8 --dry-run` a `--yes`. `skills/migrate-config/SKILL.md` (104 řádků celkem) nezmiňuje řetězec `--to-v8`, `customization`, `triage-analyst`, ani `backup`. Skill stále migruje "v3.1" Automation Config. Migration guide odkazuje neexistující funkcionalitu. Scenario A ("partial v7→v8 migration") je tedy nezvládnutý — uživatel nemá automatický migrátor.

### 3. CRITICAL — `--step-mode` chybí ve 2 ze 3 pipelines
CHANGELOG.md:184: "`--step-mode` flag — Per-step pause across all 3 pipelines (`fix-bugs`, `implement-feature`, `scaffold`)". Reality:
- `skills/fix-bugs/SKILL.md`: 0 výskytů `--step-mode`/`step_mode`
- `skills/implement-feature/SKILL.md`: 0 výskytů
- `skills/scaffold/`: pouze v step-files (4 hits)

Scenario C (SIGTERM během step-mode) tedy poklesnout nemůže, protože step-mode ve fix-bugs/implement-feature ani neexistuje. Test `v8-mode-stepmode-sigterm-atomicity` FAIL na "fix-bugs SKILL.md missing write-after-complete (atomicity) semantics".

### 4. HIGH — CHANGELOG self-contradiction (core count)
CHANGELOG.md:198: "Core contracts (maxdepth-1): **16 (unchanged)**".
CHANGELOG.md:242 (table): "Core contracts (maxdepth-1) | 16 | **17** (+`core/toml-overlay.md`)".
Reality: `find core -maxdepth 1 -name '*.md' | wc -l` = 16. File je v `core/overlay/toml-overlay.md` (sub-namespace). Tabulka na ř.242 lže o 17 a o cestě `core/toml-overlay.md` (neexistuje).

### 5. HIGH — Phase 4 spec final/ obsahuje stale v7.0.0 obsah
`.forge/phase-4-spec/final/requirements.md:1`: "Phase 4 — Requirements (EARS) for **v7.0.0**". `design.md:1` taktéž v7.0.0. Žádné REQ-OVR/REQ-MODE/REQ-AGT existence. Všech 35+ v8 testů co odkazují `.forge/phase-4-spec/final/design.md` (např. `v8-hidden-mode-flag-double-yolo.sh` Assertion 3: `grep -qF 'GOT_YOLO=false' design.md` → FAIL ověřeno) selhávají na obsahový mismatch.

### 6. HIGH — Cross-file invariant 3 (template parity) test FAILuje
`v8-invariant-template-parity` hlásí Missing: `.gitea/issue_template/bug.md`. Test očekává jména `bug.md`/`feature.md`, repo má `bug_report.md`/`feature_request.md`. Buď test má bug, nebo template parity check je falešně zelená.

### 7. MEDIUM — Status field inconsistency v Phase 7 task results
`.forge/phase-7-execution/T-*/status.json`: smíšené hodnoty `complete`/`completed`/`DONE`/`PASS`. Programatická konzumace harness reportu je k chybě.

### Závěr
**FAIL gate triggered.** Robustness skóre 0.32 — pod 0.7 prahem. Nutná revision cycle s minimálními požadavky: (a) přepsat 13 dispatch sites na nová agent jména, (b) implementovat `/migrate-config --to-v8`, (c) doplnit `--step-mode` do fix-bugs/implement-feature, (d) opravit CHANGELOG core count contradiction, (e) refresh `.forge/phase-4-spec/final/` na v8 obsah (nebo dokumentovat že se nepoužívá).

## File:line citace

- `CHANGELOG.md:198` vs `CHANGELOG.md:242` — core count rozpor
- `skills/migrate-config/SKILL.md` (celý 104řádkový soubor neobsahuje `--to-v8`)
- `skills/fix-bugs/SKILL.md:180,202,205` — `triage-analyst` dispatch
- `skills/fix-ticket/SKILL.md` — 5 starých dispatch sites
- `.forge/phase-4-spec/final/requirements.md:1` — "for v7.0.0"
- `tests/scenarios-hidden/v8-hidden-mode-flag-double-yolo.sh:90` — assertion fails
- `tests/scenarios/v8-invariant-template-parity.sh` — `bug.md` vs `bug_report.md`
- `core/overlay/toml-overlay.md` (vs CHANGELOG ř.242 path `core/toml-overlay.md`)
