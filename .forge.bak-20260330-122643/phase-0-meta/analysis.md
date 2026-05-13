# Phase 0 — Task Analysis

## Task Type Classification

**Type:** Enhancement (MINOR version — new backward-compatible features)
**Category:** Infrastructure polish / DX improvement
**Version:** v5.6.0

This is a batch of 6 related follow-up items from v5.5.0, all touching scaffold/init infrastructure. Each item is well-scoped, has clear acceptance criteria, and the target files are identified. No new agents, no new commands, no contract-breaking changes.

## Complexity Assessment

### Scope
- **Files to create:** 1 (`core/mcp-detection.md`)
- **Files to modify:** 6-8 (`commands/scaffold.md`, `commands/init.md`, `commands/implement-feature.md`, `state/schema.md`, `core/state-manager.md`, `docs/plans/roadmap.md`, `CHANGELOG.md`, possibly `CLAUDE.md`)
- **Total changes:** 6 discrete items, each self-contained
- **Cross-cutting concerns:** Items 1 and 5 both touch Step 0-MCP. Items 3 and 4 both touch Step 0-INFRA. Item 6 touches scaffold + implement-feature.

### Ambiguity: LOW
All 6 items have clear descriptions, identified source files, and explicit behavior definitions. The codebase has strong patterns to follow (core/ contract format, flag parsing patterns, state schema conventions).

### Risk: LOW
- Pure markdown changes — no runtime, no compilation, no deployment
- MINOR version — no breaking changes to any contract
- All changes are additive (new core file, new optional state field, new CLI flag, new check step)
- Existing test suite validates markdown structure (headings, cross-references)

### Estimated effort per item:
1. core/mcp-detection.md — MEDIUM (new file + refactor two commands to reference it)
2. init.md .mcp.json.example detection — SMALL (add detection step to init)
3. state.json infrastructure field — SMALL (add field to schema + state-manager + scaffold write)
4. --infra CLI flag — SMALL (add flag parsing + wire to Step 0-INFRA)
5. canary-write check — SMALL (add sub-step to Step 0-MCP)
6. YOLO+no-MCP block — SMALL (add guard clause to scaffold + implement-feature)

**Overall complexity: MEDIUM** (6 small/medium items with moderate cross-file coordination)

## Fast-Track Eligibility

**Eligible: NO**

Rationale: 6 items across 8+ files with cross-references between them. Not a single-file fix. Requires coordinated editing to maintain consistency. Standard forge pipeline is appropriate.

## Security Evaluation

**N/A** — pure markdown plugin, no code execution, no credentials handling, no network access. The canary-write check (item 5) describes behavior for the LLM to follow, not actual code.

## Domain Identification

**Domain:** Claude Code plugin development (markdown-based agent/command definitions)
**Sub-domain:** Scaffold pipeline infrastructure, MCP server detection, state management

## Codebase Context Assessment

### Highly relevant files (must read before editing):
- `commands/scaffold.md` — primary target (items 1, 4, 5, 6)
- `commands/init.md` — secondary target (items 1, 2)
- `commands/implement-feature.md` — secondary target (item 6)
- `state/schema.md` — target (item 3)
- `core/state-manager.md` — target (item 3)
- `core/mcp-preflight.md` — reference for core contract format
- `core/config-reader.md` — reference for core contract format
- `docs/reference/trackers.md` — MCP Server Detection table (referenced by item 1)

### Pattern sources:
- `core/config-reader.md` — canonical core contract format (Purpose/Input/Output/Failure)
- Existing flag parsing in `commands/scaffold.md` (--lang, --framework, --db patterns)
- Existing state field definitions in `state/schema.md`

## Confidence Scoring

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Requirements clarity | 0.95 | All 6 items have explicit descriptions and known source files |
| Codebase understanding | 0.95 | All target files read and analyzed; patterns are well-established |
| Implementation path | 0.90 | Clear for all items; item 1 (core extraction) has the most coordination |
| Risk assessment | 0.95 | Low-risk additive changes to a markdown-only codebase |
| **Overall confidence** | **0.93** | High confidence — well-defined scope with strong patterns to follow |

## Routing Decision

**Pipeline mode: adaptive**
**Recommended phases:**

1. **Phase 1 (Research):** SKIP — all context is already gathered in this analysis
2. **Phase 2 (Research Q&A):** SKIP — no open questions
3. **Phase 3 (Brainstorm):** SKIP — implementation approach is clear from patterns
4. **Phase 4 (Spec):** SKIP — user provided detailed spec for all 6 items
5. **Phase 5 (TDD):** SKIP — test suite is bash-based structural checks; tests will be updated as part of implementation
6. **Phase 6 (Plan):** EXECUTE — decompose into dependency-ordered tasks
7. **Phase 7 (Execute):** EXECUTE — parallel subagents for independent items
8. **Phase 8 (Verify):** EXECUTE — run test suite, validate cross-references
9. **Phase 9 (Finish):** EXECUTE — changelog, roadmap update, version considerations

**Parallelization opportunities:**
- Items 2, 3, 4, 5, 6 are independent of each other
- Item 1 (core/mcp-detection.md) must be created BEFORE items 1's refactoring of scaffold.md and init.md
- Items 4 and 5 both modify scaffold.md — must be sequenced or merged into one task
- Item 6 modifies scaffold.md AND implement-feature.md — must be sequenced after 4 and 5

**Recommended task graph:**
```
Task A: Create core/mcp-detection.md (new file)
Task B: Refactor scaffold.md Step 0-MCP to reference core/mcp-detection.md  [depends: A]
Task C: Refactor init.md Steps 3+7 to reference core/mcp-detection.md      [depends: A]
Task D: Add .mcp.json.example detection to init.md                          [depends: C]
Task E: Add infrastructure field to state/schema.md + core/state-manager.md [independent]
Task F: Add --infra flag + infrastructure state write to scaffold.md        [depends: B, E]
Task G: Add canary-write check to scaffold.md Step 0-MCP                    [depends: F]
Task H: Add YOLO+no-MCP block to scaffold.md + implement-feature.md        [depends: G]
Task I: Update roadmap.md + CHANGELOG.md                                    [depends: all]
```

Due to heavy scaffold.md contention, the most practical approach is:
1. Create core/mcp-detection.md (standalone)
2. Edit state/schema.md + core/state-manager.md (standalone, parallel with 1)
3. Edit init.md (items 1 refactor + item 2 detection — sequential)
4. Edit scaffold.md (items 1 refactor + 4 + 5 + 6 — single coordinated edit)
5. Edit implement-feature.md (item 6 — standalone)
6. Update docs (roadmap, changelog)
