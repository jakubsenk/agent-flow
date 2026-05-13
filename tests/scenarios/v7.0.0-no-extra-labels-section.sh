#!/usr/bin/env bash
# AC-DEL-EXTRA-LABELS-1, AC-DEL-EXTRA-LABELS-2, AC-DEL-EXTRA-LABELS-3, AC-DEL-EXTRA-LABELS-4
# Asserts that the "Extra labels" config section is absent from all active source
# files after the v7.0.0 release commit lands.
# Excluded: .forge/, .forge.bak-*, docs/plans/, docs/superpowers/, CHANGELOG.md,
# README.md (migration table), REVIEW-REPORT-v3.1.0.md (historical review),
# check-setup/ (intentional deprecation-warning prose for old config users).
# Note: --exclude-dir takes basename patterns, not paths (grep limitation).
set -euo pipefail

cd "$(dirname "$0")/../.."
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Functional check 1: no "Extra labels" in any active .md file
# Note: --exclude-dir='.forge.v*' excludes versioned forge archives (e.g. .forge.v8.0.0/)
count=0
count=$(grep -rn 'Extra labels' \
  --include='*.md' \
  --exclude-dir=.forge \
  --exclude-dir='.forge.bak-*' \
  --exclude-dir='.forge.v*' \
  --exclude-dir=plans \
  --exclude-dir=superpowers \
  --exclude=CHANGELOG.md \
  --exclude=README.md \
  --exclude=REVIEW-REPORT-v3.1.0.md \
  --exclude-dir=check-setup \
  . 2>/dev/null | wc -l | tr -d ' ') || count=0
if [ "$count" != "0" ]; then
  echo "FAIL: Found $count 'Extra labels' references in active files:" >&2
  grep -rn 'Extra labels' \
    --include='*.md' \
    --exclude-dir=.forge \
    --exclude-dir='.forge.bak-*' \
    --exclude-dir='.forge.v*' \
    --exclude-dir=plans \
    --exclude-dir=superpowers \
    --exclude=CHANGELOG.md \
    --exclude=README.md \
    --exclude=REVIEW-REPORT-v3.1.0.md \
    --exclude-dir=check-setup \
    . 2>/dev/null | head -20 >&2 || true
  FAIL=1
fi

# Functional check 2: core/config-reader.md no longer has the pr_rules.extra_labels parse rule
if grep -q 'pr_rules\.extra_labels' core/config-reader.md 2>/dev/null; then
  fail "core/config-reader.md still contains pr_rules.extra_labels parse rule"
fi

# Functional check 3: agents/publisher.md no longer references Extra labels
if grep -q 'Extra labels' agents/publisher.md 2>/dev/null; then
  fail "agents/publisher.md still references Extra labels"
fi

# Functional check 4: test scenario arrays no longer contain "Extra labels"
if grep -q '"Extra labels"' tests/scenarios/config-reader-sections.sh 2>/dev/null; then
  fail "tests/scenarios/config-reader-sections.sh OPTIONAL_SECTIONS still has Extra labels"
fi
if grep -q '"Extra labels"' tests/scenarios/v6.9.0-bc-no-renamed-section.sh 2>/dev/null; then
  fail "tests/scenarios/v6.9.0-bc-no-renamed-section.sh OPTIONAL_SECTIONS still has Extra labels"
fi

# Functional check 5: v6.9.0-bc-no-renamed-section.sh mutation guard now expects 18, not 19
if ! grep -qE '\[ "\$\{#OPTIONAL_SECTIONS\[@\]\}" -eq 18 \]' tests/scenarios/v6.9.0-bc-no-renamed-section.sh 2>/dev/null; then
  fail "tests/scenarios/v6.9.0-bc-no-renamed-section.sh mutation guard not updated to -eq 18"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-DEL-EXTRA-LABELS-1..5 — Extra labels absent from all active surfaces"
exit "$FAIL"
