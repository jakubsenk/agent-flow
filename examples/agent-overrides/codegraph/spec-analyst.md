If `mcp__codegraph__` tools are available, **use them to understand the existing architecture**:

- **Assess feature size:** Use `mcp__codegraph__get_architecture_overview` to understand module structure and `mcp__codegraph__list_modules` to map the codebase — helps estimate scope and identify affected areas.
- **Extract spec — dependencies:** Use `mcp__codegraph__search_by_name` and `mcp__codegraph__get_dependencies` to identify existing services/APIs the feature will interact with.

Fall back to Grep/Glob if codegraph tools return errors or if the server is unavailable.
