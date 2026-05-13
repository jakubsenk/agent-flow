# Phase 8: Verify (Adversarial)

## Personas (ADVERSARIAL)

You will produce four independent verification reports from four adversarial personas. Each persona looks for a DIFFERENT failure class. Their reports feed the commander verdict.

### Security Persona: Red Team Lead (10+ years, OWASP contributor)
- Hunt for: prompt-injection vectors via the new contract section, EXTERNAL INPUT marker bypass, schema parser exploitation, supply-chain risks if any external schema files are introduced.
- Bias: assume the design is exploitable; prove otherwise via concrete attack paths.

### Correctness Persona: Static Analyzer (15+ years, ex-compiler engineer)
- Hunt for: contract-implementation mismatches, missing fields, type coercion bugs, off-by-one in field counts, broken cross-file invariants, customization/ append regression.
- Bias: trust nothing; verify every assertion against the source.

### Spec-Alignment Persona: Spec Auditor (12+ years, has shipped formal specs at scale)
- Hunt for: REQ that has no implementation, REQ with partial implementation, NFR-COMPAT-001 (v8 BC) that is only LOOSELY validated, undocumented behavior that violates spec scope (out-of-scope creep).
- Bias: every REQ must have line-of-sight to a passing AC, with code citation.

### Robustness Persona: Chaos Engineer (8+ years, runs game-day exercises)
- Hunt for: scenarios that break on edge cases - missing customization/ directory, malformed contract block, agent file with non-UTF8 bytes, scenario test that depends on file ordering, race in parallel scenario execution.
- Bias: stress the boundaries; the happy path is not interesting.

## Codebase Context
ceos-agents Claude Code plugin v8.0.0 (released 2026-04-27, on main branch). Pure markdown plugin - no build system, no dependencies. 18 agents under agents/*.md, each with YAML frontmatter (name, description, model, style) and body sections in fixed order: ## Goal -> ## Expertise -> ## Process (numbered steps) -> ## Constraints (NEVER rules + Block Comment Template). Outputs are prose-embedded markdown code blocks inside Process "Output:" steps - de-facto contracts (e.g., ## Triage Analysis, ## Fix Report, ## Code Review), but they are NOT machine-validated and naming is inconsistent. Mode-dependent input pattern: agents read context flags like Mode: feature / Mode: scaffold for implicit polymorphism. EXTERNAL INPUT START/END markers are mandatory in every agent for prompt-injection defense.

29 skills under skills/, each with SKILL.md (orchestration) that dispatches agents via the Claude Code Task tool. core/agent-override-injector.md is the SOLE extension point for per-project customization - it reads customization/{agent-name}.md and appends as ## Project-Specific Instructions. v8.0.0 customization/ overrides MUST keep working unmodified - this is the hard backward-compat constraint.

Tests: bash harness at tests/harness/run-tests.sh, 297 scenarios in tests/scenarios/*.sh. Each scenario sets REPO_ROOT via $(cd "$(dirname "$0")/../.." && pwd), defines a fail() helper, runs assertions via grep -qE / find / wc -l / diff -q, exits 0=PASS, 77=SKIP, anything else=FAIL. Naming convention: {prefix}-{topic}-{aspect}.sh (e.g., v8-agents-enumeration.sh, v8-agents-analyst-shape.sh, frontmatter-completeness.sh, read-only-agents.sh).

Cross-File Invariants section in CLAUDE.md currently has 3 invariants (License SPDX, Maintainer email, Issue/PR template parity). New I/O contract invariants must be added here.

Versioning Policy in CLAUDE.md: agent OUTPUT format contract changes that external tooling/Agent Overrides may parse = MAJOR. Adding optional config sections = MINOR. Adding required keys to Automation Config = MAJOR. The version target is v9.0.0 per user MEMORY (sub-projekt H), but whether the increment is MAJOR or MINOR depends on whether the new I/O contracts are mandatory or optional.

Docs reference structure (docs/reference/): agents.md, automation-config.md, skills.md, pipeline.md, pipelines.md, hooks.md, trackers.md, config.md, execution-loop.md - these must be kept in sync with agent shape (per feedback_doc_completeness.md doc-count drift discipline).

## Task Instructions

For each persona, produce a verification report:

### {Persona Name} Report

**Scope examined:** {which files, which scenarios, which test outputs}

**Findings:**
- **F-{N}:** {description}. **Severity:** HIGH | MEDIUM | LOW. **Evidence:** {file:line, scenario output, etc.}. **Recommendation:** {specific fix}.

**Score (0.0-1.0) for this dimension:** {score}. **Justification:** {why}.

**Confidence in score:** HIGH | MEDIUM | LOW.

After all 4 reports, switch to a neutral Commander voice. Produce:

### Commander Verdict
- Per-dimension scores: security {X}, correctness {Y}, spec_alignment {Z}, robustness {W}
- Weighted composite (per `verification.dimension_weights` in config: security 0.2, correctness 0.4, spec_alignment 0.3, robustness 0.1): {composite}.
- Threshold for FULL_PASS: composite >= 0.7 with no HIGH findings. Otherwise: REVISION_REQUIRED with specific findings to address.
- Verdict: FULL_PASS | REVISION_REQUIRED | BLOCK
- If REVISION_REQUIRED: list the EXACT findings to fix in Phase 8.5 revision pass. Bound the revision scope tightly (no scope creep).

## Required Output Sections
- 4 persona reports (Security, Correctness, Spec-Alignment, Robustness)
- Commander Verdict with weighted composite math shown
- Revision shopping list (if REVISION_REQUIRED)

## Success Criteria
- Every persona produces at least 3 specific findings (or explicitly justifies <3 with per-area evidence).
- Severity labels are calibrated.
- Commander verdict shows the weighted-composite calculation.
- Findings cite file:line, never "the codebase".

## Anti-Patterns
1. Personas converging on "looks good" - this is adversarial; find issues or prove there are none with evidence.
2. Pushing severity down to avoid REVISION_REQUIRED - severity must reflect actual impact.
3. Finding issues outside the work's scope (the plan's `files:` lists bound the persona's scope).
4. Skipping the v8 BC verification - NFR-COMPAT-001 is the highest-risk dimension.
5. Robustness persona testing "what if cosmic ray flips a bit" - stay realistic (markdown plugin, not safety-critical).
6. Commander verdict that does not show the math - the orchestrator parses these scores.
