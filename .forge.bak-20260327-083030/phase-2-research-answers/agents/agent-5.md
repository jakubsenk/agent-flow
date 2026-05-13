# Research Answers — RQ-17 through RQ-20: Forge-Plan vs Architect Compatibility, Versioning

---

## RQ-17: Forge-Plan vs Architect Task Tree Schema — Compatibility

**Question:** What is the architect's exact output format, and how would forge-plan's output compare?

### Architect's Required YAML Schema

Sourced from `agents/architect.md` lines 46-65 (Process step 7):

```yaml
decomposition:
  strategy: sequential | parallel | mixed
  reason: "Brief explanation why decomposition is needed"
  subtasks:
    - id: "sub-1"
      title: "Short description"
      scope: "What exactly to do"
      files:
        - path/to/file1.ext
        - path/to/file2.ext
      estimated_lines: 25
      depends_on: []
      maps_to:
        - "AC-1: {text of the parent feature/bug AC this subtask addresses}"
        - "AC-3: {text of another parent AC}"
      acceptance_criteria:
        - "Testable criterion 1"
        - "Testable criterion 2"
```

**Required fields per subtask:** `id`, `title`, `scope`, `files`, `estimated_lines`, `depends_on`, `maps_to`, `acceptance_criteria`.

Runtime fields added by the orchestrating command (not the architect): `status`, `commit_hash`, `restore_point`.

### Forge-Plan Output Format

Sourced from `.forge.bak-20260325-204006/phase-6-plan/final.md` (the actual forge-plan output from Phase A planning):

Forge-plan produces a **prose markdown document** (not YAML), structured as:

```
## PR N: Title (vX.Y.Z)

### Task N.M: Short description
- **Files:** list
- **Change:** prose description
- **Dependencies:** N.X or "none"
- **Estimated lines:** integer
- **Acceptance:** shell command
- **Rollback:** git command
```

Key structural differences:

| Field | Architect YAML | Forge-Plan Prose |
|-------|---------------|-----------------|
| Format | YAML block | Markdown prose with bold labels |
| Task ID | `id: "sub-1"` | `### Task N.M:` heading |
| Scope | `scope:` field | `**Change:**` field |
| Dependencies | `depends_on: []` | `**Dependencies:**` prose |
| Lines estimate | `estimated_lines: 25` | `**Estimated lines:** integer` |
| Acceptance criteria | `acceptance_criteria:` list | `**Acceptance:**` shell command |
| `maps_to` | Required field with `AC-N:` format | **Absent** — no field |
| `strategy` | Top-level field | Described in parallel execution tables separately |
| `reason` | `reason:` field | **Absent** — implied by PR title |

### Compatibility Assessment

The formats are **structurally incompatible**. The architect schema is YAML consumed by `implement-feature.md` Step 5 via programmatic parsing (`maps_to` index extraction, topological sort). The forge-plan output is human-readable prose designed for LLM interpretation and developer review, not machine parsing.

The forge-plan output also lacks the `maps_to` field entirely, which is not a cosmetic omission — it is the mechanism for AC coverage traceability (see RQ-18).

**Confidence:** HIGH. Both formats were read directly from source files. The forge-plan output is a real example artifact, not a hypothetical.

---

## RQ-18: Forge-Plan AC Maps_to Gap — Coverage Check Failure

**Question:** Would the AC coverage check in implement-feature always fail on forge-plan output?

### AC Coverage Check Algorithm

Sourced from `commands/implement-feature.md` lines 123-137 (Step 5, "AC coverage check"):

```
AC matching algorithm:
- Each maps_to entry uses format AC-{N}: {text} where N is 1-based index
- Coverage check: collect all N values from all subtasks' maps_to fields,
  verify that every integer from 1 to {total parent AC count} appears at least once
- Text after AC-N: is informational — matching is by index only
- If a maps_to entry cannot be parsed (no AC-{N}: prefix) → treat as warning, not error
```

The check also applies in `commands/scaffold.md` Step 5 (lines 304-311): "For each epic individually (using format `AC-{N}: {text}` as per architect constraints)."

### What Forge-Plan Output Lacks

The forge-plan format does not include a `maps_to` field on any task. It has:
- `**Acceptance:**` — a shell command verifying the task is done (e.g., `grep -c 'state.json' commands/fix-ticket.md`)
- No `maps_to:` entries linking to parent AC indices

### Failure Mode Analysis

If forge-plan output were passed to implement-feature's AC coverage check:

1. The command collects `maps_to` references from all subtasks → finds zero entries
2. It computes the set difference: all parent AC indices (1..N) minus mapped indices (empty set) = all parent ACs unmapped
3. Result:
   - In YOLO mode → **immediate Block** ("Incomplete decomposition — unmapped AC detected")
   - In non-YOLO mode → warning displayed, user must confirm "Continue anyway? [Y/n]"

**The check would always produce a warning/block on unmodified forge-plan output.** It would not silently pass. The non-YOLO path allows human override; YOLO mode would hard-block.

### The Parsing Fallback

There is one softening rule: "If a `maps_to` entry cannot be parsed (no `AC-{N}:` prefix) → treat as warning, not error." This applies when a `maps_to` field exists but is malformed. It does NOT apply when the field is entirely absent — absence means zero entries collected, triggering the set-difference calculation to show all AC as unmapped.

**Confidence:** HIGH. The exact algorithm is specified in `commands/implement-feature.md` lines 134-137. The forge-plan output format was verified from the real Phase A artifact.

**NEEDS_VALIDATION:** Whether `implement-feature.md` would even receive forge-plan output depends on the integration design. If forge-plan output is translated/adapted before being consumed, the mismatch may be handled at the translation layer rather than detected at the AC coverage step.

---

## RQ-19: Epic-to-Card Creation Sequence — Pre-Implementation vs Post-Implementation

**Question:** Which creation sequence is more compatible with MCP capabilities?

### Current MCP Pre-Flight Check Placement

Sourced from `commands/implement-feature.md` lines 58-65 (Step 0, "MCP pre-flight check"):

```
Before any pipeline operation, verify MCP tool availability.
- Check that at least one mcp__* tool matching the tracker type is accessible
- If not accessible → STOP with error message
```

The MCP check is the **first action** in implement-feature, before branch creation, before spec-analyst, before anything else.

### Scaffold's Card Creation Sequence (Post-Implementation)

Sourced from `commands/scaffold.md` Step 9 (lines 435-455):

```
### Step 9: Issue Tracker (Optional)

Check if Issue Tracker section in generated CLAUDE.md has TODO markers
  (look for <!-- TODO: in Instance or Project values).
If TODO markers present → skip (no tracker configured).

If tracker configured and mode is not Full YOLO:
  "Create cards in issue tracker for implemented features? [Y/n]"

  If yes:
    For each spec/epics/*.md:
      Create epic card
      For each user story: create sub-issue, link to spec file
```

Scaffold's MCP check is only required when `--issue` flag is used (Step 1) or when Step 9 executes. If `--issue` is not used, MCP availability is **not checked at startup** — the pipeline proceeds through spec-writing, scaffolding, architecture, implementation, and testing without touching MCP at all. Card creation is optional, interactive (user opts in), and skipped entirely in Full YOLO mode.

### Compatibility Analysis

**Pre-implementation card creation (forge integration calling implement-feature per card):**
- implement-feature's MCP pre-flight runs at step 0 — before branch creation
- If MCP is unavailable at any point, the entire pipeline stops
- Cards must exist in the tracker before the pipeline can verify their state and set "In Progress"
- Creating cards pre-implementation means MCP must be available at pipeline entry; any MCP outage blocks the entire run

**Post-implementation card creation (scaffold's Step 9 model):**
- MCP is not contacted until after all implementation is complete
- Implementation proceeds on local git state only (spec/, code, tests)
- If MCP is unavailable, the user is asked whether to skip card creation or retry
- Cards can also be created manually after the fact (scaffold leaves TODO markers)
- Full YOLO mode skips card creation entirely — no MCP dependency

**Conclusion:** Post-implementation card creation (scaffold's Step 9 model) is more compatible with MCP capabilities because:
1. It avoids MCP as a blocking pre-condition — implementation can proceed without a working tracker connection
2. It is opt-in and interactive — the user is asked whether to create cards
3. It has an explicit TODO-marker detection that allows graceful degradation when tracker is not configured
4. It matches the scaffold pipeline's design principle that MCP is only required when the `--issue` flag is used

The pre-implementation sequence (implement-feature model) is necessary when the issue tracker is the authoritative source for the work item (the issue already exists and drives the pipeline). Post-implementation creation is appropriate when the work is self-contained and the tracker is a downstream notification target, not a driver.

**Confidence:** HIGH. The MCP pre-flight placement in implement-feature (step 0) and scaffold (step 9 optional) is explicit in both command files.

---

## RQ-20: Versioning Impact of New Optional Config Keys

**Question:** Is adding deploy config keys MINOR or MAJOR? Can existing Hooks be used?

### Versioning Policy (from `CLAUDE.md` lines 200-206)

| Level | Trigger |
|-------|---------|
| MAJOR | Breaking change in Automation Config contract — new required key, renamed section — OR breaking change in agent output format contract |
| MINOR | New backward-compatible feature — new optional key, new command/agent |
| PATCH | Behavior fix without contract change |

**Key rule:** "Adding a **required** key to Automation Config = MAJOR. Adding an **optional** section = MINOR."

### Deploy Config Keys: MINOR or MAJOR?

New deploy config keys (e.g., `Compose file`, `Health check URL`, `Services`, `Deploy command`) added as an **optional** section would be a **MINOR** bump.

Evidence: This is the exact precedent set by Browser Verification. Per project memory (MEMORY.md):
- Browser Verification was added in v5.1.0 as a new optional config section with 8 keys
- The version bump was MINOR (v5.0.0 → v5.1.0), not MAJOR
- The section is listed in CLAUDE.md's Config Contract under "Optional sections"

The versioning policy explicitly states: "optional Hooks section" as a MINOR example. Browser Verification followed this pattern exactly.

**If any deploy key is made required** (e.g., `Deploy command` added to the required sections table), that would be MAJOR. The distinction is solely required vs. optional.

### Can Existing Hooks Be Used?

The existing Hooks section supports 4 hook points: `Pre-fix`, `Post-fix`, `Pre-publish`, `Post-publish`.

Each hook runs a Bash command:
- Pre-fix: before fixer runs
- Post-fix: after fixer + reviewer approve
- Pre-publish: before publisher creates PR
- Post-publish: after PR is created

**Deployment use case analysis:**

- `Pre-publish`: Could run a local build/smoke test before the PR is created. Suitable for "verify nothing is broken before PR."
- `Post-publish`: Runs after PR creation (not after merge). Suitable for "notify deployment system that a PR is ready."

**Gap:** There is no post-merge hook. `Post-publish` fires on `pr-created` event (per `commands/implement-feature.md` lines 277-280). The `Verify command` (Build & Test section) runs after merge, but it is a verification command, not a hook — it cannot run arbitrary deployment logic, only verify success/failure.

For a full deployment workflow (e.g., `docker compose up` after PR merge), the existing hooks are **insufficient** without a new hook category. Adding a new hook category (e.g., `Post-merge`, `Deploy`) would itself be a MINOR bump (new optional section). Using the existing `Verify command` as a deployment trigger is a workaround: set `Verify command` to a deployment script. This fits within the current contract without a version bump.

**Summary:**
- New optional deploy config section: **MINOR** bump
- New required deploy config key: **MAJOR** bump
- Using existing `Hooks`: **partially sufficient** (pre/post publish only, no post-merge hook)
- Using `Verify command` as deploy trigger: **works within current contract, no bump needed**
- Adding a dedicated `Deploy` hook category: **MINOR** bump (new optional section)

**Confidence:** HIGH for versioning rules (explicit in CLAUDE.md). MEDIUM for hooks sufficiency — the Verify command workaround is inferred from the contract; it was not validated against a real deployment scenario.
