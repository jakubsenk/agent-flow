# Proposal A — Conservative

## Strategic Frame

v7.0.0 is a MAJOR (breaking) release per CLAUDE.md versioning policy, but "breaking" does not mandate "noisy." The strategy is: do the minimum mechanical work the spec requires, reuse every existing pattern verbatim (publisher agent, MCP prefix-scan from `core/mcp-detection.md`, issue-ID regex from v6.8.1), and concentrate the user-facing migration help in two places where the user is already looking — `/ceos-agents:check-setup` (pre-flight) and `CHANGELOG.md` (post-upgrade). No new config keys, no new flags, no runtime banners, no stub skills. If a user types a deprecated identifier, Claude Code's normal "skill not found" error is the correct signal — augmented by the fact that `/check-setup` will have already warned them on first run.

## 1. /publish auto-detect implementation strategy

The rewrite is surgical: insert one branch decision between current Step 1 and Step 4. Steps 4-9 (publisher dispatch, webhook, display) remain byte-identical except that `Step 6 (issue tracker state)` and `Step 7 (PR comment)` become **conditional on `issue_found == true`**. The publisher agent at `agents/publisher.md` is dispatched with the same Task signature; only the context string changes (one extra line: `mode = full | pr_only`).

### Pseudocode for skills/publish/SKILL.md Steps 1-3 replacement

```
### 0. MCP pre-flight check
   (UNCHANGED — already verifies tracker MCP tool availability)

## Steps

1. Determine the current branch:
   branch_name = $(git branch --show-current)

2. Extract issue_id from branch_name:
   a. Read `Source Control → Branch naming` template from Automation Config
      (e.g., "fix/{issue-id}-{description}")
   b. Identify static prefix before `{issue-id}` placeholder (e.g., "fix/")
   c. Strip prefix from branch_name. Apply regex `^[A-Za-z0-9#._-]+`
      (REUSE the v6.8.1 issue-ID regex verbatim — see fix-ticket/SKILL.md:91)
   d. issue_id = first regex capture, or null if no match

3. Determine publish mode:
   IF issue_id == null:
     mode = "pr_only"
     LOG: "[INFO] No issue ID found in branch name '{branch_name}'.
            Publishing PR without tracker update."
     SKIP to Step 4.

   ELSE:
     # Read tracker_type from Automation Config (default: youtrack)
     # Use MCP prefix-scan per core/mcp-detection.md:28-34 — DO NOT hardcode
     # tool names. The LLM resolves the get-issue tool at runtime from the
     # tracker prefix (e.g., mcp__youtrack__*, mcp__github__*).
     attempt: tracker.getIssue(issue_id) via discovered MCP tool

     IF success:
       mode = "full"
       LOG: "[INFO] Issue {issue_id} found. Publishing PR + tracker update."
     ELIF error_type == "not_found":   # per core/mcp-detection.md:58-87
       mode = "pr_only"
       LOG: "[INFO] Issue {issue_id} not found in tracker.
              Publishing PR without tracker update."
     ELSE:   # error_type in {tls, auth, timeout, unknown}
       FAIL with the message from §5 below.

4. Verify commits above base branch.   (UNCHANGED)
5. Check for existing open PR.         (UNCHANGED)
6. Read Type from Automation Config.   (UNCHANGED)
7. Dispatch publisher agent (Task, haiku) with context:
     "Type = {Type}. Use MCP server for {Type}.
      mode = {mode}.
      issue_id = {issue_id or 'none'}."
   (UNCHANGED dispatch shape — only the context string adds 2 lines.)
8. IF mode == "full":
     - Set issue tracker state per State transitions → For Review
     - Post PR-link comment to issue tracker
   ELSE:
     - Skip both (PR-only mode).
9. Webhook (UNCHANGED — pr-created event fires in both modes; issue_id field
   is empty string when mode == "pr_only", consistent with the v6.8.0
   forward-compatible payload contract).
10. Display result: PR URL + (mode == "full" ? "issue {issue_id} → For Review"
                              : "PR-only mode (no tracker update)")
```

### Cited patterns reused verbatim

- **MCP prefix-scan**, not hardcoded tool names: `core/mcp-detection.md:28-34, 36`. Phase 2 confirmed (Q7): "the codebase uses prefix-scan — no hardcoded single-issue tool names exist." `/publish` MUST follow this contract; the get-issue tool name (`get_issue`, `getIssue`, etc.) is discovered at runtime from the prefix.
- **Error classification**: `core/mcp-detection.md:58-87`. The 5-type table (`tls`, `auth`, `not_found`, `timeout`, `unknown`) is the exact decision basis for the 3-way fork.
- **Issue-ID regex**: `^[A-Za-z0-9#._-]+$` from `skills/fix-ticket/SKILL.md:91` (per v6.8.1). For branch-extraction we drop the trailing `$` anchor so the regex matches the issue-ID prefix segment of the branch.
- **Publisher agent unchanged**: `agents/publisher.md` line 69 (`Extra labels` reference) is removed independently as part of Action 1; no other publisher edits.

### Why Steps 1-3 only

Phase 2 Q6 confirmed there is no existing branch→issue-ID extraction logic anywhere in the codebase. This is genuinely new logic, but it is local to `/publish`. By scoping the rewrite to Steps 1-3 and leaving 4-10 structurally intact, we keep the diff small enough for a single reviewer pass and we do not perturb the publisher agent's haiku-tier prompt (which is the most cost-sensitive in the pipeline).

## 2. Migration UX

### What the user sees on first run after v7.0.0 upgrade

Three touchpoints, in the order the user typically hits them:

1. **They run `/ceos-agents:check-setup`** (recommended in CHANGELOG migration section as step 1). `check-setup` already enumerates Automation Config sections at `skills/check-setup/SKILL.md:56`. We extend it with a **deprecated-section detector**: if the user's CLAUDE.md still contains an `### Extra labels` heading, emit:

   ```
   [WARN] Deprecated config section: ### Extra labels
     This section was removed in v7.0.0. Move any labels into
     ### PR Rules → Labels (which already supports a list).
     The duplicate Extra labels was removed because PR Rules → Labels
     fully covers the use case. See CHANGELOG.md for migration guide.
   ```

   This is a **warning, not a block**. The pipeline still runs; `Extra labels` is silently ignored by the publisher (since `agents/publisher.md:69` is gone). The warning is enough for the user to clean up at their leisure.

2. **They type `/status` or `/init`** (Czech-speaking users with muscle memory). Claude Code displays its standard "skill not found" error. We do NOT add stub skills (see §3). The CHANGELOG and README already tell them the new names; the muscle memory recalibrates within 1-2 attempts.

3. **They type `/ceos-agents:create-pr`**. Same — Claude Code says skill not found. CHANGELOG explains the auto-detect replacement.

### CHANGELOG migration guide enhancements

The spec includes a migration guide template; my recommended extensions (kept short — no bikeshedding):

```markdown
## v7.0.0 — Public Release Cleanup (BREAKING)

### Migration steps (in order)

1. Run `/ceos-agents:check-setup`. It will warn about deprecated config sections.
2. If you used `### Extra labels`: move any label values into `### PR Rules → Labels`
   (which is a comma-separated list and fully supersedes Extra labels). Delete
   the `### Extra labels` heading.
3. Update any aliases or scripts that called the old skills:
   - `/ceos-agents:status` → `/ceos-agents:pipeline-status`
   - `/ceos-agents:init` → `/ceos-agents:setup-mcp`
   - `/ceos-agents:create-pr` → `/ceos-agents:publish` (auto-detects
     PR-only vs PR+tracker mode based on branch name)
4. Run `/ceos-agents:check-setup` again to confirm no warnings.

### Why these changes
... (spec template fills this in)

### Slash-command collision warning

`/status` and `/init` (without the `ceos-agents:` prefix) are now Claude Code
built-ins. Always use the full `/ceos-agents:` namespace prefix to invoke
ceos-agents skills. This was the primary motivation for the rename — the
short forms were unreachable since Claude Code's builtins shadowed them.
```

### check-setup extension scope

Add ONE new check function (`check_deprecated_config_v7`) that scans CLAUDE.md for the literal string `### Extra labels`. That is the entire deprecated-section surface for v7.0.0 (only one section was removed). Implementation: a single grep + warn. ~10 lines added to `skills/check-setup/SKILL.md`.

This extension is **additive and non-breaking**. It does not change `/check-setup`'s exit semantics — warnings are warnings, not failures.

## 3. Stub-or-not decision (skills/status, skills/init)

**Verdict: DELETE entirely. No stubs.**

### Rationale

1. **The spec is explicit** (v7.0.0 FINÁLNÍ scope): rename the directories, no aliases, no stubs. Persona C will probe whether silent skill-not-found is acceptable; my answer is yes, because:

2. **`/status` and `/init` are Claude Code built-ins.** Per the user's project memory: "kolize s Claude Code builtin `/status`" and "kolize s Claude Code builtin `/init`." If we leave a `skills/status/SKILL.md` stub that prints "renamed," it would compete with the built-in. The user would get whichever the runtime resolves — probably the built-in, making our stub invisible. A stub here is worse than nothing because it fails silently.

3. **Stubs add ongoing maintenance cost.** A stub skill is still a frontmatter+body file that test scenarios (`skills-frontmatter-check.sh`, `skills-directory-structure.sh`) must account for. The Phase 2 Q8 test inventory already plans to update these tests to reflect 28 skills with `pipeline-status` and `setup-mcp`. Adding stubs would mean 30 skills (28 real + 2 stubs), permanently — or a more complex test that distinguishes "real" from "stub" skills. Not worth the complexity.

4. **Persona B's "deprecation banner on first invocation" is not implementable.** Claude Code does not give skills a one-time-fire-then-self-disable mechanism. We cannot persist "user has seen this banner." The spec already forbids this design (anti-pattern: "DO NOT propose a soft-deprecation cycle that requires runtime support Claude Code does not have").

5. **MAJOR version is the social contract for breaking renames.** The user opted into this when they chose v7.0.0 over v6.11.0. The CHANGELOG migration guide is the deprecation guidance; that is industry-standard for MAJOR releases.

### What the user actually sees if they type `/ceos-agents:status`

Claude Code: `Skill 'ceos-agents:status' not found.`

This is fine. It is a one-time confusion that is resolved by:
- The CHANGELOG (which the user is presumed to have read for a MAJOR upgrade)
- The README warning section (Action 6)
- `/ceos-agents:check-setup` warnings if they kept old config

## 4. /create-pr removal vs /publish --pr-only flag

**Verdict: DELETE `/create-pr` entirely. No flag. Auto-detect handles all three cases.**

### Rationale

1. **Spec forbids `--no-tracker` flag**: "DO NOT propose new config keys (the spec is explicit: no config key, no `--no-tracker` flag for `/publish`)." A `--pr-only` flag is the same anti-pattern under a different name.

2. **Auto-detect fully covers the legitimate use cases.** Phase 2 Q6 + Q7 give us the 3-way fork:
   - **No issue_id in branch name** → PR-only (covers users on branches like `chore/cleanup`, `release/prep`, `docs/typo`)
   - **issue_id present + tracker confirms 404** → PR-only (covers users with stale branches whose issue was deleted)
   - **issue_id present + tracker confirms found** → full mode (the happy path)

   The only case a manual `--pr-only` flag covers that auto-detect does not is "I have a valid issue_id, the tracker is reachable, the issue exists, but I want to publish the PR without updating tracker state." That is a fundamentally weird workflow — why would the user not want the state update? — and the spec correctly chooses not to support it.

3. **The auto-detect mode is fully deterministic.** Given the same branch name + same tracker state, the mode is always the same. No surprise side-effects, no hidden mode-switches.

4. **Even Persona A normally argues for soft deprecation** — but here the rename `/create-pr` → `/publish` is not even a rename; it's a **functionality merge**. `/create-pr` was always a strict subset of `/publish` (publish did the same thing PLUS tracker update). A subset operation absorbed by a superset operation does not need a soft deprecation cycle; it needs a CHANGELOG entry explaining the absorption.

### What about CI/cron contexts where MCP is not provisioned?

This is Persona C's edge case. Resolution: the existing `Step 0 MCP pre-flight check` in `skills/publish/SKILL.md:12-17` already STOPs the pipeline with: "Cannot connect to your {Type} issue tracker. Run `/ceos-agents:check-setup` for diagnostics." This is the correct behavior in CI: if you're publishing through ceos-agents, you must have tracker MCP configured. CI users who genuinely cannot have MCP can use raw `gh pr create` or equivalent — `/publish` is not designed to be MCP-less, and the spec is explicit on this.

## 5. Tracker-down failure UX

### Exact error message text

When `tracker.getIssue(issue_id)` returns `error_type` in `{tls, auth, timeout, unknown}` (per `core/mcp-detection.md:58-87` classification), `/publish` emits:

```
[ceos-agents] Publish blocked: tracker unreachable

Branch: {branch_name}
Detected issue ID: {issue_id}
Tracker type: {tracker_type}
MCP error class: {error_type}

The {tracker_type} integration is misconfigured or unreachable. /publish cannot
verify whether issue {issue_id} exists, so it cannot safely choose between
PR-only mode and full PR + tracker mode.

Recovery options (pick one):

  1. Run /ceos-agents:check-setup to diagnose the tracker connection.
     Most common causes: expired token (auth), self-signed cert (tls),
     network/VPN required (timeout).

  2. If you intentionally want a PR with no tracker update, rename your
     branch to one that does not start with the configured Branch naming
     prefix (e.g., from "fix/PROJ-123-foo" to "chore/PROJ-123-foo"), then
     re-run /publish. The auto-detect will not extract an issue ID, and
     PR-only mode will activate.

  3. Fix the tracker outage and re-run /publish. No retry-flag is needed;
     /publish is idempotent — it will not duplicate commits or PRs.

For the full failure mode reference see docs/guides/troubleshooting.md.
```

### Why this exact wording

- **Bracket prefix `[ceos-agents]`**: matches the Block Comment Template convention from CLAUDE.md so the message is machine-parseable by `/resume-ticket` and downstream tooling.
- **No emoji status banner**: Persona B will propose colored emoji prefixes; I reject that for plaintext-terminal compatibility (logs, CI artifacts). Plain text wins for grep-ability.
- **Three numbered recovery options**: exhaustively covers (a) "tracker is genuinely broken — fix it," (b) "I never wanted tracker update — work around it," (c) "transient — try again."
- **Recovery option 2 is the deliberate workaround for the `--no-tracker` use case** the spec forbids as a flag. The user can still get PR-only mode by renaming the branch. This is a good pattern: branch naming is the existing source of truth for issue association; making it the lever is consistent.
- **Recommends `/ceos-agents:check-setup`** — the same skill we extended in §2 to detect deprecated config. Reinforces `check-setup` as the universal triage entry point.
- **Idempotency callout**: addresses the implicit user fear "if I re-run will I get duplicate PRs?" — preempting a support question.

### What about a paused-pipeline state?

Persona B may suggest emitting a `pipeline-paused` webhook event for tracker-down. I reject: paused state in v6.9.0 means "awaiting NEEDS_CLARIFICATION human input" with a 30-day timeout window. Tracker-down is a **transient infrastructure failure** and does not need pipeline-state persistence. `/publish` is a leaf-node skill (no state.json) per Phase 2 finding; pausing it would require new state-management surface. Out of scope for v7.0.0.

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| User has existing scripts calling `/ceos-agents:create-pr` from CI/cron and they break overnight | CHANGELOG migration guide step 3 explicitly enumerates all 3 deprecated identifiers with replacement. Detection: BIFITO autopilot pilot per project memory uses `/fix-ticket` and `/implement-feature` only — not `/create-pr` — so the live pilot is unaffected. |
| User has `### Extra labels` in CLAUDE.md and expects the labels to still work | `/check-setup` warning catches it on first run. Until they migrate, labels are silently dropped — but `### PR Rules → Labels` was always a superset, so most users never used `### Extra labels` to begin with (Phase 2 confirmed only 2 of 8 templates referenced it). |
| `/publish` auto-detect misidentifies a branch like `feature/standalone-doc-fix` as having issue_id `standalone-doc-fix` | The regex `^[A-Za-z0-9#._-]+` will indeed match. Then the tracker lookup returns `not_found` → mode = pr_only. Correct outcome by accident, but **correct outcome**. The 3-way fork makes false-positive issue-ID extraction self-healing. |
| Tracker MCP returns `error_type = "unknown"` (a connection class we did not anticipate) | Maps to FAIL bucket per the message in §5. User runs `/check-setup`, which surfaces the underlying MCP error. No silent failure. |
| Test harness HARD-FAILs on the 12 scenarios per Phase 2 Q8 | All 12 are mechanical updates documented in Phase 2's canonical change list. Forge Phase 7 executes them per the table. No design risk — only execution risk. |
| User on a branch matching `Branch naming` regex but with NO MCP server configured | Caught by Step 0 MCP pre-flight. `/publish` STOPs before reaching the auto-detect logic. The pre-flight error message recommends `/check-setup` — same recovery path as §5. |

## Trade-offs

What this proposal gives up vs Personas B and C will likely propose:

- **vs Persona B (Innovative)**: I give up the inline emoji status banner ("Issue OK" / "Issue 404" / "Tracker DOWN") that prints BEFORE doing anything. B will argue that user delight requires a status preview. I argue that the dispatch is fast enough (single MCP call) that printing an early banner just adds visual noise; the final result line in Step 10 already conveys the same info. I also give up Persona B's `migrate-config v7` auto-rewriter — partly because the deprecated surface is one section (`Extra labels`), trivially manual; partly because automated config rewrites add a "did the auto-rewrite preserve my comments?" trust burden that pure documentation does not.

- **vs Persona C (Skeptical)**: I give up the safety-net stubs for `/status` and `/init` that print "renamed." C will argue that silent skill-not-found is hostile UX. I argue that for a MAJOR release with CHANGELOG + README warnings + `/check-setup` proactive detection, the user has THREE forewarnings before they hit skill-not-found. The fourth signal (Claude Code's own error) is sufficient. C may also argue for an explicit `--pr-only` flag for CI users; I refuse on spec grounds and offer the branch-rename workaround in §5 recovery option 2 as the deliberate escape hatch.

- **What I gain by giving these up**: a smaller diff (lower review cost), no new test scenarios beyond the 12 mechanical updates, no runtime behavior that depends on Claude Code features we cannot guarantee, and a CHANGELOG migration guide short enough that users will actually read it. The conservative bet: ceos-agents is at <100 users today (per project memory: "dnes málo userů, později mnohem víc"); investing in elaborate migration UX for a small user base wastes engineering on the wrong audience. We should ship the rename cleanly and save the migration-tooling investment for v8.0.0/v9.0.0 when the user base is larger.
