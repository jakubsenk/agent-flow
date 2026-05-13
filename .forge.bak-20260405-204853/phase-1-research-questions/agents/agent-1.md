# Agent 1 Research Findings — Areas 1 & 2

**Focus:** Scaffold Step 4e Pattern Analysis + Decomposition Pipeline Flow

---

## Area 1: Scaffold Step 4e Pattern Analysis

### Source: `skills/scaffold/SKILL.md` — Step 4e (lines ~519–573)

---

### 1.1 How does Step 4e iterate over spec/epics/*.md files?

**Exact excerpt:**
```
1. Iterate over `spec/epics/*.md` files (sorted by filename prefix):
   For each epic file:
   a. Idempotency guard (epic): ...
   b. Create epic-level issue ...
   c. Parse stories from the epic markdown file:
      - Split content on `\n---\n` delimiter to get blocks
      - Identify story blocks by matching `### Story N.M:` headings
      - For each story block: ...
   d. Language fidelity: ...
   e. Track the result: success or failure for this epic.
```

**Key observation:** Sorted by filename prefix (the NN numeric prefix). The spec file format uses `\n---\n` as section delimiters and `### Story N.M:` as story headings.

---

### 1.2 Exact MCP tool invocation pattern for each of the 6 tracker types

**From Step 4e (lines ~543–554):**

For trackers with **native sub-issues** (YouTrack, Jira, Linear, Redmine):

| Tracker | Parent parameter(s) to pass |
|---------|----------------------------|
| YouTrack | `parent: {epic-issue-id}` |
| Jira | `parent: {epic-issue-key}`, `issuetype: "Sub-task"` |
| Linear | `parentId: {epic-issue-id}` |
| Redmine | `parent_issue_id: {epic-issue-id}` |

For trackers **without native sub-issues** (GitHub, Gitea):
- Create standalone issue with title `[{epic_title}] {story_title}`
- Add cross-reference to epic issue in description

**Verification step (native sub-issue trackers only):**
> After creating each story sub-issue, read the created issue back from the tracker. Confirm that the parent field is set to the epic issue ID. If NOT set, log `WARN: Story {story-issue-id} parent not set to {epic-issue-id}.` and continue.

**Confirmed from `docs/reference/trackers.md` Sub-Issue Capabilities table:**
```
| youtrack | Yes | `parent: {issue-id}` | N/A |
| jira     | Yes | `parent: {key}`, `issuetype: "Sub-task"` | N/A |
| linear   | Yes | `parentId: {issue-id}` | N/A |
| redmine  | Yes | `parent_issue_id: {issue-id}` | N/A |
| github   | No  | N/A | Standalone issue: `[{epic_title}] {story_title}`, cross-reference in description |
| gitea    | No  | N/A | Standalone issue: `[{epic_title}] {story_title}`, cross-reference in description |
```

---

### 1.3 Idempotency guard — how it works

**Epic-level idempotency (excerpt):**
```
Idempotency guard (epic): Check if the epic file already contains a
`<!-- {TrackerType}: ... -->` back-reference comment after the `# Epic NN:`
heading. If present: skip epic creation, extract the existing issue ID for
use as parent ID in story creation. Jump to step 1.c.
```

**Story-level idempotency (excerpt):**
```
Idempotency guard (story): If story heading already has a
`<!-- {TrackerType}: ... -->` back-reference comment on the next line,
skip creation for this story.
```

**Back-reference write-back pattern:**
- Epic: `<!-- {TrackerType}: {EPIC-ISSUE-ID} -->` inserted after `# Epic NN:` heading
- Story: `<!-- {TrackerType}: {STORY-ISSUE-ID} -->` inserted immediately after `### Story N.M:` heading

**Gap found:** The format uses `{TrackerType}` as a literal variable. It is not clear from Step 4e whether `TrackerType` is e.g. `youtrack`, `YouTrack`, or the full type string. The back-reference comments later need to be parsed by Steps 8a and 8b which look for `<!-- {TrackerType}: {ID} -->` — so consistency matters.

---

### 1.4 Partial failure handling — accumulator pattern

**Exact excerpt:**
```
2. Partial failure handling (accumulator pattern):
   - On individual story failure: log WARN, continue to next story.
     The epic is considered succeeded if the epic-level issue was created.
   - On individual epic failure: log WARN, continue to next epic.
   - After iteration completes: if any epics succeeded, commit the partial links:
     git add spec/
     git commit -m "chore: link spec epics to tracker issues"
   - Display result: `Created {N}/{M} tracker issues ({S} stories, {F} story failures).`
   - If N < M: `Remaining epics can be linked later via /implement-feature.`
   - Pipeline continues — this is a WARN, not a BLOCK.
```

**Key characteristic:** The commit is only made if at least one epic succeeded. If ALL epics fail, no commit is made. This is an accumulator-then-commit pattern rather than per-epic commits.

---

### 1.5 GitHub/Gitea fallback (no native sub-issues)

**Pattern:** Prefix epic title into story issue title:
- Title: `[{epic_title}] {story_title}`
- Description: includes cross-reference back to the epic issue

**No sub-issue hierarchy is created.** Issues are siblings, linked only by title prefix and description text. This contrasts with native-sub-issue trackers where a true parent-child relationship is established.

---

### Research Questions — Area 1

**Q1.** The idempotency guard checks for `<!-- {TrackerType}: ... -->` back-reference comments. When decomposition subtask tracker issues are created, should they also use this exact same back-reference comment format, written back into a source file (e.g., `.claude/decomposition/{ISSUE-ID}.yaml`)? Or is a different persistence mechanism needed?

**Q2.** Step 4e iterates `spec/epics/*.md` files — a well-defined source structure. For decomposition subtask creation, what is the analogous "source of truth" file? The task tree in `.claude/decomposition/{ISSUE-ID}.yaml` contains all subtask definitions. Is this file the input for iterating subtasks to create tracker issues?

**Q3.** The GitHub/Gitea fallback creates standalone issues with `[{epic_title}] {story_title}` prefix. For decomposition subtasks, what should the fallback title format be? Options: `[{parent_issue_id}] {subtask_title}` or `[SUBTASK] {subtask_title}` or just `{subtask_title}`. Does the parent issue title need to appear in the subtask issue title?

**Q4.** Step 4e has a hard skip condition: if `tracker_write_available = false`, step is entirely skipped. For decomposition subtask creation, should the same guard apply? What if issue creation fails mid-subtask-loop — should the fixer wait for an issue ID before proceeding, or can it proceed without one?

**Q5.** Step 4e uses the `On start set` state transition explicitly for created issues (it says "Do NOT apply `On start set`"). For subtask tracker issues created during decomposition, when should the state be set? At creation time? When fixer starts working on the subtask?

**Q6.** The partial failure accumulator pattern in Step 4e commits back-reference changes at the end of iteration. For decomposition subtask issue creation, where should the issue ID be persisted? In `.claude/decomposition/{ISSUE-ID}.yaml` (a new `tracker_issue_id` field per subtask), in `state.json`, or in both?

**Q7.** Step 4e's idempotency guard enables safe re-runs by checking back-reference comments already written to spec files. For decomposition, if the pipeline is resumed mid-way (via `/resume-ticket`), how does the new subtask issue creation step know which subtasks already have tracker issues? The `.yaml` file must store per-subtask `tracker_issue_id` for this to work.

**Q8.** Verification after story creation reads the created issue back to confirm parent linkage. For decomposition subtask issues, is there an analogous verification step needed? Or is it sufficient to just check that the MCP tool call returned an issue ID?

---

## Area 2: Decomposition Pipeline Flow

### Sources: `skills/implement-feature/SKILL.md`, `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `agents/architect.md`

---

### 2.1 At what exact step does decomposition happen in each skill?

**implement-feature:**
- Step 4 (Architect) produces the task tree
- **Step 5 (Decomposition decision)** is where the tree is validated and saved
- Steps 6a–6i execute each subtask in a loop

**fix-ticket:**
- Step 3 (Triage) → Step 4 (Code-analyst) → **Step 4a (Decompose flag parsing)** → **Step 4b (Decomposition decision)**
- If DECOMPOSE: architect runs inline in Step 4b
- Step 4c: subtask execution loop

**fix-bugs:**
- Steps 2 (Triage, parallel) → 3 (Code-analyst, parallel) → **Step 3a (Decompose flag parsing)** → **Step 3b (Decomposition decision, per-bug)**
- If DECOMPOSE: architect runs inline in Step 3b
- Step 3c: subtask execution loop (per-bug)

---

### 2.2 Data available after architect approval — task tree structure

**From `agents/architect.md` step 8 (YAML output format):**

```yaml
decomposition:
  strategy: sequential | parallel | mixed
  reason: "Brief explanation why decomposition is needed"
  subtasks:
    - id: "sub-1"
      title: "Short description"
      scope: "What exactly to do"
      files:
        - path/to/file1.ext
        - path/to/file2.ext
      estimated_lines: 25
      depends_on: []
      maps_to:
        - "AC-1: {text of the parent feature/bug AC this subtask addresses}"
        - "AC-3: {text of another parent AC}"
      acceptance_criteria:
        - "Testable criterion 1"
        - "Testable criterion 2"
```

**Runtime fields added by orchestrating skill (NOT in architect output):**
- `status: "pending"` (updated to `"completed"` after each subtask execution)
- `commit_hash: null` (set to SHA after commit)
- `restore_point: null` (set to SHA before subtask for rollback)

**Note:** `tracker_issue_id` is NOT currently a field. This is a gap that a subtask issue creation feature would need to fill.

---

### 2.3 Where is the task tree saved?

**Explicit excerpt from all three skills (identical wording):**
```
Save task tree: Create `.claude/decomposition/` if it does not exist
(`mkdir -p .claude/decomposition/`). Write the full task tree (including all
subtask fields and runtime fields `status: "pending"`, `commit_hash: null`,
`restore_point: null`) to `.claude/decomposition/{ISSUE-ID}.yaml`.
```

**Additionally in state.json** (`decomposition` section):
- `decomposition.status` — `"completed"` / `"blocked"`
- `decomposition.decision` — `"DECOMPOSE"` / `"SINGLE_PASS"`
- `decomposition.strategy` — strategy string or `null`
- `decomposition.subtasks` — list (synced subset — `id`, `status`, `commit_hash` per subtask)

**Two persistence locations:** `.claude/decomposition/{ISSUE-ID}.yaml` (full plan) and `state.json` (runtime status summary).

---

### 2.4 Subtask object fields

**Architect-defined fields:**
| Field | Type | Description |
|-------|------|-------------|
| `id` | string | e.g., `"sub-1"`, `"sub-2"` |
| `title` | string | Short description |
| `scope` | string | What exactly to do |
| `files` | list of strings | File paths affected |
| `estimated_lines` | integer | Estimated diff lines |
| `depends_on` | list of strings | IDs of prerequisite subtasks |
| `maps_to` | list of strings | AC references (`AC-N: {text}`) |
| `acceptance_criteria` | list of strings | Testable criteria for this subtask |

**Skill-added runtime fields:**
| Field | Type | Default | Updated when |
|-------|------|---------|-------------|
| `status` | string | `"pending"` | Set to `"completed"` after `git commit` |
| `commit_hash` | string | `null` | Set to SHA after commit |
| `restore_point` | string | `null` | Set to `HEAD~1` before subtask execution |

**Missing field (gap):**
| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `tracker_issue_id` | string | `null` | Would store the created tracker issue ID for the subtask — not currently defined |

---

### Research Questions — Area 2

**Q9.** The task tree is saved to `.claude/decomposition/{ISSUE-ID}.yaml` before the execution loop begins. For subtask issue creation, should a new step be inserted **before** the execution loop starts (create all issues upfront), or should issue creation happen **per-subtask** just before fixer starts work on each one?

**Q10.** The architect output does NOT include a `tracker_issue_id` field — this is a runtime addition like `status`, `commit_hash`, `restore_point`. Which skill is responsible for writing `tracker_issue_id` back to the YAML after creation: the orchestrating skill itself, or a new dedicated step/agent?

**Q11.** In `fix-bugs`, decomposition decision happens **per-bug** (Step 3b). If bugs are being processed with worktrees in parallel, and each bug needs tracker subtask issues created, does issue creation need to be serialized (one bug at a time) to avoid MCP rate limits or tracker API concurrency issues?

**Q12.** The `maps_to` field links each subtask to parent acceptance criteria (`AC-N: {text}`). When creating tracker sub-issues, should the `maps_to` data appear in the sub-issue description? This would provide traceability from tracker issue to parent AC without requiring the user to read the YAML file.

**Q13.** In `implement-feature` Step 6h (Acceptance gate), the gate runs after each subtask execution. If a subtask has a tracker issue, should the acceptance gate result (APPROVE/REQUEST_CHANGES) be written back as a comment to the subtask's tracker issue?

**Q14.** The subtask `id` field uses values like `"sub-1"`, `"sub-2"`. The tracker issue will have its own ID (e.g., `PROJ-123`). How should these two IDs be kept synchronized across `state.json` and `.claude/decomposition/{ISSUE-ID}.yaml`? The YAML needs a `tracker_issue_id` field; does `state.json`'s `decomposition.subtasks` list also need to carry `tracker_issue_id` per subtask?

**Q15.** For the GitHub/Gitea fallback (no native sub-issues), the parent issue cannot be set. Given that the decomposition subtask is a child of a bug/feature ticket (not an "epic"), what is the correct cross-reference format to use? The scaffold pattern uses `[{epic_title}] {story_title}` in the title. For decomposition subtasks the natural format would be `[{ISSUE-ID}] {subtask_title}`. Is this the right convention?

**Q16.** The decomposition pipeline in `fix-bugs` operates in two phases: (a) all triages and code-analyst runs in parallel, THEN (b) per-bug sequential execution. For tracker issue creation, which phase is the right insertion point — after phase (a) when all task trees exist, or inline in phase (b) just before each bug's fixer loop?

---

## Gaps and Ambiguities Found

### Gap 1: No `tracker_issue_id` field in task tree schema
Neither the architect agent nor the skills define a `tracker_issue_id` per-subtask field. Adding subtask issue creation requires extending the YAML schema and the `decomposition.subtasks` list in `state.json`. This is a schema change — any resume/rollback logic that reads the YAML will need to handle the new field gracefully (treat `null`/absent as "not yet created").

### Gap 2: Step numbering collision risk
In `fix-ticket`, decomposition happens at Step 4b/4c. In `fix-bugs`, it is Step 3b/3c. In `implement-feature`, it is Step 5/6. A new "create subtask tracker issues" step would need a consistent step number/letter suffix across all three skills. No existing convention suggests what that suffix should be (e.g., `4b-issues` in fix-ticket, `3b-issues` in fix-bugs, `5-issues` in implement-feature).

### Gap 3: TrackerType casing in back-reference comments
The scaffold Step 4e uses `<!-- {TrackerType}: {ID} -->` as the back-reference format. Step 8a and 8b parse these comments to find issue IDs. The exact casing/value of `TrackerType` in the comment is not canonically defined anywhere — it appears to be whatever the tracker `Type` config value is (e.g., `youtrack`, `github`, `gitea`). For decomposition subtask back-references stored in a YAML file rather than a Markdown file, a new storage format or a different field in the YAML must be defined instead.

### Gap 4: Scaffold Step 4e only runs once (scaffold-time)
Step 4e is purely a scaffold-time operation — it runs once during project creation. Decomposition subtask issue creation would be a **pipeline-time** operation (runs every time a ticket is decomposed). The trigger, guard conditions, and persistence mechanism need to be designed from scratch for the decomposition context.

### Gap 5: No recovery mechanism specified for partial subtask issue creation
Step 4e has a clear accumulator pattern with a commit at the end. If subtask issue creation is done before the execution loop, partial failures mid-loop (some subtasks have issues, some don't) could leave the YAML in an inconsistent state. The resume logic (`/resume-ticket`) would need to detect and skip already-created issues using an idempotency mechanism similar to Step 4e's back-reference guards.

### Gap 6: `fix-bugs` decompose mode missing `--yolo` auto-approve
In `fix-bugs`, the decomposition plan display says "Display plan and wait for confirmation" without mentioning `--yolo` auto-approve (unlike `implement-feature` Step 5 which explicitly says `If --yolo → auto-approve`). This may affect where subtask issue creation should sit in `fix-bugs` (before or after confirmation).

---

## Key File Paths Referenced

- `skills/scaffold/SKILL.md` — Step 4e (lines ~519–573), Step 8a–8b
- `skills/implement-feature/SKILL.md` — Steps 4–6i
- `skills/fix-ticket/SKILL.md` — Steps 4a–4c
- `skills/fix-bugs/SKILL.md` — Steps 3a–3c
- `agents/architect.md` — Task tree YAML format (lines ~46–72)
- `core/decomposition-heuristics.md` — DECOMPOSE vs SINGLE_PASS decision logic
- `docs/reference/trackers.md` — Sub-Issue Capabilities table (lines ~86–97)
