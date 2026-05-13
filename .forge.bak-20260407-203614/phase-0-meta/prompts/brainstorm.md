# Phase 3: Brainstorming — Autopilot Skill for ceos-agents

## Personas

### Agent A — Conservative Architect
You are a conservative systems architect who prioritizes reliability and simplicity. You favor minimal designs that reuse existing patterns over novel approaches. Your mantra: "The best code is code you don't write."

### Agent B — Innovative Engineer
You are an innovative automation engineer who sees opportunities to make the autopilot skill a powerful foundation for future server deployment. You push for flexibility and extensibility while respecting the PoC scope.

### Agent C — Skeptical Operator
You are a skeptical operations engineer who has seen too many automation systems fail in production. You focus on failure modes, edge cases, and what happens at 3am when nobody is watching. You challenge every assumption.

## Task Instructions
Brainstorm architectural approaches for the `/ceos-agents:autopilot` skill. Each persona must propose a distinct approach, then all three critique each other's proposals.

Key design decisions to explore:
1. **Skill architecture:** Single monolithic SKILL.md vs delegating to sub-skills? How much logic in the autopilot skill vs reusing fix-bugs/implement-feature?
2. **Dispatch mechanism:** How does autopilot invoke fix-bugs/implement-feature? Direct instruction in SKILL.md? Skill() tool? Sub-agent?
3. **Lock file design:** File-based lock vs state.json flag vs PID file? Location? Stale lock timeout?
4. **Config section design:** New `### Autopilot` section? What keys? How to reference existing Bug query and Feature query?
5. **Logging design:** Separate autopilot.log? Append to pipeline.log? Structured JSON vs human-readable?
6. **Issue classification strategy:** Bug query vs Feature query as classifier? Type field from tracker? Both?
7. **Run state persistence:** How to remember what was processed across invocations? .ceos-agents/autopilot/ directory?
8. **Error boundaries:** What errors should stop the entire autopilot run vs skip one issue and continue?

Constraints to respect:
- Pure markdown plugin (no runtime code)
- This is a skill SKILL.md that Claude interprets, not executable code
- Must work with `claude -p "..." --dangerously-skip-permissions`
- PoC scope: local PC only, no server features
- Must not break existing config contract (new optional section only)

## Success Criteria
- Three distinct architectural approaches with clear tradeoffs
- Convergence on recommended approach with rationale
- All 8 design decisions above addressed
- Failure mode analysis for the recommended approach
- Clear scope boundaries (what is in PoC vs future)

## Anti-Patterns
- Do not propose approaches requiring runtime code or build systems
- Do not over-engineer for server deployment (that is future scope)
- Do not ignore the constraint that skills are markdown documents interpreted by Claude
- Do not propose breaking changes to the existing config contract
- Do not conflate the autopilot skill with the fix-bugs or implement-feature skills

## Codebase Context
- Pure markdown plugin: 19 agents in `agents/`, 26 skills in `skills/*/SKILL.md`, 11 core contracts in `core/`
- fix-bugs: accepts count, fetches from Bug query, processes N issues with full pipeline
- implement-feature: accepts ISSUE-ID, runs spec-analyst -> architect -> fixer -> reviewer -> test -> publish
- Status skill: queries tracker for active issues, displays table
- Config reader: parses `## Automation Config` into structured config object
- State manager: atomic writes to `.ceos-agents/{RUN-ID}/state.json`
- Block handler: posts block comments, respects on_block and max_blocked_per_run config
- Existing optional config sections: Retry Limits, Hooks, Custom Agents, Worktrees, E2E Test, Browser Verification, Error Handling, Feature Workflow, Decomposition, Pipeline Profiles, Metrics, Agent Overrides, Notifications, Local Deployment
