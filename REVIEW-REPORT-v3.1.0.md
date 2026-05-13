# Expertní Review Report — CLAUDE-agents v3.1.0

**Datum:** 2026-03-01
**Reviewer:** Claude Opus 4.6 (automated comprehensive review)
**Scope:** Kompletní repozitář — 13 agents, 22 commands, 1 skill, docs, tests, examples, metadata
**Status:** ALL FINDINGS RESOLVED

---

## Executive Summary

Plugin CLAUDE-agents v3.1.0 prošel kompletním 4-kolým review cyklem:

- **Round 1:** 75 nálezů (4 CRITICAL, 16 HIGH, 30 MEDIUM, 25 LOW) — all fixed
- **Round 2:** 2 nové nálezy (1 HIGH, 1 LOW) — all fixed
- **Round 3:** 3 nové nálezy (1 MEDIUM, 2 LOW) — all fixed
- **Round 4:** 0 nálezů — **CLEAN**

**Celkové hodnocení:** Všech 80 nálezů opraveno. Plugin je v konzistentním stavu — 2-vrstvá architektura dodržena, Config Contract aligned, MCP examples match docs, Block handlers kompletní, version-bump funkční, gitea jako 5. tracker type plně integrován.

---

## Statistiky

### Per Severity

| Severity | Počet |
|----------|-------|
| CRITICAL | 4 |
| HIGH | 16 |
| MEDIUM | 30 |
| LOW | 25 |
| **TOTAL** | **75** |

### Per Kategorie

| Kategorie | C | H | M | L | Total |
|-----------|---|---|---|---|-------|
| 1. Architektura & Design | 2 | — | 3 | — | 5 |
| 2. Prompt Engineering Quality | — | — | 5 | 7 | 12 |
| 3. Command Orchestration | 2 | 8 | 12 | 6 | 28 |
| 4. Config Contract | — | 1 | 5 | — | 6 |
| 5. Konzistence & Naming | — | — | 3 | 2 | 5 |
| 6. Skill & Plugin Metadata | — | — | 1 | 1 | 2 |
| 7. Dokumentace | — | 4 | 3 | 5 | 12 |
| 8. Testy | — | — | 2 | 1 | 3 |
| 9. Robustnost & Edge Cases | — | 3 | 4 | 2 | 9 |
| 10. Bezpečnost | — | — | 1 | 1 | 2 |

---

## CRITICAL (4)

### [CRITICAL-01] fix-bugs.md — Block handler nenastaví issue stav a nepostne Block Comment
- **Soubor:** `commands/fix-bugs.md` (řádky 269–284)
- **Kategorie:** 1. Architektura & Design
- **Popis:** Block handler (krok X) v `fix-bugs` spustí rollback-agent a pošle webhook, ale **nikdy nenastaví issue stav na Blocked** a **nikdy nepostne Block Comment Template** do issue trackeru. Srovnání s `implement-feature.md` krok X (řádky 249–263), který explicitně obsahuje: "Nastav issue stav na Blocked" + plný Block Comment Template. V `fix-bugs` chybí oba kroky.
- **Dopad:** Bugy, které selžou v pipeline, NEBUDOU označeny jako Blocked v issue trackeru. Ghost failures bez traceability.
- **Doporučení:** Přidat do kroku X: (1) `Nastav issue stav na Blocked (State transitions → Blocked)`, (2) `Přidej Block komentář do issue trackeru:` + plný template — matching `implement-feature.md` krok X.

### [CRITICAL-02] fix-ticket.md — Block handler nenastaví issue stav a nepostne Block Comment
- **Soubor:** `commands/fix-ticket.md` (řádky 257–270)
- **Kategorie:** 1. Architektura & Design
- **Popis:** Identický problém jako CRITICAL-01. Block handler má jen rollback + webhook, ale chybí nastavení stavu a Block Comment. Rollback-agent sice "posts block comment" dle své definice, ale command-level orchestrace by neměla spoléhat na agenta pro state change — command musí explicitně instruovat.
- **Dopad:** Pokud rollback-agent selže s MCP, issue zůstane v "In Progress" bez záznamu o selhání.
- **Doporučení:** Stejná oprava jako CRITICAL-01.

### [CRITICAL-03] version-bump.md — Git tag BEZ commitu
- **Soubor:** `commands/version-bump.md` (řádky 16–27)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Command zapisuje novou verzi do `plugin.json` (krok 4) a `marketplace.json` (krok 5), pak vytvoří git tag (krok 6), ale **neexistuje krok pro `git add` + `git commit`**. Tag se vytvoří na aktuálním HEAD, ale změny souborů nejsou commitnuté — tag ukazuje na PŘEDCHOZÍ stav, ne na version bump.
- **Dopad:** Kompletně nefunkční release workflow. Každý version bump přes tento command vytvoří tag na špatném commitu.
- **Doporučení:** Přidat krok mezi 5 a 6: `git add .claude-plugin/plugin.json .claude-plugin/marketplace.json && git commit -m "chore: bump version {stará} → {nová}"`. Případně přeuspořádat: (4) zapiš soubory, (5) commit, (6) tag.

### [CRITICAL-04] version-bump.md — Tag PŘED changelogem (porušuje vlastní release process)
- **Soubor:** `commands/version-bump.md` (řádek 25)
- **Kategorie:** 3. Command Orchestration
- **Popis:** I kdyby commit krok existoval, MEMORY.md explicitně říká: "NIKDY netagovat před changelogem! Tag musí být na finálním commitu." Tento command taguje PŘED jakýmkoli changelogem.
- **Dopad:** Porušení vlastního release process dokumentovaného v MEMORY.md. Tag vždy bude na špatném commitu pokud uživatel pak dopisuje changelog.
- **Doporučení:** Buď (a) přidat changelog step PŘED tag, nebo (b) odebrat tag krok z version-bump a nechat tagging na manuálním release procesu, nebo (c) přidat varování: "Tag vytvořen. Pokud plánujete changelog update, odstraňte tag a znovu vytvořte po finálním commitu."

---

## HIGH (16)

### [HIGH-01] resume-ticket.md — Nepodporuje feature tickety
- **Soubor:** `commands/resume-ticket.md` (řádek 59)
- **Kategorie:** 9. Robustnost & Edge Cases
- **Popis:** Command říká "použij stejné kroky jako `/fix-ticket`" pro všechny checkpointy, ale nikdy nedetekuje zda je ticket bug nebo feature. Feature tickety mají jiný pipeline (`implement-feature` se `spec-analyst` → `architect`), jiné čísla kroků, a jiné stage names.
- **Dopad:** Obnovení feature ticketu použije bug-fix pipeline místo feature pipeline. Špatné kroky, špatní agenti.
- **Doporučení:** Přidat detekci: pokud issue má spec checkpoint (`[CLAUDE-agents] Spec analýza dokončena.`) → použij `implement-feature` step mapping. Pokud triage checkpoint → použij `fix-ticket`.

### [HIGH-02] analyze-bug.md — Chybí validace $ARGUMENTS
- **Soubor:** `commands/analyze-bug.md` (řádek 8)
- **Kategorie:** 9. Robustnost & Edge Cases
- **Popis:** Command očekává issue ID v `$ARGUMENTS`, ale nikdy nevaliduje že je neprázdný. Při volání bez argumentů triage-analyst dostane prázdný kontext.
- **Doporučení:** Přidat krok 0: `Pokud $ARGUMENTS je prázdný → oznam: "Usage: /CLAUDE-agents:analyze-bug <ISSUE-ID>"`

### [HIGH-03] analyze-bug.md — Žádný guard na Automation Config / MCP
- **Soubor:** `commands/analyze-bug.md` (řádky 10–14)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Command říká "Čti Automation Config" ale nemá error handling pokud (a) CLAUDE.md neexistuje, (b) Automation Config sekce chybí, (c) MCP server pro tracker není dostupný.
- **Doporučení:** Přidat guard: ověř existenci CLAUDE.md a Automation Config s Issue Tracker Type před dispatchem agentů.

### [HIGH-04] fix-bugs.md — Nečte Error Handling config
- **Soubor:** `commands/fix-bugs.md` (řádky 16–30)
- **Kategorie:** 4. Config Contract
- **Popis:** Konfigurace section čte Worktrees a Decomposition, ale NEČTE `Error Handling` sekci (`On block`, `Max blocked per run`). Config Contract v CLAUDE.md definuje tyto klíče. Command by měl respektovat `Max blocked per run` pro zastavení po N blocích.
- **Dopad:** Pokud projekt konfiguruje `Max blocked per run: 3`, pipeline přesto zpracuje všechny bugy a plýtvá tokeny.
- **Doporučení:** Přidat Error Handling do Konfigurace sekce a implementovat `Max blocked per run` check v Block handler / smyčce.

### [HIGH-05] fix-ticket.md — Nečte Error Handling config (On block)
- **Soubor:** `commands/fix-ticket.md` (řádky 14–29)
- **Kategorie:** 4. Config Contract
- **Popis:** `On block` akce z Error Handling (může být `comment`, `close`, etc.) se nikdy nečte ani nepoužívá.
- **Doporučení:** Přidat Error Handling → On block do Konfigurace a implementovat v Block handler.

### [HIGH-06] implement-feature.md — Nečte Error Handling config
- **Soubor:** `commands/implement-feature.md` (řádky 10–27)
- **Kategorie:** 4. Config Contract
- **Popis:** Stejný pattern — Error Handling sekce se nečte.
- **Doporučení:** Přidat Error Handling reading do Konfigurace sekce.

### [HIGH-07] publish.md — Žádný guard proti publish bez změn
- **Soubor:** `commands/publish.md` (řádky 10–25)
- **Kategorie:** 9. Robustnost & Edge Cases
- **Popis:** Command nekontroluje zda existují skutečné změny k publishu. Pokud je volán na clean branch bez commitů nad base, pokusí se vytvořit prázdné PR.
- **Doporučení:** Přidat pre-flight check: ověř že current branch má commity nad base_branch.

### [HIGH-08] create-pr.md — Nepoužívá PR Description Template
- **Soubor:** `commands/create-pr.md` (řádky 1–17)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Command říká "Vytvoř PR dle PR Rules" ale nezmiňuje PR Description Template z Automation Config. PRs vytvořené tímto commandem nebudou sledovat project template.
- **Doporučení:** Přidat explicitní instrukci: použij PR Description Template z Automation Config.

### [HIGH-09] changelog.md — Nečte Automation Config
- **Soubor:** `commands/changelog.md` (řádky 1–57)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Changelog command vůbec nečte Automation Config. Používá přímo `git tag` a `git log`. Nezná Source Control → Remote ani Issue Tracker → Type, takže neví jaký MCP server použít pro PR detaily.
- **Doporučení:** Přidat čtení Automation Config (minimálně Source Control → Remote, Issue Tracker → Type).

### [HIGH-10] scaffold.md — Používá `git add -A`
- **Soubor:** `commands/scaffold.md` (řádek 80)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Krok 5 používá `git add -A`, což může přidat temp soubory, .env, IDE konfiguraci. Přestože scaffold je na čistém projektu, je to riziková praktika.
- **Doporučení:** Použít `git add .` s proper `.gitignore` generovaným scaffolderem, nebo explicitně listovat file patterns.

### [HIGH-11] YouTrack MCP — Nekonzistence package name mezi example a docs
- **Soubor:** `examples/mcp-configs/youtrack.json` (řádek 5) vs `docs/setup/mcp-configuration.md` (řádky 18, 38)
- **Kategorie:** 7. Dokumentace
- **Popis:** Example používá `@modelcontextprotocol/server-youtrack` s env `YOUTRACK_URL`. Setup guide používá `@vitalyostanin/youtrack-mcp` s env `YOUTRACK_BASE_URL`. Jsou to RŮZNÉ packages s různými env proměnnými. Uživatel sledující example dostane nefunkční konfiguraci oproti tomu co říká setup guide.
- **Doporučení:** Sjednotit na jeden package. Pokud `@vitalyostanin/youtrack-mcp` je ten testovaný, aktualizovat example. Pokud `@modelcontextprotocol/server-youtrack` je novější, aktualizovat docs.

### [HIGH-12] Gitea MCP — Nekonzistence package vs binary mezi example a docs
- **Soubor:** `examples/mcp-configs/gitea.json` (řádky 4–8) vs `docs/setup/mcp-configuration.md` (řádky 25–29)
- **Kategorie:** 7. Dokumentace
- **Popis:** Example používá `npx -y @modelcontextprotocol/server-gitea` s env `GITEA_TOKEN`/`GITEA_URL`. Setup guide popisuje binárku `forgejo-mcp` s env `FORGEJO_TOKEN`/`FORGEJO_URL`. Kompletně odlišné servery, odlišné env proměnné.
- **Doporučení:** Standardizovat. Buď nabídnout obě možnosti jasně označené, nebo sjednotit na jednu.

### [HIGH-13] `gitea` tracker type v example ale ne v kódu
- **Soubor:** `examples/configs/gitea-spring-boot.md` (řádek 10: `Type | gitea`) vs `CLAUDE.md` (řádek 103) vs `commands/check-setup.md` vs `commands/onboard.md`
- **Kategorie:** 4. Config Contract
- **Popis:** Example config používá `Type | gitea`, ale: (1) Config Contract v CLAUDE.md listuje jen `youtrack/github/jira/linear`, (2) `check-setup` nemá `gitea` case v per-tracker validaci, (3) `onboard` nenabízí `gitea` jako volbu. Uživatel s `Type: gitea` dostane warning "Unknown tracker type".
- **Doporučení:** Buď přidat `gitea` jako pátý podporovaný tracker type (CLAUDE.md, check-setup, onboard) NEBO změnit example na podporovaný type.

### [HIGH-14] v3.1 design doc — Status DRAFT ale v3.1.0 je released
- **Soubor:** `docs/plans/2026-03-01-v3.1-unified-design.md` (řádek 5)
- **Kategorie:** 7. Dokumentace
- **Popis:** Design dokument říká `Status: DRAFT` a `Aktuální verze: 3.0.1` ale v3.1.0 byla implementována a releasnuta (commit `a257f88`, tag `v3.1.0`).
- **Doporučení:** Aktualizovat status na `IMPLEMENTED`, verzi na `3.1.0`.

### [HIGH-15] fix-bugs.md — WebFetch v allowed-tools ale nikdy se nepoužívá
- **Soubor:** `commands/fix-bugs.md` (řádek 3)
- **Kategorie:** 3. Command Orchestration
- **Popis:** `allowed-tools` obsahuje `WebFetch` ale žádný krok nepoužívá web fetching. Zbytečné permission escalation.
- **Doporučení:** Odebrat `WebFetch` z allowed-tools.

### [HIGH-16] dashboard.md — Chybí Write tool v allowed-tools
- **Soubor:** `commands/dashboard.md` (řádek 3)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Command generuje HTML soubor (krok 8) ale nemá `Write` v allowed-tools. Místo toho používá Bash s `cat > file << 'EOF'`. Nekonzistentní s best practice pro file creation.
- **Doporučení:** Přidat `Write` do allowed-tools a použít Write tool, nebo explicitně zdokumentovat proč se používá Bash.

---

## MEDIUM (30)

### [MEDIUM-01] fixer.md — 100-řádkový diff limit je soft suggestion
- **Soubor:** `agents/fixer.md` (řádek 66)
- **Kategorie:** 2. Prompt Engineering Quality
- **Popis:** "Diff > 100 lines → reconsider approach" — měkké doporučení. Architect ale referuje totéž jako hard limit: "Each subtask MUST be <= 100 lines diff (fixer's hard limit)".
- **Doporučení:** Změnit na: "Diff MUST NOT exceed 100 lines — if approaching this limit, break the change into smaller steps or Block."

### [MEDIUM-02] priority-engine.md — Chybí handling pro prázdný backlog
- **Soubor:** `agents/priority-engine.md`
- **Kategorie:** 2. Prompt Engineering Quality
- **Popis:** Constraint "Max 50 issues" ale žádný handling pro 0 issues. Pokud query vrátí prázdný výsledek, agent nemá definované chování.
- **Doporučení:** Přidat: "If backlog query returns 0 issues, output 'No open issues found' and exit."

### [MEDIUM-03] architect.md — Chybí handling pro chybějící vstup
- **Soubor:** `agents/architect.md` (krok 1)
- **Kategorie:** 2. Prompt Engineering Quality
- **Popis:** Krok 1 říká "Read the specification" ale nedefinuje co dělat pokud specifikace chybí nebo je neúplná.
- **Doporučení:** Přidat: "If specification/impact report is missing, Block with 'Missing input from previous pipeline stage'."

### [MEDIUM-04] fixer.md — Chybí handling pro chybějící analýzu
- **Soubor:** `agents/fixer.md` (krok 1)
- **Kategorie:** 2. Prompt Engineering Quality
- **Popis:** Krok 1 říká "Read the triage analysis and impact report thoroughly" ale žádný fallback pokud chybí.
- **Doporučení:** Přidat: "If triage analysis or impact report is missing, Block with 'Missing input from previous pipeline stage'."

### [MEDIUM-05] priority-engine.md — Block Comment Template chybí inline
- **Soubor:** `agents/priority-engine.md` (řádek 67)
- **Kategorie:** 2. Prompt Engineering Quality
- **Popis:** Říká "use Block Comment Template" ale NEOBSAHUJE šablonu inline jako všichni ostatní agenti. Všech 10 dalších agentů s BCT má plný template s agent-specific poli.
- **Doporučení:** Přidat plný inline template s `Agent: priority-engine`, `Krok: Backlog Prioritization`.

### [MEDIUM-06] create-pr.md — Nepoužívá publisher agenta
- **Soubor:** `commands/create-pr.md` (řádky 1–17)
- **Kategorie:** 1. Architektura & Design
- **Popis:** `create-pr` vytváří PR přímo přes Bash/MCP, zatímco `publish` dispatchuje `publisher` agenta. Dvě různé cesty pro PR creation s potenciálně odlišným chováním (labels, template, description).
- **Doporučení:** Buď (a) dispatchovat publisher agenta i z `create-pr`, nebo (b) dokumentovat záměrný rozdíl (create-pr = lightweight, publish = full pipeline).

### [MEDIUM-07] status.md — Nečte Feature Workflow config
- **Soubor:** `commands/status.md` (řádky 12–33)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Command čte Bug query states ale nikdy nezmiňuje Feature Workflow query. Feature issues v aktivních stavech budou chybět ve status přehledu.
- **Doporučení:** Přidat Feature Workflow → Feature query čtení.

### [MEDIUM-08] fix-bugs/fix-ticket/implement-feature — Nečtou Extra labels
- **Soubor:** `commands/fix-bugs.md`, `commands/fix-ticket.md`, `commands/implement-feature.md`
- **Kategorie:** 4. Config Contract
- **Popis:** Žádný z hlavních pipeline commands nečte `Extra labels` z Automation Config. Tato config sekce se nikdy nepředá publisherovi.
- **Doporučení:** Přidat Extra labels čtení a předání do publisher context.

### [MEDIUM-09] estimate.md — Reference na neexistující verzi 3.1.4
- **Soubor:** `commands/estimate.md` (řádek 68)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Krok 7 říká "Pokud `/metrics` report existuje (z 3.1.4)" — verze 3.1.4 neexistuje. Aktuální je 3.1.0.
- **Doporučení:** Odstranit verzi referenci nebo opravit.

### [MEDIUM-10] check-setup.md — Nevaliduje v3.1 optional sekce
- **Soubor:** `commands/check-setup.md` (řádky 59–63)
- **Kategorie:** 4. Config Contract
- **Popis:** Krok 5 validuje optional sekce ale seznam neobsahuje `Decomposition`, `Pipeline Profiles`, `Metrics`, `Feature Workflow` — všechny přidané v v3.0/v3.1.
- **Doporučení:** Přidat chybějící sekce do validation listu.

### [MEDIUM-11] onboard.md — Hardcoded pipeline profile presets
- **Soubor:** `commands/onboard.md` (řádky 62–75)
- **Kategorie:** 1. Architektura & Design
- **Popis:** Command obsahuje definice profilů (fast, strict, minimal) s konkrétními stage konfiguracemi. To je agent-level znalost v command.
- **Doporučení:** Přesunout profile presets do example/template souboru a referovat z commandu.

### [MEDIUM-12] migrate-config.md — Křehká heuristika detekce verze
- **Soubor:** `commands/migrate-config.md` (řádky 18–21)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Detekce verze config závisí na přítomnosti sekcí: "Jen Issue Tracker + Source Control → v1.x". Selže pokud v1.x config má Pipeline Profiles z manuálního přidání.
- **Doporučení:** Zvážit přidání `Config-Version: v3.1` klíče do Automation Config formátu, nebo zdokumentovat omezení heuristiky.

### [MEDIUM-13] fix-bugs.md — Triage paralelismus odkazuje na batch_size z Worktree config
- **Soubor:** `commands/fix-bugs.md` (řádek 62)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Krok 2 říká "(paralelně, max batch_size)" ale batch_size je Worktree config. V sekvenčním módu (žádné worktrees) batch_size neexistuje. Triage je read-only a může být vždy paralelní.
- **Doporučení:** Oddělit triage paralelismus od worktree config.

### [MEDIUM-14] fix-bugs.md — Block handler chybí worktree path context
- **Soubor:** `commands/fix-bugs.md` (řádky 273–274)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Rollback-agent context neobsahuje worktree path. `fix-ticket` má "Kontext spuštění: CWD (bez worktree)" ale `fix-bugs` při worktree módu nemá ekvivalent.
- **Doporučení:** Přidat: "Kontext spuštění: {worktree_path} (pokud worktree) | CWD (pokud sekvenční)."

### [MEDIUM-15] fix-bugs.md — Step numbering nekonzistentní s fix-ticket
- **Soubor:** `commands/fix-bugs.md` (řádky 62–205)
- **Kategorie:** 5. Konzistence & Naming
- **Popis:** fix-bugs kroky jdou 1, 2, 3, 3a-3d, 4, 5, 5a-5b... fix-ticket používá 1–9 + X s sub-kroky. Různé číslování ztěžuje cross-referenci a resume-ticket mapping.
- **Doporučení:** Sladit číslování kroků mezi fix-ticket a fix-bugs pro sdílenou pipeline část.

### [MEDIUM-16] scaffold.md — `rm -rf $SCAFFOLD_TEMP` bez safety check
- **Soubor:** `commands/scaffold.md` (řádek 72)
- **Kategorie:** 10. Bezpečnost
- **Popis:** Krok 4 spouští `rm -rf $SCAFFOLD_TEMP` bez ověření že proměnná je nastavena a ukazuje na temp directory. Pokud `mktemp -d` selhal, mohl by smazat nechtěný adresář.
- **Doporučení:** Přidat guard: ověř `$SCAFFOLD_TEMP` je neprázdný a začíná cestou k systémovému temp adresáři.

### [MEDIUM-17] publish.md — Nekontroluje existenci PR
- **Soubor:** `commands/publish.md` (řádky 10–25)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Command nevyhlédne existující PR pro aktuální branch před vytvořením nového. Dvojí spuštění vytvoří duplicitní PR.
- **Doporučení:** Přidat: kontrola existujícího otevřeného PR pro branch před vytvořením.

### [MEDIUM-18] resume-ticket.md — DECOMPOSE_PARTIAL má prioritu nad PUBLISHED
- **Soubor:** `commands/resume-ticket.md` (řádky 37–44)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Detekční logika dává DECOMPOSE_PARTIAL nejvyšší prioritu. Pokud issue bylo dekompozováno A již má PR (PUBLISHED), resume command zkusí pokračovat v dekompozici místo rozpoznání že pipeline je hotová.
- **Doporučení:** Kontrolovat PUBLISHED stav jako první, pak DECOMPOSE_PARTIAL.

### [MEDIUM-19] analyze-bug.md — Chybí triage checkpoint comment instrukce
- **Soubor:** `commands/analyze-bug.md` (řádky 12–14)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Command dispatchuje triage-analyst ale neinstruuje ho zapsat checkpoint komentář (`[CLAUDE-agents] Triage dokončen.`). Dashboard a resume-ticket nedetekují triage z tohoto commandu.
- **Doporučení:** Přidat instrukci: po úspěšném triage postni checkpoint komentář do issue trackeru.

### [MEDIUM-20] v3.1 design doc — Říká 12 agentů místo 13
- **Soubor:** `docs/plans/2026-03-01-v3.1-unified-design.md` (řádek 56)
- **Kategorie:** 5. Konzistence & Naming
- **Popis:** "12 specializovaných agentů" ale v3.1 má 13 (priority-engine přidán). Summary v tomtéž dokumentu správně říká 13.
- **Doporučení:** Opravit na "13 specializovaných agentů".

### [MEDIUM-21] Roadmap design doc — APPROVED ale superseded
- **Soubor:** `docs/plans/2026-02-28-v3.1-v5.0-roadmap-design.md` (řádek 5)
- **Kategorie:** 7. Dokumentace
- **Popis:** Status APPROVED ale v3.1 unified design explicitně superseduje tento dokument. Roadmap stále ukazuje v3.1/v3.2/v3.3 jako separate releases.
- **Doporučení:** Aktualizovat status na `SUPERSEDED by 2026-03-01-v3.1-unified-design.md`.

### [MEDIUM-22] Future roadmap doc — DRAFT ale superseded
- **Soubor:** `docs/plans/2026-02-25-future-roadmap.md` (řádek 5)
- **Kategorie:** 7. Dokumentace
- **Popis:** Status DRAFT, `Aktuální verze: 2.0.0`. Vše navržené bylo implementováno v v3.0/v3.1 nebo deferred to runtime.
- **Doporučení:** Aktualizovat na `SUPERSEDED`.

### [MEDIUM-23] Tests README — Popisuje 9 scénářů ale existuje jen 8 scriptů
- **Soubor:** `tests/README.md` vs `tests/scenarios/` (8 souborů)
- **Kategorie:** 8. Testy
- **Popis:** README popisuje scénáře 0–8 (check-setup, happy-path, triage-block, build-fail, dry-run, feature-pipeline, scaffold, dashboard, decomposition). Skutečné skripty: happy-path, triage-block, fixer-retry, reviewer-reject, test-fail, publish-success, profile-skip, verify-fail. Scénáře 0, 3, 4, 5, 6, 7, 8 z README nemají odpovídající .sh soubory.
- **Doporučení:** Vytvořit chybějící skripty nebo aktualizovat README.

### [MEDIUM-24] Mock project — Chybí Pipeline Profiles a Metrics
- **Soubor:** `tests/mock-project/CLAUDE.md`
- **Kategorie:** 8. Testy
- **Popis:** Mock project config má Retry Limits, Hooks, Worktrees, Feature Workflow, Decomposition — ale NEMÁ Pipeline Profiles ani Metrics (oboje přidáno v v3.1). Test fixture `tests/harness/fixtures/automation-config.md` Pipeline Profiles MÁ.
- **Doporučení:** Přidat Pipeline Profiles a Metrics do mock project CLAUDE.md.

### [MEDIUM-25] Example configs — Chybí optional v3.1 sekce
- **Soubor:** Všechny soubory v `examples/configs/`
- **Kategorie:** 7. Dokumentace
- **Popis:** Žádný z 6 config templates neobsahuje optional sekce (Retry Limits, Hooks, Pipeline Profiles, Metrics, etc.). Ukazují jen 5 required sekcí.
- **Doporučení:** Vytvořit alespoň jeden "full" template se všemi optional sekcemi, nebo přidat zakomentované příklady.

### [MEDIUM-26] Skill routing — version-bump args zobrazuje None
- **Soubor:** `skills/bug-workflow/SKILL.md` (řádek 23)
- **Kategorie:** 6. Skill & Plugin Metadata
- **Popis:** Intent mapping pro "Bump plugin version" ukazuje `Arguments: None`. Ale `/version-bump` podporuje optional `patch/minor/major` argument.
- **Doporučení:** Aktualizovat Arguments na `Optional: patch/minor/major`.

### [MEDIUM-27] CHANGELOG — Jazyková nekonzistence mezi verzemi
- **Soubor:** `CHANGELOG.md`
- **Kategorie:** 5. Konzistence & Naming
- **Popis:** v3.0.0 a v3.1.0 používají anglické hlavičky (Added, Changed, Fixed). v2.0.0 a v1.1.0 používají české (Nové funkce, Dokumentace). Intro je česky.
- **Doporučení:** Standardizovat. Zvážit update starších entries nebo poznámku o jazykovém přechodu.

### [MEDIUM-28] implement-feature.md — Redundantní never-skip constraint pro architect
- **Soubor:** `commands/implement-feature.md` (řádek 53)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Říká "NIKDY neskipuj architect, fixer, reviewer, publisher" ale architect není ve stage mapping tabulce, takže ho profil ani skipnout nemůže.
- **Doporučení:** Cleanup — odebrat architect z "never skip" listu nebo ho přidat do mapping jako non-skippable stage.

### [MEDIUM-29] fix-ticket.md — Decompose flag parsing placement
- **Soubor:** `commands/fix-ticket.md` (řádky 87–92)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Decompose flag se "parsuje" v kroku 4a ale reálně se $ARGUMENTS čte na začátku. Placement je matoucí, byť funkčně správný.
- **Doporučení:** Přesunout flag parsing dokumentaci na začátek souboru k popisu $ARGUMENTS.

### [MEDIUM-30] dashboard.md — CSS hardcoded v command definici
- **Soubor:** `commands/dashboard.md` (řádky 113–117)
- **Kategorie:** 1. Architektura & Design
- **Popis:** Specifické CSS barvy (#3B82F6, #EF4444, etc.) a HTML struktura jsou v command definici. Prescriptivní UI logika v orchestration commandu.
- **Doporučení:** Přesunout CSS do template souboru nebo popsat jen content requirements.

---

## LOW (25)

### [LOW-01] triage-analyst.md — Constraints duplikují Process kroky
- **Soubor:** `agents/triage-analyst.md` (řádky 66–67)
- **Kategorie:** 2. Prompt Engineering Quality
- **Popis:** Constraints "Duplicate detection: search by keywords..." a "Attachments: download to system temp directory..." duplikují kroky 2 a 3 z Process.
- **Doporučení:** Přeformulovat jako hard constraints nebo odebrat.

### [LOW-02] reviewer.md — Chybí handling pro prázdný fixer output
- **Soubor:** `agents/reviewer.md`
- **Kategorie:** 2. Prompt Engineering Quality
- **Popis:** Krok 2 říká "Read every changed file" ale neřeší scénář kdy fixer neprovedl žádné změny.
- **Doporučení:** Přidat: "If no files were changed by the fixer, BLOCK with 'No code changes detected'."

### [LOW-03] scaffolder.md — Chybí handling pro chybějící stack-selector output
- **Soubor:** `agents/scaffolder.md` (krok 1)
- **Kategorie:** 2. Prompt Engineering Quality
- **Popis:** Krok 1 říká "Read stack selection" ale nemá fallback pro chybějící output.
- **Doporučení:** Přidat error handling.

### [LOW-04] priority-engine.md — NEVER constraint neříká "modify code"
- **Soubor:** `agents/priority-engine.md` (řádek 63)
- **Kategorie:** 2. Prompt Engineering Quality
- **Popis:** Constraint říká "NEVER modify issues" (správně pro prioritizaci) ale pro úplnost by měl říkat i "NEVER modify code".
- **Doporučení:** Změnit na "NEVER modify code or issues — read-only analysis."

### [LOW-05] reviewer.md + fixer.md — "consider" v Reviewer Loop
- **Soubor:** `agents/reviewer.md` (řádek 54), `agents/fixer.md` (řádek 58)
- **Kategorie:** 2. Prompt Engineering Quality
- **Popis:** "consider their reasoning" / "consider their perspective" — měkké formulace. Ale záměrné pro prevenci infinite disagreement loops.
- **Doporučení:** Ponechat — záměrný design.

### [LOW-06] e2e-test-engineer.md — "Try running" v kroku
- **Soubor:** `agents/e2e-test-engineer.md` (řádek 23)
- **Kategorie:** 2. Prompt Engineering Quality
- **Popis:** "Try running the E2E test command in list/dry-run mode" — ale má concrete fallback s příklady.
- **Doporučení:** Ponechat — acceptable s fallbackem.

### [LOW-07] version-check.md — Funguje jen v CLAUDE-agents repo
- **Soubor:** `commands/version-check.md` (řádky 12–13)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Command hledá `.claude-plugin/plugin.json` v CWD. Z consuming projektu vždy selže.
- **Doporučení:** Clarify v popisu že je to plugin-maintenance command, nebo adjustovat na plugin installation path.

### [LOW-08] changelog.md — Jen merge commits
- **Soubor:** `commands/changelog.md` (řádek 22)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Krok 2 používá `git log --merges`. Při squash/ff merge produkuje prázdný changelog.
- **Doporučení:** Přidat fallback: pokud žádné merge commits, použít all commits.

### [LOW-09] template.md — Hardcoded template list
- **Soubor:** `commands/template.md` (řádky 26–32)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Tabulka templateů je statická v command file. Krok 1 sice dělá Glob, ale zobrazená tabulka je hardcoded.
- **Doporučení:** Odebrat statickou tabulku, spoléhat na Glob výsledek.

### [LOW-10] estimate.md — Token cost model zastará
- **Soubor:** `commands/estimate.md` (řádky 60–64)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Ceny tokenů ($3/MTok Sonnet, $15/MTok Opus) jsou hardcoded. Zastarají s pricing changes.
- **Doporučení:** Přidat komentář s datem cen nebo přesunout do config.

### [LOW-11] prioritize.md — Žádný error handling pokud priority-engine selže
- **Soubor:** `commands/prioritize.md` (řádky 27–33)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Command dispatchuje priority-engine bez Block handler kroku X.
- **Doporučení:** Přidat error handling: "Pokud priority-engine selže, zobraz error message."

### [LOW-12] fix-bugs.md — Worktree cleanup s --force
- **Soubor:** `commands/fix-bugs.md` (řádek 319)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Cleanup používá `git worktree remove --force` bez pokusu o non-force verzi.
- **Doporučení:** Zkusit non-force nejdříve, force jen jako fallback.

### [LOW-13] docs/setup/mcp-configuration.md — Jen YouTrack + Gitea
- **Soubor:** `docs/setup/mcp-configuration.md`
- **Kategorie:** 7. Dokumentace
- **Popis:** Setup guide pokrývá jen YouTrack a Gitea/Forgejo MCP servery. GitHub, Jira, Linear chybí přestože multi-tracker support je v3.1 feature.
- **Doporučení:** Přidat brief sekce pro GitHub, Jira, Linear, nebo cross-reference na examples.

### [LOW-14] docs/setup/tokens.md — Jen YouTrack + Gitea tokeny
- **Soubor:** `docs/setup/tokens.md`
- **Kategorie:** 7. Dokumentace
- **Popis:** Token guide jen pro YouTrack a Gitea. Chybí GitHub PAT, Jira API token, Linear API key.
- **Doporučení:** Přidat nebo linkovat na oficiální dokumentaci trackerů.

### [LOW-15] Pre-v3.0 design docs stále APPROVED místo SUPERSEDED
- **Soubor:** `docs/plans/2026-02-27-0{1,2,3,4}-*.md` (4 soubory)
- **Kategorie:** 7. Dokumentace
- **Popis:** Tyto 4 design dokumenty byly konsolidovány do `2026-02-28-v3.0-unified-design.md` (IMPLEMENTED). Individuální docs zůstávají APPROVED.
- **Doporučení:** Aktualizovat status na `SUPERSEDED`.

### [LOW-16] CONTRIBUTING.md — Fork workflow na interním Gitea
- **Soubor:** `CONTRIBUTING.md` (řádek 7)
- **Kategorie:** 7. Dokumentace
- **Popis:** "Fork the repository" — přestože repo je na interním Gitea. Gitea forking podporuje, takže funkčně OK.
- **Doporučení:** Low priority. Pokud se plugin přesune na veřejnou platformu, ověřit instrukce.

### [LOW-17] plugin.json — Nelistuje agents/commands/skills
- **Soubor:** `.claude-plugin/plugin.json`
- **Kategorie:** 6. Skill & Plugin Metadata
- **Popis:** Obsahuje jen name, description, version, author. Nemá enumeration agentů, commands, skills. Claude Code zřejmě auto-discovers z adresářové struktury.
- **Doporučení:** Zvážit přidání explicitních arrays pokud plugin spec to podporuje.

### [LOW-18] Block Comment Template — Czech field names v English docs
- **Soubor:** `CLAUDE.md` (řádky 144–151)
- **Kategorie:** 5. Konzistence & Naming
- **Popis:** Template používá české názvy polí (Krok, Důvod, Detail, Doporučení) vedle anglického Agent. V3.1 přešel na anglickou dokumentaci.
- **Doporučení:** Zvážit anglickou verzi nebo zdokumentovat že je záměrně česky.

### [LOW-19] Triage checkpoint v češtině
- **Soubor:** `CLAUDE.md` (řádek 156)
- **Kategorie:** 5. Konzistence & Naming
- **Popis:** `[CLAUDE-agents] Triage dokončen.` — české text parsované regexem. Hard dependency na češtinu pro machine parsing.
- **Doporučení:** Pokud internacionalizace, zvážit jazykově neutrální formát.

### [LOW-20] scaffold-add.md — Žádná validace generované komponenty
- **Soubor:** `commands/scaffold-add.md` (řádky 53–56)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Krok 5 validuje jen "pokud existuje Build/Test command". Bez nich se generovaná komponenta nevaliduje.
- **Doporučení:** Minimálně ověřit syntaktickou validitu (JSON/YAML parsing pro CI configs).

### [LOW-21] dashboard.md — Spec checkpoint regex v angličtině vs triage v češtině
- **Soubor:** `commands/dashboard.md` (řádek 42)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Spec checkpoint: "Spec analysis complete." (English). Triage checkpoint: "Triage dokončen." (Czech). Nekonzistentní, ale oba správně matčují své agenty.
- **Doporučení:** Informační — oba patterny jsou korektní pro příslušné agenty.

### [LOW-22] Test skripty jsou strukturální, ne behavioral
- **Soubor:** `tests/scenarios/*.sh`
- **Kategorie:** 8. Testy
- **Popis:** Všech 8 test skriptů kontroluje existenci souborů a grep patterny v agent/command definicích. Žádný neinvokuje pipeline ani nesimuluje MCP interakce. Mock MCP server existuje ale nepoužívá se.
- **Doporučení:** Zvážit alespoň jeden integration-level test s mock MCP serverem.

### [LOW-23] CLAUDE.md — Smíšený jazyk v Pipeline Profiles popisu
- **Soubor:** `CLAUDE.md` (řádky 128–130)
- **Kategorie:** 5. Konzistence & Naming
- **Popis:** "Pipeline Profiles se aplikují..." a "Verify command se spouští..." — české věty uprostřed anglického dokumentu.
- **Doporučení:** Přeložit do angličtiny pro konzistenci s rest of CLAUDE.md.

### [LOW-24] README.md — Tvrzení o --help flagu
- **Soubor:** `README.md` (řádek 105)
- **Kategorie:** 7. Dokumentace
- **Popis:** "Run the command with `--help` for details." — ale žádný command nemá implementovaný --help flag. Slash commands v Claude Code nemají built-in help systém.
- **Doporučení:** Odebrat nebo přeformulovat: "See CLAUDE.md for full specification."

### [LOW-25] migrate-config.md — Neřeší Verify key přidání do existující tabulky
- **Soubor:** `commands/migrate-config.md` (řádek 27)
- **Kategorie:** 3. Command Orchestration
- **Popis:** Build & Test → Verify je optional enhancement, ale krok 5 nepopisuje jak přidat klíč do existující tabulky (vs. nová sekce).
- **Doporučení:** Přidat specifickou logiku pro vkládání řádků do existujících tabulek.

---

## Top 5 Priorities

### 1. Opravit Block handler v fix-ticket.md a fix-bugs.md (CRITICAL-01, CRITICAL-02)
**Dopad:** Každý failure v hlavní bug-fix pipeline (nejpoužívanější workflow) nechá issue v neznámém stavu bez záznamu. Základ traceability je broken.
**Effort:** Malý — copy-paste z implement-feature.md krok X.

### 2. Opravit version-bump.md — přidat commit krok, opravit tag pořadí (CRITICAL-03, CRITICAL-04)
**Dopad:** Version release command je kompletně nefunkční. Každý version bump vytvoří tag na špatném commitu s uncommitted changes.
**Effort:** Malý — přidat 1 krok (git add + commit) a přeuspořádat.

### 3. Sjednotit MCP config examples s setup docs (HIGH-11, HIGH-12, HIGH-13)
**Dopad:** User-facing. Nový uživatel sledující examples dostane nefunkční setup protože package names a env vars nesouhlasí s docs. Plus `gitea` type v example ale ne v kódu.
**Effort:** Střední — vyžaduje rozhodnutí který package je kanonický.

### 4. Přidat Error Handling config čtení do hlavních pipeline commands (HIGH-04, HIGH-05, HIGH-06)
**Dopad:** Config Contract slibuje `Max blocked per run` a `On block` behavior, ale žádný command to nečte. Uživatelé nastavující tyto hodnoty budou frustrováni.
**Effort:** Malý — přidat čtení + check do 3 commands.

### 5. Opravit resume-ticket pro feature tickety (HIGH-01)
**Dopad:** Feature ticket resume použije bug-fix pipeline místo feature pipeline. Špatní agenti, špatné kroky.
**Effort:** Střední — přidat detekci typu ticketu a druhý step mapping.

---

*Report generated by Claude Opus 4.6 — 75 findings across 13 agents, 22 commands, 1 skill, docs, tests, examples, and metadata.*
