# Phase 3: Brainstorm

## Persona

You are a design-minded plugin architect weighing implementation approaches for a well-specified migration task. You focus on consistency, maintainability, and minimal disruption.

## Task Instructions

Explore implementation approaches for the three v6.4.4 items. The scope is narrow (PATCH), so focus on execution strategy rather than feature design.

### Brainstorm Topics

**Item 1: Bare Path Migration — Resolution Placement Strategy**

The key design question: where to place the Glob resolution block in files with multiple references.

- **Option A: Resolve-once at file top.** Add a "Path Resolution" preamble section near the top of each file. All subsequent references use the resolved path variable. Pros: DRY, matches check-setup pattern. Cons: adds a section that feels out of place in wizard-style skills (onboard).
- **Option B: Resolve-once at first reference.** Put the full Glob resolution block at the first `trackers.md` reference in the file. Subsequent references say "using the trackers.md path resolved in Step N." Pros: natural reading order. Cons: ties resolution to a specific step.
- **Option C: Resolve at each reference.** Each bare reference gets its own Glob resolution. Pros: self-contained steps. Cons: massive duplication (6x in onboard alone), contradicts the check-setup pattern.

Recommendation needed: Which option best fits each file's structure?

**Item 2: error_type — Classification Location**

- **Option A: Classify in Process section.** Add a classification step between steps 3 and 4 that maps error strings to error_type. Output Contract gains the new field.
- **Option B: Classify in Failure Handling.** Move classification logic to Failure Handling section, which already handles error cases.
- **Option C: Classify inline in each failure case.** Each failure case in Process/Failure Handling sets its own error_type.

**Item 3: Step 10 TLS — Scope of Mirroring**

- Should Step 10 be an exact copy of Step 9's error classification, or should it be adapted for SC-specific error patterns?
- SC connectivity uses repository metadata fetch, not bug query — are the error patterns the same?

### Constraints

- PATCH version — no breaking changes
- Must be consistent with existing check-setup v6.4.3 patterns
- Plugin is read by LLMs — clarity and readability matter more than DRYness at the macro level

## Success Criteria

- Clear recommendation for each brainstorm topic with rationale
- Identified risks and mitigations for each approach
- Final direction ready for spec phase

## Anti-Patterns

- Do NOT over-engineer — this is a PATCH migration, not a redesign
- Do NOT propose changes outside the 3 roadmap items
- Do NOT introduce new abstractions or shared resolution utilities

## Codebase Context

- `skills/onboard/SKILL.md`: wizard-style skill with 9 steps. trackers.md references in Steps 2 (5 refs) and 4b (1 ref)
- `skills/scaffold/SKILL.md`: complex multi-phase skill. trackers.md references in Steps 0-INFRA, 0-MCP, 4b, 4e
- `skills/init/SKILL.md`: setup skill. 1 trackers.md reference in Step 0
- `core/mcp-detection.md`: shared contract. 1 trackers.md reference in Process step 1
- `skills/check-setup/SKILL.md`: reference implementation. Resolves in Step 3a, reuses in Step 7
