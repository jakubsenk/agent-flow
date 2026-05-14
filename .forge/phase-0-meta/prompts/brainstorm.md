# Phase 3: Brainstorming

## Task
Brainstorm the implementation approach for the agent-flow v1.0.0 OSS release migration.

## Three Personas Required

### Persona 1: Conservative Release Engineer
{{PERSONA}}
You are a cautious OSS release engineer who has seen renames go wrong. You prioritize safety: verify before deleting, check cross-file invariants, use find-replace with confirmation. You worry about missing occurrences in unexpected places.

Your approach: Do the rename in strictly ordered waves — delete first (least risk), then rename (most mechanical), then rewrite docs (highest effort). Verify at each step.

### Persona 2: Pragmatic Automator
{{PERSONA}}
You are an automation-focused engineer who wants to do this efficiently in parallel. You know the codebase is pure markdown with no build system, so mechanical renames are safe to parallelize. You'd use a single comprehensive search-replace pass, then verify.

Your approach: One pass for all "ceos-agents" → "agent-flow" replacements across all files simultaneously. Then handle the doc rewrites (README, CHANGELOG, SECURITY) as separate parallel tasks. Delete last.

### Persona 3: Quality-Focused Skeptic
{{PERSONA}}
You are skeptical that a simple find-replace will be enough. You focus on: what CANNOT be renamed (binary files), what should not be renamed (historical references in CHANGELOG), what needs manual rewriting vs automated replacement, and how to verify completeness.

Your approach: Categorize changes by effort — (a) pure mechanical rename, (b) rewrite from scratch, (c) partial update. Address each category separately. Build a verification checklist.

## Success Criteria
{{SUCCESS_CRITERIA}}
- Three distinct, heterogeneous implementation approaches proposed
- Each approach considers ordering, risk, and verification
- Key tensions identified: mechanical rename vs doc rewrite, safety vs efficiency
- A recommendation produced by judge synthesis

## Anti-Patterns
{{ANTI_PATTERNS}}
- Do not converge all three personas on the same approach
- Do not ignore binary files (PDF, PPTX)
- Do not propose approaches that rename git history (explicitly out of scope)
- Do not propose changes to the .forge/ pipeline state (it's being used)

## Codebase Context
{{CODEBASE_CONTEXT}}
Plugin: ceos-agents v10.2.0 being rebranded to agent-flow v1.0.0
Pure markdown plugin. No build system. No tests that run the plugin code.
Files to delete: .forge.bak-*/, docs/plans/, docs/superpowers/, skills/version-bump/
Files to rewrite: README.md, CHANGELOG.md, SECURITY.md, CLAUDE.md, docs/roadmap.md (new)
Files for mechanical rename only: agents/, skills/, core/, docs/guides/, docs/reference/, plugin.json, marketplace.json
