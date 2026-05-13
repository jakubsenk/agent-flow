# Unified Improvements Summary

Souhrnny dokument pokryvajici 6 identifikovanych oblasti pro zlepseni CLAUDE-agents pluginu. Cross-referencuje brainstorm dokumenty 01-06 a slouzi jako rozhodovaci podklad.

## Severity Matrix

| # | Tema | Severity | Complexity | Impact oblast | Primarni dotcene soubory |
|---|------|----------|------------|---------------|--------------------------|
| 1 | Forgejo MCP wrong URL + CLAUDE-agents: prefix analyza | Medium | S | Dokumentace, DX | `docs/guides/mcp-configuration.md`, `docs/guides/installation.md`, `examples/mcp-configs/gitea.json`, `docs/reference/trackers.md` |
| 2 | Onboard wizard -- pridat MCP token setup | High | M | First-run experience, DX | `commands/onboard.md`, `docs/guides/tokens.md`, `docs/guides/mcp-configuration.md` |
| 3 | Onboard -- directory scope bug (zapis mimo CWD) | Critical | S-M | Bezpecnost, datova integrita | `commands/onboard.md`, `commands/migrate-config.md` |
| 4 | Scaffold -- nekompletni aplikace, zavislost na issue trackeru | Medium | L | Scaffold pipeline, UX | `commands/scaffold.md`, `agents/scaffolder.md`, `commands/scaffold-validate.md`, `commands/scaffold-add.md` |
| 5 | Fix-bugs -- selhani pri discovery tokenu | High | M | Bug-fix pipeline, spolehlivost | `commands/fix-bugs.md`, `commands/fix-ticket.md`, `commands/implement-feature.md`, `commands/check-setup.md` |
| 6 | Session resume -- opetovne vyzadovani opravneni | Medium | S | UX, resume pipeline | `commands/resume-ticket.md`, `docs/guides/troubleshooting.md` |

## Detailni analyza jednotlivych temat

### 1. Forgejo MCP wrong URL + CLAUDE-agents: prefix analyza

**Stav:** V dokumentaci jsou 2 oddelene problemy:

**Problem A — Potencialne chybna URL:** V dokumentaci je pouzivana URL `codeberg.org/forgejo/forgejo-mcp/releases`. Puvodni brainstorm (doc 01) tvrdil, ze spravna URL je `codeberg.org/goern/forgejo-mcp/releases`, ale toto tvrzeni nebylo overeno a retezec `goern` se v celem codebase nevyskytuje nikde krome brainstorm 01. Vsechny zdrojove soubory (vcetne historickych design dokumentu) konzistentne pouzivaji `forgejo/forgejo-mcp`.

> **Status: Neovereno, vyzaduje overeni u upstream Codeberg registru.** Pred jakoukoli opravou je nutne: (1) overit na Codeberg, zda existuje `codeberg.org/forgejo/forgejo-mcp`, (2) overit, zda existuje `codeberg.org/goern/forgejo-mcp`, (3) zjistit, ktery je aktivne udrzovany a obsahuje releases. Teprve po overeni lze rozhodnout o oprave.

**Problem B — UX rozdil:** Gitea/Forgejo konfigurace pouziva `<path-to-binary>/forgejo-mcp` — to je spravne jako placeholder, ale pro uzivatele matouci ve srovnani s ostatnimi trackery (youtrack, github, jira, linear, redmine), ktere pouzivaji `npx` a nepotrebuji absolutni cestu k binarce.

Dalsi dotcene soubory: `examples/mcp-configs/gitea.json` (stejny `<path-to-binary>/forgejo-mcp` pattern) a `docs/reference/trackers.md` (MCP Server Detection tabulka).

**CLAUDE-agents: prefix:** Analyza vsech 22 commands ukazuje, ze prefix `CLAUDE-agents:` se pouziva ve 2 kontextech:
1. **V slash command referencich** (spravne): `/CLAUDE-agents:fix-ticket`, `/CLAUDE-agents:check-setup` atd. — 10 commands, 34 vyskytu.
2. **V agent Task tool volanich** (spravne): `CLAUDE-agents:triage-analyst`, `CLAUDE-agents:fixer` atd.

**Kolizni riziko — detailni analyza 22 commands:**

| Kategorie | Commands | Pocet |
|-----------|----------|-------|
| Genericke nazvy (VYSOKE riziko kolize) | `changelog`, `dashboard`, `estimate`, `metrics`, `onboard`, `publish`, `status`, `template`, `scaffold`, `prioritize` | ~10 |
| Specificke nazvy (NIZKE riziko) | `analyze-bug`, `fix-bugs`, `fix-ticket`, `implement-feature`, `resume-ticket`, `scaffold-add`, `scaffold-validate`, `migrate-config` | ~8 |
| Hranicni | `check-setup`, `create-pr`, `version-bump`, `version-check` | ~4 |

Klicovy zaver: Prefix je pravdepodobne **platform-enforced** — toto je **hypoteza zalozena na pozorovani chovani, ne overeny fakt** (viz doc 01: "Zda je prefix 'platform-enforced' je hypoteza, nikoli overeny fakt"). Na tomto predpokladu stoji cela analyza prefixu. S rostoucim ekosystemem pluginu roste riziko kolizi u generickych nazvu. Uzivatel muze vyuzit tab-complete (`/CL<tab>`) nebo skill routing (natural language pristup).

**Dopad:** Medium — pokud je URL chybna, uzivatel stahne binarku z neexistujiciho repa. Pokud je URL spravna, problem se omezuje na UX nesoulad s ostatnimi trackery. Fix URL je trivialni, ale vyzaduje externi overeni jako prerequisite.

### 2. Onboard wizard -- pridat MCP token setup

**Stav:** Aktualni onboard wizard (`commands/onboard.md`) ma 10 kroku (Step 0 az Step 9):
- Krok 0: Detection & Routing (fresh/update mod)
- Krok 1: Template Offer
- Krok 2: Issue Tracker (typ, URL, projekt, query, stavy)
- Krok 3: Source Control
- Krok 4-5: PR Rules, Build & Test
- Krok 6: Optional sections
- Krok 7: Generate Automation Config
- Krok 8: Output Options (print vs write to CLAUDE.md)
- Krok 9: Closing message — "Configure MCP servers (see docs/guides/mcp-configuration.md)"

**Problem:** Mezi krokem 8 (Output Options) a krokem 9 (closing message) chybi kriticka cast — uzivatel ma vsechny konfiguracni hodnoty, ale nema nastavenou `.mcp.json` s tokeny. Musi rucne cist 2 oddelene dokumenty (`tokens.md` + `mcp-configuration.md`) a rucne vytvorit `.mcp.json`.

**Navrhovane reseni — 3 varianty umisteni:**

**Varianta A (doporucena): Novy krok 8a** — mezi Step 8 (Output Options) a Step 9 (Closing Message):
- Na zaklade zvolenoho Type z kroku 2 nabidnout generovani `.mcp.json`
- Zobrazit presne instrukce pro ziskani tokenu (cist z `docs/guides/tokens.md` — sekce odpovidajici zvolenemu trackeru)
- Nabidnout automaticky zapis `.mcp.json` (s tokeny jako placeholdery `<YOUR_TOKEN>`)
- Pro Gitea/Forgejo: pridat instrukce ke stazeni binary
- Vytvorit `.mcp.json.example` (bez tokenu, commitovatelny)
- Pridat `.mcp.json` do `.gitignore` (pokud tam jeste neni)

**Varianta B: Samostatny command `/CLAUDE-agents:setup-mcp`** — volany z closing message onboardu. Pro: separace zodpovednosti. Proti: uzivatel muze zapomenout spustit.

**Varianta C: Hybrid do Step 2** — hned po vyberu tracker type se zepta na token a URL. Pro: kontextove nejlogictejsi. Proti: misi Automation Config (CLAUDE.md) s MCP config (.mcp.json).

**Rozsah MCP setupu — 3 moznosti:** (1) Jen tokeny (minimalni), (2) Plny MCP setup (vsechno), (3) Hybrid (doporucen) — default automaticky, `c` pro customizaci.

**Sdileny MCP server pro tracker + source control:** Gitea a GitHub pouzivaji STEJNY MCP server pro issue tracker i source control (Gitea tracker + Gitea hosting → obe `forgejo-mcp`; GitHub tracker + GitHub hosting → obe `server-github`). Wizard nesmi v tomto pripade server v `.mcp.json` duplikovat — pokud tracker a source control sdileji server, staci jedina konfigurace.

**Chybejici `redmine.json` template:** V `examples/mcp-configs/` chybi `redmine.json` (existuje youtrack.json, github.json, gitea.json, jira.json, linear.json, ale ne Redmine). Vytvoreni `redmine.json` je **povinny prerequisite** pro implementaci wizard generovani `.mcp.json`.

**Technicka omezeni:**
- Onboard ma `allowed-tools: Read, Glob, Write, Edit` — **NEMA Bash ani mcp__***
- OS detekce pro Forgejo binarku musi byt formou otazky uzivateli (ne programaticky)
- Validace konektivity primo v onboardu by vyzadovala rozsireni allowed-tools o `mcp__*`

**Rizikovost:** Tokeny v `.mcp.json` — wizard NESMI zapsat skutecne tokeny do CLAUDE.md. Muze vytvorit template a pozadat uzivatele o rucni vlozeni. `.mcp.json` nesmi byt v gitu.

### 3. Onboard -- directory scope bug (zapis mimo CWD)

**Stav:** Onboard wizard ma v `allowed-tools: Read, Glob, Write, Edit`. V kroku 0 cte "target project's CLAUDE.md", ale **nikde explicitne neomezuje cestu na CWD**. V kroku 8 (Fresh mode) zapisuje do CLAUDE.md:
- "append to the end of CLAUDE.md" — ale nespecifikuje, ze to musi byt `./CLAUDE.md`

**Problem:** Fráze "target project's CLAUDE.md" je vagni — nechava na modelu, kam zapise. Pokud CLAUDE.md neexistuje v CWD, model muze najit jednu o uroven vys a zapsat tam. Toto je bezpecnostni riziko — naruseni konfigurace jineho projektu.

**Rozsah problemu je sirsi nez jen onboard:**
- `commands/migrate-config.md` pouziva STEJNOU vagni formulaci "Read the target project's CLAUDE.md" (radek 12) — ma identicky problem a mela by dostat stejny fix
- Celkem **7 commands** pouziva formulaci "target project's CLAUDE.md": `onboard`, `migrate-config`, `implement-feature`, `dashboard`, `estimate`, `prioritize`, `metrics` (dle doc 03, presna tabulka se 7 polozkami). Z toho 2 jsou write-capable (onboard, migrate-config) s vysokym rizikem, 1 (implement-feature) pise kod ale ne config, a 4 jsou read-only nebo pisuji jine soubory
- Update mode (Step U3) ma stejny problem — "Write to CLAUDE.md after confirmation" bez specifikace cesty, a je potencialne nebezpecnejsi kvuli parsovani a prepisu existujiciho configu

**Dulezite:** Navrzeny fix je **prompt-level constraint, ne technicky guard**. `allowed-tools: Write, Edit` umoznuje zapis kamkoli. Constraint se opira o instruovani modelu, ne o technicke omezeni.

**Navrhovane reseni (Varianta 1 + safety check, doporuceno):**

Pridat na zacatek onboard.md:
```markdown
## Scope

This command operates on the CLAUDE.md file in the CURRENT WORKING DIRECTORY.
- Target file: `./CLAUDE.md` (relative to CWD)
- If `./CLAUDE.md` does not exist: create it in CWD
- NEVER read or write CLAUDE.md outside of CWD
- NEVER traverse parent directories to find CLAUDE.md
```

Upravit Step 0, Step 8, Update mode Step U3 na explicitni `./CLAUDE.md`.

**Edge cases (z dokumentu 03):**

1. **Monorepo** — vice CLAUDE.md na ruznych urovnich. Reseni: vzdy CWD, poznamka o spusteni z kazdeho package adresare zvlast.
2. **Nested projects / submoduly** — CWD constraint funguje spravne.
3. **Symlinky** — pouzit resolved path pro display, operovat na CWD.
4. **Spusteni z podadresare (src/)** — **nejrelevantnejsi edge case**. CWD constraint zapise CLAUDE.md do `src/components/` — to je spatne. Vylepseni: heuristika pro detekci parent CLAUDE.md:
   ```
   If CWD is NOT a git root AND parent directories contain CLAUDE.md:
     "You're in a subdirectory. CLAUDE.md exists at {parent}/CLAUDE.md.
      Write here ({CWD}) or there ({parent})? [here/THERE]"
   ```
5. **Prazdny adresar** — vytvorit CLAUDE.md v CWD, doporucit `git init`.
6. **Spusteni z plugin directory** — uzivatel omylem spusti onboard z adresare CLAUDE-agents pluginu samotneho. CWD constraint by vedl k zapisu Automation Config do pluginoveho CLAUDE.md — to je nezadouci. Heuristika: pokud CWD obsahuje `.claude-plugin/plugin.json`, zobrazit warning a zeptat se uzivatele.
7. **`--fresh` flag a detekce** — v `--fresh` mode neexistuje heuristika pro nalezeni existujiciho CLAUDE.md — command rovnou prejde do Fresh mode. CWD constraint musi platit nezavisle na `--fresh`/`--update` flagech.

**Rozsah fixu:**

| Rozsah | Co zahrnuje | Release typ |
|--------|-------------|-------------|
| Minimalni | Scope sekce, explicitni CWD constraint, NEVER pravidlo | Patch |
| Rozsireny | Minimalni + heuristika pro subdirectory detekci + aplikace na `migrate-config.md` + check-setup kontrola s absolutni cestou | Minor |
| Systemovy | Rozsireny + sjednoceni formulace "target project's CLAUDE.md" → "Read Automation Config from CLAUDE.md" (nebo "Read from CLAUDE.md in the current working directory") napric vsech 7 postizenymi commands. Odstrani systemovou nekonzistenci — commands, ktere delaji totez, budou pouzivat stejny jazyk | Minor |

**Dopad:** Kriticky — scope fixu je vice nez "3 vety". Minimalni fix je cca 8-10 radku zmen (Scope sekce 4-5 radku + uprava Step 0 + uprava Step 8 + NEVER pravidlo). Rozsireny fix zahrnuje i migrate-config a heuristiku.

### 4. Scaffold -- nekompletni aplikace, zavislost na issue trackeru

**Stav:** Scaffold pipeline (`commands/scaffold.md`) generuje kompletni skeleton:
1. Stack-selector vybere technologii
2. Scaffolder generuje soubory vcetne CLAUDE.md s Automation Config
3. Validace (build, test, lint, CLAUDE.md check)
4. Git init

**5 identifikovanych gapu (proc jsou aplikace nekompletni):**

**Gap 1: Scaffold konci u kostry — nepokracuje k implementaci.** Mezi `/scaffold` a `/implement-feature` je manualni mezera. Uzivatel musi rucne vyplnit TODO v CLAUDE.md, rucne zalozit issues v issue trackeru, rucne spustit `/implement-feature` pro kazdy issue.

**Gap 2: Chybi code review.** Scaffold pouziva pouze 2 agenty (stack-selector, scaffolder). Scaffolder sam verifikuje build/test/lint (max 3 retries), ale **chybi code review** — nikdo nehodnosti kvalitu generovaneho kodu (ne jen zda se builduje). Neni fixer<->reviewer smycka.

**Gap 3: Issue tracker dependency blokuje autonomni pouziti.** `/implement-feature` **VYZADUJE Issue ID** jako povinny vstup. Bez nastaveneho issue trackeru nelze po scaffoldu pokracovat. Automaticky prechod scaffold -> implementace je NEMOZNY.

**Gap 4: Scaffolder nema kontext o pozadovanych features.** Uzivatel pise popis projektu ("REST API pro spravu uzivatelu s autentizaci a CRUD operacemi"), stack-selector z toho vybere tech stack, ale **tato informace o pozadovanych features se ZAHODI**. Scaffolder generuje generickou kostru bez ohledu na to, co uzivatel popsal. Toto je ROOT CAUSE problemu — i kdyby scaffold pokracoval k implementaci, ztrateny kontext o features by vedl k neuplne aplikaci.

**Gap 5: Spec-analyst a architect nejsou zapojeni.** Feature pipeline pouziva spec-analyst (strukturovana specifikace) a architect (architektura + task tree). Scaffold pipeline tyto agenty vubec nevola — prestoze by mohli z popisu projektu vygenerovat specifikace a architekturu jeste PRED scaffoldingem. Toto vysvetluje, PROC je kostra genericka — chybi analyticka faze.

**Navrhovane reseni — 4 pristupy:**

**Pristup A (jednoduchy):** Po scaffoldu automaticky spustit `/CLAUDE-agents:onboard` (s vylepsenim z tematu #2).

**Pristup B (konzervativni):** Scaffold vygeneruje kostru, pak automaticky vytvori issues v trackeru a spusti `/implement-feature`. Pro: znovupouzije existujici pipeline. Proti: neodstranuje zavislost na issue trackeru.

**Pristup C (minimalni):** Vylepsit Krok 6 (Report) — pridat explicitni navod "Run /CLAUDE-agents:onboard to complete Issue Tracker setup" jako prvni next step.

**Pristup D (hybridni, z doc 04):** `/scaffold` zustava jak je. Nova faze se aktivuje flagem `--implement`. Interni implementace vyuziva novy command `/scaffold-implement`, ktery `/scaffold` vola automaticky. Pro: zpetna kompatibilita, modularita, znovupouzitelnost. Proti: 2 command soubory k udrzbe.

**Scaffold v2 pipeline koncept (z doc 04):** Spojeni scaffold + feature pipeline bez issue trackeru:
```
Popis projektu → Stack-selector → Scaffolder → Validace → Git init
    → [NOVA FAZE] → Spec-analyst* (extrakce features z PUVODNIHO popisu)
    → Architect (architektura + task tree) → Plan display + user approval
    → Pro kazdou feature: Fixer <-> Reviewer → Test-engineer → Commit
    → Integracni testy → Final report → (volitelne) Publisher
```

Klicovy designovy bod: Fixer, reviewer a test-engineer issue tracker **NEPOTREBUJI** — pracuji s kontextem z orchestrujiciho commandu. Issue tracker je potreba pouze pro cteni vstupnich pozadavku (nahraditelne primym vstupem), stavove prechody (volitelny side effect) a block komenty (nahraditelne stdout reportem).

**Doplnujici uvahy (z doc 04 review):**
- Publisher ma STREDNI kriticnost vuci issue trackeru (aktivni side effect: nastavuje stav issue, pridava komentar s PR odkazem), ne NIZKOU
- Spec-analyst v kroku 6 postuje checkpoint komentar do issue trackeru — dalsi zavislost
- Interakce s existujicimi `/scaffold-add` a `/scaffold-validate` neni vyresena
- Rollback-agent chybi v navrhu — jak se rollback zachova, kdyz feature 3 z 5 selze?
- Existujici Decomposition config sekce (Max subtasks, Fail strategy, Commit strategy) muze kolidovat s novymi scaffold v2 limity
- **Architect na minimalni codebase:** Architect v kroku 2 cte existujici codebase, ale u cerstve scaffoldovaneho projektu je codebase minimalni (10-20 souboru kostry bez business logiky). Riziko: architect muze produkovat suboptimalni navrhy bez kontextu "realneho" kodu. Mitigace: architect DOSTANE scaffold output jako kontext; sekvencni implementace features znamena, ze architect pro feature 2+ uz vidi kod z feature 1; command musi zajistit explicitni instrukci respektovat existujici strukturu projektu

**Dopad:** Stredni — ovlivnuje prvni pouziti scaffoldu, ale nesouvi s runtime stabilitou.

### 5. Fix-bugs -- selhani pri discovery tokenu

**Stav:** `fix-bugs` pipeline (`commands/fix-bugs.md`) zacina krokem 1 (Fetch bugs) — pouziva MCP server pro dotaz na issue tracker. Pokud MCP server neni nastaven, token je neplatny nebo vyprsely:
- Pipeline selze na prvnim kroku s chybou od MCP serveru
- Zadny recovery mechanismus — cely run skonci
- `check-setup` (`commands/check-setup.md`) existuje jako separatni command a overuje konektivitu (Block 3, krok 9-10), ale **neni automaticky volan pred fix-bugs**

**Analyza soucasneho stavu:**
- `fix-bugs` cte config (Type, Retry Limits, Hooks...) ale **nevaliduje MCP konektivitu**
- `fix-ticket` ma stejny problem
- `implement-feature` ma stejny problem
- `analyze-bug` cte jen config existenci (krok 2), ne konektivitu — ale TAKE pouziva MCP pro triage (krok 3) a tedy TAKE trpi stejnym problemem
- Celkem **16 z 22 commands** pouziva `mcp__*` v `allowed-tools` — dotcene jsou i `dashboard`, `metrics`, `prioritize`, `estimate`, `status`, `changelog`, `create-pr`, `scaffold`, `scaffold-add`, `resume-ticket`, `publish`, `check-setup`

**Klicovy poznatek:** CLAUDE-agents **nema vlastni token discovery mechanismus**. Tokeny jsou ulozeny v `.mcp.json` a **Claude Code platforma** je zodpovedna za jejich nacitani. Plugin muze pouze instruovat agenty, validovat pres check-setup, dokumentovat, a generovat `.mcp.json`.

**Cross-platform specifika (z doc 05):**

| Aspekt | Windows | Linux | macOS |
|--------|---------|-------|-------|
| CWD path separator | `\` i `/` funguji | Pouze `/` | Pouze `/` |
| Forgejo MCP server | `.exe` binarka | ELF binarka | Mach-O binarka |
| Symlinky | NTFS junction / mklink | nativni | nativni |
| Case sensitivity paths | Ne | Ano | Ne (default) |

Hlavni cross-platform problem: cesta k Forgejo MCP binarce v `.mcp.json` musi odpovidat OS.

**Navrhovane reseni — 3 pristupy (doporucena kombinace A + B + C):**

**Pristup A (quick win):** Lepsi dokumentace k umisteni `.mcp.json` — sekce "Important: .mcp.json Location" v `docs/guides/mcp-configuration.md`.

**Pristup B (patch):** Rozsirit `check-setup.md` o diagnostiku — hledani `.mcp.json` v parent directories a subdirectories, actionable chybove hlasky.

**Pristup C (minor):** Onboard wizard generuje `.mcp.json` v CWD (navazuje na tema #2).

**Pristup D (ZAVRHNUT):** Config klic pro explicitni cestu k `.mcp.json` — **koncepcne vadny**. CLAUDE-agents nemuze ovlivnit, odkud Claude Code nacita `.mcp.json`. I kdybychom znali cestu, nemuzeme rict platforme, aby ji pouzila. Toto je dulezity negativni nalez (co NEDELAT).

**Pre-flight check vs automaticky check-setup:** Pro pipeline commands (fix-bugs, fix-ticket, implement-feature) je doporucen inline lightweight check — overit jen `.mcp.json` existenci + MCP konektivitu (1 testovaci dotaz). Check-setup zustava pro plnou validaci. Existujici reference na `docs/reference/trackers.md` MCP Server Detection tabulku lze vyuzit.

**Doporucene reseni — guard clause (z doc 05):** Doc 05 analyzuje 3 reseni pro riziko duplicity logiky (check-setup vs inline pre-flight) a explicitne doporucuje **Reseni 3 (zjednoduseny inline check jako guard clause)**: kazdy pipeline command si na zacatku overi jen `mcp__*` tool availability. Pokud tool neexistuje, zobrazi: "MCP server for {type} not available. Run /CLAUDE-agents:check-setup for diagnostics." Toto neni duplicita — je to jen guard clause, plna diagnostika zustava v check-setup. Minimalni duplicita, jasne oddelene zodpovednosti.

**Dopad:** Vysoky — primo ovlivnuje spolehlivost hlavni pipeline. Bez pre-flight checku uzivatel dostane kryptickou MCP chybu misto smysluplne hlasky.

### 6. Session resume -- opetovne vyzadovani opravneni

**Stav:** `resume-ticket` (`commands/resume-ticket.md`) detekuje checkpointy:
- `FRESH` / `POST_TRIAGE` / `POST_ANALYSIS` / `POST_FIX` / `POST_REVIEW` / `PUBLISHED` / `DECOMPOSE_PARTIAL`
- Detekce funguje pres `[CLAUDE-agents]` komentare v issue trackeru + git stav

**Problem:** Kdyz uzivatel spusti `resume-ticket` v nove Claude Code session:
1. MCP tool permissions se musi znovu schvalit (Claude Code bezpecnostni model)
2. Kazdy MCP tool call vyzaduje explicitni souhlas uzivatele
3. Pipeline s 5+ agenty muze vyzadovat desitky schvaleni

**Analyza:** Toto je **omezeni platformy Claude Code**, ne CLAUDE-agents pluginu. Plugin nema moznost:
- Predschvalit MCP tool permissions
- Cachovat permissions mezi sessions
- Obejit bezpecnostni model

Claude Code ma 4 mechanismy pro permissions:
1. **Session permissions** — docasne, plati jen pro aktualni session
2. **Project settings** (`.claude/settings.json`) — trvale per-project allowlisty
3. **Global settings** (`~/.claude/settings.json`) — trvale globalni
4. **`allowed-tools` ve frontmatter** — definuje scope dostupnych nastroju (scope omezeni, ne auto-approval)

**Bezpecnostni uvahy pro allowlisty (z doc 06):**

| Potreba | Doporuceny allowlist |
|---------|---------------------|
| Read-only analyza | `Read, Glob, Grep, mcp__{tracker}__*` |
| Plna pipeline | `Read, Write, Edit, Glob, Grep, Bash, mcp__{tracker}__*, mcp__{sc}__*` |
| Minimalni | `Read, Glob, Grep` + per-tool approval |

**VAROVANI:** Wildcard `mcp__*` povoluje VSECHNY MCP servery vcetne serveru z JINYCH pluginu — to je bezpecnostni riziko. Doporucit specificke allowlisty (`mcp__youtrack__*`, `mcp__gitea__*`) misto wildcardu.

**Navrhovane reseni (kombinace 4 moznosti):**

**Moznost 1 (ihned):** Pridat do `docs/guides/troubleshooting.md` sekci o permissions a `.claude/settings.json` konfiguraci.

**Moznost 2 (minor):** Onboard wizard generuje `.claude/settings.json` s allowlistem odpovidajicim zvolenym MCP serverum (navazuje na tema #2).

**Moznost 3 (diagnostika):** Pridat do `check-setup` kontrolu `.claude/settings.json` — zda obsahuje potrebne permissions. (Poznamka: scope creep risk — check-setup overuje pipeline readiness, ne platform config.)

**Moznost 4 (upstream report):** Overit, zda je chovani session permission reset ocekavane, nebo jde o bug v Claude Code. Pokud bug — reportovat na `github.com/anthropics/claude-code/issues`. Toto muze byt nejucinnejsi fix.

**Worktree paralelni mod a dopad na permissions (z doc 06):** Pri worktree paralelnim modu (`fix-bugs` Variant A) je permission problem nasobeny — kazdy paralelni Task muze vyzadovat samostatne schvaleni MCP tools. Pri `batch_size = 3` to znamena az 3x vice permission promptu. Pro uzivatele s worktree konfiguraci je `.claude/settings.json` s pre-approved permissions de facto **nutnost**, ne volba. Toto by melo byt zdurazneno v dokumentaci (troubleshooting.md i worktree sekci).

**Dopad:** Stredni — UX nevyhoda, ale ne blokujici. Reseni je omezene platformou.

## Dependency Graph

```
Tema 3 (CWD scope bug)
  |
  v
Tema 2 (Onboard MCP setup) -----> Tema 5 (Token discovery)
  |                                    |
  v                                    v
Tema 4 (Scaffold)              Tema 6 (Session resume)

Tema 1 (Forgejo URL) = nezavisle
```

**Vztahy:**
- **3 -> 2:** CWD bug musi byt opraven PRED pridanim MCP setupu do onboardu (jinak novy krok tez muze zapsat mimo CWD)
- **2 -> 5:** Pokud onboard spravne nastavuje `.mcp.json`, snizi se pocet token discovery selhani
- **2 -> 4:** Pokud onboard podporuje MCP setup, scaffold muze automaticky volat onboard po scaffoldu
- **5 -> 6:** Pre-flight check v fix-bugs by mel detekovat i expired tokens, coz je cast problemu session resume
- **1:** Nezavisle — dokumentacni zmena bez vazeb

## Doporucene poradi implementace

| Poradi | Tema | Duvod |
|--------|------|-------|
| 1. | #3 Onboard CWD scope bug | **Critical severity, S complexity (minimalni fix).** Bezpecnostni fix, zadne zavislosti. Quick win. Aplikovat i na `migrate-config.md`. |
| 2. | #5 Fix-bugs token discovery | **High severity, M complexity.** Primo zlepsuje spolehlivost hlavni pipeline. Nezavisi na #3, ale je prioritnejsi nez UX zlepseni. |
| 3. | #2 Onboard MCP token setup | **High severity, M complexity.** Po oprave #3 (bezpecnost CWD) lze bezpecne rozsirit onboard o MCP krok. Snizuje vyskyty #5. |
| 4. | #1 Forgejo MCP URL + docs | **Medium severity, S complexity.** Quick win, nezavisle. Vyzaduje externi overeni URL pred opravou. |
| 5. | #6 Session resume permissions | **Medium severity, S complexity.** Castecne reseno #2 a #5. Dokumentacni zmena + UX upozorneni + optional upstream report. |
| 6. | #4 Scaffold issue tracker dependency | **Medium severity, L complexity.** Nejvetsi effort, zavisi na #2 a #3. Resit az po stabilizaci onboardu. |

## Quick Wins vs Major Efforts

### Quick Wins (< 1 hodina prace)

| Tema | Co presne udelat | Efekt |
|------|-------------------|-------|
| #3 | Pridat `## Scope` sekci do `commands/onboard.md` (4-5 radku), upravit Step 0 a Step 8 na explicitni `./CLAUDE.md`, pridat NEVER pravidlo. Aplikovat na `migrate-config.md`. Celkem cca 8-10 radku zmen. | Eliminuje bezpecnostni riziko |
| #1 | Overit URL na Codeberg, opravit ve 2-4 souborech. Pridat poznamku o relativni vs absolutni ceste k forgejo-mcp. | Opravi nefunkcni odkaz, snizi zmateni novych uzivatelu |
| #6 | Pridat sekci do `docs/guides/troubleshooting.md` o permissions. Pridat tip o specifickych allowlistech (ne wildcard `mcp__*`). Zvazit upstream report. | Nastavi spravna ocekavani, zmirni UX problemy |

### Stredni Effort (2-4 hodiny)

| Tema | Co presne udelat | Efekt |
|------|-------------------|-------|
| #5 | Pridat pre-flight check do pipeline commands (fix-bugs, fix-ticket, implement-feature). Rozsirit check-setup o diagnostiku `.mcp.json` lokace. Pridat cross-platform poznamky. | Eliminuje krypticke MCP chyby |
| #2 | Pridat krok 8a do onboard wizardu (MCP template generovani + `.mcp.json.example`), krok 8b pro permissions setup. Resit technicka omezeni allowed-tools. | Kompletni first-run experience |

### Major Effort (1+ den)

| Tema | Co presne udelat | Efekt |
|------|-------------------|-------|
| #4 | Navrhnout a implementovat scaffold v2 (hybridni pristup D nebo monoliticky A). Resit 5 gapu, integraci spec-analyst/architect, rollback-agent v novem pipeline, interakci s scaffold-add/validate, a vztah k existujici Decomposition konfiguraci. | Plynulejsi scaffold-to-pipeline prechod, funkcni aplikace |

## Rozhodovaci otazky

### Tema #1: Forgejo MCP URL + docs

1. **Je URL `goern/forgejo-mcp` skutecne spravna?** Prerequisite — nutne externi overeni na Codeberg pred jakoukoli opravou.

2. **Opravit URL jen ve 2 aktivnich souborech, nebo i v historickych docs/plans/ souborech?** (Min. 5 vyskytu v archivnich dokumentech.)

3. **Chces pridat do dokumentace UX tip o tab-complete (`/CL<tab>`) pro prefix?**

### Tema #2: Onboard MCP token setup

4. **Kde v onboard flow umistit MCP setup?** Varianta A (Step 8a — po Output Options, Step 8b pro permissions), B (samostatny command), nebo C (integrovany do Step 2)?

5. **Ma onboard generovat `.mcp.json` s placeholder tokeny, nebo jen zobrazit instrukce?**
   - *Generovat:* Uzivatel ma soubor okamzite, staci vlozit token. `.mcp.json` nesmi byt v gitu (bezpecnost). Pridat `.mcp.json` do `.gitignore`.
   - *Jen instrukce:* Mene automatizovane, ale bezpecnejsi — uzivatel si vytvori soubor sam.

6. **Ma onboard generovat take `.mcp.json.example` (bez tokenu, commitovatelny)?**

7. **Jak resit Forgejo MCP binarku?** Wizard nema Bash v allowed-tools, nemuze detekovat OS programaticky. Ptat se uzivatele, nebo preskocit?

8. **Ma wizard v update modu umet aktualizovat existujici `.mcp.json`?** Merge logika je netrivialni — `.mcp.json` muze obsahovat servery nesouvísející s CLAUDE-agents (filesystem MCP, database MCP). Nesmi je smazat.

9. **Vyzaduje MCP setup rozsireni `allowed-tools` onboardu (pridani `mcp__*` pro validaci konektivity)?** Technicka blokovaci otazka.

### Tema #3: Onboard CWD scope bug

10. **CWD nebo git root jako default?** CWD je jednodussi a bezpecnejsi, ale git root je "spravnejsi" pro vetsinu projektu.

11. **Minimalni fix (patch — jen CWD constraint) nebo rozsireny fix (minor — heuristika pro subdirectory detekci)?** Doc 03 explicitne rozlisuje tyto dva pristupy. Klicovy edge case: uzivatel v `/project/src/components/` spusti onboard — minimalni fix zapise CLAUDE.md do spatneho mista.

12. **Ma se "target project's CLAUDE.md" sjednotit napric VSEMI commands?** Formulace je systemova (7 commands pouziva stejne vague vyjadreni — viz tabulka v doc 03). Tri urovne fixu: (A) jen write-capable commands (onboard, migrate-config) — minimalni scope, adresuje realne riziko; (B) sjednotit formulaci ve vsech 7 commands — systemova konzistence; (C) sjednotit ve vsech 22 commands — idealni konzistence, ale over-engineering pro commands, ktere uz funguji spravne.

13. **Opravit CWD bug jako standalone hotfix (patch release), nebo spojit s pre-flight checkem do jednoho minor releasu?**
    - **Doporuceni:** Standalone patch — je to bezpecnostni fix, nemel by cekat.

### Tema #4: Scaffold completeness redesign

14. **Ma `/scaffold` ve vychozim stavu implementovat features?**
    - **(a)** `--implement` je default — scaffold automaticky pokracuje k implementaci
    - **(b)** `--no-implement` je default — zpetna kompatibilita
    - **(c)** Interaktivni prompt: "Chcete implementovat features? [Y/n]"

15. **Architektura commandu:** Rozsirit stavajici `scaffold.md` o kroky 7-12, nebo novy command `scaffold-implement.md` (volaný scaffoldem / samostatne pouzitelny)?

16. **Limit na pocet features:** Max 3 (konzervativni) / 5 (kompromis) / 7 (shodne s Decomposition Max subtasks) / bez limitu?

17. **Spec-analyst vstup bez issue trackeru:** Command pripravi "fake issue" kontext (spec-analyst se nemeni), nebo pridat podminkovy krok do spec-analysta, nebo novy agent `feature-extractor`?

18. **Issue tracker optional globalne?** Pouze pro scaffold, nebo vsechny commandy funguji i bez issue trackeru (vetsi zmena)?

19. **Handling selhani uprostred implementace:** Fail-fast / skip-and-continue / konfigurovatelne (jako Decomposition Fail strategy)?

20. **Vztah k existujici Decomposition konfiguraci:** Ma scaffold v2 cist Decomposition sekci z CLAUDE.md (kterou sam vygeneroval), nebo mit hardcoded limity?

21. **Granularita commitu:** Kazda feature = 1 commit, nebo Commit strategy z Decomposition config (squash/individual)?

### Tema #5: Fix-bugs token discovery

22. **Pre-flight check vs automaticky check-setup:** Inline lightweight check (rychlejsi, overuje jen MCP konektivitu) nebo automaticky volat `/CLAUDE-agents:check-setup --skip-build` (bez duplikace, ale pomalejsi)?

23. **Ma pre-flight check pokryvat jen pipeline commands (fix-bugs, fix-ticket, implement-feature), nebo vsechny MCP-dependent commands (16 z 22)?** Zasadni architektonicke rozhodnuti.

24. **Ma check-setup rozlisovat "MCP server not configured" vs "MCP server configured but not running"?**

### Tema #6: Session resume permissions

25. **Ma onboard generovat `.claude/settings.json` s allowlistem?** Pokud ano — specificky (`mcp__youtrack__*`) nebo wildcard (`mcp__*`)?

26. **Chces reportovat upstream (Claude Code issue)?** Pokud `claude -c` by mel zachovat permission state ale nezachovava — to je bug nebo design decision?

27. **Ma `resume-ticket` detekovat nedostupne MCP nastroje a zobrazit actionable error PRED spustenim pipeline?** (Pre-flight check analogicky k tematu #5, ale specificky pro resume flow.)

