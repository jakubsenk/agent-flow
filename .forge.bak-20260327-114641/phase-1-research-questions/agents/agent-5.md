# Agent 5 Research: Area 6 — Version, Changelog, and Test Infrastructure

**Research angle:** Version management, changelog format, and test infrastructure as they relate to scaffold infrastructure redesign.

---

## Q25: Current version in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`

Both files report the same version:

**`.claude-plugin/plugin.json`** — `"version": "5.4.1"`
**`.claude-plugin/marketplace.json`** — `"version": "5.4.1"`

The two files are kept in sync manually. `plugin.json` contains the canonical version field alongside `name`, `description`, `author`, `repository`, and `license`. `marketplace.json` nests the same version under `plugins[0].version`.

---

## Q26: CHANGELOG.md format for MINOR releases

The file follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) with Semantic Versioning. From the first 100 lines:

**Most recent MINOR entry:**

```
## [5.3.0] — 2026-03-27

**MINOR** — scaffold-to-deployment workflow: auto-finalize, config validity gate, status readiness,
feature from chat, local deployment verification. No breaking changes.

### Added
- **<Feature name (bold)>:** <description with specifics on files/agents/keys affected>
...

### Changed
- **<Item name (bold)>:** <description of behavior change>
...

### Details
- 19 agents (was 18): +deployment-verifier
- 25 commands (was 24): +check-deploy
- 14 optional config sections (was 13): +Local Deployment
- 27 tests pass (20 existing + 7 forge structural)
- Phase 8 verification: security 0.72, correctness 0.90, spec-alignment 0.93, robustness 0.70
- Deferred to roadmap: forge bridge, standalone machine, scaffold --extend, batch features
```

**MINOR entry structure:**
1. `## [X.Y.0] — YYYY-MM-DD` header
2. Bold severity + one-line summary with "No breaking changes." trailer
3. `### Added` section — bulleted, each item bolded, includes affected file paths/agent names/config keys
4. `### Changed` section (when applicable) — same format
5. `### Fixed` section (when applicable)
6. `### Details` section — counts of agents/commands/config sections, test counts, optional forge verification scores, deferred items

---

## Q27: Scaffold-related test files in `tests/`

Four scaffold-specific test scenarios exist under `tests/scenarios/`:

### `scaffold-v2-happy-path.sh`
**Purpose:** Full pipeline happy path for scaffold v2.

**Validates:**
- Agent files `agents/spec-writer.md` and `agents/spec-reviewer.md` exist
- Both agents use `model: opus` in frontmatter
- `commands/scaffold.md` contains all 10 pipeline steps: Mode Selection, spec-writer reference, spec-reviewer reference, "architect agent", "Feature Implementation Loop", "E2E Tests", "Final Report"
- Three interaction modes present: "Interactive", "YOLO with checkpoint", "Full YOLO"

**Validation mechanism:** `grep -q` pattern matching on file contents; exits 1 on any missing element.

---

### `scaffold-v2-input-conflicts.sh`
**Purpose:** Validates mutually exclusive flag handling.

**Validates:**
- Error message "Only one input source allowed" exists in `commands/scaffold.md`
- Error message "--no-implement skips specification phase" exists
- All four input flags documented: `--template`, `--spec`, `--issue`, `--no-implement`
- All four tech stack flags present: `--lang`, `--framework`, `--db`, `--ci`

**Validation mechanism:** `grep -qF` flag presence checks.

---

### `scaffold-v2-no-implement.sh`
**Purpose:** Backwards compatibility — `--no-implement` must produce v3.x behavior.

**Validates:**
- `--no-implement` flag documented in `commands/scaffold.md`
- "Legacy Flow" section exists for `--no-implement` path
- Legacy flow references `stack-selector` (not `spec-writer`)
- "EXIT pipeline" marker present (pipeline exits before spec phase)
- Legacy report contains "Create issues in your issue tracker" (v3.x next-steps text)

**Validation mechanism:** `grep -q` pattern matching.

---

### `scaffold-v2-spec-loop.sh`
**Purpose:** Validates spec-writer/spec-reviewer iteration loop mechanics.

**Validates:**
- `agents/spec-writer.md` contains "Pipeline Block" (Block Comment Template)
- `agents/spec-reviewer.md` contains "APPROVE" verdict
- `agents/spec-reviewer.md` contains "REVISE" verdict
- `commands/scaffold.md` references "Spec iterations"
- `commands/scaffold.md` contains "spec-writer.*spec-reviewer loop" (regex)
- `commands/scaffold.md` handles "max_iterations exhausted"
- `CLAUDE.md` contains "Spec iterations" in Retry Limits section

**Validation mechanism:** Mix of `grep -q` and `grep -q` regex patterns.

---

## Q28: Test harness structure (`tests/harness/run-tests.sh`)

### Structure overview

```
tests/
  harness/
    run-tests.sh          # Main test runner
    mock-mcp-server.sh    # MCP mock helper
    fixtures/
      automation-config.md  # Sample Automation Config for tests
      issues.json           # Mock issue data
  scenarios/              # 19 individual .sh test files
  mock-project/           # Mock project with CLAUDE.md and app.py
```

### How tests are run

**Invocation:**
- `./tests/harness/run-tests.sh` — runs all scenarios
- `./tests/harness/run-tests.sh <scenario-name>` — runs a single named scenario (without `.sh`)

**Execution model:**
1. Runner iterates over all `tests/scenarios/*.sh` files
2. Each scenario runs via `bash "$scenario"` with stdout/stderr suppressed (`> /dev/null 2>&1`) in batch mode
3. Exit codes determine outcome:
   - `0` → PASS
   - `77` → SKIP (special sentinel, not counted as failure)
   - Any other non-zero → FAIL

**Validation approach:**
- Tests are pure bash scripts using `set -e` (fail on first error)
- Validation is done via `grep -q` / `grep -qF` pattern matching against actual plugin source files (no runtime execution of plugin logic)
- Tests verify structural integrity: file existence, frontmatter values, command keyword presence, agent cross-references
- No mocking of Claude API — tests check the markdown definitions themselves
- Tests are static analysis of the markdown corpus

**Summary output format:**
```
=== Test Results ===
  PASS: scaffold-v2-happy-path
  PASS: scaffold-v2-input-conflicts
  ...
Total: 19 | Pass: 19 | Fail: 0 | Skip: 0
```

Runner exits with code 1 if any FAIL; exits 0 otherwise.

**Total scenarios at v5.3.0:** 27 tests (20 scenarios + 7 forge structural, per CHANGELOG). Current scenario directory contains 19 `.sh` files directly under `tests/scenarios/`.

---

## Key Findings for Scaffold Infrastructure Redesign

1. **Version impact:** Any new required key in Automation Config = MAJOR bump. New optional scaffold flags/sections = MINOR. Behavior fixes = PATCH. Current version is 5.4.1.

2. **Test coverage is structural, not behavioral:** All 4 scaffold tests validate markdown text patterns in `commands/scaffold.md` and `agents/spec-writer.md` / `agents/spec-reviewer.md`. Any redesign must preserve the exact grep patterns these tests check, or update the tests in tandem.

3. **Critical grep anchors in scaffold tests** (must not be broken without updating tests):
   - `"Mode Selection"` in scaffold.md
   - `"Feature Implementation Loop"` in scaffold.md
   - `"E2E Tests"` in scaffold.md
   - `"Final Report"` in scaffold.md
   - `"Interactive"`, `"YOLO with checkpoint"`, `"Full YOLO"` in scaffold.md
   - `"Only one input source allowed"` in scaffold.md
   - `"--no-implement skips specification phase"` in scaffold.md
   - `"Legacy Flow"` in scaffold.md
   - `"EXIT pipeline"` in scaffold.md
   - `"Create issues in your issue tracker"` in scaffold.md
   - `"Spec iterations"` in scaffold.md and CLAUDE.md
   - `"spec-writer.*spec-reviewer loop"` (regex) in scaffold.md
   - `"max_iterations exhausted"` in scaffold.md
   - `"Pipeline Block"` in spec-writer.md
   - `"APPROVE"` and `"REVISE"` in spec-reviewer.md
   - `model: opus` in spec-writer.md and spec-reviewer.md

4. **CHANGELOG Details section convention:** After any version touching scaffold, the Details section must update agent count, command count, optional config section count, and test pass count.
