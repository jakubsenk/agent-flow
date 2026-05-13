# Design: Skills vs Commands

**Datum:** 2026-02-19 (validováno 2026-02-24)
**Status:** APPROVED

## Kontext

Plugin CLAUDE-agents má 5 commands v `commands/` a 7 agents v `agents/`. Skills jsou novější koncept v plugin systému Claude Code. Otázka: měli bychom migrovat orchestraci z commands na skills?

## Technické rozdíly

| Aspekt | Commands | Skills |
|--------|----------|--------|
| Formát | `commands/name.md` (flat file) | `skills/name/SKILL.md` (adresář) |
| Invokace | Uživatel: `/plugin:command` | Model: automaticky dle kontextu, nebo `Skill("name")` |
| Argumenty | `$ARGUMENTS` placeholder | Žádný mechanismus |
| Tool pre-approval | `allowed-tools` v frontmatteru | Není k dispozici |
| Model override | `model` v frontmatteru | Není k dispozici |
| Podpůrné soubory | Ne (flat file) | Ano (celý adresář) |
| Auto-discovery | Ne (uživatel musí zadat) | Ano (model matchuje dle description) |

## Dva režimy použití

| Režim | Popis | Mechanismus |
|-------|-------|-------------|
| **Plně autonomní** | `/fix-bugs 5` — pipeline jede od YT po PR | Commands (explicitní, deterministic) |
| **Poloautonomní** | "Oprav mi bug PROJ-123" — přirozený jazyk | Skills (auto-discovery) |

## Závěr: Commands + Routing Skill

### Commands zůstávají (5 důvodů)

1. **`$ARGUMENTS` jsou nezbytné** — 3/5 commands berou issue ID nebo počet bugů. Skills tento mechanismus nemají.
2. **`allowed-tools` je kritické** — commands používají MCP patterns. Bez pre-approval by každá operace vyžadovala ruční potvrzení.
3. **`model` override** — pipeline závisí na tom, že triage běží na sonnet, fixer na opus, publisher na haiku. Skills toto neumí.
4. **Explicitní invokace pro plnou automatizaci** — `/fix-bugs 5` musí jet bez interakce.
5. **Orchestrační logika patří do commands** — commands definují WHAT (pořadí agentů), agents definují HOW.

### Přidáváme routing skill (auto-discovery)

Nový skill `bug-workflow` řeší poloautonomní režim:
- Auto-discovery — uživatel píše přirozeně, model rozpozná záměr
- Extrahuje argumenty z konverzace (issue ID, počet bugů)
- Invokuje správný command přes `Skill(skill='CLAUDE-agents:<command>', args='...')`
- Žádná duplikace orchestrační logiky — skill jen routuje

### Safety guard

| Operace | Destruktivní? | Chování skillu |
|---------|---------------|----------------|
| analyze-bug | Ne (read-only) | Spustit rovnou |
| fix-ticket | Ano | Potvrdit před spuštěním |
| fix-bugs | Ano | Potvrdit před spuštěním |
| create-pr | Ano | Potvrdit před spuštěním |
| publish | Ano | Potvrdit před spuštěním |

### Kdy by další skills dávaly smysl

Pokud bychom přidali metodologické znalosti (best practices pro triage, review patterns, error handling strategie) — ty by byly dobrými kandidáty na skills. Není urgentní.
