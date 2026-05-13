ceos-agents v6.8.0 — Autopilot + Observability.

Téma: headless deployment + monitoring. Tři položky balené dohromady, protože Autopilot je primární consumer observability dat.

Scope (detaily v `docs/plans/roadmap.md` pod `## PLANNED — v6.8.0`):

1. **Autopilot skill** `/ceos-agents:autopilot` — thin dispatcher pro headless běh. Čte Bug/Feature query, klasifikuje, dispatchuje existující skills (fix-ticket / implement-feature).
Lock file, nová optional config sekce `### Autopilot`. Zdroj: forge brainstorm 2026-04-05 (schválený).

2. **Observability Hooks (D10)** — rozšířit webhook systém o `pipeline-started`, `step-completed`, `pipeline-completed` eventy. Zdroj: external review 2026-04-08, D10.

3. **Real-Time Cost Visibility** — per-stage `tokens_used` / `duration_ms` / `tool_uses` v state.json, mechanismus kopíruje forge.json 1:1. Pipeline summary tabulka, `/metrics` agreguje.

Constraints:
- Plugin je pure-markdown
- Žádné breaking changes v Automation Config
- Czech se mnou, English ve všech souborech
- Testy přes `./tests/harness/run-tests.sh`
- Changelog + version bump přes `/ceos-agents:version-bump` jsou součástí závěru
- Review dokumenty do `docs/plans/` jako `{name}-REVIEW.md`
