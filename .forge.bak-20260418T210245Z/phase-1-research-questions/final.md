# Phase 1 Research Questions — ceos-agents v6.8.0 (Synthesized)

## Framing

v6.8.0 introduces three interlocking features — Real-Time Cost Visibility (per-stage `tokens_used`, `duration_ms`, `tool_uses`, `model` fields in state.json plus a top-level `pipeline` accumulator), Observability Hooks (three new webhook events: `pipeline-started`, `step-completed`, `pipeline-completed`), and Autopilot (a headless dispatcher with a lock file, issue-classification loop, and 7 new Automation Config keys). Each feature touches a public contract surface: state.json schema, webhook payload shape, and the Automation Config key space. Before Phase 4 can produce a spec, eleven decision-critical questions must be answered by reading existing artifacts — not by interviewing the user or drafting proposals. The questions below are organized into four sections: (A) contract and schema questions that define what ceos-agents writes and promises externally, (B) behavioral semantics questions that define what happens at runtime in edge cases, (C) integration and compatibility questions that verify the upgrade path from v6.7.x, and (D) source-of-truth questions that resolve roadmap prose against actual artifacts.

---

## Section A: Contract & Schema Questions

**Q1.** What exact field name and shape does the Claude Code Task/Agent tool return for token usage metadata — is it `total_tokens` (a single integer), `input_tokens + output_tokens` (two separate integers that must be summed), `tokens_estimated` (a single estimated field), or a nested object — and is `duration_ms` a field the Task tool returns directly or must the skill measure wall-clock time around the Task call?

Why it matters: The roadmap's v6.8.0 spec uses `tokens_used` in state.json and references `total_tokens` from the Task tool result, but the forge.json artifacts (the reference implementation) store `tokens_estimated` — Agent 3 confirmed this discrepancy by inspecting `.forge.bak-20260417-170848/forge.json`. If the field name returned by the Task tool differs from both, every per-stage write instruction in all four pipeline skills will be wrong from day one. This is the single highest-priority question.

Exact files to inspect:
- `C:/gitea_ceos-agents/.forge.bak-20260417-170848/forge.json` (most recent run — confirmed `tokens_estimated`)
- `C:/gitea_ceos-agents/.forge.bak-20260416-065037/forge.json` (confirms pattern across runs)

**Q2.** When v6.8.0 adds `tokens_used`, `duration_ms`, `tool_uses`, `model`, `started_at`, and `completed_at` to existing per-stage sections and adds a wholly new top-level `pipeline` accumulator object, should `schema_version` advance from `"1.0"` to `"1.1"` or remain `"1.0"` — and what backward-read guarantee must `/resume-ticket` provide for state files written by v6.7.x that carry none of these fields?

Why it matters: `state/schema.md` currently declares `"Always \"1.0\" for this specification"` and documents the file shape as an invariant; adding additive fields changes the declared invariant. The schema version value determines whether `/resume-ticket` and external tooling that check `schema_version == "1.0"` silently misread v6.8.0 state files. The backward-read clause determines whether a consuming project can resume a v6.7.x in-flight run after upgrading.

Exact files to inspect:
- `C:/gitea_ceos-agents/state/schema.md` — schema_version declaration and Full Schema Example section
- `C:/gitea_ceos-agents/core/state-manager.md` — atomic write protocol and any version-negotiation clause

**Q3.** Does `state/schema.md`'s Full Schema Example already contain `started_at`/`completed_at` on per-stage objects, or does any existing stage section already carry a `model` field — making any of v6.8.0's planned additions a conflict rather than a clean addition?

Why it matters: If any of the six planned per-stage fields (`tokens_used`, `duration_ms`, `tool_uses`, `model`, `started_at`, `completed_at`) already exist in the schema, adding them again creates a schema conflict; if they are entirely absent, the spec describes clean additive writes with no migration logic needed.

Exact files to inspect:
- `C:/gitea_ceos-agents/state/schema.md` — Full Schema Example section and Top-Level Field Definitions table

**Q4.** For the three new webhook events (`pipeline-started`, `step-completed`, `pipeline-completed`), what exact JSON fields are mandatory in every payload, which fields are event-specific optionals, and do the new event names follow the same hyphenated-lowercase convention as existing events (`pr-created`, `issue-blocked`) — and is there an authoritative event-name registry in `core/post-publish-hook.md` or `core/block-handler.md` that must be updated, or is the existing contract open-ended (no enum restriction)?

Why it matters: Event name format and payload shape are the primary integration contract for external webhook consumers. If `core/post-publish-hook.md` hard-codes an enum of valid event names, adding three new events without updating that core contract produces a silent-drop bug. Divergent naming between `pipeline.log` field names (e.g., `duration_s`, `phase`) and webhook payload field names (e.g., `duration`, `step_name`) doubles the consumer integration surface.

Exact files to inspect:
- `C:/gitea_ceos-agents/core/post-publish-hook.md` — On events list and payload shape
- `C:/gitea_ceos-agents/core/block-handler.md` — event name `"issue-blocked"` and payload shape

**Q5.** Do any of the 7 planned Autopilot config key names (`Max issues per run`, `Lock timeout`, `Log file`, `Bug limit`, `Feature limit`, `On error`, `Dry run`) collide with keys already defined in other optional config sections (`Error Handling`, `Pipeline Profiles`, `Metrics`) when `core/config-reader.md` parses them — specifically, is there already an `On error` key or `Log file` key in any existing section?

Why it matters: Config-reader parses sections by heading name and key name; a duplicate key in a different section can produce silent wrong-value reads if the parser is not section-scoped. Automation Config keys are a public contract — any rename after v6.8.0 ships is a MAJOR version bump.

Exact files to inspect:
- `C:/gitea_ceos-agents/core/config-reader.md`
- `C:/gitea_ceos-agents/CLAUDE.md` — existing optional config sections (Error Handling, Pipeline Profiles, Metrics)

---

## Section B: Behavioral Semantics Questions

**Q6.** Does `step-completed` fire once per top-level pipeline stage (triage, code_analysis, fixer_reviewer aggregate, test, publish — at most ~7 events per run) or once per sub-step including every individual fixer↔reviewer iteration (up to ~17 events per run) — and when a stage is skipped via a Pipeline Profile, does a `step-skipped` event fire or is the event simply omitted?

Why it matters: This is the single highest-volume design decision for external consumers. "fixer (×3)" on the roadmap summary table could mean 1 `step-completed` event or 3 — at 10 issues/run × 5 iterations that is a 10× throughput difference. Note: `pipeline.log` already records a `fixer_iteration` event per loop iteration (confirmed in `state/schema.md` lines 389, 401); the spec can assign per-iteration resolution to `pipeline.log` (internal) and top-level-only granularity to `step-completed` (external), cleanly separating concerns.

**Q7.** When Autopilot runs and the `Feature Workflow` section is absent from Automation Config — the common case for bug-only projects — does it (a) silently run bug-only mode using `Bug query` exclusively, (b) log a `[WARN]` and continue with bugs only, or (c) Block the entire run with a config-validation error requiring explicit `Feature limit: 0` — and does this behavior change when `Feature limit` is set to a non-zero value in the Autopilot section despite `Feature Workflow` being absent?

Why it matters: Every bug-only consuming project (the most common ceos-agents profile) must be able to upgrade to v6.8.0 and adopt Autopilot without adding a `Feature Workflow` section. If the answer is (c), every existing project requires a config migration. The interaction with a non-zero `Feature limit` when no query exists is an additional edge case the spec must address explicitly.

**Q8.** When `Dry run: true` is set in the Autopilot config section, does the skill fully short-circuit after printing the classified issue list (no filesystem side effects — no state.json, no lock file, no pipeline.log appends, no webhooks), or does it only suppress issue-tracker writes and git operations (matching the `--dry-run` behavior in `fix-ticket` which still runs triage and code-analyst) — and does it fire or suppress the `pipeline-started` webhook?

Why it matters: If the lock file is created in dry-run mode, concurrent cron invocations will false-positive lock and abort. If webhooks fire during dry-run, external monitoring systems receive events for non-existent pipeline runs. The fix-ticket `--dry-run` partial model and the Autopilot full-short-circuit model are both valid choices but produce opposite integration behaviors; the spec must choose one explicitly.

**Q9.** When the `fixer_reviewer` stage accumulates usage across N iterations, does `fixer_reviewer.tokens_used` in state.json represent the cumulative sum (iteration 1 + 2 + ... + N, enabling the roadmap's "fixer (×3) | opus | 135,000" summary row) or only the last-iteration snapshot — and is there a per-iteration breakdown array (e.g., `fixer_reviewer.iterations[N].tokens_used`) or only the aggregate value?

Why it matters: A cumulative sum is required for the roadmap's summary table to be meaningful and for `/metrics` aggregation to be accurate. A snapshot would undercount cost and mislead the cost-visibility feature on its first ship. The spec must state the semantics explicitly so all four pipeline skills implement the accumulator consistently.

**Q10.** When a webhook call fails (non-2xx or timeout) for a new event — especially `pipeline-started` fired at pipeline init — does the failure block the pipeline start, trigger a retry, or is it purely advisory (log `[WARN]` and continue), matching the existing advisory pattern in `core/post-publish-hook.md`?

Why it matters: If the three new events deviate from the existing advisory contract, implementers may add retry logic that is architecturally inconsistent with the existing webhook pattern. The spec must make the failure-handling contract explicit rather than leaving it implicit.

---

## Section C: Integration & Compatibility Questions

**Q11.** Does `/resume-ticket` currently read `schema_version` before attempting to access per-stage fields (e.g., `fixer_reviewer.*`), and will it throw a parse or key-access error when it encounters a v6.8.0 state.json with a new top-level `pipeline` object and per-stage usage fields it has never seen — or does the atomic-write protocol imply sufficient tolerance that no explicit guard is needed?

Why it matters: Consuming projects that upgrade to v6.8.0 mid-run will have in-flight state.json files written by v6.7.x with no usage fields; if `/resume-ticket` uses `?.` optional-chain semantics (treat absent fields as null/0) the upgrade is seamless, but if it expects the new fields the pipeline will crash on resume. This is a hard backward-compatibility requirement.

Exact files to inspect:
- `C:/gitea_ceos-agents/skills/resume-ticket/SKILL.md` — Step that reads state.json fields
- `C:/gitea_ceos-agents/core/state-manager.md` — merge-update vs. whole-object-replacement write behavior

**Q12.** Does the new `/ceos-agents:autopilot` skill require `disable-model-invocation: true` in its frontmatter (like the 14 pipeline orchestration skills that are not user entry points), or does it omit this flag because it is a direct user-invokable dispatcher — and does `/metrics`' current "Token cost estimate" logic use hardcoded constants (`sonnet ~30k`, `opus ~50k`) or already reads state.json, requiring a dual-mode aggregation strategy for the v6.8.0 transition period?

Why it matters: The `disable-model-invocation` flag determines whether Autopilot appears in the Claude Code skill picker. The `/metrics` dual-mode question determines whether v6.8.0 state.json files are read for actual tokens while pre-v6.8.0 files fall back to heuristics — a transition behavior the spec must define because the two run vintages will coexist in the same repo.

Exact files to inspect:
- `C:/gitea_ceos-agents/skills/metrics/SKILL.md` — Step 6 ("Token cost estimate") and any heuristic constants
- `C:/gitea_ceos-agents/skills/analyze-bug/SKILL.md` or `C:/gitea_ceos-agents/skills/onboard/SKILL.md` — frontmatter pattern for user-entry skills (confirm `disable-model-invocation` usage)

---

## Section D: Source-of-Truth & Validation Questions

**Q13.** What exact text does the external review recommendation D10 contain — specifically: is the word "observability" used, what payload field names are explicitly recommended, and is the source document dated 2026-04-07 or 2026-04-08 (input.md says 2026-04-08 but Agent 3 confirmed the file is dated 2026-04-07)?

Why it matters: D10 is cited as the primary business justification for Observability Hooks in v6.8.0. If the spec uses different field names than D10 recommended, it deviates from the source that authorizes this feature. The date discrepancy between input.md and the review report must be resolved — the file date is authoritative.

Exact file to inspect:
- `C:/gitea_ceos-agents/docs/plans/readmine-project/ceos-agents-review-report.md` — Section 8.3, item D10 (confirmed by Agent 3 as the authoritative source)

**Q14.** Is the "forge brainstorm 2026-04-05 (approved)" Autopilot design present as a standalone file in `docs/plans/brainstorm/` or `docs/plans/`, or is the roadmap section (lines 621–643 of `docs/plans/roadmap.md`) the only artifact containing the approved design decisions for the 7 config key names, lock-file path, two-query classification rule, and CLI invocation pattern?

Why it matters: Agent 3 confirmed that no standalone brainstorm file was found. If the roadmap is the sole ground truth, any ambiguity in its prose cannot be resolved by a more detailed source — the spec must explicitly accept the roadmap as authoritative and resolve all ambiguities inline, rather than deferring to a brainstorm document.

Exact files to inspect:
- `C:/gitea_ceos-agents/docs/plans/brainstorm/` — directory listing for any file containing "autopilot" or dated 2026-04-05
- `C:/gitea_ceos-agents/docs/plans/roadmap.md` — lines 621–643 (Autopilot design section)

---

## Decision Dependency Block

| Question | Phase 4 / Phase 7 Decision Unlocked |
|----------|--------------------------------------|
| Q1 | BLOCKS all usage-capture implementation: exact field name and type for `tokens_used` in state.json and per-stage objects; whether forge parity claim holds; impacts all 4 pipeline skills |
| Q2 | `schema_version` value to write in v6.8.0 state files; backward-read tolerance clause in `core/state-manager.md`; whether `/resume-ticket` needs a null-coalesce guard |
| Q3 | Whether per-stage fields are net-new or partial additions; clean-add vs. migration-required in state/schema.md additions |
| Q4 | Authoritative event name list in `core/post-publish-hook.md`; `step-completed` payload field set (mandatory vs. optional); whether `CLAUDE.md` Notifications section needs an updated enum |
| Q5 | `### Autopilot` section key names locked into public contract; whether `core/config-reader.md` needs section-scoped key disambiguation |
| Q6 | `step-completed` granularity spec (per-iteration vs. per-stage); `step_name` enum in payload; Phase 7 test scenario count for webhook event assertions |
| Q7 | Autopilot feature-query-absent behavior clause; impacts `skills/autopilot/SKILL.md` Step 0 guard; every bug-only consumer's upgrade path |
| Q8 | Autopilot `Dry run` behavioral spec: full short-circuit vs. partial dry-run; state.json initialization and webhook suppression contract |
| Q9 | `fixer_reviewer.tokens_used` semantics (cumulative vs. snapshot); whether per-iteration breakdown array is in schema; summary table formula; `/metrics` aggregation correctness |
| Q10 | Webhook failure-handling contract for new events: advisory vs. blocking; consistency with existing post-publish-hook pattern |
| Q11 | Whether `skills/resume-ticket/SKILL.md` needs a schema-version guard; Phase 7 regression test for resume on v1.0 state file; merge-update vs. whole-object-replace write strategy |
| Q12 | Autopilot SKILL.md frontmatter (`disable-model-invocation` present or absent); `/metrics` dual-mode aggregation strategy for v6.8.0 transition period |
| Q13 | Exact payload field names for Observability Hooks; D10 date citation in spec; whether spec deviates from external review recommendation |
| Q14 | Whether roadmap is sole ground truth for Autopilot design; resolution of any ambiguities in 7 config key names and lock-file semantics |

---

## Synthesis Notes

### Per-Question Attribution

| Question | Primary Source | Enrichment |
|----------|---------------|------------|
| Q1 | Agent 1 (Q14) + Agent 3 (Q1, Q12) | Agent 3's artifact-inspection finding (`tokens_estimated` in forge.json) is authoritative and injected into Q1; file paths from Agent 3 |
| Q2 | Agent 1 (Q1) + Agent 3 (Q3) | Agent 2 (Q2) added schema_version write-timing angle (eager vs. lazy) — merged into Q2 framing |
| Q3 | Agent 3 (Q15) | Unique to Agent 3; no equivalent in Agent 1 or 2 |
| Q4 | Agent 1 (Q3, Q4, Q12) | Agent 2 (Q3) added mandatory-vs-optional field angle; Agent 3 (Q2) confirmed payload shape concern |
| Q5 | Agent 1 (Q5) | No equivalent in Agent 2 or 3; key-collision risk unique to Agent 1 |
| Q6 | Agent 1 (Q6) + Agent 2 (Q5) + Agent 3 (Q5) | All three agents raised this question; Agent 2 added the `step-skipped` angle; Agent 2 (Q13) provided the `pipeline.log` separation-of-concerns resolution noted in Q6's framing |
| Q7 | Agent 1 (Q8) + Agent 2 (Q6) + Agent 3 (Q6) | All three raised feature-query-absent; Agent 2 added `Feature limit: non-zero` edge case; merged into Q7 |
| Q8 | Agent 1 (Q7) + Agent 2 (Q4) + Agent 3 (Q7) | All three raised dry-run; Agent 2 provided the `fix-ticket --dry-run` partial-model comparison; merged into Q8 |
| Q9 | Agent 1 (Q10) + Agent 2 (Q1) + Agent 3 (Q8) | All three raised token accumulation; Agent 2 added per-iteration breakdown array angle; merged into Q9 |
| Q10 | Agent 1 (Q12 partial) + Agent 2 (Q8) | Agent 2's webhook-failure advisory pattern question was cleaner; Agent 1's enum-registry concern folded into Q4 |
| Q11 | Agent 1 (Q2, Q11) + Agent 2 (Q9) + Agent 3 (Q9) | All three raised resume-ticket compat; merged file paths from Agent 3 added; Agent 1's accumulator-write strategy folded in |
| Q12 | Agent 3 (Q11) + Agent 2 (Q10) | Agent 3's frontmatter angle and Agent 2's /metrics dual-mode angle combined (both are pre-impl checks for Autopilot and metrics) |
| Q13 | Agent 3 (Q14) | Unique to Agent 3; date discrepancy finding (2026-04-07 vs. 2026-04-08) is authoritative |
| Q14 | Agent 3 (Q13) | Unique to Agent 3; no-standalone-brainstorm finding confirmed |

### Scoring Table

| Agent | Coverage (0-5) | Specificity (0-5) | Decision-Criticality (0-5) | Non-Overlap (0-5) | Total |
|-------|---------------|-------------------|---------------------------|-------------------|-------|
| Agent 1 | 5 | 3 | 5 | 4 | 17 |
| Agent 2 | 4 | 3 | 4 | 3 | 14 |
| Agent 3 | 4 | 5 | 4 | 4 | 17 |

**Base agent selected:** Agent 1 (tied with Agent 3; selected for superior Decision Dependency Map structure and coverage breadth). Agent 3's concrete artifact-inspection findings are injected as authoritative overrides into Q1, Q13, Q14, and file-path annotations throughout.

**Questions after merge:** 14 (within the 10–15 hard bounds)

### Disagreement Analysis

No criterion std dev exceeded 1.5 — no formal Disagreement flag triggered. Minor tensions resolved:

1. **`tokens_estimated` vs. `total_tokens` vs. `tokens_used`**: Agent 1 (Q14) noted the forge.json discrepancy; Agent 3 (Q12) confirmed it by naming the exact artifact files. Resolution: Agent 3's finding is authoritative. Q1 uses Agent 3's concrete evidence and file paths.

2. **`step-completed` granularity**: Agent 1 (Q6) framed as per-iteration vs. per-stage; Agent 2 (Q5, Q13) proposed the separation-of-concerns resolution (pipeline.log = internal per-iteration; step-completed = external per-stage). Resolution: Agent 2's resolution is adopted as a framing note in Q6 without prejudging the Phase 4 decision.

3. **D10 date**: Agent 3 (Q14) found the review report is dated 2026-04-07 while input.md says 2026-04-08. Resolution: the file date (2026-04-07) is treated as authoritative per Agent 3's direct inspection.

4. **Standalone Autopilot brainstorm**: Agent 3 (Q13) confirmed no standalone file found. Resolution: roadmap lines 621–643 are designated sole ground truth pending Phase 2 confirmation.

### Questions Intentionally Excluded

- **Agent 1 Q9 (Windows lock-file atomicity)**: Windows-specific platform concern; the lock file semantics are covered in Q8 (dry-run) and the platform concern is an implementation detail, not a spec-level Phase 4 decision. Excluded to stay within 15-question cap.
- **Agent 1 Q13 (Agent Overrides + Autopilot)**: Covered adequately by Q12's Autopilot integration checks. The exact override injection path is a Phase 4 spec clause but lower priority than the 14 retained questions.
- **Agent 2 Q11 (Agent Overrides in headless dispatch)**: Same coverage as above — merged intent absorbed by Q12.
