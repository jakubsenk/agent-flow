# Phase 2 Research Answers (Agent 2: Behavioral Semantics)

## Framing

This document answers Section B questions (Q6–Q10) from the synthesized Phase 1 question set. All claims are cited to exact file paths and line numbers. Questions outside Section B are noted as out of scope. Evidence priority followed: roadmap.md v6.8.0 section (lines 621–716) first, then existing pipeline skills, then core contracts. Where the roadmap is silent and no existing skill sets a precedent, the answer is marked OPEN for Phase 3 brainstorm.

---

## Section A Questions

**Q1–Q5:** Out of scope for this agent (Section A: Contract & Schema Questions — assigned to Agent 1).

---

## Section B: Behavioral Semantics Questions

### Q6: Does `step-completed` fire once per top-level pipeline stage or once per sub-step including every individual fixer↔reviewer iteration — and when a stage is skipped via a Pipeline Profile, does a `step-skipped` event fire or is the event simply omitted?

**A:** The roadmap describes `step-completed` as one of three new webhook events for "Observability Hooks," but gives no explicit statement on per-stage vs. per-iteration granularity for the webhook. However, the existing `pipeline.log` event schema provides a strong structural precedent: `pipeline.log` already records a `fixer_iteration` event per loop iteration (internal, per-iteration resolution), while top-level stage transitions are captured by `phase_start`/`phase_complete` events (external-facing). The roadmap (line 648) describes these new webhooks as providing "richer payload (step_name, duration, iteration_count)" and positions them as the external real-time signal to complement the internal `pipeline.log`. The phrase "step_name" in the roadmap payload description strongly implies that `step-completed` maps to a named pipeline stage (triage, code_analysis, fixer_reviewer, test, publisher — ~7 events per run), not to individual iterations. The `iteration_count` field in the payload (roadmap line 648) is the per-stage aggregate, not a per-iteration event.

For skipped stages: `pipeline.log` already has a `phase_skip` event type (`state/schema.md`, line 402: `"phase_skip"` with fields `phase`, `reason`). The roadmap does not name a `step-skipped` webhook event. The existing advisory pattern for skipped stages is internal log-only. Whether a `step-skipped` webhook fires is OPEN — the roadmap is silent on this edge case.

**Citations:**
- `docs/plans/roadmap.md:648` — `step-completed` payload includes `step_name, duration, iteration_count`
- `state/schema.md:389,401` — `fixer_iteration` event per loop iteration in pipeline.log (internal per-iteration resolution)
- `state/schema.md:386,402` — `phase_complete` and `phase_skip` events in pipeline.log
- `docs/plans/roadmap.md:677` — "For fixer↔reviewer loop: accumulate across iterations (fix.iterations: 3, fix.tokens_used: 135000)" — confirms per-stage aggregate intent

**Confidence:** MEDIUM — top-level granularity is strongly implied by `iteration_count` as a field (not a multiplier on events), and by the pipeline.log separation-of-concerns pattern, but no roadmap sentence explicitly states "one event per stage, not per iteration."

**Follow-up:** Phase 3 should explicitly confirm: "step-completed fires once per top-level named stage, not per fixer-reviewer iteration." Also confirm whether `step-skipped` is an event type or is simply omitted.

---

### Q7: When Autopilot runs and the `Feature Workflow` section is absent from Automation Config — the common case for bug-only projects — does it (a) silently run bug-only mode using `Bug query` exclusively, (b) log a `[WARN]` and continue with bugs only, or (c) Block the entire run with a config-validation error requiring explicit `Feature limit: 0`?

**A:** The roadmap (line 634) defines the Autopilot config defaults explicitly: `Feature limit (0)`. A default of `0` means features are disabled by default with no explicit config required. The roadmap (line 628) describes Autopilot as a "thin dispatcher that reads Bug query + Feature query, classifies issues, dispatches fix-ticket or implement-feature per issue" — it reads both queries but uses Feature query only if it is configured. The roadmap (line 634) also states `Bug limit (0)` and `Feature limit (0)` as config keys, both defaulting to `0` (unlimited). This default-zero pattern combined with the two-query classification design (line 633: "Two-query classification: Bug query first, then Feature query, bug takes priority on overlap") implies that if `Feature Workflow` is absent, Autopilot simply skips the Feature query step and processes bugs only — option (a) or (b).

The existing `fix-bugs` skill (line 37, `skills/fix-bugs/SKILL.md`) reads `Notifications`, `Feature Workflow` etc. as optional sections with no block on absence. The `metrics` skill (line 37, `skills/metrics/SKILL.md`) reads `Feature Workflow → Feature query` with "Optionally:" prefix — absence causes the query to be skipped, not a block. This pattern provides the strongest existing precedent: absent optional sections are skipped, not blocking.

Whether the behavior is silent (a) or warns (b) when `Feature Workflow` is absent is OPEN — the roadmap does not specify. The interaction with a non-zero `Feature limit` when `Feature Workflow` is absent (e.g., `Feature limit: 5` but no query) is also OPEN and must be explicitly addressed in the spec (most likely: warn that no Feature query is configured, default to bug-only mode).

**Citations:**
- `docs/plans/roadmap.md:634` — Autopilot config defaults: `Feature limit (0)`, `Bug limit (0)`, `On error (skip)`
- `docs/plans/roadmap.md:628` — "reads Bug query + Feature query, classifies issues, dispatches fix-ticket or implement-feature per issue"
- `docs/plans/roadmap.md:633` — "Two-query classification: Bug query first, then Feature query, bug takes priority on overlap"
- `skills/metrics/SKILL.md:37` — `Feature Workflow → Feature query` read as optional ("Optionally:"); absence skips the query without error
- `skills/fix-bugs/SKILL.md:1–100` — Feature Workflow section not read in fix-bugs; no block on absence of feature config

**Confidence:** MEDIUM — the default-zero pattern and optional-section precedent make option (c) very unlikely; (a) vs. (b) is OPEN.

**Follow-up:** Phase 3 must decide: (a) silent vs. (b) [WARN] for absent Feature Workflow. Must also define behavior when `Feature limit` is non-zero but `Feature Workflow` is absent.

---

### Q8: When `Dry run: true` is set in the Autopilot config section, does the skill fully short-circuit after printing the classified issue list (no filesystem side effects — no state.json, no lock file, no pipeline.log appends, no webhooks), or does it only suppress issue-tracker writes and git operations?

**A:** The roadmap (line 634) lists `Dry run (false)` as one of 7 Autopilot config keys with a default of `false`, but provides no behavioral description of what dry-run mode suppresses. This is the only mention of `Dry run` in the roadmap's Autopilot section.

The existing `fix-ticket --dry-run` provides the closest precedent. In `fix-ticket`, dry-run runs only steps 1 (without issue tracker changes), 3 (triage), and 4 (code-analyst), then generates a report — it does NOT suppress state.json writes (triage and code_analysis state updates still occur per `fix-ticket/SKILL.md:149, 162`), but it suppresses git operations and issue tracker writes. Pipeline.log appends happen as a side-effect of state.json writes (per `core/state-manager.md:28`). The `fix-ticket` dry-run explicitly calls triage-analyst and code-analyst agents.

For Autopilot's dry-run, the purpose is classification preview ("print the classified issue list") before dispatching any sub-skills. If it followed the `fix-ticket` partial model, it would call triage-analyst on each issue and produce a classification report — with state.json side effects. If it follows a full short-circuit model, no agents are dispatched and no filesystem state is written. The lock file question is particularly important: if the lock file is created in dry-run mode, concurrent cron invocations will false-positive lock and abort.

This behavioral question is OPEN — the roadmap states the key exists with default `false` but does not define what it suppresses. The spec must choose one model explicitly.

**Citations:**
- `docs/plans/roadmap.md:634` — `Dry run (false)` listed in 7 Autopilot config keys; no behavioral description given
- `skills/fix-ticket/SKILL.md:110–111` — fix-ticket dry-run: "run only steps 1 (without issue tracker changes), 3, and 4, then generate a report. No side effects."
- `skills/fix-ticket/SKILL.md:121` — "In dry-run: skip this step." (issue tracker write skipped)
- `skills/fix-ticket/SKILL.md:149,162` — state.json writes still occur in dry-run (triage and code_analysis sections updated)
- `core/state-manager.md:28` — pipeline.log append happens on every state.json write (step 5 of Write Process)

**Confidence:** LOW — roadmap names the key but is silent on semantics; `fix-ticket` partial model is the closest precedent but may not be appropriate for a headless dispatcher.

**Follow-up:** Phase 3 must define Autopilot dry-run semantics: full short-circuit (classification list only, no lock, no state.json, no webhooks) vs. partial (dispatch triage per issue, write state.json, suppress downstream agents and git). The lock-file behavior under dry-run is especially critical for cron-based deployments.

---

### Q9: When the `fixer_reviewer` stage accumulates usage across N iterations, does `fixer_reviewer.tokens_used` in state.json represent the cumulative sum or only the last-iteration snapshot — and is there a per-iteration breakdown array?

**A:** The roadmap is explicit on this point. Line 677: "For fixer↔reviewer loop: accumulate across iterations (fix.iterations: 3, fix.tokens_used: 135000)". This unambiguously defines `tokens_used` as a **cumulative sum** across all iterations. The summary table (roadmap line 685) shows `fixer (×3) | opus | 135,000` as a single aggregated row, confirming the intent is one cumulative value per stage for the summary report.

The roadmap does not define a per-iteration breakdown array (e.g., `fixer_reviewer.iterations[N].tokens_used`). The existing `fixer_reviewer` schema section (`state/schema.md:85–91`) stores only `iterations` (integer counter) and `last_verdict` — no per-iteration array. The roadmap's mechanism description (lines 668–691) describes writing per-stage usage fields and a top-level `pipeline` accumulator, but does not add a per-iteration breakdown array to `fixer_reviewer`. The `pipeline.log` file already records each `fixer_iteration` event (with timestamp and verdict, `state/schema.md:389,401`) and can provide per-iteration timing from log analysis, but token data is not currently in `pipeline.log` events.

The `fix-ticket` skill (line 302) increments `fixer_reviewer.iterations` after each iteration but writes no per-iteration token field — consistent with a cumulative aggregate, not a breakdown array.

**Citations:**
- `docs/plans/roadmap.md:677` — "For fixer↔reviewer loop: accumulate across iterations (fix.iterations: 3, fix.tokens_used: 135000)"
- `docs/plans/roadmap.md:685` — Summary table: `fixer (×3) | opus | 135,000` (single cumulative row)
- `state/schema.md:85–91` — Current `fixer_reviewer` section: `iterations` (integer), no per-iteration array
- `state/schema.md:389,401` — `fixer_iteration` event in pipeline.log (timestamp + verdict only, no tokens)
- `skills/fix-ticket/SKILL.md:302` — "increment fixer_reviewer.iterations" after each iteration; no per-iteration token write

**Confidence:** HIGH — roadmap is explicit on cumulative semantics; absence of per-iteration array in both schema and roadmap mechanism description is definitive.

---

### Q10: When a webhook call fails for a new event — especially `pipeline-started` fired at pipeline init — does the failure block the pipeline start, trigger a retry, or is it purely advisory?

**A:** The existing webhook failure-handling pattern is fully documented and unambiguous. `core/post-publish-hook.md:30–33` states: "Webhook failure (non-2xx or timeout) → log warning '[WARN] Webhook delivery failed: {error}', continue." followed by "All post-publish hooks are advisory only. Failures here never block the pipeline." The `curl` invocation uses `--max-time 5 --retry 0` — explicitly zero retries (`core/post-publish-hook.md:17–22`). The `core/block-handler.md:54` defines the same pattern: "Webhook failure → log warning, continue (do NOT retry)."

The roadmap (line 645–651) describes the three new Observability Hook events as an expansion of the existing webhook system ("Expand webhook system beyond current 2 events"), explicitly placing them in the same `Notifications` config section (`Files: core/post-publish-hook.md, core/block-handler.md, CLAUDE.md (Notifications config), pipeline skills`). This grouping with existing advisory events strongly implies the new events inherit the same advisory failure-handling contract.

There is no indication in the roadmap that the new events deviate from the advisory pattern. If `pipeline-started` blocked on webhook failure, Autopilot cron jobs would fail at the first webhook delivery failure — clearly not the intent for a headless dispatcher.

**Citations:**
- `core/post-publish-hook.md:17–22` — `curl --max-time 5 --retry 0` (zero retries, 5-second timeout)
- `core/post-publish-hook.md:30–33` — "Webhook failure → log warning, continue. All post-publish hooks are advisory only."
- `core/block-handler.md:54` — "Webhook failure → log warning, continue (do NOT retry)."
- `docs/plans/roadmap.md:648–651` — New events grouped with existing webhook infrastructure: "Files: core/post-publish-hook.md, core/block-handler.md, CLAUDE.md (Notifications config)"
- `docs/plans/roadmap.md:645` — "Expand webhook system beyond current 2 events" — expansion, not replacement

**Confidence:** HIGH — two existing core contracts (post-publish-hook.md and block-handler.md) both define advisory-only webhook failure semantics with zero retries; roadmap groups new events with the same infrastructure.

---

## Section C Questions

**Q11–Q12:** Out of scope for this agent (Section C: Integration & Compatibility — assigned to Agent 3).

## Section D Questions

**Q13–Q14:** Out of scope for this agent (Section D: Source-of-Truth & Validation — assigned to Agent 3).

---

## Key Findings

- **Q6 (step-completed granularity):** MEDIUM confidence that events fire per top-level stage (not per fixer iteration), inferred from `iteration_count` as a payload field and pipeline.log's existing `fixer_iteration` event separation-of-concerns pattern. Whether `step-skipped` events exist is OPEN.
- **Q7 (missing Feature Workflow):** MEDIUM confidence that Autopilot runs bug-only mode without blocking when `Feature Workflow` is absent — consistent with all existing optional-section patterns. Silent vs. [WARN] behavior and the non-zero `Feature limit` edge case are both OPEN.
- **Q8 (Dry run semantics):** LOW confidence — roadmap names the key but defines no behavior. `fix-ticket --dry-run` partial model (still writes state.json, skips git/tracker) is the closest precedent but may not apply to a headless dispatcher. Lock-file behavior under dry-run is critical for cron safety and is explicitly OPEN.
- **Q9 (cumulative vs. snapshot tokens_used):** HIGH confidence — roadmap line 677 is explicit: cumulative sum. No per-iteration breakdown array exists or is planned in roadmap; pipeline.log provides per-iteration timing but not tokens.
- **Q10 (webhook failure handling):** HIGH confidence — existing contracts in `core/post-publish-hook.md` and `core/block-handler.md` are unambiguous: advisory only, zero retries, `[WARN]` and continue. New events inherit this pattern per roadmap grouping.
- **forge.json field name confirmed:** `.forge.bak-20260417-170848/forge.json:9` stores `tokens_estimated` (not `total_tokens`); the roadmap's Real-Time Cost Visibility section (line 654) says "mechanism copied from forge" but maps this to `total_tokens` in its mechanism description (line 669) — this discrepancy is a Q1 concern (Section A), not Section B.
