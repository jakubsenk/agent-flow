# 01 — Forgejo MCP opravy + analyza CLAUDE-agents: prefixu

## Aktualni stav

### URL Forgejo MCP serveru — vyzaduje overeni

V dokumentaci je pouzivana URL `codeberg.org/forgejo/forgejo-mcp/releases`. Brainstorm puvodni verze tvrdil, ze spravna URL je `codeberg.org/goern/forgejo-mcp/releases`, ale toto tvrzeni nebylo overeno a v celem codebase se retezec `goern` nevyskytuje nikde jinde. Vsechny zdrojove soubory (vcetne historickych design dokumentu) konzistentne pouzivaji `forgejo/forgejo-mcp`.

**Status: Neovereno, vyzaduje overeni u upstream Codeberg registru.**

**Poznamka k dokumentu 07:** Dokument `07-unified-improvements-summary.md` na radku 22 prezentuje `goern/forgejo-mcp` jako potvrzenou opravu URL. Toto je v rozporu s neutralni formulaci tohoto dokumentu ("vyzaduje overeni"). Dokument 07 musi byt slazen s touto opatrnejsi formulaci po overeni skutecneho stavu na Codeberg.

Pred jakoukoli opravou je nutne:
1. Overit na Codeberg, zda existuje `codeberg.org/forgejo/forgejo-mcp` (aktualni URL v dokumentaci)
2. Overit na Codeberg, zda existuje `codeberg.org/goern/forgejo-mcp` (alternativni URL)
3. Zjistit, ktery z nich je aktivne udrzovany a obsahuje releases

### Dotcene soubory

| Soubor | Popis | Typ reference |
|--------|-------|---------------|
| `docs/guides/mcp-configuration.md` | Radek 45 — zdrojova URL pro stahovani binarky | Aktivni dokumentace |
| `docs/guides/installation.md` | Radek 72 — odkaz na download pro Linux | Aktivni dokumentace |
| `examples/mcp-configs/gitea.json` | Pattern `<path-to-binary>/forgejo-mcp` | Konfiguracni sablona |
| `docs/reference/trackers.md` | MCP Server Detection tabulka — Package sloupec `forgejo-mcp` | Reference |
| `docs/guides/cross-platform.md` | Radky 16, 22, 31 — reference na `forgejo-mcp` binarku (ne URL) | Aktivni dokumentace |
| `docs/guides/tokens.md` | Radek 10 — `forgejo-mcp` jako MCP server v tabulce | Aktivni dokumentace |
| `docs/plans/2026-02-25-v1.2-installation-docs-design.md` | Historicka reference | Archivni |
| `docs/plans/2026-02-25-v1.4-linux-compatibility-design.md` | Historicka reference | Archivni |
| `docs/plans/2026-02-25-v2.0-implementation-plan.md` | 2 vyskyty — historicka reference | Archivni |
| `docs/plans/2026-02-25-v2.0-sync-document.md` | Historicka reference | Archivni |

### Sekundarni problem: UX binarniho stahovani

Nezavisle na spravnosti URL existuje UX nesoulad: vsechny ostatni trackery (YouTrack, GitHub, Jira, Linear, Redmine) pouzivaji `npx` instalaci, zatimco Gitea/Forgejo vyzaduje manualni stahovani Go binarky. Toto je identifikovano take v dokumentu 07 jako tema #1. K datu tvorby tohoto dokumentu neexistuje `forgejo-mcp` npm balicek.

### Zavaznost

**Medium** — pokud je URL chybna, uzivatel stahne binarku z neexistujiciho repa. Pokud je URL spravna, problem se omezuje na UX nesoulad s ostatnimi trackery.

### Navrhovany fix

1. **Prerequisite:** Overit skutecny stav na Codeberg (viz vyse)
2. Opravit URL ve 2 aktivnich souborech (`mcp-configuration.md`, `installation.md`) podle vysledku overeni
3. Aktualizovat `examples/mcp-configs/gitea.json` pokud se meni nazev binarky
4. Overit, ze nazev binarky (`forgejo-mcp`) odpovida tomu, co se stahuje z verified URL. Pokud se nazev binarky zmeni, je nutne aktualizovat i `docs/guides/cross-platform.md` a `docs/guides/tokens.md` (obsahuji reference na nazev `forgejo-mcp`, i kdyz ne na URL)
5. Zvazit pridani poznamky, ze existuje i alternativni repo (pokud obe existuji), aby uzivatel vedel o moznych zdrojich
6. Historicke soubory v `docs/plans/` jsou archivni a oprava neni nutna, ale muze byt provedena pro konzistenci

---

## Analyza CLAUDE-agents: prefixu

### Jak prefix funguje

Prefix `CLAUDE-agents:` je odvozen od nazvu pluginu definovaneho v `plugin.json` (`"name": "CLAUDE-agents"`). Predpoklad je, ze Claude Code platforma tento prefix automaticky pridava jako namespace mechanismus pluginoveho systemu. Tento predpoklad je zalozen na pozorovani chovani, nikoli na officialní dokumentaci Claude Code plugin API — pokud Claude Code zmeni chovani prefixu v budouci verzi, analyza bude vyzadovat aktualizaci.

**Poznamka:** Zda je prefix "platform-enforced" (nelze selektivne vypnout pro jednotlive commands) je hypoteza, nikoli overeny fakt. Pro ucely teto analyzy pracujeme s timto predpokladem.

### Analyza vsech 22 commands

| Command | Plny nazev | Genericky nazev? | Riziko kolize | Prefix nutny? |
|---------|-----------|-------------------|---------------|---------------|
| analyze-bug | `CLAUDE-agents:analyze-bug` | Ne | Nizke | Ne (specificky) |
| changelog | `CLAUDE-agents:changelog` | **Ano** | **Vysoke** | **Ano** |
| check-setup | `CLAUDE-agents:check-setup` | Castecne | Stredni | Spise ano |
| create-pr | `CLAUDE-agents:create-pr` | Castecne | Stredni | Spise ano |
| dashboard | `CLAUDE-agents:dashboard` | **Ano** | **Vysoke** | **Ano** |
| estimate | `CLAUDE-agents:estimate` | **Ano** | **Vysoke** | **Ano** |
| fix-bugs | `CLAUDE-agents:fix-bugs` | Ne | Nizke | Ne |
| fix-ticket | `CLAUDE-agents:fix-ticket` | Ne | Nizke | Ne |
| implement-feature | `CLAUDE-agents:implement-feature` | Ne | Nizke | Ne |
| metrics | `CLAUDE-agents:metrics` | **Ano** | **Vysoke** | **Ano** |
| migrate-config | `CLAUDE-agents:migrate-config` | Castecne | Nizke | Ne |
| onboard | `CLAUDE-agents:onboard` | **Ano** | **Vysoke** | **Ano** |
| prioritize | `CLAUDE-agents:prioritize` | **Ano** | Stredni | Spise ano |
| publish | `CLAUDE-agents:publish` | **Ano** | **Vysoke** | **Ano** |
| resume-ticket | `CLAUDE-agents:resume-ticket` | Ne | Nizke | Ne |
| scaffold | `CLAUDE-agents:scaffold` | **Ano** | Stredni | Spise ano |
| scaffold-add | `CLAUDE-agents:scaffold-add` | Ne | Nizke | Ne |
| scaffold-validate | `CLAUDE-agents:scaffold-validate` | Ne | Nizke | Ne |
| status | `CLAUDE-agents:status` | **Ano** | **Vysoke** | **Ano** |
| template | `CLAUDE-agents:template` | **Ano** | **Vysoke** | **Ano** |
| version-bump | `CLAUDE-agents:version-bump` | Castecne | Stredni | Spise ano |
| version-check | `CLAUDE-agents:version-check` | Castecne | Stredni | Spise ano |

### Shrnuti

- **~10 commands** ma genericke nazvy kde prefix chrani pred kolizemi (`changelog`, `dashboard`, `estimate`, `metrics`, `onboard`, `publish`, `status`, `template`, `scaffold`, `prioritize`)
- **~8 commands** ma dostatecne specificke nazvy (`analyze-bug`, `fix-bugs`, `fix-ticket`, `implement-feature`, `resume-ticket`, `scaffold-add`, `scaffold-validate`, `migrate-config`)
- **~4 commands** jsou hranicni (`check-setup`, `create-pr`, `version-bump`, `version-check`)

### Doporuceni

**Ponechat prefix** — duvody:

1. **Plugin name-derived** — prefix vychazi z `"name": "CLAUDE-agents"` v `plugin.json` a (dle dosavadniho pozorovani) je automaticky aplikovan na vsechny commands pluginu
2. **Namespace safety** — s rostoucim ekosystemem pluginu roste riziko kolizi u generickych nazvu
3. **Konzistence** — mix prefixed/unprefixed by byl matouci
4. **UX zmirneni** — uzivatele mohou pouzit tab-complete (`/CL<tab>` → rozbali se na `CLAUDE-agents:`)
5. **Skill routing** — skill `CLAUDE-agents:bug-workflow` umoznuje natural language pristup bez znalosti presneho command nazvu. Toto je jiz existujici alternativa k prefixovanym nazvum — uzivatel muze pouzit prirozeny jazyk misto `/CLAUDE-agents:<command>`

### Alternativy ke zvazeni

| Moznost | Pro | Proti |
|---------|-----|-------|
| Ponechat prefix (status quo) | Bezpecne, konzistentni | Verbose |
| Prejmenovat plugin na kratsi nazev | Kratsi prefix (napr. `ca:fix-bugs`) | Breaking change, ztrata brand recognition |
| Aliasy bez prefixu | UX zlepseni | Dle dosavadniho pozorovani Claude Code platformou nepodporovano |
| Skill routing (jiz existuje) | Natural language pristup, zadny prefix nutny | Pokryva jen cast commandu, mene predikovatelne |

---

## Rozhodovaci otazky

1. **Je URL `codeberg.org/forgejo/forgejo-mcp` spravna, nebo je spravna `codeberg.org/goern/forgejo-mcp`?**
   Toto je prerequisite pro jakoukoli opravu. Je nutne overit na Codeberg pred dalsimi kroky.

2. **Chces opravit URL jen ve 2 aktivnich souborech, nebo i ve 4 historickych `docs/plans/` souborech?**
   Doporuceni: opravit jen aktivni soubory. Historicke jsou archivni a nemaji dopad na uzivatele.

3. **Je prejmenování pluginu na kratsi nazev (napr. `claude-agents` → prefix `ca:`) realisticka moznost, nebo je brand `CLAUDE-agents` fixni?**
   CLAUDE.md explicitne definuje `CLAUDE-agents` jako brand a installation path. Prejmenování by bylo breaking change.

4. **Chces pridat do dokumentace poznamku o tab-complete a skill routing jako UX tip pro nove uzivatele?**
   Doporuceni: ano, vhodne misto je `docs/guides/installation.md` (po instalaci pluginu) nebo closing message v `/CLAUDE-agents:onboard`.

5. **Chces pridat do CLAUDE.md nebo docs/ sekci "Command Quick Reference" s kratkymi aliasy pro dokumentaci (nikoliv funkcni aliasy)?**
   Nizka priorita, ale muze zlepsit onboarding experience.

---

