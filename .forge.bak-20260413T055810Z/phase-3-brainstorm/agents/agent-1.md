# Agent 1 — Steady Eddie (Conservative)

Persona: Proven patterns, minimal change, backward compatibility.

---

## Q1: Bare Path Resolution Placement

### Option A — File-top preamble (resolve once at file top)

Resolving at the very top of the file means the variable is available everywhere, but it forces a Glob call even if the skill exits early (e.g., scaffold exits at Step 0-INFRA if tracker = "later"). Adds a small overhead to every invocation. Not how check-setup does it — check-setup resolves at Step 3a, which is the first step that needs the path.

- Risk: Unnecessary Glob on early-exit paths.

### Option B — First-reference (resolve once at the first step that uses it)

This is exactly what check-setup does: Step 3a is the first consumer, the path is resolved there, and Step 7 reuses it ("reuse the trackers.md path resolved in Step 3a"). The pattern is proven, well-understood, and already documented in the codebase. For onboard, that means Step 2 start. For scaffold, that means Step 0-INFRA start. For init, it is inline at Step 0 since there is only one reference.

- Risk: Minimal. A future editor might add a reference before the resolve point and not realize the variable is not yet available. The path-note blockquote mitigates this.

### Option C — Every reference (resolve at every point of use)

This would mean up to 6 separate Glob calls in onboard and 4 in scaffold. Redundant, slow, and violates check-setup Step 7's explicit prohibition: "reuse the trackers.md path resolved in Step 3a (do not Glob again)." Introduces inconsistency with the established pattern.

- Risk: Performance degradation; contradicts the codebase's own stated principle.

### Recommendation: Option B (first-reference)

**Rationale:** This is what check-setup already does (Step 3a resolve, Step 7 reuse). Copying a proven in-codebase pattern is the lowest-risk approach and maintains consistency across skills. The research document (Section 1, "Resolve-Once vs. Inline Decision" table) already reached the same conclusion for each file.

**Risk:** Near-zero. The pattern has been live since the check-setup TLS diagnostics were added (commit cf25e54) and has not caused issues.

**If forced to pick differently:** I would choose Option A only for scaffold (because scaffold is a long pipeline and early resolution avoids the risk of a late-added reference missing the variable), but keep Option B for onboard and init. I would NOT choose Option C under any circumstance.

---

## Q2: error_type Classification Location

### Option A — Process section (add classification logic inline in Process steps)

This would mean inserting the 5-value enum and its pattern-matching rules into the Process step 3 description. It bloats the Process section, which currently describes a clean procedural flow (look up, check tool, verify read, canary write). Process is meant to describe WHAT happens, not detailed error classification logic. Structural change to the flow of mcp-detection.md.

- Risk: Makes the Process section harder to read. Mixes procedural steps with classification tables.

### Option B — Failure Handling section (add error_type assignment to existing failure scenarios)

The Failure Handling section already enumerates the exact scenarios where errors occur (no matching tool, read fails, write create fails, write delete fails). Adding an `error_type` assignment to each scenario is purely additive — one new field per existing bullet. The Output Contract gets a new field definition. No restructuring of Process or any other section. This is the minimal structural change to mcp-detection.md.

- Risk: Very low. The Failure Handling section already describes the error cases; we are annotating them with a classification label.

### Option C — Inline per case (scatter error_type assignments across Process and Failure Handling)

This would mean each step in Process that can fail gets an inline error_type note, AND the Failure Handling section also mentions them. Redundancy creates maintenance risk — if we add a 6th error_type in the future, we must update it in multiple places. Violates the single-source principle.

- Risk: Duplication drift. Future edits might update one location but not the other.

### Recommendation: Option B (Failure Handling section)

**Rationale:** The Failure Handling section is the natural home for error classification — it already lists every failure scenario. Adding `error_type` assignment there is additive (no deletions, no moves) and keeps the Process section's procedural clarity intact. The Output Contract gets a new field definition — also purely additive.

**Risk:** Callers (init, scaffold) must look at Failure Handling rather than Process to understand what error_type they will receive. This is acceptable because the Output Contract field definition will reference the enum values, giving callers everything they need without reading Failure Handling.

**If forced to pick differently:** I would choose Option A, placing a compact classification table at the end of Process step 3 (after the "If connectivity fails" line). I would not choose Option C because duplication across sections is a maintenance antipattern in a pure-markdown codebase with no automated consistency checks.

---

## Q3: Step 10 TLS Mirroring Scope

### Option: Exact mirror of Step 9

Copy Step 9's TLS branch verbatim and paste it into Step 10 with only label changes ("Issue tracker" becomes "Source control"). This gives maximum consistency — the two steps look identical in structure, same 8 TLS patterns, same curl probe logic, same NODE_OPTIONS hints.

- Risk: Duplication. If Step 9 is later updated (e.g., a 9th TLS pattern is added), Step 10 must be updated in lockstep. In a pure-markdown codebase there is no extraction mechanism to share logic between steps.

### Option: Adapted for SC (add SC-specific URL derivation)

Step 10 cannot use `{Instance}` for the curl probe because the SC Remote is `owner/repo`, not a URL. This option adds a derivation block to extract `{sc_base_url}` from the SC MCP server entry in `.mcp.json`. The research document provides a complete replacement text for this approach (Section 3, "Step 10 — Complete Replacement Text"). The TLS patterns, curl logic, and NODE_OPTIONS hints mirror Step 9, but the URL derivation is SC-specific.

- Risk: Slightly more complex than a pure copy because of the URL derivation logic. However, this complexity is inherent to the SC use case — `owner/repo` genuinely is not a URL, so this adaptation is required regardless.

### Option: Minimal (just TLS detection + hint, no curl probe)

Skip the curl probe entirely. When a TLS pattern is detected, immediately emit `[FAIL]` with the NODE_OPTIONS hint. This is simpler and avoids the `{sc_base_url}` derivation problem entirely. The curl probe in Step 9 exists to distinguish "server reachable but TLS rejected by MCP" from "server completely unreachable" — useful diagnostic detail but not strictly necessary for the fix action (NODE_OPTIONS hint is the same either way).

- Risk: Less diagnostic precision. The user cannot tell whether the server is genuinely unreachable or just has a TLS issue. However, the NODE_OPTIONS hint covers the most common case (corporate/private CA), and the catch-all already suggests verifying the URL.

### Recommendation: Adapted for SC (research document's proposed text)

**Rationale:** The research document's proposed replacement (Section 3) is the right balance. It reuses Step 9's TLS patterns and curl structure verbatim (maximum consistency where it matters — pattern list and hint messages), while adding the necessary SC-specific URL derivation. The derivation is simple: extract base hostname from the SC MCP server entry in `.mcp.json`, which check-setup already reads in Step 6-7. The adapted version also preserves Step 10's existing SC-specific branches (auth with per-platform scopes, 404 with repo name, tool-not-found as WARN) which are better than Step 9's equivalents.

**Risk:** The `{sc_base_url}` derivation adds ~4 lines of new logic. If the derivation fails (e.g., no parseable URL in the MCP config), the text already specifies a fallback: skip the probe and emit the no-curl-available variant. This is a graceful degradation.

**If forced to pick differently:** I would choose the minimal option (TLS detection + hint, no curl probe). The curl probe provides diagnostic nuance but the actionable advice (NODE_OPTIONS hint) is the same in both curl outcomes. Dropping the probe would make Step 10 simpler and avoid the URL derivation question entirely. I would NOT choose the exact mirror because it pretends the SC and tracker contexts are identical when they are structurally different (URL vs. owner/repo).

---

## Summary Matrix

| Question | Recommendation | Confidence | Change footprint |
|----------|---------------|------------|-----------------|
| Q1: Bare path placement | B (first-reference) | High | Matches check-setup exactly; 3 files get resolve-once blocks |
| Q2: error_type location | B (Failure Handling) | High | Additive only; Output Contract + Failure Handling in mcp-detection.md |
| Q3: Step 10 TLS scope | Adapted for SC | Medium-High | Research doc's replacement text; ~25 lines replace ~7 lines in Step 10 |

### Implementation order preference

Follow the research document's recommended order (Section 4):
1. `core/mcp-detection.md` — error_type (B) then path-note (A) in one session
2. `skills/check-setup/SKILL.md` — Step 10 replacement (C)
3. `skills/init/SKILL.md` — single bare ref (A)
4. `skills/onboard/SKILL.md` — 6 bare refs (A)
5. `skills/scaffold/SKILL.md` — 4 bare refs, chunked reads (A)

This order minimizes line-number drift between edits and handles the dual-edit file (mcp-detection.md) first.
