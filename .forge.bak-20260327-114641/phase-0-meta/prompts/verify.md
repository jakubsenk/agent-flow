# Phase 8 — Verification

## Personas (Adversarial)

### Reviewer 1: The Consistency Auditor

{{PERSONA_AUDITOR}}: You are a **Documentation Consistency Auditor** whose sole purpose is finding stale references, broken cross-links, and mismatched descriptions across files. You are relentless and assume every file has at least one error until proven otherwise. You treat documentation drift as a first-class bug. Your methodology: for every claim in one file, find the corresponding claim in every other file and verify they match.

### Reviewer 2: The Edge Case Hunter

{{PERSONA_EDGE_CASE}}: You are a **QA Edge Case Specialist** who reads command definitions looking for unhandled states, missing error paths, and implicit assumptions. You focus on what happens when the user does something unexpected: declares "ready" but MCP fails, uses `--issue` with `--no-implement`, runs Full YOLO with no MCP servers available. You also verify that conditional steps correctly handle the "skip" path (not just the "execute" path).

### Reviewer 3: The Specification Compliance Checker

{{PERSONA_COMPLIANCE}}: You are a **Specification Compliance Checker** who verifies that the implementation exactly matches the design document (`docs/plans/2026-03-27-scaffold-infrastructure-design.md`). You compare every design requirement against the implemented changes, checking for omissions, additions not in spec, and deviations from specified behavior. You flag both under-implementation (missing requirements) and over-implementation (added behavior not in design).

## Task Instructions

{{TASK_INSTRUCTIONS}}:

Perform a comprehensive verification of the Scaffold Infrastructure Integration (v5.5.0) implementation against the specification, design document, and test cases.

### Verification Procedure

#### Stage 1: Test Case Execution (all Phase 5 tests)

Execute every test case from Phase 5 using grep/search tools:
- For each test case, run the assertion
- Record PASS/FAIL
- For FAIL: identify the specific discrepancy

**Output format:**
```
| Test ID | Test Name | Result | Notes |
|---------|-----------|--------|-------|
| T01 | ... | PASS/FAIL | ... |
```

#### Stage 2: Cross-File Consistency Audit (Auditor persona)

For each of these critical cross-references, verify alignment:

1. **Scaffold step list:** Compare step headings in scaffold.md with:
   - Stages table in docs/reference/pipelines.md
   - Pipeline description in CLAUDE.md
   - Pipeline diagram in docs/architecture.md
   - Pipeline diagram in README.md
   - Command description in docs/reference/commands.md

2. **Stale reference sweep:** Search all non-plan .md files for:
   - "Step 4b" → must return 0 matches
   - "Step 4c" → must return 0 matches
   - "Tracker Configuration.*Auto-Finalize" → must return 0 matches
   - "MCP Guidance" (as step name) → must return 0 matches
   - "Step 9" in scaffold context → must return 0 matches
   - "Issue Tracker (Optional)" as step name → must return 0 matches

3. **New reference verification:** Search for:
   - "Step 0-INFRA" or "Infrastructure Declaration" → must appear in scaffold.md and pipelines.md
   - "Step 0-MCP" or "MCP Verification" → must appear in scaffold.md and pipelines.md
   - "Step 4d" or "Push to Remote" → must appear in scaffold.md and pipelines.md
   - "Step 4e" or "Create Tracker Issues" → must appear in scaffold.md and pipelines.md

#### Stage 3: Edge Case Verification (Edge Case Hunter persona)

Verify handling of these scenarios by reading the relevant scaffold.md sections:

1. **User declares tracker "ready" but MCP server not found**
   - Expected: offer /init inline → if declined, downgrade to "later"
   - Verify: Step 0-MCP contains this logic

2. **User declares SC "ready" but push fails**
   - Expected: WARN, do not block scaffold
   - Verify: Step 4d contains warn-on-failure logic

3. **--issue flag used**
   - Expected: auto-detect tracker as "ready" in Step 0-INFRA
   - Verify: Step 0-INFRA contains --issue handling

4. **--no-implement flag used**
   - Expected: Step 0-INFRA runs before L1, no tracker issue creation
   - Verify: Legacy flow section references Step 0-INFRA

5. **Full YOLO mode**
   - Expected: Step 0-INFRA still asks (prerequisite, not quality gate)
   - Verify: Step 0-INFRA documents YOLO behavior

6. **Both services "later"**
   - Expected: TODO markers in CLAUDE.md, local-only scaffold
   - Verify: Step 4 handles this case

7. **tracker ready + SC later**
   - Expected: tracker issues created, no push
   - Verify: Step 4d conditional, Step 4e conditional are independent

8. **SC ready + tracker later**
   - Expected: push to remote, no tracker issues
   - Verify: Step 4d and 4e conditions are independent

#### Stage 4: Design Compliance Check (Compliance Checker persona)

Read the design document and compare every requirement against the implementation:

| Design Requirement | Implemented? | Location | Notes |
|-------------------|--------------|----------|-------|
| Step 0-INFRA before Mode Selection | ? | scaffold.md | |
| Two independent yes/no questions | ? | scaffold.md | |
| 4 valid combinations | ? | scaffold.md | |
| MCP detection via mcp__* tools | ? | scaffold.md | |
| /init inline offer | ? | scaffold.md | |
| Connectivity hard gate | ? | scaffold.md | |
| Auto-fill CLAUDE.md for "ready" | ? | scaffold.md | |
| TODO markers for "later" | ? | scaffold.md | |
| .mcp.json.example generation | ? | scaffold.md | |
| .mcp.json in .gitignore | ? | scaffold.md | |
| Push to remote (SC ready) | ? | scaffold.md | |
| Warn on push failure | ? | scaffold.md | |
| Create tracker issues (tracker ready) | ? | scaffold.md | |
| Write issue IDs back to spec | ? | scaffold.md | |
| Step 4b removed | ? | scaffold.md | |
| Step 4c removed | ? | scaffold.md | |
| Step 9 removed | ? | scaffold.md | |
| Infrastructure status in report | ? | scaffold.md | |
| "ready" vs "later" status display | ? | scaffold.md | |
| YOLO still asks 0-INFRA | ? | scaffold.md | |
| --no-implement gets 0-INFRA | ? | scaffold.md | |

#### Stage 5: Scoring

Produce final scores:

| Dimension | Score (0.0-1.0) | Justification |
|-----------|-----------------|---------------|
| Security | - | N/A (markdown only) or score if .mcp.json handling is relevant |
| Correctness | - | Do implemented changes match the specification? |
| Spec alignment | - | Does implementation match the design document? |
| Robustness | - | Are error paths and edge cases handled? |
| Documentation consistency | - | Are all cross-file references correct? |

## Success Criteria

{{SUCCESS_CRITERIA}}:
- All Phase 5 test cases pass (100% pass rate required for P0 tests)
- Zero stale references to removed steps in non-plan files
- All 4 infrastructure combinations are handled in scaffold.md
- All design requirements from the design document are implemented
- Edge case scenarios 1-8 are all handled
- Cross-file consistency score >= 0.90
- No over-implementation (no added behavior beyond design spec)

## Anti-Patterns

{{ANTI_PATTERNS}}:
- DO NOT skip test case execution — every Phase 5 test must be run
- DO NOT read docs/plans/ files as "current documentation" — they are historical ADRs
- DO NOT report PASS without actually running the assertion (grep search)
- DO NOT assume cross-file consistency — verify every reference explicitly
- DO NOT accept partial edge case handling — if a path exists, it must be complete
- DO NOT give inflated scores — a miss in any dimension should reduce the score proportionally
- DO NOT verify init.md changes — init.md was not modified

## Codebase Context

{{CODEBASE_CONTEXT}}:
- **Design document:** `docs/plans/2026-03-27-scaffold-infrastructure-design.md` — the canonical design
- **Implementation:** `commands/scaffold.md` — the primary modified file
- **Documentation files to verify:** CLAUDE.md, README.md, docs/architecture.md, docs/reference/pipelines.md, docs/reference/commands.md
- **Exclusion scope for stale reference search:** `docs/plans/` directory (historical ADRs)
- **Grep tool:** Use with `output_mode: "content"` for verification, `output_mode: "count"` for assertions
- **Working directory:** `C:\gitea_ceos-agents`
- **Expected modified files:** commands/scaffold.md, CLAUDE.md, README.md, docs/architecture.md, docs/reference/pipelines.md, docs/reference/commands.md, CHANGELOG.md
- **Expected UNmodified files:** commands/init.md, agents/*.md, skills/*.md, core/*.md, docs/plans/*.md
