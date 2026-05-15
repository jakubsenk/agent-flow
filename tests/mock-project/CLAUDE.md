# Mock Project

Test project for smoke testing the agent-flow pipeline.

## Automation Config

### Issue Tracker
| Key | Value |
|------|---------|
| Type | youtrack |
| Instance | `test.youtrack.cloud` |
| Project | `MOCK` |
| Bug query | `project: MOCK State: Open Type: Bug` |
| State transitions | In Progress: `In Progress`, Blocked: `Blocked`, For Review: `For Review` |
| On start set | `State: In Progress` |

### Source Control
| Key | Value |
|------|---------|
| Remote | `<your-gitea-host>/test/mock-project` |
| Base branch | `main` |
| Branch naming | `MOCK-{issue}-{short-description}` |

### PR Rules
| Key | Value |
|------|---------|
| Labels | `ForReview` |

### PR Description Template

```
## Summary
{summary}

## Root Cause
{root_cause}

## Changes
{changes}

## Testing
{testing}

Fixes {issue_link}
```

### Build & Test
| Key | Value |
|------|---------|
| Build command | `python -c "import app"` |
| Test command | `python -m pytest tests/ -v` |

### Retry Limits (optional)
| Key | Value |
|------|---------|
| Fixer iterations | 3 |
| Test attempts | 2 |
| Build retries | 2 |

### Hooks (optional)
| Key | Value |
|------|---------|
| Pre-fix | `echo "pre-fix hook"` |
| Post-fix | `echo "post-fix hook"` |

### Worktrees (optional)
| Key | Value |
|------|---------|
| Batch size | 2 |
| Base path | `.worktrees/` |
| Cleanup | auto |

### Feature Workflow (optional)
| Key | Value |
|------|---------|
| Feature query | `project: MOCK State: Open Type: Feature` |
| On start set | `State: In Progress` |

### Decomposition (optional)
| Key | Value |
|------|---------|
| Max subtasks | 5 |
| Fail strategy | fail-fast |
| Commit strategy | squash |

### Pipeline Profiles (optional)
| Profile | Skip stages | Extra stages |
|--------|-------------|--------------|
| fast | triage, test-engineer-e2e | — |
| ci | analyst-impact, test-engineer-e2e | — |

### Metrics (optional)
| Key | Value |
|-----|-------|
| Output | stdout |
| Period | 30 |
