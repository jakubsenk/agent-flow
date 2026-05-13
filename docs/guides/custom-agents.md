# Custom Agents

ceos-agents supports custom agents that extend the pipeline at two integration points: after the fixer (post-fix) and before the publisher (pre-publish). Custom agents follow the same definition format as built-in agents and can block the pipeline if they detect issues.

This guide walks you through creating, testing, and integrating a custom agent.

## Agent Definition Format

Every agent (built-in or custom) is a markdown file with YAML frontmatter and a structured body:

```markdown
---
name: my-custom-agent
description: One-line description shown in Claude Code's agent picker
model: sonnet
---

You are a [Role] specializing in [domain].

## Goal

What this agent accomplishes in one sentence.

## Expertise

List of skills and knowledge areas.

## Process

1. First step — what to do
2. Second step — what to do
3. ...

## Constraints

- NEVER do X
- Max Y items
- On failure: BLOCK with reason
```

**Frontmatter fields:**

| Field | Required | Values | Purpose |
|-------|----------|--------|---------|
| name | Yes | lowercase-with-hyphens | Unique identifier |
| description | Yes | One line | Shown in Claude Code's agent picker |
| model | Yes | `sonnet`, `opus`, `haiku` | Which model runs this agent |

**Body sections (in order):**

| Section | Purpose |
|---------|---------|
| Goal | Single sentence describing the agent's objective |
| Expertise | Skills and knowledge areas the agent should demonstrate |
| Process | Numbered, actionable steps the agent follows |
| Constraints | Hard limits, NEVER rules, and failure handling |

## Read-Only vs Execution Agents

The distinction between read-only and execution agents is critical for pipeline safety:

**Read-only agents** analyze data and produce reports. They NEVER modify code, create files, or interact with git. Built-in read-only agents: analyst-impact, reviewer, spec-analyst, architect, priority-engine.

**Execution agents** modify code, create files, or interact with external systems. Built-in execution agents: fixer, test-engineer, browser-agent, publisher, scaffolder, rollback-agent.

Custom agents should clearly state their type in the Constraints section. A read-only custom agent (e.g., security scanner) should include `NEVER modify code` in its constraints. An execution custom agent (e.g., documentation generator) should specify exactly what it is allowed to modify.

## Integration Points

Custom agents can be inserted at two points in the pipeline:

### Post-fix Agent

Runs **after** the fixer produces a successful build and **after** the post-fix hook (if configured), but **before** the reviewer. Use cases:

- Security scanning (check for hardcoded secrets, vulnerable patterns)
- Compliance checks (license headers, coding standards)
- Custom linting beyond what the build command covers

### Pre-publish Agent

Runs **after** all tests pass and **after** the pre-publish hook (if configured), but **before** the publisher creates a PR. Use cases:

- Documentation generation (update API docs from code changes)
- Changelog validation (ensure changelog entry exists)
- Release notes preparation

### Configuration

Add custom agents to the Custom Agents section of your Automation Config:

```markdown
### Custom Agents

| Key | Value |
|-----|-------|
| Post-fix agent | `.claude/agents/security-scanner.md` |
| Pre-publish agent | `.claude/agents/changelog-validator.md` |
```

The path is relative to the project root. The agent file must follow the standard agent definition format.

## Writing Your First Custom Agent

Here is a step-by-step walkthrough for creating a security scanner agent:

**Step 1: Create the agent file.**

Create `.claude/agents/security-scanner.md` in your project (not in the plugin repository).

**Step 2: Define the frontmatter.**

```yaml
---
name: security-scanner
description: Scans code changes for hardcoded secrets and security vulnerabilities
model: sonnet
---
```

Choose `sonnet` for analysis tasks. Use `opus` only if the agent needs to make complex judgment calls. Use `haiku` only for mechanical tasks.

**Step 3: Write the agent body.**

Define the role, goal, expertise, process, and constraints. The process steps should be specific and actionable. Constraints should define when to BLOCK.

**Step 4: Configure the integration point.**

Add the agent to your Automation Config (see Configuration section above).

**Step 5: Test the agent.**

See the Testing section below.

## Testing Custom Agents

Before integrating a custom agent into the pipeline, test it in isolation:

1. **Run via Task tool directly.** In Claude Code, use the Task tool to dispatch your agent with sample context. Verify the output format matches your expectations.

2. **Verify the output structure.** Ensure the agent produces a clear verdict (PASS or BLOCK) and a structured report. The pipeline skill will parse the output to decide whether to continue or trigger the block handler.

3. **Test the BLOCK path.** Feed the agent input that should trigger a BLOCK and verify it produces the correct Block Comment Template format:

```
[ceos-agents] Pipeline Block
Agent: security-scanner
Step: post-fix
Reason: Hardcoded API key detected in config file
Detail: src/config.ts:15 contains string matching AWS access key pattern (AKIA...)
Recommendation: Move the API key to environment variables and use .env file
```

4. **Test with real pipeline context.** Run `/ceos-agents:fix-bugs` on a test issue with the custom agent configured. Verify it runs at the correct point in the pipeline.

## Example: Security Scanner Agent

Here is a complete custom agent that scans for hardcoded secrets:

```markdown
---
name: security-scanner
description: Scans code changes for hardcoded secrets and security vulnerabilities
model: sonnet
---

You are a Security Analyst specializing in secret detection and secure coding practices.

## Goal

Scan code changes produced by the fixer agent for hardcoded secrets, credentials, and common security vulnerabilities.

## Expertise

Secret detection patterns (API keys, tokens, passwords, private keys), OWASP Top 10, secure coding practices, common vulnerability patterns in web applications.

## Process

1. Read the fixer output to identify all changed files.
2. For each changed file, scan for:
   - Hardcoded API keys (AWS, GCP, Azure, Stripe, etc.)
   - Hardcoded passwords or tokens
   - Private keys or certificates
   - Connection strings with embedded credentials
   - Insecure cryptographic patterns (MD5, SHA1 for passwords)
   - SQL injection vulnerabilities in new code
3. Check if a .env.example file exists and whether new environment-dependent values should be added to it.
4. Produce a security scan report:
   - List all findings with severity (CRITICAL, HIGH, MEDIUM, LOW)
   - For each finding: file, line, pattern matched, recommendation
   - Overall verdict: PASS (no CRITICAL/HIGH findings) or BLOCK (any CRITICAL/HIGH finding)
5. If BLOCK: format the output using the Block Comment Template.

## Constraints

- NEVER modify code — this is a read-only scanning agent
- BLOCK only on CRITICAL or HIGH severity findings
- MEDIUM and LOW findings are reported as warnings but do not block
- Max scan scope: only files changed by the fixer (do not scan the entire codebase)
- If no changed files are found, report PASS with a note
```

To use this agent, add it to your Automation Config:

```markdown
### Custom Agents

| Key | Value |
|-----|-------|
| Post-fix agent | `.claude/agents/security-scanner.md` |
```

For more custom agent examples, see the `examples/custom-agents/` directory in the plugin repository, which includes agents for compliance checking, dependency analysis, and migration review.

## Constraints and Best Practices

- **Custom agents receive pipeline context.** The skill passes issue details, fixer output, and previous agent results as context when dispatching your agent.
- **A BLOCK from a custom agent stops the pipeline for that issue.** The block handler runs rollback-agent and posts a block comment. Use BLOCK judiciously — only for issues that genuinely cannot proceed.
- **Follow the namespace convention.** If you are publishing your custom agent for others to use, prefix the name with your namespace (e.g., `my-org:security-scanner`).
- **Keep agents focused on a single responsibility.** A security scanner should not also check code style. Split responsibilities into separate agents if needed.
- **Use the appropriate model tier.** Most custom agents should use `sonnet` for analysis or `haiku` for mechanical tasks. Reserve `opus` for agents that need to make complex quality judgments.
- **Document the BLOCK criteria.** In the Constraints section, clearly define what triggers a BLOCK vs a warning. This makes the agent's behavior predictable and debuggable.
