# Phase 9: Completion Prompt

## Summary Template

Generate a completion report covering:

### Changes Made

1. **Step 4e: Explicit sub-issue parent parameters** (`skills/scaffold/SKILL.md`)
   - Replaced vague "using the tracker's native parent parameter" with inline table of exact MCP parameter names per tracker
   - Added post-creation verification with WARN on missing parent link

2. **Step 8b: Removed cascade close assumption** (`skills/scaffold/SKILL.md`)
   - Removed incorrect claim that "closing parent epic cascades to children"
   - Unified close logic: all tracker types now explicitly close each story sub-issue

3. **Step 8a: Implementation comments** (`skills/scaffold/SKILL.md`)
   - New step between E2E tests and issue closing
   - Posts `[ceos-agents]` prefixed comments on each story and epic with implementation details
   - Graceful failure handling (WARN, not BLOCK)

4. **Design quality improvements** (`agents/spec-writer.md`, `agents/scaffolder.md`)
   - spec-writer: added "Design & UX" section requirement for web/frontend/fullstack projects
   - scaffolder: added design system batch (CSS framework, base styles) for web projects
   - scaffolder: added design system check to quality scorecard

5. **Language fidelity** (`agents/spec-writer.md`, `skills/scaffold/SKILL.md`)
   - Added diacritics/non-ASCII preservation constraint to spec-writer
   - Added language fidelity instruction to Step 4e for tracker issue creation

### Versioning Impact
- **Level:** PATCH — all changes are behavior fixes within existing contract
- **No breaking changes:** No new required Automation Config keys, no agent output format changes
- **Optional additions:** Design & UX spec section is optional (only for web projects)

### Test Results
- `./tests/harness/run-tests.sh` — {PASS/FAIL}

### Files Modified
- `skills/scaffold/SKILL.md` — Steps 4e, 8a (new), 8b
- `agents/spec-writer.md` — Process section, Constraints section
- `agents/scaffolder.md` — Process section (new batch), Constraints section (scorecard)

### Residual Risk
- Design quality improvement depends on LLM compliance with the new instructions — cannot be guaranteed, only strongly encouraged
- Language fidelity depends on LLM compliance — explicit constraint significantly improves compliance but cannot enforce it at the markdown-instruction level
- Sub-issue parent linking depends on the MCP server accepting the parameter — if the YouTrack MCP tool ignores `parent`, the issue persists (but the new WARN will make it visible)
