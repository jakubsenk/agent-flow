# Phase 0 Meta-Agent Analysis (Pipeline State Artifact)

This is a /forge orchestrator contract artifact, consumed at STEP 0.4. Not a human report.

Run ID: forge-2026-04-25-001
Generated: 2026-04-25
Repo: ceos-agents (Claude Code plugin, pure markdown)
Target version: v7.0.0 (cleanup release, BREAKING)

## 1. Task Type Classification

Primary: refactor
Secondary: migration, docs

Rationale:
- Touches existing structure (rename 2 skill dirs, delete 1 skill, delete 1 config section, rewrite 1 skill logic) = refactor.
- Ships breaking changes to public config contract (`Extra labels`) and public slash command names (`/status`, `/init`, `/create-pr`) = migration semantics; CHANGELOG migration guide in scope; cross-file invariants must hold.
- Substantial doc edits but NOT pure docs - skill code is rewritten and skill files deleted/renamed.

Final: refactor with migration emphasis on verification.

## 2. Complexity Assessment

| Axis | Score | Justification |
|---|---|---|
| Scope | 4 | ~6 skills, ~3 agents, ~5 docs, 8 config templates, tests, CLAUDE.md, README.md, workflow-router, core/* refs |
| Ambiguity | 2 | Spec lists exact files per action, exact rename pairs, full /publish auto-detect logic, pre-written migration guide |
| Risk | 4 | BREAKING change in public config + slash command names + skill set. Per CLAUDE.md = MAJOR. Cross-file invariants discipline required |

Composite (max): 4

Implications:
- Maximum agents on Phase 1-3, 7
- Default-to-upgraded models (opus on Phase 4 spec, Phase 6 plan, Phase 8 verify)
- 3 review rounds (default)
- JIT recommended (composite >= 3)
- Verification weights tilted toward correctness + spec_alignment, NOT security

## 3. Domain Identification

- Language/Runtime: none (markdown plugin)
- Framework: Claude Code plugin (skills + agents + core contracts)
- Domain: Developer-tooling / CI orchestration
- Specialty concerns: public API contract stability; doc-count consistency across 5 anchors; cross-file invariants (license SPDX, maintainer email, template parity); bash test harness POSIX-portable scripts in tests/scenarios/v7-*.sh

## 4. Codebase Context Assessment

Existing patterns:
- Skills: `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`, optional `disable-model-invocation`, `allowed-tools`, `argument-hint`).
- Renaming a skill = rename the directory `skills/<old>/` -> `skills/<new>/`, change `name:` in frontmatter, then grep + replace ALL references across repo.
- Agents: `agents/<name>.md` with frontmatter (`name`, `description`, `model`, `style`).
- Optional Automation Config sections in `docs/reference/automation-config.md` and CLAUDE.md.
- Tests: bash harness `tests/harness/run-tests.sh`, scenarios in `tests/scenarios/`, naming `v<MAJOR>.<MINOR>-<topic>.sh`.
- Each scenario: `#!/usr/bin/env bash; set -euo pipefail`, exit 0=PASS, non-0=FAIL, 77=SKIP.
- v6.10.0 converted 16 doc-grep tests to FUNCTIONAL; v7 visible scenarios MUST follow that discipline.
- Workflow-router intent table is in `skills/workflow-router/SKILL.md`.
- CHANGELOG follows Keep-a-Changelog format.

Cross-file invariants (CLAUDE.md "Cross-File Invariants"):
1. License SPDX `"MIT"` consistent across `plugin.json`, `marketplace.json`, `LICENSE` first heading.
2. Maintainer email `filip.sabacky@ceosdata.com` consistent across SECURITY.md, CODE_OF_CONDUCT.md, CONTRIBUTING.md.
3. Issue/PR templates byte-identical between `.gitea/` and `.github/`.

Anti-patterns from project memory (apply directly):
- **Doc completeness before commit** (feedback_doc_completeness.md): audit ALL 5 anchor files for stale counts (29 -> 28 skills, 19 -> 18 sections, 21 agents unchanged). Files: CLAUDE.md, README.md, docs/reference/automation-config.md, docs/reference/skills.md, docs/architecture.md.
- **Docs coverage in migrations** (feedback_docs_coverage.md): grep ENTIRE repo for old terms (`/ceos-agents:status`, `/ceos-agents:init`, `/create-pr`, `Extra labels`). No survivors in active files. Forge backups under `.forge.bak-*` are EXCLUDED.
- **Never blindly trust specs** (feedback_never_trust_spec.md): validate spec assumptions in Phase 1-2 (file paths, `examples/configs/` vs `examples/config-templates/`).
- **Negation logic when wrapping checks** (feedback_negation_logic_when_wrapping_checks.md): apply De Morgan dual when extending rejection logic.
- **Test discipline**: no doc-grep tests for v7. Visible scenarios MUST be functional (parse branch name, extract issue ID, assert correct dispatch path, etc.).

Test framework context (for tdd.md prompt):
- Harness: `tests/harness/run-tests.sh`
- Scenario directory: `tests/scenarios/`
- Naming for v7.0.0: `v7.0.0-<topic>.sh`
- Pattern: bash, `set -euo pipefail`, `cd "$(dirname "$0")/../.."`
- Helpers: `tests/lib/fixtures.sh` (`make_state_json`, `setup_scratch`, `require_jq`)
- Anti-pattern gate: `v6.10.0-no-awk-source-in-rewrites.sh` blocks `awk+source` code-lift in test additions

Relevant code (for fixer/planner):
- `skills/publish/SKILL.md` (will be rewritten - Steps 1-3: branch parsing, ID extraction, MCP tracker.getIssue() lookup, 3-way fork)
- `skills/create-pr/SKILL.md` (will be DELETED entirely)
- `skills/status/SKILL.md` -> `skills/pipeline-status/SKILL.md` (frontmatter `name: pipeline-status`)
- `skills/init/SKILL.md` -> `skills/setup-mcp/SKILL.md` (frontmatter `name: setup-mcp`)
- `skills/workflow-router/SKILL.md` (intent table - drop /create-pr row, rename /status, rename /init)
- `agents/publisher.md:69` (Extra labels reference - remove)
- `skills/fix-ticket/`, `skills/fix-bugs/`, `skills/implement-feature/` (Extra labels references; /create-pr references rewire)
- `examples/configs/*.md` (8 templates - strip Extra labels rows)
- `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` (refers to Extra labels - update or RETIRE via exit 77)

### Compressed CODEBASE_CONTEXT for downstream prompts

ceos-agents v6.10.0 is a Claude Code plugin (pure markdown, zero dependencies, bash test harness only). It defines 21 specialist agents (`agents/<name>.md`) orchestrated by 29 skills (`skills/<name>/SKILL.md` with YAML frontmatter). Each skill reads `## Automation Config` from a consuming project's CLAUDE.md (19 optional sections, 5 required) and dispatches agents via the Task tool. Tests are bash scripts in `tests/scenarios/` run by `tests/harness/run-tests.sh` (exit 0=PASS, 77=SKIP). v6.10.0 enforced functional-test discipline (no doc-grep tests). Cross-file invariants documented in CLAUDE.md "Cross-File Invariants" (license SPDX, maintainer email, template parity .gitea<->.github). Renaming a skill = rename `skills/<old>/` -> `skills/<new>/` + change `name:` frontmatter + grep-replace ALL references across CLAUDE.md, README.md, docs/, skills/, agents/, examples/, tests/. Doc count fields (29 skills, 19 optional config sections) appear in CLAUDE.md, README.md, docs/reference/automation-config.md, docs/reference/skills.md, docs/architecture.md and MUST be kept consistent. v7.0.0 = cleanup release: delete `Extra labels` config section, fix `Pause Limits` doc mapping (applies to 6 skills not just /autopilot), rename `/ceos-agents:status` -> `/ceos-agents:pipeline-status` (Claude Code builtin collision), rename `/ceos-agents:init` -> `/ceos-agents:setup-mcp` (collision), rewrite `/publish` to auto-detect tracker (issue ID found -> full publish; not found -> PR-only + WARN; tracker down -> FAIL with guidance), delete `/create-pr` skill (replaced by auto-detect), add README+installation.md warnings about builtin collisions. Counts: 29 -> 28 skills, 19 -> 18 config sections, 21 agents unchanged. NOT in scope: version bump (user runs `/version-bump` manually after pipeline). IN scope: CHANGELOG entry with migration guide.

## Confidence Scoring (Devin Pattern)

| Question | Score | Rationale |
|---|---|---|
| Q1 well-defined? | 0.92 | Spec lists every action, every affected file group, exact rename targets, full /publish auto-detect logic, pre-written migration guide. Minor open decisions cosmetic. |
| Q2 context supports? | 0.93 | Codebase well-mapped; recent v6.10.0 work demonstrated similar cross-cutting edits + functional test discipline. |
| Q3 within capabilities? | 0.95 | Pure markdown plugin edits, no novel infra, no new runtime, no new languages. Forge has shipped multiple ceos-agents releases. |

Composite (min): 0.92
Threshold: 0.7 (default `meta_agent.confidence_threshold`)
Verdict: 0.92 >= 0.9 -> proceed immediately, no clarification needed.

## Fast-Track Eligibility Assessment

### Tier A - Deterministic keyword/regex scan (FLOOR)

Raw input scanned: the user task verbatim from input.md (Czech with English scope summary).

| Cat | Match | Verdict |
|---|---|---|
| 1 destructive ops | none (no `rm -rf`, no SQL DROP). `smazat` (Czech "delete") refers to one config section + one skill directory | no match |
| 2 credentials | none | no match |
| 3 irreversible side-effects | substring "release" appears as noun ("v7.0.0 cleanup release"), NOT verb against external registry; user explicitly EXCLUDES the version bump (the registry-touching step). Tier-A pattern "publish release" is supply-chain - context contradicts | LITERAL MATCH on "release" substring; defense-in-depth escalation to Tier B |
| 4 elevated privileges | none | no match |
| 5 ambiguous scope | none (6 enumerated actions, exact files in spec) | no match |
| 6 network irreversibility | none | no match |
| 7 supply-chain ops | none (no npm/docker/cargo publish) | no match |
| 8 billing/quota | none | no match |
| 9 system-service | none | no match |

Interpretation: literal "release" matches but pattern targets supply-chain publication. User STOPS BEFORE version bump. Defense-in-depth: not auto-blocking on substring match when context contradicts. Note: composite complexity = 4 means fast-track is INELIGIBLE on the complexity precondition alone, regardless of Tier A/B verdict. Fast-track is OFF.

### Tier B - security_evaluation

```json
{
  "security_evaluation": {
    "destructive_ops":          { "result": "pass", "evidence": "Deletes 1 markdown skill directory (skills/create-pr/) and 1 doc config section heading. No data loss, no DB ops, no rm -rf. Reversible via git." },
    "credential_handling":      { "result": "pass", "evidence": "No credentials, secrets, tokens, or API keys read/written/transmitted. Pure markdown editing." },
    "irreversible_side_effects":{ "result": "pass", "evidence": "Version bump is OUT-OF-SCOPE (user runs /version-bump manually). No PR push, no registry publish, no email/notification, no webhook trigger inside this pipeline." },
    "elevated_privileges":      { "result": "pass", "evidence": "No sudo, no chmod with octal mode, no chown. File edits within the working directory only." },
    "ambiguous_scope":          { "result": "pass", "evidence": "Scope bounded: 6 enumerated actions, exact files listed in spec table, target version v7.0.0 explicit. No all-files or everything phrasing." },
    "network_irreversibility":  { "result": "pass", "evidence": "No DNS, CDN, firewall, load balancer, or webhook-registration changes. Webhook config keys stay as-is in schema." },
    "supply_chain_ops":         { "result": "pass", "evidence": "No npm/pip/docker/cargo/gem/nuget publish operations. Plugin is markdown-only and not distributed via any package registry." },
    "billing_quota_ops":        { "result": "pass", "evidence": "No cloud provisioning, no quota change, no subscription modification. Pure markdown file edits." },
    "system_service_effects":   { "result": "pass", "evidence": "No systemctl/launchd/Windows-Services interaction, no cron, no firewall, no docker daemon, no iptables." }
  }
}
```

### Fast-Track Decision

NOT activated. Reason: composite complexity = 4 (>= 3). Eligibility precondition `composite <= 2` failed. Fall through to FULL pipeline.

## Template Selection

`routing.auto_select_template = false` per merged config. Skip per protocol.

```json
{
  "template_selection": {
    "selected": null,
    "confidence": 1.0,
    "rationale": "routing.auto_select_template is false; skip per protocol. The 'refactoring' template would be the closest match by domain but selection is gated."
  }
}
```

## Pipeline Configuration Decisions

| Decision | Value | Source | Rationale |
|---|---|---|---|
| Phase skipping | none (run all 0-9) | meta-agent | refactor + composite=4 + risk=4 -> full pipeline |
| Agent count | default-to-max | meta-agent | composite=4 |
| Model tier | default with opus on Phase 4/6/8 | meta-agent | composite=4 + breaking-change discipline |
| Review rounds | 3 (default) | default | composite=4 borderline; 3 sufficient given high spec clarity |
| Approval gates | [3, 4, 6] | default | brainstorm + spec + plan checkpoints |
| JIT | enabled | meta-agent | composite >= 3 |
| Replanning enabled | true | default | safe default |
| Replanning max_cycles | 1 | default | low ambiguity (=2) does not justify increasing |
| Replanning divergence_threshold | 0.3 | default | risk=4 borderline; tighter threshold optional but not required |
| Verification weights | corr 0.35, spec 0.30, robust 0.20, sec 0.15 | meta-agent | refactor + breaking-change + cross-file invariants -> correctness + spec_alignment dominate. NO security-sensitive ops. Lowering security from default 0.30 to 0.15 |
| oracle.enabled | true (default) | default | unchanged |
| tdd.mutation_threshold | 70 (default) | default | functional-test discipline already enforced via anti-pattern gate |
| review.triage_enabled | false (default) | default | composite=4 not high enough to add another gate |

## Routing Decision Summary

- task_type: `refactor`
- secondary_types: `["migration", "docs"]`
- action: `full_pipeline`
- target_skill: `null`
- skip_profile: `null`
- confidence: 0.92
- reasoning: Refactor with breaking-change risk and migration emphasis. Full pipeline 0-9. Spec is detailed enough for high-confidence execution. Secondary docs+migration signals do NOT warrant phase subset because real implementation work (skill rewrite, file deletion, frontmatter changes) is required.

(Standalone JSON written to `routing-decision.json`.)

## Anti-Patterns to Inject Into Phase Prompts

1. **Doc count drift** - failing to update all 5 anchor files (CLAUDE.md, README.md, docs/reference/automation-config.md, docs/reference/skills.md, docs/architecture.md) when changing a count.
2. **Stale references** - leaving `/ceos-agents:status`, `/ceos-agents:init`, `/create-pr`, `Extra labels` in any active file (excluding `.forge.bak-*` historical archives).
3. **Doc-grep tests** - adding test scenarios that only `grep` for documentation strings instead of exercising real behavior. v7 visible scenarios MUST invoke parsing/dispatch logic.
4. **Cross-file invariant violation** - accidentally changing license SPDX, maintainer email, or breaking template parity between `.gitea/` and `.github/`.
5. **Out-of-scope version bump** - modifying `plugin.json`, `marketplace.json`, or creating a `v7.0.0` git tag inside the pipeline. The user runs `/version-bump` manually AFTER the pipeline completes.
6. **Negation logic when wrapping checks** - when extending a rejection check, apply De Morgan dual.
7. **Workflow-router intent table forgotten** - `skills/workflow-router/SKILL.md` lists every skill with trigger phrases. It MUST be updated for renames + `/create-pr` deletion.
8. **Frontmatter `name:` field drift** - when renaming a skill directory, the frontmatter `name:` MUST also change (else slash command resolves to old name).
9. **Migration guide omitted** - CHANGELOG.md MUST contain the migration block (pre-written in the spec) so consumers can upgrade.
10. **Spec assumption blindly accepted** - Phase 1-2 must verify file paths actually exist (e.g., confirm `examples/configs/` vs `examples/config-templates/`).

## Required Phase Outputs

- Phase 1 (research questions): 5-8 questions targeting (a) full file-path enumeration, (b) `Pause Limits` exact mapping list, (c) `/publish` MCP tracker call signature per supported tracker, (d) workflow-router intent table format, (e) CHANGELOG section structure.
- Phase 2 (research answers): grounded answers with file:line citations.
- Phase 3 (brainstorm): 3 personas (conservative, innovative, skeptical) on `/publish` auto-detect implementation, especially the `tracker down` failure mode and migration UX.
- Phase 4 (spec): EARS requirements + acceptance criteria, machine-checkable. Cross-file invariant preservation as explicit ACs.
- Phase 5 (TDD): bash test scenarios in `tests/scenarios/v7.0.0-*.sh`, FUNCTIONAL only.
- Phase 6 (plan): dependency graph; renames are independent of `/publish` rewrite; `Extra labels` deletion is independent.
- Phase 7 (execution): subagent-driven, parallelizable for independent file groups.
- Phase 8 (verification): adversarial; assert cross-file invariants + count consistency + no stale references + functional test pass.
- Phase 9 (completion): final report; explicitly NOTE that version bump is deferred to user.

End of analysis.md.
