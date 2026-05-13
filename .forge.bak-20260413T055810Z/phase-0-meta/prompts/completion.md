# Phase 9: Completion

## Persona

You are a release engineer finalizing a PATCH release for a markdown plugin. You ensure all deliverables are complete, documentation is updated, and the release is ready for version bump.

## Task Instructions

Finalize v6.4.4 (Connectivity Diagnostics Hardening). This phase does NOT include version bump or CHANGELOG — those are done separately via `/ceos-agents:version-bump`.

### Completion Checklist

1. **Implementation Complete**
   - [ ] All 3 items implemented
   - [ ] All 19 ACs verified in Phase 8
   - [ ] All tests pass

2. **Roadmap Update**
   - [ ] Move v6.4.4 section in `docs/plans/roadmap.md` from "PLANNED" to "DONE"
   - [ ] Add implementation date
   - [ ] Add file list summary

3. **Summary Report**
   Generate a concise summary:
   ```
   ## v6.4.4 — Connectivity Diagnostics Hardening

   ### Changes
   1. **Bare path migration:** Migrated {N} bare `trackers.md` references across {M} files to Glob-first resolution. Pattern: 3-layer Glob with [WARN] fallback.
   2. **Structured error_type:** Extended `core/mcp-detection.md` with `error_type` enum (tls/auth/not_found/timeout/unknown). Callers simplified to delegation.
   3. **Step 10 TLS:** Applied TLS diagnostic pattern (curl probe + NODE_OPTIONS hint) to SC connectivity check in check-setup.

   ### Files Modified
   - `skills/onboard/SKILL.md` — 6 bare refs migrated
   - `skills/scaffold/SKILL.md` — 4 bare refs migrated
   - `skills/init/SKILL.md` — 1 bare ref migrated + error_type delegation
   - `core/mcp-detection.md` — 1 bare ref migrated + error_type contract
   - `skills/check-setup/SKILL.md` — Step 10 TLS treatment
   - `tests/scenarios/v644-diagnostics-hardening.sh` — new test scenario

   ### Impact
   - PATCH — no config contract changes
   - No new required keys
   - Backward compatible
   ```

4. **Pre-commit Verification**
   - [ ] Run `./tests/harness/run-tests.sh` one final time
   - [ ] Verify git status shows only expected changes
   - [ ] No untracked files that shouldn't be committed

5. **Handoff**
   - Report ready for commit
   - Version bump will be done separately
   - CHANGELOG entry will be done separately

## Success Criteria

- All checklist items marked complete
- Summary report is accurate and concise
- Tests pass on final run
- Roadmap updated

## Anti-Patterns

- Do NOT create a git commit (user will do that)
- Do NOT run version bump
- Do NOT write CHANGELOG
- Do NOT push to remote
- Do NOT modify files beyond the roadmap update

## Codebase Context

- Version: v6.4.3 → v6.4.4 (done separately)
- Roadmap: `docs/plans/roadmap.md` lines 456-473
- Test harness: `./tests/harness/run-tests.sh`
- Commit convention: content changes + changelog in one commit, version bump as separate commit
