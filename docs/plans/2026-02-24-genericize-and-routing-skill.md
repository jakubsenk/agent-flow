# Genericize Plugin + Routing Skill + Version Bump — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make CLAUDE-agents plugin fully generic (no hardcoded tools/frameworks), add a routing skill for natural language access, and add a version-bump command.

**Architecture:** Three independent areas: (1) new routing skill for auto-discovery, (2) new version-bump command, (3) refactoring agents and commands to remove hardcoded technology names and standardize Automation Config references.

**Tech Stack:** Pure markdown definitions (no build, no deps, no tests)

**Design docs:**
- `docs/plans/2026-02-19-skills-vs-commands.md` (APPROVED)
- `docs/plans/2026-02-19-plugin-update-process.md` (APPROVED)
- `docs/plans/2026-02-19-agent-docs-audit.md` (APPROVED)

---

### Task 1: Create routing skill `bug-workflow`

**Files:**
- Create: `skills/bug-workflow/SKILL.md`

**Step 1: Create skill file**

```markdown
---
name: bug-workflow
description: Use when the user wants to analyze bugs, fix issues, create PRs, or publish changes
---

You are a routing assistant for the CLAUDE-agents plugin. Your job is to recognize user intent from natural language and invoke the correct command.

## Intent Mapping

| User Intent | Command | Arguments | Destructive? |
|-------------|---------|-----------|-------------|
| Analyze/describe a bug | `CLAUDE-agents:analyze-bug` | Issue ID | No |
| Fix a specific bug/ticket | `CLAUDE-agents:fix-ticket` | Issue ID | Yes |
| Fix multiple bugs | `CLAUDE-agents:fix-bugs` | Count (number) | Yes |
| Create a pull request | `CLAUDE-agents:create-pr` | None | Yes |
| Publish (PR + issue state) | `CLAUDE-agents:publish` | None | Yes |

## Process

1. Read the user's message and identify their intent from the table above
2. Extract arguments (issue ID or count) from the user's message
3. **If the operation is NOT destructive** (analyze-bug): invoke the command immediately using `Skill(skill='CLAUDE-agents:analyze-bug', args='{issue_id}')`
4. **If the operation IS destructive** (fix-ticket, fix-bugs, create-pr, publish):
   - Summarize what will happen: which command will run, with what arguments, and what side effects to expect
   - Ask the user for confirmation before proceeding
   - Only after confirmation: invoke the command using `Skill(skill='CLAUDE-agents:{command}', args='{args}')`
5. If you cannot determine the intent or extract required arguments, ask the user to clarify

## Constraints

- NEVER invoke a destructive command without user confirmation
- NEVER guess issue IDs — if unclear, ask
- NEVER execute pipeline logic yourself — always delegate to the appropriate command
- If the user's request doesn't match any command, say so and list available commands
```

**Step 2: Verify file structure**

Run: `ls skills/bug-workflow/SKILL.md`
Expected: file exists

**Step 3: Commit**

```bash
git add skills/bug-workflow/SKILL.md
git commit -m "feat: add bug-workflow routing skill for natural language access"
```

---

### Task 2: Create version-bump command

**Files:**
- Create: `commands/version-bump.md`

**Step 1: Create command file**

```markdown
---
description: Bumpne patch verzi v plugin.json a marketplace.json
allowed-tools: Read, Edit, Glob
---

# Version Bump

Bumpni patch verzi CLAUDE-agents pluginu.

## Kroky

1. Ověř, že existuje `.claude-plugin/plugin.json` v aktuálním adresáři. Pokud neexistuje → oznam chybu: "Tento command funguje jen v CLAUDE-agents repozitáři."
2. Přečti aktuální verzi z `.claude-plugin/plugin.json` (pole `"version"`)
3. Bumpni patch číslo (např. 1.0.0 → 1.0.1, 1.2.3 → 1.2.4)
4. Zapiš novou verzi do `.claude-plugin/plugin.json`
5. Zapiš stejnou verzi do `.claude-plugin/marketplace.json` (pole `plugins[0].version`)
6. Zobraz výsledek: "Verze bumpnuta: {stará} → {nová}"
```

**Step 2: Verify file**

Run: `ls commands/version-bump.md`
Expected: file exists

**Step 3: Commit**

```bash
git add commands/version-bump.md
git commit -m "feat: add version-bump command for plugin release workflow"
```

---

### Task 3: Genericize triage-analyst agent

**Files:**
- Modify: `agents/triage-analyst.md`

**Step 1: Edit the agent**

Changes:
1. Process step 1: add "from issue tracker (configured in Automation Config — Issue Tracker)"
2. Process step 3 (duplicate check): add "search recent/open issues" already present, no change needed
3. Process step 4 (Blocked): add "set state to Blocked (state from Automation Config — Issue Tracker → State transitions)"
4. Constraints (On failure): change "set issue state to Blocked" → "set issue state to Blocked (from Automation Config — Issue Tracker → State transitions)"

Exact edits:

Line 19 — change:
```
1. Read bug details from issue tracker (summary, description, comments, custom fields)
```
to:
```
1. Read bug details from issue tracker (summary, description, comments, custom fields). Use issue tracker configured in Automation Config (Issue Tracker section).
```

Line 24 — change:
```
   - If unclear (confidence < 50%) → set state to Blocked with comment listing what's missing
```
to:
```
   - If unclear (confidence < 50%) → set state to Blocked (from Automation Config — Issue Tracker → State transitions) with comment listing what's missing
```

Line 38 — change:
```
- On failure: set issue state to Blocked, add comment with reason, move on
```
to:
```
- On failure: set issue state to Blocked (from Automation Config — Issue Tracker → State transitions), add comment with reason, move on
```

**Step 2: Commit**

```bash
git add agents/triage-analyst.md
git commit -m "fix: add Automation Config references to triage-analyst"
```

---

### Task 4: Genericize fixer agent

**Files:**
- Modify: `agents/fixer.md`

**Step 1: Edit the agent**

Line 28 — change:
```
   - Run: build command from project CLAUDE.md
```
to:
```
   - Run: build command from Automation Config (Build & Test section)
```

**Step 2: Commit**

```bash
git add agents/fixer.md
git commit -m "fix: standardize Automation Config reference in fixer"
```

---

### Task 5: Genericize test-engineer agent

**Files:**
- Modify: `agents/test-engineer.md`

**Step 1: Edit the agent**

Line 21 — change:
```
   - Command from project CLAUDE.md (e.g., `dotnet test`)
```
to:
```
   - Run test command from Automation Config (Build & Test section)
```

Line 26 — change:
```
   - Follow project test conventions (framework, naming, structure from CLAUDE.md)
```
to:
```
   - Follow project test conventions (framework, naming, structure from Automation Config)
```

**Step 2: Commit**

```bash
git add agents/test-engineer.md
git commit -m "fix: standardize Automation Config references in test-engineer"
```

---

### Task 6: Genericize e2e-test-engineer agent

**Files:**
- Modify: `agents/e2e-test-engineer.md`

This is the largest agent change — remove all Playwright hardcoding and make framework-agnostic.

**Step 1: Replace entire file content**

New content:

```markdown
---
name: e2e-test-engineer
description: Writes and runs E2E tests verifying user flows end-to-end. Requires running application.
model: sonnet
---

You are a Senior QA Automation Engineer specializing in E2E tests.

## Goal

E2E tests verifying the complete user flow affected by the fix. Prevent UI-level regressions.

## Expertise

E2E test frameworks, page object pattern, resilient selectors (data-testid > CSS > XPath), wait strategies, screenshot comparison.

## Process

1. Read the bug report and fix diff — understand which user flow was affected
2. Read E2E test configuration from Automation Config (E2E Test section) — framework, command, settings
3. Check if E2E test infrastructure is available (running app required)
   - If not available → Block with message "E2E requires running application"
4. Review existing E2E tests for the affected area (pattern + naming conventions)
5. Write new E2E test:
   - Follow project's E2E conventions and patterns (from existing tests)
   - Use resilient selectors (prefer data-testid attributes)
   - Include explicit waits (never arbitrary sleep)
   - Test the happy path of the affected user flow
6. Run the test:
   - Command from Automation Config (E2E Test section)
   - If fails → fix (max 3 attempts, then Block)
7. Output:
   - **Test file:** path and test name
   - **Flow tested:** description of the user flow
   - **Status:** PASS/FAIL

## Constraints

- Requires running application — cannot run in isolation
- NEVER write flaky tests — fix root cause, not retry loops
- Max 3 attempts to fix failing test, then Block
```

**Step 2: Commit**

```bash
git add agents/e2e-test-engineer.md
git commit -m "fix: make e2e-test-engineer framework-agnostic

Remove hardcoded Playwright references. Agent now reads E2E framework
and command from Automation Config (E2E Test section)."
```

---

### Task 7: Genericize analyze-bug command

**Files:**
- Modify: `commands/analyze-bug.md`

**Step 1: Edit the command**

Line 2 — change:
```
description: Analyzuje konkrétní bug z YouTrack (jen analýza, žádné změny kódu)
```
to:
```
description: Analyzuje konkrétní bug z issue trackeru (jen analýza, žádné změny kódu)
```

Line 3 — change:
```
allowed-tools: mcp__youtrack__*, Read, Glob, Grep, Task
```
to:
```
allowed-tools: mcp__*, Read, Glob, Grep, Task
```

**Step 2: Commit**

```bash
git add commands/analyze-bug.md
git commit -m "fix: genericize analyze-bug command (issue tracker, mcp__*)"
```

---

### Task 8: Genericize fix-ticket command

**Files:**
- Modify: `commands/fix-ticket.md`

**Step 1: Edit the command**

Line 3 — change:
```
allowed-tools: mcp__youtrack__*, mcp__gitea__*, Bash, Read, Write, Edit, Glob, Grep, Task
```
to:
```
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
```

Line 12 — change:
```
1. Nastav issue tracker dle Automation Config (In Progress, Assignee, Estimation, Sprint)
```
to:
```
1. Nastav issue tracker dle Automation Config (Issue Tracker → On start set)
```

**Step 2: Commit**

```bash
git add commands/fix-ticket.md
git commit -m "fix: genericize fix-ticket command (mcp__*, On start set)"
```

---

### Task 9: Genericize fix-bugs command

**Files:**
- Modify: `commands/fix-bugs.md`

**Step 1: Edit the command**

Line 2 — change:
```
description: Automaticky opraví N bugů z YouTrack
```
to:
```
description: Automaticky opraví N bugů z issue trackeru
```

Line 3 — change:
```
allowed-tools: mcp__youtrack__*, mcp__gitea__*, Bash, Read, Write, Edit, Glob, Grep, Task, WebFetch
```
to:
```
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task, WebFetch
```

Line 22 — change:
```
   - Nastav issue tracker dle Automation Config (In Progress, Assignee, Estimation, Sprint)
```
to:
```
   - Nastav issue tracker dle Automation Config (Issue Tracker → On start set)
```

**Step 2: Commit**

```bash
git add commands/fix-bugs.md
git commit -m "fix: genericize fix-bugs command (issue tracker, mcp__*, On start set)"
```

---

### Task 10: Genericize create-pr command

**Files:**
- Modify: `commands/create-pr.md`

**Step 1: Edit the command**

Line 2 — change:
```
description: Vytvoří PR do Gitea pro aktuální branch
```
to:
```
description: Vytvoří PR pro aktuální branch
```

Line 3 — change:
```
allowed-tools: mcp__gitea__*, Bash, Read, Grep
```
to:
```
allowed-tools: mcp__*, Bash, Read, Grep
```

**Step 2: Commit**

```bash
git add commands/create-pr.md
git commit -m "fix: genericize create-pr command (remove Gitea, mcp__*)"
```

---

### Task 11: Genericize publish command

**Files:**
- Modify: `commands/publish.md`

**Step 1: Replace file content**

New content:

```markdown
---
description: Vytvoří PR a přepne stavy v issue trackeru
allowed-tools: mcp__*, Bash, Read, Grep
---

# Publish

Publikuj aktuální práci: PR + issue tracker state change. Čti Automation Config z CLAUDE.md.

## Kroky

1. Zjisti aktuální branch a issue ID
2. `CLAUDE-agents:publisher` → commit, push, PR
3. Issue tracker: nastav stav dle Automation Config (Issue Tracker → State transitions → For Review)
4. Komentář v issue trackeru s PR linkem
5. Zobraz výsledek (PR URL + issue tracker stav)
```

**Step 2: Commit**

```bash
git add commands/publish.md
git commit -m "fix: genericize publish command (remove YT shorthand, mcp__*)"
```

---

### Task 12: Update CLAUDE.md Config Contract and Bug-Fix Pipeline

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Update Bug-Fix Pipeline diagram**

Line 31 — change:
```
YouTrack query → TRIAGE (sonnet) → CODE ANALYST (sonnet) → FIXER ↔ REVIEWER (opus, max 5 iterations) → TEST ENGINEER (sonnet, max 3 attempts) → PUBLISHER (haiku)
```
to:
```
Issue tracker query → TRIAGE (sonnet) → CODE ANALYST (sonnet) → FIXER ↔ REVIEWER (opus, max 5 iterations) → TEST ENGINEER (sonnet, max 3 attempts) → PUBLISHER (haiku)
```

**Step 2: Update Config Contract optional section**

Line 84 — change:
```
Optional: Worktrees, Error Handling, E2E Test, Extra labels.
```
to:
```
Optional: Worktrees (Batch size, base path, cleanup), Error Handling, E2E Test (framework, command), Extra labels.
```

**Step 3: Update Repository Structure to include skills/**

Line 17 — add after `- `commands/` — 5 orchestration commands (slash commands)`:
```
- `skills/` — 1 routing skill for natural language access
```

Line 18 — change:
```
- `docs/plans/` — Architecture decision records
```
stays the same.

**Step 4: Update Commands list**

Line 23 — change:
```
**Commands** (orchestration — WHAT to do): `/analyze-bug`, `/fix-ticket`, `/fix-bugs`, `/create-pr`, `/publish`
```
to:
```
**Commands** (orchestration — WHAT to do): `/analyze-bug`, `/fix-ticket`, `/fix-bugs`, `/create-pr`, `/publish`, `/version-bump`
```

**Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md — generic pipeline, Config Contract, skills/ in structure"
```

---

### Task 13: Final verification and squash commit (optional)

**Step 1: Verify all files are consistent**

Run: `grep -r "YouTrack\|Gitea\|Playwright\|dotnet test\|YT " agents/ commands/`
Expected: no matches (all hardcoded references removed)

**Step 2: Verify Automation Config references**

Run: `grep -r "Automation Config" agents/`
Expected: matches in triage-analyst, fixer, test-engineer, e2e-test-engineer, publisher (5 agents)

**Step 3: Verify mcp__* in commands**

Run: `grep "allowed-tools" commands/`
Expected: all commands use `mcp__*` (not `mcp__youtrack__*` or `mcp__gitea__*`)

**Step 4: Verify skill exists**

Run: `ls skills/bug-workflow/SKILL.md`
Expected: file exists

**Step 5: Verify version-bump command exists**

Run: `ls commands/version-bump.md`
Expected: file exists

---

### Task 14: Code review

**Step 1: Run code review**

Use `superpowers:requesting-code-review` skill to review all changes against the design documents:
- `docs/plans/2026-02-19-skills-vs-commands.md`
- `docs/plans/2026-02-19-plugin-update-process.md`
- `docs/plans/2026-02-19-agent-docs-audit.md`

Review should verify:
- All audit findings from agent-docs-audit are addressed
- Routing skill matches design from skills-vs-commands
- Version-bump command matches design from plugin-update-process
- No regressions in existing agent/command functionality
- Consistent terminology across all files
