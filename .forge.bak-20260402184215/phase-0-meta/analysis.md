# Phase 0 — Task Analysis

## Task Type

`bugfix` — Two behavioral bugs in an existing skill definition (pure markdown).

## Complexity

**Medium** — Two distinct bugs in a single file (`skills/scaffold/SKILL.md`), both requiring additions (not just edits) to an existing multi-hundred-line orchestration definition. The fixes require understanding the full scaffold pipeline flow and cross-referencing with `fix-ticket` and `implement-feature` for behavioral parity.

## Confidence

**0.92** — The bugs are clearly identified from user evidence and confirmed by source analysis. Both root causes are understood.

## Domain

Markdown pipeline orchestration definitions. No runtime code, no build system.

## Codebase Context

### Repository
- `ceos-agents` — a Claude Code plugin providing automated bug-fix, feature, and scaffold workflows
- Pure markdown: agent definitions (YAML frontmatter + prose) and skill definitions (orchestration instructions)
- 19 agents in `agents/`, 26 skills in `skills/`

### Key Files
| File | Role |
|------|------|
| `skills/scaffold/SKILL.md` | **Primary bug location** — scaffold skill orchestration |
| `skills/implement-feature/SKILL.md` | Reference — how features handle issue state transitions |
| `skills/fix-ticket/SKILL.md` | Reference — how bugs handle issue state transitions |
| `agents/publisher.md` | Reference — the agent that updates tracker state in other pipelines |
| `agents/spec-writer.md` | Context — how epics/stories are structured in spec/ |
| `docs/reference/trackers.md` | Reference — tracker API syntax for state transitions |
| `core/block-handler.md` | Shared contract — block handling protocol |

### Evidence Project
`C:\Users\FSABACKY\claude\licence-ceos-agents-yt` — a project scaffolded by `ceos-agents`, containing:
- `spec/epics/01-project-setup.md` through `spec/epics/06-excel-export.md`
- Each epic has `<!-- YouTrack: LIC-{N} -->` back-references (epic issues created successfully)
- Stories are defined with `### Story N.M:` headings inside each epic file
- **No story-level back-references** exist — confirming stories were NOT created as sub-issues

## Bug Analysis

### Bug 1: Stories not created as sub-issues in tracker

**Location:** `skills/scaffold/SKILL.md`, Step 4e (lines 519-523)

**Root Cause:** Step 4e line 523c says:
> "For each user story within the epic: create a sub-issue under the epic issue."

This instruction exists but is insufficient. It lacks:
1. **Explicit parsing guidance** — how to identify story boundaries in the markdown (stories use `### Story N.M:` headings)
2. **Sub-issue creation syntax** — no tracker-specific guidance for creating sub-issues/subtasks (unlike epic creation which is just "create an issue")
3. **Back-reference format for stories** — line 524d says "Write the created issue ID back into the spec file as a reference comment" but only specifies one back-reference pattern, not distinguishing epic-level vs story-level
4. **Story content extraction** — no guidance on what to put in the sub-issue title and description (the story title? the AC? both?)

The LLM executing this skill likely interpreted "create a sub-issue" as "include the story text in the epic description" because the instruction is ambiguous and the epic description already contains the stories.

**Fix:** Expand Step 4e with explicit sub-step instructions for story extraction, sub-issue creation (with tracker-specific sub-issue/subtask API guidance), and per-story back-reference writing.

### Bug 2: Epics (and stories) not closed after implementation

**Location:** `skills/scaffold/SKILL.md`, Steps 7-9 (lines 615-773)

**Root Cause:** The scaffold pipeline has NO step that transitions tracker issues to a completed state after implementation. Comparing with other pipelines:
- `fix-ticket` and `implement-feature` both use the **publisher agent** (Step 9/10) which explicitly updates issue tracker state (publisher.md Step 7: "Set issue state")
- The scaffold pipeline's Step 7 (Feature Implementation Loop) commits code but never touches the tracker
- Step 9 (Final Report) displays results but does not update tracker state
- There is no publisher agent invocation in the scaffold pipeline (by design — scaffold doesn't create PRs per-feature)

The fix-ticket pipeline closes its issue via the publisher agent. The scaffold pipeline skips publisher entirely (it does git commits directly, not PRs), so there's no agent responsible for closing tracker issues.

**Fix:** Add a new step after each epic's subtasks are completed (or after the full implementation loop) that transitions the corresponding tracker issues to "Done" (or equivalent per tracker type). This should use the State Transition syntax from `docs/reference/trackers.md`. Stories should be closed when their corresponding subtask completes; epics should be closed when all their stories are closed.

## Routing Decision

**Template:** None (custom bugfix — no template matches)
**Phase subset:** 1 (research) -> 3 (brainstorm) -> 4 (spec) -> 5 (TDD) -> 6 (plan) -> 7 (execute) -> 8 (verify) -> 9 (completion)
**Phase 2 (deep research):** Skip — the bugs are well-understood from Phase 0 analysis
**Phase 3 (brainstorm):** Include — multiple valid approaches for the fix (per-story vs batch, inline vs separate step)

## Security Evaluation

**Risk:** None. This is a markdown-only change to orchestration instructions. No secrets, no credentials, no runtime code, no user data handling.

## Sizing Estimate

- Lines changed: ~80-120 (additions/modifications in SKILL.md)
- Files changed: 1 primary (`skills/scaffold/SKILL.md`), possibly 1 test file
- Complexity: Medium — requires careful insertion into an already dense orchestration file
