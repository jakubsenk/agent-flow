# 03 — Onboard directory scope bug

## Aktuální stav

### Problém

Při spuštění `/CLAUDE-agents:onboard` se command pokusil upravit CLAUDE.md o úroveň výš, mimo adresář projektu. Uživatel musel manuálně korigovat.

### Analýza implementace

V `commands/onboard.md`, Step 0:

```
1. Read the target project's CLAUDE.md
2. Look for `## Automation Config` section
```

**Klíčový nález:** Command nikde nedefinuje, co znamená "the target project". Nespecifikuje:
- Cestu k CLAUDE.md
- Zda použít CWD, git root, nebo jinou logiku
- Jak se chovat, pokud CLAUDE.md neexistuje v CWD

Fráze "the target project's CLAUDE.md" je **vágní** — nechává na modelu, kam zapíše.

### Rozsah problému — 7 commands se stejnou formulací

Problém se netýká pouze `onboard`. Formulace "the target project's CLAUDE.md" se vyskytuje identicky v 7 commands:

| Command | Řádek | Formulace | Write-capable? | Riziko |
|---------|-------|-----------|---------------|--------|
| `onboard` | 18 | "Read the target project's CLAUDE.md" | **Ano** (Write, Edit) | **Vysoké** — může zapsat config na špatné místo |
| `migrate-config` | 12 | "Read the target project's CLAUDE.md" | **Ano** (Edit) | **Vysoké** — může přepsat cizí CLAUDE.md |
| `implement-feature` | 12 | "Read from the target project's CLAUDE.md" | **Ano** (Write, Edit) | **Střední** — čte config, ale píše kód, ne config |
| `dashboard` | 19 | "Read from the target project's CLAUDE.md" | Ano (Write — HTML) | Nízké — píše HTML soubor, ne CLAUDE.md |
| `estimate` | 12 | "Read from the target project's CLAUDE.md" | Ne | Nízké — read-only, ale může číst špatný config |
| `prioritize` | 12 | "Read from the target project's CLAUDE.md" | Ne | Nízké — read-only |
| `metrics` | 18 | "Read from the target project's CLAUDE.md" | Ne | Nízké — read-only |

Pro srovnání — ostatní commands používají jasnější formulace:

| Command | Formulace | Riziko |
|---------|-----------|--------|
| `fix-ticket` | "Read Automation Config from CLAUDE.md" + "Work in the current directory" | Nízké — explicitní CWD |
| `fix-bugs` | "Read Automation Config from CLAUDE.md" | Nízké — implicitní CWD |
| `check-setup` | "Read the current project's CLAUDE.md" | Nízké — "current" je jasné |
| `status` | "Read Automation Config from CLAUDE.md of the current project" | Nízké — "current project" |
| `analyze-bug` | "Read Automation Config from CLAUDE.md" | Nízké — implicitní CWD |
| `changelog` | "Read Automation Config from CLAUDE.md" | Nízké — implicitní CWD |
| `publish` | "Read Automation Config from CLAUDE.md" | Nízké — implicitní CWD |
| `create-pr` | "Read Automation Config from CLAUDE.md" | Nízké — implicitní CWD |
| `resume-ticket` | "Read Automation Config from CLAUDE.md" | Nízké — implicitní CWD |
| `scaffold` | "State detection" sekce — "check the target directory" | Specifické — jde o nový projekt |
| `scaffold-add` | "if it exists in CLAUDE.md or from auto-detect" (write-capable) | Nízké — CLAUDE.md reference v kontextu build/test detekce |
| `scaffold-validate` | "current directory" | Nízké — explicitní CWD |
| `template` | Read-only, nepíše do souborů | N/A |
| `version-bump` | Plugin-internal | N/A |
| `version-check` | Plugin-internal | N/A |

### Příčina bugu

1. **"target project" ≠ "current directory"** — slovo "target" implikuje, že projekt může být jinde
2. **Žádný explicit constraint** — model může hledat CLAUDE.md v parent directories
3. **Model sám rozhodne prohledat nadřazené adresáře** — pokud CLAUDE.md neexistuje v CWD, model (ne Read tool) se rozhodne zadat cestu k parent directory. Read tool čte konkrétní zadanou cestu — problém je v tom, že prompt nespecifikuje kterou cestu zadat, a model hledá v hierarchii sám.
4. **Step 8 (Output Options)** říká "Write directly into CLAUDE.md" — bez specifikace absolutní cesty
5. **Step U3 (Update mode)** má stejný problém — "Write to CLAUDE.md after confirmation" bez specifikace cesty. V update mode je to potenciálně horší, protože model nejprve naparsuje existující config z parent directory a pak ho přepíše.

### Prompt-level vs. technický guard

Navrhovaný fix je pouze na úrovni promptu (textový constraint). Command `onboard` má `allowed-tools: Read, Glob, Write, Edit` — Write i Edit tool umožňují zápis do libovolné cesty. Neexistuje technický guard (např. omezení allowed-tools na konkrétní adresář), který by zápis mimo CWD fyzicky znemožnil.

Stejné platí pro `migrate-config` (allowed-tools: Read, Edit, Glob) — Edit umožňuje editaci libovolného souboru.

To znamená, že robustnost fixu závisí čistě na tom, jak spolehlivě model dodržuje textové instrukce. Pro CLAUDE-agents plugin (který je celý prompt-based) je to konzistentní přístup — všechny constrainty ve všech agents a commands jsou prompt-level.

---

## Navrhované řešení

### Varianta 1: Explicitní CWD constraint (doporučeno)

Přidat na začátek onboard.md:

```markdown
## Scope

This command operates on the CLAUDE.md file in the CURRENT WORKING DIRECTORY.
- Target file: `./CLAUDE.md` (relative to CWD)
- If `./CLAUDE.md` does not exist: create it in CWD
- NEVER read or write CLAUDE.md outside of CWD
- NEVER traverse parent directories to find CLAUDE.md
```

A upravit Step 0:
```
1. Read `./CLAUDE.md` in the current working directory
   - If file does not exist → Fresh mode (step 1), will create it in CWD
```

A upravit Step U3 (Update mode):
```
- "Apply changes to CLAUDE.md? [Y/n]"
- Write to `./CLAUDE.md` in the current working directory after confirmation
```

**Pro:** Jednoduchý, jasný, žádná ambiguita.
**Proti:** Nefunguje dobře v monorepo (viz edge cases).

### Varianta 2: Git root detection

```markdown
## Scope

Target directory = git repository root (result of `git rev-parse --show-toplevel`).
If not in a git repo → use CWD.
```

**Pro:** Konzistentní s tím, kde obvykle CLAUDE.md žije.
**Proti:** V monorepo může být CLAUDE.md v subrepu, ne v root.

### Varianta 3: Interaktivní potvrzení cesty

```markdown
Step 0.5: Confirm target directory
"I'll write Automation Config to: {CWD}/CLAUDE.md. Is this correct? [Y/n/path]"
```

**Pro:** Uživatel vždy ví, kam se zapisuje.
**Proti:** Extra krok v každém běhu.

### Doporučení: Varianta 1 + safety check z Varianty 3

```
1. Defaultně operuj na `./CLAUDE.md` (CWD)
2. Před zápisem (Step 8 i Step U3) zobraz: "Will write to: {absolute_path}/CLAUDE.md"
3. NEVER traverse parent directories
```

---

## Edge cases

### 1. Monorepo (více CLAUDE.md na různých úrovních)

```
/monorepo/
  CLAUDE.md              ← root config
  /packages/web/
    CLAUDE.md            ← package-specific config
    src/
```

**Scénář:** Uživatel spustí onboard z `/packages/web/`. Kam psát?

**Řešení:** Vždy CWD. Pokud uživatel chce root config, musí spustit z rootu.
**Upozornění:** Přidat poznámku:
```
Note: This command writes to CLAUDE.md in your current directory.
For monorepos, run this command from each package directory separately.
```

### 2. Nested projects / submoduly

```
/project/
  CLAUDE.md
  /vendor/submodule/
    CLAUDE.md
```

**Scénář:** Uživatel je v `/vendor/submodule/` a spustí onboard.

**Řešení:** CWD constraint funguje správně — zapíše do submodulu.

### 3. Symlinky

```
/projects/myapp/ → /home/user/actual-project/
```

**Scénář:** CWD je symlink.

**Řešení:** Použít resolved path (`realpath`) pro display, ale operovat na CWD. Symlinky by neměly ovlivnit chování.

### 4. Spuštění z podadresáře (src/)

```
/project/
  CLAUDE.md
  src/
    components/
```

**Scénář:** Uživatel je v `/project/src/components/` a spustí onboard.

**Řešení:** CWD constraint zapíše CLAUDE.md do `src/components/` — **to je špatně**.

**Vylepšení:** Přidat heuristiku:
```
If CWD is NOT a git root AND parent directories contain CLAUDE.md:
  "You're in a subdirectory. CLAUDE.md exists at {parent}/CLAUDE.md.
   Write here ({CWD}) or there ({parent})? [here/THERE]"
```

### 5. Prázdný adresář (nový projekt)

**Scénář:** Uživatel spustí onboard v prázdném adresáři bez git.

**Řešení:** Vytvořit CLAUDE.md v CWD. Přidat `git init` doporučení do closing message.

### 6. Spuštění z plugin directory

**Scénář:** Uživatel omylem spustí `/CLAUDE-agents:onboard` z adresáře CLAUDE-agents pluginu samotného (kde existuje CLAUDE.md s pluginovou dokumentací, ne s Automation Config).

**Řešení:** CWD constraint by vedl k zápisu Automation Config do pluginového CLAUDE.md — to je nežádoucí. Heuristika:
```
If CWD contains `.claude-plugin/plugin.json`:
  "Warning: You appear to be in a plugin directory, not a project directory.
   Automation Config should be in your project's CLAUDE.md, not here.
   Continue anyway? [y/N]"
```

### 7. `--fresh` flag a detekce

**Scénář:** Uživatel spustí `onboard --fresh`. Flag `--fresh` přeskakuje detekci existujícího configu (Step 0, bod 3).

**Důsledek:** V `--fresh` mode neexistuje ani heuristika pro nalezení existujícího CLAUDE.md — command rovnou přejde do Fresh mode. Pokud CLAUDE.md existuje v parent directory, `--fresh` ho zcela ignoruje a vytvoří nový v CWD. To je v zásadě **správné chování** s CWD constraintem, ale bez constraintu může model stále hledat v parent directories.

**Řešení:** CWD constraint musí platit nezávisle na `--fresh`/`--update` flagech.

---

## Rozsah fixu

### Minimální fix (doporučeno pro patch release)

1. Přidat `## Scope` sekci do `commands/onboard.md` s explicitním CWD constraintem
2. V Step 8 i Step U3 zobrazit absolutní cestu před zápisem
3. Přidat `NEVER traverse parent directories` constraint

### Rozšířený fix (minor release)

1. Minimální fix +
2. Heuristika pro detekci subdirectory (viz edge case 4)
3. Aplikovat stejný pattern na `migrate-config.md` (stejný problém — identická "target project's" formulace a write-capable)
4. Přidat do `check-setup` kontrolu: "CLAUDE.md detected at {path}" s absolutní cestou

### Systémový fix (minor release, vyšší scope)

1. Rozšířený fix +
2. Sjednotit formulaci "target project's CLAUDE.md" → "Read Automation Config from CLAUDE.md" (nebo "Read from CLAUDE.md in the current working directory") napříč všech 7 postižených commands
3. Tím se odstraní systémová nekonzistence — commands, které dělají totéž, budou používat stejný jazyk

---

## Rozhodovací otázky

1. **CWD nebo git root jako default?** CWD je jednodušší a bezpečnější, ale git root je "správnější" pro většinu projektů.

2. **Má onboard zobrazit potvrzení cesty před zápisem?** (Extra krok, ale prevence chyb.)

3. **Jak řešit spuštění ze subdirectory?** Tiše zapsat do CWD, nebo detekovat parent CLAUDE.md a zeptat se?

4. **Má se stejný fix aplikovat i na `migrate-config`?** (Má identickou "target project's" formulaci a je write-capable.)

5. **Je to patch fix (jen constraint text) nebo minor (heuristika + potvrzení)?**

6. **Má se "target project's CLAUDE.md" standardizovat napříč VŠEMI commands?** Formulace "target project's" se vyskytuje v 7 commands. Některé jsou read-only (estimate, prioritize, metrics), takže riziko je nižší, ale nekonzistence v jazyce může vést k nekonzistentnímu chování modelu. Varianty:
   - **A) Opravit jen write-capable commands** (onboard, migrate-config) — minimální scope, adresuje reálné riziko
   - **B) Sjednotit formulaci ve všech 7 commands** — systémová konzistence, ale větší diff
   - **C) Sjednotit ve všech 22 commands** — ideální konzistence, ale over-engineering pro commands, které už fungují správně

---

