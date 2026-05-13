# Brainstorm -- v10.2.0 Phase B Path-Format -- Persona: INNOVATIVE

**Forge run:** `forge-2026-05-13-001`
**Persona:** Plugin Platform Architect, 10 years -- mechanism-favoring.
**Inputs honored:** Phase 1 final.md, Phase 2 final.md (CRITICAL: B1 = NOT-VIABLE-without-helper per I1), roadmap.md L1489-L1513.

> **Up-front honesty on the persona's prior:** I came in wanting `${PLUGIN_ROOT}` + a resolver shim because it is "the right abstraction" across future skill additions. I will steelman B2 and B3 fairly below. But I also accept the Phase 2 constraint as binding -- there is no platform-injected `$PLUGIN_ROOT` (Phase 2 I1: zero matches in `skills/`, `agents/`, `core/`; `.claude-plugin/plugin.json` has no env-injection schema). My job is therefore to design the helper that makes B1 actually viable, not to wave it in. Anti-pattern #3 ("mechanism-light wins ties") is real -- if my helper is heavy, the tie goes to B2.

---

## B1 Analysis (${PLUGIN_ROOT} + resolver helper)

**Strengths:**
- **Depth-agnostic.** Every rewrite is identical: `${PLUGIN_ROOT}/core/<file>.md`. No depth-2 vs depth-3 vs depth-1 class split (the Phase 2 "B2 depth-split mandate" disappears entirely). One sed pattern handles all 185 occurrences in all 40 files. Compare to B2 which requires 3 separate sed invocations or an explicit file-class manifest.
- **Surface form is self-documenting.** A reader of `skills/fix-bugs/SKILL.md:108` sees `${PLUGIN_ROOT}/core/resume-detection.md` and immediately understands "anchored at plugin root." A reader of `../../core/resume-detection.md` must mentally compute the depth -- and so must Claude.
- **One source of truth for path resolution.** If a future Claude Code release does inject `CLAUDE_PLUGIN_ROOT` natively (the trend is clear -- `filip-superpowers` and `superpowers` already use this name per Phase 2 I1), the shim becomes a 1-line `: "${PLUGIN_ROOT:=$CLAUDE_PLUGIN_ROOT}"` and we are forward-compatible for free.
- **Composes cleanly with v10.0.0 `core/lib/stage-invariant.sh` precedent (134 lines).** That file established the "core/lib/ holds POSIX helpers, sourced by hooks, jq-free, BSD/GNU-grep portable" convention. A `core/lib/path-resolver.sh` (~25 lines) is a natural sibling -- not a new architectural class.
- **Phase A guard becomes trivially correct.** The guard probe is `[ -r "${PLUGIN_ROOT}/core/mcp-preflight.md" ]` -- one absolute path, no CWD assumption.

**Weaknesses:**
- **Requires the helper-shim to exist, AND requires the orchestrator's THIN CONTROLLER to source it before any `core/` reference is encountered.** This is a new pre-flight step in `data/guard-block.md` (3 files). If the source step is skipped, every `core/` reference becomes a literal `${PLUGIN_ROOT}/core/...md` string and silently degrades the same way BIFITO-4293 degraded -- which is the bug we are fixing. The helper must be sourced inside the Phase A guard block (not separately).
- **Bash-only resolution.** `${PLUGIN_ROOT}` is a shell variable, not a markdown construct. Claude must execute the resolver-source step as a Bash tool call. If Claude reads `core/resume-detection.md` via Read tool *before* the Bash source, the orchestrator hits an unset variable and either errors loud (good) or silently treats it as empty (bad: `/core/resume-detection.md` -- file not found, same silent-degradation bug). Mitigation: Phase A guard MUST fail-loud on `[ -z "${PLUGIN_ROOT}" ]` before any `core/*.md` Read.
- **Two-failure-mode surface.** Beyond "core/ not found" (B2/B3 share this), B1 adds "PLUGIN_ROOT unset" and "PLUGIN_ROOT set to wrong path." Both must be tested in Phase C.
- **Markdown lint / IDE noise.** Some markdown linters flag `${VAR}` syntax in non-code-block prose as an unresolved template. Not blocking, but ugly.
- **Mechanism budget violation risk vs anti-pattern #3.** A 25-line shim + Phase A wiring is meaningfully more machinery than B2 (sed pass) or B3 (prose). The win must justify it.

**Concrete example (file:line):** `skills/fix-bugs/SKILL.md:108`

Before (v10.1.2 HEAD):

```
Follow `core/resume-detection.md` for resume detection logic. Inputs: `ISSUE_ID` (single) or
```

After B1:

```
Follow `${PLUGIN_ROOT}/core/resume-detection.md` for resume detection logic. Inputs: `ISSUE_ID` (single) or
```

**Phase A guard interaction:** **Composes, with mandatory ordering.** Phase A `<PREFLIGHT>` block (new XML block prepended to each `data/guard-block.md` per Phase 2 I3) must execute steps in this order:

1. Bash: `source core/lib/path-resolver.sh` (resolves `${PLUGIN_ROOT}` from `$BASH_SOURCE`-equivalent or `pwd`-walk; see Helper Design below).
2. Bash: `[ -n "${PLUGIN_ROOT}" ] || { echo "plugin-root not resolved..."; exit 1; }`.
3. Bash: `[ -r "${PLUGIN_ROOT}/core/mcp-preflight.md" ] || { echo "plugin-root resolved to '${PLUGIN_ROOT}' but core/mcp-preflight.md not readable -- plugin install integrity check failed"; exit 1; }`.
4. Export `PLUGIN_ROOT` for subsequent step subagents.

Without step 1, every `${PLUGIN_ROOT}/core/...md` Read fails closed. Phase A is **mandatory** to make B1 work; the two are co-dependent, not orthogonal.

**Phase C scenario coverage:** **Yes, with two test vectors.** `tests/scenarios/v10-skill-from-external-cwd.sh` must exercise:
- (a) `cd /tmp/external-project && /fix-bugs BIFITO-4293` -- B1 should resolve `${PLUGIN_ROOT}` via the shim's CWD-walk fallback and find core/. If it doesn't, the guard fails loud.
- (b) `cd /tmp/external-project && PLUGIN_ROOT= /fix-bugs BIFITO-4293` -- explicit unset to confirm fail-loud branch.

If B1 is chosen, both vectors are mandatory. B2 only needs vector (a). This is the cost.

**5-year forward-compat:** **Best of the three.** Reasoning:
- Cross-platform plugin installs (next-generation Claude Code likely formalizes `CLAUDE_PLUGIN_ROOT` -- already used by 2 other plugins on this machine per Phase 2 I1) cost ~1 line of helper diff to adopt.
- Adding 18th, 19th, 20th skill = zero additional path-resolution work. Each new SKILL.md uses the same `${PLUGIN_ROOT}/core/...md` pattern; no depth-class calculation required.
- If `core/lib/` grows to add e.g. `state-helpers.sh`, the helper-discovery pattern is already in place.
- B2 carries the depth-split tax forever: every new skill author must remember the rule "SKILL.md = ../../core, steps/*.md = ../../../core, data/*.md = ../../../core, agents/*.md = ../core." Cognitive load compounds.
- B3 is prose-only; it does not actually fix the silent-degradation mechanism, it only documents it. New skill authors will copy old patterns and forget the clarifier.

---

## B2 Analysis (../../core/ relative)

**Steelman first.** B2 is the option I should pick if my B1 helper turns out to be heavy or fragile. Phase 2 verified B2 is VIABLE: `dirname(dirname(skills/fix-bugs/SKILL.md))` = repo root, and all 17 core files resolve via `ls skills/fix-bugs/../../core/`. Zero new machinery -- it is pure prose change in 40 files. No new failure mode added; the only failure mode (CWD != skill dir) is the same one Phase A guard already addresses.

**Strengths:**
- **Zero new mechanism.** A single sed pass per depth-class (3 invocations total). 0 new files, 0 new functions, 0 new env vars. Anti-pattern #3 favored.
- **Phase A guard composes orthogonally.** The guard checks `[ -r core/mcp-preflight.md ]` (or `[ -r skills/fix-bugs/../../core/mcp-preflight.md ]` -- depth-1 from guard-block.md). Either works; no helper needed.
- **Resolves Claude's known weakness with anchoring.** Phase 2 evidence: zero existing files use any non-standard prefix; all 185 occurrences are bare `core/<name>.md`. The transform is mechanical and verifiable -- run `grep -rn '^core/\|[^./]core/' skills/ agents/ --include='*.md'` post-rewrite; expect 0 matches.
- **Lowest total LOC change.** Phase B remains in the ~50-100 net-lines budget (roadmap L1509). B1's helper-shim consumes ~25 of that budget before the rewrite even starts.

**Weaknesses:**
- **The depth-split tax.** 3 separate sed invocations or a file-class manifest. Phase 2 explicitly flagged this as the primary B2 risk (B2 Depth-Split Mandate section). One missed class = corrupted files at `agents/*.md` (`../../../core/` would point above the repo) or step files (`../../core/` would point at `skills/{name}/core/` -- the exact silent-degradation bug we are fixing).
- **Claude relative-path mishandling (roadmap L1501).** Documented model behavior: when CWD != skill dir, Claude sometimes resolves `../../core/X.md` against CWD instead of against the file containing the reference. Phase A guard catches the FIRST such failure; subsequent reads must each be checked. (Note: this is the same mechanism that surfaced BIFITO-4293.)
- **New-skill authoring friction.** Every new SKILL.md author must internalize the depth table. v10.2.0 ships with 9 SKILL.md + 28 step files + 2 (now 3) guard-block.md + 3 agent files. v10.3.0+ adds more. Cognitive tax compounds.
- **Aesthetic noise.** `../../core/` in 175 skill locations and `../core/` in 7 agent locations is visually heavier than `${PLUGIN_ROOT}/core/`.

**Concrete example (file:line):** `skills/fix-bugs/SKILL.md:108`

Before:

```
Follow `core/resume-detection.md` for resume detection logic. Inputs: `ISSUE_ID` (single) or
```

After B2 (depth-2 class):

```
Follow `../../core/resume-detection.md` for resume detection logic. Inputs: `ISSUE_ID` (single) or
```

For comparison, the depth-3 step file `skills/fix-bugs/steps/01-triage.md:47` gets `../../../core/state-manager.md`; the depth-1 agent file `agents/analyst.md:114` gets `../core/resume-detection.md`.

**Phase A guard interaction:** **Fully orthogonal.** Guard is a fail-loud probe; B2 is a prose rewrite. They do not depend on each other. Guard catches B2's failure mode (CWD != skill dir -> relative resolution fails) and aborts loud instead of degrading silent.

**Phase C scenario coverage:** **Yes, single vector.** External-CWD scenario directly exercises B2's failure surface. If from `/tmp/external-project` Claude resolves `../../core/X.md` against CWD instead of against skill file location, the scenario fails -- which is what we want (forcing Phase A guard to abort loud). Phase C is sufficient with one vector.

**5-year forward-compat:** **Middle.** The depth-split tax is a permanent author-time burden. Every new skill author makes a depth-class decision per `core/` reference. Plugin-marketplace-driven skill contributions from outside contributors will routinely get this wrong. Phase A guard catches the failures, but the iteration cost is real. B1 amortizes the helper cost across new additions; B2 distributes the cost across each author.

---

## B3 Analysis (inline clarifier + guard-block resolver instruction)

**Steelman first.** B3 has the lowest mechanism cost of all three. The "fix" is purely social/documentary: first occurrence in each SKILL.md gets a `(sibling of skills/, at plugin root)` clarifier, and `data/guard-block.md` gets a one-line "core/ paths are anchored at plugin root, the parent directory of skills/" prose instruction. Zero sed, zero new machinery, zero new failure mode. It is impossible to break because there is no executable logic to break.

**Strengths:**
- **Lowest LOC change of all three.** ~10 lines of prose total (one clarifier per SKILL.md first-occurrence + 2-3 lines in each guard-block.md).
- **Zero machinery surface.** Cannot introduce a regression because there is no logic.
- **Composes orthogonally with Phase A guard.** Guard remains the actual fail-loud mechanism; B3 is purely advisory prose.

**Weaknesses:**
- **Does not fix the silent-degradation mechanism.** Phase 2 confirms: BIFITO-4293 occurred because Claude *misinterpreted* `core/X.md` as a subpath of `skills/fix-bugs/`. Adding "(sibling of skills/, at plugin root)" prose at the first occurrence relies on Claude remembering the clarifier for the next 184 occurrences in the same session. Real model behavior: attention decays; multi-step pipelines spawn fresh subagents that re-read fresh prefix windows; the clarifier will be dropped under context pressure.
- **No machine-checkable contract.** Phase 4 cannot lock B3's success because there is no syntactic invariant to test against. We can grep that the clarifier prose exists, but we cannot grep that Claude actually followed it.
- **The whole bug class re-occurs the moment Phase A guard is bypassed.** B3 leans 100% on Phase A. If Phase A guard ever has a bypass condition (a flag, a profile, a new skill that forgets the guard directive), the bug returns. B1 and B2 fix the path itself; B3 only fixes the documentation around the path.
- **Anti-pattern #2 risk (aesthetics-only argument).** B3 has no evidence anchor for why this would prevent recurrence beyond "Claude will read the clarifier and remember." That is not a falsifiable claim.

**Concrete example (file:line):** `skills/fix-bugs/SKILL.md:108`

Before:

```
Follow `core/resume-detection.md` for resume detection logic. Inputs: `ISSUE_ID` (single) or
```

After B3 (first occurrence in file -- `skills/fix-bugs/SKILL.md` already references core at line 108, so the clarifier appends here):

```
Follow `core/resume-detection.md` (sibling of skills/, at plugin root -- e.g. `./core/resume-detection.md` from plugin root, NOT skills/fix-bugs/core/) for resume detection logic. Inputs: `ISSUE_ID` (single) or
```

Plus `skills/fix-bugs/data/guard-block.md` gets:

```
> All `core/<file>.md` references in this skill and its step files are anchored at plugin root (the parent directory of skills/). They are NOT resolved relative to skill directory or CWD.
```

**Phase A guard interaction:** **B3 IS the prose half of Phase A.** B3 lives inside `data/guard-block.md` -- it is the explanatory prose paired with the Phase A executable check. Phase A guard does the fail-loud work; B3 is the documentation. Not orthogonal -- collapsed into the same file.

**Phase C scenario coverage:** **Does not exercise B3 directly.** External-CWD scenario tests path resolution, not prose comprehension. If Claude reads the clarifier but still mis-resolves, the scenario fails -- which is correct behavior -- but B3 cannot be said to have "passed" or "failed" the scenario in any falsifiable sense. The scenario tests Phase A; B3 free-rides.

**5-year forward-compat:** **Worst.** Each new skill author must remember to add the clarifier at the first `core/` occurrence. Linters cannot enforce it (it's prose). It will rot. B3 alone in v10.5.0 would mean every new skill has a fresh chance to silently degrade because someone forgot the clarifier comment. The only durable mechanism is Phase A guard -- B3 contributes nothing additive past the first release.

---

## Helper Design (mandatory if B1 is chosen)

**File location:** `core/lib/path-resolver.sh`
**Convention basis:** `core/lib/stage-invariant.sh` (v10.0.0, 134 lines) -- POSIX-compatible, jq-free, Windows Git-Bash + macOS BSD + Linux GNU tested.

**Resolution strategy (3-tier with fail-loud fallback):**

1. **Tier 1 -- platform-injected env var.** If `${CLAUDE_PLUGIN_ROOT}` is set by the runtime, adopt it. (Forward-compat hook; current Claude Code does not set it for ceos-agents per Phase 2 I1, but `filip-superpowers` and `superpowers` plugins already use this exact name; once Claude Code formalizes it, we get it for free.)
2. **Tier 2 -- `$BASH_SOURCE`-relative.** Resolve from this script's own location: `core/lib/path-resolver.sh` -> `dirname` twice -> plugin root.
3. **Tier 3 -- CWD-walk fallback.** Walk upward from `$PWD` looking for a directory containing both `core/` and `skills/` and `.claude-plugin/plugin.json`. Stop at filesystem root.
4. **Fail-loud if all three tiers fail.** Exit 1 with the BIFITO-4293-aligned message.

**Runnable example (the file I would write):**

```bash
#!/usr/bin/env bash
# core/lib/path-resolver.sh
# v10.2.0 - Resolve PLUGIN_ROOT for ceos-agents orchestrator.
# Sourced by data/guard-block.md Phase A preflight block.
# POSIX-compatible. Convention mirrors core/lib/stage-invariant.sh (v10.0.0, 134L).
#
# Contract: after sourcing, $PLUGIN_ROOT is set to an absolute path
# satisfying [ -r "$PLUGIN_ROOT/core/mcp-preflight.md" ], OR the script
# has exited 1 with a fail-loud diagnostic.

set -uo pipefail

resolve_plugin_root() {
  # Tier 1: platform-injected env var (forward-compat).
  if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -r "${CLAUDE_PLUGIN_ROOT}/core/mcp-preflight.md" ]; then
    printf '%s' "$CLAUDE_PLUGIN_ROOT"; return 0
  fi

  # Tier 2: $BASH_SOURCE-relative (script is at core/lib/path-resolver.sh).
  local script_dir candidate
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" 2>/dev/null || script_dir=""
  if [ -n "$script_dir" ]; then
    candidate="$(cd "$script_dir/../.." && pwd)" 2>/dev/null
    if [ -n "$candidate" ] && [ -r "$candidate/core/mcp-preflight.md" ]; then
      printf '%s' "$candidate"; return 0
    fi
  fi

  # Tier 3: CWD-walk fallback (handles external-CWD dispatch).
  candidate="$PWD"
  while [ "$candidate" != "/" ] && [ -n "$candidate" ]; do
    if [ -r "$candidate/core/mcp-preflight.md" ] \
       && [ -d "$candidate/skills" ] \
       && [ -f "$candidate/.claude-plugin/plugin.json" ]; then
      printf '%s' "$candidate"; return 0
    fi
    candidate="$(dirname "$candidate")"
  done

  return 1
}

PLUGIN_ROOT="$(resolve_plugin_root)" || {
  echo "[ceos-agents] FATAL: plugin-root not resolved -- core/ sibling of skills/ not found." >&2
  echo "  Attempted: CLAUDE_PLUGIN_ROOT, \$BASH_SOURCE-relative, CWD-walk from $PWD." >&2
  echo "  Check plugin install integrity (expected layout: <root>/core/, <root>/skills/, <root>/.claude-plugin/plugin.json)." >&2
  return 1 2>/dev/null || exit 1
}
export PLUGIN_ROOT
```

**Estimated LOC:** ~40 (with comments). Stage-invariant.sh is 134L; this is ~30% of that budget. Within "core/lib/ helper" precedent.

**Orchestrator pickup mechanism:** Phase A guard prepends a new `<PREFLIGHT>` XML block (per Phase 2 I3 structural placement) to each of 3 `data/guard-block.md` files:

```
<PREFLIGHT>
Before any other instruction, execute this Bash command exactly:
  source core/lib/path-resolver.sh

If it fails, abort the pipeline. Do NOT proceed to MANDATORY-EXECUTION-GUARD.
After success, $PLUGIN_ROOT is set; all subsequent `${PLUGIN_ROOT}/core/...md` references resolve.
</PREFLIGHT>
```

**Step Completion Invariants impact (v10.0.0 reliability contract):** Zero. The helper does not touch `dispatch_witness`, `dispatched_at`, `tool_uses`, or `status`. It runs *before* the first agent dispatch. Harness 0-fail holds.

---

## Recommendation

**Choose:** **B1** (with the helper-shim design above) -- but **only** if Phase 4 spec commits to the full 3-tier resolver and Phase A `<PREFLIGHT>` ordering. If the spec ships a degraded B1 (e.g., Tier 1 only, no CWD-walk fallback), I retract and prefer B2.

**Confidence:** **0.62** (moderate-positive).

The confidence is not higher because I am genuinely weighing the anti-pattern #3 warning ("mechanism-light wins ties"). B2 is closer to a tie than my persona bias would naturally admit. The 0.62 reflects:
- +0.20 depth-agnostic rewrite (single sed pattern beats 3-class manifest)
- +0.15 forward-compat for 5-year horizon (10+ new skills land without new path logic)
- +0.10 composes with v10.0.0 `core/lib/` convention
- +0.05 surface form self-documents intent
- -0.10 ~40 LOC helper-shim is real mechanism budget vs B2's 0 LOC
- -0.10 two-failure-mode surface (unset PLUGIN_ROOT + wrong PLUGIN_ROOT) requires 2 Phase C vectors vs B2's 1
- -0.08 markdown-only plugin ethos (anti-pattern #3) genuinely tilts toward B2

**Falsifiable success metric:**

> B1 wins if and only if `tests/scenarios/v10-skill-from-external-cwd.sh` executes `/fix-bugs BIFITO-4293` from CWD `/tmp/external-project` (no `CLAUDE_PLUGIN_ROOT` env) AND:
>
> 1. The pre-flight `source core/lib/path-resolver.sh` exits 0 via Tier 2 ($BASH_SOURCE) OR Tier 3 (CWD-walk).
> 2. `[ -n "${PLUGIN_ROOT}" ] && [ -r "${PLUGIN_ROOT}/core/mcp-preflight.md" ]` returns 0.
> 3. The orchestrator successfully reads `${PLUGIN_ROOT}/core/resume-detection.md` (per `skills/fix-bugs/SKILL.md:108`).
> 4. A second test variant with `PLUGIN_ROOT=` explicit-unset AND CWD outside any ceos-agents checkout fails LOUD (exit 1 with the diagnostic message), not silent.
> 5. Harness suite remains 348-pass / 0-fail (no v10.0.0 reliability regression).
>
> B1 LOSES (and Phase 4 should fall back to B2 with depth-split mandate) if any of (1)-(4) fails on Linux, macOS, or Windows Git-Bash.

**Key risk if wrong:** The helper-shim adds an attack surface and an extra dispatch-time failure mode that markdown-only plugin ethos warns against. If `${PLUGIN_ROOT}` resolution proves unreliable on Windows Git-Bash (where `$BASH_SOURCE[0]` can be a relative path under some MinGW configs) AND the CWD-walk Tier 3 cannot find the marker (because the user invoked from a deeply nested directory inside the repo), the whole pipeline fails at preflight -- which is at least loud, but it is a new failure class that B2 does not introduce. Mitigation: Phase C must run the scenario on all 3 OSes (matching `core/lib/stage-invariant.sh` self-test's stated portability target).

**One honest concession to the SKEPTICAL persona track:** If SKEPTICAL surfaces a Windows-MinGW $BASH_SOURCE failure mode I haven't anticipated, my recommendation collapses. B2 + Phase A guard becomes the right answer. The judge should weight Phase C OS-matrix evidence heavily.

DONE
