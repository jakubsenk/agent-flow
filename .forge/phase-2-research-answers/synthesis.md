# Phase 2 Synthesis — v10.2.0 core/ Path Disambiguation
# Research Answers (Synthesis Agent)

**Forge run:** `forge-2026-05-13-001`
**Base agent:** Agent 2 (score 23/25)
**Std dev:** 0.82 (score-based selection; threshold 1.5 not exceeded)
**Verified by synthesis agent:** 2026-05-13

---

## C1. Exact enumeration of `core/<file>.md` references requiring rewrite — scope-lock for Phase B.

**Answer:** Live grep on v10.1.2 HEAD (commit 32f6f33) yields:

- **182 lines** containing `core/[a-z][a-z-]*\.md` across **40 unique files** (37 in `skills/`, 3 in `agents/`)
- **185 true occurrences** (3 lines each contain two distinct `core/*.md` patterns)

Both numbers were independently verified by the synthesis agent:
- `grep -rn 'core/[a-z][a-z-]*\.md' skills/ agents/ --include='*.md' | wc -l` → **182** (line count)
- `grep -roh 'core/[a-z][a-z-]*\.md' skills/ agents/ --include='*.md' | wc -l` → **185** (occurrence count via `-o`)

The 3 dual-pattern lines (confirmed by synthesis agent grep):
- `skills/implement-feature/SKILL.md:130` — `core/block-handler.md` and `core/state-manager.md`
- `skills/implement-feature/steps/03-decomposition.md:91` — `core/tracker-subtask-creator.md` and `core/mcp-body-formatting.md`
- `skills/publish/SKILL.md:176` — two references to `core/mcp-detection.md`

**Use 182 as the line count** (number of grep output lines; controls sed rewrite operations). **Use 185 as the occurrence count** (number of actual pattern instances; controls regex substitution completeness). The roadmap estimate of 201 is an over-count by at least 16.

**File breakdown:** 175 lines in 37 `skills/` files + 7 lines in 3 `agents/` files. The 3 agent files (`agents/analyst.md`, `agents/fixer.md`, `agents/publisher.md`) are **in-scope for Phase B** — they carry the same bare `core/<file>.md` pattern and the same disambiguation risk.

Zero occurrences use any non-standard prefix (`./core/`, `../../core/`, `${PLUGIN_ROOT}/core/`). The v10.1.2 baseline is 100% bare `core/<name>.md`.

**Evidence:**
- Synthesis agent: `grep -rn 'core/[a-z][a-z-]*\.md' skills/ agents/ --include='*.md' | wc -l` → 182
- Synthesis agent: `grep -roh 'core/[a-z][a-z-]*\.md' skills/ agents/ --include='*.md' | wc -l` → 185
- Synthesis agent: `grep -Prn 'core/[a-z][a-z-]*\.md.*core/[a-z][a-z-]*\.md' skills/ agents/ --include='*.md'` → 3 lines (confirmed above)
- Agent 2 (base): `grep -oE "core/[a-z][a-z-]*\.md"` per-match extraction: skills/ = 178, agents/ = 7, total = 185

**Per-name occurrence distribution (true counts, 185 total):**

```
71  core/state-manager.md           (38% of 185)
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

`core/state-manager.md` + `core/agent-override-injector.md` = 105/185 = **57%** of all rewrites.

**Phase B Scope Lock (machine-readable, 182 lines / 185 occurrences):**

```
agents/analyst.md:114:core/resume-detection.md
agents/analyst.md:307:core/resume-detection.md
agents/fixer.md:66:core/resume-detection.md
agents/fixer.md:160:core/resume-detection.md
agents/publisher.md:65:core/mcp-body-formatting.md
agents/publisher.md:77:core/status-verification.md
agents/publisher.md:144:core/mcp-body-formatting.md
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
skills/implement-feature/SKILL.md:130:core/block-handler.md          [dual-pattern line]
skills/implement-feature/SKILL.md:130:core/state-manager.md           [dual-pattern line]
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
skills/implement-feature/steps/03-decomposition.md:91:core/tracker-subtask-creator.md  [dual-pattern line]
skills/implement-feature/steps/03-decomposition.md:91:core/mcp-body-formatting.md      [dual-pattern line]
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
skills/publish/SKILL.md:176:core/mcp-detection.md                [dual-pattern line]
skills/publish/SKILL.md:176:core/mcp-detection.md                [dual-pattern line — same name twice]
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
```

---

## C2. Does `core/mcp-preflight.md` qualify as a stable, high-removal-cost probe target for the Phase A guard, and does `skills/scaffold/data/guard-block.md` exist?

**Answer:** `core/mcp-preflight.md` **qualifies** as the canonical Phase A guard probe target. Confirmed to exist (47 lines). Referenced by exactly **6 skill SKILL.md files** and **0 agent files**:
- `skills/autopilot/SKILL.md:79`
- `skills/create-backlog/SKILL.md:42`
- `skills/fix-bugs/SKILL.md:162`
- `skills/implement-feature/SKILL.md:45`
- `skills/scaffold/SKILL.md:258`
- `skills/sprint-plan/SKILL.md:64`

All 6 are pipeline-entry-point files — the highest-traffic orchestration layer. Renaming or removing `core/mcp-preflight.md` requires updating all 6 critical SKILL.md files, making it stable and high-removal-cost. It is not marked deprecated in any roadmap entry. The Phase A guard `[ -r core/mcp-preflight.md ]` check must be evaluated from CWD = project root (the standard Claude Code working directory). If CWD is repo root, the path resolves correctly without any path prefix.

`skills/scaffold/data/guard-block.md` does **NOT** exist. `ls skills/scaffold/` returns only `SKILL.md` and `steps/` — no `data/` directory exists. `grep -n "guard-block" skills/scaffold/SKILL.md` returns zero matches. Phase A therefore requires **3 discrete actions**:
1. `mkdir skills/scaffold/data/` (create the directory)
2. Create `skills/scaffold/data/guard-block.md` as a new file (content to be authored from scratch, mirroring the existing guard-block structure)
3. Add a `Read tool` directive to `skills/scaffold/SKILL.md` to load the guard-block before any other instruction — matching the existing pattern at `skills/fix-bugs/SKILL.md:11` and `skills/implement-feature/SKILL.md:11`

**Evidence:**
- `ls core/mcp-preflight.md` — confirmed existence
- `wc -l core/mcp-preflight.md` — 47 lines
- `grep -rn "core/mcp-preflight\.md" skills/ agents/ --include="*.md"` — 6 skill hits, 0 agent hits
- `ls skills/scaffold/` — `SKILL.md`, `steps/` only (no `data/`)
- `grep -n "guard-block" skills/scaffold/SKILL.md` — 0 matches
- Existing guard directives: `skills/fix-bugs/SKILL.md:11`, `skills/implement-feature/SKILL.md:11`

---

## I1. Is `$PLUGIN_ROOT` a documented Claude Code dispatch contract, or must it be computed at runtime — and does this eliminate B1?

**Answer:** `PLUGIN_ROOT` (in any form) does **NOT** appear in `skills/`, `agents/`, or `core/` at v10.1.2. The only occurrences in the entire repo are:
- `.claude/settings.local.json:82,84` — `CLAUDE_PLUGIN_ROOT` manually embedded by the **filip-superpowers** and **superpowers** plugins in their own hook invocation strings; this is not injected by Claude Code's dispatch runtime
- `.forge/` brainstorm/plan prompts — design discussion only

`.claude-plugin/plugin.json` contains no env-injection schema (keys: `name`, `description`, `version`, `author`, `repository`, `license` only — no `env`, `rootEnvVar`, or dispatch-context fields).

**B1 disposition: NOT-VIABLE-without-helper.** No platform-injected `$PLUGIN_ROOT` equivalent exists in ceos-agents dispatch context. Implementing B1 would require a `core/lib/path-resolver.sh` shim (~20 lines) adding runtime complexity, a new failure mode, and no platform guarantee.

**B2 (`../../core/X.md`) is VIABLE** without any helper: `dirname(dirname(skills/fix-bugs/SKILL.md))` = repo root, and `ls skills/fix-bugs/../../core/` confirms all 17 core contract files resolve correctly. See I1 depth-split note in the B2 spec mandate below.

**Evidence:**
- `grep -rn "PLUGIN_ROOT" skills/ agents/ core/ --include="*.md"` — 0 matches
- `.claude/settings.local.json:82-84` — `CLAUDE_PLUGIN_ROOT` set by OTHER plugins, not runtime-injected
- `.claude-plugin/plugin.json` — no env-injection fields
- `ls skills/fix-bugs/../../core/` — 17 files confirmed

---

## I2. What is the per-file-name distribution of the 182 occurrences — and does `core/state-manager.md` concentration create authoring risk for B2 or B3?

**Answer:** See per-name distribution table in C1 above (185 true occurrences). `core/state-manager.md` (71) + `core/agent-override-injector.md` (34) = 105/185 = 57% of rewrites.

For B2 authoring risk: no occurrence uses a non-standard prefix. All 185 instances are bare `core/<name>.md` (confirmed by `grep -rn "\./core/\|skills/\.\./core/\|\.\./core/" skills/ agents/ --include="*.md"` returning 0 matches). A global sed substitution handles all occurrences mechanically. The 3 dual-pattern lines (two `core/*.md` patterns on one line) are correctly handled by a global (`g`) flag sed substitution.

No authoring risk from pattern variation. The primary authoring risk is **B2 depth-split** — see the mandatory spec note below.

**Evidence:**
- `grep -roh "core/[a-z][a-z-]*\.md" skills/ agents/ --include="*.md" | sort | uniq -c | sort -rn` — full distribution
- Non-standard prefix grep — 0 matches confirmed
- Dual-pattern verification: 3 lines confirmed via synthesis agent grep

---

## I3. Do the existing two guard-block.md files contain any path-resolution mechanism, or must Phase A write it from scratch?

**Answer:** Neither `skills/fix-bugs/data/guard-block.md` (73 lines) nor `skills/implement-feature/data/guard-block.md` (70 lines) contains any path-resolution mechanism. `grep -rn "PLUGIN_ROOT\|__FILE__\|dirname\|\[ -r" skills/fix-bugs/data/guard-block.md skills/implement-feature/data/guard-block.md` returns **zero matches** in both files.

Both files contain: `<MANDATORY-EXECUTION-GUARD>` XML block with THIN CONTROLLER instructions, `<orchestration_contract>` block describing pre-dispatch state.json writes and witness computation (with a citation reference to `core/lib/stage-invariant.sh::compute_dispatch_witness` by name, not as a file-system path check), and `<rationalization_red_flags>` table. Zero executable path logic.

Phase A must add path-resolution **entirely from scratch**. Structural placement: prepend a new `<PREFLIGHT>` XML block **before** `<MANDATORY-EXECUTION-GUARD>` in each guard-block.md, following the existing XML tag naming convention. The `skills/implement-feature/data/guard-block.md:5-6` explicitly states "Changes here are contract edits — Phase 7 implementation MUST preserve XML tag names, the THIN CONTROLLER identifier, the dispatched_at + dispatch_witness pre-dispatch write contract, and ALL red-flag rows." The new `<PREFLIGHT>` block is additive and does not conflict with this constraint.

**Evidence:**
- `grep -rn "PLUGIN_ROOT\|\[ -r\|dirname\|__FILE__" skills/fix-bugs/data/guard-block.md skills/implement-feature/data/guard-block.md` — 0 matches
- Line counts: 73 (fix-bugs), 70 (implement-feature)
- `skills/fix-bugs/data/guard-block.md:43` — prose citation of `core/lib/stage-invariant.sh::compute_dispatch_witness`, not executable resolution
- XML tag conventions: `<MANDATORY-EXECUTION-GUARD>`, `<orchestration_contract>`, `<rationalization_red_flags>`

---

## B2 Depth-Split Mandate (CRITICAL — merged from Agent 3, absent in base Agent 2)

**This is a mandatory spec note for the Phase 4 spec writer.** B2 requires different relative prefixes per file depth class. A single naive sed pattern `s|core/\([a-z][a-z-]*\.md\)|../../core/\1|g` applied uniformly to all 40 files will **corrupt** depth-3 and depth-1 files.

**Depth classes and required prefixes:**

| Depth class | Example files | Required prefix | Relative path |
|---|---|---|---|
| Depth 2 from repo root | `skills/{name}/SKILL.md` | `../../core/` | Up 2 levels |
| Depth 3 from repo root | `skills/{name}/steps/*.md` | `../../../core/` | Up 3 levels |
| Depth 3 from repo root | `skills/{name}/data/*.md` | `../../../core/` | Up 3 levels |
| Depth 1 from repo root | `agents/*.md` | `../core/` | Up 1 level |

**Phase 4 spec MUST mandate 3 separate sed invocations** (or an explicit file-class list), one per depth class. Alternatively, Phase 4 may accept B1 (PLUGIN_ROOT helper shim) which eliminates the depth problem entirely at the cost of a `core/lib/path-resolver.sh` shim — but B1 is NOT-VIABLE-without-helper per I1.

All three research agents cited the SKILL.md vs steps/ split. Agent 3 uniquely and explicitly enumerated all 4 depth classes including `agents/*.md` (depth 1, `../core/`). This finding is merged from Agent 3 into the synthesis as it is absent from Agent 2's base output.

---

## Synthesis Notes

### Scores

| Agent | C1 Completeness | B1 Rigor | scaffold/data Precision | Depth-Split | Citation Discipline | Total |
|---|---|---|---|---|---|---|
| Agent 1 | 3 | 5 | 5 | 4 | 5 | 22/25 |
| Agent 2 | 5 | 5 | 5 | 3 | 5 | **23/25** |
| Agent 3 | 3 | 5 | 4 | 5 | 4 | 21/25 |

**Std dev:** sqrt(((22-22)^2 + (23-22)^2 + (21-22)^2) / 3) = sqrt(2/3) ≈ **0.82** — below 1.5 threshold; score-based selection applies.

**Base agent:** Agent 2

### Contributions Merged

- **From Agent 1:** Structural recommendation for scaffold guard-block.md placement (`<PREFLIGHT>` block before `<THIN_CONTROLLER_CONTRACT>`); explicit note on B3 as NOT recommended as primary approach.
- **From Agent 3:** Complete 4-class depth-split enumeration including `agents/*.md` (depth 1, `../core/`). This is the critical unique contribution absent from Agent 2. Also: explicit "DONE_WITH_CONCERNS" flag flagging the depth split as a critical risk — elevated to a dedicated top-level section in this synthesis.

### Contradictions Resolved

**Line count vs occurrence count discrepancy:**
- Agent 1 and Agent 3 reported "182 occurrences" — conflating line count with occurrence count.
- Agent 2 correctly reported 182 lines / 185 true occurrences via `grep -oE`.
- Synthesis agent independently verified: line count = 182 (confirmed), occurrence count = 185 (confirmed), dual-pattern lines = 3 (confirmed with actual content).
- Resolution: **182 = line count** (correct for sed line-mode operations); **185 = occurrence count** (correct for regex substitution completeness verification). Both numbers are valid — they measure different things. Use 182 for "how many grep output lines to expect"; use 185 for "how many pattern rewrites to verify."

**agents/ depth in B2 scope:**
- Agent 1 and Agent 2 stated B2 requires `../../core/` for SKILL.md and `../../../core/` for step files, but neither fully resolved the `agents/*.md` case.
- Agent 3 explicitly stated `agents/*.md` → `../core/` (up 1 level from repo root, agents/ is 1 level deep).
- Synthesis confirms: agents/ files are at depth 1 from repo root, so `../core/X.md` is the correct relative prefix for that class.

**scaffold/data/ action count:**
- All three agents agreed on 3 actions (mkdir + new file + SKILL.md include directive). No contradiction. Agent 2's phrasing "2 edits + 1 new include directive + 1 mkdir + 1 new file" (5 actions) in its recommendation section was a miscounting of the editorial operations, not the logical Phase A tasks; the 3-task framing (directory creation, file creation, SKILL.md directive) is canonical.

### Disagreement Flags

None. All three agents converged on: B1 = NOT-VIABLE-without-helper, B2 = VIABLE, B3 = insufficient alone, scaffold/data/ does not exist, guard-block.md has no existing path-resolution logic. The only material disagreement (line vs occurrence count) is fully resolved above.

---

**STATUS: SYNTHESIS_COMPLETE**
