#!/usr/bin/env bash
# AC: AC-T1-7-1, AC-T1-7-2, AC-T1-7-3
# Anti-pattern harness gate — V6100_TOUCHED enumeration.
# Scans all v6.10.0-touched scenarios for awk+source code-lift pattern.
# Fails on any match (except sourcing tests/lib/fixtures.sh).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# V6100_TOUCHED — authoritative per requirements.md Section 1.
# Cardinality: 4 RETIRE + 16 REWRITE + 8 EXTEND + 19 net-new +
#              1 pre-track + 1 Track3 REWRITE + 1 KEEP-with-EXTEND = 50.
TOUCHED_SCENARIOS=(
  # RETIRE (4)
  "tests/scenarios/v6.9.0-changelog-completeness.sh"
  "tests/scenarios/v6.9.0-plugin-repo-url-invalid-tld.sh"
  "tests/scenarios/ac-v692-autopilot-bash-dispatch.sh"
  "tests/scenarios/v6.9.0-webhook-proto-coverage.sh"
  # REWRITE (16)
  "tests/scenarios/v6.9.0-autopilot-skip-paused.sh"
  "tests/scenarios/v6.9.0-bc-no-removed-agent-output.sh"
  "tests/scenarios/v6.9.0-bc-no-removed-webhook-event.sh"
  "tests/scenarios/v6.9.0-bc-no-renamed-section.sh"
  "tests/scenarios/v6.9.0-circuit-breaker-non-blocking.sh"
  "tests/scenarios/v6.9.0-circuit-breaker-semantics.sh"
  "tests/scenarios/v6.9.0-metrics-format-json.sh"
  "tests/scenarios/v6.9.0-needs-clarification-dos-cap.sh"
  "tests/scenarios/v6.9.0-needs-clarification-fixer.sh"
  "tests/scenarios/v6.9.0-needs-clarification-resume.sh"
  "tests/scenarios/v6.9.0-needs-clarification-triage.sh"
  "tests/scenarios/v6.9.0-outcome-failed-trap.sh"
  "tests/scenarios/v6.9.0-pause-timeout-validation.sh"
  "tests/scenarios/v6.9.0-pipeline-history-append.sh"
  "tests/scenarios/v6.9.0-pipeline-history-pii-scope.sh"
  "tests/scenarios/v6.9.0-pipeline-paused-webhook.sh"
  # EXTEND (8)
  "tests/scenarios/v6.9.0-bc-no-new-required-key.sh"
  "tests/scenarios/v6.9.0-block-handler-counter-example.sh"
  "tests/scenarios/v6.9.0-cross-file-invariants.sh"
  "tests/scenarios/v6.9.0-external-input-marker-receiver.sh"
  "tests/scenarios/v6.9.0-jira-dotted-regex-accept.sh"
  "tests/scenarios/v6.9.0-jira-regex-dot-only-reject.sh"
  "tests/scenarios/v6.9.0-jq-compact-form.sh"
  "tests/scenarios/v6.9.0-pipeline-history-credential-redaction.sh"
  # Net-new (19)
  "tests/scenarios/v6.10.0-no-awk-source-in-rewrites.sh"
  "tests/scenarios/v6.10.0-fixtures-helpers-contract.sh"
  "tests/scenarios/v6.10.0-contributing-security-section.sh"
  "tests/scenarios/v6.10.0-changelog-v6100-entry.sh"
  "tests/scenarios/v6.10.0-layer1-imperative-dispatch-coverage.sh"
  "tests/scenarios/v6.10.0-validate-dispatch-hook-contract.sh"
  "tests/scenarios/v6.10.0-state-schema-dispatched-at-additive.sh"
  "tests/scenarios/v6.10.0-dispatch-hook-install-surface.sh"
  "tests/scenarios/v6.10.0-skill-dispatch-enforcement.sh"
  "tests/scenarios/v6.10.0-autopilot-audit-disclosure.sh"
  "tests/scenarios/v6.10.0-layers-3-5-deferred-disclosure.sh"
  "tests/scenarios/v6.10.0-hooks-reference-doc-content.sh"
  "tests/scenarios/v6.10.0-dispatch-enforcement-guide-content.sh"
  "tests/scenarios/v6.10.0-roadmap-canonical-source-correction.sh"
  "tests/scenarios/v6.10.0-external-input-bullet-placement.sh"
  "tests/scenarios/v6.10.0-no-frontmatter-changes-11-agents.sh"
  "tests/scenarios/v6.10.0-no-receiver-side-bullet-in-11.sh"
  "tests/scenarios/v6.10.0-residual-risk-disclosure.sh"
  "tests/scenarios/v6.10.0-roadmap-corrections-unified.sh"
  # Pre-track + Track3 REWRITE + KEEP-with-EXTEND (3)
  "tests/scenarios/pipeline-agent-dispatch-models.sh"
  "tests/scenarios/prompt-injection-protection.sh"
  "tests/scenarios/v6.9.0-doc-count-drift.sh"
)
# Verify cardinality
expected_count=50
actual_count=${#TOUCHED_SCENARIOS[@]}
if [ "$actual_count" -ne "$expected_count" ]; then
  fail "TOUCHED_SCENARIOS cardinality: expected $expected_count, got $actual_count"
fi

# Pattern: awk extracting function to .sh file AND dot-sourcing it
# Exception: sourcing tests/lib/fixtures.sh (permitted per REQ-T1-6)
for scenario in "${TOUCHED_SCENARIOS[@]}"; do
  full_path="$REPO_ROOT/$scenario"
  [ -f "$full_path" ] || continue  # Skip missing files (pre-implementation)
  # Skip self — this file contains heredoc fixture text that would false-positive
  [[ "$full_path" -ef "${BASH_SOURCE[0]}" ]] && continue
  if grep -qE 'awk[[:space:]].*\^.*\\\(\\\)' "$full_path" 2>/dev/null; then
    if grep -qE '^\.[[:space:]].*\.sh' "$full_path" 2>/dev/null; then
      if ! grep -qE '^\s*\.\s+.*tests/lib/fixtures\.sh' "$full_path"; then
        fail "$scenario contains awk+source code-lift pattern"
      fi
    fi
  fi
done

# AC-T1-7-3: Negative control — synthetic fixture with awk+source MUST trigger
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/_synthetic-trigger.sh" <<'SH'
awk '/^myfunc\(\) \{/,/^\}$/' realfile.sh > "$SCRATCH/fn.sh"
. "$SCRATCH/fn.sh"
SH
synthetic_triggered=0
if grep -qE 'awk[[:space:]].*\^.*\\\(' "$TMP/_synthetic-trigger.sh" 2>/dev/null; then
  if grep -qE '^\.[[:space:]].*\.sh' "$TMP/_synthetic-trigger.sh" 2>/dev/null; then
    if ! grep -qE '^\s*\.\s+.*tests/lib/fixtures\.sh' "$TMP/_synthetic-trigger.sh"; then
      synthetic_triggered=1
    fi
  fi
fi
[ "$synthetic_triggered" -eq 1 ] || fail "Negative control: synthetic awk+source pattern not detected (gate is vacuous)"

[ "$FAIL" -eq 0 ] && echo "PASS: anti-pattern gate clean on ${#TOUCHED_SCENARIOS[@]} touched scenarios"
exit "$FAIL"
