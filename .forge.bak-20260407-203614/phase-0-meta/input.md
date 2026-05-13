Implement a local automated pipeline runner for ceos-agents. Read docs/plans/roadmap.md section "Standalone Machine Deployment" (line 589) for full context and open questions.

Goal: A user runs a single command (or sets up a Windows Task Scheduler / cron job) that periodically polls their YouTrack issue tracker and automatically runs /ceos-agents:fix-bugs or /ceos-agents:implement-feature on matching issues, fully unattended until PR creation.

Scope for this iteration (local PC proof-of-concept):
1. A new skill /ceos-agents:autopilot (or similar name) that:
   - Reads Bug query and Feature query from Automation Config
   - Queries the issue tracker for matching issues
   - For each issue: determines if it's a bug or feature, dispatches the appropriate pipeline skill
   - Logs results (success/blocked/error) to a file
   - Handles "already in progress" issues (skip them)
   - Respects a configurable max issues per run (default: 1)
2. Documentation on how to set up Windows Task Scheduler or cron to invoke it via `claude -p "Run /ceos-agents:autopilot" --dangerously-skip-permissions`
3. Consider: what happens if a previous run is still going when cron fires again (lock file?)

Out of scope: auth persistence testing, server deployment, systemd services. This is a local PoC only.
