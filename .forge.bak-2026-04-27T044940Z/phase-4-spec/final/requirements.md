# Phase 4 — Requirements (EARS) for v7.0.0

> **Release theme:** Cleanup + naming + auto-detect publish (BREAKING).
> **Source of truth:** `docs/superpowers/specs/2026-04-24-public-release-readiness-WIP.md` (sekce "v7.0.0 FINÁLNÍ scope" + "/publish auto-detect logic" + Migration guide).
> **No version bump in pipeline scope.** REQ-NO-VERSION-BUMP exists to PROHIBIT it; user runs `/version-bump` post-pipeline.

All requirements are EARS-formatted single sentences. Each requirement is referenced by stable ID. Phase 3 user-approved decisions and Phase 2 file:line citations are encoded inline. The 11 Phase 3 open questions are resolved within these REQs (see resolution map at the bottom).

---

## REQ-DEL-EXTRA-LABELS — Delete `Extra labels` config section

**EARS:** When the v7.0.0 release commit lands, the system shall not contain any `Extra labels` configuration section, table row, parse rule, agent prompt fragment, optional-section enumeration entry, or onboarding menu item in any active (non-`docs/plans/`, non-`docs/superpowers/`, non-`.forge/`, non-`.forge.bak-*`, non-`CHANGELOG.md`) file under `core/`, `agents/`, `skills/`, `docs/`, `examples/`, `tests/`, `CLAUDE.md`, or `README.md`.

**Scope (Phase 2 Q2 inventory — 17 active locations):**
- `core/config-reader.md:31` — parse rule deletion
- `agents/publisher.md:69` — prompt fragment rewrite ("Add labels from PR Rules section only.")
- `skills/fix-ticket/SKILL.md:47, 638` — config-read bullet + publisher context segment
- `skills/fix-bugs/SKILL.md:42, 783` — same
- `skills/implement-feature/SKILL.md:35, 599` — same
- `skills/check-setup/SKILL.md:56` — optional-section enumeration list
- `skills/migrate-config/SKILL.md:41` — migration loop enumeration
- `skills/onboard/SKILL.md:175, 204` — interactive menu item [12] + config summary
- `docs/reference/automation-config.md:33, 332-339` — Quick reference row + section body
- `CLAUDE.md:149` — optional sections table row
- `examples/configs/github-nextjs.md:104` — section body
- `examples/configs/redmine-oracle-plsql.md:182` — section body
- `tests/scenarios/config-reader-sections.sh:25` — array element
- `tests/scenarios/v6.9.0-bc-no-renamed-section.sh:25, 47` — array element + mutation guard

**Note:** `CLAUDE.md:160` count string "19 → 18" is governed by REQ-COUNTS, not this REQ.

---

## REQ-PAUSE-LIMITS-DOC — Fix `Pause Limits` Used-By column

**EARS:** When the v7.0.0 release commit lands, the `Pause Limits` row in the Quick reference table at `docs/reference/automation-config.md:40` shall list the 6 lifecycle participants `/fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot, /resume-ticket` (the precise set from Phase 2 R3 + DISAGREEMENT B resolution), and the `CLAUDE.md` mention of `Pause Limits` shall remain consistent with this list.

**Scope (Phase 2 R3 + DISAGREEMENT B):**
- `docs/reference/automation-config.md:40` — change `| Pause Limits | No | /autopilot |` → `| Pause Limits | No | /fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot, /resume-ticket |`
- `docs/reference/automation-config.md:460-477` — section body already accurate (no edit)
- `docs/reference/automation-config.md:628` — HTML comment, optional consistency update only (NOT in scope of REQ)
- `CLAUDE.md` `Pause Limits` mention — must remain consistent (no edit required because CLAUDE.md does not enumerate consumers; it only describes the option)

**Rationale:** The 4 pause-emitters (fix-ticket, fix-bugs, implement-feature, scaffold) write `status="paused"`; autopilot enforces the timeout and auto-aborts; resume-ticket reads `paused` and writes `running`. All 6 are relevant to configuring/understanding Pause Limits.

---

## REQ-RENAME-STATUS — Rename `/ceos-agents:status` → `/ceos-agents:pipeline-status`

**EARS:** When the v7.0.0 release commit lands, the directory `skills/status/` shall not exist, the directory `skills/pipeline-status/` shall exist with frontmatter `name: pipeline-status`, and every active reference (skill cross-reference, doc index, README skill table, workflow-router intent table + Step 3 prose, troubleshooting guide, test scenario path) shall use the new identifier `pipeline-status` (or `/ceos-agents:pipeline-status`) without any residual `/ceos-agents:status` or bare `status` skill-name reference EXCEPT in the workflow-router "Did you mean...?" fallback prose at `skills/workflow-router/SKILL.md` (design.md §5.3), which intentionally references the deprecated identifier to support user disambiguation (excluding the unrelated `state.json.status` field, the prose word "status" in non-skill-name contexts, and `.forge/`/`.forge.bak-*`/`CHANGELOG.md` history).

**Scope (Phase 2 Q4 + Action 3 change list):**
- Directory rename via `git mv skills/status skills/pipeline-status`
- `skills/pipeline-status/SKILL.md` frontmatter `name: status` → `name: pipeline-status`
- `skills/workflow-router/SKILL.md:18` — intent table row (skill-id field)
- `skills/workflow-router/SKILL.md:54` — Step 3 non-destructive prose (bare-word `status` in skill-name context)
- `docs/reference/skills.md:33, 193, 509, 516, 524, 555, 584` — Skill Index + section heading + examples + Related skills
- `docs/guides/troubleshooting.md:311`
- `README.md:153` — skill table row
- `CLAUDE.md:31` — skills enumeration
- `tests/scenarios/skills-directory-structure.sh:54` — EXPECTED_SKILLS array
- `tests/scenarios/skills-frontmatter-check.sh:~90` — READONLY_SKILLS array
- `tests/scenarios/no-mcp-jargon-errors.sh:20` — `skills/status/SKILL.md` → `skills/pipeline-status/SKILL.md`

**Constraint (Phase 3 D4):** No stub at `skills/status/`. Skill-not-found error from Claude Code is the intended behavior post-upgrade. CHANGELOG must disclose this (see REQ-CHANGELOG-MIGRATION).

---

## REQ-RENAME-INIT — Rename `/ceos-agents:init` → `/ceos-agents:setup-mcp`

**EARS:** When the v7.0.0 release commit lands, the directory `skills/init/` shall not exist, the directory `skills/setup-mcp/` shall exist with frontmatter `name: setup-mcp`, and every active reference (core contract, MCP pre-flight contract, skill cross-reference, doc index, README skill table, getting-started guide, installation guide, MCP-configuration guide, troubleshooting guide, workflow-router intent table, test scenario path) shall use the new identifier `setup-mcp` (or `/ceos-agents:setup-mcp`) without any residual `/ceos-agents:init` or bare `init` skill-name reference EXCEPT in the workflow-router "Did you mean...?" fallback prose at `skills/workflow-router/SKILL.md` (design.md §5.3), which intentionally references the deprecated identifier to support user disambiguation (excluding `git init`, `npm init`, `forge init`, and other non-skill-name contexts; excluding `.forge/`/`.forge.bak-*`/`CHANGELOG.md` history).

**Scope (Phase 2 Q4 + Action 4 change list):**
- Directory rename via `git mv skills/init skills/setup-mcp`
- `skills/setup-mcp/SKILL.md` frontmatter + 5 self-references at lines 202, 215, 225, 263, 341
- `core/config-reader.md:57` — `run /ceos-agents:init.` → `run /ceos-agents:setup-mcp.`
- `core/mcp-preflight.md:36` — `or /ceos-agents:init` → `or /ceos-agents:setup-mcp`
- `skills/check-setup/SKILL.md:68, 76`
- `skills/pipeline-status/SKILL.md:60, 82` (formerly skills/status/)
- `skills/onboard/SKILL.md:242`
- `skills/implement-feature/SKILL.md:85`
- `skills/create-backlog/SKILL.md:52`
- `skills/scaffold/SKILL.md:180, 183, 188, 213, 217, 221, 1068, 1070, 1076, 1078, 1098`
- `skills/workflow-router/SKILL.md:20`
- `docs/reference/skills.md:29, 387, 391, 398-427`
- `docs/getting-started.md:115, 125`
- `docs/guides/installation.md:92`
- `docs/guides/mcp-configuration.md:5, 52`
- `docs/guides/troubleshooting.md:225`
- `README.md:164`
- `CLAUDE.md:31`
- `tests/scenarios/skills-directory-structure.sh:43`
- `tests/scenarios/skills-frontmatter-check.sh:~97`
- `tests/scenarios/scaffold-mcp-checkpoint.sh:7`
- `tests/scenarios/v6.10.0-dispatch-hook-install-surface.sh:17`
- `tests/scenarios/v644-diagnostics-hardening.sh:19, 36, 67, 109, 375, 378`

**Constraint (Phase 3 D4):** No stub at `skills/init/`. Same rationale as REQ-RENAME-STATUS.

---

## REQ-PUBLISH-AUTO-DETECT — `/publish` rewrite with branch parse + tracker auto-detect

**EARS:** When `/publish` is invoked, the system shall (a) determine `current_branch` via `git branch --show-current` (FAIL with exit non-zero on detached HEAD — empty result), (b) parse the `Source Control → Branch naming` template from Automation Config (if absent: `issue_id = null`, skip extraction), identify the literal prefix preceding `{issue-id}` in the template, strip that prefix from `current_branch` to obtain a residue, and extract `issue_id` from the residue via the canonical issue-ID extraction regex `^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)` (which matches all 6 supported tracker ID shapes: youtrack/jira/linear `PROJ-123`, github/gitea/redmine numeric `123` or hash-prefixed `#42`), capturing the first match as `issue_id`, applying the v6.8.1 path-traversal defense `! issue_id =~ ^\.+$` (defensive secondary check; the canonical regex never matches dot-only strings) BEFORE any MCP pre-flight runs, (c) gate the existing MCP pre-flight (current Step 0 of `skills/publish/SKILL.md`) on `tracker_needed = (issue_id != null)`, (d) when `tracker_needed == true` locate the single-issue fetch tool via prefix-scan per `core/mcp-detection.md:28-34` (no hardcoded tool names) and call it with `issue_id`, (e) classify any failure per `core/mcp-detection.md:58-87` into exactly one of the 5 buckets `tls`, `auth`, `not_found`, `timeout`, `unknown`, (f) branch on the outcome into one of three modes `full-publish`, `pr-only-no-id`, `pr-only-404`, or FAIL with exit non-zero when `error_type ∈ {tls, auth, timeout, unknown}` (including the case "tracker prefix has tools but no `get_issue`-shaped tool found" which is classified as `unknown` and FAILs), and (g) emit the publisher Report `Tracker:` row in exactly one of the three forms `Tracker: Updated → For Review` | `Tracker: Skipped — issue ID '{issue_id}' not found in {tracker_type}` | `Tracker: Skipped — no issue ID in branch name`.

### REQ-PUBLISH-AUTO-DETECT — Sub-clauses

**SC-1 (Phase 3 open question 1 resolution):** Step 0 (NEW) is a pre-pre-flight branch parse; current Step 0 (MCP pre-flight) is renumbered to Step 1 and runs ONLY when `tracker_needed == true`. The PR-only-no-id mode bypasses MCP entirely (a user on `chore/refactor-foo` with no MCP server configured MUST be able to publish a PR).

**SC-2 (Phase 3 open question 2 resolution):** The error_type classification is the closed 5-bucket enum exactly: `tls`, `auth`, `not_found`, `timeout`, `unknown`. The `unknown` bucket is the defensive default; `unknown → FAIL` (no soft fallback).

**SC-3 (Phase 3 open question 3 resolution):** When the prefix `mcp__{tracker_type}__*` resolves to one or more tools but none of them is a `get_issue`-shaped single-issue fetch tool, the system shall set `error_type = "unknown"` and FAIL per the FAIL tier UX. This handles future tracker types (e.g., Asana with non-standard tool names).

**SC-4 (Phase 3 open question 4 resolution):** The Publish Report `Tracker:` row uses these three exact strings (no localization, no variation):
- `Tracker: Updated → For Review` (mode `full-publish`)
- `Tracker: Skipped — issue ID '{issue_id}' not found in {tracker_type}` (mode `pr-only-404`)
- `Tracker: Skipped — no issue ID in branch name` (mode `pr-only-no-id`)

**SC-5 (Phase 3 open question 5 resolution — operator note):** The rewritten `skills/publish/SKILL.md` shall include a brief note in the skill-level prose (not as a separate section) stating that `/publish` is interactive-only and that headless / CI / cron paths use `/ceos-agents:autopilot`. This note is informational; absence does not affect runtime behavior, but presence is asserted by AC.

**SC-6 (FAIL tier UX — Phase 3 Dimension 5):** On FAIL, the skill shall emit the block message in the `[ceos-agents] 🔴 Pipeline Block` format (per CLAUDE.md "Block Comment Template") with `Skill:` field (not `Agent:`), Reason, Detail (echoing `error_type` and `tracker_type`), and a 4-step Recommendation list:
  1. Run `/ceos-agents:check-setup` to diagnose tracker connectivity.
  2. To create a PR without tracker update, rename the branch to a non-matching prefix (e.g., `chore/...` instead of `fix/PROJ-123-foo`), then re-run `/publish`.
  3. To create the PR manually, run `git push -u origin {branch} && gh pr create` (or the tracker UI's equivalent).
  4. Once the tracker is reachable, re-run `/ceos-agents:publish`.

**SC-7 (404 WARN tier — Phase 3 Dimension 5):** On `error_type == "not_found"`, the skill shall emit a single-line (one logical line, one `echo` invocation, terminated by a single `\n`) `[ceos-agents][WARN]` message with semantic content: `Branch '{branch}' contains issue ID pattern '{issue_id}' but no matching ticket was found in {tracker_type}. Creating PR without tracker update.` Pipeline continues; webhook fires `pr-created` with `issue_id` empty.

**SC-8 (No-issue-id INFO tier — Phase 3 Dimension 5):** When `issue_id == null` after extraction, the skill shall emit a single-line (one logical line, one `echo` invocation, terminated by a single `\n`) `[ceos-agents][INFO]` message with semantic content: `Branch '{branch}' does not match the configured Branch naming pattern. Creating PR without tracker contact.` Pipeline continues; webhook fires `pr-created` with `issue_id` empty.

**SC-9 (Webhook semantics):** The existing `pr-created` event fires in all non-FAIL modes. No `pr-created` event fires on FAIL. No new webhook event is introduced (`tracker-down` deferred to v7.0.1+ per Phase 3 D5; whether `pipeline-completed` with `outcome: failed` fires on `/publish` FAIL is also deferred to v7.0.1+).

**SC-10 (Missing Branch naming config — HIGH-1 fix):** When the `Source Control → Branch naming` config key is absent from Automation Config, the skill shall NOT FAIL; instead it shall log a single-line `[ceos-agents][INFO] No Branch naming pattern configured; PR-only mode.` line, set `issue_id = null` (and `tracker_needed = false`), and proceed to the pre-publish checks (Step 3). This produces `mode = "pr-only-no-id"` regardless of branch name.

**SC-11 (Extraction algorithm contract — CRITICAL-1 fix, REGEX-EXTRACTOR form):** The branch-parse algorithm shall use a CANONICAL ISSUE-ID EXTRACTION REGEX, not a "split at delimiter" approach. The "split at first delimiter" approach was ABANDONED in revision-2 because YouTrack/Jira/Linear issue IDs (`PROJ-123`, `ABC-456`, `ENG-789`) themselves contain `-`, so splitting at the first `-` of `PROJ-123-fix-crash` yields `PROJ`, not `PROJ-123`. The fundamental issue: when the post-`{issue-id}` template delimiter character also appears INSIDE the issue ID, "split at first delimiter" cannot work. Concretely:

1. Parse the Branch naming template literal text vs `{issue-id}` placeholder vs `{description}` placeholder.
2. Identify `pre_prefix` (literal text preceding `{issue-id}` in the template). The post-`{issue-id}` delimiter is intentionally NOT used as a split boundary; the canonical regex below understands the structure of valid issue IDs and consumes only the issue-ID portion.
3. If branch_name does NOT start with `pre_prefix`: `issue_id = null`.
4. Else: `residue = branch_name` with `pre_prefix` stripped from the front.
5. Apply the canonical extraction regex anchored at the start of the residue:

   ```
   ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)
   ```

   The regex matches EITHER `#?[0-9]+` (numeric, optionally hash-prefixed — covers github/gitea/redmine shapes `123` and `#42`) OR `[A-Za-z][A-Za-z0-9_]*-[0-9]+` (alphanumeric project prefix + `-` + digits — covers youtrack/jira/linear shapes `PROJ-123`, `ABC_DEF-789`). The first capture group is the issue_id; the remainder of the residue (e.g., `-fix-crash` after `PROJ-123`) is description and is discarded. If the regex does not match: `issue_id = null`.
6. Apply path-traversal defense: if `issue_id =~ ^\.+$` (dot-only): `issue_id = null`. The canonical regex never matches dot-only strings, so this check is defensive (preserved from v6.8.1 contract).

This regex covers ALL 6 supported tracker types (youtrack, jira, linear, github, gitea, redmine). For pattern `feature/{issue-id}` (no description segment): the regex still works — it consumes only the issue-ID portion. For pattern `fix/{issue-id}-{description}` and branch `fix/PROJ-123-fix-crash`: residue is `PROJ-123-fix-crash`, the regex matches `PROJ-123`, the trailing `-fix-crash` is discarded.

**SC-12 (Detached HEAD handling — Reviewer 2 finding f-v4w5x6):** When `git branch --show-current` returns empty (detached HEAD), the skill shall FAIL (exit non-zero) with INFO-level diagnostic: `Cannot determine branch (detached HEAD). /publish requires an active branch.` Detached HEAD is treated as FAIL (not pr-only-no-id) because there is no branch to push or to use as PR source.

---

## REQ-DEL-CREATE-PR — Delete `/create-pr` skill

**EARS:** When the v7.0.0 release commit lands, the directory `skills/create-pr/` shall not exist, and every active reference to `/create-pr`, `ceos-agents:create-pr`, or the literal path `skills/create-pr/SKILL.md` in skills, agents, docs, README, examples, or active test scenarios shall be either removed (if a self-contained row/example/array element, or if it is a `/publish` skill's own "Related skills" entry referring back to itself), or rewritten to reference `/ceos-agents:publish` (if a "Related skills" or alternative-skill mention IN ANOTHER SKILL — not in `/publish` itself), EXCEPT in the workflow-router "Did you mean...?" fallback prose at `skills/workflow-router/SKILL.md` (design.md §5.3), which intentionally references the deprecated identifier to support user disambiguation.

**Scope (Phase 2 Q4 + Action 5 change list):**
- `git rm -r skills/create-pr/`
- `docs/reference/automation-config.md:19` — remove `/create-pr,` from `PR Rules` Used-By column
- `docs/reference/automation-config.md:20` — remove `/create-pr,` from `PR Description Template` Used-By column
- `docs/reference/skills.md:26` — DELETE `| Publishing | [/create-pr](#create-pr) |` row
- `docs/reference/skills.md:323-342` — DELETE entire `### /create-pr` section (~20 lines)
- `docs/reference/skills.md:363` — remove `/create-pr` reference from Related skills in `### /publish` section
- `README.md:148` — DELETE `| `/create-pr` | ... |` skill table row
- `CLAUDE.md:31` — remove `/create-pr,` from skills enumeration
- `skills/workflow-router/SKILL.md:15` — DELETE `create-pr` intent table row
- `skills/workflow-router/SKILL.md:55` — remove `create-pr,` from destructive list prose
- `tests/scenarios/no-mcp-jargon-errors.sh:15` — REMOVE `"skills/create-pr/SKILL.md"` from STANDARD_ERROR_FILES
- `tests/scenarios/skills-directory-structure.sh:36` — REMOVE `create-pr` from EXPECTED_SKILLS
- `tests/scenarios/skills-frontmatter-check.sh:51` — REMOVE `create-pr` from PIPELINE_SKILLS; FC-5 count comment 12→11

**Constraint (Phase 3 D4):** No stub. The auto-detect's three-mode fork covers every legitimate `/create-pr` use case except "PR-only with valid tracker reference" — the lost-agency case which is explicitly disclosed in REQ-CHANGELOG-MIGRATION.

---

## REQ-DOCS-COLLISION-WARN — README + installation guide collision warning

**EARS:** When the v7.0.0 release commit lands, both `README.md` and `docs/guides/installation.md` shall contain a clearly-marked subsection (heading at H2 or H3 level — explicit subsection, not a passing prose mention) that (a) names the collision: short forms `/status` and `/init` collide with Claude Code built-in slash commands, (b) instructs users to always use the namespaced forms `/ceos-agents:pipeline-status` and `/ceos-agents:setup-mcp`, and (c) lists the 3 deprecated identifiers from v6.10.x → v7.0.0 (`/ceos-agents:status` → `/ceos-agents:pipeline-status`, `/ceos-agents:init` → `/ceos-agents:setup-mcp`, `/ceos-agents:create-pr` → `/ceos-agents:publish`).

**Scope:**
- New subsection in `README.md` (placement: after Installation section per Phase 2 Action 6).
- New subsection in `docs/guides/installation.md` (NEW subsection — Phase 2 Agent 2 finding F5 confirmed no existing Limitations/Caveats section; this is a fresh insertion).

---

## REQ-CHANGELOG-MIGRATION — CHANGELOG.md migration block

**EARS:** When the v7.0.0 release commit lands, `CHANGELOG.md` shall contain a top-level `## [7.0.0]` section (or equivalent project convention header) with a "Migration from v6.10.x to v7.0.0" subsection that includes (a) the 5 verbatim bullet points from the spec migration guide (in English; Czech variants from the spec are translated), (b) a lost-agency disclosure for `/create-pr` removal stating that the "PR-only with valid tracker reference" case is no longer supported and documenting the branch-rename workaround (Phase 3 D4 + open question 8), (c) a skill-not-found disclosure stating that users who type `/ceos-agents:status` or `/ceos-agents:init` will see Claude Code's standard skill-not-found error post-upgrade (Phase 3 D3 + open question 9), and (d) a state.json forward-compat note stating that in-flight v6.10.x pipelines continue to work because state.json schema is unchanged (Phase 3 R7 + open question 6).

**Scope (5 bullets from spec verbatim, translated to English):**
1. `Extra labels` config section removed → move any labels into `PR Rules → Labels`.
2. `/ceos-agents:status` → `/ceos-agents:pipeline-status` (short form `/status` collided with a Claude Code builtin).
3. `/ceos-agents:init` → `/ceos-agents:setup-mcp` (short form `/init` collided with a Claude Code builtin).
4. `/create-pr` removed → use `/publish` (auto-detects: when the branch contains an issue ID and the ticket exists, performs a tracker update; otherwise PR-only).
5. `Pause Limits` doc fixed — the section applies to all pipeline skills, not just `/autopilot` (no functional change, doc only).

**Plus the 3 disclosure lines** specified in (b)/(c)/(d) above.

---

## REQ-COUNTS — Doc count consistency

**EARS:** When the v7.0.0 release commit lands, every count-bearing line in the 5 anchor files (`CLAUDE.md`, `README.md`, `docs/reference/automation-config.md`, `docs/reference/skills.md`, `docs/architecture.md`) plus `docs/getting-started.md` (Phase 2 finding F7) shall display "28 skills" (not 29) and "18 optional config sections" (not 19), and the agent count "21 agents" shall remain unchanged everywhere.

**Scope (Phase 2 Q9 — exact file:line):**

"29 skills" → "28 skills":
- `CLAUDE.md:18`
- `README.md:262`
- `docs/reference/skills.md:3` (two occurrences on the same line)
- `docs/architecture.md:27` (`SKL[29 Skills]` → `SKL[28 Skills]`)
- `docs/getting-started.md:219`

"19 optional" → "18 optional":
- `CLAUDE.md:160`
- `README.md:221`
- `docs/reference/automation-config.md:9`

**No change required:**
- `plugin.json`, `marketplace.json` — no count strings.
- `examples/configs/*.md` — no occurrences.

---

## REQ-INVARIANTS — Cross-file invariants preserved

**EARS:** When the v7.0.0 release commit lands, the three CLAUDE.md "Cross-File Invariants" shall continue to hold: (1) license SPDX `"MIT"` consistent across `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and `LICENSE`; (2) maintainer email `filip.sabacky@ceosdata.com` consistent across `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`; (3) issue/PR templates byte-identical between `.gitea/` and `.github/` paired files (verified via `diff -q`).

**Scope:** No code edits expected; this REQ asserts the invariants are not broken by the rename/delete actions.

---

## REQ-NO-VERSION-BUMP — Pipeline shall NOT bump version

**EARS:** When the v7.0.0 forge pipeline executes Phases 5-9 and produces commits on `forge/v7.0.0`, the system shall NOT modify `.claude-plugin/plugin.json` `"version"`, `.claude-plugin/marketplace.json` `"version"`, or create any v7.0.0 git tag, and Phase 8 shall verify that no `"version"` field diff exists between `main` and the pipeline branch.

**Scope:**
- The user runs `/ceos-agents:version-bump` (or the project's manual procedure) AFTER the pipeline produces a clean Phase 8 verdict.
- This REQ exists to prohibit version-bump leakage — it has no positive scope.

---

## Phase 3 open-question resolution map

| Open question | Resolution location |
|---|---|
| 1. `/publish` Step 0 ordering: pre-pre-flight branch parse, then `tracker_needed`-gated MCP pre-flight | REQ-PUBLISH-AUTO-DETECT SC-1 |
| 2. error_type "unknown" disposition: 5-bucket enum, `unknown → FAIL` defensive default | REQ-PUBLISH-AUTO-DETECT SC-2 |
| 3. "Tracker registered but no get_issue-shaped tool found" → `error_type = unknown` → FAIL | REQ-PUBLISH-AUTO-DETECT SC-3 |
| 4. Publish Report `Tracker:` row format (3 exact strings) | REQ-PUBLISH-AUTO-DETECT SC-4 |
| 5. `/publish` interactive-only note (CI/cron path = `/autopilot`) | REQ-PUBLISH-AUTO-DETECT SC-5 |
| 6. State.json forward-compat note in migration guide | REQ-CHANGELOG-MIGRATION (d) |
| 7. Phase 8 empty-skills-dir invariant verification command | design.md §8 + AC-RENAME-STATUS-3 / AC-RENAME-INIT-3 |
| 8. Lost-agency disclosure for `/create-pr` removal in CHANGELOG | REQ-CHANGELOG-MIGRATION (b) |
| 9. Skill-not-found CHANGELOG note | REQ-CHANGELOG-MIGRATION (c) |
| 10. Workflow-router "Did you mean...?" prose (4 lines, deprecated names list) | design.md §5 + REQ-DEL-CREATE-PR/REQ-RENAME-* implicit; AC-DOCS-COLLISION-WARN-3 |
| 11. `/check-setup` deprecated-config WARN exit semantics: warn does NOT change exit code | design.md §4 + AC-CHANGELOG-MIGRATION-4 |

---

## REQ summary

11 REQs covering 6 release actions + 2 cross-cutting concerns (counts, invariants) + 3 governance constraints (no version bump, collision warn, changelog migration). No REQ extends beyond the 6 spec actions or relaxes the BREAKING-CHANGE classification (no aliases, stubs, or deprecation banners introduced).
