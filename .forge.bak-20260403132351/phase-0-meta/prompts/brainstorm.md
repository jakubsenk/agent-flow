# Phase 3: Brainstorm

## Issue 1: Design Quality

### Approach A: Scaffolder-only fix
Add a new batch to scaffolder.md for web projects that installs and configures a CSS framework (Tailwind CSS or similar), generates base layout/styles, and includes responsive defaults.

**Pros:** Direct fix at the generation point. Immediately visible improvement.
**Cons:** Scaffolder already generates 10-20 files. Adding design files increases complexity. Hard to pick the "right" CSS framework generically.

### Approach B: Spec-writer enhancement (RECOMMENDED)
Add a "Design & UX" section to spec-writer's spec template for web/frontend/fullstack projects. This section captures: CSS framework preference, design system (colors, typography, spacing), responsive requirements, and accessibility level. The scaffolder then reads this from the spec and generates accordingly.

**Pros:** Design decisions are captured in the spec (source of truth). Scaffolder gets explicit guidance rather than guessing. User can review/edit design choices at the spec checkpoint.
**Cons:** Two files to modify instead of one.

### Approach C: Agent Override pattern
Create a default "design-advisor" agent override that gets injected into scaffolder for web projects.

**Pros:** Clean separation. No changes to core agents.
**Cons:** Overcomplicates for what should be a standard feature. Agent overrides are for project-specific customization, not plugin defaults.

**Decision:** Approach B — spec-writer enhancement with scaffolder follow-through. This keeps design decisions in the spec where the user can review them.

## Issue 2: Story Linking

### Approach A: Explicit parameter per tracker in Step 4e (RECOMMENDED)
Replace the vague "using the tracker's native parent parameter" with explicit per-tracker MCP tool call examples showing the exact parameter name and format.

**Pros:** Eliminates ambiguity. LLM has exact parameter name to use.
**Cons:** Slightly verbose. Must be kept in sync with trackers.md.

### Approach B: Reference trackers.md explicitly
Add "Read the parent parameter from the Sub-Issue Capabilities table in docs/reference/trackers.md" to Step 4e.

**Pros:** Single source of truth.
**Cons:** Still requires the LLM to look up and apply the info correctly. Adds a read step.

**Decision:** Approach A with a reference back to trackers.md. Be explicit about the parameter name inline but note the source.

## Issue 3: Story Closing

### Approach A: Always explicitly close all stories (RECOMMENDED)
Remove the cascade assumption entirely. For ALL trackers, explicitly close each story sub-issue. Unify the behavior across tracker types.

**Pros:** Correct behavior guaranteed. Simpler logic (no tracker-type branching for close behavior).
**Cons:** Extra API calls for trackers that might cascade (but harmless — closing an already-closed issue is a no-op).

### Approach B: Keep cascade for some trackers
Research which trackers actually cascade and only explicitly close for those that don't.

**Pros:** Fewer API calls.
**Cons:** Fragile — cascade behavior depends on tracker configuration, not just tracker type. Not worth the complexity.

**Decision:** Approach A — always close explicitly.

## Issue 4: Implementation Comments

### Approach A: New Step 8a before close (RECOMMENDED)
Add a "Step 8a: Post Implementation Comments" between Step 8/E2E and Step 8b/Close. For each completed story, post a comment with: what was implemented, files changed, commit hash.

**Pros:** Clear audit trail. Fits naturally in the pipeline flow. Uses existing `[ceos-agents]` prefix convention.
**Cons:** Additional API calls per story.

### Approach B: Comment during Step 7 per subtask
Post a comment on the story issue after each subtask commits in Step 7d.

**Pros:** More granular — each subtask gets its own comment.
**Cons:** One story may be implemented across multiple subtasks. Frequent small comments may be noisy. More complex to implement (need story-to-subtask mapping during implementation).

**Decision:** Approach A — single summary comment per story after all implementation is done. Cleaner and more useful for human review.

## Issue 5: Diacritics Preservation

### Approach A: Constraint in spec-writer + scaffold SKILL.md (RECOMMENDED)
Add a language fidelity constraint to spec-writer and to scaffold SKILL.md Step 4e. When user input contains non-ASCII characters (diacritics, accents, CJK, etc.), agents must preserve them exactly.

**Pros:** Targets the two points where text flows from user input to persistent output (spec files and tracker issues).
**Cons:** Cannot guarantee LLM compliance — but explicit instruction significantly improves compliance.

### Approach B: Broad constraint across all agents
Add the constraint to every agent definition.

**Pros:** Comprehensive.
**Cons:** Most agents don't produce user-facing text with locale sensitivity. Unnecessary noise in agents that only deal with code.

**Decision:** Approach A — targeted constraint where it matters most.
