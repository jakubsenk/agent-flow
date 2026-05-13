# Phase 4 — Formal Acceptance Criteria (machine-checkable)
# v9.0.0 sub-projekt H — Agent I/O Contracts

**Companion to:** `requirements.md`, `design.md`
**Convention:** Every AC is checkable by a specific bash command, file existence test, or grep pattern. Verification methods reference scenario filenames that Phase 7 implements per design.md §3.

REPO_ROOT shorthand below: `R="C:/gitea_ceos-agents"`. All commands assume `cd $R` first.

---

## AC-H-001..009 — Output Contract section presence and shape

### AC-H-001
**Assertion:** Every file under `agents/*.md` (post-stack-selector-deletion = 17 files) contains a line matching `^## Output Contract$`.
**Verification:** `tests/scenarios/v9-output-contract-completeness.sh` exits 0.
**Pass condition:** `for f in $R/agents/*.md; do grep -qE '^## Output Contract$' "$f" || echo "MISS: $f"; done` produces zero MISS lines.
**Trace:** REQ-H-001, REQ-H-033.

### AC-H-002
**Assertion:** In every agent file, the line containing `^## Output Contract$` appears AFTER the first occurrence of `^## Process` (or `^## Process — Phase:` for polymorphic agents) and BEFORE the first occurrence of `^## Constraints$`.
**Verification:** `tests/scenarios/v9-output-contract-position.sh` exits 0 for every agent.
**Pass condition:** For every `agents/*.md` file: `process_line=$(grep -nE '^## Process' "$f" | head -1 | cut -d: -f1); oc_line=$(grep -nE '^## Output Contract' "$f" | head -1 | cut -d: -f1); cons_line=$(grep -nE '^## Constraints$' "$f" | head -1 | cut -d: -f1); [ "$process_line" -lt "$oc_line" ] && [ "$oc_line" -lt "$cons_line" ]`.
**Trace:** REQ-H-002.

### AC-H-003
**Assertion:** Every `## Output Contract` section (or every per-phase H3 sub-block for polymorphic agents) contains both an Inputs table header `Section | Source | Required` and an Outputs table header `Section produced | When | Required fields`.
**Verification:** `tests/scenarios/v9-output-contract-shape.sh` exits 0 (or 77 if SKIP-guard fires for unimplemented agents during transition; exits 0 for all 17 agents post-Phase 7).
**Pass condition:** For each agent's `## Output Contract` section content: `grep -qE 'Section \| Source \| Required'` AND `grep -qE 'Section produced \| When \| Required fields'`. AND at least one Outputs-table row matches `\| \`## [A-Za-z][A-Za-z _-]*\` \|`.
**Trace:** REQ-H-003, REQ-H-004, REQ-H-005, REQ-H-006.

### AC-H-004
**Assertion:** No agent file contains a section heading matching `^## Project-Specific Instructions$` (reserved by override injector).
**Verification:** `grep -lE '^## Project-Specific Instructions$' $R/agents/*.md` returns empty.
**Pass condition:** Exit code 1 (no match) from the grep.
**Trace:** REQ-H-022.

---

## AC-H-010..019 — Polymorphism (per-phase blocks for 4 agents)

### AC-H-010
**Assertion:** `agents/analyst.md` `## Output Contract` section contains both H3 sub-headings `### Output Contract — Phase: triage` and `### Output Contract — Phase: impact`.
**Verification:** `tests/scenarios/v9-output-contract-polymorphic-split.sh` (analyst portion).
**Pass condition:** `grep -qE '^### Output Contract — Phase: triage$' $R/agents/analyst.md` AND `grep -qE '^### Output Contract — Phase: impact$' $R/agents/analyst.md`.
**Trace:** REQ-H-011.

### AC-H-011
**Assertion:** `agents/test-engineer.md` `## Output Contract` section contains both H3 sub-headings `### Output Contract — Default (no flag)` and `### Output Contract — Phase: --e2e`.
**Verification:** Same scenario, test-engineer portion.
**Pass condition:** Both `grep -qE '^### Output Contract — Default \(no flag\)$'` and `grep -qE '^### Output Contract — Phase: --e2e$'` in `$R/agents/test-engineer.md`.
**Trace:** REQ-H-012.

### AC-H-012
**Assertion:** `agents/browser-agent.md` `## Output Contract` section contains both H3 sub-headings `### Output Contract — Phase: reproduce` and `### Output Contract — Phase: verify`.
**Verification:** Same scenario, browser-agent portion.
**Pass condition:** Both H3 headings grep present in `$R/agents/browser-agent.md`.
**Trace:** REQ-H-013.

### AC-H-013
**Assertion:** `agents/spec-reviewer.md` `## Output Contract` section contains both H3 sub-headings `### Output Contract — Default (review mode)` and `### Output Contract — Phase: --verify`.
**Verification:** Same scenario, spec-reviewer portion.
**Pass condition:** Both H3 headings grep present in `$R/agents/spec-reviewer.md`.
**Trace:** REQ-H-014.

### AC-H-014
**Assertion:** Each per-phase H3 sub-block independently satisfies AC-H-003 — its own Inputs table + Outputs table with the required column headers, and at least one backtick-quoted `## Heading` row in the Outputs table.
**Verification:** `tests/scenarios/v9-output-contract-shape.sh` extends the section-extraction logic to operate per-H3-sub-block when polymorphic.
**Pass condition:** Per-sub-block awk-extracted content satisfies the same shape grep used in AC-H-003.
**Trace:** REQ-H-015.

---

## AC-H-020..029 — Backward compatibility

### AC-H-020
**Assertion:** `core/agent-override-injector.md` is unchanged from v8.0.0.
**Verification:** `git diff main..HEAD -- core/agent-override-injector.md` (manual inspection during Phase 8 release commit) returns empty.
**Pass condition:** Zero-byte diff for that file.
**Trace:** REQ-H-020.

### AC-H-021
**Assertion:** Existing `examples/customization/*.toml` and `examples/agent-overrides/**/*.md` example files inject without modification when applied via the override injector flow against v9.0.0 agents.
**Verification:** Manual protocol per design.md §8 — diff shows only the new `## Output Contract` section added; the appended `## Project-Specific Instructions` block is byte-identical pre/post.
**Pass condition:** `diff -u bc-fixture-v8-{agent}.txt bc-fixture-v9-{agent}.txt` shows additions ONLY inside the `## Output Contract` section; zero deletions; zero non-`## Output Contract` additions.
**Trace:** REQ-H-021, NFR-COMPAT-002.

---

## AC-H-030..039 — Test scenarios exist and pass

### AC-H-030
**Assertion:** All 6 new lint scenarios exist as executable bash files under `tests/scenarios/`.
**Verification:** File existence check.
**Pass condition:** `for s in v9-output-contract-shape v9-output-contract-completeness v9-output-contract-position v9-output-contract-polymorphic-split v9-xref-outputs-skill-references v9-agents-must-be-dispatched; do test -x "$R/tests/scenarios/$s.sh"; done` exits 0.
**Trace:** REQ-H-030.

### AC-H-031
**Assertion:** Every new v9 scenario, when invoked directly, exits 0 (PASS) on the v9.0.0 codebase. SKIP exits (77) are acceptable only for `v9-output-contract-shape.sh` and only during the transition — not after Phase 7 implementation completes.
**Verification:** `for s in tests/scenarios/v9-*.sh; do bash "$s" || echo "FAIL: $s"; done` produces zero FAIL lines.
**Pass condition:** Exit code 0 from each scenario.
**Trace:** REQ-H-039.

### AC-H-032
**Assertion:** `tests/harness/run-tests.sh` executes all v9 scenarios as part of the default test run and reports them in its summary.
**Verification:** Run the harness; capture stdout; grep for the 6 new scenario names.
**Pass condition:** `bash $R/tests/harness/run-tests.sh 2>&1 | grep -cE 'v9-output-contract-(shape|completeness|position|polymorphic-split)|v9-xref-outputs-skill-references|v9-agents-must-be-dispatched'` returns 6.
**Trace:** REQ-H-030; tests/harness/run-tests.sh enumerates scenarios.

### AC-H-033
**Assertion:** `v9-xref-outputs-skill-references.sh` emits zero failures — every backtick-quoted `## Heading` declared in any agent's Outputs table appears literally (modulo backticks) in at least one `skills/**/SKILL.md` or `skills/**/steps/*.md` file. Exclusions: `## NEEDS_*` sentinels and `## Output Contract` itself.
**Verification:** Run the scenario; assert exit 0.
**Pass condition:** `bash $R/tests/scenarios/v9-xref-outputs-skill-references.sh; echo $?` = 0.
**Trace:** REQ-H-034, REQ-H-060.

### AC-H-034
**Assertion:** `v9-agents-must-be-dispatched.sh` emits zero failures — every agent file under `agents/*.md` is dispatched by at least one skill via strict-idiom `Task(subagent_type='ceos-agents:{name}', model='{tier}')`.
**Verification:** Run the scenario; assert exit 0.
**Pass condition:** `bash $R/tests/scenarios/v9-agents-must-be-dispatched.sh; echo $?` = 0.
**Trace:** REQ-H-035, REQ-H-081.

---

## AC-H-040..049 — stack-selector deletion

### AC-H-040
**Assertion:** `agents/stack-selector.md` does NOT exist on the v9.0.0 commit.
**Verification:** `test -f $R/agents/stack-selector.md`.
**Pass condition:** `test ! -f $R/agents/stack-selector.md && echo OK` returns OK.
**Trace:** REQ-H-080.

### AC-H-041
**Assertion:** `skills/scaffold/SKILL.md` no longer references `stack-selector` in any line — the prose `stack-selector → scaffolder → ...` text at line 91 is rewritten to remove the reference.
**Verification:** `grep -E 'stack-selector' $R/skills/scaffold/SKILL.md` returns empty.
**Pass condition:** `grep -cE 'stack-selector' $R/skills/scaffold/SKILL.md` returns 0.
**Trace:** REQ-H-080.

### AC-H-042
**Assertion:** `agents/rollback-agent.md` no longer lists `stack-selector` in its read-only-blocking-agent skip list (Process step 1 / Constraints).
**Verification:** `grep -E 'stack-selector' $R/agents/rollback-agent.md` returns empty.
**Pass condition:** `grep -cE 'stack-selector' $R/agents/rollback-agent.md` returns 0.
**Trace:** REQ-H-083.

### AC-H-043
**Assertion:** No file under `skills/**/*.md` contains the literal `subagent_type='ceos-agents:stack-selector'` or `Run ceos-agents:stack-selector`.
**Verification:** `grep -rE "ceos-agents:stack-selector" $R/skills/` returns empty.
**Pass condition:** `grep -rcE "ceos-agents:stack-selector" $R/skills/ | grep -v ':0$'` returns empty (zero non-zero counts).
**Trace:** REQ-H-080.

### AC-H-044
**Assertion:** CLAUDE.md `## Architecture: 2-Layer System` Agents enumeration line lists exactly 17 agents (stack-selector removed).
**Verification:** Count comma-separated names in the agents list line at CLAUDE.md:35 (or wherever the list now lives).
**Pass condition:** `grep -E '^\*\*Agents\*\*' $R/CLAUDE.md | head -1 | tr ',' '\n' | wc -l` returns 17.
**Trace:** REQ-H-082.

---

## AC-H-050..059 — Dispatch idiom harmonization

### AC-H-050
**Assertion:** No file under `skills/**/*.md` contains the legacy prose dispatch idiom `Run ceos-agents:{name} (Task tool, model: ...)` or its variants `Run \`ceos-agents:{name}\` (Task tool, model: ...)` or `Dispatch ceos-agents:{name} (Task tool, model: ...)`.
**Verification:** Recursive grep across skills directory.
**Pass condition:** `grep -rE '(Run|Dispatch) \`?ceos-agents:[a-z-]+\`?\s*\(Task tool' $R/skills/` returns empty.
**Trace:** REQ-H-090.

### AC-H-051
**Assertion:** Every agent dispatch in `skills/**/*.md` uses the strict idiom `Task(subagent_type='ceos-agents:{name}', model='{tier}')` with a `model='{tier}'` value matching the agent's frontmatter `model:` field.
**Verification:** For each strict-idiom occurrence, extract subagent_type + model, verify against agent frontmatter.
**Pass condition:** Bash spot-check (Phase 8): for each dispatch, `extracted_model == grep "^model:" agents/{name}.md | cut -d: -f2 | tr -d ' '`. Zero mismatches.
**Trace:** REQ-H-091.

### AC-H-052
**Assertion:** No agent file under `agents/*.md` is modified by the dispatch-idiom harmonization (REQ-H-090). The Phase 7 commits implementing harmonization touch only `skills/**/*.md`.
**Verification:** During the dispatch-idiom commit's diff inspection: `git show --stat <commit-hash>` lists only `skills/` paths.
**Pass condition:** Zero `agents/` paths in the harmonization commit's stat output.
**Trace:** REQ-H-092.

---

## AC-H-060..069 — CLAUDE.md amendments

### AC-H-060
**Assertion:** `CLAUDE.md` Versioning Policy table's MAJOR row text contains the new clause `mandatory new structured contract section in agent definition files that v8.0.0 agents would fail validation against`.
**Verification:** `grep -F 'mandatory new structured contract section' $R/CLAUDE.md`.
**Pass condition:** Exit code 0 from the grep.
**Trace:** REQ-H-050.

### AC-H-061
**Assertion:** `CLAUDE.md` contains the verbatim Versioning Policy clarification paragraph appended after the table (per REQ-H-051).
**Verification:** `grep -F 'Adding new static declaration sections to agent definition files' $R/CLAUDE.md` AND `grep -F 'structure-blind and is not "external tooling that parses" agent body sections' $R/CLAUDE.md`.
**Pass condition:** Both greps exit 0.
**Trace:** REQ-H-051.

### AC-H-062
**Assertion:** `CLAUDE.md` `## Cross-File Invariants` subsection lists 4 numbered invariants (was 3).
**Verification:** Count numbered list items immediately under the `## Cross-File Invariants` heading and before the next `## ` heading.
**Pass condition:** `awk '/^## Cross-File Invariants/{found=1; next} found && /^## /{exit} found' $R/CLAUDE.md | grep -cE '^[0-9]+\.\s+\*\*'` returns 4.
**Trace:** REQ-H-061.

### AC-H-063
**Assertion:** The 4th invariant in CLAUDE.md Cross-File Invariants subsection contains the literal phrase `Agent Output Contract ↔ skill xref consistency`.
**Verification:** `grep -F 'Agent Output Contract ↔ skill xref consistency' $R/CLAUDE.md`.
**Pass condition:** Exit code 0.
**Trace:** REQ-H-060.

### AC-H-064
**Assertion:** The 4th invariant references `tests/scenarios/v9-xref-outputs-skill-references.sh` as its verifier.
**Verification:** `grep -F 'tests/scenarios/v9-xref-outputs-skill-references.sh' $R/CLAUDE.md`.
**Pass condition:** Exit code 0.
**Trace:** REQ-H-060.

---

## AC-H-070..079 — Migration guide

### AC-H-070
**Assertion:** `docs/guides/migration-v8-to-v9.md` exists and is non-empty.
**Verification:** `test -s $R/docs/guides/migration-v8-to-v9.md`.
**Pass condition:** Exit code 0.
**Trace:** REQ-H-070.

### AC-H-071
**Assertion:** The migration guide contains all 4 required H2 section headings, in order: `## Overview`, `## Breaking Changes`, `## Migration Steps`, `## Compatibility Check`.
**Verification:** Extract H2 headings and assert order.
**Pass condition:** `grep -nE '^## (Overview|Breaking Changes|Migration Steps|Compatibility Check)$' $R/docs/guides/migration-v8-to-v9.md | awk -F: '{print $2}' | tr '\n' '|'` returns `## Overview|## Breaking Changes|## Migration Steps|## Compatibility Check|` (in this order).
**Trace:** REQ-H-070.

### AC-H-072
**Assertion:** The `## Breaking Changes` section enumerates at least 4 changes: mandatory `## Output Contract`, `.md` overlay hard removal, deprecated agent name hard errors, stack-selector deletion.
**Verification:** Section content greps.
**Pass condition:** Within the `## Breaking Changes` block: `grep -F 'Output Contract'`, `grep -F '.md agent overlays'`, `grep -F 'triage-analyst'`, `grep -F 'stack-selector'` ALL exit 0.
**Trace:** REQ-H-072.

### AC-H-073
**Assertion:** The `## Compatibility Check` section contains a copy-pasteable bash command that detects heading collisions with `## Output Contract` or `## Project-Specific Instructions` in `customization/*.md` files.
**Verification:** `grep -E 'grep .*-l.*Output Contract.*customization' $R/docs/guides/migration-v8-to-v9.md`.
**Pass condition:** Exit code 0.
**Trace:** REQ-H-074.

---

## AC-H-080..089 — Stale-list scenario fixes (REQ-H-036..H-038)

### AC-H-080
**Assertion:** `tests/scenarios/section-order.sh` AGENTS array enumerates exactly the 17 v9.0.0 agent names (no v7 names: triage-analyst, code-analyst, e2e-test-engineer, reproducer, browser-verifier; no stack-selector).
**Verification:** Inspect array contents.
**Pass condition:** Bash sources the file's array variable; `[ "${#AGENTS[@]}" -eq 17 ]` AND every element is one of the 17 valid v9 names.
**Trace:** REQ-H-036.

### AC-H-081
**Assertion:** `tests/scenarios/section-order.sh` PASSES on the v9.0.0 codebase.
**Verification:** Run the scenario.
**Pass condition:** `bash $R/tests/scenarios/section-order.sh; echo $?` = 0.
**Trace:** REQ-H-036.

### AC-H-082
**Assertion:** `tests/scenarios/frontmatter-completeness.sh` AGENTS array enumerates the 17 v9.0.0 agent names. PASSES on the v9.0.0 codebase.
**Verification:** Run the scenario.
**Pass condition:** `bash $R/tests/scenarios/frontmatter-completeness.sh; echo $?` = 0; AND array length = 17.
**Trace:** REQ-H-037.

### AC-H-083
**Assertion:** `tests/scenarios/read-only-agents.sh` READ_ONLY_AGENTS array contains exactly: `analyst reviewer spec-analyst architect priority-engine spec-reviewer acceptance-gate backlog-creator sprint-planner` (9 agents — no triage-analyst, no code-analyst, no stack-selector). PASSES on v9.0.0.
**Verification:** Run the scenario.
**Pass condition:** `bash $R/tests/scenarios/read-only-agents.sh; echo $?` = 0; AND array length = 9 with the exact names listed.
**Trace:** REQ-H-038.

---

## AC-H-090..099 — Documentation drift (NFR-DOC-001)

### AC-H-090
**Assertion:** `README.md` (if it states an agent count or enumeration) reflects 17 agents post-v9.0.0.
**Verification:** Inspect README.md for any `18 agents`, `18 agent`, or stack-selector mention; replace with 17.
**Pass condition:** `grep -E '\b18 (agents|agent definitions)\b' $R/README.md` returns empty AND `grep -F 'stack-selector' $R/README.md` returns empty.
**Trace:** NFR-DOC-001.

### AC-H-091
**Assertion:** `docs/reference/agents.md` enumerates the 17 v9.0.0 agents (or 17 agent count if it counts).
**Verification:** Inspect file; same predicates as AC-H-090.
**Pass condition:** `grep -E '\b18 agents\b' $R/docs/reference/agents.md` returns empty AND `grep -F 'stack-selector' $R/docs/reference/agents.md` returns empty.
**Trace:** NFR-DOC-001.

### AC-H-092
**Assertion:** `docs/architecture.md` agent count fields (where present) read 17.
**Verification:** Same predicates.
**Pass condition:** `grep -E '\b18 (agents|agent definitions)\b' $R/docs/architecture.md` returns empty AND no stack-selector mention.
**Trace:** NFR-DOC-001.

### AC-H-093
**Assertion:** Skill count remains 29 (unchanged) across CLAUDE.md, README.md, docs/reference/automation-config.md, docs/reference/skills.md, docs/architecture.md.
**Verification:** Spot grep for `29 skills` in each.
**Pass condition:** Each file either contains `29 skills` or contains no skill count assertion. No file states `28 skills` or `30 skills`.
**Trace:** NFR-DOC-001.

---

## AC-H-100..109 — Release artifacts

### AC-H-100
**Assertion:** `.claude-plugin/plugin.json` `version` field reads exactly `9.0.0`.
**Verification:** JSON parse.
**Pass condition:** `python3 -c 'import json; print(json.load(open("'$R'/.claude-plugin/plugin.json"))["version"])'` returns `9.0.0`.
**Trace:** REQ-H-040.

### AC-H-101
**Assertion:** `.claude-plugin/marketplace.json` `plugins[0].version` reads exactly `9.0.0`.
**Verification:** JSON parse.
**Pass condition:** `python3 -c 'import json; print(json.load(open("'$R'/.claude-plugin/marketplace.json"))["plugins"][0]["version"])'` returns `9.0.0`.
**Trace:** REQ-H-040.

### AC-H-102
**Assertion:** `CHANGELOG.md` has a v9.0.0 entry header `## [9.0.0] — YYYY-MM-DD` with at least one sub-section heading containing `Sub-projekt H` or `Agent I/O Contracts`.
**Verification:** Combined grep.
**Pass condition:** `grep -E '^## \[9\.0\.0\]' $R/CHANGELOG.md` exits 0 AND within that section: `grep -E 'Sub-projekt H|Agent I/O Contracts'` exits 0.
**Trace:** REQ-H-041.

### AC-H-103
**Assertion:** Git tag `v9.0.0` exists and points at the release commit.
**Verification:** `git tag -l v9.0.0`.
**Pass condition:** Output contains the literal `v9.0.0`.
**Trace:** REQ-H-040; project Version Release Process MEMORY.

---

## AC-H-110..119 — Backward-compat verification

### AC-H-110
**Assertion:** Override-injection equivalence — for every `examples/customization/*.toml` and `examples/agent-overrides/**/*.md` file, the resolved agent context (base agent + appended `## Project-Specific Instructions` block) has byte-identical `## Project-Specific Instructions` content pre/post v9.0.0; the only diff is the new `## Output Contract` section in the base agent.
**Verification:** Manual protocol per design.md §8.
**Pass condition:** `diff -u bc-fixture-v8-{agent}.txt bc-fixture-v9-{agent}.txt | grep -E '^[+-]' | grep -vE '^[+-]## Output Contract|^[+-]\| Section|^[+-]\| `## |^[+-]\|---|^[+-]### |^[+-]$'` returns empty (only Output-Contract-related diffs survive the filter).
**Trace:** REQ-H-021, NFR-COMPAT-002.

### AC-H-111
**Assertion:** All v8.0.0 test scenarios under `tests/scenarios/v8-*.sh` continue to PASS unchanged on the v9.0.0 codebase (with the 3 stale-list updates per REQ-H-036/-H-037/-H-038, which are NOT v8 scenarios — they are pre-v8 scenarios; v8-prefixed scenarios are unaffected).
**Verification:** Run the harness restricted to v8-prefixed scenarios.
**Pass condition:** `for s in $R/tests/scenarios/v8-*.sh; do bash "$s" || echo "FAIL: $s"; done` produces zero FAIL lines.
**Trace:** NFR-COMPAT-001.

---

## AC-H-120..129 — Catch-all / spec-prompt §6 backward-compat matrix

### AC-H-120
**Assertion:** Backward-compat matrix is complete — covers at minimum these 5 dimensions:
| v8.0.0 behavior | v9.0.0 behavior | BC verdict | Test |
|-----------------|-----------------|------------|------|
| `customization/{agent}.md` overlay (TOML overlay primary path) | identical: appended verbatim as `## Project-Specific Instructions` | preserved | AC-H-021 / AC-H-110 |
| `customization/{agent}.md` overlay (legacy `.md` path with `[WARN]`) | `[ERROR]` and refuse dispatch | BREAKING (pre-announced) | REQ-H-100; documented in migration-v8-to-v9.md §Migration Steps |
| Dispatch via `ceos-agents:triage-analyst|code-analyst|e2e-test-engineer|reproducer|browser-verifier` (legacy v7 names) with `[WARN]` | `[ERROR]` and refuse dispatch | BREAKING (pre-announced) | REQ-H-101 |
| Skill grep on `## Fix Report` (load-bearing string) | identical — REQ-H-006 mandates the string in fixer's Outputs table | preserved | AC-H-033 (xref scenario asserts skill still references it) |
| Agent file body parseable as 4-section `## Goal/Expertise/Process/Constraints` block | adds `## Output Contract` between Process and Constraints; structural reading still works | preserved | AC-H-002 + AC-H-021 |
| `agents/stack-selector.md` exists and is read by some skill | DELETED — scaffolder subsumes function | BREAKING (cleanup) | AC-H-040, AC-H-041, AC-H-043 |

**Verification:** Manual matrix review during Phase 8 sign-off; each row has a corresponding AC ID.
**Pass condition:** Each row in the matrix maps to ≥1 AC in this document.
**Trace:** spec-prompt §6 Backward-Compatibility Matrix requirement.

---

## Coverage map (REQ → AC)

| REQ | Mapped AC |
|-----|-----------|
| REQ-H-001 | AC-H-001 |
| REQ-H-002 | AC-H-002 |
| REQ-H-003..H-008 | AC-H-003 |
| REQ-H-009 | AC-H-003 (table-row variant) |
| REQ-H-011 | AC-H-010 |
| REQ-H-012 | AC-H-011 |
| REQ-H-013 | AC-H-012 |
| REQ-H-014 | AC-H-013 |
| REQ-H-015 | AC-H-014 |
| REQ-H-020 | AC-H-020 |
| REQ-H-021 | AC-H-021, AC-H-110 |
| REQ-H-022 | AC-H-004 |
| REQ-H-023 | AC-H-073 (collision detection in migration guide) |
| REQ-H-030 | AC-H-030 |
| REQ-H-031 | (in scenario boilerplate; verified by AC-H-031) |
| REQ-H-032..H-035 | AC-H-031, AC-H-033, AC-H-034 |
| REQ-H-036..H-038 | AC-H-080, AC-H-081, AC-H-082, AC-H-083 |
| REQ-H-039 | AC-H-031 |
| REQ-H-040 | AC-H-100, AC-H-101, AC-H-103 |
| REQ-H-041 | AC-H-102 |
| REQ-H-042 | AC-H-102, AC-H-072 |
| REQ-H-050 | AC-H-060 |
| REQ-H-051 | AC-H-061 |
| REQ-H-060 | AC-H-063, AC-H-064 |
| REQ-H-061 | AC-H-062 |
| REQ-H-070 | AC-H-070, AC-H-071 |
| REQ-H-072 | AC-H-072 |
| REQ-H-073 | AC-H-072 |
| REQ-H-074 | AC-H-073 |
| REQ-H-080 | AC-H-040, AC-H-041, AC-H-043 |
| REQ-H-081 | AC-H-034 |
| REQ-H-082 | AC-H-044 |
| REQ-H-083 | AC-H-042 |
| REQ-H-090 | AC-H-050 |
| REQ-H-091 | AC-H-051 |
| REQ-H-092 | AC-H-052 |
| REQ-H-100..H-102 | AC-H-072 (migration guide enumeration) — implementation-detail ACs deferred per REQ-H-102 |
| NFR-COMPAT-001 | AC-H-111 |
| NFR-COMPAT-002 | AC-H-021, AC-H-110 |
| NFR-DOC-001 | AC-H-090, AC-H-091, AC-H-092, AC-H-093 |
| NFR-PERF-001 | (Phase 8 timed harness run; informational, not gate) |

---

## Open questions flagged for reviewer

**OQ-A — Should `## Output Contract` per-phase H3 sub-blocks use 3-column or 4-column "When" table?** Current spec uses 3-column `Section produced | When | Required fields`. An alternate 4-column `Section produced | Phase | When | Required fields` was considered but rejected (per-phase split is already encoded in the H3 heading). Phase 5 (TDD) author should confirm the 3-column choice or escalate.

**OQ-B — Should `## Output Contract` content for the `rollback-agent` (haiku, mechanical) be as detailed as `## Output Contract` for the `analyst` (sonnet, complex)?** Design §2.11 enumerates 5 distinct outputs for rollback-agent (Rollback Report + 4 terminal sentinel literals); this is intentional documentation completeness, not over-engineering. Phase 5 may compress the 4 terminal sentinels into a single row with a `When` cell listing all 4 conditions if that proves more readable.

**OQ-C — Heading collision behavior in the override injector (REQ-H-023).** Spec accepts that an override file containing `## Output Contract` injects verbatim, producing two `## Output Contract` blocks in the resolved context. Migration guide §Compatibility Check provides a detection grep. Phase 5 should consider whether a hard scenario (`v9-customization-no-output-contract-collision.sh`) is warranted, or whether the migration-guide grep is sufficient. Spec defers to Phase 5 reviewer.
