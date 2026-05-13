# Phase 4: Specification

## Persona

You are a specification writer producing precise, testable requirements for a markdown plugin migration. You write EARS-format requirements and define acceptance criteria that can be verified by grep, diff, and manual inspection.

## Task Instructions

Produce a formal specification for v6.4.4 (Connectivity Diagnostics Hardening). Three work items, all PATCH-level.

### Specification Structure

For each item, produce:
1. **Requirements** (EARS format: "When [trigger], the [system] shall [behavior]")
2. **Acceptance Criteria** (testable assertions)
3. **File Change Inventory** (exact files and sections affected)
4. **Boundary Conditions** (edge cases, error paths)

### Item 1: Bare Path Migration (trackers.md)

**Requirement:** When any skill or core contract references `docs/reference/trackers.md`, the system shall use Glob-first resolution with the three-layer pattern: `.claude/plugins/**/docs/reference/trackers.md` first, then `**/docs/reference/trackers.md`, then CWD fallback.

**Acceptance Criteria to define:**
- AC-1: Each of the 4 affected files contains a path-note blockquote explaining the Glob resolution
- AC-2: No bare `docs/reference/trackers.md` remains as a direct Read instruction in any skill or core file (excluding docs/plans, tests, CHANGELOG, README)
- AC-3: Files with multiple references resolve once and reuse (onboard Step 2, scaffold earliest step)
- AC-4: Each file has a [WARN] fallback with file-specific skip message when trackers.md is not found
- AC-5: The Glob resolution pattern matches check-setup v6.4.3 exactly (same 3 layers, same preference logic)

**Files:** `skills/onboard/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/init/SKILL.md`, `core/mcp-detection.md`

### Item 2: Structured error_type in core/mcp-detection.md

**Requirement:** When MCP detection encounters a connectivity error, the system shall classify the error into a structured `error_type` field with one of: `tls`, `auth`, `not_found`, `timeout`, `unknown`.

**Acceptance Criteria to define:**
- AC-6: `core/mcp-detection.md` Output Contract includes `error_type` field with enum definition
- AC-7: `core/mcp-detection.md` Process section includes error classification logic mapping error string patterns to error_type values
- AC-8: The error string patterns for `tls` match the check-setup Step 9 TLS patterns exactly
- AC-9: The error string patterns for `auth` match the check-setup Step 9 auth patterns exactly
- AC-10: `not_found` covers 404/not found patterns, `timeout` covers timeout/ETIMEDOUT/ESOCKETTIMEDOUT patterns
- AC-11: Callers (check-setup, init) can delegate to error_type instead of inline pattern matching

**Files:** `core/mcp-detection.md`, `skills/check-setup/SKILL.md`, `skills/init/SKILL.md`

### Item 3: Step 10 TLS Treatment

**Requirement:** When the SC connectivity check (Step 10) in check-setup encounters a TLS error, the system shall apply the same diagnostic pattern as Step 9: TLS error detection, curl probe, and NODE_OPTIONS hint.

**Acceptance Criteria to define:**
- AC-12: Step 10 has a TLS error classification branch with the same error string patterns as Step 9
- AC-13: Step 10 includes a curl probe for SC URL on TLS error
- AC-14: Step 10 emits NODE_OPTIONS hint on confirmed TLS failure
- AC-15: Step 10 retains existing auth (401/403), not_found (404), and timeout error branches
- AC-16: Step 10 error messages reference "Source control" (not "Issue tracker")

**Files:** `skills/check-setup/SKILL.md`

### Cross-Cutting

- AC-17: All changes are backward-compatible (no config contract changes)
- AC-18: Existing test `tests/scenarios/check-setup-improvements.sh` AC-11 still passes
- AC-19: No new required config keys introduced

## Success Criteria

- All 19 acceptance criteria are testable (can be verified by grep, file inspection, or test execution)
- File change inventory is complete and accurate
- No scope creep beyond the 3 roadmap items
- EARS-format requirements are precise and unambiguous

## Anti-Patterns

- Do NOT add requirements beyond the 3 roadmap items
- Do NOT propose config contract changes (this is PATCH)
- Do NOT define requirements that can only be tested at runtime (this is a markdown plugin)
- Do NOT conflate the spec with the implementation plan

## Codebase Context

- Versioning: PATCH (v6.4.4). No MAJOR/MINOR implications.
- Reference pattern: `skills/check-setup/SKILL.md` Steps 3a, 7, 9, 10
- Error_type enum: `tls`, `auth`, `not_found`, `timeout`, `unknown` (from roadmap)
- Test file: `tests/scenarios/check-setup-improvements.sh`
