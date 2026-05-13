# Phase 2 Research Answers — Agent 1
# Categories A + B: Block Handler, Skill Step 1, Fix-Verification, Fix-Bugs, Trackers Reference, Config Reader, Redmine Templates

---

## A1: What exact MCP call does `core/block-handler.md` make to set the Blocked state?

**Source:** `core/block-handler.md` line 23 (Step 2)

```
2. **Set issue state:** Transition the issue to the Blocked state (from config → State transitions → Blocked) via the issue tracker MCP server.
```

**Answer:** The block-handler passes the raw config string verbatim. It reads `State transitions → Blocked` from the Automation Config object that was passed in as the `config` input (line 17: `config | object | Automation Config values: Error Handling, State transitions, Notifications`). It does **not** do any tracker-type resolution or normalization itself — it delegates the interpretation entirely to "the issue tracker MCP server". There is no tracker-type branching in this step. Whatever string value is stored under `State transitions → Blocked` in the config (e.g., `status:Blocked` for Redmine, `State: Blocked` for YouTrack) is passed directly to the MCP call.

**Key quote (line 23):**
> `Transition the issue to the Blocked state (from config → State transitions → Blocked) via the issue tracker MCP server.`

**Failure handling (line 53):**
> `State transition failure → log warning, continue.`

No MCP tool name is specified in block-handler — the tool name is implied by the tracker type the MCP server was initialized with.

---

## A2: Do `fix-ticket/SKILL.md` Step 1 and `implement-feature/SKILL.md` Step 1 have tracker-type branching?

### fix-ticket/SKILL.md Step 1

**Source:** `skills/fix-ticket/SKILL.md` lines 113–116

```
### 1. Set issue tracker

Set the state per Automation Config (Issue Tracker → On start set). Read Type for the correct MCP server.

*In dry-run: skip this step.*
```

**Answer:** No tracker-type branching. It is a raw passthrough: it reads the `On start set` value directly from the config and uses `Type` only to select which MCP server prefix to use (`mcp__youtrack__*`, `mcp__redmine__*`, etc.). The state value itself is passed verbatim — no per-tracker normalization.

### implement-feature/SKILL.md Step 1

**Source:** `skills/implement-feature/SKILL.md` lines 163–166

```
### 1. Set issue state

Read the issue from the issue tracker. Set the state per Feature Workflow → On start set
(fallback: Issue Tracker → On start set).
```

**Answer:** No tracker-type branching. Same raw passthrough pattern, with the additional logic of preferring `Feature Workflow → On start set` over the base `Issue Tracker → On start set`. The value read is passed directly to the MCP server — no per-tracker normalization.

**Conclusion for A2:** Both skills use raw passthrough. The difference is only that implement-feature has a Feature Workflow fallback chain; fix-ticket uses `On start set` directly. Neither has tracker-type branching at Step 1.

---

## A3: Does `core/fix-verification.md` Step 6 set issue state when re-opening?

**Source:** `core/fix-verification.md` lines 27–31

```
6. If command fails → post failure comment to the issue:
   [ceos-agents] ❌ Fix verification failed.
   Command: `{command}`
   Output: {first 500 chars}
   If State transitions contains a re-open key → set the issue state back. Display: "Fix verification failed. Issue re-opened." Return `FAILED`.
```

**Answer:** YES. Step 6 is a confirmed state-setting call site. It conditionally transitions the issue state back (re-opens) when verification fails, using the `State transitions` map from the Automation Config input. The condition is: `State transitions contains a re-open key`. This is a guard — not all configs will have a re-open key. The exact key name is not specified in the contract; it is inferred from whatever key in the State transitions map semantically means "re-open" for that tracker type.

**Input contract confirms access (line 7):**
> `config — Automation Config (Build & Test section — Verify command; Issue Tracker section — State transitions)`

This is the **only** non-block state-setting call site in fix-verification — Step 5 (success path) only posts a comment.

---

## A4: Does `skills/fix-bugs/SKILL.md` have its own status-setting or delegate to fix-ticket?

**Source:** `skills/fix-bugs/SKILL.md`

### Status-setting in fix-bugs

fix-bugs does **not** delegate to fix-ticket via Task. It is a standalone skill with its own full pipeline. After a full search for "On start set", "Set issue", and "issue state" in the file, the following status-setting call sites were found:

**1. No "Set issue state" step equivalent to fix-ticket Step 1.** The fix-bugs pipeline has no step that sets the issue state to "In Progress" (or the configured `On start set` value) before starting work on each bug. The step numbering goes: Step 1 (Fetch bugs) → Step 2 (Triage) → Step 3 (Code-analyst). There is no "Set issue tracker" step.

**2. Block handler (Step X) sets state to Blocked (line 642):**
```
2. **Set issue state to Blocked** (State transitions → Blocked)
```

**3. Fix-verification re-open (lines 593–601, step 8c):** Follows `core/fix-verification.md` — the re-open state-set from A3 applies here too.

**Architecture:** fix-bugs dispatches agents (triage-analyst, code-analyst, fixer, reviewer, test-engineer, publisher) individually via Task tool with its own step logic. It **never** calls `fix-ticket` via Task. It mirrors fix-ticket's pipeline steps but inline, with worktree/parallel-processing support as a key differentiator.

**Key finding:** fix-bugs is missing the "Set issue state to In Progress" that fix-ticket has at Step 1. This is a functional gap: bugs processed by fix-bugs do not get their tracker state set to In Progress when the pipeline starts (only blocked when blocked, or re-opened if fix-verification fails).

---

## A5: What does `docs/reference/trackers.md` specify for Redmine format?

**Source:** `docs/reference/trackers.md`

### State Transition Syntax table — Redmine row (line 27)

```
| redmine | `status:{name}` | `status:In Progress` | `status:Closed` |
```

### Redmine note below the State Transition Syntax table (lines 29–30)

```
> **Redmine note:** The `status:{name}` format is an LLM convention. The LLM translates this to the appropriate Redmine API call (e.g., `status_id=2` for "In Progress"). Status name-to-ID mapping depends on the Redmine instance configuration.
```

### Validation Rules table — Redmine row (line 73)

```
| redmine | Must contain `project_id=` | `status:{name}` | Any URL |
```

**Summary:** Redmine uses the `status:{name}` format as an LLM-interpreted convention. The state name is a human-readable label (e.g., "In Progress", "Blocked", "Closed") which the LLM resolves to the appropriate `status_id` via the Redmine MCP API. There is no native structured syntax — it is intentionally an abstraction over Redmine's numeric ID system.

---

## B1: How does `core/config-reader.md` parse `state_transitions`?

**Source:** `core/config-reader.md` lines 15–16 (Step 2)

```
2. Parse **required sections** — each is a `| Key | Value |` table under its `### {Section}` heading:
   - `### Issue Tracker` → `issue_tracker.type` (default: `youtrack`), `issue_tracker.instance`,
     `issue_tracker.project`, `issue_tracker.bug_query`,
     `issue_tracker.state_transitions` (key→value map), `issue_tracker.on_start_set`
```

**Answer:** `state_transitions` is parsed as a **verbatim key→value map** with no tracker-specific normalization. The config-reader contract specifies it as `(key→value map)` — the keys are state names (e.g., "In Progress", "Blocked") and the values are the raw transition strings from the config table (e.g., `status:In Progress`, `State: In Progress`). There is no tracker-type branching, no format validation, and no normalization at parse time. The raw strings are stored as-is in `issue_tracker.state_transitions` and passed to downstream consumers (skills, block-handler, fix-verification).

The config-reader itself does not know or care about tracker type when parsing this field — it simply builds the map. Interpretation is deferred to the MCP call site.

---

## B2: Do both Redmine config templates use `status:{name}` format?

### `examples/configs/redmine-oracle-plsql.md`

**Source:** lines 14–15

```
| State transitions | In Progress: `status:In Progress`, Blocked: `status:Blocked`, For Review: `status:For Review`, Done: `status:Closed` |
| On start set | `status:In Progress` |
```

**TODO comments present (lines 17–18):**
```
<!-- TODO: Verify status names match your Redmine workflow (GET /issue_statuses.json) -->
<!-- TODO: Verify tracker_id corresponds to "Bug" tracker (GET /projects/<id>/trackers.json) -->
```

### `examples/configs/redmine-rails.md`

**Source:** lines 14–15

```
| State transitions | In Progress: `status:In Progress`, Blocked: `status:Blocked`, For Review: `status:For Review`, Done: `status:Closed` |
| On start set | `status:In Progress` |
```

**No TODO comments** in the Issue Tracker section of the rails template (the file ends at line 46 with only Build & Test configured — it is a minimal template with no optional sections and no TODO markers on the Issue Tracker rows).

**Answer:** YES — both Redmine templates use identical `status:{name}` format for State transitions and On start set. Both use the same four-state mapping: `In Progress`, `Blocked`, `For Review`, `Done` (mapped to `status:Closed`). The oracle-plsql template includes two TODO comments reminding the user to verify status names against their Redmine instance's `/issue_statuses.json` API. The rails template does not include these reminders.

**Format conformance:** Both templates are fully consistent with `docs/reference/trackers.md` which specifies `status:{name}` as the Redmine format.
