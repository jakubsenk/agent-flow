# Phase 2: Research Verification — Final Answers

**Date:** 2026-04-02  
**Verified by:** Research verification agent (claude-sonnet-4-6)

---

## RQ-1: Story linking broken in YouTrack

**Verdict: REFUTED (partially)**

The claim was that the LLM doesn't reliably pass the `parent` parameter when creating YouTrack sub-issues. The actual code tells a different story:

**Evidence:**

- `skills/scaffold/SKILL.md:533` — "create sub-issue with parent set to epic issue ID using the tracker's native parent parameter"
- `docs/reference/trackers.md:88-97` — The Sub-Issue Capabilities table explicitly documents the per-tracker parent parameter name:
  - YouTrack: `parent: {issue-id}`
  - Jira: `parent: {key}`, `issuetype: "Sub-task"`
  - Linear: `parentId: {id}`
  - Redmine: `parent_issue_id: {id}`
- `docs/reference/trackers.md:97` (note) — "The parent parameter names are MCP tool conventions. The LLM uses these when invoking the tracker's MCP create-issue tool."

**Assessment:** The instruction in `SKILL.md:533` says "using the tracker's native parent parameter" but does NOT inline the parameter name — it defers to `docs/reference/trackers.md`. The reference table does exist and provides the specific parameter name (`parent: {issue-id}` for YouTrack). The LLM executing Step 4e would need to cross-reference `trackers.md` to know the exact parameter name. The indirection is a mild reliability risk — if the LLM skips reading `trackers.md`, it might not know the specific key name — but the information IS present and accessible.

**Partial confirmation:** The instruction is technically complete but relies on cross-file lookup. Inlining the parameter name directly in `SKILL.md:533` would be more reliable.

---

## RQ-2: YouTrack cascade close assumption wrong

**Verdict: CONFIRMED**

**Evidence:**

- `skills/scaffold/SKILL.md:743` — "For trackers with native sub-issues (YouTrack, Jira, Linear, Redmine): closing the parent epic **typically** cascades to children. Do NOT explicitly close story sub-issues."

The word **"typically"** is the key problem. Cascade-close in YouTrack is NOT a default behavior — it requires an explicit workflow rule configured by a project admin. Without that rule, story sub-issues remain open after the parent epic is closed. The pipeline assumes cascade behavior that may not exist, leading to orphaned open story issues after a scaffold run.

**Recommendation:** This is a genuine bug. The assumption must be removed. Step 8b should always explicitly close story sub-issues for all native sub-issue trackers (YouTrack, Jira, Linear, Redmine), the same way it already does for GitHub/Gitea. Alternatively, add a configurable `Cascade close: true/false` key to the Automation Config.

---

## RQ-3: No implementation comments on tracker issues

**Verdict: CONFIRMED**

**Evidence:**

Grep for "comment" in `skills/scaffold/SKILL.md` returns only these matches:
- Lines 522, 532, 731, 738, 742 — all refer to HTML back-reference `<!-- {TrackerType}: ... -->` comments written into spec files, not to tracker issue comments.
- Line 845 — "Block comments in scaffold context go to stdout, not issue tracker"

No step in the scaffold pipeline posts a comment to a tracker issue with implementation details. The only tracker interactions are:
1. Step 4e: create issues (write back IDs to spec files)
2. Step 8b: transition issues to Done

The publisher agent (`agents/publisher.md:68`) does post a comment ("Add comment to issue with PR link") but this applies only in the bug-fix and feature pipelines, not the scaffold pipeline.

**Assessment:** After scaffold completes, the created tracker issues have no implementation evidence, no PR links, and no summary of what was done. Developers browsing YouTrack/Jira after a scaffold run see bare issues with no activity trail.

**Recommendation:** Add a sub-step in Step 8b or Step 9: for each closed epic issue, post a comment summarizing what was implemented (list of features, branch name, or PR link if applicable).

---

## RQ-4: No language fidelity instructions

**Verdict: CONFIRMED**

**Evidence:**

Grep for `diacrit`, `language`, `encoding`, `unicode`, `UTF` across all files in `agents/` returns no matches related to text preservation or character encoding. Results found are only about programming language conventions (e.g., "language-specific directory conventions" in `agents/scaffolder.md:129`).

`skills/onboard/SKILL.md:191-196` — The "Language rules" section exists but addresses a different concern: it specifies that config keys must be in English and that identifier values must be in English. It says "User-provided values preserved as-is (URLs, project names, commands)" but this is about config generation, not about content written to tracker issues or spec files.

No agent file contains instructions to preserve diacritics, maintain source text encoding, or avoid mangling non-ASCII characters (Czech, Slovak, German umlauts, etc.) when reading from or writing to issue trackers.

**Recommendation:** Add a constraint to triage-analyst, spec-analyst, spec-writer, and publisher along the lines of: "NEVER transliterate or remove diacritics from user-provided content — preserve original encoding including Czech, Slovak, German, and other non-ASCII characters in issue titles, descriptions, and comments."

---

## RQ-5: No design system in scaffold

**Verdict: CONFIRMED**

**Evidence:**

- `agents/spec-writer.md` — No design-related sections. The agent covers: vision, goals, success criteria, tech stack, architecture, data flow, API, NFR, user stories with GWT acceptance criteria. The word "design" appears only once: in the `style` frontmatter field ("Visionary, comprehensive, user-centric") and once as "UX requirements" as a label for rule-oriented AC format. No design system, brand guidelines, color, typography, or component library instructions exist.
- `agents/scaffolder.md` — No design-related sections. Batches 1-5 cover: build config, entry point, gitignore, .env, database config, smoke test, test infrastructure, linter config, Dockerfile, CI config, README.md, CLAUDE.md. No frontend design artifacts, style config, or UI framework setup.
- `skills/scaffold/SKILL.md` — Grep for "design system", "design token", "design guide", "brand", "visual", "color palette", "typography" returns zero matches.

**Assessment:** The scaffold pipeline produces zero frontend design artifacts. For frontend projects, this means scaffolded projects have no design tokens file, no base CSS/theme, no component library setup, and no brand guidelines reference in the spec. This is a gap specifically for frontend and full-stack web projects.

**Recommendation:** Add an optional "Design System" section to the Automation Config and to spec/architecture.md. When the tech stack is frontend/full-stack, spec-writer should ask about design system preferences (Tailwind, MUI, shadcn/ui, custom, etc.) and scaffolder should generate the appropriate base config. This is optional for backend/CLI projects.

---

## Fix Strategy Summary

| RQ | Status | Priority | Recommended Fix |
|----|--------|----------|-----------------|
| RQ-1: Story parent parameter indirection | Partially refuted (information exists but requires cross-file lookup) | Low | Inline the tracker-specific parent parameter name in `SKILL.md:533` instead of deferring to `trackers.md` |
| RQ-2: YouTrack cascade close assumption | CONFIRMED BUG | High | Remove the "typically cascades" assumption. Always explicitly close story sub-issues for all native sub-issue trackers, or add a `Cascade close: true/false` config key |
| RQ-3: No implementation comments | CONFIRMED GAP | Medium | Add a step in Step 8b/9 to post a comment to each closed epic issue with implementation summary (features implemented, branch, PR link) |
| RQ-4: No diacritics preservation | CONFIRMED GAP | Medium | Add diacritics preservation constraint to triage-analyst, spec-analyst, spec-writer, and publisher agent definitions |
| RQ-5: No design system in scaffold | CONFIRMED GAP | Low | Add optional Design System section to config and spec; scaffolder generates base design config for frontend stacks |

### Implementation Order (suggested)

1. **RQ-2 (High)** — Fix the cascade close bug. Affects correctness of all scaffold runs against YouTrack/Jira/Linear/Redmine. Simple change in `SKILL.md:743`.
2. **RQ-4 (Medium)** — Add diacritics constraints to 4 agent files. Low risk, high value for non-English projects.
3. **RQ-3 (Medium)** — Add implementation comment step. Requires new logic in Step 8b or Step 9.
4. **RQ-1 (Low)** — Inline parent parameter name in SKILL.md:533 to remove cross-file lookup dependency.
5. **RQ-5 (Low)** — Design system support is a new feature, scope it as a separate MINOR version addition.
