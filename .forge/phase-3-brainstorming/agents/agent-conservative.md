# Brainstorm -- v10.2.0 Phase B Path-Format -- Persona: CONSERVATIVE

**Persona:** Senior Plugin Reliability Engineer, 15+ years. Default-deny. Mechanism-light wins ties. The plugin is markdown-only with no build system (CLAUDE.md L17); adding executable resolver shims is moving in the wrong direction.

**Ground-truth inputs:** Phase 2 final answers (B1 NOT-VIABLE-without-helper, B2 has 4-class depth-split risk, `skills/scaffold/data/guard-block.md` does NOT exist, baseline is 100% bare `core/<name>.md`).

---

## B1 Analysis (${PLUGIN_ROOT} + resolver helper in `core/lib/`)

**Strengths:**

- **Depth-blind rewrite.** A single global sed `s|core/\([a-z][a-z-]*\.md\)|${PLUGIN_ROOT}/core/\1|g` works uniformly across all 40 files (agents/ depth 1, SKILL.md depth 2, steps/+data/ depth 3). No per-class file lists. Eliminates the entire class of bug surfaced in Phase 2's B2 Depth-Split Mandate.
- **Self-locating tokens.** `${PLUGIN_ROOT}/core/state-manager.md` is unambiguous on visual inspection. A future reviewer cannot mis-read it as "sibling of `skills/fix-bugs/`" the way bare `core/state-manager.md` was misread for BIFITO-4293 (roadmap L1491).
- **Composability with existing v10.0.0 contract.** A `core/lib/path-resolver.sh` shim fits naturally next to the existing `core/lib/stage-invariant.sh` (134 lines, MEMORY.md). The reliability sub-team already accepts a `core/lib/` directory as the place for orchestrator-helper Bash.
- **Future-proof against CWD-drift.** If Claude Code introduces a future dispatch CWD that is NOT repo root (e.g., per-skill subprocess dirs), B1 is the only option that survives without re-flowing every file.

**Weaknesses:**

- **NOT-VIABLE-without-helper (Phase 2 I1, dispositive).** Live grep on v10.1.2 HEAD finds zero `PLUGIN_ROOT` usages in `skills/`, `agents/`, `core/`. `.claude-plugin/plugin.json` has no env-injection schema. Claude Code does not inject `$PLUGIN_ROOT`. The variable is unbound at SKILL.md read time, so without a shim Claude would Read `${PLUGIN_ROOT}/core/state-manager.md` as a literal path with the `${PLUGIN_ROOT}` token present and fail.
- **The shim is itself executable code.** A 20-line Bash helper is mechanism. Markdown plugins should not need Bash to resolve a sibling directory. This is the v10.0.0 reliability lib mindset bleeding into a place where it does not belong; the path resolution does not need atomic witness semantics.
- **New failure surface.** The shim can fail (PATH issues on Windows-WSL, locale, shebang on bare Alpine, exit-on-error trap from caller). v10.0.0 introduced `core/lib/stage-invariant.sh` only because dispatch witness genuinely needs atomic SHA-256 computation. Path resolution does not justify the same machinery cost.
- **185 sed rewrites + 20-line shim + new orchestrator boot step** is more code than B2's 3-class sed + B3's prose-only change. The Phase 2 answer puts Phase B at 50-100 net lines; the shim alone consumes 20% of that budget.
- **Token-leak risk in prose.** Many of the 185 occurrences sit inside human prose ("see `core/state-manager.md` for state schema"). Rewriting these to `${PLUGIN_ROOT}/core/state-manager.md` makes the prose noticeably uglier across 9 SKILL.md, 28 step files, and 2 guard-block.md. Documentation quality regression.

**Concrete example (file:line):**

`skills/fix-bugs/SKILL.md:162` currently reads:

```
| 00   | (orchestrator) MCP pre-flight + state init | Follow `core/mcp-preflight.md`, validate issue_id, ...
```

B1 rewrites to:

```
| 00   | (orchestrator) MCP pre-flight + state init | Follow `${PLUGIN_ROOT}/core/mcp-preflight.md`, validate issue_id, ...
```

The orchestrator must (a) source `core/lib/path-resolver.sh` from the guard-block, (b) export `PLUGIN_ROOT` BEFORE the first Read tool call, and (c) trust that Claude expands the token inside backticks when constructing the Read path. The last is unverified Claude behavior — Claude may treat backticked markdown as literal display text and NOT expand the shell token. This is the dispositive failure: the v10.0.0 dispatch_witness mechanism uses Bash because state.json writes go through Bash; path Reads go through the Read tool, which does NOT shell-expand its argument.

**Phase A guard interaction:**

If the resolver shim fails to set `PLUGIN_ROOT`, the Phase A `[ -r core/mcp-preflight.md ]` probe (which is itself a bare relative path per Phase 2 C2 — runs from repo-root CWD) might still pass. That creates a **dangerous gap**: Phase A green-lights, but every downstream Read of `${PLUGIN_ROOT}/core/X.md` 404s with `PLUGIN_ROOT` as literal text. The guard does not validate B1's correctness end-to-end. To close the gap, Phase A would need to additionally verify `[ -n "$PLUGIN_ROOT" ] && [ -r "$PLUGIN_ROOT/core/mcp-preflight.md" ]` — extra mechanism cost on top of the shim.

**Phase C scenario coverage:**

`tests/scenarios/v10-skill-from-external-cwd.sh` from `/tmp/external-project` CWD does exercise B1's failure mode IF the scenario invokes Read on a `${PLUGIN_ROOT}/core/X.md` path AND if the Read tool's lack of shell-expansion is what causes the failure. But this is a Claude Code runtime behavior, not a Bash test. A shell-based harness scenario cannot easily simulate the Read tool's argument-parsing rules. Phase C coverage is **partial at best** for B1 — the actual failure mode (Read-as-literal-text) lives outside Bash scope.

**5-year forward-compat:**

The strongest B1 argument. If next 10 features add e.g. `core/spec-validator.md`, `core/decomposition-graph.md`, etc., B1's rewrite rule never needs to change — same `${PLUGIN_ROOT}/core/<name>.md` shape for every new contract. B2 requires depth-aware authoring forever. B3 requires authors to remember to inline-clarify on first occurrence of any new core/ ref. B1 wins forward-compat on paper. But this assumes the shim survives 5 years of Claude Code dispatch changes — and Claude Code's plugin API is still evolving (v10.0.0 reliability contract was added 1 week ago). Betting on Bash machinery in a markdown plugin is a 5-year bet against the wrong axis.

---

## B2 Analysis (`../../core/` relative)

**Strengths:**

- **No new mechanism.** Pure prose rewrite. Composes with v10.0.0 reliability contract without touching `core/lib/`. CLAUDE.md L17 "No build system, no dependencies" stays true.
- **Empirically VIABLE per Phase 2 I1.** `ls skills/fix-bugs/../../core/` confirms all 17 core contract files resolve correctly when CWD is repo root. The Read tool follows OS-level relative path semantics, which are well-defined.
- **Unambiguous on visual inspection.** `../../core/state-manager.md` cannot be mis-read as `skills/fix-bugs/core/state-manager.md` (which is what BIFITO-4293 surfaced). The `../../` prefix forces the reader to count directory levels.
- **Phase C scenario gives directly executable verification.** The external-CWD test can `cd /tmp/external-project && ls $PLUGIN_DIR/skills/fix-bugs/../../core/mcp-preflight.md` — pure POSIX file-system test, no Claude Code runtime semantics required.

**Weaknesses:**

- **B2 Depth-Split Mandate (Phase 2 critical finding).** A single sed pattern does NOT work. The 40 affected files split into 4 depth classes (`agents/*.md` → `../core/`, `skills/{name}/SKILL.md` → `../../core/`, `skills/{name}/steps/*.md` → `../../../core/`, `skills/{name}/data/*.md` → `../../../core/`). Phase 4 spec must mandate 3 separate sed invocations (or an explicit file-class list). A naive global sed corrupts depth-3 and depth-1 files silently.
- **Authoring trap for future contributors.** New step file at depth 4 (e.g., `skills/fix-bugs/steps/04-fixer-reviewer-loop/subloop.md` if a future split happens) needs `../../../../core/`. Contributors must count `../` correctly. Easy to typo, hard to catch in review without an automated check.
- **CWD coupling (roadmap L1501).** Roadmap explicitly flags: "Claude má problém s relative paths když CWD ≠ skill dir". The Read tool resolves relative paths against CWD. Claude Code dispatches with CWD = repo root in the BIFITO case, but Phase 2 C2 evidence only proves this for the orchestrator's `[ -r core/mcp-preflight.md ]` probe — it does NOT prove the Read tool from inside a sub-agent's prompt always sees CWD = repo root. If a sub-agent inherits a sub-skill CWD, `../../core/state-manager.md` would resolve relative to that sub-CWD.
- **Visual noise on prose.** "Follow `../../core/mcp-preflight.md`" reads less naturally than the current "Follow `core/mcp-preflight.md`". Across 185 occurrences in user-facing prose, this is a documentation regression.
- **No fail-loud safety net.** If `../../../core/X.md` typo lands and a step file Reads non-existent path, Claude may silently fall back ("file does not exist — proceeding without core/ logic"), reproducing the exact BIFITO-4293 silent-degradation symptom. Phase A guard catches the boot-time case but not per-step-file typos.

**Concrete example (file:line):**

`skills/fix-bugs/SKILL.md:162` (depth 2) rewrites to:

```
| 00   | ... | Follow `../../core/mcp-preflight.md`, validate issue_id, ...
```

`skills/fix-bugs/steps/04-fixer-reviewer-loop.md:3` (depth 3) rewrites to:

```
Follow `../../../core/fixer-reviewer-loop.md` ...
```

`agents/analyst.md:114` (depth 1) rewrites to:

```
... reads `../core/resume-detection.md` ...
```

Three different prefixes for three depth classes. The mechanical rewrite is a 3-pass sed, not a one-liner. Phase 4 spec must spell out file lists per class.

**Phase A guard interaction:**

Phase A guard `[ -r core/mcp-preflight.md ]` runs at repo-root CWD and is **structurally independent of B2**. Guard validates that the plugin install is intact; B2's relative paths validate that any given Read resolves. Phase A catches the gross "wrong CWD" case; it does NOT catch a typo'd `../../core/` in a depth-3 file. Composition is clean but coverage is partial.

**Phase C scenario coverage:**

Phase C external-CWD test directly exercises B2. From `/tmp/external-project`, the harness sets `cd $PLUGIN_DIR/skills/fix-bugs` and tests `[ -r ../../core/mcp-preflight.md ]`. This is a true POSIX test of relative resolution. Phase C scenario coverage for B2 is **highest of the three options** — easiest to write a falsifiable test.

**5-year forward-compat:**

Mediocre. Every new step file added requires its author to count directory depth and pick the right prefix. If the plugin restructures (e.g., flattens `skills/*/steps/` into `skills/*/`), all depth-3 prefixes must be re-flowed. B2 is brittle to directory-tree changes. Over 5 years and ~10 new features, this is a non-trivial maintenance tax.

---

## B3 Analysis (inline clarifier prose + guard-block.md resolver instruction)

**Strengths:**

- **Zero mechanism.** No sed pass over 185 occurrences. No depth-class accounting. No shim. The mechanical-rewrite Phase B becomes "edit first-occurrence clarifier in 9 SKILL.md + add 1 line to each of 3 guard-block.md = 12 edits total".
- **Impossible to break by future contributor.** Bare `core/<name>.md` stays bare. The disambiguation lives in (a) a once-per-SKILL.md prose clarifier and (b) the guard-block.md preflight instruction that ALREADY exists at boot (Phase A). The guard tells Claude "core/ is at plugin root, sibling of skills/" — and Phase A fails loud if that root cannot be found.
- **Composes with Phase A as defense-in-depth.** Phase A guard already verifies `[ -r core/mcp-preflight.md ]` from repo-root CWD. That probe IS the path-resolution test. If Phase A passes, bare `core/X.md` works for every subsequent Read at repo-root CWD. B3 leans on Phase A and adds explicit prose for the human-and-Claude reader, not new path syntax.
- **Forward-compat is automatic.** A new core file added in v10.5.0 needs no rewrite, no depth recount. Authors write `core/new-thing.md` and the guard-block + clarifier already cover the resolution semantics.
- **Documentation quality preserved.** Prose stays readable. "Follow `core/state-manager.md`" is the canonical phrasing and remains unchanged.
- **Smallest blast radius.** If B3 is wrong, the fix is to add Phase A teeth (which is mandatory anyway). If B1 is wrong, you rewrite 185 occurrences AND remove a shim AND re-flow boot sequence. If B2 is wrong, you rewrite 185 occurrences across 3 depth classes. B3's rollback cost is lowest.

**Weaknesses:**

- **Does not directly fix BIFITO-4293 root cause.** BIFITO-4293 happened because Claude mis-resolved `core/X.md` despite the path being correct from repo-root CWD (a hallucinated `skills/fix-bugs/core/` prefix per roadmap L1493). An inline prose clarifier helps the human reader; it may not deter Claude from a future hallucination. B3 relies entirely on Phase A to fail-loud. If Phase A does its job, B3 is sufficient. If Phase A has a gap, B3 has nothing.
- **Surface-ugliness on the first-occurrence clarifier.** "Follow `core/mcp-preflight.md` (sibling of `skills/`, at plugin root — e.g. `./core/mcp-preflight.md` from plugin root, NOT `skills/<skill>/core/`)" is a 30-word inline interruption to a table cell at `skills/fix-bugs/SKILL.md:162`. Visual cost, but a one-time tax.
- **Relies on author discipline.** Future SKILL.md authors must remember to include the clarifier on first `core/` reference. A new SKILL.md added without it gives the same BIFITO-4293 hallucination surface. Mitigation: lint scenario in Phase C.
- **No machine-checkable invariant.** B1 has "PLUGIN_ROOT is set"; B2 has "../../core/X.md resolves from CWD". B3 has "first occurrence in SKILL.md has clarifier prose" — a regex check against drift, not a semantic check.
- **2 of 3 guard-block.md exist; the third (scaffold) must be created from scratch** (Phase 2 C2). That work is Phase A's, not B3's, but it shows B3 leans heavily on Phase A doing its job for all three skills.

**Concrete example (file:line):**

`skills/fix-bugs/SKILL.md:162` first occurrence rewrites to:

```
| 00   | (orchestrator) MCP pre-flight + state init | Follow `core/mcp-preflight.md` (located at plugin root, sibling of `skills/` — NOT under `skills/fix-bugs/`), validate issue_id, ...
```

All subsequent 12 occurrences in `skills/fix-bugs/SKILL.md` and 0/all step files / data files / agent files stay as bare `core/<name>.md`. Total edits in fix-bugs: 1 SKILL.md line. Total across all 9 SKILL.md: 9 lines. Plus 1 resolver-instruction line in each of `skills/{fix-bugs,implement-feature,scaffold}/data/guard-block.md` = 3 lines. **Total Phase B edit volume: ~12 lines.** Versus B1 ~205 lines (185 rewrites + 20-line shim) and B2 ~185-200 lines (depth-aware rewrites + per-class file lists).

**Phase A guard interaction:**

B3 is the ONLY option whose correctness IS Phase A's correctness. The guard's `[ -r core/mcp-preflight.md ]` from repo-root CWD validates exactly the resolution semantics B3 relies on. If Phase A passes, every bare `core/X.md` in the plugin works. If Phase A fails-loud, the user gets the message from roadmap L1497 ("plugin-root not resolved — core/ sibling of skills/ not found"). The composition is tightest of the three options.

**Phase C scenario coverage:**

Phase C external-CWD scenario tests "does the boot sequence find core/ when the user invokes /fix-bugs from /tmp/external-project". For B3, this reduces to "does Phase A fire correctly from external CWD". Two sub-cases: (1) Phase A is invoked with CWD = repo root (Claude Code's normal dispatch) — guard passes, bare paths work. (2) Phase A is invoked with CWD = /tmp/external-project — guard fails-loud as designed. Both branches are testable in a single Bash harness scenario. Phase C coverage for B3 is **clean and falsifiable**.

**5-year forward-compat:**

Best of the three. New core files added at v10.5.0, v11.0.0, v12.0.0 need no path syntax. Directory tree restructures cost zero per-file rewrites. The only forward maintenance is "new SKILL.md must include the clarifier on first core/ reference" — a lint rule. B3 wears the best because its mechanism is prose discipline backed by a single boot-time invariant (Phase A), not a depth-aware syntax or a Bash shim.

---

## Recommendation

**Choose:** **B3** (inline clarifier prose + guard-block.md resolver instruction)

**Confidence:** **0.82**

**Key argument (1 sentence):** B3 minimizes mechanism in a mechanism-free plugin (CLAUDE.md L17), composes tightly with the mandatory Phase A guard (which already does the actual path-resolution test), and survives 5 years of new features and directory-tree changes without rewrite — B1 requires an unjustified Bash shim AND fails the Read-tool-shell-expansion check (dispositive per Phase 2 I1), and B2 carries the depth-split mandate (Phase 2 critical finding) that turns a "mechanical sed" into a 3-pass depth-aware operation with per-step-file typo risk and no fail-loud safety on per-occurrence mistakes.

**Falsifiable success metric:**

> Phase C scenario `tests/scenarios/v10-skill-from-external-cwd.sh` passes on B3 when (a) the harness invokes `/fix-bugs` from CWD = `/tmp/external-project`, (b) Phase A guard fires and produces the L1497 error message verbatim, and (c) the harness asserts exit-code != 0 (fail-loud, no silent fallback). The same scenario MUST fail on a control variant that disables Phase A (proving Phase A is what protects B3). If the scenario passes with Phase A disabled, B3 is insufficient and we fall back to B2 with depth-aware sed.

**Key risk if wrong:**

B3's correctness is 100% inherited from Phase A. If Phase A has a CWD-edge-case I have not anticipated (e.g., a future Claude Code release that dispatches sub-agents with CWD = `skills/{name}/` instead of repo root), B3 silently breaks because bare `core/X.md` would then resolve to `skills/{name}/core/X.md` — exactly the BIFITO-4293 failure mode. Mitigation: Phase A guard MUST be the very first instruction in each guard-block.md AND must run BEFORE any sub-agent dispatch (already required per Phase 2 I3 `<PREFLIGHT>` placement). The recommendation is conditional on Phase A being robust; if Phase A is weakened in spec or implementation, downgrade to B2 + depth-aware sed.

**Why not B1 (steelmanned and rejected):** Even with the `core/lib/path-resolver.sh` shim, B1's `${PLUGIN_ROOT}/core/X.md` token inside backticked markdown is read by Claude's Read tool, which does NOT shell-expand its arguments. The shim sets the env var; the Read tool ignores the env var. To fix this, B1 would need a second mechanism (a Read-tool wrapper or a documented Claude expansion convention), neither of which exists. The forward-compat win is real but rests on Bash machinery in a markdown plugin — wrong abstraction.

**Why not B2 (steelmanned and rejected):** B2 is empirically viable (Phase 2 I1 confirmed) and Phase-C-friendly, BUT the depth-split mandate (Phase 2 critical finding from Agent 3) converts the "mechanical sed" into 3-class authoring forever. Every new step file is a typo opportunity. Phase A guard does not catch per-occurrence relative-path typos in step files. Over 5 years and ~10 new core/ files, B2 accumulates a maintenance tax B3 does not.

DONE
