# Formal Acceptance Criteria: Decomposition Subtask Tracker Creation (v6.4.0)

Each criterion is uniquely numbered, testable via grep or structural checks on the markdown files, and maps to a specific requirement from `requirements.md`.

---

## FC-1: Step Placement in implement-feature

**Criterion:** `skills/implement-feature/SKILL.md` SHALL contain a heading `### 5a. Create tracker subtasks` (or `### Step 5a`) that appears AFTER the heading containing "Decomposition decision" (Step 5) and BEFORE the heading containing "Subtask execution" (Step 6).

**Verification:**
```bash
grep -n "### 5a\." skills/implement-feature/SKILL.md
# Must return exactly one match
# Line number must be > line of "### 5. Decomposition"
# Line number must be < line of "### 6. Subtask execution"
```

**Maps to:** REQ-1.1

---

## FC-2: Step Placement in fix-ticket

**Criterion:** `skills/fix-ticket/SKILL.md` SHALL contain a heading `### 4b-tracker. Create tracker subtasks` (or equivalent) that appears AFTER the heading containing "Decomposition decision" (Step 4b) and BEFORE the heading containing "Subtask execution" (Step 4c).

**Verification:**
```bash
grep -n "4b-tracker" skills/fix-ticket/SKILL.md
# Must return at least one match
# Line number must be > line of "### 4b. Decomposition"
# Line number must be < line of "### 4c. Subtask execution"
```

**Maps to:** REQ-1.2

---

## FC-3: Step Placement in fix-bugs

**Criterion:** `skills/fix-bugs/SKILL.md` SHALL contain a heading `### 3b-tracker. Create tracker subtasks` (or equivalent) that appears AFTER the heading containing "Decomposition decision" (Step 3b) and BEFORE the heading containing "Subtask execution" (Step 3c).

**Verification:**
```bash
grep -n "3b-tracker" skills/fix-bugs/SKILL.md
# Must return at least one match
# Line number must be > line of "### 3b. Decomposition"
# Line number must be < line of "### 3c. Subtask execution"
```

**Maps to:** REQ-1.3

---

## FC-4: Triple Gate in All Three Skills

**Criterion:** Each of the three skill files SHALL contain ALL THREE gate conditions in the new step:
1. The string `decomposition.decision` with value `"DECOMPOSE"` (or equivalent check)
2. The string `Create tracker subtasks` with value `disabled` (or check for enabled/disabled)
3. The string `tracker_effective_status` with value `"ready"` (or equivalent check)

**Verification:**
```bash
# For each of the 3 skill files:
grep -c "decomposition.decision" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must be >= 1 in each (existing + new step)
grep -c "Create tracker subtasks" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must be >= 1 in each (new step)
grep -c "tracker_effective_status" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must be >= 1 in each (new step)
```

**Maps to:** REQ-1.1, REQ-1.2, REQ-1.3, design.md Section 8

---

## FC-5: Per-Tracker Parent Parameters

**Criterion:** Each of the three skill files SHALL contain a table or list documenting the parent parameter for ALL SIX tracker types:
- YouTrack: `parent: {PARENT-ISSUE-ID}`
- Jira: `parent: {PARENT-ISSUE-KEY}` and `issuetype: "Sub-task"`
- Linear: `parentId: {PARENT-ISSUE-ID}`
- Redmine: `parent_issue_id: {PARENT-ISSUE-ID}`
- GitHub: standalone issue with `[{PARENT-ISSUE-ID}]` title prefix
- Gitea: standalone issue with `[{PARENT-ISSUE-ID}]` title prefix

**Verification:**
```bash
# For each of the 3 skill files:
grep "parent:" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md | grep -i youtrack
grep "issuetype.*Sub-task" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
grep "parentId:" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
grep "parent_issue_id:" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Each grep must return at least one match per file
```

**Maps to:** REQ-2.1 through REQ-2.7

---

## FC-6: Jira Nested Sub-Task Guard

**Criterion:** Each of the three skill files SHALL contain text describing the Jira edge case: when the parent issue is of type "Sub-task", the system creates a flat issue without parent link and logs a WARN.

**Verification:**
```bash
grep -l "Sub-task.*flat issue\|flat issue.*Sub-task\|parent.*Sub-task.*WARN\|Sub-task.*without parent" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files
```

**Maps to:** REQ-2.3

---

## FC-7: tracker_issue_id in State Schema

**Criterion:** `state/schema.md` SHALL contain a row in the Subtask Object Fields table with:
- Field name: `tracker_issue_id`
- Type: `string or null`
- Default: `null`

**Verification:**
```bash
grep "tracker_issue_id" state/schema.md
# Must return at least one match
# Must NOT contain "tracker_id" as a separate field (field name collision check)
grep "tracker_id[^_]" state/schema.md
# Must return zero matches (no bare tracker_id field)
```

**Maps to:** REQ-4.1, REQ-4.3

---

## FC-8: tracker_issue_id in YAML Write Instructions

**Criterion:** Each of the three skill files SHALL contain `tracker_issue_id: null` as part of the initial YAML subtask fields written during the decomposition decision step (existing step, not the new step).

**Verification:**
```bash
grep "tracker_issue_id.*null\|tracker_issue_id" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return at least one match per file
```

**Maps to:** REQ-4.2

---

## FC-9: Config Key in CLAUDE.md

**Criterion:** `CLAUDE.md` SHALL contain `Create tracker subtasks` in the Decomposition optional keys table within the Config Contract section. The default SHALL be `enabled`.

**Verification:**
```bash
grep "Create tracker subtasks" CLAUDE.md
# Must return at least one match
grep -A1 "Create tracker subtasks" CLAUDE.md | grep "enabled"
# Must return at least one match confirming default
```

**Maps to:** REQ-5.1, REQ-5.3

---

## FC-10: Config Key in automation-config.md

**Criterion:** `docs/reference/automation-config.md` SHALL contain `Create tracker subtasks` in the Decomposition section with description mentioning `enabled` and `disabled` values.

**Verification:**
```bash
grep "Create tracker subtasks" docs/reference/automation-config.md
# Must return at least one match
```

**Maps to:** REQ-5.1

---

## FC-11: Idempotency Algorithm (YAML-first, state.json fallback)

**Criterion:** Each of the three skill files SHALL describe the idempotency check in this order:
1. Read `tracker_issue_id` from YAML -- if non-null, skip
2. Read `tracker_issue_id` from state.json -- if non-null, recover and skip
3. Create via MCP

The text SHALL contain the words "YAML" and "state.json" and "fallback" (or "recover") in the step description.

**Verification:**
```bash
# For each of the 3 skill files, within the new step section:
grep -l "YAML.*state.json\|state.json.*fallback\|state.json.*recover" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files
```

**Maps to:** REQ-3.1, REQ-3.2, REQ-3.3

---

## FC-12: Partial Failure Accumulator Pattern

**Criterion:** Each of the three skill files SHALL contain text specifying:
1. On individual failure: WARN and continue
2. After loop: display `"Created {N}/{M} tracker sub-issues"`
3. On 100% failure: elevated WARN about connectivity
4. Pipeline NEVER blocks on tracker creation failure

**Verification:**
```bash
grep -l "NEVER block\|never block\|Pipeline continues" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files
grep -l "Created.*tracker sub-issues" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files
```

**Maps to:** REQ-6.1 through REQ-6.4

---

## FC-13: GitHub/Gitea Checklist with Sentinel

**Criterion:** Each of the three skill files SHALL contain the sentinel comment format `<!-- ceos-agents:decomposition-checklist:{ISSUE-ID} -->` (or the pattern `ceos-agents:decomposition-checklist`) and describe the checklist format with `- [ ]` checkboxes.

**Verification:**
```bash
grep -l "ceos-agents:decomposition-checklist" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files
grep -l "\- \[ \].*#" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files
```

**Maps to:** REQ-7.1, REQ-7.2

---

## FC-14: Single Git Commit After Creation Loop

**Criterion:** Each of the three skill files SHALL specify a single `git commit` for the tracker issue IDs with a message containing "link decomposition subtasks to tracker" (or equivalent). The commit SHALL happen AFTER the entire creation loop, not per-subtask.

**Verification:**
```bash
grep -l "git commit.*link decomposition\|git commit.*tracker" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files
```

**Maps to:** design.md Section 7

---

## FC-15: maps_to in Sub-Issue Description

**Criterion:** Each of the three skill files SHALL specify that the sub-issue description includes `maps_to` references (the "Addresses:" line) for traceability to parent acceptance criteria.

**Verification:**
```bash
grep -l "maps_to\|Addresses:" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files (existing maps_to references + new step)
```

**Maps to:** REQ-2.8

---

## FC-16: Resume Ticket Awareness

**Criterion:** `skills/resume-ticket/SKILL.md` SHALL reference `tracker_issue_id` in the context of the `DECOMPOSE_PARTIAL` checkpoint, indicating that existing tracker issue IDs are preserved on resume.

**Verification:**
```bash
grep "tracker_issue_id" skills/resume-ticket/SKILL.md
# Must return at least one match
```

**Maps to:** REQ-8.1

---

## FC-17: No tracker_id Field Name (Naming Guard)

**Criterion:** NONE of the implementation files SHALL introduce a field named `tracker_id` (without the `_issue` suffix). The field name is `tracker_issue_id` everywhere.

**Verification:**
```bash
# Check that no new bare tracker_id field is introduced
grep -r "tracker_id[^_]" state/schema.md skills/implement-feature/SKILL.md skills/fix-ticket/SKILL.md skills/fix-bugs/SKILL.md
# Existing Redmine references (tracker_id as issue TYPE parameter) are acceptable in docs/reference/trackers.md
# New files must NOT introduce tracker_id as a field name
```

**Maps to:** REQ-4.3

---

## FC-18: Dual-Store Write Order

**Criterion:** Each of the three skill files SHALL specify that state.json is written IMMEDIATELY after each successful MCP creation (per-subtask, atomic), while YAML is committed once after the entire loop.

**Verification:**
```bash
grep -l "state.json.*immediately\|state.json.*atomic\|atomic write protocol" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files (existing references + new step)
```

**Maps to:** REQ-3.3, design.md Section 6

---

## Acceptance Criteria Summary

| ID | Description | Verification Method | Maps to |
|----|-------------|--------------------|---------| 
| FC-1 | Step 5a in implement-feature | grep heading position | REQ-1.1 |
| FC-2 | Step 4b-tracker in fix-ticket | grep heading position | REQ-1.2 |
| FC-3 | Step 3b-tracker in fix-bugs | grep heading position | REQ-1.3 |
| FC-4 | Triple gate in all 3 skills | grep 3 conditions | REQ-1.x |
| FC-5 | Per-tracker parent parameters | grep 6 tracker patterns | REQ-2.x |
| FC-6 | Jira nested sub-task guard | grep Sub-task flat issue | REQ-2.3 |
| FC-7 | tracker_issue_id in schema | grep state/schema.md | REQ-4.1 |
| FC-8 | tracker_issue_id in YAML init | grep YAML null init | REQ-4.2 |
| FC-9 | Config key in CLAUDE.md | grep config contract | REQ-5.1 |
| FC-10 | Config key in automation-config.md | grep docs | REQ-5.1 |
| FC-11 | Idempotency algorithm | grep YAML+state.json pattern | REQ-3.x |
| FC-12 | Partial failure accumulator | grep never-block + display | REQ-6.x |
| FC-13 | GitHub/Gitea checklist sentinel | grep sentinel pattern | REQ-7.x |
| FC-14 | Single git commit | grep commit message | design |
| FC-15 | maps_to in description | grep Addresses/maps_to | REQ-2.8 |
| FC-16 | Resume ticket awareness | grep tracker_issue_id in resume | REQ-8.1 |
| FC-17 | No tracker_id naming collision | grep negative check | REQ-4.3 |
| FC-18 | Dual-store write order | grep atomic write | REQ-3.3 |
