# Research Questions -- v10.2.0 core/ Path Disambiguation

## Critical (must answer before Phase 4 spec drafting)

**C1. Exact enumeration of `core/<file>.md` occurrences needing rewrite.**

The roadmap (L1503) estimates 201 occurrences across 37 files. Actual survey (2026-05-13 grep against v10.1.2 HEAD) yields **175 occurrences across 37 files** in `skills/` plus **7 additional occurrences across 3 agent files** (`agents/analyst.md` lines 114, 307; `agents/fixer.md` lines 66, 160; `agents/publisher.md` lines 65, 77, 144). The roadmap scope statement "9 SKILL.md + 28 step files + 2 guard-block.md" does not include agents — yet agents contain unambiguous `core/<file>.md` patterns. Phase 2 must produce a flat `file:line:matched-pattern` list that resolves whether (a) the 26-occurrence gap between 201 and 175 is a roadmap over-count or a genuine missed-file class, and (b) whether agent files are in or out of Phase B scope. Without a frozen list, Phase 4 spec cannot lock scope. Files to read: grep output over `skills/**/*.md` and `agents/*.md`; cross-check against `docs/plans/roadmap.md` L1499-L1503.

**C2. Does `skills/scaffold/data/guard-block.md` exist, or does Phase A create it from scratch?**

The roadmap (L1497) targets "skills/{fix-bugs,implement-feature,scaffold}/data/guard-block.md" for Phase A. A Glob of `skills/*/data/guard-block.md` returns exactly two matches: `skills/fix-bugs/data/guard-block.md` (73L) and `skills/implement-feature/data/guard-block.md` (70L). `skills/scaffold/data/guard-block.md` does NOT exist. This changes the Phase A work-item count: the guard for scaffold is a file creation, not an edit. Phase 4 spec must state explicitly whether the scaffold guard should be structurally identical to the fix-bugs guard, or whether it differs (scaffold has no `orchestration_contract` block currently). Verify by reading `skills/scaffold/SKILL.md` to understand how scaffold currently boots and whether a `data/` directory exists at all for scaffold. Files: `skills/scaffold/SKILL.md`, `skills/fix-bugs/data/guard-block.md`.

## Important (nice to have for Phase 4 spec)

**I1. Is `$PLUGIN_ROOT` a documented Claude Code dispatch contract, or is it undefined at orchestrator runtime?**

B1 path format (`${PLUGIN_ROOT}/core/...md`) depends on an env var being set and resolvable by the orchestrating Claude process. A grep of `PLUGIN_ROOT` across all `skills/`, `agents/`, and `core/` returns zero matches — the variable is not used anywhere in the plugin today. Phase 2 must determine whether Claude Code's Task tool dispatch injects any `PLUGIN_ROOT`-equivalent env var, or whether the guard-block.md resolver must compute it dynamically via `dirname`-twice from `__file__` or an equivalent Bash idiom. If `PLUGIN_ROOT` is unsupported, B1 is eliminated as a candidate. Files/sources: Claude Code public documentation on skill dispatch environment; `skills/fix-bugs/data/guard-block.md` for the existing resolver pattern (if any).

**I2. How many skills reference `core/mcp-preflight.md` by name, and is that count sufficient to establish it as a stable probe target for the Phase A guard?**

The roadmap (L1497) designates `core/mcp-preflight.md` as the canonical probe target for Phase A's fail-loud guard. Survey shows it is referenced by **6 skills** (`fix-bugs/SKILL.md`, `implement-feature/SKILL.md`, `scaffold/SKILL.md`, `autopilot/SKILL.md`, `create-backlog/SKILL.md`, `sprint-plan/SKILL.md`) and by **0 agents**. The file exists at `core/mcp-preflight.md` (47L). High reference count (6) means renaming it would be a MINOR-or-MAJOR change, making it a stable probe target. Phase 2 should confirm the file is not marked deprecated or "to-be-renamed" in any roadmap entry, and check whether the Phase A guard should test `core/mcp-preflight.md` specifically or any canonical `core/` sentinel. Files: `core/mcp-preflight.md`, `docs/plans/roadmap.md` for future rename risk.

**I3. Do the existing two guard-block.md files contain a path-resolution mechanism, or must one be written from scratch for Phase A?**

The Phase A guard must test readability of `core/mcp-preflight.md` at a resolved plugin-root path. Both existing guard-block.md files (`skills/fix-bugs/data/guard-block.md` 73L, `skills/implement-feature/data/guard-block.md` 70L) contain orchestration contracts and rationalization-red-flag tables, but no preflight path-probe logic. Verified by reading both files: neither contains a `[ -r ... ]` test or `dirname`-based resolution. This means Phase A must add new prose (not edit existing prose), or prepend a new block to each guard-block.md. Phase 4 spec must decide whether the probe is a new `<PREFLIGHT>` XML block or inlined into the existing `<MANDATORY-EXECUTION-GUARD>`. Files: `skills/fix-bugs/data/guard-block.md`, `skills/implement-feature/data/guard-block.md`.

DONE_WITH_CONCERNS
