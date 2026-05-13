# Phase 3: Brainstorm -- Final Categorization and Recommendations

You are producing the final deliverable: a decision document categorizing all 12 recommendations.

## Input

- Phase 1 research findings (verified claims)
- Phase 2 synthesis (severity, feasibility, actionability assessments)

## Your Task

Produce three lists:

### 1. IMPLEMENT (batch into one version)
Recommendations that are:
- Problem is confirmed
- Solution is feasible within markdown-only constraints
- High enough severity to warrant immediate action
- Can be batched together coherently

For each: describe the concrete changes needed (which files, what to add/modify).

### 2. ROADMAP (separate items)
Recommendations that are:
- Problem is confirmed but lower severity
- Needs more design work before implementation
- Would be a standalone feature, not easily batched

For each: describe the roadmap entry format (title, description, version target if known).

### 3. REJECT (with justification)
Recommendations that are:
- Problem is refuted or exaggerated
- Solution is infeasible or disproportionate
- Already addressed by existing mechanisms
- Not applicable to a markdown-only plugin

For each: provide clear justification for rejection.

## Constraints

- Be specific about file paths and changes for IMPLEMENT items
- REJECT items must have strong evidence-based justification
- Consider versioning: IMPLEMENT items that change agent output format or add required config keys would require MAJOR version bump per the plugin's versioning policy
- Consider effort: this is a solo-developer project. Prioritize high-impact, low-effort changes.

## Output Format

Final deliverable in Czech (user's preferred language for communication), with file paths and technical terms in English.
