# Phase 1 Research Questions — Agent 3 (Integration/BC lens)

## Self-score: 0.94
My confidence the question set is complete and well-targeted. Deduction: REPO_ROOT path bug lives in `.forge.bak-*/` files (not currently in the repo), so the exact fix surface is slightly unclear from current HEAD. All other questions are grep-verified against actual file state.

## Categories covered: A, B, C, D, E, F, cross-cutting

---

## Questions

### A — OSS Readiness

**1. What SPDX license identifier should replace "UNLICENSED" in plugin.json, and is the field format the same in marketplace.json?**
Verified: `.claude-plugin/plugin.json` has `"license": "UNLICENSED"`. `.claude-plugin/marketplace.json` has no `license` field at all — unclear if it needs one or mirrors from plugin.json. The sister plugin `filip-superpowers` uses `"license": "MIT"`. Candidate OSI licenses: MIT (used by filip-superpowers, simplest), Apache-2.0 (patent grant, common for tooling), BSD-3-Clause (minimal, restrictive on endorsement). Research must confirm whether marketplace.json needs a license field added.
Target files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `/c/gitea_filip-superpowers/.claude-plugin/plugin.json` (reference)

**2. Has a public mirror (GitHub or public Gitea) been provisioned for the repository?**
`plugin.json.repository` currently points to `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git`. The roadmap says "update to public mirror once the repo is mirrored." If no public URL exists yet, the repository URL update must defer. This is a blocker gate: no URL = this sub-item defers to v6.9.1.
Target files: `docs/plans/roadmap.md` lines 756-757, `.claude-plugin/plugin.json`

**3. What minimum content is required for SECURITY.md, and what is the vulnerability reporting contact?**
None of `LICENSE`, `SECURITY.md`, or `CODE_OF_CONDUCT.md` exist yet in the repo root (confirmed by filesystem check). CONTRIBUTING.md line 97-108 has a generic "Reporting Issues" section but no vulnerability-specific channel or SLA. SECURITY.md must add: reporting channel (email or GitHub security advisory), response SLA, and supported versions. The author email `filip.sabacky@ceosdata.com` is the only known contact.
Target files: `CONTRIBUTING.md` (lines 97-108), `docs/plans/roadmap.md` lines 755-756

**4. Does the existing CONTRIBUTING.md Code of Conduct section (lines 103-108) conflict with or duplicate the planned CODE_OF_CONDUCT.md?**
CONTRIBUTING.md lines 103-108 contain a 4-bullet informal code of conduct ("Be respectful", "Focus on technical merit", etc.). Contributor Covenant 2.1 is the planned choice. The new CODE_OF_CONDUCT.md will be more comprehensive. The CONTRIBUTING.md section must either link to the new file or be replaced — leaving both creates contradictory/duplicated governance. This is a BC integration concern for external contributors.
Target files: `CONTRIBUTING.md` (lines 103-108), `docs/plans/roadmap.md` line 757

**5. Where do .gitea and .github issue/PR templates live, and what templates already exist?**
`.gitea/` exists in the repo (contains only `workflows/`) and `.github/` does NOT exist. Template paths differ: Gitea uses `.gitea/issue_template/` (directory) and `.gitea/pull_request_template.md` (file); GitHub uses `.github/ISSUE_TEMPLATE/` and `.github/PULL_REQUEST_TEMPLATE.md`. Since the current hosting is Gitea (internal), Gitea templates are primary. Should .github templates also be created as forward-compatibility for the public GitHub mirror? This determines whether 2 or 4 new template files are needed.
Target files: `.gitea/` (current contents), `docs/plans/roadmap.md` line 758, `CONTRIBUTING.md` (lines 97-100 — issues section)

**6. Does README.md "Author & License" section (line 280-282) need updating after license change?**
README.md line 282 currently reads: "See `plugin.json` for license details." Once LICENSE is added and `plugin.json.license` is set, this section should cite the license by name (e.g., "MIT License") and link to the LICENSE file. Also, the docs/ARCHITECTURE.md Mermaid diagram (line ~50) still says "28 Skills" — a stale count from before v6.8.0. If any agent/skill/section count changes in v6.9.0, ALL files with embedded counts need simultaneous updates.
Target files: `README.md` (lines 280-282, line ~260-261), `docs/ARCHITECTURE.md` (Mermaid diagram skill count)

---

### B — v6.8.1 Polish

**7. What is the exact count of curl invocations missing --proto in fix-ticket, fix-bugs, and implement-feature, and what line numbers need patching?**
Verified by grep: fix-ticket has 2 curl calls (lines 106, 183), fix-bugs has 13 curl calls (lines 119, 190, 236, 368, 429, 479, 511, 545, 573, 614, 651, 680, 741), implement-feature has 3 curl calls (lines 108, 221, 535). None have `--proto "=http,https"`. The contract file `core/post-publish-hook.md` already has `--proto` in both Section 3 (line 18) and Section 4 (line 120). Total missing: 18 sites. Each skill-level example must add `--proto "=http,https"` between the opening `curl` and `--max-time`.
Target files: `skills/fix-ticket/SKILL.md` (lines 106, 183), `skills/fix-bugs/SKILL.md` (lines 119, 190, 236, 368, 429, 479, 511, 545, 573, 614, 651, 680, 741), `skills/implement-feature/SKILL.md` (lines 108, 221, 535)

**8. Does tests/scenarios/v681-harness-exit-propagation.sh need a trap for temp file cleanup, and what is the canonical trap form used elsewhere?**
The scenario creates `$TMPSCEN` at line 80 (`REPO_ROOT/tests/scenarios/$TMPNAME.sh`) and removes it at line 86 with `rm -f "$TMPSCEN"`. But no `trap 'rm -f "$TMPSCEN"' EXIT INT TERM` is registered — if the test is killed mid-run (Ctrl-C), the temp file leaks. The canonical trap form used in `tests/scenarios/autopilot-trap-cleanup.sh` and the autopilot SKILL.md is `trap '...' EXIT` (EXIT-only). The fix must add the trap AFTER `TMPSCEN` is defined (not before). Is EXIT alone sufficient, or should INT TERM be included? The roadmap says "EXIT INT TERM" — verify whether test runners use SIGTERM.
Target files: `tests/scenarios/v681-harness-exit-propagation.sh` (lines 72-86), `tests/scenarios/autopilot-trap-cleanup.sh` (trap form reference)

**9. Should webhook JSON payloads in skill examples use jq -nc (compact) or jq -n (multi-line), and does any downstream consumer document byte-equality parsing?**
`core/block-handler.md` Step 5 uses `jq -n` (multi-line). `core/post-publish-hook.md` Section 4 uses heredoc inline JSON (single-line literals). The roadmap calls out "jq -nc compact vs pretty-print" as a concern — downstream consumers parsing byte-equality may break on multi-line output. No consumer-facing contract document mentions byte-equality. Research must determine: (a) whether the fix should be `jq -nc` in block-handler (adding `-c` flag), (b) whether this changes the WEBHOOK-R8 backward-compat guarantee (CLAUDE.md says "additive fields... Consumers MUST use lenient JSON parsing"), (c) whether any test scenario asserts exact byte-level output shape.
Target files: `core/block-handler.md` (lines 41-55), `core/post-publish-hook.md` (lines 17-22, 100-126), `CLAUDE.md` (webhook payload BC section)

**10. What is the exact current issue_id regex across all four skills, and which character(s) must be added to support Jira dotted-project keys (e.g., PROJ.NAME-123)?**
All four skills (fix-ticket line 90, fix-bugs line 95, implement-feature line 92, resume-ticket line 86) have `^[A-Za-z0-9#_-]+$`. Jira dotted-project keys like `PROJ.NAME-123` require `.` (dot) to be added. Decision point: add `.` to the regex, OR document the restriction in skill prose and reject with a clear error message. Adding `.` to the allowlist is safe (dots cannot enable path traversal since the path uses the ID as a single segment, not parsed as directories — `PROJ.NAME-123` maps to `.ceos-agents/PROJ.NAME-123/state.json`). However, check: does dot in the ID break any downstream usage (run_id format, decomposition YAML filename)?
Target files: `skills/fix-ticket/SKILL.md` (line 90), `skills/fix-bugs/SKILL.md` (line 95), `skills/implement-feature/SKILL.md` (line 92), `skills/resume-ticket/SKILL.md` (line 86), `skills/autopilot/SKILL.md` (if regex present there too)

**11. Where exactly is the REPO_ROOT path bug in .forge/phase-5-tdd/tests-hidden/*.sh, and is the fix symptomatic (patch the files) or root-cause (fix the generator)?**
Hidden tests in `.forge.bak-20260419T184209Z/phase-5-tdd/tests-hidden/` all use `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"` — but files living in `.forge/phase-5-tdd/tests-hidden/` are 3 directory levels deep from repo root (`.forge/` → `phase-5-tdd/` → `tests-hidden/`), requiring `../../../`. The current `.forge/` directory contains no `phase-5-tdd/` (only `phase-0-meta/` and `phase-1-research/`). If these tests will be placed in `.forge/phase-5-tdd/tests-hidden/` during v6.9.0 TDD phase, the generator that produces them (likely the forge pipeline) must emit `../../../`. Is the generator a skill, a core contract, or a phase template? Check the most recent forge bak to identify where TDD hidden test templates originate.
Target files: `.forge.bak-20260419T184209Z/phase-5-tdd/tests-hidden/*.sh` (REPO_ROOT line), forge TDD phase template if one exists

**12. What exactly is the AC-ITEM-3.2 false-positive in core/block-handler.md, and what is the scoping solution?**
`core/block-handler.md` line 59 (the prose explaining why `${var:1:-1}` is NOT needed) mentions `${var:1:-1}` as a counter-example in running prose — not inside a fenced code block. If any automated test (scenario) checks that `${var:1:-1}` is ABSENT from `core/block-handler.md` using a simple grep, it will false-positive on the prose line. The fix options are: (a) move the counter-example into a fenced code block (grep-scoping in tests should then exclude fenced blocks), (b) rephrase the prose to avoid the literal string `${var:1:-1}`, (c) change the test to exclude fenced code blocks. What test currently performs this check? Is it a hidden test or a public scenario?
Target files: `core/block-handler.md` (lines 55-68), `tests/scenarios/` (search for any test that greps block-handler for this pattern), `.forge.bak-20260419T184209Z/phase-5-tdd/tests-hidden/h-block-handler-heredoc.sh`

---

### C — v6.8.0 Additions

**13. What JSON schema should --format json produce for /ceos-agents:metrics, and does docs/reference/skills.md already document the flag?**
Confirmed: `docs/reference/skills.md` line 562 already documents `--format <md|json>` for `/ceos-agents:metrics`, but `skills/metrics/SKILL.md` line 101 says "Output format is always markdown" and the frontmatter `argument-hint` does NOT include `--format`. This is a documentation-vs-implementation gap from v6.8.0. The JSON output must be a machine-readable mirror of the markdown report. Existing human output structure (Step 7 in SKILL.md) covers: pipeline overview table, per-pipeline token breakdown, period summary table, block analysis table, agent effectiveness table. What is the JSON key naming convention? Should the JSON include provenance fields (measured vs estimated)? The SKILL.md frontmatter `argument-hint` must also be updated.
Target files: `skills/metrics/SKILL.md` (lines 1-12, 99-176), `docs/reference/skills.md` (lines 555-575)

**14. Where exactly in the fix-ticket, fix-bugs, and implement-feature dispatch loops should outcome:failed fire for catastrophic exits?**
`core/post-publish-hook.md` line 85 defines `outcome` as one of: `success`, `blocked`, `failed`. `skills/fix-ticket/SKILL.md` line 508 fires `outcome: "success"` and line 542 fires `outcome: "blocked"` — but `outcome: "failed"` has no documented fire path. The roadmap notes this as "documented in spec but no implementation path." Catastrophic exits (OOM, SIGKILL, uncaught error) in a bash pipeline context cannot be trapped uniformly — they leave no clean shutdown hook. The fire path requires: (a) a bash `trap ERR` or `trap EXIT` that detects pipeline.status != completed/blocked and fires `outcome: "failed"`, OR (b) documenting that `failed` only fires on non-zero exit from the skill's bash block. Which approach is compatible with the `pipeline-completed` WEBHOOK-R4 ordering rule (fire AFTER terminal state committed)?
Target files: `skills/fix-ticket/SKILL.md` (lines 504-545), `skills/fix-bugs/SKILL.md` (lines 680-690), `skills/implement-feature/SKILL.md` (outcome fire path), `core/post-publish-hook.md` (lines 82-100, WEBHOOK-R4)

**15. What is the minimum-viable circuit breaker design for webhook delivery, and should state persist across pipeline runs?**
`core/post-publish-hook.md` currently has advisory-failure semantics: `[WARN] Webhook delivery failed: {error}` and continue. The roadmap adds a circuit breaker for "slow/hung webhooks." The current curl has `--max-time 5 --retry 0` — so timeouts are already bounded at 5s. What additional behavior is a circuit breaker supposed to provide? Options: (a) fail-open with backoff after N consecutive failures (in-memory only — resets per pipeline run), (b) persistent failure count in `.ceos-agents/circuit-breaker.json` (survives pipeline restarts), (c) skip webhook firing for the remainder of a pipeline run after 1 failure. Option (b) requires atomic write protocol (same as state.json). Confirm: does the circuit breaker apply to all 5 webhook event types equally, or only to slow (timeout) failures vs connection refused?
Target files: `core/post-publish-hook.md` (lines 29-33, 100-126), `core/state-manager.md` (atomic write protocol reference)

**16. What is the minimum-viable multi-host distributed lock design for Autopilot, and what is the confirmed defer-to-v6.9.1 fallback?**
`skills/autopilot/SKILL.md` lines 30 and 121-225 document the current mkdir-based process-local lock at `.ceos-agents/autopilot.lock/`. The roadmap calls multi-host lock "hardest item" and the current workaround is "disjoint queries across hosts." For v6.9.0, the viable options are: (a) simple flat-file lock with stronger primitive (flock via lockfile-progs), (b) etcd/consul advisory lock (requires external infra), (c) advisory lock service (custom HTTP), (d) document the disjoint-query pattern explicitly as the v6.9.0 recommendation and defer locking to v6.9.1. Option (d) requires only adding documentation (operators guide). What prose must change in `skills/autopilot/SKILL.md` and `docs/guides/autopilot.md` to formalize the multi-host workaround?
Target files: `skills/autopilot/SKILL.md` (lines 28-35, 99-230), `docs/guides/autopilot.md` (multi-host section)

---

### D — NEEDS_CLARIFICATION State

**17. How is NEEDS_DECOMPOSITION currently handled across the three dispatch sites, and which exact code paths must be mirrored for NEEDS_CLARIFICATION?**
Confirmed integration sites for NEEDS_DECOMPOSITION: (a) `skills/fix-ticket/SKILL.md` line 328 (revert + re-decompose, max 1), (b) `skills/fix-bugs/SKILL.md` line 396 (revert + re-decompose per-bug, max 1), (c) `skills/implement-feature/SKILL.md` lines 359-361 (block in decomposition mode, or block issue in single-pass). `core/fixer-reviewer-loop.md` line 21 also intercepts it. For NEEDS_CLARIFICATION: fixer + triage-analyst are the two agents, dispatched by fix-ticket, fix-bugs, analyze-bug, and implement-feature. Each dispatch site must check for the new signal before proceeding to the next step. What is the exact pause mechanism? Can the pipeline write to state.json with a "clarification_pending" status and await user input via resume-ticket, or must it block-and-wait synchronously?
Target files: `skills/fix-ticket/SKILL.md` (lines 325-340), `skills/fix-bugs/SKILL.md` (lines 180-210, 393-410), `skills/analyze-bug/SKILL.md` (lines 24-35), `skills/implement-feature/SKILL.md` (lines 345-365), `core/fixer-reviewer-loop.md` (lines 18-44)

**18. What is the exact additive JSON shape for NEEDS_CLARIFICATION in state.json, and which Step Status Enum value does it use?**
`state/schema.md` Step Status Enum (lines 449-461) currently has: `pending`, `in_progress`, `completed`, `failed`, `skipped`, `blocked`, `not_applicable`. NEEDS_CLARIFICATION requires a new status — either a new enum value (`awaiting_clarification`) or reuse of `blocked` with a sub-type field. Adding a new enum value is a MINOR-compatible additive change. The clarification request object must contain at minimum: `{question, agent, step, run_id}`. Where in the state.json does this object live? Top-level `clarification` field (parallel to `block`) or per-stage? The `status` field for triage or fixer_reviewer would need to be set to the new value, which downstream consumers that read `status` must handle gracefully.
Target files: `state/schema.md` (lines 449-461, top-level field definitions), `core/state-manager.md` (additive field guidance)

**19. How does resume-ticket currently resume from a state, and what new path must it add to inject a clarification answer?**
`skills/resume-ticket/SKILL.md` (Priority 0: State File Detection) reads `state.json`, finds the first `in_progress` or `pending` step after all `completed` steps, and restores context. For NEEDS_CLARIFICATION, the user provides the answer as an argument to `/ceos-agents:resume-ticket {ISSUE-ID} --clarification "answer text"`. Resume-ticket must: (a) detect `status: "awaiting_clarification"` in the appropriate stage, (b) read the stored clarification question from the `clarification` object, (c) inject the answer into the agent's context when re-dispatching. The Heuristic Detection table (lines 37-58) has no NEEDS_CLARIFICATION checkpoint — it must be added with a detection signal (e.g., presence of `clarification` object in state.json with `status: "awaiting_clarification"`). What priority does CLARIFICATION_PENDING get relative to DECOMPOSE_PARTIAL?
Target files: `skills/resume-ticket/SKILL.md` (lines 15-100), `state/schema.md`

**20. Which skills dispatch both fixer AND triage-analyst, and are there any dispatch sites missed by the 3 primary skills?**
Confirmed dispatch sites: fixer dispatched by fix-ticket (line 325), fix-bugs (line 393), implement-feature (line 347), scaffold (line 778). Triage-analyst dispatched by fix-ticket (line 161), fix-bugs (line 180), analyze-bug (line 24). Scaffold dispatches fixer but NOT triage-analyst. analyze-bug dispatches triage-analyst but NOT fixer. Each dispatch site for either agent needs NEEDS_CLARIFICATION signal handling. The draft questions (D category) only mention fix-ticket, fix-bugs, implement-feature, and resume-ticket — this misses analyze-bug (triage-analyst dispatch) and scaffold (fixer dispatch). Confirm: does scaffold need NEEDS_CLARIFICATION handling, given it uses fixer for subtask implementation?
Target files: `skills/analyze-bug/SKILL.md` (lines 24-35), `skills/scaffold/SKILL.md` (lines 773-800)

---

### E — pipeline-history.md Feedback Loop

**21. Should pipeline-history.md be append-only markdown or JSONL, and where exactly should it be stored?**
Roadmap (lines 808-809) proposes `.claude/pipeline-history.md` (append-only markdown, one section per run). `state/schema.md` uses JSONL for `pipeline.log`. Markdown is more readable in-context for agents. The key BC concern: if stored in `.claude/` it is outside the plugin's `.ceos-agents/` convention and may interact with Claude Code's own `.claude/` directory structure. Does `.claude/pipeline-history.md` conflict with any Claude Code reserved files? Alternative: `.ceos-agents/pipeline-history.md` (global, not per-run). What format (section headers, fields) gives fixer and reviewer enough signal in 5-10 recent entries without exceeding context budget?
Target files: `docs/plans/roadmap.md` (lines 806-811), `state/schema.md` (pipeline.log JSONL format as format reference)

**22. At what step in fixer.md and reviewer.md should pipeline-history.md be loaded, and what is the context injection mechanism?**
`agents/fixer.md` Step 1 reads triage analysis and impact report. `agents/reviewer.md` Step 1 reads fix implementation. Pipeline-history.md would be most useful at Step 1 for fixer (patterns from past failed fixes in same module) and Step 1 for reviewer (patterns from past review cycles). The injection mechanism in a Task-tool dispatch is the `context` string passed to the agent — history is prepended. BC concern: adding history to context increases token consumption per fixer/reviewer invocation. Does this interact with the `fixer_reviewer.tokens_used` accumulator in a way that distorts `/metrics` estimates? Should history loading be controlled by a new optional Automation Config key (opt-in)?
Target files: `agents/fixer.md` (Step 1, lines 20-23), `agents/reviewer.md` (Step 1), `skills/fix-ticket/SKILL.md` (pre-dispatch fixer context), `skills/metrics/SKILL.md` (token heuristics)

**23. What is the write point for pipeline-history.md appends, and does it go into post-publish-hook or into the skill directly?**
`core/post-publish-hook.md` is the canonical place for end-of-pipeline writes (post-publish hook, webhook fire). An append to `pipeline-history.md` at pipeline end (success OR block) fits naturally into `post-publish-hook.md` as a new Section 5, or into each skill's terminal step. BC concern: if appended in `post-publish-hook.md`, all 4 pipeline skills (fix-ticket, fix-bugs, implement-feature, scaffold) would inherit the behavior automatically. But fix-bugs runs per-issue in a loop — should each bug fix in the loop get its own history entry? The append must use an atomic write pattern to avoid corruption when two pipeline runs complete simultaneously. Does the existing atomic write protocol (tmp + rename) work for append-only files?
Target files: `core/post-publish-hook.md` (Section 4 end, ~line 150), `skills/fix-bugs/SKILL.md` (per-bug loop structure), `core/state-manager.md` (atomic write protocol — does it cover append?)

---

### F — ARCHITECTURE.md Freshness Warning

**24. Does docs/ARCHITECTURE.md currently appear in fix-ticket or implement-feature, and what git command detects "older than N commits"?**
Confirmed: `docs/ARCHITECTURE.md` exists (not missing). Neither `skills/fix-ticket/SKILL.md` nor `skills/implement-feature/SKILL.md` references it currently. The scaffolder generates it (agents/scaffolder.md line 116, skills/scaffold/SKILL.md line 526). The docs/ARCHITECTURE.md Mermaid diagram still says "28 Skills" (stale since v6.8.0 added the 29th). Roadmap proposed check: `git log --oneline docs/ARCHITECTURE.md | wc -l` (counts commits since last edit). But a count of commits on the file is not "older than N commits since last ARCHITECTURE.md change" — the correct check is `git rev-list HEAD...$(git log -1 --format="%H" -- docs/ARCHITECTURE.md) --count` (commits since last edit). What is the default N? Roadmap is silent. The warning must be advisory-only and never block.
Target files: `skills/fix-ticket/SKILL.md` (insertion point), `skills/implement-feature/SKILL.md` (insertion point), `docs/ARCHITECTURE.md` (Mermaid skill count — also a doc drift item), `docs/plans/roadmap.md` (lines 812-817)

**25. Is the ARCHITECTURE.md freshness warning advisory-only, and how is it surfaced to the user without interrupting the pipeline?**
Roadmap line 817: "soft warning." The warning should print to the pipeline log/output at the START of fix-ticket/implement-feature (after MCP pre-flight, before triage dispatch), so the operator sees it without pipeline blocking. BC impact: the warning adds a `git log` bash call at pipeline start — this is always safe (read-only git command). Does it interact with `--dry-run` flag? In dry-run mode, the warning should still fire. Should the warning also appear in the `pipeline-completed` webhook payload? If yes, the payload schema (MINOR additive) would need a new optional `warnings` array field.
Target files: `skills/fix-ticket/SKILL.md` (Step 1 or Step 2 — before triage dispatch), `skills/implement-feature/SKILL.md` (same insertion area), `core/post-publish-hook.md` (pipeline-completed payload — if warnings field added)

---

### Cross-Cutting

**26. Which files contain hardcoded counts (agents, skills, core contracts, optional sections, templates) that will drift if v6.9.0 adds any new agent or skill?**
Confirmed count locations:
- `CLAUDE.md` lines 17-18 ("21 agent definitions", "29 skills"), line 159 ("18 optional config sections")
- `README.md` lines 260-261 ("All 29 skills", "All 21 agents"), line 219 ("18 optional sections")
- `docs/reference/automation-config.md` line 9 ("5 required sections and 18 optional sections")
- `docs/reference/skills.md` line 3 ("all 29 skills in the ceos-agents plugin")
- `docs/ARCHITECTURE.md` Mermaid diagram (currently shows "28 Skills" — ALREADY STALE from v6.8.0!)
If NEEDS_CLARIFICATION is implemented as a new fixer/triage output state (no new agent, no new skill), counts stay stable. But pipeline-history.md might add a new core contract. Phase 9 doc audit must check all 6 locations simultaneously before committing.
Target files: `CLAUDE.md` (lines 17-18, 159), `README.md` (lines 219, 260-261), `docs/reference/automation-config.md` (line 9), `docs/reference/skills.md` (line 3), `docs/ARCHITECTURE.md` (Mermaid diagram)

**27. What is the exact CHANGELOG format (v6.8.1 and v6.8.0 entries) that v6.9.0 must follow?**
Confirmed format from reading CHANGELOG.md:
- Header: `## [X.Y.Z] — YYYY-MM-DD`
- Sub-header: `**MINOR/PATCH** — {theme description}`
- Sections: `### Added`, `### Changed`, `### Fixed`, `### Internal`
- Each item: `**{affected file(s)}** — {what changed}. {Closes/See reference}.`
- v6.8.0 also has `### Migration notes` and `### Known Issues` — appropriate when BC impact or deferrals exist
- v6.9.0 is MINOR; it will likely need `### Migration notes` for OSS readiness (license change) and `### Added` for new files (LICENSE, SECURITY.md, CODE_OF_CONDUCT.md, templates)
- No Impact line observed in the current v6.8.x format — the "Impact:" field seen in roadmap entries is for roadmap only, not CHANGELOG.
Target files: `CHANGELOG.md` (lines 10-63 for v6.8.1 + v6.8.0 entries)

**28. Does the NEEDS_CLARIFICATION state propagate to any webhook payload, and if so, is that a MINOR-backward-compatible additive field?**
`core/post-publish-hook.md` WEBHOOK-R8 states: "Existing events are unchanged. No existing payload field has been renamed. Webhook payloads are forward-compatible — additive fields may be added in future MINOR versions." If NEEDS_CLARIFICATION causes a new pipeline outcome (pipeline pauses mid-run, not completed or blocked), the `pipeline-completed` event would NOT fire until the pipeline resumes and completes. This means no webhook payload change is needed for the pause itself. But if `pipeline-completed` with `outcome: "blocked"` fires when NEEDS_CLARIFICATION is raised, consumers may misinterpret it. A new `outcome: "clarification_pending"` value for `pipeline-completed` would be additive and backward-compatible (consumers ignore unknown values per WEBHOOK-R8 lenient parsing). Research must confirm: should clarification-pause fire `pipeline-completed` or not?
Target files: `core/post-publish-hook.md` (lines 82-100, 147-150 WEBHOOK-R8), `CLAUDE.md` (webhook payload BC section), `docs/reference/skills.md` (resume-ticket docs)

**29. Does the docs/reference/skills.md already-documented --format json flag for /metrics create a contract obligation for v6.9.0, or is it currently an aspirational doc?**
`docs/reference/skills.md` line 562 explicitly documents `/ceos-agents:metrics [--period <N>] [--output <path>] [--format <md|json>]` with `--format <md|json>` as a current flag. But `skills/metrics/SKILL.md` does NOT implement it — line 101 says "Output format is always markdown" and the frontmatter `argument-hint` is `"[--period <N>] [--output <path>]"` (no `--format`). This is an existing spec-impl gap. If a user runs `/ceos-agents:metrics --format json`, the skill currently ignores the flag (markdown output). This means the reference docs create a user-facing promise that must be honored in v6.9.0. The JSON schema for the output must be specified in Phase 4 as EARS requirements. Research must confirm: was `--format json` added to the reference docs prematurely, or has it always been there as aspirational documentation?
Target files: `docs/reference/skills.md` (lines 555-575), `skills/metrics/SKILL.md` (lines 1-12, 99-105), CHANGELOG.md (search for --format json in past entries)

---

## Notes

### Cross-cutting integration sites missed by the draft

The draft 30 questions cover the main landscape but miss several BC-critical cross-cutting sites I identified during the audit:

1. **analyze-bug as a triage-analyst dispatch site**: The draft (Q21 in category D) only enumerates fix-ticket, fix-bugs, implement-feature for NEEDS_CLARIFICATION. `skills/analyze-bug/SKILL.md` also dispatches triage-analyst and must handle the new signal. Added as Q20.

2. **scaffold as a fixer dispatch site**: `skills/scaffold/SKILL.md` dispatches fixer in its implementation phases (line 778). If NEEDS_CLARIFICATION is added to fixer, scaffold must also handle it. Added to Q20.

3. **docs/ARCHITECTURE.md is ALREADY stale (28 Skills in Mermaid)**: The Mermaid diagram says "28 Skills" but v6.8.0 added the 29th. This is an existing doc drift issue that Phase 9 must fix regardless of v6.9.0 scope. Added to Q24 and Q26.

4. **docs/reference/skills.md already documents --format json for /metrics**: This creates a pre-existing user-facing contract obligation, not just a deferred feature. Phase 4 must treat this as a BC requirement, not a new addition. Added as Q29.

5. **WEBHOOK-R8 and NEEDS_CLARIFICATION interaction**: If the pipeline pauses for NEEDS_CLARIFICATION, the `pipeline-completed` webhook may not fire (pipeline is neither completed nor blocked). This interaction is not covered in the draft. Added as Q28.

6. **CONTRIBUTING.md Code of Conduct duplication risk**: The draft (Q4 area) noted CODE_OF_CONDUCT.md is new, but didn't surface the specific integration conflict with CONTRIBUTING.md lines 103-108. Added as Q4.

7. **marketplace.json lacks license field**: plugin.json has `license: "UNLICENSED"` but marketplace.json has no license field at all. The draft Q6 asks about SPDX format; this question (Q1) specifically asks whether marketplace.json needs to be updated at all.

### Confirmed BC invariants for MINOR release

From the integration lens:
- State schema_version must remain "1.0" — all new fields are additive (NEEDS_CLARIFICATION object, pipeline-history.md path)
- No Automation Config required keys can be added — any new keys (e.g., pipeline-history path) must be optional with defaults
- Webhook payload BC: `pipeline-completed.outcome` can get `"clarification_pending"` as an additive new value (consumers use lenient parsing), OR the event simply does not fire on pause
- The 18 curl sites missing `--proto` are a documentation fix, not a contract change — no schema_version impact
- `--format json` for /metrics changes the SKILL.md contract but not the Automation Config contract — MINOR-safe
