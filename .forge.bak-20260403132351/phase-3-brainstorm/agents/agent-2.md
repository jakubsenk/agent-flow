# Brainstorm: Agent 2 (Innovator Perspective)

**Date:** 2026-04-02
**Role:** Comprehensive, forward-looking solutions that prevent recurrence

---

## Issue 1: Design Quality — No Design/UI Instructions for Web Projects

### Root Cause Behind the Root Cause

The spec-writer agent was designed as a backend-first specification tool. Its section template (vision, goals, tech stack, architecture, data flow, API, NFR, user stories) maps perfectly onto backend services and CLI tools but has a blind spot: it treats the UI as an emergent property of user stories rather than a first-class design artifact. The scaffolder similarly generates build tooling, testing, linting, and CI but has no concept of visual infrastructure (design tokens, theme files, base CSS, component library setup).

This is a **category gap** — the system was designed for one project archetype (API/backend/CLI) and later expanded to support frontend/full-stack without updating the artifact model.

### Proposed Fix: Full Design & UX Section in spec-writer + Scaffolder Design Batch

**A. spec-writer: Add a conditional "Design & UX" section to spec/architecture.md**

Add a new process step (between current steps 3 and 4) that triggers ONLY when the tech stack is frontend or full-stack:

```
## Design & UX (IF APPLICABLE — frontend or full-stack projects only)

### Design System
- **Approach:** {Tailwind CSS | MUI | shadcn/ui | Chakra UI | custom CSS | none}
- **Rationale:** {why this choice fits the project}

### Visual Identity
- **Color palette:** {primary, secondary, accent, neutral — hex values or "defer to implementation"}
- **Typography:** {font family, scale — or "system defaults"}
- **Spacing scale:** {e.g., 4px base unit — or "framework default"}

### Component Strategy
- **Library:** {component library name or "custom"}
- **Key components:** {list of 3-7 primary UI components the project needs}

### Responsive Strategy
- **Breakpoints:** {mobile-first | desktop-first}
- **Target viewports:** {mobile, tablet, desktop — specific widths}

### Accessibility
- **Target level:** {WCAG 2.1 AA | AAA | none specified}
- **Key considerations:** {screen reader support, keyboard navigation, color contrast}
```

Detection logic for "frontend or full-stack": if the Tech Stack section mentions any of: React, Vue, Svelte, Angular, Next.js, Nuxt, SvelteKit, Remix, Astro, HTML, CSS, Tailwind, frontend, web app, SPA, SSR, full-stack. If backend-only or CLI: write `## Design & UX\nNot applicable — this is a {backend API | CLI | library} project.`

**B. scaffolder: Add a conditional Batch 2.5 — Design Infrastructure**

Between Batch 2 (Config & Data) and Batch 3 (Quality), add:

```
**Batch 2.5 — Design (if frontend/full-stack):**
- Design tokens file (tailwind.config.ts / theme.ts / design-tokens.css — based on spec Design & UX section)
- Base layout component or CSS reset (if component library chosen)
- Global styles entry point (src/styles/globals.css or equivalent)
```

This batch is SKIPPED for backend-only and CLI projects.

**C. Prevention mechanism: Stack archetype detection**

Add a reusable "stack archetype" concept to the scaffold pipeline. At Step 2 (spec-writer), after tech stack is chosen, classify the project as one of: `backend-api`, `cli-tool`, `library`, `frontend-spa`, `full-stack-ssr`, `full-stack-api`. Store this as an in-memory value `stack_archetype`. This archetype drives conditional sections in spec-writer, scaffolder, and future agents — so that adding a new archetype-specific feature never requires touching every file individually.

### Impact Assessment

- **Files changed:** `agents/spec-writer.md` (add conditional Design & UX section), `agents/scaffolder.md` (add Batch 2.5), `skills/scaffold/SKILL.md` (add stack archetype detection and pass-through)
- **Versioning:** MINOR bump (new optional behavior, no breaking changes)
- **Risk:** Low. Conditional sections that are skipped for non-frontend projects have zero impact on existing backend scaffolds.

---

## Issue 2: Story Linking — Step 4e Cross-File Lookup for Parent Parameter

### Root Cause Behind the Root Cause

The instruction at `SKILL.md:533` says "using the tracker's native parent parameter" and references `docs/reference/trackers.md` via the phrase "see Sub-Issue Capabilities." This is an LLM instruction reliability problem: when the LLM is executing a complex multi-step workflow (Step 4e iterates over epics and stories), it may not stop mid-iteration to read a reference file. The information IS available but the instruction pattern is fragile.

This is a systemic issue: **any instruction that defers critical action parameters to a cross-file lookup is a reliability risk.** The LLM executes instructions sequentially and under token pressure. Cross-file lookups mid-execution are the weakest link.

### Proposed Fix: Inline Parameter Table + Tracker Interaction Contract

**A. Inline the parent parameter table directly in SKILL.md:533**

Replace the cross-file reference with an inline lookup table:

```markdown
- **If tracker supports native sub-issues:** create sub-issue with parent set to epic issue ID.
  Use the tracker-specific parent parameter:

  | Tracker | Parent parameter(s) |
  |---------|-------------------|
  | youtrack | `parent: {epic-issue-id}` |
  | jira | `parent: {epic-issue-id}`, `issuetype: "Sub-task"` |
  | linear | `parentId: {epic-issue-id}` |
  | redmine | `parent_issue_id: {epic-issue-id}` |
```

**B. Create a Tracker Interaction Contract (`core/tracker-interaction.md`)**

This addresses the systemic issue. Create a new core contract that centralizes all tracker interaction patterns used across the pipeline. Every skill that interacts with the tracker references this contract instead of `trackers.md` (which remains as a human-readable reference doc).

The contract would define:

```markdown
# Tracker Interaction Contract

## Purpose
Centralize all tracker MCP interaction patterns. Skills reference this contract
for reliable tracker operations.

## Create Sub-Issue

| Tracker | MCP parameters |
|---------|---------------|
| youtrack | `parent: {parent-id}` |
| jira | `parent: {parent-id}`, `issuetype: "Sub-task"` |
| linear | `parentId: {parent-id}` |
| redmine | `parent_issue_id: {parent-id}` |
| github | N/A — use standalone issue with `[{parent_title}] {child_title}` prefix |
| gitea | N/A — use standalone issue with `[{parent_title}] {child_title}` prefix |

## Close Issue

| Tracker | MCP operation |
|---------|--------------|
| youtrack | Set state per `State transitions -> Done` |
| jira | `transition:Done` (or per config) |
| linear | `state:Done` (or per config) |
| redmine | `status:Closed` (or per config) |
| github | `close` |
| gitea | `close` |

## Post Comment

| Tracker | Comment format |
|---------|---------------|
| All | Use MCP `add-comment` or equivalent tool. Content: plain text or markdown. |

## Cascade Behavior

**No tracker has guaranteed cascade close by default.** Always close children explicitly.
```

This contract becomes the single source of truth for all tracker interactions. `trackers.md` becomes a human reference doc, and `core/tracker-interaction.md` becomes the LLM instruction doc.

### Impact Assessment

- **Files changed:** `skills/scaffold/SKILL.md` (inline table at line 533), new `core/tracker-interaction.md`
- **Versioning:** PATCH (reliability improvement, no contract change)
- **Risk:** Very low. Inlining a table is the simplest possible fix.

---

## Issue 3: Story Closing — Step 8b Wrongly Assumes Cascade Close

### Root Cause Behind the Root Cause

The instruction at `SKILL.md:743` says "closing the parent epic **typically** cascades to children." This is wrong for ALL four native sub-issue trackers:

- **YouTrack:** No cascade by default. Requires an admin-configured Workflow rule.
- **Jira:** No cascade by default. Requires a post-function in the workflow scheme.
- **Linear:** No cascade. Parent/child states are independent.
- **Redmine:** No cascade. Subtask states are independent.

The word "typically" was a false generalization. The root cause behind this is that the instruction was written based on assumed tracker behavior rather than verified tracker documentation. The system had no mechanism to verify tracker-specific behavioral claims.

### Proposed Fix: Always Explicitly Close + Tracker Interaction Contract Reference

**A. Replace SKILL.md:743 with explicit close for ALL trackers**

Replace the current lines 741-743:

```markdown
   a. Transition the epic issue to Done using `State transitions -> Done` syntax from Automation Config.
   b. Close all story sub-issues within the epic individually:
      - Read story issue IDs from `<!-- {TrackerType}: {STORY-ID} -->` back-reference comments within the epic file.
      - For each story issue ID: transition to Done using the same `State transitions -> Done` syntax.
      - On failure for individual story: WARN (`Could not transition story {story_id} to Done: {error}`), continue to next story.
```

Remove the GitHub/Gitea vs native sub-issue distinction entirely. The behavior is now uniform across all trackers: always close explicitly. This is simpler, more correct, and eliminates the entire class of "does this tracker cascade?" ambiguity.

**B. Update `core/tracker-interaction.md` (from Issue 2) to include the "No cascade" rule**

The Cascade Behavior section in the new contract explicitly states: "No tracker has guaranteed cascade close by default. Always close children explicitly." This prevents the assumption from being reintroduced in future skills.

**C. Prevention mechanism: Behavioral claims in tracker docs require verification**

Add a note to `docs/reference/trackers.md` at the top:

```
> **Contribution rule:** All behavioral claims about tracker features (e.g., "cascade close",
> "auto-link", "webhook on transition") MUST be verified against the tracker's official
> documentation or API behavior. Do not assume behavior based on UI observation or common
> expectations.
```

### Impact Assessment

- **Files changed:** `skills/scaffold/SKILL.md` (Step 8b rewrite), `core/tracker-interaction.md` (cascade section), `docs/reference/trackers.md` (contribution note)
- **Versioning:** PATCH (bug fix, no contract change)
- **Risk:** Very low. The fix makes behavior MORE deterministic.

---

## Issue 4: No Implementation Comments Posted to Tracker Issues

### Root Cause Behind the Root Cause

The scaffold pipeline has a tracker interaction model that is write-once-read-never: it creates issues (Step 4e) and transitions them (Step 8b), but never communicates results back to the issues themselves. This is in contrast to the bug-fix and feature pipelines, where the publisher agent posts a comment with the PR link (publisher.md:68).

The deeper issue is that the scaffold pipeline was designed as a LOCAL workflow (generates files, commits, pushes) with tracker integration bolted on later (v5.3.0). The tracker interactions were added for issue creation and state management, but the "reporting back" pattern from the bug-fix pipeline was not ported over.

### Proposed Fix: Implementation Summary Comment Step + Tracker Comment Contract

**A. Add a new sub-step in Step 8b: post implementation summary comment to each epic**

After transitioning each epic to Done, post a summary comment:

```markdown
   a. Transition the epic issue to Done.
   b. Close all story sub-issues individually (see Issue 3 fix).
   c. Post implementation summary comment to the epic issue:
      ```
      [ceos-agents] Implementation Summary
      Branch: {branch_name or "main" if committed directly}
      PR: {PR URL if created at Step 4d, or "N/A"}
      Features implemented: {count of non-blocked subtasks} / {total subtasks}
      Blocked: {count} ({list of blocked subtask titles, or "none"})
      Spec compliance: {PASS | PARTIAL | FAIL} (from Step 7b spec-reviewer --verify, if ran)
      ```
      On failure: WARN, continue.
```

**B. Extend the Tracker Interaction Contract with a "Post Implementation Comment" operation**

Add to `core/tracker-interaction.md`:

```markdown
## Post Implementation Comment

When closing a tracker issue that was worked on by the pipeline, post a summary comment.

**Template:**
```
[ceos-agents] Implementation Summary
Branch: {branch}
PR: {pr_url or "N/A"}
Features implemented: {implemented_count} / {total_count}
Blocked: {blocked_count} ({blocked_titles or "none"})
```

**When to use:**
- scaffold pipeline: Step 8b, after transitioning each epic to Done
- implement-feature pipeline: publisher step (already done via publisher agent)
- fix-bugs pipeline: publisher step (already done via publisher agent)
```

**C. Also post a comment to each story sub-issue before closing it**

For story-level traceability, post a brief comment to each story issue before transitioning it to Done:

```
[ceos-agents] Implemented in branch {branch}. Parent epic: {epic-issue-id}.
```

This ensures that every tracker issue created by the scaffold pipeline has at least one activity trail entry, making post-scaffold auditing possible.

### Impact Assessment

- **Files changed:** `skills/scaffold/SKILL.md` (Step 8b expansion), new `core/tracker-interaction.md` section
- **Versioning:** PATCH (gap fill, no contract change)
- **Risk:** Low. Comment posting failures are already handled with WARN-and-continue pattern.

---

## Issue 5: Diacritics — Agents Drop Non-ASCII Characters

### Root Cause Behind the Root Cause

This is a **systemic LLM behavior issue**, not a code bug. When an LLM processes text that contains diacritics (Czech: hacky and carky, German: umlauts, etc.) and then regenerates that text in a different context (e.g., writing it to a tracker issue, including it in a spec), it may "normalize" the text by dropping diacritics. This happens because:

1. The LLM's training data is English-dominated, so it has a mild bias toward ASCII text
2. No instruction explicitly tells the agent to preserve original encoding
3. The agents treat user-provided text as "information to process" rather than "verbatim content to preserve"

The deeper issue is that the agent system has no **cross-cutting language fidelity principle**. Each agent operates independently, and the only language rule in the system (onboard SKILL.md:191-196) addresses config key naming, not content preservation.

### Proposed Fix: Cross-Cutting Language Fidelity Constraint

**A. Add a universal constraint to EVERY agent that reads or writes user-provided text**

Not just the 4 agents identified in the research (triage-analyst, spec-analyst, spec-writer, publisher), but ALL 19 agents. The constraint is cheap (one line) and prevents the issue from recurring when new agents are added or existing agents process unexpected non-ASCII input.

Add to the `## Constraints` section of every agent:

```
- NEVER transliterate, normalize, or drop diacritics from user-provided content. Preserve the original encoding of all non-ASCII characters (Czech hacky/carky, German umlauts, French accents, etc.) in issue titles, descriptions, comments, spec content, and commit messages. If unsure about a character, preserve it verbatim.
```

**B. Add a Language Fidelity section to CLAUDE.md (this repo's instructions)**

In the "Key Conventions Across All Agents" section of CLAUDE.md, add:

```markdown
- All agents MUST preserve original text encoding — NEVER transliterate or drop diacritics from user content
```

This makes the rule discoverable by anyone editing agent definitions.

**C. Add a Language Fidelity section to the core contracts**

Create a brief core contract `core/language-fidelity.md`:

```markdown
# Language Fidelity Contract

## Purpose
Ensure all agents preserve the original encoding of user-provided text.

## Rule
When reading text from any source (issue tracker, user input, spec files, config files)
and writing it to any destination (tracker comments, spec files, commit messages, PR descriptions):
- Preserve all diacritics (hacky, carky, umlauts, accents, tildes)
- Preserve all non-ASCII characters (CJK, Cyrillic, Arabic, etc.)
- NEVER transliterate to ASCII equivalents (e.g., never convert "Prirazeni" from "Prirazeni")
- NEVER normalize Unicode forms unless the destination explicitly requires it

## Scope
Applies to ALL agents. The constraint is added to each agent's Constraints section
but this contract is the authoritative source.

## Exceptions
- Config keys: MUST be in English ASCII (per onboard SKILL.md language rules)
- Branch names: MUST be ASCII (git convention)
- Identifier values in Automation Config: MUST be in English ASCII
```

**D. Prevention mechanism: Agent definition linter check**

Add a test case to `tests/` that verifies every agent file in `agents/` contains the diacritics preservation constraint. This catches new agents that forget to include it.

### Impact Assessment

- **Files changed:** All 19 files in `agents/`, `CLAUDE.md` (key conventions), new `core/language-fidelity.md`, new test in `tests/`
- **Versioning:** PATCH (constraint addition, no contract change)
- **Risk:** Very low. Adding a constraint line to each agent has zero behavioral side effects for ASCII-only projects.

---

## Cross-Cutting Themes and Prevention Mechanisms

### Theme 1: The Tracker Interaction Model is Incomplete

Issues 2, 3, and 4 all stem from the same root: the scaffold pipeline's tracker interactions were designed ad-hoc rather than against a formal contract. The bug-fix and feature pipelines have the publisher agent as a centralized tracker interaction point, but the scaffold pipeline does its own tracker operations inline.

**Prevention:** The proposed `core/tracker-interaction.md` contract centralizes all tracker interaction patterns. Any new pipeline that needs to create, close, or comment on tracker issues references this contract instead of reimplementing the logic.

### Theme 2: LLM Instructions Must Be Self-Contained at Point of Use

Issues 2 and 5 share a pattern: critical information that the LLM needs at execution time is stored elsewhere (in a reference doc, or not stored at all). LLMs are not reliable at cross-file lookups mid-execution.

**Prevention:** The "inline at point of use" principle. Whenever a skill instruction requires the LLM to use a specific parameter name, format, or value, that information must appear directly in the instruction, not behind a "see document X" reference. Reference docs are for humans; inline tables are for LLM instructions.

### Theme 3: Backend-First Design Creates Frontend Blind Spots

Issue 1 is a symptom of the entire scaffold pipeline being designed with backend projects as the primary archetype. This will recur as more frontend-specific concerns emerge (e.g., i18n setup, PWA configuration, image optimization pipeline).

**Prevention:** The "stack archetype" concept. Classify the project early in the pipeline and use the archetype to conditionally activate entire feature sets. This is more scalable than adding one-off "if frontend then..." checks to every agent.

---

## Summary Table

| Issue | Fix Scope | Key Innovation | Prevention Mechanism |
|-------|-----------|---------------|---------------------|
| 1. Design quality | spec-writer + scaffolder | Conditional Design & UX section, Design Infrastructure batch | Stack archetype detection |
| 2. Story linking | SKILL.md + new core contract | Inline parameter table | `core/tracker-interaction.md` contract |
| 3. Story closing | SKILL.md + core contract | Uniform explicit close for ALL trackers | "No cascade" rule in contract + contribution note in trackers.md |
| 4. No comments | SKILL.md + core contract | Implementation summary comment | Tracker comment operation in contract |
| 5. Diacritics | All 19 agents + CLAUDE.md + new core contract | Universal language fidelity constraint | `core/language-fidelity.md` + linter test |

## Implementation Priority (Innovator Recommendation)

1. **Issues 2+3+4 together** (tracker interaction cluster) — These three share the same root cause (incomplete tracker interaction model). Fix them together by creating `core/tracker-interaction.md` and updating `SKILL.md` Step 4e and Step 8b in one pass. This is the highest-value change because it fixes a confirmed bug (cascade close) and two confirmed gaps in a single coherent refactor.

2. **Issue 5** (diacritics) — Cross-cutting but mechanical. Touch all 19 agent files once to add the constraint. Create the core contract and the test. High value for non-English users.

3. **Issue 1** (design quality) — Most scope, most innovation, most optional. This is a genuine feature addition that expands the scaffold pipeline's capability. Recommend implementing it as a separate MINOR version to keep the bug-fix patch clean.
