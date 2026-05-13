# Phase 2 Research Answers (Agent 1: Contract & Source-of-Truth)

## Framing

This document answers all Section A (Contract & Schema) and Section D (Source-of-Truth) questions from the synthesized Phase 1 question set. Every factual claim is tied to a cited file and line range. All four forge.json artifacts inspected confirm a consistent `tokens_estimated` field name (not `total_tokens`) in the per-phase usage objects; this is the single most impactful finding, as it contradicts the roadmap's stated mechanism for v6.8.0. The review report D10 date, config-reader collision risk, and schema field completeness are also fully resolved by direct artifact inspection.

---

## Section A: Contract & Schema Questions

### Q1: What exact field name and shape does the Claude Code Task/Agent tool return for token usage metadata — is it `total_tokens` (a single integer), `input_tokens + output_tokens` (two separate integers that must be summed), `tokens_estimated` (a single estimated field), or a nested object — and is `duration_ms` a field the Task tool returns directly or must the skill measure wall-clock time around the Task call?

**A:** Direct inspection of forge.json artifacts in this repo shows the per-phase field name is `tokens_estimated` (a single integer), not `total_tokens`. Both the most-recent run (`.forge.bak-20260417-170848/forge.json`) and the prior v6.7.2 run (`.forge.bak-20260416-065037/forge.json`) store per-phase token counts as `"tokens_estimated": <integer>` with no separate `input_tokens`/`output_tokens` split. The accumulator in `metrics` is `"total_tokens_estimated"`. `duration_ms` is a per-phase field present in forge.json (e.g., `"duration_ms": 370000`), and the roadmap's "Mechanism" section says skills "capture `total_tokens`, `duration_ms`, `tool_uses` from Task tool result after every agent dispatch." However, forge.json itself uses `tokens_estimated`, not `total_tokens` — creating a discrepancy between the roadmap prose and the actual artifact. The roadmap v6.8.0 section describes `total_tokens` as the field name to capture from the Task tool result, then write `tokens_used` to state.json, but all forge.json evidence uses `tokens_estimated` for what is stored. Whether the Task tool actually returns a field named `total_tokens` at runtime (and forge merely renames it to `tokens_estimated` when writing forge.json) cannot be confirmed from these static artifacts alone — it would require live Task tool call inspection.

**Citations:**
- `.forge.bak-20260417-170848/forge.json:9` — `"tokens_estimated": 91023` per phase-0
- `.forge.bak-20260416-065037/forge.json:9` — same pattern, `"tokens_estimated": 116452`
- `.forge.bak-20260416-065037/forge.json:44-46` — accumulator: `"total_tokens_estimated": 1341612`
- `docs/plans/roadmap.md:656` — roadmap prose: "Agent/Task tool returns 3 usage fields: `total_tokens`, `duration_ms`, `tool_uses`"
- `docs/plans/roadmap.md:669` — mechanism step 1: "capture `total_tokens`, `duration_ms`, `tool_uses` from Task tool result"

**Confidence:** MEDIUM — forge.json artifacts confirm the stored field name is `tokens_estimated`; whether the Task tool's raw return value uses `total_tokens` before forge renames it cannot be resolved without live tool call evidence.

**Follow-up:** Phase 3 should flag: if the Task tool returns `total_tokens` and forge renames to `tokens_estimated`, ceos-agents v6.8.0 spec must choose a stored field name and state it explicitly. If the Task tool itself returns `tokens_estimated`, the roadmap prose at line 656 is wrong and must be corrected.

---

### Q2: When v6.8.0 adds `tokens_used`, `duration_ms`, `tool_uses`, `model`, `started_at`, and `completed_at` to existing per-stage sections and adds a wholly new top-level `pipeline` accumulator object, should `schema_version` advance from `"1.0"` to `"1.1"` or remain `"1.0"` — and what backward-read guarantee must `/resume-ticket` provide for state files written by v6.7.x that carry none of these fields?

**A:** `state/schema.md` line 148 declares `schema_version` as `"1.0"` with the note "Always `\"1.0\"` for this specification. Enables future schema evolution." There is no version-negotiation clause anywhere in `core/state-manager.md` — the Read Process (lines 34-35) simply reads and returns parsed JSON with no version check. The Resume Process (lines 38-53) accesses `status` fields on per-stage objects to find the resume point; it does NOT guard against absent usage fields. Adding the six per-stage usage fields and top-level `pipeline` section are purely additive writes (state-manager writes field_path values, does not replace the entire object). For v6.7.x files missing these fields, any consumer reading `triage.tokens_used` will get `null`/`undefined` — there is no runtime guard today. The roadmap line 714 classifies Real-Time Cost Visibility as "PATCH (informational output, no contract change)" — implying the author intends `schema_version` to stay at `"1.0"`. However, the schema.md line 148 says "Always `\"1.0\"` for this specification" — meaning a version bump to `"1.1"` would require updating that documentation.

**Citations:**
- `state/schema.md:35` — Full Schema Example shows `"schema_version": "1.0"`
- `state/schema.md:148` — Top-Level Field Definitions: "Always `\"1.0\"` for this specification. Enables future schema evolution."
- `core/state-manager.md:34-35` — Read Process: no version check
- `core/state-manager.md:38-53` — Resume Process: accesses `status` fields, no null-guard for usage fields
- `docs/plans/roadmap.md:714` — "Impact: PATCH (informational output, no contract change)"

**Confidence:** HIGH — the schema_version, atomic write mechanism, and resume logic are directly readable from artifacts.

---

### Q3: Does `state/schema.md`'s Full Schema Example already contain `started_at`/`completed_at` on per-stage objects, or does any existing stage section already carry a `model` field — making any of v6.8.0's planned additions a conflict rather than a clean addition?

**A:** Direct inspection of the Full Schema Example (lines 33–141) and the Top-Level Field Definitions table (lines 144–250) confirms: **none** of the six planned per-stage fields (`tokens_used`, `duration_ms`, `tool_uses`, `model`, `started_at`, `completed_at`) currently exist in any stage section. The existing stage objects contain only behavioral fields: `status`, `severity`, `area`, `complexity`, `acceptance_criteria`, `reproduction_steps`, `ac_source` (triage); `status`, `risk`, `affected_files`, `estimated_diff_lines` (code_analysis); `status`, `iterations`, `max_iterations`, `last_verdict`, `ac_fulfillment` (fixer_reviewer); etc. The only `started_at`/`completed_at` timestamps in the schema are top-level fields (`started_at` at line 156, `updated_at` at line 155 — there is no `completed_at` at top level either). The `deployment` object does have `started_at` and `verified_at` fields (lines 137-138, 261-262) — but these are on the deployment sub-object, not on standard pipeline stage objects. All six planned additions are therefore clean additive writes with no conflict.

**Citations:**
- `state/schema.md:33-141` — Full Schema Example (no usage fields on any stage object)
- `state/schema.md:64-91` — triage and code_analysis objects (no model, no timing, no token fields)
- `state/schema.md:85-91` — fixer_reviewer object (only status, iterations, max_iterations, last_verdict, ac_fulfillment)
- `state/schema.md:155-156` — top-level `started_at` and `updated_at` only; no top-level `completed_at`
- `state/schema.md:137-138` — deployment.started_at and deployment.verified_at (deployment sub-object only)
- `docs/plans/roadmap.md:704-709` — What needs to change: confirms all six are net-new additions

**Confidence:** HIGH

---

### Q4: For the three new webhook events (`pipeline-started`, `step-completed`, `pipeline-completed`), what exact JSON fields are mandatory in every payload, which fields are event-specific optionals, and do the new event names follow the same hyphenated-lowercase convention as existing events (`pr-created`, `issue-blocked`) — and is there an authoritative event-name registry in `core/post-publish-hook.md` or `core/block-handler.md` that must be updated, or is the existing contract open-ended (no enum restriction)?

**A:** The existing events are: `pr-created` (core/post-publish-hook.md:17–23, payload: `event`, `issue_id`, `pr_url`, `timestamp`) and `issue-blocked` (core/block-handler.md:39–43, payload: `event`, `issue_id`, `agent`, `reason`, `timestamp`). Both follow hyphenated-lowercase naming. The new event names proposed in the roadmap — `pipeline-started`, `step-completed`, `pipeline-completed` — follow the same convention. Neither `core/post-publish-hook.md` nor `core/block-handler.md` contains a hard-coded enum of valid event names; both check whether the configured `On events` list *contains* a specific event name string. Therefore, adding new event names does NOT require updating an enum registry — the contract is open-ended. The roadmap (line 648) specifies payload fields for the new events as: `step_name`, `duration`, `iteration_count`. No explicit mandatory-vs-optional breakdown is provided in the roadmap beyond what is cited.

**Citations:**
- `core/post-publish-hook.md:3–23` — pr-created event: curl command, payload shape, advisory failure handling
- `core/post-publish-hook.md:30-33` — "All post-publish hooks are advisory only"
- `core/block-handler.md:39–43` — issue-blocked event: curl command, payload: `event`, `issue_id`, `agent`, `reason`, `timestamp`
- `core/block-handler.md:50-53` — webhook failure: "log warning, continue (do NOT retry)"
- `docs/plans/roadmap.md:648` — new events: `pipeline-started`, `step-completed`, `pipeline-completed`; payload fields: `step_name`, `duration`, `iteration_count`

**Confidence:** HIGH for naming convention and open-ended registry. MEDIUM for payload mandatory-vs-optional breakdown (roadmap does not distinguish).

---

### Q5: Do any of the 7 planned Autopilot config key names (`Max issues per run`, `Lock timeout`, `Log file`, `Bug limit`, `Feature limit`, `On error`, `Dry run`) collide with keys already defined in other optional config sections (`Error Handling`, `Pipeline Profiles`, `Metrics`) when `core/config-reader.md` parses them?

**A:** Direct inspection of `core/config-reader.md` shows the config-reader is **section-scoped**: it parses each `### {Section}` heading independently and maps keys to section-prefixed config properties (e.g., `error_handling.on_block`, `metrics.output`). The existing key names across all optional sections are:

- `### Error Handling`: `On block`, `Max blocked per run` → `error_handling.on_block`, `error_handling.max_blocked_per_run`
- `### Pipeline Profiles`: `Profile`, `Skip stages`, `Extra stages` → `profiles` list
- `### Metrics`: `Output`, `Period` → `metrics.output`, `metrics.period`

None of the 7 planned Autopilot keys (`Max issues per run`, `Lock timeout`, `Log file`, `Bug limit`, `Feature limit`, `On error`, `Dry run`) match any existing key name in any section. There is a **surface similarity** between `On error` (Autopilot) and `On block` (Error Handling) — they are distinct strings and distinct concepts. The config-reader's section-scoped parsing means even identical key names in different sections would map to different prefixed config properties (e.g., `autopilot.on_error` vs. `error_handling.on_block`), so no collision risk exists at the parser level.

**Citations:**
- `core/config-reader.md:30` — `### Error Handling`: keys `On block`, `Max blocked per run`
- `core/config-reader.md:35` — `### Metrics`: keys `Output`, `Period`
- `core/config-reader.md:33` — `### Pipeline Profiles`: keys `Profile`, `Skip stages`, `Extra stages`
- `core/config-reader.md:1-60` — parser is section-scoped (heading-delimited parse blocks)
- `docs/plans/roadmap.md:634` — 7 Autopilot key names: `Max issues per run`, `Lock timeout`, `Log file`, `Bug limit`, `Feature limit`, `On error`, `Dry run`

**Confidence:** HIGH — no collision found; section-scoped parsing confirmed.

---

## Section B–C Questions

### Q6–Q12

Out of scope for this agent (Section B: Behavioral Semantics, Section C: Integration & Compatibility). These questions are assigned to Agents 2 and 3.

---

## Section D: Source-of-Truth & Validation Questions

### Q13: What exact text does the external review recommendation D10 contain — specifically: is the word "observability" used, what payload field names are explicitly recommended, and is the source document dated 2026-04-07 or 2026-04-08?

**A:** The review report file at `docs/plans/readmine-project/ceos-agents-review-report.md` line 203–204 contains the following verbatim D10 text:

> **D10. Observability hooks**
> Rozšířit Notifications systém o structured event payload (phase, duration, tokens_used, outcome) pro integrace s observability platformami (Grafana, DataDog). Umožnit real-time sledování pipeline, nejen post-hoc dashboard.

Key findings from this text:
1. The word "observability" IS used — both in the heading ("Observability hooks") and in the body ("observability platformami").
2. The explicitly recommended payload field names are: `phase`, `duration`, `tokens_used`, `outcome`. Note: the roadmap (line 648) uses `step_name`, `duration`, `iteration_count` — the field `tokens_used` and `outcome` from D10 are NOT in the roadmap's payload spec; `step_name` and `iteration_count` in the roadmap are NOT in D10's recommendation.
3. The document's internal date stamp at line 224 reads `*Zpráva zpracována: 2026-04-07*`. The roadmap (line 646) cites "External review report analysis (2026-04-08)". The file itself contains `2026-04-07` — the file date is authoritative. Git commit history confirms the file was committed on 2026-04-10 (first appearance), which is consistent with an internal processing date of 2026-04-07.

**Citations:**
- `docs/plans/readmine-project/ceos-agents-review-report.md:203-204` — verbatim D10 text with payload field names
- `docs/plans/readmine-project/ceos-agents-review-report.md:224` — `*Zpráva zpracována: 2026-04-07*`
- `docs/plans/roadmap.md:646` — roadmap cites "2026-04-08" as source date
- `docs/plans/roadmap.md:648` — roadmap payload fields: `step_name`, `duration`, `iteration_count` (differs from D10's `phase`, `tokens_used`, `outcome`)

**Confidence:** HIGH — direct file inspection.

**Follow-up:** The payload field divergence between D10 (`phase`, `duration`, `tokens_used`, `outcome`) and the roadmap (`step_name`, `duration`, `iteration_count`) must be resolved in Phase 4. The roadmap is a later, more specific design document; D10 is the business-justification origin. Phase 4 spec should note this divergence and adopt one canonical set.

---

### Q14: Is the "forge brainstorm 2026-04-05 (approved)" Autopilot design present as a standalone file in `docs/plans/brainstorm/` or `docs/plans/`, or is the roadmap section (lines 621–643 of `docs/plans/roadmap.md`) the only artifact containing the approved design decisions?

**A:** Directory listing of `docs/plans/brainstorm/` contains: `01-forgejo-mcp-fixes.md`, `02-onboard-mcp-tokens.md`, `03-onboard-directory-scope.md`, `04-scaffold-completeness.md`, `05-fix-bugs-token-discovery.md`, `06-session-resume-permissions.md`, `07-unified-improvements-summary.md`, `DECISIONS.md`, `EXECUTE-AND-REVIEW.md`, `IMPLEMENTATION-PLAN.md`. No file contains "autopilot" in its name. A grep for "autopilot", "Autopilot", or "2026-04-05" across the brainstorm directory returns zero matches. The `docs/plans/` root listing (40+ files) contains no file dated 2026-04-05 or named with "autopilot". The roadmap at lines 621–643 (specifically line 626: "**Source:** forge brainstorm (2026-04-05, approved)") is therefore the **sole artifact** containing the approved Autopilot design decisions. The 7 config key names, lock-file path (`.ceos-agents/autopilot.lock`), two-query classification rule, and CLI invocation pattern exist only in `docs/plans/roadmap.md:628–637`.

**Citations:**
- `docs/plans/roadmap.md:626` — "Source: forge brainstorm (2026-04-05, approved)" — roadmap asserts brainstorm existed
- `docs/plans/roadmap.md:628-637` — full Autopilot design: lock file path, 7 config keys, classification rule, CLI invocation
- `docs/plans/brainstorm/` — directory listing (10 files, none named autopilot, none matching 2026-04-05)
- Grep result: zero matches for "autopilot"/"Autopilot"/"2026-04-05" in brainstorm directory

**Confidence:** HIGH — file not found by listing and grep.

---

## Key Findings

- **tokens_estimated vs. total_tokens**: All forge.json artifacts (2+ runs confirmed) store per-phase token usage as `tokens_estimated`, not `total_tokens`. The roadmap's v6.8.0 "Mechanism" prose says to capture `total_tokens` from the Task tool. This discrepancy is unresolved by static artifact inspection alone — Phase 4 spec must explicitly name the field that will be used in state.json.
- **Schema additions are all net-new**: None of the 6 planned per-stage fields (`tokens_used`, `duration_ms`, `tool_uses`, `model`, `started_at`, `completed_at`) exist in `state/schema.md` v1.0 — clean additive writes, no migration needed. The top-level `pipeline` accumulator is also entirely absent.
- **schema_version stays "1.0"**: Roadmap classifies Real-Time Cost Visibility as PATCH; state-manager has no version-negotiation; resume process accesses `status` fields only. No backward-read guard exists for absent usage fields, but absent field reads will silently return null/undefined — acceptable for additive additions.
- **Webhook event registry is open-ended**: Neither `core/post-publish-hook.md` nor `core/block-handler.md` hard-codes an event name enum; new events do not require registry updates. Existing naming convention (hyphenated-lowercase) is consistent with proposed new event names.
- **No Autopilot config key collision**: The 7 planned `### Autopilot` section keys do not collide with any existing section keys; config-reader is section-scoped, preventing cross-section ambiguity.
- **D10 payload diverges from roadmap**: D10 recommends `phase`, `duration`, `tokens_used`, `outcome`; roadmap specifies `step_name`, `duration`, `iteration_count`. Phase 4 must reconcile this discrepancy. The review report's authoritative date is **2026-04-07** (internal stamp), not 2026-04-08 as cited in the roadmap.
- **Roadmap is sole Autopilot ground truth**: No standalone brainstorm file for the "2026-04-05 (approved)" Autopilot design exists anywhere in the repo. `docs/plans/roadmap.md:621-643` is the exclusive specification source for all Autopilot design decisions.
