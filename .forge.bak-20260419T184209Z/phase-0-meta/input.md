# User Input (Verbatim)

udelej verzi z roadmapy 2. Nová sekce ## PLANNED — v6.8.1 (Post-v6.8.0 follow-ups) — 6 položek:

- examples/config-templates/* Autopilot row per šablona
- issue_id regex gate (path-traversal defense)
- JSON-encode payload field interpolation dokumentace
- Lock-timeout text alignment (120 vs 125min buffer)
- Fixer-reviewer crash-recovery regression test
- Test harness exit-code propagation (fail propagation)

## Interpretation

The user wants a v6.8.1 PATCH release for the `ceos-agents` plugin (Filip Sabacky's
Claude Code plugin), executing the six "Post-v6.8.0 follow-ups" documented in
`docs/plans/roadmap.md` under the `## PLANNED — v6.8.1` heading.

Release sequence the user expects (per user's memory at
`C:\Users\FSABACKY\.claude\projects\C--gitea-ceos-agents\memory\`):
1. Implement the six items (content changes).
2. Add CHANGELOG entry for v6.8.1 in the same commit sequence.
3. Run `./tests/harness/run-tests.sh` BEFORE committing (140/140 baseline).
4. Commit content + changelog together.
5. Use `/ceos-agents:version-bump` skill as a SEPARATE commit for the 6.8.0 → 6.8.1 bump.
6. Tag.
