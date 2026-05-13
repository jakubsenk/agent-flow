# Agent 2: Innovative UX Designer — Brainstorm Analysis

**Role:** Developer Experience Architect
**Perspective:** User mental model, CLI ergonomics, "if the user runs a second command, we failed"
**Date:** 2026-03-27

---

## 1. Implementation Ordering

Recommended file modification order, optimized for incremental testability and UX coherence:

### Tier 1: Core behavioral change (the scaffold command itself)

| Order | File | Rationale |
|-------|------|-----------|
| 1 | `commands/scaffold.md` — removals (4b, 4c, 9) | Clear the dead weight first. Every edit afterward works on a cleaner canvas. Removing the "configure later" anti-patterns is the UX win. |
| 2 | `commands/scaffold.md` — add Step 0-INFRA + 0-MCP | The heart of the redesign. This is where the user's first impression changes from "scaffold dumps TODOs on me" to "scaffold asks me what I have, then does the work." |
| 3 | `commands/scaffold.md` — extend Step 4, add 4d + 4e | These are the payoff steps. The user declared intent at 0-INFRA; now scaffold actually delivers on that promise. |
| 4 | `commands/scaffold.md` — MCP Pre-flight rewrite + renumbering | Cleanup pass. Fix all "Step 10" references to "Step 9", rewrite MCP Pre-flight, add infrastructure section to Final Report. |

### Tier 2: Documentation alignment (must reflect the UX change accurately)

| Order | File | Rationale |
|-------|------|-----------|
| 5 | `docs/reference/pipelines.md` | The authoritative pipeline reference. Stages table and Mermaid diagram updates. Do this before README/CLAUDE.md because those are summaries of this document. |
| 6 | `CLAUDE.md` | The ASCII pipeline diagram and Scaffold Pipeline section. This is what Claude Code reads as context for every session. Must be accurate before any testing. |
| 7 | `docs/architecture.md` | The `graph LR` Mermaid diagram. Quick 2-line edit. |
| 8 | `README.md` | The `flowchart TD` Mermaid diagram. Quick 2-line edit. |
| 9 | `docs/reference/commands.md` | Prose update for /scaffold description. Low risk, low priority. |

### Tier 3: Testing + versioning

| Order | File | Rationale |
|-------|------|-----------|
| 10 | `tests/scenarios/scaffold-v2-happy-path.sh` | Add new assertions, update "Step 10" references. Run the test suite to validate all changes. |
| 11 | `tests/scenarios/scaffold-v2-no-implement.sh` | Add 0-INFRA assertion. |
| 12 | `CHANGELOG.md` | Write once, after all behavioral changes are settled. |
| 13 | `.claude-plugin/plugin.json` + `marketplace.json` | Version bump. Absolute last step. |

**Key principle:** Modify the behavior first, then make the docs match, then verify with tests, then stamp with a version. Never version-bump before tests pass.

---

## 2. Step 0-INFRA Placement — After State Detection, Before Mode Selection

**Verdict: The research's confirmed position is correct. After State Detection, before Mode Selection.**

From a UX perspective, this is the only defensible position. Here is the reasoning through the lens of the user's mental model:

**State Detection is a guard, not a question.** The user does not experience State Detection as a "step" — it is an automatic safety check. If the directory has uncommitted changes or already has a CLAUDE.md, scaffold stops the user before they invest any cognitive effort. This is the "are you sure you meant to come here?" bouncer at the door.

**Step 0-INFRA is the first real question.** Once the user passes the guard, the very first thing they should hear is: "What infrastructure do you have?" This frames the entire scaffold session. The user's answer to "do you have a tracker?" and "do you have a repo?" sets expectations for everything that follows: whether scaffold will create issues, whether it will push to a remote, whether the Final Report says "you're done" or "here's what you still need to set up."

**Why NOT before State Detection:** If you ask "what's your tracker?" and then immediately say "oh wait, this directory already has a project — did you mean to run /implement-feature?", you have wasted the user's time and trust. The user answered a meaningful question for nothing. That is the cardinal sin of CLI UX.

**Why NOT after Mode Selection:** Mode Selection (Interactive/YOLO/Full YOLO) is about HOW the user wants to interact with the pipeline. Infrastructure Declaration is about WHAT the user has available. "What do you have?" must come before "how do you want to work?" because the answer to "what" constrains the answer to "how" (e.g., Full YOLO with tracker=ready means auto-create issues; Full YOLO with tracker=later means skip issue creation entirely).

**The `--no-implement` edge case is handled correctly:** Step 0-INFRA fires before the `--no-implement` early exit at Step 0. This means even `--no-implement` users benefit from infrastructure declaration. The legacy flow's L5 gets extended with push behavior. This is good — even a skeleton-only scaffold should be pushable if the user has a repo ready.

---

## 3. init.md Inline Invocation — My Vision for Seamless MCP Setup

The research resolved this as **Option A: replicate MCP subset inline, do NOT call /init**. I agree with this decision, but I want to articulate the UX vision more clearly because the implementation is at risk of becoming a mechanical copy-paste of init.md logic rather than a thoughtfully designed inline experience.

### The dream UX (what the user should experience)

```
Before we scaffold, tell me about your infrastructure:

1. Issue tracker:
   (a) I have a tracker project ready → What type? [youtrack/github/jira/linear/gitea/redmine]
   (b) Not now — I'll set it up later via /init + /onboard

2. Source control:
   (a) I have a git repo ready → What's the remote? (e.g., org/my-project)
   (b) Not now — I'll set it up later

[If tracker=ready]
Checking MCP connectivity for YouTrack...
  ✅ MCP server found. Verifying access to project PROJ...
  ✅ Connected. 42 issues visible.

[If tracker=ready but MCP missing]
  ⚠ No MCP server for YouTrack detected in this session.
  You can continue without it — scaffold will generate .mcp.json.example
  with placeholders. Run /ceos-agents:init after scaffold to complete setup.
  Continue? [Y/n]
```

### What "replicate MCP subset inline" must NOT become

It must NOT become a wizard. The moment you ask the user for a token during scaffold, you have broken the flow. Scaffold is about creating a project, not configuring developer credentials. The boundary is:

- **Step 0-INFRA collects:** tracker type, tracker instance URL, tracker project key, SC remote, SC base branch. These are PROJECT-level decisions.
- **Step 0-MCP verifies:** whether MCP is already available in the current session. This is a DETECTION step, not a configuration step.
- **Step 4 generates:** `.mcp.json.example` with placeholders. This is a FILE GENERATION step.
- **/ceos-agents:init** (run separately after scaffold): collects TOKENS, generates `.mcp.json`, validates connectivity. This is a DEVELOPER ENVIRONMENT step.

The research document correctly identifies this boundary. The risk is in the implementation: someone might see "replicate init.md Steps 3-7" and think they should also replicate the token collection (init.md Step 4). They should not.

### The `.mcp.json.example` is the handoff artifact

This is an underappreciated UX insight. The `.mcp.json.example` file is the physical manifestation of "scaffold did its job, now you do yours." It contains the correct server names, the correct env var names, and placeholder tokens. When the user runs `/ceos-agents:init` later, init should DETECT this file and use it as a template — auto-filling everything except the tokens. This creates a seamless two-step experience:

1. `/scaffold` asks what you have, verifies MCP if possible, generates `.mcp.json.example`
2. `/ceos-agents:init` reads `.mcp.json.example`, asks only for tokens, writes `.mcp.json`

This handoff is not explicitly documented in the design. It should be.

---

## 4. Documentation Update Strategy

### Principle: Docs describe the UX, not the implementation

The documentation updates should be written from the user's perspective, not from the developer's perspective. The user does not care that "Step 4b was removed and its logic was moved to Step 0-INFRA." The user cares that "scaffold now asks about your infrastructure upfront and sets it up automatically."

### Specific strategy per doc

| Document | Audience | Voice | Update Focus |
|----------|----------|-------|--------------|
| `commands/scaffold.md` | Claude Code (the AI reading and executing) | Imperative, precise | Exact step logic, guard clauses, in-memory state management |
| `docs/reference/pipelines.md` | Plugin developers, contributors | Reference, neutral | Stages table accuracy, Mermaid diagram correctness |
| `docs/reference/commands.md` | Users discovering commands | Friendly, benefit-oriented | "What it does" prose: emphasize that scaffold now handles infrastructure setup |
| `docs/architecture.md` | Architecture-level readers | Structural | Mermaid diagram: add Infrastructure Declaration node |
| `README.md` | First-time visitors | Marketing-adjacent | Mermaid diagram: show that scaffold includes infrastructure; this is a selling point |
| `CLAUDE.md` | Claude Code (session context) | Compact, authoritative | ASCII diagram: must be accurate because Claude reads this for every session |
| `CHANGELOG.md` | Users upgrading from v5.4.x | What changed, what to watch out for | Full YOLO behavior change is the most important callout |

### The CHANGELOG entry deserves special attention

The v5.5.0 CHANGELOG must frame this as a UX improvement, not a refactoring. Proposed structure:

```
## [5.5.0] — YYYY-MM-DD

### Added
- Step 0-INFRA: scaffold now asks about tracker and source control before mode selection
- Step 0-MCP: scaffold verifies MCP connectivity for declared services
- Step 4d: auto-push to remote when source control is ready
- Step 4e: auto-create tracker issues from spec/epics/ when tracker is ready

### Changed
- Full YOLO mode now asks the infrastructure question (Step 0-INFRA) — previously,
  tracker configuration was silently skipped
- Final Report (formerly Step 10, now Step 9) includes infrastructure status section
- .mcp.json.example is generated during scaffold for future /init runs

### Removed
- Step 4b (Tracker Configuration) — replaced by Step 0-INFRA
- Step 4c (MCP Guidance) — replaced by Step 0-MCP
- Step 9 (Issue Tracker Optional) — replaced by Step 4e (moved before implementation)
```

---

## 5. Step Numbering — "0-INFRA" / "0-MCP" User-Friendliness

### Assessment: The alphanumeric suffixes are acceptable but not ideal

"Step 0-INFRA" communicates "this happens before Step 0" which is correct. But the naming has issues:

**Problem 1: "0-INFRA" reads like a code variable, not a step name.** When the user encounters this in a report or error message, "Step 0-INFRA" feels like internal jargon. Compare with "Step 0: Mode Selection" which is immediately understandable.

**Problem 2: Sub-steps 4d/4e break the mental model of "step 4 = Git Init."** Step 4 was a simple concept: initialize git and commit. Now it has four sub-steps (4, 4d, 4e), which makes it feel like a mini-pipeline within the pipeline. The letter suffixes (d, e) skip a/b/c because those were removed, which is confusing for anyone reading the step list without historical context.

### Alternative proposals

**Option A (recommended): Named phases instead of numbered sub-steps**

Instead of `0-INFRA`, `0-MCP`, `0`, `0b`, use phase groupings:

```
Phase 0: Setup
  - Infrastructure Declaration (was 0-INFRA)
  - MCP Verification (was 0-MCP)
  - Mode Selection (was Step 0)
  - Brainstorming (was Step 0b)

Phase 1-3: Specification + Skeleton (unchanged)

Phase 4: Integration
  - Git Init (was Step 4)
  - Push to Remote (was Step 4d)
  - Create Tracker Issues (was Step 4e)

Phase 5-8: Implementation (unchanged numbers)
Phase 9: Report
```

**Why this is better:** The user's mental model groups related steps. "Setup" is a natural phase. "Integration" is a natural phase. The numbered steps within each phase can be flat (just sequential within the phase).

**Why this might be rejected:** It is a larger naming change than the design intended. The existing step numbering is already established in v4.0.0+ and changing it risks test breakage and documentation churn across many files.

**Option B (minimal, pragmatic): Keep 0-INFRA and 0-MCP but use descriptive headings**

Keep the step numbers as-is for internal references and tests, but use descriptive headings in user-facing output:

```
### Step 0-INFRA: Infrastructure Declaration
### Step 0-MCP: MCP Verification
```

The step number is a label; the heading is what the user reads. This is what the design already specifies and it works well enough.

**Option C: Renumber everything as integers**

Steps become: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15. But this breaks every existing test assertion and documentation reference. Rejected for being too disruptive.

**My recommendation: Option B. The design's naming is good enough. Do not let perfect naming block the UX improvement.**

---

## 6. Testing — Verifying the UX Flow

### The existing test harness is structural, not behavioral

The current tests in `tests/scenarios/` are `grep`-based: they verify that certain strings exist in `commands/scaffold.md`. This is a necessary minimum but it tests nothing about UX flow. You cannot grep your way to "the user experiences a coherent onboarding."

### What the tests should verify (within the constraints of a markdown plugin)

**Tier 1: Structural assertions (can be tested now)**

These are the grep-based tests from the research document. They verify that the right steps exist and the removed steps are gone:

```bash
# New steps present
grep -q "Infrastructure Declaration" "$SCAFFOLD_CMD"
grep -q "0-MCP" "$SCAFFOLD_CMD"
grep -q "Push to Remote" "$SCAFFOLD_CMD"
grep -q "Create Tracker Issues" "$SCAFFOLD_CMD"

# Old steps removed
! grep -q "Step 4b" "$SCAFFOLD_CMD"
! grep -q "Step 4c" "$SCAFFOLD_CMD"
! grep -q "Step 9: Issue Tracker" "$SCAFFOLD_CMD"

# Renumbering complete
grep -q "Step 9: Final Report" "$SCAFFOLD_CMD"
! grep -q "Step 10" "$SCAFFOLD_CMD"
```

**Tier 2: Ordering assertions (should be added)**

The tests should verify that steps appear in the correct order. This is critical for the UX because if 0-INFRA appears after Mode Selection, the entire design is broken:

```bash
# Step 0-INFRA must appear before Mode Selection
INFRA_LINE=$(grep -n "Infrastructure Declaration" "$SCAFFOLD_CMD" | head -1 | cut -d: -f1)
MODE_LINE=$(grep -n "Step 0: Mode Selection" "$SCAFFOLD_CMD" | head -1 | cut -d: -f1)
if [ "$INFRA_LINE" -ge "$MODE_LINE" ]; then
  echo "FAIL: Step 0-INFRA must appear before Step 0 Mode Selection"
  exit 1
fi
```

This is a new category of test assertion that the current test suite does not have. It directly validates the UX ordering.

**Tier 3: Cross-file consistency (should be added)**

Verify that the pipeline stages table in `pipelines.md` matches the steps in `scaffold.md`:

```bash
# Stages table must include 0-INFRA
grep -q "0-INFRA" "$REPO_ROOT/docs/reference/pipelines.md"

# Stages table must NOT include old Step 9 Issue Tracker
! grep -q "| 9 | Issue Tracker" "$REPO_ROOT/docs/reference/pipelines.md"
```

**Tier 4: No dangling references (should be added)**

After all edits, verify no "Step 10" references remain in scaffold.md:

```bash
# No remaining "Step 10" references
if grep -q "Step 10" "$SCAFFOLD_CMD"; then
  echo "FAIL: Found dangling 'Step 10' reference in scaffold.md"
  exit 1
fi
```

### What CANNOT be tested in this harness but should be noted

- Whether the in-memory state actually carries from Step 0-INFRA to Step 4d/4e (this is runtime behavior of Claude Code's Task tool, not testable via grep)
- Whether the MCP connectivity check actually works (requires a real MCP server)
- Whether the Full YOLO behavior change is correctly communicated to the user (requires human review of the CHANGELOG)

---

## 7. Risk Mitigation — UX Pitfalls

### Top 3 Implementation Risks (Ranked)

**Risk #1: The in-memory state illusion (CRITICAL)**

The entire design relies on values collected at Step 0-INFRA being "carried in-memory" to Steps 4, 4d, and 4e. But this is a markdown command file executed by Claude Code's conversation context, not a program with variables. The "in-memory state" is actually "Claude remembers what the user said 10,000 tokens ago." If the conversation is long (Full YOLO with many features), Claude may lose track of the exact tracker_type or sc_remote values. The scaffold.md prose must be EXTREMELY explicit: "Use the tracker_type value from Step 0-INFRA. Do NOT re-read CLAUDE.md." This instruction must appear at EVERY step that uses in-memory values, not just in the MCP Pre-flight section.

**Mitigation:** Add a "Required in-memory values" preamble to Steps 4, 4d, and 4e that explicitly lists what values to use and where they came from. This serves as a context anchor for the LLM executing the command.

**Risk #2: Full YOLO surprise prompt (HIGH)**

In v5.3.0, Full YOLO users experience zero prompts during scaffold (after mode selection). In v5.5.0, Step 0-INFRA introduces a mandatory question even in Full YOLO mode. This is a behavior change that will surprise power users. The design correctly identifies this but underestimates the impact: Full YOLO users chose Full YOLO specifically because they do not want to be asked things. Being asked "what tracker do you have?" when they expected complete automation feels like a regression.

**Mitigation:** Consider a `--infra later,later` CLI flag that pre-answers the infrastructure question. If provided, Step 0-INFRA auto-sets both to "later" with no prompt. This preserves Full YOLO's zero-prompt experience for users who do not have infrastructure ready. The design does not mention this flag. It should.

**Risk #3: Step 4e creating issues before implementation (MEDIUM-HIGH)**

The design moves issue creation from Step 9 (after implementation) to Step 4e (after skeleton, before implementation). This is a fundamental UX change. In v5.3.0, issues were created from IMPLEMENTED features — the user knew what was done. In v5.5.0, issues are created from SPEC EPICS — the user is committing to a plan that has not been executed yet. If implementation blocks on 3 of 5 epics, the tracker will have 5 issues but only 2 are actually done. This creates a misleading tracker state.

**Mitigation:** Step 4e should mark created issues with a "planned" or "draft" status, not "in progress." The Final Report (Step 9) should update the status of implemented issues to the On start set state from Automation Config. Issues for blocked features should be marked as blocked. This two-phase status update is not in the design but is essential for tracker accuracy.

---

## One Concern the Design Missed

### The `.mcp.json.example` to `/ceos-agents:init` handoff is not specified

The design says Step 4 generates `.mcp.json.example`. The design says the Final Report tells the user to "run `/ceos-agents:init` to complete MCP setup." But nowhere does it specify that `/ceos-agents:init` should DETECT and USE the `.mcp.json.example` file as a pre-filled template.

Currently, `init.md` Step 2 checks for `.mcp.json` existence but says nothing about `.mcp.json.example`. If the user runs `/ceos-agents:init` after scaffold, init will ask all the questions from scratch — tracker type, instance URL, token — even though scaffold already collected the tracker type and instance URL and wrote them into `.mcp.json.example`.

This means the user answers the SAME questions twice: once during scaffold (Step 0-INFRA) and again during init (Steps 3-4). That is exactly the "if the user has to run a second command, we failed" anti-pattern.

**Proposed fix (out of scope for v5.5.0 but should be filed as a follow-up):** Add a Step 1b to `init.md`: "If `.mcp.json.example` exists, read it. Pre-fill tracker type, instance URL, and server configuration from the example file. Only ask for tokens." This makes init a 30-second token-paste operation instead of a 3-minute wizard re-run.

For v5.5.0, the minimum viable fix is: the Final Report (Step 9) should include a clear instruction: "Copy `.mcp.json.example` to `.mcp.json` and fill in your tokens" as an alternative to running `/ceos-agents:init`. This gives users the fast path without requiring changes to init.md.

---

## GO/NO-GO Recommendation

### GO — with two conditions

**Condition 1:** Add explicit "Required in-memory values" blocks to Steps 4, 4d, and 4e in `commands/scaffold.md`. The research document identifies this risk but the mitigation is only in the MCP Pre-flight section. It must be at the point of use.

**Condition 2:** The CHANGELOG entry must clearly call out the Full YOLO behavior change. Users who run `scaffold --no-implement` in Full YOLO mode will now be prompted. This is not a bug, it is a design decision, but it must be communicated.

**Why GO:**
- The current UX (scaffold dumps TODOs, user runs 3 more commands) is objectively bad
- The redesign front-loads the one question that matters ("what infrastructure do you have?") and eliminates the dead-end steps
- The research is thorough: all edge cases (--issue auto-detect, --no-implement legacy flow, Full YOLO behavior) have been analyzed
- The risk of in-memory state loss is mitigable through prompt engineering (explicit state references in each step)
- The file change set is well-scoped: 1 critical file (scaffold.md), 5 doc files, 2 test files, 3 metadata files

**Why not NO-GO:**
- The design does not introduce any breaking changes to the Automation Config contract
- The step numbering is additive (0-INFRA, 0-MCP, 4d, 4e) — no existing step numbers change except 10 becoming 9
- Test assertions are well-documented with exact strings to grep for
- The init.md handoff gap is a follow-up, not a blocker

---

## Summary

| Item | Verdict |
|------|---------|
| Implementation ordering | scaffold.md removals first, then additions, then docs, then tests, then version |
| Step 0-INFRA placement | Correct: after State Detection, before Mode Selection |
| init.md inline invocation | Option A (replicate subset) is correct; add "Required in-memory values" blocks |
| Documentation strategy | Update docs to reflect UX benefit, not implementation details; CHANGELOG is critical |
| Step numbering | "0-INFRA" / "0-MCP" is acceptable; consider `--infra` CLI flag for Full YOLO |
| Testing | Add ordering assertions and cross-file consistency checks |
| Risk #1 | In-memory state loss in long conversations — mitigate with explicit state anchors |
| Risk #2 | Full YOLO surprise prompt — mitigate with `--infra` flag (follow-up) |
| Risk #3 | Premature issue creation — mitigate with two-phase status updates |
| Missed concern | `.mcp.json.example` to `/init` handoff not specified |
| **GO/NO-GO** | **GO** (with 2 conditions) |
