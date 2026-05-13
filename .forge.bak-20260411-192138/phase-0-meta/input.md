# User Input (Verbatim)

Improve the `check-setup` skill in the `ceos-agents` Claude Code plugin. Three specific issues were found during testing on the `drmax-readmine-test` project:

**Issue 1: MCP connectivity — missing TLS error diagnostics**
When the Redmine MCP server returns "fetch failed", check-setup just reports "not reachable". In reality, the server was running, but Node.js was refusing a self-signed/internal certificate (UNABLE_TO_VERIFY_LEAF_SIGNATURE). Requirement: When an MCP query fails with "fetch failed", add a diagnostic step to Block 3 (Connectivity) — try curl on the Instance URL. If it returns an HTTP response but MCP failed, recommend adding `"NODE_OPTIONS": "--use-system-ca"` to the MCP server's env section in .mcp.json. Distinguish in output: `[FAIL] server unreachable` vs `[FAIL] server reachable but MCP connection failed (likely TLS — add NODE_OPTIONS: --use-system-ca to .mcp.json env)`.

**Issue 2: Gitea token scope — WARN is too vague**
Check-setup reports [WARN] that read:user scope is missing, but doesn't say which pipeline phases actually need it. If no phase uses list_my_repositories, the WARN is unnecessary. Requirement: Verify whether the pipeline actually calls list_my_repositories. If not, remove the check or downgrade to [INFO]. If yes, specify in the WARN which phases need it.

**Issue 3: trackers.md — relative path doesn't work**
The skill references docs/reference/trackers.md but the path is relative to the ceos-agents root, not the skill directory. When reading from a different CWD, the file isn't found. Requirement: Ensure robust path resolving to trackers.md independent of CWD.
