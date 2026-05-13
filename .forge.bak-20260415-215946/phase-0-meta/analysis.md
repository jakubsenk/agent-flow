# Phase 0 Analysis — v6.7.0 (Pipeline Hardening)

## Task Classification

| Dimension | Value | Rationale |
|-----------|-------|-----------|
| Task type | feature | Two new capabilities: prompt injection protection (new core contract + agent constraints) and plugin version tracking (new state field + resume behavior) |
| Scope | 3 | ~15 files across agents/, skills/, core/, state/, tests/ |
| Ambiguity | 1 | Fully specified by user with exact file paths, markers, and content |
| Risk | 2 | No breaking changes, no config contract changes. Risk from touching many agent files (5 agents, 5 skills) simultaneously |
| Composite | 3 | max(3, 1, 2) |
| Domain | Pipeline security, state management, markdown plugin definitions |
| Language | Markdown (pure plugin, no runtime code) |

## Complexity Assessment

**Scope = 3:** Changes span multiple layers of the plugin:
- Core contracts: new `core/external-input-sanitizer.md`, modify `core/state-manager.md`
- Agent definitions: `agents/triage-analyst.md`, `agents/code-analyst.md`, `agents/fixer.md`, `agents/reviewer.md`, `agents/spec-analyst.md`
- Skills: `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/resume-ticket/SKILL.md`, `skills/scaffold/SKILL.md`
- State schema: `state/schema.md`
- Plugin metadata: `CLAUDE.md` (core count update 13 -> 14)
- Tests: new test scenario file
- Roadmap: `docs/plans/roadmap.md`

**Ambiguity = 1:** Every change is precisely specified:
- Item 1: exact markers (`--- EXTERNAL INPUT START ---` / `--- EXTERNAL INPUT END ---`), exact files, exact constraint text
- Item 2: exact field name (`plugin_version`), exact comparison logic, exact WARN behavior

**Risk = 2:** No config contract changes (MINOR version). Risk is slightly elevated because:
- 5 agent files need simultaneous constraint additions (pattern must be consistent)
- 5 skill files need sanitizer references (wrapping logic must be identical)
- But all changes are additive — no existing behavior is modified, only augmented

## Security Evaluation

| Dimension | Score | Notes |
|-----------|-------|-------|
| Attack surface | Reduced | Item 1 explicitly mitigates prompt injection via external tracker content |
| Injection risk | Reduced | Markers prevent LLM from following injected instructions in issue titles/descriptions |
| Data exposure | None | No credentials or secrets involved |
| Privilege escalation | None | No permission model changes |

Overall security impact: **POSITIVE** — Item 1 is specifically a security hardening measure.

## Codebase Context

### Item 1: Prompt Injection Protection (D2)

**What gets wrapped:** External content from issue trackers — titles, descriptions, comments, PR descriptions. These are fetched via MCP tools and passed to agents as context.

**Where wrapping happens:** After MCP read, before agent dispatch. The pipeline skills (fix-ticket, fix-bugs, implement-feature, resume-ticket, scaffold) read from trackers and build agent context.

**Agents receiving external content:**
- `triage-analyst` — reads issue details directly (step 1)
- `code-analyst` — receives triage output containing issue details (step 1)
- `fixer` — receives issue context transitively through triage + impact report
- `reviewer` — receives issue context through triage + fixer output
- `spec-analyst` — reads feature request details directly (step 1)

**Existing constraint pattern in agents:** All agents have a `## Constraints` section with NEVER rules. The new constraint follows the same pattern.

### Item 2: Plugin Version Tracking (D12)

**State schema:** `state/schema.md` defines the structure of `.ceos-agents/{RUN-ID}/state.json`. Adding `plugin_version` as a new top-level field.

**State manager:** `core/state-manager.md` handles read/write/resume of state files. Needs instruction to read version from `.claude-plugin/plugin.json` at initialization time.

**Resume-ticket:** `skills/resume-ticket/SKILL.md` reads state files and determines resume point. Adding version comparison: if stored `plugin_version` differs in major version from current -> WARN.

**Plugin version source:** `.claude-plugin/plugin.json` contains `"version": "6.6.0"`.

## Fast-Track Eligibility

**NOT eligible.** Composite = 3 (threshold <= 2).

## JIT Recommendation

**Recommend jit.enabled: true** — composite >= 3, multiple cross-cutting file changes.

## Verification Weight Recommendation

Security-focused feature — adjusted weights:
- security: 0.3 (keep default — Item 1 is security-related)
- correctness: 0.3 (keep default — must verify all files have consistent markers/constraints)
- spec_alignment: 0.2 (keep default — exact spec compliance matters)
- robustness: 0.2 (keep default — version comparison edge cases)

Default weights are appropriate for this task.

## Phase Skip Recommendation

All phases KEEP. No phases skipped.
- Research: needed to verify all external-content touchpoints across 28 skills
- Brainstorm: useful for marker format and agent constraint wording
- Spec: needed to formalize exact marker text and wrapping process
- TDD: needed for test scenario
- Plan: needed for dependency ordering (core contract before skills/agents)
- Execute: implementation
- Verify: critical for ensuring all 5 agents + 5 skills are consistently updated
