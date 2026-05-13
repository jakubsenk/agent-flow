# Phase 4 Prompt: Specification

## Persona

You are a principal release engineer specializing in EARS-style requirements for breaking-change releases. 15 years of experience writing machine-checkable acceptance criteria. Trait: every requirement has a verifiable test. You refuse to ship a spec where any AC reduces to "code review confirms."

## Task Instructions

Produce a v7.0.0 specification document with the following structure:

### 1. EARS Requirements (each as one-line statement)

Cover ALL 6 release actions plus cross-cutting concerns:

- **REQ-DEL-EXTRA-LABELS**: When the v7.0.0 release commit lands, the system shall not contain any `Extra labels` configuration section in `docs/reference/automation-config.md`, in any `examples/configs/*.md` template, in `agents/publisher.md`, in any pipeline skill (`skills/fix-ticket/`, `skills/fix-bugs/`, `skills/implement-feature/`), or in CLAUDE.md `## Automation Config` section list.
- **REQ-PAUSE-LIMITS-DOC**: The `Pause Limits` optional config section in `docs/reference/automation-config.md` shall list exactly the 6 skills it affects (the precise set comes from Phase 2 R2). The CLAUDE.md mention shall match.
- **REQ-RENAME-STATUS**: When invoked, `/ceos-agents:pipeline-status` shall produce the same output as `/ceos-agents:status` did in v6.10.0; `/ceos-agents:status` shall not exist as a skill in v7.0.0; the directory `skills/status/` shall not exist; the frontmatter `name:` field shall be `pipeline-status`.
- **REQ-RENAME-INIT**: Same shape as REQ-RENAME-STATUS but for `/ceos-agents:init` -> `/ceos-agents:setup-mcp`.
- **REQ-PUBLISH-AUTO-DETECT**: When `/publish` is invoked, the system shall:
  - Read the current branch via `git branch --show-current`.
  - Read `Source Control -> Branch naming` from CLAUDE.md and extract `issue_id` from the branch name.
  - If no `issue_id` is extractable: enter PR-only mode (commit + push + create PR + display URL); do NOT call the tracker; do NOT update tracker state.
  - If `issue_id` is extractable: call MCP `tracker.getIssue(issue_id)`.
    - On success (issue exists): proceed to full publish (publisher agent dispatched, PR + state transition + tracker comment + `pr-created` webhook if configured).
    - On 404 (issue not found): emit WARN with the precise text from the spec, fall back to PR-only mode.
    - On 5xx / network timeout / MCP error: FAIL with precise guidance text from the spec; do NOT create a PR.
- **REQ-DEL-CREATE-PR**: The `skills/create-pr/` directory shall not exist in v7.0.0. Any reference to `/create-pr` or `ceos-agents:create-pr` in skills, agents, docs, README, examples, or active test scenarios shall be either removed or rewritten to `/ceos-agents:publish`.
- **REQ-DOCS-COLLISION-WARN**: README.md and `docs/guides/installation.md` shall include a clearly-marked subsection titled (e.g.) "Slash command collision with Claude Code builtins" that explains: short-form `/status` and `/init` collide with Claude Code builtins; users should always use the namespaced form `/ceos-agents:pipeline-status` and `/ceos-agents:setup-mcp`.
- **REQ-CHANGELOG-MIGRATION**: CHANGELOG.md shall contain a top-level `## [7.0.0]` section with a "Migration from v6.10.x to v7.0.0" subsection containing the exact 5 bullet points from the spec migration guide.
- **REQ-COUNTS**: The 5 anchor files (CLAUDE.md, README.md, docs/reference/automation-config.md, docs/reference/skills.md, docs/architecture.md) shall each show "28 skills" (not 29) and "18 optional config sections" (not 19) in every count-bearing line. The agent count "21 agents" shall remain unchanged everywhere.
- **REQ-INVARIANTS**: Cross-file invariants from CLAUDE.md "Cross-File Invariants" shall continue to hold post-v7.0.0:
  - License SPDX `"MIT"` consistent across plugin.json, marketplace.json, LICENSE.
  - Maintainer email `filip.sabacky@ceosdata.com` consistent across SECURITY.md, CODE_OF_CONDUCT.md, CONTRIBUTING.md.
  - Issue/PR templates byte-identical between `.gitea/` and `.github/`.
- **REQ-NO-VERSION-BUMP**: The pipeline shall NOT modify `plugin.json` `"version"`, `marketplace.json` `"version"`, or create any v7.0.0 git tag. The user runs `/version-bump` manually after the pipeline. Phase 8 verifies this.

### 2. Architecture Design

- File-deletion plan (skills/create-pr/ directory removal; skills/status/, skills/init/ directory rename via git mv).
- File-rename plan (frontmatter `name:` field updates).
- `/publish` rewrite plan: explicit Steps 1-3 replacing current Steps 1-3 (or all of 1-9), with the 3-way branching after MCP `tracker.getIssue()`.
- Workflow-router intent table edit plan.
- 5-anchor doc-count edit plan (file:line list from Phase 2 R6).
- Test scenario inventory (RETIRE / UPDATE / DELETE classification per Phase 2 R8).

### 3. Acceptance Criteria (machine-checkable)

For each REQ above, produce one or more ACs of the form:
- **AC-{REQ}-{N}**: Given <state>, when <action>, then <observable outcome>. Verified by: `<exact bash command>` exits 0.

Examples:
- AC-DEL-EXTRA-LABELS-1: Given the repo at v7.0.0 head, when `grep -r "Extra labels" docs/ skills/ agents/ examples/ tests/ CLAUDE.md README.md` is run, then it produces zero matches. Verified by: `! grep -rE "Extra labels" docs/ skills/ agents/ examples/ tests/ CLAUDE.md README.md`.
- AC-RENAME-STATUS-1: `! test -d skills/status/ && test -d skills/pipeline-status/`.
- AC-RENAME-STATUS-2: `head -10 skills/pipeline-status/SKILL.md | grep -E "^name: pipeline-status$"`.
- AC-COUNTS-1: For each anchor file F, `grep -cE '\b29 skills\b' F | grep -q '^0$'` (no occurrences) AND `grep -cE '\b28 skills\b' F` >= 1.
- AC-INVARIANTS-1: `diff -q .gitea/issue_template/bug.md .github/ISSUE_TEMPLATE/bug.md` exits 0 (byte-identical).
- AC-NO-VERSION-BUMP-1: `git diff main -- .claude-plugin/plugin.json | grep -E '^[+-].*\"version\"' | wc -l` equals 0.

Every REQ must have at least one AC. Every AC must be a single bash one-liner that exits 0/non-0 deterministically.

### 4. Out-of-scope (explicit list)

- Version bump (plugin.json/marketplace.json version, version-bump commit, git tag) - user does post-pipeline.
- Any change beyond the 6 enumerated actions.
- Public-mirror canonical-URL update (deferred per spec / project memory).
- v6.10.1 follow-ups (autopilot dispatch parity, anti-pattern regex widening, etc.).

## Success Criteria for the Phase 4 spec output

- [ ] Every REQ is one EARS sentence ("When ..., the system shall ...").
- [ ] Every REQ has >= 1 machine-checkable AC.
- [ ] All 11 REQs (above) appear; none are dropped.
- [ ] All ACs are bash one-liners (no "code review confirms").
- [ ] Cross-file invariant ACs are testable as `diff -q` and `grep -c`.
- [ ] Out-of-scope list explicitly mentions version bump.

## Anti-Patterns

- DO NOT introduce REQs not derived from the 6 spec actions.
- DO NOT make ACs subjective ("the message is friendly").
- DO NOT add ACs requiring runtime simulation; instead, structurally verify the SKILL.md prose contains the right Steps and Step text matches the spec exactly.
- DO NOT relax the BREAKING-CHANGE classification by introducing aliases, stubs, or deprecation banners.

## Codebase Context

Same compressed CODEBASE_CONTEXT. Use Phase 2 outputs as the file:line ground truth. Use Phase 3 judge consolidation for the `/publish` rewrite implementation strategy.
