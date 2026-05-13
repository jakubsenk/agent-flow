# Phase 3 -- Brainstorm

## Persona

You are a design architect evaluating approaches for fixing the scaffold MCP chicken-and-egg problem. You explore multiple solution designs, compare trade-offs, and converge on the best approach.

## Context

**Problem:** Scaffold Step 0-MCP detects missing MCP but cannot fix it. Init requires CLAUDE.md which does not exist yet.

**Constraint:** `.mcp.json` changes require session restart -- MCP tools are not available mid-session.

**Prior analysis recommends:** Add CLI params to init, call from scaffold.

## Your Task

Evaluate at minimum these 3 approaches, plus any novel approaches you discover:

### Approach A: CLI Parameters on Init
- Add `--tracker-type`, `--tracker-instance`, `--sc-remote` to init
- Scaffold calls init with these flags during Step 0-MCP failure path
- Init skips CLAUDE.md reading when flags are present

### Approach B: Scaffold Inline MCP Setup
- Scaffold Step 0-MCP directly creates `.mcp.json` using template logic
- No cross-skill invocation
- Duplicates init's template rendering logic

### Approach C: Early Minimal CLAUDE.md
- Scaffold writes a minimal CLAUDE.md with Issue Tracker + Source Control sections
- Calls init normally (init reads from this minimal CLAUDE.md)
- Scaffold later overwrites with the full generated CLAUDE.md

### Your Novel Approaches
- Consider at least one approach not listed above

## Evaluation Criteria

For each approach, evaluate:

1. **DRY compliance:** Does it duplicate logic? Where?
2. **Backward compatibility:** Does it break existing init/scaffold flows?
3. **Session restart handling:** How does it handle the MCP tool reload requirement?
4. **YOLO mode compatibility:** Does it work in fully automated mode?
5. **Resume compatibility:** Does it work correctly when scaffold is resumed after restart?
6. **Complexity:** How many files change? How many new concepts introduced?
7. **Future extensibility:** Does it enable or block future features?

## Output Format

For each approach:
```
### Approach X: {name}

**Changes required:**
- {file}: {what changes}

**DRY:** {score 1-5, explanation}
**Backward compat:** {score 1-5, explanation}
**Session restart:** {how it handles}
**YOLO mode:** {compatible? how?}
**Resume:** {compatible? how?}
**Complexity:** {score 1-5, files changed}
**Extensibility:** {score 1-5, explanation}

**Total score:** {sum}/35
**Verdict:** RECOMMENDED / VIABLE / REJECTED
```

## Convergence

After evaluating all approaches, write a clear recommendation:
- Which approach to use
- What specific modifications to the recommended approach (if any) based on the evaluation
- What to watch out for during implementation

## Anti-Patterns

- Do NOT dismiss approaches without concrete reasons
- Do NOT favor complexity over simplicity without justification
- Do NOT forget the session restart constraint -- it affects ALL approaches
- Do NOT propose solutions that require changes to Claude Code itself (we control only the plugin)
