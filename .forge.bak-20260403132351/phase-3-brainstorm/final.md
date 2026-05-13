# Phase 3: Brainstorm Synthesis

## Judge-Mediated Recommendation

After evaluating conservative, innovative, and skeptical perspectives, here is the recommended approach per issue.

### Issue 1: Design Quality — DEFERRED TO ROADMAP

**Decision:** Deferred to future version. Recorded in `docs/plans/roadmap.md` under EXPLORING. Needs its own full forge run with research to determine whether a new agent, scaffolder extension, or spec-writer enhancement is the right approach.

**Rationale:** User feedback: "je potřeba se nad tím zamyslet jak to nejlépe řešit." LLMs don't have visual taste — the fix must focus on tooling (CSS framework, design tokens), not aesthetics. Multiple approaches exist (new agent, hybrid, minimal) and each has real trade-offs worth exploring separately.

### Issue 2: Story Linking — CONSERVATIVE WINS

**Decision:** Inline the tracker-specific parent parameter names directly in Step 4e. Add a verification sub-step (from skeptic) to read back the created issue and confirm parent is set.

**Scope:**
- `skills/scaffold/SKILL.md` Step 4e: Replace "using the tracker's native parent parameter" with explicit per-tracker parameter table inline. Add verification sub-step after creation.

**Versioning:** PATCH

### Issue 3: Story Closing — CONSERVATIVE+SKEPTIC WINS  

**Decision:** Remove cascade assumption. Explicitly close ALL story issues for ALL trackers. Handle already-closed issues gracefully (treat as success).

**Scope:**
- `skills/scaffold/SKILL.md` Step 8b: Remove tracker-type branching for close behavior. Close all stories explicitly. Add "If issue is already in target state, treat as success" instruction.

**Versioning:** PATCH

### Issue 4: Implementation Comments — CONSERVATIVE+SKEPTIC WINS

**Decision:** Add implementation summary comment per epic (NOT per story — per skeptic's noise concern). Posted before closing. Aggregate story completion status. WARN on failure, never BLOCK.

**Scope:**
- `skills/scaffold/SKILL.md`: Add Step 8a between E2E tests and Step 8b. Post `[ceos-agents]` prefixed comment on each epic issue.

**Versioning:** PATCH

### Issue 5: Diacritics Preservation — CONSERVATIVE+INNOVATIVE

**Decision:** Add language fidelity constraint to spec-writer (primary text producer) and scaffold SKILL.md Step 4e (tracker issue creation). The constraint should be explicit: "Preserve all diacritics and non-ASCII characters from user input exactly."

**Scope:**
- `agents/spec-writer.md`: Add NEVER constraint about diacritics stripping
- `skills/scaffold/SKILL.md` Step 4e: Add language fidelity instruction for issue titles/descriptions

**Versioning:** PATCH

## Overall Versioning

Issues 2-5 are PATCH. Issue 1 is arguably MINOR (new optional spec section). However, since the spec-writer's output format is internal (no consuming project reads it as a contract), this can be treated as PATCH too. Final call: **PATCH version bump**.

## Implementation Order

4 fixes (Issue 1 deferred). All independent — can be implemented in parallel. Grouping:
1. **Tracker cluster** (Issues 2, 3, 4): All in `skills/scaffold/SKILL.md`
2. **Diacritics** (Issue 5): `agents/spec-writer.md` + `skills/scaffold/SKILL.md`

Total estimated change: ~40-60 lines across 2 files.
