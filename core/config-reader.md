# Config Reader

## Purpose

Parse `## Automation Config` from the project's CLAUDE.md. Extract all required and optional sections into a config object that commands can use without re-parsing.

## Input Contract

- **claude_md_content** (string, required): Full contents of the project's CLAUDE.md file
- **claude_local_md_content** (string, optional): Full contents of `CLAUDE.local.md` located adjacent to the project's CLAUDE.md, when that file exists. Absent (file not present) means no developer overrides — parse CLAUDE.md alone.

## Process

0. **Local override merge (precedence: `CLAUDE.local.md` > `CLAUDE.md`).** Before parsing, resolve the effective config block:
   - If no `CLAUDE.local.md` exists next to the project CLAUDE.md → use the CLAUDE.md `## Automation Config` block unchanged (pure defaults). Skip the rest of this step.
   - If `CLAUDE.local.md` exists → locate its `## Automation Config` block (same heading; if absent, treat as no overrides). Parse it into the same `section → {key → value}` shape as the base, then **merge it over** the base block with these rules:
     - **Sparse, per-section, per-key.** The local block contains only the sections/keys a developer wants to change.
     - Key present in both base and local → **local value replaces** the base value.
     - A local key present with an **empty value** clears the base value (resolves to unset/default); to merely inherit the base value, omit the key entirely.
     - Multi-value keys (e.g. `On events`, `Labels`, `Ports`) and key→value-map values (e.g. `State transitions`) are replaced as a **whole unit** — per-key merge applies only at the section-key level, never inside an individual key's value.
     - Section present in local with keys absent from the base section → those keys are **added** to the section.
     - Section present only in base → **kept unchanged**.
     - Section present only in local → **added** to the effective config.
     - Multi-line `### PR Description Template` → if present in local, the **whole block replaces** the base template (not a per-line merge).
     - Local section present but empty/malformed → log `[WARN] Ignoring malformed local override: {section}` and keep the base section. Never block on a local override.
   - The remainder of this contract (steps 1–4, defaults, validation) operates on the **merged** result, so every skill and agent that reads config per this document inherits the override transparently. Required-section validation (step 4) runs against the merged config. Because malformed local overrides are dropped during this Step 0 merge (the base section is retained), a malformed local override of a required section never causes a spurious Step-4 failure — Step 4 only ever sees the retained base section.

1. Locate the `## Automation Config` heading. Everything from that heading to the next `##`-level heading (or end of file) is the config block.

2. Parse **required sections** — each is a `| Key | Value |` table under its `### {Section}` heading:
   - `### Issue Tracker` → `issue_tracker.type` (default: `youtrack`), `issue_tracker.instance`, `issue_tracker.project`, `issue_tracker.bug_query`, `issue_tracker.state_transitions` (key→value map), `issue_tracker.on_start_set`
   - `### Source Control` → `source_control.remote`, `source_control.base_branch`, `source_control.branch_naming`
   - `### PR Rules` → `pr_rules.labels`
   - `### PR Description Template` → `pr_rules.description_template` (verbatim multi-line text under the subsection heading)
   - `### Build & Test` → `build.build_command`, `build.test_command`, `build.verify_command` (optional key within this section)

3. Parse **optional sections** — missing section → use defaults:
   - `### Retry Limits` → `retry.fixer_iterations` (default: 5), `retry.test_attempts` (default: 3), `retry.build_retries` (default: 3), `retry.spec_iterations` (default: 5), `retry.root_cause_iterations` (default: 3)
   - `### Module Docs` → `module_docs.path` (default: none) — passed to analyst and architect as context
   - `### Hooks` → `hooks.pre_fix`, `hooks.post_fix`, `hooks.pre_publish`, `hooks.post_publish` (default: none)
   - `### Custom Agents` → `custom_agents.post_fix_agent`, `custom_agents.pre_publish_agent` (default: none)
   - `### Worktrees` → `worktrees.batch_size`, `worktrees.base_path`, `worktrees.cleanup` (default: none)
   - `### E2E Test` → `e2e.framework`, `e2e.command` (default: none)
   - `### Browser Verification` → `browser.enabled` (default: `true`), `browser.base_url`, `browser.start_command`, `browser.on_events`, `browser.timeout` (default: 60), `browser.max_pages` (default: 5), `browser.screenshot_storage` (default: `.agent-flow/{ISSUE-ID}/screenshots`), `browser.exploration` (default: disabled), `browser.exploration_max_clicks` (default: 20). Derived gate consumed by `skills/fix-bugs/steps/03-reproduce.md` and `08-browser-verify.md`: `browser_verification_enabled = false` when the `### Browser Verification` section is **absent** from the merged config **OR** `browser.enabled` is `false` (a developer typically sets `| Enabled | false |` in `CLAUDE.local.md` to disable verification on their machine without removing the shared section). When the section is present and `Enabled` is unset, it defaults to `true`.
   - `### Error Handling` → `error_handling.on_block` (default: `comment`), `error_handling.max_blocked_per_run` (default: unlimited)
   - `### Feature Workflow` → `feature.query`, `feature.on_start_set` (default: none)
   - `### Decomposition` → `decomposition.max_subtasks` (default: 7), `decomposition.fail_strategy` (default: `fail-fast`), `decomposition.commit_strategy` (default: `squash`), `decomposition.create_tracker_subtasks` (default: `enabled`)
   - `### Pipeline Profiles` → `profiles` (list of `{name, skip_stages, extra_stages}`) (default: none)
   - `### Metrics` → `metrics.output` (default: `stdout`), `metrics.period` (default: `30 days`)
   - `### Agent Overrides` → `agent_overrides.path` (default: `customization/`)
   - `### Notifications` → `notifications.webhook_url`, `notifications.on_events` (default: none; valid events: `pr-created`, `issue-blocked`, `pipeline-started`, `step-completed`, `pipeline-completed`)
   - `### Local Deployment` → keys: `Type` (mapped to `local_deployment.type`, default: `docker`), `Start command` (mapped to `local_deployment.start_command`, default: `docker compose up -d`), `Stop command` (mapped to `local_deployment.stop_command`, default: `docker compose down`), `Health check URL` (mapped to `local_deployment.health_check_url`, default: `http://localhost:3000/health`), `Health check timeout` (mapped to `local_deployment.health_check_timeout`, default: 60), `Ports` (mapped to `local_deployment.ports`, default: none)
   - `### Sprint Planning` → `sprint_planning.sprint_duration` (default: `2 weeks`, valid: `1 week`, `2 weeks`, `3 weeks`, `4 weeks`), `sprint_planning.capacity_unit` (default: `story-points`, valid: `story-points`, `hours`), `sprint_planning.team_capacity` (default: none), `sprint_planning.velocity_target` (default: none), `sprint_planning.sprint_field` (default: tracker-dependent), `sprint_planning.mode` (default: `suggest`, valid: `suggest` — read-only plan, `apply` — writes to tracker + dispatch), `sprint_planning.max_issues` (default: 20, valid: 1–50), `sprint_planning.epic_template` (default: none)
   - `### Autopilot` → `autopilot.max_issues_per_run` (default: 1), `autopilot.lock_timeout` (default: 120 minutes — stale lock threshold), `autopilot.log_file` (default: `.agent-flow/autopilot.log` — append-only run log), `autopilot.bug_limit` (default: 0 — 0 means no per-type cap; use `autopilot.max_issues_per_run` as the only cap), `autopilot.feature_limit` (default: 0 — 0 means no per-type cap for features), `autopilot.on_error` (default: `skip`, enum: `skip` | `stop` — `skip` = log [WARN] and continue; `stop` = abort run on first per-issue error), `autopilot.dry_run` (default: `false` — full short-circuit: no lock, no state, no webhook, no dispatch). NOTE: `Bug query` is read from `### Issue Tracker` (required existing key); `Feature query` is read from `### Feature Workflow` (optional section — absent triggers [WARN] and bug-only mode). Neither lives in `### Autopilot`. Consumed by `skills/autopilot/SKILL.md`.

4. Validate required sections: confirm that `### Issue Tracker`, `### Source Control`, `### PR Rules`, `### PR Description Template`, and `### Build & Test` are present and non-empty.

## Output Contract

A config object with all parsed values and defaults applied. Commands reference keys using dot-notation (e.g., `issue_tracker.type`, `retry.fixer_iterations`, `agent_overrides.path`).

## Failure Handling

- **`## Automation Config` heading not found:** BLOCK pipeline immediately with:
  ```
  [agent-flow] 🔴 Pipeline Block
  Agent: config-reader
  Step: config parsing
  Reason: No "## Automation Config" section found in CLAUDE.md.
  Detail: The project's CLAUDE.md must contain "## Automation Config" with all required sections.
  Recommendation: Add the Automation Config section. See docs/reference/config.md or run /agent-flow:setup-mcp.
  ```
- **One or more required sections missing:** BLOCK pipeline with the same template, listing the missing section names in Detail.
- **Optional section present but malformed** (e.g., table has wrong columns): log a warning with the section name and use the default value. Never block on an optional section.
