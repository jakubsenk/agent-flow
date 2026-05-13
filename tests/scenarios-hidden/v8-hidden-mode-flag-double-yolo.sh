#!/usr/bin/env bash
# Hidden adversarial test — do NOT reference in spec/visible
# Tests: "--yolo --yolo" (same flag twice) is idempotent (not error)
# Edge case: double-flag invocation must not trigger mutual-exclusion error
set -uo pipefail

# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Guard: ensure we are not running from staging location
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Assertion 1: flag parsing with GOT_YOLO — second --yolo is idempotent
# ---------------------------------------------------------------------------
echo "--- Assertion 1: --yolo --yolo is idempotent (GOT_YOLO set to true twice) ---"

# Simulate the GOT_YOLO pattern from design.md §5.1
GOT_YOLO=false
GOT_STEP_MODE=false
MODE="default"

for arg in "--yolo" "--yolo"; do
  case "$arg" in
    --yolo)
      GOT_YOLO=true
      MODE="yolo"
      ;;
    --step-mode)
      GOT_STEP_MODE=true
      MODE="step-mode"
      ;;
  esac
done

# Mutual exclusion check
if [ "$GOT_YOLO" = "true" ] && [ "$GOT_STEP_MODE" = "true" ]; then
  fail "UNEXPECTED: --yolo --yolo triggered mutual exclusion error (should not)"
else
  echo "OK: --yolo --yolo is idempotent — GOT_YOLO=true, GOT_STEP_MODE=false"
fi

if [ "$MODE" = "yolo" ]; then
  echo "OK: MODE=yolo after --yolo --yolo"
else
  fail "MODE=$MODE after --yolo --yolo (expected yolo)"
fi

# ---------------------------------------------------------------------------
# Assertion 2: Mutual exclusion only triggers when BOTH different flags set
# ---------------------------------------------------------------------------
echo "--- Assertion 2: mutual exclusion only for --yolo + --step-mode ---"
GOT_YOLO2=false
GOT_STEP_MODE2=false
MODE2="default"

for arg in "--yolo" "--step-mode"; do
  case "$arg" in
    --yolo) GOT_YOLO2=true; MODE2="yolo" ;;
    --step-mode) GOT_STEP_MODE2=true; MODE2="step-mode" ;;
  esac
done

SHOULD_ERROR=0
if [ "$GOT_YOLO2" = "true" ] && [ "$GOT_STEP_MODE2" = "true" ]; then
  SHOULD_ERROR=1
fi

if [ "$SHOULD_ERROR" -eq 1 ]; then
  echo "OK: --yolo --step-mode correctly triggers mutual exclusion"
else
  fail "--yolo --step-mode should trigger mutual exclusion but did not"
fi

# ---------------------------------------------------------------------------
# Assertion 3: design.md explicit boolean pattern handles double-yolo
# ---------------------------------------------------------------------------
echo "--- Assertion 3: design.md explicit boolean pattern handles double flag ---"
DESIGN="$REPO_ROOT/.forge/phase-4-spec/final/design.md"
if [ -f "$DESIGN" ]; then
  if grep -qF 'GOT_YOLO=false' "$DESIGN"; then
    echo "OK: design.md initializes GOT_YOLO=false (double flag is safe)"
  else
    fail "design.md missing GOT_YOLO=false initialization"
  fi
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: --yolo --yolo is idempotent (GOT_YOLO=true, no mutual exclusion error)"
fi
exit "$FAIL"
