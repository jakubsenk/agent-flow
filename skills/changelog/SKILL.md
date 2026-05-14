---
name: changelog
description: Automatic changelog generation from merged PRs
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob
disable-model-invocation: true
---

# Changelog

Generate a changelog from merged PRs since the last git tag. Write to `CHANGELOG.md`.

### 0. MCP pre-flight check

Before any pipeline operation, verify MCP tool availability:
- Read Type from Automation Config (Issue Tracker section)
- Check that at least one `mcp__*` tool matching the tracker type is accessible
- If not accessible → STOP with: "Cannot connect to your {Type} issue tracker. Is the {Type} integration configured? Run `/agent-flow:check-setup` for diagnostics."

## Steps

1. Read Automation Config from CLAUDE.md:
   - Source Control → Remote
   - Issue Tracker → Type (default: youtrack)
   If Automation Config is missing, use git remote and default youtrack.

2. Find the last git tag:
   ```
   git tag --sort=-version:refname | head -1
   ```
   If no tag exists, use the entire history.

3. Get merged commits since the tag:
   ```
   git log {last_tag}..HEAD --oneline --merges
   ```
   If `--merges` returns no results (squash/ff merge workflow), use `git log {tag}..HEAD --oneline` without filter.

4. For each merge commit: retrieve the PR number and title via source control MCP.

5. Categorize by Conventional Commits prefixes:
   - `feat:` → **New Features**
   - `fix:` → **Fixes**
   - `docs:`, `chore:`, `refactor:`, `test:`, `ci:` → **Internal**
   - Other → **Other Changes**

6. Generate a changelog section in Keep a Changelog format:

```markdown
## [{version}] — {date YYYY-MM-DD}

### New Features
- feat: description from PR title (#42)

### Fixes
- fix: description from PR title (#39)

### Internal
- chore: description (#40)
```

7. Write to `CHANGELOG.md`:
   - If the file does not exist, create it with the header `# Changelog`
   - If it exists, insert the new section below the header (above existing versions)

8. Display the result: "Changelog updated: {count} changes in version {version}"

## Rules

- Format: Keep a Changelog (English)
- PRs without a Conventional Commits prefix → "Other Changes" section
- Do not display empty categories
