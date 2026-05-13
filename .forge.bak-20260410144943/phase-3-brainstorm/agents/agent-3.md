# Agent 3 — Skepticky technicku auditor

**Perspektiva:** Devil's advocate. Co se muze pokazit a co jsme podcenili.

---

## 1. Slepe skvrny analyzy

### 1.1 Nebyl testovan zadny end-to-end flow

Cela analyza je teoreticka. Nikdo nespustil ani jediny `/ceos-agents:fix-ticket` proti Redmine instanci s Oracle PL/SQL projektem. Vsechny zavery typu "funguje out-of-the-box" jsou odvozeny z cteni markdown definic, nikoliv z empirickeho overeni. To je zásadní epistemicky problem — plugin je markdown-only, takze jeho chovani je emergentni vlastnost LLM interpretace, ne deterministickeho kodu.

**Konkretne:** Tvrzeni "Build/Test agnosticke — exit kod primarni signal" je pravdive na urovni designu, ale v praxi muze fixer agent spatne interpretovat Oracle error output, zvlast kdyz ORA-XXXXX chyba ma vicedilny stack trace prelozeny pres SQLcl wrapper. Tohle nikdo netestoval.

### 1.2 "Workaround" neni to same co "funguje"

Analyza klasifikuje mnozstvi mezer jako "CASTECNE — existuje workaround." Ale workaround vyzaduje, aby uzivatel presne vedel, co dela. Milan Martak explicitne pise, ze App tym ma "0 zkusenosti s agentickym vyvojem." Kazdy workaround je potencialni bod selhani, ktery vyzaduje expertni zasah.

Priklady:
- **Status name-to-ID mapovani:** "LLM konvence" znamena, ze LLM hada spravne ID. Na nestandardni Redmine instanci s cesky pojmenovanymi stavy ("Novy", "V realizaci", "Dokonceno") je pravdepodobnost chyby vysoka. Agent Override s explicitnim mapovanim to opravi — ale kdo ho napise a odladi?
- **NEEDS_DECOMPOSITION v subtask loop:** Workaround je "nastavit disabled a rucne dekomponovat." To eliminuje jednu z klicovych hodnot pluginu.
- **Publisher mandatory:** "Interaktivne lze odmitnout" — skvele, ale kdo bude u terminalu, kdyz to bezi v demonstraci?

### 1.3 Redmine API token = plny pristup

Analyza to zminuje jen okrajove, ale Redmine API klice nemaji scoped permissions. Token, ktery agent pouziva, ma plny pristup ke VSEM projektum v Redmine instanci. Pokud agent spatne interpretuje query a zacne upravovat tickety v jinem projektu, neni zadna ochrana. A to `redmine.test.ceosdata.com` je testovaci instance — co az se prejde na produkci?

### 1.4 Chybi odhad celkoveho casu na rozjezd

Analyza rika "3 soubory v projektu + 1 sablona v pluginu." Ale nerika, kolik HODIN prace to realne bude. Muj skepticky odhad:

| Polozka | Optimisticky | Realisticky | Pesimisticky |
|---------|-------------|-------------|--------------|
| CLAUDE.md + Automation Config | 2h | 4h | 8h |
| Agent Overrides (fixer, test-engineer) | 3h | 6h | 12h |
| MCP server setup + overeni | 1h | 3h | 6h |
| Oracle Docker stabilizace | 2h | 4h | 8h |
| Prvni testovaci run + debugging | 4h | 8h | 16h |
| Ladeni po prvnim selhani | 2h | 6h | 16h |
| **Celkem** | **14h** | **31h** | **66h** |

Realisticky scenar je 4-5 pracovnich dni, ne "par hodin." A to jeste nepocitam cas Milana Martaka na konzultace ohledne Oracle konvenci a Redmine workflow.

---

## 2. Realne prekazky onboardingu

### 2.1 Docker + Oracle + Claude Code = trojity fail-point

Pipeline vyzaduje, aby behem celeho behu:
1. Docker daemon bezel
2. Oracle XE kontejner byl zdravy a responzivni
3. MCP server redmine byl pripojen
4. Claude Code mel stabilni API spojeni

Jeden pad kterehokoli bodu = pipeline block. Oracle XE v Dockeru je notoricky nestabilni — kontejner spotrebovava 2-4 GB RAM, startup trva 60-90 sekund, a sqlcl connections mohou timeoutovat. Fixer agent nema zadny retry mechanismus pro "databaze neni ready" — proste uvidí build failure a zacne opravovat neexistujici problem.

### 2.2 Kdo bude u terminalu?

Plugin predpoklada, ze nekdo je u terminalu a muze reagovat na interaktivni prompty (publisher odmitnutí, clarifications). Ale cil je "automatizovany vyvoj." Tenhle rozpor neni v analyze adresovan.

Pro demo pred CEO to znamena: bud nekdo sedi u terminalu a rucne schvaluje kroky (coz podkopava narativ "automatizace"), nebo se to necha bezet automaticky a riskuje, ze agent udela neco necekaneho.

### 2.3 utPLSQL testy v praxi

Analyza predpoklada, ze v projektu existuji vzorove utPLSQL testy. Ale co kdyz neexistuji? Fixer agent ma v procesu krok 5 "RED: Write a test that reproduces the bug." Napsani utPLSQL testu vyzaduje:
- Znalost utPLSQL anotaci (`-- %suite`, `-- %test`, `-- %beforeeach`)
- Spravne nastaveni test schema s granty
- ROLLBACK strategii (manualni vs. automaticky)
- Znalost Oracle-specifickych assertu (`ut.expect()`)

Agent Override pro test-engineer muze pomoci, ale stale spoliha na to, ze Opus/Sonnet spravne generuje utPLSQL kod. Kolize mezi generickymi znalostmi Claude o testovani a specifickami utPLSQL frameworku je predvidatelna.

### 2.4 Git repozitar — kde vlastne je?

Analyza nastavuje `Remote: <owner/repo>` jako placeholder. Ale zakladni otazka: kde bezi Git server? Gitea? GitHub? GitLab? Redmine ma vlastni Git integraci? Kazda varianta ma jiny MCP server pro source control a jinou konfiguraci. Tohle neni trivialita.

---

## 3. Oracle PL/SQL specifika — je Claude skutecne dobry?

### 3.1 Co Claude (Opus) zvladne

Na zaklade empirickych zkusenosti komunity a benchmarku:
- **Zakladni PL/SQL syntaxe:** Ano — CREATE PACKAGE, procedury, funkce, kurzory, %TYPE/%ROWTYPE
- **Jednoduche CRUD packages:** Ano — INSERT/UPDATE/DELETE s exception handlingem
- **utPLSQL zakladni testy:** Castecne — zna framework, ale dela chyby v anotacich

### 3.2 Kde Claude selhava

**Oracle-specificke konstrukty:**
- **BULK COLLECT + FORALL:** Claude casto generuje neefektivni rádek-po-radku zpracovani misto BULK operaci. Pro kompenzacni engine, ktery bude zpracovavat velke objemy dat, je to kriticke.
- **Analytic functions (OVER/PARTITION BY):** Claude je zna, ale casto generuje suboptimalni varianty s vnorenym SELECT misto window funkce.
- **PL/SQL warning suppression (PRAGMA):** Claude zapomina na `PRAGMA EXCEPTION_INIT` pro custom exceptions a `PRAGMA AUTONOMOUS_TRANSACTION` pro logovani.
- **Oracle hints:** `/*+ LEADING(t1) USE_NL(t2) */` — Claude je neumi a nemelo by je generovat, ale bez explicitni instrukce muze.
- **Flyway idempotence:** `V{N}__xxx.sql` migrace musi byt idempotentni. Claude casto generuje `CREATE TABLE` bez `IF NOT EXISTS` ekvivalentu (ktery v Oracle neexistuje — musi se pouzit PL/SQL blok s `EXECUTE IMMEDIATE` a exception handlerem). Tohle je klasicky fail-point.
- **Package state invalidation:** Kdyz Claude zmeni spec (.pks), musi prekompilovat vsechny zavisle objekty. Agent Override muze instrukovat "vzdy spust `compile_all.sh`", ale to je pomale a nakladne.

### 3.3 Chybove rezy pro kompenzacni engine

Specificke oblasti kde Claude bude mit problemy:
- **Oracle DATE vs. TIMESTAMP:** Kompenzace zahrnuji casove vypocty. Claude si casto plete DATE a TIMESTAMP semantiku, zvlast s casovymi zonami.
- **NUMBER precision:** `NUMBER(18,2)` vs. `NUMBER` — pro financni vypocty je presnost kriticka. Claude defaultne pouziva `NUMBER` bez precision.
- **NLS settings:** Oracle NLS (National Language Support) ovlivnuje formatovani cisel a dat. Claude o NLS vi, ale neaplikuje to konzistentne.
- **Deterministic funkce:** Pro kompenzacni vypocty je determinismus klicovy. Claude ne vzdy oznacuje funkce jako `DETERMINISTIC` kdyz by mel.

### 3.4 Realisticky odhad uspesnosti

Pro jednoduchy bug (chybejici null check, spatna podminka v WHERE):
- **Uspesnost prvniho pokusu:** ~70%
- **Uspesnost po 3 iteracich fixer-reviewer:** ~90%

Pro stredne slozity feature (novy package s 3-5 procedurami, Flyway migrace, testy):
- **Uspesnost prvniho pokusu:** ~30%
- **Uspesnost po 5 iteracich:** ~60%
- **Pravdepodobnost NEEDS_DECOMPOSITION nebo Block:** ~40%

Pro slozity feature (kompenzacni engine s vicero tabulkami, triggery, batch zpracovanim):
- **Uspesnost:** <20% bez vyznamneho lidskeho zasahu

---

## 4. Redmine MCP spolehlivost

### 4.1 mcp-server-redmine — kdo to vlastne udrzuje?

Package `mcp-server-redmine` od `yonaka15` na GitHubu. Klicove otazky:

- **Pocet stazeni/stars:** Nezname. MCP ekosystem je mlady, mnoho serveru je v early-stage kvalite.
- **Posledni update:** Nezname. Pokud se MCP protokol zmeni (coz se deje — MCP je v aktivnim vyvoji), server muze prestat fungovat.
- **Pokryti Redmine API:** Redmine REST API ma ~30 endpointu. MCP server pravdepodobne pokryva jen podmnozinu. Otazka: pokryva `update_issue` s `assigned_to_id`? Pokryva `list_issue_statuses` pro status-to-ID mapovani?
- **Error handling:** Kdyz Redmine vrati 500 (coz dela celkem casto pri concurrency), co MCP server udela? Propaguje chybu? Retryuje? Tichy fail?

### 4.2 MCP protokol na Windows

Cely ceos-agents dev stack bezi na Windows (viz env info). MCP servery spoustene pres `npx` na Windows maji zname problemy:
- **Path separatory:** `--prefix` s Windows paths muze selhat
- **Process cleanup:** `npx` na Windows spatne ukoncuje child procesy — MCP server muze zustat bezet po skonceni Claude Code session
- **stdin/stdout piping:** MCP pouziva stdio transport. Na Windows muze byt problem s encodingem (UTF-8 vs. system codepage)

### 4.3 Konkretni rizika pro pipeline

| Operace | Riziko | Dopad |
|---------|--------|-------|
| Query issues | Spatna query syntax → prazdny result | Pipeline skonci "no issues to process" |
| Update status | Spatne status_id → API error 422 | Pipeline block, ticket ve spatnem stavu |
| Create sub-issue | Chybejici parent_issue_id support v MCP | Decomposition nefunguje |
| Add comment | Limit na delku komentare (Redmine default: 64KB) | Block Comment muze byt oriznut |
| Read attachments | MCP server to pravdepodobne nepodporuje | Agent nevidí prilohy ticketu |

---

## 5. Demo rizika

### 5.1 Scenar: Demo pred CEO selze

**Pravdepodobnost:** 40-60% pri prvnim pokusu bez predchoziho dry-runu.

**Typicke failure mody:**
1. **MCP server nenastaruje** — npx stahne spatnou verzi, network timeout, missing dependency
2. **Oracle kontejner neni ready** — startup sequence trva dele nez ocekavano, sqlcl connection refused
3. **Fixer generuje nevalidni PL/SQL** — kompilacni chyba, 3 retry iterace, kazda trva 30-60 sekund, CEO se diva na terminal 5 minut
4. **Status transition selze** — ticket zustane ve spatnem stavu, agent pokracuje bez povsimnuti
5. **Token limit** — slozitejsi ticket spotrebuje tokeny a session se prerusi (Milan uz tenhle problem zazil: "dosly tokeny")

### 5.2 Fallback strategie (chybi v analyze!)

Analyza neobsahuje ZADNY fallback plan pro pripad selhani dema. To je kriticka mezera. Navrhuji:

**Tier 1 — Predtocene demo (nejbezpecnejsi):**
- Spustit pipeline predtim, nahrat screencast
- Prezentovat jako "takto to bezi v praxi"
- Zive ukazat pouze Redmine board s vysledky

**Tier 2 — Rucni orchestrace s pripravenym ticketem:**
- Predpripravit jednoduchy ticket (null check fix, 5 radku zmena)
- Spustit pouze `/ceos-agents:analyze-bug` (nejmene rizikovy krok)
- Pokud projde, spustit `/ceos-agents:fix-ticket`
- Pokud cokoli selze, prepnout na Tier 1

**Tier 3 — Claude Code bez pluginu:**
- Ukazat Claude Code primo s Oracle projektem
- "Tady vidite, jak agent analyzuje kod a navrhuje opravu"
- Prezentovat ceos-agents jako "automatizacni vrstvu nad timto"

### 5.3 Casovy odhad dema

| Scénář | Cas | Riziko |
|--------|-----|--------|
| analyze-bug jednoducheho ticketu | 2-3 min | Nizke |
| fix-ticket jednoducheho bugu (XS) | 5-10 min | Stredni |
| fix-ticket stredniho bugu (S) | 15-30 min | Vysoke |
| Kompletni pipeline vcetne PR | 20-45 min | Velmi vysoke |

CEO pozornost: realisticky 15-20 minut. Pipeline S-bugu muze trvat dele.

---

## 6. Skryte naklady

### 6.1 API naklady (tokeny)

Analyza zminuje "heuristiky +-50%, zadna realna data z API." Pokusim se o realistictejsi odhad:

| Faze pipeline | Odhadované tokeny (input+output) | Cena (Opus $15/$75 per 1M) |
|---------------|----------------------------------|---------------------------|
| Triage (sonnet) | ~20K in, ~3K out | ~$0.02 |
| Code-analyst (sonnet) | ~50K in, ~5K out | ~$0.05 |
| Fixer iter 1 (opus) | ~80K in, ~10K out | ~$1.95 |
| Reviewer iter 1 (opus) | ~60K in, ~5K out | ~$1.28 |
| Fixer iter 2 (opus) | ~100K in, ~10K out | ~$2.25 |
| Reviewer iter 2 (opus) | ~80K in, ~5K out | ~$1.58 |
| Test-engineer (sonnet) | ~40K in, ~8K out | ~$0.04 |
| Publisher (haiku) | ~10K in, ~2K out | ~$0.01 |
| **Celkem (2 iterace)** | | **~$7.18** |
| **Celkem (5 iteraci)** | | **~$18-26** |

Pro 10 ticketu mesicne: **$70-260/mesic** jen na API naklady. Bez hard cost ceilingu muze jediny problem-ticket stát $30+.

### 6.2 Cas lidi

| Polozka | Kdo | Cas/mesic |
|---------|-----|-----------|
| Setup a udrzba Oracle Dockeru | Milan/Infra | 4-8h |
| Ladeni Agent Overrides | Filip | 8-16h (prvni mesic), 2-4h (pak) |
| Monitoring a intervence pri blocich | Milan | 4-8h |
| Review AI-generovaneho kodu | App tym | 8-16h |
| Troubleshooting MCP/pipeline issues | Filip | 4-8h |

Prvni mesic: **28-56 hodin lidskeho casu.** To neni "automatizace" — to je "novy nastroj s vysokymi startup naklady."

### 6.3 Infrastruktura

- Oracle XE Docker: 2-4 GB RAM dedikované
- Claude Code/API: subscription + API credits
- Redmine test instance: uz bezi, ale udrzba
- Git server: uz bezi

---

## 7. Alternativni pristup — rucni orchestrace

### 7.1 Proc by to mohlo byt lepsi

Milan sam pise: "klidne jen cast + rucni orchestrace promptovani." Tohle neni slabost — je to pragmatismus. Full pipeline ma desitky failure pointu. Rucni orchestrace ma jeden: cloveka.

**Navrh postupneho nasazovani (3 faze):**

**Faze A (tyden 1-2): Claude Code + Oracle — bez pluginu**
- Cil: Overit, ze Claude Code s Oracle PL/SQL vubec funguje
- Setup: CLAUDE.md s Oracle konvencemi, Docker s Oracle XE
- Workflow: Clovek rucne zada "oprav bug #123" a sleduje vysledek
- Metrika: % uspesnych opravu, prumerna doba, kvalita kodu

**Faze B (tyden 3-4): ceos-agents analyze-bug + manual fix**
- Cil: Overit Redmine integraci a triage kvalitu
- Pridat: Automation Config, MCP server, `/ceos-agents:analyze-bug`
- Workflow: Agent analyzuje, clovek opravuje (nebo rucne spusti fix)
- Metrika: Kvalita triage, spravnost AC extrakce, Redmine state transitions

**Faze C (tyden 5+): Postupne zapinani pipeline fazi**
- Cil: Overit end-to-end pipeline na jednoduchych ticketech
- Pridat: `/ceos-agents:fix-ticket` na XS/S ticketech
- Workflow: Pipeline bezi, clovek monitoruje a zasahuje pri blocich
- Metrika: % automaticky vyresenych ticketu, naklady, cas

### 7.2 Proc plny pipeline hned je riskantni

- **Prilis mnoho pohyblivych casti:** Docker + Oracle + MCP + Redmine + Git + Claude API
- **Nulova zkusenost tymu:** App tym nezna ani Claude Code, natoz pipeline
- **Neni kam eskalovat:** Kdyz pipeline blockne, kdo to bude resit? Filip neni na projektu fulltime.
- **CEO expectations:** Pokud ukazeme full pipeline a ten selze, dojem je horsi nez kdyby jsme ukazali mensi ale funkcni cast

### 7.3 Verdikt

Doporucuji **Fazi A+B jako MVP pro demo** (2-3 tydny pripravy) a **Fazi C az po validaci** feedback z dema. Plny pipeline az kdyz:
1. Minimalne 5 ticketu uspesne proslo analyze-bug bez intervence
2. Agent Overrides pro Oracle PL/SQL jsou odladeny na 3+ realnych opravach
3. Milan potvrdil, ze Redmine state transitions fungují spravne

---

## 8. Sumarni rizikova matice

| Riziko | Pravdepodobnost | Dopad | Mitigace |
|--------|-----------------|-------|----------|
| Demo selze pred CEO | 40-60% | Vysoky | Predtocene demo jako fallback |
| Oracle PL/SQL chyby od agenta | 70%+ pri complex tasks | Stredni | Agent Override + lidsky review |
| mcp-server-redmine nestabilita | 30% | Vysoky | Predtestovat KAZDY MCP call rucne |
| Token runaway na slozitem ticketu | 20% | Stredni | Konzervativni retry limity (fixer=2) |
| Status name-to-ID selhani | 40% na nestandardní instanci | Stredni | Explicitni mapovani v Override |
| Docker Oracle crash behem pipeline | 15% | Vysoky | Health check pred kazdym runem |
| App tym odmitne nastroj | 30% | Velmi vysoky | Postupna adopce (Faze A-B-C) |
| MCP na Windows path issues | 25% | Stredni | Testovat na cilovem stroji |

**Celkove hodnoceni:** Projekt je proveditelny, ale timeline "ASAP" je nerealisticky pro full pipeline. Realisticky MVP (Faze A+B) je 3-4 tydny. Full pipeline (Faze C) je 6-8 tydnu za predpokladu, ze feedback z dema nebude vyzadovat vyrazne zmeny v pristupu.
