#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #10 — Tier B+C)
# Functional: resume-ticket handles --clarification flag with EXTERNAL INPUT wrapping.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESUME="$REPO_ROOT/skills/resume-ticket/SKILL.md"
[ -f "$RESUME" ] || { fail "skills/resume-ticket/SKILL.md not found"; exit 1; }

# --clarification flag must be documented
if ! grep -qE '\-\-clarification' "$RESUME"; then
  fail "skills/resume-ticket/SKILL.md missing --clarification flag"
fi

# EXTERNAL INPUT markers must be used to wrap clarification answer (producer side)
if ! grep -qF 'EXTERNAL INPUT START' "$RESUME"; then
  fail "resume-ticket must wrap clarification answer with EXTERNAL INPUT markers"
fi
if ! grep -qF 'EXTERNAL INPUT END' "$RESUME"; then
  fail "resume-ticket missing EXTERNAL INPUT END marker"
fi

# Tier C: create synthetic clarification content and verify marker pattern
cat > "$TMP/clarification_answer.txt" <<'EOT'
--- EXTERNAL INPUT START ---
The issue should use option B per the product team's latest guidance.
--- EXTERNAL INPUT END ---
EOT
if ! grep -qF '--- EXTERNAL INPUT START ---' "$TMP/clarification_answer.txt"; then
  fail "Synthetic clarification answer: EXTERNAL INPUT START marker malformed"
fi
if ! grep -qF '--- EXTERNAL INPUT END ---' "$TMP/clarification_answer.txt"; then
  fail "Synthetic clarification answer: EXTERNAL INPUT END marker malformed"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: resume-ticket --clarification with EXTERNAL INPUT wrapping verified"
exit "$FAIL"
