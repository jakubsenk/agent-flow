# Agent 2 Research — Areas 3 & 4: State Schema + Config Contract

## Area 3: State Schema

### Files read
- `state/schema.md`

### Key findings

#### Current `decomposition` block (top-level, in Full Schema Example)

```json
"decomposition": {
  "status": "pending",
  "decision": null,
  "subtasks": [],
  "strategy": null
}
```

Field definitions from the table at line 185–189:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `decomposition.status` | string | `"pending"` | Phase status (Step Status Enum) |
| `decomposition.decision` | string or null | `null` | `DECOMPOSE` or `SINGLE_PASS` |
| `decomposition.subtasks` | object[] | `[]` | List of subtask objects |
| `decomposition.strategy` | string or null | `null` | `squash` or `per-subtask` |

#### Current Subtask Object Fields (lines 192–208)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | string | Yes | — | Subtask identifier (e.g., `"subtask-1"`) |
| `title` | string | Yes | — | Human-readable title |
| `status` | string | Yes | `"pending"` | `pending`, `in_progress`, `completed`, `failed`, `blocked` |
| `commit_hash` | string or null | No | `null` | Git SHA after successful execution |
| `restore_point` | string or null | No | `null` | Git SHA before execution started |
| `depends_on` | string[] | No | `[]` | IDs of prerequisite subtasks |
| `scope` | string | No | `null` | Description from architect output |
| `files` | string[] | No | `[]` | File paths this subtask will modify |
| `estimated_lines` | integer or null | No | `null` | Estimated lines changed |
| `acceptance_criteria` | string[] | No | `[]` | Per-subtask AC from architect |
| `maps_to` | string[] | No | `[]` | Parent AC references (`AC-{N}: {text}`) |

**No `tracker_id` field exists in the current schema.**

#### Existing `tracker_id` references in the codebase

All existing hits of `tracker_id` in the codebase are unrelated to decomposition — they refer to **Redmine's REST API query parameter** (`tracker_id=1` meaning "Bug tracker type"), not to a tracker issue ID. Examples:
- `docs/reference/automation-config.md`: `Bug query | project_id=my-project&status_id=open&tracker_id=1`
- `docs/reference/trackers.md`: `tracker_id` in Redmine query table

The only reference to adding `tracker_id` to subtasks is in the roadmap (`docs/plans/roadmap.md`, line 447):
> `State: store tracker issue IDs in decomposition.subtasks[N].tracker_id`

#### Schema version

The schema is currently pinned at `"schema_version": "1.0"`. No versioning increment mechanism is documented in `state/schema.md`.

### Questions generated from Area 3

**Q1. Where exactly in the subtask object should `tracker_id` be placed?**
The schema defines 11 fields. `tracker_id` is a post-execution artifact (set after MCP call). Should it sit alongside `commit_hash` and `restore_point` (other post-execution fields), or at the end as a new optional field? Is the placement order significant for documentation consistency?

**Q2. Should `tracker_id` be nullable (`string or null`) or simply absent when not created?**
The roadmap says "store tracker issue IDs" but does not specify whether all subtasks always get this field (default `null` when not created) or whether the field is only written when tracker issue creation succeeds. What is the right default and behavior when `Create tracker subtasks = false`?

**Q3. What happens to `tracker_id` on subtask failure or resume?**
If a subtask is later re-executed (after a `restore_point` rollback), does the tracker issue already exist? The idempotency guard must check `tracker_id != null` in state.json before attempting creation. Is this the intended idempotency mechanism, or should it check the tracker itself?

**Q4. Does adding `tracker_id` to the subtask schema require a schema version bump?**
The schema is pinned at `"schema_version": "1.0"`. The field is optional (nullable, default `null`), so old state files remain valid. Is this a backward-compatible change that does NOT need a version bump, or should the schema version change to indicate new fields are available?

**Q5. Should a `tracker_issue_url` companion field also be stored alongside `tracker_id`?**
The scaffold Step 4e writes back `<!-- {TrackerType}: {ID} -->` comments but no URL. For state readability, should the subtask object also store the full URL (e.g., `https://youtrack.example.com/issue/PROJ-45`), or just the ID?

**Q6. What is the `tracker_id` field name consistency with the rest of the schema?**
The schema uses `infrastructure.tracker_type`, `infrastructure.tracker_instance`, etc. for the top-level tracker configuration. Is `tracker_id` the right field name for a subtask's issue ID, or should it be `issue_id`, `tracker_issue_id`, or `sub_issue_id` to avoid confusion with Redmine's `tracker_id` query param?

---

## Area 4: Config Contract

### Files read
- `CLAUDE.md` (Config Contract section)
- `docs/reference/automation-config.md` (Decomposition section and optional section pattern)

### Key findings

#### Current Decomposition section in CLAUDE.md (line 151)

```
| Decomposition | Max subtasks, Fail strategy, Commit strategy | 7, fail-fast, squash |
```

#### Current Decomposition section in automation-config.md (lines 345–353)

```markdown
### Decomposition

Controls task decomposition behavior for complex bugs and features.

| Key | Default | Description |
|-----|---------|-------------|
| Max subtasks | 7 | Maximum subtasks the architect can create |
| Fail strategy | `fail-fast` | `fail-fast` stops on first failure; `continue` attempts remaining |
| Commit strategy | `squash` | `squash` = one commit; `individual` = one commit per subtask |
```

#### Pattern for adding optional keys to existing sections

The reference doc uses a 3-column format for optional section documentation:

```markdown
| Key | Default | Description |
|-----|---------|-------------|
| Key name | `default-value` | Sentence description |
```

The CLAUDE.md summary table lists: `| Section | Keys | Default |` (3 columns).

For boolean-style optional keys (e.g., `On block`, `Max blocked per run`), defaults are plain English values (`comment`, `unlimited`). For boolean flags, there is no existing precedent in the config contract — no existing key uses `true`/`false` syntax. The nearest analogy is `Commit strategy | squash` (an enum, not boolean).

#### Roadmap proposed key (line 448)

```
Optional: add `Decomposition | Create tracker subtasks` config key (default: true)
```

This is a new **key within an existing optional section** (`Decomposition`). Adding a key within an existing optional section is a **MINOR** change per the versioning policy (new backward-compatible feature — new optional key).

#### How skills read this config

`implement-feature/SKILL.md` lines 32–33:
```
- Decomposition: Max subtasks (default: 7), Fail strategy (default: fail-fast), Commit strategy (default: squash)
```
Each skill explicitly lists which Decomposition keys it reads and their defaults. A new key must be added to each consuming skill's Configuration section.

Affected skills: `implement-feature`, `fix-ticket`, `fix-bugs`, and optionally `scaffold` (though scaffold has its own Step 4e).

#### Config format: table format constraint

From CLAUDE.md line 157:
> All sections use table format (`| Key | Value |`). No bullet-point lists in config sections.

The documentation format uses `| Key | Default | Description |` (3 columns) for optional section reference, and `| Key | Value |` (2 columns) in consuming project configs.

### Questions generated from Area 4

**Q7. Should `Create tracker subtasks` default to `true` or `false`?**
The roadmap proposes `default: true`. But this introduces a behavioral change for all existing projects that upgrade the plugin — they will suddenly start creating tracker sub-issues on next decomposition run. Is opt-in (`false`) safer for backward compatibility, or is opt-out (`true`) the right UX since the feature addresses an explicit user expectation?

**Q8. What is the exact key name format for `Create tracker subtasks`?**
The pattern from existing keys is Title Case words (e.g., `Max subtasks`, `Fail strategy`, `Commit strategy`). Should the new key be `Create tracker subtasks` (as proposed in roadmap), or a shorter form like `Tracker subtasks` or `Create sub-issues`? Consider that GitHub/Gitea do not have native sub-issues — the key name should not imply a capability that varies by tracker.

**Q9. Should there be a separate key for the GitHub/Gitea fallback strategy?**
For trackers without native sub-issues (GitHub, Gitea), scaffold Step 4e creates standalone issues with a `[{epic}] {title}` prefix and cross-reference body. Should the Decomposition section document this fallback in the key description, or should there be a separate `Subtask fallback strategy` key (values: `checklist`, `standalone`, `none`)?

**Q10. Should `Create tracker subtasks` be added to the Decomposition section or a new section?**
The Decomposition section currently has 3 keys (max, fail strategy, commit strategy). Adding tracker creation there is semantically reasonable. However, a dedicated `Tracker Subtasks` subsection (inside Decomposition or as a peer) might be clearer for future extensibility (e.g., if label, state, or template keys are added later). Which fits the existing config architecture better?

**Q11. Which skills must be updated in their Configuration sections when the new key is added?**
Based on the codebase, skills that read the Decomposition config block are: `implement-feature`, `fix-ticket`, `fix-bugs`. The `scaffold` skill does NOT use this config block for its Step 4e logic (it uses `tracker_effective_status` and in-memory variables from Step 0-INFRA). Does `scaffold` also need the new key, or should it be excluded?

**Q12. What is the versioning impact of adding this key?**
Per CLAUDE.md versioning policy:
> Adding an **optional** section = MINOR.
> Adding a **required** key = MAJOR.

Adding a new optional key to an existing optional section (`Decomposition`) is **MINOR** (v6.4.0). However, if the default is `true` and existing behavior changes for all upgrading projects, is this actually a breaking change that warrants MAJOR? The feature pipeline behavior changes (subtasks now get tracker issues created) even though no config change is required.

---

## Cross-cutting Gaps and Ambiguities

**Gap A: Idempotency mechanism is undefined.**
The roadmap says "check if subtask already exists before creating (handle resume)". The state schema stores `tracker_id` but no documentation exists for how the skill checks idempotency. Is it: (a) check `tracker_id != null` in state.json, (b) query the tracker for existing issues with matching title, or (c) both? This needs a clear decision before implementation.

**Gap B: GitHub/Gitea fallback strategy is inconsistently described in the roadmap.**
The roadmap says:
> GitHub/Gitea: create issues with `parent: #{parent-issue-number}` in body (no native subtask support — use checklist in parent issue)

But scaffold Step 4e uses "standalone issue with `[{epic_title}] {story_title}` prefix + cross-reference body." These two strategies differ. The decomposition flow needs a consistent decision: checklist in parent issue body, or standalone issues? The scaffold model should be followed for consistency, but neither the roadmap description nor the trackers.md fallback description fully agrees.

**Gap C: YAML file back-reference pattern for decomposition.**
Scaffold writes `<!-- {TrackerType}: {ID} -->` back into `spec/epics/*.md`. For decomposition, the back-reference would go into `.claude/decomposition/{ISSUE-ID}.yaml`. YAML does not support HTML comments — the back-reference mechanism must be different (likely a `tracker_id:` field in the YAML subtask block, mirroring state.json). This needs explicit design.

**Gap D: State schema version policy on adding optional fields.**
The schema is pinned at `"1.0"` with no documented upgrade path for adding optional fields. Adding `tracker_id` as a nullable optional field is backward-compatible (old state files still parse). But should the schema explicitly document this as a non-breaking extension, or is a version bump needed?
