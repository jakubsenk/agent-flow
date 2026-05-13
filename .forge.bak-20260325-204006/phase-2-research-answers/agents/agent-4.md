# Research Answer 4: Pipeline State Trace

## fix-ticket Step-by-Step State Trace

Sources: `commands/fix-ticket.md`, `agents/triage-analyst.md`, `agents/reproducer.md`, `agents/browser-verifier.md`, `agents/rollback-agent.md`

| Step | Description | State Produced | Persisted To | Lost on Session End? |
|------|-------------|----------------|--------------|---------------------|
| 0 (MCP pre-flight) | Verify MCP tool availability for configured tracker type | Error message if unavailable | Nowhere | N/A — guard only |
| 0 (Dry-run check) | Parse --dry-run flag; if set, run only steps 1/3/4 | In-memory flag: `dry_run = true/false` | Nowhere | Yes — flag state is in-session only |
| Config read | Read Automation Config from CLAUDE.md | In-memory: retry limits, hooks, custom agents, browser verification flags, decomposition params, error handling, extra labels, agent overrides path | Nowhere | Yes — full config re-read each run |
| 1 (Set issue state) | Set state per `On start set` in Automation Config | Issue tracker state change | Issue tracker (external) | No — external system holds it |
| 2 (Create branch) | `git checkout -b {branch_naming} {base_branch}` | Git branch | Git local + remote | No — branch persists in git |
| 3 (Triage) | Run `ceos-agents:triage-analyst`. Validates clarity, checks duplicates, assesses severity, extracts AC (2-5 items), estimates complexity (XS/S/M/L), extracts browser reproduction steps (UI bugs only) | In-memory: `acceptance_criteria` list, `complexity`, `severity`, `area`, `reproduction_steps`. External: triage checkpoint comment `[ceos-agents] Triage completed. Severity: {s}. Area: {a}. Complexity: {c}. AC: {n}.` | Issue tracker comment (checkpoint only — NOT full AC list) | Yes — the full `acceptance_criteria` list and `complexity` value exist only in-session. The comment records counts only, not values. |
| 3 (Triage — duplicate/unclear) | If duplicate or unclear → Block handler (step X) | Block comment on issue tracker | Issue tracker | No — comment persists |
| 4 (Code-analyst) | Run `ceos-agents:code-analyst`. Produces impact report: affected files, risk level, estimated diff lines, independent_changes count | In-memory: `risk`, `affected_files`, `estimated_diff_lines`, `independent_changes` | Nowhere | Yes — entire impact report is lost on session end |
| 4a (Decompose flag parsing) | Parse --decompose / --no-decompose from $ARGUMENTS | In-memory: `decompose_mode = FORCE / DISABLED / AUTO` | Nowhere | Yes |
| 4b (Decomposition decision) | Evaluate code-analyst output against thresholds (risk==HIGH, affected_files>=4, estimated_diff_lines>60 AND affected_files>=3, independent_changes>=2) | Decision: DECOMPOSE or SINGLE_PASS | Nowhere | Yes — decision re-derived from in-memory code-analyst output |
| 4b (Architect — decomposition) | If DECOMPOSE: run architect (opus). Produces task tree YAML with subtasks, depends_on links, maps_to AC references | Task tree YAML file | `.claude/decomposition/{ISSUE-ID}.yaml` | No — file persists across session boundary |
| 4b (AC coverage check) | Verify all parent AC from triage are covered by maps_to in task tree | In-memory: unmapped AC list | Nowhere | Yes |
| 4c (Subtask execution loop) | Per-subtask: verify depends_on, run pre-fix hook, fixer, build, post-fix hook, post-fix custom agent, reviewer, test-engineer, e2e-test-engineer, commit. Save commit_hash and restore_point back to task tree YAML on disk. | Code changes (git commits), updated task tree YAML with per-subtask commit_hash and restore_point | Git commits + `.claude/decomposition/{ISSUE-ID}.yaml` (updated on each subtask commit) | Partial — task tree structure and restore points survive; per-subtask fixer/reviewer iteration counts, build output, test output lost |
| 4d (Pre-fix hook) | Run Hooks → Pre-fix bash command | Hook stdout/stderr | Nowhere | Yes — hook output lost |
| 4e (Browser Reproduction) | Run `ceos-agents:reproducer` (conditional: browser_verification_enabled AND browser_reproduce). Agent generates `.claude/reproducer-script.js`, runs it with timeout enforcement, writes evidence bundle | `.claude/reproducer-script.js` (Playwright script), `.claude/reproduction-result.json` (status, page_url, accessibility_snapshot, console_errors, network_failures, screenshot_path), screenshot at `{Screenshot storage}/{issue-id}-before.png` | `.claude/reproducer-script.js`, `.claude/reproduction-result.json`, screenshot file in `.claude/screenshots/` | No — all three files persist. Note: NEVER committed to git. |
| 5 (Fixer) | Run `ceos-agents:fixer` (opus). TDD approach, diffs ≤100 lines. May signal NEEDS_DECOMPOSITION. | Code changes (uncommitted diff), in-memory fixer verdict | Git working tree (uncommitted) | Yes — uncommitted changes lost if session crashes. Once committed (step 6/Build success), survives. Fixer iteration count is in-session only. |
| 5 (Fixer — NEEDS_DECOMPOSITION) | Authoritative revert: `git checkout . && git clean -fd`. Then route to architect decomposition (step 4b) | Revert applied to working tree | Git | No |
| 6 (Build) | Run Build command from Automation Config. Retry up to Build retries limit. | In-memory: pass/fail, retry count | Nowhere | Yes — build output and retry count lost |
| 6a (Post-fix hook) | Run Hooks → Post-fix bash command | Hook stdout/stderr | Nowhere | Yes |
| 6b (Post-fix custom agent) | Run Custom Agents → Post-fix agent (one-shot) | Agent verdict (BLOCK or pass) | Nowhere | Yes |
| 7 (Reviewer loop) | Run `ceos-agents:reviewer` (opus). Produces AC Fulfillment section (per-AC: FULFILLED/PARTIALLY/NOT ADDRESSED). REQUEST_CHANGES → back to fixer. Loop up to Fixer iterations limit. | In-memory: reviewer verdict, AC fulfillment section, iteration count | Nowhere | Yes — reviewer verdict history and iteration count are in-session only |
| 8 (Test-engineer) | Run `ceos-agents:test-engineer` (sonnet). Loop up to Test attempts limit. | In-memory: test pass/fail, attempt count | Nowhere | Yes — test output and attempt count lost |
| 8a (E2E test-engineer) | Conditional (E2E Test section exists or profile Extra stages). Run `ceos-agents:e2e-test-engineer`. | In-memory: pass/fail | Nowhere | Yes |
| 8a-browser (Browser Verification) | Conditional (browser_verification_enabled AND browser_verify). Run `ceos-agents:browser-verifier`. Agent replays `.claude/reproducer-script.js`, checks adjacent pages, visual AC check, optional guided exploration. | `.claude/verification-result.json` (verdict, subphase_a, subphase_b, screenshots array), screenshot files in `.claude/screenshots/`. Note: `.claude/verifier-script.js` may be written as temp. | `.claude/verification-result.json`, `.claude/screenshots/`, `.claude/verifier-script.js` (temp, never committed) | No — JSON file persists. In-session: verdict fed back to fixer if FAILED, observations passed to PR comment context. |
| 8b (Acceptance gate) | Conditional (AC >= 3 OR complexity >= M). Run `ceos-agents:acceptance-gate` (sonnet). Read-only. REQUEST_CHANGES → back to fixer (counts toward same Fixer iterations limit). | In-memory: APPROVE or REQUEST_CHANGES | Nowhere | Yes |
| 8c (Pre-publish hook) | Run Hooks → Pre-publish bash command | Hook stdout/stderr | Nowhere | Yes |
| 8d (Pre-publish custom agent) | Run Custom Agents → Pre-publish agent (one-shot) | Agent verdict | Nowhere | Yes |
| 9 (Result / Publisher decision) | Display result. If --yolo or user approves: run `ceos-agents:publisher` (haiku). Publisher creates PR, sets issue state to "For Review". | PR URL | Git remote (branch pushed) + issue tracker (PR link comment) | No — PR is durable in git/tracker |
| 9a (Post-publish hook) | Run Hooks → Post-publish. Failure = warning only. | Hook stdout/stderr | Nowhere | Yes |
| 9b (Webhook) | POST to Webhook URL with event=pr-created, issue_id, pr_url, timestamp | Webhook delivery | External webhook receiver | N/A — fire-and-forget |
| 9c (Token estimate) | Display estimate: ~119,000 tokens, ~$0.50–$1.60 | None | Nowhere | N/A — display only |
| 9d (Fix Verification) | Conditional (Verify command exists). Polls for PR merge (max 5 attempts × 30s). Runs Verify command on base branch. | Issue tracker comment (`[ceos-agents] ✅ Fix verified.` or `[ceos-agents] ❌ Fix verification failed.`). If FAIL: re-opens issue. | Issue tracker comment | No — comment persists |
| X (Block handler) | Run `ceos-agents:rollback-agent` (haiku). CWD mode: `git stash` + `git reset --hard {base_branch}` + `git clean -fd`. Worktree mode: `git reset --hard {base_branch}` + `git clean -fd`. Post block comment. Set issue state to Blocked. Optionally fire issue-blocked webhook. | Block comment on issue tracker, issue state = Blocked, git state reverted | Issue tracker (block comment + state), Git (revert applied) | Partial — block comment and issue state persist; pre-rollback git diff, exact error context, stash contents (CWD mode only) are not tracked |

**Exceptions to rollback:** Block handler step 1 in rollback-agent explicitly skips rollback for blocks from triage-analyst, code-analyst, spec-analyst, architect, stack-selector (read-only agents — no git changes), publisher (PR may exist — manual cleanup), and scaffolder.

---

## fix-bugs Concurrency Model

Source: `commands/fix-bugs.md`

### Variant A: Parallel (Worktrees config exists)

fix-bugs operates in two modes depending on whether the Worktrees config section exists.

**Parallel worktree mode:**
1. After fetching bugs (step 1), triage is always parallel regardless of worktree config — triage is read-only so parallelism is safe.
2. Code-analyst is also parallel for all bugs that passed triage.
3. For the fix pipeline, bugs are processed in batches of `batch_size` (default: 3). For each batch:
   - `git worktree add {base_path}/{issue_id} -b {branch_naming_pattern} {base_branch}` creates one worktree per bug
   - All Task calls for bugs in the batch are dispatched IN ONE MESSAGE BLOCK (fully parallel)
   - Each Task receives its worktree path and works isolated (`cd` to worktree as first step)
   - After all Tasks complete: collect results, run rollback-agent per blocked bug IN its worktree, then clean up all worktrees

**State conflicts in parallel mode:**

| Conflict Type | Risk | Mitigation |
|--------------|------|------------|
| Git branch naming collision | Medium — two bugs could map to same branch name if naming pattern is not unique per issue | Branch naming pattern includes issue ID (from Automation Config Branch naming), so collision is only possible if two issues have the same ID |
| `.claude/reproduction-result.json` | HIGH — this file is written to the MAIN repo `.claude/` directory, not the worktree. All parallel worktrees share the same `.claude/` directory. If two bugs run browser reproduction concurrently, they will overwrite each other's `reproduction-result.json` and `reproducer-script.js`. | No mitigation stated in the codebase. This is a documented gap. |
| `.claude/verification-result.json` | HIGH — same as reproduction-result.json. browser-verifier writes to `.claude/verification-result.json` in the main repo directory. Parallel verifiers will clobber each other's results. | No mitigation stated. |
| `.claude/screenshots/` | LOW — screenshots are named `{issue-id}-before.png` so naming should be unique per issue, avoiding collision. | The `{issue-id}` in filename provides natural isolation. |
| `.claude/decomposition/{ISSUE-ID}.yaml` | LOW — file is named by issue ID so parallel decompositions write to different files. | Issue ID in filename provides isolation. |
| Issue tracker state transitions | LOW — each bug is a separate issue; state changes are per-issue. | Independent issue IDs prevent conflict. |
| Build command contention | MEDIUM — if Build command touches shared resources (e.g., a port, shared DB), parallel builds may interfere. | No mitigation. Depends entirely on how the project's build command is isolated. |

**Fix Verification in batch mode:** Verification runs BEFORE worktree cleanup. Verification is per-bug and runs in the bug's worktree (parallel mode) or CWD (sequential mode).

### Variant B: Sequential (no Worktrees config)

Process bugs one by one in CWD. No worktrees. No parallelism conflict. Block counter (`block_count`) is tracked across bugs; if `Max blocked per run` limit is reached, remaining bugs are skipped.

**Block counter logic (fix-bugs only, not fix-ticket):**
- After each blocked bug: `block_count++`
- If `block_count >= Max blocked per run` (from Error Handling config, default: unlimited) → stop, display "Max blocked per run ({N}) reached. Remaining {M} bugs skipped."
- fix-ticket has no equivalent counter (single-ticket, one block = pipeline ends)

---

## resume-ticket Detection Heuristic

Source: `commands/resume-ticket.md`

The checkpoint detection is a priority-ordered decision tree, NOT a flat 7-level table. The code says "7-level" in CLAUDE.md memory but the actual command defines 7 checkpoint states evaluated in this exact order:

### Detection Logic (priority order, highest first)

```
if PR exists for branch → PUBLISHED
else if .claude/decomposition/{ISSUE-ID}.yaml exists → DECOMPOSE_PARTIAL
else if branch has commits above base → POST_FIX (or POST_REVIEW if reviewer approval comment)
else if branch exists + triage comment → POST_ANALYSIS
else if triage comment exists → POST_TRIAGE
else → FRESH
```

### Checkpoint Table

| Priority | Checkpoint | Signal Read | What Is Skipped |
|----------|------------|-------------|-----------------|
| 1 (highest) | `DECOMPOSE_PARTIAL` | File `.claude/decomposition/{ISSUE-ID}.yaml` exists AND some subtask marked completed in the YAML | Triage + code-analyst + already-completed subtasks |
| 2 | `PUBLISHED` | Open PR exists for the branch (via source control MCP) | Entire pipeline — display status only |
| 3 | `POST_REVIEW` | Branch has commits above base AND reviewer approval comment exists in issue tracker | Triage + code-analyst + fixer + reviewer |
| 4 | `POST_FIX` | Branch has commits above base (no reviewer comment) | Triage + code-analyst + fixer |
| 5 | `POST_ANALYSIS` | Branch exists (per Branch naming pattern) AND triage checkpoint comment exists | Triage + code-analyst |
| 6 | `POST_TRIAGE` | Comment `[ceos-agents] Triage completed.` or `[CLAUDE-agents] Triage completed.` exists (no branch) | Triage only |
| 7 (lowest) | `FRESH` | None of the above signals present | Nothing — full pipeline runs |

**DECOMPOSE_PARTIAL** has explicit highest-priority override: "This checkpoint has the HIGHEST priority — if a task tree exists, always use DECOMPOSE_PARTIAL." When detected, reads the YAML to find last completed subtask, continues from next in_progress or pending subtask, resets failed subtasks to pending.

**Pipeline type detection** (runs after checkpoint detection, step 8 of resume-ticket):
- Comment `[ceos-agents] Spec analysis completed.` → FEATURE pipeline (use implement-feature steps)
- Comment `[ceos-agents] Triage completed.` → BUG pipeline (use fix-ticket steps)
- Neither → BUG pipeline (default)

**Signal sources queried at resume time:**
1. Issue tracker: comments (via MCP) — for triage checkpoint, spec checkpoint, reviewer approval comment, blocked state
2. Git: branch existence, commit count above base branch (via Bash)
3. Source control MCP: open PR existence
4. Local filesystem: `.claude/decomposition/{ISSUE-ID}.yaml`

**Known limitation (stated in resume-ticket.md):** "Detection is best-effort — heuristics may not be 100% accurate. Worst case: re-run one extra step — not a catastrophe."

---

## Persistent Artifacts Inventory

Complete list of artifacts that survive LLM session boundaries, with their file paths.

### Local Filesystem (project root)

| Artifact | Path | Written By | Consumed By | Committed? |
|----------|------|------------|-------------|------------|
| Decomposition task tree YAML | `.claude/decomposition/{ISSUE-ID}.yaml` | fix-ticket step 4b, fix-bugs step 3b, implement-feature | resume-ticket (DECOMPOSE_PARTIAL checkpoint), subtask execution loop | No (recommended to gitignore) |
| Reproduction result JSON | `.claude/reproduction-result.json` | `agents/reproducer.md` (via Bash tool) | browser-verifier (reads in step 1), fixer (passed as additional context) | No — NEVER commit (explicit constraint in reproducer.md) |
| Reproducer Playwright script | `.claude/reproducer-script.js` | `agents/reproducer.md` (via Write tool) | browser-verifier (reuses script in sub-phase A replay) | No — NEVER commit |
| Verification result JSON | `.claude/verification-result.json` | `agents/browser-verifier.md` (via Write tool) | Pipeline command (reads verdict), fixer (if FAILED) | No — NEVER commit |
| Verifier Playwright script | `.claude/verifier-script.js` | `agents/browser-verifier.md` (implied by NEVER commit constraint) | Internal to browser-verifier | No — NEVER commit |
| Screenshots (reproduction) | `.claude/screenshots/{issue-id}-before.png` | `agents/reproducer.md` | PR comment context, browser-verifier visual check | No |
| Screenshots (verification) | `.claude/screenshots/` (paths recorded in verification-result.json) | `agents/browser-verifier.md` | PR comment context | No |
| Setup validated marker | `.claude/setup-validated` | `commands/check-setup.md` | `commands/status.md` recommendation (step 7c) | Unknown — not documented |

### Git Repository

| Artifact | Location | Written By | Consumed By |
|----------|----------|------------|-------------|
| Feature branch | Git local + remote | fix-ticket step 2, fix-bugs worktree setup | All subsequent steps, reviewer, publisher |
| Fixer commits | Git history on branch | fixer agent (commit per subtask in decomposition mode) | reviewer (reads diff), test-engineer, browser-verifier (git diff HEAD~1), publisher |
| Squashed commit (decomposition) | Git history | fix-ticket step 4c (after all subtasks) | publisher |

### Issue Tracker (External)

| Artifact | Written By | Consumed By |
|----------|------------|-------------|
| Issue state (In Progress, Blocked, For Review) | fix-ticket step 1, block handler step X | resume-ticket (blocked warning), status command |
| Triage checkpoint comment `[ceos-agents] Triage completed. Severity: {s}. Area: {a}. Complexity: {c}. AC: {n}.` | triage-analyst step 7 | resume-ticket (POST_TRIAGE detection, pipeline type detection) |
| Block comment `[ceos-agents] 🔴 Pipeline Block` | rollback-agent step 5 (via block handler) | resume-ticket (blocked warning, step 9) |
| Fix verified comment `[ceos-agents] ✅ Fix verified.` | fix-ticket step 9d | Human readers |
| Fix verification failed comment `[ceos-agents] ❌ Fix verification failed.` | fix-ticket step 9d | Human readers; triggers issue re-open |
| PR link / "For Review" state | publisher agent | status command |

---

## State Loss Inventory

Complete list of what is NOT persisted across session boundaries.

| Lost State | Last Known Location | Impact of Loss |
|------------|---------------------|----------------|
| Full acceptance criteria list (text of each AC) | In-memory context from triage-analyst output | resume-ticket cannot recover AC text — must re-run triage or re-read issue. Downstream agents (fixer, reviewer, acceptance-gate) need AC text, not just count. MEDIUM impact. |
| Complexity value (XS/S/M/L) | In-memory context from triage-analyst output | Acceptance gate condition (`complexity >= M`) cannot be re-evaluated at resume. Comment has count of AC, not complexity value. MEDIUM impact. |
| Code-analyst impact report (affected_files, risk, estimated_diff_lines, independent_changes) | In-memory context from code-analyst | Decomposition decision cannot be re-derived. Resume at POST_ANALYSIS skips to fixer without re-running code-analyst. MEDIUM impact. |
| Fixer iteration count | In-memory counter in command | Resume after fixer runs always resets the loop counter. A previously-exhausted fixer could get fresh iterations on resume. LOW-MEDIUM impact (could allow more retries than configured). |
| Test attempt count | In-memory counter | Same as fixer iteration count — resets on resume. LOW-MEDIUM impact. |
| Build retry count | In-memory counter | Same. LOW impact. |
| Reviewer verdict history (which iterations led to REQUEST_CHANGES, and why) | In-memory context | Fixer resuming after reviewer does not know the history of what was rejected. May repeat rejected approaches. MEDIUM impact. |
| Browser verification verdict (VERIFIED/PARTIAL/FAILED/SKIPPED) | In-memory after reading `.claude/verification-result.json` | File persists on disk, so recovery is POSSIBLE if command re-reads the file. However, no command explicitly does this on resume — the orchestrator reads it inline during execution only. MEDIUM impact. |
| Build output (stdout/stderr) | In-memory | Cannot be referenced in block comments after session end. LOW impact. |
| Test output | In-memory | Same. LOW impact. |
| Which pipeline profile was active | In-memory parsed from --profile argument | If resume-ticket is called without the same --profile flag, it will not skip the same stages. This could cause stages to run that were previously skipped. HIGH impact. |
| Hook execution results (pre/post-fix, pre/post-publish) | In-memory | Hook stdout/stderr not captured anywhere. Cannot diagnose hook failures after session end. LOW impact. |
| Custom agent verdict (BLOCK reason details) | Block comment only (if blocked) | If custom agent passed, no record of its run. LOW impact. |
| Subtask restore_point (per-subtask git hash) | `.claude/decomposition/{ISSUE-ID}.yaml` (written after each commit) | The YAML is updated after each subtask commit, so this survives IF the YAML write succeeded before session end. If the crash happened between commit and YAML write, the restore point for the last completed subtask is lost. LOW-MEDIUM impact. |
| Token usage actuals | Nowhere | Metrics command has no real data. LOW operational impact. |
| Per-step timing | Nowhere | Cannot compute real duration metrics. LOW operational impact. |

---

## status Command Data Sources

Source: `commands/status.md`

The status command reads exclusively from live external sources. It has no local state reads.

| Data Point | Source | How Retrieved |
|------------|--------|---------------|
| Active issues (in progress, blocked, for review) | Issue tracker | MCP query using states from `Issue Tracker → State transitions` in Automation Config |
| Feature issues (if Feature Workflow config exists) | Issue tracker | MCP query using `Feature Workflow → Feature query` |
| Branch existence | Source control MCP | Look for remote branches containing the issue ID as substring (per Branch naming config) |
| PR existence | Source control MCP | Look for open PRs for the given branch |
| Setup validated marker | Local filesystem | Checks `.claude/setup-validated` — if absent, recommends running check-setup |
| CLAUDE.md existence and completeness | Local filesystem (CWD) | Checks for `<!-- TODO:` markers in Automation Config sections |

**What status does NOT read:**
- `.claude/decomposition/` — does not show decomposition state
- `.claude/reproduction-result.json` — does not show browser reproduction state
- Issue tracker comments — does not parse `[ceos-agents]` comment history
- Git commit history — does not analyze branch depth or commit count

**Recommended next steps logic** (step 7 of status.md) is entirely heuristic:
- Blocked issues → suggests `analyze-bug`
- Stale branches (>24h without new commits) → suggests `resume-ticket` (reads branch age from source control MCP)
- PRs awaiting review → states count
- No active issues → suggests `fix-bugs` or `prioritize`
- Feature backlog → suggests `implement-feature` or `prioritize`

---

## Gaps

Items that could not be fully determined from the source files:

1. **Where `.claude/setup-validated` is written.** `commands/status.md` reads it and `commands/check-setup.md` presumably writes it, but `commands/check-setup.md` was not read in this research session. The exact format (empty file? JSON? timestamp?) is unknown.

2. **Whether `.claude/verifier-script.js` is explicitly written by browser-verifier or is implicit.** The browser-verifier.md constraint says NEVER commit it, but the Process steps do not explicitly include a Write step for the verifier script (unlike reproducer.md which explicitly writes to `.claude/reproducer-script.js`). The script may be written as part of the inline Playwright generation steps that were not fully shown.

3. **Race condition mitigation for `.claude/reproduction-result.json` in parallel worktree mode.** The fix-bugs worktree documentation says each Task "works in its worktree," but `reproducer.md` writes to `.claude/reproduction-result.json` which is a path relative to the script's CWD — which may be the worktree root (isolated) or the main repo root (shared). If it is relative to the worktree, there is no conflict. If it is absolute to the main `.claude/`, there is a race condition. The source does not disambiguate.

4. **Reviewer approval comment format.** The resume-ticket `POST_REVIEW` checkpoint detects a "reviewer approval comment" in the issue tracker, but the reviewer agent definition was not read in this session. The exact format of this comment is unknown — it may be a standardized `[ceos-agents]` prefix comment or free-form.

5. **Triage-analyst attachment storage.** The triage-analyst constraint says "MUST store downloaded attachments in system temp directory only, organized by issue ID." The exact temp path and whether these survive between sessions was not investigated.

6. **fix-bugs Max blocked per run counter scope.** It is unclear whether `block_count` resets between batches (in parallel worktree mode, after cleanup and before the next batch starts) or is cumulative across the entire run. The command says "after reaching the limit, stop processing remaining bugs" but the batch boundary interaction is not stated.
