# Revision 1 Notes — Phase 8 Cycle 0

Date: 2026-04-17
Applied by: Claude Code (surgical revision cycle, Phase 8 → 7)

## Fix Status

| # | Severity | Description | Applied | File |
|---|----------|-------------|---------|------|
| 1 | HIGH | state.json run_id write-back in fix-ticket | YES | `skills/fix-ticket/SKILL.md` |
| 2 | HIGH | state.json run_id write-back in implement-feature | YES | `skills/implement-feature/SKILL.md` |
| 3 | MEDIUM | schema.md RUN-ID table + JSON example updated | YES | `state/schema.md` |
| 4 | MEDIUM | Autopilot `--dangerously-skip-permissions` risk documented | YES | `skills/autopilot/SKILL.md` |
| 5 | MEDIUM | Operator-trust paragraph in CLAUDE.md + config.md | YES | `CLAUDE.md`, `docs/reference/config.md` |
| 6 | MEDIUM | `--proto "=http,https"` restriction added | YES | `core/post-publish-hook.md` |
| 7 | MEDIUM | CHANGELOG `aborted` → `failed` in outcome enum | YES | `CHANGELOG.md` |
| 8 | MEDIUM | CHANGELOG Autopilot key names corrected | YES | `CHANGELOG.md` |

## Before/After Snippets

### Fix 1 — fix-ticket SKILL.md (lines 87-91)

**Before:**
```
Initialize `state.json` ... with `run_id: "{ISSUE-ID}"`. Follow atomic write protocol from `core/state-manager.md`.

**`run_id` generation:** Compute `run_id = "{ISSUE_ID}_{YYYYMMDDTHHMMSSZ}"` ... Store this `run_id` in memory and use it unchanged for the entire run.

**Fire `pipeline-started` webhook:**
```

**After:**
```
Initialize `state.json` ... with `run_id: "{ISSUE-ID}"`. Follow atomic write protocol from `core/state-manager.md`.

**`run_id` generation:** Compute `run_id = "{ISSUE_ID}_{YYYYMMDDTHHMMSSZ}"` ... Store this `run_id` in memory and use it unchanged for the entire run. Write the computed `run_id` back to `.ceos-agents/{ISSUE-ID}/state.json` atomically (overwriting the bare `{ISSUE-ID}` value written at init). Follow atomic write protocol from `core/state-manager.md`. This write-back MUST complete before firing the `pipeline-started` webhook so that `state.json.run_id` matches the webhook `run_id` field.

**Fire `pipeline-started` webhook:**
```

### Fix 2 — implement-feature SKILL.md (lines 89-91)

Same pattern as Fix 1 — identical write-back sentence added after run_id computation.

### Fix 3 — state/schema.md RUN-ID table

**Before:**
```
| Issue tracker pipeline | `ISSUE-ID` | `PROJ-42` |
```
and JSON example:
```json
"run_id": "PROJ-42",
```

**After:**
```
| Issue tracker pipeline | `{ISSUE-ID}_{YYYYMMDDTHHMMSSZ}` | `PROJ-42_20260418T133000Z` |
```
and JSON example:
```json
"run_id": "PROJ-42_20260418T133000Z",
```
(pipeline.log example run_ids also updated: `PROJ-123` → `PROJ-123_20260322T143000Z`)

### Fix 4 — autopilot SKILL.md Security Considerations

Added new `## Security Considerations` section before `## Rules` with:
- `--dangerously-skip-permissions` blast radius explanation
- Containment guidance: dedicated OS user, container/chroot, query auditing, network egress restriction
- Reference to SSRF deferral in v6.9.0

### Fix 4b — autopilot SKILL.md Step 7.3 Log file write

**Before:**
```
2. Lock release is AUTOMATIC via the trap ...
3. Exit codes:
```

**After:**
```
2. Append the run summary to $LOG_FILE (the `Log file` config key, default `.ceos-agents/autopilot.log`). Format: `{ISO8601}|{run_id}|{issues_processed}|{n_success}|{n_block}|{n_error}|{total_tokens}|{total_duration_ms}`. On write failure: log `[autopilot][WARN] Log file not writable: {error}` and continue.
3. Lock release is AUTOMATIC via the trap ...
4. Exit codes:
```

### Fix 5 — CLAUDE.md + docs/reference/config.md operator-trust paragraph

**CLAUDE.md — added after Webhook Payloads paragraph:**
```
**Operator trust required**: The `Webhook URL` value is dispatched via `curl` without scheme or host validation. Operators are responsible for configuring trusted URLs pointing to internal observability endpoints. SSRF defenses (e.g., restricting `file://`/`gopher://` schemes) are deferred to v6.9.0. Per spec design §3.6.
```

**config.md — added before Notifications key table:**
Same paragraph as above.

### Fix 6 — core/post-publish-hook.md curl --proto flag

**Before:**
```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
```

**After (Section 3 + Section 4 example):**
```bash
curl --proto "=http,https" --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
```

Added inline note: "The `--proto "=http,https"` flag restricts the transport to HTTP/HTTPS only, blocking `file://`, `gopher://`, `ftp://`, and other schemes."

### Fix 7 — CHANGELOG.md outcome enum

**Before:**
```
`pipeline-completed` (with `outcome` field: `success`/`blocked`/`aborted`)
```

**After:**
```
`pipeline-completed` (with `outcome` field: `success`/`blocked`/`failed`)
```

### Fix 8 — CHANGELOG.md Autopilot key names

**Before:**
```
7 keys: `Bug query`, `Feature query`, `Max issues per run`, `Max features per run`, `Stop on error`, `Dry run`, `Lock file`
```

**After:**
```
7 keys: `Max issues per run`, `Lock timeout`, `Log file`, `Bug limit`, `Feature limit`, `On error`, `Dry run`. (`Bug query` is read from `### Issue Tracker`; `Feature query` is read from `### Feature Workflow` — neither is an Autopilot-section key.)
```

## Test Harness Results

- **Before revision:** 139/140 (1 FAIL: `ac-v68-doc-version-6.8.0`)
- **After revision:** 139/140 (1 FAIL: `ac-v68-doc-version-6.8.0`)
- **Regression:** None — same pre-existing expected failure (version bump not yet applied via `/ceos-agents:version-bump`)

## Additional Notes

- `core/post-publish-hook.md` `pipeline-completed.outcome` enum was already `success | blocked | failed` (not `aborted`) — Fix 6 confirmed correct, only CHANGELOG needed updating (Fix 7).
- `state/schema.md` pipeline.log example entries (`PROJ-123`) also updated to `PROJ-123_20260322T143000Z` for full consistency within the doc.
- No new agents, no schema_version bump, no config-contract breaking changes introduced.
