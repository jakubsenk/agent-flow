# Public Release Plan — ceos-agents

**Datum:** 2026-04-29
**Status:** Approved direction, awaiting execution
**Verze pluginu:** v8.0.0 (released, on gitea internal)

---

## Rozhodnutí

### Ownership: **osobní účet `fsabacky`**, ne org `ceosdata`

Repo bude `github.com/fsabacky/ceos-agents`. CEOS Data atribuovaná v `plugin.json:author.email` (`filip.sabacky@ceosdata.com`) a v README footeru ("Built at CEOS Data"). Migrace na org je vždy možná později (`Settings → Transfer ownership`); opak (osobní → poté zpět) ztrácí stars a inbound linky.

**Důvody pro osobní účet:**
- Open-source plugin = osobní brand. Org účet u solo projektu působí korporátně.
- Reputace kumuluje autorovi, ne firmě. Při změně zaměstnání plugin zůstane v firmě, autor začíná od nuly.
- Žádné firemní právní review při každém releasu = rychlost.
- MIT + author "Filip Sabacky" už v `plugin.json` máš. Konzistence.

**Kdy by dávalo smysl `ceosdata/ceos-agents`:** komerční SLA tier, multiple maintaineři, firemní OSS strategie. Žádný z těch důvodů aktuálně neplatí.

### Hosting: **GitHub primary, Gitea secondary mirror**

GitHub kvůli:
- `claude plugin marketplace add owner/repo` shortcut funguje pro GitHub nativně.
- Discoverability (awesome-lists, search).
- GitHub Releases jako changelog UI.

Gitea internal zůstane jako secondary mirror — kontinuita CI/historie.

### Strategie: **Tichý launch teď, hlasitý launch s v9.3.0**

Anti-pattern: čekat na "až bude všechno ready" → uvolní se nikdy. Plugin je v8.0.0, FULL_PASS 0.863, technicky vyzrálý. **Uvolnit teď, anonymně, bez fanfár.** Marketing až bude co ukázat (web + demo).

---

## Fáze

### PHASE 1 — Repo prep (lokálně, žádný push)

**Audit + fix placeholderů:**
- `plugin.json:repository` z `https://example.invalid/ceos-agents.git` → `https://github.com/fsabacky/ceos-agents.git`
- `marketplace.json` přidat `repository` field
- README Quick Start: `claude plugin marketplace add <path-to-repo>` → `claude plugin marketplace add fsabacky/ceos-agents`
- LICENSE copyright header (verify "Filip Sabacky" + rok)

**Cleanup `.forge.bak-*` (50+ adresářů):**
- Přidat do `.gitignore`: `.forge.bak-*/`
- `git rm -r --cached .forge.bak-*` (z indexu, nechat na disku)
- Případně i fyzicky smazat z workdiru
- Ne přepisovat historii — kdo chce forge audit trail najde si v `git log`

**README footer:** "Built at [CEOS Data](https://ceosdata.com)" — atribuce bez ownershipu.

**Verify cross-file invariants** (CLAUDE.md §Cross-File Invariants):
1. License SPDX `"MIT"` v plugin.json + marketplace.json + LICENSE heading
2. Maintainer email `filip.sabacky@ceosdata.com` v SECURITY.md + CODE_OF_CONDUCT.md + CONTRIBUTING.md
3. Issue/PR template parity `.gitea/` ↔ `.github/`

### PHASE 2 — GitHub setup

1. Vytvoření public repo `github.com/fsabacky/ceos-agents` (prázdný, MIT, bez auto-README)
2. `git remote add github git@github.com:fsabacky/ceos-agents.git`
3. `git push github main --tags` (všechny tagy v6.7.0..v8.0.0)
4. GitHub Releases pro v8.0.0 (release notes z CHANGELOG.md)
5. **Repo settings:**
   - Issues: ON
   - Discussions: ON
   - Wiki: OFF (docs jsou v repu)
   - Projects: OFF
6. **Topics:** `claude-code`, `plugin`, `ai-agents`, `devtools`, `automation`, `bug-fixing`, `code-review`
7. **Branch protection na main:** require PR, require status checks (až bude CI)
8. **Reservace jmen:** vytvořit prázdné `github.com/fsabacky/ceos-agents-web` a `github.com/fsabacky/ceos-agents-demo` aby je nikdo nesquatnul

### PHASE 3 — Verification

1. Fresh klon do `/tmp/ceos-test/`
2. `claude plugin marketplace add fsabacky/ceos-agents`
3. `claude plugin install ceos-agents@ceos-agents`
4. Smoke test:
   - `/ceos-agents:check-setup`
   - `/ceos-agents:onboard --dry-run` (pokud existuje)
   - `/ceos-agents:version-check`
5. README odkazy → linkcheck (markdown-link-check nebo manuálně)
6. Cross-platform smoke: alespoň jeden test na macOS/Linux (WSL stačí)

**Stop condition:** všechny smoke testy zelené, install z `claude plugin marketplace add` funguje na čisté instalaci.

### PHASE 4 — Release polish (= roadmap v9.3.0)

Předpoklad: PHASE 1-3 zelené, plugin **leží** na GitHubu, pár early adopterů to zkouší 1:1.

1. **Showcase web deploy** (`ceos-agents-web` v0.1.0) — host na canonical doméně
2. **Demo repo** (`ceos-agents-demo`) — minimal example projekt s issues k fixnutí, hands-on tutorial
3. **Canonical URL + DNS** (např. `ceos-agents.dev` nebo `ceosdata.com/agents`)
4. **README rewrite** se screenshoty/GIF dema, link na hosted web

### PHASE 5 — Announcement

1. PR do `awesome-claude-code-plugins` (komunitní list na GitHubu)
2. Post na Anthropic Discord, kanál `#community-creations` (nebo aktuální ekvivalent)
3. X/Twitter post — tag @AnthropicAI, hashtag #ClaudeCode
4. LinkedIn post (volitelně, brand pro CEOS Data)
5. Blog post na `ceosdata.com/blog` (volitelně)

### PHASE 6 — Post-launch (T+2 týdny)

1. Triage prvních issues od externích uživatelů
2. v8.0.1 polish ticket merge (7 LOW items)
3. Setup recurring `/schedule` agenta na issue triage (volitelně)
4. Sledovat install metrics (jestli existují)

---

## Co **nedělat** v první iteraci

- ❌ Nečekat na v8.0.1 polish (non-blocking)
- ❌ Nepushovat 50+ `.forge.bak-*` adresářů
- ❌ Nepsat forge brief na tohle (4-5 souborů změnit, ne multi-week feature)
- ❌ Branch protection / signed commits / DCO (solo maintainer, nemá smysl)
- ❌ Hlasitý announce před hosted demo
- ❌ Migrace na org dokud nebude důvod (komerční tier nebo team)

---

## Konkrétní acceptance criteria pro "lze uvolnit"

**Minimum viable launch (PHASE 1-3, ~půlden):**
- AC-1: `plugin.json:repository` neobsahuje `example.invalid`
- AC-2: README Quick Start install command funguje na čisté instalaci
- AC-3: `.forge.bak-*` adresáře nejsou na public GitHub
- AC-4: Všechny 3 cross-file invariants verified zelené
- AC-5: Smoke test `claude plugin install` z fresh klonu projde
- AC-6: Repos `ceos-agents-web` a `ceos-agents-demo` rezervované

**Plný launch (PHASE 4-5, ~3-5 dní):**
- AC-7: Hosted showcase web na canonical URL
- AC-8: Demo repo s minimálně 3 reálnými issues k fixnutí
- AC-9: README obsahuje aspoň 1 GIF/screenshot dema
- AC-10: PR submitted do awesome-claude-code-plugins

---

## Otevřené otázky

1. **GitHub username:** `fsabacky` předpokládám — verify že je dostupný a tvůj.
2. **Canonical doména:** koupit `ceos-agents.dev`/`.io`/`.app` nebo subdoména `agents.ceosdata.com`? (Nutí rozhodnout pro PHASE 4.)
3. **CI po push na GitHub:** GitHub Actions enabled? (Memory zmiňuje Gitea Actions runner not configured — GitHub Actions je free pro public repos, mohlo by sjednotit CI.)
4. **Gitea internal mirror — keep nebo retire?** Pokud GitHub bude primary, jaký je důvod udržovat dva remotes long-term?

---

## Reference

- CLAUDE.md §Versioning Policy — pro v8.0.1 vs v9.x rozhodnutí
- CLAUDE.md §Cross-File Invariants — verify checks
- MEMORY.md → Roadmap Items → v9.2.0 (demo) + v9.3.0 (G polish)
- ceos-agents-web repo → v0.1.0 status
