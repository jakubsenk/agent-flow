# Agent 1: Minimalist Migrator — Position Paper

## Decision 1: Frontmatter strategy

Keep only what already exists: `name`, `description`, `allowed-tools`. Do not add `model`, `context`, `paths`, or `hooks` during migration — those are scope expansion. The only required change is renaming the source file from `commands/foo.md` to `skills/foo/SKILL.md`. One new field worth adding: `argument-hint` where the command already documents its argument syntax in the first line of the body, because it costs nothing to surface and improves UX in the picker. That is the ceiling.

## Decision 2: File splitting strategy

Do not split any file. The 200-line threshold is not a technical constraint — skills have no documented line limit. Splitting introduces new files, new paths, and new cross-references. If a file exceeds 200 lines, leave it as-is inside its skill directory. The directory structure already provides natural grouping if reference material is needed later. Zero splits, zero new files.

## Decision 3: Cross-reference update strategy

Update only files that will break if left unchanged: the 25 test files that assert `commands/` paths, and any file that generates or validates those paths at runtime. The 3 core files, CLAUDE.md, and the 1 docs file should be updated only if they contain paths that are checked programmatically or that cause test failures. Purely descriptive references (prose that says "commands/fix-bugs.md") do not break anything and can stay until a documentation pass is planned separately. Distinguish breaking from cosmetic; fix only breaking.

## Decision 4: Test migration approach

Update the 25 test file references from `commands/foo.md` to `skills/foo/SKILL.md` as a mechanical find-and-replace. Do not restructure test logic, add new scenarios, or change assertions. If a test passes after the path update, it is done. If a test fails for a reason unrelated to the path, note it and move on — the migration is not a bug-fix sprint. One commit per logical batch (e.g., path updates separate from frontmatter changes) to keep the diff reviewable.

## Decision 5: Migration ordering

1. Create all `skills/*/` directories and copy files (no deletions yet).
2. Update frontmatter in all copied files (add `name`, optionally `argument-hint`).
3. Update test paths (mechanical find-replace).
4. Run tests; fix only path-related failures.
5. Delete `commands/` directory.
6. Update breaking cross-references in core/CLAUDE.md only if tests or tooling require it.

This order means the plugin is never in a broken state mid-migration: old paths exist until new paths are verified.
