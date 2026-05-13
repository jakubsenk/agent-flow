# v5.6.1 UX Polish — Design

## File Modification Plan

### Primary File: `commands/scaffold.md`

This file receives the most changes (UXP-1, UXP-2, UXP-3, UXP-4):

| Section | Lines | Change |
|---------|-------|--------|
| Flag Parsing | 22 | --infra format description |
| Flag Validation | 36-40 | Validation rules + error messages |
| Step 0-INFRA (--infra preset) | 60-62 | Parsing logic update |
| Step 0-INFRA (On resume) | 126 | Resume override logic (UXP-4) |
| Step 0-MCP (detect MCP) | 138-143 | Canary announcement (UXP-2) |
| Step 0-MCP (mcp_available false) | 146 | Error message (UXP-3) |
| Step 0-MCP (YOLO block) | 158-160 | Block message (UXP-3) |
| Step 0-MCP (auto-downgrade) | 163 | Downgrade message (UXP-3) |
| MCP Pre-flight Check section | 750-751 | Standard error (UXP-3) |

### Standard Error Message Files (12 files, identical change)

All share the exact same error string pattern. Each file has this text exactly once:

| File | Line |
|------|------|
| `commands/analyze-bug.md` | 15 |
| `commands/changelog.md` | 15 |
| `commands/create-pr.md` | 17 |
| `commands/dashboard.md` | 29 |
| `commands/estimate.md` | 23 |
| `commands/fix-bugs.md` | 80 |
| `commands/metrics.md` | 29 |
| `commands/prioritize.md` | 22 |
| `commands/publish.md` | 15 |
| `commands/resume-ticket.md` | 72 |
| `commands/scaffold-add.md` | 24 |
| `commands/status.md` | 15 |

All receive the same transformation:
```
OLD: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure."
NEW: "Cannot connect to your {Type} issue tracker. Is the {Type} integration configured? Run `/ceos-agents:check-setup` for diagnostics."
```

### implement-feature.md (3 changes)

| Section | Lines | Change |
|---------|-------|--------|
| MCP pre-flight (standard) | 76 | Error message (UXP-3) |
| MCP pre-flight (YOLO block) | 72-74 | Block Reason + Detail + Recommendation (UXP-3) |
| Step 0c (card creation block) | 146 | Recommendation text (UXP-3) |

### core/mcp-preflight.md (2 changes)

| Section | Lines | Change |
|---------|-------|--------|
| No matching MCP tool block | 34-36 | Reason + Recommendation (UXP-3) |
| Connectivity failure block | 43 | Reason (UXP-3) |

### Metadata files

| File | Change |
|------|--------|
| `CHANGELOG.md` | New v5.6.1 entry |
| `docs/plans/roadmap.md` | Move PLANNED v5.6.1 section to DONE |

## Dependency Order

Changes are independent at the file level but should be applied in this order for clarity:

1. **UXP-1 (--infra format)** — affects only `commands/scaffold.md`. Apply all UXP-1.x requirements first because UXP-4 references the new format in its override logic.

2. **UXP-4 (resume --infra override)** — affects only `commands/scaffold.md` line 126. Depends on UXP-1 being applied first (the override logic uses the new `tracker:{value},sc:{value}` format).

3. **UXP-2 (canary announcement)** — affects only `commands/scaffold.md` lines 138-143. Independent of other changes.

4. **UXP-3 (MCP jargon)** — affects 16 files. Fully independent. Can be applied in any order. Apply last to avoid merge conflicts with scaffold.md changes from UXP-1/2/4.

5. **CHANGELOG + Roadmap** — apply after all content changes are verified.

## Edge Cases to Handle

### UXP-1: --infra Format

- **Mixed case:** Reject. Format is case-sensitive (`ready` and `later` only, not `Ready` or `LATER`).
- **Extra whitespace:** `--infra tracker:ready, sc:later` (space after comma). Reject — "no whitespace" rule matches current behavior.
- **Duplicate keys:** `--infra tracker:ready,tracker:later`. Reject — "Invalid --infra format" error.
- **Missing key:** `--infra tracker:ready` (no sc). Reject — partial named format is ambiguous.
- **Old format detection:** When `--infra ready,later` is provided (matches `{ready|later},{ready|later}`), show specific migration error pointing to new format. Do NOT silently treat it as the old format.

### UXP-2: Canary Announcement

- **SC service:** No announcement. The announcement only fires for tracker services where `check_write = true`. SC services always have `check_write = false`.
- **Tracker with null project:** If `tracker_project` is null (user said "ready" but hasn't provided project key yet), the announcement should still display but with a generic message. However, this case should not occur because Step 0-INFRA collects project key before Step 0-MCP runs.
- **Full YOLO mode:** Announcement still displays. The announcement is informational only — it does not ask for confirmation.

### UXP-3: MCP Jargon

- **SC vs Tracker distinction:** The current standard error always says "issue tracker" because all 12 files using the standard pattern access the issue tracker (not SC). The only SC-specific MCP check is in scaffold.md Step 0-MCP, which has its own distinct error messages. No SC-specific "Cannot connect to your {Type} repository" variant is needed in the standard pattern.
- **Internal references preserved:** Messages that are internal context (e.g., `Type = {Type from config}. Use the MCP server for {Type}.` in agent dispatch context) are NOT user-facing and should NOT be changed. These are instructions to the agent, not displayed to the user.
- **Block message format:** Block messages are semi-structured (parsed by `/resume-ticket`). The `[ceos-agents]` prefix and field names (Agent, Step, Reason, Detail, Recommendation) must be preserved exactly.

### UXP-4: Resume Override

- **No state.json exists:** Override logic only applies when `state.json` exists with `infrastructure` populated. If there is no state file, normal Step 0-INFRA runs (no change).
- **Downgrade clears detail fields:** When downgrading from `ready` to `later`, clear `tracker_type`, `tracker_instance`, `tracker_project` (or `sc_remote`, `sc_base_branch`) to null. This prevents stale values from being used if the user later upgrades again.
- **Upgrade after downgrade:** If state has `"downgraded"` (from a previous MCP failure) and user provides `--infra tracker:ready`, treat `downgraded → ready` the same as `later → ready`. Re-ask for detail fields, re-run Step 0-MCP.
- **Same values:** If `--infra` values match existing state values (e.g., both already `ready`), display `Infrastructure override: no changes.` and skip re-verification.
- **Partial override:** `--infra` always specifies both tracker and SC (or the shorthand applies to both). There is no partial override (changing only tracker while leaving SC from state). This is by design — the shorthands `ready`/`later` apply to both.

## What NOT to Change

1. **`core/mcp-detection.md`** — This is the shared contract for MCP detection logic. It does not contain user-facing error messages (those are in the calling commands). No changes needed.

2. **Agent files (`agents/*.md`)** — Only `agents/triage-analyst.md` mentions "MCP server" (line 110: "If issue tracker MCP server is unreachable: report error to chat, do not proceed"). This is an agent constraint, not a user-facing error message string. Agents operate in the Task tool context and their error messages are processed by the orchestrating command. Leave unchanged.

3. **`commands/check-setup.md`** — This file uses "MCP server" extensively in its diagnostic output (e.g., "No MCP server configured for tracker type", "Issue tracker MCP server configured"). This is appropriate because `/check-setup` IS the diagnostics tool — users running it expect technical details about their MCP configuration. The term "MCP server" is correct in this context. Leave unchanged.

4. **`commands/init.md`** — Uses "MCP server" in technical context (configuring `.mcp.json`, determining which servers to install). This is appropriate — `/init` is the configuration tool. Leave unchanged.

5. **`commands/fix-ticket.md`** — Lines 123 and 333 use "MCP server for {Type}" in agent dispatch context (passed to triage-analyst and publisher). These are internal instructions, not user-facing. The MCP pre-flight check on line 76 says "Follow `core/mcp-preflight.md`" which delegates to the core contract (updated in UXP-3.8). Leave fix-ticket.md unchanged.

6. **`commands/fix-bugs.md`** — Lines 99 and 321 use "MCP server for {Type}" in agent dispatch context. Same reasoning as fix-ticket.md. The line 80 standard error IS updated (via UXP-3.1). Lines 99 and 321 are left unchanged (internal context, not user-facing).

7. **`commands/onboard.md`** — Line 219 says "Run /ceos-agents:init to configure MCP servers". This is a next-step instruction and "MCP servers" is acceptable here since the user is being directed to the technical `/init` command. Leave unchanged.

8. **`docs/plans/` files** — Historical design documents. No changes (except roadmap.md for status update).

9. **`docs/reference/` files** — Reference documentation uses "MCP server" as a technical term in appropriate context. Leave unchanged.

10. **`examples/` directory** — MCP config examples. Technical context, no changes.

11. **Test files** — `tests/harness/mock-mcp-server.sh` uses "MCP server" in internal script comments. Leave unchanged.

12. **`commands/publish.md` line 24** — `Context: "Type = {Type from config}. Use MCP server for {Type}."` is agent dispatch context (instruction to publisher agent), not a user-facing error. Leave unchanged — only line 15 (the standard error) is updated.
