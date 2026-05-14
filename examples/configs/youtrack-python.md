# Python + YouTrack — Automation Config Template

> Copy the section below into your project's CLAUDE.md

## Automation Config

> **Note:** Per-agent TOML overlay files in `customization/` (e.g., `customization/*.toml`) enable fine-grained customization without forking the plugin. See `docs/guides/toml-overlay-syntax.md` and example overlays in `examples/customization/`. Agent names: `triage-analyst`/`code-analyst` → `analyst`; `e2e-test-engineer` → `test-engineer --e2e`; `reproducer`/`browser-verifier` → `browser-agent`. Update any Pipeline Profiles `Skip stages` values accordingly. See the [CHANGELOG](../../CHANGELOG.md) for the full list of changes.

### Issue Tracker
| Key | Value |
|------|---------|
| Type | youtrack |
| Instance | `<project>.youtrack.cloud` |
| Project | `<PROJECT>` |
| Bug query | `project: <PROJECT> State: Open Type: Bug` |
| State transitions | In Progress: `State: In Progress`, Blocked: `State: Blocked`, For Review: `State: For Review`, Done: `State: Done` |
| On start set | `State: In Progress` |

### Source Control
| Key | Value |
|------|---------|
| Remote | `<hostname>/<owner/repo>` |
| Base branch | `main` |
| Branch naming | `<PROJECT>-{issue}-{short-description}` |

### PR Rules
| Key | Value |
|------|---------|
| Labels | `ForReview` |

### PR Description Template

## Summary
{summary}

## Root Cause
{root_cause}

## Changes
{changes}

## Testing
{testing}

Fixes {issue_id}

### Build & Test
| Key | Value |
|------|---------|
| Build command | `pip install -e .` |
| Test command | `pytest` |

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

