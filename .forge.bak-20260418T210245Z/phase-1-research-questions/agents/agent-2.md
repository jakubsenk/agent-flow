# Phase 1 Research Questions — Agent 2 (Runtime Behavior & Edge Cases)

## Angle

This set of questions probes ceos-agents v6.8.0 through a runtime-execution lens — what actually happens at the moment the pipeline runs, in edge cases, under partial state, and on concurrent invocations. Gaps in behavioral semantics are the most likely source of silent failures in a headless, unattended dispatcher like Autopilot, and of subtle protocol drift in the new observability hooks and cost-tracking accumulator. Each question below targets a decision point whose correct answer cannot be derived by reading the roadmap alone — it requires cross-referencing live skill code, state schema, and pipeline contracts.

---

## Section A: Contract & Schema Questions

**Q1.** When the `fixer_reviewer` stage accumulates usage across iterations, does `fixer_reviewer.tokens_used` represent the running cumulative total (updated after each iteration) or only the final total written once at loop completion, and is there a per-iteration breakdown array (e.g., `fixer_reviewer.iterations[N].tokens_used`) or only the aggregate?

Why it matters: Spec-writer must decide whether per-iteration token data is stored in state.json (requiring a richer schema) or only the aggregate; the summary table in the roadmap shows a single aggregate row for "fixer (×3)", which suggests aggregate-only — but the spec must be explicit to avoid schema ambiguity.

**Q2.** Does `state.json`'s `schema_version` bump from `"1.0"` to `"1.1"` apply globally to the entire file on the first write of a v6.8.0 pipeline, or is the version field updated only when a usage field is actually written (i.e., after the first agent dispatch that captures tokens)?

Why it matters: If the version bump happens eagerly at pipeline init, v6.7.x `/resume-ticket` reading a half-run v6.8.0 state file will see `"1.1"` on a file with no usage fields yet — the major-version check in resume-ticket only warns on major version mismatch, but implementations need to know whether `schema_version: "1.1"` is a pre-condition or a post-condition of usage-field writes.

**Q3.** For the three new webhook events, does `step-completed` carry the same mandatory fields as `pr-created` (`event`, `issue_id`, `pr_url`, `timestamp`), and which additional fields are mandatory vs. optional — specifically, is `tokens_used` in the `step-completed` payload mandatory or omitted when cost-visibility is not yet implemented?

Why it matters: External consumers parsing `step-completed` need a stable field set from day 1; if `tokens_used` is optional in the payload but absent in v6.8.0, consumers must handle its absence — the spec must declare which fields are guaranteed present.

**Q4.** For Autopilot's `Dry run` config key (default: `false`), does activating it prevent ALL side effects — including state.json creation, lock file acquisition, pipeline.log writes, and webhook delivery — or does it only suppress issue-tracker writes and git operations (as `--dry-run` does in fix-ticket)?

Why it matters: The fix-ticket `--dry-run` mode still runs triage and code-analyst (read-only steps); if Autopilot `Dry run: true` maps to this same partial dry-run, webhook consumers and external monitoring would still receive `pipeline-started` events — which may be intentional (visibility) or a surprise (noise). The spec must declare the exact boundary.

---

## Section B: Behavioral Semantics Questions

**Q5.** Does the `step-completed` webhook event fire after every top-level named stage (triage, code_analysis, fixer_reviewer, test, publisher), after every internal retry within a stage (e.g., each of 5 fixer↔reviewer iterations), or after both — and when a stage is skipped via a pipeline profile, does a `step-skipped` event fire or is the event simply omitted?

Why it matters: This is the single highest-volume decision for external consumers: "fixer (×3)" could mean 1 `step-completed` event or 3 — at 10 issues/run × 5 iterations that is 10× throughput difference; skipped-stage behavior determines whether consumers can reconstruct a complete pipeline timeline from webhook events alone.

**Q6.** When Autopilot is invoked and the `### Autopilot` config section is present but `### Feature Workflow` is absent from Automation Config, does Autopilot (a) run bug-only mode silently using Bug query exclusively, (b) log a warning and continue with bugs only, or (c) block the entire run with a config-validation error — and does this behavior differ when `Feature limit` is set to a non-zero value in the Autopilot section?

Why it matters: A project that uses only bug tracking (no `Feature Workflow`) should be able to adopt Autopilot without touching its Automation Config; if the answer is (c), every existing project needs a config migration. The interaction with a non-zero `Feature limit` further tightens this decision.

**Q7.** When Autopilot acquires the lock file at `.ceos-agents/autopilot.lock` and a second concurrent Autopilot invocation finds the lock non-stale (within 120 min), does the second invocation exit with a non-zero code (hard stop), print a human-readable message and exit 0 (soft stop), or block-wait up to `Lock timeout` seconds before aborting — and is there a distinction between "lock present and fresh" vs. "lock present and stale" in the exit path?

Why it matters: In a CI schedule that fires every 30 min, two invocations will overlap if the first run exceeds 30 min; the behavior on lock contention determines whether CI marks the run as failed (non-zero exit) or silently skips it — both are valid but the spec must choose one.

**Q8.** When a webhook call fails (non-2xx or curl timeout at 5s) mid-pipeline — specifically for the new `pipeline-started` event fired at pipeline init — does the failure block the pipeline start, trigger a retry, or is it purely advisory (log `[WARN]` and continue) consistent with the existing `pr-created` pattern in `core/post-publish-hook.md`?

Why it matters: The existing post-publish-hook pattern is explicitly advisory (failures never block); if the three new events follow the same advisory contract, this must be stated in the spec as a deliberate choice so implementers don't add retry logic; any deviation from the existing pattern is a behavioral inconsistency that needs justification.

**Q9.** When `/resume-ticket` reads a state.json written by v6.7.x (schema_version `"1.0"`, no usage fields on any stage), how does it behave when the resumed pipeline's skill tries to write `fixer_reviewer.tokens_used` — does it merge the new field into the existing object, or does it re-initialize the entire stage object, potentially losing `fixer_reviewer.iterations` and `fixer_reviewer.last_verdict` already stored?

Why it matters: Resume correctness is critical — losing `iterations` count would reset the retry limit counter and allow an unbounded extra fixer cycle on a resumed run; the atomic-write merge semantics of `core/state-manager.md` must explicitly handle partial-schema state files.

---

## Section C: Integration & Compatibility Questions

**Q10.** Does `/metrics` Step 6 ("Token cost estimate") in `skills/metrics/SKILL.md` currently derive per-issue token estimates heuristically (stages × model constants) rather than reading actual usage from state.json, and when v6.8.0 adds real `tokens_used` fields to state.json, does `/metrics` switch to reading those fields where present and falling back to the heuristic for older runs — or does it always use the heuristic regardless?

Why it matters: The roadmap says `/metrics` "reads per-stage usage from state.json across completed issues" — but the current skill uses hardcoded constants (`sonnet ~30k`, `opus ~50k`); the spec must define the dual-mode aggregation path (real data for v6.8.0+ runs, estimate for older runs) because the transition period will have both in the same repo.

**Q11.** Do agent-override files in `customization/` (e.g., `customization/fixer.md`) interact with Autopilot-dispatched pipelines the same way they interact with manually-invoked `fix-ticket` — specifically, does Autopilot pass the Agent Overrides config key to each dispatched `fix-ticket` / `implement-feature` invocation, or does headless dispatch bypass the override injection path in `core/agent-override-injector.md`?

Why it matters: Projects that rely on `customization/reviewer.md` for security-specific review instructions expect those instructions to apply in both interactive and headless runs; if Autopilot bypasses the override path, the feature silently degrades in headless mode with no error.

---

## Section D: Source-of-Truth & Validation Questions

**Q12.** What exact field names does the Claude Code Task tool return in its usage metadata object after an agent dispatch — specifically, is the top-level token count exposed as `total_tokens` (a single field), `input_tokens` + `output_tokens` (two fields that must be summed), or some other shape — and is `duration_ms` returned by the Task tool itself or must the skill measure wall-clock time around the Task call?

Why it matters: The roadmap states "Agent/Task tool returns 3 usage fields on every dispatch: `total_tokens`, `duration_ms`, `tool_uses`" but this claim requires verification against actual forge.json artifacts at `C:/gitea_filip-superpowers/` — if the field is `input_tokens + output_tokens` rather than `total_tokens`, every usage-capture line in 4 pipeline skills will be wrong on first implementation.

**Q13.** Does the `pipeline.log` JSONL file defined in `state/schema.md` already include a `fixer_iteration` event type (confirmed in schema lines 389, 401) that fires per loop iteration, and if so, can the `step-completed` webhook event for the fixer_reviewer stage be derived from `pipeline.log` by the pipeline skill at loop completion rather than requiring per-iteration webhook calls — making `pipeline.log` the canonical internal record and webhook the external notification?

Why it matters: If `pipeline.log` already captures per-iteration data, the spec can define `step-completed` as a top-level-only webhook event (one per stage, fired at stage completion) while retaining full per-iteration resolution internally — this resolves Q5's granularity question by separation of concerns and avoids flooding external consumers with per-iteration events.

---

## Decision Dependency Block

```
Q1 → spec for fixer_reviewer usage schema (aggregate vs. per-iteration array)
Q2 → spec for schema_version write timing (eager vs. lazy bump)
Q3 → spec for step-completed payload field list (mandatory vs. optional fields)
Q4 → spec for Autopilot Dry run boundary (full short-circuit vs. partial dry-run)
Q5 → spec for step-completed event granularity + skip-stage behavior (depends on Q13)
Q6 → spec for Feature Workflow absence fallback in Autopilot
Q7 → spec for lock-contention exit behavior (hard vs. soft stop)
Q8 → spec for new webhook event failure handling (advisory or blocking)
Q9 → spec for resume-ticket backward-compat merge behavior on partial-schema state.json
Q10 → spec for /metrics dual-mode aggregation (real vs. heuristic per run vintage)
Q11 → spec for Autopilot→agent-override injection path
Q12 → BLOCKS all usage-capture implementation (field names must be verified before spec-writing)
Q13 → informs Q5 granularity decision; read state/schema.md pipeline.log event table + forge.json artifact
```
