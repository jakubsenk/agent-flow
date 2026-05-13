# Phase 7: Execute

## Objective
Implement ALL changes from the Phase 6 plan. Edit every file that needs modification. This is the actual implementation phase.

## Method
1. Read the implementation plan from Phase 6
2. For each batch in order:
   a. Execute all CRQs in the batch using Edit tool
   b. After each batch, verify by reading the modified files
   c. Run relevant test scenarios to verify structural integrity
3. After all batches: run the full test suite

## Execution Rules

### Edit Protocol
- Use the Edit tool for all changes
- Always read the file first to get exact current content
- Use precise old_string/new_string to avoid ambiguity
- After each edit, verify the change was applied correctly

### Agent File Edits
When editing agent files in `agents/`:
- Preserve YAML frontmatter exactly (name, description, model, style fields)
- Preserve section order: Goal -> Expertise -> Process -> Constraints
- Process steps must be numbered
- Constraints must start with NEVER or define hard limits
- Do not change the model assignment unless the spec explicitly requires it

### Core Contract Edits
When editing core contracts in `core/`:
- Preserve the Purpose -> Input Contract -> Process -> Output Contract -> Failure Handling structure
- Preserve table formats for input/output contracts
- Ensure all field references match state schema

### State Schema Edits
When editing `state/schema.md`:
- Preserve JSON example format
- Preserve table format for field definitions
- Ensure backward compatibility (new fields must be optional with defaults)

### Skill Edits
When editing skill files in `skills/`:
- Preserve YAML frontmatter
- Preserve step numbering
- Ensure agent dispatch references match agent names in `agents/`
- Ensure core contract references match files in `core/`

## Verification Checkpoints
- After Batch 1: run `./tests/harness/run-tests.sh frontmatter-completeness`
- After each batch: run `./tests/harness/run-tests.sh section-order`
- After all batches: run `./tests/harness/run-tests.sh` (full suite)

## Output
Report every change made with the format:
```
## Execution Log

### CRQ-{N}: {title}
- File: {path}
- Status: DONE / SKIPPED (with reason)
- Lines changed: {N}
```

If any edit fails or a test breaks:
1. Document the failure
2. Revert the specific edit if possible
3. Continue with remaining edits
4. Report all failures in the execution log
