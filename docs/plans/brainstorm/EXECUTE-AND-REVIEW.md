# Implementace a iterativní review — ceos-agents v3.4.0

> **Pro Claude:** Tohle je dvou-fázový prompt. Nejdřív implementuj, pak reviewuj dokud není vše bez chyby.

---

## FÁZE 1: IMPLEMENTACE

Máš k dispozici implementační plán: `docs/plans/brainstorm/IMPLEMENTATION-PLAN.md`

### Instrukce

1. **Přečti CELÝ plán** — od začátku do konce, včetně Review sekce
2. **Implementuj fáze 1–7** v pořadí, task po tasku
3. **Po každé fázi spusť verifikační příkazy** uvedené v plánu
4. **Po každé fázi commitni** přesně podle commit message v plánu
5. **Prerequisity (P1–P4):** P2 (vytvoř redmine.json) udělej jako první. P1 (URL ověření) a P3 (komunikace uživatelům) a P4 (Gitea repo rename) jsou manuální — přeskoč je, zapiš TODO.

### Pravidla implementace

- Používej `replace_all: true` kde plán říká "replace all" (zejména Phase 1 rename)
- Pro Phase 1: zpracuj soubory po skupinách (metadata → skill → commands → agents → docs → root → tests → plans), NE jeden po jednom
- Pro Phase 3 Task 3.3: edituj content matchingem (old_string/new_string), NE line numbers
- Pro Phase 4: `commands/init.md` je NOVÝ soubor — použij Write tool
- Pro Phase 6: zkopíruj guard clause template přesně dle plánu do 15 commands
- NEPŘIDÁVEJ nic co není v plánu — žádné extra features, žádné "vylepšení"
- NEMĚŇ soubory v `docs/plans/brainstorm/` ani `docs/plans/2026-*`
- Piš anglicky (všechen obsah souborů)

### Pořadí commitů

```
1. feat!: rename plugin CLAUDE-agents → ceos-agents
2. fix: correct Forgejo MCP URL to goern/forgejo-mcp + add UX tip to onboard
3. fix: directory scope — git root + confirm, unify CLAUDE.md wording in 7 commands
4. feat: add /ceos-agents:init command for MCP + permissions setup
5. fix: check-setup — distinguish not-configured vs not-running, parent dir detection
6. feat: add MCP pre-flight guard clause to 15 pipeline commands
7. docs: add permission troubleshooting section
```

### NEPOUŽÍVEJ version-bump

Verzi (CHANGELOG, plugin.json, marketplace.json bump, tag) budeme dělat ZVLÁŠŤ po review. Commituj jen obsahové změny.

---

## FÁZE 2: ITERATIVNÍ REVIEW

Po dokončení VŠECH 7 commitů spusť iterativní review:

### Krok R1: Verifikační grepe

Spusť VŠECHNY tyto příkazy a zapiš výsledky:

```bash
# 1. Žádné CLAUDE-agents v aktivních souborech
grep -rl "CLAUDE-agents" --include="*.md" --include="*.json" --include="*.yaml" --include="*.sh" . | grep -v "docs/plans/2026-" | grep -v ".claude/" | grep -v "docs/plans/brainstorm" | grep -v "REVIEW-REPORT" | grep -v "EXECUTE-AND-REVIEW"

# 2. Žádné forgejo/forgejo-mcp v docs/guides a examples
grep -r "forgejo/forgejo-mcp" docs/guides/ docs/reference/ examples/

# 3. Žádné "target project's CLAUDE.md" v commands
grep -r "target project's CLAUDE.md" commands/

# 4. Guard clause ve správném počtu commands
grep -l "MCP pre-flight check" commands/*.md | wc -l
# Expected: 15

# 5. Soubory BEZ guard clause
grep -L "MCP pre-flight check" commands/*.md
# Expected: 8 files (check-setup, init, onboard, migrate-config, scaffold-validate, template, version-bump, version-check)

# 6. Nový init command existuje
test -f commands/init.md && echo "OK" || echo "MISSING"

# 7. Nový redmine.json existuje
test -f examples/mcp-configs/redmine.json && echo "OK" || echo "MISSING"

# 8. Plugin metadata správně
grep -c "ceos-agents" .claude-plugin/plugin.json .claude-plugin/marketplace.json
# Expected: plugin.json:2, marketplace.json:2

# 9. SKILL.md přejmenován
grep -c "ceos-agents" skills/bug-workflow/SKILL.md
# Expected: 26

# 10. Scope section v onboard a migrate-config
grep -c "## Scope" commands/onboard.md commands/migrate-config.md
# Expected: 1 each

# 11. Resume-ticket backwards compat — musí detekovat OBA prefixy
grep -c "CLAUDE-agents" commands/resume-ticket.md
# Expected: > 0 (legacy prefix v detekci)

# 12. Check-setup parent dir detection
grep "parent" commands/check-setup.md
# Expected: match (parent directory detection)

# 13. Troubleshooting permission section
grep "Permission Issues" docs/guides/troubleshooting.md
# Expected: match

# 14. Onboard closing message odkazuje na init
grep "init" commands/onboard.md
# Expected: match (reference to /ceos-agents:init)

# 15. UX tip v onboard
grep "tab-completion\|tab-complete\|skill router" commands/onboard.md
# Expected: match
```

### Krok R2: Obsahový review

Pro KAŽDÝ modifikovaný soubor:
1. Přečti ho celý
2. Ověř že neobsahuje nekonzistence (např. `CLAUDE-agents` v jednom místě a `ceos-agents` jinde)
3. Ověř že markdown formátování je validní (žádné rozbité tabulky, nekončící code bloky)
4. Ověř že frontmatter je intaktní (---/--- bloky na začátku commands a agents)

**Minimum files to full-read:**
- commands/resume-ticket.md (backwards compat)
- commands/onboard.md (Scope + closing message + UX tip)
- commands/migrate-config.md (Scope)
- commands/check-setup.md (Block 2+3 rewrite)
- commands/init.md (nový — celý)
- commands/fix-bugs.md (guard clause insertion point)
- commands/fix-ticket.md (guard clause)
- skills/bug-workflow/SKILL.md (26 renames)
- .claude-plugin/plugin.json
- .claude-plugin/marketplace.json
- docs/guides/troubleshooting.md (new section)
- docs/guides/mcp-configuration.md (URL fix)
- docs/guides/installation.md (URL fix)
- CLAUDE.md (rename + install instruction)
- README.md (rename)

### Krok R3: Zapiš findings

Pro každý finding:
- Soubor a řádek
- Co je špatně
- Severity: CRITICAL (rozbité fungování) / HIGH (špatný výstup) / MEDIUM (nepřesnost) / LOW (kosmetické)

### Krok R4: Oprav

Pro CRITICAL a HIGH findings: oprav okamžitě, amenduj příslušný commit.
Pro MEDIUM: oprav, commitni jako `fix: review corrections for v3.4.0`.

### Krok R5: Opakuj

Po opravě spusť review znovu od kroku R1. Opakuj dokud review iterace nenajde **ZERO findings CRITICAL/HIGH/MEDIUM**.

LOW findings zapiš ale neopravuj (kosmetické, neblokují).

### Krok R6: Finální report

Na konec vypiš:

```
## Implementation & Review Complete

Commits: [počet]
Review iterations: [počet]
Final findings: [počet] CRITICAL, [počet] HIGH, [počet] MEDIUM, [počet] LOW
All CRITICAL/HIGH/MEDIUM resolved: Yes
Status: READY FOR VERSION BUMP

Next steps:
1. Manual: Communicate rename to 4 users (P3)
2. Manual: Verify Codeberg URL https://codeberg.org/goern/forgejo-mcp/releases (P1)
3. Run: /ceos-agents:version-bump minor (bumps to 3.4.0, creates tag)
4. Manual: Rename Gitea repo CLAUDE-agents → ceos-agents (P4)
5. Run: git push origin main --tags
```
