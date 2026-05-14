# fix-verification

## Purpose

Run the verify command after PR merge to confirm the changes work on the target branch.

## Input Contract
- `config` — Automation Config (Build & Test section — Verify command; Issue Tracker section — State transitions)
- `issue_id` — issue tracker ID
- `pr_url` — URL of the merged PR
- `base_branch` — base branch to checkout after merge

## Process
1. If Build & Test → Verify command is not configured → return `SKIPPED`.
2. Wait for PR merge: query via MCP server, max 5 attempts with 30s interval.
   - If PR is not merged after 5 attempts → return `SKIPPED` with note: "PR not merged yet. Run verify manually: `{Verify command}`".
3. Checkout base branch and pull: `git checkout {base_branch} && git pull`.
4. Run the Verify command from Automation Config.
5. If command succeeds → post success comment to the issue:
   ```
   [agent-flow] ✅ Verified. Verify command: `{command}`. Output: {first 500 chars}.
   ```
   Return `PASSED`.
6. If command fails → post failure comment to the issue:
   ```
   [agent-flow] ❌ Verification failed.
   Command: `{command}`
   Output: {first 500 chars}
   ```
   If State transitions contains a re-open key → set the issue state back. After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded. Display: "Verification failed. Issue re-opened." Return `FAILED`.

## Output Contract

`PASSED` | `FAILED` | `SKIPPED`

## Failure Handling
- Verify command timeout → treat as `FAILED` (apply step 6 handling).
- PR not merged after polling window → return `SKIPPED` with manual-run note.
- MCP query failure during merge check → treat as PR not merged, return `SKIPPED`.
