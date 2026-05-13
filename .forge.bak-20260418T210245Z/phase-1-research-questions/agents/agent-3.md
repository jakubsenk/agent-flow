# Phase 1 Research Questions — Agent 3 (Source-of-Truth Verification & Evidence-Based Design)

## Angle

My lens is **Source-of-Truth Verification & Evidence-Based Design**: before any field name, event key, or schema version can be written into the spec, the authoritative artifact that defines or validates it must be read and cited. Two common failure modes motivate this angle. First, roadmap prose may summarize an artifact differently from the artifact itself (e.g., the forge.json field name `tokens_estimated` vs. the roadmap claim of `total_tokens`). Second, references to external documents ("forge brainstorm 2026-04-05", "external review 2026-04-08 D10") may or may not have standalone repo artifacts — the spec writer must know which before assuming ground truth. Every Section D question below names an exact file to inspect so research agents have zero ambiguity about where to look.

---

## Section A: Contract & Schema Questions

**Q1.** What exact field name does the Task/Agent tool return for the token count — `total_tokens`, `tokens_estimated`, `input_tokens + output_tokens`, or something else — and must ceos-agents state.json use the same name or translate it?

Why it matters: The roadmap's v6.8.0 spec uses `tokens_used` in state.json and references `total_tokens` from the Task tool result, but the forge.json artifacts (the reference implementation) store `tokens_estimated` — if the field name returned by the Task tool differs from both, every per-stage write in all four pipeline skills will be wrong from day one.

---

**Q2.** For the three new webhook events (`pipeline-started`, `step-completed`, `pipeline-completed`), what exact JSON fields are mandatory in every payload, and which fields are event-specific optionals — specifically, does `step-completed` need an `iteration_count` field and does `pipeline-completed` need a `total_tokens` field?

Why it matters: `core/post-publish-hook.md` and `core/block-handler.md` define the two existing event payloads as flat minimal objects (`event`, `issue_id`, `pr_url`/`agent`, `timestamp`); adding optional fields per event type creates a multi-shape payload contract that external consumers must handle, and the spec must lock down which fields are required vs. optional to avoid breaking consumers on the first ship.

---

**Q3.** Should the `schema_version` in state.json advance from `"1.0"` to `"1.1"` or remain `"1.0"`, and what is the minimum backward-compat read guarantee that `/resume-ticket` must provide for runs written by v6.7.x with no usage fields?

Why it matters: `state/schema.md` currently declares `"Always \"1.0\" for this specification"` — adding a per-stage usage object and a top-level `pipeline` accumulator is additive but changes the documented invariant; the spec must decide the bump rule and document what readers MUST tolerate when new fields are absent.

---

**Q4.** What exact key names and value types are the 7 Autopilot config keys, and are their defaults already locked (`Max issues per run: 1`, `Lock timeout: 120`, `Bug limit: 0`, `Feature limit: 0`, `On error: skip`, `Dry run: false`) or subject to change during spec?

Why it matters: Automation Config keys are a documented public contract (MAJOR bump if renamed); the roadmap lists these defaults but the Phase 4 spec must either confirm them as locked or document the open decision before implementation begins.

---

## Section B: Behavioral Semantics Questions

**Q5.** Does `step-completed` fire once per top-level pipeline stage (triage, code_analysis, fixer_reviewer aggregate, test, publish) or once per sub-step including every individual fixer↔reviewer iteration (iteration 1 of 5, iteration 2 of 5, ...)?

Why it matters: Top-level-only firing produces at most ~7 events per pipeline run; per-iteration firing produces up to ~7 + 5×2 = 17 events — the difference is significant for external consumer throughput design, state.json write frequency, and the meaning of `step_name` in the payload.

---

**Q6.** When Autopilot runs and the `Feature Workflow` section is absent from Automation Config, does it silently run bug-only mode, emit a logged warning and run bug-only mode, or Block with an explicit error before processing any issues?

Why it matters: The roadmap states "Bug query first, then Feature query, bug takes priority on overlap" but says nothing about the absent-Feature-query case; the behavior must be specified before implementation to avoid a silent misclassification where all feature issues are skipped with no feedback.

---

**Q7.** When `Dry run: true` is set in the Autopilot config section, does the skill still write the append-only log file, create/delete the lock file, and write state.json for each would-be dispatched issue — or does it fully short-circuit after printing the classified issue list?

Why it matters: Dry run semantics in headless mode determine whether operators can safely test Autopilot on a production config without side effects; if the lock file is created in dry run, concurrent cron invocations could false-positive lock and abort.

---

**Q8.** For the `fixer_reviewer` stage in state.json, when usage is accumulated across 5 iterations, does `tokens_used` represent the cumulative sum (iteration 1 + 2 + 3 + ...) or the last-iteration snapshot, and does this match the forge.json reference pattern?

Why it matters: A cumulative sum is required for the summary table's `fixer (×3) | opus | 135,000` row to be meaningful; a snapshot would undercount cost and mislead `/metrics` aggregation; the spec must state the semantics explicitly so all four pipeline skills implement it consistently.

---

## Section C: Integration & Compatibility Questions

**Q9.** Does `/resume-ticket` — which reads state.json to determine where to re-enter the pipeline — tolerate a v6.7.x state.json that has no `tokens_used`, `duration_ms`, `tool_uses`, or `model` fields on any stage, or does it require a schema migration step on resume?

Why it matters: Consuming projects that upgrade to v6.8.0 mid-run will have in-flight state.json files written by v6.7.x; if `/resume-ticket` reads usage fields with `?.` optional semantics (treat absence as `null`/`0`) the upgrade is seamless, but if it requires the new fields the pipeline will crash on resume.

---

**Q10.** Do the three new webhook events (`pipeline-started`, `step-completed`, `pipeline-completed`) conflict with or duplicate the existing `issue-blocked` event in `core/block-handler.md` — specifically, when a pipeline is blocked mid-run, does `pipeline-completed` still fire with `status: blocked`, or does only `issue-blocked` fire?

Why it matters: The two existing events (`pr-created`, `issue-blocked`) each fire from a specific core contract; the three new events span the entire pipeline lifecycle and could create duplicate notifications at block-time unless the spec defines exactly which event fires (and which does not) when the pipeline terminates via block rather than success.

---

**Q11.** Does the new `/ceos-agents:autopilot` skill require the `disable-model-invocation: true` frontmatter flag (like the 14 pipeline skills that are not direct entry points), or does it omit this flag because it is a user-invokable entry-point dispatcher?

Why it matters: The frontmatter flag determines whether Autopilot appears in the Claude Code skill picker as a user-invokable command; pipeline skills with `disable-model-invocation: true` are internal and do not appear; Autopilot should appear — but this must be confirmed against the pattern used by the other two user-entry skills (`/analyze-bug`, `/onboard`).

---

## Section D: Source-of-Truth & Validation Questions

**Q12.** What is the exact field name that the Claude Code Task/Agent tool returns for usage metadata in practice — is it `tokens_estimated`, `total_tokens`, `input_tokens + output_tokens`, or a nested object — as evidenced by the most recent completed forge.json artifacts?

Why it matters: The roadmap states the mechanism copies forge.json 1:1, but the actual forge.json artifacts in `C:/gitea_ceos-agents/.forge.bak-20260417-170848/forge.json` and `C:/gitea_ceos-agents/.forge.bak-20260416-065037/forge.json` store `tokens_estimated` per phase — not `total_tokens` as stated elsewhere in the roadmap prose — and both artifacts are estimations, not actuals; the spec writer must read these two files and confirm whether the ceos-agents state.json should mirror `tokens_estimated` (the forge field name) or use `tokens_used` (the roadmap's proposed state.json field name).

Exact files to inspect:
- `C:/gitea_ceos-agents/.forge.bak-20260417-170848/forge.json` (most recent run, v6.7.2 implementation)
- `C:/gitea_ceos-agents/.forge.bak-20260416-065037/forge.json` (v6.7.1 implementation, confirming pattern)

---

**Q13.** Is the "forge brainstorm 2026-04-05 (approved)" Autopilot design present as a standalone file in the repository under `docs/plans/brainstorm/` or `docs/plans/`, or is the roadmap section at lines 621–643 of `docs/plans/roadmap.md` the only artifact containing the approved design decisions?

Why it matters: If no standalone brainstorm file exists, the roadmap is the sole ground truth for 7 Autopilot config key names, the lock-file path (`.ceos-agents/autopilot.lock`), the two-query classification rule, the error boundary semantics, and the CLI invocation pattern; any ambiguity in roadmap prose cannot be resolved by reading a more detailed source document, and the spec must explicitly accept the roadmap as authoritative rather than treating it as a summary.

Exact files to inspect:
- `C:/gitea_ceos-agents/docs/plans/brainstorm/` directory listing (does any file name contain "autopilot" or reference 2026-04-05?)
- `C:/gitea_ceos-agents/docs/plans/roadmap.md` lines 621–643 (confirm this is the full design, not a summary)

---

**Q14.** What exact text does the external review recommendation D10 say — is the word "observability" used, what fields are explicitly named, and is the source document dated 2026-04-07 or 2026-04-08 — as found in the review report file?

Why it matters: The input.md says "external review 2026-04-08, D10" but the review report at `docs/plans/readmine-project/ceos-agents-review-report.md` is dated "2026-04-07"; D10 recommends "structured event payload (phase, duration, tokens_used, outcome)" — if the spec uses different field names than D10 recommended, it deviates from the source that justifies Observability Hooks as a v6.8.0 item, which may matter for traceability when the external reviewer evaluates the delivered implementation.

Exact file to inspect:
- `C:/gitea_ceos-agents/docs/plans/readmine-project/ceos-agents-review-report.md` — Section 8.3, item D10

---

**Q15.** What does the current `state/schema.md` Full Schema Example contain for per-stage timing — does each stage already have `started_at`/`completed_at` fields, or do only the top-level `started_at`/`updated_at` exist — and does any existing stage section already carry a `model` field?

Why it matters: The v6.8.0 plan adds `started_at`, `completed_at`, `tokens_used`, `duration_ms`, `tool_uses`, and `model` to each stage; if any of these fields already exist (e.g., `model` was added in a prior patch), adding them again creates a schema conflict; if they are entirely absent, the spec can describe clean additive writes without any migration logic.

Exact file to inspect:
- `C:/gitea_ceos-agents/state/schema.md` — Full Schema Example section and Top-Level Field Definitions table

---

## Decision Dependency Block

| Question | Blocks |
|----------|--------|
| Q1, Q12 | Per-stage usage write instructions in all 4 pipeline skills; field names in state/schema.md additions; `/metrics` aggregation logic |
| Q2, Q10 | Exact payload shape for `pipeline-started`, `step-completed`, `pipeline-completed`; how block events interact with pipeline-completion event |
| Q3, Q15 | `schema_version` bump value; whether per-stage fields are net-new or partial additions; backward-compat clause in state-manager |
| Q4, Q13 | Autopilot config section table in CLAUDE.md; 7 key names locked into public contract |
| Q5 | `step_name` enum in `step-completed` payload; write frequency in pipeline skills; webhook volume estimate for consumers |
| Q6, Q7 | Autopilot behavior spec: Feature-query-absent error handling; dry-run side-effect scope |
| Q8 | `fixer_reviewer.tokens_used` semantics; summary table formula; `/metrics` query correctness |
| Q9 | Whether `/resume-ticket` needs a compat-read guard or optional-chain instruction in Phase 4 spec |
| Q11 | Autopilot SKILL.md frontmatter — `disable-model-invocation` present or absent |
| Q14 | Exact field names for observability hook payloads; date discrepancy in source citation |
