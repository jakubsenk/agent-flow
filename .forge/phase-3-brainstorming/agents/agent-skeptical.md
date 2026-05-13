# Brainstorm -- v10.2.0 Phase B Path-Format -- Persona: SKEPTICAL

**Persona role:** Test Infrastructure Engineer + Devil's Advocate, 8y. Default-distrust posture: every option is guilty until a regression scenario clears it. Adversarial probes on each B*. Steelman B1 and B3 fairly; conclude with B2 only if Phase C can be made rigorous enough to catch the failure modes B2 implies.

**Evidence anchors used throughout:**
- `phase-2-research-answers/final.md` (locked at v10.1.2 / `32f6f33`): 182 lines / 185 occurrences across 40 files; depth-split 4 classes; B1 NOT-VIABLE-without-helper; `core/mcp-preflight.md` 6 refs; `scaffold/data/` does not exist; guard-block.md files have zero path-resolution logic.
- `core/lib/stage-invariant.sh` (v10.1.2, 134L): `compute_dispatch_witness`, `check_dispatch_witness`, `emit_witness_audit`.
- `skills/fix-bugs/data/guard-block.md` L41-43: cites `core/lib/stage-invariant.sh::compute_dispatch_witness` as prose reference, NOT as a shell-resolvable path.
- `skills/fix-bugs/SKILL.md` L162: `core/mcp-preflight.md` reference (concrete rewrite target below).
- `tests/scenarios/v10-step-completion-invariants-completeness.sh` L25: `REPO_ROOT="${CEOS_REPO_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"` — proves the harness convention for "compute repo root from script location, allow override env var." Phase C scenario will mirror this exactly.

---

## B1 Analysis (${PLUGIN_ROOT} + resolver helper in `core/lib/path-resolver.sh`)

**Strengths:**
- Future-proof against directory-depth churn: if a skill is ever moved (e.g., `skills/{name}/SKILL.md` → `skills/group/{name}/SKILL.md`), the path text does not change — only the resolver re-computes from `BASH_SOURCE`.
- Explicit machinery makes failures grep-able. `${PLUGIN_ROOT}/core/mcp-preflight.md` unresolved produces a literal `${PLUGIN_ROOT}` substring in `ls` errors — diagnostic gold compared to "No such file or directory: core/mcp-preflight.md" (which is exactly the silent-degradation trail from BIFITO-4293 per roadmap L1491).
- Composes cleanly with v10.0.0 `core/lib/stage-invariant.sh`: same `core/lib/` directory, same shell-callable contract surface, same "bash-grade helper" idiom.

**Weaknesses (skeptical posture — these are deal-breakers, not paper-cuts):**
- **Phase 2 I1 is binary-conclusive: `$PLUGIN_ROOT` is NOT a Claude Code dispatch contract.** Zero occurrences in skills/agents/core; `.claude-plugin/plugin.json` has no env-injection schema. The only `CLAUDE_PLUGIN_ROOT` references in the whole repo (`.claude/settings.local.json:82,84`) are manually embedded by OTHER plugins. Adopting B1 means the ceos-agents plugin INVENTS a runtime contract the platform does not back.
- **Markdown cannot resolve env vars.** SKILL.md files are read by the model, not executed by bash. Writing `${PLUGIN_ROOT}/core/state-manager.md` in prose creates a NEW failure class: the model has to KNOW to resolve `${PLUGIN_ROOT}` from the resolver-helper output, which is a second-order dispatch the orchestrator must remember to perform. **A path-format bug fix that adds a new path-resolution step that itself can be skipped is a strict regression.** This is exactly the silent-degradation shape that BIFITO-4293 surfaced — we'd be replacing one silent-skip class with another.
- **Resolver helper is new attack surface.** ~20 lines of bash that the v10.0.0 audit pipeline (`compute_dispatch_witness`, `check_dispatch_witness`, `emit_witness_audit`) does not currently validate. A bug in `path-resolver.sh` could resolve to `/`, and `${PLUGIN_ROOT}/core/state-manager.md` would become `/core/state-manager.md` — readable on some systems, silently wrong. Phase 8 robustness audit on v10.1.0/v10.1.1 already found a `grep -A 8 → 30` window-size bug in `stage-invariant.sh`; assume any new helper carries the same class of latent defect.
- **Violates anti-pattern 3 in the prompt.** "Mechanism-light wins ties" for a markdown-only plugin. B1 maximizes machinery to solve a path-text problem.
- **Forward-compat is illusory.** The "future skill restructure" argument is hypothetical — there has been ZERO skill-directory-restructure in the plugin's v6→v10 history. Pre-paying optionality cost is YAGNI.

**Concrete example (file:line):** `skills/fix-bugs/SKILL.md:162`
- Before: `| 00   | (orchestrator) MCP pre-flight + state init | Follow \`core/mcp-preflight.md\`, validate issue_id, ...`
- After (B1): `| 00   | (orchestrator) MCP pre-flight + state init | Follow \`${PLUGIN_ROOT}/core/mcp-preflight.md\` (resolve PLUGIN_ROOT via \`core/lib/path-resolver.sh\`), validate issue_id, ...`
- Problem visible: now EVERY step file must prefix with `${PLUGIN_ROOT}/` AND every reader must know how to resolve it. The prose grows ~15 chars per occurrence × 185 occurrences = ~2,800 extra chars across the surface; documentation cost is not zero.

**Phase A guard interaction:** ORTHOGONAL but interaction-heavy. Phase A guard (probe `[ -r core/mcp-preflight.md ]` from CWD = repo root per phase-2 C2) does NOT validate that B1 occurrences are rewritten correctly. If `path-resolver.sh` is broken but the probe file is reachable, guard passes — silent failure persists at the per-step level. To close this gap, Phase A guard would have to additionally validate `${PLUGIN_ROOT}` resolution succeeds — adding test surface to B1's already-large machinery footprint.

**Phase C scenario coverage:** A from-`/tmp/external-project` scenario tests CWD invariance — which is exactly what B1's resolver claims to provide. The scenario therefore directly exercises B1's failure mode. BUT: the scenario can only test the HAPPY path (resolver works → probe found). It cannot test the silent-skip class where a future authoring slip omits `${PLUGIN_ROOT}/` prefix from a new SKILL.md occurrence. That requires a STATIC scan (lint) — additional Phase C investment.

**5-year forward-compat:** Best of three IN ISOLATION (only path-format change that survives a directory restructure with zero edits). But the v10.0.0 reliability contract bakes the assumption that skills are at `skills/{name}/` depth 2 — see `core/lib/stage-invariant.sh` and `state/schema.md`. Restructuring depth in any future version would invalidate other invariants too. So B1's portability advantage is theoretical, not realizable without bigger contract churn.

---

## B2 Analysis (`../../core/X.md` relative-to-SKILL)

**Strengths:**
- **Zero new machinery.** Pure prose rewrite. Composes trivially with v10.0.0 contract: `core/lib/stage-invariant.sh` is referenced by prose path ALREADY (`skills/fix-bugs/data/guard-block.md:43`), and that prose reference is depth-2 (`../../core/lib/...`)-equivalent under B2. No new failure mode introduced into the dispatch_witness / Step Completion Invariants chain.
- **Markdown reader behavior is well-tested.** Claude already follows relative refs in markdown across thousands of plugin invocations. Phase 2 I1 confirms `ls skills/fix-bugs/../../core/` resolves correctly — the OS-level path semantics are deterministic.
- **Phase 2 C1 confirms zero non-standard prefixes.** All 185 occurrences are bare `core/<name>.md` (no `./core/`, no `skills/../core/`). Mechanical sed substitution is feasible per-depth-class.
- **CWD-invariant.** `../../core/X.md` from `skills/fix-bugs/SKILL.md` resolves correctly regardless of the model's CWD at dispatch time, because the resolution is anchored to the SKILL.md path, NOT to CWD. This is exactly the property BIFITO-4293's silent degradation exposed (the orchestrator was reading SKILL.md from `skills/fix-bugs/` but resolving `core/` against its own working dir).

**Weaknesses (skeptical posture — these are the failure modes Phase C MUST catch):**
- **B2 depth-split is real and dangerous.** Phase 2 final.md "B2 Depth-Split Mandate" section is explicit: 4 distinct prefix classes (`agents/*.md` → `../core/`; `skills/{X}/SKILL.md` → `../../core/`; `skills/{X}/steps/*.md` → `../../../core/`; `skills/{X}/data/*.md` → `../../../core/`). A NAIVE global sed `s|core/X|../../core/X|g` applied uniformly will corrupt 7 agent files (over-deep) and 30 step/data files (under-deep). Phase 4 spec MUST mandate 3 separate sed invocations or an explicit file-class manifest.
- **Symlink hazard.** If a consumer's plugin install symlinks `~/.claude/plugins/cache/ceos-agents` → some other path, `../../core/` from a symlinked SKILL.md resolves via the SYMLINK PARENT, not the link target's parent — on most shells. The marketplace clone path under `~/.claude/plugins/cache/` is observable but the structure under it is not documented as symlink-free. **Phase C must include a symlinked-plugin-dir variant.**
- **Path with spaces.** Consumer CWD could be `C:/Users/Some User/projects/external/`. `../../core/X.md` is symbol-only — no quoting needed for the path-format itself. But if any preflight probe in Phase A guard uses `[ -r ../../core/mcp-preflight.md ]` and the SKILL.md path itself contains a space, bash without quoting breaks. **Phase A guard probe MUST quote the path.**
- **Claude relative-path mishandling.** The roadmap L1501 itself flags: "Claude má problém s relative paths když CWD ≠ skill dir." This is the central risk — historical observation that the model sometimes resolves `../../core/X.md` against CWD (silent wrong) instead of against SKILL.md's directory (silent right). **Phase C must explicitly probe this in adversarial-CWD setup, not just "happy path external CWD."**
- **Future restructure (e.g., `skills/group/X/SKILL.md` at depth 3) silently breaks all `../../core/` refs in those files.** No lint catches this until the day a /fix-bugs run silently fails again. Mitigation: a new lint scenario asserting "for each `*.md` under `skills/`, the dotdot-prefix count matches the file's depth." ~15-line bash check; should be added to Phase C.

**Concrete example (file:line):** `skills/fix-bugs/SKILL.md:162`
- Before: `| 00   | (orchestrator) MCP pre-flight + state init | Follow \`core/mcp-preflight.md\`, validate issue_id, ...`
- After (B2): `| 00   | (orchestrator) MCP pre-flight + state init | Follow \`../../core/mcp-preflight.md\`, validate issue_id, ...`
- Sed pattern for the SKILL.md depth-2 class: `sed -i 's|`core/\([a-z][a-z-]*\.md\)|`../../core/\1|g' skills/*/SKILL.md skills/*/data/*.md` — WRONG: data files are depth-3. Correct manifest: 4 invocations, one per depth class. (Phase 4 spec must enumerate.)

**Phase A guard interaction:** STRONG defense-in-depth pairing. Phase A guard probes from CWD = repo root (per phase-2 C2: `[ -r core/mcp-preflight.md ]` resolves correctly there) — this is INDEPENDENT of B2's depth-relative resolution. So Phase A catches "plugin install integrity" failures (core/ missing entirely, wrong CWD at SKILL.md load); B2 catches "path text correctly anchored to SKILL.md location." Two orthogonal defenses → silent degradation must defeat BOTH to recur. This is the defense-in-depth case for B2 + Phase A specifically.

**Phase C scenario coverage:** Direct fit IF the scenario is rigorous. Minimum bar for Phase C to lock B2:
1. **CWD-invariance probe.** Invoke `/fix-bugs` (or a stub harness equivalent) from CWD = `/tmp/external-project/` (or `$TMPDIR/ext-$$`), assert that the SKILL.md→`../../core/mcp-preflight.md` resolution succeeds, the orchestrator does NOT silently skip core/ logic.
2. **Phase A guard hit-test.** Inside the scenario, temporarily `mv core/mcp-preflight.md core/mcp-preflight.md.bak` and assert the pipeline ABORTS with the canonical message (`"plugin-root not resolved..."` per roadmap L1497). Restore afterward.
3. **Depth-split static lint.** Bash check: for each file in the 4 depth classes, assert the `core/`-references use the CORRECT dotdot count. ~20 lines. This is what catches future file additions at the wrong depth — a class of failure the runtime scenario above cannot catch.
4. **Symlink-resilience probe.** Create `$TMPDIR/plugin-symlink-$$` symlinking to the repo root; invoke from there; assert resolution still works. (If it doesn't on a specific OS, document the constraint in README install notes.)
5. **Adversarial-CWD edge cases.** Path with spaces (`$TMPDIR/dir with spaces/`), path with unicode (`$TMPDIR/üñîçødé/`), path with deep nesting (`$TMPDIR/a/b/c/d/e/f/g/`). All must produce identical pass behavior.

If Phase C ships items 1+2+3 at minimum, the bet is locked. Items 4 and 5 are nice-to-have but reduce residual risk.

**5-year forward-compat:** WORST of three IN ISOLATION — depth-split means any future directory restructure requires N edits proportional to occurrences (185 today). BUT: combined with the depth-lint from Phase C above, future restructures fail loud at lint time, not silently at user-run time. So the forward-compat hit is bounded.

---

## B3 Analysis (inline clarifier prose + `data/guard-block.md` resolver instruction)

**Strengths:**
- Even less machinery than B2. Pure prose annotation; no path math.
- Cannot break by any future structural change — the prose simply describes the current layout.
- Diff-minimal: only ~9 SKILL.md files need a first-occurrence annotation; the other ~28 step files and 3 agent files require no edit (the prose-clarifier-once approach assumes a careful reader).

**Weaknesses (skeptical posture — fatal in our threat model):**
- **Reader-dependent. BIFITO-4293 proved exactly that the reader is not always careful.** Claude hallucinated reading 3 nonexistent files from `skills/fix-bugs/core/` (roadmap L1493). A prose clarifier on line 162 of a 252-line SKILL.md doesn't help when the orchestrator scanned only a sub-section and confabulated paths from training-data priors.
- **NO mechanical enforcement.** Phase A guard cannot verify that B3 prose is correctly written — a missing annotation is a docstring bug, not a runtime failure. Phase C scenario cannot distinguish a B3-correct run from a B2-correct run when both succeed; the differentiator only appears under reader-hallucination conditions, which are NOT reproducible in a deterministic test scenario.
- **`data/guard-block.md` is dispatch-time prose, not load-time enforcement.** Adding "Resolve `core/X.md` as sibling-of-`skills/`" to guard-block.md is a hint to the reader — same failure surface that BIFITO-4293 exhibited.
- **Composes weakly with v10.0.0 reliability contract.** Step Completion Invariants and dispatch_witness audit are MECHANICAL enforcement layers. B3 introduces a NON-MECHANICAL enforcement layer alongside them — a regression in the v10.0.0 thin-controller philosophy ("subagents do reasoning, orchestrator does NOT reason about the problem domain").
- **B3 has been the de-facto status quo and it failed.** The current v10.1.2 prose contains references like `core/mcp-preflight.md` with implicit "sibling of skills/" reading — that's exactly what BIFITO-4293 broke against. Doubling down on prose without mechanical reinforcement just adds more prose to ignore.

**Concrete example (file:line):** `skills/fix-bugs/SKILL.md:162`
- Before: `| 00   | (orchestrator) MCP pre-flight + state init | Follow \`core/mcp-preflight.md\`, validate issue_id, ...`
- After (B3, first occurrence in this file — L108 actually predates L162; the FIRST `core/*.md` ref in `fix-bugs/SKILL.md` is L108 `core/resume-detection.md`): `| 00   | (orchestrator) MCP pre-flight + state init | Follow \`core/mcp-preflight.md\` *(path is sibling of skills/, at plugin root — e.g. \`./core/mcp-preflight.md\` from plugin root, NOT \`skills/fix-bugs/core/\`)*, validate issue_id, ...`
- Plus a guard-block.md prepend like: `<PREFLIGHT>All \`core/<file>.md\` paths in this skill are relative to plugin root (sibling of \`skills/\`).</PREFLIGHT>`
- Problem visible: the annotation reads as a tooltip, not a contract. The orchestrator can scan past it or selectively attend.

**Phase A guard interaction:** ORTHOGONAL only. Phase A guard catches "core/ entirely missing" — but B3 specifically does NOT address the silent-skip case where `core/` exists and the orchestrator simply confabulates the wrong sub-path. Phase A's probe of `core/mcp-preflight.md` from CWD = repo root passes whether B3 prose is correct or absent.

**Phase C scenario coverage:** Phase C cannot adequately exercise B3's failure mode. The failure mode is "model misreads prose under specific cognitive-load conditions" — non-deterministic, not reproducible in scripted harness scenarios. A Phase C scenario can verify the prose is PRESENT (static-check that each SKILL.md contains a clarifier on first `core/` occurrence) but cannot verify the prose is EFFECTIVE.

**5-year forward-compat:** Brittle. Each future SKILL.md addition must remember to include the clarifier on first `core/` mention. A static-lint can enforce "must contain clarifier comment" but can't enforce "comment is semantically correct." Pure-prose mechanism, pure-prose maintenance burden.

---

## Recommendation

**Choose:** B2 + Phase A guard (defense-in-depth pairing)

**Confidence:** 0.85

The skeptical confidence is high (not 0.95) because B2 carries depth-split authoring risk that REQUIRES Phase C rigor to neutralize. If Phase C ships only "external CWD happy path" without the depth-lint static check (item 3 above), confidence drops to 0.60 — at which point I would defer to B3 + heavy Phase A guard. With the depth-lint added to Phase C, B2 strictly dominates.

**Falsifiable success metric (must hold simultaneously):**

1. **Phase C runtime scenario PASSES on B2:** `tests/scenarios/v10-skill-from-external-cwd.sh` invoked from CWD = `$TMPDIR/external-$$/` succeeds (orchestrator reaches Step 00 mcp-preflight load, witness audit emits WITNESS_OK for at least one stage, no silent core/-skip detected via grep for the BIFITO-4293 marker phrase `"Core files don't exist in this install"` in the orchestrator transcript).
2. **Phase C runtime scenario FAILS-LOUD when core/ removed:** with `core/mcp-preflight.md` moved out, the same scenario aborts with stderr matching `plugin-root not resolved` (regex). Exit code non-zero.
3. **Phase C depth-lint PASSES on v10.2.0 HEAD:** new static scenario `tests/scenarios/v10-core-path-depth-consistency.sh` asserts: for each `*.md` under {`agents/`, `skills/{X}/SKILL.md`, `skills/{X}/steps/*.md`, `skills/{X}/data/*.md`}, every `../../core/`-or-similar reference uses the depth-correct prefix per the Phase 2 depth-split table. ~25 lines bash, jq-free, mirrors the v10-step-completion-invariants scenario style.
4. **v10.0.0 reliability contract is preserved unchanged:** `core/lib/stage-invariant.sh` is NOT modified; existing 13 v10-*.sh scenarios all still PASS; harness reports 0 failures (currently 353/348/0/5).
5. **Hypothetical B1 would FAIL metric 1** because B1 requires `${PLUGIN_ROOT}` resolution which the platform does not back (per Phase 2 I1). **Hypothetical B3 would PASS metric 1** but FAIL the implicit "no silent degradation on reader confabulation" test — which we cannot encode mechanically, hence why B3 is rejected on prior evidence (BIFITO-4293 == real-world falsification of B3 in production).

**Key risk if wrong:**

The depth-split is mishandled in Phase B's mechanical rewrite, producing a v10.2.0 release with 185 occurrences rewritten but some at the WRONG depth (e.g., `agents/*.md` rewritten to `../../core/` instead of `../core/`). This would silently break ANALYST/FIXER/PUBLISHER (the 3 agent files) at runtime in exactly the same silent-degradation shape as BIFITO-4293 — except now the bug ships from the fix-for-BIFITO-4293 release. Mitigation: the Phase C depth-lint (metric 3) is the kill-switch. **If we ship without Phase C item 3, we're flying blind on the most likely B2 regression class.** Phase 4 spec MUST treat the depth-lint as a P0 acceptance criterion, not a "nice-to-have."

Second-order risk: Phase A guard text quotes a path under a CWD containing spaces and fails to quote it. Mitigation: `[ -r "core/mcp-preflight.md" ]` with explicit quotes in the guard prose (and ideally a self-test mirroring `core/lib/stage-invariant.sh`'s `--self-test` mode at L124).

DONE
