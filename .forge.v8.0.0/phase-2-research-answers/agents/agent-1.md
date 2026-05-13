# Phase 2 Research Answers — Agent 1 (Senior Open-Source Archaeologist)

> Trait: Rigorous file:line citation. Every claim cites a real file:line. No hallucinated paths.

---

## Q1: How many of the 8 config templates in `examples/configs/` actually contain "Extra labels"?

### Direct Answer

Only **2 of the 8** templates contain an `Extra labels` section. The remaining 6 templates have no `Extra labels` row and must NOT be touched for Action 1.

### Evidence

Grep of all 8 files in `examples/configs/` for `Extra labels`:

- `examples/configs/github-nextjs.md:104` — `### Extra labels (optional)`
- `examples/configs/redmine-oracle-plsql.md:182` — `### Extra labels (optional)`

No matches in: `github-python-fastapi.md`, `github-dotnet.md`, `gitea-spring-boot.md`, `jira-react.md`, `youtrack-python.md`, `redmine-rails.md` (verified via `Grep path=examples/configs/ glob=*.md` — returned exactly 2 hits).

### Implication for v7.0.0

Phase 7 must only edit 2 config templates (github-nextjs.md and redmine-oracle-plsql.md), not all 8. Touching the other 6 would introduce unnecessary diffs with no functional purpose.

---

## Q2: Complete file:line inventory of `Extra labels` references; does `core/config-reader.md` parse it into a field consumed by unlisted skills?

### Direct Answer

`core/config-reader.md` parses `Extra labels` into `pr_rules.extra_labels` at line 31. Consumers beyond the spec's list include: `skills/check-setup/SKILL.md`, `skills/migrate-config/SKILL.md`, `skills/onboard/SKILL.md`, and `agents/publisher.md`. The `config-reader-sections.sh` test has `"Extra labels"` hardcoded in its OPTIONAL_SECTIONS array at line 25 and will FAIL after deletion unless updated.

### Evidence

Non-.forge.bak file inventory of `Extra labels`:

**core/**
- `core/config-reader.md:31` — `### Extra labels` → `pr_rules.extra_labels` (default: none)

**skills/**
- `skills/check-setup/SKILL.md:56` — `Retry Limits, Hooks, Custom Agents, Notifications, Worktrees, E2E Test, Error Handling, Extra labels, Decomposition, Pipeline Profiles, Metrics, Feature Workflow, Local Deployment`
- `skills/fix-ticket/SKILL.md:47` — `**Extra labels** from Extra labels section (if it exists):`
- `skills/fix-ticket/SKILL.md:638` — `Extra labels: {Labels from Extra labels config, if they exist}.`
- `skills/fix-bugs/SKILL.md:42` — `**Extra labels** from Extra labels section (if it exists):`
- `skills/fix-bugs/SKILL.md:783` — `Extra labels: {Labels from Extra labels config, if they exist}.`
- `skills/migrate-config/SKILL.md:41` — `For each optional section (Retry Limits, Hooks, Custom Agents, Notifications, Worktrees, E2E Test, Error Handling, Extra labels, Feature Workflow, Decomposition, Pipeline Profiles, Metrics, Build & Test → Verify):`
- `skills/implement-feature/SKILL.md:35` — `Extra labels: Labels (default: none) — additional labels for the PR (passed to publisher)`
- `skills/implement-feature/SKILL.md:599` — `Extra labels (from Extra labels config, if they exist)`
- `skills/onboard/SKILL.md:175` — `[12] Extra labels — additional PR labels`
- `skills/onboard/SKILL.md:204` — `Extra labels: Labels (default: none)`

**agents/**
- `agents/publisher.md:69` — `If Extra labels section exists, add those too.`

**docs/**
- `docs/reference/automation-config.md:33` — `| Extra labels | No | /fix-ticket, /fix-bugs, /implement-feature |`
- `docs/reference/automation-config.md:9` — `There are 5 required sections and 19 optional sections.`

**examples/configs/**
- `examples/configs/github-nextjs.md:104` — `### Extra labels (optional)`
- `examples/configs/redmine-oracle-plsql.md:182` — `### Extra labels (optional)`

**CLAUDE.md**
- `CLAUDE.md:160` — `There are 19 optional config sections in total.` (the table includes `Extra labels`)

**tests/**
- `tests/scenarios/config-reader-sections.sh:25` — `"Extra labels"` in OPTIONAL_SECTIONS array
- `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` — checks for 19 optional section names including Extra labels (via `v6.9.0-bc-no-renamed-section.sh` OPTIONAL_SECTIONS array)

**Unlisted skills confirmed as consumers:**
- `skills/check-setup/SKILL.md:56` lists `Extra labels` in its optional-section enumeration — MUST be updated
- `skills/migrate-config/SKILL.md:41` enumerates `Extra labels` in migration loop — MUST be updated
- `skills/onboard/SKILL.md:175,204` guides users to set up `Extra labels` — MUST be updated

### Implication for v7.0.0

Phase 7 must edit all 10 non-.forge.bak files above. The `config-reader-sections.sh` test MUST have the `"Extra labels"` entry removed from OPTIONAL_SECTIONS (line 25) and the hardcoded count updated from 19→18 in its mutation guard. `agents/publisher.md:69` must be updated to remove `Extra labels` fallback. `skills/check-setup`, `skills/migrate-config`, and `skills/onboard` are unlisted consumers that MUST be updated.

---

## Q3: Which exactly 6 skills implement pause-on-NEEDS_CLARIFICATION semantics, and does `analyze-bug` qualify?

### Direct Answer

The 6 skills that write a `paused` state to `state.json` are: **fix-ticket, fix-bugs, implement-feature, scaffold, autopilot, resume-ticket**. `analyze-bug` does NOT pause — it handles NEEDS_CLARIFICATION interactively (no state.json, no pipeline pause) and explicitly says so. `resume-ticket` qualifies because it reads `state.json.status == "paused"` and triggers the resume path, which is a NEEDS_CLARIFICATION handler (Priority 0).

### Evidence

- `skills/analyze-bug/SKILL.md:26` — `If triage output contains ## NEEDS_CLARIFICATION (interactive surface — no state.json, no pipeline pause):`
- `skills/fix-ticket/SKILL.md:195` — `**NEEDS_CLARIFICATION detection (after triage-analyst dispatch):** If triage output contains ## NEEDS_CLARIFICATION (see core/agent-states.md for the authoritative pause-state contract):`
- `skills/fix-ticket/SKILL.md:419` — `**NEEDS_CLARIFICATION detection (after fixer dispatch):** If fixer output contains ## NEEDS_CLARIFICATION:`
- `skills/fix-bugs/SKILL.md:216` — `**NEEDS_CLARIFICATION detection (after triage-analyst dispatch, per bug):** If triage output contains ## NEEDS_CLARIFICATION:`
- `skills/fix-bugs/SKILL.md:473` — `**NEEDS_CLARIFICATION detection (after fixer dispatch, per bug):** If fixer output contains ## NEEDS_CLARIFICATION:`
- `skills/implement-feature/SKILL.md:382` — `**NEEDS_CLARIFICATION detection (after fixer dispatch):** If fixer output contains ## NEEDS_CLARIFICATION:`
- `skills/scaffold/SKILL.md:788` — `**NEEDS_CLARIFICATION detection (after fixer dispatch — Step 7a):** If fixer output contains ## NEEDS_CLARIFICATION:`
- `skills/autopilot/SKILL.md:400` — `paused) outcome="paused" ;; # NEEDS_CLARIFICATION — not an error; Step 1a handles on next run`
- `skills/autopilot/SKILL.md:411` — `paused — child_exit == 0 AND state.json.status == "paused" (NEEDS_CLARIFICATION; next autopilot run's Step 1a will enforce Pause Limits and either skip or auto-abort).`
- `skills/resume-ticket/SKILL.md:15` — `### Paused Detection (Priority 0 — NEEDS_CLARIFICATION)`
- `skills/resume-ticket/SKILL.md:17` — `**Priority 0 — paused (NEEDS_CLARIFICATION):** Before any other detection, check if state.json top-level status == "paused" and state.json.clarification != null:`

**analyze-bug is interactive-only.** No state.json pause is written: `skills/analyze-bug/SKILL.md:26` explicitly says "no state.json, no pipeline pause."

**`docs/reference/automation-config.md:40`** — `| Pause Limits | No | /autopilot |` — this is the line that says "/autopilot only" and must be corrected.

### Implication for v7.0.0

`docs/reference/automation-config.md:40` must change `/autopilot` to list all 6 correct skills: `/fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot, /resume-ticket`. The section body at lines 460–477 also describes Pause Limits but does not restrict it to autopilot (the section heading at line 460 says "Controls how long a pipeline waits in the paused state" — this is accurate for all 6). Line 628 is inside a commented-out example block (`<!--...-->`) and is informational only. Full details in DISAGREEMENT C resolution below.

---

## Q4: Complete file:line inventory of every reference to `/ceos-agents:status`, `ceos-agents:status`, `/ceos-agents:init`, `ceos-agents:init` — including `core/` files and inline user-facing strings.

### Direct Answer

There are numerous references to `/ceos-agents:init` across skills, docs, and core. The `/ceos-agents:status` references are fewer and concentrated in user-facing text. No test scenario files contain these strings. `core/mcp-preflight.md:36` contains `/ceos-agents:init` in a Recommendation field. `skills/status/SKILL.md:60,82` contain `/ceos-agents:init` in table output strings.

### Evidence

**core/**
- `core/config-reader.md:57` — `run /ceos-agents:init.`
- `core/mcp-preflight.md:36` — `Recommendation: Run /ceos-agents:check-setup for diagnostics, or /ceos-agents:init to configure the {tracker_type} integration.`

**skills/** (ceos-agents:init references — user-facing output strings):
- `skills/check-setup/SKILL.md:68` — `[FAIL] "No .mcp.json found. Run /ceos-agents:init to create one."`
- `skills/check-setup/SKILL.md:76` — `[FAIL] "No MCP server configured for tracker type '{type}'. Run /ceos-agents:init to set it up."`
- `skills/create-backlog/SKILL.md:52` — `Recommendation: Run /ceos-agents:check-setup for diagnostics, or /ceos-agents:init to configure the {Type} integration.`
- `skills/implement-feature/SKILL.md:85` — `Recommendation: Either configure the {Type} integration first (run /ceos-agents:init), or create the issue manually...`
- `skills/onboard/SKILL.md:242` — `2. Run /ceos-agents:init to configure MCP servers and permissions`
- `skills/scaffold/SKILL.md:180` — `Build the init command from Step 0-INFRA values: /ceos-agents:init --tracker-type ... --sc-remote ...`
- `skills/scaffold/SKILL.md:183` — `(a) Configure now — run /ceos-agents:init to set up MCP (recommended)`
- `skills/scaffold/SKILL.md:188` — `1. Display the exact init command: Run: /ceos-agents:init --tracker-type...`
- `skills/scaffold/SKILL.md:213` — `configure the {tracker_type} integration first (run /ceos-agents:init --tracker-type...)`
- `skills/scaffold/SKILL.md:217` — `Auto-invoke init with flags: execute /ceos-agents:init --tracker-type...`
- `skills/scaffold/SKILL.md:221` — `Configure later via /ceos-agents:init.`
- `skills/scaffold/SKILL.md:1068` — `Tracker: Downgraded — MCP unavailable during scaffold. Configure via /ceos-agents:init`
- `skills/scaffold/SKILL.md:1070` — `Tracker: Not configured — run /ceos-agents:init + /ceos-agents:onboard --update`
- `skills/scaffold/SKILL.md:1076` — `SC: Downgraded — MCP unavailable during scaffold. Push manually and run /ceos-agents:init`
- `skills/scaffold/SKILL.md:1078` — `SC: Not configured — set up a remote and run /ceos-agents:init`
- `skills/scaffold/SKILL.md:1098` — `2. Run /ceos-agents:init to configure MCP servers`
- `skills/init/SKILL.md:202` — `re-run /ceos-agents:init, or download the binary manually.`
- `skills/init/SKILL.md:215` — `re-run /ceos-agents:init.`
- `skills/init/SKILL.md:225` — `Install it and re-run /ceos-agents:init.`
- `skills/init/SKILL.md:263` — `Re-run /ceos-agents:init to fix the path.`
- `skills/init/SKILL.md:341` — `Tip: You can re-run /ceos-agents:init --update anytime to update your setup.`

**skills/** (ceos-agents:status references):
- `skills/status/SKILL.md:60` — table row `MCP Server | ✅/⚠️ | Connected / Not configured — run /ceos-agents:init`
- `skills/status/SKILL.md:82` — table row `MCP Server | ⚠️ | Not configured — run /ceos-agents:init`
- `skills/workflow-router/SKILL.md:18` — `| Show status/overview | ceos-agents:status | None | No |`
- `skills/workflow-router/SKILL.md:20` — `| Configure MCP/tokens/permissions | ceos-agents:init | Optional: --update | Yes |`

**docs/**
- `docs/getting-started.md:115` — `/ceos-agents:init`
- `docs/getting-started.md:125` — `You can re-run /ceos-agents:init --update anytime to update your setup.`
- `docs/guides/installation.md:92` — `The /ceos-agents:init skill will automatically attempt go install as a fallback.`
- `docs/guides/troubleshooting.md:225` — `1. Run /ceos-agents:init — it generates .claude/settings.json with appropriate permissions`
- `docs/guides/troubleshooting.md:311` — `2. **Check the pipeline stage:** Use /ceos-agents:status to see the current state...`
- `docs/guides/mcp-configuration.md:5` — `**Automated setup:** Run /ceos-agents:init to generate .mcp.json automatically...`
- `docs/guides/mcp-configuration.md:52` — `Alternatively, run /ceos-agents:init which handles this automatically.`
- `docs/reference/skills.md:398,399,400` — `/ceos-agents:init` syntax examples
- `docs/reference/skills.md:423,427` — `/ceos-agents:init` usage examples
- `docs/reference/skills.md:516,524` — `/ceos-agents:status` usage examples

**tests/scenarios/** — No matches for `ceos-agents:status` or `ceos-agents:init` in `.sh` files (confirmed via grep of tests/scenarios/**/*.sh).

Tests that reference the skill's **directory path** (will break after rename):
- `tests/scenarios/scaffold-mcp-checkpoint.sh:7` — `INIT_SKILL="$REPO_ROOT/skills/init/SKILL.md"`
- `tests/scenarios/v6.10.0-dispatch-hook-install-surface.sh:17` — `INIT="$REPO_ROOT/skills/init/SKILL.md"`
- `tests/scenarios/v644-diagnostics-hardening.sh:19,36,67,109,375,378` — multiple references to `skills/init/SKILL.md`
- `tests/scenarios/no-mcp-jargon-errors.sh:20` — `"skills/status/SKILL.md"` in STANDARD_ERROR_FILES array

### Implication for v7.0.0

Phase 7 must update all `skills/init/` and `skills/status/` path references in tests when renaming the directories. 4 test scenario files contain hardcoded `skills/init/SKILL.md` paths and will FAIL after the rename unless updated. `no-mcp-jargon-errors.sh:20` references `skills/status/SKILL.md` which must be renamed too.

---

## Q5: Exact structure of `workflow-router` intent table and Step 3/4 prose for `/ceos-agents:status`, `/ceos-agents:init`, `/ceos-agents:create-pr`, `/publish`.

### Direct Answer

All four skill names appear as distinct rows in the intent table at `skills/workflow-router/SKILL.md` lines 15–20. `/ceos-agents:create-pr` also appears in the Step 4 destructive list at line 55. `/ceos-agents:status` appears in the Step 3 non-destructive list at line 54. No publish description mentions auto-detect in the current prose.

### Evidence

**Intent table rows (verbatim):**
- `skills/workflow-router/SKILL.md:15` — `| Create a pull request | ceos-agents:create-pr | None | Yes |`
- `skills/workflow-router/SKILL.md:16` — `| Publish (PR + issue state) | ceos-agents:publish | None | Yes |`
- `skills/workflow-router/SKILL.md:18` — `| Show status/overview | ceos-agents:status | None | No |`
- `skills/workflow-router/SKILL.md:20` — `| Configure MCP/tokens/permissions | ceos-agents:init | Optional: --update | Yes |`

**Step 3/4 prose (exact quotes):**
- `skills/workflow-router/SKILL.md:54` — `3. **If the operation is NOT destructive** (analyze-bug, check-setup, version-check, status, dashboard, metrics, estimate, prioritize, template, scaffold-validate, check-deploy without flags, autopilot --dry-run): invoke the command immediately`
- `skills/workflow-router/SKILL.md:55` — `4. **If the operation IS destructive** (fix-ticket, fix-bugs, create-pr, publish, check-deploy --start/--stop, autopilot without --dry-run):`

**Verification:** `status` appears in the non-destructive list (Step 3 prose, line 54) but NOT as `ceos-agents:status` — just as the short name `status`. `init` does NOT appear in Step 3 or 4 prose (it is in the intent table only). `create-pr` appears only in Step 4 destructive list (line 55) and the intent table (line 15).

### Implication for v7.0.0

Phase 7 must make 4 edits to `skills/workflow-router/SKILL.md`:
1. Line 15: remove the `create-pr` row entirely
2. Line 18: rename `ceos-agents:status` → `ceos-agents:pipeline-status`
3. Line 20: rename `ceos-agents:init` → `ceos-agents:setup-mcp`
4. Line 54: rename `status` → `pipeline-status` in the non-destructive list
5. Line 55: remove `create-pr,` from the destructive list

Note: `publish` row (line 16) description "PR + issue state" remains accurate after auto-detect (it may detect no issue but still creates a PR, and when it does detect an issue it updates the tracker). The row itself does not need to change.

---

## Q6: Exact current branch-name-to-issue-ID extraction logic in `publish/SKILL.md` Steps 1-3 and how fix-ticket/fix-bugs extract the issue ID.

### Direct Answer

`skills/publish/SKILL.md` Step 1 says only "Determine the current branch and issue ID" (line 21) — it provides no extraction pattern. The issue ID is expected to be already known (pipeline context). `skills/fix-ticket/SKILL.md` creates the branch at Step 2 (line 169) using `{branch_naming}` from Automation Config — the template `fix/{issue-id}-{description}` means the issue ID is embedded as a prefix before the first hyphen after the prefix. There is no explicit regex extraction function; the skill receives the issue ID as `$ARGUMENTS`.

### Evidence

- `skills/publish/SKILL.md:21` — `1. Determine the current branch and issue ID`
- `skills/publish/SKILL.md:22` — `2. Verify that the current branch has commits above the base branch...`
- `skills/publish/SKILL.md:23` — `3. Check whether an open PR already exists for the current branch.`
- `skills/fix-ticket/SKILL.md:169` — `git checkout -b {branch_naming} {base_branch} — values from Automation Config (Source Control).`
- `docs/reference/automation-config.md:109` — `| Branch naming | fix/{issue-id}-{description} |`
- `docs/reference/automation-config.md:111` — `The {issue-id} and {description} placeholders are replaced at runtime. Description is derived from the issue title (lowercased, spaces replaced with hyphens).`

**Issue-ID validation regex** (used in fix-ticket, fix-bugs, implement-feature, resume-ticket):
- `skills/fix-ticket/SKILL.md:91` — `if [[ ! "${ISSUE_ID}" =~ ^[A-Za-z0-9#._-]+$ || "${ISSUE_ID}" =~ ^\.+$ ]]; then`

This allowlist regex (`^[A-Za-z0-9#._-]+$`) is the extraction validation pattern. For branch-name-to-issue-ID extraction in `/publish` auto-detect, Phase 7 must implement: strip the branch naming prefix (e.g., `fix/`), extract the portion before the next `-description` suffix, and validate against `^[A-Za-z0-9#._-]+$`. No capture-group regex is pre-defined; the extraction logic must be written fresh.

**`create-pr/SKILL.md:24`** provides a reference implementation: `Extract the issue ID from the branch name` — but no regex is given; it defers to LLM interpretation of the branch naming pattern at runtime.

### Implication for v7.0.0

Phase 7's `publish` auto-detect must implement the 3-way fork at Step 1. The safest approach: read `Source Control → Branch naming` pattern from Automation Config, derive the prefix (e.g., `fix/`), strip it, extract the issue ID by matching the regex `^[A-Za-z0-9#._-]+` against the branch name after prefix removal. If extraction fails → PR-only mode (no tracker update). If extraction succeeds but tracker is down → FAIL with guidance. The same validation regex from fix-ticket line 91 should be reused for consistency.

---

## Q7: For each tracker type, MCP tool name for single-issue fetch; error shapes for 404 vs 5xx/timeout.

### Direct Answer

`core/mcp-detection.md` documents connectivity via "list 1 issue" (line 39), NOT a single-issue-get. There is no documented `getIssue` MCP tool for any tracker — the detection contract uses `list` operations. The error classification is documented by type string, not HTTP status code: `"not_found"` for 404/DNS, `"timeout"` for ETIMEDOUT/ECONNREFUSED/timeout, `"auth"` for 401/403.

### Evidence

**Tool prefixes by tracker (from `core/mcp-detection.md:27-34`):**
- `core/mcp-detection.md:28` — youtrack: `mcp__youtrack__*`
- `core/mcp-detection.md:29` — github: `mcp__github__*`
- `core/mcp-detection.md:30` — jira: `mcp__jira__*` or `mcp__atlassian__*`
- `core/mcp-detection.md:31` — linear: `mcp__linear__*`
- `core/mcp-detection.md:32` — gitea: `mcp__gitea__*` or `mcp__forgejo__*`
- `core/mcp-detection.md:33` — redmine: `mcp__redmine__*`

**Read connectivity check** (from `core/mcp-detection.md:39`): "attempt to list 1 issue from the declared project (or list projects if no project specified)"

**Error classification** (from `core/mcp-detection.md:75-84`):
- `core/mcp-detection.md:79` — `"not_found"` triggered by: `404, not_found, not found, ENOTFOUND, EAI_AGAIN`
- `core/mcp-detection.md:80` — `"timeout"` triggered by: `timeout, ETIMEDOUT, ECONNREFUSED, ECONNRESET`
- `core/mcp-detection.md:78` — `"auth"` triggered by: `401, 403, unauthorized, forbidden, invalid token, authentication`
- `core/mcp-detection.md:81` — `"unknown"` for all remaining errors

**Critical gap for v7.0.0 auto-detect:** There is no documented `mcp__youtrack__getIssue` (or equivalent) tool. The MCP detection pattern uses `list` operations only. For the 3-way fork in publish auto-detect, Phase 7 must implement the issue-existence check using the list/search operation with the specific issue ID as a filter, not a direct `getIssue` call. The error classification from `core/mcp-detection.md` applies: `error_type == "not_found"` means issue does not exist (404), `error_type == "timeout"` or `"auth"` means tracker unreachable.

**`docs/reference/trackers.md`** does not document individual MCP tool names (only MCP package names and keywords). There is no `getIssue` tool documented anywhere in the codebase.

### Implication for v7.0.0

Phase 7 must not assume a `getIssue` MCP tool exists. The auto-detect in `/publish` must use the same pattern as `core/mcp-detection.md` read connectivity: list/search for the specific issue ID from the branch name. The 3-way fork is: (1) issue found → tracker update + PR, (2) empty result / not_found → PR only, (3) auth/timeout/unknown error → FAIL with guidance citing `/ceos-agents:check-setup`.

---

## Q8: Complete test scenario inventory that will HARD-FAIL or produce false-positives after v7.0.0.

### Direct Answer

At minimum **9 test scenarios** are at risk. The critical scenario is `v6.9.0-doc-count-drift.sh` — it has BOTH a positive assertion for "19 optional config sections in total" (HARD-FAIL) AND a negative assertion rejecting "18 optional config sections in total" (which will silently PASS when we update to 18 — but it's a NEGATIVE check, so it will only FAIL if we write "18 optional config sections in total" elsewhere). See DISAGREEMENT D resolution for full analysis.

### Evidence

**HARD-FAIL after v7.0.0 (direct count/name changes):**

1. `tests/scenarios/regression-skill-count-29.sh:14` — `if [ "$SKILL_COUNT" -ne 29 ]` — HARD-FAIL when create-pr is deleted (count drops to 28)

2. `tests/scenarios/ac-v68-doc-skill-count-29.sh:15` — `if ! grep -nE '29 skills' CLAUDE.md | grep -q .` — HARD-FAIL when CLAUDE.md is updated from 29→28 skills

3. `tests/scenarios/v6.9.0-doc-count-drift.sh:42-45` — `grep -qF '19 optional config sections in total'` — HARD-FAIL when CLAUDE.md drops from 19→18 optional sections

4. `tests/scenarios/v6.9.0-doc-count-drift.sh:72` — `[ "$skills_count" -eq 29 ]` — HARD-FAIL when skills dir count drops to 28

5. `tests/scenarios/v6.9.0-doc-count-drift.sh:79` — `[ "$optional_count" -eq 19 ]` — HARD-FAIL when optional sections table drops to 18

6. `tests/scenarios/skills-directory-structure.sh:24-58` — hardcoded `EXPECTED_SKILLS` array contains `create-pr` (line 36), `status` (line 54), `init` (line 43); count check `expected_count="${#EXPECTED_SKILLS[@]}"` = 29 — HARD-FAIL on 3 counts (missing create-pr, unexpected pipeline-status, unexpected setup-mcp)

7. `tests/scenarios/skills-frontmatter-check.sh:51` — `create-pr` in `PIPELINE_SKILLS` array — HARD-FAIL when `skills/create-pr/` is deleted; `skills/status/SKILL.md` in FC-6 `READONLY_SKILLS` (line 87) — HARD-FAIL after rename

8. `tests/scenarios/config-reader-sections.sh:25` — `"Extra labels"` in OPTIONAL_SECTIONS array — HARD-FAIL when `Extra labels` removed from CLAUDE.md and config-reader.md

9. `tests/scenarios/no-mcp-jargon-errors.sh:15` — `"skills/create-pr/SKILL.md"` in STANDARD_ERROR_FILES array — HARD-FAIL when `skills/create-pr/` is deleted (file not found)

**Tests with path references to renamed skill directories (HARD-FAIL after rename):**

10. `tests/scenarios/scaffold-mcp-checkpoint.sh:7` — `INIT_SKILL="$REPO_ROOT/skills/init/SKILL.md"` — HARD-FAIL when renamed to `skills/setup-mcp/`
11. `tests/scenarios/v6.10.0-dispatch-hook-install-surface.sh:17` — `INIT="$REPO_ROOT/skills/init/SKILL.md"` — HARD-FAIL after rename
12. `tests/scenarios/v644-diagnostics-hardening.sh` (multiple lines) — references `skills/init/SKILL.md` at lines 19, 36, 67, 109, 375, 378 — HARD-FAIL after rename
13. `tests/scenarios/no-mcp-jargon-errors.sh:20` — `"skills/status/SKILL.md"` — HARD-FAIL after rename to `skills/pipeline-status/`

**False-positive acceptance signal:**

14. `tests/scenarios/ac-v68-doc-optional-sections-18.sh:15` — `grep -nE '(18|19) optional'` — will SILENTLY PASS after the drop to 18 (matches "18 optional"), creating a false-positive signal. This test was designed as an upgrade guard (17→18) and is now a weak check.

15. `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` — enumerates all 19 optional section names including `"Extra labels"` — HARD-FAIL when `Extra labels` is removed from CLAUDE.md

**Test classification summary:**

| Test file | Action | Reason |
|-----------|--------|--------|
| `regression-skill-count-29.sh` | UPDATE: 29→28 | Count drops after create-pr deletion |
| `ac-v68-doc-skill-count-29.sh` | UPDATE: 29→28 | Count drops in CLAUDE.md and skills.md |
| `v6.9.0-doc-count-drift.sh` | UPDATE: 19→18, 29→28 | Both count assertions must be updated; negative assertion at line 56-57 must be inverted |
| `skills-directory-structure.sh` | UPDATE: remove create-pr, rename status→pipeline-status, rename init→setup-mcp | Hardcoded expected skill list |
| `skills-frontmatter-check.sh` | UPDATE: remove create-pr from PIPELINE_SKILLS, update status/init in READONLY_SKILLS | Hardcoded skill names |
| `config-reader-sections.sh` | UPDATE: remove "Extra labels" from OPTIONAL_SECTIONS | Hardcoded section names |
| `no-mcp-jargon-errors.sh` | UPDATE: remove create-pr from STANDARD_ERROR_FILES, update status path | File paths hardcoded |
| `scaffold-mcp-checkpoint.sh` | UPDATE: init→setup-mcp path | Path hardcoded |
| `v6.10.0-dispatch-hook-install-surface.sh` | UPDATE: init→setup-mcp path | Path hardcoded |
| `v644-diagnostics-hardening.sh` | UPDATE: all init path references | Path hardcoded (6 lines) |
| `ac-v68-doc-optional-sections-18.sh` | RETIRE (exit 77) or UPDATE | Legacy upgrade guard; now accepts either 18 or 19 — valid but weak |
| `v6.9.0-bc-no-renamed-section.sh` | UPDATE: remove "Extra labels" from enumeration | Hardcoded 19-section list |
| `xref-command-count.sh` | UPDATE | Derives count from CLAUDE.md via regex — will auto-correct if CLAUDE.md is updated correctly |
| `v6.9.0-arch-freshness-refresh-on-release.sh` | UPDATE: 29→28 in assertion text | Has "29 Skills" assertion for docs/architecture.md |

### Implication for v7.0.0

Phase 7 must update or retire 13+ test files. The safest strategy: update all count-bearing tests to the v7.0.0 targets (28 skills, 18 optional sections) and update all path-bearing tests to use the new directory names. `ac-v68-doc-optional-sections-18.sh` should be RETIRED (exit 77) as its pass condition (`18|19 optional`) will be trivially true after the drop.

---

## Q9: Exact line numbers in 5 anchor docs where "29 skills" and "19 optional" appear; do plugin metadata or examples contain count strings?

### Direct Answer

"29 skills" appears in CLAUDE.md (line 18), README.md (line 262), docs/reference/skills.md (line 3), and docs/architecture.md (line 27). "19 optional" appears in CLAUDE.md (line 160) and docs/reference/automation-config.md (line 9). `plugin.json` and `marketplace.json` contain NO count strings. `examples/configs/*.md` contain NO references to `ceos-agents:status`, `ceos-agents:init`, or `create-pr`.

### Evidence

**"29 skills":**
- `CLAUDE.md:18` — `` `skills/` — 29 skills (slash commands, including workflow-router) ``
- `README.md:262` — `| [Skills](docs/reference/skills.md) | All 29 skills — syntax, flags, examples |`
- `docs/reference/skills.md:3` — `This reference covers all 29 skills in the ceos-agents plugin. All 29 ceos-agents skills are listed...`
- `docs/architecture.md:27` — `SKL[29 Skills]` (inside mermaid diagram block)

**"19 optional" (config sections):**
- `CLAUDE.md:160` — `There are 19 optional config sections in total. All sections use table format...`
- `docs/reference/automation-config.md:9` — `There are 5 required sections and 19 optional sections.`

**docs/architecture.md:** Confirmed has `SKL[29 Skills]` at line 27 but NO "19 optional" string (architecture.md does not track optional section counts). The anchor for optional sections is only CLAUDE.md and automation-config.md.

**plugin.json and marketplace.json:** Neither contains count strings or skill-name references (confirmed by reading full files). `plugin.json` has only `name`, `description`, `version`, `author`, `repository`, `license`. `marketplace.json` has only `name`, `owner`, `plugins` array with same structure.

**examples/configs/*.md:** No matches for `ceos-agents:status`, `ceos-agents:init`, or `create-pr` in any of the 8 config templates (confirmed via grep — zero matches).

**Complete change list for Phase 6/7:**

| File | Line | Current text | New text |
|------|------|-------------|----------|
| `CLAUDE.md` | 18 | `29 skills` | `28 skills` |
| `CLAUDE.md` | 160 | `19 optional config sections in total` | `18 optional config sections in total` |
| `CLAUDE.md` | (optional table row) | `Extra labels` row | DELETE row |
| `README.md` | 262 | `All 29 skills — syntax, flags, examples` | `All 28 skills — syntax, flags, examples` |
| `docs/reference/skills.md` | 3 | `all 29 skills...All 29 ceos-agents skills` | `all 28 skills...All 28 ceos-agents skills` |
| `docs/architecture.md` | 27 | `SKL[29 Skills]` | `SKL[28 Skills]` |
| `docs/reference/automation-config.md` | 9 | `19 optional sections` | `18 optional sections` |
| `docs/reference/automation-config.md` | 33 | `Extra labels` row | DELETE row |
| `docs/reference/automation-config.md` | 40 | `\| Pause Limits \| No \| /autopilot \|` | `\| Pause Limits \| No \| /fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot, /resume-ticket \|` |

### Implication for v7.0.0

Phase 6 planner can use this change list directly. No plugin metadata files need version or count updates. No examples/configs need skill-name updates.

---

## Validation Resolutions

### DISAGREEMENT A: 8 templates vs 2 templates containing `Extra labels`

**Verdict: Agent-3 was correct — only 2 templates contain `Extra labels`.**

**Evidence:**
- `examples/configs/github-nextjs.md:104` — `### Extra labels (optional)` ✓
- `examples/configs/redmine-oracle-plsql.md:182` — `### Extra labels (optional)` ✓
- No matches in: `github-python-fastapi.md`, `github-dotnet.md`, `gitea-spring-boot.md`, `jira-react.md`, `youtrack-python.md`, `redmine-rails.md`

The spec claim "8 config templates reference Extra labels" was false. Phase 7 must only edit the 2 files that actually contain the section.

---

### DISAGREEMENT B: Does `resume-ticket` implement pause semantics (emit NEEDS_CLARIFICATION or write `state.paused`)?

**Verdict: `resume-ticket` QUALIFIES as one of the 6 skills — but for the RESUME side, not the pause side. Both sides are part of the same Pause Limits feature. Agent-1's original claim to include it was correct from a feature-scope perspective; Agent-3 raised a valid precision concern.**

**Evidence:**
- `skills/resume-ticket/SKILL.md:15` — `### Paused Detection (Priority 0 — NEEDS_CLARIFICATION)`
- `skills/resume-ticket/SKILL.md:17` — `**Priority 0 — paused (NEEDS_CLARIFICATION):** Before any other detection, check if state.json top-level status == "paused" and state.json.clarification != null:`
- `skills/resume-ticket/SKILL.md:33` — `Set top-level status back to running.` (writes state.json)

`resume-ticket` does NOT emit NEEDS_CLARIFICATION (it handles the answer, not the question). However, it IS part of the Pause Limits feature lifecycle — it reads and transitions the paused state. The CLAUDE.md memory states "fix-ticket, fix-bugs, implement-feature, scaffold, autopilot, resume-ticket as the presumed 6." For the `automation-config.md` doc fix (the dispatch site for Pause Limits), listing resume-ticket is correct because Pause Limits enforcement happens in autopilot AND resume-ticket reads the paused state.

**Precision clarification:** The 5 skills that WRITE the paused state are: fix-ticket, fix-bugs, implement-feature, scaffold, autopilot. Resume-ticket READS and CLEARS the paused state. For the `Pause Limits` doc fix, ALL 6 should be listed as consumers.

---

### DISAGREEMENT C: Does `docs/reference/automation-config.md` say "/autopilot only" at multiple locations?

**Verdict: Agent-3 was correct that Pause Limits appears at lines 40, 460, 470, and 628. However, only line 40 says "/autopilot only" — the section body (lines 460–477) accurately describes all-pipeline pause semantics and does NOT restrict to autopilot. Line 628 is inside a commented-out example block.**

**Evidence:**
- `docs/reference/automation-config.md:40` — `| Pause Limits | No | /autopilot |` — THIS IS THE BUG. The "Used By" column says only `/autopilot`.
- `docs/reference/automation-config.md:460` — `### Pause Limits` — section heading; body text says "Controls how long a pipeline waits in the paused state" — does NOT restrict to autopilot. This is accurate for all 6 skills.
- `docs/reference/automation-config.md:470` — `### Pause Limits` — this is an example block showing the config syntax. No "autopilot only" claim here.
- `docs/reference/automation-config.md:628` — `### Pause Limits (optional, v6.9.0+)` — inside `<!-- ... -->` commented-out complete config example. Not user-visible. No doc fix needed here.

**Single-location fix required:** Only `docs/reference/automation-config.md:40` says `/autopilot` and must be updated to list all 6 applicable skills. The section body (lines 460–477) is already accurate. Line 628 is inside a comment and informational only.

---

### DISAGREEMENT D: Does `v6.9.0-doc-count-drift.sh` lines 56-57 contain a NEGATIVE assertion that rejects "18 optional config sections in total"?

**Verdict: Agent-3 was correct. Lines 55-58 contain a negative assertion that HARD-FAILS if CLAUDE.md contains "18 optional config sections in total".**

**Evidence:**
- `tests/scenarios/v6.9.0-doc-count-drift.sh:55` — `echo "--- Assertion 5 (AC-064a NEGATIVE): no stale 18 optional ---"`
- `tests/scenarios/v6.9.0-doc-count-drift.sh:56` — `if grep -qF '18 optional config sections in total' "$CLAUDE_MD"; then`
- `tests/scenarios/v6.9.0-doc-count-drift.sh:57` — `fail "AC-064a: CLAUDE.md still has stale '18 optional config sections in total'"`

**Consequence for v7.0.0:** When Phase 7 updates CLAUDE.md from "19 optional config sections in total" to "18 optional config sections in total", this test will HARD-FAIL at line 57 (because it was written to detect the OLD pre-v6.9.0 value "18" as stale). Additionally, the positive assertion at line 42-45 will also HARD-FAIL (because "19 optional config sections in total" will no longer be present).

**Required fix:** `v6.9.0-doc-count-drift.sh` must be updated in Phase 7 to:
1. Change the positive assertion (line 42) from `'19 optional config sections in total'` to `'18 optional config sections in total'`
2. Change the negative assertion (line 56) from `'18 optional config sections in total'` to `'19 optional config sections in total'`  
3. Change the optional-sections table row count assertion (line 79) from `[ "$optional_count" -eq 19 ]` to `[ "$optional_count" -eq 18 ]`
4. Change the skills count assertion (line 72) from `[ "$skills_count" -eq 29 ]` to `[ "$skills_count" -eq 28 ]`
5. Update the PASS message at line 89 to say `28 skills, 18 optional`

Failing to invert the negative assertion at line 56-57 will cause HARD-FAIL even after the correct CLAUDE.md update.

---

DONE — answered Q1-Q9 with 87 citations, resolved 4 disagreements.
