# Phase 2 Research Answers — Agent 1

## Scope

Answering MCP-4 (publisher.md two occurrences), SV-1 through SV-4 (status verification exact text), and MCP-1 (inline NEVER locations).

---

## MCP-4: How to Handle publisher.md's Two Occurrences

Read `agents/publisher.md` completely. Two NEVER instructions about `\n` exist.

### Step 6 inline NEVER instruction (line 65, inside the Description bullet)

**Exact text (the full bullet sub-item):**
```
  - Build the PR body as a multi-line string with real line breaks between sections — NEVER use the literal characters `\n` as line separators.
```

**Context (surrounding lines):**
```
- **Description:** Use PR Description Template from Automation Config (always English). Fill in ALL template sections:
  - Build the PR body as a multi-line string with real line breaks between sections — NEVER use the literal characters `\n` as line separators.
  - Summary, Changes, Testing, Issue link
```

This occurrence is embedded as a sub-item inside the Description bullet of Step 6. It is describing how to build the PR body.

### Constraints section NEVER instruction (line 96, fifth bullet)

**Exact text:**
```
- NEVER use the literal characters `\n` in any MCP tool parameter that accepts multi-line text (PR description, issue comments). Always construct multi-line strings with actual line breaks (real newlines). The MCP tool receives the parameter value as-is — escaped sequences like `\n` are rendered literally, not as newlines.
```

**Context (surrounding lines):**
```
- NEVER include "Generated with Claude Code" footer in PR description — if the tool auto-appends it, that is acceptable, but do NOT add it manually
- NEVER use the literal characters `\n` in any MCP tool parameter that accepts multi-line text (PR description, issue comments). Always construct multi-line strings with actual line breaks (real newlines). The MCP tool receives the parameter value as-is — escaped sequences like `\n` are rendered literally, not as newlines.
- PR description always in English
```

This occurrence is in the Constraints section and is the most detailed/authoritative explanation of the rule.

### Recommendation: Replace BOTH with reference phrase (DRY approach)

**Step 6 inline replacement:**
```
  - Build the PR body as a multi-line string with real line breaks between sections — follow `core/mcp-body-formatting.md`.
```

**Constraints section replacement:**
```
- Follow `core/mcp-body-formatting.md` when constructing multi-line MCP tool parameters (PR description, issue comments)
```

**Rationale:** The contract file (`core/mcp-body-formatting.md`) will contain the full explanation (the "why" — that escaped `\n` sequences are rendered literally). Both occurrences should be pure references to avoid dual-maintenance. The Constraints section is the more detailed occurrence, but since it will be the *only* place the full explanation lives (in the contract file), both publisher.md occurrences should be pure references. This is consistent with the DRY approach used for `core/status-verification.md`.

---

## SV-1: implement-feature/SKILL.md — Step 1 exact text

**File:** `skills/implement-feature/SKILL.md`

**Step 1 (lines 163–168):**
```
### 1. Set issue state

Read the issue from the issue tracker. Set the state per Feature Workflow → On start set
(fallback: Issue Tracker → On start set).

### 2. Create branch
```

**Exact surrounding text at insertion point (10+ words before and after):**

Before insertion point: `(fallback: Issue Tracker → On start set).`
After insertion point (next non-blank line): `### 2. Create branch`

The step has NO status-verification reference currently. The insertion goes as a new standalone line after the closing parenthesis line and before `### 2. Create branch`.

**Exact old_string for Edit tool:**
```
Read the issue from the issue tracker. Set the state per Feature Workflow → On start set
(fallback: Issue Tracker → On start set).

### 2. Create branch
```

**Exact new_string for Edit tool:**
```
Read the issue from the issue tracker. Set the state per Feature Workflow → On start set
(fallback: Issue Tracker → On start set).

After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

### 2. Create branch
```

---

## SV-2: core/fix-verification.md — Step 6 (failure path) exact text

**File:** `core/fix-verification.md`

**Step 6 (lines 24–30):**
```
6. If command fails → post failure comment to the issue:
   ```
   [ceos-agents] ❌ Fix verification failed.
   Command: `{command}`
   Output: {first 500 chars}
   ```
   If State transitions contains a re-open key → set the issue state back. Display: "Fix verification failed. Issue re-opened." Return `FAILED`.
```

**No status-verification reference exists currently.** The insertion point is within step 6, after "set the issue state back" and before "Display:".

**Exact old_string for Edit tool:**
```
   If State transitions contains a re-open key → set the issue state back. Display: "Fix verification failed. Issue re-opened." Return `FAILED`.
```

**Exact new_string for Edit tool:**
```
   If State transitions contains a re-open key → set the issue state back. After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded. Display: "Fix verification failed. Issue re-opened." Return `FAILED`.
```

---

## SV-3: fix-bugs/SKILL.md — Block handler Step 2 exact text

**File:** `skills/fix-bugs/SKILL.md`

**Block handler Step 2 (lines 644):**
```
2. **Set issue state to Blocked** (State transitions → Blocked)
```

**No status-verification reference exists currently.** The step is a single line with no sub-content. The insertion goes as an indented continuation line directly after step 2.

**Exact surrounding text (lines 642–648):**
```
   - DO NOT rollback on block from triage/code-analyst — no git changes to revert

2. **Set issue state to Blocked** (State transitions → Blocked)

3. **On block action** (per Error Handling → On block):
```

**Exact old_string for Edit tool:**
```
2. **Set issue state to Blocked** (State transitions → Blocked)

3. **On block action** (per Error Handling → On block):
```

**Exact new_string for Edit tool:**
```
2. **Set issue state to Blocked** (State transitions → Blocked)
   After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

3. **On block action** (per Error Handling → On block):
```

---

## SV-4: scaffold/SKILL.md — Step 8b item 3 exact text

**File:** `skills/scaffold/SKILL.md`

**Step 8b Transition logic item 3 (lines 819–823):**
```
3. For each fully-completed epic:
   a. Transition the epic issue to Done using `State transitions -> Done` syntax from Automation Config.
   b. Close each story sub-issue individually for ALL tracker types. Read story IDs from back-reference comments (`<!-- {TrackerType}: {STORY-ID} -->`) within the epic file. Transition each story issue to Done using the same `State transitions -> Done` syntax.
   c. If a story issue is already in the target Done state, treat it as success — do not emit a warning or error.
   d. On failure (epic or story transition): WARN (`Could not transition {issue_id} to Done: {error}`), continue to next.
```

**No status-verification reference exists currently.** The Phase 1 synthesis calls for adding the reference in sub-items 3a and 3b.

**Exact old_string for Edit tool:**
```
3. For each fully-completed epic:
   a. Transition the epic issue to Done using `State transitions -> Done` syntax from Automation Config.
   b. Close each story sub-issue individually for ALL tracker types. Read story IDs from back-reference comments (`<!-- {TrackerType}: {STORY-ID} -->`) within the epic file. Transition each story issue to Done using the same `State transitions -> Done` syntax.
   c. If a story issue is already in the target Done state, treat it as success — do not emit a warning or error.
```

**Exact new_string for Edit tool:**
```
3. For each fully-completed epic:
   a. Transition the epic issue to Done using `State transitions -> Done` syntax from Automation Config. After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.
   b. Close each story sub-issue individually for ALL tracker types. Read story IDs from back-reference comments (`<!-- {TrackerType}: {STORY-ID} -->`) within the epic file. Transition each story issue to Done using the same `State transitions -> Done` syntax. After each status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.
   c. If a story issue is already in the target Done state, treat it as success — do not emit a warning or error.
```

---

## MCP-1 VERIFICATION: All Inline NEVER Instruction Locations

### 1. agents/publisher.md

**Step 6 (line 65) — inside Description bullet:**
```
- **Description:** Use PR Description Template from Automation Config (always English). Fill in ALL template sections:
  - Build the PR body as a multi-line string with real line breaks between sections — NEVER use the literal characters `\n` as line separators.
  - Summary, Changes, Testing, Issue link
```

NEVER line (line 65): `  - Build the PR body as a multi-line string with real line breaks between sections — NEVER use the literal characters \`\n\` as line separators.`

**Constraints section (line 96):**
```
- NEVER include "Generated with Claude Code" footer in PR description — if the tool auto-appends it, that is acceptable, but do NOT add it manually
- NEVER use the literal characters `\n` in any MCP tool parameter that accepts multi-line text (PR description, issue comments). Always construct multi-line strings with actual line breaks (real newlines). The MCP tool receives the parameter value as-is — escaped sequences like `\n` are rendered literally, not as newlines.
- PR description always in English
```

NEVER line (line 96): `- NEVER use the literal characters \`\n\` in any MCP tool parameter that accepts multi-line text (PR description, issue comments). Always construct multi-line strings with actual line breaks (real newlines). The MCP tool receives the parameter value as-is — escaped sequences like \`\n\` are rendered literally, not as newlines.`

### 2. core/block-handler.md

**Step 4 (line 38) — after the block comment template:**
```
   [ceos-agents] 🔴 Pipeline Block
   Agent: {agent_name}
   Step: {step_name}
   Reason: {reason}
   Detail: {detail}
   Recommendation: {recommendation}
   ```
   When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters `\n` as line separators.
5. **Fire webhook** if config → Notifications → Webhook URL exists
```

NEVER line (line 38): `   When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters \`\n\` as line separators.`

### 3. skills/fix-ticket/SKILL.md

**Step 4b-tracker area** — search for `\n` NEVER instruction in fix-ticket:

The `\n` NEVER instruction in fix-ticket appears at Step 4b-tracker (line 386):
```
    - If `maps_to` is empty, omit the "Addresses:" line.
    - If `files` is empty, omit the "Files:" line.
    - The "Parent issue:" line is always present.
    - When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators.
```

NEVER line: `    - When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters \`\n\` as line separators.`

### 4. skills/implement-feature/SKILL.md

**Step 5a area (line 431):**
```
- If `maps_to` is empty, omit the "Addresses:" line.
- If `files` is empty, omit the "Files:" line.
- The "Parent issue:" line is always present.

When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators.

### Step 5a-exit (--decompose-only mode)
```

NEVER line (line 431): `When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters \`\n\` as line separators.`

### 5. skills/fix-bugs/SKILL.md

**3b-tracker area (line 373):**
```
When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators.

### 3c. Subtask execution (decomposition, per-bug)
```

NEVER line (line 373): `When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters \`\n\` as line separators.`

**Block handler Step 4 area (lines 660–661):**
```
   Recommendation: {what human should do}
   ```

When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters `\n` as line separators.

5. **Webhook — issue-blocked:**
```

NEVER line (line 661): `When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters \`\n\` as line separators.`

---

## Summary Table

| Location | NEVER instruction type | Replacement phrase |
|----------|------------------------|-------------------|
| `agents/publisher.md` Step 6 (inline sub-bullet) | PR body construction | `follow \`core/mcp-body-formatting.md\`` |
| `agents/publisher.md` Constraints (5th bullet) | General MCP multi-line text | `Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters` |
| `core/block-handler.md` Step 4 (prose after template) | Block comment posting | `Follow \`core/mcp-body-formatting.md\` when constructing the comment string.` |
| `skills/fix-ticket/SKILL.md` Step 4b-tracker (bullet) | Sub-issue description | `Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters.` |
| `skills/implement-feature/SKILL.md` Step 5a (standalone line) | Sub-issue description | `Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters.` |
| `skills/fix-bugs/SKILL.md` Step 3b-tracker (standalone line) | Sub-issue description | `Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters.` |
| `skills/fix-bugs/SKILL.md` Block handler Step 4 (prose after template) | Block comment posting | `Follow \`core/mcp-body-formatting.md\` when constructing the comment string.` |

**Total: 7 inline NEVER occurrences to replace across 5 files.**

Note: fix-bugs has 2 NEVER occurrences (one in 3b-tracker, one in Block handler Step 4), same as publisher.md.
