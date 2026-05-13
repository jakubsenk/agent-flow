# Phase 2 Research Synthesis: Scaffold Infrastructure Redesign
# Definitive Reference Document

**Synthesized from:** 5 research agents (Agent 1–5)
**Phase 1 input:** `.forge/phase-1-research-questions/final.md`
**Date:** 2026-03-27
**Scope:** Implementation reference for `docs/plans/2026-03-27-scaffold-infrastructure-design.md`

---

## 1. Complete File Change Matrix

| File | Priority | What Changes | Line Ranges | Risk |
|------|----------|--------------|-------------|------|
| `commands/scaffold.md` | CRITICAL | Remove Step 4b entirely | L263–L298 | High — 36 lines deleted; internal jump refs must also update |
| `commands/scaffold.md` | CRITICAL | Remove Step 4c entirely | L300–L307 | Medium — 8 lines deleted |
| `commands/scaffold.md` | CRITICAL | Remove Step 9 entirely | L481–L501 | High — 21 lines deleted; MCP pre-flight refs must update |
| `commands/scaffold.md` | CRITICAL | Add Step 0-INFRA (new section) | Insert after L47 (after State Detection), before L51 (Step 0) | High — new prose; exact label must match test assertions |
| `commands/scaffold.md` | CRITICAL | Add Step 0-MCP (new section) | Insert immediately after Step 0-INFRA | High — MCP inline strategy resolved to Option A (inline subset, not `/init` call) |
| `commands/scaffold.md` | CRITICAL | Extend Step 4 (Git Init) | L251–L261 | Medium — add auto-fill + `.mcp.json.example` generation prose |
| `commands/scaffold.md` | CRITICAL | Add Step 4d (Push to Remote) | Insert after L261 (after Step 4) | Medium — new prose; includes Full YOLO run-without-confirmation behavior |
| `commands/scaffold.md` | CRITICAL | Add Step 4e (Create Tracker Issues) | Insert after Step 4d | Medium — Full YOLO skips; `--no-implement` guard required; spec/epics/ existence guard required |
| `commands/scaffold.md` | CRITICAL | Rewrite MCP Pre-flight Check section | L540–L551 | High — entire section replaced; remove Step 9 ref, add Step 4e + `--issue` + 0-INFRA in-memory value refs |
| `commands/scaffold.md` | HIGH | Update "jump to Step 10" internal refs | L443, L449 | Low — simple text replace: "Step 10" → "Step 9" |
| `commands/scaffold.md` | HIGH | Update MCP pre-flight "Step 9" ref | L544 | Low — simple text replace: "Step 9" → "Step 4e" |
| `commands/scaffold.md` | HIGH | Rename Step 10 heading | L503 | Low — `### Step 10: Final Report` → `### Step 9: Final Report` |
| `commands/scaffold.md` | MEDIUM | Update Step 9 (now Final Report) content | L505–L538 | Low — add infrastructure status section to report display |
| `docs/reference/pipelines.md` | CRITICAL | Remove Step 9 row from Stages table | L281 | Low — single row deletion |
| `docs/reference/pipelines.md` | CRITICAL | Renumber Step 10 row to Step 9 | L282 | Low — single cell edit |
| `docs/reference/pipelines.md` | CRITICAL | Add 0-INFRA, 0-MCP, 4d, 4e rows to Stages table | After L272 (Step 0 row) and after L276 (Step 4 row) | Medium — 4 new rows; note ordering: 0-INFRA and 0-MCP before Step 0 |
| `docs/reference/pipelines.md` | CRITICAL | Update Mermaid diagram: remove TRACKER node | L256–L257 (`E2E --> TRACKER{...} --> REPORT` chain) | Medium — remove node + edges, reconnect `E2E --> REPORT` |
| `docs/reference/pipelines.md` | CRITICAL | Update Mermaid diagram: add INFRA_DECL node | L211 (`DETECT -->|Empty| MODE`) | Medium — insert node between DETECT empty-path and MODE; also add INFRA after START/before DETECT or between DETECT and MODE |
| `docs/reference/pipelines.md` | HIGH | Update Mermaid diagram: label GIT_INIT change or add PUSH/CREATE_ISSUES nodes | L232, L237 | Medium — `GIT_INIT --> ARCHITECT` chain gains 4d/4e nodes |
| `README.md` | HIGH | Update Scaffold Pipeline mermaid diagram: add InfraDecl node before Mode | L112–L124 | Low — insert single node; update `Desc --> Mode` edge to `Desc --> Infra --> Mode` |
| `docs/architecture.md` | HIGH | Update scaffold graph LR: add node before Mode selection | L118–L127 | Low — insert single node `A --> A2[Infrastructure Declaration] --> B` |
| `CLAUDE.md` | HIGH | Update Scaffold Pipeline text diagram | L66–L73 | Low — prepend `[0-INFRA] → [0-MCP] →` before `User description → [Mode selection]` |
| `docs/reference/commands.md` | MEDIUM | Update /scaffold "What it does" prose | L219 | Low — add 1–2 sentences about infrastructure declaration before mode selection |
| `CHANGELOG.md` | HIGH | Add new v5.5.0 entry | Before current `## [5.4.1]` entry | Low — append-only; frozen once written |
| `.claude-plugin/plugin.json` | HIGH | Bump version 5.4.1 → 5.5.0 | `"version"` field | Low — single field |
| `.claude-plugin/marketplace.json` | HIGH | Bump version 5.4.1 → 5.5.0 | `"version"` field inside `plugins[0]` | Low — single field; must match plugin.json |
| `tests/scenarios/scaffold-v2-happy-path.sh` | HIGH | Add assertions for new steps; verify renamed Final Report heading | ~L66 (add after existing assertions) | Medium — new step label strings must exactly match scaffold.md text |
| `tests/scenarios/scaffold-v2-no-implement.sh` | MEDIUM | Add assertion that Step 0-INFRA exists; verify legacy flow strings preserved | ~L34 area | Low — additive only; no removal |

**Files confirmed requiring NO changes:**

- `agents/` (all 19 files)
- `checklists/` (all files)
- `core/` (all files)
- `state/` (all files)
- `examples/` (all files)
- `docs/guides/` (all files — installation.md, mcp-configuration.md, custom-agents.md, etc.)
- `docs/plans/` (all files — historical; design plan itself is source, not target)
- `commands/init.md` — inline strategy resolved as Option A (scaffold replicates subset, no init.md changes)
- `commands/onboard.md`, `commands/init.md` — their own "Step 9" labels are for different commands, unrelated
- `tests/scenarios/scaffold-v2-input-conflicts.sh` — no step-specific assertions; all flag strings remain
- `tests/scenarios/scaffold-v2-spec-loop.sh` — no step-specific assertions; all spec-loop strings remain
- `tests/harness/run-tests.sh` — auto-discovers scenario files; no changes needed

---

## 2. Design Decisions Resolved

### Decision 1: init.md Inline Strategy — CANNOT invoke inline → replicate MCP subset in scaffold

**Resolution: Option A — scaffold replicates the relevant MCP logic inline. init.md is NOT modified.**

**Rationale:** `commands/init.md` Step 1 has a hard unconditional gate: it reads Automation Config from CLAUDE.md and errors immediately (`"No Automation Config found. Run /ceos-agents:onboard first."`) with no bypass parameter. During scaffold's Step 0-MCP, the target project CLAUDE.md does not yet exist (skeleton generation is Step 3). Calling `/init` inline would fail immediately.

**What scaffold's Step 0-MCP must implement directly (replicating init.md Steps 3–7):**

1. Accept tracker type and instance URL from Step 0-INFRA in-memory state (do NOT read CLAUDE.md).
2. Determine the correct MCP package from the tracker type using the same lookup table from `docs/reference/trackers.md`:
   - `youtrack` → `@vitalyostanin/youtrack-mcp`, token: `YOUTRACK_TOKEN`, extra: `YOUTRACK_URL`
   - `github` → `@modelcontextprotocol/server-github`, token: `GITHUB_PERSONAL_ACCESS_TOKEN`
   - `jira` → `@modelcontextprotocol/server-atlassian`, token: `ATLASSIAN_API_TOKEN`, extras: `ATLASSIAN_URL`, `ATLASSIAN_EMAIL`
   - `linear` → `@modelcontextprotocol/server-linear`, token: `LINEAR_API_KEY`
   - `gitea` → `forgejo-mcp` (binary), token: `FORGEJO_TOKEN`, extra: `FORGEJO_URL`
   - `redmine` → `mcp-server-redmine`, token: `REDMINE_API_KEY`, extra: `REDMINE_HOST`
3. Check if MCP tool is accessible: look for at least one `mcp__*` tool matching the tracker type.
4. If not accessible: offer inline setup guidance (do NOT block; offer `[Y/n]` to continue without or run setup).
5. Step 4 (Git Init extension) generates `.mcp.json.example` only — with `<YOUR_*>` placeholders. Real tokens are never collected during scaffold (user must run `/ceos-agents:init` separately after scaffold).

**Consequence for Step 10 Final Report:** Must surface "Tokens not configured — run `/ceos-agents:init` to complete MCP setup" when `.mcp.json.example` was generated but `.mcp.json` does not exist.

---

### Decision 2: --issue auto-detect — YES, auto-set tracker=ready

**Resolution: When `--issue` is provided, Step 0-INFRA auto-sets tracker = "ready" and skips the tracker question.**

**Rationale:** The `--issue` flag means the user has an existing tracker issue ID. This implies tracker is already accessible. Asking "Is your tracker ready?" after the user just provided an issue ID is redundant and confusing. Additionally, if the user were to answer "later" despite providing `--issue`, Step 1 (which reads the issue via MCP) would fail.

**Exact behavior:**

1. If `--issue` is detected during Flag Parsing:
   - Step 0-INFRA sets `tracker_status = "ready"` automatically.
   - Display: `Detected issue tracker from --issue flag: tracker auto-configured as ready.`
   - Do NOT ask the tracker question. Skip directly to the SC question.
2. Source Control question is still asked normally.
3. At Step 0-MCP: verify tracker MCP connectivity. If MCP is unavailable:
   - Display: `Could not reach tracker to fetch issue {ID}. Please describe your project instead.`
   - Downgrade `tracker_effective_status = "downgraded"`.
   - Discard the `--issue` flag's input source. Fall back to asking for a project description.
4. This fallback must be handled before the MCP pre-flight check to avoid a hard stop.

---

### Decision 3: Step 0-INFRA position — after State Detection, before Mode Selection

**Resolution: Confirmed order:**

```
Flag Parsing → Flag Validation → State Detection → Step 0-INFRA → Step 0-MCP → Step 0 (Mode Selection) → Step 0b (Brainstorm) → Step 1 ...
```

**Rationale:** State Detection (lines L38–L47) guards whether scaffold should proceed at all — it checks for existing projects, CLAUDE.md presence, and uncommitted git changes. If State Detection stops the command ("Existing project with CLAUDE.md → use /implement-feature"), asking infrastructure questions first is wasted effort and confusing UX.

Step 0-INFRA inserts at line L49 (after L47 `If state is not 1 and user does not confirm → stop.`) and before L51 (`### Step 0: Mode Selection`).

**For `--no-implement`:** The `--no-implement` early exit at Step 0 (L55–L56) currently reads: `If --no-implement: → Skip to legacy flow`. The redesign adds Step 0-INFRA and Step 0-MCP before Step 0, which means `--no-implement` will pass through Step 0-INFRA and Step 0-MCP first. The design document explicitly states: "Step 0-INFRA is added before L1 but the legacy flow does not create tracker issues." This means:
- Step 0-INFRA runs for `--no-implement`.
- Step 0-MCP runs for `--no-implement`.
- The `--no-implement` exit to legacy flow happens at Step 0 (after 0-INFRA and 0-MCP).
- Legacy flow's Step L5 (git init) may optionally add Step 4d behavior (push to remote if SC=ready); see Decision 5.

---

### Decision 4: Full YOLO + Step 4e — SKIP (consistent with current Step 9 rule)

**Resolution: Step 4e (Create Tracker Issues) is SKIPPED in Full YOLO mode.**

**Rationale:** This directly mirrors the current Step 9 behavior:

> "If mode is Full YOLO and tracker configured: Skip — do not create cards automatically in Full YOLO."

Creating tracker issues is a collaborative action requiring human oversight of naming, status, and hierarchy. Full YOLO defers post-scaffold tracker management to the human.

**Full YOLO behavior matrix for new steps:**

| Step | Full YOLO Behavior |
|------|--------------------|
| Step 0-INFRA | ASKED — prerequisite decision, cannot be skipped |
| Step 0-MCP | Attempted automatically. If MCP unavailable: downgrade to "later" automatically (no prompt) |
| Step 0 (Mode Selection) | Skipped — Full YOLO already selected |
| Step 4 auto-fill | Runs without confirmation prompts |
| Step 4d (Push to Remote) | Runs without confirmation if SC=ready. Failure is WARN only (no stop) |
| Step 4e (Create Tracker Issues) | SKIPPED — consistent with former Step 9 Full YOLO behavior |

**Note:** Step 0-INFRA question being asked in Full YOLO is an intentional behavior change from v5.3.0 (where Step 4b was silently skipped). The CHANGELOG entry must call this out.

---

### Decision 5: --no-implement + Step 4d — not directly applicable (legacy flow exits before Step 4)

**Resolution: Step 4d does NOT run for `--no-implement` via the main pipeline path. The legacy flow's Step L5 (Git Init) should be extended with push behavior if SC=ready.**

**Rationale:** The `--no-implement` early exit at Step 0 redirects to the legacy flow (L1–L6), which has its own L5 Git Init step. The main pipeline's Step 4, Step 4d, and Step 4e are never reached. However, Step 0-INFRA runs before the exit, meaning SC may be declared "ready."

**Required legacy flow change:**

After the legacy flow's L5 Git Init, add L5b: if SC=ready → attempt push to remote (WARN on failure, do not block). This matches the intent of Step 4d for the legacy path.

**Step 4e for `--no-implement`:** Definitively does NOT run. No spec/epics/ directory is generated by the legacy flow. The design explicitly states this is by design.

**Step 4e guard clause (also applicable to main flow):**

```
If Full YOLO mode → SKIP Step 4e
If --no-implement OR spec/epics/ does not exist OR spec/epics/ is empty → SKIP Step 4e
```

---

### Decision 6: MCP Pre-flight Check rewrite — reference Step 0-MCP and --issue, not Step 9

**Resolution: The entire MCP Pre-flight Check section (L540–L551) is replaced.**

**New content:**

```markdown
## MCP Pre-flight Check

After v5.5.0, MCP availability is verified proactively at Step 0-MCP — not lazily before individual
operations. The pre-flight logic below covers cases outside Step 0-MCP coverage.

**Cases requiring an additional MCP check:**

- `--issue` flag: Step 1 fetches the issue description from the tracker. Before fetching, verify the
  tracker MCP tool is still accessible (Step 0-MCP may have run earlier in the session but the tool
  could become unavailable). If inaccessible → apply `--issue` downgrade fallback (see Step 0-INFRA).

- `--no-implement` legacy flow: Step 0-INFRA fires before L1 (stack-selector). If the user declared
  tracker or SC as "ready", verify MCP accessibility before L1. For "later" services, no MCP check
  is needed.

**When Step 0-MCP covers the check (no additional pre-flight needed):**

- Step 4d (push to remote): SC MCP was verified at Step 0-MCP. No additional check.
- Step 4e (create tracker issues): Tracker MCP was verified at Step 0-MCP. No additional check.

**Standard error message:**

If MCP inaccessible at any check point:
→ STOP: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics
  or `/ceos-agents:init` to configure."

**Critical — in-memory state for Steps 4d and 4e:** Do NOT re-read CLAUDE.md for tracker type or
remote values in Steps 4d and 4e. CLAUDE.md may still contain TODO markers at that point. Use the
values collected at Step 0-INFRA stored in-memory as `tracker_type`, `tracker_instance`,
`sc_remote`, `tracker_effective_status`, `sc_effective_status`.
```

---

## 3. Critical Implementation Notes

### Note 1: In-memory state for infrastructure decisions (do NOT re-read CLAUDE.md)

Steps 4d and 4e run after Step 4 (Git Init) which writes CLAUDE.md with auto-filled values. However, CLAUDE.md may still contain TODO markers for keys the user skipped or that auto-fill could not resolve. Re-reading CLAUDE.md at Step 4d/4e would produce unreliable results.

**The following values must be captured at Step 0-INFRA and carried in-memory throughout the pipeline:**

| Variable | Source | Used By |
|----------|--------|---------|
| `tracker_type` | User answer at Step 0-INFRA | Step 0-MCP, Step 4e, MCP pre-flight |
| `tracker_instance` | User answer at Step 0-INFRA | Step 0-MCP, Step 4, Step 4e |
| `tracker_project` | User answer at Step 0-INFRA | Step 4, Step 4e |
| `sc_remote` | User answer at Step 0-INFRA | Step 4, Step 4d |
| `sc_base_branch` | User answer at Step 0-INFRA (default: main) | Step 4d |
| `tracker_effective_status` | `"ready"` \| `"later"` \| `"downgraded"` | Step 4, Step 4e |
| `sc_effective_status` | `"ready"` \| `"later"` \| `"downgraded"` | Step 4, Step 4d |

`tracker_effective_status` starts as the user's declared value from Step 0-INFRA. It downgrades to `"downgraded"` if Step 0-MCP fails connectivity check and user chooses to continue. `tracker_effective_status = "downgraded"` causes Step 4e to skip and Step 4 to keep TODO markers for tracker keys.

---

### Note 2: Step renumbering cascade — Step 10 stays Step 10, CORRECTION: it becomes Step 9

After removing Step 9 (Issue Tracker Optional), the former Step 10 (Final Report) must be renumbered to Step 9. The following renumbering cascade applies:

| Old Step | New Step | Location |
|----------|----------|----------|
| Step 10 | Step 9 | `commands/scaffold.md` L503 heading |
| "jump to Step 10" | "jump to Step 9" | L443, L449 |
| Stages table `\| 10 \|` | `\| 9 \|` | `docs/reference/pipelines.md` L282 |

**Steps 5–8 are NOT renumbered.** Their labels remain unchanged. Step 0-INFRA and Step 0-MCP use alphanumeric suffixes (not integer 0.1/0.2), so there is no integer gap before Step 1.

**Pipeline count in CHANGELOG entry:** The stage count in Final Report is not a user-facing number. The Stages table in pipelines.md will show: 0-INFRA, 0-MCP, 0, 0b, 1, 2, 3, 4, 4d, 4e, 5, 6, 7, 7b, 8, 9 — a total of 16 named stages (down from 15 named stages by +4 new −3 removed +1 renaming = net +1 real stage).

---

### Note 3: Test assertions that will break and what to replace them with

**Assertions confirmed safe (will NOT break if scaffold.md text is preserved as-is):**

| Assertion | File | Verdict |
|-----------|------|---------|
| `grep -q "Mode Selection"` | happy-path | Safe — Step 0 heading unchanged |
| `grep -q "spec-writer"` | happy-path | Safe |
| `grep -q "spec-reviewer"` | happy-path | Safe |
| `grep -q "architect agent"` | happy-path | Safe |
| `grep -q "Feature Implementation Loop"` | happy-path | Safe — Step 7 heading unchanged |
| `grep -q "E2E Tests"` | happy-path | Safe — Step 8 heading unchanged |
| `grep -q "Final Report"` | happy-path | Safe — text "Final Report" still present (step is only renumbered) |
| `grep -q "Interactive"` | happy-path | Safe |
| `grep -q "YOLO with checkpoint"` | happy-path | Safe |
| `grep -q "Full YOLO"` | happy-path | Safe |
| `grep -q "Only one input source allowed"` | input-conflicts | Safe — error text unchanged |
| `grep -q "\-\-no-implement skips specification phase"` | input-conflicts | Safe — error text unchanged |
| `grep -q "Legacy Flow"` | no-implement | Safe — legacy section heading unchanged |
| `grep -q "EXIT pipeline"` | no-implement | Safe — early-exit wording unchanged |
| `grep -q "Create issues in your issue tracker"` | no-implement | Safe — L6 report text preserved |
| `grep -q "Spec iterations"` | spec-loop | Safe |
| `grep -q "spec-writer.*spec-reviewer loop"` | spec-loop | **AT RISK** — this regex requires exact phrase "spec-writer" and "spec-reviewer loop" to appear on the same line in scaffold.md. Do NOT change the loop description wording |
| `grep -q "max_iterations exhausted"` | spec-loop | Safe — wording preserved |

**New assertions to ADD in `tests/scenarios/scaffold-v2-happy-path.sh`:**

```bash
# Step 0-INFRA: Infrastructure Declaration present
grep -q "Infrastructure Declaration" "$SCAFFOLD_CMD"

# Step 0-MCP present
grep -q "0-MCP" "$SCAFFOLD_CMD"

# Step 4d: Push to Remote present
grep -q "Push to Remote" "$SCAFFOLD_CMD"

# Step 4e: Create Tracker Issues present
grep -q "Create Tracker Issues" "$SCAFFOLD_CMD"
```

**New assertions to ADD in `tests/scenarios/scaffold-v2-no-implement.sh`:**

```bash
# Step 0-INFRA present even in --no-implement flow
grep -q "Infrastructure Declaration" "$SCAFFOLD_CMD"
```

**Regression guard assertions to ADD in `tests/scenarios/scaffold-v2-happy-path.sh`:**

```bash
# Step 4b REMOVED
! grep -q "Step 4b" "$SCAFFOLD_CMD"

# Step 4c REMOVED
! grep -q "Step 4c" "$SCAFFOLD_CMD"

# Step 9 REMOVED (old Issue Tracker Optional)
! grep -q "Step 9: Issue Tracker" "$SCAFFOLD_CMD"
```

**Important:** The exact string `"Infrastructure Declaration"` must be present in `commands/scaffold.md` Step 0-INFRA heading. If a different label is chosen during implementation (e.g., "0-INFRA: Infrastructure Preflight"), the test assertions must be updated to match. Use the label from the design document consistently: `### Step 0-INFRA: Infrastructure Declaration`.

---

### Note 4: Mermaid diagram update patterns for each file

**Pattern 1 — `README.md` (lines 112–124, `flowchart TD`)**

Current:
```
Desc["Project Description..."] --> Mode["Mode Selection..."]
```
Required change:
```
Desc["Project Description..."] --> Infra["Infrastructure Declaration<br/><i>tracker · source control</i>"]
Infra --> Mode["Mode Selection..."]
```

**Pattern 2 — `docs/architecture.md` (lines 118–127, `graph LR`)**

Current:
```
A[User description] --> B[Mode selection]
```
Required change:
```
A[User description] --> A2[Infrastructure Declaration]
A2 --> B[Mode selection]
```

**Pattern 3 — `docs/reference/pipelines.md` (lines 208–265, full `flowchart TD`)**

Three changes required:

*Change 3a — Remove TRACKER node (Step 9):*
Current:
```
E2E --> TRACKER{Issue Tracker<br/>Cards?}
TRACKER --> REPORT([Final Report])
```
Replace with:
```
E2E --> REPORT([Final Report])
```
Delete the `TRACKER` node definition entirely. Remove any `style TRACKER` line if present.

*Change 3b — Add INFRA_DECL node before MODE:*
Current:
```
DETECT -->|Empty| MODE{Mode<br/>Selection}
```
Replace with:
```
DETECT -->|Empty| INFRA_DECL[Infrastructure Declaration<br/><i>tracker · source control</i>]
INFRA_DECL --> MODE{Mode<br/>Selection}
```

*Change 3c — Add PUSH and CREATE_ISSUES nodes after GIT_INIT:*
Current:
```
GIT_INIT --> ARCHITECT[Architecture<br/>architect]
```
Replace with:
```
GIT_INIT --> PUSH[Push to Remote<br/><i>if SC ready</i>]
GIT_INIT --> CREATE_ISSUES[Create Tracker Issues<br/><i>if tracker ready, not Full YOLO</i>]
PUSH --> ARCHITECT[Architecture<br/>architect]
CREATE_ISSUES --> ARCHITECT
```
Note: GIT_INIT fans out to PUSH and CREATE_ISSUES in parallel, then both merge to ARCHITECT.

**Pattern 4 — `CLAUDE.md` (lines 66–73, ASCII text diagram)**

Current first line:
```
User description → [Mode selection] → SPEC-WRITER ↔ SPEC-REVIEWER (opus)
```
Required change:
```
[0-INFRA: infra declaration] → [0-MCP: MCP check] → User description → [Mode selection] → SPEC-WRITER ↔ SPEC-REVIEWER (opus)
```

Also update the `→ Validate → Git init` segment to mention new sub-steps:
```
→ Validate → Git init → [4d: push] → [4e: tracker issues]
```

And remove `→ [Spec compliance check (spec-reviewer --verify)]` from the CLAUDE.md diagram. This is the Step 9 equivalent in the CLAUDE.md diagram (note: Agent 5 identified this line as the Step 9 candidate for removal from CLAUDE.md). The step-by-step compliance check (`7b: Spec Compliance Check`) still exists — only the `[Spec compliance check (spec-reviewer --verify)]` shorthand in the CLAUDE.md abstract diagram is removed if it represents the old Step 9.

**Clarification on CLAUDE.md Step 9 removal:** The current CLAUDE.md diagram shows `[Spec compliance check (spec-reviewer --verify)]` which maps to `Step 7b: Spec Compliance Check` in `commands/scaffold.md` — NOT to old Step 9 (Issue Tracker). Step 7b is unchanged. Therefore the CLAUDE.md diagram should NOT remove that line. Only prepend the infrastructure steps.

---

## 4. Risk Register

### Risk 1 — In-memory state not carried through pipeline (IMPACT: HIGH)

**Description:** Steps 4d and 4e rely on `tracker_effective_status`, `sc_effective_status`, `tracker_type`, and `sc_remote` values established at Step 0-INFRA. If the implementer re-reads CLAUDE.md at Step 4d/4e instead of using in-memory values, the values will be wrong (CLAUDE.md still has TODO markers at that point in some flows).

**Mitigation:** The MCP Pre-flight Check section explicitly states "Do NOT re-read Automation Config." This must also be stated in the Step 0-INFRA description: "Store these values in memory for use in Steps 4, 4d, 4e, and 10."

**Detection:** If Step 4d attempts a push and CLAUDE.md says `<!-- TODO: -->` for Remote, the push will fail with a nonsensical error instead of being skipped.

---

### Risk 2 — MCP Pre-flight Check section missed during implementation (IMPACT: HIGH)

**Description:** The MCP Pre-flight Check is a trailing policy section (L540–L551), visually detached from the step definitions. It is easy to edit Steps 4b, 4c, and 9 and forget to update this section. The current text lists Step 9 as an MCP trigger — leaving it unchanged creates a contradiction.

**Mitigation:** This document lists the MCP Pre-flight Check as a CRITICAL change explicitly. The new text is fully specified in Decision 6 above. During implementation verification, do a search for "Step 9" in `commands/scaffold.md` — any match after implementation is an error (only one occurrence should remain: inside the renamed `### Step 9: Final Report` heading).

---

### Risk 3 — Test spec-writer regex breaks (IMPACT: MEDIUM)

**Description:** `tests/scenarios/scaffold-v2-spec-loop.sh` has `grep -q "spec-writer.*spec-reviewer loop"` — this regex requires exact same-line match. If the spec loop description in scaffold.md changes wording (e.g., line wrap or restructuring during Step 1 prose edits), the test will fail.

**Mitigation:** Do NOT edit the Step 1 (Specification Phase) prose content. Limit changes to removing Steps 4b/4c/9 and adding the new steps; Step 1 content is unchanged.

---

### Risk 4 — Full YOLO behavior change not communicated (IMPACT: MEDIUM)

**Description:** In v5.3.0, Full YOLO silently skipped Step 4b (tracker configuration). In v5.5.0, Full YOLO users will be asked about infrastructure at Step 0-INFRA — this is an interactive prompt that did not exist before. Users who relied on Full YOLO for completely unattended runs will be surprised.

**Mitigation:** The CHANGELOG entry for v5.5.0 must explicitly state this under `### Changed`: "Full YOLO mode now includes Step 0-INFRA infrastructure question (previously, tracker config was silently skipped in Full YOLO via Step 4b)."

---

### Risk 5 — Step renumbering cascade misses internal jump references (IMPACT: MEDIUM)

**Description:** After removing Step 9 and renumbering Step 10 → Step 9, internal scaffold.md references at L443 and L449 (`"jump to Step 10"`) become stale. If missed, the command will instruct jumps to a step number that no longer exists.

**Mitigation:** After all edits, search `commands/scaffold.md` for `"Step 10"`. Every match must be either the renamed heading `### Step 9: Final Report` (which will not match "Step 10") or a stale reference to fix. There should be zero remaining "Step 10" strings after implementation.

---

### Risk 6 — `.mcp.json.example` vs. `.mcp.json` confusion (IMPACT: LOW-MEDIUM)

**Description:** The extended Step 4 generates `.mcp.json.example` (with `<YOUR_*>` placeholders) but NOT `.mcp.json` (with real tokens). init.md generates both. Users may not realize they still need to run `/ceos-agents:init` to get a functional `.mcp.json`. The scaffold pipeline will "succeed" but the project cannot actually run `/fix-ticket` or `/implement-feature` until tokens are configured.

**Mitigation:** Step 9 (Final Report, renumbered from Step 10) must include a "Remaining setup required" section that explicitly lists `.mcp.json` token configuration as a required next step when `.mcp.json.example` was generated. The existing "Remaining TODOs in CLAUDE.md" section should be extended with a check for this.

---

### Risk 7 — docs/reference/pipelines.md Mermaid diagram TRACKER node removal leaves dangling edges (IMPACT: LOW)

**Description:** The current diagram has edges: `E2E --> TRACKER{Issue Tracker Cards?}` and `TRACKER --> REPORT([Final Report])`. Removing the TRACKER node without reconnecting the edges will break Mermaid rendering.

**Mitigation:** Explicitly replace both edges with the single `E2E --> REPORT` edge as specified in Pattern 3a above. Verify Mermaid renders correctly by checking the full flowchart after edit.

---

### Risk 8 — CLAUDE.md "Spec compliance check" line misidentified as Step 9 (IMPACT: LOW)

**Description:** Agent 5 initially identified `[Spec compliance check (spec-reviewer --verify)]` in CLAUDE.md as a "Step 9 candidate for removal." This is incorrect — that line maps to Step 7b (Spec Compliance Check), which is unchanged. Removing it from CLAUDE.md would incorrectly erase documentation of Step 7b.

**Mitigation:** Do NOT remove the `[Spec compliance check (spec-reviewer --verify)]` line from CLAUDE.md. Only prepend the infrastructure steps. The CLAUDE.md diagram does not mention old Step 9 (Issue Tracker Optional) explicitly — no removal is needed.
