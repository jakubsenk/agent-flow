# Agent 5: Test Infrastructure & Versioning Research

**Investigator:** Meticulous Codebase Analyst
**Scope:** Scaffold redesign — test assertions, version files, CLAUDE.md scaffold section

---

## Part 1: Test Files — Complete Grep Assertion Inventory

### File: `tests/scenarios/scaffold-v2-happy-path.sh`

**All grep assertions (grep -q lines):**

```bash
# Line 19 — agent frontmatter check (runs for spec-writer and spec-reviewer)
grep -q "^model: opus$" "$REPO_ROOT/agents/$agent.md"

# Line 29 — Step 0: Mode selection
grep -q "Mode Selection" "$SCAFFOLD_CMD"

# Line 35 — Step 1: spec-writer reference
grep -q "spec-writer" "$SCAFFOLD_CMD"

# Line 41 — Step 1: spec-reviewer reference
grep -q "spec-reviewer" "$SCAFFOLD_CMD"

# Line 47 — Step 5: Architecture
grep -q "architect agent" "$SCAFFOLD_CMD"

# Line 53 — Step 7: Feature Implementation Loop
grep -q "Feature Implementation Loop" "$SCAFFOLD_CMD"

# Line 59 — Step 8: E2E Tests
grep -q "E2E Tests" "$SCAFFOLD_CMD"

# Line 65 — Step 10: Final Report
grep -q "Final Report" "$SCAFFOLD_CMD"

# Line 71 — Mode: Interactive
grep -q "Interactive" "$SCAFFOLD_CMD"

# Line 75 — Mode: YOLO with checkpoint
grep -q "YOLO with checkpoint" "$SCAFFOLD_CMD"

# Line 79 — Mode: Full YOLO
grep -q "Full YOLO" "$SCAFFOLD_CMD"
```

**Assertions referencing steps being REMOVED (4b, 4c, 9):**
- None of the assertions in this file explicitly reference steps 4b, 4c, or 9 by name.
- However, `grep -q "E2E Tests"` (line 59, Step 8) and step numbering context may shift if step 9 is removed and renumbered.

**Assertions needing to be ADDED for new steps (0-INFRA, 0-MCP, 4d, 4e):**
- No assertion for `0-INFRA` (infrastructure/tooling preflight)
- No assertion for `0-MCP` (MCP availability check)
- No assertion for `4d`
- No assertion for `4e`

**Assertions that will BREAK after redesign:**
- `grep -q "Feature Implementation Loop"` — will break if the step heading is renamed
- `grep -q "E2E Tests"` — will break if renumbered or renamed as part of step 9 removal
- `grep -q "Final Report"` — will break if Step 10 is renumbered due to step removals

---

### File: `tests/scenarios/scaffold-v2-input-conflicts.sh`

**All grep assertions (grep -q lines):**

```bash
# Line 11 — mutual exclusion error message
grep -q "Only one input source allowed" "$SCAFFOLD_CMD"

# Line 17 — --no-implement conflict
grep -q "\-\-no-implement skips specification phase" "$SCAFFOLD_CMD"

# Lines 23-28 — flag presence loop (uses grep -qF)
grep -qF -- "--$flag" "$SCAFFOLD_CMD"   # for flag in: template spec issue no-implement

# Lines 31-35 — tech stack flags loop (uses grep -qF)
grep -qF -- "--$flag" "$SCAFFOLD_CMD"   # for flag in: lang framework db ci
```

**Assertions referencing steps being REMOVED (4b, 4c, 9):**
- None explicitly reference removed steps by number.
- `grep -q "\-\-no-implement skips specification phase"` — depends on the exact error text remaining unchanged.

**Assertions needing to be ADDED for new steps (0-INFRA, 0-MCP, 4d, 4e):**
- No assertions cover new flags or error messages related to 0-INFRA, 0-MCP, 4d, 4e.

**Assertions that will BREAK after redesign:**
- `grep -q "\-\-no-implement skips specification phase"` — will break if the conflict error message text changes.
- `grep -q "Only one input source allowed"` — will break if the mutual exclusion message is reworded.

---

### File: `tests/scenarios/scaffold-v2-no-implement.sh`

**All grep assertions (grep -q lines):**

```bash
# Line 11 — --no-implement flag documented
grep -q "\-\-no-implement" "$SCAFFOLD_CMD"

# Line 17 — legacy flow section present
grep -q "Legacy Flow" "$SCAFFOLD_CMD"

# Line 23 — legacy flow uses stack-selector
grep -q "stack-selector" "$SCAFFOLD_CMD"

# Line 34 — EXIT pipeline before spec phase
grep -q "EXIT pipeline" "$SCAFFOLD_CMD"

# Line 40 — legacy report: v3.x next steps
grep -q "Create issues in your issue tracker" "$SCAFFOLD_CMD"
```

**Assertions referencing steps being REMOVED (4b, 4c, 9):**
- None of the assertions in this file explicitly reference steps 4b, 4c, or 9 by step label.
- The legacy flow section (`grep -q "Legacy Flow"`) is implicitly tied to the `--no-implement` bypass which skips the entire v2 pipeline including steps 4b/4c/9. If the legacy flow section heading is renamed, this assertion breaks.

**Assertions needing to be ADDED for new steps (0-INFRA, 0-MCP, 4d, 4e):**
- No assertions for new preflight steps (0-INFRA, 0-MCP) in `--no-implement` path.
- No assertions for whether 0-INFRA/0-MCP are skipped or executed in legacy flow.

**Assertions that will BREAK after redesign:**
- `grep -q "Legacy Flow"` — will break if the legacy section heading is renamed.
- `grep -q "EXIT pipeline"` — will break if the early-exit wording changes.
- `grep -q "Create issues in your issue tracker"` — will break if the legacy report next-steps text changes.

---

### File: `tests/scenarios/scaffold-v2-spec-loop.sh`

**All grep assertions (grep -q lines):**

```bash
# Line 13 — spec-writer has Pipeline Block template
grep -q "Pipeline Block" "$SPEC_WRITER"

# Line 19 — spec-reviewer has APPROVE verdict
grep -q "APPROVE" "$SPEC_REVIEWER"

# Line 23 — spec-reviewer has REVISE verdict
grep -q "REVISE" "$SPEC_REVIEWER"

# Line 29 — scaffold command references Spec iterations
grep -q "Spec iterations" "$SCAFFOLD_CMD"

# Line 35 — spec-writer/spec-reviewer loop defined
grep -q "spec-writer.*spec-reviewer loop" "$SCAFFOLD_CMD"

# Line 41 — max_iterations exhaustion handling
grep -q "max_iterations exhausted" "$SCAFFOLD_CMD"

# Line 47 — CLAUDE.md has Spec iterations in Retry Limits
grep -q "Spec iterations" "$REPO_ROOT/CLAUDE.md"
```

**Assertions referencing steps being REMOVED (4b, 4c, 9):**
- None explicitly reference steps 4b, 4c, or 9.
- `grep -q "spec-writer.*spec-reviewer loop"` uses a regex pattern — will break if the loop description wording changes even slightly (e.g., step renumbering changes surrounding text).

**Assertions needing to be ADDED for new steps (0-INFRA, 0-MCP, 4d, 4e):**
- No assertions cover 0-INFRA, 0-MCP, 4d, or 4e loop mechanics.

**Assertions that will BREAK after redesign:**
- `grep -q "spec-writer.*spec-reviewer loop"` — regex pattern; will break if the exact phrase "spec-writer" and "spec-reviewer loop" no longer appear on the same line in scaffold.md.
- `grep -q "max_iterations exhausted"` — will break if the exhaustion handling text changes.
- `grep -q "Spec iterations" "$SCAFFOLD_CMD"` — will break if the config key reference is renamed.

---

### File: `tests/harness/run-tests.sh`

**All grep assertions (grep -q lines):**
- None. The harness uses no `grep -q` assertions directly.
- It runs bash scripts from `$SCENARIOS_DIR/*.sh` and checks their exit codes.
- Exit code 0 = PASS, exit code 77 = SKIP, any other non-zero = FAIL.
- No hardcoded scenario names — discovers all `*.sh` files in `tests/scenarios/`.

**Harness behavior notes relevant to redesign:**
- Adding new scenario files (e.g., `scaffold-v2-infra-steps.sh`) is automatically picked up.
- Renaming scenario files does NOT require harness changes.
- The harness summary line is: `Total: $((PASS + FAIL + SKIP)) | Pass: $PASS | Fail: $FAIL | Skip: $SKIP`

---

## Summary: Assertion Impact Matrix

| Assertion | File | Will Break? | Reason |
|-----------|------|-------------|--------|
| `grep -q "Mode Selection"` | happy-path | No | Step 0 stays |
| `grep -q "spec-writer"` | happy-path | No | Agent stays |
| `grep -q "spec-reviewer"` | happy-path | No | Agent stays |
| `grep -q "architect agent"` | happy-path | No | Step 5 stays |
| `grep -q "Feature Implementation Loop"` | happy-path | **Possible** | If heading renamed |
| `grep -q "E2E Tests"` | happy-path | **Possible** | If step 8 renumbered/renamed |
| `grep -q "Final Report"` | happy-path | **Possible** | If step 10 renumbered |
| `grep -q "YOLO with checkpoint"` | happy-path | No | Mode stays |
| `grep -q "Full YOLO"` | happy-path | No | Mode stays |
| `grep -q "Only one input source allowed"` | input-conflicts | **Possible** | Text-dependent |
| `grep -q "\-\-no-implement skips specification phase"` | input-conflicts | **Possible** | Text-dependent |
| `grep -qF -- "--template"` etc. | input-conflicts | No | Flags stay |
| `grep -q "Legacy Flow"` | no-implement | **Possible** | Heading rename |
| `grep -q "EXIT pipeline"` | no-implement | **Possible** | Wording change |
| `grep -q "Create issues in your issue tracker"` | no-implement | **Possible** | Text-dependent |
| `grep -q "Pipeline Block"` | spec-loop | No | Template stays |
| `grep -q "APPROVE"` | spec-loop | No | Verdict stays |
| `grep -q "REVISE"` | spec-loop | No | Verdict stays |
| `grep -q "Spec iterations" (scaffold.md)` | spec-loop | No | Config key stays |
| `grep -q "spec-writer.*spec-reviewer loop"` | spec-loop | **Yes** | Regex; text-sensitive |
| `grep -q "max_iterations exhausted"` | spec-loop | **Possible** | Text-dependent |
| `grep -q "Spec iterations" (CLAUDE.md)` | spec-loop | No | Config key stays |

**Assertions to ADD for new steps:**
- `grep -q "0-INFRA"` or `grep -q "Infrastructure Preflight"` in scaffold.md
- `grep -q "0-MCP"` or `grep -q "MCP Availability"` in scaffold.md
- `grep -q "4d"` or relevant step-4d heading in scaffold.md
- `grep -q "4e"` or relevant step-4e heading in scaffold.md
- Assertions verifying 0-INFRA/0-MCP are skipped in `--no-implement` legacy path

---

## Part 2: Version Files

### `.claude-plugin/plugin.json` — current version

```json
{
  "name": "ceos-agents",
  "description": "CEOS CLAUDE Agents — development automation: bug-fix, feature pipeline, scaffold, decomposition, dashboard",
  "version": "5.4.1",
  "author": {
    "name": "Filip Sabacky"
  },
  "repository": "https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git",
  "license": "UNLICENSED"
}
```

**Current version: `5.4.1`**

---

### `.claude-plugin/marketplace.json` — current version

```json
{
  "name": "ceos-agents",
  "owner": {
    "name": "Filip Sabacky"
  },
  "plugins": [
    {
      "name": "ceos-agents",
      "source": "./",
      "description": "CEOS CLAUDE Agents — development automation: bug-fix, feature pipeline, scaffold, decomposition, dashboard",
      "version": "5.4.1"
    }
  ]
}
```

**Current version: `5.4.1`** (matches plugin.json)

---

### `CHANGELOG.md` — Format Reference (first 150 lines)

The changelog follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) with Semantic Versioning.

**Entry format pattern:**

```markdown
## [X.Y.Z] — YYYY-MM-DD

**PATCH/MINOR/MAJOR** — one-line summary. No breaking changes. / Breaking changes in X.

### Added
- **Feature name (component):** Description. Sub-bullets for details.

### Changed
- **What changed:** Description.

### Fixed
- **What was fixed:** Description.

### Details
- Count lines (e.g., "19 agents (unchanged), 25 commands (unchanged)")
- Contributor attribution
- Phase verification scores (for forge-built features)
```

**Most recent entry header:** `## [5.4.1] — 2026-03-26`

**Version bump target for scaffold redesign:**
- The scaffold pipeline changes (new steps 0-INFRA, 0-MCP, 4d, 4e; removal of steps 4b, 4c, 9) are behavior changes to an existing command.
- Steps 4b/4c removal changes observable scaffold behavior (no more interactive tracker configuration during scaffold).
- If these are pipeline behavior changes without new required config keys: **MINOR** bump → `5.5.0`.
- If any new required Automation Config key is introduced: **MAJOR** bump → `6.0.0`.

---

## Part 3: CLAUDE.md Scaffold Pipeline Section

The exact Scaffold Pipeline section from `CLAUDE.md` (lines 63–77):

```markdown
## Scaffold Pipeline

```
User description → [Mode selection] → SPEC-WRITER ↔ SPEC-REVIEWER (opus)
  → [Spec checkpoint] → SCAFFOLDER (sonnet, +test infrastructure, +scorecard)
  → Validate → Git init
  → ARCHITECT (opus, +maps_to) → [Feature plan checkpoint]
  → FIXER ↔ REVIEWER (opus) → TEST ENGINEER (sonnet)
  → [Spec compliance check (spec-reviewer --verify)]
  → E2E-TEST-ENGINEER (sonnet) → Final report
```

With `--no-implement`: `STACK-SELECTOR (sonnet) → SCAFFOLDER (sonnet) → Validate → Git init` (v3.x behavior).

In scaffold v2 mode, the specification is saved as a `spec/` folder in the project root (spec/README.md, spec/architecture.md, spec/verification.md, spec/epics/*.md). This folder is the single source of truth for all downstream agents.
```

**What needs updating in this section for the redesign:**

1. **New preflight steps (0-INFRA, 0-MCP):** The pipeline diagram must show infrastructure/MCP preflight before Mode selection.
2. **Steps 4b/4c removal:** The interactive tracker configuration steps are removed; the pipeline diagram does not explicitly show them, but the prose description and the scaffold.md command detail them. CLAUDE.md pipeline diagram does not currently show 4b/4c explicitly — no change needed to diagram for this removal.
3. **Step 9 removal (if step 9 = Spec compliance check):** The `[Spec compliance check (spec-reviewer --verify)]` line would be removed from the pipeline diagram.
4. **New steps 4d/4e:** If these are between Scaffolder and Architect, they need to be added to the pipeline diagram.
5. **Updated `--no-implement` note:** If 0-INFRA/0-MCP run even in legacy mode, the `--no-implement` shorthand description needs updating.

**Proposed updated pipeline diagram (draft):**

```
[0-INFRA preflight] → [0-MCP check] → User description → [Mode selection]
  → SPEC-WRITER ↔ SPEC-REVIEWER (opus) → [Spec checkpoint]
  → SCAFFOLDER (sonnet, +test infrastructure, +scorecard)
  → [4d: ...] → [4e: ...] → Validate → Git init
  → ARCHITECT (opus, +maps_to) → [Feature plan checkpoint]
  → FIXER ↔ REVIEWER (opus) → TEST ENGINEER (sonnet)
  → E2E-TEST-ENGINEER (sonnet) → Final report
```

(Exact 4d/4e labels depend on the design spec — fill in from the plan document.)

---

## Key Findings Summary

1. **Current version:** `5.4.1` in both `plugin.json` and `marketplace.json`.
2. **Version bump needed:** MINOR (`5.5.0`) minimum for scaffold pipeline changes; MAJOR (`6.0.0`) if new required config keys are introduced.
3. **Test assertions at risk:** 7 assertions are "possible break" and 1 (`spec-writer.*spec-reviewer loop`) is a confirmed break risk due to regex text sensitivity.
4. **No existing assertions** cover steps 0-INFRA, 0-MCP, 4d, or 4e — these need new test assertions.
5. **CLAUDE.md scaffold section** explicitly shows `[Spec compliance check (spec-reviewer --verify)]` — this is the step 9 candidate for removal; it must be deleted from the pipeline diagram.
6. **The harness (`run-tests.sh`) requires zero changes** — it auto-discovers scenario files.
7. **Changelog format:** MINOR entry with `### Added`, `### Changed`, `### Removed` subsections; details line must reflect updated agent/command counts.
