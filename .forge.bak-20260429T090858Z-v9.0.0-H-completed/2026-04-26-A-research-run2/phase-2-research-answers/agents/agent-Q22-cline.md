# Q22 Deep-Dive: Cline — Per-Step HITL Exemplar a Modular Prompt Composition

**Agent:** Q22-cline (Run 2 deep-dive)
**Datum:** 2026-04-26
**Primární lens:** OSS code (cline/cline GitHub source)
**Sekundární lens:** Community (Reddit, HN, changelog, GitHub releases, docs)
**Recency:** Cline v3.81.0 vydán 2026-04-24 — all data verified k tomuto datu
**Relevance pro sub-projekt B:** KRITICKÁ — per-step HITL exemplar + YOLO evolution timeline

---

## Lens disclosure

Tento report čerpá primárně ze dvou zdrojů:

1. **OSS code** — přímé čtení TypeScript source kódu repozitáře `cline/cline` přes GitHub API. Všechny file paths a line-level citace jsou verifikované ke commitu main branch přítomným k 2026-04-26. Repozitář prošel significantní refaktorizací: originální `system.ts` jednoduchý soubor byl nahrazen modulárním systémem `src/core/prompts/system-prompt/` s registry, builder, komponenty a varianty.

2. **Community** — GitHub release notes (kompletní timeline z GitHub API), Cline dokumentace (docs.cline.bot), GitHub marketplace page, GitHub issue tracker. Reddit fetch selhal (403), HN search nenalezl relevantní Cline-specifický thread.

**Poznámka k "CC5 controversy"** zmíněné v Run 1 final.md: Přes systematické vyhledávání na HN, GitHub discussions a issues se konkrétní thread označovaný jako "CC5 controversy" nepodařilo identifikovat. Nejpravděpodobnější interpretace: Run 1 agent pravděpodobně referencoval obecnou komunitní kritiku "per-step approval je neudržitelný pro autonomní workflow" bez specific thread ID. Tato kritika je dobře doložena jinými zdroji (viz Dimenze 4 níže). Nepotrzený claim = disclosed jako "unverified" v souladu s hard rules tohoto runu.

---

## Exec summary

Cline (61,019 GitHub stars k 2026-04-26, 3.7M VSCode installs) je **single-agent IDE-resident architecture** s jedním ze dvou nejdůkladněji zdokumentovaných HITL evolutions v ekosystému. Čtyři poznatky jsou architektonicky kritické pro sub-projekt B:

1. **Per-step approval jako founding principle (2024)** — každé tool call vyžadovalo explicitní user click. Popis v repozitáři k 2026-04-26 stále zní: *"capable of creating/editing files, executing commands, using the browser, and more with your permission every step of the way"* — GitHub repo description. Toto je nejčistší per-step HITL exemplar v ekosystému.

2. **Auto Approve jako první ústupek (2024-08 → 2025-05)** — v1.4.0 (2024-08-26) přidán "Always allow read-only operations" jako první granulární bypass. v3.0.0 (2024-12-18) jako "Cline's most requested feature" přišel plný Auto-approve menu. Friction signal: uživatelé opakovaně klikali "Approve" na stejné low-risk operace.

3. **YOLO mode jako druhý ústupek (2025-09)** — experimentální YOLO mode v3.30.1 (2025-09-19), formalizovaný v v3.31.0 (2025-09-25): plná deaktivace všech approval gates. CLI flag `--yolo` přidán ve v3.32.7 (2025-10-08). YOLO mode rozšířen v v3.58.0 (2026-02-12): custom `--thinking` token budget a `--max-consecutive-mistakes` flag.

4. **Modular system prompt composition** — od run 1's "15-line `agent_role.ts`" k nyní plně modulárnímu systému s **14 komponentami registrovanými přes `PromptRegistry`**, každá jako samostatný TypeScript modul s `componentOverrides` hook pro per-variant customization. Composition order definovaná v `components/index.ts:getSystemPromptComponents()`.

---

## Dimenze 1 — Granularita agentů

**Cline = single-agent IDE-resident architecture.** Žádný orchestrátor, žádný multi-agent dispatch, žádné specializované sub-agenty v core flow. GitHub repository description (verifikováno 2026-04-26): *"Autonomous coding agent right in your IDE, capable of creating/editing files, executing commands, using the browser, and more with your permission every step of the way."*

Jedna LLM instance drží celou session. Celý codebase — file reading, terminal execution, browser use, MCP tool invocation — je přístupný jednomu agent loop přes tool calls. Granularita agenta = maximální (vše v jednom). Subagents feature (v3.58.0, 2026-02-12: *"replace legacy subagents with the native `use_subagents` tool"*) umožňuje Cline spustit nový Cline task jako subprocess, ale toto je **volitelná feature, ne architektonický základ**.

**Srovnání s ceos-agents:** ceos-agents má 21 úzce specializovaných agentů (triage-analyst, code-analyst, fixer, reviewer, test-engineer, …). Každý agent dostane fresh context dispatch. Cline nemá ekvivalent — jediný agent loop zpracovává triage, analýzu, implementaci i verifikaci sequentially v jediné conversation thread. **Toto je fundamentální architektonická propast**: ceos-agents je role-switching multi-specialist pipeline, Cline je single-generalist continuous-context agent.

**Proč je granularita v Cline relevantní pro sub-projekt A:** Cline dokazuje, že single-agent model s bohatou tool sadou může dosáhnout vysoké adopce (61k★) — evidence pro "Fixer can do it all" variantu v A.1 brainstormu. Run 1 final.md (Q2 sekce) cituje Kim et al. 2512.08296: *"single-agent baselines překonávají multi-agent na SWE benchmarks"* — Cline je production exemplar tohoto claims.

---

## Dimenze 2 — Pipeline configuration mechanism

**Cline nemá pipelines v ceos-agents smyslu slova.** Neexistuje hardcoded sequence `TRIAGE → CODE-ANALYST → FIXER → REVIEWER`. Místo toho:

- Agent loop iteruje: user message → LLM response (tool calls) → tool execution → result → LLM next step
- **Tool selection = LLM decision** — model rozhodne, zda next step je `read_file`, `execute_command`, `replace_in_file`, nebo `attempt_completion`
- Sequence kroků emerguje z LLM reasoning, není prescriptivně definována

**Konfigurační mechanismus:** žádný. Uživatel nemůže specifikovat "nejdřív analyzuj, pak fixuj, pak verifikuj" — LLM to rozhoduje sám. Jedinou konfigurací jsou `.clinerules` (viz Dimenze 3) a `Plan mode vs Act mode`.

**Plan mode vs Act mode** (zavedeno v době v3.x, formalizováno do Auto Approve settingů): v Plan mode Cline pouze plánuje, NEVYKONÁVÁ změny — to je nejblíže "gate před implementací" v ceos-agents smyslu. v Act mode vykonává. Přepnutí je buď manuální (user button) nebo automatické v YOLO mode.

**Srovnání s ceos-agents:** ceos-agents definuje pipeline explicitně jako markdown prose (`skills/fix-bugs/SKILL.md` ~600 řádků). Fáze jsou deterministické, agenti přednastavení, order hardcoded. Cline nemá žádnou analogii — emergentní pipeline je výsledek LLM tool-use decisions, ne explicitní orchestrace.

---

## Dimenze 3 — Per-project customization

Cline má tři customization mechanismy:

### 3a — .clinerules (primární)

Dokumentace (docs.cline.bot/customization/cline-rules.md, verifikováno 2026-04-26):

- **Formát:** `.md` nebo `.txt` soubory v `.clinerules/` adresáři na project root
- **Conditional rules:** YAML frontmatter s `paths:` glob patterns — rule se aktivuje pouze když matching soubory jsou v kontextu
- **Hierarchie:** workspace rules (`.clinerules/`) > global rules (`~/Documents/Cline/Rules/`)
- **Cross-IDE compatibility:** Cline také načítá Cursor rules (`.cursor/rules/`), Windsurf rules (`.windsurfignore`), AGENTS.md — source verifikace v `user_instructions.ts`

**Implementace v kódu** — `src/core/prompts/system-prompt/components/user_instructions.ts`:

```typescript
export async function getUserInstructions(variant, context): Promise<string | undefined> {
    const customInstructions = buildUserInstructions(
        context.globalClineRulesFileInstructions,
        context.localClineRulesFileInstructions,
        context.localCursorRulesFileInstructions,
        context.localCursorRulesDirInstructions,
        context.localWindsurfRulesFileInstructions,
        context.localAgentsRulesFileInstructions,
        context.clineIgnoreInstructions,
        context.preferredLanguageInstructions,
    )
    // Returns undefined if no custom instructions → component skipped
}
```

Pořadí merge v `buildUserInstructions()`: `preferredLanguage` → `globalClineRules` → `localClineRules` → `localCursorRules` → `localCursorRulesDir` → `localWindsurfRules` → `localAgentsRules` → `clineIgnore` → concatenation s `\n\n`.

### 3b — Custom Instructions (IDE settings)

User-level instrukce zadané přímo v VS Code settings — mapovány na `globalClineRulesFileInstructions` a předány do `USER_INSTRUCTIONS` sekce.

### 3c — Memory Bank

Dokumentace (docs.cline.bot/features/memory-bank.md): strukturovaný systém markdown souborů v projektu. Hierarchická file struktura: `projectbrief.md`, `productContext.md`, `activeContext.md`, `systemPatterns.md`, `techContext.md`, `progress.md`. Memory Bank je **oficiální Cline feature** (dokumentace potvrzuje), nikoliv community-developed pattern jak bylo uvedeno v Run 1 zadání.

Memory Bank persists context across sessions protože Cline je inherentně stateless mezi konverzacemi (reset = nová konverzace). `/newtask` a `/smol` slash commands pomáhají manage context window limits.

### 3d — MCP Servers

MCP servers jsou třetí customization vrstvou — viz Dimenze 7 (framework-specific sekce).

**Srovnání s ceos-agents:** ceos-agents customization = `Agent Overrides` (append-to-prompt, analogické Cline `.clinerules`), `Pipeline Profiles` (skip/extra stages — bez Cline analogie), `Hooks` (bez Cline analogie). Cline jde dál v cross-IDE rules compatibility (Cursor/Windsurf/AGENTS.md ingestion) — to je pro ceos-agents inertní (Claude Code plugin, ne IDE extension).

---

## Dimenze 4 — HITL pattern (PRIORITA: celá UX evolution timeline)

### 4.1 Founding principle: per-step approval (2024-07 až 2024-11)

Cline byl od počátku postaven na filosofii **"your permission every step of the way"** — tato fráze zůstává v repository description k 2026-04-26. GitHub repo description (verifikováno API): *"Autonomous coding agent right in your IDE, capable of creating/editing files, executing commands, using the browser, and more with your permission every step of the way."*

Každý tool call — `read_file`, `write_to_file`, `execute_command`, `browser_action` — vyžadoval explicitní user klik v IDE panel. Neexistoval bypass. Toto je **nejčistší per-step HITL exemplar v SWE agent ekosystému**.

**První Cline release:** v1.0.4, 2024-07-28. Tool approval byl zabudován od verze 0.

### 4.2 První ústupek: granulární read-only bypass (v1.4.0, 2024-08-26)

```
v1.4.0 — 2024-08-26
- Add "Always allow read-only operations" setting to let Claude read files and view directories without needing approval (off by default)
```

První uznání, že **read-only operations jsou low-risk** a opakované klikání "Approve" na file reads je friction bez hodnoty. Výchozí stav: off.

### 4.3 Auto Approve menu jako "most requested feature" (v3.0.0, 2024-12-18)

```
v3.0.0 — 2024-12-18
### Auto-approve
Cline's most requested feature is here 🎉 You can now let Cline work more autonomously 
with the new Auto-approve menu, letting you choose what tools he can use without needing 
your permission.
- Set a limit for how many API requests Cline makes before asking for your approval to keep going.
- And if you have Cline working in the background, he can send system notifications for when 
  he needs your attention, i.e. to get your approval, answer a question, or when a task is completed.
```

**Friction signal explicitní:** "most requested feature" = community pressure po ~5 měsících produkčního nasazení. Uživatelé zjevně opakovaně klikali "Approve" na low-risk actions. Release note potvrzuje, že **approval fatigue byl hlavní UX problém**.

Doplňující vývoj v v3.0.x a v3.1.x-v3.2.x:

```
v3.2.0 — 2025-01-21
- Add on/off toggle for MCP servers to disable them when not in use, 
  and auto-approve setting for individual tools in MCP servers.

v3.3.0 — 2025-02-09
- You can now create a .clineignore file to block Cline from accessing 
  specified file patterns. Especially useful when using auto-approve in 
  a project with sensitive files!
```

### 4.4 Granularity expansion (v3.8.5–v3.16.1, 2025-03 až 2025-05)

```
v3.8.5 — 2025-04-01
- Move the MCP Restart and Delete buttons and add an auto-approve all toggle

v3.10.0 — 2025-04-08
- Add new auto-approve option to approve ALL commands (use at your own risk!)

v3.12.0 — 2025-04-12
- Add auto-approve options for edits/reads outside of the workspace

v3.15.2 — 2025-05-12
- Added details to auto approve menu and more sensible default controls

v3.16.1 — 2025-05-18
- Enable auto approve toggle switch, allowing users to easily turn auto-approve 
  functionality on or off without losing their action settings
- Fix quick actions functionality in auto-approve settings
```

Pattern: "approve ALL commands (use at your own risk!)" — Cline tým **váhal** nabídnout plný bypass. Warning v release notes signalizuje tension mezi user demand a product safety posture.

### 4.5 YOLO Mode jako formální autonomní režim (v3.30.1 + v3.31.0, 2025-09)

```
v3.30.1 — 2025-09-19 (release date z GitHub API)
- Add experimental yolo mode feature that disables all user approvals and 
  automatically executes a task and navigates through plan to act mode 
  until the task is complete

v3.31.0 — 2025-09-25
- YOLO Mode: Enable in settings to let Cline approve all actions and 
  automatically switch between plan/act mode
```

Telemetry přidána ve v3.30.3 (2025-09-20): *"adding yolo mode telemetry by @0xToshii"* — signal, že tým sbírá data o YOLO mode usage. YOLO mode CLI flag `--yolo` formalizován v v3.32.7 (2025-10-08).

**Pozorování z release notes:** experimentální tagging v3.30.1 → formalizace v3.31.0 = jeden týden. Buď user response byl pozitivní, nebo byl YOLO připraven a experimentální tag byl marketing/safety posture.

### 4.6 Rozšíření YOLO pro CLI (v3.58.0, 2026-02-12)

```
v3.58.0 — 2026-02-12
- CLI: new task controls/flags including custom --thinking token budget and 
  --max-consecutive-mistakes for yolo runs
- Tools: add auto-approval support for attempt_completion commands
```

CLI `--yolo` flag + `--thinking` + `--max-consecutive-mistakes` = **headless autonomous pipeline mode**. Toto je přímá paralela k ceos-agents `/autopilot` skill — Cline CLI s YOLO = batch/CI autonomous execution bez IDE GUI.

### 4.7 Auto-approve 8 kategorií (2026, aktuální stav)

Dokumentace (docs.cline.bot/features/auto-approve.md, verifikováno 2026-04-26):

Osm granulárních kategorií auto-approve:
1. Read project files
2. Read all files (outside workspace)
3. Edit project files
4. Edit all files (outside workspace)
5. Execute safe commands (model-flagged)
6. Execute all commands
7. Use the browser
8. Use MCP servers

Model označuje každý command s `requires_approval` flag. "Safe" operace = build commands, read-only tasks. "Unsafe" = destructive operations, dependency changes.

**YOLO mode = blanket override** — bypass všech 8 kategorií simultánně. Dokumentace: *"This is dangerous"* a *"disables all safety checks."*

### 4.8 Enterprise YOLO controls (2026)

URL `docs.cline.bot/enterprise-solutions/configuration/infrastructure-configuration/control-other-cline-features/yolo-mode.md` — enterprise admins mohou centrálně konfigurovat YOLO mode availability. Toto signalizuje, že YOLO mode je nyní production-grade enterprise feature, ne experimental.

### 4.9 UX evolution timeline — souhrn

| Datum | Verze | HITL stav |
|-------|-------|-----------|
| 2024-07 | v1.0.x | Per-step approval, žádný bypass |
| 2024-08 | v1.4.0 | + "Always allow read-only" (opt-in) |
| 2024-12 | v3.0.0 | + Auto Approve menu ("most requested feature") |
| 2025-01 | v3.2.0 | + MCP per-tool auto-approve |
| 2025-04 | v3.10.0 | + "Approve ALL commands" (with warning) |
| 2025-05 | v3.16.1 | + Auto-approve toggle (on/off without losing settings) |
| 2025-09 | v3.30.1 | + Experimental YOLO mode |
| 2025-09 | v3.31.0 | + YOLO mode formalized + always-on auto-approve redesign |
| 2025-10 | v3.32.7 | + `--yolo` CLI flag |
| 2026-02 | v3.58.0 | + YOLO CLI extensions (--thinking, --max-consecutive-mistakes) |
| 2026-04 | v3.81.0 | Enterprise YOLO controls available |

**Směr vývoje:** od per-step manual gate → granulární kategorie → categorical bypass → full blanket bypass + CLI flag + enterprise controls. Každý krok byl friction-driven — reaction na user complaints o opakovaném klikání.

### 4.10 "CC5 controversy" — status

Run 1 final.md (recency audit sekce, řádek 62) cituje: *"Cline auto-approve always-on + YOLO mode (2026)"* s odkazem na community CC5 controversy. Přes vyhledávání na HN, GitHub discussions, GitHub issues — konkrétní thread nebo incident označovaný jako "CC5 controversy" nebyl nalezen. **Hypotéza:** Run 1 agent mohl zkomprimovat "Cline's per-step approval model jako friction point v komunitě" do zkratky "CC5 controversy" bez existujícího konkrétního thread ID. Eventuálně "CC5" = "Claude Code 5" release, kde community diskutovala srovnání Cline vs Claude Code native subagents — ale toto není verifikovatelné z dostupných zdrojů. **Disclosed jako unverified.**

---

## Dimenze 5 — Stateful vs stateless agent design

**Cline session je stateful within conversation; stateless across conversations.**

V rámci jedné konverzace (task):
- LLM drží celý conversation history (všechny tool calls + results + user messages)
- Stav projektu (otevřené soubory, terminal output, checkpoint) je udržován v extension state
- Fixer vidí předchozí pokusy v rámci jednoho ticketu — kontext se akumuluje

Mezi konverzacemi:
- Nová konverzace = čistý kontext, žádná memory o předchozích tasks
- **Memory Bank pattern** (viz Dimenze 3) řeší tento cross-session memory gap file-based persistencí

**Srovnání s ceos-agents:** ceos-agents je stateless per-dispatch — fixer dostane čistý kontext s explicitně předanými informacemi (state.json, relevant files). Cline je stateful per-session — fixer akumuluje context organicky. Trade-off: ceos-agents má prediktabilní token cost per agent, Cline's context může narůstat neomezeně v dlouhých sessions.

**Praktický dopad:** Cline's stateful model umožňuje agent "zapamatovat si" předchozí pokusy bez explicitního state management. ceos-agents musí explicitně přečíst state.json, předchozí diff, atd. — ale za cenu srozumitelnosti a auditability.

---

## Dimenze 6 — Lessons learned (primární sekce)

### 6.1 Modular component-prompt composition — HLAVNÍ DELIVERABLE

Run 1 citoval `agent_role.ts:15` jako příklad thin (15-line) agent role definition. K 2026-04-26 je realita komplexnější a architektonicky zajímavější:

**Cline prošel kompletní refaktorizací systém promptu** ze single-file `system.ts` na modulární systém v `src/core/prompts/system-prompt/`. Nová architektura:

#### 6.1.1 Komponenty — kompletní file-by-file breakdown

**`agent_role.ts`** (`src/core/prompts/system-prompt/components/agent_role.ts`, 675 bytes):
```typescript
const AGENT_ROLE = [
    "You are Cline,",
    "a highly skilled software engineer",
    "with extensive knowledge in many programming languages, frameworks, design patterns, and best practices.",
]

export async function getAgentRoleSection(variant, context): Promise<string> {
    const template = variant.componentOverrides?.[SystemPromptSection.AGENT_ROLE]?.template || AGENT_ROLE.join(" ")
    return new TemplateEngine().resolve(template, context, {})
}
```

Obsah = 3 string literals, joinované do jedné věty (~40 slov). Toto je "15 lines" z Run 1 — ale **skutečný výstup funkce je 1 věta**, ne 15 řádků. Kód je 15 řádků, prompt output je minimalistický.

**`objective.ts`** (`src/core/prompts/system-prompt/components/objective.ts`, 3182 bytes):
- Sekce `OBJECTIVE` s 6 numbered steps
- Popis jak iterativně pracovat (analyze → prioritize → work through sequentially → verify → attempt_completion → accept feedback)
- Context-conditional: krok 3 a step 4 se mění dle `context.yoloModeToggled` — v YOLO mode přeskočí "ask user for missing parameters"
- Template override: `variant.componentOverrides?.[SystemPromptSection.OBJECTIVE]?.template`

**`rules.ts`** (`src/core/prompts/system-prompt/components/rules.ts`, 11515 bytes — největší komponenta):
- Sekce `RULES` s ~25 bullet points
- Environment-conditional placeholders: `{{BROWSER_RULES}}` (jen pokud `context.supportsBrowserUse`), `{{CLI_RULES}}` (jen pokud `context.isCliEnvironment`), `{{BROWSER_WAIT_RULES}}`
- YOLO-conditional: pravidlo pro `ask_followup_question` se mění dle `context.yoloModeToggled`
- Template override: `variant.componentOverrides?.[SystemPromptSection.RULES]?.template`

**`capabilities.ts`** (`src/core/prompts/system-prompt/components/capabilities.ts`, 6253 bytes):
- Sekce `CAPABILITIES` popisující dostupné tools
- Context-conditional placeholders: `{{BROWSER_SUPPORT}}` (jen s browser), `{{BROWSER_CAPABILITIES}}`, `{{WEB_TOOLS_CAPABILITIES}}` (jen pokud `context.providerInfo.providerId === "cline"` AND `context.clineWebToolsEnabled`)
- Template override: `variant.componentOverrides?.[SystemPromptSection.CAPABILITIES]?.template`

**`mcp.ts`** (`src/core/prompts/system-prompt/components/mcp.ts`, 3867 bytes):
- **Podmínečná komponenta** — vrací `undefined` pokud nejsou žádné MCP servery: `if (servers.length === 0) { return undefined }`
- Pokud servery existují, generuje `MCP SERVERS` sekci s tool schemas, resources, templates a prompts per server
- Template override: `variant.componentOverrides?.[SystemPromptSection.MCP]?.template`
- Utility: `hasEnabledMcpServers(context): boolean` — exported pro use v jiných komponentách

**`user_instructions.ts`** (`src/core/prompts/system-prompt/components/user_instructions.ts`, 2622 bytes):
- **Podmínečná komponenta** — vrací `undefined` pokud žádné custom instructions
- Agreguje: `globalClineRulesFileInstructions`, `localClineRulesFileInstructions`, `localCursorRulesFileInstructions`, `localCursorRulesDirInstructions`, `localWindsurfRulesFileInstructions`, `localAgentsRulesFileInstructions`, `clineIgnoreInstructions`, `preferredLanguageInstructions`
- Sekce `USER'S CUSTOM INSTRUCTIONS` s `{{CUSTOM_INSTRUCTIONS}}` placeholder

**Ostatní komponenty** (menší):
- `system_info.ts` — OS, shell, home directory, IDE info
- `skills.ts` — Skills sekce (pokud jsou skills v context)
- `task_progress.ts` — TODO/task progress tracking
- `feedback.ts` — Feedback handling
- `act_vs_plan_mode.ts` — Plan vs Act mode instructions
- `editing_files.ts` — File editing specifics (replace_in_file usage)
- `tool_use/` (directory) — Tool use instructions per tool

#### 6.1.2 Composition mechanism — `PromptBuilder.build()`

`src/core/prompts/system-prompt/registry/PromptBuilder.ts`:

```typescript
async build(): Promise<string> {
    const componentSections = await this.buildComponents()
    const placeholderValues = this.preparePlaceholders(componentSections)
    const prompt = this.templateEngine.resolve(this.variant.baseTemplate, this.context, placeholderValues)
    return this.postProcess(prompt)
}

private async buildComponents(): Promise<Record<string, string>> {
    const sections: Record<string, string> = {}
    const { componentOrder } = this.variant
    // Process components sequentially to maintain order
    for (const componentId of componentOrder) {
        const result = await componentFn(this.variant, this.context)
        if (result?.trim()) {
            sections[componentId] = result  // undefined-returning components jsou SKIPPED
        }
    }
    return sections
}
```

Klíčové vlastnosti:
- **Sequential processing** zachovává order
- **undefined = skip** — podmínečné komponenty (MCP, USER_INSTRUCTIONS, SKILLS) jsou automaticky vynechány
- **baseTemplate** s placeholders určuje finální layout — komponenty jsou vloženy do template placeholders

#### 6.1.3 Composition order — `components/index.ts:getSystemPromptComponents()`

```typescript
export function getSystemPromptComponents() {
    return [
        { id: SystemPromptSection.AGENT_ROLE,          fn: getAgentRoleSection },
        { id: SystemPromptSection.SYSTEM_INFO,          fn: getSystemInfo },
        { id: SystemPromptSection.MCP,                  fn: getMcp },              // CONDITIONAL
        { id: SystemPromptSection.USER_INSTRUCTIONS,    fn: getUserInstructions }, // CONDITIONAL
        { id: SystemPromptSection.TOOL_USE,             fn: getToolUseSection },
        { id: SystemPromptSection.EDITING_FILES,        fn: getEditingFilesSection },
        { id: SystemPromptSection.CAPABILITIES,         fn: getCapabilitiesSection },
        { id: SystemPromptSection.SKILLS,               fn: getSkillsSection },    // CONDITIONAL
        { id: SystemPromptSection.RULES,                fn: getRulesSection },
        { id: SystemPromptSection.OBJECTIVE,            fn: getObjectiveSection },
        { id: SystemPromptSection.ACT_VS_PLAN,          fn: getActVsPlanModeSection },
        { id: SystemPromptSection.FEEDBACK,             fn: getFeedbackSection },
        { id: SystemPromptSection.TASK_PROGRESS,        fn: getUpdatingTaskProgress },
    ]
}
```

**13 komponent v defaultním pořadí.** MCP, USER_INSTRUCTIONS a SKILLS jsou podmínečné (vracejí `undefined` pokud conext neobsahuje relevantní data).

#### 6.1.4 Variant system — `PromptRegistry` + `PromptVariant`

`PromptVariant` interface (`types.ts`) definuje:
- `componentOrder: readonly SystemPromptSection[]` — každý variant může mít jiné pořadí
- `componentOverrides: Partial<Record<SystemPromptSection, ConfigOverride>>` — každý variant může mít jiný template per component
- `matcher: (context) => boolean` — automatický výběr variantu dle modelu/providera

`PromptRegistry` (singleton) při startu extension:
1. Načte všechny varianty z `variants/` directory
2. Zaregistruje komponenty z `getSystemPromptComponents()`
3. Na request: `getVariant(context)` → `PromptBuilder(variant, context, components)` → `build()`

#### 6.1.5 Modular component tabulka — přehled 5 primárních komponent

| Soubor | Velikost | Obsah | Podmínečný | Override hook | Composition order |
|--------|----------|-------|------------|---------------|-------------------|
| `agent_role.ts` | 675 B | 1 věta identity ("You are Cline…") | Ne | `componentOverrides[AGENT_ROLE]` | 1. (první) |
| `objective.ts` | 3182 B | 6-step task methodology; YOLO-conditional text | Ne | `componentOverrides[OBJECTIVE]` | 10. |
| `rules.ts` | 11515 B | ~25 operational rules; browser/CLI conditional blocks | Ne | `componentOverrides[RULES]` | 9. |
| `capabilities.ts` | 6253 B | Tool catalog + browser/web-tools conditional | Ne | `componentOverrides[CAPABILITIES]` | 7. |
| `mcp.ts` | 3867 B | MCP servers list; returns `undefined` if no servers | **Ano** | `componentOverrides[MCP]` | 3. |
| `user_instructions.ts` | 2622 B | .clinerules + Cursor/Windsurf/AGENTS.md merge | **Ano** | `componentOverrides[USER_INSTRUCTIONS]` | 4. |

### 6.2 Per-step HITL UX trade-offs — lessons learned

Cline je **longest-running empirical test** per-step approval architecture v production SWE agent kontextu (2024-07 → 2026-04 = 21 měsíců). Lessons:

1. **Per-step approval je viable founding UX** — 61k★ a 3.7M installs potvrzují, že "your permission every step" byl atraktivní diferenciátor oproti early autonomous agents (AutoGPT, Devin early version). Uživatelé chtěli kontrolu.

2. **Approval fatigue je reálný problém při ~5 měsících** — v3.0.0 jako "most requested feature" v prosinci 2024 přišel po červenci 2024 launch. ~5 měsíců do první signifikantní HITL relaxace.

3. **Granularity je klíčová** — uživatelé nechtěli vypnout approval úplně, chtěli kategorické kontroly. Auto Approve menu s 8 kategoriemi je výsledkem iterace na user feedback. Binární on/off nebyl dostatečný.

4. **YOLO jako escape hatch, ne default** — YOLO mode existuje ale není default. Cline maintains per-step-by-default posture s YOLO jako opt-in. GitHub description 2026-04-26 stále zdůrazňuje "your permission every step of the way".

5. **CLI jako primary YOLO channel** — YOLO mode je pro CLI (headless/CI) primárně. Pro IDE use je auto-approve kategorizovaný přístup dominantní.

### 6.3 Srovnání s Cursor 3 parallel-prompt model (Q16 kontext)

Cursor 3 (Run 1 citace: April 2026) přidal **worktree parallel-prompt model** — 8 paralelních Claude agents v izolovaných worktrees. Cline zůstává single-agent sequential. Toto je architektonická propast:

| Dimenze | Cline | Cursor 3 |
|---------|-------|----------|
| Paralelismus | Single agent loop | 8 parallel agents |
| HITL | Per-step + Auto Approve + YOLO | Per-agent review (less clear) |
| Statefulness | Stateful per session | Isolated per worktree |
| IDE integrace | VSCode extension (JS/TS) | Native Cursor IDE |
| Stars (2026-04) | 61k | N/A (proprietary) |

Cursor parallel model je architektonicky blíže ceos-agents fixer↔reviewer loop, ale v IDE kontextu. Cline single-agent loop je blíže hypothetické "single-generalist fixer" variantě pro A.1 brainstorm.

---

## Dimenze 7 — Co lze přenést do markdown-only Claude Code plugin

Toto je **primární otázka pro sub-projekt A**.

### 7.1 Modular component-prompt composition jako precedent

Cline's `getSystemPromptComponents()` pattern je přímý precedent pro ceos-agents v8.0.0 potenciální architectural change:

**Současný ceos-agents přístup:** monolithic agent file (`agents/fixer.md` = 117 řádků). Vše v jednom: Role, Goal, Expertise, Process, Constraints.

**Cline-inspired modular přístup:** rozbitím agent definition na komponenty:
- `agents/fixer/agent_role.md` — 2-3 věty identity
- `agents/fixer/rules.md` — NEVER constraints
- `agents/fixer/capabilities.md` — dostupné tools a jak je používat
- `agents/fixer/process.md` — numbered process steps
- `agents/shared/security.md` — shared prompt-injection constraint

**Runtime composition v Agent Overrides:** místo append-to-prompt, project-specific `customization/fixer.md` by mohl selektivně override konkrétní sekci (jen rules, nebo jen process) bez nutnosti duplikovat celý agent file.

**Cline source citation:** `PromptVariant.componentOverrides: Partial<Record<SystemPromptSection, ConfigOverride>>` (`types.ts`) + `variant.componentOverrides?.[SystemPromptSection.RULES]?.template` pattern v každém komponentu.

**Limitace pro markdown-only plugin:** Cline implementuje composition v TypeScript runtime. ceos-agents nemá runtime — kompozice by musela být provedena buď (a) Claude Code Task tool call na assembly agent, nebo (b) konvencí v Agent Overrides dokumentaci (human-readable description jak komponenty skládat). Žádný automatický runtime assembly není možný v pure markdown plugin.

### 7.2 Conditional component inclusion

Cline's pattern: MCP sekce je SKIPPED pokud nejsou MCP servers. User instructions jsou SKIPPED pokud nejsou .clinerules. Toto je přímý analog pro ceos-agents:

- `acceptance-gate` v fixer←→reviewer loop: SKIP pokud complexity < M AND AC < 3 (již implementováno v ceos-agents)
- `reproducer` agent: SKIP pokud není reproduction_steps v triage output (implicitní v ceos-agents workflow)
- `browser-verifier` agent: SKIP pokud Browser Verification config není přítomna

Cline's conditional pattern je tedy **architektonicky konzistentní s existujícím ceos-agents skipping mechanikem** — validace current approach, nikoli inspiration pro change.

### 7.3 Customization hierarchy (global → project → conditional)

Cline: `preferredLanguage → globalClineRules → localClineRules → localCursorRules → localWindsurfRules → clineIgnore` (merge pořadí v `user_instructions.ts`).

ceos-agents může adoptovat analogickou hierarchii pro Agent Overrides:
- Level 1: Plugin default agent definition
- Level 2: User global overrides (`~/.claude/customization/fixer.md`)
- Level 3: Project-local overrides (`customization/fixer.md`)
- Level 4: Per-task runtime context (explicitně předaný v dispatch)

Toto by bylo rozšíření current single-level Agent Overrides na multi-level hierarchii.

### 7.4 HITL pattern transfer

Cline's HITL evolution timeline je **blueprint pro ceos-agents sub-projekt B decision**:

- **Start conservative** (per-step) → **evolve granular** (kategorie) → **provide escape hatch** (YOLO/autopilot)
- ceos-agents již má tento arc: defaultní pipeline s human gates (publish = PR ne direct push) → Pipeline Profiles (skip stages) → `/autopilot` s `Dry run: true`
- Cline's "8 kategorií" model je inspirací pro ceos-agents granulární auto-approve: "vždy auto-approve triage, auto-approve code-analyst, vyžaduj gate před publisher"

---

## Dimenze 8 — Co je framework-specific (nelze přenést)

### 8.1 VSCode Extension runtime

Cline = TypeScript VSCode extension. Veškerá logika běží v VS Code extension host procesu. Runtime composition, PromptRegistry singleton, `context.supportsBrowserUse`, `context.isCliEnvironment` — to vše závisí na VS Code API. **Nepřenositelné do markdown plugin.**

### 8.2 Multi-provider model abstraction

Cline je vendor-agnostic — podporuje Anthropic, OpenAI, Gemini, Bedrock, Vertex, OpenRouter, Ollama, xAI a desítky dalších. `PromptVariant.matcher(context)` vybírá prompt variant dle providera a modelu. **Nepřenositelné** — ceos-agents je Claude Code plugin, provider = Anthropic only.

### 8.3 Plan/Act mode

Plan mode vs Act mode je VS Code extension feature — Claude Code plugin v ceos-agents nemá ekvivalent. Nejbližší analog je ceos-agents fixer mode (NEEDS_DECOMPOSITION signaling), ale mechanismus je fundamentálně jiný.

### 8.4 .clinerules conditional glob patterns

YAML frontmatter v `.clinerules/` s `paths:` glob patterns — context-aware rule activation. Claude Code plugin nemá ekvivalentní runtime pro glob matching. Agent Overrides jsou statické append-to-prompt.

### 8.5 Memory Bank jako native feature

Cline Memory Bank má native slash command support (`/newtask`, `/smol`). ceos-agents by mohl inspirovat se konvencí (strukturované markdown files), ale native integration by vyžadovala Claude Code-level changes.

---

## Adoption metrics (verifikováno 2026-04-26)

| Metrika | Hodnota | Zdroj |
|---------|---------|-------|
| GitHub stars | 61,019 | GitHub API, 2026-04-26 |
| GitHub forks | 6,283 | GitHub API, 2026-04-26 |
| VSCode Marketplace installs | 3,738,518 | VS Code Marketplace, 2026-04-26 |
| VSCode Marketplace rating | 4/5 (283 ratings) | VS Code Marketplace, 2026-04-26 |
| Aktuální verze | v3.81.0 | GitHub release, 2026-04-24 |
| Repozitář vytvořen | 2024-07-06 | GitHub API |
| Open issues | 714 | GitHub API, 2026-04-26 |
| License | Apache 2.0 | GitHub |

**Poznámka:** Run 1 final.md citoval "61.0k★, 1M+ VSCode installs" — stars jsou přesně 61,019, ale VSCode installs jsou **3.7M, ne 1M+**. Run 1 data pravděpodobně pocházela ze staršího zdroje nebo undercount.

---

## Komparativní osa: Cline vs ceos-agents

| Dimenze | Cline | ceos-agents |
|---------|-------|-------------|
| Agent count | 1 (single loop) | 21 specialized |
| Pipeline | Emergent (LLM-decided) | Hardcoded markdown |
| Customization | .clinerules (markdown) + YAML frontmatter | Agent Overrides (append) + Profiles + Hooks |
| HITL default | Per-step approval | Gate before publisher (PR creation) |
| HITL escape | Auto Approve (8 categories) + YOLO | Autopilot + `--yolo` |
| Statefulness | Stateful per session | Stateless per dispatch |
| Cross-session memory | Memory Bank (file-based) | state.json + pipeline-history.md |
| Runtime | TypeScript + VSCode extension host | Pure markdown (no runtime) |
| Prompt architecture | Modular (13+ components, registry, variants) | Monolithic per-agent markdown |
| Platform | Multi-provider | Claude Code / Anthropic only |
| Stars (2026-04) | 61,019 | N/A (sub-plugin) |

---

## Klíčová zjištění pro Q22 cross-run synthesis

1. **Modular component-prompt composition** je v Cline source kódu verifikovaná production praxe. 13 komponent, registry pattern, conditional inclusion, variant system s per-component overrides. Toto je **nejkonkrétnější OSS-code precedent** pro potenciální ceos-agents v8.0.0 "decompose agent.md into component overlay files".

2. **HITL evolution arc** (per-step → granular categories → escape hatch) je 21měsíční empirický test. Klíčový finding: uživatelé chtěli kategorické kontroly, ne binary on/off. Friction byl real (5 měsíců do "most requested feature"). **Per-step default + granular categories + YOLO escape je validated UX pattern**.

3. **Single-agent vs 21 specialists** — Cline's 61k★ + 3.7M installs při single-agent architektuře je contra-evidence pro "more agents = better". Ale task type bifurcation (Run 1 Q2) stále platí: Cline řeší open-ended user requests, ceos-agents řeší deterministic CI pipeline — different task type → different optimal architecture.

4. **"CC5 controversy"** z Run 1 se nepodařilo verifikovat jako konkrétní incident. Closest equivalent: v3.0.0 release note "most requested feature" + user feedback na per-step approval fatigue over 5 měsíců. Disclosed jako unverified.

5. **Přenositelná architektonická inspirace:** component-based prompt decomposition (Dimenze 7.1) + multi-level override hierarchy (Dimenze 7.3) jsou dva konkrétní patterns relevantní pro A.1 brainstorm — oboje jsou **compatible s markdown-only constraint** ceos-agents.
