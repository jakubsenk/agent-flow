# Phase 5: TDD

## Test Strategy

This is a markdown-only plugin with no runtime code. Testing is done via the existing manual test harness (`tests/harness/run-tests.sh`) which validates structural integrity of agent definitions, skill files, and cross-references.

### Existing Test Coverage
The test harness checks:
- Agent frontmatter validity (name, description, model, style fields)
- Skill file structure (SKILL.md presence, required frontmatter)
- Cross-references between files (trackers.md entries match skill references)
- Documentation consistency

### Tests for This Change

Since this is a markdown plugin, "tests" means verifying structural integrity after edits. The test harness will catch:

1. **T-1: scaffolder.md structure** — frontmatter intact, section order preserved (Goal > Expertise > Process > Constraints)
2. **T-2: spec-writer.md structure** — frontmatter intact, section order preserved
3. **T-3: scaffold SKILL.md structure** — step numbering consistent, no dangling references
4. **T-4: trackers.md table integrity** — all rows have correct column count

### Manual Verification Checklist

After implementation, verify by reading the modified files:

- [ ] Step 4e explicitly names parent parameters for YouTrack, Jira, Linear, Redmine
- [ ] Step 8b no longer mentions cascade behavior
- [ ] Step 8b closes stories for all tracker types
- [ ] New Step 8a exists with comment posting logic
- [ ] spec-writer has Design & UX section for web projects
- [ ] spec-writer has language fidelity constraint
- [ ] scaffolder has design system batch for web projects
- [ ] All modified files pass `./tests/harness/run-tests.sh`

### Mutation Considerations

Not applicable — no executable code. The "mutations" in a markdown plugin would be removing instructions or changing wording, which can only be caught by semantic review, not automated mutation testing.
