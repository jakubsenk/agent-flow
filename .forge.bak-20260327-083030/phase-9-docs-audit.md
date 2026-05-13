# Docs Audit — v5.3.0 / v5.4.0 Features

**Date:** 2026-03-26
**Scope:** Check whether documentation reflects the following new additions:
- 19 agents (deployment-verifier is new)
- 25 commands (check-deploy is new)
- skill renamed to `workflow-router` (was `bug-workflow`)
- `Local Deployment` config section (new optional section)
- `deployment-verifier` agent
- `/check-deploy` command

**Ground truth (actual filesystem):**
- `agents/` = 19 agents (including deployment-verifier)
- `commands/` = 25 commands (including check-deploy)
- `skills/workflow-router/SKILL.md` — skill already renamed, description already updated
- `CLAUDE.md` — already fully updated (19 agents, 25 commands, workflow-router, Local Deployment, deployment-verifier)

---

## 1. `docs/reference/agents.md`

**Status: OUTDATED**

Issues:
- Line 3: says "18 specialized agents" — should be **19**
- Agent overview table (lines 9–28): missing `deployment-verifier` row
- Model selection rationale (lines 33–34): sonnet list does not include `deployment-verifier`
- Read-only vs Execution classification (line 33): `deployment-verifier` is execution (writes result.json, manages app lifecycle)
- No `deployment-verifier` agent section exists anywhere in the file

Missing content to add:
- Count: 18 → 19
- Table row: `| deployment-verifier | sonnet | Execution | Standalone (/check-deploy) |`
- Agent section for deployment-verifier (name, model, type, pipeline, inputs, outputs, constraints, example output)
- Sonnet model list update in rationale paragraph

---

## 2. `docs/reference/commands.md`

**Status: OUTDATED**

Issues:
- Line 3: says "All 23 ceos-agents commands" — should be **25** (24 were in README, but check-deploy makes 25)

  > **Note:** README.md and CLAUDE.md both now list 25 commands. commands.md says 23.

- Command Index table (lines 14–40): missing `/check-deploy` row
- No `/check-deploy` section exists anywhere in the file

Missing content to add:
- Count: 23 → 25
- Table row for `/check-deploy` (Config category, links to anchor)
- Full `/check-deploy` section with syntax, flags (--start, --stop), description, example, related commands

---

## 3. `docs/reference/automation-config.md`

**Status: OUTDATED**

Issues:
- Overview table (lines 14–35): missing `Local Deployment` row
- Section count claim (line 9): "5 required sections and 13 optional sections" — with Local Deployment added it should be **14 optional sections**
- No `### Local Deployment` section exists in the Optional Sections part of the file

Missing content to add:
- Row in overview table: `| Local Deployment | No | /check-deploy |`
- Full `### Local Deployment` optional section with table of keys (Type, Start command, Stop command, Health check URL, Health check timeout, Ports) and example

---

## 4. `docs/reference/pipelines.md`

**Status: CURRENT**

The pipelines reference does not need to mention deployment-verifier or check-deploy — this is a standalone command, not part of the bug-fix, feature, or scaffold pipelines. The file correctly documents the three pipeline diagrams. No update needed.

---

## 5. `docs/reference/execution-loop.md`

**Status: CURRENT**

The execution loop documents the fixer/reviewer/test-engineer pattern shared across pipelines. check-deploy is not part of this loop. No update needed.

---

## 6. `docs/reference/trackers.md`

**Status: CURRENT**

Tracker reference covers issue tracker integrations only. No connection to deployment-verifier or check-deploy. No update needed.

---

## 7. `docs/guides/installation.md`

**Status: CURRENT**

Covers plugin installation steps only. Does not enumerate commands or agents. No update needed.

---

## 8. `docs/guides/` — other files

**Status: CURRENT** (custom-agents.md, cross-platform.md, mcp-configuration.md, tokens.md, troubleshooting.md)

None of these files enumerate commands or agents by count. No updates needed for the new additions.

---

## 9. `docs/architecture.md`

**Status: OUTDATED**

Issues:
- Line 28: `CMD[23 Slash Commands]` in the Mermaid diagram — should be **25**
- Lines 30–33: EXEC_AGENTS box in the diagram lists agents but does not include `deployment-verifier`
  - Current exec agents listed: "fixer, test-engineer, e2e-test-engineer, publisher, scaffolder, rollback-agent, spec-writer"
  - Missing: `deployment-verifier`
- Model selection table (lines 64–68): sonnet row does not list `deployment-verifier`
  - Current sonnet list: "triage-analyst, code-analyst, test-engineer, e2e-test-engineer, spec-analyst, stack-selector, scaffolder"
  - Missing: `deployment-verifier`

Note: The bug-fix pipeline diagram in architecture.md (line 82–87) is a simplified summary view. It intentionally omits optional stages (reproducer, browser-verifier). Omitting deployment-verifier is consistent with that pattern — deployment-verifier is not part of the bug-fix pipeline at all. No change needed to pipeline diagrams.

---

## 10. `README.md`

**Status: OUTDATED**

Issues:
- Line 3: "18 specialized AI agents, 24 orchestration commands" — should be **19 agents, 25 commands**
- Mermaid overview diagram (line 12): `Agents (18)` — should be **19**
- Commands table (lines 134–163): missing `/check-deploy` row
- Agents table (lines 168–189): missing `deployment-verifier` row
- Configuration section (line 208): "**12 optional sections**" — with Local Deployment added, should be **13 optional sections** (or "13 optional sections")
- Documentation table (lines 249–250): Commands reference says "All 24 commands" — should be **25**

---

## 11. `CONTRIBUTING.md`

**Status: CURRENT**

CONTRIBUTING.md does not mention agent or command counts anywhere. It describes the agent format, command format, and contribution process generically. No update needed.

---

## 12. `docs/plans/roadmap.md`

**Status: CURRENT**

The roadmap correctly has:
- `## PLANNED — v5.3.0 (Guided Handoff)` section — exists (lines 136–166)
- `## PLANNED — v5.4.0 (Feature from Chat + Deploy)` section — exists (lines 168–182), includes Local Deployment Verification entry
- `workflow-router` rename listed under v5.3.0 PLANNED items (line 156)
- `deployment-verifier` and `check-deploy` listed under v5.4.0 (line 181)

No update needed.

---

## 13. `.claude-plugin/plugin.json`

**Status: CURRENT**

Version: 5.2.0 — matches current released version. No command list in this file. No update needed.

---

## 14. `.claude-plugin/marketplace.json`

**Status: CURRENT**

Version: 5.2.0 — matches. No command list in this file. No update needed.

---

## 15. `docs/getting-started.md`

**Status: OUTDATED**

Issues:
- "Next Steps" section (line 219): says "Explore all 23 commands" — should be **25**
  - Exact text: "**[Command Reference](reference/commands.md)** — Explore all 23 commands with syntax, flags, and usage examples."

---

## Summary Table

| File | Status | What Needs Updating |
|------|--------|---------------------|
| `docs/reference/agents.md` | OUTDATED | Count 18→19, add deployment-verifier row + section |
| `docs/reference/commands.md` | OUTDATED | Count 23→25, add check-deploy row + section |
| `docs/reference/automation-config.md` | OUTDATED | Add Local Deployment optional section + table row |
| `docs/reference/pipelines.md` | CURRENT | — |
| `docs/reference/execution-loop.md` | CURRENT | — |
| `docs/reference/trackers.md` | CURRENT | — |
| `docs/guides/installation.md` | CURRENT | — |
| `docs/guides/*.md` (other 5) | CURRENT | — |
| `docs/architecture.md` | OUTDATED | CMD count 23→25 in diagram, add deployment-verifier to exec agents box + sonnet model table |
| `README.md` | OUTDATED | Counts (agents 18→19, commands 24→25), add check-deploy to commands table, add deployment-verifier to agents table, optional sections 12→13 |
| `CONTRIBUTING.md` | CURRENT | — |
| `docs/plans/roadmap.md` | CURRENT | — |
| `.claude-plugin/plugin.json` | CURRENT | — |
| `.claude-plugin/marketplace.json` | CURRENT | — |
| `docs/getting-started.md` | OUTDATED | "23 commands" → "25 commands" |

---

## Files with OUTDATED status (5 files)

1. `/c/gitea_ceos-agents/docs/reference/agents.md` — count + missing deployment-verifier
2. `/c/gitea_ceos-agents/docs/reference/commands.md` — count + missing check-deploy
3. `/c/gitea_ceos-agents/docs/reference/automation-config.md` — missing Local Deployment section
4. `/c/gitea_ceos-agents/docs/architecture.md` — counts + diagram
5. `/c/gitea_ceos-agents/README.md` — counts + missing rows in both tables
6. `/c/gitea_ceos-agents/docs/getting-started.md` — "23 commands" string

## Files with MISSING status

None — all referenced files exist.
