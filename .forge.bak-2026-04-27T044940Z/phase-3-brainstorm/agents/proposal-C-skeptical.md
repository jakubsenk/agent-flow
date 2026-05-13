# Proposal C — Skeptical (Contrarian SRE)

**Persona stance:** Every "clean rename" I have shipped in 15 years has broken something for an unknown user we never modeled. The spec is internally consistent for the happy path; my job is to enumerate the *quiet* paths and pin down the failure mode of each, *within the spec's stated constraints* (no new config keys, no `--no-tracker` flag, no soft-deprecation of `/create-pr`).

**Verdict up-front:** I accept the v7.0.0 scope. I do not propose adding flags or stub skills. But I demand explicit, written behavior for **eight** corners the spec is silent on, because Phase 7 will otherwise pick the wrong default by accident.

---

## Dimension 1 — `/publish` auto-detect implementation strategy

**Strategy: literal, defensive, fail-loud.**

Current `skills/publish/SKILL.md` Step 1 is a one-liner ("Determine the current branch and issue ID"). Step 0 already runs MCP pre-flight via the same idiom that lives at the top of `skills/create-pr/SKILL.md` and `skills/status/SKILL.md`. **The MCP pre-flight at Step 0 is the load-bearing piece** — and it is the source of my biggest objection (see Edge Case E1 below): Step 0 currently STOPs unconditionally on missing MCP, which is incompatible with the auto-detect's "PR-only mode" branch. Step 0 must be **softened** to a soft-warn for `/publish` only — or auto-detect must run *before* Step 0 to decide whether MCP is needed at all.

I propose **option B — auto-detect runs before MCP pre-flight**:

```
Step 0 (NEW — pre-pre-flight): Branch parse → determine if tracker contact is needed.
  a. issue_id_extracted = parse_branch_name(git branch --show-current, Branch naming)
  b. If issue_id_extracted is null → set tracker_needed = false; skip to Step 1 (PR-only path)
  c. Else → set tracker_needed = true; proceed to Step 0a

Step 0a (renamed from Step 0 — MCP pre-flight, GATED): Only if tracker_needed:
  - Existing pre-flight check from current Step 0
  - On failure: emit FAIL message (verbatim from Dim 5)

Step 1 (NEW): If tracker_needed:
  - MCP call to fetch issue (prefix-scan per core/mcp-detection.md)
  - 3-way fork: found / 404 / 5xx-ish

Step 2-N: existing publisher dispatch path, gated on outcome
```

**Reuse rules** (no new logic, no invented regex):
- Branch parsing: reuse the strip-prefix pattern from Phase 2 Q6, with the `^[A-Za-z0-9#._-]+` regex from `skills/fix-ticket/SKILL.md:91`. **Do not invent a new capture-group regex.**
- MCP call: prefix-scan per `core/mcp-detection.md:36` ("Scan available tools for at least one tool matching the prefix"). The LLM picks the `get_issue`-shaped tool at runtime.
- Error classification: reuse the 5-bucket priority table from `core/mcp-detection.md:73-83` (tls / auth / not_found / timeout / unknown).

**3-way fork — explicit (refining Dim 7's spec language):**

| Outcome | Trigger | Action |
|---|---|---|
| Issue found | MCP call returns issue object | Full publisher dispatch (haiku, current Step 5) |
| Issue not found | `error_type == "not_found"` | PR-only mode + WARN line (no tracker update) |
| Tracker unreachable | `error_type` ∈ {`timeout`, `auth`, `tls`, `unknown`} | FAIL with guidance (verbatim Dim 5) |

**Why merge `auth` and `tls` into FAIL, not into PR-only:** an auth or TLS error is a *configuration* problem the user must fix; silently degrading to PR-only would publish a PR that the next `/publish` would then update inconsistently when the auth issue is resolved. That asymmetry is a bug-magnet. FAIL forces resolution.

**Why merge `unknown` into FAIL, not into PR-only:** the spec says "tracker down → fail." `unknown` is the catch-all. Defaulting `unknown` to PR-only would produce inconsistent behavior over time as MCP servers add new error codes. Conservative default = FAIL on anything other than `not_found`.

---

## Dimension 2 — Migration UX (first run after upgrade)

**The spec gives users a CHANGELOG migration block. That is the floor. I propose a soft ceiling.**

**No interactive deprecation banners** — Claude Code does not support per-skill first-invocation hooks. A persona-B-style "stretch" feature is out of scope (the Anti-Patterns block forbids runtime support that doesn't exist).

**What we SHOULD do — three layered touch-points:**

1. **CHANGELOG migration block** — mandatory, spec-mandated, lives in `CHANGELOG.md` under `## v7.0.0`. Use the verbatim template from spec line 95-103.

2. **Two README sections (action 6)** — collision warning AND migration table:
   ```markdown
   ### Migrating from v6.x

   v7.0.0 contains breaking renames and deletions. See CHANGELOG for full migration.

   | Old name | New name | Reason |
   |---|---|---|
   | `/ceos-agents:status` | `/ceos-agents:pipeline-status` | Short form `/status` collided with Claude Code builtin |
   | `/ceos-agents:init`   | `/ceos-agents:setup-mcp`     | Short form `/init` collided with Claude Code builtin |
   | `/ceos-agents:create-pr` | `/ceos-agents:publish` (auto-detect) | Removed; `/publish` now detects PR-only vs full-publish from branch name |
   | `Extra labels` config section | `PR Rules → Labels` | Duplicate functionality consolidated |
   ```

3. **`/check-setup` migration helper (NO new flag)** — extend the existing `skills/check-setup/SKILL.md` MCP/config validation to **detect deprecated config**:
   - If `Extra labels` section is found in CLAUDE.md → emit `[WARN] 'Extra labels' section is deprecated in v7.0.0. Migrate labels to 'PR Rules → Labels'.`
   - If user's CLAUDE.md still says "29 skills" or "19 optional" → emit `[INFO] CLAUDE.md count strings reference v6.x. Update to 28 skills / 18 optional sections.`
   - **No behavior change** to `/check-setup` exit codes — these are warnings, not blocks. This is doc-grep additive logic, not a new feature, not a new config key, not a flag. **Within the spec's no-scope-creep constraint.**

**What I refuse to ship:** a `/migrate-config v7` sub-skill (Persona B's idea). The existing `/migrate-config` skill already enumerates `Extra labels` per Phase 2 Q2 (line 41) — when we delete that array element in Phase 7, the existing skill no longer touches `Extra labels`. That is sufficient. A new sub-skill is over-engineering for a 4-action breaking release.

---

## Dimension 3 — Stub-or-not for renamed skills

**Verdict: NO STUBS. Spec wins.** The spec says "delete entirely"; I agree, but for a different reason than spec implies.

Persona A's argument for stubs: "be kind to users." Persona B: "delete cleanly." **I read the spec literally and check the runtime contract.**

**Hard constraint that kills the stub idea:** Claude Code skills are dispatched by name match against `.claude-plugin/`-loaded skill directories. If we leave `skills/status/SKILL.md` as a one-liner saying "Renamed to /ceos-agents:pipeline-status", that file:
1. Counts toward `find skills -maxdepth 1 -mindepth 1 -type d | wc -l` → skill count becomes 30, not 28. Phase 8 invariant FAILS.
2. Forces us to maintain TWO directories with the same logical purpose for the v7.0.0 lifetime. Future contributors adding a feature to `pipeline-status` must remember to also touch the stub.
3. The `regression-skill-count-29.sh` test (Phase 2 Q8 #1) expects `-eq 28`. A stub would force `-eq 30`. Test must be rewritten to handle stubs as second-class — fragile.

**What we ACCEPT instead:** Claude Code will emit its standard "skill not found" error when a user types `/ceos-agents:status`. That error is generic but *correct* — the skill genuinely does not exist. The README migration table (Dim 2) is the discoverability surface; the CHANGELOG is the authoritative source.

**Caveat / honest disclosure to add to CHANGELOG:** "Users who type `/ceos-agents:status` after the upgrade will see Claude Code's standard skill-not-found error. There is no aliasing layer — this is intentional to prevent skill-count drift and double-maintenance burden."

This is the kind of honesty the spec demands: don't pretend, don't sugar-coat, document the failure mode.

---

## Dimension 4 — `/create-pr` removal vs flag

**Verdict: FULL DELETE. Auto-detect subsumes it correctly.**

I read `skills/create-pr/SKILL.md` (28 lines total). The functional delta vs `/publish` is:
- Step 4 in `/create-pr`: "Create a PR using PR Rules + label ID resolution"
- Step 5-7 in `/publish` (via publisher agent): "Create a PR + update tracker state + comment"

**The auto-detect's `not_found` branch produces the EXACT behavior of `/create-pr`** — PR created, no tracker update. So `/create-pr` becomes a degenerate case of `/publish` when the branch has no extractable issue ID.

**Edge case the spec misses:** what if a user EXPLICITLY wants PR-only behavior but their branch *does* have an extractable issue ID and *that* issue exists in the tracker? Under auto-detect, they get full publish (tracker update + comment). They cannot opt out. This is a real loss of control that v6.10.x users had.

**Mitigation within spec constraints (no `--no-tracker` flag allowed):**
- Document this in CHANGELOG: "v7.0.0 removes the ability to opt out of tracker update when the branch matches an existing issue. To create a PR without touching the tracker, use a non-matching branch name (e.g., `chore/refactor-foo` instead of `fix/PROJ-123-foo`)."
- This is a real downgrade in user agency. We are accepting it because the spec is firm. **But Phase 4 spec MUST acknowledge this regression in the Migration guide.**

**No flag added. No skill resurrected. Full delete.**

---

## Dimension 5 — Tracker-down failure UX (exact text)

The spec gives us baseline language at line 82-84. I propose this **verbatim** for Phase 4:

```
[ceos-agents] 🔴 Pipeline Block
Skill: /ceos-agents:publish
Step: Tracker auto-detect (Step 1)
Reason: Issue tracker unreachable — cannot verify whether '{issue_id}' exists.
Detail: {error_type} error from {tracker_type} MCP: {error_message}
Recommendation:
  1. Run `/ceos-agents:check-setup` to diagnose tracker connectivity.
  2. If the tracker is intentionally offline, create the PR manually:
     git push -u origin {branch} && gh pr create   (or your tracker's equivalent)
  3. Once the tracker is reachable, re-run `/ceos-agents:publish` to update the issue state.
```

**Why this exact shape:**
- Uses `[ceos-agents] 🔴 Pipeline Block` per CLAUDE.md "Block Comment Template" → machine-parseable by `/resume-ticket` and webhook consumers.
- `Skill:` not `Agent:` — this is a skill-level block, not an agent block.
- `Step:` field cites Step 1 of the auto-detect logic (per Dim 1 numbering).
- `Detail:` includes the error_type classification — operators triaging via grep can filter `tls` vs `auth` vs `timeout` quickly.
- `Recommendation` is **3 numbered steps** (not prose), because users in panic mode read step 1, ignore the rest if it works.
- **Recommendation 2 is critical** — manual escape hatch. If the tracker has been down for 4 hours and the user MUST ship a PR, they have a copy-pasteable command. No new flag, no new feature; just operator empowerment.

**For the `not_found` (404) case (PR-only + WARN), separate text:**

```
[ceos-agents][WARN] Branch '{branch}' contains issue ID pattern '{issue_id}'
but no matching ticket was found in {tracker_type}.
Creating PR without tracker update.
```

Single-line, INFO-level, stdout (not block channel). Pipeline continues.

**For the `extraction failed` case (no issue ID in branch), a third tier:**

```
[ceos-agents][INFO] Branch '{branch}' does not match the configured 'Branch naming'
pattern. Creating PR without tracker contact.
```

INFO-level — a non-matching branch is *probably* intentional (user named it `chore/refactor-foo`), so this should not look alarming.

---

## Risk Mitigation (LARGEST section per persona-C contract — 8 risks)

### R1 — MCP pre-flight Step 0 conflicts with PR-only mode (CRITICAL)

**The hidden corner:** `skills/publish/SKILL.md:12-17` currently has an unconditional MCP pre-flight at Step 0. It STOPs the skill if MCP is unavailable. **Under auto-detect, when the branch has no issue ID, MCP is irrelevant — but Step 0 still STOPs.**

**Spec silence:** the spec's auto-detect logic block (lines 61-85) mentions "MCP call: tracker.getIssue(issue_id)" as Step 4 of the new flow but never addresses the existing Step 0.

**Probe result:** A user on a branch named `chore/refactor-foo` with NO MCP server provisioned (the BIFITO autopilot pilot scenario, where MCP is configured but not always reachable on the dev workstation) would, under naive Phase 7 implementation, hit Step 0 and STOP. They cannot create a PR for a non-tracker branch. This is a regression vs v6.10.x where `/create-pr` had its own Step 0 that the same user would hit, but `/create-pr`'s Step 0 was the same blocker — *so today the workflow simply does not exist.*

**Mitigation:** Phase 4 spec MUST explicitly require Step 0 to be **gated by `tracker_needed` boolean** computed in the new pre-pre-flight (Dim 1). Three lines of pseudo-code in the spec are sufficient. **Without this, Phase 7 will copy Step 0 verbatim and break PR-only mode.**

### R2 — Branch matches `Branch naming` regex but issue ID is bogus

**The hidden corner:** A user creates branch `fix/abc-temp-experiment` because they were prototyping. The `Branch naming` template `fix/{issue-id}-{description}` matches; `parse_branch_name` extracts `abc` as issue_id; `tracker.getIssue("abc")` returns `not_found`; auto-detect creates a PR-only with WARN.

**Is this correct?** Yes — but the WARN must be loud enough that the user notices their branch was *interpreted* as a tracker reference. If we suppress the WARN, the user assumes the PR was tracker-linked and is later confused why no tracker update happened.

**Spec silence:** spec line 76-79 says "Branch obsahuje vzor issue ID '{issue_id}' ale ticket nenalezen v trackeru" — the warning text is fine. But the spec does not require the warning to surface in the **pipeline output footer** (the publish report).

**Mitigation:** The `Publish Report` (publisher agent line 82-87) MUST include a `Tracker:` row with one of:
- `Updated → For Review` (full publish)
- `Skipped — issue ID '{X}' not found in {tracker_type}` (404 path)
- `Skipped — no issue ID in branch name` (extraction failed path)

This makes the auto-detect's *decision* visible in the user-facing report, not buried in stderr.

### R3 — Tracker types we don't list (e.g., future Asana)

**The hidden corner:** The spec lists 6 tracker types (youtrack, github, jira, linear, gitea, redmine). What if a user adds `Type: asana` to their config and wires up an `mcp__asana__*` server? `core/mcp-detection.md:34` says: "(unknown) → `mcp__{tracker_type}__*` (best-effort)". So MCP detection works.

But **the auto-detect's tool-name discovery** (Dim 1 phrase: "locate the single-issue fetch tool, typically a `get_issue` or `getIssue` variant") is LLM-dispatched per `core/mcp-detection.md:36`. The LLM scans available tools for one matching `mcp__asana__*` AND a name like `get_*` or `*_issue*`. If the Asana MCP server uses a different convention (e.g., `mcp__asana__fetch_task_by_id`), the LLM may pick the wrong tool or fail to find one.

**Spec silence:** what is the behavior when prefix-scan finds NO tool matching the issue-fetch shape, even though the tracker prefix has tools registered?

**Mitigation:** Treat "prefix has tools but no issue-fetch shape found" as `error_type: "unknown"` → FAIL path. Phase 4 spec must add this branch. Concrete:

```
If MCP tool prefix has matching tools but no get_issue-shaped tool can be invoked:
  → error_type = "unknown"
  → FAIL with: "Tracker type '{type}' is registered but the integration does not
     expose an issue-fetch tool. Run /ceos-agents:check-setup to diagnose."
```

### R4 — User has NO MCP server provisioned but tracker_type is set in config

**The hidden corner:** A new user runs `/ceos-agents:setup-mcp`, the wizard runs, but the user closes the wizard before MCP servers are actually installed. CLAUDE.md says `Type: gitea` but no `mcp__gitea__*` tool is registered.

**Probe (per persona-C task instruction):** Does auto-detect FAIL or fall through to PR-only?

**Per `core/mcp-detection.md:67`:** "No matching MCP tool found → Return `mcp_available: false`, `error: "No MCP tool matching prefix..."`, `error_type: "unknown"`. Caller decides whether to block or downgrade."

**Per Dim 1's 3-way fork:** `error_type == "unknown"` → FAIL.

**Verdict:** The user gets a FAIL with the standard message ("Tracker unreachable..."). They run `/ceos-agents:check-setup`, which tells them no MCP server is registered. They install the MCP server. They retry. **This is the right behavior.** The alternative — silently degrading to PR-only when MCP is missing — would create the BIFITO scenario where users assume the tracker is being updated when it is not.

**Mitigation:** Phase 4 spec must explicitly state: "Missing MCP server is treated as `error_type: unknown` → FAIL path. There is no auto-fallback to PR-only mode based on MCP availability." This closes the "what if user is on plane / CI / no MCP" loophole that Persona B might want to soft-handle.

### R5 — CI/cron contexts where MCP is unavailable

**The hidden corner:** A CI runner invokes `claude -p "Run /ceos-agents:publish" --dangerously-skip-permissions` after a build succeeds. MCP servers may not be configured in the CI environment (token storage / network restrictions).

**Spec silence:** spec is silent on CI semantics for `/publish`.

**Probe result:** Per R4, this fails loudly. CI logs show the FAIL message. Operator either (a) configures MCP in CI, or (b) does not call `/publish` from CI (uses raw `gh pr create` instead).

**Why I am OK with this:** `/publish` is a *destructive* skill (per workflow-router line 55). Destructive skills should not silently degrade in headless contexts — they should fail loudly. **The Autopilot pattern is the supported headless path** — Autopilot runs `/fix-ticket` and `/implement-feature` (which include their own publish steps), not `/publish` directly.

**Mitigation:** Phase 4 spec should add a brief Operator note: "`/publish` is intended for interactive use. For headless CI/cron, use `/ceos-agents:autopilot` or invoke the underlying git/gh tooling directly. `/publish` will FAIL in environments where the configured MCP server is unreachable, by design."

### R6 — Autopilot dispatcher does not reference renamed skills (VERIFIED CLEAN)

**Probe (per persona-C task instruction):** I grepped `skills/autopilot/SKILL.md` for `create-pr`, `/ceos-agents:status`, `/ceos-agents:init`. **Zero matches.** Per `skills/autopilot/SKILL.md:373-378`, autopilot dispatches only `/ceos-agents:fix-ticket` and `/ceos-agents:implement-feature`. The BIFITO autopilot pilot is unaffected by the v7.0.0 renames.

**Verdict:** No mitigation needed — autopilot is clean. Documenting this here so Phase 7 doesn't waste a research cycle re-verifying.

### R7 — User upgrades during a paused (NEEDS_CLARIFICATION) pipeline

**The hidden corner:** User has an active state.json at `.ceos-agents/PROJ-42/state.json` with `status == "paused"` from v6.10.0. They upgrade to v7.0.0 and run `/ceos-agents:resume-ticket PROJ-42`. The state.json may include references to `/ceos-agents:init` in clarification answers (user typed "I ran /ceos-agents:init and it said X").

**Spec silence:** the spec does not address mid-pipeline upgrades.

**Probe result:** state.json content is user-text data; the consuming logic is `resume-ticket` parsing the clarification response. The renamed skills do not appear in `state.json` *schema* — only in user-typed prose. Functional impact: zero.

**Mitigation:** Phase 4 spec should add a one-liner under Migration guide: "In-flight pipelines from v6.10.x continue to work with v7.0.0 — state.json schema is unchanged. The renames affect only skill invocation, not state."

### R8 — Phase 8 verification commands assume happy path

**The hidden corner:** The Phase 2 verification commands (final.md lines 535-639) check "skill count = 28" via `find skills -maxdepth 1 -mindepth 1 -type d`. But if Phase 7 leaves an empty `skills/status/` directory (e.g., partial git mv on Windows), the count is still 29, the test "passes" structurally, and Phase 8 doesn't catch the orphan.

**Mitigation:** Phase 4 spec must require Phase 7 to use `git rm -r skills/status` (NOT `mkdir skills/pipeline-status && cp -r skills/status/* skills/pipeline-status/`). And Phase 8 verification must add an explicit check:

```bash
[ -z "$(find skills -maxdepth 1 -mindepth 1 -type d -empty)" ] \
  && echo "skills/: no empty dirs OK" \
  || echo "skills/: empty directories present (FAIL)"
```

This is the kind of "trust but verify" that catches the partial-rename failure mode. **Without this, a Phase 7 hiccup on Windows (where some operations are non-atomic) could ship a 29-skill plugin that *advertises* 28.**

---

## Edge Cases Identified (>= 3 required; I list 8)

Summary table cross-referencing risks above:

| # | Edge case | Spec silent? | Mitigation |
|---|---|---|---|
| E1 | MCP pre-flight Step 0 conflicts with PR-only mode | Yes | R1 — gate Step 0 by `tracker_needed` |
| E2 | Branch matches naming regex but issue ID is bogus | Partially | R2 — surface decision in Publish Report |
| E3 | Future tracker type (Asana etc.) with non-standard tool name | Yes | R3 — treat as `error_type: unknown` |
| E4 | User has tracker config but no MCP server provisioned | Yes | R4 — FAIL, not silent PR-only |
| E5 | CI/cron contexts where MCP is unavailable | Yes | R5 — document `/publish` as interactive-only |
| E6 | Autopilot dispatcher references to renamed skills | Yes (verified clean) | R6 — none needed; autopilot is clean |
| E7 | Mid-pipeline (paused) upgrade from v6.10.x | Yes | R7 — document state.json forward-compat |
| E8 | Phase 8 verification missing empty-dir check | Yes | R8 — add empty-dir invariant |

---

## Spec amendments I require for Phase 4

To translate this proposal into the formal spec, Phase 4 must add the following text (in spec language, not in this proposal's prose):

1. **Step 0 gating clause** for `/publish`: explicit `tracker_needed` boolean computed before MCP pre-flight. (R1)
2. **Publish Report `Tracker:` row** with three states. (R2)
3. **`error_type: unknown` fork** explicitly listed in the auto-detect logic. (R3, R4)
4. **Operator note: `/publish` is interactive-only** in the usage section. (R5)
5. **Forward-compat clause** for in-flight v6.10.x pipelines. (R7)
6. **Phase 8 empty-directory check** in the verification commands. (R8)
7. **Migration guide acknowledgment** of the lost user agency from `/create-pr` removal (no opt-out for tracker-matching branches). (Dim 4)
8. **CHANGELOG note** that `/ceos-agents:status` and `/ceos-agents:init` produce Claude Code's standard skill-not-found error after upgrade. (Dim 3)

These are all *clarifications*, not scope additions. They cost a Phase-4 spec update of ~50 lines but prevent Phase 7 from picking 8 wrong defaults.

---

## What I am NOT proposing (anti-patterns I deliberately reject)

- ❌ Stub `skills/status/SKILL.md` and `skills/init/SKILL.md` that print rename messages. **Rejected:** breaks skill count, doubles maintenance.
- ❌ `--no-tracker` flag for `/publish`. **Rejected:** spec forbids; auto-detect is the contract.
- ❌ `/migrate-config v7` sub-skill. **Rejected:** existing `migrate-config` skill suffices once Phase 7 deletes the `Extra labels` array element.
- ❌ Soft-deprecation cycle for `/create-pr` (one minor cycle). **Rejected:** v7.0.0 is MAJOR; clean break is correct per CLAUDE.md versioning policy.
- ❌ Interactive deprecation banners on first invocation. **Rejected:** runtime does not support per-skill first-invocation hooks.
- ❌ New config keys. **Rejected:** spec forbids; all decisions are in Automation Config that already exists or in branch-name parsing logic.

---

## Summary table — Skeptical positions vs spec

| Dimension | Spec position | My position | Delta |
|---|---|---|---|
| 1 (auto-detect impl) | Step 1-3 rewrite of `/publish` | Step 1-3 + soften Step 0 to gated pre-flight | ADD: gating logic |
| 2 (migration UX) | CHANGELOG migration block | CHANGELOG + README table + `/check-setup` warns | EXTEND: 2 advisory layers |
| 3 (stubs) | Delete entirely | Delete entirely (agree); document failure mode honestly | AGREE + disclose |
| 4 (`/create-pr` removal) | Full delete | Full delete (agree); acknowledge lost agency in CHANGELOG | AGREE + disclose |
| 5 (tracker-down UX) | Baseline language | Refined 3-tier (FAIL block / 404 WARN / no-match INFO) + manual escape hatch | REFINE |

---

DONE — proposal-C-skeptical.md written, dimensions 1-5 addressed, 8 edge cases identified
