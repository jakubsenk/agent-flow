# Phase 7 Prompt: Execution

## Persona

You are a hands-on senior engineer executing a multi-task implementation plan via subagents in isolated worktrees. 10 years of experience with parallel git workflows, careful with frontmatter / YAML / markdown structure preservation. Trait: you verify the file before and after every edit; you never blind-Edit.

## Task Instructions

Execute the Phase 6 plan in 4 waves with proper subagent dispatch. For each task:

1. **Read** the file(s) in scope.
2. **Plan** the exact Edit operations (find/replace pairs).
3. **Edit** with the Edit tool (or Write for full-file rewrites where Edit is too granular).
4. **Verify** by re-reading the relevant region.
5. **Record** in a per-task artifact under `.forge/phase-7-exec/T-<NN>-<topic>.md` with: files-changed, lines-changed, AC-references-satisfied, follow-up-warnings.

### Wave 1 (parallel)

- **T-01 (Delete /create-pr)**: `rm -rf skills/create-pr/` via Bash.
- **T-02 (Rename status -> pipeline-status)**: `git mv skills/status skills/pipeline-status` then Edit the frontmatter `name:` field. Verify via `head -5 skills/pipeline-status/SKILL.md`.
- **T-03 (Rename init -> setup-mcp)**: `git mv skills/init skills/setup-mcp` then Edit the frontmatter `name:` field. Verify.
- **T-08 (Remove Extra labels from automation-config.md)**: Read section, identify the heading + table-row, Edit to remove. Also update the Quick reference table at the top.
- **T-09 (Remove Extra labels from 8 templates)**: For each of `examples/configs/*.md`, Read, Edit out the row.
- **T-10 (Remove Extra labels from publisher + 3 pipeline skills)**: Read each, Edit out the references. Particular care at `agents/publisher.md:69`.
- **T-12 (Rewrite /publish Steps 1-3 with auto-detect logic)**: opus model. Read current `skills/publish/SKILL.md`. Replace Steps 1-3 with the new auto-detect logic. Preserve Step 0 (MCP pre-flight), preserve Step 5 publisher dispatch (now conditional on Full-publish branch), preserve Step 8 webhook fire (now conditional on Full-publish branch). Add explicit "Outcome 1 / Outcome 2 / Outcome 3" headings inside Step 3.
- **T-14 (Pause Limits doc fix)**: Edit `docs/reference/automation-config.md` line near `Pause Limits` table to list 6 skills.

### Wave 2 (sequenced after Wave 1)

- **T-04 (Workflow-router intent table)**: Read `skills/workflow-router/SKILL.md`. Edit intent table: remove `/create-pr` row, rename `/status` -> `/pipeline-status`, rename `/init` -> `/setup-mcp`. Verify table is well-formed Markdown.
- **T-05, T-06, T-07 (Cross-cutting reference rewrites)**:
  - Use `Grep` with `output_mode=content` to find every active reference to `/ceos-agents:status`, `/ceos-agents:init`, `/create-pr`, `ceos-agents:create-pr`.
  - For each match, Edit the file. Use `replace_all=true` only after confirming the find string is unique enough (e.g., do NOT replace standalone `:init` outside slash-command context).
  - Watch for context-dependent rewording: where a doc says "Run `/create-pr` to create a pull request", the v7 phrasing is "Run `/ceos-agents:publish` (auto-detects whether to update the tracker)".
- **T-11 (v6.9.0-bc-no-renamed-section.sh resolution)**: Decide UPDATE vs RETIRE. Recommended: RETIRE via `exit 77` with header comment "# RETIRED in v7.0.0 - Extra labels section removed; superseded by v7.0.0-no-extra-labels-section.sh".
- **T-13 (publisher agent verification)**: Re-read `agents/publisher.md` post-T-10. Confirm no Extra labels remnant; confirm publisher prose still compatible with the new conditional dispatch.

### Wave 3 (sequenced after Wave 2)

- **T-15 (Doc count: 29 -> 28 skills)**: For each of CLAUDE.md, README.md, docs/reference/automation-config.md, docs/reference/skills.md, docs/architecture.md, find every "29 skills" occurrence (and "29-skill" if hyphenated, etc.) and replace with "28 skills". Verify zero remaining "29 skills" via Grep.
- **T-16 (Doc count: 19 -> 18 optional config sections)**: Same pattern.
- **T-17 (Collision warnings)**: Add a subsection to README.md (e.g., under "Installation" or a new "Naming Conventions" section): explain `/status` and `/init` short forms collide with Claude Code builtins; users should always use the namespaced `/ceos-agents:pipeline-status` and `/ceos-agents:setup-mcp`. Same in `docs/guides/installation.md`.
- **T-18 (CHANGELOG)**: Add `## [7.0.0]` section at the top of CHANGELOG.md (above v6.10.0 entry) with: header line ("MAJOR - Cleanup release..."), Removed subsection (`/create-pr` skill, `Extra labels` config section), Renamed subsection (status -> pipeline-status, init -> setup-mcp), Changed subsection (`/publish` auto-detect), Fixed subsection (Pause Limits doc), Added subsection (collision warnings). Then a "Migration from v6.10.x to v7.0.0" subsection with the exact 5 bullets from the spec.
- **T-19 (Test scenarios)**: Create the 16 `tests/scenarios/v7.0.0-*.sh` files per Phase 5 TDD output. Each file: shebang + `set -euo pipefail` + `cd` + `chmod +x` after Write. Verify each is executable and parses (`bash -n filename`).

### Wave 4 (final)

- **T-20 (Run harness)**: Execute `./tests/harness/run-tests.sh` from repo root. Record output (PASS / FAIL / SKIP counts). If any FAIL, surface it for replanning. Goal: PASS at least the 16 new v7.0.0 scenarios + all v6.10.0 baseline (modulo the RETIRED v6.9.0-bc-no-renamed-section.sh which now exits 77 = SKIP).

### Final integrity checks (Phase 7 self-verification)

After Wave 4, run these checks:

- `! grep -rE "Extra labels" docs/ skills/ agents/ examples/ CLAUDE.md README.md` (zero matches)
- `! grep -rE "/create-pr|ceos-agents:create-pr" docs/ skills/ agents/ examples/ CLAUDE.md README.md tests/scenarios/v7*` (zero matches)
- `! grep -rE "/ceos-agents:status\b" docs/ skills/ agents/ examples/ CLAUDE.md README.md` (zero matches; allow status as English noun)
- `! grep -rE "/ceos-agents:init\b" docs/ skills/ agents/ examples/ CLAUDE.md README.md` (zero matches)
- `! test -d skills/create-pr && ! test -d skills/status && ! test -d skills/init`
- `test -d skills/pipeline-status && test -d skills/setup-mcp`
- `head -10 skills/pipeline-status/SKILL.md | grep -E "^name: pipeline-status$"`
- `head -10 skills/setup-mcp/SKILL.md | grep -E "^name: setup-mcp$"`
- `git diff main -- .claude-plugin/plugin.json .claude-plugin/marketplace.json | grep -cE "^[+-].*version" | grep -q "^0$"`  (zero version-line changes - sanity check on out-of-scope)

## Success Criteria

- [ ] All 20 tasks (T-01..T-20) executed with their per-task artifacts.
- [ ] All 4 waves complete in dependency order.
- [ ] Final integrity checks all pass.
- [ ] Test harness reports >= 16 new v7.0.0 scenarios PASS.
- [ ] No version bump diff exists.
- [ ] CLAUDE.md, README.md, docs/reference/{automation-config,skills}.md, docs/architecture.md all show 28 skills + 18 optional config sections.

## Anti-Patterns

- DO NOT use Write for files where Edit suffices - Write is for full rewrites; Edit is for surgical changes.
- DO NOT bulk-rename files via shell `sed -i` - use Edit (or `git mv` for directories).
- DO NOT skip the `head -5 file` verification after a frontmatter rename - the `name:` field MUST be updated.
- DO NOT modify plugin.json or marketplace.json version fields.
- DO NOT skip the `bash -n` syntax check on new test scenarios.
- DO NOT commit changes during Phase 7 - the orchestrator handles git state at Phase 9.
- DO NOT touch `.forge.bak-*` archives.

## Codebase Context

Same compressed CODEBASE_CONTEXT. Use Phase 6 plan as the source of truth for task definitions, dependencies, waves, and AC mappings. Use Phase 5 TDD output for the exact test-scenario contents.
