Implement v6.5.2 (Redmine + Publisher Fixes) — two confirmed pipeline bugs from real-world Redmine usage (drmax-readmine-test project).

### Bug 1: Redmine Status Transitions — Numeric ID Parsing
Pipeline agents fail silently when setting Redmine issue status — config uses text names (`status:In Progress`) but Redmine MCP tool requires numeric `status_id`.

Required changes:
- A. `skills/onboard/SKILL.md`: Generate `status_id:XX` format for Redmine. Ideally call `GET /issue_statuses.json` during onboard and let user pick from real statuses with IDs. Fallback: instruct user to enter numeric ID manually.
- B. `core/config-reader.md`: Parse both formats: `status_id:22` (numeric, preferred) and `status:In Progress` (legacy, WARN + best-effort).
- C. Pipeline agents (all status-setting sites): After each `redmine_update_issue(status_id: XX)`, verify via `redmine_get_issue` that status actually changed. If mismatch → WARN (not BLOCK).
- D. Files: `skills/onboard/SKILL.md`, `core/config-reader.md`, `skills/implement-feature/SKILL.md`, `skills/fix-ticket/SKILL.md`, `core/block-handler.md`, `core/post-publish-hook.md`.

AC:
1. `status_id:22` format parsed correctly and passed to MCP
2. `status:In Progress` legacy format logs WARN but still works (best-effort)
3. Post-update verification via `redmine_get_issue` after every status change
4. Pipeline continues with WARN on verification failure (not BLOCK)
5. Onboard template for Redmine generates `status_id:XX` format

### Bug 2: Publisher Literal `\n` in PR Body
Publisher agent passes PR body with escaped `\n` sequences instead of real newlines. Gitea MCP tool (`mcp__gitea__create_pull_request`) renders them literally in PR description.

Required changes:
- Publisher agent must pass `body` parameter as multi-line string with real line breaks, not escape sequences.
- Applies to ALL MCP tool calls accepting markdown body: `create_pull_request`, `edit_issue`, `create_issue_comment`, etc.
- Review all MCP call sites in `agents/publisher.md` and pipeline skills for the same pattern.
- Files: `agents/publisher.md`, potentially `skills/implement-feature/SKILL.md`, `skills/fix-ticket/SKILL.md`, `core/block-handler.md`.

### Post-implementation
1. Update `docs/plans/roadmap.md` — move v6.5.2 to DONE status
2. Run `./tests/harness/run-tests.sh` and fix failures
Version: PATCH (v6.5.2). No config contract changes — behavioral fixes only.
