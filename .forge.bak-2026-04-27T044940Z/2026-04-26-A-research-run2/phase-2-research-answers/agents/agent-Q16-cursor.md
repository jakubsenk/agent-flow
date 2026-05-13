# Q16 — Cursor (Composer + 2.0): Hluboká analýza pro ceos-agents v8.0.0 Research Run 2

**Agent:** Q16-cursor (production + vendor lens)
**Datum:** 2026-04-26
**Run:** 2026-04-26-A-research-run2
**Scope:** Sub-projekt A — Agent Shape Rework, vstup do Q22 cross-run synthesis
**Status:** FINAL

---

## Lens disclosure

Tento report operuje primárně z **production lens** (ARR trajektorie, enterprise deployment data, pricing) a **vendor lens** (Cursor blog, docs, changelog, technické reporty). Community lens (forum.cursor.com, DEV.to, Medium) použit sekundárně pro validaci a "known issues". Akademická literatura použita tam, kde Cursor byl citován v kontextu (arxiv 2512.18925v3 — empirická studie rules).

**Scope omezení:** Cursor je proprietary closed-source produkt. Všechny architektonické detaily pochází z vendor-published blogů, changelogů, a technických reportů. Zdrojový kód Cursor IDE ani modelu není veřejný. Čtenář musí zohlednit, že vendor blog může přikrášlovat výsledky a/nebo omezovat technické disclosure.

---

## Exec summary

Cursor je k dubnu 2026 dominantní komerční AI coding product s **$2B ARR** (fastest B2B SaaS scale ever, 0→$2B za ~3 roky) a **$50B valuation** (Series E, Andreessen Horowitz + Thrive Capital + Nvidia, 2026-04). Jeho architektura prošla třemi výrazně odlišnými generacemi: Composer 1 (Oct 2025, proprietární MoE model + RL harness), Cursor 2.0 + 2.5 (Nov 2025 – Feb 2026, multi-agent worktrees + async subagents + plugin marketplace), a Cursor 3 (Apr 2026, Agents Window jako primární UI paradigma).

Pro ceos-agents v8.0.0 jsou přenositelné čtyři věci: (1) `.cursor/rules` overlay pattern jako konzistentní referenční implementace Generic+overlay architekturou, (2) worktree izolace jako první-třídní primitiv pro paralelní agenty, (3) progressivní HITL (diff review + YOLO mode + /best-of-n) jako dvouúrovňová strategie, (4) plugin format (skills + subagents + MCP + hooks + rules v jednom instalačním balíčku). Co je neoddělitelně IDE-specifické: electron/Node.js runtime, forked-VSCode UI, proprietární Composer model, a visual Design Mode.

---

## 1. Granularita agentů

### Composer 1 vs Cursor 2.0 — architektonická evoluce

**Composer 1** (Oct 2025) je single agentic entity: proprietární MoE (mixture-of-experts) model plus tool harness s file-read/edit, semantic codebase search, string grep a terminal. Výsledkem je jeden velmi kapacitní agent disponující sám sebou nástroji — paradigma "tool-using agent" bez explicitní granularity.

> *"Composer is a frontier model that is 4x faster than similarly intelligent models"* — [cursor.com/blog/2-0](https://cursor.com/blog/2-0)

**Cursor 2.0** (Nov 2025) přidal granularitu na úrovni paralelizace: `git worktree add` vytvoří izolovaný checkout, v němž běží Composer jako samostatný agent-proces. Cursor dokumentace explicitně uvádí **"up to 8 agents simultaneously"** — to je published limit, ne architektonický strop. Každý worktree-agent má vlastní filesystem view a pracuje na samostatné větvi.

> *"Run up to eight agents in parallel using git worktrees or remote machines to prevent file conflicts"* — [cursor.com/docs/configuration/worktrees](https://cursor.com/docs/configuration/worktrees)

Granularita v 2.0 je tedy **horizontální replikace jednoho agenta** (8× Composer v 8 worktrees), nikoliv hierarchická specializace (triage-analyst → fixer → reviewer). Odpověď na otázku "Compositor 1 vs 2.0 granularity?" je: Composer 1 = monolithic single-agent; Cursor 2.0 = horizontálně škálovaný single-agent typ, ne multi-specialist pipeline.

**Cursor 2.5** (Feb 2026) přidává asynchronní subagenty, což poprvé vytváří hierarchii: parent agent → dítě subagents → potenciálně vnuci. Subagents běží na pozadí a parent pokračuje v práci. Dokumentace uvádí stromovou strukturu bez specifikace depth limit.

> *"Subagents can spawn their own subagents, creating a tree of coordinated work"* — [cursor.com/changelog/2-5](https://cursor.com/changelog/2-5)

**Cursor 3** (Apr 2, 2026) posunuje granularitu dál: Agents Window zobrazuje všechny agenty v sidebar — local, cloud, worktree, remote SSH. `/best-of-n` spustí stejný task paralelně přes více modelů, každý v vlastním izolovaném worktree, pak porovná výsledky. Cursor tak zavádí **best-of-N sampling** jako user-facing feature.

> *"The /best-of-n command runs the same task in parallel across multiple models, each in its own isolated worktree, then compares outcomes."* — [cursor.com/changelog/3-0](https://cursor.com/changelog/3-0)

**Srovnání s ceos-agents:** ceos-agents používá narrow sequential specialization (21 agentů), Cursor používá horizontal replication (8× stejný model) s volitelnou hierarchií (parent→child subagents). Oba přístupy vedou na odlišné architektonické problémy — ceos-agents koordinační overhead 21 rolí, Cursor context-sharing problém přes worktrees (každý agent nemá kontext ostatních).

---

## 2. Pipeline configuration mechanism

Cursor **nemá explicitní pipeline DSL pro uživatele**. Neexistuje soubor, kde by uživatel definoval `stage: [triage, fix, review, publish]`. Pipeline v Cursoru je implicitně definována tím, co agent dělá — Composer model je natrénován se specifickými tool-use patterny, a uživatel může ovlivnit chování třemi mechanismy:

### `.cursor/rules` (hlavní konfigurační surface)

Pravidla jsou `*.mdc` nebo `*.md` soubory v adresáři `.cursor/rules/` s YAML frontmatter:

```yaml
---
description: "Rule description"
globs: ["**/pattern/**/*.ext"]
alwaysApply: false
---
# Rule content in markdown
```

- `alwaysApply: true` → pravidlo se připojuje do každého chat session
- `alwaysApply: false` + `description` → agent sám rozhodne, zda pravidlo je relevantní
- `globs` → pravidlo platí jen pro soubory odpovídající glob patternu
- Precedence: Team Rules → Project Rules → User Rules (při konfliktu vyhrává dřívější)
- Empiricky: průměrný projekt má **4.68 rule souborů**, průměrná délka **462.67 řádků** (SD=1197; velký rozptyl). (arxiv 2512.18925v3, "Beyond the Prompt")

### AGENTS.md

Cursor adoptoval AGENTS.md standard (kredit OpenAI, Aug 2025). AGENTS.md je plain markdown bez frontmatter, umístěný v project root nebo v podadresáři. Closest file k editovanému souboru má přednost. Cursor je explicitně uveden v listu adoptovaných platforem na agents.md.

> *"AGENTS.md is just standard Markdown. Use any headings you like; the agent simply parses the text you provide. The closest AGENTS.md to the edited file wins; explicit user chat prompts override everything."* — [agents.md](https://agents.md/)

### MCP server config

Cursor podporuje MCP (Model Context Protocol, donovaný AAIF / Linux Foundation 2025-12-09). MCP servery rozšiřují tool harness o customní nástroje. Od Cursor 2.5 jsou MCP servery součástí plugin formátu.

**Vztah k ceos-agents:** ceos-agents má analogický mechanismus v `Agent Overrides` (append-to-prompt) + `Pipeline Profiles` (skip/extra stages) + `Hooks`. Cursor řeší configuraci overlay (rules) ale ne pipeline definition. Oba tedy sdílejí Generic+overlay filozofii bez pipeline DSL.

---

## 3. Per-project customization

Cursor implementuje třívrstvou customization hierarchii:

### Vrstva 1: User-level rules
`~/.cursor/rules/*.mdc` — globální pravidla platná pro všechny projekty. Unikátní user preferences (styl, model chování, workflow).

### Vrstva 2: Team rules
V Cursor Teams ($40/user/month) lze sdílet "shared chats, commands, and rules" na org úrovni. Implementace přes centralizované billing a admin dashboard.

### Vrstva 3: Project rules
`.cursor/rules/*.mdc` v project root — verzovatelné v gitu, sdílené v teamu. Precedence: Team > Project > User (dřívější vyhrává).

### `.cursor/worktrees.json`
Konfigurační soubor pro worktree management: setup příkazy (`setup-worktree-unix`, `setup-worktree-windows`), cleanup interval (`cursor.worktreeCleanupIntervalHours`), max počet worktrees (`cursor.worktreeMaxCount`).

### Plugin format (Cursor 2.5+)
Plugins na Cursor Marketplace balí: skills + subagents + MCP servery + hooks + rules do jednoho instalačního balíčku. Nainstalován příkazem `/add-plugin`. Partneři: Amplitude, AWS, Figma, Linear, Stripe (k Feb 2026).

**Best practice od Cursoru:**
> *"Start simple. Add rules only when you notice the agent making the same mistake repeatedly. Don't paste style guides — use a linter instead."* — [cursor.com/blog/agent-best-practices](https://cursor.com/blog/agent-best-practices)

**Empirická data (arxiv 2512.18925v3):** Rules mají 5 kategorií — Project (85% repos), Convention (84%), Guideline (89%), LLM Directive (50%), Example (50%). Nejčastější je Guideline obsah (33% všech řádků). Efektivita rules na LLM performance nebyla v této studii měřena — "remains an open question".

**Known issue:** Forum.cursor.com hlásí sporadické ignorování rules files po update (verze 1.0.0 regression). File format bug: nové project rules se někdy vytvářejí jako `.mdc` místo `RULE.md`. Tyto jsou bug-level problémy, ne design-level.

---

## 4. HITL pattern

Cursor implementuje dvouúrovňový HITL:

### Úroveň 1: Synchronous diff review (default)
Každý agent edit se zobrazí jako diff highlight v IDE. Uživatel vidí změny real-time jak agent píše. Pokud agent jde špatným směrem, uživatel klikne Stop. Po dokončení lze přijmout/odmítnout celý diff nebo reviewovat per-soubor.

> *"The diff view shows changes as they happen. If you see the agent heading in the wrong direction, click Stop to cancel and redirect."* — [cursor.com/blog/agent-best-practices](https://cursor.com/blog/agent-best-practices)

Po dokončení: uživatel může spustit "Review → Find Issues" pro line-by-line analýzu.

### Úroveň 2: YOLO mode (autonomní)
Settings > Features > Agent > "Yolo mode" — agent vykonává změny bez žádosti o accept. Terminal příkazy s matching patterny se auto-schválí. YOLO mode byl popularizován v Cursoru (2024), pak v Claude Code (2025), nyní standardní feature.

**Multi-file accept-all:** Dokumentace nespecifikuje granulární selective-file approval — worktree workflow nabízí "Apply to merge worktree changes back" jako bulk operaci.

### Cursor 3: /best-of-n jako strukturovaný HITL gate
`/best-of-n` je explicitní HITL gate: agent spustí N paralelních pokusů, Cursor navrhne nejsilnější řešení, uživatel vybere. To je strukturovaná confidence-based review — pro obtížné úkoly kde jeden pokus nestačí.

**"4x faster" claim — verifikace source:**
Cursor tvrdí, že Composer je 4x faster než "similarly intelligent models". Měření probíhá přes interní benchmark **CursorBench** (tokens per second, standardizované na Anthropic tokenizer). Konkrétní čísla nejsou ve veřejných zdrojích — VentureBeat uvádí "250 tokens/sec: roughly 4x faster than GPT-5 or Claude 4.5 Sonnet" (citát z externí analýzy, ne z Cursor technického reportu). **Methodologie není peer-reviewed a není reprodukovatelná externě.** Cursor Bench je interní benchmark bez public specification.

**Závěr:** "4x faster" je vague vendor claim, metodologicky neverifikovatelný. Praktická validace: Cursor 2.0 changelog uvádí "most turns complete in under 30 seconds" — tento claims je operational/UX oriented, ne throughput.

---

## 5. Stateful vs stateless agent design

### Composer chat session retention
Composer sessions jsou stavové v rámci jednoho chat threadu — model má přístup k historii konverzace (multi-turn context). Composer 1 blog explicitně uvádí "long-context generation" jako klíčovou vlastnost.

### Cursor 2.0: worktree isolation jako stateful-per-worktree
Každý worktree agent má izolovaný filesystem state — git branch, soubory, dependencies. To je **filesystem-level state**, ne conversation state. Agenti napříč worktrees **nesdílejí kontext** navzájem — každý agent operuje s "clean slate" kontextem pro daný task (analogie s Cognition "Devin Manages Devins" March 2026 rationale: *"Each managed Devin gets a clean slate, a narrow focus"*).

### Cursor 2.5: async subagent state
Při asynchronním subagent spawning parent pokračuje, zatímco dítě běží. Parent a dítě sdílejí záměr (task delegovaný parentem) ale ne konverzační kontext. Dokumentace nespecifikuje mechanismus předávání state mezi parent a child.

### Cursor 3: Agents Window persistence
Agents Window zobrazuje všechny aktivní a dokončené agenty — de facto dashboard stavů. Uživatel může vidět agenty inicializované z různých zdrojů (mobile, Slack, GitHub, Linear). To je **UI-level state aggregation**, ne agent memory.

**Composer 2 (Kimi K2.5 base, Mar 2026):** Trénován ve dvou fázích — continued pretraining na code-heavy data mix, pak large-scale RL. RL probíhá v "realistic Cursor sessions with the same tools and harness the deployed model uses" — tedy agent je natrénován přímo na produkčním harnessu. Výsledky: CursorBench 61.3 (37% zlepšení oproti Composer 1.5), SWE-bench Multilingual 73.7, Terminal-Bench 61.7. ([cursor.com/blog/composer-2-technical-report](https://cursor.com/blog/composer-2-technical-report), [cursor.com/blog/real-time-rl-for-composer](https://cursor.com/blog/real-time-rl-for-composer))

**Real-time RL pipeline** (Mar 26, 2026): Cursor sbírá "billions of tokens from user interactions" → reward signals → training loop → nový checkpoint za ~5 hodin → múltiple daily deploys. Měřené metriky: edit persistence +2.28%, dissatisfied follow-ups −3.13%, latency −10.3%. Toto je **nejrychlejší RL feedback loop** publikovaný komerčním AI coding nástrojem.

**Závěr stateful vs stateless:** Cursor je hybridní — chat thread je stavový (multi-turn), worktree agent dostane clean filesystem state, subagent dostane delegovaný task intent. Není to "pure stateless dispatch" jako ceos-agents, ale ani "deep state retention" jako CrewAI threads.

---

## 6. Lessons learned

### ARR a adopce — verifikace

- **$500M ARR překonáno:** TechCrunch, Jun 5, 2025: *"Cursors Anysphere nabs $9.9B valuation, soars past $500M ARR"* ([techcrunch.com/2025/06/05](https://techcrunch.com/2025/06/05/cursors-anysphere-nabs-9-9b-valuation-soars-past-500m-arr/)). Tento milestone je verifikovatelný (TechCrunch, nikoliv vendor-only claim).
- **$2B ARR (Feb 2026):** The Next Web uvádí: *"Cursor in talks to raise $2B at $50B valuation after hitting $2B ARR in three years"* — tato data pochází z fundraising dokumentů, sekundárně reportovaných. Není peer-reviewed, ale je konzistentní přes více tech médií (Fortune, TechCrunch, thenextweb.com).
- **$6B ARR forecast 2026:** Jedinou zdrojem je Anysphere sama. Treat as aspirational vendor projection.
- **Valuation:** $50B Series E (Apr 2026), co-led by a16z + Thrive + Nvidia — zpráva potvrzena přes více zdrojů.

### Composer RL training — methodologie

Composer 1 (Oct 29, 2025):
- MoE architektura, trénovaná s RL v "hundreds of thousands of concurrent sandboxed coding environments adapted from Background Agents infrastructure"
- Nativní low-precision training: MXFP8 MoE kernels + expert parallelism + hybrid sharded data parallelism
- Scale: "thousands of NVIDIA GPUs"
- Evaluation: CursorBench (interní, real agent requests + hand-curated solutions)
- Žádné parametry (počet expertů, total params) nebyly disclosed

Composer 2 (Mar 24, 2026, base: Kimi K2.5):
- Two-phase: continued pretraining (EP=8, CP=2) + large-scale RL (EP=8, CP=8)
- RL v realistic Cursor sessions s production harness
- CursorBench: 61.3 (+37% vs Composer 1.5), SWE-bench Multilingual: 73.7, Terminal-Bench: 61.7
- "Competitive with strongest frontier models" + "Pareto-optimal cost-accuracy tradeoff"

Real-time RL (Mar 26, 2026): 5-hour checkpoint cycle, multiple daily deploys, on-policy training z production inference tokens.

### Pricing changes 2025→2026

| Milestone | Datum | Událost |
|-----------|-------|---------|
| Request-based → credit-based | Jun 2025 | Rushed rollout, user backlash, reports of overcharging |
| Pro: $20/month credit pool | Jun 2025 | Auto mode unlimited na paid plans |
| Pro+: $60/month | 2025-2026 | 3x credits vs Pro |
| Ultra: $200/month | 2025-2026 | 20x usage, priority access |
| Teams: $40/user/month | current | Shared rules + analytics + SSO |
| Composer 2 Standard: $0.50/1M in, $2.50/1M out | 2026 | Direct API pricing |
| Composer 2 Fast: $1.50/1M in, $7.50/1M out | 2026 | Speed-optimized variant |

**Klíčový pricing insight:** Auto mode je unlimited na paid plans — uživatel platí jen za manuální výběr frontier modelů (Claude Sonnet, GPT-5.4 etc.) z credit pool. Tato struktura incentivizuje "Auto" = Composer.

### Known issues a community feedback

1. **Rules drift:** Empirická studie (arxiv 2512.18925v3) ukazuje, že starší projekty se přesouvají od project-specific rules k obecným guidelines — natural drift rules od specificity k dokumentaci.
2. **Rules ignored bug:** Forum reports o project rules neplatných po verzi update (v1.0.0 regression).
3. **Rule explosion (community perception):** Uživatelé s mnoha rules reportují konflikty a nepředvídatelné chování — ale žádná kvantifikace v primárních zdrojích.
4. **AGENTS.md vs .cursor/rules:** Cursor přijal oba standardy (AGENTS.md pro jednoduchá nastavení, .cursor/rules pro komplexní per-file/team/glob logic). Precedence mezi nimi není explicitně dokumentována — potenciální zdroj zmatku.
5. **Pricing backlash (Jun 2025):** Credit-based billing migration byl kritizován za špatnou komunikaci. Post-backlash stabilizace: Auto mode unlimited = zmírňuje stížnosti.

---

## 7. Co lze přenést do markdown-only Claude Code plugin (ceos-agents kontext)

### 7.1 `.cursor/rules` overlay pattern → ceos-agents Agent Overrides

Cursor's `.cursor/rules` s YAML frontmatter je production-validated přístup k Generic+overlay. ceos-agents `Agent Overrides` (append-to-prompt per agent) je funkčně analogický, ale bez:
- glob-based conditional activation (rules platí jen pro `.py` files, etc.)
- alwaysApply vs description-based activation dichotomie
- Team-level rules tier

**Přenositelná inspirace:** ceos-agents by mohl rozšířit `Agent Overrides` o `globs` pole v override souboru — např. `fixer-django.md` s `globs: ["**/*.py"]` se aktivuje jen u Python-heavy commitů.

### 7.2 Worktree parallel orchestration → ceos-agents Worktrees Optional Config

Cursor's worktree izolace (`.cursor/worktrees.json`, `setup-worktree-unix/windows`, max count, cleanup interval) je přesný referenční vzor pro ceos-agents `### Worktrees` Optional Config sekci. Specificky:
- `cursor.worktreeMaxCount` analogický k ceos-agents "Batch size"
- `cursor.worktreeCleanupIntervalHours` analogický k ceos-agents "Cleanup"
- `/apply-worktree` + `/delete-worktree` příkazy jako user-facing worktree lifecycle

### 7.3 AGENTS.md jako sdílený standard

Cursor přijal AGENTS.md (AAIF/Linux Foundation steward). ceos-agents dnes primárně čte `## Automation Config` z `CLAUDE.md`. V8.0.0 by mohl přidat AGENTS.md jako alternativní/doplňkový vstupní soubor — zvyšuje interoperabilitu s jinými agenty (Devin, Codex, Jules, Gemini CLI), kteří AGENTS.md také čtou.

### 7.4 Plugin format (skills + subagents + MCP + hooks + rules)

Cursor 2.5 plugin balí všechny komponenty do jednoho instalačního balíčku. ceos-agents je celý "plugin" ve smyslu Claude Code plugin systému — ale interní organizace je flat (`agents/`, `skills/`, `core/`). Plugin bundling pattern od Cursoru nabízí inspiraci pro grouping: "fix-workflow plugin" = fixer + reviewer + test-engineer + rollback-agent + relevant skills.

### 7.5 Best-of-N sampling jako pipeline stage

Cursor's `/best-of-n` jako user-facing feature se mapuje na potential ceos-agents pattern: místo 1 fixer iteration → dispatch N parallel fixers v worktrees → judge vybere nejlepší. Relevantní pro komplexní issue kde retry-limit 5 nestačí.

### 7.6 Real-time RL feedback pattern → pipeline-history.md

Cursor sbírá edit persistence + dissatisfied follow-ups jako reward signal. ceos-agents `pipeline-history.md` append-only metadata (v6.9.0) sleduje block reasons + pipeline outcomes — analogická struktura. Pokud by ceos-agents someday fine-tunal agenty, `pipeline-history.md` je správný data collection point.

---

## 8. Co je framework-specific (neoddělitelné od Cursoru)

### 8.1 Electron + VSCode fork + IDE distribution

Cursor je forked Visual Studio Code (electron/Node.js/TypeScript), distribuovaný jako desktop IDE. `cursor.worktreeMaxCount`, `cursor.worktreeCleanupIntervalHours` jsou VSCode settings keys. Design Mode funguje přes built-in browser panel. Agent Tabs = IDE tab management. Toto vše je neodlučitelné od IDE runtime.

### 8.2 Proprietární Composer model

Composer je proprietární MoE model Anysphere Inc. — není OSS, není dostupný přes API bez Cursor IDE (Composer 2 API ceny existují ale jen pro Cursor integraci). Architektonická rozhodnutí (real-time RL, Kimi K2.5 base, MXFP8 kernels) nejsou dostupná jako standalone components. Claude Code plugins nemohou "použít Composer".

### 8.3 Background Agents cloud infrastructure

Sandboxed cloud environments pro async subagents jsou proprietární cloud infrastruktura Cursoru. Umožňují škálování nad lokální resource limit. ceos-agents běží local (Claude Code) — cloud sandboxing není dostupný.

### 8.4 Cursor Marketplace

Cursor Marketplace s first-party integracemi (Amplitude, AWS, Figma, Linear, Stripe) je proprietární distribucí platformy. Analogie: Claude Code skills marketplace (skills.anthropic.com) — ale Cursor Marketplace je IDE-native s přímou IDE integrací přes `/add-plugin`.

### 8.5 Visual diff UI a Design Mode

IDE-native diff highlighting per-line + Design Mode (annotate UI elements v built-in browser) jsou UI-layer features nerepresentovatelné v markdown-only plugin. ceos-agents HITL pattern musí spoléhat na Claude Code terminal output + PR diff review.

### 8.6 Language stack lock-in

Cursor extensions a plugins jsou napsané v TypeScript (VSCode extension API). ceos-agents je pure markdown — zero language lock-in je explicit designová volba a framework-agnostic vlastnost.

---

## Citace a zdroje

| Claim | Zdroj | Datum |
|-------|-------|-------|
| Cursor 2.0 "up to 8 agents in parallel, git worktrees" | [cursor.com/blog/2-0](https://cursor.com/blog/2-0) | Nov 2025 |
| "4x faster than similarly intelligent models" | [cursor.com/blog/2-0](https://cursor.com/blog/2-0) | Nov 2025 |
| Composer = MoE model, RL training, hundreds of thousands sandboxed environments | [cursor.com/blog/composer](https://cursor.com/blog/composer) | Oct 29, 2025 |
| Composer 2: Kimi K2.5 base, CursorBench 61.3, SWE-bench Multilingual 73.7 | [cursor.com/blog/composer-2-technical-report](https://cursor.com/blog/composer-2-technical-report) | Mar 24, 2026 |
| Real-time RL: 5h checkpoint cycle, edit persistence +2.28%, dissatisfied -3.13% | [cursor.com/blog/real-time-rl-for-composer](https://cursor.com/blog/real-time-rl-for-composer) | Mar 26, 2026 |
| Cursor 2.5: async subagents, plugin marketplace, sandbox access controls | [cursor.com/changelog/2-5](https://cursor.com/changelog/2-5) | Feb 17, 2026 |
| Cursor 3: Agents Window, /best-of-n, /worktree command, Design Mode, Agent Tabs | [cursor.com/changelog/3-0](https://cursor.com/changelog/3-0) | Apr 2, 2026 |
| .cursor/rules format (alwaysApply, globs, description frontmatter) | [cursor.com/docs/rules](https://cursor.com/docs/rules) | 2026 |
| Worktrees: worktrees.json, setup-worktree-unix, maxCount, cleanup interval | [cursor.com/docs/configuration/worktrees](https://cursor.com/docs/configuration/worktrees) | 2026 |
| Agent best practices: "Start simple, add rules only when agent repeats mistakes" | [cursor.com/blog/agent-best-practices](https://cursor.com/blog/agent-best-practices) | 2026 |
| AGENTS.md standard, AAIF/Linux Foundation stewardship 2025-12-09 | [agents.md](https://agents.md/), [linuxfoundation.org/press](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation) | Dec 9, 2025 |
| AGENTS.md adopted >60k open-source projects (vendor claim) | [agents.md](https://agents.md/) | 2026 |
| $500M ARR: TechCrunch verified | [techcrunch.com/2025/06/05](https://techcrunch.com/2025/06/05/cursors-anysphere-nabs-9-9b-valuation-soars-past-500m-arr/) | Jun 5, 2025 |
| $2B ARR, $50B valuation Series E (a16z + Thrive + Nvidia) | [thenextweb.com/news/cursor-anysphere-2-billion-funding](https://thenextweb.com/news/cursor-anysphere-2-billion-funding-50-billion-valuation-ai-coding) | Apr 2026 |
| Credit-based billing Jun 2025, Auto mode unlimited on paid plans | [cursor.com/docs/models-and-pricing](https://cursor.com/docs/models-and-pricing) | Jun 2025 |
| Composer 2 API: $0.50/1M in (Standard), $1.50/1M in (Fast) | [forum.cursor.com Composer 2 vs Auto model pricing](https://forum.cursor.com/t/composer-2-vs-auto-model-pricing/157665) | 2026 |
| Empirická studie rules: avg 4.68 files/repo, avg 462.67 lines, 5 categories | [arxiv.org/html/2512.18925v3](https://arxiv.org/html/2512.18925v3) | Dec 2025 |
| YOLO mode: Settings > Features > Agent, auto-approves matching terminal commands | [forum.cursor.com/t/how-to-use-enable-yolo-mode](https://forum.cursor.com/t/how-to-use-enable-yolo-mode/112974) | 2025-2026 |
| Fortune: "Cursor's crossroads: rapid rise and very uncertain future" | [fortune.com/2026/03/21](https://fortune.com/2026/03/21/cursor-ceo-michael-truell-ai-coding-claude-anthropic-venture-capital/) | Mar 21, 2026 |

---

## Shrnutí pro Q22 cross-run synthesis

| Dimenze | Cursor finding | Evidence strength |
|---------|---------------|-------------------|
| Agent granularity | Horizontální replikace (8× worktree), nikoliv specialist hierarchy | Vendor blog (High) |
| Pipeline configuration | Žádný pipeline DSL; .cursor/rules overlay + AGENTS.md | Vendor docs (High) |
| Per-project customization | 3-tier (User→Project→Team), rules/.cursor, AGENTS.md, plugins | Vendor docs + arxiv (High) |
| HITL pattern | Diff review (synchronous default) + YOLO mode (opt-in) + /best-of-n (structured) | Vendor docs + forum (High) |
| Stateful design | Chat stavový; worktree filesystem izolovaný; subagent clean-slate | Vendor changelog (Medium) |
| Lessons learned | Real-time RL 5h cycle; $2B ARR; 4x faster claim neverifiable | Mixed (vendor/TechCrunch) |
| Přenositelné do ceos-agents | Rules overlay pattern, worktrees config, AGENTS.md adopt, /best-of-n pattern | Vendor docs (High) |
| Framework-specific | Electron IDE, Composer MoE model, cloud sandboxes, Visual Design Mode | Vendor (High) |

**Klíčový finding pro Q22:** Cursor validuje **Generic+overlay** jako production-dominant pattern pro coding agents. Horizontální worktree paralelizace (ne specialist hierarchy) je Cursor's primární scaling mechanismus. HITL je dvouúrovňový (synchronous + YOLO opt-in), nikoliv per-stage gates. Plugin bundling (skills+subagents+MCP+hooks+rules) je Cursor's odpověď na composability challenge — direct parallel s tím, co ceos-agents řeší pro v8.0.0.
