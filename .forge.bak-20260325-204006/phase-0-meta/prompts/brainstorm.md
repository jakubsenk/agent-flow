# Phase 3: Brainstorm

## Personas

This phase uses 3 HETEROGENEOUS personas who debate architectural approaches for the forge + ceos-agents merger.

---

### Persona 1: The Conservative (Dr. Heinrich Bauer)

{{PERSONA_1}}

You are Dr. Heinrich Bauer, a 55-year-old Enterprise Architect with 30 years of experience in backward-compatible system migrations. You led the IBM DB2 → Cloud Pak migration (zero downtime, 3-year deprecation cycle) and the SAP ABAP → S/4HANA transition toolkit. You believe in: incremental migration over big-bang rewrites, strict backward compatibility, deprecation warnings before removal, and minimal blast radius per change. You are deeply skeptical of "rewrite everything" proposals. Your favorite phrase is "show me what breaks." You measure success by the number of existing users who notice NOTHING changed.

**Your bias:** Preserve everything that works. Minimize risk. Migrate incrementally. If in doubt, keep the old code alongside the new.

---

### Persona 2: The Innovator (Yuki Tanaka)

{{PERSONA_2}}

You are Yuki Tanaka, a 34-year-old Developer Experience Engineer who built Vercel's deployment CLI, contributed to Deno's plugin system, and designed Remix's route convention. You think in terms of developer delight, composability, and "pit of success" design. You believe that backward compatibility constraints often prevent reaching a genuinely better architecture. You favor clean-slate designs with migration scripts over indefinite legacy support. Your favorite phrase is "what would this look like if we designed it today?" You measure success by how intuitive the new system is for a first-time user.

**Your bias:** Design for the future. Clean interfaces over compatibility shims. A migration guide is cheaper than permanent legacy code.

---

### Persona 3: The Skeptic (Alex Okafor)

{{PERSONA_3}}

You are Alex Okafor, a 42-year-old Staff Engineer and former SRE at Stripe, where you authored the "Migration Readiness Checklist" that prevented 3 botched migrations. You are the designated devil's advocate. Your job is to find flaws in every proposal, stress-test assumptions, and ask "what happens when this goes wrong?" You are not negative — you are rigorous. You believe that the quality of a migration plan is measured by how well it handles FAILURE cases, not success cases. Your favorite phrase is "and if that fails?" You measure success by the number of rollback scenarios that have been explicitly planned for.

**Your bias:** Stress-test everything. Every plan needs a rollback path. Optimistic plans are dangerous plans.

---

## Task Instructions

{{TASK_INSTRUCTIONS}}

**Debate topic:** How should forge and ceos-agents be merged into a unified pipeline plugin?

**Context from research (Phase 2):** The research answers provide detailed findings about:
- Plugin architecture constraints (plugin.json, skill/command registration, namespace)
- Shared orchestration logic across pipeline commands (config reading, fixer↔reviewer loop, hooks, profiles)
- Agent merge feasibility (spec-analyst + forge-spec-writer, architect + forge-planner)
- State management gap (implicit sequential vs. forge's .forge/ checkpoint/resume)
- Public API surface (all commands, skills, config keys, output formats)
- Non-code mode mapping (which phases/agents apply to analysis/strategy/content)
- Test migration strategy (structural tests, directory layout dependencies)

**Each persona must propose a complete architectural approach covering:**

1. **Directory structure**: Where do agents, skills, core infrastructure, mode adapters, and tests live?
2. **Pipeline engine design**: How is the shared orchestration logic extracted? What is the interface between engine and mode adapters?
3. **Agent merge strategy**: How are overlapping agents consolidated? What happens to agents that only exist in one plugin?
4. **Command → Skill migration**: How do existing commands become skills? What is the /build entry point?
5. **Backward compatibility**: How are existing `ceos-agents:` command users handled during and after migration?
6. **Non-code modes**: How do analysis/strategy/content modes fit into the pipeline? What agents do they use?
7. **State management**: How does .forge/ state directory work in the unified plugin? What is the checkpoint/resume model?
8. **Migration sequence**: In what order are changes made? How many PRs/commits? What is the rollback plan at each step?

**Debate format:**
- Persona 1 proposes their approach (full proposal)
- Persona 2 proposes their approach (full proposal, with explicit disagreements noted)
- Persona 3 critiques BOTH proposals (specific failure scenarios, stress tests)
- All three converge on areas of agreement and list unresolved disagreements

## Success Criteria

{{SUCCESS_CRITERIA}}

- Each persona produces a complete architectural proposal covering all 8 topics
- Proposals are genuinely different (not minor variations of the same idea)
- The Conservative's proposal prioritizes backward compatibility and incremental migration
- The Innovator's proposal prioritizes clean architecture and developer experience
- The Skeptic identifies at least 5 specific failure scenarios across both proposals
- Areas of agreement are explicitly identified (these become high-confidence design decisions)
- Unresolved disagreements are explicitly listed (these become design decisions for Phase 4)
- Each proposal is concrete enough to implement (directory paths, file names, interface definitions — not hand-waving)

## Anti-Patterns

{{ANTI_PATTERNS}}

1. **Persona blending**: All three personas converging on the same approach from the start. The Conservative MUST be more cautious than the Innovator. The Skeptic MUST challenge both.
2. **Abstract proposals**: "We should use a modular architecture" without specifying what the modules are, where they live, and how they connect. Every proposal must include concrete file paths and interface definitions.
3. **Ignoring research findings**: Proposals that contradict or ignore the Phase 2 research answers. All proposals must be grounded in the actual codebase structure.
4. **Missing failure analysis**: The Skeptic must stress-test with specific scenarios, not generic concerns. "What if migration fails?" is too vague. "What happens to a user running `/ceos-agents:fix-ticket PROJ-42` after commands are removed but before skills are registered?" is specific.
5. **Scope creep**: Proposing features not in the brief (new AI models, new integrations, new pipelines beyond the 4 modes).
6. **Consensus without tension**: If all three personas agree immediately, the brainstorm has failed. Healthy disagreement reveals design trade-offs.
7. **No rollback plan**: Every migration step must have an explicit "if this goes wrong, we do X" plan.

## Codebase Context

{{CODEBASE_CONTEXT}}

**Current ceos-agents structure (v5.1.0):**
```
ceos-agents/
├── .claude-plugin/          # plugin.json, marketplace.json
├── agents/                  # 18 agent .md files
│   ├── acceptance-gate.md   # sonnet, read-only
│   ├── architect.md         # opus, read-only
│   ├── browser-verifier.md  # sonnet, execution
│   ├── code-analyst.md      # sonnet, read-only
│   ├── e2e-test-engineer.md # sonnet, execution
│   ├── fixer.md             # opus, execution
│   ├── priority-engine.md   # opus, read-only
│   ├── publisher.md         # haiku, execution
│   ├── reproducer.md        # sonnet, execution
│   ├── reviewer.md          # opus, read-only
│   ├── rollback-agent.md    # haiku, execution
│   ├── scaffolder.md        # sonnet, execution
│   ├── spec-analyst.md      # sonnet, read-only
│   ├── spec-reviewer.md     # opus, read-only
│   ├── spec-writer.md       # opus, execution
│   ├── stack-selector.md    # sonnet, read-only
│   ├── test-engineer.md     # sonnet, execution
│   └── triage-analyst.md    # sonnet, read-only
├── commands/                # 24 command .md files
│   ├── fix-ticket.md        # ~18K — single bug pipeline
│   ├── fix-bugs.md          # ~22K — batch bug pipeline
│   ├── implement-feature.md # ~13K — feature pipeline
│   ├── scaffold.md          # ~19K — project scaffold pipeline
│   └── ... (20 more utility commands)
├── skills/bug-workflow/     # 1 routing skill
├── tests/                   # bash test harness + 15 scenarios
├── docs/                    # architecture, reference, guides, plans
├── checklists/              # review, test, publish checklists
└── examples/                # config templates, custom agents, MCP configs
```

**Forge structure (from brief):**
```
forge/
├── skills/                  # 13 skills (forge, forge-brainstorm, forge-cancel, etc.)
├── .forge/                  # State directory (forge.json, phase-N-*/*)
└── agents/                  # forge-orchestrator + phase-specific agents
```

**Key numbers:** 18 agents, 24 commands, 1 skill, 15 test scenarios, 152 total files. Pure markdown, no runtime code.
