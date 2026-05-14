# Contributing to agent-flow

Thank you for your interest in contributing to agent-flow! This guide will help you get started.

## How to Contribute

1. **Fork** the repository at https://github.com/asysta-act/agent-flow
2. **Create a branch** from `main` (`git checkout -b feature/your-feature`)
3. **Make your changes** following the conventions below
4. **Test** your changes (see Testing section)
5. **Submit a Pull Request** with a clear description

### Coding Standards

- Follow the conventions documented in [CLAUDE.md](CLAUDE.md)
- Agent definitions: English descriptions, Goal/Expertise/Process/Constraints sections
- Command definitions: English descriptions in frontmatter, structured orchestration steps
- Config sections: always table format (`| Key | Value |`)

## Writing Custom Agents

Custom agents extend the pipeline with domain-specific checks. They follow the same format as core agents.

### Agent Format

```yaml
---
name: your-agent-name
description: One-line description (English)
model: sonnet | opus | haiku
---
```

Followed by markdown sections in this exact order:

1. **Goal** — What the agent achieves
2. **Expertise** — Domain knowledge areas
3. **Process** — Numbered, actionable steps
4. **Constraints** — Rules starting with NEVER or defining hard limits

### Best Practices

- Keep agents focused on a single responsibility
- Read-only agents should NEVER modify code
- Use the Block Comment Template for failure reporting
- Choose the right model: `opus` for critical decisions, `sonnet` for analysis, `haiku` for mechanical tasks
- See `examples/custom-agents/` for reference implementations

## Writing Commands

Commands orchestrate agents and define pipeline flows.

### Command Format

```yaml
---
description: Short description (English)
allowed-tools: tool1, tool2, ...
---
```

### Guidelines

- Commands contain orchestration logic, not domain logic
- Read configuration from `## Automation Config` in the project's CLAUDE.md
- Dispatch agents via the Task tool
- Handle errors via Block handler pattern
- Support `--dry-run` where applicable

## Submitting Examples

### Config Templates

Add new templates to `examples/configs/`:

1. Name format: `{tracker}-{stack}.md`
2. Include complete `## Automation Config` block
3. Use placeholder values (`<...>`) for project-specific settings
4. Include appropriate Build & Test commands for the stack

### Custom Agent Examples

Add to `examples/custom-agents/`:

1. Follow the standard agent format (frontmatter + 4 sections)
2. Must be read-only (analysis only, no code modifications)
3. Include example output format in the Process section

### MCP Config Examples

Add to `examples/mcp-configs/`:

1. Standard `.mcp.json` format
2. Use placeholder values for tokens and URLs
3. One file per tracker/service

## Functional test scenarios — security expectations

New test scenarios added under `tests/scenarios/` are reviewed against the following checklist at PR time. There is no automated CI gate enforcing these rules; enforcement is at PR review. Scenarios that violate these expectations will be sent back for revision before merge.

1. No `$(...)` command-substitution in fixture construction — use pre-assigned variables or heredocs instead.
2. No `eval` in any scenario — dynamic code execution in test fixtures is never necessary and introduces injection risk.
3. No out-of-tree sourcing — only `tests/lib/fixtures.sh` or inline bash is permitted; no sourcing of files outside the `tests/` directory.
4. **No `awk` + `source` code-lift pattern** — do not extract functions from production scripts via `awk` then `source` them in tests. Use inline-redefine instead.
5. `set -uo pipefail` mandatory at scenario start — catches unbound variables and pipeline failures that would otherwise silently mask test errors.
6. All filesystem operations (paths, filenames, directory references) must be double-quoted to handle spaces and special characters correctly.
7. Scratch directory hygiene — use `mktemp -d` (never `$TMPDIR` or `$HOME`) and register `trap 'rm -rf "$SCRATCH"' EXIT` to guarantee cleanup on any exit path.

## Reporting Issues

- **Bugs**: Open an issue with reproduction steps, expected vs actual behavior
- **Feature Requests**: Open an issue describing the use case and proposed solution
- **Questions**: Open a discussion or issue with the `question` label

For security vulnerabilities, see [SECURITY.md](SECURITY.md) instead of opening a public issue.

## Questions or issues?

For questions about contributing or to reach the maintainer, contact [filip.sabacky@ceosdata.com](mailto:filip.sabacky@ceosdata.com).

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for the full Code of Conduct.
