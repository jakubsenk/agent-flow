# Phase 8: Verification Prompt

## Verification Dimensions

### 1. Correctness (weight: 0.3)

**V-1.1: Step 4e parent parameter accuracy**
- Check that the parent parameter table in Step 4e matches `docs/reference/trackers.md` Sub-Issue Capabilities table exactly
- YouTrack: `parent: {issue-id}`
- Jira: `parent: {key}`, `issuetype: "Sub-task"`
- Linear: `parentId: {id}`
- Redmine: `parent_issue_id: {id}`

**V-1.2: Step 8b cascade removal**
- Confirm the sentence "closing the parent epic typically cascades to children. Do NOT explicitly close story sub-issues" is completely removed
- Confirm the replacement text says to close ALL story issues explicitly for ALL tracker types
- Confirm GitHub/Gitea still works (they had explicit close already — verify this wasn't broken)

**V-1.3: Step 8a comment format**
- Confirm `[ceos-agents]` prefix is used (consistent with Block Comment Template and other pipeline comments)
- Confirm guard clause matches Step 8b's guard clause pattern
- Confirm the step is correctly numbered (8a, between 8 and 8b)

**V-1.4: Design & UX additions**
- Confirm spec-writer process step is correctly numbered (no gaps, no collisions)
- Confirm scaffolder batch is correctly positioned (after core, before config)
- Confirm scorecard check exists

**V-1.5: Language fidelity constraint**
- Confirm constraint is specific (gives examples, not just "preserve characters")
- Confirm it appears in both spec-writer.md and scaffold SKILL.md

### 2. Spec Alignment (weight: 0.2)

**V-2.1:** Each of the 5 requirements (REQ-1 through REQ-5) has corresponding changes in the right files
**V-2.2:** No unnecessary changes to files not listed in the plan
**V-2.3:** No new required Automation Config keys introduced (would require MAJOR version bump)

### 3. Security (weight: 0.3)

**V-3.1:** No sensitive information added (tokens, URLs, credentials)
**V-3.2:** No new file write operations that could be exploited
**V-3.3:** MCP tool call instructions don't expose injection vectors

### 4. Robustness (weight: 0.2)

**V-4.1:** Step 8a has proper guard clause and failure handling (WARN, not BLOCK)
**V-4.2:** Step 4e verification step gracefully handles missing parent link
**V-4.3:** Step 8b unified close logic handles missing story IDs gracefully
**V-4.4:** Design & UX section is conditional (only for web projects, doesn't break CLI/API projects)
**V-4.5:** Language fidelity constraint doesn't conflict with "English for code" convention

## Structural Integrity Checks

- [ ] All agent files preserve frontmatter (name, description, model, style)
- [ ] All agent files preserve section order (Goal > Expertise > Process > Constraints)
- [ ] Scaffold SKILL.md step numbering is consistent (0-INFRA, 0-MCP, 0, 0b, 1, 2, 3, 4, 4a-4e, 5, 6, 7, 7b, 8, 8a, 8b, 9)
- [ ] No dangling cross-references to renamed/removed sections
- [ ] `./tests/harness/run-tests.sh` passes

## Acceptance Gate

All 5 issues addressed:
- [ ] Issue #1: spec-writer has Design & UX section, scaffolder has design batch
- [ ] Issue #2: Step 4e has explicit parent parameters per tracker
- [ ] Issue #3: Step 8b closes stories explicitly for all trackers
- [ ] Issue #4: Step 8a posts implementation comments
- [ ] Issue #5: Language fidelity constraints in spec-writer and Step 4e
