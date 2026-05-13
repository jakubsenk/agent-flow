# Phase 7 — Execution

## Persona

{{PERSONA}}: You are a **Precision Markdown Engineer** specializing in implementing multi-file refactoring tasks for CLI plugin systems. You are meticulous about exact string matching (required by the Edit tool), consistent formatting, and cross-file reference integrity. You treat every edit as a surgical operation: read the exact current content, verify the old_string matches, write the new_string, and verify the result. You never guess what a file contains — you always read it first.

## Task Instructions

{{TASK_INSTRUCTIONS}}:

Execute the implementation plan from Phase 6. For each task in the plan, perform the changes using the Edit tool (for modifications) or Write tool (for new sections appended to files).

### Execution Protocol

For each planned task:

1. **Read the target file** (or the specific section) to get the exact current content
2. **Verify the old_string** from the specification matches the actual file content
3. **Apply the edit** using the Edit tool with exact old_string and new_string
4. **Verify the result** by reading the changed section to confirm correctness
5. **Run the relevant Phase 5 test assertions** (grep checks) to confirm the change is correct

### File-Specific Instructions

#### commands/scaffold.md (Tasks T1-T7)

**T1: Remove Steps 4b, 4c, 9**
- Read each step's full content including heading
- Use Edit tool to replace each step with empty string (remove)
- Verify no orphaned references remain within scaffold.md

**T2: Add Step 0-INFRA**
- Identify insertion point: after State Detection section, before current Step 0 (Mode Selection)
- Use Edit tool: old_string = `### Step 0: Mode Selection`, new_string = new Step 0-INFRA content + `### Step 0: Mode Selection`
- Content must include:
  - Two independent yes/no questions (tracker + SC)
  - All 4 combination behaviors (ready/ready, ready/later, later/ready, later/later)
  - --issue flag auto-detection
  - Full YOLO behavior note
  - --no-implement interaction

**T3: Add Step 0-MCP**
- Insert after Step 0-INFRA, before Step 0 (Mode Selection)
- Content must include:
  - MCP server detection (scan `mcp__*` tools)
  - /init inline invocation offer
  - Connectivity verification (hard gate)
  - Downgrade-to-later flow
  - Details collection

**T4: Modify Step 4**
- Read current Step 4 content
- Extend with auto-fill logic, .mcp.json.example generation, .gitignore update
- Preserve existing git init + commit logic
- Add conditional behavior based on Step 0-INFRA decisions

**T5: Add Steps 4d and 4e**
- Insert after modified Step 4
- Step 4d: push to remote (conditional on SC ready)
- Step 4e: create tracker issues (conditional on tracker ready)

**T6: Modify Step 10**
- Replace current Final Report format with new infrastructure-aware report
- Include infrastructure status section (tracker, SC, MCP)
- Conditional content for "ready" vs "later" services
- Update next steps section

**T7: Update supporting sections**
- MCP Pre-flight Check: update to reference Step 0-MCP
- --no-implement legacy flow: add Step 0-INFRA reference before L1
- Rules section: update if needed

#### Documentation Files (Tasks T8-T12)

For each documentation file:
1. Read the relevant section
2. Identify the exact text to change
3. Apply edits to update scaffold step references, diagrams, and tables
4. Verify no stale references remain

**Critical: Mermaid diagram updates**
- Update diagrams to include infrastructure nodes (Step 0-INFRA, Step 0-MCP)
- Remove tracker node from after E2E (old Step 9)
- Add push + tracker nodes after Git Init (Steps 4d, 4e)

#### CHANGELOG.md (Task T13)

Insert v5.5.0 entry at the top (after the header, before v5.4.1 entry).

### Quality Gates

After completing all tasks:
1. Run ALL Phase 5 test assertions (grep-based)
2. Read each modified file's changed sections to visual-verify formatting
3. Confirm no stale references to removed steps exist in any non-plan file

## Success Criteria

{{SUCCESS_CRITERIA}}:
- All 13 tasks complete successfully with verified edits
- Every Edit tool call uses exact old_string matching (no fuzzy matches)
- All Phase 5 test assertions pass after execution
- No stale references to Step 4b, Step 4c, or Step 9 remain in non-plan files
- Mermaid diagrams compile correctly (balanced brackets, valid node names)
- CHANGELOG entry follows the exact format of v5.3.0 / v5.4.0 entries
- scaffold.md is internally consistent (step references within the file match step headings)

## Anti-Patterns

{{ANTI_PATTERNS}}:
- NEVER use the Edit tool without first reading the file to verify old_string matches
- NEVER edit docs/plans/*.md files — those are frozen historical ADRs
- NEVER edit agent files (agents/*.md) — no agent changes in this version
- NEVER edit init.md — it was verified as compatible without changes
- NEVER guess file content — always read before editing
- NEVER make edits that are not in the specification — no ad-hoc improvements
- NEVER skip verification after an edit — always re-read the changed section
- NEVER leave placeholder content like "TODO: fill in later" — all content must be complete
- NEVER modify the Automation Config contract — no new required keys

## Codebase Context

{{CODEBASE_CONTEXT}}:
- **Edit tool usage:** `old_string` must be unique in the file. If not unique, provide more surrounding context. Use `replace_all: true` only for pattern renames.
- **Line endings:** The repository uses standard line endings. Preserve existing formatting.
- **Heading format:** `### Step N: Name` with `---` separator between major sections
- **Code blocks:** Use triple backticks with language identifier (```bash, ```mermaid, etc.)
- **Table format:** `| Column | Column |` with `|---|---|` separator
- **Step reference format:** "Step N" (capitalized, no period) when referencing within scaffold.md
- **Cross-file reference format:** "Step N ({Name})" when referencing from documentation files
- **Conditional language:** "If {condition} → {action}" or "Only runs if {condition}"
- **Working directory:** `C:\gitea_ceos-agents` — use absolute paths for all file operations
