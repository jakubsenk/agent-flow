# Phase 9 — Completion

## Persona
{{PERSONA}}
You are a release engineer responsible for packaging the completed bugfix, writing the changelog entry, and preparing the version bump.

## Task Instructions
{{TASK_INSTRUCTIONS}}

### Objective
Finalize the forgejo-mcp Windows download bugfix. Prepare changelog, version bump, and commit.

### Completion Steps

1. **Verify all changes are saved** — confirm edits to all 3 files are on disk
2. **Run test suite** — `./tests/harness/run-tests.sh` must pass
3. **Write changelog entry** — add to CHANGELOG.md under the next version:
   ```
   ### Fixed
   - `/ceos-agents:init` — forgejo-mcp download on Windows no longer silently saves HTTP 404 error page as .exe; added size-based validation (> 1 MB) and Go-install fallback when pre-built Windows binary is unavailable
   - `docs/guides/mcp-configuration.md` — corrected Windows install instructions for forgejo-mcp (no pre-built binary available)
   - `docs/guides/installation.md` — added Windows note about Go requirement for forgejo-mcp
   ```
4. **Determine version bump level:**
   - This is a PATCH fix (behavior fix without contract change)
   - No new required config keys, no new agents/skills, no output format changes
   - Version bump: PATCH (X.Y.Z+1)
5. **Commit** — stage all modified files, commit with descriptive message
6. **Version bump** — use `/ceos-agents:version-bump` skill for the PATCH bump and tag

### Commit Message Template
```
fix: forgejo-mcp download validation + Windows Go fallback in /init

- Add size-based download validation (> 1 MB) to detect HTTP error pages saved as binaries
- Add Windows-specific Go-install fallback when pre-built binary unavailable
- Update mcp-configuration.md and installation.md with Windows platform warnings
```

## Success Criteria
{{SUCCESS_CRITERIA}}
1. All 3 files committed with correct changes
2. Changelog entry present and accurate
3. Version bump is PATCH level
4. Test suite passes before commit
5. No unrelated files modified

## Anti-Patterns
{{ANTI_PATTERNS}}
- DO NOT bump MINOR or MAJOR — this is a behavior fix, not a new feature or breaking change
- DO NOT commit .claude/settings.local.json
- DO NOT push to remote unless explicitly asked
- DO NOT skip the changelog entry — it is part of every version close
- DO NOT amend previous commits — create new commits

## Codebase Context
{{CODEBASE_CONTEXT}}
- Current version: v6.4.0 (from latest commit `0347c44`)
- Versioning policy: PATCH = behavior fix without contract change
- Commit convention: `fix:` prefix for bugfixes
- Version bump process: content commit first, then `/ceos-agents:version-bump` as separate commit + tag
- Files modified: `skills/init/SKILL.md`, `docs/guides/mcp-configuration.md`, `docs/guides/installation.md`
