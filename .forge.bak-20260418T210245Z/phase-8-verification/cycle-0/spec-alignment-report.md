# Phase 8 Spec-Alignment Adversary Report

## Methodology

Cross-referenced Phase 4 final artifacts (`requirements.md` / `design.md` / `formal-criteria.md`) against the implementation branch. Walked all 33 EARS requirements (AUTOPILOT-R1..R13, WEBHOOK-R1..R8, COST-R1..R12) and probed each for a backing artifact (SKILL.md clause, core contract prose, docs row, or scenario test). Ran 10 AC verification shell commands verbatim as written in `formal-criteria.md` (AC-1, AC-5, AC-9, AC-13, AC-14, AC-21, AC-22, AC-23, AC-25, AC-27, AC-28, AC-30, AC-33, AC-38 — exceeded 10 because the overhead was small). Ran targeted grep sweeps for the six Section-6 NOT_IN_SCOPE items (step-skipped / autopilot-started / autopilot-completed / `--format json` / `pipeline-summary.json` / `schema_version "1.1"` / billing-currency strings). Inspected `core/post-publish-hook.md` Section 4 JSON literals against `design.md` §§4.3-4.5 field-by-field. Verified the 25+ files enumerated in `design.md` Section 3 are all present / modified.

## EARS Coverage

- Total EARS: 33
- Implemented: 33
- Missing: 0

Spot-check matrix (representative):

| EARS | Artifact | Evidence |
|---|---|---|
| AUTOPILOT-R1 | `skills/autopilot/SKILL.md` lines 2/5/6 | frontmatter correct |
| AUTOPILOT-R2 | `skills/autopilot/SKILL.md` line 121 | `mkdir .ceos-agents/autopilot.lock` |
| AUTOPILOT-R5 | `skills/autopilot/SKILL.md` lines 99/234/317 | `trap ... EXIT` present; installed after successful mkdir |
| AUTOPILOT-R9 | `skills/autopilot/SKILL.md` lines 283-284 | `Skill(ceos-agents:fix-ticket...)` + `implement-feature` |
| AUTOPILOT-R13 | `skills/autopilot/SKILL.md` (Step 2 INFO line) | `[autopilot][INFO] Running on host` |
| WEBHOOK-R1 | `core/post-publish-hook.md:5` | Purpose line rewritten |
| WEBHOOK-R2..R4 | `core/post-publish-hook.md:35-98` | Section 4 payloads + fire-order rule |
| WEBHOOK-R8 | `core/post-publish-hook.md:132-134` + `core/block-handler.md:42` | existing `pr-created` / `issue-blocked` untouched |
| COST-R1 | `state/schema.md:5,37,214` | `schema_version` stays `"1.0"` |
| COST-R2..R6 | 4 pipeline skills (33/50/38/45 marker hits) | per-stage usage + pipeline accumulator written |
| COST-R7/R8/R11 | `skills/metrics/SKILL.md` (16 measured/estimated markers) | dual-mode split + footer |
| COST-R10 | `state/schema.md` + `cost-summary-truncation.sh` | 20-row / 4000-char cap documented |
| COST-R12 | `tests/scenarios/ac-v68-cost-task-tool-usage-field-discovery.sh` | DISCOVERED_FIELD allowlist asserted |

All 33 EARS have a traceable artifact; no structural gap.

## AC Verification Sample

| AC | Command | Result |
|---|---|---|
| AC-1 | `ac-v68-autopilot-skill-exists.sh` | PASS (3 frontmatter greps = 1 each) |
| AC-5 | `ac-v68-autopilot-trap-exit.sh` | PASS (trap ... EXIT present) |
| AC-9 | `ac-v68-webhook-post-publish-hook-section4.sh` | PASS (Purpose + Section 4) |
| AC-13 | `ac-v68-webhook-existing-events-unchanged.sh` | PASS |
| AC-14 | `ac-v68-cost-schema-version-stays-1.0.sh` | PASS |
| AC-21 | `ac-v68-autopilot-config-keys.sh` | PASS (7 keys in CLAUDE.md) |
| AC-22 | `ac-v68-doc-optional-sections-18.sh` | PASS (18 optional) |
| AC-23 | `ac-v68-doc-skill-count-29.sh` | PASS (29 skills in CLAUDE.md + docs/reference) |
| AC-25 | `ac-v68-webhook-three-events-documented.sh` | PASS |
| AC-27 | `ac-v68-doc-version-6.8.0.sh` | **FAIL** (plugin.json/marketplace.json still `6.7.2`) |
| AC-28 | `ac-v68-doc-changelog-entry.sh` | PASS |
| AC-30 | `ac-v68-autopilot-lock-mkdir.sh` | PASS |
| AC-33 | `ac-v68-webhook-no-step-skipped.sh` | PASS |
| AC-38 | `ac-v68-cost-task-tool-usage-field-discovery.sh` | PASS |

13 of 14 sampled ACs pass; the single failure is AC-27 (version bump).

## Scope Creep Check

| NOT_IN_SCOPE item | Grep result | Verdict |
|---|---|---|
| `step-skipped` webhook | Only appears inside test files asserting its absence | clean |
| `autopilot-started` / `autopilot-completed` batch events | Zero occurrences in repo (excluding `.forge.bak-*`) | clean |
| `--format json` on `/metrics` | Zero occurrences in `skills/metrics/` | clean |
| `pipeline-summary.json` artifact | Zero occurrences outside `.forge.bak-*` | clean |
| `schema_version: "1.1"` bump | Only inside old `.forge.bak-*` snapshots; all live files keep `"1.0"` | clean |
| Billing / currency semantics | Only informational cost-estimate prose in `docs/guides/autopilot.md` + `docs/reference/pipelines.md` — no $/USD/currency-conversion code | clean |

No scope creep detected.

## Known Drifts (documented, not counted as findings)

- **Autopilot config key names (spec-era vs roadmap-canonical).** `requirements.md` / `design.md` §4.7 list Gate-1 summary names (`Bug query`, `Feature query`, `Max issues per run`, `Max features per run`, `Stop on error`, `Dry run`, `Lock file`). Implementation in `CLAUDE.md:157`, `skills/autopilot/SKILL.md:51-59`, `core/config-reader.md`, and `docs/reference/config.md` uses roadmap-canonical names (`Max issues per run`, `Lock timeout`, `Log file`, `Bug limit`, `Feature limit`, `On error`, `Dry run`). User-approved Phase-7 reconciliation; ACs verifying this section (AC-21) were written against the roadmap names and pass. The historical spec text has not been retroactively rewritten.

## Findings

### [SPEC-FINDING-1] severity=MEDIUM

- **ac_id:** AC-27
- **requirement_id:** design.md §3.6 rows `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- **status:** missing
- **location:** `.claude-plugin/plugin.json:4` (`"version": "6.7.2"`) + `.claude-plugin/marketplace.json:11` (`"version": "6.7.2"`)
- **details:** AC-27 grep `'"version": "6.8.0"'` returns zero matches in both manifests. Design.md Section 3.6 explicitly lists these two files as MODIFY with "Bump `version` from `6.7.2` to `6.8.0`". The version bump has not been performed.
- **remediation:** Run `/ceos-agents:version-bump 6.8.0` OR edit both manifest files manually before commit. Per user convention (memory note), this is typically executed as the final release-closing step via the dedicated skill. If deferred intentionally until after Phase 8 verification, this is a known pre-release step — but as of this adversarial scan the artifact state does NOT satisfy AC-27.

### [SPEC-FINDING-2] severity=LOW

- **ac_id:** n/a (CHANGELOG freshness)
- **requirement_id:** design.md §3.6 row `CHANGELOG.md`
- **status:** mismatched
- **location:** `CHANGELOG.md:18`
- **details:** CHANGELOG v6.8.0 "Added" entry describes the `### Autopilot` section as having 7 keys named `Bug query, Feature query, Max issues per run, Max features per run, Stop on error, Dry run, Lock file` — the Gate-1 spec-era names. The actual implementation (and `CLAUDE.md:157`) uses the roadmap-canonical names `Max issues per run, Lock timeout, Log file, Bug limit, Feature limit, On error, Dry run`. A user reading the CHANGELOG will be misled about which keys to add to their config.
- **remediation:** Edit `CHANGELOG.md:18` to enumerate the actual 7 key names that match `CLAUDE.md`. Estimated effort: 1 line edit.

### [SPEC-FINDING-3] severity=LOW

- **ac_id:** n/a (CHANGELOG outcome enum)
- **requirement_id:** design.md §4.5 `pipeline-completed` — `outcome` ∈ `{success, blocked, failed}`
- **status:** mismatched
- **location:** `CHANGELOG.md:16`
- **details:** CHANGELOG refers to `outcome` values `success/blocked/aborted`. Spec (`design.md:85`) and implementation (`core/post-publish-hook.md:85`, all four pipeline skills) use `success/blocked/failed`. Webhook consumers reading the CHANGELOG will expect a value (`aborted`) that will never be emitted.
- **remediation:** Replace `aborted` with `failed` in `CHANGELOG.md:16`.

### [SPEC-FINDING-4] severity=LOW

- **ac_id:** AC-24 (command format, not semantic content)
- **requirement_id:** design.md §3.6 `docs/reference/skills.md`
- **status:** mismatched (verbatim grep)
- **location:** `docs/reference/skills.md:18`
- **details:** AC-24 specifies `grep -n "^| /autopilot " docs/reference/skills.md` must return exactly 1 match. Actual row begins `| Bug-Fix | [/autopilot](#autopilot) |` — the file uses a multi-column table with a category prefix, so the literal `"^| /autopilot "` pattern from the spec fails. However, the file DOES document `/autopilot` (lines 18, 75, 82, 91, 99) and the semantic requirement (autopilot discoverable in skills reference) is satisfied.
- **remediation:** Either (a) update AC-24 in formal-criteria.md to match the new table format, or (b) add a bare `| /autopilot ` row somewhere in the file. Preference (a) — the implementation is correct; the AC grep is brittle.

## Dimension Score

Scoring rubric:
- EARS coverage 33/33 = 1.00 (weight 0.35)
- AC sample 13/14 = 0.93 (weight 0.35)
- Scope creep 0 items = 1.00 (weight 0.20)
- Document freshness (CHANGELOG drift × 2 + AC-24 brittle grep) = 0.70 (weight 0.10)

Weighted: 0.35×1.00 + 0.35×0.93 + 0.20×1.00 + 0.10×0.70 = 0.35 + 0.326 + 0.20 + 0.07 = **0.946**

Downgrade for the MEDIUM finding (AC-27 version-bump gap, blocking for ship but mechanical to fix): −0.06.

**spec_alignment_score:** 0.88
