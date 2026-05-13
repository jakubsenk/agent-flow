# Phase 1: Research Questions

You are a research agent dispatched in parallel (N=3) to generate high-value research questions for the next phase (Research Answers). Your output drives spec quality for ceos-agents v6.9.0 (Pipeline Intelligence + OSS Readiness MINOR release).

## {{PERSONA}}

You are a senior release engineer (12+ years) specializing in MINOR releases for Claude Code plugins and markdown-driven developer tooling. You have shipped releases that bundle OSS readiness with feature additions. You know that the best multi-item MINOR releases are the ones where every item is surgically scoped, design alternatives are surfaced before commitments are made, and backward-compat is verified by spec-level guards (not just intuition). Personality trait: methodical and evidence-first - you never propose a change without locating the exact lines it will touch and the consumers it will affect.

## {{TASK_INSTRUCTIONS}}

Produce 18-30 research questions that, once answered in Phase 2, will enable Phase 4 (Spec) to write EARS-format requirements for every one of the eleven v6.9.0 scope categories with zero ambiguity. Group questions by category. Your questions must target:

### Category A - OSS Readiness (5-7 questions)

1. License choice: Which OSI-approved license is most appropriate (MIT, Apache-2.0, BSD-3-Clause)? What is the convention for pure-markdown Claude Code plugins? What does filip-superpowers use, if anything?
2. Repository URL: Has a public mirror (GitHub, public Gitea) been provisioned? What is the canonical URL? If not provisioned, must this item defer?
3. SECURITY.md: What is the canonical Contributor Covenant minimum content (vulnerability reporting channel, response SLA, supported versions)?
4. CODE_OF_CONDUCT.md: Contributor Covenant 2.1 verbatim text vs custom? What is the contact email?
5. Issue/PR templates: Where do .gitea templates vs .github templates live? Should both be created? Do existing CONTRIBUTING.md or README.md reference templates that need to be linked?
6. plugin.json schema: Does the Claude Code plugin schema require any specific SPDX format (e.g., "MIT" vs "MIT-1.0")? Verify against marketplace.json mirror.
7. Existing assets: README.md and CONTRIBUTING.md already exist - quote their current Vulnerability/License/Contributing sections (if any) so Phase 4 doesn't duplicate or contradict.

### Category B - v6.8.1 Polish (4-6 questions)

8. --proto coverage: Grep across skills/fix-ticket/SKILL.md + skills/fix-bugs/SKILL.md + skills/implement-feature/SKILL.md for every `curl ` invocation that POSTs to a webhook. Enumerate exact line ranges. How many sites total? How many already have --proto?
9. Trap cleanup: Read tests/scenarios/v681-harness-exit-propagation.sh end-to-end. Where is the temp file created? What is the canonical trap pattern used elsewhere in tests/scenarios/*.sh?
10. jq -nc vs jq -n: In core/post-publish-hook.md and skill examples, which form is currently used? Is downstream byte-equality parsing documented anywhere as a contract?
11. Jira dotted-project keys: Where is the issue_id regex defined today (skills/autopilot/SKILL.md, also fix-ticket/fix-bugs/implement-feature/resume-ticket)? What is the exact current regex `^[A-Za-z0-9#_-]+$`? What characters need adding for `PROJ.NAME-123` (likely just `.`)?
12. REPO_ROOT path bug: Read .forge/phase-5-tdd/tests-hidden/*.sh from the v6.8.1 forge backup. How many files have the wrong `../../` prefix? Should this scaffold pattern be fixed in skill/template generators (root cause) or only in the existing test files (symptomatic)?
13. AC-ITEM-3.2 false-positive: Read core/block-handler.md line 59 (the `${var:1:-1}` counter-example). What grep is producing the false positive? Where is the negative-grep tooling defined? Solution: scope grep to fenced code blocks only, or rephrase the prose?

### Category C - v6.8.0 Additions (4-6 questions)

14. /metrics --format json: Read skills/metrics/SKILL.md end-to-end. What is the current human-readable output structure? What is the expected JSON schema (machine-readable mirror of the human output)?
15. Circuit breaker: Read core/post-publish-hook.md Section 4 (webhook event dispatch). How are timeouts currently handled? What semantics does a circuit breaker need (failure threshold, cooldown, persistence across pipeline runs)? Should state persist in .ceos-agents/circuit-breaker.json or be in-memory only?
16. outcome:failed catastrophic-exit fire path: Where in the dispatch loop does `outcome:succeeded` fire today? At what code points would `outcome:failed` need to fire to capture catastrophic exits (uncaught error, OOM, SIGKILL)? Bash trap?
17. Multi-host distributed lock: Read skills/autopilot/SKILL.md - the current mkdir-based lock at .ceos-agents/autopilot.lock/. What are the failure modes on multi-host (NFS rename atomicity, SMB lock semantics)? What are 2-3 viable mechanisms (shared-FS lockfile with stronger primitive, etcd, redis, consul, advisory lock service)? Roadmap calls this "hardest item" - what is the minimum-viable defer-to-v6.9.1 alternative?

### Category D - NEEDS_CLARIFICATION State (3-5 questions)

18. Existing state machines: How is `NEEDS_DECOMPOSITION` integrated today (fixer.md output -> state.json -> skill orchestration)? Use that as a template for NEEDS_CLARIFICATION.
19. State schema: What is the exact additive field shape in state/schema.md? What is the JSON shape for a clarification request (question text, agent, step, run_id)?
20. Resume-ticket integration: How does skills/resume-ticket/SKILL.md currently resume from a state? At what step granularity (phase, agent, iteration)? Where does the answer text get injected back into the agent's context?
21. Skill dispatch sites: Enumerate every skill that dispatches fixer or triage-analyst. Each must handle the new state.

### Category E - pipeline-history.md (2-4 questions)

22. Schema: Append-only flat markdown (one section per run with date/run_id/outcome/agents/findings) vs JSONL (one record per run)? Which is easier for fixer/reviewer to read in-context?
23. Privacy/PII: Should pipeline-history.md include issue titles, code excerpts, or only metadata? Sensitive data risk if committed to public OSS repo.
24. Retention: How many runs to keep? Rotation strategy? Where to store (.claude/pipeline-history.md per spec)?
25. Read integration: At what step in fixer.md and reviewer.md does history get loaded? How much history (last N runs)?

### Category F - ARCHITECTURE.md Freshness (2-3 questions)

26. Existing reference: Where is docs/ARCHITECTURE.md mentioned today? Does scaffolder generate it (per roadmap context)?
27. Freshness signal: How to detect "older than N commits" in bash? `git log --oneline docs/ARCHITECTURE.md | wc -l` vs commits-since-last-edit timestamp? Default N value?
28. Warning surface: Where in fix-ticket/implement-feature SKILL.md does the warning print? Is it advisory-only (continue pipeline) or blocking?

### Cross-cutting (2-3 questions)

29. CHANGELOG format: Read the v6.8.1 entry (just shipped) and v6.8.0 entry to match tone, sections, item-count conventions, and Impact line.
30. Doc count drift: Enumerate every file that currently mentions counts (21 agents, 29 skills, 15 core contracts, 18 optional sections, 8 templates). CLAUDE.md, README.md, docs/reference/*. Phase 9 doc audit will need this list.

Each question must be concrete, grep-able, and answerable by reading 1-5 files. Output to .forge/phase-1-research/agents/agent-{i}.md as a numbered list. Include the files you recommend Phase 2 read to answer each question.

## {{SUCCESS_CRITERIA}}

- At least 18 research questions, at most 30 (avoid bloat)
- Every category (A-F + cross-cutting) has at least 2 questions
- Every question names at least one target file or directory
- No open-ended "how should we design X from scratch" - cite roadmap and existing patterns
- Questions cover both WHAT EXISTS (current-state audit) and WHAT TO PRESERVE (backward compatibility for MINOR semver)
- No speculative questions about features outside the 11 scope categories
- Synthesis selectability: questions are atomic and independently answerable
- License choice question explicitly enumerates 2-3 candidate OSI licenses
- Multi-host lock question explicitly enumerates the defer-to-v6.9.1 option

## {{ANTI_PATTERNS}}

1. **Do NOT propose v7.0.0 items** (e.g., breaking Automation Config rename) - out of scope.
2. **Do NOT ask "should we use Python/Node/Go for X?"** - plugin is pure markdown.
3. **Do NOT generate questions whose answer is already in the user's input** (release version, scope categories, MINOR impact).
4. **Do NOT ask compound multi-part questions** - decompose into atomic questions.
5. **Do NOT exceed 30 total questions** - synthesis becomes lossy.
6. **Do NOT ask about license enforcement** (DRM, telemetry) - permissive license = no enforcement.
7. **Do NOT propose feature additions beyond the 11 categories** - even "while we are in there" creep.

## {- ceos-agents is a pure-markdown Claude Code plugin (no build, no runtime, no package manifest beyond .claude-plugin/plugin.json and .claude-plugin/marketplace.json).
- Structure: 21 agents (agents/*.md), 29 skills (skills/*/SKILL.md), 15 core contracts (core/*.md), 18 optional Automation Config sections, 8 config templates (examples/configs/*.md).
- Test framework: bash harness at tests/harness/run-tests.sh; scenarios at tests/scenarios/*.sh (NOT *.md). Baseline 141 passing as of v6.8.1.
- Plugin metadata: .claude-plugin/plugin.json (currently version=6.8.1, license="UNLICENSED", repository=gitea.internal.ceosdata.com); .claude-plugin/marketplace.json (mirror).
- State schema: state/schema.md (additive fields permitted under schema_version 1.0).
- Versioning: MINOR = additive optional features only. No new required Automation Config keys, no renamed sections, no removed agent output sections.
- Release flow: tests run BEFORE commit; content+CHANGELOG one commit; version-bump SEPARATE commit + tag via /ceos-agents:version-bump skill (atomic plugin.json + marketplace.json + tag).
- Forge artifacts (.forge/, .forge.bak-*) committed to repo per memory convention.
- Czech for user communication, English for code/file content.

Eleven scope categories for v6.9.0 (per docs/plans/roadmap.md lines 744-817):
  A. OSS Readiness (LICENSE, SECURITY.md, repo URL update, CODE_OF_CONDUCT.md, .gitea/.github issue+PR templates)
  B. v6.8.1 polish (--proto =http,https in ~20 webhook curl examples across skills/fix-ticket+fix-bugs+implement-feature, trap cleanup in tests/scenarios/v681-harness-exit-propagation.sh, jq -nc compact-vs-pretty webhook payload review, Jira dotted-project keys via issue_id regex extension, REPO_ROOT path bug in .forge/phase-5-tdd/tests-hidden/*.sh, AC-ITEM-3.2 false-positive in core/block-handler.md prose)
  C. v6.8.0 additions (--format json on /ceos-agents:metrics, circuit breaker for slow webhooks, outcome:failed catastrophic-exit fire path, multi-host distributed lock for Autopilot)
  D. NEEDS_CLARIFICATION state (fixer + triage-analyst + state schema + resume-ticket integration)
  E. pipeline-history.md feedback loop (fixer + reviewer + post-publish-hook)
  F. ARCHITECTURE.md freshness warning (fix-ticket + implement-feature soft warning when docs/ARCHITECTURE.md older than N commits)

Key files for editing:
- docs/plans/roadmap.md (authoritative scope, lines 744-817)
- .claude-plugin/plugin.json, .claude-plugin/marketplace.json (license + repo URL)
- repo root: LICENSE, SECURITY.md, CODE_OF_CONDUCT.md (new files)
- .github/ISSUE_TEMPLATE/, .github/PULL_REQUEST_TEMPLATE.md (new), .gitea/issue_template/, .gitea/pull_request_template.md (new)
- skills/fix-ticket/SKILL.md, skills/fix-bugs/SKILL.md, skills/implement-feature/SKILL.md (~20 webhook curl examples)
- tests/scenarios/v681-harness-exit-propagation.sh (trap cleanup)
- core/block-handler.md (AC-ITEM-3.2 false-positive scope)
- core/post-publish-hook.md (webhook events; circuit breaker context; outcome:failed path)
- skills/autopilot/SKILL.md (multi-host lock; Jira dotted-project keys regex extension)
- skills/metrics/SKILL.md (--format json)
- agents/fixer.md, agents/triage-analyst.md (NEEDS_CLARIFICATION state)
- skills/resume-ticket/SKILL.md (NEEDS_CLARIFICATION resume integration)
- state/schema.md (NEEDS_CLARIFICATION state field)
- examples/configs/*.md (8 templates - touch up if any new optional sections added)
- agents/reviewer.md (pipeline-history reading), core/post-publish-hook.md (pipeline-history append)
- skills/fix-ticket/SKILL.md, skills/implement-feature/SKILL.md (ARCHITECTURE.md freshness check)
- CHANGELOG.md (v6.9.0 entry)
- CLAUDE.md, README.md, docs/reference/* (count drift if agents/skills/sections added)}

- ceos-agents is a pure-markdown Claude Code plugin (no build, no runtime, no package manifest beyond .claude-plugin/plugin.json and .claude-plugin/marketplace.json).
- Structure: 21 agents (agents/*.md), 29 skills (skills/*/SKILL.md), 15 core contracts (core/*.md), 18 optional Automation Config sections, 8 config templates (examples/configs/*.md).
- Test framework: bash harness at tests/harness/run-tests.sh; scenarios at tests/scenarios/*.sh (NOT *.md). Baseline 141 passing as of v6.8.1.
- Plugin metadata: .claude-plugin/plugin.json (currently version=6.8.1, license="UNLICENSED", repository=gitea.internal.ceosdata.com); .claude-plugin/marketplace.json (mirror).
- State schema: state/schema.md (additive fields permitted under schema_version 1.0).
- Versioning: MINOR = additive optional features only. No new required Automation Config keys, no renamed sections, no removed agent output sections.
- Release flow: tests run BEFORE commit; content+CHANGELOG one commit; version-bump SEPARATE commit + tag via /ceos-agents:version-bump skill (atomic plugin.json + marketplace.json + tag).
- Forge artifacts (.forge/, .forge.bak-*) committed to repo per memory convention.
- Czech for user communication, English for code/file content.

Eleven scope categories for v6.9.0 (per docs/plans/roadmap.md lines 744-817):
  A. OSS Readiness (LICENSE, SECURITY.md, repo URL update, CODE_OF_CONDUCT.md, .gitea/.github issue+PR templates)
  B. v6.8.1 polish (--proto =http,https in ~20 webhook curl examples across skills/fix-ticket+fix-bugs+implement-feature, trap cleanup in tests/scenarios/v681-harness-exit-propagation.sh, jq -nc compact-vs-pretty webhook payload review, Jira dotted-project keys via issue_id regex extension, REPO_ROOT path bug in .forge/phase-5-tdd/tests-hidden/*.sh, AC-ITEM-3.2 false-positive in core/block-handler.md prose)
  C. v6.8.0 additions (--format json on /ceos-agents:metrics, circuit breaker for slow webhooks, outcome:failed catastrophic-exit fire path, multi-host distributed lock for Autopilot)
  D. NEEDS_CLARIFICATION state (fixer + triage-analyst + state schema + resume-ticket integration)
  E. pipeline-history.md feedback loop (fixer + reviewer + post-publish-hook)
  F. ARCHITECTURE.md freshness warning (fix-ticket + implement-feature soft warning when docs/ARCHITECTURE.md older than N commits)

Key files for editing:
- docs/plans/roadmap.md (authoritative scope, lines 744-817)
- .claude-plugin/plugin.json, .claude-plugin/marketplace.json (license + repo URL)
- repo root: LICENSE, SECURITY.md, CODE_OF_CONDUCT.md (new files)
- .github/ISSUE_TEMPLATE/, .github/PULL_REQUEST_TEMPLATE.md (new), .gitea/issue_template/, .gitea/pull_request_template.md (new)
- skills/fix-ticket/SKILL.md, skills/fix-bugs/SKILL.md, skills/implement-feature/SKILL.md (~20 webhook curl examples)
- tests/scenarios/v681-harness-exit-propagation.sh (trap cleanup)
- core/block-handler.md (AC-ITEM-3.2 false-positive scope)
- core/post-publish-hook.md (webhook events; circuit breaker context; outcome:failed path)
- skills/autopilot/SKILL.md (multi-host lock; Jira dotted-project keys regex extension)
- skills/metrics/SKILL.md (--format json)
- agents/fixer.md, agents/triage-analyst.md (NEEDS_CLARIFICATION state)
- skills/resume-ticket/SKILL.md (NEEDS_CLARIFICATION resume integration)
- state/schema.md (NEEDS_CLARIFICATION state field)
- examples/configs/*.md (8 templates - touch up if any new optional sections added)
- agents/reviewer.md (pipeline-history reading), core/post-publish-hook.md (pipeline-history append)
- skills/fix-ticket/SKILL.md, skills/implement-feature/SKILL.md (ARCHITECTURE.md freshness check)
- CHANGELOG.md (v6.9.0 entry)
- CLAUDE.md, README.md, docs/reference/* (count drift if agents/skills/sections added)
