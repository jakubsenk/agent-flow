# Agent 1 Research Findings

## RQ-1: Story Extraction from Epic Markdown

### Finding

Epic files follow a rigid, machine-parseable structure. Stories are delimited by `---` horizontal rules and use `### Story N.M: Title` as the heading. Each story contains a user-story sentence and an `**Acceptance Criteria:**` section listing bullet items in either Given/When/Then or MUST: rule format.

### Evidence

File: `C:/Users/FSABACKY/claude/licence-ceos-agents-yt/spec/epics/01-project-setup.md`

```markdown
# Epic 01: Project Setup and Data Model
<!-- YouTrack: LIC-3 -->

## Description
...

## Priority: must

## Dependencies: none

---

### Story 1.1: Initialize Vite + React + TypeScript Project

**As** a developer, **I want** a working Vite project scaffold with React 19 and TypeScript, **so that** I can start building features immediately.

**Acceptance Criteria:**

- Given the project is cloned and `pnpm install` is run, When `pnpm dev` is executed, Then Vite dev server starts ...
- MUST: `package.json` includes React 19, Vite 6, TypeScript 5.5+, ...

---

### Story 1.2: Define Core TypeScript Types
...
```

**Exact structural rules observed across all 6 epic files:**

1. **Epic heading:** `# Epic NN: Title` at line 1
2. **Back-reference comment:** `<!-- YouTrack: {ISSUE-ID} -->` at line 2 (immediately after heading)
3. **Epic metadata:** `## Description`, `## Priority`, `## Dependencies` sections
4. **Epic/story separator:** `---` (bare horizontal rule)
5. **Story heading level:** `### Story N.M: Title` (H3, always `Story` keyword, dot-separated numbering)
6. **Story user sentence:** `**As** ... **I want** ... **so that** ...` paragraph
7. **AC section:** `**Acceptance Criteria:**` followed by bullet list
8. **Story separator:** `---` ends each story (including the last one before the next story)

### Implication

Parsing boundary is unambiguous: split on `\n---\n` to get story blocks, then match `### Story N.M:` heading to detect stories vs. the epic header block. The `---` separator is reliable — every story in all 6 files ends with one, including the final story in the file.

---

## RQ-2 (sub-question from RQ-1): Sub-Issue Title vs Description

### Finding

The story title (`### Story N.M: Title text`) maps to the sub-issue title. The full story body (user-story sentence + Acceptance Criteria bullets) maps to the sub-issue description.

### Evidence

From `skills/scaffold/SKILL.md` Step 4e, lines 519–524:

```
1. Iterate over spec/epics/*.md files (sorted by filename prefix):
   - For each epic file:
     a. Create an epic-level issue in the tracker project (title from epic heading, description from epic content).
     ...
     c. For each user story within the epic: create a sub-issue under the epic issue.
     d. Write the created issue ID back into the spec file as a reference comment.
```

The skill says "title from epic heading" for the epic-level issue. By analogy, story title maps to sub-issue title and story body (user sentence + AC) maps to sub-issue description. The spec-writer agent process step 8 also uses `spec/epics/{list} — {count} epics, {total stories} user stories` confirming stories are discrete units.

### Implication

When creating sub-issues in Step 4e: extract `### Story N.M: {title}` as issue title, and the full markdown body (everything from the user-story sentence to the closing `---`) as the description. Strip the `---` separator itself from the description body.

---

## RQ-3 (sub-question from RQ-1): Back-Reference Comment Format

### Finding

Epic back-references use `<!-- YouTrack: {ISSUE-ID} -->` on line 2 of the file, immediately after the `# Epic NN: Title` heading. This is a tracker-agnostic HTML comment with `<!-- {TrackerType}: {ID} -->` pattern.

### Evidence

All 6 epic files in the evidence project:

```
C:/Users/FSABACKY/claude/licence-ceos-agents-yt/spec/epics/01-project-setup.md:  <!-- YouTrack: LIC-3 -->
C:/Users/FSABACKY/claude/licence-ceos-agents-yt/spec/epics/02-people-management.md: <!-- YouTrack: LIC-4 -->
C:/Users/FSABACKY/claude/licence-ceos-agents-yt/spec/epics/03-license-management.md: <!-- YouTrack: LIC-5 -->
C:/Users/FSABACKY/claude/licence-ceos-agents-yt/spec/epics/04-dashboard.md: <!-- YouTrack: LIC-6 -->
C:/Users/FSABACKY/claude/licence-ceos-agents-yt/spec/epics/05-usage-tracking.md: <!-- YouTrack: LIC-7 -->
C:/Users/FSABACKY/claude/licence-ceos-agents-yt/spec/epics/06-excel-export.md: <!-- YouTrack: LIC-8 -->
```

Step 4e in `skills/scaffold/SKILL.md` line 524 confirms: "Write the created issue ID back into the spec file as a reference comment."

The analogous format for **story** back-references does not yet exist in the codebase — Step 4e only mentions writing the epic-level ID back, not story-level IDs. The skill says "created issue ID" (singular) per epic file, with no mention of per-story comment writeback.

### Implication

For stories, the analogous comment format would be `<!-- YouTrack: {STORY-ISSUE-ID} -->` inserted immediately after `### Story N.M: {title}`. However, the current Step 4e specification has a **gap**: it does not specify where or how sub-issue IDs are written back. This needs to be defined in the fix. A natural placement is the line immediately following the `### Story N.M:` heading, mirroring the epic pattern.

---

## RQ-4 (= RQ-5 in task spec): Test Coverage for Step 4e

### Finding

There are **no tests** that verify sub-issue creation logic. The only test referencing Step 4e is a **structural presence check** — it verifies that the text "Create Tracker Issues" appears in `skills/scaffold/SKILL.md`. No test validates the actual sub-issue creation behavior, the back-reference writeback, partial failure handling, or the iteration logic over stories within epics.

### Evidence

**Test 1 — scaffold-v2-happy-path.sh, lines 104–108:**
```bash
# Step 4e: Create Tracker Issues present
if ! grep -q "Create Tracker Issues" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing Step 4e: Create Tracker Issues"
  exit 1
fi
```
This only checks that the heading string exists in the file.

**Test 2 — scaffold-v2-no-implement.sh, lines 37–40:**
```bash
if ! grep -q "Create issues in your issue tracker" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md legacy report missing v3.x next steps"
  exit 1
fi
```
This checks the `--no-implement` legacy flow mentions issue creation in next-steps prose — not the actual Step 4e logic.

**Test 3 — scaffold-v561-regression.sh:** Does not reference Step 4e or tracker issue creation at all.

No other test scenario files match `4e|tracker issue|sub.issue|subissue` patterns (grep confirmed across all 39 `.sh` files in `tests/scenarios/`).

**Test format used (from harness):** All tests are bash scripts using `grep -q` pattern checks against the skill/agent markdown files. There is no runtime execution or mock MCP server interaction for scaffold-specific tracker calls.

### Implication

The fix to Step 4e (adding sub-issue creation specification) will require a new or updated test scenario. The existing `scaffold-v2-happy-path.sh` test only validates that the section heading exists. A new test should verify that:
1. The sub-issue creation instruction is present in Step 4e text.
2. The story back-reference writeback format is defined.
3. The iteration pattern (per-story within each epic) is specified.

The test can follow the same grep-based pattern used in the existing scaffold tests — no mock MCP execution is needed since all scaffold tests are static markdown analysis tests.
