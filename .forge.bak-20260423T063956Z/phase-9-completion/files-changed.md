# Files Changed in v6.9.0

## OSS Readiness — New files at repo root

- `LICENSE` (MIT, ~21 lines) — NEW
- `SECURITY.md` — NEW
- `CODE_OF_CONDUCT.md` — NEW

## Issue and PR templates — New files

- `.gitea/issue_template/bug_report.md` — NEW
- `.gitea/issue_template/feature_request.md` — NEW
- `.gitea/pull_request_template.md` — NEW
- `.github/ISSUE_TEMPLATE/bug_report.md` — NEW (byte-identical mirror of Gitea)
- `.github/ISSUE_TEMPLATE/feature_request.md` — NEW (byte-identical mirror of Gitea)
- `.github/PULL_REQUEST_TEMPLATE.md` — NEW (byte-identical mirror of Gitea)

## Core contracts

- `core/agent-states.md` — NEW (16th core contract; NEEDS_CLARIFICATION pause state spec)
- `core/snippets/webhook-curl.md` — NEW (21 sites)
- `core/snippets/issue-id-validation.md` — NEW (4 sites)
- `core/snippets/metrics-json-schema.md` — NEW (1 site)
- `core/snippets/pipeline-completion.md` — NEW (3 sites)
- `core/snippets/architecture-freshness.md` — NEW (2 sites)
- `core/snippets/README.md` — NEW (rollback contract + citation count table)
- `core/post-publish-hook.md` — MODIFIED (Section 4.2 circuit breaker; Section 5 pipeline-history; line ~85 footnote; pipeline-paused webhook event; T-17f NEEDS_CLARIFICATION; cycle-1 fixes for awk truncation + webhook wiring)
- `core/block-handler.md` — MODIFIED (jq -nc compact form; counter-example HTML comment wrap; Block Comment Template Detail bound to 100 chars + sanitized)

## Skills — Modified

- `skills/fix-ticket/SKILL.md` — MODIFIED (--proto curl; issue_id regex; NEEDS_CLARIFICATION dispatch; outcome:failed Step Z; architecture freshness; snippet markers: 5)
- `skills/fix-bugs/SKILL.md` — MODIFIED (--proto curl at 13 sites; issue_id regex; NEEDS_CLARIFICATION dispatch; outcome:failed Step Z; snippet markers: 15)
- `skills/implement-feature/SKILL.md` — MODIFIED (--proto curl; issue_id regex; NEEDS_CLARIFICATION dispatch; outcome:failed Step Z; architecture freshness; snippet markers: 6)
- `skills/scaffold/SKILL.md` — MODIFIED (NEEDS_CLARIFICATION dispatch detection)
- `skills/analyze-bug/SKILL.md` — MODIFIED (NEEDS_CLARIFICATION interactive-only special case)
- `skills/resume-ticket/SKILL.md` — MODIFIED (--clarification flag; Priority 0 paused detection; EXTERNAL INPUT wrap; negative pipeline-completed invariant; cycle-1: forbid clarifications_consumed increment)
- `skills/autopilot/SKILL.md` — MODIFIED (pause detection; parse_pause_timeout; multi-host defer note; Pause Limits section)
- `skills/metrics/SKILL.md` — MODIFIED (--format json flag; schema documented; block.detail exclusion; snippet marker: 1)
- `skills/onboard/SKILL.md` — MODIFIED (internal hostname leak removal)

## Agents — Modified (additive only)

- `agents/fixer.md` — MODIFIED (NEEDS_CLARIFICATION fenced-block contract; EXTERNAL INPUT Constraint; pipeline-history read Step 1; cycle-1: asked_at write; case-insensitive grep; fixer_reviewer.iterations path)
- `agents/triage-analyst.md` — MODIFIED (NEEDS_CLARIFICATION fenced-block contract; EXTERNAL INPUT Constraint; cycle-1 same fixes)
- `agents/reviewer.md` — MODIFIED (pipeline-history read Step 1 — last 10 entries; EXTERNAL INPUT marker; sanitize_block_reason read-side note)

## State and plugin metadata

- `state/schema.md` — MODIFIED (clarification object; paused enum; awaiting_clarification step status; aborted_by_system; block.detail HARD CONTRACT; cycle-1: asked_at field; clarifications_consumed increment-owner doc; 17-pattern count fixed in Phase 9 doc-audit)
- `.claude-plugin/plugin.json` — MODIFIED (license: MIT; repository: example.invalid placeholder; version: 6.9.0)
- `.claude-plugin/marketplace.json` — MODIFIED (license: MIT added; version: 6.9.0)

## Documentation

- `CLAUDE.md` — MODIFIED (Cross-File Invariants subsection with 3 invariants; Pause Limits row; 15→16 core contracts; 18→19 optional sections; Webhook Payloads DoS operator note; autopilot guide updated)
- `README.md` — MODIFIED (28→29 skills at 2 sites; LICENSE link; SECURITY.md link)
- `CONTRIBUTING.md` — MODIFIED (CODE_OF_CONDUCT.md link replacing 4 CoC bullets; SECURITY.md pointer)
- `docs/architecture.md` — MODIFIED (28→29 skills; 16 core contracts; NEEDS_CLARIFICATION node; pipeline-history feedback arrow; circuit-breaker label; snippets sub-cluster; staleness counter reset)
- `docs/reference/skills.md` — MODIFIED (--format json documented; pipeline-history doc pointer; 17-pattern count fixed in Phase 9 doc-audit)
- `docs/reference/automation-config.md` — MODIFIED (19 optional sections count)
- `docs/guides/installation.md` — MODIFIED (internal hostname removal; .gitignore guidance for pipeline-history.md; 17-pattern count fixed in Phase 9 doc-audit)
- `docs/guides/autopilot.md` — MODIFIED (Multi-Host Coordination subsection; Webhook Reliability subsection; Paused Issues subsection)
- `docs/plans/roadmap.md` — MODIFIED (v6.9.0 PLANNED→SHIPPED; v6.9.1 deferral entries; 17-pattern count fixed in Phase 9 doc-audit)
- `CHANGELOG.md` — MODIFIED (v6.9.0 entry with all sections: Added/Changed/Migration notes/Known Issues/Internal)

## Tests — New and modified

- `tests/scenarios/v6.9.0-*.sh` — 41 NEW visible test scenarios
- `.forge/phase-5-tdd/tests-hidden/h-*.sh` — 8 NEW hidden test scenarios
- `tests/scenarios/v6.9.0-needs-clarification-e2e.sh` — NEW (cycle-1 functional e2e, covers all 8 cycle-1 bugs)
- `tests/scenarios/v681-harness-exit-propagation.sh` — MODIFIED (trap cleanup for SIGTERM/Ctrl-C)
- `tests/scenarios/prompt-injection-protection.sh` — MODIFIED (15→16 count; shopt guards; find -maxdepth 1)
- `.forge/phase-5-tdd/tests-hidden/h-block-handler-heredoc.sh` — MODIFIED (REPO_ROOT path: ../../ → ../../../)

## Forge artifacts (committed per project convention)

- `.forge/phase-0-meta/` through `.forge/phase-9-completion/` — all phase artifacts
- `.forge/forge.json` — pipeline state
- `.forge/forge.log` — execution log

## Summary counts

- NEW files: ~25 (3 OSS root + 6 templates + 7 core/snippets + 1 core/agent-states + ~8 hidden tests)
- MODIFIED files: ~35 (9 skills + 3 agents + 2 plugin metadata + 2 state/schema + 10 docs + 3 test scenarios)
- Total visible: ~60 files changed + ~50 .forge/ artifacts
- Test harness: 141 (baseline) → 183 (+42: 41 visible + 1 e2e from cycle-1)
