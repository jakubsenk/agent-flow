# Phase 8 — Correctness Review (Adversary 2) — Cycle 2

**Dimension:** Correctness  
**Reviewer:** Adversary 2 (Correctness Specialist)  
**Date:** 2026-04-27  
**Release:** v8.0.0  
**Cycle:** 2 (post-narrow-scope revision)

---

## Verdict JSON

```json
{
  "dimension": "correctness",
  "score": 0.62,
  "cycle": 2,
  "revision_required": true,
  "summary": "Cycle 2 narrow-scope revision fixed CR-1 (dispatch syntax PASS), CR-2 (fix-ticket --step-mode PASS), CR-3 (migrate-config halt PASS), CR-4 (mutex text in all 4 skills PASS), template parity (PASS), and agent docs (test-engineer + browser-agent PASS). Issue 6 (resume-ticket guard) remains PARTIAL — explicit 'MUST NOT re-execute last_completed_step' text still absent. Visible test pass rate improved from 50.0% to 53.75% (43/80). Adjusted rate excluding 6 confirmed Windows/harness bugs: ~61% (49/80). Significant residual failures remain in overlay mechanics (5), mode edge cases (12), migrate-config details (3), design.md gaps (5), and doc content gaps (11). The analyst.md Phase Dispatch heading is level ### instead of required ##, causing v8-agents-analyst-shape to FAIL. Score improves from 0.57 → 0.62, still below 0.70 threshold.",
  "checks": {
    "CR1_dispatch_syntax": "PASS — 0 occurrences of 'subagent_type=\\'ceos-agents:<name> --\\'' (flag-in-type) pattern in fix-ticket; all 9 dispatch sites use separate model + prompt pattern",
    "CR2_fix_ticket_step_mode": "PASS — GOT_YOLO + GOT_STEP_MODE parsing present (7 hits including argument-hint, init, parse, mutex guard, doc); fix-ticket now matches fix-bugs/implement-feature/scaffold structure",
    "CR3_migrate_config_halt": "PASS — 1 occurrence of 'Backup creation failed' in migrate-config/SKILL.md; [ERROR] log on backup failure present",
    "CR4_mutex_text": "PASS — 'Flags --yolo and --step-mode are mutually exclusive' present in all 4 skills (fix-bugs:1, implement-feature:1, scaffold:1, fix-ticket:1); v8-mode-mutual-exclusion.sh PASS",
    "template_parity": "PASS — .gitea/issue_template/bug_report.md == .github/ISSUE_TEMPLATE/bug_report.md (byte-identical); feature_request.md pair PASS; pull_request_template.md pair PASS; v8-invariant-template-parity.sh PASS",
    "agent_docs_test_engineer": "PASS — test-engineer.md has --e2e flag documentation (4 hits); e2e-test-engineer.md absent; v8-agents-test-engineer-shape.sh PASS",
    "agent_docs_browser_agent": "PASS — browser-agent.md has ## Phase Dispatch section (1 hit); documents --phase reproduce + --phase verify; reproducer.md + browser-verifier.md absent; v8-agents-browser-agent-shape.sh PASS",
    "agent_docs_analyst": "FAIL — analyst.md has '### Phase Dispatch' (level 3) but test requires '^## Phase Dispatch' (level 2); v8-agents-analyst-shape.sh FAIL",
    "issue6_resume_ticket_step_mode_abort": "PARTIAL — step_mode_abort + REQ-MODE-008a section present (2 hits); dispatches from last_completed_step+1 (correct logic); explicit guard text 'MUST NOT re-execute last_completed_step' ABSENT; v8-hidden-step-mode-abort-resume assertion 4 would FAIL",
    "visible_tests": { "pass": 43, "fail": 37, "total": 80, "rate": "53.75%" },
    "newly_passing_vs_cycle1": [
      "v8-agents-test-engineer-shape",
      "v8-agents-browser-agent-shape",
      "v8-invariant-template-parity",
      "v8-mode-mutual-exclusion",
      "v8-matrix-fixbugs-stepmode",
      "v8-matrix-implfeat-stepmode",
      "v8-matrix-scaffold-stepmode",
      "v8-matrix-implfeat-yolo"
    ],
    "windows_harness_bugs": {
      "count": 6,
      "tests": [
        "v8-doc-changelog-v8 (grep -F + UTF-8 Arrow crash)",
        "v8-doc-claude-md-scaffold-prose-removed (newline in integer expression)",
        "v8-doc-toml-syntax-content (Windows grep multiline)",
        "v8-count-config-sections (### scope ambiguity)",
        "v8-doc-agents-enumeration (single-line table extraction)",
        "v8-invariant-doc-enumeration-parity (README format extraction)"
      ],
      "adjusted_pass_rate": "49/80 = 61.25%"
    }
  }
}
```

---

## CR verifikace — výsledky

### CR-1: fix-ticket dispatch syntax (cycle 0: FAIL → cycle 1/2: PASS)

```bash
grep -E "subagent_type='ceos-agents:[a-z-]+ --" skills/fix-ticket/SKILL.md
# → 0 výsledků
```

Všechna dispatchovací volání používají oddělený `model=` + `with prompt including` formát. Žádná stará syntaxe s flagem v `subagent_type` řetězci. **PASS.**

---

### CR-2: fix-ticket --step-mode (cycle 1: neuvedeno → cycle 2: PASS)

```bash
grep -c "step-mode\|GOT_STEP_MODE" skills/fix-ticket/SKILL.md → 7
```

`argument-hint` obsahuje `--step-mode`, inicializace `GOT_STEP_MODE=false`, parsování a mutual exclusion guard přítomné. Struktura identická s ostatními 3 pipeline skills. `v8-mode-mutual-exclusion.sh` **PASS** (4/4 skills pokryty).

---

### CR-3: migrate-config halt na backup selhání (cycle 1: 0 hits → cycle 2: PASS)

```bash
grep -c "Backup creation failed" skills/migrate-config/SKILL.md → 1
```

`[ERROR]` log na backup selhání dokumentován. **PASS.**

---

### CR-4: Mutex text ve 4 skills (cycle 1: fix-bugs/impl-feat/scaffold → cycle 2: +fix-ticket PASS)

```bash
grep -c "Flags --yolo and --step-mode are mutually exclusive" skills/fix-ticket/SKILL.md → 1
```

Všechny 4 pipeline skills mají přesný mutex text. `v8-mode-mutual-exclusion.sh` **PASS.**

---

### Template parity (cycle 1: FAIL → cycle 2: PASS)

`.gitea/issue_template/bug_report.md` ↔ `.github/ISSUE_TEMPLATE/bug_report.md` — byte-identical.  
`.gitea/issue_template/feature_request.md` ↔ `.github/ISSUE_TEMPLATE/feature_request.md` — byte-identical.  
`.gitea/pull_request_template.md` ↔ `.github/PULL_REQUEST_TEMPLATE.md` — byte-identical.  
`v8-invariant-template-parity.sh` **PASS.**

---

### Agent docs (cycle 1: FAIL → cycle 2: PASS/FAIL)

- `agents/test-engineer.md` — `--e2e` flag dokumentace přítomna (4 hity). `v8-agents-test-engineer-shape.sh` **PASS.**
- `agents/browser-agent.md` — `## Phase Dispatch` sekce přítomna, `--phase reproduce` + `--phase verify` dokumentovány. `v8-agents-browser-agent-shape.sh` **PASS.**
- `agents/analyst.md` — `### Phase Dispatch` na řádku 26 — Level 3 heading místo Level 2 (`##`). Test `v8-agents-analyst-shape.sh` hledá `^## Phase Dispatch` regex. **FAIL.**

---

### Issue 6: resume-ticket step_mode_abort guard (cycle 1: PARTIAL → cycle 2: PARTIAL)

`REQ-MODE-008a` sekce přítomna. Logika `last_completed_step + 1` správná. Chybí explicitní text: `MUST NOT re-execute last_completed_step` nebo ekvivalentní guard. Cycle 2 toto neadresoval.

---

## Přehled zbývajících selhání (37/80 visible)

### Kategorie A — Formátové a harness mezery (11 testů, z nichž 6 jsou Windows harness bugs)

| Test | Typ | Detail |
|------|-----|--------|
| `v8-agents-analyst-shape` | Impl gap | `### Phase Dispatch` místo `## Phase Dispatch` |
| `v8-agents-deprecation-alias` | Doc gap | Inline deprecation warning v fix-bugs SKILL.md chybí |
| `v8-count-config-sections` | Harness bug | `###` grep scope ambiguita |
| `v8-doc-agents-enumeration` | Harness bug | Jednořádkový tabulkový formát |
| `v8-doc-changelog-v8` | Harness bug | `grep -F` + UTF-8 `→` na Windows |
| `v8-doc-claude-md-scaffold-prose-removed` | Harness bug | Newline v integer expression |
| `v8-doc-config-templates` | Doc gap | `customization/*.toml` reference v 8 config templates |
| `v8-doc-migration-guide-sections` | Doc gap | `Migration:` prefix text chybí |
| `v8-doc-toml-syntax-content` | Harness bug | Fenced TOML blok + Windows grep |
| `v8-invariant-doc-enumeration-parity` | Harness bug | README tabulka extrakce |
| `v8-invariant-plugin-perm-constraint` | Doc gap | Přesná fráze `hooks are skill-orchestrated, not agent-frontmatter` |

### Kategorie B — Overlay mechanics (5 testů)

| Test | Detail |
|------|--------|
| `v8-overlay-array-append` | Array append syntaxe nedokumentována |
| `v8-overlay-md-legacy-only` | .md-only path nedokumentována kompletně |
| `v8-overlay-md-toml-coexist` | setup-agents SKILL.md neřeší koexistenci .md + .toml |
| `v8-overlay-scalar-override` | design.md chybí `overlay-wins-over-plugin-default` pravidlo |
| `v8-overlay-table-deepmerge` | Table deep-merge logika chybí |

### Kategorie C — Mode edge cases (12 testů)

| Test | Detail |
|------|--------|
| `v8-matrix-fixbugs-default` | `MODE.*default\|default.*mode` text chybí v fix-bugs SKILL.md |
| `v8-matrix-fixbugs-yolo` | `yolo.*gate\|yolo.*autonomous` text chybí |
| `v8-matrix-implfeat-default` | Spec Checkpoint dokumentace chybí |
| `v8-matrix-scaffold-default` | Vague-description brainstorm trigger chybí |
| `v8-matrix-scaffold-yolo` | Observable `--yolo` autonomous execution contract chybí |
| `v8-mode-scaffold-vague-skip` | Vague heuristic threshold (20 slov) nedokumentován |
| `v8-mode-stepmode-abort-state` | `state/schema.md` step_mode_abort klíče + exit 0 chybí |
| `v8-mode-stepmode-prompt-format` | Přesný formát step-mode checkpointu chybí |
| `v8-mode-stepmode-sigterm-atomicity` | SIGTERM atomicita nedokumentována |
| `v8-mode-stepmode-skip-escape` | Escape sekvence v skip logice chybí |
| `v8-mode-vague-heuristic-boundaries` | 20-slov threshold boundary nedokumentován |
| `v8-nf-v7-project-compat` | `.md` legacy fallback v fix-bugs SKILL.md chybí |

### Kategorie D — Migrate-config detail gaps (3 testy)

| Test | Detail |
|------|--------|
| `v8-migrate-config-backup-failure` | `customization/ untouched` + non-zero exit na selhání chybí |
| `v8-migrate-config-dryrun-noop` | Dry-run noop guarantee chybí |
| `v8-migrate-config-yolo-autoresolve` | `--yolo` autoresolve v migrate-config chybí |

### Kategorie E — design.md / formal-criteria.md gaps (5 testů)

| Test | Detail |
|------|--------|
| `v8-setup-agents-header` | design.md chybí `# generated:` header příklad |
| `v8-setup-agents-preview` | design.md setup-agents flow chybí preview diff krok |
| `v8-steps-default-resolution` | design.md §4.2 chybí `[INFO]` override-active logging spec |
| `v8-steps-near-miss-warn` | Zero-pad near-miss normalizace: `4-fixer.md` → `04-fixer-reviewer-loop.md` (ne `04-fixer.md`) |
| `v8-steps-override-replace` | `formal-criteria.md` AC-STEPS-005 chybí OVERRIDE BODY / replace semantics |

---

## Souhrnné hodnocení

**Skóre: 0.62 / 1.0**

Zdůvodnění oproti cycle 1 (0.57):

- CR-1, CR-2, CR-3, CR-4 potvrzeny jako PASS — výsledky cycle 2 oprav drží.
- Template parity: FAIL → **PASS** (+1).
- Agent docs: test-engineer + browser-agent FAIL → **PASS** (+2). Analyst PARTIAL (heading level bug).
- Mode mutual exclusion: FAIL → **PASS** díky přidání fix-ticket --step-mode (+1 přímý, +4 matrix testy).
- Celkem 8 nově procházejících testů: +3 procentní body (50% → 53.75%).
- Adjusted rate (bez 6 Windows harness bugs): ~61.25%.
- Skóre 0.57 → **0.62** odráží 8 nových PASS plus harness-bug korekci.

Zbývající mezery (37 visible failures) jsou soustředěny v:
1. design.md chybějící příklady a specifikace (5 testů) — orchestrační concern
2. Mode edge-case dokumentace v SKILL.md souborech (12 testů)
3. Overlay mechanics docs (5 testů)
4. Migrate-config detail (3 testy)
5. Formátové/harness mezery (11 testů, 6 z toho Windows bugs)

**Revision cycle:** REQUIRED — skóre 0.62 je pod prahem 0.70.

**Prioritizované opravy pro cycle 3:**
1. `agents/analyst.md` — změnit `### Phase Dispatch` → `## Phase Dispatch` (1 řádek, opraví 1 test)
2. `skills/fix-bugs/SKILL.md` — doplnit `default mode` text + `--yolo zero gates/autonomous` text (opraví 2 matrix testy)
3. `skills/implement-feature/SKILL.md` — doplnit Spec Checkpoint + Decomposition Approval text (opraví 2 testy)
4. `skills/scaffold/SKILL.md` — doplnit vague-description brainstorm trigger + `--yolo` autonomous contract (opraví 2 testy)
5. `state/schema.md` — doplnit `step_mode_abort` + `last_completed_step` klíče (opraví abort-state test)
6. `core/overlay/toml-overlay.md` nebo `docs/guides/` — doplnit array-append, scalar-override, table-deepmerge, .md-only path (opraví 4 overlay testy)
7. `skills/setup-agents/SKILL.md` — doplnit .md + .toml koexistenci (opraví coexist overlay test)
8. `skills/resume-ticket/SKILL.md` — doplnit explicitní guard `MUST NOT re-execute last_completed_step` (uzavře Issue 6)
9. `skills/migrate-config/SKILL.md` — doplnit `customization/ untouched` + `non-zero exit` + `--yolo autoresolve` (opraví 3 testy)
10. Zbývající design.md gaps (header, preview, §4.2) + formal-criteria.md AC-STEPS-005 (opraví 4 testy)
