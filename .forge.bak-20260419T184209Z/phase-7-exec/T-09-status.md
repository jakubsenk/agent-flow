# T-09 Status — block-handler Step 5 Rewrite

**Task:** Rewrite `core/block-handler.md` Step 5 with heredoc + `--proto` + `jq -n --arg`
**Status:** DONE
**File touched:** `C:/gitea_ceos-agents/core/block-handler.md`
**Source block:** `design.md:180-210` (verbatim)

---

## Anchor Phrase Greps

All 5 required phrases found in `core/block-handler.md`:

| Phrase | Line(s) | Result |
|--------|---------|--------|
| `--data-binary @-` | 52 | FOUND |
| `--proto "=http,https"` | 51, 60 | FOUND |
| `<<EOF` | 52 | FOUND |
| `jq -n` | 43, 57, 64 | FOUND |
| `--arg` | 41, 44, 45, 46, 47, 48, 57 | FOUND |

---

## Negative Checks

| Check | Result | Notes |
|-------|--------|-------|
| `${var:1:-1}` as actual shell construct | ABSENT (PASS) | Line 59 contains the literal text `` `${var:1:-1}` `` inside backticks in prose — it is a documentation reference showing what the code does NOT use, not an operative shell expression. This is verbatim text from `design.md:201` and is correct per spec. |
| `curl ... -d '{` inline substitution | ABSENT (PASS) | Old inline `-d '{"event":...}'` pattern fully removed. |

---

## Change Summary

**Removed (old Step 5 block, lines ~39-44):**
```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"issue-blocked","issue_id":"{issue_id}","agent":"{agent_name}","reason":"{reason}","timestamp":"{ISO8601}"}' \
  "{Webhook URL}"
```

**Replaced with (new Step 5 block, lines ~39-67):**
- `jq -n --arg` structural payload construction for 5 fields (event, issue_id, agent, reason, timestamp)
- `curl --proto "=http,https"` + `--data-binary @-` + heredoc `<<EOF ... EOF`
- Explanatory prose: jq string escaping, --proto restriction, heredoc safety
- Advisory failure semantics preserved
- No `${var:1:-1}` substring construct used operatively (POSIX-safe)
