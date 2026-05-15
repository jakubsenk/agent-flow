# Customization Examples

This directory shows how to customize agent-flow behavior in your consuming project
without modifying the plugin itself. There are two independent mechanisms:

---

## 1. Agent TOML Overlays — `customization/{agent}.toml`

Override per-agent behavior: swap model, add process steps, tighten constraints, adjust limits.

| File | Agent | What it does |
|------|-------|--------------|
| `analyst-monorepo.toml` | analyst | Adds workspace-awareness to impact analysis (monorepos) |
| `fixer-no-tests.toml` | fixer | Disables test generation for projects without test infrastructure |
| `reviewer-strict-security.toml` | reviewer | Adds STRIDE threat model and SQL injection checks to every review |

**How to use:** Copy the file into your project's Agent Overrides directory
(configured via `Agent Overrides → Path` in Automation Config, default: `customization/`).
Rename to match the agent you want to customize (e.g. `analyst.toml`, `fixer.toml`).

Full schema reference: [`docs/guides/toml-overlay-syntax.md`](../../docs/guides/toml-overlay-syntax.md)

---

## 2. Step Overrides — planned for v1.2

Step-level overrides (`customization/steps/{skill}/{NN}-{name}.md`) are designed but
not yet active in v1.0. See [docs/guides/steps-decomposition.md](../../docs/guides/steps-decomposition.md)
for the planned interface.

Use [TOML agent overlays](#1-agent-toml-overlays--customizationagenttoml) for current
per-agent customization.
