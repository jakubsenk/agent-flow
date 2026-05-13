# Research Question 7: Test Migration Strategy

## Refined Question

The 15 existing test scenarios are exclusively static analysis tests — they grep and check for string
patterns in markdown files. None execute agents, none start pipelines, none run commands. The
migration question is therefore: when the "unified pipeline" changes command file content and
directory layout, which existing tests will break (false failures), which will silently pass on
incomplete content (false passes), and what behavioral tests are needed to validate the new pipeline
logic that the current suite cannot verify?

---

## Test Inventory

| Test file | Type | What it validates | Depends on current layout? | Migration impact |
|---|---|---|---|---|
| `happy-path.sh` | Structural | Exact list of 24 command filenames + 18 agent filenames exist under `commands/` and `agents/` | Yes — hardcodes every filename | HIGH: any rename, merge, or split of commands/agents causes failures |
| `triage-block.sh` | Structural | `agents/triage-analyst.md` contains string `"Block Comment Template"` or `"Pipeline Block"` | Yes — hardcodes agent path | LOW: path stays stable; content check is fragile if wording changes |
| `fixer-retry.sh` | Structural | `agents/fixer.md` has `"iteration\|retry\|attempt"` AND frontmatter `model: opus` | Yes — hardcodes agent path | LOW: model constraint is useful; keyword check is very loose |
| `reviewer-reject.sh` | Structural | `agents/reviewer.md` has both `"APPROVE"` and `"REQUEST_CHANGES"` strings | Yes — hardcodes agent path | LOW: useful contract check; breaks if verdict format is renamed |
| `test-fail.sh` | Structural | `agents/test-engineer.md` has `"NEVER\|Constraint"` | Yes | VERY LOW: trivially satisfied; tests nothing meaningful |
| `publish-success.sh` | Structural | `agents/publisher.md` has `"NEVER.*main"` pattern AND `model: haiku` | Yes — hardcodes agent path | LOW: useful contract check |
| `profile-skip.sh` | Structural | `fix-ticket.md`, `fix-bugs.md`, `implement-feature.md` each have `"Pipeline profile parsing\|--profile"` AND `"NEVER.*skip"` | Yes — hardcodes 3 command paths | MEDIUM: if unified pipeline merges these commands, all 3 checks must still match 1 or more files |
| `verify-fail.sh` | Structural | `fix-ticket.md` has step `"9d\. Fix Verification"`, `fix-bugs.md` has `"8c\. Fix Verification"`, `implement-feature.md` has `"10b\. Feature Verification"` | YES — hardcodes exact step numbers (9d, 8c, 10b) | HIGH: step numbers change during any refactor; this test will false-fail on trivial renumbering |
| `pipeline-consistency.sh` | Structural/Cross-file | Checks 4 pipeline commands for: emoji in block comment, `git add -A` not `git add .`, retry limits text, SCAFFOLD_TEMP safety, rollback-agent + issue tracker co-occurrence | Yes — operates on exactly 4 hardcoded files | HIGH: if unified pipeline reduces these 4 to fewer files or renames steps, checks 3 and 5 (retry-limit text, rollback context) may break |
| `scaffold-v2-happy-path.sh` | Structural | `agents/spec-writer.md` + `agents/spec-reviewer.md` exist with `model: opus`; `commands/scaffold.md` has specific strings: Mode Selection, spec-writer, spec-reviewer, architect agent, Feature Implementation Loop, E2E Tests, Final Report, Interactive, YOLO with checkpoint, Full YOLO | Yes — all 8 string literals in `scaffold.md` | MEDIUM: text checks are brittle; break on any heading rename |
| `scaffold-v2-input-conflicts.sh` | Structural | `commands/scaffold.md` has exact error strings: `"Only one input source allowed"`, `"--no-implement skips specification phase"`, flags `--template`, `--spec`, `--issue`, `--no-implement`, `--lang`, `--framework`, `--db`, `--ci` | Yes — hardcodes 8 exact flag strings | MEDIUM: flag name changes break tests; useful flag-existence checks |
| `scaffold-v2-no-implement.sh` | Structural | `commands/scaffold.md` has `"--no-implement"`, `"Legacy Flow"`, `"stack-selector"`, `"EXIT pipeline"`, `"Create issues in your issue tracker"` | Yes | MEDIUM: exact phrase checks break on rewording |
| `scaffold-v2-spec-loop.sh` | Structural | `spec-writer.md` has `"Pipeline Block"`; `spec-reviewer.md` has `"APPROVE"` and `"REVISE"`; `scaffold.md` has `"Spec iterations"`, `"spec-writer.*spec-reviewer loop"` (regex), `"max_iterations exhausted"`; `CLAUDE.md` has `"Spec iterations"` | Yes — checks both agent and command files and top-level CLAUDE.md | MEDIUM: regex `spec-writer.*spec-reviewer loop` is brittle; CLAUDE.md check ties test to plugin docs |
| `browser-verification-skip.sh` | Structural (most thorough) | 10 checks: agent file existence + frontmatter completeness (all 4 fields) + `model: sonnet`; `fix-ticket.md` + `fix-bugs.md` have `"browser_verification_enabled"` guard; `CLAUDE.md` has `"Browser Verification"`; specific constraint strings in both agent files; stage-mapping strings in both commands | Yes — touches 6 files across 3 directories | MEDIUM: best-structured test in suite; checks real contract points |
| `pipeline-consistency.sh` (cont.) | (already listed above) | — | — | — |

**Total: 14 unique test files** (README.md says 13, but there are 14 scenario scripts; the README was written before `browser-verification-skip.sh` was added and still says 13).

---

## Test Runner Analysis

`tests/harness/run-tests.sh` is a minimal bash harness:

- Discovers all `*.sh` files in `tests/scenarios/` via glob — no explicit list.
- Runs each with `bash <scenario> > /dev/null 2>&1` — output is suppressed in batch mode; only exit code matters.
- Exit code 0 = PASS, exit code 77 = SKIP, any other non-zero = FAIL.
- Supports single-scenario mode: `run-tests.sh <name>` runs one file with output visible.
- No parallelism, no timeout, no retry.
- Exits with code 1 if any test FAILs; exits 0 if only PASS/SKIP.
- No dependency on the mock-project or mock-mcp-server at runtime — none of the 14 scenarios use either.

The mock-mcp-server (`tests/harness/mock-mcp-server.sh`) and mock-project (`tests/mock-project/`) are
infrastructure for future real-execution tests but are **not used by any existing scenario**. They are
dead weight relative to the current suite.

---

## Layout Dependencies

Every test hardcodes paths relative to `REPO_ROOT` (resolved from `$(dirname "$0")/../..`). Specific
layout dependencies:

| Path hardcoded | Used by |
|---|---|
| `commands/<name>.md` (24 specific names) | `happy-path.sh` |
| `agents/<name>.md` (18 specific names) | `happy-path.sh` |
| `agents/triage-analyst.md` | `triage-block.sh` |
| `agents/fixer.md` | `fixer-retry.sh` |
| `agents/reviewer.md` | `reviewer-reject.sh` |
| `agents/test-engineer.md` | `test-fail.sh` |
| `agents/publisher.md` | `publish-success.sh` |
| `commands/fix-ticket.md`, `commands/fix-bugs.md`, `commands/implement-feature.md` | `profile-skip.sh`, `verify-fail.sh` |
| `commands/fix-ticket.md`, `commands/fix-bugs.md`, `commands/implement-feature.md`, `commands/scaffold.md` | `pipeline-consistency.sh` |
| `agents/spec-writer.md`, `agents/spec-reviewer.md`, `commands/scaffold.md` | `scaffold-v2-happy-path.sh`, `scaffold-v2-spec-loop.sh` |
| `commands/scaffold.md` | `scaffold-v2-input-conflicts.sh`, `scaffold-v2-no-implement.sh` |
| `agents/reproducer.md`, `agents/browser-verifier.md`, `commands/fix-ticket.md`, `commands/fix-bugs.md`, `CLAUDE.md` | `browser-verification-skip.sh` |
| `CLAUDE.md` | `scaffold-v2-spec-loop.sh`, `browser-verification-skip.sh` |

No test touches `skills/`, `docs/`, `checklists/`, `.claude-plugin/`, or `examples/`.

---

## Test Coverage Gaps

**What the current tests do NOT cover:**

1. **Agent output contract** — Tests check that agents contain certain words, but do not verify that
   the structured output sections (e.g., triage-analyst's `Acceptance criteria`, `Complexity`,
   `Reproduction steps` fields) match the CLAUDE.md output contract.

2. **Cross-agent handoff contracts** — No test checks that what triage-analyst outputs (fields) are
   the same fields that fix-ticket commands consume. The wiring between agents and commands is untested.

3. **Config section completeness** — The mock-project CLAUDE.md and the fixture `automation-config.md`
   are never validated against the Config Contract table in CLAUDE.md. A new required key could be
   added without any test failing.

4. **Frontmatter completeness for all agents** — Only `browser-verification-skip.sh` checks all 4
   frontmatter fields (`name`, `description`, `model`, `style`) — and only for `reproducer` and
   `browser-verifier`. The other 16 agents are not validated for `style` field presence.

5. **Model assignment correctness** — Only `fixer-retry.sh` (opus) and `publish-success.sh` (haiku)
   check model. The opus agents `reviewer`, `architect`, `spec-writer`, `spec-reviewer`,
   `priority-engine` are unchecked; the sonnet agents are entirely unchecked.

6. **Section order in agent files** — The canonical `Goal → Expertise → Process → Constraints` order
   is never validated. A malformed agent with wrong section order would pass all tests.

7. **Read-only vs. execution agent constraint** — No test verifies that read-only agents (reviewer,
   code-analyst, acceptance-gate, etc.) do not contain phrases implying file writes.

8. **Rollback agent integration** — `pipeline-consistency.sh` checks that `rollback-agent` and
   `issue tracker` co-occur in pipeline files, but does not check `agents/rollback-agent.md` content.

9. **Acceptance gate conditionality** — No test verifies that fix-ticket/fix-bugs correctly gate on
   `AC ≥ 3 or complexity ≥ M` vs. implement-feature's unconditional gate.

10. **Browser verification step ordering** — No test checks that browser-verifier appears after
    test-engineer and before publisher in both fix-ticket and fix-bugs.

11. **Decomposition mechanics** — The NEEDS_DECOMPOSITION signal from fixer, max subtasks config key,
    and fail-strategy handling are completely untested.

12. **Worktree config integration** — The Worktrees config section in mock-project CLAUDE.md is never
    exercised by any test.

---

## New Tests Needed

For a unified pipeline migration the following new scenarios are required:

**Structural parity tests (update existing):**
1. `happy-path-unified.sh` — Replace per-file name checks with a count check: assert exactly N
   command files exist in `commands/` and exactly M agent files in `agents/`. Prevents silent file
   omissions without hardcoding every name.
2. `frontmatter-completeness.sh` — Loop all 18 agents; assert each has `name:`, `description:`,
   `model:`, `style:` frontmatter fields. Replaces the partial check in `browser-verification-skip.sh`.
3. `model-assignment.sh` — Assert each agent uses the model specified in CLAUDE.md's model selection
   table (opus: fixer, reviewer, architect, priority-engine, spec-writer, spec-reviewer; haiku:
   publisher, rollback-agent; sonnet: all others).
4. `section-order.sh` — Assert each agent file contains `## Goal`, `## Expertise`, `## Process`,
   `## Constraints` in that order.

**Contract coherence tests (new):**
5. `config-contract.sh` — Validate that both `tests/harness/fixtures/automation-config.md` and
   `tests/mock-project/CLAUDE.md` contain all required config section headings from the CLAUDE.md
   contract table.
6. `step-labels-stable.sh` — Replace `verify-fail.sh`'s hardcoded step numbers (9d, 8c, 10b) with
   label-based checks: assert `Fix Verification` section exists without locking in the step number.
7. `read-only-agents.sh` — Assert that the 9 read-only agents (triage-analyst, code-analyst,
   reviewer, spec-analyst, architect, stack-selector, priority-engine, spec-reviewer, acceptance-gate)
   do not contain phrases like `Edit(`, `Write(`, `create file`, `git commit`, or `git push`.
8. `acceptance-gate-conditionality.sh` — Assert fix-ticket and fix-bugs reference `AC.*3\|complexity.*M`
   gating condition, and implement-feature references unconditional gate invocation.

**Pipeline flow tests (behavioral, markdown-level):**
9. `agent-dispatch-order.sh` — For fix-ticket, fix-bugs, and implement-feature: assert that agent
   dispatch patterns appear in the correct relative order (triage before code-analyst, code-analyst
   before fixer, fixer before reviewer, reviewer before test-engineer, test-engineer before publisher).
10. `browser-verifier-ordering.sh` — Assert that in fix-ticket and fix-bugs, `browser-verifier`
    appears after `test-engineer` and before `publisher` (by line number).
11. `rollback-agent-placement.sh` — Assert that in fix-ticket and fix-bugs, `rollback-agent` is
    referenced only in fixer/reviewer/test failure branches, not after publisher.
12. `decomposition-signal.sh` — Assert that `agents/fixer.md` references `NEEDS_DECOMPOSITION` and
    that fix-ticket and implement-feature handle it (contain `NEEDS_DECOMPOSITION` handling text).
13. `unified-pipeline-consistency.sh` — Extension of `pipeline-consistency.sh`: if the unified
    pipeline introduces a single shared pipeline file, verify all 5 existing consistency rules apply
    to that file, plus verify that browser-verification guard
    (`browser_verification_enabled`) is present.

---

## Files Examined

- `/c/gitea_ceos-agents/tests/harness/run-tests.sh`
- `/c/gitea_ceos-agents/tests/harness/mock-mcp-server.sh`
- `/c/gitea_ceos-agents/tests/harness/fixtures/automation-config.md`
- `/c/gitea_ceos-agents/tests/harness/fixtures/issues.json`
- `/c/gitea_ceos-agents/tests/mock-project/CLAUDE.md`
- `/c/gitea_ceos-agents/tests/mock-project/app.py`
- `/c/gitea_ceos-agents/tests/mock-project/tests/test_app.py`
- `/c/gitea_ceos-agents/tests/scenarios/happy-path.sh`
- `/c/gitea_ceos-agents/tests/scenarios/triage-block.sh`
- `/c/gitea_ceos-agents/tests/scenarios/fixer-retry.sh`
- `/c/gitea_ceos-agents/tests/scenarios/reviewer-reject.sh`
- `/c/gitea_ceos-agents/tests/scenarios/test-fail.sh`
- `/c/gitea_ceos-agents/tests/scenarios/publish-success.sh`
- `/c/gitea_ceos-agents/tests/scenarios/profile-skip.sh`
- `/c/gitea_ceos-agents/tests/scenarios/verify-fail.sh`
- `/c/gitea_ceos-agents/tests/scenarios/pipeline-consistency.sh`
- `/c/gitea_ceos-agents/tests/scenarios/scaffold-v2-happy-path.sh`
- `/c/gitea_ceos-agents/tests/scenarios/scaffold-v2-input-conflicts.sh`
- `/c/gitea_ceos-agents/tests/scenarios/scaffold-v2-no-implement.sh`
- `/c/gitea_ceos-agents/tests/scenarios/scaffold-v2-spec-loop.sh`
- `/c/gitea_ceos-agents/tests/scenarios/browser-verification-skip.sh`
- `/c/gitea_ceos-agents/tests/README.md`

---

## Migration Risks

**R1 — False failures from hardcoded step numbers.**
`verify-fail.sh` checks for step labels `9d`, `8c`, `10b` by exact string. Any renumbering during
refactor — even one that preserves the feature — will produce false failures. This is the most
fragile test.

**R2 — False failures from exact filename lists in happy-path.sh.**
`happy-path.sh` enumerates all 24 command names and all 18 agent names. If the unified pipeline
renames, merges, or adds any file, this test fails until the list is manually updated. During active
migration this becomes a maintenance burden rather than a safety net.

**R3 — Silent passes from insufficient keyword guards.**
`test-fail.sh` passes if `agents/test-engineer.md` contains any of `"NEVER"`, `"Constraint"` — these
strings will always be present. This test provides zero signal and will continue to pass even on a
completely rewritten agent that removes all constraints.

**R4 — Mock infrastructure is unused and will mislead.**
`mock-mcp-server.sh` and the Python mock-project code exist but no scenario uses them. A contributor
reading the test README will expect integration tests; none exist. If the unified pipeline introduces
real agent invocations in CI, the harness is not wired to support them.

**R5 — CLAUDE.md content checks create circular dependencies.**
`scaffold-v2-spec-loop.sh` checks that `CLAUDE.md` contains `"Spec iterations"`. This ties test
correctness to the plugin's own documentation file. If that section is restructured (e.g., during a
docs overhaul), the test fails for reasons unrelated to the code under migration.

**R6 — pipeline-consistency.sh targets exactly 4 files.**
`PIPELINE_FILES` is a hardcoded list of 4 command files. If the unified pipeline introduces a shared
base command file that contains the fixer/reviewer/test loop, the consistency checks will not run
against it unless the test is updated.

**R7 — No test exercises the scaffold-add, scaffold-validate, or check-setup commands.**
These 3 commands have zero test coverage. If they are affected by the migration (e.g., they reference
the unified pipeline), failures will be invisible.

**R8 — Discrepancy between README (13 scenarios) and actual directory (14 scenarios).**
`browser-verification-skip.sh` was added after the README was written. The count is already stale.
This pattern of undocumented additions will compound during migration.
