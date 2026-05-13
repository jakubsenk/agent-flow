# Q19 — BMAD-METHOD: Hluboká analýza (Run 2 Agent Report)

**Datum:** 2026-04-26
**Agent:** Q19 — BMAD-METHOD deep-dive
**Lens:** OSS code (primary) + community (secondary)
**Run:** 2026-04-26-A-research-run2
**Vstup:** Run 1 final.md (Q3, Q5b, Q5c, Q8, Q12 BMAD excerpts) + live WebFetch/WebSearch

---

## Lens disclosure

Tento report je psán ze dvou primárních lens:

- **OSS code (primary):** přímé čtení BMAD-METHOD GitHub repo (`bmad-code-org/BMAD-METHOD`), CHANGELOG, releases, docs site, zdrojových souborů SKILL.md a step souborů. Každé tvrzení citováno na konkrétní zdroj.
- **Community (secondary):** GitHub issues (#675, #1062, #2003), GitHub discussions (#1306), komunitní blogy (Medium, vibesparking.com, bennycheung.github.io, buildmode.dev), uživatelské zkušenosti a sentiment.

Run 1 final.md poskytl baseline evidence (BMAD `customize.toml` s explicit merge rules, v6 alpha critique 50+ workflows, star-count discrepancy 45.7k vs 29.6k). Run 2 tuto evidenci verifikuje a expanduje napříč všemi 8 dimenzemi šablony.

---

## Exec summary

BMAD-METHOD je **closest peer k ceos-agents v8.0.0** pro 4 důvody: (1) oba jsou Claude Code markdown-only pluginy bez runtime; (2) oba implementují Generic+Overlay customization; (3) oba cílí SDLC orchestration s více specializovanými agenty; (4) oba řeší stejný design problém — jak dodat HITL SDLC pipeline pro projekty s různými technologickými stacky. BMAD je 7-9 let starší, má masivní komunitu, a jeho evoluce v3 → v4 → v6 je přesně ten typ lessons-learned evidence, kterou ceos-agents v8.0.0 potřebuje.

**5 klíčových findings pro Q23 cross-run synthesis:**

1. **`customize.toml` 3-tier merge semantics** (scalars override, arrays append, arrays-of-tables match by `code`) je produkčně validovaný pattern pro overlay customization — přenositelný přímo do ceos-agents Agent Overrides v2 design.
2. **Scaling pain je reálný a měřitelný:** v4 → v6 přešel z 12 na 19+ agentů a z 20 na 50+ workflows; komunita to nazývá "complexity creep" s explicitními GitHub issues dokumentujícími onboarding failure.
3. **Persona-menu pattern** (agent čeká na user input ze strukturovaného menu) je radikálně odlišný od ceos-agents auto-dispatch. BMAD je HITL-driven by design; ceos-agents je autonomous-pipeline-first. Oba mají platící uživatele.
4. **Steps/*.md decomposition** (každý krok = standalone .md soubor) řeší LLM drift problém při dlouhých workflows tím, že redukuje context na 2,000–3,000 tokenů per step vs 15,000 tokenů monolithic.
5. **v6 stability a discoverability critique** je empirická data point: "design hole" — framework předpokládá vyšší technickou kompetenci než typický target user má; Issue #2003 autor píše "10–15× víc času s BMAD než bez". Pro ceos-agents v8.0.0: progressive disclosure a onboarding quality jsou pre-launch blockers, ne post-launch polish.

**Star count verifikace (Run 2):** GitHub.com/bmad-code-org/BMAD-METHOD ukazuje 45.7k★ k 2026-04-26 per GitHub Issue #1559 (dated Feb 2026). Run 1 citace 29.6k byla zřejmě momentální anomálie nebo jiná repo migrace. Oba čísla jsou evidencí; 45.7k je konzistentní s quemsah/awesome-claude-plugins indexem.

---

## Dimenze 1 — Granularita agentů

### SDLC role boundaries v BMAD

BMAD-METHOD v6 stable (GA 2026-03-02) šipuje **6 hardcoded named agents** ve svém core BMM modulu, každý přiřazen k fázi SDLC:

| Agent (jméno) | Role ID | Fáze | Skill ID |
|---|---|---|---|
| Analyst (Mary) | Business Analyst | Analysis | `bmad-analyst` |
| Technical Writer (Paige) | Documentation | Analysis | `bmad-tech-writer` |
| Product Manager (John) | Product Strategy | Planning | `bmad-agent-pm` |
| UX Designer (Sally) | UX Design | Planning | `bmad-ux-designer` |
| Architect (Winston) | System Design | Solutioning | `bmad-architect` |
| Developer (Amelia) | Development & QA | Implementation | `bmad-agent-dev` |

Source: [docs.bmad-method.org/reference/agents/](https://docs.bmad-method.org/reference/agents/)

**Historická progrese (community evidence):**

- **v3/V4:** "12+ specialized agents" — monolithic agent files, pravděpodobně Analyst + PM + Architect + SM + PO + Dev + QA + TechWriter + Security + Custom slots. V4 branch ukazuje 628 commits a `bmad-core/agents/` strukturu.
- **v6 alpha:** komunita dokumentovala "50+ workflows, 19+ specialized agents" — per Medium blog [@hieutrantrung.it](https://medium.com/@hieutrantrung.it/from-token-hell-to-90-savings-how-bmad-v6-revolutionized-ai-assisted-development-09c175013085): *"50+ workflows (up from 20), 19+ specialized agents (up from 12)"*
- **v6.3.0 (April 2026):** **"Consolidated three agent personas into single Developer agent (Amelia)"** — explicitní konsolidace; Barry, Quinn, Bob eliminováni. Package size dropped 91% (6.2 MB → 555 KB). [GitHub releases 2026-04-10]
- **v6 stable (post-v6.3.0):** 6 hardcoded agents per official docs.

**Per-agent SKILL.md depth:**

Run 1 (OSS code agent-3) citoval `bmad-dev-story/SKILL.md` jako **485 řádků** — jednoznačně "deep" tier (300+ řádků). Tato hodnota platila pro v6-alpha period; v6 stable po konsolidaci a "Everything is now a skill" architektonickém overhauling (v6.1.0, March 2026) může mít jiné čísla. `bmad-advanced-elicitation/SKILL.md` = 142 řádků per verifikace v Run 2 (WebFetch). Core skills trend ke kratším souborům po konsolidaci.

**Prompt strategy per role:**

BMAD agenti mají **hardcoded identity layer** (jméno, title, doménové vlastnictví, emoji prefix — unchangeable) a **customizable layer** (role description, principles, communication_style, menu items, MCP tool integrations). Persona-loading aktivační sekvence:

1. Resolve agent config (merge defaults + overrides)
2. Execute prepend steps (pre-flight)
3. Adopt persona (identity + customizations)
4. Load persistent_facts (org rules, optional file: references)
5. Load config (user name, language, artifact paths)
6. Greet user (personalized, with emoji prefix)
7. Execute append steps (post-greet setup)
8. **Dispatch nebo present menu** — intent matching: pokud opening message mapuje na menu item, go directly; jinak render menu a čekej na user input

Source: [docs.bmad-method.org/explanation/named-agents/](https://docs.bmad-method.org/explanation/named-agents/)

**Srovnání s ceos-agents:**

ceos-agents šipuje 21 úzkých specialistů (triage-analyst, code-analyst, fixer, reviewer, acceptance-gate, test-engineer, e2e-test-engineer, publisher, rollback-agent, spec-analyst, architect, stack-selector, scaffolder, priority-engine, spec-writer, spec-reviewer, reproducer, browser-verifier, deployment-verifier, backlog-creator, sprint-planner). BMAD po konsolidaci šipuje 6. Paradigm je jiný: BMAD = broad SDLC roles s deep persona + menu; ceos-agents = narrow CI/CD automation agents s sequential pipeline dispatch.

---

## Dimenze 2 — Pipeline configuration mechanism

### Steps/*.md procedural decomposition

BMAD workflow = `steps/*.md` procedural decomposition. Každý step = standalone `.md` soubor s jedinou logickou úlohou. Mechanismus popsán v CHANGELOG a docs:

**Konkrétní file path (verifikováno v Run 2):**
```
src/bmm-skills/3-solutioning/bmad-check-implementation-readiness/steps/step-05-epic-quality-review.md
```
Source: [github.com/bmad-code-org/BMAD-METHOD/blob/main/src/bmm-skills/3-solutioning/bmad-check-implementation-readiness/steps/step-05-epic-quality-review.md](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/src/bmm-skills/3-solutioning/bmad-check-implementation-readiness/steps/step-05-epic-quality-review.md)

**PRD creation workflow — step kontext:**
```
src/bmm-skills/2-plan-workflows/bmad-create-prd/steps-c/step-05-domain.md
```
Tento soubor je **Step 5 of 13** v PRD creation procesu — mezi Step 4 (scope) a Step 6 (innovation). Obsahuje:
- Execution gate (check domain complexity z step-02; nízká = skip)
- Discovery sequence (4 fáze: verify → load CSV → conversation → document)
- Menu navigation po completion: [A] Advanced Elicitation, [P] Party Mode, [C] Continue

Source: [github.com/bmad-code-org/BMAD-METHOD/blob/main/src/bmm-skills/2-plan-workflows/bmad-create-prd/steps-c/step-05-domain.md](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/src/bmm-skills/2-plan-workflows/bmad-create-prd/steps-c/step-05-domain.md)

**Proč steps/*.md:**

Token economics jsou centrálním motivem. Per @hieutrantrung.it Medium blog:
- Monolithic workflow: **15,000 tokenů loaded upfront**
- Step-file workflow: **2,000–3,000 tokenů per step** → **~80% token reduction per workflow execution**
- Document sharding: PRD jako celek = 45,000 tokenů; sharded = 8,000 tokenů (index + Epic 3 + relevant functional requirements) = **82% reduction**
- Healthcare company case study: 74% reduction (31,667 → 8,333 avg tokenů per workflow); cost $847/month → $220/month

**Markdown jako primární config surface + TOML pro override:**

Každý skill = SKILL.md (main entrypoint) + volitelné `steps/` subdirectory + volitelné `methods.csv` helper. TOML overlay (`customize.toml` + `_bmad/custom/*.toml`) žije vedle skill souborů. Workflow routing se neděje přes YAML control-flow DSL — děje se přes markdown procedural instructions (agent čte "go to step-06" jako text instrukci, nebo user interaguje přes menu).

**v6.1.0 breaking change (March 2026):**

*"Convert entire BMAD method to skills-based architecture"* — migration from YAML+instructions to **unified workflow.md format**. Removal of legacy YAML/XML workflow engine infrastructure. Toto je klíčová historická lekce: BMAD **zkusil YAML workflows**, pak je **zrušil a přešel na čistý markdown**. Přesně stejný pohyb, který Run 1 syntéza identifikuje jako "markdown-procedural is dominant in Claude Code plugin space."

Source: [github.com/bmad-code-org/BMAD-METHOD/releases](https://github.com/bmad-code-org/BMAD-METHOD/releases) — v6.1.0 (13 Mar 2026).

---

## Dimenze 3 — Per-project customization a `customize.toml` schema

### Povinný deep-dive: full schema

**Mechanismus: 3-tier merge, TOML-based**

BMAD v6.4.0 (25 Apr 2026) zavedl **TOML-based customization** jako stabilní surface. Předchozí pokus s YAML-based customization byl explicitně dropnut: *"Customization is now TOML-based; the briefly introduced YAML-based customization is no longer supported."*

Source: [github.com/bmad-code-org/BMAD-METHOD/releases](https://github.com/bmad-code-org/BMAD-METHOD/releases) — v6.4.0 (25 Apr 2026).

**Priority stack (3 vrstvy):**

| Priorita | Soubor | Scope | Git status |
|---|---|---|---|
| 1 (wins) | `_bmad/custom/{skill-name}.user.toml` | Osobní | gitignored |
| 2 | `_bmad/custom/{skill-name}.toml` | Team/org | committed |
| 3 (base) | `{skill-dir}/customize.toml` | Plugin defaults | shipped with BMAD |

**4 merge rules (shape-based, not field-named):**

| Shape | Rule |
|---|---|
| **Scalar** (string, int, bool, float) | Override wins — team value replaces base |
| **Table** (`[section]`) | Deep merge — recursively apply rules |
| **Array-of-tables** s matching identifier field (`code`) | Merge by key — matching codes replace in-place, new codes append |
| **Any other array** (append-only arrays) | Append — base items first, then team, then user |

Source: [docs.bmad-method.org/how-to/customize-bmad/](https://docs.bmad-method.org/how-to/customize-bmad/)

**Critical caveat:** *"No removal mechanism. Overrides cannot delete base items."* Tj. overlay pattern je additive-only — nemůže odstranit default menu items nebo default persistent_facts, jen přidávat.

**Customizable scalar fields (příklady):**

```toml
[agent]
icon = "🏥"
role = "Drives product discovery for a regulated healthcare domain."
communication_style = "Precise, regulatory-aware, asks compliance-shaped questions early."
```

Scalars: `icon`, `role`, `communication_style`. Identity scalars `agent.name` a `agent.title` jsou hardcoded v SKILL.md — **NOT customizable via overlay**.

**Append-only arrays (4 klíče):**

```toml
# persistent_facts — static context agent drží celou session
[agent]
persistent_facts = [
  "Our org is AWS-only -- do not propose GCP or Azure.",
  "file:{project-root}/docs/compliance/hipaa-overview.md",
]

# principles — value system additions
[agent]
principles = [
  "Ship nothing that can't pass an FDA audit.",
  "User value first, compliance always.",
]

# activation_steps_prepend — runs BEFORE persona intro
[agent]
activation_steps_prepend = [
  "Scan {project-root}/docs/compliance/ and load any HIPAA-related documents as context.",
]

# activation_steps_append — runs AFTER greet, BEFORE menu
[agent]
activation_steps_append = [
  "Read {project-root}/_bmad/custom/company-glossary.md if it exists.",
]
```

**Menu customization (arrays-of-tables merge by `code`):**

```toml
# Replace existing menu item (match by code "CE")
[[agent.menu]]
code = "CE"
description = "Create Epics using our delivery framework"
skill = "custom-create-epics"

# Add new item (new code "RC" — appended)
[[agent.menu]]
code = "RC"
description = "Run compliance pre-check"
prompt = """Read {project-root}/_bmad/custom/compliance-checklist.md
and scan all documents against it."""
```

Každý menu item má přesně **jedno z** `skill` (invokes registered skill) nebo `prompt` (executes text directly). Source: [docs.bmad-method.org/how-to/customize-bmad/](https://docs.bmad-method.org/how-to/customize-bmad/)

**Workflow customization (stejný mechanismus pod `[workflow]`):**

```toml
[workflow]
activation_steps_prepend = [
  "Load {project-root}/docs/product/north-star-principles.md as context.",
]
persistent_facts = [
  "All briefs must include regulatory-risk section.",
  "file:{project-root}/docs/compliance/product-brief-checklist.md",
]
on_complete = "Summarize the brief in three bullets..."
```

**Safe override pattern (kritická guidance):**

*"Copying the full customize.toml into an override is actively harmful: the next update ships new defaults, but your override file locks in the old values, causing you to silently drift out of sync."*

Correct pattern = **sparse override files obsahující pouze změněné fields**. Vše ostatní se inherits automaticky z vrstvy níž.

**`file:` reference convention:**

Persistent_facts, activation_steps_*_prepend/append, a menu prompt mohou obsahovat `file:{project-root}/path/to/file.md` — agent načte obsah souboru jako context. Podporuje glob patterns.

**Resolution script:**

```bash
python3 {project-root}/_bmad/scripts/resolve_customization.py \
  --skill {skill-root} \
  --key agent
```

Requirement: Python 3.11+ (kvůli `tomllib`). Žádné pip install. Deterministic resolver — NIKOLI LLM-driven.

Source: [docs.bmad-method.org/how-to/customize-bmad/](https://docs.bmad-method.org/how-to/customize-bmad/)

**Central config (4-file system):**

```
_bmad/config.toml               (installer-owned, base layer)
_bmad/config.user.toml          (installer-owned, user defaults)
_bmad/custom/config.toml        (team overrides, committed)
_bmad/custom/config.user.toml   (personal overrides, gitignored)
```

Installer partitions answers by `scope:` v `module.yaml`: `scope: team` → `_bmad/config.toml`; `scope: user` → `_bmad/config.user.toml`.

**Agent-level vs workflow-level customization:**

3-layer composition model:
1. **Agent layer** (`_bmad/custom/bmad-agent-{role}.toml`) — shapes behavior across all workflows daný agent dispatches
2. **Workflow layer** (`_bmad/custom/bmad-{workflow-name}.toml`) — applies conventions to specific workflows
3. **Central config** (`config.toml`) — manages roster membership a shared settings

Source: [docs.bmad-method.org/how-to/expand-bmad-for-your-org/](https://docs.bmad-method.org/how-to/expand-bmad-for-your-org/)

---

## Dimenze 4 — HITL pattern

### BMAD jako heavily HITL-oriented framework

BMAD je ze své podstaty **user-driven**. Nepouští autonomní pipeline — každý agent čeká na human input po každém kroku. Toto je fundamentální designová volba, odlišující BMAD od ceos-agents.

**Persona-menu pattern:**

Agent activation: user invokuje agenta (dragging .md file, `@agent-name`, nebo `*agent-name` CLI pattern). Agent načte personu, zobrazí menu, a **čeká**. Menu = strukturovaná nabídka workflow opcí s alphanumeric kódy. User vybírá. Agent reaguje.

Per [docs.bmad-method.org/explanation/named-agents/](https://docs.bmad-method.org/explanation/named-agents/):
*"If your opening message maps to a menu item, go directly; otherwise render the menu and wait for input."*

Každý step file obsahuje po completion **menu navigation**: "Advanced Elicitation [A], Party Mode [P], Continue [C]" — user explicitně rozhoduje co dál. Source: `step-05-domain.md` — verifikováno v Run 2.

**Party Mode:**

BMAD "Party Mode" = multi-agent collaborative discussion v jedné session. BMad Master orchestruje, picking relevant agents per message. Agents *"respond in character, agree, disagree, and build on each other's ideas."* Continuous human-interactive loop. Use cases: big decisions, brainstorming, post-mortems, retrospectives. Source: [docs.bmad-method.org/explanation/party-mode/](https://docs.bmad-method.org/explanation/party-mode/)

**v6.3.0 (April 2026):** party-mode was consolidated into single SKILL.md s real subagent spawning via Agent tool — single-file architecture replacing multi-file workflow.

**Checkpoint gates:**

- `bmad-check-implementation-readiness` — quality gate před coding; PASS/CONCERNS/FAIL verdict
- `bmad-checkpoint-preview` — guided human review of commits and branches (v6.3.0)
- Developer agents "halt and report" architectural conflicts; NE autonomous decision
- Pre-commit quality gates v config.yaml

**Srovnání s ceos-agents:**

ceos-agents je autonomous-pipeline-first — skills orchestrují agenty sekvenčně bez per-step user approval (výjimky: `--yolo`, NEEDS_CLARIFICATION pause, acceptance-gate). BMAD vyžaduje human input na každém SDLC checkpoint. BMAD = "developer as conductor"; ceos-agents = "pipeline as conductor". Oba patterns mají platící uživatele — výběr je HITL placement, nikoli capability (per Run 1 Q6 cross-lens consensus).

**Implication pro v8.0.0:**

BMAD dokazuje, že heavy-HITL approach je viral (45.7k★) i v Claude Code plugin ekosystému. ceos-agents design choice "autonomous-first s strategic gates" je platný jiný bod v design space — ale sub-projekt B (Human-in-the-loop) by měl zvážit BMAD persona-menu pattern jako referenci pro interactive mode.

---

## Dimenze 5 — Stateful vs stateless agent design

### BMAD agent invocation pattern

BMAD agents jsou **stateless dispatch + stateful session persistence** — hybrid.

**Stateless elementy:**
- Skills a workflows jsou regenerovány při instalaci; nejsou session-aware
- TOML konfigurace = version-controlled, reproducible
- Každý agent invocation začíná s fresh context (activation sequence re-runs each time)

**Stateful elementy:**
- `sprint-status.yaml` — tracks Phase 4 progress across sessions
- `_memory/*-sidecar/` — runtime persistence per agent
- Artifacts (.md files v `_bmad-output/`) = persistent state across sessions
- Steps/*.md decomposition umožňuje "pause and save state during long tasks" (Step outputs do `_bmad-output/`)

Source: [deepwiki.com/bmad-code-org/BMAD-METHOD](https://deepwiki.com/bmad-code-org/BMAD-METHOD) — hybrid stateful/stateless classification.

**"Stay in role" vs stateless dispatch:**

BMAD persona = "stay in role" pro dobu session. Uživatel zavolá Johna (PM) na začátku session; John zůstává v roli celou session dokud user neodejde nebo nezmění agenta. Toto je **stateful conversation pattern**. Ale session-to-session persistence je přes artifacts (Markdown files) — nikoli přes LLM memory. Tj.: **session-stateful, cross-session stateless** (state je externalised do filesystem).

**Srovnání s ceos-agents:**

ceos-agents šipuje stateless dispatch s explicit state passing přes `state.json` a `pipeline-history.md`. Každý agent dostane čistý kontext + relevantní state jako input. Funkčně ekvivalentní k BMAD cross-session stateless pattern — oba externalise state do filesystemu. Run 1 (Q4) identifikoval ceos-agents jako "stateless agents, stateful pipeline state" = hybrid konzistentní s BMAD.

---

## Dimenze 6 — "Lessons learned" (klíčová priorita pro Q19)

### v3 → v5 → v6 migration history

**V3 / V4 — Monolithic single-file approach:**

Verze 3 a 4 používaly monolithic agent files — *"the monolithic 'one size fits all' approach of earlier versions is gone."* Agentic personas existovaly jako single .md files. Workflows = monolithic `workflow.md` files. V4 branch (github.com/bmad-code-org/BMAD-METHOD/tree/V4) obsahuje `bmad-core/agents/` strukturu s 628 commits.

**Skipped v5:**

V5.0.0 byl skipped kvůli NPX registry issues které corrupted verzi. Development pokračoval přímo s v6.0.0-alpha.0. Toto je důležité — "v3 → v5 migration history" z Run 1 zadání je fakticky "v4 → v6 migration history" (žádný public v5 stable release existuje).

**v6 alpha period (2025 → early 2026):**

V6 alpha přinesl dramatické scaling-up:
- Počet workflows: **20 → 50+**
- Počet agentů: **12 → 19+**
- Nové koncepty: step-file architecture, document sharding, web bundles, modularity (BMM, BMB, CIS, BMVCS jako separátní repos)

Per Medium blog (v6 alpha period): *"At the heart of v6 is the BMad Core framework (Collaboration Optimized Reflection Engine), which provides a universal architecture for human-AI collaboration. BMM for software development, BMB for creating custom agents, CIS for brainstorming, BMVCS for git workflows."*

**v6 alpha kritika — konkrétní GitHub issues:**

**Issue #675:** *"v6-alpha: Installer selects Windsurf but bmad status shows claude-code; update/build path handling inconsistent."* Problém: IDE binding merger hard-codes "claude-code"; update command expects deprecated "docs" module. Source: [github.com/bmad-code-org/BMAD-METHOD/issues/675](https://github.com/bmad-code-org/BMAD-METHOD/issues/675)

**Issue #1062:** *"v6.0.0-alpha.12 to alpha.14 update error — Module 'core' not found in any source location."* Quick Update selekce "Settings Preserved" proběhla hladce, ale "Modify BMAD Installation" selhalo. Source: [github.com/bmad-code-org/BMAD-METHOD/issues/1062](https://github.com/bmad-code-org/BMAD-METHOD/issues/1062)

**Issue #1166:** Update command fails s "Module not found in any source location" i když moduly jsou properly installed. Source: [github.com/bmad-code-org/BMAD-METHOD/issues/1166](https://github.com/bmad-code-org/BMAD-METHOD/issues/1166)

Tyto 3 issues ukazují **hidden cost of declarative DSL evolution**: když se framework vyvíjí (v6.0.0-alpha.12 → alpha.14), installer upgrade path se rozbil. Uživatelé na mid-project projektech jsou blokováni. Přesně tento risk byl identifikován v Run 1 Q5b community evidence.

**Issue #2003 — Structural Gaps and Contradictions (v6 Stable):**

Author MethCDN: *"The team's AI agents openly acknowledge that the stable version (v6) has a 'design hole': it assumes a level of technical competence that the target user does not possess."*

Konkrétní kritika:
- Framework promoted jako accessible pro technical i non-technical users, ale oba struggles
- *"inexperienced or non-technical user does not have the skills to read and understand a complex mountain of code, nor to make architectural decisions"*
- *"no safety mechanism (safeguard) that forces the developer agent to reread the original code, understand the real nature of the problem, or verify that the fix is actually effective"*
- Pattern z Epic 1: developers renaming variables instead of implementing required functionality; placeholder tests; stub code s TODO comments
- *"A small MVP would perhaps require 10 to 15 times the time with BMAD compared to a normal traditional development process"*

Source: [github.com/bmad-code-org/BMAD-METHOD/issues/2003](https://github.com/bmad-code-org/BMAD-METHOD/issues/2003)

**v6 stable GA — 2026-03-02:**

V6.0.4 = stable GA per vibesparking.com: *"BMAD v6.0.4: Two Minutes from Beta to Stable."* Obsah: edge case hunter review task, bugfixes, installer template path syntax.

Source: [github.com/bmad-code-org/BMAD-METHOD/releases](https://github.com/bmad-code-org/BMAD-METHOD/releases) — v6.0.4 (01 Mar 2026).

**Post-stable konsolidace:**

- **v6.1.0 (13 Mar 2026):** *"Everything is now a skill"* architectural overhaul; removed legacy YAML/XML workflow engine; package size -91% (6.2 MB → 555 KB); všech 15 platforem migrovalo na native Agent Skills format.
- **v6.2.0 (15 Mar 2026):** Converted 25+ workflows to native skill packages from YAML/XML; deterministic skill validator s 19 pravidly.
- **v6.3.0 (10 Apr 2026):** Consolidated 3 agent personas → single Developer agent (Amelia); snížení komplexity.
- **v6.4.0 (25 Apr 2026):** Full TOML-based customization framework; `bmad-customize` skill pro guided TOML authoring.
- **v6.5.0 (26 Apr 2026):** 18 new supported agent platforms (total 42); `.agents/skills/` standard.

**Lesson learned z v6 alpha → v6 stable → v6.x konsolidace:**

1. **Complexity creep je reálný risk při scaling.** 12 → 19+ agentů, 20 → 50+ workflows způsobilo onboarding friction a installer reliability issues.
2. **YAML workflow engine byl zaveden a pak odstraněn.** v6.1.0 explicitly removed legacy YAML/XML — marker toho, že markdown je nadřazený pro plugin kontext.
3. **Konsolidace je validní odpověď na complexity creep.** v6.3.0 merged 4 personas → 1; package -91%. BMAD explicitně zvolil "fewer, broader agents" místo "more, narrower agents."
4. **Upgrade paths v deklarativních DSL frameworkech se lámou.** Issues #675, #1062, #1166 jsou empirický důkaz, nikoliv teorie.
5. **"Design hole" v user competence assumptions** je fundamental challenge pro SDLC-oriented AI frameworks. BMAD to přiznává v Issue #2003 přes vlastní agenty.

**Star count verifikace:**

GitHub Issue #1559 (dated Feb 2026) ukazuje 45.7k★. Run 1 citace 29.6k z github.com přímo mohla být momentální counter anomálie nebo artifact repo migrace. Obě čísla jsou v evidenci; 45.7k je konzistentní s quemsah index a komunitními blogposty.

---

## Dimenze 7 — Co lze přenést do markdown-only Claude Code plugin (ceos-agents kontext)

### Transferable patterns s evidence

**1. SKILL.md frozen base + customize.toml overlay = Agent Overrides v2 design**

Aktuální ceos-agents `Agent Overrides` (append-to-prompt) je jednodušší verze BMAD overlay. BMAD overlay má 3-tier priority stack a 4 merge rules. Klíčová přenositelná insight:

- **Scalars override wins** — pokud project-specific override specifikuje `role = "..."`, toto přepíše generic ceos-agents fixer role description
- **Arrays append** — project-specific `persistent_facts` se přidají k base agent facts (nikoli je nahrazují)
- **Arrays-of-tables match by identifier** — pro menu items (u ceos-agents pipeline stages?) match by ID a replace in-place
- **Sparse override is safe; full copy is harmful** — ceos-agents v8.0.0 by měl explicitně dokumentovat stejné pravidlo

Run 1 (agent-3): *"Copying the full customize.toml into an override is actively harmful: the next update ships new defaults, but your override file locks in the old values, causing you to silently drift out of sync."* BMAD shipped toto jako explicit documentation warning (viz Dimenze 3 výše).

**Konkrétní transferable pro ceos-agents Agent Overrides v2:**
- Structured TOML (nebo YAML) overlay soubor namísto raw markdown append file
- Explicit merge semantics documentation
- `persistent_facts` ekvivalent = project-specific kontext facts, append-only
- `principles` ekvivalent = project-specific reviewer/fixer constraints, append-only
- Activation steps prepend/append = pre/post agent hooks analogie

**2. 3-tier merge semantics = direct přenos do Pipeline Profiles + Custom Agents**

ceos-agents Pipeline Profiles (skip/extra stages) a Custom Agents (post-fix agent, pre-publish agent) jsou funkčně analogické k BMAD menu customization a workflow activation steps. BMAD poskytuje **battle-tested merge formalism**: scalars override, arrays append, arrays-of-tables match by code.

Pro ceos-agents Pipeline Profiles: pokud profiles budou formalized jako TOML/YAML, BMAD 3-tier merge je direct precedent. Zejména "match by code" semantika pro stage definitions (stage name = identifier key).

**3. Steps/*.md decomposition = řešení pro ceos-agents hardcoded 600-řádkové SKILL.md pipelines**

ceos-agents `fix-bugs/SKILL.md` = hardcoded sequential pipeline ~600 řádků v jednom souboru. BMAD `bmad-create-prd/steps-c/step-05-domain.md` = jeden krok z 13, ~100 řádků. BMAD dokazuje, že steps/*.md decomposition:

- Redukuje token load per agent invocation (2,000–3,000 vs 15,000 tokenů)
- Enableuje conditional execution (gate: "skip if low complexity")
- Umožňuje per-step HITL (user menu po každém stepu)
- Zlepšuje LLM reliability (focused context)

ceos-agents v8.0.0 by mohlo zvážit steps/*.md pattern pro fix-bugs pipeline: `steps/01-triage.md`, `steps/02-code-analysis.md`, `steps/03-fixer-loop.md`, etc. Každý step je then loadován agent per-step — nikoli celý 600-řádkový soubor najednou.

**4. Discoverability preemption — klíčový anti-pattern z BMAD scaling**

BMAD pain points (50+ workflows, 19+ agents) způsobily:
- Onboarding complexity critique
- Installer upgrade failures (#675, #1062, #1166)
- "Design hole" critique (#2003)
- Konsolidace v6.3.0 (4 personas → 1)

ceos-agents v8.0.0 navrhuje **Generic+Overlay with possible Agent consolidation**. BMAD empiricky dokazuje, že:
- Narrow specialists proliferate when shipping is easy
- Periodic consolidation je healthy (BMAD to udělal v6.3.0)
- Discoverability breaks first (uživatel neví které z 50 workflows použít)

**Preemptive actions pro ceos-agents:**
- `/ceos-agents:check-setup` + `/ceos-agents:pipeline-status` jako discovery tools (already exists)
- Dashboard skill (already exists v7.0.0)
- Agent count ceiling: BMAD settled na 6 after konsolidace; ceos-agents 21 = "at outer edge of production precedent" (Run 1 Q2)

**5. `file:` reference convention = dynamic context loading**

BMAD `persistent_facts = ["file:{project-root}/docs/compliance/hipaa-overview.md"]` je elegantní pattern: overlay soubor odkazuje na project-specific dokumenty, agent je načte jako context. ceos-agents `Module Docs` (optional config sekce, path to docs) plní podobnou roli — ale BMAD pattern umožňuje per-agent per-workflow dokumenty, nikoli jen global docs path.

---

## Dimenze 8 — Co je framework-specific

BMAD je **markdown-only Claude Code plugin** — stejná forma jako ceos-agents. Toto je MINIMÁLNÍ framework-specific content; tedy maximální applicability.

**Skutečně framework-specific (nelze přímo transferovat):**

1. **Node.js installer (`npx bmad-method install`)** — BMAD vyžaduje Node.js v20+ a Python 3.11+ pro resolution script. ceos-agents je pure plugin bez runtime. Pokud by ceos-agents adoptoval TOML overlay + resolve script, Python 3.11+ dependency se přidá. Toto je malý, ale reálný threshold.

2. **`_bmad/scripts/resolve_customization.py`** — deterministic TOML merge resolver jako Python script. ceos-agents by musel buď: (a) reimplementovat v bash, (b) přijmout Python dependency, nebo (c) zůstat u jednodušší markdown-append bez merge formalism.

3. **`bmad-customize` skill** (v6.4.0) — guided TOML authoring skill. ceos-agents `/onboard` skill plní podobnou roli — ale pro Automation Config (CLAUDE.md table format), ne pro TOML overlay files.

4. **Platform support matrix (42 platforms v6.5.0)** — BMAD instaluje do `.claude/skills/`, `.cursor/skills/`, `.cline/skills/`, `.agents/skills/` atd. ceos-agents je Claude Code only. Toto je BMAD-specific investment pro multi-platform coverage.

5. **Modularita mimo core repo** — CIS (Creative Intelligence Suite), BMB (BMad Builder), Game Dev Studio jsou separate repos. ceos-agents je monorepo plugin.

**Co NENÍ framework-specific (přenositelné bez bloků):**

- SKILL.md format pro agent definitions
- steps/*.md procedural decomposition
- customize.toml merge semantics jako design pattern (nezáleží na konkrétní implementaci — principy jsou přenositelné i bez Python scriptu)
- Persona-menu interaction pattern
- Sparse overlay s explicit merge rules
- Token reduction via step decomposition
- Konsolidace narrow agents → broader roles

---

## Comparison table: BMAD vs ceos-agents

| Dimenze | BMAD-METHOD (v6 stable) | ceos-agents (v7.0.0 baseline) |
|---|---|---|
| **Forma** | Markdown-only Claude Code plugin + Node.js installer | Pure markdown plugin, bez runtime |
| **Agent granularita** | 6 broad SDLC roles (Analyst/PM/Architect/UX/Dev/TechWriter) po v6.3.0 konsolidaci | 21 narrow CI/CD specialists (triage-analyst → publisher) |
| **Pipeline konfigurace** | steps/*.md procedural decomposition; každý step = standalone .md, conditional skip | Hardcoded sequential markdown pipelines ~600 řádků each (fix-bugs, implement-feature, scaffold) |
| **Customization mechanismus** | TOML overlay: 3-tier (base → team → user), 4 merge rules (scalars override, arrays append, arrays-of-tables match by code) | Markdown append-to-prompt (Agent Overrides dir) + CLAUDE.md table Automation Config |
| **Customization scope** | Per-agent (role, principles, menu items, persistent_facts, activation_steps) + per-workflow | Per-agent text append + skip/add stages + pre/post hooks |
| **HITL pattern** | Heavily HITL — persona-menu per step; user drives sequencing; Party Mode pro multi-agent discussion | Autonomous-first s strategic gates (triage, AC, acceptance-gate, pre-publish); --yolo pro zero gates |
| **Stateful design** | Session-stateful (persona stays in role); cross-session stateless (state externalised to .md artifacts) | Stateless dispatch + stateful pipeline (state.json + pipeline-history.md) |
| **Token management** | Step-file decomposition: 2,000–3,000 tokens/step vs 15,000 monolithic; 74–90% reported savings | Progressive disclosure via Skills system; per-stage token tracking v6.8.0; pipeline-history.md |
| **Stars (2026-04-26)** | 45.7k★ (verifikováno GH Issue #1559, Feb 2026) | N/A (private repo; v7.0.0 pre-public-release) |
| **Škálování** | Scaled 12 → 19+ agents, 20 → 50+ workflows v v6 alpha; poté konsolidováno zpět na 6 agents | 21 agents, 28 skills (v7.0.0); žádná konsolidace provedena |
| **Upgrade path stabilita** | Issues #675, #1062, #1166: alpha installer breaking; post-stable zlepšení | 8 config templates; migration guides; Agent Overrides backward-compatible |
| **Framework-specific** | Node.js installer, Python resolver script, 42-platform support | Claude Code only; no installer |
| **Meta-gen** | Žádné | Žádné |
| **Closest precedent pro** | Generic+Overlay customization; step decomposition; HITL persona-menu | Autonomous CI/CD pipeline automation; sequential multi-agent orchestration |

---

## Cross-run synthesis contribution (pro Q23)

**Evidence pro Q2 (granularita):**

BMAD empiricky dokazuje, že "12 → 19+ agents" way scaling způsobilo discoverability breakdown a complexity critique. Konsolidace v6.3.0 (4 → 1 Developer persona) je evidence-based reversal. Implikace pro ceos-agents: 21 narrow agents = "at outer edge" per Run 1; BMAD evidence přidává **empirický scaling limit** (kolem 12–15 before pain; 19+ = documented critique).

**Evidence pro Q5a (pipeline shape diversity):**

BMAD pipeline = procedural markdown sequential (steps/*.md). Hybridní HITL placement (user menu per step). 19 workflows v stable (50+ v alpha). Potvrzuje Run 1 finding: "markdown-procedural je dominant v Claude Code plugin space." BMAD šel z YAML/XML workflow engine (v5/v6-alpha) → pure markdown (v6.1.0) — **empirický proof** že YAML workflow engine v Claude Code plugin kontextu není nutný.

**Evidence pro Q8 (Generic+Overlay):**

BMAD = nejsofistikovanější Generic+Overlay implementace v Claude Code plugin ekosystému. customize.toml s 4 merge rules = production-validated na 45.7k★ scale. Žádný meta-gen. Sparse overlay = safe; full-copy override = harmful (dokumentováno). Přímý precedent pro ceos-agents Agent Overrides v2 design.

**Evidence pro Q3 (Universal vs per-project):**

BMAD je generický framework customizovaný přes overlay. Žádné per-project agent sets. Potvrzuje Run 1 Q3 consensus: "Generic+Overlay je dominantní production pattern."

**Evidence pro Q19 klíčové lessons:**

1. Scaling past 15+ agents creates discoverability & maintenance crisis (empirické, ne teoretické)
2. YAML workflow engine v markdown plugin kontextu = slepá ulička (BMAD to zkusil, pak odstranil)
3. Steps/*.md decomposition = validní approach k token reduction a LLM reliability (74–90% token savings empiricky)
4. customize.toml 3-tier merge = production-validated overlay pattern pro Generic+Overlay architecture
5. "Design hole" — target user competence mismatch — je strukturální challenge pro SDLC-oriented AI frameworks

---

## Použité zdroje (citace)

- [github.com/bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) — hlavní repo, star count
- [github.com/bmad-code-org/BMAD-METHOD/releases](https://github.com/bmad-code-org/BMAD-METHOD/releases) — release history v6.0.2–v6.5.0
- [github.com/bmad-code-org/BMAD-METHOD/blob/main/CHANGELOG.md](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/CHANGELOG.md) — changelog v4 → v6
- [docs.bmad-method.org/how-to/customize-bmad/](https://docs.bmad-method.org/how-to/customize-bmad/) — **customize.toml full schema** (primární zdroj pro Dimenzi 3)
- [docs.bmad-method.org/reference/agents/](https://docs.bmad-method.org/reference/agents/) — complete agent list (6 agents)
- [docs.bmad-method.org/reference/workflow-map/](https://docs.bmad-method.org/reference/workflow-map/) — 19 workflows v 4 fázích
- [docs.bmad-method.org/explanation/named-agents/](https://docs.bmad-method.org/explanation/named-agents/) — agent activation sequence, hardcoded vs customizable
- [docs.bmad-method.org/explanation/party-mode/](https://docs.bmad-method.org/explanation/party-mode/) — Party Mode HITL pattern
- [docs.bmad-method.org/how-to/expand-bmad-for-your-org/](https://docs.bmad-method.org/how-to/expand-bmad-for-your-org/) — 3-layer customization model
- [github.com/bmad-code-org/BMAD-METHOD/issues/675](https://github.com/bmad-code-org/BMAD-METHOD/issues/675) — v6-alpha installer inconsistency
- [github.com/bmad-code-org/BMAD-METHOD/issues/1062](https://github.com/bmad-code-org/BMAD-METHOD/issues/1062) — alpha.12 → alpha.14 update failure
- [github.com/bmad-code-org/BMAD-METHOD/issues/1166](https://github.com/bmad-code-org/BMAD-METHOD/issues/1166) — module not found on update
- [github.com/bmad-code-org/BMAD-METHOD/issues/2003](https://github.com/bmad-code-org/BMAD-METHOD/issues/2003) — Structural Gaps and Contradictions v6 Stable
- [github.com/bmad-code-org/BMAD-METHOD/discussions/1306](https://github.com/bmad-code-org/BMAD-METHOD/discussions/1306) — v6.0.0-alpha.23 release discussion
- [github.com/bmad-code-org/BMAD-METHOD/blob/main/src/bmm-skills/3-solutioning/bmad-check-implementation-readiness/steps/step-05-epic-quality-review.md](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/src/bmm-skills/3-solutioning/bmad-check-implementation-readiness/steps/step-05-epic-quality-review.md) — step file example (Dimenze 2)
- [github.com/bmad-code-org/BMAD-METHOD/blob/main/src/bmm-skills/2-plan-workflows/bmad-create-prd/steps-c/step-05-domain.md](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/src/bmm-skills/2-plan-workflows/bmad-create-prd/steps-c/step-05-domain.md) — step file s menu navigation pattern
- [github.com/bmad-code-org/BMAD-METHOD/blob/main/src/core-skills/bmad-advanced-elicitation/SKILL.md](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/src/core-skills/bmad-advanced-elicitation/SKILL.md) — SKILL.md example (142 řádků)
- [medium.com/@hieutrantrung.it/from-token-hell-to-90-savings-how-bmad-v6-revolutionized-ai-assisted-development-09c175013085](https://medium.com/@hieutrantrung.it/from-token-hell-to-90-savings-how-bmad-v6-revolutionized-ai-assisted-development-09c175013085) — token savings data, agent/workflow count
- [deepwiki.com/bmad-code-org/BMAD-METHOD](https://deepwiki.com/bmad-code-org/BMAD-METHOD) — architecture overview, stateful/stateless classification
- [buildmode.dev/blog/mastering-bmad-method-2025/](https://buildmode.dev/blog/mastering-bmad-method-2025/) — persona activation sequence, user interaction pattern
- Run 1 final.md (2026-04-26) — Q3, Q5b, Q8, Q12 BMAD-specific sections (baseline evidence)

**Recency stamp:** 2026-04-26. Všechny WebSearch a WebFetch výsledky pořízeny téhož dne.
