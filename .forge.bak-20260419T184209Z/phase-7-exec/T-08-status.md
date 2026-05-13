# T-08 Status — Field value safety paragraph inserted

## Task
Insert verbatim paragraph from `design.md:165-177` into `core/post-publish-hook.md` Section 4,
after the "Advisory failure" sentence (line 102) and before the "Example for `pipeline-started`:" line.

## Status: DONE

## Anchor phrase grep verification

```
grep -n "Field value safety" core/post-publish-hook.md
104:**Field value safety:** The heredoc prevents shell-word-splitting and glob expansion, but a raw

grep -n "issue_id regex gate" core/post-publish-hook.md
108:The `issue_id` regex gate (see issue_id validation in skills' Step 0, R-ITEM-2.1 through R-ITEM-2.6)

grep -n "block-handler.md" core/post-publish-hook.md
114:`core/block-handler.md` Step 5 for the canonical pattern) rather than interpolating variables into

grep -n "jq -n --arg" core/post-publish-hook.md
113:`ceos-agents-block` events), use `jq -n --arg` structural payload construction (see

grep -n "percent-encoded" core/post-publish-hook.md
110:interpolate directly. The `pr_url` field in `pipeline-completed` payloads SHOULD be percent-encoded

grep -n "heredoc" core/post-publish-hook.md
23:   Note: Use a heredoc to pass the JSON body ...
102:... Use the same `curl --max-time 5 --retry 0` pattern with a heredoc to pass the JSON body...
104:**Field value safety:** The heredoc prevents shell-word-splitting and glob expansion, but a raw
105:`"${var}"` substitution inside a heredoc JSON literal does NOT JSON-encode field values. ...
```

## Required phrases — all present

| Phrase | Line | Status |
|--------|------|--------|
| `Field value safety` | 104 | PASS |
| heredoc vs JSON-encoding discussion | 104-105 | PASS |
| `issue_id` regex gate cross-reference (R-ITEM-2.1 through R-ITEM-2.6) | 108 | PASS |
| `core/block-handler.md` Step 5 canonical pattern pointer | 114 | PASS |
| `jq -n --arg` structural payload construction | 113 | PASS |
| `percent-encoded` (pr_url field) | 110 | PASS |

## Placement verification

Inserted after line 102 ("Advisory failure: log `[WARN]...` and continue pipeline. Never block.")
and before line 116 ("Example for `pipeline-started`:").

AC-ITEM-3.1 satisfied: paragraph present with literal phrase "Field value safety".
AC-ITEM-3.4 (negative): no inline `-d '{...}'` pattern introduced by this change.
