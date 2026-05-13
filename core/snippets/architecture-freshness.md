# Snippet — docs/architecture.md freshness check

Canonical advisory-only Bash block for detecting stale `docs/architecture.md`. Cite this file from skill orchestration step boundaries that benefit from freshness reminders.

```bash
# Architecture freshness check (v6.9.0+) — advisory only, non-blocking.
# threshold: 25 commits since last docs/architecture.md edit.
last_commit=$(git log -1 --format="%H" -- docs/architecture.md 2>/dev/null)
if [ -z "$last_commit" ]; then
  echo "[INFO] docs/architecture.md not tracked or absent — skipping freshness check"
else
  commits_since=$(git rev-list HEAD ^${last_commit} --count 2>/dev/null)
  if [ -n "$commits_since" ] && [ "${commits_since}" -ge 25 ]; then
    echo "[WARN] docs/architecture.md has not been updated in ${commits_since} commits (threshold: 25). Consider reviewing it for accuracy before this pipeline run."
  fi
fi
```

**Threshold N=25 rationale:** balance between alert fatigue and meaningful staleness signal. Configurable in v6.9.1+ if operators report tuning needs.

**Lowercase path consistency:** `docs/architecture.md` (NOT the uppercase variant). This lowercase form is canonical per Phase 2 §Q-F-2.

**Non-blocking:** the block always exits 0 (advisory only); pipeline continues regardless of warning/info output.

## Used by:
- `skills/fix-bugs/SKILL.md` line 338 (citation marker `<!-- @snippet:architecture-freshness -->`)

**Expected citation count:** 1 (verifier `tests/scenarios/v690-snippet-citation-counts.sh`).

(Historical: prior to v9.3.0 the legacy `skills/fix-ticket/SKILL.md` was also a citation site between Step 0b and Step 1; it was merged into `fix-bugs`. The former `skills/implement-feature/SKILL.md` citation has likewise been removed.)
