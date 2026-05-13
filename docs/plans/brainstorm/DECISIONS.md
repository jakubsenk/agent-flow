# Brainstorm rozhodnuti

Stav: PROBIHAJICI

## Doc 01 — Forgejo MCP opravy + prefix analyza

| # | Otazka | Rozhodnuti | Status |
|---|--------|-----------|--------|
| 1 | Je URL `forgejo/forgejo-mcp` nebo `goern/forgejo-mcp`? | **`goern/forgejo-mcp`** — overeno na Codeberg (forgejo/forgejo-mcp = 404) | ROZHODNUTO |
| 2 | Opravit URL jen v aktivnich nebo i historickych souborech? | **Jen aktivni soubory** (2 soubory) | ROZHODNUTO |
| 3 | Prejmenovat plugin na kratsi nazev? | **Ano — prejmenovat na `ceos-agents`**. Vcetne repo rename v Gitea. Breaking change, 4 uzivatele. | ROZHODNUTO |
| 4 | Pridat UX tip o tab-complete a skill routing? | **Ano** — pridat do closing message onboard wizardu | ROZHODNUTO |
| 5 | Pridat "Command Quick Reference" sekci? | **Ne** — nizka priorita, skill routing pokryva use case | ROZHODNUTO |

**Status: DOKONCEN**

## Doc 02 — Onboard MCP tokens

Klicove architektonicke rozhodnuti: **Novy command `init`** pro developer environment setup. Onboard zustava jen pro projekt.

| # | Otazka | Rozhodnuti | Status |
|---|--------|-----------|--------|
| 1 | Rozsirit `allowed-tools` v onboard? | **Ne** — onboard zustava ciste souborovy. Novy command `init` bude mit `Read, Glob, Write, Edit, Bash, mcp__*`. | ROZHODNUTO |
| 2 | Kde v onboard flow umistit MCP setup? | **Nikde** — MCP setup patri do noveho `init` commandu. Onboard v closing message odkaze na `init`. | ROZHODNUTO |
| 3 | Generovat `.mcp.json` automaticky nebo tisknout template? | **Automaticky** — `init` precte Automation Config, vi jaky tracker, vygeneruje `.mcp.json` a zapise. | ROZHODNUTO |
| 4 | Jak resit Forgejo MCP binarku? | **`init` se zepta na platformu** (nebo detekuje pres `Bash` — ma k nemu pristup) a navede ke stazeni spravne binarky. | ROZHODNUTO |
| 5 | Update mod — aktualizovat existujici `.mcp.json`? | **Ano** — `init` musi umi merge (zachovat cizi servery, aktualizovat jen relevantni). | ROZHODNUTO |
| 6 | Validace konektivity v onboardu? | **Ne v onboardu, ano v `init`** — `init` ma `mcp__*` a po konfiguraci pingne server. | ROZHODNUTO |
| 7 | Sdileny MCP server (Gitea/GitHub)? | **`init` detekuje shodu** tracker+SC → jedna konfigurace, zadna duplikace. | ROZHODNUTO |
| 8 | Konfigurovat i source control MCP? | **Ano** — `init` konfiguruje vse co pipeline potrebuje (tracker + SC). | ROZHODNUTO |

**Status: DOKONCEN**

## Doc 03 — Onboard directory scope

| # | Otazka | Rozhodnuti | Status |
|---|--------|-----------|--------|
| 1 | CWD nebo git root jako default? | **Git root** — CLAUDE.md patri do korene projektu. Standard (git init, npm init). | ROZHODNUTO |
| 2 | Zobrazit potvrzeni cesty pred zapisem? | **Ano** — `Target: {path} — Is this correct? [Y/n/custom path]`. Resi i monorepo. | ROZHODNUTO |
| 3 | Jak resit spusteni ze subdirectory? | **Vyreseno otazkami 1+2** — git root + confirm. Uzivatel vidi a muze zmenit. | ROZHODNUTO |
| 4 | Aplikovat fix i na migrate-config? | **Ano** — identicka formulace, write-capable, stejne riziko. | ROZHODNUTO |
| 5 | Patch nebo minor? | **Minor** — heuristika + potvrzeni, ne jen text change. | ROZHODNUTO |
| 6 | Standardizovat formulaci napric commands? | **Varianta B** — sjednotit ve vsech 7 commands s "target project's". A je nedusledna, C je over-engineering. | ROZHODNUTO |

**Status: DOKONCEN**

## Doc 04 — Scaffold completeness

**POZASTAVENO — vyzaduje redesign.** Scaffold v2 ma amatersky flow — chybi strukturovany rozpad: Specifikace → Epicy → Features → Task tree → Implementace. Soucasni agenti (spec-analyst, architect) jsou navrzeni pro single issue, ne cely projekt. Pred rozhodovanim o detailech (Q1-Q10) je nutne navrhnout profesionalni specifikacni flow. Samostatny brainstorm.

| # | Otazka | Rozhodnuti | Status |
|---|--------|-----------|--------|
| 1 | Default chovani scaffoldu | **(c) Interaktivni prompt** — zeptat se uzivatele | ROZHODNUTO |
| 2-10 | Zbyle otazky | **Pozastaveno** — zavisi na redesignu specifikacniho flow | POZASTAVENO |

**Status: POZASTAVENO**

## Doc 05 — Fix-bugs token discovery

| # | Otazka | Rozhodnuti | Status |
|---|--------|-----------|--------|
| 1 | Dokumentace nebo i diagnostika v check-setup? | **Oboji** — docs pro onboarding, check-setup diagnostika pro debugging. | ROZHODNUTO |
| 2 | Check-setup hledat `.mcp.json` v parent dirs? | **Ano** — diagnostika, zadny side-effect. Hlaska: "Found at ../, but Claude Code loads from CWD." | ROZHODNUTO |
| 3 | Onboard generovat `.mcp.json`? | **Ne** — resi novy `init` command (viz doc 02). | ROZHODNUTO |
| 4 | Warning o CWD v closing message? | **Ano** — strucne: "Run `/ceos-agents:init` to configure MCP servers." | ROZHODNUTO |
| 5 | Rozlisovat "not configured" vs "not running"? | **Ano** — dve ruzne chybove hlasky, dva ruzne next steps. | ROZHODNUTO |
| 6 | Pre-flight check pro 4 nebo 16 commands? | **Vsech 16** — guard clause je jednoradkovy, konzistentni UX. | ROZHODNUTO |
| 7 | Patch nebo minor? | **Minor** — nova diagnostika v check-setup + guard clause. | ROZHODNUTO |

**Status: DOKONCEN**

## Doc 06 — Session resume permissions

Klicove rozhodnuti: Permissions setup je soucast noveho `init` commandu (doc 02), ne onboardu.

| # | Otazka | Rozhodnuti | Status |
|---|--------|-----------|--------|
| 1 | Patch nebo minor? Spojit s doc 02? | **Minor, spojit.** `init` resi MCP + permissions v jednom flow. Docs update (troubleshooting) jako patch mezitim. | ROZHODNUTO |
| 2 | Generovat `.claude/settings.json`? Jaky allowlist? | **Ano, `init` nabidne volbu:** Full pipeline / Read-only / Minimal / Custom. | ROZHODNUTO |
| 3 | Reportovat upstream? | **Ano** — ztrata permissions pri `claude -c` muze byt bug. Reprodukcni kroky jsou v dokumentu. | ROZHODNUTO |
| 4 | MCP wildcard vs specificke? | **Specificke** — `init` generuje dle zvoleneho trackeru (`mcp__gitea__*`, ne `mcp__*`). Bezpecnejsi. | ROZHODNUTO |
| 5 | Pre-flight MCP check v resume-ticket? | **Ano** — guard clause jako u vsech 16 MCP-zavislych commands (doc 05 Q6). | ROZHODNUTO |

**Status: DOKONCEN**

## Doc 07 — Unified improvements summary

Nema vlastni rozhodovaci otazky — vsechny jsou kopie z doc 01-06 a byly rozhodnuty tam.

**Status: DOKONCEN**

---

## Souhrnny stav

| Doc | Tema | Status |
|-----|------|--------|
| 01 | Forgejo MCP + prefix | DOKONCEN |
| 02 | Onboard MCP tokens → novy `init` command | DOKONCEN |
| 03 | Onboard directory scope | DOKONCEN |
| 04 | Scaffold completeness | POZASTAVENO — vyzaduje redesign specifikacniho flow |
| 05 | Fix-bugs token discovery | DOKONCEN |
| 06 | Session resume permissions | DOKONCEN |
| 07 | Unified summary | DOKONCEN |

## Klicova architektonicka rozhodnuti (cross-doc)

1. **Novy command `init`** — developer environment setup (MCP servery, tokeny, permissions). Oddeleno od `onboard` (projekt). Best practice pattern `.env.example` vs `.env`.
2. **Rename na `ceos-agents`** — vcetne repo rename v Gitea. Breaking change, 4 uzivatele.
3. **Git root + confirm** — default pro vsechny write commands. Standard (git init, npm init).
4. **Guard clause ve vsech 16 MCP commands** — jednoradkovy pre-flight check.
5. **Scaffold v2 pozastaven** — chybi profesionalni specifikacni flow (Spec → Epicy → Features → Tasks → Implementace).
