# Research Questions -- v10.2.0 core/ Path Disambiguation

## Critical (must answer before Phase 4 spec drafting)

C1. **Exact enumeration of `core/<file>.md` references requiring rewrite — scope-lock for Phase B.**
The roadmap (L1503) estimates 201 occurrences across 37 files. Live grep (`grep -rn "core/[a-z][a-z-]*\.md" skills/ agents/ --include="*.md"`, v10.1.2 HEAD commit 32f6f33) yields **182 occurrences across 40 unique files**: 175 occurrences in 37 `skills/` files + 7 occurrences in 3 `agents/` files (`agents/analyst.md`, `agents/fixer.md`, `agents/publisher.md`). The roadmap framing "9 SKILL.md + 28 step files + 2 guard-block.md" explicitly targets only `skills/` — yet agents contain the same bare `core/<file>.md` patterns. Phase 2 must produce a frozen flat `file:line:matched-pattern` list and resolve whether the 3 agent files are in-scope for Phase B. The 26-occurrence gap between 201 (roadmap estimate) and 175 (skills/ only) is a roadmap over-count, not a missed-file class. Grep command to freeze scope: `grep -rn "core/[a-z][a-z-]*\.md" skills/ agents/ --include="*.md"`.

C2. **Does `core/mcp-preflight.md` qualify as a stable, high-removal-cost probe target for the Phase A guard, and does `skills/scaffold/data/guard-block.md` exist?**
Live verification (v10.1.2 HEAD):
- `core/mcp-preflight.md` exists (47 lines). Referenced by exactly **6 skill files**: `fix-bugs/SKILL.md`, `implement-feature/SKILL.md`, `scaffold/SKILL.md`, `autopilot/SKILL.md`, `create-backlog/SKILL.md`, `sprint-plan/SKILL.md`. Zero agent references. High reference count (6 pipeline-critical skills) means renaming it requires a MINOR-or-MAJOR change — confirming it as a stable probe target. It is not marked deprecated in any roadmap entry. Verify: `grep -rn "core/mcp-preflight\.md" skills/ agents/ --include="*.md"`. Also confirm the guard path resolves correctly relative to the CWD Claude Code sets when loading `skills/fix-bugs/data/guard-block.md` (i.e., whether `[ -r core/mcp-preflight.md ]` or an absolute equivalent is needed).
- `skills/scaffold/data/guard-block.md` does **NOT** exist. Furthermore, `skills/scaffold/data/` directory does **NOT** exist (ls of `skills/scaffold/` returns only `SKILL.md` and `steps/`). Phase A therefore requires: (a) creating the `data/` directory, (b) creating `guard-block.md` as a new file. The Phase 4 spec must state explicitly: 2 edits (fix-bugs, implement-feature) + 1 directory-create + 1 file-create (scaffold). Also confirm whether `skills/scaffold/SKILL.md` already references a `guard-block.md` include, or whether a new include directive must also be added.

## Important (nice to have for Phase 4 spec)

I1. **Is `$PLUGIN_ROOT` a documented Claude Code dispatch contract, or must it be computed at runtime — and does this eliminate B1?**
Zero existing uses of `PLUGIN_ROOT` found across all 40 files with `core/` references (live grep returns no matches). This is strong evidence B1 is NOT currently supported by the runtime. Phase 2 must confirm via Claude Code plugin dispatch documentation or `.claude-plugin/plugin.json` schema whether any `PLUGIN_ROOT`-equivalent env var is injected. If no env var is reliably set for this plugin's SKILL.md dispatch context, B1 is **NOT-VIABLE-without-helper** and requires a `core/lib/path-resolver.sh` shim (~20 lines) to compute plugin root from `dirname`-twice. This is a binary gate: if B1 is eliminated, the design choice reduces to B2 (relative `../../core/`) vs B3 (inline prose clarifier + guard-block instruction).

I2. **What is the per-file-name distribution of the 182 occurrences — and does `core/state-manager.md` concentration create authoring risk for B2 or B3?**
Live counts (skills/ + agents/ combined): `core/state-manager.md` = **71 occurrences** (39% of 182 total); `core/agent-override-injector.md` = **34 occurrences** (19%). These two names alone account for 58% of all rewrites. If B2 (relative `../../core/`) is chosen, a single sed pattern `s|core/\([a-z][a-z-]*\.md\)|../../core/\1|g` must handle all 71 state-manager occurrences consistently. Confirm no occurrence uses a non-standard prefix (`./core/` or `skills/../core/`) that would escape a naive global replace. Check `skills/fix-bugs/steps/01-triage.md` (8 occurrences, highest per step file) as representative sample. If any edge-case prefix exists, it must be called out in the Phase 4 spec as a B2 risk.

I3. **Do the existing two guard-block.md files contain any path-resolution mechanism, or must Phase A write it from scratch?**
Live verification: neither `skills/fix-bugs/data/guard-block.md` (73 lines) nor `skills/implement-feature/data/guard-block.md` (70 lines) contains any `[ -r ... ]` test, `dirname`-based resolution, or `PLUGIN_ROOT` reference (grep for `PLUGIN_ROOT`, `__FILE__`, `dirname`, `[ -r` returns zero matches). The existing files contain orchestration contracts and rationalization-red-flag tables only. This means Phase A must add entirely new prose — either a new `<PREFLIGHT>` XML block or a prepended section — not edit existing logic. The Phase 4 spec must decide the structural placement: prepend vs new block type.

---

## Synthesis Notes

- Base agent: agent-3 (score: 24/25)
- Scores: agent-1=21/25, agent-2=22/25, agent-3=24/25 (std dev: ~1.25 — below 1.5 threshold, score-based selection applied)
- Contributions added from non-base agents:
  - From agent-2 I3: guard-block.md files contain no path-resolution mechanism — confirmed by live grep and merged as I3 above (agent-3 omitted this structural insight).
  - From agent-1 C2 (partial): probe CWD resolution question (does `[ -r core/mcp-preflight.md ]` resolve correctly relative to skill CWD) — merged into C2 above.
- Contradictions resolved:
  - **Occurrence count (175 vs 182):** Both counts are correct with different scopes. `skills/` only = 175 occurrences in 37 files (agent-2 framing). `skills/ + agents/` = 182 occurrences in 40 files (agent-1 and agent-3 framing). Resolved by live grep with explicit scope distinction. Roadmap estimate of 201 is an over-count regardless of scope.
  - **scaffold/data/ directory existence:** Agent-1 stated the directory "does exist" (incorrect). Agent-3 stated DIR_NOT_FOUND. Agent-2 was silent on directory. Live `ls skills/scaffold/` confirms: only `SKILL.md` and `steps/` present — **directory does NOT exist**. Agent-3 was correct.
  - **I2 numbering collision:** Agent-2 I2 covers guard-block.md path-resolution (merged as I3). Agent-3 I2 covers scaffold/data/ (kept in C2). Agent-2 I3 covers state-manager concentration (kept as I2). Renumbered for clarity with no content loss.
- Disagreement flags: None. Std dev 1.25 < 1.5. All agents agree on core facts; differences were scope-framing and omission, not factual contradiction (except scaffold/data/ existence, resolved by live verification).

DONE_WITH_CONCERNS
