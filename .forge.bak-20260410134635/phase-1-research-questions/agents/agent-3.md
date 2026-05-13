# Agent 3: Research Findings — D9, D10, D11, D12

## D9: Context Summarization Agent

### D9: Context Summarization Agent
- **Claim accuracy:** REFUTED
- **Evidence:**
  - `skills/fix-ticket/SKILL.md` and `skills/implement-feature/SKILL.md`: Each pipeline phase dispatches agents via the Task tool (e.g., `Run ceos-agents:triage-analyst (Task tool, model: sonnet)`). Each Task invocation is a **separate sub-agent call** with explicitly constructed context — not an inherited full conversation thread.
  - Context passed to each agent is narrow and explicit. Example from fix-ticket step 3: `Context: "Type = {Type from config}. Use the MCP server for {Type}."` — just the type string. Example from step 4: `Context: "Root cause iterations = {N}. Module Docs path = {path}."`. From step 5 (fixer): `Context: "Max build retries = {N}. Block Comment Template: {template}. Acceptance criteria: {AC from triage}."`.
  - Context accumulation across phases is controlled: each agent receives only what the orchestrating skill explicitly passes (IDs, AC lists, diffs, config values). There is no "full conversation inheritance" between Task invocations.
  - `state/schema.md`: The state file (`state.json`) and `pipeline.log` persist structured data between phases so agents do not need to re-derive it from a conversation thread.
  - `docs/plans/v3.1-scalability-assessment.md` (lines 67-82): Explicit analysis notes total plugin overhead is ~33k tokens, with per-interaction overhead of ~3k-6k tokens, both well within the 200k context window.
- **Nuance:** The report assumes agents inherit conversation context and that a summarizer would compress inter-phase context bloat. This is architecturally incorrect — agents run as isolated Task tool invocations with surgically constructed, minimal context strings. A Haiku summarizer agent would add overhead (an extra Task invocation per phase transition) with no benefit, since context is already minimal by design. The only case where context accumulates is the fixer↔reviewer loop (multiple iterations within a single orchestration session), but that is bounded by `max_iterations` (default: 5) and the explicit 100-line diff limit on fixer output. No evidence of context pressure warranting a dedicated summarizer agent.

---

## D10: Observability Hooks

### D10: Observability Hooks
- **Claim accuracy:** PARTIALLY_CONFIRMED
- **Evidence:**
  1. **Dashboard is post-hoc:** `skills/dashboard/SKILL.md` confirms this. It reads data from the issue tracker and git after the fact (Step 1: "Fetch all issues matching Bug query"; Step 2: "Parse [ceos-agents] comments"). No live pipeline connection. The design doc `docs/plans/2026-02-27-03-dashboard-v3.2.md` (lines 1005-1008) explicitly lists what Level 2 (real-time) would need: "Event emitting from commands (JSONL stream), Background server process, SSE/WebSocket communication, In-memory state management" — confirming these are NOT present in v1.
  2. **Metrics are post-hoc:** `skills/metrics/SKILL.md` reads from the issue tracker and git log after the fact (Step 1: "Fetch all issues via MCP server"; Step 3: "`git log --oneline --since=...` via Bash").
  3. **Webhook payload structure:** `core/post-publish-hook.md` (lines 18-23): `{"event":"pr-created","issue_id":"${issue_id}","pr_url":"${pr_url}","timestamp":"${ISO8601}"}`. `core/block-handler.md` (line 38): `{"event":"issue-blocked","issue_id":"{issue_id}","agent":"{agent_name}","reason":"{reason}","timestamp":"{ISO8601}"}`. The payloads are minimal and event-specific: `pr-created` has 4 fields, `issue-blocked` has 5 fields. They are JSON-structured but carry limited data.
  4. **pipeline.log exists:** `state/schema.md` (lines 276-308): `pipeline.log` is an append-only JSONL file written during pipeline execution with typed events: `pipeline_start`, `phase_start`, `phase_complete`, `fixer_iteration`, `block`, `pipeline_complete`. Each event has timestamps and phase/agent data. This IS a structured, machine-readable event log written in real-time during execution.
  5. **status skill:** `skills/status/SKILL.md` provides live issue state from the tracker but only at the issue/PR level (not intra-pipeline stage granularity). It reads from the tracker and git on demand.
  6. **CLAUDE.md Notifications section:** Only two keys: `Webhook URL` and `On events`. Events are limited to `pr-created` and `issue-blocked` — no granular phase-level events.
- **Nuance:** The report's claim that "dashboard is post-hoc" and "no real-time pipeline metrics" is CONFIRMED for `/dashboard` and `/metrics`. However, the claim that "notification payload is not structured" is PARTIALLY WRONG — the payloads ARE structured JSON (confirmed by reading the actual curl commands in `core/post-publish-hook.md` and `core/block-handler.md`). The real gap is that payloads are minimal (only 4-5 fields each) and only two events are supported (`pr-created`, `issue-blocked`), missing phase-level granularity. Critically, the `pipeline.log` JSONL file (written per-run to `.ceos-agents/{ISSUE-ID}/pipeline.log`) IS a real-time structured event stream — but it is local only, not accessible externally without file tailing. It is not exposed via webhook.

---

## D11: Multi-Reviewer Pattern

### D11: Multi-Reviewer Pattern
- **Claim accuracy:** PARTIALLY_CONFIRMED
- **Evidence:**
  1. **Reviewer already covers security:** `agents/reviewer.md` (lines 34-35): The review checklist explicitly includes "**Security:** Any new vulnerabilities? Check for: injection (SQL, command, XSS), auth bypass, information leakage, insecure defaults" and "**Performance:** Could this introduce performance regression?". Security is a built-in checklist item, not an afterthought.
  2. **security-analyst custom agent example exists:** `examples/custom-agents/security-analyst.md` — a fully defined example of a dedicated security scanning agent (OWASP Top 10, model: sonnet). This can be plugged in via the `Custom Agents → Post-fix agent` config key.
  3. **Custom Agents extensibility:** `CLAUDE.md` config contract: "Custom Agents | Post-fix agent, Pre-publish agent". `skills/fix-ticket/SKILL.md` steps 6b and 8e show custom agents can be inserted at two points in the pipeline. `skills/implement-feature/SKILL.md` steps 6c and 8 show the same. These are one-shot gates, not loop participants.
  4. **fixer-reviewer-loop.md:** `core/fixer-reviewer-loop.md` shows a single reviewer dispatched per iteration. There is no multi-reviewer orchestration built into the loop. Multiple reviewer agents cannot participate in the same loop.
  5. **Agent Overrides:** `CLAUDE.md` — "Agent Overrides" section allows project-specific instructions appended to any agent. A project could add security-focused instructions to `customization/reviewer.md` to make the reviewer apply a security lens on every review.
- **Nuance:** The report's claim is PARTIALLY_CONFIRMED. A second dedicated reviewer is not natively supported — the fixer-reviewer loop runs a single reviewer (opus). However, the recommendation is already largely addressable via existing mechanisms: (a) the reviewer already includes security in its built-in checklist, (b) a security-analyst custom agent example already exists in `examples/custom-agents/`, (c) Agent Overrides can strengthen the reviewer's security lens project-specifically, and (d) a custom post-fix or pre-publish agent can act as a second gate. What does NOT exist is a way to have two full reviewers participate interactively in the fixer↔reviewer loop with separate perspectives — that would require architectural changes to `core/fixer-reviewer-loop.md`.

---

## D12: Agent Versioning

### D12: Agent Versioning
- **Claim accuracy:** CONFIRMED
- **Evidence:**
  1. **No version field in agent frontmatter:** Confirmed by reading multiple agents. All frontmatter contains only: `name`, `description`, `model`, `style`. Example from `agents/fixer.md`: `name: fixer`, `description: ...`, `model: opus`, `style: Pragmatic, minimal, surgical`. Example from `agents/reviewer.md`: same 4-field pattern. `CLAUDE.md` documents the agent format: "Every agent file follows this exact structure: name, description, model, style" — no `version` field.
  2. **resume-ticket has no version compatibility check:** `skills/resume-ticket/SKILL.md` — resume logic uses state.json step statuses and heuristic detection (branch presence, comments, git state). There is no agent version comparison, no check for agent definition changes between runs, and no schema version compatibility gate. The only versioning field is `"schema_version": "1.0"` in state.json (tracking state file format, not agent definitions).
  3. **state/schema.md — no agent version tracking:** The full schema (`state/schema.md` lines 30-133) contains no agent version fields. `config.profile` and `config.flags` are stored, but not agent definition hashes/versions.
  4. **core/state-manager.md:** No agent version tracking mechanism. `schema_version: "1.0"` in state.json tracks the state file schema, not agent definitions.
- **Nuance:** The claim is fully CONFIRMED. Agent frontmatter has no `version` field, and resume logic does not check whether agent definitions changed between an initial run and a resume attempt. In practice this is a real gap: if an agent's behavior contract changes (e.g., reviewer output format) between when a pipeline was blocked and when it is resumed, the resume logic has no way to detect this incompatibility. The report correctly identifies this. However, the practical impact is mitigated by the fact that this is a pure-markdown plugin — users update agent definitions by updating the plugin version, and the global plugin version IS tracked in `plugin.json`. The gap is that `state.json` does not record which plugin version initiated the run, making cross-version resume technically undetected.
