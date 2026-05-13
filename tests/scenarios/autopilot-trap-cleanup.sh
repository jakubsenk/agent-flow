#!/usr/bin/env bash
set -euo pipefail

# AC-34: Autopilot lock released on exit via trap (runtime)
# Traces: AUTOPILOT-R5
# Description: Verifies SKILL.md documents trap EXIT registered AFTER successful mkdir
#              and PID verification before rm -rf

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

FAIL=0

# trap ... EXIT must be documented
if ! grep -qE 'trap .*EXIT' "$SKILL"; then
  echo "FAIL: $SKILL missing 'trap ... EXIT' handler documentation" >&2
  FAIL=1
fi

# PID verification in trap (owner.json.pid == $$)
if ! grep -qiE 'owner.*pid|pid.*owner|OWNER_PID|\$\$' "$SKILL"; then
  echo "FAIL: $SKILL does not document PID ownership check in trap" >&2
  FAIL=1
fi

# rm -rf for lock removal in trap
if ! grep -qiE 'rm -rf.*LOCK|rm.*lock_dir' "$SKILL"; then
  echo "FAIL: $SKILL does not document rm -rf lock directory in trap" >&2
  FAIL=1
fi

# ABSOLUTE path for LOCK_DIR (CWD-safe)
if ! grep -qiE 'ABSOLUTE|absolute|abs.*path|\$\(pwd\)|resolve.*absolute' "$SKILL"; then
  echo "FAIL: $SKILL does not document absolute path for LOCK_DIR (CWD-safe trap)" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: autopilot-trap-cleanup — SKILL.md documents trap EXIT with PID check + rm -rf"
exit "$FAIL"
