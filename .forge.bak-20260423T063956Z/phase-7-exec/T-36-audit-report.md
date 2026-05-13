# T-36 Doc Count Drift Audit (2026-04-20)

## Files audited
- `CLAUDE.md`
- `README.md`
- `docs/reference/skills.md`
- `docs/reference/automation-config.md`
- `docs/reference/agents.md`
- `docs/architecture.md`
- `docs/guides/installation.md`
- `docs/guides/autopilot.md`
- `docs/plans/roadmap.md`
- `CONTRIBUTING.md`

Note: `.forge/`, `.forge.bak-*` directories excluded (historical pipeline artifacts — not live source).
Note: `CHANGELOG.md` excluded from stale-mention checks (historical version entries are correct-as-written).

## Negative greps results

| Pattern | Match count (live source) | Files (if any) |
|---------|--------------------------|----------------|
| `15 (shared\|core\|pipeline pattern\|core contracts\|contracts)` | 0 | none |
| `18 optional` | 0 | none (CHANGELOG.md v6.8.0 historical entry exempted) |
| `28 [Ss]kills` | 2 → FIXED | `README.md` lines 3 and 10 (before fix) |
| `(20\|22) agents` | 0 | none |
| `(28\|30) skills` | 0 remaining | `README.md` 2 occurrences fixed in-place |

## Findings

### Stale mentions found and fixed

**README.md — 2 occurrences of "28" for skill count (truth: 29)**

1. `README.md:3` — "21 specialized AI agents, **28** orchestration skills, zero dependencies."
   - Fixed to: "21 specialized AI agents, **29** orchestration skills, zero dependencies."

2. `README.md:10` — Mermaid node label `Skills["<b>Skills</b> (**28**)<br/>Orchestration — WHAT to do"]`
   - Fixed to: `Skills["<b>Skills</b> (**29**)<br/>Orchestration — WHAT to do"]`

### Files confirmed clean (no stale mentions)

- `CLAUDE.md` — correctly shows: 21 agents (line 17), 29 skills (line 18), 16 shared pipeline pattern contracts (line 27), 19 optional config sections (line 160)
- `docs/reference/skills.md` — correctly shows "All 29 skills" (line 3)
- `docs/reference/automation-config.md` — correctly shows "5 required sections and 19 optional sections" (line 9)
- `docs/reference/agents.md` — no stale count mentions
- `docs/architecture.md` — correctly shows `SKL[29 Skills]` (line 27) and "Core Contracts (16)" (line 33)
- `docs/guides/installation.md` — no stale count mentions
- `docs/guides/autopilot.md` — no stale count mentions
- `docs/plans/roadmap.md` — no stale count mentions
- `CONTRIBUTING.md` — no stale count mentions

## Verdict
FIXED_IN_PLACE (2 surgical fixes in README.md, ≤3 threshold — applied in this task)

## Recommendation for T-37
PROCEED
