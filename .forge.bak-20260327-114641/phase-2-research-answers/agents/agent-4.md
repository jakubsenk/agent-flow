# Agent 4 — Research Answers: Scaffold Infrastructure Design

**Date:** 2026-03-27
**Source files analyzed:**
- `commands/init.md`
- `commands/scaffold.md`
- `docs/plans/2026-03-27-scaffold-infrastructure-design.md`

---

## Part 1: init.md Deep Analysis

### Can init be invoked inline from scaffold?

**Short answer: Not directly — it has a hard CLAUDE.md dependency that fails on a fresh scaffold.**

#### Step 1's CLAUDE.md Dependency (exact quote)

From `commands/init.md`, Step 1:

> Read Automation Config from CLAUDE.md. Extract:
> - **Type** from Issue Tracker (determines tracker MCP server)
> - **Instance** from Issue Tracker (determines server URL/env vars)
> - **Remote** from Source Control (determines SC MCP server and hostname)
>
> If no Automation Config found → error: "No Automation Config found. Run `/ceos-agents:onboard` first."

This is a hard gate. During scaffold, CLAUDE.md either does not exist yet (before Step 3) or has been generated with TODO markers (after Step 3 but before Step 4b fills values). If `/init` is invoked inline at Step 0-MCP — which fires before the scaffold skeleton is generated — there is no CLAUDE.md at all. The call would immediately error out.

**Conclusion:** Init cannot be invoked inline without receiving explicit tracker type/instance/remote data as arguments or via a bypass path that skips Step 1's file read.

---

#### Exact MCP Detection Logic — Step 3 Table (exact quote)

From `commands/init.md`, Step 3:

> Read `docs/reference/trackers.md` MCP Server Detection table.
>
> | Tracker Type | MCP Package | Token env var | Extra env vars |
> |-------------|-------------|---------------|----------------|
> | youtrack | `@vitalyostanin/youtrack-mcp` | `YOUTRACK_TOKEN` | `YOUTRACK_URL` |
> | github | `@modelcontextprotocol/server-github` | `GITHUB_PERSONAL_ACCESS_TOKEN` | — |
> | jira | `@modelcontextprotocol/server-atlassian` | `ATLASSIAN_API_TOKEN` | `ATLASSIAN_URL`, `ATLASSIAN_EMAIL` |
> | linear | `@modelcontextprotocol/server-linear` | `LINEAR_API_KEY` | — |
> | gitea | `forgejo-mcp` (binary) | `FORGEJO_TOKEN` | `FORGEJO_URL` |
> | redmine | `mcp-server-redmine` | `REDMINE_API_KEY` | `REDMINE_HOST` |
>
> **Shared server detection:** Compare tracker Type hostname with Source Control Remote hostname.
> - Gitea tracker + Gitea SC → single `forgejo-mcp` instance (shared)
> - GitHub tracker + GitHub SC → single `server-github` instance (shared)
> - Mixed (e.g. Jira + GitHub SC) → two separate servers
>
> Determine which servers to configure:
> 1. Tracker MCP server (always)
> 2. Source control MCP server (if different from tracker)

This is the full detection logic. Init resolves the MCP package by reading the tracker Type from Automation Config, then cross-checks the tracker hostname against the SC hostname for the shared-server optimization. The logic is purely lookup-based — no dynamic probing of available `mcp__*` tools.

---

#### Exact Connectivity Validation Logic — Step 7 (exact quote)

From `commands/init.md`, Step 7:

> For each configured MCP server with non-placeholder tokens:
>
> - Attempt a minimal MCP call:
>   - Tracker: query 1 issue (same as check-setup Block 3)
>   - Source control: list repos (same as check-setup Block 3)
> - Success → "[OK] {server_name} connected successfully"
> - Failure → "[FAIL] {server_name}: {error}. Check your token and URL."
>
> If any placeholder tokens remain:
> - "[SKIP] {server_name}: token not configured. Add it to .mcp.json later."

Step 7 validates by attempting actual MCP calls. The two checks are:
1. Tracker: query 1 issue (equivalent to check-setup Block 3 tracker check)
2. SC: list repos (equivalent to check-setup Block 3 SC check)

The logic gracefully handles skipped tokens — placeholder values cause a `[SKIP]` output instead of a failure, so partial setups are acceptable.

---

#### What Would Need to Change for Inline Invocation

To support calling `/init` inline from Step 0-MCP, the following changes are required:

1. **Step 1 bypass / parameterization:** Init needs an `--inline` mode (or equivalent parameter) that accepts tracker type, instance URL, and SC remote as direct arguments instead of reading from CLAUDE.md. When called inline during scaffold, the scaffold command would pass these values from Step 0-INFRA answers.

2. **Scope narrowing flag:** The current init runs the full 9-step wizard (detect → tokens → platform → generate .mcp.json → validate → permissions → closing message). Inline invocation from scaffold only needs the MCP detection and connectivity verification (Steps 3, 4, 5, 6, 7 — not Step 8 permissions). A `--partial` or `--mcp-only` flag would avoid the full wizard.

3. **Target directory handling:** Init's Step 6 writes `.mcp.json` to CWD. During scaffold's Step 0-MCP, the target project directory may not exist yet. Init would need to either accept a `--target-dir` argument or scaffold must ensure the target directory exists before calling init inline.

4. **Token handling during inline call:** When called inline, the project does not yet have a `.mcp.json`. Init could write `.mcp.json.example` (with `<YOUR_*>` placeholders) to the target directory — which aligns with the design's requirement to generate `.mcp.json.example` at Step 4 without copying real tokens.

5. **Output contract:** Inline callers need a machine-readable result (tracker-ready: yes/no, sc-ready: yes/no, errors: [...]) rather than the human-readable closing message of Step 9.

---

## Part 2: Edge Case Resolution

### Where exactly does Step 0-INFRA insert relative to State Detection?

**Step 0-INFRA inserts BEFORE State Detection.**

From the design document:

> **New Step 0-INFRA: Infrastructure Declaration**
> Replaces the current Step 4b and Step 4c. Moves to the **very beginning** of scaffold, before Mode Selection.

The current scaffold execution order is:
1. Flag Parsing
2. Flag Validation
3. State Detection
4. Step 0: Mode Selection
5. (rest of pipeline)

The design inserts Step 0-INFRA before Mode Selection, and the impact table explicitly shows:

> | Step 0 (Mode Selection) | Moves after Step 0-INFRA and Step 0-MCP |

However, the design is silent on whether 0-INFRA runs before or after State Detection. The logical placement is:

- **Flag Parsing and Flag Validation:** Must run first (they determine if `--no-implement` was passed, which affects 0-INFRA behavior — see the `--no-implement` section of the design).
- **State Detection:** Should run before 0-INFRA. Reason: if State Detection determines "Existing project with CLAUDE.md" (state 3) and redirects to `/implement-feature`, asking the infrastructure question first would be wasted effort. The existing State Detection logic gates whether the full scaffold pipeline runs at all.
- **Step 0-INFRA:** Runs after State Detection confirms state 1 (empty directory / fresh scaffold). This is consistent with all other Step 0 content running after State Detection.
- **Step 0-MCP:** Runs immediately after Step 0-INFRA.
- **Step 0 (Mode Selection):** Runs after Step 0-MCP (as stated explicitly in the design).

**Definitive order:**
```
Flag Parsing → Flag Validation → State Detection → Step 0-INFRA → Step 0-MCP → Step 0 (Mode Selection) → Step 0b (Brainstorm) → Step 1...
```

---

### How should --issue flag interact with Step 0-INFRA?

The `--issue` flag means the user is starting from an existing tracker issue. This implies: tracker is already configured, the project exists in the tracker, and MCP connectivity for the tracker is presumably available (otherwise the user could not even look up the issue ID).

**Recommended behavior:**

When `--issue` is present, Step 0-INFRA should **auto-detect tracker=ready** for the tracker portion. Specifically:

1. Skip the manual tracker question — the user has demonstrated tracker intent by providing an issue ID.
2. Set tracker state to "ready" with the project inferred from the issue ID's prefix (e.g., `PROJ-1` → project key `PROJ`).
3. Still ask the SC question (the user may or may not have a repo ready). Alternatively: if `--issue` is combined with a description that implies an existing remote, auto-set SC too.
4. Proceed to Step 0-MCP with tracker=ready, verify MCP connectivity (query the specific `--issue` ID as the connectivity check — this doubles as input fetching), and fail gracefully if MCP is not available.

**Edge case:** If MCP is not available and tracker was auto-set to "ready" via `--issue`, the scaffold command cannot fetch the issue description for spec-writer. In this case, Step 0-MCP must downgrade tracker to "later" AND discard the `--issue` flag's input source — falling back to asking the user for a project description directly. The user should be notified: "Could not reach tracker to fetch issue {ID}. Please describe your project instead."

The design document notes for `--issue` in the Spec Phase section:

> When using `--issue` flag (starting from a tracker epic), spec-reviewer questions are handled **in the chat** (Interactive mode), not posted to the tracker.

This confirms `--issue` implies Interactive mode for the spec phase but does not explicitly define the 0-INFRA interaction. The auto-detect interpretation is the consistent extension.

---

### What happens with --no-implement + Step 4d/4e?

From `commands/scaffold.md`, the `--no-implement` flag immediately exits to the legacy flow:

> If `--no-implement`:
> → Skip to legacy flow: stack-selector → scaffolder → validate → move → git init → report (v3.x behavior, steps L1–L6 below). EXIT pipeline.

The legacy flow (L1–L6) has its own Git init at Step L5 and its own report at Step L6. It does NOT go through the main pipeline's Step 4, Step 4d, or Step 4e.

From the design document:

> **--no-implement Legacy Flow**
> The `--no-implement` flow (L1-L6) remains unchanged. Step 0-INFRA is added before L1 but the legacy flow does not create tracker issues (no spec/epics to create from).

**Conclusion for Step 4d and Step 4e with --no-implement:**

- **Step 4d (Push to remote):** Does NOT run. The legacy flow has its own L5 git init that commits locally. Push behavior is not part of the legacy flow. If the design adds push capability, it must be added to L5 separately, or a new step L5b inserted.
- **Step 4e (Create tracker issues):** Does NOT run and CANNOT run — the legacy flow skips the Spec phase entirely (no spec/epics/*.md files are generated). There are no epic files from which to create tracker issues. The design explicitly acknowledges this: "the legacy flow does not create tracker issues (no spec/epics to create from)."

If SC was declared "ready" at Step 0-INFRA during a `--no-implement` run, the legacy flow's L6 report should inform the user that push was not performed (or the design should add a push step to L5/L5b for the legacy flow — this is a gap in the current design that needs a decision).

---

### How does Full YOLO interact with new steps?

From the design document:

> **Full YOLO Mode Behavior**
> In Full YOLO mode, Step 0-INFRA question is still asked (it cannot be skipped — infrastructure is a prerequisite decision, not a quality gate). However:
> - If user declared "ready" → proceed without confirmations in all subsequent steps
> - If user declared "later" → scaffold runs fully locally with no stops

Mapping this across all new and modified steps:

| Step | Full YOLO behavior |
|---|---|
| Step 0-INFRA | ASKED — not skippable. Infrastructure intent must be declared. |
| Step 0-MCP | Runs. If MCP missing and user said "ready": the inline `/init` offer (`[Y/n]`) must auto-accept Y, or Full YOLO must skip the offer and attempt MCP anyway, blocking if unavailable. The design is silent on this sub-case — recommend: attempt MCP detection, if fails → downgrade to "later" automatically (no prompt). |
| Step 0 (Mode Selection) | Skipped — Full YOLO is already selected. |
| Step 4 (Git Init + Auto-fill) | Runs. Auto-fill proceeds without confirmation (no prompts — consistent with Full YOLO). |
| Step 4d (Push) | Runs without confirmation if SC=ready. Failure is WARN only (no stop). |
| Step 4e (Create tracker issues) | Skipped in Full YOLO for the design's Step 9 equivalent. However, Step 4e is the replacement for Step 9 — check the existing scaffold.md for Step 9: |

From `commands/scaffold.md`, Step 9:

> If mode is Full YOLO and tracker configured:
>   Skip — do not create cards automatically in Full YOLO.

This behavior should carry forward to Step 4e: **Step 4e is skipped in Full YOLO.** Rationale: creating tracker issues is a collaborative action (linking spec to tracker requires human oversight of naming, status, and hierarchy). Full YOLO defers this to the human post-scaffold.

Summary of Full YOLO across new steps:
- 0-INFRA: asked (prerequisite decision)
- 0-MCP: attempted automatically, downgrade on failure (no prompt)
- 4 auto-fill: runs without prompts
- 4d push: runs without confirmation
- 4e issue creation: SKIPPED (consistent with existing Step 9 Full YOLO behavior)

---

## Part 3: MCP Pre-flight Rewrite

### Current MCP Pre-flight Check Section (exact quote)

From `commands/scaffold.md`, at the end of the Orchestration section:

> ## MCP Pre-flight Check
>
> MCP pre-flight check is only required when:
> - `--issue` flag is used (Step 1 — reading issue description from tracker)
> - Step 9 — creating cards in issue tracker (only when tracker is configured and user opts in)
>
> For `--no-implement`, keep the same behavior as v3.x (MCP check before stack-selector).
>
> Before any MCP operation, verify MCP tool availability:
> - Read Type from Automation Config (Issue Tracker section)
> - Check that at least one `mcp__*` tool matching the tracker type is accessible
> - If not accessible → STOP with: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure."

### Problem with the Current Text

The current pre-flight check references:
- **Step 9** — which is REMOVED in the redesign (replaced by Step 4e).
- The pre-flight describes a one-off check model ("only required when"). After the redesign, MCP is checked comprehensively and proactively at **Step 0-MCP**, not lazily before individual operations.
- The pre-flight reads Automation Config for the tracker Type — which does not exist yet during scaffold (before Step 3 generates CLAUDE.md). This is the same CLAUDE.md dependency problem as init.md Step 1.

### Proposed Rewrite

```markdown
## MCP Pre-flight Check

After the redesign (v5.5.0), MCP availability is verified proactively at Step 0-MCP — not lazily
before individual operations. The pre-flight logic below applies to cases that fall outside
Step 0-MCP coverage.

**Cases requiring an additional MCP check:**

- `--issue` flag: Step 1 fetches the issue description from the tracker. Before fetching,
  verify the tracker MCP tool is still accessible (Step 0-MCP may have run earlier in the
  session, but the tool could become unavailable). If inaccessible → STOP with the error
  below.

- `--no-implement` legacy flow: Step 0-INFRA fires before L1 (stack-selector). If the user
  declared tracker or SC as "ready", verify MCP accessibility before L1. For "later" services,
  no MCP check is needed.

**When Step 0-MCP covers the check (no additional pre-flight needed):**

- Step 4d (push to remote): SC MCP was verified at Step 0-MCP. No additional check.
- Step 4e (create tracker issues): Tracker MCP was verified at Step 0-MCP. No additional check.

**Standard error message (unchanged):**

If MCP inaccessible at any of the above check points:
→ STOP: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for
  diagnostics or `/ceos-agents:init` to configure."

**Note on Automation Config:** Steps 4d and 4e use the tracker Type and remote values
collected at Step 0-INFRA (in memory), not from CLAUDE.md — because CLAUDE.md may still have
TODO markers when these steps run. Do NOT re-read Automation Config for MCP type detection
in Steps 4d/4e.
```

### Key Differences from Current Text

| Aspect | Current | Proposed |
|---|---|---|
| Step 9 reference | Present | Removed (Step 9 is deleted) |
| Step 4d/4e references | Absent | Added |
| Lazy vs. proactive check | Lazy (only when needed) | Proactive at 0-MCP; pre-flight is a fallback |
| CLAUDE.md dependency | Reads from Automation Config | Uses in-memory values from 0-INFRA for steps 4d/4e |
| --no-implement handling | "keep v3.x behavior" | Explicitly tied to 0-INFRA "ready" declaration |

---

*End of agent-4.md*
