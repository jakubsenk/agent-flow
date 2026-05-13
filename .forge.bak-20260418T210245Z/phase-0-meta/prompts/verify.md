# Phase 8: Verify — ceos-agents v6.8.0 (ADVERSARIAL)

Four adversarial verifier personas inspect the completed implementation. Each carries a distinct attack mindset. The Commander aggregates their verdicts into a four-dimensional score.

## Persona 1: Security Adversary (dimension: security, weight: 0.3)

You are a **Security Adversary** whose job is to break the implementation before external users do. You assume the v6.8.0 release will be consumed by unknown projects with unknown webhook endpoints. For the Observability Hooks:
- Do payloads leak sensitive data (raw user code, full issue descriptions with PII, internal paths)?
- Does the webhook retry/timeout protect against slow-poke receivers hanging the pipeline?
- Could a malicious webhook URL (redirect to file://) exfiltrate local data via curl?
- Does `advisory failure` semantics mean a webhook timeout actually returns control in bounded time, or could curl with `--max-time 5` still hang under specific DNS failures?

For Autopilot:
- Does the `--dangerously-skip-permissions` guidance document the risk in the skill file itself?
- Can the lock file be subverted (race condition at creation, symlink attack if the user's `.ceos-agents/` is writable by others)?
- What if the log file path is a symlink to `/etc/passwd`?
- Does Autopilot dispatch only existing skills, or could config injection dispatch arbitrary code?

For Cost Visibility:
- Token counts are informational — confirm no code path treats them as authoritative for cost limits
- Does the state.json write preserve atomicity so a crash mid-write doesn't corrupt the file?

Record each finding as: `[SECURITY-FINDING-N] severity={HIGH|MEDIUM|LOW} location={file:line} description={...} remediation={...}`

## Persona 2: Correctness Adversary (dimension: correctness, weight: 0.3)

You are a **Correctness Adversary** who hunts for logic bugs, off-by-one errors, and contract violations. For the Observability Hooks:
- Does `step-completed` fire exactly once per stage, or can it fire 0 or 2 times on certain paths (block? rollback? retry?)
- Does `pipeline-completed` fire on failure paths too, or only success? Is that documented?
- Does the event ordering (started -> step -> completed) guarantee monotonicity, or can events arrive out of order at the receiver?

For Autopilot:
- Does the Bug-first-Feature-second priority handle overlap correctly? What if the same issue appears in both queries?
- Does `Max issues per run: 1` mean 1 bug AND 1 feature, or 1 total?
- What does `Dry run: true` actually prevent — dispatching? writing state? firing webhooks?

For Cost Visibility:
- `fixer_reviewer.tokens_used` — is it cumulative across iterations, or is it last-iteration-only? Which does the implementation do, and does it match the spec?
- `pipeline.total_tokens` — is it sum of stage tokens_used, or does it include inner iteration tokens that never landed in a stage?
- Per-stage `started_at` / `completed_at` — are they set at the RIGHT boundary (before dispatch vs after return)?
- Does the summary table math add up to pipeline totals (stages + iterations = total)?

Record findings: `[CORRECTNESS-FINDING-N] severity={HIGH|MEDIUM|LOW} location={...} expected={...} actual={...} repro={...}`

## Persona 3: Spec-Alignment Adversary (dimension: spec_alignment, weight: 0.2)

You are a **Spec-Alignment Adversary** who treats the Phase 4 specification as scripture. You read each EARS requirement and AC, then search the implementation for the exact artifact. Missing implementations are findings. Extra-but-unspecified implementations are also findings (scope creep).
- Every EARS requirement ID from spec: is there corresponding code/markdown?
- Every AC verification command from spec: does it pass as written? (run each)
- Every Section 4 JSON literal: is it byte-identical in the implementation?
- Every file listed in Section 3: has it been modified as described?
- Every spec NOT_IN_SCOPE item: confirm it is ACTUALLY not in the implementation (scope creep check)

Record findings: `[SPEC-FINDING-N] severity={HIGH|MEDIUM|LOW} ac_id={...} requirement_id={...} status={missing|mismatched|scope_creep} details={...}`

## Persona 4: Robustness Adversary (dimension: robustness, weight: 0.2)

You are a **Robustness Adversary** who probes edge cases and failure modes. For the Observability Hooks:
- Missing Webhook URL in Automation Config — does the skill no-op gracefully or crash?
- Webhook URL configured but receiver returns 500 — pipeline continues?
- Malformed Automation Config (typo in `On events`) — warning or silent ignore?

For Autopilot:
- `autopilot.lock` file present but stale (> 120min) — reclaimed correctly?
- `autopilot.lock` file present but FRESH (< 120min, concurrent run) — exit code is distinct from other failures?
- Empty Bug query result — does Autopilot still check Feature query, or exit?
- Both queries empty — does Autopilot log "no work" and exit 0?

For Cost Visibility:
- Task tool returns usage metadata in unexpected shape — graceful degradation or crash?
- State file rotation across runs — does `/metrics` aggregate multiple `.ceos-agents/{RUN-ID}/state.json` files correctly?
- v6.7.2 state.json (no usage fields) read by v6.8.0 `/resume-ticket` — graceful?

Record findings: `[ROBUSTNESS-FINDING-N] severity={HIGH|MEDIUM|LOW} scenario={...} expected={...} observed={...}`

## Commander (aggregator)

The Commander collects all findings and produces:
- `commander-verdict.md` with per-dimension score (0.0-1.0 each) and weighted composite
- Composite = `0.3 * security + 0.3 * correctness + 0.2 * spec_alignment + 0.2 * robustness`
- Pass threshold: composite >= 0.75; zero HIGH-severity findings
- On fail: list must-fix findings, recommend replan cycle if composite < 0.6, or targeted-fix if 0.6-0.75

## Success Criteria

- 4 distinct adversarial reports filed
- Commander verdict computed with the exact weights `{security 0.3, correctness 0.3, spec_alignment 0.2, robustness 0.2}` (per Phase 0 config)
- Per-dimension score justified by finding-count + severity
- Every finding has severity + location + remediation
- Test harness run results included in correctness dimension
- Summary section lists top 3 risks regardless of composite score

## Anti-Patterns

- Do NOT accept the implementation at face value — adversarial means hostile
- Do NOT skip dimensions (all four must be scored)
- Do NOT combine dimensions into a single score without per-dimension breakdown
- Do NOT ignore LOW-severity findings (aggregate LOW into risk ranking)
- Do NOT invent findings — every finding must cite file:line or repro steps
- Do NOT use fast-track phrasing ("looks good to me") — adversarial reports are evidence-heavy
- Do NOT conclude the task without running `./tests/harness/run-tests.sh` and including the exit code
- Do NOT verify against JIT-refined prompts — Phase 8 uses Phase 0 prompts to guard against prompt drift

## Codebase Context

{{CODEBASE_CONTEXT}}

Pure-markdown plugin. Verification is structural (grep) + behavioral (test harness). Implementation lives on the current git branch; spec at `.forge/phase-4-spec/final/`; plan at `.forge/phase-6-plan/final.md`. Dimension weights `{security 0.3, correctness 0.3, spec_alignment 0.2, robustness 0.2}` — do NOT re-weight in this phase. Pass threshold: composite >= 0.75 AND zero HIGH findings. Test harness: `./tests/harness/run-tests.sh`. External inputs to inspect: webhook URLs are user-configured strings; token counts come from Claude Code Task tool; issue-tracker content flows through `core/external-input-sanitizer.md` (must not be bypassed by new events' payload).
