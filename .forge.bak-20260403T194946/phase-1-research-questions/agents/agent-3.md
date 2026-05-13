# Agent 3 Research Findings: Decomposition Subtask State During Execution

## Research Question 7: Per-Subtask Status Tracking in Step 6

### Primary File: `skills/implement-feature/SKILL.md`

---

## Finding 1: Per-Subtask Status Tracking in the Execution Loop (Step 6)

**Short answer: No, per-subtask status is NOT tracked in `state.json` during execution.**

### What the skill says

In Step 6 (lines 239–323), the skill defines the subtask execution loop with phases 6a–6h. The only `state.json` update instructions found inside the subtask loop are:

- **Step 6d (Reviewer)** — line 280: updates `fixer_reviewer` fields per iteration (iterations count, last_verdict, ac_fulfillment, status).
- **Step 6e (Test-engineer)** — line 293: updates `test.status`, `test.attempts`, `test.last_result`.
- **Step 6g (Acceptance gate)** — line 312: updates `acceptance_gate.status` and `acceptance_gate.verdict`.

**None of these writes include a per-subtask status field.** The `state.json` `decomposition.subtasks` list (defined in the schema as `object[]`) is written once in **Step 5** (line 237) when the decomposition plan is saved, but never updated during the loop with subtask-level status changes.

### What Step 6h says (Commit subtask, lines 316–322)

```
git add -A
git commit -m "feat({subtask-id}): {subtask-title}"

Save commit_hash and restore_point to the task tree.
Update the task tree state on disk (.claude/decomposition/).
```

- `commit_hash` and `restore_point` are saved to the **disk YAML file** (`.claude/decomposition/{ISSUE-ID}.yaml`), **not** to `state.json`.
- There is **no instruction to write updated subtask status back to `state.json`**.
- The phrase "Update the task tree state on disk" refers exclusively to the YAML file, not the JSON state file.

### Gap summary

| What happens at Step 6h | Written to YAML | Written to state.json |
|-------------------------|-----------------|----------------------|
| commit_hash | Yes (implied) | No |
| restore_point | Yes (implied) | No |
| subtask status = "completed" | Implicit (task tree "state") | No explicit instruction |

The `state.json` `decomposition.subtasks` list is populated once at Step 5 and not updated as subtasks complete. There is no instruction to update individual subtask entries in `decomposition.subtasks` (e.g., setting `status: "completed"`) during the loop.

---

## Finding 2: Architect Agent Output Format

**File: `agents/architect.md`**

### Output format (lines 77–85)

The architect returns a markdown block:

```markdown
## Architecture Design
- **Architecture:** {high-level design — 2-3 sentences}
- **Approach rationale:** {why this approach over alternatives}
- **Files affected:** {list with description of changes per file}
- **Risk assessment:** {LOW|MEDIUM|HIGH} — {justification}
- **Decomposition:** {YES ({N} subtasks, {strategy}) | NO (single task)}
- **Task tree:** (YAML block if decomposed, or single-task plan if not)
```

The YAML task tree structure (lines 47–66):

```yaml
decomposition:
  strategy: sequential | parallel | mixed
  reason: "..."
  subtasks:
    - id: "sub-1"
      title: "..."
      scope: "..."
      files: [...]
      estimated_lines: 25
      depends_on: []
      maps_to:
        - "AC-1: {text}"
      acceptance_criteria:
        - "..."
```

### Does the architect write the task tree to disk?

**No.** The architect agent is explicitly read-only (Constraints, line 91: "NEVER modify code — read-only analysis and design"). The task tree is returned as output text/YAML in the agent's response. It is the **orchestrating skill** (`implement-feature`) that writes the task tree to disk in Step 5.

### Runtime fields note (architect.md line 72)

> "Note: The orchestrating command adds runtime fields (`status`, `commit_hash`, `restore_point`) during subtask execution. The architect only defines the initial plan."

This confirms the architect defines the static plan; the skill is supposed to add runtime fields during execution — but as Finding 1 shows, the skill only updates the YAML file, not `state.json`.

---

## Finding 3: Who Creates the `.claude/decomposition/` Directory?

**File: `core/decomposition-heuristics.md`**

The `core/decomposition-heuristics.md` file does **not** mention creating any directory. Its responsibility is limited to:
- Deciding `DECOMPOSE` vs `SINGLE_PASS` based on flags and code-analyst thresholds
- Defining input/output contracts
- Defining failure handling

The `.claude/decomposition/` directory creation is **not addressed in `core/decomposition-heuristics.md`**. The skill (`implement-feature/SKILL.md`) Step 5 (line 235) says:

> "Save task tree: Write to `.claude/decomposition/{ISSUE-ID}.yaml`"

No explicit `mkdir` instruction exists. The implicit assumption is that the Write tool (or Bash) will create the directory when writing the file, or that the directory already exists. This is a gap — no explicit directory creation step is documented.

---

## Finding 4: State Schema — `decomposition.subtasks` Object

**File: `state/schema.md` lines 185–189**

```
| decomposition.subtasks | object[] | No | [] | List of subtask objects (mirrors decomposition YAML). |
```

The schema says `decomposition.subtasks` "mirrors decomposition YAML" — implying it should be a copy of the architect's task tree. However:

1. The schema does **not define the shape of each subtask object** in the table — no sub-fields documented.
2. There is no documented `status` field within a subtask object in the schema.
3. No "Step Status Enum" values are linked to per-subtask tracking.

This means even if the skill were to write per-subtask status back to `state.json`, there is no schema contract for what fields a subtask object should have at runtime.

---

## Lifecycle Trace: Subtask State from Creation to Completion

| Phase | Action | Location Written |
|-------|--------|-----------------|
| **Step 4 (Architect runs)** | Architect returns YAML task tree in its response | Memory only (Task tool output) |
| **Step 5 (Decomposition decision)** | Skill saves task tree to disk | `.claude/decomposition/{ISSUE-ID}.yaml` |
| **Step 5 (state.json update)** | `decomposition.status = "completed"`, `decomposition.decision`, `decomposition.strategy`, `decomposition.subtasks[]` written | `state.json` |
| **Step 6 loop start** | `depends_on` check: skill reads subtask status from YAML or in-memory | `.claude/decomposition/{ISSUE-ID}.yaml` (or in-memory) |
| **Step 6b–6g (fixer/reviewer/test/gate)** | Phase-level fields updated (fixer_reviewer, test, acceptance_gate) | `state.json` |
| **Step 6h (Commit)** | `commit_hash` + `restore_point` saved to task tree | `.claude/decomposition/{ISSUE-ID}.yaml` only |
| **Step 6h (per-subtask status)** | **No instruction to mark subtask as "completed"** | **Neither file — gap** |
| **Step 7 (Integration)** | No state.json update documented | — |

---

## Key Bugs / Gaps Identified

1. **No per-subtask `status` update in `state.json`**: Step 6h only updates the YAML file. The `decomposition.subtasks` list in `state.json` is written once (Step 5) and never updated with per-subtask completion status.

2. **No explicit directory creation**: `.claude/decomposition/` directory creation is not documented anywhere — not in `core/decomposition-heuristics.md`, not in the skill. The write in Step 5 implicitly relies on the environment creating the directory.

3. **Subtask object schema not defined**: `state/schema.md` says `decomposition.subtasks` "mirrors decomposition YAML" but does not define runtime fields (`status`, `commit_hash`, `restore_point`) in the schema table — even though `agents/architect.md` line 72 says the orchestrating command should add these fields.

4. **`depends_on` check reads from ambiguous source**: Step 6 says "Verify that all depends_on have status 'completed'" but since status is not written to `state.json`, the only source is the in-memory task tree or YAML — and YAML update is only documented to add `commit_hash`/`restore_point`, not `status`.

5. **`core/decomposition-heuristics.md` references wrong skill**: The Output Contract in `core/decomposition-heuristics.md` (line 34) says "see `skills/fix-ticket/SKILL.md` steps 4b–4c" for decomposition execution — but `fix-ticket` does not implement a full decomposition loop; the full decomposition logic lives in `implement-feature`. This reference appears to be stale or incorrect.
