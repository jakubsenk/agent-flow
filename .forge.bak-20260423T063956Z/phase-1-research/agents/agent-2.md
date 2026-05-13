# Phase 1 Research Questions — Agent 2 (Security/Compliance lens)

## Self-score: 0.88
My confidence that the question set is complete and well-targeted. Minor uncertainty on
pipeline-history PII scope (Q22-23) and the exact test scenario to reference for
REPO_ROOT depth (the hidden test directory does not exist in the current tree, only
the harness invocation from scenarios/).

## Categories covered: A, B, C, D, E, F, cross-cutting

---

## Questions

### A — OSS Readiness

1. What SPDX license identifier should replace "UNLICENSED" in `plugin.json` and
   `marketplace.json`? Enumerate MIT, Apache-2.0, and BSD-3-Clause and compare on:
   (a) OSI approval status, (b) patent-grant clause (Apache-2.0 only), (c) convention
   among pure-markdown Claude Code plugins. Is there an existing license file anywhere
   in the repo to avoid contradicting?
   Target files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`,
   repo root (no LICENSE file present — confirmed absent).

2. Does `marketplace.json` have a `license` field that must be updated alongside
   `plugin.json.license`, or is it inherited? Quote the current schema of both files
   to confirm the exact key names and whether both need patching.
   Target files: `.claude-plugin/plugin.json` (line 9: `"license": "UNLICENSED"`),
   `.claude-plugin/marketplace.json` (no license key currently — verify).

3. The internal hostname `gitea.internal.ceosdata.com` appears in at least three
   user-facing files outside the plugin metadata: `docs/guides/installation.md`,
   `skills/onboard/SKILL.md`, `tests/mock-project/CLAUDE.md`, and
   `docs/reference/agents.md`. Which occurrences are example/placeholder values (safe
   to leave as-is or redact to `<your-gitea-host>`) versus hard-coded assumptions
   about the deployment environment that a public user cannot satisfy?
   Target files: `docs/guides/installation.md`, `skills/onboard/SKILL.md`,
   `docs/reference/agents.md`, `tests/mock-project/CLAUDE.md`.

4. What is the minimum viable content for `SECURITY.md`? Does the Contributor Covenant
   2.1 security reporting template cover: (a) preferred channel (email vs GitHub
   Security Advisory), (b) response SLA (days), (c) supported version range? What
   contact email should be listed — is `filip.sabacky@ceosdata.com` intended to be
   public, or should a dedicated alias be used?
   Target files: `CONTRIBUTING.md` lines 97-109 (existing "Code of Conduct" and
   "Reporting Issues" stubs that must not be duplicated), `README.md` lines 278-282
   ("Author & License" section).

5. `CODE_OF_CONDUCT.md`: Does `CONTRIBUTING.md` already contain a partial Code of
   Conduct (lines 103-109 — "Be respectful…")? If yes, does creating a full
   Contributor Covenant 2.1 file contradict or supersede that section? What change
   (if any) is needed to `CONTRIBUTING.md` so it links to the new
   `CODE_OF_CONDUCT.md` rather than duplicating content?
   Target files: `CONTRIBUTING.md` lines 103-109, `CONTRIBUTING.md` lines 97-102
   (Reporting Issues — references issues only, not SECURITY.md).

6. Where should issue and PR templates live for maximum compatibility given that the
   repo currently has `.gitea/workflows/test.yaml` but no `.github/` directory?
   Should both `.gitea/issue_template/` and `.github/ISSUE_TEMPLATE/` be created (for
   mirror readiness), or only the `.gitea/` tree until a GitHub mirror is confirmed?
   What template types are minimally required: bug-report, feature-request, PR?
   Target files: `.gitea/` (only `workflows/test.yaml` exists — no issue_template dir),
   absence of `.github/` confirmed.

7. `README.md` currently points to `plugin.json` for license details
   (`See plugin.json for license details` — line 282). After the license change, does
   the README need updating to cite the new LICENSE file and SPDX ID directly? Are
   there other docs that reference "UNLICENSED" or the internal Gitea URL that would
   become stale misinformation on a public mirror?
   Target files: `README.md` (lines 278-282), `docs/guides/installation.md` (lines
   12-36, all references to `gitea.internal.ceosdata.com`), `docs/reference/config.md`
   (line 57, SSRF note citing v6.9.0 deferral that will be resolved).

---

### B — v6.8.1 Polish

8. Exact count of `curl` invocations without `--proto "=http,https"` across the three
   primary skill files. `skills/fix-ticket/SKILL.md` has 12 curl calls at confirmed
   lines (106, 183, and ten more); `skills/fix-bugs/SKILL.md` has 11 curl calls;
   `skills/implement-feature/SKILL.md` has 3 curl calls — NONE of these 26+ calls
   include `--proto`. `core/post-publish-hook.md` Section 3 and Section 4 ALREADY have
   `--proto`. What is the complete list of line numbers needing the flag added, and
   does `skills/fix-bugs/SKILL.md` line 742 (the older `pipeline-complete` -d flag
   pattern) also need fixing or should it be removed as a duplicate/stale call?
   Target files: `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`,
   `skills/implement-feature/SKILL.md`.

9. `tests/scenarios/v681-harness-exit-propagation.sh` creates a temp file at
   `$TMPSCEN` (line 80) and deletes it inline at line 86 (`rm -f "$TMPSCEN"`), but
   there is NO `trap ... EXIT INT TERM` guard. If `bash "$HARNESS"` crashes or the
   user sends SIGINT before line 86, the temp file leaks into `tests/scenarios/`.
   What is the canonical trap pattern used in existing passing scenario tests (check
   `autopilot-trap-cleanup.sh` and `ac-v68-autopilot-trap-exit.sh` for reference
   patterns)? Should the fix be `trap 'rm -f "$TMPSCEN"' EXIT INT TERM` placed
   immediately after line 81 (`chmod +x "$TMPSCEN"`)?
   Target files: `tests/scenarios/v681-harness-exit-propagation.sh` (lines 79-86),
   `tests/scenarios/autopilot-trap-cleanup.sh` (lines 22-44, trap pattern reference).

10. `jq -n` (pretty-print, multi-line) vs `jq -nc` (compact, single-line): the
    canonical pattern in `core/block-handler.md` Step 5 uses `jq -n` (confirmed line
    43). The inline heredoc payloads in skill files use string interpolation (no jq).
    Are there any downstream consumers of webhook payloads that parse byte-equality
    (i.e., comparing raw JSON string bytes rather than parsed values)? Is there any
    documentation commitment in `core/post-publish-hook.md` or `docs/reference/config.md`
    that specifies whether payloads are compact or pretty-printed? Confirm whether
    `jq -nc` is strictly required or merely advisory.
    Target files: `core/block-handler.md` (line 43), `core/post-publish-hook.md`
    (Section 3 and Section 4 examples), `docs/guides/autopilot.md` (lines 288-296,
    payload safety guidance).

11. The `issue_id` allowlist regex `^[A-Za-z0-9#_-]+$` is defined in four skills
    (fix-ticket, fix-bugs, implement-feature, resume-ticket). Jira dotted-project keys
    like `PROJ.NAME-123` require adding `.` to the allowlist. What is the EXACT current
    regex text in each of the four skill files (are they identical)? Does adding `.`
    introduce any path-traversal risk on a Unix filesystem (`.` is safe in filenames;
    `..` is not — is the single-dot case guarded by anchoring `^...$` with no `..`
    possibility)? Should the restriction also be documented in prose for non-Jira
    trackers where `.` in issue IDs is unexpected?
    Target files: `skills/fix-ticket/SKILL.md` (lines 87-93),
    `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`,
    `skills/resume-ticket/SKILL.md`.

12. The roadmap cites a `REPO_ROOT` path bug in `.forge/phase-5-tdd/tests-hidden/*.sh`
    (`../../` should be `../../../`). However, this directory does NOT exist in the
    current repo tree (confirmed: `.forge/` only contains `config.json`, `forge.json`,
    `forge.log`, `phase-0-meta/`, `phase-1-research/`, `replanning/` — no
    `phase-5-tdd/`). The existing `tests/scenarios/*.sh` files use
    `$(cd "$(dirname "$0")/../.." && pwd)` (2 levels up from scenarios/ to repo root —
    correct). The `tests/scenarios/plugin-version-tracking/*.sh` files use
    `$(cd "$(dirname "$0")/../../.." && pwd)` (3 levels up from the subdir — correct).
    Is the REPO_ROOT path bug relevant to THIS release (Phase 5 will generate new test
    files)? Should Phase 4 spec mandate the correct depth as a requirement, or is this
    a TDD phase concern only?
    Target files: `tests/scenarios/v681-harness-exit-propagation.sh` (line 10: correct
    `../../`), `.forge/` directory listing (phase-5-tdd absent — path bug deferred).

13. `core/block-handler.md` line 59 documents `${var:1:-1}` as a counter-example (a
    Bash-specific construct NOT needed because `jq -n --arg` handles escaping). This
    prose appears to trigger a negative grep in an AC-ITEM-3.2 test (false positive).
    What is the exact grep pattern in the AC-ITEM-3.2 test that matches this line?
    Is the test checking for literal `${var:1:-1}` usage in curl payloads, and does
    restricting the grep to fenced code blocks (lines between ` ``` ` markers) fully
    resolve the false positive without weakening the test?
    Target files: `core/block-handler.md` (line 59), `tests/scenarios/` (search for
    the AC-ITEM-3.2 test file — likely `ac-v68-*` or `block-handler*` scenario).

---

### C — v6.8.0 Additions

14. `skills/metrics/SKILL.md` currently supports `--period N` and `--output path` flags
    (lines 10-16). The `--format json` flag is planned. What is the complete human-
    readable output structure emitted by Steps 4-8 of the current metrics skill (the
    summary table, per-agent table, and token cost section)? The JSON schema should be
    a machine-readable mirror — enumerate every top-level key, its type, and source
    step. Does the JSON output go to stdout (respecting `--output`) or always to a
    separate file?
    Target files: `skills/metrics/SKILL.md` (Steps 4-8, lines 59-end).

15. Circuit breaker for webhooks: `core/post-publish-hook.md` Section 4 specifies
    `--max-time 5 --retry 0` (confirmed). The circuit breaker must track consecutive
    failures and stop firing after a threshold. Where would circuit breaker state
    persist — in `.ceos-agents/circuit-breaker.json` (per-run, reset each pipeline)
    or in `.ceos-agents/` at the repo level (persistent across runs)? What is the
    failure threshold (e.g., 3 consecutive failures) and cooldown period (e.g., 60s)?
    Does the circuit breaker state need to be SSRF-resistant (i.e., a compromised
    webhook endpoint that always times out should trip the breaker without operator
    action)?
    Target files: `core/post-publish-hook.md` (Section 3 and Section 4 — all curl
    invocations), `state/schema.md` (to determine if circuit breaker state belongs in
    state.json or separate file).

16. `outcome: "failed"` fire path: `core/post-publish-hook.md` line 85 documents
    `outcome` as one of `success`, `blocked`, `failed`. The `pipeline-completed`
    payload with `outcome: "failed"` is documented but the fire path for catastrophic
    exits (OOM, SIGKILL, uncaught error) is not implemented. In a bash-driven markdown
    skill, catastrophic exit means the parent `claude -p` process dies without running
    cleanup. What minimal mechanism can fire the `outcome:failed` webhook — a `trap
    EXIT` in the skill's bash snippets, or a separate wrapper script? Is this
    achievable without runtime code (pure markdown skill constraint)?
    Target files: `core/post-publish-hook.md` (lines 83-98, pipeline-completed
    payload), `skills/autopilot/SKILL.md` (lines 373-394, security considerations and
    rules), `state/schema.md` (status enum: `failed` value at line 219).

17. Multi-host distributed lock for Autopilot: the current `mkdir`-based lock
    (`.ceos-agents/autopilot.lock/`) is process-local and documented in
    `skills/autopilot/SKILL.md` lines 350-353 as deferred to v6.9.0. What is the
    minimum-viable alternative that avoids NFS rename-atomicity failure modes?
    Enumerate: (a) shared-FS advisory lockfile with `flock` (Linux-only, not BusyBox),
    (b) tracker-level "lock issue" (portable, already has MCP), (c) simple HTTP
    lock-service (requires infra), (d) defer to v6.9.1 with improved docs on disjoint
    queries. What does the roadmap call the "hardest item" and which option does it
    recommend for the minimum-viable v6.9.0 path?
    Target files: `skills/autopilot/SKILL.md` (lines 350-394, lock section and
    security considerations), `docs/guides/autopilot.md` (lines 215-287, observability
    and multi-host guidance), `docs/plans/roadmap.md` (lines 777-783).

---

### D — NEEDS_CLARIFICATION State

18. How is `NEEDS_DECOMPOSITION` currently integrated end-to-end? In `agents/fixer.md`
    (lines 36-48) fixer outputs `## NEEDS_DECOMPOSITION`. In `skills/fix-ticket/SKILL.md`
    (lines 328-333) the orchestrator detects this string and branches. In `state/schema.md`
    there is a `decomposition` object. Map the exact field names and status values that
    change when NEEDS_DECOMPOSITION fires — this is the template for NEEDS_CLARIFICATION.
    Target files: `agents/fixer.md` (lines 36-48), `skills/fix-ticket/SKILL.md`
    (lines 323-333), `state/schema.md` (lines 123-128, decomposition object).

19. What additive fields in `state/schema.md` would represent a NEEDS_CLARIFICATION
    pause? Proposed shape: `clarification: { status, question, agent, step, run_id,
    answer }`. Confirm `schema_version` stays `"1.0"` (additive fields are
    backward-compatible per note at line 5). What Step Status Enum value covers the
    paused state — is `in_progress` sufficient, or does a new `"awaiting_input"` enum
    value need to be added (which would be a schema contract change requiring
    documentation)?
    Target files: `state/schema.md` (lines 1-10 for additive policy, lines 449-461
    Step Status Enum), `skills/resume-ticket/SKILL.md` (lines 16-32, state file
    detection and resume logic).

20. `skills/resume-ticket/SKILL.md` currently detects resume point by finding the first
    `in_progress` or first `pending` step after all `completed` steps (lines 20-23).
    At what granularity can it resume a NEEDS_CLARIFICATION pause: (a) re-run the
    entire blocked phase from scratch with the answer injected, or (b) continue from
    the exact sub-step within the phase? What is the mechanism for injecting the human
    answer into the resumed agent's context — as a state.json field read by the skill,
    or as a direct argument to the Task dispatch?
    Target files: `skills/resume-ticket/SKILL.md` (lines 13-32, Priority 0 state-file
    detection), `agents/fixer.md` (lines 66-78, reviewer loop — shows how iteration
    context is passed), `agents/triage-analyst.md` (to check if triage has a parallel
    pattern).

21. Which skills dispatch fixer or triage-analyst and must therefore handle the new
    NEEDS_CLARIFICATION output state? Enumerate all dispatch sites. Known sites:
    `skills/fix-ticket/SKILL.md` (fixer + triage-analyst), `skills/fix-bugs/SKILL.md`
    (fixer + triage-analyst), `skills/implement-feature/SKILL.md` (fixer only — no
    triage). Are there any other skills that dispatch these agents (e.g., scaffold,
    resume-ticket)?
    Target files: `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`,
    `skills/implement-feature/SKILL.md`, `skills/resume-ticket/SKILL.md`,
    `skills/scaffold/SKILL.md` (grep for `ceos-agents:fixer` or `ceos-agents:triage`).

---

### E — pipeline-history.md

22. Where should `pipeline-history.md` live? The roadmap (line 808) says
    `.claude/pipeline-history.md`. Is `.claude/` gitignored in typical project setups
    (it contains `settings.local.json` which is gitignored per project memory)? If
    `pipeline-history.md` is in `.claude/`, it may be committed to the project repo
    by default — is that desired? What is the privacy implication of committing issue
    titles and outcomes to a public OSS project that uses ceos-agents?
    Target files: `docs/plans/roadmap.md` (lines 806-810), `state/schema.md`
    (lines 1-18 — `.ceos-agents/` layout, not `.claude/`).

23. What fields should pipeline-history.md include vs exclude for privacy? Issue IDs
    and outcomes (low sensitivity) vs issue titles, code excerpts, block reasons (may
    contain PII or proprietary details). If the plugin itself goes OSS, the history
    file in `tests/mock-project/` or examples could expose real project data. Define
    the minimum metadata set that is useful to fixer/reviewer without including
    potentially sensitive content.
    Target files: `docs/plans/roadmap.md` (lines 806-811), `state/schema.md`
    (block object: `{agent, step, reason, detail, recommendation}` — detail may contain
    source code excerpts).

24. Should `pipeline-history.md` be append-only flat markdown (one H2 section per run)
    or JSONL (one record per line)? Fixer and reviewer are markdown-native agents that
    read via `Read` tool — markdown is easier to consume in-context. JSONL would
    require a parsing step. What is the max history size to keep in context (last N
    runs)? At what pipeline step should the append happen — after `pipeline-completed`
    webhook fires, or as part of the publisher step?
    Target files: `core/post-publish-hook.md` (Section 4, pipeline-completed event —
    natural append point), `agents/fixer.md` (Process step 1 — where history read
    would be inserted), `agents/reviewer.md` (to identify where history context
    would be injected).

---

### F — ARCHITECTURE.md Freshness

25. Does `docs/ARCHITECTURE.md` currently exist in the ceos-agents repo? The scaffolder
    agent generates it for scaffold target projects, not for the plugin repo itself.
    Is the freshness warning for the plugin's own `docs/ARCHITECTURE.md`, or for the
    target project's `docs/ARCHITECTURE.md` (i.e., the one scaffolder generates)?
    Clarify the scope of the warning.
    Target files: `docs/plans/roadmap.md` (lines 812-817), `agents/scaffolder.md`
    (to confirm `docs/ARCHITECTURE.md` is generated in the target project),
    `skills/fix-ticket/SKILL.md` and `skills/implement-feature/SKILL.md` (where the
    warning would be inserted).

26. How should the "N commits" staleness threshold be computed in a bash snippet inside
    a markdown skill? The roadmap proposes `git log --oneline docs/ARCHITECTURE.md |
    wc -l`. An alternative is `git log --oneline -1 docs/ARCHITECTURE.md` to get the
    last-edited commit, then compare its timestamp to HEAD. What is the recommended
    default N? At what step in fix-ticket and implement-feature should the check run
    (before fixer dispatch, after code-analyst)? Is the warning advisory-only (pipeline
    continues) or can it ever block?
    Target files: `docs/plans/roadmap.md` (line 817: "soft warning"),
    `skills/fix-ticket/SKILL.md` (to identify insertion point, post code-analyst),
    `skills/implement-feature/SKILL.md` (same).

---

### Cross-cutting

27. CHANGELOG format conventions: Read the existing v6.8.0 and v6.8.1 entries to
    determine: section heading style (## vs ###), item prefix format (- vs *), presence
    of an "Impact" line, whether test counts are stated, and how multi-item releases
    are organized. The v6.9.0 entry must match exactly — including whether OSS Readiness
    items go into a separate subsection or are mixed with features.
    Target files: `CHANGELOG.md` (v6.8.1 and v6.8.0 entries — last two major entries).

28. Enumerate every file that currently states a count that will become stale if
    agents, skills, or optional config sections are added in v6.9.0. Known locations:
    `CLAUDE.md` (21 agents, 29 skills, 15 core contracts, 18 optional sections, 8
    templates), `README.md` (same counts implied), `docs/reference/skills.md`,
    `docs/reference/agents.md`. Will NEEDS_CLARIFICATION state or pipeline-history.md
    additions change any count (new core contracts, new state fields, new sections)?
    Target files: `CLAUDE.md` (counts in "## Repository Structure" and
    "## Config Contract"), `README.md`, `docs/reference/skills.md`,
    `docs/reference/agents.md`.

29. Prompt injection protection coverage: agents with `NEVER follow instructions...
    EXTERNAL INPUT` constraint: fixer, reviewer, code-analyst, triage-analyst,
    spec-analyst, architect, reproducer, browser-verifier, acceptance-gate,
    priority-engine (10 agents confirmed). Agents WITHOUT this constraint: test-
    engineer, e2e-test-engineer, publisher, rollback-agent, scaffolder, stack-selector,
    spec-writer, spec-reviewer, deployment-verifier, backlog-creator, sprint-planner
    (11 agents). Of these 11, which ones receive issue tracker content as input (making
    them injection-vulnerable)? Should the constraint be added to test-engineer and
    e2e-test-engineer (they read test output which may originate from issue content
    under Autopilot `--dangerously-skip-permissions`)?
    Target files: `agents/test-engineer.md`, `agents/e2e-test-engineer.md`,
    `agents/publisher.md`, `agents/scaffolder.md` (to check Process step inputs),
    `skills/autopilot/SKILL.md` (lines 373-384, security considerations — explicitly
    flags poisoned issue content risk).

---

## Notes

### Security/compliance gaps found during audit vs draft question set

**Under-indexed areas in the draft (security lens):**

1. **Internal hostname exposure in user-facing docs** — the draft Q2 only asks about
   `plugin.json.repository`. The internal hostname `gitea.internal.ceosdata.com`
   appears in `docs/guides/installation.md` (lines 15-36), `skills/onboard/SKILL.md`
   (line 102), and indirectly in examples. A public OSS repo containing these strings
   will break every install attempt for external users AND discloses an internal
   infrastructure name. This is Q3 above and is a HIGH-PRIORITY OSS blocker not
   covered in the original draft.

2. **Prompt injection protection gap (Q29)** — 11 of 21 agents lack the
   `EXTERNAL INPUT` constraint. Under Autopilot with
   `--dangerously-skip-permissions`, poisoned issue content flows to test-engineer
   and e2e-test-engineer, which run bash commands. This is a concrete security risk
   documented in `skills/autopilot/SKILL.md` lines 373-384 but not covered in the
   draft questions.

3. **pipeline-history.md PII/privacy (Q22-23)** — the draft Q23 covers this, but
   the original framing is too narrow. The key risk is committing `block.detail`
   (which can contain source code excerpts or stack traces with PII) to a public
   repo. The question needs to explicitly scope the minimum metadata set.

4. **`outcome:failed` mechanism feasibility (Q16)** — the draft correctly identifies
   this but does not ask whether it is achievable given the pure-markdown constraint.
   A bash `trap EXIT` only works if the skill's bash snippet runs in a shell that
   survives the parent process death — under `claude -p`, this is not guaranteed.

**Over-indexed areas in the draft:**

- Q10 (jq -nc vs jq -n) is genuinely minor; no documented byte-equality parsing
  contract exists in any consumer-facing doc. I have preserved the question but
  narrowed it to confirm absence of such a contract rather than treating it as a
  blocking concern.

- Q12 (REPO_ROOT path bug) is moot for the current repo state since the
  `.forge/phase-5-tdd/` directory doesn't exist yet. The question is reframed to
  clarify it is a TDD phase concern, not a current codebase bug.

**MINOR contract preservation risks:**

- Adding `awaiting_input` to the Step Status Enum (D-19) would be a new enum value
  that schema consumers must handle — this is additive (MINOR-safe) only if
  existing code gracefully ignores unknown status strings. The question flags this.
- The `--format json` flag on metrics (C-14) adds a new output mode — confirm no
  existing test asserts on the exact current output format without gating on absence
  of `--format json`.

**OSS exposure summary:**
The highest-risk OSS go-live blocker is NOT the license SPDX string — it is the
internal hostname `gitea.internal.ceosdata.com` embedded in user-facing installation
documentation. A user cloning from a public mirror and following `installation.md`
will be directed to an unreachable internal host. This must be fixed (Q3, Q7) before
any public announcement.
