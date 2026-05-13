# Phase 4 — Architecture / Design for v7.0.0

This design document instantiates the requirements in `requirements.md` against the v6.10.0 codebase. All file:line citations come from Phase 2 final.md (verified via live grep). Phase 3 user-approved decisions are encoded inline.

---

## Section 1 — Deletion plan

### 1.1 `skills/create-pr/` — full directory delete

**Command:** `git rm -r skills/create-pr/`

**Rationale:** Phase 3 D4 unanimous DELETE verdict. No stub. Reuse: auto-detect three-mode fork (full-publish / pr-only-no-id / pr-only-404) covers every legitimate `/create-pr` use case except "PR-only with valid tracker reference" — disclosed in CHANGELOG.

**Post-delete invariant:** `find skills -maxdepth 1 -mindepth 1 -type d | wc -l == 28`.

### 1.2 `Extra labels` config section — content edits across 17 active locations

Use Phase 2 R2 inventory verbatim. Each edit is a content removal (DELETE row, DELETE line, REMOVE array element) — no edits introduce new content (count-string update is in REQ-COUNTS scope, not REQ-DEL-EXTRA-LABELS).

| File | Line(s) | Operation |
|------|---------|-----------|
| `core/config-reader.md` | 31 | DELETE parse rule (1 line) |
| `agents/publisher.md` | 69 | REWRITE: "If Extra labels section exists, add those too." → "Add labels from PR Rules section only." |
| `skills/fix-ticket/SKILL.md` | 47 | DELETE bullet (1 line) |
| `skills/fix-ticket/SKILL.md` | 638 | DELETE segment from publisher context string |
| `skills/fix-bugs/SKILL.md` | 42 | DELETE bullet |
| `skills/fix-bugs/SKILL.md` | 783 | DELETE segment |
| `skills/implement-feature/SKILL.md` | 35 | DELETE line |
| `skills/implement-feature/SKILL.md` | 599 | DELETE segment |
| `skills/check-setup/SKILL.md` | 56 | REMOVE `Extra labels,` from optional-section enumeration |
| `skills/migrate-config/SKILL.md` | 41 | REMOVE `Extra labels,` from migration loop list |
| `skills/onboard/SKILL.md` | 175 | DELETE menu item `[12] Extra labels — additional PR labels` |
| `skills/onboard/SKILL.md` | 204 | DELETE config summary line |
| `docs/reference/automation-config.md` | 33 | DELETE Quick reference table row |
| `docs/reference/automation-config.md` | 332-339 | DELETE entire `### Extra labels` section (heading + table, ~8 lines) |
| `CLAUDE.md` | 149 | DELETE optional sections table row |
| `examples/configs/github-nextjs.md` | 104 | DELETE `### Extra labels (optional)` section |
| `examples/configs/redmine-oracle-plsql.md` | 182 | DELETE `### Extra labels (optional)` section |
| `tests/scenarios/config-reader-sections.sh` | 25 | REMOVE `"Extra labels"` from OPTIONAL_SECTIONS array |
| `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` | 25 | REMOVE `"Extra labels"` from OPTIONAL_SECTIONS array |
| `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` | 47 | UPDATE mutation guard `[ "${#OPTIONAL_SECTIONS[@]}" -eq 19 ]` → `-eq 18`; update success message |

---

## Section 2 — Rename plan

### 2.1 `skills/status/` → `skills/pipeline-status/`

**Steps:**
1. `git mv skills/status skills/pipeline-status`
2. Edit `skills/pipeline-status/SKILL.md` frontmatter: `name: status` → `name: pipeline-status`
3. Update all references per Phase 2 Action 3 change list (see REQ-RENAME-STATUS scope).

### 2.2 `skills/init/` → `skills/setup-mcp/`

**Steps:**
1. `git mv skills/init skills/setup-mcp`
2. Edit `skills/setup-mcp/SKILL.md` frontmatter: `name: init` → `name: setup-mcp`
3. Update all references per Phase 2 Action 4 change list (see REQ-RENAME-INIT scope).

### 2.3 Windows hazard mitigation (Phase 3 R8)

After renames + delete are complete, verify that no orphan empty directories remain under `skills/`:

```bash
find skills -maxdepth 1 -mindepth 1 -type d -empty | wc -l
# Expected: 0
```

This protects against a Windows-specific edge case where partial moves can leave empty directories that would inflate the skill count from 28 to 29 (or higher) on the post-rename invariant. Phase 7 must use `git mv` (not `mkdir + cp + rm`) to avoid this.

**Phase 8 invariant:** see Section 8 below.

---

## Section 3 — `/publish` rewrite design

The current `skills/publish/SKILL.md` (37 lines, single-header `## Steps` block) is replaced with a 10-step structure. Steps 4-9 (publisher dispatch + state transition + comment + webhook + display) remain functionally intact; only Step 5's context string adds a `mode` field, and Step 6 conditionally skips on PR-only modes.

### 3.1 Pseudocode (full replacement of current Steps 0-3)

```
### Step 0 — Branch parse (NEW, pre-pre-flight)

a. branch_name = $(git branch --show-current)
   If empty (detached HEAD) → FAIL (EXIT non-zero) with single-line INFO:
     "[ceos-agents][INFO] Cannot determine branch (detached HEAD). /publish requires an active branch."
   (Detached HEAD is treated as FAIL — exit non-zero — NOT as
    pr-only-no-id, because there is no branch to push or use as PR
    source. This is REQ-PUBLISH-AUTO-DETECT SC-12.)

b. Read `Source Control → Branch naming` from Automation Config.
   The template uses {issue-id} (and optionally {description}) as
   placeholders (per docs/reference/automation-config.md:109-111,
   e.g. "fix/{issue-id}-{description}" or "feature/{issue-id}").

   If the `Branch naming` key is ABSENT from Automation Config
   (REQ-PUBLISH-AUTO-DETECT SC-10):
     issue_id = null
     tracker_needed = false
     Emit single-line INFO:
       "[ceos-agents][INFO] No Branch naming pattern configured; PR-only mode."
     Jump directly to Step 3 (skip Steps 0c-d, 1, 2).

c. Identify the literal prefix preceding `{issue-id}`:
   - pre_prefix = literal text preceding {issue-id}

   The post-`{issue-id}` delimiter character is intentionally NOT
   parsed or used as a split boundary. The canonical extraction
   regex (Step 0d) understands the structure of valid issue IDs
   and consumes only the issue-ID portion, ignoring any trailing
   description segment.

   Bash idiom for prefix identification:
     prefix=$(echo "$branch_naming_pattern" | sed 's/{issue-id}.*//')

   Examples:
   - template "fix/{issue-id}-{description}" → pre_prefix="fix/"
   - template "feature/{issue-id}" → pre_prefix="feature/"
   - template "{issue-id}" → pre_prefix=""

d. Regex-based issue-ID extraction (REQ-PUBLISH-AUTO-DETECT SC-11
   — REGEX-EXTRACTOR form, replaces the "split at first delimiter"
   approach which was abandoned in revision-2 because the standard
   YouTrack/Jira/Linear ID format `PROJ-123` itself contains `-`,
   making "split at first `-`" yield `PROJ` instead of `PROJ-123`):

   If branch_name does NOT start with pre_prefix:
     issue_id = null
   Else:
     residue = branch_name with pre_prefix stripped from front.

     Apply the canonical extraction regex against the residue:

       ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)

     This regex anchors at start of residue and matches EITHER:
       - `#?[0-9]+` — numeric, optionally `#`-prefixed
         (github/gitea/redmine shapes: `123`, `#42`)
       - `[A-Za-z][A-Za-z0-9_]*-[0-9]+` — alphanumeric project
         prefix + `-` + digits (youtrack/jira/linear shapes:
         `PROJ-123`, `ABC-456`, `ABC_DEF-789`)

     Bash idiom:
       if [[ "$residue" =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ]]; then
         issue_id="${BASH_REMATCH[1]}"
       else
         issue_id=""
       fi

     The first match is the issue_id. Any trailing characters in
     the residue (e.g., `-fix-crash` after `PROJ-123`) are
     description and discarded. If the regex does not match (e.g.,
     residue starts with non-issue-ID-shaped text): issue_id=null.

     Path-traversal defense (defensive — canonical regex never
     matches dot-only by construction): if issue_id =~ ^\.+$,
     set issue_id = null. (Preserved from v6.8.1 contract.)

   Coverage by tracker (all 6 supported types):

   | Tracker | Issue ID shape | Example | Regex branch matched |
   |---------|----------------|---------|----------------------|
   | youtrack | uppercase prefix + `-` + digits | PROJ-123 | `[A-Za-z][A-Za-z0-9_]*-[0-9]+` |
   | jira | uppercase prefix + `-` + digits | ABC-456 | `[A-Za-z][A-Za-z0-9_]*-[0-9]+` |
   | linear | uppercase prefix + `-` + digits | ENG-789 | `[A-Za-z][A-Za-z0-9_]*-[0-9]+` |
   | github | numeric (optionally `#`-prefixed) | 123 / #42 | `#?[0-9]+` |
   | gitea | numeric (optionally `#`-prefixed) | 123 / #42 | `#?[0-9]+` |
   | redmine | numeric (optionally `#`-prefixed) | 42 / #42 | `#?[0-9]+` |

   Worked examples (Phase 7 must include these in skill prose):
   - branch="fix/PROJ-123-fix-crash", template="fix/{issue-id}-{description}"
       → pre_prefix="fix/"
       → residue="PROJ-123-fix-crash"
       → regex matches `PROJ-123` → issue_id="PROJ-123"
       → trailing "-fix-crash" is description, discarded
   - branch="feature/PROJ-456", template="feature/{issue-id}"
       → pre_prefix="feature/"
       → residue="PROJ-456"
       → regex matches `PROJ-456` → issue_id="PROJ-456"
   - branch="chore/refactor-foo", template="fix/{issue-id}-{description}"
       → branch does NOT start with "fix/" → issue_id=null
   - branch="fix/123-numeric-id", template="fix/{issue-id}-{description}" (github/gitea/redmine)
       → pre_prefix="fix/"
       → residue="123-numeric-id"
       → regex matches `123` (numeric branch) → issue_id="123"
   - branch="fix/#42-fix", template="fix/{issue-id}-{description}" (github hash-prefixed)
       → pre_prefix="fix/"
       → residue="#42-fix"
       → regex matches `#42` → issue_id="#42"
   - branch="feature/ABC_DEF-789", template="feature/{issue-id}" (youtrack with underscore)
       → pre_prefix="feature/"
       → residue="ABC_DEF-789"
       → regex matches `ABC_DEF-789` → issue_id="ABC_DEF-789"

e. Set tracker_needed = (issue_id != null).

   If tracker_needed == false:
     mode = "pr-only-no-id"
     Emit single-line INFO:
       "[ceos-agents][INFO] Branch '{branch_name}' does not match the configured Branch naming pattern. Creating PR without tracker contact."
     (Single logical line — single `echo` invocation — terminated
      by single \n. REQ-PUBLISH-AUTO-DETECT SC-8.)
     Skip directly to Step 3.
   Else:
     proceed to Step 1.

### Step 1 — MCP pre-flight (RENAMED from current Step 0; GATED)

ONLY runs if tracker_needed == true:
  Reuse the existing MCP pre-flight from current Step 0:
    - Read Type from Automation Config (Issue Tracker section)
    - Check that at least one mcp__* tool matching the tracker type
      is accessible
    - If not accessible → emit FAIL block per Section 3.2 FAIL tier
      (error_type = "unknown" if classification fails) → EXIT non-zero

### Step 2 — Tracker lookup (GATED on tracker_needed)

ONLY runs if tracker_needed == true:
  a. Read tracker_type from Automation Config (default: youtrack).
  b. Locate single-issue fetch tool via prefix-scan per
     core/mcp-detection.md:28-34 and core/mcp-detection.md:36
     ("Scan available tools for at least one tool matching the
     prefix"). Do NOT hardcode tool names — pick the
     get_issue-shaped tool from mcp__{tracker_type}__*.
  c. Call discovered tool with issue_id.
  d. Classify outcome per core/mcp-detection.md:58-87:

     ┌─ Issue returned with valid summary →
     │     mode = "full-publish"
     │     INFO: "[ceos-agents][INFO] Issue {issue_id} found in
     │       {tracker_type}. Publishing PR + tracker update."
     │
     ├─ error_type == "not_found" →
     │     mode = "pr-only-404"
     │     WARN per Section 3.2 §404 tier
     │     (single-line, NOT block channel)
     │
     ├─ error_type ∈ {"timeout", "auth", "tls", "unknown"} →
     │     mode = "FAIL"
     │     emit FAIL block per Section 3.2 §FAIL tier
     │     EXIT non-zero
     │
     └─ "Prefix has tools but no get_issue-shaped tool found" →
           classify as error_type = "unknown" → FAIL (R3 mitigation)

### Step 3 — Common pre-publish (mode-independent except FAIL)

a. git log {base_branch}..HEAD --oneline
   If zero commits → STOP with INFO:
     "No changes to publish — branch has no commits above {base_branch}."
b. Check whether an open PR exists for current_branch.
   If yes → STOP with INFO: "PR already exists: {URL}."

### Step 4 — Read Type from Automation Config (UNCHANGED)

### Step 5 — Dispatch publisher agent (haiku, Task)

Context (mode field added):
  "Type = {Type from config}. Use MCP server for {Type}.
   mode = {mode}.
   issue_id = {issue_id or 'none'}."

### Step 6 — Tracker state + comment (CONDITIONAL on mode)

IF mode == "full-publish":
  - Set issue tracker state per State transitions → For Review
  - Post PR-link comment to issue tracker
ELSE (mode in {pr-only-no-id, pr-only-404}):
  - Skip both. Log:
    "[ceos-agents][INFO] PR-only mode ({mode}); tracker not updated."

### Step 7 — Webhook (UNCHANGED)

pr-created event fires in all non-FAIL modes. issue_id field is
empty string when mode in {pr-only-no-id, pr-only-404} per v6.8.0
forward-compatible payload contract.

### Step 8 — Publish Report (publisher agent §82-87 ADDS Tracker: row)

The publisher agent emits a Publish Report. As of v7.0.0, the
agent's report MUST include a Tracker: row in exactly one of these
three forms:

  - Tracker: Updated → For Review               (mode "full-publish")
  - Tracker: Skipped — issue ID '{issue_id}' not found in {tracker_type}
                                                (mode "pr-only-404")
  - Tracker: Skipped — no issue ID in branch name
                                                (mode "pr-only-no-id")

### Step 9 — Display result (UNCHANGED — PR URL + state)

### Operator note (REQ-PUBLISH-AUTO-DETECT SC-5)

(Inserted into skill prose, not as a separate Step)

> /publish is interactive-only — it requires user confirmation flows
> in agent prose and may FAIL in environments without an MCP server
> configured (CI / cron). For headless / batch publishing, use
> /ceos-agents:autopilot.
```

### 3.2 Tracker-down failure UX (three tiers)

#### FAIL tier (`error_type ∈ {timeout, auth, tls, unknown}`)

Format (matches CLAUDE.md "Block Comment Template"):

```
[ceos-agents] 🔴 Pipeline Block
Skill: /ceos-agents:publish
Step: Tracker auto-detect (Step 2)
Reason: Issue tracker unreachable — cannot verify whether '{issue_id}' exists.
Detail: {error_type} error from {tracker_type} MCP: {error_message}
Recommendation:
  1. Run `/ceos-agents:check-setup` to diagnose tracker connectivity.
  2. If you intentionally want a PR with no tracker update, rename your
     branch to one that does NOT start with the configured Branch naming
     prefix (e.g., from "fix/PROJ-123-foo" to "chore/PROJ-123-foo"),
     then re-run /publish. Auto-detect will fall through to PR-only mode.
  3. If the tracker is intentionally offline, create the PR manually:
     git push -u origin {branch} && gh pr create
     (or your tracker UI's equivalent)
  4. Once the tracker is reachable, re-run `/ceos-agents:publish`.
```

`Skill:` field (not `Agent:`) — convention for skill-level blocks. Format is machine-parseable by `/resume-ticket` and webhook consumers (per CLAUDE.md "Block Comment Template").

#### 404 WARN tier (`error_type == "not_found"`)

```
[ceos-agents][WARN] Branch '{branch}' contains issue ID pattern '{issue_id}' but no matching ticket was found in {tracker_type}. Creating PR without tracker update.
```

NOTE — this is ONE logical line; emit as a single `echo` call (single `\n` at end). REQ-PUBLISH-AUTO-DETECT SC-7. The displayed wrapping in this design document is a presentation artifact; the implementation MUST NOT split into multiple `echo` calls or insert mid-line newlines. Stdout (not block channel). Pipeline continues with `mode = "pr-only-404"`.

#### No-issue-id INFO tier (issue_id == null after extraction)

```
[ceos-agents][INFO] Branch '{branch}' does not match the configured Branch naming pattern. Creating PR without tracker contact.
```

NOTE — single logical line, single `echo` call. REQ-PUBLISH-AUTO-DETECT SC-8. INFO level. Non-matching branch is probably intentional (user named it `chore/refactor-foo`); should not look alarming. Pipeline continues with `mode = "pr-only-no-id"`.

#### Missing Branch naming INFO tier (Branch naming key absent — REQ-PUBLISH-AUTO-DETECT SC-10)

```
[ceos-agents][INFO] No Branch naming pattern configured; PR-only mode.
```

Single logical line. Pipeline continues with `mode = "pr-only-no-id"`. Skips MCP pre-flight entirely.

#### Detached HEAD FAIL tier (REQ-PUBLISH-AUTO-DETECT SC-12)

```
[ceos-agents][INFO] Cannot determine branch (detached HEAD). /publish requires an active branch.
```

Single logical line. Exits non-zero. NOT a Block Comment Template message — this is a pre-flight environment check, not a tracker-down failure. No tracker comment, no webhook event.

### 3.3 Citations

- `core/mcp-detection.md:28-34` — tracker prefix table (no hardcoded tool names)
- `core/mcp-detection.md:36` — "Scan available tools for at least one tool matching the prefix"
- `core/mcp-detection.md:58-87` — error classification (5-bucket enum + Classification Reference table)
- `skills/fix-ticket/SKILL.md:91` — issue_id regex `^[A-Za-z0-9#._-]+$` + dot-only rejection
- `docs/reference/automation-config.md:109-111` — Branch naming template (`fix/{issue-id}-{description}`)
- `agents/publisher.md` §82-87 — Publish Report format (gets new `Tracker:` row added)

### 3.4 What does NOT change

- Steps 4, 5 (dispatch shape), 7 (webhook), 9 (display) — unchanged in shape.
- `agents/publisher.md` other than §69 (`Extra labels` text) and §82-87 (new `Tracker:` row).
- `core/mcp-detection.md`, `core/mcp-preflight.md` — referenced unchanged.
- State schema `state.json` — unchanged (forward-compat: in-flight v6.10.x pipelines continue to work).
- Webhook payload contracts — `pr-created` payload uses empty-string `issue_id` for PR-only modes per v6.8.0 forward-compat.

---

## Section 4 — Migration support design

### 4.1 CHANGELOG.md `## [7.0.0]` block (verbatim, English)

The CHANGELOG entry uses this template (Phase 7 inserts at the top of CHANGELOG.md, above the existing v6.10.0 entry):

```markdown
## [7.0.0] — Unreleased

### BREAKING CHANGES

- `Extra labels` config section removed → move any labels into `PR Rules → Labels`.
- `/ceos-agents:status` → `/ceos-agents:pipeline-status` (short form `/status` collided with a Claude Code builtin).
- `/ceos-agents:init` → `/ceos-agents:setup-mcp` (short form `/init` collided with a Claude Code builtin).
- `/create-pr` removed → use `/publish` (auto-detects: when the branch contains an issue ID and the ticket exists, performs a tracker update; otherwise PR-only).
- `Pause Limits` doc fixed — the section applies to all pipeline skills, not just `/autopilot` (no functional change, doc only).

### Migration from v6.10.x to v7.0.0

1. **`Extra labels` removal.** Move any labels you had under `### Extra labels (optional)` into your `### PR Rules → Labels` list. The plugin ignores `Extra labels` after the upgrade — `/check-setup` emits a `[WARN]` if it detects the deprecated section in your CLAUDE.md.

2. **`/ceos-agents:status` → `/ceos-agents:pipeline-status`.** Update any saved aliases, scripts, or CI configurations. There is no aliasing layer — typing `/ceos-agents:status` after the upgrade produces Claude Code's standard skill-not-found error.

3. **`/ceos-agents:init` → `/ceos-agents:setup-mcp`.** Same as #2 — no alias, skill-not-found error on the old name.

4. **`/create-pr` removed.** Use `/ceos-agents:publish`. The skill now auto-detects the publishing mode from the branch name:
   - Branch starts with the configured `Branch naming` prefix AND the residue matches the canonical issue-ID extraction regex AND that issue exists in the tracker → full publish (PR + tracker update + comment + webhook).
   - Branch starts with the prefix AND the regex matches a valid issue-ID segment AND the issue is 404 → PR-only with `[WARN]` (creates the PR, skips tracker update, logs once).
   - Branch does NOT start with the configured prefix (or `Branch naming` is unconfigured, or the residue does not match the canonical issue-ID regex) → PR-only with `[INFO]` (creates the PR, never contacts the tracker).
   - Tracker unreachable (5xx / timeout / TLS / auth / unknown error) → FAIL with diagnostic block.

   **Issue-ID extraction uses a canonical regex** that understands the structure of all 6 supported tracker ID shapes (youtrack/jira/linear `PROJ-123`, github/gitea/redmine `123` or `#42`). The regex `^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)` is anchored at the start of the post-prefix residue and consumes only the issue-ID portion; any trailing description segment is discarded. For `Branch naming: fix/{issue-id}-{description}` and branch `fix/PROJ-123-fix-crash`, the extracted issue_id is `PROJ-123` (the regex matches the project-prefix-plus-digits shape), NOT `PROJ` (which would have been the result of the abandoned "split at first `-` delimiter" approach) and NOT `PROJ-123-fix-crash` (which would have been the result of greedy validation). See `skills/publish/SKILL.md` Step 0d for the worked extraction examples covering all 6 tracker ID shapes.

   **Lost agency disclosure:** v7.0.0 removes the ability to opt out of tracker update when the branch matches an existing issue. To create a PR without touching the tracker, use a branch name that does NOT start with the configured `Branch naming` prefix (e.g., `chore/refactor-foo` instead of `fix/PROJ-123-foo`). Note: simply renaming `fix/PROJ-123-foo` → `chore/PROJ-123-foo` works because the configured prefix `fix/` no longer matches; the issue-ID-shaped residue is irrelevant when the prefix doesn't match.

5. **`Pause Limits` doc fix.** No action required. The Quick reference table at `docs/reference/automation-config.md:40` now correctly lists all 6 lifecycle participants (`/fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot, /resume-ticket`).

### State.json forward-compatibility

In-flight pipelines from v6.10.x continue to work — `state.json` schema is unchanged. Renames affect only skill invocation; existing pipeline runs proceed normally because state.json does not embed skill names.

### Skill-not-found behavior

Users who type `/ceos-agents:status`, `/ceos-agents:init`, or `/ceos-agents:create-pr` after the upgrade will see Claude Code's standard skill-not-found error. There is no aliasing layer — this is intentional to prevent skill-count drift (`find skills -maxdepth 1 -mindepth 1 -type d | wc -l` must equal 28 post-v7.0.0).

### Counts after v7.0.0

- 21 agents (no change)
- 28 skills (was 29; `/create-pr` removed)
- 16 core contracts (no change)
- 18 optional config sections (was 19; `Extra labels` removed)
- 8 config templates (no change)
```

### 4.2 README.md migration table (Phase 3 Dimension 2)

Insert this table in `README.md` after the Installation section (location coordinated with REQ-DOCS-COLLISION-WARN subsection):

```markdown
### Renames and removals — v6.10.x → v7.0.0

| Old name | New name | Reason |
|---|---|---|
| `/ceos-agents:status` | `/ceos-agents:pipeline-status` | Short form `/status` collides with a Claude Code builtin |
| `/ceos-agents:init` | `/ceos-agents:setup-mcp` | Short form `/init` collides with a Claude Code builtin |
| `/ceos-agents:create-pr` | `/ceos-agents:publish` (auto-detect) | Removed; `/publish` detects PR-only vs full-publish from branch name |
| `Extra labels` config section | `PR Rules → Labels` | Duplicate functionality consolidated |
```

### 4.3 `/check-setup` deprecated-config detector (Phase 3 Dimension 2 + open question 11)

Insert this snippet into `skills/check-setup/SKILL.md` (placement: late in the existing scan loop, before the final exit-code computation):

```bash
## Deprecated v6.x config detection

if grep -q '^### Extra labels' "$CLAUDE_MD"; then
  echo "[WARN] Deprecated config section: ### Extra labels"
  echo "  Removed in v7.0.0. Move any labels into ### PR Rules → Labels"
  echo "  (which fully supports the use case). See CHANGELOG.md."
fi
```

**Exit-code semantics (Phase 3 open question 11):** The `[WARN]` does NOT change `/check-setup`'s exit code. `/check-setup` does not have a warn-vs-fail tiering today (only gate-based fails); this REQ explicitly chooses warning-only behavior. AC verifies this by running `/check-setup` against a CLAUDE.md with `### Extra labels` and asserting exit 0 plus the WARN string in stdout.

**No first-run nudge from `core/config-reader.md`** (Phase 3 D3 reject). **No sentinel comment in user CLAUDE.md.** **No `/migrate-config` v7 extension.**

### 4.4 README + installation guide collision warning (REQ-DOCS-COLLISION-WARN)

Both files get an explicit subsection at the H2 or H3 level. Sample heading + content (final wording can vary per Phase 7 prose, but the core message is fixed):

#### README.md (insert after Installation section)

```markdown
### Slash command collision with Claude Code builtins

The short forms `/status` and `/init` collide with built-in Claude Code slash commands. To avoid surprises, always invoke ceos-agents skills with the full namespace prefix:

- `/ceos-agents:pipeline-status` (NOT `/status`)
- `/ceos-agents:setup-mcp` (NOT `/init`)

In v7.0.0 the previous `/ceos-agents:status` and `/ceos-agents:init` skill names were renamed; `/ceos-agents:create-pr` was removed in favor of `/ceos-agents:publish` (auto-detect). See [Renames and removals](#renames-and-removals--v610x--v700) above.
```

#### docs/guides/installation.md (insert as a NEW subsection — Phase 2 F5 confirmed no Limitations section exists)

```markdown
### Slash command collision with Claude Code builtins

ceos-agents skills are namespaced (`/ceos-agents:<skill>`) to avoid conflicts with other plugins and with Claude Code's built-in commands. The short forms `/status` and `/init` collide with builtins; always use the namespaced forms:

- `/ceos-agents:pipeline-status` (renamed from `/ceos-agents:status` in v7.0.0)
- `/ceos-agents:setup-mcp` (renamed from `/ceos-agents:init` in v7.0.0)
- `/ceos-agents:publish` (replaces removed `/ceos-agents:create-pr` with auto-detect; see CHANGELOG)
```

---

## Section 5 — Workflow-router edits

### 5.1 Intent table edits (`skills/workflow-router/SKILL.md:15-20`)

Phase 2 Q5 captured the verbatim current rows:

```
| Create a pull request | `ceos-agents:create-pr` | None | Yes |
| Publish (PR + issue state) | `ceos-agents:publish` | None | Yes |
| Show status/overview | `ceos-agents:status` | None | No |
| Configure MCP/tokens/permissions | `ceos-agents:init` | Optional: --update | Yes |
```

5 surgical edits:

| Line | Edit |
|------|------|
| 15 | DELETE the `create-pr` table row |
| 18 | `ceos-agents:status` → `ceos-agents:pipeline-status` |
| 20 | `ceos-agents:init` → `ceos-agents:setup-mcp` |
| 54 | `status` → `pipeline-status` in the Step 3 non-destructive list |
| 55 | Remove `create-pr,` from the Step 4 destructive list |

Line 16 (`/publish` row) is unchanged — its description "PR + issue state" remains accurate after auto-detect.

### 5.2 Step 3/4 prose (Phase 2 Q5 verbatim)

Current text at `skills/workflow-router/SKILL.md:54-55`:

```
3. **If the operation is NOT destructive** (analyze-bug, check-setup, version-check, status, dashboard, metrics, estimate, prioritize, template, scaffold-validate, check-deploy without flags, autopilot --dry-run): invoke the command immediately
4. **If the operation IS destructive** (fix-ticket, fix-bugs, create-pr, publish, check-deploy --start/--stop, autopilot without --dry-run):
```

Post-v7.0.0:

```
3. **If the operation is NOT destructive** (analyze-bug, check-setup, version-check, pipeline-status, dashboard, metrics, estimate, prioritize, template, scaffold-validate, check-deploy without flags, autopilot --dry-run): invoke the command immediately
4. **If the operation IS destructive** (fix-ticket, fix-bugs, publish, check-deploy --start/--stop, autopilot without --dry-run):
```

### 5.3 New "Did you mean...?" fallback prose (Phase 3 D3 + open question 10)

Insert this block into `skills/workflow-router/SKILL.md` (placement: a new step or paragraph at the end of the Steps section, near the existing fallback prose; exact placement Phase-7 author's choice):

```
### Deprecated names (v6.10.x → v7.0.0)

If the user references a deprecated identifier, suggest the new name and continue:

- `ceos-agents:status` → did you mean `/ceos-agents:pipeline-status`?
- `ceos-agents:init` → did you mean `/ceos-agents:setup-mcp`?
- `ceos-agents:create-pr` → did you mean `/ceos-agents:publish`? (auto-detects PR-only vs full-publish from the branch name)
```

This is a documentation insertion — the workflow-router does not implement runtime aliasing. It only emits the suggestion in agent prose.

**Workflow-router exclusion contract (resolved in Phase 4 — RESOLVED, no Phase-7 deferral):** Because this prose intentionally references the three deprecated identifiers (`ceos-agents:status`, `ceos-agents:init`, `ceos-agents:create-pr`), the deprecated-identifier sanity greps in Phase 8 (design.md §8.2) and the formal ACs `AC-RENAME-STATUS-4`, `AC-RENAME-INIT-4`, `AC-DEL-CREATE-PR-2` MUST exclude `skills/workflow-router/SKILL.md` via `--exclude=skills/workflow-router/SKILL.md`. Conversely, a positive AC `AC-DOCS-COLLISION-WARN-WORKFLOW-1` verifies the deprecated names ARE present in the workflow-router file. AC-RENAME-STATUS-5 (which checks `! grep ... 'ceos-agents:status'` against workflow-router) and AC-DEL-CREATE-PR-7 (same pattern for `create-pr`) are tightened to scope the prohibition outside the "Deprecated names" section — see formal-criteria.md for the binding AC commands. This resolves Phase 4 review findings f-a1b2c3 (Reviewers 1, 2, 3) and f-b2d4e5 (Reviewer 3 CRITICAL).

### 5.4 Citations

- `skills/workflow-router/SKILL.md:15` — create-pr intent row (DELETE)
- `skills/workflow-router/SKILL.md:18` — status intent row (rename)
- `skills/workflow-router/SKILL.md:20` — init intent row (rename)
- `skills/workflow-router/SKILL.md:54` — Step 3 non-destructive list (rename `status` → `pipeline-status`)
- `skills/workflow-router/SKILL.md:55` — Step 4 destructive list (remove `create-pr,`)

---

## Section 6 — Cross-cutting doc count edits

Phase 2 R6 + Q9 + finding F7. The 5 anchor files plus `docs/getting-started.md`:

| File | Line | Current | New |
|------|------|---------|-----|
| `CLAUDE.md` | 18 | `29 skills (slash commands, including workflow-router)` | `28 skills (slash commands, including workflow-router)` |
| `CLAUDE.md` | 31 | `..., /create-pr, ..., /status, ..., /init, ...` | remove `/create-pr,`; `/status`→`/pipeline-status`; `/init`→`/setup-mcp` |
| `CLAUDE.md` | 149 | `\| Extra labels \| Labels \| (none) \|` | DELETE row (REQ-DEL-EXTRA-LABELS) |
| `CLAUDE.md` | 160 | `There are 19 optional config sections in total.` | `There are 18 optional config sections in total.` |
| `README.md` | 148 | `\| `/create-pr` \| ... \|` | DELETE row (REQ-DEL-CREATE-PR) |
| `README.md` | 153 | `\| `/status` \| ... \|` | `\| `/pipeline-status` \| ... \|` (REQ-RENAME-STATUS) |
| `README.md` | 164 | `\| `/init` \| ... \|` | `\| `/setup-mcp` \| ... \|` (REQ-RENAME-INIT) |
| `README.md` | 221 | `**19 optional sections** cover ..., labels, ...` | `**18 optional sections** cover ...` (remove "labels" from list) |
| `README.md` | 262 | `All 29 skills — syntax, flags, examples` | `All 28 skills — syntax, flags, examples` |
| `docs/reference/skills.md` | 3 | `all 29 skills ... All 29 ceos-agents skills` | `all 28 skills ... All 28 ceos-agents skills` |
| `docs/architecture.md` | 27 | `SKL[29 Skills]` | `SKL[28 Skills]` |
| `docs/reference/automation-config.md` | 9 | `19 optional sections` | `18 optional sections` |
| `docs/getting-started.md` | 219 | `Explore all 29 skills` | `Explore all 28 skills` |

---

## Section 7 — Test scenario plan

Phase 2 Q8 inventory. Classification per scenario:

### UPDATE (12 scenarios — content edits)

| # | File | Detail |
|---|------|--------|
| 1 | `tests/scenarios/regression-skill-count-29.sh` | Line 14: `-ne 29` → `-ne 28` |
| 2 | `tests/scenarios/ac-v68-doc-skill-count-29.sh` | Lines 15, 21: flip positive `28 skills`, negative `29 skills` |
| 3 | `tests/scenarios/v6.9.0-doc-count-drift.sh` | 6 changes (DISAGREEMENT D resolution): line 42-45 (positive flip 19→18), line 55-58 (negative flip 18→19), line 72 (`-eq 29` → `-eq 28`), line 79 (`-eq 19` → `-eq 18`), line 84 (fallback prose 19→18), line 89 (PASS message `19 optional, 29 skills` → `18 optional, 28 skills`) |
| 4 | `tests/scenarios/skills-directory-structure.sh` | Line 36: remove `create-pr`; line 43: `init`→`setup-mcp`; line 54: `status`→`pipeline-status` |
| 5 | `tests/scenarios/skills-frontmatter-check.sh` | Line 51: remove `create-pr`; ~line 90: `status`→`pipeline-status`; ~line 97: `init`→`setup-mcp`; FC-5 count comment 12→11; FC-6 entries renamed |
| 6 | `tests/scenarios/no-mcp-jargon-errors.sh` | Line 15: remove `skills/create-pr/SKILL.md`; line 20: `skills/status/SKILL.md` → `skills/pipeline-status/SKILL.md` |
| 7 | `tests/scenarios/config-reader-sections.sh` | Line 25: remove `"Extra labels"` from OPTIONAL_SECTIONS array |
| 8 | `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` | Line 25: remove `"Extra labels"`; line 47: mutation guard `-eq 19` → `-eq 18`; success message updated |
| 9 | `tests/scenarios/v6.9.0-arch-freshness-refresh-on-release.sh` | Lines 18-28: flip positive `SKL[29 Skills]` → `SKL[28 Skills]`, negative reject `SKL[28 Skills]` → reject `SKL[29 Skills]` (Phase 2 Agent 3 finding) |
| 10 | `tests/scenarios/scaffold-mcp-checkpoint.sh` | Line 7: `skills/init/SKILL.md` → `skills/setup-mcp/SKILL.md` |
| 11 | `tests/scenarios/v6.10.0-dispatch-hook-install-surface.sh` | Line 17: `skills/init/SKILL.md` → `skills/setup-mcp/SKILL.md` |
| 12 | `tests/scenarios/v644-diagnostics-hardening.sh` | Lines 19, 36, 67, 109, 375, 378: `skills/init/SKILL.md` → `skills/setup-mcp/SKILL.md` (6 occurrences) |

### NO-CHANGE (3 scenarios — passes by design)

| File | Reason |
|------|--------|
| `tests/scenarios/ac-v68-doc-optional-sections-18.sh` | Regex `(18\|19) optional` correctly accepts "18 optional" — passes after drop |
| `tests/scenarios/xref-command-count.sh` | Dynamic filesystem count; auto-corrects when CLAUDE.md is updated consistently |
| `tests/scenarios/v6.9.0-cross-file-invariants.sh` | Tests invariant structure (license SPDX, maintainer email, template parity), not skill counts |

### RETIRE (none)

No scenarios are retired in v7.0.0 — all 12 HARD-FAIL scenarios are mechanically updated to expect the new counts/paths.

### DELETE (none)

No scenarios are deleted. The closest candidates (`regression-skill-count-29.sh`, `ac-v68-doc-skill-count-29.sh`) are kept and updated; their value (asserting count consistency) survives the rename.

### Critical (Phase 2 DISAGREEMENT D)

`v6.9.0-doc-count-drift.sh` MUST update BOTH the positive assertion at lines 42-45 (which currently looks for `'19 optional config sections in total'`) AND the negative assertion at lines 55-58 (which currently rejects `'18 optional config sections in total'`). After v7.0.0, both polarities flip: line 42-45 looks for `'18 optional config sections in total'`, line 55-58 rejects `'19 optional config sections in total'`. Lines 72, 79, 84, 89 also update per Phase 2 DISAGREEMENT D resolution (6 total edits).

---

## Section 8 — Phase 8 verification commands

Adopted verbatim from Phase 2 final.md "Phase 8 Verification Commands" section (lines 533-640) with one addition: the empty-skills-dir invariant (Phase 3 R8 / open question 7).

### 8.1 Cross-file invariants

```bash
# Invariant 1: License SPDX consistency
grep -c '"MIT"' .claude-plugin/plugin.json     # Expected: 1
grep -c '"MIT"' .claude-plugin/marketplace.json  # Expected: 1
head -1 LICENSE | grep -qF 'MIT License' && echo "LICENSE: MIT OK" || echo "LICENSE: MIT FAIL"

# Invariant 2: Maintainer email consistency
for f in SECURITY.md CODE_OF_CONDUCT.md CONTRIBUTING.md; do
  echo "$f: $(grep -c 'filip.sabacky@ceosdata.com' "$f")"
done
# Expected: SECURITY.md: 1, CODE_OF_CONDUCT.md: 1, CONTRIBUTING.md: 1

# Invariant 3: Issue/PR template parity
diff -q .gitea/issue_template/bug_report.md .github/ISSUE_TEMPLATE/bug_report.md
diff -q .gitea/issue_template/feature_request.md .github/ISSUE_TEMPLATE/feature_request.md
diff -q .gitea/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md
```

### 8.2 Deprecated identifier sanity (each must return 0)

```bash
# Extra labels removed everywhere (non-historical, non-forge)
grep -rn "Extra labels" \
  --include="*.md" \
  --exclude-dir=.forge \
  --exclude-dir=".forge.bak-*" \
  --exclude-dir=docs/plans \
  --exclude-dir=docs/superpowers \
  --exclude=CHANGELOG.md \
  . | wc -l
# Expected: 0

# No stale ceos-agents:status references (non-forge, active files only)
# NOTE: workflow-router excluded — it intentionally references the
# deprecated identifier in its "Did you mean...?" fallback prose
# (design.md §5.3). Workflow-router presence is positively asserted
# by AC-DOCS-COLLISION-WARN-WORKFLOW-1.
grep -rn "ceos-agents:status\b" \
  --include="*.md" \
  --exclude-dir=.forge \
  --exclude-dir=".forge.bak-*" \
  --exclude-dir=docs/plans \
  --exclude-dir=docs/superpowers \
  --exclude=CHANGELOG.md \
  --exclude=skills/workflow-router/SKILL.md \
  . | wc -l
# Expected: 0

# No stale ceos-agents:init references
grep -rn "ceos-agents:init\b" \
  --include="*.md" \
  --exclude-dir=.forge \
  --exclude-dir=".forge.bak-*" \
  --exclude-dir=docs/plans \
  --exclude-dir=docs/superpowers \
  --exclude=CHANGELOG.md \
  --exclude=skills/workflow-router/SKILL.md \
  . | wc -l
# Expected: 0

# No stale ceos-agents:create-pr references
grep -rn "ceos-agents:create-pr\b" \
  --include="*.md" \
  --exclude-dir=.forge \
  --exclude-dir=".forge.bak-*" \
  --exclude-dir=docs/plans \
  --exclude-dir=docs/superpowers \
  --exclude=CHANGELOG.md \
  --exclude=skills/workflow-router/SKILL.md \
  . | wc -l
# Expected: 0

# Positive workflow-router check: deprecated names ARE present in
# the "Did you mean...?" prose (must be >= 3 hits across the 3
# deprecated identifiers — see AC-DOCS-COLLISION-WARN-WORKFLOW-1).
grep -E '(ceos-agents:status|ceos-agents:init|ceos-agents:create-pr)' \
  skills/workflow-router/SKILL.md | wc -l
# Expected: >= 3
```

### 8.3 Skill directory sanity

```bash
[ ! -d skills/create-pr ] && echo "create-pr: DELETED OK" || echo "create-pr: STILL EXISTS (FAIL)"
[ ! -d skills/status ] && echo "skills/status: GONE OK" || echo "skills/status: STILL EXISTS (FAIL)"
[ -d skills/pipeline-status ] && echo "skills/pipeline-status: EXISTS OK" || echo "skills/pipeline-status: MISSING (FAIL)"
[ ! -d skills/init ] && echo "skills/init: GONE OK" || echo "skills/init: STILL EXISTS (FAIL)"
[ -d skills/setup-mcp ] && echo "skills/setup-mcp: EXISTS OK" || echo "skills/setup-mcp: MISSING (FAIL)"

SKILL_COUNT=$(find skills -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
[ "$SKILL_COUNT" -eq 28 ] && echo "skill count: 28 OK" || echo "skill count: $SKILL_COUNT (expected 28, FAIL)"

# Empty-skills-dir invariant (Phase 3 R8 / open question 7)
EMPTY_DIRS=$(find skills -maxdepth 1 -mindepth 1 -type d -empty | wc -l | tr -d ' ')
[ "$EMPTY_DIRS" -eq 0 ] && echo "empty-skills-dirs: 0 OK" || echo "empty-skills-dirs: $EMPTY_DIRS (FAIL — Windows orphan directory hazard)"
```

### 8.4 Doc count consistency

```bash
grep -qF '28 skills' CLAUDE.md && echo "CLAUDE.md 28 skills: OK" || echo "CLAUDE.md 28 skills: FAIL"
grep -qF '29 skills' CLAUDE.md && echo "CLAUDE.md stale 29: FAIL" || echo "CLAUDE.md stale 29: absent OK"
grep -qF '18 optional config sections in total' CLAUDE.md && echo "CLAUDE.md 18 optional: OK" || echo "CLAUDE.md 18 optional: FAIL"
grep -qF '19 optional config sections in total' CLAUDE.md && echo "CLAUDE.md stale 19: FAIL" || echo "CLAUDE.md stale 19: absent OK"

grep -qF '28 skills' README.md && echo "README 28 skills: OK" || echo "README 28 skills: FAIL"
grep -qF '18 optional sections' README.md && echo "README 18 optional: OK" || echo "README 18 optional: FAIL"

grep -qE 'all 28 skills' docs/reference/skills.md && echo "skills.md 28: OK" || echo "skills.md 28: FAIL"
grep -qF '18 optional sections' docs/reference/automation-config.md && echo "automation-config 18: OK" || echo "automation-config 18: FAIL"
grep -qF 'SKL[28 Skills]' docs/architecture.md && echo "architecture 28: OK" || echo "architecture 28: FAIL"
grep -qF 'all 28 skills' docs/getting-started.md && echo "getting-started 28: OK" || echo "getting-started 28: FAIL"
```

### 8.5 Pause Limits Used-By column

```bash
grep -A0 'Pause Limits.*No' docs/reference/automation-config.md | grep -q 'fix-ticket' \
  && echo "Pause Limits Used-By updated: OK" \
  || echo "Pause Limits Used-By still /autopilot only: FAIL"
```

### 8.6 Frontmatter names correct after renames

```bash
grep -q '^name: pipeline-status' skills/pipeline-status/SKILL.md \
  && echo "pipeline-status frontmatter: OK" || echo "pipeline-status frontmatter: FAIL"
grep -q '^name: setup-mcp' skills/setup-mcp/SKILL.md \
  && echo "setup-mcp frontmatter: OK" || echo "setup-mcp frontmatter: FAIL"
```

### 8.7 No-version-bump invariant (REQ-NO-VERSION-BUMP)

```bash
# Pipeline branch must not modify plugin.json or marketplace.json version field
git diff main -- .claude-plugin/plugin.json | grep -E '^[+-].*"version"' | wc -l
# Expected: 0
git diff main -- .claude-plugin/marketplace.json | grep -E '^[+-].*"version"' | wc -l
# Expected: 0
# No v7.0.0 tag created
git tag -l v7.0.0 | wc -l
# Expected: 0
```

---

## Section 9 — Out-of-scope

The following are explicitly OUT of scope for this v7.0.0 forge pipeline:

1. **Version bump.** `plugin.json.version` and `marketplace.json.version` are NOT touched. No v7.0.0 git tag is created. The user runs `/ceos-agents:version-bump` (or the project's manual procedure) AFTER the pipeline produces a clean Phase 8 verdict. REQ-NO-VERSION-BUMP makes this a verified prohibition.

2. **v6.10.1 follow-ups.** Per project memory:
   - Autopilot dispatch audit parity
   - Anti-pattern regex widening
   - README enumeration drift checks

   These were noted at v6.10.0 release but are explicitly NOT planned for execution — they are superseded by the v7.0.0 plan and will be re-evaluated in v9.0.0 polish work if still relevant.

3. **Public-mirror canonical-URL update.** `plugin.json.repository` remains at the RFC 2606 unsquattable `https://example.invalid/...` value from v6.9.0. The canonical URL update is part of v9.0.0 (sub-projekt G — Public release polish), not v7.0.0.

4. **Webhook event additions.** No new webhook event introduced. `tracker-down` is deferred to v7.0.1+ if observability demand emerges (Phase 3 D5 + open question deferred).

5. **`/migrate-config` v7 extension.** No auto-rewrite, no sentinel comment in user CLAUDE.md, no first-run nudge from `core/config-reader.md`. The migration support surface is exactly: CHANGELOG block + README table + `/check-setup` `[WARN]`. Phase 3 D3 unanimous reject.

6. **Stub skills.** No `skills/status/`, `skills/init/`, or `skills/create-pr/` stub remains after delete/rename. Skill-not-found error from Claude Code is the intended behavior post-upgrade. Phase 3 D4 unanimous DELETE.

7. **`/publish --no-tracker` flag or any new flags.** The v7.0.0 design intent is "no new config keys, no new flags." Workaround for the lost-agency case is branch-rename (documented in CHANGELOG).

8. **Localization of CHANGELOG / README / migration prose.** All user-facing text in v7.0.0 is English per project conventions. The Czech bullets in the spec are translated to English in CHANGELOG.

9. **Architectural reworks.** Sub-projekty A (Agent shape rework) and B (Human-in-the-loop pipelines) are scheduled for v8.0.0. v7.0.0 explicitly does NOT touch agent definitions beyond the `agents/publisher.md:69, 82-87` edits required by REQ-DEL-EXTRA-LABELS and REQ-PUBLISH-AUTO-DETECT.

---
