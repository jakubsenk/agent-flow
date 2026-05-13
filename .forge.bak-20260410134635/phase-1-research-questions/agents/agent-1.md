# Agent 1: Design Pattern Claims Verification

Verified against codebase at v6.4.1 (claim was written about v6.3.3).

---

### D1: Context Management
- **Claim accuracy:** PARTIALLY_CONFIRMED
- **Evidence:**
  - `skills/fix-ticket/SKILL.md` lines 129–579: Every agent is dispatched via `Task tool`. The `Context:` field for each invocation is **explicitly defined** and minimal:
    - triage-analyst gets: `Type = {Type from config}. Use the MCP server for {Type}.`
    - code-analyst gets: `Root cause iterations = {Root cause iterations from config}. Module Docs path = {...}.`
    - fixer gets: `Max build retries = {Build retries}. Block Comment Template. Acceptance criteria: {AC from triage}.`
    - reviewer gets: `Max fixer iterations = {Fixer iterations}. Acceptance criteria: {AC from triage}.`
    - test-engineer gets: `Max test attempts = {Test attempts from config}.`
    - publisher gets: `Type = {Type from config}. Extra labels: {Labels}.`
  - `core/fixer-reviewer-loop.md` lines 2–10: Fixer receives `context + any previous reviewer feedback`. Reviewer receives `fixer's changes + AC list`. Reviewer critique is passed back to fixer as `additional context` in the loop (line 9).
  - No `core/output-validator.md`, no context budgeting, no summarization module exists in the `core/` directory (`core/` contains: agent-override-injector, block-handler, config-reader, decomposition-heuristics, fix-verification, fixer-reviewer-loop, mcp-detection, mcp-preflight, post-publish-hook, profile-parser, state-manager).
  - `agents/reproducer.md` line 123: Evidence bundle truncated to 15000 characters — the only explicit truncation rule found.
  - `agents/scaffolder.md` line 25: "Generate project files in batches (to manage token limits)" — one token-aware pattern.
- **Nuance:** The report's claim is **partially wrong in its framing**. The Task tool creates isolated sub-agent invocations — each agent does NOT receive the full accumulated conversation history of the parent skill session. Each Task invocation is a separate context. However, the claim has merit in a narrower sense: within the fixer-reviewer loop (`core/fixer-reviewer-loop.md` line 9), reviewer critique IS passed back to the fixer as `additional context`, meaning fixer context grows across iterations. There is no explicit mechanism for summarizing or compressing that growing iteration context. There is also no `context-budget`, `summariz`, or `compress` pattern anywhere in the codebase. The claim overstates the problem (agents don't get ALL previous output — they get specific curated excerpts) but correctly identifies the absence of a context budgeting or summarization module.

---

### D2: Prompt Injection Protection
- **Claim accuracy:** CONFIRMED
- **Evidence:**
  - Full search across all files for `sanitiz`, `EXTERNAL`, `injection`, `untrusted`, `input.valid` returned zero hits in agent definitions or core modules. All matches were either: CHANGELOG shell-injection fix for webhooks, reviewer checklist items about output code injection (SQL/XSS in the *user's* codebase), or plan documents.
  - `core/config-reader.md`: No sanitization instructions. Only parses CLAUDE.md structure.
  - `agents/triage-analyst.md` step 1: "Read bug details from issue tracker (summary, description, comments, custom fields)" — raw issue content is read and passed directly to analysis with no sanitization or tagging.
  - `agents/triage-analyst.md` step 9: Triage output includes raw reproduction steps from the issue tracker, passed verbatim into downstream agent contexts.
  - `skills/fix-ticket/SKILL.md` line 431: Reproducer context includes `{issue description}` and `{full triage output}` — both sourced directly from the issue tracker without sanitization markers.
  - No `[EXTERNAL INPUT]` tags, no input validation layer, no sandboxing instructions appear anywhere in agents or core modules.
- **Nuance:** The report is fully correct. External content (issue descriptions, code comments) is read by agents and incorporated into context without any sanitization, tagging, or validation step. This is a genuine gap. The reviewer agent does check for injection vulnerabilities *in the code being reviewed* (reviewer.md line 34), but there is no protection against prompt injection *in the pipeline inputs themselves*.

---

### D3: Structured Agent Output
- **Claim accuracy:** PARTIALLY_CONFIRMED
- **Evidence:**
  - Agent output formats (from actual agent files):
    - `agents/triage-analyst.md` lines 74–86: Fixed markdown template with named sections (`## Triage Analysis`, `**Summary:**`, `**Acceptance Criteria:**`, `**Complexity:**`, `**Reproduction steps:**`).
    - `agents/code-analyst.md` lines 76–95: Fixed markdown template (`## Impact Report`, `**Root cause location:**`, `**Affected files:**`, `**Risk level:**`, `**Reproduction trace:**`, `**Sanity check:**`).
    - `agents/reviewer.md` lines 66–76: Fixed markdown template (`## Code Review`, `**Verdict:**`, `**Issues found:**`, `**AC Fulfillment:**`).
    - `agents/fixer.md` lines 54–61: Fixed markdown template (`## Fix Report`, `**Root cause:**`, `**Approach:**`, `**Build:**`, `**Tests:**`).
  - `core/` directory listing: No `output-validator.md` file exists. The 11 core modules are: agent-override-injector, block-handler, config-reader, decomposition-heuristics, fix-verification, fixer-reviewer-loop, mcp-detection, mcp-preflight, post-publish-hook, profile-parser, state-manager.
  - Machine-readable tokens DO exist: `Quality gate: PASS` / `Quality gate: UNCLEAR` (triage-analyst.md line 40-44), `APPROVE` / `REQUEST_CHANGES` / `BLOCK` (reviewer.md), `## NEEDS_DECOMPOSITION` (fixer.md line 37), `root cause confirmed: YES / NO` (code-analyst.md).
  - `core/fixer-reviewer-loop.md` line 27: Reviewer output is consumed by checking for `APPROVE` string; AC Fulfillment section is extracted by name.
- **Nuance:** The claim is partially right. There is no JSON schema validation and no `output-validator` core module. However, the claim that outputs are "truly free-form" is wrong — agents produce rigidly templated markdown with consistent required headings and machine-readable token signals. The skill orchestrators parse these tokens by string matching (e.g., checking for `APPROVE`, `UNCLEAR`, `## NEEDS_DECOMPOSITION`). This is structured output via markdown convention, not JSON schema. The gap is real (no schema enforcement, no validation layer) but the outputs are far more structured than "free-form text."

---

### D4: Reviewer Instruction Differentiation
- **Claim accuracy:** REFUTED
- **Evidence:**
  - `agents/fixer.md`:
    - Role: `Senior Developer specializing in surgical bug fixes` (line 8)
    - Style: `Pragmatic, minimal, surgical` (frontmatter)
    - Goal: "Minimal correct fix that solves the root cause. Simplest solution that doesn't break anything."
    - Process focus: root cause reasoning, red-green-refactor TDD, backwards compatibility, minimal diffs (≤100 lines)
    - Constraints: `NEVER change more than necessary`, `NEVER modify public APIs without explicit approval`, `Diff MUST NOT exceed 100 lines`
  - `agents/reviewer.md`:
    - Role: `Senior Code Reviewer acting as a quality gate` (line 8)
    - Style: `Adversarial, evidence-driven, thorough` (frontmatter)
    - Goal: "Ensure the fix addresses root cause, follows project conventions, and introduces no regressions."
    - Process focus: adversarial checklist (line 28: "You are an ADVERSARIAL reviewer. Assume problems exist and find them. Adopt a cynical stance"), mandatory minimum 3 issues per review (line 55-62), edge case analysis with systematic boundary tracing, AC fulfillment audit, explicit security checklist (injection, auth bypass, XSS, information leakage).
    - Constraints: `NEVER modify code`, `NEVER approve with zero findings unless per-checklist-item justification`, `MUST include AC Fulfillment section`.
  - The reviewer has a mandatory adversarial framing with a structured checklist that the fixer lacks entirely. The fixer is constructive/minimal; the reviewer is adversarial/skeptical. Different role personas, different constraints, different process steps, different output structure.
- **Nuance:** The claim is wrong. While both agents use `model: opus`, their perspectives are genuinely and intentionally differentiated. The reviewer explicitly adopts an adversarial stance and is instructed to assume problems exist, making it structurally distinct from the fixer's constructive role. The reviewer also has a unique security checklist, an AC fulfillment audit requirement, and a mandatory minimum issue count — none of which apply to the fixer. The "same blind spots" concern has some abstract merit (same base model may have similar trained biases) but is not supported by the actual prompt design, which creates a clear adversarial asymmetry.
