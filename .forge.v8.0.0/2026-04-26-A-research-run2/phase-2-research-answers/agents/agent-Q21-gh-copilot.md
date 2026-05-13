# Q21 — GitHub Copilot Coding Agent: Hluboká analýza

**Agent:** Q21-gh-copilot  
**Run:** 2026-04-26-A-research-run2  
**Datum:** 2026-04-26  
**Lens:** vendor (primary) + production (secondary)  
**Rozsah:** 8 dimenzí + exec summary + comparison table  
**Status:** FINAL

---

## Lens disclosure

Tento report pracuje primárně z **vendor-published public claims** (github.blog, docs.github.com, GitHub Changelog). GitHub Copilot Coding Agent je **closed-source** — žádný zdrojový kód není veřejný. Veškerá evidence o interní architektuře je proto **vendor-narrative**: co GitHub publikoval v blogu, dokumentaci a changelogu, nikoli co je verifikovatelné nezávislou analýzou zdrojového kódu. Všechna tvrzení o sub-agent kompozici jsou odvozena z veřejných popisů UX a API, ne z inspekce kódu. Kde existuje rozdíl mezi "vendor claim" a "verifikovatelný fakt," je to explicitně označeno.

---

## Executive summary

GitHub Copilot Coding Agent je **nejbližší production analogon k ceos-agents implement-feature pipeline**: asynchronní issue-to-PR workflow, spec → plan → implement → review gate pattern, human-in-the-loop pouze na strategických bodech, a customizace přes repo-level instrukční soubory. V průběhu dubna 2024 (Workspace preview) → září 2025 (Coding Agent GA) → dubna 2026 (research/plan/code rozšíření) prošel produkt výraznou evolucí.

Klíčové empirické nálezy:
- **4.7 milionů paid subscribers** k lednu 2026 (Microsoft FY26 Q2 earnings, verifikovatelný zdroj), nikoli "10M+". Run 1 final.md citoval "10M+ paid Copilot seats" — toto číslo se nepodařilo verifikovat; nejlepší dostupný zdroj uvádí 4.7M placených odběratelů GitHub Copilot.
- **Workspace → Coding Agent** přechod (květen 2025) je vendor-komunikovaná "product maturation," ne selhání; spec-plan-implement pipeline zachována, ale přestavěna do async GitHub-nativního modelu.
- **Sub-agent architektura** je z dubna 2026 veřejně dokumentována: custom agents + plan agent jako rozlišené komponenty — ale interní model routing (který model obsluhuje která fáze) není zveřejněn.
- **HITL je "strategic gates" exemplar**: jeden strategický gate (PR review + merge), volitelný gate (plan approval před implementací), semi-automatický gate (CI/CD checks). Žádné per-step approval gates.
- **Customizace** jde přes hierarchii souborů (org → repo → path-specific), nikoli přes pipeline-as-config.
- **Přenositelné do markdown-only pluginu:** spec → plan → implement gate pattern, issue-to-PR asynchronní primitiv, hierarchická instrukční customizace.
- **Framework-specifické:** GitHub Actions compute backend, closed-source agent routing, GitHub Cloud dependency, enterprise firewall model.

---

## Dimenze 1 — Granularita agentů

### Co je veřejně dokumentováno

GitHub nikdy nezveřejnil kompletní seznam interních sub-agentů Coding Agenta. Z veřejné dokumentace a changelogů lze rekonstruovat **3 rozlišené komponenty**:

1. **Plan Agent** (dokumentován explicitně jako "plan agent" v GitHub Changelog 2026-03-11): "Ask Copilot to produce an implementation plan and review the approach before Copilot writes any code." Generuje implementační plán, čeká na uživatelský feedback před tím, než začne psát kód. — [GitHub Changelog 2026-04-01](https://github.blog/changelog/2026-04-01-research-plan-and-code-with-copilot-cloud-agent/)
2. **Research Agent** (dokumentován od dubna 2026): "Kick off a research session to answer questions requiring thorough investigation and comprehensive answers." Slouží k průzkumu codebase bez generování kódu. — [docs.github.com: research-plan-iterate](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/research-plan-iterate)
3. **Repair/Implementation Agent** (implicitní): agent, který reálně generuje code changes, spouští testy a opravuje CI failures. Copilot Workspace (2024) tento komponent nazýval "Repair Agent."

**Copilot Workspace (2024) přidával také Brainstorm Agent** — diskuse ambiguit před spec fází. Po přechodu na Coding Agent není jasné, zda Brainstorm Agent přežil jako separátní komponenta, nebo byl absorbován do Research phase.

**Custom Agents** (custom sub-agents): od října 2025 je možné přidat vlastní agenty jako `.github/agents/*.yml` definice. Každý custom agent má vlastní system prompt, omezení nástrojů a MCP servery. Copilot SDK runtime provádí **automatic delegation** na základě intent matching — odpovídající požadavek → sub-agent spuštěn v izolovaném kontextu. — [docs.github.com: custom-agents](https://docs.github.com/en/copilot/how-tos/copilot-sdk/use-copilot-sdk/custom-agents), [GitHub Changelog 2025-10-28](https://github.blog/changelog/2025-10-28-custom-agents-for-github-copilot/)

**Verifikační omezení:** GitHub nikde nepublikoval diagram "fáze X → model Y → sub-agent Z." Interní model routing (který model — GPT-4o, Claude, Gemini — obsluhuje jakou fázi) není zveřejněn. Vendor popis "sub-agent architecture" je UX-level popis, ne technical architecture diagram. Tvrzení Run 1 final.md o "Spec Agent + Plan Agent + Implementation Agent + Review Agent (4 komponenty)" je **konstrukt z community zdrojů** (Java Code Geeks, NxCode.io) kombinovaný s Workspace dokumentací — nikoli přímá GitHub citace.

**Srovnání s ceos-agents:** ceos-agents implementuje 21 explicitních agentů jako separátní markdown soubory. Copilot pravděpodobně implementuje menší počet interních komponent (odhad 3–5 na základě veřejných popisů), plus neomezený počet uživatelsky definovaných custom agents. Granularita směrem dovnitř je tedy **menší nebo srovnatelná**, ale extensibility mechanizmus (custom agents) je formálněji strukturovaný.

---

## Dimenze 2 — Pipeline configuration mechanism

### Hardcoded vs konfigurovatelná pipeline

Copilot Coding Agent pipeline je **hardcoded v GitHub backendu** — uživatel ji nemůže rekonfigurovat přes projekt-level config. Neexistuje `copilot-pipeline.yaml` nebo ekvivalent, který by definoval pořadí fází. Pořadí research → plan → implement → review je fixní produkt GitHub.

**Co je konfigurovatelné:**
- Zda agent začne s implementačním plánem (user prompt instruuje — "create a plan first")
- Zda PR vznikne ihned nebo až po explicitním uživatelském příkazu (od dubna 2026: Copilot může pracovat na branchi bez okamžitého otevření PR)
- Jaké custom agents jsou k dispozici a kdy se spouštějí (intent matching, viz Dimenze 1)
- Jaké MCP servery má agent k dispozici
- Firewall rules pro internet access

**Trigger mechanizmus:** issue assigned to Copilot → agent se spustí asynchronně. Od dubna 2026 lze agent spustit také z Agents Panel, Copilot Chat (VS Code), GitHub Mobile. — [GitHub Blog: Agents Panel](https://github.blog/news-insights/product-news/agents-panel-launch-copilot-coding-agent-tasks-anywhere-on-github/)

**Stateless vs stateful konfigurace:** Pipeline konfigurace je **stateless** — načítá se z repo souborů při každém spuštění, není uložena v databázi. Agent session je ale **stateful** — Copilot pushuje commity průběžně do draft PR a uživatel sleduje progress v session logu.

**Implikace pro ceos-agents:** Copilot neposkytuje pipeline-as-config precedent. Customizace pipeline shape přes YAML DSL je plně vendor-specifická feature Copilota, která není dostupná uživatelům. To reaffirmuje Run 1 finding: žádný major vendor neimplementuje user-exposed YAML-pipeline-as-control-flow-DSL.

---

## Dimenze 3 — Per-project customization

### Hierarchie instrukčních souborů (jako of 2026-04)

Copilot Coding Agent podporuje **víceúrovňovou hierarchii** instrukčních souborů:

**Úroveň 1 — Organizace:**
- Org-level custom instructions nastaveny administrátorem. Od listopadu 2025. — [GitHub Changelog 2025-11-05](https://github.blog/changelog/2025-11-05-copilot-coding-agent-supports-organization-custom-instructions/)

**Úroveň 2 — Repozitář (globální):**
- `.github/copilot-instructions.md` — primární soubor, plain Markdown. Čteno všemi Copilot agenty (chat + coding agent + code review). — [docs.github.com: adding-custom-instructions](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot)
- `AGENTS.md` v root repo — od srpna 2025; interoperabilní s Devin, Claude Code, Gemini CLI. — [GitHub Changelog 2025-08-28](https://github.blog/changelog/2025-08-28-copilot-coding-agent-now-supports-agents-md-custom-instructions/)
- `CLAUDE.md`, `GEMINI.md` — od srpna 2025 čteny Copilot Coding Agentem

**Úroveň 3 — Cesta v repozitáři (path-specific):**
- `.github/instructions/*.instructions.md` — od července 2025. `applyTo:` frontmatter property specifikuje path glob. — [GitHub Changelog 2025-07-23](https://github.blog/changelog/2025-07-23-github-copilot-coding-agent-now-supports-instructions-md-custom-instructions/)
- `excludeAgent:` property od listopadu 2025 — kontroluje, které Copilot agenty daný soubor ignorují. — [GitHub Changelog 2025-11-12](https://github.blog/changelog/2025-11-12-copilot-code-review-and-coding-agent-now-support-agent-specific-instructions/)

**Úroveň 4 — Custom agents (`.github/agents/*.yml`):**
- YAML frontmatter s `name:`, `description:`, `instructions:`, `tools:`, `mcpServers:`. — [docs.github.com: custom-agents-configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration)

**Auto-generování instrukcí:** od srpna 2025 Copilot umí automaticky generovat `copilot-instructions.md` na základě analýzy repozitáře. — [GitHub Changelog 2025-08-06](https://github.blog/changelog/2025-08-06-copilot-coding-agent-automatically-generate-custom-instructions/)

**Srovnání s ceos-agents Agent Overrides:** ceos-agents `customization/{agent-name}.md` je append-to-prompt pattern pro každý pojmenovaný agent. Copilot hierarchie je sofistikovanější — path-specific scope, excludeAgent granularita, org-level — ale cílí na stejný use case: project-specific instructions bez forku.

---

## Dimenze 4 — HITL pattern

### Strategic gates exemplar

Copilot Coding Agent je **nejjasnějším production exemplarem "strategic gates" HITL patternu** v ekosystému (per Run 1 Q6 finding). Konkrétní implementace:

**Gate 1 — Plan approval (volitelný):**
Uživatel může říct "create a plan first." Copilot vygeneruje implementační plán a čeká na approval nebo feedback před tím, než napíše kód. Pokud uživatel nežádá plán explicitně — agent přeskočí gate a jde rovnou do implementace. — [docs.github.com: research-plan-iterate](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/research-plan-iterate), [GitHub Changelog 2026-04-01](https://github.blog/changelog/2026-04-01-research-plan-and-code-with-copilot-cloud-agent/)

**Gate 2 — PR review (povinný, strategický):**
Copilot otevírá **draft PR** — tím dostane uživatel signal. Uživatel musí manuálně:
1. Zkontrolovat diff (Review the diff button)
2. Schválit PR (GitHub PR review workflow)
3. Schválit spuštění CI/CD (GitHub Actions čekají na approval)
Copilot **nemůže schválit vlastní PR** ani **spustit CI bez approval.** — [docs.github.com: about-coding-agent](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-coding-agent)

**Gate 3 — CI/CD (semi-automatický):**
GitHub Actions runs vyžadují lidské schválení před spuštěním pro Copilot PRs. To je security gate, ne jen quality gate. "Built with security in mind, coding agent's pull requests require human approval before any CI/CD workflows run." — [github.blog: meet-the-new-coding-agent](https://github.blog/news-insights/product-news/github-copilot-meet-the-new-coding-agent/)

**Co je plně autonomní (bez gate):**
- Research fáze (codebase průzkum)
- Commit pushování průběžně do draft PR
- Spouštění testů uvnitř ephemeral environment
- Oprava CI failures (pokud environment to umožňuje)

**Klíčová vlastnost:** uživatel sleduje progress v real-time přes session log, ale **neintervenuje per-step**. Jediná nutná akce = schválení PR + CI. Toto je "strategic gates" pattern per definici z Run 1 Q6 taxonomie (Anthropic checkpoint-or-blocker pattern analog).

**Srovnání s ceos-agents:** ceos-agents má 3 confirmation points v implement-feature: Step 0c (card creation), Step 5 (decomposition plan), Step 9 (PR creation). Copilot má analogicky Plan Gate (volitelný) + PR Gate (povinný). Oba systémy sdílejí stejný philosophical model — **strategické zásahy, ne per-step.**

---

## Dimenze 5 — Stateful vs stateless agent design

### Session model

Copilot Coding Agent je **stateful uvnitř session, stateless mezi sessions**.

**Stateful uvnitř session:**
- Agent udržuje kontext celé session (file changes, test outputs, tool call history)
- Průběžně pushuje commity do draft PR — stav je externalizován do gitu
- Session log je persistent a čitelný uživatelem kdykoli během nebo po session
- Ephemeral environment (GitHub Actions runner) přežívá celou session — není per-step restartován — [docs.github.com: cloud-agent](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent)

**Stateless mezi sessions:**
- Každé přiřazení issue Copilotovi spouští novou session s čistým kontextem
- Custom instructions se re-načítají z instrukčních souborů při každém spuštění
- Žádná cross-session paměť (na rozdíl od Claude Code's persistent memory subagents)

**GitHub Actions jako compute backend:**
Ephemeral environment je powered by GitHub Actions. Dostupné nástroje: bash, python, git, test runners, linters — vše co je nainstalováno v CI/CD environment projektu. Organizace mohou konfigurovat custom runners (ARC, Actions Runner Scale Set). — [docs.github.com: customize-the-agent-environment](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/customize-the-agent-environment)

**Firewall a security isolation:**
Built-in agent firewall omezuje internet access. Konfigurovatelné od července 2025 (per-domain allowlist). Org-level firewall settings od dubna 2026. — [GitHub Changelog 2026-04-03](https://github.blog/changelog/2026-04-03-organization-firewall-settings-for-copilot-cloud-agent/)

**Srovnání s ceos-agents:** ceos-agents je "stateless dispatch + explicit summary handoff" — každý agent dostane kontext přes Task(context=...) call, bez sdílené session paměti. Stav pipeline je exernalizován do `state.json` (analogicky Copilot exernalizuje do git commits + draft PR). Oba přístupy jsou **funkčně hybridní**: stateless agenti, stateful pipeline state.

---

## Dimenze 6 — "Lessons learned": timeline a retrospektiva

### Kompletní timeline s evidencí

**Duben 2024 — Copilot Workspace technical preview:**
GitHub Next spustil Copilot Workspace jako browser-based environment. Pipeline: Issue → Brainstorm Agent → Spec (current vs desired state) → Plan (file-level actions per file) → Implementation → Repair Agent (fixes CI errors). Uživatel mohl editovat spec i plán v UI před implementací. "Natural language to working code, via a spec-plan-implement pipeline." — [githubnext.com/projects/copilot-workspace](https://githubnext.com/projects/copilot-workspace)

**Mezikrok 2024–2025 — Feedback accumulation:**
Developers loved the concept and filed a lot of bug reports. Workspace byl "technical preview" — experimentální, bez production SLAs. Hlavní limity: (a) samostatná browser-only UX mimo GitHub.com native flow, (b) silná závislostiní na lineárním GUI workflow (spec → plan → impl), (c) nedostatečná integrace do GitHub Actions CI, (d) modely 2024 ještě nedosahovaly potřebné reliability pro autonomní implementaci.

**30. května 2025 — Workspace sunset:**
GitHub official statement: "GitHub took everything learned from Copilot Workspace — the sub-agent architecture, the issue-to-PR workflow, the asynchronous execution model — and rebuilt it as the Copilot Coding Agent." Toto je vendor-narrative. Nezávislé hodnocení: šlo o **product consolidation** — Workspace jako separátní produkt byl neudržitelný, core IP bylo absorbováno. — [github.com: orgs/community/discussions/159068](https://github.com/orgs/community/discussions/159068)

**Prosinec 2024 / leden–červen 2025 — Interní rebuild + public preview:**
Copilot Coding Agent public preview: [GitHub Changelog 2025-05-19](https://github.blog/changelog/2025-05-19-github-copilot-coding-agent-in-public-preview/). Klíčová změna oproti Workspace: agent je GitHub-nativní (issue assignment trigger, draft PR, GitHub Actions ephemeral env), ne browser-only tool.

**Září 2025 — Coding Agent GA:**
Generally available pro všechny paid Copilot subscribers. — [github.com: orgs/community/discussions/159068](https://github.com/orgs/community/discussions/159068)

**Říjen–prosinec 2025 — Customization expansion:**
- Custom agents (`.github/agents/`) — říjen 2025
- AGENTS.md, CLAUDE.md, GEMINI.md support — srpen 2025
- Org-level custom instructions — listopad 2025
- `excludeAgent:` property — listopad 2025
- Agent Skills — prosinec 2025 — [GitHub Changelog 2025-12-18](https://github.blog/changelog/2025-12-18-github-copilot-now-supports-agent-skills/)

**Leden 2026 — Adoption milestone:**
**4.7 milionů paid GitHub Copilot subscribers** (75% YoY growth) per Microsoft FY26 Q2 earnings call 2026-01-28. Největší enterprise deploymenty: Publicis 95,000 seats, deployments >35,000 seats u více zákazníků. — [windowsforum.com: microsoft-copilot-15m-seats-4-7m-subscribers](https://windowsforum.com/threads/microsoft-copilot-hits-15-million-paid-seats-and-4-7-million-github-subscribers.400630/)

**OPRAVA RUN 1: "10M+ paid Copilot seats"** — toto číslo se nepodařilo verifikovat jako paid subscribers pro GitHub Copilot. Číslo 4.7M je nejlepší dostupný verifikovatelný zdroj (Microsoft earnings, Q1 2026). Číslo 20M je "all-time users" (broader, includes free tier), reportováno TechCrunch k červenci 2025. — [techcrunch.com: github-copilot-crosses-20m-users](https://techcrunch.com/2025/07/30/github-copilot-crosses-20-million-all-time-users/)

**Únor–duben 2026 — Research/Plan/Code expansion:**
- Více viditelnosti do session logs — únor 2026 — [GitHub Changelog 2026-03-19](https://github.blog/changelog/2026-03-19-more-visibility-into-copilot-coding-agent-sessions/)
- Plan agent GA v JetBrains — březen 2026 — [GitHub Changelog 2026-03-11](https://github.blog/changelog/2026-03-11-major-agentic-capabilities-improvements-in-github-copilot-for-jetbrains-ides/)
- **Research, plan, and code** — nový 3-fázový workflow, branching bez okamžitého PR — [GitHub Changelog 2026-04-01](https://github.blog/changelog/2026-04-01-research-plan-and-code-with-copilot-cloud-agent/)
- Agents Panel — spouštění tasků kdekoli na GitHub — [github.blog: agents-panel](https://github.blog/news-insights/product-news/agents-panel-launch-copilot-coding-agent-tasks-anywhere-on-github/)
- GitHub Mobile support — duben 2026 — [GitHub Changelog 2026-04-08](https://github.blog/changelog/2026-04-08-github-mobile-research-and-code-with-copilot-cloud-agent-anywhere/)

### SWE-bench performance

GitHub Copilot agent mode s Claude 3.7 Sonnet dosahuje **56% pass rate na SWE-bench Verified** (reportováno digitailapplied.com, duben 2026). Run 1 citoval SWE-bench Pro "22-point scaffold swing" — toto platí i pro Copilot: výkon silně závisí na quality instrukčních souborů a environment setupu. Vendor nepublikuje SWE-bench Verified čísla přímo — všechna benchmark data jsou z community a third-party zdrojů.

### Proč Workspace selhal jako separátní produkt

Analýza na základě vendor-komunikovaných důvodů + community pozorování:
1. **UX isolace:** Workspace žil na separátní URL (githubnext.com), ne na github.com — friction pro adoption
2. **Model omezení 2024:** modely tehdejší generace nedosahovaly dostatečné reliability pro autonomní implementaci v produkčních repozitech
3. **GitHub Actions integrace:** Workspace neintegrovalo ephemeral CI environments — code changes nebyly automaticky testovány v reálném CI
4. **Lineárnost flow:** Workspace vyžadovalo browser UI pro každý krok — nebyla možná async background execution
5. **Timing:** GA Coding Agent přišel až po release modelů (GPT-4o, Claude 3.5/3.7 Sonnet), které umožnily spolehlivější autonomii

**Vendor framing:** "Not deprecated — matured into production." Toto je credible, ne jen spin: core spec-plan-implement pipeline survives, ale implementace je radikálně odlišná (GitHub-native, async, Actions-powered).

---

## Dimenze 7 — Co lze přenést do markdown-only Claude Code pluginu

*Toto je primární hodnotová sekce tohoto reportu.*

### A) Spec → Plan → Implement → Review gate pattern

**Co Copilot dělá:** uživatel může explicitně požádat o plán před implementací. Agent generuje plán, čeká na human review/feedback, pak implementuje. Plan Gate je **opt-in** (uživatel musí instruovat — agent neprovede automaticky).

**Co ceos-agents dělá analogicky:** implement-feature Step 5 = Decomposition Plan s explicit user approval gate (`Continue? [Y/n]`). Architect agent generuje task tree, uživatel schvaluje, pak fixer implementuje. YOLO mode auto-approves.

**Klíčový rozdíl:** Copilot Plan Gate je **user-triggered** (uživatel říká "create a plan first" v promptu), ne automatický krok pipeline. ceos-agents Decomposition Gate je **pipeline-triggered** (automaticky se spouští pokud `decompose_mode != DISABLED`). Copilot flexibilita umožňuje single-pass bez plan review, ceos-agents to řeší přes `--no-decompose` flag.

**Přenositelná lesson:** Plan Gate jako opt-in (user request) vs povinný (pipeline step) — Copilot ukazuje, že pro smaller features je friction Gate nevítaná. ceos-agents `--no-decompose` flag to řeší, ale pro single-pass features (bez decomposition) chybí analogon "opt-in plan review." Tento gap je malý ale reálný.

### B) Issue-to-PR async primitiv

**Co Copilot dělá:** GitHub Issue assigned to Copilot → agent běží na pozadí → draft PR otevřen → uživatel dostane notification. Asynchronní model — uživatel nemusí čekat.

**Co ceos-agents dělá analogicky:** `/ceos-agents:autopilot` je nejbližší analog — batch headless dispatcher. `/ceos-agents:fix-ticket` a `/ceos-agents:implement-feature` jsou semi-synchronní (uživatel čeká na completion v terminálu).

**Klíčový rozdíl:** Copilot je **nativně async** — agent session běží jako cloud job, uživatel dostane notification. ceos-agents je **synchronní** — Claude Code instance musí zůstat aktivní po celou dobu. Pro krátké tasky není rozdíl, pro dlouhé (>30 min) je to zásadní gap.

**Přenositelná lesson:** async execution model (job submission → notification → review) je odlišný paradigm než synchronní pipeline. Pro markdown-only plugin je nativní asynchnost nedosažitelná bez runtime infrastruktury. Ale: ceos-agents `autopilot` + Task Scheduler (Windows) nebo cron (Linux) je closest approximation.

### C) HITL gate placement: "strategic gates" pattern

**Copilot empirická evidence:** production system s 4.7M paid subscribers (leden 2026) validuje "strategic gates" jako viable default pro coding agent use case. Uživatelé akceptují autonomní coding s jedním strategickým gateem (PR review).

**Přenositelná lesson:** strategic gates (ne per-step) jsou production-validated HITL pattern pro coding agent workflows. ceos-agents Step 9 `Create PR? [Y/n]` je přesně tento pattern. **Přímá empirická validace ceos-agents HITL design.**

### D) GitHub Actions jako compute extension

**Co Copilot dělá:** agent spouští testy, linters, build příkazy v ephemeral GitHub Actions runner. Uživatel konfiguruje `copilot-setup-steps:` v `.github/workflows/` pro pre-provision tools.

**Implikace pro ceos-agents:** ceos-agents `Verify command` (runs after PR merge) je analogický post-merge verification hook. ceos-agents `Build command` a `Test command` jsou spouštěny lokálně v Claude Code session — ne v ephemeral CI. Ale pattern je shodný: build/test/verify jsou konfigurovatelné příkazy, ne hardcoded logika.

**Přenositelná lesson:** ceos-agents by potenciálně mohl emitovat GitHub Actions workflow YAML jako součást Publisher kroku (pre-merge), který by spustil verify pipeline na straně CI/CD. Toto je **future architecture option** — Copilot ukazuje, že Actions-as-extension-point je produkčně validovaný vzor.

### E) Hierarchická customizace instrukcí

**Co Copilot dělá:** org → repo → path-specific instrukce, auto-discovery, excludeAgent granularita.

**Co ceos-agents dělá:** `Agent Overrides` append-to-prompt pattern (flat, per-agent, ne per-path).

**Přenositelná lesson:** path-specific instructions (`applyTo: "src/api/**"`) jsou sofistikovanější než flat per-agent override. Pro ceos-agents v8.0.0: přidání path-scope do Agent Overrides (např. `customization/fixer-api.md` s `applyTo:` frontmatter) by zrcadlilo Copilot pattern bez nutnosti runtime infrastruktury.

### F) Spec-driven development jako separátní toolkit

GitHub vydal **`github/spec-kit`** jako open-source toolkit pro spec-driven development — nezávislý na Copilot Coding Agentovi, kompatibilní s Claude Code, Copilot, Gemini CLI. Spec Kit definuje proces: Product Requirements → Technical Spec → Implementation Plan → Code. Toto je **formalizace spec → plan → implement gate patternu** jako community standard. — [github.blog: spec-driven-development-toolkit](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/), [github.com/github/spec-kit](https://github.com/github/spec-kit)

**Přenositelná lesson:** spec-kit jako open-source standard potvrzuje, že spec → plan → implement je convergentní paradigma, ne Copilot-specifické. ceos-agents implement-feature pipeline je v souladu s tímto paradigmatem.

---

## Dimenze 8 — Co je framework-specific (nepřenositelné)

### GitHub vendor lock-in

1. **GitHub Actions compute backend:** Ephemeral runner, firewall, secrets access — vyžaduje GitHub Actions. Nelze replikovat v GitLab CI, Gitea Actions, nebo lokálním prostředí bez ekvivalentní infrastruktury.

2. **Closed-source agent routing:** Interní orchestrace (model selection, fáze, retry logic) je GitHub backend kód. Není dokumentována, není customizovatelná, není replikovatelná.

3. **GitHub Cloud dependency:** Copilot Coding Agent vyžaduje GitHub.com (nebo GitHub Enterprise Cloud). Není self-hostable. Gitea, GitLab, on-prem GitHub Server nemají Copilot Coding Agent.

4. **Issue-PR workflow integration:** Agent nativně čte GitHub Issues, pushuje do GitHub repos, otvírá GitHub PRs. Integrace je nativní pro GitHub — žádná konfigurace. ceos-agents musí tuto integraci konfigurovat přes `## Automation Config` (Issue Tracker, Source Control).

5. **Microsoft compute a model hosting:** Copilot model routing (výběr, který frontier model obsluhuje jakou fázi) je Microsoft interní. Uživatelé mají limited model choice (GitHub nabízí "your preferred model" v custom agents, ale interní routing phase agentů není exponován).

6. **Enterprise firewall a security model:** Built-in network isolation, org-level firewall configuration, prompt injection defense jsou enterprise features vyžadující GitHub Enterprise Cloud + přístupy na infra úrovni.

---

## Stage-by-stage comparison table: Copilot vs ceos-agents implement-feature

| Fáze | Copilot Coding Agent | ceos-agents implement-feature | Shodné? | Klíčový rozdíl |
|------|---------------------|-------------------------------|---------|----------------|
| **Trigger** | GitHub Issue assigned to Copilot; Agents Panel; Copilot Chat; GitHub Mobile | `/ceos-agents:implement-feature ISSUE-ID` nebo `--description "..."` | Částečně | Copilot = async cloud job; ceos = sync CLI session |
| **Pre-flight** | MCP tools check implicitní (GitHub nativní); firewall init | Step 0: MCP pre-flight; config validity gate (Step 0b) | Částečně | ceos má explicitní config validaci; Copilot má built-in firewall |
| **Specification** | Copilot Workspace (2024) měl explicit Spec phase; Coding Agent (2025+) = implicitní (z issue description); Spec Kit toolkit jako optional standard | Step 3: spec-analyst agent (sonnet) — čte issue, píše acceptance criteria, postuje zpět do trackeru | Částečně | Copilot neemituje explicitní spec artefakt jako standalone document; ceos emituje AC list jako trackeable artifact |
| **Research** | Research Agent (od dubna 2026) — opt-in, codebase průzkum před implementací | Step 3a: code-analyst agent (sonnet) — codebase impact analysis, ≤5 affected files | Shodné | Obě fáze jsou read-only codebase průzkum; Copilot opt-in, ceos automatický |
| **Architecture / Plan** | Plan Agent (opt-in, user-triggered) — implementační plán, čeká na human review | Step 4: architect agent (opus) — task tree, YAML, maps_to traceability; Step 5: decomposition decision + user approval gate | Shodné | Plan Gate: Copilot opt-in (uživatel říká "create a plan"); ceos automatický (decomposition decision) |
| **Plan Gate (HITL)** | Volitelný — uživatel musí explicitně požádat; agent čeká na feedback | Step 5: `Continue? [Y/n]` (skippable s --yolo); `--no-decompose` bypass | Shodné | Obě implementují opt-out plan review; Copilot opt-in, ceos opt-out |
| **Implementace** | Implementation Agent — kód změny, průběžné commity do draft PR | Step 6b: fixer agent (opus) — implementuje, ≤100 line diffs, max 5 Fixer iterations | Shodné | Copilot = continuous commit stream; ceos = iterative dispatch |
| **Code review** | GitHub PR review (human reviewer); žádný automatický review agent pro vlastní kód | Step 6d: reviewer agent (opus) — AC fulfillment check, REQUEST_CHANGES → fixer loop | Odlišné | Copilot spoléhá na lidského reviewera; ceos má automatický agent review |
| **Build / test** | Ephemeral GitHub Actions runner — build + test automaticky | Step 6d-smoke: Build command + Test command po reviewer approval; Step 6e: test-engineer agent | Shodné | Obě spouštějí build/test; Copilot v cloud, ceos lokálně |
| **Acceptance gate** | GitHub PR review = jediný acceptance mechanism | Step 6h: acceptance-gate agent (sonnet) — verifikuje AC fulfillment s kód evidencí | Odlišné | ceos má automatický AC verification krok; Copilot spoléhá na human reviewer |
| **PR Gate (HITL)** | Povinný — Copilot nemůže schválit vlastní PR; CI/CD vyžaduje human approval | Step 9: `Create PR? [Y/n]` (skippable s --yolo); publisher agent pak vytvoří PR | Shodné | Obě implementují PR jako HITL gate; Copilot má security enforcement, ceos je UX gate |
| **Customizace** | `.github/copilot-instructions.md`; AGENTS.md; `.github/instructions/*.instructions.md`; `.github/agents/*.yml` | `customization/{agent-name}.md` (Agent Overrides, append-to-prompt) | Shodné v principu | Copilot = hierarchická multi-level customizace; ceos = flat per-agent |
| **Stateful execution** | Session stateful (ephemeral runner přežívá celou session); git commits jako state exernalizace | `state.json` pipeline state; každý agent = stateless dispatch; state předán explicitně | Shodné | Obě exernalizují stav (git/JSON); obě jsou per-session stateful |
| **Post-publish** | PR merged → CI/CD spuštěno (automatické) | Step 10b: Verify command po PR merge (volitelný) | Shodné | Obě mají post-merge verification hook |
| **Error handling** | Agent session log — uživatel vidí co se stalo; žádný structured block comment | Block handler → Block Comment Template → rollback-agent; state.json block object | Odlišné | ceos má formalizovaný block protokol; Copilot má ad-hoc session logs |
| **Async model** | Nativně async — cloud job, notification, background execution | Synchronní v CLI; autopilot jako closest async analog | Odlišné | Zásadní architektonický rozdíl — Copilot je cloud-native, ceos je CLI-session-bound |

**Legenda shody:**
- Shodné = principiálně stejný přístup, různá implementace
- Částečně = sdílená část logiky, divergentní v jiné části
- Odlišné = fundamentálně jiný přístup

---

## Spec-Driven Development gate pattern: detailní analýza (Q21 primární deliverable)

### Spec fáze — jak Copilot zpracovává specifikaci

**Copilot Workspace (2024)** měl explicitní spec artefakt: "current state" vs "desired state" jako editovatelný textový artifact v UI. Uživatel mohl editovat spec před přechodem do plan fáze.

**Copilot Coding Agent (2025+)** spec fázi **nezveřejňuje jako explicitní artefakt**. Agent čte GitHub Issue description a comments jako implicitní specifikaci. Žádný standalone "spec.md" není generován — issue description je spec. Custom instructions (`.github/copilot-instructions.md`) jsou přidány k systémovému promptu agenta, ne ke spec artefaktu.

**GitHub spec-kit** (open source, vendor endorsement): definuje explicitní spec artefakt ve formátu markdown — `prd.md` (Product Requirements Document) → `technical-spec.md` → `implementation-plan.md` jako separátní soubory. Toto je **opt-in workflow** pro týmy, které chtějí formalizovanou spec fázi. Spec Kit je tool-agnostic (funguje s Claude Code, Copilot, Gemini CLI). — [github.blog: spec-driven-development-toolkit](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)

**Implikace:** ceos-agents spec-analyst agent emitující acceptance criteria jako structured artefakt (writeback do issue trackeru) je **sofistikovanější** než Copilot Coding Agent baseline. Zároveň méně formalizovaný než GitHub spec-kit plná SDD pipeline. ceos-agents leží mezi těmito dvěma přístupy.

### Plan fáze — gates a triggers

**Copilot Plan Gate (od dubna 2026):**
- User prompt obsahuje "create a plan" nebo similar → agent generuje plan
- Plan je prezentován jako text response (ne jako separátní file artefakt v baseline flow)
- Uživatel může iterovat přes feedback ("change approach X", "add step Y")
- Po schválení → implementace začíná
- Bez explicitní "create a plan" instrukce → agent jde rovnou do implementace
- Výsledkem je tedy **opt-in plan gate**, nikoli povinný krok

**ceos-agents Decomposition Gate:**
- Architect agent vygeneruje YAML task tree → uložen do `.claude/decomposition/{ISSUE-ID}.yaml`
- AC coverage check (každé AC musí mít maps_to v task tree)
- `Continue? [Y/n]` prompt — uživatel schvaluje nebo odmítá
- `--yolo` auto-approves, `--no-decompose` přeskočí celý krok

**Rozdíl v artefaktu:** Copilot plan = ephemeral text response. ceos-agents task tree = persistovaný YAML soubor s explicit dependency graph, maps_to traceability, estimated_lines per subtask. ceos-agents plan je **strukturovanější a persistentnější**.

### Implement fáze — iterace a retry logika

**Copilot:** implementuje průběžně, commituje do draft PR. Pokud test fails → agent pokusí o opravu (počet pokusů není dokumentován). Session log ukazuje co se děje. Uživatel může intervenovat komentářem v PR nebo Copilot Chat.

**ceos-agents:** fixer ↔ reviewer loop, max 5 iterací (konfigurovatelné). Smoke check po každém approve. Test-engineer opravuje failing tests (max 3 pokusy). Každý krok má structured state v state.json.

**Reliability:** Copilot nepublikuje retry limits ani structured failure modes. ceos-agents má explicitní retry limits a Block Comment Template. ceos-agents failure model je transparentnější.

### Review Gate — human vs automated

**Copilot review gate = human-only:** PR vyžaduje human reviewer (Copilot nemůže schválit vlastní PR). GitHub Copilot Code Review existuje jako separátní feature (AI-generated code review komentáře), ale neslouží jako blocker pro coding agent workflow.

**ceos-agents review = agent + human hybrid:**
1. Reviewer agent (opus) = automated AC fulfillment check → REQUEST_CHANGES nebo APPROVE
2. Acceptance-gate agent (sonnet) = second automated AC verification
3. PR Gate (Step 9) = human decision

Toto je **fundamentální rozdíl v review philosophy:** Copilot spoléhá na human peer review jako primární quality gate. ceos-agents implementuje automated quality gates před human PR review. Oba přístupy mají trade-offs: automated gates eliminují lidský bottleneck ale mohou mít false positives/negatives; human review je spolehlivější ale pomalejší.

---

## Závěrečné shrnutí dimenzí

| Dimenze | Copilot finding | Vztah k ceos-agents |
|---------|----------------|---------------------|
| Granularita agentů | 3 veřejně dokumentované komponenty (Research, Plan, Implementation); custom agents extensibility | ceos-agents 21 agentů = hlubší specializace, ale podobný pattern |
| Pipeline config | Hardcoded GitHub backend; žádný user-configurable pipeline DSL | Potvrzuje Run 1: žádný vendor neexponuje YAML-pipeline DSL uživatelům |
| Per-project customizace | Multi-level hierarchie (org → repo → path-specific → excludeAgent) | ceos Agent Overrides = flat per-agent; Copilot hierarchie je sofistikovanější |
| HITL pattern | Strategic gates: Plan Gate (opt-in) + PR Gate (povinný) + CI Gate (security) | ceos-agents sdílí stejný philosophical model; empirická validace |
| Stateful design | Session-stateful + git jako state externalization | Funkčně ekvivalentní ceos state.json + git commits |
| Timeline / lessons | Workspace (preview 2024) → sunset → Coding Agent GA (2025); product maturation, ne selhání | Relevantní pro ceos-agents: spec-plan-implement pipeline je durabilní paradigma |
| Přenositelné | Plan Gate pattern; issue-to-PR primitiv; strategic gates; spec-kit jako standard | Přímá aplikace na ceos implement-feature design |
| Framework-specific | GitHub Actions; closed-source routing; GitHub Cloud; enterprise firewall | ceos-agents může být vendor-agnostic tam, kde Copilot není |

---

## Citace

### Primární (vendor docs, github.blog)

- [GitHub Copilot: Meet the new coding agent](https://github.blog/news-insights/product-news/github-copilot-meet-the-new-coding-agent/) — announcement, 2025
- [About GitHub Copilot coding agent — docs.github.com](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-coding-agent) — canonical feature description
- [Research, plan, and code with Copilot cloud agent — GitHub Changelog 2026-04-01](https://github.blog/changelog/2026-04-01-research-plan-and-code-with-copilot-cloud-agent/) — Research/Plan/Code expansion
- [Research, plan, and iterate — docs.github.com](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/research-plan-iterate) — how-to documentation
- [Custom agents for GitHub Copilot — GitHub Changelog 2025-10-28](https://github.blog/changelog/2025-10-28-custom-agents-for-github-copilot/) — custom agents launch
- [Custom agents and sub-agent orchestration — docs.github.com](https://docs.github.com/en/copilot/how-tos/copilot-sdk/use-copilot-sdk/custom-agents) — sub-agent architecture
- [Custom agents configuration — docs.github.com](https://docs.github.com/en/copilot/reference/custom-agents-configuration) — YAML schema reference
- [Adding repository custom instructions — docs.github.com](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot) — copilot-instructions.md
- [AGENTS.md support — GitHub Changelog 2025-08-28](https://github.blog/changelog/2025-08-28-copilot-coding-agent-now-supports-agents-md-custom-instructions/)
- [Path-specific instructions — GitHub Changelog 2025-07-23](https://github.blog/changelog/2025-07-23-github-copilot-coding-agent-now-supports-instructions-md-custom-instructions/)
- [Org custom instructions — GitHub Changelog 2025-11-05](https://github.blog/changelog/2025-11-05-copilot-coding-agent-supports-organization-custom-instructions/)
- [excludeAgent property — GitHub Changelog 2025-11-12](https://github.blog/changelog/2025-11-12-copilot-code-review-and-coding-agent-now-support-agent-specific-instructions/)
- [Coding Agent public preview — GitHub Changelog 2025-05-19](https://github.blog/changelog/2025-05-19-github-copilot-coding-agent-in-public-preview/)
- [Coding Agent GA — community discussion](https://github.com/orgs/community/discussions/159068)
- [Plan Agent GA in JetBrains — GitHub Changelog 2026-03-11](https://github.blog/changelog/2026-03-11-major-agentic-capabilities-improvements-in-github-copilot-for-jetbrains-ides/)
- [Agent Skills — GitHub Changelog 2025-12-18](https://github.blog/changelog/2025-12-18-github-copilot-now-supports-agent-skills/)
- [Agents Panel — github.blog](https://github.blog/news-insights/product-news/agents-panel-launch-copilot-coding-agent-tasks-anywhere-on-github/)
- [Copilot Workspace — githubnext.com](https://githubnext.com/projects/copilot-workspace) — historical reference
- [MCP and Copilot cloud agent — docs.github.com](https://docs.github.com/en/copilot/concepts/agents/coding-agent/mcp-and-coding-agent)
- [Firewall for Copilot cloud agent — docs.github.com](https://docs.github.com/copilot/customizing-copilot/customizing-or-disabling-the-firewall-for-copilot-coding-agent)
- [Org firewall settings — GitHub Changelog 2026-04-03](https://github.blog/changelog/2026-04-03-organization-firewall-settings-for-copilot-cloud-agent/)
- [More visibility into sessions — GitHub Changelog 2026-03-19](https://github.blog/changelog/2026-03-19-more-visibility-into-copilot-coding-agent-sessions/)
- [GitHub spec-kit — github.com](https://github.com/github/spec-kit) — MIT license
- [Spec-driven development with AI — github.blog](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
- [Spec-driven development Copilot Academy](https://copilot-academy.github.io/workshops/immersive-experience/spec_driven_development)

### Sekundární (production + community)

- [4.7M GitHub Copilot subscribers — Windows Forum / Microsoft FY26 Q2](https://windowsforum.com/threads/microsoft-copilot-hits-15-million-paid-seats-and-4-7-million-github-subscribers.400630/) — Microsoft earnings call 2026-01-28
- [GitHub Copilot 20M all-time users — TechCrunch, 2025-07-30](https://techcrunch.com/2025/07/30/github-copilot-crosses-20-million-all-time-users/)
- [Copilot Workspace & Agentic Era — Java Code Geeks, 2026-02](https://www.javacodegeeks.com/2026/02/github-copilot-workspace-the-agentic-era.html)
- [56% SWE-bench Verified with Claude 3.7 Sonnet — Digital Applied, 2026-04](https://www.digitalapplied.com/blog/ai-coding-assistants-april-2026-cursor-copilot-claude)

### Oprava Run 1

**Run 1 final.md citace "10M+ paid Copilot seats":** Tato čísla se nepodařila verifikovat jako paid subscribers pro GitHub Copilot. Nejlepší dostupný verifikovatelný zdroj je **4.7 milionů paid subscribers** (Microsoft FY26 Q2 earnings, leden 2026). Číslo "10M+" pravděpodobně kombinuje GitHub Copilot s Microsoft 365 Copilot (Microsoft reportoval 15M paid seats pro Microsoft Copilot v lednu 2026 — ale to je jiný produkt). Tato korekce je aditivní k Run 1 evidenci, ne ji vyvracení.

---

*Report připraven: 2026-04-26. Všechna vendor-narrative tvrzení označena. Closed-source limitation explicitně disclosed ve všech dimenzích.*
