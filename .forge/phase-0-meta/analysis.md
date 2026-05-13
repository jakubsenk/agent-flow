# Phase 0 -- Meta-Agent Analysis -- v10.2.0

## 1. Task Type Classification

**Primary task_type:** `refactor`

The user input `implementuj verzi v10.2.0` resolves -- per `docs/plans/roadmap.md` L1489-L1513 -- to **`core/` path disambiguation in skill SKILL.md files (MINOR)**:
- **Phase A (~30 lines):** Fail-loud preflight guard in `skills/{fix-bugs,implement-feature,scaffold}/data/guard-block.md` probing `core/mcp-preflight.md`; aborts with `plugin-root not resolved` if unreadable.
- **Phase B (~50-100 lines net):** Mechanical rewrite of `core/<file>.md` references across **37 files / ~175-201 occurrences** to unambiguous shape (B1/B2/B3 -- Phase 4 spec decides).
- **Phase C (~30-50 lines):** New `tests/scenarios/v10-skill-from-external-cwd.sh` external-CWD regression scenario.

Secondary signal: `bugfix` (BIFITO-4293 silent degradation 2026-05-13). Classifying as refactor engages full pipeline (correct for 37-file scope + design decision); bugfix would underweight cross-file consistency risk.

## 2. Complexity Assessment

| Axis | Score | Justification |
|---|---|---|
| Scope | 3 | 37 files across `skills/` + 2 guard-block.md + new harness scenario. |
| Ambiguity | 2 | 3 work items enumerated + 3 candidate path-formats. One design choice remaining. |
| Risk | 3 | Path-resolution prose every orchestrator reads. Failure = silent degradation. |

**Composite = max(3, 2, 3) = 3.** Drives default agent scaling, default models, 3 review rounds, **JIT enabled**, default replanning, verification weights `correctness: 0.35, security: 0.25, spec_alignment: 0.2, robustness: 0.2` (sum = 1.0; tilted toward correctness because a missed reference returns silent degradation).

## 2b. Fast-Track Eligibility

**INELIGIBLE.** Composite = 3 (must be <=2). Confidence = 0.85 (must be >=0.9). Preconditions fail. Tier A + Tier B not evaluated. **No `fast_spec.json` written.** No `security_evaluation` block emitted (Tier B only runs when preconditions pass). Note: raw input string contains zero Tier A keywords; Tier A would have passed vacuously.

## 3. Domain Identification

| Dimension | Value |
|---|---|
| Language/Runtime | Markdown (prose) + Bash 4+ (POSIX subset for Win Git-Bash + macOS BSD + Linux GNU) |
| Framework | Claude Code plugin (markdown-only orchestration; no build system) |
| Domain | Orchestrator-internal text refactor + test infrastructure |
| Specialty | Cross-platform path resolution; silent-degradation prevention; harness coverage gap; mechanical-rewrite correctness |

## 4. Codebase Context Assessment

**Repo:** `C:/gitea_ceos-agents` -- ceos-agents Claude Code plugin v10.1.2 (commit `32f6f33`, tag `v10.1.2`).

**Architecture (CLAUDE.md):** 17 agents with mandatory `## Step Completion Invariants`; 18 skills using thin-controller pattern (SKILL.md + steps/*.md); 17 top-level `core/*.md` contracts (count enforced); shared lib `core/lib/stage-invariant.sh` (134L, subdir+`.sh` exempt from count); harness `tests/harness/run-tests.sh` at 353/348/0/5; 13 v10-*.sh scenarios.

**Path-resolution failure mode (the bug):** Orchestrator reads `Read core/mcp-preflight.md` from `skills/fix-bugs/SKILL.md`. From out-of-repo CWD, `core/` resolves to `<cwd>/core/` (nonexistent); Claude silently continued without core logic (BIFITO-4293) -- lost resume-detection, mcp-preflight, config-reader, block-handler, decomposition-heuristics, agent-override-injector, dispatch_witness audit.

**Files affected (live grep 2026-05-13):** 37 files: 9 SKILL.md (analyze-bug, autopilot, create-backlog, fix-bugs, implement-feature, publish, scaffold, setup-mcp, sprint-plan), 2 existing guard-block.md (fix-bugs/data, implement-feature/data), 28 step files under skills/{fix-bugs,implement-feature,scaffold}/steps/.

**Test patterns:** `v10-<short>.sh`, `set -euo pipefail`, exit 0/1/77, `[PASS]/[FAIL]/[SKIP]`, no jq.

**Doc-count drift discipline:** Skills 18 (UNCHANGED), Core 17 (UNCHANGED), Agents 17 (UNCHANGED), Config sections 18 (UNCHANGED), v10-*.sh 13 -> 14 (+1).

**Release discipline (project memory):** (1) harness BEFORE commit, (2) changelog same commit as content, (3) version-bump via `/ceos-agents:version-bump` skill, separate commit, then tag.

## Codebase Context Snippet (for downstream prompts)

```
PROJECT: ceos-agents v10.1.2 (Claude Code plugin, markdown-only; commit 32f6f33, tag v10.1.2)
LANGUAGE: Markdown + Bash 4+ POSIX (Win Git-Bash + macOS BSD + Linux GNU)
NO BUILD SYSTEM. NO DEPENDENCIES. Harness: tests/harness/run-tests.sh (353/348/0/5).

V10.2.0 SCOPE -- core/ path disambiguation per docs/plans/roadmap.md L1489-L1513:
- Phase A: Fail-loud guard in skills/{fix-bugs,implement-feature,scaffold}/data/guard-block.md (~30 lines)
- Phase B: Mechanical rewrite of ~175-201 `core/<file>.md` occurrences across 37 files (B1/B2/B3 TBD)
- Phase C: tests/scenarios/v10-skill-from-external-cwd.sh -- external-CWD regression (~30-50 lines)

KEY FILES (v10.1.2 baseline):
- skills/fix-bugs/data/guard-block.md (73L), skills/implement-feature/data/guard-block.md (70L)
- skills/scaffold/data/guard-block.md (NEW in Phase A)
- core/mcp-preflight.md (47L) -- canonical probe target for Phase A guard
- 9 SKILL.md + 28 step files + 2 existing guard-block.md = 37 files
- tests/scenarios/v10-*.sh: 13 existing, +1 new (Phase C)
- core/lib/stage-invariant.sh -- v10.0.0 reliability lib (EXEMPT from core/ count)

CLASSIFICATION: MINOR (no Auto Config contract change, no agent Output Contract change).

DOC-QUARTET SYNC: Skills 18 / Core 17 / Agents 17 / Config 18 (all UNCHANGED); v10-*.sh 13 -> 14.

V10.0.0 RELIABILITY CONTRACT (must not regress):
- agents/*.md ## Step Completion Invariants mandatory section
- dispatch_witness computed/verified per dispatch
- tests/scenarios/v10-step-completion-invariants-completeness.sh enforces presence
- Harness MUST remain 0-fail post-v10.2.0

VERSION TARGET: v10.1.2 -> v10.2.0 (MINOR via /ceos-agents:version-bump skill).

EVIDENCE BASE:
- docs/plans/roadmap.md L1489-L1513 (canonical v10.2.0 spec)
- BIFITO-4293 transcript (described in roadmap text)
- core/mcp-preflight.md (canonical probe target)
- CLAUDE.md (conventions, versioning, doc-count discipline)
- .forge.bak-2026-05-13T111528Z/ (v10.1.0 forge reference pattern)
```

## Confidence Scoring

| Q | Score | Why |
|---|---|---|
| Q1 Well-defined? | 0.85 | 3 work items enumerated; B1/B2/B3 path-format open; Phase 4 spec decides. |
| Q2 Context supports? | 0.95 | Full repo + prior forge artifacts + roadmap text. |
| Q3 Within capabilities? | 0.95 | Mechanical refactor + 1 test scenario well within forge envelope. |

**Composite = min = 0.85.** Threshold 0.7. **Proceed with noted assumptions:**
1. Path-format defaults to **B3** (inline clarifier + guard-block resolver instruction) unless Phase 4 finds stronger reason for B1/B2.
2. Phase A guard added to `skills/scaffold/data/guard-block.md` (NEW file -- parity with fix-bugs + implement-feature). If Phase 4 decides otherwise, scope shrinks by 1 file.
3. CHANGELOG.md v10.2.0 entry follows existing v10.1.x structure (Keep-a-Changelog).
4. Version bump uses `/ceos-agents:version-bump` skill, not manual (project rule).

## 5. Domain Expertise Consumption

**Template loaded:** NONE. `routing.auto_select_template == false`. Section skipped per protocol.

## 6. Template Auto-Selection Protocol

**SKIPPED.** `routing.auto_select_template = false`. No `template_selection` block.

## 7. Routing Decision

See `.forge/phase-0-meta/routing-decision.json` (standalone, 7 top-level keys). Summary: `task_type=refactor`, `action=full_pipeline`, `confidence=0.92`.

## Provenance

- Repo state: `C:/gitea_ceos-agents` @ `32f6f33` (tag `v10.1.2`) on 2026-05-13.
- Roadmap source: `docs/plans/roadmap.md` L1489-L1513 (v10.2.0); L1517-L1610 (v10.3.0 GitHub cleanup, OUT of scope).
- Pre-merged config: `.forge/forge.json:config` (all `source: "default"`).

## Briefing Discrepancy Note

The user-facing briefing characterized v10.2.0 as **"GitHub pre-release cleanup"**. Roadmap L1521 explicitly states that scope was **renumbered to v10.3.0** on 2026-05-13. Per project rule "trust the roadmap", actual v10.2.0 is `core/` path disambiguation (BIFITO-4293 fix). Downstream phases will produce that release, NOT cleanup. If user intended cleanup, orchestrator should surface this at Phase 4 approval gate.