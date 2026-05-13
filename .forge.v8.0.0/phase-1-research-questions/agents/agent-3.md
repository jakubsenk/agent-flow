# Phase 1 Agent 3 — Research Questions (Skeptical / QA-Engineer)

## Q1: How many existing tests will HARD-FAIL after v7.0.0 changes — and what is the complete list?

- **Why**: At least 5 scenarios hardcode counts/identifiers that v7.0.0 changes: `regression-skill-count-29.sh` asserts exactly 29 skill dirs; `ac-v68-doc-skill-count-29.sh` asserts "29 skills" in CLAUDE.md/skills.md; `v6.9.0-doc-count-drift.sh` asserts "19 optional config sections in total" and "skills/ directory count = 29"; `v6.9.0-bc-no-renamed-section.sh` enumerates all 19 sections including "Extra labels"; `config-reader-sections.sh` explicitly lists "Extra labels" in its array. The spec says only update/retire `v6.9.0-bc-no-renamed-section.sh` — but this is likely incomplete.
- **Files to read**: `tests/scenarios/regression-skill-count-29.sh`, `tests/scenarios/ac-v68-doc-skill-count-29.sh`, `tests/scenarios/v6.9.0-doc-count-drift.sh`, `tests/scenarios/v6.9.0-bc-no-renamed-section.sh`, `tests/scenarios/config-reader-sections.sh`, `tests/scenarios/xref-command-count.sh`, `tests/scenarios/v6.9.0-arch-freshness-refresh-on-release.sh`
- **Maps to release action**: Actions 1, 3, 4, 5 (all count/identifier changes)

## Q2: Does the spec correctly enumerate all 8 config templates that reference "Extra labels" — or only 2?

- **Why**: The spec claims `examples/configs/*.md` (all 8 templates) reference `Extra labels`, but a live grep found matches in only 2 files: `redmine-oracle-plsql.md` and `github-nextjs.md`. If only 2 of 8 templates contain `Extra labels`, the Phase 7 executor must NOT touch the other 6, and the TDD spec may over-count changes. Per `feedback_never_trust_spec.md`: read the file, do not trust the count.
- **Files to read**: All 8 files in `examples/configs/` (`github-nextjs.md`, `github-python-fastapi.md`, `github-dotnet.md`, `gitea-spring-boot.md`, `jira-react.md`, `youtrack-python.md`, `redmine-rails.md`, `redmine-oracle-plsql.md`) — grep each for "Extra labels"
- **Maps to release action**: Action 1 (delete Extra labels)

## Q3: Which exactly 6 skills implement pause-on-NEEDS_CLARIFICATION semantics, and do `analyze-bug` and `resume-ticket` qualify?

- **Why**: The spec states "Pause Limits applies to 6 skills" and lists fix-ticket, fix-bugs, implement-feature, scaffold, autopilot, resume-ticket as the presumed set. But `skills/analyze-bug/SKILL.md` has a NEEDS_CLARIFICATION handler (interactive-only, no state.json pause). And `resume-ticket` implements the *resume* side, not the *pause* side. The doc fix must name the correct 6 — a wrong list in `automation-config.md` is a new accuracy bug.
- **Files to read**: `skills/fix-ticket/SKILL.md` (line ~195 and ~419), `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/autopilot/SKILL.md`, `skills/resume-ticket/SKILL.md`, `skills/analyze-bug/SKILL.md`, `docs/reference/automation-config.md:40`
- **Maps to release action**: Action 2 (fix Pause Limits doc mapping)

## Q4: Does `core/config-reader.md` reference "Extra labels" as a parseable section — meaning it must also be updated when the section is deleted?

- **Why**: `config-reader-sections.sh` checks that every section in CLAUDE.md's optional table is ALSO present in `core/config-reader.md`. If `Extra labels` is listed in `core/config-reader.md` and we delete it from CLAUDE.md/automation-config.md without also removing it from `core/config-reader.md`, this test will continue to pass but `core/config-reader.md` will contain a stale section definition. Conversely, if we remove it from `core/config-reader.md` but `config-reader-sections.sh` still hardcodes "Extra labels" in its array (line 25), the test will FAIL.
- **Files to read**: `core/config-reader.md` (grep for "Extra labels"), `tests/scenarios/config-reader-sections.sh` (full file)
- **Maps to release action**: Action 1 (delete Extra labels) — cross-file consistency

## Q5: What is the exact structure of the workflow-router intent table — specifically, does it list `/ceos-agents:status`, `/ceos-agents:init`, and `/ceos-agents:create-pr` as distinct rows, or are they embedded in intent descriptions?

- **Why**: The spec says to update the workflow-router intent table for all 3 renamed/deleted skills. If these skills appear as embedded text inside intent descriptions (not as isolated rows), the update pattern is different and more fragile. Also: does the workflow-router intent table have a row for `/publish` that will need updating when auto-detect logic changes the skill's description?
- **Files to read**: `skills/workflow-router/SKILL.md` (full intent table section)
- **Maps to release action**: Actions 3, 4, 5 (rename status, rename init, delete create-pr + rewrite publish)

## Q6: Does `tests/scenarios/skills-directory-structure.sh` enumerate skill directory names explicitly (making it a hard-fail when `status/` and `init/` dirs are renamed)?

- **Why**: `tests/scenarios/skills-directory-structure.sh` matched a grep for "create-pr" — meaning it either enumerates skill dirs by name or checks for specific ones. If it has a hardcoded list that includes `status`, `init`, or `create-pr`, renaming/deleting those directories will cause a FAIL that the spec does not mention. Similarly, `skills-frontmatter-check.sh` matched "create-pr" and may iterate over all skill dirs.
- **Files to read**: `tests/scenarios/skills-directory-structure.sh`, `tests/scenarios/skills-frontmatter-check.sh`, `tests/scenarios/no-mcp-jargon-errors.sh`
- **Maps to release action**: Actions 3, 4, 5 (directory renames and deletion)

## Q7: Does `docs/reference/automation-config.md:40` accurately describe the Pause Limits row's "applies to" column — and is line 40 actually the only location, or does the section body also state "/autopilot only"?

- **Why**: The spec targets `automation-config.md:40` for the Pause Limits mapping fix, but live grep shows Pause Limits appears at lines 40, 460, 470, AND 628 in `automation-config.md`. If the section body at lines 460-470 also says "/autopilot only" (or implies it), only fixing line 40 leaves the doc partially incorrect. The spec assumption that a single line edit resolves this must be verified.
- **Files to read**: `docs/reference/automation-config.md` lines 35-50 (table row), lines 455-480 (section content), lines 620-640 (another occurrence)
- **Maps to release action**: Action 2 (fix Pause Limits doc mapping)

## Q8: Does the `ac-v68-doc-optional-sections-18.sh` test accept "18 optional" as PASS — meaning after v7.0.0 drops to 18 sections, this old test silently passes AND creates a false-positive acceptance signal?

- **Why**: `ac-v68-doc-optional-sections-18.sh` checks `(18|19) optional` — it was written to handle v6.9.0's bump from 18 to 19 as valid. After v7.0.0 drops back to 18, this test will still PASS (18 matches the pattern), but `v6.9.0-doc-count-drift.sh` assertion 3 checks for the exact string "19 optional config sections in total" and will FAIL unless updated. This creates an asymmetric regression: one test silently passes while the other hard-fails. The fix for `v6.9.0-doc-count-drift.sh` must update the expected count from 19 to 18, but must not break the negative assertion at line 56-57 which rejects "18 optional config sections in total". Verify whether both tests need updating and whether updating one creates a contradiction with the other.
- **Files to read**: `tests/scenarios/ac-v68-doc-optional-sections-18.sh`, `tests/scenarios/v6.9.0-doc-count-drift.sh` lines 41-57, `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` lines 45-49 (mutation guard asserts array length == 19)
- **Maps to release action**: Action 1 (delete Extra labels — reduces optional count 19 → 18)
