# Python + YouTrack — Automation Config Template

> Copy the section below into your project's CLAUDE.md

## Automation Config

> **Migration note (v7 → v8):** v8.0.0 introduces per-agent TOML overlay files in
> `customization/` (e.g., `customization/*.toml`) for fine-grained customization without forking the plugin. See
> `docs/guides/toml-overlay-syntax.md` and example overlays in `examples/customization/`.
> Agent names have also changed: `triage-analyst`/`code-analyst` → `analyst`;
> `e2e-test-engineer` → `test-engineer --e2e`; `reproducer`/`browser-verifier` →
> `browser-agent`. Update any Pipeline Profiles `Skip stages` values accordingly.
> For migration guidance, see `docs/guides/migration-v7-to-v8.md` (the `/migrate-config` skill that previously automated this was removed in v9.5.0).

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
| Log file | .ceos-agents/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | false |

### Pause Limits (optional, v6.9.0+)
| Key | Value |
|-----|-------|
| Pause timeout | 30 days |
-->

