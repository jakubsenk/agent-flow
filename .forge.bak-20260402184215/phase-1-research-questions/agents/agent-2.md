# RQ-2: Tracker Sub-Issue Creation Capabilities

**Research Agent:** agent-2
**Date:** 2026-04-02
**Sources examined:** `docs/reference/trackers.md`, `agents/publisher.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md`, `docs/guides/mcp-configuration.md`, `core/mcp-detection.md`, `docs/plans/2026-03-06-scaffold-v2-design.md`, `docs/plans/2026-03-27-scaffold-infrastructure-design.md`

---

## Sub-Question 1: Which trackers support native sub-issues/subtasks?

**Finding:** `docs/reference/trackers.md` contains NO information about sub-issue/subtask support. It documents query syntax, state transitions, instance defaults, PR footer syntax, validation rules, and MCP server detection — but has zero content about hierarchical issue relationships. Native sub-issue capability must be inferred from tracker knowledge and from how the codebase currently uses them.

From codebase evidence (scaffold Step 4e instruction: "For each user story within the epic: create a sub-issue under the epic issue"), the assumption is that all 6 supported trackers can handle this, but no tracker-specific guidance is provided.

What is known from general tracker knowledge (not documented in this repo):
- **YouTrack:** Native subtasks — issues can have a parent issue via the `parent` field. YouTrack MCP (`@vitalyostanin/youtrack-mcp`) likely exposes a create-issue call with a `parent` parameter.
- **Jira:** Native sub-tasks — issue type "Sub-task" with a `parent` field. Jira REST API / MCP (`@modelcontextprotocol/server-atlassian`) supports `issueType: "Sub-task"` + `parent: {key}`.
- **Linear:** Native sub-issues — issues can have a `parentId`. Linear MCP (`@modelcontextprotocol/server-linear`) exposes this.
- **GitHub:** No native sub-issue concept in standard Issues. GitHub has "task lists" (markdown checkboxes in issue body) and, in GitHub Projects, hierarchical items. Issues can be linked but there is no true parent-child API. GitHub MCP (`@modelcontextprotocol/server-github`) does not support a `parent` parameter on issue creation.
- **Gitea:** No native sub-issue concept. Gitea issues support labels and cross-references but not hierarchical parent-child. Forgejo MCP (`forgejo-mcp`) does not support `parent` in issue creation.
- **Redmine:** Native sub-tasks — issues have a `parent_issue_id` field. Redmine MCP (`mcp-server-redmine`) likely supports this.

**Evidence:**
- `docs/reference/trackers.md` — entire file (no sub-issue table exists)
- `skills/scaffold/SKILL.md` line 523: `"For each user story within the epic: create a sub-issue under the epic issue."`
- `docs/plans/2026-03-06-scaffold-v2-design.md` lines 465-466: `"One epic per spec/epics/*.md" / "Features as sub-issues under epics (from user stories)"`

**Implication:** The trackers.md reference is incomplete — it does not document sub-issue capabilities. The codebase assumes all trackers support sub-issues but provides no per-tracker instructions. GitHub and Gitea do NOT support native sub-issues, making the current Step 4e instruction incorrect for those two trackers.

---

## Sub-Question 2: What is the MCP API for creating a sub-issue in each supported tracker?

**Finding:** There is NO documentation anywhere in the codebase about MCP tool signatures for sub-issue creation. The codebase uses `mcp__*` wildcard tool calls and relies on the LLM to infer the correct tool and parameters at runtime. No skill or agent file specifies tool names like `mcp__youtrack__create_issue` or parameter schemas like `parent_id`.

The only MCP-related documentation covers:
- Package names and environment variables (`docs/guides/mcp-configuration.md`)
- Tool prefix detection patterns (`core/mcp-detection.md`): e.g., `mcp__youtrack__*`, `mcp__github__*`
- Connectivity testing (canary issue creation via MCP)

From the MCP packages known in the codebase, expected sub-issue creation patterns (inferred, not documented):

| Tracker | MCP Package | Expected Sub-Issue API |
|---------|-------------|------------------------|
| YouTrack | `@vitalyostanin/youtrack-mcp` | `mcp__youtrack__create_issue` with `parent: {issue-id}` — exact param unknown |
| Jira | `@modelcontextprotocol/server-atlassian` | `mcp__jira__create_issue` with `issuetype: "Sub-task"` + `parent: {key}` |
| Linear | `@modelcontextprotocol/server-linear` | `mcp__linear__create_issue` with `parentId: {id}` |
| GitHub | `@modelcontextprotocol/server-github` | No sub-issue API — fallback required |
| Gitea | `forgejo-mcp` | No sub-issue API — fallback required |
| Redmine | `mcp-server-redmine` | `mcp__redmine__create_issue` with `parent_issue_id: {id}` |

**Evidence:**
- `core/mcp-detection.md` lines 23-28: tool prefix table (only prefix, not tool names)
- `docs/guides/mcp-configuration.md`: full MCP config reference (env vars only, no tool schemas)
- `docs/reference/trackers.md`: no MCP tool signatures documented

**Implication:** The codebase has a significant documentation gap. Skills that create sub-issues (scaffold Step 4e) give the LLM no guidance on HOW to call the MCP API. The LLM must guess the correct tool name and parameters. This is a reliability risk. The trackers.md reference should be extended with a sub-issue creation table.

---

## Sub-Question 3: Is there a generic "create issue with parent" pattern, or do we need tracker-specific instructions?

**Finding:** The codebase uses a single generic instruction with NO tracker-specific branching. Scaffold Step 4e says "create a sub-issue under the epic issue" without any per-tracker conditional logic. There is no `if tracker == "github" then...` logic anywhere.

The current approach relies entirely on the LLM to translate the high-level instruction into the appropriate tracker-specific API call. This works for trackers that natively support parent-child (YouTrack, Jira, Linear, Redmine) but breaks silently for GitHub and Gitea.

There is no shared core contract (like `core/create-sub-issue.md`) — no equivalent of `core/fixer-reviewer-loop.md` or `core/mcp-detection.md` for issue creation patterns.

**Evidence:**
- `skills/scaffold/SKILL.md` lines 519-524: single generic loop, no tracker-type conditional
- `docs/plans/2026-03-06-scaffold-v2-implementation-plan.md` lines 755-762: design also uses generic "Create sub-issue under epic card" with no tracker branching
- No file matching `core/*issue*` or `core/*tracker*` exists in the codebase

**Implication:** A tracker-specific instruction table is needed in either `docs/reference/trackers.md` or a new `core/sub-issue-creation.md`. The scaffold Step 4e (and any future skill that creates hierarchical issues) should branch on `tracker_type` with per-tracker instructions.

---

## Sub-Question 4: Fallback for trackers without native sub-issue support (GitHub, Gitea)

**Finding:** The codebase has NO defined fallback strategy for GitHub or Gitea. Step 4e simply says "create a sub-issue" with no mention of fallbacks, no conditional logic, and no acknowledgment that some trackers lack this capability.

The codebase DOES have a general partial-failure handler (accumulator pattern): if individual epic creation fails, log a WARN and continue. This means if a sub-issue creation fails on GitHub/Gitea, it is silently skipped with a warning rather than blocked. This is the de-facto "fallback" — but it results in incomplete tracker structure, not a meaningful alternative representation.

Possible fallbacks for trackers without native sub-issues (not in codebase, but standard practice):
- **GitHub:** Create standalone issues with a naming convention (e.g., `[EPIC-TITLE] User Story: {story title}`), add a label like `epic:{epic-id}`, and add a cross-reference link in the description. Alternatively, use a task list in the epic issue body (markdown checkboxes that GitHub renders as progress).
- **Gitea:** Same as GitHub — standalone issues with label-based grouping and cross-reference links in descriptions. Gitea does not render task lists as sub-issues.

**Evidence:**
- `skills/scaffold/SKILL.md` lines 526-536: accumulator pattern (WARN + continue), no fallback logic
- `docs/plans/2026-03-06-scaffold-v2-design.md` lines 463-468: design lists "Features as sub-issues under epics" with no GitHub/Gitea exception
- `docs/reference/trackers.md`: no fallback column in any table

**Implication:** For the fix, GitHub and Gitea need an explicit fallback strategy documented in `trackers.md` and implemented in scaffold Step 4e (and any other skill creating sub-issues). The recommended fallback is:
1. Create a standalone issue for each user story (no parent)
2. Use a naming convention: `[{epic_title}] {story_title}`
3. Add a label (from `Extra labels` config, or auto-generate `epic` label) to group them
4. Add a cross-reference comment in the epic issue body: "Sub-issues: #{id1}, #{id2}, ..."
5. Add a reference link in each sub-issue description pointing back to the epic

This fallback preserves discoverability while working within GitHub/Gitea constraints.

---

## Summary Table

| Tracker | Native Sub-Issues | MCP API Documented | Fallback Defined |
|---------|-------------------|-------------------|-----------------|
| YouTrack | Yes (parent field) | No | No |
| Jira | Yes (Sub-task type) | No | No |
| Linear | Yes (parentId) | No | No |
| GitHub | No | N/A | No |
| Gitea | No | N/A | No |
| Redmine | Yes (parent_issue_id) | No | No |

## Key Gaps Identified

1. **`docs/reference/trackers.md` is missing a sub-issue capabilities section** — needs a new table with: native support (Y/N), parent parameter name, issue type override (for Jira), fallback strategy.
2. **No per-tracker MCP tool guidance** — scaffold Step 4e gives the LLM no tool name hints. A new `core/sub-issue-creation.md` contract or inline tracker table would make this reliable.
3. **GitHub and Gitea silently fail** — the accumulator pattern swallows errors. Step 4e needs an explicit fallback branch for trackers without native parent support.
4. **publisher.md** does not touch sub-issue creation — it only creates PRs and updates issue state. No changes needed there.
5. **implement-feature/SKILL.md** does not create tracker issues — it only reads existing ones. Subtask decomposition is purely internal (`.claude/decomposition/` YAML). No changes needed there for sub-issue creation, but if the feature was to sync decomposition subtasks to the tracker, the same gap applies.
