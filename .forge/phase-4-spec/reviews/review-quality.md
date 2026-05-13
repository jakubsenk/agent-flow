# Phase 4 Quality Review — v10.2.0 `core/` Path Disambiguation

**Forge run:** `forge-2026-05-13-001`
**Reviewer role:** Quality (craft, testability, Phase 7 implementability)
**Artifacts reviewed:**
- `.forge/phase-4-spec/final/requirements.md`
- `.forge/phase-4-spec/final/design.md`
- `.forge/phase-4-spec/final/formal-criteria.md`

---

## Verdict JSON

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": true,
    "no_regressions": true,
    "lint_clean": false,
    "pass": false
  },
  "tier_2": {
    "fail_to_pass": {"passed": null, "failed": null, "total": null},
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true
  },
  "tier_3": {
    "correctness": 3,
    "completeness": 4,
    "security": 4,
    "maintainability": 4,
    "robustness": 2,
    "weighted_aggregate": 3.35,
    "pass": false
  },
  "overall_verdict": "FAIL",
  "confidence": 0.88,
  "findings": [
    {
      "id": "f-d1a2b3",
      "severity": "CRITICAL",
      "criterion": "correctness",
      "location": "requirements.md:REQ-A-2 + design.md:A.1 (line 27)",
      "description": "Probe path off-by-one: REQ-A-2 specifies `../../core` for `skills/{name}/data/guard-block.md`, but those files are at depth-3 (plugin_root/skills/{name}/data/), so the correct relative path from their directory is `../../../core/` (3 up-levels, not 2). Additionally REQ-A-2 simultaneously states 'CWD = repository root', which would require `core/mcp-preflight.md` (0 dotdots), creating an internal contradiction. Design A.1 code block compounds the error: it shows `PROBE=\"../../core/mcp-preflight.md\"` for fix-bugs/data/guard-block.md, which is depth-3. The implementation order note on design.md line 580 correctly says 'depth-3 PROBE path' but conflicts with the actual code block above it. The test scenario C.1 correctly uses `../../../core/mcp-preflight.md` (the only internally consistent reference), confirming the REQ and A.1 block are wrong.",
      "recommendation": "Fix REQ-A-2: change `../../core` to `../../../core` for skills/{name}/data/ files. Resolve the CWD contradiction by clarifying that the probe runs from CWD = guard-block.md file's directory (not repo root), or alternatively restate the probe path as `core/mcp-preflight.md` and mandate CWD=repo_root. Fix design A.1 code block: change `PROBE=\"../../core/mcp-preflight.md\"` to `PROBE=\"../../../core/mcp-preflight.md\"`."
    },
    {
      "id": "f-e4f5g6",
      "severity": "CRITICAL",
      "criterion": "correctness",
      "location": "requirements.md:REQ-C-1 (line 130)",
      "description": "REQ-C-1 assertion (a) states the probe succeeds 'with depth-correct `../../core/mcp-preflight.md`', but the fixture in design C.1 runs from `skills/demo/data` (depth-3) and correctly uses `../../../core/mcp-preflight.md` (3 dotdots). This is the same off-by-one error as REQ-A-2, propagated into the REQ text for the test scenario description.",
      "recommendation": "Fix REQ-C-1 assertion (a): change `../../core/mcp-preflight.md` to `../../../core/mcp-preflight.md`."
    },
    {
      "id": "f-h7i8j9",
      "severity": "MAJOR",
      "criterion": "robustness",
      "location": "formal-criteria.md:FC-C-3 (lines 244-251)",
      "description": "FC-C-3 copies the depth-lint script to `$TMP/tests/` but invokes it as `bash tests/scenarios/v10-core-path-depth-consistency.sh` from `cd $TMP`. The `tests/scenarios/` subdirectory is never created — only `tests/` is. The bash invocation will fail with 'no such file or directory' before it can test anything, meaning FC-C-3 would exit non-zero for the WRONG reason (script-not-found, not lint-caught-violation).",
      "recommendation": "Fix FC-C-3: replace `mkdir \"$TMP/tests\"` with `mkdir -p \"$TMP/tests/scenarios\"` and update the cp destination to `\"$TMP/tests/scenarios/\"`. Alternatively change the invocation to `bash tests/v10-core-path-depth-consistency.sh` and adjust REPO_ROOT derivation accordingly."
    },
    {
      "id": "f-k1l2m3",
      "severity": "MINOR",
      "criterion": "correctness",
      "location": "formal-criteria.md:FC-B-6 (note paragraph)",
      "description": "FC-B-6 hard-codes expected count as 185 but the note immediately below acknowledges the true post-Phase-A count may be 188 (185 + 3 PROBE lines from guard-block.md files). This uncertainty is deferred to Phase 7, which means the FC as written may fail on a correct implementation. Phase 7 implementer has no normative guidance on which value to assert.",
      "recommendation": "Resolve the count before Phase 7: either confirm the PROBE path line in guard-block.md IS counted by the grep pattern (making it 188), or confirm it is NOT (making it 185). Update the FC expected value to the resolved count. Consider documenting the exact grep used on the pre-rewrite tree to derive the baseline."
    },
    {
      "id": "f-n4o5p6",
      "severity": "MINOR",
      "criterion": "maintainability",
      "location": "design.md:B.3 script (lines 221, 229)",
      "description": "The Phase B rewrite helper script uses `mapfile -t` (bash 4.0+ builtin) for building file arrays. macOS ships bash 3.2.57 by default, where `mapfile` is unavailable. Phase 7 implementers on macOS without Homebrew bash would need to substitute with a `while IFS= read -r` loop. The script is not committed to the repo (temporary), so this is advisory rather than blocking.",
      "recommendation": "Replace `mapfile -t ARRAY < <(find ...)` with a POSIX-portable while-read loop, or add a comment noting the bash 4+ requirement and the Win Git-Bash / Linux default satisfies it."
    }
  ]
}
```

---

## Empirical Check Results

| Check | Command | Result | Assessment |
|-------|---------|--------|------------|
| Normative verb count | `grep -c 'SHALL\|MUST' requirements.md` | **26** | PASS — every REQ section contains normative verbs |
| FC reference coverage | `grep -c 'FC-[ABCDE]-[0-9]' requirements.md` | **25** | PASS — all 24 REQs reference at least one FC |
| Sed pattern present | `grep -E 's\|.*core/' design.md \| head -5` | 4 distinct sed invocations shown | PASS |
| 4-backslash check | `grep -c '\\\\'` on design.md | **0** | PASS — no 4-backslash escapes found |

## Phase-Specific Criteria Assessment

### 1. EARS Form Rigor

PASS with minor notes. Each REQ-*.* item has exactly one normative SHALL statement. REQ-B-3 and REQ-E-3 have supplemental numerical assertions tied to the SHALL, which is acceptable. No multi-paragraph essays masquerading as requirements.

### 2. FC Runnability (spot-check 5 FCs)

- **FC-A-1:** `grep -lE '^<PREFLIGHT>$' ... | wc -l | tr -d ' '` — runs as written. PASS.
- **FC-B-3:** `for f in skills/*/SKILL.md; grep -oE ... | grep -vE ...` — runs as written. PASS.
- **FC-B-7:** Idempotency via `cat / printf / sed / comparison` — structurally correct; `printf '%s\n' "$before"` handles embedded newlines. PASS.
- **FC-D-1:** `sed -n "${start},${end}p"` in a while-read loop — portable. PASS.
- **FC-C-3:** FAIL — see finding f-h7i8j9 (tests/scenarios/ subdir missing).

### 3. Sed Correctness

The final B.3 sed pattern `s|(^|[^./])core/([a-z][a-z-]*\.md)|\1{prefix}core/\2|g` is correct:

- Uses 2-backslash escapes (`\1`, `\2`) in `-E` mode. PASS.
- `[^./]` negative character class prevents double-rewrite. PASS.
- `^|[^./]` alternation handles line-start edge case. PASS.
- 4 discrete sed invocations, one per depth class. PASS.
- Verified against 3 dual-pattern lines in B.4 spot-check table. PASS.

The initial code block in B.1 (lines 141-143) shows the simpler `[^./]` without the `^` alternation, then the corrected version with `(^|[^./])` follows on line 151. Both are shown for pedagogical reasons — the canonical form (line 151 and B.3 script) is correct.

### 4. Phase C Scenarios Self-Contained

**v10-skill-from-external-cwd.sh:**
- Shebang: `#!/usr/bin/env bash` — PASS
- `set -uo pipefail` (note: `-e` missing!) — MINOR: `set -euo pipefail` stated in REQ-C-1 item 5 but the design shows `set -uo pipefail`. The scenario proceeds with `FAIL=0` + `fail()` function which is a valid alternative to `set -e`, so functionally equivalent. Non-blocking.
- `mktemp -d ... || mktemp -d -t 'v10ext'` — cross-platform fallback present. PASS.
- `[PASS]` / `[FAIL]` / `[SKIP]` prefixes — PASS.
- `exit 0/1/77` — PASS.
- `trap 'rm -rf "$TMP_ROOT"' EXIT` — PASS.

**v10-core-path-depth-consistency.sh:**
- Shebang: `#!/usr/bin/env bash` — PASS.
- `set -uo pipefail` — PASS.
- Pure bash + grep -E + find (no jq, no realpath). PASS.
- `[PASS]` / `[FAIL]` prefixes — PASS.
- `exit 0/1` — PASS (77 not needed as no tmpdir).
- Uses `eval "find ..."` — functions with single-argument patterns; minor injection concern but patterns are hardcoded strings. Acceptable.

### 5. Phase A Error String

`ABORT: plugin-root not resolved -- core/ sibling of skills/ not found at $PROBE. Check plugin install integrity.`

- Is a literal string (the `$PROBE` expansion is from a shell variable, not a template placeholder — correct for runtime). PASS.
- `exit 2` explicitly stated in REQ-A-3 and design A.1 code block. PASS.

### 6. Open Questions Flagged

Three open questions are explicitly flagged in requirements.md, each with a proposed default. All are non-blocking for Phase 7. PASS.

---

## Tier 3 Scoring Detail

| Criterion | Score | Rationale |
|-----------|-------|-----------|
| Correctness | 3/5 | Two CRITICAL defects (probe depth off-by-one appears in REQ-A-2, design A.1, and REQ-C-1). The scenario code is correct (3 dotdots) creating an internal inconsistency that will cause a Phase 7 implementer to follow the wrong normative text while the FC scenario passes. High divergence risk. |
| Completeness | 4/5 | 24 REQs, 26 FCs, full implementation order, spot-check table, B5 idempotency proof, open questions documented. FC-B-6 count ambiguity is the only completeness gap (MINOR). |
| Security | 4/5 | No 4-backslash over-escape. PROBE path uses `[ -r ]` (read-only test, no execution). `eval "find ..."` in depth-lint uses hardcoded patterns (no user input). `exit 2` distinct from 1/0. |
| Maintainability | 4/5 | Implementation order section is exemplary. Spot-check B.4 table gives concrete before/after for 10 lines across 5 files. B3 documentary clarifier scoped exclusively to guard-block.md (not spread across 185 occurrences). mapfile issue advisory only. |
| Robustness | 2/5 | FC-C-3 path bug means the counterfactual self-test of the depth-lint would fail for wrong reasons. Idempotency proof is sound (FC-B-7). Depth-class coverage (4 classes) is correct. The probe path inconsistency (D1/D2) means the guard itself is under-specified and would be implemented wrong by a mechanical follower of the normative text. |

**Weighted aggregate:** (3×0.30) + (4×0.25) + (4×0.20) + (4×0.15) + (2×0.10) = 0.90 + 1.00 + 0.80 + 0.60 + 0.20 = **3.50**

Weighted aggregate is at the minimum pass threshold (3.5), but Tier 1 fails due to lint_clean=false (two CRITICAL correctness defects mean a Phase 7 implementer following the normative text will produce a wrong probe path).

---

## Required Fixes Before Phase 7

### Fix 1 (CRITICAL — REQ-A-2 + design A.1)

**requirements.md REQ-A-2:** Change:
> `../../core` for `skills/{name}/data/guard-block.md`

To:
> `../../../core` for `skills/{name}/data/guard-block.md`

Also clarify or remove the contradictory "CWD = repository root" sentence. Proposed resolution: replace with "CWD = the guard-block.md file's directory (the orchestrator changes directory to the file's location before running the probe)."

**design.md A.1 code block (line 27):** Change:
```bash
PROBE="../../core/mcp-preflight.md"
```
To:
```bash
PROBE="../../../core/mcp-preflight.md"
```

### Fix 2 (CRITICAL — REQ-C-1)

**requirements.md REQ-C-1 item 4(a):** Change:
> probe SUCCEEDS when run from plugin root with depth-correct `../../core/mcp-preflight.md`

To:
> probe SUCCEEDS when CWD is the guard-block fixture directory (`skills/demo/data/`) with depth-correct `../../../core/mcp-preflight.md`

### Fix 3 (MAJOR — FC-C-3)

**formal-criteria.md FC-C-3:** Change:
```bash
mkdir "$TMP/tests"
cp tests/scenarios/v10-core-path-depth-consistency.sh "$TMP/tests/" 2>/dev/null || true
...
cd "$TMP" && CEOS_REPO_ROOT="$TMP" bash tests/scenarios/v10-core-path-depth-consistency.sh
```
To:
```bash
mkdir -p "$TMP/tests/scenarios"
cp tests/scenarios/v10-core-path-depth-consistency.sh "$TMP/tests/scenarios/" 2>/dev/null || true
...
cd "$TMP" && CEOS_REPO_ROOT="$TMP" bash tests/scenarios/v10-core-path-depth-consistency.sh
```

### Fix 4 (MINOR — FC-B-6)

Resolve the 185 vs 188 count ambiguity before Phase 7 by running the grep pattern on the pre-rewrite tree to confirm whether PROBE lines are captured. Update the expected value to the confirmed number.

---

**STATUS: REVISION-NEEDED**
**Iteration:** 1 of 3 max
