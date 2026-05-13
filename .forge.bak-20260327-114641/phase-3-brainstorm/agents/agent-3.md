# Agent 3: Skeptical Systems Thinker — Scaffold Infrastructure v5.5.0 Review

**Role:** Distributed Systems Architect
**Focus:** Hidden coupling, failure modes, state management correctness, error paths
**Input:** `.forge/phase-2-research-answers/final.md` + design plan + current codebase

---

## 1. Implementation Ordering — Minimizing Inconsistent Intermediate States

The critical constraint: `commands/scaffold.md` is a single file undergoing both deletions (Steps 4b, 4c, 9) and insertions (Steps 0-INFRA, 0-MCP, 4d, 4e). If the file is committed partway through — or if tests run against a partially edited file — there will be dangling internal references (e.g., "jump to Step 10" pointing at a deleted heading, or MCP Pre-flight Check still referencing "Step 9").

**Recommended file modification order:**

1. **`commands/scaffold.md`** — ALL changes in one atomic pass. This is non-negotiable. The file has internal cross-references (jump targets, MCP Pre-flight Check section, step numbers) that form a consistency set. Partial edits create contradictions that structural tests would flag as failures. Within this file, the sub-order should be:
   - (a) Add Step 0-INFRA and Step 0-MCP (insertions at L49)
   - (b) Delete Steps 4b, 4c (L263-L307)
   - (c) Extend Step 4 with auto-fill and `.mcp.json.example` generation
   - (d) Add Steps 4d, 4e (insertions after Step 4)
   - (e) Delete Step 9 (L481-L501)
   - (f) Rename Step 10 to Step 9 (L503 heading)
   - (g) Update all internal jump references ("Step 10" -> "Step 9" at L443, L449)
   - (h) Rewrite MCP Pre-flight Check section (L540-L551)
   - (i) Update Step 9 (formerly 10) Final Report content with infrastructure status
   The reason for this order: deletions shift line numbers, so working top-down prevents invalidating line references for subsequent edits.

2. **`docs/reference/pipelines.md`** — Stages table + Mermaid diagram. Must be consistent with scaffold.md. Edit immediately after scaffold.md so the two authoritative references agree.

3. **`CLAUDE.md`** — The text diagram in the Scaffold Pipeline section. This is read by Claude Code itself for context, so it must match the actual command definition.

4. **`README.md`** + **`docs/architecture.md`** — Mermaid/diagram updates. Lower risk; these are documentation, not execution logic.

5. **`docs/reference/commands.md`** — Prose update for /scaffold. Low coupling.

6. **`tests/scenarios/scaffold-v2-happy-path.sh`** + **`tests/scenarios/scaffold-v2-no-implement.sh`** — Test updates. Must come after scaffold.md changes so assertions match new content.

7. **`CHANGELOG.md`** + **`.claude-plugin/plugin.json`** + **`.claude-plugin/marketplace.json`** — Version bump. Always last.

**Key principle:** scaffold.md and its tests form a transactional unit. All scaffold.md edits must be committed together, not incrementally. A partial commit where Steps 4b/4c are deleted but 0-INFRA is not yet added creates a pipeline with no infrastructure setup at all.

---

## 2. Step 0-INFRA Placement — State Management Implications

The placement (after State Detection, before Mode Selection) is correct but introduces a subtle state lifecycle issue.

**The problem:** Step 0 (Mode Selection) is where `state.json` is initialized (`status: "running"`, `run_id` generated). Step 0-INFRA runs BEFORE Step 0. This means:

- Infrastructure questions are asked before `state.json` exists.
- If the user answers the infrastructure questions and then Step 0 fails or user aborts at Mode Selection, the infrastructure answers are lost with no trace in state.
- If the scaffold crashes between Step 0-INFRA and Step 0, there is zero state persistence — no `run_id`, no `state.json`, no `pipeline.log` entry.

**Is this a real problem?** Partially. The current design already has this gap: Flag Parsing, Flag Validation, and State Detection all run before `state.json` creation. Step 0-INFRA adds another pre-state step, but it is the first one that collects *user input* (not just parsing CLI flags). Losing flag values is no-cost; losing answers to interactive questions is annoying.

**The state schema (`state/schema.md`) has no field for infrastructure declarations.** The in-memory variables (`tracker_type`, `tracker_instance`, `tracker_project`, `sc_remote`, `sc_base_branch`, `tracker_effective_status`, `sc_effective_status`) listed in the research synthesis are entirely in-memory. They are never persisted to `state.json`. This means:

- `/resume-ticket` cannot resume a scaffold that failed after Step 0-INFRA but before Step 4 (where values are committed to CLAUDE.md).
- If the LLM session crashes mid-scaffold, infrastructure declarations are lost entirely. The user must re-answer the questions.
- There is no audit trail of what was declared vs. what was effective (e.g., "ready" downgraded to "downgraded").

**Assessment:** This is an accepted gap, not a blocking issue. The design explicitly states "in-memory" for these values. But it should be documented as a known limitation: resume-ticket cannot recover infrastructure declarations. The cost of adding a `state.json` field is low, but the design chose not to, and I will not argue it as a blocker. I raise it as a concern for the improvement section below.

---

## 3. init.md Inline Invocation — Failure Modes

The research synthesis correctly identifies that calling `/init` inline is impossible (init.md Step 1 hard-gates on CLAUDE.md existence). The design replicates a subset of init.md logic (Steps 3-7) directly in scaffold.md. This creates a **logic fork** that will drift over time.

**Specific failure modes:**

**3a. Tracker type lookup table divergence.** The tracker-to-MCP-package mapping exists in three places after this change:
- `commands/init.md` Step 3 (canonical)
- `docs/reference/trackers.md` (reference)
- `commands/scaffold.md` Step 0-MCP (replicated)

When a new tracker type is added (say, `notion`), all three must be updated. The research synthesis lists the lookup table inline. If the implementer copies this table verbatim into scaffold.md, it becomes a third source of truth. The correct approach: scaffold.md Step 0-MCP should reference `docs/reference/trackers.md` by path ("Read the MCP Server Detection table from `docs/reference/trackers.md`"), NOT embed the table. This is how init.md does it (Step 3: "Read `docs/reference/trackers.md`").

**3b. MCP tool detection heuristic divergence.** init.md Step 7 validates connectivity by attempting a minimal MCP call. scaffold.md Step 0-MCP will implement its own connectivity check. If the detection heuristic changes in init.md (e.g., checking for a specific tool name instead of `mcp__*` prefix), scaffold.md will use the stale heuristic.

**3c. The "run `/init` now?" offer in Step 0-MCP.** The research synthesis (Section 2, Decision 1, point 4) says: "If not accessible: offer inline setup guidance (do NOT block; offer `[Y/n]` to continue without or run setup)." But running `/init` from within scaffold has the same CLAUDE.md gate problem that made Option A necessary in the first place. If the user says "Y" to "Run `/init` now?", what happens? CLAUDE.md does not exist. init.md will error immediately. The design must either (a) not offer to run `/init` at all during scaffold, or (b) explicitly state that the "run setup" option means "manual setup instructions" not "invoke /init". The research synthesis's wording is ambiguous here and could lead to an implementation that offers a broken code path.

**3d. `.mcp.json` vs `.mcp.json.example` generation at Step 4.** The design says Step 4 generates `.mcp.json.example` with `<YOUR_*>` placeholders but NOT `.mcp.json` with real tokens. However, the MCP verification at Step 0-MCP already confirmed the MCP tools are accessible (meaning tokens exist in the parent context). The scaffold pipeline will then proceed to Steps 4d and 4e which require MCP access — but the NEW project directory has no `.mcp.json`. This works because MCP servers are configured at the session level (parent context), not per-project. But future sessions in the new project directory will have no MCP access until the user runs `/init`. This is documented but could confuse users who see MCP working during scaffold and then failing afterward.

---

## 4. Documentation Update Strategy — Preventing Drift

The design touches 8+ files with diagram and text updates. The documentation drift risk is real.

**Drift vectors identified:**

| Source of Truth | Downstream Docs | Drift Risk |
|---|---|---|
| `commands/scaffold.md` (step definitions) | `docs/reference/pipelines.md` (stages table) | HIGH — separate files, easy to forget one |
| `commands/scaffold.md` (step definitions) | `CLAUDE.md` (ASCII pipeline diagram) | HIGH — CLAUDE.md is read by the LLM for self-context; stale diagram = stale behavior guidance |
| `commands/scaffold.md` (step definitions) | `README.md` (Mermaid diagram) | MEDIUM — cosmetic |
| `commands/scaffold.md` (step definitions) | `docs/architecture.md` (graph LR) | MEDIUM — cosmetic |
| `commands/scaffold.md` (step definitions) | `docs/reference/commands.md` (prose) | LOW — vague prose, rarely referenced |

**Mitigation strategy:** The test harness currently only validates `commands/scaffold.md` content (grep assertions). There is no test that validates consistency between scaffold.md and pipelines.md. A post-implementation verification pass should search all files for "Step 9" (old issue tracker), "Step 10" (old final report), "Step 4b", and "Step 4c" — any match outside of CHANGELOG.md is a drift error.

Recommended: add a regression test that greps across ALL markdown files for removed step labels:

```bash
# No file outside CHANGELOG should reference removed steps
for pattern in "Step 4b" "Step 4c" "Step 9: Issue Tracker"; do
  matches=$(grep -rl "$pattern" "$REPO_ROOT" --include="*.md" | grep -v CHANGELOG | grep -v "docs/plans/")
  if [ -n "$matches" ]; then
    echo "FAIL: Stale reference to '$pattern' in: $matches"
    exit 1
  fi
done
```

---

## 5. Step Numbering — Collision Risks

**Within scaffold.md:** Steps 0-INFRA, 0-MCP, 4d, 4e use alphanumeric suffixes. No collision with existing integer steps. The research synthesis correctly notes that Steps 5-8 are not renumbered. This is clean.

**Cross-command collision:** init.md has its own "Step 9" (Closing message). onboard.md likely has its own step numbers. The research synthesis explicitly confirms these are unrelated. No collision.

**But there IS a subtle naming collision:** The existing `Step 7b: Spec Compliance Check` in scaffold.md uses the same naming pattern as the new steps (alphanumeric suffix). This is fine syntactically, but the research synthesis (Risk 8) flagged that Agent 5 confused the CLAUDE.md `[Spec compliance check (spec-reviewer --verify)]` line with old Step 9. This confusion arose precisely because the naming is overloaded. If a future agent confuses "Step 7b" with a new step, the same misidentification could happen again.

**Concrete risk:** The happy-path test currently checks for `"Final Report"` (line 65 of the test) without checking the step number. After renumbering, the test still passes because it matches the text "Final Report" regardless of whether the heading says "Step 9" or "Step 10". This is accidentally correct, but it means the test does NOT verify that renumbering actually happened. The proposed new assertions (from the research synthesis) also do not verify that `"Step 9: Final Report"` exists as a heading. Only the removal assertions (`! grep -q "Step 9: Issue Tracker"`) are proposed. I would add: `grep -q "Step 9: Final Report"` to positively assert the renumbering.

---

## 6. Testing — What Structural Tests Cannot Catch

The existing test suite is purely structural: it greps for string presence in markdown files. It does not execute any pipeline logic. Here is what it fundamentally cannot catch:

**6a. Logical path coverage of the 4-combination matrix.** The design specifies 4 combinations (tracker ready/later x SC ready/later). Structural tests can verify that the words "ready" and "later" appear in scaffold.md. They cannot verify that all 4 paths lead to correct behavior. Specifically:

- **tracker=ready, SC=later:** Step 4e should run (create issues), Step 4d should NOT run (no push). Is this combination actually reachable in the prose? The Step 4d guard says "Only runs if SC was declared 'ready'". The Step 4e guard says "Only runs if tracker was declared 'ready'". These are independent. But the prose must make it clear that 4d and 4e are INDEPENDENT steps, not sequential. The Mermaid diagram in the research synthesis (Pattern 3c) shows GIT_INIT fanning out to PUSH and CREATE_ISSUES in parallel. If the scaffold.md prose describes them sequentially ("After push, create issues"), then the tracker=ready/SC=later path would attempt push first, fail/skip, and the question is whether CREATE_ISSUES still runs.

- **tracker=ready, SC=ready, but MCP for tracker fails at Step 0-MCP:** tracker_effective_status downgrades to "downgraded". Does Step 4e respect the effective status (not the declared status)? The prose must use `tracker_effective_status` not `tracker_status`.

**6b. In-memory state persistence across Task tool boundaries.** Steps 0-INFRA through 4e span multiple agent dispatches via the Task tool. The in-memory variables must survive across these Task dispatches. In the Claude Code architecture, the parent command (scaffold.md) maintains state between Task calls — each Task is a sub-conversation. But if the parent command does not explicitly pass the infrastructure variables into each Task's context, the Task agents will not have access. Structural tests cannot verify that the parent command passes the right context.

**6c. MCP tool availability between Step 0-MCP and Steps 4d/4e.** The research synthesis (Decision 6) says "No additional check" for Steps 4d and 4e because "MCP was verified at Step 0-MCP." But the time gap between Step 0-MCP and Step 4d/4e includes the entire specification phase, skeleton generation, architecture, and potentially hours of feature implementation. MCP servers can become unavailable (token expiry, server restart, network change). The design accepts this risk with "no additional check" — this is a conscious tradeoff (low probability, non-fatal failure mode since Step 4d is WARN-only). But Step 4e failures are more severe: partial issue creation (see section 7 below).

**6d. The `--issue` auto-detect + downgrade path.** When `--issue` is provided, `tracker_status` is auto-set to "ready". Then Step 0-MCP verifies connectivity. If MCP is unavailable, `tracker_effective_status` becomes "downgraded" and the `--issue` flag is discarded in favor of asking for a project description. This is a 3-state transition: ready -> verify -> downgrade. Structural tests cannot verify this state machine.

**6e. Full YOLO + Step 0-INFRA interaction.** The research synthesis (Decision 4) says Step 0-INFRA is ASKED in Full YOLO, which is a behavior change. But the current scaffold.md does not have "Step 0-INFRA" yet, so there is no existing test for YOLO behavior at this step. The only YOLO test is the mode selection presence check. No test will verify the new YOLO behavior.

---

## 7. Risk Mitigation — Hidden Failure Paths

### Top 3 Implementation Risks (Ranked)

**RISK 1 (CRITICAL): Step 4e Partial Issue Creation — Non-Atomic Side Effect**

Step 4e iterates over `spec/epics/*.md` and creates tracker issues one at a time. If the MCP server fails mid-iteration (after creating 3 of 5 epics), the scaffold has:
- 3 orphaned issues in the tracker with no local reference
- 2 epics with no tracker link
- A git commit ("chore: link spec epics to tracker issues") that only partially links issues
- No rollback mechanism for created tracker issues (MCP servers do not support transactional rollback)

This is the classic distributed transaction problem. The design has no compensation logic. The rollback-agent only handles git state, not external service state.

**Mitigation needed:** Step 4e must:
1. Track which issues were successfully created (accumulator list)
2. If a creation fails mid-iteration: commit whatever was linked so far (partial is better than nothing)
3. Report which epics were NOT created: "Created 3/5 tracker issues. Failed at epic-04. Run `/ceos-agents:implement-feature` on remaining epics to create their issues."
4. This should be a WARN, not a BLOCK (pipeline continues to Step 5 with partial tracker integration)

The design document says nothing about partial failure at Step 4e. The research synthesis's Risk Register also does not mention this. It is the most dangerous hidden failure path because it involves external side effects that cannot be rolled back.

**RISK 2 (HIGH): Logic Fork Between init.md and scaffold.md Step 0-MCP**

As detailed in section 3, the replicated MCP logic will drift from init.md over time. The next time a tracker type is added or MCP detection heuristics change, scaffold.md Step 0-MCP will be stale. This is a maintenance time bomb.

**Mitigation:** Scaffold.md Step 0-MCP should reference `docs/reference/trackers.md` by path for the lookup table (same as init.md does), NOT embed the table. Additionally, add a structural test that verifies both init.md and scaffold.md reference `docs/reference/trackers.md`:

```bash
for cmd in init scaffold; do
  if ! grep -q "docs/reference/trackers.md" "$REPO_ROOT/commands/$cmd.md"; then
    echo "FAIL: commands/$cmd.md must reference docs/reference/trackers.md"
    exit 1
  fi
done
```

**RISK 3 (HIGH): In-Memory State Variables Have No Persistence or Validation Contract**

Seven in-memory variables are introduced (`tracker_type`, `tracker_instance`, `tracker_project`, `sc_remote`, `sc_base_branch`, `tracker_effective_status`, `sc_effective_status`). These are:
- Not in `state.json` schema
- Not validated against any enum (what values are legal for `tracker_effective_status`?)
- Not passed explicitly in Task tool context (the research says "in-memory" but does not specify HOW they are carried — the parent scaffold command must hold them, but the prose instructions to the LLM must explicitly mention them at Steps 4, 4d, and 4e)

If the implementing LLM reads "use in-memory values from Step 0-INFRA" at Step 4d but does not have those values in its context window (due to context length or Task tool isolation), it will fall back to reading CLAUDE.md — which is exactly the failure the design tries to prevent.

**Mitigation:** The scaffold.md prose at Steps 4, 4d, and 4e must explicitly list all variable names and their sources: "Use `tracker_type` (from Step 0-INFRA), `sc_remote` (from Step 0-INFRA)...". Do not rely on a blanket "use in-memory values" instruction. The research synthesis provides this table but the actual scaffold.md prose must repeat it at each consumption point.

---

## The 4-Combination Matrix — Path Coverage Analysis

| # | Tracker | SC | Step 0-MCP | Step 4 auto-fill | Step 4d | Step 4e | Covered in Design? |
|---|---|---|---|---|---|---|---|
| 1 | ready | ready | Verify both | Full auto-fill | Push | Create issues | YES |
| 2 | ready | later | Verify tracker only | Tracker auto-fill, SC=TODO | Skip | Create issues | YES |
| 3 | later | ready | Verify SC only | SC auto-fill, tracker=TODO | Push | Skip | YES |
| 4 | later | later | Skip MCP entirely | All TODO | Skip | Skip | YES |
| 5 | ready->downgraded | ready | Tracker MCP fails, SC passes | SC auto-fill, tracker=TODO | Push | Skip | YES (via downgrade) |
| 6 | ready->downgraded | later->downgraded | Both fail | All TODO | Skip | Skip | PARTIALLY |
| 7 | --issue (auto-ready) | later | Tracker MCP fails -> downgrade -> discard --issue | All TODO | Skip | Skip | YES (Decision 2) |

**Path 6 is underspecified.** If both services are declared "ready" but both MCP checks fail at Step 0-MCP, the user gets two sequential downgrade prompts. The UX for this double-failure is not described. Does the user get asked twice ("Continue without tracker? [Y/n]" then "Continue without SC? [Y/n]")? Or is there a combined prompt? And if the user says "N" to the first, does the scaffold abort entirely or still ask about SC?

The design should specify: each service is independently downgraded. Answering "Abort" on either service aborts the entire scaffold. Answering "Continue without" downgrades that service only.

---

## What Step 4e Partial Failure Looks Like

```
Step 4e: Creating tracker issues...
  [OK] spec/epics/01-auth.md -> PROJ-10
  [OK] spec/epics/02-api.md -> PROJ-11
  [OK] spec/epics/03-dashboard.md -> PROJ-12
  [FAIL] spec/epics/04-notifications.md -> MCP error: connection refused

  Partial result: 3/5 epics linked. Committing partial links.
  Remaining epics can be linked via /ceos-agents:implement-feature.

  git commit -m "chore: link spec epics to tracker issues (partial: 3/5)"
```

Without this handling, the current design would either:
- Crash and leave uncommitted partial state
- Block the entire pipeline for a non-critical side effect
- Silently succeed with a misleading commit message

---

## One Concern the Design Missed

**The design has no concept of "infrastructure state" in `state.json`, which means `/ceos-agents:resume-ticket` cannot resume a scaffold that failed between Step 0-INFRA and Step 4.**

The state schema has fields for triage, code_analysis, fixer_reviewer, test, etc. — but no `infrastructure` field. When `state.json` is initialized at Step 0 (after Step 0-INFRA), the infrastructure declarations should be persisted immediately. Otherwise:

1. User answers infrastructure questions (Step 0-INFRA)
2. MCP verification passes (Step 0-MCP)
3. User selects mode (Step 0)
4. `state.json` is created — but contains NO record of infrastructure answers
5. Specification phase runs (Step 1) — could take 10+ minutes
6. Session crashes
7. User runs `/resume-ticket` on the scaffold run
8. Resume finds `state.json`, sees triage.status = "completed" (reused for spec phase), resumes at Step 3
9. But the infrastructure variables are GONE. Steps 4, 4d, 4e will either re-ask the questions (confusing) or silently skip infrastructure setup (wrong)

**Recommended improvement:** Add an `infrastructure` object to `state.json`:

```json
{
  "infrastructure": {
    "tracker_declared": "ready",
    "tracker_effective": "ready",
    "tracker_type": "gitea",
    "tracker_instance": "https://gitea.example.com",
    "tracker_project": "PROJ",
    "sc_declared": "ready",
    "sc_effective": "ready",
    "sc_remote": "org/repo",
    "sc_base_branch": "main"
  }
}
```

This is a schema addition (schema_version stays "1.0" since the field is optional and null by default). It makes infrastructure state resumable and auditable.

**This is NOT a blocker for v5.5.0** — the design can ship without it. But it should be tracked as a known gap, and the v5.5.0 CHANGELOG should note: "Infrastructure declarations are in-memory only and not persisted to state.json. Resume after mid-scaffold crash will re-prompt for infrastructure."

---

## GO / NO-GO Recommendation

**GO — with conditions.**

The design is sound in its core approach (move infrastructure declaration early, verify MCP proactively, remove dead steps). The 4-combination matrix is well-defined. The research synthesis is thorough and resolves all ambiguous decisions.

**Conditions for GO:**

1. **Step 4e must have partial failure handling.** The current design treats issue creation as atomic (all-or-nothing). It must handle partial creation with accumulator + WARN + partial commit. Without this, a flaky MCP connection during Step 4e could leave orphaned tracker issues with no local reference.

2. **Scaffold.md Step 0-MCP must reference `docs/reference/trackers.md` by path, NOT embed the lookup table.** Embedding creates a logic fork that will drift. This is a one-line change in the implementation prose.

3. **The "Run `/init` now?" offer in Step 0-MCP must be clarified as "manual setup instructions" or removed entirely.** Offering to run `/init` inline will fail because CLAUDE.md does not exist yet. The wording must not suggest that `/init` can be invoked at that point.

4. **All scaffold.md changes must be committed atomically.** No intermediate commits that leave the file in an inconsistent state with dangling step references.

If these 4 conditions are met, the implementation risk is manageable. The state persistence gap (no `infrastructure` field in state.json) is a known limitation, not a blocker.

---

## Summary Table

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| 1 | Step 4e partial issue creation (non-atomic external side effect) | CRITICAL | Add accumulator + partial commit + WARN continuation |
| 2 | Logic fork between init.md and scaffold.md MCP logic | HIGH | Reference `docs/reference/trackers.md` by path, not embed |
| 3 | In-memory variables have no persistence or validation contract | HIGH | Explicitly list variables at each consumption point in prose; consider state.json field |
| 4 | Double MCP failure UX (both services fail) underspecified | MEDIUM | Specify independent downgrade with abort-either-aborts-all |
| 5 | MCP availability gap between Step 0-MCP and Steps 4d/4e | MEDIUM | Accept risk (4d is WARN-only); add WARN handling to 4e |
| 6 | Documentation drift across 8 files | MEDIUM | Post-implementation grep for removed step labels; add regression test |
| 7 | Resume-ticket cannot recover infrastructure declarations | LOW-MEDIUM | Document as known gap; track for future state.json extension |
| 8 | "Run `/init` now?" offer is a broken code path | LOW | Remove offer or reword as manual instructions |
