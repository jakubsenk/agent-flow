# Decision — forge-2026-04-11-001

## Ready to Commit?

**Yes.**

Commander verdict: PASS (1.00 / 1.00). All 14 ACs pass. Test harness 53/53 PASS. No regressions.

## Versioning Impact

**PATCH** (v6.4.2 → v6.4.3)

Rationale per CLAUDE.md versioning policy:
- No new required keys in Automation Config
- No renamed sections
- No new output format contracts
- No new agents or skills
- This is a behavior fix to an existing skill — diagnostics are more accurate but the
  contract (what check-setup does, what config it reads) is unchanged

## Recommended Commit Message

```
fix: improve check-setup TLS diagnostics and trackers.md path resolution

- Step 9: classify MCP failures as TLS / auth / generic; run curl probe to
  distinguish server-reachable-but-TLS vs network-down; emit NODE_OPTIONS hint
- Step 3a: three-layer Glob for trackers.md (plugin dir first, CWD fallback)
- Step 7: reuse resolved trackers.md path; skip-with-[WARN] if unavailable
- Step 10: fetch repo metadata instead of list repos; per-status branches
  (401/403, 404, tool-not-found as [WARN], timeout)
```

## Follow-up Candidates

1. Audit `read:user` token-scope check — may now be redundant after Step 10 change
2. Add `--no-probe` flag to suppress curl dependency in airgapped environments
3. Grep other skills for `docs/reference/trackers.md` bare paths — apply same Glob fix
