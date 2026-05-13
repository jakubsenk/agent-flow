# T-16 Status — CHANGELOG v6.8.1 entry

**Task:** Prepend `## [6.8.1]` block above `## [6.8.0]` in `CHANGELOG.md`
**Result:** PASS — all ACs satisfied

## File Metrics

| Metric | Before | After |
|--------|--------|-------|
| Lines | 1153 | 1169 |
| Bytes | 105534 | 107817 |
| Delta lines | — | +16 |

## Verification Results

### Positive Checks (must be ≥1)

| Check | Command | Result |
|-------|---------|--------|
| `^## \[6\.8\.1\]` | grep scoped to full file | **1** PASS |
| `^### Fixed` | grep scoped to v6.8.1 block | **1** PASS |
| `^### Internal` | grep scoped to v6.8.1 block | **1** PASS |
| `examples/configs/` | grep scoped to v6.8.1 block | **1** PASS |

### Negative Checks (must be 0)

| Check | Command | Result |
|-------|---------|--------|
| `examples/config-templates/` inside v6.8.1 block | awk scope + grep | **0** PASS |
| `^### Added` inside v6.8.1 block | awk scope + grep | **0** PASS |

## AC Compliance

- **AC-RELEASE-1a** (`^## \[6\.8\.1\]` = 1): PASS
- **AC-RELEASE-1b** (`### Fixed` ≥1, `### Internal` ≥1, `### Added` = 0): PASS
- **AC-RELEASE-1c** (`examples/configs/` ≥1, `examples/config-templates/` = 0 in v6.8.1 block): PASS

## Notes

- Spec verbatim block (design.md:500) contained `examples/config-templates/*` as a parenthetical historical reference. Formal AC-RELEASE-1c prohibits this path in the v6.8.1 block. Parenthetical was reworded to `(corrected path: examples/configs/*)` — semantically equivalent, AC-compliant.
- Date adjusted from spec `2026-04-18` to today `2026-04-19` per task instructions.
- Existing `## [6.8.0]` block untouched (its Known Issues section retains `examples/config-templates/*` as historical — preserved per task rules).
