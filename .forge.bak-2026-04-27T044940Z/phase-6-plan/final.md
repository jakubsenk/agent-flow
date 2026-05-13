# Phase 6 Final: v7.0.0 Implementation Plan

## Overview

The v7.0.0 release is a BREAKING-CHANGE cleanup pipeline composed of **20 tasks across 4 waves**. Most tasks are mechanical edits (delete rows, rename identifiers, flip count strings) parallelizable within a wave; only **T-12** (`/publish` rewrite) is semantically substantive and needs `opus`. The pipeline strictly avoids version-bump leakage (REQ-NO-VERSION-BUMP) — `plugin.json`/`marketplace.json` `"version"` fields are off-limits. Wave 4 (T-20) executes `tests/harness/run-tests.sh` as the in-Phase-7 sanity gate; Phase 8 then runs the full verification command suite from `design.md` §8 against the resulting branch state.

Strategy: complete file-system-level changes (deletes + renames + new content) in **Wave 1** so all subsequent reference rewrites in **Wave 2** see the canonical paths. **Wave 3** then enumerates counts, collision warnings, CHANGELOG, and copies new test scenarios. **Wave 4** runs the harness.

---

## Task Manifest

### T-01: Delete `skills/create-pr/` directory

- **Wave:** 1
- **Model:** sonnet
- **Dependencies:** none
- **Scope (files touched):**
  - `skills/create-pr/SKILL.md` (DELETE)
  - any other files inside `skills/create-pr/` (verify and DELETE recursively)
- **Action:** `git rm -r skills/create-pr/`
- **Expected outcome:** directory absent from working tree and index
- **ACs satisfied:** AC-DEL-CREATE-PR-1
- **Phase 5 scenarios:** `v7.0.0-no-create-pr-skill.sh`
- **Verification:** `[ ! -d skills/create-pr ]`
- **Risk:** very low (mechanical)
- **Windows hazard:** post-delete verify `find skills -maxdepth 1 -mindepth 1 -type d -empty | wc -l` reports `0` (no orphan empty dir from `rm -rf` race)

---

### T-02: Rename `skills/status/` → `skills/pipeline-status/` + update frontmatter

- **Wave:** 1
- **Model:** sonnet
- **Dependencies:** none
- **Scope (files touched):**
  - directory rename via `git mv skills/status skills/pipeline-status`
  - `skills/pipeline-status/SKILL.md` frontmatter: `name: status` → `name: pipeline-status`
  - any in-skill self-referential prose where `name: status` or the bare skill name appears (read full file post-rename and edit)
- **Action:** `git mv skills/status skills/pipeline-status` then frontmatter edit
- **Expected outcome:** `skills/status/` absent; `skills/pipeline-status/SKILL.md` exists with `^name: pipeline-status$`
- **ACs satisfied:** AC-RENAME-STATUS-1, AC-RENAME-STATUS-2, AC-RENAME-STATUS-3
- **Phase 5 scenarios:** `v7.0.0-skill-rename-status.sh`, `v7.0.0-empty-skills-dir-invariant.sh`
- **Verification:** `[ ! -d skills/status ] && [ -d skills/pipeline-status ] && head -10 skills/pipeline-status/SKILL.md | grep -qE '^name: pipeline-status$'`
- **Risk:** low
- **Windows hazard:** MUST use `git mv` (not `mkdir + cp + rm`) per design.md §2.3; post-rename verify `find skills -maxdepth 1 -mindepth 1 -type d -empty | wc -l` reports `0`

---

### T-03: Rename `skills/init/` → `skills/setup-mcp/` + update frontmatter + 5 self-references

- **Wave:** 1
- **Model:** sonnet
- **Dependencies:** none
- **Scope (files touched):**
  - directory rename via `git mv skills/init skills/setup-mcp`
  - `skills/setup-mcp/SKILL.md` frontmatter: `name: init` → `name: setup-mcp`
  - `skills/setup-mcp/SKILL.md` lines 202, 215, 225, 263, 341 — self-references `/ceos-agents:init` → `/ceos-agents:setup-mcp` (per Phase 2 R4 Action 4)
- **Action:** `git mv skills/init skills/setup-mcp` then frontmatter + 5 in-file edits
- **Expected outcome:** `skills/init/` absent; `skills/setup-mcp/SKILL.md` exists with `^name: setup-mcp$`; no in-file self-references to `/ceos-agents:init`
- **ACs satisfied:** AC-RENAME-INIT-1, AC-RENAME-INIT-2, AC-RENAME-INIT-3
- **Phase 5 scenarios:** `v7.0.0-skill-rename-init.sh`, `v7.0.0-empty-skills-dir-invariant.sh`
- **Verification:** `[ ! -d skills/init ] && [ -d skills/setup-mcp ] && head -10 skills/setup-mcp/SKILL.md | grep -qE '^name: setup-mcp$' && ! grep -q '/ceos-agents:init' skills/setup-mcp/SKILL.md`
- **Risk:** low
- **Windows hazard:** `git mv` only (per design.md §2.3); post-rename empty-dir invariant check

---

### T-04: Update `skills/workflow-router/SKILL.md` — intent table + Step 3/4 prose + add "Did you mean...?" section

- **Wave:** 2
- **Model:** sonnet (semantic — intent table mutation + new prose authorship; sonnet sufficient because edits are pre-specified verbatim by design.md §5)
- **Dependencies:** T-01, T-02, T-03 (workflow-router refers to all 3 deprecated identifiers)
- **Scope (files touched):**
  - `skills/workflow-router/SKILL.md:15` — DELETE `create-pr` intent table row (`| Create a pull request | ceos-agents:create-pr | None | Yes |`)
  - `skills/workflow-router/SKILL.md:18` — `ceos-agents:status` → `ceos-agents:pipeline-status` in intent table row
  - `skills/workflow-router/SKILL.md:20` — `ceos-agents:init` → `ceos-agents:setup-mcp` in intent table row
  - `skills/workflow-router/SKILL.md:54` — Step 3 non-destructive list: `status` → `pipeline-status` (bare word in skill-name context)
  - `skills/workflow-router/SKILL.md:55` — Step 4 destructive list: remove `create-pr,`
  - APPEND new "Deprecated names" section per design.md §5.3 with 3 lines listing `ceos-agents:status` → `ceos-agents:pipeline-status`, `ceos-agents:init` → `ceos-agents:setup-mcp`, `ceos-agents:create-pr` → `ceos-agents:publish` and the phrase "did you mean" (verbatim from design.md §5.3)
- **Action:** sequential Edit calls, then Write (or Edit) to add the new section near end of Steps
- **Expected outcome:** intent table has neither stale `ceos-agents:status` nor `ceos-agents:init` nor `ceos-agents:create-pr` rows; Step 3/4 prose updated; new "Deprecated names" subsection contains all 3 deprecated identifiers and the phrase "did you mean"
- **ACs satisfied:** AC-RENAME-STATUS-5, AC-RENAME-STATUS-6, AC-DEL-CREATE-PR-7, AC-DEL-CREATE-PR-8, AC-DOCS-COLLISION-WARN-3, AC-DOCS-COLLISION-WARN-WORKFLOW-1
- **Phase 5 scenarios:** `v7.0.0-workflow-router-intent-table.sh`
- **Verification:** `grep -q 'ceos-agents:pipeline-status' skills/workflow-router/SKILL.md && grep -E 'NOT destructive.*pipeline-status' skills/workflow-router/SKILL.md && [ "$(grep -E '(ceos-agents:status|ceos-agents:init|ceos-agents:create-pr)' skills/workflow-router/SKILL.md | wc -l | tr -d ' ')" -ge "3" ] && ! grep -qE 'IS destructive.*create-pr,' skills/workflow-router/SKILL.md`
- **Risk:** medium — this is the ONLY file where deprecated identifiers must REMAIN (in the new Deprecated names section); accidentally over-cleaning would break AC-DOCS-COLLISION-WARN-WORKFLOW-1

---

### T-05: Replace `/ceos-agents:status` → `/ceos-agents:pipeline-status` in remaining active files (workflow-router excluded)

- **Wave:** 2
- **Model:** sonnet
- **Dependencies:** T-02 (depends on directory existing at new path so cross-references resolve when reading)
- **Scope (files touched, per Phase 2 R4 Action 3 + REQ-RENAME-STATUS):**
  - `docs/reference/skills.md:33` — Skill Index table row
  - `docs/reference/skills.md:193` — Related skills in `/fix-bugs` section
  - `docs/reference/skills.md:509` — section heading `### /status` → `### /pipeline-status`
  - `docs/reference/skills.md:516, 524` — example invocations
  - `docs/reference/skills.md:555, 584` — Related skills cross-refs
  - `docs/guides/troubleshooting.md:311`
  - `README.md:153` — skill table row
  - `CLAUDE.md:31` — skills enumeration (single-line edit; combine with T-06/T-07 changes if same line)
  - `tests/scenarios/skills-directory-structure.sh:54` — `EXPECTED_SKILLS` array element
  - `tests/scenarios/skills-frontmatter-check.sh:~90` — `READONLY_SKILLS` array element
  - `tests/scenarios/no-mcp-jargon-errors.sh:20` — path `skills/status/SKILL.md` → `skills/pipeline-status/SKILL.md`
- **Excluded (per binding contract):** `skills/workflow-router/SKILL.md` (handled in T-04 with positive prose), `.forge/`, `.forge.bak-*`, `docs/plans/`, `docs/superpowers/`, `CHANGELOG.md`
- **Action:** per-file Edit calls; for `CLAUDE.md:31` coordinate with T-06 and T-07 (same enumeration line)
- **Expected outcome:** zero matches for `ceos-agents:status\b` outside workflow-router; zero `/status\`` references in README/CLAUDE/skills.md
- **ACs satisfied:** AC-RENAME-STATUS-4, AC-RENAME-STATUS-7, AC-TEST-INVENTORY-4 (partial), AC-TEST-INVENTORY-5 (partial), AC-TEST-INVENTORY-6 (partial)
- **Phase 5 scenarios:** `v7.0.0-skill-rename-status.sh`
- **Verification:** `[ "$(grep -rn 'ceos-agents:status\b' --include='*.md' --exclude-dir=.forge --exclude-dir='.forge.bak-*' --exclude-dir=docs/plans --exclude-dir=docs/superpowers --exclude=CHANGELOG.md --exclude=skills/workflow-router/SKILL.md . | wc -l | tr -d ' ')" = "0" ] && grep -q '`/pipeline-status`' README.md && ! grep -qE '^\| \`/status\` \|' README.md`
- **Risk:** low — pure mechanical replacement
- **Coordination note:** `CLAUDE.md:31` is a single-line skills enumeration touched by T-05/T-06/T-07; **T-05 owns** the line edit (rename `/status` → `/pipeline-status`) but must preserve T-06 (rename `/init` → `/setup-mcp`) and T-07 (remove `/create-pr,`) outcomes. Implementation approach: after T-04..T-07 complete, **the final line state must reflect ALL three changes** — Phase 7 dispatcher must serialize T-05/T-06/T-07 on this single line (or have the agent perform all three edits as one operation)

---

### T-06: Replace `/ceos-agents:init` → `/ceos-agents:setup-mcp` in remaining active files (workflow-router excluded)

- **Wave:** 2
- **Model:** sonnet
- **Dependencies:** T-03 (depends on directory existing at new path)
- **Scope (files touched, per Phase 2 R4 Action 4 + REQ-RENAME-INIT):**
  - `core/config-reader.md:57` — `run /ceos-agents:init.` → `run /ceos-agents:setup-mcp.`
  - `core/mcp-preflight.md:36` — `or /ceos-agents:init` → `or /ceos-agents:setup-mcp`
  - `skills/check-setup/SKILL.md:68, 76`
  - `skills/pipeline-status/SKILL.md:60, 82` (former `skills/status/`)
  - `skills/onboard/SKILL.md:242`
  - `skills/implement-feature/SKILL.md:85`
  - `skills/create-backlog/SKILL.md:52`
  - `skills/scaffold/SKILL.md:180, 183, 188, 213, 217, 221, 1068, 1070, 1076, 1078, 1098` (11 sites)
  - `docs/reference/skills.md:29` — Skill Index table row + section heading rename
  - `docs/reference/skills.md:387, 391, 398-427` — Related skills + section heading + 5+ examples
  - `docs/getting-started.md:115, 125`
  - `docs/guides/installation.md:92`
  - `docs/guides/mcp-configuration.md:5, 52`
  - `docs/guides/troubleshooting.md:225`
  - `README.md:164` — skill table row
  - `CLAUDE.md:31` — skills enumeration (coordinate with T-05/T-07; see T-05 coordination note)
  - `tests/scenarios/skills-directory-structure.sh:43` — `EXPECTED_SKILLS` array
  - `tests/scenarios/skills-frontmatter-check.sh:~97` — `READONLY_SKILLS` array
  - `tests/scenarios/scaffold-mcp-checkpoint.sh:7`
  - `tests/scenarios/v6.10.0-dispatch-hook-install-surface.sh:17`
  - `tests/scenarios/v644-diagnostics-hardening.sh:19, 36, 67, 109, 375, 378` (6 sites)
- **Excluded:** `skills/workflow-router/SKILL.md` (handled in T-04), `.forge/`, `.forge.bak-*`, `docs/plans/`, `docs/superpowers/`, `CHANGELOG.md`. **Also exclude non-skill-name contexts:** `git init`, `npm init`, `forge init` literal occurrences MUST NOT be touched
- **Action:** per-file Edit calls; verify each match is in skill-name context before editing
- **Expected outcome:** zero matches for `ceos-agents:init\b` outside workflow-router
- **ACs satisfied:** AC-RENAME-INIT-4, AC-RENAME-INIT-5, AC-RENAME-INIT-6, AC-RENAME-INIT-7, AC-TEST-INVENTORY-4, AC-TEST-INVENTORY-5, AC-TEST-INVENTORY-10, AC-TEST-INVENTORY-11, AC-TEST-INVENTORY-12
- **Phase 5 scenarios:** `v7.0.0-skill-rename-init.sh`
- **Verification:** `[ "$(grep -rn 'ceos-agents:init\b' --include='*.md' --exclude-dir=.forge --exclude-dir='.forge.bak-*' --exclude-dir=docs/plans --exclude-dir=docs/superpowers --exclude=CHANGELOG.md --exclude=skills/workflow-router/SKILL.md . | wc -l | tr -d ' ')" = "0" ] && grep -q '/ceos-agents:setup-mcp' core/mcp-preflight.md && grep -q '/ceos-agents:setup-mcp' core/config-reader.md`
- **Risk:** medium-low — wide surface (33 sites across 17 files); requires per-occurrence inspection because `init` appears in non-skill contexts (`git init`, etc.); use `--include='*.md'` only and grep `/ceos-agents:init` not bare `init`

---

### T-07: Remove `/create-pr` references — replace with `/ceos-agents:publish` where appropriate (workflow-router excluded)

- **Wave:** 2
- **Model:** sonnet
- **Dependencies:** T-01 (deletion must be done so cross-refs are unambiguously stale)
- **Scope (files touched, per Phase 2 R4 Action 5 + REQ-DEL-CREATE-PR):**
  - `docs/reference/automation-config.md:19` — REMOVE `/create-pr,` from `PR Rules` Used-By column
  - `docs/reference/automation-config.md:20` — REMOVE `/create-pr,` from `PR Description Template` Used-By column
  - `docs/reference/skills.md:26` — DELETE `| Publishing | [/create-pr](#create-pr) |` row from Skill Index table
  - `docs/reference/skills.md:323-342` — DELETE entire `### /create-pr` section (~20 lines)
  - `docs/reference/skills.md:363` — REMOVE `/create-pr` from `Related skills` list in `### /publish` section
  - `README.md:148` — DELETE `/create-pr` skill table row
  - `CLAUDE.md:31` — REMOVE `/create-pr,` from skills enumeration (coordinate with T-05/T-06; see T-05 note)
  - `tests/scenarios/no-mcp-jargon-errors.sh:15` — REMOVE `"skills/create-pr/SKILL.md"` from `STANDARD_ERROR_FILES`
  - `tests/scenarios/skills-directory-structure.sh:36` — REMOVE `create-pr` from `EXPECTED_SKILLS`
  - `tests/scenarios/skills-frontmatter-check.sh:51` — REMOVE `create-pr` from `PIPELINE_SKILLS`; FC-5 count comment `12 pipeline` → `11 pipeline`
- **Excluded:** `skills/workflow-router/SKILL.md` (handled in T-04 — adds Deprecated names entry), `.forge/`, `.forge.bak-*`, `docs/plans/`, `docs/superpowers/`, `CHANGELOG.md`
- **Reword guidance:** Where existing prose describes "creates a PR" workflow generically (NOT skill-name reference), preserve as-is. Where prose says "use /create-pr to publish" or similar, change to "use /ceos-agents:publish" (auto-detect mode).
- **Action:** per-file Edit calls; combine with T-05/T-06 final state on `CLAUDE.md:31`
- **Expected outcome:** zero `ceos-agents:create-pr\b` matches outside workflow-router; zero `### /create-pr` heading in skills.md; zero `/create-pr` skill table row in README
- **ACs satisfied:** AC-DEL-CREATE-PR-2, AC-DEL-CREATE-PR-3, AC-DEL-CREATE-PR-4, AC-DEL-CREATE-PR-5, AC-DEL-CREATE-PR-6, AC-DEL-CREATE-PR-9, AC-DEL-CREATE-PR-10, AC-DEL-CREATE-PR-11
- **Phase 5 scenarios:** `v7.0.0-no-create-pr-skill.sh`
- **Verification:** `[ "$(grep -rn 'ceos-agents:create-pr\b' --include='*.md' --exclude-dir=.forge --exclude-dir='.forge.bak-*' --exclude-dir=docs/plans --exclude-dir=docs/superpowers --exclude=CHANGELOG.md --exclude=skills/workflow-router/SKILL.md . | wc -l | tr -d ' ')" = "0" ] && ! grep -qE '^\| \`/create-pr\` \|' README.md && ! grep -qE '^### /create-pr$' docs/reference/skills.md`
- **Risk:** low

---

### T-08: Remove `Extra labels` from `docs/reference/automation-config.md`

- **Wave:** 1
- **Model:** sonnet
- **Dependencies:** none
- **Scope (files touched):**
  - `docs/reference/automation-config.md:33` — DELETE Quick reference table row `| Extra labels | No | /fix-ticket, /fix-bugs, /implement-feature |`
  - `docs/reference/automation-config.md:332-339` — DELETE entire `### Extra labels` section body (heading + table, ~8 lines)
- **Action:** Edit calls per range
- **Expected outcome:** no `Extra labels` references in `docs/reference/automation-config.md`
- **ACs satisfied:** AC-DEL-EXTRA-LABELS-1 (partial)
- **Phase 5 scenarios:** `v7.0.0-no-extra-labels-section.sh`
- **Verification:** `! grep -q 'Extra labels' docs/reference/automation-config.md`
- **Risk:** very low

---

### T-09: Remove `Extra labels` from 2 config templates

- **Wave:** 1
- **Model:** sonnet
- **Dependencies:** none
- **Scope (files touched, per Phase 2 Q1 — only 2 of 8 templates contain `Extra labels`):**
  - `examples/configs/github-nextjs.md:104` — DELETE entire `### Extra labels (optional)` section
  - `examples/configs/redmine-oracle-plsql.md:182` — DELETE entire `### Extra labels (optional)` section
- **Excluded (no edits — Phase 2 verified zero matches):** `github-python-fastapi.md`, `github-dotnet.md`, `gitea-spring-boot.md`, `jira-react.md`, `youtrack-python.md`, `redmine-rails.md`
- **Action:** Edit calls per file (delete heading + section body)
- **Expected outcome:** zero `Extra labels` matches across `examples/configs/*.md`
- **ACs satisfied:** AC-DEL-EXTRA-LABELS-1 (partial)
- **Phase 5 scenarios:** `v7.0.0-no-extra-labels-section.sh`
- **Verification:** `! grep -rq 'Extra labels' examples/configs/`
- **Risk:** very low

---

### T-10: Remove `Extra labels` from agents/skills/CLAUDE.md/core (15 sites across 9 files)

- **Wave:** 1
- **Model:** sonnet
- **Dependencies:** none
- **Scope (files touched, per Phase 2 Q2 + REQ-DEL-EXTRA-LABELS):**
  - `core/config-reader.md:31` — DELETE parse rule (1 line)
  - `agents/publisher.md:69` — REWRITE `If Extra labels section exists, add those too.` → `Add labels from PR Rules section only.`
  - `skills/fix-ticket/SKILL.md:47` — DELETE bullet
  - `skills/fix-ticket/SKILL.md:638` — DELETE `Extra labels: ...` segment from publisher context string
  - `skills/fix-bugs/SKILL.md:42` — DELETE bullet
  - `skills/fix-bugs/SKILL.md:783` — DELETE segment
  - `skills/implement-feature/SKILL.md:35` — DELETE line
  - `skills/implement-feature/SKILL.md:599` — DELETE segment
  - `skills/check-setup/SKILL.md:56` — REMOVE `Extra labels,` from optional-section enumeration
  - `skills/migrate-config/SKILL.md:41` — REMOVE `Extra labels,` from migration loop list
  - `skills/onboard/SKILL.md:175` — DELETE menu item `[12] Extra labels — additional PR labels`
  - `skills/onboard/SKILL.md:204` — DELETE config summary line
  - `CLAUDE.md:149` — DELETE optional sections table row `| Extra labels | Labels | (none) |`
- **Excluded:** `CLAUDE.md:160` (count string — handled by T-16, NOT this task per requirements.md "Note: CLAUDE.md:160 count string '19 → 18' is governed by REQ-COUNTS")
- **Action:** per-file Edit calls
- **Expected outcome:** all 13 active locations cleared (test scenarios cleared in T-11)
- **ACs satisfied:** AC-DEL-EXTRA-LABELS-1 (partial), AC-DEL-EXTRA-LABELS-2, AC-DEL-EXTRA-LABELS-3
- **Phase 5 scenarios:** `v7.0.0-no-extra-labels-section.sh`
- **Verification:** `! grep -q 'Extra labels' agents/publisher.md && ! grep -q 'pr_rules\.extra_labels' core/config-reader.md && ! grep -q 'Extra labels' skills/fix-ticket/SKILL.md`
- **Risk:** very low — surgical deletes; one rewrite (publisher.md:69) needs care

---

### T-11: Update `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` (UPDATE — keep utility)

- **Wave:** 2
- **Model:** sonnet
- **Dependencies:** T-10 (CLAUDE.md must already be cleaned so the negative assertion passes)
- **Decision: UPDATE (not RETIRE).** Per anti-pattern guidance and DISAGREEMENT D resolution, the test still has utility — it asserts the OPTIONAL_SECTIONS array shape, which guards against accidental re-introduction. Updating preserves regression coverage; retiring would lose that.
- **Scope (files touched):**
  - `tests/scenarios/v6.9.0-bc-no-renamed-section.sh:25` — REMOVE `"Extra labels"` from `OPTIONAL_SECTIONS` array element list
  - `tests/scenarios/v6.9.0-bc-no-renamed-section.sh:47` — UPDATE mutation guard `[ "${#OPTIONAL_SECTIONS[@]}" -eq 19 ]` → `-eq 18`
  - `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` success message — update from referencing 19 to 18
  - Also: `tests/scenarios/config-reader-sections.sh:25` — REMOVE `"Extra labels"` from `OPTIONAL_SECTIONS` array (single line edit, same pattern)
- **Action:** Edit calls
- **Expected outcome:** both test files no longer reference `Extra labels`; mutation guard correctly asserts 18; success message consistent
- **ACs satisfied:** AC-DEL-EXTRA-LABELS-4, AC-DEL-EXTRA-LABELS-5, AC-TEST-INVENTORY-7, AC-TEST-INVENTORY-8
- **Phase 5 scenarios:** `v7.0.0-no-extra-labels-section.sh`
- **Verification:** `! grep -qF '"Extra labels"' tests/scenarios/v6.9.0-bc-no-renamed-section.sh && grep -qE '\-eq 18' tests/scenarios/v6.9.0-bc-no-renamed-section.sh && ! grep -qF '"Extra labels"' tests/scenarios/config-reader-sections.sh`
- **Risk:** low

---

### T-12: Rewrite `skills/publish/SKILL.md` — full Steps 0-9 per design.md §3.1 (OPUS)

- **Wave:** 1
- **Model:** **opus** (the only opus task in the pipeline — semantic logic, branch parsing, regex prose, 3-mode fork, 3 failure UX tiers)
- **Dependencies:** none for the file edit, but logically downstream of T-13 publisher.md edit (handled separately in T-13)
- **Scope (files touched):**
  - `skills/publish/SKILL.md` — full rewrite of Steps 0-9 per design.md §3.1
- **Required content (verbatim contract from design.md §3.1):**
  1. **Step 0 — Branch parse** (NEW, pre-pre-flight):
     - 0a: `branch_name = $(git branch --show-current)`; FAIL on detached HEAD with single-line `[ceos-agents][INFO] Cannot determine branch (detached HEAD). /publish requires an active branch.` (SC-12)
     - 0b: Read `Source Control → Branch naming` from Automation Config; if absent, emit `[ceos-agents][INFO] No Branch naming pattern configured; PR-only mode.`, set `issue_id = null`, `tracker_needed = false`, jump to Step 3 (SC-10)
     - 0c: Identify `pre_prefix` (literal text preceding `{issue-id}`); use `sed 's/{issue-id}.*//'` idiom; explicit prose disclaiming "split at first delimiter" approach (SC-11)
     - 0d: Apply CANONICAL extraction regex `^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)` against residue (`pre_prefix` stripped); show Bash idiom with `BASH_REMATCH[1]`; document path-traversal defense `^\.+$` (defensive secondary check); include the 6-tracker coverage table; include all 6 worked examples (per design.md §3.1 Step 0d): `fix/PROJ-123-fix-crash` → `PROJ-123`, `feature/PROJ-456` → `PROJ-456`, `chore/refactor-foo` → `null`, `fix/123-numeric-id` → `123`, `fix/#42-fix` → `#42`, `feature/ABC_DEF-789` → `ABC_DEF-789`
     - 0e: Set `tracker_needed = (issue_id != null)`; if false → mode `pr-only-no-id`, emit single-line `[ceos-agents][INFO] Branch '{branch_name}' does not match the configured Branch naming pattern. Creating PR without tracker contact.` (SC-8), jump to Step 3
  2. **Step 1 — MCP pre-flight** (RENAMED from current Step 0; GATED on `tracker_needed == true`)
  3. **Step 2 — Tracker lookup** (GATED): cite `core/mcp-detection.md:28-34, 36, 58-87`; closed 5-bucket enum `{tls, auth, not_found, timeout, unknown}` (SC-2); 3 outcome modes `full-publish` / `pr-only-404` / FAIL; "prefix has tools but no `get_issue`-shaped" → `unknown` → FAIL (SC-3)
  4. **Step 3 — Common pre-publish** (zero-commits early-stop with INFO `No changes to publish — branch has no commits above {base_branch}.`; existing-PR check)
  5. **Step 4 — Read Type from Automation Config** (UNCHANGED)
  6. **Step 5 — Dispatch publisher agent (haiku, Task)** with context including `mode = {mode}` and `issue_id = {issue_id or 'none'}`
  7. **Step 6 — Tracker state + comment (CONDITIONAL on mode)**: only on `full-publish`; PR-only modes skip with INFO log
  8. **Step 7 — Webhook (UNCHANGED)**: `pr-created` event in all non-FAIL modes; `issue_id` empty when PR-only
  9. **Step 8 — Publish Report**: 3 exact `Tracker:` row strings (SC-4) — in publisher agent (covered by T-13 in agents/publisher.md, but skill prose must reference the contract)
  10. **Step 9 — Display result (UNCHANGED)**
  11. **Operator note** (SC-5): `/publish is interactive-only — ... For headless / batch publishing, use /ceos-agents:autopilot.`
  12. **FAIL tier block** (SC-6): full `[ceos-agents] 🔴 Pipeline Block` template with `Skill: /ceos-agents:publish`, 4-step Recommendation list including branch-rename workaround
  13. **404 WARN tier** (SC-7): single logical line `[ceos-agents][WARN] Branch '{branch}' contains issue ID pattern '{issue_id}' but no matching ticket was found in {tracker_type}. Creating PR without tracker update.` — emitted as one `echo` invocation
- **Action:** Read existing `skills/publish/SKILL.md` (37 lines), Write full replacement
- **Expected outcome:** rewritten skill contains all required tokens for AC verification (regex, 3 modes, 5 error_types, single-line WARN/INFO messages, `Skill:` block field, citations, operator note)
- **ACs satisfied:** AC-PUBLISH-AUTO-DETECT-1 through AC-PUBLISH-AUTO-DETECT-15, AC-PUBLISH-AUTO-DETECT-EXTRACTION-1, -2, -3, -4, -5, AC-PUBLISH-AUTO-DETECT-ZERO-COMMITS (21 ACs)
- **Phase 5 scenarios:** `v7.0.0-publish-auto-detect-issue-found.sh`, `v7.0.0-publish-auto-detect-issue-404.sh`, `v7.0.0-publish-auto-detect-tracker-down.sh`, `v7.0.0-publish-no-issue-id-pr-only.sh`, `v7.0.0-publish-extraction-regex.sh`
- **Verification:** `grep -qE '^### Step 0' skills/publish/SKILL.md && grep -q 'tracker_needed' skills/publish/SKILL.md && grep -qE '\[A-Za-z\]\[A-Za-z0-9_\]\*-\[0-9\]\+' skills/publish/SKILL.md && grep -q '"unknown"' skills/publish/SKILL.md && grep -q 'full-publish' skills/publish/SKILL.md && grep -q 'pr-only-404' skills/publish/SKILL.md && grep -q 'pr-only-no-id' skills/publish/SKILL.md && grep -qE '\[ceos-agents\]\[WARN\].*contains issue ID pattern' skills/publish/SKILL.md && grep -qE 'detached HEAD' skills/publish/SKILL.md && grep -q 'autopilot' skills/publish/SKILL.md`
- **Risk:** highest in pipeline — semantic prose authorship; opus needed for nuanced regex coverage table + 6 worked examples + 4 UX tiers in single contract document

---

### T-13: Update `agents/publisher.md` — add `Tracker:` row contract + final pass

- **Wave:** 2
- **Model:** sonnet
- **Dependencies:** T-12 (publisher.md report contract must align with `/publish` skill mode field); T-10 (already removed `Extra labels` text at line 69)
- **Scope (files touched):**
  - `agents/publisher.md` §82-87 (Publish Report area) — ADD `Tracker:` row contract with the 3 exact strings:
    - `Tracker: Updated → For Review` (mode `full-publish`)
    - `Tracker: Skipped — issue ID '{issue_id}' not found in {tracker_type}` (mode `pr-only-404`)
    - `Tracker: Skipped — no issue ID in branch name` (mode `pr-only-no-id`)
  - VERIFY `agents/publisher.md:69` no longer contains `Extra labels` (ensured by T-10) — if T-10 is incomplete, add it here defensively
  - VERIFY publisher behavior aligns with `/publish` Step 5 dispatch (publisher only invoked on Full publish branch in design — but publisher AGENT prose may run in all 3 modes since it composes the report)
- **Action:** Edit calls in §82-87 area
- **Expected outcome:** `agents/publisher.md` contains all 3 exact `Tracker:` row strings; `Extra labels` reference absent
- **ACs satisfied:** AC-PUBLISH-AUTO-DETECT-6, AC-DEL-EXTRA-LABELS-3 (defensive)
- **Phase 5 scenarios:** `v7.0.0-publish-auto-detect-issue-found.sh` (implicit)
- **Verification:** `grep -q 'Tracker: Updated → For Review' agents/publisher.md && grep -q "Tracker: Skipped — issue ID" agents/publisher.md && grep -q 'Tracker: Skipped — no issue ID in branch name' agents/publisher.md && ! grep -q 'Extra labels' agents/publisher.md`
- **Risk:** low

---

### T-14: Fix `Pause Limits` Used-By column in `docs/reference/automation-config.md:40`

- **Wave:** 1
- **Model:** sonnet
- **Dependencies:** none
- **Scope (files touched):**
  - `docs/reference/automation-config.md:40` — change `| Pause Limits | No | /autopilot |` → `| Pause Limits | No | /fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot, /resume-ticket |`
- **Excluded:** `docs/reference/automation-config.md:460-477` (section body already accurate per Phase 2 R3); `docs/reference/automation-config.md:628` (HTML comment, optional, NOT in REQ scope); `CLAUDE.md` Pause Limits mention (does not enumerate consumers, no edit needed)
- **Action:** Edit single-line replace
- **Expected outcome:** Quick reference row for `Pause Limits` lists all 6 lifecycle participants
- **ACs satisfied:** AC-PAUSE-LIMITS-DOC-1, AC-PAUSE-LIMITS-DOC-2
- **Phase 5 scenarios:** `v7.0.0-pause-limits-mapping.sh`
- **Verification:** `grep -E '^\| Pause Limits \| No \| /fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot, /resume-ticket \|' docs/reference/automation-config.md && ! grep -E '^\| Pause Limits \| No \| /autopilot \|$' docs/reference/automation-config.md`
- **Risk:** very low — single-line surgical edit

---

### T-15: Update count "29 skills" → "28 skills" in 5 anchor files + getting-started

- **Wave:** 3
- **Model:** sonnet
- **Dependencies:** T-01, T-02, T-03 (filesystem skill count must equal 28 to validate)
- **Scope (files touched, per design.md §6 + Phase 2 Q9 + F7):**
  - `CLAUDE.md:18` — `29 skills (slash commands, including workflow-router)` → `28 skills (slash commands, including workflow-router)`
  - `README.md:262` — `All 29 skills — syntax, flags, examples` → `All 28 skills — syntax, flags, examples`
  - `docs/reference/skills.md:3` — TWO occurrences on same line: `all 29 skills ... All 29 ceos-agents skills` → `all 28 skills ... All 28 ceos-agents skills`
  - `docs/architecture.md:27` — `SKL[29 Skills]` → `SKL[28 Skills]`
  - `docs/getting-started.md:219` — `Explore all 29 skills` → `Explore all 28 skills`
- **Action:** Edit calls per file (use Edit `replace_all=true` only where safe; otherwise individual edits)
- **Expected outcome:** all 5 anchors plus getting-started show 28 skills consistently
- **ACs satisfied:** AC-COUNTS-1, AC-COUNTS-3 (partial — 28 skills part), AC-COUNTS-4, AC-COUNTS-6, AC-COUNTS-7, AC-COUNTS-8 (filesystem invariant), AC-COUNTS-10 (empty-dir invariant)
- **Phase 5 scenarios:** `v7.0.0-doc-count-28-skills.sh`, `v7.0.0-empty-skills-dir-invariant.sh`
- **Verification:** `grep -qF '28 skills' CLAUDE.md && ! grep -qE '\b29 skills\b' CLAUDE.md && grep -qF '28 skills' README.md && grep -qF 'all 28 skills' docs/reference/skills.md && grep -qF 'SKL[28 Skills]' docs/architecture.md && grep -qF 'all 28 skills' docs/getting-started.md && [ "$(find skills -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')" = "28" ]`
- **Risk:** very low

---

### T-16: Update count "19 optional config sections" → "18 optional config sections"

- **Wave:** 3
- **Model:** sonnet
- **Dependencies:** T-08 (Extra labels removed from automation-config.md), T-10 (removed from CLAUDE.md table)
- **Scope (files touched, per Phase 2 Q9):**
  - `CLAUDE.md:160` — `There are 19 optional config sections in total.` → `There are 18 optional config sections in total.`
  - `README.md:221` — `**19 optional sections** cover ..., labels, ...` → `**18 optional sections** cover ...` (also remove "labels" from the prose enumeration since the section is gone)
  - `docs/reference/automation-config.md:9` — `19 optional sections` → `18 optional sections`
- **Excluded (per Phase 2 Q9):** `plugin.json`, `marketplace.json` (no count strings); `docs/architecture.md` (no "19 optional" string); `examples/configs/*.md` (no occurrences)
- **Action:** Edit calls per file
- **Expected outcome:** all 3 count-bearing files show 18; no stale 19
- **ACs satisfied:** AC-COUNTS-2, AC-COUNTS-3 (partial — 18 optional part), AC-COUNTS-5
- **Phase 5 scenarios:** `v7.0.0-doc-count-18-config-sections.sh`
- **Verification:** `grep -qF '18 optional config sections in total' CLAUDE.md && ! grep -qF '19 optional config sections in total' CLAUDE.md && grep -qF '18 optional sections' README.md && ! grep -qE '\b19 optional sections\b' README.md && grep -qF '18 optional sections' docs/reference/automation-config.md`
- **Risk:** very low

---

### T-17: Add slash-command collision warning subsection to README.md and docs/guides/installation.md

- **Wave:** 3
- **Model:** sonnet
- **Dependencies:** T-02, T-03, T-04 (renames must be complete + workflow-router updated so the warning lists the canonical new identifiers)
- **Scope (files touched):**
  - `README.md` — INSERT new H3 subsection `### Slash command collision with Claude Code builtins` after the Installation section, with content per design.md §4.4 (mention `/status` and `/init` collide with Claude Code builtins; recommend `/ceos-agents:pipeline-status` and `/ceos-agents:setup-mcp`; cross-reference the migration table inserted by T-18)
  - `docs/guides/installation.md` — INSERT NEW H3 subsection (per Phase 2 Agent 2 finding F5 — no existing Limitations section), with similar content per design.md §4.4 (slightly different prose)
  - **ALSO** insert per design.md §4.2 a "Renames and removals — v6.10.x → v7.0.0" table in `README.md` (4 rows for status, init, create-pr, Extra labels) near the new collision-warning subsection
- **Action:** Edit calls (INSERT after Installation section anchor)
- **Expected outcome:** both README and installation.md contain H2/H3 subsection mentioning "collision" / "slash command" / "builtin"; both name `/ceos-agents:pipeline-status` and `/ceos-agents:setup-mcp`
- **ACs satisfied:** AC-DOCS-COLLISION-WARN-1, AC-DOCS-COLLISION-WARN-2
- **Phase 5 scenarios:** `v7.0.0-readme-collision-warning.sh`
- **Verification:** `grep -qE '^#{2,3} .*([Ss]lash.*[Cc]ommand|[Cc]ollision|[Bb]uiltin)' README.md && grep -qE 'collide.*Claude Code|builtin' README.md && grep -q '/ceos-agents:pipeline-status' README.md && grep -q '/ceos-agents:setup-mcp' README.md && grep -qE '^#{2,3} .*([Ss]lash.*[Cc]ommand|[Cc]ollision|[Bb]uiltin)' docs/guides/installation.md && grep -q '/ceos-agents:pipeline-status' docs/guides/installation.md && grep -q '/ceos-agents:setup-mcp' docs/guides/installation.md`
- **Risk:** low — pure insertion

---

### T-18: Add `## [7.0.0]` section + Migration block to CHANGELOG.md + insert `/check-setup` deprecated-config detector

- **Wave:** 3
- **Model:** sonnet
- **Dependencies:** T-01..T-13 conceptually (CHANGELOG cites all 4 breaking actions); concrete dependency is on Wave 1 + Wave 2 completion
- **Scope (files touched):**
  - `CHANGELOG.md` — INSERT new `## [7.0.0] — Unreleased` block at top (above v6.10.0 entry) per design.md §4.1 verbatim. Must include:
    - `### BREAKING CHANGES` subsection with 5 bullets (Extra labels, /status rename, /init rename, /create-pr removal + auto-detect description, Pause Limits doc fix)
    - `### Migration from v6.10.x to v7.0.0` subsection with 5 numbered bullets (verbatim English from design.md §4.1)
    - `### State.json forward-compatibility` paragraph (REQ-CHANGELOG-MIGRATION (d))
    - `### Skill-not-found behavior` paragraph (REQ-CHANGELOG-MIGRATION (c))
    - `### Counts after v7.0.0` table (21 agents, 28 skills, 16 core, 18 optional, 8 templates)
    - LOST AGENCY DISCLOSURE inside migration bullet 4 (REQ-CHANGELOG-MIGRATION (b)) — branch-rename workaround: e.g., `chore/refactor-foo` instead of `fix/PROJ-123-foo`
  - `skills/check-setup/SKILL.md` — INSERT `## Deprecated v6.x config detection` snippet (per design.md §4.3) late in the existing scan loop, before final exit-code computation. Snippet emits `[WARN] Deprecated config section: ### Extra labels` line if user CLAUDE.md has `### Extra labels` heading. Exit code MUST stay 0 (warn-only — no exit 1, no FAIL, no return 1, no fail()).
- **Action:** Edit `CHANGELOG.md` (INSERT at top); Edit `skills/check-setup/SKILL.md` (INSERT before exit-code block)
- **Expected outcome:** `## [7.0.0]` heading exists at top of CHANGELOG; Migration subsection exists with all 5 bullets + 3 disclosures; `/check-setup` has the deprecated-detector snippet that does NOT exit non-zero
- **ACs satisfied:** AC-CHANGELOG-MIGRATION-1 through AC-CHANGELOG-MIGRATION-7 (7 ACs)
- **Phase 5 scenarios:** `v7.0.0-changelog-migration-guide.sh`
- **Verification:** `grep -qE '^## \[7\.0\.0\]' CHANGELOG.md && grep -qE '^### Migration from v6\.10\.x to v7\.0\.0' CHANGELOG.md && grep -qE 'Extra labels.*PR Rules' CHANGELOG.md && grep -qE 'pipeline-status' CHANGELOG.md && grep -qE 'setup-mcp' CHANGELOG.md && grep -qE '/create-pr.*removed' CHANGELOG.md && grep -qE 'Pause Limits.*pipeline skills' CHANGELOG.md && grep -qE 'Lost agency|opt out.*tracker|branch-rename workaround|non-matching branch' CHANGELOG.md && grep -qE 'skill-not-found|standard skill-not-found|no aliasing' CHANGELOG.md && grep -qE 'state\.json.*unchanged|forward-compat|in-flight pipelines' CHANGELOG.md && grep -qE 'Deprecated.*config|deprecated v6\.x' skills/check-setup/SKILL.md && grep -qE '\[WARN\].*Extra labels' skills/check-setup/SKILL.md && ! grep -E '\[WARN\].*Extra labels' skills/check-setup/SKILL.md | grep -qE 'exit 1|FAIL|fail\(\)|return 1'`
- **Risk:** medium — long content insertion; verify all 7 ACs match before declaring done
- **No version bump:** This task does NOT touch `plugin.json` or `marketplace.json` — REQ-NO-VERSION-BUMP enforced. The CHANGELOG `[7.0.0] — Unreleased` header is the only "version-naming" artifact in the pipeline.

---

### T-19: Copy 18 v7.0.0-*.sh scenarios from `.forge/phase-5-tdd/tests/` to `tests/scenarios/` + update existing scenarios per Phase 2 R8

- **Wave:** 3
- **Model:** sonnet
- **Dependencies:** none for the copy; logically Wave 1+2 should be done so the new tests can execute meaningfully (they can be added before, but T-20 will run them)
- **Scope (files touched):**
  - **NEW (copy from `.forge/phase-5-tdd/tests/` per Phase 5 manifest):**
    1. `tests/scenarios/v7.0.0-no-extra-labels-section.sh`
    2. `tests/scenarios/v7.0.0-skill-rename-status.sh`
    3. `tests/scenarios/v7.0.0-skill-rename-init.sh`
    4. `tests/scenarios/v7.0.0-no-create-pr-skill.sh`
    5. `tests/scenarios/v7.0.0-publish-auto-detect-issue-found.sh`
    6. `tests/scenarios/v7.0.0-publish-auto-detect-issue-404.sh`
    7. `tests/scenarios/v7.0.0-publish-auto-detect-tracker-down.sh`
    8. `tests/scenarios/v7.0.0-publish-no-issue-id-pr-only.sh`
    9. `tests/scenarios/v7.0.0-publish-extraction-regex.sh`
    10. `tests/scenarios/v7.0.0-doc-count-28-skills.sh`
    11. `tests/scenarios/v7.0.0-doc-count-18-config-sections.sh`
    12. `tests/scenarios/v7.0.0-pause-limits-mapping.sh`
    13. `tests/scenarios/v7.0.0-changelog-migration-guide.sh`
    14. `tests/scenarios/v7.0.0-readme-collision-warning.sh`
    15. `tests/scenarios/v7.0.0-cross-file-invariants.sh`
    16. `tests/scenarios/v7.0.0-workflow-router-intent-table.sh`
    17. `tests/scenarios/v7.0.0-no-version-bump.sh`
    18. `tests/scenarios/v7.0.0-empty-skills-dir-invariant.sh`
  - **UPDATE (existing scenarios per Phase 2 Q8 / design.md §7):**
    1. `tests/scenarios/regression-skill-count-29.sh` — line 14: `-ne 29` → `-ne 28`
    2. `tests/scenarios/ac-v68-doc-skill-count-29.sh` — flip polarity: line 15 (positive) → `28 skills`; line 21 (negative) → `29 skills`
    3. `tests/scenarios/v6.9.0-doc-count-drift.sh` — **6 edits per Phase 2 DISAGREEMENT D resolution**:
       - Lines 42-45: positive flip `'19 optional config sections in total'` → `'18 optional config sections in total'`
       - Lines 55-58: negative flip — reject `'19 optional config sections in total'` (was `'18 optional...'`)
       - Line 72: `[ "$skills_count" -eq 29 ]` → `-eq 28`
       - Line 79: `[ "$optional_count" -eq 19 ]` → `-eq 18`
       - Line 84 (fallback prose): `'19 optional config sections in total'` → `'18 optional config sections in total'`
       - Line 89 (PASS message): `19 optional, 29 skills` → `18 optional, 28 skills`
    4. `tests/scenarios/skills-directory-structure.sh` — line 36: remove `create-pr`; line 43: `init`→`setup-mcp`; line 54: `status`→`pipeline-status` (overlaps with T-05/T-06/T-07 — coordinate; T-19 owns the final state of this file)
    5. `tests/scenarios/skills-frontmatter-check.sh` — line 51: remove `create-pr`; ~line 90: `status`→`pipeline-status`; ~line 97: `init`→`setup-mcp`; FC-5 count comment `12 pipeline` → `11 pipeline`; FC-6 entries renamed (overlaps with T-05/T-06/T-07; T-19 owns final state)
    6. `tests/scenarios/no-mcp-jargon-errors.sh` — line 15: remove `skills/create-pr/SKILL.md`; line 20: `skills/status/SKILL.md` → `skills/pipeline-status/SKILL.md` (overlaps with T-05/T-07; T-19 owns final state)
    7. `tests/scenarios/v6.9.0-arch-freshness-refresh-on-release.sh` — lines 18-28: flip polarity `SKL[29 Skills]` ↔ `SKL[28 Skills]` (positive flip + negative flip)
    8. `tests/scenarios/scaffold-mcp-checkpoint.sh` — line 7: `skills/init/SKILL.md` → `skills/setup-mcp/SKILL.md`
    9. `tests/scenarios/v6.10.0-dispatch-hook-install-surface.sh` — line 17: `skills/init/SKILL.md` → `skills/setup-mcp/SKILL.md`
    10. `tests/scenarios/v644-diagnostics-hardening.sh` — lines 19, 36, 67, 109, 375, 378: 6 occurrences `skills/init/SKILL.md` → `skills/setup-mcp/SKILL.md`
    11. `tests/scenarios/config-reader-sections.sh` — line 25: remove `"Extra labels"` (already in T-11 scope; T-19 verifies)
    12. `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` — array + mutation guard updates (already in T-11 scope; T-19 verifies)
- **Coordination note:** Tests #4, #5, #6, #11, #12 above overlap with T-05/T-06/T-07/T-11. **Resolution:** T-05/T-06/T-07/T-11 do their portion of these edits (per their explicit scope); T-19 verifies the final state and applies any missed edits. To avoid race, Phase 7 dispatcher must serialize T-11 → T-19 within Wave 2/3 boundary. Recommended: T-19 owns "verify and complete" — it ensures the final post-Wave state matches AC-TEST-INVENTORY-1..12 exactly.
- **NO-CHANGE scenarios** (verify they still pass):
  - `tests/scenarios/ac-v68-doc-optional-sections-18.sh` — regex `(18\|19) optional` accepts 18, no change needed
  - `tests/scenarios/xref-command-count.sh` — dynamic count, auto-corrects
  - `tests/scenarios/v6.9.0-cross-file-invariants.sh` — tests invariants, not counts
- **Action:** `cp` for new scenarios; per-file Edit calls for updates
- **Expected outcome:** 18 new test scenarios in `tests/scenarios/` with v7.0.0-* prefix; all 12 UPDATE scenarios reflect new counts/paths
- **ACs satisfied:** AC-TEST-INVENTORY-1 through AC-TEST-INVENTORY-15 (15 ACs)
- **Phase 5 scenarios:** all 18 new ones become live in `tests/scenarios/`
- **Verification:** `[ "$(ls tests/scenarios/v7.0.0-*.sh | wc -l | tr -d ' ')" = "18" ] && grep -E '\-ne 28' tests/scenarios/regression-skill-count-29.sh && grep -qF '18 optional config sections in total' tests/scenarios/v6.9.0-doc-count-drift.sh && grep -qF 'SKL[28 Skills]' tests/scenarios/v6.9.0-arch-freshness-refresh-on-release.sh && [ "$(grep -cF 'skills/setup-mcp/SKILL.md' tests/scenarios/v644-diagnostics-hardening.sh)" = "6" ]`
- **Risk:** medium — large surface; coordination needed across Wave 2 tasks

---

### T-20: Run `bash tests/harness/run-tests.sh` from repo root + record output

- **Wave:** 4 (FINAL — gate task)
- **Model:** sonnet
- **Dependencies:** ALL of Wave 1 + Wave 2 + Wave 3 (T-01..T-19)
- **Scope:**
  - Execute `bash tests/harness/run-tests.sh` from repo root
  - Capture full output (stdout + stderr) to a file under `.forge/phase-7-execute/` (e.g., `harness-output.log`)
  - Parse PASS/FAIL/SKIP counts; record in completion artifact
  - **Expected baseline:** v6.10.0 had 203/190/0/13 (total/PASS/FAIL/SKIP). v7.0.0 expected: ~208 total (190 retained + 18 new). FAIL count target = 0.
- **Action:** `bash tests/harness/run-tests.sh > harness-output.log 2>&1; tail -50 harness-output.log; cat completion-summary.txt`
- **Expected outcome:** harness exits 0 (or with documented expected SKIPs); FAIL count = 0; PASS count >= 190 + 18 new functional checks
- **ACs satisfied:** none directly — this is the in-Phase-7 sanity gate; Phase 8 runs the full AC verification suite from `design.md` §8 separately
- **Phase 5 scenarios:** all 18 new + all 12 updated existing run via the harness
- **Verification:** `bash tests/harness/run-tests.sh; echo "exit=$?"`
- **Risk:** medium — if harness fails, Phase 7 must loop back to fix the failing tasks before Phase 8

---

## Dependency Graph

```
WAVE 1 — parallel (no inter-task dependencies)
─────────────────────────────────────────────────
T-01 (delete create-pr)            ─┐
T-02 (rename status→pipeline-status) ─┤
T-03 (rename init→setup-mcp)        ─┤
T-08 (Extra labels in automation-config.md) ─┤
T-09 (Extra labels in 2 templates)         ─┼── all parallel
T-10 (Extra labels in agents/skills/CLAUDE) ─┤
T-12 (publish rewrite — opus, semantic)    ─┤
T-14 (Pause Limits doc fix)               ─┘

WAVE 2 — sequenced after Wave 1
────────────────────────────────────────────────
T-04 (workflow-router edits)        ← T-01, T-02, T-03
T-05 (status refs cleanup)          ← T-02
T-06 (init refs cleanup)            ← T-03
T-07 (create-pr refs cleanup)       ← T-01
T-11 (Extra labels test scenarios)  ← T-10
T-13 (publisher.md final pass)      ← T-12, T-10

  Coordination edge: T-05, T-06, T-07 all touch CLAUDE.md:31 (skills enumeration line)
  → MUST serialize on this single line OR have one agent perform all 3 edits in one pass
  → Recommendation: dispatcher serializes T-05 → T-06 → T-07 within Wave 2

WAVE 3 — sequenced after Wave 2
────────────────────────────────────────────────
T-15 (count 28 skills)             ← T-01, T-02, T-03 (filesystem invariant)
T-16 (count 18 optional sections)  ← T-08, T-10
T-17 (collision warnings)          ← T-02, T-03, T-04
T-18 (CHANGELOG + check-setup)     ← T-01..T-13 (cites all 4 breaking actions; deprecated-detector targets Extra labels)
T-19 (copy + update test scenarios) ← T-11 (overlap on 2 files); also coordinates with T-05/T-06/T-07 on shared test files

WAVE 4 — final gate (sequential, ALL prior)
────────────────────────────────────────────────
T-20 (run harness)                 ← T-01..T-19 (all)
```

### Edge enumeration (acyclic verification)

```
T-04 ← {T-01, T-02, T-03}
T-05 ← {T-02}
T-06 ← {T-03}
T-07 ← {T-01}
T-11 ← {T-10}
T-13 ← {T-12, T-10}
T-15 ← {T-01, T-02, T-03}
T-16 ← {T-08, T-10}
T-17 ← {T-02, T-03, T-04}
T-18 ← {T-01, T-02, T-03, T-04, T-05, T-06, T-07, T-08, T-09, T-10, T-11, T-12, T-13}
T-19 ← {T-11}  (overlap-only — file-level coordination, see note above)
T-20 ← {T-01..T-19} (all 19 prior)
```

### Acyclicity proof

Topological sort levels (each task can only depend on tasks in earlier levels):

- **Level 1 (Wave 1):** T-01, T-02, T-03, T-08, T-09, T-10, T-12, T-14 — depend only on the empty initial state
- **Level 2 (Wave 2):** T-04, T-05, T-06, T-07, T-11, T-13 — all dependencies are in Level 1
- **Level 3 (Wave 3):** T-15, T-16, T-17, T-18, T-19 — all dependencies are in Levels 1-2
- **Level 4 (Wave 4):** T-20 — dependencies span Levels 1-3

No edge points from a higher level to a lower level → DAG is acyclic. ✓

---

## Wave Plan

### Wave 1 (Parallel, ~10-15 min wall-clock with parallelism)

T-01 (delete create-pr), T-02 (rename status), T-03 (rename init), T-08 (Extra labels in automation-config), T-09 (Extra labels in 2 templates), T-10 (Extra labels in 9 files), T-12 (publish rewrite — **opus**), T-14 (Pause Limits Used-By column).

8 tasks, all parallelizable. T-12 is the heavy one (~30K tokens, opus); the rest are mechanical sonnet edits.

### Wave 2 (Sequential after Wave 1, ~5-8 min)

T-04 (workflow-router 5 edits + new "Deprecated names" section), T-05 (status refs cleanup), T-06 (init refs cleanup), T-07 (create-pr refs cleanup), T-11 (Extra labels test scenarios), T-13 (publisher.md final pass).

6 tasks. T-05/T-06/T-07 must serialize on `CLAUDE.md:31` (single enumeration line); other edits parallelizable.

### Wave 3 (Sequential after Wave 2, ~5-8 min)

T-15 (count 28 skills, 5 anchor files), T-16 (count 18 optional sections, 3 files), T-17 (collision warnings + migration table in README + installation.md), T-18 (CHANGELOG `## [7.0.0]` + Migration block + check-setup deprecated-detector), T-19 (copy 18 v7.0.0-*.sh scenarios + update 12 existing scenarios).

5 tasks, partially parallelizable (T-15, T-16 are independent from T-17, T-18; T-19 overlaps with prior tasks but Phase 7 should serialize it last to verify final state).

### Wave 4 (Final sequential gate)

T-20 (`bash tests/harness/run-tests.sh` from repo root; record harness output; expected: PASS >= 190+18, FAIL = 0).

---

## Critical Implementation Notes

1. **Workflow-router exception (binding contract).** Per Phase 4 spec / design.md §5.3 / formal-criteria.md AC-DOCS-COLLISION-WARN-WORKFLOW-1, `skills/workflow-router/SKILL.md` legitimately RETAINS the 3 deprecated identifiers (`ceos-agents:status`, `ceos-agents:init`, `ceos-agents:create-pr`) inside a new "Deprecated names" section that T-04 must ADD. The deprecated-identifier sanity greps in AC-RENAME-STATUS-4 / AC-RENAME-INIT-4 / AC-DEL-CREATE-PR-2 use `--exclude=skills/workflow-router/SKILL.md`, but **Phase 7 must verify the prose IS there** (positive check via AC-DOCS-COLLISION-WARN-WORKFLOW-1 and AC-DOCS-COLLISION-WARN-3). Failure mode to guard against: T-04 deletes the intent table rows but forgets to add the new "Deprecated names" section → AC-DOCS-COLLISION-WARN-WORKFLOW-1 fails.

2. **`/publish` extraction regex (binding contract).** T-12 must encode the canonical regex `^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)` exactly per design.md §3.1 / SC-11. Both pseudocode AND prose explanation required. The "split at first delimiter" approach is **explicitly abandoned** and the skill prose must say so (it's checked by AC-PUBLISH-AUTO-DETECT-EXTRACTION-1 prose token `'PROJ-123-fix-crash'` + the runtime bash check). All 6 worked examples must appear in skill prose verbatim per design.md §3.1 Step 0d.

3. **Existing `v6.9.0-doc-count-drift.sh` (Phase 2 DISAGREEMENT D).** T-19 must apply ALL 6 edits per Phase 2 R8 / design.md §7 — both lines 42-45 (positive, 19→18) AND lines 55-58 (negative flip — reject 19 instead of 18) AND lines 72/79 (-eq counts) AND lines 84/89 (prose strings). Missing the line-89 PASS message edit was the original spec gap; AC-TEST-INVENTORY-3 explicitly checks for `'18 optional, 28 skills'`.

4. **`tests/scenarios/v6.9.0-bc-no-renamed-section.sh` decision: UPDATE (not RETIRE).** T-11 rewrites it to assert NO `Extra labels` reference + flips mutation guard to 18. Rationale: the test still has utility (asserts OPTIONAL_SECTIONS array shape, guards against re-introduction). Retiring would lose regression coverage. AC-DEL-EXTRA-LABELS-4 and AC-DEL-EXTRA-LABELS-5 verify the update.

5. **No version bump (REQ-NO-VERSION-BUMP).** T-18 CHANGELOG entry uses `## [7.0.0] — Unreleased` header but does NOT touch `plugin.json:version` or `marketplace.json:version`. User runs `/version-bump` post-pipeline. AC-NO-VERSION-BUMP-1, -2, -3 verify zero diff in version fields and no v7.0.0 git tag.

6. **Phase 8 verification commands are NOT run in Phase 7.** Phase 8 runs the design.md §8 commands. T-20's `run-tests.sh` is the in-Phase-7 sanity gate (functional tests). Phase 8 then independently runs cross-file invariants, deprecated-identifier greps, skill directory checks, doc count consistency, frontmatter checks, no-version-bump invariant, and empty-skills-dir invariant.

7. **Coordination on `CLAUDE.md:31` (skills enumeration line).** T-05, T-06, T-07 all touch this line. Recommendation: Phase 7 dispatcher SERIALIZES these three tasks within Wave 2 (T-05 first, T-06 second, T-07 third); each agent reads the latest line, applies its edit, and the cumulative result reflects all 3 changes. Alternative: a single "CLAUDE.md cleanup" sub-task within T-05 performs all 3 edits.

8. **`docs/getting-started.md:219` (Phase 2 finding F7).** Spec did NOT originally include this in the 5-anchor list — Phase 2 added it as F7 finding, and design.md §6 / formal-criteria.md AC-COUNTS-7 binds it. T-15 must include this file in its scope.

9. **`core/mcp-preflight.md:36` and `core/config-reader.md:57` (Phase 2 spec correction).** Spec Action 4 originally missed these two `core/` references. Phase 2 R4 + design.md §2.2 + formal-criteria.md AC-RENAME-INIT-5/6 bind them. T-06 must include them.

10. **`docs/reference/automation-config.md:19, 20` (Phase 2 spec correction).** Spec Action 5 originally missed these two `/create-pr` references in the PR Rules + PR Description Template Used-By columns. Phase 2 R4 + formal-criteria.md AC-DEL-CREATE-PR-5/6 bind them. T-07 must include them.

11. **`tests/scenarios/v6.9.0-arch-freshness-refresh-on-release.sh` (Phase 2 Agent 3 finding).** Spec did NOT originally include this in the test update list. Phase 2 Q8 added it (asserts `SKL[29 Skills]` positive AND rejects `SKL[28 Skills]` negative — both fire after architecture.md update in T-15). T-19 must flip both polarities.

---

## Worktree / Isolation

Phase 7 may use isolation modes per pipeline config. For ceos-agents (pure markdown, no build, no compile step), worktree isolation is overkill. **Recommendation: Phase 7 dispatch agents WITHOUT worktree** — same git state acceptable since:

- All edits within a wave are non-overlapping (or explicitly serialized for `CLAUDE.md:31`)
- No build step → no shared state risk from concurrent compilation
- Tests run only at the end (T-20), not per-task

If isolation is desired anyway (defense in depth), each Wave 1 task could use a separate worktree merging back at Wave 2 entry — but this adds 6 git operations per task with no functional benefit.

---

## Estimated Token Cost

- **Wave 1:** ~80K tokens (T-12 is heavy ~30K opus tokens for full skill rewrite; other 7 tasks combined ~50K sonnet)
- **Wave 2:** ~50K tokens (T-04 workflow-router ~15K; T-05/T-06/T-07 cleanups ~25K combined; T-11 + T-13 ~10K)
- **Wave 3:** ~60K tokens (T-18 CHANGELOG insertion + check-setup detector ~25K; T-17 collision warnings ~10K; T-15/T-16 count edits ~5K; T-19 test scenario copy + update ~20K)
- **Wave 4:** ~10K tokens (T-20 harness execution + result recording)

**Total Phase 7 estimate: ~200K tokens.**

---

## Out-of-Scope (carry-forward from Phase 4)

The following are explicitly OUT of scope for v7.0.0 / this Phase 7 execution:

1. **Version bump** — `plugin.json.version` and `marketplace.json.version` are NOT touched. No `v7.0.0` git tag is created. The user runs `/ceos-agents:version-bump` (or the project's manual procedure) AFTER the pipeline produces a clean Phase 8 verdict. REQ-NO-VERSION-BUMP makes this a verified prohibition (AC-NO-VERSION-BUMP-1, -2, -3).

2. **v6.10.1 follow-ups** (per project memory):
   - Autopilot dispatch audit parity
   - Anti-pattern regex widening
   - README enumeration drift checks

   These are explicitly NOT planned for execution — they are superseded by the v7.0.0 plan and will be re-evaluated in v9.0.0 polish work if still relevant.

3. **Public-mirror canonical-URL update.** `plugin.json.repository` remains at the RFC 2606 unsquattable `https://example.invalid/...` value from v6.9.0. The canonical URL update is part of v9.0.0 (sub-projekt G — Public release polish), not v7.0.0.

4. **Webhook event additions.** No new webhook event introduced. `tracker-down` event is deferred to v7.0.1+ if observability demand emerges.

5. **`/migrate-config` v7 extension.** No auto-rewrite, no sentinel comment in user CLAUDE.md, no first-run nudge from `core/config-reader.md`. The migration support surface is exactly: CHANGELOG block (T-18) + README migration table (T-17) + `/check-setup` `[WARN]` (T-18). Phase 3 D3 unanimous reject.

6. **Stub skills.** No `skills/status/`, `skills/init/`, or `skills/create-pr/` stub remains after delete/rename. Skill-not-found error from Claude Code is the intended behavior post-upgrade. Phase 3 D4 unanimous DELETE.

7. **`/publish --no-tracker` flag or any new flags.** The v7.0.0 design intent is "no new config keys, no new flags." Workaround for the lost-agency case is branch-rename (documented in CHANGELOG via T-18).

8. **Localization of CHANGELOG / README / migration prose.** All user-facing text in v7.0.0 is English per project conventions. Czech bullets in the spec are translated to English in CHANGELOG (T-18).

9. **Architectural reworks.** Sub-projekty A (Agent shape rework) and B (Human-in-the-loop pipelines) are scheduled for v8.0.0. v7.0.0 explicitly does NOT touch agent definitions beyond the `agents/publisher.md:69, 82-87` edits required by REQ-DEL-EXTRA-LABELS (T-10) and REQ-PUBLISH-AUTO-DETECT (T-13).

---

## Validation that plan is acyclic

**Edge list** (target ← source — i.e., target depends on source):

```
T-04 ← T-01      T-04 ← T-02      T-04 ← T-03
T-05 ← T-02
T-06 ← T-03
T-07 ← T-01
T-11 ← T-10
T-13 ← T-10      T-13 ← T-12
T-15 ← T-01      T-15 ← T-02      T-15 ← T-03
T-16 ← T-08      T-16 ← T-10
T-17 ← T-02      T-17 ← T-03      T-17 ← T-04
T-18 ← {T-01, T-02, T-03, T-04, T-05, T-06, T-07, T-08, T-09, T-10, T-11, T-12, T-13}
T-19 ← T-11
T-20 ← {T-01..T-19}
```

**Topological sort**:

| Level | Tasks | All deps in earlier levels? |
|-------|-------|-----------------------------|
| 1 | T-01, T-02, T-03, T-08, T-09, T-10, T-12, T-14 | Yes (no deps) |
| 2 | T-04, T-05, T-06, T-07, T-11, T-13 | Yes (Level 1 only) |
| 3 | T-15, T-16, T-17, T-18, T-19 | Yes (Levels 1-2 only) |
| 4 | T-20 | Yes (Levels 1-3 only) |

No back-edges → DAG is acyclic. The 4-wave layering is a valid topological ordering. ✓

---

## REQ coverage map (final check)

| REQ | Tasks | ACs |
|-----|-------|-----|
| REQ-DEL-EXTRA-LABELS | T-08, T-09, T-10, T-11 | AC-DEL-EXTRA-LABELS-1..5 |
| REQ-PAUSE-LIMITS-DOC | T-14 | AC-PAUSE-LIMITS-DOC-1, -2 |
| REQ-RENAME-STATUS | T-02, T-04, T-05 | AC-RENAME-STATUS-1..7 |
| REQ-RENAME-INIT | T-03, T-04, T-06 | AC-RENAME-INIT-1..7 |
| REQ-PUBLISH-AUTO-DETECT | T-12, T-13 | AC-PUBLISH-AUTO-DETECT-1..15, EXTRACTION-1..5, ZERO-COMMITS |
| REQ-DEL-CREATE-PR | T-01, T-04, T-07 | AC-DEL-CREATE-PR-1..11 |
| REQ-DOCS-COLLISION-WARN | T-04, T-17 | AC-DOCS-COLLISION-WARN-1, -2, -3, WORKFLOW-1 |
| REQ-CHANGELOG-MIGRATION | T-18 | AC-CHANGELOG-MIGRATION-1..7 |
| REQ-COUNTS | T-15, T-16 (filesystem invariants from T-01..T-03) | AC-COUNTS-1..10 |
| REQ-INVARIANTS | (no edits — preserved by all tasks) | AC-INVARIANTS-1..3 |
| REQ-NO-VERSION-BUMP | (governance — enforced across all tasks) | AC-NO-VERSION-BUMP-1..3 |

All 11 REQs covered. ✓
All 94 ACs traceable to at least one task. ✓
