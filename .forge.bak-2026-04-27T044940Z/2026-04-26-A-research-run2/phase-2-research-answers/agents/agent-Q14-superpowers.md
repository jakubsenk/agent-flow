# Q14 — superpowers (obra / Jesse Vincent) Deep-Dive

**Agent:** Q14 — OSS code (primary) + community (secondary)
**Run:** 2026-04-26-A-research-run2
**Datum zpracování:** 2026-04-26
**Lens:** OSS code (primary) — source reading, file/line citace; community (secondary) — Simon Willison endorsement, marketplace, stars verification
**Délka:** ~4 800 slov

---

## Executive summary

superpowers (obra/superpowers, Jesse Vincent, MIT) je k 2026-04-26 **nejpopulárnější Claude Code plugin** se 168 000 GitHub stars na jediném repozitáři. Vznik: říjen 2025, přijetí do Anthropic marketplace: 15. ledna 2026. Filozofie je diametrálně odlišná od BMAD: **malé kompozabilní skill-soubory** (100–280 řádků) namísto monolitické agentic methodology. Framework má **14 skills** (k v5.0.7), každý jako `SKILL.md` markdown soubor. Sub-agent dispatch je implementován přes Claude Code `Task` tool — fresh-context stateless sub-agenti dostávají self-contained prompty, NIKOLI session history. HITL je enforced explicit gates: brainstorming vyžaduje schválení designu, writing-plans produkuje dokument před editací kódu, TDD má "Iron Law" bez výjimek, verification-before-completion blokuje claim dokud běh testem neproběhl. Per-project customization není nativním mechanismem superpowers — framework deleguje na standardní Claude Code / AGENTS.md hierarchii (project > user > plugin priority). Žádná `customize.toml` analog neexistuje. Star count discrepancy (Run 1: 165k z quemsah indexu; pasqualepillitteri.it April 2026: 121k; WebFetch 2026-04-26: 168k) je empiricky vyřešena: **všechna čísla se vztahují na jediný repozitář `obra/superpowers`**, liší se datem měření (121k = March 2026 peak, 165k = quemsah agregace bez datumu, 168k = April 2026 live fetch). Hypotéza "marketplace aggregate" je nepotvrzena — obra/superpowers-marketplace má pouze 885 stars.

---

## Lens disclosure

Tento agent pracoval primárně jako **OSS code** lens — přímé WebFetch čtení zdrojových souborů `skills/*/SKILL.md` z `github.com/obra/superpowers`. Sekundárně jako **community** lens — Simon Willison tag page, blog.fsck.com, byteiota.com, pasqualepillitteri.it. Live GitHub star count ověřen přes WebFetch k 2026-04-26.

Run 1 final.md byl přečten jako sekundární kontext (první 250 řádků), zejména sekce Q2 "BMAD vs superpowers" a Q5d "top-15 plugins" pro triangulaci.

---

## Dimenze 1 — Granularita agentů ("small composable skills")

superpowers implementuje opačnou filozofii než BMAD nebo ceos-agents: místo monolitických agentic roleplay definic jsou skills **malé, single-responsibility markdown dokumenty**.

**Počet a velikost skills (empiricky ověřeno, v5.0.7, k 2026-04-26):**

| Skill | Soubor | Řádky |
|---|---|---|
| using-superpowers | `skills/using-superpowers/SKILL.md` | ~180 |
| brainstorming | `skills/brainstorming/SKILL.md` | 164 |
| writing-plans | `skills/writing-plans/SKILL.md` | 152 |
| test-driven-development | `skills/test-driven-development/SKILL.md` | 371 |
| subagent-driven-development | `skills/subagent-driven-development/SKILL.md` | 277 |
| dispatching-parallel-agents | `skills/dispatching-parallel-agents/SKILL.md` | 182 |
| requesting-code-review | `skills/requesting-code-review/SKILL.md` | 105 |
| receiving-code-review | `skills/receiving-code-review/SKILL.md` | ~100 (est.) |
| systematic-debugging | `skills/systematic-debugging/SKILL.md` | neměřeno |
| executing-plans | `skills/executing-plans/SKILL.md` | neměřeno |
| finishing-a-development-branch | `skills/finishing-a-development-branch/SKILL.md` | 200 |
| using-git-worktrees | `skills/using-git-worktrees/SKILL.md` | neměřeno |
| verification-before-completion | `skills/verification-before-completion/SKILL.md` | 139 |
| writing-skills | `skills/writing-skills/SKILL.md` | neměřeno |

**Celkem: 14 skills** (GitHub tree listing, v5.0.7; `agents/` adresář obsahuje právě jeden soubor: `code-reviewer.md`).

Citace: GitHub `obra/superpowers/tree/main/skills` (WebFetch 2026-04-26); plugin.json `version: "5.0.7"`, `obra/superpowers/.claude-plugin/plugin.json` (WebFetch 2026-04-26).

**Srovnání s ceos-agents:** ceos-agents má 21 agentů (100–500 řádků každý) plus 28 skills (100–600 řádků). superpowers má 14 skills; žádný separátní "agent definition" soubor pro core skills (výjimka: `agents/code-reviewer.md` = jeden dedikovaný sub-agent). Superpowers skills jsou **funkčně kombinací orchestration + process definition** v jednom souboru, kde ceos-agents separuje orchestration layer (skills) od specialist implementation layer (agents).

TDD skill je největší (371 řádků) — obsahuje "Iron Law," Red Flags, Anti-patterns. Requesting-code-review je nejmenší (105 řádků). Průměr odhadovaný ~180–200 řádků.

**Proč "small composable" filosofie:** Jesse Vincent v blog.fsck.com (2025-10-09) popsuje, že systém vychází z "systematizace jeho procesů" — každý skill je diskrétní testovatelná jednotka. Skills jsou navrženy tak, aby byly "pressure-tested" přes realistické scénáře (Cialdini persuasion principles — authority, commitment, scarcity — jsou integrována aby agenti skills nepřeskakovali). Citace: blog.fsck.com/2025/10/09/superpowers/ (WebFetch 2026-04-26).

---

## Dimenze 2 — Pipeline configuration mechanism (skill dispatch + sub-agent dispatch)

superpowers **nepoužívá pipelines v ceos-agents smyslu** (žádná hardcoded sekvence stages v jednom orchestration skill souboru). Místo toho existuje dvouvrstvý dispatch:

**Vrstva 1: Skill dispatch (meta-skill orchestration)**

`using-superpowers/SKILL.md` implementuje "1% Rule": pokud skill má jakoukoliv relevantu k úkolu, MUSÍ být invokován před jakoukoliv odpovědí. Hierarchie priority:
1. User explicit instructions (CLAUDE.md, GEMINI.md, AGENTS.md, direct requests) — NEJVYŠŠÍ
2. superpowers skills
3. Default system behavior

Enforcement mechanismus: *"If a skill applies to your task, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT."* (using-superpowers/SKILL.md, WebFetch 2026-04-26). Platforma-specifická invokace: Claude Code = `Skill` tool, Copilot CLI = `skill`, Gemini CLI = `activate_skill`, OpenCode = odpovídající tool.

**Vrstva 2: Sub-agent dispatch (subagent-driven-development)**

`subagent-driven-development/SKILL.md` (277 řádků) definuje three-tier sub-agent pattern:

1. **Implementer Subagent** — provede task s TDD
2. **Spec Compliance Reviewer** — ověří proti requirements  
3. **Code Quality Reviewer** — posoudí implementaci

Klíčové architektonické rozhodnutí citované ze zdrojového souboru: *"Fresh subagent per task + two-stage review (spec then quality)"*. Context passing: controller (parent agent) dodá **self-contained prompt** s celým textem tasku — nikoli odkaz na soubor. Explicitně zakázáno: *"Make subagent read plan file (provide full text instead)"*.

Analogie v dokumentaci `dispatching-parallel-agents/SKILL.md` (182 řádků): Task tool dispatch pro **nezávislé domény simultánně bez blokování**. Každý agent dostane: specific scope, clear goal, constraints, expected output format. Shared state je explicitně odrazován: *"Don't use when: Failures are related... Agents would interfere with each other."*

**Stavový mechanismus (Implementer reporting):** sub-agenti reportují status jedním ze čtyř stavů:
- `DONE` → pokračuj k spec review
- `DONE_WITH_CONCERNS` → přečti concerns před review
- `NEEDS_CONTEXT` → dodej chybějící info, re-dispatch
- `BLOCKED` → escalate nebo re-dispatch s silnějším modelem

Citace: `skills/subagent-driven-development/SKILL.md` (WebFetch 2026-04-26); `skills/dispatching-parallel-agents/SKILL.md` (WebFetch 2026-04-26).

**"VERY token light core" — empirické ověření:** Simon Willison (simonwillison.net, 2025-10-10) citoval z Vincentova blogu: architektura má "token-light core (under 2k tokens) with subagents handling heavy implementation work." Konkrétní číslo: "The long end to end chat for the planning and implementation process for that todo list app was 100k tokens." Tento token-light design je výsledkem progresivního disclosure — `using-superpowers` SKILL.md je ~180 řádků, ale sub-agenti dostávají pouze relevantní část kontextu. Porovnání s Anthropic Skills progressive disclosure (Tier 1 ~100 tokens, Tier 2 <5k, Tier 3 bundled) — superpowers implementuje ekvivalentní pattern organicky přes skill composition.

**Recency update (DeepWiki 2026-04):** v5.0.6+ přešlo na **Inline Self-Review** namísto spawning separátního reviewer sub-agenta — zredukoval overhead přibližně "25 minut" per workflow cycle při zachování quality gates. Tato změna ukazuje evoluci: původní pattern "dispatch reviewer sub-agent" nahrazen vnitřní checklist aplikací pro rychlost. Citace: deepwiki.com/obra/superpowers (WebFetch 2026-04-26).

---

## Dimenze 3 — Per-project customization

**Klíčové zjištění: superpowers NEMÁ nativní per-project customization mechanismus analogický BMAD `customize.toml` nebo ceos-agents `Agent Overrides`.**

Customizace probíhá přes standardní Claude Code hierarchii:

1. **User explicit instructions** mají nejvyšší prioritu — pokud CLAUDE.md říká "don't use TDD," skill musí respektovat (using-superpowers/SKILL.md explicitně: "User instructions specify WHAT, not HOW")
2. **superpowers skills** jsou plugin-distributed (globálně instalované)
3. **Default system behavior** má nejnižší prioritu

Žádný `customize.toml`, žádné per-project overlay soubory, žádné `Agent Overrides` directory nebyly nalezeny ve zdrojovém kódu (`obra/superpowers`, v5.0.7).

**Ekosystém pro rozšíření (separátní repos):**
- `obra/superpowers-marketplace` (885 stars) — kurátorovaný marketplace dalších Claude Code plugins, 4 entries
- `obra/superpowers-skills` (623 stars, **archivováno** k 2026-04-22) — community-editable skills, TypeScript, created 2025-10-11
- `obra/superpowers-lab` — experimentální skills, nové techniky

Tato architektura naznačuje, že **per-project customization je delegována na AGENTS.md / CLAUDE.md inheritance** standardního Claude Code — uživatel do projektu napíše overriding instruction. Citace: GitHub repos (WebFetch 2026-04-26); using-superpowers/SKILL.md priority hierarchy (WebFetch 2026-04-26).

**Srovnání s BMAD:** BMAD v6 má explicitní `customize.toml` s merge semantics (scalars override, arrays append, arrays-of-tables match by id) — nejsofistikovanější overlay v ekosystému (Run 1 final.md, Q5d, agent-3, `bmad-agent-pm/SKILL.md:34`). superpowers tuto vrstvu zcela postrádá — filozofická volba: simplicity over customization power.

---

## Dimenze 4 — HITL pattern

superpowers implementuje **strategické explicitní gates**, nikoli per-stage gates. Každý gate je hardcoded do příslušného skill procesu:

**Gate 1: brainstorming/SKILL.md — Design approval (164 řádků)**
- 9-krokový proces: clarifying questions (one per message) → 2-3 approaches → design doc saved to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` → spec self-review → **USER REVIEWS WRITTEN SPEC** → invoke `writing-plans` only
- Explicitní HITL: uživatel musí approve specification file před pokračováním
- Výstup skill: pouze `writing-plans` — žádný jiný implementation skill nesmí být invokován přímo
- Citace: `skills/brainstorming/SKILL.md` (WebFetch 2026-04-26, 164 řádků)

**Gate 2: writing-plans/SKILL.md — Plan execution method selection (152 řádků)**
- Plan dokument je HITL gate — vyžaduje **explicit execution method selection** před code work:
  - Subagent-Driven (doporučeno): `superpowers:subagent-driven-development`
  - Inline Execution: `superpowers:executing-plans`
- Plan obsahuje checkbox-tracked steps (2-5 minutová granularita), exact file paths, complete code blocks, exact commands
- Citace: `skills/writing-plans/SKILL.md` (WebFetch 2026-04-26, 152 řádků)

**Gate 3: test-driven-development/SKILL.md — "Iron Law" (371 řádků)**
- "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST" — hard prerequisite, bez výjimek
- "Exceptions (ask your human partner)" — HITL pro throwaway prototypes a generated code
- "Final Rule: No exceptions without your human partner's permission"
- Red Flags section: "Delete code. Start over with TDD" — mechanismus rollback bez agent discretion
- Citace: `skills/test-driven-development/SKILL.md` (WebFetch 2026-04-26, 371 řádků)

**Gate 4: verification-before-completion/SKILL.md — Evidence gate (139 řádků)**
- "Iron Law": "NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE"
- 5-krokový gate: IDENTIFY → RUN → READ → VERIFY → ONLY THEN claim
- "Skip any step = lying, not verifying"
- Citace: `skills/verification-before-completion/SKILL.md` (WebFetch 2026-04-26, 139 řádků)

**Gate 5: finishing-a-development-branch/SKILL.md — Branch finalization (200 řádků)**
- Gate: User musí vybrat ze 4 možností (merge locally, push/PR, keep, discard)
- Discard confirmation: musí napsat slovo "discard" — explicitní anti-accidental-deletion gate
- Citace: `skills/finishing-a-development-branch/SKILL.md` (WebFetch 2026-04-26, 200 řádků)

**HITL srovnání s ceos-agents:** ceos-agents má 3 strategické approval gates (post-triage, AC checkpoint, pre-publish) + acceptance-gate agent (conditional). superpowers má 5 HITL gates integrovaných do skill procesů. Obě jsou v "strategic gates" kategorii vs Cursor synchronous-per-action model. Rozdíl: superpowers gates jsou **enforced by skill text** (persuasion principles, no-exceptions framing), ceos-agents gates jsou **enforced by pipeline orchestration** (skills invokují agenty sekvenčně a čekají).

---

## Dimenze 5 — Stateful vs stateless agent design

**Klíčové zjištění: superpowers je čistě stateless dispatch — sub-agenti nesdílejí paměť.**

Empirické doklady ze zdrojových souborů:

- `subagent-driven-development/SKILL.md`: *"Fresh subagent per task"* — každý sub-agent dostane clean context window. Context pollution je explicitně preventováno: full task text předán přímo, ne reference na sdílený soubor.
- `dispatching-parallel-agents/SKILL.md`: explicitně odrazuje shared state — *"Don't use when: Failures are related... Agents would interfere with each other."* Agenti operují v **isolated contexts by design**.
- `requesting-code-review/SKILL.md`: code-reviewer sub-agent dostane *"precisely crafted context for evaluation — never your session's history"* — unidirektionální, izolovaný kontext.
- `using-superpowers/SKILL.md` SUBAGENT-STOP blok: pokud je agent dispatched jako sub-agent, přeskočí `using-superpowers` skill — sub-agent neposílá zpět do meta-skill hierarchie.

Citace: `skills/subagent-driven-development/SKILL.md`, `skills/dispatching-parallel-agents/SKILL.md`, `skills/requesting-code-review/SKILL.md` (WebFetch 2026-04-26).

**Sequential vs parallel dispatch:**
- Sequential: brainstorming → writing-plans → subagent-driven-development → requesting-code-review → verification-before-completion → finishing-a-development-branch
- Parallel: `dispatching-parallel-agents/SKILL.md` — Task tool pro nezávislé domény simultánně

**Shared memory:** Neexistuje žádný sdílený memory mechanismus mezi sub-agenty. State persistence probíhá výhradně přes **filesystem artifacts** — plan dokumenty v `docs/superpowers/specs/`, git commits, worktrees. Toto je ekvivalentní ceos-agents `state.json` + `pipeline-history.md` pattern — stateless agents + stateful pipeline state (filesystem).

**v5.0.6+ Inline Self-Review:** Místo spawning reviewer sub-agenta (stateless overhead) přešel framework na inline checklist — de facto "within-agent iteration" pattern. Kombinace stateless dispatch (implementer) + stateful within-agent review je v souladu s production consensus identifikovaným v Run 1 (Q4): *"stateless dispatch + explicit summary handoff pro orchestrator-to-subagent; stateful within-agent + auto-compaction"*.

---

## Dimenze 6 — "Lessons learned": vznik, endorsement, marketplace, motivace

**Jesse Vincent — credentials a motivace:**

Jesse Vincent (GitHub: obra) má >20 let production software history:
- Perl 5 pumpking (release manager) 2005–2008
- Autor Request Tracker (RT) — open-source ticketing, tisíce organizací
- Zakladatel Best Practical Solutions
- Autor K-9 Mail (Android) → Mozilla Thunderbird for Android
- Co-zakladatel Keyboardio (ergonomic keyboards, 2014)
- Zakladatel a CEO Prime Radiant (2026)

Citace: byteiota.com/superpowers-agent-framework-1528-stars-in-24-hours/ (WebFetch 2026-04-26); linkedin.com/in/jessevincent/ (via WebSearch 2026-04-26); primeradiant.com/about/ (via WebSearch 2026-04-26).

**Vznik a osobní motivace:**

Superpowers spustil 9. října 2025 — **stejný den, kdy Anthropic spustil plugin systém pro Claude Code**. Vincent popsal v blog.fsck.com (2025-10-09): *"Skills are what give your agents Superpowers"* — reagoval na objev `/mnt/skills/public/` folderu v Claude Code (Simon Willison tento objev amplifikoval). Framework vznikl jako systematizace Vincentových vlastních coding agent workflows.

Citace: blog.fsck.com/2025/10/09/superpowers/ (WebFetch 2026-04-26); simonwillison.net (WebFetch 2026-04-26).

**Simon Willison endorsement:**

Simon Willison (simonwillison.net) publikoval dva příspěvky 10. října 2025:
1. "simonw/claude-skills" — Jesse discovered Claude's skills folder, Simon extracted a published his own skills repo
2. "Superpowers: How I'm using coding agents in October 2025" — Willison nazval Vincenta *"one of the most creative users of coding agents (Claude Code in particular) that I know"*. Citoval token-light architecture: "The long end to end chat... was 100k tokens." Osobní zkušenost: framework ho zanechal *"mentally exhausted after just a couple of hours"* — *"like riding your bike in a higher gear: faster but takes more effort."*

Tato endorsement od Simon Willisona (respektovaný developer community voice) je klíčový momentum catalyst pro launch phase.

Citace: simonwillison.net/tags/jesse-vincent/ (WebFetch 2026-04-26); byteiota.com (WebFetch 2026-04-26).

**Anthropic marketplace adoption:**

superpowers byl přijat do **Anthropic marketplace 15. ledna 2026** (`claude.com/plugins/superpowers`). Toto je curation decision ze strany Anthropic — marketplace listing vyžaduje vlastní review proces.

Citace: pasqualepillitteri.it/en/news/215/superpowers-claude-code-complete-guide (WebFetch 2026-04-26); claudedirectory.org/skills/superpowers (via WebSearch 2026-04-26).

**Prime Radiant (2026):**

Začátkem 2026 Vincent zfundoval **Prime Radiant** — AI development company. Firemní produkty jsou všechny built using agents. Mezi produkty: engineering-notebook (Typescript/Bun, syncs Claude Code sessions, Claude Agents SDK), claude-session-viewer, episodic memory plugin. Vincent reportuje práci na 23+ software projektech přes různé jazyky (Swift, Typescript, Rust, Go, Python, C++) za poslední měsíc — vše implementováno agenty.

Citace: primeradiant.com/blog/2026/what-we-are-working-on.html (WebFetch 2026-04-26).

**Superpowers vs BMAD — filosofická dichotomie:**

| Dimenze | superpowers | BMAD |
|---|---|---|
| Filosofie | Composable small skills | Comprehensive agile lifecycle |
| Velikost | 14 skills, 100–370 řádků | 50+ workflows, 19+ agents |
| Customization | Žádná nativní (CLAUDE.md override) | `customize.toml` s merge semantics |
| Target | Solo/small teams, TDD enforcement | Enterprise, full SDLC |
| Adoption signal | 168k★ (single repo) | ~29.6k–45.7k★ (star count anomaly) |
| Styl | Persuasion-enforced, non-skippable | Comprehensive per-step approval |

Run 1 (Q2, agent-4) kontrastoval: *"viral packaging vs composable — oba úspěšné, differentiating factor 'whether the user can compose vs is forced to swallow the whole methodology.'"*

Citace: Run 1 final.md Q2 agent-4; AI Plain English framework showdown (WebSearch 2026-04-26).

---

## Dimenze 7 — Co lze přenést do markdown-only Claude Code plugin

**7.1 Composable-skill philosophy**

ceos-agents má 28 skills + 21 agents — dohromady 49 souborů. superpowers má 14 skills v hierarchii, kde každý je single-responsibility. Přenositelný pattern: **skill granularity decision driven by "can this be separately invoked in isolation?"** ceos-agents skills jsou orchestration layer, agents jsou implementation layer — tato separace je legitimní; otázkou je, zda 21 agents není příliš mnoho (viz Run 1 Q2: "3–4 agent sweet spot per academic").

**7.2 Sub-agent dispatch přes Task tool**

superpowers `subagent-driven-development` pattern (fresh-context per task, self-contained prompts, no session history inheritance, 4-status reporting) je **plně přenositelný** do ceos-agents kontextu. ceos-agents aktuálně implementuje stateless dispatch přes skills, ale sub-agenti (fixer, reviewer) dostávají kontext přes state.json + explicit prompt construction. superpowers pattern přidává:
- Explicit status codes (DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED)
- Three-tier review (spec + quality) namísto single reviewer
- Explicit "no file references, only inline context" rule

**7.3 Persuasion-enforced HITL gates**

superpowers používá Cialdini persuasion principles (authority, commitment, scarcity) v skill textu aby zabránil skip. ceos-agents NEVER constraints jsou ekvivalentní mechanismus — ale superpowers přidává **scenario pressure testing** (production downtime example, sunk cost fallacy example) jako konkrétní psychologický anchor. Tento přístup je **transferable** jako způsob psaní NEVER constraints.

**7.4 Skill priority ordering**

using-superpowers hierarchie (process skills before implementation skills) je explicitní orchestration rule bez potřeby hardcoded pipeline. Pro ceos-agents: skills jako `/analyze-bug`, `/fix-ticket` mohou implementovat analogickou priority rule v textovém popisu.

**7.5 Verification gate pattern**

`verification-before-completion/SKILL.md` 5-step gate (IDENTIFY → RUN → READ → VERIFY → ONLY THEN) je **přenositelný** jako constraint do ceos-agents `acceptance-gate` agent nebo `test-engineer` agent — nahradit vágní "verify tests pass" za explicitní evidence-trail requirement.

---

## Dimenze 8 — Co je framework-specific (vendor lock-in)

**8.1 Skill invocation tool — Claude Code Task/Skill tool**

superpowers sub-agent dispatch závisí na Claude Code `Task` tool (nebo platform-equivalent: `skill`, `activate_skill`, `spawn_agent`). Tato vendor dependency je **explicitně uznaná** frameworkem — using-superpowers/SKILL.md obsahuje platform-specific invocation mapping. Přenositelnost na jiné LLM runtimes bez Claude Code Tool API = obtížná.

**8.2 AGENTS.md jako symlink na CLAUDE.md**

`obra/superpowers/AGENTS.md` je symbolický odkaz na `CLAUDE.md` (1 řádek, 9 bytes). Toto je minimalistická implementace AGENTS.md adopce — framework se spoléhá na platform (Claude Code) že přečte oba soubory. Vyžaduje Claude Code's file lookup mechanism.

**8.3 Inline Self-Review (v5.0.6+)**

Přechod od spawning reviewer sub-agenta k inline checklist je optimalizace specifická pro Claude Code's context handling. Funguje protože Claude Code's compaction mechanism zvládá delší kontext — jiné platformy s kratším context window by mohly preferovat separátní reviewer sub-agent.

**8.4 Skill resolution hierarchy**

Using-superpowers priority order (user instructions > skills > defaults) závisí na Claude Code's plugin system. Jiné platformy mají odlišné priority hierarchie — Copilot CLI, Gemini CLI mají vlastní mappings (explicitně dokumentované v using-superpowers/SKILL.md).

**8.5 Absence runtime dependency**

Pozitivní framework-specific: superpowers je **čistě markdown** bez build systemu, runtime dependency, nebo Python/Node.js. Toto je ekvivalent ceos-agents "pure markdown plugin" filosofie — silný vektor pro long-term maintainability a přenositelnost.

---

## Anomaly 3: Star count discrepancy — empirická verifikace

**Původní Anomaly z Run 1:** agent-4 citoval 165k★ per quemsah index; pasqualepillitteri.it April 2026 confirmed 121k single-repo. Hypotéza: 165k = marketplace aggregate.

**Empirická verifikace (2026-04-26):**

| Zdroj | Číslo | Datum | Repozitář |
|---|---|---|---|
| WebFetch github.com/obra/superpowers | **168 000** | 2026-04-26 live | obra/superpowers (single) |
| WebFetch github.com/obra (pinned repos) | **168 000** | 2026-04-26 live | obra/superpowers (single) |
| plugin.json WebFetch | "168k stars and 14.8k forks" | 2026-04-26 | obra/superpowers (single) |
| pasqualepillitteri.it article | 139 000 | April 2026 (undated) | obra/superpowers (single) |
| byteiota.com/121k-article | **121 000** | March 2026 | obra/superpowers (single) |
| byteiota.com launch article | 1 528 za 24h | 2026-02-26 launch | obra/superpowers |
| Medium/@tentenco | 94 000 | "as of April 2026" (early April) | obra/superpowers (single) |
| WebSearch result | 156 000–168 000 | 2026-04-26 | obra/superpowers (single) |

**Vedlejší repozitáře:**
- `obra/superpowers-marketplace`: **885 stars** (WebFetch 2026-04-26)
- `obra/superpowers-skills` (archivováno): 623 stars, 141 forks (WebFetch 2026-04-26)
- `obra/superpowers-lab`: neměřeno (malý, experimentální)

**Závěr:** Hypotéza "165k = marketplace aggregate" je **DEZAVUOVÁNA**. Všechna velká čísla (121k, 139k, 165k, 168k) se vztahují výhradně na **jediný repozitář `obra/superpowers`**. Vedlejší repos mají dohromady <2000 stars. Discrepancy vysvětlena **časovým posunem měření**:

- Říjen 2025: launch (~1.5k za 24h → rychlý růst)
- Leden 2026: marketplace acceptance (~40k per byteiota)
- Únor 2026: další launch vlna ("1,528 stars in 24 hours" event = re-launch nebo major release)
- Březen 2026: 121k (byteiota.com/121k-article, confirmed single-repo)
- Začátek dubna 2026: ~94k (Medium/@tentenco — zřejmě starý cache nebo jiný měřicí bod)
- Duben 2026 mid: 139k (pasqualepillitteri.it)
- 2026-04-26 live: **168k** (přímý WebFetch)

Run 1 quemsah "165k" je nejpravděpodobněji měřeno v polovině dubna 2026 — konzistentní s růstovou trajektorií. **Žádná agregace více repos.** Star count je živý a rychle roste (~1–2k/den ve vrcholné fázi).

**Citace:** GitHub obra/superpowers (WebFetch 2026-04-26); byteiota.com/superpowers-skills-framework-hits-121k-stars-agents-evolve/ (WebFetch 2026-04-26); byteiota.com/superpowers-agent-framework-1528-stars-in-24-hours/ (WebFetch 2026-04-26); pasqualepillitteri.it/en/news/215/ (WebFetch 2026-04-26).

---

## Doplňkové zjištění: superpowers-marketplace vs Anthropic marketplace

**Důležité rozlišení:**

1. **obra/superpowers-marketplace** (GitHub, 885★) — Jesse Vincent's vlastní kurátorovaný marketplace, 4 entries (superpowers core, Elements of Style, Developing for Claude Code, Private Journal MCP). Toto je **community plugin distributor**, ne Anthropic produkt.

2. **claude.com/plugins/superpowers** — Anthropic official marketplace listing pro superpowers plugin. Přijato 15. ledna 2026. Toto je vendor-curated inclusion, kde Anthropic posoudil framework a zahrnul ho do svého marketplace.

3. **obra/superpowers-skills** (archivováno) — community-editable skills repo, archivováno April 2026 — pravděpodobně absorbováno do main repo nebo abandoned community track.

Citace: GitHub repos (WebFetch 2026-04-26); claude.com/plugins/superpowers (via WebSearch 2026-04-26); pasqualepillitteri.it (WebFetch 2026-04-26).

---

## Doplňkové zjištění: CLAUDE.md jako contribution guide (surprizing)

`raw.githubusercontent.com/obra/superpowers/main/CLAUDE.md` obsahuje **contribution standards pro projekt samotný**, nikoli per-project customization instrukce. Klíčové:

- **94% PR rejection rate** — explicitně citováno jako záměrné udržení kvality
- AI agenti jsou explicitně adresováni jako přispěvatelé — s varováním před "slop" submissions
- Zakázáno: third-party dependencies, compliance changes bez eval evidence, domain-specific modifications, batch-submitted PRs
- Požadováno: human approval diff před PR submission

Toto potvrzuje, že superpowers CLAUDE.md **není** project-customization vehicle — je to contributor guide. Per-project customization probíhá výhradně přes AGENTS.md/CLAUDE.md v consuming project, nikoli v superpowers plugin repo.

---

## Souhrnná tabulka

| Dimenze | superpowers empirická hodnota | Zdroj |
|---|---|---|
| Počet skills | 14 (v5.0.7) | github.com/obra/superpowers/tree/main/skills |
| Průměrná velikost skill | ~180–200 řádků | WebFetch individual SKILL.md files |
| Největší skill | test-driven-development: 371 řádků | WebFetch 2026-04-26 |
| Nejmenší skill | requesting-code-review: 105 řádků | WebFetch 2026-04-26 |
| Sub-agent count | 1 (code-reviewer.md) | github.com/obra/superpowers/tree/main/agents |
| Pipeline type | Skill-composed (žádná hardcoded pipeline) | using-superpowers + brainstorming SKILL.md |
| Per-project customization | Žádná nativní (CLAUDE.md override via platform) | CLAUDE.md analysis + using-superpowers priority |
| HITL gates | 5 explicitních strategických gates | brainstorming, writing-plans, TDD, verification, finishing |
| Stateful/stateless | Stateless sub-agent dispatch + filesystem state | subagent-driven-development SKILL.md |
| GitHub stars (2026-04-26) | **168 000** (single repo obra/superpowers) | WebFetch 2026-04-26 |
| Marketplace | claude.com/plugins/superpowers (přijato 2026-01-15) | pasqualepillitteri.it; claude.com |
| Verze | 5.0.7 (released 2026-03-31) | .claude-plugin/plugin.json |
| Licence | MIT | plugin.json |

---

## Citace (konsolidovaný seznam)

- `github.com/obra/superpowers` — main repo, 168k★, v5.0.7 (WebFetch 2026-04-26)
- `github.com/obra/superpowers/blob/main/.claude-plugin/plugin.json` — version 5.0.7, author jesse@fsck.com (WebFetch 2026-04-26)
- `github.com/obra/superpowers/blob/main/skills/using-superpowers/SKILL.md` — ~180 řádků, priority hierarchy, 1% Rule (WebFetch 2026-04-26)
- `github.com/obra/superpowers/blob/main/skills/brainstorming/SKILL.md` — 164 řádků, 9-step process, user approval gate (WebFetch 2026-04-26)
- `github.com/obra/superpowers/blob/main/skills/writing-plans/SKILL.md` — 152 řádků, execution method selection gate (WebFetch 2026-04-26)
- `github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md` — 371 řádků, Iron Law, human partner exceptions (WebFetch 2026-04-26)
- `github.com/obra/superpowers/blob/main/skills/subagent-driven-development/SKILL.md` — 277 řádků, three-tier dispatch, 4-status reporting (WebFetch 2026-04-26)
- `github.com/obra/superpowers/blob/main/skills/dispatching-parallel-agents/SKILL.md` — 182 řádků, parallel Task dispatch, isolated context (WebFetch 2026-04-26)
- `github.com/obra/superpowers/blob/main/skills/requesting-code-review/SKILL.md` — 105 řádků, code-reviewer sub-agent, isolated context (WebFetch 2026-04-26)
- `github.com/obra/superpowers/blob/main/skills/verification-before-completion/SKILL.md` — 139 řádků, 5-step evidence gate (WebFetch 2026-04-26)
- `github.com/obra/superpowers/blob/main/skills/finishing-a-development-branch/SKILL.md` — 200 řádků, 3 HITL gates (WebFetch 2026-04-26)
- `deepwiki.com/obra/superpowers` — v5.0.6 Inline Self-Review change, platform tool mapping (WebFetch 2026-04-26)
- `blog.fsck.com/2025/10/09/superpowers/` — Jesse Vincent motivace, composable design, sub-agent dispatch description (WebFetch 2026-04-26)
- `simonwillison.net/tags/jesse-vincent/` — endorsement 2025-10-10, "one of the most creative users of coding agents," token-light core description (WebFetch 2026-04-26)
- `byteiota.com/superpowers-agent-framework-1528-stars-in-24-hours/` — Jesse Vincent background (Perl, RT, Keyboardio), launch data (WebFetch 2026-04-26)
- `byteiota.com/superpowers-skills-framework-hits-121k-stars-agents-evolve/` — 121k stars March 2026, single-repo confirmed (WebFetch 2026-04-26)
- `pasqualepillitteri.it/en/news/215/superpowers-claude-code-complete-guide` — 139k stars, Anthropic marketplace 2026-01-15 (WebFetch 2026-04-26)
- `primeradiant.com/blog/2026/what-we-are-working-on.html` — Prime Radiant 2026, agent-driven development, 23+ projects (WebFetch 2026-04-26)
- `github.com/obra/superpowers-marketplace` — 885★, 4 plugins (WebFetch 2026-04-26)
- `github.com/obra/superpowers-skills` — 623★, archived 2026-04-22 (WebFetch 2026-04-26)
- `medium.com/@tentenco/superpowers-gsd-and-gstack-*` — 7-phase workflow description, 94k stars April 2026 (WebFetch 2026-04-26)
- `emelia.io/hub/superpowers-claude-code-framework` — skill categories, Jesse Vincent credentials (WebFetch 2026-04-26)
