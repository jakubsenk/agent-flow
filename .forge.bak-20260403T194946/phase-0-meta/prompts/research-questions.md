# Phase 1 — Research Questions

## Persona
{{PERSONA}}: Senior Claude Code Plugin Engineer specializing in pipeline orchestration markdown definitions, state persistence patterns, and agent-skill contract design.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

You are investigating two bugs in `skills/implement-feature/SKILL.md`:

1. **Subtask persistence failure:** After the architect agent decomposes a feature into subtasks, the task tree is not persisted to files or state.json. The "Save task tree" instruction exists at Step 5 (line 235) and Step 6h (line 322) but may be insufficient.

2. **Confirmation flow disorder:** The skill asks for user confirmations at wrong points, breaking autonomous execution. The `--yolo` flag should auto-approve all confirmations.

### Research Questions

Answer these questions by reading the codebase:

1. **Persistence delta:** Compare `skills/implement-feature/SKILL.md` Step 5 ("Save task tree" + state.json update at line 235-237) with `skills/fix-ticket/SKILL.md` Step 4b (lines 169-182). What exactly does fix-ticket do that implement-feature does not? List every persistence action line by line.

2. **State.json decomposition writes:** In implement-feature, where exactly are `decomposition.status`, `decomposition.decision`, `decomposition.strategy`, and `decomposition.subtasks` written? Compare with the state schema (`state/schema.md` lines 185-189). Are all four fields covered?

3. **Step 6h task tree update:** Implement-feature Step 6h (line 322) says "Update the task tree state on disk (.claude/decomposition/)." Is this instruction clear enough for an LLM executor to know WHAT to write and WHERE? Compare with fix-ticket Step 4c point 9 (line 196).

4. **Confirmation inventory:** List every `[Y/n]` and `[y/N]` prompt in implement-feature/SKILL.md. For each, identify: (a) which step it's in, (b) whether `--yolo` bypasses it, (c) whether it's appropriate for that pipeline stage.

5. **YOLO coverage gaps:** Search for all places in implement-feature that check for `--yolo`. Are there any confirmation prompts that do NOT have a `--yolo` auto-approve branch? Are there any `--yolo` checks that auto-approve something that should always require confirmation?

6. **fix-ticket confirmation model:** How does fix-ticket handle confirmations? Does it have the same pattern (decomposition plan + publish decision only)?

7. **Decomposition subtask state during execution:** In implement-feature Step 6 (subtask execution loop), is the per-subtask status tracked? When a subtask completes (Step 6h), does the state get written to both `.claude/decomposition/{ISSUE-ID}.yaml` and `state.json`?

## Success Criteria
{{SUCCESS_CRITERIA}}:
- All 7 questions answered with specific file paths and line numbers
- Every persistence gap identified with before/after comparison
- Every confirmation point catalogued with YOLO-bypass status
- Clear delta table: "implement-feature has X, fix-ticket has Y, gap is Z"

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. Reading only implement-feature without comparing to fix-ticket (the reference implementation)
2. Assuming the markdown text is sufficient without checking whether an LLM executor would interpret it correctly
3. Conflating "the instruction exists" with "the instruction is complete" — a vague instruction in markdown is a bug even if the topic is mentioned
4. Ignoring the state.json schema when evaluating persistence completeness
5. Missing the distinction between `.claude/decomposition/` file persistence and `state.json` field persistence — both must work

## Codebase Context
{{CODEBASE_CONTEXT}}:
Pure markdown Claude Code plugin. No runtime code. Files to read:
- `skills/implement-feature/SKILL.md` — primary bug location
- `skills/fix-ticket/SKILL.md` — reference implementation
- `state/schema.md` — persistence schema
- `core/decomposition-heuristics.md` — shared decomposition logic
- `agents/architect.md` — architect output format
