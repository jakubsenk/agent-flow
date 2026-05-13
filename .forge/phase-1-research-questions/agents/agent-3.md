# Research Questions -- v10.2.0 core/ Path Disambiguation

**Angle:** Primary Implementation Vector (dispatch compatibility, file-level concerns)
**Agent:** 3 of 3
**Grounded via:** live repo survey 2026-05-13, v10.1.2 baseline (commit 32f6f33)

---

## Critical (must answer before Phase 4 spec drafting)

**C1. Exact enumeration — which 40 files and 182 total occurrences contain `core/<file>.md` patterns?**

The roadmap (L1503) estimates 37 files / ~201 occurrences but live grep reveals 40 files / 182 occurrences. The discrepancy matters for Phase B scope-lock: 3 additional files are `agents/analyst.md`, `agents/fixer.md`, `agents/publisher.md` (7 occurrences total, currently excluded from roadmap's "37 files" framing). The roadmap explicitly scopes Phase B to skills/ only ("9 SKILL.md + 28 step files + 2 guard-block.md"). Before Phase 4 spec drafting, the team must decide: are `agents/*.md` references in-scope for Phase B rewrite, or are they correctly excluded because agents are dispatched from their own context? Answer by grepping `agents/analyst.md` L114, L307; `agents/fixer.md` L66, L160; `agents/publisher.md` L65, L77, L144 and confirming whether the same silent-degradation failure mode applies to Task-dispatched agents (they receive full file contents, so path resolution may differ from skill orchestration).

**C2. Does `core/mcp-preflight.md` have a stable, high-removal-cost reference profile that makes it a safe canonical probe target for the Phase A guard?**

Live count: referenced by exactly **6 skill files** (`fix-bugs/SKILL.md`, `scaffold/SKILL.md`, `implement-feature/SKILL.md`, `create-backlog/SKILL.md`, `sprint-plan/SKILL.md`, `autopilot/SKILL.md`) and **0 agent files**. It is the most frequently referenced file per skill (6 skills) but only the 6th most referenced by total line-occurrences (6 of 182 total). Confirm that `core/mcp-preflight.md` exists at commit 32f6f33 (verified: yes, at `C:/gitea_ceos-agents/core/mcp-preflight.md`) and that its removal would require touching all 6 pipeline-critical skills — confirming high removal cost and stability as probe target. Also confirm it has no aliases or symlinks that could satisfy a `[ -r ]` check from a wrong CWD accidentally.

---

## Important (nice to have for Phase 4 spec)

**I1. Is `$PLUGIN_ROOT` (option B1) a documented Claude Code dispatch contract, or is it undefined in the runtime environment?**

Zero existing uses of `PLUGIN_ROOT`, `PLUGIN_ROOT`, or `../../core` found across all 40 files (live grep returned no matches). This is strong evidence B1 is not currently supported. Confirm by reading Claude Code plugin dispatch documentation or checking the `.claude-plugin/plugin.json` schema for any env-var injection contract. If `PLUGIN_ROOT` is undefined in dispatch context, B1 is eliminated and the decision reduces to B2 (relative `../../core/`) vs B3 (inline prose clarifier + guard-block instruction). This is a binary gate that collapses the design space before Phase 4 spec drafting.

**I2. Does `skills/scaffold/data/guard-block.md` currently exist, and if not, does `skills/scaffold/data/` directory exist to receive it?**

Live state: `skills/scaffold/data/` directory does **not exist** (ls returned DIR_NOT_FOUND). `skills/scaffold/` contains only `SKILL.md` and `steps/`. This means Phase A must: (a) create the `data/` directory, (b) create `guard-block.md` as a new file — it cannot be a simple edit of an existing file. Contrast with `fix-bugs` and `implement-feature` which both have existing `data/guard-block.md` files (73L and confirmed). The Phase 4 spec must distinguish: 2 edits + 1 create (not 3 edits). Confirm also whether `skills/scaffold/SKILL.md` already has a reference point for a `guard-block.md` include, or whether a new `include` directive must be added there as well.

**I3. Of the 182 total `core/<file>.md` occurrences, what is the distribution across the 17 unique core file names — specifically: does `core/state-manager.md` alone account for >38% of all rewrites, and does this concentration create any B2/B3 authoring risk?**

Live count shows `core/state-manager.md` appears 71 times (71/175 = 40.6% of skills/ occurrences, ~39% of total 182). The next highest is `core/agent-override-injector.md` at 34 (19%). If B3 (inline prose clarifier at first occurrence per file) is chosen, state-manager.md appears in so many files that "first occurrence per file" prose insertion is mechanical. If B2 (relative path `../../core/`) is chosen, state-manager.md's 71 occurrences need consistent sed rewriting. Confirm the full per-file breakdown is consistent with a single regex substitution pattern `s|core/\([a-z][a-z-]*\.md\)|../../core/\1|g` (or equivalent B3 prose), and that no occurrence uses a non-standard prefix (e.g., `./core/` or `skills/../core/`) that would escape a naive global replace. Check `skills/fix-bugs/steps/01-triage.md` (8 occurrences, highest per step file) as representative sample.

---

DONE_WITH_CONCERNS
