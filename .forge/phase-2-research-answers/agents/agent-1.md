# Research Answers -- v10.2.0 core/ Path Disambiguation

_Agent: 1 of 3 | Angle: Primary Implementation Vector_

---

## C1. Exact enumeration of `core/<file>.md` references requiring rewrite — scope-lock for Phase B.

**Answer:** Live grep on v10.1.2 HEAD (commit 32f6f33) yields **182 occurrences across 40 unique files**: 175 occurrences in 37 `skills/` files + 7 occurrences in 3 `agents/` files (`agents/analyst.md`, `agents/fixer.md`, `agents/publisher.md`). Zero of the 182 occurrences already use a disambiguated form (`../../core/`, `${PLUGIN_ROOT}/core/`, `./core/`) — confirmed by `grep -rn "\.\./\.\./core\|PLUGIN_ROOT.*core\|\./core/" skills/ agents/ --include="*.md"` returning zero matches. The roadmap estimate of 201 is an over-count by 26 regardless of scope. The 3 agent files ARE in-scope for Phase B because they contain the same bare `core/<file>.md` pattern that the guard-block fix targets. Top-concentration filenames: `core/state-manager.md` = 71 (39%), `core/agent-override-injector.md` = 34 (19%), together 58% of all rewrites.

**Evidence:** `grep -rn "core/[a-z][a-z-]*\.md" skills/ agents/ --include="*.md" | wc -l` → 182; `grep -oP "^[^:]+" | sort -u | wc -l` → 40; zero pre-existing disambiguated forms confirmed by negative grep.

## Phase B Scope Lock (machine-readable, derived from C1)

```
agents/analyst.md:114:core/resume-detection.md
agents/analyst.md:307:core/resume-detection.md
agents/fixer.md:160:core/resume-detection.md
agents/fixer.md:66:core/resume-detection.md
agents/publisher.md:144:core/mcp-body-formatting.md
agents/publisher.md:65:core/mcp-body-formatting.md
agents/publisher.md:77:core/status-verification.md
skills/analyze-bug/SKILL.md:23:core/external-input-sanitizer.md
skills/autopilot/SKILL.md:37:core/config-reader.md
skills/autopilot/SKILL.md:420:core/post-publish-hook.md
skills/autopilot/SKILL.md:69:core/config-reader.md
skills/autopilot/SKILL.md:79:core/mcp-preflight.md
skills/create-backlog/SKILL.md:110:core/agent-override-injector.md
skills/create-backlog/SKILL.md:118:core/state-manager.md
skills/create-backlog/SKILL.md:17:core/config-reader.md
skills/create-backlog/SKILL.md:281:core/state-manager.md
skills/create-backlog/SKILL.md:316:core/state-manager.md
skills/create-backlog/SKILL.md:328:core/agent-override-injector.md
skills/create-backlog/SKILL.md:349:core/state-manager.md
skills/create-backlog/SKILL.md:377:core/agent-override-injector.md
skills/create-backlog/SKILL.md:42:core/mcp-preflight.md
skills/create-backlog/SKILL.md:88:core/state-manager.md
skills/create-backlog/SKILL.md:99:core/state-manager.md
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
skills/fix-bugs/steps/01-triage.md:145:core/agent-states.md
skills/fix-bugs/steps/01-triage.md:173:core/state-manager.md
skills/fix-bugs/steps/01-triage.md:22:core/status-verification.md
skills/fix-bugs/steps/01-triage.md:47:core/state-manager.md
skills/fix-bugs/steps/01-triage.md:51:core/agent-override-injector.md
skills/fix-bugs/steps/01-triage.md:70:core/external-input-sanitizer.md
skills/fix-bugs/steps/01-triage.md:81:core/state-manager.md
skills/fix-bugs/steps/01-triage.md:9:core/status-verification.md
skills/fix-bugs/steps/02-impact.md:106:core/agent-override-injector.md
skills/fix-bugs/steps/02-impact.md:118:core/decomposition-heuristics.md
skills/fix-bugs/steps/02-impact.md:125:core/state-manager.md
skills/fix-bugs/steps/02-impact.md:24:core/state-manager.md
skills/fix-bugs/steps/02-impact.md:28:core/agent-override-injector.md
skills/fix-bugs/steps/02-impact.md:56:core/state-manager.md
skills/fix-bugs/steps/02-impact.md:85:core/decomposition-heuristics.md
skills/fix-bugs/steps/02-impact.md:90:core/state-manager.md
skills/fix-bugs/steps/03-reproduce.md:100:core/state-manager.md
skills/fix-bugs/steps/03-reproduce.md:39:core/state-manager.md
skills/fix-bugs/steps/03-reproduce.md:43:core/agent-override-injector.md
skills/fix-bugs/steps/03-reproduce.md:75:core/state-manager.md
skills/fix-bugs/steps/04-fixer-reviewer-loop.md:138:core/agent-override-injector.md
skills/fix-bugs/steps/04-fixer-reviewer-loop.md:174:core/state-manager.md
skills/fix-bugs/steps/04-fixer-reviewer-loop.md:25:core/state-manager.md
skills/fix-bugs/steps/04-fixer-reviewer-loop.md:3:core/fixer-reviewer-loop.md
skills/fix-bugs/steps/04-fixer-reviewer-loop.md:34:core/agent-override-injector.md
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
skills/implement-feature/SKILL.md:110:core/resume-detection.md
skills/implement-feature/SKILL.md:122:core/agent-override-injector.md
skills/implement-feature/SKILL.md:130:core/block-handler.md
skills/implement-feature/SKILL.md:35:core/resume-detection.md
skills/implement-feature/SKILL.md:41:core/config-reader.md
skills/implement-feature/SKILL.md:45:core/mcp-preflight.md
skills/implement-feature/SKILL.md:53:core/mcp-body-formatting.md
skills/implement-feature/SKILL.md:65:core/profile-parser.md
skills/implement-feature/SKILL.md:69:core/resume-detection.md
skills/implement-feature/SKILL.md:71:core/resume-detection.md
skills/implement-feature/SKILL.md:77:core/state-manager.md
skills/implement-feature/SKILL.md:79:core/agent-states.md
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
skills/implement-feature/steps/02-architect.md:25:core/agent-override-injector.md
skills/implement-feature/steps/02-architect.md:40:core/state-manager.md
skills/implement-feature/steps/02-architect.md:6:core/state-manager.md
skills/implement-feature/steps/03-decomposition.md:105:core/state-manager.md
skills/implement-feature/steps/03-decomposition.md:11:core/decomposition-heuristics.md
skills/implement-feature/steps/03-decomposition.md:59:core/state-manager.md
skills/implement-feature/steps/03-decomposition.md:64:core/state-manager.md
skills/implement-feature/steps/03-decomposition.md:7:core/state-manager.md
skills/implement-feature/steps/03-decomposition.md:91:core/tracker-subtask-creator.md
skills/implement-feature/steps/04-fixer-reviewer-loop.md:127:core/state-manager.md
skills/implement-feature/steps/04-fixer-reviewer-loop.md:19:core/state-manager.md
skills/implement-feature/steps/04-fixer-reviewer-loop.md:39:core/agent-override-injector.md
skills/implement-feature/steps/04-fixer-reviewer-loop.md:52:core/state-manager.md
skills/implement-feature/steps/04-fixer-reviewer-loop.md:61:core/agent-states.md
skills/implement-feature/steps/04-fixer-reviewer-loop.md:79:core/agent-override-injector.md
skills/implement-feature/steps/04-fixer-reviewer-loop.md:85:core/fixer-reviewer-loop.md
skills/implement-feature/steps/04-fixer-reviewer-loop.md:91:core/state-manager.md
skills/implement-feature/steps/05-smoke.md:11:core/state-manager.md
skills/implement-feature/steps/05-smoke.md:24:core/state-manager.md
skills/implement-feature/steps/06-test.md:101:core/state-manager.md
skills/implement-feature/steps/06-test.md:114:core/state-manager.md
skills/implement-feature/steps/06-test.md:20:core/state-manager.md
skills/implement-feature/steps/06-test.md:24:core/state-manager.md
skills/implement-feature/steps/06-test.md:43:core/agent-override-injector.md
skills/implement-feature/steps/06-test.md:55:core/state-manager.md
skills/implement-feature/steps/06-test.md:71:core/state-manager.md
skills/implement-feature/steps/06-test.md:89:core/agent-override-injector.md
skills/implement-feature/steps/07-acceptance-gate.md:13:core/state-manager.md
skills/implement-feature/steps/07-acceptance-gate.md:32:core/agent-override-injector.md
skills/implement-feature/steps/07-acceptance-gate.md:46:core/state-manager.md
skills/implement-feature/steps/08-publish.md:111:core/state-manager.md
skills/implement-feature/steps/08-publish.md:128:core/post-publish-hook.md
skills/implement-feature/steps/08-publish.md:132:core/fix-verification.md
skills/implement-feature/steps/08-publish.md:22:core/state-manager.md
skills/implement-feature/steps/08-publish.md:41:core/agent-override-injector.md
skills/implement-feature/steps/08-publish.md:51:core/state-manager.md
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
skills/scaffold/steps/05-fixer-reviewer-loop.md:100:core/block-handler.md
skills/scaffold/steps/05-fixer-reviewer-loop.md:62:core/agent-states.md
skills/scaffold/steps/05-fixer-reviewer-loop.md:70:core/fixer-reviewer-loop.md
skills/scaffold/steps/07-spec-verify.md:52:core/status-verification.md
skills/scaffold/steps/08-final-report.md:11:core/state-manager.md
skills/setup-mcp/SKILL.md:100:core/mcp-detection.md
skills/setup-mcp/SKILL.md:299:core/mcp-detection.md
skills/setup-mcp/SKILL.md:309:core/mcp-detection.md
skills/setup-mcp/SKILL.md:33:core/mcp-detection.md
skills/setup-mcp/SKILL.md:64:core/mcp-detection.md
skills/setup-mcp/SKILL.md:98:core/mcp-detection.md
skills/sprint-plan/SKILL.md:122:core/agent-override-injector.md
skills/sprint-plan/SKILL.md:144:core/agent-override-injector.md
skills/sprint-plan/SKILL.md:170:core/state-manager.md
skills/sprint-plan/SKILL.md:220:core/state-manager.md
skills/sprint-plan/SKILL.md:27:core/config-reader.md
skills/sprint-plan/SKILL.md:270:core/state-manager.md
skills/sprint-plan/SKILL.md:289:core/state-manager.md
skills/sprint-plan/SKILL.md:318:core/agent-override-injector.md
skills/sprint-plan/SKILL.md:64:core/mcp-preflight.md
skills/sprint-plan/SKILL.md:79:core/state-manager.md
```

---

## C2. Does `core/mcp-preflight.md` qualify as a stable, high-removal-cost probe target for the Phase A guard, and does `skills/scaffold/data/guard-block.md` exist?

**Answer:** `core/mcp-preflight.md` exists (47 lines, confirmed via `ls -la core/mcp-preflight.md`), was added in v9.6.0 (CHANGELOG), and is referenced by exactly **6 skill SKILL.md files**: `skills/autopilot/SKILL.md:79`, `skills/create-backlog/SKILL.md:42`, `skills/fix-bugs/SKILL.md:162`, `skills/implement-feature/SKILL.md:45`, `skills/scaffold/SKILL.md:258`, `skills/sprint-plan/SKILL.md:64`. Zero agent references. Six pipeline-critical skill references means renaming it requires coordinated edits to 6 files — confirming it as a stable, high-removal-cost probe target. It is not marked deprecated in any roadmap entry. Regarding CWD resolution: if `[ -r core/mcp-preflight.md ]` is evaluated with CWD = repo root (the typical Claude Code working directory), it resolves correctly — `core/mcp-preflight.md` exists relative to repo root. The Phase 4 spec must specify that the guard's probe path is evaluated from repo root CWD, not relative to the skill file's on-disk location.

`skills/scaffold/data/guard-block.md` does **NOT** exist. `ls skills/scaffold/` returns only `SKILL.md` and `steps/` — no `data/` directory whatsoever (`ls skills/fix-bugs/data/` returns `guard-block.md`; `ls skills/implement-feature/data/` returns `guard-block.md`; scaffold has no equivalent). Furthermore, `skills/scaffold/SKILL.md` contains no reference to `guard-block.md` (grep returns zero matches). Phase A therefore requires: (a) `mkdir skills/scaffold/data/`, (b) create `skills/scaffold/data/guard-block.md` as a new file, AND (c) add a `Read and apply` directive to `skills/scaffold/SKILL.md:` that loads it (mirroring `skills/fix-bugs/SKILL.md:11` and `skills/implement-feature/SKILL.md:11`). The Phase 4 spec must state these as 3 discrete actions (not 2).

**Evidence:** `ls core/mcp-preflight.md` confirms existence; `grep -rn "core/mcp-preflight\.md" skills/ agents/` → 6 skill hits, 0 agent hits; `ls skills/scaffold/` → `SKILL.md steps/` only; `grep -n "guard-block" skills/scaffold/SKILL.md` → zero matches.

---

## I1. Is `$PLUGIN_ROOT` a documented Claude Code dispatch contract, or must it be computed at runtime — and does this eliminate B1?

**Answer:** `$PLUGIN_ROOT` (and `CLAUDE_PLUGIN_ROOT`) are **NOT** part of the ceos-agents plugin runtime contract. A broad grep across the entire repo (`grep -rn "PLUGIN_ROOT" . --include="*.md" --include="*.sh" --include="*.json"`) finds zero occurrences in `skills/`, `agents/`, or `core/` — the only hits are in `.forge/` brainstorm/plan prompts (design discussion only) and `.claude/settings.local.json` (a different plugin's `CLAUDE_PLUGIN_ROOT` injected by that plugin's own hook, not by the Claude Code platform). `plugin.json` (`C:/gitea_ceos-agents/.claude-plugin/plugin.json`) contains no `env`, `rootEnvVar`, or dispatch-context keys — it is a 7-key manifest with no env-injection schema. B1 is therefore **NOT-VIABLE-without-helper**: no platform-injected `$PLUGIN_ROOT` equivalent exists in ceos-agents dispatch context. Using B1 would require a `core/lib/path-resolver.sh` shim that computes plugin root from `dirname`-twice of a known anchor file — adding runtime complexity that B2 avoids entirely.

B2 (`../../core/X.md`) is VIABLE: Python path computation confirms that from `skills/fix-bugs/SKILL.md` (depth 2 from repo root), `../../core/mcp-preflight.md` resolves to `core/mcp-preflight.md` (repo root relative) which exists (`os.path.exists` → True). From step files at depth 3 (`skills/fix-bugs/steps/01-triage.md`), `../../../core/X.md` resolves identically to repo root `core/X.md` (True). **Note:** B2 requires different relative prefixes for SKILL.md files (`../../core/`) vs step files (`../../../core/`) — a single naive sed pattern `s|core/\([a-z][a-z-]*\.md\)|../../core/\1|g` applied uniformly would corrupt step files. The Phase 4 spec MUST specify two separate sed invocations or a depth-aware rewrite strategy.

**Evidence:** `grep -rn "PLUGIN_ROOT" . --include="*.md" --include="*.sh" --include="*.json"` → zero hits in skills/agents/core; `.claude-plugin/plugin.json` has no env schema; Python `os.path.exists("core/mcp-preflight.md")` from `dirname(dirname("skills/fix-bugs/SKILL.md"))` → True; from `dirname(dirname(dirname("skills/fix-bugs/steps/01-triage.md")))` → True.

---

## I2. What is the per-file-name distribution of the 182 occurrences — and does `core/state-manager.md` concentration create authoring risk for B2 or B3?

**Answer:** Combined skills/ + agents/ distribution (total 182): `core/state-manager.md` = **71 occurrences** (39%); `core/agent-override-injector.md` = **34** (19%); `core/mcp-detection.md` = **14** (8%); `core/resume-detection.md` = **13** (7%); `core/config-reader.md` = **7** (4%); `core/mcp-preflight.md` = **6** (3%); `core/mcp-body-formatting.md` = **5** (3%); `core/block-handler.md` = **5** (3%); `core/agent-states.md` = **5** (3%); `core/status-verification.md` = **4** (2%); `core/post-publish-hook.md` = **4**; `core/fixer-reviewer-loop.md` = **4**; `core/external-input-sanitizer.md` = **4**; `core/decomposition-heuristics.md` = **4**; `core/profile-parser.md` = **2**; `core/fix-verification.md` = **2**; `core/tracker-subtask-creator.md` = **1**. Two names alone (state-manager + agent-override-injector) account for 105 of 182 rewrites (58%).

For B2 authoring risk: no occurrence uses a non-standard prefix (`./core/`, `skills/../core/`) — confirmed by `grep -rn "\.\./\.\./core\|PLUGIN_ROOT.*core\|\./core/" skills/ agents/ --include="*.md"` returning zero matches. All 182 are bare `core/<name>.md`. However, as noted in I1, the B2 sed pattern depth-mismatch (SKILL.md = `../../`, step files = `../../../`, data/ files = `../../../`) is the primary authoring risk — not pattern variation. A representative sample (`skills/fix-bugs/steps/01-triage.md`) has 8 occurrences all at the bare `core/X.md` form — no edge-case prefix exists anywhere in the enumeration.

**Evidence:** `grep -rn "core/[a-z][a-z-]*\.md" skills/ agents/ --include="*.md" | grep -oP "core/[a-z][a-z-]*\.md" | sort | uniq -c | sort -rn` — full distribution above; `grep -rn "\.\./\.\./core" skills/ agents/` → zero matches.

---

## I3. Do the existing two guard-block.md files contain any path-resolution mechanism, or must Phase A write it from scratch?

**Answer:** Neither `skills/fix-bugs/data/guard-block.md` (confirmed to exist) nor `skills/implement-feature/data/guard-block.md` contains any `[ -r ... ]` test, `dirname`-based resolution, or `PLUGIN_ROOT` reference. `grep -rn "PLUGIN_ROOT\|dirname\|__FILE__\|\[ -r" skills/fix-bugs/data/guard-block.md skills/implement-feature/data/guard-block.md` returns zero matches. The existing files contain orchestration contracts (THIN CONTROLLER identifier, dispatch invariants, rationalization-red-flag tables, XML-tagged sections) — zero path-resolution logic. Phase A must add entirely new prose to introduce the CWD-relative probe. The structural placement question (prepend section vs new `<PREFLIGHT>` XML block) is unresolved by existing content — the existing files use `<THIN_CONTROLLER_CONTRACT>` and `<RATIONALIZATION_RED_FLAGS>` XML tag conventions; Phase 4 spec should add a `<PREFLIGHT>` block following that convention, prepended before `<THIN_CONTROLLER_CONTRACT>` so it fires first. This is a spec-writer judgment call; the evidence shows the existing structure does not constrain the placement.

**Evidence:** `head -5 skills/fix-bugs/data/guard-block.md` → `# Mandatory Execution Guard — /fix-bugs` with XML tag conventions; `grep -rn "PLUGIN_ROOT\|dirname\|\[ -r" skills/fix-bugs/data/guard-block.md skills/implement-feature/data/guard-block.md` → zero matches; `skills/fix-bugs/SKILL.md:11` and `skills/implement-feature/SKILL.md:11` show how guard-block.md is loaded (`Read tool` directive).

---

## Recommendation to Phase 4 Spec Writer

**Path-format winner: B2 (`../../core/X.md` / `../../../core/X.md` depth-adjusted)**

Rationale:
- B1 is **eliminated**: `$PLUGIN_ROOT` is not injected by the Claude Code platform for this plugin (zero evidence in plugin.json, skills/, agents/, core/; only `CLAUDE_PLUGIN_ROOT` appears in a different plugin's hook inside `.claude/settings.local.json`). A helper shim would add runtime complexity without platform guarantee.
- B2 is **viable and verifiable**: Python path computation confirms `../../core/mcp-preflight.md` from any SKILL.md depth-2 file resolves to existing `core/mcp-preflight.md`; `../../../core/X.md` from any steps/ depth-3 file resolves identically. `os.path.exists()` → True for both.
- B2 **risk to flag in spec**: Two distinct relative prefixes required — `../../core/` for `skills/*/SKILL.md` and `skills/*/data/*.md` (depth 2 from repo root), `../../../core/` for `skills/*/steps/*.md` and `agents/*.md` (depth 3 from repo root, or 2 from skills/ root). A naive single-pass sed will corrupt one class. Spec must mandate separate sed invocations per depth, or an explicit file-class list.
- B3 (inline clarifier prose) is NOT recommended as primary approach — 182 occurrences of inline prose changes is higher editorial risk than a mechanical path prefix rewrite, and provides no runtime verifiability.

DONE
