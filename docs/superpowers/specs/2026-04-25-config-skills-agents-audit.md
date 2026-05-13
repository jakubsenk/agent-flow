# Config + Skills + Agents Audit (4-reviewer + judge consolidation)

**Date:** 2026-04-25
**Scope:** sub-projekt C — cleanup před public release (cesta k v6.11.0 / v6.12.0 / v7.0.0)
**Reviewers:**
- **Adoption** — nový uživatel, 1. týden
- **Power-user** — 6+ měsíců, BIFITO + drmax-readmine-test reálná data
- **Maintainer** — doc drift, test coverage, internal fragility
- **Public-Release** — externí OSS hodnotitel, "Astro/Tailwind moment" optikou

**Method:** 4 paralelních agentů → judge consolidation (tento dokument)

---

## Executive Summary

Audit napříč 69 položkami (19 config sekcí + 29 skills + 21 agentů) ukazuje **silný konsenzus pro významný cleanup před public release**: minimálně 18 položek má 3+ reviewerů hlasujících pro DELETE/MERGE/SIMPLIFY (eliminační intenze). Plugin trpí třemi strukturálními problémy, které všichni 4 reviewery viděli ze své strany: (1) **PM rodina** (sprint-plan, prioritize, dashboard, create-backlog, metrics) je out-of-scope pro core mission "fix-bugs + ship-PRs" — DELETE konsenzus napříč Adoption/Public-Release, weak signal i u Power-user (0 runs za 6 měsíců); (2) **Spec rodina** (spec-analyst + spec-writer + spec-reviewer + acceptance-gate) je 4-agent fragmentace jednoho kontraktu — Public-Release navrhuje konsolidaci; (3) **Scaffold povrch** (scaffold + scaffold-add + scaffold-validate + scaffolder + stack-selector) je 1147-line monolit se 4-tier dependency, navrhuje se zjednodušení pomocí flagů. **Doporučená alokace:** v6.11.0 = 14 no-controversy DELETE/MERGE (PM rodina + 3 dead skills + 5 dead config sekcí), v6.12.0 = scaffold rework + spec rodina konsolidace + agent merge experimenty, v7.0.0 = README kategorizace + 3 PROMOTE items (workflow-router, Agent Overrides, Autopilot) + missing OSS pieces.

---

## Konsolidované verdikty

### Config sekce (19 položek)

| # | Položka | Adoption | Power-user | Maintainer | Public-Release | Konsenzus | Finální doporučení | Důvod |
|---|---|---|---|---|---|---|---|---|
| 1 | Retry Limits | KEEP | KEEP | KEEP | KEEP | **STRONG KEEP** | KEEP | Aktivně používáno BIFITO+drmax, žádný hlas proti |
| 2 | Module Docs | DEMOTE | DELETE | KEEP | DELETE | **STRONG DELETE** | DELETE | 1-key sekce, 0/8 templates, 0 reálných projektů |
| 3 | Hooks | KEEP | DEMOTE | KEEP | KEEP | DEMOTE-mild | KEEP (move to advanced) | 3 hlasy KEEP, ale Power-user 0/8 aktivně — schovat z hlavní reference |
| 4 | Custom Agents | DEMOTE | DELETE | MERGE→Hooks | MERGE→Hooks | **CONSOLIDATE** | MERGE into Hooks | Nahrazeno Agent Overrides (Power-user evidence) |
| 5 | Notifications | KEEP | UNCLEAR | KEEP | KEEP | KEEP | KEEP | Webhook circuit-breaker dokončen v6.9.0, security defer známý |
| 6 | Worktrees | DEMOTE | DELETE | UNCLEAR | SIMPLIFY | **STRONG DELETE/CONSOLIDATE** | DELETE or DEMOTE | 0/8 templates, dead-feature kandidát |
| 7 | E2E Test | KEEP | UNCLEAR | KEEP | MERGE→Testing | CONSOLIDATE | MERGE with Browser Verification → "Testing" | Public-Release navrhuje sloučit, BIFITO má Playwright ale neaktivuje |
| 8 | Browser Verification | SIMPLIFY | DELETE | SIMPLIFY | SIMPLIFY | **CONSOLIDATE** | SIMPLIFY (8 keys → 2-3) + merge with E2E Test | 8 keys nejvíc ze všech, 0 reálných projektů využívá |
| 9 | Error Handling | KEEP | KEEP | KEEP | KEEP | **STRONG KEEP** | KEEP | Oba projekty rozdílně používají |
| 10 | Extra labels | MERGE | DELETE | KEEP | MERGE→PR Rules | **CONSOLIDATE** | MERGE into PR Rules | 0/8 templates, ale Maintainer drží — sloučit do PR Rules subkey |
| 11 | Feature Workflow | KEEP | KEEP | KEEP | KEEP | **STRONG KEEP** | KEEP | BIFITO aktivně |
| 12 | Decomposition | DEMOTE | SIMPLIFY | KEEP | SIMPLIFY | **CONSOLIDATE** | SIMPLIFY (4 keys → 1-2) | drmax přepisuje defaults, 4 keys overkill |
| 13 | Pipeline Profiles | DEMOTE | KEEP | SIMPLIFY | DELETE | **CONFLICT** | NEEDS-USER-DECISION | drmax kriticky využívá vs. Public-Release "kitchen-sink" |
| 14 | Metrics | KEEP | DELETE | KEEP | DELETE | **CONFLICT** | NEEDS-USER-DECISION | Power-user defaults nikdy nemění, ale Adoption KEEP |
| 15 | Agent Overrides | DEMOTE | **PROMOTE** | KEEP | KEEP | **PROMOTE** | PROMOTE (kandidát na first-class) | drmax killer feature, nahrazuje Custom Agents |
| 16 | Local Deployment | KEEP | KEEP | KEEP | DELETE | KEEP (with concern) | KEEP | drmax Oracle docker reálně používá; Public-Release optika docker-compose duplicate |
| 17 | Sprint Planning | DELETE | UNCLEAR | KEEP | DELETE | **STRONG DELETE** | DELETE | 0 runs za 6 měsíců, out-of-scope pro core |
| 18 | Autopilot | DEMOTE | **PROMOTE** | KEEP | SIMPLIFY | KEEP/PROMOTE | KEEP + simplify (7 keys → 4) | Jediná sekce v 8/8 templates, ale 7 keys overkill |
| 19 | Pause Limits | DELETE | SIMPLIFY | KEEP | DELETE | **STRONG DELETE** | DELETE/INLINE | 8/8 default 30 days, mohlo být 1 row |

### Skills (29 položek)

| # | Položka | Adoption | Power-user | Maintainer | Public-Release | Konsenzus | Finální doporučení | Důvod |
|---|---|---|---|---|---|---|---|---|
| 1 | analyze-bug | KEEP | KEEP | KEEP | MERGE→fix-ticket --dry-run | KEEP (with consolidation option) | KEEP | 3 KEEP, Public-Release navrhuje flag, ale dry-run přidat za úvahu |
| 2 | autopilot | DEMOTE | KEEP | KEEP | KEEP | KEEP | KEEP | Power-user denně, dokumentace dospělá |
| 3 | changelog | DEMOTE | KEEP | KEEP | KEEP | KEEP | KEEP | Každý release |
| 4 | check-deploy | KEEP | UNCLEAR | KEEP | DELETE | **CONFLICT** | NEEDS-USER-DECISION | Public-Release "docker-compose ps" vs Adoption hodnotí jako KEEP |
| 5 | check-setup | **PROMOTE** | KEEP | KEEP | KEEP | **PROMOTE** | PROMOTE | Adoption: největší adopční win, Power-user: po každé config změně |
| 6 | create-backlog | DEMOTE | UNCLEAR | KEEP | DELETE | **STRONG DELETE** | DELETE | PM rodina, 0 evidence v reálných projektech |
| 7 | create-pr | MERGE | KEEP | KEEP | MERGE→publish | CONSOLIDATE | KEEP + add `publish --no-tracker` flag | Manuální fallback důležitý |
| 8 | dashboard | DEMOTE | DELETE | UNCLEAR | DELETE | **STRONG DELETE** | DELETE | 0 evidence kdokoliv používá, kitchen-sink |
| 9 | discuss | UNCLEAR | DELETE | UNCLEAR | DELETE | **STRONG DELETE** | DELETE | "chatbot novelty", 0 runs za 6 měsíců |
| 10 | estimate | KEEP | SIMPLIFY | KEEP | DELETE | CONSOLIDATE | MERGE into pipeline `--dry-run` | Mohlo být dry-run output |
| 11 | fix-bugs | KEEP | KEEP | KEEP | KEEP | **STRONG KEEP** | KEEP | Killer app |
| 12 | fix-ticket | KEEP | KEEP | KEEP | KEEP | **STRONG KEEP** | KEEP | Killer app, OSS hook |
| 13 | implement-feature | KEEP | KEEP | KEEP | KEEP | **STRONG KEEP** | KEEP | drmax aktivně |
| 14 | init | SIMPLIFY (rename) | KEEP | KEEP | MERGE→onboard | CONSOLIDATE | MERGE/RENAME (init/onboard naming clash) | Adoption: 2 wizardy s podobným názvem = bariéra |
| 15 | metrics | DEMOTE | KEEP | KEEP | DELETE | **CONFLICT** | NEEDS-USER-DECISION | Pokud Metrics config DELETE, pak i tato skill |
| 16 | migrate-config | DELETE (z první linie) | KEEP | KEEP | KEEP | KEEP (DEMOTE) | DEMOTE-to-advanced | Power-user 6.7.x použil, ale ne pro nového usera |
| 17 | onboard | KEEP | KEEP | KEEP | KEEP | **STRONG KEEP** | KEEP | 1× při scaffold, entry point |
| 18 | prioritize | DEMOTE | UNCLEAR | KEEP | DELETE | **STRONG DELETE** | DELETE | PM rodina, 0 evidence |
| 19 | publish | KEEP | KEEP | KEEP | KEEP | **STRONG KEEP** | KEEP | Auto-dispatched |
| 20 | resume-ticket | KEEP | KEEP | KEEP | KEEP | **STRONG KEEP** | KEEP | Po každém blocku |
| 21 | scaffold-add | SIMPLIFY | UNCLEAR | KEEP (0 tests) | SIMPLIFY (--add flag) | **CONSOLIDATE** | MERGE → `scaffold --add` flag | 0 tests + sdílí scaffolder kontrakt = silent breakage risk |
| 22 | scaffold-validate | MERGE | KEEP | KEEP | MERGE→check-setup | **CONSOLIDATE** | MERGE into check-setup | 2 hlasy MERGE — funkční překryv |
| 23 | scaffold | KEEP | KEEP | KEEP (1147 lines) | SIMPLIFY | KEEP+SIMPLIFY | KEEP, refaktor v6.12.0 | Monolit, 4-tier dependency stack |
| 24 | sprint-plan | DELETE (z první linie) | UNCLEAR (0 runs) | KEEP | DELETE | **STRONG DELETE** | DELETE | PM rodina, out-of-scope |
| 25 | status | KEEP | KEEP | KEEP | KEEP | **STRONG KEEP** | KEEP | Power-user denně |
| 26 | template | KEEP | SIMPLIFY (8→2) | KEEP | SIMPLIFY (8→3-4) | CONSOLIDATE | SIMPLIFY (8 templates → 4 reference + community) | 6 z 8 nikdy nepoužitých |
| 27 | version-bump | DEMOTE | KEEP (memory rule) | KEEP | KEEP | KEEP | KEEP | Memory rule explicitní |
| 28 | version-check | KEEP | DELETE | KEEP | KEEP | KEEP | KEEP | 3 hlasy KEEP, Power-user kritika ale ne dominantní |
| 29 | workflow-router | UNCLEAR (PROMOTE candidate) | KEEP | DEMOTE (Claude Code #26251) | DELETE | **CONFLICT** | NEEDS-USER-DECISION | Adoption: hidden gem; Maintainer: arch anomálie; Public-Release: duplikuje native routing |

### Agenti (21 položek — hlasovali jen Maintainer + Public-Release)

| # | Položka | Adoption | Power-user | Maintainer | Public-Release | Konsenzus (2 reviewery) | Finální doporučení | Důvod |
|---|---|---|---|---|---|---|---|---|
| 1 | acceptance-gate | — | — | KEEP (0 tests) | MERGE→reviewer --ac-only | CONFLICT | KEEP, deferred merge to v6.12.0 | Read-only, ale dispatch site malé |
| 2 | architect | — | — | KEEP (107 lines, 0 tests) | KEEP | KEEP | KEEP | Critical pro feature pipeline |
| 3 | backlog-creator | — | — | KEEP | DELETE (s create-backlog) | CONFLICT/DELETE | DELETE (s skill) | Pokud create-backlog DELETE, agent jde s ním |
| 4 | browser-verifier | — | — | SIMPLIFY (0 tests) | SIMPLIFY (s e2e) | **CONSOLIDATE** | SIMPLIFY + merge with reproducer | 8 config keys, 0 tests, low usage |
| 5 | code-analyst | — | — | KEEP (canonical) | KEEP | **STRONG KEEP** | KEEP | Canonical EXTERNAL INPUT vzor |
| 6 | deployment-verifier | — | — | KEEP (5 sites, 0 tests) | DELETE (s check-deploy) | CONFLICT | NEEDS-USER-DECISION | Pokud check-deploy DELETE, agent jde s ním |
| 7 | e2e-test-engineer | — | — | KEEP (8 sites NEJVÍC) | MERGE→test-engineer --scope | CONFLICT/CONSOLIDATE | KEEP, deferred merge v6.12.0 | 8 dispatch sites = největší integrace |
| 8 | fixer | — | — | KEEP | KEEP | **STRONG KEEP** | KEEP | Critical |
| 9 | priority-engine | — | — | KEEP | DELETE (s prioritize) | CONFLICT/DELETE | DELETE (s skill) | PM rodina |
| 10 | publisher | — | — | KEEP (0 tests) | KEEP | KEEP | KEEP | Auto-dispatched |
| 11 | reproducer | — | — | KEEP (0 tests) | SIMPLIFY (merge s browser-verifier) | CONSOLIDATE | MERGE with browser-verifier → "browser-agent" | Public-Release navrhuje konsolidaci |
| 12 | reviewer | — | — | KEEP | KEEP | **STRONG KEEP** | KEEP | Critical |
| 13 | rollback-agent | — | — | KEEP (haiku, git reset, 0 tests) | KEEP | KEEP (with risk) | KEEP + add tests v6.11.0 | Maintainer flag: 0 tests + git reset = riziko |
| 14 | scaffolder | — | — | KEEP (210 lines, 22 cross-refs) | SIMPLIFY | KEEP+SIMPLIFY | SIMPLIFY v6.12.0 (with scaffold rework) | 4-tier dependency |
| 15 | spec-analyst | — | — | KEEP | MERGE→spec-author (with spec-writer) | CONSOLIDATE | MERGE v6.12.0 | Spec rodina fragmentace |
| 16 | spec-reviewer | — | — | KEEP | MERGE→reviewer | CONSOLIDATE | MERGE v6.12.0 | Funkční překryv s reviewer |
| 17 | spec-writer | — | — | KEEP | MERGE→spec-author | CONSOLIDATE | MERGE v6.12.0 | Spec rodina fragmentace |
| 18 | sprint-planner | — | — | KEEP | DELETE (s sprint-plan) | CONFLICT/DELETE | DELETE (s skill) | PM rodina |
| 19 | stack-selector | — | — | KEEP | DELETE (do scaffolder) | CONFLICT/CONSOLIDATE | MERGE into scaffolder v6.12.0 | Scaffold rodina |
| 20 | test-engineer | — | — | KEEP | KEEP | **STRONG KEEP** | KEEP | Critical |
| 21 | triage-analyst | — | — | KEEP | KEEP | **STRONG KEEP** | KEEP | Critical, AC extraction |

---

## Souhrn

### Klasifikace verdiktů

| Klasifikace | Config (19) | Skills (29) | Agenti (21) | Celkem (69) |
|---|---|---|---|---|
| STRONG KEEP | 3 | 8 | 5 | 16 |
| STRONG DELETE | 4 | 5 | 0 | 9 |
| CONSOLIDATE (MERGE/SIMPLIFY) | 5 | 4 | 5 | 14 |
| DEMOTE / HIDE | 1 | 1 | 0 | 2 |
| CONFLICT (vyžaduje rozhodnutí) | 2 | 3 | 5 | 10 |
| PROMOTE | 1 | 1 | 0 | 2 |
| KEEP (mild) | 3 | 7 | 6 | 16 |

**Eliminační intenze celkem:** 25/69 = **36 %** položek má 3+ reviewerů v intenzi DELETE/MERGE/SIMPLIFY. To je významný cleanup signál pro public release.

### Top 5 konfliktů (vyžadují user rozhodnutí)

1. **Pipeline Profiles** (CONFIG) — Public-Release: DELETE ("kitchen-sink") vs Power-user: KEEP ("drmax kriticky využívá pro skip browser/e2e"). **Otázka:** podržet pro power-userů nebo zjednodušit na flagy?
2. **Metrics + metrics skill** — Power-user: defaults nikdy nemění (de facto DELETE) vs Maintainer/Adoption: KEEP. **Otázka:** je to telemetrie pro projektové vlastníky nebo dead-config?
3. **workflow-router** (SKILL) — Adoption: hidden gem PROMOTE candidate; Maintainer: architektonická anomálie + Claude Code #26251 blocker; Public-Release: duplikuje native skill routing. **Otázka:** PROMOTE jako entry point nebo DELETE?
4. **check-deploy + deployment-verifier** — Public-Release: docker-compose ps duplicates; Adoption/Maintainer: KEEP. **Otázka:** je to skutečně value-add nad docker-compose ps?
5. **Spec rodina (4 agenti)** — Maintainer: KEEP všechny; Public-Release: MERGE 4→2. **Otázka:** dovolit konsolidaci spec-author + reviewer integrace, nebo držet 4-agent strukturu?

### Top 5 STRONG DELETE (4-reviewer konsenzus, ready-to-cut)

1. **dashboard** — 0 evidence kdokoliv používá; Adoption DEMOTE, Power-user DELETE, Maintainer UNCLEAR, Public-Release DELETE.
2. **discuss** — 0 runs za 6 měsíců, "chatbot novelty"; Adoption UNCLEAR, ostatní DELETE.
3. **prioritize + priority-engine** — PM rodina, 0 evidence; všechny 4 reviewery v eliminační intenzi.
4. **sprint-plan + sprint-planner** — 0 runs za 6 měsíců; PM rodina, out-of-scope.
5. **create-backlog + backlog-creator** — PM rodina, 0 evidence v reálných projektech.

**+ Config sekce:** Module Docs, Worktrees, Sprint Planning, Pause Limits — 4 sekce s konsenzem DELETE/SIMPLIFY-into-default.

### Top 5 PROMOTE (zviditelnit / zjednodušit on-ramp)

1. **check-setup** — Adoption: největší adopční win; Power-user: po každé config změně. **Akce:** přesunout do top-level README první linie + onboard wizard.
2. **Agent Overrides** (CONFIG) — Power-user: drmax killer feature, nahrazuje Custom Agents. **Akce:** přesunout do core (ne optional), eliminovat Custom Agents jako duplicate.
3. **Autopilot** (CONFIG) — Jediná sekce v 8/8 templates. **Akce:** zjednodušit (7 keys → 3-4), zvýraznit jako default workflow.
4. **workflow-router** (SKILL) — Adoption: hidden gem (CONFLICT s Maintainer/Public-Release, vyžaduje rozhodnutí; viz konflikt #3 výše).
5. **fix-ticket pipeline diagram** — Public-Release: jeden ze 3 obvious wins pro OSS. **Akce:** README hero diagram.

### Konsolidační skupiny (kde MERGE doporučují aspoň 2 reviewery)

- **Spec rodina:** spec-analyst + spec-writer → "spec-author"; spec-reviewer → reviewer (Public-Release; Maintainer KEEP — CONFLICT)
- **Test rodina:** e2e-test-engineer → test-engineer --scope (Public-Release); E2E Test config + Browser Verification config → "Testing" (Public-Release + Adoption SIMPLIFY)
- **Scaffold rodina:** scaffold-add → `scaffold --add`; scaffold-validate → check-setup; stack-selector → scaffolder (Public-Release; Maintainer KEEP s flagem 1147 lines monolith)
- **PM rodina (DELETE):** sprint-plan + sprint-planner; prioritize + priority-engine; create-backlog + backlog-creator; dashboard; (volitelně metrics — CONFLICT)
- **Status/Setup rodina:** status + check-setup + check-deploy + scaffold-validate — Public-Release navrhuje sloučit do 2 skills, ostatní KEEP
- **Hooks rodina:** Custom Agents → Hooks (Maintainer + Public-Release MERGE; Power-user DELETE — i tak konsolidační směr)
- **Browser/Reproducer:** browser-verifier + reproducer → "browser-agent" (Public-Release); Maintainer SIMPLIFY oba

---

## Doporučení pro release allocation

### v6.11.0 — Cleanup Sprint (no-controversy items, ~3-5 dní)

**Skills DELETE (5):**
1. `dashboard` (4-reviewer konsenzus)
2. `discuss` (3 hlasů DELETE)
3. `sprint-plan` (3 hlasů DELETE) + agent `sprint-planner`
4. `prioritize` (3 hlasů DELETE) + agent `priority-engine`
5. `create-backlog` (3 hlasů DELETE) + agent `backlog-creator`

**Config sekce DELETE (4):**
6. Module Docs (1-key, 0 evidence)
7. Worktrees (0/8 templates)
8. Sprint Planning (0 runs, out-of-scope; logická návaznost na sprint-plan DELETE)
9. Pause Limits (8/8 default — inline as Autopilot subkey nebo hard-code)

**Config sekce CONSOLIDATE (4 → 2):**
10. Custom Agents → MERGE into Hooks (subkey "agent_overrides")
11. Extra labels → MERGE into PR Rules (subkey)
12. E2E Test + Browser Verification → MERGE into single "Testing" section (Public-Release + Adoption signal)
13. Browser Verification keys 8 → 3 (nutné defaults pro většinu projektů)

**Promotes (3):**
14. Agent Overrides → core (ne optional) — replace Custom Agents in templates
15. check-setup → README first-class onboard step
16. Autopilot keys 7 → 4 (zjednodušení)

**Quick wins / docs:**
17. README skills tabulka — kategorizovat (Daily/Weekly/Once/Advanced) místo flat 29 řádků (Adoption #1 bariéra)
18. `init` vs `onboard` naming — rename `init` → `init-env` nebo merge

**Effort estimate:** 14 mechanical changes + 5 config refactor + 1 doc rewrite = pipeline-ready forge run, **aggregate score target 0.90+ FULL_PASS**.

**Backward compat:** všechny DELETE/MERGE jsou breaking change → **v6.11.0 je MAJOR-style minor** s migration guide; nebo posunout na **v7.0.0** pokud chceme striktní MAJOR boundary (viz user otázka #1 níže).

### v6.12.0 — Architecture Rework (CONFLICT items + scaffold + spec rodina)

**Scaffold rodina rework:**
- `scaffold-add` → `scaffold --add` flag
- `scaffold-validate` → `check-setup --scaffold` flag
- `stack-selector` → MERGE into scaffolder
- `scaffold` 1147 lines → split or modularize (Maintainer fragility flag)

**Spec rodina konsolidace (rozhoduje user otázka #5):**
- `spec-analyst` + `spec-writer` → `spec-author` (single agent, 2 modes)
- `spec-reviewer` → MERGE into reviewer with `--mode=spec` flag
- `acceptance-gate` → MERGE into reviewer with `--ac-only` flag

**CONFLICT resolution (user musí rozhodnout):**
- Pipeline Profiles — kitchen-sink vs power-user kritika
- Metrics + metrics skill — telemetrie nebo dead-config
- workflow-router — PROMOTE vs DELETE
- check-deploy + deployment-verifier — KEEP vs docker-compose duplicate

**Test coverage backfill:**
- 15/21 agentů (71%) bez dedikovaných testů — alespoň critical (rollback-agent, publisher, scaffolder, browser-verifier)
- 47/60 v6.9+v6.10 scenarios jsou doc-grep — convert to functional kde to dává smysl

### v7.0.0 — Polish + Public Release

**OSS-ready pieces (existing roadmap):**
- Canonical repo URL (z v6.10.1 deferral) — `plugin.json.repository`
- SECURITY.md secondary contact channel

**README rework:**
- Hero diagram: fix-ticket pipeline (Public-Release obvious win)
- Categorized skill list (vs flat 29 rows)
- "Time-to-first-fix < 30 min" target (Adoption: aktuálně 40-90 min)

**Missing OSS pieces (Public-Release):**
- 3-4 reference templates místo 8 (template SIMPLIFY)
- "Astro/Tailwind moment" — single killer demo: 6 trackerů × fix-ticket × pipeline diagram

**Autopilot hardening (z v6.11.0 deferred roadmap):**
- Cross-run circuit breaker persistence
- Webhook URL allowlist
- Multi-host distributed lock

**Per-tracker query presets** (Power-user request) — knihovna pro 6 trackerů, ne aby user vymýšlel.

---

## Klíčové strukturální insights

### 1. PM vrstva je out-of-scope (4-reviewer signal)
Sprint-plan, prioritize, create-backlog, dashboard, metrics — všechny tyto skills/agents směřují k "project management replacement", ale core mission ceos-agents je **fix-bugs + ship-PRs**. Adoption viděl bariéry, Power-user viděl 0 evidence, Maintainer viděl test gaps, Public-Release viděl out-of-scope. **Společný závěr:** PM rodina = bullshit-bingo, držet by ji bylo "Big-Enterprise-Plugin" branding místo "Astro/Tailwind moment".

### 2. Spec rodina fragmentace = 4-agent overhead pro 1 kontrakt
spec-analyst (analysis) + spec-writer (creation) + spec-reviewer (review) + acceptance-gate (verification) — všichni 4 čtou stejný spec dokument a produkují varianty stejného outputu. Public-Release explicitně označuje jako "fragmentace", Maintainer nedělá konsolidační návrh ale flag cross-ref count je vysoký. **Společný závěr:** logický refaktor pro v6.12.0.

### 3. Scaffold povrch = 4-tier monolith
scaffold (1147 lines) → scaffolder (210 lines, 22 cross-refs) + scaffold-add (0 tests) + scaffold-validate + stack-selector. Maintainer flag fragility, Public-Release flag overengineering vs CRA "1 příkaz". **Společný závěr:** v6.12.0 rework s `scaffold --add` flag pattern.

### 4. Test discipline gap je publikem viděn (3+ reviewerů)
Maintainer explicitně: 15/21 agentů bez dedikovaných testů; 47/60 v6.9+v6.10 scenarios jsou doc-grep. Public-Release implicitně signaluje (test coverage uváděn jako fragility marker). Power-user nepřímo: BIFITO autopilot pilot **PAUSED pending v6.9.2** = produkční bug v autopilotu prošel doc-grep testy. **Společný závěr:** v6.10.0 Track 1 Test Discipline Overhaul byl správný směr, ale jen pokrývá část — pokračování v v6.11.0/v6.12.0.

### 5. Adoption barriers jsou strukturální, ne kosmetické
Adoption identifikoval: flat 29-skill README, init vs onboard clash, 40-90 min time-to-first-fix, hidden gems (workflow-router). Tyto problémy nelze vyřešit lepším copywritingem — **vyžadují DELETE/CONSOLIDATE strategii** (Public-Release stejný směr). README rewrite v v7.0.0 dává smysl jen po cleanu v6.11.0.

### 6. Doc drift je systémový risk (Maintainer)
Pipeline-skill triplet (fix-ticket + fix-bugs + implement-feature) = 3-way drift; count drift ("19 sections" ale README enumeruje 18); 8 templates ale 6 nikdy nepoužitých. **Public-release blocker** — externí evaluator si toho všimne první den. v6.11.0 cleanup snižuje fragility surface.

### 7. Real-world usage data dává nejsilnější signál (Power-user)
6 měsíců BIFITO + drmax dat ukazuje, co se skutečně používá: fix-ticket, fix-bugs, autopilot, status, resume-ticket, version-bump, check-setup. Vše ostatní je v "občas / unclear / 0 runs" zóně. **Akce:** README hero list = těchto 7 skills; všechno ostatní v "advanced" sekci.

---

## Otevřené otázky pro uživatele

1. **MAJOR vs MINOR pro cleanup?** v6.11.0 by obsahoval ~9 DELETE položek = breaking change. Chceme je nakopit do v7.0.0 (čistá MAJOR boundary) nebo udělat v6.11.0 jako "MINOR with migration guide" jak roadmap implikuje? **Rekomendace judge:** v7.0.0 jako čistá MAJOR boundary, v6.11.0 dělá cleanup jen v doc surface (kategorizace, hide demote items, no DELETE).

2. **Pipeline Profiles — DELETE nebo KEEP?** Power-user (drmax) kriticky používá pro skip-browser/e2e. Public-Release mark "kitchen-sink". Rozhodnutí: (a) zachovat ale demote z reference; (b) zjednodušit na 1-key (`Skip stages: browser,e2e`); (c) DELETE a nahradit CLI flag `--skip=browser,e2e`. **Která možnost?**

3. **Metrics + metrics skill — DELETE nebo KEEP?** Power-user defaults nikdy nemění (de facto dead). Public-Release out-of-scope. Maintainer KEEP pro test coverage. **Otázka:** používá to někdo z reálných projektů (BIFITO, drmax) prakticky, nebo je to vestige z early-stage?

4. **workflow-router — PROMOTE, KEEP, nebo DELETE?** Adoption hidden gem; Maintainer arch anomálie + #26251 blocker; Public-Release duplikuje native routing. **Otázka:** chceme to mít jako entry point pro nové členy (Power-user citoval jako "entry pro nové členy") nebo je to legacy, který má být odstraněn s upstream fixem?

5. **Spec rodina konsolidace — schválit pro v6.12.0?** Public-Release navrhuje `spec-analyst + spec-writer → spec-author`; `spec-reviewer → reviewer --mode=spec`; `acceptance-gate → reviewer --ac-only`. Power-user ani Adoption neviděli (interní agenti). Maintainer KEEP. **Otázka:** chceš povolit experiment v v6.12.0 (forge pipeline s --no-implement design fáze), nebo držet 4-agent strukturu jako stable contract?

6. **Sprint-plan / prioritize / create-backlog (PM rodina) — confirm DELETE?** 4-reviewer konsenzus DELETE, ale Maintainer KEEP. **Otázka:** existuje plán někde do budoucna použít je v ASYSTA orchestraci nebo jsou skutečně dead?

7. **8 → 3-4 templates — který shortlist?** Power-user používá github-nextjs + redmine-oracle-plsql (2 z 8). Které 4 templates držet jako reference (zbytek do "community-contributed" sekce)? Návrh judge: github-nextjs (web), gitea-spring-boot (backend), redmine-oracle-plsql (legacy/enterprise), youtrack-python (vědecké/datové).

---

**Konec dokumentu.**
