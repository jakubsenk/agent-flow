# Phase 1: Research Questions -- Sprint Planning for ceos-agents

## Persona

You are a **DevOps Automation Architect** with deep expertise in issue tracker APIs (YouTrack, Jira, Linear, GitHub, Gitea, Redmine), sprint/iteration management across project management tools, and human-in-the-loop workflow design for AI-assisted development pipelines.

## Task Instructions

Generate a comprehensive set of research questions that must be answered before designing and implementing sprint planning capability for the ceos-agents plugin. The research must cover:

### Tracker API Sprint Semantics (CRITICAL)

For each of the 6 supported tracker types, determine:
1. **YouTrack:** How are sprints/agile boards managed via MCP API? What is the data model (sprint = board iteration)? Can sprints be created/updated/queried programmatically? What MCP tool patterns exist for sprint operations?
2. **Jira:** How does the Jira MCP server expose sprint management? What is the relationship between sprints, boards, and issues? Can issues be moved to sprints via MCP? What about Jira Cloud vs Jira Server differences?
3. **Linear:** What is Linear's "cycle" concept and how does it map to sprints? How are cycles created and issues assigned to cycles via the Linear MCP API?
4. **GitHub:** GitHub has no native sprint concept -- how do milestones serve as sprint proxies? What are the limitations? Can milestone dates be set programmatically via GitHub MCP?
5. **Gitea:** Same as GitHub -- milestones as sprint proxy. What Gitea/Forgejo MCP API operations exist for milestone management?
6. **Redmine:** How do Redmine "versions" map to sprints? Can target versions be set on issues via MCP? What about Redmine's sprint/agile plugins?

### Semi-Autonomous Workflow Design

7. What are the human decision points in sprint planning? (Issue selection, capacity confirmation, sprint goal, scope negotiation)
8. How should the autonomous mode differ from semi-autonomous? What does the AI decide vs. what does the human confirm?
9. What existing ceos-agents confirmation patterns can be reused? (e.g., implement-feature Step 5 decomposition approval, Step 0c card creation confirmation)
10. How should velocity be calculated when no historical data exists (cold start)?

### Integration with Existing Components

11. How should sprint planning consume priority-engine output? Should it run priority-engine internally or require it as a prerequisite?
12. What is the relationship between sprint planning and the existing `/fix-bugs` batch processing? Does sprint planning replace/extend batch selection?
13. How should sprint state persist? New state schema fields? Separate sprint state file?
14. Should sprint planning be aware of decomposition (architect output) for capacity planning?

### Config Contract

15. What new Automation Config sections are needed? Sprint duration, team capacity, velocity target?
16. Is this a MINOR version bump (new optional section) or MAJOR (required section)?
17. How does sprint planning interact with existing Pipeline Profiles?

### Scope Boundaries

18. Should sprint planning include sprint review/retrospective automation, or only planning?
19. Should it include burndown tracking, or delegate that to the tracker's native views?
20. What is the minimum viable sprint planning that delivers value without becoming a PM tool?

## Success Criteria

- All 6 tracker types have documented sprint/iteration API capabilities and MCP tool availability
- Semi-autonomous workflow decision points are clearly identified
- Integration points with existing priority-engine, fix-bugs, and implement-feature are mapped
- Config contract impact is assessed (MINOR vs MAJOR version bump)
- Clear scope boundary: what sprint planning does and does NOT do in ceos-agents
- At least 20 research questions covering all 4 areas above

## Anti-Patterns

1. **Tracker-agnostic handwaving** -- do NOT assume all trackers have equivalent sprint APIs. Research each one specifically.
2. **PM tool creep** -- sprint planning in ceos-agents must enhance the existing pipeline, not replace dedicated PM tools. Keep scope tight.
3. **Ignoring cold start** -- velocity calculation with no history is a real problem. Do not skip it.
4. **Assuming MCP completeness** -- MCP servers may not expose all tracker API features. Research actual MCP tool availability, not just tracker REST APIs.
5. **Overlooking the roadmap reversal** -- the roadmap explicitly said "NOT PLANNED" for sprint planning. Research questions must address WHY the previous decision was wrong and what changed.

## Codebase Context

- **Repository:** ceos-agents -- pure markdown Claude Code plugin, no runtime code
- **Supported trackers:** youtrack, jira, linear, github, gitea, redmine (MCP-based access)
- **Existing prioritization:** `agents/priority-engine.md` produces P0/P1/P2 tiers with impact/risk/effort scores
- **Existing batch processing:** `skills/fix-bugs/SKILL.md` processes N issues sequentially
- **Existing tracker creation:** `skills/implement-feature/SKILL.md` Step 5a creates sub-issues in all 6 tracker types
- **Config pattern:** Optional sections in `## Automation Config` with `| Key | Value |` tables
- **State pattern:** `.ceos-agents/{RUN-ID}/state.json` with atomic writes via `core/state-manager.md`
- **Current version:** v6.4.6 (plugin.json)
- **Agent count:** 19 agents, 26 skills, 11 core patterns
- **Roadmap status:** Sprint planning was NOT PLANNED -- now explicitly requested by author
