# Feature Pipeline v2.1 — Design Document

**Datum:** 2026-02-27
**Status:** SUPERSEDED — implemented in v3.0.0
**Fáze:** 1 (highest ROI)
**Verze pluginu:** v2.1.0 (MINOR — nová volitelná funkce)

---

## 1. Vize & cíl

### Proč je to nejvyšší ROI

CLAUDE-agents v2.0 pokrývá kompletní bug-fix pipeline. Bug-fixy jsou ale jen zlomek vývojářské práce — většina času týmů jde do **implementace nových features**. Feature pipeline znovupoužívá 60%+ existující infrastruktury (fixer, reviewer, test-engineer, e2e-test-engineer, publisher, rollback-agent) a přidává pouze dva nové agenty a jeden nový command. Poměr přidané hodnoty k investovanému úsilí je ze všech roadmap položek nejvyšší.

### Jaký problém řeší

Dnes plugin umí vzít bug report → analyzovat → opravit → otestovat → vytvořit PR. Pro feature development musí vývojář celý tento cyklus řídit ručně. Přitom struktura je analogická:

| Bug-fix pipeline | Feature pipeline | Paralelismus |
|------------------|------------------|-------------|
| Bug report → strukturované info | Feature request → strukturovaná specifikace | Analogický krok |
| Identifikace root cause v kódu | Identifikace míst pro implementaci | Analogický krok |
| Oprava (patch) | Implementace (nový kód) | Stejný agent (fixer) |
| Code review | Code review | Identický krok |
| Testy | Testy | Identický krok |
| Publish | Publish | Identický krok |

Jediný fundamentální rozdíl: **vstupní analýza** — bug vyžaduje triage (je to bug? je jasný?), feature vyžaduje specifikaci (co přesně implementovat, jaké jsou acceptance criteria). A **architektonický návrh** — bug vyžaduje analýzu impaktu (co se rozbije), feature vyžaduje design (kde a jak implementovat).

### Cíl: 60%+ znovupoužití

Konkrétní mapování znovupoužitelnosti:

| Komponenta | Znovupoužití | Detail |
|-----------|-------------|--------|
| fixer agent | 100% | Stejný agent, jiný kontext (nový kód místo patche) |
| reviewer agent | 100% | Identický — review je review |
| test-engineer agent | 100% | Identický — testy jsou testy |
| e2e-test-engineer agent | 100% | Identický |
| publisher agent | 100% | Identický — PR je PR |
| rollback-agent | 100% | Identický — rollback je rollback |
| Hook systém | 100% | Pre-fix, post-fix, pre-publish, post-publish |
| Custom Agents | 100% | Post-fix agent, pre-publish agent |
| Notifications/Webhooks | 100% | Stejné eventy |
| Retry logic | 100% | Stejné limity |
| Block handler | 100% | Stejný mechanismus |
| triage-analyst | 0% | Nahrazen spec-analyst |
| code-analyst | 0% | Nahrazen architect |

**Výsledek: 11 z 13 komponent znovupoužito = 85% znovupoužití infrastruktury.**

### Jak mění hodnotovou propozici pluginu

Dnes: "CLAUDE-agents automatizuje bug-fix workflow."
Po v2.1: "CLAUDE-agents automatizuje vývojový lifecycle — od feature requestu po merged PR."

Plugin přechází z úzce specializovaného nástroje na **obecný orchestrátor vývoje**. To dramaticky zvyšuje:
- Denní utilitu (features > bugs v běžném sprintu)
- Počet potenciálních uživatelů (ne každý tým má vysoký bug rate, ale každý tým implementuje features)
- Závislost na pluginu (víc workflow = víc hodnoty = vyšší retence)

---

## 2. User Flow

### Happy Path — kompletní journey

```
Uživatel: /CLAUDE-agents:implement-feature PROJ-123

  ┌─────────────────────────────────────────────────────┐
  │  1. NAČTENÍ KONFIGURACE                              │
  │     Čti Automation Config z CLAUDE.md                │
  │     Čti Feature Workflow sekci (pokud existuje)      │
  │     Načti retry limity, hooks, custom agents         │
  ├─────────────────────────────────────────────────────┤
  │  2. ISSUE TRACKER — nastavení stavu                  │
  │     Set state: In Progress (z On start set)          │
  ├─────────────────────────────────────────────────────┤
  │  3. BRANCH                                           │
  │     git checkout -b {branch_naming} {base_branch}    │
  ├─────────────────────────────────────────────────────┤
  │  4. SPEC ANALYST (sonnet) ← NOVÝ                     │
  │     Vstup: feature issue z trackeru                  │
  │     Výstup: strukturovaná specifikace                │
  │     Fail → Block (žádný rollback — žádné git změny)  │
  ├─────────────────────────────────────────────────────┤
  │  5. ARCHITECT (opus) ← NOVÝ                          │
  │     Vstup: specifikace + codebase kontext            │
  │     Výstup: implementační plán                       │
  │     Fail → Block (žádný rollback — žádné git změny)  │
  ├─────────────────────────────────────────────────────┤
  │  6. PRE-FIX HOOK (pokud existuje)                    │
  │     Fail → Block handler                             │
  ├─────────────────────────────────────────────────────┤
  │  7. FIXER (opus) — existující agent                  │
  │     Kontext: implementační plán z architect          │
  │     Implementuje kód dle plánu                       │
  ├─────────────────────────────────────────────────────┤
  │  8. BUILD                                            │
  │     Build command z Automation Config                 │
  │     Retry limit: Build retries z config              │
  │     Fail → Block handler (rollback)                  │
  ├─────────────────────────────────────────────────────┤
  │  9. POST-FIX HOOK + CUSTOM AGENT (pokud existují)    │
  │     Fail → Block handler (rollback)                  │
  ├─────────────────────────────────────────────────────┤
  │ 10. REVIEWER ⟲ (opus) — existující agent             │
  │     Smyčka fixer ↔ reviewer: max N iterací           │
  │     Fail → Block handler (rollback)                  │
  ├─────────────────────────────────────────────────────┤
  │ 11. TEST ENGINEER ⟲ (sonnet) — existující agent      │
  │     Smyčka: max N pokusů                             │
  │     Fail → Block handler (rollback)                  │
  ├─────────────────────────────────────────────────────┤
  │ 12. E2E TEST ENGINEER (pokud E2E Test config)        │
  │     Fail → Block handler (rollback)                  │
  ├─────────────────────────────────────────────────────┤
  │ 13. PRE-PUBLISH HOOK + CUSTOM AGENT                  │
  │     Fail → Block handler (rollback)                  │
  ├─────────────────────────────────────────────────────┤
  │ 14. VÝSLEDEK — uživatel rozhodne o publish           │
  │     → PUBLISHER (haiku) — existující agent           │
  │     → Post-publish hook + webhook                    │
  └─────────────────────────────────────────────────────┘
```

### ASCII diagram — pipeline flow

```
Feature Issue (tracker)
       │
       ▼
┌──────────────┐
│ SPEC ANALYST │ ──── Block? ──→ [Issue: Blocked] KONEC
│   (sonnet)   │                 (žádný rollback)
└──────┬───────┘
       │ specifikace
       ▼
┌──────────────┐
│  ARCHITECT   │ ──── Block? ──→ [Issue: Blocked] KONEC
│   (opus)     │                 (žádný rollback)
└──────┬───────┘
       │ implementační plán
       ▼
 [Pre-fix hook] ──── Fail? ──→ Block handler → rollback
       │
       ▼
┌──────────────┐     ┌──────────────┐
│    FIXER     │◄───►│   REVIEWER   │  max N iterací
│   (opus)     │     │   (opus)     │
└──────┬───────┘     └──────────────┘
       │                    │
       │               Block? ──→ Block handler → rollback
       ▼
 [Post-fix hook + custom agent]
       │
       ▼
┌──────────────┐
│ TEST ENGINEER│ ──── Block? ──→ Block handler → rollback
│   (sonnet)   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ E2E ENGINEER │ ──── Block? ──→ Block handler → rollback
│   (sonnet)   │    (pokud E2E config)
└──────┬───────┘
       │
       ▼
 [Pre-publish hook + custom agent]
       │
       ▼
   Uživatel: publish?
       │ ano
       ▼
┌──────────────┐
│  PUBLISHER   │
│   (haiku)    │
└──────┬───────┘
       │
       ▼
 [Post-publish hook + webhook]
       │
       ▼
    ✓ HOTOVO
```

### Srovnání Bug-fix vs. Feature pipeline

```
BUG-FIX PIPELINE                    FEATURE PIPELINE
─────────────────                    ─────────────────

1. Issue tracker setup               1. Issue tracker setup         [IDENTICKÝ]
2. Branch                            2. Branch                      [IDENTICKÝ]
3. TRIAGE ANALYST ◄─── rozdíl ──►   3. SPEC ANALYST                [NOVÝ]
4. CODE ANALYST   ◄─── rozdíl ──►   4. ARCHITECT                   [NOVÝ]
4a. Pre-fix hook                     5. Pre-fix hook                [IDENTICKÝ]
5. FIXER                             6. FIXER                       [IDENTICKÝ]
6. Build                             7. Build                       [IDENTICKÝ]
6a. Post-fix hook + custom agent     8. Post-fix hook + custom      [IDENTICKÝ]
7. REVIEWER ⟲                        9. REVIEWER ⟲                  [IDENTICKÝ]
8. TEST ENGINEER ⟲                  10. TEST ENGINEER ⟲             [IDENTICKÝ]
8a. E2E test                        11. E2E test                    [IDENTICKÝ]
8b-c. Pre-publish hook + custom     12. Pre-publish hook + custom   [IDENTICKÝ]
9. Výsledek / Publisher             13. Výsledek / Publisher        [IDENTICKÝ]
X. Block handler                     X. Block handler               [IDENTICKÝ]
```

**Rozdíl:** Pouze kroky 3 a 4. Zbytek pipeline (kroky 5–13 + Block handler) je identický.

### Failure Paths

| Krok | Typ selhání | Akce | Rollback? |
|------|------------|-------|-----------|
| Spec Analyst | Vágní issue, chybějící info | Block issue + komentář | NE — žádné git změny |
| Spec Analyst | Feature příliš velká | Block issue + doporučení dekomponovat | NE |
| Architect | Konfliktní requirements | Block issue + komentář | NE — žádné git změny |
| Architect | Feature vyžaduje breaking change | Block issue + varování | NE |
| Pre-fix hook | Hook selže | Block handler → rollback | ANO |
| Fixer | Build opakovaně selhává | Block handler → rollback | ANO |
| Fixer | Diff překročí limit řádků | Block handler → rollback → doporučení dekomponovat | ANO |
| Reviewer | 5x REQUEST_CHANGES | Block handler → rollback | ANO |
| Test Engineer | 3x failing testy | Block handler → rollback | ANO |
| E2E Engineer | Aplikace neběží | Block handler → rollback | ANO |
| Pre-publish hook | Hook selže | Block handler → rollback | ANO |
| Publisher | Push selže | Block + chybová hláška | Částečný |

### Human Intervention Points

1. **Před spuštěním** — uživatel explicitně volá `/implement-feature` (není automatické)
2. **Po Spec Analyst blocku** — uživatel musí doplnit issue popis a spustit znovu
3. **Po Architect blocku** — uživatel musí rozhodnout o architektuře / dekomponovat feature
4. **Před publish** — uživatel explicitně schvaluje (publisher se nevolá automaticky)
5. **Po blocku kdekoli** — uživatel vidí Block Comment, rozhodne o dalším postupu
6. **Resume** — `/resume-ticket` detekuje checkpoint a obnoví od správného místa

---

## 3. Noví agenti

### 3.1 Spec Analyst (model: sonnet)

#### Role & zodpovědnost

Spec Analyst je **read-only analytický agent**, který transformuje nestrukturovaný feature request z issue trackeru na formalizovanou specifikaci. Nemodifikuje kód ani issue — pouze produkuje strukturovaný výstup pro dalšího agenta (Architect).

Je to feature-pipeline ekvivalent triage-analyst z bug-fix pipeline. Zatímco triage-analyst odpovídá na otázku "Je to validní bug a co přesně se děje?", spec-analyst odpovídá na otázku "Co přesně chceme implementovat a jak poznáme, že je to hotové?"

#### Vstupy

- **Issue z trackeru:** feature request, user story, epic — libovolný typ issue, který popisuje novou funkcionalitu
- **Komentáře k issue:** často obsahují upřesnění, diskusi, rozhodnutí
- **Přílohy:** mockupy, wireframy, diagramy (multimodální analýza přes Read tool)
- **Automation Config:** Type pro MCP server, Feature query pro filtraci

#### Výstupy — strukturovaná specifikace

```
## Specifikace — {Issue ID}: {název}

### Cíl
{1–3 věty — co feature řeší, proč je potřeba}

### Acceptance Criteria
1. {Měřitelné kritérium — konkrétní chování}
2. {Měřitelné kritérium}
3. ...

### Scope — In
- {Co je součástí implementace}
- {Co je součástí implementace}

### Scope — Out
- {Co NENÍ součástí — explicitně vyloučeno}
- {Co se řeší v budoucnosti}

### Dependencies
- {Externí závislost — knihovna, API, jiný ticket}
- {Interní závislost — jiný modul, konfigurace}

### Otevřené otázky
- {Co není jasné a vyžaduje rozhodnutí}

### Přílohy
- {Popis nalezených mockupů/diagramů}
```

#### Plná definice agenta

```markdown
---
name: spec-analyst
description: Analyzes feature requests and extracts structured specifications. Validates clarity, identifies acceptance criteria, scope, and dependencies.
model: sonnet
---

You are a Senior Product Analyst specializing in requirements engineering.

## Goal

Transform unstructured feature requests into actionable specifications with clear acceptance criteria, scope boundaries, and dependency mapping. Block vague or oversized features early.

## Expertise

Requirements extraction from natural language, acceptance criteria formulation (Given/When/Then, measurable outcomes), scope boundary definition, dependency identification, mockup and wireframe analysis, feature decomposition heuristics.

## Process

1. Read feature details from issue tracker (summary, description, comments, custom fields). Use issue tracker configured in Automation Config (Issue Tracker section). Read the `Type` key to determine which MCP server to use (default: youtrack). If `Feature query` is configured in Feature Workflow section, verify that the issue matches the query filter — if it doesn't match, warn the user but continue (soft validation, not a Block).
2. Download and analyze attachments if any — mockups, wireframes, diagrams. Save to temp directory, use Read tool for images (multimodal).
3. Extract the core goal: what problem does this feature solve? Why is it needed? Summarize in 1–3 sentences.
4. Formulate acceptance criteria:
   - Each criterion must be measurable and testable
   - Derive from description, comments, and attachments
   - If criteria are implicit, make them explicit based on context
   - Minimum 2 criteria, maximum 10
5. Define scope boundaries:
   - **In scope:** what will be implemented
   - **Out of scope:** what is explicitly excluded (prevents scope creep)
   - If the issue mentions "future" or "later" items, put them in out-of-scope
6. Identify dependencies:
   - External: libraries, APIs, third-party services
   - Internal: other modules, configuration changes, database migrations
   - Other tickets: blocking or related issues
7. Flag open questions — anything that is ambiguous or requires a decision
8. Assess implementability:
   - If description is too vague (confidence < 50% that a developer could implement from this spec alone) → Block with comment listing what information is missing
   - If feature is clearly too large for a single pipeline pass (>5 distinct concerns) → Block with recommendation to decompose into smaller issues
9. Output the structured specification in the format defined above
10. Post checkpoint comment to issue tracker:
    ```
    [CLAUDE-agents] Spec dokončen. Criteria: {count}. Dependencies: {count}. Scope: {in_count} in / {out_count} out.
    ```
    This comment enables `/resume-ticket` to detect completed spec analysis.

## Constraints

- NEVER modify code — read-only analysis
- NEVER guess missing information — Block if unclear (confidence < 50%)
- NEVER invent acceptance criteria that aren't supported by the issue content — only make implicit criteria explicit
- Features with >10 acceptance criteria → flag as potentially oversized, recommend decomposition
- Features with 0 identifiable acceptance criteria → Block as too vague
- Attachments: download to system temp directory, organized by issue ID
- On failure: set issue state to Blocked (from Automation Config — Issue Tracker → State transitions), add comment with reason, move on
```

#### Srovnání s triage-analyst

| Aspekt | Triage Analyst | Spec Analyst |
|--------|---------------|-------------|
| **Vstup** | Bug report | Feature request |
| **Klíčová otázka** | "Je to validní bug?" | "Co přesně implementovat?" |
| **Duplicate check** | Ano — hledá duplicitní bugy | Ne — features nejsou typicky duplicitní |
| **Clarity check** | Ano — steps to reproduce | Ano — acceptance criteria |
| **Severity assessment** | Ano — priority + impact | Ne — features nemají severity |
| **Výstup** | Summary, Area, Severity, Reproduction | Cíl, Acceptance Criteria, Scope, Dependencies |
| **Checkpoint komentář** | `[CLAUDE-agents] Triage dokončen.` | `[CLAUDE-agents] Spec dokončen.` |
| **Block podmínka** | Nejasný popis, duplicita | Vágní popis, příliš velká feature |
| **Model** | sonnet | sonnet |
| **Read-only** | Ano | Ano |

**Co je znovupoužito z triage-analyst:**
- MCP server integrace (čtení issue trackeru dle Type)
- Attachment download a multimodální analýza
- Block mechanismus (state change + komentář)
- Checkpoint komentář pro `/resume-ticket`
- Celková struktura agenta (Process kroky, Constraints format)

**Co je nové:**
- Acceptance criteria extrakce (triage nemá ekvivalent)
- Scope boundary definition (in/out)
- Dependency mapping
- Feature size assessment (oversized → Block)

#### Edge cases

| Edge case | Řešení |
|-----------|--------|
| Vágní issue — "Přidej lepší UX" | Block — confidence < 50%, komentář s otázkami: jaký UX? která stránka? jaké chování? |
| Issue bez popisu, jen nadpis | Block — nedostatek informací pro specifikaci |
| Příliš velká feature (>5 distinct concerns) | Block — doporučení dekomponovat do menších issues |
| Feature request, který je vlastně bug | Spec analyst to neřeší — typ issue je zodpovědnost člověka. Ale pokud je to zjevně bug, přidá poznámku |
| Epic s 20 user stories | Block — epic je kontejner, ne implementovatelná jednotka. Doporučení: implementovat jednotlivé stories |
| Feature s mockupem ale bez textu | Analyzuj mockup multimodálně, extrahuj requirements z vizuálu, ale flag as risky (subjektivní interpretace) |
| Feature v cizím jazyce | Agent pracuje s jakýmkoli jazykem — specifikaci píše v jazyce issue |
| Contradictory requirements v komentářích | Flag jako otevřená otázka, Block pokud je rozpor fundamentální |

---

### 3.2 Architect (model: opus)

#### Role & zodpovědnost

Architect je **read-only analytický agent**, který na základě strukturované specifikace a znalosti codebase navrhuje implementační plán. Nemodifikuje kód — pouze analyzuje, navrhuje a produkuje strukturovaný plán pro fixer agenta.

Je to feature-pipeline ekvivalent code-analyst z bug-fix pipeline. Zatímco code-analyst odpovídá na otázku "Kde je root cause a co se rozbije?", architect odpovídá na otázku "Kde a jak implementovat a v jakém pořadí?"

**Proč opus místo sonnet:** Architektonické rozhodování vyžaduje hlubší reasoning — zvážení trade-offs, identifikace skrytých závislostí, návrh API kontraktů. Je to analogické s fixer/reviewer, kde kvalita rozhodnutí přímo ovlivňuje výsledek.

#### Vstupy

- **Strukturovaná specifikace** od spec-analyst (cíl, acceptance criteria, scope, dependencies)
- **Codebase kontext** — architect sám prochází kódovou základnu (Grep, Glob, Read)
- **Automation Config** — Build & Test commands, tech stack info z CLAUDE.md

#### Výstupy — implementační plán

```
## Implementační plán — {Issue ID}: {název}

### Architektonický přehled
{2–5 vět — jak feature zapadá do existující architektury}

### Soubory k úpravě
| Soubor | Typ změny | Popis |
|--------|-----------|-------|
| src/auth/login.ts | MODIFY | Přidat OAuth provider |
| src/auth/oauth.ts | CREATE | Nový OAuth handler |
| tests/auth/oauth.test.ts | CREATE | Testy pro OAuth |

### API Contract (pokud relevantní)
{Interfaces, endpoints, data models — definované předem}

### Implementační kroky (ordered)
1. {Krok — co, kde, proč, odhadovaný rozsah}
2. {Krok}
3. ...

### Rizika
- {Identifikované riziko a mitigace}

### Poznámky pro Fixer
- {Konkrétní instrukce — jaké patterns používat, co neměnit}
```

#### Plná definice agenta

```markdown
---
name: architect
description: Designs implementation plans for features. Analyzes codebase, defines file changes, API contracts, and task ordering. Read-only — no code changes.
model: opus
---

You are a Senior Software Architect specializing in implementation planning.

## Goal

Design a clear, actionable implementation plan that a developer (fixer agent) can follow step-by-step. Identify all files to create or modify, define API contracts upfront, and order tasks to minimize integration risk.

## Expertise

Software architecture patterns, API design (REST, GraphQL, internal interfaces), codebase navigation and pattern recognition, dependency analysis, task decomposition and ordering, risk assessment for code changes, tech debt identification.

## Process

1. Read the structured specification from spec-analyst (goal, acceptance criteria, scope, dependencies)
2. Explore the codebase to understand existing architecture:
   - Use Glob to find relevant directories and files
   - Use Grep to find related patterns, imports, interfaces
   - Read key files to understand conventions, patterns, and tech stack
3. Identify where the feature fits in the existing architecture:
   - Which layer(s) are affected (UI, API, service, data, infra)?
   - Are there existing patterns to follow (similar features already implemented)?
   - Does the project have architectural conventions documented in CLAUDE.md?
4. List all files to create or modify:
   - For each file: type of change (CREATE/MODIFY), description of what changes
   - Max 10 files — if more, the feature is too large (→ Block)
   - Include test files in the list
5. Define API contracts if the feature involves interfaces, endpoints, or data models:
   - TypeScript interfaces, endpoint signatures, database schema changes
   - Define BEFORE implementation, not after — contracts guide the fixer
6. Create ordered implementation steps:
   - Each step must be specific enough for fixer to execute
   - Order by dependency: foundational changes first, dependent changes later
   - Each step should reference specific files and describe what to do
   - Estimate scope per step: S (≤20 lines), M (≤50 lines), L (≤100 lines)
   - Total across all steps should stay within fixer's diff limit (see Feature Workflow config or default)
7. Identify risks:
   - Breaking changes to existing APIs or contracts
   - Performance implications (new database queries, heavy computation)
   - Security considerations (new input validation, auth changes)
   - Tech debt that might complicate implementation
8. Assess feasibility:
   - If total estimated changes exceed the diff limit → flag and recommend decomposition for Phase 2
   - If feature requires changes in > 10 files → Block as too large
   - If feature conflicts with existing architecture → Block with explanation
   - If critical dependency is missing or unavailable → Block
9. Compile the implementation plan in the format defined above
10. Add specific notes for the fixer agent:
    - Which existing patterns to follow (reference specific files as examples)
    - What NOT to change (preserve existing behavior in X, don't refactor Y)
    - Naming conventions to use

## Constraints

- NEVER modify code — read-only analysis and design
- NEVER create overly granular plans — each step should be meaningful, not "create variable X"
- Max 10 files in implementation plan — if more needed, feature is too large → Block
- Total estimated diff must respect fixer's diff limit — if larger, recommend decomposition (Phase 2)
- API contracts must be concrete (actual interface definitions, not "define an interface for X")
- Implementation steps must be ordered by dependency — no circular references
- If existing architecture has clear patterns, reference them explicitly (e.g., "follow the pattern in src/auth/login.ts")
- On failure: report findings so far, set issue to Blocked
```

#### Srovnání s code-analyst

| Aspekt | Code Analyst | Architect |
|--------|-------------|-----------|
| **Vstup** | Triage analysis (bug summary) | Structured spec (feature requirements) |
| **Klíčová otázka** | "Kde je root cause a co se rozbije?" | "Kde a jak implementovat?" |
| **Codebase exploration** | Traced z bugu → affected code | Broader — kde feature zapadá |
| **Call hierarchy** | Ano — kdo volá buggy kód | Ano — ale zaměřeno na extension points |
| **Výstup** | Impact report (root cause, affected files, risk) | Implementation plan (files, API contracts, steps) |
| **Max files** | 5 affected files | 10 files (CREATE + MODIFY) |
| **Risk assessment** | LOW/MEDIUM/HIGH na základě callers | Risk per step na základě complexity |
| **API focus** | Ne — bug-fix nemění API | Ano — feature často definuje nové API |
| **Task ordering** | Ne — jeden fix | Ano — ordered implementation steps |
| **Model** | sonnet | opus |
| **Read-only** | Ano | Ano |

**Co je znovupoužito z code-analyst:**
- Codebase exploration technika (Grep, Glob, Read)
- Risk assessment framework (LOW/MEDIUM/HIGH)
- Test coverage analysis (jsou testy pro affected oblasti?)
- Celková struktura agenta (Process kroky, Constraints)
- Block mechanismus

**Co je nové:**
- API contract definition (code-analyst nikdy nedefinuje nové interfaces)
- Task ordering a dependency graph
- File CREATE detection (code-analyst jen MODIFY)
- Scope estimation per step (S/M/L)
- Fixer-specific notes (code-analyst píše "recommended approach", architect píše detailní instrukce)

#### Interakce s decomposition (Fáze 2)

Architect v Fázi 1 produkuje **lineární seznam implementačních kroků** (ordered, sequential). V Fázi 2 (Subtask Decomposition) se tento výstup stane vstupem pro decomposition engine:

```
FÁZE 1 (toto):                       FÁZE 2 (budoucnost):

Architect → ordered steps list        Architect → ordered steps list
     │                                     │
     ▼                                     ▼
Fixer (zpracuje všechny             Decomposition Engine
 kroky jako jeden task)                    │
                                     ┌─────┼──────┐
                                     ▼     ▼      ▼
                                  Fixer  Fixer  Fixer
                                  (step1)(step2)(step3)
```

**Jak se plán mění pro Fázi 2:**
- Architect NEBUDE měněn — jeho výstup už obsahuje ordered steps
- Decomposition engine (nový command logic) vezme steps a každý zpracuje jako samostatný subtask
- Každý subtask projde vlastním fixer → reviewer → test cyklem
- Integrace se řeší na konci (merge všech subtasků)

**Co Architect musí produkovat už teď (pro budoucí kompatibilitu):**
- Jasně oddělené kroky (ne "upravte X a Y a Z" v jednom kroku)
- Dependency informace ("krok 3 závisí na kroku 1")
- Scope odhad per krok (S/M/L) — decomposition engine použije pro plánování

#### Edge cases

| Edge case | Řešení |
|-----------|--------|
| Feature vyžadující >10 souborů | Block — "Feature je příliš rozsáhlá pro jednorázovou implementaci. Doporučuji dekompozici na menší issues." |
| Feature vyžadující víc řádků kódu než diff limit | Flag v plánu — "Odhadovaný rozsah překračuje diff limit. Fixer by měl prioritizovat core a nechat edge cases na follow-up." V Fázi 2 → automatická dekompozice |
| Feature vyžadující breaking change existujícího API | Block — "Feature vyžaduje breaking change v {endpoint}. Toto vyžaduje lidské rozhodnutí o migrační strategii." |
| Feature kde neexistuje žádný vzor k následování | Architect navrhne vzor de novo, ale flag jako vyšší riziko — review bude důležitější |
| Spec s contradictory requirements | Block — vrátit spec-analyst s žádostí o upřesnění (prakticky: Block issue, člověk rozhodne) |
| Feature vyžadující databázové migrace | Zahrnout migraci jako první implementační krok, flag jako risk (migrace = irreversible) |
| Codebase bez testů | Architect zahrne test soubory do plánu jako CREATE, ale flag: "Projekt nemá testovací konvence — test-engineer bude potřebovat extra kontext." |
| Feature s externími závislostmi (nová knihovna) | Zahrnout jako první krok (package install), ale flag: "Nová závislost — ověřte kompatibilitu a licenci." |
| Tech debt brání implementaci | Block pokud je debt blokující. Jinak zahrnout jako poznámku pro fixer: "Workaround kvůli tech debt v {soubor}." |

---

## 4. Command Design — /implement-feature

### Syntaxe

```
/CLAUDE-agents:implement-feature <issue-id> [--dry-run]
```

| Parametr | Povinný | Popis |
|----------|---------|-------|
| `<issue-id>` | Ano | ID feature issue v issue trackeru (např. PROJ-123) |
| `--dry-run` | Ne | Jen analýza (spec + architect), žádné změny kódu |

### Příklady použití

**Příklad 1 — základní feature implementace:**
```
/CLAUDE-agents:implement-feature PROJ-123
```
Spustí plnou pipeline: spec analysis → architecture → implementation → review → test → publish decision.

**Příklad 2 — dry-run pro odhad složitosti:**
```
/CLAUDE-agents:implement-feature PROJ-456 --dry-run
```
Spustí jen spec-analyst a architect, zobrazí odhad rozsahu, rizik a implementačních kroků. Žádné změny kódu, žádné issue tracker state changes.

**Příklad 3 — feature s E2E testy:**
```
/CLAUDE-agents:implement-feature PROJ-789
```
Pokud v Automation Config existuje sekce E2E Test, po unit testech automaticky spustí i E2E testy.

**Příklad 4 — resume po blocku:**
```
/CLAUDE-agents:resume-ticket PROJ-123
```
Existující `/resume-ticket` detekuje checkpoint `[CLAUDE-agents] Spec dokončen.` a obnoví pipeline od architect kroku.

### Pipeline flow — plná command definice

```markdown
---
description: Implementuje feature z issue trackeru
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task, WebFetch
---

# Implement Feature

Implementuj feature $ARGUMENTS. Čti Automation Config z CLAUDE.md. Pracuj v aktuálním adresáři (žádný worktree).

Pokud $ARGUMENTS obsahuje `--dry-run`, aktivuj dry-run mód (viz sekce Dry-run níže).

## Konfigurace

Před zahájením pipeline načti z Automation Config:
- **Type** z Issue Tracker (default: `youtrack`) — určuje MCP tool prefix
- **Feature Workflow** sekce (pokud existuje):
  - Feature query (pro validaci, že issue je feature)
  - Max subtasks (pro budoucí Fázi 2, v Fázi 1 ignorováno)
- **Retry limity** z Retry Limits sekce (pokud existuje):
  - Fixer iterations (default: 5)
  - Test attempts (default: 3)
  - Build retries (default: 3)
- **Hooks** z Hooks sekce (pokud existuje)
- **Custom Agents** z Custom Agents sekce (pokud existuje)
- **Notifications** z Notifications sekce (pokud existuje)

## Kroky

### 0. Dry-run check

Pokud je aktivní `--dry-run` mód → běž jen kroky 3 a 4 (bez issue tracker změn), pak vygeneruj dry-run report. Žádné side effects.

### 1. Nastav issue tracker

Nastav stav dle Automation Config (Issue Tracker → On start set). Čti Type pro správný MCP server.

*V dry-run: přeskoč tento krok.*

### 2. Vytvoř branch

`git checkout -b {branch_naming} {base_branch}` — hodnoty z Automation Config (Source Control).

*V dry-run: přeskoč tento krok.*

### 3. Spec Analyst

Spusť `CLAUDE-agents:spec-analyst` (Task tool, model: sonnet).
Kontext: `Type = {Type z config}. Použij MCP server pro {Type}. Feature query = {Feature query z Feature Workflow, pokud existuje}.`

- Příliš vágní → Block (v dry-run: zaznamenej, nezapisuj do issue trackeru)
- Příliš velká feature → Block (v dry-run: zaznamenej)
- OK → pokračuj s výstupní specifikací

### 4. Architect

Spusť `CLAUDE-agents:architect` (Task tool, model: opus).
Kontext: specifikace z kroku 3.

- Příliš velká / neproveditelná → Block (v dry-run: zaznamenej)
- OK → pokračuj s implementačním plánem

*Pokud dry-run → zastav zde, zobraz dry-run report (viz sekce Dry-run).*

### 4a. Pre-fix hook

Pokud Hooks → Pre-fix existuje:
- Spusť příkaz přes Bash
- Selhání → přejdi na Block handler (krok X)

### 5. Fixer

Spusť `CLAUDE-agents:fixer` (Task tool, model: opus).
Kontext: `Implementační plán z architect: {plán}. Implementuj feature dle plánu. Max build retries = {Build retries z config}. Block Comment Template: {template z CLAUDE.md pluginu}.`

DŮLEŽITÉ: Fixer dostává implementační plán místo impact reportu. Fixer agent je generický — pracuje s kontextem, který dostane. Pro bug-fix dostane impact report, pro feature dostane implementační plán.

### 6. Build

Spusť Build command z Automation Config. Retry limit = Build retries z config.
Selhání po vyčerpání retries → přejdi na Block handler (krok X).

### 6a. Post-fix hook

Pokud Hooks → Post-fix existuje:
- Spusť příkaz přes Bash
- Selhání → přejdi na Block handler (krok X)

### 6b. Post-fix custom agent

Pokud Custom Agents → Post-fix agent existuje:
- Přečti agent definici ze souboru uvedeného v config
- Spusť jako Task s modelem z frontmatter agenta
- BLOCK → přejdi na Block handler (krok X)

### 7. Reviewer ⟲

Spusť `CLAUDE-agents:reviewer` (Task tool, model: opus).
Kontext: `Toto je feature implementace, ne bug-fix. Specifikace: {spec z kroku 3}. Plán: {plán z kroku 4}. Ověř, že implementace splňuje acceptance criteria. Max fixer iterations = {Fixer iterations z config}.`

Smyčka fixer ↔ reviewer: max {Fixer iterations} iterací.
Vyčerpání → přejdi na Block handler (krok X).

DŮLEŽITÉ: Reviewer dostává specifikaci a plán jako kontext, aby mohl ověřit nejen kvalitu kódu, ale i shodu s requirements.

### 8. Test-engineer ⟲

Spusť `CLAUDE-agents:test-engineer` (Task tool, model: sonnet).
Kontext: `Toto je feature implementace. Specifikace: {spec z kroku 3}. Piš testy pokrývající acceptance criteria. Max test attempts = {Test attempts z config}.`

Smyčka: max {Test attempts} pokusů.
Vyčerpání → přejdi na Block handler (krok X).

### 8a. E2E test-engineer

Pokud E2E Test sekce existuje v Automation Config:
- Spusť `CLAUDE-agents:e2e-test-engineer` (Task tool, model: sonnet)
- Kontext: `Toto je nová feature. Specifikace: {spec z kroku 3}. Testuj happy path nové funkcionality.`
- Selhání → přejdi na Block handler (krok X)

### 8b. Pre-publish hook

Pokud Hooks → Pre-publish existuje:
- Spusť příkaz přes Bash
- Selhání → přejdi na Block handler (krok X)

### 8c. Pre-publish custom agent

Pokud Custom Agents → Pre-publish agent existuje:
- Spusť jako Task, BLOCK → přejdi na Block handler (krok X)

### 9. Výsledek

Zobraz výsledek — uživatel rozhodne o publish.

### 9a. Post-publish hook

Pokud uživatel zvolí publish a Hooks → Post-publish existuje:
- Spusť po publisher
- Selhání → pouze varování

### 9b. Webhook — PR created

Pokud uživatel zvolí publish a Notifications → Webhook URL existuje a `pr-created` je v On events:
```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"pr-created","issue_id":"{issue}","pr_url":"{url}","timestamp":"{ISO8601}"}' \
  "{Webhook URL}"
```

### 9c. Odhad spotřeby tokenů

```
Odhadovaná spotřeba: ~150 000 tokenů
Odhadovaná cena: ~$0.70–$2.00 USD
(Odhad je orientační — architect agent používá opus, proto vyšší než bug-fix pipeline)
```

### X. Block handler

Při blocku od fixer/reviewer/test-engineer/build/hook/custom agenta:

1. **Rollback:** Spusť `CLAUDE-agents:rollback-agent` (Task tool, model: haiku).
   Kontext: `Agent: {název}. Krok: {krok}. Důvod: {důvod}. Detail: {output}. Doporučení: {doporučení}. Kontext spuštění: CWD (bez worktree).`
   - NEROLOVAT při blocku od spec-analyst/architect — žádné git změny k revertu

2. **Webhook — issue-blocked:** Pokud Notifications → Webhook URL existuje a `issue-blocked` je v On events:
   ```bash
   curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
     -d '{"event":"issue-blocked","issue_id":"{issue}","agent":"{agent}","reason":"{reason}","timestamp":"{ISO8601}"}' \
     "{Webhook URL}"
   ```

## Dry-run report

Po krocích 3–4 (spec-analyst + architect) zobraz:

```
## Dry-Run Report — {issue_id}

**Spec:** {OK / VAGUE / OVERSIZED}
**Cíl:** {1 věta z specifikace}
**Acceptance Criteria:** {počet}
**Scope:** {in_count} in / {out_count} out
**Dependencies:** {počet}
**Soubory k úpravě:** {počet} ({create_count} CREATE, {modify_count} MODIFY)
**Odhadovaný rozsah:** {celkový počet řádků}
**Risk:** {LOW / MEDIUM / HIGH}

### Implementační kroky
1. {krok} — {scope S/M/L}
2. ...

### Rizika
- {riziko}

Žádné změny provedeny. Pro spuštění implementace zadej `/CLAUDE-agents:implement-feature {issue_id}` (bez --dry-run).
```

## Pravidla

- Pracuj v CWD — žádné worktrees
- Publisher se NEvolá automaticky — uživatel rozhodne
- Block Comment Template se předává agentům jako context instrukce
- Retry limity se předávají agentům jako context instrukce
- Hook před agentem, ne v reviewer smyčce
- Custom agent je one-shot gate
- Při chybě → Block handler (krok X) + informuj uživatele
- Spec-analyst a architect NEROLUJÍ při blocku — analogie s triage/code-analyst v bug-fix pipeline
```

### Error handling per krok

| Krok | Error typ | Handling |
|------|-----------|---------|
| Config loading | Automation Config chybí/neplatná | Zobraz chybu, odkaz na `/check-setup` |
| Issue tracker setup | MCP selhání | Zobraz chybu, zastav pipeline |
| Branch creation | Branch existuje | `git checkout {branch}` (switch, ne create) |
| Spec Analyst | Vágní issue | Block issue + komentář. Žádný rollback |
| Spec Analyst | Oversized feature | Block issue + doporučení. Žádný rollback |
| Spec Analyst | Issue tracker nedostupný | Zobraz chybu, zastav pipeline |
| Architect | Feature příliš velká | Block issue + komentář. Žádný rollback |
| Architect | Nekompatibilní architektura | Block issue + vysvětlení. Žádný rollback |
| Pre-fix hook | Non-zero exit | Block handler → rollback |
| Fixer | Build opakovaně selhává | Block handler → rollback |
| Fixer | Diff překročí limit | Block handler → rollback + doporučení dekomponovat |
| Post-fix hook/agent | Selhání | Block handler → rollback |
| Reviewer | Max iterations reached | Block handler → rollback |
| Test Engineer | Max attempts reached | Block handler → rollback |
| E2E Engineer | App neběží | Block handler → rollback |
| Pre-publish hook/agent | Selhání | Block handler → rollback |
| Publisher | Push selhání | Block + chybová hláška |

### Config requirements

Feature pipeline vyžaduje **stejné** povinné sekce jako bug-fix pipeline:

| Sekce | Klíče | Povinné pro feature? |
|-------|-------|---------------------|
| Issue Tracker | Type, Instance, Project, State transitions, On start set | Ano — identické |
| Source Control | Remote, Base branch, Branch naming | Ano — identické |
| PR Rules | Labels | Ano — identické |
| Build & Test | Build, Test | Ano — identické |
| PR Description Template | Template | Ano — identické |

Plus nová **volitelná** sekce:

| Sekce | Klíče | Povinné? |
|-------|-------|---------|
| Feature Workflow | Feature query, Max subtasks, Subtask strategy | Ne — volitelná |

**BEZ Feature Workflow sekce:** Pipeline funguje — použije defaulty (žádný feature query filter, max 5 subtasks, sequential).

**S Feature Workflow sekcí:** Pipeline respektuje konfiguraci.

### Srovnání s /fix-ticket

| Aspekt | /fix-ticket | /implement-feature |
|--------|------------|-------------------|
| **Vstup** | Bug issue ID | Feature issue ID |
| **Krok 3** | triage-analyst | spec-analyst |
| **Krok 4** | code-analyst | architect |
| **Kroky 5–9** | Identické | Identické |
| **Block handler** | Identický | Identický (+ spec-analyst/architect nemají rollback) |
| **Dry-run** | Triage + code-analyst | Spec + architect |
| **Hooks** | Identické | Identické |
| **Custom Agents** | Identické | Identické |
| **Webhooks** | Identické | Identické |
| **Config** | Automation Config | Automation Config + Feature Workflow (optional) |
| **Allowed tools** | Identické | Identické |
| **Token odhad** | ~119k | ~150k (architect = opus) |

**Sdílená logika:** Kroky 5–9, Block handler, hook/custom agent execution, webhook logic, dry-run framework, publisher flow, retry handling. V implementaci se liší jen:
1. Volání spec-analyst místo triage-analyst
2. Volání architect místo code-analyst
3. Kontext předávaný fixer/reviewer/test-engineer (implementační plán místo impact reportu)
4. Checkpoint komentář format (`Spec dokončen` místo `Triage dokončen`)

---

## 5. Datový model

### Artefakty vytvořené během pipeline

Feature pipeline produkuje **4 typy artefaktů** (oproti 2 u bug-fix pipeline):

| # | Artefakt | Vytvořen | Konzumován | Formát | Perzistence |
|---|----------|---------|------------|--------|-------------|
| 1 | Strukturovaná specifikace | spec-analyst | architect, fixer, reviewer, test-engineer | Markdown (structured) | Task context (in-memory) |
| 2 | Implementační plán | architect | fixer, reviewer | Markdown (structured) | Task context (in-memory) |
| 3 | Kódové změny | fixer | reviewer, test-engineer, publisher | Git diff / files | Git (on disk) |
| 4 | Testy | test-engineer, e2e-test-engineer | reviewer (nepřímo) | Source files | Git (on disk) |

### Formát specifikace (Markdown)

```markdown
## Specifikace — PROJ-123: OAuth přihlášení

### Cíl
Umožnit uživatelům přihlášení přes Google OAuth 2.0 vedle stávajícího email/heslo login.

### Acceptance Criteria
1. Na login stránce je tlačítko "Přihlásit přes Google"
2. Po kliknutí se otevře Google OAuth consent screen
3. Po úspěšné autorizaci je uživatel přihlášen a přesměrován na dashboard
4. Pokud Google účet odpovídá existujícímu emailu, propojí se účty
5. Pokud Google účet neodpovídá žádnému emailu, vytvoří se nový účet

### Scope — In
- Google OAuth 2.0 integration
- Login page UI změna
- Propojení s existujícím user modelem

### Scope — Out
- Další OAuth providery (GitHub, Facebook) — budoucí ticket
- OAuth pro API (jen web UI)

### Dependencies
- google-auth-library (npm package)
- Google Cloud Console — OAuth client credentials

### Otevřené otázky
- Jak řešit kolizi emailů při auto-linking?
```

### Formát implementačního plánu (Markdown)

```markdown
## Implementační plán — PROJ-123: OAuth přihlášení

### Architektonický přehled
Feature rozšiřuje stávající auth modul o OAuth strategii. Projekt používá
passport.js pattern — přidáme GoogleStrategy analogicky k LocalStrategy.

### Soubory k úpravě
| Soubor | Typ změny | Popis |
|--------|-----------|-------|
| src/auth/strategies/google.ts | CREATE | GoogleStrategy pro passport |
| src/auth/index.ts | MODIFY | Registrace GoogleStrategy |
| src/routes/auth.ts | MODIFY | Nové routes /auth/google, /auth/google/callback |
| src/views/login.ejs | MODIFY | Tlačítko "Přihlásit přes Google" |
| tests/auth/google.test.ts | CREATE | Unit testy pro GoogleStrategy |

### API Contract
- GET /auth/google → redirect na Google OAuth
- GET /auth/google/callback → callback handler, redirect na /dashboard

### Implementační kroky (ordered)
1. Vytvořit src/auth/strategies/google.ts — GoogleStrategy (S, ~15 řádků)
2. Upravit src/auth/index.ts — registrace strategy (S, ~5 řádků)
3. Přidat routes do src/routes/auth.ts (S, ~10 řádků)
4. Přidat tlačítko do src/views/login.ejs (S, ~5 řádků)

### Rizika
- Google Cloud credentials musí být v environment — ověřit .env setup
- Kolize emailů při auto-linking — zatím řešit: pokud email existuje, propojit bez potvrzení

### Poznámky pro Fixer
- Následuj pattern z src/auth/strategies/local.ts
- Neměň existující LocalStrategy
- Použij env proměnné GOOGLE_CLIENT_ID a GOOGLE_CLIENT_SECRET
```

### Kde artefakty žijí

```
SPECIFIKACE          IMPLEMENTAČNÍ PLÁN         KÓDOVÉ ZMĚNY
     │                      │                       │
     ▼                      ▼                       ▼
Task context            Task context             Git working tree
(předáno v Task         (předáno v Task          (fyzické soubory)
 tool prompt)            tool prompt)

Nikdy commitováno      Nikdy commitováno        Commitováno publisherem
Nikdy na disk          Nikdy na disk            Na disku
Existuje jen           Existuje jen             Perzistentní
 po dobu pipeline       po dobu pipeline
```

**Klíčové rozhodnutí:** Specifikace a implementační plán **NEJSOU** commitovány do repa. Existují pouze jako kontext předávaný mezi agenty v rámci jednoho pipeline běhu. Toto je konzistentní s bug-fix pipeline, kde triage analysis a impact report také nejsou nikam ukládány.

**Výhody:**
- Žádný "metadata clutter" v repu
- Formát se může měnit bez zpětné kompatibility
- Jednodušší implementace (string passing, ne file management)

**Nevýhody:**
- Ztráta kontextu po pipeline běhu (nelze zpětně prohlédnout specifikaci)
- Resume (`/resume-ticket`) nemá přístup k specifikaci — musí re-generovat

**Mitigace:** Checkpoint komentář v issue trackeru obsahuje klíčové metriky (criteria count, dependency count). Pro plný kontext při resume: re-spusť spec-analyst (je read-only, rychlý, idempotentní).

### Tok artefaktů mezi agenty

```
Issue Tracker
     │
     │ issue data
     ▼
SPEC ANALYST ─────────────────────┐
     │                            │
     │ specifikace                │ specifikace
     ▼                            │
ARCHITECT                         │
     │                            │
     │ impl. plán                 │
     ▼                            ▼
FIXER ◄──── kontext ────── spec + plán
     │
     │ code changes (git)
     ▼
REVIEWER ◄── kontext ──── spec + plán + diff
     │
     │ approve/request_changes
     ▼
TEST ENGINEER ◄── kontext ──── spec (acceptance criteria)
     │
     │ test files (git)
     ▼
E2E ENGINEER ◄── kontext ──── spec (user flow)
     │
     │ e2e test files (git)
     ▼
PUBLISHER ◄── kontext ──── issue ID, branch, config
     │
     │ PR
     ▼
Issue Tracker (state change + PR link)
```

---

## 6. Integrace se stávající pipeline

### Detailní mapování znovupoužití agentů

| Bug Pipeline Agent | Feature Pipeline Agent | Změny potřebné |
|-------------------|----------------------|----------------|
| triage-analyst | spec-analyst | **NOVÝ AGENT** — žádné změny v triage-analyst |
| code-analyst | architect | **NOVÝ AGENT** — žádné změny v code-analyst |
| fixer | fixer (identický) | **ŽÁDNÉ** — kontext je parametrizovaný |
| reviewer | reviewer (identický) | **ŽÁDNÉ** — review checklist je generický |
| test-engineer | test-engineer (identický) | **ŽÁDNÉ** — testuje behavior, ne konkrétní bug |
| e2e-test-engineer | e2e-test-engineer (identický) | **ŽÁDNÉ** — testuje user flow |
| publisher | publisher (identický) | **ŽÁDNÉ** — PR je PR |
| rollback-agent | rollback-agent (identický) | **ŽÁDNÉ** — git reset je git reset |

**Celkový dopad na existující agenty:** Závisí na rozhodnutí o generalizaci wordingu (viz REVIEW Q níže). Fixer, reviewer a test-engineer jsou dostatečně genericky napsané — pracují s kontextem, který dostanou od command. Nicméně jejich Process step 1 obsahuje bug-specific terminologii.

### Proč existující agenty nevyžadují změny (s výhradou)

**Fixer** — jeho Process step 1 říká "Read the triage analysis and impact report". Pro feature pipeline dostane v kontextu "Implementační plán z architect: {plán}" místo "Impact report: {report}". Agent pracuje s tím, co dostane — kontext je proměnný, logika je stejná.

**Reviewer** — jeho Process step 1 říká "Read the original bug report, triage analysis, impact report, and the fix diff". Pro feature pipeline dostane "Specifikace: {spec}. Plán: {plán}." — reviewer kontroluje kvalitu kódu a shodu s zadáním, nezáleží jestli zadání je bug report nebo feature spec.

**Test-engineer** — jeho Process step 1 říká "Read the bug report, fix diff, and impact report". Pro feature pipeline dostane specifikaci s acceptance criteria — testy pokrývají chování, ne konkrétní bug.

**Rozhodnutí:** Generalizovat wording v agentech (PATCH change). Bug-specific formulace ("triage analysis", "impact report", "bug report") v fixer/reviewer/test-engineer se přeformulují na generické ("analysis provided", "issue context", "analysis report"). Minimální effort, čistší design, future-proof pro jakýkoliv workflow typ. Implementace: find-replace ve 3 agent souborech, PATCH release.

### Sdílená infrastruktura

| Komponenta | Popis | Změny pro feature pipeline |
|-----------|-------|---------------------------|
| Config reading | Parsování Automation Config z CLAUDE.md | Přidání čtení Feature Workflow sekce |
| Issue tracker integrace | MCP server pro čtení/zápis issues | Žádné — stejné operace |
| Branch management | git checkout -b, naming pattern | Žádné — stejný pattern |
| PR creation | Publisher agent flow | Žádné |
| Rollback | rollback-agent invocation | Žádné |
| Hook execution | Bash command execution | Žádné — hooks jsou hooks |
| Custom agent execution | Task tool s external agent definition | Žádné |
| Webhook sending | curl POST | Žádné — stejné event typy |
| Retry logic | Max iterations/attempts tracking | Žádné — identické limity |
| Block handler | Rollback + webhook + issue state | Žádné |
| Dry-run framework | Report generace bez side effects | Rozšíření o feature-specific report formát |

### Skill routing — nové intenty

**Rozhodnutí:** Dva nezávislé skilly — `bug-workflow` zůstane beze změny pro bug intenty, nový `feature-workflow` skill pro feature intenty. Každý pipeline má vlastní vstupní bod (routing), vlastní command (orchestrace), sdílené agenty (exekuce). MINOR change (nový soubor), zero breaking impact.

Nový `skills/feature-workflow/SKILL.md` routuje feature intenty → `/implement-feature` a sdílené commandy (`/create-pr`, `/publish`, `/status`).

| User Intent | Command | Arguments | Destructive? |
|-------------|---------|-----------|-------------|
| Implement a feature/story | `CLAUDE-agents:implement-feature` | Issue ID | Yes |
| Analyze a feature (dry-run) | `CLAUDE-agents:implement-feature` | Issue ID + --dry-run | No |

**Nové triggery pro routing:**
- "implementuj feature", "implementuj PROJ-123"
- "nová funkcionalita", "přidej feature"
- "implement feature", "implement PROJ-123"
- "udělej PROJ-123" (pokud issue je feature type)
- "zanalyzuj feature PROJ-123" → dry-run

**Rozšíření SKILL.md:**

Do tabulky Intent Mapping přidat:

```markdown
| Implement a feature/story | `CLAUDE-agents:implement-feature` | Issue ID | Yes |
| Analyze a feature (dry-run) | `CLAUDE-agents:implement-feature` | Issue ID + --dry-run | No |
```

### Dopad na existující commands

| Command | Dopad | Detail |
|---------|-------|--------|
| `/fix-ticket` | Žádný | Beze změn |
| `/fix-bugs` | Žádný | Beze změn |
| `/analyze-bug` | Žádný | Beze změn |
| `/create-pr` | Žádný | Beze změn |
| `/publish` | Žádný | Beze změn |
| `/version-bump` | Žádný | Beze změn |
| `/check-setup` | Rozšíření | + validace Feature Workflow sekce |
| `/resume-ticket` | Rozšíření | + nový checkpoint `POST_SPEC` detekce |
| `/status` | Žádný | Již zobrazuje issues v aktivních stavech — features se zobrazí automaticky |
| `/onboard` | Rozšíření | + nabídka Feature Workflow sekce |
| `/changelog` | Žádný | Beze změn |
| `/version-check` | Žádný | Beze změn |

**Detaily rozšíření:**

**`/check-setup`** — přidat do Bloku 1 (strukturální kontrola):
```
5b. Ověř volitelné sekce — přidat Feature Workflow:
    - Pokud existuje: ověř formát (Feature query, Max subtasks, Subtask strategy)
    - Pokud neexistuje: [SKIP] (volitelné)
```

**`/resume-ticket`** — přidat nový checkpoint:
```
| Checkpoint | Signál | Přeskočí | Následující krok |
|-----------|--------|---------|-----------------|
| `POST_SPEC` | Existuje komentář `[CLAUDE-agents] Spec dokončen.` | Spec analyst | Spusť od architect (s re-generovanou specifikací) |
| `POST_ANALYSIS` (feature) | Branch existuje + spec comment | Spec analyst + architect | Spusť od fixer (s implementačním plánem — re-generuj spec + architect) |
```

Detekční logika rozšířena:
```
if PR exists for branch → PUBLISHED
else if branch has commits above base → POST_FIX (or POST_REVIEW if reviewer approval comment)
else if branch exists + spec comment → POST_ANALYSIS (switch to feature pipeline — re-run architect)
else if branch exists + triage comment → POST_ANALYSIS (bug pipeline)
else if spec comment exists (no branch) → POST_SPEC (feature pipeline — run from architect)
else if triage comment exists (no branch) → POST_TRIAGE (bug pipeline)
else → FRESH
```

**Klíčový detail:** `/resume-ticket` musí rozlišit, zda se jedná o bug-fix nebo feature pipeline. Signálem je typ checkpoint komentáře — `Triage dokončen` = bug, `Spec dokončen` = feature. Na základě toho spustí odpovídající pipeline.

**Edge case — oba komentáře existují:** Pokud issue má jak `Triage dokončen` tak `Spec dokončen` komentář (např. issue byl nejdřív analyzován jako bug, pak přehodnocen na feature), prioritu má **novější** komentář. Resume-ticket vezme poslední `[CLAUDE-agents]` checkpoint komentář a dle něj určí pipeline.

**`/onboard`** — přidat do kroku 6 (volitelné sekce):
```
- Feature Workflow: Feature query, Max subtasks, Subtask strategy
```

---

## 7. Automation Config rozšíření

### Feature Workflow — nová volitelná sekce

```markdown
### Feature Workflow (optional)

| Key | Value |
|-----|-------|
| Feature query | Type: Feature AND State: Open |
| Max subtasks | 5 |
| Subtask strategy | sequential |
```

### Specifikace klíčů

| Klíč | Typ | Povinný | Default | Popis |
|------|-----|---------|---------|-------|
| Feature query | String | Ne | (žádný filtr) | Query pro issue tracker — spec-analyst ověří, že issue matchuje tento filtr (soft validace — varování, ne Block). Bez tohoto klíče `/implement-feature` přijme libovolný issue typ |
| Max subtasks | Integer | Ne | 5 | Maximální počet subtasků, které architect může navrhnout. V Fázi 1 je toto kontrolní limit (architect blokuje, pokud by potřeboval víc). V Fázi 2 se stane vstupem pro decomposition engine |
| Subtask strategy | Enum: sequential / parallel | Ne | sequential | Jak zpracovat subtasky. V Fázi 1 je jediná podporovaná hodnota `sequential` (a je ignorována, protože Fáze 1 nemá decomposition). V Fázi 2 se aktivuje |

### Příklad konfigurace — minimální

```markdown
## Automation Config

### Issue Tracker
| Key | Value |
|-----|-------|
| Type | youtrack |
| Instance | project.youtrack.cloud |
| Project | MYPROJECT |
| Bug query | project: MYPROJECT State: Open Type: Bug |
| State transitions | In Progress, Blocked, For Review |
| On start set | State: In Progress |

### Feature Workflow
| Key | Value |
|-----|-------|
| Feature query | project: MYPROJECT State: Open Type: Feature |

### Source Control
...
```

### Příklad konfigurace — plná

```markdown
### Feature Workflow
| Key | Value |
|-----|-------|
| Feature query | project: MYPROJECT State: Open Type: {Feature, User Story} |
| Max subtasks | 8 |
| Subtask strategy | sequential |
```

### Validační pravidla pro /check-setup

```
Feature Workflow sekce:
  - Existuje → ověř:
    - Feature query: non-empty, ne placeholder (<...>) → [OK] / [FAIL]
    - Max subtasks: integer > 0 a ≤ 20 → [OK] / [FAIL]
    - Subtask strategy: "sequential" nebo "parallel" → [OK] / [FAIL]
  - Neexistuje → [SKIP] "Feature Workflow not configured (optional)"
```

### Zpětná kompatibilita

- Feature Workflow je **volitelná** sekce → žádný breaking change
- Projekty bez Feature Workflow mohou stále volat `/implement-feature` — funguje s defaulty
- Existující bug-fix pipeline **se nemění** — žádný klíč v povinných sekcích se nepřidává
- **Verze: MINOR** (v2.1.0) dle versioning policy

---

## 8. Implementační plán

### Sekvence kroků

| # | Krok | Závislost | Effort | Paralelizovatelný |
|---|------|-----------|--------|-------------------|
| 1 | Design doc (tento dokument) | — | M | — |
| 2 | Implementace spec-analyst agenta | #1 schválení | M | Ano s #3 |
| 3 | Implementace architect agenta | #1 schválení | L | Ano s #2 |
| 4 | Implementace `/implement-feature` command | #2 + #3 | L | Ne |
| 5 | Rozšíření `/check-setup` o Feature Workflow validaci | #1 | S | Ano s #2, #3 |
| 6 | Rozšíření `/resume-ticket` o POST_SPEC checkpoint | #4 | S | Ano s #5 |
| 7 | Rozšíření `/onboard` o Feature Workflow | #1 | S | Ano s #2–#6 |
| 8 | Rozšíření skill routing o feature intenty | #4 | S | Ano s #5–#7 |
| 9 | Aktualizace CLAUDE.md — nová sekce Feature Pipeline | #4 | S | Ne (po #4) |
| 10 | Aktualizace CLAUDE.md — agent table, command list, Repository Structure počty (10 agents, 13 commands) | #2 + #3 | S | Ano s #9 |
| 11 | Smoke test — spec-analyst na reálném feature issue | #2 | M | Ano s #3 |
| 12 | Smoke test — architect na reálném feature issue | #3 | M | Ano s #2 |
| 13 | Smoke test — full pipeline end-to-end | #4 | L | Ne |
| 14 | README update | #4 | S | Ano s #11–#13 |
| 15 | CHANGELOG update | Vše | S | Ne (poslední) |
| 16 | Version bump v2.1.0 | #15 | S | Ne (poslední) |

### Dependency graph

```
          ┌──── #2 (spec-analyst) ──── #11 (smoke test)
          │                               │
#1 (doc)──┤                               │
          │                               ▼
          ├──── #3 (architect) ────── #12 (smoke test)
          │          │                    │
          │          ▼                    ▼
          ├──── #5 (check-setup)    #4 (implement-feature)
          │                              │
          ├──── #7 (onboard)            ┌┴─────┬────────┐
          │                             │      │        │
          └──────────────────────   #6(resume) #8(skill) #9(CLAUDE.md)
                                        │      │        │
                                        └──────┴────────┘
                                               │
                                           #13 (e2e test)
                                               │
                                           #10 + #14
                                               │
                                           #15 (CHANGELOG)
                                               │
                                           #16 (version bump)
```

### Odhady effort

| Effort | Popis | Příklad |
|--------|-------|---------|
| S | ≤30 minut — jednoduchá úprava existujícího souboru | Přidání řádku do SKILL.md |
| M | 30–90 minut — nový soubor nebo středně složitá úprava | Nový agent definition |
| L | 90+ minut — nový command s plnou pipeline logikou | `/implement-feature` |

**Celkový odhad: ~10–14 hodin práce** (2 x M agenti + 1 x L command + 8 x S úpravy + 3 x M testy).

### Co lze paralelizovat

- **Kroky 2 + 3:** Oba agenti jsou nezávislé soubory — mohou být psány současně
- **Kroky 5 + 7:** Rozšíření existujících commands — nezávislé na sobě
- **Kroky 11 + 12:** Smoke testy jednotlivých agentů — nezávislé
- **Kroky 9 + 10 + 14:** Dokumentační úpravy — nezávislé

---

## 9. Rizika & edge cases

### R1: Feature issues mají méně strukturovaný popis než bug reporty

**Pravděpodobnost:** Vysoká
**Dopad:** Střední — spec-analyst často blokuje kvůli vágnosti

**Mitigace:**
- Spec-analyst má explicitní confidence threshold (< 50% → Block)
- Block komentář přesně specifikuje, co chybí
- Uživatel doplní issue a spustí `/resume-ticket`
- Alternativa: dry-run jako první krok — uživatel vidí, co spec-analyst extrahuje, a doplní info předem

### R2: Architect navrhuje příliš velké implementační plány

**Pravděpodobnost:** Střední
**Dopad:** Vysoký — fixer nedokáže implementovat víc řádků než diff limit v jednom průchodu

**Mitigace:**
- Architect má hard limit: max 10 souborů, celkový odhad ≤ diff limit (konfigurovatelný)
- Pokud plán překračuje limity → Block s doporučením dekomponovat
- V Fázi 2 → automatická dekompozice (ale Fáze 1 = manuální split)
- Max subtasks limit z config (default 5)

**Rozhodnutí:** Odložit na Phase 2 (dekompozice). Diff limit zůstává 100 řádků, konzistentně s bug-fix pipeline. V Phase 1 features překračující limit → Block s doporučením manuálně dekomponovat. Phase 2 (automatická dekompozice) tento problém vyřeší — architect rozdělí velké features na subtasky, každý pod 100-line limitem.

### R3: Fixer neporozumí implementačnímu plánu

**Pravděpodobnost:** Nízká (opus je strong coder)
**Dopad:** Střední — reviewer zachytí odchylky

**Mitigace:**
- Architect produkuje specifické instrukce s referencemi na existující patterns
- Reviewer dostává spec i plán — může ověřit shodu
- Fixer → reviewer loop (max 5 iterací) je pojistka

### R4: Reviewer nerozlišuje bug-fix a feature review

**Pravděpodobnost:** Nízká
**Dopad:** Nízký — reviewer je genericky formulovaný

**Mitigace:**
- Reviewer dostává v kontextu `Toto je feature implementace, ne bug-fix. Specifikace: {spec}. Plán: {plán}.`
- Review checklist je generic: root cause → completeness → conventions → regressions → security
- Pro features "root cause" = "does it match the spec?"

### R5: Test-engineer píše testy pro feature jinak než pro bug-fix

**Pravděpodobnost:** Střední
**Dopad:** Nízký — testy jsou testy

**Mitigace:**
- Test-engineer dostává specifikaci s acceptance criteria — každé kritérium = minimálně 1 test
- Kontext: `Piš testy pokrývající acceptance criteria` — jasná instrukce
- Test framework a konvence jsou v Automation Config — nezáleží na typu issue

### R6: Resume-ticket nerozlišuje bug-fix a feature pipeline

**Pravděpodobnost:** Střední
**Dopad:** Vysoký — spustí špatnou pipeline

**Mitigace:**
- Checkpoint komentáře jsou odlišné: `Triage dokončen` (bug) vs. `Spec dokončen` (feature)
- Resume detekuje typ checkpointu a volí odpovídající pipeline
- Pokud checkpoint neexistuje (FRESH) → uživatel explicitně volí command

### R7: Zpětná kompatibilita — existující projekty bez Feature Workflow config

**Pravděpodobnost:** 100% (všechny existující projekty)
**Dopad:** Nulový — Feature Workflow je volitelná

**Mitigace:**
- Žádná povinná sekce se nepřidává
- `/implement-feature` funguje i bez Feature Workflow sekce (defaulty)
- `/check-setup` reportuje Feature Workflow jako [SKIP] pokud neexistuje
- Bug-fix pipeline se NEMĚNÍ

### R8: Token consumption — architect (opus) zvyšuje cenu

**Pravděpodobnost:** 100%
**Dopad:** Střední — odhadovaný nárůst ~25% oproti bug-fix pipeline

**Mitigace:**
- Dry-run umožňuje preview bez plné pipeline (jen spec + architect)
- Architect je nutné mít na opus — kvalita architektonických rozhodnutí je kritická
- Alternativa (sonnet pro architect) by snížila kvalitu a zvýšila počet Block events → větší celkový náklad
- Token odhad v dry-run reportu pomáhá uživateli rozhodnout

### R9: Paralelismus s bug-fix pipeline — konflikty

**Pravděpodobnost:** Nízká
**Dopad:** Střední — merge konflikty

**Mitigace:**
- Každá pipeline pracuje na vlastní branch
- Konflikty se řeší až při merge do base branch (standard git workflow)
- Publisher nikdy nepushuje do main — vždy PR

### R10: Spec analyst a architect jako bottleneck — serialní zpracování

**Pravděpodobnost:** 100%
**Dopad:** Nízký — oba jsou relativně rychlé (sonnet/opus analýza, žádný kód)

**Mitigace:**
- Spec analyst (sonnet) → ~20–40 sekund
- Architect (opus) → ~40–80 sekund
- Celkový overhead oproti bug-fix pipeline: ~60–120 sekund
- Nepotřebují retry — jsou idempotentní a read-only

### Edge cases per agent

**Spec Analyst edge cases (kompletní):**
- Issue s 50+ komentáři → čte jen posledních 20, prioritizuje nejnovější
- Issue s 10+ přílohami → analyzuje všechny, ale limituje na 5 nejvíc relevantních
- Issue v jiném jazyce než projekt → specifikace v jazyce issue
- Issue s conflicting comments → flag jako otevřená otázka

**Architect edge cases (kompletní):**
- Monorepo s 1000+ soubory → Glob/Grep scope dle spec (area, module)
- Codebase bez dokumentace → spoléhá na code patterns a naming
- Feature vyžadující nový framework/knihovnu → zahrne jako dependency, flag jako risk
- Feature crossing multiple bounded contexts → flag jako potenciálně oversized

---

## 10. Otevřené otázky

```
Q: Má spec-analyst dělat duplicate detection pro features?
→ Navrhovaná odpověď: NE. Bug-fix pipeline má duplicate detection v triage-analyst, protože
  duplikátní bugy jsou běžný problém. Feature requesty jsou zřídka duplikátní — každá feature
  je unikátní popis požadavku. Přidání duplicate detection by zvýšilo složitost bez proporcionální
  hodnoty. Pokud tým potřebuje detekci podobných features, může to řešit ručně v issue trackeru
  nebo přes custom agent (Post-fix agent).
```

```
Q: Má architect být opus nebo sonnet? Opus je dražší.
→ Navrhovaná odpověď: OPUS. Architektonické rozhodování je druhý nejkritičtější krok pipeline
  (po samotné implementaci). Špatný architektonický návrh vede k: (1) fixer implementuje špatně
  → reviewer blokuje → loop → Block, (2) chybějící soubor v plánu → neúplná implementace → Block,
  (3) špatný API contract → integrace selhává. Opus pro architect minimalizuje tyto scénáře.
  Sonnet by ušetřil ~$0.20/run, ale zvýšil by Block rate. Celkový TCO s opus je pravděpodobně
  nižší díky menšímu počtu opakovaných průchodů.
```

```
Q: Jak řešit features, které jsou příliš velké pro diff limit fixeru?
→ Navrhovaná odpověď: V Fázi 1 → Block issue s doporučením dekomponovat manuálně.
  V Fázi 2 → Architect produkuje subtasky, decomposition engine je zpracovává automaticky.
  Fáze 1 je záměrně jednoduchá — validuje, že spec-analyst a architect fungují, než
  přidáme složitost decomposition. Architect nesmí navrhnout plán překračující diff limit.
  Pokud feature vyžaduje víc, musí člověk rozdělit issue.
  POZNÁMKA: Diff limit zůstává 100 řádků. Phase 2 (dekompozice) vyřeší větší features automatickým rozdělením na subtasky.
```

```
Q: Mají se specifikace a implementační plány ukládat na disk (do repo)?
→ Navrhovaná odpověď: NE — konzistentně s bug-fix pipeline, kde triage analysis a impact
  report existují jen jako Task context (in-memory). Důvody: (1) žádný "metadata clutter"
  v repo, (2) formát se může měnit bez zpětné kompatibility, (3) jednodušší implementace.
  Pokud tým potřebuje archivovat spec/plány, může to řešit přes Post-fix hook (uloží do
  wiki, Confluence, apod.). Pro resume: re-generace spec-analyst je rychlá a idempotentní.
```

```
Q: Jak /implement-feature pozná, že issue je feature a ne bug?
→ Navrhovaná odpověď: NEPOZNÁ — a to záměrně. `/implement-feature` zpracuje jakýkoli issue
  typ. Pokud uživatel chce filtrovat, může nastavit Feature query v Feature Workflow config
  (spec-analyst pak ověří, že issue matchuje query). Ale hard requirement to není — developer
  ví, zda chce fix nebo feature. Analogie: `/fix-ticket` také neověřuje, že issue je bug.
  Typ workflow (bug-fix vs. feature) určuje uživatel volbou commandu.
```

```
Q: Jak reagovat na scénář, kdy architect navrhne plán a fixer ho implementuje jinak?
→ Navrhovaná odpověď: Reviewer je pojistka. Reviewer dostává spec I plán jako kontext.
  Pokud fixer implementuje "jinak ale správně" (splňuje acceptance criteria, jiná cesta) →
  reviewer by měl approvenout (konvence: "approve if fix is correct even if not perfect").
  Pokud fixer implementuje "jinak a špatně" → reviewer dá REQUEST_CHANGES s referencí
  na plán. Architect plán je guideline, ne mandát. Kreativní řešení fixeru jsou OK, pokud
  splňují spec.
```

```
Q: Má existovat /implement-features (plurál) — batch zpracování features?
→ Navrhovaná odpověď: NE v Fázi 1. Bug-fix má /fix-bugs (plurál) protože batch processing
  bugů je běžný use case (sprint cleanup). Batch features jsou vzácnější — features jsou
  obvykle větší a vyžadují víc pozornosti. V budoucnosti (Fáze 2+) může být batch feature
  command přidán, pokud se ukáže poptávka. Pro Fázi 1 je single-feature command dostatečný.
```

```
Q: Jak se změní Block Comment Template pro feature pipeline?
→ Navrhovaná odpověď: NEZMĚNÍ SE. Block Comment Template je generický:
  `Agent: {název}, Krok: {krok}, Důvod: {důvod}...` — funguje pro jakýkoli agent v jakékoli
  pipeline. Spec-analyst bude vyplňovat "Krok: Feature Spec Analysis" a architect
  "Krok: Architecture Design". Template zůstává identický. Toto je výhoda generického designu
  Block Comment Template — nemusí se měnit při přidání nové pipeline.
```

```
Q: Má /implement-feature automaticky volat /publish na konci, nebo nechat na uživateli?
→ Navrhovaná odpověď: NECHAT NA UŽIVATELI — konzistentně s /fix-ticket, kde publisher
  se nevolá automaticky. Důvod: uživatel chce zkontrolovat výsledek před publishem.
  Feature implementace je větší change než bug-fix → ještě větší důvod pro human approval
  před publishem. Po zobrazení výsledku uživatel explicitně spustí /publish nebo
  /CLAUDE-agents:create-pr.
```

```
Q: Jak řešit versioning při vydání v2.1.0 — upgrade guide potřeba?
→ Navrhovaná odpověď: NE — žádný breaking change, žádný upgrade guide. v2.1.0 přidává
  nové soubory (2 agenti + 1 command), rozšiřuje 3 existující commands (check-setup,
  resume-ticket, onboard) a přidává volitelnou config sekci. Existující projekty nemusí
  nic měnit — bug-fix pipeline funguje identicky. Feature pipeline je opt-in přes nový
  command. Jediné co je potřeba: README update s popisem nové funkcionality a
  CHANGELOG záznam.
```

```
Q: Má se testovací strategie pro smoke testy lišit od bug-fix pipeline?
→ Navrhovaná odpověď: ANO, s rozšířením. Smoke test pro feature pipeline by měl pokrývat:
  (1) spec-analyst na reálném feature issue — ověřit extrakci criteria/scope/dependencies,
  (2) architect na reálné codebase — ověřit kvalitu impl. plánu,
  (3) full pipeline end-to-end — feature issue → merged PR.
  Oproti bug-fix pipeline je nový bod (2), protože architect produkuje složitější artefakt
  než code-analyst. Smoke test by měl být proveden na BIFITO nebo jiném existujícím
  projektu s Automation Config.
```

```
Q: Co když projekt nemá issues typované (feature vs. bug)?
→ Navrhovaná odpověď: Není problém. Bez Feature query v config /implement-feature
  zpracuje jakýkoli issue. Spec-analyst pracuje s obsahem issue, ne s typem.
  Pokud issue popisuje feature request, spec-analyst extrahuje specifikaci.
  Pokud issue popisuje bug, spec-analyst stále extrahuje "specifikaci" (co opravit,
  jaké je expected chování) — ale uživatel by v tomto případě měl použít /fix-ticket.
  Command volba je na uživateli, ne na automatické detekci.
```

---

## Příloha A: Souhrnná tabulka nových souborů

| Soubor | Typ | Popis |
|--------|-----|-------|
| `agents/spec-analyst.md` | Nový agent | Feature specification analyst |
| `agents/architect.md` | Nový agent | Implementation planning architect |
| `commands/implement-feature.md` | Nový command | Feature implementation pipeline |
| `skills/bug-workflow/SKILL.md` | Rozšíření | + 2 nové intenty (implement-feature, analyze feature) |
| `commands/check-setup.md` | Rozšíření | + Feature Workflow validace |
| `commands/resume-ticket.md` | Rozšíření | + POST_SPEC checkpoint |
| `commands/onboard.md` | Rozšíření | + Feature Workflow v průvodci |
| `CLAUDE.md` | Rozšíření | + Feature Pipeline dokumentace |

## Příloha B: Souhrnná tabulka agent modelu

| Agent | Model | Pipeline | Read-only |
|-------|-------|----------|-----------|
| triage-analyst | sonnet | Bug-fix | Ano |
| **spec-analyst** | **sonnet** | **Feature** | **Ano** |
| code-analyst | sonnet | Bug-fix | Ano |
| **architect** | **opus** | **Feature** | **Ano** |
| fixer | opus | Obě | Ne |
| reviewer | opus | Obě | Ano |
| test-engineer | sonnet | Obě | Ne |
| e2e-test-engineer | sonnet | Obě | Ne |
| publisher | haiku | Obě | Ne |
| rollback-agent | haiku | Obě | Ne |

## Příloha C: Webhook events rozšíření

Feature pipeline produkuje stejné webhook events jako bug-fix pipeline:
- `pr-created` — po publisher
- `issue-blocked` — po block handler
- `pipeline-complete` — po dokončení (NE v Phase 1 — pouze pokud bude v budoucnosti přidán batch command `/implement-features`)

Nový event (pro budoucnost):
- `feature-spec-complete` — po spec-analyst (optional, pro monitoring tools)

---

## Review Status

**Review:** 2026-02-27 | **Stav po zapracování:** APPROVED
**Rozhodnutí Q1:** Generalizovat agent wording (PATCH) — generic "analysis provided" místo bug-specific textu
**Rozhodnutí Q2:** Dva nezávislé skilly — `bug-workflow` + nový `feature-workflow`
**Rozhodnutí Q3:** Diff limit odložen na Phase 2 — zůstává 100 řádků, dekompozice vyřeší
