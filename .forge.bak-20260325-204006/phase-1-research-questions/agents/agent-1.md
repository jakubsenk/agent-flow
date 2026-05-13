# Research Question 1: Plugin Architecture Constraints

## Refined Question

What are the exact structural constraints of the Claude Code plugin system — specifically: the plugin.json schema (which fields are required vs optional), how skills and commands are each registered and invoked (file naming, frontmatter schema, namespace rules), and what concrete migration risks exist when the `bug-workflow` skill or new skills are expected to replace or absorb the 24 existing `ceos-agents:` namespaced commands?

## Findings

### 1. plugin.json Schema

Both plugins examined use a minimal plugin.json at `.claude-plugin/plugin.json`. The confirmed fields are:

- `name` (string, required) — plugin identifier, also used as the namespace prefix
- `version` (string, required) — semver string
- `description` (string, required) — human-readable description
- `author` (object with `name` key, required) — attribution
- `repository` (string, optional) — git URL
- `license` (string, optional) — license identifier
- `homepage` (string, optional) — web URL
- `keywords` (array of strings, optional) — discovery tags

Neither plugin uses fields like `main`, `commands`, `skills`, or `agents` in plugin.json. There is NO explicit registration of commands or skills in plugin.json — the plugin system discovers them by directory convention.

ceos-agents plugin.json (C:/gitea_ceos-agents/.claude-plugin/plugin.json):
- name: "ceos-agents", version: "5.1.0"
- Has: name, description, version, author, repository, license
- Does NOT have: keywords, homepage, hooks

filip-superpowers plugin.json:
- name: "filip-superpowers", version: "0.1.0"
- Has: name, description, version, author, repository, homepage, license, keywords
- Does NOT have: any explicit command/skill registration

**Key finding:** The plugin.json schema is declarative metadata only. It does not control which commands or skills are active. Registration is purely structural (directory + frontmatter).

### 2. marketplace.json Schema

Both plugins use `.claude-plugin/marketplace.json` to describe publishable plugins. It wraps one or more plugin entries:

```json
{
  "name": "<marketplace-name>",
  "owner": { "name": "..." },
  "plugins": [
    {
      "name": "<plugin-name>",
      "source": "./",
      "description": "...",
      "version": "...",
      "author": { "name": "..." }
    }
  ]
}
```

The `source: "./"` in ceos-agents means the marketplace entry points to the repo root. This file appears to be used for discovery and installation, not for runtime behavior.

### 3. Command Registration Pattern

Commands live in `commands/*.md`. Each command file uses YAML frontmatter with these fields:
- `description` (string) — shown in Claude Code's command picker
- `allowed-tools` (string) — comma-separated list of tools the command can use (e.g., `mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task`)

The command filename (without `.md`) becomes the command name. The namespace prefix comes from `plugin.name` in plugin.json. So `commands/fix-ticket.md` in the `ceos-agents` plugin registers as `/ceos-agents:fix-ticket`.

There are 24 commands in `commands/`. None of them have any `name:` field in their frontmatter — the filename is the sole name registrant.

Example frontmatter (analyze-bug.md):
```yaml
---
description: Analyzes a specific bug from the issue tracker (analysis only, no code changes)
allowed-tools: mcp__*, Read, Glob, Grep, Task
---
```

Example frontmatter (fix-ticket.md):
```yaml
---
description: Analyzes and fixes a specific ticket (in CWD, no worktree)
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
---
```

### 4. Skill Registration Pattern

Skills live in `skills/<skill-name>/skill.md` (ceos-agents uses lowercase `skill.md`) or `skills/<skill-name>/SKILL.md` (filip-superpowers uses uppercase). The skill directory name becomes the skill name. The namespace prefix is the same plugin name.

So `skills/bug-workflow/skill.md` in the `ceos-agents` plugin registers as the `bug-workflow` skill under namespace `ceos-agents`.

Skill frontmatter uses exactly TWO fields:
```yaml
---
name: bug-workflow
description: Use when the user wants to analyze bugs, fix issues, create PRs, publish changes, scaffold projects, or implement features
---
```

The `name` field is present in skill frontmatter but NOT in command frontmatter. In skill frontmatter, `name` appears to be advisory/matching — it matches the directory name.

Skills do NOT have an `allowed-tools` field in their frontmatter (confirmed by examining both the ceos-agents skill and all filip-superpowers skills). This is a significant difference from commands.

### 5. Namespace Rules

The namespace prefix for both commands and skills is the `name` field in `plugin.json`. For ceos-agents: `ceos-agents`. Invocation syntax:
- Commands: `/ceos-agents:<command-name>` (e.g., `/ceos-agents:fix-ticket`)
- Skills: `ceos-agents:<skill-name>` (e.g., `ceos-agents:bug-workflow`)

The CLAUDE.md explicitly states (Plugin Composability section): "All commands are invoked as `/ceos-agents:<command>` (e.g., `/ceos-agents:fix-ticket`)"

Skills are invoked differently — the skill itself (in bug-workflow/skill.md line 43) shows the invocation syntax: `Skill(skill='ceos-agents:analyze-bug', args='{issue_id}')`. This means from within a skill, other skills/commands are called by their namespaced name.

### 6. Cross-Reference: Commands Calling Each Other

Commands invoke agents via the `Task` tool, using the agent's namespaced name. For example, fix-ticket.md line 102-103:
```
Run `ceos-agents:triage-analyst` (Task tool, model: sonnet).
```

The skill (bug-workflow) calls commands using `Skill(skill='ceos-agents:<command>')`. So the current architecture is: User → Skill (routing) → Command (orchestration) → Agent (Task tool).

### 7. How the Existing Skill Works

The bug-workflow skill (lines 1-56 of skills/bug-workflow/skill.md) is a routing layer only. It:
1. Identifies user intent from natural language
2. Confirms destructive operations with the user
3. Delegates to the appropriate command via `Skill(skill='ceos-agents:<command>')` invocation

It does NOT execute any pipeline logic itself. All pipeline logic lives in commands.

### 8. filip-superpowers Comparison: Skill-Heavy Architecture

The filip-superpowers plugin uses skills exclusively — it has NO `commands/` directory at all. It has 10 skills (forge, forge-research, forge-brainstorm, forge-spec, forge-tdd, forge-plan, forge-execute, forge-verify, forge-status, forge-resume, forge-cancel). Each skill is fully self-contained with pipeline logic. The `forge` skill (SKILL.md) is the orchestrator and references sub-skills via `/filip-superpowers:forge-resume` etc.

This confirms that skills CAN contain full orchestration logic — the plugin system doesn't restrict what goes in a skill vs a command.

### 9. Skill File Name Casing Difference

ceos-agents: `skills/bug-workflow/skill.md` (lowercase)
filip-superpowers: `skills/forge/SKILL.md` (uppercase)

Both work. The file naming convention is not enforced by the plugin system.

### 10. Agent Registration

Agents live in `agents/*.md` and use frontmatter with: `name`, `description`, `model`, `style`. They are invoked via the Task tool using their namespaced name (e.g., `ceos-agents:triage-analyst`). Agents are NOT invocable as slash commands by users — only via Task tool from within commands or skills.

## Key Constraints Discovered

- **plugin.json is metadata-only**: No explicit registration of commands, skills, or agents. Registration is entirely by directory structure.
- **Command namespace = plugin name**: Changing the plugin name would break all `/ceos-agents:*` references globally.
- **Skills have no `allowed-tools` field**: Unlike commands, skills cannot declare tool permissions in their frontmatter. This may be a significant constraint if skills need tools like Bash, Write, or mcp__* that commands currently use — the tool permissions model may differ.
- **Skill invocation syntax differs from command invocation**: Commands are `/namespace:name` (slash-prefixed). Skills are called programmatically as `Skill(skill='namespace:name')` — no slash prefix in code, but users invoke them with a slash: `/namespace:skill-name`.
- **Commands and skills can coexist**: The existing bug-workflow skill already delegates to commands. There is no constraint preventing a skill from delegating to other commands.
- **No `name` field in command frontmatter**: Commands are named by their filename only.
- **Skill `name` frontmatter field**: Present in both plugins' skill files. It appears to be required for skill registration (matches directory name).
- **The Task tool agent namespace**: Agents are invoked as `ceos-agents:<agent-name>` — this namespace is coupled to the plugin name, same as commands/skills.
- **No commands directory in filip-superpowers**: Confirms skills are architecturally equivalent to commands for full pipeline logic. The two types are not functionally distinct to the plugin runtime.
- **File convention difference**: ceos-agents uses `skill.md` (lowercase), filip-superpowers uses `SKILL.md` (uppercase). Both work. Consistency within the plugin is advisable.

## Files Examined

1. `C:/gitea_ceos-agents/.claude-plugin/plugin.json` — Plugin identity schema (name, version, description, author, repository, license)
2. `C:/gitea_ceos-agents/.claude-plugin/marketplace.json` — Marketplace listing wrapping plugin entries
3. `C:/gitea_ceos-agents/skills/bug-workflow/skill.md` — The only existing skill; routing-only pattern with `name` + `description` frontmatter; delegates to commands via Skill() calls
4. `C:/gitea_ceos-agents/commands/fix-ticket.md` — Full pipeline command; `description` + `allowed-tools` frontmatter; invokes agents via Task tool
5. `C:/gitea_ceos-agents/commands/analyze-bug.md` — Read-only command; minimal `allowed-tools` (no Bash/Write)
6. `C:/gitea_ceos-agents/commands/scaffold.md` — Complex multi-phase command; full allowed-tools including Bash
7. `C:/gitea_ceos-agents/docs/reference/commands.md` — Confirms all commands namespaced as `/ceos-agents:<command>`
8. `C:/gitea_ceos-agents/docs/reference/agents.md` — Confirms 18 agents, Task tool dispatch pattern
9. `C:/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.1.0/.claude-plugin/plugin.json` — Comparison plugin schema (adds keywords, homepage)
10. `C:/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.1.0/skills/forge/SKILL.md` — Full pipeline skill (10 phases, ~440 lines); confirms skills CAN hold full orchestration logic
11. `C:/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.1.0/skills/forge-research/SKILL.md` — Sub-skill pattern; references other skills via `/filip-superpowers:forge-resume`
12. `C:/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.1.0/skills/forge-status/SKILL.md` — Read-only skill; confirms skills can be read-only

## Migration Risks

1. **`allowed-tools` gap for skills**: All 24 commands declare `allowed-tools` in their frontmatter. If skills do not support `allowed-tools`, then migrating command logic into skills could strip tool access. The fixer pipeline (fix-ticket.md) needs `mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task` — if a skill replacing it cannot declare these, all MCP and file operations break. This is the highest-risk unknown.

2. **All internal cross-references use `ceos-agents:` prefix**: The skill bug-workflow uses `Skill(skill='ceos-agents:analyze-bug')`. The commands use `Run ceos-agents:triage-analyst (Task tool)`. If commands are removed, skills replacing them must keep the same invocation name, or all cross-references must be updated. With 24 commands and 18 agents each potentially referenced from multiple places, this is a large refactoring surface.

3. **No `name` field in command frontmatter vs required `name` in skill frontmatter**: If the migration adds a `name` field to skill frontmatter that conflicts with the directory name, behavior is undefined. The safe pattern (from both plugins) is: skill `name` = directory name = invocation name.

4. **User-facing invocation change**: Users currently invoke commands as `/ceos-agents:fix-ticket`. If these become skills, the invocation path is the same (`/ceos-agents:fix-ticket`) as long as the skill directory is named `fix-ticket`. But if the routing approach changes (one big skill vs 24 individual skills), user muscle memory breaks.

5. **Bug-workflow skill currently delegates to commands**: If commands are removed but bug-workflow skill still references `Skill(skill='ceos-agents:fix-ticket')`, the delegation breaks unless `fix-ticket` becomes a skill. The skill's intent table (lines 10-38) lists 24 command-to-intent mappings — all must stay resolvable.

6. **plugin.json does not need changes for adding skills**: Adding new skills requires only creating new skill directories with SKILL.md files. No plugin.json update needed. This is low-risk.

7. **Skill discovery mechanism is unknown**: The exact mechanism by which Claude Code discovers skills (lowercase vs uppercase filename, required frontmatter fields) is inferred from examples but not confirmed from official documentation. The casing difference (skill.md vs SKILL.md) between the two plugins is unexplained and represents an ambiguity risk.

8. **Agents remain unchanged**: Agents are invoked via Task tool regardless of whether the caller is a command or a skill. Migrating commands to skills does NOT require changing agent files — agents are isolated from this migration.

## Open Questions

1. **Do skills support `allowed-tools` frontmatter?** This is the single most critical unknown. If not, how do skills gain access to Bash, mcp__*, Write, and Edit? Does the skill inherit the invoking context's tool permissions, or is tool access unrestricted for skills?

2. **Is `skill.md` vs `SKILL.md` filename significant?** Both plugins work with different casing. Is Claude Code case-sensitive for skill discovery on Windows (which has a case-insensitive filesystem)?

3. **Can a skill call another skill?** The forge/SKILL.md references sub-skills like `/filip-superpowers:forge-resume`. The bug-workflow skill calls commands via `Skill()`. Is there a depth limit or recursive invocation constraint?

4. **What is the exact difference between a skill and a command at runtime?** Both are markdown files with YAML frontmatter describing behavior. The primary observed difference is: commands have `allowed-tools`, skills have `name`. Is there any behavioral difference in how Claude Code loads and executes them (e.g., context window allocation, tool access model)?

5. **Can a command and a skill share the same namespace name?** If `commands/fix-ticket.md` and `skills/fix-ticket/SKILL.md` both exist under `ceos-agents`, which takes precedence when `/ceos-agents:fix-ticket` is invoked?

6. **Are there any hooks or lifecycle mechanisms in plugin.json** that were not used by either plugin examined? (The filip-superpowers plugin has a `hooks/hooks.json` file that could not be read due to permissions.)

7. **How does `$CLAUDE_SKILL_DIR` work?** The forge SKILL.md references `${CLAUDE_SKILL_DIR}` as a path to read sub-prompts. Is this an injected environment variable? Does it point to the skill's own directory? This pattern (splitting skill logic into multiple prompt files within the skill directory) may be relevant for large command migrations.

8. **What happens to the `describe` command (`/discuss`) which has no direct user-intent mapping in bug-workflow?** The skill's intent table does not list `discuss`. If migrating from 24 commands to skills, commands not covered by the routing skill would become inaccessible via natural language.
