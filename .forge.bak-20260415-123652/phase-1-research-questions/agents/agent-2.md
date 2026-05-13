# Research Questions — Agent 2: Pipeline Contract Analyst
## Focus: fix-bugs "On start set" Step + Cross-Reference Integrity

---

## Section 1: fix-bugs Per-Issue Loop Structure

### Q1. What is the current step numbering sequence in fix-bugs?

**Finding from file read:** `skills/fix-bugs/SKILL.md` uses this top-level numbered sequence:

- Step 0: MCP pre-flight check (global, before any per-issue work)
- Step 0 (also): Dry-run check
- Step 1: Fetch bugs (global — fetches all N bugs at once)
- Step 2: Triage (parallel, per-bug)
- Step 3: Code-analyst (parallel, per-bug)
- Step 3a: Decompose flag parsing
- Step 3b: Decomposition decision (per-bug)
- Step 3b-tracker: Create tracker subtasks
- Step 3c: Subtask execution (decomposition, per-bug)
- Step 3d: Pre-fix hook
- Step 3e: Browser Reproduction
- Step 4: Fixer
- Step 5: Build
- Step 5a: Post-fix hook
- Step 5b: Post-fix custom agent
- Step 6: Reviewer
- Step 6a: Smoke check (post-review)
- Step 7: Test-engineer
- Step 7a-deploy: Deployment guard (pre-E2E)
- Step 7b: E2E test-engineer
- Step 7b-browser: Browser Verification
- Step 7c: Acceptance gate (conditional)
- Step 7d: Pre-publish hook
- Step 7e: Pre-publish custom agent
- Step 8: Publisher
- Step 8a: Post-publish hook
- Step 8b: Webhook — PR created
- Step 8c: Fix Verification (optional, per-bug)
- Step 9: Summary
- Step 9a: Webhook — pipeline-complete
- Step X: Block handler

**Research Question 1a:** The "per-issue loop" in fix-bugs is not a single explicit loop step — triage (step 2) and code-analyst (step 3) are parallel, while steps 4–8 are sequential per-bug (with worktree variant running steps 2–8 in parallel Tasks). Where exactly in the sequential flow should "On start set" be inserted?

**Research Question 1b:** fix-ticket's Step 1 ("Set issue tracker") occurs AFTER MCP pre-flight and BEFORE branch creation and triage. In fix-bugs, there is no branch creation step (branches are created implicitly per-bug during worktree setup or fixer). Should the new step go between step 1 (Fetch bugs) and step 2 (Triage) as a new step 1a or 1b? Or before step 2 within the parallel triage execution loop?

**Research Question 1c:** fix-bugs runs triage in parallel for ALL bugs before any per-bug fix work begins. "In Progress" semantics mean the issue is actively being worked. Setting all N issues to "In Progress" during triage may be premature — triage may result in DUPLICATE or UNCLEAR outcomes. Should "On start set" fire before triage (optimistic) or after triage passes (only for bugs that proceed to fix)?

**Research Question 1d:** The worktree variant reference says "Run the pipeline (steps 2–8) for EVERY bug in the batch IN PARALLEL." If the new "On start set" step is numbered as step 1a (between step 1 and step 2), it would NOT be included in the worktree parallel range. Does this matter? Should it be step 2a (inserted after triage, before code-analyst) so it falls within the parallel range, or is the worktree range reference just illustrative and will be updated alongside the new step?

**Research Question 1e:** The dry-run check at step 0 says "No side effects: no issue tracker state changes." Does this mean the new "On start set" step must also carry a "*In dry-run: skip this step.*" annotation, matching fix-ticket's Step 1?

---

## Section 2: Pattern Matching — fix-ticket Step 1

### Q2. What is the exact wording of fix-ticket Step 1?

**Finding from file read:** `skills/fix-ticket/SKILL.md` lines 112–119:

```
### 1. Set issue tracker

Set the state per Automation Config (Issue Tracker → On start set). Read Type for the correct MCP server.

After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

*In dry-run: skip this step.*
```

**Research Question 2a:** The fix-ticket step is titled "Set issue tracker" — not "Set issue state" or "Set In Progress." Should fix-bugs use the same heading "Set issue tracker" for consistency, or something slightly different given that fix-bugs processes multiple issues (e.g., "Set issue state" repeated per-bug)?

**Research Question 2b:** fix-ticket Step 1 references `core/status-verification.md` immediately after the status-set MCP call. The roadmap entry for v6.6.0 says that `skills/fix-bugs/SKILL.md` block handler is one of the 4 remaining sites where status verification needs wiring. Should the new "On start set" step in fix-bugs ALSO include a `core/status-verification.md` reference (as fix-ticket does), or is it enough to just set the state without verification for this step?

**Research Question 2c:** fix-ticket Step 1 says "Read Type for the correct MCP server." fix-bugs already reads Type during configuration (step 0 MCP pre-flight). Should the new step reference Type reading again, or simply say "Use the MCP server for {Type}" (implying it's already in context)?

**Research Question 2d:** implement-feature Step 1 says: "Read the issue from the issue tracker. Set the state per Feature Workflow → On start set (fallback: Issue Tracker → On start set)." fix-bugs uses no Feature Workflow section — it uses Bug query. Should the new fix-bugs step mirror fix-ticket exactly (Issue Tracker → On start set only) rather than the implement-feature pattern?

---

## Section 3: Stage Mapping Table — Step Number Renumbering Impact

### Q3. Does adding a new step between step 1 and step 2 require updating the stage mapping table?

**Finding from file read:** `skills/fix-bugs/SKILL.md` lines 65–71 contain this stage mapping:

```
Stage mapping for bug pipeline (fix-bugs):
- `triage` = step 2 (Triage)
- `code-analyst` = step 3 (Code-analyst)
- `test-engineer` = step 7 (Test-engineer)
- `e2e-test-engineer` = step 7b (E2E test-engineer)
- `reproducer` = step 3e (Browser Reproduction)
- `browser-verifier` = step 7b-browser (Browser Verification)
```

**Research Question 3a:** If the new "On start set" step is numbered step 1a (inserted between step 1 and step 2), the stage mapping table does NOT need updating — all steps referenced keep their numbers. Is this the safest insertion point from a numbering perspective?

**Research Question 3b:** Alternatively, if the new step replaces the existing step numbering (e.g., current step 1 becomes step 1, new step becomes step 1a, triage stays step 2), no renumbering occurs. This is preferable. Confirm: does inserting step 1a leave triage at step 2, code-analyst at step 3, etc. — requiring zero changes to the stage mapping table?

**Research Question 3c:** fix-ticket uses step 3 for triage, step 4 for code-analyst. fix-bugs uses step 2 for triage, step 3 for code-analyst. The numbering is already different between the two skills, so the fix-bugs step numbering doesn't need to mirror fix-ticket's Step 1 numbering — it just needs to be consistent within fix-bugs. Is "Step 1a" the right sub-step label convention, or should it be "Step 1b" (to leave 1a available), or should it be a brand-new top-level step (making current step 1 into "1. Fetch bugs" and new step "1a. Set issue state")?

---

## Section 4: Cross-Reference Integrity

### Q4. What cross-references need updating when adding the new "On start set" step?

**Finding — CLAUDE.md core count:** Line 27 states:
```
- `core/` — 12 shared pipeline pattern contracts
```
There are currently exactly 12 files in `core/`:
`agent-override-injector.md`, `fix-verification.md`, `profile-parser.md`, `post-publish-hook.md`, `state-manager.md`, `mcp-preflight.md`, `mcp-detection.md`, `fixer-reviewer-loop.md`, `decomposition-heuristics.md`, `config-reader.md`, `status-verification.md`, `block-handler.md`

The fix-bugs "On start set" step itself does NOT create a new core file — it is purely a step added to `skills/fix-bugs/SKILL.md`. The core count of 12 only becomes 13 when `core/mcp-body-formatting.md` is created (separate v6.6.0 item).

**Research Question 4a:** For the "fix-bugs On start set" item specifically, does CLAUDE.md require any update? The step addition doesn't create a new core file and doesn't change the agent count or skill count. Is the only file change `skills/fix-bugs/SKILL.md`?

**Research Question 4b:** Does the worktree parallel execution reference "Run the pipeline (steps 2–8)" need to be updated? If the new step is "1a," the worktree range "steps 2–8" still starts at triage (step 2), which is correct — the "On start set" step would run before the parallel dispatch. Should the reference be updated to "steps 1a–8" or "steps 2–8 (plus step 1a for issue state)"?

**Research Question 4c:** Does the dry-run section ("run only steps 1–3") need updating? If a new step 1a is added and it must be skipped in dry-run, but the dry-run range is stated as "steps 1–3," the new step 1a falls within this range. Does the dry-run section need to be amended to say "steps 1–3 (skipping step 1a as it has issue tracker side effects)" — or is the dry-run annotation within the step itself sufficient?

**Research Question 4d:** The roadmap entry for v6.6.0 fix-bugs step says: "Files: `skills/fix-bugs/SKILL.md`. Impact: MINOR." It also says "currently fix-bugs is the only pipeline skill that doesn't set issue state on start — it delegates to publisher for 'For Review' but never sets 'In Progress'." Does this mean publisher already handles the final state transition? Is there a risk that adding "In Progress" at start conflicts with the existing publisher state transition sequence?

**Research Question 4e:** The CLAUDE.md `## Bug-Fix Pipeline` architecture description does not enumerate individual pipeline steps by number. It uses a flow diagram. Does this description need updating to mention the new initial state-setting behavior, or is it already implied by the existing pipeline description?

---

## Section 5: Additional Cross-References in Docs and Tests

### Q5. Are there other places in the repo that reference fix-bugs step numbering that would need updating?

**Research Question 5a:** The `docs/reference/skills.md` (or equivalent reference doc) may describe fix-bugs pipeline steps. Does it list numbered steps that would be affected by inserting step 1a?

**Research Question 5b:** The `tests/` directory may have test scenarios that reference fix-bugs step numbers (e.g., "step 2" for triage). Would adding step 1a require updates to any test scenario files?

**Research Question 5c:** The `checklists/` directory may reference pipeline steps by number for fix-bugs. Do any checklist files enumerate steps that would shift due to the new insertion?

**Research Question 5d:** The `/ceos-agents:resume-ticket` skill may reference step numbers or step names for the fix-bugs pipeline to determine where to resume. Would adding step 1a break resume-ticket's ability to correctly identify pipeline position?

---

## Summary of Key Findings

| Finding | Impact |
|---------|--------|
| fix-bugs has no "On start set" step | Single file change: `skills/fix-bugs/SKILL.md` |
| Insertion point: between step 1 (Fetch) and step 2 (Triage) | Step "1a" — no renumbering of existing steps |
| Stage mapping table (steps 2–7b) unaffected | Zero updates to stage mapping section |
| fix-ticket Step 1 exact pattern: 3 lines (set state + status-verification + dry-run skip) | Match this pattern exactly |
| CLAUDE.md core count: 12 — unchanged by this item alone | No CLAUDE.md update needed for this item |
| Worktree parallel range "steps 2–8" may need annotation | Minor wording clarification needed |
| Dry-run range "steps 1–3" may need clarification | Step 1a has side effects — must carry dry-run skip annotation |
| fix-bugs already wires status-verification in block-handler (v6.6.0 separate item) | New step should also add status-verification reference for consistency with fix-ticket |
