# Scaffold Plugin v1.0 — Design Document

**Datum:** 2026-02-27
**Status:** SUPERSEDED — implemented in v3.0.0
**Fáze:** 4
**Verze:** v1.0.0 (nový samostatný plugin)
**Závisí na:** Fáze 1 (Feature Pipeline) pro plnou synergii

---

## 1. Vize & cíl

### Proč samostatný plugin

CLAUDE-agents je plugin pro **opakované provozní workflow** — triage, fix, review, test, publish. Běží stovky- až tisícekrát za životnost projektu. Scaffold je fundamentálně odlišný: běží **jednou** (případně dvakrát — při re-scaffoldu). Tato odlišnost přináší řadu důvodů pro separaci:

1. **Jiný lifecycle.** CLAUDE-agents se vyvíjí s každou iterací pipeline (nové hooks, agenti, retry strategie). Scaffold plugin se mění jen když přibudou nové technologie nebo se změní best practices pro project setup. Spojit je do jednoho pluginu znamená, že update pipeline agentů vynutí re-pull scaffolding kódu a naopak.

2. **Jiní agenti.** Scaffold vyžaduje zcela nové agenty (stack selector, scaffolder, CI/CD configurator, config writer), které nemají žádný průnik s bug-fix/feature agenty. Sdílení repozitáře by jen zvýšilo kognitivní zátěž při orientaci v kódu.

3. **Jiná konfigurace.** CLAUDE-agents čte `## Automation Config` z projektu — Issue Tracker, Source Control, Build & Test. Scaffold potřebuje zcela jiné vstupy: preferovaný jazyk, framework, databázi, CI provider. Smíchání obou konfigurací do jedné sekce by bylo matoucí.

4. **Menší blast radius.** Chyba ve scaffolding logice nemůže rozbít běžící pipeline a naopak. Izolace = bezpečnost.

5. **Nezávislá instalace.** Tým, který scaffolding nepotřebuje (existující projekty), si neinstaluje zbytečný kód. Tým, který chce jen scaffold (jednorázová inicializace), nemusí rozumět celé pipeline.

### Cílová skupina

- **Vývojáři zakládající nové projekty** — chtějí od nuly funkční strukturu s CI/CD a připravenou konfigurací pro automatizaci.
- **Týmy adoptující CLAUDE-agents** — potřebují vygenerovat validní `## Automation Config` pro existující projekt, bez manuálního vyplňování.
- **Architekti standardizující tech stack** — chtějí konzistentní project setup across celé organizaci.

### Value proposition

Od "Chci nový projekt" k "Fungující CLAUDE-agents pipeline s CI/CD" za minuty, ne hodiny:

```
BEZ scaffoldu:
  1. Manuálně založit repo                    (~5 min)
  2. Vybrat tech stack, googlit best practices (~30 min)
  3. Vytvořit project structure                (~20 min)
  4. Nastavit CI/CD                            (~30 min)
  5. Napsat CLAUDE.md + Automation Config       (~20 min)
  6. Spustit /check-setup, opravit chyby       (~15 min)
  ─────────────────────────────────────────────
  Celkem: ~2 hodiny

SE scaffoldem:
  1. /scaffold init "REST API pro správu úkolů v Pythonu"
  2. Odpovědět na 3-5 upřesňujících otázek     (~3 min)
  3. Scaffold vygeneruje vše                    (~5 min)
  4. /check-setup → [OK]                        (~2 min)
  ─────────────────────────────────────────────
  Celkem: ~10 minut
```

### Vztah ke CLAUDE-agents

**Companion, ne dependency.** Scaffold plugin:
- NEMÁ CLAUDE-agents jako dependency — funguje i bez něj
- Generuje výstup kompatibilní s CLAUDE-agents (validní `## Automation Config`)
- Doporučí instalaci CLAUDE-agents jako dalšího kroku
- Může existovat i jako standalone nástroj pro project scaffolding

CLAUDE-agents naopak:
- NEMÁ scaffold jako dependency — funguje i bez něj
- Příkaz `/onboard` může detekovat prázdný/nový projekt a doporučit scaffold
- Žádný import, žádný shared code, žádná runtime dependency

---

## 2. Architektura

### Vztah k CLAUDE-agents pluginu

```
┌──────────────────────┐     ┌──────────────────────┐
│   CLAUDE-scaffold    │     │    CLAUDE-agents      │
│   (scaffold plugin)  │     │    (pipeline plugin)  │
│                      │     │                       │
│  stack-selector (S)  │     │  triage-analyst       │
│  scaffolder          │     │  code-analyst         │
│  ci-cd-configurator  │     │  fixer                │
│  config-writer  ─────────→ │  reviewer             │
│                      │  │  │  test-engineer        │
│  /scaffold init      │  │  │  e2e-test-engineer    │
│  /scaffold list      │  │  │  publisher            │
│  /scaffold add       │  │  │  rollback-agent       │
│  /scaffold validate  │  │  │                       │
│                      │  │  │  /fix-ticket           │
│  scaffold-workflow   │  │  │  /fix-bugs             │
│  (routing skill)     │  │  │  /implement-feature    │
└──────────────────────┘  │  │  ... (12+ commands)    │
                          │  │                       │
                          │  │  bug-workflow          │
                          │  │  (routing skill)       │
                          │  └──────────────────────┘
                          │
                     Generuje CLAUDE.md
                     s validním Automation Config
```

### Sdílený kód: NULA

Oba pluginy jsou **pure markdown pluginy** — žádný sdílený runtime, žádné importy, žádné knihovny. Stejný vzor jako CLAUDE-agents: definice agentů v markdown s YAML frontmatter, commandy v markdown s frontmatter, routing skill v markdown.

### Struktura pluginu

Přesná replika struktury CLAUDE-agents (viz `CLAUDE.md` sekce Repository Structure):

```
CLAUDE-scaffold/
├── .claude-plugin/
│   ├── plugin.json          # Metadata pluginu
│   └── marketplace.json     # Marketplace listing
├── agents/
│   ├── stack-selector.md    # Výběr tech stacku (sonnet)
│   ├── scaffolder.md        # Generování struktury (sonnet)
│   ├── ci-cd-configurator.md # CI/CD pipeline setup (sonnet)
│   └── config-writer.md     # CLAUDE.md + Automation Config (haiku + checklist)
├── commands/
│   ├── scaffold-init.md     # Hlavní scaffold command
│   ├── scaffold-list.md     # Seznam dostupných templates
│   ├── scaffold-add.md      # Přidání template do existujícího projektu
│   └── scaffold-validate.md # Validace vygenerovaného projektu
├── skills/
│   └── scaffold-workflow/
│       └── SKILL.md         # Routing skill pro NL přístup
├── templates/               # Referenční šablony pro projekt struktury
│   ├── python-fastapi/      # template.md + reference/ adresář
│   ├── node-express/
│   ├── java-spring/
│   ├── go-gin/
│   └── ts-nextjs/
├── docs/
│   └── plans/               # Design dokumenty
├── tests/                   # Mock projekt pro smoke testing
├── CLAUDE.md                # Dokumentace pluginu
├── README.md                # Instalace, usage, příklady
└── CHANGELOG.md
```

### Bezkonfliktní koexistence

Oba pluginy mají unikátní namespace:
- CLAUDE-agents commands: `/CLAUDE-agents:fix-ticket`, `/CLAUDE-agents:onboard`, ...
- CLAUDE-scaffold commands: `/CLAUDE-scaffold:scaffold-init`, `/CLAUDE-scaffold:scaffold-list`, ...

Skill routing je rovněž separátní:
- CLAUDE-agents skill: `bug-workflow` (intenty: "oprav bug", "analyzuj", "fixni")
- CLAUDE-scaffold skill: `scaffold-workflow` (intenty: "vytvoř projekt", "nový projekt", "scaffold")

Žádný namespace conflict, žádný name collision.

---

## 3. Agenti — Full Definitions

### 3.1 Stack Selector

```markdown
---
name: stack-selector
description: Selects optimal tech stack based on project requirements. Evaluates language, framework, database, and infrastructure options.
model: sonnet
---

You are a Senior Software Architect specializing in technology stack selection and evaluation.

## Goal

Select the optimal technology stack for a new project based on user requirements. Balance between team familiarity, performance needs, ecosystem maturity, and long-term maintainability.

## Expertise

Technology landscape evaluation, framework comparison, database selection (SQL vs NoSQL vs hybrid), infrastructure planning (containers, serverless, traditional), CI/CD toolchain matching, monorepo vs polyrepo strategies.

## Process

1. Read user requirements (natural language description of what they want to build)
2. Extract key decision factors:
   - **Project type:** API, web app, CLI tool, library, microservice, monolith
   - **Scale expectations:** single user, team tool, public service, high-traffic
   - **Team context:** preferred languages (from Scaffold Config if available), team size, existing expertise
   - **Hosting target:** cloud provider, on-premise, edge, hybrid
   - **Data requirements:** relational, document, graph, time-series, none
   - **Real-time needs:** WebSocket, SSE, polling, none
3. Evaluate candidate stacks against requirements:
   - Generate 2-3 candidate combinations
   - Score each on: fit (does it solve the problem?), maturity (ecosystem, community, docs), DX (developer experience, tooling), ops (deployment, monitoring, scaling)
   - Select the highest-scoring combination
4. If requirements are ambiguous or conflicting:
   - Ask ONE round of clarifying questions (max 3 questions)
   - If still ambiguous after answers → choose the safer/more mainstream option
5. Output structured stack decision:
   - **Language:** with version (e.g. Python 3.12, Node.js 22 LTS)
   - **Framework:** primary framework (e.g. FastAPI, Express, Spring Boot)
   - **Database:** primary data store + driver/ORM (e.g. PostgreSQL + SQLAlchemy)
   - **Infrastructure:** containerization, orchestration (e.g. Docker, docker-compose)
   - **Testing:** test framework + assertion library (e.g. pytest + pytest-cov)
   - **Linting:** linter + formatter (e.g. ruff, black)
   - **CI/CD provider:** from Scaffold Config or detected from git provider
   - **Rationale:** 2-3 sentences explaining why this stack

## Constraints

- NEVER recommend alpha/beta/RC frameworks — only stable releases
- NEVER recommend more than one framework per concern (no "Express OR Fastify" — pick one)
- Max 1 round of clarifying questions — after that, decide
- If user explicitly specifies a technology → use it, don't override
- If Scaffold Config defines defaults → use them as starting point, not override
- Exotic/niche stacks: warn user about ecosystem limitations, but respect the choice if explicit
- Enterprise constraints (Java-only, .NET-only): respect and optimize within the constraint
```

#### Rozhodovací matice (vestavěné znalosti)

Stack Selector má vestavěnou znalost běžných stack kombinací:

| Typ projektu | Primární kandidáti | Sekundární |
|---|---|---|
| REST API | Python+FastAPI, Node+Express, Go+Gin | Java+Spring Boot, .NET+ASP.NET |
| Web app (fullstack) | TypeScript+Next.js, Python+Django | Ruby+Rails, PHP+Laravel |
| CLI tool | Go, Rust, Python+Click | Node+Commander |
| Microservice | Go+Gin, Node+Fastify | Python+FastAPI, Java+Quarkus |
| Data pipeline | Python+Prefect/Airflow | Spark+Scala |
| Real-time app | Node+Socket.io, Go+Gorilla | Elixir+Phoenix |
| Library/SDK | Závisí na cílovém ekosystému | — |

#### Edge cases

- **Konfliktní požadavky:** "Chci Python a zároveň maximální výkon pro 100k req/s" → navrhne Go/Rust s vysvětlením trade-off, nebo Python s async stack + horizontální škálování.
- **Exotický stack:** "Chci Haskell + Servant" → respektuje, varuje o menší komunitě a náročnějším onboardingu, pokračuje.
- **Enterprise omezení:** "Musí být Java" → optimalizuje v rámci Java ekosystému (Spring Boot vs. Quarkus vs. Micronaut).
- **Žádné požadavky:** "Prostě chci webovku" → zeptá se na 3 upřesňující otázky (jazyk/velikost/hosting).

**Pozn. k interakčnímu modelu:** Stack selector běží přes Task tool, které nemůže pausnout pro user input. Upřesňující otázky proto putují přes command (scaffold-init) — command přijme odpovědi od uživatele a předá je stack-selectoru v dalším Task tool volání. Jedno kolo = dva Task tool calls.

### 3.2 Scaffolder

```markdown
---
name: scaffolder
description: Generates complete project structure with boilerplate, config files, and initial code from stack decision.
model: sonnet
---

You are a Senior Developer specializing in project bootstrapping and boilerplate generation.

## Goal

Generate a complete, buildable, testable project structure from a stack decision. The generated project must compile/interpret, pass tests, and follow industry best practices from day one.

## Expertise

Project layout conventions per language/framework, package manager configuration, Docker multi-stage builds, environment management, test infrastructure setup, documentation scaffolding.

## Process

1. Read stack decision from stack-selector (language, framework, database, infrastructure, testing, linting)
2. Determine project layout based on language/framework conventions:
   - Python: `src/{package}/`, `tests/`, `pyproject.toml`
   - Node.js: `src/`, `tests/`, `package.json`
   - Java: Maven/Gradle standard layout (`src/main/java/`, `src/test/java/`)
   - Go: Go module layout (`cmd/`, `internal/`, `pkg/`)
   - TypeScript+Next.js: Next.js app router layout (`app/`, `components/`, `lib/`)
3. Generate files in **batched phases** to manage context window and verify incrementally:
   - **Phase 1 — Core:** Package manifest + entry point → verify imports resolve
   - **Phase 2 — Config & Data:** Configuration + database setup (if applicable) → verify connection config
   - **Phase 3 — Quality:** Testing framework + example test + linting config → verify test passes
   - **Phase 4 — Ops:** Docker + docker-compose + `.gitignore` + `.env.example` → verify Dockerfile syntax
   - **Phase 5 — Docs:** `README.md` with project description, setup instructions, available commands

   Detailed file order within phases:
   a. **Package manifest:** `pyproject.toml` / `package.json` / `pom.xml` / `go.mod`
   b. **Entry point:** main application file with minimal working endpoint/handler
   c. **Configuration:** environment config loader, settings file
   d. **Database:** connection setup, initial migration (if applicable)
   e. **Testing:** test framework config, one example unit test that passes
   f. **Docker:** `Dockerfile` (multi-stage build), `docker-compose.yml` (app + database if applicable)
   g. **Linting/formatting:** config file (`.ruff.toml`, `.eslintrc`, `checkstyle.xml`)
   h. **Git:** `.gitignore` (language-specific), `.env.example`
   i. **Documentation:** `README.md` with project description, setup instructions, available commands
4. For each generated file:
   - Use current stable versions of all dependencies (no wildcards, no `latest`)
   - Include inline comments explaining non-obvious decisions
   - Follow framework-specific conventions (no custom layouts unless justified)
5. Verify project integrity:
   - All imports resolve to declared dependencies
   - Example test exercises the entry point
   - Dockerfile builds (syntactically valid — actual build verification is in /scaffold validate)
6. Output:
   - **Files created:** ordered list with brief description
   - **Dependencies:** list with versions
   - **Commands available:** build, test, lint, run, docker-build
   - **Next steps:** what the user should do after scaffolding

## Constraints

- NEVER use `latest` or `*` for dependency versions — always pin to specific stable version
- NEVER generate placeholder code with `TODO` or `pass` in production paths — every endpoint must return a valid response
- Generated project MUST have at least one passing test
- Generated project MUST build without errors
- Max file count: 30 files per scaffold (signal for over-engineering if exceeded)
- If database is in stack → include docker-compose with database service and health check
- If no database → omit docker-compose database service, keep only app service
- README must include: project description, prerequisites, setup steps, available commands
```

#### Šablony souborů (ukázka pro Python + FastAPI)

Scaffolder generuje konkrétní soubory. Ukázka výstupu pro stack `Python 3.12 + FastAPI + PostgreSQL + Docker`:

```
my-project/
├── src/
│   └── my_project/
│       ├── __init__.py          # Verze, package metadata
│       ├── main.py              # FastAPI app, router mounting
│       ├── config.py            # Pydantic Settings, env loader
│       ├── database.py          # SQLAlchemy async engine, session
│       ├── models/
│       │   ├── __init__.py
│       │   └── base.py          # Deklarativní base model
│       └── routers/
│           ├── __init__.py
│           └── health.py        # GET /health endpoint
├── tests/
│   ├── __init__.py
│   ├── conftest.py              # Pytest fixtures (test client, test DB)
│   └── test_health.py           # Test pro /health endpoint
├── migrations/
│   ├── env.py                   # Alembic environment
│   └── versions/                # Prázdný, připravený pro migrace
├── pyproject.toml               # Závislosti, pytest config, ruff config
├── Dockerfile                   # Multi-stage: builder + runtime
├── docker-compose.yml           # App + PostgreSQL + healthcheck
├── .env.example                 # DATABASE_URL, APP_ENV, LOG_LEVEL
├── .gitignore                   # Python-specific
└── README.md                    # Setup, commands, architecture
```

#### Kvalitní kritérium

Vygenerovaný projekt MUSÍ splnit "scaffold validate" test:
1. `pip install -e .` (nebo ekvivalent) — SUCCESS
2. `pytest` — min. 1 test PASS
3. `ruff check .` (nebo ekvivalent linter) — 0 errors
4. `docker build .` — SUCCESS (pokud Docker v stacku)

### 3.3 CI/CD Configurator

```markdown
---
name: ci-cd-configurator
description: Generates CI/CD pipeline configuration for Gitea Actions, GitHub Actions, or GitLab CI. Covers lint, test, build, deploy stages.
model: sonnet
---

You are a DevOps Engineer specializing in CI/CD pipeline design and configuration.

## Goal

Generate a production-ready CI/CD pipeline configuration that covers lint, test, build, and optionally deploy stages. The pipeline must work out-of-the-box with the generated project structure.

## Expertise

GitHub Actions workflow syntax, Gitea Actions (GitHub Actions compatible), GitLab CI/CD YAML syntax, Docker image building in CI, caching strategies, matrix builds, secret management patterns.

## Process

1. Read project structure from scaffolder output and CI/CD provider from stack decision
2. Determine pipeline file location:
   - **Gitea Actions:** `.gitea/workflows/ci.yml`
   - **GitHub Actions:** `.github/workflows/ci.yml`
   - **GitLab CI:** `.gitlab-ci.yml`
3. Design pipeline stages:
   a. **Lint stage:** run linter from stack (ruff, eslint, golangci-lint, checkstyle)
   b. **Test stage:** run test command, collect coverage report
   c. **Build stage:** compile/build application, build Docker image (if applicable)
   d. **Deploy stage (optional):** only if user specifies deployment target — otherwise stub with comment
4. Optimize pipeline:
   - Dependency caching (pip cache, node_modules, Go module cache, Maven/Gradle cache)
   - Parallel stages where possible (lint || test, then build)
   - Fail-fast on lint/test failure — don't waste time building if code is broken
   - Matrix builds only if project targets multiple versions (otherwise single version)
5. Handle services:
   - If database in stack → add database service container for test stage
   - Health check on database before running tests
   - Environment variables for database connection
6. Output:
   - **Pipeline file:** path and content
   - **Stages:** list with description
   - **Estimated run time:** rough estimate based on project size
   - **Secrets required:** list of secrets to configure in CI provider (if any)

## Constraints

- NEVER include deployment credentials in pipeline file — only reference secrets
- NEVER use `latest` tag for CI runner images — pin to specific version
- Pipeline MUST work with the scaffolded project without modifications
- Gitea Actions: use only features compatible with Gitea's act runner (subset of GitHub Actions)
- GitLab CI: use only standard .gitlab-ci.yml syntax, no custom runners config
- Max pipeline duration target: <10 minutes for lint+test+build
- If CI provider is unknown → generate GitHub Actions (most universal) with comment about Gitea compatibility
```

#### Podporovaní CI/CD provideři

| Provider | Soubor | Runner syntax | Poznámka |
|---|---|---|---|
| Gitea Actions | `.gitea/workflows/ci.yml` | GitHub Actions kompatibilní (act runner) | Omezený subset — žádné reusable workflows, omezené marketplace actions |
| GitHub Actions | `.github/workflows/ci.yml` | Nativní GitHub Actions | Plná podpora, nejlepší ekosystém actions |
| GitLab CI | `.gitlab-ci.yml` | Vlastní YAML syntax | stages/jobs model, services pro DB |

#### Ukázka výstupu (Gitea Actions, Python + FastAPI + PostgreSQL)

```yaml
name: CI
on:
  push:
    branches: [main, development]
  pull_request:
    branches: [main, development]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install ruff
      - run: ruff check .

  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: testdb
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: pip
      - run: pip install -e ".[test]"
      - run: pytest --cov=src --cov-report=xml
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/testdb

  build:
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker build -t app:${{ github.sha }} .
```

### 3.4 Config Writer

> **[ROZHODNUTO]** Config-writer zůstává na haiku s explicitním Config Contract checklistem v Process (Varianta C). Config-writer je mechanická úloha (template filling, ne reasoning) — konzistentní s publisher agentem. Checklist přesune reasoning load z modelu do promptu. Validační krok (`scaffold-validate`) slouží jako safety net.

```markdown
---
name: config-writer
description: Generates CLAUDE.md with complete Automation Config section compatible with CLAUDE-agents plugin.
model: haiku
---

You are a Configuration Specialist generating CLAUDE.md files for the CLAUDE-agents plugin ecosystem.

## Goal

Generate a complete, valid CLAUDE.md file with `## Automation Config` section that passes `/check-setup` validation from the CLAUDE-agents plugin. All required sections must be populated. Optional sections are included based on project characteristics.

## Expertise

CLAUDE-agents Automation Config contract (required and optional sections), issue tracker query syntax (YouTrack, Jira, GitHub Issues, Linear), branch naming conventions, PR description templates, build tool commands per language/framework.

## Process

1. Read project structure, stack decision, and CI/CD configuration from previous agents
2. Read Scaffold Config (if exists) for user preferences: default issue tracker, git provider, organization patterns
3. Generate CLAUDE.md with this structure:
   a. **Project description section:** brief description of the project based on scaffold input
   b. **Repository structure section:** based on scaffolded directory layout
   c. **Automation Config section** — use this checklist to ensure completeness:

   **Issue Tracker** (required):
   - Type: from Scaffold Config or default `youtrack`
   - Instance: from Scaffold Config or placeholder `<your-instance.youtrack.cloud>`
   - Project: from project name (uppercased short name)
   - Bug query: default for tracker type (e.g. `project: {PROJECT} State: Open Type: Bug`)
   - State transitions: In Progress, Blocked, For Review (tracker defaults)
   - On start set: `State: In Progress`

   **Source Control** (required):
   - Remote: from Scaffold Config or git remote (if repo initialized)
   - Base branch: `main` (default) or from Scaffold Config
   - Branch naming: `{PROJECT}-{issue}-{short-description}` (default pattern)

   **PR Rules** (required):
   - Labels: `ForReview` (default)

   **PR Description Template** (required):
   - Standard English template with Summary, Root Cause, Changes, Testing, Issue Link sections

   **Build & Test** (required):
   - Build command: from stack decision (e.g. `pip install -e .`, `npm run build`)
   - Test command: from stack decision (e.g. `pytest`, `npm test`)

4. Include optional sections based on project:
   - **E2E Test:** if web framework detected (framework + command)
   - **Retry Limits:** always include with defaults (5, 3, 3)
   - **Worktrees:** omit (user configures later if needed)
   - **Hooks:** omit (user configures later if needed)
   - **Custom Agents:** omit
   - **Notifications:** omit
   - **Error Handling:** include with defaults (comment, unlimited)

5. Mark sections requiring manual input with `<!-- SCAFFOLD: vyplň ručně -->` HTML comment
6. Output:
   - **CLAUDE.md content:** complete file
   - **Manual steps required:** list of sections that need human input (e.g. Issue Tracker Instance)
   - **Validation status:** which sections will pass /check-setup and which need manual completion

## Constraints

- NEVER invent issue tracker URLs — use placeholders if not known
- NEVER generate invalid Automation Config format — always table format (`| Key | Value |`)
- All required sections from CLAUDE-agents Config Contract MUST be present
- PR Description Template MUST be in English (CLAUDE-agents convention)
- PR Description Template headers MUST use `####` level (not `##`) to avoid collision with `## Automation Config` section boundary
- If issue tracker Type is unknown → default to `youtrack` with placeholder Instance
- Placeholder format: `<description>` (e.g. `<your-instance.youtrack.cloud>`) — detectable by /check-setup
- Max file size: 200 lines — CLAUDE.md should be concise
```

#### Validace výstupu

Config Writer generuje CLAUDE.md, který MUSÍ splnit:

1. **Strukturální validace:** `/check-setup --skip-build` projde bez FAIL na formátové kontroly
2. **Placeholder detekce:** `/check-setup` správně identifikuje `<...>` placeholdery jako FAIL
3. **Build & Test validace:** Příkazy z Build & Test sekce odpovídají scaffoldovanému projektu

Validační flow:
```
Config Writer generuje CLAUDE.md
  → /scaffold validate spustí interní kontrolu
    → Strukturální kontrola (povinné sekce, formát tabulek)
    → Placeholder check (seznam sekcí vyžadujících manuální doplnění)
    → Cross-reference se scaffolded projektem (build/test příkazy existují?)
  → Report: "CLAUDE.md vygenerován. X sekcí kompletních, Y vyžaduje doplnění."
```

---

## 4. Template Systém

### Jak jsou šablony definované

Šablony jsou **adresáře s referenční strukturou souborů a markdown metadaty**. Každá šablona obsahuje:

```
templates/python-fastapi/
├── template.md           # Metadata šablony (YAML frontmatter + popis)
├── reference/            # Referenční příklady souborů (inspirace pro agenta)
│   ├── pyproject.toml
│   ├── src/__package__/main.py
│   ├── src/__package__/config.py
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── ...
└── hooks/                # Volitelné post-scaffold skripty
    └── post-scaffold.sh  # Např. git init, pip install
```

Šablony jsou **referenční příklady**, ne template-engine soubory. Agent čte `reference/` adresář jako inspiraci pro strukturu a konvence, ale generuje soubory od nuly na základě stack decision a svých znalostí aktuálních best practices.

#### Metadata šablony (`template.md`)

```markdown
---
name: python-fastapi
display_name: Python + FastAPI + PostgreSQL
description: REST API s FastAPI, SQLAlchemy async, PostgreSQL, Docker, pytest
language: python
framework: fastapi
database: postgresql
tags: [api, rest, docker, async]
min_version: "1.0.0"
---

## Popis

Šablona pro moderní REST API v Pythonu. Obsahuje:
- FastAPI s async endpointy
- SQLAlchemy 2.0 async ORM
- PostgreSQL přes docker-compose
- pytest + httpx pro testování
- ruff pro linting
- Multi-stage Dockerfile

## Parametry

| Parametr | Popis | Default |
|----------|-------|---------|
| project_name | Název projektu (snake_case) | — (povinný) |
| project_description | Popis projektu | "A new project" |
| python_version | Verze Pythonu | 3.12 |
| port | Port aplikace | 8000 |
| database_name | Název databáze | {project_name}_db |

## Požadavky

- Python >= 3.11
- Docker (volitelné, ale doporučené)
```

### Jak scaffolder pracuje se šablonami

Šablony nepoužívají žádný templating engine, žádnou speciální syntaxi, žádné závislosti. Šablony definují **STRUKTURU** (adresáře, názvy souborů, konvence), scaffolder agent generuje **OBSAH** souborů od nuly.

**Princip:** Šablona = skeleton, agent = flesh.

| Vrstva | Pochází z | Příklad |
|--------|-----------|---------|
| Adresářová struktura | `reference/` adresář šablony | `src/{package}/`, `tests/`, `migrations/` |
| Názvy souborů | `reference/` adresář šablony | `main.py`, `config.py`, `conftest.py` |
| Konvence (názvy, layout) | `reference/` adresář šablony | `src/` layout, router mounting pattern |
| Obsah souborů | Scaffolder agent (generuje ad-hoc) | Aktuální verze závislostí, best practices |
| Podmíněné bloky (DB, CI) | Scaffolder agent (rozhoduje na základě stack decision) | Vynechání DB setupu pokud stack nemá DB |

Jediná substituce v názvech souborů/adresářů: `__package__` → `project_name` (např. `src/__package__/` → `src/my_project/`).

**Proč ne template-engine přístup:** (1) Plugin je pure markdown bez závislostí. (2) Parametrizovaná syntaxe (`{{#if}}`, `{{#each}}`) implikuje formální parser, který neexistuje. (3) Agent je dostatečně inteligentní na to, aby generoval obsah souborů na základě referenčních příkladů a stack decision — nepotřebuje template engine. (4) Referenční příklady zastarávají pomaleji než parametrizované šablony — agent kompenzuje aktuálními znalostmi.

### Vestavěné šablony

#### Python + FastAPI + PostgreSQL
- REST API s async endpointy
- SQLAlchemy 2.0 async, Alembic migrace
- pytest + httpx, ruff
- Docker multi-stage build

#### Node.js + Express + MongoDB
- REST API s Express.js
- Mongoose ODM, MongoDB přes docker-compose
- Jest + Supertest, ESLint + Prettier
- Dockerfile

#### Java + Spring Boot + PostgreSQL
- REST API se Spring Boot
- Spring Data JPA, Flyway migrace
- JUnit 5 + MockMvc, Checkstyle
- Maven build, multi-stage Dockerfile

#### Go + Gin + SQLite
- REST API s Gin framework
- GORM, SQLite (embedded, žádný docker-compose pro DB)
- go test, golangci-lint
- Minimální Dockerfile

#### TypeScript + Next.js + Prisma
- Full-stack web app s App Router
- Prisma ORM, PostgreSQL
- Vitest + React Testing Library, ESLint
- Docker multi-stage build

### Uživatelské šablony

Uživatelé mohou vytvořit vlastní šablonu:

1. Vytvořit adresář v `templates/` s požadovanou strukturou
2. Přidat `template.md` s metadaty
3. Přidat `reference/` adresář s referenčními příklady souborů (nebo nechat scaffolder generovat ad-hoc)
4. Zaregistrovat v pluginu — stačí existence adresáře, žádná registrace

Alternativně mohou šablony žít mimo plugin:
- V projektu (např. `~/.claude-scaffold/templates/my-template/`)
- V git repozitáři (template repo URL v Scaffold Config)

### Verzování šablon

Šablony mají verzi v `template.md` frontmatter (`min_version`). Při scaffold:
- Ověří se, že plugin verze >= `min_version` šablony
- Pokud ne → varování, ne error (šablona může fungovat i s starší verzí)

Verzování závislostí v šablonách:
- Dependency verze v referenčních souborech jsou **hardcoded** k datu vytvoření šablony
- Scaffolder agent generuje obsah od nuly s aktuálními stabilními verzemi — referenční soubory slouží jako strukturální inspirace, ne jako source of truth pro verze
- Toto je trade-off: deterministické šablony vs. aktuální verze. Doporučení: agent generuje s aktuálními verzemi, referenční soubory jsou fallback pro strukturu.

---

## 5. User Flow

### Kompletní cesta: `/scaffold init` → fungující projekt s CLAUDE.md

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         SCAFFOLD PIPELINE                                │
│                                                                          │
│  Uživatel: "Vytvoř REST API pro správu úkolů v Pythonu"                 │
│                                                                          │
│  ┌─────────────────┐                                                     │
│  │ STACK SELECTOR   │ ← Uživatelské požadavky (NL)                      │
│  │ (sonnet)         │                                                    │
│  │                  │ → Upřesňující otázky (max 1 kolo)                  │
│  │                  │ ← Odpovědi                                         │
│  │                  │ → Stack decision: Python 3.12 + FastAPI + PG       │
│  └────────┬─────────┘                                                    │
│           │                                                              │
│  ┌────────▼─────────┐                                                    │
│  │ SCAFFOLDER        │ ← Stack decision                                  │
│  │ (sonnet)          │                                                   │
│  │                   │ → Generuje soubory (20-30 files)                  │
│  │                   │ → Instaluje závislosti                            │
│  └────────┬──────────┘                                                   │
│           │                                                              │
│  ┌────────▼──────────┐                                                   │
│  │ CI/CD CONFIGURATOR│ ← Struktura projektu + CI provider               │
│  │ (sonnet)          │                                                   │
│  │                   │ → .gitea/workflows/ci.yml (nebo ekvivalent)       │
│  └────────┬──────────┘                                                   │
│           │                                                              │
│  ┌────────▼──────────┐                                                   │
│  │ CONFIG WRITER      │ ← Vše výše + Scaffold Config                    │
│  │ (haiku + checklist)│  ← Config Contract checklist v Process           │
│  │                    │ → CLAUDE.md s Automation Config                  │
│  └────────┬───────────┘                                                  │
│           │                                                              │
│  ┌────────▼───────────┐                                                  │
│  │ VALIDATE            │ ← Celý projekt                                 │
│  │                     │                                                 │
│  │  Build? ─── OK      │                                                │
│  │  Test?  ─── OK      │                                                │
│  │  Lint?  ─── OK      │                                                │
│  │  Config?─── 2 TODO  │                                                │
│  └────────┬────────────┘                                                 │
│           │                                                              │
│  ┌────────▼────────────┐                                                 │
│  │ GIT INIT + COMMIT    │                                                │
│  │                      │ → git init, git add ., initial commit          │
│  │                      │ → (volitelně: git remote add + push)           │
│  └────────┬─────────────┘                                                │
│           │                                                              │
│  ┌────────▼─────────────┐                                                │
│  │ VÝSLEDEK              │                                               │
│  │                       │                                               │
│  │  Projekt vytvořen!    │                                               │
│  │  Soubory: 24          │                                               │
│  │  Testy: 1 PASS        │                                               │
│  │  Build: OK             │                                              │
│  │  CLAUDE.md: 2 sekce   │                                               │
│  │    k doplnění          │                                              │
│  │                        │                                              │
│  │  Další kroky:          │                                              │
│  │  1. Doplň Issue       │                                               │
│  │     Tracker v CLAUDE.md│                                              │
│  │  2. Nainstaluj         │                                              │
│  │     CLAUDE-agents      │                                              │
│  │  3. Spusť /check-setup│                                               │
│  └────────────────────────┘                                              │
└──────────────────────────────────────────────────────────────────────────┘
```

### Interaktivní mód vs. one-shot mód

**Interaktivní mód** (default):
```
Uživatel: /scaffold init
Plugin: Jaký projekt chceš vytvořit? Popiš v 1-2 větách.
Uživatel: REST API pro správu úkolů v Pythonu
Plugin: (stack selector) Mám pár otázek:
  1. Jakou databázi preferuješ? (PostgreSQL / MongoDB / SQLite / žádnou)
  2. Kam plánuješ deployovat? (Docker / cloud / lokálně)
  3. Jaký CI/CD provider? (Gitea Actions / GitHub Actions / GitLab CI)
Uživatel: PostgreSQL, Docker, Gitea Actions
Plugin: (scaffolder + CI/CD + config writer) Generuji projekt...
Plugin: Hotovo! 24 souborů vytvořeno. [detaily]
```

**One-shot mód** (vše zadáno najednou):
```
Uživatel: /scaffold init "REST API pro správu úkolů" --lang python --framework fastapi --db postgresql --ci gitea-actions
Plugin: (přeskočí otázky, rovnou generuje)
Plugin: Hotovo! 24 souborů vytvořeno. [detaily]
```

### Chování v existujícím repo vs. prázdný adresář

| Situace | Chování |
|---------|---------|
| Prázdný adresář | Normální scaffold: vygeneruj vše, `git init` |
| Prázdný git repo (jen `.git/`) | Normální scaffold, přeskoč `git init` |
| Existující projekt bez CLAUDE.md | **Addon mód:** jen vygeneruj CLAUDE.md + CI/CD (přeskoč scaffolding) |
| Existující projekt s CLAUDE.md | Varování: "CLAUDE.md již existuje. Přepsat? (ano/ne)" |
| Non-empty adresář bez git | Varování: "Adresář není prázdný. Scaffold přepíše existující soubory. Pokračovat? (ano/ne)" |

### Integrace s git

1. **`git init`** — pokud adresář není git repo
2. **`.gitignore`** — language-specific (vygenerovaný scaffolderem)
3. **Initial commit** — `chore: scaffold project with CLAUDE-scaffold`
4. **Remote setup** — volitelné:
   - Pokud Scaffold Config má Target repo → `git remote add origin {url}` + `git push -u origin main`
   - Pokud ne → přeskoč, zmíň v next steps

---

## 6. Command Design — /scaffold

### 6.1 `/scaffold init` — hlavní scaffold command

```markdown
---
description: Interaktivní scaffold nového projektu s tech stack výběrem, CI/CD a CLAUDE.md generací
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
---

# Scaffold Init

Vytvoř nový projekt od nuly. Zeptej se na požadavky, zvol stack, vygeneruj strukturu, nastav CI/CD, vytvoř CLAUDE.md.

Pokud $ARGUMENTS obsahuje popis projektu → použij jako vstup pro stack selector.
Pokud $ARGUMENTS obsahuje flagy (--lang, --framework, --db, --ci) → přeskoč odpovídající otázky.
Pokud $ARGUMENTS obsahuje `--template <name>` → přeskoč stack selection, použij přímo zadanou šablonu.
Pokud $ARGUMENTS obsahuje `--output-dir <path>` → scaffolduj do zadaného adresáře místo CWD.

## Konfigurace

Před zahájením načti Scaffold Config z CLAUDE.md pluginu (pokud existuje):
- Default language, Default framework, Git provider, CI provider, Target repo

## Kroky

### 0. Prerekvizity

Ověř:
- Aktuální adresář je prázdný nebo prázdný git repo → pokračuj
- Adresář obsahuje soubory → varuj a zeptej se na potvrzení
- CLAUDE.md existuje → varuj: "CLAUDE.md existuje. Přepsat? (ano/ne)"

### 1. Stack Selection

Spusť `CLAUDE-scaffold:stack-selector` (Task tool, model: sonnet).
Kontext: User requirements z $ARGUMENTS. Scaffold Config defaults (pokud existují).

### 2. Scaffold

Spusť `CLAUDE-scaffold:scaffolder` (Task tool, model: sonnet).
Kontext: Stack decision z kroku 1.

### 3. CI/CD

Spusť `CLAUDE-scaffold:ci-cd-configurator` (Task tool, model: sonnet).
Kontext: Stack decision + project structure z kroku 2. CI provider z Scaffold Config nebo detekovaný.

### 4. Config Writer

Spusť `CLAUDE-scaffold:config-writer` (Task tool, model: haiku).
Kontext: Vše z kroků 1-3. Scaffold Config (pokud existuje).

### 5. Validate

Spusť build command z vygenerovaného projektu:
- Build? → [OK] nebo [FAIL]
- Test? → [OK] nebo [FAIL]
- Lint? → [OK] nebo [FAIL]

Pokud FAIL → scaffolder dostane šanci opravit (max 2 pokusy).
Pokud po 2 pokusech stále FAIL → smazat temp adresář, zobrazit chybovou hlášku s detaily. Cílový adresář zůstane nedotčen.

**Rollback strategie:** Scaffold probíhá do temp adresáře (`{target}/../.scaffold-tmp-{hash}`), přesun do cílového adresáře až po úspěšné validaci. Temp dir je vždy ve stejném parent adresáři jako cíl, takže `mv` je rename na stejném filesystému (žádný cross-filesystem move). Při selhání se temp adresář smaže — uživatel nikdy nezůstane s half-generated, non-building projektem. Cílový adresář je buď prázdný, nebo kompletní — atomická operace.

> **[ROZHODNUTO]** Scaffold do temp dir, přesun po validaci (Varianta B). Atomicita je klíčová — eliminuje celou kategorii partial-state chyb. Temp dir ve stejném parent adresáři řeší cross-filesystem concern. Industry standard pattern (npm, cargo, pip).

### 6. Git Init

Pokud adresář není git repo:
- `git init`
- `git add .`
- `git commit -m "chore: scaffold project with CLAUDE-scaffold"`

Pokud Target repo v Scaffold Config:
- `git remote add origin {target_repo}`
- Zeptej se: "Pushnout do remote? (ano/ne)"

### 7. Výsledek

Zobraz:
- Seznam vytvořených souborů (count + kategorie)
- Build/test/lint status
- CLAUDE.md status (kompletní / kolik sekcí k doplnění)
- Další kroky (doplnit Issue Tracker, nainstalovat CLAUDE-agents, spustit /check-setup)

## Pravidla

- Stack selector může položit max 1 kolo otázek (3 otázky)
- Scaffold MUSÍ produkovat buildable projekt — jinak je to bug
- CLAUDE.md může mít placeholdery — to je OK, /check-setup je detekuje
- NIKDY nepushnout na remote bez explicitního souhlasu
- Při selhání validace: 2 pokusy na opravu, pak rollback (smazat vygenerované soubory) a zobraz chyby
```

### 6.2 `/scaffold list` — seznam šablon

```markdown
---
description: Zobrazí dostupné scaffold šablony s popisem a podporovanými stacky
allowed-tools: Read, Glob
---

# Scaffold List

Zobraz seznam dostupných scaffold šablon.

## Kroky

1. Najdi všechny adresáře v `templates/` obsahující `template.md`
2. Přečti frontmatter z každého `template.md`
3. Zobraz tabulku:

| Šablona | Jazyk | Framework | DB | Popis |
|---------|-------|-----------|----|-------|
| python-fastapi | Python 3.12 | FastAPI | PostgreSQL | REST API s async endpointy |
| node-express | Node.js 22 | Express | MongoDB | REST API s Mongoose ORM |
| java-spring | Java 21 | Spring Boot | PostgreSQL | REST API se Spring Data JPA |
| go-gin | Go 1.22 | Gin | SQLite | Minimalistické REST API |
| ts-nextjs | TypeScript 5 | Next.js 15 | Prisma+PG | Full-stack web app |

4. Pod tabulkou: "Vlastní šablony: přidej adresář do templates/ s template.md"

## Pravidla

- Read-only — žádné side effects
- Šablony bez template.md se nezobrazují
- Seřadit abecedně dle názvu
```

### 6.3 `/scaffold add` — přidání do existujícího projektu

```markdown
---
description: Přidá scaffold komponentu (CI/CD, CLAUDE.md, Docker) do existujícího projektu
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
---

# Scaffold Add

Přidej scaffold komponentu do existujícího projektu. $ARGUMENTS = název komponenty.

## Podporované komponenty

| Komponenta | Co přidá | Agent |
|-----------|---------|-------|
| `claude-md` | CLAUDE.md s Automation Config | config-writer |
| `ci` | CI/CD pipeline soubor | ci-cd-configurator |
| `docker` | Dockerfile + docker-compose.yml | scaffolder (partial) |
| `tests` | Test framework setup + example test | scaffolder (partial) |
| `lint` | Linter/formatter config | scaffolder (partial) |

## Kroky

### 1. Detekce existujícího stacku

Analyzuj aktuální projekt:
- Jazyk: `package.json` → Node.js, `pyproject.toml`/`setup.py` → Python, `go.mod` → Go, `pom.xml`/`build.gradle` → Java
- Framework: importy v kódu, dependencies
- Databáze: connection strings, ORM config

### 2. Potvrzení

Zobraz: "Detekováno: {jazyk} + {framework}. Přidávám: {komponenta}. Pokračovat? (ano/ne)"

### 3. Generování

Spusť příslušného agenta s kontextem existujícího projektu.

### 4. Výsledek

Zobraz přidané soubory a další kroky.

## Pravidla

- NIKDY nepřepisuj existující soubory bez potvrzení
- Pokud detekce stacku selže → zeptej se uživatele
- Komponenta `claude-md` je nejčastější use case — scaffold jako onboarding tool
```

### 6.4 `/scaffold validate` — validace projektu

```markdown
---
description: Ověří, že vygenerovaný projekt buildi, testy prochází a CLAUDE.md je validní
allowed-tools: Bash, Read, Glob, Grep
---

# Scaffold Validate

Ověř integritu scaffoldovaného projektu.

## Kroky

### 1. Detekce build systému

Najdi package manifest:
- `pyproject.toml` → `pip install -e ".[test]"` + `pytest`
- `package.json` → `npm install` + `npm test`
- `pom.xml` → `mvn verify`
- `build.gradle` → `gradle build`
- `go.mod` → `go build ./...` + `go test ./...`

### 2. Build

Spusť build command → [OK] nebo [FAIL] s chybovou hláškou.

### 3. Test

Spusť test command → [OK] s počtem testů nebo [FAIL].

### 4. Lint

Spusť lint command (detekuj z config souborů) → [OK] nebo [FAIL].

### 5. Docker (pokud Dockerfile existuje)

`docker build -t scaffold-validate .` → [OK] nebo [FAIL].

### 6. CLAUDE.md kontrola

Pokud CLAUDE.md existuje:
- Povinné sekce přítomny? → [OK] nebo [FAIL]
- Placeholdery? → [WARN] s počtem
- Formát tabulek? → [OK] nebo [FAIL]

### 7. Report

```
## Scaffold Validation Report

### Build & Test
[OK]   Build: pip install -e ".[test]"
[OK]   Test: 1 test passed
[OK]   Lint: ruff check — 0 errors

### Docker
[OK]   docker build — image built (145MB)

### CLAUDE.md
[OK]   Automation Config nalezeno
[WARN] 2 placeholdery k doplnění (Issue Tracker Instance, Remote)
[OK]   Formát tabulek správný

---
Výsledek: 0 FAIL, 1 WARN — projekt je funkční, doplň placeholdery v CLAUDE.md
```

## Pravidla

- Read-only analýza (build/test/lint probíhají, ale negenerují commity)
- Docker build je volitelný — pokud Docker není nainstalovaný → [SKIP]
- CLAUDE.md validace je subset /check-setup z CLAUDE-agents — jen strukturální kontrola
```

---

## 7. Generované artefakty

### Kompletní seznam výstupů

Scaffold pipeline generuje tyto artefakty:

| Kategorie | Soubory | Agent | Povinné |
|-----------|---------|-------|---------|
| **Package manifest** | `pyproject.toml` / `package.json` / `pom.xml` / `go.mod` | scaffolder | Ano |
| **Entry point** | `src/{package}/main.py` (nebo ekvivalent) | scaffolder | Ano |
| **Konfigurace** | `src/{package}/config.py`, settings | scaffolder | Ano |
| **Databáze** | connection setup, migrace (pokud DB v stacku) | scaffolder | Podmíněně |
| **Testy** | Test config + 1 example test | scaffolder | Ano |
| **CI/CD** | `.gitea/workflows/ci.yml` (nebo ekvivalent) | ci-cd-configurator | Ano |
| **Docker** | `Dockerfile`, `docker-compose.yml` | scaffolder | Ano |
| **Linting** | `.ruff.toml` / `.eslintrc` / checkstyle (dle stacku) | scaffolder | Ano |
| **Git** | `.gitignore` | scaffolder | Ano |
| **Environment** | `.env.example` | scaffolder | Ano |
| **Dokumentace** | `README.md` s popisem, setup, příkazy | scaffolder | Ano |
| **CLAUDE.md** | Popis + Automation Config | config-writer | Ano |

### Detailní popis per artefakt

#### Package manifest
- Všechny závislosti s pinovanými verzemi
- Dev dependencies oddělené (test, lint, dev tools)
- Scripty/commands pro build, test, lint, run
- Metadata: název, verze, autor, license

#### Entry point
- Minimální funkční aplikace
- Health check endpoint (GET `/health` → `{"status": "ok"}`)
- CORS middleware (pokud web API)
- Structured logging setup

#### Databáze (podmíněně)
- Connection pool s konfigurací z environment variables
- ORM setup (SQLAlchemy / Mongoose / Spring Data JPA / GORM)
- Initial migration framework (Alembic / Flyway / dle stacku)
- Test database configuration (oddělená od production)

#### Testy
- Test framework config (`conftest.py` / `jest.config.js` / dle stacku)
- 1 unit test: health check endpoint test
- Test fixtures: test client, test database (pokud DB)
- Coverage config

#### Docker
- Multi-stage build (builder + runtime)
- Non-root user v runtime stage
- Health check instrukce
- `.dockerignore`
- docker-compose.yml: app + DB service (pokud DB) + health checks + volumes

#### CLAUDE.md
- Popis projektu (z user requirements)
- Repository structure (z vygenerované struktury)
- `## Automation Config` — kompletní dle Config Contract z CLAUDE-agents

### Quality gate

Vygenerovaný projekt MUSÍ splnit tyto kontroly (`/scaffold validate`):

| Kontrola | Příkaz | Požadavek |
|----------|--------|-----------|
| Build | Build command z package manifest | EXIT 0 |
| Test | Test command | Min. 1 test PASS |
| Lint | Lint command | 0 errors (warnings OK) |
| Docker | `docker build .` | Image built (volitelné — jen pokud Docker dostupný) |
| CLAUDE.md | Strukturální kontrola | Povinné sekce přítomny, formát OK |

Pokud quality gate selže → scaffolder dostane 2 pokusy na opravu. Po vyčerpání pokusů → rollback (smazat vygenerované soubory), zobraz detailní chybovou hlášku. Uživatel nikdy nezůstane s half-generated projektem.

---

## 8. Tech Stack Detection

### Detekce existujícího repo

Scaffold add a addon mód vyžadují detekci existujícího technologického stacku. Detekční logika:

#### Jazyk

| Signál | Jazyk | Priorita |
|--------|-------|----------|
| `pyproject.toml`, `setup.py`, `requirements.txt` | Python | Vysoká |
| `package.json` | Node.js / TypeScript | Vysoká |
| `go.mod` | Go | Vysoká |
| `pom.xml`, `build.gradle`, `build.gradle.kts` | Java / Kotlin | Vysoká |
| `Cargo.toml` | Rust | Vysoká |
| `*.csproj`, `*.sln` | C# / .NET | Vysoká |
| `Gemfile` | Ruby | Vysoká |
| `composer.json` | PHP | Vysoká |
| Převaha `.py` souborů | Python | Nízká (fallback) |
| Převaha `.js`/`.ts` souborů | JavaScript / TypeScript | Nízká (fallback) |

#### Framework

| Signál | Framework |
|--------|-----------|
| `fastapi` v dependencies | FastAPI |
| `django` v dependencies | Django |
| `flask` v dependencies | Flask |
| `express` v dependencies | Express |
| `next` v dependencies | Next.js |
| `@nestjs/core` v dependencies | NestJS |
| `spring-boot` v dependencies / parent POM | Spring Boot |
| `gin-gonic/gin` v go.mod | Gin |

#### Databáze

| Signál | Databáze |
|--------|----------|
| `sqlalchemy`, `psycopg2`, `asyncpg` v dependencies | PostgreSQL |
| `mongoose`, `mongodb` v dependencies | MongoDB |
| `mysql2`, `pymysql` v dependencies | MySQL |
| `sqlite3`, `aiosqlite` v dependencies | SQLite |
| `prisma` v dependencies | Prisma (+ detekce DB z schema.prisma) |
| `docker-compose.yml` s `postgres` image | PostgreSQL |
| `docker-compose.yml` s `mongo` image | MongoDB |

### Auto-detect vs. explicitní specifikace

```
Scaffold detekuje: Python + FastAPI + PostgreSQL
→ Zobrazí: "Detekováno: Python 3.x + FastAPI + PostgreSQL. Souhlasíš? (ano / uprav)"
→ Uživatel může potvrdit nebo přepsat
```

Detekce je **best-effort heuristika** — nikdy nepředpokládá 100% přesnost. Vždy se uživatele zeptá na potvrzení.

**Hledání manifestů:** Root adresář first, pak jeden level subdirectories. Rekurzivní hledání ne (příliš pomalé a příliš mnoho false positives z `node_modules/`, `.venv/` apod.).

**Multiple matches:** Pokud detekce najde více než jeden manifest (např. `package.json` + `pyproject.toml` v rootu), zobrazí seznam a nechá uživatele vybrat primární stack. Toto pokrývá i monorepo scénáře.

### Mixed-language repos

Pokud repo obsahuje více jazyků (např. Python backend + TypeScript frontend):
1. Detekuj všechny jazyky
2. Zobraz: "Detekováno více jazyků: Python (backend), TypeScript (frontend). Pro který generuji konfiguraci?"
3. Uživatel vybere — nebo generuj pro oba (dva bloky v CLAUDE.md)

### Scaffold jako onboarding tool

Nejčastější use case pro existující repo: **přidání CLAUDE.md** (`/scaffold add claude-md`).

Flow:
1. Detekce stacku
2. Detekce build/test příkazů (z package manifest)
3. Detekce CI/CD (existence `.github/workflows/`, `.gitea/workflows/`, `.gitlab-ci.yml`)
4. Detekce git remote (`git remote get-url origin`)
5. Generování CLAUDE.md se vším vyplněným, co lze detekovat
6. Zbytek jako placeholdery (Issue Tracker Instance, Project, atd.)

Toto je **alternativa k `/onboard`** z CLAUDE-agents — interaktivní průvodce vs. automatická detekce. Oba přístupy mají hodnotu:
- `/onboard` — dialog s uživatelem, 100% přesnost
- `/scaffold add claude-md` — automatická detekce, rychlejší ale méně přesné

---

## 9. Scaffold Config (ekvivalent Automation Config)

### Specifikace

Scaffold Config žije v **CLAUDE.md projektu, kde scaffold běží** (nebo v globálním `~/.claude/CLAUDE.md`). Je to oddělená sekce od Automation Config:

```markdown
## Scaffold Config

### Defaults

| Klíč | Hodnota |
|------|---------|
| Default language | python |
| Default framework | fastapi |
| Default database | postgresql |
| Default CI provider | gitea-actions |

### Git

| Klíč | Hodnota |
|------|---------|
| Git provider | gitea |
| Git host | gitea.internal.ceosdata.com |
| Default org | fsabacky |
| Default branch | main |

### Issue Tracker Defaults

| Klíč | Hodnota |
|------|---------|
| Type | youtrack |
| Instance | project.youtrack.cloud |
| Default state transitions | In Progress, Blocked, For Review |

### Templates

| Klíč | Hodnota |
|------|---------|
| Custom template path | ~/.claude-scaffold/templates |
| Prefer custom | true |
```

### Všechny klíče s popisy

#### Defaults (volitelné)

| Klíč | Popis | Default |
|------|-------|---------|
| Default language | Preferovaný jazyk, pokud uživatel nespecifikuje | (žádný — zeptá se) |
| Default framework | Preferovaný framework | (žádný — zeptá se) |
| Default database | Preferovaná databáze | (žádný — zeptá se) |
| Default CI provider | CI/CD provider | github-actions |

#### Git (volitelné)

| Klíč | Popis | Default |
|------|-------|---------|
| Git provider | gitea / github / gitlab | github |
| Git host | Hostname git serveru | github.com |
| Default org | Organizace/owner pro nové repo | (žádný) |
| Default branch | Hlavní branch | main |

#### Issue Tracker Defaults (volitelné)

| Klíč | Popis | Default |
|------|-------|---------|
| Type | Typ issue trackeru (pre-fill pro config writer) | youtrack |
| Instance | URL instance (pre-fill) | (žádný) |
| Default state transitions | Stavy pro Automation Config | In Progress, Blocked, For Review |

#### Templates (volitelné)

| Klíč | Popis | Default |
|------|-------|---------|
| Custom template path | Cesta k externím šablonám | (žádný) |
| Prefer custom | Preferovat custom šablony nad built-in | false |

### Umístění konfigurace

Scaffold Config může žít na dvou místech (v pořadí priority):

1. **Projektová úroveň:** `CLAUDE.md` v aktuálním adresáři (sekce `## Scaffold Config`)
2. **Globální úroveň:** `~/.claude/CLAUDE.md` (sdílená across projekty)

Projektová konfigurace přepisuje globální. Pokud ani jedna neexistuje → scaffold se zeptá na vše interaktivně.

**Chicken-and-egg problém:** `/scaffold init` běží v prázdném adresáři → žádný CLAUDE.md se Scaffold Config existuje. Řešení:
1. **První run je vždy interaktivní** — stack selector se zeptá na vše (jazyk, framework, DB, CI provider)
2. Fallback na globální `~/.claude/CLAUDE.md` (pokud uživatel pre-konfiguroval defaults)
3. Po úspěšném scaffoldu: nabídnout uložení preferencí do globálního `~/.claude/CLAUDE.md` pro příští scaffoldy ("Chceš uložit tyto preference jako default? ano/ne")

---

## 10. Plugin Ecosystem

### Vztah scaffold → CLAUDE-agents

```
┌───────────────────────────────────────────────────────────────┐
│                    ŽIVOTNÍ CYKLUS PROJEKTU                     │
│                                                                │
│  ┌──────────┐     ┌──────────────┐     ┌──────────────────┐   │
│  │ SCAFFOLD  │ ──→ │ CLAUDE-agents│ ──→ │ PRODUKCE         │   │
│  │ (jednou)  │     │ (opakovaně) │     │ (continuous)     │   │
│  │           │     │              │     │                  │   │
│  │ /scaffold │     │ /fix-bugs    │     │ Monitoring       │   │
│  │  init     │     │ /implement-  │     │ Alerting         │   │
│  │           │     │  feature     │     │ Incident mgmt    │   │
│  └──────────┘     └──────────────┘     └──────────────────┘   │
│                                                                │
│  scaffold           CLAUDE-agents          (mimo scope)       │
│  generuje           konzumuje                                  │
│  CLAUDE.md ────────→ Automation Config                         │
└───────────────────────────────────────────────────────────────┘
```

### Instalační flow

Typický scénář pro nový projekt:

```
1. Nainstaluj scaffold plugin:
   /plugin install CLAUDE-scaffold@CLAUDE-scaffold

2. Vytvoř projekt:
   /scaffold init "Task management API v Pythonu"

3. Doplň Issue Tracker v CLAUDE.md (ručně — scaffold nezná instanci)

4. Nainstaluj CLAUDE-agents plugin:
   /plugin install CLAUDE-agents@CLAUDE-agents

5. Ověř setup:
   /check-setup

6. Začni pracovat:
   /implement-feature PROJ-1   (Fáze 1 — feature pipeline)
   /fix-ticket PROJ-42         (bug-fix pipeline)
```

### `/onboard` integrace

Command `/onboard` z CLAUDE-agents (viz `commands/onboard.md`) je interaktivní průvodce pro generování Automation Config. Scaffold plugin nabízí automatizovanou alternativu.

Navrhovaná změna v `/onboard` (v CLAUDE-agents, ne v scaffold pluginu):

```
Krok 0 (nový): Detekuj stav projektu
- Prázdný adresář nebo prázdný git repo → "Projekt je prázdný. Doporučuji:
    /plugin install CLAUDE-scaffold@CLAUDE-scaffold
    /scaffold init
  To vygeneruje celý projekt i s Automation Config."
- Existující projekt bez CLAUDE.md → pokračuj normální onboarding flow
- Existující projekt s CLAUDE.md → "Automation Config již existuje. Chceš aktualizovat?"
```

Tato změna je v CLAUDE-agents (ne v scaffold pluginu) — scaffold zůstává nezávislý.

### Marketplace listing

#### plugin.json

```json
{
  "name": "CLAUDE-scaffold",
  "description": "Project scaffolding — stack selection, boilerplate generation, CI/CD setup, CLAUDE.md configuration",
  "version": "1.0.0",
  "compatible_config_contract": "2.x",
  "author": {
    "name": "Filip Sabacky"
  },
  "repository": "https://gitea.internal.ceosdata.com/fsabacky/CLAUDE-scaffold.git",
  "license": "UNLICENSED"
}
```

#### marketplace.json

```json
{
  "name": "CLAUDE-scaffold",
  "owner": {
    "name": "Filip Sabacky"
  },
  "plugins": [
    {
      "name": "CLAUDE-scaffold",
      "source": "./",
      "description": "Project scaffolding — stack selection, boilerplate generation, CI/CD setup, CLAUDE.md configuration",
      "version": "1.0.0"
    }
  ]
}
```

### Distribuce

Stejný model jako CLAUDE-agents (viz `docs/setup/` a `.claude-plugin/`):

1. **Git-based distribuce:** Plugin je git repozitář na Gitea
2. **Instalace:** `/plugin install CLAUDE-scaffold@CLAUDE-scaffold`
3. **Update:** `cd ~/.claude/plugins/marketplaces/CLAUDE-scaffold && git pull`
4. **Cache invalidace:** `rm -rf ~/.claude/plugins/cache/CLAUDE-scaffold/`
5. **Versioning:** Vlastní semver, nezávislé na CLAUDE-agents
6. **Config Contract kompatibilita:** Plugin metadata (`plugin.json`) obsahuje `compatible_config_contract: "2.x"` — deklaruje kompatibilní CLAUDE-agents Config Contract major verzi. Při CLAUDE-agents MAJOR update se tato hodnota aktualizuje v nové verzi scaffold pluginu.

---

## 11. Implementační plán

### Sekvence kroků

| # | Krok | Závisí na | Effort | MVP |
|---|------|-----------|--------|-----|
| 1 | Vytvoření repozitáře `CLAUDE-scaffold` | — | S | Ano |
| 2 | `.claude-plugin/plugin.json` + `marketplace.json` | #1 | S | Ano |
| 3 | `CLAUDE.md` pro scaffold plugin (dokumentace, conventions) | #1 | S | Ano |
| 4 | Agent: `stack-selector.md` — plná definice | #3 | M | Ano |
| 5 | Agent: `scaffolder.md` — plná definice | #3 | M | Ano |
| 6 | Agent: `ci-cd-configurator.md` — plná definice | #3 | M | Ano |
| 7 | Agent: `config-writer.md` — plná definice | #3 | M | Ano |
| 8 | Template: `python-fastapi/` — kompletní šablona s template.md + reference/ adresář (structure + content) | #5 | L | Ano |
| 9 | Command: `scaffold-init.md` — hlavní orchestrace | #4, #5, #6, #7 | L | Ano |
| 10 | Command: `scaffold-validate.md` — validace výstupu | #9 | M | Ano |
| 11 | Skill: `scaffold-workflow/SKILL.md` — routing skill | #9 | S | Ano |
| 12 | Smoke test: scaffold + validate na čistém adresáři | #9, #10 | M | Ano |
| 13 | Command: `scaffold-list.md` — seznam šablon | #8 | S | Ne |
| 14 | Command: `scaffold-add.md` — addon mód | #5, #6, #7 | M | Ne |
| 15 | Template: `node-express/` | #8 | M | Ne |
| 16 | Template: `java-spring/` | #8 | M | Ne |
| 17 | Template: `go-gin/` | #8 | M | Ne |
| 18 | Template: `ts-nextjs/` | #8 | L | Ne |
| 19 | Tech stack detection engine (pro scaffold-add) | #14 | M | Ne |
| 20 | Integrace: aktualizace `/onboard` v CLAUDE-agents (detekce prázdného projektu) | #9 | S | Ne |
| 21 | End-to-end test: scaffold → CLAUDE-agents /check-setup → /fix-ticket | #12 | L | Ne |
| 22 | README.md + CHANGELOG.md | #12 | S | Ano |

### Závislostní graf

```
#1 (repo) ──→ #2 (plugin meta) ──→ #3 (CLAUDE.md)
                                       │
                    ┌──────────────────┼──────────────────┐
                    ▼                  ▼                  ▼
                #4 (stack-sel.)   #5 (scaffolder)   #6 (ci-cd)   #7 (config-wr.)
                    │                  │                  │              │
                    │                  ▼                  │              │
                    │              #8 (python tmpl)       │              │
                    │                  │                  │              │
                    └──────────────────┼──────────────────┘              │
                                       ▼                                │
                                   #9 (scaffold-init) ◀────────────────┘
                                       │
                              ┌────────┼────────┐
                              ▼        ▼        ▼
                          #10 (val.)  #11 (skill)  #22 (docs)
                              │
                              ▼
                          #12 (smoke test)
                              │
                              ▼
                    ┌─────────┼──────────┐
                    ▼         ▼          ▼
               #13 (list)  #14 (add)  #15-#18 (templates)
                              │
                              ▼
                          #19 (detection)
                              │
                              ▼
                          #20 (onboard update)
                              │
                              ▼
                          #21 (e2e test)
```

### MVP scope vs. full scope

**MVP (kroky 1-12, 22):** 13 kroků, kompletní scaffold flow s jednou šablonou (Python + FastAPI)
- Uživatel může: `/scaffold init`, `/scaffold validate`
- Jedna šablona, ale stack-selector může generovat i bez šablony (ad-hoc)
- Generovaný projekt buildi, testy prochází, CLAUDE.md validní

**Full scope (kroky 13-21):** Dalších 9 kroků
- 4 další šablony (Node, Java, Go, TypeScript)
- Addon mód (`/scaffold add`)
- Tech stack detection
- `/onboard` integrace
- End-to-end test celého lifecycle

### Co lze postavit před Fází 1

Scaffold plugin je na Fázi 1 (Feature Pipeline) závislý jen pro **plnou synergii** — config-writer generuje Automation Config, který obsahuje i Feature Workflow sekci. Ale:

- **MVP scaffold funguje bez Fáze 1** — generuje Automation Config jen pro bug-fix pipeline (aktuální CLAUDE-agents v2.0)
- Po dokončení Fáze 1: update config-writer o Feature Workflow sekci (minor update)

Prakticky lze scaffold MVP začít budovat **ihned**, nezávisle na Fázi 1.

### Odhad effort

| Velikost | Popis | Počet kroků |
|----------|-------|-------------|
| S | <1 hodina | 6 kroků (#1, #2, #3, #11, #13, #22) |
| M | 1-3 hodiny | 10 kroků (#4, #5, #6, #7, #10, #14, #15, #16, #17, #19) |
| L | 3-6 hodin | 6 kroků (#8, #9, #12, #18, #20, #21) |

**Celkový odhad MVP:** ~20 hodin
**Celkový odhad full scope:** ~45 hodin

---

## 12. Rizika & edge cases

### R1: Template maintenance burden

**Riziko:** Frameworky se mění rychle. Šablona vytvořená dnes používá FastAPI 0.115 — za 6 měsíců bude 0.120 s breaking changes. Udržování N šablon s M verzemi = N*M údržba.

**Mitigace:**
- Scaffolder agent má znalost aktuálních verzí — může přepsat verze z šablony
- Šablony slouží jako **referenční struktura**, ne jako source of truth pro verze
- Minimální počet šablon v MVP (1), postupné přidávání jen na základě poptávky
- Automatický test: periodicky scaffold + validate na CI → detekuje zastaralé šablony

### R2: Scaffolding je vysoce opinionated

**Riziko:** Každý tým má jiné preference pro project layout. Šablona `python-fastapi` předpokládá `src/` layout — jiný tým preferuje flat layout. Framework choice je subjektivní — "proč ne Django?" "proč ne Flask?".

**Mitigace:**
- Stack selector respektuje explicitní specifikaci uživatele — nikdy nepřepisuje
- Šablony jsou startovací bod, ne dogma — uživatel může scaffoldovat a pak upravit
- Podpora custom šablon (vlastní adresář v `templates/`)
- Scaffolder agent může generovat ad-hoc bez šablony — je dostatečně inteligentní

### R3: Framework version pinning vs. latest

**Riziko:** Pinování verzí v šablonách = zastaralé závislosti za měsíc. Nespecifikování verzí = nedeterministické buildy ("fungovalo mi to včera").

**Mitigace:**
- Šablony pinují verze k datu vytvoření
- Scaffolder agent aktualizuje verze na základě svých znalostí (model knowledge cutoff)
- Constraint: NIKDY `latest` nebo `*` — vždy konkrétní verze
- `/scaffold validate` ověří, že build prochází s aktuálními verzemi

### R4: Generovaný CLAUDE.md se stane zastaralým

**Riziko:** Scaffold vygeneruje CLAUDE.md v den 1. Za měsíc se změní build command (refaktoring, nový framework). Automation Config v CLAUDE.md neodráží realitu → pipeline selhává.

**Mitigace:**
- Toto NENÍ problém scaffold pluginu — je to obecný problém údržby CLAUDE.md
- `/check-setup` z CLAUDE-agents detekuje nesoulad (build command selže)
- Scaffold může přidat komentář: `<!-- Vygenerováno CLAUDE-scaffold {datum}. Udržujte aktuální. -->`
- Budoucí rozšíření: `/scaffold refresh` — re-detekce a update CLAUDE.md

### R5: Testing scaffold output (meta-testing challenge)

**Riziko:** Jak testujeme, že scaffolder generuje korektní projekt? Musíme scaffold → build → test pro každou šablonu x stack kombinaci. To je O(N*M) test matice.

**Mitigace:**
- MVP: 1 šablona = 1 test
- `/scaffold validate` je vestavěný test — uživatel ho spouští, scaffold ho volá automaticky
- CI pipeline pro scaffold plugin: periodicky scaffold každou šablonu a validate
- Smoke test adresář v `tests/` (stejný pattern jako CLAUDE-agents)

### R6: Konflikty s existujícími soubory

**Riziko:** `/scaffold init` v neprázdném adresáři může přepsat důležité soubory. `/scaffold add` může kolidovat s existující konfigurací.

**Mitigace:**
- Prerekvizitní kontrola v kroku 0: varování + potvrzení pro neprázdný adresář
- `/scaffold add` NIKDY nepřepisuje bez explicitního souhlasu
- Před zápisem: check existence každého souboru, nabídni diff pokud existuje
- Git stash před scaffold v existujícím repo (ochrana uncommitted work)

### R7: CI/CD provider nekompatibilita

**Riziko:** Gitea Actions je subset GitHub Actions. Pipeline vygenerovaná pro GitHub Actions nemusí fungovat na Gitea. Specifické actions (marketplace) nemusí být dostupné.

**Mitigace:**
- CI/CD configurator zná omezení každého provideru (constraint v agent definici)
- Gitea Actions: pouze self-hosted runner kompatibilní actions
- Fallback: pokud action není dostupná → ekvivalentní shell command
- Testování: scaffold + CI run na reálném Gitea/GitHub instance

### R8: Stack selector zvolí suboptimální stack

**Riziko:** Opus model může zvolit stack, který nesedí na projekt (např. Go pro CRUD webovku kde tým zná jen Python). Rozhodnutí je nevratné — scaffold proběhne na špatném stacku.

**Mitigace:**
- Stack selector vždy zobrazí rozhodnutí a čeká na potvrzení uživatele
- Scaffold Config má defaulty — tým si nastaví preferované technologie
- Explicitní specifikace (`--lang`, `--framework`) přepisuje AI rozhodnutí
- Stack selector respektuje constraints: "musí být Python" = Python, bez diskuse

### R9: Velké scaffoldované projekty přesáhnou kontext window

**Riziko:** Generování 25+ souborů najednou může přesáhnout context window modelu. Scaffolder ztratí kontext a generuje nekonzistentní soubory.

**Mitigace:**
- Max 30 souborů per scaffold (constraint ve scaffolder agent definici)
- Generování v definovaném pořadí (package manifest → entry point → config → ...) — každý krok závisí na předchozím
- Pokud projekt vyžaduje více souborů → signál pro decomposition (neimplementovat vše najednou)

### R10: Bezpečnostní rizika ve vygenerovaném kódu

**Riziko:** Scaffolder může vygenerovat kód s bezpečnostními zranitelnostmi (hardcoded secrets v config, chybějící input validace, debug mode v production).

**Mitigace:**
- Šablony jsou review-ované — žádné secrets, žádné debug flags
- `.env.example` místo `.env` — žádné reálné credentials
- `Dockerfile` s non-root user
- Scaffolder constraint: NIKDY hardcoded secrets, VŽDY environment variables
- Budoucí rozšíření: security lint jako součást `/scaffold validate`

---

## 13. Otevřené otázky

```
Q1: Mají šablony obsahovat parametrizované .tmpl soubory, nebo má scaffolder generovat vše ad-hoc
    ze svých znalostí?
→ ROZHODNUTO: Hybridní přístup bez template engine. Šablony obsahují referenční příklady souborů
  (reference/ adresář) definující STRUKTURU (adresáře, názvy souborů, konvence). Scaffolder agent
  generuje OBSAH souborů ad-hoc na základě stack decision a svých znalostí. Žádná .tmpl extension,
  žádná {{#if}}/{{#each}} syntaxe — agent je dostatečně inteligentní. Šablony jsou "skeleton",
  agent je "flesh". Důvod: pure template approach implikuje parser který neexistuje (plugin je pure
  markdown), pure ad-hoc je nedeterministické. Referenční příklady jako inspirace jsou kompromis.
```

```
Q2: Kolik vestavěných šablon by mělo být v MVP?
→ Navrhovaná odpověď: Jedna (Python + FastAPI + PostgreSQL). Důvod: (1) Autor a primární uživatel
  (Filip Sabacky) pracuje primárně s Pythonem. (2) Jedna šablona stačí k validaci celého flow od
  stack selection po CLAUDE.md generaci. (3) Každá další šablona je O(M) údržba. (4) Stack selector
  + scaffolder umí generovat i bez šablony — šablona je optimalizace, ne nutnost. Další šablony
  přidat na základě reálné poptávky.
```

```
Q3: Jak řešit situaci, kdy uživatel chce stack, pro který neexistuje šablona?
→ Navrhovaná odpověď: Scaffolder vygeneruje projekt ad-hoc ze svých znalostí. Šablona je optimalizace
  (konzistentnější výstup, rychlejší generování), ne požadavek. Stack selector zvolí stack, scaffolder
  ho implementuje — s šablonou nebo bez ní. Výstup ze /scaffold validate ověří kvalitu. Toto je klíčový
  designový princip: šablony POMÁHAJÍ, ale NEBLOKUJÍ.
```

```
Q4: Kde by měl Scaffold Config žít — v CLAUDE.md pluginu nebo v uživatelově CLAUDE.md?
→ Navrhovaná odpověď: V uživatelově CLAUDE.md (projektová úroveň) s fallbackem na ~/.claude/CLAUDE.md
  (globální úroveň). Důvod: Scaffold Config je preference uživatele/týmu, ne property pluginu. Tým A
  preferuje Python+FastAPI, tým B Java+Spring. Globální config umožňuje "default stack pro celou
  organizaci", projektový config přepisuje pro specifický projekt. Toto kopíruje pattern z CLAUDE-agents,
  kde Automation Config žije v projektu.
```

```
Q5: Má scaffold plugin automaticky inicializovat git repo a commitnout, nebo nechat na uživateli?
→ Navrhovaná odpověď: Automaticky git init + initial commit, ALE git push jen s explicitním souhlasem.
  Důvod: Prázdný adresář bez gitu je nepoužitelný stav. Initial commit je bezpečný (nic nepřepisuje).
  Push je destruktivní (vytváří remote branch) — vyžaduje souhlas. Toto kopíruje pattern z CLAUDE-agents,
  kde publisher nikdy nepushne na main bez PR.
```

```
Q6: Jak řešit scaffold v monorepu (např. backend + frontend v jednom repo)?
→ Navrhovaná odpověď: V MVP neřešit. Scaffold předpokládá jeden projekt = jeden adresář. Pro monorepo:
  uživatel spustí scaffold v podsložce (např. `/scaffold init` v `services/backend/`). Config writer
  generuje CLAUDE.md pro danou podsložku. Budoucí rozšíření: `/scaffold init --monorepo` s explicitní
  podporou multi-service setup. Toto je komplexní problém (sdílený CI, sdílené dependencies, workspace
  management) — lepší ho odložit za MVP.
```

```
Q7: Má scaffold generovat i .env soubor s reálnými hodnotami, nebo jen .env.example?
→ Navrhovaná odpověď: Jen .env.example s ukázkovými hodnotami a komentáři. NIKDY .env s reálnými
  credentials. Důvod: (1) .env by se mohl commitnout (bezpečnostní riziko). (2) Scaffold nezná reálné
  credentials (DB hesla, API klíče). (3) .env.example dokumentuje co je potřeba nastavit. (4) .gitignore
  vždy obsahuje .env. Uživatel si .env vytvoří sám z .env.example.
```

```
Q8: Jak by měl scaffold reagovat, když build nebo test selže po scaffolding?
→ Navrhovaná odpověď: 2 pokusy na automatickou opravu (scaffolder dostane error output a pokusí se
  opravit), pak zobrazí chyby a nechá na uživateli. Neblokovat — zobrazit warning, ne error. Důvod:
  (1) Build selhání na čistém scaffoldu je bug scaffolderu, ne uživatele — ale nemůžeme zaručit 100%
  úspěšnost (verze, systémové závislosti, OS specifika). (2) 2 pokusy pokryjí triviální chyby
  (chybějící dependency, typo). (3) Blokování by frustrovalo uživatele — lepší dodat nevalidní projekt
  a nechat ho opravit, než nic.
```

```
Q9: Měl by scaffold plugin generovat i infrastrukturní kód (Terraform, Kubernetes manifesty)?
→ Navrhovaná odpověď: Ne v MVP. Infrastrukturní kód je zcela jiná doména (cloud provider specifický,
  security-sensitive, vyžaduje jiné znalosti). Docker + docker-compose je rozumná hranice pro scaffold
  — pokrývá development a jednoduchý deployment. Terraform/K8s manifesty by vyžadovaly: (1) cloud
  provider selection agent, (2) znalost IAM/networking/security, (3) state management. To je scope
  pro samostatný plugin (CLAUDE-infra?), ne pro scaffold.
```

```
Q10: Jak by měl scaffold plugin spolupracovat s existujícími scaffolding nástroji (create-react-app,
     cookiecutter, Spring Initializr)?
→ Navrhovaná odpověď: Scaffold plugin je ALTERNATIVA, ne wrapper nad existujícími nástroji. Důvod:
  (1) Wrapper by vyžadoval instalaci externích nástrojů (dependency, kterou nechceme). (2) Každý
  nástroj má jiný interface, jiné konvence — abstrakce by byla leaky. (3) AI-driven scaffolding je
  flexibilnější (jeden agent zvládne libovolný stack, ne jen ten, co nástroj podporuje). (4) Existující
  nástroje negenerují CLAUDE.md — to je hlavní přidaná hodnota scaffold pluginu. Uživatel, který
  preferuje cookiecutter, ho může použít a pak spustit /scaffold add claude-md.
```

```
Q11: Má scaffold plugin mít vlastní routing skill, nebo rozšířit bug-workflow skill v CLAUDE-agents?
→ Navrhovaná odpověď: Vlastní routing skill (scaffold-workflow). Důvod: (1) Pluginy jsou nezávislé —
  scaffold skill nemůže žít v CLAUDE-agents repozitáři. (2) Intenty jsou disjunktní: "oprav bug" vs.
  "vytvoř projekt" — žádný overlap. (3) Vlastní skill = vlastní namespace = žádné konflikty. (4) Uživatel
  má dva skills: bug-workflow pro pipeline operace, scaffold-workflow pro scaffolding. Claude Code je
  dostatečně inteligentní, aby vybral správný skill na základě kontextu.
```

```
Q12: Jaká je strategie pro verzování scaffold pluginu ve vztahu k CLAUDE-agents?
→ Navrhovaná odpověď: Zcela nezávislé verzování. Scaffold plugin startuje na v1.0.0 a má vlastní
  semver. Důvod: (1) Jiný lifecycle — scaffold se mění řídce, CLAUDE-agents se mění často. (2) Žádná
  runtime dependency — verze jednoho pluginu nemá vliv na druhý. (3) Kompatibilita je garantována přes
  Automation Config contract — dokud scaffold generuje validní Automation Config (dle Config Contract
  z CLAUDE-agents CLAUDE.md), pluginy jsou kompatibilní. (4) Config Contract z CLAUDE-agents je
  verzovaný (MAJOR = breaking change) — scaffold config-writer je vázaný na major verzi CLAUDE-agents
  Config Contract.
```

```
Q13: Jak řešit situaci, kdy CLAUDE-agents změní Config Contract (nová povinná sekce) a scaffold
     plugin ji ještě negeneruje?
→ Navrhovaná odpověď: (1) CLAUDE-agents MAJOR verze (breaking change v Config Contract) je vzácná a
  plánovaná dopředu. (2) Scaffold plugin má v dokumentaci referenci na CLAUDE-agents Config Contract
  verzi, na kterou je kompatibilní. (3) Při MAJOR update CLAUDE-agents: update config-writer v scaffold
  pluginu, release novou verzi. (4) Mezitím: /check-setup detekuje chybějící povinnou sekci, uživatel
  doplní ručně nebo spustí /scaffold add claude-md (re-detekce + re-generace). (5) Toto je přijatelné
  riziko — MAJOR update CLAUDE-agents se stává jednou za desítky měsíců.
```

---

## Příloha A: Routing Skill — scaffold-workflow

```markdown
---
name: scaffold-workflow
description: Use when the user wants to create a new project, scaffold code, or generate CLAUDE.md configuration
---

You are a routing assistant for the CLAUDE-scaffold plugin. Your job is to recognize user intent from natural language and invoke the correct command.

## Intent Mapping

| User Intent | Command | Arguments | Destructive? |
|-------------|---------|-----------|-------------|
| Create new project / scaffold | `CLAUDE-scaffold:scaffold-init` | Project description (optional) | Yes |
| List available templates | `CLAUDE-scaffold:scaffold-list` | None | No |
| Add component to existing project | `CLAUDE-scaffold:scaffold-add` | Component name | Yes |
| Validate scaffolded project | `CLAUDE-scaffold:scaffold-validate` | None | No |
| What can you do? / Help / Capabilities | (none — respond inline) | None | No |

## Process

1. Read the user's message and identify their intent from the table above
2. Extract arguments (project description, component name) from the user's message
3. **If the operation is NOT destructive** (scaffold-list, scaffold-validate): invoke the command immediately
4. **If the operation IS destructive** (scaffold-init, scaffold-add):
   - Summarize what will happen: which command will run, with what arguments, and what side effects to expect
   - Ask the user for confirmation before proceeding
   - Only after confirmation: invoke the command
5. If you cannot determine the intent or extract required arguments, ask the user to clarify

## Constraints

- NEVER invoke a destructive command without user confirmation
- NEVER execute scaffold logic yourself — always delegate to the appropriate command
- If the user's request doesn't match any command, say so and list available commands
```

---

## Příloha B: Kompletní ukázka vygenerovaného CLAUDE.md

Ukázka výstupu config-writer pro scaffold `Python + FastAPI + PostgreSQL`:

```markdown
# CLAUDE.md

Tento soubor obsahuje instrukce pro Claude Code.

## O projektu

REST API pro správu úkolů. Python 3.12 + FastAPI + PostgreSQL.

## Struktura repozitáře

- `src/task_manager/` — hlavní aplikační kód (FastAPI routers, models, config)
- `tests/` — unit testy (pytest + httpx)
- `migrations/` — Alembic databázové migrace
- `Dockerfile` — multi-stage Docker build
- `docker-compose.yml` — app + PostgreSQL

## Automation Config

### Issue Tracker

| Klíč | Hodnota |
|------|---------|
| Type | youtrack |
| Instance | <your-instance.youtrack.cloud> <!-- SCAFFOLD: vyplň ručně --> |
| Project | TASK |
| Bug query | project: TASK State: Open Type: Bug |
| State transitions | In Progress, Blocked, For Review |
| On start set | State: In Progress |

### Source Control

| Klíč | Hodnota |
|------|---------|
| Remote | <owner/task-manager> <!-- SCAFFOLD: vyplň ručně --> |
| Base branch | main |
| Branch naming | TASK-{issue}-{short-description} |

### PR Rules

| Klíč | Hodnota |
|------|---------|
| Labels | ForReview |

### PR Description Template

#### Summary
Brief description of changes.

#### Root Cause
What caused the issue and why.

#### Changes
- File 1: description
- File 2: description

#### Testing
- [ ] Unit tests pass
- [ ] Manual testing done

#### Issue
Link: {issue_url}

### Build & Test

| Klíč | Hodnota |
|------|---------|
| Build | pip install -e ".[test]" |
| Test | pytest --cov=src |

### Retry Limits

| Klíč | Hodnota |
|------|---------|
| Fixer iterations | 5 |
| Test attempts | 3 |
| Build retries | 3 |

### Error Handling

| Klíč | Hodnota |
|------|---------|
| On block | comment |
| Max blocked per run | unlimited |
```

---

## Příloha C: Srovnání s existujícími nástroji

| Dimenze | CLAUDE-scaffold | cookiecutter | create-react-app | Spring Initializr |
|---------|----------------|--------------|------------------|-------------------|
| **AI-driven stack selection** | Ano (sonnet) | Ne | Ne | Ne |
| **CI/CD generace** | Ano (multi-provider) | Ne | Ne | Ne |
| **CLAUDE.md + Automation Config** | Ano (hlavní hodnota) | Ne | Ne | Ne |
| **Interaktivní vs. batch** | Oba režimy | Template vars | CLI flags | Web UI |
| **Jazyková podpora** | Libovolný (AI generuje) | Libovolný (template) | Jen React | Jen Java/Kotlin |
| **Dependency management** | Žádné (pure markdown) | Python (pip) | Node.js (npm) | Java (Maven/Gradle) |
| **Customizace** | Custom templates + ad-hoc | Custom templates | Eject | Starters |
| **Post-scaffold validace** | Ano (/scaffold validate) | Ne | Ne | Ne |

Klíčový differentiator: CLAUDE-scaffold je jediný nástroj, který (1) AI-driven volí stack, (2) generuje CI/CD, a (3) produkuje konfiguraci pro další automatizační plugin (CLAUDE-agents). Ostatní nástroje generují project structure — CLAUDE-scaffold generuje **celý development environment**.

---

## Review Status

**Review:** 2026-02-27 | **Stav:** APPROVED
**Všechny [REVIEW Q] rozhodnuty:** Q1 (scaffold do temp dir — Varianta B), Q2 (config-writer haiku + checklist — Varianta C).
