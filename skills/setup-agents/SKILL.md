---
name: setup-agents
description: One-shot project scanner that generates smart customization/*.toml defaults per agent
allowed-tools: Bash, Read, Write, Glob, Grep
argument-hint: "[--dry-run] [--yolo] [--force]"
disable-model-invocation: true
---

# /agent-flow:setup-agents

## Purpose

One-shot project scanner that detects project type (Python, TypeScript, monorepo, test
framework, Java, Rust, .NET) and generates smart `customization/{agent}.toml` defaults
for agents in the consuming project. This is a meta-agent style one-shot tool — NOT a
continuous meta-gen architecture.

Reference: `docs/guides/setup-agents-skill.md` for full heuristic enumeration and worked examples.
TOML schema: `core/overlay/toml-overlay.md` (3-tier merge contract).

## Synopsis

```
/agent-flow:setup-agents [--dry-run] [--yolo] [--force]
```

Flags:
- (no flags): scan project, preview-diff each planned file, prompt Apply / Skip / Abort before each write.
- `--yolo`: scan and write all generated files silently (no preview prompt). Idempotent regen of `# generated:` files and first-time writes both apply without confirmation.
- `--force`: overwrite existing user-edited files (those WITHOUT `# generated:` header) after backing up to `{agent}.toml.bak-{ISO-8601-timestamp}`; still subject to preview prompt unless `--yolo` is also supplied.
- `--dry-run`: scan and print planned writes to stdout; write nothing to disk.

## Step 1 — Detect project root

Detect project root as the directory containing `CLAUDE.md`, falling back to the git
repository root (`git rev-parse --show-toplevel`), falling back to CWD.

```bash
if [ -f "CLAUDE.md" ]; then
  PROJECT_ROOT="$(pwd)"
elif git rev-parse --show-toplevel > /dev/null 2>&1; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
  PROJECT_ROOT="$(pwd)"
fi
CUSTOMIZATION_DIR="${PROJECT_ROOT}/customization"
```

Ensure `customization/` directory exists (create if absent):

```bash
mkdir -p "${CUSTOMIZATION_DIR}"
```

## Step 2 — Project scan (heuristic detection)

Scan the project root for manifest files and framework configs. Build a detection map:

### Python project detection

Trigger files: `pyproject.toml`, `requirements.txt`, `setup.py`

```bash
PYTHON_PROJECT=false
if [ -f "${PROJECT_ROOT}/pyproject.toml" ] || \
   [ -f "${PROJECT_ROOT}/requirements.txt" ] || \
   [ -f "${PROJECT_ROOT}/setup.py" ]; then
  PYTHON_PROJECT=true
fi
```

If `mypy.ini`, `setup.cfg` (with `[mypy]` section), or `pyproject.toml` (with `[tool.mypy]`)
is present, set `MYPY_DETECTED=true` for stricter type-hint constraints.

Generates: `analyst.toml` + `fixer.toml` with Python-specific `[[constraints]]`:
- PEP 8 style compliance
- Type hints (strict if mypy detected)
- pytest as test framework

### Monorepo detection

Trigger: `pnpm-workspace.yaml`, `turbo.json`, `lerna.json`, `nx.json`, `rush.json` present
at project root, OR ≥ 2 `package.json` files at depth > 1, OR ≥ 2 `pyproject.toml` files
at depth > 1.

```bash
MONOREPO=false
for f in pnpm-workspace.yaml turbo.json lerna.json nx.json rush.json; do
  [ -f "${PROJECT_ROOT}/${f}" ] && MONOREPO=true && break
done
# Also detect by sub-package count
SUB_PKG_COUNT=$(find "${PROJECT_ROOT}" -mindepth 2 -maxdepth 4 -name 'package.json' | wc -l)
[ "$SUB_PKG_COUNT" -ge 2 ] && MONOREPO=true
```

Generates: `analyst.toml` with `[[process_additions]]` for multi-package impact analysis:
- On `--phase impact`, walk all top-level packages and report cross-package dependencies.
- Monorepo guidance appended to the analyst's process steps.

### TypeScript project detection

Trigger: `tsconfig.json` at project root.

Generates: `reviewer.toml` with `[[constraints]]` requiring TypeScript strict-mode compatibility.

### Test framework detection

Trigger files: `jest.config.js`, `jest.config.ts`, `jest.config.mjs`, `jest.config.cjs`,
`vitest.config.js`, `vitest.config.ts`, `vitest.config.mjs`, `pytest.ini`, `pyproject.toml`
(with `[tool.pytest.ini_options]`), `playwright.config.js`, `playwright.config.ts`.

Generates: `test-engineer.toml` with `[limits].test_framework` set to the detected framework name.

### Java / Maven / Gradle detection

Trigger: `pom.xml` or `build.gradle` at project root.

Generates: `fixer.toml` with Java-specific constraints (Maven/Gradle build awareness).

### Rust detection

Trigger: `Cargo.toml` at project root.

Generates: `fixer.toml` with Rust-specific constraints (cargo conventions, clippy awareness).

### .NET detection

Trigger: `*.csproj` or `*.sln` at project root (glob match).

Generates: `fixer.toml` with .NET-specific constraints (dotnet CLI, NuGet conventions).

## Step 3 — Build PlannedOverlays

After detection, construct the set of `PlannedOverlays`: a mapping of
`{agent-name} → {TOML content string}` for all agents where a heuristic fired.

Each generated TOML file begins with:
```
# generated: {ISO-8601-timestamp} by /setup-agents
```

Example header line: `# generated: 2026-04-27T10:00:00Z by /setup-agents`

The `# generated:` header MUST be the first line of every file written by this skill.
This sentinel enables idempotent regen detection (Step 4).

## Step 4 — Idempotent regen + write logic

For each agent in `PlannedOverlays`:

1. Determine target path: `${CUSTOMIZATION_DIR}/{agent}.toml`
2. **Symlink escape guard**: resolve real path before writing:
   ```bash
   # Portable realpath (GNU readlink -f not available on macOS bash 3.2)
   RESOLVED=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "${CUSTOMIZATION_DIR}/${agent}.toml" 2>/dev/null)
   if [ -z "$RESOLVED" ]; then
     # Fallback: uname-based check or skip with WARN
     echo "[WARN] Symlink escape detection skipped: python3 os.path.realpath unavailable" >&2
   else
     CUSTOM_REAL=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "${CUSTOMIZATION_DIR}" 2>/dev/null)
     case "$RESOLVED" in
       "${CUSTOM_REAL}"/*) : ;; # Safe: within customization/
       *) echo "[ERROR] Symlink escape detected: ${CUSTOMIZATION_DIR}/${agent}.toml → ${RESOLVED}; refusing write" >&2; continue ;;
     esac
   fi
   ```
3. **Existing file handling**:
   - **File absent**: proceed to preview prompt (Step 3a), then write.
   - **File exists, first line matches `^# generated: `**: eligible for idempotent regen.
     Proceed to preview prompt (Step 3a), then write.
   - **File exists, first line does NOT match `^# generated: `**: user-edited file.
     - Without `--force`: emit `[WARN] User-edited overlay ${CUSTOMIZATION_DIR}/${agent}.toml preserved; pass --force to overwrite` and SKIP (no preview prompt — no write is planned).
     - With `--force`: backup existing file to `${CUSTOMIZATION_DIR}/${agent}.toml.bak-${TIMESTAMP}` (where TIMESTAMP is ISO-8601 format, e.g. `2026-04-27T103000Z`), then proceed to preview prompt (Step 3a), then write.

**Step 3a — Preview prompt** (UNLESS `--yolo`):

Display a diff-style preview of the planned content vs existing content (if any):

```
[setup-agents] Planned write: customization/{agent}.toml
--- existing (or /dev/null if new)
+++ planned
{diff lines}

Apply / Skip this agent / Abort? [a/s/q]:
```

- `a` (Apply): write the file.
- `s` (Skip this agent): skip this file, continue to next.
- `q` (Abort): halt /setup-agents; no further writes.

With `--yolo`: skip prompt; apply all writes silently.

Scope isolation: NEVER modify files outside `customization/`. NEVER modify `agents/`,
`skills/`, `docs/`, `CLAUDE.md`, `plugin.json`, or any other project or plugin source files.
All writes are restricted to `${CUSTOMIZATION_DIR}/`.

### Legacy `.md` overlay coexistence

When scanning `customization/`, `/setup-agents` may encounter legacy `.md` overlay files
(unsupported — hard error):

- **Only legacy `.md` exists**: emit `[ERROR] Legacy .md overlay format is not supported for {agent}; manual conversion required — see docs/guides/toml-overlay-syntax.md for TOML overlay format examples.` and refuse to proceed.
- **Both legacy `.md` and `.toml` exist**: emit `[ERROR] Legacy .md overlay found alongside {agent}.toml; remove the .md file (TOML takes precedence). See docs/guides/toml-overlay-syntax.md.` and refuse to proceed.
- **Only `.toml` exists**: normal path, no warning.

## Step 5 — TOML output content

Each generated TOML file is minimal, idiomatic, and documented inline.

### Python project — `analyst.toml`

```toml
# generated: {ISO-8601} by /setup-agents
# Python project detected via: pyproject.toml / requirements.txt / setup.py

[[constraints]]
rule = "All code analysis reports must reference PEP 8 compliance status."

[[constraints]]
rule = "Report import structure issues (circular imports, unused imports)."
```

### Python project — `fixer.toml`

```toml
# generated: {ISO-8601} by /setup-agents
# Python project detected. Mypy detected: {true|false}

[[constraints]]
rule = "All new code must be PEP 8 compliant (max line length 88 for Black-compatible projects, 79 otherwise)."

[[constraints]]
rule = "Use type hints on all new public functions and methods."
# (emitted only when MYPY_DETECTED=true)
```

### Python project — `test-engineer.toml` (when pytest.ini detected)

```toml
# generated: {ISO-8601} by /setup-agents
# Test framework detected: pytest

[limits]
test_framework = "pytest"
```

### Monorepo — `analyst.toml`

```toml
# generated: {ISO-8601} by /setup-agents
# Monorepo detected via: {trigger-file or >=2 sub-packages}

[[process_additions]]
step = "after_default"
instruction = "On --phase impact, walk all top-level packages (apps/*, packages/*, libs/*) and report cross-package dependencies in the affected-files list. Include a 'Cross-package impact' subsection in the report."

[[process_additions]]
step = "after_default"
instruction = "For multi-package changes, list each affected package separately with its own impact summary."
```

### TypeScript project — `reviewer.toml`

```toml
# generated: {ISO-8601} by /setup-agents
# TypeScript project detected via: tsconfig.json

[[constraints]]
rule = "All reviewed code must be compatible with TypeScript strict mode (strictNullChecks, noImplicitAny)."

[[constraints]]
rule = "Flag any use of 'any' type without explicit justification comment."
```

### Test framework — `test-engineer.toml` (jest/vitest/playwright)

```toml
# generated: {ISO-8601} by /setup-agents
# Test framework detected: {framework-name}

[limits]
test_framework = "{framework-name}"
```

## Step 6 — Summary report

After all agents processed, print a summary table:

```
[setup-agents] Summary
Agent              | Action  | Reason
-------------------|---------|----------------------------------------
analyst            | Write   | Python project + monorepo heuristics
fixer              | Write   | Python project heuristic
reviewer           | Skip    | User-edited overlay preserved
test-engineer      | Write   | pytest detected
```

Print count: `{N} files written, {M} skipped.`

## Constraints

- NEVER modify files outside `customization/`. All writes restricted to `customization/` dir.
- NEVER modify `agents/`, `skills/`, `docs/`, `CLAUDE.md`, or any plugin source files.
- NEVER read or write CLAUDE.md of the consuming project (only used for project root detection).
- NEVER follow symbolic links for write operations when the link target lies outside `customization/`.
- Every generated file MUST begin with `# generated: {ISO-8601} by /setup-agents` on line 1.
- The `--force` flag MUST create a `.bak-{ISO-8601-timestamp}` backup before overwriting.
- Preview prompt MUST be shown before every write UNLESS `--yolo` is supplied.
- All 17 agents may have customization templates (analyst, fixer, reviewer, test-engineer,
  acceptance-gate, publisher, rollback-agent, spec-analyst, architect,
  scaffolder, priority-engine, spec-writer, spec-reviewer, browser-agent,
  deployment-verifier, backlog-creator, sprint-planner). Note: rollback-agent is invoked by
  fix-bugs when a block occurs — it reverts git state and posts a block comment
  to the issue tracker.
- Use POSIX-portable bash (`#!/usr/bin/env bash`, no GNU-only extensions); compatible with
  bash 3.2 and Git Bash (Windows).
- Use `python3 os.path.realpath()` for symlink resolution (macOS portability; `readlink -f`
  is GNU-only and unavailable on macOS bash 3.2 without GNU coreutils).
- Reference `skills/setup-agents/lib/toml-merge.sh` for TOML write utilities.
- Skills count increases from 28 → 29 after this skill is added.

## Block Comment

If `/setup-agents` fails to complete:

```
[agent-flow] 🔴 Pipeline Block
Agent: setup-agents
Step: {step where failure occurred}
Reason: {max 2 sentences}
Detail: {error output}
Recommendation: {what the human should do — e.g., check python3 availability, verify symlink, pass --force}
```
