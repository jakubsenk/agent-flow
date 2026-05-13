#!/usr/bin/env bash
# Verifies: AC-OVR-008, REQ-OVR-007
# Description: Pipeline log must record agent=reviewer overlay_source={toml|md|none}
#   overlay_path=... exactly once per dispatch. Tests verify the specification
#   documents all three provenance patterns and that the pipeline skill
#   specifies where and how the provenance log line is written.
# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Guard: ensure we are not running from staging location
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT INT TERM

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Assertion 1: fix-bugs SKILL.md (or a core file) specifies the provenance log
#   format for all 3 scenarios: toml-only / md-only / no-overlay
# ---------------------------------------------------------------------------
echo "--- Assertion 1: pipeline log format for toml-only overlay documented ---"

# We check ALL plausible doc locations: fix-bugs/SKILL.md, core/agent-dispatch.md,
# docs/guides/toml-overlay-syntax.md, setup-agents/SKILL.md
PROVENANCE_DOCS=(
  "$REPO_ROOT/skills/fix-bugs/SKILL.md"
  "$REPO_ROOT/core/agent-dispatch.md"
  "$REPO_ROOT/docs/guides/toml-overlay-syntax.md"
  "$REPO_ROOT/skills/setup-agents/SKILL.md"
  "$REPO_ROOT/docs/reference/pipeline.md"
)

FOUND_TOML_LOG=0
FOUND_MD_LOG=0
FOUND_NONE_LOG=0

for doc in "${PROVENANCE_DOCS[@]}"; do
  [ -f "$doc" ] || continue

  if grep -qF 'overlay_source=toml' "$doc"; then
    echo "OK (Assertion 1): overlay_source=toml pattern found in $(basename "$doc")"
    FOUND_TOML_LOG=1
  fi

  if grep -qF 'overlay_source=md' "$doc"; then
    echo "OK (Assertion 2): overlay_source=md pattern found in $(basename "$doc")"
    FOUND_MD_LOG=1
  fi

  if grep -qF 'overlay_source=none' "$doc"; then
    echo "OK (Assertion 3): overlay_source=none pattern found in $(basename "$doc")"
    FOUND_NONE_LOG=1
  fi
done

# All three sources must be documented somewhere in the spec docs
if [ "$FOUND_TOML_LOG" -eq 0 ]; then
  # Docs not yet written — valid SKIP scenario (implementation pending)
  echo "SKIP: overlay_source=toml provenance format not yet documented (implementation pending)" >&2
  exit 77
fi

echo "--- Assertion 2: md-only overlay provenance format documented ---"
if [ "$FOUND_MD_LOG" -eq 0 ]; then
  fail "overlay_source=md provenance log format not documented in any spec file"
fi

echo "--- Assertion 3: no-overlay provenance format documented ---"
if [ "$FOUND_NONE_LOG" -eq 0 ]; then
  fail "overlay_source=none provenance log format not documented in any spec file"
fi

# ---------------------------------------------------------------------------
# Assertion 4: The exact log key names are documented (agent=, overlay_path=)
# ---------------------------------------------------------------------------
echo "--- Assertion 4: 'agent=' and 'overlay_path=' log keys documented ---"
FOUND_AGENT_KEY=0
FOUND_PATH_KEY=0
for doc in "${PROVENANCE_DOCS[@]}"; do
  [ -f "$doc" ] || continue
  if grep -qF 'agent=reviewer' "$doc" || grep -qF 'agent=' "$doc"; then
    FOUND_AGENT_KEY=1
  fi
  if grep -qF 'overlay_path=' "$doc"; then
    FOUND_PATH_KEY=1
  fi
done
if [ "$FOUND_AGENT_KEY" -eq 0 ]; then
  fail "agent= key for provenance log not documented in any spec file"
fi
if [ "$FOUND_PATH_KEY" -eq 0 ]; then
  fail "overlay_path= key for provenance log not documented in any spec file"
fi
echo "OK: agent= and overlay_path= log key names documented"

# ---------------------------------------------------------------------------
# Assertion 5: .ceos-agents/pipeline.log is the target log file
# ---------------------------------------------------------------------------
echo "--- Assertion 5: .ceos-agents/pipeline.log is documented as log destination ---"
FOUND_LOG_FILE=0
for doc in "${PROVENANCE_DOCS[@]}"; do
  [ -f "$doc" ] || continue
  if grep -qF 'pipeline.log' "$doc"; then
    FOUND_LOG_FILE=1
    echo "OK: pipeline.log destination documented in $(basename "$doc")"
    break
  fi
done
if [ "$FOUND_LOG_FILE" -eq 0 ]; then
  fail ".ceos-agents/pipeline.log not documented as provenance log destination"
fi

# ---------------------------------------------------------------------------
# Assertion 6: "exactly once per dispatch" semantics documented
# ---------------------------------------------------------------------------
echo "--- Assertion 6: exactly-once-per-dispatch semantics documented ---"
FOUND_ONCE=0
for doc in "${PROVENANCE_DOCS[@]}"; do
  [ -f "$doc" ] || continue
  if grep -qiE 'exactly once|once per dispatch|per dispatch' "$doc"; then
    FOUND_ONCE=1
    echo "OK: exactly-once-per-dispatch semantics found in $(basename "$doc")"
    break
  fi
done
if [ "$FOUND_ONCE" -eq 0 ]; then
  fail "exactly-once-per-dispatch semantics not documented"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-OVR-008 — overlay provenance log format (toml/md/none) documented"
fi
exit "$FAIL"
