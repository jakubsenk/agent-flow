# Phase 0 — User Input (Verbatim)

Implement v5.6.1 (UX Polish) for the ceos-agents plugin. Four items from the roadmap:

1. **--infra flag format**: Change positional `--infra ready,later` to self-documenting `--infra tracker:ready,sc:later` format
2. **Canary-write should ask or announce**: Before creating test item in tracker, announce "Testing write access — creating a temporary test item in {project}..." and in interactive mode consider asking first
3. **Error messages should use user language not MCP jargon**: Rewrite block messages from "MCP server for {type} is not available" to "Cannot connect to your {type} tracker. Is the {type} integration configured?" with actionable next steps
4. **Resume should allow infrastructure override**: Detect `--infra` flag on re-invocation of scaffold resume and prefer it over stale state.json values. Display: "Infrastructure changed since last run. Using new values."
