# Phase 2 Research — Unified Findings

**Sources:** agent-1.md (Categories A+B), agent-2.md (Category C), agent-3.md (Categories D+E+F)

---

## 1. Executive Summary

- **Bug 1 (status_id resolution):** All status-setting call sites use raw passthrough — no tracker-type branching exists anywhere. The `status:{name}` LLM convention is the current Redmine format; changing it to `status_id:{id}` requires touching `docs/reference/trackers.md` (3 rows), both Redmine config templates, `skills/migrate-config/SKILL.md` Step 3, and both `skills/fix-ticket/SKILL.md` and `skills/fix-bugs/SKILL.md`. The onboard wizard requires only `trackers.md` changes (it is a pure reader of that file).
- **Bug 2 (newline encoding):** Every multi-line MCP payload in the pipeline lacks encoding guidance. Six confirmed vulnerable call sites span `agents/publisher.md`, `core/block-handler.md`, `skills/fix-ticket/SKILL.md`, and `skills/implement-feature/SKILL.md`. The only encoding-aware pattern in the codebase is `core/post-publish-hook.md`'s heredoc for a shell `curl` call — correct model but applies only to a single-line payload.
- **fix-bugs is an independent pipeline** that does NOT delegate to fix-ticket; it has no "On start set" step at all, meaning bugs processed via `/fix-bugs` never get their tracker state set to In Progress. Any fix applied to fix-ticket must be duplicated independently in fix-bugs.
- **No post-set verification precedent exists.** All status-set calls across the entire pipeline are fire-and-forget. Introducing read-back verification would be a completely new pattern.
- **migrate-config currently has no Redmine-specific detection.** If `status_id:{id}` becomes canonical, existing Redmine users will need an interactive migration sub-step (IDs are instance-specific and cannot be auto-resolved).

---

## 2. Bug 1: Complete Call-Site Inventory

All status-setting call sites confirmed by research. None have tracker-type branching; all pass values verbatim from config.

| # | Location | File:Line | What it does | Tracker branching | Needs fix |
|---|----------|-----------|-------------|-------------------|-----------|
| 1 | fix-ticket Step 1 | `skills/fix-ticket/SKILL.md:113–116` | Sets `On start set` state when pipeline starts (In Progress) | NO | YES |
| 2 | implement-feature Step 1 | `skills/implement-feature/SKILL.md:163–166` | Sets `Feature Workflow → On start set` (fallback: `Issue Tracker → On start set`); same passthrough | NO | YES |
| 3 | publisher Step 7 | `agents/publisher.md:73–77` | Sets state to "For Review" (from `State transitions`) after PR creation | NO | YES |
| 4 | block-handler Step 2 | `core/block-handler.md:23` | Sets state to Blocked (from `State transitions → Blocked`) on pipeline block | NO | YES |
| 5 | fix-verification Step 6 | `core/fix-verification.md:27–31` | Conditionally re-opens issue (from `State transitions`) when verify command fails after PR merge | NO | YES |
| 6 | fix-bugs Block Handler | `skills/fix-bugs/SKILL.md:641–642` | Sets state to Blocked — same as block-handler pattern but inline in fix-bugs | NO | YES |
| 7 | fix-bugs publisher delegation | `skills/fix-bugs/SKILL.md:562` | Dispatches publisher agent which executes call site #3 | NO | Covered by #3 |

**Note on fix-bugs:** Call site #6 (Blocked) is the only state-set in fix-bugs besides the publisher. fix-bugs has NO "On start set" call — there is no Step 1 equivalent to fix-ticket Step 1. This is an existing functional gap independent of the format bug.

**config-reader:** `core/config-reader.md:15–16` parses `state_transitions` as a verbatim key→value map with zero normalization. This is the upstream source — all call sites receive pre-parsed raw strings.

---

## 3. Bug 2: Complete MCP Body Call-Site Inventory

All multi-line MCP body/description call sites, confirmed by research.

| # | Location | File:Line | What it does | Encoding guidance | Vulnerable |
|---|----------|-----------|-------------|-------------------|------------|
| 1 | publisher Step 6 — PR description | `agents/publisher.md:58–71` | Creates PR with multi-section Description Template (Summary, Changes, Testing, Issue link, Root Cause/Objective) | NONE | YES |
| 2 | publisher Constraints — Block Comment | `agents/publisher.md:95–103` | Posts 6-line Block Comment Template to issue tracker on failure | NONE | YES |
| 3 | block-handler Step 4 — Block comment | `core/block-handler.md:28–36` | Posts 6-line Block Comment Template to issue tracker on block | NONE | YES |
| 4 | fix-ticket Step 4b-tracker — subtask description | `skills/fix-ticket/SKILL.md:369–383` | Creates subtask issues with 4-section description template (scope, Addresses, Files, Parent issue) via `description:`/`body:` MCP parameter | NONE | YES |
| 5 | implement-feature Step 5a — subtask description | `skills/implement-feature/SKILL.md:415–429` | Identical 4-section template to #4, same MCP parameter pattern | NONE | YES |
| 6 | publisher Step 7 — PR link comment | `agents/publisher.md:73–76` | Posts single-line PR URL as comment to issue tracker | N/A | NO (single-line, safe) |
| 7 | block-handler Step 5 — webhook | `core/block-handler.md:39` | Single-line JSON curl payload (reason field max 2 sentences) | N/A | NO (single-line, safe) |
| 8 | post-publish-hook.md — webhook | `core/post-publish-hook.md:17–23` | Single-line JSON heredoc curl; HAS encoding guidance with explicit rationale | YES (heredoc) | NO (single-line, safe) |

**Pattern:** Call sites #1–5 are all genuinely multi-line and all lack encoding guidance. Call sites #6–8 are effectively single-line or safe. `post-publish-hook.md` is the sole encoding-aware example in the codebase, but its heredoc is a Bash shell pattern (for `curl`), not directly applicable to MCP tool parameter passing.

---

## 4. Key Design Decisions Required

### 4a. Where should status_id resolution happen?

**Options identified by research:**

- **Option A — trackers.md format change:** Change the canonical Redmine format from `status:{name}` to `status_id:{id}` in `docs/reference/trackers.md`. The onboard wizard auto-picks this up (it is a pure reader). Requires the user to supply numeric IDs during onboard or migrate-config. No call-site changes needed — IDs are baked into the config at setup time.
- **Option B — per-call-site resolution:** Each call site reads `status:{name}`, performs an MCP lookup (`GET /issue_statuses.json`), resolves to `status_id`, then makes the state-set call. This requires tracker-type branching at every call site (#1–#6 above) and MCP calls in contexts where they may not be allowed (e.g., onboard wizard has no `mcp__*` in allowed-tools).
- **Option C — config-reader normalization:** Extend `core/config-reader.md` to detect Redmine type and resolve `status:{name}` → `status_id:{id}` at parse time (one place). Requires MCP access during config-reader execution, which is not currently in its contract.

**Decision needed:** Which option? Option A is lowest scope (3 rows in trackers.md + migration rule + template updates). Options B and C require architectural changes.

### 4b. Should the fix cover only Redmine or be tracker-agnostic?

All call sites are already tracker-agnostic in their passthrough design. If the fix is a format change in trackers.md (Option A), it is Redmine-specific by definition. If the fix is encoding guidance or verification logic (Option B/C), it should be tracker-agnostic since all trackers share the same call-site pattern. **Decision needed.**

### 4c. How to handle the onboard wizard without MCP access?

The onboard wizard (`skills/onboard/SKILL.md`) has `allowed-tools: Read, Glob, Write, Edit` — `mcp__*` tools are blocked at the harness level. If the fix requires live status_id lookup during onboard (e.g., to generate `status_id:2` rather than `status:In Progress`), the wizard cannot do it. Two sub-options:

- Add an interactive prompt asking the user to supply numeric IDs manually during the wizard (requires running `GET /issue_statuses.json` in a separate terminal and pasting the output).
- Keep `status:{name}` format for wizard output and resolve IDs only at runtime (per-call-site, requires allowed-tools expansion for MCP).

**Decision needed:** Interactive ID collection vs. runtime resolution.

### 4d. What newline encoding instruction to add, and where?

The codebase has one model: `core/post-publish-hook.md` heredoc with explanatory note. But that model is for Bash `curl`, not MCP tool parameters. For MCP calls, the encoding strategy is different (structured parameter passing, not shell strings). Options:

- Add an explicit instruction to each vulnerable call site: "Use `\n` literal escaping when passing multi-line strings to MCP tools."
- Add a shared encoding note in a new `core/` contract (e.g., `core/mcp-encoding.md`) and reference it from each agent/skill.
- Add the instruction to the affected agents' Constraints sections (publisher, block-handler) and to the affected skill steps (fix-ticket 4b-tracker, implement-feature 5a).

**Decision needed:** Centralized contract vs. per-site guidance.

### 4e. migrate-config scope

`skills/migrate-config/SKILL.md` Step 3 currently detects only: (1) bullet-point format, (2) missing `Type` key. If `status_id:{id}` becomes canonical, a new rule is needed:

> "Redmine state transitions in `status:{name}` format (pre-vX.Y) → offer conversion to `status_id:{id}` format"

Unlike existing migrations (purely syntactic), this requires an interactive sub-step: the user must supply numeric IDs for each status name, because IDs are instance-specific and cannot be resolved without live Redmine API access.

**Decision needed:** Is this migration required at this version, or deferred to a later version?

### 4f. fix-bugs coverage

fix-bugs is an independent pipeline with no "On start set" call. If Bug 1 fix adds status_id support to fix-ticket Step 1, that fix does NOT benefit fix-bugs users (because fix-bugs has no Step 1 equivalent). Similarly, any encoding guidance changes in fix-ticket call sites must be replicated independently in fix-bugs.

**Decision needed:** Does the fix scope include adding an "On start set" call to fix-bugs (closing the existing functional gap), or is that deferred?

---

## 5. Risks and Constraints

### Backward compatibility with `status:{name}`

Changing `docs/reference/trackers.md` to make `status_id:{id}` the canonical format would break existing Redmine users whose configs were generated by the old onboard wizard. The Validation Rules table in trackers.md would reject their `status:{name}` values if updated. **Risk:** Silent breakage if migrate-config is not run. Mitigation: keep `status:{name}` accepted in Validation Rules as a legacy alias, or clearly communicate a breaking-change version bump.

### fix-bugs has no "On start set" step

This is a pre-existing functional gap (not introduced by the v6.5.2 change). Any fix to fix-ticket's Step 1 does not close this gap. If the fix plan's scope assumes "all status-sets are fixed," fix-bugs must be explicitly in scope.

### No post-set verification precedent

All status-set calls in the entire pipeline are fire-and-forget (agent-3, E1). Introducing a read-back verification step is a new pattern with no established contract. This means:
- No shared `core/` contract to extend — a new one would be needed.
- Every call site (#1–#6) would need individual read-back logic or a shared delegated step.
- Failure modes (state didn't change) require new decision logic not currently in any agent.

### Publisher is haiku model (minimal instruction-following)

`agents/publisher.md` uses `model: haiku` (confirmed by CLAUDE.md model table: "haiku — publisher, rollback-agent"). Haiku has reduced instruction-following fidelity compared to sonnet/opus. Adding encoding instructions (e.g., "use `\n` escaping in MCP parameters") to the publisher agent's Steps or Constraints carries higher risk of non-compliance than the same instruction in a sonnet-model agent. Any encoding fix in publisher should be kept simple and unambiguous.

### Onboard wizard MCP restriction is a hard harness constraint

The `allowed-tools: Read, Glob, Write, Edit` frontmatter restriction in `skills/onboard/SKILL.md` is enforced by the Claude Code harness, not just a design principle. Adding live MCP lookups (e.g., to resolve status names to IDs) requires amending the `allowed-tools` frontmatter — this is a deliberate design choice that must be explicitly approved, not just a rule to relax.

### Subtask description templates are byte-for-byte identical across fix-ticket and implement-feature

Call sites #4 and #5 use identical templates and identical MCP parameter structures. Any fix applied to one must be applied identically to the other (`skills/fix-ticket/SKILL.md:369–383` and `skills/implement-feature/SKILL.md:415–429`).
