# Phase 1: Research -- Verify Review Report Claims

You are researching the ceos-agents codebase to verify 12 specific claims made in an external review report. The report was written about v6.3.3; the current version is v6.4.1.

## Your Task

For EACH of the 12 recommendations (D1-D12), verify whether the described problem actually exists in the current code. Do NOT trust the report -- verify everything by reading actual files.

## Research Protocol

For each recommendation, produce:
1. **Claim** -- what the report says
2. **Evidence** -- what you found in the code (with file paths and line references)
3. **Verdict** -- CONFIRMED / PARTIALLY_CONFIRMED / REFUTED / OUTDATED (fixed since v6.3.3)

## Recommendations to Verify

### D1: Context Management
**Claim:** No mechanism for context summarization/budgeting. Each agent gets context of all previous steps, causing quality degradation in late pipeline stages.
**Where to look:**
- `skills/fix-ticket/SKILL.md` -- how context is passed between steps
- `skills/fix-bugs/SKILL.md` -- same
- `skills/implement-feature/SKILL.md` -- same
- `core/fixer-reviewer-loop.md` -- what context fixer/reviewer receive
- Check whether agents run as separate Task tool invocations (which provides inherent context isolation)
- Search for "context-budget", "summariz", "compress" in Automation Config sections

**Critical question:** Does each agent truly receive the full history of all previous agents, or does each Task invocation start fresh with only specific context passed by the orchestrating skill?

### D2: Prompt Injection Protection
**Claim:** Agents read external content (issue descriptions, code comments) without any sanitization. No `[EXTERNAL INPUT]` tagging or detection mechanism.
**Where to look:**
- `core/config-reader.md` -- any sanitization instructions
- `agents/triage-analyst.md` -- how it reads issue content
- `agents/code-analyst.md` -- how it reads code
- All skill files -- any mention of input sanitization
- Search for "sanitiz", "EXTERNAL", "injection" across the codebase

### D3: Structured Agent Output
**Claim:** No schema-validated JSON outputs. Agents produce free-text markdown. No output-validator core module.
**Where to look:**
- All 19 agent files -- check output format sections
- `core/` directory -- any output-validator module
- `skills/` -- how downstream steps parse upstream agent output
- Key question: are outputs structured markdown (with consistent headings/format) or truly free-form?

### D4: Reviewer Instruction Differentiation
**Claim:** Reviewer and fixer share similar perspective (both "senior developer" with Opus). Same model, same blind spots.
**Where to look:**
- `agents/fixer.md` -- role description, perspective, constraints
- `agents/reviewer.md` -- role description, perspective, constraints
- Compare: do they have genuinely different instruction sets?
- Check reviewer's adversarial stance, security focus, edge case analysis

### D5: Graduated Escalation
**Claim:** Binary block/success model. No NEEDS_CLARIFICATION state. Agent cannot ask clarifying questions.
**Where to look:**
- `agents/fixer.md` -- NEEDS_DECOMPOSITION output (is this a third state?)
- `core/block-handler.md` -- only BLOCK handling?
- All agent output sections -- any "needs clarification" or "ask user" mechanism
- `skills/fix-ticket/SKILL.md` -- any user interaction points during pipeline
- `skills/implement-feature/SKILL.md` -- user confirmation steps

### D6: Cost Guardrails
**Claim:** No hard cost ceiling. Runaway pipeline has no automatic stop.
**Where to look:**
- `skills/estimate/SKILL.md` -- pre-run only?
- `core/state-manager.md` -- any cost tracking fields
- `state/schema.md` -- any cost/token fields
- Automation Config contract in CLAUDE.md -- any cost-related config key
- Search for "cost", "limit", "ceiling", "budget" in config sections

### D7: Flaky Test Detection
**Claim:** No handling for flaky/unstable tests. Pipeline blocks on any test failure.
**Where to look:**
- `agents/test-engineer.md` -- retry logic, flakiness detection
- `core/fixer-reviewer-loop.md` -- test handling
- `skills/fix-ticket/SKILL.md` steps 7a, 8 -- test execution flow
- Test-engineer constraints about flaky tests (does it prevent writing flaky tests or detect existing ones?)

### D8: Plugin Self-Tests in CI
**Claim:** No way to automatically detect regression in agent definitions.
**Where to look:**
- `.gitea/workflows/test.yaml` -- does it run?
- `tests/harness/run-tests.sh` -- test runner
- `tests/scenarios/` -- count and nature of test scenarios
- Memory note: "Gitea Actions runner not configured -- all CI jobs cancelled at 0s"

### D9: Context Summarization Agent
**Claim:** Need a Haiku summarizer between pipeline phases.
**Where to look:**
- Verify D1 findings first -- if context is already isolated per Task, this may be unnecessary
- Check if any existing mechanism compresses context

### D10: Observability Hooks
**Claim:** Dashboard is post-hoc only. No real-time pipeline metrics. No structured event payload in notifications.
**Where to look:**
- `skills/dashboard/SKILL.md` -- is it truly post-hoc only?
- `skills/metrics/SKILL.md` -- real-time or post-hoc?
- `core/post-publish-hook.md` -- webhook payload structure
- `core/block-handler.md` -- webhook payload structure
- Notifications config -- what events are supported?

### D11: Multi-Reviewer Pattern
**Claim:** For complex tickets, need two reviewers with different perspectives (security + correctness).
**Where to look:**
- `agents/reviewer.md` -- does it already cover security?
- `examples/custom-agents/security-analyst.md` -- is this an existing pattern?
- Custom Agents config -- could post-fix agent serve as second reviewer?

### D12: Agent Versioning
**Claim:** No version field in agent frontmatter. Resume may be unstable across agent definition changes.
**Where to look:**
- Any agent frontmatter -- check for version field
- `skills/resume-ticket/SKILL.md` -- version compatibility check
- `state/schema.md` -- any agent version tracking

## Output Format

For each D1-D12, produce a structured finding block:

```
### D{N}: {Title}
- **Claim accuracy:** CONFIRMED / PARTIALLY_CONFIRMED / REFUTED / OUTDATED
- **Evidence:** {file paths and specific content found}
- **Nuance:** {what the report got right, what it got wrong, what it missed}
- **Current state in v6.4.1:** {any changes since v6.3.3 that affect this}
```
