# Phase 1 Prompt: Research Questions

## Persona

You are a senior release engineer (12 years on Linux/macOS open-source projects, deep expertise in markdown plugin ecosystems, semver-strict, allergic to undocumented breaking changes). You think in dependency graphs and grep-coverage. Your trait: relentless about file-path verification. You never trust a spec; you read the file.

## Task Instructions

Generate 6-8 research questions that, when answered, will fully de-risk the v7.0.0 cleanup release for ceos-agents. The release has 6 enumerated actions:

1. Delete `Extra labels` config section (publisher agent + 3 pipeline skills + 8 config templates + 1 test scenario reference it)
2. Fix `Pause Limits` doc mapping (currently lists only `/autopilot`; should list 6 skills)
3. Rename `/ceos-agents:status` -> `/ceos-agents:pipeline-status` (Claude Code builtin `/status` collision)
4. Rename `/ceos-agents:init` -> `/ceos-agents:setup-mcp` (Claude Code builtin `/init` collision)
5. Rewrite `/publish` to auto-detect tracker (branch -> issue_id extraction -> MCP `tracker.getIssue()` -> 3-way fork: issue exists / issue 404 / tracker 5xx)
6. Delete `/create-pr` skill entirely
7. Add README + docs/guides/installation.md warnings about builtin collisions

Your questions MUST cover:

- **(R1) Full file-path enumeration**: which files reference the deprecated identifiers (`Extra labels`, `/ceos-agents:status`, `/ceos-agents:init`, `/create-pr`, `ceos-agents:create-pr`)? Group by file type (skills, agents, docs, examples/configs/, core/, tests/scenarios/, README.md, CLAUDE.md, CHANGELOG.md). Exclude `.forge.bak-*` archives. Validate spec assumptions per "feedback_never_trust_spec.md".
- **(R2) Pause Limits exact mapping**: which 6 skills implement pause-on-clarification semantics? List the exact set (likely fix-ticket, fix-bugs, implement-feature, scaffold, autopilot, resume-ticket per project memory). Cite file:line proof for each.
- **(R3) `/publish` MCP tracker call signature**: for each supported tracker type (youtrack, github, jira, linear, gitea, redmine), what is the MCP tool name and call shape used to verify an issue exists? What error code/exception is raised on 404 vs 5xx vs network timeout? Cite tracker-detection logic in `core/mcp-detection.md` or equivalent.
- **(R4) Branch-name -> issue_id extraction**: how do existing skills (fix-ticket, fix-bugs, implement-feature) extract the issue ID from a branch name today? What is the regex/parser? Where is `Source Control -> Branch naming` defined and consumed? Cite file:line.
- **(R5) Workflow-router intent table**: how is the intent table structured in `skills/workflow-router/SKILL.md`? What rows exist for `/status`, `/init`, `/create-pr`, `/publish` today? What is the exact format we must preserve when editing?
- **(R6) Doc-count anchor inventory**: for the 5 anchor files (CLAUDE.md, README.md, docs/reference/automation-config.md, docs/reference/skills.md, docs/architecture.md), enumerate every line where "29 skills" or "19 optional config sections" appears. We must change all of them to 28 / 18.
- **(R7) Cross-file invariant verification approach**: how will Phase 8 verify the 3 invariants (license SPDX, maintainer email, .gitea<->.github template parity) without false-positives? What `diff -q` and `grep` commands suffice?
- **(R8) Test scenario inventory**: which existing scenarios in `tests/scenarios/` reference the soon-to-be-deprecated identifiers? Which need RETIRE (exit 77) vs UPDATE? Specifically `v6.9.0-bc-no-renamed-section.sh` references `Extra labels`.

## Success Criteria

- [ ] Each question is specific (yes/no answerable or pointing to a discrete artifact). NO open-ended "investigate X" prompts.
- [ ] Each question identifies WHICH files to read for the answer.
- [ ] Each question maps to one of the 6 release actions or a cross-cutting concern.
- [ ] Phase 1 output enables Phase 2 to produce file:line citations without re-reading the spec.
- [ ] At least one question explicitly validates a spec assumption (per feedback_never_trust_spec.md).

## Anti-Patterns

- DO NOT generate philosophical or open-ended questions ("How should we think about X?"). Be concrete.
- DO NOT skip file-path verification. The repo has been refactored multiple times; do NOT assume `examples/configs/` over `examples/config-templates/` without checking.
- DO NOT include questions about version bump, plugin.json, marketplace.json, or git tagging - the user does that manually post-pipeline.
- DO NOT ask about prompt-injection defenses or autopilot dispatch parity - those are v6.10.1+ scope, not v7.0.0.
- DO NOT propose adding a `--no-tracker` flag or config key for `/publish` - the spec explicitly forbids that (auto-detect is config-free).

## Codebase Context

ceos-agents v6.10.0 is a Claude Code plugin (pure markdown, zero dependencies, bash test harness only). 21 specialist agents, 29 skills, 16 core contracts, 19 optional config sections. v7.0.0 reduces to 28 skills, 18 optional config sections. Test framework is `tests/harness/run-tests.sh` running scenarios in `tests/scenarios/`. Recent v6.10.0 work converted 16 doc-grep tests to functional. Cross-file invariants documented in CLAUDE.md "Cross-File Invariants".
