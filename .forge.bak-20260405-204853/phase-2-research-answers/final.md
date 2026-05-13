# Phase 2: Research Answers — Consolidated

## Design Decisions Resolved

### RQ-1: Timing → UPFRONT (all issues created before execution loop)
- Scaffold Step 4e creates all issues in a dedicated step before implementation
- Consistent with reference implementation, simpler idempotency
- Gives users visibility of all subtask issues before code changes begin
- New step inserted between decomposition decision and execution loop

### RQ-2: GitHub/Gitea Fallback → CHECKLIST in parent issue body
- User explicitly specified "checklist in parent issue body"
- Roadmap (`docs/plans/roadmap.md` line 444) confirms: "use checklist in parent issue"
- Technically feasible: read parent issue body via MCP, append markdown checklist, update issue
- Scaffold's standalone approach is wrong for decomposition (subtasks are ephemeral execution steps, not independent work items)
- Checklist format: `- [ ] [{subtask_title}](#{issue_url_or_number})` for each subtask

### RQ-3: Idempotency → YAML-first with per-subtask write
- Write `tracker_issue_id` into YAML immediately after each successful creation
- On resume, check `tracker_issue_id != null` in YAML → skip if already populated
- Mirrors scaffold's back-reference comment pattern (scaffold: HTML comments in .md, decomposition: YAML field)
- No tracker-side query needed — YAML is authoritative
- `DECOMPOSE_PARTIAL` resume already reads YAML, so this fits naturally

### RQ-4: Field Name → `tracker_issue_id` (RECOMMENDED) but roadmap says `tracker_id`
- `tracker_id` appears 11 times in codebase referring to Redmine's issue TYPE parameter
- `tracker_issue_id` is unambiguous — avoids naming collision
- **Decision needed at spec phase:** align with roadmap (`tracker_id`) or use clearer name (`tracker_issue_id`)

### RQ-5: Dual Storage → YES, both YAML and state.json
- Existing dual-write pattern for `commit_hash` and `restore_point` in both locations
- YAML = persistent human-readable plan; state.json = runtime resume/metrics
- Both must carry the field (same as existing subtask fields)

### RQ-6: Default → `enabled` (active by default)
- Every existing optional key defaults to the "active" behavior
- Feature is gated by `tracker_effective_status = "ready"` — projects without tracker integration unaffected
- CHANGELOG must document behavioral change
- Classification remains MINOR (v6.4.0) — adding optional key to existing optional section

### RQ-7: Config Format → String enum (`enabled`/`disabled`), not boolean
- No existing Automation Config key uses `true`/`false` — convention is string enums
- Examples: `fail-fast`/`continue`, `squash`/`individual`, `comment`/`close`
- Key: `Create tracker subtasks` | Default: `enabled` | Values: `enabled`, `disabled`
- No separate fallback strategy key needed — skill handles GitHub/Gitea internally based on tracker type

### RQ-8: Jira Sub-task Constraint → WARN and skip parent-linking
- Jira rejects nested sub-tasks (sub-task under sub-task)
- No existing guard for this case
- Recommendation: if parent issue type is "Sub-task", create the sub-issue WITHOUT parent link (flat issue), log WARN
- Not a blocker — edge case, handled gracefully

### RQ-9: Linear UUID Resolution → MCP server handles transparently
- No documentation addresses UUID vs display ID
- Plugin passes through whatever ID format the MCP server returned
- Implicit delegation to MCP server — no explicit conversion layer needed

### RQ-10: Failure Policy → WARN-and-continue (accumulator pattern)
- Direct precedent: scaffold Step 4e uses accumulator pattern
- `core/block-handler.md` and `core/state-manager.md`: infrastructure side-effect failures are non-fatal
- Individual subtask issue creation failure: log WARN, continue to next
- After all: commit YAML with successfully-created tracker_issue_ids
- Display result: "Created {N}/{M} tracker sub-issues ({F} failures)"

### RQ-11: YAML Commit Strategy → Bundle with subtask execution commit
- No — WRONG approach. Since all issues are created UPFRONT (RQ-1 decision), the YAML should be committed ONCE after the entire creation loop completes (before execution loop begins)
- Pattern matches scaffold Step 4e: `git add .claude/decomposition/ && git commit -m "chore: link decomposition subtasks to tracker issues"`
- This single commit is the idempotency checkpoint — on resume, committed tracker_issue_ids indicate already-created issues

### RQ-12: Step Numbering
- **implement-feature**: Step 5a (between Step 5 decomposition decision and Step 6 execution loop)
- **fix-ticket**: Step 4b-tracker (between Step 4b decomposition decision and Step 4c execution loop)
- **fix-bugs**: Step 3b-tracker (between Step 3b decomposition decision and Step 3c execution loop)
- All gated on `decomposition.decision == "DECOMPOSE"` and `Create tracker subtasks == enabled`

### RQ-13: Post-creation Verification → Lightweight (MCP return check only)
- Scaffold's read-back pattern verifies parent linkage for spec-based issues
- For decomposition, the MCP create-issue return value confirms creation
- Parent linkage verification is nice-to-have but not essential — WARN if verification fails

### RQ-14: Write Capability Check → Reuse existing tracker_effective_status gate
- `core/mcp-preflight.md` has the write canary pattern
- Decomposition skills already check tracker availability at pipeline start
- The new step should be gated on `tracker_effective_status == "ready"` (same gate as scaffold Step 4e)
- No separate write check needed — failure is caught inline with accumulator pattern

### RQ-15: maps_to in Sub-issue Description → YES, include for traceability
- The `maps_to` field links subtasks to parent acceptance criteria
- Including `maps_to` references in tracker sub-issue descriptions provides traceability
- Format: "Addresses: AC-1: {text}, AC-3: {text}" in the issue description
- Low effort, high value — makes tracker issues self-documenting

---

## Summary of All Decisions

| # | Decision | Choice |
|---|----------|--------|
| RQ-1 | Timing | Upfront (all before execution loop) |
| RQ-2 | GitHub/Gitea | Checklist in parent issue body |
| RQ-3 | Idempotency | YAML-first (tracker_issue_id field) |
| RQ-4 | Field name | `tracker_issue_id` (avoids Redmine collision) |
| RQ-5 | Dual storage | Yes (YAML + state.json) |
| RQ-6 | Default | `enabled` |
| RQ-7 | Config format | String enum: enabled/disabled |
| RQ-8 | Jira nested | WARN, skip parent-linking |
| RQ-9 | Linear UUID | MCP server handles |
| RQ-10 | Failure policy | WARN-and-continue (accumulator) |
| RQ-11 | YAML commit | Single commit after upfront creation loop |
| RQ-12 | Step numbers | 5a / 4b-tracker / 3b-tracker |
| RQ-13 | Verification | Lightweight (MCP return only) |
| RQ-14 | Write check | Reuse tracker_effective_status |
| RQ-15 | maps_to | Include in sub-issue description |

## Open Items for Spec Phase
1. **Field name final decision**: `tracker_id` (roadmap) vs `tracker_issue_id` (unambiguous) — spec must decide
2. **Checklist format for GitHub/Gitea**: exact markdown template for the checklist items
3. **Step numbering convention**: should sub-steps use letter suffixes (5a) or dash notation (4b-tracker)?
