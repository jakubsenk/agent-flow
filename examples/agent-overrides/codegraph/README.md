# Codegraph Agent Overrides

Agent override files for projects using a [codegraph MCP server](../mcp-configs/codegraph.json).

## Usage

Copy the files you need into your project's Agent Overrides directory (configured via `Agent Overrides → Path` in Automation Config). Files must be placed **directly** in the override path — not in a subdirectory:

```
# Correct — files at override root
customization/architect.md
customization/analyst.md
customization/spec-analyst.md

# Wrong — subdirectory is silently ignored
customization/codegraph/architect.md
```

> **Note:** The override file for the analyst agent is `analyst.md` (canonical name). `code-analyst.md` is a legacy name — **rename it to `analyst.md` before use**. The agent override injector matches filenames against agent names, and the agent is named `analyst`.

## Included Agents

| File | Agent | What codegraph adds |
|------|-------|---------------------|
| `architect.md` | architect | Structured dependency/inheritance analysis for design decisions, blast radius assessment |
| `code-analyst.md` | analyst (**legacy name — rename to `analyst.md` before use**) | Call graph tracing for root cause analysis, usage counting for risk assessment |
| `spec-analyst.md` | spec-analyst | Architecture overview for feature size estimation, dependency mapping for spec extraction |

## Codegraph Tools Used

These overrides reference tools from the codegraph MCP server's Structural and Convention Discovery categories:

`get_architecture_overview`, `list_modules`, `get_dependencies`, `get_dependents`, `get_inheritance`, `get_file_structure`, `search_by_name`, `find_usages`, `get_call_graph`, `list_conventions`
