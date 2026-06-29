#!/usr/bin/env bash
# ===========================================================================
# Test:     overlay-digest-toml-branch.sh
# AC:       AC-034b (REQ-031, REQ-034) — the overlay_source=toml branch of
#           compute_overlay_digest, today NEVER executed by any scenario (A7),
#           is exercised and pinned to an EXACT 64-hex known-answer.
# Known-answer (independent): sha256 of the LF-normalized rendered block bytes
#   `model = "sonnet"\nstyle = "Terse"`  (the bash helper hashes the STRING it is
#   given with `printf '%s'` — no trailing newline added) ==
#   28e5f433dfcc6443fe4b4f9c0851c51dd4fb2e16c1fe5a2ea9f629f99dc3a468
# (re-derived inline with printf|sha256sum AND pinned as a literal so a
#  trailing-newline / formula mutation is killed).
# NOTE: the GATE's overlay_digest hashes the RAW .toml FILE bytes *including* the
# file's trailing newline (REQ-031); that file-digest is computed at runtime in
# overlay-digest-ground-truth.sh — it is intentionally NOT this string golden.
# ===========================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT" || { echo "FAIL: cannot cd to REPO_ROOT=$REPO_ROOT" >&2; exit 1; }
# shellcheck disable=SC1090
. "$REPO_ROOT/tests/lib/assert.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

LIB="$REPO_ROOT/core/lib/stage-invariant.sh"
[ -f "$LIB" ] || { echo "SKIP: $LIB missing" >&2; exit 77; }
command -v sha256sum >/dev/null 2>&1 || { echo "SKIP: no sha256sum" >&2; exit 77; }
# shellcheck disable=SC1090
. "$LIB"

GOLDEN="28e5f433dfcc6443fe4b4f9c0851c51dd4fb2e16c1fe5a2ea9f629f99dc3a468"
# Rendered block string (LF-joined, no trailing newline — $() strips trailing LF,
# matching the bash helper's `printf '%s'` no-trailing-newline semantics).
BYTES=$(printf 'model = "sonnet"\nstyle = "Terse"')

# Independent reference (raw printf|sha256sum), self-validates the golden literal.
REF=$(printf '%s' "$BYTES" | sha256sum | awk '{print $1}')
[ "$REF" = "$GOLDEN" ] || fail "reference: inline sha256 ($REF) != pinned golden ($GOLDEN)"

# The toml branch must return EXACTLY the 64-hex digest of those bytes.
DIG=$(compute_overlay_digest toml "$BYTES") || fail "compute_overlay_digest toml returned non-zero"
[ "$DIG" = "$GOLDEN" ] \
  || fail "toml-branch: compute_overlay_digest toml = '$DIG', expected golden '$GOLDEN' (formula/newline drift)"
matches_re "$DIG" '^[0-9a-f]{64}$' \
  || fail "toml-branch: digest '$DIG' is not 64 lowercase hex"

# Boundary: none / md_rejected branches return the literal source token (not a hash).
[ "$(compute_overlay_digest none)" = "none" ] \
  || fail "none-branch: expected literal 'none'"
[ "$(compute_overlay_digest md_rejected)" = "md_rejected" ] \
  || fail "md_rejected-branch: expected literal 'md_rejected'"

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: overlay-digest-toml-branch — toml branch executed; digest == $GOLDEN; none/md_rejected literal"
  exit 0
fi
exit 1
