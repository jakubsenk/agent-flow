```json
{
  "tier_1": null,
  "tier_2": null,
  "tier_3": {
    "correctness": 3.5,
    "completeness": 3.0,
    "security": 3.0,
    "maintainability": 4.0,
    "robustness": 3.0,
    "weights": {
      "correctness": 0.30,
      "completeness": 0.25,
      "security": 0.20,
      "maintainability": 0.15,
      "robustness": 0.10
    },
    "weighted_aggregate": 3.3
  },
  "overall_verdict": "FAIL",
  "confidence": "HIGH",
  "findings": [
    {
      "id": "f-quality-1",
      "severity": "MAJOR",
      "category": "correctness",
      "title": "Multiple AC verification commands use `\\|` inside `grep -E` — will not match as intended",
      "detail": "AC-6, AC-21, AC-22, AC-23, AC-28 all use the pattern `grep -nE \"X\\|Y\"`. Inside a double-quoted bash string the backslash is preserved into the regex argument; in ERE mode `\\|` is a literal pipe character, NOT alternation — alternation in ERE is bare `|`. AC-6 would search for the literal string `fix-ticket|implement-feature` instead of either. AC-22's `17 optional\\|18 optional`, AC-23's `28 skills\\|29 skills`, AC-28's `Autopilot\\|Observability\\|Cost Visibility` all fail the same way. These ACs cannot be satisfied by any implementation. Fix: remove the backslash (use `|`) or switch to `grep -E` without it, or use two separate greps.",
      "location": "formal-criteria.md AC-6, AC-21, AC-22, AC-23, AC-28"
    },
    {
      "id": "f-quality-2",
      "severity": "MAJOR",
      "category": "correctness",
      "title": "AC-2 references test file `autopilot-lock-acquire.sh` that design.md does not create",
      "detail": "AC-2 text says `inverted positive check in autopilot-lock-acquire.sh shows owner.json present`, but design.md Section 3.7 test table lists only autopilot-dry-run.sh, autopilot-lock-held.sh, autopilot-lock-stale.sh, autopilot-feature-workflow-absent.sh for the autopilot family. Phase 7 will have no such file to create unless the AC or design is updated. Either add the test to design.md Section 3.7 or rewrite AC-2 to use only existing scenarios.",
      "location": "formal-criteria.md AC-2 vs design.md Section 3.7"
    },
    {
      "id": "f-quality-3",
      "severity": "MAJOR",
      "category": "completeness",
      "title": "Three file changes from the approved brainstorm are missing from design.md",
      "detail": "Phase 3 final.md (Item 1 `File changes`) lists: `skills/workflow-router/SKILL.md` (add autopilot intent row), `docs/reference/pipelines.md` (add `Autopilot batch dispatch` subsection), and `examples/config-templates/*` (append `### Autopilot` example to 2 of 8 templates). None of these appear in design.md Section 3. Phase 7 will not touch them and Gate 2 decisions get silently lost. Either add to Section 3 or explicitly mark as descoped in NOT_IN_SCOPE with rationale.",
      "location": "design.md Section 3.6 vs brainstorm/final.md Item 1 File changes table"
    },
    {
      "id": "f-quality-4",
      "severity": "MAJOR",
      "category": "completeness",
      "title": "Stage enum mismatch: `reproduction` vs `reproducer`",
      "detail": "state/schema.md uses the object name `reproduction` (line 79). Section 4.1 applied-list uses `reproduction` (correct). But design.md Section 3.3 bullet (a) for fix-ticket lists stages as `reproducer if run`, and brainstorm Item 2 `Stage enum` lists `reproducer`. Phase 7 will be unsure whether the state.json stage is called `reproduction` (schema) or `reproducer` (design narrative) — and whether the webhook `step_name` is one or the other. Fix: pick one (schema already established `reproduction`) and use it consistently in design.md Section 3.3 and in webhook payload `step_name` examples.",
      "location": "design.md Section 3.3 vs state/schema.md line 79"
    },
    {
      "id": "f-quality-5",
      "severity": "MAJOR",
      "category": "correctness",
      "title": "WEBHOOK-R3 fire-order ambiguity: before or after state write?",
      "detail": "WEBHOOK-R3 reads `When a top-level pipeline stage writes {stage}.status: completed to state.json and Webhook URL is configured... the skill shall fire a step-completed webhook`. Does the webhook fire BEFORE or AFTER the atomic state-manager write? If after — a state-write failure followed by a fired webhook causes observable state to diverge from webhook stream. If before — a webhook-before-commit represents a stage that may never actually commit. core/state-manager.md already advertises advisory write semantics (retry once, then log and continue), making this non-trivial. Spec must pin the sequence: `write state → fire webhook` (preferred, webhook reflects reality) with explicit note that a failed state write suppresses the webhook.",
      "location": "requirements.md WEBHOOK-R3 + design.md Section 3.3"
    },
    {
      "id": "f-quality-6",
      "severity": "MAJOR",
      "category": "robustness",
      "title": "Lock-acquisition race window in Section 4.8 snippet",
      "detail": "The snippet does: `mkdir` → on failure, parse acquired_at → if stale, `rm -rf` + `mkdir || exit 2`. Between `rm -rf` and `mkdir`, a third autopilot run can slip in. The snippet handles this by exiting 2 on mkdir failure, but R3's message `Another Autopilot run in progress` is only emitted in the fresh-lock branch — the post-stale failure path prints `[autopilot][ERROR] lock re-acquire failed`, which no AC checks for. More importantly, after stale-recovery the parsed PID/hostname/timestamp of the competing owner is not re-read, so the log line lies about `age`. Fix: retry the entire read→stale-check loop once after stale-removal failure, and update messaging.",
      "location": "design.md Section 4.8"
    },
    {
      "id": "f-quality-7",
      "severity": "MAJOR",
      "category": "robustness",
      "title": "`date -u -d \"$acquired_at\"` is not portable to BSD date (macOS)",
      "detail": "Section 4.8 uses `$(date -u -d \"$acquired_at\" +%s)` for ISO timestamp parsing. This is GNU-date syntax. BSD date on macOS requires `-j -f '%Y-%m-%dT%H:%M:%SZ'`. The spec claims `mkdir`-based bash for portability and says `Windows Git Bash: mkdir resolves via MSYS and works identically` — but does not address macOS date-arithmetic. A macOS developer running autopilot with a stale lock would silently skip the stale-detection branch (the arithmetic produces garbage on BSD). Fix: either specify Python/Perl timestamp parsing, or provide both GNU and BSD branches, or explicitly restrict autopilot to Linux+Windows Git Bash in operations guide.",
      "location": "design.md Section 4.8 stale-check snippet"
    },
    {
      "id": "f-quality-8",
      "severity": "MAJOR",
      "category": "completeness",
      "title": "Missing tests for AUTOPILOT-R5, R8, R10, R12",
      "detail": "R5 (trap-release lock on EXIT) has only the grep-based AC-5 — no scenario that actually runs a failing autopilot and asserts the lock directory is gone afterward. R8 (Feature limit > 0 without Feature query WARN) has no scenario. R10 (`On error: stop` breaks the loop) has no scenario — only the default `skip` path is implicitly covered. R12 (MCP unreachable exits 3 without creating lock) has no scenario. These are observable runtime behaviors; static grep is insufficient. Add four scenarios to design.md Section 3.7.",
      "location": "design.md Section 3.7 vs requirements.md AUTOPILOT-R5, R8, R10, R12"
    },
    {
      "id": "f-quality-9",
      "severity": "MAJOR",
      "category": "correctness",
      "title": "AC-13 cannot actually verify payload `field lists contain exactly X` via `grep -A3`",
      "detail": "AC-13 expects `grep -A3 '\"event\":\"pr-created\"' core/post-publish-hook.md` to demonstrate that the existing payload is unchanged. But `grep -A3` prints lines; it does not parse JSON. A future edit adding a new field to the heredoc would still show 3 lines of context and pass. The AC does not actually lock the contract. Fix: use a byte-diff against a frozen reference (`diff <(sed -n '/pr-created/,+4p' ...) tests/fixtures/pr-created-payload.json`), or move the assertion into a scenario that captures the payload with nc and parses it with jq, comparing the key set to a fixed list.",
      "location": "formal-criteria.md AC-13"
    },
    {
      "id": "f-quality-10",
      "severity": "MAJOR",
      "category": "security",
      "title": "No webhook URL validation (SSRF / injection surface)",
      "detail": "The Webhook URL is copied from CLAUDE.md Automation Config directly into `curl --data-binary @- \"{Webhook URL}\"`. If an operator places a hostile URL (file:///, internal cloud-metadata endpoint 169.254.169.254, localhost port-scan probes) the plugin will dutifully POST to it — plus the JSON payload may include `issue_id`, `pipeline`, and `pr_url` which can leak project internals. Spec should at minimum (a) require `https://` or `http://`, (b) reject loopback/link-local addresses in production, OR (c) explicitly acknowledge as out-of-scope trusted-operator with a security-note paragraph pointing to operator responsibility. Current spec treats URL as fully trusted with zero validation — no mention in security considerations.",
      "location": "requirements.md Section 1.2 / design.md Section 4.3–4.5"
    },
    {
      "id": "f-quality-11",
      "severity": "MAJOR",
      "category": "security",
      "title": "Lock-file `owner.json` parsing is brittle and injection-prone",
      "detail": "Section 4.8 parses owner.json with `grep -o '\"acquired_at\":\"[^\"]*\"' | cut -d'\"' -f4`. Under adversarial conditions a hostile process writing to the same `.ceos-agents/` directory could place a crafted owner.json with quote-escaped payloads or control characters that break the `date -d` call. More practically: if the file is empty or partially written (crash mid-write), the regex returns empty string and `date -d \"\" +%s` returns current-epoch, which would evaluate as 0-minutes-old and falsely report the lock as fresh, blocking all future runs until the 120-minute natural expiry. Fix: defensive parse with explicit `[ -z \"$acquired_at\" ] && { rm -rf lock; retry; }` branch.",
      "location": "design.md Section 4.8"
    },
    {
      "id": "f-quality-12",
      "severity": "MAJOR",
      "category": "robustness",
      "title": "Clock-skew is not acknowledged",
      "detail": "Stale detection uses `$(date -u +%s) - $(date -u -d \"$acquired_at\" +%s)`. If two hosts share the `.ceos-agents/` directory over NFS/CIFS with skewed clocks (even a few minutes), a fresh lock on host A may appear stale to host B — autopilot-on-B would `rm -rf` an active lock directory and race host A. The spec says `two repos run independently` but offers no guard if the repo is accessed from multiple hosts. Add a note: stale threshold minus-epsilon buffer (e.g., `(now - acquired_at) > (Lock_timeout + 5)` minutes) to absorb typical drift, or mandate single-host usage explicitly.",
      "location": "design.md Section 4.8 + requirements.md AUTOPILOT-R4"
    },
    {
      "id": "f-quality-13",
      "severity": "MINOR",
      "category": "completeness",
      "title": "`webhook-pipeline-events.sh` scenario depends on `nc` availability — Windows Git Bash",
      "detail": "Design.md Section 3.7 says `Starts a local HTTP listener (nc -l or Python one-liner)`. Neither is guaranteed on Windows Git Bash (ncat/nc often absent; Python 3 is present but not always on PATH). Spec should pin ONE implementation (Python one-liner with `python -c` is most portable) and include an `nc` / `python` availability precheck (SKIP with exit 77 if neither).",
      "location": "design.md Section 3.7"
    },
    {
      "id": "f-quality-14",
      "severity": "MINOR",
      "category": "completeness",
      "title": "CHANGELOG.md AC-28 regex does not match 2026-04-17 date",
      "detail": "Design.md Section 3.6 requires `Add v6.8.0 entry dated 2026-04-17 with three subsections`. AC-28 only checks the heading `## 6.8.0` and the three keywords — it doesn't verify the date or the `MINOR` classification note. A date-less or mis-dated entry passes. MINOR because a reviewer will notice, but Phase 7 has no machine gate.",
      "location": "formal-criteria.md AC-28 vs design.md Section 3.6"
    },
    {
      "id": "f-quality-15",
      "severity": "MINOR",
      "category": "maintainability",
      "title": "`pipeline.summary_table` stores markdown inside JSON — coupling data+presentation",
      "detail": "Acknowledged in brainstorm as a known trade-off (Skeptic note). Spec proceeds anyway. Recommend documenting in state/schema.md that consumers wishing to re-render should parse `pipeline.total_tokens/duration_ms/tool_uses` (the structured fields) and regenerate their own table — the markdown is a convenience artifact, not the canonical source. Without this note, downstream tooling may lock onto the markdown format and future format changes (column order, units) become breaking.",
      "location": "design.md Section 4.2"
    },
    {
      "id": "f-quality-16",
      "severity": "MINOR",
      "category": "maintainability",
      "title": "Spec does not specify how `{stage}.model` is derived",
      "detail": "COST-R4 says `{stage}.model` is written before dispatch. Brainstorm pseudocode reads `{agent.model_from_frontmatter}`. Design.md Section 3.3 does not spell out how the skill knows the model — is it hardcoded per stage (e.g., triage → sonnet) or read dynamically from agents/{name}.md frontmatter? For fixer_reviewer it's just `opus` (hardcoded). For the scaffold variant stages, nothing is stated. Phase 7 will have to guess. Fix: add a one-line rule: `{stage}.model` is the agent's frontmatter `model` field, read at dispatch time; or provide an explicit stage→model mapping table.",
      "location": "design.md Section 3.3 + state-manager.md modifications"
    },
    {
      "id": "f-quality-17",
      "severity": "MINOR",
      "category": "robustness",
      "title": "Concurrent Autopilot with `/fix-bugs` or direct `/fix-ticket` not addressed",
      "detail": "The autopilot.lock guards only against concurrent autopilot runs. A human running `/ceos-agents:fix-ticket PROJ-42` directly while autopilot is dispatching the same ticket is unguarded — both processes write to `.ceos-agents/PROJ-42/state.json`. state-manager.md line 74 says `last-write-wins (acceptable — human should not run the same ticket twice)`. Spec should surface this constraint in docs/guides/autopilot.md as an operator warning, not leave it implicit.",
      "location": "design.md Section 3.6 docs/guides/autopilot.md"
    },
    {
      "id": "f-quality-18",
      "severity": "MINOR",
      "category": "correctness",
      "title": "AC-30 regex is unnecessarily complex and fragile",
      "detail": "`grep -nE 'mkdir\\s+[\"'\"'\"']*\\.ceos-agents/autopilot\\.lock' skills/autopilot/SKILL.md` — the `[\"'\"'\"']*` is an attempt to match optional quotes via shell-escape gymnastics. If the implementer writes `mkdir -p .ceos-agents/autopilot.lock/` (with `-p` and trailing slash), the regex fails. Simplify: `grep -nE 'mkdir .*\\.ceos-agents/autopilot\\.lock' skills/autopilot/SKILL.md`.",
      "location": "formal-criteria.md AC-30"
    }
  ]
}
```

## Human-Readable Summary

**Weighted aggregate: 3.3 / 5 — FAIL** (minimum threshold 3.5 AND every criterion ≥ some floor).

The spec is directionally correct and well-grounded in the brainstorm, but carries a cluster of Phase-7-blocking defects that together prevent a deterministic, testable build:

### Top concerns

1. **Five AC verification commands are syntactically broken** (f-quality-1). The `\|` inside `grep -E` is literal pipe, not alternation. AC-6, AC-21, AC-22, AC-23, AC-28 cannot pass. This alone disqualifies the spec without a rewrite pass.

2. **Design coverage gaps** against the approved brainstorm (f-quality-3): `skills/workflow-router/SKILL.md`, `docs/reference/pipelines.md`, and `examples/config-templates/*` updates are approved but not listed in Section 3. Phase 7 will silently drop them.

3. **Portability claims don't hold** (f-quality-7 + f-quality-12): `date -u -d ISO_TS` is GNU-only; macOS BSD date fails silently, and clock-skew over shared filesystems can destroy fresh locks. The spec promised `portable bash` after revising away PowerShell but the portability claim is not rigorously verified.

Supporting issues: stage-name inconsistency (`reproduction` vs `reproducer`), missing runtime tests for R5/R8/R10/R12, webhook fire-order ambiguity vs atomic state write, no webhook URL validation, brittle owner.json parsing, and a referenced but undefined test file (`autopilot-lock-acquire.sh`).

### Recommendation

Return to spec-writer with the findings list. None of the MAJOR items require rethinking Gate 1 decisions — they are tightening, consistency, and portability fixes. Re-review after fixes; expected aggregate should clear 4.0+.
