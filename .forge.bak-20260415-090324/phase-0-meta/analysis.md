# Phase 0 Analysis — v6.5.2 (Redmine + Publisher Fixes)

## Task Classification

| Dimension | Value | Rationale |
|-----------|-------|-----------|
| Task type | bugfix | Two confirmed pipeline bugs from real-world usage |
| Scope | 3 | ~10 files across agents/, skills/, core/, docs/, examples/ |
| Ambiguity | 1 | Fully specified changes with explicit file list and AC |
| Risk | 1 | No breaking changes, PATCH version, behavioral fixes only |
| Composite | 3 | max(3, 1, 1) |
| Domain | DevOps pipeline, issue tracker integration, markdown definitions |
| Language | Markdown (pure plugin, no runtime code) |

## Complexity Assessment

**Scope = 3:** Changes span multiple layers of the plugin:
- Core contracts: `core/config-reader.md`, `core/block-handler.md`, `core/post-publish-hook.md`
- Agent definitions: `agents/publisher.md`
- Skills: `skills/onboard/SKILL.md`, `skills/fix-ticket/SKILL.md`, `skills/implement-feature/SKILL.md`
- Reference docs: `docs/reference/trackers.md`
- Config templates: `examples/configs/redmine-oracle-plsql.md`, `examples/configs/redmine-rails.md`
- Roadmap: `docs/plans/roadmap.md`

**Ambiguity = 1:** Every change is precisely specified:
- Bug 1: exact format (`status_id:XX`), exact parsing rules, exact verification protocol, exact files
- Bug 2: exact root cause (escaped `\n`), exact fix (multi-line strings), exact files

**Risk = 1:** No config contract changes. All changes are backward-compatible behavioral fixes. Legacy `status:Name` format remains supported with WARN.

## Security Evaluation

| Dimension | Score | Notes |
|-----------|-------|-------|
| Attack surface | None | No new external inputs; existing tracker data parsing only |
| Injection risk | None | No user-controlled code execution paths added |
| Data exposure | None | No credentials or secrets involved |
| Privilege escalation | None | No permission model changes |

Overall security impact: **NONE** — pure markdown definition changes with no runtime code.

## Codebase Context

### Bug 1: Redmine Status Transitions

**Root cause chain:**
1. `docs/reference/trackers.md` line 29 says "The LLM translates this to the appropriate Redmine API call" — this assumption fails in practice
2. `skills/onboard/SKILL.md` step 2.6 generates `status:In Progress` format using trackers.md defaults
3. `core/config-reader.md` parses state_transitions as plain key-value map with no Redmine-specific handling
4. Pipeline skills pass the text-format value directly to MCP, which needs numeric `status_id`
5. No verification after status update — silent failure

**Status-setting call sites (exhaustive):**
- `skills/fix-ticket/SKILL.md` step 1 (On start set)
- `skills/implement-feature/SKILL.md` step 1 (On start set)
- `core/block-handler.md` step 2 (set to Blocked)
- `agents/publisher.md` step 7 (set to For Review)
- `core/fix-verification.md` step 5 (re-open on verify failure)

### Bug 2: Publisher Literal `\n`

**Root cause:** `agents/publisher.md` step 6 creates PR with description filled from template. The agent concatenates the template with `\n` escape sequences as string literals instead of constructing a multi-line string.

**MCP call sites in publisher that accept markdown body:**
- Step 6: `create_pull_request` (body parameter)
- Step 7: `create_issue_comment` (body parameter)

**Other MCP call sites across skills:**
- `core/block-handler.md` step 4: post block comment
- Pipeline skills: block comments via block-handler delegation

## Fast-Track Eligibility

**NOT eligible.** Composite = 3 (threshold <= 2).

## JIT Recommendation

**Recommend jit.enabled: true** — composite >= 3.

## Verification Weight Recommendation

Correctness-critical bugfix — adjusted weights:
- correctness: 0.4 (up from 0.3)
- spec_alignment: 0.3 (up from 0.2)
- security: 0.15 (down from 0.3)
- robustness: 0.15 (down from 0.2)

## Phase Skip Recommendation

All phases KEEP. No phases skipped.
