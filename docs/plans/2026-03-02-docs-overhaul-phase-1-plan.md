# Phase 1: Translation (CZ → EN) — Implementation Plan

**Phase:** 1 of 4 (Documentation Overhaul)
**Scope:** Translate all Czech content to English across ~54 files
**Risk:** HIGH (regex parsers, checkpoint markers, cross-references)
**Version target:** 3.2.0 (part of Documentation Overhaul release)
**Design doc:** `docs/plans/2026-03-01-documentation-overhaul-design.md`

## Prerequisites

1. **Backup:** Create a git tag `pre-phase-1` on current `main` before starting, so rollback is trivial.
2. **No open branches:** Ensure no in-flight fix/feature branches depend on Czech block template patterns.
3. **Consuming projects:** User must re-run `/CLAUDE-agents:onboard` on consuming projects after Phase 1 lands — old Czech block comments in issue trackers will no longer be parsed by updated regexes.
4. **Single atomic commit:** All changes in Phase 1 MUST land in a single commit. Partial translation (e.g., agents translated but commands still Czech) would break regex parsing because agents would emit English fields while commands still parse Czech patterns.

## Translation Order

The order matters because of data flow dependencies:

1. **CLAUDE.md** — Canonical definition of Block Comment Template and checkpoint markers. All agents and commands reference this. Must be updated first so subsequent files can reference the correct English patterns.
2. **Agents** — They GENERATE block comments and checkpoint markers. If agents emit English fields but commands still parse Czech, the pipeline breaks. Agents must be updated before commands.
3. **Commands** — They PARSE block comments and checkpoint markers via regex. Commands must be updated AFTER agents so the regex patterns match what agents now emit.
4. **Tests** — They ASSERT on patterns. Must match what agents and commands now produce.
5. **Other files** — Examples, configs, CHANGELOG, CONTRIBUTING, setup docs. These are consumed by humans, not by regex parsers, so order is less critical.

**CRITICAL CONSTRAINT:** Groups 1-3 must be deployed atomically. There is no safe partial state.

## Critical Artifacts

### Block Comment Template

**OLD (Czech):**
```
[CLAUDE-agents] 🔴 Pipeline Block
Agent: {agent name}
Krok: {pipeline step}
Důvod: {max 2 sentences}
Detail: {technical output}
Doporučení: {what human should do}
```

**NEW (English):**
```
[CLAUDE-agents] 🔴 Pipeline Block
Agent: {agent name}
Step: {pipeline step}
Reason: {max 2 sentences}
Detail: {technical output}
Recommendation: {what human should do}
```

Field mapping:
- `Agent:` stays `Agent:` (already English)
- `Krok:` → `Step:`
- `Důvod:` → `Reason:`
- `Detail:` stays `Detail:` (already English)
- `Doporučení:` → `Recommendation:`

### Checkpoint Markers

**Triage checkpoint:**
- OLD: `[CLAUDE-agents] Triage dokončen. Severity: {severity}. Area: {area}.`
- NEW: `[CLAUDE-agents] Triage completed. Severity: {severity}. Area: {area}.`

**Spec checkpoint:**
- OLD: `[CLAUDE-agents] Spec analýza dokončena. Oblast: {area}. Kritéria: {count}.`
- NEW: `[CLAUDE-agents] Spec analysis completed. Area: {area}. Criteria: {count}.`

### Regex Parsers

These are the EXACT patterns that must change simultaneously in the three parser files.

#### `commands/dashboard.md` (lines 38-48)

**OLD (line 38-39):**
```
Regex: `^\[CLAUDE-agents\] Triage dokončen\. Severity: (.+)\. Area: (.+)\.$`
→ Extrahuj severity, area
```

**NEW:**
```
Regex: `^\[CLAUDE-agents\] Triage completed\. Severity: (.+)\. Area: (.+)\.$`
→ Extract severity, area
```

**OLD (line 42-43):**
```
Regex: `^\[CLAUDE-agents\] Spec analýza dokončena\. Oblast: (.+)\. Kritéria: (.+)\.$`
→ Extrahuj area, criteria count
```

**NEW:**
```
Regex: `^\[CLAUDE-agents\] Spec analysis completed\. Area: (.+)\. Criteria: (.+)\.$`
→ Extract area, criteria count
```

**OLD (line 47):**
```
Následující řádky: `Agent: (.+)`, `Krok: (.+)`, `Důvod: (.+)`, `Detail: (.+)`, `Doporučení: (.+)`
→ Extrahuj agent, step, reason, detail, recommendation
```

**NEW:**
```
Following lines: `Agent: (.+)`, `Step: (.+)`, `Reason: (.+)`, `Detail: (.+)`, `Recommendation: (.+)`
→ Extract agent, step, reason, detail, recommendation
```

**OLD (line 51):**
```
- "Triage dokončen" nebo "Spec analysis complete" → analysis
```

**NEW:**
```
- "Triage completed" or "Spec analysis completed" → analysis
```

#### `commands/metrics.md` (lines 35-59)

**OLD (line 36):**
```
Regex: `^\[CLAUDE-agents\] Triage dokončen\. Severity: (.+)\. Area: (.+)\.$`
```

**NEW:**
```
Regex: `^\[CLAUDE-agents\] Triage completed\. Severity: (.+)\. Area: (.+)\.$`
```

**OLD (line 39):**
```
Regex: `^\[CLAUDE-agents\] Spec analýza dokončena\. Oblast: (.+)\. Kritéria: (.+)\.$`
```

**NEW:**
```
Regex: `^\[CLAUDE-agents\] Spec analysis completed\. Area: (.+)\. Criteria: (.+)\.$`
```

**OLD (line 42):**
```
Následující řádky: `Agent: (.+)`, `Krok: (.+)`, `Důvod: (.+)`, `Detail: (.+)`, `Doporučení: (.+)`
```

**NEW:**
```
Following lines: `Agent: (.+)`, `Step: (.+)`, `Reason: (.+)`, `Detail: (.+)`, `Recommendation: (.+)`
```

**OLD (line 59):**
```
- `top_block_reasons` = top 5 nejčastějších "Důvod:" z block komentářů
```

**NEW:**
```
- `top_block_reasons` = top 5 most frequent "Reason:" values from block comments
```

#### `commands/resume-ticket.md` (lines 18, 57-58)

**OLD (line 18):**
```
| `POST_TRIAGE` | Existuje komentář `[CLAUDE-agents] Triage dokončen.` | Triage |
```

**NEW:**
```
| `POST_TRIAGE` | Comment `[CLAUDE-agents] Triage completed.` exists | Triage |
```

**OLD (line 57-58):**
```
   - Pokud existuje komentář `[CLAUDE-agents] Spec analýza dokončena.` → FEATURE pipeline (použij kroky jako `/implement-feature`)
   - Pokud existuje komentář `[CLAUDE-agents] Triage dokončen.` → BUG pipeline (použij kroky jako `/fix-ticket`)
```

**NEW:**
```
   - If comment `[CLAUDE-agents] Spec analysis completed.` exists → FEATURE pipeline (use steps from `/implement-feature`)
   - If comment `[CLAUDE-agents] Triage completed.` exists → BUG pipeline (use steps from `/fix-ticket`)
```

## Steps

### Group 1: CLAUDE.md (Canonical Definition)

#### Step 1.1: CLAUDE.md — Block Comment Template and checkpoint markers

**File:** `CLAUDE.md`

**Changes:**

1. **Lines 145-151 — Block Comment Template:**
   - `Agent: {název agenta}` → `Agent: {agent name}`
   - `Krok: {krok pipeline kde selhalo}` → `Step: {pipeline step where failure occurred}`
   - `Důvod: {max 2 věty}` → `Reason: {max 2 sentences}`
   - `Detail: {technický output — chybová hláška, diff, test output}` → `Detail: {technical output — error message, diff, test output}`
   - `Doporučení: {co by měl člověk udělat}` → `Recommendation: {what the human should do}`

2. **Line 156 — Triage checkpoint:**
   - `[CLAUDE-agents] Triage dokončen. Severity: {severity}. Area: {area}.` → `[CLAUDE-agents] Triage completed. Severity: {severity}. Area: {area}.`

3. **Line 123 — Pipeline Profiles key listing:**
   - `Profil` → `Profile` (column header in Pipeline Profiles table). Note: cosmetic change — commands parse by section name and row position, not by column header text.

4. **Line 161 — Czech explanatory note (remove entirely):**
   - OLD: `> Pole šablony (Krok, Důvod, Detail, Doporučení) jsou záměrně v češtině — slouží jako interní identifikátory pro machine parsing.`
   - NEW: (delete this line — it is no longer applicable since fields are now English)

**Risk:** HIGH — this is the canonical definition. Every agent and command references this. Must be correct.

---

### Group 2: Agents (13 files)

All 11 agents with Block Comment Template need the Czech field names translated. 2 agents (scaffolder, stack-selector) have no block template. Additionally, 2 agents have checkpoint markers, and 1 agent has Czech filler text in block template fields.

#### Step 2.1: `agents/triage-analyst.md`

**Changes:**

1. **Lines 46-47 — Triage checkpoint comment:**
   - `[CLAUDE-agents] Triage dokončen. Severity: {severity}. Area: {area}.` → `[CLAUDE-agents] Triage completed. Severity: {severity}. Area: {area}.`

2. **Lines 56-60 — Block Comment Template:**
   - `Krok: Triage` → `Step: Triage`
   - `Důvod: {max 2 věty — co je špatně}` → `Reason: {max 2 sentences — what is wrong}`
   - `Detail: {co konkrétně chybí nebo je nejasné}` → `Detail: {what specifically is missing or unclear}`
   - `Doporučení: {co by měl autor issue udělat}` → `Recommendation: {what the issue author should do}`

**Risk:** HIGH — triage-analyst generates the checkpoint comment that resume-ticket, dashboard, and metrics parse.

#### Step 2.2: `agents/spec-analyst.md`

**Changes:**

1. **Line 54 — Spec checkpoint comment:**
   - `[CLAUDE-agents] Spec analýza dokončena. Oblast: {area}. Kritéria: {count}.` → `[CLAUDE-agents] Spec analysis completed. Area: {area}. Criteria: {count}.`

2. **Lines 66-71 — Block Comment Template:**
   - `Krok: Spec Analysis` → `Step: Spec Analysis`
   - `Důvod: {reason}` → `Reason: {reason}`
   - `Detail: {what is missing or unclear}` → `Detail: {what is missing or unclear}` (already English)
   - `Doporučení: {what the author should add to the issue}` → `Recommendation: {what the author should add to the issue}`

**Risk:** HIGH — spec-analyst generates the spec checkpoint that resume-ticket, dashboard, and metrics parse.

#### Step 2.3: `agents/code-analyst.md`

**Changes:**

Lines 59-63 — Block Comment Template:
- `Krok: Impact Analysis` → `Step: Impact Analysis`
- `Důvod: {reason}` → `Reason: {reason}`
- `Detail: {what was found so far}` → `Detail: {what was found so far}` (already English)
- `Doporučení: {what the human should investigate}` → `Recommendation: {what the human should investigate}`

**Risk:** LOW — no regex parsers depend on code-analyst block comments specifically.

#### Step 2.4: `agents/fixer.md`

**Changes:**

Lines 71-76 — Block Comment Template:
- `Krok: Fix Implementation` → `Step: Fix Implementation`
- `Důvod: {reason}` → `Reason: {reason}`
- `Detail: {technical output — build error, approach that failed}` → `Detail: {technical output — build error, approach that failed}` (already English)
- `Doporučení: {what the human should do}` → `Recommendation: {what the human should do}`

**Risk:** LOW.

#### Step 2.5: `agents/reviewer.md`

**Changes:**

Lines 68-73 — Block Comment Template:
- `Krok: Code Review` → `Step: Code Review`
- `Důvod: {reason}` → `Reason: {reason}`
- `Detail: {unresolved critical issues}` → `Detail: {unresolved critical issues}` (already English)
- `Doporučení: {what the human should review}` → `Recommendation: {what the human should review}`

**Risk:** LOW.

#### Step 2.6: `agents/test-engineer.md`

**Changes:**

Lines 52-58 — Block Comment Template:
- `Krok: Test Writing` → `Step: Test Writing`
- `Důvod: {reason}` → `Reason: {reason}`
- `Detail: {test output, failure message}` → `Detail: {test output, failure message}` (already English)
- `Doporučení: {what the human should check}` → `Recommendation: {what the human should check}`

**Risk:** LOW.

#### Step 2.7: `agents/e2e-test-engineer.md`

**Changes:**

Lines 61-66 — Block Comment Template:
- `Krok: E2E Test Writing` → `Step: E2E Test Writing`
- `Důvod: {reason}` → `Reason: {reason}`
- `Detail: {test output, failure message}` → `Detail: {test output, failure message}` (already English)
- `Doporučení: {what the human should check}` → `Recommendation: {what the human should check}`

**Risk:** LOW.

#### Step 2.8: `agents/publisher.md`

**Changes:**

Lines 87-93 — Block Comment Template:
- `Krok: Publish` → `Step: Publish`
- `Důvod: {reason}` → `Reason: {reason}`
- `Detail: {technical output — git error, API error}` → `Detail: {technical output — git error, API error}` (already English)
- `Doporučení: {what the human should do}` → `Recommendation: {what the human should do}`

**Risk:** LOW.

#### Step 2.9: `agents/rollback-agent.md`

**Changes:**

Lines 62-67 — Block Comment Template (in Process Step 5):
- `Krok: {the pipeline step where failure occurred}` → `Step: {the pipeline step where failure occurred}`
- `Důvod: {failure reason}` → `Reason: {failure reason}`
- `Detail: {technical output — error message, test output, diff}` → `Detail: {technical output — error message, test output, diff}` (already English)
- `Doporučení: {what the human should do}` → `Recommendation: {what the human should do}`

**Risk:** LOW.

#### Step 2.10: `agents/architect.md`

**Changes:**

Lines 90-95 — Block Comment Template:
- `Krok: Architecture Design` → `Step: Architecture Design`
- `Důvod: {reason}` → `Reason: {reason}`
- `Detail: {what was analyzed, what went wrong}` → `Detail: {what was analyzed, what went wrong}` (already English)
- `Doporučení: {what the human should do — e.g., split the issue, clarify requirements}` → `Recommendation: {what the human should do — e.g., split the issue, clarify requirements}`

**Risk:** LOW.

#### Step 2.11: `agents/priority-engine.md`

**Changes:**

Lines 70-76 — Block Comment Template:
- `Krok: Backlog Prioritization` → `Step: Backlog Prioritization`
- `Důvod: {max 2 věty}` → `Reason: {max 2 sentences}`
- `Detail: {co bylo analyzováno}` → `Detail: {what was analyzed}`
- `Doporučení: {co by měl člověk udělat}` → `Recommendation: {what the human should do}`

**Risk:** LOW. Note: priority-engine is the only agent besides triage-analyst that has Czech filler text inside the block template fields (not just field names).

#### Step 2.12: `agents/scaffolder.md` — NO CHANGES

Scaffolder explicitly does not use the Block Comment Template (line 97). No Czech content in this file.

#### Step 2.13: `agents/stack-selector.md` — NO CHANGES

Stack-selector explicitly does not use the Block Comment Template (line 64). No Czech content in this file.

---

### Group 3: Commands (22 files)

Every command file has Czech frontmatter descriptions and Czech prose. Translation is full-file for all 22 commands. Below, each step lists the specific Czech content categories for each file.

**Common patterns across all command files:**
- `description:` in YAML frontmatter — translate CZ → EN
- `## Kroky` → `## Steps`
- `## Pravidla` → `## Rules`
- `## Konfigurace` → `## Configuration`
- `## Orchestrace` → `## Orchestration`
- `Pokud ...` → `If ...`
- `Spusť ...` → `Run ...`
- `Zobraz ...` → `Display ...`
- `Přečti ...` → `Read ...`
- `Ověř ...` → `Verify ...`
- `Kontext:` → `Context:`
- `Selhání →` → `Failure →`
- `Žádné změny` → `No changes`

#### Step 3.1: `commands/analyze-bug.md`

**Frontmatter:** `Analyzuje konkrétní bug z issue trackeru (jen analýza, žádné změny kódu)` → `Analyzes a specific bug from the issue tracker (analysis only, no code changes)`

**Body (lines 7-19):** Full Czech prose. Key translations:
- `Analyzuj bug $ARGUMENTS. Čti Automation Config z CLAUDE.md.` → `Analyze bug $ARGUMENTS. Read Automation Config from CLAUDE.md.`
- `## Kroky` → `## Steps`
- `Pokud $ARGUMENTS je prázdný → oznam:` → `If $ARGUMENTS is empty → report:`
- `Ověř, že CLAUDE.md existuje a obsahuje sekci` → `Verify that CLAUDE.md exists and contains section`
- `Po úspěšném triage instrukuj agenta, aby postl checkpoint komentář` → `After successful triage, instruct the agent to post checkpoint comment`
- Checkpoint text: `[CLAUDE-agents] Triage dokončen.` → `[CLAUDE-agents] Triage completed.`
- `Pokud triage OK → spusť` → `If triage OK → run`
- `Zobraz výsledky (triage + impact report)` → `Display results (triage + impact report)`
- `Žádné změny kódu, žádné issue tracker state changes. Jen analýza.` → `No code changes, no issue tracker state changes. Analysis only.`

**Risk:** MEDIUM — contains checkpoint text literal.

#### Step 3.2: `commands/changelog.md`

**Frontmatter:** `Automatické generování changelogu z merged PR` → `Automatic changelog generation from merged PRs`

**Body (lines 7-63):** Full Czech prose. Key translations:
- `Vygeneruj changelog z merged PR od posledního git tagu. Zapiš do CHANGELOG.md.` → `Generate changelog from merged PRs since last git tag. Write to CHANGELOG.md.`
- `## Kroky` → `## Steps`
- `Čti Automation Config z CLAUDE.md:` → `Read Automation Config from CLAUDE.md:`
- `Pokud Automation Config chybí, použij` → `If Automation Config is missing, use`
- `Najdi poslední git tag:` → `Find the last git tag:`
- `Pokud žádný tag neexistuje → použij celou historii` → `If no tag exists → use full history`
- `Získej merged commity od tagu:` → `Get merged commits since tag:`
- `Pokud --merges nevrátí výsledky` → `If --merges returns no results`
- `Pro každý merge commit: zjisti PR číslo` → `For each merge commit: get PR number`
- `Kategorizuj dle Conventional Commits prefixů:` → `Categorize by Conventional Commits prefixes:`
- `Nové funkce` → `New Features` (in template)
- `Opravy` → `Fixes` (in template)
- `Interní` → `Internal` (in template)
- `Ostatní změny` → `Other Changes` (in template)
- `Vygeneruj changelog sekci` → `Generate changelog section`
- `Zapiš do CHANGELOG.md:` → `Write to CHANGELOG.md:`
- `Pokud soubor neexistuje → vytvoř` → `If file does not exist → create`
- `Pokud existuje → vlož novou sekci` → `If file exists → insert new section`
- `Zobraz výsledek:` → `Display result:`
- `Changelog aktualizován: {počet} změn ve verzi {verze}` → `Changelog updated: {count} changes in version {version}`
- `## Pravidla` → `## Rules`
- `Formát: Keep a Changelog (česky)` → `Format: Keep a Changelog (English)`
- `PR bez Conventional Commits prefixu → sekce "Ostatní změny"` → `PRs without Conventional Commits prefix → "Other Changes" section`
- `Prázdné kategorie nezobrazuj` → `Do not display empty categories`

**Risk:** LOW.

#### Step 3.3: `commands/check-setup.md`

**Frontmatter:** `Validace Automation Config, MCP serverů a tokenů` → `Validate Automation Config, MCP servers, and tokens`

**Body (lines 7-149):** Full Czech prose. Extensive content. Key translations:
- `Zkontroluj konfiguraci projektu pro CLAUDE-agents pipeline.` → `Check project configuration for CLAUDE-agents pipeline.`
- `Report: co funguje, co chybí, co selhalo.` → `Report: what works, what is missing, what failed.`
- `## Kroky` → `## Steps`
- `### Blok 1: Automation Config (strukturální kontrola)` → `### Block 1: Automation Config (structural check)`
- `Přečti CLAUDE.md aktuálního projektu` → `Read the current project's CLAUDE.md`
- `Ověř existenci` → `Verify existence`
- `Ověř povinné sekce a klíče:` → `Verify required sections and keys:`
- `Sekce` → `Section`, `Povinné klíče` → `Required keys`
- `### 3a. Per-tracker validace` → `### 3a. Per-tracker validation`
- `Na základě Type z Issue Tracker proveď tracker-specifické kontroly:` → `Based on Type from Issue Tracker, perform tracker-specific checks:`
- All `ověř` → `verify`, `hledej` → `search for`, `formát` → `format`
- `Pro neznámý Type →` → `For unknown Type →`
- `Pro každý klíč: ověř, že hodnota existuje a NENÍ placeholder` → `For each key: verify that value exists and is NOT a placeholder`
- `Přítomný a vyplněný →` → `Present and filled →`
- `Prázdný nebo placeholder →` → `Empty or placeholder →`
- `Ověř volitelné sekce (pokud existují, zkontroluj formát):` → `Verify optional sections (if present, check format):`
- `Existuje a správný formát →` → `Exists and correct format →`
- `Neexistuje →` → `Does not exist →`
- `Existuje ale špatný formát →` → `Exists but wrong format →`
- `### Blok 2: MCP servery (přítomnost a konektivita)` → `### Block 2: MCP servers (presence and connectivity)`
- `Přečti .mcp.json` → `Read .mcp.json`
- `Porovnej MCP servery s Automation Config:` → `Compare MCP servers with Automation Config:`
- `### Blok 3: Konektivita` → `### Block 3: Connectivity`
- `Spusť Bug query` → `Run Bug query`
- `Úspěch →` → `Success →`
- `Auth error →` → `Auth error →` (keep)
- `Timeout →` → `Timeout →` (keep)
- `autentizace selhala` → `authentication failed`
- `server nedostupný` → `server unreachable`
- `### Blok 4: Build & Test (volitelné)` → `### Block 4: Build & Test (optional)`
- `## Formát výstupu` → `## Output format`
- All output labels: translate Czech report text
- `## Automation Config nalezeno` → `## Automation Config found`
- `všechny klíče vyplněny` → `all keys filled`
- `sekce chybí (volitelné)` → `section missing (optional)`
- `Test command je prázdný` → `Test command is empty`
- `nakonfigurován` → `configured`
- `nenalezen pro remote` → `not found for remote`
- `připojení OK, projekt {PROJECT} nalezen, X bugů` → `connection OK, project {PROJECT} found, X bugs`
- `autentizace selhala` → `authentication failed`
- `Přeskočeno` → `Skipped`
- `Výsledek:` → `Result:`
- `Konfigurace je kompletní. Pipeline je připravena.` → `Configuration is complete. Pipeline is ready.`
- `Pipeline NELZE spustit. Oprav výše uvedené chyby.` → `Pipeline CANNOT run. Fix the errors listed above.`
- `### Blok 5: Plugin Composability` → `### Block 5: Plugin Composability`
- `Zkontroluj nainstalované pluginy:` → `Check installed plugins:`
- `Hledej plugin registry:` → `Search for plugin registry:`
- `Pokud nalezen: přečti seznam` → `If found: read the list`
- `Pro každý plugin: zkontroluj` → `For each plugin: check`
- `Pokud conflict →` → `If conflict →`
- `Pokud žádné konflikty →` → `If no conflicts →`
- `## Pravidla` → `## Rules`
- `Read-only — nikdy nezapisuj do CLAUDE.md ani issue trackeru` → `Read-only — never write to CLAUDE.md or issue tracker`
- `Konektivita: pouze čtecí MCP dotazy` → `Connectivity: read-only MCP queries`
- `Placeholder detekce: vzor <...> v hodnotách = FAIL` → `Placeholder detection: pattern <...> in values = FAIL`
- `Bezpečný pro opakované spouštění` → `Safe for repeated execution`

**Risk:** LOW (no regex parsers, but very large file).

#### Step 3.4: `commands/create-pr.md`

**Frontmatter:** `Vytvoří PR pro aktuální branch` → `Creates a PR for the current branch`

**Body (lines 7-18):** Czech prose. Key translations:
- `> **Pozn.:**` → `> **Note:**`
- `create-pr je lightweight varianta — vytvoří PR přímo bez publisher agenta. Pro plný pipeline (PR + issue tracker update) použij /publish.` → `create-pr is a lightweight variant — creates a PR directly without the publisher agent. For the full pipeline (PR + issue tracker update) use /publish.`
- `Vytvoř PR pro aktuální branch. Čti Automation Config z CLAUDE.md (PR Rules, labels, base branch).` → `Create a PR for the current branch. Read Automation Config from CLAUDE.md (PR Rules, labels, base branch).`
- `## Kroky` → `## Steps`
- `Zjisti aktuální branch` → `Get current branch`
- `Zjisti issue ID z názvu branche` → `Get issue ID from branch name`
- `Commit + push pokud jsou uncommitted changes` → `Commit + push if there are uncommitted changes`
- `Vytvoř PR dle PR Rules` → `Create PR per PR Rules`
- `Pokud template neexistuje, použij výchozí formát` → `If template does not exist, use default format`
- `Zobraz PR URL` → `Display PR URL`

**Risk:** LOW.

#### Step 3.5: `commands/dashboard.md` — CRITICAL (regex parsers)

**Frontmatter:** `Vygeneruje HTML dashboard se stavem pipeline — issues, blocked, statistiky` → `Generates an HTML dashboard with pipeline state — issues, blocked, statistics`

**Body (lines 7-151):** Full Czech prose with CRITICAL regex patterns. Key translations:

**Regex patterns (MUST be exact):**
- Line 38: `Triage dokončen` → `Triage completed`; `Extrahuj` → `Extract`
- Line 42-43: `Spec analýza dokončena\. Oblast:` → `Spec analysis completed\. Area:`; `Kritéria:` → `Criteria:`; `Extrahuj area, criteria count` → `Extract area, criteria count`
- Line 47: `Krok: (.+)` → `Step: (.+)`; `Důvod: (.+)` → `Reason: (.+)`; `Doporučení: (.+)` → `Recommendation: (.+)`; `Extrahuj agent, step, reason, detail, recommendation` → `Extract agent, step, reason, detail, recommendation`
- Line 51: `"Triage dokončen" nebo "Spec analysis complete"` → `"Triage completed" or "Spec analysis completed"`

**Other Czech content:**
- All section headers: `## Parsování flagů` → `## Flag parsing`; `## Konfigurace` → `## Configuration`; `## Orchestrace` → `## Orchestration`
- `Načti z CLAUDE.md cílového projektu:` → `Read from the target project's CLAUDE.md:`
- `Volitelně:` → `Optional:`
- `### 1. Fetch issues` — `Přes MCP server (dle Issue Tracker → Type):` → `Via MCP server (per Issue Tracker → Type):`
- `Načti všechny issues matching` → `Fetch all issues matching`
- `Pro každý issue: ID, title, state, comments` → `For each issue: ID, title, state, comments`
- `Filtruj dle` → `Filter by`
- `### 2. Parse [CLAUDE-agents] komentáře` → `### 2. Parse [CLAUDE-agents] comments`
- `Pro každý issue projdi komentáře a najdi` → `For each issue, scan comments and find`
- `Pipeline stage odvození:` → `Pipeline stage inference:`
- All `Block od` → `Block from`
- `PR link v komentáři →` → `PR link in comment →`
- `Žádný [CLAUDE-agents] komentář →` → `No [CLAUDE-agents] comment →`
- `Filtruj dle --stage pokud zadán.` → `Filter by --stage if provided.`
- `### 3. Fetch PR data` — `Přes source control MCP:` → `Via source control MCP:`
- `Pro každý issue najdi branch` → `For each issue find branch`
- `Pro každou branch najdi PR` → `For each branch find PR`
- `Extrahuj: PR URL, PR number, merge stav` → `Extract: PR URL, PR number, merge status`
- `### 4. Compute statistics` — `z block komentářů` → `from block comments`
- `### 5. Generate timeline` — `Seřaď všechny` → `Sort all`; `Posledních 20 eventů` → `Last 20 events`
- `Pro každý event:` → `For each event:`; `stručný popis` → `brief description`; `pokud starší než dnes` → `if older than today`
- `### 6. Generate recommendations` — `Threshold-based pravidla:` → `Threshold-based rules:`; `Průměrný čas roste` → `Average time increasing`
- `### 7. Generate HTML` — `Vygeneruj self-contained HTML soubor` → `Generate a self-contained HTML file`; all `struktura`, `Responsivní`, `Barvy`, etc.
- `### 8. Write HTML file` (no Czech)
- `### 9. Report` (no Czech)
- `> CSS a HTML struktura jsou inline — dashboard je self-contained statický soubor.` → `> CSS and HTML structure are inline — dashboard is a self-contained static file.`
- `## Pravidla` → `## Rules`
- `Dashboard je READ-ONLY operace — žádné změny v issue trackeru ani gitu` → `Dashboard is a READ-ONLY operation — no changes to issue tracker or git`
- `HTML musí být self-contained — žádné externí CSS/JS/font dependencies` → `HTML must be self-contained — no external CSS/JS/font dependencies`
- `Všechna data se čtou přes MCP servery — žádné přímé API volání` → `All data is read via MCP servers — no direct API calls`
- `Pokud MCP server není dostupný → report error, nezobrazuj prázdný dashboard` → `If MCP server is unavailable → report error, do not display empty dashboard`
- `Výstup vždy v angličtině (konzistentní s agenty a pipeline komentáři)` → `Output always in English (consistent with agents and pipeline comments)`

**Risk:** HIGH — contains 3 regex patterns and 2 checkpoint literal matches that MUST match the new English format.

#### Step 3.6: `commands/estimate.md`

**Frontmatter:** `Odhadne spotřebu tokenů a cenu před spuštěním pipeline` → `Estimates token usage and cost before running pipeline`

**Body (lines 7-102):** Full Czech prose. Key translations:
- All section headers, `Konfigurace`, `Orchestrace`, flag parsing, etc.
- `Načti z CLAUDE.md` → `Read from CLAUDE.md`
- `Přes MCP server` → `Via MCP server`
- `Na základě issue description, Grep pro relevantní keywords v codebase. Spočítej:` → `Based on issue description, Grep for relevant keywords in codebase. Count:`
- `Pokud --profile → aplikuj` → `If --profile → apply`
- `Jinak full pipeline` → `Otherwise full pipeline`
- `Iteration multiplier` (already English)
- `Pokud metrics data dostupná → mention` → `If metrics data available → mention`
- `## Pravidla` → `## Rules`
- `Read-only — žádné side effects` → `Read-only — no side effects`
- `Pokud issue neexistuje → error:` → `If issue does not exist → error:`

**Risk:** LOW.

#### Step 3.7: `commands/fix-bugs.md` — CRITICAL (block template in Block handler)

**Frontmatter:** `Automaticky opraví N bugů z issue trackeru` → `Automatically fixes N bugs from the issue tracker`

**Body (lines 7-406):** Extensive Czech prose. This is the largest command file. Key translations:

**Block handler (lines 274-310) — Block Comment Template:**
- Line 279: `Agent: {název}. Krok: {krok}. Důvod: {důvod}. Detail: {output}. Doporučení: {doporučení}. Kontext spuštění:` → `Agent: {name}. Step: {step}. Reason: {reason}. Detail: {output}. Recommendation: {recommendation}. Execution context:`
- Lines 291-297: Block template:
  - `Krok: {pipeline step}` → `Step: {pipeline step}`
  - `Důvod: {max 2 věty}` → `Reason: {max 2 sentences}`
  - `Doporučení: {what human should do}` → `Recommendation: {what human should do}`

**Summary table (line 249):**
- `Blokující důvod` → `Block reason`

**Summary text (line 255):**
- `opraveno, {N_blocked} zablokováno, {N_dup} duplicit` → `fixed, {N_blocked} blocked, {N_dup} duplicates`

**Token estimate (lines 257-263):**
- `Odhadovaná spotřeba:` → `Estimated usage:`
- `Odhadovaná cena:` → `Estimated cost:`
- `Odhad je orientační — skutečné náklady mohou být` → `Estimate is approximate — actual costs may be`

**Dry-run report (lines 359-398):**
- Table headers: `Est. Složitost` → `Est. Complexity`
- `### Souhrn` → `### Summary`
- `Připraveno k fixu:` → `Ready for fix:`
- `Duplicity:` → `Duplicates:`
- `Nejasné / k dořešení:` → `Unclear / to resolve:`
- `### Odhadovaná složitost` → `### Estimated complexity`; `Stupeň | Popis | Počet` → `Level | Description | Count`
- `řádků` → `lines`, `soubor` → `file`, `soubory` → `files`, `souborů` → `files`
- `### Odhad zdrojů` → `### Resource estimate`
- `Odhadovaná doba pipeline:` → `Estimated pipeline duration:`
- `Odhadovaná spotřeba tokenů:` → `Estimated token usage:`
- `Přesnost ±30 %` → `Accuracy ±30%`

**All other Czech prose:** Section headers, configuration descriptions, orchestration steps, worktree management, etc. — full translation required.

**Specific items requiring careful attention:**
- `Parsování pipeline profilu` → `Pipeline profile parsing`
- `Parsování decompose flagu` → `Decompose flag parsing`
- `Omezení: NIKDY neskipuj fixer, reviewer, publisher — tyto stages jsou povinné.` → `Restriction: NEVER skip fixer, reviewer, publisher — these stages are mandatory.`
- `Max blocked per run ({N}) dosažen. Zbývajících {M} bugů přeskočeno.` → `Max blocked per run ({N}) reached. Remaining {M} bugs skipped.`

**Risk:** HIGH — contains Block Comment Template in block handler that must match new English field names.

#### Step 3.8: `commands/fix-ticket.md` — CRITICAL (block template in Block handler)

**Frontmatter:** `Analyzuje a opraví jeden konkrétní ticket (v CWD, bez worktree)` → `Analyzes and fixes a specific ticket (in CWD, no worktree)`

**Body (lines 7-327):** Extensive Czech prose. Same patterns as fix-bugs.md.

**Block handler (lines 270-300) — Block Comment Template:**
- Line 275: `Agent: {název}. Krok: {krok}. Důvod: {důvod}. Detail: {output}. Doporučení: {doporučení}. Kontext spuštění: CWD (bez worktree).` → `Agent: {name}. Step: {step}. Reason: {reason}. Detail: {output}. Recommendation: {recommendation}. Execution context: CWD (no worktree).`
- Lines 287-293: Block template same as fix-bugs

**Dry-run report (lines 302-317):**
- `Est. složitost` → `Est. complexity`
- `Žádné změny provedeny. Pro spuštění opravy zadej` → `No changes made. To run the fix, enter`

**Token estimate (lines 239-245):**
- Same as fix-bugs token estimate

**All section headers, orchestration steps, etc.:** Full translation required (same patterns as fix-bugs).

**Risk:** HIGH — contains Block Comment Template in block handler.

#### Step 3.9: `commands/implement-feature.md` — CRITICAL (block template in Block handler)

**Frontmatter:** `Implementuje feature z issue trackeru — spec → design → fix → review → test → publish` → `Implements a feature from the issue tracker — spec → design → fix → review → test → publish`

**Body (lines 7-278):** Full Czech prose. Key translations:

**Block handler (lines 249-269) — Block Comment Template:**
- Lines 259-265: same block template translation as fix-bugs/fix-ticket

**Other key items:**
- `## Parsování flagů` → `## Flag parsing`
- `## Parsování pipeline profilu` → `## Pipeline profile parsing`
- `Omezení: NIKDY neskipuj: fixer, reviewer, publisher.` → `Restriction: NEVER skip: fixer, reviewer, publisher.`
- `### 5. Decomposition decision` — `Zobraz plán:` → `Display plan:`
- `Závisí na` → `Depends on`
- `Strategie: sekvenční | Celkem: ~N řádků` → `Strategy: sequential | Total: ~N lines`
- `Pokračovat? [A/n]` → `Continue? [Y/n]`
- `Čekej na potvrzení. Pokud uživatel odmítne → zastaň.` → `Wait for confirmation. If user declines → stop.`
- `### 9. Zobraz výsledek` → `### 9. Display result`
- `Shrnutí změn` → `Summary of changes`
- `Vytvořit PR? [A/n]` → `Create PR? [Y/n]`

**Risk:** HIGH — contains Block Comment Template in block handler.

#### Step 3.10: `commands/metrics.md` — CRITICAL (regex parsers)

**Frontmatter:** Already in English: `Generuje pipeline analytics report — success rate, per-agent effectiveness, failure patterns`

**Body (lines 7-125):** Czech prose with CRITICAL regex patterns. Key translations:

**Regex patterns (lines 35-42):** See "Regex Parsers" section above for exact old → new.

**Other Czech content:**
- `## Parsování flagů` → `## Flag parsing`
- `## Konfigurace` → `## Configuration`
- `Načti z CLAUDE.md` → `Read from CLAUDE.md`
- `Volitelně:` → `Optional:`
- `## Orchestrace` → `## Orchestration`
- `Přes MCP server` → `Via MCP server`
- `Pro každý issue projdi komentáře. Extrahuj:` → `For each issue, scan comments. Extract:`
- `Následující řádky:` → `Following lines:`
- `nejčastějších "Důvod:" z block komentářů` → `most frequent "Reason:" values from block comments`
- `Pro každý agent ... count blocks, success rate, nejčastější důvod selhání` → `For each agent ... count blocks, success rate, most frequent failure reason`
- `z reviewer komentářů (kolik REQUEST_CHANGES před APPROVE)` → `from reviewer comments (how many REQUEST_CHANGES before APPROVE)`
- `pokud agent blokuje > 30% issues → flag pattern s top důvodem` → `if agent blocks > 30% issues → flag pattern with top reason`
- Report template (lines 80-81): `| Metrika | Hodnota |` → `| Metric | Value |` (already has this in English report format)
- `## Pravidla` → `## Rules`
- All rule items translated

**Risk:** HIGH — contains regex patterns.

#### Step 3.11: `commands/migrate-config.md`

**Frontmatter:** `Detekuje verzi Automation Config a navrhne upgrade na aktuální` → `Detects Automation Config version and suggests upgrade to current`

**Body (lines 7-77):** Czech prose. Key translations:
- `Migrace Automation Config na aktuální verzi (v3.1).` → `Migrate Automation Config to current version (v3.1).`
- `## Konfigurace` → `## Configuration`
- `Přečti CLAUDE.md cílového projektu, najdi` → `Read the target project's CLAUDE.md, find`
- `## Orchestrace` → `## Orchestration`
- `### 1. Detect config version` — `> **Pozn.:**` → `> **Note:**`
- `Detekce verze je heuristická — pokud byl config manuálně upraven` → `Version detection is heuristic — if config was manually modified`
- `wizard zobrazí detekovanou verzi a uživatel může potvrdit nebo opravit` → `wizard shows the detected version and user can confirm or correct`
- `Na základě přítomnosti sekcí:` → `Based on presence of sections:`
- `### 2. Identify missing optional sections` — `Porovnej s aktuální specifikací v3.1:` → `Compare with current v3.1 specification:`
- `Pro každou optional sekci:` → `For each optional section:`
- `Existuje →` → `Exists →`; `Neexistuje →` → `Does not exist →`; `nabídni přidání` → `offer to add`
- `### 3. Check for deprecated patterns` — `Bullet-point formát místo tabulkového → nabídni konverzi` → `Bullet-point format instead of table → offer conversion`
- `Chybějící Type v Issue Tracker (pre-v1.6) → nabídni přidání` → `Missing Type in Issue Tracker (pre-v1.6) → offer to add`
- `### 5. Apply changes` — `Po uživatelově schválení:` → `After user approval:`
- `## Pravidla` → `## Rules`
- `Vždy čekej na potvrzení před zápisem` → `Always wait for confirmation before writing`
- `Nikdy neodstraňuj existující sekce` → `Never remove existing sections`
- `Nové sekce přidávej NA KONEC Automation Config bloku` → `Add new sections AT THE END of the Automation Config block`
- `Pokud CLAUDE.md nemá ## Automation Config → error:` → `If CLAUDE.md has no ## Automation Config → error:`

**Risk:** LOW.

#### Step 3.12: `commands/onboard.md`

**Frontmatter:** `Interaktivní průvodce pro vygenerování Automation Config` → `Interactive wizard for generating Automation Config`

**Body (lines 7-98):** Full Czech prose. Key translations:
- `Interaktivní průvodce, který shromáždí parametry a vygeneruje ## Automation Config blok.` → `Interactive wizard that collects parameters and generates the ## Automation Config block.`
- `## Kroky` → `## Steps`
- `Nabídni template jako starting point:` → `Offer a template as starting point:`
- `"Chceš začít od template? ..."` → `"Would you like to start from a template? I have pre-built configurations for popular stacks."`
- `Pokud ano →` → `If yes →`
- `Pokud vybere template →` → `If user selects a template →`
- `Pokud ne → pokračuj klasickým průvodcem` → `If no → continue with the standard wizard`
- `Přivítej uživatele:` → `Welcome the user:`
- `"Nastavím Automation Config pro tvůj projekt. Postupně se zeptám na všechny parametry."` → `"I'll set up Automation Config for your project. I'll ask about all parameters step by step."`
- `**Issue Tracker** — zeptej se postupně:` → `**Issue Tracker** — ask step by step:`
- `Jaký issue tracker používáš?` → `Which issue tracker do you use?`
- `URL instance:` → `Instance URL:`
- `Název projektu / project key:` → `Project name / project key:`
- `Query pro otevřené bugy — nabídni default dle trackeru:` → `Query for open bugs — offer default per tracker:`
- `State transitions — nabídni defaulty dle trackeru:` → `State transitions — offer defaults per tracker:`
- Steps 3-6: all `zeptej se`, `Chceš nastavit {sekci}?`, etc.
- `**Vygeneruj Automation Config** blok ze shromážděných odpovědí` → `**Generate Automation Config** block from collected answers`
- `**Nabídni výstup:**` → `**Offer output:**`
- `**Možnost 1 (default):** Vypiš blok do chatu — uživatel zkopíruje sám` → `**Option 1 (default):** Print block to chat — user copies manually`
- `**Možnost 2:** Zapiš přímo do CLAUDE.md` → `**Option 2:** Write directly to CLAUDE.md`
- `Pokud ## Automation Config již existuje → varuj a nabídni přepis nebo zrušení` → `If ## Automation Config already exists → warn and offer overwrite or cancel`
- `Pokud neexistuje → připoj na konec CLAUDE.md` → `If does not exist → append to end of CLAUDE.md`
- `## Pravidla` → `## Rules`
- `Nevaliduj odpovědi — validace patří do /check-setup` → `Do not validate answers — validation belongs in /check-setup`
- `Nabízej defaulty, ale uživatel je může změnit` → `Offer defaults, but user can change them`
- `Volitelné sekce přeskakuj, pokud uživatel řekne ne` → `Skip optional sections if user says no`
- `Výstup vždy v tabulkovém formátu (| Klíč | Hodnota |)` → `Output always in table format (| Key | Value |)`
- `Na konci průvodce zmíň:` → `At the end of the wizard, mention:`
- `"Plugin CLAUDE-agents používá sémantické verzování (semver). Detaily viz Versioning Policy v CLAUDE.md pluginu."` → `"The CLAUDE-agents plugin uses semantic versioning (semver). See Versioning Policy in the plugin's CLAUDE.md for details."`

**Risk:** LOW.

#### Step 3.13: `commands/prioritize.md`

**Frontmatter:** `Analyzuje backlog a navrhne pořadí fixů pomocí AI prioritizace` → `Analyzes backlog and suggests fix order using AI prioritization`

**Body (lines 7-43):** Czech prose. Key translations:
- `## Konfigurace` → `## Configuration`
- `Načti z CLAUDE.md` → `Read from CLAUDE.md`
- `Volitelně:` → `Optional:`
- `## Orchestrace` → `## Orchestration`
- `### 1. Fetch issues` — `Přes MCP server` → `Via MCP server`
- `### 2. Enrich with history` — `Pokud metrics report existuje` → `If metrics report exists`; `přečti per-area failure patterns` → `read per-area failure patterns`
- `### 3. Spusť priority-engine` → `### 3. Run priority-engine`
- `Pokud priority-engine selže nebo vrátí chybu, zobraz:` → `If priority-engine fails or returns an error, display:`
- `"Prioritization failed: {důvod}"` → `"Prioritization failed: {reason}"`
- `### 4. Output` — `Zobraz výsledek agenta. Pokud --output specifikován → zapiš do souboru.` → `Display agent result. If --output specified → write to file.`
- `## Pravidla` → `## Rules`

**Risk:** LOW.

#### Step 3.14: `commands/publish.md`

**Frontmatter:** `Vytvoří PR a přepne stavy v issue trackeru` → `Creates a PR and updates issue tracker states`

**Body (lines 7-28):** Czech prose. Key translations:
- `Publikuj aktuální práci: PR + issue tracker state change. Čti Automation Config z CLAUDE.md.` → `Publish current work: PR + issue tracker state change. Read Automation Config from CLAUDE.md.`
- `## Kroky` → `## Steps`
- `Zjisti aktuální branch a issue ID` → `Get current branch and issue ID`
- `Ověř, že aktuální branch má commity` → `Verify that current branch has commits`
- `Pokud nemá → oznam: "Žádné změny k publishu — branch nemá commity nad {base_branch}." a ukonči.` → `If not → report: "No changes to publish — branch has no commits above {base_branch}." and stop.`
- `Zkontroluj, zda pro aktuální branch již existuje otevřený PR. Pokud ano → zobraz: "PR již existuje: {PR URL}." a ukonči.` → `Check if an open PR already exists for the current branch. If yes → display: "PR already exists: {PR URL}." and stop.`
- `Přečti Type` → `Read Type`
- `Issue tracker: nastav stav` → `Issue tracker: set state`
- `Komentář v issue trackeru s PR linkem` → `Comment in issue tracker with PR link`
- `Selhání → varování, nesmí zastavit publish.` → `Failure → warning, must not stop publish.`
- `Zobraz výsledek (PR URL + issue tracker stav)` → `Display result (PR URL + issue tracker state)`

**Risk:** LOW.

#### Step 3.15: `commands/resume-ticket.md` — CRITICAL (literal checkpoint matching)

**Frontmatter:** `Obnoví pipeline z místa selhání bez re-analýzy` → `Resumes pipeline from failure point without re-analysis`

**Body (lines 7-91):** Full Czech prose with CRITICAL literal matches. Key translations:

**Checkpoint detection table (lines 14-22):**
- All `Signál` → `Signal`, `Přeskočí` → `Skips`
- Line 18: `Existuje komentář [CLAUDE-agents] Triage dokončen.` → `Comment [CLAUDE-agents] Triage completed. exists`
- Line 19: `Existuje branch (dle branch naming z config) + triage komentář` → `Branch exists (per branch naming from config) + triage comment`
- Line 20: `Branch s commity nad base branch` → `Branch with commits above base branch`
- Line 21: `Branch + reviewer approval komentář` → `Branch + reviewer approval comment`
- Line 22: `Existuje otevřené PR pro branch` → `Open PR exists for branch`
- `Žádná branch, žádné komentáře` → `No branch, no comments`
- `Celá pipeline — jen zobraz stav` → `Entire pipeline — just display status`
- `Triage + analysis + hotové subtasky` → `Triage + analysis + completed subtasks`

**Detection logic (lines 24-33):** Pseudocode, mostly English. No changes needed except comments.

**Pipeline type detection (lines 56-59) — CRITICAL literals:**
- Line 57: `[CLAUDE-agents] Spec analýza dokončena.` → `[CLAUDE-agents] Spec analysis completed.`
- Line 58: `[CLAUDE-agents] Triage dokončen.` → `[CLAUDE-agents] Triage completed.`
- `→ FEATURE pipeline (použij kroky jako /implement-feature)` → `→ FEATURE pipeline (use steps from /implement-feature)`
- `→ BUG pipeline (použij kroky jako /fix-ticket)` → `→ BUG pipeline (use steps from /fix-ticket)`
- `Pokud ani jedno → BUG pipeline (default)` → `If neither → BUG pipeline (default)`

**All other Czech prose:** Steps, rules, checkpoint descriptions, etc. — full translation.

**Risk:** HIGH — contains literal checkpoint strings that must match what agents now emit.

#### Step 3.16: `commands/scaffold.md`

**Frontmatter:** `Vytvoří nový projekt od nuly — tech stack → skeleton → validace → git init` → `Creates a new project from scratch — tech stack → skeleton → validation → git init`

**Body (lines 7-118):** Czech prose. Key translations:
- `## Parsování flagů` → `## Flag parsing`
- `předvolená` → `preset`
- `Zbytek po odstranění flagů = project description (přirozený jazyk)` → `Remainder after removing flags = project description (natural language)`
- `## Detekce stavu` → `## State detection`
- `Před zahájením zkontroluj cílový adresář:` → `Before starting, check the target directory:`
- `Prázdný adresář (nebo neexistuje) → plný scaffold` → `Empty directory (or does not exist) → full scaffold`
- `Existující projekt bez CLAUDE.md → nabídni:` → `Existing project without CLAUDE.md → offer:`
- `"Projekt existuje ale nemá CLAUDE.md. Chcete /scaffold-add claude-md?"` → `"Project exists but has no CLAUDE.md. Would you like /scaffold-add claude-md?"`
- `"Projekt už má Automation Config. Chcete /implement-feature?"` → `"Project already has Automation Config. Would you like /implement-feature?"`
- `Existující git repo s uncommitted changes → varuj:` → `Existing git repo with uncommitted changes → warn:`
- `"Uncommitted changes. Commitněte nebo stashněte."` → `"Uncommitted changes. Commit or stash them."`
- `Pokud stav ≠ 1 a uživatel nepotvrdí → zastaň.` → `If state ≠ 1 and user does not confirm → stop.`
- `## Orchestrace` → `## Orchestration`
- Steps 1-6: all Czech prose
- `Vytvoř temp adresář:` → `Create temp directory:`
- `### 3. Validace` → `### 3. Validation`
- `Spusť validaci v temp adresáři` → `Run validation in temp directory`
- `Pokud jakýkoliv check selhává:` → `If any check fails:`
- `Předej error output zpět scaffolderovi` → `Pass error output back to scaffolder`
- `Scaffolder opraví (max 3 retries)` → `Scaffolder fixes (max 3 retries)`
- `Pokud 3× fail → smaž temp, report chybu, zastaň` → `If 3x fail → delete temp, report error, stop`
- `### 4. Přesun do cílového adresáře` → `### 4. Move to target directory`
- `Pokud $SCAFFOLD_TEMP je prázdný nebo neobsahuje /tmp` → `If $SCAFFOLD_TEMP is empty or does not contain /tmp`
- `NESPOUŠTĚJ rm -rf — oznam chybu` → `DO NOT run rm -rf — report error`
- `## Pravidla` → `## Rules`
- All rules translated
- `Vždy generuj do temp adresáře` → `Always generate to temp directory`
- `Nikdy nepřepisuj existující soubory bez potvrzení` → `Never overwrite existing files without confirmation`
- `Pokud uživatel neposkytl project description → zeptej se` → `If user did not provide project description → ask`

**Risk:** LOW.

#### Step 3.17: `commands/scaffold-add.md`

**Frontmatter:** `Přidá komponentu do existujícího projektu (claude-md, ci, docker, tests)` → `Adds a component to an existing project (claude-md, ci, docker, tests)`

**Body (lines 7-69):** Czech prose. Key translations:
- `## Podporované komponenty` → `## Supported components`
- `Komponenta | Co generuje | Agent` → `Component | What it generates | Agent`
- All orchestration steps, detection, confirmation, validation, report, rules translated.
- `Detekuj existující tech stack z project souborů:` → `Detect existing tech stack from project files:`
- `Pokud nelze detekovat → zeptej se uživatele.` → `If unable to detect → ask the user.`
- `Detekuj framework z importů a dependencies:` → `Detect framework from imports and dependencies:`
- `Zobraz: "Detekován stack: ... Generuji {component}. Pokračovat? [A/n]"` → `Display: "Detected stack: ... Generating {component}. Continue? [Y/n]"`
- `## Pravidla` → `## Rules`
- `Nikdy nepřepisuj existující soubory bez potvrzení` → `Never overwrite existing files without confirmation`
- `Pro claude-md: pokud CLAUDE.md už existuje → zeptej se jestli přepsat nebo mergovat` → `For claude-md: if CLAUDE.md already exists → ask whether to overwrite or merge`
- `Auto-detect hledá nejdřív v root, pak jeden level subdirectories` → `Auto-detect searches root first, then one level of subdirectories`
- `Pokud multiple matches (mixed-language repo) → zeptej se uživatele na primární stack` → `If multiple matches (mixed-language repo) → ask user for primary stack`

**Risk:** LOW.

#### Step 3.18: `commands/scaffold-validate.md`

**Frontmatter:** `Validuje projekt — build, testy, lint, CLAUDE.md struktura` → `Validates project — build, tests, lint, CLAUDE.md structure`

**Body (lines 7-87):** Czech prose. Key translations:
- All orchestration steps translated
- `## Orchestrace` → `## Orchestration`
- `### 1. Detekce build systému` → `### 1. Build system detection`
- `Hledej package manifest v root adresáři:` → `Search for package manifest in root directory:`
- `Pokud nelze detekovat →` → `If unable to detect →`
- `### 2. Build check` — `Spusť detekovaný build command.` → `Run detected build command.`
- `Pokud CLAUDE.md existuje a má Build & Test → Build: použij ten příkaz` → `If CLAUDE.md exists and has Build & Test → Build: use that command`
- `Jinak: použij auto-detect z kroku 1` → `Otherwise: use auto-detect from step 1`
- Repeat pattern for test check, lint check, CLAUDE.md check, Docker check
- `## Pravidla` → `## Rules`
- `Read-only kromě Docker build (build je idempotentní)` → `Read-only except Docker build (build is idempotent)`
- `Pokud žádný package manifest → report všechny SKIP, ne FAIL` → `If no package manifest → report all SKIP, not FAIL`
- `WARN ≠ FAIL — WARN je informativní, FAIL je blocker` → `WARN ≠ FAIL — WARN is informational, FAIL is a blocker`
- `Docker check vyžaduje Docker daemon — pokud nedostupný, SKIP s poznámkou` → `Docker check requires Docker daemon — if unavailable, SKIP with note`

**Risk:** LOW.

#### Step 3.19: `commands/status.md`

**Frontmatter:** `Přehled rozpracovaných issues — stav pipeline, branch, PR` → `Overview of in-progress issues — pipeline state, branch, PR`

**Body (lines 7-37):** Czech prose. Key translations:
- `Zobraz přehledovou tabulku rozpracovaných issues. Čti Automation Config z CLAUDE.md.` → `Display an overview table of in-progress issues. Read Automation Config from CLAUDE.md.`
- `## Kroky` → `## Steps`
- `Přečti Automation Config` → `Read Automation Config`
- `Přečti Type z Issue Tracker sekce` → `Read Type from Issue Tracker section`
- `Dotáže se issue trackeru (přes MCP server odpovídající Type)` → `Query the issue tracker (via MCP server matching Type)`
- `na issues v aktivních stavech:` → `for issues in active states:`
- `Stavy z Automation Config` → `States from Automation Config`
- Table headers: `Issue | Název | Fáze | Branch | PR` → `Issue | Title | Stage | Branch | PR`
- `Pokud Feature query existuje, přidej i feature issues do přehledu.` → `If Feature query exists, also add feature issues to the overview.`
- `Pod tabulkou zobraz součty:` → `Below the table, display totals:`
- `## Pravidla` → `## Rules`
- `Zobrazuj pouze aktivní issues (ne Done/Closed)` → `Display only active issues (not Done/Closed)`
- `Issues bez branch → zobraz — ve sloupci Branch a PR` → `Issues without a branch → show — in Branch and PR columns`
- `Vždy live data — žádné cachování` → `Always live data — no caching`

**Risk:** LOW.

#### Step 3.20: `commands/template.md`

**Frontmatter:** `Vygeneruje Automation Config template pro zadaný tech stack` → `Generates Automation Config template for a given tech stack`

**Body (lines 7-56):** Czech prose. Key translations:
- `## Orchestrace` → `## Orchestration`
- `### Varianta 1: list` — `Pokud $ARGUMENTS = list:` → `If $ARGUMENTS = list:`
- `Pro každý soubor extrahuj název z # heading` → `For each file, extract name from # heading`
- `Zobraz tabulku:` → `Display table:`
- `### Varianta 2: <stack-name>` — `Pokud $ARGUMENTS = konkrétní název:` → `If $ARGUMENTS = a specific name:`
- `Přečti` → `Read`; `Zobraz obsah` → `Display contents`; `Na konci zobraz:` → `At the end display:`
- `### Error handling` — `Pokud template neexistuje →` → `If template does not exist →`
- `## Pravidla` → `## Rules`
- `Read-only — pouze čte a zobrazuje templates` → `Read-only — only reads and displays templates`
- `Žádné side effects` → `No side effects`

**Risk:** LOW.

#### Step 3.21: `commands/version-bump.md`

**Frontmatter:** `Bumpne verzi v plugin.json a marketplace.json (patch/minor/major)` → `Bumps version in plugin.json and marketplace.json (patch/minor/major)`

**Body (lines 7-33):** Czech prose. Key translations:
- `Bumpni verzi CLAUDE-agents pluginu.` → `Bump the CLAUDE-agents plugin version.`
- `## Argumenty` → `## Arguments`
- `volitelný typ bumpu:` → `optional bump type:`
- `## Kroky` → `## Steps`
- `Ověř, že existuje .claude-plugin/plugin.json` → `Verify that .claude-plugin/plugin.json exists`
- `Pokud neexistuje → oznam chybu:` → `If does not exist → report error:`
- `"Tento command funguje jen v CLAUDE-agents repozitáři."` → `"This command only works in the CLAUDE-agents repository."`
- `Přečti aktuální verzi` → `Read current version`
- `Verze má formát` → `Version has format`
- `Parsuj $ARGUMENTS:` → `Parse $ARGUMENTS:`
- `Pokud je prázdný nebo patch → bumpni PATCH` → `If empty or patch → bump PATCH`
- `Pokud minor → bumpni MINOR a vynuluj PATCH` → `If minor → bump MINOR and reset PATCH`
- `Pokud major → bumpni MAJOR a vynuluj MINOR i PATCH` → `If major → bump MAJOR and reset MINOR and PATCH`
- `Pokud jiná hodnota → oznam chybu:` → `If other value → report error:`
- `"Neplatný argument '$ARGUMENTS'. Použij: patch, minor, major."` → `"Invalid argument '$ARGUMENTS'. Use: patch, minor, major."`
- `Zapiš novou verzi` → `Write new version`
- `Zapiš stejnou verzi` → `Write same version`
- `Commitni změny:` → `Commit changes:`
- `Vytvoř git tag:` → `Create git tag:`
- `Zobraz výsledek: "Verze bumpnuta: ... Tag: ..."` → `Display result: "Version bumped: ... Tag: ..."`
- `**Poznámka:**` → `**Note:**`
- `Tento command bumpne POUZE verzi v plugin metadatech.` → `This command only bumps the version in plugin metadata.`
- `CHANGELOG.md a README.md je potřeba aktualizovat ručně` → `CHANGELOG.md and README.md need to be updated manually`

**Risk:** LOW.

#### Step 3.22: `commands/version-check.md`

**Frontmatter:** `Porovná nainstalovanou verzi pluginu s nejnovější dostupnou` → `Compares installed plugin version with the latest available`

**Body (lines 7-36):** Czech prose. Key translations:
- `> **Pozn.:**` → `> **Note:**`
- `Tento command funguje pouze v CLAUDE-agents repozitáři` → `This command only works in the CLAUDE-agents repository`
- `Zkontroluj, zda je nainstalovaná verze CLAUDE-agents aktuální.` → `Check whether the installed CLAUDE-agents version is up to date.`
- `## Kroky` → `## Steps`
- `Ověř, že existuje` → `Verify that exists`
- `Pokud neexistuje → oznam:` → `If does not exist → report:`
- `Přečti nainstalovanou verzi` → `Read installed version`
- `Zjisti nejnovější dostupnou verzi:` → `Get the latest available version:`
- `Extrahuj verzi z tagu` → `Extract version from tag`
- `Porovnej verze a zobraz výsledek:` → `Compare versions and display result:`
- `**Aktuální:** "... — aktuální verze"` → `**Up to date:** "... — up to date"`
- `**Dostupná aktualizace:** "... — dostupná aktualizace"` → `**Update available:** "... — update available"`
- `**Lokálně novější:** "... — lokální verze je novější než remote"` → `**Locally newer:** "... — local version is newer than remote"`
- `Při selhání sítě (git ls-remote selže): zobraz jen lokální verzi s varováním "Nepodařilo se zjistit remote verzi"` → `On network failure (git ls-remote fails): display only local version with warning "Could not determine remote version"`
- `## Pravidla` → `## Rules`
- `Funguje jen v CLAUDE-agents repozitáři (guard na plugin.json)` → `Only works in the CLAUDE-agents repository (guard on plugin.json)`
- `Vyžaduje SSH klíč nebo HTTPS token pro git ls-remote` → `Requires SSH key or HTTPS token for git ls-remote`
- `Žádné side effects — jen čtení` → `No side effects — read only`

**Risk:** LOW.

---

### Group 4: Tests

#### Step 4.1: `tests/README.md`

**File:** `tests/README.md`

**Changes:** Full translation of entire file. Key items:
- `# Testování CLAUDE-agents` → `# Testing CLAUDE-agents`
- `Test suite pro ověření pipeline logiky. Obsahuje mock MCP server, test runner a 8 automatizovaných scénářů.` → `Test suite for verifying pipeline logic. Contains mock MCP server, test runner, and 8 automated scenarios.`
- `## Struktura` → `## Structure`
- `Mock projekt s Automation Config` → `Mock project with Automation Config`
- `Kompletní Automation Config` → `Complete Automation Config`
- `Python kód se dvěma úmyslnými bugy` → `Python code with two intentional bugs`
- `Testy pro mock kód` → `Tests for mock code`
- `test scénářů (bash skripty)` → `test scenarios (bash scripts)`
- `Celá pipeline end-to-end` → `Full pipeline end-to-end`
- `Triage-analyst detekuje duplicitu → Block` → `Triage-analyst detects duplicate → Block`
- `Fixer vyčerpá retry limit → Block + rollback` → `Fixer exhausts retry limit → Block + rollback`
- `Reviewer zamítne fix → fixer iteruje` → `Reviewer rejects fix → fixer iterates`
- `Test-engineer selhává → Block po limitu` → `Test-engineer fails → Block at limit`
- `Publisher vytvoří PR a aktualizuje tracker` → `Publisher creates PR and updates tracker`
- `Fix Verification selže → issue re-opened` → `Fix Verification fails → issue re-opened`
- `## Mock projekt` → `## Mock project`
- `obsahuje:` → `contains:`
- `kompletní Automation Config se všemi sekcemi` → `complete Automation Config with all sections`
- `testy, které selžou na buggy kódu a projdou po opravě` → `tests that fail on buggy code and pass after fix`
- `## Test scénáře` → `## Test scenarios`
- `Scénář | Soubor | Ověřuje` → `Scenario | File | Verifies`
- `## Spuštění` → `## Running`
- `Všechny scénáře` → `All scenarios`
- `Jeden scénář` → `Single scenario`
- `## Důležité` → `## Important`
- `Testy používají mock MCP server — nevyžadují reálné instance` → `Tests use mock MCP server — no real instances required`
- `Mock MCP vrací předpřipravené responses pro každý scénář` → `Mock MCP returns pre-built responses for each scenario`
- `CI: Gitea Actions workflow spouští testy při push` → `CI: Gitea Actions workflow runs tests on push`

**Risk:** LOW.

#### Step 4.2: `tests/scenarios/profile-skip.sh`

**File:** `tests/scenarios/profile-skip.sh`

**Changes:** This test greps for `Parsování pipeline profilu` and `NIKDY neskipuj`. After translation these become `Pipeline profile parsing` and `NEVER.*skip`. The test already has the English fallback pattern (`NEVER.*skip`), but the Czech pattern needs updating.

Line 11: `grep -q "Parsování pipeline profilu\|--profile"` → `grep -q "Pipeline profile parsing\|--profile"`
Line 18: `grep -q "NIKDY neskipuj\|NEVER.*skip"` → `grep -q "NEVER.*skip"`

**Risk:** MEDIUM — test will fail if Czech patterns are removed from commands but test still looks for them.

#### Step 4.3: `tests/harness/fixtures/issues.json`

**File:** `tests/harness/fixtures/issues.json`

**Changes:** Line 30 contains a triage checkpoint comment in Czech:
- OLD: `"[CLAUDE-agents] Triage dokončen. Severity: HIGH. Area: API."`
- NEW: `"[CLAUDE-agents] Triage completed. Severity: HIGH. Area: API."`

**Risk:** MEDIUM — other tests may assert on this fixture's content.

#### Step 4.4: `tests/mock-project/CLAUDE.md`

**File:** `tests/mock-project/CLAUDE.md`

**Changes:**
- Line 3: `Testovací projekt pro smoke testing CLAUDE-agents pipeline.` → `Test project for smoke testing the CLAUDE-agents pipeline.`
- All table headers `| Klíč | Hodnota |` → `| Key | Value |` (lines 8-9, 19-20, 27-28, 31, 47-48, 53-54, 60-61, 67-68, 74-75, 79-80, 87)
- Line 87: `| Profil |` → `| Profile |` (Pipeline Profiles table header)

**Risk:** LOW — mock project used for smoke testing, no regex parsers.

#### Step 4.5: `tests/harness/fixtures/automation-config.md`

**File:** `tests/harness/fixtures/automation-config.md`

**Changes:**
- All table headers `| Klíč | Hodnota |` → `| Key | Value |` (lines 4, 14, 22, 39)
- Line 46: `| Profil |` → `| Profile |` (Pipeline Profiles table header)

**Risk:** LOW.

---

### Group 5: Examples, Configs, Other

#### Step 5.1: `examples/configs/gitea-spring-boot.md`

**Changes:** All table headers `| Klíč | Hodnota |` → `| Key | Value |` (lines 8, 19, 25, 44)

**Risk:** LOW.

#### Step 5.2: `examples/configs/github-dotnet.md`

**Changes:** All table headers `| Klíč | Hodnota |` → `| Key | Value |` (lines 8, 19, 25, 47)

**Risk:** LOW.

#### Step 5.3: `examples/configs/github-nextjs.md`

**Changes:**
- All table headers `| Klíč | Hodnota |` → `| Key | Value |` (lines 8, 19, 25, 44, and inside the commented-out optional sections: lines 53, 59, 69, 77, 82, 89, 95, 99, 105, 109, 115, 123, 130)
- Line 48: `> **Odkomentuj a uprav volitelné sekce dle potřeby.**` → `> **Uncomment and customize optional sections as needed.**`
- Inside commented-out sections: `| Profil |` → `| Profile |` (line 123)

**Risk:** LOW.

#### Step 5.4: `examples/configs/github-python-fastapi.md`

**Changes:** All table headers `| Klíč | Hodnota |` → `| Key | Value |` (lines 8, 19, 25, 44)

**Risk:** LOW.

#### Step 5.5: `examples/configs/jira-react.md`

**Changes:** All table headers `| Klíč | Hodnota |` → `| Key | Value |` (lines 8, 19, 25, 44)

**Risk:** LOW.

#### Step 5.6: `examples/configs/youtrack-python.md`

**Changes:** All table headers `| Klíč | Hodnota |` → `| Key | Value |` (lines 8, 19, 25, 46)

**Risk:** LOW.

#### Step 5.7: `examples/mcp-configs/gitea.json`

**Changes:** Line 5: `<cesta-k-binárce>` → `<path-to-binary>`

**Risk:** LOW.

#### Step 5.8: `CHANGELOG.md`

**Changes:**

1. **Line 3:** `Všechny významné změny v CLAUDE-agents pluginu.` → `All notable changes to the CLAUDE-agents plugin.`

2. **Line 5:** `Formát: [Keep a Changelog](https://keepachangelog.com/cs/1.1.0/)` → `Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)` (also change URL from `/cs/` to `/en/`)

3. **Line 6:** `Verzování: [Semantic Versioning](https://semver.org/lang/cs/)` → `Versioning: [Semantic Versioning](https://semver.org/)` (drop `/lang/cs/`)

4. **Line 8:** `> **Poznámka k jazyku:** Od verze 3.0.0 jsou záznamy v angličtině (Added, Changed, Fixed). Starší verze používají českou terminologii.` → `> **Language note:** From v3.0.0 onward, entries use English headers (Added, Changed, Fixed). Older versions use Czech terminology.`

5. **v3.1.1 (line 17):** `- **dashboard + metrics:** spec checkpoint regex fixed to match Czech format agent actually posts (\`Spec analýza dokončena\` instead of English)` → `- **dashboard + metrics:** spec checkpoint regex fixed to match format agent actually posts (\`Spec analysis completed\`)`

6. **v3.1.0 section (lines 64-99):** Multiple Czech descriptions:
   - Line 67: `nový agent` → `new agent`; `backlog analýza s impact/risk/effort scoring a dependency grafem` → `backlog analysis with impact/risk/effort scoring and dependency graph`
   - Line 69: `range-based predikce token usage (best/typical/worst) před spuštěním pipeline` → `range-based token usage prediction (best/typical/worst) before running pipeline`
   - Line 72: `Konfigurovatelné profily` → `Configurable profiles`; `skip/add stages per task type` (already English)
   - Line 73: `Post-publish verifikační krok` → `Post-publish verification step`; `s closed-loop feedback` (already English)
   - Line 74: `Rozšíření code-analyst o past fixes, known patterns, pipeline history, risk modifier` → `Extended code-analyst with past fixes, known patterns, pipeline history, risk modifier`
   - Line 75: `jako first-class trackery vedle YouTrack — per-tracker validace v check-setup, per-tracker defaults v onboard` → `as first-class trackers alongside YouTrack — per-tracker validation in check-setup, per-tracker defaults in onboard`
   - Line 76: `Přepracovaná worktree orchestrace — result collection, batching, cleanup modes (auto/manual)` → `Reworked worktree orchestration — result collection, batching, cleanup modes (auto/manual)`
   - Line 77: `conflict detection v check-setup` → `conflict detection in check-setup` (minor)
   - Line 79: `anglický README.md, český archivován jako README.cs.md` → `English README.md, Czech archived as README.cs.md`
   - Line 80: `jak přispět, napsat custom agenta, reportovat bugy` → `how to contribute, write custom agents, report bugs`
   - Line 85: `nový --profile <name> flag pro pipeline profiles` → `new --profile <name> flag for pipeline profiles`
   - Line 86-88: `nový krok` → `new step`; `Přepracovaná Worktree sekce` → `Reworked Worktree section`
   - Line 90: `multi-tracker defaults` → (already English)
   - Line 91: `Rozšířený krok 6 (historical context), strukturovaný output` → `Extended step 6 (historical context), structured output`
   - Line 92: `3 nové optional sekce` → `3 new optional sections`
   - Line 93: `5 nových intent mappings` → `5 new intent mappings`
   - Line 94: `podpora volitelného argumentu` → `support for optional argument`

7. **v3.0.1 section (lines 101-123):** Czech descriptions:
   - Line 104: `chybějící Block Comment Template pro BLOCK verdict` → `missing Block Comment Template for BLOCK verdict`
   - Line 105: `pro smazání untracked souborů po resetu` → `for deleting untracked files after reset`
   - Line 106: `kompletní seznam agentů v skip-rollback logice (přidáni ...)` → `complete agent list in skip-rollback logic (added ...)`
   - Line 107: `rozlišení pre-existujících test failures od nových (konzistence s fixerem)` → `distinction between pre-existing test failures and new ones (consistency with fixer)`
   - Line 108: `odkaz na konfigurovatelné Build retries z Automation Config` → `reference to configurable Build retries from Automation Config`
   - Line 109: `role rozšířena z "bug fixes" na generický pipeline` → `role expanded from "bug fixes" to generic pipeline`
   - Line 110: `checkpoint komentář v češtině pro konzistenci s triage-analyst` → `checkpoint comment in English for consistency with triage-analyst`
   - Line 113: `strukturované output šablony (markdown bloky)` → `structured output templates (markdown blocks)`
   - Line 114: `Block Comment Template reference pro failure handling` → `Block Comment Template reference for failure handling`
   - Line 115: `think-before-acting krok` → `think-before-acting step`
   - Line 116: `explicitní číslované kroky pro spolehlivější následování` → `explicit numbered steps for more reliable following`
   - Line 117: `iterativní loop awareness s popisem kontextu předávaného z commandů` → `iterative loop awareness with description of context passed from commands`
   - Line 119: `read-only constraint, dynamic version note, intentional absence of Block Template documented` → (already mostly English)
   - Line 120: `flexible file count, table format reminder, intentional absence of Block Template documented` → (already mostly English)
   - Line 121: `strategy selection criteria (...), diff estimation heuristics, runtime fields note` → (already mostly English)
   - Line 122: `diferenciovaný role title ("Software Engineer" místo "Software Architect")` → `differentiated role title ("Software Engineer" instead of "Software Architect")`

8. **v2.0.0 section (lines 124-175):** This section is entirely Czech. Translate category headers and all entries:
   - `### Nové funkce` → `### Added`
   - `### Dokumentace` → `### Documentation`
   - `### Interní` → `### Internal`
   - All `feat:`, `docs:`, `chore:` descriptions translated

9. **v1.1.0 section (lines 176-182):**
   - `### Nové funkce` → `### Added`
   - `genericizace pluginu — žádná project-specific logika` → `plugin genericization — no project-specific logic`
   - `routing skill pro natural language přístup` → `routing skill for natural language access`

10. **v1.0.0 section (lines 183-188):**
    - `### Nové funkce` → `### Added`
    - `počáteční release — 7 agentů, 5 commands` → `initial release — 7 agents, 5 commands`
    - `bug-fix pipeline: triage → analysis → fix → review → test → publish` (already English)

**Risk:** LOW — CHANGELOG is human-readable, not machine-parsed.

#### Step 5.9: `CONTRIBUTING.md`

**Changes:**

1. **Line 17:** `Command definitions: Czech descriptions in frontmatter, structured orchestration steps` → `Command definitions: English descriptions in frontmatter, structured orchestration steps`

2. **Line 57:** `description: Short description (Czech)` → `description: Short description (English)`

**Risk:** LOW — these are prescriptive guidelines that must match the new reality.

#### Step 5.10: `README.cs.md` — DELETE

**Action:** Delete `README.cs.md` entirely. It is the archived Czech README that will no longer be needed after all content is in English.

**Risk:** LOW — the file is an archive. The English README.md remains.

---

### Group 6: Setup Docs (4 files)

#### Step 6.1: `docs/setup/installation.md`

**Changes:** Full translation of entire file. Key items:
- `# Instalace CLAUDE-agents` → `# Installing CLAUDE-agents`
- `Krok za krokem: od nulového stavu po funkční pipeline.` → `Step by step: from zero to a working pipeline.`
- `## Předpoklady` → `## Prerequisites`
- `Co | Jak ověřit` → `What | How to verify`
- `Přístup k internímu Gitea | Viz sekce níže` → `Access to internal Gitea | See section below`
- `## 1. Přístup k Gitea` → `## 1. Access to Gitea`
- `Plugin je hostovaný na` → `The plugin is hosted on`
- `Potřebuješ SSH nebo HTTPS přístup.` → `You need SSH or HTTPS access.`
- `### Varianta A: SSH (doporučeno)` → `### Option A: SSH (recommended)`
- `Vygeneruj SSH klíč (pokud nemáš):` → `Generate SSH key (if you don't have one):`
- `Přidej veřejný klíč do Gitea:` → `Add public key to Gitea:`
- `Nastav` → `Set up`
- `Ověř:` → `Verify:`
- `### Varianta B: HTTPS` → `### Option B: HTTPS`
- `Vygeneruj Gitea Personal Access Token` → `Generate Gitea Personal Access Token`
- `## 2. Instalace pluginu` → `## 2. Plugin installation`
- `Spusť Claude Code v libovolném adresáři` → `Run Claude Code in any directory`
- `Zadej:` → `Enter:`
- `Ověř: zadej ... a zkontroluj, že se nabízí commands (tab-complete)` → `Verify: enter ... and check that commands are offered (tab-complete)`
- `### Update pluginu` → `### Updating the plugin`
- `Marketplace cache se neaktualizuje automaticky. Po vydání nové verze:` → `Marketplace cache does not update automatically. After a new version is released:`
- `Poté restartuj Claude Code session.` → `Then restart the Claude Code session.`
- `## 3. Setup projektu` → `## 3. Project setup`
- `Po instalaci pluginu je nutné nastavit konkrétní projekt:` → `After installing the plugin, you need to set up each project:`
- `Vytvoř .mcp.json` → `Create .mcp.json`
- `Přidej ## Automation Config do CLAUDE.md projektu` → `Add ## Automation Config to the project's CLAUDE.md`
- `Ověř:` → `Verify:`
- `## Platformové poznámky` → `## Platform notes`
- `### Windows (primární)` → `### Windows (primary)`
- `Výše popsaný postup je pro Windows. Cesty používají ~/` → `The procedure above is for Windows. Paths use ~/ notation`
- `### Linux` — `SSH konfigurace je identická` → `SSH configuration is identical`
- `stáhni linux-amd64 binary` → `download linux-amd64 binary`
- `ulož jako` → `save as`; `nastav` → `set`
- `V .mcp.json použij linuxovou cestu k binárce` → `In .mcp.json use Linux path to binary`
- `Detaily viz` → `Details in`
- `### macOS` — `Explicitně nepodporováno, ale pravděpodobně funkční (analogické Linuxu).` → `Not explicitly supported, but likely functional (analogous to Linux).`

**Risk:** LOW.

#### Step 6.2: `docs/setup/tokens.md`

**Changes:** Full translation of entire file. Key items:
- `# Tokeny pro CLAUDE-agents` → `# Tokens for CLAUDE-agents`
- `CLAUDE-agents komunikuje s issue trackerem a source controlem přes MCP servery. Každý MCP server vyžaduje API token.` → `CLAUDE-agents communicates with the issue tracker and source control via MCP servers. Each MCP server requires an API token.`
- `## Přehled` → `## Overview`
- `Token | Služba | MCP server` → `Token | Service | MCP server`
- `Jeden token = jedna služba. Tokeny se ukládají do .mcp.json (nikdy do CLAUDE.md).` → `One token = one service. Tokens are stored in .mcp.json (never in CLAUDE.md).`
- All tracker-specific instructions (YouTrack, Gitea, GitHub, Jira, Linear): translate step descriptions
- `Otevři YouTrack → klikni na svůj profil` → `Open YouTrack → click on your profile`
- `Název tokenu: doporučení` → `Token name: recommended`
- `Klikni Create — token se zobrazí jen jednou, zkopíruj ho ihned` → `Click Create — token is shown only once, copy it immediately`
- `Platnost: doporučení bez expirace nebo 1 rok` → `Validity: recommended no expiration or 1 year`
- `## Bezpečnost tokenů` → `## Token security`
- `**.mcp.json NIKDY do gitu** — přidej do .gitignore` → `**.mcp.json NEVER in git** — add to .gitignore`
- `**Tokeny nepsat do CLAUDE.md** — CLAUDE.md je v gitu` → `**Never put tokens in CLAUDE.md** — CLAUDE.md is in git`
- `**Únik tokenu:** okamžitě revokuj` → `**Token leak:** immediately revoke`
- `**.mcp.json.example** — trackovaný v gitu jako template bez skutečných tokenů` → `**.mcp.json.example** — tracked in git as template without real tokens`

**Risk:** LOW.

#### Step 6.3: `docs/setup/mcp-configuration.md`

**Changes:** Full translation of entire file. Key items:
- `# MCP konfigurace` → `# MCP Configuration`
- `.mcp.json je konfigurační soubor pro MCP servery. Claude Code ho načítá automaticky při spuštění v adresáři, kde soubor existuje.` → `.mcp.json is the configuration file for MCP servers. Claude Code loads it automatically when started in a directory where the file exists.`
- `## Umístění` → `## Location`
- `**Per-projekt** (doporučeno)` → `**Per-project** (recommended)`
- `trackovaný v gitu jako template (bez tokenů)` → `tracked in git as template (without tokens)`
- `v .gitignore (obsahuje tokeny)` → `in .gitignore (contains tokens)`
- `## Struktura souboru` → `## File structure`
- In JSON example: `<cesta-k-binárce>` → `<path-to-binary>`
- `## YouTrack MCP server` section: `Balíček:` → `Package:`; `Spuštění:` → `Run:`; `Env proměnné:` → `Env variables:`; `Ověření:` → `Verification:`
- `V Claude Code zadej dotaz na existující issue. Pokud vidíš odpověď s daty z YouTrack, MCP server funguje.` → `In Claude Code, query an existing issue. If you see a response with data from YouTrack, the MCP server is working.`
- Same pattern for all MCP server sections
- `## Ověření celého setupu` → `## Verifying the complete setup`
- `Po nastavení obou MCP serverů spusť:` → `After configuring both MCP servers, run:`
- `Command ověří konfiguraci, konektivitu a zobrazí report.` → `Command verifies configuration, connectivity, and displays a report.`
- `### Časté chyby` → `### Common errors`
- `Chyba | Příčina | Řešení` → `Error | Cause | Solution`
- `Neplatný nebo expirovaný token` → `Invalid or expired token`
- `Vygeneruj nový token v YouTrack` → `Generate new token in YouTrack`
- `Špatná URL nebo nedostupný server` → `Wrong URL or server unreachable`
- `Ověř URL v prohlížeči` → `Verify URL in browser`
- `Binárka neexistuje na dané cestě` → `Binary does not exist at given path`
- `Zkontroluj cestu v .mcp.json` → `Check path in .mcp.json`

**Risk:** LOW.

#### Step 6.4: `docs/setup/cross-platform-checklist.md`

**Changes:** Full translation of entire file. Key items:
- `# Cross-Platform Test Checklist` (already English)
- `Manuální checklist pro ověření pipeline na různých platformách.` → `Manual checklist for verifying pipeline on different platforms.`
- `## Předpoklady` → `## Prerequisites`
- `Plugin nainstalován` → `Plugin installed`
- `.mcp.json nakonfigurován s platnými tokeny` → `.mcp.json configured with valid tokens`
- `## Automation Config v CLAUDE.md projektu` → `## Automation Config in project CLAUDE.md`
- `Test issue existuje v issue trackeru` → `Test issue exists in issue tracker`
- `## Windows` — `všechny kontroly OK` → `all checks OK`
- `triage + analýza proběhne` → `triage + analysis runs`
- `odpovídá` → `responds`
- `Worktree cesty fungují (relativní cesta v Automation Config)` → `Worktree paths work (relative path in Automation Config)`
- `## Linux` — `nastaven` → `set`; `Cesta k binárce v .mcp.json odpovídá Linuxové konvenci` → `Binary path in .mcp.json follows Linux convention`; `Worktree cesty: relativní formát (ne C:\...)` → `Worktree paths: relative format (not C:\...)`
- `## macOS` — `Analogické Linuxu — nepodporováno oficiálně` → `Analogous to Linux — not officially supported`
- `## Poznámky` → `## Notes`
- `Plugin samotný je platform-agnostic (čistý markdown)` → `The plugin itself is platform-agnostic (pure markdown)`
- `Platform-specific rozdíly jsou pouze v .mcp.json cestách a MCP server binárkách` → `Platform-specific differences are only in .mcp.json paths and MCP server binaries`
- `Worktree cesty v Automation Config musí být **relativní**` → `Worktree paths in Automation Config must be **relative**`

**Risk:** LOW.

---

### Group 7: Deletions and Cleanup

#### Step 7.1: Delete `README.cs.md`

Run: `git rm README.cs.md`

This is the archived Czech README. After Phase 1, all documentation is in English, making this file redundant.

**Risk:** NONE.

#### Step 7.2: CLAUDE.md — remove Czech explanatory note

Already covered in Step 1.1 (line 161). The note `> Pole šablony (Krok, Důvod, Detail, Doporučení) jsou záměrně v češtině...` is no longer applicable after translation.

---

## Critical Points

These constraints MUST NOT be violated:

1. **Atomicity:** All regex parser updates (dashboard.md, metrics.md, resume-ticket.md) MUST be in the same commit as agent block template updates. If agents emit `Step:` but dashboard still parses `Krok:`, the pipeline dashboard breaks.

2. **Checkpoint marker consistency:** The EXACT strings `[CLAUDE-agents] Triage completed.` and `[CLAUDE-agents] Spec analysis completed.` must appear identically in:
   - Agents that generate them: `triage-analyst.md` (line 46), `spec-analyst.md` (line 54)
   - Commands that parse them: `dashboard.md` (lines 38, 42), `metrics.md` (lines 36, 39), `resume-ticket.md` (lines 18, 57-58)
   - Commands that instruct agents to post them: `analyze-bug.md` (line 15)
   - Test fixtures: `tests/harness/fixtures/issues.json` (line 30)

3. **Block field name consistency:** The EXACT field names `Step:`, `Reason:`, `Detail:`, `Recommendation:` must appear identically in:
   - CLAUDE.md (canonical definition)
   - All 11 agent block templates
   - All 3 command block handlers (fix-bugs.md, fix-ticket.md, implement-feature.md)
   - All 3 regex parser commands (dashboard.md, metrics.md — not resume-ticket, which does not parse individual fields)
   - rollback-agent.md (posts the template)

4. **Test fixture alignment:** `tests/harness/fixtures/issues.json` must use the new English checkpoint format so dashboard/metrics tests can match.

5. **Profile-skip test update:** `tests/scenarios/profile-skip.sh` must be updated to grep for English patterns, not Czech.

6. **`| Klíč | Hodnota |` consistency:** All 6 example configs + 2 test configs + 1 mock project must change to `| Key | Value |`. The `onboard.md` output format instruction must also change from `| Klíč | Hodnota |` to `| Key | Value |`.

7. **CONTRIBUTING.md must reflect new reality:** Lines 17 and 57 must say "English" instead of "Czech" for command frontmatter descriptions.

## Verification

After applying all changes, run these grep commands to confirm no Czech artifacts remain:

```bash
# 1. No Czech block template fields in agents or commands
grep -r "Krok:" agents/ commands/ CLAUDE.md
# Expected: 0 results

# 2. No Czech checkpoint markers
grep -r "Triage dokončen" agents/ commands/ tests/
# Expected: 0 results

grep -r "Spec analýza dokončena" agents/ commands/ tests/
# Expected: 0 results

grep -r "Oblast:" agents/ commands/
# Expected: 0 results (was used in spec checkpoint)

grep -r "Kritéria:" agents/ commands/
# Expected: 0 results (was used in spec checkpoint)

# 3. No Czech table headers in active files (exclude docs/plans/)
grep -r "Klíč | Hodnota" examples/ tests/ commands/ agents/ CLAUDE.md CONTRIBUTING.md CHANGELOG.md docs/setup/
# Expected: 0 results

# 4. No Czech section headers in commands
grep -r "## Kroky\|## Pravidla\|## Konfigurace\|## Orchestrace" commands/
# Expected: 0 results

# 5. No Czech frontmatter descriptions
grep -r "^description:.*[čěšžřďťňůúýáíé]" commands/
# Expected: 0 results

# 6. Verify English patterns are present
grep -r "Step:" agents/ commands/ CLAUDE.md | head -5
# Expected: multiple results in block templates

grep -r "Triage completed" agents/ commands/ tests/
# Expected: triage-analyst.md, analyze-bug.md, dashboard.md, metrics.md, resume-ticket.md, issues.json

grep -r "Spec analysis completed" agents/ commands/
# Expected: spec-analyst.md, dashboard.md, metrics.md, resume-ticket.md

# 7. README.cs.md deleted
test -f README.cs.md && echo "FAIL: README.cs.md still exists" || echo "PASS: README.cs.md deleted"

# 8. Profile test updated
grep "Parsování pipeline profilu" tests/scenarios/profile-skip.sh
# Expected: 0 results

# 9. No Czech in CONTRIBUTING.md
grep -i "czech" CONTRIBUTING.md
# Expected: 0 results
```

**Note:** `docs/plans/` directory is EXCLUDED from verification. Historical design documents are archival and may contain Czech or mixed languages by design. They are NOT translated in Phase 1.

## Commit Message

```
docs: translate all Czech content to English (Phase 1 of Documentation Overhaul)

Translate 54 files from Czech to English:
- CLAUDE.md: Block Comment Template fields (Krok→Step, Důvod→Reason, Doporučení→Recommendation)
- CLAUDE.md: checkpoint markers (Triage dokončen→Triage completed, Spec analýza dokončena→Spec analysis completed)
- 11 agents: Block Comment Template field names
- 22 commands: full translation of frontmatter, orchestration steps, rules
- 3 commands with regex parsers: dashboard.md, metrics.md, resume-ticket.md (updated simultaneously)
- 4 setup docs: full translation
- 6 config templates: table headers Klíč|Hodnota → Key|Value
- Tests: fixtures, mock project, profile-skip.sh assertions
- CHANGELOG.md: section headers and descriptions
- CONTRIBUTING.md: updated coding standards (Czech→English)
- Delete README.cs.md (Czech README archive, no longer needed)

All regex parsers, checkpoint markers, and block template field names
updated atomically to maintain pipeline consistency.

Part of v3.2.0 Documentation Overhaul (Phase 1 of 4).
```
