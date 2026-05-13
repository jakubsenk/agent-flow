# CEO Presentation Narrative — ceos-agents (v7 → v9 + ACT relace)

**Datum brainstormu:** 2026-04-27
**Autor:** Filip Šabacký
**Audience:** CEO (AI-savvy, používá starší verze ceos-agents) + 1 technický kolega
**Cíl prezentace:** Společné rozhodnutí, co změnit pro rychlejší public release ceos-agents zdarma (marketing + community contributions). Plus uchopit interní rollout (zavádění do firemních týmů bez hluboké AI zkušenosti).
**Forma:** Whiteboard, dlouhá decision-making session (~75-90 min, ~5-7 hlavních bloků + 6-9 diagramů)
**Tone:** Expert-to-expert, vykání, bez marketingového jazyka, comparative s trhem
**Konvence:** Komunikace v češtině; obsah souborů v angličtině (ceos-agents projektová konvence)

---

## Strategie narrativu

Chronologická "evoluce" s decision frame na začátku a konci. Příběh: vize → research → pivot → realizace → otevřené body. CEO uvidí, že rozhodnutí vznikla **na základě dat**, ne ego abandon. Pivot meta-agent → overlay je nejsilnější narrative beat.

Dva paralelní tlaky na produkt, oba ho vedou stejným směrem:
- **Public release** (zkušení devs, světový trh, marketing + community)
- **Interní rollout** (kolegové bez hluboké AI zkušenosti, AI-nepolíbení)

Insight: optimalizujeme-li pro těžší target (interní non-AI lidi), dostaneme i lehčí target zdarma. Rozhodujeme jen jednou.

---

## Sekce 1 — Otevření / Decision frame (3 min)

### Co řekneš

> *"Dneska se chceme dohodnout, co s ceos-agents udělat, aby šly co nejdříve veřejně zdarma — primárně jako reklama na nás a sekundárně s nadějí, že komunita přinese vylepšení. Zároveň ceos-agents zavádíme do dalších týmů ve firmě, mezi kolegy bez hluboké AI zkušenosti — produkt potřebuje úpravy, aby ho zvládli i nezkušení uživatelé. Tyhle dva tlaky — public release a interní rollout — vedou produkt stejným směrem (jednoduchost, onboarding, robustnost), takže rozhodujeme jen jednou. Abyste mohl dobře rozhodnout, potřebujete celý koncept ucelně. Trávil jste s tím chvíle a viděl jste části — claude-grade jste viděl, ceos-agents znáte dobře, filip-superpowers jste slyšel. Dneska propojím, jak to celé do sebe zapadá, a proč to vypadá tak, jak vypadá. Na konci vám otevřu otevřené otázky, kde vás potřebuju."*

### Co napíšeš na tabuli (Diagram 1 — Mapa session)

```
DNES:
1. Co je ceos-agents (architektura)
2. Proč filip-superpowers a forge
3. Evoluce vize: meta-agent + claude-grade → overlay
4. Co jsme dělali posledně (v7.0.0 + v8.0.0 — hlavní změny)
5. Kam směřujeme: v9.0.0 launch → v10.0.0 možnosti
6. ROZHODNUTÍ: public release + interní rollout — co cuttovat?

DVA PARALELNÍ TLAKY:
  → Public (zkušení devs)
  → Interní (AI-nepolíbení)
  Optimalizujeme pro těžší → dostaneme oba.
```

### Čeho se vyhnout

- Marketingový jazyk
- "Slepá ulička" / "chyba" rétorika
- Tykání
- Stavění public a interního proti sobě (nejsou konkurence — jsou paralelní cesty)

---

## Sekce 2 — Co je ceos-agents (architektura, 12 min)

### Co řekneš

> *"Začnu od základu, protože budu navazovat. ceos-agents je Claude Code plugin — tedy běží v rámci platformy Anthropic Claude Code, kterou znáte. Plugin distribuujeme přes marketplace, instalace je jeden příkaz. Architektura je dvouvrstvá: skills jsou orchestrátory (vědí CO udělat), agenti jsou specialisté (vědí JAK). 21 agentů, 28 skills. Žádný runtime kód — všechno je markdown s YAML frontmatter, který Claude Code interpretuje. To je důležitý positioning bod: 100 % top-15 Claude Code pluginů používá markdown. BMAD-METHOD (45 700 hvězd) v březnu 2026 dokonce odstranili YAML workflow engine ve verzi 6.1.0, package -91 %. My jsme markdown nikdy neopustili."*
>
> *"Pipeline je sekvenční — to je vědomá volba proti paralelním orchestracím (Cursor 3.2 má 8 paralelních agentů ve worktrees, Anthropic Team Lead Feb 2026 má peer-to-peer messaging). Náš důvod: bug-fix je sekvenční úkol — triage → analýza dopadu → fix ↔ review → test → publish. Paralelizace tady přidává koordinační režii (research z Free-MAD: paralelní bez koordinace = 17.2× error amplification vs 1× single agent). Sekvenční s 21 specializovanými agenty (po v8.0.0 18) — víc než kdokoli na trhu. BMAD má 6, Devin 4, Cursor specialized modes."*

### Diagram 2 — Architektura

```
        CLAUDE CODE PLATFORM (Anthropic)
        ↓ (plugin marketplace)
        ceos-agents PLUGIN (markdown + YAML)
        ↓
  ┌─────────────────────────────────────┐
  │ SKILLS (28) — orchestrátoři         │  → "CO"
  │ /fix-ticket, /implement-feature,    │
  │ /scaffold, /autopilot, /publish,... │
  └─────────────────────────────────────┘
        ↓ dispatch
  ┌─────────────────────────────────────┐
  │ AGENTI (21 → 18 v v8.0.0)           │  → "JAK"
  │ opus: fixer, reviewer, architect    │
  │ sonnet: triage, code-analyst, test  │
  │ haiku: publisher, rollback          │
  └─────────────────────────────────────┘
        ↓ runtime
  Anthropic API (Opus 4.7 / Sonnet 4.6 / Haiku 4.5)

KLÍČOVÉ: 0 řádků runtime kódu. Všechno markdown.
```

### Diagram 3 — Bug-fix pipeline flow

```
Issue tracker (YouTrack/Jira/Linear/Gitea/Redmine/GitHub)
    ↓
TRIAGE (sonnet) → AC extraction, complexity, repro steps
    ↓
CODE-ANALYST (sonnet) → impact map, ≤5 affected files
    ↓
[Pre-fix hook]
    ↓
FIXER (opus) ↔ REVIEWER (opus)   max 5 iterací
    ↓                              ↑
    ↓ ← block-rollback (haiku) ←   │
    ↓
[Post-fix hook] → smoke test (build + test)
    ↓
TEST-ENGINEER (sonnet)
    ↓
[Acceptance gate] (AC ≥ 3 OR complexity ≥ M)
    ↓
[Pre-publish hook]
    ↓
PUBLISHER (haiku) → PR with template
    ↓
Verify command (post-merge) → reopen if fail
```

### Klíčové body (co CEO musí pochopit)

1. **Plugin model = my žijeme uvnitř Claude Code**, neběhme samostatně. Důsledek: distribuce přes Anthropic marketplace (110k+ devs/měs visit), constraint = nelze používat hooks/MCP v agent frontmatter (Run 2 Oprava 2). To vysvětluje, proč máme skill-orchestraci.
2. **Markdown je strategická volba.** 100 % top-15 plugins, AGENTS.md je AAIF-stewarded, BMAD reverted z YAML v 6.1.0 (březen 2026, package -91 %). Microsoft Agent Framework jde naopak (enterprise YAML, 1.0 GA Apr 6 2026) — to je jiná tržní část (enterprise .NET/Python), ne plugin space.
3. **Sekvenční pipeline + 18 specializovaných agentů** = pozice mezi single-agent generalistou (Devin, Cursor, Cline) a paralelní orchestracemi (Cursor 3.2, Anthropic Team Lead). Každý agent má jednu věc. Reviewer ↔ fixer iteruje (max 5 cyklů).
4. **Model tiering Opus/Sonnet/Haiku** = cost-aware už dnes. Opus 4.7 GA Apr 16 2026 přinesl ~35 % víc tokenů per token (nový tokenizer) → cost efektivně vzrostl.

### Čeho se vyhnout

- "Plugin = jen nástroj" — to neumí přenést konkurenční pozici
- Detailní popis každého agenta (na tabuli vyjmenovat 3-4 nejvýraznější: fixer, reviewer, triage, publisher)
- Tykání

---

## Sekce 3 — Proč filip-superpowers a forge (12 min)

### Co řekneš

> *"Když ceos-agents začínalo, dělal jsem ho ad-hoc — psal jsem agenty rukou, testoval, opravoval, iteroval. Brzo jsem narazil na strop kvality: LLM přijde s něčím, co vypadá dobře, já to zkontroluju, něco opravím, a 3 týdny později zjistím, že verze 5.x má 41 testů, které jsou jen doc-string grepy, ne skutečné testy. To je přesně to, před čím varuje Karpathy v eseji o 'Vibe Coding' — bez evaluace nemáš pipeline, máš jen iluzi."*
>
> *"filip-superpowers je můj soukromý plugin, fork komunitního superpowers Jesseho Vincenta — což je dnes #2 nejpoužívanější Claude Code framework, 121 tisíc hvězd. Vincent po Lednu 2026, kdy ho Anthropic přijal do oficiálního marketplace, akcentoval u všech: 'don't trust LLM output without process'. Přesně z toho vychází i moje filip-superpowers."*
>
> *"Forge je v té paměti core orchestrace — multi-fázová pipeline pro vývoj komplexních věcí. 10 fází: research → brainstorm → spec → TDD → plan → execute → verify. Pro kontext: tahle prezentace, kterou připravujeme, zrovna teď jede v jedné z těch fází (brainstorming). v6.9.0 ceos-agents byla forged, v6.10.0 forged, v7.0.0 právě běží paralelně přes forge, v8.0.0 specs jsou hotové. Nezapisujeme features, forge-ujeme je."*

### Diagram 4 — Forge pipeline architektura

```
forge — JAK to vlastně dělá agenty a zadání
─────────────────────────────────────────────

  Phase 0  Routing gate          User vstup → klasifikace task type → výběr fází
                                 (Phase subset varies: bug ≠ feature ≠ research)

  Phase 1  Research questions    1 LEAD agent (sonnet) generuje 5-25 otázek
                                 (rozkládá problém: technical/market/risks/edge)

  Phase 2  Research answers      N PARALELNÍCH agentů (sonnet) — 1 agent / 1 otázka
                                 5 lenses: academic, production, OSS code, community,
                                 vendor docs → každý má SVŮJ briefing prompt
                                 → synthesis agent (opus) sloučí + zhodnotí

  Phase 3  Brainstorm            3 PROPOSALS — heterogenní agenti (conservative,
                                 innovative, skeptical) → JUDGE (opus) rozhodne

  Phase 4  Spec (EARS)           1 SPEC-WRITER (opus) → 3 PARALELNÍ REVIEWERS
                                 (spec-compliance, quality, devils-advocate) →
                                 max 3 revize cycle, gate decision

  Phase 5  TDD                   TEST-WRITER (sonnet) generuje testy ZE SPECU,
                                 ne z kódu → mutation gate 70% kill rate → hidden
                                 test reserve (20%) drží neviditelný benchmark

  Phase 6  Plan                  PLAN-WRITER (opus) → dependency graph →
                                 paralelizovatelné tasky identifikovány

  Phase 7  Execute               N PARALELNÍCH FIXERS (opus) v isolated worktrees
                                 → každý task má vlastní ↔ REVIEWER smyčku

  Phase 8  Verification          5 PARALELNÍCH verifikátorů: security, correctness,
                                 spec-alignment, robustness, devils-advocate →
                                 COMMANDER VERDICT (opus) agreguje skóre 0-1

  Phase 9  Completion            Changelog, version-bump, tag

  Phase 10 (gates)               3 user approval points

JAK FORGE TVOŘÍ AGENTY:
- Každá fáze má TEMPLATE prompt (markdown soubor) s placeholders
- Substituce: {task}, {research_findings}, {spec_path}, {file_list}
- Multi-agent dispatch: parent skill volá Task() N-krát s jiným zadáním
- Heterogenita = záměrně různé "lenses" (vyhýbáme se group-think, viz Free-MAD)

JAK FORGE DĚLÁ ZADÁNÍ:
- Phase 0 routing analyzuje user vstup, vybírá fáze (bug-fix neskáče celé 10 fází)
- Phase 1 LEAD agent rozloží task na ≤25 zkoumatelných otázek (decomposition)
- Spec phase generuje EARS-format requirements (machine-checkable: WHEN/WHILE/IF)
- Plan phase generuje task graph s blokádami a paralelismem
```

### Diagram 5 — Cross-plugin dogfooding

```
filip-superpowers (forge)        ceos-agents
────────────────────────         ──────────────
"jak vyvíjím" ─────dělá───────► "co vyvíjím"

ceos-agents (Claude Code plugin)  → end-user fixne bug → PR
forge (vývojový proces)           → developer (já) forge-uje feature → commit

OBĚ POUŽÍVAJÍ STEJNÉ PRINCIPY:
- multi-fázová pipeline
- specializovaní agenti
- verifikace > inspekce
- evaluace na konci
```

### Anthropic 5 patternů — proč ceos-agents bug-fix pipeline používá jen 3

| Pattern | Co dělá | ceos-agents bug-fix | Proč / proč ne |
|---------|---------|---------------------|----------------|
| **Routing** | Vstup → výběr handler | **Ano** | `/workflow-router` → fix-ticket / implement-feature / scaffold |
| **Chaining** | Sekvenční LLM volání | **Ano** | triage → code-analyst → fixer → reviewer → test → publish |
| **Parallelization** | Více agentů paralelně | **Ne (záměrně)** | Bug-fix je sekvenční; paralelizace přidá koordinační režii. Free-MAD: nezkoordinovaná paralelizace = 17.2× error amplification |
| **Orchestrator-workers** | Lead + sub-agenti | **Ne** | ceos-agents je "skill orchestrator + flat agent list", ne hierarchie. Jednoduší debugging, ale méně rich. Plánováno možná pro v8.0.0 D5 konsolidaci |
| **Evaluator-optimizer** | Iterativní refinement | **Ano (omezeně)** | Reviewer ↔ fixer smyčka (max 5 iterací). Ne plný "evaluate → adjust prompt → retry" — to dělá forge phase 5 mutation gate, ne ceos-agents |

**Proč nepoužíváme všech 5:** ceos-agents není obecný framework, je to **specializovaná pipeline pro bug-fix / feature / scaffold**. Pro ten task type je sekvenční chaining + iterativní review nejvhodnější. Forge naopak používá všech 5 — protože dev process je obecnější. Tohle je pozice, ne nedostatek.

### Reálná skepse k autonomii (honest acknowledgment)

> *"Vím, co lidé říkají o filip-superpowers a podobných nástrojích — že nerozumí té autonomii, nevěří jí, že to lze použít jen na část práce, že stejně musí připravit zadání. Ten pocit je oprávněný, a já souhlasím."*
>
> *"Forge NENÍ 'klikni a hotovo'. Tady je realita:*
> - *Já píšu počáteční zadání (1-3 odstavce). Forge to nedělá za mě.*
> - *Po fázi 1-3 (research → brainstorm) je gate — schvaluju směr. Forge se zeptá, ne diktuje.*
> - *Po fázi 4 (spec) je gate — schvaluju formální požadavky.*
> - *Po fázi 6 (plan) je gate — schvaluju task graph.*
> - *Phase 8 verification odhalí ~5-15 % chyb i v tom, co projde phase 7 → fix → re-verify.*
>
> *Tedy: forge je 'discipline collaborator', ne 'autonomous engineer'. Vyřeší 70-80 % typing, validuje, vede strukturu. Ale poslední 20 % rozhodnutí, kontextu, business priority — to dělám já. Karpathy to přesně popsal: 'pull deterministic steps OUT of LLM' — gates jsou determinismus, agenty jsou kreativita."*
>
> *"Co to ale znamená pro public release ceos-agents (NE forge — ceos-agents):"*
> - *Stejně jako forge potřebuje user-prepared zadání, ceos-agents potřebuje user-prepared issue v trackeru s aspoň částečně srozumitelnou triáží.*
> - *NEEDS_CLARIFICATION mechanika (od v6.9.0) PŘESNĚ řeší pochybnosti AI — pipeline se zeptá uživatele, neimprovizuje.*
> - *Default mode má strategické gates, není to YOLO. v8.0.0 přidává `--step-mode` (per-agent pause) pro novice users.*

### Diagram 6 — ceos-agents přes forge timeline

```
Forge architektura dokončena:     2026-03-21
První forge run na ceos-agents:   2026-03-25  (+3 dny)
Dnes:                             2026-04-27  (+33 dní)

Celkem forge runů:                46
Cadence:                          ~1.4 runů / den

Documented major runs:
  v6.8.0   forge-2026-04-17-001  3.67M tokens   0.857
  v6.8.1   forge-2026-04-18-001  2.34M tokens   0.907
  v6.9.0   forge-2026-04-19-001  ~5M tokens     0.953
  v6.10.0  forge-2026-04-23-002  4.3M tokens    0.862  (~13h)
  v8.0.0   2026-04-26-A research run 1+2        (research-only)
  v7.0.0   běží paralelně                       TBD

Cumulative documented:           ~15.3M tokens (jen 4 major runy)
Cumulative odhad (46 runů):      ~20-25M tokens, ~150-200h wallclock

Earliest backup: .forge.bak-20260325-204006
Latest backup:   .forge.bak-2026-04-27T044940Z (dnes ráno)
```

### Honest disclaimer (důležité)

- **46 ≠ 46 plně dokončených pipeline.** Některé backupy jsou mid-pipeline checkpoints, jeden je explicitně `aborted`. Realisticky cca 15-25 plně dokončených pipeline-runů, zbytek partial / iterace stejného běhu.
- **Forge sám se v té době vyvíjel** — early March runy používaly proto-verzi, dnešní pipeline (10 fází + commander-verdict) se ustálila kolem v6.8.0.

### Comparison table — forge / filip-superpowers vs trh

| Nástroj | Hvězdy | Pattern | Multi-LLM | HITL gates | TDD enforced | Production deployments |
|---------|--------|---------|-----------|------------|--------------|------------------------|
| **superpowers** (Vincent, OG) | 121k | Skill-driven, 2-stage review | Claude only | Manual | Implicit | Hundreds public |
| **filip-superpowers + forge** (já) | private | 10-phase pipeline, 5-agent verification | Claude only | 3 explicit gates + auto | Mutation 70% kill rate | 1 (ceos-agents) |
| **BMAD-METHOD** | 45.7k | Persona menu, agile lifecycle | Multi (CC/Cursor/Windsurf/9+) | Persona handoffs | No | Significant adoption |
| **Anthropic Skills** (vanilla) | — (official) | Primitives, no process | Claude only | None built-in | No | Native |
| **Cursor 3.2** (Apr 24, 2026) | $2B ARR | 8 parallel agents in worktrees | Multi providers | Per-rule allow/deny | No | Massive |
| **Devin / Cognition** ($25B raise talks) | SaaS, $20/mo | Cloud orchestrator + managed units | Closed | 2 checkpoints (Plan + PR) | Implicit | Goldman Sachs etc. |
| **Cline** | 3.7M VSCode | Auto Approve → 8 categories | Multi (75+ via OpenRouter) | Granular per-action | No | Massive |
| **GitHub Copilot Coding Agent** (GA Apr 20, 2026) | bundled | Issue → Actions sandbox → PR | OpenAI / Anthropic | Self-review | Yes (in workflow) | All Copilot Enterprise/Pro+ |

**Kde forge sedí:** mezi BMAD (proces s personami, ale méně rigorózní gates) a vanilla Anthropic Skills (primitives bez procesu). **Forge unikum: 5-paralelní phase 8 verification + commander-verdict aggregator + mutation gate na phase 5 TDD.** Žádný z trhu nemá tu kombinaci.

---

## Sekce 4 — Evoluce vize: meta-agent + claude-grade → overlay (10 min)

### Co je "pivot" (krátké vysvětlení)

> *"Pivot = strategická změna směru na základě dat. Když mám původní vizi, zkoumám trh a výzkum, a oboje řekne 'tohle nikde neprodukuje produkční systémy', neignoruju to a trvám na své vizi — pivotuju. Změním směr."*

### Co je TOML (krátké vysvětlení)

> *"TOML je config formát, něco jako .ini, ale s vnořenými strukturami. Pravděpodobně ho znáte z `pyproject.toml`, `Cargo.toml`, `next.config.toml`. Pro nás to znamená: jednoduchý textový soubor, kde uživatel napíše projekt-specifická pravidla, která se mergnou nad generic agent prompt."*

### Co řekneš

> *"Tento blok je důležitý, protože vám ukáže, jak se moje myšlení vyvíjelo na základě dat. Nebyl to lineární plán → execution. Byla to vize → research → pivot."*
>
> *"Původní vize, kterou jsem měl ještě před vznikem forge: meta-agent generuje všechny agenty per-project. Tedy ne 21 generických agentů, jak je máme dnes, ale projekt-specific 21 agentů, vyladěné podle kódbáze, technologie, konvencí. Validace by probíhala nezávisle — to bylo místo, kde jste poprvé viděl claude-grade. Smyčka byla: meta-agent vygeneruje agenty per-project → claude-grade je auditem nezávislé instance LLM zhodnotí kvalitu (skóre A-F + Top 3 to fix) → meta-agent opraví → ship."*
>
> *"Krásný princip. Self-improving system, žádné generic kompromisy. Ale data ukázala něco jiného."*

### Diagram 7 — Evoluce vize

```
EVOLUCE VIZE — od meta-gen po overlay
─────────────────────────────────────────

PŮVODNÍ VIZE (Q1 2026):
   user instaluje → META-AGENT generuje 21 agentů PER PROJECT
                    → claude-grade nezávisle audituje (skóre A-F)
                    → meta-agent opraví → ship


PIVOT (po research, Q2 2026):
   ceos-agents přibaluje 21 GENERIC agentů (dnes), 18 po v8.0.0
   user spustí /setup-agents → meta-agent generuje malý TOML overlay
   → merge generic + overlay (BMAD-style 3-tier)
   → ship

   claude-grade dnes: samostatný produkt (ClaudeGrade v0.8.0), nepatří sem


CO JSOU TI AGENTI (4 kategorie, 21 dnes / 18 po v8.0.0):
─────────────────────────────────────────────────────────

  BUG-FIX (11 agentů dnes / 8 po konsolidaci):
    triage-analyst (sonnet)     ─┐  (v8: → analyst --phase triage)
    code-analyst (sonnet)       ─┘
    fixer (opus)
    reviewer (opus)
    test-engineer (sonnet)      ─┐  (v8: e2e absorbed přes --e2e flag)
    e2e-test-engineer (sonnet)  ─┘
    reproducer (sonnet)         ─┐  (v8: → browser-agent --phase reproduce/verify)
    browser-verifier (sonnet)   ─┘
    publisher (haiku)
    rollback-agent (haiku)
    acceptance-gate (sonnet)

  FEATURE / SPEC (2):
    spec-analyst (sonnet)
    architect (opus)
    (+ sdílené z bug-fix: fixer, reviewer, test-engineer, publisher)

  SCAFFOLD (5):
    spec-writer (opus)
    spec-reviewer (opus)
    stack-selector (sonnet)
    scaffolder (sonnet)
    deployment-verifier (sonnet)

  PLANNING / MANAGEMENT (3):
    priority-engine (opus)
    backlog-creator (sonnet)
    sprint-planner (sonnet)

  Distribuce: opus 6 / sonnet 13 / haiku 2 (z 21 dnes)
```

### Co data ukázala (citovatelné — pro CEO oprávněnost pivotu)

Z research (filip-superpowers `08-meta-agent-concept.md` + ceos-agents `.forge/2026-04-26-A-research-run1`):

1. **"Per-project full-duplication has zero vendor exemplars; meta-gen has zero production deployments"** — Run 1, lensový konsensus 5/5. MetaGen (arxiv 2601.19290), ADAS, MetaSynth — všechno academic-only, žádné production.
2. **"Generic+overlay (append-to-prompt or TOML merge) is the only production-validated pattern"** — Run 1. Důkazy: BMAD-METHOD `customize.toml` 3-tier pattern (45.7k★ produkce); Anthropic 5-tier subagent priority **explicitně endorses append-to-prompt overlay**; Codex Subagents TOML inherit-with-override.
3. **"LLM-as-config-interpreter is the weakest link in any meta-agent design"** — Run 2 synthesis. Tedy: meta-agent může generovat overlay (malý, kontrolovatelný), ale negenerovat celý agent prompt (velký, fragile, neudržovatelný).
4. **"Prompt optimization +6% quality vs agent scaling +3%"** — research z 01-prompt-engineering. Nevyplatí se per-project tvořit nové prompty; vyplatí se per-project doladit overlay nad ověřený generic.

### Klíčové insighty pro CEO

- **Pivot není "porážka", je to discipline.** Pokud bych pokračoval v meta-gen, šel bych proti tomu, co celý trh udělal (BMAD, Anthropic, Codex). Research ukázal, že ten směr nikde neprodukuje produkční systémy.
- **Overlay přístup ŘEŠÍ původní problém.** Cíl byl: "agenti pro tenhle konkrétní projekt". Overlay umí to samé — generic přidá projektovým specifickým instrukcím (tech stack, konvence, business pravidla) — ale bez fragility full-gen. Generic jádro je rigorózně testované (forge); overlay je malý fragment, který je řízeně rizikový.
- **`/setup-agents` = realizace nového směru.** Skill v8.0.0 D1 — naskenuje projekt, vygeneruje smart TOML defaulty, jednorázový run, idempotent. D původně součást v9.0.0 (public launch katalog), nyní absorbováno do v8.0.0, protože onboarding overlay logika patří k architecture, ne UI.
- **claude-grade JE NEZÁVISLÝ produkt.** Když jste ho viděl, byla to ještě smyčka v původní vizi. Dnes ClaudeGrade v0.8.0 je samostatný produkt (Stripe + Clerk + Neon + AI Gateway + Vercel) — AI readiness grader pro CLAUDE.md / AGENTS.md / .cursorrules ve veřejnosti. Není to ceos-agents příslušenství. Dvě nezávislé linky práce.

### Pozice vůči konkurenci

| Tool | Per-project agent strategy | Note |
|------|---------------------------|------|
| **BMAD-METHOD** | `customize.toml` overlay (3-tier merge) | Ten samý směr jako my po pivotu, **45.7k★ tržní validace** |
| **Anthropic Skills** | 5-tier subagent priority (CLAUDE.md → ./.../skill → user-level) | Append-to-prompt = explicitní endorsement overlay přístupu |
| **Codex Subagents** | TOML inherit-with-override | Ten samý vzor |
| **superpowers (Vincent)** | Primarily generic + occasional skill overrides | Méně formální overlay |
| **Cursor / Devin / Cline** | Žádný per-project agent customization (chat-driven) | Naprosto jiný UX |
| **MetaGen / ADAS** | Full per-project meta-gen | Academic only, zero production |

---

## Sekce 5 — v7.0.0 + v8.0.0 hlavní změny (15-18 min)

### Co řekneš

> *"Tohle je nejdelší blok, protože tady se rozhoduje, co je dnes ceos-agents schopné. Pokud používáte starší verzi (řekněme něco z v5-v6.7), většina toho, co teď ukážu, je nová. Aktivní vývoj soustředěně přes forge jsem začal v polovině března 2026 — to je ~6 týdnů, z toho vznikla řada v6.8 → v8.0. Nebudu vyjmenovávat všechno, vyberu ze v7 a v8 změny s největším tržním/uživatelským dopadem."*
>
> *"Princip: v7.0.0 je o čištění před public release — méně friction, méně kolizí. v8.0.0 je o architektuře — připravit produkt tak, aby ho zvládli i nezkušení uživatelé z firmy a aby udržel krok s tržními trendy (BMAD, Cline, Anthropic Skills)."*

### Diagram 8 — v7+v8 timeline

```
v7.0.0 — CLEANUP (před public release, 6 akcí)
──────────────────────────────────────────────
   Cíl: odstranit friction před zdarma launchem
   Důvod MAJOR: 4 ze 6 jsou breaking changes

   1. NAMING KOLIZE s Claude Code builtins   ← veřejný launch blocker
        /ceos-agents:status  → /pipeline-status   (kolidoval s built-in /status)
        /ceos-agents:init    → /setup-mcp         (kolidoval s built-in /init)

   2. AUTO-DETECT TRACKER v /publish         ← UX zjednodušení
        Smazán /create-pr (duplikát)
        /publish → issue ID → tracker update + PR
        /publish → bez ID → jen PR
        /publish → tracker down → fail s návodem

   3. CONFIG CLEANUP                          ← méně rozhodování pro uživatele
        Smazána sekce "Extra labels" (duplikovala PR Rules → Labels)
        Pause Limits doc fix (applies to 6 skills, ne jen autopilot)

   4. README + docs varování                  ← edukace pro novice
        Krátké slash formy (/init /status atd.) kolidují s Claude Code

   Counts: 29 → 28 skills, 19 → 18 config sekcí, 21 agentů beze změny


v8.0.0 — ARCHITECTURE REWORK (5 + 1 rozhodnutí)
─────────────────────────────────────────────────
   Cíl: novice-friendly + tržní validace + konsolidace
   Důvod MAJOR: TOML overlay + agent renamy = breaking

   D1   GENERIC AGENTS + TOML OVERLAY + /setup-agents
        Realizace pivotu z evoluce vize (Sekce 4)
        BMAD-style 3-tier merge (scalar/array/table)
        ✓ Anthropic 5-tier subagent priority endorses tento pattern
        ✓ BMAD `customize.toml` 45.7k★ produkční validace

   D2   MARKDOWN SKILLS + steps/*.md DECOMPOSITION
        Monolitické ~600-line SKILL.md → entry (~100) + steps/*.md (5-8 × 150-200)
        Token reduction ~80% (15k monolithic → 2-3k per step)
        ✓ BMAD v6.1.0 odstranil YAML workflow engine, package -91% (březen 2026)

   D3   HITL MODE FRAMEWORK (3 mode flags)
        --yolo       (zero gates, pro experty / autopilot)
        default      (strategic conditional gates)
        --step-mode  (NEW, per-agent pause — pro novice users z firmy)
        ✓ Cline Auto Approve → 8 granular categories (5 měsíců produkce)

   D4   STATELESS DISPATCH (status quo, zachováno)
        Žádná migrace. Stateless agents + externalized state (state.json + git)
        ✓ Devin "Manages Devins" (březen 2026) potvrzuje stejný pattern

   D5   21 → 18 AGENTŮ (konsolidace 3 párů)
        triage-analyst + code-analyst → analyst (--phase)
        test-engineer + e2e-test-engineer → test-engineer (--e2e)
        reproducer + browser-verifier → browser-agent (--phase)
        ✓ BMAD v6.3.0 (10. dubna 2026) merged 4 agents → 1 'Amelia' (17 dní zpět)
        ✓ Kim et al. arXiv 2512.08296: per-agent reasoning thins past 3-4 under fixed compute

   B6   SCAFFOLD MODE HARMONIZACE
        /scaffold mode flags align s A.1 (--yolo / default / --step-mode)

   D V8 ABSORBOVÁNO: /setup-agents skill je realizace toho, co bylo plánované
   jako "v9.0.0 D katalog/onboarding wizard"
```

### Klíčové insighty pro CEO

1. **v7.0.0 je všech 6 akcí "veřejná friction"**, ne nové features. Pokud bychom šli na trh bez toho, první uživatelé by hlásili: "tvoj `/init` mi přepsal Claude Code builtin". Není to glamourous práce, ale je nutná.

2. **v8.0.0 je 4 z 5 rozhodnutí TRŽNĚ VALIDOVÁNO** v posledních 30 dnech:
   - D1 overlay = BMAD customize.toml (45.7k★) + Anthropic 5-tier
   - D2 markdown = BMAD v6.1.0 YAML rollback (březen 2026)
   - D3 mode framework = Cline Auto Approve evolution
   - D4 stateless = Devin "Manages Devins" (březen 2026)
   - D5 konsolidace = BMAD v6.3.0 4→1 merge (Apr 10, 2026 — 17 dní zpátky)
   
   Tedy: nejsme alone. Trh konverguje stejným směrem.

3. **--step-mode v D3 je explicitně pro interní rollout** (kolegové bez AI experience). Default mode je pro středně-zkušené, --yolo je pro pokročilé / autopilot. Tři módy = tři uživatelské profily.

4. **Konsolidace 21→18 NENÍ snížení funkčnosti** — je to logické párování. 3 páry, které jsou koncepčně 1 práce s 2 fázemi. Stejné jako když BMAD sloučil 4 agenty do 'Amelie' — žádná feature loss, jen lepší dispatch.

5. **v8.0.0 absorbuje původní v9.0.0 D** (`/setup-agents` skill). Onboarding logika patří k architektuře, ne UI vrstvě. v9 family se proto rozdělila: **v9.0.0 = E + F (pure FE)**, **v9.1.0 = Demo projekt (NEW)**, **v9.2.0 = G + hosting + announcement**.

### Pozice vůči trhu (2026-04-27)

| Naše rozhodnutí | Trh udělal totéž | Když |
|-----------------|------------------|------|
| v7 cleanup před launchem | BMAD v6.1.0 odstranil YAML workflow engine | Březen 2026 |
| v8 D1 TOML overlay | BMAD customize.toml + Anthropic 5-tier | 2025-2026 ongoing |
| v8 D2 markdown decomposition | BMAD v6.1.0 (-91% package size) | Březen 2026 |
| v8 D3 mode framework | Cline Auto Approve → 8 categories | 2025-2026 (5 měs.) |
| v8 D5 21→18 agentů | BMAD v6.3.0 4→1 'Amelia' merge | Apr 10, 2026 (17d) |

**Frontier věci děláme jinde** — forge multi-phase verification, AC traceability, NEEDS_CLARIFICATION state machine — to nikdo z velkých nemá.

---

## Sekce 6 — Kam směřujeme: v9.0.0 launch → v10.0.0 možnosti (12 min)

### Co řekneš

> *"Public release ceos-agents není jeden release. Po detailním re-readu A.1 specu jsem si uvědomil, že na to potřebujeme tři verze za sebou — v9.0.0, v9.1.0, v9.2.0 — protože každá řeší jiný conversion gap. Plus je tady dlouhodobá možnost v10.0.0 Node.js Runtime, kterou nechceme dnes rozhodnout, ale chci ji vám představit, abyste věděl, co by stálo za úvahu, kdybychom měli kapacitu."*

### Diagram 9 — Public release timeline

```
v9.0.0 — UI vrstva (E + F)                  pure FE, žádný backend
─────────────────────────────────────────
   E = PLNÝ SHOWCASE (statický HTML/JS na 1 stránce)
       1. Hero + video/GIF "ceos-agents fixne bug za 8 minut"
          (real screenrecord, ne marketing animace)
       2. 18-agent gallery (karty: role + model + příklad výstupu)
       3. Config wizard stepper se živým TOML preview
          → download bundle (CLAUDE.md + customization/*.toml)
       4. "Co dál" minimal: install snippet + docs link
          + teaser "Demo project coming in v9.1.0"

       ✓ Tržní precedenty: Tailwind Play, shadcn/ui, create-next-app web,
         Linear/Resend/Prisma hero showcases
       ✗ Suchý config formulář bez showcase nekonvertuje

   F = READ-ONLY DASHBOARD
       Čte .ceos-agents/pipeline-history.md + state.json
       Vizualizuje: seznam runů, fáze, tokeny, čas, výsledek
       Žádné akce (žádný approve, abort, retry) — to je v10.0.0


v9.1.0 — DEMO PROJEKT (NEW, conversion mechanism)
─────────────────────────────────────────
   Vlastní repo: ceos-agents-demo
   Pre-configured: CLAUDE.md + customization/*.toml
   Záměrné bugy/features jako tracker issues
   Walkthrough README: "spusť /fix-bugs, podívej se jak agent rozhoduje"

   PROČ — bez demo je E "krásná stránka, prohlédne, odejde"
   Demo = aktivní zkušenost = adoption conversion

   BONUS SELF-REINFORCING LOOP:
       Demo run produkuje state.json snapshoty
       → E hero "fixne bug za 8 minut" replay scenarios
       Demo + E si navzájem dodávají autenticitu

   Scope OPEN (delegováno na forge phase 1 research):
       - Stack? (Node? Python? Go? něco jiného?)
       - Tracker? (Gitea? GitHub Issues? embedded?)
       - Repo location? (ceosdata? komunitní mirror?)
       - Walkthrough length? (5 min? 30 min?)

   ✓ Precedenty: shadcn/ui example, Next.js examples,
     BMAD-METHOD tutorial, create-* CLI ship example app


v9.2.0 — G + HOSTING + ANNOUNCEMENT
─────────────────────────────────────────
   Canonical repo URL (plugin.json.repository → veřejný GitHub)
   SECURITY contact channel (secondary kromě e-mailu)
   README rewrite (anglicky, public audience)
   Hosting deploy E + F (decision: GitHub Pages / Gitea Pages / Vercel)
   Announcement (Anthropic plugin marketplace submission, Show HN, awesome-lists)


v10.0.0 — NODE.JS RUNTIME (možnost, dnes ne)
─────────────────────────────────────────
   Separátní repo, "biggest investment"
   Standalone runtime → ceos-agents bez Claude Code CLI dependency
   Backend pro F INTERAKTIVITU (klik = spusť pipeline z webu)
   Pro hosty/use-cases, kde Claude Code CLI nelze instalovat

   NENÍ:
       - Headless dispatch (máme přes Autopilot)
       - Telemetry dashboard (to má ACT, internal AI Control Tower)
       - Multi-LLM (ACT)
       - Enterprise compliance (ACT)

   ROZHODOVAT AŽ PO MĚŘENÍ v9.0.0 LAUNCHU
   (jestli F interaktivita je hodnota, nebo read-only stačí)
```

### Diagram 10 — Závislost graf

```
v8.0.0 (architecture)
   │
   ├─ A.1 (TOML overlay)  ───► E (config wizard potřebuje schema)
   │
   └─ B.1 (HITL gates)    ───► F (dashboard čte gates state)
                                  │
   v9.0.0 (E + F) ─────────► v9.1.0 (Demo)
                                  │       │
                                  │       └─► E hero replay (self-reinforcing)
                                  │
   v9.1.0 ─────────────────► v9.2.0 (G + hosting + announcement)
                                  │
                                  └─► v10.0.0 (Node.js Runtime — možnost)
```

### Klíčové insighty pro CEO

1. **v9.0.0 SAMOTNÉ není dostatečné pro úspěšný launch.** E je krásná stránka, ale bez demo (v9.1.0) si user prohlédne, řekne 'super', odejde. Demo je conversion mechanism — aktivní zkušenost ("spusť `/fix-bugs`, sleduj jak rozhoduje") převede prohlížeče na uživatele.

2. **v9.1.0 demo má self-reinforcing loop s E.** Demo run produkuje state.json snapshoty, které pak E používá pro hero replay scenarios.

3. **Scope demo zámrně delegovaný na forge phase 1 research.** Nevím, jestli demo má být Node.js / Python / Go aplikace, jaký tracker, jaké bugy. To není moje doména — to je výsledek research o cílové audience.

4. **v9.2.0 hosting decision je netriviální.** GitHub Pages = jednoduché ale jen statika; Gitea Pages = vlastní infra; Vercel = best DX ale závislost na třetím partneru.

5. **v10.0.0 explicitně NEDNES.** Rozhoduje se po měření v9.0.0 launchu. Bez dat nedává smysl 3-6 měsíců eng work na něco, co možná nepotřebujeme.

### Pozice vůči trhu

| Náš plán | Tržní precedent |
|----------|-----------------|
| E pure FE showcase (statický) | Tailwind Play, shadcn/ui, create-next-app web (vše statika + JS) |
| v9.1.0 demo projekt | shadcn/ui example, Next.js examples directory, BMAD tutorial project, create-* CLI ship app |
| v9.2.0 plugin marketplace submission | superpowers (121k★) — star curve breaks na den marketplace acceptance (Jan 15, 2026) |
| v10.0.0 standalone runtime | Devin (cloud-managed), Cursor (remote machines) — rozdílné, ale stejný problem space |

---

## Sekce 7 — ROZHODNUTÍ: public release + interní rollout (15-20 min)

### Co řekneš

> *"Tím se dostáváme k rozhodnutí, kvůli kterému jsme tady. Předem řeknu, že některé otázky, které jsem si připravil, jste mi předem odložil — hosting, scope demo projektu, announcement strategie. To řeším později, abychom se na schůzce nezasekli na detailu. Co tady chci s vámi rozhodnout, jsou věci, kde já vlastní rozhodnutí udělat nemůžu — strategická, prioritizace, risk acceptance."*

### Diagram 11 — Decision board

```
ROZHODNUTÍ KE SCHŮZCE
═══════════════════════════════════════════════════════════════

D-A  PRIORITA / PACE
     Má ceos-agents v9.x dnes právo na soustředěný čas?
     Nebo je něco důležitějšího (drmax, BIFITO, jiný klient, ACT)?
     Reálná cílová data: v8.0.0 forge run? v9.0.0 ready? v9.2.0 launch?

D-B  RISK ACCEPTANCE — známé gapy v9.0.0
     Shipping bez:
       - Cloud-managed runtime (Devin, Copilot Coding Agent mají, my ne)
       - Telemetry dashboard tier (Datadog/Grafana) — ACT, ne v9.0.0
       - Self-review code/secret/dependency scanning v PR pipeline (Copilot má)
       - Marketshare baseline (0 hvězd dnes vs Superpowers 121k, BMAD 45.7k)
     Akceptujeme tyto gapy, nebo zdržuje launch jeden z nich?

D-C  CEOS-AGENTS vs ACT IDENTITA V PUBLIC KOMUNIKACI
     Kdy řekneme "to je ACT scope, ne ceos-agents"?
     Mělo by se ACT vůbec zmiňovat v ceos-agents public docs?
     Risk: lidi se ptají "máte něco lepšího?", redirect na interní produkt může působit
     jako "bait and switch".

D-D  INTERNÍ ROLLOUT vs PUBLIC SEQUENCING
     Pilotně interně → feedback → public? Nebo paralelně?
     Kdo je pilotní tým ve firmě? (drmax? BIFITO? jiní?)
     Kdo z firmy se starbí o non-AI-savvy onboarding feedback?

D-E  PUBLIC MIRROR + LICENCE STATUS
     Repo dnes na privátním Gitea (gitea.internal.ceosdata.com)
     Public mirror (GitHub) pro v9.2.0 announcement — kdo provisionuje?
     LICENSE = MIT zafixované, no decision
     plugin.json.repository = `example.invalid` placeholder, čeká na canonical URL

D-F  CO BYSTE OD CEOS-AGENTS CHTĚL VIDĚT, CO TAM DNES NENÍ?
     (otevřená otázka, vstup pro vás)
     CEO používá v5-v6.7 — co byste chtěl jako uživatel jinak?
```

### Klíčové insighty pro CEO (jak rámovat své vstupy)

1. **D-A je nejdůležitější.** Pokud ceos-agents nemá v9.x soustředěný čas, launch se neskončí. Memory ukazuje, že dnes paralelně běží: drmax-readmine demo, BIFITO autopilot pilot (paused), v7.0.0 forge run, v8.0.0 forge plánovaný. Pokud je ceos-agents v9.x na 5. místě v prioritách, řekni to teď, abych mohl rozumně plánovat.

2. **D-B se týká strategie "ship vs polish".** Klasický dilema: vydat ASAP s gapy a sbírat feedback, nebo ladit, dokud nebude 100% featured-parity. Pro ceos-agents argumentuju shipnout — superpowers (121k★) také začínal jako "ne featured-complete" a feedback formoval roadmapu. Featured parity vůči Cursor / Devin nikdy nedosáhneme; positioning je jiný (specialized SDLC pipeline + tracker abstrakce + AC traceability).

3. **D-C je jemná.** ACT je interní, ceos-agents public. Public ceos-agents user nemůže dnes získat ACT. Pokud budou hledat "klik=spusť pipeline", redirect na "máme interní produkt, ale není pro veřejnost" může působit nefér. Možná vůbec nezmiňovat ACT v ceos-agents public docs — držet hranice.

4. **D-D je o feedback loopu.** Pokud interní rollout produkuje konkrétní pain points (např. "kolega Pavel se zasekl na NEEDS_CLARIFICATION, protože nepochopil, co po něm chce"), to je gold pro public release — protože to samé budou hlásit veřejní uživatelé. Doporučuju pilotně interně PŘED public launchem.

5. **D-E je infra.** Public mirror = někdo z týmu provisionuje GitHub org / repo. Pokud to máme udělat my, je to na ToDo. Nedráží launch o víc než pár dní.

6. **D-F je vaše vstup.** Vy jste user — co byste chtěl, co tam dnes není? CEO používá staré verze, takže může mít konkrétní pain points (rate limits, bugs ve workflow-router, slow autopilot, něco jiného), které jsou v6.x už opraveny, nebo jsou v8/v9 plánovány.

### Recommended outcome ze schůzky

Cíl: opustit místnost s těmito odpověďmi:
- **D-A:** ano/ne na soustředěný čas; cílové datum pro v9.0.0 launch (nebo "kdykoli to bude ready")
- **D-B:** akceptujeme gapy / nebo blokuje něco specifického
- **D-C:** ACT v public docs ano/ne / "zmínit jako 'enterprise verze'" / nezmiňovat
- **D-D:** kdo je interní pilotní tým, kdy začíná
- **D-E:** kdo provisionuje public mirror, do kdy
- **D-F:** seznam 1-3 vašich pain pointů z používání starší verze

### CEO talking-point (uzavírací)

> *"Tohle je decision board. Šest otevřených otázek. Některé mají jasnou doporučenou odpověď z mé strany, jiné jsou opravdu vaše. Cíl schůzky: opustit místnost s alespoň D-A, D-B, D-D, D-F rozhodnutými, zbytek si dohrajeme do týdne. Pokud máte otázku, kterou jsem nezachytil, doplníme ji teď."*

---

## Appendix A — Comparison matrix (top competitors)

| Capability | ceos-agents | superpowers | BMAD | Anthropic Skills | Cursor | Devin | Cline | Copilot Coding Agent |
|---|---|---|---|---|---|---|---|---|
| Markdown + YAML plugin | ✓ | ✓ | ✓ | ✓ | — | — | — | — |
| Sequential pipeline | ✓ (specialized) | partial | partial | — | — | — | — | ✓ (Actions sandbox) |
| Multi-tracker abstraction | ✓ (6 trackers) | — | — | — | — | GH only | — | GH only |
| NEEDS_CLARIFICATION state machine | ✓ | — | — | — | — | partial | — | — |
| AC traceability (`maps_to`) | ✓ | — | — | — | — | — | — | partial |
| Webhook events | ✓ | — | — | — | — | — | — | GH Actions |
| HITL mode framework | v8.0.0 | manual | persona handoffs | — | per-rule allow/deny | 2 checkpoints | 8 categories | self-review |
| Multi-LLM | Claude only | Claude only | 9+ platforms | Claude only | multi providers | Claude (closed) | 75+ providers | OpenAI/Anthropic |
| Cloud-managed runtime | — | — | — | — | remote machines | ✓ ($20/mo) | — | Actions sandbox |
| Telemetry dashboard tier | basic JSON | — | — | — | enterprise | ACU benchmarks | — | GH Insights |
| Stars / Adoption | private | 121k★ | 45.7k★ | native | $2B ARR | $25B raise talks | 3.7M VSCode | All Copilot users |

---

## Appendix B — Honest weaknesses (pro CEO transparentnost)

### 3 věci, kde jsme významně pozadu (years, not months)

1. **Cloud-managed runtime** — Devin, Cursor remote machines, Copilot Actions sandbox umožňují ship while laptop sleeps. ceos-agents vyžaduje aktivní Claude Code CLI na hostu. Greenfield GitHub teams chtějí "$20/mo button", to my dnes nejsme.
2. **Telemetry, observability, benchmarks** — Devin publikuje ACU benchmarks, MS Agent Framework má native OpenTelemetry, Cursor enterprise admin console. My máme `/metrics` (stdout JSON), `/dashboard` (static HTML), webhook events. CTO doing vendor evaluation uvidí gap.
3. **Mindshare a distribuce** — superpowers 121k★, BMAD 45.7k★, opencode 140k★, Cline 5M+ VSCode installs. ceos-agents je private bez veřejného listingu. Buyer's first question — "who else uses this?" — nemáme veřejnou odpověď. v9.2.0 to řeší launchem.

### 5 věcí, kde nás konkurence předbíhá

1. **Parallel agent execution** — Cursor 8 paralelních, Anthropic Team Lead, Devin clone. Náš pipeline je sekvenční (záměrně, ale méně rich UX).
2. **Spec-first / brainstorming workflow** — BMAD personas + curated workflow menus, superpowers `brainstorming` skill enforced. My máme spec-analyst + architect, ale méně discoverable.
3. **Self-review** — Copilot runs code-scanning + secret-scanning + dep CVE check uvnitř workflow. My spoléháme na consuming project's CI.
4. **Plan / approval mode s diff preview** — opencode Plan/Build, Cursor accept/reject hunks, Cline Plan/Act. v8.0.0 `--step-mode` to dotáhne.
5. **Multi-LLM** — opencode 75+ providers, Cline OpenRouter, MS AF connectors. Anthropic-only blokuje GPT/Gemini/local users.

### 5 věcí, kde jsme unikátní (true differentiators)

1. **Issue-tracker-aware pipeline s multi-tracker abstrakcí** (YouTrack/Jira/Linear/Gitea/Redmine/GitHub) jako first-class config contract.
2. **NEEDS_CLARIFICATION state machine** s typed state schema, DoS counters, pause-timeout config, tracker-comment producer/receiver protocol.
3. **AC traceability** — acceptance-gate verifikuje per-AC fulfillment s code+test evidence; architect emit `maps_to: AC-{N}`; spec-reviewer `--verify` mode.
4. **Webhook event stream s run_id correlation + circuit breaker** (`pipeline-started`, `step-completed`, `pipeline-completed`, `ceos-agents-block`, `pipeline-paused`).
5. **Per-pipeline retry budgets s named limits** (5 fixer↔reviewer, 3 test, 3 build, 5 spec, 3 root cause) konfigurovatelné per-project.

---

## Appendix C — Citace klíčových research findings

- **Anthropic "Building Effective Agents"** — 5 patternů: routing, chaining, parallelization, orchestrator-workers, evaluator-optimizer
- **TDFlow** (arXiv 2510.23761): 94.3 % SWE-bench s 4 sub-agenty
- **AdverTest mutation testing**: 70 % kill rate gate, 8.56 % quality improvement
- **Free-MAD** (arXiv 2502.02533): heterogenní paralelní agenti +12-16 %; nezkoordinovaní 17.2× error amplification
- **Karpathy "Vibe Coding"**: "March of Nines" 90→99 % = 99→99.9 %; "pull deterministic steps OUT of LLM"
- **MetaGen / ADAS / MetaSynth**: full per-project meta-gen academic-only, zero produkce
- **BMAD-METHOD v6.1.0** (březen 2026): odstranil YAML workflow engine, package -91 %
- **BMAD-METHOD v6.3.0** (Apr 10, 2026): 4 agenty → 1 'Amelia' merge
- **Cline Auto Approve evolution**: single toggle → YOLO → 8 granular categories
- **Devin "Manages Devins"** (březen 2026): orchestrator stateful + managed clean-slate
- **Cursor 3.2** (Apr 24, 2026): async subagents, multi-root workspaces
- **GitHub Copilot Coding Agent GA** (Apr 20, 2026): assign issue → Actions sandbox → PR
- **Claude Opus 4.7 GA** (Apr 16, 2026): same price, ~35 % víc tokenů (nový tokenizer)
- **superpowers (Jesse Vincent)** Anthropic marketplace acceptance Jan 15, 2026 — star curve breakpoint

---

## Appendix D — Diagramy ke kreslení (souhrn)

1. **Mapa session** (Sekce 1) — 6 položek + dva paralelní tlaky
2. **Architektura ceos-agents** (Sekce 2) — Claude Code platform → plugin → skills → agents → API
3. **Bug-fix pipeline flow** (Sekce 2) — issue tracker → triage → ... → publisher → verify
4. **Forge pipeline architektura** (Sekce 3) — 10 fází + JAK forge tvoří agenty / dělá zadání
5. **Cross-plugin dogfooding** (Sekce 3) — filip-superpowers (forge) ←→ ceos-agents
6. **Forge timeline** (Sekce 3) — od 2026-03-21 design po dnes, 46 runs
7. **Evoluce vize + 4 kategorie agentů** (Sekce 4) — meta-gen → overlay + bug-fix/feature/scaffold/planning
8. **v7+v8 timeline** (Sekce 5) — 6 cleanup actions + 5+1 architecture decisions
9. **Public release timeline** (Sekce 6) — v9.0.0 → v9.1.0 → v9.2.0 → v10.0.0
10. **Závislost graf** (Sekce 6) — v8 (A→E, B→F) → v9.0 → v9.1 → v9.2 → v10
11. **Decision board** (Sekce 7) — 6 otevřených otázek

---

## Appendix E — Anti-patterns (čeho se vyhnout napříč prezentací)

- Marketingový jazyk ("revoluční", "next-gen", "cutting-edge")
- Tykání (vykání bezvýjimečně)
- "Slepá ulička" / "chyba" rétorika k meta-gen pivotu (evoluce, ne porážka)
- Tvrdit "lepší než Cursor / Devin" (jiný segment, ne lepší univerzálně)
- Detailní vyjmenování každého agenta / každé fáze forge / každé akce v7
- Skrývat gapy (D-B explicitně otevřená — to buduje trust)
- Lobby za "permission to focus" v D-A (CEO rozhodne sám)
- Slibovat v10.0.0 implementaci (je to možnost, ne plán)
- Zmiňovat ACT v public ceos-agents docs (D-C otevřená otázka)
- Investor pitch tone (zaměstnanec → nadřízený, společné rozhodnutí)
