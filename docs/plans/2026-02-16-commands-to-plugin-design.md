# Design: Přesun commands do pluginu

**Datum:** 2026-02-16
**Status:** Schváleno
**Kontext:** Commands jsou v BIFITO `.claude/commands/`, ale jsou generické — patří do pluginu.

## Problém

Commands (analyze-bug, fix-ticket, fix-bugs, create-pr, publish) jsou uloženy v BIFITO repozitáři (`C:\gitea_BIFITO\.claude\commands\`), přestože neobsahují nic BIFITO-specifického. Každý command říká jen "čti Automation Config z CLAUDE.md" — veškerá konfigurace je v projektu.

Důsledek: Pro CEOS-CMD by bylo nutné commands zkopírovat. To je duplicita.

## Rozhodnutí

**2 vrstvy: Commands + Agents v pluginu, Config v projektu.**

Zvažovaná alternativa (3 vrstvy: Commands + Skills + Agents jako superpowers) zamítnuta — skills vrstva přidává indirection bez přínosu. Orchestrace = command, není důvod ji oddělovat.

## Architektura

```
┌─────────────────────────────────────────┐
│        CLAUDE-agents plugin             │
│        (sdílený, nainstalovaný)         │
│                                         │
│  commands/          agents/             │
│  ├─ analyze-bug     ├─ triage-analyst   │
│  ├─ fix-ticket      ├─ code-analyst     │
│  ├─ fix-bugs        ├─ fixer            │
│  ├─ create-pr       ├─ reviewer         │
│  └─ publish         ├─ test-engineer    │
│                     ├─ e2e-test-engineer │
│                     └─ publisher        │
└──────────────┬──────────────────────────┘
               │ čte config
               ▼
┌─────────────────────────────────────────┐
│        Projekt CLAUDE.md                │
│        (per-project konfigurace)        │
│                                         │
│  ## Automation Config                   │
│  ├─ Issue Tracker (YT instance, query)  │
│  ├─ Source Control (remote, branching)  │
│  ├─ PR Rules (labels, template)      │
│  ├─ Build & Test (příkazy)              │
│  ├─ Worktrees & Parallelization         │
│  └─ Error Handling                      │
│                                         │
│  .mcp.json (tokeny, MCP servery)        │
└─────────────────────────────────────────┘
```

## Config Contract

Každý projekt musí mít v CLAUDE.md sekci `## Automation Config` s těmito podsekcemi:

### Povinné

| Podsekce | Klíče |
|----------|-------|
| Issue Tracker | Instance, Project, Bug query, State transitions, On start set |
| Source Control | Remote (owner/repo), Base branch, Branch naming pattern |
| PR Rules | Labels (seznam), PR description template |
| Build & Test | Build command, Test command |

### Volitelné

| Podsekce | Klíče |
|----------|-------|
| Worktrees | Batch size, Worktree base, Cleanup pravidla |
| Error Handling | Rollback strategie |
| E2E Test | E2E command, Runsettings |
| Extra labels | Podmíněné labels (např. SSIS) |

**Princip:** Commands neobsahují žádné if/else per projekt. Čtou config a aplikují co tam najdou.

## Migrace

1. Přesunout 5 commands z `C:\gitea_BIFITO\.claude\commands\` do `C:\gitea_CLAUDE-agents\commands\`
2. Smazat `.claude/commands/` v BIFITO
3. Reinstalovat plugin pro refresh cache (`/plugin install`)
4. Automation Config v BIFITO CLAUDE.md — beze změny
5. Otestovat: `/analyze-bug BIFITO-XXXX`

## Onboarding nového projektu

1. Plugin je globálně nainstalovaný → commands dostupné všude
2. Přidat `.mcp.json` s tokeny projektu
3. Přidat `## Automation Config` do CLAUDE.md s hodnotami projektu
4. Hotovo — `/fix-bugs 5` funguje
