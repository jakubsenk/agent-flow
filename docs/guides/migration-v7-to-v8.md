# Migration Guide: v7.0.0 → v8.0.0

> **Note (v9.5.0):** The `/migrate-config` skill referenced throughout this guide was removed in v9.5.0. All migration steps that previously used `/ceos-agents:migrate-config --to-v8` must now be performed manually following the step-by-step instructions below.

Tento průvodce je určen pro projektové týmy, které aktualizují ceos-agents plugin z verze v7.0.0 na v8.0.0 (Architecture Rework). Popisuje všechny breaking changes, postup migrace krok za krokem, a rollback proceduru. Technický obsah je v angličtině.

---

## Overview

v8.0.0 is the last major structural change before the v9.0.0 public launch. It consolidates the plugin's agent count from 21 to 18, replaces the raw-text `.md` customization overlay system with a structured TOML 3-tier merge overlay, decomposes monolithic `SKILL.md` files into `steps/*.md` sub-files, and introduces a unified three-mode flag framework (`--yolo` / default / `--step-mode`) across all three pipelines (including scaffold, which previously used an interactive `(a)/(b)/(c)` prompt).

### Summary of breaking changes

| # | What changed | Who is affected |
|---|--------------|-----------------|
| 1 | `customization/{agent}.md` → `customization/{agent}.toml` | Projects using agent customization |
| 2 | 3 agent merges: 6 old agents → 3 new agents | Pipeline Profiles with skip stages; custom workflows referencing old names |
| 3 | SKILL.md steps decomposition | Authors of custom step overrides (new feature in v8.0.0); Pipeline Profiles named-phase syntax |
| 4 | Scaffold interactive mode prompt removed | Scripts/docs that reference `(a) Interactive`, `(b) YOLO with checkpoint`, `(c) Full YOLO` |

### What is NOT changing

- `## Automation Config` section structure (18 optional sections, unchanged)
- `state.json` schema version (stays `"1.0"`, only additive fields added)
- All 15 non-merged agents: `fixer`, `reviewer`, `acceptance-gate`, `publisher`, `rollback-agent`, `spec-analyst`, `architect`, `stack-selector`, `scaffolder`, `priority-engine`, `spec-writer`, `spec-reviewer`, `deployment-verifier`, `backlog-creator`, `sprint-planner`
- Existing skills (26 non-pipeline skills are unchanged)
- NEEDS_CLARIFICATION tracker-async feature (orthogonal, works across all modes)

---

## Prerequisites

Before running the migration:

1. **Back up your project configuration:**
   ```sh
   cp CLAUDE.md CLAUDE.md.bak-v7
   cp -r customization/ customization.manual-bak-v7/
   ```
2. **Verify your v7.0.0 pipeline is working** — run `/ceos-agents:check-setup` and confirm no errors.
3. **Ensure Git working tree is clean** — commit or stash any in-flight changes before running `/migrate-config --to-v8`.
4. **Python 3.6+** must be available on PATH (used by the TOML migration tooling for round-trip parse verification).

---

## TOML overlay conversion

Migration: Replace `customization/{agent}.md` with `customization/{agent}.toml`. Run `/ceos-agents:migrate-config --to-v8` for automated conversion.

### What changed

In v7.0.0, project-specific agent customization was stored as raw markdown text in `customization/{agent}.md`. The plugin appended this text verbatim to the agent's prompt.

In v8.0.0, the primary format is `customization/{agent}.toml` — a structured TOML file with 3-tier merge semantics:

| Tier | TOML construct | Semantics |
|------|----------------|-----------|
| 1 — Scalar override | `model = "sonnet"` | Project value wins; plugin default discarded |
| 2 — Array append | `[[process_additions]]`, `[[constraints]]` | Plugin defaults first, then project additions |
| 3 — Table deep merge | `[limits]` | Key-by-key union; project key wins on conflict |

### Before (v7.0.0 `.md` format)

```
# customization/reviewer.md
Always check for SQL injection in all database queries.
Block any PR introducing eval() or Function().
```

### After (v8.0.0 `.toml` format)

```toml
# customization/reviewer.toml

[[process_additions]]
step = "after_default"
instruction = "Always check for SQL injection in all database queries."

[[constraints]]
rule = "Block any PR introducing eval() or Function()."
```

The `step` field in `[[process_additions]]` is a canonical anchor name. For a catch-all (apply at end of agent process), use `step = "after_default"`. See `docs/guides/toml-overlay-syntax.md` for the full anchor name reference per agent.

### Deprecation alias

In v8.0.0, legacy `customization/{agent}.md` files still work but emit a `[WARN]` log:

```
[WARN] Legacy .md overlay format will be removed in v9.0.0; migrate via /migrate-config --to-v8
```

When both `.md` and `.toml` exist for the same agent, `.toml` takes precedence and `.md` is ignored (with a separate `[WARN]`). See the [Deprecation timeline](#deprecation-timeline) section.

---

## Agent rename mapping

Migration: Update every reference to a renamed agent (code-analyst → analyst-impact, e2e-test-engineer → test-engineer-e2e, reproducer → browser-agent-reproduce, browser-verifier → browser-agent-verify) in your CLAUDE.md, customization/, and any custom skills.

### What changed

Three pairs of agents were merged into single agents with internal phase/flag dispatch. The total agent count goes from 21 to 18.

### Full 6 → 3 rename mapping table

| Old agent (v7.0.0) | Phase / mode arg | New agent (v8.0.0) | Notes |
|--------------------|------------------|---------------------|-------|
| `triage-analyst` | `--phase triage` | `analyst` | Severity, area, AC extraction, complexity |
| `code-analyst` | `--phase impact` | `analyst` | Affected files (≤ 5), call-graph summary |
| `test-engineer` | (default, `--e2e=false`) | `test-engineer` | Name preserved; behavior extended |
| `e2e-test-engineer` | `--e2e=true` | `test-engineer` | Merged into existing test-engineer |
| `reproducer` | `--phase reproduce` | `browser-agent` | Pre-fix browser reproduction steps |
| `browser-verifier` | `--phase verify` | `browser-agent` | Post-fix browser verification |

### Complete v8.0.0 agent list (18 agents)

`analyst`, `fixer`, `reviewer`, `acceptance-gate`, `test-engineer`, `publisher`, `rollback-agent`, `spec-analyst`, `architect`, `stack-selector`, `scaffolder`, `priority-engine`, `spec-writer`, `spec-reviewer`, `browser-agent`, `deployment-verifier`, `backlog-creator`, `sprint-planner`

### Migration impact on `customization/` files

If you have overlay files for the old agent names, `/migrate-config --to-v8` renames them automatically:

| Old overlay file | New overlay file | Notes |
|------------------|------------------|-------|
| `customization/triage-analyst.md` | `customization/analyst.toml` | Phase tag: `--phase triage` |
| `customization/code-analyst.md` | `customization/analyst.toml` | Phase tag: `--phase impact` |
| `customization/e2e-test-engineer.md` | `customization/test-engineer.toml` | E2E sentinel added |
| `customization/reproducer.md` | `customization/browser-agent.toml` | Phase tag: `--phase reproduce` |
| `customization/browser-verifier.md` | `customization/browser-agent.toml` | Phase tag: `--phase verify` |

If both `customization/triage-analyst.md` and `customization/code-analyst.md` exist, they are merged into a single `customization/analyst.toml` with separate `[[process_additions]]` blocks tagged for each phase.

### Deprecation alias for old agent names

In v8.0.0, using an old agent name in `customization/` files or in `Skip stages:` lists emits a `[WARN]`:

```
[WARN] Agent name 'triage-analyst' deprecated; use 'analyst' (removed in v9.0.0)
```

The old agent files (`agents/triage-analyst.md`, `agents/code-analyst.md`, `agents/e2e-test-engineer.md`, `agents/reproducer.md`, `agents/browser-verifier.md`) no longer exist in v8.0.0. The plugin resolves deprecated names to their v8 equivalents at runtime.

---

## SKILL decomposition

Migration: Replace any references to the merged skills (e.g., separate analyst phases) with the consolidated v8 skill names; review your Pipeline Profiles for skip-stage entries that still use pre-v8 names.

### What changed

The three pipeline skills (`fix-bugs`, `implement-feature`, `scaffold`) were monolithic single-file `SKILL.md` files (~600 lines). In v8.0.0 each is restructured into:

- `skills/{skill}/SKILL.md` — entry point, ≤ 120 lines, contains mode flag parsing and step dispatch logic
- `skills/{skill}/steps/{NN-name}.md` — per-step instruction files (5–8 files per pipeline, ~100–200 lines each)

**This is transparent for most users.** Only authors of step overrides (see `docs/guides/steps-decomposition.md`) and Pipeline Profiles with stage skip syntax are affected.

### Step file layout reference

```
skills/fix-bugs/steps/
  01-triage.md
  02-impact.md
  03-reproduce.md          (conditional)
  04-fixer-reviewer-loop.md
  05-test.md
  06-acceptance-gate.md    (conditional)
  07-publish.md

skills/implement-feature/steps/
  01-spec.md
  02-architect.md
  03-decomposition.md
  04-fixer-reviewer-loop.md
  05-test.md
  06-acceptance-gate.md
  07-publish.md

skills/scaffold/steps/
  01-mode-resolve.md
  02-spec-write-review.md
  03-scaffold.md
  04-architect.md
  05-fixer-reviewer-loop.md
  06-test.md
  07-spec-verify.md
  08-final-report.md
```

### Step override (new feature in v8.0.0)

Projects can override individual steps by placing a file at:

```
customization/steps/{skill}/{NN-name}.md
```

Example — override the acceptance gate step for fix-bugs:

```
customization/steps/fix-bugs/06-acceptance-gate.md
```

The override is **replace-only**: it fully replaces the plugin-default step. Filename must match exactly (two-digit zero-padded prefix, kebab-case, `.md` extension). See `docs/guides/steps-decomposition.md` for full details.

### Pipeline Profiles named-phase syntax migration

The `Skip stages:` syntax in `### Pipeline Profiles` must use new named-phase identifiers in v8.0.0. v7 names are accepted with a `[WARN]` log (deprecation alias):

```
[WARN] Pipeline Profiles legacy stage name 'code-analyst' — consider migrating to 'analyst-impact'
```

See the [Skip stages syntax migration](#skip-stages-syntax-migration) section for the full conversion table.

---

## Plugin permission constraint

Migration: Audit your customization/ and CLAUDE.md hook configurations for any direct shell invocations that the v8 plugin permission model now requires explicit allow-listing for.

### What it is

The Claude Code platform **does not support** `hooks`, `mcpServers`, or `permissionMode` keys in plugin agent YAML frontmatter. These keys are silently ignored when present in agent files — they do not configure anything and create a false sense of security.

Starting with v8.0.0, these keys are explicitly banned from all 18 agent files in `agents/*.md`. This is a hard plugin-internal invariant enforced by Phase 8 verification.

### Correct pattern for project-level hooks

Project hooks are configured via the `### Hooks` section in your project's `## Automation Config` in `CLAUDE.md`, and are dispatched at the skill level via the Bash tool — NOT at the agent frontmatter level.

**Correct (skill-orchestrated hooks via Automation Config):**

```markdown
### Hooks

| Key | Value |
|-----|-------|
| Pre-fix | make pre-fix-check |
| Post-fix | make post-fix-notify |
```

<!-- COUNTER-EXAMPLE: The following agent frontmatter pattern is BLOCKED by the Claude Code platform and will be silently ignored. Do NOT use it. -->
```yaml
# BLOCKED — do not add hooks/mcpServers/permissionMode to agent frontmatter
hooks:
  pre_tool_use: echo "hook"
mcpServers:
  - name: my-server
permissionMode: "allowedTools"
```
<!-- END COUNTER-EXAMPLE -->

### Why this matters for migration

If your project has custom agent override files that add `hooks:`, `mcpServers:`, or `permissionMode:` keys to agent frontmatter, those keys are non-functional and should be removed. The intended functionality should be implemented via `### Hooks` in `## Automation Config`.

---

## Scaffold mode harmonization

Migration: Update any /scaffold invocation in CI or onboarding scripts to use the unified mode flag set (--yolo / default / --step-mode) introduced in v8.0.0.

### What changed

In v7.0.0, `/ceos-agents:scaffold` displayed an interactive mode selection prompt at startup:

```
Choose mode:
(a) Interactive — brainstorm if vague + spec checkpoint + feature plan checkpoint
(b) YOLO with checkpoint — 2 mandatory checkpoints, skip brainstorm
(c) Full YOLO — zero gates, autonomous
```

In v8.0.0 this prompt is **removed**. Scaffold uses the same three-mode flag framework as `fix-bugs` and `implement-feature`.

### Equivalence table

| v7 user invocation | v8.0.0 equivalent | Behavioral mapping |
|--------------------|---------------------|---------------------|
| `/scaffold "vague"` → prompt → `(a) Interactive` | `/scaffold "vague"` (no flag) | Brainstorm triggers (vague heuristic), then 2 checkpoints |
| `/scaffold "technical description ≥ 20 words"` → `(a)` or `(b)` | `/scaffold "technical description ≥ 20 words"` (no flag) | Brainstorm auto-skipped (non-vague heuristic); 2 checkpoints remain |
| `/scaffold "..."` → prompt → `(b) YOLO with checkpoint` | `/scaffold "..."` (no flag) | Same as default — 2 checkpoints, brainstorm only if vague |
| `/scaffold "..."` → prompt → `(c) Full YOLO` | `/scaffold "..." --yolo` | Zero gates, no brainstorm, fully autonomous |
| (no v7 equivalent) | `/scaffold "..." --step-mode` | New: per-step pause across all scaffold steps |

### Vague description heuristic

In default mode, the brainstorm step fires automatically when the description is vague. A description is considered **non-vague** (brainstorm skipped) when BOTH:

1. Word count ≥ 20
2. Contains at least one technical term (framework name, version number, file extension, CLI flag pattern)

If your workflow relied on `(b) YOLO with checkpoint` to skip brainstorm for short descriptions, write a more technical description (≥ 20 words with a technical term), or use `--yolo` to skip all gates.

### Scripts and automation

If you have wrapper scripts that pipe input to the scaffold prompt to select mode `(a)`, `(b)`, or `(c)`, those scripts will **break** in v8.0.0 — the prompt no longer exists. Update them to use flag-based invocation:

```sh
# v7 (interactive prompt — broken in v8)
echo "a" | claude -p "/ceos-agents:scaffold 'my project'"

# v8 (flag-based — correct)
claude -p "/ceos-agents:scaffold 'my project'"           # default mode
claude -p "/ceos-agents:scaffold 'my project' --yolo"    # fully autonomous
claude -p "/ceos-agents:scaffold 'my project' --step-mode"  # per-step pause
```

---

## Skip stages syntax migration

Migration: Translate every Skip stages: entry in CLAUDE.md from pre-v8 names (code-analyst, reproducer, browser-verifier, e2e-test-engineer) to the v8/v9 canonical names listed in CLAUDE.md "Stage names for skip:".

### Conversion table

Use these new named-phase identifiers in `### Pipeline Profiles → Skip stages`:

| v7 `Skip stages` value | v8.0.0 recommended syntax | Notes |
|-------------------------|----------------------------|-------|
| `code-analyst` | `analyst-impact` | Impact phase of merged analyst |
| `triage-analyst` | `analyst-triage` | Triage phase of merged analyst |
| `e2e-test-engineer` | `test-engineer-e2e` | E2E flag of test-engineer |
| `reproducer` | `browser-agent-reproduce` | Reproduce phase of browser-agent |
| `browser-verifier` | `browser-agent-verify` | Verify phase of browser-agent |
| `acceptance-gate` | `acceptance-gate` | Unchanged |

### Before (v7.0.0)

```markdown
### Pipeline Profiles

| Profile | Skip stages | Extra stages |
|---------|-------------|--------------|
| fast | code-analyst, e2e-test-engineer | |
| minimal | triage-analyst, code-analyst, e2e-test-engineer, browser-verifier | |
```

### After (v8.0.0)

```markdown
<!-- migrated v7→v8 by /migrate-config -->
### Pipeline Profiles

| Profile | Skip stages | Extra stages |
|---------|-------------|--------------|
| fast | analyst-impact, test-engineer-e2e | |
| minimal | analyst-triage, analyst-impact, test-engineer-e2e, browser-agent-verify | |
```

### Runtime alias behavior

v8.0.0 accepts v7 stage names at runtime (with `[WARN]` log) so pipelines continue working without running migration. However, this alias will be removed in v9.0.0. Run `/migrate-config --to-v8` to update the syntax permanently.

---

## /migrate-config --to-v8

Migration: Run /migrate-config --to-v8 once per project after upgrading; review the proposed diff before accepting (the skill operates on staged-diff preview semantics).

The `/ceos-agents:migrate-config --to-v8` skill automates the conversion of v7 project configuration to v8 format.

### Step 1: Preview with dry-run

```sh
/ceos-agents:migrate-config --to-v8 --dry-run
```

This scans your project and prints a planned-actions report **without modifying any files**. Example output:

```
# /migrate-config --to-v8 --dry-run report (no files modified)

PLANNED ACTIONS:
  1. Backup: customization/ → customization.bak-v7-2026-04-27T103000Z/
  2. customization/reviewer.md → customization/reviewer.toml (3 process_additions, 1 constraint)
  3. customization/triage-analyst.md → customization/analyst.toml (apply --phase triage)
  4. customization/code-analyst.md → MERGE INTO customization/analyst.toml (apply --phase impact)
  5. CLAUDE.md ## Automation Config: Skip stages [code-analyst] → [analyst-impact]

CONFLICTS DETECTED: 1
  customization/triage-analyst.md content mentions both phases ambiguously.
  Re-run without --dry-run to resolve interactively.

To apply: re-run without --dry-run.
```

### Step 2: Review preview and address conflicts

Read the dry-run report carefully. Conflicts arise when a single `customization/{agent}.md` file references behavior specific to multiple merged phases. You will be prompted to choose:

```
1) Apply to triage phase only
2) Apply to impact phase only
b) Apply to both phases
s) Skip this file (leave as .md, handle manually)
```

With `--yolo` flag, ambiguous files auto-resolve to option `b` (apply to both phases) with a `[WARN]` log.

### Step 3: Apply the migration

```sh
/ceos-agents:migrate-config --to-v8 --yes
```

The `--yes` flag confirms non-interactive application. The skill will:

1. Create backup: `customization.bak-v7-{timestamp}/` (atomically before any writes)
2. Convert each `customization/{agent}.md` to `customization/{agent}.toml`
3. Rename files for merged agents (per the [Agent rename mapping](#agent-rename-mapping) table)
4. Update `### Pipeline Profiles → Skip stages` syntax in `CLAUDE.md`
5. Print a summary report listing every change

### Step 4: Verify the setup

```sh
/ceos-agents:check-setup
```

Confirm all checks pass. If you see TOML parse errors, see the [Troubleshooting](#troubleshooting) section.

### Step 5: Run your existing test suite

If your project has a test suite configured in `### Build & Test`, run it to confirm the pipeline functions correctly with the migrated configuration:

```sh
/ceos-agents:scaffold-validate
```

### Migration summary report format

```
| File                              | Action                          | Detail                        |
|-----------------------------------|---------------------------------|-------------------------------|
| customization/reviewer.md         | Converted → reviewer.toml       | 3 process_additions           |
| customization/triage-analyst.md   | Renamed + converted → analyst.toml | --phase triage               |
| customization/code-analyst.md     | Merged → analyst.toml           | --phase impact                |
| CLAUDE.md (Pipeline Profiles)     | Skip stages updated             | code-analyst → analyst-impact |
```

---

## Deprecation timeline

### v8.0.0 (current release)

| Feature | Status | Behavior |
|---------|--------|----------|
| `customization/{agent}.md` legacy overlays | **Deprecated** | Accepted; emits `[WARN]` per invocation |
| Old agent names (`triage-analyst`, `code-analyst`, `e2e-test-engineer`, `reproducer`, `browser-verifier`) in `customization/` | **Deprecated** | Accepted; emits `[WARN]` per invocation |
| Old `Skip stages` values (`code-analyst`, `triage-analyst`, etc.) | **Deprecated** | Accepted at runtime; emits `[WARN]`; `/migrate-config --to-v8` updates them |
| `state.json` v7 alias keys (`triage_completed_at`, `code_analyst_completed_at`) | **Deprecated** | Written in v8.0.0 transitional mode; read by `/pipeline-status` with v8 key preferred |
| Scaffold interactive mode prompt `(a)/(b)/(c)` | **Removed** | Hard removal in v8.0.0; use flag-based invocation |

### v9.0.0 (hard removal target)

| Feature | Status |
|---------|--------|
| `customization/{agent}.md` legacy overlays | **Hard removal** — plugin will reject `.md` overlays with `[ERROR]` |
| Old agent names in any context | **Hard removal** — deprecated names will cause `[ERROR]` not `[WARN]` |
| `state.json` v7 alias keys | **Hard removal** — transitional alias keys no longer written |
| v7 `Skip stages` legacy values | **Hard removal** — unrecognized stage names cause pipeline abort |

**Action required before v9.0.0:** Run `/ceos-agents:migrate-config --to-v8` on all projects using this plugin.

---

## Troubleshooting

### TOML parse error after migration

**Symptom:** `[ERROR] TOML overlay validation failed for reviewer: {detail}`

**Common causes:**

1. **Triple-quote in content** — if your original `.md` overlay contained `"""`, the migration tool escapes it automatically. If you edited the `.toml` manually and broke the escaping, fix it:
   - Replace `"""` inside a triple-quoted string with `""\"`
   - Or switch to a single-line basic string with `\"` for embedded quotes

2. **Unknown key** — verify the key is in the allowed set for that agent. Check `docs/guides/toml-overlay-syntax.md`. Note: `[meta]` sub-keys are always accepted without validation.

3. **Syntax error** — validate with: `python3 -c "import tomllib; tomllib.load(open('customization/reviewer.toml', 'rb'))"`

### Step override not applied

**Symptom:** Custom step file exists in `customization/steps/{skill}/` but the plugin uses the default step.

**Common causes:**

1. **Filename mismatch** — the filename must exactly match the plugin-default step filename, including the two-digit zero-padded prefix: `06-acceptance-gate.md` not `6-acceptance-gate.md`.
2. **Case mismatch** — filenames are case-sensitive. `04-Fixer-Reviewer-Loop.md` does NOT match `04-fixer-reviewer-loop.md`.
3. **Underscore instead of hyphen** — `04_fixer_reviewer_loop.md` does NOT match `04-fixer-reviewer-loop.md`.

When the plugin detects a near-miss (possible mismatch), it emits:

```
[WARN] Possible misnamed step override: 04_fixer_reviewer_loop.md — did you mean 04-fixer-reviewer-loop.md?
```

Check the log output for this warning.

### `--step-mode` hangs waiting for input

**Symptom:** Pipeline stops with `[step-mode] Step N/total completed: step-name` and does not proceed.

**Cause:** `--step-mode` requires interactive terminal input. It is designed for interactive debugging, not for batch/CI use.

- For CI/automation: use `--yolo` flag
- For interactive use: respond with `c` (continue), `s` (skip remaining gates), or `a` (abort)
- Empty input is rejected (re-prompts) — press a key followed by Enter

If the shell is not attached to a TTY, the prompt will block indefinitely. Do not use `--step-mode` in non-interactive shells.

### Pipeline resumes from wrong step after `--step-mode` abort

If you aborted a `--step-mode` run with `a` and inline auto-resume (triggered by re-invoking the original entry-point skill, e.g. `/ceos-agents:fix-bugs <ID>`) skips the wrong step:

1. Check `.ceos-agents/state.json` — `last_completed_step` should name the last fully completed step
2. Run `/ceos-agents:pipeline-status {ID}` to confirm what the pipeline sees
3. If `last_completed_step` is incorrect (e.g., points to an in-flight step interrupted by Ctrl+C rather than `a`), this is expected — the atomicity guarantee ensures the interrupted step is re-run from scratch

---

## Rollback procedure

If the migration causes issues, restore from the automatic backup created by `/migrate-config --to-v8`:

### Step 1: Identify the backup directory

```sh
ls customization.bak-v7-*/
```

The directory name contains the ISO-8601 timestamp of the migration run (e.g., `customization.bak-v7-2026-04-27T103000Z/`).

### Step 2: Restore customization files

```sh
# Remove migrated files
rm -rf customization/

# Restore from backup
cp -r customization.bak-v7-2026-04-27T103000Z/ customization/
```

### Step 3: Restore CLAUDE.md

```sh
cp CLAUDE.md.bak-v7 CLAUDE.md
```

(If you created a manual backup per the Prerequisites step. The `/migrate-config --to-v8` tool does not back up `CLAUDE.md` separately — only `customization/` is backed up automatically.)

### Step 4: Downgrade the plugin

Re-install the v7.0.0 version of ceos-agents. After rollback, the v7 `.md` overlays and old agent names will work without warnings again.

### Notes on rollback safety

- The backup is created **atomically before any writes** — if the backup step fails (disk full, permission denied), the migration aborts and `customization/` is untouched.
- Backup includes all files present in `customization/` at migration time (recursive copy, permissions and timestamps preserved where the filesystem supports it).
- The backup directory is NOT automatically deleted after successful migration. Delete it manually when you are confident in the migration: `rm -rf customization.bak-v7-{timestamp}/`
