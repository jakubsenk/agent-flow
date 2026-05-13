# Research Answers -- v10.2.0 core/ Path Disambiguation

## C1. Exact enumeration of `core/<file>.md` references requiring rewrite — scope-lock for Phase B.

**Answer:** Live grep at commit 32f6f33 (v10.1.2) yields **182 lines containing `core/[a-z][a-z-]*\.md`** across **40 unique files** (37 in `skills/`, 3 in `agents/`). Because 3 of those 182 lines contain two distinct `core/*.md` patterns each (verified by `grep -P 'core/[a-z][a-z-]*\.md.*core/[a-z][a-z-]*\.md'` returning exactly 3 lines at `skills/implement-feature/SKILL.md:130`, `skills/implement-feature/steps/03-decomposition.md:91`, `skills/publish/SKILL.md:176`), the true **occurrence count is 185** (178 in skills/ + 7 in agents/). The roadmap estimate of 201 is an over-count regardless of scope. The 3 agent files (`agents/analyst.md`, `agents/fixer.md`, `agents/publisher.md`) contribute 7 occurrences (4× `core/resume-detection.md`, 2× `core/mcp-body-formatting.md`, 1× `core/status-verification.md`) and are in-scope for Phase B rewrites because they carry the same bare `core/<file>.md` pattern. None of the 182 lines already use `../../core/`, `${PLUGIN_ROOT}`, or any inline clarifier prose — the v10.1.2 baseline is 100% ambiguous.

**Evidence:**
- `grep -rn "core/[a-z][a-z-]*\.md" skills/ --include="*.md" | wc -l` = 175 lines
- `grep -rn "core/[a-z][a-z-]*\.md" agents/ --include="*.md" | wc -l` = 7 lines
- `grep -rn "core/[a-z][a-z-]*\.md" skills/ --include="*.md" | awk '{print $1}' | sort -u | wc -l` = 37 unique files
- `grep -rn "core/[a-z][a-z-]*\.md" agents/ --include="*.md" | awk '{print $1}' | sort -u` = agents/analyst.md, agents/fixer.md, agents/publisher.md
- True occurrence count via `grep -oE "core/[a-z][a-z-]*\.md"` per-match extraction: skills/ = 178, agents/ = 7, total = **185**

**Per-name occurrence distribution (true counts):**
```
71  core/state-manager.md          (38% of 185 total)
34  core/agent-override-injector.md (18%)
14  core/mcp-detection.md
13  core/resume-detection.md
 7  core/config-reader.md
 6  core/mcp-preflight.md
 5  core/mcp-body-formatting.md
 5  core/block-handler.md
 5  core/agent-states.md
 4  core/status-verification.md
 4  core/post-publish-hook.md
 4  core/fixer-reviewer-loop.md
 4  core/external-input-sanitizer.md
 4  core/decomposition-heuristics.md
 2  core/profile-parser.md
 2  core/fix-verification.md
 1  core/tracker-subtask-creator.md
```
Total = 185. `core/state-manager.md` + `core/agent-override-injector.md` account for 105/185 = **57%** of all rewrites.

**Phase B Scope Lock (machine-readable, derived from C1):**

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
skills/fix-bugs/steps/03-reproduce.md:100:core/state-manager.md
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

**Scope totals:** 182 lines, 185 occurrence instances (3 lines have dual patterns), 40 unique files (37 skills/ + 3 agents/).

---

## C2. Does `core/mcp-preflight.md` qualify as a stable, high-removal-cost probe target for the Phase A guard, and does `skills/scaffold/data/guard-block.md` exist?

**Answer:** `core/mcp-preflight.md` confirmed to exist at 47 lines (`ls core/mcp-preflight.md && wc -l core/mcp-preflight.md` = 47 core/mcp-preflight.md). It is referenced by exactly **6 skill files** and **0 agent files**: `skills/autopilot/SKILL.md:79`, `skills/create-backlog/SKILL.md:42`, `skills/fix-bugs/SKILL.md:162`, `skills/implement-feature/SKILL.md:45`, `skills/scaffold/SKILL.md:258`, `skills/sprint-plan/SKILL.md:64`. All 6 are pipeline-entry-point SKILL.md files — the highest-traffic orchestration layer. Renaming or removing `core/mcp-preflight.md` would require updating the 6 most critical SKILL.md files, confirming it is stable and high-removal-cost. It is not marked deprecated in any roadmap entry examined. It qualifies as the canonical Phase A guard probe target. Regarding the Phase A guard CWD resolution question: the existing guard-block.md files use bare `core/lib/stage-invariant.sh::compute_dispatch_witness` references (at `skills/fix-bugs/data/guard-block.md:43` and `skills/implement-feature/data/guard-block.md:40`), implying the CWD is expected to be the project root when these files are read — a `[ -r core/mcp-preflight.md ]` check would resolve correctly ONLY if CWD = project root at skill dispatch time. This is consistent with B2 semantics but needs a runtime CWD assertion in the Phase A guard. Regarding `skills/scaffold/data/guard-block.md`: this file does **NOT** exist. `ls skills/scaffold/` returns only `SKILL.md` and `steps/` — no `data/` directory exists. Furthermore, `skills/scaffold/SKILL.md:11-13` contains no `guard-block.md` include directive (grep for "guard-block" in scaffold/SKILL.md returns zero matches). Phase A therefore requires: (a) `mkdir skills/scaffold/data/`, (b) create `skills/scaffold/data/guard-block.md` (new file), (c) add a `Read` directive in `skills/scaffold/SKILL.md` matching the pattern at `skills/fix-bugs/SKILL.md:11` ("Use the Read tool to load `skills/scaffold/data/guard-block.md` BEFORE any other instruction").

**Evidence:**
- `core/mcp-preflight.md` existence: `ls core/mcp-preflight.md` = confirmed
- `core/mcp-preflight.md` line count: `wc -l core/mcp-preflight.md` = 47
- Reference count: `grep -rn "core/mcp-preflight\.md" skills/ agents/ --include="*.md"` = 6 hits, 0 agent hits
- `skills/scaffold/` directory listing: SKILL.md, steps/ (no data/ dir)
- `grep -n "guard-block" skills/scaffold/SKILL.md` = 0 matches
- Existing guard-block directive in fix-bugs: `skills/fix-bugs/SKILL.md:11`
- Existing guard-block directive in implement-feature: `skills/implement-feature/SKILL.md:11`

---

## I1. Is `$PLUGIN_ROOT` a documented Claude Code dispatch contract, or must it be computed at runtime — and does this eliminate B1?

**Answer:** `PLUGIN_ROOT` (in any form) does NOT appear in any `skills/`, `agents/`, or `core/*.md` file at v10.1.2 (live grep of entire repo returns zero matches in those directories). The only `PLUGIN_ROOT` / `CLAUDE_PLUGIN_ROOT` occurrences in the repo are in `.claude/settings.local.json` (lines 82 and 84), where the **filip-superpowers** and **superpowers** plugins inject `CLAUDE_PLUGIN_ROOT` as a Bash env var in hook commands — but this is set by those plugins themselves in hook invocation strings, not by Claude Code's dispatch runtime. The `plugin.json` at `.claude-plugin/plugin.json` contains no env-injection schema (keys: `name`, `description`, `version`, `author`, `repository`, `license` only). No `allowed-env` or `env-inject` field is present. There is no documented Claude Code runtime convention for injecting a plugin root path into skill dispatch context. **B1 is therefore NOT-VIABLE-without-helper**: if chosen, it requires a `core/lib/path-resolver.sh` shim (~20 lines) that computes plugin root via `dirname "$(dirname "$(realpath "$BASH_SOURCE")")"` or equivalent, and the guard-block.md must source this shim before any `[ -r ${PLUGIN_ROOT}/core/... ]` check. B2 (`../../core/X.md`) is viable: `dirname(dirname(skills/fix-bugs/SKILL.md)) = .` and `ls skills/fix-bugs/../../core/` confirms all 17 core contract files resolve correctly. B3 (inline prose) requires no file-system resolution but provides no machine-checkable guard.

**Evidence:**
- `grep -rn "PLUGIN_ROOT" skills/ agents/ core/ --include="*.md"` = 0 matches
- `.claude/settings.local.json:82-84`: `CLAUDE_PLUGIN_ROOT` used in hook Bash commands by OTHER plugins, not injected by runtime
- `.claude-plugin/plugin.json`: no env-injection fields (verified by Read)
- `ls skills/fix-bugs/../../core/` = 17 files confirmed (agent-override-injector.md through tracker-subtask-creator.md)

**B1 disposition: NOT-VIABLE-without-helper.** A `core/lib/path-resolver.sh` shim is required to use B1. B2 is immediately viable.

---

## I2. What is the per-file-name distribution of the 182 occurrences — and does `core/state-manager.md` concentration create authoring risk for B2 or B3?

**Answer:** Using `grep -oE "core/[a-z][a-z-]*\.md"` to count true occurrences (not just lines), `core/state-manager.md` = **71 occurrences** (38% of 185) and `core/agent-override-injector.md` = **34 occurrences** (18%), together comprising 57% of all rewrites. For B2, a global sed `s|core/\([a-z][a-z-]*\.md\)|../../core/\1|g` would need to match all 71 `core/state-manager.md` instances consistently. No edge-case prefixes were found: no occurrence uses `./core/`, `skills/../core/`, or any other non-standard prefix (confirmed by examining all 182 raw grep lines — every match is bare `core/<name>.md` with no path prefix). The 3 lines with dual patterns (`skills/implement-feature/SKILL.md:130`, `skills/implement-feature/steps/03-decomposition.md:91`, `skills/publish/SKILL.md:176`) each have two bare `core/<name>.md` patterns on the same line; a global sed replace handles both occurrences correctly. The B2 sed risk is not in the pattern but in prose context: lines like `skills/fix-bugs/steps/01-triage.md:145` contain `core/agent-states.md` inside a Bash comment (`# Fire pipeline-paused webhook (see core/agent-states.md Section 2)`). A global replace would correctly rewrite these too, which is the desired behavior. No authoring risk above normal mechanical replace care.

**Evidence:**
- `grep -Prn "core/[a-z][a-z-]*\.md" skills/ agents/ --include="*.md" | grep -oE "core/[a-z][a-z-]*\.md" | sort | uniq -c | sort -rn` = distribution table above
- `grep -Prn "core/[a-z][a-z-]*\.md.*core/[a-z][a-z-]*\.md" skills/ agents/ --include="*.md"` = 3 lines with dual patterns
- Zero matches for `\./core/` or `skills/\.\./core/` in the full 182-line output (visual scan of complete grep output)

---

## I3. Do the existing two guard-block.md files contain any path-resolution mechanism, or must Phase A write it from scratch?

**Answer:** Neither `skills/fix-bugs/data/guard-block.md` (73 lines) nor `skills/implement-feature/data/guard-block.md` (70 lines) contains any path-resolution mechanism. Confirmed by `grep -rn "PLUGIN_ROOT\|__FILE__\|dirname\|\[ -r" skills/fix-bugs/data/guard-block.md skills/implement-feature/data/guard-block.md` returning zero matches. Both files contain only: (1) `<MANDATORY-EXECUTION-GUARD>` XML block with THIN CONTROLLER instructions, (2) `<orchestration_contract>` block describing pre-dispatch state.json writes and witness computation (with a reference to `core/lib/stage-invariant.sh::compute_dispatch_witness` by name, not by file-system path check), (3) `<rationalization_red_flags>` table. The existing `core/lib/stage-invariant.sh::compute_dispatch_witness` reference at `skills/fix-bugs/data/guard-block.md:43` is prose-level only — it names the function, not a file-system read. Phase A must add path-resolution entirely from scratch. Structural placement recommendation: prepend a new `<PREFLIGHT>` XML block before `<MANDATORY-EXECUTION-GUARD>` in each guard-block.md (preserving all existing XML tag names and contracts as required by `skills/implement-feature/data/guard-block.md:5-6`).

**Evidence:**
- `grep -rn "PLUGIN_ROOT\|\[ -r\|dirname\|__FILE__" skills/fix-bugs/data/guard-block.md` = 0 matches (exit 1)
- `grep -rn "PLUGIN_ROOT\|\[ -r\|dirname\|__FILE__" skills/implement-feature/data/guard-block.md` = 0 matches (exit 1)
- `skills/fix-bugs/data/guard-block.md` line count: 73 lines (Read tool)
- `skills/implement-feature/data/guard-block.md` line count: 70 lines (Read tool)
- `skills/implement-feature/data/guard-block.md:5-6`: "Changes here are contract edits — Phase 7 implementation MUST preserve XML tag names, the THIN CONTROLLER identifier, the dispatched_at + dispatch_witness pre-dispatch write contract, and ALL red-flag rows."

---

## Recommendation to Phase 4 Spec Writer

**Path-format winner: B2 (`../../core/X.md`) with Phase A guard.**

Rationale:
1. **B1 is NOT-VIABLE-without-helper**: Zero evidence of any `PLUGIN_ROOT`-equivalent env var injected by Claude Code dispatch runtime (I1). Adding a `core/lib/path-resolver.sh` shim adds 20+ lines of Bash infrastructure with no precedent in this plugin.
2. **B2 is immediately viable**: `dirname(dirname(skills/fix-bugs/SKILL.md)) = project root` and `ls skills/fix-bugs/../../core/` confirms all 17 core contracts exist at the resolved path. The sed mechanical rewrite `s|core/\([a-z][a-z-]*\.md\)|../../core/\1|g` handles all 185 occurrences (including 3 dual-pattern lines) correctly with no edge-case prefixes.
3. **B3 (inline prose)** provides no machine-checkable guard and fails FC-B-1 (`grep -rn 'core/[a-z-]\+\.md' skills/ | grep -v -E '(\${PLUGIN_ROOT}|\.\./\.\./|...)'` must return 0). B3 alone is insufficient.
4. **Phase A guard** (new `<PREFLIGHT>` block in guard-block.md files) must check `[ -r ../../core/mcp-preflight.md ]` at runtime. `core/mcp-preflight.md` is confirmed as the canonical probe target (6 pipeline-critical references, 47 lines, not deprecated).
5. **Scope is 40 files** (37 skills/ + 3 agents/). The 3 agent files contribute only 7 occurrences but carry the same ambiguity and must be included in Phase B.
6. **scaffold/data/ directory and guard-block.md must be created** as net-new (not edit) — 2 edits (fix-bugs/SKILL.md, implement-feature/SKILL.md already have include directives) + 1 new include directive in scaffold/SKILL.md + 1 mkdir + 1 new file.

DONE
