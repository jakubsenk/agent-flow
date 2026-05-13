# Phase 2 Research Answers — ceos-agents v6.8.0 (Synthesized)

## Framing

All 14 research questions have authoritative answers drawn from direct artifact inspection by the three parallel agents. The contract and source-of-truth questions (Section A, D) are fully resolved at HIGH confidence: schema additions are clean net-new writes, the webhook event registry is open-ended, Autopilot config keys have no collision, and the roadmap is the sole ground truth for the approved Autopilot design. Three behavioral questions (Q6, Q7, Q8) remain OPEN at MEDIUM or LOW confidence because the roadmap is silent on their exact semantics — Phase 3 must choose a direction. The single most consequential finding across all agents is the `tokens_estimated` vs. `total_tokens` / `tokens_used` field-name triangle: forge.json artifacts use `tokens_estimated`, the roadmap mechanism prose uses `total_tokens` (capture) → `tokens_used` (store), and static inspection cannot resolve whether the Task tool itself returns `total_tokens`. This design decision gates all four pipeline skill implementations and must be settled in Phase 3.

---

## Answers

### Q1: Exact field name and shape returned by the Claude Code Task/Agent tool for token usage metadata, and whether `duration_ms` is returned by the tool or must be measured by the skill

**A:** Forge.json artifacts (two confirmed runs: `.forge.bak-20260417-170848/forge.json` and `.forge.bak-20260416-065037/forge.json`) store per-phase token usage as `"tokens_estimated": <integer>` — a single integer field, not a nested object, not `input_tokens + output_tokens`. The accumulator field is `"total_tokens_estimated"`. The roadmap v6.8.0 mechanism prose (line 656) states "Agent/Task tool returns 3 usage fields: `total_tokens`, `duration_ms`, `tool_uses`" and step 1 says "capture `total_tokens`, `duration_ms`, `tool_uses` from Task tool result." Forge.json also carries `"duration_ms": 370000` per phase, consistent with the roadmap claim that `duration_ms` is available from the tool result. Whether the Task tool returns `total_tokens` at runtime (and forge renames it to `tokens_estimated` when writing forge.json) or whether the Task tool itself returns `tokens_estimated` cannot be resolved from static artifacts alone — it requires live tool call inspection. This is a DESIGN DECISION for Phase 3.

**Citations:**
- `.forge.bak-20260417-170848/forge.json:9` — `"tokens_estimated": 91023` per phase-0
- `.forge.bak-20260416-065037/forge.json:9` — same pattern, `"tokens_estimated": 116452`
- `.forge.bak-20260416-065037/forge.json:44-46` — accumulator: `"total_tokens_estimated": 1341612`
- `docs/plans/roadmap.md:656` — "Agent/Task tool returns 3 usage fields: `total_tokens`, `duration_ms`, `tool_uses`"
- `docs/plans/roadmap.md:669` — mechanism step 1: "capture `total_tokens`, `duration_ms`, `tool_uses` from Task tool result"

**Confidence:** MEDIUM — stored field name in forge artifacts is confirmed as `tokens_estimated`; whether the Task tool API surface uses `total_tokens` before forge renames it is unverified by static inspection.

**Source Agent:** Agent 1 (primary); Agent 2 (corroborating forge.json confirmation)

**Follow-up:** Phase 3 must choose the canonical stored field name for state.json and explicitly resolve whether forge renames `total_tokens` → `tokens_estimated` or whether the Task tool itself returns `tokens_estimated`. This decision gates all four pipeline skill write instructions.

---

### Q2: Whether `schema_version` should advance from `"1.0"` to `"1.1"` and what backward-read guarantee `/resume-ticket` must provide for v6.7.x state files

**A:** `state/schema.md` line 148 declares `schema_version` as `"1.0"` with the note "Always `\"1.0\"` for this specification. Enables future schema evolution." The roadmap (line 714) explicitly classifies Real-Time Cost Visibility as "PATCH (informational output, no contract change)," implying the author intends schema_version to remain `"1.0"`. `core/state-manager.md` has no version-negotiation clause: the Read Process (lines 34–35) reads and returns parsed JSON with no version check; the Write Process uses merge-update (field_path dot-notation into the existing object), not whole-object replacement. For v6.7.x state files missing the new usage fields, any consumer reading `triage.tokens_used` will silently receive `null`/`undefined` — no runtime error. The resume process (lines 38–53 of state-manager.md) accesses only `status` fields for checkpoint detection, not usage fields. Schema stays `"1.0"`; `/resume-ticket` needs no guard; the additive write pattern provides implicit backward compatibility.

**Citations:**
- `state/schema.md:35` — Full Schema Example: `"schema_version": "1.0"`
- `state/schema.md:148` — "Always `\"1.0\"` for this specification. Enables future schema evolution."
- `core/state-manager.md:34-35` — Read Process: no version check
- `core/state-manager.md:38-53` — Resume Process: accesses only `status` fields
- `docs/plans/roadmap.md:714` — "Impact: PATCH (informational output, no contract change)"

**Confidence:** HIGH

**Source Agent:** Agent 1

**Follow-up:** Phase 4 spec should document that `schema_version` remains `"1.0"` and that absent usage fields silently return null/undefined — this is the intended backward compatibility mechanism.

---

### Q3: Whether `state/schema.md` already contains any of the six planned per-stage fields, making v6.8.0 additions conflicts rather than clean additions

**A:** Direct inspection of the Full Schema Example (lines 33–141) and Top-Level Field Definitions table (lines 144–250) confirms that **none** of the six planned per-stage fields (`tokens_used`, `duration_ms`, `tool_uses`, `model`, `started_at`, `completed_at`) exist in any current pipeline stage section. Existing stage objects carry only behavioral fields (status, severity, area, complexity, acceptance_criteria, etc.). The only `started_at`/`completed_at`-class timestamps are: top-level `started_at` (line 156) and `updated_at` (line 155) — no top-level `completed_at`. The `deployment` sub-object carries `started_at` and `verified_at` (lines 137–138, 261–262), but these are on the deployment sub-object, not standard pipeline stage objects. All six planned additions are clean net-new writes with no conflict and no migration logic required.

**Citations:**
- `state/schema.md:33-141` — Full Schema Example (no usage fields on any stage object)
- `state/schema.md:64-91` — triage and code_analysis objects (confirmed: no model, no timing, no token fields)
- `state/schema.md:85-91` — fixer_reviewer object: only status, iterations, max_iterations, last_verdict, ac_fulfillment
- `state/schema.md:155-156` — top-level started_at and updated_at only; no top-level completed_at
- `state/schema.md:137-138` — deployment.started_at and deployment.verified_at (deployment sub-object only)
- `docs/plans/roadmap.md:704-709` — confirms all six are net-new additions

**Confidence:** HIGH

**Source Agent:** Agent 1

**Follow-up:** None — clean addition confirmed. Phase 4 spec can proceed with additive field writes.

---

### Q4: Mandatory and optional fields for the three new webhook events, naming convention, and whether an authoritative event-name registry requires updating

**A:** Existing events are: `pr-created` (`core/post-publish-hook.md:17–23`, payload: `event`, `issue_id`, `pr_url`, `timestamp`) and `issue-blocked` (`core/block-handler.md:39–43`, payload: `event`, `issue_id`, `agent`, `reason`, `timestamp`). Both use hyphenated-lowercase naming. The proposed new event names (`pipeline-started`, `step-completed`, `pipeline-completed`) follow the same convention. Neither `core/post-publish-hook.md` nor `core/block-handler.md` contains a hard-coded enum of valid event names — both check whether the configured `On events` list *contains* a specific string. No enum registry update is required. The roadmap (line 648) specifies payload fields for the new events as: `step_name`, `duration`, `iteration_count`. However, D10's original recommendation specifies: `phase`, `duration`, `tokens_used`, `outcome`. This is a PAYLOAD DIVERGENCE that Phase 3 must resolve (see Critical Cross-Checks below). The roadmap does not distinguish mandatory vs. optional fields within the payload.

**Citations:**
- `core/post-publish-hook.md:3-23` — pr-created event: curl command, payload shape, advisory failure handling
- `core/post-publish-hook.md:30-33` — "All post-publish hooks are advisory only"
- `core/block-handler.md:39-43` — issue-blocked event: payload fields
- `core/block-handler.md:50-53` — webhook failure: "log warning, continue (do NOT retry)"
- `docs/plans/roadmap.md:648` — new events payload: `step_name`, `duration`, `iteration_count`
- `docs/plans/readmine-project/ceos-agents-review-report.md:203-204` — D10 payload: `phase`, `duration`, `tokens_used`, `outcome`

**Confidence:** HIGH for naming convention and open-ended registry. MEDIUM for payload field set (D10 vs. roadmap divergence unresolved).

**Source Agent:** Agent 1 (registry/naming); Agent 1 + Agent 3 (D10 divergence)

**Follow-up:** Phase 3 must choose the canonical payload field set, reconciling D10 (`phase`, `duration`, `tokens_used`, `outcome`) with roadmap (`step_name`, `duration`, `iteration_count`).

---

### Q5: Whether the 7 planned Autopilot config key names collide with keys in existing optional config sections

**A:** `core/config-reader.md` is section-scoped: it parses each `### {Section}` heading independently and maps keys to section-prefixed config properties. Existing optional section keys are: `Error Handling` → `On block`, `Max blocked per run`; `Pipeline Profiles` → `Profile`, `Skip stages`, `Extra stages`; `Metrics` → `Output`, `Period`. None of the 7 planned Autopilot keys (`Max issues per run`, `Lock timeout`, `Log file`, `Bug limit`, `Feature limit`, `On error`, `Dry run`) match any existing key in any section. Surface similarity between `On error` (Autopilot) and `On block` (Error Handling) — distinct strings, distinct concepts, section-scoped parsing prevents cross-section collision. No collision risk at any level.

**Citations:**
- `core/config-reader.md:30` — `### Error Handling`: keys `On block`, `Max blocked per run`
- `core/config-reader.md:35` — `### Metrics`: keys `Output`, `Period`
- `core/config-reader.md:33` — `### Pipeline Profiles`: keys `Profile`, `Skip stages`, `Extra stages`
- `core/config-reader.md:1-60` — parser is section-scoped (heading-delimited parse blocks)
- `docs/plans/roadmap.md:634` — 7 Autopilot key names confirmed

**Confidence:** HIGH — no collision found; section-scoped parsing confirmed.

**Source Agent:** Agent 1

**Follow-up:** None — key names are safe. Phase 4 can write the `### Autopilot` section definition directly.

---

### Q6: Whether `step-completed` fires per top-level pipeline stage or per fixer↔reviewer iteration, and whether a `step-skipped` event fires for skipped stages

**A:** The roadmap does not make an explicit statement on per-stage vs. per-iteration granularity. However, two strong structural signals imply per-stage: (1) the roadmap payload for `step-completed` includes `iteration_count` as a field (line 648) — if events fired per-iteration, `iteration_count` would be a monotonic counter redundant with the event sequence, not a stage-level summary; (2) `pipeline.log` already records `fixer_iteration` events per loop iteration (`state/schema.md:389,401`) providing internal per-iteration resolution, while top-level `phase_complete` events capture stage transitions — a clean separation of concerns. The roadmap (line 677) confirms the intent: "accumulate across iterations (fix.iterations: 3, fix.tokens_used: 135000)" — a single cumulative row per stage, not one row per iteration. For skipped stages: `pipeline.log` carries `phase_skip` events (`state/schema.md:402`), but the roadmap does not name a `step-skipped` webhook event; skipped stage handling for webhooks is OPEN.

**Citations:**
- `docs/plans/roadmap.md:648` — `step-completed` payload: `step_name, duration, iteration_count`
- `state/schema.md:389,401` — `fixer_iteration` per-iteration events in pipeline.log (internal)
- `state/schema.md:386,402` — `phase_complete` and `phase_skip` events in pipeline.log
- `docs/plans/roadmap.md:677` — "accumulate across iterations (fix.iterations: 3, fix.tokens_used: 135000)"

**Confidence:** MEDIUM — top-level granularity strongly implied but no roadmap sentence explicitly states "one event per stage, not per iteration."

**Source Agent:** Agent 2 (primary); Agent 1 (Q6 framing)

**Follow-up:** Phase 3 must explicitly confirm: "step-completed fires once per top-level named stage, not per fixer-reviewer iteration." Must also decide whether `step-skipped` is an event type or is simply omitted.

---

### Q7: When `Feature Workflow` is absent from Automation Config, whether Autopilot blocks, warns, or silently runs bug-only mode — and what happens with non-zero `Feature limit` when the section is absent

**A:** The roadmap (line 634) defines `Feature limit (0)` as a default — zero by default means features are disabled without explicit config. The roadmap (line 628) describes Autopilot as a dispatcher that "reads Bug query + Feature query" — uses Feature query only if configured. All existing skills treat absent optional sections as skip-not-block: `skills/metrics/SKILL.md:37` reads `Feature Workflow → Feature query` with "Optionally:" prefix (absence skips the query); `skills/fix-bugs/SKILL.md` reads no Feature Workflow section at all with no block. This precedent makes option (c) — blocking on absent Feature Workflow — very unlikely. Whether the behavior is silent (a) or emits `[WARN]` (b) is OPEN. The interaction with a non-zero `Feature limit` when `Feature Workflow` is absent (e.g., `Feature limit: 5` but no query defined) is also OPEN — most likely outcome is a warning that no Feature query is configured, defaulting to bug-only mode.

**Citations:**
- `docs/plans/roadmap.md:634` — Autopilot config defaults: `Feature limit (0)`, `Bug limit (0)`, `On error (skip)`
- `docs/plans/roadmap.md:628` — "reads Bug query + Feature query, classifies issues"
- `docs/plans/roadmap.md:633` — "Two-query classification: Bug query first, then Feature query, bug takes priority on overlap"
- `skills/metrics/SKILL.md:37` — Feature Workflow read as optional; absence skips query without error
- `skills/fix-bugs/SKILL.md:1-100` — Feature Workflow section not read; no block on absence

**Confidence:** MEDIUM — option (c) is very unlikely; (a) vs. (b) is OPEN; non-zero Feature limit edge case is OPEN.

**Source Agent:** Agent 2

**Follow-up:** Phase 3 must decide: (a) silent vs. (b) [WARN] for absent Feature Workflow. Must also define the non-zero-Feature-limit-but-no-query behavior.

---

### Q8: Dry run semantics for Autopilot — full short-circuit vs. partial (suppresses only git/tracker writes), and whether the lock file and webhooks are created

**A:** The roadmap (line 634) lists `Dry run (false)` as one of 7 Autopilot config keys with default `false`, but provides no behavioral description of what dry-run mode suppresses — this is the sole mention. The closest precedent is `fix-ticket --dry-run` (`skills/fix-ticket/SKILL.md:110–111`): "run only steps 1 (without issue tracker changes), 3, and 4, then generate a report. No side effects." However, `fix-ticket` dry-run still writes state.json for triage and code_analysis (lines 149, 162) and these writes trigger pipeline.log appends (`core/state-manager.md:28`). For Autopilot (a headless cron dispatcher), a full short-circuit model — no agents dispatched, no lock file created, no state.json written, no webhooks fired — is more appropriate because: (1) if the lock file is created in dry-run, concurrent cron invocations false-positive lock; (2) if webhooks fire in dry-run, monitoring systems receive events for non-existent pipeline runs. The spec must choose one model explicitly. This question is OPEN with LOW confidence.

**Citations:**
- `docs/plans/roadmap.md:634` — `Dry run (false)` listed in 7 Autopilot config keys; no behavioral description
- `skills/fix-ticket/SKILL.md:110-111` — fix-ticket dry-run: runs steps 1/3/4 only, generates report
- `skills/fix-ticket/SKILL.md:149,162` — state.json writes still occur in fix-ticket dry-run
- `core/state-manager.md:28` — pipeline.log append happens on every state.json write

**Confidence:** LOW — roadmap names the key but is silent on semantics; fix-ticket partial model is the closest precedent but may not be appropriate for a headless dispatcher.

**Source Agent:** Agent 2

**Follow-up:** Phase 3 must define Autopilot dry-run semantics: full short-circuit (classification list only, no lock, no state.json, no webhooks) is recommended for cron safety, but this is a design decision.

---

### Q9: Whether `fixer_reviewer.tokens_used` is cumulative across iterations or a last-iteration snapshot, and whether a per-iteration breakdown array is planned

**A:** The roadmap is explicit and unambiguous. Line 677: "For fixer↔reviewer loop: accumulate across iterations (fix.iterations: 3, fix.tokens_used: 135000)" — `tokens_used` is a **cumulative sum**. The summary table (line 685) shows `fixer (×3) | opus | 135,000` as a single aggregated row per stage. No per-iteration breakdown array is defined in the roadmap mechanism (lines 668–691) or in the current `fixer_reviewer` schema section (`state/schema.md:85–91`, which carries only `iterations` as an integer counter). `pipeline.log` records each `fixer_iteration` event with timestamp and verdict (`state/schema.md:389,401`) but carries no token data per iteration. `skills/fix-ticket/SKILL.md:302` increments `fixer_reviewer.iterations` after each iteration with no per-iteration token write — consistent with cumulative aggregate only.

**Citations:**
- `docs/plans/roadmap.md:677` — "accumulate across iterations (fix.iterations: 3, fix.tokens_used: 135000)"
- `docs/plans/roadmap.md:685` — summary table: single cumulative row `fixer (×3) | opus | 135,000`
- `state/schema.md:85-91` — current fixer_reviewer: only `iterations` integer, no per-iteration array
- `state/schema.md:389,401` — fixer_iteration in pipeline.log: timestamp + verdict, no tokens
- `skills/fix-ticket/SKILL.md:302` — increments fixer_reviewer.iterations; no per-iteration token write

**Confidence:** HIGH — roadmap is explicit on cumulative semantics; absence of per-iteration array is definitive.

**Source Agent:** Agent 2

**Follow-up:** None — spec can directly state: `fixer_reviewer.tokens_used` = cumulative sum across all iterations; no per-iteration breakdown array in state.json.

---

### Q10: Whether webhook failure for new events — especially `pipeline-started` — blocks the pipeline, triggers a retry, or is purely advisory

**A:** The existing webhook failure-handling pattern is fully documented and unambiguous across two core contracts. `core/post-publish-hook.md:17–22`: curl invocation uses `--max-time 5 --retry 0` (zero retries, 5-second timeout). `core/post-publish-hook.md:30–33`: "Webhook failure (non-2xx or timeout) → log warning '[WARN] Webhook delivery failed: {error}', continue. All post-publish hooks are advisory only. Failures here never block the pipeline." `core/block-handler.md:54`: "Webhook failure → log warning, continue (do NOT retry)." The roadmap (lines 645–651) positions the three new Observability Hook events as an expansion of the existing webhook system ("Expand webhook system beyond current 2 events") and groups them under the same files (`core/post-publish-hook.md`, `core/block-handler.md`). New events inherit the advisory-only contract. If `pipeline-started` blocked on webhook failure, Autopilot cron jobs would fail at the first webhook delivery failure.

**Citations:**
- `core/post-publish-hook.md:17-22` — `curl --max-time 5 --retry 0`
- `core/post-publish-hook.md:30-33` — "All post-publish hooks are advisory only. Failures here never block the pipeline."
- `core/block-handler.md:54` — "Webhook failure → log warning, continue (do NOT retry)."
- `docs/plans/roadmap.md:648-651` — new events grouped with existing webhook infrastructure files

**Confidence:** HIGH — two existing core contracts are unambiguous; roadmap groups new events with same infrastructure.

**Source Agent:** Agent 2

**Follow-up:** None — advisory-only pattern is settled. Phase 4 spec can state: new events inherit existing advisory failure-handling contract (zero retries, [WARN] and continue).

---

### Q11: Whether `/resume-ticket` reads `schema_version` before accessing per-stage fields, and whether it will error on v6.8.0 state files with new fields

**A:** `/resume-ticket` does NOT read `schema_version` before accessing fields. The skill reads exactly five field paths from state.json: `triage.acceptance_criteria`, `triage.complexity`, `fixer_reviewer.iterations`, `config.profile`, `config.flags` (step 3 of Checkpoint detection). There is a `plugin_version` check but it is "advisory only, never block" (line 19). The JSON read is a flat field-path accessor — no schema-strict deserialization; unknown fields in the JSON produce no error. `core/state-manager.md:21–27` uses merge-update writes (set at field_path into existing object), not whole-object replacement. Result: (1) v6.7.x state files read by v6.8.0 `/resume-ticket` — all five known fields are present, new fields simply absent, clean resume; (2) v6.8.0 state files read by v6.7.x `/resume-ticket` — extra fields ignored, clean resume; (3) mid-upgrade hybrid state files — additive write leaves old fields intact, five-field reader handles transparently. No code changes required for backward compatibility.

**Citations:**
- `skills/resume-ticket/SKILL.md:19` — plugin_version check: "advisory only, never block"; no schema_version check
- `skills/resume-ticket/SKILL.md:26-29` — exhaustive list: 5 fields only
- `core/state-manager.md:21-27` — Write Process: merge-update, not whole-object replacement
- `core/state-manager.md:34-35` — Read Process: "read and return parsed JSON"; no schema validation

**Confidence:** HIGH

**Source Agent:** Agent 3

**Follow-up:** Phase 4 spec should explicitly state `/resume-ticket` requires no update. Phase 5 TDD: regression test for resume on v6.7.x-style state.json under v6.8.0.

---

### Q12: Whether `/ceos-agents:autopilot` requires `disable-model-invocation: true` in its frontmatter, and whether `/metrics` uses hardcoded constants or reads state.json

**A:**

**Part 1 — `disable-model-invocation`:** 14 of 28 existing skills carry the flag — all are pipeline dispatchers (changelog, check-deploy, create-backlog, create-pr, fix-bugs, fix-ticket, implement-feature, migrate-config, publish, resume-ticket, scaffold, scaffold-add, sprint-plan, version-bump). Direct user entry points (analyze-bug, check-setup, dashboard, discuss, estimate, init, metrics, onboard, prioritize, scaffold-validate, status, template, version-check) do NOT carry it. Autopilot is genuinely ambiguous: it is a direct user entry point (user types `/ceos-agents:autopilot`) AND it dispatches fix-ticket and implement-feature (pipeline skills that carry the flag). The structural precedent does not unambiguously resolve to one value — this is a DESIGN DECISION for Phase 3.

**Part 2 — `/metrics` dual-mode:** `skills/metrics/SKILL.md` Step 6 uses **hardcoded model constants** exclusively: `sonnet ~30k`, `opus ~50k`, `haiku ~5k` per invocation (line 79). The skill reads NO state.json today — only issue tracker comments and git log (steps 1–5). For v6.8.0 transition: a dual-mode strategy is required — if state.json exists for a run with `pipeline.total_tokens` (or per-stage `tokens_used`), use actual values; otherwise fall back to heuristic constants.

**Citations:**
- `skills/metrics/SKILL.md:79` — hardcoded constants: `sonnet ~30k`, `opus ~50k`, `haiku ~5k`
- `skills/metrics/SKILL.md:35-68` — Steps 1–5: MCP issue tracker + git log only; no state.json read
- `skills/fix-bugs/SKILL.md` — confirmed carries `disable-model-invocation: true`
- `skills/metrics/SKILL.md` — confirmed ABSENT `disable-model-invocation`
- `skills/analyze-bug/SKILL.md:1-6` — ABSENT `disable-model-invocation` (same user-entry pattern as autopilot)

**Confidence:** HIGH for Part 2 (/metrics heuristic confirmed). LOW for Part 1 (autopilot frontmatter genuinely ambiguous).

**Source Agent:** Agent 3

**Follow-up:** Phase 3 must make an explicit decision on Autopilot's `disable-model-invocation` value (user-entry vs. dispatcher precedent). Phase 4 spec must define `/metrics` dual-mode read strategy.

---

### Q13: Exact text of D10 — whether "observability" is used, what payload fields are recommended, and the authoritative date

**A:** The review report (`docs/plans/readmine-project/ceos-agents-review-report.md`, lines 203–204) contains the following verbatim D10 text:

> **D10. Observability hooks**  
> Rozšířit Notifications systém o structured event payload (**phase, duration, tokens_used, outcome**) pro integrace s observability platformami (Grafana, DataDog). Umožnit real-time sledování pipeline, nejen post-hoc dashboard.

Key facts: (1) The word "observability" IS used — in the heading and in "observability platformami". (2) D10's explicit payload fields: `phase`, `duration`, `tokens_used`, `outcome` — exactly four fields. (3) `tool_uses` is NOT in D10 — it appears in the roadmap spec but is not mandated by the external review. (4) D10 does NOT specify event names — `pipeline-started`, `step-completed`, `pipeline-completed` originate in the roadmap, not D10. (5) Authoritative date: the file's own datestamp `*Zpráva zpracována: 2026-04-07*` (line 224) is authoritative. The "2026-04-08" in `input.md` is an off-by-one (likely when the review was read by the project owner, one day after authoring). The roadmap (line 648) payload (`step_name`, `duration`, `iteration_count`) differs from D10 — `tokens_used` and `outcome` from D10 are absent from the roadmap payload; `step_name` and `iteration_count` from the roadmap are not in D10.

**Citations:**
- `docs/plans/readmine-project/ceos-agents-review-report.md:203-204` — verbatim D10 text with payload field names
- `docs/plans/readmine-project/ceos-agents-review-report.md:224` — `*Zpráva zpracována: 2026-04-07*`
- `docs/plans/readmine-project/ceos-agents-review-report.md:195` — Section 8.3 heading
- `.forge/phase-0-meta/input.md:10` — "external review 2026-04-08, D10" (off-by-one)
- `docs/plans/roadmap.md:646` — roadmap cites "2026-04-08" (incorrect)
- `docs/plans/roadmap.md:648` — roadmap payload: `step_name`, `duration`, `iteration_count` (differs from D10)

**Confidence:** HIGH — direct file inspection by both Agent 1 and Agent 3 (identical findings).

**Source Agent:** Agent 1 + Agent 3 (identical findings — corroborated)

**Follow-up:** Phase 4 spec must cite D10 as "authored 2026-04-07." Phase 3 must reconcile D10 vs. roadmap payload divergence (see Critical Cross-Checks).

---

### Q14: Whether the "forge brainstorm 2026-04-05 (approved)" Autopilot design exists as a standalone file or whether the roadmap is the sole artifact

**A:** No standalone brainstorm file for the Autopilot feature exists. A glob of `docs/plans/brainstorm/` yields 10 files: `01-forgejo-mcp-fixes.md`, `02-onboard-mcp-tokens.md`, `03-onboard-directory-scope.md`, `04-scaffold-completeness.md`, `05-fix-bugs-token-discovery.md`, `06-session-resume-permissions.md`, `07-unified-improvements-summary.md`, `DECISIONS.md`, `EXECUTE-AND-REVIEW.md`, `IMPLEMENTATION-PLAN.md`. None is named "autopilot" or dated "2026-04-05". A grep for "autopilot"/"Autopilot"/"2026-04-05" across the brainstorm directory returns zero matches. The `docs/plans/` root (40+ files) contains no autopilot-named file. No forge.bak directory dated 2026-04-05 was found (available bak directories start at `20260415`). The roadmap at line 626 asserts "Source: forge brainstorm (2026-04-05, approved)" — but the output artifact of that brainstorm was never committed to `docs/plans/brainstorm/`. **`docs/plans/roadmap.md:621–643` is the sole authoritative artifact** containing the approved Autopilot design: 7 config key names, lock-file path (`.ceos-agents/autopilot.lock`), two-query classification rule, and CLI invocation pattern.

**Citations:**
- `docs/plans/roadmap.md:626` — "Source: forge brainstorm (2026-04-05, approved)"
- `docs/plans/roadmap.md:628-637` — full Autopilot design: lock file, 7 config keys, classification rule, CLI
- `docs/plans/brainstorm/` — 10 files, none named autopilot, none matching 2026-04-05
- `.forge/phase-0-meta/input.md:8` — "Zdroj: forge brainstorm 2026-04-05 (schválený)"
- Grep: zero matches for "autopilot" in brainstorm directory

**Confidence:** HIGH — confirmed by negative search result in two search strategies by both Agent 1 and Agent 3.

**Source Agent:** Agent 1 + Agent 3 (identical findings — corroborated)

**Follow-up:** Phase 4 spec authors must accept the roadmap as sole ground truth and resolve all Autopilot ambiguities inline — there is no backstop brainstorm document.

---

## Key Findings for Phase 3 Brainstorm

- **Field name triangle (BLOCKS Q1):** forge.json stores `tokens_estimated`; roadmap says capture `total_tokens` → store `tokens_used`. Phase 3 must pick ONE canonical stored field name for state.json and confirm (or disprove) what the Task tool actually returns. This decision gates all four pipeline skill write instructions.
- **D10 vs. roadmap payload divergence (BLOCKS Q4/Q13):** D10 mandates `phase, duration, tokens_used, outcome`; roadmap specifies `step_name, duration, iteration_count`. The canonical payload field set for `step-completed` and `pipeline-completed` must be resolved before Phase 4 can write the Observability Hooks spec.
- **Autopilot `disable-model-invocation` flag (DESIGN DECISION Q12):** Autopilot is both a user entry point (→ no flag, like analyze-bug) and a pipeline dispatcher (→ flag present, like fix-bugs). Phase 3 must pick one and justify.
- **`step-completed` granularity (CONFIRM Q6):** Per-stage (implied by `iteration_count` field and pipeline.log separation-of-concerns) vs. per-iteration. Phase 3 should make this explicit so Phase 4 can write a precise `step_name` enum.
- **Dry run semantics (OPEN Q8):** Full short-circuit (no lock, no state.json, no webhooks — classification list only) vs. partial model (like fix-ticket, still writes state.json). Lock-file behavior under dry-run is critical for cron safety.
- **Feature Workflow absence behavior (OPEN Q7):** Silent skip vs. `[WARN]` for absent Feature Workflow section; and behavior when `Feature limit` is non-zero but no Feature query is configured.
- **`/metrics` dual-mode aggregation (DESIGN DECISION Q12):** Spec must define the transition-period strategy: if state.json carries `pipeline.total_tokens`, use actual tokens; else fall back to `sonnet ~30k / opus ~50k / haiku ~5k` heuristics.
- **`schema_version` stays "1.0" (CONFIRMED Q2):** Roadmap classifies as PATCH; additive writes; state-manager has no version negotiation. Phase 4 spec can state this definitively.
- **All six per-stage fields are clean net-new additions (CONFIRMED Q3):** No conflict with existing schema. No migration logic required.
- **Roadmap is sole Autopilot ground truth (CONFIRMED Q14):** No brainstorm backstop — spec must resolve all roadmap prose ambiguities inline.

---

## Open Questions Escalated to Brainstorm

1. **What is the canonical state.json stored field name for token usage?** Options: `tokens_estimated` (forge parity), `tokens_used` (roadmap prose), `total_tokens` (roadmap mechanism step). Requires confirming Task tool API surface or making a design decision independent of it. — *Q1*

2. **What is the canonical `step-completed` webhook payload field set?** Options: D10 (`phase, duration, tokens_used, outcome`) vs. roadmap (`step_name, duration, iteration_count`) vs. merged superset. — *Q4/Q13*

3. **Does `/ceos-agents:autopilot` carry `disable-model-invocation: true`?** The pattern splits — user entry point says no, dispatcher of pipeline skills says yes. Phase 3 must choose with explicit reasoning. — *Q12*

4. **What exactly does Autopilot dry-run suppress?** Full short-circuit (classification list only, no lock file, no state.json, no webhooks) is recommended for cron safety. Phase 3 must decide. — *Q8*

5. **Does `step-completed` fire once per top-level stage (with `iteration_count` as a summary) or once per fixer-reviewer iteration?** Implied per-stage, but not explicitly stated. — *Q6*

6. **When `Feature Workflow` is absent: silent skip (a) or `[WARN]` and continue (b)?** And what happens when `Feature limit` is non-zero but no Feature query exists? — *Q7*

7. **Does `step-skipped` fire as a webhook event when a Pipeline Profile stage is skipped, or is the event simply omitted?** Roadmap is silent. — *Q6 edge case*

---

## Synthesis Notes

### Per-Agent Attribution

| Question | Primary Agent | Notes |
|----------|--------------|-------|
| Q1 | Agent 1 | Agent 2 corroborated forge.json `tokens_estimated` finding |
| Q2 | Agent 1 | No coverage by Agents 2/3; unique to Agent 1 |
| Q3 | Agent 1 | No coverage by Agents 2/3; unique to Agent 1 |
| Q4 | Agent 1 | Agent 3 confirmed D10 payload divergence; both used |
| Q5 | Agent 1 | Unique to Agent 1; no equivalent in Agents 2/3 |
| Q6 | Agent 2 | Agent 1 provided framing in Q1 research; Agent 2 evidence strongest |
| Q7 | Agent 2 | Best coverage of optional-section precedent pattern |
| Q8 | Agent 2 | Best coverage; fix-ticket precedent and cron safety analysis |
| Q9 | Agent 2 | Roadmap line 677 citation is definitive; no conflict across agents |
| Q10 | Agent 2 | Two core contract citations unambiguous; no conflict |
| Q11 | Agent 3 | Unique to Agent 3; 5-field accessor analysis and merge-write confirmation |
| Q12 | Agent 3 | Unique to Agent 3; both parts clearly answered |
| Q13 | Agent 1 + Agent 3 | Both inspected the same file; findings identical — HIGH confidence corroborated |
| Q14 | Agent 1 + Agent 3 | Both conducted negative search; findings identical — HIGH confidence corroborated |

### Scoring

| Agent | Coverage (0-5) | Specificity (0-5) | Decision-Criticality (0-5) | Non-Overlap (0-5) | Total |
|-------|---------------|-------------------|---------------------------|-------------------|-------|
| Agent 1 | 5 | 5 | 5 | 4 | 19 |
| Agent 2 | 4 | 4 | 4 | 3 | 15 |
| Agent 3 | 4 | 5 | 4 | 4 | 17 |

**Base agent:** Agent 1 (highest score; five HIGH-confidence answers with exact line citations). Agent 3 selected as co-primary for Q11, Q12, Q13, Q14 (unique coverage areas with HIGH confidence). Agent 2 selected as primary for Q6–Q10 (exclusive Section B coverage).

### Disagreement Resolution

No criterion std dev exceeded 1.5 — no Disagreement flag triggered. Minor tensions:

1. **Q13 date:** Both Agent 1 and Agent 3 independently inspected the same file and agree on `2026-04-07` as authoritative (file's own datestamp). No disagreement.

2. **Q14 brainstorm existence:** Both Agent 1 and Agent 3 conducted independent negative searches and agree no standalone file exists. No disagreement.

3. **Q12 autopilot flag:** Agent 3 correctly identified the ambiguity (neither "no flag" nor "flag present" is definitively correct from structural pattern alone). No false resolution — flagged as OPEN with LOW confidence. This is the correct synthesis output.

4. **Q1 field name:** Agent 1 (Section A focus) and Agent 2 (noted as cross-cutting) both cite the same forge.json artifacts with the same `tokens_estimated` finding. Agent 1's analysis of the roadmap vs. artifact divergence is more complete; selected as primary.

---

## Confidence Distribution

| Confidence | Questions | Count |
|-----------|-----------|-------|
| HIGH | Q2, Q3, Q5, Q9, Q10, Q11, Q13, Q14 | 8 |
| MEDIUM | Q1, Q4, Q6, Q7 | 4 |
| LOW | Q8, Q12 (Part 1 only) | 2 |

**Total:** HIGH: 8 — MEDIUM: 4 — LOW: 2
