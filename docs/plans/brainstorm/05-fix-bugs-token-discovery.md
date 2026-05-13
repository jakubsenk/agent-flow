# 05 — Fix-bugs token discovery

## Aktualni stav

### Problem

1. `/fix-bugs` hlasi, ze nema nastaveny YT token
2. Kdyz uzivatel rekne, ze token je v rootu projektu, najde si ho
3. Kdyz token da do `/packages/web-client/.mcp.json`, `check-setup` hlasi FAIL

### Jak CLAUDE-agents pracuje s tokeny

**Klicovy poznatek:** CLAUDE-agents **nema vlastni token discovery mechanismus**. Tokeny jsou ulozeny v `.mcp.json` a **Claude Code platforma** je zodpovedna za jejich nacitani.

```
Claude Code startup:
  1. Nacte .mcp.json z CWD (pokud existuje)
  2. Spusti MCP servery definovane v .mcp.json
  3. Zpristupni MCP nastroje (mcp__youtrack__*, mcp__gitea__*, ...)

CLAUDE-agents commands:
  1. Ctou Automation Config z CLAUDE.md
  2. Volaji MCP nastroje (mcp__youtrack__search, mcp__gitea__create_pull_request, ...)
  3. Pokud MCP server nebezi -> nastroj neexistuje -> chyba
```

### Kde je problem

| Situace | Co se stane | Proc |
|---------|-------------|------|
| `.mcp.json` v project root | Funguje | Claude Code nacte `.mcp.json` z CWD pri startu |
| `.mcp.json` v subdirectory | **Nefunguje** | Claude Code hleda `.mcp.json` POUZE v CWD, ne v podadresarich |
| `.mcp.json` v parent directory | **Zavisi** | Claude Code **mozna** hleda v hierarchii, ale neni to garantovane |
| Token v env variable | **Zavisi na implementaci MCP serveru** | Claude Code predava env vars z `.mcp.json` `env` sekce MCP serverum. Systemove env vars jsou ale take dostupne procesu (dedi se z parent procesu). Zda MCP server pouzije systemovy env nebo vyzaduje explicitni konfiguraci v `.mcp.json`, zavisi na konkretni implementaci serveru. |

### Check-setup a `.mcp.json` validace

`check-setup.md` Block 2, krok 6:
```
Read `.mcp.json` in the project root -> [OK] or [FAIL]
```

Check-setup explicitne hleda `.mcp.json` **v project root**. Pokud je jinde, hlasi FAIL. V `check-setup.md` neexistuje zadny platform-specificky warning ani rozliseni chovani mezi Windows/Linux/macOS — vsechny platformy se chovaji stejne (hleda `.mcp.json` v CWD a hlasi [OK] nebo [FAIL]).

---

## Analyza MCP zavislosti v commands

### Kompletni mapa MCP-zavislych commands

Z 22 commands jich **16 pouziva `mcp__*`** v `allowed-tools`. Nasledujici tabulka kategorizuje kazdy command podle typu MCP zavislosti:

#### Pipeline commands (kriticky — MCP je nezbytny pro cely workflow)

| Command | MCP pouziti | Tracker MCP | Source control MCP |
|---------|------------|-------------|-------------------|
| `fix-bugs` | Query issues, state changes, PR creation, comments | Ano | Ano |
| `fix-ticket` | Query issue, state changes, PR creation, comments | Ano | Ano |
| `implement-feature` | Query issue, state changes, PR creation, comments | Ano | Ano |
| `resume-ticket` | Query issue state/comments, checkpoint detection, pipeline | Ano | Ano |

#### Publishing commands (MCP pro PR/issue tracker operace)

| Command | MCP pouziti | Tracker MCP | Source control MCP |
|---------|------------|-------------|-------------------|
| `publish` | PR creation, issue state change, comments | Ano | Ano |
| `create-pr` | PR creation | Ne | Ano |

#### Analysis commands (MCP pro cteni dat z trackeru)

| Command | MCP pouziti | Tracker MCP | Source control MCP |
|---------|------------|-------------|-------------------|
| `analyze-bug` | Query issue, post triage checkpoint comment | Ano | Ne |
| `status` | Query active issues, find PRs | Ano | Ano |
| `dashboard` | Fetch issues, comments, PRs | Ano | Ano |
| `metrics` | Fetch issues, comments | Ano | Ne (git log via Bash) |
| `estimate` | Fetch issue details | Ano | Ne |
| `prioritize` | Fetch open issues | Ano | Ne |
| `changelog` | Fetch PR details from merged commits | Ne | Ano |

#### Scaffold commands (MCP pouze pro navazne operace)

| Command | MCP pouziti | Tracker MCP | Source control MCP |
|---------|------------|-------------|-------------------|
| `scaffold` | Ma `mcp__*` v allowed-tools, ale primo ho nepouziva — scaffold generuje do temp dir, MCP by se pouzil jen pokud scaffold navaze na implement-feature | Potencialne | Potencialne |
| `scaffold-add` | Ma `mcp__*` v allowed-tools, ale primo ho nepouziva — generuje komponenty lokalne | Potencialne | Potencialne |

#### Validation command

| Command | MCP pouziti | Tracker MCP | Source control MCP |
|---------|------------|-------------|-------------------|
| `check-setup` | Connectivity test — query tracker (1 result), list repos | Ano | Ano |

#### Commands BEZ MCP zavislosti (6 z 22)

| Command | Proc nepotrebuje MCP |
|---------|---------------------|
| `version-bump` | Pracuje jen s plugin.json/marketplace.json + git |
| `version-check` | Git ls-remote + lokalni soubory |
| `migrate-config` | Cte/edituje CLAUDE.md lokalne |
| `onboard` | Wizard — generuje konfiguraci lokalne |
| `template` | Cte sablony z `examples/configs/` |
| `scaffold-validate` | Build/test/lint — lokalni operace |

### MCP Server Detection reference

`docs/reference/trackers.md` obsahuje tabulku **MCP Server Detection**, kterou jiz `check-setup` pouziva (Block 2, krok 7):

| Tracker | Keywords in .mcp.json | Package |
|---------|----------------------|---------|
| youtrack | `youtrack` | `@vitalyostanin/youtrack-mcp` |
| github | `github` | `@modelcontextprotocol/server-github` |
| jira | `jira` or `atlassian` | `@modelcontextprotocol/server-atlassian` |
| linear | `linear` | `@modelcontextprotocol/server-linear` |
| gitea | `gitea` or `forgejo` | `forgejo-mcp` |
| redmine | `redmine` | `mcp-server-redmine` |

Tato tabulka je klicova pro jakykoliv pre-flight check — umoznuje detekovat, zda je MCP server pro dany tracker nakonfigurovany.

---

## Co CLAUDE-agents MUZE ovlivnit

CLAUDE-agents je **plugin z markdown souboru**. Nema runtime kod, nemuze spoustet daemon, nemuze modifikovat Claude Code startup. Plugin muze pouze:

1. **Instruovat agenty** jak a kde hledat tokeny (v command/agent textu)
2. **Validovat** pres `check-setup` (read-only)
3. **Dokumentovat** spravny setup
4. **Generovat** `.mcp.json` pres onboard wizard

## Co CLAUDE-agents NEMUZE ovlivnit

1. Kde Claude Code hleda `.mcp.json`
2. Jak Claude Code startuje MCP servery
3. Discovery logiku Claude Code platformy
4. Environment variable predavani do MCP serveru

---

## Navrhovane pristupy

### Pristup A: Lepsi dokumentace (quick win)

Pridat do `docs/guides/mcp-configuration.md`:

```markdown
## Important: .mcp.json Location

`.mcp.json` MUST be in the directory where you start Claude Code.
Claude Code loads `.mcp.json` from its startup directory (CWD) only.

- Correct: `/my-project/.mcp.json` -> start Claude Code in `/my-project/`
- Wrong: `/my-project/packages/web/.mcp.json` -> Claude Code won't find it
- Wrong: `/home/user/.mcp.json` -> not loaded unless you start from ~

For monorepos: place `.mcp.json` in the repository root,
even if you work primarily in a subdirectory.
```

**Effort:** S
**Impact:** Preventivni, neresi existujici broken setups

### Pristup B: Check-setup vylepseni

Rozsirit `check-setup.md` o:

```markdown
### Block 2a: .mcp.json discovery (diagnostic)

6a. If .mcp.json NOT found in CWD:
    - Search parent directories (up to git root or 3 levels)
    - Search common subdirectories (packages/*, apps/*)
    - If found elsewhere:
      [WARN] ".mcp.json found at {path} but NOT in CWD ({cwd}).
             Claude Code only loads .mcp.json from CWD.
             Fix: copy or symlink to {cwd}/.mcp.json"
    - If not found anywhere:
      [FAIL] "No .mcp.json found. Run /CLAUDE-agents:onboard to create one."
```

**Effort:** M
**Impact:** Diagnosticky — pomuze uzivateli najit problem

### Pristup C: Onboard wizard generuje `.mcp.json` v CWD

(Viz dokument 02 — integrovat MCP setup do onboardu)

**Effort:** M-L
**Impact:** Preventivni — novy uzivatel dostane `.mcp.json` na spravne misto

### Pristup D: Config klic pro explicitni cestu k `.mcp.json`

Pridat do Automation Config:
```
| MCP config path | .mcp.json |
```

Commands by pak hledaly `.mcp.json` na zadane ceste.

**PROBLEM:** Toto je **koncepcne vadne**. CLAUDE-agents nemuze ovlivnit, odkud Claude Code nacita `.mcp.json`. I kdybychom znali cestu, nemuzeme rict platforme, aby ji pouzila.

**Effort:** N/A (neimplementovatelne)

---

## Srovnavaci tabulka

| Pristup | Effort | Impact | Resi root cause? | Implementovatelne? |
|---------|--------|--------|-------------------|-------------------|
| A: Dokumentace | S | Nizky (preventivni) | Ne | Ano |
| B: Check-setup diagnostika | M | Stredni (diagnosticky) | Castecne | Ano |
| C: Onboard generuje .mcp.json | M-L | Vysoky (preventivni) | Ano (pro nove projekty) | Ano |
| D: Config klic | — | — | — | **Ne** |

### Doporuceni: Kombinace A + B + C

1. **A (S):** Ihned — lepsi dokumentace k umisteni `.mcp.json`
2. **B (M):** Patch release — check-setup diagnostika pro existujici uzivatele
3. **C (M-L):** Minor release — onboard generuje `.mcp.json` (navazuje na dokument 02)

---

## Riziko duplicity logiky: check-setup vs. inline pre-flight

Pokud by se zavedl inline pre-flight check do pipeline commands (fix-bugs, fix-ticket, implement-feature), existuje riziko, ze se validacni logika roztristeni mezi dva ruzne mechanismy:

1. **check-setup** (Block 2+3) — plna validace MCP serveru a konektivity
2. **Inline pre-flight** v pipeline commands — rychla kontrola pred spustenim pipeline

### Analyza rizika

| Aspekt | check-setup | Inline pre-flight |
|--------|-------------|-------------------|
| Kdy se spousti | Manualne, pred prvnim pouzitim | Automaticky pred kazdym pipeline run |
| Rozsah | Plny (config + MCP + connectivity + build) | Jen MCP dostupnost |
| Rychlost | Pomale (build/test) | Rychle (jen MCP ping) |
| Udrzba | Jeden soubor | Logika rozptylena v N commands |

### Mozna reseni

**Reseni 1: check-setup --preflight (nove)** — Pridat do check-setup novy flag `--preflight`, ktery spusti POUZE Block 2 (MCP presence) + Block 3 (connectivity). Pipeline commands by pak volaly `/CLAUDE-agents:check-setup --preflight` jako prvni krok. Logika zustane v jednom souboru.

**Reseni 2: Sdileny pre-flight blok v CLAUDE.md** — Definovat pre-flight kroky v pluginovem CLAUDE.md a commands by na ne odkazovaly. Problem: CLAUDE.md neni command, neda se volat.

**Reseni 3: Zjednoduseny inline check** — Kazdy pipeline command si na zacatku overi jen `mcp__*` tool availability (jeste pred ctenim issue). Pokud tool neexistuje, zobrazi: "MCP server for {type} not available. Run /CLAUDE-agents:check-setup for diagnostics." Toto neni duplicita — je to jen guard clause, plna diagnostika zustava v check-setup.

**Doporuceni:** Reseni 3 (guard clause) je nejcistsi. Minimalni duplicita, jasne oddelene zodpovednosti.

---

## Cross-platform specifika

| Aspekt | Windows | Linux | macOS |
|--------|---------|-------|-------|
| CWD path separator | `\` i `/` fungují | Pouze `/` | Pouze `/` |
| Claude Code `.mcp.json` loading | CWD | CWD | CWD |
| Forgejo MCP server | `.exe` binarka | ELF binarka | Mach-O binarka |
| Forgejo binary varianta | `forgejo-mcp.exe` | `forgejo-mcp` (+ `chmod +x`) | `darwin-amd64` nebo `darwin-arm64` |
| Symlinky | NTFS junction / mklink | nativni | nativni |
| Case sensitivity paths | Ne | Ano | Ne (default) |

Hlavni cross-platform problem: **cesta k Forgejo MCP binarce** v `.mcp.json` musi odpovidat OS. Onboard wizard by mel detekovat OS a generovat spravnou cestu.

### Token discovery na ruznych platformach

Token discovery je v praxi platform-agnosticke — `.mcp.json` je JSON soubor, ktery se nacita z CWD na vsech platformach stejne. Rozdily jsou pouze:

1. **Cesta k MCP binarce** — OS-specificka (viz tabulka vyse)
2. **Systemove env vars** — Na vsech platformach se dedi z parent procesu, ale format se lisi (Windows: `%VAR%`, Unix: `$VAR`). V `.mcp.json` se pouziva format `${VAR}`, ktery Claude Code zpracovava na vsech platformach stejne.
3. **User-level .mcp.json** — Platformova dokumentace Claude Code uvadi moznost globalni konfigurace v `~/.claude/.mcp.json`. Toto tvrzeni neni overitelne z codebase CLAUDE-agents. Pokud je podporovano, muze to byt alternativni reseni pro monorepo scenare (jedno misto, vice projektu).

---

## Rozhodovaci otazky

1. **Je dokumentace dostatecny fix, nebo chces i diagnostiku v check-setup?**

2. **Ma check-setup hledat `.mcp.json` v parent directories jako diagnostiku?** (Existujici chovani: hleda jen v project root.)

3. **Ma onboard generovat `.mcp.json`?** (Viz dokument 02 — souvisi.)

4. **Chces pridat do closing message onboardu explicitni warning?**
   ```
   IMPORTANT: Start Claude Code from {CWD} to load .mcp.json correctly.
   ```

5. **Ma check-setup rozlisovat "MCP server not configured" vs "MCP server configured but not running"?** (Dnes jen hlasi FAIL bez rozliseni priciny.)

6. **Ma pre-flight check pokryvat vsech 16 MCP-zavislych commands, nebo jen 4 pipeline commands (fix-bugs, fix-ticket, implement-feature, resume-ticket)?**

   Argumenty pro pipeline-only:
   - Pipeline commands jsou jedine, ktere meni kod a issue tracker stav — selhani uprostred je drazsi
   - Analysis commands (analyze-bug, status, ...) selzou okamzite a uzivatel vi proc
   - 4 commands = nizsi udrzba

   Argumenty pro vsech 16:
   - Konzistentni uzivatelska zkusenost
   - I analysis commands (dashboard, metrics) mohou byt frustrujici kdyz selzou bez vysvetleni
   - Guard clause (Reseni 3) je jednoradkovy — overhead je minimalni

7. **Je tohle patch (jen docs) nebo minor (check-setup diagnostika)?**

---

