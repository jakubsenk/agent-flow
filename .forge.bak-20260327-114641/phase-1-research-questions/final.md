# Phase 1 Research Synthesis: Scaffold Infrastructure Redesign

**Synthesized from:** 5 research agents (Areas 1–6)
**Date:** 2026-03-27
**Scope:** `docs/plans/2026-03-27-scaffold-infrastructure-design.md` implementation research

---

## Section A: Current State (What Exists Now)

### A.1 Scaffold Command Structure (`commands/scaffold.md`)

The current scaffold command has these pipeline steps relevant to the redesign:

| Step | Label | Lines | Status in New Design |
|------|-------|-------|----------------------|
| Step 0 | Mode Selection (+ state init) | 51–66 | Moves AFTER new Step 0-INFRA and Step 0-MCP |
| Step 0b | Brainstorming Phase (optional) | ~151 | Unchanged |
| Step 4 | Git Init | 251–261 | Extended with auto-fill + `.mcp.json` generation |
| Step 4b | Tracker Configuration (Auto-Finalize) | 263–298 | **REMOVED** — replaced by Step 0-INFRA + Step 4 auto-fill |
| Step 4c | MCP Guidance | 300–307 | **REMOVED** — replaced by Step 0-MCP inline `/init` |
| Step 9 | Issue Tracker (Optional) | 481–501 | **REMOVED** — replaced by Step 4e (moved before implementation) |
| Step 10 | Final Report | 503–538 | Updated to show infrastructure status |
| MCP Pre-flight Check | Policy section | 540–551 | Must be rewritten; currently references Step 9 |

**Legacy flow (--no-implement):** Steps L1–L6 are a self-contained mini-pipeline (stack-selector → scaffolder → validate → move → git init → report). They bypass all Steps 4–10. Step 0-INFRA will be inserted before L1 in the redesign.

**State initialization:** `run_id` is generated in Step 0 as `scaffold-{timestamp}`. Step 0 creates `.ceos-agents/{run_id}/` and writes `state.json` with `status: "running"`, `pipeline: "scaffold"`.

### A.2 Step 4b Current Behavior

Step 4b scans `## Automation Config` table rows for `<!-- TODO:` markers (pure text match, not semantic). It collects all incomplete keys into `incomplete_keys[]`, prompts the user interactively per key (with auto-fill defaults for query/transitions), writes values to CLAUDE.md via Edit tool, and commits: `git add CLAUDE.md && git commit -m "chore: configure Automation Config"`.

**Full YOLO behavior:** Step 4b is explicitly skipped ("cannot guess tracker URLs in unattended mode"). TODOs remain in CLAUDE.md.

### A.3 Step 4c Current Behavior

Step 4c is informational only. It displays "Run `/ceos-agents:init` to set it up" only when the tracker Instance was filled in Step 4b. If TODOs remain (including in Full YOLO), Step 4c is silently skipped via the "TODOs remain" condition — there is no explicit Full YOLO guard. The step does not block or run `/init`.

### A.4 Step 9 Current Behavior

Step 9 creates tracker cards from `spec/epics/*.md` after E2E tests. It has an explicit Full YOLO bypass. The MCP Pre-flight Check section (lines 540–551) lists Step 9 as one of two MCP triggers, alongside the `--issue` flag.

### A.5 MCP Pre-flight Check (Policy Section)

Current location: after Step 10, before `## Rules`. It is a **policy section, not a pipeline step** — applied contextually at two points: Step 1 (`--issue` flag) and Step 9 (card creation). For `--no-implement`, it triggers before L1. The check is lightweight (tool presence only, not full connectivity).

### A.6 Full YOLO Mode Skip Matrix

| Step | Full YOLO Behavior | Skip Mechanism |
|------|--------------------|----------------|
| Step 2 (Spec Checkpoint) | Skip | Explicit |
| Step 4b (Tracker Config) | Skip | Explicit ("cannot guess URLs") |
| Step 4c (MCP Guidance) | Effectively skip | Implicit — conditioned on Step 4b result |
| Step 6 (Feature Plan Checkpoint) | Skip | Explicit |
| Step 9 (Issue Tracker) | Skip | Explicit |
| Steps 5, 7b (data integrity gates) | Block (not skip) | Explicit escalation |

### A.7 init.md Structure

`commands/init.md` is a 9-step interactive wizard. Steps relevant to the redesign:

- **Step 1:** Reads Automation Config from CLAUDE.md — **hard dependency**, errors immediately if absent
- **Step 3:** Determines MCP servers from `docs/reference/trackers.md` MCP Server Detection table; handles shared server case (same hostname for tracker + SC)
- **Step 4:** Collects tokens interactively; generates both `.mcp.json` (real tokens) and `.mcp.json.example` (placeholders)
- **Step 7:** Validates connectivity via minimal MCP calls (same as check-setup Block 3)
- **Allowed tools:** `Read, Glob, Write, Edit, Bash, mcp__*` — no `Task` tool, cannot dispatch sub-agents

init.md is explicitly designed for standalone execution. It writes to the current working directory: `.mcp.json`, `.claude/settings.json`, and updates `.gitignore`.

### A.8 Current Version

`.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` both report `"version": "5.4.1"`. Both files must be updated in tandem (manual sync).

---

## Section B: Files Requiring Changes (Complete List)

### B.1 Primary Implementation Files

| Priority | File | Lines | Reason for Change |
|----------|------|-------|-------------------|
| CRITICAL | `commands/scaffold.md` | 51–66 | Add new Step 0-INFRA and Step 0-MCP BEFORE current Step 0 (Mode Selection); move `run_id` generation to Step 0-INFRA or retain at Step 0 |
| CRITICAL | `commands/scaffold.md` | 263–298 | Remove `### Step 4b: Tracker Configuration (Auto-Finalize)` entire section |
| CRITICAL | `commands/scaffold.md` | 265, 272 | Remove `skip to Step 4c` references (no longer exists) |
| CRITICAL | `commands/scaffold.md` | 300–307 | Remove `### Step 4c: MCP Guidance` entire section |
| CRITICAL | `commands/scaffold.md` | 302 | Remove `If Issue Tracker Instance was filled in Step 4b:` reference |
| CRITICAL | `commands/scaffold.md` | 251–261 | Extend Step 4 (Git Init) with auto-fill + `.mcp.json` generation |
| CRITICAL | `commands/scaffold.md` | (new) | Add Step 4d: Push to Remote |
| CRITICAL | `commands/scaffold.md` | (new) | Add Step 4e: Create Tracker Issues (with `--no-implement` guard) |
| CRITICAL | `commands/scaffold.md` | 481–501 | Remove `### Step 9: Issue Tracker (Optional)` entire section |
| CRITICAL | `commands/scaffold.md` | 540–551 | Rewrite MCP Pre-flight Check section — remove Step 9 reference, update triggers |

### B.2 Reference Documentation

| Priority | File | Lines | Reason for Change |
|----------|------|-------|-------------------|
| CRITICAL | `docs/reference/pipelines.md` | 269–281 | Update stage table: add Step 0-INFRA, Step 0-MCP, Step 4d, Step 4e rows; remove Step 9 row; update Step 4 notes |
| CRITICAL | `docs/reference/pipelines.md` | 208–265 | Update Mermaid diagram: remove `TRACKER` node (Step 9), add `INFRA_DECL` node before `MODE`; update `GIT_INIT` node label |
| HIGH | `README.md` | 112–126 | Update scaffold Mermaid flowchart: add infrastructure declaration node before Mode Selection; update "Git Init + Commit" label |
| HIGH | `docs/architecture.md` | 118–135 | Update scaffold `graph LR` diagram: add Step 0-INFRA node before Mode Selection; update "Git init" node |
| HIGH | `CLAUDE.md` | 66–73 | Update Scaffold Pipeline text diagram: add infrastructure step before mode selection |
| MEDIUM | `docs/reference/commands.md` | ~219 | Update prose description of `/scaffold` to mention infrastructure declaration step |

### B.3 Version Files

| Priority | File | Reason for Change |
|----------|------|-------------------|
| HIGH | `.claude-plugin/plugin.json` | Bump version to 5.5.0 (MINOR — new optional behavior, no breaking contract change) |
| HIGH | `.claude-plugin/marketplace.json` | Bump version to 5.5.0 in tandem with plugin.json |
| HIGH | `CHANGELOG.md` | Add new `## [5.5.0]` entry following the established MINOR format |

### B.4 Test Files

| Priority | File | Lines | Reason for Change |
|----------|------|-------|-------------------|
| HIGH | `tests/scenarios/scaffold-v2-happy-path.sh` | ~66 | Add grep assertions for new Step 0-INFRA strings (e.g., `"Infrastructure Declaration"` or design-chosen label); verify new steps present |
| MEDIUM | `tests/scenarios/scaffold-v2-no-implement.sh` | ~95 | Verify `"Create issues in your issue tracker"` grep target is still present after Step L6 report text is preserved; add check for Step 0-INFRA presence in --no-implement flow if applicable |

### B.5 Files That Must NOT Be Modified

| File | Reason |
|------|--------|
| `CHANGELOG.md` v5.3.0 section | Historical record — documents what shipped in v5.3.0; immutable |
| `docs/plans/roadmap.md` v5.3.0 DONE section | Completed items; historical |
| `docs/plans/2026-03-27-scaffold-infrastructure-design.md` | The new design document itself — describes changes to be made |
| All `docs/plans/2026-03-06-scaffold-v2-*.md` | Historical implementation plans for scaffold v2 (v4.x) |
| All `docs/plans/brainstorm/` files | Historical brainstorming |
| `docs/plans/2026-03-03-redmine-tracker-support-*.md` | Their "Step 4b" references are to `commands/onboard.md`, not scaffold |
| `docs/plans/2026-03-08-ac-pipeline-v5-plan*.md` | Their "Step 4b" references are to `implement-feature` and `reviewer`, not scaffold |

---

## Section C: Critical Findings & Design Gaps

### C.1 CRITICAL: init.md Cannot Run Inline — CLAUDE.md Dependency

**The design says "run `/init` inline" in Step 0-MCP. This is technically impossible without modification.**

init.md Step 1 performs an unconditional hard stop: `"No Automation Config found. Run /ceos-agents:onboard first."` — with no bypass parameter. CLAUDE.md is generated in scaffold's Step 3 (skeleton generation) — it does not exist when Step 0-MCP would run.

**Implication:** The phrase "run `/init` inline" must be interpreted as one of two approaches:
- **(Option A — Inline subset):** Scaffold replicates the relevant subset of init.md logic directly: skip Steps 1–2 (no CLAUDE.md yet), execute Steps 3–7 using tracker type already known from Step 0-INFRA declaration.
- **(Option B — Extend init.md):** Add a `--mcp-only` flag to init.md that skips the CLAUDE.md dependency check and accepts tracker type as a parameter.

Option A is simpler to implement. Option B avoids code duplication but requires a backward-compatible extension to init.md.

**This must be resolved before implementation begins (Phase 2 decision point).**

### C.2 CRITICAL: `--issue` Flag Implies tracker=ready (Design Gap)

The `--issue` flag causes scaffold to read an issue description from the tracker via MCP at Step 1. If `--issue` is provided, the user demonstrably has: a tracker project (they have an issue ID) and working MCP connectivity.

The design document does not address this case. Step 0-INFRA would still ask "Issue tracker: (a) ready / (b) later" — which is redundant and confusing when the user already passed `--issue`.

**Furthermore:** If the user declares "later" at Step 0-INFRA despite providing `--issue`, Step 1 will fail when attempting to read the issue via MCP. The design's "Impact on Existing Steps" table says "`--issue` input source works as before" — but this is only true if tracker is forced to "ready" when `--issue` is present.

**Recommended fix:** When `--issue` is provided, auto-set tracker = "ready", display "Detected issue tracker from --issue flag: auto-configuring", and skip the tracker question in Step 0-INFRA. The SC question must still be asked.

**This is a design gap that must be resolved before implementation.**

### C.3 CRITICAL: MCP Pre-flight Check References Step 9 — Easy to Miss

The MCP Pre-flight Check is a **policy section** located after Step 10 (lines 540–551), visually separated from the step definitions. It explicitly lists:

```
MCP pre-flight check is only required when:
- `--issue` flag is used (Step 1 — reading issue description from tracker)
- Step 9 — creating cards in issue tracker (only when tracker is configured and user opts in)
```

After the redesign:
- Step 9 is removed entirely
- MCP verification moves to Step 0-MCP (before Mode Selection)
- The trigger conditions change completely

This section is **easy to overlook** when updating the step definitions because it is in a separate trailing section. If left unchanged, it creates a contradiction where the policy references a step that no longer exists.

**Action required:** Rewrite the entire MCP Pre-flight Check section to reflect the new trigger model.

### C.4 CRITICAL: Test Files Have grep Assertions That Must Be Updated

The following grep patterns in test scenarios are anchored to strings that the redesign must either preserve or update:

**Strings that MUST be preserved** (removing these would break tests without test updates):
- `"Mode Selection"` — `scaffold-v2-happy-path.sh`
- `"Feature Implementation Loop"` — `scaffold-v2-happy-path.sh`
- `"E2E Tests"` — `scaffold-v2-happy-path.sh`
- `"Final Report"` — `scaffold-v2-happy-path.sh`
- `"Interactive"`, `"YOLO with checkpoint"`, `"Full YOLO"` — `scaffold-v2-happy-path.sh`
- `"Only one input source allowed"` — `scaffold-v2-input-conflicts.sh`
- `"--no-implement skips specification phase"` — `scaffold-v2-input-conflicts.sh`
- `"Legacy Flow"` — `scaffold-v2-no-implement.sh`
- `"EXIT pipeline"` — `scaffold-v2-no-implement.sh`
- `"Create issues in your issue tracker"` — `scaffold-v2-no-implement.sh` (from L6 report text)
- `"Spec iterations"` — `scaffold-v2-spec-loop.sh` and CLAUDE.md
- `"spec-writer.*spec-reviewer loop"` (regex) — `scaffold-v2-spec-loop.sh`
- `"max_iterations exhausted"` — `scaffold-v2-spec-loop.sh`

**New assertions that SHOULD be added** after redesign:
- A grep for the Step 0-INFRA label/text (whatever label is chosen in implementation)
- A grep verifying Step 4b and Step 4c are NOT present (regression guard)
- A grep verifying Step 9 is NOT present (regression guard)

### C.5 Mermaid Diagrams in 3+ Files Reference Scaffold Flow

Three files contain Mermaid diagrams that will become stale after the redesign:

| File | Diagram Type | Stale Elements |
|------|-------------|----------------|
| `README.md` (lines 112–126) | `flowchart TD` | No Step 0-INFRA before Mode Selection; "Git Init + Commit" label needs updating |
| `docs/architecture.md` (lines 118–135) | `graph LR` | No Step 0-INFRA before Mode Selection; "Git init" node needs updating |
| `docs/reference/pipelines.md` (lines 208–265) | `flowchart` (full) | `TRACKER` node (Step 9) between E2E and REPORT must be removed; Step 0-INFRA node must be added before MODE |

The `docs/reference/pipelines.md` diagram is the most critical — it is the canonical reference diagram and includes the `TRACKER` node (`E2E --> TRACKER{Issue Tracker Cards?} --> REPORT`) that directly represents Step 9 being removed.

**CLAUDE.md** also has a text-based pipeline diagram (lines 66–73) that omits Step 4b/4c and Step 9 (already simplified), but will need the infrastructure step prepended before "Mode selection".

---

## Section D: Edge Cases & Interactions

### D.1 Full YOLO Mode — Behavior Change Not Flagged

**This is an implicit breaking UX change.** In the current design, Full YOLO skips Step 4b entirely ("cannot guess tracker URLs in unattended mode"). The new design says "In Full YOLO mode, Step 0-INFRA question is STILL asked (it cannot be skipped)."

This inverts the current behavior: Full YOLO users who previously had tracker config silently skipped will now face an interactive infrastructure question. The design document handles this consciously but does not flag it as a behavior change. The CHANGELOG entry for v5.5.0 should explicitly note this.

### D.2 "Downgrade to later" Requires Explicit State Tracking

The design mentions that if MCP verification fails at Step 0-MCP, the user can "Continue without {service}" which effectively downgrades the service from "ready" to "later". The design does not specify the implementation:

**Required:** An effective-status variable (e.g., `tracker_status = "ready" | "later" | "downgraded"`) separate from what the user declared at Step 0-INFRA. This status must propagate to:
- Step 4 auto-fill: use TODO markers for tracker keys if downgraded
- Step 4d: skip push to remote if SC downgraded
- Step 4e: skip card creation if tracker downgraded
- Step 10 report: show appropriate status per service

**Special case with `--issue` flag:** If the user provided `--issue` and tracker MCP then fails at Step 0-MCP, downgrading means Step 1 cannot read the issue. The command must abort or offer: "Cannot read issue — MCP unavailable. Continue without --issue? [Y/n]"

### D.3 Step 0-INFRA Insertion Point — Ambiguity Resolved

The design says "very beginning of scaffold, before Mode Selection" but does not mention State Detection. State Detection (which runs before Step 0 Mode Selection) determines whether scaffolding is appropriate (existing project, git repo with changes, etc.) — it can stop the command entirely.

**Recommended insertion point:** After Flag Validation, after State Detection, before Step 0 (Mode Selection).

Rationale: There is no value in collecting infrastructure declarations before the guard gate that determines whether scaffold should proceed at all.

### D.4 Step 4e Guard for --no-implement Mode

The design states "legacy flow does not create tracker issues (no spec/epics to create from)". However, if Step 0-INFRA is inserted before the `--no-implement` exit point in Step 0, and the user declares tracker = "ready", Step 4e would be reached without spec/epics/ existing.

**Required guard:** Step 4e must explicitly check: `if no_implement = true OR spec/epics/ does not exist OR spec/epics/ is empty → skip`.

**SC interaction:** Step 4d (push to remote) should still run for `--no-implement` flows — the scaffolded skeleton can be pushed even without a spec. The design does not explicitly address this.

### D.5 --brainstorm Flag Ordering (UX Consideration)

`--brainstorm` triggers Step 0b (runs after Mode Selection, only in Interactive mode). Step 0-INFRA runs before Mode Selection. If `--brainstorm` is provided without a project description, the user is asked about infrastructure before being asked about their project — which may feel counterintuitive.

This is a UX concern only; there is no functional conflict. The Flag Validation's existing `--brainstorm AND --spec → Error` check has no interaction with Step 0-INFRA.

### D.6 `.mcp.json` Output Difference Between scaffold and init.md

`init.md` generates two files: `.mcp.json` (with real tokens, collected interactively) and `.mcp.json.example` (with `<YOUR_*>` placeholders). The design's Modified Step 4 generates only `.mcp.json.example` with placeholders — tokens are never requested during scaffold.

This means the new project still requires manual token fill before the pipeline can run. This is internally consistent in the design but is a notable difference from what `init.md` produces in a standalone run. The Step 10 Final Report should surface this under "Remaining setup required."

### D.7 Step 0b Brainstorming Phase — No Change

`--brainstorm` and Step 0b have no functional interaction with any of the new steps (0-INFRA, 0-MCP, 4d, 4e). Step 0b is unchanged.

---

## Section E: Version & Test Infrastructure

### E.1 Version Bump Required

**This redesign is a MINOR release (v5.5.0).** Rationale:
- New behavior added (Step 0-INFRA, Step 0-MCP, Step 4d, Step 4e)
- No new required keys in Automation Config (the infrastructure questions are asked interactively, not read from config)
- No changes to Automation Config contract that would force a MAJOR bump
- Existing `--no-implement` and full scaffold flows remain supported

Both `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` must be updated to `5.5.0` in the same commit.

### E.2 CHANGELOG Entry Requirements

Following the established MINOR format from v5.3.0:

```
## [5.5.0] — 2026-03-27

**MINOR** — scaffold infrastructure redesign: Step 0-INFRA declaration, MCP verification,
auto-push, pre-implementation tracker card creation. No breaking changes.

### Added
- **Step 0-INFRA:** ...
- **Step 0-MCP:** ...
- **Step 4d:** ...
- **Step 4e:** ...

### Changed
- **Full YOLO infrastructure questions:** ...  ← must call out the behavior change
- **Scaffold Steps 4b/4c replaced:** Replaces Steps 4b/4c and Step 9 with the new infrastructure flow.

### Details
- [counts, test pass count]
```

The CHANGELOG entry must explicitly state "Replaces Steps 4b/4c and Step 9" for history traceability between v5.3.0 (which introduced those steps) and v5.5.0 (which replaces them).

### E.3 Test Infrastructure — What Must Be Preserved and Added

**Tests are static markdown analysis** — `grep -q` against source files. No Claude API calls. All 4 scaffold test scenarios run against `commands/scaffold.md` text.

**Strings that must remain in `commands/scaffold.md` after redesign** (test breakage if removed):

| String | Test File | Risk if Removed |
|--------|-----------|-----------------|
| `"Mode Selection"` | scaffold-v2-happy-path.sh | FAIL |
| `"Feature Implementation Loop"` | scaffold-v2-happy-path.sh | FAIL |
| `"E2E Tests"` | scaffold-v2-happy-path.sh | FAIL |
| `"Final Report"` | scaffold-v2-happy-path.sh | FAIL |
| `"Interactive"` | scaffold-v2-happy-path.sh | FAIL |
| `"YOLO with checkpoint"` | scaffold-v2-happy-path.sh | FAIL |
| `"Full YOLO"` | scaffold-v2-happy-path.sh | FAIL |
| `"Only one input source allowed"` | scaffold-v2-input-conflicts.sh | FAIL |
| `"--no-implement skips specification phase"` | scaffold-v2-input-conflicts.sh | FAIL |
| `"Legacy Flow"` | scaffold-v2-no-implement.sh | FAIL |
| `"EXIT pipeline"` | scaffold-v2-no-implement.sh | FAIL |
| `"Create issues in your issue tracker"` | scaffold-v2-no-implement.sh | FAIL — this is in the L6 report Next steps; must remain |
| `"Spec iterations"` | scaffold-v2-spec-loop.sh | FAIL |
| `"spec-writer.*spec-reviewer loop"` (regex) | scaffold-v2-spec-loop.sh | FAIL |
| `"max_iterations exhausted"` | scaffold-v2-spec-loop.sh | FAIL |

**New tests to add** for the redesign:
- `scaffold-v2-infrastructure-declaration.sh` — verify Step 0-INFRA text present, Step 4b absent, Step 4c absent, Step 9 absent, Step 4d and Step 4e present

**Existing tests expected to require no changes:**
- `scaffold-v2-input-conflicts.sh` — all four checked flags remain (`--template`, `--spec`, `--issue`, `--no-implement`)
- `scaffold-v2-no-implement.sh` — legacy flow strings all remain; only risk is if L6 report text changes
- `scaffold-v2-spec-loop.sh` — no scaffold step dependency; checks spec-writer/spec-reviewer internals

### E.4 Run Tests Before Commit

Per project convention: run `./tests/harness/run-tests.sh` before committing any changes. All 19+ scenarios must pass.

---

## Section F: Open Design Questions for Later Phases

The following questions are not yet resolved and must be decided before or during implementation (Phase 2+):

| # | Question | Severity | Agent Who Raised It |
|---|----------|----------|---------------------|
| OQ1 | "Run `/init` inline" — Option A (inline subset) or Option B (extend init.md with `--mcp-only`)? Option A is simpler; Option B avoids duplication. | HIGH | Agent 2, Agent 4 |
| OQ2 | `--issue` flag must force tracker = "ready" in Step 0-INFRA — what is the exact auto-detect message and does it skip the SC question? | HIGH | Agent 4 |
| OQ3 | Exact label for the new step: "Step 0-INFRA", "Infrastructure Declaration", or another name? Must be consistent across all files and tests. | MEDIUM | Agent 3 |
| OQ4 | Step 4e `--no-implement` guard: should Step 4d (push) run for legacy flow? Design implies yes but does not state it explicitly. | MEDIUM | Agent 4 |
| OQ5 | "Downgrade to later" effective-status variable — what is the variable name and exact state transitions? Must be defined before Step 0-MCP is written. | MEDIUM | Agent 4 |
| OQ6 | Step 0-INFRA insertion: is "after State Detection, before Step 0 Mode Selection" the confirmed interpretation? Design says "very beginning" but that is ambiguous. | MEDIUM | Agent 4 |
| OQ7 | `--brainstorm` UX ordering — is asking about infrastructure before project description acceptable, or should Step 0-INFRA be deferred to after Step 0b in interactive mode? | LOW | Agent 4 |
| OQ8 | Modified Step 4 generates `.mcp.json.example` only (no real tokens). Should Step 10 Final Report explicitly surface "Tokens not configured — run `/ceos-agents:init` to complete setup"? | LOW | Agent 4 |
| OQ9 | "Spec Phase Questions" section in the design document refers to tracker-comment behavior for `--issue` that does not exist in current scaffold.md. Is this a future feature or dead text? | COSMETIC | Agent 4 |

---

## Summary: Scope Recap

**Files to change:** 10 (scaffold.md, pipelines.md, README.md, architecture.md, CLAUDE.md, commands.md, plugin.json, marketplace.json, CHANGELOG.md, +1 new test scenario)

**Files confirmed unchanged:** agents/ (all), checklists/, core/, examples/, docs/guides/, docs/plans/ (historical), state/schema.md, check-setup.md, init.md (unless Option B chosen for OQ1)

**Steps removed from scaffold.md:** Step 4b, Step 4c, Step 9

**Steps added to scaffold.md:** Step 0-INFRA, Step 0-MCP, Step 4d, Step 4e

**Test strings at risk if not preserved:** 15 identified grep anchors in 4 test files

**Critical blockers before implementation:** OQ1 (init.md inline strategy) and OQ2 (`--issue` auto-detect) must be resolved in Phase 2 design decisions.
