# Phase 1: Research Questions — v6.7.2 Pipeline Consistency & Dedup

## Persona
{{PERSONA}}: You are a **plugin architecture analyst** specializing in markdown-based DSL systems, code deduplication patterns, and contract-based pipeline orchestration. You understand how LLM-directed pipelines consume markdown contracts and how duplication degrades maintainability.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Generate research questions for the following 4 work items in the ceos-agents plugin (pure markdown, no runtime code):

### Work Item 1: Tracker Subtask Extraction
The "Create tracker subtasks" pseudocode is duplicated verbatim across 3 skills (fix-ticket step 4b-tracker, fix-bugs step 3b-tracker, implement-feature step 5a). Each copy is ~153 lines including the triple gate, idempotency checks, per-tracker MCP creation, dual store writes, GitHub/Gitea checklist, YAML commit, and result display.

Questions should investigate:
- What are the exact differences (if any) between the 3 copies? Are there subtle divergences beyond the step numbering?
- What input parameters vary per-skill (step labels, decomposition YAML paths, state.json paths)?
- How do other core contracts handle the delegation pattern (e.g., `core/block-handler.md`, `core/post-publish-hook.md`)?
- What is the right granularity for the input contract — should the core contract own the triple gate, or should callers gate before delegating?

### Work Item 2: Webhook Format Alignment
The implement-feature skill deviates from the canonical webhook format used in core contracts.

Questions should investigate:
- What is the complete inventory of all webhook curl calls across all skills and core contracts?
- What are the exact key name deviations (`issue` vs `issue_id`, `pr` vs `pr_url`)?
- Are there any consumers of these webhooks that would break on key name changes? (Likely no — webhooks are fire-and-forget to user-configured URLs)
- Should fix-bugs steps 8b/9a inline webhooks be extracted to core contract references too, or left as-is?

### Work Item 3: Block Handler Inline Removal
implement-feature step X references core/block-handler.md AND inlines the full 6-step procedure.

Questions should investigate:
- Does the inline copy in implement-feature step X differ in any way from core/block-handler.md?
- What skill-specific logic (if any) needs to remain after removing the inline copy?
- How do fix-ticket and fix-bugs handle their block handler steps — do they also inline, or purely delegate?

### Work Item 4: Doc Fixes
Five files need documentation corrections.

Questions should investigate:
- `core/fix-verification.md`: Where does "Fix verification" appear in the title/body? What is the exact replacement text?
- `core/state-manager.md`: What does the forward reference to resume-ticket.md say exactly? What heuristic should replace it?
- `state/schema.md`: What fields does the e2e_test section currently have vs what it should have?
- `state/schema.md`: Where should the triage/code_analysis field reuse note go?
- `core/fixer-reviewer-loop.md`: Where does the NEEDS_DECOMPOSITION reference appear, and what does it currently say?

## Success Criteria
{{SUCCESS_CRITERIA}}:
- At least 15 research questions covering all 4 work items
- Questions are answerable by reading specific files in the repository
- Each question identifies the file(s) to examine
- Questions address both "what is the current state" and "what should the target state be"
- No questions about topics outside the 4 work items

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. Asking vague questions like "how does the pipeline work" instead of targeted file-specific questions
2. Generating questions about Automation Config contract changes (this is a PATCH — no contract changes)
3. Asking about test coverage for the changes (tests are a separate concern for later phases)
4. Generating redundant questions that could be answered by reading the same file
5. Asking about user-facing behavior changes (there are none — this is internal refactoring)

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Repository: ceos-agents — Claude Code plugin, pure markdown definitions
- Structure: `agents/` (21), `skills/` (28), `core/` (14 contracts), `state/` (schema docs), `tests/` (~39 scenarios)
- Key files for this task:
  - `skills/fix-ticket/SKILL.md` — step 4b-tracker (tracker subtasks), step X (block handler)
  - `skills/fix-bugs/SKILL.md` — step 3b-tracker (tracker subtasks), steps 8b/9a (webhooks), step X (block handler)
  - `skills/implement-feature/SKILL.md` — step 5a (tracker subtasks), step 10a (webhook), step X (block handler + inline)
  - `core/block-handler.md` — canonical block handling protocol
  - `core/post-publish-hook.md` — canonical webhook format (heredoc)
  - `core/fix-verification.md`, `core/state-manager.md`, `core/fixer-reviewer-loop.md` — doc fix targets
  - `state/schema.md` — schema doc fix target
- Versioning: v6.7.1 -> v6.7.2 (PATCH)
