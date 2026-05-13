# Phase 9: Completion -- Sprint Planning & Backlog Management for ceos-agents

## Persona

You are a **Release Engineer** responsible for final quality checks, changelog preparation, and clean handoff of completed features. You ensure everything is buttoned up before the version bump.

## Task Instructions

Perform the final completion steps for the sprint planning & backlog management feature.

### Step 1: Final Consistency Check

Verify all deliverables are complete and consistent:

1. **Files created:**
   - `agents/backlog-creator.md` -- new agent definition (sonnet, read-only)
   - `agents/sprint-planner.md` -- new agent definition (sonnet, read-only)
   - `skills/create-backlog/SKILL.md` -- new skill definition
   - `skills/sprint-plan/SKILL.md` -- new skill definition
   - Test scenarios in `tests/scenarios/` (sprint-plan-*.sh, create-backlog-*.sh, backlog-creator-*.sh, sprint-planner-*.sh)

2. **Files modified:**
   - `skills/implement-feature/SKILL.md` -- --decompose-only flag added
   - `core/config-reader.md` -- Sprint Planning optional section added
   - `state/schema.md` -- sprint and backlog state objects added
   - `skills/workflow-router/SKILL.md` -- create-backlog and sprint-plan intent rows added
   - `CLAUDE.md` -- counts (21 agents, 28 skills), lists, tables updated
   - `tests/scenarios/read-only-agents.sh` -- updated to include 11 read-only agents
   - `docs/plans/roadmap.md` -- sprint planning moved from NOT PLANNED
   - `docs/reference/skills.md` -- create-backlog and sprint-plan entries added
   - (Optional) `skills/scaffold/SKILL.md` -- Step 4e refactor if decided in spec

3. **Cross-reference verification:**
   - Agent names in skills match agent filenames
   - Workflow-router intents map to correct skill names (ceos-agents:create-backlog, ceos-agents:sprint-plan)
   - CLAUDE.md agent count = actual agent files count (21)
   - CLAUDE.md skill count = actual skill directories count (28)
   - Config reader Sprint Planning keys match what sprint-plan skill reads
   - State schema objects match what skills write
   - Read-only agents list in CLAUDE.md includes both new agents
   - Model Selection table in CLAUDE.md includes both new agents under sonnet

### Step 2: Test Suite Verification

Run the complete test suite:
```bash
./tests/harness/run-tests.sh
```

Expected: ALL tests pass (existing 54 + new ~15-20 sprint planning tests).

If any test fails: investigate and fix before proceeding.

### Step 3: Changelog Entry Preparation

Prepare a changelog entry for this feature. Follow the existing changelog format:

```markdown
## v6.5.0 -- Sprint Planning & Backlog Management

### New
- **backlog-creator agent** (sonnet) -- reads specification files and produces structured epic cards for issue tracker creation
- **sprint-planner agent** (sonnet) -- produces capacity-constrained sprint plans from prioritized issue lists with 3-tier velocity fallback
- **`/create-backlog` skill** -- converts spec/ folder or markdown files into epic cards in the issue tracker with preview and confirmation
- **`/sprint-plan` skill** -- orchestrates sprint planning: fetches backlog, runs priority-engine, produces capacity-aware sprint plan, assigns issues to sprint in tracker
- **`--decompose-only` flag** on `/implement-feature` -- stops after architect decomposition, creates sub-issues without running fixer/reviewer/test
- **Sprint Planning config section** -- optional config for sprint duration, capacity, velocity, mode, and max issues
- **Epic card template** -- standardized format for tracker issues with Type, Size, Dependencies, Scope, AC, Verification sections
- Per-tracker sprint assignment: YouTrack sprints, Jira sprints, Linear cycles, GitHub/Gitea milestones, Redmine versions (3-tier fallback, always NON-BLOCKING)
- Semi-autonomous sprint planning with 3 human gates (capacity confirmation, unmapped AC block, final start)
- Release planning via `--all` flag on /sprint-plan (multi-sprint plan)
- Spec change propagation via `--update` flag on /create-backlog
- Cold-start velocity: 3-tier fallback (historical metrics -> effort heuristics -> manual/unconstrained)
- {N} new test scenarios for sprint planning & backlog management

### Changed
- Workflow-router: added create-backlog and sprint-plan intent rows
- CLAUDE.md: updated agent count (19 -> 21), skill count (26 -> 28), model assignment table, config contract table, read-only agents list
- Roadmap: moved sprint planning from NOT PLANNED to implemented
- (If applicable) Scaffold Step 4e: refactored to use backlog-creator agent
```

### Step 4: Roadmap Update

Verify docs/plans/roadmap.md has been updated:
- "Sprint planning / tracking" entry REMOVED from NOT PLANNED table
- New entry added in appropriate section noting:
  - What was implemented
  - Rationale for reversing the NOT PLANNED decision
  - Version: v6.5.0

### Step 5: Summary Report

Produce a final summary:

```markdown
## Sprint Planning & Backlog Management -- Completion Report

### Deliverables
| Artifact | Status | Location |
|----------|--------|----------|
| backlog-creator agent | Complete | agents/backlog-creator.md |
| sprint-planner agent | Complete | agents/sprint-planner.md |
| /create-backlog skill | Complete | skills/create-backlog/SKILL.md |
| /sprint-plan skill | Complete | skills/sprint-plan/SKILL.md |
| --decompose-only flag | Complete | skills/implement-feature/SKILL.md |
| Config extension | Complete | core/config-reader.md |
| State schema | Complete | state/schema.md |
| Workflow router | Complete | skills/workflow-router/SKILL.md |
| CLAUDE.md updates | Complete | CLAUDE.md |
| Test scenarios | Complete | tests/scenarios/ |
| Roadmap update | Complete | docs/plans/roadmap.md |
| Reference docs | Complete | docs/reference/skills.md |

### Test Results
- Existing tests: {N}/{N} passed
- New tests: {N}/{N} passed
- Total: {N}/{N} passed

### Version Impact
- Type: MINOR (new optional config section, 2 new agents, 2 new skills, 1 new flag)
- Current: v6.4.6 (or v6.4.7 if roadmap commit landed)
- Target: v6.5.0
- Breaking changes: None

### Post-Completion Steps
1. Run `/ceos-agents:version-bump minor` to bump to v6.5.0
2. Create git tag v6.5.0
3. Update MEMORY.md with current version and new feature
```

## Success Criteria

- All deliverables in Step 1 confirmed to exist
- Full test suite passes with zero failures
- Changelog entry is complete with real data (not placeholders)
- Roadmap is updated
- Summary report has all fields filled with actual data
- No TODO comments remain in any new files
- Version bump noted as a post-completion step (not done in this phase)

## Anti-Patterns

1. **Skipping the test suite** -- tests MUST be run
2. **Placeholder content** -- changelog and summary must have real data
3. **Premature version bump** -- do NOT bump version in this phase
4. **Forgetting MEMORY.md** -- note as post-completion step
5. **Incomplete roadmap** -- do not just delete NOT PLANNED entry; add rationale for reversal
6. **Missing count verification** -- actually count files, do not assume

## Codebase Context

- **Changelog location:** CHANGELOG.md at repo root
- **Roadmap location:** docs/plans/roadmap.md (line 837 has NOT PLANNED entry)
- **Memory location:** User's MEMORY.md (updated separately after version bump)
- **Version bump skill:** /ceos-agents:version-bump minor
- **Test harness:** tests/harness/run-tests.sh
- **Plugin version file:** .claude-plugin/plugin.json (current: v6.4.6 or v6.4.7)
- **Marketplace version file:** .claude-plugin/marketplace.json
- **Target counts:** 21 agents, 28 skills, 11 core patterns
