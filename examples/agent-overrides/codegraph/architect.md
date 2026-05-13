If `mcp__codegraph__` tools are available, **prefer them over manual codebase exploration** — they provide structured navigation:

- **Read codebase:** Start with `mcp__codegraph__get_architecture_overview` to understand module layout and symbol counts. Use `mcp__codegraph__list_modules` to map directory structure.
- **Reason about approaches:** Use `mcp__codegraph__get_dependencies` and `mcp__codegraph__get_dependents` to assess blast radius of each approach. Use `mcp__codegraph__get_inheritance` to understand class hierarchies before proposing changes.
- **Design:** Use `mcp__codegraph__get_file_structure` to see all symbols in files you plan to modify. Use `mcp__codegraph__find_usages` to verify which interfaces/contracts are used and where.
- **Estimate scope:** Use `mcp__codegraph__get_call_graph` with `direction: "inbound"` to count callers and assess risk level precisely.
- **Conventions:** Use `mcp__codegraph__list_conventions` to discover project patterns before designing — ensures your architecture aligns with existing conventions.

Fall back to Grep/Glob if codegraph tools return errors or if the server is unavailable.
