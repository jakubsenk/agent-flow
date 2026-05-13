# Agent 1: Conservative Brainstorm

**Perspective:** Minimal changes, backwards compatibility, low risk  
**Date:** 2026-04-02

---

## Issue 1: Design Quality — No UI/Design Instructions for Web Projects

### Proposed Fix

**Do not add a new config section or pipeline step.** Instead, add a single paragraph to `agents/spec-writer.md` inside the existing Process step 3 (spec generation), conditional on frontend/full-stack stacks:

```
When the tech stack includes a frontend framework (React, Vue, Svelte, Angular, Next.js, Nuxt, etc.)
or is a full-stack web application: the architecture.md MUST include a "Design System" subsection under
the high-level overview. This subsection should specify: chosen component library or CSS framework
(e.g., Tailwind, MUI, shadcn/ui), color palette approach (tokens file vs inline), and typography scale.
If the user did not specify design preferences, make a decisive choice based on the framework ecosystem
and document the rationale — same as the existing tech stack behavior in step 6.
```

Also add one line to `agents/scaffolder.md` Process step 2, Batch 1 or Batch 3:

```
If the tech stack includes a frontend framework: generate a base design config file appropriate to the
chosen design system (e.g., tailwind.config.js, theme.ts). This is boilerplate only — no custom components.
```

**Files changed:** 2 (`agents/spec-writer.md`, `agents/scaffolder.md`)  
**Lines added:** ~6-8 total  
**New steps/sections:** 0 (modifications to existing process steps)  
**Config contract change:** None  
**Backwards compatibility:** Full — backend/CLI projects see no change; the instruction is conditional on frontend stacks

### Trade-offs

- **Pro:** Zero new config sections, zero new pipeline steps. The spec-writer already makes tech stack decisions in step 6 — this follows the same pattern.
- **Pro:** No MINOR version bump needed (no config contract change).
- **Con:** No user override for design preferences beyond what they provide in the project description or interactive mode. A future `Design System` config section could offer that, but that is a new feature, not a bugfix.
- **Con:** The scaffolder instruction is vague ("appropriate to the chosen design system") — but the scaffolder already handles varied stacks generically, so this fits its existing pattern.

### Rejected Alternatives

1. **New `Design System` config section in Automation Config** — This is a MINOR version feature, not a bugfix. Adds contract surface area. Over-engineering for a gap that can be closed with 6 lines of agent instructions.
2. **New pipeline step between spec-writer and scaffolder** — Unnecessary. Spec-writer already writes architecture.md. Just tell it to include design info.
3. **New `design-advisor` agent** — Far too heavy. No justification for a 20th agent when existing agents can handle this.

---

## Issue 2: Story Linking — Step 4e Parent Parameter Indirection

### Proposed Fix

Inline the tracker-specific parent parameter directly in `skills/scaffold/SKILL.md` line 533, replacing the cross-file reference. Change:

```
create sub-issue with parent set to epic issue ID using the tracker's native parent parameter
```

To:

```
create sub-issue with parent set to epic issue ID. Use the tracker-specific parameter:
YouTrack: `parent: {epic-issue-id}`, Jira: `parent: {key}` + `issuetype: "Sub-task"`,
Linear: `parentId: {epic-issue-id}`, Redmine: `parent_issue_id: {epic-issue-id}`
```

**Files changed:** 1 (`skills/scaffold/SKILL.md`)  
**Lines changed:** 1 line expanded to ~3 lines  
**New steps/sections:** 0  
**Config contract change:** None  
**Backwards compatibility:** Full — same behavior, just more explicit instructions

### Trade-offs

- **Pro:** Eliminates cross-file lookup. The LLM executing Step 4e now has the parameter name in immediate context.
- **Pro:** Information is duplicated from `docs/reference/trackers.md` but this is intentional redundancy for reliability — the reference doc remains the authoritative source.
- **Con:** If a new tracker is added, the inline list in SKILL.md must be updated alongside `trackers.md`. Mild maintenance burden.
- **Con:** Makes line 533 longer. But clarity beats brevity for LLM instructions.

### Rejected Alternatives

1. **Add `See docs/reference/trackers.md` as a stronger directive** — The instruction already says "see Sub-Issue Capabilities in docs/reference/trackers.md". Making it stronger doesn't fix the core problem: the LLM may not read it.
2. **Move the table into SKILL.md and remove from trackers.md** — Over-correction. trackers.md is the canonical reference for multi-skill use. Keep both.

---

## Issue 3: Story Closing — Step 8b Cascade Close Assumption

### Proposed Fix

Replace the flawed assumption at `skills/scaffold/SKILL.md` line 743 with explicit close-all behavior. Change:

```
c. For trackers with native sub-issues (YouTrack, Jira, Linear, Redmine): closing the parent epic typically cascades to children. Do NOT explicitly close story sub-issues.
```

To:

```
c. For trackers with native sub-issues (YouTrack, Jira, Linear, Redmine): also close each story sub-issue explicitly. Read story IDs from back-reference comments within the epic file. Do NOT rely on cascade close — it requires tracker-specific workflow rules that may not be configured.
```

This makes line 742 (GitHub/Gitea behavior) and line 743 (native sub-issue trackers) do the same thing: explicitly close all story issues. The only difference is that 742 closes "standalone story issues" and the new 743 closes "story sub-issues" — but the MCP state transition call is the same.

**Files changed:** 1 (`skills/scaffold/SKILL.md`)  
**Lines changed:** 1 line replaced  
**New steps/sections:** 0  
**Config contract change:** None  
**Backwards compatibility:** Slightly different behavior for projects where cascade close IS configured — those will now get redundant close calls (epic cascades + explicit close). This is harmless: transitioning an already-closed issue to Done is a no-op in all tracked systems.

### Trade-offs

- **Pro:** Fixes the actual bug. Simple one-line replacement.
- **Pro:** No new config key needed. The fix is unconditional.
- **Pro:** Redundant close calls on systems with cascade rules are harmless (idempotent).
- **Con:** Slightly more API calls per scaffold run (one per story issue). Negligible cost.

### Rejected Alternatives

1. **Add `Cascade close: true/false` config key** — This is a MINOR version feature. Adds a config key that 99% of users won't understand or configure correctly. The safer default is "always close explicitly". If a user complains about redundant API calls, we can add the config key later.
2. **Detect cascade behavior at runtime** — Impossible without tracker-admin-level API access. Over-engineering.
3. **Only close stories, not epics, and let cascade handle epics** — Inverts the problem. Worse.

---

## Issue 4: No Comments — No Implementation Summary Posted to Tracker

### Proposed Fix

Add a sub-step to Step 8b (between the existing transition logic and the display line). After transitioning each epic to Done, post a comment. Insert after line 743:

```
e. Post implementation summary comment to the epic issue:
   ```
   [ceos-agents] Scaffold implementation complete.
   Branch: {branch name from git}
   Features: {implemented count}/{total count}
   Blocked: {blocked count, or "none"}
   PR: {PR URL if created, or "N/A"}
   ```
   On comment failure: WARN (`Could not post comment to {issue_id}: {error}`), continue.
```

**Files changed:** 1 (`skills/scaffold/SKILL.md`)  
**Lines added:** ~7  
**New steps/sections:** 0 (sub-step within existing Step 8b)  
**Config contract change:** None  
**Backwards compatibility:** Full — adds comments to issues that previously had none. No existing behavior changes.

### Trade-offs

- **Pro:** Minimal addition to existing step. Uses the same error handling pattern (WARN + continue) as the rest of Step 8b.
- **Pro:** Comment format uses `[ceos-agents]` prefix for machine-parseability, consistent with triage checkpoint comments.
- **Pro:** Only posts to epic issues, not each story — reduces API calls.
- **Con:** Only posts to epic issues. Story issues won't get comments. This is intentional for minimality — epic comments are sufficient for traceability. Story-level comments can be added later if needed.
- **Con:** The comment is sparse. But that matches the mechanical nature of Step 8b. Detailed implementation notes belong in the PR description, not in every tracker issue.

### Rejected Alternatives

1. **New Step 8c for comments** — Unnecessary. Step 8b already iterates over epics and has a natural place for comments.
2. **Comment on every story issue too** — Over-engineering. Multiplies API calls. Epic-level comment is sufficient.
3. **Reuse publisher agent's comment logic** — Publisher operates in a different context (single issue + single PR). Scaffold Step 8b handles N issues. The patterns don't match.
4. **Post comments in Step 9 instead** — Step 9 is a display step (final report). Mixing tracker writes into it violates separation of concerns. Step 8b is where tracker writes happen.

---

## Issue 5: Diacritics — Agents Drop Non-ASCII Characters

### Proposed Fix

Add a single constraint line to 4 agent files. The constraint is identical across all agents:

```
- NEVER transliterate, normalize, or strip diacritics from user-provided text — preserve original characters (Czech, Slovak, German, etc.) in all output including issue titles, descriptions, comments, and spec content
```

Add to `## Constraints` section of:
1. `agents/triage-analyst.md` (reads and writes to tracker)
2. `agents/spec-analyst.md` (reads and writes to tracker)
3. `agents/spec-writer.md` (writes spec files from user input)
4. `agents/publisher.md` (writes to tracker — PR descriptions and comments)

**Files changed:** 4 agent files  
**Lines added:** 1 per file = 4 total  
**New steps/sections:** 0  
**Config contract change:** None  
**Backwards compatibility:** Full — English-only projects are unaffected. Non-English projects get correct behavior.

### Trade-offs

- **Pro:** Minimal change — one constraint line per agent.
- **Pro:** Constraints section is where NEVER rules live by convention (per CLAUDE.md). This fits perfectly.
- **Pro:** No skill changes needed. The issue is agent-level (the LLM's default tendency to transliterate), so the fix is agent-level.
- **Con:** Only covers 4 agents. Other agents (fixer, reviewer, architect, scaffolder, etc.) also process text, but they primarily work with code and English-language technical content. The 4 chosen agents are the ones that read user-facing text from trackers and write it back. If diacritics issues appear in other agents later, the constraint can be added incrementally.
- **Con:** A single constraint line may not be sufficient for all LLMs in all cases. But constraints are the strongest directive in agent definitions — the Process section says what to do, Constraints say what to NEVER do. This is the right mechanism.

### Rejected Alternatives

1. **Add the constraint to ALL 19 agents** — Shotgun approach. Most agents never touch user-facing text. Adds noise to agents like rollback-agent and code-analyst where it's irrelevant.
2. **Add a global instruction in a core/ file** — No such mechanism exists. Core files are pipeline contracts, not global agent instructions. Would require new architecture.
3. **Add to CLAUDE.md project instructions** — This is the plugin's CLAUDE.md, not the consuming project's. Plugin-level CLAUDE.md governs development of the plugin itself, not runtime agent behavior. Wrong layer.
4. **Add encoding/charset enforcement** — Over-engineering. The issue is LLM behavior (transliteration), not encoding. UTF-8 is already the default everywhere.

---

## Summary: Total Impact

| Issue | Files Changed | Lines Changed | New Steps | Config Change | Version Impact |
|-------|--------------|---------------|-----------|---------------|----------------|
| 1. Design quality | 2 agents | ~8 | 0 | None | PATCH |
| 2. Story linking | 1 skill | ~3 | 0 | None | PATCH |
| 3. Story closing | 1 skill | ~2 | 0 | None | PATCH |
| 4. No comments | 1 skill | ~7 | 0 (sub-step) | None | PATCH |
| 5. Diacritics | 4 agents | 4 | 0 | None | PATCH |
| **Total** | **8 files** | **~24 lines** | **0** | **None** | **PATCH** |

All 5 fixes are PATCH-level. No config contract changes. No new pipeline steps. No new agents. No breaking changes. Total delta: approximately 24 lines across 8 files.

### Implementation Order (by risk, ascending)

1. **Issue 2 (story linking)** — Safest. Pure instruction clarification. Zero behavioral change.
2. **Issue 5 (diacritics)** — 4 identical one-liners. No logic change.
3. **Issue 3 (story closing)** — Behavioral change but idempotent. Low risk.
4. **Issue 4 (no comments)** — New behavior (posting comments). Low risk but adds API calls.
5. **Issue 1 (design quality)** — Broadest scope (2 agents, conditional logic). Still low risk but harder to test.
