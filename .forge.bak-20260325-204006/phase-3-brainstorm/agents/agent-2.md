# Proposal 2: The Innovator's Approach (Yuki Tanaka)

## Philosophy

Three principles guide this proposal:

1. **Design for the target state, not the current state.** Every hour spent building compatibility shims is an hour not spent on the architecture users will actually live with. A migration guide is a one-time cost; permanent adapter layers are a recurring tax on every future contributor.

2. **Pit of success over pit of flexibility.** The unified plugin should make it trivially easy to do the right thing (invoke `/build`, get mode auto-detection, get persistent state) and awkward to do the wrong thing (bypass state management, skip review gates, hand-wire pipeline steps).

3. **Composable primitives over monolithic commands.** The current 400+ line pipeline commands are not maintainable. The fix is not to extract "shared patterns" into includes that those monoliths reference — it is to decompose the pipeline into a genuine engine with typed phases, where each phase is a small, testable unit that the engine orchestrates.

Where I expect to disagree with a Conservative approach: on deprecation timelines, on whether existing commands should get adapter wrappers, on whether the `ceos-agents:` namespace prefix should survive indefinitely, and on whether agent merges should be deferred. I will be explicit about each disagreement and why I believe the bolder path yields a better outcome.

---

## 1. Directory Structure

The current flat structure (`agents/`, `commands/`, `skills/`) conflates concern layers. The target structure separates the pipeline engine, mode adapters, agents, and entry points into distinct directories. Here is what I would ship:

```
/
├── .claude-plugin/
│   ├── plugin.json              # name: "ceos-agents" (unchanged)
│   └── marketplace.json
│
├── core/                        # Pipeline engine — the heart of the plugin
│   ├── engine.md                # Phase executor: reads state.json, dispatches phases in order
│   ├── state-schema.md          # State.json schema documentation + validation rules
│   ├── review-loop.md           # Generic writer↔reviewer iteration protocol
│   ├── block-handler.md         # Block detection, comment posting, rollback dispatch
│   ├── config-reader.md         # Automation Config parser (all sections, defaults, validation)
│   ├── context-handoff.md       # Phase-to-phase context assembly protocol
│   ├── approval-gate.md         # AC coverage check, acceptance gate logic
│   └── mcp-preflight.md         # MCP availability check
│
├── modes/                       # Mode adapters — map generic phases to domain-specific agents
│   ├── code-bug.md              # Bug-fix pipeline: triage→analyst→fixer→reviewer→test→publish
│   ├── code-feature.md          # Feature pipeline: spec→architect→fixer→reviewer→test→publish
│   ├── code-project.md          # Scaffold pipeline: spec-writer→scaffolder→architect→fixer→...
│   ├── analysis.md              # Analysis mode: intake→analyst→writer→reviewer→synthesizer
│   ├── strategy.md              # Strategy mode: intake→analyst→strategist→reviewer→synthesizer
│   └── content.md               # Content mode: intake→writer→reviewer→editor→publisher
│
├── agents/                      # All agent definitions (unchanged location, updated roster)
│   ├── triage-analyst.md
│   ├── code-analyst.md
│   ├── fixer.md
│   ├── reviewer.md
│   ├── test-engineer.md
│   ├── e2e-test-engineer.md
│   ├── publisher.md
│   ├── rollback-agent.md
│   ├── acceptance-gate.md
│   ├── reproducer.md
│   ├── browser-verifier.md
│   ├── priority-engine.md
│   ├── spec-analyst.md          # Unchanged — reads issue tracker, extracts WHAT
│   ├── spec-writer.md           # Scaffold spec-writer (software specs)
│   ├── spec-reviewer.md         # Unchanged
│   ├── stack-selector.md
│   ├── scaffolder.md
│   ├── planner.md               # NEW: merged architect + forge planner (mode dispatch)
│   ├── intake-agent.md          # NEW: flexible input ingestion for non-code modes
│   ├── domain-analyst.md        # NEW: analytical reasoning for analysis/strategy modes
│   └── synthesizer.md           # NEW: output assembly and formatting for non-code modes
│
├── skills/                      # Entry points — what users actually invoke
│   ├── build/                   # PRIMARY: /build entry point
│   │   ├── SKILL.md             # Mode detection, flag parsing, dispatch to engine
│   │   ├── mode-detection.md    # Auto-detection logic (git state, file types, user hints)
│   │   └── flag-reference.md    # All supported flags across all modes
│   ├── ops/                     # Operational skills (non-pipeline)
│   │   └── SKILL.md             # Routes: status, dashboard, metrics, check-setup, etc.
│   └── legacy/                  # Deprecated command router (removal in v7.0.0)
│       └── SKILL.md             # Maps old ceos-agents:X invocations to /build equivalents
│
├── commands/                    # DEPRECATED — thin wrappers during migration
│   ├── fix-ticket.md            # → Skill('build', args='--mode code-bug {issue-id}')
│   ├── fix-bugs.md              # → Skill('build', args='--mode code-bug --batch {query}')
│   ├── implement-feature.md     # → Skill('build', args='--mode code-feature {issue-id}')
│   ├── scaffold.md              # → Skill('build', args='--mode code-project {description}')
│   ├── ... (remaining 20)       # Each reduced to a 5-line redirect
│   └── _DEPRECATED.md           # Migration guide for command users
│
├── checklists/                  # Unchanged
├── docs/                        # Unchanged (updated references)
├── examples/                    # Unchanged (add mode examples)
└── tests/
    ├── harness/
    │   ├── run-tests.sh
    │   ├── mock-mcp-server.sh   # WIRED (finally)
    │   └── fixtures/
    ├── scenarios/
    │   ├── engine/              # Pipeline engine unit tests
    │   ├── modes/               # Mode adapter tests
    │   ├── agents/              # Agent structural tests
    │   ├── integration/         # Full pipeline tests using mock-mcp-server
    │   └── legacy/              # Backward compat tests for deprecated commands
    └── mock-project/
```

### Key Decisions

**Why `core/` as separate markdown files, not inline in the skill?** Because the `$CLAUDE_SKILL_DIR` pattern (confirmed in Phase 2 Finding 1.6) allows the build skill to `Read` sub-files. Each `core/*.md` file is a self-contained protocol that the engine references. This makes each pipeline primitive independently readable, testable, and replaceable.

**Why keep `agents/` flat?** Agent discovery is by directory convention (`agents/*.md`). Changing this breaks Claude Code's Task tool dispatch. The agents directory stays flat, but we add 3 new agents and merge 1 (architect → planner).

**Why `modes/` instead of embedding mode logic in the skill?** Mode adapters define the phase-to-agent mapping for each pipeline variant. They are the answer to "what does Phase 3 mean in analysis mode vs code-bug mode?" Separating them from the engine makes it possible to add a new mode by adding one file, not by modifying the engine.

**Why deprecate `commands/` rather than delete?** Because the `ceos-agents:` namespace has ~160 Class B documentation references. But the deprecation is aggressive — each command file shrinks to a 5-line redirect on day one, not "eventually."

---

## 2. Pipeline Engine Design

### The Problem with "Pattern Extraction"

The Phase 2 research identifies 10 shared patterns and proposes extracting them. This is the wrong frame. Extracting shared code from three 400-line commands produces three 250-line commands plus a shared-patterns library — you still have monoliths, just thinner ones. The correct move is to replace the monolithic command model with a proper pipeline engine.

### The Engine

The pipeline engine (`core/engine.md`) is the single orchestrator. It does one thing: execute a sequence of typed phases, managing state transitions between them. It does not know what "triage" means. It does not know about MCP servers. It reads a mode adapter that tells it which phases to run and which agents to dispatch.

**Phase Protocol:**

Each phase has a uniform interface:

```
Phase {
  name: string              # e.g., "triage", "analyze", "fix", "review", "test", "publish"
  agent: string             # Agent to dispatch via Task tool
  model: string             # Model override (from agent definition or mode adapter)
  skip_condition: string    # When to skip (e.g., "profile.skip includes 'triage'")
  context_from: string[]    # Which previous phases' outputs to include in context
  retry: {max: number, on: string}  # Retry config (e.g., max 3 on BUILD_FAIL)
  on_fail: string           # "block" | "rollback-and-block" | "skip" | "decompose"
  gate: string | null       # Post-phase gate condition (e.g., "ac_count >= 3 → run acceptance-gate")
}
```

**Mode Adapter Contract:**

Each mode file (`modes/*.md`) defines:

1. **Phase sequence** — ordered list of Phase definitions
2. **Context assembly rules** — how each phase's input is built from prior outputs
3. **Decomposition rules** — when and how to split work (code modes use architect/planner; non-code modes do not decompose)
4. **Completion criteria** — what "done" means for this mode

Example skeleton for `modes/code-bug.md`:

```markdown
# Code Bug Mode

## Phase Sequence

| # | Phase      | Agent              | Skip Condition           | Context From        | On Fail              |
|---|------------|--------------------|--------------------------|---------------------|----------------------|
| 1 | setup      | (engine built-in)  | never                    | config              | block                |
| 2 | triage     | triage-analyst     | profile.skip             | setup               | block                |
| 3 | analyze    | code-analyst       | profile.skip             | triage              | block                |
| 4 | reproduce  | reproducer         | !browser_reproduce       | triage, analyze     | skip                 |
| 5 | plan       | planner            | decompose_mode=DISABLED  | analyze, triage     | block                |
| 6 | fix        | fixer              | never                    | plan, triage, repro | rollback-and-block   |
| 7 | review     | reviewer           | never                    | fix, triage         | back-to-fix          |
| 8 | test       | test-engineer      | profile.skip             | fix                 | retry(3)             |
| 9 | e2e-test   | e2e-test-engineer  | !e2e_config              | fix                 | retry(3)             |
|10 | verify-ui  | browser-verifier   | !browser_verify          | fix, reproduce      | skip                 |
|11 | gate       | acceptance-gate    | ac<3 AND complexity<M    | fix, test, triage   | block                |
|12 | publish    | publisher          | never                    | fix, review         | block                |

## Decomposition

Trigger: code-analyst risk=HIGH OR files>=4 OR (diff>60 AND files>=3) OR changes>=2
Agent: planner (ceos mode)
Max subtasks: from config (default 7)
Per-subtask loop: phases 6-7 repeated per subtask, then integration phase 8
```

### The Review Loop as a Primitive

`core/review-loop.md` defines the generic iteration protocol:

```
ReviewLoop(writer_agent, reviewer_agent, max_iterations, context) {
  for i in 1..max_iterations:
    writer_output = dispatch(writer_agent, context + reviewer_feedback)
    reviewer_output = dispatch(reviewer_agent, writer_output)
    if reviewer_output.verdict == APPROVE: return SUCCESS
    reviewer_feedback = reviewer_output.issues
  return BLOCK("Max iterations exhausted")
}
```

This single primitive replaces three separate fixer-reviewer loop implementations in fix-ticket, fix-bugs, and implement-feature, plus the spec-writer/spec-reviewer loop in scaffold. The engine calls `ReviewLoop(fixer, reviewer, 5, ...)` for code modes and `ReviewLoop(spec-writer, spec-reviewer, 5, ...)` for scaffold mode.

### Why This Is Better Than Pattern Extraction

Pattern extraction preserves the current model where each command is its own orchestrator that happens to call shared subroutines. The engine model inverts control: the engine is the orchestrator, and mode adapters are declarative configuration. Adding a new pipeline mode is adding a table, not writing a 400-line command.

---

## 3. Agent Merge Strategy

### Merge: architect + forge planner → `planner.md`

**I disagree with keeping these as separate agents.** Phase 2 Domain 3 confirms that no consuming command parses agent identity — they parse YAML structure. A unified planner with mode dispatch is MORE compatible, not less.

The planner agent receives a `mode` parameter in its context:

- **ceos mode** (default): Produces the current architect output exactly. `maps_to: AC-{N}: {text}` format preserved verbatim. `sub-{N}` IDs, `depends_on[]`, `estimated_lines` — all unchanged. The `Decomposition: YES/NO` signal preserved.
- **forge mode**: Produces the forge planner output. `REQ-{NNN}` format. Task graph with phase assignments.

The mode is set by the engine based on which mode adapter is active. No agent needs to "decide" which format to use — the orchestration layer tells it.

**The `architect` name is retired.** The agent file moves to `agents/planner.md`. The rollback-agent's skip list, the discuss command's default panel, and any other hardcoded references to "architect" are updated in the same PR. This is a Class A change — internal only, no user impact beyond Agent Override users who have `customization/architect.md`.

For Agent Override users: the migration guide documents `architect.md → planner.md` rename. `check-setup` gains a validation that warns if `customization/architect.md` exists but `customization/planner.md` does not.

### Do NOT Merge: spec-analyst + spec-writer

Phase 2 confirms these are incompatible: spec-analyst extracts WHAT from an issue tracker (read-only, sonnet, `NEVER design architecture`). spec-writer generates a full specification including architecture (write, opus). These remain separate agents. Anyone proposing this merge is solving a naming problem, not an architecture problem.

### Do NOT Merge: spec-writer + forge spec-writer

Same reasoning: ceos spec-writer generates software project specifications in the `spec/` folder convention. Forge's spec-writing is a different pipeline phase with different inputs (brainstorm output, not user description). The spec-writer's current design is already well-scoped for software projects. Non-code modes get their own document-generation agents (see section 6) rather than overloading spec-writer with mode switches.

### New Agents (3)

1. **`intake-agent.md`** (sonnet) — Flexible input ingestion. Accepts URL, PDF, pasted text, file set, conversation transcript. Produces a structured brief (summary, key facts, constraints, open questions). This is the non-code equivalent of triage-analyst + code-analyst combined.

2. **`domain-analyst.md`** (opus) — Analytical and strategic reasoning. Statistical claim assessment, logical validity checking, causal analysis, competitive landscape analysis, stakeholder mapping. This fills Gaps 2, 3, and 5 from Phase 2 Domain 6. One agent, not three — the mode adapter context tells it whether to reason analytically or strategically.

3. **`synthesizer.md`** (sonnet) — Output assembly. Takes reviewed findings/recommendations and produces the final deliverable in the appropriate format (report, strategy document, content piece). The non-code equivalent of publisher. Handles formatting, information hierarchy, audience adaptation.

### Agent Rename Safety

The `agents/planner.md` rename from `agents/architect.md` triggers updates in:
- rollback-agent.md skip list (Class A)
- discuss.md default agents (Class A)
- All commands referencing `ceos-agents:architect` in Task tool calls (~6 references, Class A)
- skills/bug-workflow/SKILL.md intent table (Class A)
- CLAUDE.md agent table and pipeline diagrams (Class B)
- docs/reference/ agent reference (Class B)

All Class A changes go in one atomic PR. Class B documentation updates go in the same PR. Agent Override users get a `check-setup` warning — not a compatibility shim.

---

## 4. Command to Skill Migration

### The `/build` Entry Point

`/build` is the primary user-facing command. It replaces all pipeline commands with a single, mode-aware entry point.

**Invocation:**

```
/build "fix login timeout bug" --ticket PROJ-123
/build "implement OAuth2 support" --ticket PROJ-456
/build "create a task management app with React and Supabase"
/build "analyze our Q1 marketing performance" --mode analysis
/build "develop a go-to-market strategy for APAC" --mode strategy
/build "write a technical blog post about our migration" --mode content
```

**Mode Detection Logic** (in `skills/build/mode-detection.md`):

```
1. If --mode provided → use that mode directly
2. If --ticket provided:
   a. Read ticket from issue tracker
   b. If ticket type is bug/defect → code-bug
   c. If ticket type is feature/story → code-feature
   d. If ambiguous → ask user
3. If no --ticket AND description provided:
   a. If CWD has no git repo OR description mentions "new project"/"create"/"scaffold" → code-project
   b. If description mentions "analyze"/"research"/"evaluate" → analysis
   c. If description mentions "strategy"/"plan"/"roadmap" → strategy
   d. If description mentions "write"/"blog"/"documentation"/"content" → content
   e. Default → code-feature (with confirmation)
4. If nothing provided → interactive: ask what they want to do
```

**Flag Mapping:**

| Current Command Flag | `/build` Equivalent |
|---------------------|---------------------|
| `fix-ticket PROJ-123` | `build --ticket PROJ-123` (auto-detects bug) |
| `fix-bugs 5` | `build --batch 5 --mode code-bug` |
| `implement-feature PROJ-456` | `build --ticket PROJ-456` (auto-detects feature) |
| `scaffold "description"` | `build "description"` (auto-detects project) |
| `--dry-run` | `--dry-run` (unchanged) |
| `--decompose` | `--decompose` (unchanged) |
| `--profile fast` | `--profile fast` (unchanged) |
| `--yolo` | `--yolo` (unchanged) |
| `scaffold --no-implement` | `build --mode code-project --skeleton-only` |
| `scaffold --brainstorm` | `build --mode code-project --brainstorm` |

### Non-Pipeline Commands → Ops Skill

Commands that are not pipeline orchestrations become the `ops` skill:

| Current Command | Ops Skill Route |
|----------------|-----------------|
| `status` | `/ops status` |
| `dashboard` | `/ops dashboard` |
| `metrics` | `/ops metrics` |
| `check-setup` | `/ops check-setup` |
| `estimate` | `/ops estimate PROJ-123` |
| `prioritize` | `/ops prioritize` |
| `version-check` | `/ops version-check` |
| `version-bump` | `/ops version-bump` |
| `changelog` | `/ops changelog` |
| `onboard` | `/ops onboard` |
| `init` | `/ops init` |
| `migrate-config` | `/ops migrate-config` |
| `template` | `/ops template` |
| `discuss` | `/ops discuss` |
| `resume-ticket` | `/build --resume PROJ-123` (absorbed into /build) |

`resume-ticket` is not a separate command — it is `--resume` on `/build`. The engine reads the state file (or falls back to heuristics for pre-migration tickets) and resumes from the recorded checkpoint. This eliminates the separate resume-ticket command with its fragile step-number mapping entirely.

### The Legacy Skill

`skills/legacy/SKILL.md` is a simple routing table:

```
User invokes ceos-agents:fix-ticket PROJ-123
  → Display: "⚠ Deprecated: use /build --ticket PROJ-123 instead"
  → Invoke: Skill('build', args='--ticket PROJ-123')
```

This file has a hard expiration: removed in v7.0.0 (two minor versions after introduction in v6.0.0). The deprecation window is 2 minor releases, not "indefinite." Reason: every day the legacy router exists is a day someone writes a tutorial referencing the old commands. A clean break, announced loudly, is better than permanent dual paths.

---

## 5. Backward Compatibility

### My Stance: Aggressive but Honest

The Conservative approach will propose long deprecation cycles, adapter layers, and "no breaking changes for N versions." I believe this is wrong. Here is why:

1. **The plugin has a small user base.** This is an internal tool at CEOS, not a public npm package with 10M weekly downloads. The blast radius of a breaking change is bounded and knowable.

2. **The `[CLAUDE-agents]` → `[ceos-agents]` precedent proves breaking changes are survivable.** The rename happened, users adapted, and the codebase already supports dual-prefix detection in resume-ticket. Another rename is not unprecedented.

3. **Compatibility shims become permanent.** Every "temporary" compatibility layer I have seen in developer tools is still there 3 years later because removing it is always lower priority than new features.

### Concrete Strategy

**KEEP (no changes ever):**
- `[ceos-agents]` comment prefix in all Class C templates (23 templates). These are immutable. Adding new comment types is fine; changing existing ones is not.
- Plugin name `ceos-agents` in plugin.json. The namespace stays.
- Automation Config table format and all existing required/optional sections.
- `maps_to: AC-{N}: {text}` format in planner output (ceos mode). This is regex-parsed and failure is silent.

**CHANGE WITH MIGRATION GUIDE (v6.0.0 MAJOR):**
- `commands/` directory: all commands become 5-line redirects to `/build` or `/ops`. Users see a deprecation warning. Commands are fully removed in v7.0.0.
- `architect` agent renamed to `planner`. Agent Override users with `customization/architect.md` get a `check-setup` warning. The file is not auto-migrated — the user renames it.
- `resume-ticket` command absorbed into `build --resume`. The legacy redirect handles the transition.
- New state directory: `.ceos-agents/{ISSUE-ID}/state.json` added alongside (not replacing) the existing `.claude/decomposition/` path. The engine reads both; writes only to the new location. Old decomposition YAML remains supported for in-flight tickets.

**CHANGE WITHOUT CEREMONY (v6.0.0, internal only):**
- All Class A references (~60) updated in the same PR that introduces the engine.
- Test suite restructured (see section 8).
- Internal command cross-references in documentation updated.

**NOT CHANGED (explicitly deferred):**
- `[ceos-agents]` is NOT renamed to something like `[build-pipeline]`. The comment prefix is permanent.
- The `ceos-agents:` namespace prefix on commands is NOT changed. Even in the legacy redirects, the invocation path `ceos-agents:fix-ticket` continues to work.

### Deprecation Timeline

| Version | What Happens |
|---------|-------------|
| v5.2.0 (prep) | Prerequisites: state.json, test fixes, race condition fix, pre-existing gaps. No breaking changes. |
| v6.0.0 (MAJOR) | Pipeline engine, `/build`, `/ops`, `planner` rename, command deprecation warnings. Full migration guide in CHANGELOG. |
| v6.1.0 | Non-code modes (analysis, strategy, content). New agents. |
| v7.0.0 (MAJOR) | Remove deprecated command redirects. Remove `skills/legacy/`. Clean break. |

Two versions. Not five. Not "when we get around to it."

---

## 6. Non-Code Modes

### All Four Modes in Scope for v6.1.0

The Conservative will want to ship "analysis only" and defer strategy/content. I think this is wrong because:
- The pipeline engine is mode-agnostic by design. Adding a mode is adding a mode adapter file, not modifying the engine.
- The three new agents (intake-agent, domain-analyst, synthesizer) serve all non-code modes. Building them for one mode and then "extending" them for others is wasted effort — build them generically from the start.
- Users who want non-code modes want them now. Shipping analysis-only is like shipping a car with the steering wheel but no gas pedal.

### Mode Definitions

**Analysis Mode** (`modes/analysis.md`):

Purpose: Structured analysis of a topic, dataset, or situation. Output: analytical report with findings, evidence, and recommendations.

| Phase | Agent | Purpose |
|-------|-------|---------|
| intake | intake-agent | Ingest input (URL, PDF, text, files). Produce structured brief. |
| analyze | domain-analyst | Deep analytical reasoning. Statistical assessment, causal analysis, logical validity. |
| draft | spec-writer (adapted) | Generate structured report (findings, evidence, conclusions, recommendations). |
| review | reviewer (adapted) | Adversarial review. Check logical fallacies, unsupported claims, missing evidence. |
| revise | spec-writer (adapted) | Address reviewer feedback. Strengthen weak arguments. |
| synthesize | synthesizer | Final formatting. Executive summary. Visualization suggestions. |

Review loop: spec-writer ↔ reviewer, max 3 iterations.

**Strategy Mode** (`modes/strategy.md`):

Purpose: Strategic planning and decision-making. Output: strategy document with options, trade-offs, recommendations, and action plan.

| Phase | Agent | Purpose |
|-------|-------|---------|
| intake | intake-agent | Ingest context (market data, competitor info, constraints). |
| analyze | domain-analyst | Competitive landscape, stakeholder mapping, scenario planning. |
| plan | planner (strategy mode) | Generate strategic options with trade-off matrix. |
| draft | spec-writer (adapted) | Write strategy document (situation, options, recommendation, action plan). |
| review | reviewer (adapted) | Feasibility check. Bias detection. Assumption validation. |
| revise | spec-writer (adapted) | Strengthen. |
| synthesize | synthesizer | Final formatting. Decision framework. Timeline. |

**Content Mode** (`modes/content.md`):

Purpose: Content creation (blog posts, documentation, technical writing). Output: publication-ready content.

| Phase | Agent | Purpose |
|-------|-------|---------|
| intake | intake-agent | Ingest brief (topic, audience, format, references). |
| outline | planner (content mode) | Structure: sections, key points, flow. |
| draft | spec-writer (adapted) | Write content following outline. |
| review | reviewer (adapted) | Readability, audience fit, accuracy, information hierarchy. |
| revise | spec-writer (adapted) | Polish. |
| synthesize | synthesizer | Final formatting. SEO suggestions. Publication metadata. |

### Agent Adaptation Strategy

Rather than creating 4 variants of spec-writer for each mode, the reviewer and spec-writer receive a **domain context block** from the mode adapter. This block replaces their software-specific checklists with domain-appropriate criteria.

Example: in analysis mode, the reviewer's context includes:

```
## Domain Review Criteria (replaces software checklists)
- Logical validity: Do conclusions follow from evidence?
- Causal claims: Are causal assertions supported or merely correlational?
- Statistical claims: Are sample sizes, confidence intervals, and methodologies sound?
- Bias detection: Are there confirmation bias, survivorship bias, or selection bias patterns?
- Completeness: Are obvious counterarguments addressed?
- Actionability: Are recommendations specific enough to execute?
```

This is exactly the same mechanism as Agent Overrides (`customization/reviewer.md`), but injected by the mode adapter rather than by the user. The agent prompt structure (Goal, Expertise, Process, Constraints) is unchanged.

### Non-Code State

Non-code modes use the same `.ceos-agents/{RUN-ID}/state.json` structure. The RUN-ID is a timestamp-based ID (not an issue ID, since non-code modes may not have issue tracker context). The state file tracks phase completion, iteration counts, and output artifacts identically to code modes.

---

## 7. State Management

### Unified State Model

A single state directory at `.ceos-agents/` replaces both the current `.claude/decomposition/` convention and the `.forge/` directory.

**Why not keep `.forge/`?** Because the plugin is called `ceos-agents`, not `forge`. Using `.forge/` for a `ceos-agents` plugin is confusing — it looks like a different tool's state. The forge state model is excellent; the directory name is wrong. Migration is a one-line check: "if `.forge/` exists and `.ceos-agents/` does not, migrate."

**Directory structure:**

```
.ceos-agents/
├── {ISSUE-ID or RUN-ID}/
│   ├── state.json           # Pipeline position, phase statuses, iteration counts
│   ├── triage.json          # Full triage output (AC list, complexity, severity, reproduction_steps)
│   ├── analysis.json        # Code-analyst/domain-analyst output
│   ├── plan.json            # Planner output (task tree or strategic plan)
│   ├── review-log.json      # Reviewer verdicts and feedback per iteration
│   ├── reproduction/        # Browser artifacts (worktree-safe: namespaced by run)
│   │   ├── result.json
│   │   ├── script.js
│   │   └── screenshots/
│   └── pipeline.log         # Append-only event log (forge.log equivalent)
└── config-cache.json        # Parsed Automation Config (avoids re-parsing per phase)
```

**state.json Schema:**

```json
{
  "schema_version": "1.0.0",
  "run_id": "PROJ-123",
  "mode": "code-bug",
  "status": "running",
  "started_at": "2026-03-22T10:00:00Z",
  "updated_at": "2026-03-22T10:15:00Z",
  "config_snapshot": {
    "profile": "fast",
    "skip_stages": ["triage"],
    "retry_limits": {"fixer": 5, "test": 3, "build": 3}
  },
  "phases": {
    "setup":    {"status": "completed", "started_at": "...", "completed_at": "..."},
    "triage":   {"status": "skipped", "reason": "profile: fast"},
    "analyze":  {"status": "completed", "started_at": "...", "completed_at": "..."},
    "fix":      {"status": "running", "iteration": 2, "started_at": "..."},
    "review":   {"status": "pending"},
    "test":     {"status": "pending"},
    "publish":  {"status": "pending"}
  },
  "decomposition": {
    "active": true,
    "strategy": "sequential",
    "subtasks": [
      {"id": "sub-1", "status": "completed", "commit_hash": "abc123"},
      {"id": "sub-2", "status": "running"},
      {"id": "sub-3", "status": "pending"}
    ]
  },
  "metrics": {
    "total_iterations": {"fixer": 2, "test": 0, "build": 1},
    "blocks": []
  }
}
```

### Resume from State

The `--resume` flag on `/build` reads state.json directly:

1. Find `.ceos-agents/{ISSUE-ID}/state.json`
2. If exists: read the last completed phase, resume from the next pending phase
3. If not exists: fall back to the current heuristic detection (comment + git state) for backward compatibility with pre-v6.0.0 runs
4. The heuristic fallback is removed in v7.0.0

This eliminates the stage-number coupling in resume-ticket entirely. The state file is authoritative. Step numbers are an implementation detail of the mode adapter, not a resume contract.

### Race Condition Fix

The reproduction/verification artifacts move from `.claude/reproduction-result.json` (shared, race-prone) to `.ceos-agents/{ISSUE-ID}/reproduction/result.json` (per-issue, isolated). This fixes the HIGH-risk race condition in fix-bugs parallel mode identified in Phase 2 Domain 4.

### Backward Compatibility for State

- `.claude/decomposition/{ISSUE-ID}.yaml` continues to be read (but not written) by the engine for in-flight tickets that started before v6.0.0
- `.forge/` directories in other projects are not touched (forge is a different plugin)
- The `[ceos-agents]` comment prefix in issue trackers is unchanged — comments remain the external state signal

---

## 8. Migration Sequence

### Approach: 4 PRs, Not 12

The Conservative will propose many small, individually safe PRs. I propose fewer, larger, well-scoped PRs because:

1. Each PR that touches the pipeline engine requires re-running all tests. Many small PRs means many test runs against half-migrated state.
2. Half-migrated states are the most dangerous states. A codebase with both old commands and new engine running simultaneously is harder to reason about than one that has fully transitioned.
3. Code review is more effective on coherent changesets. A PR titled "extract MCP pre-flight pattern" tells the reviewer nothing about whether the final architecture works. A PR titled "introduce pipeline engine with code-bug mode" is reviewable as a design.

### PR 1: Prerequisites (v5.2.0 MINOR)

**Scope:** All 6 prerequisites from Phase 2, plus test infrastructure.

1. Fix `.claude/` race condition (reproducer.md, browser-verifier.md, fix-bugs.md — path namespacing)
2. Fix spec-writer.md missing emoji in block comment
3. Fix `discuss` gap in skill router
4. Update 3 fragile tests (happy-path.sh, verify-fail.sh, pipeline-consistency.sh)
5. Add 4 structural parity tests
6. Introduce `.ceos-agents/{ISSUE-ID}/state.json` — commands write state after each phase; resume-ticket reads state (with heuristic fallback)

**Rollback:** `git revert` the PR. All changes are additive (state writing is new; old behavior preserved via fallback).

**Test plan:** All 18 existing + 4 new tests pass. Manual test: run fix-ticket on a real issue, verify state.json is written, verify resume-ticket reads it.

### PR 2: Pipeline Engine + Code Modes (v6.0.0 MAJOR)

**Scope:** The core architectural change.

1. Create `core/` directory with all 7 engine files
2. Create `modes/` directory with code-bug.md, code-feature.md, code-project.md
3. Create `skills/build/` with SKILL.md, mode-detection.md, flag-reference.md
4. Create `skills/ops/SKILL.md` for non-pipeline commands
5. Create `skills/legacy/SKILL.md` for deprecated command routing
6. Rename `agents/architect.md` → `agents/planner.md` with mode dispatch
7. Convert all 24 commands to 5-line redirects
8. Update all internal references (Class A: ~60)
9. Update documentation (Class B: ~160)
10. Restructure test suite into `tests/scenarios/{engine,modes,agents,integration,legacy}/`
11. Wire mock-mcp-server for integration tests
12. Write MIGRATION.md guide

**Rollback:** This is a major version. Rollback is "stay on v5.2.x." The v6.0.0 tag is not pushed until the full PR is reviewed and tested.

**Test plan:** All restructured tests pass. Integration tests using mock-mcp-server validate engine dispatches agents correctly for code-bug mode. Legacy redirect tests confirm old command invocations still work.

### PR 3: Non-Code Modes + New Agents (v6.1.0 MINOR)

**Scope:** Additive — new modes and agents.

1. Create 3 new agents: intake-agent.md, domain-analyst.md, synthesizer.md
2. Create modes: analysis.md, strategy.md, content.md
3. Update build skill mode-detection.md with new mode patterns
4. Add mode-specific domain context blocks for reviewer/spec-writer adaptation
5. Add test scenarios for non-code modes
6. Update documentation with non-code mode reference

**Rollback:** `git revert` the PR. No existing functionality is modified.

**Test plan:** New mode adapter tests validate phase sequences. Agent structural tests validate new agents follow the frontmatter convention. Integration tests validate the intake→analyze→draft→review loop.

### PR 4: Legacy Removal (v7.0.0 MAJOR)

**Scope:** Remove all deprecated paths.

1. Delete `commands/` directory entirely
2. Delete `skills/legacy/SKILL.md`
3. Remove heuristic fallback from resume logic (state.json is authoritative)
4. Remove `.claude/decomposition/` read support (migrate-config handles conversion)
5. Clean up any remaining dual-path code
6. Update all documentation to reference only `/build` and `/ops`

**Rollback:** Stay on v6.x.

---

## Risk Assessment

### What Could Go Wrong

**Risk 1: Engine abstraction is too rigid for scaffold.**
Scaffold is the most divergent pipeline. It has state detection (empty dir, existing project), spec-writer/spec-reviewer loop before any implementation, and git-init mid-pipeline. The mode adapter for code-project may need "meta-phases" (scaffold-setup, spec-loop) that do not fit the uniform Phase protocol.
*Mitigation:* The Phase protocol includes `on_fail: "decompose"` and skip conditions. Scaffold-specific phases (scaffolder, git-init) are first-class phases in the code-project adapter, not shoehorned into the generic "fix" phase. If the Phase protocol genuinely cannot express scaffold, it gets extended — but the burden of proof is on scaffold's uniqueness, not on the engine's flexibility.

**Risk 2: Mode auto-detection is unreliable.**
Natural language intent detection ("is this a bug or a feature?") will get it wrong sometimes. A user saying "fix the login" might mean a bug fix or a feature improvement.
*Mitigation:* Auto-detection always has a confirmation step unless `--mode` is explicit or `--yolo` is set. The penalty for misdetection is one extra prompt, not a wrong pipeline execution.

**Risk 3: Planner mode dispatch introduces subtle format bugs.**
A single planner agent emitting two different output formats (AC-{N} for ceos, REQ-{NNN} for forge) has a higher risk of format contamination than two separate agents.
*Mitigation:* The planner receives explicit mode context: "You are operating in ceos mode. Your output MUST use `maps_to: AC-{N}: {text}` format. NEVER use REQ-{NNN} format in ceos mode." The structural test suite validates output format per mode. Silent failures are caught by the AC coverage check in the engine (which already exists and would catch a wrong format).

**Risk 4: The 4-PR approach is too large per PR.**
PR 2 touches every file in the repository. Review fatigue is real.
*Mitigation:* PR 2 is split into reviewable sections (core/ first, then modes/, then skills/, then commands/, then tests, then docs). The PR description includes a reading order. The alternative — 12 small PRs each touching half the codebase — is worse for review coherence.

**Risk 5: Non-code modes lack real-world validation.**
Analysis, strategy, and content modes are designed from first principles, not from user feedback.
*Mitigation:* Ship them as "experimental" in v6.1.0 with a clear label. Collect feedback. Iterate in v6.2.0. The engine architecture means mode changes are mode-adapter-only changes — low cost to iterate.

**Risk 6: Agent Override users with `customization/architect.md` silently lose their customizations.**
The rename from architect to planner means their override file stops being picked up.
*Mitigation:* `check-setup` validation added in PR 2 that warns: "Found customization/architect.md but no customization/planner.md — your architect overrides will not be applied. Rename the file." This is a diagnostic warning, not an automatic migration — users should review their overrides during the rename.

---

## Explicit Disagreements with Conservative Approach

### 1. Deprecation Timeline

**Conservative says:** "Keep old commands working for 3-5 minor versions. Deprecation warnings first, removal later, maybe."
**I say:** Two versions. v6.0.0 introduces redirects with warnings. v7.0.0 removes them. Every version the old commands exist, someone writes automation referencing them. The longer you wait, the more expensive the removal becomes. The `[CLAUDE-agents]` → `[ceos-agents]` precedent proves the user base can handle a migration.

### 2. Pattern Extraction vs. Engine

**Conservative says:** "Extract the 10 shared patterns into reusable includes. Keep commands as orchestrators."
**I say:** Pattern extraction preserves the fundamental problem — three 400-line monoliths that each re-implement orchestration logic. The engine model inverts control. Mode adapters are declarative phase tables, not imperative orchestration scripts. This is a one-time higher cost for a permanently lower maintenance burden.

### 3. Agent Merges

**Conservative says:** "Keep architect and planner as separate agents to avoid format contamination risk."
**I say:** Two agents emitting identical YAML schemas with different field values is MORE maintenance and MORE drift risk than one agent with explicit mode dispatch. The consuming commands parse structure, not agent identity. Unification with mode dispatch is the cleaner architecture.

### 4. Non-Code Mode Scope

**Conservative says:** "Ship analysis mode first, defer strategy and content."
**I say:** The pipeline engine is mode-agnostic. The three new agents serve all non-code modes. Shipping one mode and "extending" to others later means building the agents twice — once narrowly, once generically. Build them generically from the start. The marginal cost of three mode adapter files vs. one is trivial.

### 5. State Directory Naming

**Conservative says:** "Keep `.forge/` for backward compatibility since forge users already have it."
**I say:** `.forge/` is the state directory for the `forge` skill in the `filip-superpowers` plugin. It is not the state directory for `ceos-agents`. Using `.forge/` in a `ceos-agents` plugin is confusing to anyone who did not attend the design meeting. The state directory should be `.ceos-agents/`. The one-time migration cost (check for `.forge/`, move to `.ceos-agents/`) is worth the permanent clarity.

### 6. PR Size

**Conservative says:** "Many small PRs, each independently revertible."
**I say:** Half-migrated states are the most dangerous states. A codebase with both old commands actively orchestrating and a new engine partially deployed is harder to reason about, harder to test, and harder to debug than a codebase that has cleanly transitioned. Four well-scoped PRs with clear rollback boundaries (stay on previous version) are safer than twelve PRs that create twelve intermediate states.

### 7. Test Strategy

**Conservative says:** "Keep grep-based tests, add a few more."
**I say:** The test suite is a false confidence generator (Phase 2 Insight 6). A command could lose its entire fixer-reviewer loop and all tests would pass. The mock-mcp-server exists. The mock-project exists. They have never been wired. PR 2 is the right time to wire them — the engine restructure requires new tests anyway. Static grep tests are kept for structural validation; integration tests are added for behavioral validation. Both, not either.
