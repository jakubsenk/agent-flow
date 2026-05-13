# Research Agent 3: Config Contract & Scope Boundaries

## Config Contract Impact

### Proposed Config Section: Sprint Planning

All keys are optional. The section is activated only when present. Absence means sprint planning is disabled (skills that read it skip sprint-related steps silently).

| Key | Default | Description |
|-----|---------|-------------|
| Sprint duration | `2 weeks` | Length of one sprint. Accepted: `1 week`, `2 weeks`, `3 weeks`, `4 weeks`. Used by sprint-planner to compute capacity and deadline. |
| Capacity unit | `story-points` | Unit for sizing: `story-points`, `hours`, `days`. Determines how velocity and capacity are compared. |
| Team capacity | (none) | Total capacity available in one sprint (in Capacity unit). E.g., `40` for 40 story-points or `80` for 80 hours. When absent → planner skips capacity fit check. |
| Velocity target | (none) | Historically delivered units per sprint. Used as the realistic ceiling when team capacity is not set. When both are set → min(Team capacity, Velocity target) is used. |
| Sprint field | `Sprint` | Name of the custom field in the issue tracker that holds sprint assignment. Tracker-specific: YouTrack/Jira use custom fields, GitHub/Gitea use milestones, Linear uses cycles. |
| Priority field | `Priority` | Name of the priority field in the issue tracker. Used to rank candidates for sprint. |
| Mode | `suggest` | Behaviour mode: `suggest` = read-only recommendation with diff for human approval; `apply` = write sprint assignments directly to tracker after confirmation. |
| Max issues | `20` | Maximum issues to consider for sprint planning per run. Maps directly to `--limit` pattern used by `/prioritize`. |
| Include types | `bug, feature` | Comma-separated issue types to include. Tracker-agnostic label. |
| Exclude labels | (none) | Comma-separated labels that permanently disqualify an issue from sprint consideration (e.g., `blocked, wont-fix`). |
| Estimation field | (none) | Name of the estimation/story-points field in the tracker. When present, sprint-planner reads it instead of deriving size from complexity. When absent → derives from triage-analyst complexity (XS=1, S=2, M=3, L=5). |
| Report path | (none) | If set, write sprint plan report to this file in addition to stdout (e.g., `reports/sprint-plan.md`). |

**Example config block (table format, consistent with all other optional sections):**

```markdown
### Sprint Planning

| Key | Value |
|-----|-------|
| Sprint duration | 2 weeks |
| Capacity unit | story-points |
| Team capacity | 40 |
| Velocity target | 35 |
| Sprint field | Sprint |
| Priority field | Priority |
| Mode | suggest |
| Max issues | 20 |
| Include types | bug, feature |
| Exclude labels | blocked, wont-fix |
| Estimation field | Story points |
| Report path | reports/sprint-plan.md |
```

### Version Bump Assessment

**MINOR (X.Y.0)** — new backward-compatible optional section.

Rationale per CLAUDE.md Versioning Policy: "Adding an **optional** section = MINOR." This section has no required keys and zero impact on projects that do not configure it. The sprint-planner agent and `/sprint-plan` skill are new additions (not renames or breaking changes). No existing Automation Config key is renamed or removed. No existing agent output format contract changes.

This is structurally identical to how `Browser Verification` was introduced (v5.1.0, MINOR), `Local Deployment` (v5.3.0, MINOR), and `Autopilot` (planned v6.7.0, MINOR per roadmap).

If `Mode: apply` auto-assigns issues to sprints without human confirmation, that is a behavioral side-effect on the tracker — but it is gated behind an explicit config choice. The config contract itself remains optional and backward-compatible.

### Pipeline Profile Interaction

Sprint planning is NOT a pipeline stage. It is a standalone pre-pipeline skill (like `/prioritize` or `/estimate`) that produces a sprint plan but does not execute the fix or implement pipeline.

Consequence: Sprint Planning config does NOT interact with `### Pipeline Profiles` at all. Pipeline Profiles control skip/extra stages within `fix-ticket`, `fix-bugs`, and `implement-feature`. Sprint planning runs before those skills, not within them.

The one indirect relationship: `/sprint-plan` may suggest running `/fix-bugs --limit N` or `/implement-feature <ID>` on the planned issues. The user selects a profile at that point independently. Sprint Planning config has no `Skip stages` or profile-override capability.

---

## Scope Boundaries

### In Scope

- **Sprint backlog selection:** Query open issues, apply priority + capacity constraints, produce a ranked list of issues that fit in the upcoming sprint. This is the core value — replacing manual backlog grooming with AI-assisted selection.
- **Capacity fitting:** Given team capacity (story-points or hours) and velocity target, trim or extend the proposed issue list to fit the sprint window.
- **Size derivation:** If no estimation field is configured, derive size from triage-analyst complexity labels already present in tracker comments (`[ceos-agents] Triage completed. ... Complexity: M.`). This reuses existing structured data without adding a new pipeline stage.
- **Sprint assignment (optional, Mode: apply):** After human confirmation, write the sprint assignment to the tracker. Uses the `Sprint field` key and tracker MCP server already required for all pipeline skills.
- **Sprint plan report:** A markdown table of planned issues with ID, title, complexity/size, priority, and rationale. Saved to `Report path` if configured. Follows the same pattern as `/metrics` output.
- **Dependency awareness:** Reuse priority-engine's dependency graph logic (issues that block others are prioritized). Sprint-planner delegates ranking to priority-engine (Task tool, opus) and applies capacity constraints on top.

### Out of Scope (with justification)

- **Sprint review automation:** Sprint review is a team ceremony that requires human judgment on what "done" means, demo narratives, and stakeholder feedback. ceos-agents has no model of sprint goals or demo scripts. Including this would pull the plugin firmly into PM territory. Trackers (YouTrack, Jira, Linear) have native review workflows.
- **Sprint retrospective:** Retrospectives involve team dynamics and process improvement discussions that are human-facilitated by design. Automating retrospectives would conflict with the plugin's stated scope: "ceos-agents is not a PM tool."
- **Burndown tracking:** Burndown is a live metric that updates throughout the sprint as issues close. The tracker's native burndown view already does this. `/metrics` already provides pipeline-level analytics. Adding real-time burndown would duplicate tracker functionality. Delegation is the correct answer.
- **Velocity history computation:** Computing velocity requires historical sprint data, which is tracker-specific (YouTrack has velocity charts, Jira has velocity reports). Replicating this in a markdown plugin adds fragility. Instead, users configure `Velocity target` manually (one-time input) — same pattern as `Team capacity`.
- **Sprint goal writing:** Writing a sprint goal narrative is a product management task requiring context about business objectives, not just issue metadata.
- **Issue estimation (story pointing):** Sprint-planner reads estimation data from the tracker or derives it from triage complexity. It does NOT run a dedicated estimation session on unpointed issues — that would require interactive sessions with the team (planning poker model), which is outside a CLI plugin's capability.
- **Multi-team / capacity per-person breakdown:** Per-person workload assignment is pure PM tooling. Sprint Planning config has `Team capacity` as a single aggregate number.

### Minimum Viable Sprint Planning

The minimum sprint planning that delivers genuine value, with no scope creep:

1. Read open issues from tracker (reuse existing MCP + Bug query / Feature query pattern).
2. Dispatch `ceos-agents:priority-engine` (Task tool, opus) — already exists, already ranks by impact/risk/effort.
3. Apply capacity constraint: walk ranked list, accumulate estimated sizes, stop when capacity is reached.
4. Output a sprint plan table: `| # | Issue | Size | Priority | Rationale |` — human-readable, tracker-independent.
5. If `Mode: apply` → confirm with user, write `Sprint field` to each planned issue via MCP.

This is a thin wrapper around two already-existing capabilities: priority-engine + MCP tracker write. The new work is: one new skill (orchestration) and one optional config section. No new agent is strictly required if sprint-planner logic is simple enough to inline in the skill — but a dedicated agent keeps the architecture clean and model costs predictable.

---

## New Components Inventory

### New Agent: sprint-planner

**Purpose:** Applies capacity constraints and sprint-specific scoring on top of priority-engine output to produce a sprint plan. Distinct from priority-engine because it requires sprint context (duration, capacity, velocity) that priority-engine does not have. Priority-engine is a general backlog ranker; sprint-planner is a time-bounded capacity fitter.

**Model: sonnet** — analysis and report generation, not critical code changes. Consistent with other analysis agents: triage-analyst, code-analyst, spec-analyst, acceptance-gate. Priority-engine uses opus because it must reason about complex dependency graphs and multi-dimensional scoring across 50 issues. Sprint-planner receives pre-ranked output from priority-engine and applies simpler arithmetic constraints — sonnet is sufficient.

**Read-only: yes** — sprint-planner does NOT modify code. It reads issues and optionally writes sprint field assignments via the skill's MCP call (not the agent directly). Consistent with the convention: execution agents write code, skills write to trackers.

**Proposed frontmatter:**

```markdown
---
name: sprint-planner
description: Applies capacity constraints to a prioritized backlog to produce a sprint plan with fit analysis
model: sonnet
style: Pragmatic, capacity-aware, time-boxed
---
```

**Sections (Goal / Expertise / Process / Constraints):**

- **Goal:** Receive a prioritized issue list and sprint capacity parameters; produce a sprint plan that fits within the sprint window, accounting for team velocity, issue sizes, and dependencies.
- **Expertise:** Capacity planning, sprint sizing, dependency ordering, scope negotiation.
- **Process (sketch):**
  1. Receive: prioritized issue list (from priority-engine), Sprint Planning config keys (duration, capacity unit, team capacity, velocity target, max issues, exclude labels, estimation field).
  2. Filter: remove issues matching `Exclude labels`.
  3. Resolve sizes: if `Estimation field` present → read from tracker data. Else map triage complexity (XS=1, S=2, M=3, L=5 story-points; or XS=2h, S=4h, M=8h, L=16h for hours).
  4. Apply capacity ceiling: `effective_capacity = min(Team capacity, Velocity target)` if both set; else whichever is present; else unlimited (return top `Max issues`).
  5. Walk priority-ordered list: accumulate size until `effective_capacity` is reached. Issues that would overflow by ≤20% of their own size may be included (rounding buffer).
  6. Flag dependency-blocked issues: if issue A is in plan but depends on B which is not → add B to plan or flag A as at-risk.
  7. Output sprint plan (structured markdown table) and overflowing issues with sizes.
- **Constraints:** NEVER modify code. NEVER assign sprint field directly — the skill handles tracker writes. Max 50 issues as input (consistent with priority-engine limit). If capacity is 0 or unconfigured → output full priority list capped at `Max issues` with a note.

### New Skill: sprint-plan

**Purpose:** Orchestrate sprint planning: fetch issues, run priority-engine, run sprint-planner, optionally apply to tracker.

**Proposed frontmatter:**

```markdown
---
name: sprint-plan
description: Produces a sprint plan by ranking backlog issues against team capacity and optionally assigning them to the next sprint
allowed-tools: mcp__*, Read, Glob, Grep, Task
argument-hint: "[--apply] [--dry-run] [--capacity <N>] [--duration <1w|2w|3w|4w>] [--output <path>]"
---
```

**Arguments:**
- `--apply` — override `Mode: suggest` → write sprint assignments to tracker after confirmation.
- `--dry-run` — show plan without writing anything, regardless of `Mode` config.
- `--capacity <N>` — override `Team capacity` from config for this run.
- `--duration <1w|2w|3w|4w>` — override `Sprint duration` for this run.
- `--output <path>` — override `Report path` for this run.

**Orchestration steps:**
1. MCP pre-flight check (consistent with all pipeline skills — pattern: `core/mcp-preflight.md`).
2. Read Sprint Planning config. If section absent → stop: "Sprint Planning config not found. Add `### Sprint Planning` section to Automation Config or run `/ceos-agents:check-setup`."
3. Fetch open issues via MCP (Bug query + Feature query, filtered by `Include types`, capped at `Max issues`).
4. Run `ceos-agents:priority-engine` (Task tool, opus). Pass: issue list + `Priority field`.
5. Run `ceos-agents:sprint-planner` (Task tool, sonnet). Pass: ranked list + Sprint Planning config.
6. Display sprint plan. If `--dry-run` → stop here.
7. If `Mode: apply` or `--apply` flag → confirm with user (show plan, ask "Apply sprint assignments? [y/N]"). On confirm → for each issue in plan: write `Sprint field` via MCP.
8. If `--output` or `Report path` → write report to file.

**Rules:** Read-only by default (Mode: suggest). Destructive only when Mode: apply or --apply flag. Confirmation required before tracker writes (consistent with workflow-router destructive ops pattern).

### Workflow-Router Updates

Add two new rows to the Intent Mapping table in `skills/workflow-router/SKILL.md`:

| User Intent | Command | Arguments | Destructive? |
|-------------|---------|-----------|-------------|
| Plan next sprint / sprint planning / what goes in sprint | `ceos-agents:sprint-plan` | Optional: --apply, --capacity N, --output path | No (suggest mode) / Yes (apply mode) |
| Apply sprint plan / assign issues to sprint | `ceos-agents:sprint-plan` | `--apply` | Confirm before assigning |

The "apply" variant maps to the same skill but with the `--apply` flag and requires confirmation (consistent with the `check-deploy --start` pattern which also maps to the same skill with a flag and is marked destructive).

### CLAUDE.md Config Contract Additions

Two additions to CLAUDE.md:

1. **Optional sections table** — add one new row:

| Section | Keys | Default |
|---------|------|---------|
| Sprint Planning | Sprint duration, Capacity unit, Team capacity, Velocity target, Sprint field, Priority field, Mode, Max issues, Include types, Exclude labels, Estimation field, Report path | 2 weeks, story-points, (none), (none), Sprint, Priority, suggest, 20, bug\, feature, (none), (none), (none) |

2. **Architecture: 2-Layer System** — update agent count from 19 to 20, skill count from 26 to 27.

3. **Model Selection table** — add sprint-planner to the sonnet row.

4. **Key Conventions** — sprint-planner is a read-only agent (no code modification).

### Test Scenarios Needed

Following the pattern of existing test scenarios (shell scripts in `tests/scenarios/`):

1. **`sprint-plan-config-contract.sh`** — Verify `Sprint Planning` section present in CLAUDE.md optional sections table with all 12 keys and correct defaults. Analogous to `test-config-contract.sh`.

2. **`sprint-plan-skill-structure.sh`** — Verify `skills/sprint-plan/SKILL.md` exists, has correct frontmatter (name, description, allowed-tools, argument-hint), dispatches priority-engine and sprint-planner via Task tool. Analogous to `pipeline-feature-agents.sh`.

3. **`sprint-planner-agent-format.sh`** — Verify `agents/sprint-planner.md` exists, has correct frontmatter (name, description, model: sonnet, style), has Goal/Expertise/Process/Constraints sections, appears in read-only agents list. Analogous to `frontmatter-completeness.sh` and `read-only-agents.sh`.

4. **`workflow-router-sprint-intent.sh`** — Verify workflow-router SKILL.md contains `sprint-plan` in its intent table. Analogous to `xref-skip-stage-names.sh`.

5. **`xref-command-count-sprint.sh`** — Update `xref-command-count.sh` claim: skills count from 26 to 27, agents count from 19 to 20. (Or update the existing test to match new counts.)

6. **`sprint-plan-dry-run.sh`** — Verify `--dry-run` flag prevents tracker writes (check that SKILL.md contains the dry-run gate before any MCP write operations). Analogous to `profile-skip.sh`.

---

## Roadmap Reversal Justification

The `NOT PLANNED` entry in `docs/plans/roadmap.md` (line 837) reads:

> **Sprint planning / tracking** | ceos-agents is not a PM tool. Sprint tracking is delegated to issue trackers (YouTrack/Jira/Linear have native sprints).

This was a correct rejection of **sprint tracking** (burndown, retrospectives, review). It was NOT a rejection of **sprint planning as backlog selection**.

Three conditions changed since that decision was recorded:

1. **Priority-engine exists (v6.x).** When the sprint planning entry was added to NOT PLANNED, the priority-engine agent did not exist. Sprint planning now requires only a thin wrapper around already-built capabilities (priority-engine + MCP tracker writes). The build cost dropped from "new full agent + new analysis logic" to "new skill + one thin agent for capacity fitting."

2. **Metrics + estimate infrastructure.** The `/metrics` and `/estimate` skills (v6.x) established the pattern for read-only analytical skills that produce planning-relevant output. Sprint planning is the natural next step in the planning → execution sequence: estimate → prioritize → **sprint-plan** → fix-ticket/implement-feature.

3. **Scope clarification.** The original rejection conflated two distinct concepts: (a) sprint tracking (continuous burndown, review, retro — correctly rejected, trackers do this) and (b) sprint planning as a one-shot backlog selection tool (new, not rejected). The `Mode: suggest` default makes the skill read-only by default, reinforcing that it is an analytical tool, not a PM replacement.

**What remains correctly NOT PLANNED:** burndown tracking, sprint review automation, sprint retrospective, per-person workload assignment. These remain delegated to native tracker features.

---

## Key Findings & Risks

**Finding 1 — Thin build, high reuse.** Sprint planning reuses priority-engine (opus, already built), MCP tracker access (already required), and the existing `/prioritize` orchestration pattern. The net new code is: one SKILL.md (orchestration), one agent definition (capacity fitting, ~60 lines), two workflow-router intent rows, one config section. Estimated delta: well under 200 lines of new markdown.

**Finding 2 — Mode: apply is the only destructive surface.** In default `Mode: suggest`, the skill is fully read-only. Tracker writes only happen with `Mode: apply` in config OR `--apply` flag, both gated behind user confirmation. Risk of unintended tracker mutation is low.

**Finding 3 — Estimation quality depends on triage completeness.** If issues have not been triaged by the pipeline (no `[ceos-agents] Triage completed` comment), sprint-planner must fall back to deriving size from issue description only (priority-engine's Effort dimension). Teams that use ceos-agents for all their issues get better sprint plans than teams that mix manual and automated triage. This is a documentation concern, not a blocking risk.

**Finding 4 — Sprint field is tracker-specific.** YouTrack and Jira use custom fields for sprints; GitHub and Gitea use milestones; Linear uses cycles. The `Sprint field` config key must be interpreted differently per tracker type. The skill must read `Issue Tracker → Type` and apply tracker-specific MCP write logic. This adds conditional complexity to the skill. Mitigation: document the tracker-specific behavior clearly per-tracker in `docs/reference/automation-config.md` (same pattern as State transitions documentation).

**Finding 5 — Count claims in CLAUDE.md and tests must be updated atomically.** `tests/scenarios/xref-command-count.sh` asserts agent count = 19 and skills count = 26. Adding sprint-planner + sprint-plan skill will fail this test unless both the CLAUDE.md claims and the test are updated in the same commit. This is a known maintenance pattern (identical issue arose for deployment-verifier in v5.3.0).

**Risk 1 — Scope creep pressure.** Once sprint planning is in, users will request sprint tracking, velocity auto-computation, and retrospective summaries. The NOT PLANNED rationale (ceos-agents is not a PM tool) must be explicitly restated for these follow-on requests. The roadmap entry for sprint planning should explicitly list what is NOT included.

**Risk 2 — Velocity target is manual.** Users must provide velocity manually. If they misconfigure it (too high or too low), the sprint plan will be unrealistic. Mitigation: document clearly, add a note in the sprint plan output: "Velocity target: {N} (configured manually — update Sprint Planning config to adjust)."

**Risk 3 — Versioning: MINOR is correct but borderline.** Adding 1 agent + 1 skill + 1 config section in one release is a medium-sized MINOR bump. Per the Versioning Policy this is definitively MINOR (optional section, no required keys, no breaking changes). However, the `Mode: apply` capability does write to the tracker — if this is classified as a "new output contract" one could argue MINOR is correct but should be announced clearly in the changelog. Recommend: emphasize in changelog that `Mode: apply` is the first skill to write sprint metadata, not just issue state transitions.
