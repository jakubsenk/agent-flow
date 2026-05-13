# Phase 7 Files Changed — v7.0.0

Derived from `git diff --name-status main` (authoritative) + Phase 6 plan task scopes.
Only non-`.forge/` files listed (forge artifacts are a separate category).

---

## Deleted

| File | Reason |
|---|---|
| `skills/create-pr/SKILL.md` | REQ-DEL-CREATE-PR — skill removed entirely (T-01) |

---

## Renamed (git mv)

| Old path | New path | Reason |
|---|---|---|
| `skills/status/SKILL.md` | `skills/pipeline-status/SKILL.md` | REQ-RENAME-STATUS (T-02) |
| `skills/init/SKILL.md` | `skills/setup-mcp/SKILL.md` | REQ-RENAME-INIT (T-03) |

---

## New Test Scenarios (18 v7.0.0-*.sh files)

All created in `tests/scenarios/`:

- `v7.0.0-changelog-migration-guide.sh`
- `v7.0.0-cross-file-invariants.sh`
- `v7.0.0-doc-count-18-config-sections.sh`
- `v7.0.0-doc-count-28-skills.sh`
- `v7.0.0-empty-skills-dir-invariant.sh`
- `v7.0.0-no-create-pr-skill.sh`
- `v7.0.0-no-extra-labels-section.sh`
- `v7.0.0-no-version-bump.sh`
- `v7.0.0-pause-limits-mapping.sh`
- `v7.0.0-publish-auto-detect-issue-404.sh`
- `v7.0.0-publish-auto-detect-issue-found.sh`
- `v7.0.0-publish-auto-detect-tracker-down.sh`
- `v7.0.0-publish-extraction-regex.sh`
- `v7.0.0-publish-no-issue-id-pr-only.sh`
- `v7.0.0-readme-collision-warning.sh`
- `v7.0.0-skill-rename-init.sh`
- `v7.0.0-skill-rename-status.sh`
- `v7.0.0-workflow-router-intent-table.sh`

---

## Modified — Documentation

| File | Change summary |
|---|---|
| `CLAUDE.md` | Skills count 29→28, optional sections 19→18, skills enumeration updated (remove `/create-pr`, rename `/status`→`/pipeline-status`, `/init`→`/setup-mcp`) |
| `README.md` | Skill table rows updated; skill count 29→28; optional sections 19→18; new `### Slash command collision` subsection |
| `CHANGELOG.md` | Added `## [7.0.0]` section with BREAKING CHANGES + migration guide (5 bullets, skill-not-found disclosure, state.json forward-compat note, counts table) |
| `docs/architecture.md` | `SKL[29 Skills]` → `SKL[28 Skills]` |
| `docs/getting-started.md` | Skill count 29→28; `/ceos-agents:init` → `/ceos-agents:setup-mcp` references |
| `docs/guides/installation.md` | New `### Slash command collision` subsection; `/ceos-agents:init` → `/ceos-agents:setup-mcp` |
| `docs/guides/mcp-configuration.md` | `/ceos-agents:init` → `/ceos-agents:setup-mcp` references |
| `docs/guides/troubleshooting.md` | `/ceos-agents:status` → `/ceos-agents:pipeline-status`; `/ceos-agents:init` → `/ceos-agents:setup-mcp` |
| `docs/reference/automation-config.md` | `Extra labels` section removed; `Pause Limits` Used-By column updated to list all 6 participants; `/create-pr` removed from PR Rules + PR Description Template Used-By; optional sections count 19→18 |
| `docs/reference/skills.md` | `/create-pr` section deleted (~20 lines); `/status` → `/pipeline-status` throughout; `/init` → `/setup-mcp` throughout; skill count 29→28 (2 occurrences) |
| `docs/plans/roadmap.md` | v7.0.1 follow-up bin added (INFO/LOW/ADVISORY findings from Phase 8) |

---

## Modified — Core Contracts

| File | Change summary |
|---|---|
| `core/config-reader.md` | `Extra labels` parse rule deleted; `/ceos-agents:init` → `/ceos-agents:setup-mcp` reference |
| `core/mcp-preflight.md` | `/ceos-agents:init` → `/ceos-agents:setup-mcp` reference |

---

## Modified — Skills

| File | Change summary |
|---|---|
| `skills/publish/SKILL.md` | Full rewrite — Step 0 (branch parse + issue-ID extraction), tracker auto-detect, 5-bucket error classification, 3-mode fork (full-publish / pr-only-404 / pr-only-no-id), FAIL tier block message, interactive-only note |
| `skills/pipeline-status/SKILL.md` | Frontmatter `name: pipeline-status`; self-references updated; `/ceos-agents:init` → `/ceos-agents:setup-mcp` |
| `skills/setup-mcp/SKILL.md` | Frontmatter `name: setup-mcp`; 5 self-references `/ceos-agents:init` → `/ceos-agents:setup-mcp` |
| `skills/workflow-router/SKILL.md` | Intent table: `create-pr` row deleted, `status` → `pipeline-status`, `init` → `setup-mcp`; Step 3/4 prose updated; new "Deprecated names" ("Did you mean...?") subsection |
| `skills/check-setup/SKILL.md` | `Extra labels` removed from optional-section enumeration; added deprecated-section detector for stale `Extra labels` heading; `/ceos-agents:init` → `/ceos-agents:setup-mcp` |
| `skills/onboard/SKILL.md` | `Extra labels` menu item [12] removed; config summary updated; `/ceos-agents:init` → `/ceos-agents:setup-mcp` |
| `skills/migrate-config/SKILL.md` | `Extra labels` removed from migration loop enumeration |
| `skills/scaffold/SKILL.md` | 11 occurrences `/ceos-agents:init` → `/ceos-agents:setup-mcp` |
| `skills/implement-feature/SKILL.md` | `Extra labels` config-read bullet removed; `/ceos-agents:init` → `/ceos-agents:setup-mcp` |
| `skills/fix-ticket/SKILL.md` | `Extra labels` config-read bullet + publisher context segment removed |
| `skills/fix-bugs/SKILL.md` | `Extra labels` config-read bullet + publisher context segment removed |
| `skills/create-backlog/SKILL.md` | `/ceos-agents:init` → `/ceos-agents:setup-mcp` |

---

## Modified — Agents

| File | Change summary |
|---|---|
| `agents/publisher.md` | `Extra labels` prompt fragment removed; "Add labels from PR Rules section only." |

---

## Modified — Tests (existing scenarios updated)

| File | Change summary |
|---|---|
| `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` | `Extra labels` removed from array; mutation guard updated |
| `tests/scenarios/config-reader-sections.sh` | `Extra labels` array element removed |
| `tests/scenarios/regression-skill-count-29.sh` | Updated assertion to 28 |
| `tests/scenarios/ac-v68-doc-skill-count-29.sh` | Updated assertion to 28 |
| `tests/scenarios/v6.9.0-doc-count-drift.sh` | Updated skills count assertions to 28 |
| `tests/scenarios/sprint-counts.sh` | `skills_fs` and `skills_claimed` assertions updated to 28 |
| `tests/scenarios/v6.9.0-arch-freshness-refresh-on-release.sh` | `SKL[29]` → `SKL[28]` assertion |
| `tests/scenarios/no-mcp-jargon-errors.sh` | `skills/create-pr/SKILL.md` removed from STANDARD_ERROR_FILES; `skills/status/SKILL.md` → `skills/pipeline-status/SKILL.md` |
| `tests/scenarios/scaffold-mcp-checkpoint.sh` | `/ceos-agents:init` → `/ceos-agents:setup-mcp` |
| `tests/scenarios/v6.10.0-dispatch-hook-install-surface.sh` | `/ceos-agents:init` → `/ceos-agents:setup-mcp` |
| `tests/scenarios/v644-diagnostics-hardening.sh` | 6 occurrences `/ceos-agents:init` → `/ceos-agents:setup-mcp` |
| `tests/scenarios/skills-directory-structure.sh` | `create-pr` removed, `status` → `pipeline-status`, `init` → `setup-mcp` from EXPECTED_SKILLS |
| `tests/scenarios/skills-frontmatter-check.sh` | `create-pr` removed from PIPELINE_SKILLS; FC-5 count comment 12→11; `status` → `pipeline-status`, `init` → `setup-mcp` from READONLY_SKILLS |

---

## Retired Tests (exit 77)

| File | Reason |
|---|---|
| `tests/scenarios/v6.10.0-autopilot-audit-disclosure.sh` | Checks for v6.10.0 forge artifact (`.forge/phase-4-spec/research/autopilot-hook-interaction.md`) not present in v7.0.0 forge; T-21 fix-up |
| `tests/scenarios/v6.10.0-layers-3-5-deferred-disclosure.sh` | Checks for v6.10.0 "Layer 3/5" terminology not used in v7.0.0 spec; T-21 fix-up |

---

## Modified — Config Examples

| File | Change summary |
|---|---|
| `examples/configs/github-nextjs.md` | `Extra labels` section body removed |
| `examples/configs/redmine-oracle-plsql.md` | `Extra labels` section body removed |

**Not modified** (6 remaining templates had no `Extra labels` section): `github-python-fastapi.md`, `github-dotnet.md`, `gitea-spring-boot.md`, `jira-react.md`, `youtrack-python.md`, `redmine-rails.md`

---

## NOT Modified (per REQ-NO-VERSION-BUMP)

- `.claude-plugin/plugin.json` — `"version"` field unchanged
- `.claude-plugin/marketplace.json` — `"version"` field unchanged
- No `v7.0.0` git tag created
