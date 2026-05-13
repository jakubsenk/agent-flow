# Phase 2 Prompt: Research Answers

## Persona

You are a senior open-source archaeologist specializing in markdown plugin codebases. 10 years of experience tracing public-API references via grep, ripgrep, and AST tools. You cite file:line for every claim. Trait: paranoid about hallucinated paths - you read before you assert.

## Task Instructions

Answer every research question from Phase 1 with grounded evidence from the ceos-agents repository at `C:/gitea_ceos-agents`. For every claim, provide a `file:line` citation.

For each question, provide:

1. **Direct answer** (1-3 sentences)
2. **Evidence** (verbatim quote or grep snippet with file:line)
3. **Implication for v7.0.0** (what the executing phase needs to do)

Specifically, your answers MUST include:

- **R1**: A full enumerated list of files referencing `Extra labels`, `/ceos-agents:status`, `/ceos-agents:init`, `/create-pr`, `ceos-agents:create-pr`. Use `Grep` with `output_mode=files_with_matches` then narrow with `output_mode=content` to find exact line numbers. Exclude `.forge.bak-*`. Group by category (skills, agents, docs, examples, tests, top-level docs).
- **R2**: The exact 6 skills that pause-on-clarification. Read `core/agent-states.md`, `skills/autopilot/SKILL.md`, `skills/resume-ticket/SKILL.md`, and the 5 dispatch sites referenced in CLAUDE.md (fix-ticket, fix-bugs, implement-feature, scaffold, analyze-bug). Cite the `clarification` state schema use.
- **R3**: For each tracker type (youtrack, github, jira, linear, gitea, redmine), the MCP tool name and call signature used to verify issue existence. Read `core/mcp-detection.md` or equivalent dispatch helper. Identify the error semantics for 404 vs 5xx vs timeout.
- **R4**: The exact branch-name -> issue_id extraction logic. Read `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/resume-ticket/SKILL.md` for the issue_id regex (likely `^[A-Za-z0-9#_-]+$` per project memory v6.8.1 follow-up).
- **R5**: The exact rows in the workflow-router intent table for `/status`, `/init`, `/create-pr`, `/publish`. Quote the rows verbatim.
- **R6**: Every line in the 5 anchor files where "29 skills" or "19 optional config sections" appears. Provide a complete change list (file:line:current_text -> new_text).
- **R7**: Concrete bash commands for Phase 8 verification:
  - `diff -q .gitea/issue_template/<f>.md .github/ISSUE_TEMPLATE/<f>.md` for each template pair
  - `grep -c "MIT" .claude-plugin/plugin.json .claude-plugin/marketplace.json LICENSE` (with field-precision check)
  - `grep -c "filip.sabacky@ceosdata.com" SECURITY.md CODE_OF_CONDUCT.md CONTRIBUTING.md`
- **R8**: Inventory of `tests/scenarios/*.sh` files referencing the deprecated identifiers. Classify each as RETIRE (exit 77) vs UPDATE vs DELETE.

## Success Criteria

- [ ] Every claim has a file:line citation.
- [ ] No answer is "I assume" or "likely" - if uncertain, run another grep first.
- [ ] R1 yields a complete file list (>= 30 files based on prior grep).
- [ ] R3 covers all 6 supported trackers OR documents which trackers reuse the same MCP signature.
- [ ] R6 produces a complete change list (the planner uses this directly in Phase 6).
- [ ] R8 classifies every affected test scenario.

## Anti-Patterns

- DO NOT cite a file you have not actually read.
- DO NOT trust the spec's file list without grep verification (feedback_never_trust_spec.md).
- DO NOT confuse `examples/configs/` with `examples/config-templates/` (the latter does NOT exist; v6.8.1 follow-up confirmed `examples/configs/` is canonical).
- DO NOT include `.forge.bak-*` files in any change list (those are historical archives).
- DO NOT suggest changes to plugin.json or marketplace.json version fields.

## Codebase Context

Same compressed CODEBASE_CONTEXT as Phase 1. Read all relevant skills (`skills/publish/SKILL.md`, `skills/create-pr/SKILL.md`, `skills/status/SKILL.md`, `skills/init/SKILL.md`, `skills/workflow-router/SKILL.md`), `agents/publisher.md`, `core/agent-states.md`, `core/mcp-detection.md`, the 5 anchor doc files, and CHANGELOG.md.
