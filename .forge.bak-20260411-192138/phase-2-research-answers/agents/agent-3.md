# Agent 3 — Path Resolution Fix for trackers.md in check-setup

## 1. Chosen Approach: Glob-Based Path Discovery

**Mechanism:** Replace each bare `docs/reference/trackers.md` reference in the skill prose with an explicit instruction to locate the file via the Glob tool before reading it.

The skill instructs the LLM to:
1. Use `Glob("**/docs/reference/trackers.md")` to locate the file within the plugin installation cache.
2. Read the first match returned by Glob.
3. If Glob returns no results, fall back to reading `docs/reference/trackers.md` relative to CWD (the consuming project root).
4. If neither path resolves, emit `[WARN] trackers.md not found — per-tracker validation skipped`.

## 2. Why Glob Over ${CLAUDE_PLUGIN_ROOT}

| Factor | Glob | ${CLAUDE_PLUGIN_ROOT} |
|--------|------|-----------------------|
| Already in allowed-tools | Yes (line 4 of frontmatter: `allowed-tools: mcp__*, Read, Glob, Grep, Bash`) | Requires adding a new variable expansion mechanism |
| Runtime discovery | Resolves the actual on-disk location regardless of install path | Depends on variable being correctly expanded in every execution context |
| Fallback path | Naturally composable with a CWD fallback | No fallback without additional conditionals |
| Convention consistency | Read + Glob is already the pattern used for .mcp.json discovery (Steps 6–7) | New pattern with no precedent in this skill |
| Risk if variable fails silently | N/A | Skill reads wrong path, silently returns empty or wrong content |

Glob is the most defensive choice and requires zero changes to the skill's allowed-tools list.

## 3. Exact Text Changes — Before / After

### Reference 1 — Line 32 (Step 3a)

**BEFORE:**
```
Read `docs/reference/trackers.md`. Find the row matching the configured Type in the Validation Rules table.
```

**AFTER:**
```
Locate trackers.md: use Glob with pattern `**/docs/reference/trackers.md`. Read the first result.
If Glob returns no matches, read `docs/reference/trackers.md` (relative to CWD) as a fallback.
If the file cannot be found by either method → [WARN] "trackers.md not found — per-tracker validation skipped" and skip the rest of Step 3a.
Find the row matching the configured Type in the Validation Rules table.
```

---

### Reference 2 — Line 59 (Step 7, Issue tracker MCP sub-bullet)

**BEFORE:**
```
- Issue tracker MCP: read the MCP Server Detection table from `docs/reference/trackers.md`.
    Find the row matching Type. Search .mcp.json server names/URLs for the listed keywords.
```

**AFTER:**
```
- Issue tracker MCP: locate trackers.md using the same Glob resolution as Step 3a (reuse the
    already-resolved path; do not Glob again). Read the MCP Server Detection table.
    Find the row matching Type. Search .mcp.json server names/URLs for the listed keywords.
    If trackers.md was unavailable in Step 3a → [WARN] "trackers.md not found — MCP server keyword match skipped."
```

**Key design decision for line 59:** Reference the resolution already performed in Step 3a rather than Glob-ing a second time. This avoids redundancy and makes it explicit that both references share a single resolution result. The skill should store the resolved path mentally (or re-read the same file) — the prose makes this clear with "reuse the already-resolved path."

## 4. Preamble About Path Resolution

**Recommendation: Yes, add a short preamble — but place it as a note inside Step 3a, not at the top of the file.**

Rationale: The skill top-level section "Check Setup" is a user-facing description. A technical path-resolution note there would be confusing to users reading the skill description. Placing it inline at the first usage point (Step 3a) keeps it actionable and co-located with the code that needs it.

Suggested preamble text (add as a blockquote immediately before Step 3a):

```
> **Path resolution note:** `trackers.md` lives in the plugin installation directory, not in the
> consuming project. Always locate it via Glob (`**/docs/reference/trackers.md`) before reading.
> Fall back to CWD-relative path only if Glob returns no results.
```

## 5. Scope Note — Other Files With the Same Pattern

The bare `docs/reference/trackers.md` path appears in **14 files total** across the repository:

- `skills/check-setup/SKILL.md` — **this task, fixed here**
- 12+ other skill SKILL.md files and core contract files — bare path, same latent failure mode
- `docs/` reference files — bare paths used for cross-linking (lower risk: docs are not executed)

**This task fixes check-setup only.** The remaining 12+ files should be migrated in a separate task titled something like "Fix bare trackers.md path in all skills and core contracts." The fix pattern is identical: replace bare `Read docs/reference/trackers.md` with the Glob-then-fallback instruction.

A grep for the migration scope:
```
pattern: docs/reference/trackers\.md
scope: skills/, core/
```

This will enumerate every file requiring the same treatment.

## 6. Implementation Checklist

- [ ] Add path resolution note blockquote before Step 3a heading
- [ ] Replace line 32 reference with Glob-then-fallback instruction (3 prose lines)
- [ ] Replace line 59 reference with "reuse already-resolved path" instruction
- [ ] Verify `Glob` remains in `allowed-tools` frontmatter (it already is — no change needed)
- [ ] No version bump required (patch-level behavior fix, no Automation Config contract change)
- [ ] Open a follow-up task for the remaining 12+ files with the same bare-path pattern
