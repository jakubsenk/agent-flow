# Konzervativni perspektiva: Onboarding SK kompenzace na ceos-agents

**Pohled:** Solutions Architect (konzervativni)
**Datum:** 2026-04-10
**Verze pluginu:** ceos-agents v6.4.1
**Projekt:** SK kompenzace (Oracle PL/SQL + Redmine)

---

## 1. Co realne funguje a muzeme ukazat

### Jistoty (overene, nizke riziko selhani)

**Redmine integrace** je pokryta v pluginu od v6.4.0. Existuje sablona `examples/configs/redmine-rails.md`, ktera ukazuje presny format. Redmine MCP server (`mcp__redmine__*`) je dokumentovan v tracker-specific tabulce v `fix-ticket/SKILL.md` vcetne parametru `project_id`, `subject`, `description`, `parent_issue_id`. Filtr `assigned_to_id=me` je standardni Redmine query parametr -- neni potreba custom fields.

**Build/Test agnosticita** je architekturne zabudovana. Fixer spousti Build command a Test command jako shell stringy pres Bash tool. Pro Oracle PL/SQL to muze byt cokoliv -- `sqlplus @build.sql`, `utPLSQL`, vlastni skript. Plugin nezna a nepotrebuje znat jazyk projektu.

**Fixer (opus) zvladne PL/SQL.** Claude opus ma znalosti Oracle PL/SQL. Fixer je language-agnostic -- cte soubory, implementuje opravu, spousti build. Jedina podminka: soubory musi byt v git repu a build/test musi byt spustitelne z prikazove radky.

**Triage-analyst** funguje nad libovolnym issue trackerem. Extrahuje acceptance criteria, severity, complexity. Vystup je strukturovany markdown. Toto je nejbezpecnejsi cast pro demo -- je read-only, nic nezmeni.

**Pipeline profily** umoznuji preskocit kroky, ktere nejsou relevantni (napr. `browser-verifier`, `e2e-test-engineer`). To zjednodusuje prvni nasazeni.

### Podminenosti (funguje, ale s omezenimi)

**Reviewer (opus)** provede kvalitni code review PL/SQL. Ale: jeho "adversarial review" checklist je optimalizovan pro obecny kod. PL/SQL specifika (kurzory, exception handling, implicit commits) nezna z kontextu pluginu -- musi byt dodany pres `customization/reviewer.md`.

**Decomposition** (architect agent) produkuje task tree. Ale: `NEEDS_DECOMPOSITION` signal z fixeru v subtask loop **nema handling** (znama mezera). Pri demo na jednoduchem bugu se toto nestane; pri slozitejsim pripadu ano.

**State name->ID mapovani** pro Redmine stavy funguje na LLM konvenci. Fixer cte `State transitions | In Progress: status:In Progress` a pouziva text. Redmine MCP server pak musi rozumet textovemu nazvu stavu. Toto je "mekka vazba" -- funguje, dokud nazvy stavu v konfiguraci presne odpovidaji nazvum v Redmine.

---

## 2. Rizika a limity

### Vysoka rizika (mohou zpusobit selhani pri demo)

| Riziko | Pravdepodobnost | Dopad | Mitigace |
|--------|-----------------|-------|----------|
| Redmine MCP server neni dostupny/nefunguje | STREDNI | Pipeline se zablokuje v kroku 0 (MCP pre-flight) | Overit PRED demo. Spustit `/ceos-agents:check-setup`. |
| Build command nefunguje z CLI (Oracle env, TNS, credentials) | VYSOKA | Fixer nemuze overit svou opravu, cyklus se rozbije | Manualne overit, ze `sqlplus @build.sql` funguje z bashe na stroji, kde bezi Claude Code. |
| PL/SQL soubory nejsou v gitu | STREDNI | Fixer nema co cist, code-analyst nema co analyzovat | Zjistit strukturu repa pred onboardingem. |
| Token limit prekrocen na velkych PL/SQL souborech | NIZKA | Agent selze uprostred analyzy | PL/SQL balicky mohou mit tisice radku. Overit velikosti souboru. |
| Stavy v Redmine nesedi s konfiguraci | STREDNI | Stav se neprepne, pipeline pokracuje ale issue zustane v puvodnim stavu | Overit presne nazvy stavu. |

### Stredni rizika (nezpusobi selhani, ale snizi hodnotu demo)

| Riziko | Popis |
|--------|-------|
| Token tracking neni presny (+-50%) | Odhad nakladu v kroku 9c bude nepresny. Pro CEO prezentaci to muze byt problem -- nemuze rict "stoji to X CZK za bug". |
| Hard cost ceiling chybi | Neexistuje mechanismus "zastav pipeline kdyz spotrebujes $N". Teoreticky muze fixer-reviewer loop spotrebovat hodne tokenu. |
| Acceptance gate se preskoci u jednoduchych bugu | Pro XS/S complexity a <3 AC se acceptance-gate nespusti. To je by design, ale CEO muze ocekavat ze "vzdy overime kvalitu". |

### Architekturni limity (neresitelne v ramci onboardingu)

- **Standalone agent invocability** -- agenty nelze spoustet mimo pipeline kontext. Nelze rict "spust jen fixera na tento soubor".
- **Zadne GUI/dashboard v realnem case** -- `/ceos-agents:dashboard` generuje staticke HTML. Neni to Redmine plugin ani webove rozhrani.
- **Jednosmerny tok** -- pipeline jde vpred. Kdyz reviewer rekne "spatne", vrati se k fixerovi -- ale clovek nemuze zasahnout uprostred iterace (krome CTRL+C).

---

## 3. Minimalni viable setup

### Co je potreba pripravit (3 soubory, 0 zmen v pluginu)

**1. `CLAUDE.md` v projektu SK kompenzace:**

```markdown
## Automation Config

### Issue Tracker
| Key | Value |
|------|---------|
| Type | redmine |
| Instance | `https://redmine.sk-kompenzace.cz` |
| Project | `sk-kompenzace` |
| Bug query | `project_id=sk-kompenzace&status_id=open&assigned_to_id=me&tracker_id=1` |
| State transitions | In Progress: `status:In Progress`, Blocked: `status:Feedback`, Done: `status:Closed` |
| On start set | `status:In Progress` |

### Source Control
| Key | Value |
|------|---------|
| Remote | `org/sk-kompenzace` |
| Base branch | `main` |
| Branch naming | `fix/{issue}-{short-description}` |

### PR Rules
| Key | Value |
|------|---------|
| Labels | `ForReview` |

### Build & Test
| Key | Value |
|------|---------|
| Build command | `./scripts/build.sh` |
| Test command | `./scripts/test.sh` |
```

**2. `customization/fixer.md`:**
PL/SQL konvence, schema pravidla, Oracle-specificke patterny (kurzory, exception handling, PRAGMA AUTONOMOUS_TRANSACTION atd.).

**3. `customization/test-engineer.md`:**
utPLSQL konvence, jak spoustit testy, jake assertiony pouzivat.

### Co NEmusi byt pripraveno pro prvni demo

- Zadne `customization/reviewer.md` (reviewer funguje i bez nej, jen nebude znat PL/SQL specifika)
- Zadny E2E Test config
- Zadna Browser Verification
- Zadna Local Deployment sekce
- Zadne Hooks ani Custom Agents
- Zadna Decomposition konfigurace (defaulty staci)

### Minimalni technicke predpoklady

1. Claude Code nainstalovany a funkcni
2. Plugin `ceos-agents` nainstalovan (`claude plugin install ceos-agents@ceos-agents`)
3. Redmine MCP server nakonfigurovany a dostupny
4. Git repo s PL/SQL soubory (klon na lokalni stroj)
5. Build/test scripty spustitelne z CLI bez manualni interakce
6. Oracle klient/pripojeni funkcni na stroji kde bezi Claude Code

---

## 4. Co NEdelat

### Prilis brzy (predcasne pro onboarding)

- **Neslibit automaticke reseni vsech bugu.** Plugin je asistent, ne nahrada vyvojare. Fixer muze selhat, reviewer muze blokovat, pipeline muze skoncit v Block stavu. To je normalni a ocekavane chovani.
- **Nenastavovat batch pipeline (`/fix-bugs`).** Zacit s jednim tiketem (`/fix-ticket`). Batch pridava slozitost (worktrees, paralelismus) bez pridane hodnoty pro uvodni validaci.
- **Nenastavovat decomposition.** Prvni tikety by mely byt XS/S complexity. Decomposition je pro M/L a ma znamou mezeru (NEEDS_DECOMPOSITION v subtask loop).
- **Nenastavovat webhooky/notifikace.** Pridavaji konfiguraci bez okamzite hodnoty.
- **Neslibovat presne naklady.** Token tracking je heuristika +-50%. Rici "odhadujeme $0.50-$1.60 za bug" je falesne presne. Lepe: "prvni mesic sledujeme skutecne naklady, pak budeme vedet".

### Vubec (mimo scope pluginu)

- **Nenasazovat jako "AI vyvojar".** Plugin je pipeline orchestrator. Nepise nove features od nuly (na to je `/implement-feature`, coz je jina pipeline s jinym rizikovym profilem).
- **Nevytvorit vlastni agenty.** Agent Overrides (`customization/*.md`) staci pro projektove specifika. Novy agent = zmena v pluginu = udrzba.
- **Nemodifikovat agent definice.** Nulove zmeny v `agents/*.md`. Vsechno jde pres customization/.

---

## 5. Doporuceny postup

### Faze 0: Priprava prostredi (1-2 dny)

1. Nainstalovat Claude Code na vyvojovy stroj
2. Nainstalovat plugin ceos-agents
3. Nakonfigurovat Redmine MCP server
4. Overit: `git clone`, `sqlplus` z CLI, testy z CLI
5. Pripravit 3 soubory (CLAUDE.md, customization/fixer.md, customization/test-engineer.md)

**Gate:** `/ceos-agents:check-setup` vraci PASS na vsechny required sekce.

### Faze 1: Suchy beh (1 den)

1. Vybrat 1 jednoduchy bug (XS/S, 1 soubor, jasne popsany)
2. Spustit `/ceos-agents:fix-ticket ISSUE-123 --dry-run`
3. Overit: triage output dava smysl, code-analyst identifikoval spravne soubory
4. Pokud ne: upravit CLAUDE.md nebo customization soubory

**Gate:** Dry-run report je rozumny a odpovidajici realite.

### Faze 2: Prvni ostry beh (1 den)

1. Spustit `/ceos-agents:fix-ticket ISSUE-123` (bez --dry-run, bez --yolo)
2. Sledovat kazdy krok pipeline
3. Na konci: rucne zkontrolovat vysledny PR
4. NEpublikovat automaticky -- rucne schvalit

**Gate:** PR obsahuje rozumnou opravu. Build a testy prochazi.

### Faze 3: Validace na 3-5 tiketech (3-5 dnu)

1. Postupne spustit pipeline na 3-5 ruznych tiketech (ruzna slozitost, ruzne moduly)
2. Zaznamenavat: cas, naklady (skutecne tokeny), pocet iteraci fixer/reviewer, pocet bloku
3. Identifikovat patterny: kde pipeline selhava, co chybi v customization

**Gate:** >=60% tiketu uspesne doresi pipeline. Zbytek se blokuje s rozumnym duvodem.

### Faze 4: CEO prezentace

**Co ukazat:**
- Dry-run na novem tiketu (bezpecne, bez vedlejsich efektu)
- Hotovy PR z faze 2/3 (konkretni priklad uspesneho vysledku)
- Block priklad (ukazat ze system umi rict "nevim, clovece pomoz")
- Metriky z faze 3 (uspesnost, cas, naklady)

**Co NEukazat:**
- Zivou pipeline (muze selhat z technickych duvodu -- Oracle spojeni, MCP timeout)
- Batch pipeline (slozite, nepredvidatelne)
- Odhady nakladu (nejsou presne)

**Co rict uprimne:**
- "Plugin je orchestrator -- ridi praci AI modelu, ne nahrazuje vyvojare"
- "Uspesnost 60-80% na jednoduchych bugech, slozitejsi vyzaduji lidsky zasah"
- "Naklady zjistime az po pilotnim obdobi (mesic realneho pouzivani)"
- "Integrace s Redmine funguje, ale vyzaduje stabilni MCP server"

---

## Zaver

Onboarding SK kompenzace na ceos-agents je proveditelny s minimalnim usilim (3 soubory, 0 zmen v pluginu). Hlavni rizika nejsou v pluginu ale v infrastrukture (Oracle CLI, Redmine MCP, git repo struktura). Doporucuji striktne sekvencni postup: suchy beh, jeden tiket, pak teprve skalovani. CEO prezentaci zakladat na hotovych vysledcich, ne na zive ukazce.

Nejvetsi hodnota pluginu pro SK kompenzace neni "automaticke opravovani bugu" ale **standardizovany proces**: kazdy tiket projde triazi, analyzou, opravou, review a testovanim. I kdyz pipeline blokuje a clovek musi zasahnout, struktura a dokumentace procesu ma hodnotu sama o sobe.
