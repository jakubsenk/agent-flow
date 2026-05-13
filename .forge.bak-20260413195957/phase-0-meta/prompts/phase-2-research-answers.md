# Phase 2: Research Answers

## Objective
Answer every question from Phase 1 by deep-reading all agents, skills, and core contracts. Produce a comprehensive audit document.

## Method
1. Read every agent file in `agents/` (19 files)
2. Read every pipeline skill: `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md`
3. Read every core contract in `core/` (11 files)
4. Read `state/schema.md`
5. Cross-reference: for each agent, find every place it's dispatched in the 4 pipeline skills

## Required Outputs

### Output 1: Agent Dispatch Matrix
Create a table: Pipeline x Agent x Step x Context x Model

Columns: Pipeline | Step | Agent | Model | Context Passed | Conditional?

Must cover: fix-ticket (all steps), fix-bugs (all steps), implement-feature (all steps), scaffold (all steps including legacy --no-implement flow)

### Output 2: Shared Agent Cross-Mode Report
For each shared agent, produce:
```
Agent: {name}
Pipelines: {list}
Mode-specific context differences:
  - Bug: {what context}
  - Feature: {what context}
  - Scaffold: {what context}
Mode adequacy:
  - Bug: {OK / ISSUE: description}
  - Feature: {OK / ISSUE: description}
  - Scaffold: {OK / ISSUE: description}
```

### Output 3: Per-Agent Quality Scorecard
For each of the 19 agents:
```
Agent: {name} (model: {model})
Goal clarity: {1-5} — {note}
Process completeness: {1-5} — {note}
Constraint coverage: {1-5} — {note}
Output format quality: {1-5} — {note}
Mode awareness: {1-5} — {note}
Overall: {1-5}
Recommendations: {list}
```

### Output 4: Core Contract Assessment
For each core contract:
```
Contract: {name}
Referenced by: {list of skills}
Mode assumptions: {any single-mode assumptions found}
Completeness: {OK / ISSUE}
Recommendations: {list}
```

### Output 5: State Schema Assessment
```
Field overloading: {list of fields reused with different semantics}
Missing fields: {list of fields needed but absent}
Scaffold-specific gaps: {list}
Recommendations: {list}
```

### Output 6: Consistency Findings
```
Duplicated code: {list of duplicated sections across skills}
Inconsistencies: {list of behavior differences that should be consistent}
Template inconsistencies: {list}
```

### Output 7: Prioritized Findings Summary
Rank all findings by impact (HIGH/MEDIUM/LOW):
- HIGH: Issues that could cause pipeline failures or incorrect behavior
- MEDIUM: Quality gaps, missing best practices, content weaknesses
- LOW: Cosmetic, documentation, minor improvements
