# Sub-projekt A — Agent Shape Rework: Design Spec (v8.0.0)

**Verze:** A.1 brainstorm output
**Datum:** 2026-04-26
**Cílový release:** v8.0.0 (A + B společně)
**Status:** Design spec připravený k validaci uživatelem; po schválení vstupuje do v8.0.0 forge pipeline (Phase 4 spec → 5 TDD → 6 plan → 7 execute → 8 verify → 9 completion)

---

## 1. Context

### 1.1 Co je v scope

Sub-projekt A z roadmapu (`docs/plans/roadmap.md` řádky 1009–1019) — Agent Shape Rework. Cíl: rozhodnout finální tvar 21 agentů a 3 pipelines (`fix-bugs`, `implement-feature`, `scaffold`) před public release ve v9.0.0.

**Konkrétní artefakty rozhodované v této fázi:**
- Customization mechanism (jak projekty upravují plugin agenty)
- Pipeline definition format (markdown vs declarative)
- HITL strategy (delegováno na sub-projekt B)
- State management (zachovat / měnit)
- Agent count + role granularity (konsolidace?)

### 1.2 Co je out of scope

- **Sub-projekt B (Human-in-the-Loop)** — paralelní brainstorm + research, výsledky se sloučí do v8.0.0 forge
- **Sub-projekty D, E, F, G** — v9.0.0+ (Public launch UI vrstva + polish)
- **Implementační detaily** — tato spec specifikuje WHAT, forge phases 5-7 řeší HOW
- **Migration code samotný** — vyrobí forge phase 7 execute

### 1.3 Research foundation

A.1 brainstorm je postaven na evidence z dvou forge research runů (2026-04-26):

| Run | Lokace | Obsah |
|---|---|---|
| Run 1 | `.forge/2026-04-26-A-research-run1/phase-2-research-answers/final.md` (871 řádků) | Q1–Q12 — agent prompt engineering, pipeline architecture, configuration philosophy, quality measurement, framework discovery (Top 10 shortlist) |
| Run 2 | `.forge/2026-04-26-A-research-run2/phase-2-research-answers/final.md` (616 řádků) | Q13–Q22 deep-dives 10 frameworků (opencode, superpowers, Claude Code, Cursor, OpenAI Agents SDK, MS Agent Framework, BMAD-METHOD, Devin, GH Copilot Coding Agent, Cline) + Q23 cross-run paradigm synthesis + 10 oprav Run 1 + 8 open questions |

A.1 brainstorm s uživatelem (2026-04-26) prošel D1–D5 dimenze, postupně potvrzeno.

---

## 2. Rozhodnutí (5 dimenzí)

### D1 — Customization Mechanism

**Rozhodnutí:**
1. **Generic markdown agenti zůstávají** v `agents/*.md` (Claude Code platformové requirement — agent definice MUSÍ být markdown s YAML frontmatter; bez toho ji Claude Code nenačte jako Task tool agenta).
2. **Overlay přechází z `.md` append na `.toml` strukturovanou konfiguraci.** `customization/{agent-name}.toml` umožňuje override modelu, retry limitů, přidání process steps, přidání constraints — strukturovaně, ne raw append text.
3. **Nová skill `/setup-agents`** — meta-agent jako jednorázový onboarding tool. Naskenuje projekt (CLAUDE.md, source, frameworks, conventions) a vygeneruje smart `customization/*.toml` defaulty. **Ne** je to "meta-gen architecture" (kterou Run 2 evidence vyvrátila s 0 production deployments) — je to scaffold-style one-shot generator s ochranou před přepsáním user editů (`# generated:` header + idempotent regen).

**Evidence:**
- Generic+overlay je dominant production pattern (5/5 Run 1 lenses + 8/10 Run 2 frameworků: BMAD, Anthropic Skills, superpowers, Claude Code, opencode, Codex Subagents, Cline, Cursor) [Q3, Q8, Q11]
- Per-project full-duplication: 0 vendor exemplars, community-rejected anti-pattern [Q8]
- Meta-gen jako primary architecture: 0 production deployments k 2026-04 (jen akademická literatura — MetaGen arxiv 2601.19290, ADAS, MetaSynth) [Q8, Q11]
- BMAD `customize.toml` 3-tier merge je production-validated u 45.7k★ Claude Code plugin [Q19]
- Codex Subagents TOML inherit-with-override je production-shipping pattern [Q17]
- Anthropic 5-tier subagent priority explicitně endorsuje append-to-prompt [Q15]

**TOML overlay konkrétní semantika (BMAD-style 3-tier merge):**

```toml
# customization/reviewer.toml — příklad
model = "sonnet"  # override (default je opus)

[[process_additions]]
step = "after_security_check"
instruction = "Always check for SQL injection in all database queries."

[[constraints]]
rule = "PR review messages must be in Czech."

[limits]
max_review_iterations = 3  # default je 5
```

**Merge rules:**
- Skalární klíče (`model`, `style`) — override (TOML přepíše plugin default)
- Pole tabulek (`[[process_additions]]`, `[[constraints]]`) — append (TOML přidá k plugin defaultu)
- Tabulky (`[limits]`) — deep merge per klíč

**`/setup-agents` skill chování:**
- Spuštění: jednorázové na `/setup-agents` (uživatel iniciuje)
- Vstup: projekt root (CLAUDE.md, package.json/pyproject.toml/atd., source layout, framework detection)
- Výstup: smart defaulty v `customization/*.toml` per agent, který má smysl customizovat
- Idempotent regen: pokud `customization/{agent}.toml` existuje a NEMÁ `# generated:` header → user editoval, NEPŘEPÍŠE; pokud má header → bezpečně regen
- Doporučení: skill produkuje preview diff před zápisem souboru

**Migration impact (breaking change):**
- Existing `customization/*.md` overlay soubory v consuming projektech (BIFITO, drmax) musí migrovat na `*.toml`
- Migration helper skill (`/migrate-config --to-v8`) vyrobí konverzi (raw append text → `[[process_additions]]` block)
- Deprecation alias: v v8.0.0 oba formáty fungují (`.md` jako legacy, `.toml` jako primary); v v9.0.0 hard removal `.md`

### D2 — Pipeline Definition Format

**Rozhodnutí:**
1. **Pipeline zůstává markdown** (skills/*/SKILL.md). Žádný YAML/JSON pipeline DSL.
2. **Decomposition do `steps/*.md`** — místo monolithic ~600-řádkového SKILL.md rozdělit na entry point (~100 řádků) + 5-8 step souborů.
3. **Step override přes overlay** — `customization/steps/{skill}/{step-name}.md` umožňuje user nahradit konkrétní step, aniž by forkoval celý plugin.

**Evidence:**
- BMAD v6.1.0 (2026-03-13) explicitně **odstranil YAML workflow engine** a vrátil se k markdownu — package size -91% (6.2 MB → 555 KB) [Q19]
- BMAD důvody: 3 documented installer/upgrade issues (#675, #1062, #1166), onboarding "design hole" (#2003: "10-15× času s BMAD než bez"), ekosystémová konvergence na markdown+frontmatter standard [Q19]
- 100% top-15 Claude Code pluginů používá markdown [Q15]
- MS Workflows.Declarative stále `--prerelease` i po 1.0 GA — enterprise YAML emerging ale ne production-stable referenční implementace [Q18]
- BMAD steps/*.md decomposition: **80% token reduction** (15k monolithic → 2-3k per step), lepší LLM reliability na delších pipelines [Q19]

**Konkrétní struktura po decomposition:**

```
skills/fix-bugs/
  SKILL.md                       (~100 řádků, entry point + dispatch logic)
  steps/
    01-triage.md                 (~150 řádků)
    02-code-analyst.md           (~150 řádků)
    03-reproducer.md             (~120 řádků, optional)
    04-fixer-reviewer-loop.md    (~200 řádků)
    05-test.md                   (~150 řádků)
    06-acceptance-gate.md        (~120 řádků, conditional)
    07-publisher.md              (~100 řádků)
```

**Pipeline customization cesty:**
1. **Pipeline Profiles v Automation Config** (existuje v v7, rozšíříme): `Skip stages: [03-reproducer, 06-acceptance-gate]` → SKILL.md přečte profile a přeskočí
2. **Step override přes overlay** (nový v v8.0.0): `customization/steps/fix-bugs/04-fixer-reviewer-loop.md` nahradí konkrétní step
3. **Hooks** (existuje v v7): pre/post-fix/publish bash hooks zůstávají

**Migration impact (breaking change):**
- Existing `skills/*/SKILL.md` se rozdělí na entry + steps/
- Tests (`tests/scenarios/*.sh`) musí ověřovat steps/*.md path resolution
- Documentation (docs/architecture.md, docs/reference/skills.md) musí reflektovat novou strukturu

### D3 — HITL Strategy: Mode framework v A, implementace v B

**Rozhodnutí: A.1 spec deklaruje 3 mode flags jako contract; B doplní implementační detaily a revize default gates.**

#### Současný gate inventář (verifikováno ze 3 SKILL.md souborů, 2026-04-26)

Aktuální gate landscape NENÍ "5 fixed strategic gates" jak jsem v draftu nepřesně tvrdil. Realita je heterogenní:

**fix-bugs (verified `skills/fix-bugs/SKILL.md`):**
| Místo | Typ | Triggerovaná |
|---|---|---|
| Step 0b: Config Validity Gate | Validation | Vždy (block při invalid config) |
| Triage Quality gate UNCLEAR | Block-or-continue | Conditional |
| NEEDS_CLARIFICATION pause | Event-driven (tracker) | Conditional (triage/fixer emit) |
| Decomposition AC coverage prompt | User prompt | Conditional (jen unmapped AC, non-YOLO) |
| Step 7c: Acceptance gate | Agent dispatch (sonnet) | Conditional (AC ≥ 3 nebo complexity ≥ M) |
| Custom post-fix agent | One-shot gate | Conditional (jen pokud nakonfigurován) |

**implement-feature (verified `skills/implement-feature/SKILL.md` line 672):**
> "Confirmation points: Step 0c (card creation, --description mode only), Step 5 (decomposition plan approval + AC coverage check), Step 9 (PR creation). All other steps run autonomously."

**scaffold (verified `skills/scaffold/SKILL.md`):**
3 mode selection na začátku jako separátní dimenze:
- (a) Interactive — brainstorm + Spec Checkpoint + Feature Plan Checkpoint + průběžné prompts
- (b) YOLO with checkpoint — pouze 2 mandatory checkpoints (Spec, Feature Plan)
- (c) Full YOLO — zero gates

#### v8.0.0 mode framework (A.1 contract)

A.1 spec deklaruje **3 mode flags** napříč fix-bugs / implement-feature pipelines (scaffold má vlastní 3-mode selection beze změny):

| Mode flag | Status | Co |
|---|---|---|
| `--yolo` | existující v7 | Zero gates, batch / autopilot mode |
| default (strategic) | existující v7 + B revize | Conditional gates per pipeline (acceptance, decomposition, NEEDS_CLARIFICATION) — viz inventář výše |
| **`--step-mode`** | **NEW v v8.0.0** | Pauza po každém agentovi (Cline-style, debug/učení) — A vyrobí mechanismus, B doladí UX |

**`--yolo` je exkluzivní vůči `--step-mode`** (zero gates ≠ per-agent pauzy). Default mode + `--step-mode` jsou alternativy, ne kombinace.

**NEEDS_CLARIFICATION ortogonální feature:** Funguje napříč všemi 3 módy beze změny od v6.9.0. Pipeline pauzí, postne otázku do trackeru jako comment, user odpoví, `/resume-ticket --clarification` pokračuje. **Není to mód, je to event-driven feature pro ambiguity handling.**

#### Boundary contract A → B

| Aspekt | Sub-projekt A scope | Sub-projekt B scope |
|---|---|---|
| Mode flags existence (`--yolo`, `--step-mode`) | ✅ A.1 contract | — |
| `--step-mode` flag parsing v entry SKILL.md | ✅ A přidá (steps decomposition pomáhá) | — |
| Per-agent prompt mechanism (po každém step dispatch ask "Continue?") | ✅ A vyrobí (po each step v `steps/*.md`) | B doladí: konkrétní wording, escape eskalace |
| Default strategic gates (current inventory) | ✅ A zachovává beze změny | B revize: možná konsolidace, přidání, podmínění |
| Event-driven gates (iter count > N, HIGH severity) | — | ✅ B: které eventy, jaké thresholds |
| Configurable thresholds | — | ✅ B: design + impl |
| NEEDS_CLARIFICATION ortogonální infrastructure | ✅ A reuse beze změny | — |

**Důvody pro A↔B split:**
- Sub-projekt B má vlastní brainstorm + research → není fér ho předhrát rozhodnutími z A
- Q6 v Run 1 + Run 2 byla preliminary, ne dedicated HITL research
- A poskytuje **framework infrastruktury** (mode flags, dispatch hooks); B doplňuje **implementační detaily a default tuning**
- D1, D2, D4, D5 jsou self-contained — A.1 spec funguje s tímto framework D3

**Co A.1 EXPLICITNĚ NESLIBUJE:**
- ❌ `--smart` mode — redundantní s default + B improvements (default je už event-driven přes conditional gates)
- ❌ `--tracker-async` mode — NEEDS_CLARIFICATION už řeší tracker komunikaci pro ambiguity events; rozšíření na všechny gates je over-engineered
- ❌ Custom mode kombinace (např. `--step-mode --tracker-async`) — pokud B najde důvod, přidá se v B; A.1 ne

### D4 — State Management

**Rozhodnutí: Zachovat status quo (stateless dispatch + externalizovaný state).**

- Stateless agent dispatch (každý agent dostane fresh context, kontext explicitně předán)
- `state.json` v `.ceos-agents/` (pipeline state, mode-aware schema)
- Git pro kód (changes versioned)
- `pipeline-history.md` (telemetry, run metadata, sanitized block reasons)

**Evidence:**
- Stateless dispatch + externalizovaný state je production-validated hybrid: GitHub Copilot model (stateful uvnitř session, stateless mezi sessions, stav v git/draft PR) [Q21]; "Devin Manages Devins" (2026-03) — parent stateful + managed Devins clean-slate [Q20]
- Stateless DPM paper (arxiv 2604.20158): stateless 7-15× faster, 2 LLM calls vs 83-97 [Q4]
- Anthropic explicit: "Subagents prevent context bloat by isolating exploration in clean context windows" [Q4]
- Token cost growth ve stateful loops: 888 tokenů iter 1 → 18,900 by iter 5 bez compaction [Q4]
- **Claude Code plugin agenti NEMOHOU sdílet session state** — platformové constraint [Q15], stateful sessions B option je technicky nemožné

**Žádná migration impact.** State schema (`state/schema.md`) může dostat additive fieldy v rámci D5 agent rename (např. nové `analyst_*` keys), ale schema_version zůstává `1.0` (backward-compatible reads).

### D5 — Single vs Multi-Agent + Agent Count

**Rozhodnutí: Konsolidovat 21 → 18 agentů přes 3 párové merge.**

| Sloučit | Důvod | Mode flag |
|---|---|---|
| **triage-analyst + code-analyst → `analyst`** | Oba read-only, oba na začátku pipeline, sdílí kontext (issue + codebase), žádný information loss při sloučení | `analyst --phase triage` / `analyst --phase impact` |
| **test-engineer + e2e-test-engineer → `test-engineer`** | Stejná doména (testy), stejný model (sonnet), funkční overlap | `test-engineer --e2e` flag (default: unit only) |
| **reproducer + browser-verifier → `browser-agent`** | Oba browser automation (Playwright), liší se jen kdy v pipeline běží | `browser-agent --phase reproduce` / `browser-agent --phase verify` |

**Po konsolidaci: 21 - 3 = 18 agentů.**

**Spec triáda (spec-analyst, spec-writer, spec-reviewer) NEKONSOLIDOVAT** — Run 2 evidence: spec workflow má funkční důvod oddělení (analyst čte z trackeru, writer produkuje, reviewer kritizuje). Sloučení by degradovalo quality přes loss of role separation. Stejně tak backlog-creator + sprint-planner (různé fáze planning, různé výstupy).

**Sequential pipeline obhájitelnost vyšší agent counts:**

ceos-agents má **sequential** dispatch (ne parallel critique nebo persona-menu). Každý agent dostane fresh context bez bloat z předchozích. To umožňuje větší agent count než BMAD (6 personas, persona-menu pattern) nebo Anthropic Multi-Agent Research (1 lead + 3-5 parallel sub-agents — fixed compute Kim et al. limit) [Q2, Q19, CC1].

**Evidence pro 18 (ne 6, ne 21):**
- BMAD konsolidace 19+ → 6 [Q19]: BMAD je persona-menu, agenti běží **paralelně přes user choice**, ne sequentially. Náš pattern je odlišný.
- Kim et al. (arxiv 2512.08296) "thinning past 3-4 under fixed compute" [Q2]: vztahuje se na **simultaneous** agenty (parallel critique). Sequential dispatch nemá fixed compute constraint.
- Anthropic Multi-Agent Research +90.2% pro **read tasks** s 3-5 parallel [CC1]: opět parallel pattern.
- ceos-agents 21 = outer edge, ALE konsolidace 21 → 18 odstraňuje 3 most-redundant pairs bez ztráty schopností.

**Migration impact (breaking change):**

6 původních agent names → 3 new names:
- `triage-analyst` + `code-analyst` → `analyst` (rename + merge)
- `test-engineer` (samostatný) + `e2e-test-engineer` → `test-engineer` (extended s `--e2e` flag)
- `reproducer` + `browser-verifier` → `browser-agent` (rename + merge)

- `customization/triage-analyst.md` (či .toml) → `customization/analyst.toml` migration helper
- Pipeline Profiles `Skip stages: [code-analyst]` → `Skip stages: [analyst-impact]` (named-phase syntax)
- Doc updates: docs/reference/agents.md, agents description tables, examples

---

## 3. Plugin Permission Constraint (BLOCKING)

**Run 2 Q15 oprava 2 odhalila:** Plugin agenti v Claude Code **NEPODPORUJÍ** `hooks`, `mcpServers`, ani `permissionMode` frontmatter pole — Claude Code je z bezpečnostních důvodů ignoruje.

**Důsledek pro v8.0.0:**

ceos-agents jako plugin **NEMŮŽE** svým agentům přidávat hooks ani přepínat permission mode přes agent frontmatter. Všechny hooks musí být:

| Vrstva | Jak |
|---|---|
| **Plugin-level hooks** | Definované v `.claude-plugin/plugin.json` (ne per-agent) |
| **Skill-level orchestration** | SKILL.md explicitně volá bash hook commands přes `Bash` tool |
| **Per-stage hooks (pre-fix, post-fix, pre-publish, post-publish)** | Definované v project Automation Config `### Hooks` sekce, dispatchnuté skill (ne agent) |

**Migration impact:**
- Existing `### Hooks` config sekce v consuming projektech (BIFITO, drmax) zůstávají funkční — beze změny
- Žádný v6/v7 konfig se nelámě (hooks jsou na project-level, ne agent-level)
- Doc clarification: docs/reference/automation-config.md musí explicitně říkat "hooks jsou skill-orchestrated, ne agent-frontmatter"

---

## 4. Architecture Changes Summary

### 4.1 Před (v7.0.0) → Po (v8.0.0)

| Aspekt | v7.0.0 | v8.0.0 |
|---|---|---|
| Agent count | 21 | **18** (po 3 párových merge) |
| Agent format | Markdown + YAML frontmatter | Markdown + YAML frontmatter (zachovat) |
| Customization | `customization/{agent}.md` append-to-prompt | `customization/{agent}.toml` strukturovaný 3-tier merge |
| Setup tool | `/onboard` (interactive CLAUDE.md wizard) | `/onboard` + **`/setup-agents`** (smart TOML overlay generator) |
| Pipeline definition | Monolithic `skills/*/SKILL.md` (~600 řádků) | Entry `SKILL.md` (~100 řádků) + `steps/*.md` (5-8 souborů) |
| Pipeline customization | Pipeline Profiles + Hooks | Pipeline Profiles + Hooks + **step override** v overlay |
| HITL mode flags | `--yolo` + default strategic | `--yolo` + default strategic + **`--step-mode`** (NEW); B doplní detaily |
| State | stateless dispatch + state.json + git | Same |
| Plugin permission constraint | (skrytý) | **Explicitně dokumentovaný** — hooks jsou skill-level, ne agent-level |

### 4.2 Counts impact

| Metric | v7.0.0 | v8.0.0 |
|---|---|---|
| Agents | 21 | 18 (-3) |
| Skills | 28 | 29 (+1: `/setup-agents`) |
| Optional config sections | 18 | 18 (no change) |
| Core contracts | 16 | 16 (no change) |
| Config templates | 8 | 8 (no change, ale aktualizované syntaxí) |

### 4.3 Breaking changes (must migrate)

1. `customization/{agent}.md` → `customization/{agent}.toml` (deprecation alias v8.0.0, hard removal v9.0.0)
2. Agent renames: 6 agents → 3 (mapping table v migration guide)
3. SKILL.md decomposition do `steps/*.md` (transparentní pro users; affects custom skill authors)
4. Pipeline Profiles syntax: `Skip stages: [code-analyst]` → `Skip stages: [analyst-impact]` (named-phase)

---

## 5. Documentation Requirements (HIGH PRIORITY)

User explicit instruction (2026-04-26 brainstorm): **"hlavne pozor na doc, to si zapis. musi se to vse mega dukladne zdokumentovat."** Public release ve v9.0.0 — špatné/chybějící docs by zničily adoption. Saved to memory: `project_v8_doc_requirements.md`.

**Mandatory deliverables v8.0.0 forge:**

### 5.1 Migration guides

| Doc | Cíl |
|---|---|
| `docs/guides/migration-v7-to-v8.md` (NEW) | Comprehensive migration guide — TOML overlay konverze, agent renames, SKILL.md decomposition implications, plugin permission clarification |
| `docs/guides/toml-overlay-syntax.md` (NEW) | TOML overlay reference — merge rules, examples per agent, common patterns, anti-patterns |
| `docs/guides/setup-agents-skill.md` (NEW) | `/setup-agents` skill usage — kdy použít, jak interpretovat output, idempotent regen behavior, ochrana před přepsáním user editů |
| `docs/guides/steps-decomposition.md` (NEW) | Pipeline `steps/*.md` decomposition — proč, jak číst, jak override, jak debugovat |

### 5.2 Reference docs (must update)

- `docs/reference/agents.md` — table of 18 agentů (po konsolidaci), description per agent, model assignment, mode flags
- `docs/reference/skills.md` — `/setup-agents` přidat (29 skills total), aktualizovat ostatní
- `docs/reference/automation-config.md` — TOML overlay sekce, plugin permission constraint clarification
- `docs/reference/pipeline.md` (NEW or rewrite) — steps/*.md model, override mechanism, profile semantics
- `docs/architecture.md` — updated diagram (18 agents, steps decomposition, TOML overlay layer, /setup-agents skill flow)

### 5.3 Examples

- `examples/configs/*.md` — všechny 8 templates updated s TOML overlay examples (ne jen mention)
- `examples/customization/` (NEW directory) — example TOML overlay soubory per common patterns:
  - `reviewer-strict-security.toml`
  - `fixer-no-tests.toml`
  - `analyst-monorepo.toml`
  - `step-override-example.md`

### 5.4 README.md

Top-level README must:
- Update agent count (21 → 18) napříč všemi sekcemi
- Add v8.0.0 highlights box (TOML overlay, /setup-agents, steps decomposition)
- Migration callout pro existing users
- Diagram refresh

**Note on count parity:** Per CLAUDE.md "Cross-File Invariants" + `feedback_doc_completeness.md`, agent count update musí proběhnout v sync napříč 5 soubory: `CLAUDE.md`, `README.md`, `docs/reference/automation-config.md`, `docs/reference/skills.md` (přesah), `docs/architecture.md`. Forge phase 9 doc audit MUSÍ enumerovat ne jen counts, ale full agent list completeness (lesson z v6.9.0 → v6.9.1: count strings checked, enumeration completeness missed = 34 doc gaps).

### 5.5 CHANGELOG.md

Detailní migration path per breaking change:
- Před vs Po příklady kódu
- Konkrétní migration commands (`/migrate-config --to-v8`)
- Deprecation timeline (v8.0.0 alias → v9.0.0 removal)
- Rationale per change s odkazem na research evidence

### 5.6 Tests

- Phase 8 verification scenarios MUSÍ obsahovat doc-completeness checks (ne jen count strings — actual enumeration completeness, follow-up na v6.9.1 lesson)
- New scenarios: TOML overlay parsing, `/setup-agents` idempotent regen, agent rename backward compat, steps/*.md path resolution

### 5.7 Doc audit discipline (per existing feedback_doc_completeness.md)

Forge phase 9 completion **MUSÍ** spustit doc audit:
- Grep ALL doc files (CLAUDE.md, README.md, docs/) pro stale numbers (21 agents, 28 skills, etc.)
- Cross-file invariants (license SPDX, maintainer email, template parity) per CLAUDE.md "Cross-File Invariants" section
- Enumeration parity (ne jen count fields — full agent list / skill list / config section list napříč CLAUDE.md, README.md, docs/reference/automation-config.md, docs/reference/skills.md, docs/architecture.md)

---

## 6. Open Questions for Implementation Phase (forge)

Tyto otázky **A.1 brainstorm explicitně neuzavřel** — předány do forge phase 4 spec / phase 5 TDD / phase 6 plan k řešení s implementačním kontextem.

**OQ-A.1: TOML schema v plné formě.** A.1 spec definuje merge rules (skalár override, array append, table deep-merge), ale **konkrétní schema per agent** (které klíče jsou vůbec overrideable, validation rules, error messaging) je implementační detail. Forge phase 4 spec ho dotáhne.

**OQ-A.2: `/setup-agents` heuristics.** Skill musí scanovat projekt a generovat smart defaulty. Konkrétní heuristics (jak rozhodnout "Python projekt → fixer dostane Python-specific constraints", "monorepo → analyst dostane multi-package guidance") jsou věc forge research/spec phase.

**OQ-A.3: Step override granularity.** A.1 řekl "step override přes `customization/steps/{skill}/{step-name}.md`". Otevřené: může step override měnit i pořadí? Jen replace? Replace + insert before/after? Forge spec to dotáhne.

**OQ-A.4: Pipeline Profiles syntax extension.** Po konsolidaci agentů a steps decomposition se Pipeline Profiles syntax mění. Konkrétní migration od `code-analyst` → `analyst-impact` step name resolution je věc forge plan/execute phase.

**OQ-A.5: TOML migration helper UX.** `/migrate-config --to-v8` vyrobí konverzi `.md` → `.toml`. Otevřené: dry-run flag, conflict resolution při ambiguitě, backup originálu.

**OQ-A.6: Backwards compat strategy v v8.0.0.** Deprecation alias `.md` overlay funguje paralelně s `.toml` v v8.0.0. Otevřené: warnings v logs? Strict mode flag? Sunset announcement timing.

**OQ-A.7: `--step-mode` per-agent prompt UX.** A vyrobí mechanismus (po každém step v `steps/*.md` ask user "Continue?"). Otevřené pro forge phase 4 spec: konkrétní wording promptu, escape options ("Continue / Skip remaining gates / Abort"), state persistence při abort uprostřed step-mode (resume-ticket compatibility). Sub-projekt B mu může doladit po své research.

**Sub-projekt B konvergence:** Tyto OQ se neřeší v sub-projektu B — všechny jsou A-internal. Sub-projekt B má vlastní open questions kolem HITL.

---

## 7. References

### Research evidence
- Run 1 final.md: `.forge/2026-04-26-A-research-run1/phase-2-research-answers/final.md`
- Run 2 final.md: `.forge/2026-04-26-A-research-run2/phase-2-research-answers/final.md`
- Q12 framework discovery (Top 10 shortlist): Run 1 final.md sekce Q12
- Q19 BMAD-METHOD deep-dive (TOML overlay precedent): `.forge/2026-04-26-A-research-run2/phase-2-research-answers/agents/agent-Q19-bmad-method.md`
- Q15 Claude Code platform (plugin permission constraint): Run 2 deep-dive
- Q23 cross-run paradigm synthesis: Run 2 final.md sekce 1-9

### Roadmap context
- `docs/plans/roadmap.md` řádky 1009–1019 (sub-projekt A definition)
- `docs/plans/roadmap.md` řádky 1021–1027 (release allocation v7-v8-v9)

### Research questions DRAFT
- `docs/superpowers/specs/2026-04-26-A-research-questions-DRAFT.md` (původní research zadání)

### Memory feedback
- `feedback_propose_dont_punt_and_defend_numbers.md` (defend every number)
- `feedback_never_trust_spec.md` (always verify)
- `feedback_doc_completeness.md` (audit ALL doc files for stale counts)
- `project_v8_doc_requirements.md` (mega thorough docs for v8.0.0 — explicit user instruction 2026-04-26)

---

## 8. Next Steps

1. **User reviews A.1 spec** (this document) — feedback / approval
2. **Sub-projekt B brainstorm + research** (parallel track) — bude probíhat samostatně, finální spec uložen jako `docs/superpowers/specs/<future-date>-B-hitl-design.md` (datum se doplní při uložení)
3. **Spec consolidation:** A + B specs → `docs/superpowers/specs/<future-date>-v8.0.0-design.md` (combined; datum se doplní při uložení; vznikne až po dokončení sub-projektu B)
4. **Decision: forge full pipeline vs phase-skip:**
   - Full forge (Phase 1-9) — pokud A+B kombinace vyžaduje další research
   - Phase-skip forge (Phase 4 spec → 9 completion) — pokud A+B specs jsou implementation-ready
5. **Implementation in v8.0.0 forge run** — produces actual code changes, tests, docs
6. **v8.0.0 release** — version bump, CHANGELOG, push, announcement
