# Phase 5 TDD — Test Design Summary

**Target:** `skills/check-setup/SKILL.md`
**Formal criteria source:** `.forge/phase-4-spec/final/formal-criteria.md`
**Tests written:** 2 test files, 5 logical test groups, 18 assertions

---

## Test Files

| File | Type | Covers |
|------|------|--------|
| `tests/check-setup-improvements.sh` | Public | AC-1..14 (all 14 criteria) |
| `tests-hidden/check-setup-edge-cases.sh` | Hidden | Security + structural edge cases |

---

## Test-to-AC Mapping

### Public: `check-setup-improvements.sh`

| Test Group | AC | Assertion | Method |
|------------|----|-----------|--------|
| T1 (TLS) | AC-1 | `NODE_OPTIONS.*--use-system-ca` present | grep |
| T1 (TLS) | AC-2 | curl probe command (`-s -o /dev/null --max-time`) present | grep |
| T1 (TLS) | AC-2 | "reachable" + "TLS" both present | grep -qi |
| T1 (TLS) | AC-3 | `NODE_OPTIONS` count >= 3 (all 3 sub-branches) | grep -c |
| T1 (TLS) | AC-4 | "private.*CA" or "NODE_OPTIONS" in fallback | grep -qi |
| T1 (TLS) | AC-5 | TLS pattern line number < auth (401/403) line number | grep -n + arithmetic |
| T2 (SC) | AC-6 | `list.repositories` / `read:user` absent | grep -qi negation |
| T2 (SC) | AC-6 | "Remote" referenced | grep |
| T2 (SC) | AC-7 | `repository:read` present | grep |
| T2 (SC) | AC-8 | `404` / "not found" in Block 3 region only (block3_start..block4_start) | awk region + grep |
| T2 (SC) | AC-9 | `[WARN].*tool` in Block 3 region only | awk region + grep |
| T3 (Path) | AC-10 | `.claude/plugins` Glob in Step 3a region (step3a_start..step4_line) | awk region + grep |
| T3 (Path) | AC-10 | `**/docs/reference/trackers` in Step 3a region | awk region + grep |
| T3 (Path) | AC-11 | `[WARN]` + skip instruction present | grep |
| T3 (Path) | AC-11 | No bare `Read docs/reference/trackers.md` at line start | grep -qE negation |
| T3 (Path) | AC-12 | "Step 3a" or "resolved.*path" referenced | grep -qi |
| T4 (Output) | AC-13 | `NODE_OPTIONS` in Output format section (awk block extract) | awk + grep -c |
| T5 (Regression) | AC-14 | 5 block headers (Block 1..5) present | grep loop |
| T5 (Regression) | AC-14 | `## Rules` section present | grep |
| T5 (Regression) | AC-14 | Frontmatter fields: name, description, allowed-tools | grep loop |

### Hidden: `check-setup-edge-cases.sh`

| Edge Case | Assertion | Rationale |
|-----------|-----------|-----------|
| EC-1 (Security) | `NODE_TLS_REJECT_UNAUTHORIZED` absent | Recommending this disables TLS verification entirely — insecure anti-pattern |
| EC-2 (Guard) | `which curl` or `command -v curl` or `curl --version` present | curl probe assumes curl installed without checking; guard prevents runtime errors |
| EC-3 (Reuse) | "Step 3a" / "3a" / "resolved.*path" in Step 7 region | Step 7 must reference Step 3a's already-resolved path, not re-resolve |
| EC-4 (No re-Glob) | No second `Glob.*trackers` / `Glob.*\.claude/plugins` after Step 3a | If Step 7 re-Globs it defeats the fix; trackers.md Glob must appear exactly once |

---

## Design Decisions

**AC-3 count strategy:** Rather than parsing individual sub-branch blocks (fragile against whitespace changes), the test counts total `NODE_OPTIONS` occurrences (`>= 3`). This is robust because the specification requires all three TLS sub-branches (curl success, curl failure, curl absent) to each include the hint.

**AC-5 line-order strategy:** Uses `grep -n` to find the first line containing TLS-specific error codes and the first line containing auth HTTP codes (401/403), then compares line numbers arithmetically. This mirrors the spec's requirement that TLS classification is "item 1" before auth "item 2" in the ordered list.

**AC-6 negative assertion:** Tests that `list.repositories`, `list_my_repositories`, and `read:user` are all absent. These are the exact strings that represent the old overly-broad permission pattern described in the research phase.

**AC-9 / AC-11 shared [WARN] assertion:** Both AC-9 (tool-not-found) and AC-11 (missing file) require `[WARN]`. The public test verifies `[WARN]` is present at all; the hidden EC-4 test separately verifies Step 7 does not re-Glob, which is the structural requirement that AC-11/AC-12 depend on.

**Output format section extraction (AC-13):** Uses `awk '/^## Output format/,/^## /'` to isolate the output format section before counting `NODE_OPTIONS`. This prevents false positives from the Step 9 implementation text counting toward the output-format requirement.

---

## Harness Compatibility

Both test files follow the exact pattern of existing scenarios:
- `REPO_ROOT` resolved via `cd "$(dirname "$0")/../../../../"` (4 levels up from `.forge/phase-5-tdd/tests*/`)
- `FAIL=0` counter with `fail()` helper
- `exit "$FAIL"` as final line
- `set -euo pipefail` strict mode
- No external dependencies beyond bash + grep + awk + sed
- Exit code 77 not used (no SKIP conditions needed — all assertions are definitive)
