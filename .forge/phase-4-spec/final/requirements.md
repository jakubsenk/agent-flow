# v10.2.0 — `core/` Path Disambiguation — Requirements (EARS)

**Forge run:** `forge-2026-05-13-001`
**Target version:** v10.1.2 → v10.2.0 (MINOR)
**Direction lock (Gate 1 approved):** HYBRID — B2 depth-aware mechanical rewrite (PRIMARY) + Phase A fail-loud guard + B3 documentary clarifier in 3 `data/guard-block.md` files + Phase C with TWO scenarios (runtime external-CWD + static depth-lint).

**Evidence-base citations used:**
- `phase-2`: `.forge/phase-2-research-answers/final.md`
- `phase-3`: `.forge/phase-3-brainstorming/final.md`
- `roadmap`: `docs/plans/roadmap.md`
- `claude-md`: `CLAUDE.md`

---

## REQ-A — Fail-Loud Guard (Phase A)

### REQ-A-1 — Probe target locked

WHEN any of `/ceos-agents:fix-bugs`, `/ceos-agents:implement-feature`, or `/ceos-agents:scaffold` is invoked, the orchestrator SHALL execute a pre-flight readability probe against the canonical sentinel file `core/mcp-preflight.md` BEFORE any Task() dispatch and BEFORE writing `state.json`.

- **Provenance:** `phase-2` §C2 (47-line file, referenced by 6 SKILL.md, 0 agent files — highest stable-removal-cost target).
- **FC:** FC-A-1.

### REQ-A-2 — Probe shape and resolution rules

The probe SHALL evaluate `[ -r "<RESOLVED_CORE>/mcp-preflight.md" ]` where `<RESOLVED_CORE>` is computed as the depth-correct relative path from the **guard-block.md file's own directory** (i.e. `../../../core` for `skills/{name}/data/guard-block.md`, which sits at depth-3 from repo root). The probe path resolves relative to the guard-block.md file's directory because guard-block.md is included by SKILL.md via a Read directive whose relative paths are evaluated relative to the including file's location, not to Claude's CWD.

- **Provenance:** `phase-3` §Recommendation item 1 (probe semantics); per Quality reviewer finding f-d1a2b3 (depth-correctness) and Devil's Advocate finding f-da0004 (resolution wording).
- **FC:** FC-A-1, FC-A-2, FC-A-6.

### REQ-A-3 — Canonical failure message

WHEN REQ-A-2's probe fails (file not readable), the orchestrator SHALL print to stderr the EXACT string:

```
ABORT: plugin-root not resolved -- core/ sibling of skills/ not found at <attempted-path>. Check plugin install integrity.
```

…where `<attempted-path>` is the literal resolved path that failed the `-r` test. The orchestrator SHALL then `exit 2` (NOT 1, NOT 0 — distinguishes guard-abort from generic test failure).

- **Provenance:** `phase-0-meta/prompts/spec.md` REQ-A bullet; `phase-3` §Recommendation item 1.
- **FC:** FC-A-1, FC-A-3.

### REQ-A-4 — Affected files (exhaustive)

The Phase A guard SHALL be installed in exactly three files:

1. `skills/fix-bugs/data/guard-block.md` (existing, 73 lines)
2. `skills/implement-feature/data/guard-block.md` (existing, 70 lines)
3. `skills/scaffold/data/guard-block.md` (NEW — file + parent `data/` directory created from scratch)

Insertion: prepend a new `<PREFLIGHT>` XML block immediately BEFORE the existing `<MANDATORY-EXECUTION-GUARD>` block. NO existing line in either pre-existing guard-block.md is removed or re-ordered.

- **Provenance:** `phase-2` §C2 (scaffold/data/ does NOT exist), §I3 (no existing path-resolution logic in either file).
- **FC:** FC-A-1, FC-A-2 (3 files asserted).

### REQ-A-5 — `scaffold` SKILL.md Read-tool directive

The `skills/scaffold/SKILL.md` file SHALL contain a Read-tool directive at line 11 (mirroring `skills/fix-bugs/SKILL.md:11` and `skills/implement-feature/SKILL.md:11`) instructing the orchestrator to load `skills/scaffold/data/guard-block.md` BEFORE any other instruction in the file.

- **Provenance:** `phase-2` §C2 third action ("Add a Read tool directive to skills/scaffold/SKILL.md").
- **FC:** FC-A-4.

### REQ-A-6 — B3 documentary clarifier (additive, scoped)

Each `<PREFLIGHT>` block SHALL contain a one-line clarifier prose stating: "All `core/<file>.md` references in this skill use relative paths from the file's directory (`../core/`, `../../core/`, or `../../../core/` depending on depth). The canonical layout is `core/` as sibling of `skills/` at plugin root." This clarifier appears ONLY in the 3 guard-block.md files; it is NOT inserted into the 185 occurrences themselves.

- **Provenance:** `phase-3` §Recommendation item 3 ("B3 prose clarifier (ADDITIVE, ~3-9 lines, ONLY in guard-block.md)"); Probe 3 verdict ("B3 belongs in a hybrid as a low-cost additive ON TOP of B2, NOT as a substitute").
- **FC:** FC-A-5.

---

## REQ-B — Path Rewrite (Phase B)

### REQ-B-1 — Direction lock (B2 depth-aware mechanical rewrite, B1 rejected, B3 additive only)

Phase B SHALL implement option **B2 (depth-aware mechanical rewrite)** as the PRIMARY path format. Each `core/<file>.md` reference SHALL be rewritten to a depth-correct relative path. Option B1 (`${PLUGIN_ROOT}/core/...`) is REJECTED. Option B3 (inline prose clarifier) is NOT applied to the 185 occurrences; B3 prose appears ONLY in the 3 `<PREFLIGHT>` blocks per REQ-A-6.

- **Provenance:** `phase-3` §Synthesis Recommendation (HYBRID, confidence 0.84); `phase-2` §I1 (B1 NOT-VIABLE-without-helper; Read tool does not shell-expand `${PLUGIN_ROOT}`); `phase-3` Probe 2 verdict (helper-shim violates CLAUDE.md L17 markdown-only invariant).
- **FC:** FC-B-1, FC-B-2, FC-B-3, FC-B-4, FC-B-5.

### REQ-B-2 — Depth classes and required relative prefixes

The mechanical rewrite SHALL apply per-depth-class prefixes:

| Depth class | Files matched by glob | Required prefix | Up-levels |
|---|---|---|---|
| Depth 1 (`agents/`) | `agents/*.md` | `../core/` | 1 |
| Depth 2 (skill root) | `skills/*/SKILL.md` | `../../core/` | 2 |
| Depth 3 (skill steps) | `skills/*/steps/*.md` | `../../../core/` | 3 |
| Depth 3 (skill data) | `skills/*/data/*.md` | `../../../core/` | 3 |

A single uniform sed across all files is FORBIDDEN. Phase 7 implementation SHALL use four (4) discrete sed invocations or an explicit file-class manifest. Each invocation SHALL use 2-backslash escape conventions in extended-regex (`-E`) mode. 4-backslash escapes are FORBIDDEN (lesson from v10.1.0 over-escape bug, per `feedback_negation_logic_when_wrapping_checks.md`).

- **Provenance:** `phase-2` §"B2 Depth-Split Mandate"; `phase-3` §Recommendation item 2; `claude-md` MEMORY.md v10.1.0 4-backslash lesson.
- **FC:** FC-B-2 (depth 1), FC-B-3 (depth 2), FC-B-4 (depth 3 steps), FC-B-5 (depth 3 data).

### REQ-B-3 — Scope-lock enumeration (40 files, 185 occurrences)

The Phase B rewrite SHALL touch EXACTLY the 40 files enumerated in `phase-2/final.md` §C1 scope-lock list (3 agents + 37 skills) and SHALL rewrite ALL 185 occurrences (182 lines including 3 dual-pattern lines at `implement-feature/SKILL.md:130`, `implement-feature/steps/03-decomposition.md:91`, `publish/SKILL.md:176`).

- **Provenance:** `phase-2` §C1 (line count 182 / occurrence count 185 verified by synthesis agent grep).
- **FC:** FC-B-6 (total occurrence count post-rewrite = 0 bare `core/X.md` outside guard-block prose).

### REQ-B-4 — Idempotency

The Phase B rewrite SHALL be idempotent: running the rewrite a second time on the post-Phase-B tree SHALL produce zero additional changes (verified via `diff` before vs after second run). The rewrite pattern SHALL NOT match already-rewritten paths (i.e., MUST NOT double-prefix `../../core/X.md` into `../../../../core/X.md`).

- **Provenance:** `phase-0-meta/prompts/spec.md` Phase B design bullet ("Show how the script is idempotent").
- **FC:** FC-B-7.

### REQ-B-5 — No prose-narrative collateral

Lines inside `<rationalization_red_flags>` tables and other discussion prose that mention paths in pure narrative (e.g., user-facing markdown documentation under `docs/`) are OUT-OF-SCOPE. Only the 40 files in REQ-B-3 are modified. `docs/`, `CHANGELOG.md`, `README.md`, `CLAUDE.md` are NOT rewritten by the Phase B sed (REQ-D updates them by hand).

- **Provenance:** `phase-2` §C1 scope-lock list (only `skills/` and `agents/` enumerated); roadmap L1503 ("Postiženo: 9 SKILL.md + 28 step files + 2 guard-block.md").
- **FC:** FC-B-8 (no doc/ changes from Phase B sed).

---

## REQ-C — Test Scenarios (Phase C)

### REQ-C-1 — Runtime external-CWD scenario (new)

A new harness scenario SHALL be added at `tests/scenarios/v10-skill-from-external-cwd.sh` that:

1. Creates a temporary external CWD via `mktemp -d` (cross-platform: Win Git-Bash + macOS BSD + Linux GNU).
2. Synthesizes a minimal plugin install fixture under `$TMPDIR/plugin-fixture/` containing `core/mcp-preflight.md` and one SKILL.md depth-2 file.
3. Simulates the guard-block.md preflight probe FROM the external CWD AND from inside the synthetic plugin root.
4. Asserts: (a) probe SUCCEEDS when CWD is the guard-block fixture directory (`skills/demo/data/`, depth-3) with depth-correct `../../../core/mcp-preflight.md`; (b) probe FAILS with exit 2 and the canonical message regex `plugin-root not resolved` when the sentinel is removed.
5. Uses `set -euo pipefail`, returns exit code `0` (PASS) / `1` (FAIL) / `77` (SKIP), emits `[PASS]` / `[FAIL]` / `[SKIP]` prefixed lines.
6. Cleans up tmpdir via `trap '...' EXIT`.

- **Provenance:** `phase-3` §Recommendation Phase C bullet C1 + C2; `phase-0-meta/prompts/spec.md` REQ-C bullet.
- **FC:** FC-C-1.

### REQ-C-2 — Static depth-lint scenario (new)

A new harness scenario SHALL be added at `tests/scenarios/v10-core-path-depth-consistency.sh` that:

1. For each file in the depth-class globs (REQ-B-2 table), parses every `(\.\./)+core/[a-z][a-z-]*\.md` occurrence.
2. Computes the file's depth from repo root via path-component count.
3. Asserts the dotdot-count in each occurrence matches `(depth + 1)` for files under `skills/` data/steps subdirs (depth-3 → `../../../`), `depth` for SKILL.md (depth-2 → `../../`), and `(depth)` for `agents/*.md` (depth-1 → `../`).
4. Fails with exit 1 + offending file:line list on any mismatch.
5. Same cross-platform constraints as REQ-C-1.
6. Mirrors the structure of `tests/scenarios/v10-step-completion-invariants-completeness.sh` (jq-free, pure bash + grep/awk).

- **Provenance:** `phase-3` §Recommendation Phase C bullet C3 (P0 kill-switch); `phase-2` §"B2 Depth-Split Mandate".
- **FC:** FC-C-2.

### REQ-C-3 — Counterfactual self-test of depth-lint

Phase 7 verification (Phase 8 commander) SHALL run `tests/scenarios/v10-core-path-depth-consistency.sh` on a deliberately-corrupted control fixture (one file's `../../../core/X.md` reverted to `../../core/X.md`) and confirm it FAILS with exit 1 and the offending file:line listed. This proves the lint actually catches the failure mode it is designed to catch.

- **Provenance:** `phase-3` §Falsifiable success metric §6 ("Counterfactual sanity").
- **FC:** FC-C-3.

### REQ-C-4 — Cross-platform compatibility

Both new scenarios SHALL use POSIX-portable constructs only. SHALL NOT use GNU-only `mktemp --suffix`, `grep -P`, GNU `sed -i` without backup suffix portably, or `realpath` (unavailable on macOS BSD by default). SHALL use `[ -r ... ]`, `mktemp -d`, BRE/ERE regex compatible with both GNU and BSD grep.

- **Provenance:** `phase-0-meta/prompts/spec.md` REQ-C bullet ("Cross-platform: must work on Win Git-Bash + Linux GNU + macOS BSD").
- **FC:** FC-C-1, FC-C-2 (both must run green in harness on Win Git-Bash).

---

## REQ-D — Cross-Cutting (Doc-quartet, CHANGELOG, version bump)

### REQ-D-1 — Doc-quartet v10-*.sh count update

The harness scenario count of `tests/scenarios/v10-*.sh` files SHALL be updated from **13 → 15** (two new scenarios added in REQ-C-1 and REQ-C-2) in all five doc-quartet files: `CLAUDE.md`, `README.md`, `docs/reference/automation-config.md`, `docs/reference/skills.md`, `docs/architecture.md`. Where a literal "13" count is present, it SHALL be updated to "15". Where no literal count is present (some files only name-cite individual scenarios), no count update is required for that file BUT the file SHALL be reviewed to confirm no stale numeric claim exists.

- **Provenance:** `phase-0-meta/prompts/spec.md` REQ-D-1 (revised user lock: 13 → 15, not 14); `claude-md` `feedback_doc_completeness.md` (doc-count drift audit discipline).
- **FC:** FC-D-1.

### REQ-D-2 — CHANGELOG entry

`CHANGELOG.md` SHALL gain a new section `### v10.2.0 -- core/ Path Disambiguation` placed above the v10.1.2 section, following the Keep-a-Changelog convention used by prior v10.1.x entries. The entry SHALL summarize Phase A (guard), Phase B (185-occurrence depth-aware rewrite across 40 files), Phase C (2 new harness scenarios: external-CWD + depth-lint), and reference roadmap L1489-L1513.

- **Provenance:** `phase-0-meta/prompts/spec.md` REQ-D-2; `claude-md` MEMORY.md "Version Release Process" (changelog entry without being asked).
- **FC:** FC-D-2.

### REQ-D-3 — Version bump 10.1.2 → 10.2.0

The version bump SHALL be performed via the `/ceos-agents:version-bump` skill (NOT manual edit of `.claude-plugin/plugin.json` or `marketplace.json`). The bump SHALL be a separate commit from the content commit per project release discipline. Git tag `v10.2.0` SHALL be created after the bump commit.

- **Provenance:** `claude-md` MEMORY.md "Version Release Process" + `feedback_version_bump_skill.md`.
- **FC:** FC-D-3.

### REQ-D-4 — Roadmap status update

`docs/plans/roadmap.md` L1489-L1513 (the v10.2.0 entry) SHALL be updated post-ship to reflect release status (e.g., adding `**Released:** 2026-MM-DD` line consistent with prior v10.x roadmap entries).

- **Provenance:** `claude-md` `feedback_roadmap_items.md` (roadmap items MUST be recorded).
- **FC:** FC-D-4.

---

## REQ-E — Reliability Invariants (No Regression of v10.0.0 Contract)

### REQ-E-1 — Step Completion Invariants section preserved

All 17 `agents/*.md` files SHALL retain their `## Step Completion Invariants` section unchanged in structure (header text, position relative to `## Output Contract` and `## Constraints`). The Phase B sed SHALL NOT touch the section headers; only `core/<file>.md` references inside the section body MAY be rewritten by the depth-1 sed (which is permitted and expected).

- **Provenance:** `claude-md` L106 (v10.0.0 reliability contract mandatory section); `phase-0-meta/prompts/spec.md` REQ-E-1.
- **FC:** FC-E-1.

### REQ-E-2 — Step Completion completeness scenario continues to pass

`tests/scenarios/v10-step-completion-invariants-completeness.sh` SHALL continue to return exit 0 ("PASS") on the v10.2.0 release-candidate commit.

- **Provenance:** `phase-0-meta/prompts/spec.md` REQ-E-2.
- **FC:** FC-E-2.

### REQ-E-3 — Harness 0-fail baseline

`./tests/harness/run-tests.sh` SHALL report **0 failed** scenarios on the v10.2.0 release-candidate commit. The pass count SHALL be ≥ 353 (current baseline 353/348/0/5 + 2 new scenarios from REQ-C). Skip count MAY rise within the 5-skip envelope (acceptable per v9.6.1 precedent).

- **Provenance:** `phase-0-meta/prompts/spec.md` REQ-E-3; `claude-md` MEMORY.md (harness 353/348/0/5 baseline).
- **FC:** FC-E-3.

### REQ-E-4 — `dispatch_witness` audit byte-identical

`core/lib/stage-invariant.sh` SHALL be byte-identical to v10.1.2 HEAD (commit `32f6f33`). No edits to the reliability library are permitted in v10.2.0. The functions `compute_dispatch_witness`, `check_dispatch_witness`, and `emit_witness_audit` retain their v10.1.2 behavior.

- **Provenance:** `phase-3` §Recommendation item 5; `phase-0-meta/prompts/spec.md` REQ-E-4.
- **FC:** FC-E-4.

### REQ-E-5 — Existing 13 v10-*.sh scenarios continue to pass

All 13 existing `tests/scenarios/v10-*.sh` files (enumerated in MEMORY.md count baseline) SHALL continue to return exit 0 on the v10.2.0 release-candidate commit. No regression introduced by Phase B's depth-aware rewrite SHALL surface in any existing scenario.

- **Provenance:** `phase-3` §Falsifiable success metric §4; `claude-md` MEMORY.md (13 v10-*.sh scenarios baseline).
- **FC:** FC-E-5.

---

## Open Questions Flagged for Gate 2

1. **Roadmap "Postiženo" count drift (cosmetic, non-blocking):** roadmap L1503 enumerates "9 SKILL.md (fix-bugs:12, implement-feature:14, scaffold:11, …) + 28 step files + 2 guard-block.md" with per-file occurrence counts that do not match the Phase 2 ground truth (e.g., roadmap claims 12 occurrences in fix-bugs SKILL.md; Phase 2 enumeration shows 11). REQ-D-4 covers the post-ship roadmap update — should Phase 7 also rewrite L1503 to match the Phase 2 numbers, or leave the per-file counts as user-narrative-only and not normative? **Default proposed:** leave L1503 untouched in Phase 7; the post-ship release-status update (REQ-D-4) is the only roadmap edit.

2. **Doc-quartet literal-count update (REQ-D-1):** `grep -c 'v10-.*\.sh'` returns `CLAUDE.md=1, README.md=0, docs/reference/automation-config.md=1, docs/reference/skills.md=0, docs/architecture.md=0`. Only CLAUDE.md L106 and automation-config.md cite an `v10-*.sh` name (not a count). No literal "13" appears in any of the 5 files for the v10 scenario count specifically. REQ-D-1 normatively requires "review for stale numeric claims"; the actual change set may be ZERO files if no literal "13" count exists. **Default proposed:** Phase 7 reviews and reports the actual change set during execution; if zero, FC-D-1 PASSES trivially.

3. **`scaffold/data/guard-block.md` content source (cosmetic, design-time):** Phase A specifies the new file mirrors the existing structure of `skills/fix-bugs/data/guard-block.md`. Open: does scaffold need scaffold-specific red-flag rows (e.g., "Draft skips spec-writer because 'description is detailed enough'")? **Default proposed:** Phase 7 authors scaffold-flavored red-flag rows mirroring the scaffold pipeline stages (spec-writer, spec-reviewer, scaffolder, architect, fixer-reviewer, test-engineer). Total file ~75-80 lines, similar to existing two.

---

**STATUS: REQUIREMENTS-COMPLETE**
