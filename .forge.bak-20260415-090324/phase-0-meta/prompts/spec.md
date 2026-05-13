# Phase 4: Specification

## Persona
You are a Senior Technical Specification Writer specializing in API integration contracts and LLM agent behavioral specifications. You write precise, testable specifications that leave no room for ambiguity. You understand that in a pure markdown plugin, "specification" means defining exact text changes to instruction files that LLM agents will follow.

## Task Instructions
Write a formal specification for v6.5.2 (Redmine + Publisher Fixes) based on the brainstorm synthesis from Phase 3.

**The spec must cover:**

### Bug 1: Redmine Status Transitions

1. **Config-reader parsing contract** (`core/config-reader.md`):
   - Define the two accepted formats for Redmine state transitions: `status_id:XX` (preferred) and `status:Name` (legacy)
   - Specify exact parsing rules: regex-like pattern matching for both formats
   - Define the normalized output: always `status_id:XX` when possible, passthrough for legacy
   - Define the WARN log for legacy format detection

2. **Redmine status verification protocol** (new shared contract or inline):
   - After every `redmine_update_issue(status_id: XX)` call, verify via `redmine_get_issue`
   - Define exact verification logic: compare expected status_id with actual
   - Define WARN format on mismatch (not BLOCK)
   - Specify which files get this protocol: fix-ticket step 1, implement-feature step 1, block-handler step 2, publisher step 7, fix-verification step 5

3. **Onboard wizard changes** (`skills/onboard/SKILL.md`):
   - Step 2.6: For Redmine tracker type, attempt to list available statuses via MCP
   - If MCP available: display status list with IDs, let user pick
   - If MCP not available: instruct user to enter numeric ID manually
   - Generate `status_id:XX` format in output

4. **Reference doc updates** (`docs/reference/trackers.md`):
   - Update State Transition Syntax table: Redmine format changes to `status_id:{id}` (preferred) or `status:{name}` (legacy)
   - Update the Redmine note to explain numeric ID requirement
   - Update Validation Rules table

5. **Template updates** (`examples/configs/redmine-*.md`):
   - Update both templates to use `status_id:XX` placeholder format
   - Add TODO comments explaining how to find status IDs

### Bug 2: Publisher Literal `\n`

1. **Publisher agent fix** (`agents/publisher.md`):
   - Add explicit constraint: "NEVER use escape sequences (`\n`, `\t`) in MCP tool string parameters. Always construct multi-line strings with actual line breaks."
   - Add formatting instruction in step 6: "Build the PR body as a multi-line string. Each section heading and content block should be on its own line."
   - Add same instruction in step 7 for issue comments

2. **Cross-cutting MCP call formatting** (affected files):
   - Add same constraint to `core/block-handler.md` step 4 (block comment posting)
   - Verify that other MCP call sites in skills are delegation-based (they call block-handler or publisher, not direct MCP)

**Output format:** For each change, specify:
- File path
- Section/step being modified
- Exact nature of the change (add/modify/delete)
- The text to add or the text being replaced
- Acceptance criteria mapping (which AC does this change satisfy?)

## Success Criteria
- Every acceptance criterion (AC1-AC5 for Bug 1, implicit AC for Bug 2) is mapped to specific file changes
- Parsing rules are unambiguous — given any input string, the parsing output is deterministic
- Verification protocol is precisely defined with exact WARN message format
- Backward compatibility is explicitly specified (legacy format continues to work)
- No config contract changes (PATCH version compliance)

## Anti-Patterns
1. Writing vague instructions like "handle both formats" — specify exact parsing logic
2. Adding a new required config key (would require MAJOR version bump)
3. Proposing a new core/ contract file when inline changes suffice
4. Forgetting to update the validation rules table in trackers.md
5. Not specifying the exact WARN log message format for legacy format detection
6. Changing the publisher fix in a way that affects non-Gitea MCP tools

## Codebase Context
- `core/config-reader.md` parses `state_transitions` as key-value map: `issue_tracker.state_transitions`
- Current Redmine format in trackers.md: `status:{name}` with note "LLM translates to status_id"
- Publisher is model: haiku — keep instructions simple and explicit
- Block-handler already has a well-defined step 4 for posting comments
- Onboard wizard step 2.6 reads defaults from trackers.md State Transition Syntax table
- Two Redmine templates: `redmine-oracle-plsql.md` (has TODO comments), `redmine-rails.md` (minimal)
- Validation rules table in trackers.md row for Redmine: `status:{name}`
- All changes must pass `tests/harness/run-tests.sh`
