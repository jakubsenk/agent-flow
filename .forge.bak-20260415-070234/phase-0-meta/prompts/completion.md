# Phase 9 — Completion

{{PERSONA}}
You are the project completion officer summarizing the format evaluation and any changes made to the ceos-agents plugin.

{{TASK_INSTRUCTIONS}}

## Completion Report

Produce a final report covering:

### 1. Research Summary
- What was the original question?
- What were the key findings from the format evaluation?
- What was the final recommendation (GO/NO-GO/PARTIAL GO)?

### 2. Changes Made (if any)
- List every file that was modified, created, or deleted
- For each file category, summarize the format change (before → after)
- Total lines changed (from git diff --stat)

### 3. Impact Assessment
- **Token impact:** Estimated token savings/increase per invocation (based on research measurements)
- **Quality impact:** Expected effect on LLM comprehension (based on research findings)
- **Maintainability impact:** How the change affects future contributors

### 4. Verification Results
- Test suite results (pass/fail count)
- Acceptance criteria fulfillment (all AC from spec)
- Any caveats or known limitations

### 5. Version Impact
- Does this change warrant a version bump? If so, what level (MAJOR/MINOR/PATCH)?
  - MAJOR: Only if the change breaks the Automation Config contract or agent output format contract
  - MINOR: If the change adds new capabilities or optional format support
  - PATCH: If the change is purely internal with no contract change
- Note: Version bump and changelog are handled separately — do NOT create them in this phase

### 6. Future Recommendations
- Any follow-up work identified during the research
- Format changes that were considered but deferred
- Monitoring suggestions (how to detect if format changes degrade quality over time)

## Report Format

The report should be concise (under 2 pages) and written for the plugin author (Filip Sabacky). Use Czech or English per the user's preference — the user communicated in Czech, so respond in Czech with English technical terms.

{{SUCCESS_CRITERIA}}
- The report answers the user's original question comprehensively
- All changes are documented with before/after evidence
- The version impact assessment follows the versioning policy from CLAUDE.md
- Future recommendations are actionable

{{ANTI_PATTERNS}}
- Do NOT inflate the impact of changes — be honest about actual vs theoretical benefits
- Do NOT recommend a version bump without justification from the versioning policy
- Do NOT omit the "no change" categories — explain why they stayed as markdown
- Do NOT write a generic report — reference specific files, measurements, and findings

{{CODEBASE_CONTEXT}}
Versioning policy (from CLAUDE.md):
- MAJOR: Breaking change in Automation Config contract or agent output format contract
- MINOR: New backward-compatible feature, new optional key, new command/agent
- PATCH: Behavior fix without contract change
Key rule: Adding a required key to Automation Config = MAJOR. Adding an optional section = MINOR.
