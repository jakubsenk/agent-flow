# Research Answer 5: Namespace Reference Inventory

## Complete Reference List

Sources: exhaustive grep for `ceos-agents:`, `[ceos-agents]`, and bare `ceos-agents` across all files under `C:/gitea_ceos-agents/`. `.git/` object files excluded; `.git/logs/` and `.git/config` are included where they contain references. `.forge/` research artifacts and `docs/plans/brainstorm/` historical plans are included for completeness but flagged separately.

### Legend

- **ceos-agents:** = slash-command prefix or Task-tool dispatch prefix (e.g., `/ceos-agents:fix-ticket`, `ceos-agents:fixer`)
- **[ceos-agents]** = machine-parseable issue-tracker comment prefix
- **bare** = the string `ceos-agents` used as a plugin name, token label, or prose reference (not a functional invocation)
- **Class A** = Internal-only: command orchestration files, agent definitions, skill router. Safe to update in one PR with no user impact beyond the PR itself.
- **Class B** = User-facing documentation: README, docs/**, CONTRIBUTING, CHANGELOG, CLAUDE.md, getting-started.md, guides, reference docs. Requires coordinated release note.
- **Class C** = External data format written to issue trackers at runtime: comment templates in agent/command files whose exact text is posted to YouTrack/GitHub/Jira and cannot be retroactively changed.

---

### Table Part 1: Command files (`commands/*.md`)

| File | Line(s) | Reference type | Context | Class |
|------|---------|----------------|---------|-------|
| `commands/analyze-bug.md` | 15 | `ceos-agents:` (slash cmd) | MCP guard error message: "Run `/ceos-agents:check-setup`…" — user-visible error | B |
| `commands/analyze-bug.md` | 19 | `ceos-agents:` (slash cmd) | Usage hint printed to user: "Usage: /ceos-agents:analyze-bug" | B |
| `commands/analyze-bug.md` | 21 | `ceos-agents:` (Task tool) | Internal agent dispatch: `Run ceos-agents:triage-analyst` | A |
| `commands/analyze-bug.md` | 22 | `[ceos-agents]` | Triage checkpoint comment template posted to issue tracker | C |
| `commands/analyze-bug.md` | 23 | `ceos-agents:` (Task tool) | Internal agent dispatch: `run ceos-agents:code-analyst` | A |
| `commands/changelog.md` | 15 | `ceos-agents:` (slash cmd) | MCP guard error message — user-visible | B |
| `commands/check-setup.md` | 53, 59 | `ceos-agents:` (slash cmd) | FAIL messages referencing `/ceos-agents:init` — user-visible output | B |
| `commands/check-setup.md` | 121 | `ceos-agents:` (bare+colon) | Conflict warning: `ceos-agents:{cmd}` — user-visible | B |
| `commands/create-pr.md` | 17 | `ceos-agents:` (slash cmd) | MCP guard error message — user-visible | B |
| `commands/dashboard.md` | 29 | `ceos-agents:` (slash cmd) | MCP guard error message — user-visible | B |
| `commands/dashboard.md` | 40, 42, 65, 87 | `[ceos-agents]` | Internal parsing instructions: "Parse [ceos-agents] comments" — commands telling Claude how to parse issue tracker comments | A |
| `commands/estimate.md` | 23 | `ceos-agents:` (slash cmd) | MCP guard error message — user-visible | B |
| `commands/fix-bugs.md` | 71 | `ceos-agents:` (slash cmd) | MCP guard error message — user-visible | B |
| `commands/fix-bugs.md` | 87, 101, 184, 195, 225, 234, 244, 251, 268, 287, 355 | `ceos-agents:` (Task tool) | Internal agent dispatch calls | A |
| `commands/fix-bugs.md` | 317 | `[ceos-agents]` | Verify success comment template posted to issue tracker: `[ceos-agents] ✅ Fix verified.` | C |
| `commands/fix-bugs.md` | 368 | `[ceos-agents]` | Block comment template posted to issue tracker: `[ceos-agents] 🔴 Pipeline Block` | C |
| `commands/fix-ticket.md` | 78 | `ceos-agents:` (slash cmd) | MCP guard error message — user-visible | B |
| `commands/fix-ticket.md` | 102, 113, 194, 205, 235, 244, 254, 261, 278, 298, 351 | `ceos-agents:` (Task tool) | Internal agent dispatch calls | A |
| `commands/fix-ticket.md` | 335 | `[ceos-agents]` | Verify success comment template: `[ceos-agents] ✅ Fix verified.` | C |
| `commands/fix-ticket.md` | 340 | `[ceos-agents]` | Verify failure comment template: `[ceos-agents] ❌ Fix verification failed.` | C |
| `commands/fix-ticket.md` | 364 | `[ceos-agents]` | Block comment template: `[ceos-agents] 🔴 Pipeline Block` | C |
| `commands/fix-ticket.md` | 394 | `ceos-agents:` (slash cmd) | Dry-run output message — user-visible | B |
| `commands/implement-feature.md` | 63 | `ceos-agents:` (slash cmd) | MCP guard error message — user-visible | B |
| `commands/implement-feature.md` | 212 | `ceos-agents:` (Task tool) | Internal agent dispatch | A |
| `commands/implement-feature.md` | 278, 281 | `[ceos-agents]` | Verify success/failure comment templates posted to issue tracker | C |
| `commands/implement-feature.md` | 295 | `[ceos-agents]` | Block comment template: `[ceos-agents] 🔴 Pipeline Block` | C |
| `commands/init.md` | 10, 30 | `ceos-agents:` (slash cmd) | User-visible prose and error message | B |
| `commands/init.md` | 205, 208 | `ceos-agents:` (slash cmd) | Closing message printed to user | B |
| `commands/metrics.md` | 29 | `ceos-agents:` (slash cmd) | MCP guard error message — user-visible | B |
| `commands/metrics.md` | 37, 60, 62, 64 | `[ceos-agents]` | Internal parsing instructions: "Parse [ceos-agents] comments" — how to compute metrics from issue tracker | A |
| `commands/migrate-config.md` | 86 | `ceos-agents:` (slash cmd) | Error message printed to user | B |
| `commands/onboard.md` | 42, 55 | `ceos-agents:` (slash cmd) | User-facing prompts and wizard text | B |
| `commands/onboard.md` | 214, 215, 216, 221 | `ceos-agents:` (slash cmd) | Closing message printed to user | B |
| `commands/prioritize.md` | 22 | `ceos-agents:` (slash cmd) | MCP guard error message — user-visible | B |
| `commands/prioritize.md` | 36 | `ceos-agents:` (Task tool) | Internal agent dispatch | A |
| `commands/publish.md` | 15 | `ceos-agents:` (slash cmd) | MCP guard error message — user-visible | B |
| `commands/publish.md` | 23 | `ceos-agents:` (Task tool) | Internal agent dispatch | A |
| `commands/resume-ticket.md` | 17, 18 | `[ceos-agents]` | Checkpoint state detection — `[ceos-agents] Triage completed.` and `[CLAUDE-agents]` (legacy) — parsing logic | A |
| `commands/resume-ticket.md` | 51 | `ceos-agents:` (slash cmd) | MCP guard error message — user-visible | B |
| `commands/resume-ticket.md` | 64, 65 | `[ceos-agents]` | Pipeline type detection by comment prefix — internal logic | A |
| `commands/resume-ticket.md` | 85, 86 | `[ceos-agents]` | Checkpoint detection strings: `[ceos-agents] Spec analysis completed.` and `[ceos-agents] Triage completed.` | A |
| `commands/resume-ticket.md` | 97 | `[ceos-agents]` | Backward-compat note (internal instruction): `[ceos-agents]` is new, `[CLAUDE-agents]` is legacy | A |
| `commands/scaffold-add.md` | 24 | `ceos-agents:` (slash cmd) | MCP guard error message — user-visible | B |
| `commands/scaffold.md` | 141, 142 | `ceos-agents:` (slash cmd) | User-facing completion message with next steps | B |
| `commands/scaffold.md` | 375 | `[ceos-agents]` | Block comment template posted to issue tracker | C |
| `commands/scaffold.md` | 468, 469 | `ceos-agents:` (slash cmd) | Completion message printed to user | B |
| `commands/scaffold.md` | 483 | `ceos-agents:` (slash cmd) | MCP guard error message — user-visible | B |
| `commands/status.md` | 15 | `ceos-agents:` (slash cmd) | MCP guard error message — user-visible | B |
| `commands/status.md` | 44, 47, 49, 50, 53, 54, 56, 59 | `ceos-agents:` (slash cmd) | Recommended next-step messages printed to user | B |
| `commands/template.md` | 33, 46, 51 | `ceos-agents:` (slash cmd) | Usage hints and error messages printed to user | B |
| `commands/version-bump.md` | 8, 25 | bare `ceos-agents` | Prose description and guard message | B |
| `commands/version-check.md` | 8, 14, 25, 26, 27, 32, 34, 36, 37, 41 | bare `ceos-agents` | Version status messages printed to user; path `~/.claude/plugins/marketplaces/ceos-agents/` | B |

---

### Table Part 2: Agent files (`agents/*.md`)

| File | Line(s) | Reference type | Context | Class |
|------|---------|----------------|---------|-------|
| `agents/architect.md` | 99 | `[ceos-agents]` | Block comment template in Constraints section: `[ceos-agents] 🔴 Pipeline Block` | C |
| `agents/code-analyst.md` | 27, 42 | `[ceos-agents]` | Process step: search for prior `[ceos-agents]` comments in issue tracker (parsing instruction) | A |
| `agents/code-analyst.md` | 58 | `[ceos-agents]` | Block comment template: `[ceos-agents] 🔴 Pipeline Block` | C |
| `agents/e2e-test-engineer.md` | 61 | `[ceos-agents]` | Block comment template: `[ceos-agents] 🔴 Pipeline Block` | C |
| `agents/fixer.md` | 86 | `[ceos-agents]` | Block comment template: `[ceos-agents] 🔴 Pipeline Block` | C |
| `agents/priority-engine.md` | 23 | `[ceos-agents]` | Process step: use historical `[ceos-agents]` comments as data source (parsing instruction) | A |
| `agents/priority-engine.md` | 71 | `[ceos-agents]` | Block comment template: `[ceos-agents] 🔴 Pipeline Block` | C |
| `agents/publisher.md` | 88 | `[ceos-agents]` | Block comment template: `[ceos-agents] 🔴 Pipeline Block` | C |
| `agents/reviewer.md` | 111 | `[ceos-agents]` | Block comment template: `[ceos-agents] 🔴 Pipeline Block` | C |
| `agents/rollback-agent.md` | 62 | `[ceos-agents]` | Block comment template: `[ceos-agents] 🔴 Pipeline Block` | C |
| `agents/spec-analyst.md` | 55 | `[ceos-agents]` | Spec-analysis checkpoint comment template: `[ceos-agents] Spec analysis completed.` — posted to issue tracker | C |
| `agents/spec-analyst.md` | 60 | `[ceos-agents]` | AC listing comment template: `[ceos-agents] Acceptance Criteria:` — posted to issue tracker | C |
| `agents/spec-analyst.md` | 76 | `[ceos-agents]` | Block comment template: `[ceos-agents] 🔴 Pipeline Block` | C |
| `agents/spec-writer.md` | 88 | `[ceos-agents]` | Block comment template: `[ceos-agents] Pipeline Block` (note: missing 🔴 emoji — pre-existing gap) | C |
| `agents/test-engineer.md` | 55 | `[ceos-agents]` | Block comment template: `[ceos-agents] 🔴 Pipeline Block` | C |
| `agents/triage-analyst.md` | 70 | `[ceos-agents]` | Triage checkpoint comment template: `[ceos-agents] Triage completed. Severity: {severity}. Area: {area}. Complexity: {complexity}. AC: {count}.` — posted to issue tracker | C |
| `agents/triage-analyst.md` | 78 | `[ceos-agents]` | Block comment template: `[ceos-agents] 🔴 Pipeline Block` | C |

---

### Table Part 3: Skill file (`skills/bug-workflow/SKILL.md`)

| File | Line(s) | Reference type | Context | Class |
|------|---------|----------------|---------|-------|
| `skills/bug-workflow/SKILL.md` | 12–38 | `ceos-agents:` (skill/cmd names) | Intent mapping table: 24 rows mapping natural language intents to `ceos-agents:<command>` invocation names | A |
| `skills/bug-workflow/SKILL.md` | 43 | `ceos-agents:` (Skill() call) | Invocation example for non-destructive commands: `Skill(skill='ceos-agents:analyze-bug', ...)` | A |
| `skills/bug-workflow/SKILL.md` | 47 | `ceos-agents:` (Skill() call) | Invocation template for confirmed destructive commands: `Skill(skill='ceos-agents:{command}', ...)` | A |

---

### Table Part 4: Core project files (`CLAUDE.md`, `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`)

| File | Line(s) | Reference type | Context | Class |
|------|---------|----------------|---------|-------|
| `CLAUDE.md` | 168, 170, 172 | `ceos-agents:` (slash cmd) | Plugin Composability section — contract documentation for contributors and plugin consumers | B |
| `CLAUDE.md` | 179, 190 | `[ceos-agents]` | Block Comment Template and Triage checkpoint format — templates defining the external comment format | C |
| `CLAUDE.md` | 193 | `[ceos-agents]` | Explanatory prose about the prefix — documentation | B |
| `README.md` | 59, 62, 65, 161, 196 | `ceos-agents:` (slash cmd) | Quick-start examples and command reference table — user-facing | B |
| `CHANGELOG.md` | 62, 161, 166, 173 | `ceos-agents:` and `[ceos-agents]` | Historical release notes documenting the rename and format changes — changelog prose | B |
| `CONTRIBUTING.md` | 1, 3 | bare `ceos-agents` | Title and prose — documentation | B |

---

### Table Part 5: Documentation files (`docs/**/*.md`)

| File | Line(s) | Reference type | Context | Class |
|------|---------|----------------|---------|-------|
| `docs/getting-started.md` | 32, 41, 115, 125, 132, 160, 170, 190, 200, 220–222, 257–259 | `ceos-agents:` (slash cmd) | Step-by-step onboarding guide — user-facing | B |
| `docs/architecture.md` | 52, 143, 200, 217, 218, 263, 264 | `ceos-agents:` (slash cmd) and `[ceos-agents]` | Architecture reference — user-facing | B |
| `docs/guides/installation.md` | 45, 64 | `ceos-agents:` (slash cmd) | Installation verification instructions — user-facing | B |
| `docs/guides/troubleshooting.md` | 15, 27, 29, 51, 52, 59, 94, 97, 115, 128, 146, 174, 188, 269, 270, 274, 282 | `ceos-agents:` (slash cmd) | Troubleshooting steps — user-facing | B |
| `docs/guides/mcp-configuration.md` | 5, 144 | `ceos-agents:` (slash cmd) | Setup guide — user-facing | B |
| `docs/guides/custom-agents.md` | 146, 154 | `[ceos-agents]` and `ceos-agents:` | Block comment template example in guide; test instruction | B |
| `docs/guides/cross-platform.md` | 14, 15, 24, 25 | `ceos-agents:` (slash cmd) | Cross-platform validation checklist — user-facing | B |
| `docs/guides/tokens.md` | 1, 3, 23, 31, 39, 47, 55 | bare `ceos-agents` | Token naming convention: `ceos-agents-<PROJECT>` — user-facing naming guidance | B |
| `docs/reference/commands.md` | 7, 52, 63, 67–629 (many lines) | `ceos-agents:` (slash cmd) | Exhaustive command reference with syntax and examples — user-facing | B |
| `docs/reference/agents.md` | 98, 130, 200 | `[ceos-agents]` | Example output blocks showing comment formats — user-facing | B |
| `docs/reference/pipelines.md` | 14, 52, 53, 55, 57, 101, 125, 204, 298, 321, 336, 344, 383, 386 | `ceos-agents:` and `[ceos-agents]` | Pipeline reference — user-facing | B |
| `docs/reference/automation-config.md` | 212, 292, 321, 330, 359, 366 | `ceos-agents:` (slash cmd) | Config reference — user-facing | B |
| `docs/reference/execution-loop.md` | 43 | `[ceos-agents]` | Execution loop reference showing block comment format — user-facing | B |

---

### Table Part 6: Plugin metadata (`.claude-plugin/`)

| File | Line(s) | Reference type | Context | Class |
|------|---------|----------------|---------|-------|
| `.claude-plugin/plugin.json` | 2 | bare `ceos-agents` | `"name": "ceos-agents"` — this field IS the namespace. The plugin name determines the `ceos-agents:` prefix on all commands and skills | A (source of truth) |
| `.claude-plugin/marketplace.json` | 2, 8 | bare `ceos-agents` | `"name": "ceos-agents"` repeated in marketplace metadata | A |

---

### Table Part 7: Test files (`tests/**/*`)

| File | Line(s) | Reference type | Context | Class |
|------|---------|----------------|---------|-------|
| `tests/harness/run-tests.sh` | 2, 14 | bare `ceos-agents` | Script comment and echo label — test infrastructure | A |
| `tests/harness/mock-mcp-server.sh` | 2 | bare `ceos-agents` | Script comment — test infrastructure | A |
| `tests/harness/fixtures/issues.json` | 30 | `[ceos-agents]` | Fixture data: `"[ceos-agents] Triage completed. Severity: HIGH. Area: API."` — hardcoded test fixture simulating an issue tracker comment | A |
| `tests/scenarios/pipeline-consistency.sh` | 19, 21 | `[ceos-agents]` | Test assertion: grep for `[ceos-agents].*Pipeline Block` and validates emoji presence | A |
| `tests/README.md` | 1 | bare `ceos-agents` | Section heading — documentation | B |
| `tests/mock-project/CLAUDE.md` | 3 | bare `ceos-agents` | Prose description in mock project — test infrastructure | A |

---

### Table Part 8: CI/CD (`.gitea/workflows/test.yaml`)

| File | Line(s) | Reference type | Context | Class |
|------|---------|----------------|---------|-------|
| `.gitea/workflows/test.yaml` | 1 | bare `ceos-agents` | Workflow name: `Test ceos-agents` — CI label | A |

---

### Table Part 9: Runtime configuration (`.claude/settings.local.json`)

| File | Line(s) | Reference type | Context | Class |
|------|---------|----------------|---------|-------|
| `.claude/settings.local.json` | 56 | `ceos-agents:` (Skill() call) | `"Skill(ceos-agents:version-bump)"` in allowedTools list — local developer config, NOT committed | A (not tracked) |

---

### Table Part 10: Historical plans and `.forge/` artifacts

These files are internal design/planning documents and research artifacts. They are not user-facing operational surfaces. All are Class A for update purposes; none are externally-written data.

| File | Notes |
|------|-------|
| `docs/plans/brainstorm/IMPLEMENTATION-PLAN.md` | Historical rename-planning document; dozens of `ceos-agents:` references documenting the CLAUDE-agents → ceos-agents migration |
| `docs/plans/brainstorm/EXECUTE-AND-REVIEW.md` | Historical execution log |
| `docs/plans/brainstorm/DECISIONS.md` | Decision records |
| `docs/plans/2026-03-08-ac-pipeline-v5-plan.md` | Plan with comment format examples |
| `docs/plans/2026-03-08-ac-pipeline-evaluation.md` | Evaluation notes |
| `docs/plans/2026-03-08-bugfix-pipeline-discuss.md` | Discussion notes |
| `docs/plans/2026-03-06-scaffold-v2-EXECUTE.md` | Execution log |
| `docs/plans/2026-03-06-scaffold-v2-implementation-plan.md` | Implementation plan |
| `docs/plans/2026-03-06-pipeline-consistency-design.md` | Design notes |
| `docs/plans/2026-03-09-browser-verification-plan.md` | Plan with agent dispatch examples |
| `docs/plans/2026-03-09-v5.0.0-post-release-review.md` | Post-release review |
| `docs/plans/quality-improvements-plan.md` | Plan with status message examples |
| `docs/plans/competitive-analysis.md` | Competitive analysis (Czech) with command references |
| `docs/plans/roadmap.md` | Roadmap with potential new command reference |
| `docs/plans/analysis-improvements-REVIEW.md` | Review doc (untracked) |
| `docs/plans/v3.1-scalability-assessment.md` | Assessment document |
| `docs/plans/README.md` | Index document |
| `.forge/phase-0-meta/**` | Forge prompts and analysis (all research artifacts) |
| `.forge/phase-1-research-questions/**` | Phase 1 research output |
| `.forge/phase-2-research-answers/agents/agent-1.md` | Phase 2 research artifact |
| `.git/logs/HEAD`, `.git/logs/refs/heads/main`, `.git/config` | Git metadata — immutable history |

All entries above: Class A (internal/archived). The `.git/logs/` entries are immutable git history — updating the namespace would not change them.

---

## Classification Summary

### Class A: Internal-Only (safe to update in a single PR)

Count: approximately 60 individual references across 18 files.

Key files:
1. `commands/fix-ticket.md` — Task-tool dispatch calls (`ceos-agents:triage-analyst` etc., 11 occurrences)
2. `commands/fix-bugs.md` — Task-tool dispatch calls (11 occurrences)
3. `commands/implement-feature.md` — Task-tool dispatch (1 occurrence)
4. `commands/analyze-bug.md` — Task-tool dispatch (2 occurrences)
5. `commands/publish.md` — Task-tool dispatch (1 occurrence)
6. `commands/prioritize.md` — Task-tool dispatch (1 occurrence)
7. `commands/dashboard.md` — `[ceos-agents]` parsing instructions (4 occurrences)
8. `commands/metrics.md` — `[ceos-agents]` parsing instructions (4 occurrences)
9. `commands/resume-ticket.md` — `[ceos-agents]` detection strings for pipeline stage inference (5 occurrences)
10. `skills/bug-workflow/SKILL.md` — 24-row intent table + 2 Skill() call templates (26 occurrences)
11. `.claude-plugin/plugin.json` — `"name": "ceos-agents"` (the source of the namespace, 1 occurrence)
12. `.claude-plugin/marketplace.json` — plugin name (2 occurrences)
13. `tests/harness/run-tests.sh` — comments/labels (2 occurrences)
14. `tests/harness/mock-mcp-server.sh` — comment (1 occurrence)
15. `tests/harness/fixtures/issues.json` — fixture data simulating a tracker comment (1 occurrence)
16. `tests/scenarios/pipeline-consistency.sh` — test assertion strings (2 occurrences)
17. `tests/mock-project/CLAUDE.md` — prose (1 occurrence)
18. `.gitea/workflows/test.yaml` — workflow name (1 occurrence)

**Important subtlety for Class A items:** The `[ceos-agents]` occurrences in `dashboard.md`, `metrics.md`, and `resume-ticket.md` are parsing instructions telling Claude how to detect comments that were ALREADY posted to issue trackers by agents. Updating those detection strings in a single PR is internally safe (the commands work), BUT if the format they are detecting changes simultaneously, existing comments in issue trackers would no longer be detected. These are operationally Class A (file update is safe) but functionally coupled to Class C comments already written.

---

### Class B: User-Facing Documentation (requires release note)

Count: approximately 160 individual references across 24 files.

Key files (by category):

**Operational guides and quick-start:**
- `README.md` (5 occurrences)
- `docs/getting-started.md` (~15 occurrences)
- `docs/guides/installation.md` (2 occurrences)
- `docs/guides/troubleshooting.md` (~17 occurrences)
- `docs/guides/mcp-configuration.md` (2 occurrences)
- `docs/guides/cross-platform.md` (4 occurrences)
- `docs/guides/tokens.md` (7 occurrences — naming convention `ceos-agents-<PROJECT>`)
- `docs/guides/custom-agents.md` (2 occurrences)

**Reference documentation:**
- `docs/reference/commands.md` (~60 occurrences — exhaustive command syntax reference)
- `docs/reference/pipelines.md` (~14 occurrences)
- `docs/reference/automation-config.md` (6 occurrences)
- `docs/reference/agents.md` (3 occurrences — example output blocks)
- `docs/reference/execution-loop.md` (1 occurrence)
- `docs/architecture.md` (7 occurrences)

**Command user-visible output strings (commands that print to user):**
- `commands/status.md` (~9 occurrences — recommended next-step messages)
- `commands/onboard.md` (~6 occurrences — wizard text and closing message)
- `commands/init.md` (~4 occurrences — closing message)
- `commands/scaffold.md` (~5 occurrences — completion messages)
- `commands/fix-ticket.md` (1 occurrence — dry-run output)
- `commands/version-check.md` (~8 occurrences — version status messages)
- `commands/check-setup.md` (~3 occurrences — FAIL/WARN messages)
- All other commands with MCP guard error messages (~13 commands, 1 occurrence each)

**Project definition:**
- `CLAUDE.md` (3 occurrences — Plugin Composability section + 1 prose)
- `CHANGELOG.md` (4 occurrences — historical release notes)
- `CONTRIBUTING.md` (2 occurrences — title/prose)

**Critical note on `docs/guides/tokens.md`:** The token naming convention `ceos-agents-<PROJECT>` (e.g., `ceos-agents-BIFITO`) is a user-visible naming recommendation. Tokens already created by users with this naming pattern cannot be retroactively renamed and would become inconsistent with documentation if the name changes. This is a soft Class C item — existing tokens are outside ceos-agents' control but are not parsed by the plugin.

---

### Class C: External Data Format (cannot be retroactively updated)

Count: 23 distinct comment template occurrences across 15 files. These templates define the exact text that agents and commands post to external issue trackers (YouTrack, GitHub Issues, Jira, Linear, Gitea, Redmine). Once posted, the comments exist outside ceos-agents' control.

**Block Comment Template (`[ceos-agents] 🔴 Pipeline Block`)**

Posted by: 12 agents/commands. Template source locations:
1. `agents/architect.md` line 99
2. `agents/code-analyst.md` line 58
3. `agents/e2e-test-engineer.md` line 61
4. `agents/fixer.md` line 86
5. `agents/priority-engine.md` line 71
6. `agents/publisher.md` line 88
7. `agents/reviewer.md` line 111
8. `agents/rollback-agent.md` line 62
9. `agents/spec-analyst.md` line 76
10. `agents/test-engineer.md` line 55
11. `agents/triage-analyst.md` line 78
12. `commands/fix-bugs.md` line 368
13. `commands/fix-ticket.md` line 364
14. `commands/implement-feature.md` line 295
15. `commands/scaffold.md` line 375

Note: `agents/spec-writer.md` line 88 has `[ceos-agents] Pipeline Block` (missing `🔴` emoji — pre-existing inconsistency from pipeline-consistency-design.md).

**Triage Checkpoint Comment (`[ceos-agents] Triage completed. ...`)**

Posted by: `agents/triage-analyst.md` line 70; instructed also by `commands/analyze-bug.md` line 22. Format:
```
[ceos-agents] Triage completed. Severity: {severity}. Area: {area}. Complexity: {complexity}. AC: {count}.
```
Parsed by: `commands/resume-ticket.md` (lines 18, 65, 85), `commands/dashboard.md` (lines 40–87), `commands/metrics.md`.

**Spec Analysis Checkpoint Comment (`[ceos-agents] Spec analysis completed. ...`)**

Posted by: `agents/spec-analyst.md` line 55. Format:
```
[ceos-agents] Spec analysis completed. Area: {area}. Criteria: {count}.
```
Parsed by: `commands/resume-ticket.md` (lines 64, 85).

**AC Listing Comment (`[ceos-agents] Acceptance Criteria:`)**

Posted by: `agents/spec-analyst.md` line 60. Not parsed by any command (informational only). Still immutable once posted.

**Verify Success Comment (`[ceos-agents] ✅ Fix verified.`)**

Posted by: `commands/fix-bugs.md` line 317, `commands/fix-ticket.md` line 335, `commands/implement-feature.md` line 278.

**Verify Failure Comment (`[ceos-agents] ❌ Fix verification failed.`)**

Posted by: `commands/fix-ticket.md` line 340, `commands/implement-feature.md` line 281.

**Also in CLAUDE.md:** Lines 179 and 190 define the canonical templates for the Block Comment and Triage checkpoint. These are documentation of the format, not functional posting sites, so they are Class B for editing purposes but represent the contract specification of Class C data.

---

## Version Impact Analysis

Per the versioning policy in `CLAUDE.md`:

> MAJOR: Breaking change in Automation Config contract — new required key, renamed section — OR breaking change in agent output format contract (new/modified structured output sections that Agent Overrides or external tooling may parse).

> MINOR: New backward-compatible feature — new optional key, new command/agent.

> PATCH: Behavior fix without contract change.

### Scenario 1: Change the `[ceos-agents]` comment prefix to a new value

**Version impact: MAJOR.**

The `[ceos-agents]` prefix is the agent output format contract. It is explicitly named in the versioning policy: "breaking change in agent output format contract (new/modified structured output sections that Agent Overrides or external tooling may parse)." The prefix is parsed by `resume-ticket`, `dashboard`, and `metrics`. A prefix change breaks all three consumers for all existing comments in all users' issue trackers. Historical precedent: the `[CLAUDE-agents]` → `[ceos-agents]` rename in v4.0 was marked BREAKING in the changelog.

### Scenario 2: Change the `ceos-agents:` command/skill namespace prefix

**Version impact: MAJOR.**

The namespace is the public API. All 24 commands change invocation names simultaneously. This breaks user bookmarks, scripts, documentation references, and the skill router. Not covered by a simple config migration — requires user reinstall.

### Scenario 3: Add a new structured field to the Triage checkpoint comment

**Version impact: MAJOR.**

The checkpoint comment format is agent output format. Historical precedent: adding `Complexity: {c}. AC: {n}.` to the triage checkpoint in v5.0.0 was explicitly marked as BREAKING in `CHANGELOG.md` line 62. Any addition to a structured comment that is machine-parsed constitutes a MAJOR change.

### Scenario 4: Add a new comment type (e.g., `[ceos-agents] Browser verification completed.`)

**Version impact: MINOR.**

Adding a new comment type is additive — existing parsers don't need to handle it for current functionality. `resume-ticket` and `dashboard` would not break. They would simply not detect the new type until updated. This matches the MINOR policy: "new backward-compatible feature."

### Scenario 5: Update documentation references only (rename commands in docs without changing actual command files)

**Version impact: None** (documentation-only change is a PATCH at most, and likely not a version change at all if no behavior changes).

### Scenario 6: Rename the plugin (change `plugin.json` `"name"` field)

**Version impact: MAJOR** by implication — all command and skill invocations change, equivalent to Scenario 2.

---

## Gaps

1. **`agents/acceptance-gate.md`, `agents/reproducer.md`, `agents/browser-verifier.md`, `agents/stack-selector.md`, `agents/scaffolder.md`, `agents/spec-reviewer.md`** — these agents did not appear in the `[ceos-agents]` grep results. Either they have no block comment templates (inconsistency with the other 12 agents that do), or their block comment is delegated to the parent command. This could not be fully determined without reading each file, but the pipeline-consistency test at `tests/scenarios/pipeline-consistency.sh` implies it checks all `agents/*.md` files.

2. **`commands/discuss.md`** — present in `commands/` but was noted in Phase 1 as absent from the skill router intent table. Not examined for `[ceos-agents]` references in this pass.

3. **`commands/scaffold-validate.md`** — not confirmed to have been examined for user-visible output strings.

4. **Token naming convention permanence** — `docs/guides/tokens.md` recommends naming API tokens `ceos-agents-<PROJECT>`. Tokens already created by users with this name exist in external systems (YouTrack, GitHub, Jira, Gitea). They cannot be retroactively renamed by ceos-agents. This is analogous to Class C but was not surfaced by the grep (it uses bare `ceos-agents` as a naming recommendation, not a machine-parsed prefix). The impact is purely cosmetic/DX — no runtime parsing depends on token names.

5. **`.claude/settings.local.json`** — This file is listed in `.gitignore` per convention and is not committed. The `Skill(ceos-agents:version-bump)` allowedTools entry was observed at line 56. This is a developer-local artifact and would not affect any user or PR.

6. **Exact line counts in `docs/reference/commands.md`** — This file has approximately 60 `ceos-agents:` references (one per command syntax line, example, and cross-reference). The exact count was not enumerated per-line as it would have been repetitive; the file is a comprehensive listing of all 24 commands.
