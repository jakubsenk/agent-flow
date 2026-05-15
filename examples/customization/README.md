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

## 2. Step Overrides — `customization/steps/{skill}/{NN}-{name}.md`

Replace an entire pipeline step with your own version. The plugin detects the file at
dispatch time and uses yours instead of the default, emitting:
```
[INFO] Step override active: fix-bugs/04-fixer-reviewer-loop from project customization
```

| File | Overrides | What it does |
|------|-----------|--------------|
| `steps/fix-bugs/04-fixer-reviewer-loop.md` | `fix-bugs` step 04 | Example: adds a mandatory Czech-language review rule |

**Rules:**
- Filename MUST exactly match the plugin step filename (case-sensitive, zero-padded)
- Override **replaces** the entire step — there is no insert/before/after
- Near-miss detection: a wrong name like `4-fixer-reviewer-loop.md` emits `[WARN]` and falls through to the default

Full guide: [`docs/guides/steps-decomposition.md`](../../docs/guides/steps-decomposition.md)
