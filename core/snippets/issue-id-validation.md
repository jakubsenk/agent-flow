# Snippet — issue_id validation regex

The canonical Bash conditional for validating an `$ISSUE_ID` value before it is interpolated into any path or URL. Cite this file from any new issue-id consumer.

```bash
[[ "$ISSUE_ID" =~ ^[A-Za-z0-9#._-]+$ && ! "$ISSUE_ID" =~ ^\.+$ ]] || {
  echo "Error: invalid issue_id (must match ^[A-Za-z0-9#._-]+$ and not be dot-only)"; exit 1
}
```

**Why two clauses:**
1. `^[A-Za-z0-9#._-]+$` — accepted character class (Jira dotted-keys like `PROJ.NAME-123` are permitted).
2. `! "$ISSUE_ID" =~ ^\.+$` — REJECT dot-only inputs (`.`, `..`, `...`). Without this guard, the regex would accept `..`, which produces `.agent-flow/../state.json` — path-traversal escapes the plugin state directory.

## Used by:
- `skills/fix-bugs/SKILL.md:290` (citation marker `<!-- @snippet:issue-id-validation -->`)

