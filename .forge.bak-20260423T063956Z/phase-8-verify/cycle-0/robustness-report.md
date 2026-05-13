# Phase 8 Robustness Report — v6.9.0 (Devil's Advocate)

**Reviewer:** Phase 8 Devil's Advocate / Robustness Reviewer
**Implementation under review:** commits `3b7db77` (feat) + `6673fdd` (version bump) on `main`
**Spec reference:** `.forge/phase-4-spec/final/{requirements,design}.md`
**Method:** Source-walk + adversarial execution of bash snippets (parse_pause_timeout, sanitize_block_reason, awk trim, grep extraction) on Git-Bash 4.x and analysis of cross-skill state-flow contracts.

## Overall robustness score: 0.52

Multiple **critical** functional bugs in the NEEDS_CLARIFICATION pipeline (the headline v6.9.0 feature) that would cause every paused issue to be auto-aborted by Autopilot or to consume DoS budget at 2x the documented rate. The credential-redaction sanitizer leaks lowercase env-var assignments and JSON-style fields. Tests are doc-presence-only — they never functionally execute the bash code they claim to validate, so these bugs sailed through Phase 7 + Phase 8 quality gates.

---

## Failure scenarios (12)

### Scenario 1: `clarification.asked_at` is NEVER written by orchestrators → autopilot auto-aborts every paused issue

- **Severity**: CRITICAL
- **Trigger**: User pauses on NEEDS_CLARIFICATION; autopilot scans the queue before user resumes.
- **Failure mode**:
  - Orchestrator skills (`skills/fix-ticket/SKILL.md:219`, `:410`; `skills/fix-bugs/SKILL.md:241`, `:466`; `skills/implement-feature/SKILL.md:406`; `skills/scaffold/SKILL.md:812`) construct the `clarification` object with fields `{question, asked_by_agent, asked_at_step, asked_at_iteration, context, answer, clarifications_consumed, last_clarification_iteration}` — but **NOT** `asked_at`.
  - `skills/autopilot/SKILL.md:321` reads `jq -r '.clarification.asked_at // empty'` → returns empty string.
  - Line 322: `pause_age_seconds=$(( $(date +%s) - $(date -d "$asked_at" +%s 2>/dev/null || echo 0) ))` — empty `asked_at` makes `date -d ""` either return midnight today (GNU date) or fail (BSD date → `|| echo 0` triggers).
  - On BSD/macOS or any system where `date -d ""` fails → `pause_age = current_epoch (≈1.7B) - 0 = 1.7B`. `1.7B > 2592000` (30 days default) → ALWAYS true → state mutated to `aborted_by_system` with `abort_reason: "clarification_timeout"`, comment misleadingly says "clarification timeout exceeded" when in fact pause was created seconds ago.
  - Even on GNU date where `date -d ""` returns midnight today: in the worst case, the issue gets aborted at midnight UTC of every day, regardless of when it was actually paused.
- **Detection**: Functional test of autopilot pause-skip path against a freshly-paused issue would catch this. Current test (`v6.9.0-autopilot-skip-paused.sh`) only `grep`s for documentation strings — it never simulates a real paused state.json. Pipeline harness reports PASS.
- **Mitigation**: Three-line fix — add `asked_at: now` to all six jq write sites and document `asked_at` in `state/schema.md` clarification field table.

### Scenario 2: `clarifications_consumed` is double-incremented (orchestrator + resume-ticket) → DoS cap fires at 1.5 round-trips, not 3

- **Severity**: HIGH
- **Trigger**: Operator answers any 2 NEEDS_CLARIFICATION prompts in a single pipeline run.
- **Failure mode**:
  - Orchestrator at detection time (e.g., `skills/fix-ticket/SKILL.md:219`) writes `clarifications_consumed: ((.clarification.clarifications_consumed // 0) + 1)` — increment #1.
  - `skills/resume-ticket/SKILL.md:32` Step 4 says: "Increment `clarification.clarifications_consumed` by 1." — increment #2 per round-trip.
  - Net effect after 2 user-answered round-trips: `consumed = 4`. The 3rd detection check `if [ "$CONSUMED" -ge 3 ]` → BLOCK with `"exceeded max clarifications (3 per run)"`.
  - Spec design.md:619 explicitly states: "Counters increment at the moment the clarification fenced block is detected and BEFORE the pipeline transitions to `paused` status." — the resume-side increment is contrary to design intent.
- **Detection**: Functional round-trip test (pause → resume → pause → resume → pause → expect 3rd to succeed) would catch this. No such test exists.
- **Mitigation**: Remove "Increment ... clarifications_consumed by 1" from `skills/resume-ticket/SKILL.md:32` Step 4 (keep only `last_clarification_iteration` write).

### Scenario 3: `state.iteration` field doesn't exist → per-iteration cap (REQ-046) is permanently triggered by 2nd clarification

- **Severity**: HIGH
- **Trigger**: Two clarifications emitted within one pipeline run, regardless of whether they're in the same fixer iteration.
- **Failure mode**:
  - `skills/fix-ticket/SKILL.md:210`, `:401`; `skills/fix-bugs/SKILL.md:232`, `:457`: `CURRENT_ITER=$(jq -r '.iteration // 0' state.json)`.
  - But `state/schema.md` defines no top-level `state.iteration` field. The actual iteration counter is `fixer_reviewer.iterations` (schema line 261).
  - `jq` returns `0` (the `// 0` default) on every read. Both `LAST_ITER` and `CURRENT_ITER` always equal `0`.
  - First clarification: `LAST_ITER=null` (or `0` after // 0), `CURRENT_ITER=0` — passes if comparing `null != "0"`, but bash string-comparison of `null` to `0` is `"null" = "0"` → false → first one passes.
  - Second clarification: `LAST_ITER=0`, `CURRENT_ITER=0` → `"0" = "0"` → BLOCK with `"clarification limit per iteration exceeded"`.
- **Detection**: A scenario emitting 2 clarifications across 2 fixer iterations would expose this (the cap should permit this). No such functional test exists.
- **Mitigation**: Replace `.iteration` with `.fixer_reviewer.iterations` at all 6 read sites. (Outside of the fixer-reviewer loop, e.g., during triage, the field is `0` which is the correct semantic.)

### Scenario 4: `sanitize_block_reason()` leaks lowercase env-var credentials and JSON-style password fields

- **Severity**: HIGH (security)
- **Trigger**: Block detail contains lowercase env-var assignments (`db_password=hunter2`, `secret_key=topsecret`) OR JSON-style password fields (`{"password": "secret"}`).
- **Failure mode**: Direct adversarial test of the function (sourced from `core/post-publish-hook.md:250-269` verbatim):
  ```
  Input: db_password=hunter2 → Output: db_password=hunter2     (no redaction)
  Input: {"password": "secret_xyz"} → Output: {"password": "secret_xyz"}
  Input: {"api_token":"AAA-BBB-CCC"} → Output: {"api_token":"AAA-BBB-CCC"}
  Input: -----BEGIN PRIVATE KEY-----\nMIIEvAI...secretkeydata\n-----END PRIVATE KEY----- → Only BEGIN line redacted, body leaks
  ```
  - The VAR pattern `(^|[[:space:]])([A-Z_][A-Z0-9_]*=)[^[:space:]]+` requires UPPERCASE-only var names. Real-world `.env` files mix case (`db_password`, `pgPassword`, `apiSecret`) — none would match.
  - JSON-style key/value pairs (the most common form in error messages from REST APIs) have no pattern at all.
  - PGP private key body bypasses redaction entirely (only the BEGIN sentinel is replaced; the secret-bearing body lines remain).
- **Detection**: `tests/scenarios/v6.9.0-pipeline-history-credential-redaction.sh` only checks that the 14 redaction-tag literals appear in the markdown file body and runs isolated bash regex tests against pre-known matching inputs. It NEVER sources the actual function and feeds it adversarial inputs.
- **Mitigation**: 
  1. Extend VAR pattern to `[A-Za-z_][A-Za-z0-9_]*` (case-insensitive var names).
  2. Add a JSON-style pattern: `"(password|secret|token|api_?key|credential)"[[:space:]]*:[[:space:]]*"[^"]*"` → `"$1": "[REDACTED-JSON-FIELD]"`.
  3. Document explicitly that PGP/SSH key bodies are not multi-line redacted (already noted in design.md:912 for v6.9.1 — but the body is still leaking in v6.9.0; consider stripping the entire `BEGIN…END` block in awk-mode preprocessing).
  4. Add a TRUE functional test that sources the function and asserts redaction on adversarial input batteries.

### Scenario 5: `awk '/^## /{i++} i>=NR-50'` does NOT trim oldest H2 sections — it cuts by line number

- **Severity**: HIGH
- **Trigger**: pipeline-history.md grows beyond 50 sections.
- **Failure mode**:
  - The "Pseudocode" awk pattern from design.md:923 was shipped verbatim into `core/post-publish-hook.md:280` as the IMPLEMENTATION (no replacement performed).
  - Empirical test with 60 sections (4 lines each, 240 total lines) → after awk: only 17 sections retained, all from the START of the file (oldest ones). The intent was to keep the LAST 50 (newest).
  - Actual semantics: prints lines where `i >= NR - 50` (line-counter math, not section-counter). With `i` capped at 60 (count of sections seen so far), lines beyond NR=110 are dropped → entire history file is roughly halved without semantic boundaries.
  - Worst case: a single very-long block (e.g., a stack-trace-heavy run) consumes more than 50 lines → its own block is itself truncated mid-block on the next append; subsequent reads return malformed markdown.
- **Detection**: A trim-correctness test simulating 60 appends and asserting "exactly 50 H2 sections, newest preserved" would catch this. `v690-pipeline-history-trim.sh` is referenced in design.md:851 but does NOT exist in `tests/scenarios/`.
- **Mitigation**: Replace with a portable, section-aware trim:
  ```bash
  tac "$file" | awk '/^## /{c++} c<=50' | tac > "$file.tmp" && mv "$file.tmp" "$file"
  ```
  (`tac` is GNU-only — for POSIX, use `sed -n` reverse or write a 5-line awk that records section start line numbers.) Mid-truncation crash leaves `$file.tmp` orphan but original `$file` intact (atomic mv); no partial-trim corruption window.

### Scenario 6: Agents emit `Question:` (capitalized) but orchestrators grep for `^question:` (lowercase) → CLARIFICATION HATCH never triggers

- **Severity**: CRITICAL (functional)
- **Trigger**: Fixer or triage-analyst emits NEEDS_CLARIFICATION using the format documented in their own .md files.
- **Failure mode**:
  - `agents/fixer.md:61` instructs: `Question: <max 280 chars, single line — the specific question the operator must answer>`
  - `agents/triage-analyst.md:52` instructs: `Question: <max 280 chars, single line — the specific question the reporter must answer>`
  - `core/agent-states.md:24` (the contract) says: `question: <max 280 chars, single line>`
  - `skills/fix-ticket/SKILL.md:197`: `QUESTION=$(grep -A1 "^question:" "$TRIAGE_OUTPUT" | head -1 | sed 's/^question: //')`
  - The skill regex is **lowercase-anchored**. The agents are documented to emit **capitalized**. An LLM following the agent prompt will likely emit `Question:` → orchestrator extraction returns empty → empty `QUESTION` argument → jq writes `clarification.question = ""` → resume-ticket displays "Q: " (empty) to the operator.
  - Even worse: subsequent grep for `^context:` extracts the line `Context: ...` → but that line begins with `Context:` (capital `C`), not `context:` → `CONTEXT=""`. Both fields silently empty.
- **Detection**: A round-trip test with a mock fixer agent emitting the documented format would catch this. None exist.
- **Mitigation**: Either (a) make grep case-insensitive: `grep -iA1 "^question:"`, (b) update agents/fixer.md and agents/triage-analyst.md to emit lowercase `question:`, or (c) accept both with `grep -EA1 "^[Qq]uestion:"`.

### Scenario 7: `parse_pause_timeout()` unit downcase comment is a lie — `30 Days` (capitalized) silently falls back to default

- **Severity**: MEDIUM
- **Trigger**: Operator writes `Pause timeout | 30 Days` (capitalized D) or `1 Hour` in their CLAUDE.md, mirroring the human-readable column header capitalization.
- **Failure mode**: Adversarial test of the function copy-pasted from `skills/autopilot/SKILL.md:272-296`:
  ```
  30 days  : 2592000 (OK)
  30 Days  : [WARN] Invalid Pause timeout '30 Days'; using default 30 days  → 2592000
  1 HOUR   : [WARN] Invalid Pause timeout '1 HOUR'; using default 30 days   → 2592000
  30days   : [WARN] (no space) → 2592000
  0.5 days : [WARN] (decimal) → 2592000
  5 weeks  : [WARN] (unit not in {hour,hours,day,days}) → 2592000
  ```
  - The code comment claims "Strip surrounding whitespace; downcase the unit" but the actual sed `'s/^[[:space:]]+|[[:space:]]+$//g'` does NOT downcase. The regex `(hours?|days?)` is lowercase-only.
  - Failure is graceful (logs WARN, falls back to 30 days) — not catastrophic — but the silent fallback can cause operators to believe they configured a 365-day window when they actually have 30 days.
- **Detection**: `tests/scenarios/v6.9.0-pause-timeout-validation.sh` does not source and execute the function — only `grep`s for keyword strings. Empirical adversarial input tests are absent.
- **Mitigation**: Two-line fix — apply `tr 'A-Z' 'a-z'` after the whitespace strip, OR use a case-insensitive bash regex with `shopt -s nocasematch` scoped to the regex check.

### Scenario 8: Multi-line `context:` values are silently truncated to one line

- **Severity**: MEDIUM
- **Trigger**: Fixer or triage emits a NEEDS_CLARIFICATION block with multi-line context (per `core/agent-states.md:25` "may span multiple lines, max 500 chars").
- **Failure mode**: 
  - The extraction `CONTEXT=$(grep -A1 "^context:" "$FIXER_OUTPUT" | head -1 | sed 's/^context: //')` takes only the FIRST line after `context:`. If context starts on the same line, fine. If context starts on the NEXT line (after a header line `context:`), only the FIRST body line is captured.
  - Empirical test with multi-line input → result is the literal string `context:` (the header line itself).
  - Operator on resume sees only fragment context → asks fixer for clarification with insufficient grounding.
- **Detection**: None.
- **Mitigation**: Use awk block extraction (`awk '/^context:$/{f=1;next} /^[a-z]+:|^##/{f=0} f' file | head -c 500`) or `sed -n '/^context:/,$p' | tail -n +2`.

### Scenario 9: Race condition — autopilot `aborted_by_system` write clobbers concurrent `resume-ticket` answer

- **Severity**: HIGH
- **Trigger**: Operator runs `resume-ticket --clarification "answer"` while a cron-scheduled autopilot scan is in-flight against the same issue.
- **Failure mode**:
  - Autopilot Step 6.1a: read state.json → status==paused → compute pause_age → if exceeded → `jq '.status="aborted_by_system" | .abort_reason="clarification_timeout"' state.json > state.json.tmp && mv state.json.tmp state.json`.
  - Concurrently: resume-ticket reads same state.json → writes `clarification.answer`, sets `status="running"`.
  - The two writes race. Whichever `mv` lands second wins. If autopilot wins → the operator's answer is silently lost; the issue is now in `aborted_by_system` state but the user thinks they answered.
  - Worse: Scenario 1 makes autopilot ALWAYS believe pause is stale → autopilot ALWAYS attempts the abort write on every scan against a paused issue → race window is on every cron tick.
- **Detection**: Concurrent-write test would catch this. Process-local lock on autopilot does NOT protect against `resume-ticket` (different process, no shared lock).
- **Mitigation**: Either (a) make autopilot acquire a per-issue lock under `.ceos-agents/{ISSUE_ID}/lock/` matching the existing lock pattern, (b) have resume-ticket acquire that lock before writing, OR (c) add compare-and-swap by including the previous status in jq update conditions: `jq 'if .status=="paused" then ... else . end'`.

### Scenario 10: Snippet citation count mismatch — claimed 21 webhook-curl citations, actual count varies

- **Severity**: MEDIUM
- **Trigger**: Citation drift over future maintenance.
- **Failure mode**:
  - `core/snippets/README.md:21-25` and `core/snippets/webhook-curl.md:1052` claim expected counts: `webhook-curl: 21`, `issue-id-validation: 4`, `metrics-json-schema: 1`, `pipeline-completion: 3`, `architecture-freshness: 2`.
  - Actual counts in repo (skills + core/, excluding .forge/ and snippet self-`Used by:` self-references):
    - webhook-curl: ~23 markers (13 in fix-bugs, 2 in fix-ticket, 3 in implement-feature, 3 in post-publish-hook, 1 in block-handler, 1 in agent-states) — does not match `21` claimed.
    - Other snippets: counts also not exactly matching.
  - Design.md:1052 claims a verifier `tests/scenarios/v690-snippet-citation-counts.sh` enforces this. **The test file DOES NOT EXIST.** No actual machinery validates the counts. Drift is invisible.
- **Detection**: Manually computing counts vs README claims.
- **Mitigation**: Either (a) write the missing test (grep markers, count by name, compare to README table), OR (b) remove the Used by: line-number lists from snippet files (they are guaranteed to drift) and replace with ranges.

### Scenario 11: `pipeline-paused` webhook is documented but NEVER fires from any skill

- **Severity**: MEDIUM
- **Trigger**: Any pause transition.
- **Failure mode**:
  - The 5 jq write sites in skills (fix-ticket, fix-bugs, implement-feature, scaffold) write `status="paused"`, then `echo "[INFO] Pipeline paused — awaiting clarification..."`, then `exit 0`.
  - The `pipeline-paused` webhook is fully specified in `core/agent-states.md:52-78` and `core/post-publish-hook.md:139-188` — but no skill orchestrator invokes that snippet. The curl invocation lives only in markdown documentation.
  - REQ-050c is therefore unsatisfied at runtime. Operators who configured `On events: pipeline-paused` will receive zero events.
  - Test `tests/scenarios/v6.9.0-pipeline-paused-webhook.sh` only `grep`s for the documentation strings.
- **Detection**: Functional integration test would catch.
- **Mitigation**: Insert the curl block (with `Webhook URL` / `On events` gating) immediately before each `exit 0` in the pause-transition paths. Subject the call to circuit-breaker semantics — but see Scenario 12 (no circuit breaker counter exists either).

### Scenario 12: Webhook circuit breaker is documented but has zero implementation

- **Severity**: MEDIUM
- **Trigger**: Dead webhook endpoint.
- **Failure mode**:
  - `core/post-publish-hook.md:205-217` documents the in-memory per-run failure counter (`Counter starts at 0`, `When the counter reaches 3 consecutive failures, the circuit OPENS`).
  - Search of all skills + core for `WEBHOOK_FAILURE_COUNT`, `webhook_failure_count`, `FAILURE_COUNTER`, `circuit_open`, `breaker_state`: zero hits outside documentation/comments.
  - Each webhook call site is an independent curl invocation with no incrementing or pre-check. There is no shared bash variable, no state file, no integration. The "in-memory per-run" counter exists only in the LLM's interpretive ability to track variables across 18+ separate curl-emission code blocks across 4+ skills.
  - At runtime: dead webhook → 18+ × 5-second timeouts per pipeline run → ~90s pure latency wasted on doomed webhook deliveries. Circuit breaker text says "skills emits exactly once: `[WARN] Circuit breaker open...`" but no skill actually emits this line because no counter exists.
  - Test `v6.9.0-circuit-breaker-semantics.sh`: 5 assertions, all `grep` for documentation strings in `core/post-publish-hook.md`.
- **Detection**: Functional dead-endpoint test would catch.
- **Mitigation**: Either (a) add a real implementation — global bash variable `WEBHOOK_FAIL_COUNT=0`; helper `fire_webhook()` that increments + checks; refactor every curl site to call the helper, OR (b) downgrade the spec to "deferred to v6.9.1" honesty (matching the actual implementation state). Currently the docs over-promise.

---

## Critical findings (HIGH+) — should block release or be fast-followed

| # | Scenario | Severity | Action |
|---|----------|----------|--------|
| 1 | `asked_at` never written → autopilot auto-aborts paused issues | CRITICAL | **MUST FIX before broad rollout** — feature is functionally broken end-to-end |
| 6 | `Question:` vs `^question:` case mismatch → CLARIFICATION HATCH yields empty extraction | CRITICAL | **MUST FIX** — pause feature emits empty data on the happy path |
| 2 | `clarifications_consumed` double-incremented → DoS cap fires at consumed=4 instead of 3 | HIGH | Fast-follow v6.9.1 |
| 3 | `state.iteration` field doesn't exist → per-iteration cap broken | HIGH | Fast-follow v6.9.1 |
| 4 | `sanitize_block_reason()` leaks lowercase + JSON-style credentials | HIGH | Security fast-follow v6.9.1 |
| 5 | awk trim is broken pseudocode — cuts by line, not section | HIGH | v6.9.1 — corruption potential when history grows |
| 9 | autopilot-vs-resume race clobbers operator answer | HIGH | v6.9.1 with locking strategy |

Combined: scenarios 1+6 mean the headline feature (NEEDS_CLARIFICATION) is **functionally broken** in real operation. The pipeline pauses without a real question, the user types an answer into resume-ticket but extraction returned empty so there's nothing to actually answer. If autopilot is configured (which is the v6.9.0 OSS-readiness sweet spot), the issue is auto-aborted within minutes regardless.

The Phase 7 verification + Phase 8 verifier both passed because **all 41 v6.9.0 test scenarios are documentation-presence assertions**, not functional execution tests. The harness measures spec coverage, not behavioral correctness.

---

## Recommendations for v6.9.1

- **Test discipline overhaul**: every TDD test that claims to validate behavior MUST source the function and feed it inputs. Doc-presence assertions should be tagged `@doc-only` and counted separately from functional pass-counts.
- **Snippet citation enforcement**: ship the missing `tests/scenarios/v690-snippet-citation-counts.sh` referenced in design.md and snippet README. Or remove the `Used by:` line lists (drift-prone) in favor of `grep` recipes.
- **Forge artifact size**: 42 `.forge.bak-*` directories totaling 15MB committed to repo. At ~1.4MB per release × 100 releases = 140MB+ of historical artifacts. Either (a) add a retention policy (keep last 5 backups), (b) move to a separate orphan branch, or (c) externalize to release artifacts.
- **Shallow clone freshness**: confirmed false-negative on `--depth=1` clones — `commits_since` always returns 0. Document advisory-only nature explicitly so CI users running shallow clones don't mistakenly believe the freshness check is active.
- **PGP/SSH key body redaction**: design.md acknowledges as v6.9.1 deferral; restate in spec for 6.9.1 sprint pickup.
- **`pipeline-paused` webhook firing**: insert the curl block at all 5 pause-transition sites OR remove the webhook event from the spec.
- **Circuit breaker**: implement OR document as deferred (don't ship over-promising docs).
- **`.ceos-agents/` permissions documentation**: state/schema.md notes `state.json` `block.detail` is INCLUDE — operators in shared-host environments should be told explicitly to `chmod 700 .ceos-agents/` (not just "advisory"). Consider adding a startup check that warns if mode is world-readable.
- **Phase-3 catalog miss verification**: scenarios 1, 2, 3, 6, 11, 12 are NEW (not in Phase 3 final.md adversarial catalog). Phase 3 focused on injection / DoS / forwards-compat; missed the spec-implementation drift class entirely.

---

## Verdict + JSON

```json
{
  "dimension": "robustness",
  "score": 0.52,
  "verdict": "CONDITIONAL_PASS",
  "critical_scenarios": 2,
  "high_scenarios": 5,
  "medium_scenarios": 5,
  "completed_at": "2026-04-19T00:00:00Z",
  "blocking_for_release": [
    "Scenario 1 (asked_at never written → autopilot auto-aborts paused issues)",
    "Scenario 6 (Question vs ^question case mismatch → empty extraction on happy path)"
  ],
  "fast_follow_v691": [
    "Scenario 2 (clarifications_consumed double increment)",
    "Scenario 3 (state.iteration missing field)",
    "Scenario 4 (sanitize_block_reason lowercase + JSON leaks)",
    "Scenario 5 (awk trim broken)",
    "Scenario 9 (autopilot-vs-resume race)",
    "Scenario 11 (pipeline-paused webhook never fires)",
    "Scenario 12 (circuit breaker documented but not implemented)"
  ],
  "notes": "All 41 v6.9.0 test scenarios are documentation-presence checks, not functional tests. The headline NEEDS_CLARIFICATION feature is broken end-to-end. Recommend conditional release with v6.9.1 emergency follow-up addressing scenarios 1+6 minimum."
}
```

DONE
