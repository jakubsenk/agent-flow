# Phase 1 Research — Agent 1 Findings

**Task:** Compare implement-feature and fix-ticket decomposition persistence patterns.
**Files analyzed:**
- `skills/implement-feature/SKILL.md`
- `skills/fix-ticket/SKILL.md`
- `state/schema.md`
- `core/decomposition-heuristics.md`

---

## Question 1: Persistence Delta — Step 5 (implement-feature) vs Step 4b (fix-ticket)

### implement-feature Step 5 — "Decomposition decision" (lines 193–237)

The step ends with two persistence actions (lines 235–237):

```
**Save task tree:** Write to `.claude/decomposition/{ISSUE-ID}.yaml`

Update `state.json`: set `decomposition.status` to `"completed"`, write
`decomposition.decision` (`"DECOMPOSE"` or `"SINGLE_PASS"`),
`decomposition.strategy`, `decomposition.subtasks` list.
Follow atomic write protocol from `core/state-manager.md`.
```

### fix-ticket Step 4b — "Decomposition decision" (lines 158–182)

The equivalent block contains (lines 171–172):

```
**Save task tree to `.claude/decomposition/{ISSUE-ID}.yaml`**

**AC coverage check** (when AC are available from triage): ...
```

There is NO explicit `state.json` update instruction in fix-ticket Step 4b at all.

### Line-by-line comparison

| Persistence action | implement-feature Step 5 | fix-ticket Step 4b |
|---|---|---|
| Write task tree YAML to `.claude/decomposition/{ISSUE-ID}.yaml` | Yes (line 235) | Yes (line 171) |
| `state.json` — set `decomposition.status = "completed"` | Yes (line 237) | **MISSING** |
| `state.json` — write `decomposition.decision` | Yes (line 237) | **MISSING** |
| `state.json` — write `decomposition.strategy` | Yes (line 237) | **MISSING** |
| `state.json` — write `decomposition.subtasks` list | Yes (line 237) | **MISSING** |
| Follow atomic write protocol reference | Yes (line 237) | **MISSING** |

**Gap:** fix-ticket Step 4b saves the YAML file but never instructs the LLM executor to update state.json with the four decomposition fields. All four state.json writes are absent.

---

## Question 2: State.json Decomposition Writes in implement-feature

### Where the writes appear in implement-feature

**Single location — Step 5, lines 235–237** (`skills/implement-feature/SKILL.md`):

```
Update `state.json`: set `decomposition.status` to `"completed"`, write
`decomposition.decision` (`"DECOMPOSE"` or `"SINGLE_PASS"`),
`decomposition.strategy`, `decomposition.subtasks` list.
Follow atomic write protocol from `core/state-manager.md`.
```

This is the only place in the entire file where any of the four decomposition fields are written. There is no "SINGLE_PASS path" write — the instruction fires only when DECOMPOSE is chosen (because SINGLE_PASS skips Step 5 by going "to step 6 directly", line 193).

### Schema coverage check (state/schema.md lines 185–189)

| Schema field | Written in implement-feature Step 5? | Written in fix-ticket Step 4b? |
|---|---|---|
| `decomposition.status` (string, required, default: `"pending"`) | Yes — set to `"completed"` | No |
| `decomposition.decision` (string or null, `DECOMPOSE` or `SINGLE_PASS`) | Yes | No |
| `decomposition.subtasks` (object[], default: `[]`) | Yes — subtasks list | No |
| `decomposition.strategy` (string or null, `squash` or `per-subtask`) | Yes | No |

**All four fields are covered in implement-feature Step 5.** However there is a subtle gap: when `decompose_mode = DISABLED` or AUTO results in SINGLE_PASS, the step is skipped entirely (line 193: "single-pass (step 6 directly)"). In that path, `decomposition.status` stays `"pending"` and `decomposition.decision` stays `null` — neither is set to reflect the SINGLE_PASS outcome.

Compare with the schema definition: `decomposition.decision` has allowed values `"DECOMPOSE"` or `"SINGLE_PASS"`, implying SINGLE_PASS should also be persisted. The implement-feature skill only writes these fields in the DECOMPOSE branch.

**Secondary gap:** implement-feature has no instruction to write `decomposition.status = "completed"` or `decomposition.decision = "SINGLE_PASS"` when the pipeline takes the single-pass route.

---

## Question 3: Step 6h — "Update the task tree state on disk (.claude/decomposition/)"

### The exact text — implement-feature Step 6h (lines 316–323)

```
#### 6h. Commit subtask

```bash
git add -A
git commit -m "feat({subtask-id}): {subtask-title}"
```

Save commit_hash and restore_point to the task tree.
Update the task tree state on disk (.claude/decomposition/).
```

### Analysis — Is this clear enough for an LLM executor?

**What is ambiguous:**

1. **"Save commit_hash and restore_point to the task tree"** — "the task tree" is not defined precisely. It could mean: (a) the in-memory YAML structure, (b) the `.claude/decomposition/{ISSUE-ID}.yaml` file already saved in Step 5, or (c) a new file. There is no instruction to read the YAML first, mutate it, and write it back.

2. **"Update the task tree state on disk (.claude/decomposition/)"** — specifies the directory but not the filename or file format. A new executor would not know whether to write `{ISSUE-ID}.yaml`, `{subtask-id}.yaml`, a JSON sidecar, etc.

3. **What fields to write** — "commit_hash" and "restore_point" are mentioned in the prose but there is no schema contract for them. The state/schema.md `decomposition.subtasks` field is described only as "List of subtask objects (mirrors decomposition YAML)" — no field names are given.

4. **No atomic write protocol reference** — unlike every other state.json update in both files which ends with "Follow atomic write protocol from `core/state-manager.md`", this instruction has no such reference.

### fix-ticket equivalent — Step 4c (line 196)

```
9. Commit subtask: `git add -A && git commit -m "fix({subtask-id}): {subtask-title}"`.
   Save commit_hash and restore_point to the task tree.
```

Fix-ticket Step 4c also does NOT specify the filename or fields. However, fix-ticket recovers clarity slightly because Step 4c line 204 adds:

```
Save task tree state for resume
```

This is equally vague. **Neither skill provides a clear spec here** — both are similarly underspecified on the disk-write details of the per-subtask state. The gap between them:

| Clarity dimension | implement-feature Step 6h | fix-ticket Step 4c |
|---|---|---|
| Directory specified | Yes (`.claude/decomposition/`) | No (implied from Step 4b) |
| Filename specified | No | No |
| Fields to write (commit_hash, restore_point) | Named in prose only | Named in prose only |
| Schema for subtask object | Not provided | Not provided |
| Atomic write protocol reference | No | No |
| state.json update after commit | No | No |

**Verdict:** Step 6h is NOT clear enough for an LLM executor to reliably know WHAT to write and WHERE. The directory hint (`.claude/decomposition/`) is marginally better than fix-ticket's implicit reference, but both lack the filename, the field schema, and the write protocol. This is a shared deficiency.

The most actionable gap in implement-feature specifically: Step 6h mentions updating the task tree but does not instruct the executor to also update `state.json`'s `decomposition.subtasks[N].status`, `commit_hash`, and `restore_point` fields — fields that resume-ticket and the integration step (Step 7) would need to read back.

---

## Summary Table — All Three Questions

| Gap | File | Location | Severity |
|---|---|---|---|
| fix-ticket Step 4b missing ALL four state.json decomposition writes | `fix-ticket/SKILL.md` | Step 4b (lines 158–182) | HIGH — state.json never updated on decomposition in fix-ticket |
| implement-feature SINGLE_PASS path never writes decomposition.decision / decomposition.status | `implement-feature/SKILL.md` | Step 5 (line 193) | MEDIUM — decomposition object stays in initial `pending`/`null` state |
| Step 6h lacks filename, field schema, and atomic write protocol for task tree disk update | `implement-feature/SKILL.md` | Step 6h (lines 321–323) | MEDIUM — ambiguous enough to produce inconsistent executor behavior |
| Step 4c in fix-ticket has same task-tree-update ambiguity | `fix-ticket/SKILL.md` | Step 4c (line 196) | MEDIUM — same root cause, shared deficiency |
