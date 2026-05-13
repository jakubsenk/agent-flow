# Phase 2: Research Answers — Final (Synthesized)

## Meta
- Sources merged: agent-1.md, agent-2.md, agent-3.md
- Phase 1 questions reference: `.forge/phase-1-research/final.md`
- Discrepancies: **None.** Agents covered non-overlapping items (1+4+Release, 2+3, 5+6). All values and file citations are internally consistent. One cross-item confirmation: agent-1 independently flagged the `CHANGELOG.md:42` path discrepancy (`examples/config-templates/*` vs actual `examples/configs/`); agent-2 also referenced `examples/configs/` as the real path. Unanimous.
- Scope expansions vs. roadmap phrasing:
  1. **Item 1 — 6 bare templates need a comment block created from scratch** (roadmap implied all 8 had an existing comment block to append to; only 2 do).
  2. **Item 2 — 6 skills are affected** (fix-ticket, fix-bugs, implement-feature, resume-ticket + scaffold implicit; roadmap said "autopilot skill" but autopilot itself does NOT construct `.ceos-agents/{ISSUE-ID}/` — it delegates to fix-ticket/fix-bugs; the gate must be in the receiving skills).
  3. **Item 3 — 3 files need changes, not 1** (roadmap said "post-publish-hook.md"; block-handler.md has a worse pattern (`-d` not heredoc) and docs/guides/autopilot.md has a user-facing gap).
  4. **Item 5 — fix required in core/fixer-reviewer-loop.md BEFORE writing the test** (the test greps for text that does not yet exist; agent has to add it).
  5. **Item 6 — harness is functionally correct today** under plain `bash run-tests.sh`; the bug is a latent `-e` wrapper robustness issue, NOT a functional broken exit. Fix is still warranted (all three `((N++))` expressions).
  6. **CHANGELOG.md:42 path error** — the v6.8.0 Known Issues entry cites `examples/config-templates/*` (nonexistent path); v6.8.1 Fixed entry must use `examples/configs/*`.

---

## Item 1: Config Template Autopilot Rows

### File inventory
Files to edit (all 8):
1. `examples/configs/github-nextjs.md`
2. `examples/configs/github-python-fastapi.md`
3. `examples/configs/github-dotnet.md`
4. `examples/configs/gitea-spring-boot.md`
5. `examples/configs/jira-react.md`
6. `examples/configs/youtrack-python.md`
7. `examples/configs/redmine-rails.md`
8. `examples/configs/redmine-oracle-plsql.md`

Reference files (read-only):
- `docs/reference/config.md` (authoritative key list + defaults)
- `docs/guides/autopilot.md` (canonical 7-row table format model)

### Current-state evidence

**Template structure survey (agent-1 research, all 8 files confirmed):**

| Template | Lines | Has comment block? | Active optional sections? | `### Autopilot` present? |
|----------|---------|--------------------|--------------------------|--------------------------|
| github-nextjs | 1–134 | YES (lines 50–134) | NO | **NO** |
| github-python-fastapi | 1–47 | NO | NO | **NO** |
| github-dotnet | 1–50 | NO | NO | **NO** |
| gitea-spring-boot | 1–47 | NO | NO | **NO** |
| jira-react | 1–46 | NO | NO | **NO** |
| youtrack-python | 1–49 | NO | NO | **NO** |
| redmine-rails | 1–48 | NO | NO | **NO** |
| redmine-oracle-plsql | 1–181 | YES (lines 113–181) | YES (6 active sections) | **NO** |

**`github-nextjs.md` comment block header (verbatim):**
```
> **Uncomment and customize optional sections as needed.**

<!--
```
Optional sections inside block (in order): Build & Test (extended), Retry Limits, Hooks, Custom Agents, Notifications, Worktrees, E2E Test, Error Handling, Extra labels, Feature Workflow, Decomposition, Pipeline Profiles, Metrics.

**`redmine-oracle-plsql.md` comment block (lines 113–181) contains:**
```
### Feature Workflow (optional)
### Hooks (optional)
### Custom Agents (optional)
### Notifications (optional)
### Worktrees (optional)
### E2E Test (optional)
### Browser Verification (optional)
### Extra labels (optional)
### Module Docs (optional)
### Metrics (optional)
```
`### Autopilot` is absent from BOTH the active sections (lines 58–111) AND the comment block (lines 113–181) of `redmine-oracle-plsql.md`.

**Authoritative defaults from `docs/reference/config.md` (lines 26–41, bare table without header):**
```
### Autopilot
| Max issues per run | 1 |
| Lock timeout | 120 |
| Log file | .ceos-agents/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | false |
```

**`docs/guides/autopilot.md:40–51` (canonical template format model):**
```
### Autopilot

| Key | Value |
|-----|-------|
| Max issues per run | 1 |
| Lock timeout | 120 |
| Log file | .ceos-agents/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | true |
```
Note: guide uses `Dry run | true` as a safe-first-run example. The canonical default is `false` (per `docs/reference/config.md` and `CLAUDE.md`). Templates must use `false`.

### Proposed Autopilot row block (canonical)

**For comment-block style (6 bare templates + github-nextjs):**
```markdown
### Autopilot (optional)
| Key | Value |
|-----|-------|
| Max issues per run | 1 |
| Lock timeout | 120 |
| Log file | .ceos-agents/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | false |
```

**For `redmine-oracle-plsql.md` active-section style** (no `(optional)` suffix, consistent with its other active sections):
```markdown
### Autopilot
| Key | Value |
|-----|-------|
| Max issues per run | 1 |
| Lock timeout | 120 |
| Log file | .ceos-agents/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | false |
```

### Per-template insertion notes (8 files)

**1. `examples/configs/github-nextjs.md`**
- Insert `### Autopilot (optional)` block inside the existing `<!--...-->` comment block (lines 50–134).
- Insertion position: AFTER `### Feature Workflow (optional)` and AFTER `### Decomposition (optional)`, at the END of the comment block, before the closing `-->`. Autopilot is the last optional section in CLAUDE.md ordering.
- The block goes after `### Metrics (optional)` (last current entry) and before the closing `-->`.

**2–7. `github-python-fastapi.md`, `github-dotnet.md`, `gitea-spring-boot.md`, `jira-react.md`, `youtrack-python.md`, `redmine-rails.md`**
- These 6 templates have NO optional sections and NO comment block at all. They end after `### Build & Test`.
- Append the full comment block from scratch at the end of each file:
```markdown

> **Uncomment and customize optional sections as needed.**

<!--
### Autopilot (optional)
| Key | Value |
|-----|-------|
| Max issues per run | 1 |
| Lock timeout | 120 |
| Log file | .ceos-agents/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | false |
-->
```

**8. `examples/configs/redmine-oracle-plsql.md`**
- Active sections block ends at line 111 (after `### Error Handling` and `### Decomposition`). Inactive comment block starts at line 113.
- For the ACTIVE section: insert `### Autopilot` (no `(optional)` suffix) after `### Decomposition` (lines 104–111) and before the `> **Uncomment...` comment block divider at line 113. This is where active optional sections live.
- The placement in the active section signals to oracle/redmine users that autopilot is relevant alongside the other active sections.
- Alternatively (simpler): add it to the comment block at the end, after `### Metrics (optional)`. Either is defensible; active-section placement is preferred for consistency with the oracle template's "relevant by default" philosophy.

### Ambiguity resolved: path is `examples/configs/` not `examples/config-templates/`
The v6.8.0 Known Issues entry in `CHANGELOG.md:42` erroneously cites `examples/config-templates/*`. The actual directory is `examples/configs/`. Every Phase 4 and Phase 5 reference to these files must use `examples/configs/`. The v6.8.1 Fixed entry in CHANGELOG should read `examples/configs/*`.

### Test hooks
- Update the test scenario count in `CLAUDE.md` if a new scenario is added for Item 1 (but Item 1 has no new scenario — it is a documentation gap fill only).
- Existing tests: none currently target `examples/configs/` template completeness. A new scenario `v681-config-template-autopilot.sh` could grep all 8 templates for `### Autopilot` — but this is optional scope and Phase 4 should confirm whether to add it.

---

## Item 2: issue_id Regex Gate

### File inventory (6 skills affected + autopilot log path)

Files requiring the gate (prose instruction to validate before path construction):
1. `skills/fix-ticket/SKILL.md` — insertion after line ~87 (`Create .ceos-agents/{ISSUE-ID}/`)
2. `skills/fix-bugs/SKILL.md` — insertion before line ~90 (`For each issue fetched in step 1: create .ceos-agents/{ISSUE-ID}/`)
3. `skills/implement-feature/SKILL.md` — insertion before line ~89 (`Create .ceos-agents/{ISSUE-ID}/`)
4. `skills/resume-ticket/SKILL.md` — insertion before line ~17 (`If .ceos-agents/{ISSUE-ID}/state.json exists`)
5. `skills/autopilot/SKILL.md` — NOTE: autopilot does NOT construct `.ceos-agents/{ISSUE-ID}/` directly; it dispatches to fix-ticket/fix-bugs. No gate needed here. However, autopilot log path (`.ceos-agents/autopilot.log`, config key `Log file`) is operator-controlled, not tracker-derived. Not an attack surface.
6. `core/state-manager.md` — NOT a gate site; the gate belongs in the *skills* that call into state-manager, not in the contract document itself.

Reference files (confirming no existing sanitizer):
- `core/external-input-sanitizer.md` — prompt-injection defense only (purpose: "Prevent prompt injection attacks by clearly marking external content from issue trackers"); does NOT validate issue_id for filesystem path safety.

### Current-state evidence

**Filesystem path construction sites (verbatim, agent-2 research):**

`skills/fix-ticket/SKILL.md:87`:
```
Create `.ceos-agents/{ISSUE-ID}/` directory.
```

`skills/fix-ticket/SKILL.md:89`:
```
Compute `run_id = "{ISSUE_ID}_{YYYYMMDDTHHMMSSZ}"` where the timestamp is the UTC pipeline-start
```

`skills/fix-bugs/SKILL.md:90`:
```
For each issue fetched in step 1: create `.ceos-agents/{ISSUE-ID}/` directory and initialize `state.json`
```

`skills/fix-bugs/SKILL.md:99`:
```
2. Write `run_id` to `.ceos-agents/{ISSUE-ID}/state.json`.
```

`skills/implement-feature/SKILL.md:89`:
```
Create `.ceos-agents/{ISSUE-ID}/` directory. Initialize `state.json`
```

`skills/resume-ticket/SKILL.md:17`:
```
If `.ceos-agents/{ISSUE-ID}/state.json` exists:
```

`state/schema.md:24` (RUN-ID composition):
```
| Issue tracker pipeline | `{ISSUE-ID}_{YYYYMMDDTHHMMSSZ}` | `PROJ-42_20260418T133000Z` |
```

`state/schema.md:287` (tracker_issue_id examples):
```
(e.g., `"PROJ-45"` for YouTrack/Jira, `"#123"` for GitHub/Gitea)
```

`core/external-input-sanitizer.md:1-5` (confirms NOT path sanitization):
```
## Purpose
Prevent prompt injection attacks by clearly marking external content from issue trackers.
```

**No existing allowlist or regex for issue_id anywhere in the codebase.**

### Proposed regex: `^[A-Za-z0-9#_-]+$`

**Per-tracker coverage:**

| Tracker | Format | Example | Matches regex? |
|---------|--------|---------|----------------|
| YouTrack | `PROJ-42` | `PROJ-42` | YES (`[A-Z]`, `-`, `[0-9]`) |
| Jira | `KEY-7` | `AUTH-1` | YES |
| GitHub | `#123` | `#123` | YES (`#` permitted) |
| Gitea | `#123` | `#123` | YES |
| Redmine | integer | `42` | YES (digits only) |
| Linear | `TEAM-123` or UUID | `abc123-def4-...` | YES (`-` + `[a-f0-9]`) |

**Rejected by this regex:** `/`, `\`, `..`, `../`, null byte `\0`, space, `~`, `` ` ``, `$`, `(`, `)`, `>`, `<`, `|`, `"`, `'`, newline. All shell metacharacters and path separators are excluded.

**The `#` inclusion is necessary** for GitHub/Gitea (`#123` per `state/schema.md:287`). The `#` character is safe in filesystem paths on Linux, macOS, and Windows NTFS. It is shell-comment-safe when the variable is always used inside quotes.

### Proposed gate block (verbatim bash/markdown)

This is the EXACT prose block to insert as a numbered step at the earliest point in each skill's Step 0, before any `.ceos-agents/{ISSUE-ID}/` path construction:

```markdown
**issue_id validation (path-traversal defense):** Before constructing any filesystem path from `{ISSUE-ID}`, validate the raw issue ID against the allowlist:

```bash
if ! echo "${ISSUE_ID}" | grep -qE '^[A-Za-z0-9#_-]+$'; then
  echo "[ERROR] issue_id '${ISSUE_ID}' contains disallowed characters. Accepted: [A-Za-z0-9#_-]. Path separators, spaces, and shell metacharacters are not allowed." >&2
  exit 1
fi
```

If validation fails: print to stderr and exit 1 (no state.json written, no lock acquired). Valid examples: `PROJ-42`, `#123`, `AUTH-1`, `42`. Reject examples: `../../etc/passwd`, `foo bar`, `proj$42`, `PROJ/42`.
```

### Per-skill insertion notes

**`skills/fix-ticket/SKILL.md`:** Insert as Step 0b (or equivalent labeled sub-step) in `### 0. MCP pre-flight check`, after the `Follow core/mcp-preflight.md` line and BEFORE the `Create .ceos-agents/{ISSUE-ID}/` line (currently around line 87). The `ISSUE_ID` value at this point is the argument parsed from the skill invocation.

**`skills/fix-bugs/SKILL.md`:** Insert BEFORE the per-issue loop that creates `.ceos-agents/{ISSUE-ID}/` (currently around line 90). The gate runs once per issue_id fetched from the tracker, before the directory-creation loop body. If validation fails for one issue_id, that issue is skipped with an error log; the batch continues (consistent with `On error: skip` semantics).

**`skills/implement-feature/SKILL.md`:** Analogous to fix-ticket — insert in Step 0 before directory creation (around line 89).

**`skills/resume-ticket/SKILL.md`:** Insert before the `If .ceos-agents/{ISSUE-ID}/state.json exists` check (around line 17). The gate prevents both directory traversal reads and malformed path construction on resume.

---

## Item 3: JSON-Encode Payload Interpolation

### File inventory
1. `core/post-publish-hook.md` — Section 4 (lines ~100–111): missing JSON-encoding note
2. `core/block-handler.md` — Step 5 (lines ~40–44): uses `-d '...'` not heredoc — worse pattern
3. `docs/guides/autopilot.md` — lines 228–286: webhook section has no encoding note

### Current-state evidence

**`core/post-publish-hook.md` Section 3 note (line 23, verbatim):**
```
Note: Use a heredoc to pass the JSON body so that special characters (quotes, backslashes)
in variable values do not break the shell command. The `--proto "=http,https"` flag restricts
the transport to HTTP/HTTPS only, blocking `file://`, `gopher://`, `ftp://`, and other schemes.
```

**`core/post-publish-hook.md` Section 4 curl pattern (lines 107–111, verbatim):**
```bash
curl --proto "=http,https" --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  --data-binary @- "${Webhook_URL}" <<EOF
{"event":"pipeline-started","run_id":"${run_id}","issue_id":"${issue_id}","pipeline":"${pipeline}","timestamp":"${ISO8601}"}
EOF
```

**`core/post-publish-hook.md` Section 4 instruction (lines 100–102, verbatim):**
```
### Curl Pattern (identical to Section 3 pr-created)

Transport, curl invocation, and failure handling are identical to Section 3. Use the same
`curl --max-time 5 --retry 0` pattern with a heredoc to pass the JSON body.
```
Section 4 references Section 3 for heredoc safety but does NOT add a JSON-encoding note. Section 3's note covers shell-word-splitting only, not JSON structural safety.

**`core/block-handler.md:40-44` (verbatim — worst exposure site):**
```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"issue-blocked","issue_id":"{issue_id}","agent":"{agent_name}","reason":"{reason}","timestamp":"{ISO8601}"}' \
  "{Webhook URL}"
```
This uses `-d '...'` with single-quoted inline `{variable}` template substitution. The `{reason}` field is agent-generated free-form text ("max 2 sentences") which may contain `"`, `\`, or newlines. Missing: `--proto "=http,https"`, heredoc, JSON-encoding safety.

**`docs/guides/autopilot.md:286` (end of webhook section, verbatim):**
```
Webhook payloads are forward-compatible — additive fields may appear in future MINOR versions.
Use lenient JSON parsing (ignore unknown fields). The `Webhook URL` value is dispatched via `curl`
without scheme/host validation; restrict it to trusted internal endpoints.
```
No JSON-encoding note. No mention of field-value constraints.

**Risk field assessment:**

| Field | Source | Risk without allowlist | Risk with Item 2 gate |
|-------|--------|----------------------|----------------------|
| `issue_id` | Tracker query | HIGH (arbitrary chars) | ELIMINATED (gate ensures `[A-Za-z0-9#_-]`) |
| `run_id` | `{issue_id}_{timestamp}` | HIGH (inherits issue_id risk) | ELIMINATED (if issue_id is safe, run_id is safe) |
| `pipeline` | Skill-internal fixed string | None | None |
| `ISO8601` | Timestamp | None | None |
| `step_name` | Canonical stage key | None (if constrained) | None |
| `outcome` | Enum `success/blocked/failed` | None | None |
| `pr_url` | SCM MCP tool output | MEDIUM (may contain `"` if malformed) | Not eliminated (no allowlist for URLs) |
| `reason` | Agent-generated prose (block-handler) | HIGH (`"`, `\`, newline possible) | Not eliminated |

### Proposed prose insertions (verbatim)

#### Fix 1: `core/post-publish-hook.md` Section 4 — add JSON-encoding note

Insert AFTER the existing "Advisory failure" sentence and BEFORE the closing of the Section 4 Curl Pattern subsection (after line ~102):

```markdown
**Field value safety:** The heredoc prevents shell-word-splitting and glob expansion, but it does NOT
JSON-encode field values. Any field whose value originates from external input (e.g., `issue_id` read
from the tracker, `pr_url` from the SCM) MUST be safe for direct JSON string embedding — free of
`"`, `\`, and control characters. The `issue_id` regex gate (see issue_id validation in skills'
Step 0) ensures `issue_id` and `run_id` contain only `[A-Za-z0-9#_-]` characters and are therefore
safe to interpolate directly. The `pr_url` field in `pipeline-completed` payloads SHOULD be
percent-encoded by the SCM tool before being written to state.json; implementers MUST NOT construct
`pr_url` from raw user-controlled input.
```

#### Fix 2: `core/block-handler.md` Step 5 — convert to heredoc + add encoding note

Replace the current Step 5 curl block entirely:

```markdown
5. **Fire webhook** if config → Notifications → Webhook URL exists and `issue-blocked` is in On events:
   ```bash
   curl --proto "=http,https" --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
     --data-binary @- "${Webhook_URL}" <<EOF
   {"event":"issue-blocked","issue_id":"${issue_id}","agent":"${agent_name}","reason":"${reason_safe}","timestamp":"${ISO8601}"}
   EOF
   ```
   Where `reason_safe` is the `reason` field with `"` escaped as `\"` and `\` escaped as `\\`.
   Use `printf '%s' "${reason}" | jq -Rs .` to produce a safely JSON-encoded string (the result
   includes surrounding `"`; strip them when interpolating inside an existing `"..."` value context).
   The `--proto "=http,https"` flag restricts transport to HTTP/HTTPS only (blocks `file://`, `gopher://`, etc.).
   Advisory failure: log `[WARN] Webhook delivery failed: {error}` and continue pipeline. Never block.
```

#### Fix 3: `docs/guides/autopilot.md` — add encoding note after line 286

Append after the existing `Webhook URL` trust note:

```markdown
**Payload field safety:** Field values interpolated into webhook payloads must be safe for direct JSON
string embedding. The `issue_id` and `run_id` fields are constrained by an allowlist
(`[A-Za-z0-9#_-]`) and are safe to interpolate directly. The `pr_url` field in `pipeline-completed`
events must be a valid percent-encoded URL (as returned by the SCM MCP tool) — do not construct it
from raw user input. If you write a custom post-publish hook that interpolates agent output (e.g.,
`reason` text from a block event), use `jq -Rs .` to JSON-encode the value before embedding it.
```

### Proposed jq example (for reference in Fix 1 or implementer notes)

```bash
# Unsafe — if pr_url could contain double-quotes:
# {"pr_url":"${pr_url}"}  → structurally invalid JSON if pr_url contains "

# Safe — using jq for free-form text fields:
pr_url_json=$(jq -rn --arg v "${pr_url}" '$v')
# then interpolate ${pr_url_json} into the heredoc

# Safe — for reason field in block-handler:
reason_encoded=$(printf '%s' "${reason}" | jq -Rs .)  # produces "\"escaped reason\""
reason_json_value="${reason_encoded:1:-1}"              # strip outer quotes
```

---

## Item 4: Lock-Timeout Alignment

### Finding: 120/125/121 are INTENTIONAL values

All three numeric values are correct and intentional. They are NOT a bug in the implementation — only in the troubleshooting prose of `skills/autopilot/SKILL.md:368`.

**Complete numeric audit (all occurrences confirmed by agent-1):**

| Location | Value | Meaning |
|----------|-------|---------|
| `skills/autopilot/SKILL.md:52` — config key default | `120` | User-facing threshold (what operators configure) |
| `skills/autopilot/SKILL.md:101` — prose explanation | `120` | Same |
| `skills/autopilot/SKILL.md:127` — bash `LOCK_TIMEOUT` | `120` | Runtime variable = config value |
| `skills/autopilot/SKILL.md:128` — bash `LOCK_TIMEOUT_WITH_BUFFER` | `120+5=125` | Primary path: +5 min for NFS/CIFS clock skew |
| `skills/autopilot/SKILL.md:191` — BusyBox fallback `find -mmin` | `+121` | BusyBox path: 120+1 (1-min `-mmin` resolution buffer) |
| `skills/autopilot/SKILL.md:202` — BusyBox error message | `121min` | Same |
| `skills/autopilot/SKILL.md:208` — primary path comparison | `LOCK_TIMEOUT_WITH_BUFFER` (125) | Computed from config |
| `skills/autopilot/SKILL.md:238` — Invariant 6 | "+5 minute buffer" | Prose explaining +5 |
| **`skills/autopilot/SKILL.md:368` — troubleshooting** | **`<120min`** | **INCONSISTENT — should reference effective threshold** |
| `docs/guides/autopilot.md:45` — config table | `120` | User-facing |
| `docs/guides/autopilot.md:350` — auto-recovery note | "120 minutes (plus a 5-minute NFS/CIFS skew buffer)" | Correct — names both |
| `docs/guides/autopilot.md:370` — BusyBox section | `121 minutes` | Correct — names BusyBox path |
| `docs/guides/autopilot.md:373` — BusyBox example | `find -mmin +121` | Correct |

### The one-line inconsistency at `skills/autopilot/SKILL.md:368`

**Current text (verbatim):**
```
- **`[autopilot][ERROR] Another Autopilot run in progress`** → check `.ceos-agents/autopilot.lock/owner.json` for the owning PID and host. If the owning process is gone but the lock is <120min old, wait for stale timeout or manually `rm -rf .ceos-agents/autopilot.lock/` (only after verifying no live process).
```

The phrase `<120min old` is wrong: the actual stale threshold on the primary path is `LOCK_TIMEOUT_WITH_BUFFER` = 125 min, and 121 min on BusyBox. An operator with a 122-minute-old lock would incorrectly believe auto-recovery has fired (since 122 > 120), when in fact on the primary path the lock is NOT yet stale (122 < 125).

The guide (`docs/guides/autopilot.md:350`) is already MORE accurate than SKILL.md on this point. No guide changes are needed.

### Proposed replacement prose

**Replace the SKILL.md:368 sentence fragment `the lock is <120min old` with:**

```
the lock is less than the effective stale threshold (the configured `Lock timeout` value plus a 5-minute NFS/CIFS clock-skew buffer; default: 125 min on primary path, 121 min on BusyBox fallback)
```

**Full replacement line (verbatim):**
```
- **`[autopilot][ERROR] Another Autopilot run in progress`** → check `.ceos-agents/autopilot.lock/owner.json` for the owning PID and host. If the owning process is gone but the lock is less than the effective stale threshold (the configured `Lock timeout` value plus a 5-minute NFS/CIFS clock-skew buffer; default: 125 min on primary path, 121 min on BusyBox fallback), wait for stale auto-recovery or manually `rm -rf .ceos-agents/autopilot.lock/` (only after verifying no live process).
```

---

## Item 5: Fixer-Reviewer Crash-Recovery Regression Test

### Finding: `core/fixer-reviewer-loop.md` Step 10 lacks cumulative-tokens prose

**Current `core/fixer-reviewer-loop.md` Step 10 (line 28, verbatim):**
```
10. After each iteration, update state.json: increment `fixer_reviewer.iterations`, set `fixer_reviewer.last_verdict`, update `fixer_reviewer.ac_fulfillment` from reviewer AC Fulfillment section, set `fixer_reviewer.status` to `"in_progress"`. Follow atomic write protocol from `core/state-manager.md`.
```

**Critical gap:** No mention of `tokens_used`, `duration_ms`, or `tool_uses` accumulation. The cumulative semantics exist in two other files but NOT in the loop contract:

`state/schema.md:344` (already present — correct):
```
`fixer_reviewer.tokens_used`, `fixer_reviewer.duration_ms`, and `fixer_reviewer.tool_uses` are **cumulative across all iterations**, not per-iteration snapshots. After iteration N completes, these fields hold the running sum of all N iterations combined (e.g., after 3 iterations: `tokens_used = iter1 + iter2 + iter3`). No per-iteration breakdown array is stored in state.json — that granularity is available in `pipeline.log` via `fixer_iteration` events.
```

`core/state-manager.md:138-148` (already present — correct):
```
The `fixer_reviewer` stage accumulates token counts cumulatively across iterations (COST-R5). After each fixer or reviewer invocation within the loop:
  fixer_reviewer.tokens_used  += iteration_tokens_used   (running total)
  fixer_reviewer.duration_ms  += iteration_duration_ms
  fixer_reviewer.tool_uses    += iteration_tool_uses
No per-iteration breakdown array is persisted.
```

`state/schema.md:465-466` (atomic write protocol — already present):
```
On rename failure: retry once after 100 ms. On second failure: log to `pipeline.log` and continue (state loss is non-fatal).
```

### Proposed prose addition to `core/fixer-reviewer-loop.md` Step 10

**Full replacement for line 28 (verbatim):**
```markdown
10. After each iteration, update state.json atomically (see `core/state-manager.md` atomic write protocol): increment `fixer_reviewer.iterations`, set `fixer_reviewer.last_verdict`, update `fixer_reviewer.ac_fulfillment` from reviewer AC Fulfillment section, set `fixer_reviewer.status` to `"in_progress"`, and accumulate usage fields: `fixer_reviewer.tokens_used += iteration_tokens_used`, `fixer_reviewer.duration_ms += iteration_duration_ms`, `fixer_reviewer.tool_uses += iteration_tool_uses`. These cumulative writes ensure that if the pipeline crashes mid-loop, the state.json reflects the token cost of all completed iterations and can be used for cost reporting on resume.
```

Key additions vs. current:
- The explicit `+=` accumulation for all three token fields
- The crash-recovery semantics sentence (the word "crash" is the grep target for the new scenario)

### Proposed scenario file name and outline

**Filename:** `tests/scenarios/v681-fixer-reviewer-crash-recovery.sh`

Follows the PATCH-version prefix convention: `v644-diagnostics-hardening.sh` → `v681-fixer-reviewer-crash-recovery.sh` (digits only, no `ac-` prefix). The `ac-v68-` prefix is for minor-version AC tests.

### Verbatim scenario skeleton (from existing templates)

The scenario uses the `ac-v68-cost-fixer-reviewer-cumulative.sh` pattern (which already covers the nearest related test):

```bash
#!/usr/bin/env bash
# Test: v6.8.1 Fixer-reviewer crash-recovery — cumulative tokens_used written per iteration
# Validates: core/fixer-reviewer-loop.md Step 10 documents tokens_used accumulation per-iteration
#            and that crash-mid-loop preserves completed-iteration cost data
# Traces: COST-R5 (cumulative), state-manager atomic write protocol
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

LOOP_CONTRACT="$REPO_ROOT/core/fixer-reviewer-loop.md"
STATE_MANAGER="$REPO_ROOT/core/state-manager.md"
SCHEMA="$REPO_ROOT/state/schema.md"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Guard: required files exist
for f in "$LOOP_CONTRACT" "$STATE_MANAGER" "$SCHEMA"; do
  if [ ! -f "$f" ]; then
    echo "FAIL: required file not found: $f"
    exit 1
  fi
done

# --- Assertion 1: core/fixer-reviewer-loop.md Step 10 documents tokens_used accumulation ---
# After the fix, Step 10 must instruct the loop to accumulate tokens_used per iteration.
if ! grep -qE 'tokens_used.*iteration|iteration.*tokens_used' "$LOOP_CONTRACT"; then
  fail "core/fixer-reviewer-loop.md Step 10 does not document per-iteration tokens_used accumulation (+=)"
fi

# --- Assertion 2: core/fixer-reviewer-loop.md mentions crash-recovery semantics ---
# The fix adds a sentence about partial crash preserving completed-iteration cost data.
if ! grep -qiE 'crash|partial.*failure.*preserv|preserv.*partial' "$LOOP_CONTRACT"; then
  fail "core/fixer-reviewer-loop.md does not document crash-recovery semantics for cumulative tokens_used"
fi

# --- Assertion 3: state/schema.md already documents cumulative semantics ---
if ! grep -qiE 'cumulative|cumulat' "$SCHEMA"; then
  fail "state/schema.md does not document cumulative accumulation for fixer_reviewer (must be present)"
fi

# --- Assertion 4: core/state-manager.md already documents cumulative += write ---
if ! grep -qE 'tokens_used.*running total|cumulatively across iterations' "$STATE_MANAGER"; then
  fail "core/state-manager.md does not document cumulative running-total write for fixer_reviewer"
fi

# --- Negative: no per-iteration breakdown array in loop contract or schema ---
for file in "$LOOP_CONTRACT" "$SCHEMA"; do
  if grep -qE 'iteration_breakdown|per_iteration|iterations_detail' "$file"; then
    fail "$(basename "$file") contains per-iteration breakdown array language (must be absent)"
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: v6.8.1 fixer-reviewer crash-recovery — cumulative tokens_used documented per-iteration with crash-recovery semantics"
exit "$FAIL"
```

**Important sequence constraint:** The scenario WILL FAIL until `core/fixer-reviewer-loop.md` Step 10 is patched (Assertions 1 and 2 will fail on current HEAD). Phase 4 must patch the loop contract BEFORE writing the scenario, or ensure the scenario is added in the same commit as the loop contract fix.

---

## Item 6: Test Harness Exit-Code Propagation

### Finding: `run-tests.sh` works under `bash`, breaks under `bash -e`

**Full harness file:** `tests/harness/run-tests.sh` (69 lines)

**`set` flags (line 5):** `set -uo pipefail` — NO `-e` flag.

**Correct assessment:** The harness exit-code path IS functionally correct under `bash run-tests.sh`. Lines 66–68 correctly exit 1 when `FAIL > 0`. The roadmap item is about LATENT ROBUSTNESS, not a current functional bug.

### Root cause: `((FAIL++))` returns exit 1 when FAIL=0

**The arithmetic exit-code issue (confirmed by agent-3):**
- When `FAIL=0`, `((FAIL++))` post-increments → expression value = 0 (the pre-increment value) = false → shell returns exit code 1 from the arithmetic command.
- Under `set -uo pipefail` (no `-e`): the exit code 1 is swallowed, FAIL becomes 1, script continues normally. **Harness currently works.**
- Under strict CI wrappers (`bash -e run-tests.sh` or wrapping shell with `set -e`): the first `((FAIL++))` when FAIL=0 causes premature abort → summary line never printed, proper `exit 1` at line 67 never reached. Script exits nonzero but from the wrong site.
- Same issue: `((PASS++))` when PASS=0 → exit code 1 from arithmetic expression. Under `-e`: even a first-passing scenario would abort the harness early.

**Lines affected (verbatim current):**
```bash
# Line 42 (PASS branch):
((PASS++))

# Line 48 (SKIP branch):
((SKIP++))

# Line 52 (FAIL branch):
((FAIL++))
```

### Proposed fix (verbatim shell)

Replace all three post-increment expressions with POSIX-safe assignment forms:

```bash
# Line 42 — PASS increment:
PASS=$((PASS + 1))

# Line 48 — SKIP increment:
SKIP=$((SKIP + 1))

# Line 52 — FAIL increment:
FAIL=$((FAIL + 1))
```

`$((N + 1))` always evaluates to a non-negative integer; the assignment command returns exit 0 regardless of the arithmetic result. The exit-code ambiguity is eliminated completely for all three branches.

### Proposed meta-test scenario

**Filename:** `tests/scenarios/ac-v681-harness-exit-propagation.sh`

Uses `ac-v681-` prefix (not `v681-`) because this is an acceptance-criteria static check for the v6.8.1 fix, following the `ac-v68-*` convention used for v6.8.0 AC tests.

```bash
#!/usr/bin/env bash
# Test: v6.8.1 — Harness exit-code propagation
# Validates: run-tests.sh uses $((N + 1)) form for PASS/FAIL/SKIP increments
#            (safe under bash -e wrappers; ((N++)) returns exit 1 when N=0)
# Functional: single-scenario mode exits nonzero on failure
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
HARNESS="$REPO_ROOT/tests/harness/run-tests.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Guard
if [ ! -f "$HARNESS" ]; then
  echo "FAIL: run-tests.sh not found at $HARNESS"
  exit 1
fi

# --- Assertion 1: FAIL increment uses safe $((FAIL + 1)) form ---
if grep -qE '\(\(FAIL\+\+\)\)' "$HARNESS"; then
  fail "run-tests.sh still uses ((FAIL++)) — replace with FAIL=\$((FAIL + 1)) to avoid exit-code 1 leak under bash -e wrappers"
fi

# --- Assertion 2: PASS increment uses safe form ---
if grep -qE '\(\(PASS\+\+\)\)' "$HARNESS"; then
  fail "run-tests.sh still uses ((PASS++)) — replace with PASS=\$((PASS + 1)) to avoid exit-code 1 leak under bash -e wrappers"
fi

# --- Assertion 3: SKIP increment uses safe form ---
if grep -qE '\(\(SKIP\+\+\)\)' "$HARNESS"; then
  fail "run-tests.sh still uses ((SKIP++)) — replace with SKIP=\$((SKIP + 1)) to avoid exit-code 1 leak under bash -e wrappers"
fi

# --- Assertion 4: Functional — single-scenario mode exits nonzero on failure ---
TMPNAME="v681-meta-test-always-fail-$$"
TMPSCEN="$REPO_ROOT/tests/scenarios/$TMPNAME.sh"
printf '#!/usr/bin/env bash\nexit 1\n' > "$TMPSCEN"
chmod +x "$TMPSCEN"

bash "$HARNESS" "$TMPNAME" > /dev/null 2>&1
harness_exit=$?
rm -f "$TMPSCEN"

if [ "$harness_exit" -eq 0 ]; then
  fail "run-tests.sh single-scenario mode exited 0 for a failing scenario (exit-code propagation broken)"
else
  echo "OK: single-scenario mode correctly exits nonzero ($harness_exit) on failure"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: v6.8.1 harness exit-code propagation — safe increments and nonzero exit on failure"
exit "$FAIL"
```

**Note:** Assertion 4 uses single-scenario mode (`bash run-tests.sh <name>`) to avoid SCENARIOS_DIR override complexity. It creates a temporary failing scenario in the actual scenarios dir, runs it, and removes it. The `$$` suffix ensures no collision with other scenarios.

---

## Release Process

### CHANGELOG v6.8.1 structure (draft)

**v6.8.0 reference structure (lines 10–46, agent-1 research):**
```
## [6.8.0] — 2026-04-17
### Added
### Changed
### Migration notes
### Known Issues (deferred to v6.8.1)
### Internal
```

**Known Issues verbatim (CHANGELOG.md:41–42):**
```
### Known Issues (deferred to v6.8.1)
- **`examples/config-templates/*`** — Autopilot section not yet added per template. Operators can copy from `docs/reference/config.md`.
```
(Path `examples/config-templates/*` is wrong — actual path is `examples/configs/*`.)

**Proposed v6.8.1 CHANGELOG entry:**

```markdown
## [6.8.1] — 2026-04-18

**PATCH** — Config template completeness, lock-timeout prose alignment, fixer-reviewer crash-recovery contract, test harness robustness, payload encoding documentation.

### Fixed
- **`examples/configs/*`** — `### Autopilot` section (7 keys, commented-out) added to all 8 config templates. Closes Known Issue from v6.8.0. (Note: v6.8.0 Known Issues cited `examples/config-templates/*` — corrected path is `examples/configs/*`.)
- **`skills/autopilot/SKILL.md:368`** — Troubleshooting prose corrected: `<120min old` replaced with effective stale threshold reference (120 + 5 min NFS/CIFS buffer = 125 min primary path; 121 min BusyBox fallback). Consistent with `docs/guides/autopilot.md:350`.
- **`skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/resume-ticket/SKILL.md`** — issue_id regex gate (`^[A-Za-z0-9#_-]+$`) added before all `.ceos-agents/{ISSUE-ID}/` filesystem path constructions. Prevents path-traversal via malformed tracker issue IDs.
- **`core/post-publish-hook.md` Section 4, `core/block-handler.md` Step 5** — JSON-encoding safety note added for heredoc payloads. `core/block-handler.md` Step 5 converted from `-d '...'` to `--data-binary @-` heredoc; `--proto "=http,https"` flag added. `docs/guides/autopilot.md` webhook section updated with user-facing field safety note.
- **`core/fixer-reviewer-loop.md` Step 10** — Token accumulation (`tokens_used += iteration_tokens_used` etc.) added to per-iteration state.json write instruction. Crash-recovery semantics documented: cumulative writes preserve completed-iteration cost on mid-loop pipeline crash.
- **`tests/harness/run-tests.sh`** — `((PASS++))`, `((SKIP++))`, `((FAIL++))` replaced with `PASS=$((PASS + 1))` etc. — eliminates spurious exit-code 1 from arithmetic expressions under `bash -e` CI wrappers.

### Internal
- New test scenarios: `v681-fixer-reviewer-crash-recovery.sh`, `ac-v681-harness-exit-propagation.sh` (+2 scenarios; total: 142)
```

**Notes:**
- No `### Added` section (no new features).
- No `### Changed` section (optional config sections remain at 18; skills remain at 29).
- No `### Known Issues` section (the v6.8.0 known issue is closed by this release).
- `### Fixed` is the primary section.
- Scenario count: if 2 new scenarios added, total becomes 142 (was 140 per v6.8.0 commit summary).

### Commit sequence (from memory + version-bump SKILL.md evidence)

**`skills/version-bump/SKILL.md` pre-flight guards (verbatim, agent-1 research):**

Step 6 (CHANGELOG guard):
```
6. **CHANGELOG guard:** Read `CHANGELOG.md` and verify it contains a heading `## [{new_version}]` (where `{new_version}` is the version about to be set). If not found → error: "CHANGELOG.md has no entry for {new_version}. Add a changelog entry before bumping."
```

Step 7 (Uncommitted changes guard):
```
7. **Uncommitted changes guard:** Run `git status`. If there are uncommitted changes (staged or unstaged, excluding `.claude/settings.local.json`) → error: "Uncommitted changes detected. Commit content changes before version-bump."
```

**Required commit sequence:**
1. **Content commit** — all file changes (Items 1–6) + `CHANGELOG.md` entry for `[6.8.1]`. The `## [6.8.1]` heading MUST exist in CHANGELOG before step 2.
2. **Version-bump commit** — run `/ceos-agents:version-bump patch` → writes `plugin.json` + `marketplace.json`, commits `chore: bump version 6.8.0 → 6.8.1`, creates tag `v6.8.1`.

Version-bump does NOT touch `CHANGELOG.md`. Step 6 of version-bump enforces that the CHANGELOG entry was authored by the human in the content commit.

---

## Overall Scope Summary

### Files to edit: 14
1. `examples/configs/github-nextjs.md` — Item 1
2. `examples/configs/github-python-fastapi.md` — Item 1
3. `examples/configs/github-dotnet.md` — Item 1
4. `examples/configs/gitea-spring-boot.md` — Item 1
5. `examples/configs/jira-react.md` — Item 1
6. `examples/configs/youtrack-python.md` — Item 1
7. `examples/configs/redmine-rails.md` — Item 1
8. `examples/configs/redmine-oracle-plsql.md` — Item 1
9. `skills/autopilot/SKILL.md` — Item 4 (1 line, line 368)
10. `skills/fix-ticket/SKILL.md` — Item 2
11. `skills/fix-bugs/SKILL.md` — Item 2
12. `skills/implement-feature/SKILL.md` — Item 2
13. `skills/resume-ticket/SKILL.md` — Item 2
14. `core/fixer-reviewer-loop.md` — Item 5 (Step 10, line 28)
15. `core/post-publish-hook.md` — Item 3 (Section 4 note)
16. `core/block-handler.md` — Item 3 (Step 5 rewrite)
17. `docs/guides/autopilot.md` — Item 3 (1 paragraph after line 286)
18. `tests/harness/run-tests.sh` — Item 6 (3 lines: 42, 48, 52)
19. `CHANGELOG.md` — Release

**Total: 19 files to edit**

### Files to add: 2
1. `tests/scenarios/v681-fixer-reviewer-crash-recovery.sh` — Item 5
2. `tests/scenarios/ac-v681-harness-exit-propagation.sh` — Item 6

### Lines of change estimate
- Item 1: 8 templates × ~12 lines each = ~96 lines added (6 new comment blocks, 2 insertions)
- Item 2: 4 skills × ~8 lines each = ~32 lines added
- Item 3: 3 files × ~8 lines each = ~24 lines changed
- Item 4: 1 line changed (SKILL.md:368)
- Item 5: 1 line changed (core/fixer-reviewer-loop.md) + ~35 lines new scenario
- Item 6: 3 lines changed (run-tests.sh) + ~40 lines new scenario
- CHANGELOG: ~25 lines added
- **Total: ~256 lines added/changed across 21 files**

### Risk flags for Phase 4
1. **Item 1 — 6 bare templates need a comment block created from scratch** (not just an append). Must match `github-nextjs.md` structure exactly (`> **Uncomment...` divider + `<!--...-->`).
2. **Item 2 — gate location in fix-bugs.md is inside a per-issue loop** (validation must run per issue_id, not once globally; error handling must be `skip` not `stop` to match batch semantics).
3. **Item 3 — block-handler.md Step 5 is a full rewrite** (not just an additive note). The existing `-d '...'` pattern is replaced with heredoc. Test suite should verify the new pattern is present.
4. **Item 5 — scenario cannot be committed before core/fixer-reviewer-loop.md is patched** (Assertions 1 and 2 will fail on unpatched HEAD). Order of changes within the content commit matters.
5. **Item 6 — Assertion 4 in the meta-test writes a temp file to `tests/scenarios/`** during test execution. This is safe but unconventional; if the test suite is run in a read-only environment, Assertion 4 will fail. Phase 4 spec should decide whether to include or omit Assertion 4.
6. **CHANGELOG path correction** — the v6.8.0 Known Issues cites `examples/config-templates/*` (wrong). The v6.8.1 Fixed entry must cite `examples/configs/*`. Do not copy the wrong path.
