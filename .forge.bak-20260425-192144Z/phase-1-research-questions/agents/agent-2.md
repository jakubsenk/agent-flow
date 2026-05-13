# Phase 1 Research Questions — Track 2: Agent Dispatch Enforcement (Agent 2)

## Scope

Track 2 only: Agent Dispatch Enforcement (Layers 1 + 2 + 4) as defined in `docs/plans/roadmap.md` §"Agent Dispatch Enforcement → v6.10.0".

---

## Critical-Path Questions (Q1–Q8)

**Q1** [CRITICAL-PATH]
What is the complete enumeration of permissive dispatch prose lines (of the form `Run ceos-agents:{name} (Task tool, model: {model})`) across all in-scope pipeline skills — `fix-ticket`, `fix-bugs`, `implement-feature`, `scaffold` — and the core loop contract `fixer-reviewer-loop.md`? How many distinct dispatch sites exist, and which agents appear at each site?

Answer location: `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md`, `core/fixer-reviewer-loop.md` — grep for `Task tool, model:`.

---

**Q2** [CRITICAL-PATH]
What is the exact target imperative replacement form prescribed by the roadmap for Layer 1 prose rewrites? Does the roadmap prescribe a single canonical template string, or is it only an illustrative example? Specifically: does the prescribed form include `subagent_type=`, `model=`, the CONTRACT VIOLATION warning phrase, and the `DO NOT inline-execute` prohibition in a single fixed sentence?

Answer location: `docs/plans/roadmap.md` §"Agent Dispatch Enforcement → v6.10.0", Layer 1 bullet.

---

**Q3** [CRITICAL-PATH]
For Layer 2 (per-skill dispatch checklists): the roadmap's Layer 2 description says "PostToolUse hook + validate-dispatch.sh script" is Layer 2 — but the roadmap text labels the hook as Layer 2 and per-skill dispatch checklists as Layer 2 in the same numbering. Is Layer 2 in v6.10.0 scope the PostToolUse hook contract (validate-dispatch.sh), or per-skill pre-dispatch checklists, or both? What is the precise layer-2 deliverable boundary in the roadmap?

Answer location: `docs/plans/roadmap.md` §"Agent Dispatch Enforcement → v6.10.0", Layers 1–4 list and "Recommended v6.10.0 scope" line.

---

**Q4** [CRITICAL-PATH]
Where does `validate-dispatch.sh` live in the plugin repository layout? The roadmap describes it as a `~/.claude/settings.json` PostToolUse hook — but the plugin is pure markdown with no shell scripts in the distributed package. Does the script ship inside the plugin (e.g., `hooks/validate-dispatch.sh`), or is it documented as an operator-generated artifact (e.g., produced by `/ceos-agents:init` or `check-setup`)? No such file or `hooks/` directory currently exists — confirm by checking the full repo layout.

Answer location: `docs/plans/roadmap.md` Layer 2 bullet; `skills/init/SKILL.md` (what it generates); top-level directory listing.

---

**Q5** [CRITICAL-PATH]
The roadmap states the PostToolUse hook "reads `.ceos-agents/state.json`, asserts each expected stage has `tokens_used > 100`." Given that `state.json` uses per-stage `tokens_used` fields (e.g., `triage.tokens_used`, `code_analysis.tokens_used`, `fixer_reviewer.tokens_used`) as defined in `state/schema.md`, which specific stage keys does the validator need to assert on for a `fix-ticket` run, and what is the minimum `tokens_used` threshold that distinguishes a real Task dispatch from a zero-cost inline simulation? Is `> 100` the canonical threshold, or only illustrative in the roadmap?

Answer location: `state/schema.md` §"Per-stage usage fields"; `docs/plans/roadmap.md` Layer 2 bullet; `skills/fix-ticket/SKILL.md` pre-dispatch writes (COST-R4).

---

**Q6** [CRITICAL-PATH]
On violation detection, the roadmap says the hook should "emit `[FATAL] Skill orchestration violation: $stage did not dispatch agent` and halt." What is the exact halt mechanism in the Claude Code PostToolUse hook API? Does the hook returning a non-zero exit code halt the parent skill, or does it only log? Is there a documented Claude Code PostToolUse hook failure-mode spec (halt vs warn vs log-only) anywhere in the repo's existing docs or brainstorm files?

Answer location: `docs/plans/roadmap.md` Layer 2 bullet; `docs/plans/brainstorm/06-session-resume-permissions.md` (settings.json hook context); `docs/guides/troubleshooting.md` (settings.json setup).

---

**Q7** [CRITICAL-PATH]
The roadmap requires a functional dispatch enforcement test (`tests/scenarios/v6.10.0-skill-dispatch-enforcement.sh`) that "asserts: each stage has nonzero distinct `tokens_used`, sequential timestamps (not parallel-parent-context), distinct models per stage." The existing `pipeline-agent-dispatch-models.sh` already does doc-grep model verification but is NOT a functional behavioral test. What exact jq + bash idiom from `v6.9.0-needs-clarification-e2e.sh` should the new scenario reuse for synthetic state.json construction and `tokens_used > 0` assertions? Specifically: does the new scenario need a mock state.json with pre-populated stage records, or does it invoke a real subprocess dispatch and then read the output?

Answer location: `tests/scenarios/v6.9.0-needs-clarification-e2e.sh` (functional jq pattern); `tests/scenarios/pipeline-agent-dispatch-models.sh` (existing doc-grep baseline — NOT to duplicate); `state/schema.md` (stage field names).

---

**Q8** [CRITICAL-PATH]
Does the v6.9.2 Autopilot Bash subprocess dispatch pattern (`claude -p "Run ${TARGET_SKILL} ${ISSUE_ID}" --dangerously-skip-permissions`) in `skills/autopilot/SKILL.md` Step 6 represent a COMPLIANT dispatch pattern that Layer 1 rewrites MUST NOT break? Specifically: since pipeline skills (`fix-ticket`, `implement-feature`) have `disable-model-invocation: true`, the Task tool path is blocked for them — but all other agents dispatched by those skills (fixer, reviewer, triage-analyst, etc.) do NOT have `disable-model-invocation: true`. Does Layer 1 prose rewrite apply only to skills that dispatch other pipeline skills, or to all 21 agents dispatched via Task tool inside fix-ticket/fix-bugs/implement-feature/scaffold?

Answer location: `skills/autopilot/SKILL.md` §Step 6 dispatch rationale; `skills/fix-ticket/SKILL.md` frontmatter; `agents/fixer.md` frontmatter (check for `disable-model-invocation`).

---

## Clarification-Tier Questions (Q9–Q13)

**Q9** [CLARIFICATION]
The roadmap installation option for the PostToolUse hook is `~/.claude/settings.json` (operator global). Is there an existing mechanism in `/ceos-agents:init` or `/ceos-agents:check-setup` that generates or validates `~/.claude/settings.json` entries, or would the hook installation be a net-new documentation step? Confirm by reading what `skills/init/SKILL.md` currently writes to settings.json.

Answer location: `skills/init/SKILL.md`; `skills/check-setup/SKILL.md`; `docs/guides/troubleshooting.md` §"Configure permanent permissions".

---

**Q10** [CLARIFICATION]
Layer 3 (pre-flight subagent_type assertion at Step 0a of pipeline skills) is explicitly excluded from v6.10.0 scope per the roadmap. Is there any existing Step 0a or 0b in `fix-ticket` or `implement-feature` that would be confused with a Layer 3 implementation? Specifically, does the existing Step 0b (Config Validity Gate) in `fix-ticket/SKILL.md` already serve any dispatch-validation role that would need to be preserved unchanged?

Answer location: `skills/fix-ticket/SKILL.md` Steps 0, 0a–0c; `skills/implement-feature/SKILL.md` Steps 0–0c.

---

**Q11** [CLARIFICATION]
The existing test `tests/scenarios/pipeline-agent-dispatch-models.sh` is a doc-grep scenario that verifies model assignments for all 21 agents across 5 pipeline skills. It uses `grep "Task tool, model:"` to find dispatch lines. If Layer 1 rewrites change the prose from `Run ceos-agents:triage-analyst (Task tool, model: sonnet)` to the new imperative form (e.g., `You MUST invoke Task(subagent_type='ceos-agents:triage-analyst', model='sonnet')`), does `pipeline-agent-dispatch-models.sh` break? What is the exact grep pattern it uses that would need updating?

Answer location: `tests/scenarios/pipeline-agent-dispatch-models.sh` lines 42–44 (grep pattern); `docs/plans/roadmap.md` Layer 1 replacement form.

---

**Q12** [CLARIFICATION]
The roadmap Layer 4 functional test description says "runs synthetic skill against mock issue." Does "synthetic skill" mean (a) a minimal in-test bash script that mimics the state.json write pattern of fix-ticket, or (b) an actual invocation of `fix-ticket` with `--dry-run` against a mock tracker, or (c) just a hand-crafted state.json that is inspected by jq assertions? The distinction matters because options (b) and (c) have fundamentally different test complexity and execution time.

Answer location: `docs/plans/roadmap.md` Layer 4 bullet; `tests/scenarios/v6.9.0-needs-clarification-e2e.sh` (established pattern precedent for "synthetic" state.json construction).

---

**Q13** [CLARIFICATION]
Does adding Layer 1 prose rewrites (imperative `You MUST invoke Task(...)` vs current `Run ... (Task tool, ...)`) constitute a breaking change to the agent output format contract per the versioning policy in `CLAUDE.md`? Specifically: the prose is inside SKILL.md files (orchestration instructions to Claude, not agent output), so it does not touch any section of the agent output format contract. Confirm by checking the versioning policy MAJOR trigger definition.

Answer location: `CLAUDE.md` §"Versioning Policy" (MAJOR trigger: "breaking change in agent output format contract"); `docs/plans/roadmap.md` Layer 1 description (SKILL.md files only, not agents/ files).
