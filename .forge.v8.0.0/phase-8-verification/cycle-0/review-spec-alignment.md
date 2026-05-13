# Phase 8 — Spec Alignment Review (cycle 0)

**Pipeline:** v7.0.0 — Cleanup + naming + auto-detect publish (BREAKING)
**Reviewer:** Spec Alignment Reviewer (Opus)
**Date:** 2026-04-25
**Working dir:** `C:/gitea_ceos-agents`
**Scope verified:** 6 release actions, 11 REQs, 94 ACs (15 sampled + 8 supplementary)

---

## Summary

**Score: 0.95 / 1.0 — PASS**

- All 11 REQs traced to implementation evidence — **11/11**.
- AC sample of 23 (covering all 11 REQs) verified — **23/23 PASS**.
- All 18 v7.0.0 test scenarios in `tests/scenarios/v7.0.0-*.sh` execute with exit 0.
- All 6 spec actions present, no scope creep, no scope cuts.
- All 7 critical design decisions encoded correctly.
- 3 cross-file invariants (License SPDX, maintainer email, template parity) all hold.
- REQ-NO-VERSION-BUMP confirmed: `git diff main` shows zero `"version"` field changes; no `v7.0.0` tag exists.

**Findings: 1 advisory (text-AC vs scenario-AC scoping divergence; non-blocking).**

---

## REQ Traceability Table (11/11)

| REQ ID | EARS text (truncated) | Implementation evidence | Verdict |
|---|---|---|---|
| REQ-DEL-EXTRA-LABELS | `Extra labels` config section deleted from active surfaces | `core/config-reader.md` no `pr_rules.extra_labels`; `agents/publisher.md` no Extra labels mention; `examples/configs/github-nextjs.md` + `redmine-oracle-plsql.md` section bodies removed; `tests/scenarios/config-reader-sections.sh` + `v6.9.0-bc-no-renamed-section.sh` arrays updated; mutation guard 18; deprecated detector preserved in `skills/check-setup/SKILL.md:201-205` | PASS |
| REQ-PAUSE-LIMITS-DOC | `Pause Limits` Used-By column lists 6 lifecycle participants | `docs/reference/automation-config.md:40` row `\| Pause Limits \| No \| /fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot, /resume-ticket \|` matches verbatim; old `/autopilot`-only row removed | PASS |
| REQ-RENAME-STATUS | `skills/status/` deleted; `skills/pipeline-status/` exists with `name: pipeline-status` | `skills/pipeline-status/SKILL.md` exists with frontmatter `name: pipeline-status`; `skills/status/` does not exist; workflow-router intent table + Step 3 prose updated; README + docs/reference/skills.md + CLAUDE.md updated; deprecated identifier preserved ONLY in workflow-router "Did you mean...?" prose at line 76 | PASS |
| REQ-RENAME-INIT | `skills/init/` deleted; `skills/setup-mcp/` exists with `name: setup-mcp` | `skills/setup-mcp/SKILL.md` exists with frontmatter `name: setup-mcp`; `skills/init/` does not exist; `core/config-reader.md` + `core/mcp-preflight.md` reference setup-mcp; deprecated identifier preserved ONLY in workflow-router "Did you mean...?" prose at line 77 | PASS |
| REQ-PUBLISH-AUTO-DETECT | `/publish` rewrite with branch parse + tracker auto-detect | `skills/publish/SKILL.md`: Step 0 branch parse; canonical regex literal `^(#?[0-9]+\|[A-Za-z][A-Za-z0-9_]*-[0-9]+)` at line 79 + bash form at line 90; 5 error_type buckets `tls`/`auth`/`not_found`/`timeout`/`unknown` enumerated; `unknown → FAIL` defensive default present; 3 modes (`full-publish`, `pr-only-no-id`, `pr-only-404`) documented; FAIL tier uses `[ceos-agents] 🔴 Pipeline Block` format with `Skill: /ceos-agents:publish`; SC-7 404 WARN single-line, SC-8 no-id INFO single-line, SC-10 missing config INFO single-line, SC-12 detached HEAD FAIL guard all present | PASS |
| REQ-DEL-CREATE-PR | `skills/create-pr/` deleted | Directory does not exist; README skill table row removed; `docs/reference/skills.md` `### /create-pr` section + Related skills entry removed; PR Rules + PR Description Template Used-By columns updated; `workflow-router` intent table row deleted; `tests/scenarios/no-mcp-jargon-errors.sh` + `skills-directory-structure.sh` + `skills-frontmatter-check.sh` arrays updated; deprecated identifier preserved ONLY in workflow-router "Did you mean...?" prose at line 78 | PASS |
| REQ-DOCS-COLLISION-WARN | README + installation guide collision warning subsections | `README.md` "Renames and removals (v6.10.x → v7.0.0)" subsection at H3 (line 185) + collision prose at line 183; `docs/guides/installation.md` collision warning subsection at H2/H3 with collision prose; both name `/ceos-agents:pipeline-status` and `/ceos-agents:setup-mcp` and list 3 deprecated identifiers; workflow-router "Did you mean...?" prose lists all 3 deprecated names | PASS |
| REQ-CHANGELOG-MIGRATION | `## [7.0.0]` section with 5-bullet migration + 3 disclosures + counts table | `CHANGELOG.md` lines 10-44: `## [7.0.0]` section, 5 BREAKING CHANGES bullets, 5 migration bullets (Extra labels, status, init, create-pr, Pause Limits), Lost-agency disclosure inline at bullet 4, Skill-not-found disclosure at line 28-30, State.json forward-compat disclosure at line 32-34, Counts table at line 36-44 | PASS |
| REQ-COUNTS | Doc count 28 skills + 18 optional + 21 agents | All 7 anchors verified: CLAUDE.md "28 skills" + "18 optional config sections in total"; README.md "28 skills" + "18 optional sections"; docs/reference/skills.md "all 28 skills"; docs/reference/automation-config.md "18 optional sections"; docs/architecture.md `SKL[28 Skills]`; docs/getting-started.md "all 28 skills"; filesystem skill count = 28; agent count = 21; no empty skills/ subdirs | PASS |
| REQ-INVARIANTS | License SPDX + email + template parity | `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` both `"license": "MIT"`; `LICENSE` first line `MIT License`; `filip.sabacky@ceosdata.com` present in SECURITY.md + CODE_OF_CONDUCT.md + CONTRIBUTING.md; `diff -q` of all 3 issue/PR template pairs returns identical | PASS |
| REQ-NO-VERSION-BUMP | Pipeline must NOT bump version | `git diff main -- .claude-plugin/plugin.json \| grep '+- "version"'` returns 0 lines; same for marketplace.json; `git tag -l v7.0.0` returns empty | PASS |

---

## Sampled AC Verification (23 ACs across 11 REQs)

| AC ID | Bash command (truncated) | Exit code | Verdict |
|---|---|---|---|
| AC-DEL-EXTRA-LABELS-2 | `! grep -q 'pr_rules\.extra_labels' core/config-reader.md` | 0 | PASS |
| AC-DEL-EXTRA-LABELS-3 | `! grep -q 'Extra labels' agents/publisher.md` | 0 | PASS |
| AC-PAUSE-LIMITS-DOC-1 | `grep -E '^\| Pause Limits \| No \| /fix-ticket, ... \|' docs/reference/automation-config.md` | 0 | PASS |
| AC-RENAME-STATUS-1 | `[ ! -d skills/status ]` | 0 | PASS |
| AC-RENAME-STATUS-3 | `head -10 skills/pipeline-status/SKILL.md \| grep -qE '^name: pipeline-status$'` | 0 | PASS |
| AC-RENAME-INIT-2 | `[ -d skills/setup-mcp ] && [ -f skills/setup-mcp/SKILL.md ]` | 0 | PASS |
| AC-RENAME-INIT-5 | `grep -q '/ceos-agents:setup-mcp' core/mcp-preflight.md && ! grep -q '/ceos-agents:init' ...` | 0 | PASS |
| AC-PUBLISH-AUTO-DETECT-3 | Canonical regex `[A-Za-z][A-Za-z0-9_]*-[0-9]+` + numeric form + dot-only defense | 0 | PASS |
| AC-PUBLISH-AUTO-DETECT-4 | All 5 error_type buckets `tls`/`auth`/`not_found`/`timeout`/`unknown` present | 0 | PASS |
| AC-PUBLISH-AUTO-DETECT-5 | `unknown → FAIL` defensive default present | 0 | PASS |
| AC-PUBLISH-AUTO-DETECT-6 | 3 Tracker: row exact strings present in agents/publisher.md | 0 | PASS |
| AC-PUBLISH-AUTO-DETECT-8 | All 3 modes `full-publish`, `pr-only-no-id`, `pr-only-404` present | 0 | PASS |
| AC-PUBLISH-AUTO-DETECT-12 | SC-7 404 WARN single-line message present | 0 | PASS |
| AC-PUBLISH-AUTO-DETECT-13 | SC-8 no-id INFO single-line message present | 0 | PASS |
| AC-PUBLISH-AUTO-DETECT-14 | SC-10 missing Branch naming INFO single-line message present | 0 | PASS |
| AC-PUBLISH-AUTO-DETECT-15 | SC-12 detached HEAD FAIL guard present | 0 | PASS |
| AC-DEL-CREATE-PR-1 | `[ ! -d skills/create-pr ]` | 0 | PASS |
| AC-DOCS-COLLISION-WARN-3 | All 3 deprecated identifiers + did-you-mean prose in workflow-router | 0 | PASS |
| AC-CHANGELOG-MIGRATION-1 | `## [7.0.0]` section header present | 0 | PASS |
| AC-CHANGELOG-MIGRATION-3 | All 5 migration bullets (Extra labels, pipeline-status, setup-mcp, /create-pr removed, Pause Limits) | 0 | PASS |
| AC-COUNTS-8 | Filesystem skill count = 28 | 0 | PASS |
| AC-COUNTS-9 | Agent count = 21 | 0 | PASS |
| AC-INVARIANTS-1 | License SPDX MIT consistent across plugin.json + marketplace.json + LICENSE | 0 | PASS |
| AC-INVARIANTS-2 | filip.sabacky@ceosdata.com present in SECURITY.md + CODE_OF_CONDUCT.md + CONTRIBUTING.md | 0 | PASS |
| AC-INVARIANTS-3 | Issue/PR templates byte-identical (.gitea ↔ .github) — 3 `diff -q` pairs | 0 | PASS |
| AC-NO-VERSION-BUMP-1 | `git diff main -- .claude-plugin/plugin.json` shows zero `"version"` changes | 0 | PASS |
| AC-NO-VERSION-BUMP-3 | `git tag -l v7.0.0` returns empty | 0 | PASS |

**Result: 23/23 sampled ACs PASS.**

---

## Test Scenario Execution (binding for spec compliance)

All 18 v7.0.0 test scenarios in `tests/scenarios/v7.0.0-*.sh` execute with exit code 0:

| # | Scenario | Exit |
|---|---|---|
| 1 | v7.0.0-changelog-migration-guide.sh | 0 |
| 2 | v7.0.0-cross-file-invariants.sh | 0 |
| 3 | v7.0.0-doc-count-18-config-sections.sh | 0 |
| 4 | v7.0.0-doc-count-28-skills.sh | 0 |
| 5 | v7.0.0-empty-skills-dir-invariant.sh | 0 |
| 6 | v7.0.0-no-create-pr-skill.sh | 0 |
| 7 | v7.0.0-no-extra-labels-section.sh | 0 |
| 8 | v7.0.0-no-version-bump.sh | 0 |
| 9 | v7.0.0-pause-limits-mapping.sh | 0 |
| 10 | v7.0.0-publish-auto-detect-issue-404.sh | 0 |
| 11 | v7.0.0-publish-auto-detect-issue-found.sh | 0 |
| 12 | v7.0.0-publish-auto-detect-tracker-down.sh | 0 |
| 13 | v7.0.0-publish-extraction-regex.sh | 0 |
| 14 | v7.0.0-publish-no-issue-id-pr-only.sh | 0 |
| 15 | v7.0.0-readme-collision-warning.sh | 0 |
| 16 | v7.0.0-skill-rename-init.sh | 0 |
| 17 | v7.0.0-skill-rename-status.sh | 0 |
| 18 | v7.0.0-workflow-router-intent-table.sh | 0 |

---

## Critical Design Decisions Verification

1. **Canonical regex `^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)` exact in publish/SKILL.md** — present at line 79 (literal) and line 90 (bash form `[[ "$residue" =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ]]`). PASS.
2. **5-bucket error_type fork (`tls/auth/not_found/timeout/unknown`, `unknown → FAIL`)** — all 5 buckets quoted in skills/publish/SKILL.md; `unknown → FAIL` defensive default present. PASS.
3. **3 publish modes (`full-publish`, `pr-only-404`, `pr-only-no-id`)** — all 3 strings present in skills/publish/SKILL.md. PASS.
4. **Workflow-router "Did you mean...?" prose contains all 3 deprecated names** — `skills/workflow-router/SKILL.md:72-78` has H2 heading "Deprecated names — did you mean?" and 3 bullets covering ceos-agents:status, ceos-agents:init, ceos-agents:create-pr. PASS.
5. **Publisher Tracker row contract (3 exact strings)** — `agents/publisher.md:91-93` has all 3 exact strings: `Tracker: Updated → For Review`, `Tracker: Skipped — issue ID '{issue_id}' not found in {tracker_type}`, `Tracker: Skipped — no issue ID in branch name`. PASS.
6. **CHANGELOG `## [7.0.0]` with all 5 migration bullets + lost-agency disclosure + skill-not-found note + state.json forward-compat note + counts table** — all present in CHANGELOG.md lines 10-44. PASS.
7. **check-setup deprecated detector is WARN-only (no exit code change)** — `skills/check-setup/SKILL.md:201-208` uses `[WARN]` echo, no `exit 1`/`FAIL`/`fail()`/`return 1`; explicit confirmation prose at line 208. PASS.
8. **REQ-NO-VERSION-BUMP holds** — `git diff main -- .claude-plugin/plugin.json | grep '"version"'` returns 0 lines; same for marketplace.json; no v7.0.0 tag. PASS.

All 8 critical design decisions correctly encoded.

---

## Cross-File Invariants (3/3)

| Invariant | Command | Result |
|---|---|---|
| License SPDX | `grep -c '"license": "MIT"' .claude-plugin/{plugin,marketplace}.json` | 1, 1 |
| LICENSE header | `head -1 LICENSE` | `MIT License` |
| Maintainer email | `grep -c filip.sabacky@ceosdata.com SECURITY.md CODE_OF_CONDUCT.md CONTRIBUTING.md` | 1, 1, 1 |
| Template parity (3 pairs) | `diff -q` for bug_report, feature_request, pull_request_template | identical |

All cross-file invariants hold.

---

## Findings (1 advisory, non-blocking)

### F1 (advisory) — Text-AC vs scenario-AC scoping divergence

**Description:** AC-RENAME-STATUS-4, AC-RENAME-INIT-4, AC-DEL-CREATE-PR-2 use grep `--exclude-dir=docs/plans` and `--exclude-dir=docs/superpowers` (path-form excludes). GNU grep `--exclude-dir` only matches against the basename of the directory, so the path-form excludes do not actually exclude `docs/plans` or `docs/superpowers` content. As a result, running these ACs verbatim against the repository returns non-zero matches (7 for status, 7 for init, 6 for create-pr) — all hits are in `docs/plans/` and `docs/superpowers/` historical/plan documents OR in `README.md` migration table OR in `docs/guides/installation.md` migration prose, both of which are intentionally retained per REQ-DOCS-COLLISION-WARN.

**Mitigation:** The corresponding test scenarios (`tests/scenarios/v7.0.0-skill-rename-status.sh`, `v7.0.0-skill-rename-init.sh`, `v7.0.0-no-create-pr-skill.sh`) implement the AC intent correctly with proper basename-form exclusions, and all 3 scenarios PASS. The test scenarios are the binding implementation of the ACs for harness purposes.

**Severity:** Advisory only — does NOT block Phase 8. The implementation correctly satisfies BOTH (a) the spec intent of "no stale references in production surfaces" AND (b) REQ-DOCS-COLLISION-WARN's mandate to document the rename in README + installation guide. The text ACs in formal-criteria.md should be updated in a future revision to use basename-form `--exclude-dir=plans --exclude-dir=superpowers` and to additionally scope-exempt the migration-table contexts (already excepted by intent in REQ-DOCS-COLLISION-WARN).

**Recommendation:** Capture this AC text refinement in the v7.0.1 follow-up bin (formal-criteria.md polish) — non-blocking for v7.0.0 release.

---

## Scope Audit

### Scope creep check (no features beyond 6 actions)

Reviewed implementation diffs — no new features beyond the 6 spec actions. The publish auto-detect logic is exactly as specified in REQ-PUBLISH-AUTO-DETECT (12 sub-clauses + 5 extraction worked examples). No new agents, no new optional config sections, no new webhook events, no new core contracts. PASS.

### Scope cuts check (all 6 actions present)

| # | Action | Present |
|---|---|---|
| 1 | Delete `Extra labels` config section | Yes (REQ-DEL-EXTRA-LABELS) |
| 2 | Fix `Pause Limits` doc mapping | Yes (REQ-PAUSE-LIMITS-DOC) |
| 3 | Rename `/status` → `/pipeline-status` | Yes (REQ-RENAME-STATUS) |
| 4 | Rename `/init` → `/setup-mcp` | Yes (REQ-RENAME-INIT) |
| 5 | Auto-detect tracker in `/publish` + delete `/create-pr` | Yes (REQ-PUBLISH-AUTO-DETECT + REQ-DEL-CREATE-PR) |
| 6 | README + docs collision warning | Yes (REQ-DOCS-COLLISION-WARN) |

All 6 actions present.

---

## Conclusion

**Spec alignment score: 0.95 / 1.0 — PASS** (threshold: 0.7).

Score breakdown:
- REQ traceability: 11/11 (1.0)
- AC sample verification: 23/23 (1.0)
- Test scenario execution: 18/18 (1.0)
- Critical design decisions: 8/8 (1.0)
- Cross-file invariants: 3/3 (1.0)
- Scope discipline (no creep + no cuts): PASS (1.0)
- Findings deduction: −0.05 for F1 advisory (text-AC vs scenario-AC scoping divergence — corrected by test scenarios; AC text needs polish in v7.0.1)

The v7.0.0 implementation faithfully encodes all 6 spec actions, all 11 REQs, all 8 critical design decisions, and preserves all 3 CLAUDE.md cross-file invariants. The pipeline correctly avoided version bump per REQ-NO-VERSION-BUMP — the user runs `/version-bump` post-pipeline.

**Verdict: PASS.**
