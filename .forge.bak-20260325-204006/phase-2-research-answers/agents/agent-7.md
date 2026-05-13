# Research Answer 7: Test Suite Detailed Analysis

## Test Runner Framework

**File:** `tests/harness/run-tests.sh`

**Discovery mechanism (lines 35–55):** The runner uses a glob `"$SCENARIOS_DIR"/*.sh` to discover all `.sh` files in `tests/scenarios/`. There is no explicit test manifest — any `.sh` file dropped into `tests/scenarios/` is automatically picked up.

**Execution model:** Each scenario is executed as a separate bash subprocess via `bash "$scenario" > /dev/null 2>&1` (line 39). Standard output and stderr from scenarios are fully suppressed in batch mode; they are only visible when running a single named scenario (`./run-tests.sh scenario-name`, line 25 — output not redirected).

**Exit code protocol:**
- Exit 0 = PASS
- Exit 77 = SKIP (special code, line 45)
- Any other non-zero exit = FAIL

**Reporting:** Results are accumulated in a `RESULTS` array and printed after all tests run. The runner exits 1 if any FAIL occurred (line 67).

**Single-scenario mode (lines 18–32):** When `$1` is provided, the runner runs only that file (without `.sh` extension), prints PASS/FAIL directly, and exits with the scenario's exit code. Output is **not** suppressed in this mode.

**Notable:** The runner uses `set -uo pipefail` (line 5), but individual scenarios control their own `set -e`. No setup/teardown hooks exist. No test fixtures are auto-injected — scenarios must reference `REPO_ROOT` themselves.

---

## Test Scenario Inventory

### Scenario 1: happy-path.sh

- **What it validates:** Exhaustive file existence check for all 24 command files and all 18 agent files. Every file in `commands/` and `agents/` is verified to exist at its expected path.
- **Hardcoded references:**
  - Line 9–12: Exact list of 24 command names: `analyze-bug fix-ticket fix-bugs create-pr publish version-bump check-setup resume-ticket status onboard changelog version-check implement-feature scaffold scaffold-add scaffold-validate dashboard metrics estimate prioritize migrate-config template discuss init`
  - Line 20–24: Exact list of 18 agent names: `triage-analyst code-analyst fixer reviewer test-engineer e2e-test-engineer publisher rollback-agent spec-analyst architect stack-selector scaffolder priority-engine spec-writer spec-reviewer acceptance-gate reproducer browser-verifier`
- **Migration impact:** CRITICAL — any rename or addition of a command or agent file breaks this test. If a file is renamed (e.g., `triage-analyst` → `issue-analyst`), the test fails on the old name and silently does not check the new name.
- **Fragility assessment:** Extremely fragile to structural migration. Adding a new command/agent requires manually updating both lists. The test gives false confidence: it only checks existence, not content validity or correct wiring.

---

### Scenario 2: triage-block.sh

- **What it validates:** That `agents/triage-analyst.md` exists and contains either the string `"Block Comment Template"` or `"Pipeline Block"` (line 12).
- **Hardcoded references:**
  - Line 6: `AGENT_FILE="$REPO_ROOT/agents/triage-analyst.md"` — hardcoded filename.
  - Line 12: Search strings `"Block Comment Template"` and `"Pipeline Block"`.
- **Migration impact:** LOW — the agent file path is the only hardcoded element. If `triage-analyst.md` is renamed, this breaks; otherwise the pattern search is flexible.
- **Fragility assessment:** Minimal. The pattern check is broad (either string matches). Stable against content reformatting as long as both strings don't disappear simultaneously.

---

### Scenario 3: fixer-retry.sh

- **What it validates:** Two things about `agents/fixer.md`: (a) it contains at least one of the words `"iteration"`, `"retry"`, or `"attempt"` (line 11); (b) the first 5 lines of the file contain `"model: opus"` (line 19).
- **Hardcoded references:**
  - Line 6: `AGENT_FILE="$REPO_ROOT/agents/fixer.md"` — hardcoded filename.
  - Line 19: `head -5 "$AGENT_FILE"` — assumes `model:` field appears in first 5 lines of frontmatter.
- **Migration impact:** LOW — pattern searches are broad. Model check using `head -5` depends on frontmatter being at the top (standard YAML frontmatter convention).
- **Fragility assessment:** Stable. The `head -5` assumption could break only if the YAML frontmatter preamble (`---`) shifts the `model:` line beyond line 5. Currently frontmatter is: `---` (line 1), `name:` (line 2), `description:` (line 3), `model:` (line 4), `style:` (line 5), `---` (line 6) — so `model:` is within the first 5 lines. Adding a new frontmatter field before `model:` would silently fail.

---

### Scenario 4: reviewer-reject.sh

- **What it validates:** That `agents/reviewer.md` contains both `"APPROVE"` and `"REQUEST_CHANGES"` as literal strings.
- **Hardcoded references:**
  - Line 6: `AGENT_FILE="$REPO_ROOT/agents/reviewer.md"` — hardcoded filename.
  - Lines 10–11: Literal strings `"APPROVE"` and `"REQUEST_CHANGES"`.
- **Migration impact:** LOW — file path only. Pattern strings are stable output vocabulary.
- **Fragility assessment:** Minimal. These are reviewer output contract terms; unlikely to change without a version bump.

---

### Scenario 5: test-fail.sh

- **What it validates:** That `agents/test-engineer.md` contains either `"NEVER"` or `"Constraint"` (line 10) — indicating that constraints section exists.
- **Hardcoded references:**
  - Line 6: `AGENT_FILE="$REPO_ROOT/agents/test-engineer.md"` — hardcoded filename.
  - Line 10: Search strings `"NEVER"` and `"Constraint"`.
- **Migration impact:** LOW — file path only.
- **Fragility assessment:** Very weak test — `"NEVER"` appears in virtually any agent file that follows the standard format (all Constraints sections start with NEVER). This test would pass even if the test-engineer file had completely wrong content. Effectively only validates the file exists and has _something_ in it.

---

### Scenario 6: publish-success.sh

- **What it validates:** Two things about `agents/publisher.md`: (a) it contains a "never push to main" constraint matching the regex `"NEVER.*main|NEVER.*push.*main|never push.*main"` (line 10); (b) the first 5 lines contain `"model: haiku"` (line 17).
- **Hardcoded references:**
  - Line 6: `AGENT_FILE="$REPO_ROOT/agents/publisher.md"` — hardcoded filename.
  - Line 17: `head -5 "$AGENT_FILE"` — same `head -5` assumption as fixer-retry.sh.
- **Migration impact:** LOW — file path only. Same frontmatter ordering assumption as fixer-retry.sh.
- **Fragility assessment:** Stable for same reasons as fixer-retry.sh.

---

### Scenario 7: verify-fail.sh

- **What it validates:** That "Fix Verification" and "Feature Verification" sections exist in three command files, with specific step number anchors:
  - `fix-ticket.md` must contain `"9d. Fix Verification"` OR `"Fix Verification"` (line 8)
  - `fix-bugs.md` must contain `"8c. Fix Verification"` OR `"Fix Verification"` (line 16)
  - `implement-feature.md` must contain `"10b. Feature Verification"` OR `"Feature Verification"` (line 24)
- **Hardcoded references:**
  - Line 8: Step ID `"9d"` for fix-ticket Fix Verification.
  - Line 16: Step ID `"8c"` for fix-bugs Fix Verification.
  - Line 24: Step ID `"10b"` for implement-feature Feature Verification.
  - File paths: `commands/fix-ticket.md`, `commands/fix-bugs.md`, `commands/implement-feature.md`.
- **Current state (verified):** All three anchors are currently valid — `fix-ticket.md` has `### 9d. Fix Verification (optional)` at line 324, `fix-bugs.md` has `### 8c. Fix Verification (optional, per-bug)` at line 306, `implement-feature.md` has `### 10b. Feature Verification (optional)` at line 268.
- **Migration impact:** HIGH — any renumbering of pipeline steps in these three commands will break the specific step-ID checks. The OR fallback (`"Fix Verification"` without step number) provides partial resilience — if the step ID changes but the word "Fix Verification" remains, the test still passes. However, if the step is renamed (e.g., to "Verification" or "Post-Publish Verification"), both clauses fail.
- **Fragility assessment:** Moderately fragile. The step-number half of each OR clause is already redundant (the bare string check covers it), so renumbering alone is safe. But a rename of the verification concept itself, or splitting the step, would break the test.

---

### Scenario 8: profile-skip.sh

- **What it validates:** For each of `fix-ticket.md`, `fix-bugs.md`, `implement-feature.md`: (a) either `"Pipeline profile parsing"` or `"--profile"` appears (line 11); (b) `"NEVER.*skip"` appears (line 18).
- **Hardcoded references:**
  - Line 7: Hardcoded list `fix-ticket fix-bugs implement-feature`.
  - Lines 11, 18: Pattern strings.
- **Migration impact:** LOW — only if a new pipeline command that also supports profiles is added but not included in the hardcoded list.
- **Fragility assessment:** Stable. Both pattern checks use broad matches. The NEVER skip check (`NEVER.*skip`) would match any NEVER-prefixed constraint mentioning skipping.

---

### Scenario 9: pipeline-consistency.sh

- **What it validates:** Five cross-cutting patterns across the four pipeline command files (`fix-ticket.md`, `fix-bugs.md`, `implement-feature.md`, `scaffold.md`):
  1. Block comment format includes `🔴` emoji (lines 17–26)
  2. No `git add .` outside of `git init` sections (lines 29–46)
  3. Commands calling fixer reference "build retries"; commands calling reviewer reference "fixer iterations"; commands calling test-engineer reference "test attempts" (lines 49–67)
  4. Any `rm -rf $SCAFFOLD_TEMP` is accompanied by `"DO NOT run rm -rf"` safety check (lines 70–77)
  5. Any reference to `rollback-agent` is accompanied by `"issue tracker"` in the same file (lines 80–87)
- **Hardcoded references:**
  - Line 8: `PIPELINE_FILES="$CMDS/fix-ticket.md $CMDS/fix-bugs.md $CMDS/implement-feature.md $CMDS/scaffold.md"` — exact list of four files.
  - Line 72: Literal `'rm -rf.*SCAFFOLD_TEMP'` — assumes the variable name stays as `SCAFFOLD_TEMP`.
  - Line 73: Literal `'DO NOT run rm -rf'` — assumes this exact safety phrase.
  - Lines 52–53: Patterns `'fixer.*Task tool|Run.*fixer'` and `'build retries'`.
  - Lines 57–58: Patterns `'reviewer.*Task tool|Run.*reviewer'` and `'fixer iterations'`.
  - Lines 62–63: Patterns `'test-engineer.*Task tool|Run.*test-engineer'` and `'test attempts'`.
- **Migration impact:** HIGH — if a fifth pipeline command is added that also runs fixer/reviewer/test loops (e.g., a new `fix-sprint.md`), it is not included in `PIPELINE_FILES` and its consistency is not checked. Conversely, if `scaffold.md` loses its fixer loop, check 5 may produce false passes because scaffold doesn't call rollback-agent's issue tracker path.
- **Fragility assessment:** The file list at line 8 is the primary brittleness point. Check 2 (git add) has a context heuristic using `git init` that could silently misclassify new sections. Check 5 (rollback + issue tracker) is a file-level check, not a structural proximity check, so it can pass even if the instruction is logically disconnected from the rollback call.

---

### Scenario 10: scaffold-v2-happy-path.sh

- **What it validates:** (a) `spec-writer.md` and `spec-reviewer.md` exist; (b) both use `model: opus`; (c) `scaffold.md` contains: "Mode Selection", `spec-writer` reference, `spec-reviewer` reference, `"architect agent"`, `"Feature Implementation Loop"`, `"E2E Tests"`, `"Final Report"`, `"Interactive"`, `"YOLO with checkpoint"`, `"Full YOLO"`.
- **Hardcoded references:**
  - Lines 10, 18: Agent names `spec-writer`, `spec-reviewer`.
  - Lines 29–82: Ten exact string literals that must appear in `scaffold.md`.
  - Line 19: `grep -q "^model: opus$"` — regex anchored to start of line.
- **Migration impact:** MEDIUM — any renaming of scaffold pipeline section headings (e.g., "Feature Implementation Loop" → "Implementation Phase") breaks specific checks. Agent model changes would also break the test.
- **Fragility assessment:** Moderate. The string checks are sufficiently specific that cosmetic rewording of scaffold headings would cause failures. The `^model: opus$` anchor is robust.

---

### Scenario 11: scaffold-v2-input-conflicts.sh

- **What it validates:** That `scaffold.md` contains: (a) `"Only one input source allowed"` exact string; (b) `"--no-implement skips specification phase"` exact string; (c) flags `--template`, `--spec`, `--issue`, `--no-implement`; (d) flags `--lang`, `--framework`, `--db`, `--ci`.
- **Hardcoded references:**
  - Line 11: Exact string `"Only one input source allowed"`.
  - Line 17: Exact string `"--no-implement skips specification phase"`.
  - Lines 23–35: Eight specific flag names.
- **Migration impact:** LOW — content checks, not structure checks. Only breaks if error messages or flag names change.
- **Fragility assessment:** Low fragility. The exact error message strings (lines 11, 17) are the only real risk points — they would break if the error messages are reworded.

---

### Scenario 12: scaffold-v2-no-implement.sh

- **What it validates:** That `scaffold.md` contains: `"--no-implement"`, `"Legacy Flow"`, `"stack-selector"`, `"EXIT pipeline"`, `"Create issues in your issue tracker"`.
- **Hardcoded references:**
  - Lines 11–40: Five exact string literals in `scaffold.md`.
- **Migration impact:** LOW — string content checks. Only breaks on content changes.
- **Fragility assessment:** Low. The phrase `"EXIT pipeline"` is specific enough that if the branching language changes (e.g., to "GOTO legacy mode"), it breaks.

---

### Scenario 13: scaffold-v2-spec-loop.sh

- **What it validates:** (a) `spec-writer.md` has `"Pipeline Block"`; (b) `spec-reviewer.md` has `"APPROVE"` and `"REVISE"`; (c) `scaffold.md` has `"Spec iterations"`, `"spec-writer.*spec-reviewer loop"` (regex), and `"max_iterations exhausted"`; (d) `CLAUDE.md` has `"Spec iterations"`.
- **Hardcoded references:**
  - Lines 9–10: Hardcoded paths for `spec-writer.md`, `spec-reviewer.md`, `scaffold.md`.
  - Line 35: Regex `"spec-writer.*spec-reviewer loop"` — requires specific wording of the loop section.
  - Line 41: Exact string `"max_iterations exhausted"`.
  - Line 47: CLAUDE.md path `$REPO_ROOT/CLAUDE.md`.
- **Migration impact:** MEDIUM — the regex `"spec-writer.*spec-reviewer loop"` (line 35) is brittle: renaming the section from "loop" to "iteration" or "cycle" breaks it.
- **Fragility assessment:** Moderate. The `max_iterations exhausted` check (line 41) is a specific phrase that must not be reworded.

---

### Scenario 14: browser-verification-skip.sh

- **What it validates:** Ten checks spanning new agents and pipeline integration:
  1. `reproducer.md` and `browser-verifier.md` exist
  2. Both have all four frontmatter fields: `name`, `description`, `model`, `style`
  3. Both use `model: sonnet`
  4. `fix-ticket.md` and `fix-bugs.md` contain `"browser_verification_enabled"`
  5. `CLAUDE.md` contains `"Browser Verification"`
  6. `reproducer.md` contains `"NEVER block the pipeline"`
  7. `browser-verifier.md` contains `"NEVER block the pipeline based on Sub-phase B"`
  8. `browser-verifier.md` contains `"On events"`
  9. Both `fix-ticket.md` and `fix-bugs.md` contain `"reproducer.*step"` (regex)
  10. Both `fix-ticket.md` and `fix-bugs.md` contain `"browser-verifier.*step"` (regex)
- **Hardcoded references:**
  - Lines 9, 16, 26: Agent names `reproducer`, `browser-verifier`.
  - Lines 33, 60, 64: Command names `fix-ticket`, `fix-bugs`.
  - Lines 34, 61, 65: Specific string patterns.
  - Line 45: Exact phrase `"NEVER block the pipeline"`.
  - Line 50: Exact phrase `"NEVER block the pipeline based on Sub-phase B"`.
- **Migration impact:** MEDIUM — the stage mapping regex checks (lines 61, 65: `"reproducer.*step"` and `"browser-verifier.*step"`) depend on the pipeline step format using the word "step". If the stage mapping format changes, these fail.
- **Fragility assessment:** Moderate. The two exact NEVER-constraint phrases (lines 45, 50) are highly specific and would break on any reword. The `"On events"` check (line 55) is broad enough to be stable.

---

## Unused Infrastructure

### Mock MCP Server (`tests/harness/mock-mcp-server.sh`)

The mock MCP server is a complete, functional JSON-RPC stdin/stdout server that reads from `tests/harness/fixtures/issues.json` and `tests/harness/fixtures/automation-config.md`. It supports six MCP methods: `issues/list`, `search_issues`, `list_issues`, `issues/get`, `get_issue`, `issues/comment`, `add_issue_comment`, `pulls/create`, `create_pull_request`, `issues/update`, `update_issue`. It also writes a call log to `tests/harness/mcp-log.json`.

**Usage status: COMPLETELY UNUSED.** Zero of the 14 scenario files reference `mock-mcp-server.sh`, source it, or start it as a background process. The server was built for an integration test layer that was never implemented. No scenario file calls `FIXTURES_DIR`, reads from `issues.json` for test purposes, or references `mcp-log.json`.

### Mock Project (`tests/mock-project/`)

The mock project consists of:
- `tests/mock-project/CLAUDE.md` — a complete Automation Config with youtrack tracker, retry limits, hooks, worktrees, feature workflow, decomposition, pipeline profiles, and metrics sections.
- `tests/mock-project/app.py` — a 12-line Python file with two functions that have intentional bugs (no zero-division guard, no empty-string guard).
- `tests/mock-project/tests/test_app.py` — four pytest tests, two of which are designed to fail against the buggy `app.py` (verifying zero division raises `ValueError`, verifying empty name raises `ValueError`).

**Usage status: COMPLETELY UNUSED.** Zero scenario files reference `mock-project/`. The mock project was designed to be the execution target for integration tests that run the actual pipeline agents against real (mock) source code. No scenario currently changes directory into `mock-project/`, runs `pytest`, or imports anything from it. The intentional bugs in `app.py` and the failing tests in `test_app.py` exist solely for a future integration test that was never written.

### Fixtures (`tests/harness/fixtures/`)

- `automation-config.md` — a GitHub-based Automation Config with three pipeline profiles (`fast`, `strict`, `minimal`). Unused by all scenarios.
- `issues.json` — three sample issues (TEST-1, TEST-2, TEST-3) with varying states and labels. Unused by all scenarios (only referenced by `mock-mcp-server.sh` which itself is unused).

---

## Fragile Test Analysis

### happy-path.sh

**Exact hardcoded lists:**

Lines 9–12 — commands list (24 items):
```
analyze-bug fix-ticket fix-bugs create-pr publish version-bump \
check-setup resume-ticket status onboard changelog version-check \
implement-feature scaffold scaffold-add scaffold-validate dashboard \
metrics estimate prioritize migrate-config template discuss init
```

Lines 20–24 — agents list (18 items):
```
triage-analyst code-analyst fixer reviewer test-engineer \
e2e-test-engineer publisher rollback-agent spec-analyst \
architect stack-selector scaffolder priority-engine \
spec-writer spec-reviewer acceptance-gate reproducer browser-verifier
```

**What will break during migration:**
- Any file rename: the old name remains in the hardcoded list (false FAIL) and the new name is not checked (silent gap).
- Adding a new command or agent: the test does not fail, but the new file is not validated until manually added to the list.
- Removing a command or agent without updating the list: the test fails for the removed name even though removal may be intentional.

**What would need to change to make it migration-resilient:**
Replace the static lists with dynamic discovery — generate the expected set from the actual filesystem (`ls commands/*.md | sed 's|.*/||;s|\.md||'`) and compare against the lists in `CLAUDE.md`'s Architecture section, or simply verify that every `.md` file in `commands/` and `agents/` has valid frontmatter. Alternatively, invert the test: glob the actual files and check each has a non-empty, valid-format frontmatter rather than checking a static list.

---

### verify-fail.sh

**Exact step numbers that will break, with line numbers:**

- Line 8: `grep -q "9d\. Fix Verification\|Fix Verification"` — anchored to step ID `9d` in `fix-ticket.md`. Currently valid (step is at line 324 of fix-ticket.md).
- Line 16: `grep -q "8c\. Fix Verification\|Fix Verification"` — anchored to step ID `8c` in `fix-bugs.md`. Currently valid (step is at line 306 of fix-bugs.md).
- Line 24: `grep -q "10b\. Feature Verification\|Feature Verification"` — anchored to step ID `10b` in `implement-feature.md`. Currently valid (step is at line 268 of implement-feature.md).

**What will break during migration:**
Because each `grep` uses a logical OR with the bare section name as the second clause, renumbering steps alone (e.g., `9d` → `10d`) does NOT break the test — the bare `"Fix Verification"` clause still matches. The test only breaks if the section heading is renamed or removed entirely. The specific step-number half of each OR is redundant and provides no additional validation.

**What would need to change:**
The step-number clauses (`"9d\. Fix Verification"`, `"8c\. Fix Verification"`, `"10b\. Feature Verification"`) should either be removed (keeping only the bare section-name check) or converted to document that these are the canonical step IDs. If the intent is to pin the step numbers, the OR fallback defeats that purpose and should be removed. If the intent is only to verify the section exists, the step numbers should be dropped entirely.

---

### pipeline-consistency.sh

**Exact file list that will break, with line numbers:**

- Line 8: `PIPELINE_FILES="$CMDS/fix-ticket.md $CMDS/fix-bugs.md $CMDS/implement-feature.md $CMDS/scaffold.md"` — this is the single most fragile line in the entire test suite.

**Specific fragility points by check:**

1. **Check 2 (git add, lines 29–46):** The `git init` exclusion heuristic reads 5 lines of context (`sed -n "$((linenum > 5 ? linenum - 5 : 1)),${linenum}p"`) and checks for `git init` in that window. This is a window-size assumption: if `git add .` appears more than 5 lines after the `git init` instruction, the context window misses it and may produce a false FAIL.

2. **Check 3 (retry limits, lines 49–67):** Patterns `'fixer.*Task tool|Run.*fixer'`, `'reviewer.*Task tool|Run.*reviewer'`, `'test-engineer.*Task tool|Run.*test-engineer'` are wording-sensitive. If the invocation language changes from "Run fixer" or "Task tool" to another form (e.g., "Invoke the fixer agent"), the condition check is not triggered and the test silently skips the retry-limit validation.

3. **Check 4 (rm -rf safety, lines 70–77):** Relies on variable name `SCAFFOLD_TEMP` and exact safety phrase `"DO NOT run rm -rf"`. Both are fragile to any variable rename or safety-phrase reword.

4. **Check 5 (rollback + issue tracker, lines 80–87):** File-level check only — it confirms both strings appear somewhere in the file, not that they are logically connected. `scaffold.md` passes this check (verified: rollback-agent appears at line 371 and "issue tracker" appears multiple times), but the rollback context instruction in scaffold.md explicitly says `"No issue tracker context"`, which is the opposite of what the test intends to validate. This is a false-positive scenario.

**What would need to change to make it migration-resilient:**
1. Extract `PIPELINE_FILES` into a discoverable pattern (e.g., check all commands that reference `rollback-agent` or `fixer.*Task tool`).
2. Widen check 2's context window or use section-header detection instead of line proximity.
3. Make check 3 patterns more resilient by checking for the agent name in any invocation context, not just specific phrasing.
4. For check 5, replace the file-level co-occurrence check with a proximity check (both strings within N lines of each other).

---

## Test Coverage Map

| Aspect | Covered? | By which test? |
|--------|----------|----------------|
| All command files exist | Yes | happy-path.sh |
| All agent files exist | Yes | happy-path.sh |
| Agent frontmatter fields (name, description, model, style) | Partial | browser-verification-skip.sh (only reproducer + browser-verifier) |
| Fixer uses opus model | Yes | fixer-retry.sh |
| Publisher uses haiku model | Yes | publish-success.sh |
| Spec-writer/spec-reviewer use opus model | Yes | scaffold-v2-happy-path.sh |
| Reproducer/browser-verifier use sonnet model | Yes | browser-verification-skip.sh |
| Fixer has retry/iteration awareness | Yes | fixer-retry.sh |
| Reviewer has APPROVE/REQUEST_CHANGES | Yes | reviewer-reject.sh |
| Test-engineer has constraints | Yes (weak) | test-fail.sh |
| Publisher has main branch protection | Yes | publish-success.sh |
| Triage-analyst references block template | Yes | triage-block.sh |
| Spec-writer has block template | Yes | scaffold-v2-spec-loop.sh |
| Spec-reviewer has APPROVE/REVISE verdicts | Yes | scaffold-v2-spec-loop.sh |
| Fix Verification section in fix-ticket | Yes | verify-fail.sh |
| Fix Verification section in fix-bugs | Yes | verify-fail.sh |
| Feature Verification in implement-feature | Yes | verify-fail.sh |
| Pipeline profile parsing in pipeline commands | Yes | profile-skip.sh |
| Mandatory stage protection (NEVER skip) | Yes | profile-skip.sh |
| Block comment emoji consistency | Yes | pipeline-consistency.sh |
| git add -A (not git add .) usage | Yes | pipeline-consistency.sh |
| Retry limit references in pipeline commands | Yes | pipeline-consistency.sh |
| rm -rf safety checks | Yes | pipeline-consistency.sh |
| Rollback-agent + issue tracker co-presence | Yes (false positive for scaffold) | pipeline-consistency.sh |
| Scaffold v2 pipeline steps present | Yes | scaffold-v2-happy-path.sh |
| Scaffold three-mode selection | Yes | scaffold-v2-happy-path.sh |
| Scaffold --no-implement legacy flow | Yes | scaffold-v2-no-implement.sh |
| Scaffold input flag conflicts | Yes | scaffold-v2-input-conflicts.sh |
| Spec-writer/reviewer loop mechanics | Yes | scaffold-v2-spec-loop.sh |
| CLAUDE.md Spec iterations config key | Yes | scaffold-v2-spec-loop.sh |
| Browser verification conditional guard | Yes | browser-verification-skip.sh |
| Reproducer NEVER block constraint | Yes | browser-verification-skip.sh |
| Browser-verifier Sub-phase B constraint | Yes | browser-verification-skip.sh |
| Stage mapping for reproducer + browser-verifier | Yes | browser-verification-skip.sh |
| CLAUDE.md Browser Verification config section | Yes | browser-verification-skip.sh |
| Triage reproduction_steps field | Yes | browser-verification-skip.sh |
| Mock MCP server integration | No | (no test uses mock-mcp-server.sh) |
| Mock project pipeline execution | No | (no test uses mock-project/) |
| Actual agent invocation (live) | No | (all tests are static analysis only) |
| Command/agent naming convention (ceos-agents: namespace) | No | (not validated) |
| Agent description field content quality | No | (not validated) |
| All 24 commands have valid frontmatter | No | (happy-path only checks file existence) |
| Verify command execution after PR merge | No | (not validated) |
| CHANGELOG.md presence and format | No | (not validated) |
| Config contract completeness in CLAUDE.md | Partial | scaffold-v2-spec-loop.sh (only Spec iterations) |
| E2E test pipeline in implement-feature | No | (not validated) |
| Acceptance-gate agent model and constraints | No | (not validated) |
