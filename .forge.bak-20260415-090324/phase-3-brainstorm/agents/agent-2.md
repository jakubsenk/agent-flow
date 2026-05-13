# Agent 2 — The Innovative Pipeline Architect

## Position Statement

Bug 1 and Bug 2 are symptoms of the same architectural gap: the pipeline lacks **post-execution verification contracts** for MCP interactions. Every status-set is fire-and-forget. Every multi-line MCP payload is passed with zero encoding guidance. The codebase has 11 core contracts, but none of them address the two most common MCP failure modes: "did the state actually change?" and "did the body render correctly?"

I want to fix both bugs AND close the systemic gap — but within PATCH bounds. No config contract changes. No new required keys. No new agent definitions. Just two new core contracts that codify patterns the pipeline should have had from the start, plus surgical edits to the existing files that reference them.

---

## Part 1: Universal Status Verification — `core/status-verification.md`

### The Problem Beyond Redmine

The research confirms 7 status-setting call sites, ALL fire-and-forget. The Redmine bug (status names vs. numeric IDs) is the presenting symptom, but the underlying disease is: **no call site ever checks whether the status actually changed.** A YouTrack instance with a custom workflow that rejects certain transitions will silently fail. A Jira instance where the user's token lacks transition permissions will silently fail. A Gitea instance where the label doesn't exist will silently fail. All of these produce the same user experience: the pipeline reports success, but the issue is stuck in the wrong state.

### Proposed Contract: `core/status-verification.md`

```
# Status Verification

## Purpose

Verify that an issue tracker status transition succeeded. Provides a read-back
check after any status-set MCP call. Single source of truth for status
verification logic — prevents silent failures across all tracker types.

## Input Contract

| Field | Type | Notes |
|-------|------|-------|
| tracker_type | string | From config: youtrack, github, jira, linear, gitea, redmine |
| issue_id | string | Issue tracker ID |
| expected_state | string | The target state value that was just set |
| transition_syntax | string | The raw syntax used (e.g., `status:In Progress`, `add label:in-progress`) |

## Process

1. **Read-back:** After the status-set MCP call, read the issue's current state
   from the tracker via the same MCP server.

2. **Verify match:** Compare the current state against expected_state.
   - For label-based trackers (github, gitea): check that the expected label
     exists on the issue.
   - For state-based trackers (youtrack, jira, linear): check that the current
     state name matches expected_state (case-insensitive).
   - For redmine: check that the current status name matches expected_state
     (case-insensitive). If the MCP response includes status_id, log it for
     diagnostic purposes.

3. **On mismatch:** Log a WARNING (never block):
   WARN: Status transition may have failed for {issue_id}.
   Expected: {expected_state}. Current: {actual_state}.
   Syntax used: {transition_syntax}.

4. **On read-back failure:** Log a WARNING (never block):
   WARN: Could not verify status transition for {issue_id}: {error}.
   The transition may have succeeded — verification is advisory.

## Output Contract

- verified: boolean (true if read-back matches, false if mismatch or read failure)
- actual_state: string or null
- warning: string or null

## Failure Handling

- Read-back MCP call failure: return verified=false, warning with error.
  NEVER block the pipeline on verification failure.
- Mismatch: return verified=false with diagnostic warning.
  NEVER block — status verification is advisory.
- This contract is fire-and-warn, never fire-and-block.
```

### Why This Is PATCH-Safe

- No new config keys. No new required sections. No changes to the config contract.
- No new agents. This is a core contract — a shared instruction set, not a new Task dispatch.
- No behavioral change for successful transitions. The pipeline only gains a WARNING on failure — no existing workflow is altered.
- Advisory-only (fire-and-warn). Even if the verification itself fails (MCP call error), the pipeline continues. Zero risk of introducing new block scenarios.
- The "Follow `core/status-verification.md`" reference pattern is already established by 11 existing core contracts.

### Integration Points

Add `Follow core/status-verification.md after the status-set call` to these locations:

| # | File | What to add |
|---|------|-------------|
| 1 | `skills/fix-ticket/SKILL.md` Step 1 | After "Set the state per Automation Config" — add read-back |
| 2 | `skills/implement-feature/SKILL.md` Step 1 | After "Set the state per Feature Workflow → On start set" — add read-back |
| 3 | `agents/publisher.md` Step 7 | After "Set issue state: For Review" — add read-back |
| 4 | `core/block-handler.md` Step 2 | After "Transition the issue to the Blocked state" — add read-back |
| 5 | `core/fix-verification.md` Step 6 | After "set the issue state back" — add read-back |
| 6 | `skills/fix-bugs/SKILL.md` Block Handler Step 2 | After "Set issue state to Blocked" — add read-back |
| 7 | `skills/scaffold/SKILL.md` Step 8b | After each "Transition to Done" — add read-back |

Each integration is a 1-2 line addition: "After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded."

### But What About the Actual Redmine Bug?

The status verification contract catches the SYMPTOM (transition didn't stick). The ROOT CAUSE for Redmine is the `status:{name}` format. I propose fixing this in `docs/reference/trackers.md` by adding a Redmine-specific instruction note — not changing the format, but adding explicit guidance:

In `docs/reference/trackers.md`, State Transition Syntax table, expand the Redmine note:

```
> **Redmine note:** The `status:{name}` format is an LLM convention. The LLM
> translates this to the appropriate Redmine API call. **When making the MCP
> call, the LLM MUST resolve the status name to a numeric status_id by first
> calling the Redmine issue statuses endpoint (GET /issue_statuses.json) to
> obtain the name→ID mapping, then using status_id in the update call.** Status
> name-to-ID mapping depends on the Redmine instance configuration.
>
> If the statuses endpoint is not available via MCP, fall back to common
> defaults: New=1, In Progress=2, Resolved=3, Closed=5. Log a WARN if using
> defaults.
```

This is a documentation enhancement (PATCH), not a format change (MAJOR). The config value stays `status:In Progress`. The LLM resolution instruction is in `trackers.md`, which is already the "single source of truth for all tracker-specific values" per its own header. All call sites that reference the tracker type already have access to this file's conventions.

### Additional Fix: Redmine Config Templates

Update the two Redmine config templates to include a comment explaining the resolution:

- `examples/configs/redmine-rails.md`
- `examples/configs/redmine-oracle-plsql.md`

In the State transitions value, add an inline comment or expand the Redmine note reference:

```
| State transitions | In Progress: `status:In Progress`, Blocked: `status:Blocked`, For Review: `status:Resolved`, Done: `status:Closed` |
```

No format change — just ensure the existing values match common Redmine status names. The `trackers.md` note handles the name→ID resolution instruction.

---

## Part 2: Universal MCP Parameter Formatting — `core/mcp-body-formatting.md`

### The Problem Beyond Publisher

5 vulnerable multi-line MCP call sites, zero encoding guidance. The publisher's literal `\n` bug is the presenting symptom, but the underlying disease is: **no shared convention for how multi-line content should be passed to MCP tool parameters.** Every call site independently constructs its body string, and no contract tells the LLM what format the MCP server expects.

The key insight from the research: the single encoding-aware site (`core/post-publish-hook.md` heredoc) is for a Bash `curl` call, not an MCP tool parameter. These are fundamentally different contexts. MCP tool parameters are structured JSON — the MCP protocol serializes parameters as JSON objects. The LLM needs to understand that when it passes a multi-line string to an MCP tool parameter, the MCP client handles JSON serialization. The LLM should pass the string with actual newline characters, NOT with escaped `\n` literals.

### Proposed Contract: `core/mcp-body-formatting.md`

```
# MCP Body Formatting

## Purpose

Ensure correct formatting of multi-line string parameters passed to MCP tools
(issue descriptions, PR descriptions, comments). Prevents literal `\n` rendering
and other encoding artifacts.

## Scope

Applies to ALL MCP tool calls that accept a multi-line text body parameter:
create_pull_request (body/description), create_issue (description/body),
add_comment/create_comment (body/content), update_issue (body/description).

## Rules

1. **Use real newlines, not escape sequences.** When constructing multi-line
   content for an MCP tool parameter, use actual line breaks in the string value.
   Do NOT use literal `\n` escape sequences — these will render as visible `\n`
   text in the tracker, not as line breaks.

2. **Markdown formatting is safe.** MCP tool parameters accept markdown. Use
   headings (#, ##), bold (**text**), bullet lists (- item), and code blocks
   (```). The MCP client preserves markdown formatting.

3. **No double-encoding.** Do NOT JSON-escape the body string before passing it
   to the MCP tool. The MCP client handles JSON serialization automatically.
   Manually escaping quotes or backslashes will cause double-encoding artifacts.

4. **Template expansion.** When filling a multi-line template (e.g., PR
   Description Template, Block Comment Template), expand template variables
   first, then pass the complete expanded string as the MCP parameter value.
   Do not attempt to build the string incrementally via multiple MCP calls.

## Anti-Patterns

- `body: "Line 1\nLine 2\nLine 3"` — WRONG (literal \n characters)
- `body: "Line 1\\nLine 2\\nLine 3"` — WRONG (escaped literal \n)
- `body: JSON.stringify(template)` — WRONG (double-encoding)

## Correct Pattern

Pass the multi-line string directly as the parameter value with real line breaks.
The MCP client serializes it correctly.

## Failure Handling

If the MCP tool returns an error mentioning formatting or encoding, do NOT retry
with escaped characters. Report the error as-is — the problem is likely in the
MCP server, not in the encoding.
```

### Why This Is PATCH-Safe

- No config keys changed. No new required sections. No contract changes.
- No new agents. This is behavioral guidance for existing agents.
- No behavioral change for sites that already work correctly. Sites that accidentally use literal `\n` will now use real newlines — this is a bug fix, not a feature change.
- The contract is a reference document, not an execution contract. It has no Process steps that alter pipeline flow. It is a formatting convention, like a style guide.

### Integration Points

Add `Follow core/mcp-body-formatting.md for multi-line MCP parameters` to these locations:

| # | File | What to add |
|---|------|-------------|
| 1 | `agents/publisher.md` Constraints | Add constraint: "When passing multi-line strings to MCP tools (PR description, issue comments), follow `core/mcp-body-formatting.md`. Use real newlines, never literal `\n` escape sequences." |
| 2 | `core/block-handler.md` Step 4 | Before the block comment template: "Format the comment body following `core/mcp-body-formatting.md`." |
| 3 | `skills/fix-ticket/SKILL.md` Step 4b-tracker | Before the subtask description template: "Format the description body following `core/mcp-body-formatting.md`." |
| 4 | `skills/implement-feature/SKILL.md` Step 5a | Same as #3 (byte-for-byte identical template). |
| 5 | `skills/fix-bugs/SKILL.md` Block Handler Step 4 | Before the block comment template: "Format the comment body following `core/mcp-body-formatting.md`." |

The publisher constraint is the most critical — it targets a haiku model, which needs the clearest possible instruction. Adding "Use real newlines, never literal `\n` escape sequences" directly in the Constraints section (in addition to the core contract reference) ensures the haiku model sees the instruction without having to follow a reference.

---

## Part 3: Scope Creep Analysis

### What I Am Proposing (PATCH-safe)

| Change | Type | Files touched | Risk |
|--------|------|---------------|------|
| New `core/status-verification.md` | New core contract (advisory) | 1 new file | LOW — advisory only, no new blocks |
| New `core/mcp-body-formatting.md` | New core contract (guidance) | 1 new file | LOW — formatting convention, no execution change |
| `trackers.md` Redmine note expansion | Doc enhancement | 1 edit | LOW — adds resolution instruction, no format change |
| 7 status-verification references | 1-2 line additions | 7 edits | LOW — each is "Follow core/X after the set call" |
| 5 body-formatting references | 1-line additions | 5 edits | LOW — each is "Follow core/X" |
| Publisher Constraints addition | 1-line addition | 1 edit | LOW — explicit haiku-friendly instruction |
| Redmine config template clarity | Comment/note additions | 2 edits | LOW — no value changes |
| CLAUDE.md core count update | Number update (11 → 13) | 1 edit | TRIVIAL |
| Roadmap bug entries marked done | Status update | 1 edit | TRIVIAL |

**Total: 2 new files, ~18 edits across existing files. All edits are 1-3 lines each.**

### What I Am NOT Proposing (would be scope creep)

- Changing `status:{name}` to `status_id:{id}` format in trackers.md (MAJOR — breaks existing configs)
- Adding a new `### Status Resolution` required config section (MAJOR — new required key)
- Adding tracker-type branching to every call site (architectural change, not PATCH)
- Adding `On start set` to fix-bugs (functional gap fix, should be its own ticket)
- Modifying `core/config-reader.md` to normalize status values at parse time (changes config-reader contract)
- Adding MCP access to the onboard wizard (changes allowed-tools, which is a design decision)
- Adding `migrate-config` rules for status_id migration (requires interactive sub-step, MINOR scope)

### The Value Proposition

| Without these contracts | With these contracts |
|------------------------|---------------------|
| Redmine status transitions silently fail | Redmine LLM resolves name→ID per `trackers.md` instruction; verification warns on failure |
| YouTrack/Jira/Linear silent failures undetected | All trackers get advisory verification — first-ever post-set check |
| Publisher literal `\n` in PR descriptions | Explicit formatting guidance prevents the bug |
| Same `\n` bug latent in 4 other call sites | All 5 vulnerable sites get formatting guidance |
| Next developer adds a new status-set call site — same bug | New developer follows established `core/status-verification.md` pattern |
| Next developer adds a new MCP body call site — same bug | New developer follows established `core/mcp-body-formatting.md` pattern |

The contracts are **prophylactic infrastructure.** They cost ~40 lines each to define, ~1 line each to reference, and they prevent an entire class of bugs from recurring. The 11 existing core contracts already established this pattern — adding 2 more is architecturally consistent.

---

## Part 4: How These Integrate With Existing Architecture

### Core Contract Dependency Graph (Current)

```
config-reader ← [all pipeline skills]
mcp-preflight ← mcp-detection ← [scaffold, init, check-setup]
block-handler ← [fix-ticket, fix-bugs, implement-feature, scaffold]
fixer-reviewer-loop ← [fix-ticket, fix-bugs, implement-feature, scaffold]
state-manager ← [all pipeline skills]
fix-verification ← [fix-ticket, fix-bugs, implement-feature]
post-publish-hook ← [fix-ticket, implement-feature]
profile-parser ← [fix-ticket, fix-bugs, implement-feature]
agent-override-injector ← [all pipeline skills]
decomposition-heuristics ← [fix-ticket, fix-bugs, implement-feature]
```

### After Addition

```
status-verification ← [fix-ticket, fix-bugs, implement-feature, scaffold, publish]
                    ← [block-handler, fix-verification, publisher (agent)]
mcp-body-formatting ← [publisher (agent), block-handler]
                    ← [fix-ticket, fix-bugs, implement-feature]
```

Both new contracts are **leaf nodes** — they have no dependencies on other core contracts. They are referenced by existing contracts and skills/agents, but they do not reference anything themselves. This is the lowest-risk position in the dependency graph.

### Pattern Consistency

The integration follows the exact same pattern as existing core contracts:

- `core/mcp-preflight.md` is referenced as "Follow `core/mcp-preflight.md`" — same for new contracts.
- `core/block-handler.md` is referenced as "Follow `core/block-handler.md`" — same.
- `core/fix-verification.md` is referenced as "Follow `core/fix-verification.md`" — same.

No new referencing pattern is introduced. No new architectural concept is added. The plugin already has a `core/` layer for shared pipeline contracts — these two new contracts are natural additions to that layer.

---

## Summary

I am proposing a **systemic fix** that addresses both bugs AND prevents their entire class from recurring, while staying strictly within PATCH bounds:

1. **Bug 1 (Redmine status):** Fix the root cause via `trackers.md` Redmine note (LLM resolution instruction). Prevent the entire class via `core/status-verification.md` (advisory read-back for ALL trackers).

2. **Bug 2 (literal `\n`):** Fix the root cause via publisher Constraints addition + `core/mcp-body-formatting.md` reference. Prevent the entire class via `core/mcp-body-formatting.md` (formatting guidance for ALL MCP body calls).

3. **No scope creep:** 2 new leaf-node core contracts, 18 surgical edits (1-3 lines each), zero config contract changes, zero new agents, zero new required keys.

4. **Backward compatible:** `status:{name}` format is preserved. The Redmine note adds a resolution INSTRUCTION, not a format change. Existing configs continue to work.
