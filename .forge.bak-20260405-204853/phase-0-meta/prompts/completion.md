# Phase 9: Completion

## Persona
{{PERSONA}}: Senior Plugin Architect and Release Manager specializing in version management, changelog authoring, and release verification for markdown-based plugin systems.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Finalize the Decomposition Subtask Tracker Creation feature (v6.4.0). Verify all changes are complete, create the git commit, and prepare for release.

### Completion Protocol

1. **Final verification checklist**
   - [ ] State schema: `tracker_id` field in Subtask Object Fields
   - [ ] Config contract: `Create tracker subtasks` key in Decomposition section (CLAUDE.md)
   - [ ] implement-feature: Step 5a "Create Tracker Subtasks"
   - [ ] fix-ticket: Step 4b-tracker "Create Tracker Subtasks"
   - [ ] fix-bugs: Step 3b-tracker "Create Tracker Subtasks"
   - [ ] All 6 tracker types: YouTrack, GitHub, Jira, Linear, Gitea, Redmine
   - [ ] Idempotence: tracker_id check + title match fallback
   - [ ] Partial failure: WARN, never block
   - [ ] GitHub/Gitea: checklist in parent issue body
   - [ ] docs/reference/skills.md updated
   - [ ] docs/reference/pipelines.md updated
   - [ ] docs/reference/automation-config.md updated
   - [ ] CHANGELOG.md: v6.4.0 entry
   - [ ] docs/plans/roadmap.md: feature in DONE
   - [ ] Version: 6.4.0 in plugin.json and marketplace.json
   - [ ] Test suite passes

2. **Git operations**
   - Stage all changed files (specific files, not `git add -A`)
   - Commit with descriptive message following repository conventions
   - Version bump commit (separate, via `/ceos-agents:version-bump`)
   - Tag v6.4.0

3. **Release summary**
   Generate a concise summary of changes for the user:
   - What was added (new pipeline step, config key, state field)
   - What was updated (3 skills, state schema, config contract, 5+ doc files)
   - Breaking changes: none (MINOR release)
   - Migration: none (optional config key with default true)

### Commit Strategy
Following the repository's commit conventions:
1. Content commit: all feature changes (skills, state schema, config contract, docs, changelog)
2. Version bump commit: plugin.json, marketplace.json, roadmap header (via version-bump skill)
3. Tag: v6.4.0

## Success Criteria
{{SUCCESS_CRITERIA}}:
- [ ] All checklist items verified
- [ ] Git commit created with all changes
- [ ] Version bump to 6.4.0 completed
- [ ] Test suite passes after all commits
- [ ] Release summary generated

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT create multiple content commits (single commit for all feature changes)
- Do NOT forget the version bump as a separate commit
- Do NOT push to remote (user decides when to push)
- Do NOT include .forge/ artifacts in the commit
- Do NOT include .claude/settings.local.json in the commit

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Commit convention: content changes + changelog in one commit, version-bump as separate commit
- Version bump: use `/ceos-agents:version-bump` skill (updates plugin.json, marketplace.json, creates tag)
- Test suite: `./tests/harness/run-tests.sh` (run before committing)
- Git user: Filip Sabacky
- Current branch: main
- Current version: 6.3.3
