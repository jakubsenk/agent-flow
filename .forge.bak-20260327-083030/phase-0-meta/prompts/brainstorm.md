# Phase 3: Brainstorm

## Personas

You will conduct a structured brainstorm with **3 heterogeneous personas**. Each persona must generate at least 3 distinct ideas. After all personas contribute, synthesize into a unified recommendation.

### Persona A: The Pragmatic Incrementalist

**Background:** Senior engineering manager who has shipped 50+ developer tools. Believes in "boring technology," minimal viable features, and shipping fast. Skeptical of grand designs.

**Perspective:** What is the smallest useful increment? What can we ship in 1 day that provides value? Which of the 5 workflow stages has the highest ROI individually? What existing commands can we compose rather than building new ones?

**Biases to counteract:** May undervalue long-term architecture. Push back if solutions are too myopic.

### Persona B: The Systems Thinker

**Background:** Platform engineer who designs developer platforms at scale. Thinks in feedback loops, state machines, and composability. Loves clean abstractions.

**Perspective:** What is the right abstraction layer? How do the 5 stages compose into a state machine? What invariants must hold between stages? How does state flow from scaffold to feature to deploy? What is the minimal kernel that makes the whole pipeline extensible?

**Biases to counteract:** May over-engineer. Push back if solutions require more than 5 new files or break existing conventions.

### Persona C: The User Advocate

**Background:** Developer experience designer who has conducted 100+ usability studies. Focuses on cognitive load, error recovery, and the "pit of success." Cares about what happens when things go wrong.

**Perspective:** What does the user actually type? What is the mental model? How many commands do they need to learn? What happens when step 3 fails — can they resume? What if they want to skip the tracker? What if they're a solo developer vs. a team?

**Biases to counteract:** May prioritize UX over technical feasibility. Push back if solutions require runtime features the plugin cannot support.

## Task Instructions

**Context:** Design a scaffold-to-deployment workflow for the ceos-agents Claude Code plugin. The workflow has 5 stages:

1. **SCAFFOLD MODE:** Create project in issue tracker, add first epic, run scaffold pipeline
2. **FEATURE LOOP:** Add features to tracker, run implement-feature for each
3. **FORGE INTEGRATION:** Optionally use filip-superpowers forge to decompose epics into tracker cards
4. **LOCAL DEPLOYMENT:** Deploy locally with DB, FE, BE
5. **FUTURE:** Integrate on standalone machine

**Constraints:**
- Plugin is pure markdown — no runtime code, no build system
- All orchestration via Claude Code's Task/Bash/Read/Write tools
- Must follow existing conventions (command frontmatter, agent structure, config contract)
- Must not break existing scaffold/implement-feature commands
- Versioning: new required config key = MAJOR bump, new optional section = MINOR bump
- The user says this is exploratory — the design itself is the deliverable

**Research findings are available from Phase 2.** Use them as grounding.

**For each persona:**
1. Generate 3-5 distinct ideas for the overall workflow design
2. For each idea, specify: name, 1-paragraph description, pros (2-3), cons (2-3), estimated effort (XS/S/M/L), files affected
3. Be specific about what new commands/agents/config sections are needed

**After all personas:**
1. Identify convergence points (ideas that all personas support)
2. Identify divergence points (genuine disagreements about approach)
3. Synthesize a recommended approach that takes the best from each persona
4. Flag open questions that need user input

## Success Criteria

- 9-15 distinct ideas total across 3 personas
- Each idea is concrete enough to evaluate (not abstract hand-waving)
- Pros/cons are honest — not just cheerleading
- Convergence/divergence analysis is insightful
- Synthesized recommendation is actionable and phased
- Open questions are specific and decision-forcing

## Anti-Patterns

1. **Homogeneous thinking** — If all 3 personas converge on the same solution immediately, the brainstorm has failed. Push for genuine disagreement.
2. **Ignoring constraints** — Every idea must work within pure-markdown plugin architecture. No "just add a Node.js server" suggestions.
3. **Boiling the ocean** — The design must be deliverable in phases. Any idea that requires all 5 stages simultaneously is suspect.
4. **Cargo-culting existing patterns** — Don't just copy fix-bugs.md structure for a deployment command. Deployment has fundamentally different characteristics (stateful, long-running, environment-dependent).
5. **Ignoring failure modes** — Every idea must address: what happens when Docker isn't installed? When the tracker API is down? When the scaffold fails halfway? When deployment health checks never pass?
6. **Forgetting the user** — The user types commands in Claude Code. Every workflow step must be expressible as a slash command or a natural language instruction that the skill router can handle.
7. **Scope amnesia** — This is a DESIGN task. The brainstorm should explore the design space, not produce implementation code.

## Codebase Context

**Repository:** ceos-agents (Claude Code plugin, pure markdown, v5.2.0)
**18 agents, 24 commands, 10 core contracts, 1 skill**

**Existing relevant commands:**
- `/scaffold` — Create project from scratch (spec -> skeleton -> [implement])
- `/scaffold-add` — Add component (docker, ci, tests, claude-md) to existing project
- `/implement-feature` — Implement feature from issue tracker (spec -> design -> fix -> test -> publish)
- `/init` — Configure MCP servers and permissions
- `/onboard` — Create Automation Config in CLAUDE.md
- `/check-setup` — Validate configuration
- `/status` — Show pipeline state
- `/resume-ticket` — Resume blocked pipeline

**Existing relevant agents:**
- scaffolder — Generates skeleton with Docker, CI, test infra, CLAUDE.md
- spec-writer / spec-reviewer — Specification generation and review
- architect — Task decomposition with maps_to AC tracking
- All pipeline agents (fixer, reviewer, test-engineer, publisher, etc.)

**Config contract:** Required sections (Issue Tracker, Source Control, PR Rules, PR Description Template, Build & Test) + 15 optional sections

**State management:** `.ceos-agents/{RUN-ID}/state.json` with pipeline.log event tracking

**Deployment gap:** Scaffolder generates Dockerfile + docker-compose.yml + CI config, but no command exists to actually run/verify the deployment. The scaffolder's test infrastructure (Batch 3) includes dynamic port allocation and health check helpers, but these are for test setup, not deployment verification.
