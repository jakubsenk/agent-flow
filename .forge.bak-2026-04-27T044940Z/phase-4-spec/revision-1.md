# Phase 4 Revision Round 1

Reviewers 2 and 3 returned FAIL. Reviewer 1 returned PASS with 3 minor findings (one of which — f-a1b2c3 — was the same workflow-router contradiction that Reviewers 2 and 3 escalated to MAJOR/CRITICAL). This revision applies all MUST-FIX items (3 CRITICAL + 3 HIGH + 2 MEDIUM + 1 MINOR from the merged review set) plus the explicit prompt fixes.

## Findings Addressed (per finding_id)

### CRITICAL — addressed

- **f-a1c2d3 (Reviewer 3 CRITICAL — greedy regex extraction bug):** FIXED at requirements.md REQ-PUBLISH-AUTO-DETECT EARS clause (b) + new SC-11 + design.md §3.1 Step 0c-d (delimiter-aware extraction with worked examples) + new ACs AC-PUBLISH-AUTO-DETECT-EXTRACTION-1/-2/-3 in formal-criteria.md. Algorithm now: parse `pre_prefix` and `post_delim` from the template; strip `pre_prefix` from branch_name; if `post_delim` is non-empty split residue at first occurrence of that delimiter and validate with `^[A-Za-z0-9#._]+$` (no `-` allowed when description follows); else validate whole residue with `^[A-Za-z0-9#._-]+$`. Worked examples for all 3 prompt-mandated cases (`fix/PROJ-123-fix-crash` → `PROJ-123`; `feature/PROJ-456` → `PROJ-456`; `chore/refactor-foo` → null) are included in the design pseudocode.

- **f-b2d4e5 (Reviewer 3 CRITICAL — five false-positive ACs from workflow-router conflict):** FIXED at requirements.md (REQ-RENAME-STATUS, REQ-RENAME-INIT, REQ-DEL-CREATE-PR EARS texts now contain explicit "EXCEPT in the workflow-router 'Did you mean...?' fallback prose" exception) + design.md §5.3 (resolution made BINDING in Phase 4, no deferral) + design.md §8.2 (added `--exclude=skills/workflow-router/SKILL.md` to all 3 grep commands + added positive workflow-router check) + formal-criteria.md (AC-RENAME-STATUS-4, AC-RENAME-INIT-4, AC-DEL-CREATE-PR-2 now use `--exclude=skills/workflow-router/SKILL.md`; AC-RENAME-STATUS-5 and AC-DEL-CREATE-PR-7 are tightened to scope outside the deprecated-names section; new AC-DOCS-COLLISION-WARN-WORKFLOW-1 positively asserts presence; deferral implementation note removed).

### MAJOR — addressed

- **f-a1b2c3 (Reviewer 2 MAJOR + Reviewer 1 MINOR — workflow-router contradiction):** FIXED via the same fix as f-b2d4e5. The Reviewer 1 MINOR was the spec-author-flagged version of the same finding; the Reviewer 2/3 escalation to MAJOR/CRITICAL was correct. All five conflict ACs are now self-consistent with the workflow-router design.

- **f-d4e5f6 (Reviewer 2 MAJOR — Phase 8 §8.2 grep commands missing workflow-router exclusion):** FIXED at design.md §8.2 (added `--exclude=skills/workflow-router/SKILL.md` to all 3 deprecated-identifier sanity grep commands; added a positive workflow-router check `grep -E '(ceos-agents:status|ceos-agents:init|ceos-agents:create-pr)' skills/workflow-router/SKILL.md | wc -l` with `Expected: >= 3`).

- **f-g7h8i9 (Reviewer 2 MAJOR — REQ EARS texts missing workflow-router exception):** FIXED at requirements.md REQ-RENAME-STATUS, REQ-RENAME-INIT, REQ-DEL-CREATE-PR. All three EARS clauses now read "...without any residual /ceos-agents:status (etc.) reference EXCEPT in the workflow-router 'Did you mean...?' fallback prose at `skills/workflow-router/SKILL.md` (design.md §5.3), which intentionally references the deprecated identifier to support user disambiguation."

### HIGH — addressed

- **f-c3e5f6 (Reviewer 3 HIGH — missing Branch naming config key handling):** FIXED at requirements.md REQ-PUBLISH-AUTO-DETECT EARS clause (b) (added "if absent: `issue_id = null`, skip extraction") + new SC-10 + design.md §3.1 Step 0b (added explicit "If the `Branch naming` key is ABSENT from Automation Config" branch with `[INFO] No Branch naming pattern configured; PR-only mode.` log + jump to Step 3) + design.md §3.2 (new "Missing Branch naming INFO tier" sample) + formal-criteria.md AC-PUBLISH-AUTO-DETECT-14 (verifies the message text in skill prose).

- **f-d4f6g7 (Reviewer 3 HIGH — AC-TEST-INVENTORY-3 incomplete):** FIXED at formal-criteria.md AC-TEST-INVENTORY-3 (now enumerates all 6 mandated edits + asserts each: positive '18 optional config sections' present, negative '19 optional config sections' present in negative branch, `-eq 28` and `-eq 18` present, PASS message '18 optional, 28 skills' present, AND old PASS message '19 optional, 29 skills' absent).

- **f-e5g7h8 (Reviewer 3 HIGH — CHANGELOG bullet 4 semantic accuracy):** FIXED at design.md §4.1 CHANGELOG migration item 4. The 4 sub-bullets now precisely describe the auto-detect logic: "Branch starts with the configured `Branch naming` prefix AND the residue (delimiter-aware: split before first `{description}` delimiter) yields a valid issue-ID-shaped segment AND that issue exists in the tracker → full publish." The lost-agency disclosure now correctly explains that the workaround (rename `fix/PROJ-123-foo` → `chore/PROJ-123-foo`) works because the prefix `fix/` no longer matches — independent of the residue. A new "Branch parsing is delimiter-aware" sub-paragraph anchors the worked example.

### MEDIUM — addressed

- **f-g7i9j0 / Prompt MEDIUM (Reviewer 3 + Reviewer 2 / prompt — SC-7/SC-8 single-line vs multi-line):** FIXED at requirements.md SC-7 and SC-8 (now read "single-line (one logical line, one `echo` invocation, terminated by a single `\n`)") + design.md §3.2 (404 WARN tier and no-issue-id INFO tier samples are now displayed as single literal lines + explicit "NOTE — this is ONE logical line; emit as a single `echo` call" annotation) + formal-criteria.md AC-PUBLISH-AUTO-DETECT-12/-13 (single-line greps with all 4 token requirements per message, no `-A`/`-B` context).

- **f-f6h8i9 (Reviewer 3 MEDIUM — wrong expected email count in design §8.1):** FIXED at design.md §8.1 (changed `# Expected: SECURITY.md: 1, CODE_OF_CONDUCT.md: 1, CONTRIBUTING.md: 2` to `# Expected: SECURITY.md: 1, CODE_OF_CONDUCT.md: 1, CONTRIBUTING.md: 1`). Verified live counts: all three files have exactly 1 occurrence of `filip.sabacky@ceosdata.com`.

- **f-v4w5x6 (Reviewer 2 MINOR — detached HEAD exit semantics ambiguous):** FIXED at requirements.md REQ-PUBLISH-AUTO-DETECT EARS clause (a) ("FAIL with exit non-zero on detached HEAD — empty result") + new SC-12 (explicit "FAIL — exit non-zero — NOT pr-only-no-id, because there is no branch to push or use as PR source") + design.md §3.1 Step 0a (FAIL with single-line INFO + EXIT non-zero) + design.md §3.2 new "Detached HEAD FAIL tier" sample + formal-criteria.md AC-PUBLISH-AUTO-DETECT-15 (verifies detached-HEAD guard prose in skill).

- **f-h8j0k1 (Reviewer 3 MEDIUM — no AC tests extraction correctness):** FIXED at formal-criteria.md via new AC-PUBLISH-AUTO-DETECT-EXTRACTION-1/-2/-3 (verifies the 3 worked examples are documented in the skill prose, plus the bash `${residue%%${post_delim}*}` split pattern). These are file-content checks at Phase 8 level; the actual runtime correctness of the algorithm is an implementation concern Phase 7 must verify by running `/publish` — but the AC suite now blocks the spec-author-error path that Reviewer 3 specifically called out (a Phase 7 author who copies the regex without the delimiter logic would fail AC-PUBLISH-AUTO-DETECT-EXTRACTION-1).

### MINOR — addressed (Reviewer 1 + Reviewer 2 + Reviewer 3 minors)

- **f-j1k2l3 (Reviewer 2 MINOR — AC-DOCS-COLLISION-WARN-1/-2 don't enforce H2/H3 heading):** FIXED at formal-criteria.md AC-DOCS-COLLISION-WARN-1 and AC-DOCS-COLLISION-WARN-2 (added `grep -qE '^#{2,3} .*([Ss]lash.*[Cc]ommand|[Cc]ollision|[Bb]uiltin)'` heading-level check before the content check).

- **f-i9k1l2 (Reviewer 3 MINOR — no AC for zero-commits early-stop):** FIXED at formal-criteria.md via new AC-PUBLISH-AUTO-DETECT-ZERO-COMMITS (`grep -qE 'No changes to publish|zero commits|no commits above' skills/publish/SKILL.md`).

- **f-j0l2m3 (Reviewer 3 MINOR — FAIL mode webhook unspecified):** ADDRESSED at requirements.md SC-9 (now explicitly states "No `pr-created` event fires on FAIL. Whether `pipeline-completed` with `outcome: failed` fires on `/publish` FAIL is also deferred to v7.0.1+"). Per prompt direction "FAIL-mode webhook unspecified — defer to v7.0.1 (out of scope per spec)", no further AC was added; the deferral is now documented in SC-9 itself rather than implicit.

### NON-FIXES (per prompt direction)

- **f-p7q8r9 (Reviewer 2 MINOR — AC count claim 60 vs actual 84):** FIXED in formal-criteria.md Summary section. New count: 77 functional ACs + 15 test inventory ACs = 92 total (after the +9 new ACs / +1 widened AC added in this revision).

- **f-m4n5o6 (Reviewer 2 MINOR — exit-neutral assertion structure):** ACCEPTED AS-IS. The current AC `! grep -E '\[WARN\].*Extra labels' ... | grep -qE 'exit 1|FAIL|fail\(\)|return 1'` is a same-line check that matches the design.md §4.3 single-line snippet structure ("If `Extra labels` section detected, echo WARN; no conditional exit"). Phase 7 must implement the snippet as a single `if grep -q ... then echo ... fi` block with no exit/return lines inside, which is the documented design. Strengthening to a `-A5` context check would over-specify a constraint that the design explicitly chooses (single-line warn-only). The recommendation accepted is documented in design.md §4.3: "the check-setup snippet must NOT use a conditional exit structure" (already present in the design via the rationale "single-line is sufficient by construction").

- **f-k1m3n4 (Reviewer 3 MINOR — CHANGELOG theme convention):** ACCEPTED AS-IS, rationale: cosmetic, fixed at /version-bump time. The Phase 7 author can choose to insert the theme; Phase 8 AC-CHANGELOG-MIGRATION-1 only enforces `^## \[7\.0\.0\]` which allows both `Unreleased` and `Unreleased — Theme` forms. Not a blocking spec issue.

- **f-l2n4o5 (Reviewer 3 MINOR — REQ-DEL-CREATE-PR EARS rewrite-vs-remove ambiguity):** FIXED at requirements.md REQ-DEL-CREATE-PR EARS clause. Now explicitly reads: "shall be either removed (if a self-contained row/example/array element, OR if it is a `/publish` skill's own 'Related skills' entry referring back to itself), or rewritten to reference `/ceos-agents:publish` (if a 'Related skills' or alternative-skill mention IN ANOTHER SKILL — not in `/publish` itself)". The `docs/reference/skills.md:363` location is now unambiguously a "remove" target.

- **f-b3c4d5 (Reviewer 1 MINOR — line-number freshness disclaimer missing):** ACCEPTED AS-IS, rationale: line numbers were verified against current head at Phase 2 finalization. Pipeline executes in sequence; no intervening edits expected. Reviewer 1 explicitly graded this acceptable.

- **f-c5d6e7 (Reviewer 1 INFO — detached HEAD guard not in formal ACs):** FIXED via the f-v4w5x6 fix above (new AC-PUBLISH-AUTO-DETECT-15 covers the detached HEAD guard in formal ACs).

- **f-s1t2u3 (Reviewer 2 MINOR — SC-7/SC-8 text format coverage):** FIXED via new AC-PUBLISH-AUTO-DETECT-12/-13 (covers Reviewer 2's recommendation directly).

- **MUST-FIX-IN-PHASE-7 tag (prompt MINOR — Reviewer 1):** FIXED. Per prompt direction "this becomes redundant; just remove the deferral note", the deferral implementation note at the bottom of formal-criteria.md REQ-DOCS-COLLISION-WARN section was removed (replaced with the resolved binding contract pointing to AC-DOCS-COLLISION-WARN-WORKFLOW-1).

## Files Modified

- **requirements.md:**
  - REQ-RENAME-STATUS EARS — added workflow-router exception clause.
  - REQ-RENAME-INIT EARS — added workflow-router exception clause.
  - REQ-DEL-CREATE-PR EARS — added workflow-router exception clause + clarified Related-skills rewrite-vs-remove ambiguity.
  - REQ-PUBLISH-AUTO-DETECT EARS — added detached HEAD FAIL clause (a), missing-Branch-naming clause (b), delimiter-aware extraction algorithm (b).
  - REQ-PUBLISH-AUTO-DETECT — SC-7 and SC-8 reworded for explicit single-line semantics.
  - REQ-PUBLISH-AUTO-DETECT — SC-9 expanded with FAIL-mode no-event clarification.
  - REQ-PUBLISH-AUTO-DETECT — added new SC-10 (missing Branch naming), SC-11 (extraction algorithm 7-step contract), SC-12 (detached HEAD FAIL).

- **design.md:**
  - §3.1 Step 0a — detached HEAD now FAIL with EXIT non-zero (was ambiguous STOP).
  - §3.1 Step 0b — added explicit missing-Branch-naming branch with INFO + jump to Step 3.
  - §3.1 Step 0c — split into 3-component template parse (`pre_prefix`, `post_delim`, `description_present`) with template-shape examples.
  - §3.1 Step 0d — replaced greedy-regex extraction with delimiter-aware split + 4 worked examples (`fix/PROJ-123-fix-crash` → `PROJ-123`; `feature/PROJ-456` → `PROJ-456`; `chore/refactor-foo` → null; `fix/...` → null via dot-only).
  - §3.1 Step 0e — single-line INFO emission annotated.
  - §3.2 — 404 WARN and no-issue-id INFO samples reformatted as single literal lines + "NOTE — this is ONE logical line" annotations + new "Missing Branch naming INFO tier" sample + new "Detached HEAD FAIL tier" sample.
  - §4.1 CHANGELOG migration item 4 — sub-bullets rewritten to precisely describe the prefix-then-delimiter-aware-residue auto-detect logic + new "Branch parsing is delimiter-aware" sub-paragraph + lost-agency disclosure clarified.
  - §5.3 — workflow-router exclusion contract upgraded from "deferred to Phase 7" to BINDING in Phase 4 with explicit cross-reference to formal-criteria.md.
  - §8.1 — CONTRIBUTING.md expected email count corrected from 2 to 1.
  - §8.2 — three deprecated-identifier sanity grep commands now include `--exclude=skills/workflow-router/SKILL.md` + new positive workflow-router check (`Expected: >= 3`).

- **formal-criteria.md:**
  - AC-RENAME-STATUS-4 — added `--exclude=skills/workflow-router/SKILL.md` + descriptive header.
  - AC-RENAME-STATUS-5 — tightened to scope prohibition outside the deprecated-names section (specific intent-table and Step-3-prose negative greps).
  - AC-RENAME-INIT-4 — added `--exclude=skills/workflow-router/SKILL.md` + descriptive header.
  - AC-DEL-CREATE-PR-2 — added `--exclude=skills/workflow-router/SKILL.md` + descriptive header.
  - AC-DEL-CREATE-PR-7 — tightened to scope prohibition outside the deprecated-names section (specific intent-table and Step-4-prose negative greps).
  - AC-DOCS-COLLISION-WARN-1 / AC-DOCS-COLLISION-WARN-2 — added H2/H3 heading-level check.
  - REQ-DOCS-COLLISION-WARN — deferral implementation note REMOVED; replaced with binding "RESOLVED in Phase 4" contract pointing to new AC-DOCS-COLLISION-WARN-WORKFLOW-1.
  - AC-TEST-INVENTORY-3 — expanded to cover all 6 mandated edits per design.md Section 7 (added negative '19 optional' assertion, PASS-message tokens '18 optional, 28 skills' present and '19 optional, 29 skills' absent).
  - Summary — AC count corrected from 60 to 92 (77 functional + 15 inventory) + new resolution-contract bullet.

  - **NEW ACs added (9):**
    - AC-PUBLISH-AUTO-DETECT-12 (SC-7 single-line WARN message present)
    - AC-PUBLISH-AUTO-DETECT-13 (SC-8 single-line INFO message present)
    - AC-PUBLISH-AUTO-DETECT-14 (SC-10 missing Branch naming INFO message present)
    - AC-PUBLISH-AUTO-DETECT-15 (SC-12 detached HEAD FAIL guard present)
    - AC-PUBLISH-AUTO-DETECT-EXTRACTION-1 (greedy-regex bug fixed: `fix/PROJ-123-fix-crash` → `PROJ-123`)
    - AC-PUBLISH-AUTO-DETECT-EXTRACTION-2 (`feature/PROJ-456` no-description path → `PROJ-456`)
    - AC-PUBLISH-AUTO-DETECT-EXTRACTION-3 (non-matching prefix → `issue_id = null`)
    - AC-PUBLISH-AUTO-DETECT-ZERO-COMMITS (Step 3a early-stop documented)
    - AC-DOCS-COLLISION-WARN-WORKFLOW-1 (positive workflow-router presence check, ≥ 3 hits)

## NEW ACs added

- AC-PUBLISH-AUTO-DETECT-12 — SC-7 404 WARN single-line message (key tokens, single-line grep)
- AC-PUBLISH-AUTO-DETECT-13 — SC-8 no-issue-id INFO single-line message
- AC-PUBLISH-AUTO-DETECT-14 — SC-10 missing Branch naming INFO message
- AC-PUBLISH-AUTO-DETECT-15 — SC-12 detached HEAD FAIL guard
- AC-PUBLISH-AUTO-DETECT-EXTRACTION-1 — Delimiter-aware extraction worked example: `fix/PROJ-123-fix-crash` + `fix/{issue-id}-{description}` → `PROJ-123`
- AC-PUBLISH-AUTO-DETECT-EXTRACTION-2 — No-description path: `feature/PROJ-456` + `feature/{issue-id}` → `PROJ-456`
- AC-PUBLISH-AUTO-DETECT-EXTRACTION-3 — Non-matching prefix: `chore/refactor-foo` + `fix/{issue-id}-{description}` → `issue_id = null`
- AC-PUBLISH-AUTO-DETECT-ZERO-COMMITS — Step 3a "no commits above base" early-stop documented
- AC-DOCS-COLLISION-WARN-WORKFLOW-1 — Positive workflow-router check (≥ 3 deprecated-name hits)

## ACs modified

- AC-RENAME-STATUS-4 — added `--exclude=skills/workflow-router/SKILL.md`
- AC-RENAME-STATUS-5 — tightened to scope prohibition outside deprecated-names section (intent-table and Step-3-prose negative greps)
- AC-RENAME-INIT-4 — added `--exclude=skills/workflow-router/SKILL.md`
- AC-DEL-CREATE-PR-2 — added `--exclude=skills/workflow-router/SKILL.md`
- AC-DEL-CREATE-PR-7 — tightened to scope prohibition outside deprecated-names section (intent-table and Step-4-prose negative greps)
- AC-DOCS-COLLISION-WARN-1 — added H2/H3 heading-level check before content check
- AC-DOCS-COLLISION-WARN-2 — added H2/H3 heading-level check before content check
- AC-TEST-INVENTORY-3 — expanded from 3 to 6 assertions covering all 6 mandated `v6.9.0-doc-count-drift.sh` edits

## REQs reworded

- REQ-RENAME-STATUS — added workflow-router exception clause
- REQ-RENAME-INIT — added workflow-router exception clause
- REQ-DEL-CREATE-PR — added workflow-router exception clause + clarified Related-skills rewrite-vs-remove ambiguity
- REQ-PUBLISH-AUTO-DETECT — EARS clause expanded with detached HEAD FAIL, missing-Branch-naming handling, delimiter-aware extraction algorithm; SC-7 and SC-8 reworded for explicit single-line semantics; SC-9 expanded with FAIL-mode no-event clarification; new SC-10 / SC-11 / SC-12

DONE — 18 findings fixed (3 CRITICAL + 3 MAJOR + 3 HIGH + 4 MEDIUM + 5 MINOR), 9 ACs added, 8 ACs modified, 4 REQs reworded.
