# Phase 3 Brainstorm: Scaffold MCP Chicken-and-Egg Fix

**Session:** Phase 3 Design Evaluation
**Date:** 2026-04-01
**Problem:** Scaffold Step 0-MCP detects missing MCP but cannot fix it. Init requires CLAUDE.md which does not exist yet. MCP tools require session restart after .mcp.json creation.

---

## Problem Decomposition

Before evaluating approaches, the problem breaks into four distinct sub-problems:

1. **Init depends on CLAUDE.md** (Step 1 reads tracker Type, Instance, SC Remote) -- but during scaffold, CLAUDE.md does not exist yet. Scaffold collects these same values at Step 0-INFRA but cannot pass them to init.

2. **Session restart is unavoidable.** Claude Code does not reload MCP tools when .mcp.json is created or modified mid-session. Any solution that creates .mcp.json must tell the user to restart.

3. **Resume gap.** Step 0-MCP re-runs on resume ONLY when `--infra` flag upgrades a service (later/downgraded -> ready). Without `--infra`, state is restored from state.json and Step 0-MCP is skipped entirely. This means: if .mcp.json is created between sessions (by init or manually), a plain `/scaffold` resume will not re-verify MCP -- the downgraded status persists.

4. **YOLO mode conflict.** Init requires interactive token input. YOLO mode = no prompts. Tokens are secrets and cannot be auto-generated or defaulted.

---

## Approach A: CLI Parameters on Init

### Description

Add optional CLI flags `--tracker-type <type>`, `--tracker-instance <url>`, `--sc-remote <owner/repo>` to init. When provided, these override Step 1's CLAUDE.md read -- init skips reading Automation Config for those values and uses the CLI params instead. Scaffold calls init with these flags, passing the values collected at Step 0-INFRA.

### Mechanism

1. Scaffold Step 0-INFRA collects tracker_type, tracker_instance, sc_remote (already does this).
2. When Step 0-MCP detects missing MCP, scaffold offers: "MCP not configured. Run `/ceos-agents:init --tracker-type {t} --tracker-instance {url} --sc-remote {r}` to set up, then restart session and resume scaffold."
3. Init, when invoked with these flags, skips the CLAUDE.md requirement for Step 1. The flags supply the three values CLAUDE.md would provide. Everything else (token collection, platform detection, .mcp.json generation) proceeds normally.
4. After init completes and session restarts, user resumes scaffold.

### Changes Required

- `skills/init/SKILL.md`: Add flag parsing (3 new optional flags), modify Step 1 to accept CLI overrides, update argument-hint.
- `skills/scaffold/SKILL.md`: Modify Step 0-MCP downgrade message to include the init invocation command with flags.
- Scaffold resume must handle the re-verification (see Resume Gap Fix below).

### Evaluation

| Criterion | Score | Rationale |
|-----------|-------|-----------|
| 1. DRY compliance | **5** | Init remains the single owner of .mcp.json generation. No logic duplication. Scaffold passes data, does not duplicate behavior. |
| 2. Backward compatibility | **5** | Flags are optional. Existing `init` (no flags) works unchanged -- still reads CLAUDE.md. Existing scaffold behavior unchanged unless user acts on the new guidance message. |
| 3. Session restart handling | **4** | Explicitly tells user to restart after init. Does not attempt mid-session reload. But requires two user actions (run init, restart, resume) which is friction. |
| 4. YOLO mode compatibility | **4** | YOLO auto-downgrades already (no init call in YOLO). The flags do not interfere. In non-YOLO, init still prompts for tokens interactively -- which is correct (secrets need human input). Slight gap: YOLO users who want MCP configured must still leave YOLO to run init. |
| 5. Resume compatibility | **2** | Without the Resume Gap Fix (below), resuming scaffold after running init will NOT re-verify MCP. The downgraded status in state.json persists. User must remember `--infra tracker:ready,sc:ready` on resume. This is the critical weakness -- the approach solves the init-without-CLAUDE.md problem but not the resume gap. |
| 6. Complexity | **4** | Moderate: 3 new optional flags in init, conditional Step 1 logic, updated scaffold messages. Well-scoped, low risk. |
| 7. Future extensibility | **5** | CLI flags on init are a general-purpose improvement. Future workflows (CI/CD setup, headless provisioning) benefit from parameterized init. Other skills can call init with flags. |

**Total: 29/35**

---

## Approach B: Scaffold Inline MCP Setup

### Description

Scaffold creates .mcp.json directly during Step 0-MCP (or immediately after), using the values from Step 0-INFRA. This bypasses init entirely for the scaffold flow.

### Mechanism

1. Step 0-INFRA collects tracker_type, tracker_instance, sc_remote.
2. Step 0-MCP detects missing MCP tools.
3. Scaffold loads the template from `examples/mcp-configs/{type}.json`, substitutes instance URL, writes .mcp.json with `<YOUR_*>` token placeholders.
4. Tells user: "Created .mcp.json with placeholder tokens. Fill in your tokens, restart session, then resume scaffold."
5. On resume, Step 0-MCP re-runs and verifies connectivity.

### Changes Required

- `skills/scaffold/SKILL.md`: Add .mcp.json generation logic in Step 0-MCP (template loading, env var substitution, file writing, .gitignore update).
- No changes to init.
- Scaffold resume must handle re-verification.

### Evaluation

| Criterion | Score | Rationale |
|-----------|-------|-----------|
| 1. DRY compliance | **2** | Duplicates init's core logic: template loading (Step 6), env var substitution, .gitignore management. Two places now know how to create .mcp.json. When a new tracker type is added, both must be updated. |
| 2. Backward compatibility | **5** | No contract changes. Scaffold gains new inline behavior but does not modify any existing interface. |
| 3. Session restart handling | **3** | Creates .mcp.json but with placeholder tokens. User must: (a) fill tokens, (b) restart session, (c) resume scaffold. Three actions vs. two in Approach A. Also, if user fills tokens incorrectly, there is no validation step before restart -- init has Step 7 (connectivity validation). |
| 4. YOLO mode compatibility | **3** | In YOLO mode, scaffold auto-downgrades already. If we add inline .mcp.json creation in YOLO, we create a .mcp.json with placeholders that the user never asked for -- potentially confusing. If we skip it in YOLO, the feature only helps non-YOLO users. |
| 5. Resume compatibility | **2** | Same resume gap as Approach A. The .mcp.json exists after restart, but state.json still says "downgraded" and Step 0-MCP is skipped without --infra. |
| 6. Complexity | **3** | Duplicating init's template logic inside scaffold adds significant surface area to an already 784-line file. The template-loading, env-var mapping, and .gitignore logic is non-trivial. |
| 7. Future extensibility | **2** | Inline logic is scaffold-specific. Does not benefit other workflows. If a third skill needs MCP setup, we duplicate a third time. |

**Total: 20/35**

---

## Approach C: Early Minimal CLAUDE.md

### Description

Scaffold writes a minimal CLAUDE.md (just the Automation Config skeleton with tracker Type, Instance, and SC Remote filled in) before calling init. After init completes and scaffold resumes, the scaffolder agent overwrites CLAUDE.md with the full generated version.

### Mechanism

1. Step 0-INFRA collects tracker_type, tracker_instance, sc_remote.
2. Step 0-MCP detects missing MCP.
3. Scaffold writes a minimal CLAUDE.md:
   ```markdown
   ## Automation Config
   ### Issue Tracker
   | Key | Value |
   |-----|-------|
   | Type | {tracker_type} |
   | Instance | {tracker_instance} |
   ### Source Control
   | Key | Value |
   |-----|-------|
   | Remote | {sc_remote} |
   ```
4. Tells user: "Run `/ceos-agents:init` to configure MCP, then restart and resume scaffold."
5. Init reads the minimal CLAUDE.md successfully at Step 1.
6. On scaffold resume, Step 3 (scaffolder) generates the full CLAUDE.md, overwriting the minimal one.

### Changes Required

- `skills/scaffold/SKILL.md`: Add minimal CLAUDE.md generation in Step 0-MCP fallback path.
- No changes to init.
- Scaffold resume must handle re-verification.

### Evaluation

| Criterion | Score | Rationale |
|-----------|-------|-----------|
| 1. DRY compliance | **4** | Init stays unchanged. But scaffold now knows the minimal structure of Automation Config -- this is a partial coupling to the config format. If the required keys change, scaffold's minimal template must update too. |
| 2. Backward compatibility | **4** | No contract changes, but introduces a new artifact (minimal CLAUDE.md) that exists temporarily. If the user inspects the project between init and scaffold resume, they see an incomplete CLAUDE.md. If scaffold crashes before overwriting, a broken CLAUDE.md persists. |
| 3. Session restart handling | **4** | Same as Approach A: user runs init (which now works because CLAUDE.md exists), restarts, resumes. Two actions. |
| 4. YOLO mode compatibility | **3** | Same YOLO tension as Approach A. Additionally, writing a file that will be overwritten later is conceptually wasteful in YOLO mode. |
| 5. Resume compatibility | **2** | Same resume gap. State.json still says "downgraded" after restart. |
| 6. Complexity | **3** | The minimal CLAUDE.md is a new artifact with lifecycle concerns: when is it created? When is it overwritten? What if scaffold fails between creation and overwrite? The temporary file introduces a new state that all downstream steps must be aware of. |
| 7. Future extensibility | **3** | The minimal CLAUDE.md pattern is scaffold-specific. It does not help other workflows. It also creates a precedent of "write temporary config files" that may lead to similar hacks elsewhere. |

**Total: 23/35**

---

## Approach D: Init Flag Params + Scaffold Resume Auto-Recheck (Recommended)

### Description

Combines Approach A (CLI params on init) with a targeted fix to the resume gap: scaffold resume ALWAYS re-runs Step 0-MCP for services that are in "downgraded" state, even without `--infra` flag. This eliminates the need for users to remember `--infra` on resume.

### Mechanism

#### Part 1: Init CLI Params (same as Approach A)

Add `--tracker-type`, `--tracker-instance`, `--sc-remote` to init. Scaffold's Step 0-MCP downgrade message tells the user exactly what to run.

#### Part 2: Resume Auto-Recheck (the resume gap fix)

Modify scaffold Step 0-INFRA "On resume" logic. Currently:

> **If no `--infra` flag:** Restore in-memory variables from state as before. Display: `Resumed infrastructure state from previous run.`

Change to:

> **If no `--infra` flag:** Restore in-memory variables from state. **If any service has `effective_status == "downgraded"`, automatically re-run Step 0-MCP for those services.** Display: `Resumed infrastructure state. Re-checking previously downgraded services...`

The rationale: "downgraded" means "was ready but MCP failed." This is distinct from "later" (user chose to defer). A downgraded service SHOULD be re-checked on every resume because the user may have fixed the issue between sessions. A "later" service should NOT be re-checked (user explicitly deferred).

#### Part 3: State Upgrade on Successful Recheck

If the auto-recheck succeeds (MCP now available), update state.json:
- Set `{service}_effective_status` from `"downgraded"` to `"ready"`
- Display: `{service} MCP is now available. Upgrading from downgraded to ready.`

If the auto-recheck fails again, keep "downgraded" and continue (same behavior as current downgrade path).

### Changes Required

- `skills/init/SKILL.md`: Add flag parsing (3 new optional flags), modify Step 1 to accept CLI overrides, update argument-hint.
- `skills/scaffold/SKILL.md`: (a) Update Step 0-MCP downgrade message, (b) Add auto-recheck logic for downgraded services in the "On resume" section of Step 0-INFRA.
- `state/schema.md`: No schema change needed -- "downgraded" is already a valid value for infrastructure statuses.

### Evaluation

| Criterion | Score | Rationale |
|-----------|-------|-----------|
| 1. DRY compliance | **5** | Init owns .mcp.json generation. Scaffold owns infrastructure state and MCP verification. No duplication. |
| 2. Backward compatibility | **5** | Init flags are optional. Resume auto-recheck is additive behavior -- if nothing was downgraded, no change in behavior. "later" services still skip recheck. |
| 3. Session restart handling | **5** | Explicit guidance: "Run init with flags, restart, resume scaffold." On resume, scaffold auto-detects the newly available MCP. No manual --infra flag needed. The three-step flow (init -> restart -> resume) is the minimum possible given the platform constraint. |
| 4. YOLO mode compatibility | **4** | YOLO auto-downgrades as before. On YOLO resume, auto-recheck runs silently for downgraded services. If MCP became available, YOLO resumes with full integration automatically. If not, stays downgraded silently. Only gap: YOLO cannot run init (interactive tokens). |
| 5. Resume compatibility | **5** | This is the key differentiator. The resume gap is fully addressed: downgraded services are always rechecked. No user action needed beyond the restart. The "downgraded" vs "later" semantic distinction makes the behavior intuitive: downgraded = "we wanted it but it failed, keep trying"; later = "user chose to skip, respect their choice." |
| 6. Complexity | **4** | Two changes: (a) init flags (3 optional params + conditional Step 1), (b) resume auto-recheck (small addition to Step 0-INFRA On resume). Both are well-scoped. The auto-recheck is 5-10 lines of logic in scaffold. |
| 7. Future extensibility | **5** | Init CLI flags enable headless/scripted init. Resume auto-recheck establishes a pattern: any "downgraded" infrastructure auto-recovers on resume. This pattern applies to future infrastructure types (e.g., deployment targets, CI runners). |

**Total: 33/35**

---

## Approach E: Scaffold-Owned MCP Bootstrap with Init Delegation

### Description

A hybrid where scaffold writes ONLY the .mcp.json (not tokens -- just the server entry with placeholders), then on resume delegates to init for token collection and validation. This avoids the "init needs CLAUDE.md" problem entirely because scaffold never calls init during the first session.

### Mechanism

1. Step 0-INFRA collects tracker_type, tracker_instance, sc_remote.
2. Step 0-MCP detects missing MCP.
3. Scaffold writes .mcp.json with the correct server entry but `<YOUR_*>` token placeholders. Also writes .mcp.json.example (identical content at this stage).
4. Displays: "Created .mcp.json with placeholder tokens. Fill in your tokens in .mcp.json, then restart session and resume scaffold."
5. On resume (with the resume auto-recheck from Approach D), Step 0-MCP re-verifies. If MCP works, great. If not, keeps "downgraded."

### Changes Required

- `skills/scaffold/SKILL.md`: Add .mcp.json creation logic in Step 0-MCP (template loading, env var substitution).
- No changes to init.
- Add resume auto-recheck from Approach D.

### Evaluation

| Criterion | Score | Rationale |
|-----------|-------|-----------|
| 1. DRY compliance | **2** | Same DRY violation as Approach B. Scaffold now duplicates init's template-loading and .mcp.json generation logic. |
| 2. Backward compatibility | **5** | No contract changes. |
| 3. Session restart handling | **4** | Creates .mcp.json directly, so user only needs to fill tokens and restart. But no token validation step (init's Step 7). User might restart with wrong tokens and waste a cycle. |
| 4. YOLO mode compatibility | **3** | Creates an unsolicited .mcp.json in YOLO mode. Conceptually odd -- YOLO users did not ask for MCP setup artifacts. |
| 5. Resume compatibility | **5** | With the auto-recheck, resume works well. But the DRY cost makes this less maintainable than Approach D. |
| 6. Complexity | **3** | Template loading in scaffold + resume auto-recheck = two independent changes, one of which duplicates existing logic. |
| 7. Future extensibility | **2** | Scaffold-specific. No reuse for other workflows. |

**Total: 24/35**

---

## Approach F: State-Driven Init (Shared State File)

### Description

Instead of CLI flags, scaffold writes its infrastructure values to a shared state file (e.g., `.ceos-agents/pending-init.json`) that init reads as an alternative to CLAUDE.md.

### Mechanism

1. Step 0-MCP downgrade path: scaffold writes `tracker_type`, `tracker_instance`, `sc_remote` to `.ceos-agents/pending-init.json`.
2. User runs init. Init checks for `pending-init.json` before reading CLAUDE.md. If found, uses those values instead.
3. After init completes, it deletes `pending-init.json`.
4. User restarts and resumes scaffold.

### Evaluation

| Criterion | Score | Rationale |
|-----------|-------|-----------|
| 1. DRY compliance | **4** | Init owns .mcp.json generation. But introduces a new communication channel (shared state file) that both skills must agree on. |
| 2. Backward compatibility | **5** | Optional file. Init without the file works as before. |
| 3. Session restart handling | **4** | Same as Approach A. |
| 4. YOLO mode compatibility | **4** | Same as Approach A. |
| 5. Resume compatibility | **2** | Same resume gap as Approach A without the auto-recheck addition. (Could be combined with D's auto-recheck for 5.) |
| 6. Complexity | **3** | Introduces a new artifact (`pending-init.json`) with its own lifecycle. Init must handle detection, reading, and cleanup. More moving parts than CLI flags. File-based IPC is fragile (partial writes, stale files, cleanup failures). |
| 7. Future extensibility | **3** | The shared state pattern is reusable but file-based IPC between skills is a weak contract. CLI flags are more explicit and discoverable. |

**Total: 25/35** (or 28/35 if combined with D's auto-recheck)

---

## Comparison Matrix

| Criterion | A: CLI Params | B: Inline MCP | C: Early CLAUDE.md | **D: CLI + Auto-Recheck** | E: Scaffold Bootstrap | F: Shared State |
|-----------|:---:|:---:|:---:|:---:|:---:|:---:|
| 1. DRY | 5 | 2 | 4 | **5** | 2 | 4 |
| 2. Backward compat | 5 | 5 | 4 | **5** | 5 | 5 |
| 3. Session restart | 4 | 3 | 4 | **5** | 4 | 4 |
| 4. YOLO compat | 4 | 3 | 3 | **4** | 3 | 4 |
| 5. Resume compat | 2 | 2 | 2 | **5** | 5 | 2 |
| 6. Complexity | 4 | 3 | 3 | **4** | 3 | 3 |
| 7. Extensibility | 5 | 2 | 3 | **5** | 2 | 3 |
| **Total** | **29** | **20** | **23** | **33** | **24** | **25** |

---

## Recommendation: Approach D

**Approach D (Init CLI Params + Resume Auto-Recheck)** scores highest at 33/35 and directly addresses all four sub-problems:

1. **Init without CLAUDE.md**: CLI flags bypass the CLAUDE.md requirement.
2. **Session restart**: Explicit guidance, minimum friction (init -> restart -> resume).
3. **Resume gap**: Auto-recheck of downgraded services eliminates the need for `--infra` on resume.
4. **YOLO mode**: Auto-downgrade + silent auto-recheck on YOLO resume. No conflict.

### Why not the others?

- **A** is D without the resume fix. It solves 3 of 4 sub-problems but leaves the resume gap -- the user must remember `--infra tracker:ready` on resume.
- **B** and **E** duplicate init logic inside scaffold. DRY violation is a maintenance hazard in a pure-markdown plugin where there is no shared code to extract.
- **C** creates a temporary CLAUDE.md artifact with lifecycle concerns and partial config-format coupling.
- **F** introduces file-based IPC between skills -- more complex than CLI flags for no additional benefit.

### Implementation Scope

Two files change:

1. **`skills/init/SKILL.md`** -- Add 3 optional CLI flags, modify Step 1 to accept overrides.
2. **`skills/scaffold/SKILL.md`** -- (a) Update Step 0-MCP downgrade message to include init invocation with flags. (b) Add auto-recheck clause in Step 0-INFRA "On resume" for downgraded services.

One file optionally updated:

3. **`state/schema.md`** -- No schema change required (downgraded is already valid), but could add documentation clarifying the semantic difference between "downgraded" and "later" for the auto-recheck behavior.

### Version Impact

- Init CLI flags = new backward-compatible feature = **MINOR**
- Scaffold resume behavioral change (auto-recheck) = behavioral fix without contract change = **PATCH**
- Combined: **MINOR** version bump

### Resume Gap Fix: Precise Specification

The "On resume" section in scaffold Step 0-INFRA (currently lines 132-140) needs one additional clause. After the existing "If no `--infra` flag" case:

```
- **If no `--infra` flag:** Restore in-memory variables from state as before.
  - **Auto-recheck for downgraded services:** For each service where
    `{service}_effective_status == "downgraded"`:
    - Display: `Previously downgraded {service} — re-checking MCP availability...`
    - Re-run Step 0-MCP for that service only.
    - If MCP is now available: set `{service}_effective_status = "ready"`,
      update state.json. Display: `{service} MCP now available. Status: ready.`
    - If MCP still unavailable: keep "downgraded", display:
      `{service} MCP still unavailable. Continuing with downgraded status.`
  - For services with `effective_status == "later"`: no action (user chose
    to defer; respect their choice).
  - Display: `Resumed infrastructure state from previous run.`
```

The key semantic distinction:
- **"downgraded"** = wanted but failed -> auto-retry on every resume
- **"later"** = user explicitly chose to skip -> never auto-retry (use `--infra` to upgrade)

### Open Questions for Spec Phase

1. Should init validate that CLI-provided `--tracker-type` matches the lookup table in `core/mcp-detection.md`? (Recommendation: yes, fail early on invalid type.)
2. Should the auto-recheck have a max-retry limit (e.g., stop rechecking after 3 consecutive downgrade confirmations)? (Recommendation: no -- the user must explicitly run init between sessions, so unbounded recheck is safe. It only fires on resume, not in a loop.)
3. Should init's `--update` flag compose with the new CLI flags? (Recommendation: yes -- `--update --tracker-type gitea` should update an existing .mcp.json with a new tracker type.)
