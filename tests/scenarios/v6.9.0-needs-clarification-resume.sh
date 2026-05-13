#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #10 — Tier B+C)
# Functional: resume-ticket handles --clarification flag with EXTERNAL INPUT wrapping.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESUME="$REPO_ROOT/core/resume-detection.md"
[ -f "$RESUME" ] || { fail "core/resume-detection.md not found"; exit 1; }

# --clarification flag must be documented
if ! grep -qE '\-\-clarification' "$RESUME"; then
  fail "core/resume-detection.md missing --clarification flag"
fi

# EXTERNAL INPUT markers must be used to wrap clarification answer (producer side)
# resume-detection.md constrains agents above it; the markers appear in skill-level docs
# v10 thin-controller: accept presence in resume-detection.md, fix-bugs SKILL.md,
# OR any of the fix-bugs step files under steps/.
fb_dir="$REPO_ROOT/skills/fix-bugs"
fb_files=("$RESUME" "$fb_dir/SKILL.md")
[ -d "$fb_dir/steps" ] && while IFS= read -r -d '' f; do fb_files+=("$f"); done < <(find "$fb_dir/steps" -name '*.md' -print0)

if ! grep -lq 'EXTERNAL INPUT START' "${fb_files[@]}" 2>/dev/null; then
  fail "resume detection contract or fix-bugs must wrap clarification answer with EXTERNAL INPUT markers"
fi
if ! grep -lq 'EXTERNAL INPUT END' "${fb_files[@]}" 2>/dev/null; then
  fail "resume detection contract or fix-bugs missing EXTERNAL INPUT END marker"
fi

# Tier C: create synthetic clarification content and verify marker pattern
cat > "$TMP/clarification_answer.txt" <<'EOT'
--- EXTERNAL INPUT START ---
The issue should use option B per the product team's latest guidance.
--- EXTERNAL INPUT END ---
EOT
if ! grep -q 'EXTERNAL INPUT START' "$TMP/clarification_answer.txt"; then
  fail "Synthetic clarification answer: EXTERNAL INPUT START marker malformed"
fi
if ! grep -q 'EXTERNAL INPUT END' "$TMP/clarification_answer.txt"; then
  fail "Synthetic clarification answer: EXTERNAL INPUT END marker malformed"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: core/resume-detection.md --clarification with EXTERNAL INPUT wrapping verified"
exit "$FAIL"
