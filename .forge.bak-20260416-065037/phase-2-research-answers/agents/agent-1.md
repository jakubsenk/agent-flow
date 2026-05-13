# Research Answers — Agent 1 (Items 1–3, Q1–Q7)

## Q1. Verbatim text of line 33 in `core/config-reader.md` and surrounding inline format

**Line 33 (exact verbatim):**
```
   - `### Decomposition` → `decomposition.max_subtasks` (default: 7), `decomposition.fail_strategy` (default: `fail-fast`), `decomposition.commit_strategy` (default: `squash`)
```

**Context (lines 32–34):**
```
32:    - `### Feature Workflow` → `feature.query`, `feature.on_start_set` (default: none)
33:    - `### Decomposition` → `decomposition.max_subtasks` (default: 7), `decomposition.fail_strategy` (default: `fail-fast`), `decomposition.commit_strategy` (default: `squash`)
34:    - `### Pipeline Profiles` → `profiles` (list of `{name, skip_stages, extra_stages}`) (default: none)
```

**Inline format used by surrounding optional sections:**
The format is comma-separated inline on a single bullet line:
```
`### Section Name` → `key1` (default: value), `key2` (default: value), `key3` (default: value)
```

**Observation:** `create_tracker_subtasks` / `decomposition.create_tracker_subtasks` is NOT present on line 33. The Decomposition entry lists only 3 fields: `max_subtasks`, `fail_strategy`, `commit_strategy`. The CLAUDE.md config contract and fix-ticket/fix-bugs skill files reference a 4th field "Create tracker subtasks (default: enabled)" which is absent from `core/config-reader.md` line 33.

---

## Q2. Is `create_tracker_subtasks` already in fix-ticket and fix-bugs Configuration sections?

**`skills/fix-ticket/SKILL.md` — Configuration section (lines 40–44):**
```
- **Decomposition** from Decomposition section (if it exists):
  - Max subtasks (default: 7)
  - Fail strategy (default: fail-fast)
  - Commit strategy (default: squash)
  - Create tracker subtasks (default: enabled)
```

**YES** — `Create tracker subtasks (default: enabled)` is present at line 44 in fix-ticket.

**`skills/fix-bugs/SKILL.md` — Configuration section (lines 34–38):**
```
- **Decomposition** from Decomposition section (if it exists):
  - Max subtasks (default: 7)
  - Fail strategy (default: fail-fast)
  - Commit strategy (default: squash)
  - Create tracker subtasks (default: enabled)
```

**YES** — `Create tracker subtasks (default: enabled)` is present at line 38 in fix-bugs.

**Conclusion:** Both files already list `Create tracker subtasks (default: enabled)`. The gap is only in `core/config-reader.md` line 33 (Decomposition entry).

---

## Q3. Verbatim text of Step 0b in `skills/fix-ticket/SKILL.md`

**Lines 87–105 (exact verbatim):**
```
### Step 0b: Config Validity Gate

Follow the same validation logic as implement-feature.md Step 0b:

1. Read `## Automation Config` from CLAUDE.md
2. Check each required section (Issue Tracker, Source Control, PR Rules, Build & Test) for `<!-- TODO:` or `<...>` placeholders or empty values — collect into `incomplete_keys[]`
3. If `incomplete_keys` is not empty → **BLOCK** with `[ceos-agents]` block output:
   ```
   [ceos-agents] 🔴 Pipeline Block
   Agent: config-validator
   Step: Config Validity Gate (Step 0b)
   Reason: Required configuration is incomplete.
   Detail: Incomplete keys: {comma-separated list of incomplete keys}
   Recommendation: Run `/ceos-agents:onboard --update` to fill in missing values, or edit CLAUDE.md manually. Then run `/ceos-agents:check-setup` to verify.
   ```
   Stop pipeline execution.
4. For optional sections with `<!-- TODO:` markers: log WARN but do NOT block
   - Display: `⚠️ Optional section "{section}" has incomplete values — pipeline will continue but some features may be unavailable`
5. If all required sections are complete: proceed to Step 1
```

**Context — line 87 is the first line of Step 0b, directly under the `## Steps` section heading at line 107.**

Note: The `### Step 0b` section appears at line 87 but the `## Steps` heading appears at line 107. This means Step 0b is placed in the file BEFORE the `## Steps` heading, between the `## Pipeline profile parsing` section and `## Steps`.

---

## Q4. Exact pre-Step-1 structure in `skills/fix-bugs/SKILL.md`

The pre-Step-1 structure consists of:

**Line 1–7:** Frontmatter (--- ... ---)

**Line 9:** `# Fix Bugs Pipeline`

**Line 17:** `## Configuration` (section heading, line 17)

**Line 55:** `## Pipeline profile parsing` (section heading, line 55)

**Line 80:** `### 0. MCP pre-flight check` (sub-section, line 80)

**Line 94:** `## Orchestration` (section heading, line 94)

**Line 96:** `### 0. Dry-run check` (sub-section, line 96)

**Line 98:** `### 1. Fetch bugs` (step 1 start, line 98–100)

**Key observations:**
- In fix-bugs, there is NO `### Step 0b: Config Validity Gate` — this is a gap vs fix-ticket.
- The `## Configuration` section (lines 17–53) lists all config keys inline.
- The `## Orchestration` heading (line 94) introduces the numbered pipeline steps.
- The contributor note comment at line 89 appears inside `### 0. MCP pre-flight check`.

**Exact section heading lines with line numbers:**
| Line | Text |
|------|------|
| 17 | `## Configuration` |
| 55 | `## Pipeline profile parsing` |
| 80 | `### 0. MCP pre-flight check` |
| 94 | `## Orchestration` |
| 96 | `### 0. Dry-run check` |
| 98 | `### 1. Fetch bugs` |

---

## Q5. Exact table row texts for `config.retry_limits` fields in `state/schema.md`

**Lines 155–158 (exact verbatim):**
```
| `config.retry_limits` | object | Yes | — | Active retry limits (resolved from Automation Config or defaults). |
| `config.retry_limits.fixer_iterations` | integer | Yes | `5` | Max fixer-reviewer loop iterations. |
| `config.retry_limits.test_attempts` | integer | Yes | `3` | Max test-engineer retry attempts. |
| `config.retry_limits.build_retries` | integer | Yes | `3` | Max build retry attempts. |
```

**Line 158** is the `build_retries` row. **Line 159** immediately follows:
```
159: | `infrastructure` | object or null | No | `null` | Infrastructure declarations from scaffold Step 0-INFRA. Persists tracker and SC readiness for resume. Only populated by scaffold pipeline. |
```

So the line following `build_retries` (line 158) is line 159 — the `infrastructure` top-level field row.

---

## Q6. Exact JSON snippet for `retry_limits` in `state/schema.md` example block

**Lines 47–51 (exact verbatim):**
```json
    "retry_limits": {
      "fixer_iterations": 5,
      "test_attempts": 3,
      "build_retries": 3
    }
```

This appears inside the `"config"` object (lines 44–52):
```json
  "config": {
    "profile": "default",
    "flags": [],
    "retry_limits": {
      "fixer_iterations": 5,
      "test_attempts": 3,
      "build_retries": 3
    }
  },
```

**Observation:** Only 3 fields are present: `fixer_iterations`, `test_attempts`, `build_retries`. The fields `spec_iterations` and `root_cause_iterations` are absent from both the JSON example block AND the field definitions table in `state/schema.md`.

---

## Q7. Do fix-bugs and fix-ticket list `Spec iterations` under Retry Limits in their Configuration sections?

**`skills/fix-ticket/SKILL.md` — Retry limits block (lines 30–34):**
```
- **Retry limits** from Retry Limits section (if it exists):
  - Fixer iterations (default: 5)
  - Test attempts (default: 3)
  - Build retries (default: 3)
  - Root cause iterations (default: 3)
```

**NO** — `Spec iterations` is NOT listed in fix-ticket's Retry Limits.

**`skills/fix-bugs/SKILL.md` — Retry limits block (lines 23–27):**
```
- **Retry limits** from Retry Limits section (if it exists):
  - Fixer iterations (default: 5)
  - Test attempts (default: 3)
  - Build retries (default: 3)
  - Root cause iterations (default: 3)
```

**NO** — `Spec iterations` is NOT listed in fix-bugs's Retry Limits either.

**Conclusion:** Both fix-ticket and fix-bugs list `Root cause iterations` (which is specific to the bug pipeline) but do NOT list `Spec iterations` (which belongs to the feature/scaffold pipeline). This is correct and expected behavior — `spec_iterations` is not applicable to the bug-fix pipeline.

---

## Summary of Insertion Points

| Gap | File | Location | Action Needed |
|-----|------|----------|---------------|
| Missing `decomposition.create_tracker_subtasks` | `core/config-reader.md` | Line 33, append to Decomposition entry | Add `, `decomposition.create_tracker_subtasks` (default: `enabled`)` |
| Missing `spec_iterations` and `root_cause_iterations` in state schema | `state/schema.md` | After line 158 (after `build_retries` row) | Add 2 new table rows |
| Missing `spec_iterations` and `root_cause_iterations` in JSON example | `state/schema.md` | After line 50 (`"build_retries": 3`) | Add 2 new JSON fields |
| Missing Step 0b (Config Validity Gate) | `skills/fix-bugs/SKILL.md` | After `### 0. MCP pre-flight check`, before `## Orchestration` | Add Step 0b section (same as fix-ticket) |
