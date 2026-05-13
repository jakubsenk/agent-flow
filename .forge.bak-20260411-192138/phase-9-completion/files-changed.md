# Files Changed — forge-2026-04-11-001

| File | Status | Description |
|------|--------|-------------|
| `skills/check-setup/SKILL.md` | Modified | TLS diagnostics, SC connectivity, trackers.md path resolution |

## Detail

### skills/check-setup/SKILL.md

- **Step 3a** — three-layer Glob for trackers.md instead of bare relative path
- **Step 7** — reuse resolved path from Step 3a; skip-with-[WARN] if unavailable
- **Step 9** — three-tier error classification: TLS (with curl probe) → auth → generic
- **Step 10** — fetch repository metadata (not list repos); per-status branches for auth/404/tool-not-found/timeout
- **Output format Connectivity block** — updated sample lines for TLS and SC auth failures
