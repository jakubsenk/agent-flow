#!/usr/bin/env bash
# Test: Phase 2 config contract — Local Deployment section, check-deploy command, state schema deployment fields
# Validates FC-047 to FC-051, FC-060 to FC-070, FC-072, FC-075
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

CONFIG_READER="$REPO_ROOT/core/config-reader.md"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
ONBOARD="$REPO_ROOT/commands/onboard.md"
CHECK_SETUP="$REPO_ROOT/commands/check-setup.md"
CHECK_DEPLOY="$REPO_ROOT/commands/check-deploy.md"
STATE_SCHEMA="$REPO_ROOT/state/schema.md"
ROADMAP="$REPO_ROOT/docs/plans/roadmap.md"

# ── FC-047: core/config-reader.md has Local Deployment parsing rules ───────────
if [ ! -f "$CONFIG_READER" ]; then
  fail "FC-047: core/config-reader.md does not exist"
else
  if ! grep -q 'Local Deployment' "$CONFIG_READER"; then
    fail "FC-047: core/config-reader.md missing '### Local Deployment' section"
  fi
  # Check all 6 required keys are mentioned
  for key in 'Type' 'Start command' 'Stop command' 'Health check URL' 'Health check timeout' 'Ports'; do
    if ! grep -qi "$key" "$CONFIG_READER"; then
      fail "FC-047: core/config-reader.md Local Deployment missing key: '$key'"
    fi
  done
fi

# ── FC-048: config-reader.md defaults Health check timeout = 60, others = none ─
if [ -f "$CONFIG_READER" ]; then
  if ! grep -q '60' "$CONFIG_READER"; then
    fail "FC-048: core/config-reader.md Local Deployment missing default 'Health check timeout = 60'"
  fi
  # Verify section is documented as fully optional
  if ! grep -qi 'optional\|absent\|if.*present\|if.*missing' "$CONFIG_READER"; then
    fail "FC-048: core/config-reader.md does not document Local Deployment as optional"
  fi
fi

# ── FC-049: CLAUDE.md optional sections table has Local Deployment row ─────────
if [ -f "$CLAUDE_MD" ]; then
  if ! grep -q 'Local Deployment' "$CLAUDE_MD"; then
    fail "FC-049: CLAUDE.md Config Contract optional sections table missing 'Local Deployment' row"
  fi
  # Verify it appears in the optional (not required) section context
  local_deploy_line=$(grep -n 'Local Deployment' "$CLAUDE_MD" | head -1 | cut -d: -f1)
  if [ -z "$local_deploy_line" ]; then
    fail "FC-049: CLAUDE.md has no 'Local Deployment' entry at all"
  fi
  # Check that the key names appear nearby
  local_block=$(sed -n "$((local_deploy_line > 2 ? local_deploy_line - 2 : 1)),$((local_deploy_line + 5))p" "$CLAUDE_MD")
  if ! echo "$local_block" | grep -qi 'Type\|Start command\|Stop command\|Health check'; then
    fail "FC-049: CLAUDE.md Local Deployment row does not list required keys (Type, Start command, Stop command, Health check URL, Health check timeout, Ports)"
  fi
fi

# ── FC-050: onboard.md Step 6 multi-select has Local Deployment entry ──────────
if [ ! -f "$ONBOARD" ]; then
  fail "FC-050: commands/onboard.md does not exist"
else
  if ! grep -q 'Local Deployment' "$ONBOARD"; then
    fail "FC-050: onboard.md Step 6 multi-select checklist missing 'Local Deployment' entry"
  fi
fi

# ── FC-051: check-setup.md Block 1 Step 5 includes Local Deployment ───────────
if [ ! -f "$CHECK_SETUP" ]; then
  fail "FC-051: commands/check-setup.md does not exist"
else
  if ! grep -q 'Local Deployment' "$CHECK_SETUP"; then
    fail "FC-051: check-setup.md Block 1 optional sections list missing 'Local Deployment' with format validation"
  fi
fi

# ── FC-060: commands/check-deploy.md exists ───────────────────────────────────
if [ ! -f "$CHECK_DEPLOY" ]; then
  fail "FC-060: commands/check-deploy.md does not exist"
fi

# ── FC-061: check-deploy.md frontmatter has description and allowed-tools ──────
if [ -f "$CHECK_DEPLOY" ]; then
  if ! grep -q "^description:" "$CHECK_DEPLOY"; then
    fail "FC-061: check-deploy.md frontmatter missing 'description' field"
  fi
  if ! grep -q "^allowed-tools:" "$CHECK_DEPLOY"; then
    fail "FC-061: check-deploy.md frontmatter missing 'allowed-tools' field"
  fi
fi

# ── FC-062: check-deploy.md allowed-tools includes Bash, Read ─────────────────
if [ -f "$CHECK_DEPLOY" ]; then
  allowed_tools=$(grep "^allowed-tools:" "$CHECK_DEPLOY" || true)
  if ! echo "$allowed_tools" | grep -q 'Bash'; then
    fail "FC-062: check-deploy.md allowed-tools does not include 'Bash'"
  fi
  if ! echo "$allowed_tools" | grep -q 'Read'; then
    fail "FC-062: check-deploy.md allowed-tools does not include 'Read'"
  fi
fi

# ── FC-063: check-deploy.md handles --start, --stop, and default ──────────────
if [ -f "$CHECK_DEPLOY" ]; then
  if ! grep -q -- '--start' "$CHECK_DEPLOY"; then
    fail "FC-063: check-deploy.md missing '--start' flag handling"
  fi
  if ! grep -q -- '--stop' "$CHECK_DEPLOY"; then
    fail "FC-063: check-deploy.md missing '--stop' flag handling"
  fi
fi

# ── FC-064: check-deploy.md has Steps 1-5 covering key actions ────────────────
if [ -f "$CHECK_DEPLOY" ]; then
  step_count=$(grep -c '^### Step [0-9]\|^## Step [0-9]\|^\*\*Step [0-9]' "$CHECK_DEPLOY" || true)
  if [ "$step_count" -lt 4 ]; then
    # Fallback: count numbered steps in general
    step_count=$(grep -c '^[0-9]\+\.' "$CHECK_DEPLOY" || true)
    if [ "$step_count" -lt 4 ]; then
      fail "FC-064: check-deploy.md has fewer than 4 steps (expected Steps 1-5 covering: port check, action, health check, docker status, report)"
    fi
  fi
  if ! grep -qi 'port.*check\|check.*port' "$CHECK_DEPLOY"; then
    fail "FC-064: check-deploy.md missing step: port check"
  fi
  if ! grep -qi 'health.*check\|health.*poll' "$CHECK_DEPLOY"; then
    fail "FC-064: check-deploy.md missing step: health check"
  fi
fi

# ── FC-065: check-deploy.md Port Check has cross-platform commands ─────────────
if [ -f "$CHECK_DEPLOY" ]; then
  if ! grep -q 'lsof' "$CHECK_DEPLOY"; then
    fail "FC-065: check-deploy.md Port Check missing 'lsof' (macOS/Linux cross-platform detection)"
  fi
  if ! grep -q 'ss\|netstat' "$CHECK_DEPLOY"; then
    fail "FC-065: check-deploy.md Port Check missing 'ss' or 'netstat' (Linux cross-platform detection)"
  fi
fi

# ── FC-066: check-deploy.md shows "No Local Deployment section" and STOPs ──────
if [ -f "$CHECK_DEPLOY" ]; then
  if ! grep -qi 'No Local Deployment\|no.*local.*deployment\|Local Deployment.*absent\|absent.*Local Deployment' "$CHECK_DEPLOY"; then
    fail "FC-066: check-deploy.md missing 'No Local Deployment section' message for absent config"
  fi
fi

# ── FC-067: check-deploy.md Rules/Constraints has "NEVER modify source code" ───
if [ -f "$CHECK_DEPLOY" ]; then
  if ! grep -qi 'NEVER.*modify.*source\|NEVER.*source.*code\|never.*change.*source' "$CHECK_DEPLOY"; then
    fail "FC-067: check-deploy.md Rules/Constraints missing 'NEVER modify source code'"
  fi
fi

# ── FC-068: check-deploy.md Step 2 blocks start on port conflict ──────────────
if [ -f "$CHECK_DEPLOY" ]; then
  if ! grep -qi 'port.*conflict\|conflict.*port\|occupied.*port\|port.*occupied' "$CHECK_DEPLOY"; then
    fail "FC-068: check-deploy.md missing port conflict blocking logic (does not block start on occupied port)"
  fi
  # Ensure it doesn't silently overwrite — look for explicit stop/block language
  if ! grep -qi 'do not.*start\|block.*start\|stop.*start\|refuse.*start\|STOP\|abort' "$CHECK_DEPLOY"; then
    fail "FC-068: check-deploy.md port conflict handler does not explicitly block/abort start"
  fi
fi

# ── FC-069: state/schema.md JSON has deployment object with required fields ────
if [ ! -f "$STATE_SCHEMA" ]; then
  fail "FC-069: state/schema.md does not exist"
else
  if ! grep -q '"deployment"' "$STATE_SCHEMA"; then
    fail "FC-069: state/schema.md Full Schema Example JSON missing '\"deployment\"' object"
  fi
  for field in '"status"' '"verdict"' '"ports"' '"health_check"'; do
    if ! grep -q "$field" "$STATE_SCHEMA"; then
      fail "FC-069: state/schema.md deployment object missing field: $field"
    fi
  done
fi

# ── FC-070: state/schema.md Field Definitions has deployment.* rows ───────────
if [ -f "$STATE_SCHEMA" ]; then
  for dot_field in 'deployment.status' 'deployment.verdict' 'deployment.ports' 'deployment.health_check'; do
    if ! grep -q "$dot_field" "$STATE_SCHEMA"; then
      fail "FC-070: state/schema.md Field Definitions table missing row for '$dot_field'"
    fi
  done
fi

# ── FC-072: CLAUDE.md Architecture section lists check-deploy in commands ───────
if [ -f "$CLAUDE_MD" ]; then
  if ! grep -q 'check-deploy' "$CLAUDE_MD"; then
    fail "FC-072: CLAUDE.md Architecture section does not list 'check-deploy' in commands list"
  fi
fi

# ── FC-075: roadmap.md contains DONE section for v5.4.0 ──────────────────────
if [ -f "$ROADMAP" ]; then
  if ! grep -q 'v5\.4\.0\|5\.4\.0' "$ROADMAP"; then
    fail "FC-075: roadmap.md missing DONE section for v5.4.0"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: Phase 2 config contract and check-deploy structural tests passed (FC-047 to FC-051, FC-060 to FC-072, FC-075)"
exit "$FAIL"
