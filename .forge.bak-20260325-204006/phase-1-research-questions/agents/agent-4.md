# Research Question 4: State Management Gap Analysis

## Refined Question

How does ceos-agents currently manage pipeline state across steps (implicit via issue tracker comments and git branch heuristics, structured Block Comment Template, and the resume-ticket checkpoint table) versus forge's fully explicit `.forge/` state directory (forge.json schema, per-phase `final.md` checkpoints, structured forge.log, and metrics tracking)? What state does each ceos-agents pipeline step produce and consume, what is lost between LLM sessions, and what migration strategy is needed to bring forge-grade durability to ceos-agents pipelines?

---

## ceos-agents State Model

### Persistence Mechanism

ceos-agents has **no dedicated state store**. State is reconstructed at resume time from three external sources:

1. **Issue tracker comments** — The `[ceos-agents]` prefix makes comments machine-parseable. Two structured comment types exist:
   - Triage checkpoint: `[ceos-agents] Triage completed. Severity: {s}. Area: {a}. Complexity: {c}. AC: {n}.`
   - Block comment: `[ceos-agents] 🔴 Pipeline Block` with Agent/Step/Reason/Detail/Recommendation fields
   - Feature checkpoint: `[ceos-agents] Spec analysis completed.`

2. **Git state** — Branch existence, commit count above base branch, open PR existence, and `.claude/decomposition/{ISSUE-ID}.yaml` (task tree file, the only local file used as a checkpoint signal).

3. **Agent outputs in memory** — `acceptance_criteria`, `complexity`, `reproduction_result`, and other agent outputs are passed forward as in-context variables, not persisted to disk between steps.

### What Is Explicitly Stored

| Artifact | Location | Written By | Consumed By |
|---|---|---|---|
| Triage checkpoint comment | Issue tracker | fix-ticket orchestrator | resume-ticket detection |
| Block comment | Issue tracker | Block handler (step X) | resume-ticket (blocked state warning) |
| Decomposition task tree | `.claude/decomposition/{ISSUE-ID}.yaml` | fix-ticket step 4b | resume-ticket (DECOMPOSE_PARTIAL), subtask loop |
| Reproduction result | `.claude/reproduction-result.json` | reproducer agent | browser-verifier, fixer context |
| Screenshots | `.claude/screenshots/` | browser-verifier agent | PR comment context |
| Setup validated marker | `.claude/setup-validated` | check-setup command | status command recommendation |

### What Is NOT Stored

- The full triage output (acceptance criteria list, complexity value) — passed only as in-memory context
- Code-analyst impact report — passed only as in-memory context
- Fixer iteration count — tracked only within the current LLM session
- Build retry count — tracked only within the current LLM session
- Per-step timing / duration
- Token usage
- Which pipeline profile was active
- Reviewer verdict history
- Test attempt results history

### Resume Heuristic

`resume-ticket` reconstructs pipeline position using a priority-ordered detection table:

```
DECOMPOSE_PARTIAL > PUBLISHED > POST_REVIEW > POST_FIX > POST_ANALYSIS > POST_TRIAGE > FRESH
```

Detection signals are indirect (branch existence, commit count, comment prefixes). The comment says: "Detection is best-effort — heuristics may not be 100% accurate. Worst case: re-run one extra step."

### Status Command

`/ceos-agents:status` queries the issue tracker live for active issues, maps them to branches and PRs, and displays a summary table. It never reads local disk state (no local state to read). Recommendations are heuristic (e.g., "stale branch > 24h"). No phase-level granularity — only issue-level states (in progress, blocked, for review).

---

## forge State Model

### Persistence Mechanism

forge uses a **dedicated `.forge/` directory** as the single source of truth. State is explicit and file-system-based:

1. **`forge.json`** — Central pipeline state document with a formal schema (`schema_version: 1.0.0`). Contains:
   - Run ID, plugin version, input text
   - Pipeline-level status: `running | waiting_for_approval | completed | aborted_by_user`
   - `current_phase` (integer)
   - Per-phase status map: `phases: {}` — each entry can be `pending | in_progress | completed | skipped_by_user | invalidated`
   - Cumulative metrics: `total_tokens_estimated`, `total_duration_ms`, `review_rounds_used`, `escalations_to_human`
   - `phase_8_revision` object for cross-phase revision tracking
   - Full merged config with provenance tags (which level each value came from)

2. **`forge.log`** — Append-only structured event log with 16 defined event types (FORGE_START, PHASE_START, PHASE_END, AGENT_START, AGENT_END, REVIEW_START, REVIEW_END, APPROVAL_GATE, ESCALATE, CRASH_RECOVERY, REVISION_CYCLE, TIMEOUT_ADJUSTED, etc.).

3. **Per-phase directories** — `phase-N-{name}/` with standardized output files:
   - `agents/agent-{i}.md` — raw agent output (parallel phases)
   - `synthesis.md` — mid-phase synthesis (used as crash-recovery signal)
   - `final.md` (or `final/` directory for Phase 4) — canonical phase output; its existence = phase is complete
   - `review-*.md` — reviewer outputs (kept for audit trail)

4. **Config provenance** — `.forge/config.json` with 4-level merge provenance (defaults → project → CLI → meta-agent), each key tagged with its source.

### Checkpoint Detection

Checkpoint detection is deterministic and file-based:

```
final.md exists → mark complete, advance
synthesis.md exists → re-enter review loop from round 1
agents/ has partial files → re-dispatch only missing agents
Nothing → re-run entire phase from scratch
```

No heuristics. No external system queries at resume time.

### Context Handoff

Each phase reads ONLY the specific files listed in the Context Handoff Protocol matrix (9 rows, each row specifying exact files). Agents are forbidden from reading files outside their listed inputs. Prior-phase outputs are consumed via filesystem reads at dispatch time, not carried in LLM context.

---

## Gap Analysis

### What forge Has That ceos-agents Lacks

| Capability | forge | ceos-agents | Gap Severity |
|---|---|---|---|
| Explicit state store | `.forge/forge.json` with schema | None — state reconstructed from heuristics | Critical |
| Deterministic checkpoint detection | File existence check | Multi-signal heuristic (comments + git + files) | High |
| Pipeline status values (formal enum) | 4 pipeline + 5 phase statuses | Derived from issue tracker states | High |
| Structured event log | 16-type append-only forge.log | None | Medium |
| Per-phase timing metrics | `total_duration_ms` per phase | None | Medium |
| Token usage tracking | `total_tokens_estimated` | None (one-line estimate at end of fix-ticket) | Medium |
| Config with provenance | 4-level merge, each key tagged | Config read fresh from CLAUDE.md each run | Low |
| Revision cycle tracking | `phase_8_revision` object | No structured tracking of fixer↔reviewer iterations | Medium |
| Partial phase recovery | Re-dispatch only missing agents | Re-run entire skipped step | Medium |
| Offline resume (no external system) | Reads .forge/ only | Requires issue tracker + git access | High |
| Cascade invalidation | Explicit `final.md.invalidated` renaming | Not supported | Low |

### What ceos-agents Has That forge Lacks

| Capability | ceos-agents | forge |
|---|---|---|
| Issue tracker integration | Native — reads/writes issue state, comments | Not applicable (forge is project-local) |
| Multi-ticket orchestration | fix-bugs processes N tickets in sequence | Single-task scope |
| Rollback agent | Dedicated rollback-agent for git revert | PASS_TO_PASS gate per task, no dedicated rollback |
| Cross-session comment trail | Issue comments are durable and human-readable | forge.log is local, not shared |
| Block escalation to humans | Structured block comment with Recommendation | Escalation via AskUserQuestion (interactive only) |
| Legacy prefix detection | `[CLAUDE-agents]` backward compat | No legacy handling needed |

---

## State Produced Per Pipeline Step (ceos-agents)

| Step | State Produced | Persistence | State Consumed | What Is Lost Between Sessions |
|---|---|---|---|---|
| 0. MCP pre-flight | Nothing | None | Config (CLAUDE.md) | — |
| 1. Set issue state | Issue tracker state update | Issue tracker | Config | — |
| 2. Create branch | Git branch | Git remote | Config | — |
| 3. Triage | `acceptance_criteria` list, `complexity`, `severity`, `area`, `reproduction_steps`; triage checkpoint comment | Issue tracker comment only | Issue description | acceptance_criteria and complexity are NOT persisted — only the comment with counts |
| 4. Code-analyst | Impact report: `affected_files`, `risk`, `estimated_diff_lines`, `independent_changes` | Not persisted | Branch, issue | Entire impact report lost — must be re-read from code |
| 4b. Decomposition | Task tree YAML | `.claude/decomposition/{ISSUE-ID}.yaml` | Triage output, code-analyst report | Only task tree structure survives; per-subtask context lost |
| 4e. Browser reproduction | `reproduction_result` JSON | `.claude/reproduction-result.json` | Triage, code-analyst, Browser Verification config | File persists; metadata (when run, which browser, version) not tracked |
| 5. Fixer | Code changes (git diff) | Git commits | All prior outputs | Fixer iteration count lost; reason for each revision lost |
| 6. Build | Pass/fail result | Not persisted | Fixer output | Build output, retry count lost |
| 7. Reviewer | APPROVED / REQUEST_CHANGES verdict, AC fulfillment section | Not persisted (no comment written on approve) | AC from triage, diff | Reviewer verdict history lost; iteration count lost |
| 8. Test-engineer | Test pass/fail | Not persisted | Fixer diff | Test attempt count, test output lost |
| 8a. E2E test-engineer | E2E test pass/fail | Not persisted | Fixer diff | E2E output lost |
| 8a-browser. Browser Verifier | `VERIFIED / PARTIAL / SKIPPED / FAILED` verdict | Not persisted | reproduction-result.json, diff, AC | Verification evidence lost |
| 8b. Acceptance gate | APPROVE / REQUEST_CHANGES | Not persisted | AC, changed files | Gate result lost |
| 9. Publisher | PR URL | Git remote + issue tracker | Fixer output, config | — |
| 9d. Fix Verification | Pass/fail comment | Issue tracker comment | PR merge event | — |
| X. Block handler | Block comment | Issue tracker comment | Agent name, step, reason | Rollback details, exact git state pre-rollback |

**Key observation:** Only 4 artifacts survive session boundaries: issue tracker comments (triage checkpoint, block comment), git branch/commits, the decomposition YAML, and the reproduction result JSON. Everything else — acceptance criteria values, impact report contents, iteration counts, build/test/review results — exists only within the executing LLM session.

---

## Integration Strategy Implications

### 1. Introduce a `.ceos-agents/` State Directory Per Issue

Mirror forge's `.forge/` with a per-issue state directory:

```
.ceos-agents/{ISSUE-ID}/
  state.json          — pipeline status, current step, phase statuses
  triage.json         — acceptance_criteria, complexity, severity, area, reproduction_steps
  code-analyst.json   — impact report: affected_files, risk, estimated_diff_lines
  iteration-log.md    — fixer↔reviewer loop entries with verdicts
  metrics.json        — per-step durations, retry counts, token estimates
  ceos-agents.log     — append-only structured event log
```

### 2. Preserve Triage Output as Structured JSON

Currently only the triage *count* is persisted (in the comment). The full acceptance criteria list should be written to `triage.json` so resume-ticket can reload it without re-running triage. This avoids the "worst case: re-run one extra step" situation.

### 3. Replace Heuristic Checkpoint Detection

The current multi-signal detection (branch + commit count + comment text) is fragile. With a `state.json` file:
- `current_step` field replaces all heuristics
- `step_status` map (per step: pending / in_progress / completed / blocked / skipped) replaces comment scanning
- Resume becomes deterministic

### 4. Add Structured Event Logging

Adopt forge's event log pattern for ceos-agents. Define events:
- `PIPELINE_START`, `PIPELINE_END`, `STEP_START`, `STEP_END`
- `AGENT_START`, `AGENT_END`
- `BLOCK`, `RETRY`, `RESUME`

This enables the `/ceos-agents:metrics` command to compute real data instead of advisory estimates.

### 5. Local State Reduces External System Dependency at Resume Time

Currently `resume-ticket` requires both issue tracker access and git access. With local state, the pipeline can resume even if the issue tracker is temporarily unavailable (e.g., offline, rate-limited), and can detect the exact step rather than approximating from git history.

### 6. Backward Compatibility

The `[ceos-agents]` comment prefix must be preserved for legacy detection in already-running pipelines. New state directory is additive — existing pipelines without a `state.json` fall back to current heuristics.

### 7. Metrics Command

The existing `/ceos-agents:metrics` command currently has no local data to work with (it relies on issue tracker queries). A forge-style `metrics.json` per run would enable real duration, retry, and cost tracking.

---

## Files Examined

- `C:/gitea_ceos-agents/commands/fix-ticket.md` — full pipeline definition with step numbers and state produced/consumed
- `C:/gitea_ceos-agents/commands/resume-ticket.md` — checkpoint detection heuristics and detection logic table
- `C:/gitea_ceos-agents/commands/status.md` — status reporting, no local state reads
- `C:/gitea_ceos-agents/CLAUDE.md` — Block Comment Template format, triage checkpoint comment format, agent conventions
- `C:/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.1.0/skills/forge/SKILL.md` — forge.json schema, Phase Execution Loop, Context Handoff Protocol, Error Recovery
- `C:/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.1.0/skills/forge-resume/SKILL.md` — forge-resume logic, status transitions, crash recovery decision tree
- `C:/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.1.0/skills/forge-status/SKILL.md` — forge-status display logic, read-only behavior

---

## Migration Risks

### Risk 1: External State Is Authoritative (Critical)

ceos-agents' current state model makes the issue tracker authoritative. If a `.ceos-agents/state.json` diverges from the issue tracker (e.g., the issue was manually moved to "Done" while the pipeline was blocked), the local state file becomes stale. A conflict resolution protocol is required: local state wins for pipeline position, issue tracker wins for issue lifecycle state.

### Risk 2: Multi-Instance Conflicts (High)

`fix-bugs` processes multiple tickets, potentially spawning concurrent pipelines. If two sessions process the same ticket simultaneously, both writing to `.ceos-agents/{ISSUE-ID}/state.json`, race conditions will corrupt state. A file-locking or PID-based guard is needed.

### Risk 3: State File Accumulation (Medium)

forge creates a single `.forge/` per project run. ceos-agents would create `.ceos-agents/{ISSUE-ID}/` per ticket — potentially hundreds over time. A cleanup policy (analogous to forge's `.forge.bak-{timestamp}/` archiving) must be defined.

### Risk 4: Acceptance Criteria Format Change (Medium)

Currently acceptance criteria are passed as free-text context to agents. Persisting them as structured JSON (e.g., `[{"id": "AC-1", "text": "..."}]`) changes the format agents receive. All agents that consume AC (fixer, reviewer, acceptance-gate) would need to accept the new structured format. This is a minor breaking change in agent context contract.

### Risk 5: Resume Backward Compatibility (Medium)

`resume-ticket` currently has `[CLAUDE-agents]` legacy detection for pre-rename comments. After introducing local state, a ticket that was triaged before the migration (no state.json, only old-style comments) must still resume via heuristics. The hybrid fallback (no state.json → use current heuristics) must be maintained indefinitely or until a migration script is provided.

### Risk 6: `.ceos-agents/` in .gitignore (Low)

Like forge, the state directory should probably not be committed. But unlike forge (which prompts on first run), ceos-agents has no initialization step to insert the `.gitignore` entry. The `/ceos-agents:init` or `/ceos-agents:check-setup` commands are the appropriate place to add this prompt.

### Risk 7: Decomposition YAML Is Already Local State (Low)

`.claude/decomposition/{ISSUE-ID}.yaml` is an existing local state artifact. Migration should absorb this into the new `.ceos-agents/{ISSUE-ID}/` directory structure to avoid having state split across two locations. This changes the path that `resume-ticket` checks for `DECOMPOSE_PARTIAL` detection.
