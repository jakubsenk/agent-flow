# Phase 1 Agent 1 — Research Questions (Conservative / Release-Engineer)

## Q1: Which non-bak files reference `Extra labels` and exactly which lines must be deleted vs updated?

- **Why**: The spec lists 7 file types that reference `Extra labels`; preliminary grep shows hits in `agents/publisher.md`, `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/check-setup/SKILL.md`, `skills/onboard/SKILL.md`, `skills/migrate-config/SKILL.md`, `core/config-reader.md`, `docs/reference/automation-config.md`, all 8 `examples/configs/*.md`, and `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` — but spec only lists a subset. Phase 2 must produce an exhaustive file:line inventory before any deletion.
- **Files to read**: `agents/publisher.md`, `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/check-setup/SKILL.md`, `skills/onboard/SKILL.md`, `skills/migrate-config/SKILL.md`, `core/config-reader.md`, `docs/reference/automation-config.md`, all 8 `examples/configs/*.md`, `tests/scenarios/v6.9.0-bc-no-renamed-section.sh`, `tests/scenarios/config-reader-sections.sh`
- **Maps to release action**: Action 1 (Delete `Extra labels` config section)

## Q2: For `Pause Limits`, does `docs/reference/automation-config.md` line 40 say `/autopilot` only — and what is the exact current text that must be replaced with the 6-skill list?

- **Why**: The spec says to fix the mapping at `docs/reference/automation-config.md:40`. Preliminary read confirms `| Pause Limits | No | /autopilot |` at line 40. Phase 2 must verify the exact line number and text, and confirm that the 6 skills implementing NEEDS_CLARIFICATION are exactly: fix-ticket, fix-bugs, implement-feature, scaffold, autopilot, resume-ticket (all 6 confirmed via grep of NEEDS_CLARIFICATION in their SKILL.md files). The correct replacement text must be confirmed before editing.
- **Files to read**: `docs/reference/automation-config.md` (lines 35–50), `skills/fix-ticket/SKILL.md` (grep for NEEDS_CLARIFICATION), `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/autopilot/SKILL.md`, `skills/resume-ticket/SKILL.md`
- **Maps to release action**: Action 2 (Fix `Pause Limits` doc mapping)

## Q3: What is the complete list of files (outside `.forge.bak-*` and `.forge/`) that reference `/ceos-agents:status`, `ceos-agents:status`, `/ceos-agents:init`, or `ceos-agents:init` — and for each, is the reference in a "skills list", a user-facing example, or functional skill dispatch logic?

- **Why**: Preliminary grep found references in `CHANGELOG.md`, `CLAUDE.md`, `docs/reference/skills.md`, `docs/getting-started.md`, `docs/guides/installation.md`, `docs/guides/mcp-configuration.md`, `docs/guides/troubleshooting.md`, `docs/plans/roadmap.md`, `skills/status/SKILL.md`, `skills/init/SKILL.md`, `skills/workflow-router/SKILL.md`, `skills/check-setup/SKILL.md`, `skills/onboard/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/create-backlog/SKILL.md`, `skills/implement-feature/SKILL.md`, and `core/mcp-preflight.md`. Each reference needs classification: rename-in-place vs functional dispatch update vs doc update.
- **Files to read**: All files from the grep result above; also `README.md` (grep for `status` and `init` skill references), `tests/scenarios/` (grep for these identifiers)
- **Maps to release action**: Actions 3 and 4 (Rename `/ceos-agents:status` and `/ceos-agents:init`)

## Q4: What is the exact current logic in `skills/publish/SKILL.md` Step 1 for determining the issue ID from the current branch — and what MCP call pattern (tool name, arguments, error types) exists across supported trackers for issue existence verification?

- **Why**: The current `publish/SKILL.md` Step 1 says "Determine the current branch and issue ID" with no explicit branch-name parsing logic — there is no `git branch --show-current` call or regex match against `Source Control → Branch naming`. The auto-detect rewrite must inject this logic. Phase 2 must confirm: (a) the exact current Step 1 text to replace, (b) how fix-ticket/fix-bugs extract issue_id from branch today (cite file:line as the reference implementation pattern), and (c) what MCP tool name is used to fetch a single issue for each tracker type (e.g., `mcp__youtrack__getIssue`, `mcp__github__get_issue`) per `docs/reference/trackers.md`.
- **Files to read**: `skills/publish/SKILL.md` (full), `skills/fix-ticket/SKILL.md` (branch creation + issue_id usage), `docs/reference/trackers.md` (MCP tool names per tracker), `core/mcp-detection.md` (error_type values: `not_found` vs `timeout` vs `auth`), `core/mcp-preflight.md`
- **Maps to release action**: Action 5 (Auto-detect tracker in `/publish`)

## Q5: What is the complete set of files (outside `.forge.bak-*`) that reference `/ceos-agents:create-pr`, `ceos-agents:create-pr`, or `skills/create-pr/` — distinguishing user-facing docs/examples that must be updated from the skill directory itself that must be deleted?

- **Why**: Preliminary grep found `skills/workflow-router/SKILL.md` (intent table row for `create-pr` that must be deleted), `CLAUDE.md` (skills list), `CHANGELOG.md`, `docs/reference/skills.md`, `docs/getting-started.md`, `docs/guides/`, `core/mcp-body-formatting.md`. The `skills/create-pr/SKILL.md` directory must be deleted. All doc references must be updated to point to `/publish`. Phase 2 must produce an exhaustive list with per-file action (delete-row, update-text, or delete-file).
- **Files to read**: `skills/create-pr/SKILL.md` (full — understand what it does vs. `/publish` to craft accurate migration note), `skills/workflow-router/SKILL.md` (lines 15–16 for the create-pr intent row), `core/mcp-body-formatting.md`, `docs/reference/skills.md`, `README.md`, `docs/getting-started.md`
- **Maps to release action**: Action 5/6 (Delete `/create-pr` + update all references)

## Q6: What are the exact line numbers in the 5 anchor docs where "29 skills" and "19 optional" count strings appear, and are there any other count-bearing phrases (e.g., "All 29", "29 ceos-agents", "19 optional sections") that also need updating to 28/18?

- **Why**: Preliminary grep found count references in `CLAUDE.md:18` (29 skills), `CLAUDE.md:160` (19 optional), `README.md:221` (19 optional sections), `README.md:262` (29 skills), `docs/reference/automation-config.md:9` (19 optional sections), `docs/reference/skills.md:3` (29 skills, 2 occurrences), `docs/getting-started.md:219` (29 skills). `docs/architecture.md` was not in the grep results — Phase 2 must confirm whether it also contains count strings. Also: `skills/` frontmatter or agent count references that still say `21 agents` should NOT change, but any "29 skills" reference in skill files themselves needs checking.
- **Files to read**: `CLAUDE.md` (full), `README.md` (lines 215–270), `docs/reference/automation-config.md` (lines 1–15), `docs/reference/skills.md` (lines 1–10), `docs/getting-started.md` (lines 215–225), `docs/architecture.md` (grep for count strings)
- **Maps to release action**: Cross-cutting (all actions affect counts; must update after deletions/renames)

## Q7: What is the current state of `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` regarding `Extra labels` — is it a RETIRE (exit 77) candidate or does it need to be rewritten as a different functional test?

- **Why**: The spec explicitly calls out this test as referencing `Extra labels`. A test that verifies a config section still exists is trivially invalidated when the section is deleted — it should be RETIRED (exit 77) rather than rewritten, unless its purpose extends beyond section existence. Phase 2 must also confirm whether `tests/scenarios/config-reader-sections.sh` or any other scenario references `Extra labels`, and whether any test references `ceos-agents:status`, `ceos-agents:init`, or `ceos-agents:create-pr` as identifiers that need updating or retiring.
- **Files to read**: `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` (full), `tests/scenarios/config-reader-sections.sh` (full), `tests/scenarios/v6.9.0-doc-count-drift.sh` (full — references count strings that will change)
- **Maps to release action**: Actions 1, 3, 4, 6 (test scenario impact of all four deletions/renames)

## Q8: In `docs/guides/installation.md` and `README.md`, is there already a section or callout about slash command naming / builtin collisions — or does the warning need to be added from scratch, and what section/heading is the most logical insertion point?

- **Why**: The spec requires adding warnings about short-form slash collisions (action 6/7). Before writing new content, Phase 2 must confirm: (a) whether `installation.md` already has a "Known Limitations" or "Caveats" section that the warning can extend, (b) whether `README.md` has a comparable anchor, and (c) the exact wording constraints (the plugin is accessed as `/ceos-agents:status` not `/status`, so the warning should say the short form is NOT supported, not that it "may" conflict).
- **Files to read**: `docs/guides/installation.md` (full structure, headings), `README.md` (lines 1–100 for structure, then grep for "collision\|builtin\|short form\|known\|limitation\|caveat"), `skills/init/SKILL.md` (heading structure to understand if it already warns about `/init`)
- **Maps to release action**: Action 6 (README + docs warnings about builtin collisions)
