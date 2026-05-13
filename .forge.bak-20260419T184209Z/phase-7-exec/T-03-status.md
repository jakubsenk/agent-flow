# T-03 Status — Autopilot block appended to 6 bare config templates

**Result:** DONE

## Per-file verification (`### Autopilot` grep count = 1)

| File | Count | Status |
|------|-------|--------|
| examples/configs/github-python-fastapi.md | 1 | PASS |
| examples/configs/github-dotnet.md | 1 | PASS |
| examples/configs/gitea-spring-boot.md | 1 | PASS |
| examples/configs/jira-react.md | 1 | PASS |
| examples/configs/youtrack-python.md | 1 | PASS |
| examples/configs/redmine-rails.md | 1 | PASS |

## Block appended (verbatim from design.md:63-78)

```markdown

> **Uncomment and customize optional sections as needed.**

<!--
### Autopilot (optional)
| Key | Value |
|-----|-------|
| Max issues per run | 1 |
| Lock timeout | 120 |
| Log file | .ceos-agents/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | false |
-->
```

All 6 files: block appended at EOF, trailing newline preserved, no other modifications.
