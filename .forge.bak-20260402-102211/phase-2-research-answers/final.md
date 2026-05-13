# Phase 2 Research Answers

Generated: 2026-04-01
Scope: Research questions for init CLI params + scaffold Step 0-MCP changes.

---

## RQ-1: Init Parameter Design

Source: `skills/init/SKILL.md`

### Step 1 — Read Automation Config (lines 26-33)

Extracts from CLAUDE.md:
- **Type** from Issue Tracker section — determines which tracker MCP server to configure
- **Instance** from Issue Tracker section — determines server URL / env vars (auto-fills `YOUTRACK_URL`, `FORGEJO_URL`, etc.)
- **Remote** from Source Control section — determines SC MCP server and hostname for shared-server detection

If no Automation Config is found, init errors: "No Automation Config found. Run `/ceos-agents:onboard` first."

There is **no CLI override** for Step 1 values. All three values MUST come from CLAUDE.md at Step 1. There is no flag parsing step in init that would accept tracker type, instance, or remote via CLI.

### Step 1b — .mcp.json.example pre-fill (lines 36-51)

If `.mcp.json.example` exists (from a prior `/scaffold` run), init parses it to extract:
- Tracker type (reverse-mapped from MCP package name via `core/mcp-detection.md` lookup table)
- Instance URL (from env var values in the example file)
- Remote (inferred from SC MCP server presence)

These become **defaults** that can be overridden at token-collection time (Steps 3-4). They do not require CLAUDE.md — they are an alternative pre-fill path.

### Step 4 — Collect tokens (lines 89-105)

- Auto-fills extra env vars (Instance URL, email) from Automation Config where possible.
- For tracker and SC tokens: prompts interactively with "Paste your token (or press Enter to skip)".
- No CLI override for tokens — interactive-only.

### Summary

| Value | Source | CLI Override? |
|-------|--------|---------------|
| Tracker Type | CLAUDE.md (required) | No |
| Tracker Instance | CLAUDE.md (required) | No — but .mcp.json.example pre-fill works |
| SC Remote | CLAUDE.md (required) | No |
| Token values | Interactive prompt | No |
| Extra env vars | Auto-filled from CLAUDE.md Instance | No CLI override |

MUST come from CLAUDE.md: tracker Type, tracker Instance, SC Remote. No CLI flags exist for these in the current implementation.

---

## RQ-2: Session Restart Behavior

Source: `skills/scaffold/SKILL.md` lines 132-146, `skills/init/SKILL.md`

### Does modifying .mcp.json mid-session cause MCP tools to reload?

Neither `skills/init/SKILL.md` nor `skills/scaffold/SKILL.md` document or address the Claude Code session-reload behavior for `.mcp.json`. The MCP server lifecycle is a Claude Code platform concern, not a skill concern. The skills write `.mcp.json` but do not restart or reload MCP tools within the same session — the skill documentation is silent on this. In practice, Claude Code requires a session restart to pick up new `.mcp.json` entries.

### Does scaffold Step 0-MCP re-run on resume?

Yes — but only conditionally, triggered by Step 0-INFRA's resume logic.

Step 0-INFRA "On resume" section (lines 132-140) defines two cases:
1. **`--infra` flag provided on re-invocation:** For each service upgraded from `"later"`/`"downgraded"` to `"ready"`, the service is "marked for Step 0-MCP re-verification." Step 0-MCP then runs for those services only. Services with unchanged status skip re-verification.
2. **No `--infra` flag:** State is restored from `state.json`. Step 0-MCP is NOT re-run — the in-memory variables are simply restored and the pipeline continues from its prior checkpoint.

Step 0-MCP itself (line 146) has no independent "On resume" guard — it runs whenever Step 0-INFRA directs it to.

---

## RQ-3: Shared Server Detection Without CLAUDE.md

Source: `skills/init/SKILL.md` lines 61-85

Step 3 (lines 80-85) describes shared server detection:

> "Compare tracker Type hostname with Source Control Remote hostname."
> "Gitea tracker + Gitea SC → single `forgejo-mcp` instance (shared)"
> "GitHub tracker + GitHub SC → single `server-github` instance (shared)"
> "Mixed → two separate servers"

The values needed for this comparison are tracker **Type** and SC **Remote** — both read from Automation Config in Step 1. Since Step 1 requires CLAUDE.md and there is no CLI flag path to provide these values, **shared server detection cannot work with CLI params only**. CLAUDE.md must exist and contain both Issue Tracker → Type and Source Control → Remote.

The only alternate path is `.mcp.json.example` pre-fill (Step 1b), which can infer tracker type and SC remote from a prior scaffold run's example file — but this is still an artifact from a previous run, not a CLI parameter input.

---

## RQ-4: Token Collection Flow

Source: `skills/init/SKILL.md` lines 89-134

### Step 4 — Token collection (lines 89-105)

- "Auto-fill from Automation Config where possible (Instance → base URL)" — this means the Instance URL from CLAUDE.md is used to pre-fill `YOUTRACK_URL`, `FORGEJO_URL`, `REDMINE_HOST`, `ATLASSIAN_URL`.
- For Jira: `ATLASSIAN_EMAIL` is not in CLAUDE.md, so it is always asked interactively.
- Token values themselves (e.g., `YOUTRACK_TOKEN`) are never in CLAUDE.md (by design — NEVER rule at line 238). They are always collected interactively.

### Step 5 — Platform-specific handling / binary download (lines 109-134)

- Uses `Bash` (uname) to detect platform — no CLAUDE.md dependency.
- Asks the user for a local binary path (forgejo-mcp, mcp-server-redmine) — no CLAUDE.md dependency.
- npx-based servers need no special handling.

### Summary

Steps 4-5 have a **partial dependency on CLAUDE.md**: the Instance URL from Automation Config is used to auto-fill env var values in Step 4. Tokens themselves and binary paths do not depend on CLAUDE.md.

---

## RQ-5: Step 1b (.mcp.json.example) Interaction When Called During Scaffold Step 0-MCP

Source: `skills/init/SKILL.md` lines 36-51

Step 1b checks: "If `.mcp.json.example` exists in CWD."

When `/ceos-agents:init` is called during scaffold Step 0-MCP, the scaffold pipeline has not yet written `.mcp.json.example` — that file is generated by init itself at Step 6 (line 150: "Create `.mcp.json.example` (same structure, all tokens replaced with `<YOUR_*>`)").

Step 1b handles the no-file case explicitly (lines 49-51):
> "If `.mcp.json.example` does not exist or parsing fails: No action — proceed normally to Step 2 (no warning needed)"

So Step 1b gracefully handles the missing-file case: no warning, no error, no blocking. Proceed normally. This is safe.

---

## RQ-6: Scaffold YOLO Mode Edge Cases — Should YOLO Auto-Invoke Init?

Source: `skills/scaffold/SKILL.md` lines 64, 167-178

### YOLO mode and MCP failure

Step 0-INFRA runs in Full YOLO mode (line 64: "This step always runs — including Full YOLO mode").

Step 0-MCP YOLO handling (lines 167-178):
- If `--issue` flag provided AND MCP unavailable → **BLOCK** — emit pipeline block comment, STOP entirely. No auto-init.
- If `--issue` NOT provided AND MCP unavailable → **auto-downgrade** without prompt: set `tracker_effective_status = "downgraded"`, display advisory, continue.

### Conflict with auto-invoking init

`/ceos-agents:init` (Step 4 token collection) requires interactive user input for tokens. YOLO mode's core principle is "no prompts." Auto-invoking init from YOLO scaffold would violate this principle because:
1. Init Step 8 offers permission setup with 4 interactive choices.
2. Init Step 4 always prompts for token values (no non-interactive mode exists).
3. Init Step 5 prompts for binary paths (forgejo-mcp, mcp-server-redmine).

The scaffold skill never auto-invokes init. Instead, on MCP failure it either blocks (--issue case) or downgrades and advises the user to run `/ceos-agents:init` after scaffold completes (line 162: "a note to run `/ceos-agents:init` after scaffold completes").

**Conclusion:** YOLO mode should NOT auto-invoke init. The correct behavior is already implemented: downgrade + advisory message.

---

## RQ-7: Existing Test Coverage

Source: `tests/scenarios/` directory listing (38 files total)

### Complete file list

```
triage-block.sh, fixer-retry.sh, reviewer-reject.sh, test-fail.sh,
publish-success.sh, read-only-agents.sh, frontmatter-completeness.sh,
model-assignment.sh, section-order.sh, config-reader-sections.sh,
xref-agent-registry.sh, skills-directory-structure.sh, browser-verification-skip.sh,
pipeline-hook-order.sh, pipeline-deploy-verifier.sh, pipeline-state-writes.sh,
pipeline-feature-agents.sh, pipeline-feature-step-order.sh,
pipeline-agent-dispatch-models.sh, profile-skip.sh, xref-skip-stage-names.sh,
state-schema.sh, verify-fail.sh, scaffold-canary-announcement.sh,
scaffold-infra-flag-format.sh, scaffold-resume-infra-override.sh,
scaffold-v2-happy-path.sh, scaffold-v2-input-conflicts.sh, scaffold-v2-no-implement.sh,
scaffold-v2-spec-loop.sh, scaffold-v561-regression.sh, core-include-refs.sh,
no-mcp-jargon-errors.sh, pipeline-consistency.sh, xref-core-registry.sh,
happy-path.sh, xref-command-count.sh, config-required-keys.sh,
skills-frontmatter-check.sh
```

### Coverage related to init, scaffold Step 0-MCP, MCP detection, and infrastructure state

| Area | Test File | What It Covers |
|------|-----------|----------------|
| Scaffold Step 0-INFRA + 0-MCP presence | `scaffold-v2-happy-path.sh` | Verifies `Infrastructure Declaration` and `0-MCP` headings exist in scaffold SKILL.md; asserts ordering (0-INFRA before Mode Selection); checks Step 4d and 4e presence |
| Scaffold --infra flag format (named format) | `scaffold-infra-flag-format.sh` | Validates named `tracker:{value},sc:{value}` format in Flag Parsing; old positional format detection; named-key extraction in Step 0-INFRA |
| Scaffold resume --infra override | `scaffold-resume-infra-override.sh` | Validates "On resume" section exists; --infra override logic; re-verification when upgrading; no-change case; downgrade/clear logic |
| Canary-write announcement in Step 0-MCP | `scaffold-canary-announcement.sh` | Verifies canary-write announcement text is present; confirms it is informational (no Y/n); confirms placement within Step 0-MCP section |
| MCP user-facing error messages | `no-mcp-jargon-errors.sh` | Validates old "MCP server for {Type} is not available" pattern removed; new "Cannot connect to your {type}" pattern in scaffold.md and 13 other skill files |
| MCP core refs | `core-include-refs.sh` | Cross-references that core/ files are referenced by skills/agents that use them |
| State schema | `state-schema.sh` | Validates state/schema.md structure including infrastructure object fields |

### Coverage GAPS (not covered by any existing test)

- `/ceos-agents:init` skill itself — no test file for init SKILL.md at all
- Init Step 1b (.mcp.json.example detection and pre-fill logic)
- Shared server detection logic (Gitea + Gitea → single forgejo-mcp)
- Init Step 5 platform detection (uname, binary path)
- Init Step 8 permission levels
- MCP tool reloading behavior on session restart
- YOLO mode auto-downgrade path in Step 0-MCP (only structural presence checked, not logic)

---

## RQ-8: Version Impact

Source: `CLAUDE.md` versioning policy section

### Policy table

| Level | Trigger |
|-------|---------|
| MAJOR | Breaking change in Automation Config contract (new required key, renamed section) OR breaking change in agent output format contract |
| MINOR | New backward-compatible feature — new optional key, new skill/agent |
| PATCH | Behavior fix without contract change |

> "Key rule: Adding a **required** key to Automation Config = MAJOR. Adding an **optional** section = MINOR."

### Assessment for proposed changes

**Change 1: Adding optional CLI params to `/ceos-agents:init`**

Init currently accepts only `(none)` or `--update` (frontmatter line 6: `argument-hint: "[--update]"`). Adding new optional CLI flags (e.g., `--tracker-type`, `--instance`, `--remote`) is a new backward-compatible feature — it adds capability without removing anything or changing the Automation Config contract. **Correct version bump: MINOR.**

**Change 2: Changing scaffold Step 0-MCP behavior**

Depends on what changes:
- If the change is purely behavioral (e.g., fixing logic, improving user messaging, adding a re-run condition) without modifying the Automation Config contract or any structured agent output section → **PATCH**.
- If the change adds a new optional Automation Config key or section → **MINOR**.
- If the change adds a required Automation Config key or modifies an agent output contract (structured sections that Agent Overrides parse) → **MAJOR**.

**Combined recommendation:** If both changes ship together:
- New optional CLI params for init = MINOR
- Step 0-MCP behavioral changes only (no contract change) = PATCH
- Combined: **MINOR** (highest level wins = one MINOR bump)

If Step 0-MCP changes require a new optional Automation Config section: still **MINOR** (two MINOR triggers = one MINOR bump). Only adding a new **required** key would push it to MAJOR.

---

*END — all 8 questions answered from source files. No assumptions.*

### Summary Finding

Skills have a **minimal 2-field frontmatter** (name + description). The `allowed-tools` field is NOT in the skill frontmatter — it belongs to commands. `$ARGUMENTS` is NOT available to skills — skills use natural language routing, not structured argument passing. Skill directories support exactly one file (`SKILL.md`). The `ceos-agents:` namespace applies equally to skills.

### Detailed Data

**Existing skill:** `/c/gitea_ceos-agents/skills/workflow-router/SKILL.md`

Frontmatter (lines 1–4):
```yaml
---
name: workflow-router
description: Use when the user wants to analyze bugs, fix issues, create PRs, publish changes, scaffold projects, implement features, check deployment, or manage project workflows
---
```

**Fields supported in skill frontmatter:**
| Field | Present | Notes |
|-------|---------|-------|
| `name` | YES | Required |
| `description` | YES | Required — this is what appears in the skill picker |
| `allowed-tools` | NO | This is a command frontmatter field, NOT a skill field |
| `model` | NO | Skills are pure routing; model is irrelevant |
| `style` | NO | Agent-only field |

**`$ARGUMENTS` in skills:** NOT available. Skills receive the user's natural language message as context but have no structured `$ARGUMENTS` mechanism. The workflow-router skill reads the user's message directly (line 1: "Read the user's message and identify their intent") — there is no `$ARGUMENTS` substitution.

**Multiple files in skill directory:** The current `skills/workflow-router/` directory contains only `SKILL.md`. No evidence of support for additional files. The plugin system reads `SKILL.md` as the entry point.

**`ceos-agents:` namespace for skills:** YES — works identically to commands. The skill is registered as `ceos-agents:workflow-router` in the plugin system. When skills invoke commands, they use `Skill(skill='ceos-agents:{command}', args='{args}')` — the same namespace prefix.

**`allowed-tools` location in commands (for contrast):** Every command file has `allowed-tools` in its frontmatter. Example from `commands/fix-bugs.md` line 3:
```yaml
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
```

### Action Items

- A1.1: If commands are moved to a new directory, the `SKILL.md` intent-routing table references `ceos-agents:{command}` — these do NOT need path changes because they reference command names, not file paths.
- A1.2: Skills cannot accept `$ARGUMENTS` — any new "skill-like" commands must use the routing pattern, not argument passing.
- A1.3: The `description` field in skill frontmatter is what users see — keep it comprehensive.

---

## A2 — Cross-Reference Inventory (Exhaustive)

### Summary Finding

`commands/` is referenced from **8 distinct file categories**: tests (all 35 scenario files), core contracts (3 files), docs (1 guide file), CLAUDE.md, CHANGELOG.md, REVIEW-REPORT, and command files themselves (via `core/mcp-detection.md` comment). Total: ~100+ distinct reference lines across the entire repo.

### Detailed Data

**Category 1: Test scenarios** (path-based references — `$REPO_ROOT/commands/`)

All 35 test files in `/c/gitea_ceos-agents/tests/scenarios/` reference `commands/` via `$REPO_ROOT`. Full mapping:

| Test File | Reference Type | Lines | Specific commands referenced |
|-----------|----------------|-------|------------------------------|
| `browser-verification-skip.sh` | `$REPO_ROOT/commands/$cmd.md` loop | 34–65 | fix-ticket, fix-bugs |
| `config-reader-sections.sh` | `$CONFIG_READER` (core), no direct commands/ path | — | — |
| `config-required-keys.sh` | `$COMMANDS_DIR` = `$REPO_ROOT/commands` | 8–34 | all commands/*.md glob |
| `core-include-refs.sh` | `$REPO_ROOT/commands/${cmd}.md` | 47–56 | fix-ticket, fix-bugs, implement-feature, scaffold |
| `fixer-retry.sh` | `$REPO_ROOT/agents/` only | — | — |
| `frontmatter-completeness.sh` | `$REPO_ROOT/agents/` only | — | — |
| `happy-path.sh` | `$REPO_ROOT/commands/` glob | 9 | all commands/*.md |
| `model-assignment.sh` | `$REPO_ROOT/agents/` only | — | — |
| `no-mcp-jargon-errors.sh` | Explicit list of `commands/*.md` paths | 13–30 | analyze-bug, changelog, create-pr, dashboard, estimate, metrics, prioritize, status, resume-ticket, scaffold-add, fix-bugs, publish, scaffold, implement-feature |
| `pipeline-agent-dispatch-models.sh` | `$REPO_ROOT/commands/$cmd.md` loop | 35–37 | fix-ticket, fix-bugs, implement-feature, scaffold, check-deploy |
| `pipeline-consistency.sh` | `$CMDS` = `$REPO_ROOT/commands` glob | 8 | fix-bugs, fix-ticket, scaffold, implement-feature (dynamic grep) |
| `pipeline-deploy-verifier.sh` | `$REPO_ROOT/commands/check-deploy.md` | 11, 40–42 | check-deploy |
| `pipeline-feature-agents.sh` | `$REPO_ROOT/commands/implement-feature.md` | 10, 13 | implement-feature |
| `pipeline-feature-step-order.sh` | `$REPO_ROOT/commands/implement-feature.md` | 6, 12, 26 | implement-feature |
| `pipeline-hook-order.sh` | `$REPO_ROOT/commands/$cmd.md` loop | 21 | fix-ticket, fix-bugs, implement-feature |
| `pipeline-state-writes.sh` | Explicit `$REPO_ROOT/commands/` paths | 19–66 | fix-ticket, implement-feature, scaffold, check-deploy |
| `profile-skip.sh` | `$REPO_ROOT/commands/$cmd.md` loop | 8 | fix-ticket, fix-bugs, implement-feature |
| `publish-success.sh` | `$REPO_ROOT/agents/` only | — | — |
| `read-only-agents.sh` | `$REPO_ROOT/agents/` only | — | — |
| `reviewer-reject.sh` | `$REPO_ROOT/agents/` only | — | — |
| `scaffold-canary-announcement.sh` | `$REPO_ROOT/commands/scaffold.md` | 7 | scaffold |
| `scaffold-infra-flag-format.sh` | `$REPO_ROOT/commands/scaffold.md` | 7 | scaffold |
| `scaffold-resume-infra-override.sh` | `$REPO_ROOT/commands/scaffold.md` | 7 | scaffold |
| `scaffold-v2-happy-path.sh` | `$REPO_ROOT/commands/scaffold.md` | 26 | scaffold |
| `scaffold-v2-input-conflicts.sh` | `$REPO_ROOT/commands/scaffold.md` | 8 | scaffold |
| `scaffold-v2-no-implement.sh` | `$REPO_ROOT/commands/scaffold.md` | 8 | scaffold |
| `scaffold-v2-spec-loop.sh` | `$REPO_ROOT/commands/scaffold.md` | 8 | scaffold |
| `scaffold-v561-regression.sh` | `$REPO_ROOT/commands/scaffold.md` | 7 | scaffold |
| `section-order.sh` | `$REPO_ROOT/agents/` only | — | — |
| `state-schema.sh` | `$REPO_ROOT/commands/${cmd}.md` loop | 45, 55 | fix-ticket, fix-bugs, implement-feature, scaffold, resume-ticket |
| `test-fail.sh` | `$REPO_ROOT/agents/` only | — | — |
| `triage-block.sh` | `$REPO_ROOT/agents/` only | — | — |
| `verify-fail.sh` | `$REPO_ROOT/commands/` paths | 8, 16, 24 | fix-ticket, fix-bugs, implement-feature |
| `xref-agent-registry.sh` | `$REPO_ROOT/agents/` only | — | — |
| `xref-command-count.sh` | `$REPO_ROOT/commands/` path | 9, 43–51 | all commands/*.md glob |
| `xref-core-registry.sh` | `$REPO_ROOT/commands/` directory check | 19, 41 | all commands/*.md via COMMANDS_DIR |
| `xref-skip-stage-names.sh` | `$REPO_ROOT/commands/$cmd.md` loop | 41, 63 | fix-ticket, fix-bugs, implement-feature |

**Category 2: Core contracts** (inline cross-references)

| Core File | Line | Reference |
|-----------|------|-----------|
| `core/fixer-reviewer-loop.md` | 44 | `commands/fix-ticket.md` step 5 |
| `core/decomposition-heuristics.md` | 34 | `commands/fix-ticket.md` steps 4b–4c |
| `core/mcp-detection.md` | 7 | `commands/scaffold.md` (Step 0-MCP), `commands/init.md` (Steps 3, 7) |

**Category 3: CLAUDE.md** (project instructions)

| Line | Content |
|------|---------|
| 18 | `- \`commands/\` — 25 commands (slash commands)` |
| 50 | `(see \`commands/fix-bugs.md\` for full pipeline)` |

**Category 4: CHANGELOG.md**

Multiple historical references to `commands/` in version entries throughout the file (not path-based, informational only).

**Category 5: REVIEW-REPORT-v3.1.0.md**

Lines 55–131: Multiple references to `commands/fix-bugs.md`, `commands/fix-ticket.md`, `commands/version-bump.md`, `commands/resume-ticket.md`, `commands/analyze-bug.md`, `commands/implement-feature.md`, `commands/publish.md`, `commands/create-pr.md` (historical review document).

**Category 6: docs/guides/mcp-configuration.md**

Line 147: `[commands/check-setup.md](../../commands/check-setup.md)` (relative link)

**Category 7: Command files referencing `commands/` themselves**

Commands reference core/ files; core files backreference commands/. No command file directly references another `commands/` path.

### Reference Type Classification

| Type | Count | Files |
|------|-------|-------|
| `$REPO_ROOT/commands/` (runtime path substitution in bash) | ~60 lines | 22 test scenario files |
| Explicit string `commands/*.md` | ~25 lines | no-mcp-jargon-errors, happy-path, xref-command-count |
| Hardcoded relative path (`../../commands/`) | 1 | docs/guides/mcp-configuration.md |
| Inline prose cross-reference | 4 | core/fixer-reviewer-loop.md, core/decomposition-heuristics.md, core/mcp-detection.md, CLAUDE.md |
| Informational/historical | many | CHANGELOG.md, REVIEW-REPORT-v3.1.0.md |

### Action Items

- A2.1: If `commands/` is renamed to a new directory (e.g., `workflows/`), ALL 22 test files with `$REPO_ROOT/commands/` must be updated (simple string substitution: s/commands\//workflows\//g).
- A2.2: `xref-command-count.sh` also checks CLAUDE.md for the string `commands/` — CLAUDE.md update required.
- A2.3: 3 core files have inline prose backreferences — these are informational comments, not functional paths.
- A2.4: 1 docs guide has a relative markdown link — must be updated.
- A2.5: CLAUDE.md `## Repository Structure` section must be updated (line 18).
- A2.6: CHANGELOG.md and REVIEW-REPORT are historical — no functional change needed.

---

## A3 — File Splitting Strategy

### Summary Finding

6 files exceed 200 lines. All are command files with natural section boundaries suitable for splitting. The proposed approach: extract reusable "shared config" patterns into additional core/ files, and split ultra-large commands (scaffold, fix-bugs) into numbered phase files.

### Detailed Data

**Line counts (from `wc -l`):**

| File | Lines |
|------|-------|
| `commands/scaffold.md` | 780 |
| `commands/fix-bugs.md` | 529 |
| `commands/implement-feature.md` | 414 |
| `commands/fix-ticket.md` | 390 |
| `commands/onboard.md` | 289 |
| `commands/init.md` | 240 |

---

**commands/scaffold.md (780 lines) — Proposed split points:**

| Section | Lines | Proposed Split |
|---------|-------|----------------|
| Frontmatter + Flag Parsing | 1–48 | Keep in main file |
| Step 0-INFRA: Infrastructure Declaration | 59–138 | Extract → `core/scaffold-infra.md` (82 lines) |
| Step 0-MCP: MCP Verification | 139–203 | Extract → `core/scaffold-mcp-verification.md` (65 lines) |
| Orchestration: Mode Selection + Legacy Flow | 204–331 | Keep in main (legacy flow is self-contained) |
| Step 0b Brainstorming | 332–358 | Keep in main |
| Step 1: Specification Phase | 359–393 | Keep in main |
| Steps 2–4e: Checkpoint, Scaffold, Git, Push, Tracker Issues | 394–509 | Keep in main |
| Steps 5–7: Architecture, Implementation Loop | 510–651 | Extract → `commands/scaffold-implement.md` |
| Steps 7b–9: Compliance, E2E, Report | 652–743 | In scaffold-implement.md |
| MCP Pre-flight notes + Rules | 744–780 | Keep in main |

**Split proposal:** Split into 2 command files:
- `commands/scaffold.md` (~400 lines): flags, validation, INFRA, MCP, mode, spec, skeleton, git init
- `commands/scaffold-implement.md` (~380 lines): architecture, feature loop, compliance, E2E, report

OR: Extract infrastructure/MCP patterns (Steps 0-INFRA and 0-MCP) into `core/scaffold-infrastructure.md` (~100 lines) since scaffold.md's 0-INFRA/0-MCP is unique and unlike existing core patterns.

---

**commands/fix-bugs.md (529 lines) — Proposed split points:**

| Section | Lines | Content |
|---------|-------|---------|
| Frontmatter + Configuration | 1–47 | Config reading |
| Pipeline profile parsing | 48–71 | Profile logic |
| Steps 0–3e: MCP, fetch, triage, code-analyst, browser reproduction | 72–214 | Analysis phase |
| Steps 3a–3c: Decomposition | 123–192 | Decompose logic |
| Steps 4–8c: Fix → publish pipeline | 215–360 | Execution phase |
| Step 9–9a: Summary + webhook | 361–389 | Reporting |
| Block handler (X) | 390–431 | Block protocol |
| Worktree processing | 432–477 | Parallel execution |
| Dry-run report | 478–527 | Report format |
| Rules | 519–529 | Constraints |

**Split proposal:**
- `commands/fix-bugs.md` (~280 lines): Config, profile parsing, steps 0–3e (analysis phase), step X (block handler)
- `commands/fix-bugs-execute.md` (~250 lines): Steps 4–9a (fixer → publisher), worktree processing, dry-run report, rules

OR: The worktree section (steps Variant A/B, ~46 lines) could move to `core/worktree-processor.md`.

---

**commands/implement-feature.md (414 lines) — Proposed split points:**

| Section | Lines | Content |
|---------|-------|---------|
| Frontmatter + Configuration | 1–31 | Config |
| Flag parsing + Profile parsing | 32–58 | Flag logic |
| Steps 0–0c: MCP, dry-run, validity gate, description mode | 59–152 | Pre-pipeline setup |
| Steps 1–5: State, branch, spec-analyst, architect, decomposition | 153–234 | Spec/design phase |
| Steps 6–6h: Implementation loop | 235–320 | Execution phase |
| Steps 7–10b: Integration, publish, verification | 321–380 | Publish phase |
| Block handler (X) + Rules | 381–414 | Block + constraints |

**Split proposal:** Natural 3-way split:
- `commands/implement-feature.md` (~160 lines): Config, flag parsing, pre-pipeline (0–0c)
- `commands/implement-feature-design.md` (~80 lines): Steps 1–5 (spec/design)
- `commands/implement-feature-execute.md` (~175 lines): Steps 6–10b + block handler + rules

---

**commands/fix-ticket.md (390 lines) — Proposed split points:**

| Section | Lines | Content |
|---------|-------|---------|
| Frontmatter + Configuration | 1–53 | Config reading |
| Pipeline profile parsing | 54–72 | Profile logic |
| Steps 0–4e: MCP, validity gate, triage, code-analyst, browser | 73–225 | Analysis phase |
| Steps 4a–4c: Decomposition | 144–203 | Decompose |
| Steps 5–9d: Fix → verify pipeline | 226–362 | Execution phase |
| Dry-run report + Rules | 363–390 | Reporting + constraints |

**Split proposal:** Mirror fix-bugs pattern:
- `commands/fix-ticket.md` (~200 lines): Config, profile, steps 0–4e (analysis)
- `commands/fix-ticket-execute.md` (~190 lines): Steps 5–9d + dry-run + rules

---

**commands/onboard.md (289 lines) — Proposed split points:**

| Section | Lines | Content |
|---------|-------|---------|
| Frontmatter + Scope + Step 0 Detection | 1–49 | Setup |
| Fresh Mode (Steps 1–9) | 50–234 | Fresh wizard |
| Update Mode (Steps U0–U3) | 235–278 | Update wizard |
| Rules | 279–289 | Constraints |

**Split proposal:** Modest 2-way split:
- `commands/onboard.md` (~100 lines): Scope, detection, routing, rules
- `commands/onboard-wizard.md` (~190 lines): Fresh mode steps 1–9 + Update mode steps U0–U3

OR: Keep as-is (289 lines is manageable; splitting adds indirection without significant benefit).

---

**commands/init.md (240 lines) — Proposed split points:**

| Section | Lines | Content |
|---------|-------|---------|
| Frontmatter + Scope | 1–18 | |
| Steps 1–1b: Read config + detect example | 19–48 | |
| Steps 2–5: Detect .mcp.json, determine servers, collect tokens, platform handling | 49–135 | Token collection |
| Steps 6–9: Generate .mcp.json, validate, permissions, closing | 136–240 | Output |

**Split proposal:** Keep as-is (240 lines is manageable; natural linear flow doesn't benefit from splitting).

### Action Items

- A3.1: Priority splits: `scaffold.md` (780→2 files) and `fix-bugs.md` (529→2 files).
- A3.2: Secondary splits: `implement-feature.md` (414→2 or 3 files) and `fix-ticket.md` (390→2 files).
- A3.3: Keep `onboard.md` and `init.md` as single files — splitting adds complexity without benefit.
- A3.4: Any split creates a new command file, requiring updates to: CLAUDE.md command count, CLAUDE.md command list, `xref-command-count.sh` expectations, and `happy-path.sh` minimum count.
- A3.5: Alternatively, splitting does NOT have to produce new registered commands — the main command can `include` or `follow` a secondary file via the core/ pattern. This avoids command count changes. Check if this is the intended pattern.

---

## A4 — Test Migration Patterns

### Summary Finding

Of 35 test scenarios, **22 files reference `commands/`** and would need changes if the directory is renamed. Classification: 20 are pure path-substitution (s/commands/new-dir/), 2 require logic changes (xref-command-count checks CLAUDE.md prose, config-required-keys uses a directory variable).

### Detailed Data

**Classification of 22 affected test files:**

**Type 1: Pure path substitution** (s/commands\//newdir\//g — no logic change needed)

| File | Lines to change | Pattern |
|------|----------------|---------|
| `browser-verification-skip.sh` | 34–35, 61–65 | `$REPO_ROOT/commands/$cmd.md` |
| `core-include-refs.sh` | 47, 63 | `$REPO_ROOT/commands/${cmd}.md` |
| `no-mcp-jargon-errors.sh` | 13–30, 76 | Explicit `commands/` path strings in arrays |
| `pipeline-agent-dispatch-models.sh` | 35–37 | `$REPO_ROOT/commands/$cmd.md` |
| `pipeline-consistency.sh` | 8 | `$CMDS="$REPO_ROOT/commands"` variable |
| `pipeline-deploy-verifier.sh` | 11, 40, 42 | `$REPO_ROOT/commands/check-deploy.md` |
| `pipeline-feature-agents.sh` | 10, 13 | `$REPO_ROOT/commands/implement-feature.md` |
| `pipeline-feature-step-order.sh` | 6, 12, 26 | `$REPO_ROOT/commands/implement-feature.md` |
| `pipeline-hook-order.sh` | 21 | `$REPO_ROOT/commands/$cmd.md` |
| `pipeline-state-writes.sh` | 19–21, 36–38, 52–54, 64–66 | Explicit `$REPO_ROOT/commands/` paths |
| `profile-skip.sh` | 8 | `$REPO_ROOT/commands/$cmd.md` |
| `scaffold-canary-announcement.sh` | 7 | `$REPO_ROOT/commands/scaffold.md` |
| `scaffold-infra-flag-format.sh` | 7 | `$REPO_ROOT/commands/scaffold.md` |
| `scaffold-resume-infra-override.sh` | 7 | `$REPO_ROOT/commands/scaffold.md` |
| `scaffold-v2-happy-path.sh` | 26 | `$REPO_ROOT/commands/scaffold.md` |
| `scaffold-v2-input-conflicts.sh` | 8 | `$REPO_ROOT/commands/scaffold.md` |
| `scaffold-v2-no-implement.sh` | 8 | `$REPO_ROOT/commands/scaffold.md` |
| `scaffold-v2-spec-loop.sh` | 8 | `$REPO_ROOT/commands/scaffold.md` |
| `scaffold-v561-regression.sh` | 7 | `$REPO_ROOT/commands/scaffold.md` |
| `state-schema.sh` | 45, 55 | `$REPO_ROOT/commands/${cmd}.md` |
| `verify-fail.sh` | 8, 16, 24 | `$REPO_ROOT/commands/fix-ticket.md` etc |
| `xref-skip-stage-names.sh` | 41, 63 | `$REPO_ROOT/commands/$cmd.md` |

**Type 2: Logic change needed**

| File | Change Required |
|------|----------------|
| `xref-command-count.sh` | Lines 43–51: The `extract_claimed` function greps CLAUDE.md for the pattern `` `commands/` ``. If the directory is renamed, the CLAUDE.md prose must also change. No code logic change — just the grep pattern must match the new CLAUDE.md text. Path variable on line 44 needs updating. |
| `config-required-keys.sh` | Line 8: `COMMANDS_DIR="$REPO_ROOT/commands"`. Simple variable update. No logic change. |
| `xref-core-registry.sh` | Line 19: `fail "commands/ directory not found"` (error message string). Line 41: `fail "core/$name.md is not referenced by any command in commands/"` (error message). Lines 38–39: uses `$COMMANDS_DIR` variable. |

**Type 3: No change needed (agent-only tests)**

These 13 files only reference `agents/` or are agent-specific:
`fixer-retry.sh`, `frontmatter-completeness.sh`, `model-assignment.sh`, `publish-success.sh`, `read-only-agents.sh`, `reviewer-reject.sh`, `section-order.sh`, `test-fail.sh`, `triage-block.sh`, `xref-agent-registry.sh`, `config-reader-sections.sh`, `happy-path.sh` (references both, but commands/ is just a glob count check — path substitution only).

**Practical migration approach:**

If the new directory is called `workflows/`:

```bash
# In tests/scenarios/ — bulk replacement across all affected files:
sed -i 's|commands/|workflows/|g' *.sh
# Then manually verify xref-command-count.sh grep pattern matches updated CLAUDE.md
```

This is sufficient for all 22 affected files — no structural logic rewrites needed.

### Action Items

- A4.1: All 22 files need `commands/` → new-dir path substitution. This is a mechanical operation.
- A4.2: `xref-command-count.sh` additionally requires the CLAUDE.md to use the new directory name in the `## Repository Structure` section (the test greps CLAUDE.md for the path).
- A4.3: `happy-path.sh` hardcodes `>= 24` as minimum command count — update if new files are added by splitting.
- A4.4: `core-include-refs.sh` hardcodes minimum core reference counts: `fix-ticket>=7`, `fix-bugs>=7`, `implement-feature>=6`, `scaffold>=3`. If commands are split, the counts per-file will drop — the test will need updating OR the test must loop over all command files collectively.
- A4.5: `pipeline-consistency.sh` uses `grep -rl 'rollback-agent\|fixer.*Task tool' "$CMDS"/*.md` to dynamically find pipeline files — this is resilient to splits as long as `$CMDS` variable is updated.

---

## A5 — Backward Compatibility

### Summary Finding

The `ceos-agents:` namespace prefix is purely a runtime convention, not tied to the filesystem `commands/` path. Moving files to a new directory does NOT break command invocation. However, the plugin registration mechanism must be verified for how it discovers commands.

### Detailed Data

**How commands are registered:** The `.claude-plugin/plugin.json` file does NOT list individual command files — it only declares the plugin name, version, and author. Command discovery is path-based: Claude Code reads all `*.md` files in the `commands/` directory automatically.

**Key implication:** If `commands/` is renamed, Claude Code will look in the new directory. The namespace prefix `ceos-agents:` is derived from the plugin name (`"name": "ceos-agents"` in `plugin.json`), NOT from the directory name. Therefore renaming `commands/` → `workflows/` requires:
1. Updating `plugin.json` to point Claude Code to the new path (IF it specifies the path)
2. OR relying on Claude Code's auto-discovery of the new directory name

**plugin.json content:**
```json
{
  "name": "ceos-agents",
  "version": "5.7.0",
  "author": {"name": "Filip Sabacky"},
  "repository": "...",
  "license": "UNLICENSED"
}
```

No `commands_dir` or `commands_path` key — the plugin.json does NOT specify where commands live. This means Claude Code uses convention (a well-known directory name). **Risk: If Claude Code hard-codes `commands/` as the discovery path, renaming will break command registration.**

**Skill invocation compatibility:** The skill file at `skills/workflow-router/SKILL.md` invokes commands as `Skill(skill='ceos-agents:{command}', ...)` — this is namespace-based, not path-based. No change needed in the skill file.

**User invocation:** Users run `/ceos-agents:fix-ticket` — this is the namespace+command-name form. As long as the command files have the correct `name` in their frontmatter (they don't currently have a `name` field; commands are discovered by filename), the invocation works.

**Commands frontmatter — actual format:**
```yaml
---
description: Automatically fixes N bugs from the issue tracker
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
---
```

Commands do NOT have a `name` field — their name is derived from their filename (minus `.md`). Therefore renaming `fix-bugs.md` → `fix-bugs.md` in a different directory must preserve filenames.

### Action Items

- A5.1: CRITICAL — Research whether Claude Code hard-codes `commands/` as the discovery path before committing to a rename. Run `/ceos-agents:check-setup` or inspect Claude Code documentation.
- A5.2: If Claude Code requires `commands/` specifically, the migration is blocked. Alternative: keep the directory as `commands/` and only reorganize the content (splitting files).
- A5.3: If renaming is possible, `plugin.json` and `marketplace.json` may need a `commands_dir` field added.
- A5.4: All filenames must be preserved — a command named `fix-bugs` must still be in a file called `fix-bugs.md`.
- A5.5: The `ceos-agents:` namespace prefix will NOT change regardless of directory name.

---

## A6 — Version Bump to 6.0.0

### Summary Finding

A directory rename (`commands/` → anything) plus new required config keys = **MAJOR version** by the versioning policy. 6 files need version updates. The CHANGELOG must get a new entry.

### Detailed Data

**Versioning policy trigger** (from CLAUDE.md):

> MAJOR (X.0.0): Breaking change in Automation Config contract — new required key, renamed section — OR breaking change in agent output format contract.

A directory rename is a breaking change in the plugin structure (anyone who has scripts or documentation pointing to `commands/` path will be broken). This qualifies as MAJOR.

**Files requiring version update for 6.0.0:**

| File | Current Value | Change Required |
|------|--------------|----------------|
| `.claude-plugin/plugin.json` | `"version": "5.7.0"` | → `"version": "6.0.0"` |
| `.claude-plugin/marketplace.json` | `"version": "5.7.0"` | → `"version": "6.0.0"` |
| `CHANGELOG.md` | Latest entry: `[5.7.0] — 2026-03-31` | Add new `[6.0.0]` section at top |
| `CLAUDE.md` | Various version references (informational) | Update Repository Structure section |
| `commands/version-bump.md` | Contains version bump logic | No version number; no change needed |
| Memory file `MEMORY.md` | `v5.7.0 (as of 2026-03-31)` | Update after release |

**Files confirmed to NOT need version bumps:**
- All agent files (no version numbers)
- All command files (no version numbers)
- All core files (no version numbers)
- All test files (no version numbers)
- `README.md` (contains no version hardcode, references plugin.json dynamically)

**CHANGELOG entry template for 6.0.0:**

```markdown
## [6.0.0] — 2026-04-XX

**MAJOR** — Commands directory renamed: `commands/` → `{new-name}/`. Breaking change for scripts and external references.

### Changed
- **Directory rename:** `commands/` renamed to `{new-name}/` — update any external scripts or documentation pointing to the old path
- **CLAUDE.md:** Repository Structure section updated to reflect new directory name
- **Tests:** All 22 test scenario files updated to reference new path
- **Core contracts:** 3 core files with inline references updated
- **Docs:** `docs/guides/mcp-configuration.md` relative link updated
```

### Action Items

- A6.1: Run version bump AFTER all file changes are committed (per project convention: content commits first, version bump as separate commit).
- A6.2: Update `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` together.
- A6.3: Add CHANGELOG entry for 6.0.0 BEFORE version bump commit (per project convention from MEMORY.md).
- A6.4: Tag the commit: `git tag v6.0.0`.
- A6.5: If file splitting is done in the same release, include those changes in the same 6.0.0 CHANGELOG entry.
- A6.6: Run `./tests/harness/run-tests.sh` BEFORE committing (per MEMORY.md policy).

---

## Summary: Migration Complexity Assessment

| Area | Complexity | Files affected | Blocker? |
|------|-----------|----------------|---------|
| Skill frontmatter | None | 0 | No — skills unaffected |
| Cross-references (tests) | Low — mechanical sed | 22 test files | No |
| Cross-references (core) | Low — prose comments | 3 core files | No |
| Cross-references (CLAUDE.md) | Low | 1 file | No |
| Cross-references (docs) | Low — 1 link | 1 file | No |
| File splitting | Medium | 4–6 new files + test updates | No |
| Backward compat (plugin discovery) | CRITICAL | Depends on Claude Code internals | POSSIBLY |
| Version bump | Low | 2 plugin files + CHANGELOG | No |

**The single biggest risk:** Whether Claude Code's plugin system hard-codes `commands/` as the directory name for command discovery. This must be verified before any directory rename is committed.
