Implement v6.6.0 (v6.5.2 Follow-ups) — three items completing patterns started in v6.5.2.

### Item 1: Status Verification — Remaining Call Sites
v6.5.2 created `core/status-verification.md` (advisory post-set verification contract) and wired it into 3 call sites (publisher Step 7, block-handler Step 2, fix-ticket Step 1). Wire it into the remaining 4 call sites:
- A. `skills/implement-feature/SKILL.md` Step 1 (Set issue state)
- B. `core/fix-verification.md` Step 5 (re-open on verify failure)
- C. `skills/fix-bugs/SKILL.md` Block handler Step 2 (set issue state to Blocked)
- D. `skills/scaffold/SKILL.md` Step 8b (Close Tracker Issues — set Done state)

### Item 2: MCP Body Formatting Contract
v6.5.2 added per-site NEVER instructions for literal `\n` in 5 files. Replace these with a centralized `core/mcp-body-formatting.md` contract.
- A. Create `core/mcp-body-formatting.md`
- B. Replace inline instructions in 5 files with contract reference
- C. Update CLAUDE.md core count from 12 to 13
- D. Update test scenario

### Item 3: fix-bugs "On start set" Step
Add per-issue "On start set" step in fix-bugs per-issue loop with status verification reference.

### Post-implementation
Update roadmap, run tests, fix failures. Version: MINOR (v6.6.0).
