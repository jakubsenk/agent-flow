# Research Question 6: Non-Code Mode Mapping

## Refined Question

For the unified `/build` pipeline's non-code modes (analysis, strategy, content), which of the 10 forge phases apply as-is, which require adaptation, and which should be skipped? Which existing ceos-agents agents can be repurposed for non-code work with acceptable modifications, and what genuinely new capabilities are required that no existing agent covers?

## Phase Applicability by Mode

| Phase | Code mode | Analysis mode | Strategy mode | Content mode |
|-------|-----------|---------------|---------------|--------------|
| 0 — Meta-Agent | Applicable — analyzes repo, generates code prompts | Applicable — determines output format, research scope | Applicable — determines deliverable type, stakeholder framing | Applicable — determines document type, audience, tone |
| 1 — Research Questions | Applicable — technical research | Applicable — maps market, competitor, data landscape | Applicable — frames strategic options, identifies constraints | Applicable — gathers source material, references, style guides |
| 2 — Research Answers | Applicable | Applicable — web search, data gathering | Applicable — web search, benchmark gathering | Applicable — source collection, fact gathering |
| 3 — Brainstorm + GATE 1 | Applicable — architectural approaches | Applicable — analytical frameworks, hypotheses | Applicable — strategic alternatives, scenarios | Applicable — structural approaches, narrative angles |
| 4 — Specification + GATE 2 | Applicable — EARS requirements, design | Adapted — deliverable structure + acceptance criteria (no code spec) | Adapted — deliverable outline + success criteria | Adapted — document outline + quality criteria |
| 5 — Validation Criteria (TDD) | Applicable — test files from spec | Adapted — quality checklist, fact-check criteria (no executable tests) | Adapted — decision criteria checklist, assumption inventory | Adapted — editorial checklist, completeness criteria |
| 6 — Planning + GATE 3 | Applicable — task graph with parallelizable code tasks | Adapted — section/chapter graph, research task decomposition | Adapted — argument structure, section dependencies | Adapted — content sections with dependency order |
| 7 — Execution | Applicable — parallel implementation in worktrees | Adapted — parallel section writing (no worktrees needed, no git isolation) | Adapted — parallel section drafting | Adapted — parallel section drafting |
| 8 — Verification | Applicable — 5-agent adversarial code review | Adapted — fact-check + consistency + quality review (no security/OWASP agent) | Adapted — logic audit + assumption check + strategic coherence | Adapted — editorial review + factual accuracy + style consistency |
| 9 — Completion | Applicable — commit/PR/keep/discard | Adapted — export (MD/PDF/DOCX) + summary, no git commit needed by default | Adapted — export + summary | Adapted — export + summary |

**Legend:** Applicable = runs as-is; Adapted = phase concept applies but agent prompts and tooling differ; Skip = phase does not apply (none fully skipped across non-code modes — all 10 phases carry value).

**Key structural difference for non-code modes:**
- Phase 5 produces a checklist/criteria document rather than executable test files.
- Phase 7 has no worktree isolation requirement — parallel section writing is in-memory or single-file output.
- Phase 8 replaces security/OWASP agent with a fact-check agent; the correctness agent tests against the Phase 5 checklist rather than running code tests.
- Phase 9 offers export choices rather than git workflow choices.

## Agent Capability Overlap

### spec-writer (opus)

**Existing capability:** Generates structured specification documents (spec/README.md, spec/architecture.md, spec/verification.md, spec/epics/*.md) from a project description. Asks clarifying questions, enforces GWT acceptance criteria, applies YAGNI.

**Overlap with non-code modes:**
- Analysis mode: spec-writer's document-structuring capability directly maps to defining the deliverable structure for an analytical report. The multi-file output approach (README, architecture, verification, epics) parallels a research document's sections (executive summary, methodology, findings, conclusions).
- Strategy mode: The vision/goals/success-criteria structure in spec/README.md mirrors a strategy document's framing. The epic structure (user stories with AC) maps to strategic initiatives with measurable outcomes.
- Content mode: spec-writer's acceptance criteria writing (GWT format) can define what "done" looks like for content deliverables.

**Required adaptations:**
- The agent is wired to software project vocabulary (tech stack, deployment, APIs). The `spec/architecture.md` section is irrelevant for pure content/strategy. The agent would need a mode flag or a rewritten prompt to produce a deliverable specification rather than a software specification.
- The fixed four-file folder structure (spec/README.md, etc.) would need to flex to a single structured document or a different folder scheme for non-code deliverables.
- Constraint "NEVER generate more than 7 epics" carries over cleanly as a scope-bounding rule.

### spec-analyst (sonnet)

**Existing capability:** Transforms a feature request (from issue tracker) into a structured specification with acceptance criteria. Assesses feature size, validates clarity, posts AC to issue tracker.

**Overlap with non-code modes:**
- The core skill — reading a vague input, asking "what does done look like?", extracting measurable acceptance criteria — is exactly what Phase 4 needs for all modes.
- The size-assessment logic (single feature vs. epic) maps to "single deliverable vs. multi-part project."
- The issue-tracker posting behavior is irrelevant for non-code modes when no tracker is configured, but the agent already handles this gracefully ("Block comments go to stdout when no tracker is configured" pattern from spec-writer).

**Required adaptations:**
- The agent is tightly coupled to issue tracker input (reads from YouTrack/GitHub/Jira). For non-code modes driven by a direct text prompt, the input source changes to the user's task description.
- The "if actually a bug report, redirect to bug-fix pipeline" rule is irrelevant.
- Otherwise the agent is highly reusable as the Phase 4 specification agent for non-code modes.

### spec-reviewer (opus)

**Existing capability:** Reviews specification quality (completeness, consistency, feasibility, scope) against a fixed four-file schema. Has a `--verify` mode for checking implementation against spec.

**Overlap with non-code modes:**
- The review loop in Phase 4 (spec-writer ↔ spec-reviewer) is structurally identical for all modes. The concepts it checks — completeness, consistency, feasibility, scope, YAGNI — all apply to non-code deliverables.
- The `--verify` mode is directly reusable for non-code Phase 8 verification: "does the completed document satisfy the spec's acceptance criteria?"
- The BLOCK/WARN severity system and APPROVE/REVISE verdict system are mode-independent and highly reusable.

**Required adaptations:**
- The REQUIRED section checklist (spec/README.md must have Vision & Goals, Tech Stack, etc.) is software-specific. For non-code modes, the reviewer needs a different completeness checklist (e.g., for analysis: executive summary, methodology, findings, conclusions, recommendations).
- The "check feasibility: features are achievable within the tech stack" check must become domain-appropriate (e.g., for strategy: "are the goals achievable within the stated constraints and timeline?").
- The GWT acceptance criteria format may need relaxation for content deliverables where rule-oriented format is more natural for all criteria.

### priority-engine (opus)

**Existing capability:** Analyzes a bug/feature backlog, scores issues on Impact/Risk/Effort, groups into P0/P1/P2 tiers, identifies dependencies.

**Overlap with non-code modes:**
- Strategy mode: The scoring framework (Impact × weight + Risk × weight / Effort) is directly applicable to prioritizing strategic initiatives, investment options, or roadmap items. The dependency graph (which initiative blocks which) maps cleanly.
- Analysis mode: If the analysis involves evaluating multiple options or research directions, priority-engine's multi-dimensional scoring provides a structured framework.

**Required adaptations:**
- The agent is wired to issue-tracker input (issues with ID, title, labels, comments). For non-code strategy mode, the input is a list of strategic options or initiatives, not software issues.
- The "critical/blocker label increases score" rule is software-specific; strategy mode needs domain-appropriate scoring signals.
- The output format (P0/P1/P2 tiers) is generic enough to reuse or slightly relabel.
- Max 50 issues constraint would need to translate to "max 50 options/initiatives."

### code-analyst (sonnet)

**Existing capability:** Maps impact zone of a bug — traces call hierarchy, dependencies, test coverage gaps, risk level, historical commit patterns.

**Overlap with non-code modes:**
- The underlying analytical skill — tracing dependencies, identifying what else is affected by a change, assessing risk — has a loose conceptual parallel in analysis mode (e.g., "what other parts of the argument does this finding affect?").
- The historical pattern detection (recurring bugs in same area) has a weak parallel in content/strategy (recurring issues in same domain area).

**Required adaptations:**
- code-analyst is deeply wired to codebase tooling (Grep, Glob, git log, Bash commands). Its entire Process section is code-specific.
- For non-code modes, this agent's capabilities are largely irrelevant. The Phase 1-2 research agents fulfill the "understand the domain" need instead.
- The only reusable concept is the risk-level framework (LOW/MEDIUM/HIGH with justification), which could inform Phase 3 brainstorming for non-code modes.
- **Conclusion: code-analyst is not meaningfully reusable for non-code modes.** Its role is replaced by the research agents (Phases 1-2) in the unified pipeline.

## Gap Analysis

### Gap 1: Non-code Phase 5 — Quality Criteria Agent

The current Phase 5 (TDD) produces executable test files. For non-code modes, Phase 5 must produce a quality/completeness checklist that Phase 8 can verify against. No existing ceos-agents agent does this. The forge TDD agent is code-specific. A new "criteria-author" capability is needed that reads the Phase 4 specification and produces:
- For analysis mode: fact-check criteria, source citation requirements, methodology completeness criteria
- For strategy mode: assumption inventory, decision criteria, scenario coverage checklist
- For content mode: editorial checklist, completeness criteria, audience-fit criteria

### Gap 2: Non-code Phase 7 — Section Writer / Content Executor

The Phase 7 implementer works in git worktrees and writes code. For non-code modes, the parallel execution units are document sections, not code files. No existing agent writes structured long-form content in parallel. A "section-writer" or "content-executor" capability is needed that:
- Receives a section definition (title, scope, required content, acceptance criteria)
- Writes the section as a standalone document chunk
- Has no git worktree requirement
- Signals completion with a structured status (analogous to Phase 7 status.json)

### Gap 3: Non-code Phase 8 — Fact-Check / Content Verification Agents

The current Phase 8 has four code-specific reviewers (security, correctness via hidden tests, spec alignment, devil's advocate). For non-code modes:
- The security agent is irrelevant.
- The correctness agent (runs hidden tests) has no equivalent — needs replacement with a "fact-check agent" that verifies claims against sources and the Phase 5 checklist.
- The spec alignment agent is reusable if adapted (does the document satisfy the Phase 4 spec?).
- The devil's advocate agent is fully reusable (challenges assumptions, finds weak arguments).
- A "consistency agent" is needed that checks cross-section coherence and terminology consistency.

### Gap 4: Non-code Phase 9 — Export / Delivery

The current Phase 9 completion agent offers git-based choices (commit/PR/keep/discard). Non-code modes need export choices: render as PDF, export as DOCX, deliver as structured Markdown, or post to a destination (email, Confluence, issue tracker). No existing agent handles non-code delivery. The publisher agent (haiku) creates PRs — it would need a sibling "exporter" capability.

### Gap 5: Mode-Aware Meta-Agent Prompts

Phase 0 generates prompts for all downstream phases. These prompts are currently code-mode-specific (they reference tech stacks, test files, code implementation). For non-code modes, Phase 0 needs mode-specific prompt templates. This is a configuration/template gap rather than an agent gap — the meta-agent itself can remain the same if it receives the right mode-specific template library.

### Gap 6: Spec-Writer Mode Adapter

spec-writer's four-file output schema (spec/README.md, architecture.md, verification.md, epics/) is software-specific. For non-code modes, the agent needs either: (a) a separate mode parameter that changes the output schema, or (b) a separate agent variant. Given that the core reasoning (structure a deliverable from user input, write testable criteria) is identical, a mode parameter is preferable over forking the agent.

## Mode Adapter Design Implications

### Analysis Mode Adapter

- **Phase 0:** Must instruct the meta-agent to generate research prompts framed around the analytical question, not a codebase. The meta-agent's `{{CODEBASE_CONTEXT}}` variable becomes `{{DOMAIN_CONTEXT}}`.
- **Phase 4:** spec-writer receives a prompt instructing it to produce a deliverable structure spec (executive summary, methodology, findings, recommendations) instead of a software spec. GWT criteria are replaced with rule-oriented criteria ("MUST include source citations for all statistical claims").
- **Phase 5:** criteria-author produces a fact-check checklist and source-completeness checklist.
- **Phase 7:** section-writer runs without worktree isolation. Git operations are either skipped or simplified to in-place file writes.
- **Phase 8:** Security agent replaced by fact-check agent. Correctness agent verifies against Phase 5 checklist rather than running tests.
- **Phase 9:** Export choice presented instead of git workflow choice.

### Strategy Mode Adapter

- **Phase 0:** meta-agent frames the task as a strategic problem — identifies decision-makers, constraints, success metrics.
- **Phase 3:** brainstorm agents adopt strategic personas (market analyst, risk officer, innovation lead) rather than technical architect personas.
- **Phase 4:** spec-writer produces a strategy document structure (situation analysis, options, recommendation, implementation roadmap, KPIs).
- **Phase 5:** criteria-author produces an assumption log and decision criteria matrix.
- **Phase 6:** planner structures argument/section dependencies rather than code task dependencies.
- **Phase 7:** section-writer. Priority-engine is optionally invoked here to score and rank strategic options if the strategy involves prioritization.
- **Phase 8:** Logic-audit agent + assumption-check agent + devil's advocate (reused) + spec-alignment agent (adapted).
- **Phase 9:** Export + optional posting to issue tracker or stakeholder notification.

### Content Mode Adapter

- **Phase 0:** meta-agent identifies the content type (presentation, documentation, article), target audience, tone, and length constraints.
- **Phase 3:** brainstorm agents adopt content-persona roles (audience advocate, subject matter expert, editor).
- **Phase 4:** spec-writer produces a content brief (purpose, audience, key messages, structure outline, tone guidelines, success criteria).
- **Phase 5:** criteria-author produces an editorial checklist (completeness, accuracy, tone, accessibility, SEO if applicable).
- **Phase 6:** planner produces a section-writing order with dependencies (e.g., "executive summary written after all sections").
- **Phase 7:** section-writer. Parallel section drafting with no git isolation.
- **Phase 8:** Editorial review agent + factual accuracy agent + style consistency agent + devil's advocate (reused).
- **Phase 9:** Export in target format (Markdown, HTML, DOCX, PDF).

### Shared Adapter Concern: Phase 7 Parallelism Without Worktrees

The current Phase 7 uses git worktrees for isolation. Non-code modes do not need isolation (two agents writing different document sections do not conflict the way two agents modifying the same codebase do). The mode adapter must either:
1. Skip worktree setup entirely and have section-writers write to separate output files (e.g., `.forge/phase-7-execution/sections/section-N.md`).
2. Use a lightweight coordination protocol: each parallel writer claims a section ID in forge.json before writing.

Option 1 is simpler and sufficient — document sections have natural isolation by file.

## Files Examined

- `/c/gitea_ceos-agents/agents/spec-writer.md`
- `/c/gitea_ceos-agents/agents/priority-engine.md`
- `/c/gitea_ceos-agents/agents/code-analyst.md`
- `/c/gitea_ceos-agents/agents/spec-reviewer.md`
- `/c/gitea_ceos-agents/agents/spec-analyst.md`
- `/c/Users/FSABACKY/claude/vydelek-zkouska/plugin-merge-brief.md`
- `/c/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.1.0/skills/forge/SKILL.md`

## Migration Risks

### Risk 1: Scope creep in "analysis" and "strategy" mode definitions

The brief's table collapses "Analysis/Strategy mode" into a single column but the mode adapter design above reveals they are meaningfully different. Analysis produces findings from data; strategy produces recommendations for decisions. If these are conflated in the mode adapter, the Phase 3 brainstorm personas, Phase 4 spec structure, and Phase 8 verification agents all need to serve both simultaneously — creating a bloated, unfocused adapter. **Mitigation:** Treat analysis and strategy as separate mode adapters from the start, sharing only generic phase infrastructure.

### Risk 2: Underspecified content mode boundary

"Content" mode is the least specified in the brief. It could mean anything from a blog post to a 200-page technical manual. Without a tighter definition of what content deliverables are in scope, the mode adapter will either over-engineer for edge cases or under-serve the primary use case. **Mitigation:** Define content mode as "structured long-form documents for human consumption" and explicitly exclude interactive content (websites, apps) which belong in code mode.

### Risk 3: spec-writer dual-use tension

The brief proposes merging forge's spec-writer with ceos-agents' spec-analyst into one agent. However, spec-writer (as it exists) is a document-generation agent (produces files) while spec-analyst is an extraction agent (reads an issue, extracts structured data). These are fundamentally different tasks. Merging them into one agent creates a multi-mode agent that handles incompatible input sources (user prompt vs. issue tracker) and output targets (spec/ folder files vs. issue tracker comments). **Mitigation:** Keep them as separate agents with a shared interface contract, or create a thin dispatcher that routes to one or the other based on input source.

### Risk 4: Phase 5 quality criteria have no automated enforcement

In code mode, Phase 5 TDD tests are executable — Phase 8 correctness agent literally runs them. In non-code modes, Phase 5 produces a checklist. Phase 8 can only check the checklist by reading the document and reasoning about it — there is no execution. This means Phase 8 verification for non-code modes is inherently weaker (qualitative reasoning vs. deterministic test results). **Mitigation:** Accept this as a fundamental property of non-code modes. Document explicitly that Phase 8 for non-code modes provides high-confidence qualitative verification, not deterministic correctness guarantees. Set appropriate user expectations in Phase 9 output.

### Risk 5: Priority-engine is not a pipeline agent

The brief shows priority-engine as potentially useful for strategy mode. However, priority-engine is currently invoked standalone via `/prioritize` — it is not designed to be called as a pipeline step receiving structured Phase 6 input. Integrating it into Phase 7 of a strategy pipeline would require either promoting it to a first-class pipeline agent or wrapping it with a thin adapter. **Mitigation:** For v1 of non-code modes, treat priority-engine as an optional enrichment step that the Phase 6 planner can invoke as a sub-tool, rather than a required pipeline phase.

### Risk 6: forge.json schema assumptions break for non-code modes

Phase 9's completion agent reads `forge.json` and generates `files-changed.md` by reading each Phase 7 task's `status.json.files_modified` array. For non-code modes, there are no modified source files — only generated document sections. If the completion agent is reused without modification, it will produce an empty or misleading `files-changed.md`. **Mitigation:** Add a `deliverable_sections` array to forge.json as the non-code equivalent of `files_modified`. The mode adapter populates this instead. Phase 9's completion agent must be mode-aware or have two variants.
