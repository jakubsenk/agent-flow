# Phase 1 Research Questions — Agent 1: Contract Archaeology & Public API Risk

## Angle

This agent guards the three public contract surfaces that v6.8.0 touches: the `state.json` schema (read by `/resume-ticket` and external tooling), the webhook payload contract (consumed by external monitoring systems after D10), and the `Automation Config` key space (consumed by every ceos-agents project on upgrade). The questions below are ranked by decision criticality and probe exact field names, schema versioning semantics, backward-read tolerance, payload shape alignment with the v6.7.2 webhook consolidation work, Autopilot config key naming, and existing override mechanisms that could silently interact with the new surfaces. Anything the roadmap has already answered is excluded.

---

## Section A: Contract & Schema Questions

**Q1.** When v6.8.0 adds `tokens_used`, `duration_ms`, `tool_uses`, `model`, `started_at`, and `completed_at` to existing stage sections in state.json, does the schema version bump from `"1.0"` to `"1.1"` suffice, or does the presence of new fields in the top-level `pipeline` accumulator (a wholly new section, not a new field on an existing section) warrant a `"2.0"` bump under any existing bump-semantics policy documented in `state/schema.md` or `core/state-manager.md`?
Why it matters: determines whether `/resume-ticket` and external tooling that key-checks `schema_version == "1.0"` will silently misread state files written by v6.8.0.

**Q2.** Does `core/state-manager.md` currently document explicit backward-read behavior for `schema_version` values it does not recognize — specifically, does it define "if `schema_version` field is absent or is `"1.0"` when `"1.1"` is the current writer version, treat all new optional fields as null" — or is that tolerance only implied by the atomic tmp+rename protocol?
Why it matters: if there is no explicit backward-read clause, the spec must add one to prevent `/resume-ticket` from crashing on pre-v6.8.0 state files that lack `pipeline.*` and per-stage usage fields.

**Q3.** The `core/block-handler.md` fires the event name `"issue-blocked"` (not `"ceos-agents-block"` as suggested in the Phase 0 analysis), while `core/post-publish-hook.md` fires `"pr-created"` — do the three new v6.8.0 events (`"pipeline-started"`, `"step-completed"`, `"pipeline-completed"`) follow the same hyphenated-lowercase naming convention, and is there any existing event name registry (in `CLAUDE.md` Notifications section or `core/post-publish-hook.md`) that would need to be updated with an authoritative enum?
Why it matters: event name format is the primary integration contract for external webhook consumers; inconsistent naming requires a client-side special-case per event.

**Q4.** For the `step-completed` webhook payload, the roadmap specifies `step_name`, `duration`, and `iteration_count` as richer payload fields — but the `pipeline.log` JSONL already records `phase`, `agent`, `duration_s`, and `iteration`/`verdict` on `fixer_iteration` events: do the new webhook payload field names need to match the `pipeline.log` field names exactly (e.g., `duration_s` vs `duration`, `phase` vs `step_name`) to maintain a coherent observability contract, or are the two surfaces intentionally independent?
Why it matters: divergent naming between `pipeline.log` and the `step-completed` webhook payload doubles the consumer integration surface and makes correlation harder.

**Q5.** The Autopilot `### Autopilot` config section is documented with 7 keys in the roadmap (`Max issues per run`, `Lock timeout`, `Log file`, `Bug limit`, `Feature limit`, `On error`, `Dry run`) — do any of these key names collide with keys already defined in other optional sections (`Error Handling`, `Pipeline Profiles`, `Metrics`) when `core/config-reader.md` parses them, and specifically, is there already an `On error` key in any existing section that would shadow or conflict?
Why it matters: config-reader parses sections by heading name and key name; a duplicate key in a different section can produce silent wrong-value reads if the parser is not section-scoped.

---

## Section B: Behavioral Semantics Questions

**Q6.** When the `fixer_reviewer` loop runs 3 out of a maximum 5 iterations, does the `step-completed` webhook event fire once (at the end of the full fixer↔reviewer loop when the reviewer emits `APPROVED`) or three times (once per iteration, with an `iteration_count` payload field incrementing each time), and does the same single-vs-per-iteration question apply to `test.attempts`?
Why it matters: webhook volume and event semantics are the primary design decision for `step-completed`; external monitoring dashboards must know whether to expect N events or 1 per stage.

**Q7.** When Autopilot runs with `Dry run: true` — does it still initialize `state.json` (writing `status: "running"`) and append to `pipeline.log`, or does it short-circuit before any filesystem side-effect, and does it still fire the `pipeline-started` webhook (so external monitors see the dry run) or suppress all webhooks?
Why it matters: the dry-run contract determines whether external monitoring systems treat dry runs as real pipeline events or invisible probes; state.json initialization under dry-run also affects `/status` and `/metrics`.

**Q8.** If a consuming project's `Automation Config` has `Feature Workflow` section absent entirely (bug-only project), what is Autopilot's exact behavior when it reads `Feature query: null` — does it silently run in bug-only mode (dispatch only `fix-ticket`), emit a `[WARN]` to the log but continue, or block with an error requiring `Feature limit: 0` to be set explicitly?
Why it matters: every bug-only project (the most common ceos-agents consumer profile) must upgrade to v6.8.0 without adding `Feature Workflow` section to their config.

**Q9.** The Autopilot lock file at `.ceos-agents/autopilot.lock` stores `timestamp + hostname` and is considered stale after 120 minutes — on Windows (the current dev machine per env context), is the rename-based atomic creation pattern from `core/state-manager.md` sufficient for lock-file exclusive creation, or does Windows require a different exclusivity mechanism (e.g., O_EXCL-style open) given that Claude Code runs as a bash process on win32?
Why it matters: a race condition in lock-file creation on Windows allows two concurrent Autopilot invocations to both proceed, potentially processing the same issue twice.

**Q10.** When the `pipeline.total_tokens` accumulator is written at pipeline end — is it written as a merge-update to the existing state.json (preserving all per-stage fields already in the file) or as a new top-level `pipeline` object written in a single atomic write that could overwrite a partially populated `pipeline` field from an intermediate write?
Why it matters: if the accumulator write is a whole-object replacement, any intermediate `pipeline.started_at` or partial token data written at pipeline start would be silently erased.

---

## Section C: Integration & Compatibility Questions

**Q11.** Does `/resume-ticket` currently read `schema_version` before attempting to access `triage.*` or `fixer_reviewer.*` fields, and if not, will it throw a parse/key-access error when encountering a v6.8.0 state.json that has a new top-level `pipeline` object it has never seen before?
Why it matters: backward-compatibility of `/resume-ticket` with v6.8.0-written state files is a hard requirement; any key-access failure in resume-ticket breaks the most critical recovery workflow.

**Q12.** The v6.7.2 webhook alignment consolidated `implement-feature` and `fix-bugs` webhooks to delegate to `core/post-publish-hook.md` — does `core/post-publish-hook.md` currently contain the complete `On events` enum as an exhaustive list that must be updated when adding `pipeline-started`, `step-completed`, `pipeline-completed`, or does it just fire conditionally on membership testing with no enum restriction (meaning new events can be added without touching the core contract)?
Why it matters: if `core/post-publish-hook.md` hard-codes an enum of valid event names, adding three new events without updating the core contract produces a silent-drop bug where new events never fire.

**Q13.** Do existing `Agent Overrides` files (`customization/*.md`) get injected into Autopilot's own execution context, and if Autopilot dispatches `fix-ticket` as a sub-skill rather than as a sub-agent, does `core/agent-override-injector.md` even apply to the dispatched skill or only to agent Task tool invocations?
Why it matters: if agent overrides unexpectedly apply to Autopilot's own skill execution, project-specific instructions for (e.g.) `reviewer` could bleed into the top-level Autopilot dispatcher and alter classification behavior.

---

## Section D: Source-of-Truth & Validation Questions

**Q14.** What is the exact usage-metadata field shape returned by the Claude Code Task tool today — specifically, is it `total_tokens` (a single combined field), `input_tokens + output_tokens` (two separate fields), or `usage.input_tokens + usage.output_tokens` (nested) — and is there a `tool_uses` count field at all, or must tool-use count be inferred from `pipeline.log` event counts?
Why it matters: the forge.json reference shows `tokens_estimated` (a single estimated field, not a measured field) — if the Task tool only provides estimates or separate input/output tokens, the state.json field must be named and typed accordingly; using `tokens_used` as a single integer field is wrong if the API returns split counts.

**Q15.** Is there a standalone external review document for the 2026-04-08 review that enumerated D10 (Observability Hooks) in `docs/plans/` — specifically a file like `docs/plans/external-review-2026-04-08.md` or similar — or is the roadmap `PLANNED — v6.8.0` section the sole ground truth for D10's exact scope and payload requirements?
Why it matters: if a standalone review document exists with additional D10 requirements (payload fields, event ordering guarantees, delivery semantics), those requirements must be incorporated into the spec; relying on the roadmap summary alone could produce an incomplete contract.

---

## Decision Dependency Map

| Question | Phase 4 / Phase 7 Decision Unlocked |
|----------|-------------------------------------|
| Q1 | Phase 4: `schema_version` value to write in v6.8.0 state files; whether `core/state-manager.md` needs a version-negotiation clause |
| Q2 | Phase 4: backward-read tolerance clause in `core/state-manager.md` spec; whether `/resume-ticket` needs a null-coalesce guard for new fields |
| Q3 | Phase 4: authoritative event name list in `core/post-publish-hook.md`; whether `CLAUDE.md` Notifications section needs an updated enum |
| Q4 | Phase 4: `step-completed` payload field names; whether `pipeline.log` event schema needs alignment changes |
| Q5 | Phase 4: `### Autopilot` section key names; whether `core/config-reader.md` needs section-scoped key disambiguation |
| Q6 | Phase 4: `step-completed` granularity spec (per-iteration vs per-stage); Phase 7: test scenario count for webhook event assertions |
| Q7 | Phase 4: `Dry run` behavioral spec including state.json initialization and webhook suppression contract |
| Q8 | Phase 4: Autopilot feature-query-absent behavior clause; impacts `skills/autopilot/SKILL.md` Step 0 guard |
| Q9 | Phase 4: lock-file creation mechanism spec; whether a Windows-specific atomic-create pattern is needed |
| Q10 | Phase 4: `pipeline.*` write strategy — single end-of-pipeline write vs. incremental updates; impacts `core/state-manager.md` usage-write pattern |
| Q11 | Phase 4: whether `skills/resume-ticket/SKILL.md` needs a schema-version guard; Phase 7: regression test for resume on v1.0 state file |
| Q12 | Phase 4: whether `core/post-publish-hook.md` needs an updated event-name enum or remains open-ended |
| Q13 | Phase 4: whether `skills/autopilot/SKILL.md` needs an explicit "skip agent-override injection" clause |
| Q14 | Phase 4: exact field name and type for `tokens_used` in state.json and per-stage objects; impacts forge parity claim |
| Q15 | Phase 4: completeness of D10 payload spec; if standalone document exists, its requirements supersede the roadmap summary |
