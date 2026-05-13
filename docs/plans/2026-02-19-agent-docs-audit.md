# Design: Audit agentů vs projektová dokumentace

**Datum:** 2026-02-19 (validováno 2026-02-24)
**Status:** APPROVED

## Kontext

Ověření, že všech 7 agentů správně odkazuje na Automation Config a používá správnou terminologii, sekce a klíče.

## Vzorový agent: publisher

Publisher je gold standard — explicitně jmenuje "Automation Config" 5x a specifikuje konkrétní sekce (Source Control, PR Rules, Issue Tracker).

## Princip: Agents should be self-documenting

Každý agent, co čte config, musí explicitně říkat "from Automation Config (sekce XY)", protože:
1. Agent může být zavolán přímo (ne jen přes command)
2. Slouží jako dokumentace — nový přispěvatel vidí co agent potřebuje
3. Publisher je dobrý vzor

## Kdo potřebuje config

| Agent | Potřebuje config? | Jakou sekci? |
|-------|-------------------|--------------|
| triage-analyst | Ano | Issue Tracker (stavy, Blocked stav) |
| code-analyst | **Ne** | Jen čte kód |
| fixer | Ano | Build & Test (build command) |
| reviewer | **Ne** | Jen čte kód |
| test-engineer | Ano | Build & Test (test command) |
| e2e-test-engineer | Ano | E2E Test (framework, command) |
| publisher | Ano ✅ | Source Control, PR Rules, Issue Tracker |

## Nálezy a řešení

### Agenti

| # | Agent | Problém | Řešení |
|---|-------|---------|--------|
| H1 | e2e-test-engineer | Hardcoduje Playwright | Framework-agnostický, číst z Automation Config (E2E Test) |
| H2 | 5 agentů | Nepoužívají "Automation Config" | Standardizovat na "from Automation Config (sekce)" |
| L1 | fixer | "build command from project CLAUDE.md" | → "from Automation Config (Build & Test)" |
| L2 | test-engineer | Imprecizní + .NET bias | → "from Automation Config (Build & Test)" bez příkladů |
| L3 | e2e-test-engineer | Imprecizní + .NET bias | → "from Automation Config (E2E Test)" bez příkladů |

### Commands

| # | Command | Problém | Řešení |
|---|---------|---------|--------|
| M1 | analyze-bug, fix-bugs | Description hardcoduje "YouTrack" | → "issue tracker" |
| M2 | create-pr | Description hardcoduje "Gitea" | → "source control" |
| M3 | publish | "YT" shorthand, "For Review" bez config | → "issue tracker", reference na config |
| M4 | fix-bugs | `batch_size` není v Config Contract | Přidat do Config Contract (Worktrees) |
| M5 | triage-analyst | Nespecifikuje stav "Blocked" | Přidat referenci na Issue Tracker → State transitions |
| L4 | fix-bugs, fix-ticket | Enumerují "In Progress, Assignee, Estimation, Sprint" | → "Set fields from Automation Config (Issue Tracker → On start set)" |

### MCP allowed-tools

Všechny commands s MCP: `mcp__youtrack__*, mcp__gitea__*` → `mcp__*`

Důvody:
- Uživatel spustil command = dal souhlas s pipeline
- MCP servery mají vlastní autorizaci
- Jediný skutečně generický přístup
- Výčet konkrétních MCP serverů je vždy neúplný

### Config Contract

Přidat `batch_size` do sekce Worktrees v CLAUDE.md:
```
| Worktrees | Batch size, base path, cleanup rules |
```

## Dopad

Pro současný single-consumer setup (BIFITO) jsou změny kosmetické. Stávají se reálným problémem při onboardingu projektu s jiným toolingem (Jira + GitHub + Python + Cypress).
