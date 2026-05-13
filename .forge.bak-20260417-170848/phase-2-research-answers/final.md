# Research Answers — Final Synthesis
## Work Items: WI1, WI2, WI3, WI4

---

## WI1: Tracker Subtask Extraction

### Key Findings

**Q1.1 — Are the three pseudocode blocks identical?**

Yes. All three copies across `skills/fix-ticket/SKILL.md` (step 4b-tracker, L223–360), `skills/fix-bugs/SKILL.md` (step 3b-tracker, L240–377), and `skills/implement-feature/SKILL.md` (step 5a, L282–419) are structurally and functionally identical. Every element — FOR EACH subtask loop, idempotency check, state.json fallback, per-tracker MCP calls (YouTrack, Jira, Linear, Redmine, GitHub, Gitea), dual store write, CATCH block, commit YAML section, result messages — is word-for-word the same. The Jira nested sub-task guard is also identical across all three. The only cosmetic difference: `fix-ticket` uses a list-item (`- Follow core/mcp-body-formatting.md...`) while the other two use a plain paragraph sentence. The triple gate header wording is identical in all three. Extraction is safe — there is zero divergence to reconcile.

**Q1.2 — How does the triple gate check `tracker_effective_status`? Where is it defined?**

`tracker_effective_status` is referenced in all three files but never explicitly defined anywhere — not in the skill files and not in `core/mcp-preflight.md`. It is an implicit in-memory variable assumed to be set by the MCP pre-flight check (step 0), with value `"ready"` when MCP is available. The new core contract must formally own the definition of this variable and include it in its Input Contract.

**Q1.3 — YOLO-mode difference between fix-ticket and fix-bugs**

`fix-ticket` uses `--yolo` (CLI flag syntax) for two behaviors: auto-approve the decomposition plan, and Block on unmapped AC. `fix-bugs` uses `mode is YOLO` (prose style) only for the unmapped AC block — and has no YOLO auto-approve branch for the plan display step. Critically, `fix-bugs` does not support `--yolo` at all (its argument-hint is `"<N> [--dry-run] [--profile <name>]"`). The YOLO reference in fix-bugs is therefore a latent bug — it references a mode the skill cannot enter.

**Q1.4 — Input parameters unique to each skill's copy**

None. All three copies use the same five required in-memory values: `ISSUE_ID`, `tracker_type`, YAML path, `state.json` path, subtask list. The context differs (fix-bugs runs inside a per-bug batch loop; fix-ticket and implement-feature operate on a single issue), but the parameters themselves are identical.

**Q1.5 — How do existing core contracts handle delegation?**

All core contracts (`core/block-handler.md`, `core/post-publish-hook.md`, `core/mcp-preflight.md`) share the same structure: `## Purpose`, `## Input Contract` (Field/Type/Notes table), `## Process` (numbered steps), `## Output Contract`, `## Failure Handling` (per-scenario named responses). The new tracker-subtask contract must follow this exact structure.

**Q1.6 — Should the new contract own the triple gate?**

Yes. The triple gate belongs inside the contract, not in callers. Rationale: all three callers have identical gate text; `core/block-handler.md` owns its own entry conditions as precedent; leaving it to callers means three independent sync points. The contract's Input Contract should include `tracker_effective_status`, `decomposition_decision`, `create_tracker_subtasks_config`, `issue_id`, `tracker_type`, `subtask_list`, `state_json_path`, `yaml_path`, and `tracker_project`.

**Q1.7 — Is the Jira nested sub-task guard identical?**

Yes, completely identical across all three files (fix-ticket L271–283, fix-bugs L288–304, implement-feature L329–344).

### File References
- `skills/fix-ticket/SKILL.md` L223–360 (step 4b-tracker)
- `skills/fix-bugs/SKILL.md` L240–377 (step 3b-tracker)
- `skills/implement-feature/SKILL.md` L282–419 (step 5a)
- `core/mcp-preflight.md` (does not define `tracker_effective_status`)
- `core/block-handler.md` (Input/Output Contract pattern reference)
- `core/post-publish-hook.md` (Input/Output Contract pattern reference)

---

## WI2: Webhook Format Alignment

### Key Findings

**Q2.1 — Complete inventory of ALL webhook curl calls**

Six distinct curl invocations exist across the plugin:

| Location | Event | Flags | Key deviations from canonical |
|----------|-------|-------|-------------------------------|
| `core/block-handler.md` L39–44 | `issue-blocked` | `--max-time 5 --retry 0` | **Canonical** |
| `core/post-publish-hook.md` L18–23 | `pr-created` | `--max-time 5 --retry 0`, `--data-binary @-` heredoc | **Canonical** |
| `skills/fix-bugs/SKILL.md` L613–618 (step 8b) | `pr-created` | `--max-time 5 --retry 0`, `-d '...'` | `pr_url` key → `url` |
| `skills/fix-bugs/SKILL.md` L661–665 (step 9a) | `pipeline-complete` | `--max-time 5 --retry 0` | No canonical (fix-bugs only) |
| `skills/fix-bugs/SKILL.md` L697–701 (step X) | `issue-blocked` | `--max-time 5 --retry 0` | `issue_id` → `issue`, `{agent_name}` → `{agent}` |
| `skills/implement-feature/SKILL.md` L622–623 (step 10a) | `pr-created` | `-X POST` only | Missing `--max-time`/`--retry`, `issue_id` → `issue`, `pr_url` → `pr`, no `timestamp`, bare URL |
| `skills/implement-feature/SKILL.md` L661–664 (step X) | `issue-blocked` | `-X POST` only | Missing `--max-time`/`--retry`, `issue_id` → `issue`, no `timestamp`, bare URL |

**Q2.2 — Does fix-bugs have duplicate webhook firing?**

Yes. For `pr-created`: step 8a delegates to `core/post-publish-hook.md`, then step 8b immediately fires inline — two firings. For `issue-blocked`: step X references `core/block-handler.md` at L669, then also fires inline at L697 — two firings. `fix-ticket` is clean: one core reference only, no inline duplicate.

`implement-feature` step 10a delegates to `core/post-publish-hook.md` then also fires inline (two firings). Step X references core at L642 and fires inline at L661 (two firings).

**Q2.3 — Exact deviations in implement-feature webhooks**

`pr-created` (L622–623) vs. canonical `core/post-publish-hook.md`:
- Missing: `--max-time 5`, `--retry 0`, `timestamp` field
- Renamed: `issue_id` → `issue`, `pr_url` → `pr`
- Different: bare `{webhook_url}` (no quotes) vs. `"{Webhook URL}"`; `-d '...'` inline vs. `--data-binary @-` heredoc

`issue-blocked` (L661–664) vs. canonical `core/block-handler.md`:
- Missing: `--max-time 5`, `--retry 0`, `timestamp` field
- Renamed: `issue_id` → `issue`
- Different: bare `{webhook_url}` vs. `"{Webhook URL}"`; placeholder `{agent}` vs. `{agent_name}`

**Q2.4 — Downstream consumers**

No downstream consumers exist within the repository. However, external webhook receivers built against `implement-feature` events would read `payload.issue` and `payload.pr`, breaking if `fix-ticket`/`fix-bugs` events send `payload.issue_id` and `payload.pr_url`. Key normalization is essential for cross-pipeline consumers.

### Deviation Matrices

**pr-created event:**

| Source | `--max-time` | `--retry` | issue key | pr_url key | timestamp | URL quoting |
|--------|-------------|---------|-----------|-----------|-----------|-------------|
| `core/post-publish-hook.md` | `5` | `0` | `issue_id` | `pr_url` | present | `"..."` |
| `fix-bugs` step 8b inline | `5` | `0` | `issue_id` | `url` ❌ | present | `"..."` |
| `implement-feature` step 10a inline | absent ❌ | absent ❌ | `issue` ❌ | `pr` ❌ | absent ❌ | bare ❌ |

**issue-blocked event:**

| Source | `--max-time` | `--retry` | issue key | agent placeholder | timestamp | URL quoting |
|--------|-------------|---------|-----------|------------------|-----------|-------------|
| `core/block-handler.md` | `5` | `0` | `issue_id` | `{agent_name}` | present | `"..."` |
| `fix-bugs` step X inline | `5` | `0` | `issue` ❌ | `{agent}` | present | `"..."` |
| `implement-feature` step X inline | absent ❌ | absent ❌ | `issue` ❌ | `{agent}` | absent ❌ | bare ❌ |

### File References
- `core/block-handler.md` L39–44
- `core/post-publish-hook.md` L18–23
- `skills/fix-bugs/SKILL.md` L613–618, L661–665, L697–701
- `skills/implement-feature/SKILL.md` L622–623, L661–664
- `skills/fix-ticket/SKILL.md` L588–589, L606 (clean — delegate only)

---

## WI3: Block Handler Inline Removal

### Key Findings

**Q3.4 — Exact line range of inline block handler in implement-feature**

Lines 642–666 of `skills/implement-feature/SKILL.md` (25 lines). Line 642 is the `### X. Block handler` heading; line 666 is the state.json update step. Line 667 begins `## Rules`.

**Q3.1 — Does the implement-feature inline differ from core/block-handler.md?**

Yes — six significant gaps:

| Gap | Severity |
|-----|----------|
| No rollback guard (always calls rollback-agent, even from read-only agents like spec-analyst) | Behavioral bug |
| No rollback Task context string | Missing context |
| No status-verification follow-up after issue state set | Missing step |
| Old curl format: missing `--max-time 5`, `--retry 0`, wrong key `issue` vs `issue_id`, no `timestamp` | Protocol deviation |
| No `core/mcp-body-formatting.md` reference | Missing spec |
| No Failure Handling instructions (comment fail, webhook fail, state fail, rollback fail) | Missing spec |

The inline header even says `Follow core/block-handler.md:` then immediately re-lists all steps — contradictory: it delegates and duplicates simultaneously.

**Q3.2 — What skill-specific logic must remain after removing the inline?**

None. The state.json update step (L666) duplicates what `core/block-handler.md` already mandates. implement-feature is CWD-only (no worktree), has no block counter, and uses the generic single-issue state.json path — all already covered by core. After full delegation, no skill-specific addendum is required.

**Q3.3 — How do fix-ticket and fix-bugs structure their Step X?**

`fix-ticket` (L605–610): Pure delegate — `Follow core/block-handler.md for the block protocol.` plus one state.json reminder. No inline re-listing. Total: 6 lines. This is the canonical reference pattern.

`fix-bugs` (L667–710): Delegate sentence + full inline re-listing (same problem as implement-feature). Has legitimate skill-specific additions: worktree-aware rollback context string, per-issue `.ceos-agents/{ISSUE-ID}/state.json` path, and block counter logic (steps 7–8: `block_count`, `Max blocked per run`, skip to step 9 if limit reached). These three items are genuinely skill-specific and must remain.

**Q3.5 — Does implement-feature's inline reference any skill-specific variables?**

No. All variables (`{agent name}`, `{pipeline step}`, `{issue_id}`, `{agent}`, `{reason}`) are generic pipeline variables present in the core contract. No implement-feature-specific flags or state fields appear.

**Q3.6 — What is the canonical delegate pattern?**

Based on `fix-ticket` (L605–609) as the reference implementation:

```markdown
### X. Block handler

Follow `core/block-handler.md` for the block protocol.
```

For implement-feature, the refactored form is exactly this — no addendum needed.

### File References
- `skills/implement-feature/SKILL.md` L642–666 (inline to remove)
- `skills/fix-ticket/SKILL.md` L605–610 (reference pattern)
- `skills/fix-bugs/SKILL.md` L667–710 (delegate + skill-specific addenda)
- `core/block-handler.md` L21 (rollback guard), L24 (status-verification), L38 (mcp-body-formatting), L39–44 (curl), L45 (state.json)

---

## WI4: Documentation Fixes (LOW)

### Key Findings

**Q4.1 — "Fix verification" in core/fix-verification.md**

Two instances of bug-fix-centric language exist. This file is also invoked by the feature pipeline (`skills/implement-feature/SKILL.md`), making the language misleading.

Line 21 (success comment):
- Current: `[ceos-agents] ✅ Fix verified. Verify command: \`{command}\`. Output: {first 500 chars}.`
- Proposed: `[ceos-agents] ✅ Verified. Verify command: \`{command}\`. Output: {first 500 chars}.`

Line 26 (failure comment):
- Current: `[ceos-agents] ❌ Fix verification failed.`
- Proposed: `[ceos-agents] ❌ Verification failed.`

**Q4.2 — Other files referencing core/fix-verification.md**

Three active skill files reference it: `skills/fix-ticket/SKILL.md` (L603), `skills/fix-bugs/SKILL.md` (L622), `skills/implement-feature/SKILL.md` (L627). Also `docs/plans/roadmap.md` (L608) contains a planned-fix entry for this exact change.

**Q4.3 — Forward reference in core/state-manager.md**

Lines 41–43 contain: `Fall back to heuristic detection (see resume-ticket.md existing logic)`. This creates a forward-reference loop — a core contract borrowing its fallback definition from one of its callers (resume-ticket is a skill above the core layer). The contract cannot be understood in isolation.

**Q4.4 — Heuristic detail to inline (replacing the forward reference)**

Full heuristic table from `skills/resume-ticket/SKILL.md` (L36–70):

Before (lines 41–43):
```markdown
2. If state.json does not exist:
   - Fall back to heuristic detection (see resume-ticket.md existing logic)
   - Return resume_point from heuristic with reduced context
```

After:
```markdown
2. If state.json does not exist:
   - Fall back to heuristic detection by reading issue tracker comments, branch state, and git log:
     - PR open for branch → `PUBLISHED`
     - `.claude/decomposition/{ISSUE-ID}.yaml` exists → `DECOMPOSE_PARTIAL`
     - Branch with commits above base → `POST_FIX` (or `POST_REVIEW` if reviewer approval comment present)
     - Branch exists + `[ceos-agents] Triage completed.` comment → `POST_ANALYSIS`
     - `[ceos-agents] Triage completed.` comment only → `POST_TRIAGE`
     - Otherwise → `FRESH`
   - Return resume_point from heuristic with reduced context (no AC list, no iteration counts)
```

**Q4.5 — e2e_test section gaps in state/schema.md**

Current (L225–226): only `e2e_test.status` is defined. The `test` section has `attempts`, `max_attempts`, and `last_result` — needed for resume logic and metrics. The e2e_test section must add the same three fields, plus optionally `framework`.

JSON schema example addition:
```json
"e2e_test": {
  "status": "pending",
  "attempts": 0,
  "max_attempts": 3,
  "last_result": null
}
```

Field table additions needed:
- `e2e_test.attempts` | integer | Yes | `0` | Number of completed E2E test attempts.
- `e2e_test.max_attempts` | integer | Yes | `3` | Maximum allowed attempts (from retry limits).
- `e2e_test.last_result` | string or null | No | `null` | Most recent E2E test outcome: `PASSED` or `FAILED`.

**Q4.6 — triage.* and code_analysis.* fields and mode applicability**

Fields reused across all modes: `triage.status`, `triage.acceptance_criteria`, `triage.complexity`, `triage.ac_source`.
Bug-fix-only: `triage.severity`, `triage.reproduction_steps`.
Bug-fix-only (not feature/scaffold): `triage.area`.
Cross-mode `code_analysis.*`: `status`, `affected_files`, `estimated_diff_lines` (bug + feature); `risk` (bug only; not populated in scaffold where no code-analyst step runs).

**Q4.7 — Where to place mode-reuse note in state/schema.md**

Two locations: (1) after the `triage` section header in the field definitions table (immediately after line 171, before the first `triage.*` row); (2) in the full schema example JSON comment block (lines 64–72). The primary note should be at location 1.

**Q4.8 — NEEDS_DECOMPOSITION in core/fixer-reviewer-loop.md**

Appears at three locations: line 21 (Process, step 3), line 36 (Output Contract table), line 44 (Failure Handling). Line 44 only references `skills/fix-ticket/SKILL.md step 5` — omitting fix-bugs and implement-feature.

**Q4.9 — "Once per ticket" enforcement across all 3 callers**

Not uniform. `fix-ticket` (L452–457): enforces via explicit "already decomposed → Block" counter check. `fix-bugs` (L470–475): same explicit counter check. `implement-feature` (L482–484): no counter — always Blocks on signal (subtask scope → Block subtask; single-pass → Block issue). The "once per ticket" claim on line 21 is correct in outcome but imprecise for implement-feature.

Before (line 44):
```
- `NEEDS_DECOMPOSITION` → returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md` and `skills/fix-ticket/SKILL.md` step 5).
```

After:
```
- `NEEDS_DECOMPOSITION` → returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md`). Enforcement varies by caller: `fix-ticket` and `fix-bugs` each enforce a one-decomposition-per-ticket limit (Block if already decomposed); `implement-feature` always Blocks (decomposition mode Blocks the subtask; single-pass mode Blocks the issue).
```

### File References
- `core/fix-verification.md` L21, L26
- `core/state-manager.md` L41–43
- `state/schema.md` L171, L225–226
- `core/fixer-reviewer-loop.md` L21, L36, L44
- `skills/resume-ticket/SKILL.md` L36–70 (heuristic detection table)
- `docs/plans/roadmap.md` L608 (existing entry for fix-verification fix)

---

## Key Decisions

### WI1: Tracker Subtask Extraction

1. **Triple gate goes inside the new core contract** — not left to callers. The gate is part of the procedure, not a caller responsibility. All three callers have identical gate text; centralizing it prevents three-way drift.

2. **No parameter divergence** — the required in-memory values are identical across all three callers. The new contract's Input Contract needs no per-caller variation. Callers simply need to populate the same 9 fields before delegating.

3. **fix-bugs YOLO reference is a latent bug** — `fix-bugs` references YOLO mode in its AC coverage check (step 3b) but does not expose a `--yolo` flag. When extracting to the core contract, the YOLO path must either be guarded by a caller-provided `yolo_mode` boolean in the Input Contract, or the fix-bugs caller must strip the YOLO branch from its delegation call. The bug should be called out explicitly in the implementation.

4. **`tracker_effective_status` must be formally defined** — the new contract owns the definition: `"ready"` (MCP available) | `"unavailable"` (MCP not available). Callers set it from MCP pre-flight output. This resolves the current implicit-variable gap.

### WI2: Webhook Format Alignment

5. **implement-feature has the most deviations** — 5 attributes wrong in both its pr-created and issue-blocked inline webhooks (missing timeout, missing retry, wrong key names, missing timestamp, bare URL). fix-bugs step 8b has one deviation (`url` instead of `pr_url`). fix-ticket is already clean.

6. **Align to canonical format** — all inline skill-level curl invocations should be removed. Skills should delegate to `core/post-publish-hook.md` (pr-created) and `core/block-handler.md` (issue-blocked) exclusively. The duplicate-firing pattern (core reference + inline) in fix-bugs steps 8a/8b and implement-feature steps 10a/X must be resolved by removing the inline copies.

7. **Canonical key names are**: `issue_id` (not `issue`), `pr_url` (not `pr` or `url`), `{agent_name}` placeholder (not `{agent}`), `timestamp` always present, URL double-quoted, `--max-time 5 --retry 0` always present.

### WI3: Block Handler Inline Removal

8. **implement-feature inline can be fully replaced with fix-ticket-style delegation** — no skill-specific logic exists in implement-feature's inline body (L642–666). The one-line pattern from fix-ticket (`Follow core/block-handler.md for the block protocol.`) is sufficient.

9. **fix-bugs inline cannot be fully removed** — three items are genuinely skill-specific: worktree-aware rollback context string, per-issue `.ceos-agents/{ISSUE-ID}/state.json` path, and block counter logic (steps 7–8). These must remain as addenda after the core delegation line.

10. **The implement-feature inline has a behavioral bug** — it calls rollback-agent unconditionally, including when a read-only agent (spec-analyst, architect) blocks. core/block-handler.md has the correct conditional guard. Removing the inline and delegating to core automatically fixes this bug.

### WI4: Documentation Fixes

11. **Exact before/after text for each of the 5 doc fixes:**

    **Fix 1 — core/fix-verification.md L21:**
    - Before: `[ceos-agents] ✅ Fix verified. Verify command: \`{command}\`. Output: {first 500 chars}.`
    - After: `[ceos-agents] ✅ Verified. Verify command: \`{command}\`. Output: {first 500 chars}.`

    **Fix 2 — core/fix-verification.md L26:**
    - Before: `[ceos-agents] ❌ Fix verification failed.`
    - After: `[ceos-agents] ❌ Verification failed.`

    **Fix 3 — core/state-manager.md L41–43:**
    - Before: heuristic fallback references `(see resume-ticket.md existing logic)` — a forward-reference loop
    - After: inline the full 6-checkpoint detection table (PUBLISHED → DECOMPOSE_PARTIAL → POST_FIX/POST_REVIEW → POST_ANALYSIS → POST_TRIAGE → FRESH)

    **Fix 4 — state/schema.md L225–226:**
    - Before: `e2e_test` section has only `status` field
    - After: add `attempts` (integer, default 0), `max_attempts` (integer, default 3), `last_result` (string|null, default null) — matching parity with the `test` section

    **Fix 5 — core/fixer-reviewer-loop.md L44:**
    - Before: `(see core/decomposition-heuristics.md and skills/fix-ticket/SKILL.md step 5)` — omits fix-bugs and implement-feature
    - After: replace with note documenting all three callers and their different enforcement strategies (counter-based for fix-ticket/fix-bugs, zero-tolerance block for implement-feature)
