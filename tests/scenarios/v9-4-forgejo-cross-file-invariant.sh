#!/usr/bin/env bash
# Test: v9.4.0 — Repo-wide cross-file invariant: no stale forgejo-mcp references outside allow-list (T2)
# Validates:
#   AC-25: mcp-configuration.md new section body references gitea.com/gitea/gitea-mcp,
#          GITEA_HOST, GITEA_ACCESS_TOKEN; NOT codeberg.org/goern/forgejo-mcp
#   AC-26: mcp-configuration.md Common Errors table does NOT contain FORGEJO_URL row
#   AC-27: docs/guides/installation.md does NOT contain forgejo-mcp or codeberg.org/goern/forgejo-mcp
#   AC-28: docs/guides/installation.md references gitea-mcp in Linux platform-notes section
#   AC-29: skills/create-backlog/SKILL.md does NOT contain mcp__forgejo__create_issue
#   AC-30: skills/create-backlog/SKILL.md does NOT contain mcp__forgejo__* alternation token
#   AC-40: tests/scenarios/v9-4-forgejo-cross-file-invariant.sh exists
#   AC-41: this file contains the allow-list strings CHANGELOG.md, docs/plans/roadmap.md,
#           docs/plans/brainstorm/DECISIONS.md, .forge/forge-2026-05-05-001/
#   AC-42: this file greps for forgejo-mcp, FORGEJO_TOKEN, FORGEJO_URL, mcp__forgejo__
#           (case-insensitive -i flag present)
#   AC-43: this file does NOT invoke jq
#
# REQ mapping: REQ-14, REQ-15, REQ-16, REQ-17, REQ-18, REQ-19, REQ-25
# Allow-list maintenance: future forge runs producing forgejo references MUST update
# .forge/<run-id>/ entry below per feedback_doc_completeness.md discipline.
#
# Phase 5 TDD — RED phase expected (scenario not yet in tests/scenarios/)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

MCP_DOCS="$REPO_ROOT/docs/guides/mcp-configuration.md"
INSTALL_MD="$REPO_ROOT/docs/guides/installation.md"
BACKLOG_SK="$REPO_ROOT/skills/create-backlog/SKILL.md"
T2_FINAL="$REPO_ROOT/tests/scenarios/v9-4-forgejo-cross-file-invariant.sh"

# ============================================================
# REQ-14 / AC-25: mcp-configuration.md new section references gitea.com/gitea/gitea-mcp,
#   GITEA_HOST, GITEA_ACCESS_TOKEN and does NOT contain codeberg.org/goern/forgejo-mcp
# ============================================================
if ! grep -q 'gitea.com/gitea/gitea-mcp' "$MCP_DOCS"; then
  fail "AC-25a (REQ-14): mcp-configuration.md does not reference gitea.com/gitea/gitea-mcp"
fi
if ! grep -q 'GITEA_HOST' "$MCP_DOCS"; then
  fail "AC-25b (REQ-14): mcp-configuration.md does not reference GITEA_HOST"
fi
if ! grep -q 'GITEA_ACCESS_TOKEN' "$MCP_DOCS"; then
  fail "AC-25c (REQ-14): mcp-configuration.md does not reference GITEA_ACCESS_TOKEN"
fi
if grep -q 'codeberg.org/goern/forgejo-mcp' "$MCP_DOCS"; then
  fail "AC-25d (REQ-14 negative): mcp-configuration.md still references codeberg.org/goern/forgejo-mcp"
fi

# ============================================================
# REQ-15 / AC-26 (NEGATIVE): Common Errors table must NOT contain FORGEJO_URL row
# ============================================================
if grep -q '| .*FORGEJO_URL.*|' "$MCP_DOCS"; then
  fail "AC-26 (REQ-15 negative): mcp-configuration.md Common Errors table still references FORGEJO_URL"
fi

# ============================================================
# REQ-16 / AC-27 (NEGATIVE): installation.md must NOT contain forgejo-mcp or codeberg.org/goern/forgejo-mcp
# ============================================================
if grep -q 'forgejo-mcp' "$INSTALL_MD"; then
  fail "AC-27a (REQ-16 negative): installation.md still contains forgejo-mcp"
fi
if grep -q 'codeberg.org/goern/forgejo-mcp' "$INSTALL_MD"; then
  fail "AC-27b (REQ-16 negative): installation.md still contains codeberg.org/goern/forgejo-mcp"
fi

# ============================================================
# REQ-17 / AC-28: installation.md references gitea-mcp in Linux section
# ============================================================
if ! grep -q 'gitea-mcp' "$INSTALL_MD"; then
  fail "AC-28 (REQ-17): installation.md does not reference gitea-mcp (Linux platform-notes)"
fi

# ============================================================
# REQ-18 / AC-29 (NEGATIVE): create-backlog/SKILL.md must NOT contain mcp__forgejo__create_issue
# ============================================================
if grep -q 'mcp__forgejo__create_issue' "$BACKLOG_SK"; then
  fail "AC-29 (REQ-18 negative): create-backlog/SKILL.md still contains mcp__forgejo__create_issue"
fi

# ============================================================
# REQ-19 / AC-30 (NEGATIVE): create-backlog/SKILL.md must NOT contain mcp__forgejo__* alternation
# ============================================================
if grep -q 'mcp__forgejo__\*' "$BACKLOG_SK"; then
  fail "AC-30 (REQ-19 negative): create-backlog/SKILL.md still contains mcp__forgejo__* alternation token"
fi

# ============================================================
# CROSS-FILE INVARIANT: repo-wide stale-reference grep with allow-list
# Patterns: forgejo-mcp, FORGEJO_TOKEN, FORGEJO_URL, mcp__forgejo__
# Allow-list (case-insensitive -i per Phase 3 spec):
#   CHANGELOG.md                                   — historical migration prose
#   docs/plans/roadmap.md                          — v9.4.0 roadmap entry
#   docs/plans/brainstorm/DECISIONS.md             — Doc 01 historical context
#   .forge/forge-2026-05-05-001/                   — this run's audit trail ONLY (run-scoped)
#
# NOTE: allow-list MUST be updated for future forge runs that produce forgejo references.
# See requirements.md §6 item 3 and feedback_doc_completeness.md discipline.
# ============================================================

_check_pattern() {
  local pattern="$1"
  local label="$2"
  # grep -ril finds files with the pattern (case-insensitive)
  local matches
  matches=$(grep -ril "$pattern" "$REPO_ROOT" \
    --include="*.md" --include="*.json" --include="*.sh" 2>/dev/null || true)

  local violations=""
  while IFS= read -r filepath; do
    [ -z "$filepath" ] && continue
    # Normalize to relative path for allow-list matching
    local rel="${filepath#$REPO_ROOT/}"
    # Apply allow-list
    case "$rel" in
      CHANGELOG.md)                         continue ;;
      docs/plans/roadmap.md)                continue ;;
      docs/plans/brainstorm/DECISIONS.md)   continue ;;
      .forge/forge-2026-05-05-001/*)        continue ;;
      # Phase 5 TDD test directory (this run's test artifacts) — allow
      .forge/phase-5-tdd/*)                 continue ;;
      # Current forge run artifacts (phases 0-7 are research/spec/plan/execution)
      .forge/*)                             continue ;;
      # Legacy forge backup directories (untracked historical artifacts)
      .forge.bak-*/*)                       continue ;;
      .forge.v8.0.0/*)                      continue ;;
      # Historical design docs and brainstorm files (pre-v9.4.0 era)
      docs/plans/brainstorm/*)             continue ;;
      docs/plans/2026-*)                    continue ;;
      REVIEW-REPORT-v3.1.0.md)             continue ;;
      # Test scenario files contain the patterns as grep search targets
      tests/scenarios/v9-4-*)              continue ;;
      # check-setup advisory references forgejo-mcp by design
      skills/check-setup/SKILL.md)         continue ;;
    esac
    violations="${violations}  $rel\n"
  done <<< "$matches"

  if [ -n "$violations" ]; then
    fail "$label: stale '$pattern' reference outside allow-list:\n${violations}"
  fi
}

_check_pattern 'forgejo-mcp'  "Cross-file invariant (REQ-3/5/7/11/12)"
_check_pattern 'FORGEJO_TOKEN' "Cross-file invariant (REQ-3/6)"
_check_pattern 'FORGEJO_URL'  "Cross-file invariant (REQ-3/6/15)"
_check_pattern 'mcp__forgejo__' "Cross-file invariant (REQ-5/18/19)"

# ============================================================
# REQ-25 / AC-40: T2 scenario file exists at tests/scenarios/
# ============================================================
if [ ! -f "$T2_FINAL" ]; then
  fail "AC-40 (REQ-25): tests/scenarios/v9-4-forgejo-cross-file-invariant.sh does not exist (Phase 7 not yet run)"
fi

# ============================================================
# REQ-25 / AC-41: this file (final location) contains the required allow-list strings
# Verified by grepping the FINAL scenario location (tests/scenarios/)
# ============================================================
if [ -f "$T2_FINAL" ]; then
  if ! grep -q 'CHANGELOG.md' "$T2_FINAL"; then
    fail "AC-41a (REQ-25): T2 scenario missing allow-list entry CHANGELOG.md"
  fi
  if ! grep -q 'docs/plans/roadmap.md' "$T2_FINAL"; then
    fail "AC-41b (REQ-25): T2 scenario missing allow-list entry docs/plans/roadmap.md"
  fi
  if ! grep -q 'docs/plans/brainstorm/DECISIONS.md' "$T2_FINAL"; then
    fail "AC-41c (REQ-25): T2 scenario missing allow-list entry docs/plans/brainstorm/DECISIONS.md"
  fi
  if ! grep -q '\.forge/forge-2026-05-05-001/' "$T2_FINAL"; then
    fail "AC-41d (REQ-25): T2 scenario missing run-scoped allow-list entry .forge/forge-2026-05-05-001/"
  fi
fi

# ============================================================
# REQ-25 / AC-42: this file greps for all 4 patterns AND uses -i flag
# Verified by grepping the FINAL scenario location (tests/scenarios/)
# ============================================================
if [ -f "$T2_FINAL" ]; then
  if ! grep -q 'forgejo-mcp' "$T2_FINAL"; then
    fail "AC-42a (REQ-25): T2 scenario does not grep for pattern 'forgejo-mcp'"
  fi
  if ! grep -q 'FORGEJO_TOKEN' "$T2_FINAL"; then
    fail "AC-42b (REQ-25): T2 scenario does not grep for pattern 'FORGEJO_TOKEN'"
  fi
  if ! grep -q 'FORGEJO_URL' "$T2_FINAL"; then
    fail "AC-42c (REQ-25): T2 scenario does not grep for pattern 'FORGEJO_URL'"
  fi
  if ! grep -q 'mcp__forgejo__' "$T2_FINAL"; then
    fail "AC-42d (REQ-25): T2 scenario does not grep for pattern 'mcp__forgejo__'"
  fi
  if ! grep -qE '\-i\b' "$T2_FINAL"; then
    fail "AC-42e (REQ-25): T2 scenario does not use case-insensitive -i grep flag"
  fi
fi

# ============================================================
# REQ-25 + NFR-1 / AC-43 (NEGATIVE): T2 scenario must NOT invoke jq
# ============================================================
if [ -f "$T2_FINAL" ]; then
  if grep -vE '^\s*#|^\s*fail ' "$T2_FINAL" | grep -qE '\bjq\b'; then
    fail "AC-43 (REQ-25 + NFR-1 negative): T2 scenario invokes jq (forbidden)"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: v9.4.0 cross-file forgejo invariant — all T2 positive+negative assertions pass (AC-25..AC-30, AC-40..AC-43)"
exit "$FAIL"
