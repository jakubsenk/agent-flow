# Phase 9 — Completion

You are the completion agent. Phase 8 verification has passed. Produce the final summary and prepare for commit.

## Tasks

### C1: Final File Inventory

List every file that was modified, with a one-line description of the change:

| File | Change |
|------|--------|
| `commands/version-check.md` | Removed hardcoded URL fallback, added graceful skip for missing repository field |
| `docs/reference/commands.md` | Updated version-check description for accuracy |
| `CHANGELOG.md` | Updated entry to note genericity fix |

### C2: Commit Preparation

Prepare the git commit. Follow the project conventions from CLAUDE.md and MEMORY.md:

1. Run `./tests/harness/run-tests.sh` BEFORE committing (per MEMORY.md)
2. Stage only the modified files (no unrelated changes)
3. Commit message format:

```
fix(version-check): remove hardcoded URL fallback, ensure genericity

version-check now reads remote URL from plugin.json repository field
instead of falling back to a hardcoded internal URL. Gracefully skips
remote comparison when repository field is missing.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
```

4. Do NOT create a new version tag (this amends the v5.5.1 scope unless Phase 4 decided on v5.5.2)
5. Do NOT push — the user will decide when to push

### C3: Summary Report

Produce a summary for the user (in Czech, per project conventions):

```
## Shrnutí

### Co bylo opraveno
- `commands/version-check.md`: Odstraněn hardcoded URL fallback na interní Gitea server
- Příkaz nyní čte remote URL z `repository` pole v `plugin.json`
- Pokud `repository` pole chybí, příkaz to oznámí a přeskočí porovnání s remote verzí (místo pádu)

### Testováno
- Strukturální testy: všechny PASS (žádné hardcoded URL, žádný git pull, správná struktura)
- Regresní testy: všechny PASS
- Verze konzistentní napříč plugin.json a marketplace.json
- Ověřeno chování z repo i mimo repo

### Soubory změněny
1. `commands/version-check.md` — hlavní oprava
2. `docs/reference/commands.md` — aktualizovaný popis
3. `CHANGELOG.md` — aktualizovaný záznam

### Další kroky
- Spustit `/ceos-agents:version-check` z jiného adresáře pro manuální ověření
- Commitnout a pushnout, pokud je vše v pořádku
```

### C4: Lessons Learned

Document what caused the original bug and how to prevent it:

1. **Root cause:** The original version-check assumed it would always run from inside the ceos-agents repo directory. It used relative paths and CWD-dependent logic for what should be a global status command.

2. **Contributing factor:** The first fix added a hardcoded URL as a fallback, which solved the immediate problem but introduced a genericity violation. Hardcoded URLs work for one team but break for anyone who forks the plugin.

3. **Prevention:** Commands that are designed to work "from any directory" should be tested from at least two directories during development:
   - Inside the repo (to verify Part B triggers)
   - Outside the repo (to verify Part A works standalone)

4. **Pattern:** For plugin self-inspection commands, always resolve paths through `installed_plugins.json` (the runtime source of truth), never through CWD or hardcoded paths.

## Rules

- Do NOT push to remote
- Do NOT create tags
- Do NOT modify any files not listed in C1
- Run tests before committing
- Commit message must follow the project's conventional commit style
