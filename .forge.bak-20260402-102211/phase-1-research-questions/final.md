# Phase 1 — Research Questions: Commands-to-Skills Migration

**Generated:** 2026-04-01
**Migration scope:** 25 `commands/*.md` → `skills/*/SKILL.md` directories, v5.7.0 → v6.0.0

---

## R1 — Skill Frontmatter Contract

What exact YAML frontmatter fields does Claude Code support for skills, and how does discovery work?

**R1.1** The existing `skills/workflow-router/SKILL.md` has exactly two frontmatter fields: `name` and `description`. Commands have `description` and `allowed-tools`. Is `allowed-tools` a supported frontmatter field for skills? If not, what is the equivalent mechanism for pre-approving tools in a skill (e.g., `mcp__*`, `Bash`, `Task`)?

**R1.2** Commands use a `model` frontmatter field (inferred from agent frontmatter convention). Skills have no `model` field. Is there any frontmatter field in skills for setting a preferred or default model for that skill's execution context?

**R1.3** Commands rely on `$ARGUMENTS` as a positional placeholder for user-supplied input (e.g., `fix-bugs.md`: "Process $ARGUMENTS bugs"). Skills have no documented equivalent. What is the correct mechanism for a skill to receive and process user-supplied arguments (issue ID, count, flags)?

**R1.4** Claude Code discovers skills automatically based on the `description` field via semantic matching. Commands are invoked explicitly as `/ceos-agents:<name>`. Are skills also invocable explicitly (e.g., `/ceos-agents:fix-bugs`)? Or only through auto-discovery and `Skill()` calls?

**R1.5** The `workflow-router` SKILL.md directory contains only one file (`SKILL.md`). Can supporting files (e.g., split sections of a large command like `scaffold.md`) live in the same skill directory alongside `SKILL.md`? What file names are permitted?

**R1.6** The `plugin.json` and `marketplace.json` currently register no explicit `commands` or `skills` arrays — the plugin system discovers them by directory convention. Does moving from `commands/*.md` to `skills/*/SKILL.md` require any changes to `plugin.json` registration, or is discovery entirely filesystem-based?

**R1.7** `workflow-router` is a routing skill that invokes other skills via `Skill('ceos-agents:{command}', args='...')`. After migration, the invocation target becomes a skill name, not a command. Does the `Skill()` call syntax remain identical, or does it change when the target is a skill directory rather than a command file?

---

## R2 — Cross-Reference Inventory

Which specific files reference `commands/` paths, and what kind of reference is each?

**R2.1** Three core contract files contain `commands/` path references:
- `core/decomposition-heuristics.md:34` references `commands/fix-ticket.md` steps 4b–4c
- `core/fixer-reviewer-loop.md:44` references `commands/fix-ticket.md` step 5
- `core/mcp-detection.md:7` references `commands/scaffold.md` and `commands/init.md`

After migration, what do these references point to? Is the convention `skills/fix-ticket/SKILL.md` (directory-based path), or does the `commands/` path remain as a human-readable label?

**R2.2** `CLAUDE.md` contains two `commands/` references:
- Line 18: `- \`commands/\` — 25 commands (slash commands)` (Repository Structure section)
- Line 50: `see \`commands/fix-bugs.md\` for full pipeline` (Bug-Fix Pipeline section)

The Repository Structure line must change the directory name and file convention description. The pipeline reference must point to the new skill path. What is the correct new path format for CLAUDE.md cross-references?

**R2.3** `CHANGELOG.md` contains one `commands/` reference (description of `mcp-detection.md`, line 69). Is this a live cross-reference that needs updating, or historical text in a past changelog entry that should be left as-is?

**R2.4** Twenty-five test scenario files contain `commands/` path references of four distinct types:
- Hardcoded file paths (e.g., `$REPO_ROOT/commands/scaffold.md`)
- Directory existence checks (`[ -d "$COMMANDS_DIR" ]` where `COMMANDS_DIR="$REPO_ROOT/commands"`)
- File count assertions (`ls "$REPO_ROOT/commands/"*.md | wc -l`)
- Content checks that grep inside specific command files

For each type, what is the correct updated path or assertion logic after migration?

**R2.5** `docs/guides/mcp-configuration.md` is in the list of files referencing `commands/`. What kind of reference does it contain, and is it a user-facing path that external consumers might depend on?

**R2.6** `docs/plans/*.md` files (historical design docs) contain `commands/` references. Should these be updated to reflect the new structure, or preserved as historical records of decisions made when the `commands/` architecture was current?

**R2.7** The `agents/*.md` files — do any of them reference `commands/` paths in their Process or Constraints sections? A grep of `commands/` in `agents/` would confirm whether agent definitions need updating.

---

## R3 — File Splitting Strategy

For the six command files exceeding 200 lines, what are the logical split points and how should supporting files be loaded?

**R3.1** `scaffold.md` (780 lines) has a well-defined structure: Flag Parsing, Flag Validation, State Detection, then numbered pipeline steps (0-INFRA, 0-MCP, 0b, 1–7, X). What is the maximum skill file size that Claude Code reliably handles without truncation, and does the `skills/scaffold/` directory allow splitting into multiple files (e.g., `SKILL.md` + `pipeline.md` + `flag-parsing.md`)?

**R3.2** `fix-bugs.md` (529 lines) and `fix-ticket.md` (390 lines) share structural sections (Configuration, Pipeline profile parsing, numbered pipeline steps). The natural split would be at the Configuration section boundary (~50 lines) versus the pipeline steps (~400+ lines). Would a supporting file `skills/fix-bugs/pipeline.md` be automatically included in the skill's context, or must `SKILL.md` explicitly reference it with a `Read` instruction?

**R3.3** `implement-feature.md` (414 lines) and the scaffold pipeline share references to `core/*.md` contracts via inline `Follow \`core/config-reader.md\`` instructions. If a skill file is split, do `core/` file references survive — i.e., does Claude Code's context-loading for skills include the CWD-relative `core/` directory, or only files within the skill's own directory?

**R3.4** The current test `core-include-refs.sh` verifies that four pipeline commands contain at least N `core/` references. After splitting, content may move to supporting files. Does the test need to also scan supporting skill files, or only `SKILL.md`?

**R3.5** `onboard.md` (289 lines) and `init.md` (240 lines) are configuration wizards with many interactive prompts. Is there a convention for how skill supporting files should be named — e.g., must they end in `.md`, use a specific prefix, or follow any naming restriction?

**R3.6** Skill supporting files reside in a named directory (`skills/{name}/`). The `workflow-router` skill directory has exactly one file. Is there any evidence that multi-file skill directories are supported in the plugin spec (e.g., `plugin.json`, Anthropic docs), or only single-file `SKILL.md` directories?

---

## R4 — Test Migration Patterns

Which tests reference `commands/` and what is the minimum-change update for each?

**R4.1** `xref-command-count.sh` counts `*.md` files in `commands/` and compares to CLAUDE.md's claimed count. After migration, `commands/` may be empty or removed. Should this test be deleted, repurposed to count `skills/*/SKILL.md` files, or updated to assert that `commands/` no longer exists?

**R4.2** `happy-path.sh` checks `ls "$REPO_ROOT/commands/"*.md | wc -l` and requires `>= 24`. After migration, what assertion replaces this? Is `ls "$REPO_ROOT/skills/"*/SKILL.md | wc -l >= 25` the correct replacement, or should the test shift to checking skills directory structure?

**R4.3** `core-include-refs.sh` checks four pipeline commands by path (`commands/fix-ticket.md`, `commands/fix-bugs.md`, `commands/implement-feature.md`, `commands/scaffold.md`) for minimum `core/` reference counts. After migration, the same paths become `skills/fix-ticket/SKILL.md` etc. Is the reference count requirement unchanged (≥7, ≥7, ≥6, ≥3), or might splitting change these counts if some content moves to supporting files?

**R4.4** `xref-core-registry.sh` searches `commands/*.md` for `core/{name}` references to verify every core file is consumed by at least one command. After migration, should this search also scan `skills/*/SKILL.md` and `skills/*/*.md`? What is the minimum glob pattern to cover all skill content files?

**R4.5** `no-mcp-jargon-errors.sh` hardcodes 14 specific `commands/*.md` paths. After migration, all 14 paths change to `skills/*/SKILL.md`. This test must be updated with new path constants — are the path changes one-to-one (one old path per new path), or do any split scenarios produce multiple skill files from a single command?

**R4.6** `pipeline-agent-dispatch-models.sh` builds a path `$REPO_ROOT/commands/$cmd.md` for commands `(fix-ticket, fix-bugs, implement-feature, scaffold, check-deploy)`. After migration, the loop variable `$cmd` maps to `skills/$cmd/SKILL.md`. What is the minimal change: just update the path template inside the loop?

**R4.7** `pipeline-consistency.sh` uses `grep -rl 'rollback-agent\|fixer.*Task tool' "$CMDS"/*.md` where `CMDS="$REPO_ROOT/commands"`. After migration, what path replaces `"$CMDS"/*.md` to match all skill content? Is `"$REPO_ROOT/skills/"*/SKILL.md` sufficient, or must it also cover supporting files?

**R4.8** Seven scaffold-specific tests (`scaffold-v2-happy-path.sh`, `scaffold-v2-input-conflicts.sh`, `scaffold-v2-no-implement.sh`, `scaffold-v2-spec-loop.sh`, `scaffold-v561-regression.sh`, `scaffold-canary-announcement.sh`, `scaffold-infra-flag-format.sh`, `scaffold-resume-infra-override.sh`) all set `SCAFFOLD_CMD="$REPO_ROOT/commands/scaffold.md"`. If `scaffold.md` is split across multiple files in `skills/scaffold/`, which file does `SCAFFOLD_CMD` point to, and do any tests need to search both `SKILL.md` and supporting files?

---

## R5 — Backward Compatibility

Does the `ceos-agents:` namespace work the same for skills, and what breaks for existing users?

**R5.1** The `ceos-agents:` prefix is used in 23 of the 25 commands' bodies (e.g., `/ceos-agents:check-setup`, `ceos-agents:fix-ticket`). After migration to skills, these invocation strings become `Skill('ceos-agents:fix-ticket', ...)` calls. Do end users who have memorized `/ceos-agents:fix-bugs 5` need to change to a different invocation format?

**R5.2** `workflow-router` currently routes to `ceos-agents:{command}` skill targets. After migration, the commands become skills with the same names. Does the `Skill()` syntax in `workflow-router/SKILL.md` need any change, or does the `ceos-agents:{name}` namespace resolve identically whether the target is a command or a skill?

**R5.3** The design doc `2026-02-19-skills-vs-commands.md` explicitly states that `$ARGUMENTS` is a critical mechanism that skills lack. This decision was the primary reason commands were kept over skills. Has this constraint been resolved in a newer version of Claude Code's plugin specification, or does the migration require embedding argument-passing logic inside each skill's body?

**R5.4** The 2019-02-19 design also states skills lack `model` override capability. Several commands dispatch agents at specific models via the `Task tool, model: {model}` convention embedded in command body text — this is not a frontmatter-level override. Is this dispatch convention independent of whether the orchestrator is a command or a skill?

**R5.5** `check-setup.md` explicitly lists 25 commands and their invocation paths in its output. After migration, does `check-setup.md` need to be updated to reference skills instead, or is the user-facing invocation syntax unchanged?

**R5.6** Existing consumers of ceos-agents (projects that have installed the plugin) may have CLAUDE.md docs, runbooks, or institutional memory referencing `/ceos-agents:fix-bugs` etc. Is there a deprecation or redirect mechanism in the plugin system for old command names, or does the migration need to preserve the `commands/` directory with redirect stubs?

---

## R6 — Version Bump Mechanics

What files need version 6.0.0, what CHANGELOG format applies, and how does the roadmap update?

**R6.1** `plugin.json` and `marketplace.json` both contain `"version": "5.7.0"`. The CLAUDE.md Versioning Policy table says MAJOR is triggered by breaking change in Automation Config contract OR breaking change in agent output format contract. Does removing `commands/` and replacing with `skills/` qualify as a MAJOR version bump under this policy? Specifically: does changing the invocation syntax for users (if it changes) constitute a breaking change, or is only the Automation Config contract affected?

**R6.2** CLAUDE.md line 18 states `- \`commands/\` — 25 commands (slash commands)`. After migration, this line must change. The versioning policy says MAJOR covers "new required key, renamed section" in Automation Config but does not explicitly address Repository Structure changes. Is changing the Repository Structure section of CLAUDE.md (non-Automation-Config) sufficient justification for MAJOR, or is this a MINOR change?

**R6.3** `CHANGELOG.md` follows Keep a Changelog format with a heading pattern `## [6.0.0] — YYYY-MM-DD` followed by a bold type label (`**MAJOR**`). The changelog entry must list every file touched. What is the standard section structure for a migration-only release — should it use `### Changed` only, or also `### Added` (new skill directories) and `### Removed` (commands/ directory)?

**R6.4** The `version-bump.md` command reads `plugin.json` and `marketplace.json` and edits them. It also updates the `## Current version` comment in roadmap.md. After running `/ceos-agents:version-bump major`, which additional files must be manually updated (CLAUDE.md version references, memory MEMORY.md, roadmap.md)?

**R6.5** `roadmap.md` currently has `> **Current version:** v5.7.0`. A MAJOR release for an architectural migration belongs in a new `## DONE — v6.0.0` section. What is the standard entry format for a migration that has no new user-visible features — is "DONE — v6.0.0 (Commands-to-Skills Migration)" a valid section name, or does it need a feature-focused label?

**R6.6** The `xref-command-count.sh` test checks that CLAUDE.md's claimed count for `commands/` matches the filesystem. After migration, if `commands/` is removed, the test must be updated or deleted before the test suite can pass. Does the release process (which requires `./tests/harness/run-tests.sh` to pass before commit) mean the tests must be updated in the same commit as the migration, or can they be updated in a separate prior commit?

---

## Summary Table

| Area | Questions | Key Risk |
|------|-----------|----------|
| R1 — Frontmatter contract | 7 | `allowed-tools` and `$ARGUMENTS` may not exist for skills — entire pre-approval model may need redesign |
| R2 — Cross-reference inventory | 7 | 25 test scenarios + 3 core files + CLAUDE.md + CHANGELOG need path updates; historical docs need a policy decision |
| R3 — File splitting | 6 | No confirmed evidence that multi-file skill directories work; `scaffold.md` at 780 lines is the critical case |
| R4 — Test migration patterns | 8 | 25 of 37 test scenarios reference `commands/` paths — all need updating; split files complicate content-grep tests |
| R5 — Backward compatibility | 6 | `$ARGUMENTS` absence was the original reason commands were kept; must confirm this constraint is resolved |
| R6 — Version bump mechanics | 6 | MAJOR justification must be confirmed against versioning policy; test suite must pass before commit |

**Total: 40 questions**
