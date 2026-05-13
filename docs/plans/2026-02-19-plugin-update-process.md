# Design: Plugin Update Proces

**Datum:** 2026-02-19 (validováno 2026-02-24)
**Status:** APPROVED

## Problém

Update pluginu nikdy nefungoval na první pokus. Claude Code porovnává semver verzi, ne git SHA — pokud verze zůstane `1.0.0`, Claude Code nedetekuje změny.

## Root Cause: Version Comparison Deadlock

1. Push nového kódu na Gitea (verze zůstává `1.0.0`)
2. Claude Code fetchne marketplace — vidí `version: "1.0.0"`
3. Porovná s `installed_plugins.json` — tam je taky `"1.0.0"`
4. Závěr: "already installed" — nic nedělá

`gitCommitSha` se zapisuje do `installed_plugins.json`, ale nepoužívá se jako update trigger.

## Architektura plugin systému

```
known_marketplaces.json         -- registr marketplace repozitářů
         |
         v
marketplaces/{name}/            -- git clone marketplace repa
         |
         v (version + source z marketplace.json)
         |
cache/{marketplace}/{plugin}/{version}/   -- extrahované plugin soubory
         |
         v
installed_plugins.json          -- tracks: version, SHA, installPath
         |
         v
settings.json enabledPlugins    -- on/off toggle
```

## Řešení: Command `/version-bump`

Command v pluginu, který bumpne patch verzi v obou souborech.

### Workflow
1. Uživatel vyvíjí feature/fix
2. Spustí `/CLAUDE-agents:version-bump`
3. Command přečte aktuální verzi z `plugin.json`, bumpne patch (1.0.0 → 1.0.1)
4. Zapíše novou verzi do `plugin.json` i `marketplace.json`
5. Uživatel ručně commitne a pushne

### Proč command a ne hook
- Žádné hooky k instalaci (install-hooks.sh, symlinky)
- Plná kontrola nad tím, kdy se verze změní
- Využívá vlastní mechanismus pluginu (commands)
- Jednoduchý mentální model

### CWD ověření
Command ověří, že existuje `.claude-plugin/plugin.json` v CWD. Pokud ne, oznámí chybu — command funguje jen v CLAUDE-agents repozitáři.

## Troubleshooting návod (pro README)

I s verzováním se může stát, že cache zlobí. Návod pro ruční opravu:

```bash
# 1. Pull marketplace
cd ~/.claude/plugins/marketplaces/CLAUDE-agents && git pull origin main

# 2. Smaž cache
rm -rf ~/.claude/plugins/cache/CLAUDE-agents/

# 3. Restart Claude Code

# 4. Install
/plugin install CLAUDE-agents@CLAUDE-agents
```

## Zamítnuté alternativy

| Řešení | Důvod zamítnutí |
|--------|----------------|
| Separátní marketplace repo | Over-engineering pro jeden plugin |
| Session-start hook | Chicken-and-egg — starý hook v cache nedostane nový kód |
| Pre-commit git hook | Vyžaduje instalační krok (install-hooks.sh), zbytečná složitost |
| Auto-bump při každém commitu | Uživatel preferuje explicitní kontrolu přes command |
