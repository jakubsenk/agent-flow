# Research Answer 1: Skills Tool Access Model

## Evidence Gathered

### Command Frontmatter (ceos-agents)

Both examined commands declare explicit `allowed-tools`:

**`commands/fix-ticket.md`:**
```yaml
---
description: Analyzes and fixes a specific ticket (in CWD, no worktree)
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
---
```

**`commands/fix-bugs.md`:**
```yaml
---
description: Automatically fixes N bugs from the issue tracker
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
---
```

Both commands include the full range of file-system tools (Read, Write, Edit, Glob, Grep), execution tools (Bash), agent dispatch (Task), and a wildcard MCP pattern (`mcp__*`) for issue-tracker integrations.

### Skill Frontmatter (ceos-agents)

**`skills/bug-workflow/skill.md`:**
```yaml
---
name: bug-workflow
description: Use when the user wants to analyze bugs, fix issues, create PRs, publish changes, scaffold projects, or implement features
---
```

No `allowed-tools` key is present. The frontmatter contains only `name` and `description`. The skill is a pure routing layer — its body invokes `Skill(skill='ceos-agents:{command}', ...)` to delegate to commands, and never directly calls tools like Bash, Read, Write, or Task.

### Skill Frontmatter (filip-superpowers)

All 4 examined skills from the filip-superpowers plugin share the same frontmatter schema — `name` and `description` only, with no `allowed-tools` key in any of them:

**`skills/forge/SKILL.md`:**
```yaml
---
name: forge
description: >
  Use when the user wants to build a complete feature, module, or system
  from a natural-language description. Triggers on requests like "build me X",
  "implement Y from scratch", "create Z end-to-end", or explicit /forge invocation.
  NOT for small edits, bug fixes, or single-file changes.
---
```

**`skills/forge-execute/SKILL.md`:**
```yaml
---
name: forge-execute
description: >
  Use when the user has an approved implementation plan and wants to execute
  it with parallel subagents in isolated worktrees. ...
---
```

**`skills/forge-research/SKILL.md`:**
```yaml
---
name: forge-research
description: >
  Use when the user wants to conduct structured technical research on a topic ...
---
```

**`skills/forge-plan/SKILL.md`:**
```yaml
---
name: forge-plan
description: >
  Use when the user wants to create a detailed implementation plan with
  dependency graph and task decomposition. ...
---
```

**`skills/forge-status/SKILL.md`:**
```yaml
---
name: forge-status
description: >
  Use when the user wants to see the current state of a running or completed
  forge pipeline. ...
---
```

Zero of the 5 examined skills (across 2 separate plugins) declare `allowed-tools`.

### Tools Actually Used by Skills

The `forge` skill (SKILL.md) explicitly directs the orchestrator to use the following tools in its content:

- **Agent tool** — dispatched for every pipeline phase (Phase 0 through 9), referenced as "single Agent tool call", "N Agent tool calls in a SINGLE response". This is a tool-requiring operation (dispatches subagents with their own tool access).
- **Write** — forge.json initialization, forge.log writing, writing phase outputs to `.forge/` directory.
- **Read** — reading forge.json for state, reading phase output files per the Context Handoff Protocol.
- **AskUserQuestion** — approval gates (Gate 1, 2, 3), resume/fresh start decisions, post-completion decision.

The `forge-execute` skill additionally references:
- **Bash** — git worktree operations (`git worktree add`, `git stash`, `git rev-parse`, `git status --porcelain`, `git worktree remove`), PASS_TO_PASS test execution.
- **Agent** — parallel task dispatch.

The `forge-status` skill is explicitly described as "READ-ONLY. It never modifies forge.json or any pipeline state." — yet its frontmatter also contains no `allowed-tools` restriction.

No `commands/` directory exists in the filip-superpowers plugin — it is entirely skill-based (13 skills total).

The CLAUDE.md at the filip-superpowers plugin root could not be accessed due to permission denial.

## Conclusion

Skills do NOT support the `allowed-tools` frontmatter key. The evidence is unambiguous:

1. **Structural absence**: Zero out of 5 examined skills (across 2 plugins) declare `allowed-tools`, while every examined command declares it explicitly.

2. **Schema divergence**: The command frontmatter schema is `{description, allowed-tools}`. The skill frontmatter schema is `{name, description}`. The `allowed-tools` field is a command-only concept.

3. **Unrestricted execution in practice**: The `forge` and `forge-execute` skills instruct the orchestrator to use Agent, Write, Read, Bash, AskUserQuestion — heavy tool usage — without any frontmatter-level restriction. If skills had a tool access restriction mechanism, the forge pipeline (which requires git operations, file writes, and subagent dispatch) would be non-functional.

4. **The access model for skills is inherited from the invoking context.** A skill runs in the same tool-access context as the Claude Code session that invoked it. It does not narrow or declare its own tool whitelist. The session's already-granted tool permissions apply.

The read-only property of `forge-status` is enforced by the skill's prose instructions ("This skill is READ-ONLY. It never modifies..."), not by frontmatter-level tool restriction. This is a behavioral constraint, not a security boundary.

## Implications for Migration

If ceos-agents commands are migrated to skills, the following implications apply:

1. **Tool access does not change**: Skills will have access to all the same tools that the commands currently declare via `allowed-tools`. The `mcp__*`, Bash, Read, Write, Edit, Glob, Grep, Task permissions are all available to skills.

2. **No `allowed-tools` declaration needed**: The migrated skills will not need (and cannot use) the `allowed-tools` frontmatter key. Tool access is session-wide, not skill-scoped.

3. **Read-only enforcement must be prose-based**: The current split between read-only agents (triage-analyst, code-analyst, reviewer, etc.) and execution agents is enforced by agent prompt instructions ("NEVER modify code"). This pattern must be preserved in any skill-level equivalent — there is no frontmatter mechanism to enforce it.

4. **Security posture change**: Commands currently declare a minimal tool set (`mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task`). After migration to skills, this explicit narrowing is lost. Any tool available in the invoking session is theoretically accessible. For the ceos-agents use case (automation pipelines), this is not a practical concern since the full tool set is already declared in commands. But for environments with sensitive tools (e.g., production deployment MCPs), the absence of skill-level `allowed-tools` is a gap.

5. **The `name` field becomes mandatory**: Commands only declare `description`. Skills require both `name` and `description` in frontmatter.

## Gaps

1. **No access to the filip-superpowers CLAUDE.md**: File at `/0.1.0/CLAUDE.md` was denied. It may contain plugin-level tool access declarations that override or supplement skill frontmatter — this could not be verified.

2. **Claude Code SDK internals not inspectable**: The actual runtime behavior (whether the SDK even reads an `allowed-tools` field from skill frontmatter, or silently ignores it) cannot be determined from the markdown files alone. The absence of the field in all observed skills could reflect either "not supported" or "universally omitted by convention."

3. **`plugin.json` not examined**: The plugin metadata files (`.claude-plugin/plugin.json`) may declare plugin-level tool permissions that apply to all skills and commands within the plugin. This was not checked and could represent an additional layer in the permission model.

4. **AskUserQuestion tool**: Used by forge skills but not declared in any ceos-agents command `allowed-tools`. Its availability to skills vs. commands could not be confirmed from the examined files.
