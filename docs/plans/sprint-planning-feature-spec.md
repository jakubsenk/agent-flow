# Sprint Planning & Backlog Management — Feature Specification

> **Status:** Zadání pro forge pipeline
> **Verze pluginu:** v6.4.6 → v6.5.0 (MINOR)
> **Autor:** Filip Sabacky + Claude (collaborative design session 2026-04-13)

---

## 1. Problém

Tým začínající s autonomním AI vývojem má specifikaci (spec/ folder nebo markdown soubor), ale neví jak:
1. Převést spec na kartičky v issue trackeru (backlog)
2. Naplánovat co dělat v prvním sprintu (prioritizace + kapacita)
3. Iterovat — po sprintu upravit spec a naplánovat další

Dnes musí ručně zakládat issues, ručně vybírat co dělat, ručně spouštět `/implement-feature` na každý issue. Chybí orchestrační vrstva mezi spec a implementací.

## 2. Řešení — 3 oddělené skills

Tři nové skills, každý s jasnou zodpovědností. Oddělené, protože:
- Composability — každý se dá použít samostatně
- Učení — tým postupně pochopí co každý krok dělá
- Flexibilita — tým nemusí použít celý flow
- Existující vzor — ceos-agents už takhle funguje (prioritize → fix-bugs → publish)

### 2.1 `/create-backlog` — Spec → Epics v trackeru

**Vstup:** Spec soubor (markdown), spec/ folder (scaffold v2 formát), nebo více souborů.

**Výstup:** Epic kartičky v issue trackeru.

**Chování:**
- Přečte spec, extrahuje featury/epics
- Pro každý epic vytvoří kartičku v trackeru v JEDNOTNÉM FORMÁTU (viz sekce 4)
- Semi-autonomní: ukáže náhled epiců, člověk potvrdí před vytvořením
- Volitelný `--decompose` flag: po vytvoření epiců spustí na každý architect → vytvoří sub-issues (tasky)
- Volitelný `--update` flag: aktualizuje existující epics ze změněné spec (ne duplikuje)

**Agent:** `backlog-creator` (sonnet, read-only) — čte spec, produkuje strukturovaný seznam epiců. Skill řeší tracker zápisy.

**Integrace se scaffold:** Scaffold Step 4e dnes vytváří issues z architect task tree. Refaktorovat tak, aby volal `backlog-creator` agenta. Jeden agent, dvě místa použití.

### 2.2 `/sprint-plan` — Issues → Sprint plán

**Vstup:** Existující issues v trackeru (epics nebo tasky).

**Výstup:** Sprint plán — které issues jdou do sprintu, přiřazení v trackeru.

**Chování:**
- Stáhne otevřené issues z trackeru
- Spustí priority-engine (opus, existující) → prioritizace s P0/P1/P2 tiery
- Spustí sprint-planner (sonnet, nový) → kapacitní omezení, výběr do sprintu
- Semi-autonomní: 3 lidské gates (viz sekce 5)
- Přiřadí vybrané issues do sprintu v trackeru (sprint_assign přes MCP → Bash fallback → skip)
- Volitelný `--all` flag: naplánuje VŠECHNY sprinty (release plan), ne jen další
- Volitelný `--apply` flag: po naplánování spustí `/implement-feature` na vybrané issues
- Volitelný `--dry-run` flag: jen zobrazí plán, nic nezapisuje

**Agent:** `sprint-planner` (sonnet, read-only) — přijme prioritizovaný seznam + config, vrátí sprint plán. NIKDY neřadí znovu (priority-engine ranking je autoritativní). Skill řeší tracker zápisy a execution dispatch.

### 2.3 `/implement-feature --decompose-only` — Nový flag

**Chování:** Existující `/implement-feature` pipeline se zastaví po architect decomposition — vytvoří sub-issues v trackeru, ale NESPUSTÍ fixer/reviewer/test-engineer.

**Proč:** Tým chce vidět rozpad epicu na tasky PŘED tím, než se pustí do implementace. Dnes je decomposition "zamčená" uvnitř implement-feature pipeline.

## 3. Konkrétní flow pro cílového uživatele

### Den 1: Mám spec, chci začít

```
/create-backlog spec/
  → Načte 4 epics ze spec/epics/*.md
  → Ukáže tabulku: název, AC count, velikost, dependencies
  → "Založit do trackeru? [Y/n]"
  → Založí 4 epic kartičky

/sprint-plan
  → Priority-engine ohodnotí 4 epics
  → Sprint-planner vybere 3 epics do Sprint 1 (kapacita 40 SP)
  → "Pokračovat s tímto sprintem? [Y/n]"
  → Přiřadí 3 issues do Sprint 2026-W16

/implement-feature AUTH-1
  → Standardní pipeline: spec-analyst → architect → fixer → reviewer → test → PR
```

### Po sprint 1: Plánuji sprint 2

```
/sprint-plan
  → Vidí: AUTH-1 done, AUTH-4 done, AUTH-2 rozpracován, AUTH-3 backlog
  → Naplánuje Sprint 2 z otevřených issues
```

### Spec se změnila

```
# Upravím spec/epics/notifications.md
/create-backlog spec/epics/notifications.md --update
  → Aktualizuje existující kartičku AUTH-4 v trackeru
```

### Chci vidět celý rozpad

```
/create-backlog spec/ --decompose
  → Založí 4 epics + 14 sub-tasků (architect na každý epic)
```

### Chci naplánovat celý release

```
/sprint-plan --all
  → Release plan: Sprint 1 (epics 1,4,2), Sprint 2 (epic 3)
  → Celkem 2 sprinty, ~4 týdny
```

## 4. Jednotný formát epic kartičky

Výchozí šablona pro každý epic v trackeru:

```markdown
## {Epic Title}

**Type:** feature
**Size:** M (3 SP)
**Dependencies:** AUTH-1

### Scope
{Co se má udělat — 2-3 věty}

### Acceptance Criteria
1. {Testovatelné kritérium}
2. {Testovatelné kritérium}
3. {Testovatelné kritérium}

### Verification
- Unit: {co testovat unit testy}
- Integration: {co testovat integračně}
- E2E: {co testovat end-to-end}
```

**Override:** Přes existující Agent Overrides pattern (`customization/backlog-creator.md`) nebo config klíč `Epic template` s cestou k vlastní šabloně.

Verification sekce se automaticky odvozuje z:
- `spec/verification.md` (pokud existuje)
- AC (každé AC implikuje test)
- Build & Test config

## 5. Sprint-plan: 3 lidské gates

| Gate | Kdy | `--yolo` |
|------|------|----------|
| Gate 1: Capacity confirmation | Po sprint-planner výstupu | Auto-approve |
| Gate 2: Unmapped AC warning | Když epic nemá AC pokryté | **BLOCK** (i v --yolo) |
| Gate 3: Final "Start sprint?" | Před tracker writes / execution | Auto-approve |

`--yolo` NEIMPLIKUJE `--apply`. Potřeba explicitní `--yolo --apply` pro plně automatizované spuštění.

`--dry-run` zobrazí Gate 3 plán a skončí. Žádné tracker zápisy.

## 6. Tracker sprint assignment

**MVP scope: pouze `sprint_assign`** — přiřazení issues do existujícího sprintu/milestone/cycle. Sprint creation a querying odloženy.

Vždy NON-BLOCKING — pokud assign selže, loguje warning a pokračuje. Plán je hodnotný i bez tracker metadat.

3-tier fallback per tracker:

| Tracker | Sprint concept | MCP (Tier 1) | Bash+REST (Tier 2) | Skip (Tier 3) |
|---------|---------------|-------------|-------------------|---------------|
| YouTrack | Sprint | `update_issue(Sprint: name)` | curl REST | skip+warn |
| Jira | Sprint (Scrum only) | `add_issues_to_sprint(sprintId, issues)` | curl REST | skip+warn |
| Linear | Cycle | `update_issue(cycleId: uuid)` | GraphQL mutation | skip+warn |
| GitHub | Milestone | `update_issue(milestone: number)` | curl REST | skip+warn |
| Gitea | Milestone | unverified → Tier 2 | curl REST | skip+warn |
| Redmine | Version (vždy, nikdy Agile Plugin) | `update_issue(fixed_version_id: id)` | curl REST | skip+warn |

Pre-conditions:
- Jira: detekce Scrum vs Kanban board. Kanban → skip sprint ops, plán se vygeneruje stejně.
- Redmine: vždy Version. Žádná Agile Plugin auto-detekce.

## 7. Config contract

Nová OPTIONAL sekce `### Sprint Planning` (7 klíčů pro MVP):

| Key | Default | Description |
|-----|---------|-------------|
| Sprint duration | 2 weeks | 1 week / 2 weeks / 3 weeks / 4 weeks |
| Capacity unit | story-points | story-points / hours |
| Team capacity | (none) | Celková kapacita týmu za sprint |
| Velocity target | (none) | Historicky dodaný objem za sprint |
| Sprint field | (tracker-dependent) | Název pole v trackeru pro sprint assignment |
| Mode | suggest | suggest (read-only) / apply (zapisuje + spouští) |
| Max issues | 20 | Maximum issues k uvážení (1-50) |

Volitelný klíč pro epic šablonu:

| Key | Default | Description |
|-----|---------|-------------|
| Epic template | (none) | Cesta k custom šabloně pro epic kartičky |

Sekce NENÍ povinná. Pokud chybí → sprint-plan se chová jako read-only doporučení bez tracker writes.

## 8. Nové komponenty — souhrn

| Komponenta | Typ | Model | Nová? |
|-----------|-----|-------|-------|
| `backlog-creator` | agent (read-only) | sonnet | **NOVÝ** |
| `sprint-planner` | agent (read-only) | sonnet | **NOVÝ** |
| `/create-backlog` | skill | — | **NOVÝ** |
| `/sprint-plan` | skill | — | **NOVÝ** |
| `--decompose-only` flag | flag na implement-feature | — | **NOVÝ** |
| `--decompose` flag | flag na create-backlog | — | **NOVÝ** |
| scaffold Step 4e | refactor | — | ZMĚNA |
| workflow-router | nové intent rows | — | ZMĚNA |
| CLAUDE.md | config section + counts | — | ZMĚNA |
| docs/reference/ | dokumentace | — | ZMĚNA |

**Verze: v6.5.0 (MINOR)** — nové optional config sekce, nové agenty/skills, žádné breaking changes.

## 9. Kapacitní model a velocity

Effort-to-unit mapping (fixed):
```
EFFORT_TO_POINTS = {1: 1, 2: 2, 3: 3, 4: 5, 5: 8}  (Fibonacci)
EFFORT_TO_HOURS  = {1: 0.5, 2: 1, 3: 2, 4: 4, 5: 8}

COMPLEXITY_TO_POINTS = {XS: 1, S: 2, M: 3, L: 5}  (triage complexity precedence)
COMPLEXITY_TO_HOURS  = {XS: 2, S: 4, M: 8, L: 16}
```

Velocity 3-tier fallback:
- Tier 1 (historical): čte `./reports/metrics.md`
- Tier 2 (heuristic): effort mapping + config capacity
- Tier 3 (manual/unconstrained): prompt nebo top-N bez omezení

Cold-start: prominentní varování na každém gate.

## 10. Scope boundary — co se NEDĚLÁ

- Sprint tracking (burndown, health, completion %)
- Sprint retrospectives
- Team member modeling (per-person capacity)
- AI velocity prediction
- AI sprint goal generation
- Sprint state normalization across trackers
- Burndown data storage
- Redmine Agile Plugin detection
- Interactive scope adjustment (Gate 5) — odloženo, ne zamítnuto

## 11. Co chci od forge pipeline

1. **Kriticky zhodnotit** tento návrh proti best practices — je to konzistentní? Chybí něco? Je něco zbytečné?
2. **Ověřit** kompatibilitu s existujícím codebase (agent patterns, skill patterns, config contract, test patterns)
3. **Vyjasnit** nejasnosti — pokud něco nedává smysl, zeptat se uživatele
4. **Implementovat** všechny komponenty s testy
5. **Aktualizovat** roadmap (přesunout sprint planning z NOT PLANNED, přidat v6.5.0 entry)

## 12. Kontext z předchozího forge runu

Předchozí forge run (forge-2026-04-13-004) provedl Phase 0-3 (research + brainstorm). Klíčové výstupy jsou v `.forge.bak-*` adresáři. Relevantní findings:

- **Tracker API research:** MCP tool availability per tracker — viz `.forge.bak-*/phase-1-research-questions/final.md`
- **Brainstorm:** Conservative Pragmatist vyhrál — thin layer, 3 gates, sprint_assign only
- **Scope se změnil** po diskuzi s uživatelem: přidán create-backlog, --decompose-only, --all flag, epic template override

## 13. Referenční soubory v codebase

| Soubor | Proč je relevantní |
|--------|-------------------|
| `agents/priority-engine.md` | Sprint-planner konzumuje jeho výstup |
| `agents/spec-analyst.md` | Pattern pro read-only analysis agent |
| `agents/architect.md` | Decomposition pattern, maps_to |
| `skills/prioritize/SKILL.md` | Orchestration pattern pro priority-engine |
| `skills/implement-feature/SKILL.md` | Step 5a tracker creation, decomposition gates, --decompose-only target |
| `skills/fix-bugs/SKILL.md` | Batch processing, --yolo pattern |
| `skills/scaffold/SKILL.md` | Step 4e refactor target |
| `skills/workflow-router/SKILL.md` | Intent routing table — nové rows |
| `core/mcp-preflight.md` | MCP pre-flight check pattern |
| `core/config-reader.md` | Config parsing pattern |
| `state/schema.md` | State persistence patterns, RUN-ID formats |
| `CLAUDE.md` | Config contract, versioning policy, agent/skill counts |
| `docs/plans/roadmap.md` | NOT PLANNED entry to update |
