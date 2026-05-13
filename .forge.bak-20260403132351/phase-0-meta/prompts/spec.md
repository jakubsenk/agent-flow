# Phase 4: Specification

## Requirements

### REQ-1: Scaffold Design Quality (Issue #1)
**EARS format:** WHEN the project type is web application (frontend or fullstack), the spec-writer SHALL include a "Design & UX" section in `spec/README.md` covering CSS framework, color scheme, typography, layout approach, and responsive requirements. The scaffolder SHALL generate base design system files (CSS framework config, global styles) when the spec includes a Design & UX section.

**Acceptance Criteria:**
1. spec-writer.md contains a new "Design & UX" section requirement for web projects
2. scaffolder.md contains a new batch for design system setup when web framework is in the stack
3. scaffolder scorecard includes a "Design system" check for web projects

### REQ-2: Story Sub-Issue Linking (Issue #2)
**EARS format:** WHEN creating story issues in Step 4e for trackers with native sub-issues, the scaffold skill SHALL pass the tracker-specific parent parameter explicitly by name (e.g., `parent: {EPIC-ID}` for YouTrack) and SHALL verify the story was created as a sub-issue.

**Acceptance Criteria:**
1. Step 4e contains explicit per-tracker parent parameter names inline
2. Step 4e includes a verification step: after creating a story, confirm it was linked as a sub-issue (or log a warning if the parent parameter was not accepted)

### REQ-3: Explicit Story Closing (Issue #3)
**EARS format:** WHEN closing tracker issues in Step 8b, the scaffold skill SHALL explicitly close each story sub-issue individually for ALL tracker types, not relying on cascade behavior.

**Acceptance Criteria:**
1. Step 8b no longer contains the cascade assumption text
2. Step 8b explicitly closes story issues for all tracker types (YouTrack, Jira, Linear, Redmine, GitHub, Gitea)
3. The logic is unified: iterate all story IDs from back-reference comments and close each one

### REQ-4: Implementation Comments on Tracker Issues (Issue #4)
**EARS format:** AFTER implementation completes (Step 7) and BEFORE closing issues (Step 8b), the scaffold skill SHALL post an implementation summary comment on each completed story and epic issue in the tracker.

**Acceptance Criteria:**
1. A new Step 8a exists between Step 8/E2E and Step 8b
2. For each completed story: comment includes subtask title, files changed, commit hash
3. For each completed epic: comment includes summary of all implemented stories
4. Comments use the `[ceos-agents]` prefix
5. Guard clause: skip if tracker not ready or not writable

### REQ-5: Language Fidelity / Diacritics Preservation (Issue #5)
**EARS format:** WHEN user input contains non-ASCII characters (diacritics, accents, special characters), ALL agents processing that text SHALL preserve the exact characters without simplification or stripping.

**Acceptance Criteria:**
1. spec-writer.md contains a language fidelity constraint about preserving diacritics
2. scaffold SKILL.md Step 4e contains a language fidelity instruction for issue titles/descriptions
3. The constraint is specific and gives examples (e.g., "never write 'uzivatel' when input says 'uzivatel'")

## Architecture Impact

- **No breaking changes** to Automation Config contract (no new required keys)
- **No new agents** — all changes are to existing agent definitions and skill orchestration
- **No new skills** — all changes within existing `scaffold` skill
- **Versioning:** PATCH (behavior fixes within existing contract) for Issues #2-5. Issue #1 adds optional spec sections = could be MINOR, but since no new config key is required, PATCH is acceptable.

## Out of Scope
- Implementing actual CSS framework auto-detection logic (scaffolder already adapts to stack)
- Testing with real YouTrack MCP (cannot be tested in this repo's test suite)
- Changing other pipelines (fix-ticket, implement-feature) — those already have PR-based issue linking
