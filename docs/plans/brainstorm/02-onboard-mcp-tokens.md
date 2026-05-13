# 02 — Integrace MCP tokenů do onboard wizardu

## Aktuální stav

### Onboard wizard — struktura (10 kroků: Step 0–9)

1. **Step 0:** Detection & Routing (fresh/update mód)
2. **Step 1:** Template Offer (pre-built konfigurace)
3. **Step 2:** Issue Tracker (typ, URL, projekt, query, stavy)
4. **Step 3:** Source Control (remote, base branch, branch naming)
5. **Step 4:** PR Rules + PR Description Template
6. **Step 5:** Build & Test (build, test, verify commands)
7. **Step 6:** Optional Sections (12 volitelných sekcí)
8. **Step 7:** Generate Automation Config
9. **Step 8:** Output Options (print vs write to CLAUDE.md)
10. **Step 9:** Closing Message — **zde je zmínka o MCP:**
    ```
    2. Configure MCP servers for your issue tracker (see docs/guides/mcp-configuration.md)
    ```

### Současný MCP setup proces

MCP tokeny a servery se konfigurují **kompletně mimo onboard wizard**:
1. Uživatel si přečte `docs/guides/tokens.md` — vygeneruje token
2. Uživatel si přečte `docs/guides/mcp-configuration.md` — ručně vytvoří `.mcp.json`
3. Uživatel spustí `/CLAUDE-agents:check-setup` — ověří konektivitu

### Bolestivé body

- Uživatel musí přeskakovat mezi onboardem a 2 dalšími docs
- Onboard vygeneruje Automation Config, ale `.mcp.json` neexistuje → pipeline nefunguje
- `check-setup` odhalí problémy až po onboardu — pozdě
- Nováček netuší, že potřebuje MCP servery

### BLOCKER: Omezení `allowed-tools` v onboard commandu

Onboard wizard má `allowed-tools: Read, Glob, Write, Edit`. **Nemá přístup k `Bash` ani `mcp__*`.**

To znamená:
- **OS detekce není programaticky možná** — wizard nemůže spustit `uname` ani zjistit platformu jinak než otázkou uživateli
- **Validace konektivity v onboardu není možná** — wizard nemůže volat MCP servery pro ověření tokenu
- **Stahování binárky (forgejo-mcp) není možné** — wizard nemůže spustit curl/wget

Jakékoli navrhované features vyžadující `Bash` nebo `mcp__*` mají jako **prerequisite rozšíření `allowed-tools`** v `commands/onboard.md`. Toto je designová změna s dopadem na bezpečnostní model onboardu (aktuálně je onboard čistě read/write, bez side-effectů mimo souborový systém).

Pro srovnání: `check-setup` má `allowed-tools: mcp__*, Read, Glob, Grep, Bash` — tedy plný přístup.

---

## Mapování tracker → MCP server

| Tracker Type | MCP Server | Token env var | Další env vars | Poznámky |
|-------------|-----------|---------------|----------------|----------|
| youtrack | `@vitalyostanin/youtrack-mcp` | `YOUTRACK_TOKEN` | `YOUTRACK_BASE_URL` | npx |
| gitea | `forgejo-mcp` (binárka) | `FORGEJO_TOKEN` | `FORGEJO_URL` | Vyžaduje ruční stažení binárky; cross-platform cesty (viz níže) |
| github | `@modelcontextprotocol/server-github` | `GITHUB_PERSONAL_ACCESS_TOKEN` | — | npx; sdílí server s source control |
| jira | `@modelcontextprotocol/server-atlassian` | `ATLASSIAN_API_TOKEN` | `ATLASSIAN_URL`, `ATLASSIAN_EMAIL` | npx |
| linear | `@modelcontextprotocol/server-linear` | `LINEAR_API_KEY` | — | npx |
| redmine | `mcp-server-redmine` | `REDMINE_API_KEY` | `REDMINE_HOST` | npx s `--prefix` (nestandardní — viz níže) |

Source control MCP server závisí na hostingu (Gitea → `forgejo-mcp`, GitHub → `server-github`).

### Sdílený MCP server pro tracker + source control

Gitea a GitHub používají **stejný MCP server** pro issue tracker i source control:
- Gitea tracker + Gitea hosting → obojí `forgejo-mcp` (jedna instance)
- GitHub tracker + GitHub hosting → obojí `server-github` (jedna instance)

Wizard nesmí v tomto případě server v `.mcp.json` duplikovat. Pokud tracker a source control sdílí server, stačí jediná konfigurace.

Pro smíšené kombinace (např. Jira tracker + GitHub source control) jsou potřeba dva různé MCP servery.

### Tracker-specifické edge cases

**Forgejo MCP — cross-platform cesty:**
- Windows: `bin/forgejo-mcp.exe` (binárka `forgejo-mcp-windows-amd64.exe`)
- Linux: `bin/forgejo-mcp` (binárka `forgejo-mcp-linux-amd64`, vyžaduje `chmod +x`)
- macOS: `bin/forgejo-mcp` (binárka `forgejo-mcp-darwin-amd64` nebo `darwin-arm64`)

Cesta k binárce v `.mcp.json` se liší dle platformy. Wizard musí uživatele navést ke správnému souboru. Viz `docs/guides/cross-platform.md` a `docs/guides/mcp-configuration.md`.

**Redmine MCP — nestandardní `npx` invokace:**
```json
{
  "command": "npx",
  "args": ["-y", "--prefix", "/path/to/mcp-server-redmine", "mcp-server-redmine"]
}
```
Na rozdíl od ostatních npx-based serverů vyžaduje `--prefix` s cestou k lokální instalaci. Wizard musí uživateli vysvětlit tento požadavek a zeptat se na cestu. Viz `docs/guides/mcp-configuration.md`.

**Chybějící `redmine.json` v `examples/mcp-configs/`:**
V adresáři `examples/mcp-configs/` chybí `redmine.json` — existuje `youtrack.json`, `github.json`, `gitea.json`, `jira.json`, `linear.json`, ale ne Redmine. Pokud by wizard generoval `.mcp.json` na základě templates, musí se `redmine.json` doplnit jako prerequisite.

**Jira/Atlassian — nekonzistence `ATLASSIAN_URL` formátu:**
`examples/mcp-configs/jira.json` uvádí hodnotu `<YOUR_INSTANCE>.atlassian.net` (bez `https://` prefixu), zatímco `docs/guides/mcp-configuration.md` uvádí `https://<org>.atlassian.net` (s `https://`). Wizard musí normalizovat URL formát — pokud uživatel zadá URL bez `https://`, wizard ho automaticky přidá. Atlassian MCP server vyžaduje plnou URL s protokolem.

---

## Navrhované integrační body

### Varianta A: Nový krok mezi Step 8 a Step 9 — MCP Setup

**Pozice:** Mezi Step 8 (Output Options) a Step 9 (Closing Message). Nový krok se čísluje jako **Step 8a** (MCP setup). Následný krok pro permissions (doc 06) je **Step 8b**.

> **Prerequisite:** Rozšíření `allowed-tools` v onboard commandu (minimálně o `Write` pro `.mcp.json` — to už je povoleno; ale pro validaci konektivity by bylo potřeba `mcp__*`, pro OS detekci `Bash`). Bez rozšíření je funkčnost omezena na generování template bez validace.

```
Step 8a: MCP Server Setup
"Your Automation Config is ready. Now let's set up the MCP servers so the pipeline can connect."

1. Detekce: existuje .mcp.json v CWD?
   - Ano → "Found existing .mcp.json. Want to update it? [y/N]"
   - Ne → "No .mcp.json found. I'll create one."

2. Sdílený server check:
   Porovnat tracker type (ze Step 2) a source control hostname (ze Step 3).
   - Stejný server (Gitea+Gitea, GitHub+GitHub) → konfigurovat jednou, upozornit uživatele
   - Různé servery → konfigurovat zvlášť

3. Na základě zvoleného tracker type (ze Step 2):
   "You selected {type}. You'll need a {token_name} token."
   "Here's how to get one: {link to docs/guides/tokens.md#section}"
   "Paste your token (or press Enter to skip — you can add it later):"

4. Na základě source control (ze Step 3):
   - Pokud sdílí server s trackerem → přeskočit (token už zadán)
   - Jinak → "Your remote is on {hostname}. You'll need a {sc_token_name} token."
     "Paste your token (or press Enter to skip):"

5. Platform-specific handling (bez Bash — zeptat se uživatele):
   Pro forgejo-mcp:
   "Which OS are you on? [1] Windows [2] Linux [3] macOS"
   → Na základě odpovědi doporučit správnou binárku a cestu
   Pro Redmine:
   "mcp-server-redmine requires a local installation path (--prefix). Where is it installed?"

6. Generování .mcp.json:
   - Použij template z examples/mcp-configs/ (nebo z docs/guides/mcp-configuration.md pro Redmine)
   - Doplň URL z Automation Config (Instance → YOUTRACK_BASE_URL atd.)
   - Doplň tokeny (pokud zadány)
   - Pokud token není zadán → placeholder <YOUR_TOKEN>
   - Neduplikovat servery pro sdílený tracker+SC případ

7. Výstup:
   - Zapsat .mcp.json do CWD
   - Přidat .mcp.json do .gitignore (pokud tam není)
   - Vytvořit .mcp.json.example (bez tokenů)
```

**Pro:** Přirozený flow — po configu hned MCP. Uživatel nemusí číst docs.
**Proti:** Wizard se prodlouží. Token paste do terminálu může být UX problém.

### Varianta B: Samostatný command `/CLAUDE-agents:setup-mcp`

Nový command, volaný z closing message onboardu.

**Pro:** Separace zodpovědnosti. Lze spustit i samostatně. Může mít vlastní `allowed-tools` (včetně `Bash`, `mcp__*`).
**Proti:** Další command k udržování. Uživatel může zapomenout ho spustit.

### Varianta C: Hybrid — integrovaný do Step 2

Hned po výběru tracker type v Step 2 se zeptá na token a URL:
```
"You selected youtrack. Instance URL?"
→ uživatel zadá URL
"Do you have a YouTrack API token ready? [y/n]"
→ pokud ano → paste
→ pokud ne → "I'll show you how to create one at the end"
```

**Pro:** Kontextově nejlogičtější — tracker type → URL → token v jednom flow.
**Proti:** Mísí Automation Config (CLAUDE.md) s MCP config (.mcp.json) — dva různé soubory.

---

## Designové možnosti: rozsah

### Možnost 1: Pouze tokeny

Wizard se zeptá jen na tokeny. MCP server konfiguraci (command, args) vygeneruje automaticky na základě tracker type.

**Pro:** Minimální zátěž pro uživatele. Server config je deterministická — závisí jen na tracker type.
**Proti:** Nepokryje edge cases (custom MCP server, nestandardní cesta k binárce, Redmine `--prefix` path).

### Možnost 2: Plný MCP setup

Wizard se ptá na všechno: MCP server command, args, env vars, tokeny.

**Pro:** Kompletní. Pokryje custom servery.
**Proti:** Příliš komplexní. 90% uživatelů použije default server.

### Možnost 3: Hybrid (doporučeno)

Default: automatická konfigurace serveru na základě tracker type. Ale nabídni:
```
"I'll configure the {server_name} MCP server for {type}. Using default setup. [Enter to confirm / 'c' to customize]"
```

Pro forgejo-mcp a Redmine automaticky nabídnout customizaci (cesta k binárce / prefix path), protože tyto nemají jednoduchý npx default.

**Pro:** Jednoduché pro 90% uživatelů, flexibilní pro zbytek.
**Proti:** O něco složitější implementace.

---

## Doporučení

**Varianta A (Step 8a) + Možnost 3 (Hybrid rozsah).**

Důvody:
1. MCP setup logicky následuje po vygenerování Automation Config
2. URL a tracker type jsou už známé ze Step 2/3 — lze automaticky doplnit
3. Hybrid rozsah pokryje většinu případů bez zbytečných otázek
4. `.mcp.json` + `.gitignore` + `.mcp.json.example` se vytvoří automaticky
5. Closing message (Step 9) místo "configure MCP servers" řekne "run check-setup to verify"
6. Sdílený server pro tracker+SC se detekuje automaticky a nekonfiguruje se dvakrát

### Prerequisites pro implementaci

| Prerequisite | Nutnost | Popis |
|-------------|---------|-------|
| Rozšíření `allowed-tools` v onboard | **Povinné pro validaci** — volitelné pro generování template | Přidání `Bash` pro OS detekci, `mcp__*` pro validaci konektivity. Bez toho wizard může jen generovat template a ptát se uživatele na OS. |
| Vytvoření `examples/mcp-configs/redmine.json` | **Povinné** | Chybějící template — musí existovat před implementací wizard generování. |

### Rizika

| Riziko | Mitigace |
|--------|----------|
| Token paste do terminálu — bezpečnost | Token se zapisuje jen do `.mcp.json`, nikdy do CLAUDE.md. `.mcp.json` je v `.gitignore`. |
| Forgejo MCP vyžaduje binárku, ne npm | Wizard se zeptá uživatele na OS (bez Bash nemůže detekovat programaticky) a navede ke stažení správné binárky dle platformy. |
| Redmine MCP vyžaduje nestandardní `--prefix` | Wizard se explicitně zeptá na cestu k lokální instalaci mcp-server-redmine. |
| Uživatel nemá token připravený | "Press Enter to skip" → placeholder, closing message připomene. |
| Update mode — `.mcp.json` už existuje | Detekce + merge (zachovat existující servery nesouvisející s CLAUDE-agents, přidat/aktualizovat pouze relevantní). |
| Cross-platform cesty v `.mcp.json` | Pro forgejo-mcp: zeptat se na OS a vygenerovat správnou cestu (`forgejo-mcp.exe` vs `forgejo-mcp`). |
| Sdílený MCP server (Gitea/GitHub) | Detekce shody tracker+SC → jedna konfigurace, žádná duplikace v `.mcp.json`. |

---

## Rozhodovací otázky

1. **Prerequisite: Má se rozšířit `allowed-tools` v onboard commandu?** Aktuálně má `Read, Glob, Write, Edit`. Pro MCP setup by bylo potřeba minimálně `Bash` (OS detekce) a ideálně `mcp__*` (validace konektivity). Jaký dopad má to na bezpečnostní model onboardu (aktuálně čistě souborový, bez side-effectů)?

2. **Kde v onboard flow umístit MCP setup?** Varianta A (Step 8a — po Output Options), B (samostatný command s vlastními `allowed-tools`), nebo C (integrovaný do Step 2)?

3. **Má wizard generovat `.mcp.json` automaticky, nebo jen vytisknout template do chatu?** (Stejná volba jako u Automation Config v Step 8.)

4. **Jak řešit Forgejo MCP binárku?** Wizard nemůže detekovat OS (bez Bash) — má se ptát uživatele na platformu, nebo se má rozšířit `allowed-tools`?

5. **Má wizard v update módu umět aktualizovat existující `.mcp.json`?** Merge logika musí zachovat existující servery nesouvisející s CLAUDE-agents (filesystem MCP, database MCP atd.) a nesmí je smazat.

6. **Má se přidat validace konektivity přímo do onboardu?** (Ping MCP server po zadání tokenu — okamžitá zpětná vazba.) Vyžaduje `mcp__*` v `allowed-tools`. Nebo to nechat na `check-setup`?

7. **Jak řešit sdílený MCP server (Gitea/GitHub)?** Když tracker a source control používají stejný server — konfigurovat jednou, nebo nechat na uživateli?

8. **Chceš source control MCP server konfigurovat taky, nebo jen issue tracker?** (Source control MCP je technicky potřeba pro publisher.)

---

