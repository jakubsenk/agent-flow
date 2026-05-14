# Roadmap

agent-flow is a Claude Code plugin that automates bug-fix, feature, and scaffold
workflows — from issue tracker to merged PR — using a pipeline of specialized AI agents.

---

## v1.1.0 — Planned

### Direct Mode (tracker-free)
Use a text prompt, file, or TODO comment as the input instead of an issue tracker.
Enables `--no-pr` mode for local-only commits and teams without a tracker setup.

### Per-skill prerequisites
Lazy validation of required CLI tools (gh, jq, docker) before a pipeline starts,
with a clear "missing X, install with Y" message instead of a mid-run failure.

---

## Backlog (designed, not yet scheduled)

| Feature | What it enables |
|---------|----------------|
| **Monorepo support** | Per-package configs, selective test running |
| **Automated changelog** | Rich changelogs generated from pipeline execution data |
| **Dependency vulnerability scanning** | npm audit / pip-audit / trivy as an optional pipeline stage |
| **Performance regression testing** | Benchmark before/after a fix, surface regressions automatically |
| **Replace https://example.invalid/agent-flow.git placeholder** | Swap the canonical placeholder URL in `.claude-plugin/plugin.json` for the final public repository URL once it is provisioned |

---

## Post-release housekeeping (v1.0.0)

Skill / agent / contract counts after the v1.0.0 public release: **17 skills (down from 18 pre-release)**, **17 agents (unchanged)**, **17 core (unchanged)**. The skill reduction reflects removal of internal-only tooling; agent and contract surfaces are stable.

---

## Vision (longer term)

| Item | Description |
|------|-------------|
| **Multi-IDE support** | Cursor, Windsurf, Kiro — via a converter layer |
| **Module ecosystem** | Third-party agent bundles and a public registry |
