# v10.2.0 — `core/` Path Disambiguation — Formal Criteria

**Forge run:** `forge-2026-05-13-001`
**Maps to:** `requirements.md` REQ-A/B/C/D/E

All FCs are bash-executable. Each FC: `bash -c "<cmd>"` returns exit 0 on PASS, non-zero on FAIL. Run from repository root (`C:/gitea_ceos-agents/`). Expected outputs are exact strings or regex.

---

## FC-A — Phase A Guard

### FC-A-1 — `<PREFLIGHT>` block present in 3 guard-block.md files

**REQ:** REQ-A-1, REQ-A-4

```bash
count=$(grep -lE '^<PREFLIGHT>$' \
  skills/fix-bugs/data/guard-block.md \
  skills/implement-feature/data/guard-block.md \
  skills/scaffold/data/guard-block.md 2>/dev/null | wc -l | tr -d ' ')
test "$count" -eq 3
```

**PASS criterion:** exit 0 (count == 3).

### FC-A-2 — Probe shape: `[ -r ... ]` test against `core/mcp-preflight.md`

**REQ:** REQ-A-2

```bash
count=$(grep -lE '\[ ! -r ".*core/mcp-preflight\.md" \]' \
  skills/fix-bugs/data/guard-block.md \
  skills/implement-feature/data/guard-block.md \
  skills/scaffold/data/guard-block.md 2>/dev/null | wc -l | tr -d ' ')
test "$count" -eq 3
```

**PASS criterion:** exit 0 (probe test present in all 3 files).

### FC-A-3 — Canonical abort message + exit 2

**REQ:** REQ-A-3

The pattern matches the exact ASCII-form double-hyphen `--` string emitted by the
guard-block.md Bash probe (design.md §A.1). This intentionally deviates from
roadmap L1497's em-dash for ASCII-safety; see spec-compliance review f-a1c2e3.

```bash
count=$(grep -lE 'ABORT: plugin-root not resolved -- core/ sibling of skills/ not found at' \
  skills/fix-bugs/data/guard-block.md \
  skills/implement-feature/data/guard-block.md \
  skills/scaffold/data/guard-block.md 2>/dev/null | wc -l | tr -d ' ')
test "$count" -eq 3 && \
  grep -lE '^[[:space:]]*exit 2$' \
    skills/fix-bugs/data/guard-block.md \
    skills/implement-feature/data/guard-block.md \
    skills/scaffold/data/guard-block.md 2>/dev/null | wc -l | tr -d ' ' | grep -q '^3$'
```

**PASS criterion:** exit 0 (canonical ASCII abort message + `exit 2` line both present in all 3 files).

### FC-A-4 — `skills/scaffold/SKILL.md` Read-tool directive

**REQ:** REQ-A-5

```bash
grep -qE 'guard-block\.md.*BEFORE any other instruction' skills/scaffold/SKILL.md
```

**PASS criterion:** exit 0 (directive present).

### FC-A-5 — B3 documentary clarifier present in 3 guard-block.md files

**REQ:** REQ-A-6

```bash
count=$(grep -lE 'canonical layout is .core/. as sibling of .skills/. at plugin root' \
  skills/fix-bugs/data/guard-block.md \
  skills/implement-feature/data/guard-block.md \
  skills/scaffold/data/guard-block.md 2>/dev/null | wc -l | tr -d ' ')
test "$count" -eq 3
```

**PASS criterion:** exit 0 (clarifier prose present in all 3 files).

### FC-A-6 — Pre-Phase-B depth-correct PROBE path in all 3 guard-block.md files

**REQ:** REQ-A-2, REQ-A-4 (depth-correctness gate)

This FC runs AFTER Phase A is complete but BEFORE Phase B sed. Without this gate,
a wrong-depth authoring error in Phase A would be masked by Phase B's idempotency
guard `[^./]` (which refuses to rewrite anything already containing `./`), leaving
a depth-wrong PROBE silently uncorrected. Added per Devil's Advocate finding
f-da0003.

```bash
# All three guard-block.md files sit at skills/{name}/data/, which is depth-3
# from plugin root. The canonical PROBE path MUST be exactly "../../../core/mcp-preflight.md".
count=$(grep -lF 'PROBE="../../../core/mcp-preflight.md"' \
  skills/fix-bugs/data/guard-block.md \
  skills/implement-feature/data/guard-block.md \
  skills/scaffold/data/guard-block.md 2>/dev/null | wc -l | tr -d ' ')
test "$count" -eq 3
```

**PASS criterion:** exit 0 (all 3 guard-block.md files contain the depth-3 PROBE
assignment verbatim before Phase B sed runs).

---

## FC-B — Phase B Path Rewrite

### FC-B-1 — Zero bare `core/X.md` references in skills/ and agents/ (excluding `<PREFLIGHT>` probe blocks)

**REQ:** REQ-B-1, REQ-B-3

```bash
# Exclude lines inside ../core/, ./core/, or scope-locked `<PREFLIGHT>` probe-comment blocks.
# A "bare" occurrence is `core/X.md` with no `../` or `./` prefix.
# Note: the canonical PREFLIGHT prose intentionally mentions paths like "../core/" and
# "../../core/" — these are not bare and pass the lint.
bare_count=$(grep -rEn '(^|[^./])core/[a-z][a-z-]*\.md' skills/ agents/ --include='*.md' \
  | grep -v ':[[:space:]]*<!--' \
  | wc -l | tr -d ' ')
test "$bare_count" -eq 0
```

**PASS criterion:** exit 0 (zero bare references).

### FC-B-2 — Depth-1 prefix correct in `agents/*.md`

**REQ:** REQ-B-2 (depth-1 row)

```bash
# Every `core/X.md` reference in agents/*.md MUST be prefixed with exactly one ../.
# Match `((\.\./){N})core/X.md` and verify N==1 for every hit.
bad=$(grep -oE '(\.\./){0,}core/[a-z][a-z-]*\.md' agents/*.md \
  | awk -F: '{print $NF}' \
  | awk '!/^\.\.\/core\// {print; exit_code=1} END{exit exit_code+0}'
)
echo "$bad"
test -z "$bad"
```

**PASS criterion:** exit 0 (every match in agents/*.md begins with exactly `../core/`).

### FC-B-3 — Depth-2 prefix correct in `skills/*/SKILL.md`

**REQ:** REQ-B-2 (depth-2 row)

```bash
bad=$(for f in skills/*/SKILL.md; do
  grep -oE '(\.\./){0,}core/[a-z][a-z-]*\.md' "$f" | grep -vE '^\.\./\.\./core/' || true
done)
test -z "$bad"
```

**PASS criterion:** exit 0 (every match begins with exactly `../../core/`).

### FC-B-4 — Depth-3 prefix correct in `skills/*/steps/*.md`

**REQ:** REQ-B-2 (depth-3 steps row)

```bash
bad=$(for f in skills/*/steps/*.md; do
  [ -f "$f" ] || continue
  grep -oE '(\.\./){0,}core/[a-z][a-z-]*\.md' "$f" | grep -vE '^\.\./\.\./\.\./core/' || true
done)
test -z "$bad"
```

**PASS criterion:** exit 0 (every match begins with exactly `../../../core/`).

### FC-B-5 — Depth-3 prefix correct in `skills/*/data/*.md`

**REQ:** REQ-B-2 (depth-3 data row)

```bash
bad=$(for f in skills/*/data/*.md; do
  [ -f "$f" ] || continue
  grep -oE '(\.\./){0,}core/[a-z][a-z-]*\.md' "$f" | grep -vE '^\.\./\.\./\.\./core/' || true
done)
test -z "$bad"
```

**PASS criterion:** exit 0 (every match begins with exactly `../../../core/`).

### FC-B-6 — Total occurrence count of dotdot-prefixed `core/X.md` patterns is 188

**REQ:** REQ-B-3

```bash
total=$(grep -roE '(\.\./){1,}core/[a-z][a-z-]*\.md' skills/ agents/ --include='*.md' | wc -l | tr -d ' ')
test "$total" -eq 188
```

**PASS criterion:** exit 0 (188 dotdot-prefixed occurrences post-rewrite).

> **Count rationale (resolved per spec-revision, no longer Phase-7-deferred).** The post-Phase-A-and-Phase-B tree contains:
>
> - **185 occurrences** rewritten from bare `core/X.md` by the Phase B sed (REQ-B-3 scope: 40 files × pre-Phase-A baseline).
> - **+3 occurrences** added by Phase A — each of the 3 guard-block.md files contains the `PROBE="../../../core/mcp-preflight.md"` Bash assignment, which the grep `(\.\./){1,}core/[a-z][a-z-]*\.md` matches as a dotdot-prefixed reference.
> - **Total: 188.** The 3 PROBE assignments are in the canonical depth-correct shape (`../../../core/`), so FC-B-1 (zero bare occurrences) and FC-B-5 (depth-3 prefix correctness) both pass; FC-B-6 simply counts them.
>
> The B3 documentary-clarifier prose inside `<PREFLIGHT>` blocks mentions `../core/`, `../../core/`, and `../../../core/` as path-format examples — those are ALSO dotdot-prefixed, contributing additional matches per file. The clarifier prose is identical across all 3 guard-block.md files and contains 3 such example tokens per block, so the total is `185 + 3 (PROBE) + 9 (3 files × 3 example tokens) = 197`. **However**, the clarifier prose tokens appear as bare path fragments (e.g., `../core/`), NOT as `../core/<filename>.md`, so the `(\.\./){1,}core/[a-z][a-z-]*\.md` grep does NOT match them (no filename component). Final expected count: **185 + 3 = 188**. Phase 7 implementer validates this on the post-rewrite tree; if the actual count differs by ±5 due to authoring drift in A.3's full content (which the spec does not literally enumerate), update both the test value AND this rationale block in a single design-doc-correction commit before tagging.

### FC-B-7 — Idempotency: re-running sed produces no further changes

**REQ:** REQ-B-4

```bash
# Run the depth-2 sed again and verify no skills/*/SKILL.md changes.
for f in skills/*/SKILL.md; do
  before=$(cat "$f")
  after=$(printf '%s\n' "$before" | sed -E 's|([^./])core/([a-z][a-z-]*\.md)|\1../../core/\2|g')
  if [ "$before" != "$after" ]; then
    echo "NOT IDEMPOTENT: $f"
    exit 1
  fi
done
exit 0
```

**PASS criterion:** exit 0 (no file changes on second run).

### FC-B-8 — No `docs/` or top-level `README.md`/`CHANGELOG.md` changes from Phase B sed

**REQ:** REQ-B-5

```bash
# Verify the docs/ tree has no bare `core/X.md` introduced by Phase B (Phase B should not touch docs/).
# Note: docs/ may contain narrative mentions of paths — this FC is a sanity check that no edit
# accidentally rewrote a doc file.
# Compare to v10.1.2 HEAD via git:
git diff --stat v10.1.2 -- docs/ README.md CHANGELOG.md | grep -vE '^[[:space:]]*$' | grep -vE 'CHANGELOG\.md' | wc -l | tr -d ' ' | grep -qE '^[01]$'
```

**PASS criterion:** exit 0 (only CHANGELOG.md changed in docs+README+CHANGELOG; docs/ untouched by Phase B; CHANGELOG.md changed by REQ-D-2 only).

---

## FC-C — Phase C Test Scenarios

### FC-C-1 — `v10-skill-from-external-cwd.sh` exists and exits 0

**REQ:** REQ-C-1

```bash
test -f tests/scenarios/v10-skill-from-external-cwd.sh && \
  test -x tests/scenarios/v10-skill-from-external-cwd.sh && \
  bash tests/scenarios/v10-skill-from-external-cwd.sh
```

**PASS criterion:** exit 0; stdout contains `[PASS]` prefix.

### FC-C-2 — `v10-core-path-depth-consistency.sh` exists and exits 0

**REQ:** REQ-C-2

```bash
test -f tests/scenarios/v10-core-path-depth-consistency.sh && \
  test -x tests/scenarios/v10-core-path-depth-consistency.sh && \
  bash tests/scenarios/v10-core-path-depth-consistency.sh
```

**PASS criterion:** exit 0; stdout contains `[PASS]` prefix.

### FC-C-3 — Counterfactual: depth-lint catches deliberately-broken control

**REQ:** REQ-C-3

```bash
# Make a deep copy of a depth-3 file and revert one ../../../ to ../../
TMP=$(mktemp -d)
cp -r skills "$TMP/"
cp -r agents "$TMP/"
mkdir -p "$TMP/tests/scenarios"
cp tests/scenarios/v10-core-path-depth-consistency.sh "$TMP/tests/scenarios/" 2>/dev/null || true
# Inject a depth-violation in one file
target_file="$TMP/skills/fix-bugs/steps/01-triage.md"
sed -E -i 's|\.\./\.\./\.\./core/state-manager\.md|../../core/state-manager.md|' "$target_file" 2>/dev/null
# Run the lint from the corrupted root
(
  cd "$TMP" && CEOS_REPO_ROOT="$TMP" bash tests/scenarios/v10-core-path-depth-consistency.sh
)
rc=$?
rm -rf "$TMP"
# Expected: NON-zero exit (lint catches the violation)
test "$rc" -ne 0
```

**PASS criterion:** exit 0 (the lint correctly FAILS on the corrupted control).

### FC-C-4 — Both new scenarios use POSIX-portable mktemp (no GNU-only flags)

**REQ:** REQ-C-4

```bash
# Verify no GNU-only mktemp flags or realpath / grep -P usage.
! grep -E 'mktemp --suffix|grep -P|realpath' \
    tests/scenarios/v10-skill-from-external-cwd.sh \
    tests/scenarios/v10-core-path-depth-consistency.sh
```

**PASS criterion:** exit 0 (no forbidden constructs).

---

## FC-D — Cross-Cutting

### FC-D-1 — Doc-quartet review (no stale "13" scenario count for v10-*.sh remains)

**REQ:** REQ-D-1

This FC verifies no scenario-count-proximate `13` remains in the doc-quartet.
Tightened per Devil's Advocate f-da0002: the previous broad `\b13\b` pattern
false-positives on `docs/reference/automation-config.md:585` ("...18 Automation
Config sections (5 required + 13 optional)...") because that line ALSO contains
a `v10-counts-invariants.sh` reference, creating two unrelated 13s in proximity.
The corrected pattern requires `13` to appear in scenario-count context (next to
`scenario`, `harness`, or `v10-*.sh` token specifically).

```bash
# Search for "13" within 5 lines of a "v10-*.sh" reference in the 5 doc-quartet files.
# Only count "13" matches that appear in scenario-count context (adjacent to
# 'scenario', 'harness', or directly modifying a v10-*.sh tally).
fail=0
for doc in CLAUDE.md README.md docs/reference/automation-config.md docs/reference/skills.md docs/architecture.md; do
  [ -f "$doc" ] || continue
  # Iterate lines that mention a specific v10-*.sh scenario filename
  while IFS= read -r line; do
    lineno="${line%%:*}"
    start=$((lineno - 5))
    end=$((lineno + 5))
    [ "$start" -lt 1 ] && start=1
    # Look for "13" in scenario-count context, NOT in unrelated section-count context.
    # The pattern requires '13' to be adjacent to 'scenario' or 'harness' OR
    # to be modifying a count of v10-*.sh tests directly.
    if sed -n "${start},${end}p" "$doc" \
         | grep -E '\b13\b' \
         | grep -qE '13[[:space:]]+(v10-|harness|scenario)|((v10-[a-z-]+\.sh)|harness|scenario)[^.]*\b13\b' ; then
      echo "STALE 13 scenario-count in $doc near line $lineno"
      fail=1
    fi
  done < <(grep -nE 'v10-[a-z-]+\.sh' "$doc")
done
test "$fail" -eq 0
```

**PASS criterion:** exit 0 (no scenario-count-proximate "13" within 5 lines of any v10-*.sh reference). Verified against v10.1.2 HEAD: returns 0 (no false positive on automation-config.md:585's "13 optional").

### FC-D-2 — CHANGELOG entry for v10.2.0 present

**REQ:** REQ-D-2

```bash
grep -qE '^### v10\.2\.0 -- core/ Path Disambiguation' CHANGELOG.md
```

**PASS criterion:** exit 0.

### FC-D-3 — Version bumped to 10.2.0 in plugin.json + marketplace.json

**REQ:** REQ-D-3

```bash
grep -qE '"version":[[:space:]]*"10\.2\.0"' .claude-plugin/plugin.json && \
  grep -qE '"version":[[:space:]]*"10\.2\.0"' .claude-plugin/marketplace.json
```

**PASS criterion:** exit 0.

### FC-D-4 — Git tag `v10.2.0` exists

**REQ:** REQ-D-3, REQ-D-4

```bash
git rev-parse --verify v10.2.0 >/dev/null 2>&1
```

**PASS criterion:** exit 0 (tag exists).

---

## FC-E — Reliability Invariants (No Regression)

### FC-E-1 — All 17 `agents/*.md` retain `## Step Completion Invariants` section

**REQ:** REQ-E-1

```bash
count=$(grep -lE '^## Step Completion Invariants$' agents/*.md 2>/dev/null | wc -l | tr -d ' ')
test "$count" -eq 17
```

**PASS criterion:** exit 0 (17 agent files have the section).

### FC-E-2 — Step Completion completeness scenario passes

**REQ:** REQ-E-2

```bash
bash tests/scenarios/v10-step-completion-invariants-completeness.sh
```

**PASS criterion:** exit 0; stdout contains `PASS:` prefix.

### FC-E-3 — Harness reports 0 failed scenarios

**REQ:** REQ-E-3

```bash
output=$(./tests/harness/run-tests.sh 2>&1)
echo "$output" | grep -qE 'failed:[[:space:]]*0|0 failed|FAIL: 0'
```

**PASS criterion:** exit 0 (harness summary shows 0 failed).

### FC-E-4 — `core/lib/stage-invariant.sh` byte-identical to v10.1.2 HEAD

**REQ:** REQ-E-4

```bash
git diff v10.1.2 -- core/lib/stage-invariant.sh | wc -l | tr -d ' ' | grep -qE '^0$'
```

**PASS criterion:** exit 0 (zero diff lines vs v10.1.2 tag).

### FC-E-5 — 15 total `v10-*.sh` scenarios exist and all pass

**REQ:** REQ-E-5, REQ-C-1, REQ-C-2

```bash
count=$(ls tests/scenarios/v10-*.sh 2>/dev/null | wc -l | tr -d ' ')
test "$count" -eq 15 || { echo "Expected 15 v10-*.sh, found $count"; exit 1; }

failures=0
for s in tests/scenarios/v10-*.sh; do
  if ! bash "$s" >/dev/null 2>&1; then
    echo "FAIL: $s"
    failures=$((failures + 1))
  fi
done
test "$failures" -eq 0
```

**PASS criterion:** exit 0 (15 scenarios present, all pass).

---

## Aggregate Sanity Check

### FC-AGG-1 — Total FC count

```bash
# This spec defines:
#   FC-A: 6 (A-1..A-6 — A-6 added in spec-revision per Devil's f-da0003)
#   FC-B: 8 (B-1..B-8)
#   FC-C: 4 (C-1..C-4)
#   FC-D: 4 (D-1..D-4)
#   FC-E: 5 (E-1..E-5)
# Total: 27 FCs
echo "FC count: A=6 B=8 C=4 D=4 E=5 total=27"
```

This is informational, not a gating FC.

---

**STATUS: FORMAL-CRITERIA-COMPLETE**
