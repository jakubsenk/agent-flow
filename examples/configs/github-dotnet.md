# .NET + GitHub — Automation Config Template

> Copy the section below into your project's CLAUDE.md

## Automation Config

> **Migration note (v7 → v8):** v8.0.0 introduces per-agent TOML overlay files in
> `customization/` (e.g., `customization/*.toml`) for fine-grained customization without forking the plugin. See
> `docs/guides/toml-overlay-syntax.md` and example overlays in `examples/customization/`.
> Agent names have also changed: `triage-analyst`/`code-analyst` → `analyst`;
> `e2e-test-engineer` → `test-engineer --e2e`; `reproducer`/`browser-verifier` →
> `browser-agent`. Update any Pipeline Profiles `Skip stages` values accordingly.
> Upgrading? See the [CHANGELOG](../../CHANGELOG.md) for breaking changes and update your `## Automation Config` to match the current format.

### Issue Tracker
| Key | Value |
|------|---------|
| Type | github |
| Instance | `github.com` |
| Project | `<owner/repo>` |
| Bug query | `is:issue is:open label:bug` |
| State transitions | In Progress: `add label:in-progress`, Blocked: `add label:blocked`, For Review: `add label:for-review`, Done: `close` |
| On start set | `add label:in-progress` |

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

## Root Cause
{root_cause}

## Changes
{changes}

## Testing
{testing}

Fixes #{issue_number}

### Build & Test
| Key | Value |
|------|---------|
| Build command | `dotnet build` |
| Test command | `dotnet test` |

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

### Pause Limits (optional, v6.9.0+)
| Key | Value |
|-----|-------|
| Pause timeout | 30 days |
-->

