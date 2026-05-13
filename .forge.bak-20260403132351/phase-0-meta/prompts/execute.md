# Phase 7: Execution Prompt

## Context
You are implementing 5 fixes for the ceos-agents scaffold pipeline based on real-world user feedback. All changes are to markdown files (agent definitions and skill orchestration). No runtime code exists.

## Pre-Execution Checklist
- [ ] Read each target file before editing
- [ ] Preserve exact formatting, indentation, and section structure
- [ ] Follow CLAUDE.md conventions: agent section order (Goal > Expertise > Process > Constraints), skill step numbering
- [ ] Do not modify frontmatter in agent files
- [ ] Do not break existing cross-references

## Task Execution Instructions

### Task 1: Fix Story Sub-Issue Linking
**File:** `skills/scaffold/SKILL.md`
**Location:** Step 4e, story creation block (find "If tracker supports native sub-issues")

Replace the current vague instruction with explicit per-tracker parameter specification:

```markdown
- **If tracker supports native sub-issues** (see Sub-Issue Capabilities in `docs/reference/trackers.md`): create the story as a sub-issue by passing the parent parameter explicitly in the MCP create-issue tool call:

  | Tracker | Parent parameter to pass | Example |
  |---------|-------------------------|---------|
  | YouTrack | `parent: {EPIC-ISSUE-ID}` | `parent: PROJ-42` |
  | Jira | `parent: {EPIC-ISSUE-KEY}`, `issuetype: "Sub-task"` | `parent: PROJ-42` |
  | Linear | `parentId: {EPIC-ISSUE-ID}` | `parentId: abc-123` |
  | Redmine | `parent_issue_id: {EPIC-ISSUE-ID}` | `parent_issue_id: 42` |

  After creating each story, verify the response confirms parent linkage. If the story was created but without parent link, log: `WARN: Story {title} created as {STORY-ID} but parent link to {EPIC-ID} may not have been set. Verify manually in tracker.`
```

### Task 2: Fix Story Closing
**File:** `skills/scaffold/SKILL.md`
**Location:** Step 8b, transition logic item 3 (find "For trackers with native sub-issues")

Replace items 3b and 3c with unified logic:

```markdown
   b. Close all story sub-issues explicitly: read story issue IDs from back-reference comments (`<!-- {TrackerType}: {STORY-ID} -->`) within the epic file. For each story ID, transition to Done using the same `State transitions -> Done` syntax. Do NOT rely on cascade behavior from parent to children — most trackers do not auto-cascade close, and behavior varies by tracker configuration.
```

Remove the old 3b (GitHub/Gitea only) and 3c (cascade assumption) lines entirely.

### Task 3: Add Implementation Comments
**File:** `skills/scaffold/SKILL.md`
**Location:** Between Step 8 (E2E Tests) and Step 8b (Close Tracker Issues). Insert after the "If no E2E Test section -> skip." line.

Add new section:

```markdown
### Step 8a: Post Implementation Comments

**Guard clause — skip this step if ANY of:**
- `tracker_effective_status` is NOT `"ready"`
- `tracker_write_available` is `false`
- No tracker issues were created at Step 4e

If guard triggers → skip silently, continue to Step 8b.

**For each story issue with a back-reference ID in `spec/epics/*.md`:**

1. Collect implementation data for this story:
   - Subtask(s) that map to this story (from architect decomposition `maps_to` field)
   - For each completed subtask: title, files changed, commit hash (from Step 7d commits)
   - Whether the story was blocked (from Step 7 block handler)

2. If story was completed (not blocked): post a comment on the story issue:
   ```
   [ceos-agents] Implementation completed.
   Subtask: {subtask-title}
   Files changed: {comma-separated file list}
   Commit: {commit-hash}
   ```
   If multiple subtasks contributed to this story, list each on a separate line.

3. If story was blocked: post a comment on the story issue:
   ```
   [ceos-agents] Implementation blocked.
   Agent: {blocking agent}
   Reason: {block reason}
   ```

**For each epic issue with a back-reference ID:**

Post a summary comment on the epic issue:
```
[ceos-agents] Epic implementation summary.
Stories implemented: {N}/{M}
{for each story: - {story-title}: {DONE | BLOCKED}}
```

**On failure:** WARN (`Could not post comment on {issue_id}: {error}`), continue to next issue. Do NOT block the pipeline for comment failures.
```

### Task 4: Improve Design Quality
**File 1:** `agents/spec-writer.md`
- In the Process section, after step 3 (generate specification), add a new step about Design & UX for web projects
- In the Constraints section, add a constraint about web project design

**File 2:** `agents/scaffolder.md`
- Add a design system batch between Batch 1 and Batch 2
- Add a design system check to the quality scorecard

### Task 5: Add Language Fidelity
**File 1:** `agents/spec-writer.md`
- Add a constraint about preserving diacritics and non-ASCII characters

**File 2:** `skills/scaffold/SKILL.md`
- Add a language fidelity instruction at the beginning of Step 4e (after guard clause, before iteration)

## Post-Execution
1. Run `./tests/harness/run-tests.sh` to verify structural integrity
2. Review each modified file to confirm formatting is preserved
3. Verify no unintended changes to adjacent sections
