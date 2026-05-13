# Roadmap: CLAUDE-agents — budoucí směřování

**Datum:** 2026-02-25
**Autor:** Filip Sabacky
**Status:** SUPERSEDED by 2026-02-28-v3.1-v5.0-roadmap-design.md
**Aktuální verze:** 2.0.0

---

## Motivace

CLAUDE-agents v2.0 pokrývá kompletní bug-fix pipeline: triage → analýza → fix → review → test → publish. Plugin je stabilní, generický a rozšiřitelný přes hooks a custom agenty. Tento dokument mapuje čtyři strategické směry dalšího rozvoje.

---

## 1. Feature Pipeline

### Problém

Plugin dnes umí jen opravovat bugy. Feature development je ale dominantní aktivita většiny týmů — a sdílí s bug-fixem velkou část workflow (fixer, reviewer, test-engineer, publisher jsou znovupoužitelné).

### Návrh

Nová pipeline pro feature implementaci s dvěma novými agenty a jedním novým commandem:

| Bug pipeline | Feature pipeline | Změna |
|---|---|---|
| Triage analyst | **Spec analyst** | NOVÝ agent — extrahuje requirements, acceptance criteria, scope |
| Code analyst | **Architect** | NOVÝ agent — navrhne design, identifikuje affected areas, API contract, decomposition |
| Fixer | Implementer | Stejný agent, jiný kontext (vytváří nový kód místo patche) |
| Reviewer | Reviewer | Beze změny |
| Test engineer | Test engineer | Beze změny |
| E2E test engineer | E2E test engineer | Beze změny |
| Publisher | Publisher | Beze změny |

**Nový command:** `/implement-feature <issue-id>`

**Nové agenty (2):**

#### Spec analyst (model: sonnet)

- Čte issue z trackeru (feature request, user story, epic)
- Extrahuje: cíl, acceptance criteria, out-of-scope, dependencies
- Výstup: strukturovaná specifikace předaná dalším agentům
- Read-only — žádné změny kódu

#### Architect (model: opus)

- Na základě specifikace a codebase navrhne:
  - Které soubory vytvořit / upravit
  - API contract (interfaces, endpoints, data models)
  - Dekompozici na subtasky (pokud je feature příliš velký pro jeden průchod)
- Výstup: implementační plán s ordered task list
- Read-only — žádné změny kódu

### Subtask decomposition

Klíčový rozdíl oproti bug-fixu: feature se často rozpadne na N nezávislých dílčích úkolů. Architect agent vydá ordered list subtasků, command je zpracuje sekvenčně (nebo paralelně přes worktrees).

```
Feature issue
  └→ Spec analyst → structured spec
      └→ Architect → [subtask-1, subtask-2, subtask-3]
          ├→ subtask-1: Implementer → Reviewer → Test → ✓
          ├→ subtask-2: Implementer → Reviewer → Test → ✓
          └→ subtask-3: Implementer → Reviewer → Test → ✓
      └→ Integration test (celá feature)
      └→ Publisher (jeden PR za celou feature)
```

### Automation Config rozšíření

```markdown
### Feature Workflow (optional)
| Klíč | Hodnota |
|------|---------|
| Feature query | Type: Feature AND State: Open |
| Max subtasks | 5 |
| Subtask strategy | sequential / parallel |
```

### Dopad na verzi

- Nová **volitelná** config sekce + nový command + 2 nové agenty = **MINOR** (v2.x.0)
- Existující bug pipeline se NEMĚNÍ

---

## 2. Subtask Decomposition Engine

### Problém

Jak bug-fix, tak feature pipeline naráží na situace, kdy je problém příliš velký na jeden průchod fixeru. Dnes to řeší člověk ručně (rozpadne issue, spustí pipeline vícekrát). Automatická dekompozice je prerekvizita pro feature pipeline, ale má hodnotu i pro složité bugy.

### Návrh

Architect agent (viz bod 1) produkuje ordered list subtasků. Command engine je zpracovává:

**Sekvenční mód (default):**
```
subtask-1 → commit → subtask-2 → commit → ... → squash/merge → PR
```

**Paralelní mód (vyžaduje worktrees):**
```
subtask-1 (worktree-1) ──→ merge ─→ PR
subtask-2 (worktree-2) ──→ merge ─┘
subtask-3 (worktree-3) ──→ merge ─┘
```

Paralelní mód je rychlejší, ale riskuje merge konflikty. Sequential je bezpečnější default.

### Guardrails

- Max subtasks limit (configurable, default 5) — ochrana proti "exploding decomposition"
- Každý subtask musí projít review + test před merge do feature branch
- Pokud subtask selže, zbytek se zastaví (fail-fast) nebo pokračuje (configurable)

### Dopad

- Součást feature pipeline (bod 1), ale může být aktivován i pro bug-fix (`/fix-ticket --decompose`)
- Vyžaduje rozšíření command engine o sekvenční zpracování subtask listu

---

## 3. UI vrstva

### Problém

Pipeline běží v terminálu bez vizuální zpětné vazby pro tým. Člověk, který pipeline spustil, vidí output. Nikdo jiný ne. Pro týmové použití chybí transparentnost.

### Tři úrovně (incrementální)

#### Level 1 — Static Dashboard (nízký effort)

**Co:** HTML stránka generovaná z issue tracker dat — stav pipeline per issue, kdo blokuje, historie průchodů.

**Jak:**
- Nový command `/dashboard` — query issue tracker, vygeneruje statický HTML
- Data: issue ID, stav pipeline (triage/fix/review/test/publish/blocked), timestamp, link na PR
- Výstup: `dashboard.html` v repo root (nebo konfigurovatelná cesta)
- Refresh: manuální (spustit `/dashboard` znovu)
- Technologie: plain HTML + inline CSS, žádné dependencies

**Automation Config:**
```markdown
### Dashboard (optional)
| Klíč | Hodnota |
|------|---------|
| Output path | ./reports/dashboard.html |
| Include closed | last 30 days |
```

**Hodnota:** Tým vidí na jednom místě, co se děje. PM vidí throughput. QA vidí, co je blocked.

**Effort:** 1 nový command, žádné nové agenty, žádná infrastruktura.

#### Level 2 — Live Monitoring (střední effort)

**Co:** Real-time stream z běžící pipeline. Webové UI zobrazuje, který agent právě pracuje, co dělá, kolik času zbývá.

**Jak:**
- Lightweight HTTP server (Node.js / Python) spuštěný jako background process
- Pipeline kroky zapisují events do souboru (JSONL) nebo na localhost endpoint
- UI čte events přes SSE (Server-Sent Events) a vykresluje progress bar per issue
- Gantt-style vizualizace: timeline agentů s barvami (zelená = ok, červená = blocked, šedá = pending)

**Prerekvizity:**
- Pipeline musí emitovat strukturované eventy (nový concern pro commands)
- Background server process (mimo scope čistého Claude Code pluginu — potřebuje companion tool)

**Hodnota:** Real-time visibility. Člověk nemusí sledovat terminál. Může odejít a zkontrolovat stav v browseru.

**Effort:** Companion tool (ne plugin), event emitting v commands, frontend.

#### Level 3 — Interactive Approval (vysoký effort)

**Co:** Člověk schvaluje kroky v UI místo v terminálu. Review diff v browseru. Approve/reject tlačítka. Komentáře k návrhu fixeru.

**Jak:**
- Web UI s approval workflow
- Pipeline se zastaví na "checkpoint" krocích a čeká na human input
- Diff viewer (Monaco editor / CodeMirror) pro review fixer output
- WebSocket komunikace mezi pipeline a UI

**Prerekvizity:**
- Level 2 (live monitoring) jako základ
- Bidirectional komunikace (UI → pipeline)
- Persistent state (pipeline čeká na approval, nesmí ztratit kontext)

**Hodnota:** Full team workflow. Junior dev spustí pipeline, senior review-uje v browseru. Devin-style UX bez Devin-style vendor lock-in.

**Effort:** Signifikantní. Prakticky samostatný produkt. Zvážit až po validaci Level 1 + 2.

### Doporučená strategie

Level 1 → validovat s týmem → Level 2 jen pokud je demand → Level 3 jen pokud Level 2 nestačí.

---

## 4. Greenfield — Scaffold Plugin

### Problém

CLAUDE-agents předpokládá existující codebase s `CLAUDE.md` + Automation Config. Pro nový projekt od nuly je potřeba:
1. Zvolit tech stack
2. Vygenerovat project structure
3. Nastavit CI/CD
4. Vytvořit `CLAUDE.md` s Automation Config
5. Pak teprve spustit feature pipeline

### Návrh: Samostatný plugin `CLAUDE-scaffold`

**Proč samostatný plugin:**
- Scaffolding běží jednou. Pipeline běží opakovaně. Jiný lifecycle.
- Jiné agenty (scaffold agent ≠ fixer agent).
- Jiný Automation Config (scaffold nepotřebuje Issue Tracker, ale potřebuje tech stack preferences).
- Menší blast radius — scaffold plugin nemění nic v CLAUDE-agents.

**Navržené agenty:**

| Agent | Model | Úkol |
|-------|-------|------|
| Stack selector | opus | Zvolí tech stack na základě requirements (jazyk, framework, DB, infra) |
| Scaffolder | sonnet | Vygeneruje project structure, boilerplate, config files |
| CI/CD configurator | sonnet | Nastaví GitHub Actions / Gitea Actions / GitLab CI |
| Config writer | haiku | Vygeneruje `CLAUDE.md` s Automation Config pro CLAUDE-agents |

**Flow:**

```
User: "Vytvoř REST API pro správu úkolů v Pythonu"
  └→ Stack selector → Python 3.12 + FastAPI + PostgreSQL + Docker
      └→ Scaffolder → project structure, requirements.txt, Dockerfile, app skeleton
          └→ CI/CD configurator → .gitea/workflows/ci.yml
              └→ Config writer → CLAUDE.md s Automation Config
                  └→ Initial commit + push
                      └→ HOTOVO — uživatel může spustit CLAUDE-agents pro feature development
```

**Automation Config pro scaffold (v CLAUDE-scaffold pluginu):**

```markdown
### Scaffold Config
| Klíč | Hodnota |
|------|---------|
| Default language | python |
| Default framework | fastapi |
| Git provider | gitea |
| CI provider | gitea-actions |
| Target repo | owner/repo |
```

### Synergie s CLAUDE-agents

Scaffold plugin generuje `CLAUDE.md` s validním Automation Config → uživatel nainstaluje CLAUDE-agents → feature pipeline (bod 1) vytváří první features → bug pipeline opravuje bugy. Celý lifecycle pokryt.

### Dopad

- **Nulový dopad na CLAUDE-agents** — scaffold je samostatný plugin
- Scaffold plugin může referencovat CLAUDE-agents jako recommended companion
- `/onboard` command z CLAUDE-agents může detekovat prázdný projekt a doporučit scaffold

---

## Srovnání s Devin AI

### Poziční mapa

| Dimenze | Devin AI | CLAUDE-agents (dnes) | CLAUDE-agents (roadmap) |
|---------|----------|---------------------|------------------------|
| **Architektura** | Monolitický autonomní agent | Pipeline specializovaných agentů | Pipeline + decomposition engine |
| **Kontrola** | Black-box, těžko auditovatelný | Každý krok definovaný, checkpointy | + interactive approval (Level 3) |
| **Infrastruktura** | Vlastní VM, browser, IDE | Zero infra — běží v Claude Code | + optional companion (Level 2) |
| **Cena** | $500/měsíc flat | Cena Claude API tokenů (pay-per-use) | Beze změny |
| **Customizace** | Minimální | Plná — agenti jsou markdown | + custom agents, hooks |
| **Spolehlivost** | "Goes off the rails" u komplexních tasků | Pipeline s retry + rollback | + decomposition = menší blast radius |
| **Scope** | Bug-fix + feature + greenfield | Jen bug-fix | Bug-fix + feature + greenfield (via scaffold) |
| **Team visibility** | Devin dashboard | Terminál | Dashboard → Live monitoring → Interactive |
| **Vendor lock-in** | Plný (Devin platform) | Žádný (markdown + Claude Code) | Žádný |

### Kde jsme lepší

1. **Auditovatelnost** — každý krok je definovaný markdown, člověk vidí přesně co se děje
2. **Customizace** — agenti, hooks, custom agents — vše konfigurovatelné per projekt
3. **Cena** — pay-per-use vs. $500/měsíc flat fee
4. **Rollback** — explicitní rollback agent, ne "undo" tlačítko
5. **Pipeline discipline** — strukturovaný workflow je spolehlivější než freeform autonomie

### Kde Devin vede (a jak dohnat)

1. **Feature development** → Bod 1 (feature pipeline) + Bod 2 (decomposition)
2. **Greenfield** → Bod 4 (scaffold plugin)
3. **Visual dashboard** → Bod 3 (UI vrstva, Level 1–3)
4. **Browser interaction** → Mimo scope (Devin má vlastní browser pro testování web UI)
5. **Persistent memory across sessions** → Claude Code memory + CLAUDE.md (už máme)

### Strategická pozice

CLAUDE-agents NENÍ a NEMÁ BÝT "Devin klon". Jiná filozofie:

- **Devin** = autonomní vývojář (nahrazuje člověka)
- **CLAUDE-agents** = orchestrovaná linka s lidským dohledem (augmentuje člověka)

Orchestrovaný přístup je v praxi spolehlivější, protože:
- Selhání je lokalizované (jeden agent, jeden krok)
- Retry a rollback jsou explicitní
- Člověk může zasáhnout v checkpointech
- Blast radius je omezený (max 100 řádků diff na fixer průchod)

---

## Roadmap — fáze a milníky

### Fáze 1: Feature Pipeline (v3.0)

**Scope:** Spec analyst + Architect + `/implement-feature` command + config rozšíření

**Předpoklady:**
- v2.0 pipeline stabilní a otestovaná v produkci (BIFITO)
- Feedback z reálného bug-fix usage (min. 10 úspěšných pipeline průchodů)

**Kroky:**
1. Design doc pro spec-analyst a architect agenty (frontmatter, Goal/Expertise/Process/Constraints)
2. Design doc pro `/implement-feature` command (pipeline flow, config, error handling)
3. Implementace spec-analyst agenta
4. Implementace architect agenta
5. Implementace `/implement-feature` command (sekvenční mód)
6. Rozšíření `/onboard` o Feature Workflow sekci
7. Rozšíření `/check-setup` o validaci Feature Workflow config
8. Rozšíření skill routing o feature intenty ("implementuj", "feature", "nová funkcionalita")
9. Smoke test v BIFITO nebo jiném projektu
10. README + CHANGELOG update

**Versioning:** MINOR (v3.0.0) — nová volitelná funkce, žádný breaking change

**Rizika:**
- Architect agent může generovat příliš granulární nebo příliš hrubé subtasky → potřeba calibrace
- Feature issues mají méně strukturovaný popis než bug reporty → spec analyst musí být robustní

---

### Fáze 2: Subtask Decomposition (v3.1)

**Scope:** Sekvenční zpracování subtasků, paralelní mód (worktrees), `--decompose` flag pro bug-fix

**Předpoklady:**
- Fáze 1 hotová a stabilní
- Architect agent produkuje spolehlivé task listy

**Kroky:**
1. Design doc pro decomposition engine (sekvenční vs. paralelní, merge strategie, fail handling)
2. Rozšíření `/implement-feature` o multi-subtask zpracování
3. Implementace sekvenčního módu (subtask → commit → next subtask)
4. Implementace paralelního módu (worktrees, merge, conflict detection)
5. Přidání `--decompose` flagu do `/fix-ticket` pro složité bugy
6. Guardrails: max subtasks limit, fail-fast vs. continue config
7. Test s reálnou multi-file feature

**Versioning:** MINOR (v3.1.0)

**Rizika:**
- Paralelní mód může generovat merge konflikty → potřeba conflict resolution strategie
- Subtask ordering matters — špatné pořadí = build failures

---

### Fáze 3: Dashboard — Level 1 (v3.2)

**Scope:** Statický HTML dashboard, nový `/dashboard` command

**Předpoklady:**
- Fungující issue tracker integrace (bug + feature pipeline)
- Dostatek dat pro smysluplný dashboard

**Kroky:**
1. Design doc pro dashboard (layout, data model, config)
2. Implementace `/dashboard` command
3. HTML template s inline CSS (responsive, dark/light mode)
4. Konfigurace: output path, date range, issue filter
5. Rozšíření skill routing o "dashboard" / "přehled" / "report"
6. Dokumentace

**Versioning:** MINOR (v3.2.0)

**Rizika:**
- Nízké — statický HTML bez dependencies, jasně definovaný scope

---

### Fáze 4: Scaffold Plugin (samostatný repo)

**Scope:** Nový plugin `CLAUDE-scaffold` — stack selection, project generation, CI/CD setup, CLAUDE.md generation

**Předpoklady:**
- Feature pipeline stabilní (Fáze 1)
- Jasné patterns pro Automation Config (validované na 2+ projektech)

**Kroky:**
1. Nový repozitář `CLAUDE-scaffold`
2. Design doc pro scaffold pipeline (stack selector, scaffolder, CI/CD, config writer)
3. Implementace 4 agentů
4. Implementace `/scaffold` command
5. Template library pro běžné stack kombinace (Python+FastAPI, Node+Express, Java+Spring...)
6. Integrace: scaffold generuje validní CLAUDE.md → CLAUDE-agents funguje okamžitě
7. Test: scaffold → feature pipeline → bug-fix pipeline end-to-end
8. Plugin marketplace listing

**Versioning:** Samostatný plugin, vlastní semver (v1.0.0)

**Rizika:**
- Scaffolding je highly opinionated — nutná flexibilita pro různé stack preference
- Template maintenance burden — frameworky se mění

---

### Fáze 5: Live Monitoring — Level 2 (budoucnost)

**Scope:** Companion tool pro real-time pipeline vizualizaci

**Předpoklady:**
- Dashboard Level 1 validován s týmem
- Jasný demand pro real-time visibility

**Kroky:**
1. Rozhodnutí o technologii (Node.js SSE server vs. Python WebSocket vs. jiné)
2. Event emitting protokol pro commands (JSONL nebo structured events)
3. Implementace companion serveru
4. Frontend (lightweight SPA nebo terminal UI)
5. Integrace s CLAUDE-agents commands (event hooks)

**Poznámka:** Toto přesahuje scope čistého Claude Code pluginu. Vyžaduje companion tool s vlastním lifecycle. Realizovat jen pokud Level 1 nepostačuje potřebám týmu.

---

### Fáze 6: Interactive Approval — Level 3 (dlouhodobá vize)

**Scope:** Web UI s approval workflow, diff viewer, bidirectional komunikace

**Předpoklady:**
- Level 2 funguje a je adoptován
- Tým aktivně požaduje review workflow v browseru

**Poznámka:** Toto je prakticky samostatný produkt. Zvážit až po validaci Level 1 + 2. Může být realizováno jako open-source companion project nebo jako komerční extension.

---

## Prioritizace a závislosti

```
Fáze 1 (Feature Pipeline)
  ↓
Fáze 2 (Decomposition) ←── závisí na Fáze 1
  ↓
Fáze 3 (Dashboard L1) ←── nezávisí na Fáze 2, ale lepší s daty z feature pipeline
  ↓
Fáze 4 (Scaffold) ←── závisí na Fáze 1 (generuje config pro feature pipeline)
  ↓
Fáze 5 (Live Monitoring) ←── závisí na Fáze 3 (rozšíření dashboardu)
  ↓
Fáze 6 (Interactive) ←── závisí na Fáze 5 (rozšíření monitoringu)
```

**Nejvyšší ROI:** Fáze 1 (Feature Pipeline) — znovupoužívá 60% existujícího kódu, rozšiřuje scope pluginu na dominantní use case.

**Quick win:** Fáze 3 (Dashboard L1) — může být implementován paralelně s čímkoli, nízký effort, okamžitá hodnota pro tým.

---

## Metriky úspěchu

| Fáze | Metrika | Cíl |
|------|---------|-----|
| Feature Pipeline | Úspěšně implementovaných features bez human intervention | >50% |
| Decomposition | Subtasky, které projdou review na první pokus | >70% |
| Dashboard | Týmová adopce (kolik lidí dashboard kontroluje) | >3 lidé |
| Scaffold | Čas od "chci nový projekt" po "první feature PR" | <30 minut |
| Live Monitoring | Redukce "co se děje?" dotazů v chatu | >80% |
