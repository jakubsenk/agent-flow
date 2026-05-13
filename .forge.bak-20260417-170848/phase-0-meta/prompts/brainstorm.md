# Phase 3: Brainstorm — v6.7.2 Pipeline Consistency & Dedup

## Personas

### Agent 1: Contract Design Architect
{{PERSONA_1}}: You are a **contract design architect** who specializes in creating reusable, composable contracts for LLM-directed pipeline systems. You prioritize clean input/output boundaries, minimal coupling, and forward compatibility.

### Agent 2: Refactoring Pragmatist
{{PERSONA_2}}: You are a **refactoring pragmatist** who has maintained large markdown-based DSL systems. You prioritize minimal diff size, zero behavioral change, and preserving LLM comprehension patterns (explicit repetition where it helps the LLM follow instructions).

### Agent 3: Documentation Systems Engineer
{{PERSONA_3}}: You are a **documentation systems engineer** specializing in schema documentation, cross-reference integrity, and terminology consistency across technical specifications. You focus on how documentation consumers (both humans and LLMs) parse and rely on precise terminology.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Brainstorm approaches for the 4 work items in v6.7.2. Each agent should propose a complete approach for ALL 4 items, not just their specialty area.

### Work Item 1: Tracker Subtask Extraction
The ~153-line "Create tracker subtasks" block is duplicated across fix-ticket, fix-bugs, and implement-feature. Design the extraction to `core/tracker-subtask-creator.md`.

Key design decisions:
- **Input contract scope**: Should the core contract own the triple gate (skip conditions), or should callers evaluate the gate and only call the contract when they decide to proceed?
- **Caller residue**: What remains in each skill after extraction? Just the delegation reference, or also the step header and input values?
- **Per-Tracker table**: Should the table move to the core contract, or stay duplicated in each skill for LLM context?
- **mcp-body-formatting reference**: The core contract will need its own reference to this dependency.

### Work Item 2: Webhook Format Alignment
implement-feature has deviating webhook key names and missing flags.

Key design decisions:
- **Scope of alignment**: Fix only implement-feature deviations, or also standardize fix-bugs inline webhooks?
- **Inline vs delegation**: Should implement-feature step 10a delegate to core/post-publish-hook.md entirely (like fix-ticket does), or keep inline with corrected format?
- **Key naming convention**: Confirm `issue_id` (not `issue`) and `pr_url` (not `pr`) as canonical.

### Work Item 3: Block Handler Inline Removal
implement-feature step X inlines the full block procedure after referencing core/block-handler.md.

Key design decisions:
- **Residual content**: What stays in step X after removing the inline copy? The state.json update is skill-specific.
- **Comparison with other skills**: fix-ticket step X says "Follow core/block-handler.md" and adds state.json update. fix-bugs step X inlines more detail. Should fix-bugs also be cleaned up?

### Work Item 4: Doc Fixes
Five files with documentation issues.

Key design decisions:
- **fix-verification.md title**: "Fix verification" -> "Verification" or "Post-merge verification"?
- **state-manager.md heuristic**: How to express the inline heuristic without creating a new forward reference?
- **e2e_test fields**: What exact field definitions to add (types, defaults, descriptions)?

## Success Criteria
{{SUCCESS_CRITERIA}}:
- Each agent proposes a complete approach covering all 4 work items
- Approaches are concrete (not abstract principles) — specify what text goes where
- At least one approach addresses the "LLM comprehension" angle (whether extraction hurts or helps the LLM's ability to follow pipeline instructions)
- Trade-offs between approaches are explicit
- All approaches maintain PATCH semantics (no behavioral change)

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. Proposing new features or enhancements beyond the 4 specified work items
2. Suggesting changes to the Automation Config contract (this is a PATCH)
3. Over-engineering the core contract with excessive abstraction
4. Ignoring the LLM-directed nature of the pipeline (these markdowns are prompts, not code)
5. Proposing changes that would require updating consuming projects
6. Treating the fix-bugs contributor note comment as duplication to remove
7. Suggesting test changes without grounding in specific test file analysis

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Repository: ceos-agents — Claude Code plugin, pure markdown
- Core contracts follow: Purpose, Input Contract, Process, Output Contract, Failure Handling
- Skills reference core contracts with: "Follow `core/{name}.md`" + input values
- The triple gate pattern is consistent across all 3 skills — it should move to the core contract
- fix-bugs has a `<!-- Contributor note:` explaining intentional repetition of state.json write instructions — do NOT consolidate those
- 14 existing core contracts, this adds the 15th
- Current version: v6.7.1, target: v6.7.2 (PATCH)
