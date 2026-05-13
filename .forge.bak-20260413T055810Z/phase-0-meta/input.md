# Phase 0 Input

Implementace v6.4.4 (Connectivity Diagnostics Hardening) podle roadmapy v docs/plans/roadmap.md — sekce "PLANNED — v6.4.4". Three items:

1. **Bare path migration (trackers.md)**: Migrate all bare `docs/reference/trackers.md` references across the plugin to use Glob-first resolution (the pattern introduced in check-setup v6.4.3). Affects 13+ files: skills/onboard/SKILL.md (6 refs), skills/scaffold/SKILL.md (4 refs), skills/init/SKILL.md (1 ref), core/mcp-detection.md (1 ref), and others. Pattern: Three-layer Glob (`.claude/plugins/**/`, `**/`, CWD fallback) with `[WARN]` on missing file.

2. **Structured error_type in core/mcp-detection.md**: Extend core/mcp-detection.md with a structured `error_type` output field (enum: `tls`, `auth`, `not_found`, `timeout`, `unknown`). Currently raw error strings passed through, each caller parses independently. With error_type, callers become 3-line delegation calls.

3. **Step 10 TLS treatment in check-setup**: Apply the same TLS diagnostic pattern (curl probe + NODE_OPTIONS hint) to the SC connectivity check (Step 10). Currently only Step 9 (Issue tracker) has TLS diagnostics; Step 10 still falls back to generic "unreachable" on TLS failure.

Versioning: PATCH. No version bump needed (done separately).
