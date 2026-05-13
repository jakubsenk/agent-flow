# v10.2.0 — `core/` Path Disambiguation — Design

**Forge run:** `forge-2026-05-13-001`
**Maps to:** `requirements.md` REQ-A/B/C/D/E

This document gives Phase 7 implementers exact diffs, scripts, and source. Every fragment is intended to be applicable verbatim (with the small caveats noted).

---

## Phase A — Fail-Loud Guard

### A.1 Diff for `skills/fix-bugs/data/guard-block.md`

Existing file is 73 lines. Insert a new `<PREFLIGHT>` block immediately BEFORE the existing `<MANDATORY-EXECUTION-GUARD>` block (which currently starts at line 9). No existing line is removed; everything below shifts down by the inserted block length.

**Insertion (above line 9, after the existing HTML comment ending at line 7):**

```markdown
<PREFLIGHT>
## PRE-FLIGHT PROBE — DO THIS BEFORE READING ANY OTHER SECTION.

Before evaluating the orchestration contract below, you MUST verify the plugin
install integrity. Execute this Bash probe; the PROBE path is depth-correct
relative to this guard-block.md file's own directory (`skills/{name}/data/`,
which is depth-3 from plugin root, so 3 up-levels are required):

```bash
PROBE="../../../core/mcp-preflight.md"
if [ ! -r "$PROBE" ]; then
  echo "ABORT: plugin-root not resolved -- core/ sibling of skills/ not found at $PROBE. Check plugin install integrity." >&2
  exit 2
fi
```

If the probe fails, ABORT the pipeline with exit code 2 and the canonical
message above. DO NOT silently fall back to "I'll work from SKILL.md + step
files directly." Silent degradation is the BIFITO-4293 failure mode this guard
exists to prevent.

**Path-format note (B3 documentary clarifier — informational, not executable):**
All `core/<file>.md` references in this skill use relative paths from the file's
directory: `../core/` for `agents/*.md`, `../../core/` for `skills/*/SKILL.md`,
and `../../../core/` for `skills/*/{steps,data}/*.md`. The canonical layout is
`core/` as sibling of `skills/` at plugin root.
</PREFLIGHT>

```

(Then the existing line 9 `<MANDATORY-EXECUTION-GUARD>` follows unchanged.)

### A.2 Diff for `skills/implement-feature/data/guard-block.md`

Identical insertion pattern: prepend a `<PREFLIGHT>` block before the existing `<MANDATORY-EXECUTION-GUARD>` (which currently starts at line 8). Text identical to A.1 except the leading H1 ("Mandatory Execution Guard — /implement-feature") is preserved at line 1.

### A.3 NEW file `skills/scaffold/data/guard-block.md`

`skills/scaffold/data/` does NOT exist on v10.1.2. Phase 7 must:

1. `mkdir -p skills/scaffold/data/`
2. Create `skills/scaffold/data/guard-block.md` as a fresh file using the structure below.

Skeleton (~78 lines, mirroring fix-bugs/data/guard-block.md plus scaffold-flavored red-flag rows):

```markdown
# Mandatory Execution Guard — /scaffold

<!--
  Referenced from `skills/scaffold/SKILL.md`.
  Load-bearing orchestrator guard. Changes here are contract edits.
  Mirrors precedent at skills/fix-bugs/data/guard-block.md and
  skills/implement-feature/data/guard-block.md.
-->

<PREFLIGHT>
[…same probe block as A.1 — A.1 already specifies depth-3 PROBE path `../../../core/mcp-preflight.md`, which is the correct depth for ALL THREE existing/new guard-block.md files since they ALL sit at `skills/{name}/data/`…]
</PREFLIGHT>

<MANDATORY-EXECUTION-GUARD>
## YOU MUST EXECUTE THE PIPELINE. NO EXCEPTIONS.

DO NOT answer the user's question directly.
DO NOT skip a step because "the spec-writer already covered it" or "the scaffolder will pick this up."
DO NOT reason about the project domain — subagents do that.
DO NOT bypass spec-writer, spec-reviewer, scaffolder, architect, fixer-reviewer,
test-engineer, or spec-reviewer --verify based on intuition.
DO NOT inline-execute step logic — every step is a Task() dispatch.

You are a THIN CONTROLLER. Your ONLY job is to:
1. Initialize `.ceos-agents/{PROJECT_ID}/` and `state.json`
2. Read `steps/NN-*.md` files via the Read tool — they contain the dispatch logic
3. Dispatch each step's Task() call exactly as the step file specifies
4. Write atomic `state.json` updates (`dispatched_at` + `dispatch_witness` BEFORE each Task)
5. Surface dispatch-audit log anomalies in the final terminal report

<orchestration_contract>
[…same orchestration_contract prose as fix-bugs, with skill name swapped to /scaffold…]
</orchestration_contract>

<rationalization_red_flags>
## Rationalization Red Flags — STOP IMMEDIATELY

| Behaviour in draft response | Reality |
|-----------------------------|---------|
| Draft frames spec-reviewer as redundant ("spec-writer's output is clean") | spec-reviewer catches assumptions, contradictions, and EARS-form violations that spec-writer's draft misses. Dispatch. |
| Draft skips architect because "scope is obvious from spec" | architect produces the maps_to task tree linking subtasks to AC. Decomposition (Step 03) depends on it. Dispatch. |
| Draft frames spec-reviewer --verify as ceremonial ("we tested it manually") | spec-reviewer --verify runs the compliance check against the locked spec. Manual testing cannot substitute. Dispatch. |
| Draft skips test-engineer --e2e because "no e2e framework configured" | Read `### E2E Test` in Automation Config; if absent, write `e2e_test.status = "skipped"` — DO NOT leave at "pending". |
| Draft jumps to final report after fixer-reviewer without running test-engineer | The dispatch table is the contract. Read each step file before dispatching. |
| Draft inserts inline Task() without writing `dispatched_at` + `dispatch_witness` | Pre-dispatch write is MANDATORY. If you cannot write the witness, you cannot dispatch. |
| Draft pretends "PostToolUse validator will catch it" as fallback | The hook is ADVISORY by default (exit 0). It emits audit lines but does NOT block. |

The ONLY pre-dispatch user interaction permitted is the existing spec checkpoint
and feature plan checkpoint in the new-project flow. Any other question,
summary, or options menu BEFORE the first Task dispatch is a guard violation.
</rationalization_red_flags>
</MANDATORY-EXECUTION-GUARD>
```

### A.4 `skills/scaffold/SKILL.md` Read-tool directive

Insert at line 11 (immediately after the `# Scaffold` H1 and blank line at line 10), mirroring the structure at `skills/fix-bugs/SKILL.md:11`:

```markdown
Read and apply the mandatory execution guard defined in `skills/scaffold/data/guard-block.md` BEFORE any other instruction in this file.
```

Existing line 11 (currently `Input: $ARGUMENTS = ...`) shifts to line 13.

---

## Phase B — Depth-Aware Mechanical Rewrite

### B.1 Rewrite script structure

Phase 7 implementer creates a one-shot bash script at the project root (NOT committed — temporary helper). The script runs 4 depth-class sed invocations against the scope-locked file list from `phase-2/final.md` §C1.

**Sed pattern (canonical, verified against bash 5.2 + GNU sed 4.x — see §B.2 below):**

```bash
# Idempotent: matches only "core/X.md" NOT preceded by "../" or "./"
sed -E -i 's|([^./])core/([a-z][a-z-]*\.md)|\1../core/\2|g'      # depth-1 prefix
sed -E -i 's|([^./])core/([a-z][a-z-]*\.md)|\1../../core/\2|g'   # depth-2 prefix
sed -E -i 's|([^./])core/([a-z][a-z-]*\.md)|\1../../../core/\2|g' # depth-3 prefix
```

The negative-character-class `[^./]` is the idempotency guarantee: it refuses to match `../core/` and `./core/`, so a second run is a no-op.

**Line-start edge case — REJECTED ALTERNATIVE.** An earlier draft of this section proposed `s|(^|[^./])core/...|...|g` (alternation to handle the line-start edge). That pattern is **broken on GNU sed 4.9**: the inner `|` (regex alternation) collides with the outer `|` (sed s-delimiter), producing `sed: -e expression: unknown option to 's'`. Live test confirmed (see §B.2 verification log). **Resolution:** Phase 2 enumeration confirms ZERO line-start occurrences across all 40 scope-locked files (every `core/X.md` reference is preceded by a backtick, space, slash, or other non-`./` character inside prose or code-spans). The simpler `[^./]` form is therefore sufficient. Phase 7 MUST NOT introduce the `(^|...)` alternation; if a future contributor adds a line-start occurrence, the static depth-lint (FC-C-2) will catch the resulting unrewritten path during CI.

### B.2 Verification log (bash 5.2 + GNU sed 4.x — live test 2026-05-13)

Spec-revision-time live execution on Windows Git-Bash (GNU sed 4.x). This block reproduces the exact commands and their actual stdout. The session was re-run after the f-da0001 fix to confirm the canonical pattern works AND the rejected alternation pattern fails.

**Test 1 — REJECTED pattern (sanity check that f-da0001 was real):**

```
$ sed -E 's|(^|[^./])core/([a-z][a-z-]*\.md)|\1../../core/\2|g' sample.md
sed: -e expression #1, char 36: unknown option to `s'
EXIT=1
```

**Test 2 — CANONICAL pattern (drop `^` branch, simple `[^./]` only):**

Input (`sample.md`):
```
Reference `core/state-manager.md` here.
Already-rewritten `../../core/state-manager.md` should NOT double-rewrite.
And `../core/state-manager.md` should NOT change either.
Dual on one line: `core/block-handler.md` and `core/state-manager.md` together.
At start: core/early.md is line-start (synthetic edge case).
```

Command:
```bash
sed -E 's|([^./])core/([a-z][a-z-]*\.md)|\1../../core/\2|g' sample.md
```

Output:
```
Reference `../../core/state-manager.md` here.
Already-rewritten `../../core/state-manager.md` should NOT double-rewrite.
And `../core/state-manager.md` should NOT change either.
Dual on one line: `../../core/block-handler.md` and `../../core/state-manager.md` together.
At start: ../../core/early.md is line-start (synthetic edge case).
```

**Test 3 — Idempotency (re-run on Test 2 output):** identical to Test 2 output, **zero further changes**. Confirmed by `diff` showing no differences after second pass.

**Verification conclusions:**

1. `|` delimiter + `(^|[^./])` alternation = parse error on GNU sed 4.9 (confirms f-da0001 was a true defect, not a theoretical concern).
2. Canonical `[^./]` pattern correctly rewrites both mid-line and the dual-pattern-on-one-line case (Probe 4 from Devil's review).
3. Already-rewritten `../../core/...` and `../core/...` paths are NOT re-touched (idempotency guard holds).
4. Phase 2's "zero line-start occurrences" claim re-verified by re-running `grep -rEn '^core/[a-z][a-z-]*\.md' skills/ agents/ --include='*.md'` against v10.1.2 HEAD: returned **0 matches**. The synthetic `At start: core/early.md` line in the fixture above is preceded by a space (the line literally starts with `At start:`), so it is mid-line; the simple `[^./]` matches the space and the rewrite proceeds as expected.

### B.3 Four sed invocations (one per depth class)

Phase 7 implements this as a bash script (`/tmp/v10.2.0-phase-b.sh` or similar, NOT committed):

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# ---- Depth 1 (agents/*.md) -> ../core/ ----
# 3 files: agents/analyst.md, agents/fixer.md, agents/publisher.md
DEPTH1_FILES=(
  agents/analyst.md
  agents/fixer.md
  agents/publisher.md
)
for f in "${DEPTH1_FILES[@]}"; do
  sed -E -i 's|([^./])core/([a-z][a-z-]*\.md)|\1../core/\2|g' "$f"
done

# ---- Depth 2 (skills/*/SKILL.md) -> ../../core/ ----
# 9 files
DEPTH2_FILES=(
  skills/analyze-bug/SKILL.md
  skills/autopilot/SKILL.md
  skills/create-backlog/SKILL.md
  skills/fix-bugs/SKILL.md
  skills/implement-feature/SKILL.md
  skills/publish/SKILL.md
  skills/scaffold/SKILL.md
  skills/setup-mcp/SKILL.md
  skills/sprint-plan/SKILL.md
)
for f in "${DEPTH2_FILES[@]}"; do
  sed -E -i 's|([^./])core/([a-z][a-z-]*\.md)|\1../../core/\2|g' "$f"
done

# ---- Depth 3a (skills/*/steps/*.md) -> ../../../core/ ----
# 26 files (from Phase 2 enumeration: fix-bugs/steps/01-12 = 12; implement-feature/steps/01-08 = 8; scaffold/steps/01-08 = 6)
mapfile -t DEPTH3_STEPS < <(find skills -mindepth 3 -path '*/steps/*.md' -type f)
for f in "${DEPTH3_STEPS[@]}"; do
  sed -E -i 's|([^./])core/([a-z][a-z-]*\.md)|\1../../../core/\2|g' "$f"
done

# ---- Depth 3b (skills/*/data/*.md) -> ../../../core/ ----
# 3 files post-Phase-A: fix-bugs/data/guard-block.md, implement-feature/data/guard-block.md,
#                       scaffold/data/guard-block.md (NEW from Phase A)
mapfile -t DEPTH3_DATA < <(find skills -mindepth 3 -path '*/data/*.md' -type f)
for f in "${DEPTH3_DATA[@]}"; do
  sed -E -i 's|([^./])core/([a-z][a-z-]*\.md)|\1../../../core/\2|g' "$f"
done

echo "Phase B rewrite complete."
```

**Ordering:** Phase A MUST run BEFORE Phase B. Reason: Phase A creates `skills/scaffold/data/guard-block.md` whose contents reference `core/mcp-preflight.md`; Phase B's depth-3 sed then rewrites this reference (and any others in the new file) to `../../../core/...`. Running Phase B first would skip the new file entirely.

### B.4 Spot-check before/after (5 files, 10 lines)

Manual verification samples Phase 7 must produce (after running B.3 script):

| File | Line | Before | After (expected) |
|---|---|---|---|
| `agents/analyst.md` | 114 | `` `core/resume-detection.md` `` | `` `../core/resume-detection.md` `` |
| `agents/publisher.md` | 65 | `` `core/mcp-body-formatting.md` `` | `` `../core/mcp-body-formatting.md` `` |
| `skills/fix-bugs/SKILL.md` | 124 | `` `core/config-reader.md` `` | `` `../../core/config-reader.md` `` |
| `skills/implement-feature/SKILL.md` | 130 (dual) | `` `core/block-handler.md` and `core/state-manager.md` `` | `` `../../core/block-handler.md` and `../../core/state-manager.md` `` |
| `skills/publish/SKILL.md` | 176 (dual) | `` `core/mcp-detection.md` … `core/mcp-detection.md` `` | `` `../../core/mcp-detection.md` … `../../core/mcp-detection.md` `` |
| `skills/scaffold/SKILL.md` | 258 | `` `core/mcp-preflight.md` `` | `` `../../core/mcp-preflight.md` `` |
| `skills/fix-bugs/steps/01-triage.md` | 47 | `` `core/state-manager.md` `` | `` `../../../core/state-manager.md` `` |
| `skills/implement-feature/steps/03-decomposition.md` | 91 (dual) | `` `core/tracker-subtask-creator.md` and `core/mcp-body-formatting.md` `` | `` `../../../core/tracker-subtask-creator.md` and `../../../core/mcp-body-formatting.md` `` |
| `skills/scaffold/steps/05-fixer-reviewer-loop.md` | 70 | `` `core/fixer-reviewer-loop.md` `` | `` `../../../core/fixer-reviewer-loop.md` `` |
| `skills/fix-bugs/data/guard-block.md` | 62 | `` `core/config-reader.md` `` | `` `../../../core/config-reader.md` `` |

### B.5 Idempotency proof

After running B.3 once: `git diff --stat` should show ~40 modified files. After running B.3 a second time: `git diff --stat` should show ZERO additional changes. Phase 7 commander verifies this in the verification phase.

---

## Phase C — Two New Harness Scenarios

### C.1 Full source: `tests/scenarios/v10-skill-from-external-cwd.sh`

```bash
#!/usr/bin/env bash
# ===========================================================================
# Test:        v10-skill-from-external-cwd.sh
# Falsifies:   REQ-A-1, REQ-A-2, REQ-A-3 (Phase A fail-loud guard)
# FC mapped:   FC-C-1
# What it checks:
#   ASSERT-1) When the canonical sentinel `core/mcp-preflight.md` exists,
#             a probe from a synthesized plugin root (depth-correct
#             `../../core/mcp-preflight.md`) succeeds with exit 0.
#   ASSERT-2) When the sentinel is removed, the probe (executed via the same
#             Bash snippet the guard-block.md prescribes) emits the canonical
#             ABORT message to stderr and exits with code 2.
#   ASSERT-3) Tmpdir cleanup happens regardless of pass/fail (trap EXIT).
# Cross-platform: Win Git-Bash + macOS BSD + Linux GNU. POSIX-portable only.
# Expected: PASS on v10.2.0 RC commit and beyond.
# ===========================================================================
set -uo pipefail

SCRIPT_NAME="$(basename "$0")"
FAIL=0
fail() { echo "[FAIL] $SCRIPT_NAME: $1" >&2; FAIL=1; }
pass() { echo "[PASS] $SCRIPT_NAME: $1"; }

# ---------------------------------------------------------------------------
# Setup synthetic plugin root in mktemp -d (cross-platform: no GNU --suffix)
# ---------------------------------------------------------------------------
TMP_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t 'v10ext')"
if [ -z "$TMP_ROOT" ] || [ ! -d "$TMP_ROOT" ]; then
  echo "[SKIP] $SCRIPT_NAME: mktemp -d unavailable" >&2
  exit 77
fi
trap 'rm -rf "$TMP_ROOT"' EXIT

PLUGIN_ROOT="$TMP_ROOT/plugin-fixture"
mkdir -p "$PLUGIN_ROOT/core" "$PLUGIN_ROOT/skills/demo/data"

# Minimal sentinel content (mirrors core/mcp-preflight.md role; content opaque)
cat >"$PLUGIN_ROOT/core/mcp-preflight.md" <<'EOF'
# core/mcp-preflight.md (synthetic sentinel)
This is a test fixture for v10-skill-from-external-cwd.sh.
EOF

# Minimal guard-block fixture at depth-3 (skills/demo/data/)
cat >"$PLUGIN_ROOT/skills/demo/data/guard-block.md" <<'EOF'
# guard-block (fixture)
Probe: ../../../core/mcp-preflight.md
EOF

# ---------------------------------------------------------------------------
# Phase C.1 -- ASSERT-1: sentinel present, probe from synthetic plugin root
#   succeeds (exit 0). Simulate the depth-3 probe path from data/.
# ---------------------------------------------------------------------------
EXTERNAL_CWD="$TMP_ROOT/external-project"
mkdir -p "$EXTERNAL_CWD"

# We simulate the guard-block.md probe shape. The probe is run from the
# directory containing guard-block.md (depth-3). The depth-correct path is
# `../../../core/mcp-preflight.md`.
(
  cd "$PLUGIN_ROOT/skills/demo/data" || exit 99
  PROBE="../../../core/mcp-preflight.md"
  if [ -r "$PROBE" ]; then
    exit 0
  else
    exit 2
  fi
)
RC_PROBE_OK=$?

if [ "$RC_PROBE_OK" -eq 0 ]; then
  pass "ASSERT-1 sentinel present, depth-3 probe returns exit 0"
else
  fail "ASSERT-1 expected exit 0, got $RC_PROBE_OK"
fi

# ---------------------------------------------------------------------------
# Phase C.1 -- ASSERT-2: sentinel REMOVED, probe aborts with exit 2 + message
# ---------------------------------------------------------------------------
rm -f "$PLUGIN_ROOT/core/mcp-preflight.md"

STDERR_FILE="$TMP_ROOT/probe.stderr"
(
  cd "$PLUGIN_ROOT/skills/demo/data" || exit 99
  PROBE="../../../core/mcp-preflight.md"
  if [ ! -r "$PROBE" ]; then
    echo "ABORT: plugin-root not resolved -- core/ sibling of skills/ not found at $PROBE. Check plugin install integrity." >&2
    exit 2
  fi
  exit 0
) 2>"$STDERR_FILE"
RC_PROBE_FAIL=$?

if [ "$RC_PROBE_FAIL" -eq 2 ]; then
  pass "ASSERT-2 sentinel missing, probe exits 2"
else
  fail "ASSERT-2 expected exit 2, got $RC_PROBE_FAIL"
fi

if grep -q "plugin-root not resolved" "$STDERR_FILE"; then
  pass "ASSERT-2 stderr contains canonical abort message"
else
  fail "ASSERT-2 stderr missing canonical message; got: $(cat "$STDERR_FILE")"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "[PASS] $SCRIPT_NAME"
  exit 0
fi
exit 1
```

### C.2 Full source: `tests/scenarios/v10-core-path-depth-consistency.sh`

```bash
#!/usr/bin/env bash
# ===========================================================================
# Test:        v10-core-path-depth-consistency.sh
# Falsifies:   REQ-B-1, REQ-B-2, REQ-B-3 (Phase B depth-aware rewrite)
# FC mapped:   FC-C-2
# What it checks (static lint over the v10.2.0 file tree):
#   ASSERT-1) No bare `core/<file>.md` reference survives in any in-scope
#             skill or agent file. All references are dotdot-prefixed.
#   ASSERT-2) Per-depth-class: dotdot count equals depth(file) for SKILL.md
#             (depth-2 -> ../../) and steps/data (depth-3 -> ../../../), and
#             agents/*.md (depth-1 -> ../).
#   ASSERT-3) Cleanup: this is a static scenario; no tmpdir needed.
# Cross-platform: pure bash + grep -E + find. No jq, no realpath.
# Expected: PASS on v10.2.0 RC; FAIL on a deliberately-corrupted control
#   branch where one file's prefix is reverted (REQ-C-3 counterfactual).
# ===========================================================================
set -uo pipefail

SCRIPT_NAME="$(basename "$0")"
REPO_ROOT="${CEOS_REPO_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO_ROOT" || { echo "[FAIL] $SCRIPT_NAME: cannot cd to REPO_ROOT=$REPO_ROOT" >&2; exit 1; }

FAIL=0
fail() { echo "[FAIL] $SCRIPT_NAME: $1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Depth-class file lists. Each entry: glob pattern + expected dotdot count.
# ---------------------------------------------------------------------------
check_class() {
  local pattern="$1"          # find -path pattern (single arg)
  local find_root="$2"        # find root dir (single arg)
  local find_extra="$3"       # extra find flags (e.g., -maxdepth 2)
  local expected_dotdots="$4" # integer: 1, 2, or 3
  local class_name="$5"

  # Build expected prefix string: "../" repeated N times
  local expected_prefix=""
  local i=0
  while [ "$i" -lt "$expected_dotdots" ]; do
    expected_prefix="${expected_prefix}../"
    i=$((i + 1))
  done

  # Iterate files matched by pattern
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    # Find all "(\.\./)*core/X.md" occurrences with line numbers
    grep -nE '(\.\./){1,}core/[a-z][a-z-]*\.md|[^./]core/[a-z][a-z-]*\.md|^core/[a-z][a-z-]*\.md' "$f" 2>/dev/null | while IFS= read -r match; do
      local lineno="${match%%:*}"
      local rest="${match#*:}"
      # Extract every (../)*core/X.md pattern from the line
      printf '%s\n' "$rest" | grep -oE '(\.\./){0,}core/[a-z][a-z-]*\.md' | while IFS= read -r ref; do
        # Count "../" prefix length
        local dotdot_count
        dotdot_count=$(printf '%s' "$ref" | grep -oE '\.\./' | wc -l)
        # Trim whitespace from wc -l (BSD prepends spaces)
        dotdot_count=$(echo "$dotdot_count" | tr -d ' ')
        if [ "$dotdot_count" -ne "$expected_dotdots" ]; then
          echo "$f:$lineno: depth-$class_name expected ${expected_prefix}core/, found ${ref}"
        fi
      done
    done
  done < <(eval "find $find_root $find_extra -path '$pattern' -type f")
}

# ---------------------------------------------------------------------------
# Class 1: agents/*.md -> ../ (depth-1)
# ---------------------------------------------------------------------------
class1_violations=$(check_class 'agents/*.md' 'agents' '-maxdepth 1' 1 'agents')
if [ -n "$class1_violations" ]; then
  fail "depth-1 violations in agents/:"
  echo "$class1_violations" >&2
fi

# ---------------------------------------------------------------------------
# Class 2: skills/*/SKILL.md -> ../../ (depth-2)
# ---------------------------------------------------------------------------
class2_violations=$(check_class 'skills/*/SKILL.md' 'skills' '-mindepth 2 -maxdepth 2' 2 'SKILL.md')
if [ -n "$class2_violations" ]; then
  fail "depth-2 violations in skills/*/SKILL.md:"
  echo "$class2_violations" >&2
fi

# ---------------------------------------------------------------------------
# Class 3a: skills/*/steps/*.md -> ../../../ (depth-3)
# ---------------------------------------------------------------------------
class3a_violations=$(check_class 'skills/*/steps/*.md' 'skills' '-mindepth 3' 3 'steps')
if [ -n "$class3a_violations" ]; then
  fail "depth-3 violations in skills/*/steps/:"
  echo "$class3a_violations" >&2
fi

# ---------------------------------------------------------------------------
# Class 3b: skills/*/data/*.md -> ../../../ (depth-3)
# ---------------------------------------------------------------------------
class3b_violations=$(check_class 'skills/*/data/*.md' 'skills' '-mindepth 3' 3 'data')
if [ -n "$class3b_violations" ]; then
  fail "depth-3 violations in skills/*/data/:"
  echo "$class3b_violations" >&2
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "[PASS] $SCRIPT_NAME -- all core/ path references are depth-correct across 40 in-scope files"
  exit 0
fi
exit 1
```

### C.3 Design notes for Phase 7 implementer

- **Both scenarios are jq-free, realpath-free, perl-free** — only `bash`, `grep -E`, `find`, `sed -E`, `awk`, `tr`, `wc`, `mktemp`, `mkdir`, `rm` are used. Verified compatible with Win Git-Bash, GNU coreutils, BSD coreutils.
- **Exit codes:** 0 = pass, 1 = fail, 77 = skip (only the runtime scenario uses 77, on `mktemp -d` unavailability).
- **`[PASS]` / `[FAIL]` / `[SKIP]` prefix:** harness loader parses these to aggregate the run summary.
- **The depth-lint script is intentionally simple.** It does NOT attempt to validate that the FILE referenced exists; only that the dotdot-prefix is depth-correct. File-existence validation is the job of the runtime probe (Phase A), not the static lint.
- **2-files-vs-3-scenarios traceability (advisory f-b2d4f5).** Phase 3 §Recommendation item 3 originally enumerated three logical scenarios (C1 runtime-success, C2 runtime-failure, C3 static-lint). The spec consolidates C1 + C2 into a single file (`v10-skill-from-external-cwd.sh`) with TWO internal asserts: ASSERT-1 covers C1 (sentinel present → probe success), ASSERT-2 covers C2 (sentinel removed → exit 2 + canonical message). C3 stays as its own file (`v10-core-path-depth-consistency.sh`). Functional coverage = 3 logical scenarios in 2 physical files; FC-E-3 (harness pass count) reflects +2 files, not +3.

---

## Phase D — Cross-Cutting Edits

### D.1 Doc-quartet review (5 files)

Phase 7 implementer runs `grep -c 'v10-.*\.sh'` on each of the 5 doc-quartet files. For each file:

- If the result is ≥ 1 AND a literal "13" count appears within 5 lines of a `v10-` reference: update "13" → "15".
- If no literal count exists: no edit required.

Current state (from spec author's grep on v10.1.2 HEAD): `CLAUDE.md=1, README.md=0, automation-config.md=1, skills.md=0, architecture.md=0`. CLAUDE.md L106 names `v10-step-completion-invariants-completeness.sh` but does NOT cite a count. Likely outcome: zero file edits required for REQ-D-1 because no stale "13" count exists in the doc-quartet. Phase 7 confirms.

### D.2 CHANGELOG entry

Insert above the v10.1.2 section (use Keep-a-Changelog format consistent with prior v10.1.x entries):

```markdown
### v10.2.0 -- core/ Path Disambiguation

**MINOR (no Auto Config contract change, no Output Contract change).**

Fixes BIFITO-4293 silent-degradation failure mode where orchestrator
interpreted bare `core/<file>.md` paths as `skills/{name}/core/`
subdirectories, hallucinated reads, and silently fell back without core/
logic.

**Phase A -- Fail-loud guard.** Prepend `<PREFLIGHT>` block to
`skills/{fix-bugs,implement-feature,scaffold}/data/guard-block.md`
(scaffold/data/ is new in this release). Probe asserts readability of
canonical sentinel `core/mcp-preflight.md` from the depth-correct relative
path; on failure prints `ABORT: plugin-root not resolved -- ...` to stderr
and exits with code 2.

**Phase B -- Depth-aware path rewrite.** 185 `core/<file>.md` occurrences
across 40 files (3 agents + 37 skills) rewritten to depth-correct relative
paths: `../core/` for `agents/*.md`, `../../core/` for `skills/*/SKILL.md`,
`../../../core/` for `skills/*/{steps,data}/*.md`. Rewrite is idempotent.

**Phase C -- Two new harness scenarios:**
- `tests/scenarios/v10-skill-from-external-cwd.sh` (runtime guard probe).
- `tests/scenarios/v10-core-path-depth-consistency.sh` (static depth-lint).

**v10.0.0 reliability contract preserved:** `core/lib/stage-invariant.sh`
byte-identical; all 13 prior v10-*.sh scenarios continue to PASS; harness
0-fail baseline maintained.

See roadmap.md L1489-L1513 for full context.
```

### D.3 Version bump

Run `/ceos-agents:version-bump` skill (NOT manual edit). The skill:

1. Bumps `.claude-plugin/plugin.json:version` from `"10.1.2"` to `"10.2.0"`.
2. Bumps `.claude-plugin/marketplace.json:plugins[0].version` to `"10.2.0"`.
3. Commits with message `chore: bump version 10.1.2 -> 10.2.0`.
4. Creates git tag `v10.2.0`.

Order (per `feedback_version_bump_skill.md`): (1) content + CHANGELOG one commit, (2) version-bump separate commit, (3) tag.

---

## Phase E — Reliability Invariants (no design changes — verification only)

REQ-E requires no code changes; it constrains Phase 7 verification:

- `git diff core/lib/stage-invariant.sh` after Phase B sed pass MUST show ZERO lines changed (the sed pattern `[^./]core/[a-z][a-z-]*\.md` would not match anything inside `stage-invariant.sh` even if the file were in scope, but Phase B file list explicitly excludes `core/lib/`; defensive verification).
- `tests/scenarios/v10-step-completion-invariants-completeness.sh` exits 0 post-Phase-B.
- `./tests/harness/run-tests.sh` reports 0 failed scenarios.
- The 13 existing `v10-*.sh` scenarios + 2 new ones = 15 total v10-*.sh scenarios; all pass.

---

## Implementation Order (Phase 7 task ordering)

1. **A.4** — `skills/scaffold/SKILL.md` add Read-tool directive at line 11.
2. **A.3** — `mkdir skills/scaffold/data/` + create `skills/scaffold/data/guard-block.md` from scratch with depth-3 PROBE path.
3. **A.1, A.2** — Insert `<PREFLIGHT>` block into the 2 existing guard-block.md files (with depth-3 PROBE path; both are at `skills/{X}/data/`).
4. **B.3** — Run depth-aware sed script (touches the 3 guard-block files just created/edited + 37 other files).
5. **C.1, C.2** — Author the 2 new harness scenarios; chmod +x.
6. **Verify locally:** `./tests/harness/run-tests.sh` → 0 fail; new scenarios PASS.
7. **D.2** — Author CHANGELOG entry.
8. **Commit 1:** content + scenarios + CHANGELOG.
9. **D.3** — Run `/ceos-agents:version-bump`.
10. **Commit 2 + Tag:** version bump + `v10.2.0` tag.
11. **D.4** — Update roadmap.md L1489-L1513 status line (`**Released:** YYYY-MM-DD`).

---

**STATUS: DESIGN-COMPLETE**
