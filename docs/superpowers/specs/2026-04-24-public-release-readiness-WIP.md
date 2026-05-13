# Public Release Readiness — Brainstorm

> **Status:** sub-projekt C UZAVŘEN (2026-04-25), čeká exekuce v7.0.0
> **Started:** 2026-04-24
> **Last touched:** 2026-04-25
> **Next session:** writing-plans pro v7.0.0 nebo brainstorm sub-projektu A

---

## Decided

### Epic decomposition (rozhodnuto 2026-04-24)
7 sub-projektů, pořadí C → A → B → D → E → F → G. Plný popis v `docs/plans/roadmap.md` → "Public Release Readiness".

### Release allocation (FINÁLNÍ, rozhodnuto 2026-04-25)

| Release | Theme | Sub-projekty |
|---|---|---|
| **v7.0.0** | Cleanup + naming + auto-detect publish (breaking) | C |
| **v8.0.0** | Architecture rework (breaking) | A + B |
| **v9.0.0** | Public launch (UI vrstva + polish) | D + E + F + G |

**Důvod přečíslování v7→v9:** sub-projekt C obsahuje breaking changes, per CLAUDE.md versioning policy = MAJOR. User rozhodnutí: dnes málo userů, později mnohem víc — tlačit rychle, nedělat semver-conservative scope split.

### Forge usage policy (rozhodnuto 2026-04-25)
- **Brainstorm vždy s userem** — strategická rozhodnutí se nedelegují na forge
- **forge na exekuci** pouze pro build-heavy sub-projekty: D (scanner), E (web wizard), F (interactive dashboard)
- **Bez forge** pro: C (cleanup, no build), G (polish, checklist)
- **A, B** — rozhodne se po jejich brainstormu

### Cíl projektu (rozhodnuto 2026-04-25)
**Adopce + intuice + variabilita.** Tento cíl řídí všechna design rozhodnutí napříč A-G.

### Sub-projekt C — výsledek (uzavřeno 2026-04-25)

**Cesta:**
1. Začalo jako "YAGNI sweep" (delete-driven)
2. Reframe na "Configuration Tiers / Progressive Disclosure" (preserve + tier)
3. User požádal o 4-reviewer audit (Adoption + Power-user + Maintainer + Public-Release) → judge konsolidace v `docs/superpowers/specs/2026-04-25-config-skills-agents-audit.md`
4. **Audit zahozen jako rozhodovací nástroj** — reviewers neměli kontext "nedávno dodaná feature čekající na adoption", označili strategické features (dashboard, discuss, sprint-plan, prioritize, create-backlog, Module Docs, Sprint Planning) chybně jako DELETE
5. Per-feature manuální revize v repu vyloučila všechny chybné DELETE verdikty
6. Reviewer návrh "merge 3 dvojic skillů" (init↔onboard, create-pr↔publish, scaffold-validate↔check-setup) ověřen čtením všech 6 SKILL.md → 2 ze 3 funkčně oddělené (NEMERGOVAT), 1 (publish) lze mergem nahradit auto-detectem
7. Diskuse naming kolizí s Claude Code builtins → identifikováno: `/status` a `/init` kolidují s built-in slash commands
8. **Finální scope = 4 akce + 2 doc fixes**

### v7.0.0 FINÁLNÍ scope

| # | Akce | Soubory dotčené | Breaking? |
|---|---|---|---|
| 1 | Smazat `Extra labels` config sekci | `docs/reference/automation-config.md` (sekce + Quick reference table), `agents/publisher.md:69`, `skills/fix-ticket/`, `skills/fix-bugs/`, `skills/implement-feature/`, `examples/configs/*.md`, `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` | Ano (lehce) |
| 2 | Opravit doc `Pause Limits` mapping | `docs/reference/automation-config.md:40` (`/autopilot` → `/fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot, /resume-ticket`) | Ne (doc fix) |
| 3 | Rename `/ceos-agents:status` → `/ceos-agents:pipeline-status` | `skills/status/` → `skills/pipeline-status/`, README, docs/reference/skills.md, CLAUDE.md, workflow-router intent table, všechny zmínky v core/skills | Ano |
| 4 | Rename `/ceos-agents:init` → `/ceos-agents:setup-mcp` | `skills/init/` → `skills/setup-mcp/`, README, docs/reference/skills.md, docs/guides/installation.md, workflow-router intent table, všechny zmínky | Ano |
| 5 | Auto-detect tracker v `/publish` + smazat `/create-pr` skill | `skills/publish/SKILL.md` (rewrite Steps 1-3), smazat `skills/create-pr/`, update `agents/publisher.md`, README, docs/reference/skills.md, workflow-router intent table | Ano |
| 6 | README + docs varování o kolizích krátkých forem s builtins | `README.md`, `docs/guides/installation.md` | Ne |

**Counts po v7.0.0:** 29 → **28 skills** (−`/create-pr`), 19 → **18 config sekcí** (−`Extra labels`), 21 → **21 agentů** (no change). Renamy nesnižují count.

### `/publish` auto-detect logic (rozhodnuto 2026-04-25)

```
1. git branch --show-current → current_branch
2. Z Automation Config přečti `Source Control → Branch naming` pattern
3. Match branch_name proti patternu, extrahuj issue_id

Pokud issue_id NEnalezen:
  → "PR-only mode": commit + push + create PR + display URL

Pokud issue_id nalezen:
  4. MCP call: tracker.getIssue(issue_id)
  
  Pokud issue existuje:
    → "Full publish": publisher agent (haiku)
       → PR + state transition (For Review) + tracker comment + pr-created webhook
  
  Pokud issue neexistuje (404):
    → "PR-only mode + WARN":
       "Branch obsahuje vzor issue ID '{issue_id}' ale ticket nenalezen v trackeru.
        Vytvářím PR bez tracker update."
  
  Pokud tracker nedostupný (5xx/timeout/MCP error):
    → FAIL:
       "Tracker nedostupný — nelze ověřit issue '{issue_id}'.
        Zkus znovu nebo udělej manuální commit + push + PR."
```

**Klíčové vlastnosti:**
- Žádný config key, žádný `--no-tracker` flag
- Default behavior je intuitivní: skill udělá co je v dané situaci správné
- Tracker down = fail (user vidí, že tracker je problém, není tichý fallback)
- Issue 404 = soft fallback s warningem (tracker je OK, jen ID je špatně)

### Migration guide (do CHANGELOG.md při exekuci)

```markdown
## Migration from v6.10.x to v7.0.0

- `Extra labels` config sekce smazána → přesuň labely do `PR Rules → Labels`
- `/ceos-agents:status` → `/ceos-agents:pipeline-status` (krátká forma `/status` kolidovala s Claude Code builtin)
- `/ceos-agents:init` → `/ceos-agents:setup-mcp` (krátká forma `/init` kolidovala s Claude Code builtin)
- `/create-pr` smazán → použij `/publish` (auto-detect: pokud branch má issue ID a ticket existuje, dělá tracker update; jinak jen PR)
- `Pause Limits` doc opraven — sekce platí pro všechny pipeline skills, ne jen `/autopilot` (žádná funkční změna, jen doc)
```

---

## Sub-projekty A-G (čekají na vlastní brainstorm)

Pro každý vznikne `docs/superpowers/specs/YYYY-MM-DD-<sub>-design.md` po dokončení v7.0.0.

- A — Agent shape rework (generic+overlay vs per-project vs meta-gen z filip-superpowers)
- B — Human-in-the-loop pipelines (configurable approval gates, per-step diskuze)
- D — Project scanner → agent suggester
- E — Web-based onboarding wizard
- F — Interactive dashboard (statický → ovládání pipeline)
- G — Public release polish (canonical URL, SECURITY contact, README, announcement)

---

## Resume pokyn pro příští session

**v7.0.0 ready for execution.** Příští session:
1. Načti tento soubor + `docs/plans/roadmap.md` (sekce "Public Release Readiness")
2. Volba A: spustit writing-plans skill na v7.0.0 scope (6 akcí výše) → executing-plans
3. Volba B: začít brainstorm sub-projektu A (Agent shape rework) — `docs/superpowers/specs/YYYY-MM-DD-A-agent-shape-design.md`

Audit dokument `docs/superpowers/specs/2026-04-25-config-skills-agents-audit.md` je zachován jako historická reference, není to akční zdroj.
