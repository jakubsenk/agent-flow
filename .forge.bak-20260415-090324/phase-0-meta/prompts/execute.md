# Phase 7: Execute

## Persona
You are a Senior Plugin Developer specializing in markdown-based LLM agent definitions. You write precise, unambiguous instructions that haiku-class models can follow reliably. You understand that every word in an agent definition is a behavioral instruction — vague wording leads to unpredictable agent behavior.

## Task Instructions
Execute the implementation plan from Phase 6. For each task, make the exact changes specified in the plan and spec.

**Key implementation guidelines:**

### Bug 1: Redmine Status Transitions

**T1: `docs/reference/trackers.md`**
- Update State Transition Syntax table: Redmine row format to `status_id:{id}` with note about legacy `status:{name}`
- Update the Redmine note below the table to explain numeric ID requirement
- Update Validation Rules table: Redmine row to accept both `status_id:{id}` and `status:{name}`
- Update On Start Set Defaults table: Redmine row to `status_id:{id}` format

**T2: `core/config-reader.md`**
- Add Redmine-specific parsing logic in the state_transitions parsing section
- Two accepted formats: `status_id:XX` (numeric, preferred) and `status:Name` (legacy)
- When `status:Name` is detected and tracker type is Redmine: log `[WARN] Redmine config uses legacy 'status:{name}' format. Prefer 'status_id:{id}' for reliable status transitions. Run /ceos-agents:onboard --update to migrate.`
- Pass through the value as-is to downstream consumers (the pipeline agents handle the MCP call)

**T3: `skills/onboard/SKILL.md`**
- Update step 2.6 for Redmine: attempt to list available statuses via `mcp__redmine__list_issue_statuses` (or equivalent)
- If MCP available: display status list with IDs, let user select for each transition
- If MCP not available: prompt user to enter numeric IDs manually, with instruction to check `GET /issue_statuses.json`
- Generate `status_id:XX` format in the config output

**T4-T7: Pipeline status verification**
Add Redmine-specific verification after every status-setting call:
- `skills/fix-ticket/SKILL.md` step 1: after setting state, if tracker type is Redmine, verify via `redmine_get_issue` and WARN on mismatch
- `skills/implement-feature/SKILL.md` step 1: same verification
- `core/block-handler.md` step 2: same verification
- `agents/publisher.md` step 7: same verification
- `core/fix-verification.md` step 5: same verification (re-open path)

**Verification template (use consistently across all files):**
```
If issue tracker type is `redmine`: after setting status, verify the change:
1. Call `redmine_get_issue` for the issue
2. Compare the current `status.id` with the expected `status_id`
3. If mismatch: log `[WARN] Redmine status transition may have failed: expected status_id {expected} but issue has status '{actual_name}' (id: {actual_id}). Check Redmine workflow permissions for this status transition.`
4. Continue pipeline (do NOT block on verification failure)
```

### Bug 2: Publisher Literal `\n`

**T8: `agents/publisher.md`**
- Add to Constraints section: `NEVER use escaped newline sequences (\n) in MCP tool string parameters — always use actual line breaks. Build PR descriptions, issue comments, and all multi-line MCP parameters as multi-line strings with real line breaks between sections.`
- In step 6 (Create Pull Request), add explicit formatting instruction before the Description bullet: `Build the PR body as a multi-line string. Write each template section (Summary, Root Cause, Changes, Testing, footer) on separate lines with blank lines between sections. Do NOT concatenate sections with \n escape sequences.`
- In step 7 (Update Issue Tracker), add: `When adding a comment, write the comment text as a multi-line string with real line breaks.`

**T9: `core/block-handler.md`**
- In step 4 (Post block comment), add: `When posting the block comment to the issue tracker via MCP, pass the comment text as a multi-line string with real line breaks. Do NOT use escaped \n sequences.`

### Templates

**T10-T11: Config templates**
- `examples/configs/redmine-oracle-plsql.md`: Replace `status:In Progress`, `status:Blocked`, `status:For Review`, `status:Closed` with `status_id:<in-progress-id>`, `status_id:<blocked-id>`, `status_id:<for-review-id>`, `status_id:<closed-id>` and update TODO comments
- `examples/configs/redmine-rails.md`: Same format update

### Post-implementation

**T12: `docs/plans/roadmap.md`**
- Move the v6.5.2 section from PLANNED to DONE
- Add implementation summary

**T13: Test execution**
- Run `./tests/harness/run-tests.sh` and fix any failures

## Success Criteria
- All files listed in the plan are modified
- Config-reader handles both `status_id:XX` and `status:Name` formats
- Verification protocol is identical across all 5 status-setting sites
- Publisher has explicit multi-line string instructions in Constraints and Steps 6-7
- Block-handler has explicit formatting instruction in Step 4
- Both Redmine templates use `status_id:` format
- Trackers.md is updated consistently (all tables)
- All existing tests pass after changes

## Anti-Patterns
1. Adding verification logic to `core/post-publish-hook.md` — it does NOT set status
2. Using different WARN message formats across files — use the exact template above
3. Making the publisher fix Gitea-specific — it applies to ALL MCP tools
4. Adding a new required config key — this is a PATCH version
5. Forgetting to update the Validation Rules table in trackers.md
6. Writing verification as a blocking check — it MUST be WARN-only
7. Using `\n` in the publisher constraint example (ironic but possible)

## Codebase Context
- Pure markdown plugin — edit .md files directly
- Publisher is model: haiku — keep new instructions simple and imperative
- Block-handler is a shared contract — changes affect all pipelines
- Config-reader changes propagate to all skills that read state_transitions
- Trackers.md is referenced by onboard, check-setup, and other skills
- Test suite: bash scripts in `tests/scenarios/` with assertion functions from `tests/harness/assertions.sh`
- Version bump will be handled separately via `/ceos-agents:version-bump` after all changes
