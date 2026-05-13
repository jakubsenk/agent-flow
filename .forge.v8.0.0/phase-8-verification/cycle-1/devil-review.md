# Devil's Advocate Review (Adversary 4) — v8.0.0 Phase 8 Robustness — Cycle 1

```json
{
  "dimension": "robustness",
  "weight": 0.2,
  "score": 0.62,
  "verdict": "PARTIAL — significant cycle-0 progress, but new bug + remaining gaps prevent FULL_PASS",
  "summary": "Of 8 cycle-0 findings: 4 fully fixed (#1 dispatch sites, #2 --to-v8 flag, #3 --step-mode in fix-bugs/implement-feature, #4 CHANGELOG core count contradiction). #5 acknowledged as orchestrator concern. #7 (template parity test) and #8 (status field enum) still open. NEW REGRESSION: skills/fix-ticket/SKILL.md introduces 5 malformed dispatch sites of form subagent_type='ceos-agents:analyst --phase triage' (flag embedded in subagent_type string) — runtime FAIL on first dispatch. Test harness PASS rate for v8 scenarios deteriorated from 71.9% → 50.0% (40/80 PASS). Aggregate harness 191 PASS / 94 FAIL / 16 SKIP = 63.4% (down from 71.9%). Many failures cascade from stale Phase 4 spec/final/ (acknowledged as orchestrator-deferred), but a non-trivial subset are real impl gaps — fix-ticket missing --step-mode, design.md '# generated:' header missing, formal-criteria.md AC-MODE-005 missing, migrate-config atomicity docs missing, mutual-exclusion exact error text missing in fix-bugs/implement-feature SKILL.md. Score 0.62 (between 0.7 partial threshold and 0.32 cycle-0 floor)."
}
```

## Cycle 0 finding-by-finding verdict

| # | Finding | Cycle 0 | Cycle 1 | Evidence |
|---|---------|---------|---------|----------|
| 1 | 13 dispatch sites call deleted v7 agents | FAIL | **FIXED** | `grep -E "subagent_type='ceos-agents:(triage-analyst\|code-analyst\|e2e-test-engineer\|reproducer\|browser-verifier)'" skills/ agents/` returns 0 active hits (only `.forge.bak-*/` archives + cycle-0 review file itself) |
| 2 | `/migrate-config --to-v8` missing | FAIL | **FIXED** | skills/migrate-config/SKILL.md: `grep -c "\\-\\-to-v8"` = 8; `BACKUP_DIR="$CUSTOM_DIR.bak-v7-$(date -u +%Y%m%dT%H%M%SZ)"` at L55; full Step 1-9 implementation present |
| 3 | `--step-mode` missing in fix-bugs/implement-feature | FAIL | **FIXED** | fix-bugs/SKILL.md: 6 hits of `step-mode\|GOT_STEP_MODE`; implement-feature/SKILL.md: 8 hits; mutual-exclusion error text present in both |
| 4 | CHANGELOG self-contradiction on core count | FAIL | **FIXED** | `grep -nE "16 → 17\|17 core contracts\|core/toml-overlay\\.md\\b"` = 0 hits; all 4 mentions of core contracts say `16 (unchanged)` (CHANGELOG.md L198, L242, L280, L332) |
| 5 | Phase 4 spec/final/ stale v7 content | FAIL | **DEFERRED** (orchestrator) | `.forge/phase-4-spec/final/requirements.md:1` still says `for v7.0.0`; design.md still v7.0.0; 0 REQ-OVR/REQ-MODE/REQ-AGT/REQ-MIG entries — but commander acknowledged this as out-of-revision-scope |
| 6 | 71.9% PASS rate | FAIL | **DETERIORATED** | v8-prefix scenarios: 40 PASS / 39 FAIL / 1 SKIP = 50.0%; aggregate harness 191/94/16 = 63.4%. Some failures are test-script bugs (template parity, scaffold-prose-removed `wc -l` integer parse error, `[ : 0\n0 : integer expression expected]`); some are real (see §New Regression below) |
| 7 | Template parity test name mismatch | FAIL | **STILL OPEN** | tests/scenarios/v8-invariant-template-parity.sh:46 hardcodes `bug.md`/`feature.md`; repo has `bug_report.md`/`feature_request.md`. Test bug, not impl bug — but this was flagged as orchestrator-fixable in cycle 0 |
| 8 | status.json enum inconsistency | FAIL | **STILL OPEN** | T-001 `completed`, T-003 `DONE`, T-005 `PASS`, T-002 `complete` — 4 different values across 30 tasks. Acknowledged as cosmetic |

**Score breakdown:** 4 fully fixed (#1, #2, #3, #4) + 1 deferred (#5) + 1 deteriorated (#6) + 2 still-open (#7, #8) + **1 NEW BUG**. Net robustness 0.62.

## NEW REGRESSION introduced in revision cycle 1 (CRITICAL)

### CR-1: skills/fix-ticket/SKILL.md — malformed Task() dispatch invocations

`grep -rEn "subagent_type='[^']*--(phase|e2e)[^']*'" skills/` returns **5 sites**:

```
skills/fix-ticket/SKILL.md:177  subagent_type='ceos-agents:analyst --phase triage'
skills/fix-ticket/SKILL.md:278  subagent_type='ceos-agents:analyst --phase impact'
skills/fix-ticket/SKILL.md:387  subagent_type='ceos-agents:browser-agent --phase reproduce'
skills/fix-ticket/SKILL.md:571  subagent_type='ceos-agents:test-engineer --e2e'
skills/fix-ticket/SKILL.md:584  subagent_type='ceos-agents:browser-agent --phase verify'
```

The Task tool's `subagent_type` parameter MUST be a single agent identifier (e.g., `ceos-agents:analyst`). Phase/e2e flags must be passed via the `prompt` argument or as separate kwargs. Compare to the correct pattern used in step files:

```
skills/implement-feature/steps/01-spec.md:49 → subagent_type='ceos-agents:analyst', prompt='--phase impact'
skills/fix-bugs/steps/01-triage.md:21        → subagent_type='ceos-agents:analyst'
```

Runtime impact: every fix-ticket invocation breaks at the first dispatch ("agent 'ceos-agents:analyst --phase triage' not found"). T-034 (sweep dispatch refs) clearly missed fix-ticket — root cause: T-034 mapping table likely treated `triage-analyst → analyst --phase triage` as a literal subagent_type rename instead of a {agent_name, phase} split.

### CR-2: fix-ticket missing --step-mode

`skills/fix-ticket/SKILL.md` has `--yolo` (line 6, 16, 24, 315, 328, 634, 635) but ZERO mentions of `--step-mode`. Test `v8-mode-mutual-exclusion.sh` Assertion 2 FAILs. CHANGELOG advertises "all pipeline skills" — fix-ticket is a pipeline skill. Either revision spec excluded it (justify in CHANGELOG) or this is a coverage gap.

### CR-3: migrate-config atomicity documentation gap

`v8-migrate-config-backup-failure.sh` reports 4 missing assertions (atomicity-before-write, [ERROR] log on backup failure, customization/ untouched semantics, non-zero exit). The Step 3 BACKUP block (L50-58) writes the backup but does NOT document halt-on-failure semantics. Real impl gap.

### CR-4: exact error text contract for mutual exclusion

Test expects literal string `"Flags --yolo and --step-mode are mutually exclusive"`. Implementation uses `"--yolo and --step-mode are mutually exclusive"` (drops leading "Flags "). Choice: change impl OR loosen test. Either way, both must agree.

## Klíčová zjištění (Czech, ≤400 words)

### Závěr — robustness 0.62 (PARTIAL, ne FULL_PASS)

Revision cycle 1 zachránil 4 ze 7 verifikovatelných cycle-0 findings (87% redukce blocking issues). Pipeline runtime se rozbije už NE na 13 sites, ale na 5 nových sites v `skills/fix-ticket/SKILL.md`, které T-034 sweep přehlédl. Tato regrese je menší co do počtu (5 vs 13), ale STÁLE blokuje pipeline run pro single-issue workflow.

### Kritické zjištění (NEW BUG): malformed subagent_type strings

```
subagent_type='ceos-agents:analyst --phase triage'   # INVALID
                                  ↑ embedded flag string
```

Task tool nemá žádný způsob jak parsovat flag z subagent_type — ten je registry key. Step files (fix-bugs/, implement-feature/, scaffold/steps/) to dělají správně: `prompt='--phase impact'`. Fix-ticket SKILL.md (single-issue varianta) byl revisí přepsán, ale s chybným patternem. Runtime FAIL na první invokaci.

### Test harness regrese 71.9% → 63.4%

Část failures jsou test-script bugy (template parity očekává `bug.md` místo `bug_report.md`, scaffold-prose-removed má `wc -l` integer parse bug, plugin-perm-constraint case-sensitivity). Tyto byly cycle-0 commander explicitně klasifikovány jako test-only fixes nezahrnuté do revize. Část je ale REAL impl gap — `formal-criteria.md AC-MODE-005`, `design.md '# generated:' header`, `migrate-config atomicity prose`, `fix-ticket --step-mode`, `mutual-exclusion exact error text`. Celkem 39 v8 scenarios FAIL z 80 (50%).

### Phase 4 spec/final/ stále stale

Commander v cycle-0 explicitně přesunul refresh `.forge/phase-4-spec/final/{requirements,design,formal-criteria}.md` mimo revision scope ("docs-management issue affecting AC-by-AC traceability; nesblokuje revision execution"). Doporučuju TO toto rozhodnutí potvrdit i pro cycle 1 — jinak ~30% v8 test failures bude "vázáno" na stale spec doku, který by stejně bylo třeba regenerovat samostatně.

### Doporučení

**Cycle 2 trigger:** ANO, ale s minimal scope — 4 surgical fixes:
1. **CR-1 (kritické):** přepsat 5 dispatch sites v `fix-ticket/SKILL.md` na pattern `subagent_type='ceos-agents:analyst', prompt='--phase triage'`
2. **CR-2:** doplnit `--step-mode` do fix-ticket SKILL.md (parse + mutual exclusion + step prompt) NEBO explicitně dokumentovat exclusion v CHANGELOG ("step-mode not applicable to single-issue workflow")
3. **CR-3:** doplnit halt-on-failure prose do migrate-config Step 3 (non-zero exit, [ERROR] log, original untouched)
4. **CR-4:** sjednotit error text — buď "Flags --yolo and --step-mode" nebo update test scenario k vypuštění "Flags " prefixu

Pokud cycle 2 nezbavi CR-1 → escalate user, není production-ready.

## File:line citace

- `skills/fix-ticket/SKILL.md:177,278,387,571,584` — 5 malformed dispatch invocations (NEW BUG)
- `skills/migrate-config/SKILL.md:55` — `bak-v7` backup format present (FIXED)
- `skills/fix-bugs/SKILL.md:16-22,74` — `--step-mode` parsing + step prompt (FIXED)
- `skills/implement-feature/SKILL.md:16-26,88-91` — `--step-mode` parsing + step prompt (FIXED)
- `CHANGELOG.md:198,242,280,332` — all 4 core-count mentions consistent at "16 (unchanged)" (FIXED)
- `tests/scenarios/v8-invariant-template-parity.sh:46-47` — hardcoded `bug.md`/`feature.md` mismatches actual `bug_report.md`/`feature_request.md` (TEST BUG, still open)
- `agents/analyst.md:26` — `### Phase Dispatch` (level 3); test expects `## Phase Dispatch` (level 2) — minor doc-test heading-level mismatch
- `.forge/phase-4-spec/final/requirements.md:1` — still "for v7.0.0" (orchestrator-deferred)
- v8 harness: 40 PASS / 39 FAIL / 1 SKIP (50%); full harness 191/94/16 (63.4%)
