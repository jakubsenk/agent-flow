# Agent 3: Plugin Path Resolution Research

**Focus:** Q3 — How does `check-setup` resolve `docs/reference/trackers.md` and does the current approach work?

---

## Q3.1: All references to `trackers.md` in the codebase

**14 files** reference `trackers.md`. The complete list:

| File | Type | Context |
|------|------|---------|
| `skills/check-setup/SKILL.md` | Skill | Lines 32, 59 — relative bare path references |
| `skills/onboard/SKILL.md` | Skill | Lines 68, 70, 72, 75, 76, 108 — relative bare path references |
| `skills/scaffold/SKILL.md` | Skill | Lines 93, 169, 484, 543 — relative bare path references |
| `skills/init/SKILL.md` | Skill | Line 36 — relative bare path reference |
| `core/mcp-detection.md` | Core contract | Line 19 — relative bare path reference |
| `README.md` | Documentation | Line 260 — hyperlink |
| `CHANGELOG.md` | Documentation | Lines 146, 180, 182, 394, 695, 698, 699 — version history |
| `tests/scenarios/scaffold-tracker-integration.sh` | Test | Lines 10, 39, 41, 161, 166, 171, 176, 181, 186 — test assertions |
| `docs/plans/2026-03-03-redmine-tracker-support-design.md` | Plan | Multiple — design document |
| `docs/plans/2026-03-03-redmine-tracker-support-plan.md` | Plan | Multiple — implementation plan |
| `docs/plans/brainstorm/01-forgejo-mcp-fixes.md` | Brainstorm | Line 25 — table reference |
| `docs/plans/brainstorm/05-fix-bugs-token-discovery.md` | Brainstorm | Line 107 |
| `docs/plans/brainstorm/07-unified-improvements-summary.md` | Brainstorm | Lines 9, 28, 230 |
| `docs/plans/brainstorm/IMPLEMENTATION-PLAN.md` | Plan | Lines 577, 826, 1182 |

---

## Q3.2: `docs/reference/trackers.md` — occurrences and files

**Exact string `docs/reference/trackers.md` appears in 7 source files** (skill/core/test files, excluding docs/plans and CHANGELOG):

| File | Line | Verbatim reference |
|------|------|--------------------|
| `skills/check-setup/SKILL.md` | 32 | `Read \`docs/reference/trackers.md\`.` |
| `skills/check-setup/SKILL.md` | 59 | `read the MCP Server Detection table from \`docs/reference/trackers.md\`.` |
| `skills/onboard/SKILL.md` | 68 | `read defaults from \`docs/reference/trackers.md\` Instance & Project Defaults table` |
| `skills/onboard/SKILL.md` | 70 | `read defaults from \`docs/reference/trackers.md\` Query Syntax table` |
| `skills/onboard/SKILL.md` | 72 | `read defaults from \`docs/reference/trackers.md\` Query Syntax table (Feature query format column)` |
| `skills/onboard/SKILL.md` | 75 | `read defaults from \`docs/reference/trackers.md\` State Transition Syntax table` |
| `skills/onboard/SKILL.md` | 76 | `read defaults from \`docs/reference/trackers.md\` On Start Set Defaults table` |
| `skills/onboard/SKILL.md` | 108 | `Tracker-specific footers — read from \`docs/reference/trackers.md\` PR Description Footer table` |
| `skills/scaffold/SKILL.md` | 93, 169, 484, 543 | Various table references |
| `skills/init/SKILL.md` | 36 | Instance & Project Defaults table reference |
| `core/mcp-detection.md` | 19 | MCP Server Detection table lookup |

All uses are bare relative paths — no `${CLAUDE_PLUGIN_ROOT}` or `${CLAUDE_SKILL_DIR}` prefix.

---

## Q3.3: Content and purpose of `docs/reference/trackers.md`

File: `C:/gitea_ceos-agents/docs/reference/trackers.md` — 98 lines, 7 lookup tables.

**Purpose:** Single source of truth for all tracker-specific values. Used by multiple skills and the `core/mcp-detection.md` contract. Eliminates per-tracker inline logic from individual skill files.

**Tables:**
1. **Query Syntax** — Bug/Feature query format per tracker type (youtrack, github, jira, linear, gitea, redmine)
2. **State Transition Syntax** — State update format per tracker
3. **Instance & Project Defaults** — Default instance URLs and project format
4. **On Start Set Defaults** — Default On start set values
5. **PR Description Footer** — Issue link footer syntax per tracker
6. **Validation Rules** — Query, state transition, instance validation patterns
7. **MCP Server Detection** — Package names and keywords for `.mcp.json` matching (used by check-setup Block 2)
8. **Sub-Issue Capabilities** — Native sub-issue support, parent parameters, fallback strategies

**Relevant to check-setup:**
- `Validation Rules` table → used at line 32 (Block 1, step 3a)
- `MCP Server Detection` table → used at line 59 (Block 2, step 7)

File also exists in plugin cache at:
`C:/Users/FSABACKY/.claude/plugins/cache/ceos-agents/ceos-agents/6.1.9/docs/reference/trackers.md`

---

## Q3.4: Established patterns for cross-directory references in skill files

**Pattern survey across all `skills/*/SKILL.md` files:**

### Pattern A: bare relative path (dominant pattern in ceos-agents)
```
Follow `core/config-reader.md`.
Read `docs/reference/trackers.md`.
```
Examples: `fix-bugs/SKILL.md`, `fix-ticket/SKILL.md`, `check-deploy/SKILL.md`, `check-setup/SKILL.md`, `onboard/SKILL.md`, `scaffold/SKILL.md`.

All core contract files (`core/*.md`) are referenced as bare relative paths: `core/config-reader.md`, `core/state-manager.md`, `core/mcp-detection.md`, etc.

Similarly, `docs/reference/` and `docs/guides/` files:
- `docs/reference/trackers.md` — multiple skills
- `docs/reference/automation-config.md` — `onboard/SKILL.md` line 173, 192
- `docs/guides/tokens.md` — `init/SKILL.md` line 125

### Pattern B: `${CLAUDE_SKILL_DIR}` variable (used ONLY in `filip-superpowers` forge skill)
```
Use the Read tool to load `${CLAUDE_SKILL_DIR}/dispatch/phase-0.md`.
```
This pattern references files co-located with SKILL.md (sibling files in the skill's own directory). It is NOT used anywhere in ceos-agents.

### Pattern C: `${CLAUDE_PLUGIN_ROOT}` variable (not used in ceos-agents)
Used in hook command strings in `settings.json`. Not used in any SKILL.md or agent markdown. Example from `settings.local.json`:
```
CLAUDE_PLUGIN_ROOT='C:\\Users\\FSABACKY\\.claude\\plugins\\cache\\...' bash -c '...'
```

**Summary:** ceos-agents exclusively uses bare relative paths for all cross-directory references. No skill file uses `${CLAUDE_PLUGIN_ROOT}` or `${CLAUDE_SKILL_DIR}` in Read instructions.

---

## Q3.5: Does Claude Code provide `$PLUGIN_ROOT`, `$SKILL_DIR`, or similar?

**Yes — two environment variables are confirmed from official Claude Code plugin docs:**

| Variable | Resolves to | Source |
|----------|-------------|--------|
| `${CLAUDE_PLUGIN_ROOT}` | Absolute path to plugin's installation directory | Official docs (`plugins-reference`), confirmed in `02-real-plugin-comparison.md` |
| `${CLAUDE_SKILL_DIR}` | Directory containing the current skill's SKILL.md | Official docs Section 3, confirmed in `01-plugin-api-verification.md` |
| `${CLAUDE_PLUGIN_DATA}` | Persistent directory for plugin state | Official docs, mentioned alongside PLUGIN_ROOT |
| `${CLAUDE_SESSION_ID}` | Current session ID | Official docs Section 3, confirmed |

**Key quotes from `filip-superpowers` documentation** (cross-referencing its own plugin API research):
- `"${CLAUDE_PLUGIN_ROOT}: the absolute path to your plugin's installation directory."` (from Official docs, `plugins-reference`)
- `"${CLAUDE_SKILL_DIR}: Directory containing the current skill's SKILL.md. Use for reading co-located files."` (confirmed in `section-03-plugin-structure-v2.md` table, [01, Section 3])
- `"All script paths and hook commands MUST use ${CLAUDE_PLUGIN_ROOT} because plugins are cached at ~/.claude/plugins/cache/. Hardcoded relative paths will break."` (`02-real-plugin-comparison.md`, Finding 1.9)

**Critical clarification on CLAUDE_SKILL_DIR usage:** This variable is specifically for reading files co-located *within the skill's own directory* (sibling files). For files elsewhere in the plugin (like `docs/reference/trackers.md` relative to the plugin root), `${CLAUDE_PLUGIN_ROOT}` is the correct variable.

**However — important caveat:** These variables are used in Bash hook commands (in `settings.json`) where they are interpolated by the shell. For LLM-executed `Read` tool calls inside SKILL.md text, the LLM must know to resolve the variable. The `forge` skill successfully uses `${CLAUDE_SKILL_DIR}/dispatch/phase-0.md` in natural language (`"Use the Read tool to load ${CLAUDE_SKILL_DIR}/dispatch/phase-0.md"`), suggesting the LLM does understand and correctly resolve this variable.

---

## Q3.6: Exact location of `trackers.md` references in `check-setup/SKILL.md`

**File:** `C:/gitea_ceos-agents/skills/check-setup/SKILL.md`

**Line 32** (Block 1, step 3a):
```
Read `docs/reference/trackers.md`. Find the row matching the configured Type in the Validation Rules table.
```
Context: Per-tracker query/state-transition/instance validation step.

**Line 59** (Block 2, step 7):
```
   - Issue tracker MCP: read the MCP Server Detection table from `docs/reference/trackers.md`.
     Find the row matching Type. Search .mcp.json server names/URLs for the listed keywords.
```
Context: MCP server detection by keyword matching in `.mcp.json`.

Both are bare relative path references with no path variable or absolute path.

---

## Q3.7: How do skills reference `core/` directory files?

**Pattern:** All `core/` references in skill files use bare relative paths — identical to how `docs/reference/` is referenced.

Examples from `skills/fix-bugs/SKILL.md`:
```
Follow `core/config-reader.md`.
Follow `core/profile-parser.md` to determine skip/extra stages.
Follow `core/mcp-preflight.md` to verify MCP server availability.
Follow atomic write protocol from `core/state-manager.md`.
```

Examples from `core/mcp-detection.md` (a core file referencing another):
```
1. Look up MCP package and tool prefix from the MCP Server Detection table in `docs/reference/trackers.md`:
```
```
Follow `core/mcp-detection.md` with `service_type: "tracker"`.
```

**No skill file uses absolute paths, `${CLAUDE_PLUGIN_ROOT}`, or `${CLAUDE_SKILL_DIR}` for `core/` references.**

---

## Pattern Analysis: How Does the Codebase Handle Cross-Directory References?

### Current Approach

All cross-directory references in ceos-agents use **bare relative paths** (e.g., `core/state-manager.md`, `docs/reference/trackers.md`). This is consistent across all 26 skills and 11 core contracts.

### Why This Currently Works (or Appears To)

When ceos-agents skills run **from the plugin's own repository** (`C:/gitea_ceos-agents/` as CWD), all bare relative paths resolve correctly — `docs/reference/trackers.md` exists relative to CWD.

When skills run from a **consuming project** (a different directory), these paths fail:
- `core/config-reader.md` → NOT in consuming project
- `docs/reference/trackers.md` → NOT in consuming project

**This is a systemic issue, not just check-setup.** All pipeline skills use `core/*.md` references. These work because:
1. The LLM has already read the plugin's SKILL.md (which was loaded from the plugin cache) and the content of core contracts is injected into context at skill load time — OR
2. Claude Code resolves bare relative paths against the plugin root (not CWD) when interpreting skill content

**Key evidence:** The `core/` contract files are referenced by many skills (fix-bugs, fix-ticket, check-deploy, implement-feature, etc.) and these skills demonstrably work from consuming projects. This suggests Claude Code resolves bare relative paths in SKILL.md context against the **plugin installation directory** (CLAUDE_PLUGIN_ROOT), not against CWD.

### The Documented Correct Pattern (from filip-superpowers research)

From `filip-superpowers` forge skill and its own documentation:
- `${CLAUDE_SKILL_DIR}/filename.md` — for files co-located in the skill's own directory
- `${CLAUDE_PLUGIN_ROOT}/path/to/file.md` — for files anywhere in the plugin tree

From the forge execute.md:
> "When modifying SKILL.md, ensure that any cross-references to externalized files use the `${CLAUDE_SKILL_DIR}` variable for co-located files or `${CLAUDE_PLUGIN_ROOT}` for plugin-root-relative paths. Never hardcode absolute paths."

### Conclusion on Whether ceos-agents Has a Bug

**The issue is ambiguous.** There are two possible realities:
1. **Bug exists:** Bare relative paths resolve against CWD. Works only when CWD is the plugin repo. Fails for consuming projects. Fix: use `${CLAUDE_PLUGIN_ROOT}/docs/reference/trackers.md`.
2. **No bug:** Claude Code resolves bare relative paths in skill content against CLAUDE_PLUGIN_ROOT automatically. The `core/*.md` references work in consuming projects, which would be unexplainable if bare paths resolved against CWD.

**Evidence favoring reality 2:** The user's bug report specifically says "trackers.md — relativní cesta nefunguje: Skill odkazuje na docs/reference/trackers.md ale cesta je relativní k ceos-agents root, ne ke skill directory." — This says the path is relative to ceos-agents root, not the SKILL directory. This implies the path DOES resolve against plugin root for skill content, but the issue is something else — perhaps the LLM attempts `Read("docs/reference/trackers.md")` as a filesystem operation using CWD.

**The real failure mode:** The LLM executes a `Read` tool call with path `docs/reference/trackers.md`. Claude Code's Read tool resolves this against the current working directory (consuming project root). The file doesn't exist there. The LLM silently falls back to inference or reports an error.

---

## What Works and What Doesn't

### What Works
- Reading files from CWD (`.mcp.json`, `CLAUDE.md`, project source files) — these are in the consuming project
- SKILL.md content is loaded correctly from plugin cache (Claude Code handles this)
- `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_SKILL_DIR}` variables resolve correctly in shell hook commands

### What Doesn't Work
- `Read("docs/reference/trackers.md")` from a consuming project CWD — file not present there
- By extension, `Follow core/config-reader.md` may also not work as a Read tool call — but might work because core contract content could be inlined at skill load time

### Correct Fix for check-setup

Replace bare path references with `${CLAUDE_PLUGIN_ROOT}` prefix:

**Line 32:**
```
Read `${CLAUDE_PLUGIN_ROOT}/docs/reference/trackers.md`. Find the row matching the configured Type in the Validation Rules table.
```

**Line 59:**
```
   - Issue tracker MCP: read the MCP Server Detection table from `${CLAUDE_PLUGIN_ROOT}/docs/reference/trackers.md`.
```

**Alternative fix (more robust, avoids LLM variable interpretation):** Inline the two required tables (Validation Rules and MCP Server Detection) directly into `check-setup/SKILL.md`, eliminating the cross-file dependency entirely. The tables are small (6 rows × 4 columns each) and rarely change. This is how the plugin worked before the trackers.md centralization refactor (v5.x).

**Another alternative:** Copy the two tables to a co-located file `skills/check-setup/tracker-rules.md` and reference it as `${CLAUDE_SKILL_DIR}/tracker-rules.md`.

### Scope of the Bug

Since all pipeline skills reference `core/*.md` with bare relative paths, the fix scope should be evaluated:
- If `core/*.md` references work in consuming projects, then `docs/reference/trackers.md` references should also work (same mechanism)
- If the user specifically reports check-setup failing on trackers.md lookup, the issue may be specific to check-setup's execution context or to how the LLM handles the Read instruction
- The safest fix is to either inline the tables or use `${CLAUDE_PLUGIN_ROOT}`
