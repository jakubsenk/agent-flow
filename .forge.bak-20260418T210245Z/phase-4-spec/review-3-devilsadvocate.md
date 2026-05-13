# Phase 4 Spec Review — Devil's Advocate

```json
{
  "tier_1": null,
  "tier_2": null,
  "tier_3": {
    "correctness": 3,
    "completeness": 2,
    "security": 3,
    "maintainability": 3,
    "robustness": 2
  },
  "overall_verdict": "FAIL",
  "confidence": 0.78,
  "findings": [
    {
      "id": "f-devilsadvocate-1",
      "severity": "MAJOR",
      "title": "`run_id` semantics are undefined — spec re-uses the ticket ID but claims to enable re-run correlation, which it does not",
      "where": "requirements.md Section 7 Gate-1 Ledger row 5; design.md Section 4.3/4.4/4.5 (all three payload examples show `run_id: \"PROJ-42\"` equal to `issue_id`); brainstorm final.md line 177 ('equals issue_id for single-issue runs but enables future re-run correlation')",
      "problem": "The spec never defines what a `run_id` actually is. state/schema.md:149 says `run_id` is the RUN-ID per the RUN-ID Determination table, which for a tracker pipeline IS the `ISSUE-ID` verbatim (`PROJ-42`). In every design.md payload example `run_id == issue_id`. The Gate-1 rationale (ledger row 5) justifies including `run_id` because it 'enables re-run correlation at 1 string cost' — but if run_id always equals issue_id, a re-run produces the SAME run_id, and consumers still cannot distinguish two runs of the same ticket. The field is pure overhead with zero correlation benefit unless run_id incorporates a timestamp, UUID, or invocation counter. This is a contract surface frozen by v6.8.0 that consumers will rely on — changing its semantics later (e.g., to `PROJ-42#2026-04-17T14:30:00Z`) IS a breaking webhook-payload change. Fix: either (a) redefine run_id to include a monotonic suffix for tracker pipelines (which changes state.json directory naming and breaks resume by path), or (b) drop run_id from webhook payloads and document it as NOT_IN_SCOPE for v6.8.0.",
      "fix_hint": "Add an explicit subsection 'RUN-ID for webhook correlation' to requirements.md stating: (i) for v6.8.0, run_id == issue_id for tracker pipelines; (ii) consumers MUST NOT assume run_id uniqueness across re-runs; (iii) re-run distinction is deferred to a future version. Or: remove run_id from payloads entirely — the 'cheap' argument collapses once it delivers no correlation."
    },
    {
      "id": "f-devilsadvocate-2",
      "severity": "MAJOR",
      "title": "Lock is project-directory-local — two users on different hostnames running Autopilot against the same tracker will both process the same issue",
      "where": "requirements.md AUTOPILOT-R2 (lock path `.ceos-agents/autopilot.lock/`); brainstorm final.md 'Backward Compat Risks' row 3 ('lock is project-directory-local')",
      "problem": "The lock file is in the project checkout directory. Scenario: User A on builder-01 and User B on builder-02 both have a clone of the same repo with the same Automation Config pointing at the same YouTrack/Gitea/Jira instance, and both cron jobs fire at 02:00. Both acquire their OWN local lock successfully (different disks entirely). Both query the same bug query. Both pick up PROJ-42. Both dispatch fix-ticket. Now two parallel fixer-reviewer loops push conflicting branches, duplicate PRs, and whichever one runs `/tracker:transition` first sets the other agent's state transitions to fail with 'state already changed'. The spec has ZERO mitigation for this — no tracker-level lock (e.g., a custom field `autopilot_owner`), no first-dibs comment-claim, no advisory leases in state.json. 'Document in Step 1' (brainstorm risk mitigation) is not a fix — it is an admission. This is the exact pain point Autopilot is marketed to solve (headless cron dispatch at scale).",
      "fix_hint": "Before dispatching an issue, Autopilot should post an atomic tracker-level 'claim' comment like `[ceos-agents-autopilot] {hostname}:{pid} claimed at {iso8601}` and re-read the issue; if another agent already claimed within 15s, skip. Or: add an EARS requirement that Autopilot MUST NOT be deployed for the same tracker from multiple hostnames, and document this as an operational constraint in docs/guides/autopilot.md with a loud warning."
    },
    {
      "id": "f-devilsadvocate-3",
      "severity": "MAJOR",
      "title": "`pipeline.summary_table` is an unbounded markdown string embedded in state.json — dashboard/resume reads will load O(stages × characters) per read, no truncation specified",
      "where": "requirements.md COST-R6; design.md Section 4.2 shows the string with 7 rows but no max length; NOT_IN_SCOPE item 5 ('Summary table lives in state.json.pipeline.summary_table')",
      "problem": "For a fix-ticket with all optional stages enabled (triage, code_analysis, reproducer, fixer_reviewer, test, e2e_test, browser_verification, acceptance_gate, publisher, deployment) plus feature stages or scaffold stages, the summary_table can exceed 15 rows. Scaffold pipelines with full implementation fan-out to 13+ stages. The example in 4.2 is ~600 characters; worst case is easily 2–3 KB. Not catastrophic in isolation — BUT: (a) state.json is atomically written via tmp+rename on EVERY stage update (core/state-manager.md:30); (b) /dashboard globs all state.json files in .ceos-agents/ across runs; (c) /resume-ticket reads full state.json; (d) /metrics reads the full file. Markdown inside JSON is also a data/presentation coupling nightmare — Skeptic himself flagged this in brainstorm ('Ugly pattern'). No max length is specified, no truncation rule, no size budget. Spec also does not forbid a consumer (e.g., dashboard) from writing the summary_table into other state.json files or PR bodies, which would amplify. For long-term maintainability this is a silent growth vector and a pre-rendered-presentation-in-data smell.",
      "fix_hint": "Add COST-R6a: `pipeline.summary_table` MUST NOT exceed 4 KB; rows exceeding the budget are dropped with a footer `... N stages truncated`. Also add a structured `pipeline.stages_summary: [{stage, model, tokens, duration_s, tools}, ...]` sibling field so dashboard/metrics can read data without parsing markdown — mark the markdown string as the 'human-readable projection' only."
    },
    {
      "id": "f-devilsadvocate-4",
      "severity": "MAJOR",
      "title": "Webhook blast radius: step-completed events are not throttled, not batched, not size-capped — at 10 pipelines/day × 10+ stages × slow consumer, the skill can stall for minutes",
      "where": "requirements.md WEBHOOK-R3; Section 7 Gate-1 Ledger row 5 (payload minimum); inherited from core/post-publish-hook.md Section 3 (curl --max-time 5 --retry 0)",
      "problem": "The spec inherits the existing advisory pattern (curl --max-time 5), which sounds safe. But consider: one pipeline fires `pipeline-started` + up to 13 `step-completed` + `pipeline-completed` = 15 webhooks per pipeline. fix-bugs batch mode in Autopilot context can drive this to 10+ issues × 15 events = 150 synchronous curl calls per cron cycle. If the webhook endpoint is a slow Grafana ingest returning 5xx after 3 seconds (or just hanging), the pipeline stalls 5 × 150 = 750 seconds (12.5 min) of wall-clock time PURELY waiting for timeouts, not doing work. Autopilot's Lock timeout is 120 min so the lock does not save you on day one, but productivity is shot and cron jobs back up behind each other. Also: 'advisory failure' means EVERY failed webhook logs a `[WARN]` line — pipeline.log blows up with 150 WARN lines per run for a single bad endpoint. No circuit breaker (e.g., 'after 3 failures this run, stop firing'), no event throttling, no max-size check on payload JSON. Roadmap line 651 explicitly defers retry logic — good — but it does not defer rate-limiting, which is a different issue.",
      "fix_hint": "Add WEBHOOK-R5a: after 3 consecutive webhook failures in a single pipeline, suppress all further webhook attempts for the remainder of that pipeline (log one `[WARN] Webhook circuit open after 3 failures — suppressing remaining events`). Add WEBHOOK-R9: webhook payload JSON MUST NOT exceed 8 KB; over-limit payloads are truncated (iteration_count retained, step_name retained, timestamp retained)."
    },
    {
      "id": "f-devilsadvocate-5",
      "severity": "MAJOR",
      "title": "`/metrics` dual-mode footer silently mixes measured and estimated totals in the same sum — user cannot tell which numbers are trustworthy",
      "where": "requirements.md COST-R7, COST-R8; AC-19",
      "problem": "COST-R7 says: 'when pipeline.total_tokens exists, it shall sum measured values; otherwise it shall fall back to heuristic constants.' COST-R8 says it shall append a footer `Data source: measured={X} issues, estimated={Y} issues`. The spec never forbids mixing the two sums. Example: a sprint has 20 issues — 3 ran under v6.8.0 (actual 45K/92K/18K = 155K tokens), 17 ran under v6.7.x and fall back to heuristic (17 × opus 50K = 850K). /metrics reports `Total: 1,005,000 tokens. Data source: measured=3 issues, estimated=17 issues.` The user reads this, treats it as a real number, and concludes opus usage is exploding — when actually 85% of it is a guessed constant. Heuristic `opus ~50K` is itself a wild guess: real forge phases in this very repo show `tokens_estimated` ranging 80K–230K per phase. The footer is a fig leaf; the output is misleading. Worse: for small sprints where N_measured=1 and N_estimated=1, the 'measured=1 estimated=1' footer makes the aggregate nearly meaningless. Spec should either (a) refuse to sum across the boundary and report two separate totals, or (b) add a loud warning when the mixed-mode ratio is skewed.",
      "fix_hint": "Revise COST-R8 to: '/metrics shall output two separate totals — `Measured total: {X} tokens across {N} issues` and `Estimated total (heuristic): {Y} tokens across {M} issues` — and shall NOT output a combined single-line grand total when any issues fall back to heuristics.'"
    },
    {
      "id": "f-devilsadvocate-6",
      "severity": "MINOR",
      "title": "Upgrade path from v6.7.2 → v6.8.0 has no migration note — users upgrade mid-run and in-flight state.json files may be partially populated",
      "where": "design.md 3.6 (CHANGELOG.md entry) — no migration section; docs/guides/autopilot.md (NEW) covers operations but not upgrade; AC-27/AC-28 only verify version/changelog strings",
      "problem": "Scenario: customer on v6.7.2 is mid-pipeline (fix-ticket paused after triage). They upgrade the plugin. Resume runs with v6.8.0 code against a state.json that has NO usage fields. Q11 research answer says this works (5-field path reader) — correct for /resume-ticket, but /metrics running over the SAME directory now reports this issue as 'estimated' (COST-R7) even though the pipeline continued under v6.8.0 and collected usage for later stages. Some stages have measured data, some have none — state.json is a hybrid, but metrics treats the whole run as 'estimated' because pipeline.total_tokens is absent. Nothing in the spec addresses this hybrid state. Also, the CHANGELOG does not tell users 'if you have in-flight pipelines, let them complete before upgrading' or 'measured data will be partial for resumed runs.' Operators will be surprised.",
      "fix_hint": "Add to CHANGELOG.md 6.8.0 entry: a 'Migration notes' paragraph stating (a) in-flight v6.7.2 pipelines resume cleanly but will lack cost data for already-completed stages; (b) /metrics treats any state.json missing pipeline.total_tokens as 'estimated' even if per-stage usage fields are partially populated. Add AC to verify CHANGELOG contains 'Migration' keyword in the 6.8.0 section."
    },
    {
      "id": "f-devilsadvocate-7",
      "severity": "MINOR",
      "title": "MCP failure in Autopilot exits 3 without a retry — a transient 30-second network blip kills the cron cycle",
      "where": "requirements.md AUTOPILOT-R12; brainstorm final.md Step 0",
      "problem": "Autopilot Step 0 does a single MCP ping and exits 3 on failure. No retry, no exponential backoff. Cron runs hourly; if the tracker has a 60-second outage exactly when Autopilot fires, the entire hour is skipped AND no state is recorded (no lock, no log entry per AUTOPILOT-R12 'no side-effects'). There is no visibility into why Autopilot didn't run — the log file is only appended in Step 4. The /dashboard has no 'autopilot skipped due to MCP failure' counter. Spec also does not say the exit 3 message goes to stderr (it uses `[STOP]` prefix but not destination). Cron harvesters that only capture non-zero exits and non-empty stderr may not see this.",
      "fix_hint": "Either (a) add AUTOPILOT-R12a: on MCP failure, retry with backoff (e.g., 3 attempts at 5s/15s/45s) before exit 3, OR (b) require the exit-3 message to also append a line to Log file so operators have one log location to tail. Document the cron-level retry policy expectation in docs/guides/autopilot.md."
    },
    {
      "id": "f-devilsadvocate-8",
      "severity": "MINOR",
      "title": "`tokens_used` vs forge's `tokens_estimated` divergence is ratified without a documented cross-plugin reconciliation path",
      "where": "requirements.md Section 7 Gate-1 Ledger row 1; brainstorm Gate 1 discussion bullet 3; research Q1",
      "problem": "Research Q1 flagged this as the 'single most consequential finding' (MEDIUM confidence). Brainstorm raises it as a Gate-1 discussion item. User approves `tokens_used`. But the spec then provides NO rename dictionary, NO note in state/schema.md cross-referencing the forge artifact, NO Known-Issue entry in CHANGELOG. NOT_IN_SCOPE item 15 says 'No forge.json changes' — fine, but a future /metrics cross-plugin aggregator (or ASYSTA, per user's roadmap memory) will need to reconcile the names. By then no one remembers the divergence. Additionally, the research finding that the actual Task tool API field name is NOT verified by static inspection (Q1 MEDIUM) is never resolved — the spec just asserts COST-R2 reads `result.usage.total_tokens`, `result.usage.duration_ms`, `result.usage.tool_uses`. If the Task tool actually returns `tokens_estimated` (matching forge), COST-R2 will silently read undefined and the defensive clause (COST-R3) writes 0 for every run, making all measured values zero. This bug would not be caught by tests/scenarios/cost-state-fields.sh because the test stubs the Task tool to return the spec-defined shape.",
      "fix_hint": "Add a Phase 5 TDD requirement: at least one test that dispatches a REAL sub-agent (not a stub) via Task tool against a trivial prompt and asserts that `result.usage` contains the three fields by the spec-defined names. Alternatively, add COST-R2b: the skill SHOULD also accept `result.usage.tokens_estimated` as a synonym for `total_tokens` for forward-compat and log an INFO line when that path triggers."
    },
    {
      "id": "f-devilsadvocate-9",
      "severity": "MINOR",
      "title": "CHANGELOG v6.8.0 entry is described but not drafted — style-consistency with v6.7.2 entry is unverified",
      "where": "design.md 3.6 (CHANGELOG.md row); AC-28 verifies headers and keywords only",
      "problem": "v6.7.2's CHANGELOG entry (lines 10–33) uses Added/Changed/Fixed subsections, bolded component names, specific line-count claims, and per-file migration notes. AC-28 only checks that `## [6.8.0]` exists and the three keywords Autopilot/Observability/Cost appear SOMEWHERE in it. A minimal entry like `## [6.8.0] Added: Autopilot. Added: Observability. Added: Cost Visibility.` would pass AC-28 but violate the established style. The spec tells the user WHAT to write but does not provide the draft. Given that the user's memory explicitly calls out 'Doc completeness before commit — audit ALL doc files' (feedback_doc_completeness.md), CHANGELOG drift at release time is a known past-pain failure mode.",
      "fix_hint": "Add a CHANGELOG template subsection to design.md listing mandatory bullets for each of the three features (version bump + file count + EARS-id coverage), AND tighten AC-28 to also assert presence of '### Added' subsection under the 6.8.0 heading."
    },
    {
      "id": "f-devilsadvocate-10",
      "severity": "MINOR",
      "title": "Trap-based lock release uses a static path string — if CWD changes or env vars expand unexpectedly, the trap silently deletes the wrong path",
      "where": "design.md Section 4.8 lock acquisition snippet; AC-5",
      "problem": "The snippet `trap 'rm -rf \"$LOCK_DIR\"' EXIT` with `LOCK_DIR=\".ceos-agents/autopilot.lock\"` (relative path) is vulnerable: (a) if the skill `cd`s into a subdirectory between Step 0 and Step 5 (e.g., for git operations), the trap runs with the new CWD and either fails silently (no lock to delete there) or deletes an unrelated path; (b) `rm -rf` on a relative path in a trap is a classic footgun. Portable fix is trivial: resolve to absolute path at lock acquisition. The spec does not mandate this. AC-5 greps for the pattern but won't catch the absolute-vs-relative distinction.",
      "fix_hint": "Update Section 4.8 snippet to `LOCK_DIR=\"$(pwd)/.ceos-agents/autopilot.lock\"` before the trap. Update AC-5 to also assert the snippet resolves LOCK_DIR to an absolute path (e.g., grep for `pwd` or `realpath`)."
    },
    {
      "id": "f-devilsadvocate-11",
      "severity": "MINOR",
      "title": "Autopilot trap races with mkdir: trap is registered before the conditional mkdir, so a mkdir-failed (lock held by other) path will rm -rf the lock owned by the other process",
      "where": "design.md Section 4.8 lines 212–230; requirements.md AUTOPILOT-R5 (trap registration timing unspecified)",
      "problem": "Reading 4.8 literally: `trap 'rm -rf \"$LOCK_DIR\"' EXIT` is set at line 213 BEFORE the `if mkdir` on line 214. If mkdir fails because a fresh non-stale lock exists (line 227 path), the script exits 2 — and the trap fires, running `rm -rf .ceos-agents/autopilot.lock`, destroying the OTHER process's live lock directory. Next invocation re-acquires happily, and the first process that was legitimately holding the lock now has no lock. This breaks the entire concurrency guarantee. AUTOPILOT-R5 says 'When autopilot exits... it shall release the lock via trap' but does not specify that the trap must be registered AFTER a successful mkdir.",
      "fix_hint": "Rewrite the lock snippet so the trap is registered ONLY after a successful mkdir (or after successful stale re-acquire). Alternatively, the trap body should check that owner.json.pid matches $$ before rm -rf. Update AUTOPILOT-R5 to: 'After successful lock acquisition, the Autopilot skill shall register `trap` to release the lock on exit. On failed acquisition, no trap shall be registered.' Update AC-5 to assert trap is conditional."
    },
    {
      "id": "f-devilsadvocate-12",
      "severity": "MINOR",
      "title": "No EARS requirement for Autopilot when `Issue Tracker` section itself is absent or malformed — cascading undefined behavior",
      "where": "requirements.md AUTOPILOT-R1..R12 collectively; brainstorm Step 0 says 'Read Issue Tracker (required)' but no EARS clause covers missing-required-section failure mode",
      "problem": "If a user installs the plugin and enables Autopilot without an `### Issue Tracker` section (or with one missing `Bug query`), Autopilot cannot run. But the EARS list has no requirement for this case. AUTOPILOT-R6 talks about querying `Bug query` — if that key is absent from config, what happens? Brainstorm table row ('Config missing required section → exit 4, release lock if acquired') is prose only. AC-3/AC-4/AC-7/AC-8 don't cover this. A user with a misconfigured CLAUDE.md will get either a cryptic MCP error or a silent zero-issues classification depending on how /check-setup interprets absence.",
      "fix_hint": "Add AUTOPILOT-R13: 'When `### Issue Tracker` section is absent or `Bug query` key is missing from Automation Config, the Autopilot skill shall print `[autopilot][ERROR] Issue Tracker configuration incomplete: {reason}` and exit with status 4.' Add matching AC and test scenario."
    }
  ]
}
```

## Summary

**VERDICT: FAIL** — three MAJOR findings block ship: (1) `run_id` contract surface is semantically hollow (always equals issue_id, so no re-run correlation), (2) the lock file is directory-local with zero cross-hostname protection (two CI runners against the same tracker will double-process issues), (3) `pipeline.summary_table` is an unbounded markdown string coupling data + presentation inside state.json.

Beyond the blockers: `/metrics` mixed-mode output silently sums real and guessed numbers with only a cosmetic footer; webhook blast radius has no circuit breaker (150 failing curls × 5s can stall Autopilot batch runs by 12 minutes); and the lock-trap snippet in design.md Section 4.8 has a concurrency-destroying bug where a failed mkdir still triggers rm -rf on another process's live lock.

Completeness is weak: no upgrade/migration note for v6.7.2→v6.8.0, no resolution of the `total_tokens` vs `tokens_estimated` Task-tool-API uncertainty that Phase 2 Q1 flagged MEDIUM confidence, no CHANGELOG draft to ensure style consistency, and no EARS clause for missing Issue Tracker config.

## Scariest Three (production pain hypotheticals)

1. **f-devilsadvocate-2 (lock scope):** Six months post-ship, a customer adds a second CI runner for redundancy. Both runners autopilot the same tracker. Duplicate PRs flood the team, fixer commits race-to-push, tracker state transitions fail half the time. Root cause is "we never thought about multi-host" and the plugin has no mitigation primitive.

2. **f-devilsadvocate-11 (trap race):** First production bug within a week. Two cron windows overlap by 30 seconds on a slow MCP call. Second invocation's trap fires on exit-2 and nukes the first invocation's lock. First invocation keeps running without a lock; third invocation sees no lock and starts too. Cascade of parallel fix-ticket runs on the same issue. Silent corruption.

3. **f-devilsadvocate-4 (webhook stall):** Customer configures Grafana webhook, Grafana has a bad afternoon and returns 503 after 4.9s. Autopilot batch with 10 issues × 15 events = 150 × 5s = 12.5min added to every cron cycle. Cron jobs pile up, operators think Autopilot is "slow" and disable it — the observability feature breaks the thing it was meant to observe.
