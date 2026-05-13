# Agent 3 — Skeptical Systems Engineer Brainstorm
# v5.6.1 UX Polish: Edge Cases, Failure Modes, and Risk Analysis

**Role:** Skeptical systems engineer — looking for what goes wrong, not what goes right.
**Date:** 2026-03-30

---

## Item 1: --infra Flag Format Change (`ready,later` → `tracker:ready,sc:later`)

### The Breaking Change Problem

This IS a breaking change disguised as a PATCH. The versioning policy states:
> "MAJOR (X.0.0): breaking change in Automation Config contract — new required key, renamed section — OR breaking change in agent output format contract"

The `--infra` flag is not part of the Automation Config contract (it is a CLI flag, not a config key). The versioning policy examples focus on Automation Config and agent output format. CLI flag format changes are not explicitly called out.

However, consider the actual risk: any user with a CI script running `/ceos-agents:scaffold --infra ready,later` will get `"Invalid --infra format. Expected: tracker:ready,sc:later"` after the update. Their automation silently breaks. This is functionally a breaking change even if the versioning policy doesn't require MAJOR.

**Risk level:** Medium. CI scripts and documentation referencing the old format will break silently. The CHANGELOG.md already documents the old format (`--infra ready,later`) in v5.6.0 Added entries. Anyone who read that changelog and built automation is now broken.

**Mitigator:** The flag was added in v5.6.0 (same release cycle boundary). At v5.6.1, very few users have automation using `--infra`. Early adopter risk is low but real.

**Recommendation:** Either (a) support both formats simultaneously with a deprecation notice for the old format, or (b) document explicitly in the changelog that old format scripts must be updated. Option (a) is safer for users; option (b) is acceptable given the flag's newness.

### Edge Case: Old Format Silently Misparsed

Worst case: what if Claude interprets `--infra ready,later` under the new regex and it partially matches something? If the new format validation regex is `tracker:{ready|later},sc:{ready|later}`, then `ready,later` fails cleanly with a validation error. Good. But what if the regex is written more loosely? For example, if the validator only checks for `key:value` pairs and `ready,later` gets misinterpreted as a single unknown key `"ready,later"` with no colon — then the validation fires with a confusing message. Need to ensure the validation error message explicitly shows the new format, not just "invalid format."

### Edge Case: Partial Specification (`--infra tracker:ready` without SC)

The research findings and brainstorm prompt recommend supporting partial specification: omitted key defaults to "later". This is good UX. However:

- What if the user types `--infra tracker:ready,sc:` (empty value after colon)? The validator must handle empty values explicitly — not silently default.
- What if the user types `--infra tracker:READY` (wrong case)? Current format is case-sensitive. New format should maintain case-sensitivity explicitly and the error message must say so.
- What if the user types `--infra tracker:ready sc:later` (space instead of comma)? This would be parsed as part of the project description, not the flag value. The user gets no error — they get wrong behavior. Consider whether the flag parser should detect this pattern and warn.

### Edge Case: Reversed Order (`--infra sc:later,tracker:ready`)

The brainstorm recommendation says "order-independent key:value pairs." This is the right call. But:

- The current Step 0-INFRA parsing says "Parse: first value = tracker preset, second value = SC preset." This positional assumption must be fully removed. If any parsing logic reads `infra_preset.split(",")[0]` as tracker and `[1]` as SC, reversed order silently maps SC values to tracker variables. This is a silent data corruption failure.
- The fix is straightforward (parse by key name, not position), but it must be explicitly stated in the new parsing instruction. The old instruction at line 61 `"first value = tracker preset, second value = SC preset"` must be replaced entirely — partial updates risk leaving the positional assumption in place.

### Versioning Verdict

**This is a PATCH by the letter of the policy but a MINOR-level UX concern in practice.** The flag is new (v5.6.0), the user base is small, the breakage is loud (immediate error, not silent wrong behavior). Proceed as PATCH but document the format change explicitly in changelog.

---

## Item 2: Canary-Write Announcement

### The "Silence After Announcement" Problem

The research finding is correct: the announcement belongs in `scaffold.md`, not `core/mcp-detection.md`. But the critical failure mode is this sequence:

1. Display: "Testing write access to Gitea tracker — creating a temporary canary item..."
2. Canary create call hangs (network timeout, MCP server slow)
3. User waits 30 seconds with no feedback
4. Eventually: either a timeout error, or the create succeeds and the delete hangs

From the user's perspective: they see the announcement, then silence, then possibly an unexpected error. The announcement makes the silence MORE alarming, not less. Without the announcement, the user doesn't know something is happening. With the announcement, they know something is happening but can't tell if it's stuck.

**Risk:** The announcement trades one UX problem (mystery operation) for another (apparent hang). The fix: the announcement should set expectations about timing. Something like "Testing write access to {tracker_type} tracker (this takes a moment)..." is marginally better but still not great.

### The Mode-Ordering Architectural Problem

This is the most serious issue in Item 2. Research confirmed: Step 0-INFRA and Step 0-MCP run **before** Step 0 mode selection. The brainstorm phase-0 prompt says "No interactive mode gating possible (runs before mode selection)." This is correct.

The brainstorm recommendation in phase-0 says "Add `interactive` input parameter to core/mcp-detection.md." But the research phase-1 answers establish the correct placement is in scaffold.md (the caller), not core/mcp-detection.md. These two recommendations contradict each other. The research is more rigorous. Trust the research.

The consequence: you cannot ask "OK to run canary?" in interactive mode because mode is not yet selected. Options:

**Option A: Always announce, never ask.** Simplest. No mode gating. Low confusion risk because the message explains what's happening. Acceptable for PATCH/UX polish.

**Option B: Move mode selection before Step 0-MCP.** This is architecturally correct but is a meaningful restructure of the scaffold pipeline. Step 0-INFRA can still run first (infrastructure declaration is mode-independent), but mode selection could move to between Step 0-INFRA and Step 0-MCP. Risk: this changes the user-visible flow ("what mode?" comes before "checking your tracker"). This may be the right long-term call but feels like too much for a UX polish PATCH.

**Option C: Add a preliminary mode detection by reading --no-implement or other flags early.** Fragile and partial.

**Verdict: Option A is correct for v5.6.1.** Always announce. No interactive ask. Document that interactive ask is a future enhancement if mode selection is reordered.

### Canary Announcement Should Include What to Expect

The announcement should not just say "creating canary." It should say what the canary is and that it will be deleted. Users who see a new item appear in their tracker without warning will be alarmed (even though the canary title says "safe to delete"). The announcement should say: "A test item titled '[ceos-agents] canary — safe to delete' will be created and immediately deleted to verify write permissions."

### What Happens if Canary Cleanup Already Failed (Stale Canary Exists)

`core/mcp-detection.md` step 4 says: "First, check if a stale canary exists: search for open issues with title starting with `[ceos-agents] canary`. If found, delete it before creating a new one."

The announcement happens before this stale cleanup. If a stale canary exists, the user sees "Testing write access — creating canary..." and then a delete operation runs first (not a create). If the delete of the stale canary fails, the create may still proceed or may not. The announcement could be technically misleading. Consider: announce after the stale-cleanup check, not before. Or include "cleaning up previous test items if any" in the announcement text.

---

## Item 3: MCP Jargon → User-Friendly Messages

### The Partial Fix Problem

The research finds 13 other command files using `"MCP server for {Type} is not available..."`. If only `scaffold.md` and `resume-ticket.md` are changed, users get inconsistent messaging:

- `/ceos-agents:scaffold` fails with "Cannot connect to your GitHub tracker. Run /ceos-agents:check-setup..."
- `/ceos-agents:fix-bugs` fails with "MCP server for github is not available. Run /ceos-agents:check-setup..."

This is WORSE than the current consistent (but jargony) approach. Inconsistency in error messages is harder to google, harder to document, and confusing when users switch commands.

**Risk:** The partial fix actively degrades the overall UX relative to the baseline.

**Counter-argument:** The roadmap item explicitly scopes this to v5.6.1 UX Polish, and the brainstorm prompt says "concentrated in `commands/scaffold.md`." A deliberately scoped fix is acceptable if it is acknowledged as incomplete. But the changelog must not claim "user-friendly error messages" globally — it must scope the fix explicitly to scaffold.

**Better approach for v5.6.1:** Fix ALL 15 command files that use the standard pre-flight pattern. The change is mechanical: same find-and-replace applied everywhere. The risk is low (same pattern, same replacement). Doing a partial fix introduces inconsistency without saving meaningful effort. The pattern in 13 other files is identical: search for `"MCP server for {Type} is not available. Run \`/ceos-agents:check-setup\`..."` and replace with the user-friendly version.

### The Error Message Design Risk

The proposed replacement "Cannot connect to your {tracker_type_display} tracker" has a subtle problem: it assumes the service is a tracker. For SC services (GitHub as source control, not as issue tracker), "Cannot connect to your GitHub tracker" is incorrect. GitHub is being used as SC, not as a tracker.

The standard pre-flight message in most command files only ever fires for the issue tracker (they read `Type` from the Issue Tracker config section). So `{tracker_type_display} tracker` is correct for those commands. But scaffold.md checks both tracker AND SC MCP. The replacement text must handle both service types.

For SC: "Cannot connect to your GitHub source control" or "Cannot connect to GitHub (source control)."
For tracker: "Cannot connect to your {tracker_type_display} issue tracker."

The current jargony message at least avoids this distinction by saying "MCP server" without implying what it's for.

### "MCP server for {Type}" Inside Block Comment Detail Field

Line 159 of scaffold.md is inside a Block Comment (the structured `[ceos-agents] 🔴 Pipeline Block` format). The `Detail:` field is a technical field meant to be machine-parseable and informative for debugging. Replacing MCP jargon in the `Detail:` field with user-friendly language may make the block comment LESS useful for technical diagnosis. Block comments are not user-facing UX — they are pipeline log entries. Consider keeping technical language in `Detail:` fields and only changing user-facing display strings.

---

## Item 4: Resume --infra Override

### The Downgrade Attack

The research is clear: `--infra` override on resume should live in `scaffold.md` self-resume path (line 126), not in `resume-ticket.md`. That is correct. But the behavior of downgrading from ready to later is risky:

**Scenario:** User scaffolded with `--infra tracker:ready,sc:ready`. Pipeline ran through Step 4d (push to remote) and Step 4e (create tracker issues). Pipeline blocked at Step 5 (architecture). State.json shows `tracker_status: "ready"`, `sc_status: "ready"` with all detail fields populated.

User resumes with `--infra tracker:later,sc:later` (maybe by accident). The override sets `tracker_effective_status = "later"` and `sc_effective_status = "later"`. But Steps 4d and 4e have already run — the remote has the code and the tracker has issues. The pipeline will skip re-running those steps (they are "completed" in state.json). But downstream steps that depend on infrastructure state (Step 9 final report, Step 5 if it creates tracker sub-issues) now think infrastructure is "later" even though it is actually configured.

**Result:** The final report says "Tracker: Not configured — run /ceos-agents:init" when in fact the tracker is fully configured and issues already exist in it.

**Fix:** The `--infra` override on resume should ONLY accept upgrades (later → ready), not downgrades (ready → later). If the user tries to downgrade a service that was already used in a completed step, display a warning: "Tracker was already configured and used in previous steps. Cannot downgrade to 'later'. Current override ignored for tracker."

### Step 0-MCP Must Re-Run — But State Shows Steps as Completed

Research note: "Step 0-MCP must re-run after any `--infra` override on resume." This is correct in principle but creates a conflict:

If `state.json` shows `infrastructure.tracker_status = "later"` and the user overrides to `tracker:ready`, then Step 0-INFRA (completed) and Step 0-MCP (completed, or skipped because tracker was "later") need to re-execute for the tracker service. But state.json shows those steps as completed. The resume logic that skips completed steps will skip them again.

The resume path at line 126 currently says: "restore in-memory variables from state instead of re-asking." With an `--infra` override, this restore must be partial — restore the detail fields (type, instance, project, remote, base branch) from state if they exist, but re-evaluate MCP readiness for any service whose status is being upgraded.

This is not a trivial text edit. It requires the scaffold self-resume path to conditionally re-run Step 0-MCP for upgraded services. The current "On resume" block is one sentence. The new behavior is complex enough to warrant a multi-step override procedure. Risk of getting this right in a single markdown edit is non-trivial.

### The "--infra tracker:ready" on Resume Still Needs Detail Questions

Research note at Q12: "Re-ask detail questions for any 'ready' service that lacks details in state." This is correct but creates another edge case:

If the user originally ran with `--infra tracker:later` (tracker was not configured, so no tracker details in state), and resumes with `--infra tracker:ready`, the tracker detail fields (`tracker_type`, `tracker_instance`, `tracker_project`) are all null in state.json. The resume override must ask for these details before continuing.

But if the pipeline is resuming mid-step (e.g., blocked at Step 5 architecture), asking tracker configuration questions mid-pipeline is disorienting. The user expects to resume, not to re-configure.

**Verdict:** The `--infra` override on resume is a genuinely complex interaction, not a simple text edit. It is the most dangerous of the 4 items for a PATCH release. Recommend scoping it to: ONLY allow `--infra` override when resuming from Step 0-INFRA or Step 0-MCP (early steps). If the pipeline has progressed past Step 0-MCP, reject the `--infra` override with an error: "Pipeline has already passed infrastructure setup. Cannot override --infra at this stage."

---

## Cross-Cutting Concerns

### The "PATCH Scope Creep" Risk

Items 1 and 4 are being described as PATCH changes but both carry behavioral complexity that could easily introduce regressions:

- Item 1 changes a validation regex and all parsing logic that keys off positional structure — anywhere that assumes `infra_preset.split(",")[0]` is tracker must change.
- Item 4 adds conditional state mutation during resume — a path that interacts with state.json, in-memory variables, and downstream step execution.

Items 2 and 3 are genuinely simple text edits. Items 1 and 4 are more involved.

**Risk of bundling all 4 in a single PATCH release:** If Items 1 or 4 introduce a subtle bug (e.g., reversed tracker/SC parsing, or downgrade of already-used infrastructure), it ships alongside "just a UX polish" with no test coverage (confirmed: no tests for `--infra` format).

**Recommendation:** Consider releasing Items 2 and 3 as v5.6.1 (genuinely low-risk text edits) and Items 1 and 4 as v5.6.2 after adding test coverage for the `--infra` format scenarios.

### Missing Test Coverage

No tests currently validate:
- `--infra` format parsing (old or new format)
- `--issue` + `tracker:later` conflict error
- `--infra` override behavior on resume

Any change to the `--infra` flag system ships without test coverage. The harness runs before committing (per project conventions). If no new tests are added, the pre-commit harness provides no safety net for these changes.

### The Consistent MCP Message Problem Revisited

The 13 other command files that use the old MCP jargon message are not technically in scope for this release. But the research explicitly identifies this as creating inconsistency. The changelog must be precise: do not claim "all error messages are now user-friendly." Claim only "scaffold.md and resume-ticket.md error messages updated for clarity."

---

## Summary of Risks by Item

| Item | Risk Level | Primary Risk | Recommendation |
|------|-----------|--------------|----------------|
| 1: --infra format | Medium | CI script breakage; silent misparsing if old format not detected | Support both formats with deprecation notice, or document breaking change explicitly |
| 2: Canary announcement | Low | Announcement creates "apparent hang" UX | Always announce (no mode gating); include what to expect and that canary will be deleted |
| 3: MCP jargon | Low-Medium | Partial fix creates inconsistency across 15 commands | Fix all 15 files (mechanical change); be precise in changelog scope |
| 4: Resume override | High | Downgrade of already-used infrastructure; complex state interactions | Restrict to upgrades only; reject override if past Step 0-MCP; note this is not a simple text edit |

## Verdict

Items 2 and 3 are safe for v5.6.1. Item 1 is safe with careful dual-format support. Item 4 carries enough complexity and risk that it should either be scoped down significantly (upgrades-only, early-stage-only) or deferred to v5.6.2 with explicit test coverage added first.

The versioning decision (PATCH vs MINOR) is defensible as PATCH for items 1-3. Item 4 touches state mutation during resume — if it introduces any regression, it could corrupt pipeline state. That is a strong argument for a MINOR version or deferral.
