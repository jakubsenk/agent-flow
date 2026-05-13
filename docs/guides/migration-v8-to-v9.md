# Migration Guide: v8.0.0 → v9.0.0

## Overview

v9.0.0 is a MAJOR release bundling three deliverables:

1. **Sub-projekt H — Agent I/O Contracts** (this release's headline change). Every agent definition under `agents/*.md` now declares its inputs and outputs in a mandatory `## Output Contract` section between `## Process` and `## Constraints`. The contract documents the de-facto section headings and signal sentinels skills already grep against today (e.g., `## Fix Report`, `## NEEDS_DECOMPOSITION`, `## Triage Analysis`); it does not change agent runtime behavior. Validation is author-time lint only via `tests/scenarios/v9-output-contract-*.sh` — there is no runtime schema validator, no JSON Schema sidecar, no LLM self-validation.
2. **Pre-announced `.md` agent overlay hard removal.** Per `docs/guides/migration-v7-to-v8.md:445-454`, v8.0.0 emitted `[WARN]` on `customization/{agent}.md` overlays. v9.0.0 emits `[ERROR]` and refuses dispatch — TOML-only is the supported override format.
3. **Pre-announced deprecated agent name hard errors.** Dispatching `ceos-agents:triage-analyst|code-analyst|e2e-test-engineer|reproducer|browser-verifier` returns `[ERROR]` instead of `[WARN]`. Use the v8 consolidated names: `analyst`, `test-engineer`, `browser-agent`.

The agent count moves from 18 → 17 in v9.0.0 — `agents/stack-selector.md` is deleted as a dead-code cleanup. Stack selection is now performed entirely by the scaffolder agent (which reads Tech Stack from `spec/README.md` in scaffold v2 mode or from skill-supplied flags in `--no-implement` mode).

## Breaking Changes

1. **Mandatory `## Output Contract` section in every agent file.** Plugin-internal change. Consuming projects do not need to modify any file.
2. **`.md` agent overlays no longer dispatched.** If your `customization/` directory still contains `{agent}.md` files, they are now ignored with `[ERROR]`. Migrate to TOML overlays per `docs/guides/migration-v7-to-v8.md`.
3. **Deprecated agent names hard-fail.** If your project's CLAUDE.md, hooks, or custom skills reference `triage-analyst`, `code-analyst`, `e2e-test-engineer`, `reproducer`, or `browser-verifier`, rename them now to: `analyst`, `analyst`, `test-engineer` (use `--e2e` flag), `browser-agent` (use `--phase reproduce`), `browser-agent` (use `--phase verify`) respectively.
4. **`agents/stack-selector.md` deleted.** If your project's CLAUDE.md, hooks, or custom skills reference `ceos-agents:stack-selector`, remove the reference. The scaffolder agent now subsumes stack selection.

## Migration Steps

### Step 1 — Override files (zero-touch)
Your `customization/{agent}.md` files keep working unchanged. The override injector at `core/agent-override-injector.md` is append-only and structure-blind — it appends override content as `## Project-Specific Instructions` regardless of new sections in the base agent file.

If you want to **inspect** for accidental heading collisions:

```bash
grep -lE '^## (Output Contract|Project-Specific Instructions)' customization/*.md 2>/dev/null && echo "WARN: heading collision risk" || echo "OK: no collision"
```

(See "Compatibility Check" below.) A collision does not block injection; it only creates a duplicate-section visual artifact in the resolved agent context. Resolve by renaming the override section to a project-specific heading (e.g., `## My Project Override`).

### Step 2 — Hooks and custom skills (rename + delete)

Search your project's CLAUDE.md, `customization/`, and any custom skill files for the deprecated tokens:

```bash
grep -rE 'ceos-agents:(triage-analyst|code-analyst|e2e-test-engineer|reproducer|browser-verifier|stack-selector)' .
```

For each match:
- `triage-analyst` or `code-analyst` → replace with `analyst` (add `--phase triage` or `--phase impact` accordingly).
- `e2e-test-engineer` → replace with `test-engineer` and add `--e2e` flag.
- `reproducer` → replace with `browser-agent` and add `--phase reproduce` flag.
- `browser-verifier` → replace with `browser-agent` and add `--phase verify` flag.
- `stack-selector` → delete the reference (the scaffolder handles stack selection).

### Step 3 — TOML overlay migration (if `.md` overlays exist)

If `ls customization/*.md` returns files (other than the skip — README.md, etc.), migrate each to TOML:
1. Create `customization/{agent}.toml` with the equivalent content using the `[[process_additions]]` and `[[constraints]]` block format documented in `examples/customization/reviewer-strict-security.toml`.
2. Delete the `.md` file (or move to backup).
3. Re-run `/ceos-agents:check-setup` — it should report no `[ERROR]` overlays.

### Step 4 — Optional: external parsers of agent body content

If your project parses agent body content externally (rare — most projects only use the override injector), expect a `## Output Contract` section between `## Process` and `## Constraints` in every agent file. The section content is documented in `docs/reference/agents.md` (per-agent contract).

## Compatibility Check

Run this before upgrading to confirm your project is migration-ready:

```bash
# Test 1 — no .md overlays remaining
ls customization/*.md 2>/dev/null | grep -v README.md && \
  echo "FAIL: .md overlays found — migrate to .toml first" || \
  echo "OK: no .md overlays"

# Test 2 — no deprecated agent name references
grep -rE 'ceos-agents:(triage-analyst|code-analyst|e2e-test-engineer|reproducer|browser-verifier|stack-selector)' . \
  --include='*.md' --include='*.toml' && \
  echo "FAIL: deprecated agent names found — rename per Step 2" || \
  echo "OK: no deprecated agent names"

# Test 3 — heading collision check on overrides
grep -lE '^## (Output Contract|Project-Specific Instructions)' customization/*.md 2>/dev/null && \
  echo "WARN: heading collision risk — see Step 1" || \
  echo "OK: no collision"
```

All three should output OK before running `/ceos-agents:version-bump 9.0.0`.
