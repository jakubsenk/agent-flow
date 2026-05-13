# Phase 1 Research — Bare Path Migration

Agent: agent-1
Date: 2026-04-11

---

## Q1: Canonical Glob-first Resolution Pattern (check-setup/SKILL.md lines 30-45)

**Source:** `skills/check-setup/SKILL.md` lines 30-45

The canonical pattern is defined in Step 3a under the heading "Per-tracker validation":

```markdown
### 3a. Per-tracker validation

> **Path note:** `trackers.md` lives in the plugin installation directory, not in the consuming
> project. Glob is used to handle CWD-context mismatch.

Locate `trackers.md`: Glob with pattern `.claude/plugins/**/docs/reference/trackers.md` first.
If no results, Glob with `**/docs/reference/trackers.md`. If still none, try `docs/reference/trackers.md` relative to CWD.
If multiple results, prefer the path containing `.claude/plugins/` or `ceos-agents/`; if ambiguous → [WARN] "Multiple trackers.md found — using {path}."
If the file cannot be found → [WARN] "trackers.md not found — per-tracker validation skipped. Verify plugin installation." and skip the rest of Step 3a.
```

**The 3-tier resolution algorithm:**
1. `Glob(".claude/plugins/**/docs/reference/trackers.md")` — plugin-install path first
2. `Glob("**/docs/reference/trackers.md")` — broad search fallback
3. `"docs/reference/trackers.md"` — bare CWD-relative as last resort

**Disambiguation rule:** If multiple results → prefer path containing `.claude/plugins/` or `ceos-agents/`; if still ambiguous → [WARN] "Multiple trackers.md found — using {path}."

**Not-found rule:** [WARN] (not [FAIL]) + skip the step gracefully. Never block the pipeline.

---

## Q2: Bare `docs/reference/trackers.md` References Per File

### 2a. `skills/onboard/SKILL.md`

**6 references total.** No path resolution exists for any of them — all are bare relative references.

| Line | Context | Step/Section | Type |
|------|---------|--------------|------|
| 68 | `read defaults from \`docs/reference/trackers.md\` Instance & Project Defaults table` | Step 2, sub-step 2 | look up in table |
| 70 | `read defaults from \`docs/reference/trackers.md\` Query Syntax table` | Step 2, sub-step 4 | look up in table |
| 72 | `read defaults from \`docs/reference/trackers.md\` Query Syntax table (Feature query format column)` | Step 2, sub-step 5 | look up in table |
| 75 | `read defaults from \`docs/reference/trackers.md\` State Transition Syntax table` | Step 2, sub-step 6 | look up in table |
| 76 | `read defaults from \`docs/reference/trackers.md\` On Start Set Defaults table` | Step 2, sub-step 7 | look up in table |
| 108 | `read from \`docs/reference/trackers.md\` PR Description Footer table` | Step 4b, tracker-specific footers | look up in table |

Lines 68–76 are all in **Step 2: Issue Tracker** (the tracker-selection wizard). Line 108 is in **Step 4b: PR Description Template**.

All 6 references are "look up in this table" style. The file has NO existing path resolution for any file (no Glob calls anywhere in SKILL.md). The `allowed-tools` for onboard are `Read, Glob, Write, Edit` — Glob IS available.

**Pattern implication:** Lines 68–108 span a single logical block (wizard steps 2–4). A single resolve-once at the top of Step 2 should cover all 6 references. The resolved path should be stored in-memory (e.g., `trackers_md_path`) and used for all subsequent reads.

---

### 2b. `skills/scaffold/SKILL.md`

**4 references total.** No path resolution exists — all are bare relative references. The file is large (exceeds 10000 tokens read limit, confirmed by read error on first attempt).

| Line | Context | Step/Section | Type |
|------|---------|--------------|------|
| 93 | `Instance URL (show format example from \`docs/reference/trackers.md\` Instance & Project Defaults table)` | Step 0-INFRA, "If tracker = ready" collection | look up in table |
| 169 | `required environment variables (from \`docs/reference/trackers.md\`)` | Step 0-MCP, failure guidance display | look up in table (env vars) |
| 484 | `Read the MCP Server Detection table from \`docs/reference/trackers.md\` for the package name` | Step 4b-replaced, Generate .mcp.json.example | look up in table |
| 543 | `see Sub-Issue Capabilities in \`docs/reference/trackers.md\`` | Step 4e, native sub-issue creation | look up in table / cross-reference check |

Steps 0-INFRA (line 93) and 0-MCP (line 169) are near the top of the skill. Steps 4b-replaced (line 484) and 4e (line 543) are much later. The two usage clusters are separated by ~300 lines, suggesting resolve-once at the very start (Step 0-INFRA) and reuse throughout.

The `allowed-tools` includes `Glob` — resolution is possible.

---

### 2c. `skills/init/SKILL.md`

**1 reference total.** No path resolution exists — bare relative reference.

| Line | Context | Step/Section | Type |
|------|---------|--------------|------|
| 36 | `use default from \`docs/reference/trackers.md\` Instance & Project Defaults table for the given type` | Step 0: Parameter Override, `--tracker-instance` default | look up in table |

This reference is inside the CLI-flag override path in Step 0. It is only consulted when `--tracker-instance` is NOT provided (fallback to default Instance URL from table). Single reference — no "resolve once, reuse" complexity needed, but Glob-first pattern should still be applied for consistency.

The `allowed-tools` for init includes `Glob` — resolution is possible.

---

### 2d. `core/mcp-detection.md`

**1 reference total.** No path resolution exists — bare relative reference.

| Line | Context | Step/Section | Type |
|------|---------|--------------|------|
| 19 | `from the MCP Server Detection table in \`docs/reference/trackers.md\`` | Process step 1 — MCP package lookup | look up in table |

The reference is in the core contract's Process step 1 (the first and only step that uses the table). The surrounding context (lines 19-29) even inlines the table as a fallback reference — the LLM is instructed to look up from `trackers.md` first, but the inline table is provided in the core file itself as a static copy.

**Important complication:** `core/mcp-detection.md` is a shared contract file referenced by multiple skills. It has NO `allowed-tools` frontmatter (it is not a skill — it is a markdown reference document read by other agents). The caller (skill) is responsible for resolving paths before dispatching. Adding Glob-first resolution to `core/mcp-detection.md` directly may not be valid since this file is passively read, not executed.

**Resolution strategy:** The callers (`skills/init/SKILL.md` Step 3, `skills/scaffold/SKILL.md` Step 0-MCP) already resolve or could resolve `trackers.md` before invoking `core/mcp-detection.md`. The core file's reference is more documentation-style. The migration here may be to add a path note (like the one in `check-setup/SKILL.md` lines 32-33) rather than active resolution logic.

---

## Q3: Other Runtime-Relevant Files Referencing `docs/reference/trackers.md`

Grep results filtered for files NOT in `docs/`, `tests/`, `CHANGELOG.md`, `README.md`:

| File | Line | Notes |
|------|------|-------|
| `skills/onboard/SKILL.md` | 68, 70, 72, 75, 76, 108 | 6 bare refs — runtime skill |
| `skills/scaffold/SKILL.md` | 93, 169, 484, 543 | 4 bare refs — runtime skill |
| `skills/init/SKILL.md` | 36 | 1 bare ref — runtime skill |
| `core/mcp-detection.md` | 19 | 1 bare ref — shared contract |

**Files excluded (docs/plans, changelog, readme, tests) but noted for context:**
- `docs/plans/roadmap.md` line 462 — the migration is already tracked in the roadmap
- `docs/plans/brainstorm/IMPLEMENTATION-PLAN.md` — historical implementation plan
- `docs/plans/2026-03-03-redmine-tracker-support-*.md` — historical design docs

**Total runtime-relevant bare refs: 12 across 4 files.** No other skills or core files were found with bare `trackers.md` references.

---

## Q4: "Resolve Once, Reuse Later" Pattern in check-setup/SKILL.md

**Yes, this pattern exists explicitly.** It is the primary design principle of the Step 3a resolution block.

**Step 7 (lines 65-69)** explicitly references the earlier resolution:

```markdown
7. Compare MCP servers with Automation Config:
   - Issue tracker MCP: reuse the trackers.md path resolved in Step 3a (do not Glob again).
     Read the MCP Server Detection table. Find the row matching Type.
     Search .mcp.json server names/URLs for the listed keywords.
     If trackers.md was unavailable in Step 3a → [WARN] "trackers.md not found — MCP server keyword match skipped."
```

**Key phrase:** "reuse the trackers.md path resolved in Step 3a (do not Glob again)"

This is a deliberate design choice: resolve once at the earliest use point (Step 3a), store the resolved absolute path in a variable, and pass it forward to all subsequent steps that need the file. Step 7 explicitly forbids re-Glob-ing.

This is also enforced by a test: `tests/scenarios/check-setup-edge-cases.sh` lines 66-89 verify that:
1. Step 7 does NOT contain its own Glob for trackers.md
2. The Glob appears exactly once in the skill file (in Step 3a only)

**Replication guidance for target files:**

- **`skills/onboard/SKILL.md`:** Resolve once at the start of Step 2 (first use is line 68), store as `trackers_md_path`, use for all 6 references in Steps 2 and 4.
- **`skills/scaffold/SKILL.md`:** Resolve once at the start of Step 0-INFRA (first use is line 93, the earliest step), store as `trackers_md_path`, pass forward to Steps 0-MCP, 4b-replaced, and 4e.
- **`skills/init/SKILL.md`:** Single reference only (line 36, Step 0). Resolve inline at point of use with Glob-first pattern. No "reuse" needed.
- **`core/mcp-detection.md`:** Not a skill — cannot execute Glob. Add a path note (like check-setup lines 32-33) informing the calling skill to resolve the path and pass it in. The inline table at lines 20-29 already serves as a built-in fallback.

---

## Surprises and Complications

1. **`core/mcp-detection.md` is not executable** — it has no `allowed-tools` frontmatter and is passively read by other skills. Adding active Glob-first logic there would be architecturally incorrect. The right fix is a path note + relying on the caller to resolve.

2. **`skills/scaffold/SKILL.md` exceeds the read limit** — the file is >10,000 tokens. When read in one call, it errors. The 4 references are spread across ~450 lines (93 to 543), requiring offset-based reads to cover all instances. The migration must be tested in chunks.

3. **`skills/onboard/SKILL.md` has no Glob calls** — the allowed-tools includes Glob but it is never used. Adding the Glob-first resolution introduces a new tool usage pattern for this skill.

4. **The roadmap already documents this migration** at `docs/plans/roadmap.md` line 461-462, with the correct count of 13+ files (the Grep found 12 runtime references, matching the estimate when historical/docs refs are excluded).

5. **`skills/init/SKILL.md` has an inline fallback table** in `core/mcp-detection.md` (lines 20-29) — the mcp-detection core file already inlines the MCP lookup table, meaning even if `trackers.md` is not found, the core logic still works. This makes the `core/mcp-detection.md` reference lower priority.
