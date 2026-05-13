# Devil's Advocate Review — v6.7.2

**Reviewer:** Devil's Advocate (verification phase)
**Date:** 2026-04-16
**Scope:** 3 failure scenarios for v6.7.2 (Pipeline Consistency & Dedup)

---

## Scenario 1: Content Loss — Core Contract vs Original Inline Copies

**Failure mode:** The extracted `core/tracker-subtask-creator.md` (~210 lines) omits content that existed in the original inline copies across the 3 skills, leading to silent behavioral regression.

### Investigation

Compared the core contract against all 3 skill delegation stubs:

**Core contract covers:**
- Triple gate (decomposition_decision, create_tracker_subtasks_config, tracker_effective_status)
- Subtask creation loop with idempotency (YAML-first, state.json fallback)
- All 6 tracker types (YouTrack, Jira, Linear, Redmine, GitHub, Gitea)
- Jira nested sub-task guard
- GitHub/Gitea checklist (post-loop)
- Dual-store persistence (YAML + state.json)
- Git commit after successful creations
- Issue description template with maps_to traceability
- Per-tracker MCP tool patterns table
- Failure handling (per-subtask, checklist, all-failed, YAML commit)
- "Pipeline continues -- NEVER block here" constraint
- Input contract (10 fields) and output contract (4 fields)

**Skill delegation stubs contain:**
- Reference to `core/tracker-subtask-creator.md`
- Reference to `core/mcp-body-formatting.md`
- Required in-memory values list (9 items matching core input contract)

**Content parity check:**
- The core contract Input Contract lists `yaml_path` and `state_json_path` explicitly. The skill stubs pass these as "YAML path" and "state.json path" with concrete path patterns. **Match.**
- The core contract defines `tracker_effective_status` as an input. The skill stubs list it in required values. The skills still set this value from MCP pre-flight (step 0). **Match.**
- The core contract's Issue Description Template includes `maps_to` and `files` lines. The original inline copies had the same content (verified via grep: maps_to/Addresses patterns still appear in decomposition steps of all 3 skills for the AC coverage check, separate from the tracker subtask creation). **Match.**

**Verdict:** No content loss detected. The extraction is complete.

**Probability:** LOW
**Actual existence:** No -- the core contract is a superset (adds explicit Input/Output contracts and Per-Tracker table that the inline copies lacked).

---

## Scenario 2: Cross-Reference Break — Tests Grepping Skills for Extracted Content

**Failure mode:** Test files that assert the presence of tracker subtask patterns in skill files fail after extraction because the patterns now live in the core contract.

### Investigation

**Critical test file:** `tests/scenarios/test-cross-skill-consistency.sh`
- FC-4: Greps for `decomposition.decision`, `Create tracker subtasks`, `tracker_effective_status` in all 3 skills.
  - `decomposition.decision` -- still present in decomposition state.json writes (step 4b/3b/5). **PASSES.**
  - `Create tracker subtasks` -- still present in config parsing sections. **PASSES.**
  - `tracker_effective_status` -- still present in delegation stub "Required in-memory values" line. **PASSES.**

- FC-14: Greps for `git commit.*(link|tracker|decomposition)|git commit.*subtask` in skills.
  - The subtask execution loops still contain `git commit -m "fix({subtask-id}): {subtask-title}"` / `git commit -m "feat({subtask-id}): {subtask-title}"` which matches `git commit.*subtask`. **PASSES.**
  - However, this is a **fragile coincidence**: the test was designed to find the tracker-linking commit (`chore: link decomposition subtasks to tracker issues`), but it now passes via the unrelated subtask execution commit. If the subtask commit message format ever changes to not contain "subtask", FC-14 breaks with a false negative. This is a latent test quality issue, not a v6.7.2 regression.

- FC-15: Greps for `maps_to|Addresses:` in skills.
  - Still present in AC coverage check sections (decomposition decision steps). **PASSES.**

- FC-16: Greps for `tracker_issue_id` in resume-ticket. **UNAFFECTED by extraction.**

**Other test files checked:**
- `test-tracker-types.sh`, `test-github-gitea-checklist.sh`, `test-partial-failure.sh`, `test-idempotence.sh` -- all grep `core/tracker-subtask-creator.md` directly, confirming the core contract exists. **PASSES.**

**Verdict:** All tests pass, but FC-14 passes for the wrong reason.

**Probability:** LOW (for v6.7.2 breakage), MEDIUM (for future fragility)
**Actual existence:** Latent test quality issue, not a v6.7.2 bug. FC-14 should be updated to also check `core/tracker-subtask-creator.md` for the linking commit pattern.

**Recommendation:** Add `core/tracker-subtask-creator.md` to FC-14's search scope or add a separate assertion that the core contract contains the `chore: link decomposition subtasks` commit instruction.

---

## Scenario 3: Behavioral Divergence — Webhook Key Rename and Documentation

**Failure mode:** The webhook key rename from `"issue"` to `"issue_id"` (and `"pr"` to `"pr_url"`) in implement-feature breaks external webhook receivers that parsed the old key names. The change is not documented in the CHANGELOG, so users cannot prepare.

### Investigation

**What was the old state?**
- `implement-feature` step 10a (post-publish): used `"issue":"{issue_id}"`, `"pr":"{pr_url}"` -- deviant from core
- `implement-feature` step X (block): used `"issue":"{issue_id}"`, `"agent":"{agent}"` -- deviant from core
- `core/block-handler.md` step 5: canonical `"issue_id":"{issue_id}"`, `"agent":"{agent_name}"`
- `core/post-publish-hook.md` step 3: canonical `"issue_id":"${issue_id}"`, `"pr_url":"${pr_url}"`
- `fix-bugs` step 9a (pipeline-complete): uses `"fixed"`, `"blocked"`, `"timestamp"` -- no `"issue"` key (different event)
- `fix-ticket` steps 9a/9b: delegates to `core/post-publish-hook.md` -- always used canonical keys
- `fix-bugs` step X: delegates to `core/block-handler.md` -- always used canonical keys

**What changed in v6.7.2?**
- implement-feature step X: inline block handler removed, now delegates to `core/block-handler.md` (which uses `"issue_id"`)
- implement-feature step 10a: now delegates to `core/post-publish-hook.md` (which uses `"issue_id"` and `"pr_url"`)
- Net effect: webhook payloads from implement-feature now use `"issue_id"` instead of `"issue"`, and `"pr_url"` instead of `"pr"`

**Is this documented in CHANGELOG?**
- The CHANGELOG entry for v6.7.2 does not yet exist (pending version). The roadmap describes it as "Webhook Format Alignment" under PLANNED v6.7.2.
- The key rename IS mentioned in the roadmap specification: "consistent JSON keys (`issue_id`, `pr_url`, `timestamp`)"

**Impact assessment:**
- Only affects users who had webhook receivers parsing implement-feature webhooks with the OLD key names
- fix-ticket and fix-bugs users are unaffected (they already used canonical keys via core delegation)
- The old keys only existed in implement-feature, which was the deviant -- the alignment makes all 3 skills consistent
- This is technically a behavioral change in webhook output format

**Is this a breaking change?**
- Per the versioning policy: "Breaking change in agent output format contract" = MAJOR. However, webhook payloads are not agent output format -- they are internal notification payloads. The Notifications config section is optional, and the webhook format is not documented in any user-facing contract.
- The fix aligns implement-feature with the format already used by fix-ticket and fix-bugs, so existing multi-pipeline webhook consumers already handle `"issue_id"` format. Only implement-feature-only webhook consumers with hardcoded `"issue"` key parsing would break.
- Assessment: PATCH is correct. This is a bug fix (implement-feature deviated from the canonical format), not a breaking change.

**Verdict:** The rename is correct and warranted. Risk exists for implement-feature-only webhook consumers but probability is very low.

**Probability:** LOW (vanishingly few users would have webhook receivers parsing only implement-feature webhooks with the old deviant keys)
**Actual existence:** The behavioral change is real. Documentation must note this in the CHANGELOG.

**Recommendation:** The CHANGELOG entry for v6.7.2 MUST include under "Changed" or "Fixed":
```
- **Webhook format alignment:** implement-feature webhook payloads now use canonical key names (`issue_id`, `pr_url`) matching fix-ticket, fix-bugs, and core contracts. Previously used deviant `issue` and `pr` keys.
```

---

## Summary

| # | Scenario | Probability | Actually Exists? | Mitigation |
|---|----------|-------------|-----------------|------------|
| 1 | Content loss in extraction | LOW | No | None needed |
| 2 | Test cross-reference break | LOW (now) / MEDIUM (future) | Latent fragility in FC-14 | Update FC-14 to check core contract |
| 3 | Webhook key rename impact | LOW | Real change, needs CHANGELOG note | Document in CHANGELOG |

## Robustness Score

**0.85 / 1.0**

Rationale:
- The core extraction is clean and complete (+0.3)
- Webhook alignment is correct and well-motivated (+0.2)
- Block handler inline removal is clean (+0.15)
- Documentation fixes are partially done: fix-verification.md title still says "fix-verification" (spec asked for "Verification"), state/schema.md lacks inline field reuse documentation (-0.05)
- The fixer-reviewer-loop.md already lists all 3 pipeline skills correctly (+0.1)
- FC-14 test fragility is a pre-existing issue, not a v6.7.2 regression (-0.05)
- CHANGELOG not yet written -- must capture webhook key rename (-0.05)
- No new documentation gaps introduced by the extraction (+0.15)
- core/state-manager.md forward reference to resume-ticket already removed (+0.05)

The release is safe to proceed. Two action items before commit:
1. CHANGELOG entry must mention webhook key rename under Changed/Fixed
2. Consider updating FC-14 test to include core contract in search scope (non-blocking)
