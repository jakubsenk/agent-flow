# Phase 3 Brainstorm — Judge Synthesis

---

## 1. Proposal Evaluation

### Agent 1 (Conservative)

| Criterion | Score | Notes |
|-----------|-------|-------|
| Completeness | **9/10** | Covers all 5 AC. Thorough trackers.md changes, onboard, migrate-config, templates, check-setup. Defers verification to v6.6.0 but adds a minimal MCP-error-response check in publisher. |
| Risk | **9/10** | Lowest risk profile. Keeps `status:{name}` accepted as legacy with WARN. No new patterns, no new core contracts. No allowed-tools changes. |
| Scope | **9/10** | 12 files, 0 new core contracts. Stays firmly within PATCH. The migrate-config interactive sub-step is slightly heavy but justified. |
| Practicality | **8/10** | Highly actionable — exact file paths, exact line numbers, exact text blocks. The onboard "run curl in a separate terminal" UX is clunky but pragmatic given the no-MCP constraint. |

**Strengths:** Most complete AC coverage. Treats `status_id:{id}` as the new canonical format while keeping `status:{name}` as a legacy fallback — this solves the root cause. The migrate-config rule is well-designed (interactive because IDs are instance-specific, skippable). Bug 2 coverage hits all 5 vulnerable sites plus the fix-bugs inline block comment. Test scenario for regression prevention.

**Weaknesses:** Defers post-set verification entirely. The "add MCP error-response handling to publisher Step 7" is a half-measure that does not satisfy AC #3 (post-update verification via `redmine_get_issue`) or AC #4 (WARN not BLOCK on verification failure). The onboard UX requires the user to run a curl command in a separate terminal — functional but awkward.

---

### Agent 2 (Innovative)

| Criterion | Score | Notes |
|-----------|-------|-------|
| Completeness | **7/10** | Addresses both bugs systemically but does NOT change the Redmine format to `status_id:{id}`. Relies on "LLM MUST resolve name to ID at runtime" instruction in trackers.md — this is the exact current behavior that is failing. Does not update onboard, migrate-config, or templates meaningfully. |
| Risk | **6/10** | Two new core contracts are additive and advisory-only, so technically safe. But 18 edits across the codebase for a PATCH is on the heavy side. The `status-verification.md` contract introduces a new pattern (read-back) with untested failure modes that Agent 3 correctly identified. |
| Scope | **7/10** | 2 new files + 18 edits. The core contracts are justified architecturally but stretch PATCH boundaries. CLAUDE.md core count update (11 to 13) is a visible structural change. |
| Practicality | **5/10** | The Redmine fix does NOT actually fix the root cause — it doubles down on "LLM resolves at runtime" with stronger instructions, which is the same unreliable mechanism. The verification contract is well-designed but addresses a symptom, not the cause. The MCP body formatting contract is solid. |

**Strengths:** Best systemic thinking. The `core/mcp-body-formatting.md` contract is genuinely useful and prevents the entire class of Bug 2 from recurring. The dependency graph analysis is excellent. Correctly identifies that the problem extends beyond Redmine.

**Weaknesses:** Critically: does NOT fix the Redmine root cause. Keeping `status:{name}` as canonical and telling the LLM to "MUST resolve name to status_id" is the exact current instruction in trackers.md, just stronger-worded. If the MCP server does not expose a `list_statuses` tool (likely — we have not verified this), the instruction is dead code. The verification contract catches the failure AFTER it happens but does not prevent it. This does not satisfy AC #1 (`status_id:22` format parsed correctly) or AC #5 (onboard generates `status_id:XX` format).

---

### Agent 3 (Skeptical)

| Criterion | Score | Notes |
|-----------|-------|-------|
| Completeness | **5/10** | Deliberately minimal. No verification (rejects AC #3 and #4). No onboard changes (rejects AC #5 partially). No migrate-config changes. Bug 2 fix limited to publisher + block-handler only (skips 3 of 5 vulnerable sites). |
| Risk | **10/10** | Lowest possible risk — fixes only confirmed broken behavior. Every concern raised is legitimate. The "wrong numeric ID" risk analysis is the strongest contribution of any proposal. |
| Scope | **10/10** | Smallest footprint. ~5 files changed. Unambiguously PATCH. |
| Practicality | **6/10** | The per-call-site Redmine resolution instruction (6 lines at each of 5 call sites) is code duplication. The "dual-format" approach keeps `status:{name}` as primary and `status_id:{id}` as alternative — this does not actually shift users toward the reliable format. |

**Strengths:** Best risk analysis in the set. The "wrong numeric ID silently corrupts data" concern is valid and must be addressed in the final recommendation. The "fix what is broken, leave what works" principle for Bug 2 is sound. The haiku NEVER-rule formulation is the best of the three proposals.

**Weaknesses:** Too conservative — rejects AC #3, #4, #5 in ways that would leave the acceptance criteria unmet. The per-call-site resolution approach (adding 6-line Redmine-specific blocks to 5 call sites) is more invasive than the trackers.md format change, introduces tracker-type branching where none exists, and relies on an MCP endpoint (`list_statuses`) whose availability is unverified. Refusing to fix subtask description call sites (#4, #5) for Bug 2 leaves known latent bugs unfixed.

---

## 2. Winning Approach — Per Decision

### Bug 1 — Redmine Status Transitions

**Format: `status_id:{id}` as canonical, `status:{name}` as legacy with WARN.**

Winner: **Agent 1.** Agent 2's "stronger LLM instruction" approach does not fix the root cause. Agent 3's "dual-format with runtime resolution" approach is more invasive (per-call-site branching) and relies on unverified MCP capabilities. Agent 1's approach changes the canonical format at the source (trackers.md) so that config values are directly usable by the MCP tool — this matches the design principle that all other trackers already follow (config value = MCP parameter, no LLM translation needed).

Agent 3's concern about wrong numeric IDs is valid. Mitigation: trackers.md Redmine notes, onboard wizard guidance, template TODO comments, and migrate-config skippability all explicitly warn the user to verify their IDs. A wrong numeric ID is a user-configuration error, not a pipeline bug — the same class of error as putting the wrong YouTrack project key in the config. The current silent-failure-due-to-LLM-translation is worse because it is an unpredictable system error, not a deterministic config error.

**Resolution location: trackers.md format change.**

Winner: **Agent 1.** The fix belongs in `docs/reference/trackers.md` (the single source of truth for tracker formats). No config-reader changes (it correctly passes values through). No per-call-site branching (maintains the tracker-agnostic passthrough design). The onboard wizard and check-setup are pure readers of trackers.md — they pick up the change automatically.

**Verification: Advisory post-update verification, scoped to a single core contract.**

Winner: **Agent 2's design, Agent 1's scoping.** Agent 2's `core/status-verification.md` contract is well-designed (advisory, fire-and-warn, never blocks). Agent 3's objections about verification failure modes (timeouts, permissions, race conditions, caching) are valid but are all handled by the "WARN, never BLOCK" policy — they produce log noise at worst, never pipeline failures. Agent 1's deferral to v6.6.0 would leave AC #3 and #4 unmet.

**Decision: Include `core/status-verification.md` as a new advisory core contract.** But scope the integration to 3 high-value call sites only (not all 7), to keep PATCH scope:
- `agents/publisher.md` Step 7 (most visible — PR creation)
- `core/block-handler.md` Step 2 (state transition on block)
- `skills/fix-ticket/SKILL.md` Step 1 (pipeline start)

The remaining 4 call sites (implement-feature Step 1, fix-verification Step 6, fix-bugs block handler, scaffold Step 8b) can be wired in v6.6.0. This is pragmatic: the 3 chosen sites cover the most common paths (start, block, publish).

**Onboard: Interactive ID collection with guidance, no MCP needed.**

Winner: **Agent 1.** The onboard wizard cannot use MCP (hard harness constraint). Agent 1's approach — display a curl command for the user to run in a separate terminal, accept IDs interactively, fall back to defaults if skipped — is the only workable solution. Agent 3's "no changes to onboard" leaves AC #5 unmet.

**Templates: Update to `status_id:{id}` with prominent TODO comments.**

Winner: **Agent 1**, enhanced with Agent 3's caution. Change the template values to `status_id:{id}` format, but make the TODO comment unmissable: verify IDs match your instance. The current TODO already exists in the Oracle template — strengthen it and add it to the Rails template.

**migrate-config: New interactive rule.**

Winner: **Agent 1.** The migrate-config interactive sub-step is necessary for existing Redmine users upgrading to v6.5.2. Agent 3's "no migrate-config changes" leaves users with stale configs and no migration path. The rule is skippable (user can press Enter), which addresses the "cannot auto-resolve" constraint.

**fix-bugs: No "On start set" addition (defer). Apply format fix to existing block handler.**

Winner: **Agent 1.** Adding "On start set" to fix-bugs is a new feature (MINOR), not a bug fix (PATCH). The existing block handler in fix-bugs uses the config value verbatim — the format fix in trackers.md + templates + migrate-config covers it. Note in changelog as a known limitation.

---

### Bug 2 — Publisher Literal `\n`

**Scope: All 5 vulnerable sites.**

Winner: **Agent 1.** Agent 3's argument to fix only publisher + block-handler (2 sites) and skip the subtask description call sites (#4, #5) rests on "no bug reports from those sites." But the research confirms they are byte-for-byte identical templates with zero encoding guidance — they are latently broken. Fixing all 5 is a 1-line addition per site. The risk is negligible (the instruction "use real newlines" is universally correct for MCP tool parameters), and leaving known latent bugs is poor engineering.

**Approach: Per-site NEVER constraint (no new core contract).**

Winner: **Agent 1 + Agent 3's formulation.** Agent 2's `core/mcp-body-formatting.md` contract is well-designed but is MINOR-scope overhead for a PATCH. The same result is achieved by a 1-2 line instruction at each vulnerable site. Agent 3's NEVER-rule formulation ("NEVER use the literal characters `\n`") is optimally haiku-friendly — negative constraints are the strongest signal for instruction-following.

However: **borrow Agent 2's contract text as a DEFERRED item.** The contract design is good and should be created in v6.6.0 to replace the per-site instructions with a single reference. For now, per-site is sufficient.

**Regression prevention: Yes, add a test scenario.**

Winner: **Agent 1.** A test that asserts "actual line breaks" (or equivalent marker text) exists in all 5 vulnerable files prevents future regressions. Minimal cost, high value.

---

## 3. Final Recommendation

### Files to Modify

| # | File | Change | Bug |
|---|------|--------|-----|
| 1 | `docs/reference/trackers.md` | Change Redmine row in State Transition Syntax table to `status_id:{id}` format. Rewrite Redmine note to explain numeric IDs, how to find them, and legacy `status:{name}` as unreliable fallback. Change On Start Set Defaults table Redmine row to `status_id:2`. Change Validation Rules table to accept both `status_id:{id}` and `status:{name}` (legacy). | 1 |
| 2 | `skills/onboard/SKILL.md` | Add Redmine-specific sub-step after Step 2 item 6: display guidance for finding status IDs (curl command), accept user-provided IDs or defaults. No allowed-tools change. | 1 |
| 3 | `skills/migrate-config/SKILL.md` | Add deprecated-pattern rule in Step 3: detect Redmine `status:{name}` format, offer interactive conversion to `status_id:{id}`. Skippable. | 1 |
| 4 | `skills/check-setup/SKILL.md` | Add WARN emission for Redmine configs using legacy `status:{name}` format. | 1 |
| 5 | `examples/configs/redmine-oracle-plsql.md` | Update State transitions and On start set to `status_id:{id}` format. Strengthen TODO comment with ID verification guidance. | 1 |
| 6 | `examples/configs/redmine-rails.md` | Same as #5. Add TODO comment (currently missing). | 1 |
| 7 | `core/status-verification.md` | **NEW FILE.** Advisory post-set verification contract. Read-back after status-set MCP call, compare to expected state, WARN on mismatch, NEVER block. ~40 lines. | 1 |
| 8 | `agents/publisher.md` | (a) Add newline NEVER constraint in Constraints section. (b) Reinforce in Step 6 (PR description). (c) Add "Follow `core/status-verification.md`" after Step 7 status-set. | 1+2 |
| 9 | `core/block-handler.md` | (a) Add newline instruction in Step 4 (block comment). (b) Add "Follow `core/status-verification.md`" after Step 2 status-set. | 1+2 |
| 10 | `skills/fix-ticket/SKILL.md` | (a) Add newline instruction after Step 4b-tracker subtask description template. (b) Add "Follow `core/status-verification.md`" after Step 1 status-set. | 1+2 |
| 11 | `skills/implement-feature/SKILL.md` | Add newline instruction after Step 5a subtask description template. (No verification wiring at this time — deferred.) | 2 |
| 12 | `skills/fix-bugs/SKILL.md` | Add newline instruction after Step X item 4 inline block comment template. (No verification wiring at this time — deferred.) | 2 |
| 13 | `tests/scenarios/` | **NEW FILE** (`mcp-newline-handling.sh` or similar). Assert that all 5 vulnerable files contain the newline instruction marker text. | 2 |

**Total: 13 files (11 edits + 2 new files). 1 new core contract (advisory, leaf-node). 0 config-reader changes. 0 allowed-tools changes. 0 new required config keys.**

### What to Explicitly Defer

| Deferred Item | Reason | Target |
|---------------|--------|--------|
| Verification wiring to remaining 4 call sites (implement-feature Step 1, fix-verification Step 6, fix-bugs block handler, scaffold Step 8b) | Keep PATCH scope manageable; 3 high-value sites cover the most common paths | v6.6.0 |
| `core/mcp-body-formatting.md` centralized contract | Good design (Agent 2) but MINOR scope; per-site instructions sufficient for PATCH | v6.6.0 |
| fix-bugs "On start set" step | New feature, not a bug fix; pre-existing functional gap | v6.6.0 |
| config-reader Redmine normalization | Architectural change, needs MCP access in config-reader | Not planned |
| Onboard wizard MCP access | allowed-tools expansion, design decision beyond PATCH scope | Not planned |
| CLAUDE.md core count update (11 to 12) | Only needed after the new core contract is finalized and merged | Same commit as implementation |

---

## 4. Acceptance Criteria Coverage

| AC | Requirement | How Covered | Files |
|----|-------------|-------------|-------|
| **AC-1** | `status_id:22` format parsed correctly | trackers.md canonical format changed to `status_id:{id}`. Config-reader passes through verbatim (no change needed). All call sites receive `status_id:22` from config and pass it directly to Redmine MCP tool. | trackers.md, templates (2), onboard, migrate-config |
| **AC-2** | `status:In Progress` legacy format logs WARN | trackers.md Validation Rules accepts both formats. check-setup emits `[WARN]` when it detects `status:{name}` without `status_id:`. migrate-config detects and offers conversion. | trackers.md, check-setup, migrate-config |
| **AC-3** | Post-update verification via `redmine_get_issue` | New `core/status-verification.md` contract: after status-set MCP call, read-back issue state and compare to expected. Wired into publisher Step 7, block-handler Step 2, fix-ticket Step 1. Works for ALL trackers, not just Redmine. | core/status-verification.md (new), publisher.md, block-handler.md, fix-ticket SKILL.md |
| **AC-4** | WARN not BLOCK on verification failure | `core/status-verification.md` contract explicitly states: "NEVER block the pipeline on verification failure." All failure modes (mismatch, read-back failure, network error) produce WARN log entries only. | core/status-verification.md (new) |
| **AC-5** | Onboard template generates `status_id:XX` format | Onboard wizard reads trackers.md (which now shows `status_id:{id}` as canonical). Redmine-specific sub-step guides user to find their IDs (curl command) and enter them interactively. Falls back to standard defaults if user skips. Both Redmine config templates updated to `status_id:{id}` format. | onboard SKILL.md, trackers.md, templates (2) |

**All 5 acceptance criteria are covered.**

---

## 5. Design Rationale Summary

The winning approach is **Agent 1's structure with Agent 2's verification contract (scoped down) and Agent 3's NEVER-rule formulation for Bug 2.**

- **Bug 1 root cause** is fixed by changing the canonical format in trackers.md (Agent 1), not by stronger LLM instructions (Agent 2) or per-call-site resolution (Agent 3). The format change makes Redmine consistent with the design principle already followed by all other trackers: config values are directly usable by MCP tools without LLM translation.

- **Bug 1 verification** uses Agent 2's contract design (advisory, universal, fire-and-warn) but with Agent 1's scoping philosophy (3 call sites now, rest later). This satisfies AC #3 and #4 without the scope explosion of wiring all 7 sites.

- **Bug 2** uses Agent 3's NEVER-rule formulation (strongest signal for haiku) applied to Agent 1's scope (all 5 vulnerable sites). No centralized contract for now (Agent 2's `core/mcp-body-formatting.md` deferred to v6.6.0).

- **Agent 3's risk concerns** are addressed: wrong numeric IDs are a user-config error mitigated by TODO comments, onboard guidance, and migrate-config skippability. Verification false positives are handled by the WARN-never-BLOCK policy. Subtask description sites are fixed despite no bug reports, because the latent bug is confirmed by research.
