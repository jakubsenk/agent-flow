# Research Answers — Work Item 3: Block Handler Inline Removal (Agent 2)

Source files read:
- `skills/implement-feature/SKILL.md` (677 lines)
- `core/block-handler.md` (56 lines)
- `skills/fix-ticket/SKILL.md` (638 lines)
- `skills/fix-bugs/SKILL.md` (809 lines)

---

## Q3.4: Exact line range of inline block handler in implement-feature

**Lines 642–666** of `skills/implement-feature/SKILL.md`.

```
642: ### X. Block handler
643:
644: Follow `core/block-handler.md`:
645:
646: 1. Run `ceos-agents:rollback-agent` (Task tool, model: haiku) — revert git changes
647: 2. Set issue state to Blocked (State transitions → Blocked)
648: 3. **On block action** (per Error Handling → On block):
649:    - `comment` (default): Add a Block comment to the issue tracker (see below)
650:    - `close`: Add a Block comment + close the issue
651:    - Other value: interpret as a custom action (always add a comment)
652: 4. Add Block comment to the issue tracker:
653:    ```
654:    [ceos-agents] 🔴 Pipeline Block
655:    Agent: {agent name}
656:    Step: {pipeline step}
657:    Reason: {max 2 sentences}
658:    Detail: {error output}
659:    Recommendation: {what human should do}
660:    ```
661: 5. If Notifications → Webhook URL exists and On events contains `issue-blocked`:
662:    ```bash
663:    curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"issue-blocked","issue":"{issue_id}","agent":"{agent}","reason":"{reason}"}'
664:    ```
665:
666: 6. Update `state.json`: set top-level `status` to `"blocked"`, write `block` object with `{agent, step, reason, detail, recommendation}`. Follow atomic write protocol from `core/state-manager.md`.
```

Line 667 begins the `## Rules` section — so the inline body is exactly **lines 642–666** (25 lines).

---

## Q3.1: Does inline block handler in implement-feature differ from core/block-handler.md?

**YES — multiple differences.** Detailed diff:

### Difference 1: Step header (line 644 vs core Process preamble)
- **implement-feature L644:** `Follow `core/block-handler.md`:` — then immediately re-lists all steps inline (contradictory: delegates AND duplicates).
- **core/block-handler.md:** No delegation line; directly enumerates the Process.

### Difference 2: Rollback condition (Step 1)
- **implement-feature L646:** `Run ceos-agents:rollback-agent (Task tool, model: haiku) — revert git changes` — unconditional; no guard on agent type.
- **core/block-handler.md L21:** `If the blocking agent is fixer, reviewer, test-engineer, or e2e-test-engineer, OR the blocking step is smoke-check → dispatch rollback-agent. Do NOT rollback on block from triage-analyst or code-analyst — no git changes to revert.`

**Gap:** implement-feature omits the conditional guard. It would incorrectly call rollback-agent when a read-only agent (e.g. spec-analyst) blocks.

### Difference 3: Rollback context string
- **implement-feature:** No rollback context string specified.
- **core/block-handler.md L21:** `Context: "Agent: {agent_name}. Step: {step_name}. Reason: {reason}. Detail: {detail}. Recommendation: {recommendation}. Execution context: CWD (no worktree)."`

**Gap:** implement-feature provides no Task context for rollback-agent.

### Difference 4: State transition — status-verification
- **implement-feature L647:** `Set issue state to Blocked (State transitions → Blocked)` — plain instruction.
- **core/block-handler.md L24:** `After the status-set MCP call, follow core/status-verification.md to verify the transition succeeded.`

**Gap:** implement-feature omits the status-verification follow-up.

### Difference 5: Webhook curl command format
- **implement-feature L663:**
  ```bash
  curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"issue-blocked","issue":"{issue_id}","agent":"{agent}","reason":"{reason}"}'
  ```
  — Missing `--max-time 5 --retry 0`; uses `{webhook_url}` (not `"{Webhook URL}"`); JSON field is `"issue"` not `"issue_id"`; missing `"timestamp":"{ISO8601}"`.
- **core/block-handler.md L41–44:**
  ```bash
  curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
    -d '{"event":"issue-blocked","issue_id":"{issue_id}","agent":"{agent_name}","reason":"{reason}","timestamp":"{ISO8601}"}' \
    "{Webhook URL}"
  ```

**Gap:** implement-feature curl is missing timeout flag, retry flag, timestamp field, and uses wrong JSON key (`issue` vs `issue_id`).

### Difference 6: mcp-body-formatting.md reference
- **implement-feature:** Not mentioned anywhere in the inline body.
- **core/block-handler.md L38:** `Follow core/mcp-body-formatting.md when constructing the comment string.`

**Gap:** implement-feature omits MCP body formatting instruction.

### Difference 7: state.json path
- **implement-feature L666:** `Update state.json: ...`
- **core/block-handler.md L45:** `Update state.json: ...` (same wording, no path specified — consistent).

### Difference 8: Input Contract / Output Contract / Failure Handling sections
- **core/block-handler.md:** Has explicit Input Contract (7 fields), Output Contract, and Failure Handling sections (comment failure → warn, webhook failure → warn, state failure → warn, rollback failure → warn + note in detail).
- **implement-feature:** None of these are present inline.

### Summary of gaps in implement-feature relative to core:
| Gap | Severity |
|-----|----------|
| No rollback guard (always calls rollback-agent) | Behavioral bug |
| No rollback Task context string | Missing context |
| No status-verification follow-up | Missing step |
| Old curl format (no timeout, no timestamp, wrong key) | Protocol deviation |
| No mcp-body-formatting.md reference | Missing spec |
| No Failure Handling instructions | Missing spec |

---

## Q3.2: What skill-specific logic must remain after removing the inline body?

One line must remain after stripping the inline enumeration:

**`skills/implement-feature/SKILL.md` L666:**
```
6. Update `state.json`: set top-level `status` to `"blocked"`, write `block` object with `{agent, step, reason, detail, recommendation}`. Follow atomic write protocol from `core/state-manager.md`.
```

This step 6 is **present in core/block-handler.md** (line 45) with identical meaning, so it is NOT skill-specific — it comes from core.

Conclusion: **No skill-specific logic exists in implement-feature's inline block handler.** The state.json update (line 666) duplicates what core already mandates. After delegating fully to `Follow core/block-handler.md`, the step 6 line can be removed as redundant.

The only thing that might be considered "context" is that implement-feature runs in CWD (no worktree), but core already notes `Execution context: CWD (no worktree)` in the rollback context string for non-worktree skills.

---

## Q3.3: How do fix-ticket and fix-bugs structure their Step X?

### fix-ticket (`skills/fix-ticket/SKILL.md` lines 605–610)

**Pattern: Pure delegate + one skill-specific state.json addendum.**

```
### X. Block handler

Follow `core/block-handler.md` for the block protocol.

Update `state.json`: set top-level `status` to `"blocked"`, write `block` object with
{agent, step, reason, detail, recommendation}. Follow atomic write protocol from
`core/state-manager.md`.
```

- Line 607: clean delegate sentence (`Follow core/block-handler.md for the block protocol.`)
- Lines 609: one addendum for state.json (also redundant — covered by core, but harmless as reminder)
- **No inline re-listing of steps.** Total: 6 lines.

### fix-bugs (`skills/fix-bugs/SKILL.md` lines 667–710)

**Pattern: Delegate + full inline re-listing + skill-specific addenda (worktree context, block counter).**

```
### X. Block handler

Follow `core/block-handler.md` for the block protocol.

On block from fixer\reviewer\test-engineer\build\hook\custom agent:

1. Rollback: Run rollback-agent with worktree context string
2. Set issue state to Blocked + status-verification.md
3. On block action (comment/close/custom)
4. Add Block comment
   Follow core/mcp-body-formatting.md
5. Webhook — issue-blocked (curl with --max-time 5 --retry 0)
6. Update .ceos-agents\{ISSUE-ID}\state.json
7. Block counter: Increment block_count; if >= Max blocked per run → skip to step 9
8. Continue with next bug.
```

- Line 669: delegate sentence
- Lines 671–710: full inline body re-listed (same concern as implement-feature, but with fix-bugs-specific additions)
- **Skill-specific logic unique to fix-bugs:**
  - Step 1 rollback context string includes `Execution context: {worktree_path if worktree mode} | CWD (if sequential)` — worktree-aware
  - Step 6 uses path `.ceos-agents\{ISSUE-ID}\state.json` (per-issue path, not generic `state.json`)
  - Steps 7–8: block counter logic (`block_count`, `Max blocked per run`, skip to step 9 if limit reached)

---

## Q3.5: Does implement-feature's inline reference any skill-specific variables?

**No.** All variables in the implement-feature inline body are generic pipeline variables:
- `{agent name}`, `{pipeline step}`, `{issue_id}`, `{agent}`, `{reason}` — present in core contract
- `state.json` without issue-specific path — same as fix-ticket

No implement-feature-specific flags (e.g. `--decompose`, `--no-implement`) or state fields appear in the inline block handler.

---

## Q3.6: What is the canonical "delegate + skill-specific state update" pattern?

Based on fix-ticket (the cleanest example), the canonical pattern is:

```markdown
### X. Block handler

Follow `core/block-handler.md` for the block protocol.

{skill-specific addenda only — items not covered by core}
```

**fix-ticket** (lines 605–609) is the reference implementation:
- Line 1: `### X. Block handler`
- Line 2: (blank)
- Line 3: `Follow \`core/block-handler.md\` for the block protocol.`
- Line 4: (blank)
- Line 5: The state.json reminder (redundant but harmless; omitting it would be cleaner)

For implement-feature, the ideal refactored form (removing all inline steps since none are skill-specific) would be identical to fix-ticket's pattern:

```markdown
### X. Block handler

Follow `core/block-handler.md` for the block protocol.
```

No skill-specific addendum is required because:
- implement-feature is CWD-only (no worktree path variation)
- No block counter logic applies
- state.json path is the generic single-issue path (already covered by core)
