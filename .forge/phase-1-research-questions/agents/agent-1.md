# Research Questions -- v10.2.0 core/ Path Disambiguation

## Critical (must answer before Phase 4 spec drafting)

C1. **Exact enumeration of `core/<file>.md` references requiring rewrite** — Which lines in which files
contain bare `core/<file>.md` patterns (no path prefix, no `../../`, no `${PLUGIN_ROOT}`) that
Phase B must rewrite? Produce a flat `file:line:matched-pattern` list. Based on a live grep, the
count is **182 occurrences across 40 unique files** (37 in `skills/` + 3 in `agents/`). This
differs from the roadmap estimate of "37 files / ~201 occurrences" — the agent files
(`agents/analyst.md`, `agents/fixer.md`, `agents/publisher.md`) add 7 references not counted in
the roadmap. Confirm the full list via:
`grep -rn "core/[a-z][a-z-]*\.md" skills/ agents/ --include="*.md"`
and freeze it as the scope-lock for Phase B. Without this freeze, the mechanical sed/regex pass
cannot be verified as complete.

C2. **Does `core/mcp-preflight.md` qualify as a stable, high-removal-cost probe target for the
Phase A guard?** Verify: (a) the file exists at `core/mcp-preflight.md` (47 lines), and (b) it is
referenced by at least 3 skills so removal cost is high (currently referenced by 6 files:
`skills/autopilot/SKILL.md`, `skills/create-backlog/SKILL.md`, `skills/fix-bugs/SKILL.md`,
`skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/sprint-plan/SKILL.md`).
Confirm via `grep -rn "core/mcp-preflight\.md" skills/ agents/ --include="*.md"`. Also confirm the
probe path used in the guard (`[ -r core/mcp-preflight.md ]` or absolute equivalent) resolves
correctly relative to whatever CWD Claude Code sets when loading `skills/fix-bugs/data/guard-block.md`.

## Important (nice to have for Phase 4 spec)

I1. **Is `$PLUGIN_ROOT` a documented Claude Code dispatch contract, or must it be computed at
runtime?** The repo contains zero existing uses of `PLUGIN_ROOT` in `skills/`, `agents/`, or
`core/` (confirmed by grep). B1 therefore requires a resolver helper that computes plugin root from
`__FILE__` or an absolute SKILL.md path at boot time. Determine whether Claude Code sets any
documented env var equivalent (e.g., `CLAUDE_PLUGIN_ROOT` — which appears in
`.claude/settings.local.json` for OTHER installed plugins but not for ceos-agents). If no such
env var is reliably set for this plugin's SKILL.md dispatch context, B1 is **NOT-VIABLE-without-helper**
and the B1 option requires a `core/lib/path-resolver.sh` shim of ~20 lines. This affects the
Phase A guard design (which env var, if any, to reference).

I2. **Does `skills/scaffold/data/guard-block.md` exist, or is it a new file Phase A must create?**
A `Glob` for `skills/*/data/guard-block.md` returns exactly 2 files:
`skills/fix-bugs/data/guard-block.md` and `skills/implement-feature/data/guard-block.md`.
`skills/scaffold/data/guard-block.md` does NOT exist. Phase A therefore creates 1 new file (not
edits 3 existing ones). Confirm the `skills/scaffold/data/` directory exists (it does: populated
with other step files) so the new file can be placed without creating a new sub-directory.

I3. **Do the 3 agent files with `core/<file>.md` references (`agents/analyst.md`,
`agents/fixer.md`, `agents/publisher.md`) need the same path rewrite as skill files, or are they
exempt?** These 7 references are inline prose descriptions (e.g., "resume-detection
(`core/resume-detection.md`) to detect…") rather than operative Read-tool instructions. Determine
whether Claude Code loads agent files with a CWD relative to `agents/` (in which case the same
ambiguity applies and B must cover them) or whether agent files are always loaded with an absolute
dispatch path that resolves `core/` correctly. This determines whether Phase B scope is 40 files
(182 refs) or 37 files (175 refs).

DONE_WITH_CONCERNS
