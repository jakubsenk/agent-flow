# Phase 6 Plan — v9.0.0 sub-projekt H Implementation

**Forge run:** `forge-2026-04-28-001`
**Source authority:** `.forge/phase-4-spec/final/{requirements.md,design.md,formal-criteria.md}` + `.forge/phase-3-brainstorm/gate-decision.json`
**Test target:** all 16 visible scenarios in `.forge/phase-5-tdd/tests/` exit 0 on the v9.0.0 codebase; all 6 hidden scenarios in `.forge/phase-5-tdd/tests-hidden/` also exit 0 (Phase 7 fixers do NOT see hidden tests).

---

## Summary

Plán dekomponuje sub-projekt H do **31 atomických tasků** napříč **6 dependency tracks**. Critical path má délku **5 tasků sériově** (Foundation A1 -> Test install B0 -> Per-agent contract C-FIXER -> Cleanup D2/D5 -> Release E3). Při 4-6 paralelních fixer worker workerů činí odhad wall-clock **8-10 minut** (17 per-agent tasků v Tier C jsou všechny mutually-disjoint a tvoří ~50 % objemu práce). Tři tasky byly označeny jako Opus-level (cross-cutting reasoning): T-A04 doc-count drift sweep, T-D04 dispatch-idiom harmonization, T-E03 final harness gate. Všechno ostatní = Sonnet (mechanical edits).

**Decomposition decisions worth flagging at Gate 3:**
1. **17 per-agent tasks (T-C01..T-C17)** are kept atomic (one task per agent file) — strict additive edit between Process and Constraints, ~15-30 line diff each. Could batch into 3-4 super-tasks but that erases parallelism.
2. **Dispatch-idiom harmonization (T-D04)** is ONE task touching 6 files — spec design.md §5 lists exactly 7 prose-idiom occurrences across 6 skills. Splitting per-skill would create false serialization (no shared file). The 7-occurrence reality is per spec reviewer finding f-9b8e10 (corrected from "4" in REQ-H-090 prose).
3. **Test scenario installation (T-B00)** is one bulk-copy task instead of 16 per-test tasks — destination directory `tests/scenarios/` is shared and `cp` is idempotent.
4. **stack-selector cleanup is split into 4 tasks (T-D01..T-D03 + T-D05)** because each touches a different file — matches spec design.md §4 task list.

---

## Dependency Graph (DAG)

```
                                 ┌─────────────────────────┐
                                 │ T-A01 CLAUDE.md         │
                                 │ Versioning Policy       │
                                 ├─────────────────────────┤
                                 │ T-A02 CLAUDE.md         │
                                 │ Cross-File Invariants   │
                                 ├─────────────────────────┤
                                 │ T-A03 CLAUDE.md:35      │
                                 │ Agent enumeration 17    │
                                 ├─────────────────────────┤
                                 │ T-A04 Doc-count drift   │
                                 │ (5 doc files)           │
                                 ├─────────────────────────┤
                                 │ T-A05 migration-v8-to-v9│
                                 │ create new file         │
                                 └────────────┬────────────┘
                                              │
                ┌──────────────────┐          │
                │  T-B00 Install   │          │
                │  16 v9 scenarios │          │
                │  to tests/scen/  │          │
                └────┬─────────────┘          │
                     │                        │
       ┌─────────────┼─────────────┐          │
       │             │             │          │
   ┌───▼───────────────────────────▼──────────▼──────────────┐
   │  Tier C (parallel — 17 tasks, mutually disjoint files)  │
   │  T-C01 acceptance-gate                                  │
   │  T-C02 analyst (polymorphic — 2 phases)                 │
   │  T-C03 architect                                        │
   │  T-C04 backlog-creator                                  │
   │  T-C05 browser-agent (polymorphic — 2 phases)           │
   │  T-C06 deployment-verifier                              │
   │  T-C07 fixer                                            │
   │  T-C08 priority-engine                                  │
   │  T-C09 publisher                                        │
   │  T-C10 reviewer                                         │
   │  T-C11 rollback-agent                                   │
   │  T-C12 scaffolder                                       │
   │  T-C13 spec-analyst                                     │
   │  T-C14 spec-reviewer (polymorphic — 2 phases)           │
   │  T-C15 spec-writer                                      │
   │  T-C16 sprint-planner                                   │
   │  T-C17 test-engineer (polymorphic — 2 phases)           │
   └───────┬──────────────────────────────────────────────────┘
           │
   ┌───────▼─────────────────┐
   │  Tier D — Cleanup       │
   │  (4 parallel tasks)     │
   │  T-D01 stack-selector   │  <-- delete agents/stack-selector.md
   │       file deletion     │
   │  T-D02 scaffold SKILL   │
   │       :91 stack-sel ref │
   │  T-D03 rollback-agent   │
   │       :25 skip list     │
   │  T-D04 dispatch idiom   │
   │       harmonization     │
   │       (6 skills × 7 ln) │
   │  T-D05 stale-list       │
   │       scenario fixes    │  <-- update existing v7 21-name lists
   │       (3 existing test) │     to v9 17-name lists
   └───────┬─────────────────┘
           │
   ┌───────▼──────────────────────────┐
   │  Tier E — Release (sequential)   │
   │  T-E01 CHANGELOG.md v9.0.0 entry │
   │  T-E02 plugin.json+marketplace.json bump  │
   │  T-E03 harness regression gate (verify)   │
   │  T-E04 git tag v9.0.0                     │
   └──────────────────────────────────┘
```

Tier A items A1-A5 are independent of each other but A04 + A03 may both touch CLAUDE.md (A03 = line 35 only, A04 = different doc files). Tier B is a single bulk task. Tier C tasks are 17-way parallel. Tier D is 5-way parallel (D04 file targets are disjoint from D01-D03,D05). Tier E is strictly sequential.

---

## Tasks

### Tier A — Foundation (5 tasks, parallel)

#### T-A01: CLAUDE.md Versioning Policy amendment

- **Goal:** Append the new MAJOR-row clause and the static-declaration-section clarification paragraph to CLAUDE.md Versioning Policy section.
- **Inputs:** `C:/gitea_ceos-agents/CLAUDE.md` (current Versioning Policy table); design.md §6.1 (verbatim text).
- **Outputs:** `C:/gitea_ceos-agents/CLAUDE.md` — MAJOR row text extended with `OR introduction of a mandatory new structured contract section in agent definition files that v8.0.0 agents would fail validation against`; new examples cell mentions `mandatory \`## Output Contract\` (v9.0.0)`; new paragraph appended after the `Key rule:` line per design.md §6.1.
- **AC covered:** AC-H-060, AC-H-061
- **REQ covered:** REQ-H-050, REQ-H-051
- **Visible tests that must pass after this task:** `v9-versioning-policy-amendment.sh`
- **Depends on:** (none — foundational)
- **Parallelizable with:** T-A02, T-A03, T-A04, T-A05, T-B00, all Tier C
- **Estimated lines diff:** ~12
- **Model:** sonnet
- **Risk:** LOW — verbatim text from design.md §6.1; only file edit is in CLAUDE.md.
- **Validation:** `grep -F 'mandatory new structured contract section' CLAUDE.md` exits 0; `grep -F 'Adding new static declaration sections' CLAUDE.md` exits 0; `bash tests/scenarios/v9-versioning-policy-amendment.sh` returns 0 (after T-B00 installs the test).

#### T-A02: CLAUDE.md Cross-File Invariants amendment

- **Goal:** Add a 4th invariant to CLAUDE.md Cross-File Invariants subsection.
- **Inputs:** `C:/gitea_ceos-agents/CLAUDE.md` (current 3-invariant Cross-File Invariants section); design.md §6.2 (verbatim text).
- **Outputs:** `C:/gitea_ceos-agents/CLAUDE.md` — new invariant 4 inserted before the `See \`feedback_doc_completeness.md\`` paragraph; verbatim text per design.md §6.2; literal phrase `Agent Output Contract ↔ skill xref consistency` present; literal phrase `tests/scenarios/v9-xref-outputs-skill-references.sh` present.
- **AC covered:** AC-H-062, AC-H-063, AC-H-064
- **REQ covered:** REQ-H-060, REQ-H-061
- **Visible tests that must pass after this task:** `v9-cross-file-invariants-amendment.sh`
- **Depends on:** (none — foundational)
- **Parallelizable with:** T-A01 (different sections of CLAUDE.md but author MUST coordinate via final read+sequential apply if both running on same physical file), T-A03, T-A04, T-A05, T-B00, all Tier C
- **Estimated lines diff:** ~6
- **Model:** sonnet
- **Risk:** MEDIUM — physical file lock contention with T-A01 and T-A03 if dispatched in same worktree; recommend executing A01 → A02 → A03 serially within one worktree OR using 3 separate worktrees with merge.
- **Validation:** invariant count = 4 after edit (`awk '/^## Cross-File Invariants/{found=1; next} found && /^## /{exit} found' CLAUDE.md | grep -cE '^[0-9]+\.\s+\*\*'` returns 4); v9-cross-file-invariants-amendment.sh exits 0.

#### T-A03: CLAUDE.md agent enumeration 18 → 17

- **Goal:** Delete `stack-selector` from the Agents bullet at CLAUDE.md:35 (and any other CLAUDE.md mention).
- **Inputs:** `C:/gitea_ceos-agents/CLAUDE.md`; design.md §6.3 (verbatim before/after lines).
- **Outputs:** `C:/gitea_ceos-agents/CLAUDE.md` line ~35 — comma-separated list contains 17 names (no `stack-selector`); any other `stack-selector` reference (architecture text, model selection table) removed.
- **AC covered:** AC-H-044
- **REQ covered:** REQ-H-082
- **Visible tests that must pass after this task:** none directly (covered indirectly by `v9-section-order-with-output-contract.sh` once T-D01 also completes; AC-H-044 has no dedicated visible test).
- **Depends on:** (none — foundational)
- **Parallelizable with:** T-A01, T-A02, T-A04, T-A05, T-B00, all Tier C
- **Estimated lines diff:** ~3
- **Model:** sonnet
- **Risk:** LOW — single-line edit; possible second hit in "Model Selection" table where stack-selector might be listed.
- **Validation:** `grep -E '^\*\*Agents\*\*' CLAUDE.md | head -1 | tr ',' '\n' | wc -l` returns 17; `grep -F 'stack-selector' CLAUDE.md` returns empty.

#### T-A04: Doc-count drift sweep (5 reference files)

- **Goal:** Update agent count 18 → 17 and remove stack-selector references in README.md, docs/reference/agents.md, docs/architecture.md, docs/reference/automation-config.md, docs/reference/skills.md.
- **Inputs:** these 5 doc files; design.md §6.4 (NFR-DOC-001 list); current contents to be inspected for `18 agents`, `18 agent definitions`, `stack-selector` mentions.
- **Outputs:** each of the 5 files — agent count fields read 17 (or no count assertion); zero `stack-selector` mentions; skill count remains 29 unchanged.
- **AC covered:** AC-H-090, AC-H-091, AC-H-092, AC-H-093
- **REQ covered:** NFR-DOC-001
- **Visible tests that must pass after this task:** none directly (NFR-DOC-001 covered by ad-hoc grep in Phase 8; no v9-* scenario specifically targets the doc-count in these files — but Phase 8 final harness run is the gate).
- **Depends on:** (none — foundational)
- **Parallelizable with:** T-A01, T-A02, T-A03, T-A05, T-B00, all Tier C
- **Estimated lines diff:** ~25 (5 files × ~5 line changes each)
- **Model:** opus — cross-cutting reasoning across 5 files with variable doc structures; needs to detect every count reference and stack-selector mention without over-editing; Sonnet may miss edge mentions.
- **Risk:** MEDIUM — the most error-prone task; existing docs may have multiple count mentions in different forms (`18 agents`, `18 agent definitions`, `lists 18 agents`, table cells, etc.).
- **Validation:** for each file: `grep -E '\b18 (agents|agent definitions)\b' {file}` returns empty; `grep -F 'stack-selector' {file}` returns empty; `grep -E '\b29 skills\b' {file}` still present where it was.

#### T-A05: Create docs/guides/migration-v8-to-v9.md

- **Goal:** Create new file `docs/guides/migration-v8-to-v9.md` with verbatim content from design.md §7.
- **Inputs:** design.md §7 (full markdown body, ~80 lines).
- **Outputs:** new file `C:/gitea_ceos-agents/docs/guides/migration-v8-to-v9.md` containing the 4 required H2 section headings in order (`## Overview`, `## Breaking Changes`, `## Migration Steps`, `## Compatibility Check`); enumerates 4+ breaking changes per AC-H-072; contains the Compatibility Check bash command per AC-H-073.
- **AC covered:** AC-H-070, AC-H-071, AC-H-072, AC-H-073
- **REQ covered:** REQ-H-070, REQ-H-071, REQ-H-072, REQ-H-073, REQ-H-074
- **Visible tests that must pass after this task:** `v9-migration-guide-exists.sh`
- **Depends on:** (none — foundational; new file)
- **Parallelizable with:** T-A01, T-A02, T-A03, T-A04, T-B00, all Tier C
- **Estimated lines diff:** ~80 (new file)
- **Model:** sonnet
- **Risk:** LOW — verbatim copy from spec design.md §7; no logic; just file creation.
- **Validation:** `test -s docs/guides/migration-v8-to-v9.md`; H2 heading order matches AC-H-071 grep; `bash tests/scenarios/v9-migration-guide-exists.sh` returns 0 (after T-B00).

---

### Tier B — Test infrastructure install (1 task)

#### T-B00: Install 16 v9 lint scenarios into tests/scenarios/

- **Goal:** Copy all 16 visible test scenarios from `.forge/phase-5-tdd/tests-final/*.sh` into `tests/scenarios/`; mark executable; verify install via harness enumeration.
- **Inputs:** `.forge/phase-5-tdd/tests-final/v9-*.sh` (16 files, all executable, all using REPO_ROOT relative-pwd pattern).
- **Outputs:** `C:/gitea_ceos-agents/tests/scenarios/v9-*.sh` — 16 new files with executable bit set; harness enumeration via `tests/harness/run-tests.sh` lists them in stdout summary.
- **AC covered:** AC-H-030, AC-H-032
- **REQ covered:** REQ-H-030, REQ-H-031
- **Visible tests that must pass after this task:** all 16 v9-* scenarios become invokable (most still RED until Tier C+D complete).
- **Depends on:** (none — foundational; install is independent of Tier A edits)
- **Parallelizable with:** T-A01, T-A02, T-A03, T-A04, T-A05, all Tier C
- **Estimated lines diff:** ~0 (file moves only; no edits to scenario contents — they were authored to use $REPO_ROOT/../.. correctly for `tests/scenarios/` location).
- **Model:** sonnet (mechanical copy)
- **Risk:** LOW — verbatim file copy; no scenario edits; the .forge guard in each scenario will pass once REPO_ROOT resolves to the real plugin root (not `.forge/`).
- **Validation:** `for s in v9-output-contract-shape v9-output-contract-completeness v9-output-contract-position v9-output-contract-polymorphic-split v9-xref-outputs-skill-references v9-agents-must-be-dispatched v9-frontmatter-completeness-v9-roster v9-section-order-with-output-contract v9-read-only-agents-v9-roster v9-versioning-policy-amendment v9-cross-file-invariants-amendment v9-migration-guide-exists v9-plugin-version-bumped v9-changelog-v9-entry v9-customization-backward-compat v9-dispatch-idiom-strict; do test -x "tests/scenarios/$s.sh"; done` exits 0; `bash tests/harness/run-tests.sh 2>&1 | grep -c v9-` returns 16.

**Implementation note:** the scenarios from `tests-final/` (NOT `tests/`) are the post-review-fix versions per Phase 5 review — the `tests-final/` set incorporates the 3 minor fixes (subshell bug, em-dash comment, AC-H-030..032 README exclusion). Phase 7 fixer MUST copy from `tests-final/`, not `tests/`.

---

### Tier C — Per-agent Output Contract additions (17 tasks, parallel)

Each Tier C task: read the corresponding §2.X subsection of `.forge/phase-4-spec/final/design.md`; insert the `## Output Contract` section between `## Process` and `## Constraints` in the named agent file; for polymorphic agents, use H3 sub-blocks per design.md §1.2; backtick-quote every `## Heading` row per REQ-H-006; backtick-quote file-artifact paths per REQ-H-009 (and per spec reviewer finding f-7a31bc which clarified file-artifact rows MUST also backtick-quote the path).

#### T-C01: acceptance-gate Output Contract

- **Goal:** Add `## Output Contract` section to `agents/acceptance-gate.md` between Process and Constraints per design.md §2.1.
- **Inputs:** `agents/acceptance-gate.md` current contents; design.md §2.1 (Inputs and Outputs tables).
- **Outputs:** `agents/acceptance-gate.md` with new `## Output Contract` section (Inputs table 2 rows, Outputs table 1 row backtick-quoting `## Acceptance Gate Report`).
- **AC covered:** AC-H-001, AC-H-002, AC-H-003, AC-H-004
- **REQ covered:** REQ-H-001, REQ-H-002, REQ-H-003..H-008, REQ-H-022
- **Visible tests that must pass after this task (cumulative across all Tier C):** `v9-output-contract-completeness.sh`, `v9-output-contract-shape.sh`, `v9-output-contract-position.sh`, `v9-section-order-with-output-contract.sh`
- **Depends on:** T-B00 (so tests are runnable for fixer to verify locally)
- **Parallelizable with:** T-C02..T-C17, T-A* (all touch different files)
- **Estimated lines diff:** ~12
- **Model:** sonnet
- **Risk:** LOW — strict additive edit; spec section is verbatim.
- **Validation:** `grep -qE '^## Output Contract$' agents/acceptance-gate.md`; section sits between Process and Constraints; backtick-quoted heading row present.

#### T-C02: analyst Output Contract (polymorphic, 2 phases)

- **Goal:** Add polymorphic `## Output Contract` to `agents/analyst.md` with two H3 sub-blocks (`### Output Contract — Phase: triage`, `### Output Contract — Phase: impact`) per design.md §2.2.
- **Inputs:** `agents/analyst.md` (note: has 2 `## Process — Phase: X` headings — Output Contract goes AFTER the LAST Process heading per spec reviewer finding f-d2e44f); design.md §2.2.
- **Outputs:** `agents/analyst.md` with `## Output Contract` section, then `### Output Contract — Phase: triage` (Inputs + Outputs tables), then `### Output Contract — Phase: impact` (Inputs + Outputs tables). Position: AFTER the last `## Process — Phase: impact` block, BEFORE `## Constraints`.
- **AC covered:** AC-H-001, AC-H-002, AC-H-003, AC-H-010, AC-H-014
- **REQ covered:** REQ-H-001, REQ-H-002, REQ-H-010, REQ-H-011, REQ-H-015
- **Visible tests:** `v9-output-contract-completeness.sh`, `v9-output-contract-shape.sh`, `v9-output-contract-position.sh`, `v9-output-contract-polymorphic-split.sh`
- **Depends on:** T-B00
- **Parallelizable with:** T-C01, T-C03..T-C17, T-A*
- **Estimated lines diff:** ~36 (polymorphic = 2× single-phase volume)
- **Model:** sonnet
- **Risk:** MEDIUM — polymorphic agents must satisfy strict H3 heading literals (`### Output Contract — Phase: triage` with em-dash); positional anchor is "after LAST Process heading" not "after first" per f-d2e44f.
- **Validation:** both H3 headings grep present; section sits after both `## Process — Phase: X` blocks and before Constraints; both sub-blocks have own Inputs+Outputs tables.

#### T-C03: architect Output Contract

- **Goal:** Add `## Output Contract` to `agents/architect.md` per design.md §2.3.
- **Inputs:** `agents/architect.md`; design.md §2.3.
- **Outputs:** Outputs table includes `## Architecture Design`, `decomposition:` YAML block (file-artifact-style row, backtick-quoted), `[ceos-agents] 🔴 Pipeline Block`.
- **AC covered:** AC-H-001, AC-H-002, AC-H-003
- **REQ covered:** REQ-H-001..H-008
- **Visible tests:** v9-output-contract-completeness/shape/position
- **Depends on:** T-B00
- **Parallelizable with:** T-C01, T-C02, T-C04..T-C17, T-A*
- **Estimated lines diff:** ~16
- **Model:** sonnet
- **Risk:** LOW
- **Validation:** standard single-phase OC checks.

#### T-C04: backlog-creator Output Contract

- **Goal:** Add `## Output Contract` to `agents/backlog-creator.md` per design.md §2.4.
- **Inputs:** `agents/backlog-creator.md`; design.md §2.4.
- **Outputs:** Outputs table includes `## Backlog Summary`, `## {Epic Title}` (variable heading — note for xref: stripped to `## ` prefix and excluded per Phase 5 design), `**maps_to:** AC-N: text` field (file-artifact-style), `WARNING: Only {N} AC could be inferred...`, `[ceos-agents] 🔴 Pipeline Block`.
- **AC covered:** AC-H-001, AC-H-002, AC-H-003
- **REQ covered:** REQ-H-001..H-009
- **Visible tests:** v9-output-contract-* + v9-xref-outputs-skill-references.sh (with parameterized-heading exclusion)
- **Depends on:** T-B00
- **Parallelizable with:** all other Tier C
- **Estimated lines diff:** ~18
- **Model:** sonnet
- **Risk:** LOW — but author must remember `## {Epic Title}` is parametric; xref scenario excludes fully-variable headings via `^## \{` filter.
- **Validation:** standard OC checks; `grep -F '## Backlog Summary' skills/create-backlog/SKILL.md` exists (verifies xref direction post-task).

#### T-C05: browser-agent Output Contract (polymorphic, 2 phases)

- **Goal:** Add polymorphic `## Output Contract` with `### Output Contract — Phase: reproduce` + `### Output Contract — Phase: verify` to `agents/browser-agent.md` per design.md §2.5.
- **Inputs:** `agents/browser-agent.md` (NOTE: source uses `## Process: Phase X` syntax NOT `## Process — Phase: X` — position anchor is after LAST Process heading per f-d2e44f); design.md §2.5.
- **Outputs:** OC section has 2 H3 sub-blocks; reproduce phase Outputs row backtick-quotes `## Reproduction Result`, `\`.ceos-agents/{ISSUE-ID}/reproducer-script.js\``, `\`.ceos-agents/{ISSUE-ID}/reproduction-result.json\`` (file-artifact rows backtick-quoted per f-7a31bc); verify phase Outputs row backtick-quotes `## Browser Verification Report`, `\`.ceos-agents/{ISSUE-ID}/verification-result.json\``.
- **AC covered:** AC-H-001..H-003, AC-H-012, AC-H-014
- **REQ covered:** REQ-H-001..H-009, REQ-H-013, REQ-H-015
- **Visible tests:** v9-output-contract-completeness/shape/position/polymorphic-split
- **Depends on:** T-B00
- **Parallelizable with:** all other Tier C
- **Estimated lines diff:** ~38
- **Model:** sonnet
- **Risk:** MEDIUM — polymorphic + file-artifact row backtick-quoting (f-7a31bc) + position anchor on `## Process: Phase X` syntax variant.
- **Validation:** both H3 headings grep; file-artifact path rows backtick-quoted; v9-output-contract-polymorphic-split.sh PASS for browser-agent.

#### T-C06: deployment-verifier Output Contract

- **Goal:** Add `## Output Contract` to `agents/deployment-verifier.md` per design.md §2.6.
- **Inputs:** `agents/deployment-verifier.md`; design.md §2.6.
- **Outputs:** Outputs table includes `## Deployment Verification Report` and file-artifact `\`.ceos-agents/deploy/{timestamp}/result.json\`` (backtick-quoted per f-7a31bc).
- **AC covered:** AC-H-001..H-003
- **REQ covered:** REQ-H-001..H-009
- **Visible tests:** v9-output-contract-completeness/shape/position
- **Depends on:** T-B00
- **Parallelizable with:** all other Tier C
- **Estimated lines diff:** ~14
- **Model:** sonnet
- **Risk:** LOW
- **Validation:** standard OC checks; file-artifact row backtick-quoted.

#### T-C07: fixer Output Contract

- **Goal:** Add `## Output Contract` to `agents/fixer.md` per design.md §2.7.
- **Inputs:** `agents/fixer.md`; design.md §2.7.
- **Outputs:** Outputs table includes `## Fix Report`, `## NEEDS_DECOMPOSITION`, `## NEEDS_CLARIFICATION`, `[ceos-agents] 🔴 Pipeline Block`.
- **AC covered:** AC-H-001, AC-H-002, AC-H-003, AC-H-033 (xref via `## Fix Report` referenced in skills)
- **REQ covered:** REQ-H-001..H-008
- **Visible tests:** v9-output-contract-* + v9-xref-outputs-skill-references.sh
- **Depends on:** T-B00
- **Parallelizable with:** all other Tier C
- **Estimated lines diff:** ~18
- **Model:** sonnet
- **Risk:** LOW — `## NEEDS_*` headings are excluded from xref scenario (sentinel exclusion).
- **Validation:** standard OC checks; `## Fix Report` referenced in skills/fix-ticket/SKILL.md (xref).

#### T-C08: priority-engine Output Contract

- **Goal:** Add `## Output Contract` to `agents/priority-engine.md` per design.md §2.8.
- **Inputs:** `agents/priority-engine.md`; design.md §2.8.
- **Outputs:** Outputs row backtick-quotes `## Backlog Prioritization`, sentinel `No open issues found — backlog is empty`, `[ceos-agents] 🔴 Pipeline Block`.
- **AC covered:** AC-H-001..H-003
- **REQ covered:** REQ-H-001..H-008
- **Visible tests:** v9-output-contract-* + xref
- **Depends on:** T-B00
- **Parallelizable with:** all other Tier C
- **Estimated lines diff:** ~14
- **Model:** sonnet
- **Risk:** LOW
- **Validation:** standard.

#### T-C09: publisher Output Contract

- **Goal:** Add `## Output Contract` to `agents/publisher.md` per design.md §2.9.
- **Inputs:** `agents/publisher.md`; design.md §2.9.
- **Outputs:** Outputs row backtick-quotes `## Publish Report`; mode-dependent Tracker row variants enumerated; Block row.
- **AC covered:** AC-H-001..H-003
- **REQ covered:** REQ-H-001..H-008
- **Visible tests:** v9-output-contract-* + xref
- **Depends on:** T-B00
- **Parallelizable with:** all other Tier C
- **Estimated lines diff:** ~16
- **Model:** sonnet
- **Risk:** LOW
- **Validation:** standard; `## Publish Report` referenced in skills/publish/SKILL.md.

#### T-C10: reviewer Output Contract

- **Goal:** Add `## Output Contract` to `agents/reviewer.md` per design.md §2.10.
- **Inputs:** `agents/reviewer.md`; design.md §2.10.
- **Outputs:** Outputs row backtick-quotes `## Code Review` and Block row.
- **AC covered:** AC-H-001..H-003
- **REQ covered:** REQ-H-001..H-008
- **Visible tests:** v9-output-contract-* + xref (`## Code Review` literal in skills/fix-ticket/SKILL.md)
- **Depends on:** T-B00
- **Parallelizable with:** all other Tier C
- **Estimated lines diff:** ~16
- **Model:** sonnet
- **Risk:** LOW
- **Validation:** standard.

#### T-C11: rollback-agent Output Contract

- **Goal:** Add `## Output Contract` to `agents/rollback-agent.md` per design.md §2.11. NOTE: this task adds the OC section ONLY — the separate edit to remove `stack-selector` from the skip list is task T-D03.
- **Inputs:** `agents/rollback-agent.md`; design.md §2.11; spec reviewer OQ-B (consider compressing 4 terminal-sentinel rows into 1 row with multi-condition `When` cell — Phase 5 reviewer accepted either).
- **Outputs:** Outputs table includes `## Rollback Report` + 4 terminal sentinels (read-only block, publisher block, scaffolder block, terminal pass) + `[ceos-agents] 🔴 Pipeline Block`. Recommend using 5 separate rows for clarity (matches spec design.md §2.11).
- **AC covered:** AC-H-001..H-003
- **REQ covered:** REQ-H-001..H-008
- **Visible tests:** v9-output-contract-* + xref (`## Rollback Report` literal in skills/fix-bugs or skills/fix-ticket SKILL.md — verify post-task)
- **Depends on:** T-B00
- **Parallelizable with:** all other Tier C; CONFLICTS with T-D03 (same file) — Phase 7 must serialize T-C11 → T-D03 OR merge them in one worktree.
- **Estimated lines diff:** ~24
- **Model:** sonnet
- **Risk:** MEDIUM — 5-row Outputs table is the largest mechanical edit; possible file conflict with T-D03 if dispatched separately.
- **Validation:** standard OC checks.

#### T-C12: scaffolder Output Contract

- **Goal:** Add `## Output Contract` to `agents/scaffolder.md` per design.md §2.12.
- **Inputs:** `agents/scaffolder.md`; design.md §2.12.
- **Outputs:** Outputs row backtick-quotes `## Scaffold Report` and `## Quality Scorecard` (note: nested heading — appears within Scaffold Report body but is its own backtick-quoted entry).
- **AC covered:** AC-H-001..H-003
- **REQ covered:** REQ-H-001..H-008
- **Visible tests:** v9-output-contract-* + xref
- **Depends on:** T-B00
- **Parallelizable with:** all other Tier C
- **Estimated lines diff:** ~14
- **Model:** sonnet
- **Risk:** LOW
- **Validation:** standard; both `## Scaffold Report` and `## Quality Scorecard` referenced in skills/scaffold/SKILL.md (verify xref).

#### T-C13: spec-analyst Output Contract

- **Goal:** Add `## Output Contract` to `agents/spec-analyst.md` per design.md §2.13.
- **Inputs:** `agents/spec-analyst.md`; design.md §2.13.
- **Outputs:** Outputs row backtick-quotes `## Feature Specification`, `Quality gate:` sentinels, `[ceos-agents] Spec analysis completed.` checkpoint, `[ceos-agents] Acceptance Criteria:` separate comment, Block row.
- **AC covered:** AC-H-001..H-003
- **REQ covered:** REQ-H-001..H-008
- **Visible tests:** v9-output-contract-* + xref
- **Depends on:** T-B00
- **Parallelizable with:** all other Tier C
- **Estimated lines diff:** ~16
- **Model:** sonnet
- **Risk:** LOW
- **Validation:** standard.

#### T-C14: spec-reviewer Output Contract (polymorphic, 2 phases)

- **Goal:** Add polymorphic `## Output Contract` to `agents/spec-reviewer.md` with `### Output Contract — Default (review mode)` + `### Output Contract — Phase: --verify` per design.md §2.14.
- **Inputs:** `agents/spec-reviewer.md`; design.md §2.14.
- **Outputs:** Default sub-block: Outputs row `## Spec Review`. Verify sub-block: Outputs row `## Spec Compliance Report`.
- **AC covered:** AC-H-001..H-003, AC-H-013, AC-H-014
- **REQ covered:** REQ-H-001..H-008, REQ-H-014, REQ-H-015
- **Visible tests:** v9-output-contract-* + polymorphic-split + xref
- **Depends on:** T-B00
- **Parallelizable with:** all other Tier C
- **Estimated lines diff:** ~28
- **Model:** sonnet
- **Risk:** MEDIUM — polymorphic; H3 heading for default phase is `### Output Contract — Default (review mode)` (parens in literal, must match grep exactly).
- **Validation:** both H3 headings grep present; v9-output-contract-polymorphic-split.sh PASS for spec-reviewer.

#### T-C15: spec-writer Output Contract

- **Goal:** Add `## Output Contract` to `agents/spec-writer.md` per design.md §2.15.
- **Inputs:** `agents/spec-writer.md`; design.md §2.15.
- **Outputs:** Outputs table includes `## Spec Writer Report` plus file-artifact rows backtick-quoting `\`spec/README.md\``, `\`spec/architecture.md\``, `\`spec/verification.md\``, `\`spec/epics/NN-name.md\`` (per f-7a31bc — file-artifact rows MUST be backtick-quoted), Block row.
- **AC covered:** AC-H-001..H-003, AC-H-009 (file artifacts)
- **REQ covered:** REQ-H-001..H-009
- **Visible tests:** v9-output-contract-* + xref (NB: file-path rows are not heading rows — xref scenario only checks `## Heading` rows, so file-path rows are not asserted in skills)
- **Depends on:** T-B00
- **Parallelizable with:** all other Tier C
- **Estimated lines diff:** ~22
- **Model:** sonnet
- **Risk:** MEDIUM — multiple file-artifact rows; must remember backtick-quoting per f-7a31bc.
- **Validation:** standard OC checks; file-artifact paths backtick-quoted.

#### T-C16: sprint-planner Output Contract

- **Goal:** Add `## Output Contract` to `agents/sprint-planner.md` per design.md §2.16.
- **Inputs:** `agents/sprint-planner.md`; design.md §2.16.
- **Outputs:** Outputs row backtick-quotes `## Sprint Plan: {sprint_name}` (PARAMETRIC — xref scenario strips `{...}` and matches prefix per Phase 5 implementation), plus H3 sub-tables `### Selected Issues`, `### Overflow`, `### Dependency Warnings`, `### Cold Start Warnings`, `### Release Summary`, Block row.
- **AC covered:** AC-H-001..H-003
- **REQ covered:** REQ-H-001..H-009
- **Visible tests:** v9-output-contract-* + xref
- **Depends on:** T-B00
- **Parallelizable with:** all other Tier C
- **Estimated lines diff:** ~22
- **Model:** sonnet
- **Risk:** LOW — parameterized heading is handled by xref scenario.
- **Validation:** standard.

#### T-C17: test-engineer Output Contract (polymorphic, 2 phases)

- **Goal:** Add polymorphic `## Output Contract` to `agents/test-engineer.md` with `### Output Contract — Default (no flag)` + `### Output Contract — Phase: --e2e` per design.md §2.18.
- **Inputs:** `agents/test-engineer.md`; design.md §2.18.
- **Outputs:** Default sub-block: Outputs row `## Test Report` + Block row. --e2e sub-block: Outputs row `## Test Report` + Block row (note: same heading in both phases per design.md — the `When` cell distinguishes).
- **AC covered:** AC-H-001..H-003, AC-H-011, AC-H-014
- **REQ covered:** REQ-H-001..H-008, REQ-H-012, REQ-H-015
- **Visible tests:** v9-output-contract-* + polymorphic-split + xref
- **Depends on:** T-B00
- **Parallelizable with:** all other Tier C
- **Estimated lines diff:** ~28
- **Model:** sonnet
- **Risk:** MEDIUM — polymorphic; H3 default heading literal is `### Output Contract — Default (no flag)` (parens + lowercase "no flag" per AC-H-011).
- **Validation:** both H3 headings grep present; v9-output-contract-polymorphic-split.sh PASS for test-engineer.

---

### Tier D — Cleanup (5 tasks, parallel)

#### T-D01: Delete agents/stack-selector.md

- **Goal:** Delete `agents/stack-selector.md` from the repository.
- **Inputs:** none — destructive action.
- **Outputs:** `agents/stack-selector.md` does not exist on the v9.0.0 commit.
- **AC covered:** AC-H-040
- **REQ covered:** REQ-H-080
- **Visible tests:** `v9-agents-must-be-dispatched.sh` (no longer fails on stack-selector orphan); hidden `v9-stack-selector-deleted.sh`; `v9-output-contract-completeness.sh` (file no longer exists, so loop counts 17 not 18).
- **Depends on:** T-B00 (so test can verify); does NOT depend on T-C* (orthogonal — file is deleted not edited)
- **Parallelizable with:** T-A*, T-B00, all Tier C, T-D02, T-D03, T-D04, T-D05
- **Estimated lines diff:** -54 (deletion of 1 file)
- **Model:** haiku — purely mechanical file deletion
- **Risk:** LOW — file has zero `subagent_type='ceos-agents:stack-selector'` references in skills (verified during Phase 4). Cleanup-side references handled by T-D02, T-D03, T-A03.
- **Validation:** `test ! -f agents/stack-selector.md`; v9-agents-must-be-dispatched.sh PASS.

#### T-D02: Edit skills/scaffold/SKILL.md:91 to remove stack-selector reference

- **Goal:** Rewrite the legacy-flow text at `skills/scaffold/SKILL.md:91` to describe scaffolder-direct invocation (without stack-selector intermediate).
- **Inputs:** `skills/scaffold/SKILL.md`; design.md §4 ("rewrite line 91 to reference scaffolder-direct invocation in `--no-implement` mode").
- **Outputs:** `skills/scaffold/SKILL.md` — line 91 (and any neighboring lines that reference `stack-selector → scaffolder`) rewritten to `scaffolder (with stack flags) → validate → ...`; zero `stack-selector` mentions remaining.
- **AC covered:** AC-H-041, AC-H-043
- **REQ covered:** REQ-H-080
- **Visible tests:** `v9-agents-must-be-dispatched.sh`; hidden `v9-stack-selector-deleted.sh`
- **Depends on:** (none — file edit; can run before or after T-D01)
- **Parallelizable with:** all other tasks except T-D04 (different file from T-D04 in skills/scaffold/SKILL.md — verify D04 doesn't also edit scaffold/SKILL.md)
- **Estimated lines diff:** ~5
- **Model:** sonnet
- **Risk:** LOW
- **Validation:** `grep -cE 'stack-selector' skills/scaffold/SKILL.md` returns 0.

#### T-D03: Edit agents/rollback-agent.md:25 — remove stack-selector from skip list

- **Goal:** Remove `stack-selector` from the read-only-blocking-agent skip list in `agents/rollback-agent.md` (Process step 1 / Constraints area).
- **Inputs:** `agents/rollback-agent.md`; design.md §4.
- **Outputs:** `agents/rollback-agent.md` — `stack-selector` removed from the list at line 25 (or wherever the skip list now lives); list still skips read-only agents (`analyst`, `spec-analyst`, `architect`).
- **AC covered:** AC-H-042
- **REQ covered:** REQ-H-083
- **Visible tests:** none directly; hidden `v9-stack-selector-deleted.sh` checks this file too
- **Depends on:** T-C11 (same file; Phase 7 should run T-C11 first then T-D03 in same worktree, OR merge them in one task)
- **Parallelizable with:** T-A*, T-B00, T-C* except T-C11, T-D01, T-D02, T-D04, T-D05
- **Estimated lines diff:** ~1
- **Model:** sonnet
- **Risk:** LOW — single-line edit. Note: serialize with T-C11 (same file).
- **Validation:** `grep -cE 'stack-selector' agents/rollback-agent.md` returns 0.

**Implementation note:** to avoid merge conflict, recommend Phase 7 dispatcher fold T-C11 + T-D03 into a single combined task (T-C11+D03) executed in the same worktree.

#### T-D04: Dispatch idiom harmonization (6 skill files, 7 occurrences)

- **Goal:** Rewrite all prose-idiom dispatch lines (`Run ceos-agents:X (Task tool, model: Y)` and the `Dispatch ceos-agents:...` variant) to the strict idiom `Task(subagent_type='ceos-agents:X', model='Y')` across 6 skill files.
- **Inputs:** these 6 files: `skills/check-deploy/SKILL.md`, `skills/create-backlog/SKILL.md`, `skills/sprint-plan/SKILL.md`, `skills/prioritize/SKILL.md`, `skills/scaffold-add/SKILL.md`, `skills/publish/SKILL.md`. Spec design.md §5 grep target table; spec reviewer finding f-9b8e10 corrects "4" to "7 across 6 files" (1 Dispatch variant + 6 Run variants); also Phase 5 review DA-3 confirms 9 total prose-idiom instances when including the secondary `Run the X agent (Task tool, ...)` pattern.
- **Outputs:** all 6 files — every prose-idiom dispatch rewritten to strict form with matching `model='{tier}'` from agent frontmatter; agents themselves untouched (REQ-H-092).
- **AC covered:** AC-H-050, AC-H-051, AC-H-052
- **REQ covered:** REQ-H-090, REQ-H-091, REQ-H-092
- **Visible tests:** `v9-dispatch-idiom-strict.sh`
- **Depends on:** T-B00 (so test is runnable)
- **Parallelizable with:** all Tier A, T-B00, all Tier C (different files), T-D01, T-D02 (T-D02 also touches skills/scaffold/SKILL.md but different lines — verify NO overlap; if overlap, serialize), T-D03, T-D05
- **Estimated lines diff:** ~25 (7-9 line rewrites + comment touches)
- **Model:** opus — cross-file consistency reasoning; must verify each `model='{tier}'` matches the corresponding `agents/{name}.md` frontmatter `model:` field; sonnet may miss the 2 secondary `Run the X agent` instances flagged by Phase 5 review DA-3.
- **Risk:** HIGH — touches the most files (6); coordination with T-D02 (also edits skills/scaffold/SKILL.md though `scaffold-add` is a separate skill; double-check); model-tier mapping per agent must be exact.
- **Validation:** `grep -rE '(Run|Dispatch) \`?ceos-agents:[a-z-]+\`?\s*\(Task tool' skills/` returns empty; `grep -rE 'Run the [a-z-]+ agent \(Task tool' skills/` returns empty; v9-dispatch-idiom-strict.sh PASS.

#### T-D05: Update 3 stale-list scenarios (frontmatter, section-order, read-only-agents)

- **Goal:** The 3 existing pre-v9 test scenarios that hardcode v7 21-name AGENTS arrays must be updated to the v9 17-name arrays. NOTE: per Phase 5 TDD design, these 3 scenarios are REPLACED by new v9-prefixed equivalents (`v9-frontmatter-completeness-v9-roster.sh`, `v9-section-order-with-output-contract.sh`, `v9-read-only-agents-v9-roster.sh`) that T-B00 installs. The existing v7 scenarios must be DELETED so the harness doesn't run both stale and fresh versions.
- **Inputs:** `tests/scenarios/frontmatter-completeness.sh` (existing v7), `tests/scenarios/section-order.sh` (existing v7), `tests/scenarios/read-only-agents.sh` (existing v7).
- **Outputs:** these 3 files DELETED (replaced by v9-roster equivalents installed by T-B00). Phase 5 design.md §3.7 is the spec authority — note that its prose says "update" but the v9 scenarios are distinct files (`v9-frontmatter-completeness-v9-roster.sh` etc.), so the original scenarios are obsolete and must be removed to avoid duplicate / stale assertions.
- **AC covered:** AC-H-080, AC-H-081, AC-H-082, AC-H-083
- **REQ covered:** REQ-H-036, REQ-H-037, REQ-H-038
- **Visible tests:** `v9-frontmatter-completeness-v9-roster.sh`, `v9-section-order-with-output-contract.sh`, `v9-read-only-agents-v9-roster.sh` — all PASS once stale v7 scenarios are deleted (so harness counts only v9 versions).
- **Depends on:** T-B00 (must install v9 replacements first), T-D01 (stack-selector must be deleted so 17-name array works)
- **Parallelizable with:** T-A*, T-C* (different files), T-D01-D04
- **Estimated lines diff:** -150 (3 file deletions of ~50 lines each)
- **Model:** sonnet
- **Risk:** MEDIUM — must confirm Phase 5 intent (delete vs in-place update) with Phase 6 user gate; spec design.md §3.7 prose suggests update-in-place but Phase 5 author shipped distinct v9 files. Recommend deletion (cleaner; matches the v9-prefix naming convention).
- **Validation:** stale scenarios deleted; v9 roster scenarios PASS; harness runs all v9-roster scenarios in summary.

**Open question for Gate 3:** Confirm whether T-D05 should DELETE the 3 stale scenarios or UPDATE them in-place. Phase 5 author shipped distinct `v9-*-v9-roster.sh` files which suggests deletion; spec design.md §3.7 wording suggests update-in-place. Recommend DELETE to avoid double-execution + stale-array-drift.

---

### Tier E — Release (4 tasks, sequential)

#### T-E01: CHANGELOG.md v9.0.0 entry

- **Goal:** Add v9.0.0 entry to `CHANGELOG.md` per REQ-H-041 + REQ-H-042.
- **Inputs:** `CHANGELOG.md` current contents; design.md §6 + §7 (release scope summary); REQ-H-041 / REQ-H-042 (sub-section list).
- **Outputs:** `CHANGELOG.md` — new section `## [9.0.0] — 2026-MM-DD` with sub-sections including `### Sub-projekt H: Agent I/O Contracts` enumerating: `## Output Contract` mandatory across 17 agents (after stack-selector deletion); 6 new lint scenarios; CLAUDE.md Versioning Policy + Cross-File Invariants amendments; migration-v8-to-v9.md added; AND `### Pre-announced breaking changes` enumerating `.md` overlay hard removal + deprecated agent name hard errors per REQ-H-042.
- **AC covered:** AC-H-072 (enumeration); AC-H-102 (entry exists)
- **REQ covered:** REQ-H-041, REQ-H-042
- **Visible tests:** `v9-changelog-v9-entry.sh`
- **Depends on:** all Tier A, B, C, D complete
- **Parallelizable with:** (none — sequential after Tier D)
- **Estimated lines diff:** ~30
- **Model:** sonnet
- **Risk:** LOW — content is fully specified; date is build-time.
- **Validation:** `grep -E '^## \[9\.0\.0\]' CHANGELOG.md` exits 0; sub-section grep for `Sub-projekt H` exits 0; v9-changelog-v9-entry.sh PASS.

**MEMORY discipline:** Per project Version Release Process MEMORY: "ALWAYS create changelog entry without being asked"; commit ordering "(1) content, (2) changelog same commit, (3) version-bump separate, (4) tag" — this means T-E01 MUST be in the same commit as Tier C/D content edits (not in a separate commit). Phase 7 implementer should fold T-E01 into the final content commit.

#### T-E02: plugin.json + marketplace.json version bump 8.0.0 → 9.0.0

- **Goal:** Update `version` field in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` to `9.0.0`.
- **Inputs:** these 2 JSON files; REQ-H-040.
- **Outputs:** both files have `"version": "9.0.0"` exactly; JSON parse-valid.
- **AC covered:** AC-H-100, AC-H-101
- **REQ covered:** REQ-H-040
- **Visible tests:** `v9-plugin-version-bumped.sh`
- **Depends on:** T-E01 (per MEMORY commit-ordering: changelog same commit as content; version bump separate commit)
- **Parallelizable with:** (none — sequential)
- **Estimated lines diff:** 2
- **Model:** haiku — mechanical JSON field edit
- **Risk:** LOW
- **Validation:** v9-plugin-version-bumped.sh PASS.

**MEMORY discipline:** Per `feedback_version_bump_skill.md`: use `/ceos-agents:version-bump 9.0.0` skill — never manual bump+tag. Phase 7 implementer should invoke the skill, which performs T-E02 + T-E04 atomically.

#### T-E03: Full harness regression gate

- **Goal:** Run `./tests/harness/run-tests.sh` and confirm all v9 scenarios PASS, all v8 scenarios PASS, no regressions.
- **Inputs:** `tests/harness/run-tests.sh`; current state of repo after T-E02.
- **Outputs:** harness exit code 0; all 16 v9-* scenarios PASS; all v8-* scenarios PASS; no other scenario FAILs.
- **AC covered:** AC-H-031, AC-H-032, AC-H-111
- **REQ covered:** REQ-H-039, NFR-COMPAT-001
- **Visible tests:** all 16 + all v8 + all generic scenarios
- **Depends on:** T-E01, T-E02
- **Parallelizable with:** (none)
- **Estimated lines diff:** 0 (read-only verification)
- **Model:** opus — diagnostic reasoning if anything fails; needs to map FAIL output back to which Tier C/D task is incomplete
- **Risk:** HIGH — final gate; if any scenario FAILs, must triage and dispatch fixer back to specific Tier C/D task.
- **Validation:** `bash tests/harness/run-tests.sh; echo $?` returns 0; no `FAIL:` lines in stdout for any v9-* or v8-* scenario.

#### T-E04: Git tag v9.0.0

- **Goal:** Create annotated git tag `v9.0.0` on the release commit.
- **Inputs:** release commit SHA; CHANGELOG.md v9.0.0 entry text for tag annotation.
- **Outputs:** git tag `v9.0.0` exists on the release commit and is pushed to origin.
- **AC covered:** AC-H-103
- **REQ covered:** REQ-H-040 (release artifacts); project Version Release Process MEMORY
- **Visible tests:** none directly (git state); hidden tag-existence check in Phase 8.
- **Depends on:** T-E03 (harness must be green before tagging)
- **Parallelizable with:** (none — final step)
- **Estimated lines diff:** 0
- **Model:** haiku — mechanical git tag command
- **Risk:** LOW
- **Validation:** `git tag -l v9.0.0` returns `v9.0.0`.

**MEMORY note:** the user runs `/ceos-agents:version-bump 9.0.0` per `feedback_version_bump_skill.md` — that skill performs T-E02 + commit + T-E04 in one sequence. Phase 7 implementer should NOT manually create the tag; defer to user invoking version-bump skill at Gate 3 / Phase 8 sign-off.

---

## Parallel Execution Tracks

| Track | Tasks | Workers | Wall-clock estimate |
|-------|-------|---------|---------------------|
| **Foundation** | T-A01, T-A02, T-A03, T-A04, T-A05 | 4-5 | 1.5-2 min (T-A04 is the long pole at opus, ~2 min) |
| **Test install** | T-B00 | 1 | 0.5 min |
| **Per-agent (Tier C)** | T-C01..T-C17 | 4-6 | 4-5 min (~17 tasks, batched 3-4 per worker; polymorphic agents 1.5× duration) |
| **Cleanup** | T-D01, T-D02, T-D03, T-D04, T-D05 | 4 | 2 min (T-D04 is the long pole at opus + 6 files) |
| **Release** | T-E01, T-E02, T-E03, T-E04 | 1 (sequential) | 1.5-2 min (T-E03 is the long pole — full harness run) |
| **TOTAL** | 31 tasks | 6 max workers | **~9-10 min** |

**Track parallelism opportunities:**
- Tier A + Tier B + Tier C can ALL run concurrently (they touch different file sets — Tier A = CLAUDE.md + docs, Tier B = tests/scenarios/, Tier C = agents/).
- Tier D D01-D04 can run alongside Tier C — different files. ONLY T-D03 conflicts with T-C11 (rollback-agent.md), and T-D02 may conflict with T-D04 if D04 also touches skills/scaffold/SKILL.md (it doesn't — D04 targets scaffold-add, not scaffold).
- T-D05 must wait for T-B00 + T-D01.
- Tier E is strictly sequential and cannot parallelize.

**Recommended worker allocation for 6-worker pool:**
- Workers 1-2: Tier C polymorphic agents (T-C02, T-C05, T-C14, T-C17 — slowest)
- Workers 3-5: Tier C single-phase agents (13 tasks split 4-5 each)
- Worker 6: Tier A + Tier B + Tier D in sequence (foundation + test install + cleanup)
- Phase 7 dispatcher rejoins for sequential Tier E.

---

## Critical Path

The longest dependency chain:

1. **T-B00** (test install) — 0.5 min — must complete before Tier C/D can validate locally
2. **T-C02 or T-C05 or T-C14 or T-C17** (slowest polymorphic agent edit) — ~1.5 min
3. **T-D01 + T-D05** (stack-selector deletion + stale-list cleanup) — 1 min serial
4. **T-E01 + T-E02 + T-E03** (changelog + version bump + harness) — 2.5 min serial
5. **T-E04** (tag) — 0.1 min

**Critical path floor:** ~5.6 min ≈ **6 minutes wall-clock** if all parallelism is exploited.
**Realistic estimate:** **8-10 minutes** accounting for forge worker spin-up, contention on git index for sequential edits to CLAUDE.md (T-A01 + T-A02 + T-A03 same file), and harness diagnosis time if T-E03 surfaces a regression.

---

## Open questions for Gate 3

1. **Stale-list scenarios — DELETE or UPDATE in-place?** Phase 5 author shipped 3 distinct `v9-*-v9-roster.sh` files (`v9-frontmatter-completeness-v9-roster.sh`, `v9-section-order-with-output-contract.sh`, `v9-read-only-agents-v9-roster.sh`) implying the original v7 scenarios should be DELETED. But spec design.md §3.7 prose says "update the AGENTS array". T-D05 currently plans deletion. **User confirm:** is DELETE the right call, or should T-D05 also keep the originals updated to 17-name arrays so v8 grep continuity is preserved?
2. **T-C11 + T-D03 same file (`agents/rollback-agent.md`) — fold into one task?** Two separate tasks edit the same file. Phase 7 dispatcher will need to either serialize them in one worktree or merge them into a single combined task (T-C11+D03). Plan currently keeps them separate but flags the conflict. **User confirm:** fold or serialize?
3. **REQ-H-100 / REQ-H-101 hard-error implementation — in-scope or out-of-scope for Phase 7?** Spec REQ-H-102 says implementation detail is "OUT OF SCOPE" but the v9.0.0 release vehicle bundles them per gate-decision. The plan has NO task for implementing these hard-errors — only T-E01 mentions them in CHANGELOG. The hidden test `v9-deprecated-agent-name-hard-error.sh` will FAIL on the v9.0.0 codebase if no skill/core change actually flips [WARN] → [ERROR] for deprecated agent names. **User confirm:** does the v9.0.0 release plan need an additional task (e.g., T-D06) to flip [WARN] → [ERROR] in core/agent-override-injector.md and skills/fix-bugs/SKILL.md, or is this owned by another spec doc?
