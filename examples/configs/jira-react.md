# React + Jira — Automation Config Template

> Copy the section below into your project's CLAUDE.md

## Automation Config

> **Note:** Per-agent TOML overlay files in `customization/` (e.g., `customization/*.toml`) enable fine-grained customization without forking the plugin. See `docs/guides/toml-overlay-syntax.md` and example overlays in `examples/customization/`. Agent names: `triage-analyst`/`code-analyst` → `analyst`; `e2e-test-engineer` → `test-engineer --e2e`; `reproducer`/`browser-verifier` → `browser-agent`. Update any Pipeline Profiles `Skip stages` values accordingly. See the [CHANGELOG](../../CHANGELOG.md) for the full list of changes.

### Issue Tracker
| Key | Value |
|------|---------|
| Type | jira |
| Instance | `<org>.atlassian.net` |
| Project | `<PROJECT_KEY>` |
| Bug query | `project = <PROJECT_KEY> AND status = Open AND type = Bug` |
| State transitions | In Progress: `transition:In Progress`, Blocked: `transition:Blocked`, For Review: `transition:In Review`, Done: `transition:Done` |
| On start set | `transition:In Progress` |

### Source Control
| Key | Value |
|------|---------|
| Remote | `github.com/<owner/repo>` |
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

Fixes {issue_key}

### Build & Test
| Key | Value |
|------|---------|
| Build command | `npm run build` |
| Test command | `npm test` |

> **Uncomment and customize optional sections as needed.**

<!--
### Autopilot (optional)
| Key | Value |
|-----|-------|
| Max issues per run | 1 |
| Lock timeout | 120 |
| Log file | .agent-flow/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | false |

### Pause Limits (optional)
| Key | Value |
|-----|-------|
| Pause timeout | 30 days |
-->

