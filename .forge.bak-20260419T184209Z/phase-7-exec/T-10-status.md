# T-10 Status — Append "Payload field safety" to autopilot.md

**Status:** DONE

## Change applied

File: `docs/guides/autopilot.md`
Insertion point: after line 286 (webhook-payload section), before `---` divider.

Verbatim 10-line paragraph from `design.md:214-222` appended.

## Anchor phrase grep verification

```
grep -n "Payload field safety\|jq -n --arg\|percent-encoded" docs/guides/autopilot.md
```

Results:
- Line 288: `**Payload field safety:**` — FOUND
- Line 291: `percent-encoded` — FOUND
- Line 294: `jq -n --arg` — FOUND

All 3 required literal phrases present. AC-ITEM-3.3 satisfied.
