# Proposal B — Innovative

**Persona:** 5-year power-user living on the bleeding edge of agentic dev tooling.
**Default stance:** Delight the user. Embrace the breaking change. Ship the future. Tell users what just happened in one rich line BEFORE acting on their behalf.
**Phase 3 inputs honored:** Phase 2 final research (Q1–Q9 + DISAGREEMENTs A–D), v7.0.0 spec (6 actions FINÁLNÍ scope), and CLAUDE.md versioning policy.

---

## Dimension 1 — Implementation strategy for Action 5 (`/publish` auto-detect rewrite)

### Core idea

A single 3-line **status banner** is printed BEFORE any git/MCP/PR work happens. The banner is the user's first signal — a rich, deterministic summary of the auto-detect outcome. THEN the skill proceeds.

```
✓ tracker:OK   issue:PROJ-123 ("Fix login redirect")   mode:full-publish
─ Commits: 3 above main • PR: none yet • Will: push → PR → tracker → comment
```

```
⚠ tracker:OK   issue:PROJ-999 (404 not found)          mode:pr-only
─ Commits: 1 above main • PR: none yet • Will: push → PR (no tracker update)
```

```
✗ tracker:DOWN tracker_type:youtrack  error:timeout    mode:FAIL
─ Will: STOP. Run /ceos-agents:check-setup or retry once tracker is reachable.
```

```
ℹ no_issue_id  branch:hotfix/quick-typo                 mode:pr-only
─ Commits: 1 above main • PR: none yet • Will: push → PR (no tracker context)
```

The banner is the SINGLE source of truth for what just got auto-detected and what the skill is about to do. No second-guessing, no buried `[INFO]` line, no scrolling.

### Steps 1-3 rewrite (replaces existing Steps 1-3 in `skills/publish/SKILL.md`)

```markdown
## Steps

### 1. Detect current state (banner-first)

Run these in order, accumulating the four banner fields (`status`, `tracker`, `issue`, `mode`):

a. `git branch --show-current` → current_branch.
b. Read `Source Control → Branch naming` from Automation Config. Identify the literal prefix
   before `{issue-id}` (e.g., `fix/`, `feature/`). Strip it from current_branch.
   Apply the v6.8.1 issue-ID regex `^[A-Za-z0-9#._-]+` to the residue. First match = issue_id.
   Reject the dot-only edge case (`! issue_id =~ ^\.+$`) per v6.8.1 path-traversal defense.
   If extraction fails → issue_id = null.

c. Read `Issue Tracker → Type` from Automation Config (default: youtrack).

d. If issue_id is null:
     status = ℹ ("info"); tracker = "n/a"; mode = "pr-only-no-id".
     Skip to Step 2.

e. Else attempt single-issue fetch via prefix-scan per `core/mcp-detection.md`:
     Locate the tool matching `mcp__{tracker_type}__*` whose name signals single-issue read
     (typically `get_issue`, `getIssue`, or close variant — the LLM picks the best match).
     Call it with issue_id.

   Classify the outcome with `core/mcp-detection.md` Classification Reference:

   - Issue returned with valid summary → status = ✓; tracker = "OK"; issue = "{id} (\"{summary}\")"; mode = "full-publish".
   - error_type == "not_found" → status = ⚠; tracker = "OK"; issue = "{id} (404 not found)"; mode = "pr-only-404".
   - error_type ∈ {"timeout", "auth", "tls"} → status = ✗; tracker = "DOWN"; issue = "{id} (unverified)"; mode = "FAIL".
   - error_type == "unknown" → status = ✗; tracker = "ERROR"; mode = "FAIL".

f. Print the banner (exact format above) BEFORE running ANY further git or MCP commands.
   The banner is the user's contract: it states what is about to happen.

### 2. Common pre-flight (mode-independent)

Run regardless of mode (except FAIL):

- `git log {base_branch}..HEAD --oneline` — if zero commits → "No changes to publish" + STOP.
- Check whether an open PR already exists for current_branch — if yes → "PR already exists: {URL}" + STOP.

### 3. Branch on mode

- mode = "full-publish":
    Dispatch `ceos-agents:publisher` (haiku) → commit → push → PR → tracker state transition →
    tracker comment with PR link. Fire `pr-created` webhook if configured.

- mode in {"pr-only-no-id", "pr-only-404"}:
    Dispatch `ceos-agents:publisher` (haiku) with context flag `pr_only=true` →
    commit → push → PR. SKIP tracker state transition. SKIP tracker comment.
    Still fire `pr-created` webhook if configured (issue_id field = null or "{id}-not-found-in-tracker").

- mode = "FAIL":
    Print FAIL guidance:
        "Tracker {tracker_type} is unreachable ({error_type}).
         Cannot verify issue '{issue_id}'. Stopping to prevent silent half-publish.
         Recovery options:
           1. Retry once the tracker is reachable: /ceos-agents:publish
           2. Diagnose with /ceos-agents:check-setup
           3. (Stretch) Watch the tracker-down webhook: see Notifications below."
    EXIT non-zero (no PR created, no commits modified).
    Fire `tracker-down` webhook if configured (see Stretch ideas).
```

### Why this implementation wins (innovation argument)

1. **Banner-first = the user's mental model is correct from line 1.** A 5-year power-user runs `/publish` 30+ times a week. The banner replaces the cognitive cost of "what mode will this be?" — they read 3 lines and KNOW.

2. **Same publisher agent, smarter dispatcher.** The publisher agent (haiku) gets a small context flag `pr_only=true` and skips tracker steps. We do NOT fork the agent. We do NOT add a config key. We do NOT touch `agents/publisher.md` Step 6 logic — only Step 7 conditionally skips when `pr_only=true`.

3. **Deterministic 4-mode output.** Banner format is part of the contract. External tooling (CI, autopilot, observability) can pattern-match the leading symbol (`✓`/`⚠`/`✗`/`ℹ`) for machine-readable status WITHOUT adding a `--format json` flag.

4. **Tracker-down is loud, not silent.** Per spec: tracker down = FAIL, not fallback. The banner says `✗ tracker:DOWN` in plain text — the user cannot miss it.

5. **Reuses v6.8.1 regex contract.** Issue-ID extraction uses the proven `^[A-Za-z0-9#._-]+$` regex from 4 existing skill sites. No new parsing logic invented.

### Edge case coverage (anticipates Persona C's challenges)

- **Pre-existing branch with no MCP configured** (Persona C's case): Step 0 MCP pre-flight at `skills/publish/SKILL.md:13-17` already STOPs with "Cannot connect to your {Type} issue tracker. Run /ceos-agents:check-setup". This fires BEFORE Step 1 banner. So the answer is: same fail-mode as tracker-down, with the same recovery guidance.

- **CI/cron context, no MCP**: Step 0 STOPs the same way — auto-detect cannot run, FAIL message points to setup-mcp. Per spec: no `--no-tracker` flag.

- **Future tracker type (e.g., Asana)**: prefix-scan in `core/mcp-detection.md` is generic — if `mcp__asana__*` tools are present, auto-detect works without code change. If `Type = asana` but no `mcp__asana__*` tools → Step 0 STOPs (clean fallback).

- **Branch naming pattern with no `{issue-id}` placeholder** (e.g., `release/v1.0`): residue extraction returns null → mode = pr-only-no-id. Banner shows `ℹ no_issue_id`. PR proceeds. Honest behavior.

---

## Dimension 2 — Migration UX (first run after upgrading from v6.10.0 → v7.0.0)

### Core idea: extend `/migrate-config` to auto-detect v6.x → v7.0.0 patterns

The existing `/migrate-config` skill already detects v1.x/v2.x/v3.0/v3.1 — extend it with **v6.10.0 → v7.0.0** detection logic. The user's first hint that v7.0.0 ships is when they run any pipeline skill and get a 1-line nudge:

```
ℹ ceos-agents v7.0.0 detected. Your CLAUDE.md may reference deprecated config.
   Run /ceos-agents:migrate-config to auto-fix in 2 seconds. (1-time, optional)
```

This nudge is emitted by `core/config-reader.md` ONCE per session when:
- An `Extra labels` section is detected, OR
- An `## Automation Config` block exists but no v7.0.0 marker (e.g., a sentinel comment `<!-- ceos-agents-config-version: 7 -->`).

The nudge is INFORMATIONAL. The pipeline still proceeds (it just ignores `Extra labels` silently — `pr_rules.extra_labels` is no longer parsed). The user is not blocked.

### `/migrate-config` v7 extension

Add Step 6 to `skills/migrate-config/SKILL.md`:

```markdown
### 6. Detect v6.x → v7.0.0 deprecations

Scan CLAUDE.md for v7.0.0 deprecations:

| Pattern | Detection | Auto-fix |
|---------|-----------|----------|
| `### Extra labels` section present | Section heading match | MERGE labels into `PR Rules → Labels`, DELETE the `### Extra labels` section. Show diff before write. |
| `Pause Limits` row in `automation-config.md`-style "Used By" column says only `/autopilot` | (Only if user mirrors the doc table in their own config — rare) | UPDATE to list all 6 lifecycle skills. |
| Custom Agents config still references `/ceos-agents:status` or `/ceos-agents:init` (string match) | Substring scan in shell hooks, custom agent paths | Print warning: rename to `pipeline-status`/`setup-mcp`. NO auto-fix (touching shell scripts is out of scope). |
| Saved aliases or shell completions referencing `/create-pr` | (Detected only if user explicitly opts in via `--scan-shell-history` flag) | Print: "/create-pr is removed. Use /publish — it auto-detects." NO auto-fix. |

If any v6.x→v7.0.0 deprecation is found:
  Display:
    "Detected v6.x config patterns. Auto-fix available:
     1. Merge `Extra labels` → `PR Rules → Labels` (label dedup applied)
     2. ... [other detected items]

     Confirm? [Y/n] "

If user confirms:
  Apply edits via the Edit tool.
  Add sentinel comment `<!-- ceos-agents-config-version: 7 -->` after the `## Automation Config` heading
    (suppresses future nudges).
```

### Label-merge logic (the delight detail)

When `Extra labels: Labels = [needs-review, hot-fix]` exists alongside `PR Rules: Labels = [bug, automated]`, the merge produces:

```
PR Rules:
  Labels = [bug, automated, needs-review, hot-fix]
```

with **automatic deduplication** (case-sensitive set union, order preserved: PR Rules labels first, then Extra labels not already present).

Show the diff:

```diff
 ### PR Rules
-| Labels | bug, automated |
+| Labels | bug, automated, needs-review, hot-fix |

-### Extra labels (optional)
-| Labels | needs-review, hot-fix |
```

Then ask `Apply this change? [Y/n]`.

### First-run banner on any pipeline skill

When the user runs `/fix-ticket`, `/fix-bugs`, `/implement-feature`, `/scaffold`, `/publish`, `/autopilot`, or `/check-setup` for the first time after upgrading to v7.0.0, `core/config-reader.md` emits:

```
[INFO] ceos-agents v7.0.0 — naming changes:
  /status → /pipeline-status   (collision with Claude Code builtin /status)
  /init   → /setup-mcp         (collision with Claude Code builtin /init)
  /create-pr → REMOVED         (use /publish; it auto-detects)
  Run /ceos-agents:migrate-config to clean up CLAUDE.md.
```

Once the sentinel comment is present (or user runs migrate-config to completion), the banner is suppressed.

---

## Dimension 3 — Stub-or-not decision

**Verdict: NO STUBS. Embrace the major bump.**

### Rationale (innovative stance)

1. **v7.0.0 is MAJOR per CLAUDE.md versioning policy.** Renaming user-facing skills IS a breaking change by definition. The whole point of MAJOR is "users update their muscle memory; we don't apologize for it."

2. **A 30-day stub adds permanent maintenance debt with zero learning value.** Users who type `/ceos-agents:status` after upgrade will see Claude Code's "skill not found" error — which is actually CORRECT and educational. They will check `/ceos-agents:` autocomplete, see `pipeline-status`, and learn the new name in one bounce. A stub denies them that signal.

3. **Stub adds frontmatter weight.** Every stub is a real `skills/{stub}/SKILL.md` that ships in the plugin. Plugin install size and the skill index both grow. The skill count would have to be reported as "28 active + 2 deprecated stubs = still 28? or 30?" — this creates a count-drift hazard that v6.9.0 painfully demonstrated.

4. **README + installation.md warning (Action 6) IS the migration path.** The user reads about the rename ONCE, then never again. Far better DX than a stub that prints "renamed to X" every time.

5. **`/migrate-config` extension (Dimension 2) catches the only programmatic bind point** — config files referencing the old names. Shell aliases and muscle memory are not the plugin's responsibility.

### Concession to safety: a single "skill-not-found nudge" in workflow-router

If the user types something the workflow-router parses as `/ceos-agents:status` or `/ceos-agents:init` or `/ceos-agents:create-pr`, the workflow-router's intent table can include a fallback prose line:

```markdown
**Did you mean:** If you typed `/ceos-agents:status`, the v7.0.0 name is `/ceos-agents:pipeline-status`.
                  If you typed `/ceos-agents:init`,   the v7.0.0 name is `/ceos-agents:setup-mcp`.
                  If you typed `/ceos-agents:create-pr`, use `/ceos-agents:publish` (it auto-detects).
```

This is a documentation insertion — NOT a stub skill. Workflow-router already exists; adding 4 lines costs nothing and catches users who use the workflow-router as a router rather than direct invocation.

---

## Dimension 4 — `/create-pr` removal vs `/publish --pr-only` flag

**Verdict: FULL DELETE. No flag. The auto-detect IS the feature.**

### Argument

1. **The spec is unambiguous.** Action 5: "Auto-detect tracker v `/publish` + smazat `/create-pr` skill." There is no flag. There is no opt-out. There is no soft-deprecation cycle.

2. **Adding `--pr-only` flag would re-introduce the very mode-decision the auto-detect eliminates.** Users would memorize "if branch has no issue ID, use `--pr-only`" — but the auto-detect already DOES that automatically. The flag adds vocabulary without adding capability.

3. **The 3-mode banner (Dimension 1) makes mode-prediction explicit.** Users see `mode:pr-only` in the banner before any commit lands. If they wanted PR-only on a branch with an issue ID that DOES exist, they shouldn't have named the branch with an issue ID. That's a branch-naming bug, not a flag-design bug.

4. **`/create-pr` had a pure-PR-creation use case for branches without issue IDs.** Auto-detect handles this: branch without issue ID → mode = pr-only-no-id → exactly the same behavior as the old `/create-pr`. No capability lost.

5. **Stub skill `/create-pr` that just dispatches `/publish`?** Same arguments as Dimension 3 — adds frontmatter weight, count drift, and pretends the rename is reversible. Reject.

### What the user actually loses

Nothing. Every `/create-pr` invocation maps 1:1 to `/publish` with auto-detect. The banner (Dimension 1) explicitly tells the user `mode:pr-only-no-id` when relevant — they never have to think about it.

### Edge case (Persona C anticipation)

User has a branch `hotfix/typo-readme` (no issue ID anywhere). Old: `/create-pr` → PR created. New: `/publish` → banner says `ℹ no_issue_id mode:pr-only` → PR created. Identical outcome.

---

## Dimension 5 — Tracker-down failure UX

### Core idea

The FAIL message is a **3-line block** with surgical recovery guidance. No emoji clutter, no animated spinners, just the truth.

### Exact text

When `error_type ∈ {"timeout", "auth", "tls", "unknown"}`:

```
✗ Publish FAILED — tracker {Type} is {state}.

  Issue ID detected from branch: '{issue_id}' (could not verify against tracker).
  Reason: {error_type} ({short_error_summary})
  
  Why we stopped:
    Creating a PR without verifying the issue could leave the tracker and the
    repository out of sync. v7.0.0 prefers loud failure over silent half-state.
  
  Recovery options:
    1. Retry once tracker is reachable:   /ceos-agents:publish
    2. Diagnose tracker MCP setup:        /ceos-agents:check-setup
    3. Re-authenticate (if auth error):   /ceos-agents:setup-mcp
    4. Manual escape hatch:               git push -u origin {branch}
                                          (then create PR manually via your tracker UI)
```

Per error_type, customize the variable parts:

| error_type | {state} | Recovery emphasis |
|-----------|---------|-------------------|
| timeout | unreachable (network timeout) | Retry option 1 |
| auth | rejecting authentication (401/403) | setup-mcp option 3 |
| tls | rejecting TLS certificate | check-setup option 2 + cert review |
| unknown | reporting an unexpected error | Show full error in `Reason:` line + check-setup |

### What's deliberately omitted

- **No `--force` flag suggestion.** Per spec: no opt-outs. Manual escape hatch (option 4) is documented because it's git, not a plugin feature — users always have it.
- **No retry loop.** A retry-with-backoff would obscure the failure signal. The user explicitly re-runs `/publish` when they're ready.
- **No "skip tracker" mode.** Per spec: not allowed.

### Stretch idea: tracker-down webhook event `[STRETCH-1]`

Fire a new webhook event `tracker-down` (additive — minor version bump risk noted) on tracker FAIL:

```json
{
  "event": "tracker-down",
  "tracker_type": "{Type}",
  "error_type": "{timeout|auth|tls|unknown}",
  "issue_id_attempted": "{issue_id}",
  "branch": "{branch_name}",
  "timestamp": "{ISO8601}"
}
```

Why interesting:
- Observability dashboards (D10 family from v6.8.0) would gain a real signal for tracker outages, not just inferred-from-pipeline-failures.
- Operations team could alert on `tracker-down` count > N/hour — early detection of MCP server health issues.

Why `[STRETCH]`:
- Adding a new webhook event is technically additive (per CLAUDE.md webhook forward-compat rules), but cluttering the v7.0.0 cleanup release with a new event muddies the "C is cleanup, not features" framing.
- Could be deferred to v8.0.0 or v7.0.1 without harm.
- The `pipeline-completed` webhook with `outcome: failed` already covers this case at lower fidelity.

**Recommendation:** flag for judge consideration, default to "defer to v7.0.1 patch."

---

## Stretch ideas (clearly flagged)

### `[STRETCH-2]` Runtime deprecation banner on first use of old name

**Idea:** When user runs `/ceos-agents:status` post-upgrade, Claude Code shows a one-shot banner: "This skill was renamed to /ceos-agents:pipeline-status in v7.0.0."

**Honest assessment: IMPOSSIBLE without runtime support.** Claude Code does not provide a hook for "skill not found → show custom message." When a skill name is unrecognized, Claude Code emits its own "skill not found" error — there is no plugin-level interception.

**Possible workaround (also IMPOSSIBLE):** Ship a stub skill at `skills/status/SKILL.md` that prints the banner. But Dimension 3 argues against stubs on principle. And per spec Action 3: "smaž `skills/status/`."

**Mark as IMPOSSIBLE in judge consolidation.** Do not propose for v7.0.0.

### `[STRETCH-3]` Auto-fix shell aliases via migrate-config

**Idea:** `/migrate-config --scan-shell-history` would grep `~/.bash_history`, `~/.zsh_history`, and `~/.config/fish/fish_history` for `/ceos-agents:status`, `/ceos-agents:init`, `/create-pr` and offer to rewrite them.

**Honest assessment:** Plugin shell-history rewriting crosses a trust boundary. Even with `--scan-shell-history` opt-in, modifying user shell history is high-risk for low value (the user types ~5 commands/day; muscle-memory adjustment takes a week regardless of help).

**Mark as `[STRETCH]` and recommend NOT shipping.** Documentation in README (Action 6) is sufficient.

### `[STRETCH-4]` Banner color/emoji configurability

**Idea:** Some users dislike the unicode `✓ ⚠ ✗ ℹ`. Allow a config key `Banner Style: ascii | emoji | unicode` (default unicode).

**Mark as IMPOSSIBLE per spec — Action 5 explicitly forbids new config keys.** Drop entirely. Use unicode; users on terminals that don't render it see boxes, which is also informative.

### `[STRETCH-5]` `/publish --dry-run` showing the banner without acting

**Idea:** Add `--dry-run` flag to `/publish` that runs Step 1 (banner) and STOPs without executing Step 3.

**Honest assessment:** Useful for a power-user verifying auto-detect logic on a complex branch. BUT:
- Spec forbids new flags on `/publish` (interpreted strictly: "no `--no-tracker` flag" — but a `--dry-run` is closer to safe).
- Could be deferred to v7.1.0 as feature.

**Mark as `[STRETCH]` with mild recommendation: defer to v7.1.0 if user-demand emerges.**

---

## Summary table (Persona B's all-up choices)

| Dimension | Persona B choice | Rationale |
|-----------|-----------------|-----------|
| 1. Action 5 implementation | Banner-first 4-mode auto-detect, single publisher agent with `pr_only=true` flag | Maximum user clarity, zero new agents, reuses v6.8.1 regex |
| 2. Migration UX | Extend `/migrate-config` (v6→v7 detection + label-merge auto-fix) + 1-line nudge from `core/config-reader.md` until sentinel comment present | Active migration path, not just docs |
| 3. Stubs | NO STUBS. Skill-not-found is educational. Add fallback prose to workflow-router only. | Embrace the MAJOR; reject permanent debt |
| 4. `/create-pr` removal | FULL DELETE. No `--pr-only` flag. Banner makes mode explicit. | Auto-detect IS the feature |
| 5. Tracker-down UX | 3-line FAIL block with 4 recovery options + `[STRETCH-1]` tracker-down webhook | Loud failure, no silent half-state |

**Stretch ideas flagged: 5 total.**
- `[STRETCH-1]` tracker-down webhook — defer to v7.0.1
- `[STRETCH-2]` runtime deprecation banner — IMPOSSIBLE (no Claude Code hook)
- `[STRETCH-3]` shell-history rewriting — `[STRETCH]`, recommend NOT shipping
- `[STRETCH-4]` banner-style config key — IMPOSSIBLE (spec forbids new config keys)
- `[STRETCH-5]` `/publish --dry-run` — defer to v7.1.0 if demand
