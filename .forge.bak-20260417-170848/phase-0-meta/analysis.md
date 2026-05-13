# Phase 0 Analysis — v6.7.2 Pipeline Consistency & Dedup

## Task Type

**Primary:** refactor
**Secondary:** docs

This is an internal cleanup release: extracting duplicated logic into a shared contract, aligning inconsistent formats, removing redundant inline code, and fixing documentation inaccuracies. No new features, no behavioral changes, no Automation Config contract changes.

## Complexity Assessment

| Axis | Score | Rationale |
|------|-------|-----------|
| Scope | 3 | ~10 files across core/, skills/, state/ directories. New core contract file. |
| Ambiguity | 1 | Fully specified in roadmap. All 4 work items have explicit file lists and expected changes. |
| Risk | 1 | PATCH release. Internal refactor only. No public API changes, no Automation Config contract changes. All skills delegate to the same logic they already inline. |

**Composite complexity:** 3 (max of axes)

## Domain

Claude Code plugin internals — markdown-based pipeline definitions, no runtime code.

## Confidence Assessment

| Question | Score | Rationale |
|----------|-------|-----------|
| Task well-defined? | 1.0 | Roadmap spec provides exact file lists, exact changes, and impact classification for all 4 items. |
| Context supports execution? | 1.0 | All source files read and patterns confirmed. Duplication is verbatim. Deviations are identified. |
| Within pipeline capabilities? | 1.0 | Pure markdown editing. No build system, no tests to break, no external dependencies. |

**Composite confidence:** 1.0

## Fast-Track Eligibility

- Composite complexity: 3 (FAILS <= 2 threshold)
- **Result: NOT ELIGIBLE for fast-track**

Standard pipeline required.

## Codebase Context

### Repository
- Pure markdown plugin: 21 agents, 28 skills, 14 core contracts (will become 15)
- Current version: v6.7.1, target: v6.7.2 (PATCH)
- No build system, no runtime dependencies, no compiled code

### Work Item 1: Tracker Subtask Extraction

**Current state:** The "Create tracker subtasks" pseudocode block is duplicated verbatim across 3 skills:
- `skills/fix-ticket/SKILL.md` — step 4b-tracker (~153 lines)
- `skills/fix-bugs/SKILL.md` — step 3b-tracker (~153 lines)
- `skills/implement-feature/SKILL.md` — step 5a (~153 lines)

All three contain identical:
- Triple gate logic
- Required in-memory values section
- Full pseudocode process (idempotency check, per-tracker MCP creation, dual store write, GitHub/Gitea checklist, YAML commit, result display)
- Per-Tracker Issue Creation Parameters table
- Issue Description Template

**Target:** Extract to `core/tracker-subtask-creator.md`. Each skill replaces the inline block with a delegation reference: "Follow `core/tracker-subtask-creator.md`" plus the required input values.

### Work Item 2: Webhook Format Alignment

**Current state — deviations found:**

| Location | Keys | Flags | Format |
|----------|------|-------|--------|
| `core/block-handler.md` (canonical) | `event`, `issue_id`, `agent`, `reason`, `timestamp` | `--max-time 5 --retry 0` | inline `-d` |
| `core/post-publish-hook.md` (canonical) | `event`, `issue_id`, `pr_url`, `timestamp` | `--max-time 5 --retry 0` | heredoc |
| `fix-bugs` step 8b | `event`, `issue_id`, `pr_url`, `timestamp` | `--max-time 5 --retry 0` | inline `-d` |
| `fix-bugs` step 9a | `event`, `status`, `fixed`, `blocked`, `timestamp` | `--max-time 5 --retry 0` | inline `-d` |
| **implement-feature** step 10a | `event`, `issue` (WRONG), `pr` (WRONG) | MISSING `--max-time 5 --retry 0` | inline `-d` |
| **implement-feature** step X | `event`, `issue` (WRONG), `agent`, `reason` | MISSING `--max-time 5 --retry 0`, MISSING `timestamp` | inline `-d` |

**Target:** Align implement-feature steps 10a and X to use canonical keys (`issue_id`, `pr_url`, `timestamp`) and flags (`--max-time 5 --retry 0`).

### Work Item 3: Block Handler Inline Removal

**Current state:** implement-feature step X says "Follow `core/block-handler.md`:" and then inlines the entire 6-step procedure (steps 1-6, lines 646-666). This is fragile duplication — any change to block-handler.md must also be applied to this inline copy.

**Target:** Remove the inline copy. Replace with delegation reference only, plus state.json update (which is skill-specific).

### Work Item 4: Documentation Fixes

| File | Issue | Fix |
|------|-------|-----|
| `core/fix-verification.md` | Title and references say "Fix verification" | Use mode-neutral "Verification" |
| `core/state-manager.md` | Forward reference to resume-ticket.md in Resume Process step 2 | Replace with inline heuristic description |
| `state/schema.md` e2e_test section | Missing `verdict`, `result_path`, `attempts` fields | Add the three fields |
| `state/schema.md` triage/code_analysis fields | No documentation about field reuse across modes | Add inline note about feature pipeline reuse |
| `core/fixer-reviewer-loop.md` | NEEDS_DECOMPOSITION references only mention caller generically | List all 3 pipeline skills explicitly |

## Security Evaluation

Not applicable — fast-track not eligible. No security-relevant changes in this release (no external input handling, no credential management, no network-facing code).

## Risk Summary

- **Zero breaking change risk**: All changes are internal refactors. The extracted contract produces identical behavior to the inline copies it replaces. Webhook key renames align deviating call-sites to the already-documented canonical format.
- **Test impact**: Existing tests may reference specific step numbers or text patterns. The test harness should be checked for any assertions that depend on the exact inline text being present.
- **Migration**: None required. Consuming projects are unaffected.
