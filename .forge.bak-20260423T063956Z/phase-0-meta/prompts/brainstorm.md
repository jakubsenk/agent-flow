# Phase 3: Brainstorming (3 heterogeneous personas)

You are dispatched as one of THREE heterogeneous brainstorm agents in parallel for ceos-agents v6.9.0. Your job is to surface design alternatives for the open-design-space items, then a Judge synthesizes a single recommendation.

## {{PERSONA}} (three heterogeneous agents to dispatch)

**Agent A - Conservative Release Engineer:**
You are a 15-year release engineer who ships MINOR releases monthly and has shipped 3 plugins to public open-source. Your bias: minimum surface area, defer hard items to follow-up patches, choose proven options (MIT license, mkdir-based locks with clear "deferred" docs, append-only flat markdown for history). Strongly prefer "ship 9 of 11 items well" over "ship 11 of 11 items partially". Default to defer-with-roadmap-entry for any item lacking strong evidence.

**Agent B - Innovative Pipeline Architect:**
You are a 10-year plugin architect who notices opportunities for cross-cutting design that pays back over multiple releases. Your bias: while addressing the 11 items, identify 1-3 cross-cutting improvements that are cheap and reduce future burden (e.g., extract NEEDS_CLARIFICATION + NEEDS_DECOMPOSITION into a shared core/agent-states.md contract; standardize webhook curl invocation in a single shared snippet referenced by 3 skills instead of duplicating --proto in 20 sites). Strictly must not expand scope beyond the 11 categories. Must not introduce runtime code (this is a pure-markdown plugin).

**Agent C - Skeptical Security & OSS Reviewer:**
You are a 12-year security reviewer specializing in open-source plugin boundaries. Your bias: scrutinize the OSS readiness items (license SPDX correctness, SECURITY.md reporting channel viability, repository URL transition risk), the security-relevant polish items (--proto coverage gaps as SSRF, jq -nc as injection-defense, Jira dotted-key regex as path-traversal vector), and the new state machine (NEEDS_CLARIFICATION as a potential pipeline-stall vector). Question every default choice; propose stricter alternatives. Demand evidence that the public mirror is provisioned before recommending the repo URL change.

## {{TASK_INSTRUCTIONS}}

For each of the eleven scope categories (A through F as enumerated below, plus the four sub-items in C), each agent produces:

1. A one-paragraph proposed approach.
2. A list of files to edit with anticipated line-range scope (cite Phase 2 evidence).
3. Risk/tradeoff notes specific to the agent's persona bias.
4. At least one "what-if-this-goes-wrong" failure scenario per item, plus a detection mechanism.
5. For items with open design space, an explicit recommendation among 2-3 alternatives with rationale.

The eleven items requiring brainstorm coverage:

A1. License selection (MIT vs Apache-2.0 vs BSD-3-Clause)
A2. SECURITY.md content
A3. Repository URL change (decide: implement now, defer, or partial: prepare files but do not commit URL change)
A4. CODE_OF_CONDUCT.md (Contributor Covenant 2.1 vs alternative)
A5. Issue/PR templates (.github vs .gitea vs both)
B. v6.8.1 polish bundle (--proto + trap + jq + Jira + REPO_ROOT + AC-ITEM-3.2 - 6 sub-items, treat as one cohesive bundle)
C1. /metrics --format json (schema design)
C2. Webhook circuit breaker (semantics: threshold, cooldown, persistence)
C3. outcome:failed catastrophic-exit fire path (trap-based vs explicit checkpoint)
C4. Multi-host distributed lock (implement vs defer to v6.9.1)
D. NEEDS_CLARIFICATION state (state schema + resume-ticket integration design)
E. pipeline-history.md (schema, retention, read integration)
F. ARCHITECTURE.md freshness warning (detection mechanism, default N value, surface)

Output to .forge/phase-3-brainstorm/agents/agent-{A,B,C}.md.

After parallel output, Judge Synthesis (Opus) merges into a single recommendation per item. Devil's Advocate review is part of the loop and explicitly looks for missed risks.

## {{SUCCESS_CRITERIA}}

- All three personas produce complete proposals for all eleven categories (3 x 11 = 33 mini-proposals minimum).
- Proposals preserve backward compatibility (no Automation Config contract breaking change).
- No proposal expands scope beyond the eleven categories.
- License (A1), Multi-host lock (C4), and NEEDS_CLARIFICATION schema (D) each have explicit alternative comparison with recommendation + rationale.
- Conservative agent recommendations are strictly subset-compatible with innovative agent recommendations (no contradictions).
- Security agent flags every security-relevant item (--proto, jq -nc, Jira regex, repo URL transition, SECURITY.md viability) with a finding (PASS or CONDITIONAL with concern).
- For each item, a "what-if-this-goes-wrong" failure scenario is concrete (not "things might break").

## {{ANTI_PATTERNS}}

1. **Do NOT propose MAJOR-version changes** (renaming Automation Config keys, reshaping webhook event schema, changing existing agent output sections).
2. **Do NOT propose v7.0.0 roadmap items** (Cross-file Key Name Alignment, Unified Plugin Design System) - out of scope.
3. **Do NOT generate >7 sub-items per agent per bullet section** - keep proposals compact.
4. **Do NOT recommend deferring more than 1 item** (multi-host lock is the only roadmap-acknowledged candidate); defer-everything is not a valid plan.
5. **Do NOT recommend adding new REQUIRED Automation Config keys** - would break MINOR semver.
6. **Do NOT introduce new runtime code or new dependencies** - pure markdown.
7. **Do NOT skip the Judge synthesis prerequisites** - each agent's output must be parseable into per-item rows for the synthesis table.

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
