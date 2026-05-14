#!/bin/bash
# Mock MCP server for agent-flow test harness
# Reads JSON-RPC requests from stdin, returns fixture responses
# Usage: Used by test scenarios to simulate MCP server responses

FIXTURES_DIR="$(dirname "$0")/fixtures"
LOG_FILE="$(dirname "$0")/mcp-log.json"

# Initialize log
echo "[]" > "$LOG_FILE"

log_call() {
  local method="$1"
  local params="$2"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  # Append to log using temp file for atomicity
  local tmp
  tmp=$(mktemp)
  if command -v jq &>/dev/null; then
    jq --arg m "$method" --arg p "$params" --arg t "$timestamp" \
      '. += [{"method": $m, "params": $p, "timestamp": $t}]' "$LOG_FILE" > "$tmp" && mv "$tmp" "$LOG_FILE"
  else
    echo "{\"method\": \"$method\", \"params\": \"$params\", \"timestamp\": \"$timestamp\"}" >> "$LOG_FILE"
  fi
}

# Read JSON-RPC requests from stdin
while IFS= read -r line; do
  # Extract method from JSON-RPC request
  method=""
  if command -v jq &>/dev/null; then
    method=$(echo "$line" | jq -r '.method // empty' 2>/dev/null)
  else
    # Fallback: simple grep-based extraction
    method=$(echo "$line" | grep -oP '"method"\s*:\s*"[^"]*"' | head -1 | grep -oP '(?<=")[^"]*(?="$)')
  fi

  log_call "$method" "$line"

  case "$method" in
    "issues/list"|"search_issues"|"list_issues")
      cat "$FIXTURES_DIR/issues.json"
      ;;
    "issues/get"|"get_issue")
      # Return first issue from fixtures
      if command -v jq &>/dev/null; then
        jq '.[0]' "$FIXTURES_DIR/issues.json"
      else
        cat "$FIXTURES_DIR/issues.json"
      fi
      ;;
    "issues/comment"|"add_issue_comment")
      echo '{"result": {"id": "comment-1", "status": "created"}}'
      ;;
    "pulls/create"|"create_pull_request")
      echo '{"result": {"number": 42, "url": "https://example.com/pr/42", "state": "open"}}'
      ;;
    "issues/update"|"update_issue")
      echo '{"result": {"status": "updated"}}'
      ;;
    *)
      echo "{\"error\": {\"code\": -32601, \"message\": \"Method not found: $method\"}}"
      ;;
  esac
done
