# Research Answers — Agent 2

## FBX-4: Timing of "On start set" in fix-bugs

**Finding:** The fix-bugs SKILL.md does NOT currently have an "On start set" step (equivalent to fix-ticket Step 1). The per-issue processing loop begins at Step 2 (Triage, parallel), which runs immediately after Step 1 (Fetch bugs).

**Current structure relevant to insertion point:**
```
### 1. Fetch bugs
Use Bug query from Automation Config via the MCP server matching Type. Limit = count from $ARGUMENTS.

### 2. Triage (parallel — triage is read-only, parallelism does not depend on worktree configuration)
```

There is no "On start set" step between fetching a specific issue and beginning triage. The worktree section (Variant A, step 3) says: "Run the pipeline (steps 2–8) for EVERY bug in the batch IN PARALLEL" — meaning the per-issue loop runs steps 2–8.

**Where step 1a should go:** Immediately after step 1 (Fetch bugs) and BEFORE step 2 (Triage), as a per-issue action within the loop. In the sequential variant, this is natural: before processing each individual issue, set "On start set". In the parallel worktree variant, each Task spawned receives the issue ID and would fire "On start set" at the top of that per-bug execution, before triage.

The task spec is correct: "On start set" is a per-issue step — it runs for each issue in the batch, not once at the start. The correct insertion point is AFTER fetching the batch (step 1) but BEFORE triage for each individual issue (step 2). In fix-bugs this means it should appear as a new step 1a inside the per-issue processing loop, executed before triage is launched.

---

## FBX-5: Worktree parallel range

**Finding:** The Worktree section (Variant A) specifies the parallel range in this sentence:

> "Run the pipeline (steps 2–8) for EVERY bug in the batch IN PARALLEL"

The range is explicitly **steps 2–8**. Inserting step 1a before step 2 (but still within the per-issue context) requires updating this range to **steps 1a–8**. Otherwise step 1a would not be included in the parallel per-issue processing for each Task spawned.

**Exact location in SKILL.md (around line 697):**
```
**Parallel execution:**
3. Run the pipeline (steps 2–8) for EVERY bug in the batch IN PARALLEL:
   - Use the Task tool for each bug — all Task calls in ONE message block
   - Each Task receives context: worktree path, issue ID, complete Automation Config
```

Yes, inserting step 1a requires updating the range from `steps 2–8` to `steps 1a–8`.

---

## XR-3: docs/reference/skills.md — fix-bugs step enumeration

**Finding:** The `/fix-bugs` section in `docs/reference/skills.md` does NOT enumerate individual pipeline steps by number. The "What it does" description is a high-level prose summary:

> "Queries the issue tracker using the Bug query from Automation Config, then processes up to N bugs through the full pipeline. Supports parallel processing via worktrees when the Worktrees section is configured. Produces a summary table showing the status of each bug (FIXED, BLOCKED, DUPLICATE). When decomposition is active, creates corresponding tracker sub-issues under the parent issue before executing subtasks (configurable via `Create tracker subtasks` in Decomposition config)."

No step numbers are mentioned. Step 1a insertion does NOT require updating `docs/reference/skills.md`.

---

## XR-4: skills/resume-ticket/SKILL.md — fix-bugs step number references

**Finding:** `skills/resume-ticket/SKILL.md` references fix-ticket step numbers (e.g., "start from code-analyst (step 4)", "start from fixer (step 5)", "start from reviewer (step 7)", "start from test-engineer (step 8)"), but these reference **fix-ticket** steps, not fix-bugs steps.

The BUG pipeline checkpoint table in resume-ticket reads:
```
- `POST_TRIAGE` → start from code-analyst (step 4)
- `POST_ANALYSIS` → start from fixer (step 5)
- `POST_FIX` → start from reviewer (step 7)
- `POST_REVIEW` → start from test-engineer (step 8)
```

These step numbers refer to fix-ticket's pipeline steps, not fix-bugs steps. Resume-ticket dispatches fix-ticket for BUG pipeline resumption. Step 1a in fix-bugs (the "On start set" per-issue step) would be a fix-bugs-only step and would NOT be referenced in resume-ticket's step mapping.

**Conclusion:** Inserting step 1a into fix-bugs does NOT require updating `skills/resume-ticket/SKILL.md`.

---

## XR-5: checklists/ — fix-bugs step number references

**Files found:**
- `checklists/publish-checklist.md`
- `checklists/review-checklist.md`
- `checklists/test-checklist.md`

**Finding:** A grep for "fix-bugs", "step [0-9]", or "Step [0-9]" across all three checklist files returned **no matches**. The checklists contain only generic bullet-point quality gates (correctness, security, quality, edge cases, integration) with no references to specific pipeline step numbers or to fix-bugs.

**Conclusion:** Step 1a insertion does NOT require updating any checklist file.

---

## FBX-6: Dry-run section — step range

**Finding:** The Dry-run section in fix-bugs SKILL.md specifies:

In the Orchestration section:
> "If `--dry-run` mode is active → run only steps 1–3, then generate a dry-run report (see Dry-run section). No side effects: no issue tracker state changes, no worktrees, no git operations."

And in the Code-analyst step (step 3):
> "*If dry-run → stop here, proceed to Dry-run report.*"

The dry-run range is **steps 1–3** (Fetch bugs → Triage → Code-analyst). Step 1a would be inserted between step 1 (Fetch bugs) and step 2 (Triage). Since dry-run runs steps 1–3, and step 1a falls within this range (between 1 and 2), step 1a WOULD execute during dry-run.

**Impact assessment:** The "On start set" state transition updates the issue tracker state. The dry-run section explicitly states "No side effects: no issue tracker state changes." Therefore, step 1a must include a dry-run guard: if `--dry-run` is active → skip "On start set" (no issue tracker state change). The step range reference "steps 1–3" does not need updating in text since 1a is implicitly between 1 and 2, but the step 1a definition must specify the dry-run skip condition.
