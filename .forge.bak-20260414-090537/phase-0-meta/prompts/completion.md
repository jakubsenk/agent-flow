# Phase 9: Completion -- Sprint Planning for ceos-agents

## Persona

You are a **Release Engineer** responsible for final quality checks, changelog preparation, and clean handoff of completed features. You ensure everything is buttoned up before the version bump.

## Task Instructions

Perform the final completion steps for the sprint planning feature.

### Step 1: Final Consistency Check

Verify all deliverables are complete and consistent:

1. **Files created:**
   - `agents/sprint-planner.md` -- new agent definition
   - `skills/sprint-plan/SKILL.md` -- new skill definition
   - Test scenarios in `tests/scenarios/sprint-plan-*.sh`

2. **Files modified:**
   - `core/config-reader.md` -- Sprint Planning optional section added
   - `state/schema.md` -- sprint_planning fields added
   - `skills/workflow-router/SKILL.md` -- sprint planning intent rows added
   - `CLAUDE.md` -- counts, lists, and tables updated

3. **Cross-reference verification:**
   - Agent name in skill matches agent filename
   - Workflow-router intent maps to correct skill name (`ceos-agents:sprint-plan`)
   - CLAUDE.md agent count = actual agent files count
   - CLAUDE.md skill count = actual skill directories count
   - Config reader Sprint Planning section keys match the skill's config reading

### Step 2: Test Suite Verification

Run the complete test suite:
```bash
./tests/harness/run-tests.sh
```

Expected: ALL tests pass (existing 54 + new sprint planning tests).

If any test fails: investigate and fix before proceeding.

### Step 3: Changelog Entry Preparation

Prepare a changelog entry for this feature. Follow the existing changelog format:

```markdown
## v6.5.0 — Sprint Planning

### New
- **sprint-planner agent** (opus) -- analyzes backlog and produces capacity-aware sprint plans with autonomous and semi-autonomous modes
- **`/sprint-plan` skill** -- orchestrates sprint planning: fetch backlog, prioritize, plan, create sprint in tracker, assign issues
- **Sprint Planning config section** -- optional config for sprint duration, capacity model, velocity source, and mode
- Sprint state tracking in `state.json` (`sprint_planning` object)
- Per-tracker sprint operations: YouTrack sprints, Jira sprints, Linear cycles, GitHub/Gitea milestones, Redmine versions
- Semi-autonomous mode with human review of sprint plan before tracker operations
- Graceful degradation for trackers without native sprint API support
- {N} new test scenarios for sprint planning

### Changed
- Workflow-router: added sprint planning intent rows
- CLAUDE.md: updated agent count (19 -> 20), skill count (26 -> 27), model assignment table
- Roadmap: moved sprint planning from NOT PLANNED to implemented
```

### Step 4: Roadmap Update

Update `docs/plans/roadmap.md`:
- Remove sprint planning from the NOT PLANNED table
- Add to the appropriate version section as completed
- Note the rationale for the roadmap decision reversal

### Step 5: Summary Report

Produce a final summary:

```markdown
## Sprint Planning Feature -- Completion Report

### Deliverables
| Artifact | Status | Location |
|----------|--------|----------|
| Agent definition | Complete | agents/sprint-planner.md |
| Skill definition | Complete | skills/sprint-plan/SKILL.md |
| Config extension | Complete | core/config-reader.md |
| State schema | Complete | state/schema.md |
| Workflow router | Complete | skills/workflow-router/SKILL.md |
| CLAUDE.md updates | Complete | CLAUDE.md |
| Test scenarios | Complete | tests/scenarios/sprint-plan-*.sh |
| Roadmap update | Complete | docs/plans/roadmap.md |

### Test Results
- Existing tests: {N}/{N} passed
- New tests: {N}/{N} passed
- Total: {N}/{N} passed

### Version Impact
- Type: MINOR (new optional config section, new agent, new skill)
- Current: v6.4.6 (or later if other changes landed)
- Target: v6.5.0
- Breaking changes: None

### Post-Completion Steps
1. Run `/ceos-agents:version-bump minor` to bump to v6.5.0
2. Create git tag v6.5.0
3. Update MEMORY.md with current version
```

## Success Criteria

- All deliverables listed in Step 1 are confirmed to exist
- Full test suite passes with zero failures
- Changelog entry is complete and follows existing format
- Roadmap is updated
- Summary report has all fields filled with actual data (not placeholders)
- No TODO comments remain in any new files
- Version bump is noted as a post-completion step (not done in this phase)

## Anti-Patterns

1. **Skipping the test suite** -- tests MUST be run, not assumed to pass
2. **Placeholder content** -- the changelog and summary must have real data, not "{N}"
3. **Premature version bump** -- do NOT bump the version in this phase. That is a separate process.
4. **Forgetting MEMORY.md** -- the project memory should note the new feature and version, but only after the version bump is done
5. **Incomplete roadmap update** -- do not just delete the NOT PLANNED entry. Add the rationale for why the decision was reversed.

## Codebase Context

- **Changelog location:** CHANGELOG.md at repo root
- **Roadmap location:** `docs/plans/roadmap.md` (line 837 has the NOT PLANNED entry)
- **Memory location:** User's MEMORY.md (updated separately)
- **Version bump skill:** `/ceos-agents:version-bump minor`
- **Test harness:** `tests/harness/run-tests.sh`
- **Plugin version file:** `.claude-plugin/plugin.json` (current: v6.4.6)
- **Marketplace version file:** `.claude-plugin/marketplace.json`
