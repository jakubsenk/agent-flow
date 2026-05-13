# Phase 1 Final: Research Questions for v7.0.0 Cleanup

## Q1: How many of the 8 config templates in `examples/configs/` actually contain "Extra labels" — 2 or all 8?

- **Why**: The spec says "8 config templates" reference `Extra labels`, but a live grep found matches in only 2 files (`redmine-oracle-plsql.md` and `github-nextjs.md`). Phase 2 must confirm the real count before Phase 7 executes, to avoid touching 6 templates that have no `Extra labels` row.
- **Files to read**: All 8 files in `examples/configs/` — `github-nextjs.md`, `github-python-fastapi.md`, `github-dotnet.md`, `gitea-spring-boot.md`, `jira-react.md`, `youtrack-python.md`, `redmine-rails.md`, `redmine-oracle-plsql.md` — grep each for `Extra labels`
- **Maps to release action**: Action 1 (Delete `Extra labels` config section)
- **Source**: agent-3 (primary); agent-1 corroborates with same file list

## Q2: What is the complete file:line inventory of every non-bak reference to `Extra labels`, and does `core/config-reader.md` parse it into a field consumed by skills NOT listed in the spec?

- **Why**: (a) The spec lists publisher, fix-ticket, fix-bugs, implement-feature, and the examples/configs as consumers — but `core/config-reader.md` parses `Extra labels` into `pr_rules.extra_labels`; if `onboard`, `migrate-config`, `check-setup`, or `scaffold` also read that field, deleting the section silently breaks label injection. (b) `tests/scenarios/config-reader-sections.sh` maintains an explicit array of section names — if `Extra labels` is hardcoded there, it must be updated or the test will FAIL post-deletion.
- **Files to read**: `core/config-reader.md` (grep for `extra_labels` and `Extra labels`); `skills/onboard/SKILL.md`, `skills/migrate-config/SKILL.md`, `skills/check-setup/SKILL.md`, `agents/publisher.md` (grep for `extra_labels`); `tests/scenarios/config-reader-sections.sh` (full file)
- **Maps to release action**: Action 1 (Delete `Extra labels` config section)
- **Source**: agent-2 Q5 + agent-3 Q4 merged

## Q3: Which exactly 6 skills implement pause-on-NEEDS_CLARIFICATION semantics, and does `analyze-bug` qualify or is it interactive-only?

- **Why**: The spec names fix-ticket, fix-bugs, implement-feature, scaffold, autopilot, resume-ticket as the presumed 6. But `analyze-bug` has a NEEDS_CLARIFICATION handler (possibly interactive-only with no `state.json` pause), and `resume-ticket` implements the *resume* side, not the *pause* side. The `automation-config.md` doc fix must name the correct 6 — an incorrect list is a new accuracy bug. Also confirm whether `docs/reference/automation-config.md` line 40 is the only location to fix, or whether the section body at lines ~460-470 and ~628 also states "/autopilot only".
- **Files to read**: `skills/analyze-bug/SKILL.md`, `skills/resume-ticket/SKILL.md`, `skills/fix-ticket/SKILL.md` (NEEDS_CLARIFICATION handler), `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/autopilot/SKILL.md`; `docs/reference/automation-config.md` lines 35-50 AND lines 455-480 AND lines 620-640
- **Maps to release action**: Action 2 (Fix `Pause Limits` doc mapping)
- **Source**: agent-3 Q3 + agent-1 Q2 + agent-3 Q7 merged

## Q4: What is the complete file:line inventory of every reference to `/ceos-agents:status`, `ceos-agents:status`, `/ceos-agents:init`, and `ceos-agents:init` — including `core/` files and inline user-facing output strings inside SKILL.md files?

- **Why**: `core/mcp-preflight.md` contains `/ceos-agents:init` verbatim in a Recommendation field (confirmed line ~36); core contracts are shared by all pipeline skills, so a stale reference here propagates everywhere. The spec's enumeration for Actions 3 and 4 does not list any `core/` files. Additionally, `skills/status/SKILL.md` Step 6b emits the string `run /ceos-agents:init` in user-facing table output — this survives a directory rename only if the inline text is also updated.
- **Files to read**: `core/mcp-preflight.md`, `core/mcp-detection.md`, `core/config-reader.md` (grep for `init`); `skills/status/SKILL.md` lines 58-88; `skills/init/SKILL.md` (full); `skills/check-setup/SKILL.md`; `skills/workflow-router/SKILL.md`; `skills/scaffold/SKILL.md`; `skills/onboard/SKILL.md`; `README.md` (grep); `tests/scenarios/` (grep for `ceos-agents:status` and `ceos-agents:init`)
- **Maps to release action**: Actions 3 and 4 (Rename `/ceos-agents:status` and `/ceos-agents:init`)
- **Source**: agent-2 Q2+Q3 merged; agent-1 Q3 partial overlap

## Q5: What is the exact structure of the `workflow-router` intent table and Step 3/4 prose — specifically, do `/ceos-agents:status`, `/ceos-agents:init`, and `/ceos-agents:create-pr` appear as distinct table rows, in prose lists, or both?

- **Why**: After deleting `create-pr` and renaming `status` and `init`, the workflow-router needs surgical edits in the intent table AND potentially in the Step 3/4 confirmation-logic prose. A partial edit (updating table but missing prose references like "NOT destructive fast-path" or "IS destructive confirmation" lists) leaves dangling references. Also verify whether `/publish` has a row that needs updating when its description changes for auto-detect.
- **Files to read**: `skills/workflow-router/SKILL.md` (full file — intent table lines and Steps 3-4 prose, specifically any lines referencing `create-pr`, `status`, `init`, or `publish`)
- **Maps to release action**: Actions 3, 4, 5, 6 (all skill changes touch workflow-router)
- **Source**: agent-2 Q6 + agent-3 Q5 merged

## Q6: What is the exact current branch-name-to-issue-ID extraction logic in `skills/publish/SKILL.md` Steps 1-3, and how do fix-ticket/fix-bugs/implement-feature extract the issue ID from a branch name today?

- **Why**: The current `publish/SKILL.md` Steps 1-3 assume the issue ID is already known (established pipeline run). The new auto-detect requires parsing the branch name against `Source Control → Branch naming` from Automation Config. Phase 2 must confirm: (a) exact current Step 1 text to replace; (b) file:line reference implementation in fix-ticket/fix-bugs for branch→issue_id extraction; (c) whether `Branch naming` uses regex with capture groups vs glob vs plain prefix, which affects whether the same extraction pattern can be reused verbatim.
- **Files to read**: `skills/publish/SKILL.md` (Steps 1-5, full), `skills/fix-ticket/SKILL.md` (branch creation + issue_id extraction step — cite line), `skills/fix-bugs/SKILL.md` (same), `skills/implement-feature/SKILL.md` (same), `docs/reference/automation-config.md` (`Branch naming` key description)
- **Maps to release action**: Action 5 (Auto-detect tracker in `/publish`)
- **Source**: agent-2 Q7 + agent-1 Q4 merged

## Q7: For each supported tracker type (youtrack, github, jira, linear, gitea, redmine), what is the MCP tool name used to fetch a single issue, and what response/exception distinguishes "issue not found (404)" from "tracker unreachable (5xx/timeout)"?

- **Why**: The `/publish` auto-detect spec requires a 3-way fork on `tracker.getIssue(issue_id)`, but `core/mcp-detection.md` documents only read connectivity via "list 1 issue" or "list projects", not single-issue fetch. Getting the tool name wrong (e.g., `mcp__youtrack__getIssue` vs `mcp__youtrack__get_issue`) means auto-detect silently falls back to PR-only mode on every branch. The error shape for 404 vs 5xx must also be confirmed to correctly implement the 3-way fork.
- **Files to read**: `core/mcp-detection.md` (full), `docs/reference/trackers.md` (MCP tool names per tracker), `skills/fix-ticket/SKILL.md` (how it currently fetches a specific issue — cite line), `agents/publisher.md`, `skills/publish/SKILL.md`
- **Maps to release action**: Action 5 (Auto-detect tracker in `/publish`)
- **Source**: agent-2 Q4 + agent-1 Q4 merged

## Q8: What is the complete test scenario inventory that will HARD-FAIL or produce false-positives after v7.0.0 — beyond `v6.9.0-bc-no-renamed-section.sh`?

- **Why**: At minimum 5 additional scenarios are at risk: `regression-skill-count-29.sh` (asserts exactly 29 skill dirs), `ac-v68-doc-skill-count-29.sh` (asserts "29 skills" in CLAUDE.md/skills.md), `v6.9.0-doc-count-drift.sh` (asserts "19 optional config sections in total" — will HARD-FAIL when count drops to 18), `skills-directory-structure.sh` (likely hardcodes skill dir names including `create-pr`, `status`, `init`), `skills-frontmatter-check.sh` (matched "create-pr" in a grep). Additionally, `ac-v68-doc-optional-sections-18.sh` checks `(18|19) optional` — it will silently PASS after the drop to 18, creating a false-positive acceptance signal, while `v6.9.0-doc-count-drift.sh` simultaneously HARD-FAILs on the same change; Phase 2 must verify whether updating `v6.9.0-doc-count-drift.sh` from 19→18 creates a contradiction with its own negative assertion at lines 56-57 that rejects "18 optional config sections in total".
- **Files to read**: `tests/scenarios/regression-skill-count-29.sh`, `tests/scenarios/ac-v68-doc-skill-count-29.sh`, `tests/scenarios/v6.9.0-doc-count-drift.sh` (lines 41-57), `tests/scenarios/skills-directory-structure.sh`, `tests/scenarios/skills-frontmatter-check.sh`, `tests/scenarios/ac-v68-doc-optional-sections-18.sh`, `tests/scenarios/v6.9.0-bc-no-renamed-section.sh`, `tests/scenarios/config-reader-sections.sh`, `tests/scenarios/no-mcp-jargon-errors.sh`
- **Maps to release action**: Actions 1, 3, 4, 5, 6 (all count/identifier changes)
- **Source**: agent-3 Q1+Q8 + agent-2 Q1 merged

## Q9: What are the exact line numbers in the 5 anchor docs where "29 skills" and "19 optional" appear, and do `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, or `examples/configs/*.md` contain count strings or skill-name references not covered by the anchor-doc audit?

- **Why**: The 5 anchor files (CLAUDE.md, README.md, docs/reference/automation-config.md, docs/reference/skills.md, docs/architecture.md) are the primary targets per `feedback_doc_completeness.md`, but plugin metadata and examples/ are NOT in the anchor list. If `plugin.json`/`marketplace.json` enumerate skills, or if any config template references `ceos-agents:status`/`ceos-agents:init` in example invocations, those will drift. Also confirm whether `docs/architecture.md` contains count strings (it was absent from the preliminary grep results).
- **Files to read**: `CLAUDE.md` (grep for `29 skills`, `19 optional`), `README.md` (lines 215-270), `docs/reference/automation-config.md` (lines 1-15), `docs/reference/skills.md` (lines 1-10), `docs/getting-started.md` (lines 215-225), `docs/architecture.md` (grep for count strings); `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`; grep all `examples/configs/*.md` for `ceos-agents:status`, `ceos-agents:init`, `create-pr`
- **Maps to release action**: Cross-cutting (all actions affect counts; must update after deletions/renames)
- **Source**: agent-1 Q6 + agent-2 Q8 merged

---

## Validation Tasks (Phase 2 must resolve)

- **DISAGREEMENT A**: Agent-1 claims `examples/configs/*.md` (all 8 templates) reference `Extra labels` (per spec); agent-3 claims a live grep found only 2 matches (`redmine-oracle-plsql.md` and `github-nextjs.md`). Resolve by grepping all 8 files for `Extra labels` with line numbers. This is the highest-priority disagreement — it determines the scope of Action 1 edits.

- **DISAGREEMENT B**: Agent-1 lists `resume-ticket` as one of the 6 skills implementing pause semantics (consistent with spec); agent-3 questions whether `resume-ticket` qualifies since it implements the *resume* side, not the *pause* side. Resolve by reading `skills/resume-ticket/SKILL.md` for any NEEDS_CLARIFICATION emission or `state.paused` write.

- **DISAGREEMENT C**: Agent-3 Q7 found `Pause Limits` appearing at lines 40, 460, 470, AND 628 in `docs/reference/automation-config.md`; agent-1 Q2 targets only line 40. Resolve by reading those 4 line ranges to determine whether the section body also states "/autopilot only" (requiring multi-location fix vs single-line fix).

- **DISAGREEMENT D**: Agent-3 Q8 asserts that `v6.9.0-doc-count-drift.sh` lines 56-57 contain a *negative* assertion rejecting "18 optional config sections in total" — meaning updating the count to 18 in CLAUDE.md would cause this test to FAIL. Agent-2 does not flag this. Resolve by reading `tests/scenarios/v6.9.0-doc-count-drift.sh` lines 41-57 in full.

---

## Synthesis Notes

- **Base**: agent-2 (score 23/25) — selected for strongest cross-cutting coverage (core/ files, workflow-router prose, plugin metadata) and spec-validation rigor on `extra_labels` consumer coverage
- **Contributions merged from agent-3**: Q1 (2 vs 8 templates — sharpest spec-validation catch), Q3 (analyze-bug exclusion + resume-ticket pause-vs-resume distinction), Q7 (multi-location Pause Limits in automation-config.md), Q8 (ac-v68 false-positive asymmetry + v6.9.0-doc-count-drift negative assertion); agent-3 test-scenario enumerations folded into Q8
- **Contributions merged from agent-1**: Q2 (Pause Limits exact line 40 plus config-reader-sections.sh cross-check), Q6 (publish Step 1 current text + fix-ticket reference implementation), Q8 (installation.md warning structure question folded into Q9 cross-cutting)
- **Excluded as redundant**: agent-1 Q8 (installation.md warning) — valid but lower risk than the spec-validation catches; omitted to keep list at 9; Phase 2 can read `docs/guides/installation.md` headings as part of Action 6 execution without a dedicated research question
- **Excluded as anti-pattern**: any question about `--no-tracker` flag (spec explicitly forbids), plugin.json version bump (user does manually), prompt-injection (v6.10.1+ scope)
- **Disagreements noted**: 4
