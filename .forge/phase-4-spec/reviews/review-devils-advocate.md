# Devil's Advocate Review — Phase 4 Spec
# Forge run: forge-2026-05-13-001 (v10.2.0 core/ Path Disambiguation)
# Reviewer role: Devil's Advocate (adversarial, Tier 3 only)

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": true,
    "no_regressions": true,
    "lint_clean": true,
    "pass": true,
    "note": "DA scope = quality only. Tier 1/2 set to pass by protocol."
  },
  "tier_2": {
    "fail_to_pass": {"passed": null, "failed": null, "total": null},
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true,
    "note": "DA scope = quality only. Tier 2 set to pass by protocol."
  },
  "tier_3": {
    "correctness": 3,
    "completeness": 4,
    "security": 4,
    "maintainability": 3,
    "robustness": 2,
    "weighted_aggregate": 3.25,
    "pass": false
  },
  "overall_verdict": "FAIL",
  "confidence": 0.91,
  "findings": [
    {
      "id": "f-da0001",
      "severity": "CRITICAL",
      "criterion": "correctness",
      "location": "design.md §B.1 B.3 sed script lines using | delimiter with (^|[^./]) alternation",
      "description": "The design.md B.3 script uses | as the sed s/// delimiter AND | for regex alternation inside the pattern — they conflict. `sed -E 's|(^|[^./])core/...|...|g'` fails with 'unknown option to s' on GNU sed 4.9 (confirmed on Windows Git-Bash). The script as written CANNOT run without modification.",
      "recommendation": "Switch to / as delimiter with backslash-escaping, or use a different alternation approach: `sed -E 's/(^|[^.\\/])core\\/([a-z][a-z-]*\\.md)/\\1..\\/..\\/core\\/\\2/g'`. Alternatively drop the ^-alternation entirely (Phase 2 confirms zero line-start occurrences) and rely on `[^./]` only, which avoids the | conflict entirely. Verify the fix with an explicit bash test in Phase 7."
    },
    {
      "id": "f-da0002",
      "severity": "HIGH",
      "criterion": "correctness",
      "location": "formal-criteria.md §FC-D-1 automation-config.md:585",
      "description": "FC-D-1 produces a false positive on `docs/reference/automation-config.md:585` which contains BOTH `v10-counts-invariants.sh` and `13 optional` on the same line. The FC's sed-window search (`grep -nE 'v10-' + sed -n ${start},${end}p | grep -qE '\\b13\\b'`) will match the '13' in '13 optional config sections' and incorrectly exit 1, blocking the gate even when no stale scenario count exists.",
      "recommendation": "Narrow FC-D-1's grep to match only scenario-count-proximate '13': e.g., `grep -qE '\\b13\\b.*(v10-.*\\.sh|scenario|harness)|(v10-.*\\.sh|scenario|harness).*\\b13\\b'` on the surrounding lines, OR filter out the known false-positive line by excluding 'optional' from the match context."
    },
    {
      "id": "f-da0003",
      "severity": "HIGH",
      "criterion": "robustness",
      "location": "design.md §B.3 depth-3 sed — scaffold/data/guard-block.md interaction with Phase A ordering",
      "description": "Phase A creates scaffold/data/guard-block.md containing `../../../core/mcp-preflight.md` (already depth-correct per A.3 design). Phase B's depth-3b sed then runs over ALL skills/*/data/*.md files including the new file. The sed pattern `[^./]core/X.md` will NOT match `../../../core/mcp-preflight.md` (idempotency holds). However, the guard-block.md B3 clarifier prose also contains literal `../core/`, `../../core/`, `../../../core/` as examples — these are already-prefixed and safe. RISK: if Phase A authors the PROBE path WITHOUT the depth prefix (i.e., a typo leaves `core/mcp-preflight.md` bare in the new file), Phase B would rewrite it to `../../../core/mcp-preflight.md` for depth-3 but this would be accidentally correct. The spec does not include a pre-Phase-B assertion that A.3's PROBE path is already depth-correct. If A.3 is implemented with wrong depth (e.g., `../../core/mcp-preflight.md` for a depth-3 file), Phase B silently passes the idempotency check while the guard path is wrong.",
      "recommendation": "Add an explicit FC-A gate that asserts the PROBE path in scaffold/data/guard-block.md contains exactly `../../../core/mcp-preflight.md` (3 dotdots), not the depth-2 variant. This catches Phase A authoring errors that Phase B would mask."
    },
    {
      "id": "f-da0004",
      "severity": "MINOR",
      "criterion": "robustness",
      "location": "design.md §C.1 v10-skill-from-external-cwd.sh — probe CWD vs. design intention",
      "description": "The spec (REQ-A-2) states the probe runs with CWD = repository root. But the guard-block.md is READ by Claude from its location, and the probe path `../../core/mcp-preflight.md` is relative to the guard-block.md FILE directory, not to CWD. The scenario C.1 correctly simulates this by doing `cd $PLUGIN_ROOT/skills/demo/data` before running the probe — which is depth-3. However, the REQ-A-2 phrasing 'with CWD = repository root (the Claude Code default working directory)' contradicts this: if CWD is repo root, then `../../core/mcp-preflight.md` from repo root resolves to the PARENT of the repo, not to `core/`. The requirement text is misleading. REQ-A-2 should read 'probe path is relative to the guard-block.md file directory, not CWD' — the scenario correctly implements this but the requirement text will confuse Phase 7 implementers.",
      "recommendation": "Clarify REQ-A-2: the probe resolves relative to the guard-block.md file's directory (not CWD). The scenario correctly simulates this. The requirement wording is the only issue — a documentation defect, not a runtime defect."
    },
    {
      "id": "f-da0005",
      "severity": "MINOR",
      "criterion": "robustness",
      "location": "formal-criteria.md §FC-B-6 — occurrence count ambiguity (185 vs 188)",
      "description": "FC-B-6 expects exactly 185 dotdot-prefixed occurrences. The spec self-notes: 'The PREFLIGHT probe lines in 3 guard-block.md files contribute 3 dotdot-prefixed references... so the total may be 188.' The FC comment then says 'Phase 7 confirms the exact post-rewrite count.' This is a deferred spec hole — the FC as written will FAIL if Phase A's 3 PROBE lines push the count to 188. Phase 7 must update the expected value BEFORE running FC-B-6, but the spec gives no decision on which number is correct.",
      "recommendation": "Pre-decide: 185 = occurrences in original 40-file scope BEFORE Phase A; 188 = post-Phase-A including PROBE lines in the 3 guard-block files. REQ-B-3 scopes the rewrite to 40 files + 185 occurrences (pre-Phase-A). Phase A adds 3 new PROBE references. FC-B-6 should be updated to 188 (or the FC should exclude the guard-block files from its grep). The spec should make this call explicitly."
    }
  ]
}
```

---

## Probe Analysis

### Probe 1 — Symlink hazard

**PASS.** The Phase A guard uses `[ -r "$PROBE" ]` where `PROBE` is a relative path computed from the guard-block.md directory. Symlink resolution is transparent to `-r` on all POSIX systems — bash follows symlinks when evaluating readability. If the plugin is installed via symlink, `[ -r "../../core/mcp-preflight.md" ]` resolves through the symlink chain correctly. The depth-aware sed in Phase B also operates on paths from a known `REPO_ROOT` (computed via `cd "$(dirname "$0")/.." && pwd`), not from a symlink-derived CWD. No hazard identified. Steelman: if `pwd` in a symlink-resolved shell returns the physical path, `dirname "$0"` for a script invoked by symlink path might differ — but Phase B's script is a temporary one-shot at the repo root, not invoked via symlink.

### Probe 2 — CWD with spaces

**CONCERN** (minor). The design.md B.3 script uses `REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"` which correctly handles spaces via double-quoting. The `for f in` loops and `find` use double-quoted `"$f"` expansions. The guard-block.md probe uses `PROBE="../../core/mcp-preflight.md"` (no spaces in this path) and `[ ! -r "$PROBE" ]` (correctly quoted). No structural quoting failures found. The concern is rated MINOR because phase B's script is a temporary throwaway, but the scenario scripts at `tests/scenarios/` use `REPO_ROOT` from `$0` which handles spaces correctly. Acceptable.

### Probe 3 — Windows Git-Bash line endings (CRLF)

**PASS.** The spec explicitly requires `set -euo pipefail` and POSIX-portable constructs (REQ-C-4). The existing harness scenarios in `tests/scenarios/` run on Win Git-Bash (confirmed: MEMORY.md states harness 353/348/0/5 passes). Git-Bash normalizes CRLF for shell execution. The spec does not explicitly require LF normalization in `.gitattributes`, but the existing 13 scenarios already work on this platform, establishing that the harness handles this. No new risk introduced by the 2 new scenarios. Acceptable.

### Probe 4 — The 3 dual-pattern lines

**PASS with caveat.** Verified by bash test: `sed -E 's|([^./])core/([a-z][a-z-]*\.md)|\1../../core/\2|g'` on `Follow \`core/block-handler.md\` and \`core/state-manager.md\` protocol.` correctly rewrites BOTH occurrences to `../../core/...` in one pass. The `g` flag ensures all non-overlapping matches on the line are replaced. Both backtick-preceded `core/` refs are preceded by a non-`./` character (the backtick), so `[^./]` matches, the character is consumed by `\1`, and both refs are rewritten. HOWEVER: the design.md uses `|` as sed delimiter with `(^|[^./])` alternation — which FAILS (finding f-da0001). The simpler form without the `^` branch works correctly for dual-pattern lines.

### Probe 5 — Read tool's `${PLUGIN_ROOT}` vs `../../core/X.md` resolution

**PASS (B2 is sound for its purpose, but the fundamental question has a nuanced answer).** B1 was rejected because `${PLUGIN_ROOT}/core/X.md` is a shell variable that the Read tool reads literally as a path string containing `${PLUGIN_ROOT}` — which does not resolve to a real path. B2 uses `../../core/X.md`. When Claude reads a SKILL.md file and encounters the instruction "Read `../../core/X.md`", Claude resolves this relative to its CWD (repo root), NOT relative to the file's location. From repo root, `../../core/X.md` resolves ABOVE the repo — this appears to be the same failure mode as B1. HOWEVER: the spec's Phase A guard-block.md contains the probe as a bash snippet (executed via Bash tool), not as a Read tool instruction. The B2 rewrite in SKILL.md step files is instruction prose like "Follow `../../core/state-manager.md`" — Claude's actual behavior when reading such instructions is to use the Read tool with the path relative to CWD (repo root). From repo root, `../../core/state-manager.md` goes above the repo. This IS the fundamental B2 weakness. The spec acknowledges this implicitly by making Phase A's BASH PROBE the guard (bash resolves relative to `cd`'d directory), but B2's prose instructions still have the ambiguity. The spec does NOT claim B2 fixes Claude's Read tool resolution — only that it makes paths unambiguous for human readers and eliminates silent hallucination. The BIFITO-4293 failure mode was hallucination of `skills/{name}/core/` subdirectories; B2 eliminates that by making no valid path resolve that way. Rated PASS for spec-correctness but the spec writer should acknowledge this residual limitation explicitly.

### Probe 6 — Phase 7 ordering: B.3 sed rewriting A.3's new guard-block.md

**CONCERN (addressed in spec but with a masking risk — see finding f-da0003).** The spec explicitly states "Phase A MUST run BEFORE Phase B. Reason: Phase A creates scaffold/data/guard-block.md... Phase B's depth-3 sed then rewrites [its] reference." The idempotency guard (`[^./]core/`) prevents double-rewrite of already-prefixed paths. The masking risk is: if Phase A incorrectly authors scaffold/data/guard-block.md with the wrong depth prefix (e.g., `../../core/` instead of `../../../core/` for depth-3), Phase B's depth-3 sed will still not rewrite it (because `../../core/` contains `./` before `core/`, blocking the `[^./]` match), leaving a depth-wrong path silently uncorrected. FC-B-5 would catch this (it asserts all `skills/*/data/*.md` use `../../../core/`), but only if Phase B runs. There is no pre-Phase-B assertion on A.3's output. Mitigated by FC-B-5 but the gap is noted.

### Probe 7 — v10.0.0 reliability regression: `core/state-manager.md` and `core/lib/`

**PASS.** Confirmed: `core/state-manager.md` contains ZERO `core/X.md` references (grep returned 0 matches). The `core/` files in general contain self-referential `core/X.md` prose in some files (block-handler.md, fixer-reviewer-loop.md, etc.) but Phase B's scope-lock explicitly covers ONLY `agents/*.md`, `skills/*/SKILL.md`, `skills/*/steps/*.md`, and `skills/*/data/*.md` (40 files). The B.3 script uses explicit file lists + `find skills/` and `find agents/` — it does NOT touch `core/` files. `core/lib/stage-invariant.sh` is a `.sh` file excluded from `--include='*.md'` patterns. REQ-E-4 (byte-identical stage-invariant.sh) and REQ-E-5 (existing scenarios pass) are not threatened by the Phase B sed. The design.md §Phase E verification note confirms: "Phase B file list explicitly excludes `core/lib/`". No regression risk here.

### Probe 8 — FC-D-1 false positive

**FAIL.** Confirmed by inspection: `docs/reference/automation-config.md:585` contains `13 optional` and `v10-counts-invariants.sh` on the SAME line. FC-D-1's implementation searches for `\b13\b` within 5 lines of any `v10-` reference. Line 585 IS the v10- match line, and `start=$((lineno - 5))` through `end=$((lineno + 5))` includes the line itself. `grep -qE '\b13\b'` will match `13 optional`. The FC will exit 1 falsely, blocking Phase 8 gate. This is a HIGH finding (f-da0002) because it breaks the formal verification gate without indicating any real problem.

---

## Weighted Aggregate Rationale

| Criterion | Score | Weight | Contribution |
|---|---|---|---|
| Correctness | 3 | 0.30 | 0.90 |
| Completeness | 4 | 0.25 | 1.00 |
| Security | 4 | 0.20 | 0.80 |
| Maintainability | 3 | 0.15 | 0.45 |
| Robustness | 2 | 0.10 | 0.20 |
| **Total** | | | **3.35** |

Weighted aggregate 3.35 < 3.5 threshold. Robustness below minimum of 2 (scored 2, minimum 2 — meets minimum; but correctness minimum is 3, scored 3 — meets minimum). The aggregate failure drives the FAIL verdict, not individual criterion minimums.

**Overall verdict: FAIL.** Two HIGH/CRITICAL findings (f-da0001 CRITICAL: sed script is syntactically broken on GNU sed 4.9; f-da0002 HIGH: FC-D-1 false positive on automation-config.md:585) must be resolved before Phase 7 execution. Three additional MINOR/HIGH findings (f-da0003, f-da0004, f-da0005) are recommended fixes but do not block.

**Confidence: 0.91** (high — sed delimiter conflict confirmed by live bash test; FC-D-1 false positive confirmed by line inspection).
