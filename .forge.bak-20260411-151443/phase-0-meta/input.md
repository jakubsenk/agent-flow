# Phase 0 — User Input (Verbatim)

Create a new Automation Config template for Oracle PL/SQL + Redmine stack.

Context:
- Gap analysis in docs/plans/readmine-project/ceos-agents-gap-analysis.md (section 5) contains a draft Automation Config
- Appendices A and B contain complete Agent Override drafts for fixer and test-engineer
- Existing Redmine template: examples/configs/redmine-rails.md (use as format reference)
- Oracle stack: XE 21c Docker, SQLcl 26.1, Flyway 9.22.3, utPLSQL 3.1.14

Tasks:
1. Create examples/configs/redmine-oracle-plsql.md — complete Automation Config template for Redmine + Oracle PL/SQL projects. Format must match the existing redmine-rails.md template. Include all required sections + optional sections relevant for Oracle (Local Deployment, Agent Overrides, Retry Limits, Decomposition). Add comments for what users must customize.
2. Update skills/template/SKILL.md — add redmine-oracle-plsql to the list of available templates.
3. Update docs if there are references to template lists (docs/reference/, README, etc.)
4. Run tests (./tests/harness/run-tests.sh) before completion.

Versioning: this is a new optional template = MINOR change. DO NOT do version bump.
