# Phase 1 Agent 2 — Research Questions (Innovative / Plugin-Architect)

## Q1: What is the full cascade of test scenarios that embed the old skill names as hardcoded strings, and which ones verify a count that changes?

- **Why**: `skills-directory-structure.sh` hardcodes an array of 29 expected skill names including `create-pr`, `init`, `status`; `regression-skill-count-29.sh` asserts exactly 29 directories; `skills-frontmatter-check.sh` enumerates `create-pr` in its PIPELINE_SKILLS array and `status`/`init` in its READONLY_SKILLS array — all three will FAIL after v7.0.0 renames/deletions. The spec mentions only `v6.9.0-bc-no-renamed-section.sh`. How many more test files need RETIRE or UPDATE?
- **Files to read**: `tests/scenarios/skills-directory-structure.sh`, `tests/scenarios/skills-frontmatter-check.sh`, `tests/scenarios/regression-skill-count-29.sh`, `tests/scenarios/ac-v68-doc-skill-count-29.sh`, `tests/scenarios/v6.9.0-doc-count-drift.sh`, `tests/scenarios/v6.9.0-bc-no-renamed-section.sh`, `tests/scenarios/no-mcp-jargon-errors.sh`
- **Maps to release action**: Actions 3, 4, 5, 6 (skill renames + deletion + count changes)

## Q2: Does `skills/status/SKILL.md` contain hardcoded references to `/ceos-agents:init` in its user-facing output text, and does `skills/init/SKILL.md` contain cross-references to `/ceos-agents:status`?

- **Why**: `status/SKILL.md` Step 6b Configuration Readiness table explicitly emits the string `` run `/ceos-agents:init` `` in the "MCP Server" detail column — this user-facing string in a SKILL.md survives the directory rename only if the inline text is also updated. Similarly, `init/SKILL.md` self-references its own name in several places. If these are missed, users will see stale skill names in live output after the rename.
- **Files to read**: `skills/status/SKILL.md` (lines 58-88), `skills/init/SKILL.md` (full file), `skills/check-setup/SKILL.md` (likely cross-references init)
- **Maps to release action**: Actions 3 and 4

## Q3: Does `core/mcp-preflight.md` or `core/mcp-detection.md` contain hardcoded references to `/ceos-agents:init` or `/ceos-agents:check-setup` in its Recommendation fields, and how many other core contracts reference `/ceos-agents:init` by name?

- **Why**: `core/mcp-preflight.md` line 36 already confirmed to contain `` /ceos-agents:init `` verbatim in a Recommendation field. Core contracts are shared by all pipeline skills — a stale reference here propagates to every skill that invokes the contract. The spec's file enumeration for Action 4 does not list any `core/` files.
- **Files to read**: `core/mcp-preflight.md`, `core/mcp-detection.md`, `core/config-reader.md` (confirmed reference to `init`), grep all `core/*.md` for `/ceos-agents:init`
- **Maps to release action**: Action 4 (rename init → setup-mcp)

## Q4: What is the exact MCP tool name used by each supported tracker to verify that an issue exists (not just lists projects), and what response shape distinguishes "issue not found (404)" from "tracker unreachable (5xx/timeout)"?

- **Why**: The `/publish` auto-detect spec requires a 3-way fork on `tracker.getIssue(issue_id)` — but `core/mcp-detection.md` documents only read connectivity via "list 1 issue" or "list projects", not a single-issue fetch. The actual MCP tool name for getIssue (e.g., `mcp__youtrack__getIssue` vs `mcp__youtrack__get_issue` vs `mcp__youtrack__issues_get`) varies by MCP package and is not documented in the current contracts. Getting the tool name wrong means the auto-detect silently falls back to PR-only mode on every branch.
- **Files to read**: `core/mcp-detection.md`, `docs/reference/trackers.md`, `skills/publish/SKILL.md`, `skills/fix-ticket/SKILL.md` (how it currently fetches a specific issue), `agents/publisher.md`
- **Maps to release action**: Action 5 (publish auto-detect tracker)

## Q5: Does `core/config-reader.md` parse `### Extra labels` into a separate field (`pr_rules.extra_labels`) that is consumed by any agent or skill OTHER than publisher and the 3 pipeline skills named in the spec?

- **Why**: `core/config-reader.md` line 31 confirms it parses `Extra labels` into `pr_rules.extra_labels`. If any skill not listed in the spec (e.g., `onboard`, `migrate-config`, `check-setup`, `scaffold`) reads `pr_rules.extra_labels` from the config-reader output, deleting the `Extra labels` section without updating that consumer would silently break label injection. The spec only enumerates publisher, fix-ticket, fix-bugs, implement-feature, and examples/configs.
- **Files to read**: `core/config-reader.md`, `skills/onboard/SKILL.md`, `skills/migrate-config/SKILL.md`, `skills/check-setup/SKILL.md`, `agents/publisher.md`, grep all skills for `extra_labels`
- **Maps to release action**: Action 1 (delete Extra labels config section)

## Q6: Does `workflow-router/SKILL.md` Step 3 contain `create-pr` in its "NOT destructive" fast-path list, and Step 4 in its "IS destructive" confirmation list — meaning TWO separate edits are needed, not one?

- **Why**: `workflow-router/SKILL.md` Step 3 lists non-destructive skills that bypass confirmation, and Step 4 lists destructive ones requiring confirmation. The intent table (lines 15-16) shows both `create-pr` and `publish` as separate rows with `Yes` destructive flag. After deleting `create-pr` and renaming `status` and `init`, the workflow-router needs surgical edits in the intent table AND in the Step 3/4 prose lists. A partial edit (updating table but missing prose) leaves a dangling reference to `create-pr` in the routing logic text.
- **Files to read**: `skills/workflow-router/SKILL.md` (full file, specifically lines 52-63 which reference `create-pr` and `status` in the confirmation logic prose)
- **Maps to release action**: Actions 3, 4, 5, 6 (all skill changes touch workflow-router)

## Q7: What is the exact existing branch-name-to-issue-ID extraction logic in `skills/publish/SKILL.md` Step 1, and does it conflict with the new auto-detect spec's requirement to first read `Source Control → Branch naming` from Automation Config?

- **Why**: The current `publish/SKILL.md` Steps 1-3 assume the issue ID is already known (they operate as part of an established pipeline run). The new auto-detect logic requires parsing the branch name against the configured `Branch naming` pattern — but what if the branch naming pattern in Automation Config uses a regex with capture groups vs a glob pattern vs a plain prefix? If `fix-ticket` and `implement-feature` use a different extraction method than what the new `publish` will use, there will be divergence: the same branch that fix-ticket correctly maps to PROJ-42 could fail to match in the new publish auto-detect.
- **Files to read**: `skills/publish/SKILL.md` (Steps 1-5 current), `skills/fix-ticket/SKILL.md` (branch naming extraction step), `skills/implement-feature/SKILL.md` (same), `skills/fix-bugs/SKILL.md` (same), `docs/reference/automation-config.md` (Branch naming key description)
- **Maps to release action**: Action 5 (publish auto-detect logic)

## Q8: Are there any `.claude-plugin/` metadata files or `examples/configs/*.md` templates that enumerate the full skill list or config section count, beyond what the spec's file enumeration covers?

- **Why**: The spec lists specific files for each action, but plugin metadata (`plugin.json`, `marketplace.json`) could contain skill listings, and config templates in `examples/configs/*.md` are listed for Action 1 but the spec says only "Extra labels" rows need removal. However, if any template also contains a count string like "19 optional sections" or references `ceos-agents:status` in example invocations, those will drift. The `feedback_doc_completeness.md` discipline specifically calls out 5 anchor files — but examples/ and .claude-plugin/ are not in the anchor list.
- **Files to read**: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `examples/configs/github-nextjs.md` (sample), `examples/configs/redmine-oracle-plsql.md` (confirmed to reference Extra labels), grep all `examples/configs/*.md` for `ceos-agents:status`, `ceos-agents:init`, `create-pr`
- **Maps to release action**: Actions 1, 3, 4, 6 (cross-cutting doc-count and skill-reference drift)
