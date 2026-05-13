# Phase 2 Research Answers — Agent 2
## Focus: Item 2 (issue_id regex / path-traversal) + Item 3 (JSON-encode payload docs)

---

## Item 2: issue_id Regex Gate (Path-Traversal Defense)

### Q2.1: Exact path-construction sites — where is issue_id used raw in a filesystem path?

**Evidence — every `.ceos-agents/{...}/` directory creation site in skills/:**

All six primary skills use `{ISSUE-ID}` directly in filesystem paths. Verbatim lines:

**`skills/fix-ticket/SKILL.md:87`**
```
Create `.ceos-agents/{ISSUE-ID}/` directory.
```

**`skills/fix-ticket/SKILL.md:89`**
```
Compute `run_id = "{ISSUE_ID}_{YYYYMMDDTHHMMSSZ}"` where the timestamp is the UTC pipeline-start
```

**`skills/fix-bugs/SKILL.md:90`**
```
For each issue fetched in step 1: create `.ceos-agents/{ISSUE-ID}/` directory and initialize `state.json`
```

**`skills/fix-bugs/SKILL.md:99`**
```
2. Write `run_id` to `.ceos-agents/{ISSUE-ID}/state.json`.
```

**`skills/fix-bugs/SKILL.md:358`**
```
- Create `.ceos-agents/{ISSUE-ID}/` directory before running the agent.
```

**`skills/implement-feature/SKILL.md:89`**
```
Create `.ceos-agents/{ISSUE-ID}/` directory. Initialize `state.json`
```

**`skills/resume-ticket/SKILL.md:17`**
```
If `.ceos-agents/{ISSUE-ID}/state.json` exists:
```

Screenshot storage path (from `skills/fix-ticket/SKILL.md:55` and `skills/fix-bugs/SKILL.md:50`):
```
Screenshot storage (default: `.ceos-agents/{ISSUE-ID}/screenshots`)
```

Reproduction-result path (from `skills/fix-ticket/SKILL.md:296`):
```
pass full `.ceos-agents/{ISSUE-ID}/reproduction-result.json` content to fixer
```

**`core/state-manager.md:5`** (Purpose section):
```
Read, write, and resume contract for `.ceos-agents/{RUN-ID}/state.json`.
```

**`core/state-manager.md:23`** (Write Process step 1):
```
1. Read current state from `.ceos-agents/{RUN-ID}/state.json`
```

**`core/state-manager.md:167`** (Failure Handling):
```
- **Missing directory:** Create `.ceos-agents/{RUN-ID}/` on first write.
```

**`state/schema.md:24`** (RUN-ID Determination):
```
| Issue tracker pipeline | `{ISSUE-ID}_{YYYYMMDDTHHMMSSZ}` | `PROJ-42_20260418T133000Z` |
```

**`state/schema.md:287`** (tracker_issue_id examples):
```
(e.g., `"PROJ-45"` for YouTrack/Jira, `"#123"` for GitHub/Gitea)
```

**Autopilot log path** (`skills/autopilot/SKILL.md:317`):
```
Append the run summary to `$LOG_FILE` (the `Log file` config key, default `.ceos-agents/autopilot.log`).
```

**Autopilot log path format** (`skills/autopilot/SKILL.md:319`):
```
{ISO8601}|{run_id}|{issues_processed}|{n_success}|{n_block}|{n_error}|{total_tokens}|{total_duration_ms}
```

**Observation:** The autopilot log file path is operator-configured (`Log file` key) — it does NOT use `{ISSUE-ID}` in the path itself. However, the log LINE written to that path contains `{run_id}` = `autopilot-{YYYYMMDDTHHMMSSZ}`. The per-issue child state paths DO use `{ISSUE-ID}` raw (via `fix-ticket` / `fix-bugs` / `implement-feature`). The earliest attack surface is in `fix-ticket/SKILL.md` step 0 and `fix-bugs/SKILL.md` step 0 where `{ISSUE-ID}` is used to construct `.ceos-agents/{ISSUE-ID}/`.

**Per `core/state-manager.md:23,167`:** The `{RUN-ID}` = `{ISSUE-ID}_{timestamp}` (e.g., `PROJ-42_20260418T133000Z`). So the actual directory created is `.ceos-agents/PROJ-42_20260418T133000Z/`. Both the `ISSUE-ID` component AND the full `RUN-ID` must be safe.

**No existing regex/allowlist exists for issue_id.** Confirmed: `core/external-input-sanitizer.md` exists but only handles prompt-injection via boundary markers — it performs NO filesystem-path sanitization. There is zero regex validation of `issue_id` anywhere in the plugin.

---

### Q2.2: Per-tracker issue ID character sets

Evidence from `state/schema.md:287`:
```
`"PROJ-45"` for YouTrack/Jira, `"#123"` for GitHub/Gitea
```

From state/schema.md RUN-ID table (line 24):
```
`PROJ-42_20260418T133000Z`
```

**Per-tracker character set analysis:**

| Tracker | Format | Example | Characters used |
|---------|--------|---------|-----------------|
| YouTrack | `PROJ-42` | `PROJ-42` | `[A-Z]`, `-`, `[0-9]` |
| Jira | `KEY-7` | `AUTH-1` | `[A-Z]`, `-`, `[0-9]` |
| GitHub | `#123` | `#123` | `#`, `[0-9]` |
| Gitea | `#123` | `#123` | `#`, `[0-9]` |
| Redmine | integer | `42` | `[0-9]` |
| Linear | `TEAM-123` or UUID | `AUTH-1` | `[A-Z]`, `-`, `[0-9]` (or UUID hex + `-`) |

**The `#` character is the highest-risk char:** In bash it begins a comment. On some filesystems it is valid but causes issues in URLs, makefiles, and some tools. It appears in GitHub/Gitea IDs in state/schema.md examples.

**No existing allowlist or regex is defined anywhere in the codebase.** The `core/external-input-sanitizer.md` is for prompt-injection defense, not path sanitization.

**Proposed conservative allowlist regex:**

```
^[A-Za-z0-9#_-]+$
```

Evaluation per tracker:
- YouTrack `PROJ-42` → matches (uppercase + `-` + digits)
- Jira `KEY-7` → matches
- GitHub `#123` → matches (`#` is permitted)
- Gitea `#123` → matches
- Redmine `42` → matches (digits only)
- Linear `TEAM-123` → matches; Linear UUIDs (`abc123-def4-...`) → matches (`-` + `[a-f0-9]`)

**Rejected by this regex:** `/`, `\`, `..`, `../`, null byte `\0`, space, `~`, `` ` ``, `$`, `(`, `)`, `>`, `<`, `|`, newline.

**The `#` inclusion is necessary** because GitHub/Gitea issue IDs start with `#`. However `#` is safe in filesystem paths on Linux, macOS, and Windows NTFS. It is shell-comment-safe because the issue_id is always used inside quotes in the skill pseudocode.

**Proposed validation gate block — draft verbatim:**

Location: Insert at the START of every skill's Step 0 / MCP preflight section, immediately after parsing `ISSUE_ID` from the skill argument and BEFORE constructing any `.ceos-agents/{ISSUE-ID}/` path. In `fix-ticket/SKILL.md` this is around line 87; in `fix-bugs/SKILL.md` around line 90.

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

**Exact insertion point for `skills/fix-ticket/SKILL.md`:** After the frontmatter and before line 87 (the `Create .ceos-agents/{ISSUE-ID}/ directory` instruction) — i.e., as the FIRST action of `### 0. MCP pre-flight check`, after the `Follow core/mcp-preflight.md` line but before the `Create .ceos-agents/{ISSUE-ID}/` line.

**Exact insertion point for `skills/fix-bugs/SKILL.md`:** After line 87 (MCP check prose) and before line 90 (`For each issue fetched in step 1: create .ceos-agents/{ISSUE-ID}/`). The validation runs once per issue_id before the directory creation loop body.

**Exact insertion point for `skills/implement-feature/SKILL.md`:** Analogous to fix-ticket — Step 0 before directory creation on line 89.

**Does `core/state-manager.md` need the gate?** The state-manager is a contract document, not an imperative skill. It defines the write path as `.ceos-agents/{RUN-ID}/state.json` without executing bash. The gate belongs in the *skills* that call into state-manager, not in state-manager itself.

---

## Item 3: JSON-Encode Payload Interpolation Docs

### Q3.1: Section 3 vs Section 4 documentation gap in core/post-publish-hook.md

**Evidence — Section 3 note (line 23):**
```
Note: Use a heredoc to pass the JSON body so that special characters (quotes, backslashes)
in variable values do not break the shell command. The `--proto "=http,https"` flag restricts
the transport to HTTP/HTTPS only, blocking `file://`, `gopher://`, `ftp://`, and other schemes.
```

**Evidence — Section 4 curl pattern (lines 107-111):**
```bash
curl --proto "=http,https" --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  --data-binary @- "${Webhook_URL}" <<EOF
{"event":"pipeline-started","run_id":"${run_id}","issue_id":"${issue_id}","pipeline":"${pipeline}","timestamp":"${ISO8601}"}
EOF
```

**Section 4 instruction (lines 100-102):**
```
### Curl Pattern (identical to Section 3 pr-created)

Transport, curl invocation, and failure handling are identical to Section 3. Use the same
`curl --max-time 5 --retry 0` pattern with a heredoc to pass the JSON body.
```

**The gap:** Section 4 says "Use the same ... pattern with a heredoc" and references Section 3's transport note. However, Section 3's note only says "heredoc ... so that special characters (quotes, backslashes) in variable values do not break the shell command." This covers SHELL quoting safety but does NOT state that field values must be JSON-encoded. If `${issue_id}` = `PROJ"42` (double-quote in tracker data), the heredoc does NOT prevent shell breakage (heredoc expands variables without shell parsing), but it DOES cause JSON structural corruption — the resulting payload `{"issue_id":"PROJ"42"}` is invalid JSON.

**Affected variables in Section 4 interpolations:**
- `${run_id}` — format `{ISSUE-ID}_{YYYYMMDDTHHMMSSZ}`, if issue_id gate is in place this is safe via allowlist; if not, arbitrary
- `${issue_id}` — raw from tracker query result, no validation currently
- `${pipeline}` — skill-internal string (fixed values: `fix-ticket`, `fix-bugs`, etc.), safe
- `${ISO8601}` — timestamp string, safe
- `${step_name}` — canonical stage key (e.g., `fixer_reviewer`), safe if constrained
- `${outcome}` — enum string (`success`, `blocked`, `failed`), safe
- `${pr_url}` — URL from tracker/GitHub, may contain `"` if malformed
- `${duration}` — integer, safe
- `${iteration_count}` — integer, safe

**Highest-risk fields:** `issue_id` (free-form tracker data), `pr_url` (URL from external system). If the issue_id allowlist gate (Item 2) is implemented, `issue_id` risk is eliminated. But `pr_url` in `pipeline-completed` events can contain arbitrary characters from GitHub/GitLab.

### Q3.2: block-handler.md gap

**Evidence — `core/block-handler.md:40-44`:**
```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"issue-blocked","issue_id":"{issue_id}","agent":"{agent_name}","reason":"{reason}","timestamp":"{ISO8601}"}' \
  "{Webhook URL}"
```

**Critical finding:** `core/block-handler.md` Step 5 uses `-d '...'` with single-quoted inline string substitution — NOT a heredoc. The `{reason}` field is "max 2 sentences" of agent-generated text that may contain single quotes, double quotes, newlines, or JSON metacharacters. The `{issue_id}` is raw tracker data.

This is a **second exposure site** with a different and worse pattern: single-quoted `-d` with literal `{variable}` template notation. The surrounding single quotes prevent shell variable expansion but the template syntax `{reason}` means the skill is expected to substitute the actual value in — and if `{reason}` contains `"` or `\`, the resulting JSON is structurally invalid.

This block-handler issue predates v6.8.0 (it is the existing `issue-blocked` event from Section 3's `On events` list).

### Q3.3: docs/guides/autopilot.md gap

**Evidence — `docs/guides/autopilot.md:228-286`** (lines read above):

The autopilot guide shows all three Section 4 payload examples (`pipeline-started`, `step-completed`, `pipeline-completed`) as static JSON blocks with literal example values, not bash heredoc. The guide has **no encoding note** — no mention of JSON-encoding, heredoc safety, or field-value constraints. The only note at line 286 is:
```
Webhook payloads are forward-compatible — additive fields may appear in future MINOR versions.
Use lenient JSON parsing (ignore unknown fields). The `Webhook URL` value is dispatched via `curl`
without scheme/host validation; restrict it to trusted internal endpoints.
```

No JSON-encoding or field-value safety note exists in the guide. This is a user-facing documentation gap.

---

### Draft Fix Text

#### Fix for `core/post-publish-hook.md` Section 4

**Insertion point:** Lines 100-102, the "Curl Pattern" subsection. After the existing text ending with "Advisory failure: log `[WARN] Webhook delivery failed: {error}` and continue pipeline. Never block." — add a new paragraph:

```markdown
**Field value safety:** The heredoc prevents shell-word-splitting and glob expansion, but it does NOT
JSON-encode field values. Any field whose value originates from external input (e.g., `issue_id` read
from the tracker, `pr_url` from the SCM) MUST be safe for direct JSON string embedding — free of
`"`, `\`, and control characters. The `issue_id` regex gate (see `core/config-reader.md`) ensures
`issue_id` and `run_id` contain only `[A-Za-z0-9#_-]` characters and are therefore safe to interpolate
directly. The `pr_url` field in `pipeline-completed` payloads SHOULD be percent-encoded by the SCM
tool before being written to state.json; implementers MUST NOT construct `pr_url` from raw
user-controlled input. If a field value cannot be guaranteed safe, use `jq -rn --arg v "${value}" '$v'`
to produce a properly JSON-encoded string:

```bash
# Unsafe (if pr_url could contain double-quotes):
# {"pr_url":"${pr_url}"}

# Safe alternative using jq:
pr_url_json=$(jq -rn --arg v "${pr_url}" '$v')
# then interpolate ${pr_url_json} into the heredoc
```
```

#### Fix for `core/block-handler.md` Step 5

Replace the current `-d '...'` pattern with a heredoc and add the encoding note:

```markdown
5. **Fire webhook** if config → Notifications → Webhook URL exists and `issue-blocked` is in On events:
   ```bash
   curl --proto "=http,https" --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
     --data-binary @- "{Webhook URL}" <<EOF
   {"event":"issue-blocked","issue_id":"${issue_id}","agent":"${agent_name}","reason":"${reason_safe}","timestamp":"${ISO8601}"}
   EOF
   ```
   Where `reason_safe` is the `reason` field with `"` escaped as `\"` and `\` escaped as `\\`. Use
   `printf '%s' "${reason}" | jq -Rs .` to produce a safely JSON-encoded string (the result includes
   surrounding `"`; strip them if interpolating inside an existing `"..."` JSON value context).
   The `--proto "=http,https"` flag restricts transport to HTTP/HTTPS only (blocks `file://`, `gopher://`, etc.).
```

#### Fix for `docs/guides/autopilot.md` (after line 286)

Add after the existing `Webhook URL` trust note:

```markdown
**Payload field safety:** Field values interpolated into webhook payloads must be safe for direct JSON
string embedding. The `issue_id` and `run_id` fields are constrained by an allowlist
(`[A-Za-z0-9#_-]`) and are safe to interpolate directly. The `pr_url` field in `pipeline-completed`
events must be a valid percent-encoded URL (as returned by the SCM MCP tool) — do not construct it
from raw user input. If you write a custom post-publish hook that interpolates agent output (e.g.,
`reason` text from a block event), use `jq -Rs .` to JSON-encode the value before embedding it.
```

---

### Shell-escape example (unsafe vs safe)

```bash
# UNSAFE — if issue_id = PROJ"42 (hypothetical tracker data)
curl ... <<EOF
{"issue_id":"${issue_id}"}   # → {"issue_id":"PROJ"42"} — INVALID JSON
EOF

# SAFE — with issue_id allowlist gate (Item 2)
# The gate ensures issue_id = ^[A-Za-z0-9#_-]+$ before reaching this line,
# making direct interpolation structurally safe:
curl ... <<EOF
{"issue_id":"${issue_id}"}   # safe because gate guarantees no '"', '\', spaces
EOF

# SAFE — for free-form text fields (reason, pr_url) without an allowlist gate:
reason_encoded=$(printf '%s' "${reason}" | jq -Rs .)  # produces "\"the reason text\""
reason_json_value="${reason_encoded:1:-1}"              # strip outer quotes → the reason text (escaped)
curl ... <<EOF
{"reason":"${reason_json_value}"}
EOF
```

---

## Cross-cutting: does `core/external-input-sanitizer.md` address path-traversal?

**No.** Evidence from `core/external-input-sanitizer.md:1-5`:
```
## Purpose
Prevent prompt injection attacks by clearly marking external content from issue trackers.
```

The sanitizer wraps content in `--- EXTERNAL INPUT START ---` / `--- EXTERNAL INPUT END ---` markers for prompt injection defense only. It does NOT validate, reject, or transform `issue_id` values. It does NOT address filesystem path construction. There is **zero overlap** between the external-input-sanitizer and the proposed issue_id regex gate.

---

## Summary (≤200 words)

**Item 2 (issue_id regex):** Six primary skills (`fix-ticket`, `fix-bugs`, `implement-feature`, `resume-ticket`, `fix-bugs`, `scaffold`) use `{ISSUE-ID}` raw in `.ceos-agents/{ISSUE-ID}/` directory creation, state.json paths, screenshot paths, and reproduction-result paths. No existing validation exists — `core/external-input-sanitizer.md` is prompt-injection only, not path sanitization. Per-tracker character sets: YouTrack/Jira/Linear use `[A-Z]+-[0-9]+`; GitHub/Gitea use `#[0-9]+`; Redmine uses integers. Conservative allowlist `^[A-Za-z0-9#_-]+$` covers all trackers and rejects `/`, `\`, `..`, null, spaces, `$`, backticks. The gate (bash `grep -qE` snippet) belongs in every skill's Step 0, before the first directory-creation call.

**Item 3 (JSON-encode docs):** `core/post-publish-hook.md` Section 3 (line 23) has a heredoc-safety note covering shell quoting only — no JSON-encoding requirement. Section 4 (lines 100-111) says "identical to Section 3" without adding a JSON-encoding note. `core/block-handler.md` Step 5 is worse: it uses `-d '...'` (not heredoc) with inline `{reason}` substitution — agent-generated free-form text can corrupt JSON structure. `docs/guides/autopilot.md` lines 228-286 show payload examples with no encoding note. Three files need fixes: add JSON-encoding guidance to Section 4 of post-publish-hook.md, convert block-handler.md to heredoc + encoding note, and add a user-facing note to autopilot.md.
