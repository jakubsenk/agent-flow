# Sub-projekt A — Agent Shape Rework: Research Questions (DRAFT)

**Verze:** DRAFT 1
**Datum:** 2026-04-26
**Cílový release:** v8.0.0 (společně se sub-projektem B Human-in-the-Loop)
**Status:** Research zadání čeká na dokončení v7.0.0 forge runu, pak `forge-research`

---

## Kontext

Sub-projekt A z roadmapu (`docs/plans/roadmap.md` řádky 1009–1019) má rozhodnout finální tvar agentů ceos-agents před public release. Výchozí stav:

- 21 generických agentů v `agents/*.md` (markdown + YAML frontmatter)
- 3 hardcoded pipelines: `fix-bugs`, `implement-feature`, `scaffold` (~600 řádků markdown each)
- Customization přes `Agent Overrides` (append-to-prompt) + Pipeline Profiles (skip/extra stages) + Hooks
- Filozofie: pure markdown, no build system, no runtime

Tři architektonické varianty pojmenované v roadmapu:
- **Generic+overlay** (current) — sdílení agenti + per-project overlay soubory
- **Per-project** — každý projekt má vlastní agent set
- **Meta-gen** — meta-agent generuje agenty/pipelines per-projekt z popisu

Před A.1 brainstormingem (rozhodnutí shape) potřebujeme A.0 research: hloubková analýza best practices a konkurence.

## Scope research runů

- **2 staged forge research runs:**
  1. **Run 1:** C1 + C2 + C3 + C4 (Q1–Q11) + Q12 (framework discovery)
  2. **Run 2:** Q13–Q21 (deep-dives 10 frameworků z Q12) + **Q22 (cross-run paradigm synthesis, čte Run 1 final.md)**
- **Hloubka:** N paralelních agentů per Q (forge default 5) + synthesis agent + review loop max 3 round (Tier 1 + Tier 3 quality gates)
- **Token budget:** unrestricted
- **Output:** Run 2 final.md = synthesizovaný report přes obě fáze → vstup do A.1 brainstorm

### Model assignment

Ověřeno v `filip-superpowers/0.9.19/skills/forge-research/SKILL.md:57`:

| Fáze | Model |
|---|---|
| Phase 1 (question generation) | sonnet (forge hardcoded) |
| Phase 2 (answer synthesis, vč. Q22 cross-run synthesis) | sonnet (forge hardcoded) |
| Phase 2 review loops | sonnet (forge hardcoded) |

Forge `forge-research` produkuje **structured synthesized final.md** po každém runu — score-based selection nad N agent reporty + Tier 1/Tier 3 review-loop quality gates. Žádný separate post-forge dispatch není potřeba.

---

## C1 — Agent prompt engineering

### Q1 — Hloubka agent system promptu

Jak hluboko psát agent system prompt? Spektrum:

- **Minimalistický prompt** + agent čte docs (CLAUDE.md, README, source) at runtime
- **Maximalistický prompt** — všechno do definice (current ceos: 100–500 řádků markdown s Process kroky, Constraints, Examples)

Jaké jsou trade-offs (token cost, drift, maintainability, agent reliability)? Co doporučují prompt engineering guides z **2025–2026** (Anthropic, OpenAI, akademická literatura)? Jaký je dopad zásadních změn v 2026 (Claude 4.x family, OpenAI o3/o4 reasoning models, větší context windows, lepší tool-use) na agent prompt design best practices? Změnily se doporučení mezi 2025 a 2026?

### Q2 — Granularita agenta

Jaká je optimální granularita jednoho agenta? Spektrum:

- **Velké role** (BMAD style: PM + Architect + Dev — agent dělá víc fází)
- **Úzká specializace** (current ceos: triage-analyst + code-analyst + fixer + reviewer + …)

Kdy se vyplatí který přístup? Existují empirická data (success rate, hallucination rate, task completion rate)?

### Q3 — Univerzální vs per-projekt vs hybrid agent

Má být fixer (a další execution agenti) specificky komponován per-projekt, nebo univerzální? Spektrum:

- **Fully generic** (current ceos: jeden fixer pro vše)
- **Fully per-project** (fixer-django, fixer-react, fixer-oraclepl-sql)
- **Hybrid** — generic core + project-specific tail (např. fixer-base.md sdílený + fixer-django.md jen domain-specific deltas, vrstvený jako dědičnost)

Za jakých podmínek vyhrává která varianta? Jaké jsou reálné implementace v ekosystému?

### Q4 — Stateful vs stateless agenti

Má si agent pamatovat napříč iteracemi (thread-style — fixer si pamatuje předchozí pokusy v rámci jednoho ticketu), nebo dostane každý dispatch čistý kontext (current ceos: stateless, kontext předán explicitně)? Jak to řeší konkurence (CrewAI threads, LangGraph state, AutoGen GroupChat memory)? Jaké jsou trade-offs (token cost, drift, předvídatelnost)?

---

## C2 — Pipeline architecture

### Q5 — Hardcoded vs declarative vs meta-generated pipelines

Tato klastr je rozdělen do 4 sub-otázek pro evidence-based zodpovězení.

#### Q5a — Pipeline shape diversity v ekosystému

Jaká je reálná diversity v pipeline shape napříč top-10 prozkoumanými frameworky (Q12)?

Měřitelně:
- Počet různých stage orderings
- Počet různých HITL placement strategií
- Počet různých agent-set kompozic per použití
- Distribuce: dominantní vzory vs long tail

Output: matrice frameworků × shape characteristics.

#### Q5b — Migration ROI evidence

Existují empirické case studies pro migrace markdown/code-driven → declarative pipeline (Jenkins → Tekton, Travis → GH Actions, BMAD evolution, AutoGen → Magentic-One, jiné agent frameworks)?

- Co byl reportovaný cost migration?
- Co reálný ROI (rychlost onboarding, error rates, customization adoption)?
- Co lessons learned?
- Cituj konkrétní zdroje.

#### Q5c — LLM-as-config-interpreter reliability

Empirická data: jak často LLM mistakuje při dispatch podle YAML/JSON configu vs LLM-as-skill-executor (markdown prose)?

Zdroje:
- LangGraph experiments (deterministic state machines)
- AutoGen, CrewAI dispatch reliability papers
- Anthropic structured output benchmarks 2025–2026
- OpenAI o3/o4 reasoning model experiments na agent control flow
- Akademické práce na "LLM as orchestrator" reliability

#### Q5d — Public release expectations

Co dnes uživatelé Claude Code plugins (a obecně agent framework users) očekávají od customization mechanism? Čistě markdown overlay, JSON config, YAML pipeline, Python hooks, něco jiného?

Survey komunity:
- HN, Reddit /r/ClaudeAI, /r/LocalLLaMA
- X/Twitter agent community
- Existing top plugins: BMAD, mcp-server-deepwiki, claude-code-spec, awesome-claude-code-plugins

Jaký mechanism reálně používají top adopted plugins/frameworks?

### Q6 — Human-in-the-loop placement

Kde dávat approval gates v agent pipeline? Spektrum:

- **Zero gates** (fully autonomous, current ceos `--yolo`)
- **Gate per stage** (každý agent dostane review)
- **Strategické gates** (jen klíčové: po triage, před PR)
- **Event-driven** (gate jen když confidence < threshold)

Best practices z research literatury? Jak to BMAD, CrewAI, AutoGen, LangGraph řeší? Jaký je trade-off mezi automation throughput a quality control?

(Tato otázka přesahuje s sub-projektem B — výsledky budou sdíleny.)

### Q7 — Sub-agent dispatch vs in-agent tool-use

Má fixer dispatchnout reproducera jako sub-agenta, nebo si reproducera dělat sám pomocí Bash + Playwright? Kdy se vyplatí orchestration overhead a kdy je kontraproduktivní?

Best practices? Existuje paralela s "microservices vs monolith" diskuzí v software architecture? Jak to řeší konkurence?

---

## C3 — Configuration philosophy

### Q8 — Generic+overlay vs per-project vs meta-gen

Finální architektonická volba pro shape 21 agentů. Které varianty reálně používá kdo, proč, s jakými výsledky?

Specificky:
- Update flow (plugin update vs project-specific override divergence)
- Onboarding cost (jak rychle nový projekt rozjede)
- Maintenance burden (kdo udržuje co)
- Customization power (co se reálně dá změnit)
- Error surface (kde se to láme)

### Q9 — Pipeline as config DSL expressiveness

Pokud Q5 vyjde declarative, jak silný DSL? Spektrum:

- **YAML s jednoduchým seznamem stages** (statický)
- **+ Conditional logic** (`on_skip:`, `if:`)
- **+ Full programovatelný graph** (LangGraph style)
- **+ Turing-complete** (Temporal style)

Kde je optimum mezi expressiveness a usability pro non-developer uživatele? Existují případy, kdy DSL přerostl do Turing-tarpit (Jenkins Jobs DSL, GitHub Actions, Argo Workflows)? Jaké jsou lessons learned?

---

## C4 — Quality measurement

### Q10 — Benchmarking metrics

Jak benchmarknout agent architectures? Jaké metriky používá:

- Akademická literatura (SWE-bench, HumanEval, GAIA)
- Open-source benchmarks (MetaGPT experiments, AutoGen evaluations)
- Produkční nástroje (Cursor, Cline, Aider — co měří, jak reportují)

Konkrétní metriky:
- Success rate (task completion)
- Token cost per task
- Time-to-resolution
- Clarification rate
- Regression rate
- Human intervention rate

Jak je možné některé z těchto metrik měřit v ceos-agents kontextu (markdown plugin bez runtime)?

### Q11 — Trade-off matrix template

Pro každou variantu z Q5/Q8 zkonstruovat empirickou trade-off matrici (alespoň ordinální škála s evidence-based scores):

- Onboarding cost
- Token cost
- Maintenance burden
- Customization power
- Error surface
- Public-release readiness

Cílem je matrice s konkrétními zdroji per cell, kterou v A.1 brainstormu použijeme jako rozhodovací rámec. Žádné subjective ratings — jen evidence-based.

---

## C5 — Competitive landscape

### Q12 — Framework discovery & shortlist

Hluboce prohledej ekosystém **agent orchestration / SWE agent frameworků** stav k 2026-04. Zdroje:

- GitHub trending (last 90 days)
- Hacker News (last 90 days)
- arxiv-sanity (last 6 months)
- Latent Space podcast, Anthropic/OpenAI blog
- awesome-llm-agents lists, awesome-claude-code-plugins
- X/Twitter agent community
- Reddit /r/LocalLLaMA, /r/ClaudeAI

Vytvoř ranked shortlist 15–20 nejvýznamnějších frameworků. Auto-scoring kritéria:

1. **GitHub stars trend** (delta last 90 days, ne absolutně — preferuj momentum)
2. **Search visibility** (HN mentions last 90 days, Reddit thread count, X agent community attention)
3. **Production adoption signal** (case studies, enterprise testimonials, named users)
4. **Active dev** (commits last 30 days)
5. **Architecture novelty** (paradigm distinct od ostatních — ne 5 LangGraph clonů)

Output: tabulka 15–20 entries s 1–3 sentence summary + URL + score per criterion + "why include" justifikace.

**Selection:** Top 10 podle weighted score, judge vybere automaticky bez user gate. Pokud najdeš podivné findings (např. nikdo neslyšený framework s top score), označ to v reportu, ale shortlist neblokuj.

### Q13–Q22 — Framework deep-dives (placeholders)

Po Q12 sepíšeme konkrétní deep-dive otázky pro vybraných 10 frameworků. **Šablona pro každý framework:**

> Q{N} — {Framework Name}
>
> Hluboká analýza:
> - Jak strukturuje agenty (granularita, role definition, prompt strategy)
> - Jak konfiguruje pipelines (markdown / YAML / JSON / code / meta-gen)
> - Jak řeší per-project customization (overlay / inheritance / generation)
> - HITL pattern (kde a jak)
> - Stateful vs stateless agent design
> - Co lze přenést do markdown-only Claude Code plugin
> - Co je framework-specific (runtime, language lock-in)
> - Citace na docs + GitHub source files

**Konkrétní 10 frameworků** se vyplní po výsledku Q12.

---

## Synthesis (Q22)

### Q22 — Cross-run paradigm synthesis

**Q22 je poslední otázkou v Run 2.** Forge `forge-research` ji zpracuje stejně jako ostatní Q (paralelní agenti → synthesis → review loop), ale s **explicitním pokynem číst Run 1 final.md jako kontext**, aby výstup pokrýval evidence z obou runů.

**Formulace pro Run 2 prompt:**

> Q22 — Přečti **Run 1 final.md** (`.forge/{run-1-name}/phase-2-research-answers/final.md`) i tento Run 2 souhrn (Q13–Q21 reporty od ostatních agentů) a vyrob cross-run paradigm synthesis:
>
> 1. **Komparativní matrice** (frameworks × dimensions) s evidence-based scores napříč všemi Q1–Q21
> 2. **Identifikace 2–3 paradigmat** v ekosystému (např. graph-based vs conversation-based vs workflow-based)
> 3. **Doporučení jednoho paradigmatu** pro ceos-agents v8.0.0 s explicit trade-offs
> 4. **Evidence trail per claim** — každý claim citovaný na konkrétní Q z Run 1 nebo Run 2
>
> Output: section-ready vstup pro A.1 brainstorm a následný `2026-04-MM-A-agent-shape-design.md` spec.

**Konstrukce výstupu MUSÍ být evidence-based** — každý claim s citací na zdroj z Q1–Q21. Žádné apriori biases.

---

## Out of scope

- Implementační detaily (čekají na A.1 brainstorm po dokončení research)
- Migration plan (čeká na rozhodnutí shape v A.1)
- Code changes v repu (research je read-only analýza)
- Sub-projekt B (Human-in-the-loop) — paralelní brainstorm, výsledky Q6 budou sdíleny, ale design je separate

## Dependencies

- **Před spuštěním:** dokončení v7.0.0 forge run (jiný terminál, 2026-04-26 in progress)
- **Po dokončení:** A.1 brainstorm s research v ruce → `2026-04-MM-A-agent-shape-design.md` spec → v8.0.0 forge execution

## Questions remaining open

Tyto budou odpovězeny během psaní finálního spec (A.1):

- Jaký je expected impact na backwards compatibility (v7 → v8)?
- Jak moc se o tomto rozhodnutí v A.1 brainstormu mluvit s uživateli komunity (alpha announcement)?
- Je potřeba prototyp / spike před finálním rozhodnutím?
