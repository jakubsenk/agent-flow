# Security Review — v5.5.0 Scaffold Infrastructure Integration

**Reviewer:** Security Reviewer (automated)
**Date:** 2026-03-27
**Scope:** `commands/scaffold.md` (Steps 0-INFRA, 0-MCP, 4, 4d, 4e), `CHANGELOG.md`
**Overall Score: 0.90 / 1.0**

---

## Concern 1: Token/Credential Collection in Step 0-MCP

**Verdict: PASS**

Step 0-MCP collects only:
- `tracker_type` (enum: youtrack/github/jira/linear/gitea/redmine)
- `tracker_instance` (URL)
- `tracker_project` (project key/name)
- `sc_remote` (owner/repo format)
- `sc_base_branch` (branch name, default: "main")
- Two status flags (`tracker_effective_status`, `sc_effective_status`)

No tokens, API keys, passwords, or credentials are collected or stored at any point. MCP connectivity is verified by calling existing `mcp__*` tools that are already authenticated in the parent session context. The command relies on pre-configured MCP servers rather than asking for credentials.

Step 0-MCP line 113-114 explicitly provides "required environment variables (from trackers.md)" as *guidance text* if MCP is not found, but does not prompt for or store those values.

**No issues found.**

---

## Concern 2: .mcp.json.example Placeholder Tokens

**Verdict: PASS**

Step 4b-replaced (line 370) explicitly specifies:
> generate `.mcp.json.example` with the correct MCP server package and `<YOUR_*>` token placeholders

Line 373 reinforces:
> This file is a template only — real tokens are NOT collected during scaffold.

The `<YOUR_*>` pattern is the standard placeholder convention. No real tokens from the session MCP configuration are copied into the generated file.

**No issues found.**

---

## Concern 3: .mcp.json in .gitignore

**Verdict: PASS**

Step 4b-replaced (line 372) explicitly states:
> Add `.mcp.json` to `.gitignore` (never commit real tokens).

Only `.mcp.json.example` (the template with placeholders) is committed. The actual `.mcp.json` (which would contain real tokens after user fills them in) is gitignored.

**No issues found.**

---

## Concern 4: Credential Exposure in Push URL (Step 4d)

**Verdict: PASS with NOTE**

Step 4d (lines 394-398) uses:
```bash
git remote add origin {sc_remote}
git push -u origin {sc_base_branch}
```

The `{sc_remote}` variable is collected at Step 0-INFRA as "owner/repo" format (line 84: `sc_remote | User's remote (owner/repo) or null`). This is NOT a full URL with embedded credentials (e.g., `https://token@github.com/...`). Git authentication is expected to be handled by the MCP server or pre-configured git credentials, not by embedding tokens in the URL.

**NOTE (low severity):** There is no explicit validation that `sc_remote` is in the expected `owner/repo` format and not a URL with embedded credentials. If a user accidentally pastes `https://ghp_xxxxx@github.com/org/repo`, it would be stored in-memory as `sc_remote` and used in the `git remote add` command. While this is transient (in-memory only, not persisted to files), it would appear in shell history.

**Recommendation:** Add a validation note in Step 0-INFRA's SC collection: "Validate that `sc_remote` matches `owner/repo` pattern. If a full URL with credentials is provided, strip the auth portion and warn the user." This is a minor hardening, not a blocking issue.

---

## Concern 5: Sensitive Data in Tracker Issues (Step 4e)

**Verdict: PASS with NOTE**

Step 4e (lines 415-421) creates issues from `spec/epics/*.md` content:
- Title: from epic heading
- Description: from epic content
- Sub-issues: from user stories within the epic

The spec content is user-generated (by spec-writer from user description) and represents planned features, not internal implementation details. The spec-writer agent generates public-facing specification content, not debug output or internal system data.

**NOTE (low severity):** If the user's original project description (passed to spec-writer) contains sensitive internal data, that data could flow through to tracker issues. This is inherent to the workflow design and not specific to v5.5.0 changes. The user explicitly chose to create tracker issues and provided the project description themselves.

**No actionable issue for v5.5.0.**

---

## Concern 6: Injection Vectors in MCP Detection Logic

**Verdict: PASS with NOTE**

Step 0-MCP detection (lines 106-130) works by:
1. Reading the MCP Server Detection table from `docs/reference/trackers.md` — static lookup, no user input in the table
2. Scanning available `mcp__*` tools for matching package names — read-only introspection of the Claude Code session
3. Verifying connectivity by calling the MCP tool (list issues, verify repo) — uses the MCP tool's own API, not shell commands

There are no `eval`, `exec`, `$()` command substitution, or direct shell interpolation of user-provided values in the MCP detection logic. The `tracker_type` is constrained to a known enum (youtrack/github/jira/linear/gitea/redmine).

**NOTE (informational):** The `core/mcp-preflight.md` (line 20) has a fallback for unknown tracker types: `mcp__{tracker_type}__*`. If `tracker_type` were somehow set to a malicious value, the worst case is a failed tool prefix lookup (no tool found). Since this is used as a tool name pattern match, not in a shell context, the injection risk is negligible.

---

## CHANGELOG.md Review

**Verdict: PASS**

Scanned for tokens, secrets, passwords, API keys, credentials, and bearer tokens. No sensitive information found. The changelog references `YOUTRACK_URL`, `FORGEJO_URL`, `FORGEJO_TOKEN`, and `ATLASSIAN_*` only as environment variable *names* (not values), which is appropriate for documentation.

The mention of "Docker log secret redaction" in v5.3.0 entry (line 96) refers to a feature that *prevents* secret leakage — positive security behavior.

---

## Additional Findings

### F1: rm -rf Safety (existing, not new to v5.5.0)

Lines 195-199 and 357 include `rm -rf $SCAFFOLD_TEMP` with a safety check that the path contains `/tmp`. This pre-existing defense-in-depth measure is adequate.

### F2: In-Memory State Not Persisted to state.json

The CHANGELOG Known Limitations (line 36) explicitly acknowledges:
> Infrastructure declarations are in-memory only (no state.json field). `/resume-ticket` cannot recover them after a mid-scaffold crash.

This is a reliability concern, not a security concern. In-memory storage means credentials/URLs are never written to disk state files, which is actually a security advantage.

### F3: `git add -A` Usage in Step 7d

Step 7d (line 555) uses `git add -A` for subtask commits. While this could accidentally stage sensitive files, the scaffold generates into a clean directory from the scaffolder agent. The `.gitignore` is generated with `.mcp.json` excluded (Concern 3). This is standard scaffold behavior and low risk.

---

## Summary

| # | Concern | Verdict | Severity |
|---|---------|---------|----------|
| 1 | Token collection in Step 0-MCP | PASS | None |
| 2 | .mcp.json.example placeholder tokens | PASS | None |
| 3 | .mcp.json in .gitignore | PASS | None |
| 4 | Credential exposure in push URL | PASS + NOTE | Low |
| 5 | Sensitive data in tracker issues | PASS + NOTE | Low |
| 6 | Injection vectors in MCP detection | PASS + NOTE | Informational |
| 7 | CHANGELOG secrets check | PASS | None |

**Blocking issues: 0**
**Low-severity notes: 2** (URL format validation in Step 0-INFRA, user data flow-through in Step 4e)
**Informational notes: 1** (unknown tracker type fallback)

The v5.5.0 changes demonstrate sound security design: tokens are never collected, real `.mcp.json` is gitignored, placeholder-only templates are committed, MCP detection uses tool introspection rather than shell commands, and push operations use owner/repo format rather than credential-embedded URLs.
