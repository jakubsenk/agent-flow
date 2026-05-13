# Phase 2 Research Answers (Agent 3: Integration, Compatibility & Cross-Cutting Validation)

## Framing

This document answers Section C (Integration & Compatibility, Q11–Q12) and the two Section D source-of-truth questions (Q13–Q14) that were uniquely flagged for Agent 3's resolution. The research draws exclusively from file inspection of the live codebase and forge.bak artifacts — no speculation beyond what the cited files contain. Section A and Section B questions (Q1–Q10) are out of scope for this agent and are addressed by Agents 1 and 2.

---

## Out-of-Scope Declarations

- **Q1–Q10 (Sections A and B):** Out of scope for this agent; addressed by Agents 1 and 2.

---

## Section C: Integration & Compatibility Questions

### Q11: Does `/resume-ticket` currently read `schema_version` before attempting to access per-stage fields, and will it throw a parse or key-access error when it encounters a v6.8.0 state.json with a new top-level `pipeline` object and per-stage usage fields it has never seen — or does the atomic-write protocol imply sufficient tolerance that no explicit guard is needed?

**A:** `/resume-ticket` does NOT read `schema_version` before accessing per-stage fields. The skill only accesses four specific fields from state.json: `triage.acceptance_criteria`, `triage.complexity`, `fixer_reviewer.iterations`, `config.profile`, and `config.flags` (step 3 of Checkpoint detection). There is no version check on schema_version — only a version check on `plugin_version` (major version mismatch advisory, never blocking). The skill reads fields by exact key path; if a field is absent it simply returns nothing — there is no schema-strict deserialization that would throw on unknown keys.

For the reverse compatibility direction (v6.7.x state.json read by v6.8.0 `/resume-ticket`): since the skill only reads those five field paths and v6.7.x state files carry all five of them, the skill will resume cleanly — the new v6.8.0 fields (`tokens_used`, `duration_ms`, `tool_uses`, `model`, `started_at`, `completed_at`, top-level `pipeline`) are simply absent and will be ignored by any code path that only reads the five known fields.

For the forward compatibility direction (v6.8.0 state.json read by a v6.7.x installation): `/resume-ticket`'s JSON read is a flat field-path accessor, not schema-validated deserialization. Extra fields in the JSON object produce no error — they are ignored.

`core/state-manager.md` uses a merge-update write (field_path dot-notation set into the existing object) rather than whole-object replacement (lines 21–27 of state-manager.md). This means: writing new v6.8.0 fields to an existing v6.7.x state file is additive and does not remove old fields. Any skill that resumes the run after the first v6.8.0 write encounters a hybrid object — old fields intact, new fields appended — which the five-field reader in `/resume-ticket` handles transparently.

**Citations:**
- `skills/resume-ticket/SKILL.md:19` — plugin_version check is "advisory only, never block"; no schema_version check exists
- `skills/resume-ticket/SKILL.md:26–29` — exhaustive list of fields read from state.json (5 fields only: triage.acceptance_criteria, triage.complexity, fixer_reviewer.iterations, config.profile, config.flags)
- `core/state-manager.md:21–27` — Write Process: merge-update (set at field_path), not whole-object replacement
- `core/state-manager.md:34–35` — Read Process: "read and return parsed JSON"; no schema validation step

**Confidence:** HIGH

**Follow-up:** Phase 4 spec should explicitly state that `/resume-ticket` requires no update for v6.8.0 backward compatibility. A regression test (start a pipeline on v6.7.x-style state.json, resume with v6.8.0 build) is the appropriate Phase 5 TDD artifact.

---

### Q12: Does the new `/ceos-agents:autopilot` skill require `disable-model-invocation: true` in its frontmatter — and does `/metrics`' current "Token cost estimate" logic use hardcoded constants or already reads state.json, requiring a dual-mode aggregation strategy for the v6.8.0 transition period?

**A:**

**Part 1 — Autopilot `disable-model-invocation`:**

The flag determines whether a skill appears in the Claude Code skill picker as a directly invocable user entry point. Inspection of all 28 existing skills shows that the flag is present on exactly 14 skills: changelog, check-deploy, create-backlog, create-pr, fix-bugs, fix-ticket, implement-feature, migrate-config, publish, resume-ticket, scaffold, scaffold-add, sprint-plan, version-bump. These are all orchestration/pipeline skills invoked programmatically or are complex sub-flows not meant for direct user invocation.

The remaining 14 skills — analyze-bug, check-setup, dashboard, discuss, estimate, init, metrics, migrate-config (excluded above), onboard, prioritize, scaffold-validate, status, template, version-check — do NOT carry `disable-model-invocation: true` and are direct user entry points (visible in skill picker).

The new `/ceos-agents:autopilot` is described in the roadmap as a direct user-invokable command (`/ceos-agents:autopilot [--max N] [--dry-run]`) analogous to how a user directly invokes `/ceos-agents:fix-bugs`. However, `/fix-bugs` HAS `disable-model-invocation: true` because it dispatches other skills; Autopilot similarly dispatches fix-ticket and implement-feature. The pattern is ambiguous — but the distinguishing criterion appears to be: skills that dispatch OTHER pipeline skills carry the flag; skills that only dispatch agents do not. Since Autopilot dispatches fix-ticket and implement-feature (which are themselves `disable-model-invocation: true` skills), the analogy to fix-bugs holds. No authoritative ruling exists in the roadmap, but the structural precedent strongly implies Autopilot should NOT carry `disable-model-invocation: true` if it is the user entry point (user types `/ceos-agents:autopilot`). This is a LOW-confidence inference — the roadmap does not state this explicitly.

**Part 2 — `/metrics` dual-mode aggregation:**

`skills/metrics/SKILL.md` Step 6 ("Token cost estimate") uses **hardcoded model constants** exclusively: `sonnet ~30k`, `opus ~50k`, `haiku ~5k` per invocation (line 79). It does not read state.json at all — it reads only issue tracker comments and git log (steps 1–5). The skill has no code path that opens `.ceos-agents/*/state.json`. This means:

1. For v6.7.x runs (no usage fields in state.json): the current heuristic already applies.
2. For v6.8.0 runs (actual `tokens_used` in state.json per stage): the skill will still use heuristics unless it is updated to check state.json.
3. A dual-mode strategy is required for the transition period: if `state.json` exists for a run and contains `pipeline.total_tokens` (or per-stage `tokens_used`), use actual values; otherwise fall back to the existing heuristic constants.

The heuristic constants (`sonnet ~30k`, `opus ~50k`, `haiku ~5k`) are hardcoded at `skills/metrics/SKILL.md:79`. There is no flag, no toggle, and no state.json read path in the current metrics skill.

**Citations:**
- `skills/metrics/SKILL.md:79` — hardcoded token constants: `sonnet ~30k`, `opus ~50k`, `haiku ~5k`
- `skills/metrics/SKILL.md:35–68` — Steps 1–5 data sources: MCP issue tracker + git log only; no state.json read
- `skills/resume-ticket/SKILL.md:5` — `disable-model-invocation: true` present in resume-ticket (pipeline orchestration skill)
- `skills/fix-bugs/SKILL.md` — confirmed carries `disable-model-invocation: true` (pipeline dispatcher)
- `skills/metrics/SKILL.md` — confirmed ABSENT `disable-model-invocation` (user entry point)
- `skills/analyze-bug/SKILL.md:1–6` — confirmed ABSENT `disable-model-invocation` (user entry point, same pattern as autopilot)
- bash output listing all 14 skills with `disable-model-invocation: true`

**Confidence:** HIGH for Part 2 (/metrics heuristic). LOW for Part 1 (autopilot frontmatter) — the flag usage pattern is consistent across 28 skills but the Autopilot case is genuinely ambiguous between "user invokes it directly" (→ no flag) and "it dispatches other pipeline skills" (→ flag present by fix-bugs precedent).

**Follow-up:** Phase 4 spec must make an explicit decision on Autopilot's `disable-model-invocation` value. For `/metrics`, the spec must define the dual-mode read strategy: "if state.json exists with `pipeline.total_tokens`, use actual tokens; else use heuristic constants."

---

## Section D: Source-of-Truth & Validation Questions

### Q13: What exact text does the external review recommendation D10 contain — is the word "observability" used, what payload field names are explicitly recommended, and is the source document dated 2026-04-07 or 2026-04-08?

**A:**

The review report is at `docs/plans/readmine-project/ceos-agents-review-report.md`. The exact text of D10 (lines 203–204) is:

> **D10. Observability hooks**  
> Rozšířit Notifications systém o structured event payload (phase, duration, tokens_used, outcome) pro integrace s observability platformami (Grafana, DataDog). Umožnit real-time sledování pipeline, nejen post-hoc dashboard.

Key findings from the D10 text:

1. **The word "observability" IS used** — in the section heading ("Observability hooks") and in the body phrase "observability platformami".
2. **Explicit payload field names recommended by D10:** `phase`, `duration`, `tokens_used`, `outcome` — exactly four fields.
3. **No `tool_uses` field** is mentioned in D10. The field appears in the roadmap v6.8.0 spec but is NOT in the external reviewer's original recommendation.
4. **No specific event names** are defined in D10 — it says "structured event payload" but does not enumerate `pipeline-started`, `step-completed`, or `pipeline-completed` by name. Those event names originate in the v6.8.0 roadmap (lines 621–716 of `docs/plans/roadmap.md`), not in D10.

**Date resolution:**  
- `input.md` (line 10) states "external review 2026-04-08, D10"  
- The review report file carries the text `*Zpráva zpracována: 2026-04-07*` at line 224  
- File system `mtime` is 2026-04-10 (last git commit that touched the file), not authoritative for the authoring date  
- The document's own date field (`Zpráva zpracována: 2026-04-07`) is the authoritative source for when the review was completed  
- Resolution: **the review was authored/processed on 2026-04-07**. The "2026-04-08" in `input.md` is an off-by-one error (likely when the review was received/read by the project owner, one day after authoring).

**Citations:**
- `docs/plans/readmine-project/ceos-agents-review-report.md:203–204` — verbatim D10 text
- `docs/plans/readmine-project/ceos-agents-review-report.md:224` — `*Zpráva zpracována: 2026-04-07*`
- `.forge/phase-0-meta/input.md:10` — "external review 2026-04-08, D10" (off-by-one relative to file's own date)
- `docs/plans/readmine-project/ceos-agents-review-report.md:195` — Section 8.3 heading ("Priorita: Střední") under which D10 appears

**Confidence:** HIGH

**Follow-up:** Phase 4 spec should cite D10 as "authored 2026-04-07" (matching the file's own datestamp). The spec should note that `tool_uses` is a v6.8.0 addition beyond the D10 recommendation — it is not contradicted by D10 but also not mandated by it. The mandatory payload fields per D10 are: `phase`, `duration`, `tokens_used`, `outcome`.

---

### Q14: Is the "forge brainstorm 2026-04-05 (approved)" Autopilot design present as a standalone file in `docs/plans/brainstorm/` or `docs/plans/`, or is the roadmap section (lines 621–643) the only artifact?

**A:**

No standalone brainstorm file exists for the Autopilot feature. A glob search of `docs/plans/brainstorm/` and `docs/plans/` for any file containing "autopilot" or dated "2026-04-05" returned no results. The `input.md` reference to "forge brainstorm 2026-04-05 (schválený)" identifies a forge pipeline run that produced the Autopilot design — but no output artifact from that run was committed to `docs/plans/brainstorm/`. The file system shows `.forge.bak-20260415-*` and `.forge.bak-20260416-*` directories (multiple forge runs), but none dated 2026-04-05, and none of them contain an autopilot-specific brainstorm document in their `/phase-3-brainstorm/` artifacts.

Therefore: **`docs/plans/roadmap.md` lines 621–643 are the sole authoritative ground truth** for the approved Autopilot design decisions — the 7 config key names, lock-file path `.ceos-agents/autopilot.lock`, two-query classification rule (Bug query + Feature query), and CLI invocation pattern `/ceos-agents:autopilot [--max N] [--dry-run]`.

Any ambiguities in roadmap lines 621–643 cannot be resolved by consulting a more detailed source document — the spec must accept the roadmap prose as final and resolve ambiguities inline.

**Citations:**
- `.forge/phase-0-meta/input.md:8` — "Zdroj: forge brainstorm 2026-04-05 (schválený)" (references an approved design)
- bash glob output — no file matching "autopilot" in `docs/plans/brainstorm/` or `docs/plans/`
- `.forge.bak-20260416-065037/` directory listing — confirms this bak covers 2026-04-15/16, no 2026-04-05 bak visible
- `docs/plans/roadmap.md` — designated sole ground truth (no competing artifact found)

**Confidence:** HIGH (confirmed by negative search result; no alternative source found in two search strategies)

**Follow-up:** Phase 4 spec authors should be aware that any Autopilot behavior the roadmap text does not resolve (e.g., exact lock-file contention behavior on Windows, exact Feature Workflow absence handling) has no documentary backstop — these must be decided by the spec itself, not deferred to a brainstorm.

---

## Key Findings

- **`/resume-ticket` is fully backward-compatible with v6.8.0 state.json** without code changes: it reads only 5 specific field paths, never validates schema_version, and state-manager uses additive merge-writes (not whole-object replacement).

- **`/metrics` Step 6 uses hardcoded heuristic constants** (`sonnet ~30k`, `opus ~50k`, `haiku ~5k`) and reads NO state.json today. A dual-mode read strategy is required for v6.8.0 to use actual `tokens_used` from state.json when available.

- **Agent Overrides via `core/agent-override-injector.md` apply to any agent dispatched by `fix-ticket`, `fix-bugs`, and `implement-feature`** — the injector is called before every Task dispatch (line 590 of fix-ticket). Since Autopilot dispatches fix-ticket and implement-feature, overrides will apply transitively to Autopilot-dispatched agents with no new wiring needed.

- **Webhook event enum is open-ended**: `core/post-publish-hook.md` and `core/block-handler.md` define only two existing events (`pr-created`, `issue-blocked`) inline in their curl commands — there is no registry file or enum that blocks adding new events. The pattern is additive (check `if event in On events`, fire curl).

- **D10 mandates exactly four payload fields**: `phase`, `duration`, `tokens_used`, `outcome`. The `tool_uses` field in the v6.8.0 roadmap is a spec addition beyond the external review recommendation (not contradicted, but not mandated).

- **The review report is dated 2026-04-07** (file's own `Zpráva zpracována:` field, line 224). The "2026-04-08" in `input.md` is an off-by-one.

- **The Autopilot `disable-model-invocation` flag is genuinely ambiguous**: 14 of 28 skills carry it (all pipeline dispatchers); analyze-bug and metrics (direct user commands) do not. Autopilot is both a user entry point AND a dispatcher of pipeline skills — the pattern does not unambiguously resolve to one value.

- **Roadmap lines 621–643 are the sole ground truth for the approved Autopilot design**; no standalone brainstorm file was committed.
