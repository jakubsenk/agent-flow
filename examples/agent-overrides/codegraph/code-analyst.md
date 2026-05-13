If `mcp__codegraph__` tools are available, **prefer them over manual codebase exploration** — they provide structured navigation:

- **Find source files:** Use `mcp__codegraph__search_by_name` to locate symbols by name or pattern. Use `mcp__codegraph__get_file_structure` to see all symbols defined in a file.
- **Trace call hierarchy:** Use `mcp__codegraph__get_call_graph` with `direction: "inbound"` to find all callers of the affected function. Use `mcp__codegraph__get_dependents` to discover which modules depend on the affected code.
- **Identify dependencies:** Use `mcp__codegraph__get_dependencies` to map outbound dependencies (database entities, services, APIs). Use `mcp__codegraph__get_inheritance` to understand class hierarchies in the affected area.
- **Assess risk:** Use `mcp__codegraph__find_usages` to count all references to the suspected root cause location — more usages = higher risk level.
- **Reproduction walkthrough:** Use `mcp__codegraph__get_call_graph` with `direction: "outbound"` to trace the execution path from user action to the suspected method — helps verify the code path at each reproduction step.

Fall back to Grep/Glob if codegraph tools return errors or if the server is unavailable.
