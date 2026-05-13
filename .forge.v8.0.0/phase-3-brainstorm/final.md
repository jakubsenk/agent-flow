# Phase 3 Final: Brainstorm Recommendation for v7.0.0

## Scoring Matrix

| Dimension | A (Conservative) | B (Innovative) | C (Skeptical) |
|-----------|------------------|----------------|----------------|
| Spec alignment | 5/5 | 4/5 | 5/5 |
| Simplicity | 5/5 | 3/5 | 4/5 |
| Migration UX | 4/5 | 5/5 | 4/5 |
| Edge cases | 3/5 | 4/5 | 5/5 |
| Honesty | 5/5 | 4/5 | 5/5 |
| **Total** | **22/25** | **20/25** | **23/25** |

### Scoring rationale

- **A (22/25)**: Surgical Steps 1-3 rewrite, full reuse of `agents/publisher.md` + `core/mcp-detection.md`; CHANGELOG-first migration with light `/check-setup` extension; honest about giving up B's status banner and C's safety nets; lower edge-case score because A omits R1 (MCP Step 0 / PR-only conflict) which C correctly flags as CRITICAL.
- **B (20/25)**: Banner-first design has innovation appeal but the 4-line banner format becomes a de-facto contract that v7.0.0 spec hasn't blessed; `/migrate-config` v7 extension with auto-rewrite is over-engineered for a single deprecated section; first-run nudge from `core/config-reader.md` invents a new state-tracking surface (sentinel comment) not in spec — gentle scope creep. Honest about which stretch ideas are IMPOSSIBLE.
- **C (23/25)**: Highest because it identifies R1 (MCP Step 0 ordering bug) which is a genuine spec gap that would silently break Phase 7 implementation; R2 Publish Report row is concrete UX improvement; R3-R8 are real corner cases. Honest about lost user agency from `/create-pr` removal (no opt-out for tracker-matching branches) — the kind of disclosure spec needs.

## Disagreement Analysis

### D1: Status banner UX (banner-first vs single result line)

- **A says**: No upfront banner. Single `[INFO]` line per mode, final `Step 10 result` shows mode + outcome. Rationale: dispatch is fast; early banner adds noise.
- **B says**: 4-line ascii/unicode banner printed BEFORE any work. `✓/⚠/✗/ℹ` symbol + `tracker:OK issue:PROJ-123 mode:full-publish` + commit/PR plan line. Rationale: power-users get the user's mental model right from line 1; symbol is machine-parseable.
- **C says**: Print decisions in **Publish Report footer** (R2) — three explicit `Tracker:` row states. No upfront banner.

- **VERDICT**: **C wins**, with one B contribution merged.
  - C's footer-row is structurally cleaner — it surfaces the auto-detect decision in the final report (publisher agent §82-87 already produces a Publish Report), so no new prose stream is invented.
  - However, B's three pre-flight `[INFO]` lines (one per mode) ARE worth keeping because the user wants to see the decision BEFORE the publisher dispatches (so they can Ctrl-C if the auto-detection is wrong). This is what A actually proposed (single `[INFO]` line) — A and B agree on this.
  - REJECT B's full ASCII banner format as a contract: it adds visual surface area and would lock v7.0.0 into a rendering format that v7.0.x might want to evolve. A 1-line `[INFO]` per mode is sufficient and matches existing skill conventions.

### D2: MCP pre-flight Step 0 ordering (CRITICAL)

- **A says**: Silent — A leaves Step 0 untouched. A's pseudocode keeps "Step 0 MCP pre-flight" as in v6.10.x, then proceeds to extract issue_id at Step 1.
- **B says**: Silent — same as A; banner is at Step 1, MCP pre-flight unaddressed.
- **C says**: Step 0 unconditional STOP-on-missing-MCP is **incompatible with PR-only mode**. C proposes branch-parse (issue_id extraction) BEFORE MCP pre-flight; if `issue_id == null`, set `tracker_needed = false` and skip MCP pre-flight entirely.

- **VERDICT**: **C wins decisively**. This is a real bug A and B both miss. If a user is on branch `chore/refactor-foo` (no issue ID), the spec-mandated PR-only path requires that MCP pre-flight be skipped — otherwise `/publish` STOPs with "Cannot connect to your tracker" before it even reaches the auto-detect logic. C's "pre-pre-flight branch parse → gate Step 0 by `tracker_needed`" is the correct design. Phase 4 spec must adopt this.

### D3: Migration tooling — passive docs vs active migrate-config extension

- **A says**: CHANGELOG migration block + `/check-setup` extension that scans CLAUDE.md for `### Extra labels` and emits `[WARN]`. ~10 lines added to check-setup. No new skill or sub-skill.
- **B says**: Extend `/migrate-config` skill with v6.x→v7.0.0 detection + label-merge auto-fix + sentinel comment `<!-- ceos-agents-config-version: 7 -->` to suppress future nudges + 1-line nudge from `core/config-reader.md`.
- **C says**: CHANGELOG + README migration table + `/check-setup` warns. Refuses `/migrate-config v7` extension as over-engineering.

- **VERDICT**: **A and C merge wins** (they substantively agree). REJECT B's auto-rewrite + sentinel + first-run nudge.
  - The deprecated config surface in v7.0.0 is a single section (`### Extra labels`). Phase 2 confirmed only 2 of 8 templates contain it — not worth a skill extension.
  - `/migrate-config` already enumerates `Extra labels` per Phase 2 Q2 line 41; deleting that array element in Phase 7 is the "migrate-config update" — no new logic.
  - B's sentinel comment (`<!-- ceos-agents-config-version: 7 -->`) introduces a versioning surface in user CLAUDE.md not present elsewhere and would need maintenance forever (each future release would need to update it). REJECT — the `/check-setup` warn approach has zero per-release cost.
  - First-run nudge from `core/config-reader.md` adds session-state tracking (was nudge shown this session?) that core doesn't have today. REJECT.

### D4: Stub skills for `/status`, `/init`, `/create-pr`

- **A says**: DELETE entirely. No stubs. Skill-not-found is acceptable. Workflow-router fallback prose for typo'd old names is OK.
- **B says**: DELETE entirely. No stubs. Workflow-router fallback prose acceptable.
- **C says**: DELETE entirely. No stubs (would inflate skill count to 30 and break invariants).

- **VERDICT**: **All three agree — DELETE**. C's argument is the strongest (skill count invariant), but all three converge.

### D5: Tracker-down recovery options

- **A says**: 3 numbered options: (1) `/check-setup`, (2) rename branch to bypass auto-detect (PR-only escape hatch), (3) re-run when reachable. Plain text, `[ceos-agents]` prefix.
- **B says**: 4 numbered options + `[STRETCH-1]` tracker-down webhook. Includes manual `git push` + tracker UI. Per-error_type customization (timeout/auth/tls/unknown).
- **C says**: 3 numbered options matching CLAUDE.md "Block Comment Template" verbatim (`[ceos-agents] 🔴 Pipeline Block`). Includes manual `git push` + `gh pr create` escape hatch. Three tiers (FAIL block / 404 WARN / no-match INFO).

- **VERDICT**: **C wins on format, A wins on the branch-rename hint, B's webhook deferred.**
  - C's exact format `[ceos-agents] 🔴 Pipeline Block` matches CLAUDE.md "Block Comment Template" — machine-parseable by `/resume-ticket` (this is the existing convention; deviating would be costly).
  - C's three-tier output (FAIL block / 404 WARN / no-match INFO) is the right structure — single-tier "FAIL" message conflates "tracker is down" with "no issue ID found," which are different operator actions.
  - A's recovery option 2 (rename branch to escape) is a genuinely useful disclosure — the user CAN get PR-only mode by renaming, and saying so empowers them. MERGE into C's recovery list.
  - B's `tracker-down` webhook = `[STRETCH-1]`, defer to v7.0.1/v8.0.0 per B's own concession.
  - C's `git push -u origin {branch} && gh pr create` manual escape hatch is the operational lifeline. KEEP.

### D6: Scope of `/check-setup` deprecated-config detection

- **A says**: Detect only `### Extra labels` heading. ~10 lines added.
- **B says**: Auto-fix label merge + dedupe + write CLAUDE.md edits + sentinel comment.
- **C says**: Detect `### Extra labels` AND stale count strings ("29 skills", "19 optional") in user CLAUDE.md. Doc-grep additive logic, no behavior change to exit codes.

- **VERDICT**: **A wins**, REJECT B's auto-fix and REJECT C's stale-count grep.
  - A's scope is exactly the deprecated section (1 surface) — minimal cost, addresses the only thing that breaks pipeline behavior (publisher silently dropping `Extra labels`).
  - C's "user CLAUDE.md has '29 skills'" is incorrect — user CLAUDE.md is project-specific config, NOT plugin docs. Users don't typically copy plugin count strings into their config. This check is a false-positive generator.
  - B's auto-fix reaches into user CLAUDE.md and merges labels — touching user config files automatically is high-trust, low-value here (1 section, 2 templates affected).

## Spec Violations Rejected

- **B's `[STRETCH-4]` `Banner Style: ascii | emoji | unicode` config key** — explicitly violates "no new config keys" anti-pattern. Already rejected by B.
- **B's `[STRETCH-5]` `/publish --dry-run` flag** — adds a new flag on `/publish`. Spec is silent on `--dry-run` specifically (forbids `--no-tracker`), but introducing flags during a "no-flag" cleanup release contradicts the design intent. REJECTED for v7.0.0; B already concedes "defer to v7.1.0."
- **B's `[STRETCH-1]` `tracker-down` webhook event** — additive (per webhook forward-compat rules) but adds a new event during a cleanup release. B itself recommends defer. REJECTED for v7.0.0 scope; can ship in v7.0.1 patch if observability demand emerges.
- **B's first-run banner from `core/config-reader.md` + sentinel comment in user CLAUDE.md** — invents new session-state and config-version surfaces not in spec. REJECTED as scope creep; A's CHANGELOG + `/check-setup` warn covers the same goal at zero ongoing cost.
- **B's `/migrate-config --scan-shell-history`** (`[STRETCH-3]`) — already self-rejected by B.
- **No `--pr-only` flag** — universally rejected by all three personas; reaffirmed.
- **No `/create-pr` stub or soft-deprecation** — universally rejected; reaffirmed.

## Free-MAD Flaw Analysis

### Proposal A flaws

1. **MISSES R1 (MCP Step 0 / PR-only conflict)**: A's pseudocode preserves Step 0 MCP pre-flight unconditionally, then extracts issue_id at Step 1. For a user on branch `chore/refactor-foo` with MCP unconfigured, Step 0 STOPs before Step 1 ever runs — PR-only mode is unreachable. This is a CRITICAL silent bug; A's risk table mentions "User on a branch matching `Branch naming` regex but with NO MCP server configured" but resolves it incorrectly ("Caught by Step 0 MCP pre-flight") without recognizing that PR-only mode ALSO needs to handle the no-issue-ID case independent of MCP availability.
2. **`/check-setup` extension scope underspecified**: A says "single grep + warn, ~10 lines" but doesn't specify whether the warn fires once or every run, whether it's gated by `--strict`, or how it interacts with `/check-setup` exit semantics. A claims "warnings, not failures" but `/check-setup` doesn't have a warn-vs-fail tiering today (it has gates). This is a small but real ambiguity Phase 4 must close.
3. **Missing E2 (bogus issue_id false-positive surface)**: A's risk table touches this but resolves it as "self-healing" — not wrong, but the user-facing visibility (does the WARN appear in the publish report? in stderr? both?) is left to Phase 7 to invent. Underspecified.

### Proposal B flaws

1. **Banner format becomes an implicit contract**: Once shipped, external tooling will scrape the `✓/⚠/✗/ℹ` symbols and the field layout. Future format changes become breaking. v7.0.0 (a cleanup release) is the wrong place to introduce a new structured-output surface.
2. **Sentinel comment in user CLAUDE.md (`<!-- ceos-agents-config-version: 7 -->`)** invents a per-user state surface that requires perpetual maintenance — every future release that wants to suppress nudges must update this convention. Worse, users who hand-edit CLAUDE.md may delete the sentinel and re-trigger nudges. High maintenance cost for a one-time migration goal.
3. **`/migrate-config` v7 extension automates a 1-section migration**: 2 of 8 templates have `Extra labels`; vast majority of users have zero `Extra labels` to migrate. Auto-rewrite logic is over-engineered for the actual deprecated surface.
4. **Per-error_type recovery customization in FAIL message** (timeout vs auth vs tls vs unknown) — fine UX but adds 4-row maintenance table that v7.0.1 must keep accurate against `core/mcp-detection.md` evolution. Single message with classification line + uniform recovery options (C's approach) is lower-cost.

### Proposal C flaws

1. **`/check-setup` stale-count detection (R3 indirect)**: C suggests `/check-setup` warn when user CLAUDE.md still says "29 skills" or "19 optional." But user CLAUDE.md doesn't typically contain plugin count strings — those live in plugin docs (which Phase 7 updates). False-positive generator; only catches the rare user who hand-copied count strings from the plugin into their own config. Low value.
2. **R8 (empty-directory check) scope inflation**: The empty-dir check is genuinely useful but it's a Phase 8 verification command, not a Phase 7 implementation guidance. C lists it correctly as Phase 8 but the surrounding rhetoric ("Without this, a Phase 7 hiccup on Windows could ship a 29-skill plugin") slightly overstates risk — Phase 7 will use `git rm -r` per Phase 2's verification commands, which doesn't leave empty dirs. The check is belt-and-suspenders.
3. **Refuses publisher Report banner-row but accepts FAIL block format**: C accepts `[ceos-agents] 🔴 Pipeline Block` (3-line + Recommendation list) for FAIL but argues against any banner for the success path. Asymmetric. Small inconsistency.

### Merged proposal (Free-MAD)

Take **C as the base** (highest score, identifies R1 critical bug, honest about user-agency loss). Merge:

- **A's CHANGELOG-first migration scope** (reject B's auto-rewrite, reject C's stale-count check) — minimum-surface migration support.
- **A's branch-rename escape hatch in tracker-down recovery** (recovery option 2 of A's §5) — empowers user with the existing branch-naming lever.
- **A's surgical Steps 1-3 scope** for the `/publish` rewrite — reuse existing publisher agent verbatim, only context string changes.
- **C's R1 mitigation (gate MCP pre-flight by `tracker_needed`)** as the new Step 0 design — this is the load-bearing addition.
- **C's R2 Publish Report `Tracker:` row** for surfacing decisions in user-facing output.
- **C's R3-R5 explicit error_type fork** including `unknown` → FAIL (defensive default).
- **C's three-tier output** (FAIL block / 404 WARN / no-match INFO) for the success+failure UX.

Reject from all:

- B's banner contract.
- B's sentinel comment + first-run nudge.
- B's `/migrate-config` v7 extension.
- B's stretch ideas (all 5 deferred or rejected).
- C's `/check-setup` stale-count grep.

## Recommended Approach (Final)

### Dimension 1: /publish auto-detect implementation strategy

**Winner**: **C base + A scope merged**

**Approach**: Rewrite `skills/publish/SKILL.md` Steps 0-3 with the following structure (replacing current Steps 0-3). Steps 4-10 remain structurally intact; only the publisher dispatch context string adds a `mode` field.

```
### Step 0 (NEW: branch parse — pre-pre-flight)

a. branch_name = $(git branch --show-current)
b. Read `Source Control → Branch naming` from Automation Config.
   Identify the literal prefix before `{issue-id}` placeholder
   (e.g., `fix/`, `feature/`).
c. Strip prefix from branch_name. Apply v6.8.1 issue-ID regex
   `^[A-Za-z0-9#._-]+` to the residue. Reject dot-only edge case
   (`! issue_id =~ ^\.+$`) per v6.8.1 path-traversal defense.
   First match → issue_id. No match → issue_id = null.
d. If issue_id == null:
     tracker_needed = false
     mode = "pr-only-no-id"
     Skip directly to Step 2.
   Else:
     tracker_needed = true
     proceed to Step 1.

### Step 1 (RENAMED from Step 0: MCP pre-flight, GATED)

ONLY runs if tracker_needed == true:
  Reuse the existing MCP pre-flight from current Step 0 verbatim
  (per `core/mcp-preflight.md`).
  On failure: emit FAIL block per Dimension 5.

### Step 2 (Tracker lookup — GATED on tracker_needed)

ONLY runs if tracker_needed == true:
  a. Read tracker_type from Automation Config (default: youtrack).
  b. Locate single-issue fetch tool via prefix-scan per
     `core/mcp-detection.md:28-34` and `core/mcp-detection.md:36`
     (DO NOT hardcode tool names — LLM picks the get_issue-shaped
     tool from `mcp__{tracker_type}__*`).
  c. Call discovered tool with issue_id.
  d. Classify outcome per `core/mcp-detection.md:58-87`:
     - Issue returned with valid summary →
         mode = "full-publish"
         INFO: "[ceos-agents] Issue {issue_id} found. Publishing PR + tracker update."
     - error_type == "not_found" →
         mode = "pr-only-404"
         WARN per Dimension 5 §404 tier
     - error_type ∈ {"timeout", "auth", "tls", "unknown"} →
         mode = "FAIL"
         emit FAIL block per Dimension 5 §FAIL tier
         EXIT non-zero
     - "Prefix has tools but no get_issue-shaped tool found" →
         classify as error_type = "unknown" → FAIL (R3 mitigation)

### Step 3 (Common pre-publish — mode-independent except FAIL)

a. git log {base_branch}..HEAD --oneline
   If zero commits → "No changes to publish" → STOP (info, not error).
b. Check whether an open PR exists for current_branch
   If yes → "PR already exists: {URL}" → STOP.

### Step 4-9 (Publisher dispatch + state transition + comment)

(Existing Steps 4-9 with these conditional adjustments)

Step 4: Read Type from Automation Config (UNCHANGED).
Step 5: Dispatch publisher agent (haiku, Task) with context:
  "Type = {Type}. Use MCP server for {Type}.
   mode = {mode}.
   issue_id = {issue_id or 'none'}."
   (UNCHANGED dispatch shape — only context string adds 2 lines.)

Step 6: IF mode == "full-publish":
  - Set issue tracker state per State transitions → For Review
  - Post PR-link comment to issue tracker
  ELSE (mode in {pr-only-no-id, pr-only-404}):
  - Skip both. Log "[INFO] PR-only mode ({reason}); tracker not updated."

Step 7: Webhook (UNCHANGED — pr-created event fires in all non-FAIL modes;
  issue_id field is empty string when mode in pr-only-* per v6.8.0
  forward-compatible payload contract).

Step 8: Display Publish Report. The publisher agent (per agents/publisher.md
  §82-87) ADDS a new `Tracker:` row to the report (R2 mitigation):
  - mode "full-publish":  Tracker: Updated → For Review
  - mode "pr-only-404":   Tracker: Skipped — issue ID '{issue_id}' not found in {tracker_type}
  - mode "pr-only-no-id": Tracker: Skipped — no issue ID in branch name
```

**Phase 2 citations:**
- Q6: confirmed no existing branch→issue-id extraction logic; this is genuinely new logic local to `/publish`.
- Q7: prefix-scan only, no hardcoded tool names; 5-bucket error classification (`tls`, `auth`, `not_found`, `timeout`, `unknown`).
- Reuses regex `^[A-Za-z0-9#._-]+` from `skills/fix-ticket/SKILL.md:91` (v6.8.1).

### Dimension 2: Migration UX

**Winner**: **A** (CHANGELOG + light `/check-setup` extension)

**Approach**:

1. **CHANGELOG.md `## v7.0.0` migration block** — use the verbatim template from spec line 95-103 (Czech comment in spec; CHANGELOG content itself in English per project conventions).

2. **README.md migration table** — add 1 table after Installation section:

   | Old name | New name | Reason |
   |---|---|---|
   | `/ceos-agents:status` | `/ceos-agents:pipeline-status` | Short form `/status` collides with Claude Code builtin |
   | `/ceos-agents:init` | `/ceos-agents:setup-mcp` | Short form `/init` collides with Claude Code builtin |
   | `/ceos-agents:create-pr` | `/ceos-agents:publish` (auto-detect) | Removed; `/publish` detects PR-only vs full-publish from branch name |
   | `Extra labels` config section | `PR Rules → Labels` | Duplicate functionality consolidated |

3. **`/check-setup` deprecated-config detector** (light extension, ~10 lines):

   ```
   # Existing check-setup logic ...
   
   ## Deprecated v6.x config detection
   
   if grep -q '^### Extra labels' "$CLAUDE_MD"; then
     echo "[WARN] Deprecated config section: ### Extra labels"
     echo "  Removed in v7.0.0. Move any labels into ### PR Rules → Labels"
     echo "  (which fully supports the use case). See CHANGELOG.md."
   fi
   ```

   Warning, not block. Pipeline still runs (publisher silently ignores `Extra labels` since `agents/publisher.md:69` is removed).

4. **No `/migrate-config` v7 extension** beyond the Phase 7 array-element delete (which Phase 2 already specifies). The `Extra labels` migration is a 1-section, 2-template surface — manual is correct.

**No first-run nudge from core/config-reader.md.** No sentinel comment in user CLAUDE.md. No auto-rewrite.

**Phase 2 citations:**
- Q2: `/check-setup` already enumerates `Extra labels` at line 56 (which gets removed in Phase 7). Adding the `[WARN]` detector reuses the existing scan loop.
- Q1: Only 2 of 8 templates contain `Extra labels`, justifying manual migration.

### Dimension 3: Stub-or-not

**Winner**: **All three (consensus DELETE)**, framed by C's invariant argument.

**Verdict**: **DELETE entirely. No stubs.**

**Rationale**:

1. C's argument is load-bearing: stubs would inflate `find skills -maxdepth 1 -mindepth 1 -type d | wc -l` to 30, breaking the Phase 8 invariant that asserts skill_count == 28 (per Phase 2 Q8 #1: `regression-skill-count-29.sh` updates to expect 28).
2. `/status` and `/init` are Claude Code builtins. A stub at `skills/status/SKILL.md` would be either shadowed by the builtin (invisible) or compete (unpredictable resolution). Either way, the stub fails its own purpose.
3. Workflow-router fallback prose can include a "Did you mean…?" hint for the THREE deprecated identifiers (`/ceos-agents:status`, `/ceos-agents:init`, `/ceos-agents:create-pr`). This is a documentation insertion to existing `skills/workflow-router/SKILL.md`, not a stub skill. Cost: 4 lines. Per B's concession.
4. CHANGELOG + README table + `/check-setup` warn give the user 3 forewarnings before they hit "skill not found." MAJOR version is the social contract; this is sufficient.

**Honest disclosure (per C)**: CHANGELOG must include the line: "Users who type `/ceos-agents:status` or `/ceos-agents:init` after the upgrade will see Claude Code's standard skill-not-found error. There is no aliasing layer — this is intentional to prevent skill-count drift."

### Dimension 4: /create-pr removal

**Winner**: **All three (consensus FULL DELETE)**, framed by C's lost-agency disclosure.

**Approach**: **FULL DELETE**. `git rm -r skills/create-pr/`. No flag, no stub, no soft-deprecation. The auto-detect's three-mode fork (full-publish / pr-only-no-id / pr-only-404) covers every legitimate `/create-pr` use case.

**The deleted-skill-but-needed-PR-only-with-valid-tracker case**: A user with branch `fix/PROJ-123-foo` (issue exists in tracker) who wants to create a PR WITHOUT updating tracker state — this is the only case auto-detect doesn't handle. Resolutions:

1. **Spec says no.** This use case is explicitly out-of-scope per spec design (no `--no-tracker` flag).
2. **Workaround (per A)**: Rename the branch to a non-matching prefix (e.g., `chore/PROJ-123-foo`). Auto-detect extracts no issue ID → mode = pr-only-no-id → PR-only behavior identical to old `/create-pr`.
3. **Disclosure (per C)**: CHANGELOG must explicitly acknowledge this regression: "v7.0.0 removes the ability to opt out of tracker update when the branch matches an existing issue. To create a PR without touching the tracker, use a non-matching branch name (e.g., `chore/refactor-foo` instead of `fix/PROJ-123-foo`)."

**Reuse**: Phase 2 Q4 enumerates 9 reference sites for `/create-pr` to update; Phase 2 Q8 enumerates 3 test files to update. All mechanical.

### Dimension 5: Tracker-down failure UX

**Winner**: **C's format + A's branch-rename hint merged**

**Approach** (three tiers):

#### FAIL tier (`error_type ∈ {timeout, auth, tls, unknown}`)

```
[ceos-agents] 🔴 Pipeline Block
Skill: /ceos-agents:publish
Step: Tracker auto-detect (Step 2)
Reason: Issue tracker unreachable — cannot verify whether '{issue_id}' exists.
Detail: {error_type} error from {tracker_type} MCP: {error_message}
Recommendation:
  1. Run `/ceos-agents:check-setup` to diagnose tracker connectivity.
  2. If you intentionally want a PR with no tracker update, rename your
     branch to one that does NOT start with the configured Branch naming
     prefix (e.g., from "fix/PROJ-123-foo" to "chore/PROJ-123-foo"),
     then re-run /publish. Auto-detect will fall through to PR-only mode.
  3. If the tracker is intentionally offline, create the PR manually:
     git push -u origin {branch} && gh pr create
     (or your tracker UI's equivalent)
  4. Once the tracker is reachable, re-run `/ceos-agents:publish`.
```

#### 404 WARN tier (`error_type == "not_found"`)

```
[ceos-agents][WARN] Branch '{branch}' contains issue ID pattern '{issue_id}'
but no matching ticket was found in {tracker_type}.
Creating PR without tracker update.
```

Single line, INFO/WARN level, stdout (NOT block channel). Pipeline continues with PR-only mode. The `Tracker:` row in the final Publish Report (Dimension 1 Step 8) carries the same info for post-hoc visibility.

#### No-issue-id INFO tier (issue_id == null after extraction)

```
[ceos-agents][INFO] Branch '{branch}' does not match the configured Branch
naming pattern. Creating PR without tracker contact.
```

INFO level — non-matching branch is *probably* intentional (user named it `chore/refactor-foo`); should not look alarming. Pipeline continues with PR-only mode.

**Format alignment with CLAUDE.md "Block Comment Template" (per C):**
- FAIL tier uses exact `[ceos-agents] 🔴 Pipeline Block` prefix per CLAUDE.md "Block Comment Template" — machine-parseable by `/resume-ticket` and webhook consumers.
- WARN/INFO tiers use `[ceos-agents][WARN]` / `[ceos-agents][INFO]` prefix — same machine-parseable family, lower severity.
- `Skill:` field (not `Agent:`) for skill-level blocks. C's correct convention.
- 4-step Recommendation list (not prose) — operators in panic mode read step 1, ignore the rest if it works.

**Webhook semantics**: FAIL tier fires the existing `pipeline-completed` event with `outcome: failed` per v6.9.0 contract. No new `tracker-down` event in v7.0.0 (deferred to v7.0.1+ per B's own concession).

## Open questions for Phase 4 (spec)

These clarifications must land in the Phase 4 spec before Phase 7 implementation:

1. **Step 0 / Step 1 ordering for `/publish`** (R1): the Phase 4 spec MUST explicitly require pre-pre-flight branch parse (issue_id extraction) BEFORE MCP pre-flight, gating Step 1 (MCP pre-flight) on `tracker_needed`. Spec line 61-85 gives the auto-detect logic but never addresses Step 0; Phase 7 will copy verbatim and break PR-only mode without this clause.

2. **error_type "unknown" disposition**: Phase 4 spec must EXPLICITLY enumerate the 5 error_type buckets and assert `unknown → FAIL` (defensive default). Spec line 81-83 says only "tracker nedostupný (5xx/timeout/MCP error)"; "5xx" is not a `core/mcp-detection.md` classification. Use the exact 5-bucket vocabulary: `tls`, `auth`, `not_found`, `timeout`, `unknown`.

3. **"Tracker registered but no get_issue-shaped tool found" disposition** (R3): Phase 4 spec must enumerate the prefix-has-tools-but-no-get-issue case → classify as `error_type = "unknown"` → FAIL. This closes the future-tracker-type gap (e.g., Asana with non-standard tool names).

4. **Publish Report `Tracker:` row format** (R2): Phase 4 spec must specify the three exact strings the publisher agent emits in its report:
   - `Tracker: Updated → For Review`
   - `Tracker: Skipped — issue ID '{X}' not found in {tracker_type}`
   - `Tracker: Skipped — no issue ID in branch name`

5. **Operator note: `/publish` is interactive-only** (R5): Phase 4 spec usage section should add a brief note that `/publish` will FAIL in environments without MCP (CI/cron); headless path is `/ceos-agents:autopilot`.

6. **State.json forward-compat for v6.10.x → v7.0.0 mid-pipeline** (R7): Phase 4 spec migration guide should add a one-liner: "In-flight pipelines from v6.10.x continue to work — state.json schema is unchanged. Renames affect only skill invocation."

7. **Phase 8 verification: empty-directory invariant** (R8): Phase 8 verification commands list must add an empty-skills-dir check (`find skills -maxdepth 1 -mindepth 1 -type d -empty`). Phase 7 must use `git rm -r skills/status` (NOT `mkdir + cp`) to avoid leaving orphan directories on Windows.

8. **Migration guide acknowledgment of lost user agency** (Dimension 4): Phase 4 spec migration guide must explicitly state that `/create-pr`'s "PR-only with valid tracker reference" case is no longer supported, and document the branch-rename workaround.

9. **CHANGELOG entry on skill-not-found error** (Dimension 3): Phase 4 spec migration guide must include the disclosure that `/ceos-agents:status` and `/ceos-agents:init` produce Claude Code's standard skill-not-found error post-upgrade (no aliasing).

10. **Workflow-router "Did you mean…?" prose** (Dimension 3): Phase 4 spec must specify whether the deprecated-name fallback prose is added to `skills/workflow-router/SKILL.md`. If yes, exact placement and 4-line content.

11. **`/check-setup` deprecated-config WARN exit semantics**: Does the new `[WARN]` for `### Extra labels` change the `/check-setup` exit code? Recommendation: no (warning, not failure) — but spec must say so explicitly to avoid Phase 7 ambiguity.

## Synthesis Notes

- **Base proposal**: **C (Skeptical)** with selective merges from A (Conservative).
- **From A merged in**:
  - Surgical Steps 1-3 scope philosophy (reuse publisher agent, only context string changes).
  - CHANGELOG + light `/check-setup` extension migration philosophy (reject B's auto-rewrite + sentinel).
  - Branch-rename escape hatch in tracker-down recovery (recovery option 2).
- **From B merged in**:
  - Workflow-router "Did you mean?" fallback prose for deprecated names (one of B's few salvageable ideas — small, useful).
  - The pre-publish `[INFO]` line per mode (matching what A also proposed) — single line, NOT B's full 4-line ASCII banner.
- **From C base**:
  - R1 mitigation (pre-pre-flight branch parse, gated MCP pre-flight) — CRITICAL.
  - R2 Publish Report `Tracker:` row.
  - R3 future-tracker-type fork (`prefix-has-tools-but-no-get-issue` → unknown → FAIL).
  - R4-R5 explicit error_type fork including unknown → FAIL.
  - R7-R8 forward-compat clauses for Phase 4.
  - Three-tier output structure (FAIL block / 404 WARN / no-match INFO) with `[ceos-agents]`-prefixed CLAUDE.md Block Comment Template format.
  - Lost user-agency disclosure for `/create-pr` removal.
- **All anti-patterns avoided**: ✓
  - No new config keys.
  - No `--no-tracker` flag.
  - No `/create-pr` revival.
  - No deferral of any of the 6 actions (all in v7.0.0).
  - No CHANGELOG bikeshedding (spec template used verbatim).
  - No runtime-impossible deprecation banners.
- **v7.0.0 FINÁLNÍ scope unchanged**: ✓ (6 actions, 4 breaking + 2 doc, 28 skills, 18 config sections, 21 agents).
- **Confidence in recommendation**: **0.86**

  Confidence basis:
  - Spec is internally consistent for the happy path; 11 open questions are clarifications, not redesigns.
  - R1 (Step 0 ordering) is a real gap that all three personas + judge converge on after analysis.
  - All disagreements resolved with rationale citing Phase 2 findings or CLAUDE.md conventions.
  - Phase 2 verification commands and HARD-FAIL test inventory (Q8) are mechanical — execution risk only, not design risk.
  - Residual 0.14 risk: Phase 7 Windows execution (R8 empty-dir hazard) and surface area of branch-naming template parsing (Q6) — both flagged for Phase 4 spec to constrain explicitly.
