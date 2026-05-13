# Research Answer 3: Architect Interface Contract

## Architect Agent Output Format

Source: `agents/architect.md`

The architect produces one of two output shapes depending on whether decomposition is needed.

### Shape A: Decomposed (task tree in YAML)

Defined at `agents/architect.md` lines 46–83. The full markdown output section is:

```markdown
## Architecture Design
- **Architecture:** {high-level design — 2-3 sentences}
- **Approach rationale:** {why this approach over alternatives}
- **Files affected:** {list with description of changes per file}
- **Risk assessment:** {LOW|MEDIUM|HIGH} — {justification}
- **Decomposition:** YES ({N} subtasks, {strategy})
- **Task tree:** (YAML block)
```

Embedded YAML block (lines 46–65):

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

The id pattern shown in the agent definition is `"sub-{N}"` (line 51, example `"sub-1"`). The docs/reference/agents.md example at lines 239–267 confirms ids `"sub-1"`, `"sub-2"`, `"sub-3"` as the canonical pattern used in real output.

Runtime fields NOT produced by architect (noted at line 71): `status`, `commit_hash`, `restore_point`. These are written by orchestrating commands during execution.

### Shape B: No decomposition

When decomposition is not needed (line 73):

```markdown
## Architecture Design
- **Architecture:** ...
- **Approach rationale:** ...
- **Files affected:** ...
- **Risk assessment:** ...
- **Decomposition:** NO (single task)
- **Task tree:** {single-task plan for the fixer agent}
```

The `**Decomposition:**` field acts as the detection signal consumed by commands (see below).

### Architect constraints on output format (lines 88–89)

- Every parent AC MUST be mapped to at least one subtask via `maps_to`.
- `maps_to` entries MUST use format `AC-{N}: {verbatim text from parent AC}` where N matches the parent AC numbering exactly.
- The architect MUST NOT renumber or reorder parent AC.

### Block output (lines 97–105)

```
[ceos-agents] 🔴 Pipeline Block
Agent: architect
Step: Architecture Design
Reason: {reason}
Detail: {what was analyzed, what went wrong}
Recommendation: {what the human should do}
```

---

## Consumer Parsing: implement-feature.md

Source: `commands/implement-feature.md`

### Step 4 — Invocation (lines 96–102)

```
Run the architect agent (Task tool, model: opus):
- Context: specification from spec-analyst + access to code
- Expected output: architectural design + task tree (YAML)

If architect blocks → proceed to step X (Block handler).
```

No structured parsing of the markdown prose section (Architecture, Approach rationale, Files affected, Risk assessment) is described. Those fields are informational context for the human-readable dry-run display.

### Step 5 — Decomposition decision (lines 104–148)

Detection of whether architect indicates decomposition (line 107):
```
If `decompose_mode = FORCE` or `decompose_mode = AUTO` and architect indicates decomposition:
```
The phrase "architect indicates decomposition" is not given a formal parsing rule here. The signal is the presence and value of the `**Decomposition:**` field in architect output — `YES` triggers the decomposition path, `NO` skips to single-pass. This is inferred from the architect output format definition (`**Decomposition:** {YES (...) | NO (single task)}`).

### Task tree validation (lines 109–115)

Fields parsed by commands for validation:
1. `depends_on` — checked for cycle detection: find subtasks with empty `depends_on` (roots); topological sort of remaining (lines 110–112)
2. `title` — required field presence check (line 115)
3. `scope` — required field presence check (line 115)
4. `files` — required field presence check (line 115)
5. `estimated_lines` — required field presence check (line 115)
6. `acceptance_criteria` — required field presence check (line 115)

Validation rule verbatim (line 115):
```
4. Check: each subtask has title, scope, files, estimated_lines, acceptance_criteria.
```
Note: `id` and `maps_to` are NOT in this validation list, even though they are produced by the architect and consumed elsewhere.

### AC coverage check (lines 117–131)

Parsing algorithm verbatim (lines 128–131):
```
- Each `maps_to` entry uses format `AC-{N}: {text}` where N is the 1-based index in the parent AC list
- Coverage check: collect all N values from all subtasks' `maps_to` fields, verify that every integer from 1 to {total parent AC count} appears at least once
- Text after `AC-N:` is informational (for human readability) — matching is by index only
- If a `maps_to` entry cannot be parsed (no `AC-{N}:` prefix) → treat as warning, not error
```

String matching pattern: regex equivalent of `AC-(\d+):` — extract integer N from each entry. No text-based matching.

### Task tree persistence (line 148)

```
Write to `.claude/decomposition/{ISSUE-ID}.yaml`
```

### Subtask execution loop (lines 155–226)

Fields read per subtask at runtime:
- `depends_on` — checked against per-subtask `status: "completed"` (line 158)
- `scope` — passed to fixer context (line 161)
- `files` — passed to fixer context (line 161)
- `acceptance_criteria` — passed to fixer context (line 161)
- `id` — used in commit message: `feat({subtask-id}): {subtask-title}` (line 222)
- `title` — used in commit message (line 222) and display plan table (line 138)

### Decomposition plan display (lines 134–144)

Table uses:
- `#` (position/order)
- Subtask title
- Files
- `~Lines` (estimated_lines)
- `Depends on`

---

## Consumer Parsing: fix-ticket.md

Source: `commands/fix-ticket.md`

### Step 4b — Decomposition decision (lines 128–147)

Architect is run (lines 139–143):
```
Run the architect agent (Task tool, model: opus):
- Context: code-analyst impact report + issue details
- Instructions: "Decompose this bug into subtasks. Max {max_subtasks} subtasks."
- Output: task tree (YAML)
```

Validation: explicitly deferred to implement-feature step 5 (line 145):
```
**Validate task tree:** (see implement-feature step 5)
```

### AC coverage check (lines 149–158)

maps_to parsing reference (lines 151–152):
```
2. Collect all `maps_to` references from all subtasks in the task tree
  - maps_to format: `AC-{N}: {text}` — matching is by index N only (see AC matching algorithm in implement-feature step 5)
```

This is a cross-reference to implement-feature step 5 — no separate parsing algorithm is defined in fix-ticket.md itself. The parsing is identical.

### Step 4c — Subtask execution (lines 162–172)

Fields consumed per subtask:
- `depends_on` — checked for completion status (line 164)
- `scope` — in fixer context (line 165)
- `files` — in fixer context (line 165)
- `acceptance_criteria` — in fixer context (line 165)
- `id` — in commit message `fix({subtask-id}): {subtask-title}` (line 172)
- `title` — in commit message (line 172)

Runtime fields written:
- `commit_hash` — saved to task tree after commit (line 172)
- `restore_point` — saved to task tree after commit (line 172)

Rollback uses `{restore_point_N}` (line 178).

### NEEDS_DECOMPOSITION path (lines 208–213)

Fixer output signal `## NEEDS_DECOMPOSITION` triggers architect invocation:
```
4. Run architect agent for decomposition (same as step 4b with FORCE)
```
Same interface as step 4b.

---

## Consumer Parsing: fix-bugs.md

Source: `commands/fix-bugs.md`

### Step 3b — Decomposition decision (lines 118–137)

Identical invocation pattern to fix-ticket.md (lines 130–133):
```
Run the architect agent (Task tool, model: opus):
- Context: code-analyst impact report + issue details
- Instructions: "Decompose this bug into subtasks. Max {max_subtasks} subtasks."
- Output: task tree (YAML)
```

Validation: deferred to implement-feature step 5 (line 135):
```
**Validate task tree:** (see implement-feature step 5)
```

### AC coverage check (lines 139–148)

maps_to parsing (lines 141–142):
```
2. Collect all `maps_to` references from all subtasks in the task tree
  - maps_to format: `AC-{N}: {text}` — matching is by index N only (see AC matching algorithm in implement-feature step 5)
```

Identical cross-reference structure to fix-ticket.md.

### Step 3c — Subtask execution (lines 152–162)

Fields consumed per subtask:
- `depends_on` — completion check (line 154)
- `scope`, `files`, `acceptance_criteria` — fixer context (line 155)
- `id`, `title` — commit message `fix({subtask-id}): {subtask-title}` (line 162)

Runtime fields written:
- `commit_hash`, `restore_point` (line 162)

Rollback uses `git reset --hard {restore_point_N}` (line 168).

### NEEDS_DECOMPOSITION path (lines 198–203)

Same pattern as fix-ticket.md — architect invoked again with FORCE mode.

---

## Cross-Reference: acceptance-gate.md

Source: `agents/acceptance-gate.md`

The acceptance-gate agent does NOT consume architect output directly. It is invoked after the fixer with this context (from fix-ticket.md line 279, fix-bugs.md line 269, implement-feature.md line 213):

```
Acceptance criteria: {AC from triage/spec-analyst}. Changed files: {list of files modified by fixer}.
```

The acceptance-gate reads AC from triage-analyst (bugs) or spec-analyst (features) — the same parent AC list that the architect's `maps_to` references. It does not read the task tree YAML, the `maps_to` field, or any architect output.

The acceptance-gate works independently of the architect's decomposition output. For decomposed tickets, implement-feature runs the acceptance-gate per subtask using the full feature AC (not per-subtask AC), explicitly stated at line 213:
```
Context: `Acceptance criteria: {AC from spec-analyst — full feature AC, not just per-subtask AC}. Changed files: {list of files modified by fixer}.`
```

---

## Complete Field Inventory

| Field | Format | Consumed by | Parsing method |
|-------|--------|-------------|----------------|
| `decomposition.strategy` | string: `sequential`, `parallel`, or `mixed` | implement-feature (display plan only), scaffold | String equality for display |
| `decomposition.reason` | string (free text) | implement-feature (display plan only) | Display only, no logic |
| `subtask.id` | string, pattern `"sub-{N}"` | All three commands (commit message), resume-ticket (task tree lookup) | String interpolation into commit: `fix({subtask-id}): {subtask-title}` |
| `subtask.title` | string (free text) | All three commands (commit message, display table) | String interpolation |
| `subtask.scope` | string (free text) | All three commands (fixer context) | Passed verbatim as context |
| `subtask.files` | list of path strings | All three commands (fixer context, display table) | Passed verbatim as context |
| `subtask.estimated_lines` | integer | All three commands (display table, validation) | Required field presence check; integer display |
| `subtask.depends_on` | list of subtask id strings | All three commands (cycle detection, completion check) | DAG algorithm: find empty `depends_on` = roots; topological sort |
| `subtask.maps_to` | list of strings, each `"AC-{N}: {text}"` | All three commands + scaffold (AC coverage check) | Regex extract integer N; set coverage check against 1..total |
| `subtask.acceptance_criteria` | list of strings (testable criteria) | All three commands (fixer context, validation) | Required field presence check; passed verbatim to fixer |
| `**Decomposition:**` markdown field | `YES ({N} subtasks, {strategy})` or `NO (single task)` | implement-feature (decomposition path decision) | String match: presence of `YES` vs `NO` |
| `**Risk assessment:**` markdown field | `LOW`, `MEDIUM`, or `HIGH` | Not parsed by consumers | Informational only |
| `status` (runtime) | string: `pending`, `in_progress`, `completed`, `failed` | resume-ticket, all three commands | String equality for subtask skip/retry logic |
| `commit_hash` (runtime) | string (git hash) | Squash commit in implement-feature | String reference in `git reset --soft` |
| `restore_point` (runtime) | string (git ref) | All three commands (rollback) | `git reset --hard {restore_point_N}` |

---

## Format Sensitivity Analysis

### Fragile (string-matched, silently break on format change)

**1. `maps_to` prefix format** — `AC-{N}:` prefix is parsed by regex to extract integer N. If changed to any other format (e.g., `REQ-{NNN}:`, `CRITERION-{N}:`, or unprefixed), the coverage check silently finds zero mappings and either warns or blocks depending on mode. No structural error is raised. Defined at implement-feature.md lines 128–131; consumed identically by fix-ticket.md line 152, fix-bugs.md line 142, scaffold.md line 296.

**2. `**Decomposition:**` markdown bullet** — implement-feature.md line 107 detects whether the architect "indicates decomposition" from this field. The exact string `YES` vs `NO` in the bullet value determines the pipeline branch taken. If the architect emits a different signal (e.g., `DECOMPOSE: true`, or moves the field), implement-feature will default to single-pass without error.

**3. `depends_on` field name** — implement-feature.md lines 110–112 explicitly reads field named `depends_on` for cycle detection. If renamed (e.g., `dependencies`, `blocked_by`), cycle detection silently skips validation and subtask ordering breaks. All three commands use the same field name for completion-check logic.

**4. `subtask.id` pattern `sub-{N}`** — Used in commit messages by all three commands. The commands reference it as `{subtask-id}` from the YAML. No regex validation of the `sub-{N}` pattern is described — any non-empty string would be interpolated. However, resume-ticket.md identifies partial completion by reading the task tree YAML and finding `in_progress` or `pending` status entries, which relies on `id` being a stable key.

### Robust (structural, fail loudly on change)

**5. Required field validation** — implement-feature.md line 115 checks for presence of `title`, `scope`, `files`, `estimated_lines`, `acceptance_criteria`. Missing any of these → Block. This check is explicit.

**6. DAG cycle detection** — implement-feature.md lines 110–112 performs topological sort. If `depends_on` contains IDs that don't exist as subtask `id` values → cycle detection finds them as unresolved and blocks.

**7. Max subtasks limit** — implement-feature.md line 113 checks count against config limit. Exceeding limit → Block.

### Silent failures (no error, wrong behavior)

**8. Unmapped AC in YOLO mode** — If `maps_to` entries exist but use wrong format (no `AC-{N}:` prefix), each is treated as a warning, not an error (implement-feature.md line 131). In non-YOLO mode the user is asked to confirm; in YOLO mode the pipeline blocks. But if the regex simply fails to match, the warning is generic.

**9. `maps_to` N values outside range** — If architect emits `AC-0:` (zero-indexed) or `AC-{N}:` for N > total parent AC count, the coverage check computes set difference against `1..total` and those entries simply never satisfy any requirement. No out-of-range error is defined.

---

## Gaps

1. **No formal spec for how commands detect `YES` vs `NO` decomposition** — implement-feature.md line 107 says "architect indicates decomposition" without defining which substring or field triggers this. It is inferred from the architect's `**Decomposition:** YES/NO` bullet, but no explicit string match rule is written in the command.

2. **`id` field not in the required-field validation list** — implement-feature.md line 115 lists required fields as `title, scope, files, estimated_lines, acceptance_criteria`. `id` is absent from this validation despite being used in commit messages and task tree resume logic. An architect output without `id` fields would pass validation but break commit message formatting.

3. **`maps_to` not in the required-field validation list** — The `maps_to` field is separately validated by the AC coverage check, but only when AC are provided from triage/spec-analyst. If triage is skipped (via pipeline profile) and no parent AC exist, the coverage check is vacuously satisfied and `maps_to` is never parsed.

4. **No definition of how per-subtask vs. total AC is scoped in decomposition** — implement-feature.md line 213 explicitly states the acceptance-gate receives "full feature AC, not just per-subtask AC." But the fixer receives "current subtask (scope, files, acceptance criteria)" (line 161) — meaning the per-subtask `acceptance_criteria` from the architect's YAML, not the parent AC. This creates two parallel AC lists that are never reconciled by any described parsing step.

5. **`strategy` field is not used in execution logic** — The `decomposition.strategy` value (`sequential`, `parallel`, `mixed`) appears in the display plan but no command describes using it to actually run subtasks in parallel. All three commands show sequential topological-sort execution. Whether `parallel` and `mixed` strategies are honored at runtime is not specified in any command.

6. **No schema for the `.claude/decomposition/{ISSUE-ID}.yaml` persisted file** — The runtime fields `status`, `commit_hash`, `restore_point` are written to disk by commands, but their exact YAML schema is never defined. Resume-ticket.md reads them by key (`in_progress`, `pending`, `completed`) but the file schema is implicit.

---

## Compatibility Assessment: Mode-Based Unified Agent vs. Separate Named Agents

The architect interface contract as consumed by implement-feature.md, fix-ticket.md, fix-bugs.md, and scaffold.md is defined entirely by:

1. The YAML field names: `decomposition.strategy`, `decomposition.reason`, `subtasks[].id`, `.title`, `.scope`, `.files`, `.estimated_lines`, `.depends_on`, `.maps_to`, `.acceptance_criteria`
2. The `maps_to` string format: `"AC-{N}: {text}"` with integer N parsed by index
3. The `**Decomposition:** YES/NO` markdown bullet as decomposition signal
4. The Block output format (passed through to issue tracker)

A mode-based unified agent is MORE compatible with the existing contract than separate named agents, provided the ceos-pipeline mode emits field names identical to the current architect output. No consuming command parses agent identity or name — they only parse the YAML structure. A unified agent that emits the same YAML schema in ceos mode requires zero changes to any of the three consuming commands.

Separate named agents would be equally compatible only if each emitted the identical YAML schema. The risk of divergence is the same, but the indirection (two agents to maintain) adds drift surface.

The critical constraint: any unified agent MUST preserve `maps_to: "AC-{N}: {text}"` format exactly, because the coverage check in all three commands parses the `AC-{N}:` prefix by regex with no fallback. A format change here is a silent correctness regression — no Block, no error, no warning in non-YOLO mode.
