# Research Answers — Foundation Layer (RQ-01 to RQ-04)

## RQ-01: Command chaining capability

**Answer:** There is no true command chaining in ceos-agents. No command file invokes another command directly. All cross-unit delegation uses the Task tool dispatching a named **agent** (e.g., `ceos-agents:triage-analyst`, `ceos-agents:fixer`). The only mechanism that invokes a *command* from another unit is the Skill router (`skills/bug-workflow/SKILL.md`), which calls `Skill(skill='ceos-agents:{command}', args='...')` — but this is a skill-to-command call, not a command-to-command call.

**Evidence:**

- `commands/fix-bugs.md` — every delegation is `Task tool` dispatching agents: `ceos-agents:triage-analyst`, `ceos-agents:code-analyst`, `ceos-agents:fixer`, `ceos-agents:reviewer`, `ceos-agents:test-engineer`, etc. (lines 95, 111, 198, 212, 246, 255, 274, 293, 314, 391). No reference to another command by slash-command syntax.
- `commands/fix-ticket.md` — identical pattern: all delegation is `Task tool` → agent name. (lines 99, 112, 189, 203, 237, 246, 261, 284, 306).
- `commands/implement-feature.md` — same pattern (lines 90, 102, 177, 205, 219, 225). No command invocation.
- `commands/scaffold.md` — dispatches `spec-writer`, `spec-reviewer`, `scaffolder`, `architect`, `fixer`, `reviewer`, `test-engineer`, `e2e-test-engineer`, `rollback-agent` via Task. No command invocation.
- `commands/resume-ticket.md` step 10: instructs to "use steps corresponding to the detected pipeline type: BUG → `/fix-ticket`, FEATURE → `/implement-feature`" — this is prose telling the *executing model* to follow the logic defined in those command files, NOT a programmatic invocation of those commands. The command text is read as reference, not invoked.
- `skills/bug-workflow/SKILL.md` lines 43–47: the ONLY `Skill()` invocations in the entire codebase — used by the skill router to invoke commands, not by commands to invoke each other.

**Confidence:** HIGH

**Implications:** True command chaining (one command calling another as a sub-process) does not exist and is not supported by the architecture. The 2-layer model is strict: commands orchestrate agents via Task tool; skills route to commands via Skill(). Any design that requires one pipeline command to hand off to another (e.g., fix-bugs calling fix-ticket per-bug) cannot be expressed natively — it must be replicated inline or refactored into shared agent definitions. The `resume-ticket` pattern (step 10) works around this by embedding both pipeline step tables in a single command file rather than calling the original commands.

---

## RQ-02: Skill() cross-plugin namespace scope

**Answer:** The ceos-agents codebase contains zero cross-plugin Skill() calls — all Skill() calls use the `ceos-agents:` namespace. The `.forge.bak-20260325-204006` research artifacts document the existence of a second plugin (`filip-superpowers`) with skills like `forge-plan`, `forge-execute`, etc., but no file in the ceos-agents plugin calls `Skill(skill='filip-superpowers:...')`. The forge bak files show that `filip-superpowers`'s own forge skill references its own sub-skills via `/filip-superpowers:forge-resume` (intra-plugin cross-skill calls), but whether this syntax works *across* plugin namespaces is unconfirmed from codebase inspection alone.

**Evidence:**

- `skills/bug-workflow/SKILL.md` lines 43, 47: Skill() calls use `Skill(skill='ceos-agents:analyze-bug', ...)` and `Skill(skill='ceos-agents:{command}', ...)` only. Namespace is always `ceos-agents`.
- Exhaustive grep for `Skill(skill='filip` and `filip.*Skill` across all `.md` files in `C:/gitea_ceos-agents/` returned zero matches in the live codebase.
- `.forge.bak-20260325-204006/phase-1-research-questions/agents/agent-1.md` line 199: explicitly lists as an **open question**: "Can a skill call another skill? The forge/SKILL.md references sub-skills like `/filip-superpowers:forge-resume`. Is there a depth limit or recursive invocation constraint?" — confirming cross-plugin Skill() was identified as unverified during prior research.
- `.forge.bak-20260325-204006/phase-2-research-answers/final.md` (Domain 1): does not contain a finding confirming or denying cross-plugin Skill() support. The question remained open after Phase 2.
- `docs/plans/roadmap.md` references "Cross-plugin bridge" under EXPLORING, not IMPLEMENTED — aligning with the finding that no cross-plugin call has been made.
- `.claude-plugin/plugin.json`: contains only `name`, `description`, `version`, `author`, `repository`, `license`. No tool declarations, no cross-plugin bridge configuration.

**Confidence:** MEDIUM — absence of cross-plugin calls is confirmed from codebase inspection. Whether the Claude Code runtime *supports* `Skill(skill='other-plugin:skill-name')` syntax is NEEDS_VALIDATION: no test or documentation in the inspectable files confirms or denies runtime support.

**NEEDS_VALIDATION:** Empirically invoke `Skill(skill='filip-superpowers:forge-status')` from within a ceos-agents context to confirm whether the Claude Code runtime resolves cross-plugin namespace references at invocation time.

**Implications:** The cross-plugin bridge is architecturally unexplored territory within this codebase. Any design that assumes a ceos-agents skill can call `filip-superpowers:forge-plan` as a subprocess must validate this assumption at runtime before committing to it. The roadmap's "EXPLORING" classification is the accurate current status. If cross-plugin Skill() calls do not work at runtime, the only integration path is prose-level documentation (tell the user to run the other plugin's command separately) or duplicating the logic inside ceos-agents.

---

## RQ-03: allowed-tools hard capability ceiling

**Answer:** The `allowed-tools` frontmatter in commands is the complete tool whitelist for that command's execution context. It is a hard ceiling in the sense that only listed tools are available to the executing command. However, this ceiling is determined at the **command level only** — agents dispatched via the Task tool run with their own tool access context (defined by whatever the Task tool provides to subagents), not necessarily bound by the parent command's `allowed-tools`. The `plugin.json` contains no tool declarations whatsoever.

**Evidence:**

- `commands/fix-ticket.md` frontmatter: `allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task` — 8 tool categories declared.
- `commands/fix-bugs.md` frontmatter: `allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task` — identical declaration.
- `commands/scaffold.md` frontmatter: `allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task` — identical.
- `commands/implement-feature.md` frontmatter: `allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task` — identical.
- All 24 commands use identical `allowed-tools` (confirmed by examining fix-ticket, fix-bugs, implement-feature, scaffold — all match).
- `.claude-plugin/plugin.json`: contains only `name`, `description`, `version`, `author`, `repository`, `license`. **Zero tool declarations.** There is no plugin-level tool permission layer.
- `.forge.bak-20260325-204006/phase-2-research-answers/agents/agent-1.md` (Finding 1.5): "Neither ceos-agents nor filip-superpowers declares commands, skills, or agents in plugin.json. Discovery is by directory convention."
- Skills have **no** `allowed-tools` field: `skills/bug-workflow/SKILL.md` frontmatter contains only `name` and `description`. Prior research (forge bak phase-2 final.md Domain 1) confirms skills inherit unrestricted session tool access.

**Confidence:** HIGH for the command-level ceiling. MEDIUM for agent tool access (agents dispatched via Task are not explicitly bounded by the parent command's `allowed-tools` in the inspectable files — the Claude Code SDK behavior for Task subagent tool inheritance is not documented in the codebase).

**NEEDS_VALIDATION:** Confirm whether an agent dispatched via the Task tool from inside a command is constrained to the parent command's `allowed-tools` list, or whether it receives a broader/unrestricted tool set. The agent definition files (`agents/*.md`) contain no `allowed-tools` frontmatter — they only have `name`, `description`, `model`, `style`.

**Implications:** The `allowed-tools` declaration in commands is the designed security boundary for the command layer. The absence of `allowed-tools` from `plugin.json` means there is no plugin-wide override — each command's frontmatter is authoritative for its own context. Read-only enforcement for agents like `triage-analyst`, `code-analyst`, and `reviewer` is implemented entirely via prose instructions in their agent definitions ("NEVER modify code"), not by tool restriction. This means a malfunctioning or adversarial agent could technically call Write or Edit even though the agent prose says it should not — there is no structural enforcement below the command level.

---

## RQ-04: Mid-session crash resume consistency

**Answer:** `core/state-manager.md` provides a well-specified atomic write protocol and a resume-point calculation algorithm, but it does **not** guarantee a fully consistent resume point after a mid-session crash. It guarantees: (1) atomic writes via `.tmp` rename, (2) a deterministic resume-point calculation from completed/in_progress/pending step statuses, and (3) a fallback to heuristic detection when no state file exists. It does NOT guarantee: the `in_progress` status is written before a crash inside a step, recovery context is complete for all pipeline modes, or that the fixer-reviewer iteration count surviving a crash within a loop iteration is accurate.

**Evidence:**

- `core/state-manager.md` Write Process steps 1–8: atomic write via `state.json.tmp` rename. Failure handling: retry once after 1 second; if retry fails, log warning and continue (state loss is non-fatal). This means a crash during a write can leave either the old state or no state — not a corrupted partial write, but potentially a stale state.
- `core/state-manager.md` Resume Process: "Find the first step with status 'in_progress' or 'pending' after all 'completed' steps." The resume point is only as accurate as the last successful write. If a crash occurs mid-step before the step's completion write, the resume will re-execute the entire step from its start.
- `state/schema.md` Step Status Enum: `pending`, `in_progress`, `completed`, `failed`, `skipped`, `blocked`, `not_applicable`. The `in_progress` status is written at phase start (per `pipeline.log` event `phase_start`), and `completed` at phase end. A crash between these two writes leaves the step as `in_progress` — which is the correct resume signal, but means the step re-executes from scratch (potentially re-running git operations, fixer invocations, etc.).
- `commands/fix-bugs.md` and `fix-ticket.md`: state writes occur at phase completion (e.g., "After each fixer-reviewer iteration, update state.json: increment fixer_reviewer.iterations"). A crash mid-iteration means the iteration count is not incremented — the iteration re-runs on resume but counts toward the same max limit via the state file's recorded count.
- `commands/resume-ticket.md` Priority 0 (state file detection): "Find the first step with status 'in_progress' → resume from that step." If `in_progress` was never written (crash before phase_start write), fallback is to heuristic detection — which is documented as "best-effort" and "not 100% accurate."
- `core/state-manager.md` Failure Handling: "Corrupted state file: If JSON parse fails on read: rename corrupted file to state.json.corrupt.{timestamp}, log warning, return null (triggers heuristic fallback on resume)." Heuristic fallback is confirmed as the failure mode for corrupted state.
- `core/state-manager.md` Concurrent Access: "last-write-wins (acceptable — human should not run the same ticket twice)." No locking mechanism — concurrent crash scenarios leave undefined state.

**Confidence:** HIGH — the state manager is well-documented and the consistency model is explicitly specified. The limits are clearly stated in the source: state loss is non-fatal by design, and heuristic fallback is the recovery path.

**Implications:** Resume after crash is best-effort, not guaranteed-consistent. The system is designed to tolerate re-execution of already-completed steps (idempotency is assumed but not enforced by the state manager). For a crashed fixer-reviewer loop, the worst case is: the loop re-runs from the start of the fixer step, consuming one additional iteration against the max. For a crashed build step, the worst case is a re-build. For a crashed publisher step, resume is safe (publisher re-runs the PR creation, which is idempotent for most trackers). The most fragile crash scenario is inside a git operation (commit or reset) — state.json would show the preceding step as `completed`, but the git state may not match. The `DECOMPOSE_PARTIAL` checkpoint in `resume-ticket.md` (reading `.claude/decomposition/{ISSUE-ID}.yaml`) provides a secondary recovery mechanism for decomposed tickets that is independent of state.json.
