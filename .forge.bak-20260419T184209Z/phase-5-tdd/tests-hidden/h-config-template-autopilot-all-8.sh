#!/usr/bin/env bash
# Hidden test: AC-ITEM-1.1, AC-ITEM-1.2, AC-ITEM-1.3, AC-ITEM-1.4
# Verifies all 8 config templates under examples/configs/ have:
#   - ### Autopilot heading (AC-ITEM-1.1)
#   - All 7 canonical key/value rows (AC-ITEM-1.2)
#   - | Key | Value | header + |-----|-------| alignment row (AC-ITEM-1.3)
#   - Opt-in comment block structure for 7 commented templates (AC-ITEM-1.4)
#   - Active section for redmine-oracle-plsql.md (AC-ITEM-1.4)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
CONFIGS_DIR="$REPO_ROOT/examples/configs"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

echo "--- h-config-template-autopilot-all-8 (AC-ITEM-1.1 through 1.4): all 8 config templates ---"

TEMPLATES=(
  "github-nextjs.md"
  "github-python-fastapi.md"
  "github-dotnet.md"
  "gitea-spring-boot.md"
  "jira-react.md"
  "youtrack-python.md"
  "redmine-rails.md"
  "redmine-oracle-plsql.md"
)

# -----------------------------------------------------------------------
# AC-ITEM-1.1: ### Autopilot heading in each template
# -----------------------------------------------------------------------
echo "--- AC-ITEM-1.1: ### Autopilot present in all 8 templates ---"
for tpl in "${TEMPLATES[@]}"; do
  f="$CONFIGS_DIR/$tpl"
  if [ ! -f "$f" ]; then
    fail "AC-ITEM-1.1: template file not found: $f"
    continue
  fi
  if grep -qE '^### Autopilot' "$f"; then
    echo "OK (AC-ITEM-1.1): ### Autopilot present in $tpl"
  else
    fail "AC-ITEM-1.1: ### Autopilot heading missing from $tpl"
  fi
done

# -----------------------------------------------------------------------
# AC-ITEM-1.2: All 7 canonical key rows present in each template
# -----------------------------------------------------------------------
echo "--- AC-ITEM-1.2: All 7 canonical Autopilot keys in each template ---"

REQUIRED_KEYS=(
  "| Max issues per run | 1 |"
  "| Lock timeout | 120 |"
  "| Log file | .ceos-agents/autopilot.log |"
  "| Bug limit | 0 |"
  "| Feature limit | 0 |"
  "| On error | skip |"
  "| Dry run | false |"
)

for tpl in "${TEMPLATES[@]}"; do
  f="$CONFIGS_DIR/$tpl"
  [ -f "$f" ] || continue
  for key_row in "${REQUIRED_KEYS[@]}"; do
    if grep -qF "$key_row" "$f"; then
      echo "OK (AC-ITEM-1.2): '$key_row' present in $tpl"
    else
      fail "AC-ITEM-1.2: '$key_row' missing from $tpl"
    fi
  done
done

# -----------------------------------------------------------------------
# AC-ITEM-1.3: | Key | Value | header + |-----|-------| alignment row
#   within the Autopilot section
# -----------------------------------------------------------------------
echo "--- AC-ITEM-1.3: | Key | Value | header and alignment row in each template ---"
for tpl in "${TEMPLATES[@]}"; do
  f="$CONFIGS_DIR/$tpl"
  [ -f "$f" ] || continue
  if grep -qE '^\| Key \| Value \|' "$f"; then
    echo "OK (AC-ITEM-1.3): | Key | Value | header present in $tpl"
  else
    fail "AC-ITEM-1.3: | Key | Value | header missing from $tpl (Autopilot section requires table format)"
  fi
  if grep -qE '^\|[-]+\|[-]+\|' "$f"; then
    echo "OK (AC-ITEM-1.3): alignment row present in $tpl"
  else
    fail "AC-ITEM-1.3: alignment row (|-----|-------|) missing from $tpl"
  fi
done

# -----------------------------------------------------------------------
# AC-ITEM-1.4: Opt-in comment structure for 7 commented-style templates;
#   active section for redmine-oracle-plsql.md
# -----------------------------------------------------------------------
echo "--- AC-ITEM-1.4: Opt-in comment block structure ---"

COMMENTED_TEMPLATES=(
  "github-nextjs.md"
  "github-python-fastapi.md"
  "github-dotnet.md"
  "gitea-spring-boot.md"
  "jira-react.md"
  "youtrack-python.md"
  "redmine-rails.md"
)

for tpl in "${COMMENTED_TEMPLATES[@]}"; do
  f="$CONFIGS_DIR/$tpl"
  [ -f "$f" ] || continue
  # Must have the divider line
  if grep -qE '^\> \*\*Uncomment and customize optional sections as needed\.\*\*$' "$f"; then
    echo "OK (AC-ITEM-1.4): divider line present in $tpl"
  else
    fail "AC-ITEM-1.4: '> **Uncomment and customize optional sections as needed.**' divider missing from $tpl"
  fi
  # Must have HTML comment markers
  if grep -qE '^<!--$' "$f" && grep -qE '^-->$' "$f"; then
    echo "OK (AC-ITEM-1.4): <!-- ... --> comment block markers present in $tpl"
  else
    fail "AC-ITEM-1.4: <!-- ... --> comment block markers missing from $tpl (Autopilot must be inside comment block)"
  fi
done

# redmine-oracle-plsql: ### Autopilot appears as active section (either before or inside comment block)
# The AC allows both; we just verify the ### Autopilot heading exists (checked in AC-ITEM-1.1)
REDMINE_F="$CONFIGS_DIR/redmine-oracle-plsql.md"
if [ -f "$REDMINE_F" ]; then
  if grep -qE '^### Autopilot$' "$REDMINE_F"; then
    echo "OK (AC-ITEM-1.4): redmine-oracle-plsql.md has ### Autopilot (no '(optional)' suffix, active section)"
  elif grep -qE '^### Autopilot \(optional\)$' "$REDMINE_F"; then
    echo "OK (AC-ITEM-1.4): redmine-oracle-plsql.md has ### Autopilot (optional) (inside comment block variant)"
  else
    fail "AC-ITEM-1.4: redmine-oracle-plsql.md missing ### Autopilot or ### Autopilot (optional)"
  fi
fi

# -----------------------------------------------------------------------
# Final result
# -----------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: h-config-template-autopilot-all-8 — all 8 templates have ### Autopilot with 7 canonical keys in table format"
fi
exit "$FAIL"
