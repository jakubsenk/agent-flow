# Phase 3 — Brainstorm

> **Fast-track note:** This phase is skipped. No design alternatives to explore — the task is to follow an established pattern exactly.

## Design Decision (Pre-Resolved)

### Approach: Follow Existing Template Pattern
The template must match the format of `examples/configs/redmine-rails.md` (same Redmine tracker) while incorporating Oracle PL/SQL toolchain specifics from the gap analysis.

### Key Design Choices (Already Made)

1. **Template structure:** Match github-nextjs.md pattern — required sections active, optional sections in HTML comments. This provides maximum utility: users see essential config immediately, can uncomment relevant optional sections.

2. **Oracle-specific optional sections to include:**
   - Retry Limits (with conservative values for Oracle: fixer 3, test 2, build 2)
   - Agent Overrides (path to customization/ directory)
   - Local Deployment (Oracle XE Docker container)
   - Decomposition (with tracker subtask creation disabled by default)
   - Pipeline Profiles (oracle-backend profile skipping UI-focused stages)
   - Error Handling (standard defaults)

3. **Placeholders:** Use `<angle-bracket>` format for values users must customize. Use concrete values for Oracle-specific defaults that are sensible across projects.

4. **PR Description Template:** Include Oracle-specific sections (Root Cause, Build/Test results with utPLSQL mention).

## No Alternatives Considered
This is a template addition following an established pattern. There is exactly one correct approach.
