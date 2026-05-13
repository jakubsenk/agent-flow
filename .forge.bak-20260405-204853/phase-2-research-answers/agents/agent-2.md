# Agent 2 Research Answers — Schema & Config

## RQ-5: Should tracker_issue_id be in both YAML and state.json?

### Evidence

**YAML (`.claude/decomposition/{ISSUE-ID}.yaml`) dual-storage pattern:**

`skills/fix-ticket/SKILL.md` Step 4c (lines 220–225) shows the current dual-write pattern for subtask state:

> Update the current subtask entry in `.claude/decomposition/{ISSUE-ID}.yaml`:
> - Set `status` to `"completed"`
> - Set `commit_hash` to the new commit SHA
> - Set `restore_point` to the commit SHA before this subtask
>
> Update `state.json`: find the matching subtask in `decomposition.subtasks` by `id`, set its `status` to `"completed"` and `commit_hash` to the new commit SHA.

The same dual-write pattern exists in `skills/implement-feature/SKILL.md` Step 6i (lines 354–359). Both skills write `status`, `commit_hash`, and `restore_point` to BOTH the YAML file and state.json simultaneously after each subtask.

**Purpose of each store:**

- `state.json`: runtime summary, resume detection, metrics collection (see `core/state-manager.md` lines 37–40 — Resume Process reads state.json to find first pending step and restore context)
- YAML: full plan artifact — the source of truth for architect output including `scope`, `files`, `estimated_lines`, `acceptance_criteria`, `maps_to`, `depends_on` (see `state/schema.md` Subtask Object Fields, lines 192–208)

The YAML contains the full subtask definition that survives across sessions. The state.json mirrors only the fields needed for resume and metrics.

**Scaffold Step 4e back-reference pattern (`.forge` precedent):**

`skills/scaffold/SKILL.md` Step 4e (lines 529–573) writes tracker issue IDs back into spec files as `<!-- {TrackerType}: {ID} -->` HTML comments in markdown. YAML does not support HTML comments (Gap C from agent-1 research). The back-reference mechanism for decomposition YAML must use a YAML field (`tracker_id:` key in the subtask block).

### Answer

**Yes — `tracker_issue_id` should be stored in BOTH the YAML and state.json.** This follows the established dual-write contract already proven by `commit_hash` and `restore_point`. The YAML is the persistent, human-readable plan artifact; state.json is the runtime machine-readable summary for resume/metrics. Storing only in state.json would make the YAML an incomplete record of the subtask's lifecycle; storing only in YAML would break the resume path (`core/state-manager.md` Resume Process reads state.json, not YAML).

**Field name recommendation:** Use `tracker_id` in YAML (consistent with the existing YAML subtask schema) and `tracker_id` in state.json subtask objects (consistent with roadmap item at `docs/plans/roadmap.md` line 447: "store tracker issue IDs in `decomposition.subtasks[N].tracker_id`"). Avoid `tracker_issue_id` as the long form adds no disambiguation value and the Redmine confusion (`tracker_id` = tracker type in Redmine query params, not an issue ID) only exists in the `Bug query` string context, not inside subtask objects.

**Idempotency:** The YAML `tracker_id` field serves as the primary idempotency guard — before creating a tracker issue for a subtask, skill code checks if `tracker_id` is already non-null in the YAML. state.json mirrors it for the same guard during resume.

---

## RQ-6: Should "Create tracker subtasks" default to true or false?

### Evidence

**Versioning policy (CLAUDE.md lines 221–230):**

| Level | Trigger |
|-------|---------|
| MAJOR | Breaking change in Automation Config contract — new required key, renamed section — OR breaking change in agent output format |
| MINOR | New backward-compatible feature — new optional key, new command/agent |
| PATCH | Behavior fix without contract change |

**Roadmap proposal:** `docs/plans/roadmap.md` line 448 proposes `default: true`.

**Existing optional key defaults (from `docs/reference/automation-config.md`):**

| Key | Default | Behavior if absent |
|-----|---------|-------------------|
| Fail strategy | `fail-fast` | Stops on first subtask failure |
| Commit strategy | `squash` | Single commit after all subtasks |
| Max subtasks | `7` | Architect is capped at 7 subtasks |
| On block | `comment` | Posts block comment only |
| Batch size | `3` | 3 bugs in parallel |
| Cleanup | `auto` | Removes worktrees after use |

**Pattern:** All existing defaults choose the behavior that requires less user configuration for the "happy path." No existing optional key defaults to a disabled/false state.

**Impact analysis of `default: true`:**

Existing projects that use decomposition would silently start creating tracker sub-issues on next invocation. For projects where `tracker_effective_status = "later"` or the Decomposition section is absent, the feature is already gated off (no tracker = no subtask creation). For projects that DO have a tracker configured and DO use decomposition, `default: true` means behavioral change on upgrade.

However, the feature is gated by `tracker_effective_status = "ready"` at the skill level. Projects that have not declared a tracker (or declared it as "later") are unaffected. The only affected projects are those that already have both tracker integration AND decomposition — a narrow subset that would arguably want this feature.

### Answer

**Default should be `true`.** Rationale:

1. All existing optional defaults choose the "active/enabled" behavior, not opt-in.
2. The key is gated by `tracker_effective_status = "ready"` — projects without a tracker are unaffected.
3. Projects that have both tracker and decomposition configured are exactly the projects that will benefit and expect this behavior.
4. If default were `false`, users would need to discover and add the key to get value; with `true`, the value is immediate on upgrade.

**However, the versioning classification requires care.** Although the policy says "new optional key = MINOR," the behavior change affects upgrading projects (decomposition now creates tracker issues). This is a functionally significant change even though no config update is required. The release must be documented prominently in the CHANGELOG as a behavioral change for projects using tracker + decomposition, but the classification remains MINOR (v6.4.0) per the written policy because no required key changes and no config schema breaks.

---

## RQ-7: Should the config key support more than boolean?

### Evidence

**Existing Decomposition keys (docs/reference/automation-config.md lines 345–353):**

```markdown
| Key | Default | Description |
|-----|---------|-------------|
| Max subtasks | 7 | Maximum subtasks the architect can create |
| Fail strategy | `fail-fast` | `fail-fast` stops on first failure; `continue` attempts remaining |
| Commit strategy | `squash` | `squash` = one commit; `individual` = one commit per subtask |
```

**Pattern observation:** Existing keys use enum strings (`fail-fast`/`continue`, `squash`/`individual`), not boolean values. No existing Automation Config key uses `true`/`false` syntax. From `docs/reference/automation-config.md` (checked across all optional sections): boolean-like behavior is expressed as enums (`auto`/`manual`, `enabled`/`disabled`, `comment`/`close`).

**GitHub/Gitea vs. native sub-issue trackers:**

`skills/scaffold/SKILL.md` Step 4e (lines 543–554) already implements a conditional branch:
- Native sub-issue trackers (YouTrack, Jira, Linear, Redmine): create sub-issues with parent parameter
- Non-native trackers (GitHub, Gitea): create standalone issues with `[{epic_title}] {story_title}` prefix and cross-reference

This branching is currently hardcoded in the skill — it is NOT configurable via Automation Config. The trackers.md reference documents sub-issue capabilities per tracker type.

**Roadmap item (line 448) wording:** "Optional: add `Decomposition | Create tracker subtasks` config key (default: true)" — no mention of multi-value enum.

### Answer

**The key should support more than a boolean, using an enum pattern consistent with the rest of the config.** Recommended values:

| Value | Meaning |
|-------|---------|
| `enabled` | Create tracker sub-issues using the tracker-native method (sub-issues for YouTrack/Jira/Linear/Redmine; standalone issues for GitHub/Gitea) |
| `disabled` | Skip tracker issue creation for all subtasks |

This follows the existing pattern (`enabled`/`disabled` is used by `Browser Verification → Exploration`). A raw `true`/`false` should be avoided — no existing key uses boolean literals, and the config format convention is explicit string enums.

**A third value is NOT recommended at this time.** The GitHub/Gitea fallback (standalone issues vs. checklist in parent body) is already handled internally by the skill based on tracker type from `docs/reference/trackers.md` sub-issue capability table. Exposing that as a config key (`checklist` vs `standalone`) would be premature — the scaffold Step 4e already made that decision (standalone), and implementing a checklist-based fallback would require non-trivial skill logic for a marginal use case. This can be a future MINOR addition (`Subtask fallback` key) if user demand emerges.

**Final key definition:**

```markdown
| Create tracker subtasks | `enabled` | `enabled` = create tracker issues for each subtask; `disabled` = skip |
```

---

## RQ-10: Failure policy — WARN-and-continue or hard block?

### Evidence

**`core/block-handler.md` — block protocol (lines 1–54):**

Block is a hard pipeline stop. The full block protocol: rollback git, set issue state to Blocked, post block comment, fire webhook, update state.json. Block is used when a critical phase (fixer, reviewer, test-engineer) fails unrecoverably.

**`core/block-handler.md` Failure Handling (lines 50–54):**

> - Comment posting failure → log warning, continue (do NOT retry).
> - Webhook failure → log warning, continue (do NOT retry).
> - State transition failure → log warning, continue.
> - Rollback failure → log warning, continue (partial git state — note in block comment detail).

The block handler itself uses WARN-and-continue for its own internal failures (infrastructure failures around the block action). This shows a layered pattern: **hard block for pipeline logic failures, WARN-continue for infrastructure/side-effect failures**.

**`core/state-manager.md` Failure Handling (lines 60–63):**

> - **Atomic write failure:** Retry once with 1-second delay. If retry fails: log `STATE_WRITE_FAILED` event to stderr, continue pipeline execution. **State persistence is advisory — pipeline MUST NOT block on state write failures.**

State writes are WARN-and-continue. This establishes that side-effect writes (state, logs, comments, webhooks) are non-fatal.

**Scaffold Step 4e partial failure pattern (`skills/scaffold/SKILL.md` lines 561–571):**

```
2. Partial failure handling (accumulator pattern):
   - On individual story failure: log WARN, continue to next story.
   - On individual epic failure: log WARN, continue to next epic.
   - After iteration completes: if any epics succeeded, commit the partial links.
   - Display result: `Created {N}/{M} tracker issues ({S} stories, {F} story failures).`
   - If N < M: `Remaining epics can be linked later via /implement-feature.`
   - Pipeline continues — this is a WARN, not a BLOCK.
```

This is the strongest direct precedent. Step 4e — the exact analogous feature for scaffold — explicitly uses WARN-and-continue with an accumulator pattern. Tracker issue creation is treated as a side-effect, not a gate.

### Answer

**WARN-and-continue, using the same accumulator pattern as scaffold Step 4e.** The rationale is:

1. Tracker issue creation is a bookkeeping side-effect — the actual code work (subtask execution, commit, test) is independent of whether a tracker issue was created.
2. Hard blocking on tracker failure would halt the entire pipeline for an infrastructure/integration issue unrelated to code correctness.
3. The scaffold Step 4e precedent is exact — it already handles partial tracker issue creation with WARN-and-continue. Consistency with scaffold is mandatory.
4. `core/block-handler.md` and `core/state-manager.md` both establish that infrastructure side-effect failures (webhooks, state writes) are WARN-and-continue.

**Recommended implementation:**

- On subtask tracker issue creation failure: log `WARN: Could not create tracker sub-issue for subtask {id} ({title}): {error}`, set `tracker_id = null` in YAML and state.json, continue to next subtask.
- At end of all subtasks: if any tracker issue was created, commit the spec/YAML changes (`git add .claude/decomposition/ && git commit -m "chore: link subtasks to tracker"`).
- Display summary: `Created {N}/{M} tracker sub-issues. {F} failures — subtasks can be linked manually.`

---

## RQ-11: YAML commit strategy

### Evidence

**Current YAML commit pattern in `skills/fix-ticket/SKILL.md` Step 4c (lines 214–225):**

```bash
git add -A
git commit -m "fix({subtask-id}): {subtask-title}"
```

The subtask YAML update happens BEFORE the commit:

> Update the current subtask entry in `.claude/decomposition/{ISSUE-ID}.yaml`:
> - Set `status` to `"completed"`
> - Set `commit_hash` to the new commit SHA
> - Set `restore_point` to ...

Then `git add -A` includes the YAML update in the commit. The YAML is bundled INTO the subtask's commit — it is not a separate "bookkeeping commit."

**`skills/implement-feature/SKILL.md` Step 6i (lines 348–359):**

Identical pattern:
```bash
git add -A
git commit -m "feat({subtask-id}): {subtask-title}"
```
YAML update then `git add -A` includes it.

**Scaffold Step 4e commit (lines 563–568):**

```bash
git add spec/
git commit -m "chore: link spec epics to tracker issues"
```

Scaffold commits only after iterating ALL epics — it is a batch commit for the entire step, not per-issue. This differs from the subtask pattern (per-subtask commits).

**Squash behavior (implement-feature Step 7, lines 368–372):**

```bash
git reset --soft {first_subtask_restore_point}
git commit -m "feat: {feature-title}"
```

When `Commit strategy = squash`, all per-subtask commits (including YAML updates) are squashed into one. The YAML file with all `tracker_id` fields will be in the final squashed commit.

### Answer

**`tracker_id` updates to the YAML should be committed as part of the subtask's own commit**, following the existing `git add -A` pattern. This means:

1. After creating the tracker sub-issue for a subtask, write `tracker_id` into `.claude/decomposition/{ISSUE-ID}.yaml` immediately.
2. The subsequent `git add -A && git commit -m "fix({subtask-id}): {subtask-title}"` will include the YAML update automatically.
3. No separate "bookkeeping commit" is needed.

**Exception — partial failure case:** If tracker issue creation fails for some subtasks (WARN-and-continue), those subtasks have `tracker_id: null` in YAML. A cleanup commit at pipeline end (after all subtasks) is NOT needed because the YAML state (including null tracker_ids) is already committed per-subtask. The state is always current.

**Squash case:** When `Commit strategy = squash`, all YAML updates including `tracker_id` fields are included in the single squashed commit. No special handling needed — `git reset --soft` preserves the working tree state including all YAML updates.

**On resume:** If a subtask already has `tracker_id` set in the YAML (non-null), the idempotency guard skips creation. The committed YAML is the canonical source of truth for idempotency, not a runtime query to the tracker.
