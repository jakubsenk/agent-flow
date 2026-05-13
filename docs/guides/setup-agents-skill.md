# /ceos-agents:setup-agents — Guide

Tato příručka popisuje dovednost `/ceos-agents:setup-agents` — jednorázový skener projektu,
který automaticky vygeneruje chytré výchozí hodnoty `customization/{agent}.toml` přizpůsobené
vašemu technologickému stacku. Hodí se pro první nastavení nového projektu, po větší refaktoraci
nebo při onboardingu nového člena týmu.

---

## Overview

`/ceos-agents:setup-agents` is a **one-shot project scanner** that reads the project root
(manifest files, framework configs, test configurations) and generates
`customization/{agent}.toml` overlay files with sensible, project-specific defaults for each
relevant agent.

**What it does:**
- Detects project type (Python, TypeScript/JS, Java/Maven/Gradle, Rust, .NET, monorepo)
- Generates `customization/{agent}.toml` files with heuristic-driven constraints and settings
- Prepends a `# generated:` header so files can be safely regenerated later (idempotent regen)
- Shows a preview diff before every write (unless `--yolo` is supplied)

**What it is NOT:**
- Not a continuous meta-gen architecture — it does not watch for file changes or auto-update overlays
- Not a code generator — it produces TOML overlay configuration, not source code
- Not a replacement for manual agent customization — generated defaults are starting points

The reference skill definition is at `skills/setup-agents/SKILL.md`.
The TOML overlay contract is at `core/overlay/toml-overlay.md`.

---

## When to Use It

| Scenario | Recommended action |
|----------|--------------------|
| First-time setup of a consuming project | Run `/ceos-agents:setup-agents` after `/ceos-agents:check-setup` |
| Post-major-refactor (e.g., added TypeScript, switched to monorepo) | Re-run to regenerate heuristic overlays; user-edited files are preserved |
| New team member onboarding | Run once in the project root to establish shared agent defaults |
| Reviewing what overlays would be generated without writing | Run with `--dry-run` |
| Resetting all generated overlays to current heuristics | Delete `customization/` and re-run (or use `--force`) |

---

## Synopsis

```
/ceos-agents:setup-agents [--dry-run] [--yolo] [--force]
```

### Flags

| Flag | Behavior |
|------|----------|
| (none) | Scan project, show preview diff, prompt `Apply / Skip / Abort` before each write |
| `--dry-run` | Scan and print planned writes to stdout; write nothing to disk |
| `--yolo` | Scan and write all generated files silently (no preview prompt); compatible with idempotent regen and first-time writes |
| `--force` | Overwrite user-edited files (those without `# generated:` header) after creating a `.bak-{ISO-8601}` backup; still subject to preview prompt unless `--yolo` is also supplied |

`--yolo` and `--force` may be combined: `--yolo --force` writes all planned files silently,
including user-edited ones (with backup).

`--dry-run` takes precedence over all other flags; no writes occur.

---

## Project Scanning Heuristics

`/setup-agents` detects project type by probing for manifest and configuration files in the
project root. When a heuristic fires, it schedules one or more `customization/{agent}.toml`
writes. Multiple heuristics may fire in the same run; their outputs are merged into the
`PlannedOverlays` map per agent before any write begins.

### Heuristic-to-Overlay Mapping

| Detected project type | Trigger files | Generated overlays |
|-----------------------|---------------|--------------------|
| **Python** | `pyproject.toml` OR `requirements.txt` OR `setup.py` | `analyst.toml`, `fixer.toml` |
| **Python + mypy** | Any Python trigger + `mypy.ini` OR `pyproject.toml[tool.mypy]` OR `setup.cfg[mypy]` | `fixer.toml` (adds strict type-hint constraint) |
| **TypeScript** | `tsconfig.json` | `reviewer.toml` |
| **JavaScript / Node** | `package.json` (without `tsconfig.json`) | `test-engineer.toml` (if test framework detected) |
| **Jest test framework** | `jest.config.js`, `jest.config.ts`, `jest.config.mjs`, `jest.config.cjs` | `test-engineer.toml` |
| **Vitest test framework** | `vitest.config.js`, `vitest.config.ts`, `vitest.config.mjs` | `test-engineer.toml` |
| **Pytest test framework** | `pytest.ini` OR `pyproject.toml[tool.pytest.ini_options]` | `test-engineer.toml` |
| **Playwright** | `playwright.config.js`, `playwright.config.ts` | `test-engineer.toml` |
| **Java / Maven** | `pom.xml` | `fixer.toml` |
| **Java / Gradle** | `build.gradle` OR `build.gradle.kts` | `fixer.toml` |
| **Rust** | `Cargo.toml` | `fixer.toml` |
| **.NET** | `*.csproj` OR `*.sln` (glob at project root) | `fixer.toml` |
| **Monorepo** | `pnpm-workspace.yaml`, `turbo.json`, `lerna.json`, `nx.json`, `rush.json`, OR ≥ 2 `package.json` at depth > 1, OR ≥ 2 `pyproject.toml` at depth > 1 | `analyst.toml` (multi-package guidance) |

### All 18 Agent Names (eligible for overlay generation)

The following 18 canonical agent names (post-v8.0.0) may appear as generated `{agent}.toml`
filenames in `customization/`:

`analyst`, `fixer`, `reviewer`, `test-engineer`, `acceptance-gate`, `publisher`,
`rollback-agent`, `spec-analyst`, `architect`, `stack-selector`, `scaffolder`,
`priority-engine`, `spec-writer`, `spec-reviewer`, `browser-agent`, `deployment-verifier`,
`backlog-creator`, `sprint-planner`

Current heuristics generate overlays for: `analyst`, `fixer`, `reviewer`, `test-engineer`.
Other agents can be customized by manually creating `customization/{agent}.toml` files (see
`docs/guides/toml-overlay-syntax.md`).

---

## Output Format

Every file written by `/setup-agents` begins with a `# generated:` header on line 1:

```
# generated: {ISO-8601-timestamp} by /setup-agents v8.0.0
```

This sentinel line enables idempotent regen (see next section). Example:

```toml
# generated: 2026-04-27T10:00:00Z by /setup-agents v8.0.0
# Python project detected via: pyproject.toml

[[constraints]]
rule = "All code analysis reports must reference PEP 8 compliance status."

[[constraints]]
rule = "Report import structure issues (circular imports, unused imports)."
```

The comment on line 2 records which heuristic triggered the file (for traceability).
All generated TOML is idiomatic and inline-documented.

---

## Idempotent Regen

Running `/setup-agents` multiple times on the same project is safe:

| File state | Behavior |
|------------|----------|
| **File absent** | Planned write proceeds (subject to preview prompt) |
| **File exists, first line matches `^# generated: `** | File is eligible for idempotent regen; planned write proceeds (subject to preview prompt) |
| **File exists, first line does NOT match `^# generated: `** | User-edited file — SKIPPED with `[WARN] User-edited overlay {path} preserved; pass --force to overwrite`. No preview prompt is shown (no write is planned). |
| **File exists, user-edited, `--force` supplied** | Existing file is backed up to `{agent}.toml.bak-{ISO-8601-timestamp}`, then planned write proceeds (subject to preview prompt) |

**Locking your customizations:** To prevent `/setup-agents` from ever overwriting a file you
have hand-tuned, simply remove the `# generated:` header from the first line. The skill will
treat it as user-edited and skip it in all future runs (unless `--force` is explicitly passed).

---

## Preview Prompt

Before writing any file (unless `--yolo` is supplied), `/setup-agents` displays a diff-style
preview:

```
[setup-agents] Planned write: customization/fixer.toml
--- existing (or /dev/null if new)
+++ planned
 # generated: 2026-04-26T09:00:00Z by /setup-agents v8.0.0
-# Python project detected via: requirements.txt
+# Python project detected via: pyproject.toml
 
 [[constraints]]
 rule = "All new code must be PEP 8 compliant (max line length 88 for Black-compatible projects, 79 otherwise)."

Apply / Skip this agent / Abort? [a/s/q]:
```

| Input | Action |
|-------|--------|
| `a` | Apply — write the file and continue to next agent |
| `s` | Skip this agent — leave the file unchanged, continue to next agent |
| `q` | Abort — halt `/setup-agents`; no further writes in this run |

The preview prompt fires for: first-time writes, idempotent regen of generated-header files,
and `--force` overwrites of user-edited files. Only `--yolo` bypasses the prompt entirely.

---

## Symlink Guard

`/setup-agents` enforces a strict scope boundary: **all writes are restricted to
`customization/`** within the resolved project root. A symlink inside `customization/` that
points outside this directory is a potential escape vector and is rejected:

```
[ERROR] Symlink escape detected: customization/fixer.toml → /etc/fixer.toml; refusing write
```

**Portability note:** Symlink resolution uses `python3 os.path.realpath()` for macOS bash 3.2
compatibility (GNU `readlink -f` is unavailable on macOS without GNU coreutils). If `python3`
is not available, a `[WARN]` is emitted and the guard is skipped:

```
[WARN] Symlink escape detection skipped: python3 os.path.realpath unavailable
```

---

## Scope Isolation

`/setup-agents` is strictly scoped to the `customization/` directory:

- NEVER modifies `agents/`, `skills/`, `docs/`, `CLAUDE.md`, `plugin.json`, or any plugin
  source file
- NEVER modifies the consuming project's `CLAUDE.md` (only reads it for project root detection)
- NEVER follows symbolic links whose resolved target lies outside `customization/`
- All writes go to `${PROJECT_ROOT}/customization/{agent}.toml` exclusively

If a write would violate scope isolation, the skill emits `[ERROR]` and refuses the write.

---

## Common Workflows

### Example 1: Fresh Python Project Setup

**Project layout:**
```
my-api/
  CLAUDE.md
  pyproject.toml          ← triggers Python + mypy heuristic
  mypy.ini                ← triggers strict type-hint constraint
  pytest.ini              ← triggers pytest test framework
  src/
    api/
```

**Run:**
```bash
/ceos-agents:setup-agents
```

**Expected preview (3 files planned):**

```
[setup-agents] Planned write: customization/analyst.toml
--- /dev/null
+++ planned
+# generated: 2026-04-27T10:00:00Z by /setup-agents v8.0.0
+# Python project detected via: pyproject.toml
+
+[[constraints]]
+rule = "All code analysis reports must reference PEP 8 compliance status."
+
+[[constraints]]
+rule = "Report import structure issues (circular imports, unused imports)."

Apply / Skip this agent / Abort? [a/s/q]: a
```

**Resulting `customization/fixer.toml`:**
```toml
# generated: 2026-04-27T10:00:00Z by /setup-agents v8.0.0
# Python project detected. Mypy detected: true

[[constraints]]
rule = "All new code must be PEP 8 compliant (max line length 88 for Black-compatible projects, 79 otherwise)."

[[constraints]]
rule = "Use type hints on all new public functions and methods."
```

**Resulting `customization/test-engineer.toml`:**
```toml
# generated: 2026-04-27T10:00:00Z by /setup-agents v8.0.0
# Test framework detected: pytest

[limits]
test_framework = "pytest"
```

**Summary output:**
```
[setup-agents] Summary
Agent              | Action  | Reason
-------------------|---------|------------------------------------------
analyst            | Write   | Python project heuristic
fixer              | Write   | Python project + mypy heuristics
test-engineer      | Write   | pytest framework detected

3 files written, 0 skipped.
```

---

### Example 2: TypeScript Monorepo with Vitest

**Project layout:**
```
my-monorepo/
  CLAUDE.md
  package.json            ← checked for workspaces field
  pnpm-workspace.yaml     ← triggers monorepo heuristic
  tsconfig.json           ← triggers TypeScript heuristic
  vitest.config.ts        ← triggers vitest test framework
  apps/
    web/package.json      ← counted by sub-package depth check
    api/package.json
  packages/
    ui/package.json
```

**Run (silent mode):**
```bash
/ceos-agents:setup-agents --yolo
```

**Resulting `customization/analyst.toml`:**
```toml
# generated: 2026-04-27T10:00:00Z by /setup-agents v8.0.0
# Monorepo detected via: pnpm-workspace.yaml

[[process_additions]]
step = "after_default"
instruction = "On --phase impact, walk all top-level packages (apps/*, packages/*, libs/*) and report cross-package dependencies in the affected-files list. Include a 'Cross-package impact' subsection in the report."

[[process_additions]]
step = "after_default"
instruction = "For multi-package changes, list each affected package separately with its own impact summary."
```

**Resulting `customization/reviewer.toml`:**
```toml
# generated: 2026-04-27T10:00:00Z by /setup-agents v8.0.0
# TypeScript project detected via: tsconfig.json

[[constraints]]
rule = "All reviewed code must be compatible with TypeScript strict mode (strictNullChecks, noImplicitAny)."

[[constraints]]
rule = "Flag any use of 'any' type without explicit justification comment."
```

**Resulting `customization/test-engineer.toml`:**
```toml
# generated: 2026-04-27T10:00:00Z by /setup-agents v8.0.0
# Test framework detected: vitest

[limits]
test_framework = "vitest"
```

---

### Example 3: Adding a Manual Customization (Locked from Regen)

After `/setup-agents` creates `customization/reviewer.toml`, you want to add a project-specific
constraint that should never be overwritten by regen.

**Step 1 — Edit the file and remove the `# generated:` header:**

```toml
# TypeScript project: strict mode + project conventions
# (header removed — this file is now user-managed)

[[constraints]]
rule = "All reviewed code must be compatible with TypeScript strict mode (strictNullChecks, noImplicitAny)."

[[constraints]]
rule = "Flag any use of 'any' type without explicit justification comment."

[[constraints]]
rule = "Reject any PR that removes existing Jest snapshots without a documented rationale."
```

**Step 2 — Re-run `/setup-agents` (future runs):**
```bash
/ceos-agents:setup-agents
```

Output:
```
[WARN] User-edited overlay customization/reviewer.toml preserved; pass --force to overwrite
[setup-agents] Summary
Agent              | Action  | Reason
-------------------|---------|------------------------------------------
reviewer           | Skip    | User-edited overlay preserved
test-engineer      | Write   | vitest framework (regen — no changes)

1 files written, 1 skipped.
```

The `reviewer.toml` is safely skipped on every future run until you explicitly pass `--force`.

---

### Example 4: Dry-Run Preview Before First Setup

Before committing to any writes, preview what `/setup-agents` would generate:

```bash
/ceos-agents:setup-agents --dry-run
```

Output (no files written):
```
[setup-agents] DRY RUN — no files will be written

Planned writes:
  customization/analyst.toml     (NEW) — Python project heuristic
  customization/fixer.toml       (NEW) — Python project + mypy
  customization/test-engineer.toml (NEW) — pytest detected

Total: 3 files would be written.
Run without --dry-run to apply.
```

---

### Example 5: Resetting Customizations

To reset all generated overlays to current heuristics after a major refactor:

```bash
# Option A: delete generated files and re-run
rm customization/analyst.toml customization/fixer.toml customization/test-engineer.toml
/ceos-agents:setup-agents

# Option B: keep user-edited files, only regenerate generated ones
/ceos-agents:setup-agents        # user-edited files are auto-skipped

# Option C: force overwrite everything (with backups)
/ceos-agents:setup-agents --force --yolo
# Creates .bak-{ISO-8601} backups for user-edited files, then regenerates all
```

---

## Troubleshooting

### `[WARN] User-edited overlay ... preserved`

The file exists without a `# generated:` header — it was manually edited (or created manually).
The skill will not overwrite it without `--force`.

**Fix:** Either pass `--force` to overwrite (a `.bak` backup is created automatically), or
keep the file as-is (manual edits are preserved by design).

### `[ERROR] TOML overlay validation failed for {agent}`

A **pre-existing** `customization/{agent}.toml` file has a TOML syntax error. `/setup-agents`
will fail if it attempts to read the file for diff generation.

**Fix:** Validate the TOML manually (`python3 -c "import tomllib; tomllib.load(open('{file}','rb'))"`),
fix the error, then re-run.

### `[ERROR] Symlink escape detected`

A symlink inside `customization/` points outside the directory.

**Fix:** Remove or retarget the symlink. `/setup-agents` will never follow escaping symlinks.

### `[WARN] Symlink escape detection skipped: python3 os.path.realpath unavailable`

`python3` is not installed. The symlink guard is skipped (non-fatal).

**Fix:** Install Python 3 to enable the guard. The pipeline continues without it, but symlink
escape detection is disabled for this run.

### File written but agent does not pick up the overlay

Verify that:
1. The file is at `{project_root}/customization/{agent}.toml` (not a subdirectory).
2. The agent name matches one of the 17 canonical names (e.g., `analyst`, not its prior alias).
3. The TOML parses cleanly (see "TOML validation failed" above).
4. The dispatching skill reads overlays at dispatch time (see `core/overlay/toml-overlay.md`).

### Conflict: both `.md` and `.toml` exist for the same agent

If a legacy v7 `customization/{agent}.md` and a new `customization/{agent}.toml` both exist,
the `.toml` takes precedence and a warning is emitted:

```
[WARN] Legacy .md overlay ignored; .toml takes precedence (deprecate v9.0.0)
```

**Fix:** Remove the `.md` file or migrate it to TOML format manually following [migration-v7-to-v8.md](migration-v7-to-v8.md). The `/migrate-config` skill was removed in v9.5.0.

---

## Related Documentation

- `docs/guides/toml-overlay-syntax.md` — TOML overlay format, 3-tier merge rules, per-agent
  key reference table
- `core/overlay/toml-overlay.md` — contract specification (authoritative)
- `docs/guides/migration-v7-to-v8.md` — migration guide including legacy `.md` → `.toml`
  conversion
- `skills/setup-agents/SKILL.md` — full skill definition with step-by-step implementation
