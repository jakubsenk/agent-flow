# Research Questions — Agent 1 (Contract Integrity: Items 1–3)

Focus: `core/config-reader.md` Decomposition key gap, `skills/fix-bugs/SKILL.md` missing Config Validity Gate, `state/schema.md` retry_limits gap.

---

## Research Questions

1. **What is the exact line in `core/config-reader.md` where `create_tracker_subtasks` must be inserted, and what is the verbatim pattern of the surrounding keys to match?**

   Rationale: Line 33 of `core/config-reader.md` contains the Decomposition section entry:
   `- \`### Decomposition\` → \`decomposition.max_subtasks\` (default: 7), \`decomposition.fail_strategy\` (default: \`fail-fast\`), \`decomposition.commit_strategy\` (default: \`squash\`)`
   The key `decomposition.create_tracker_subtasks` (default: `enabled`) is referenced in both `fix-ticket/SKILL.md` (line 44) and `fix-bugs/SKILL.md` (line 38) but absent here. The exact insertion point is at the end of this line — appended as `, \`decomposition.create_tracker_subtasks\` (default: \`enabled\`)`. Confirm the comma-separated inline format is consistent with all other multi-key optional sections (e.g., Retry Limits line 23, Browser Verification line 29).

2. **What is the verbatim text of Step 0b in `skills/fix-ticket/SKILL.md` that must be copied into `skills/fix-bugs/SKILL.md`?**

   Rationale: `fix-ticket/SKILL.md` lines 87–105 contain the full Step 0b definition. It must be transplanted into `fix-bugs/SKILL.md`. The exact text needs to be confirmed so the copy is character-for-character accurate, including the heading (`### Step 0b: Config Validity Gate`), all 5 numbered sub-steps, and the block template. Note that `fix-ticket/SKILL.md` says "Follow the same validation logic as implement-feature.md Step 0b" at line 89 — verify whether `fix-bugs` should also use that delegation pattern or copy the full inline text.

3. **Where exactly in `skills/fix-bugs/SKILL.md` should Step 0b be inserted, and what step numbering is currently present before Step 1?**

   Rationale: The fix-bugs skill has these pre-Step-1 sections (all before `### 1. Fetch bugs` at line 98):
   - `### 0. MCP pre-flight check` (line 80, inside the pre-`## Orchestration` block)
   - `## Orchestration` heading (line 93)
   - `### 0. Dry-run check` (line 94)

   There is no `### Step 0b` in fix-bugs. The insertion point must be determined: should it go between `### 0. Dry-run check` and `### 1. Fetch bugs`, matching the fix-ticket pattern where `### Step 0b` comes after `### 0. Dry-run check` (line 109) and before `### 1. Set issue tracker` (line 113)? Note the fix-ticket skill uses `### Step 0b:` naming (not `### 0b.`) — verify if fix-bugs should use the same heading style for consistency.

4. **What are the exact field definitions (line numbers and table row format) for the 3 existing fields in `config.retry_limits` in `state/schema.md`, and where should the 2 missing fields be inserted?**

   Rationale: `state/schema.md` lines 155–158 define `config.retry_limits` with only 3 fields:
   ```
   | `config.retry_limits` | object | Yes | — | Active retry limits (resolved from Automation Config or defaults). |
   | `config.retry_limits.fixer_iterations` | integer | Yes | `5` | Max fixer-reviewer loop iterations. |
   | `config.retry_limits.test_attempts` | integer | Yes | `3` | Max test-engineer retry attempts. |
   | `config.retry_limits.build_retries` | integer | Yes | `3` | Max build retry attempts. |
   ```
   Missing fields are `config.retry_limits.spec_iterations` (default: 5, from config-reader.md line 23) and `config.retry_limits.root_cause_iterations` (default: 3, from config-reader.md line 23). Verify the insertion is after `build_retries` (line 158), and confirm the JSON example block at lines 47–51 also needs updating (currently shows only `fixer_iterations`, `test_attempts`, `build_retries`).

5. **Does the JSON example block in `state/schema.md` (lines 33–136) need to be updated alongside the field definitions table, and what exact JSON snippet should replace the current `retry_limits` object?**

   Rationale: The schema example at lines 46–51 shows:
   ```json
   "retry_limits": {
     "fixer_iterations": 5,
     "test_attempts": 3,
     "build_retries": 3
   }
   ```
   This must be updated to include `"spec_iterations": 5` and `"root_cause_iterations": 3` to stay consistent with the field definitions table. Confirm order: should new fields follow `build_retries` (alphabetical is irrelevant here — confirm by config-reader.md order: fixer_iterations, test_attempts, build_retries, spec_iterations, root_cause_iterations).

6. **Does `skills/fix-bugs/SKILL.md` Configuration section already reference `spec_iterations` in the Retry Limits block, or is it also missing there?**

   Rationale: `fix-bugs/SKILL.md` lines 23–27 list Retry Limits as:
   - Fixer iterations (default: 5)
   - Test attempts (default: 3)
   - Build retries (default: 3)
   - Root cause iterations (default: 3)

   This matches `fix-ticket/SKILL.md` lines 32–35 exactly — both are missing `Spec iterations`. However, since fix-bugs does not run the spec pipeline, `spec_iterations` may be intentionally absent from these two skills but still required in `state/schema.md` (which is pipeline-agnostic). Confirm whether fix-bugs/fix-ticket Configuration sections should also gain the `Spec iterations` entry, or whether only `state/schema.md` needs the update.

7. **Is `create_tracker_subtasks` also missing from the Configuration section of `skills/fix-bugs/SKILL.md` and `skills/fix-ticket/SKILL.md`, or only from `core/config-reader.md`?**

   Rationale: `fix-ticket/SKILL.md` line 44 explicitly lists `Create tracker subtasks (default: enabled)` under its Decomposition section. `fix-bugs/SKILL.md` line 38 does the same. Both skills already have it. The gap is only in `core/config-reader.md` line 33, which is the authoritative parse spec. This confirms the single-file fix scope for Item 1.
