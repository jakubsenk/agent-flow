# Q13 — opencode (sst/opencode): Hluboká analýza frameworku

**Agent:** Research Agent — OSS code lens (primary) + community lens (secondary)
**Datum:** 2026-04-26
**Run:** 2026-04-26-A-research-run2
**Scope:** Q13 deep-dive — opencode (sst/opencode) pro cross-run synthesis Q22

---

## Executive Summary

1. **Anomaly 1 z Run 1 je empiricky potvrzena a aktualizována.** opencode k 2026-04-26 dosáhl ~150k GitHub stars (DeepWiki navigation: "150k stars noted"), 6,5M monthly active developers, 14,53M npm downloads za jediný měsíc (March 2026), 10M celkových downloads do 2026-01-29. STATS.md potvrzuje 7,8M GitHub + 2,4M npm downloads k 2026-01-29. Velocity 1 282 commits/30d z Run 1 je konzistentní s v1.14.25 vydaným 2026-04-25 (denní release cadence přetrvává). Toto je reálný paradigm-shift signal — ne overstated.

2. **Architektonicky opencode není jen "TUI agent": je to plnohodnotný client-server systém** (HTTP backend + TUI/desktop/web/IDE klienti) psaný v TypeScript/Bun s Zig-renderovaným TUI, s deklarativní konfigurací (`opencode.json` + `AGENTS.md`), pluginovým SDK, ACP protokolem pro IDE integrace a 75+ provider abstrakcí přes Vercel AI SDK. Není to markdown plugin — je to distribuovaný software runtime.

3. **"Claude Max routing trick" byl centrálním katalyzátorem virálního růstu.** 18k stars za 2 týdny v lednu 2026 bylo vyvoláno discovery Claude Max OAuth routingu přes opencode, následně Anthropic enforcement (2026-01-09 + 2026-02-19 formální ToS update + 2026-04-04 plný ban). DHH ("very customer hostile") amplifikoval na HN a Twitter. Kontroverze sama o sobě generovala organický marketing — ale opencode mezitím odstranil veškerý OAuth kód (2026-02-19).

4. **Granularita agentů je plochá (4 built-in primary/subagent + system)**, definovaná v `packages/opencode/src/agent/agent.ts:117–250`. Agent prompt = systémový prompt definovaný jako string nebo file reference; žádná process decomposition do numbered steps nebo constraints sekce. Radikálně tenčí než ceos-agents definice. Customizace přes `opencode.json agent.*` nebo `.opencode/agents/*.md` markdown soubory s frontmatter — přímý markdown+YAML frontmatter pattern.

5. **Přenositelné vzory do markdown-only prostředí jsou limitované:** opencode vyžaduje JavaScript/TypeScript runtime (Bun), HTTP server, Drizzle ORM databázi. Konceptuálně přenositelné jsou: (a) `mode: primary | subagent | all` tripartitní dělení agentů, (b) permission-per-tool-per-agent granularita, (c) `agent.steps` max-iteration limit per agent, (d) Plan/Build duality (read-only vs full-tool agent jako první-class UI koncept), (e) `instructions: []` pole pro multi-file instrukce. Žádná z těchto funkcí nevyžaduje runtime.

---

## 1. Granularita agentů

### Počet a typy

opencode definuje **4 user-facing built-in agenty** + 3 systémové skryté agenty:

**Primary agenty** (viditelné uživateli, cyklování přes Tab):
- **build** — defaultní vývojářský agent, plný přístup k nástrojům (`packages/opencode/src/agent/agent.ts:109–123`)
- **plan** — restricted agent, `edit` tool denied globálně kromě `.opencode/plans/*.md` (`agent.ts:124–146`)

**Subagenty** (spouštěné AI přes `task` tool nebo `@mention`):
- **general** — parallel task executor, `todowrite` denied aby neznečišťoval koordinaci (`agent.ts:147–160`)
- **explore** — read-only codebase investigator, přístup jen k `grep, glob, list, bash, read, search` + instrukce "specify thoroughness level: quick, medium, or very thorough" (`agent.ts:161–187`)

**Systémové skryté agenty:**
- **compaction** — context summarization
- **title** — session title generation
- **summary** — activity summarization

Citace: (`deepwiki.com/sst/opencode/3.2-agent-system`, 2026-04)

### Formát definice agenta

Každý agent je definován schématem `Info` (`agent.ts:27–69`) s těmito poli:

```yaml
# Markdown varianta (.opencode/agents/review.md)
---
description: Code review without modifications
mode: subagent           # primary | subagent | all
model: anthropic/claude-sonnet-4-20250514  # optional
temperature: 0.1          # optional, 0.0-1.0
top_p: 0.9                # optional
steps: 5                  # optional, max agentic iterations
color: "#ff6b6b"          # optional, UI appearance
hidden: true              # optional, hide from autocomplete
disable: false            # optional, deactivate
permission:               # optional, tool access control
  edit: deny
  bash:
    "*": ask
    "git *": allow
---
Instructions for the agent appear as the system prompt here.
```

Citace: (`opencode.ai/docs/agents/`, 2026-04; `deepwiki.com/sst/opencode/3.2-agent-system`, 2026-04)

### Délka a token odhad

Built-in agentní prompty jsou krátké — v `agent.ts` jsou prompty definovány jako inline stringy nebo reference na soubory v `packages/opencode/src/session/prompt/`. Na základě dokumentace a zdrojového kódu `explore` agent má nejdelší instrukci ("specify thoroughness level: quick, medium, or very thorough") — odhadovaných 20–50 tokens per agent definice. Systémové prompty (compaction, summary) jsou specifické a pravděpodobně delší (100–300 tokens), ale neveřejné.

Toto je radikálně "thin" pattern (Run 1 terminologie) oproti ceos-agents 100–500 řádků. opencode vsázela na to, že model sám ví co dělat, pokud dostane správné **tool permissions** a **mode restriction**, nikoli verbose instrukce.

### Dispatch mechanism

**Primary agents:** uživatel cykluje Tab klávesou. Přepnutí kdykoli, i v průběhu session.

**Subagents:** primární agent autonomně volá `TaskTool`, který spawní child session a inicializuje požadovaný subagent. Delivery best-effort (JSONL inbox + session injection dual-track). Subagenty nemohou spawnovzt další subagenty (tool visibility hiding + permission deny). (`dev.to/uenyioha/porting-claude-codes-agent-teams-to-opencode-4hol`, 2026-Q1)

Generace nového agenta přes LLM: `generate` funkce přijme popis a vrátí `{ identifier, whenToUse, systemPrompt }` — beta/experimental feature (`agent.ts` generate interface).

---

## 2. Pipeline configuration mechanism

### Primární konfigurační formát

opencode používá **JSON** jako primární konfigurační formát: `opencode.json` v project rootu nebo `~/.config/opencode/opencode.json` globálně. Alternativně `.opencode/` adresář obsahující agent `.md` soubory, tool soubory, pluginy.

**Není žádný YAML pipeline DSL.** Není žádná deklarace stage ordering. Pipeline = autonomní agentic loop, nikoli hardcoded sekvence kroků.

### `.opencode.json` schema — kompletní přehled

Všechny klíče jsou optional (bez required):

| Top-level klíč | Typ | Popis |
|---|---|---|
| `$schema` | string | "https://opencode.ai/config.json" pro IDE support |
| `model` | string | Primary model (např. "anthropic/claude-sonnet-4-5") |
| `small_model` | string | Lightweight model pro title/summary generaci |
| `provider` | object | Per-provider konfigurace (timeout, apiKey, region) |
| `server` | object | HTTP server nastavení (port, hostname, mDNS, cors) |
| `tools` | object | Tool availability (legacy, deprecated in favor of permission) |
| `agent` | object | Custom agent definitions jako objekt `{ agent-name: AgentDef }` |
| `default_agent` | string | Defaultní agent identifier |
| `command` | object | Custom slash command definitions |
| `formatter` | object | Per-formatter config (command, extensions, disabled) |
| `permission` | object | Globální tool permission defaults (ask/allow/deny) |
| `share` | string | "manual" | "auto" | "disabled" |
| `snapshot` | boolean | Git-based change tracking (default: true) |
| `autoupdate` | boolean/string | true | false | "notify" |
| `compaction` | object | Context compaction settings (auto, prune, reserved) |
| `watcher` | object | File watcher ignore patterns |
| `mcp` | object | MCP server konfigurace |
| `plugin` | array | Plugin names/paths |
| `instructions` | array | Instruction file paths + glob patterns (přidáváno do context) |
| `disabled_providers` | array | Provider IDs k vypnutí |
| `enabled_providers` | array | Provider allowlist |
| `experimental` | object | Unstable features |

Citace: (`opencode.ai/docs/config/`, 2026-04; `deepwiki.com/sst/opencode/3-configuration-system`, 2026-04)

### Konfigurace precedence (8 vrstev, highest wins)

1. Remote (`.well-known/opencode` — organizační defaults)
2. Global (`~/.config/opencode/opencode.json`)
3. Custom (`OPENCODE_CONFIG` env var)
4. Project (`opencode.json` v project tree)
5. `.opencode/` directories (agents, tools, plugins)
6. Inline (`OPENCODE_CONFIG_CONTENT` env var)
7. Managed (`/etc/opencode`, `ProgramData` — enterprise MDM)
8. macOS MDM preferences (`.mobileconfig` — nejvyšší priorita)

Merging strategy: `mergeDeep` z knihovny `remeda` s `mergeConfigConcatArrays` pro array pole (concatenate + deduplicate, nikoli replace). Citace: (`deepwiki.com/sst/opencode/3-configuration-system`, 2026-04)

### Stage ordering / agent dispatch

**Žádný explicitní pipeline DSL.** opencode je autonomní agent — prompt → agentic loop → tool calls → response. Stage ordering je emergentní z chování modelu, ne deklarativní konfigurace. Jedinou "pipelinou" je Plan mode (analýza bez commitů) → Build mode (implementace) jako dvou-krokový workflow, ale přechod je **manuální uživatelský úkon** (Tab), nikoli automatická orchestrace.

Toto je fundamentálně odlišné od ceos-agents přístupu (hardcoded 8+ stage sequential pipeline). opencode nevynucuje žádný workflow — je to conversational coding agent s tool harness.

---

## 3. Per-project customization

### Mechanismus customizace

opencode implementuje **3-vrstvou customizaci** konzistentní s Generic+Overlay paradigmatem:

**Vrstva 1 — Global defaults:**
`~/.config/opencode/opencode.json` + `~/.config/opencode/AGENTS.md` + `~/.config/opencode/agents/*.md`

**Vrstva 2 — Project-level overlay:**
`opencode.json` (nebo `.opencode.json`) v project rootu + `AGENTS.md` v project rootu + `.opencode/agents/*.md`

**Vrstva 3 — Per-agent override:**
Jednotlivá pole `agent.<name>.model`, `agent.<name>.permission`, `agent.<name>.temperature` přepisují built-in defaults

**Instructions pole jako additive overlay:**
```json
{
  "instructions": ["CONTRIBUTING.md", "docs/guidelines.md", "**/.rules/*.md"]
}
```
Glob patterny, remote URLs (5s timeout), všechny soubory jsou concatenated do LLM contextu. Toto je přímý ekvivalent ceos-agents `Agent Overrides` mechanism — append-to-prompt, nikoli fork.

Citace: (`opencode.ai/docs/rules/`, 2026-04)

### AGENTS.md integrace

opencode respektuje `AGENTS.md` hierarchii kompatibilní s Claude Code:

1. Project root `AGENTS.md` (highest priority)
2. Global `~/.config/opencode/AGENTS.md`
3. Claude Code compat: `~/.claude/CLAUDE.md` (pokud enabled)

`/init` command auto-generuje project-specific `AGENTS.md` skenováním repozitáře. Doporučeno commitovat do Gitu. (`opencode.ai/docs/rules/`, 2026-04)

### Konkrétní file paths v source kódu

- Agent service: `packages/opencode/src/agent/agent.ts` (lines 27–203)
- Session prompt: `packages/opencode/src/session/prompt/` (directory)
- ACP agent protocol: `packages/opencode/src/acp/agent.ts`
- Config schema: `packages/opencode/src/config/` (Effect.Schema s Zod surface)
- Tool directory: `.opencode/tool/` (custom tools, filename = tool name)
- Plugin directory: `.opencode/agents/*.md` nebo globální `~/.config/opencode/agents/`

---

## 4. HITL pattern

### Plan vs Build dualita

opencode implementuje HITL primárně přes **mode switching** a **permission system**, nikoli přes explicitní approval gates per pipeline stage.

**Plan mode** (built-in primary agent):
- `edit`, `write`, `patch`, `bash` tools jsou denied globálně
- Výjimka: zápis do `.opencode/plans/*.md` povolen
- Účel: AI analyzuje a navrhuje bez commitování změn
- Přechod: Tab klávesa cykluje mezi primary agents (build ↔ plan)
- Citace: (`opencode.ai/docs/modes/`, 2026-04)

**Build mode** (defaultní):
- Plný přístup k nástrojům dle permission config
- Optimální pro implementaci po schválení plánu

Toto je **dvoustupňový HITL pattern** — user explicitně přepne do Plan mode pro review, pak do Build mode pro execution. Je to strukturálnější než ad-hoc ale volnější než ceos-agents acceptance-gate architektura.

### Permission-based HITL

Granulární per-tool per-agent permissions se třemi stavy:

- `"allow"` — execute bez approval
- `"ask"` — zobrazí uživateli approval prompt se třemi volbami:
  1. **once** — schválit jen tento request
  2. **always** — schválit matching pattern pro zbytek session
  3. **reject** — zamítnout
- `"deny"` — blokovat execution

Bash příkazy: pattern matching s wildcards (last matching rule wins):
```json
"bash": {
  "*": "ask",
  "git *": "allow",
  "rm *": "deny"
}
```

Citace: (`opencode.ai/docs/permissions/`, 2026-04)

### Doom loop protection

`doom_loop` permission key (defaultně `"ask"`) detekuje repeated identical tool calls — automatická ochrana před nekonečnými retry smyčkami bez explicitního per-stage HITL.

### HITL výsledek

opencode HITL pattern je **per-tool-call event-driven**, nikoli per-stage. Konzistentní s Run 1 Q6 vendor consensus (Anthropic `needsApproval` pattern, OpenAI `RunToolApprovalItem`). **Žádná acceptance gate, žádný triage checkpoint, žádný pre-publish review** — to jsou ceos-agents specifické pipeline patterns bez ekvivalentu v opencode.

---

## 5. Stateful vs stateless agent design

### Session persistence

opencode session je **stateful within session, stateless across sessions**:

- **Within session:** `SessionPrompt.loop()` orchestruje agent processing, conversation state persistována přes Drizzle ORM do SQLite databáze. Každá zpráva je uložena, kompakce probíhá automaticky (`compaction: { auto: true }`).
- **Across sessions:** LLM je fundamentálně stateless — každá nová session startuje čistě. "Your OpenCode Agent Forgets Everything Between Sessions" (Hindsight blog, 2026-04-20) potvrzuje jako known pain point komunity.

Citace: (`deepwiki.com/sst/opencode` architecture overview, 2026-04; `hindsight.vectorize.io/blog/2026/04/20/opencode-persistent-memory`, 2026-04)

### Cross-session memory ekosystém

Komunita vytvořila plug-in ekosystém pro cross-session memory:

- **Hindsight** (`@vectorize-io/opencode-hindsight`): retain/recall/reflect tools + automatic hooks, memories injected to system prompt on session start
- **Memory Blocks** (`joshuadavidthomas/opencode-agent-memory`): Letta-style shared markdown blocks jako shared state
- **Supermemory plugin**: session summary + profile + project memories + semantic search

Citace: (`github.com/joshuaberkowitz.us/blog/github-repos-8/opencode-...`, 2026-04; `github.com/joshuadavidthomas/opencode-agent-memory`, 2026-04)

### Multi-turn behavior

Within session: plná multi-turn konverzace, model vidí celou historii (s kompakcí při overflow). Agent si "pamatuje" co udělal dřív v rámci session.

Subagent sessions: child sessions jsou independent — subagent dostane task description + relevantní kontext, ale ne celou parent session historii. Koordinace přes JSONL inbox (O(1) writes, append-only audit trail) + session injection (immediate LLM delivery). (`dev.to/uenyioha/porting-claude-codes-agent-teams-to-opencode-4hol`, 2026-Q1)

### Srovnání s ceos-agents

ceos-agents stateless dispatch + `state.json` + `pipeline-history.md` je funkčně ekvivalentní opencode stateful-within-session + stateless-across: oba udržují pipeline state externě (ceos-agents: JSON soubory; opencode: SQLite přes Drizzle ORM), oba mají stateless jednotlivé agent dispatche. **ceos-agents pattern je architektonicky správný** pro orchestrator-driven pipeline; opencode pattern je optimální pro conversational agent s kontinuálním kontextem.

---

## 6. Lessons learned specifické pro opencode

### Virální growth: "Claude Max routing trick"

**Mechanismus:** opencode v1.0 rewrite (late December 2025) zachoval OAuth flow identický s Claude Code — uživatelé mohli autentikovat se svým Claude Pro/Max credentialy přes `/connect` command, který openal browser a získal OAuth tokens stejným způsobem jako oficiální Claude Code. Technicky: headers simulovaly Claude Code client identity, Anthropic servery akceptovaly requesty jako by přicházely od oficiálního nástroje.

**Ekonomický motiv:** Claude Max předplatné $200/měsíc poskytovalo přístup k výpočetním zdrojům v hodnotě odhadovaných $3,000–$4,000/měsíc (dle Medium analýzy, Feb 2026). Pro heavy users = 93% úspora.

**Virální mechanismus:**
1. Late December 2025: v1.0 rewrite released, community discovers OAuth routing
2. 2026-01-09: Anthropic začíná technicky blokovat third-party OAuth přístup
3. Community backlash: DHH ("very customer hostile"), HN front page, Twitter developer community
4. 2026-01-09 → 2026-01-23: +18,000 GitHub stars za 2 týdny (Medium, Feb 2026)
5. 2026-02-19: Anthropic formalizuje ToS — "Using OAuth tokens obtained through Claude Free, Pro, or Max accounts in any other product, tool, or service — including the Agent SDK — is not permitted" (The Register, Feb 2026)
6. 2026-02-19: opencode odstraní veškerý Claude OAuth kód z codebase
7. 2026-04-04: Anthropic implementuje plný policy ban (Apiyi.com blog, Apr 2026)

Citace: (`medium.com/@milesk_33/opencodes-january-surge-...`, Feb 2026; `theregister.com/2026/02/20/anthropic_clarifies_ban_third_party_claude_access/`, Feb 2026; `news.ycombinator.com/item?id=47444748`, 2026-04)

**Anthropic ToS implikace:** Anthropic v novém ToS explicitně zakázal OAuth token reuse pro third-party tools. opencode přešel na přímé API klíče (pay-as-you-go model). Kontroverze odhalila fundamentální tension: uživatelé preferují vendor-agnostic tooling i při technicky horším výkonu. `shareuhack.com/en/posts/opencode-anthropic-legal-controversy-2026` (Apr 2026) sumarizuje: "Open vs Closed Debate Over AI Coding Tools."

**Mezinárodní proxy ekosystém:** Meridian (`github.com/rynfar/meridian`) a `opencode-with-claude` plugin (`github.com/ianjwhite99/opencode-with-claude`) nadále nabízejí proxy most pro Claude Max subscribers přes "documented SDK calls with no OAuth interception" — legální grey area exploiting official SDK paths, ne OAuth spoofing. Citace: (`github.com/rynfar/meridian`, 2026-04)

### Scaling pain points (komunita)

1. **Session management complexity:** Session organization je dokumentovaný scaling pain point — requests pro custom naming, better file scope clarity, fork/undo capabilities. Session-related code files "extremely large and try to do everything related to sessions" — maintainability concern. (`github.com/anomalyco/opencode/issues/10761`, 2026-04)

2. **Windows platform parity:** Windows line endings + PowerShell path handling = ongoing pain. ARM64 ripgrep fix v1.14.x. WSL2 jako workaround. (`releasebot.io/updates/sst/opencode`, 2026-04)

3. **Configuration discoverability:** Missing model documentation, setup friction pro local models. `opencode.ai/docs` navigation requires digging. Komunita žádá plugin repository pro discovery.

4. **Anthropic OAuth ban impact:** Uživatelé nuceni přejít na pay-as-you-go API pricing, significantní cost increase pro heavy users. Builder.io (2026) kvantifikuje: Claude Max subscription = "~$2,600 worth of API credits" za $200/měsíc. (`builder.io/blog/opencode-vs-claude-code`, 2026)

5. **Security incident:** CVE-2026-22812 (CVSS 8.8) — uncontrolled remote code execution vulnerability before patching. (`thomas-wiegold.com/blog/i-switched-from-claude-code-to-opencode/`, 2026)

6. **Subagent coordination unresolved issues:** Best-effort delivery receipts, no backpressure mechanism, manual recovery after server crashes, single-process architecture limitation. (`dev.to/uenyioha/porting-claude-codes-agent-teams-to-opencode-4hol`, 2026-Q1)

### v1.0 rewrite historia

Původní opencode (pre-v1.0): Go-based CLI application. v1.0 rewrite (late December 2025): kompletní rewrite na TypeScript/Bun monorepo s Zig-renderovaným TUI. Důvod přepisu: SST team z opencode fork vytvořil Anomaly Innovations (anomalyco/opencode) — de facto kontinuita projektu, ale pod novým ownership. Technologická volba TypeScript/Bun: alignment s SST/Anomaly's existing TypeScript expertise + Bun speed + monorepo management. Vercel AI SDK poskytuje 75+ provider abstrakci.

"Why the typescript and npm?" — GH issue #2143 (2025-08-21): původní user advocate pro Go static binary, issue closed bez veřejné odpovědi maintainera. (`github.com/sst/opencode/issues/2143`, 2025-08)

**Performance výsledky rewrite:** Go TUI + TypeScript core hybrid: 6s file processing vs 18–24s pro Node.js-based tools, 150ms startup vs 1.2–2s Cline. (`dev.to/ji_ai/opencode-hit-140k-stars-why-terminal-agents-won-2026-aci`, 2026-Q1)

### "TUI agents won 2026" thesis — empirické hodnocení

**Signály PRO:**
- opencode: 150k★, 6.5M monthly devs, 14.53M npm downloads/March 2026
- 3 workflow shifts driving adoption: (a) remote dev normalization (SSH/Codespaces), (b) Claude Code normalizoval CLI workflow, (c) multi-machine development mainstream
- "A terminal agent is already there" v remote boxes bez IDE forwarding
- Builder.io test: Claude Code vs opencode na stejných task — performance srovnatelná (opencode thorougher v testech, Claude Code faster)

**Signály PROTI:**
- "Cline still wins for a specific flow: editing inside VS Code with inline suggestions and selection-aware context" — IDE agents nezomřely
- Cursor 3 (Apr 2026) = "biggest architectural change since launch" — IDE tool se reinventoval, nezavřel
- opencode performance lead (6s vs 18-24s) je měřitelný ale nikoli game-changing pro workflow
- Anthropic OAuth ban odstranil key viral driver — "Claude Max routing trick" už nefunguje

**Závěr:** "TUI agents won 2026" je **over-claimed jako universální thesis** — ale empirické adoption čísla potvrzují, že terminal-native agents získaly reálný tržní podíl dříve dominovaný IDE tools. Spíše než "winner takes all" jde o bifurkaci: remote/cloud dev → terminal agents; inline editing → IDE agents.

---

## 7. Co lze přenést do markdown-only Claude Code plugin (ceos-agents kontext)

**Vědomí kontextu:** ceos-agents je markdown-only plugin bez runtime. Nemůže replikovat opencode's HTTP server, Drizzle ORM, Bun plugin system, ACP protokol, nebo Zig TUI. Následující je seznam konceptuálně přenositelných vzorů, nikoli implementačních řešení.

### 7a. `mode: primary | subagent | all` tripartice

opencode jasně dělí agenty na:
- **primary** — user-facing, cykluje Tab, pro hlavní interakci
- **subagent** — AI-spouštěný, skrytý před uživatelem, specializovaný
- **all** — hybridní dostupnost

ceos-agents rozlišení na "read-only agents" vs "execution agents" je analogické, ale není explicitně exposed v UX. Přenositelné: explicitní metadata pole `mode` v agent frontmatter komunikující uživateli (a LLM) kdy agent přebírá kontrolu vs kdy je dispatched orchestratorem.

### 7b. Permission-per-tool-per-agent granularita

opencode permission model per agent (`edit: deny`, `bash: { "*": ask, "git *": allow }`) je přenositelný jako **konceptuální vzor pro ceos-agents `Agent Overrides`**. Místo append-to-prompt, explicitní tool restriction documentation v agent definici informuje orchestratora o tom, jaké nástroje smí agent použít. ceos-agents "read-only agents NEVER modify code" = neformální ekvivalent, ale opencode model je machine-readable konfigurace, nikoli prose constraint.

### 7c. `agent.steps` max-iteration limit

opencode `steps` field (max agentic iterations per agent) je přenositelný jako formální limit v ceos-agents agent frontmatter. ceos-agents aktuálně implementuje retry limits v `### Retry Limits` Automation Config sekci — opencode přístup per-agent steps limit je granulárněji konfigurovatelný.

### 7d. Plan/Build dualita jako first-class UX concept

opencode Plan mode = primární agent s disabled edit/write/bash tools. ceos-agents má analogii v code-analyst (read-only analysis) → fixer (execution) pipeline, ale tato dualita není exposed jako user-toggleable mode. Přenositelný vzor: explicitní pojmenování "analysis phase" vs "execution phase" jako first-class koncepty v pipeline dokumentaci pro uživatele.

### 7e. `instructions: []` pole pro multi-file instrukce

opencode `instructions` array v `opencode.json` — glob patterns, remote URLs, multiple files concatenated do context. ceos-agents `Agent Overrides` directory je funkcionálně ekvivalentní ale single-file-per-agent. Přenositelný: podpora glob patterns v Agent Overrides (např. `customization/*.md` → aplikovat všechny), nebo `instructions` pole v Automation Config pro globální projekt-specifické instrukce přidávané ke všem agentům.

### 7f. Remote config URL pro organizační defaults

opencode `.well-known/opencode` remote config endpoint = organizační konfigurace servovaná přes HTTP, přepisuje global config ale podléhá project override. Přenositelný pro ceos-agents enterprise use case: shared Automation Config template URL (CONTRIBUTING.md pointer na shared config endpoint).

### 7g. Subagent isolation pattern (deny todowrite, deny task recursion)

opencode explicitně denies `todowrite` u `general` subagenta aby zabránil "background clutter" v koordinaci. `task` a `skill` permissions umožňují restrict subagent spawning. Přenositelné pro ceos-agents: explicitní `NEVER` constraint v subagent definitions zakazující další dispatch (test-engineer NEVER dispatches another agent, reproducer NEVER spawns sub-agents) — aktuálně prose constraint, mohlo by být standardizované jako metadata pole.

---

## 8. Co je framework-specific

### Runtime: TypeScript/Bun + Zig

**Bun runtime je hard dependency.** Plugin system (`@opencode-ai/plugin`) vyžaduje JavaScript/TypeScript module export. Custom tools v `.opencode/tool/` jsou Bun JavaScript soubory. Bez Bun runtime žádná extensibility. ceos-agents (markdown plugin bez build system) nemůže replikovat plugin SDK.

**Zig TUI renderer** — proprietární `OpenTUI` framework, Zig kompilovaný binary. Provides 150ms startup + 6s file processing. Nelze replikovat v markdown plugin kontextu.

**Drizzle ORM + SQLite** pro session state persistence. ceos-agents `state.json` + `pipeline-history.md` je funkčně ekvivalentní pro pipeline-style orchestration, ale nemá full conversational history replay.

### Language lock-in

TypeScript/JavaScript ecosystem lock-in. Komunita explicitně žádala Go static binary (GH issue #2143) — odpověď: closed, bez veřejné odpovědi. Go SDK (`opencode-sdk-go`) existuje ale je client SDK, nikoli core.

### Vendor dependency

75+ providers přes Vercel AI SDK. Toto je **výhoda i riziko**: abstrakce umožňuje model routing (plánovat s Claude Opus, implementovat s Haiku), ale přidává Vercel AI SDK jako dependency. ceos-agents dependency: pouze Claude Code jako runtime — jednodušší ale méně flexibilní.

### Distribution model

**opencode: distribovaný software** (npm package + GitHub binary releases). Instalace přes: `npm install -g opencode`, `curl -fsSL https://opencode.ai/install | bash`, Homebrew, Nix, Scoop. Není to plugin do existujícího nástroje — je to standalone competing tool.

**ceos-agents: plugin do Claude Code.** Distribuce přes `claude plugin install`. Toto je fundamentálně odlišný distribution model — opencode kompetuje s Claude Code, ceos-agents rozšiřuje Claude Code.

**Implikace pro ceos-agents v8.0.0:** opencode není vzor pro "jak distribuovat claude code plugin" — je to vzor pro "co by mohl standalone competitor nabídnout." Relevantní jako komparativní benchmark a zdroj inspirace pro feature parity, nikoli jako implementační vzor.

### ACP protokol (IDE integrace)

Agent Client Protocol (`opencode acp` subprocess, JSON-RPC over stdio) umožňuje Zed, JetBrains, Neovim, CodeCompanion použít opencode jako AI backend. ceos-agents plugin model nemá přímý ekvivalent — IDE integrace probíhá přes Claude Code's vlastní IDE extensions.

### Proprietární subscription tier

"OpenCode Zen" a "OpenCode Go" jsou proprietární subscription services (`opencode.ai/auth`) nabízející curated model access. Toto je business model rozhodnutí specifické pro opencode — ceos-agents nemá analogii.

---

## Lens disclosure

### Primárně využité sources

1. **opencode.ai/docs** (config, agents, rules, modes, permissions, acp, plugins, tui) — primární vendor dokumentace. Nejspolehlivější source pro schema a API.
2. **deepwiki.com/sst/opencode** (agent-system, configuration-system, sdks-and-extension-points) — DeepWiki automaticky generovaná dokumentace ze source kódu. Konzistentní s vendor docs, s dodatečnými implementačními detaily.
3. **github.com/sst/opencode** (AGENTS.md, agent.ts source, issues #2143, STATS.md, releases) — primární source pro historická data a implementační detaily.
4. **medium.com/@milesk_33** (January surge analysis, Feb 2026) — nejdetailnější analýza viral mechanismu.
5. **theregister.com** (Anthropic ToS clarification, Feb 2026) — authoritative source pro ToS implikace.
6. **dev.to/ji_ai** ("Why Terminal Agents Won 2026", 2026-Q1) — community-side paradigm shift analýza.
7. **dev.to/uenyioha** (porting agent teams, 2026-Q1) — technická analýza subagent koordinace.
8. **builder.io/blog** (OpenCode vs Claude Code, 2026) — performance srovnání.
9. **releasebot.io/updates/sst/opencode** — release cadence data (v1.14.25 k 2026-04-25).

### Evidence gaps

1. **Maintainer rationale pro TypeScript over Go rewrite:** GH issue #2143 closed bez veřejné maintainer odpovědi. Důvody pro rewrite z Go na TypeScript/Bun nejsou veřejně dokumentovány v žádném nalezitelném blog postu nebo announcement.

2. **Konkrétní token counts pro built-in agent prompty:** `packages/opencode/src/session/prompt/` directory contents nebyly veřejně přístupné — agent prompt délky jsou odhadované, nikoli měřené.

3. **Commit velocity verify k 2026-04-26:** Run 1 citoval 1 282 commits/30d. Releasebot data (v1.14.25, 2026-04-25) potvrzuje aktivní development s denními releases — velocity pravděpodobně comparable nebo vyšší, ale přesné číslo k 2026-04-26 nebylo verifikováno novým měřením.

4. **Full STATS.md pro April 2026:** STATS.md (github.com/anomalyco/opencode/blob/dev/STATS.md) končí k 2026-01-29 (10,19M downloads). April 2026 data pocházejí z sekundárních zdrojů (Medium, DeepWiki navigation mentioning "150k stars").

5. **Subagent coordination unresolved issues detail:** GH issue #10761 community thread neobsahoval specifické odpovědi v čase fetchování — pouze template invitation pro feedback.

6. **opencode.ai performance claims verificability:** "6s file processing vs 18–24s" a "150ms startup vs 1.2–2s Cline" jsou citovány z dev.to analýzy, nikoli z vlastního benchmarku. Treat as indicative, not authoritative.

---

*Citace formát v tomto dokumentu: klíčové URL jsou vždy inline v kontextu tvrzení. Kompletní seznam viz "Lens disclosure" sekce výše.*
