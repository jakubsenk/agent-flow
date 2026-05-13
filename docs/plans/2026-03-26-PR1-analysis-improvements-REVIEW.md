# PR #1: analysis-improvements — Review & Conflict Analysis

**PR:** https://gitea.internal.ceosdata.com/fsabacky/ceos-agents/pulls/1
**Author:** vludwig
**Branch:** `analysis-improvements` → `main`
**Created:** 2026-03-09 | **Last updated:** 2026-03-23
**Base:** v5.0.1 (`fc28419`) | **Current main:** v5.3.0 (`117cf38`)
**Files changed:** 14 (+177 / -45)
**Mergeable:** NO (2 conflicts)

---

## Summary of PR Changes

1. **Issue Quality Gate** — new step 4 in triage-analyst + spec-analyst for validating ticket quality before analysis
2. **Reproduction Walkthrough + Root Cause Sanity Check** — new mandatory steps 7-9 in code-analyst
3. **Module Docs** — new optional Automation Config section (`Path` key), consumed by code-analyst and architect
4. **Root cause iterations** — new Retry Limits key (default: 3), controls code-analyst iteration limit
5. **Onboard wizard update** — 13 optional sections, Retry Limits includes Root cause iterations + Spec iterations
6. **YouTrack env var rename** — `YOUTRACK_BASE_URL` → `YOUTRACK_URL` (bugfix)
7. **codegraph MCP config** — new example in `examples/mcp-configs/codegraph.json`

## Commits on PR Branch

| SHA | Date | Description |
|-----|------|-------------|
| `a58c7f5` | 2026-03-09 | Original implementation |
| `1fb6e64` | 2026-03-19 | **CR changes** — response to review |
| `2d80668` | 2026-03-23 | YouTrack URL fix |
| `79b758c` | 2026-03-23 | Codegraph MCP config example |

---

## Review Finding Resolution

Original review by fsabacky (2026-03-18) raised 4 Critical, 8 Important, 8 Minor, 8 Gaps. vludwig responded with commit `1fb6e64` on 2026-03-19.

### Critical Findings

| ID | Finding | Status | How Addressed |
|----|---------|--------|---------------|
| C-1 | fix-ticket not wired for Module Docs / Root cause iterations | FIXED | fix-ticket.md now reads both configs, passes in Context string, architect gets Module Docs path |
| C-2 | Tags `Incomplete Description` / `Needs Screenshots` may not exist in tracker | FIXED | Both tag references removed from triage-analyst and spec-analyst entirely |
| C-3 | Quality Gate has hardcoded section names — violates core design principle | FIXED | Replaced with functional questions ("Do I know what is wrong?", etc.) + content-based validation rules agnostic to ticket structure |
| C-4 | spec-analyst Quality Gate requires AC — destroys agent's primary value | FIXED | AC removed from required gate; only Description-level question required. AC inferred from description when not explicit |

### Important Findings

| ID | Finding | Status | How Addressed |
|----|---------|--------|---------------|
| I-1 | Root cause iterations not passed in Context string | FIXED | Both fix-bugs and fix-ticket now inject `Root cause iterations = {value}` in Context |
| I-2 | Module Docs path "passed as context" but actually not injected | FIXED | Variant B chosen — path actually injected into Context string + consumer list corrected |
| I-3 | Steps 8-9 in code-analyst logically misordered (deps needed before reproduction) | FIXED | Dependencies (step 5) and test coverage (step 6) now precede reproduction walkthrough (step 7) |
| I-4 | Partial report non-blocking but fixer has no instructions for `root cause confirmed: NO` | FIXED | fix-bugs and fix-ticket now route `root cause confirmed: NO` to Block handler instead of fixer |
| I-5 | fixer listed as Module Docs consumer but has no Module Docs step | FIXED | "fixer" removed from consumer list in all commands and automation-config.md |
| I-6 | implement-feature reads Root cause iterations but no consumer in feature pipeline | FIXED | Root cause iterations removed from implement-feature config block |
| I-7 | No fallback for non-deterministic repro steps | FIXED | code-analyst step 7 now has explicit non-deterministic fallback with skip + note |
| I-8 | Partial report instructs "produce standard Impact Report" but steps 8-10 not yet run | FIXED | Step reorder (deps+coverage before reproduction) + step 9 now mandates completing step 10 before report + `Completed steps` field added |

### Minor Findings

| ID | Finding | Status | How Addressed |
|----|---------|--------|---------------|
| M-1 | Step numbering 5, 5b, 5c inconsistency | FIXED | Sequential numbering: 5, 6, 7, 8 |
| M-2 | Partial report doesn't list completed steps | FIXED | `Completed steps: {list}` added to Partial analysis template |
| M-3 | implement-feature says "passed to code-analyst" but no code-analyst in feature pipeline | FIXED | Changed to "passed to architect as context" |
| M-4 | Visual bug tagging without feedback loop | FIXED | Entire visual bug detection section removed |
| M-5 | Spec iterations missing in onboard.md Retry Limits list | FIXED | Now includes `Spec iterations (default: 5)` |
| M-6 | `(max 3 candidates)` contradicts single confirmed root cause | FIXED | Changed to `{file:line — CONFIRMED}` / `{file:line — secondary defect}` |
| M-7a | root cause confirmed on two places without consistency rule | FIXED | Consistency rule added |
| M-7b | Quality Gate "empty" definition too narrow | FIXED | Section-based validation removed entirely; functional questions have no "empty" concept |

### Gaps

| ID | Finding | Status | How Addressed |
|----|---------|--------|---------------|
| Gap 1 | No naming convention for Module Docs files | PARTIAL | Fallback added ("skip if not found") but no explicit naming convention (e.g., `{module}.md`) |
| Gap 2 | Quality gate block handling not in commands | FIXED | "orchestrating command decides" text removed from agents |
| Gap 3 | architect invocation in fix-ticket missing Module Docs path | FIXED | Context string now includes Module Docs path |
| Gap 4 | "Effect of proposed fix" category error for read-only agent | FIXED | Changed to hypothetical "If this location were fixed, would the output change?" |
| Gap 5 | Visual bug detection is domain-specific | FIXED | Removed entirely |
| Gap 6 | Module Docs no fallback when file doesn't exist | FIXED | Both agents now say "skip this step and proceed without module documentation" |
| Gap 7 | "Continue downstream" vs "repeat steps 5-6" contradictory | FIXED | Single semantics: "Continue from current position downstream. Do NOT restart." |
| Gap 8 | Quality Gate section validation assumes markdown headings | FIXED | "Evaluate based on CONTENT, regardless of structure" |

### Verdict on CR Changes

**All 4 critical, all 8 important, all 8 minor, and 7/8 gaps were addressed.** Gap 1 (naming convention) is partially addressed — agents have fallback but no standardized path pattern. This is acceptable for a first release.

---

## Merge Conflicts

### Conflict 1: `agents/triage-analyst.md` (lines 65-74)

**Cause:** Main added step `5d. Extract reproduction steps for browser automation` (v5.1.0, commit `f45edd7`). PR renumbered steps to sequential (removing 5b/5c) and changed step 6→8.

**Main (ours):**
```markdown
5d. Extract reproduction steps for browser automation (only when bug is UI-related):
    - UI-related indicators: button, click, form, page, screen, modal, dialog, ...
    - If UI-related: extract ordered browser action steps
    - If reproduction steps are absent or non-UI → omit this field entirely
6. Output structured analysis:
```

**PR (theirs):**
```markdown
8. Output structured analysis:
```

**Resolution:** Keep browser automation step from main, renumber to fit PR's sequential scheme (becomes step 8, output becomes step 9). Need to also renumber steps 9 (checkpoint) accordingly.

### Conflict 2: `commands/onboard.md` — Two locations

**Location A (line 153):** Section list — PR adds `[13] Module Docs`, main adds `[13] Local Deployment`.

**Resolution:** Both are valid additions. Renumber: `[13] Module Docs`, `[14] Local Deployment`. Update "full" option text to "all 14 optional sections".

**Location B (line 185):** Section defaults — PR adds `Module Docs: Path`, main adds `Local Deployment` config.

**Resolution:** Both are valid. Include both entries.

---

## Compatibility Assessment

### Does the PR break the plugin?

**No, with the following caveats:**

1. **New optional config section** (Module Docs) is backward-compatible — MINOR bump per versioning policy
2. **New Retry Limits key** (Root cause iterations) has a default value — backward-compatible
3. **Agent behavior changes** (Quality Gate, Reproduction Walkthrough) are additive behavior improvements
4. **YouTrack URL rename** (`YOUTRACK_BASE_URL` → `YOUTRACK_URL`) is a **bug fix** — the MCP package actually uses `YOUTRACK_URL`

### Concerns after merge

1. **CLAUDE.md auto-merged** cleanly but should be verified manually — the PR adds `Root cause iterations` and `Module Docs` to the optional sections table, which now also includes v5.1-v5.3 additions (Browser Verification, Local Deployment, etc.)
2. **Step numbering in triage-analyst** will need careful verification after conflict resolution — v5.1.0 added step 5d for browser automation, PR renumbers everything. The browser step and PR's Quality Gate + sequential numbering must coexist correctly.
3. **docs/reference/automation-config.md** auto-merged but has sections from both v5.1-v5.3 and this PR — verify ordering and completeness.

### Version Impact

This PR constitutes a **MINOR** bump (new optional config section, new optional Retry Limits key). Since main is at v5.3.0, this would be v5.4.0 or incorporated into a larger release.

---

## Remaining Issues After CR Changes

1. **Gap 1 (PARTIAL):** No Module Docs file naming convention. Agent knows to "look for a matching documentation file" but convention is undefined. Low risk — agents will use their judgment.
2. **`Attachments` field removed from spec-analyst output template** — this was done to address C-3/Gap 5, but means spec-analyst no longer reports attachment findings. Minor information loss.
3. **Quality Gate `incomplete` handling:** Commands don't have explicit conditional for incomplete gate result. Both agents now just "Block" on incomplete — which feeds into the standard block flow. This is consistent but means no special handling (skip option) exists. Acceptable.

---

## Conflict Resolution Plan

1. Checkout `analysis-improvements` branch
2. Rebase onto main (or merge main into it)
3. Resolve `agents/triage-analyst.md`:
   - Keep PR's Quality Gate (functional questions)
   - Keep PR's sequential numbering
   - Insert main's browser automation step as step 8 (after complexity estimation, before output)
   - Renumber output step to 9, checkpoint to 10
4. Resolve `commands/onboard.md`:
   - Both Module Docs and Local Deployment as items [13] and [14]
   - Both default entries present in step 6f
   - Update "full" count to 14
5. Verify CLAUDE.md auto-merge result
6. Verify docs/reference/automation-config.md ordering
7. Run test suite: `./tests/harness/run-tests.sh`
8. Do NOT merge — leave for manual final review
