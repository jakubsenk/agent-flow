# Custom Agent Examples

Example custom agent definition files for the agent-flow `Post-fix agent` and
`Pre-publish agent` pipeline hooks (configured via `Custom Agents` in Automation Config).

## Included Examples

| File | Role | Use case |
|------|------|----------|
| `compliance-checker.md` | Post-fix agent | Runs compliance checks after every fix (GDPR, accessibility, etc.) |
| `dependency-analyst.md` | Post-fix agent | Analyses dependency changes introduced by the fix |
| `migration-reviewer.md` | Pre-publish agent | Reviews database migration files before PR is created |
| `security-analyst.md` | Post-fix agent | Performs security analysis on the changed code |

## How to use

1. Copy the example file to your project root (e.g. `my-compliance-checker.md`).
2. Adapt the agent instructions to your project's requirements.
3. Reference the file in your Automation Config:

   ```markdown
   ### Custom Agents
   | Key | Value |
   |-----|-------|
   | Post-fix agent | my-compliance-checker.md |
   ```

## Custom agent format

Custom agents follow the same format as built-in agents — see `agents/` for reference
and `CONTRIBUTING.md` for the mandatory six-section structure.
