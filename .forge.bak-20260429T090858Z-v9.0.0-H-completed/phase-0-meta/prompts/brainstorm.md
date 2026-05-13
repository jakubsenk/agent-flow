# Phase 3: Brainstorm

## Personas (HETEROGENEOUS)

You will produce three independent proposals from three distinct personas. Each persona writes IN CHARACTER and DOES NOT compromise to converge with the others. The judge step at the end resolves disagreements.

### Persona A: The Conservative Maintainer (15+ years, ex-Apache committer)
- Bias: minimal change, prove necessity, prioritize backward-compat over elegance.
- Trait: Will defend "do nothing" with evidence if the WHETHER question has no compelling counter-argument.
- Trait: Prefers human-readable prose over machine-readable schemas when the audience is humans (agent prompts ARE consumed by an LLM, not a parser).
- Pet peeve: Premature formalization that locks in the wrong abstraction.

### Persona B: The Innovative Architect (10+ years, has built 3 production agent platforms)
- Bias: lean into structure, extract maximal long-term value, treat contracts as first-class.
- Trait: Will argue for JSON Schema sidecars + dispatcher validation even if it adds files, because it unblocks future tooling (LSP-style autocomplete, contract linters, observability).
- Trait: Sees this as foundation for v10 Node.js Runtime and dashboard.
- Pet peeve: "We can add this later" arguments that ignore Hyrum's Law.

### Persona C: The Skeptical Operator (20+ years, runs ceos-agents in production at BIFITO and drmax-readmine-test)
- Bias: every new abstraction is a new failure mode; prove operational ROI.
- Trait: Will demand concrete failure scenarios that contracts would prevent, with evidence from past pipeline blocks.
- Trait: Does not trust LLM self-validation - if validation runs INSIDE the agent prompt, it's not validation.
- Pet peeve: Designs that look clean in spec but break at the customization/ override boundary.

## Codebase Context
ceos-agents Claude Code plugin v8.0.0 (released 2026-04-27, on main branch). Pure markdown plugin - no build system, no dependencies. 18 agents under agents/*.md, each with YAML frontmatter (name, description, model, style) and body sections in fixed order: ## Goal -> ## Expertise -> ## Process (numbered steps) -> ## Constraints (NEVER rules + Block Comment Template). Outputs are prose-embedded markdown code blocks inside Process "Output:" steps - de-facto contracts (e.g., ## Triage Analysis, ## Fix Report, ## Code Review), but they are NOT machine-validated and naming is inconsistent. Mode-dependent input pattern: agents read context flags like Mode: feature / Mode: scaffold for implicit polymorphism. EXTERNAL INPUT START/END markers are mandatory in every agent for prompt-injection defense.

29 skills under skills/, each with SKILL.md (orchestration) that dispatches agents via the Claude Code Task tool. core/agent-override-injector.md is the SOLE extension point for per-project customization - it reads customization/{agent-name}.md and appends as ## Project-Specific Instructions. v8.0.0 customization/ overrides MUST keep working unmodified - this is the hard backward-compat constraint.

Tests: bash harness at tests/harness/run-tests.sh, 297 scenarios in tests/scenarios/*.sh. Each scenario sets REPO_ROOT via $(cd "$(dirname "$0")/../.." && pwd), defines a fail() helper, runs assertions via grep -qE / find / wc -l / diff -q, exits 0=PASS, 77=SKIP, anything else=FAIL. Naming convention: {prefix}-{topic}-{aspect}.sh (e.g., v8-agents-enumeration.sh, v8-agents-analyst-shape.sh, frontmatter-completeness.sh, read-only-agents.sh).

Cross-File Invariants section in CLAUDE.md currently has 3 invariants (License SPDX, Maintainer email, Issue/PR template parity). New I/O contract invariants must be added here.

Versioning Policy in CLAUDE.md: agent OUTPUT format contract changes that external tooling/Agent Overrides may parse = MAJOR. Adding optional config sections = MINOR. Adding required keys to Automation Config = MAJOR. The version target is v9.0.0 per user MEMORY (sub-projekt H), but whether the increment is MAJOR or MINOR depends on whether the new I/O contracts are mandatory or optional.

Docs reference structure (docs/reference/): agents.md, automation-config.md, skills.md, pipeline.md, pipelines.md, hooks.md, trackers.md, config.md, execution-loop.md - these must be kept in sync with agent shape (per feedback_doc_completeness.md doc-count drift discipline).

## Task Instructions

For each persona, produce a complete proposal with these sections:

### {Persona Name}: {Proposal Title}

**Recommendation:** {Whether to formalize: YES/NO/PARTIAL. If YES/PARTIAL, describe the design in 2-3 sentences.}

**Schema language:** {JSON Schema 2020-12 / typed prose list / TypeScript-style interfaces / EBNF / no schema}

**Contract location:** {frontmatter extension / dedicated ## Inputs and ## Outputs sections in agent body / sidecar agents/contracts/{agent-name}.json / no location needed}

**Validation mechanism:** {static lint via tests/harness / dispatcher runtime check / LLM self-validation in prompt / none}

**Backward-compat strategy:** {additive optional / additive mandatory / migration with v8 grace period / no change needed}

**Versioning verdict:** {MAJOR (v9.0.0 reframed) / MINOR (v9.0.0 as planned) / no bump needed}

**Test strategy:** {specific scenarios in tests/scenarios/ - name them}

**Defense (300-500 words):** Argue this proposal in character. Cite Phase 2 evidence. Acknowledge the strongest counter-argument and explain why your proposal still holds.

**Failure modes you accept:** {2-3 things this proposal will NOT prevent or might make worse}

## Judge Step (after all 3 proposals)

After the 3 proposals, switch to a neutral senior engineering manager voice. Produce:

### Comparative Table
| Dimension | Conservative | Innovative | Skeptical |
|-----------|--------------|-----------|-----------|
| WHETHER  | ... | ... | ... |
| Schema language | ... | ... | ... |
| Location | ... | ... | ... |
| Validation | ... | ... | ... |
| BC strategy | ... | ... | ... |
| Versioning | ... | ... | ... |
| Test strategy | ... | ... | ... |

### Convergence Analysis
- Where the 3 personas AGREE: ...
- Where they DISAGREE most strongly: ...
- Which Phase 2 evidence resolves each disagreement: ...

### Recommended Synthesis
A SINGLE recommended design (not necessarily any one persona's proposal verbatim) with:
- Final WHETHER verdict and 1-paragraph justification
- Final HOW design (schema, location, validation, BC, versioning, tests)
- Explicit list of trade-offs accepted (what we gain, what we give up)
- Phase 4 spec must operationalize THIS synthesis, not the 3 raw proposals

## Success Criteria
- Each persona stays in character (no convergence-in-disguise)
- All 7 dimensions are addressed in each proposal
- Judge step has all 3 sections (table, convergence, synthesis)
- Synthesis is implementable - no hand-waving
- Backward-compat strategy is concrete (specific files, specific behavior)

## Anti-Patterns
1. Personas converging on a "compromise" instead of arguing their position.
2. Skipping the WHETHER question because the user said they want it - the skeptical persona must engage.
3. Hand-waving validation as "TBD" - validation mechanism is load-bearing.
4. Forgetting that customization/ Agent Overrides MUST not break - this is binding on every proposal.
5. Picking a versioning verdict without consulting CLAUDE.md Versioning Policy.
6. Proposing schema languages without naming a specific spec version (e.g., "JSON Schema" - which draft?).
7. Test strategies that don't fit the bash harness pattern (must be tests/scenarios/*.sh).
