# Phase 0 — Task Analysis

## Task Type Classification

**Type:** Enhancement (UX Polish)
**Category:** Textual/behavioral modifications to existing markdown command and core contract definitions
**Version:** v5.6.1 (PATCH — no breaking changes to Automation Config contract or agent output format)

This is a batch of 4 small, well-scoped UX improvements to existing plugin definitions. All changes are additive or replacement edits within existing markdown files. No new files, agents, or commands are introduced.

## Complexity Assessment

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| **Scope** | 2 | 3-4 markdown files modified. No new files created. Each change is a localized text edit. |
| **Ambiguity** | 2 | All 4 items have specific "from → to" descriptions in the roadmap. The exact wording, locations, and behavior are well-defined. Minor design decisions remain only for item 2 (interactive ask vs. announce). |
| **Risk** | 1 | Pure markdown edits. No build system, no runtime code, no compilation. Changes are backward-compatible (PATCH version). No contract-breaking changes. |
| **Composite** | 2 | max(2, 2, 1) = 2 (Low complexity) |

## Fast-Track Eligibility Assessment

### Tier A — Keyword Scan

| Signal | Present | Evidence |
|--------|---------|----------|
| "typo" / "rename" / "wording" | Partial | Items 1, 3 are largely rewording/reformatting |
| "config change" | No | — |
| "doc update" | Partial | All changes are to markdown definitions (documentation-like) |
| "simple" / "small" / "minor" | Yes | Roadmap section title: "UX Polish" |
| Security keywords (auth, token, secret, permission, injection, vulnerability) | No | — |
| Infrastructure keywords (deploy, migrate, database, schema) | No | — |
| "refactor" / "rewrite" / "redesign" | No | — |

**Tier A result:** Leans toward eligible (polish/wording changes in markdown files).

### Tier B — Semantic Evaluation

**Nature of changes:**
1. **--infra flag format** — Regex/format validation change + parsing logic update + error message update in `scaffold.md`. Self-contained, no cross-file implications beyond `resume-ticket.md` which also needs to understand the flag.
2. **Canary-write announcement** — Adding 1-2 lines of display text before the canary-write step in `core/mcp-detection.md`. Trivial insertion.
3. **Error message rewrite** — String replacement in `core/mcp-detection.md` and `commands/scaffold.md`. Find MCP jargon, replace with user-friendly language.
4. **Resume --infra override** — Adding a new flag parsing section and state-override logic to `commands/resume-ticket.md`. Small addition (~15-20 lines of markdown).

**Cross-cutting concerns:** Item 1 (--infra format) affects `scaffold.md` flag parsing + validation + Step 0-INFRA preset logic + `resume-ticket.md` (new). Item 3 (error messages) affects `core/mcp-detection.md` failure handling + `commands/scaffold.md` MCP pre-flight section. Items 2 and 4 are single-file changes.

**Test impact:** Existing tests in `tests/` are structural (file existence, frontmatter format, section headings). The `--infra` format change may affect test expectations if any tests validate the flag format. Need to check.

```json
{
  "security_evaluation": {
    "touches_auth_or_secrets": false,
    "modifies_access_control": false,
    "changes_data_handling": false,
    "affects_external_api_surface": false,
    "requires_security_review": false,
    "rationale": "All changes are to markdown instruction files. No runtime code, no token handling, no API changes. The canary-write change adds a display message but does not change the write operation itself."
  }
}
```

**Fast-track decision: ELIGIBLE**

Rationale: Composite complexity 2 (low), no security concerns, no architectural changes, no new files/agents/commands, all changes are localized text edits in 3-4 existing markdown files. This is a textbook fast-track candidate.

## Domain Identification

| Domain | Relevance |
|--------|-----------|
| **Plugin definition authoring** | Primary — all changes are markdown definition edits |
| **CLI UX design** | Secondary — flag format, error messages, interactive prompts |
| **State management** | Tertiary — item 4 touches state.json resume logic |

## Codebase Context Assessment

**Files requiring modification (confirmed via read):**

| File | Items | Lines affected (est.) |
|------|-------|-----------------------|
| `commands/scaffold.md` | 1, 3 | ~30 lines (flag parsing, validation, Step 0-INFRA preset, MCP error messages) |
| `core/mcp-detection.md` | 2, 3 | ~15 lines (canary-write announcement, failure message rewrites) |
| `commands/resume-ticket.md` | 4 | ~25 lines (new --infra flag support, state override logic) |
| `state/schema.md` | (none) | No changes needed — infrastructure field already documented |

**Files requiring review but likely no changes:**
- `tests/` — Check if any test validates `--infra` format string
- `docs/plans/roadmap.md` — Move items from PLANNED to DONE after implementation
- `CLAUDE.md` — No contract changes, no update needed

**Total estimated diff:** ~70 lines of markdown edits across 3 files.

## Confidence Scoring

| Aspect | Confidence | Note |
|--------|------------|------|
| File identification | 0.95 | Read all 4 target files; changes are clearly localized |
| Change scope | 0.90 | Well-defined from/to in roadmap; minor design decision for item 2 interactive mode |
| Risk assessment | 0.95 | Pure markdown, no runtime, no contract break |
| Fast-track decision | 0.90 | Clear low-complexity, low-risk, well-scoped changes |
| **Overall** | **0.92** | High confidence in analysis completeness and accuracy |
