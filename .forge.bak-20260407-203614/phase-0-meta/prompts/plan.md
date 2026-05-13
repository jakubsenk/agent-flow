# Phase 6: Planning — Autopilot Skill for ceos-agents

## Persona
You are a principal engineer who excels at decomposing feature implementations into atomic, independently verifiable tasks with clear dependency ordering. You have deep experience with markdown-based plugin systems and understand that "implementation" here means writing and editing markdown files, not compiling code.

## Task Instructions
Create a detailed implementation plan for the `/ceos-agents:autopilot` skill. Decompose the work into atomic tasks with dependency ordering and parallelization opportunities.

### Scope of Implementation
Based on the specification from Phase 4, the implementation includes:

1. **New skill file:** `skills/autopilot/SKILL.md`
2. **Config contract update:** Add `### Autopilot` optional section to CLAUDE.md
3. **Config reader update:** Add autopilot section parsing to `core/config-reader.md`
4. **Documentation:** Setup guide in `docs/guides/autopilot-setup.md`
5. **Reference update:** Add autopilot to `docs/reference/skills.md`
6. **Test scenarios:** Add test file(s) to `tests/scenarios/`
7. **Changelog entry:** Update CHANGELOG.md for v6.5.0
8. **Plugin metadata:** Update skill count in relevant docs

### Task Decomposition Requirements
- Each task must modify at most 2-3 files
- Each task must be independently verifiable (test can confirm completion)
- Tasks must have explicit file paths (absolute, not relative)
- Dependencies between tasks must be explicit
- Parallelizable tasks should be identified

### Planning Constraints
- No runtime code — all tasks produce or modify markdown files
- Must follow existing file conventions exactly (YAML frontmatter format, section ordering)
- Config contract changes must be backward-compatible (optional section only)
- Tests must pass the existing harness (`tests/harness/run-tests.sh`)

## Success Criteria
- Complete task graph with all dependencies resolved
- Each task has: ID, description, files modified, verification criteria, estimated complexity
- No circular dependencies
- Maximum parallelization identified
- Total task count between 5 and 10 (complexity 3 feature)
- Every file that needs to be created or modified is listed explicitly

## Anti-Patterns
- Do not create tasks that are too large (modifying 5+ files)
- Do not create tasks that are too small (single line changes)
- Do not forget documentation and test tasks
- Do not plan tasks for out-of-scope features
- Do not assume any task order that violates dependencies
- Do not plan version bump as a task (that is handled by the version-bump skill post-pipeline)

## Codebase Context
- Pure markdown plugin at `C:/gitea_ceos-agents/`
- Skills: `skills/{name}/SKILL.md` with YAML frontmatter
- Core contracts: `core/*.md` (11 files)
- Config: `CLAUDE.md` under `## Automation Config`
- Docs: `docs/guides/` (setup guides), `docs/reference/` (reference docs)
- Tests: `tests/scenarios/*.sh` (shell-based validation)
- Changelog: `CHANGELOG.md` at repo root
- Current version: 6.4.0
- Spec inputs from Phase 4: requirements.md, design.md
- Test inputs from Phase 5: test case definitions
