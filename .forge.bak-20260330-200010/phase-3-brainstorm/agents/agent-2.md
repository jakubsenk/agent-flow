# Phase 3 Brainstorm — Agent 2 (UX Designer)
# v5.6.1 UX Polish: Innovative Design Proposals

**Date:** 2026-03-30
**Role:** Innovative UX Designer — pushing for the best user experience

---

## Item 1: --infra Flag Format

### Current state (the problem)

```
--infra ready,later
```

Positional, opaque. User must memorize "first = tracker, second = SC." If they write `--infra later,ready`, it silently does the opposite of what they intended. No feedback until Step 0-INFRA runs.

### My recommendation: named key-value pairs, order-independent, partial allowed

**Primary format:**
```
--infra tracker:ready,sc:later
--infra sc:ready,tracker:later      ← same result, order doesn't matter
--infra tracker:ready               ← SC defaults to "later" (omission = later)
--infra sc:ready                    ← tracker defaults to "later"
```

**Design rationale:**
- Named keys eliminate positional ambiguity completely — no memorization required
- Order-independent parsing is natural for named pairs; users write them in whatever order they think of them
- Partial specification (omit a key = "later") reduces typing for the common case "I only have a tracker, not an SC remote yet"
- Existing documentation examples (`--infra tracker:ready,sc:later`) are fully self-describing — readable six months later without checking docs

**Validation regex (new):** Each token matches `(tracker|sc):(ready|later)`. Both keys are optional. Duplicates are rejected.

**New error message:**
```
Invalid --infra value. Use key:value pairs: --infra tracker:ready,sc:later
Keys: tracker, sc   Values: ready, later   (omitted key defaults to "later")
Examples:
  --infra tracker:ready,sc:ready   — both configured
  --infra tracker:ready            — tracker only, SC set up later
  --infra sc:later                 — explicitly defer SC (same as omitting sc key)
```

The multi-line error is deliberate. A format this composable deserves a small example set — one line would force the user to guess the rules.

**--issue conflict error (updated):**
```
--issue requires tracker access. Set --infra tracker:ready or remove --issue.
```

Shorter, actionable, no confusing `{sc}` placeholder that users might take literally.

### What about shorthands?

I considered `--infra ready` meaning "both ready" and `--infra later` meaning "both later." I recommend **against shorthands** for this release.

Reasons:
- Shorthands require a third parsing branch (no-colon = shorthand) that adds ambiguity: does `--infra ready` mean "both" or "I mistyped `tracker:ready`"?
- The common "both ready" case is already short: `--infra tracker:ready,sc:ready` is 32 characters — not painful
- Shorthands can always be added in a later MINOR release once the named-key format is established
- Power users who want brevity can alias the command in their shell

**If shorthands are added later**, the right design is `--infra all:ready` and `--infra all:later` — using the same key:value grammar, not a magic bare word.

---

## Item 2: Canary-Write Announcement

### Current state (the problem)

The canary-write happens silently. The user sees nothing between "I have a tracker project ready" and either the success continuation or a write-access warning. If they glance away and come back, they have no idea what just happened to their tracker.

Worse: the canary creates and deletes a real item in the user's tracker. Creating something in a user's external system without telling them is a UX anti-pattern — it erodes trust.

### Architecture constraint

Step 0-MCP runs **before** mode selection (Step 0). Mode is not yet known when canary-write runs. This eliminates interactive-vs-YOLO gating at the announcement point.

### My recommendation: a single clear announcement, always shown

The announcement goes in `commands/scaffold.md` Step 0-MCP, immediately before `core/mcp-detection.md` is called with `check_write: true`. The core contract stays unchanged.

**Exact text:**
```
Verifying write access to your {tracker_type_display} tracker — a test item will be
created and immediately deleted to confirm permissions.
```

Where `{tracker_type_display}` is the capitalized display name (YouTrack, GitHub, Jira, etc.).

**Design rationale:**
- "test item will be created and immediately deleted" — no surprises. User knows exactly what is about to touch their system.
- Present tense ("will be") signals imminent action, not a past fact
- One sentence, no confirmation prompt — Step 0-MCP is already past the point where the user declared "tracker: ready." They consented to tracker integration at that point. The announcement informs; it doesn't re-ask consent.
- No "please wait" or spinner language — this is a markdown instruction set, not an interactive terminal UI

**Why not ask for confirmation?**
A confirmation prompt ("Testing write access — OK? [Y/n]") would be wrong here for two reasons:
1. Mode is not known yet, so we can't skip the prompt in YOLO modes
2. The user already confirmed tracker readiness at Step 0-INFRA — a second prompt is redundant friction

The right model is "inform, then act" — not "ask, then act." The announcement achieves transparency without blocking the happy path.

**Where in scaffold.md to insert:**

After line 143 (`check_write = true`), before `core/mcp-detection.md` delegation. Specifically, the instruction block becomes:

```
   - `check_write` = `true` (for tracker only — SC does not need write check)
   - Before calling `core/mcp-detection.md`: Display:
     `Verifying write access to your {tracker_type_display} tracker — a test item will be created and immediately deleted to confirm permissions.`
```

`tracker_type_display` is derived from the display name mapping established in Item 3 below.

---

## Item 3: MCP Jargon Replacement

### Current state (the problem)

"MCP server for {type} not available" is internal plugin vocabulary. Users don't configure "MCP servers" — they connect their tools. The error tells them what failed at the wrong level of abstraction. Worse, it doesn't tell them what to do.

### My recommendation: three distinct message patterns, one mapping table

**Pattern 1 — Connection failure (interactive, non-YOLO):**

Current (line 146):
```
MCP server for {type} not detected in current session.
```

Replacement:
```
Cannot connect to your {tracker_type_display} {service_label} right now.
```

Where `{service_label}` is "issue tracker" for trackers and "repository host" for SC. Full context example:
```
Cannot connect to your Gitea issue tracker right now.
```

This is followed by the existing guidance block (package name, env vars, `/ceos-agents:init` note) — that part stays, it's already helpful.

**Pattern 2 — YOLO block comment Detail field (line 159):**

Current:
```
Detail: --issue requires tracker MCP to fetch issue description. MCP server for "{tracker_type}" is not available. In YOLO mode, there is no interactive fallback to ask for a project description.
```

Replacement:
```
Detail: --issue requires a live connection to your {tracker_type_display} tracker to fetch the issue description. The tracker is not reachable in this session. In YOLO mode, there is no interactive fallback to ask for a project description.
```

The block comment is read by humans debugging a pipeline failure. "Not reachable in this session" is more diagnostic than "not available."

**Pattern 3 — YOLO auto-downgrade (line 163):**

Current:
```
MCP for {type} not available — downgrading to "later".
```

Replacement:
```
{tracker_type_display} not reachable — treating infrastructure as "set up later".
```

"Treating infrastructure as 'set up later'" explains the consequence in plain language. Users don't know what "downgrading" means without context.

**Pattern 4 — Standard stop error (scaffold.md line 751, resume-ticket.md line 72):**

Current:
```
MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure.
```

Replacement:
```
Cannot reach your {tracker_type_display} {service_label}. Run `/ceos-agents:check-setup` to diagnose or `/ceos-agents:init` to reconfigure.
```

"Cannot reach" is concrete. "Diagnose" and "reconfigure" are action verbs that tell the user what each command actually does.

### Display name mapping table

Add this as a lookup inline in scaffold.md Step 0-MCP (it is used in 4+ places, better to define once):

| Internal type | Display name | Service label |
|---------------|-------------|---------------|
| `youtrack` | `YouTrack` | `issue tracker` |
| `github` | `GitHub` | `issue tracker` |
| `jira` | `Jira` | `issue tracker` |
| `linear` | `Linear` | `issue tracker` |
| `gitea` | `Gitea` | `issue tracker` |
| `redmine` | `Redmine` | `issue tracker` |
| `github` (SC) | `GitHub` | `repository host` |
| `gitea` (SC) | `Gitea` | `repository host` |
| `gitlab` (SC) | `GitLab` | `repository host` |

When `{tracker_type_display}` is referenced in a message, resolve via this table. For unknown types, fall back to the raw type string.

### Scope: scaffold.md + resume-ticket.md only (not all 15 files)

The phase-0 research confirmed the standard pattern appears in 15 command files. My recommendation for v5.6.1: **fix scaffold.md and resume-ticket.md only.**

Rationale:
- These are the two files in scope for this release
- A cross-codebase find-replace of 15 files is a MINOR feature, not a PATCH polish item — it changes user-visible output in every pipeline command
- The correct approach for the broader fix is to define a **shared display constant** (e.g., in a new `core/error-messages.md` contract) and have all commands reference it — but that is architecture work for v5.7.0
- v5.6.1 establishes the correct pattern in scaffold.md; future cleanup follows the established pattern

This scoping keeps v5.6.1 as a true PATCH (behavior fix, no contract change) and avoids scope creep.

---

## Item 4: Resume --infra Override

### Current state (the problem)

User scaffolds a project, declares `tracker: later`. Two days later they set up their Gitea instance. They want to resume the scaffold with tracker now ready — but they can't pass `--infra tracker:ready` to scaffold, because on resume the flag is ignored and state is always restored verbatim from state.json.

The only workaround is to manually edit state.json — which defeats the purpose of having a resume mechanism.

### Architecture finding (from research)

The resume lives in `scaffold.md` line 126 ("On resume"), NOT in `resume-ticket.md`. The resume-ticket command doesn't support scaffold pipelines at all. Changes are confined to scaffold.md only.

### My recommendation: override with re-verification

**Trigger:** `state.json` exists AND `--infra` flag is provided on the resume invocation.

**Behavior (the "On resume with --infra override" block):**

1. Parse `infra_preset` from `--infra` (using the new named-key format from Item 1)
2. Compare parsed values against `state.json` infrastructure fields
3. If any value differs:
   - Display a diff-style summary of what is changing:
     ```
     Infrastructure override detected:
       tracker: later → ready   (changed)
       sc:      later → later   (unchanged)
     ```
   - For each service whose status changed TO "ready": ask for details that may be missing from state (tracker type, instance URL, project key, remote, base branch)
   - For details already present in state.json: use stored values as defaults, let user confirm or change
   - Update state.json with new values (atomic write)
   - Re-run Step 0-MCP for services whose status changed
4. If no values differ: display `--infra flag matches existing state — no override needed.` and continue normal resume

**Display message:**
```
Infrastructure override detected:
  tracker: later → ready   (changed)
  sc:      later → later   (unchanged)

Collecting details for your {tracker_type_display} tracker...
```

**Design rationale for the diff display:**

A terse "using new values" message tells the user nothing. The diff-style display shows exactly what changed, which matters because:
- The user may have mistyped the flag — they can abort before providing details
- If both values are unchanged, they get explicit confirmation that the flag had no effect (no silent no-op)
- Power users running scaffold in automation scripts can see the override in logs

**Why re-run Step 0-MCP?**

When a service changes from "later" to "ready", the MCP has not been verified for this session. Skipping verification would allow the pipeline to proceed with an untested connection, leading to failures at Step 4e. Re-running Step 0-MCP is mandatory — the overhead is two tool calls and is worth the correctness guarantee.

**Edge case: changing from "ready" to "later"**

If the user passes `--infra tracker:later` when the previous state had `tracker: ready`, this means they want to abandon tracker integration for this run. The override should:
- Null out tracker detail fields in state.json (`tracker_type`, `tracker_instance`, `tracker_project`)
- Set `tracker_effective_status = "later"`
- Display: `Tracker integration removed. Steps 4e (tracker issues) will be skipped.`
- NOT re-run Step 0-MCP for the tracker (nothing to verify for a "later" service)

This edge case is uncommon but has a valid use case (e.g., the tracker project was deleted or the user changed their mind).

**What NOT to do: auto-detect infrastructure changes**

An alternative design would auto-detect when state.json infrastructure is stale by probing MCP at resume time. I recommend against this because:
- It would re-run MCP checks on every resume even when nothing changed
- It removes user control — the user should explicitly declare "I changed my infrastructure"
- Auto-detection would require the same detail-collection flow anyway, adding complexity without benefit

The `--infra` flag is the right mechanism: explicit, composable with the new named-key format.

---

## Cross-Cutting: Display Name Consistency

All four items reference `{tracker_type_display}`. This should be defined once in scaffold.md as a lookup table (proposed in Item 3 above) and referenced by name in all display strings. This avoids repeating the mapping in every message.

The variable `tracker_type_display` is set from `tracker_type` using the lookup table immediately after `tracker_type` is known (Step 0-INFRA). All subsequent steps use `tracker_type_display` in user-facing strings and `tracker_type` in internal logic (API calls, config values).

---

## Summary Table

| Item | Key Design Decision | Recommendation |
|------|-------------------|---------------|
| --infra format | Named keys or positional? | Named keys, order-independent, partial allowed (omission = "later") |
| --infra shorthand | `--infra ready` = both ready? | No shorthand — adds parsing ambiguity; add `all:ready` in future MINOR if needed |
| Canary announcement | Inform or ask? | Inform only — consent was given at Step 0-INFRA; no redundant prompt |
| Canary announcement | Where? core or scaffold? | scaffold.md only — core stays a pure logic contract |
| MCP jargon scope | All 15 files or targeted? | scaffold.md + resume-ticket.md only; broader fix is v5.7.0 with shared error constants |
| Resume override | Where? resume-ticket.md or scaffold.md? | scaffold.md "On resume" block — resume-ticket.md doesn't support scaffold at all |
| Resume override | Behavior on "ready → later"? | Null detail fields, skip Step 0-MCP for that service, display consequence clearly |
