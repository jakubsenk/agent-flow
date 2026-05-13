# Phase 4 Revision Round 2

Round-2 review (Reviewer 3 Devil's Advocate) returned FAIL with 1 CRITICAL + 2 HIGH + 1 MEDIUM + 1 MINOR finding, all centered on the round-1 extraction algorithm. Reviewers 1 and 2 returned PASS in round 2 (their other concerns were resolved in round 1). Round 2 surfaced that the "split at first delimiter" replacement for the original greedy regex had RESOLUTION_FAILED — the new algorithm could not extract `PROJ-123` from `PROJ-123-fix-crash` because YouTrack/Jira/Linear issue IDs themselves contain `-`.

This revision replaces the "split at delimiter" approach with a CANONICAL ISSUE-ID EXTRACTION REGEX that understands the structure of all 6 supported tracker ID shapes (youtrack, jira, linear, github, gitea, redmine).

## Round 2 Findings Addressed

- **f-r2-a1 (CRITICAL — broken extraction algorithm):** FIXED via regex extractor. SC-11 in requirements.md now specifies the canonical regex `^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)`. Design.md §3.1 Step 0d replaces the abandoned `${residue%%${post_delim}*}` idiom with the BASH_REMATCH-based extractor. Verified by runtime bash check: `bash -c 'r="PROJ-123-fix-crash"; [[ "$r" =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ]] && echo "${BASH_REMATCH[1]}"'` → `PROJ-123`.

- **f-r2-b2 (HIGH — no-hyphen validation regex incompatible with PROJ-123):** FIXED. The no-hyphen validation regex `^[A-Za-z0-9#._]+$` was a Round 1 artifact for the "split at delimiter" approach. With the regex extractor, the structural regex IS the validator — the canonical regex requires alphanumeric/digit content by construction and never matches dot-only strings. The v6.8.1 dot-only path-traversal defense (`! issue_id =~ ^\.+$`) is preserved as a defensive secondary check. Issue IDs CAN contain `-` (PROJ-123 is a valid extraction).

- **f-r2-c3 (HIGH — AC pinned to broken bash idiom):** FIXED. AC-PUBLISH-AUTO-DETECT-EXTRACTION-1 no longer requires the literal `%%${post_delim}*` idiom. Instead it requires the canonical regex character class `[A-Za-z][A-Za-z0-9_]*-[0-9]+` (or `BASH_REMATCH` / phrase `canonical extraction regex`) to appear in the skill prose, AND it includes an embedded runtime bash verification of the regex semantics (`[[ "$residue" =~ ... ]] && [[ "${BASH_REMATCH[1]}" == "PROJ-123" ]]`).

- **f-r2-d4 (MEDIUM — AC-EXTRACTION-2 OR-form too lax):** FIXED. AC-PUBLISH-AUTO-DETECT-EXTRACTION-2 now requires BOTH the input example `feature/PROJ-456` AND the asserted output `PROJ-456` AND an independent runtime bash check verifying `${BASH_REMATCH[1]} == "PROJ-456"`.

- **f-r2-e5 (MINOR — `/`-delimiter case still rejected hyphens):** FIXED. With the regex extractor approach, the post-`{issue-id}` delimiter character is no longer parsed or used as a split boundary at all. The canonical regex consumes only the issue-ID portion regardless of what character follows. Templates using `/`, `_`, or any other delimiter all work uniformly.

## Files Modified

- **requirements.md** (REQ-PUBLISH-AUTO-DETECT):
  - EARS clause (b) — replaced "delimiter-aware extraction" prose with "canonical issue-ID extraction regex `^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)`". Removed `^[A-Za-z0-9#._]+$` and `^[A-Za-z0-9#._-]+$` validator references; the canonical regex IS the validator.
  - SC-11 — fully rewritten as REGEX-EXTRACTOR form (6 steps; no `post_delim` parsing; explicit "split at delimiter abandoned in revision-2" rationale; tracker-coverage table promised in design).

- **design.md** (§3.1 Step 0c-0d):
  - Step 0c — removed `post_delim` parsing entirely; only `pre_prefix` is identified.
  - Step 0d — replaced delimiter-split pseudocode with BASH_REMATCH-based regex extractor; added 6-row tracker-coverage table (youtrack/jira/linear/github/gitea/redmine); expanded worked examples from 4 to 6 cases (added `fix/123-numeric-id` → `123`, `fix/#42-fix` → `#42`, `feature/ABC_DEF-789` → `ABC_DEF-789`).
  - §4.1 CHANGELOG migration item 4 — sub-bullet 1 reworded ("residue matches the canonical issue-ID extraction regex" instead of "delimiter-aware: split before first `{description}` delimiter"); added explicit note that the abandoned "split at first `-` delimiter" approach would have produced `PROJ` instead of `PROJ-123`.

- **formal-criteria.md** (5 ACs):
  - AC-PUBLISH-AUTO-DETECT-3 — replaced v6.8.1 charset regex check with canonical extraction regex check (looks for `[A-Za-z][A-Za-z0-9_]*-[0-9]+` AND numeric branch AND dot-only defense).
  - AC-PUBLISH-AUTO-DETECT-EXTRACTION-1 — removed `%%${post_delim}*` requirement; added regex character-class check + runtime bash verification.
  - AC-PUBLISH-AUTO-DETECT-EXTRACTION-2 — strengthened from OR-form to require BOTH input AND output strings AND runtime bash verification.
  - AC-PUBLISH-AUTO-DETECT-EXTRACTION-3 — added runtime bash check for prefix-strip step.
  - AC-PUBLISH-AUTO-DETECT-EXTRACTION-4 (NEW) — numeric-only ID coverage (`fix/123-numeric-id` → `123`).
  - AC-PUBLISH-AUTO-DETECT-EXTRACTION-5 (NEW) — hash-prefixed ID coverage (`fix/#42-fix` → `#42`).
  - Summary AC count — 92 → 94 (REQ-PUBLISH-AUTO-DETECT 19 → 21).

## ACs MODIFIED (all related to extraction)

- AC-PUBLISH-AUTO-DETECT-3 (regex contract)
- AC-PUBLISH-AUTO-DETECT-EXTRACTION-1 (PROJ-123 case)
- AC-PUBLISH-AUTO-DETECT-EXTRACTION-2 (PROJ-456 no-description case)
- AC-PUBLISH-AUTO-DETECT-EXTRACTION-3 (non-matching prefix case)

## ACs ADDED

- AC-PUBLISH-AUTO-DETECT-EXTRACTION-4 (numeric-only ID — github/gitea/redmine)
- AC-PUBLISH-AUTO-DETECT-EXTRACTION-5 (hash-prefixed ID — github/gitea/redmine)

## Test cases the canonical regex handles correctly

| branch | template | tracker style | regex branch matched | extracted issue_id |
|--------|----------|---------------|----------------------|--------------------|
| fix/PROJ-123-fix-crash | fix/{issue-id}-{description} | jira/youtrack/linear | `[A-Za-z][A-Za-z0-9_]*-[0-9]+` | PROJ-123 |
| feature/PROJ-456 | feature/{issue-id} | jira/youtrack/linear | `[A-Za-z][A-Za-z0-9_]*-[0-9]+` | PROJ-456 |
| chore/refactor-foo | fix/{issue-id}-{description} | (no prefix match) | (n/a — prefix strip fails) | "" |
| fix/123-numeric-id | fix/{issue-id}-{description} | github/gitea/redmine | `#?[0-9]+` | 123 |
| fix/#42-fix | fix/{issue-id}-{description} | github/gitea/redmine (`#`-prefix) | `#?[0-9]+` | #42 |
| feature/ABC_DEF-789 | feature/{issue-id} | youtrack (with underscore) | `[A-Za-z][A-Za-z0-9_]*-[0-9]+` | ABC_DEF-789 |

All 6 cases verified at runtime via `bash -c '... =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ...'`.

## What was NOT touched (per prompt constraint)

- All other content from round-1 revision is preserved verbatim (REQ-RENAME-STATUS, REQ-RENAME-INIT, REQ-DEL-CREATE-PR EARS texts; workflow-router exclusion contract; SC-7/SC-8 single-line annotations; SC-10 missing Branch naming; SC-12 detached HEAD FAIL; design.md §5.3 deferral resolution; design.md §8.2 Phase 8 grep commands).
- No new REQs introduced.
- CHANGELOG migration text bullet 4 high-level wording (HIGH-3 round-1 fix) is preserved; only the sub-bullet referring to the broken "delimiter-aware split" wording was replaced with the canonical-regex wording.
- `/check-setup` deprecated-config detector, README + installation guide collision warning, all 92 unrelated ACs, all 11 REQs are unchanged.

DONE — extraction regex fixed, 4 ACs modified, 2 ACs added, regex tested against {github,jira,youtrack,linear,gitea,redmine} ID shapes
