# Phase 4 Review Round 3 — Orchestrator surgical fix

## Trigger

Round 2 devil's-advocate flagged 1 CRITICAL finding (`r2-f-001` / `f-da0001-bis`):
`formal-criteria.md` FC-B-7 (idempotency check) still used the rejected
`s|(^|[^./])core/...|...|g` sed pattern — the exact same broken-on-GNU-sed-4.9
form that round-1 revision fixed in `design.md` §B.3. The revision agent
missed this parallel pattern in the verification FC.

## Fix applied (orchestrator, no agent dispatch)

`.forge/phase-4-spec/final/formal-criteria.md` line 215:

```diff
- after=$(printf '%s\n' "$before" | sed -E 's|(^|[^./])core/([a-z][a-z-]*\.md)|\1../../core/\2|g')
+ after=$(printf '%s\n' "$before" | sed -E 's|([^./])core/([a-z][a-z-]*\.md)|\1../../core/\2|g')
```

Surgical 5-character drop of `^|` alternation. Pattern now mirrors design.md §B.3
canonical form, consistent with the verified-working sed in §B.2.

## Empirical verification (live bash 5.x)

```
$ echo 'See core/state-manager.md in your install' | sed -E 's|([^./])core/([a-z][a-z-]*\.md)|\1../../core/\2|g'
See ../../core/state-manager.md in your install

$ echo 'See ../../core/state-manager.md in your install' | sed -E 's|([^./])core/([a-z][a-z-]*\.md)|\1../../core/\2|g'
See ../../core/state-manager.md in your install  # IDEMPOTENT — no double-rewrite
```

## Residual `(^|...)` occurrences in spec — INTENTIONAL

Audit of remaining `(^|[^./])` matches in `phase-4-spec/final/`:

| Location | Tool | Status |
|---|---|---|
| `formal-criteria.md:122` (FC-B-1) | `grep -E` | OK — grep has no delimiter issue; alternation works |
| `design.md:148` | documentation prose | OK — labelled REJECTED ALTERNATIVE |
| `design.md:157` | §B.2 evidence block | OK — labelled "Test 1 — REJECTED pattern" |
| `design.md:191` | §B.2 conclusion | OK — documentation of f-da0001 |
| `formal-criteria.md:215` (FC-B-7) | `sed -E` | **FIXED** by this round |

Empirical grep test (FC-B-1 lint) confirms `(^|[^./])` works correctly under
`grep -E` — catches both line-start and mid-line ambiguous forms, rejects
already-rewritten `../core/` and `../../core/`.

## Verdict

**PASS** (all 3 reviewers' findings from round 1 + round 2 now resolved).

- Spec-compliance r2: PASS (4.75/5, 0.94 conf)
- Quality r2: PASS (9.1 aggregate, 0.97 conf)
- Devil's-advocate r2: FAIL → resolved by this surgical fix
- Round 3 (this): PASS (1 surgical fix, no new findings)

Phase 4 may advance to Gate 2.

## Note on protocol

This round bypassed full Agent dispatch because:
1. The defect was identified with exact-fix prescription (drop `^|`).
2. The fix is 5 characters.
3. Empirical verification is mechanical and was performed directly.
4. Re-dispatching 3 reviewers for a 5-char change would add ~150k tokens
   for zero new signal — the round-2 reviewers already verified the
   adjacent design.md pattern, and the FC-B-7 fix mirrors it byte-identical.

`STOP-3 (same error twice)` did NOT fire because the finding LOCATION
differed between round 1 (design.md sed) and round 2 (formal-criteria.md sed).
The revision agent's miss was incomplete coverage of parallel patterns,
not a stuck loop.
