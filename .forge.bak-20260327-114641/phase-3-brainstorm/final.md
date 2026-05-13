# Phase 3 Brainstorm Synthesis — Judge's Ruling

**Date:** 2026-03-27
**Input:** Agent 1 (Conservative Incrementalist), Agent 2 (Innovative UX Designer), Agent 3 (Skeptical Systems Thinker), Phase 2 Research Synthesis
**Output:** Definitive implementation direction for Scaffold Infrastructure Redesign v5.5.0

---

## 1. Consensus Points

All three personas agree on the following without reservation:

1. **Step 0-INFRA placement:** After State Detection, before Mode Selection. The reasoning is unanimous — State Detection is a zero-cost guard that can abort the entire command; asking infrastructure questions before it wastes user time. Mode Selection depends on infrastructure knowledge, not the reverse.

2. **init.md cannot be called inline (Option A).** The hard gate on CLAUDE.md existence in init.md Step 1 is an absolute blocker. All three agree on replicating the MCP detection subset directly in scaffold.md.

3. **scaffold.md must be edited atomically.** Internal cross-references (jump targets, MCP Pre-flight, step numbers) form a consistency set. Partial edits create contradictions. All three insist on single-pass editing of scaffold.md before touching any other file.

4. **scaffold.md is edited first, documentation second, tests third, version last.** The command definition is the single source of truth. Documentation is derivative. Tests validate the source of truth. Version stamps the release.

5. **In-memory state variables must be explicitly listed at every consumption point.** A blanket "use in-memory values" instruction is insufficient for an LLM executing prose commands. Steps 4, 4d, and 4e must each name the exact variables and their origin (Step 0-INFRA).

6. **Step 10 becomes Step 9.** Steps 5-8 are not renumbered. The "0-INFRA" / "0-MCP" label convention is acceptable despite differing from the letter-suffix convention (4d, 4e) because it avoids collision with existing Step 0b.

7. **Full YOLO behavior change must be prominently documented in CHANGELOG.** Step 0-INFRA is asked even in Full YOLO. This is intentional but breaks the previous zero-prompt experience.

8. **Post-implementation grep verification is mandatory.** Search for "Step 10", "Step 4b", "Step 4c", "Step 9: Issue Tracker" across the entire repo after all edits. Any match outside CHANGELOG.md or docs/plans/ is a drift error.

---

## 2. Resolved Disagreements

### 2a. File modification order: tests early (Agent 1) vs. tests late (Agent 2, Agent 3)

**Agent 1** places tests at positions 2-3 (immediately after scaffold.md), arguing for test-driven validation of each file change. **Agent 2** places tests at positions 10-11 (after all docs). **Agent 3** places tests at position 6 (after docs).

**Ruling: Tests after all content changes, before version bump (Agent 2/3 position).** Rationale: These are structural grep tests, not executable unit tests. Running them after scaffold.md but before docs would only validate scaffold.md content — the tests do not cover documentation files. Running them after all content changes validates the final state. Additionally, test files themselves need updating (new assertions, removed assertions), and writing tests against a partially-edited codebase risks encoding intermediate state into assertions. The test harness auto-discovers scenarios, so no ordering dependency exists.

### 2b. scaffold.md internal edit order: top-down additions first (Agent 3) vs. removals first (Agent 2)

**Agent 2** recommends removals first ("clear the dead weight"), then additions. **Agent 3** recommends additions first (top-down to avoid line-number invalidation from deletions).

**Ruling: Additions first, then deletions, working top-down (Agent 3 position).** Rationale: Agent 3's reasoning is correct — deletions shift line numbers, so adding content at known line positions before deleting content below preserves line-number accuracy for subsequent edits. Removals last minimizes positional drift. However, this is an implementation-level detail that the specification need not enforce rigidly — the atomicity constraint (all scaffold.md changes in one pass) is what matters.

### 2c. Step numbering: keep "0-INFRA" (Agent 1, Agent 3) vs. phase-based naming (Agent 2)

**Agent 2** proposes "Phase 0: Setup" groupings with named sub-steps. **Agent 1** and **Agent 3** accept the current "0-INFRA" / "0-MCP" convention with the descriptive heading pattern (`### Step 0-INFRA: Infrastructure Declaration`).

**Ruling: Keep "0-INFRA" / "0-MCP" with descriptive headings (Agent 1/3 position).** Rationale: The phase-based naming is a larger refactor than this feature warrants. Existing step numbering is established across multiple files, test assertions, and documentation since v4.0.0. Introducing a new "Phase" abstraction layer creates more churn than the marginal UX improvement justifies. The descriptive heading format is sufficient. Agent 1's suggestion to add a comment explaining the naming convention coexistence is adopted: `<!-- Step numbering: 0-INFRA and 0-MCP use label suffixes to avoid collision with existing Step 0b. Steps 4d and 4e use letter suffixes per standard convention. -->`

### 2d. Step 4e partial failure handling: warn + continue (Agent 3) vs. not addressed (Agent 1, Agent 2)

**Agent 3** identifies this as CRITICAL: partial issue creation leaves orphaned tracker issues with no rollback mechanism. **Agent 1** and **Agent 2** do not address partial failure at Step 4e.

**Ruling: Adopt Agent 3's partial failure handling.** Step 4e must include an accumulator pattern: track created issues, on mid-iteration failure commit partial links, report which epics were not created, continue as WARN (not BLOCK). This is the most dangerous hidden failure path because it involves external side effects (tracker issues) that cannot be rolled back. The prose must specify:
1. Iterate over spec/epics/*.md, tracking successes.
2. On individual failure: log the failure, continue to next epic.
3. After iteration: commit whatever was linked (partial is better than nothing).
4. Report: "Created N/M tracker issues. Remaining can be linked via /implement-feature."
5. Pipeline continues — this is a WARN, not a BLOCK.

### 2e. The "Run `/init` now?" offer in Step 0-MCP: remove or reword

**Agent 3** identifies that offering to run `/init` inline is a broken code path (CLAUDE.md does not exist). **Agent 2** implicitly agrees (the boundary section makes clear `/init` is a separate step). **Agent 1** does not address this directly but says "Do not call `/init`."

**Ruling: Remove the "Run `/init` now?" offer entirely from Step 0-MCP.** The design document's original phrasing ("Run `/init` now? [Y/n]") is incorrect — `/init` will fail because CLAUDE.md does not exist at Step 0-MCP time. The correct behavior when MCP is missing: display guidance text explaining the situation, offer to continue without the service (downgrade to "later") or abort. Do NOT offer to invoke `/init`. The Final Report (Step 9) will direct users to `/init` for post-scaffold setup.

### 2f. `--infra later,later` CLI flag for Full YOLO (Agent 2) vs. not needed (Agent 1, Agent 3)

**Agent 2** proposes a `--infra` flag to pre-answer the infrastructure question, preserving Full YOLO's zero-prompt experience.

**Ruling: Out of scope for v5.5.0.** The Full YOLO behavior change (one mandatory prompt) is intentional and documented in the CHANGELOG. Adding a new CLI flag increases the flag validation matrix (interactions with `--issue`, `--no-implement`, `--spec`, `--template`) and requires additional test scenarios. If user feedback after v5.5.0 shows this is a pain point, it can be added in v5.5.1 as a patch. For now, the one-prompt trade-off is acceptable.

### 2g. L6 Report conditional for `--no-implement` (Agent 1) vs. not addressed (Agent 2, Agent 3)

**Agent 1** identifies that the legacy flow's L6 Report says "Create issues in your issue tracker" as a next step, which is stale advice when the user declared tracker=ready at Step 0-INFRA.

**Ruling: Adopt Agent 1's conditional.** The L6 Report should adapt its "Next steps" based on declared infrastructure status:
- If tracker=ready: "Your tracker is connected. Use `/implement-feature` with an issue ID."
- If tracker=later: "Create issues in your issue tracker" (current text, kept as-is).
- If SC=ready: "Your code is pushed to {remote}."
- If SC=later: "Set up source control and push" (current text, kept as-is).

This is a small change (~5 lines in the legacy flow L6 section) and prevents giving contradictory advice.

### 2h. `.mcp.json.example` to `/init` handoff (Agent 2) vs. not in scope (Agent 1, Agent 3)

**Agent 2** proposes that `/init` should detect `.mcp.json.example` and use it as a pre-filled template, avoiding redundant questions.

**Ruling: Out of scope for v5.5.0, filed as follow-up.** Modifying `init.md` is explicitly outside the design scope. The minimum viable approach for v5.5.0: the Final Report (Step 9) includes clear instructions to copy `.mcp.json.example` to `.mcp.json` and fill in tokens manually, as an alternative to running `/init`. The `/init` improvement is a natural follow-up for v5.5.1 or v5.6.0.

### 2i. Tracker type lookup table: embed vs. reference by path

**Agent 3** strongly argues that scaffold.md Step 0-MCP must reference `docs/reference/trackers.md` by path, NOT embed the lookup table. **Agent 1** mentions the same approach. **Agent 2** does not address this directly.

**Ruling: Reference by path (Agent 3 position).** Embedding the tracker-to-MCP-package mapping creates a third source of truth (alongside init.md and trackers.md). The scaffold.md Step 0-MCP prose must say: "Read the MCP Server Detection table from `docs/reference/trackers.md` to determine the expected MCP package for the declared tracker type." This is exactly how init.md does it, maintaining a single source of truth.

### 2j. Step 4e issue status: use draft/planned status (Agent 2) vs. not specified (Agent 1, Agent 3)

**Agent 2** proposes that Step 4e should create issues in "planned" or "draft" status since implementation has not yet started.

**Ruling: Partially adopted.** Step 4e creates issues using whatever initial state is appropriate for the tracker. The issue status concern is valid but tracker-specific (not all trackers have "draft" status). The design should note: "Create issues without applying the `On start set` state transition from Automation Config. Issues represent planned work, not started work. The `On start set` transition applies when `/implement-feature` begins working on each issue." This aligns with existing Automation Config semantics.

### 2k. Double MCP failure UX (Agent 3) vs. not addressed (Agent 1, Agent 2)

**Agent 3** identifies that if both tracker and SC are declared "ready" but both MCP checks fail, the UX for sequential downgrade prompts is underspecified.

**Ruling: Specify independent downgrade with abort-either-aborts-all.** Each service is checked independently. If tracker MCP fails, the user is offered: "Continue without tracker? [Y/n/Abort]". If they choose Abort, the entire scaffold stops. If they choose Y (continue without), SC check proceeds next. Same prompt for SC. This is simple, predictable, and avoids a combined prompt that would be harder to parse.

---

## 3. Adopted Implementation Direction

### File Modification Order (final)

| Order | File | Scope |
|-------|------|-------|
| 1 | `commands/scaffold.md` | ALL changes atomically: add 0-INFRA, 0-MCP, 4d, 4e; remove 4b, 4c, old 9; extend Step 4; rename Step 10 to 9; rewrite MCP Pre-flight; update all internal refs; add L6 conditional for --no-implement |
| 2 | `docs/reference/pipelines.md` | Stages table (add 4 rows, remove 1, renumber 1) + Mermaid diagram (3 changes) |
| 3 | `CLAUDE.md` | ASCII Scaffold Pipeline diagram update |
| 4 | `docs/architecture.md` | Mermaid `graph LR` update |
| 5 | `README.md` | Mermaid `flowchart TD` update |
| 6 | `docs/reference/commands.md` | Prose update for /scaffold description |
| 7 | `tests/scenarios/scaffold-v2-happy-path.sh` | Add new assertions, add regression guards, add ordering assertions |
| 8 | `tests/scenarios/scaffold-v2-no-implement.sh` | Add 0-INFRA assertion |
| 9 | `CHANGELOG.md` | v5.5.0 entry |
| 10 | `.claude-plugin/plugin.json` + `marketplace.json` | Version bump 5.4.1 -> 5.5.0 |

### Key Design Decisions (final)

1. **Step 0-INFRA placement:** After State Detection, before Mode Selection. Exact insertion point: after L47 (State Detection conclusion), before L51 (Step 0: Mode Selection).

2. **init.md strategy:** Replicate MCP detection subset inline in scaffold.md Step 0-MCP. Reference `docs/reference/trackers.md` by path for the tracker-to-MCP-package lookup table. Do NOT embed the table. Do NOT modify init.md. Add sync comment: `<!-- Replicates init.md Steps 3-7 detection logic. Keep in sync. -->`

3. **In-memory state:** Explicit variable block defined at Step 0-INFRA listing all 7 variables (`tracker_type`, `tracker_instance`, `tracker_project`, `sc_remote`, `sc_base_branch`, `tracker_effective_status`, `sc_effective_status`). Each consumption point (Steps 4, 4d, 4e, MCP Pre-flight, L5b legacy) includes a "Required in-memory values" preamble naming the exact variables and their origin.

4. **Full YOLO behavior:** Step 0-INFRA is always asked (even in Full YOLO). Step 4e is skipped in Full YOLO (consistent with former Step 9 rule). Step 0-MCP auto-downgrades without prompt in Full YOLO. Step 4d runs without confirmation in Full YOLO (WARN on failure).

5. **--issue flag:** Auto-detects tracker=ready. Skips the tracker question at Step 0-INFRA. If MCP verification fails at Step 0-MCP, discards --issue input source and falls back to project description prompt.

6. **--no-implement:** Step 0-INFRA runs. Step 0-MCP runs. Legacy flow exit at Step 0. L5 extended with L5b (push to remote if SC=ready, WARN on failure). L6 Report conditionally adapts "Next steps" based on declared infrastructure status. Steps 4d and 4e do NOT run (legacy flow never reaches them).

7. **Step 4e partial failure:** Accumulator pattern. Track created issues. On individual failure: log, continue to next epic. After iteration: commit partial links. Report "Created N/M". Pipeline continues as WARN, not BLOCK.

8. **MCP Pre-flight rewrite:** Replace entire section (L540-L551). Reference Step 0-MCP as the primary verification point. List --issue and --no-implement as additional check cases. Include explicit "Do NOT re-read CLAUDE.md" instruction with variable names.

9. **Documentation consistency:** All Mermaid diagrams and step references updated consistently across pipelines.md, architecture.md, README.md, CLAUDE.md, and commands.md. Post-edit verification pass with grep for removed step labels across all markdown files (excluding CHANGELOG.md and docs/plans/).

10. **Step 0-MCP "Run /init?" offer:** Removed entirely. When MCP is missing, display guidance and offer: "Continue without {service}? [Y/n/Abort]". No invocation of /init during scaffold.

11. **Step 4e issue status:** Issues created without applying `On start set` state transition. Issues represent planned work. Status transitions apply when `/implement-feature` begins each issue.

12. **Step numbering comment:** Add `<!-- Step numbering: 0-INFRA and 0-MCP use label suffixes to avoid collision with existing Step 0b. Steps 4d and 4e use letter suffixes per standard convention. -->` to scaffold.md's Orchestration section.

### Risks Accepted

| # | Risk | Severity | Mitigation | Accepted Because |
|---|------|----------|------------|------------------|
| 1 | In-memory state variables not persisted to state.json; /resume-ticket cannot recover infrastructure declarations after mid-scaffold crash | MEDIUM | Document as known limitation in CHANGELOG. User re-answers questions on resume. | Adding state.json fields requires schema changes + /resume-ticket impact analysis. Disproportionate effort for an edge case (mid-scaffold crashes are rare). |
| 2 | Logic fork between init.md and scaffold.md Step 0-MCP will drift when new tracker types are added | HIGH | Reference trackers.md by path (not embed). Add sync comment. Add structural test verifying both init.md and scaffold.md reference trackers.md. | Extracting shared logic to core/mcp-detection.md is a larger refactor. The reference-by-path approach plus structural test is sufficient for v5.5.0. |
| 3 | MCP availability may change between Step 0-MCP and Steps 4d/4e (hours-long scaffold sessions) | LOW | Steps 4d (WARN on failure) and 4e (accumulator + WARN) both handle MCP failures gracefully. | Adding a second MCP check at Steps 4d/4e adds complexity for a low-probability failure mode. The WARN behavior provides adequate resilience. |
| 4 | Full YOLO users surprised by mandatory Step 0-INFRA prompt | MEDIUM | CHANGELOG prominently documents this behavior change. | Infrastructure is a prerequisite decision, not a quality gate. Cannot be defaulted without knowing user intent. --infra flag deferred to follow-up. |
| 5 | Double MCP failure (both services declared ready, both fail) gives sequential prompts | LOW | Each service independently downgraded. Abort-either-aborts-all semantics documented. | Combined prompt adds UX complexity; sequential is simpler and predictable. |

### Out of Scope for v5.5.0

- **core/mcp-detection.md extraction** — Shared MCP detection logic between init.md and scaffold.md. Deferred to future refactor when a third consumer emerges.
- **init.md --mcp-only flag** — Bypass the CLAUDE.md gate for use during scaffold. Not needed with Option A (inline replication).
- **state.json infrastructure field** — Persisting infrastructure declarations for /resume-ticket recovery. Deferred; /resume-ticket impact accepted as known limitation.
- **init.md `.mcp.json.example` detection** — Auto-filling from scaffold-generated example file. Follow-up for v5.5.1 or v5.6.0.
- **`--infra later,later` CLI flag** — Pre-answering infrastructure question for Full YOLO. Follow-up if user feedback warrants it.
- **Step 4e two-phase status update** — Updating issue status after implementation completes. Current design creates issues without `On start set`; status management deferred to `/implement-feature`.

---

## 4. Divergence Assessment

The three personas converged strongly on core decisions. The primary divergences were in UX polish areas (phase naming, --infra flag, init.md handoff) and failure mode depth (Step 4e partial failure, double MCP failure). No persona challenged the fundamental design direction.

Agent 1 (Conservative) validated the design with minimal additions. Agent 2 (UX Designer) pushed for polish that would expand scope. Agent 3 (Systems Thinker) uncovered hidden failure paths that must be addressed. The synthesis adopts Agent 3's critical findings (Step 4e partial failure, trackers.md reference-by-path, /init offer removal) and Agent 1's tactical improvements (L6 conditional, naming comment) while deferring Agent 2's scope expansions (phase naming, --infra flag, init.md handoff) to follow-ups.

The brainstorm refined the original design without pivoting away from it. All core architectural decisions (placement, MCP strategy, step numbering, removal/addition set) are preserved from the original design plan. The refinements are in failure handling, state management explicitness, and edge case coverage.

```json
{
  "divergence_class": "REFINED",
  "original_keywords": [
    "Step 0-INFRA",
    "Step 0-MCP",
    "Step 4d push",
    "Step 4e tracker issues",
    "remove 4b 4c 9",
    "in-memory state",
    "Full YOLO prompt",
    "--issue auto-detect",
    "--no-implement legacy flow",
    "MCP Pre-flight rewrite",
    ".mcp.json.example generation"
  ],
  "recommended_keywords": [
    "Step 0-INFRA after State Detection",
    "Step 0-MCP inline replication",
    "Step 4d push WARN-only",
    "Step 4e accumulator partial-failure",
    "remove 4b 4c 9",
    "explicit variable block at consumption points",
    "Full YOLO mandatory prompt",
    "--issue auto-detect with downgrade fallback",
    "--no-implement L5b push L6 conditional",
    "MCP Pre-flight rewrite no-init-offer",
    ".mcp.json.example generation",
    "trackers.md reference-by-path",
    "abort-either-aborts-all downgrade"
  ],
  "keyword_overlap_score": 0.73
}
```

---

## 5. GO / NO-GO

### GO

**Conditions (must be met during implementation):**

1. Step 4e includes accumulator-based partial failure handling with WARN continuation.
2. Scaffold.md Step 0-MCP references `docs/reference/trackers.md` by path, does not embed the lookup table.
3. The "Run `/init` now?" offer is removed from Step 0-MCP; replaced with downgrade/abort prompt.
4. All scaffold.md changes are committed atomically (no intermediate commits with dangling references).
5. Steps 4, 4d, 4e, and MCP Pre-flight each include explicit "Required in-memory values" blocks naming variables and their source.
6. Legacy flow L6 Report adapts "Next steps" based on infrastructure declarations from Step 0-INFRA.
7. CHANGELOG entry explicitly documents the Full YOLO behavior change.

**Rationale for GO:**

- The design is thorough and all ambiguous decisions have been resolved by research.
- The change is a net UX improvement: front-loads one meaningful question, eliminates three dead-end steps, adds four functional steps.
- No breaking changes to the Automation Config contract (MINOR version correct).
- Risk profile is manageable: the three critical risks (partial failure, logic fork, in-memory state) all have concrete mitigations specified above.
- The file change set is well-scoped: 1 critical file, 5 documentation files, 2 test files, 3 metadata files.
- All three personas recommend GO.
