# TOML Overlay Syntax Guide

**Verze:** v8.0.0
**Platí pro:** ceos-agents plugin v8.0.0+

---

## 1. Overview

Počínaje v8.0.0 ceos-agents podporuje strukturovanou konfiguraci per-agent přes TOML overlay soubory.
Místo surového textu připojeného k promptu (starý `.md` formát z v7.x) projekt vytváří
`customization/{agent}.toml` soubory s přesně definovanou sémantikou slučování.

**TOML overlay = strukturovaná konfigurace per-agent v `customization/{agent}.toml`**, která
rozšiřuje plugin-default definici agenta ve třech vrstvách:

1. **Skalar override** — přepíše konkrétní hodnotu (např. `model`, `style`)
2. **Array append** — přidá záznamy za plugin-default pole (`[[process_additions]]`, `[[constraints]]`)
3. **Table deep-merge** — sloučí klíče v `[limits]` s plugin defaulty per klíč

Systém validuje TOML soubory přísně: neznámé klíče způsobí okamžité zastavení dispatche s chybovou
hláškou, takže překlepy ve jménech klíčů jsou okamžitě odhaleny. Tabulka `[meta]` je výjimkou —
je **volná forma** a přijímá libovolné podklíče bez validace.

---

## 2. Per-Agent Overrideable Keys Reference

Tabulka níže vyjmenovává **všech 18 agentů** v8.0.0 a jejich přepisovatelné klíče.
Všichni agenti sdílejí univerzální schéma (Tier 1 + Tier 2 + `[meta]`); Tier 3 klíče v `[limits]`
jsou agent-specifické.

| Agent | Tier 1 (scalar override) | Tier 2 (array append) | Tier 3 — `[limits]` klíče |
|-------|--------------------------|-----------------------|---------------------------|
| `analyst` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | `max_files_reported` |
| `fixer` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | `max_diff_lines`, `max_iterations` |
| `reviewer` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | `max_review_iterations` |
| `acceptance-gate` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | `ac_threshold`, `complexity_threshold` |
| `test-engineer` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | `max_test_attempts`, `test_framework` |
| `publisher` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | `max_pr_retries` |
| `rollback-agent` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | (none agent-specific) |
| `spec-analyst` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | `max_root_cause_iterations` |
| `architect` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | `max_decomposition_depth` |
| `stack-selector` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | (none agent-specific) |
| `scaffolder` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | `max_spec_iterations` |
| `priority-engine` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | (none agent-specific) |
| `spec-writer` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | `max_spec_iterations` |
| `spec-reviewer` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | (none agent-specific) |
| `browser-agent` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | `max_pages`, `exploration_max_clicks` |
| `deployment-verifier` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | (none agent-specific) |
| `backlog-creator` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | (none agent-specific) |
| `sprint-planner` | `model`, `style` | `[[process_additions]]`, `[[constraints]]` | (none agent-specific) |

**Sdílené `[limits]` klíče** (semanticky aplikovatelné u libovolného agenta):

| Key | Default | Popis |
|-----|---------|-------|
| `max_build_retries` | `3` | Max. opakování build kroku |
| `max_spec_iterations` | `5` | Max. iterací spec-writer ↔ spec-reviewer |
| `max_root_cause_iterations` | `3` | Max. iterací root cause analysis |

**`[meta]`** je volná forma dostupná všem agentům — libovolné podklíče jsou přijaty bez validace.

---

## 3. Three-Tier Merge Rules

### Tier 1 — Scalar Override

Plugin-default hodnota je **nahrazena** hodnotou z overlay souboru.

Podporované skalární klíče: `model`, `style`.

**Platné hodnoty `model`:** `opus`, `sonnet`, `haiku`.

**Příklad — přepnutí revieweru na opus:**

```toml
# customization/reviewer.toml
model = "opus"
style = "security-focused"
```

Výsledek: agent `reviewer` bude spuštěn s modelem `opus` namísto plugin-default `opus`
(v tomto případě beze změny, ale overlay je explicitní).

**Příklad — přepnutí publisheru z haiku na sonnet:**

```toml
# customization/publisher.toml
model = "sonnet"
```

Plugin default `agents/publisher.md` deklaruje `model: haiku`. Overlay přepíše na `sonnet`.
Efektivní model: `sonnet`.

### Tier 2 — Array of Tables (Append)

Overlay entries are **appended after** the plugin-default entries. Plugin-default entries always appear before project additions (order preserved).

Záznamy z overlay jsou **přidány ZA** plugin-default záznamy. Pořadí je zachováno.

**Keys:** `[[process_additions]]`, `[[constraints]]`

Povinné podklíče:
- `[[process_additions]]`: `step` (string), `instruction` (string)
- `[[constraints]]`: `rule` (string)

Neznámé podklíče uvnitř těchto položek jsou **zamítnuty** (unknown-key validation).

**Příklad — přidání security checku do revieweru:**

Plugin default má v `process_additions`:
```
[{step="after_default", instruction="Verify all acceptance criteria are addressed."}]
```

Overlay přidá:
```toml
# customization/reviewer.toml
[[process_additions]]
step = "after_default"
instruction = "Run SAST mental-pass: SQLi, XSS, SSRF, path traversal."

[[process_additions]]
step = "before_publish"
instruction = "Confirm all new public API methods have docstrings."
```

Efektivní `process_additions` (3 záznamy, v tomto pořadí):
1. `{step="after_default", instruction="Verify all acceptance criteria are addressed."}` ← plugin default
2. `{step="after_default", instruction="Run SAST mental-pass: SQLi, XSS, SSRF, path traversal."}` ← overlay
3. `{step="before_publish", instruction="Confirm all new public API methods have docstrings."}` ← overlay

### Tier 3 — Table Deep Merge

The `[limits]` table is merged key-by-key: overlay keys override the corresponding plugin-default
keys; **absent keys are inherited from the plugin default** unchanged (missing keys in the overlay
inherit their value from the plugin default).

`[limits]` tabulka se sloučí **klíč po klíči**: klíče z overlay přepíší odpovídající plugin-default
klíče; klíče, které overlay neobsahuje, jsou **zděděny z plugin defaultu** beze změny.

**Příklad — snížení max iterací pro reviewer:**

Plugin default `[limits]` pro `reviewer`:
```
{max_review_iterations=5}
```

Overlay:
```toml
# customization/reviewer.toml
[limits]
max_review_iterations = 3
```

Efektivní `[limits]`: `{max_review_iterations=3}` — overlay vyhrává.

**Příklad — partial override zachovávající zbytek:**

Plugin default `[limits]` pro `fixer`:
```
{max_diff_lines=100, max_iterations=5}
```

Overlay:
```toml
# customization/fixer.toml
[limits]
max_diff_lines = 60
```

Efektivní `[limits]`: `{max_diff_lines=60, max_iterations=5}` — `max_diff_lines` přepsán,
`max_iterations` zděděn z plugin defaultu.

### Conflict Resolution Precedence

TOML overlay **vždy vyhrává** nad plugin defaultem na stejné cestě. Neexistuje žádná
ambiguita pořadí merge — schéma je striktně 2-vrstvý zásobník (plugin default + project overlay).
v8.0.0 nezavádí 3. vrstvu (user-level overlay).

---

## 4. TOML Examples

### 4.1 `reviewer-strict-security.toml`

```toml
# customization/reviewer.toml
# Strict security posture for any project with public-facing API.
model = "opus"

[[process_additions]]
step = "after_default"
instruction = "Run a SAST mental-pass: check for SQLi, XSS, SSRF, path traversal, secret commits."

[[constraints]]
rule = "Block any PR introducing eval(), Function(), or subprocess.shell=True."

[[constraints]]
rule = "Block any PR that adds a new env var without documenting it in docs/configuration.md."

[[constraints]]
rule = "NEVER approve a PR that changes authentication flow without explicit security test coverage."

[limits]
max_review_iterations = 7

[meta]
security_level = "strict"
team_owner = "security-team"
```

### 4.2 `fixer-no-tests.toml`

```toml
# customization/fixer.toml
# Prototype branch policy: skip test dispatch on prototype/* branches.
[[process_additions]]
step = "before_test_dispatch"
instruction = "If the current branch matches the pattern prototype/*, skip test dispatch. Only run the smoke build. Mark the PR as Draft and add the label prototype-no-tests."

[[constraints]]
rule = "On prototype/* branches, NEVER create a ready-for-review PR. Always use draft mode."

[limits]
max_diff_lines = 200
max_test_attempts = 0

[meta]
policy = "prototype-no-tests"
```

### 4.3 `analyst-monorepo.toml`

```toml
# customization/analyst.toml
# Monorepo project: expand impact analysis across all top-level packages.
style = "cross-package-aware"

[[process_additions]]
step = "after_default"
instruction = "On --phase impact, walk all top-level packages under apps/, packages/, and libs/. Report cross-package dependencies in the affected-files list. Include every consumer package that imports the changed module."

[[constraints]]
rule = "Cross-package changes MUST list every consumer package in the impact report (max 5 packages, alphabetical order)."

[limits]
max_files_reported = 8
```

### 4.4 `browser-agent-parallel.toml`

```toml
# customization/browser-agent.toml
# High-coverage browser verification for a content-heavy application.
style = "thorough"

[[process_additions]]
step = "after_default"
instruction = "On --phase verify, also navigate to /accessibility-check and validate WCAG AA contrast ratios on the changed page."

[[constraints]]
rule = "NEVER mark verification as passed if any console error appears in the browser log."

[limits]
max_pages = 20
exploration_max_clicks = 100

[meta]
coverage_target = "wcag-aa"
base_url_override = "https://staging.example.com"
```

### 4.5 `agent-with-meta-table.toml`

```toml
# customization/spec-writer.toml
# Project-side metadata annotations (not consumed by plugin dispatch logic).
model = "opus"

[[constraints]]
rule = "All acceptance criteria MUST follow the EARS format (WHEN/THEN/WHILE) with no exceptions."

[limits]
max_spec_iterations = 7

[meta]
priority_label   = "ceos-priority"
team_owner       = "architecture-team"
cost_center      = "PROJ-42"
jira_component   = "Backend-Core"
review_required  = true
arbitrary_key    = "any value is accepted here — no validation applied to [meta] sub-keys"
```

---

## 5. `[meta]` Table — Free-Form

Tabulka `[meta]` je **volná forma**: plugin ji přijímá bez jakékoli validace podklíčů.

```toml
[meta]
priority_label = "ceos-priority"   # example key — entirely up to the project
team_owner     = "backend-team"    # example key
cost_center    = "PROJ-42"         # example key
any_key        = "any value"       # arbitrary; NOT subject to unknown-key validation
```

Klíče v `[meta]` **NEJSOU konzumovány** dispatch logikou pluginu. Jsou určeny výhradně
pro project-side anotace (tracking, cost attribution, tooling integrations).

**`[meta]` je EXEMPT from unknown-key rejection** (REQ-OVR-003): zatímco všechny ostatní
top-level klíče a klíče uvnitř `[limits]`, `[[process_additions]]`, `[[constraints]]` podléhají
strict-mode unknown-key validation, podklíče uvnitř `[meta]` nejsou NOT subject to unknown-key
rejection a mohou mít libovolné názvy. Meta sub-keys accept arbitrary values (strings, integers,
booleans, arrays — any valid TOML value type).

Tato výjimka umožňuje projektům ukládat libovolné metadata bez nutnosti zásahu do plugin schématu.

---

## 6. Validation Rules

### 6.1 TOML Syntax Errors

Pokud overlay soubor nelze zparsovat (neplatná TOML 1.0 syntaxe), plugin:
1. Emituje `[ERROR]` log s cestou k souboru a číslem řádku (pokud ho parser hlásí — volitelné)
2. Zastaví dispatch agenta s non-zero exit
3. NEPOKRAČUJE s žádným částečným merge

**Error format:**
```
[ERROR] TOML overlay validation failed for {agent}: {detail} (file: {overlay_path})
```

**Příklady chyb:**
```
[ERROR] TOML overlay validation failed for reviewer: syntax error: unterminated string at line 3 (file: customization/reviewer.toml)
[ERROR] TOML overlay validation failed for fixer: syntax error: expected key-value separator '=' (file: customization/fixer.toml)
```

### 6.2 Unknown-Key Validation (Strict Mode)

Unknown-key rejection se vztahuje na:

| Scope | Rejekce |
|-------|---------|
| Top-level klíče | Cokoliv jiného než `model`, `style`, `[[process_additions]]`, `[[constraints]]`, `[limits]`, `[meta]` |
| Klíče v `[limits]` | Klíče neuvedené v per-agent reference tabulce (Sekce 2) |
| Klíče v `[[process_additions]]` | Cokoliv jiného než `step` a `instruction` |
| Klíče v `[[constraints]]` | Cokoliv jiného než `rule` |
| **Podklíče v `[meta]`** | **EXEMPT — žádná validace, libovolné klíče přijímány** |

**Error format:**
```
[ERROR] TOML overlay validation failed for {agent}: unknown key '{key}' (file: {overlay_path})
```

Příklad: projekt omylem napíše `max_iterations_count` místo `max_iterations` v `customization/fixer.toml`:
```
[ERROR] TOML overlay validation failed for fixer: unknown key 'max_iterations_count' (file: customization/fixer.toml)
```

Dispatch je zastaven s exit code 1.

### 6.3 `.md` + `.toml` Koexistence (REQ-OVR-005)

Pokud pro stejného agenta existují **oba** soubory (`customization/{agent}.md` A `customization/{agent}.toml`):
- `.toml` soubor má **přednost** (primární formát v8.0.0)
- `.md` soubor je **ignorován**
- Emituje se: `[WARN] Legacy .md overlay ignored; .toml takes precedence (deprecate v9.0.0)`

---

## 7. Provenance Log

Při každém dispatch agenta plugin zapíše jeden záznam do `.ceos-agents/pipeline.log`:

**Format:**
```
agent={name} overlay_source={toml|md|none} overlay_path={path}
```

| Pole | Popis |
|------|-------|
| `agent` | Jméno agenta (např. `reviewer`) |
| `overlay_source` | `toml` — TOML overlay aplikován; `md` — legacy .md overlay aplikován; `none` — žádný overlay |
| `overlay_path` | Absolutní nebo relativní cesta k overlay souboru; `(none)` pro `overlay_source=none` |

**Tři povinné větve (každá vyskytující se právě jednou per dispatch):**

| Scénář | Log řádek |
|--------|-----------|
| `.toml` overlay použit | `agent=reviewer overlay_source=toml overlay_path=customization/reviewer.toml` |
| `.md` legacy overlay použit | `agent=reviewer overlay_source=md overlay_path=customization/reviewer.md` |
| Žádný overlay | `agent=reviewer overlay_source=none overlay_path=(none)` |

Záznam provenance je zapisován **právě jednou per dispatch** — ne jednou per pipeline run
a ne jednou per overlay klíč.

**Log destination:** `.ceos-agents/pipeline.log` (append mode; stejný soubor jako ostatní
pipeline log záznamy; rotace dle `core/state-manager.md`).

---

## 8. Backwards Compatibility

### v7 → v8 (Legacy `.md` Overlay Still Works)

v8.0.0 je plně zpětně kompatibilní s projekty v7.0.0 bez nutnosti spustit migraci:

- `customization/{agent}.md` soubory (legacy v7 formát) jsou **stále parsovány** jako raw append text
- Každé použití emituje `[WARN]` log: `[WARN] Legacy .md overlay format will be removed in v9.0.0; migrate to .toml manually`
- Pipeline se **nezastaví** kvůli legacy `.md` overlay — varování jsou advisory
- Ruční konverze `.md` → `.toml`: viz [migration-v7-to-v8.md](migration-v7-to-v8.md) (skill `/migrate-config --to-v8` byl smazán v v9.5.0)

**Souhrnná pravidla koexistence v8.0.0:**

| Stav souborů | Chování |
|--------------|---------|
| pouze `.toml` | Použije `.toml` (primární cesta) |
| pouze `.md` | Použije `.md` s WARN (legacy path) |
| oba `.toml` a `.md` | Použije `.toml`, `.md` ignoruje, emituje WARN |
| žádný | Provenance log `overlay_source=none`, žádná úprava promptu |

**v7 project compatibility (`.md` only, without `.toml`):** A project that only has `customization/{agent}.md`
files (v7 format) — without any `.toml` files — works in v8.0.0 without any migration.
The plugin detects the `.md`-only overlay path and applies the legacy append-text behavior,
emitting a deprecation `[WARN]` per dispatch. No `.toml` file is required for the pipeline to
proceed. This ensures zero-migration-required compatibility for v7 projects upgrading to v8.

### v9.0.0 Hard Removal

`customization/{agent}.md` legacy overlay podpora bude **hard-removed v9.0.0**.

- Ruční konverze `.md` → `.toml`: viz [migration-v7-to-v8.md](migration-v7-to-v8.md) (skill `/migrate-config` byl smazán v v9.5.0)
- Projekty stále používající `.md` overlay po v9.0.0 narazí na validation error při dispatch

---

## 9. Migration Path

Chcete-li převést stávající `customization/*.md` overlaye na TOML formát, postupujte dle průvodce migrací:

[migration-v7-to-v8.md](migration-v7-to-v8.md)

Skill `/migrate-config --to-v8` byl smazán v v9.5.0 — konverze se provádí manuálně dle kroků v průvodci.

Skill:
1. Zazálohuje celý `customization/` adresář do `customization.bak-v7-{timestamp}/`
2. Pro každý `{agent}.md` soubor vygeneruje `{agent}.toml` s `[[process_additions]]` bloky
3. Přejmenuje soubory dle mapping tabulky pro sloučené agenty
4. Vypíše summary report se všemi provedenými změnami

---

## Universal Schema Reference

Pro rychlý přehled — úplné schéma aplikovatelné na libovolného z 18 agentů:

```toml
# customization/{agent}.toml — full schema (applicable to any of 18 agents)

# --- Tier 1: Scalar overrides ---
model = "sonnet"      # one of: opus | sonnet | haiku
style = "rigorous"    # short descriptor; appended to agent system prompt

# --- Tier 2: Array of tables (append after plugin defaults) ---
[[process_additions]]
step        = "after_default"     # required; canonical anchor name
instruction = "Your instruction." # required; free-form string

[[process_additions]]
step        = "before_publish"
instruction = "Run smoke before PR creation."

[[constraints]]
rule = "PR review messages MUST be in Czech."

[[constraints]]
rule = "Reject any PR that adds a dependency without package.json rationale."

# --- Tier 3: Table deep merge (only listed keys merged; rest inherited from plugin default) ---
[limits]
# Tier 3 keys vary by agent — see per-agent reference table (Section 2).
# Shared keys available to any agent where semantically applicable:
max_build_retries        = 2    # default: 3
max_spec_iterations      = 5    # default: 5
max_root_cause_iterations = 3   # default: 3

# --- [meta]: free-form table — NOT subject to unknown-key validation ---
# All sub-keys accepted; NOT consumed by plugin dispatch logic.
[meta]
priority_label = "ceos-priority"
team_owner     = "backend-team"
cost_center    = "PROJ-42"
```
