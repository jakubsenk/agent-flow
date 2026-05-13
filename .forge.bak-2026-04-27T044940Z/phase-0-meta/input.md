# User Input (verbatim)

implementuj v7.0.0 cleanup release dle specifikace v docs/superpowers/specs/2026-04-24-public-release-readiness-WIP.md (sekce "v7.0.0 FINÁLNÍ scope")  je to v roadmape i ta verze. bump si delam na konci sam spustenim skillu

## Translation note

Czech instruction: implement v7.0.0 cleanup release per specification in `docs/superpowers/specs/2026-04-24-public-release-readiness-WIP.md` (section "v7.0.0 FINÁLNÍ scope"). It is in the roadmap and the version is set there. The version bump will be done by the user themselves at the end via the `/version-bump` skill.

## Scope summary (from spec)

Six concrete actions:
1. Delete `Extra labels` config section (duplicates `PR Rules → Labels`)
2. Fix doc `Pause Limits` mapping (applies to 6 skills, not just `/autopilot`)
3. Rename `/ceos-agents:status` → `/ceos-agents:pipeline-status` (collides with Claude Code builtin `/status`)
4. Rename `/ceos-agents:init` → `/ceos-agents:setup-mcp` (collides with Claude Code builtin `/init`)
5. Auto-detect tracker in `/publish` + delete `/create-pr` skill (issue ID found → tracker update + PR; not found → PR only; tracker down → fail with guidance)
6. README + docs warnings about short-form slash collisions with Claude Code builtins

Counts after v7.0.0: 29 → 28 skills (−`/create-pr`), 19 → 18 config sections (−`Extra labels`), 21 → 21 agents (no change). Renames don't reduce counts.

## Out-of-scope (explicit)

- Do NOT bump the version (plugin.json, marketplace.json, CHANGELOG version-bump commit) — user handles this manually via `/version-bump` skill at the end.
- A CHANGELOG entry for v7.0.0 (with migration guide) IS in scope as part of the implementation.
