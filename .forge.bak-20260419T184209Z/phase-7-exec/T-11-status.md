# T-11 Execution Status

**Task:** Reconcile lock-timeout phrasing at `skills/autopilot/SKILL.md:368`
**Status:** DONE

## File Modified

`C:/gitea_ceos-agents/skills/autopilot/SKILL.md` — line 368 replaced (single-line change, no other edits).

## Verification Greps

All greps run against `skills/autopilot/SKILL.md`.

### Positive assertions (required phrases present)

| Phrase | Match count | Result |
|--------|-------------|--------|
| `effective stale threshold` | 1 | PASS |
| `125 min` | 1 | PASS |
| `primary path` | 2 (also in config table) | PASS |
| `121 min` | 1 | PASS |
| `BusyBox` | 5 (also in existing bash section) | PASS |

### Negative assertion (banned phrase absent)

| Phrase | Match count | Result |
|--------|-------------|--------|
| `<120min old` | 0 | PASS |

## Replacement Applied

**Old (line 368):**
```
- **`[autopilot][ERROR] Another Autopilot run in progress`** → check `.ceos-agents/autopilot.lock/owner.json` for the owning PID and host. If the owning process is gone but the lock is <120min old, wait for stale timeout or manually `rm -rf .ceos-agents/autopilot.lock/` (only after verifying no live process).
```

**New (line 368):**
```
- **`[autopilot][ERROR] Another Autopilot run in progress`** → check `.ceos-agents/autopilot.lock/owner.json` for the owning PID and host. If the owning process is gone but the lock is less than the effective stale threshold (the configured `Lock timeout` value plus a 5-minute NFS/CIFS clock-skew buffer; default: 125 min on primary path, 121 min on BusyBox fallback), wait for stale auto-recovery or manually `rm -rf .ceos-agents/autopilot.lock/` (only after verifying no live process).
```

## Source

- Current text from: `design.md:246-248`
- Replacement text from: `design.md:251-253`
