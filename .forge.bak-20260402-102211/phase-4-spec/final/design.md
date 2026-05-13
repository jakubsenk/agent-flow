# Design: Commands-to-Skills Migration (v6.0.0)

## ADR-1: Why Skills, Not Commands

### Context

Claude Code's plugin system supports two orchestration formats:
- **Commands**: `commands/{name}.md` -- flat files, minimal frontmatter (`description`, `allowed-tools`)
- **Skills**: `skills/{name}/SKILL.md` -- directory-per-skill, richer frontmatter including `disable-model-invocation`, `argument-hint`, `context`, `model`, `paths`, `hooks`

### Decision

Migrate all 25 commands to the skills format.

### Rationale

1. **Safety via `disable-model-invocation: true`**: Pipeline and destructive skills (fix-ticket, scaffold, publish, etc.) can be marked so Claude Code will not auto-invoke them based on model reasoning alone. They require explicit user invocation via `/ceos-agents:{name}` or confirmation through the workflow-router. This is an Anthropic-recommended safety pattern for tools that modify code, create PRs, or change issue tracker state.

2. **Richer frontmatter**: Skills support `argument-hint` (shown in autocomplete), `context` (future: automatic context injection), and other fields that commands lack. This migration establishes the foundation for incremental adoption.

3. **Unified format**: The existing `workflow-router` already lives in `skills/`. After migration, all orchestration definitions live in one directory with one format. No more explaining the commands-vs-skills split to contributors.

4. **Namespace unchanged**: The `ceos-agents:` prefix works identically for skills. Users invoke `/ceos-agents:fix-ticket` before and after migration. The `$ARGUMENTS` variable works the same way in skills.

---

## ADR-2: No File Splitting in v6.0.0

### Context

Several commands (fix-bugs, scaffold, implement-feature) are 300+ lines. Splitting them into smaller, composable units was considered.

### Decision

Do NOT split files during v6.0.0. Move each command file as-is into its skill directory.

### Rationale

1. **Approved brainstorm direction**: Gate 1 review explicitly approved "no file splitting during migration" to preserve test stability.

2. **Test coupling**: 22 test scenarios grep exact patterns inside command files. Splitting would require rewriting test assertions against a new structure, compounding migration risk.

3. **Scope control**: v6.0.0 is a structural migration (file locations + frontmatter). Content changes (splitting, refactoring) belong in a follow-up PR where they can be tested independently.

4. **Follow-up**: A v6.1.0 PR can split large skills into composable parts after the migration is stable.

---

## ADR-3: Migration Ordering

### Decision

7-phase incremental approach:

1. **Phase 1**: Move 11 read-only/analysis skills
2. **Phase 2**: Move 14 pipeline/destructive skills
3. **Phase 3**: Update cross-references in tests + core (Batch A)
4. **Phase 4**: Update CLAUDE.md (Batch B)
5. **Phase 5**: Update docs prose (Batch C)
6. **Phase 6**: Delete `commands/` directory
7. **Phase 7**: Version bump to 6.0.0

### Rationale

- **Read-only first**: These have fewer cross-references and lower risk. Moving them first validates the migration mechanics.
- **Pipeline second**: These are referenced by more tests. Moving them after read-only skills means the directory structure is already validated.
- **Cross-references after all moves**: If we updated references mid-migration, some would point to `skills/` and some to `commands/`, causing test failures during the transition. Updating all references after all files are moved means the test suite can pass at each commit boundary.
- **CLAUDE.md separately**: CLAUDE.md changes are high-visibility and warrant their own review.
- **Delete last**: Only after all references are updated do we remove the source directory.
- **Version bump last**: The version reflects the completed migration state.

---

## ADR-4: Backward Compatibility

### Namespace

The `ceos-agents:` namespace prefix is unchanged. Users invoke skills the same way they invoked commands:

```
/ceos-agents:fix-ticket PROJ-123
/ceos-agents:scaffold "my project description"
```

Claude Code's plugin system resolves `ceos-agents:fix-ticket` to `skills/fix-ticket/SKILL.md` automatically after migration.

### $ARGUMENTS

The `$ARGUMENTS` variable works identically in skills. No behavioral change.

### Workflow Router

The `skills/workflow-router/SKILL.md` routes via `ceos-agents:{name}` namespace identifiers, not file paths. It requires zero changes for the migration.

### Agent Dispatch

Skills dispatch agents via the Task tool using `ceos-agents:{agent-name}` identifiers. Agents remain in `agents/`. No changes to agent files.

### Breaking Change Classification

This is a MAJOR version bump (5.x -> 6.0.0) because:
- The `commands/` directory is removed (structural breaking change)
- Any external tooling that references `commands/{name}.md` paths will break
- The Automation Config contract is unchanged -- this is NOT a config-level breaking change

Consumers who only invoke skills via `/ceos-agents:{name}` will not notice any difference.

---

## ADR-5: Test Migration Strategy

### Principle

Tests are migrated by mechanical path substitution. No behavioral changes to test logic.

### Pattern Categories

| Pattern | Count | Substitution |
|---------|-------|-------------|
| `$REPO_ROOT/commands/{name}.md` | ~45 occurrences across 22 files | `$REPO_ROOT/skills/{name}/SKILL.md` |
| `$REPO_ROOT/commands` (directory) | ~8 occurrences | `$REPO_ROOT/skills` |
| `"commands/{name}.md"` (relative) | ~16 occurrences | `"skills/{name}/SKILL.md"` |
| `$COMMANDS_DIR/*.md` glob | ~5 occurrences | `find "$SKILLS_DIR" -name SKILL.md` |
| `ls "$dir"/*.md \| wc -l` | 2 occurrences | `find "$dir" -name SKILL.md \| wc -l` |
| Error messages with "command" | ~15 occurrences | Updated to "skill" |

### Directory Glob Migration

The key structural difference between commands and skills is:
- Commands: `commands/*.md` -- flat directory, globbed with `*.md`
- Skills: `skills/*/SKILL.md` -- nested directories, each containing `SKILL.md`

Tests that use `ls "$dir"/*.md | wc -l` must switch to `find "$dir" -name SKILL.md | wc -l` because skills are in subdirectories.

Tests that use `grep -rl pattern "$dir"/*.md` must switch to `find "$dir" -name SKILL.md -exec grep -l pattern {} +` for the same reason.

### New Assertions

Two new test assertions are added (can be a new scenario file `skill-frontmatter.sh` or appended to existing `frontmatter-completeness.sh`):

1. **FC-5 check**: All 14 pipeline skills have `disable-model-invocation: true` in frontmatter
2. **FC-6 check**: All 11 read-only skills do NOT have `disable-model-invocation` in frontmatter

### Existing Test Count

The test harness currently runs 37 scenarios. After migration, all 37 must still pass, plus 1 new scenario (or 2 new assertions in an existing scenario). Expected final count: 38 scenarios.
