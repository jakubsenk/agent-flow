## Automation Config

### Issue Tracker
| Key | Value |
|------|---------|
| Type | github |
| Instance | `github.com` |
| Project | `test-org/test-repo` |
| Bug query | `is:issue is:open label:bug` |
| State transitions | In Progress: `add label:in-progress`, Blocked: `add label:blocked`, For Review: `add label:for-review` |
| On start set | `add label:in-progress` |

### Source Control
| Key | Value |
|------|---------|
| Remote | `github.com/test-org/test-repo` |
| Base branch | `main` |
| Branch naming | `fix/{issue}-{short-description}` |

### PR Rules
| Key | Value |
|------|---------|
| Labels | `ForReview` |

### PR Description Template

## Summary
{summary}

## Changes
{changes}

## Testing
{testing}

Fixes #{issue_number}

### Build & Test
| Key | Value |
|------|---------|
| Build command | `echo "build ok"` |
| Test command | `echo "test ok"` |
| Verify command | `echo "verify ok"` |

### Pipeline Profiles
| Profile | Skip stages | Extra stages |
|--------|-------------|-------------|
| fast | triage, code-analyst, test-engineer | |
| strict | | e2e-test-engineer |
| minimal | triage, code-analyst, test-engineer, e2e-test-engineer | |
