# Phase 3: Brainstorm -- Sprint Planning for ceos-agents

## Personas

### Persona 1: The Conservative Pragmatist
You are a **Senior Plugin Maintainer** who has seen feature creep destroy clean architectures. You believe sprint planning in ceos-agents should be the absolute minimum viable addition -- leveraging existing tracker-native sprint features as much as possible and adding only the thin orchestration layer that connects priority-engine output to tracker sprint APIs. You are skeptical of anything that moves ceos-agents toward being a PM tool. Your mantra: "The best code is the code you don't write."

### Persona 2: The Innovative Integrator
You are a **DevOps Product Designer** who sees sprint planning as the missing link that makes ceos-agents a complete development lifecycle tool. You believe the semi-autonomous mode is the key differentiator -- AI-assisted sprint planning where the priority-engine's analysis feeds into intelligent capacity-aware sprint proposals that humans can refine interactively. You want to push boundaries with features like velocity prediction, automatic scope adjustment, and sprint health monitoring. Your mantra: "Make the human-AI collaboration seamless."

### Persona 3: The Skeptical Architect
You are a **Systems Architect** who questions whether sprint planning belongs in ceos-agents at all, given the roadmap explicitly said NOT PLANNED. You will rigorously stress-test every proposed design against the 6-tracker abstraction layer, identify where the tracker differences make a unified sprint model impossible or fragile, and ensure that whatever is built does not violate the plugin's core principle of being a pure markdown definition system with no runtime state. Your mantra: "If you can't make it work for all 6 trackers, don't build it."

## Task Instructions

Each persona must independently propose a design approach for sprint planning in ceos-agents, then all three must debate and converge on a recommendation.

### Design Dimensions to Address

1. **Architecture:** New agent + new skill, or extend existing components?
2. **Sprint model:** Unified abstraction across trackers, or tracker-specific implementations?
3. **Autonomous vs. semi-autonomous:** How do the two modes differ? What are the human touchpoints?
4. **Capacity planning:** How is team capacity modeled? (story points, issue count, estimated hours?)
5. **Velocity tracking:** Where does velocity data live? State file? Metrics output? Tracker?
6. **Issue selection algorithm:** Pure priority-engine output? Capacity-constrained optimization? Dependency-aware?
7. **Tracker operations:** What operations are needed per tracker? Create sprint, assign issues, set dates?
8. **Config contract:** What new config section(s)? What keys? What defaults?
9. **State persistence:** Sprint state in state.json? Separate sprint file? Tracker-only?
10. **Failure modes:** What happens when tracker doesn't support sprints? When capacity is unknown? When priority-engine output is stale?

### Debate Structure

After each persona proposes their approach:
1. Each persona critiques the other two approaches (specific objections, not vague concerns)
2. Identify areas of agreement across all three
3. Produce a synthesized recommendation that takes the best from each approach

### Output Format

```markdown
## Approach A: [Conservative Pragmatist's Name]
{Full approach description addressing all 10 dimensions}

## Approach B: [Innovative Integrator's Name]
{Full approach description addressing all 10 dimensions}

## Approach C: [Skeptical Architect's Name]
{Full approach description addressing all 10 dimensions}

## Cross-Critique
{Each persona's specific objections to the other two}

## Areas of Agreement
{What all three agree on}

## Synthesized Recommendation
{Final recommended approach with clear rationale for each dimension}
```

## Success Criteria

- Three genuinely different approaches (not minor variations)
- Each approach addresses ALL 10 design dimensions
- Cross-critique identifies real technical concerns, not strawmen
- Areas of agreement form a solid foundation for the spec
- Synthesized recommendation is actionable and addresses the tracker diversity problem
- The recommendation explicitly states what sprint planning does NOT do (scope boundary)
- Semi-autonomous mode has a concrete UX flow, not just "human confirms"

## Anti-Patterns

1. **Consensus too early** -- the three approaches must be genuinely different before attempting synthesis. If they converge in round 1, push harder for differentiation.
2. **Ignoring the 6-tracker problem** -- any approach that only works for Jira and GitHub is insufficient. The abstraction must handle all 6 types or explicitly degrade gracefully.
3. **Feature creep in brainstorm** -- brainstorming is for architecture, not feature wish lists. Each approach must be implementable within the pure-markdown plugin model.
4. **Ignoring the NOT PLANNED history** -- each approach must explain why it is justified despite the previous roadmap decision.
5. **Abstract UX descriptions** -- "semi-autonomous mode asks the user" is not a design. Show the exact prompts, the exact data displayed, the exact user actions.
6. **Velocity as runtime** -- ceos-agents has no runtime. Velocity must be computed from tracker/metrics data at planning time, not tracked in real-time.
7. **Forgetting cold start** -- first sprint with no velocity data is a real scenario. Each approach must handle it.

## Codebase Context

- **Repository:** ceos-agents -- pure markdown Claude Code plugin, 19 agents, 26 skills, 11 core patterns
- **Priority-engine output format:**
  ```
  ## Backlog Prioritization
  ### P0 -- Fix Now (N issues)
  | # | Issue | Impact | Risk | Effort | Score | Rationale |
  ### P1 -- Fix Next (N issues)
  ### P2 -- Backlog (N issues)
  ### Dependencies
  {issue_A} -> blocks -> {issue_B}
  ### Recommendations
  - Suggested batch: {top N issues for next /fix-bugs run}
  ```
- **Existing confirmation UX patterns:**
  - `Create this card? [Y/n]` (implement-feature Step 0c)
  - `Continue? [Y/n]` (decomposition plan, implement-feature Step 5)
  - `Create PR? [Y/n]` (implement-feature Step 9)
- **Tracker sprint concepts:** YouTrack (agile board sprints), Jira (scrum board sprints), Linear (cycles), GitHub (milestones), Gitea (milestones), Redmine (versions)
- **Agent model selection:** opus for critical decisions, sonnet for analysis, haiku for mechanical tasks
- **Config contract rule:** New optional section = MINOR version bump. New required section = MAJOR.
- **Plugin version:** v6.4.6. Next MINOR would be v6.5.0.
- **Versioning policy:** MINOR = new backward-compatible feature (new optional key, new command/agent)
