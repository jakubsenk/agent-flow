# Agent 1 Research Findings

## RQ-1: YouTrack Sub-Issue Parent Parameter via MCP

### Source: `docs/reference/trackers.md` — Sub-Issue Capabilities table

The Sub-Issue Capabilities table (lines 88–97) defines how each tracker handles parent parameters:

```
| Tracker  | Native sub-issues | Parent parameter                           | Fallback strategy |
|----------|-------------------|--------------------------------------------|-------------------|
| youtrack | Yes               | `parent: {issue-id}`                       | N/A               |
| jira     | Yes               | `parent: {key}`, `issuetype: "Sub-task"`   | N/A               |
| linear   | Yes               | `parentId: {id}`                           | N/A               |
| redmine  | Yes               | `parent_issue_id: {id}`                    | N/A               |
| github   | No                | N/A                                        | Standalone issue: `[{epic_title}] {story_title}`, cross-reference in description |
| gitea    | No                | N/A                                        | Standalone issue: `[{epic_title}] {story_title}`, cross-reference in description |
```

The note beneath the table states:
> "The parent parameter names are MCP tool conventions. The LLM uses these when invoking the tracker's MCP create-issue tool."

**Conclusion for YouTrack:** The MCP tool convention for YouTrack is `parent: {issue-id}`. This is the parameter name the LLM is instructed to pass when calling the YouTrack MCP server's create-issue tool to create a sub-issue under an epic.

### Source: `skills/scaffold/SKILL.md` — Step 4e, Story creation logic

The exact wording in Step 4e (lines covering story creation within the epic iteration loop):

> "**If tracker supports native sub-issues** (YouTrack, Jira, Linear, Redmine — see Sub-Issue Capabilities in `docs/reference/trackers.md`): create sub-issue with parent set to epic issue ID using the tracker's native parent parameter"

> "**If tracker does NOT support native sub-issues** (GitHub, Gitea): create standalone issue with title `[{epic_title}] {story_title}`, add cross-reference to epic issue in description"

The skill delegates the exact parameter name lookup to `docs/reference/trackers.md`, which specifies `parent: {issue-id}` for YouTrack. The skill itself describes the intent ("create sub-issue with parent set to epic issue ID using the tracker's native parent parameter") rather than hardcoding the parameter name.

---

## RQ-2: YouTrack Cascade Close Behavior

### Source: `skills/scaffold/SKILL.md` — Step 8b: Close Tracker Issues

Step 8b has explicit cascade close logic. The exact lines (within the "Transition logic" section, step 3):

> "b. For GitHub/Gitea (standalone story issues): also close each story issue individually. Read story IDs from back-reference comments within the epic file."

> "c. For trackers with native sub-issues (YouTrack, Jira, Linear, Redmine): closing the parent epic typically cascades to children. Do NOT explicitly close story sub-issues."

**Conclusion:** Yes, Step 8b explicitly assumes YouTrack cascades close from parent to children. The skill only closes the epic-level issue for YouTrack (and other native sub-issue trackers: Jira, Linear, Redmine). It does NOT close story sub-issues individually, relying on YouTrack's cascade behavior. The word "typically" signals this is an assumption about tracker behavior, not a guarantee — but the action taken ("Do NOT explicitly close story sub-issues") is unconditional for these trackers.

The guard clause for Step 8b specifies it only runs when:
- `tracker_effective_status` is `"ready"`
- `tracker_write_available` is not `false`
- Back-reference comments (`<!-- {TrackerType}: ... -->`) exist in spec epic files (i.e., Step 4e ran and created issues)
- `State transitions` value from Automation Config contains a `Done` mapping

If the `Done` mapping is missing, it displays: `WARN: State transitions does not include a 'Done' mapping. Skipping issue closure.`
