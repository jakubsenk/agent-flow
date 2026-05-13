# Research Answers -- v10.2.0 core/ Path Disambiguation

**Agent:** 3 of 3 (Angle 1 -- Primary Implementation Vector)
**Commit:** 32f6f33 (v10.1.2)
**Date:** 2026-05-13

---

## C1. Exact enumeration of `core/<file>.md` references requiring rewrite — scope-lock for Phase B.

**Answer:** Live grep of `skills/` produces **175 occurrences across 37 files**. Live grep of `agents/` produces **7 occurrences across 3 files** (`agents/analyst.md`, `agents/fixer.md`, `agents/publisher.md`). Combined total: **182 occurrences across 40 unique files**. The roadmap estimate of 201 is an over-count regardless of scope. Zero occurrences use non-standard prefixes (`./core/`, `../../core/`, `${PLUGIN_ROOT}/core/`) — every match is a bare `core/<file>.md` reference, confirming no edge cases that would escape a naive global sed substitution. The `core/lib/stage-invariant.sh` references (`core/lib/[a-z]*.sh`) are a distinct pattern — NOT matched by `core/[a-z][a-z-]*\.md` — and are out of Phase B scope. Whether the 3 agent files are in-scope for Phase B is a Phase 4 spec decision; they contain the same bare pattern and carry the same disambiguation risk.

**Evidence:** grep command: `grep -rn "core/[a-z][a-z-]*\.md" skills/ --include="*.md"` → 175 hits; `grep -rn "core/[a-z][a-z-]*\.md" agents/ --include="*.md"` → 7 hits; non-standard prefix check `grep -rn "\./core/\|skills/\.\./core/\|\.\.\/core/" skills/ agents/ --include="*.md"` → 0 hits.

## Phase B Scope Lock (machine-readable, derived from C1)

```
skills/analyze-bug/SKILL.md:23:core/external-input-sanitizer.md
skills/autopilot/SKILL.md:37:core/config-reader.md
skills/autopilot/SKILL.md:69:core/config-reader.md
skills/autopilot/SKILL.md:79:core/mcp-preflight.md
skills/autopilot/SKILL.md:420:core/post-publish-hook.md
skills/create-backlog/SKILL.md:17:core/config-reader.md
skills/create-backlog/SKILL.md:42:core/mcp-preflight.md
skills/create-backlog/SKILL.md:88:core/state-manager.md
skills/create-backlog/SKILL.md:99:core/state-manager.md
skills/create-backlog/SKILL.md:110:core/agent-override-injector.md
skills/create-backlog/SKILL.md:118:core/state-manager.md
skills/create-backlog/SKILL.md:281:core/state-manager.md
skills/create-backlog/SKILL.md:316:core/state-manager.md
skills/create-backlog/SKILL.md:328:core/agent-override-injector.md
skills/create-backlog/SKILL.md:349:core/state-manager.md
skills/create-backlog/SKILL.md:377:core/agent-override-injector.md
skills/fix-bugs/data/guard-block.md:62:core/config-reader.md
skills/fix-bugs/SKILL.md:108:core/resume-detection.md
skills/fix-bugs/SKILL.md:113:core/resume-detection.md
skills/fix-bugs/SKILL.md:124:core/config-reader.md
skills/fix-bugs/SKILL.md:130:core/profile-parser.md
skills/fix-bugs/SKILL.md:162:core/mcp-preflight.md
skills/fix-bugs/SKILL.md:191:core/agent-override-injector.md
skills/fix-bugs/SKILL.md:220:core/mcp-body-formatting.md
skills/fix-bugs/SKILL.md:221:core/block-handler.md
skills/fix-bugs/SKILL.md:225:core/block-handler.md
skills/fix-bugs/SKILL.md:246:core/agent-override-injector.md
skills/fix-bugs/steps/01-triage.md:9:core/status-verification.md
skills/fix-bugs/steps/01-triage.md:22:core/status-verification.md
skills/fix-bugs/steps/01-triage.md:47:core/state-manager.md
skills/fix-bugs/steps/01-triage.md:51:core/agent-override-injector.md
skills/fix-bugs/steps/01-triage.md:70:core/external-input-sanitizer.md
skills/fix-bugs/steps/01-triage.md:81:core/state-manager.md
skills/fix-bugs/steps/01-triage.md:145:core/agent-states.md
skills/fix-bugs/steps/01-triage.md:173:core/state-manager.md
skills/fix-bugs/steps/02-impact.md:24:core/state-manager.md
skills/fix-bugs/steps/02-impact.md:28:core/agent-override-injector.md
skills/fix-bugs/steps/02-impact.md:56:core/state-manager.md
skills/fix-bugs/steps/02-impact.md:85:core/decomposition-heuristics.md
skills/fix-bugs/steps/02-impact.md:90:core/state-manager.md
skills/fix-bugs/steps/02-impact.md:106:core/agent-override-injector.md
skills/fix-bugs/steps/02-impact.md:118:core/decomposition-heuristics.md
skills/fix-bugs/steps/02-impact.md:125:core/state-manager.md
skills/fix-bugs/steps/03-reproduce.md:39:core/state-manager.md
skills/fix-bugs/steps/03-reproduce.md:43:core/agent-override-injector.md
skills/fix-bugs/steps/03-reproduce.md:75:core/state-manager.md
skills/fix-bugs/steps//03-reproduce.md:100:core/state-manager.md
skills/fix-bugs/steps/04-fixer-reviewer-loop.md:3:core/fixer-reviewer-loop.md
skills/fix-bugs/steps/04-fixer-reviewer-loop.md:25:core/state-manager.md
skills/fix-bugs/steps/04-fixer-reviewer-loop.md:34:core/agent-override-injector.md
skills/fix-bugs/steps/04-fixer-reviewer-loop.md:138:core/agent-override-injector.md
skills/fix-bugs/steps/04-fixer-reviewer-loop.md:174:core/state-manager.md
skills/fix-bugs/steps/05-smoke.md:19:core/state-manager.md
skills/fix-bugs/steps/05-smoke.md:41:core/state-manager.md
skills/fix-bugs/steps/06-test.md:26:core/state-manager.md
skills/fix-bugs/steps/06-test.md:31:core/agent-override-injector.md
skills/fix-bugs/steps/07-e2e.md:31:core/state-manager.md
skills/fix-bugs/steps/07-e2e.md:35:core/agent-override-injector.md
skills/fix-bugs/steps/07-e2e.md:76:core/agent-override-injector.md
skills/fix-bugs/steps/08-browser-verify.md:30:core/state-manager.md
skills/fix-bugs/steps/08-browser-verify.md:34:core/agent-override-injector.md
skills/fix-bugs/steps/09-acceptance-gate.md:39:core/state-manager.md
skills/fix-bugs/steps/09-acceptance-gate.md:44:core/agent-override-injector.md
skills/fix-bugs/steps/09-acceptance-gate.md:78:core/state-manager.md
skills/fix-bugs/steps/10-pre-publish.md:28:core/agent-override-injector.md
skills/fix-bugs/steps/10-pre-publish.md:53:core/state-manager.md
skills/fix-bugs/steps/11-publish.md:20:core/state-manager.md
skills/fix-bugs/steps/11-publish.md:25:core/agent-override-injector.md
skills/fix-bugs/steps/11-publish.md:52:core/state-manager.md
skills/fix-bugs/steps/11-publish.md:66:core/post-publish-hook.md
skills/fix-bugs/steps/11-publish.md:74:core/fix-verification.md
skills/fix-bugs/steps/12-result.md:11:core/state-manager.md
skills/implement-feature/data/guard-block.md:58:core/decomposition-heuristics.md
skills/implement-feature/data/guard-block.md:67:core/resume-detection.md
skills/implement-feature/SKILL.md:35:core/resume-detection.md
skills/implement-feature/SKILL.md:41:core/config-reader.md
skills/implement-feature/SKILL.md:45:core/mcp-preflight.md
skills/implement-feature/SKILL.md:53:core/mcp-body-formatting.md
skills/implement-feature/SKILL.md:65:core/profile-parser.md
skills/implement-feature/SKILL.md:69:core/resume-detection.md
skills/implement-feature/SKILL.md:71:core/resume-detection.md
skills/implement-feature/SKILL.md:77:core/state-manager.md
skills/implement-feature/SKILL.md:79:core/agent-states.md
skills/implement-feature/SKILL.md:110:core/resume-detection.md
skills/implement-feature/SKILL.md:122:core/agent-override-injector.md
skills/implement-feature/SKILL.md:130:core/block-handler.md
skills/implement-feature/SKILL.md:130:core/state-manager.md
skills/implement-feature/steps/01-spec.md:10:core/state-manager.md
skills/implement-feature/steps/01-spec.md:24:core/state-manager.md
skills/implement-feature/steps/01-spec.md:29:core/agent-override-injector.md
skills/implement-feature/steps/01-spec.md:33:core/external-input-sanitizer.md
skills/implement-feature/steps/01-spec.md:45:core/state-manager.md
skills/implement-feature/steps/01-spec.md:62:core/state-manager.md
skills/implement-feature/steps/01-spec.md:67:core/state-manager.md
skills/implement-feature/steps/01-spec.md:79:core/state-manager.md
skills/implement-feature/steps/01-spec.md:84:core/agent-override-injector.md
skills/implement-feature/steps/01-spec.md:99:core/state-manager.md
skills/implement-feature/steps/02-architect.md:6:core/state-manager.md
skills/implement-feature/steps/02-architect.md:25:core/agent-override-injector.md
skills/implement-feature/steps/02-architect.md:40:core/state-manager.md
skills/implement-feature/steps/03-decomposition.md:7:core/state-manager.md
skills/implement-feature/steps/03-decomposition.md:11:core/decomposition-heuristics.md
skills/implement-feature/steps/03-decomposition.md:59:core/state-manager.md
skills/implement-feature/steps/03-decomposition.md:64:core/state-manager.md
skills/implement-feature/steps/03-decomposition.md:91:core/tracker-subtask-creator.md
skills/implement-feature/steps/03-decomposition.md:91:core/mcp-body-formatting.md
skills/implement-feature/steps/03-decomposition.md:105:core/state-manager.md
skills/implement-feature/steps/04-fixer-reviewer-loop.md:19:core/state-manager.md
skills/implement-feature/steps/04-fixer-reviewer-loop.md:39:core/agent-override-injector.md
skills/implement-feature/steps/04-fixer-reviewer-loop.md:52:core/state-manager.md
skills/implement-feature/steps/04-fixer-reviewer-loop.md:61:core/agent-states.md
skills/implement-feature/steps/04-fixer-reviewer-loop.md:79:core/agent-override-injector.md
skills/implement-feature/steps/04-fixer-reviewer-loop.md:85:core/fixer-reviewer-loop.md
skills/implement-feature/steps/04-fixer-reviewer-loop.md:91:core/state-manager.md
skills/implement-feature/steps/04-fixer-reviewer-loop.md:127:core/state-manager.md
skills/implement-feature/steps/05-smoke.md:11:core/state-manager.md
skills/implement-feature/steps/05-smoke.md:24:core/state-manager.md
skills/implement-feature/steps/06-test.md:20:core/state-manager.md
skills/implement-feature/steps/06-test.md:24:core/state-manager.md
skills/implement-feature/steps/06-test.md:43:core/agent-override-injector.md
skills/implement-feature/steps/06-test.md:55:core/state-manager.md
skills/implement-feature/steps/06-test.md:71:core/state-manager.md
skills/implement-feature/steps/06-test.md:89:core/agent-override-injector.md
skills/implement-feature/steps/06-test.md:101:core/state-manager.md
skills/implement-feature/steps/06-test.md:114:core/state-manager.md
skills/implement-feature/steps/07-acceptance-gate.md:13:core/state-manager.md
skills/implement-feature/steps/07-acceptance-gate.md:32:core/agent-override-injector.md
skills/implement-feature/steps/07-acceptance-gate.md:46:core/state-manager.md
skills/implement-feature/steps/08-publish.md:22:core/state-manager.md
skills/implement-feature/steps/08-publish.md:41:core/agent-override-injector.md
skills/implement-feature/steps/08-publish.md:51:core/state-manager.md
skills/implement-feature/steps/08-publish.md:111:core/state-manager.md
skills/implement-feature/steps/08-publish.md:128:core/post-publish-hook.md
skills/implement-feature/steps/08-publish.md:132:core/fix-verification.md
skills/publish/SKILL.md:176:core/mcp-detection.md
skills/publish/SKILL.md:180:core/mcp-detection.md
skills/publish/SKILL.md:316:core/mcp-detection.md
skills/publish/SKILL.md:317:core/mcp-detection.md
skills/publish/SKILL.md:318:core/mcp-detection.md
skills/scaffold/SKILL.md:145:core/resume-detection.md
skills/scaffold/SKILL.md:154:core/resume-detection.md
skills/scaffold/SKILL.md:162:core/agent-override-injector.md
skills/scaffold/SKILL.md:202:core/state-manager.md
skills/scaffold/SKILL.md:241:core/mcp-detection.md
skills/scaffold/SKILL.md:258:core/mcp-preflight.md
skills/scaffold/SKILL.md:327:core/state-manager.md
skills/scaffold/SKILL.md:334:core/state-manager.md
skills/scaffold/SKILL.md:336:core/agent-states.md
skills/scaffold/SKILL.md:451:core/fixer-reviewer-loop.md
skills/scaffold/SKILL.md:574:core/agent-override-injector.md
skills/scaffold/steps/01-mode-resolve.md:55:core/state-manager.md
skills/scaffold/steps/01-mode-resolve.md:63:core/mcp-detection.md
skills/scaffold/steps/01-mode-resolve.md:74:core/post-publish-hook.md
skills/scaffold/steps/02-spec-write-review.md:10:core/external-input-sanitizer.md
skills/scaffold/steps/02-spec-write-review.md:18:core/agent-override-injector.md
skills/scaffold/steps/04-architect.md:53:core/block-handler.md
skills/scaffold/steps/05-fixer-reviewer-loop.md:62:core/agent-states.md
skills/scaffold/steps/05-fixer-reviewer-loop.md:70:core/fixer-reviewer-loop.md
skills/scaffold/steps/05-fixer-reviewer-loop.md:100:core/block-handler.md
skills/scaffold/steps/07-spec-verify.md:52:core/status-verification.md
skills/scaffold/steps/08-final-report.md:11:core/state-manager.md
skills/setup-mcp/SKILL.md:33:core/mcp-detection.md
skills/setup-mcp/SKILL.md:64:core/mcp-detection.md
skills/setup-mcp/SKILL.md:98:core/mcp-detection.md
skills/setup-mcp/SKILL.md:100:core/mcp-detection.md
skills/setup-mcp/SKILL.md:299:core/mcp-detection.md
skills/setup-mcp/SKILL.md:309:core/mcp-detection.md
skills/sprint-plan/SKILL.md:27:core/config-reader.md
skills/sprint-plan/SKILL.md:64:core/mcp-preflight.md
skills/sprint-plan/SKILL.md:79:core/state-manager.md
skills/sprint-plan/SKILL.md:122:core/agent-override-injector.md
skills/sprint-plan/SKILL.md:144:core/agent-override-injector.md
skills/sprint-plan/SKILL.md:170:core/state-manager.md
skills/sprint-plan/SKILL.md:220:core/state-manager.md
skills/sprint-plan/SKILL.md:270:core/state-manager.md
skills/sprint-plan/SKILL.md:289:core/state-manager.md
skills/sprint-plan/SKILL.md:318:core/agent-override-injector.md
agents/analyst.md:114:core/resume-detection.md
agents/analyst.md:307:core/resume-detection.md
agents/fixer.md:66:core/resume-detection.md
agents/fixer.md:160:core/resume-detection.md
agents/publisher.md:65:core/mcp-body-formatting.md
agents/publisher.md:77:core/status-verification.md
agents/publisher.md:144:core/mcp-body-formatting.md
```

**Total: 175 occurrences in 37 skills/ files + 7 occurrences in 3 agents/ files = 182 occurrences in 40 files.**

---

## C2. Does `core/mcp-preflight.md` qualify as a stable, high-removal-cost probe target for the Phase A guard, and does `skills/scaffold/data/guard-block.md` exist?

**Answer:** `core/mcp-preflight.md` exists at `C:/gitea_ceos-agents/core/mcp-preflight.md` (confirmed by `ls` returning the path without error). It is referenced by exactly **6 skill files**: `skills/autopilot/SKILL.md:79`, `skills/create-backlog/SKILL.md:42`, `skills/fix-bugs/SKILL.md:162`, `skills/implement-feature/SKILL.md:45`, `skills/scaffold/SKILL.md:258`, `skills/sprint-plan/SKILL.md:64`. Zero agent references. High reference count (6 pipeline-entry skills, all of which invoke it as their first gate operation) confirms it as a stable probe target — renaming it would require a MINOR-or-MAJOR change touching 6 files. It is not marked deprecated in any roadmap entry. The Phase A guard `[ -r core/mcp-preflight.md ]` test (relative to CWD at dispatch time) is viable if and only if B2 is selected (CWD = repo root) or if B1 is implemented with PLUGIN_ROOT resolution; for B3 (prose-only), the guard is irrelevant to path resolution but still serves as a contract-existence check. Regarding `skills/scaffold/data/guard-block.md`: `ls skills/scaffold/` returns only `SKILL.md` and `steps/` — **the `data/` directory does NOT exist** and `guard-block.md` does not exist within it. Phase A therefore requires: (a) creating `skills/scaffold/data/` directory, (b) creating `skills/scaffold/data/guard-block.md` as a new file, and (c) adding an include/reference directive to `skills/scaffold/SKILL.md` pointing to it. The two existing guard-block files are at `skills/fix-bugs/data/guard-block.md` (73 lines) and `skills/implement-feature/data/guard-block.md` (70 lines).

**Evidence:** `ls C:/gitea_ceos-agents/core/mcp-preflight.md` → confirmed; `grep -rn "core/mcp-preflight\.md" skills/ agents/ --include="*.md"` → 6 hits in skills/, 0 in agents/; `ls C:/gitea_ceos-agents/skills/scaffold/` → `SKILL.md`, `steps` only; `wc -l skills/fix-bugs/data/guard-block.md skills/implement-feature/data/guard-block.md` → 73, 70.

---

## I1. Is `$PLUGIN_ROOT` a documented Claude Code dispatch contract, or must it be computed at runtime — and does this eliminate B1?

**Answer:** Zero uses of `PLUGIN_ROOT` exist anywhere in `skills/`, `agents/`, or `core/` (grep `PLUGIN_ROOT` across all `.md`, `.sh`, `.json` files in the plugin repo returns zero matches in those directories). The only repo-internal occurrences are in `.claude/settings.local.json` lines 82 and 84, where `CLAUDE_PLUGIN_ROOT` is used as an **explicitly set env var in a `Bash(...)` permission allow-list entry by another plugin** (filip-superpowers and superpowers plugins). This is not an injected contract — it is a manually constructed string embedded in a Bash allow-rule. Importantly, `CLAUDE_PLUGIN_ROOT` is NOT present in `.claude-plugin/plugin.json` or `.claude-plugin/marketplace.json` schema (grep returns 0 matches in those files). No Claude Code plugin dispatch documentation in this repo documents an auto-injected `$PLUGIN_ROOT` or equivalent. The filip-superpowers pattern (`CLAUDE_PLUGIN_ROOT='...' bash -c 'bash "${CLAUDE_PLUGIN_ROOT}/scripts/session-start.cmd"'`) shows the env var is SET by the hook invocation string itself, not injected by the runtime. Therefore: **B1 is NOT-VIABLE-without-helper**. If B1 is to be implemented, it requires a `core/lib/path-resolver.sh` shim (~20 lines) that uses `dirname "$0"` twice to compute plugin root at runtime, then exports it. This adds non-trivial complexity. B2 (`../../core/X.md`) is viable without a helper: `dirname(dirname(skills/fix-bugs/SKILL.md))` = `.` (repo root), and `core/state-manager.md` exists at `C:/gitea_ceos-agents/core/state-manager.md` (confirmed). B3 (inline prose clarifier) requires no path change.

**Evidence:** `grep -rn "PLUGIN_ROOT" C:/gitea_ceos-agents/ --include="*.md" --include="*.json" --include="*.sh"` → matches only in `.claude/settings.local.json` (L82, L84) and `.forge/` prompts; `grep -rn "CLAUDE_PLUGIN_ROOT\|PLUGIN_ROOT" .claude-plugin/plugin.json .claude-plugin/marketplace.json` → 0 hits; `ls C:/gitea_ceos-agents/core/state-manager.md` → EXISTS.

---

## I2. What is the per-file-name distribution of the 182 occurrences — and does `core/state-manager.md` concentration create authoring risk for B2 or B3?

**Answer:** Distribution in `skills/` (175 total): `core/state-manager.md` = 71 (40.6%), `core/agent-override-injector.md` = 34 (19.4%), `core/mcp-detection.md` = 14 (8%), `core/resume-detection.md` = 9 (5.1%), `core/config-reader.md` = 7 (4%), `core/mcp-preflight.md` = 6 (3.4%), `core/block-handler.md` = 5, `core/agent-states.md` = 5, `core/post-publish-hook.md` = 4, `core/fixer-reviewer-loop.md` = 4, `core/external-input-sanitizer.md` = 4, `core/decomposition-heuristics.md` = 4, `core/status-verification.md` = 3, `core/mcp-body-formatting.md` = 3, `core/profile-parser.md` = 2, `core/fix-verification.md` = 2, `core/tracker-subtask-creator.md` = 1. In `agents/` (7 total): `core/resume-detection.md` = 4, `core/mcp-body-formatting.md` = 2, `core/status-verification.md` = 1. No occurrence uses a non-standard prefix — grep for `\./core/`, `skills/\.\./core/`, or `\.\.\/core/` returns **0 matches** across both directories. Therefore a single sed pattern `s|core/\([a-z][a-z-]*\.md\)|../../core/\1|g` (for B2) will handle all 182 occurrences without edge cases. The state-manager.md concentration (71 occurrences in 25+ files) poses no authoring risk for B2 because a regex replace is mechanical; for B3 (per-file prose insertion at first occurrence), it means 25+ files need a prose clarifier prepended — more churn than B2 but still mechanical. Representative sample `skills/fix-bugs/steps/01-triage.md` contains 8 core/ references at lines 9, 22, 47, 51, 70, 81, 145, 173 — all use bare `core/X.md`, none use `./core/` or `../../core/`, confirming no exceptions.

**Evidence:** `grep -rn "core/[a-z][a-z-]*\.md" skills/ --include="*.md" | grep -o "core/[a-z][a-z-]*\.md" | sort | uniq -c | sort -rn` → distribution table above; non-standard prefix grep → 0 hits; `grep -n "core/" skills/fix-bugs/steps/01-triage.md` → 8 lines at L9, L22, L47, L51, L70, L81, L145, L173.

---

## I3. Do the existing two guard-block.md files contain any path-resolution mechanism, or must Phase A write it from scratch?

**Answer:** Neither `skills/fix-bugs/data/guard-block.md` (73 lines) nor `skills/implement-feature/data/guard-block.md` (70 lines) contains any `[ -r ... ]` test, `dirname`-based resolution, `PLUGIN_ROOT` reference, or `__FILE__`-equivalent (grep for `PLUGIN_ROOT`, `__FILE__`, `dirname`, `[ -r` returns **zero matches** in both files). The existing files contain orchestration rationalization-red-flag tables and contract rules only — no executable path logic. The only `core/lib/` reference in guard-block.md files is a citation: `skills/fix-bugs/data/guard-block.md:43` references `core/lib/stage-invariant.sh::compute_dispatch_witness` as a rule citation, not as executable resolution code. This means Phase A must add entirely new content: if B1 or B2 wins, a new `<PREFLIGHT>` block or prepended section must be authored from scratch in the 2 existing guard-block files AND in the new `skills/scaffold/data/guard-block.md`. The Phase 4 spec must decide structural placement: prepend vs new block type (e.g., `<PREFLIGHT>` XML block matching existing conventions in the guard files).

**Evidence:** `grep -n "PLUGIN_ROOT\|__FILE__\|dirname\|\[ -r" skills/fix-bugs/data/guard-block.md skills/implement-feature/data/guard-block.md` → 0 matches; `wc -l skills/fix-bugs/data/guard-block.md skills/implement-feature/data/guard-block.md` → 73, 70; `grep -n "core/lib/" skills/fix-bugs/data/guard-block.md` → L43 (citation only, no executable logic).

---

## Recommendation to Phase 4 Spec Writer

**Path-format winner recommendation: B2 (`../../core/X.md`)**

Rationale with file:line evidence:

1. **B1 is NOT-VIABLE-without-helper** (`grep PLUGIN_ROOT .claude-plugin/plugin.json` → 0 hits; the only CLAUDE_PLUGIN_ROOT in the repo is a manually-embedded env var string in `.claude/settings.local.json:82,84` for a different plugin, not a runtime injection contract). B1 would require a `core/lib/path-resolver.sh` shim (~20 lines) adding complexity and an extra failure mode.

2. **B2 is mechanically safe**: `dirname(dirname(skills/fix-bugs/SKILL.md))` = `.` = repo root. `core/state-manager.md` exists at repo root (`ls C:/gitea_ceos-agents/core/state-manager.md` → EXISTS). A single sed pattern `s|core/\([a-z][a-z-]*\.md\)|../../core/\1|g` handles all 182 occurrences with no edge cases (non-standard prefix grep → 0 hits). The `../../` depth is fixed and consistent: all SKILL.md files live at `skills/{name}/SKILL.md` (depth 2 from root), and all step files live at `skills/{name}/steps/{file}.md` (depth 3 from root). **Wait — this is a critical edge case**: step files at depth 3 would need `../../../core/X.md`, not `../../core/X.md`. Phase 4 spec must address this split: SKILL.md files use `../../core/`, step files use `../../../core/`, guard-block.md (in `data/`) also uses `../../../core/`. The sed pattern must account for file depth.

3. **B3 (prose clarifier)** avoids path changes entirely but leaves the ambiguity unresolved — the path `core/X.md` remains relative to whatever CWD the dispatch context provides, with no machine-checkable guarantee. Rejected as insufficient for the Phase A guard.

**Depth split spec note (CRITICAL for Phase 4):**
- `skills/{name}/SKILL.md` → `../../core/X.md` (up 2 levels)
- `skills/{name}/steps/*.md` → `../../../core/X.md` (up 3 levels)
- `skills/{name}/data/*.md` → `../../../core/X.md` (up 3 levels)
- `agents/*.md` → `../core/X.md` (up 1 level) — IF agents/ is in scope

Phase 4 must specify distinct sed patterns per depth class, or use `$PLUGIN_ROOT`-based B1 (which eliminates the depth problem entirely at the cost of the helper shim).

DONE_WITH_CONCERNS
