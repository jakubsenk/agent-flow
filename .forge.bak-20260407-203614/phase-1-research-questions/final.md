# Phase 1: Research Questions — Autopilot Skill

## Q1: Lock File Mechanism
How should the autopilot prevent concurrent runs when cron fires while a previous run is still executing? What file format, location, and stale-lock detection strategy should be used, given that the plugin runs on both Windows and Unix?

## Q2: Issue Type Classification
How can the autopilot reliably determine whether a fetched issue is a bug or feature? Should it run two separate queries (Bug query + Feature query) or a single combined query with post-fetch classification based on tracker metadata?

## Q3: Skill-to-Skill Dispatch
How does a skill invoke another skill (fix-bugs, implement-feature) from within its own SKILL.md? What is the correct dispatch pattern — direct inline instructions, Skill() tool invocation, or something else?

## Q4: "Already In Progress" Detection
How should the autopilot detect issues that are already being processed by a running pipeline? Should it check `.ceos-agents/{ISSUE-ID}/state.json` for status "running", check the issue tracker state (In Progress), or both?

## Q5: Config Section Design
What keys should the new `### Autopilot` optional config section contain? What are the correct defaults? How should it reference/interact with the existing Bug query and Feature query from other config sections?

## Q6: Run State Persistence
What state should persist across autopilot invocations? Should there be a `.ceos-agents/autopilot/` directory? What should the autopilot run history format look like?

## Q7: Logging Format and Location
Where should autopilot logs be stored? Should they use the existing JSONL format from pipeline.log, a simpler human-readable format, or structured JSON? How to integrate with the existing `.ceos-agents/` directory pattern?

## Q8: Error Boundaries and Recovery
What errors should cause the autopilot to skip one issue and continue vs stop the entire run? How should partial failures be handled (e.g., 2 of 3 issues processed, then MCP server goes down)?

## Q9: Claude CLI Invocation Pattern
What is the exact `claude` CLI command syntax for invoking a skill non-interactively? How does `--dangerously-skip-permissions` interact with MCP tools? Are there other flags needed for unattended execution?

## Q10: Max Issues and Sequential Processing
Given that fix-bugs already accepts a count argument, should autopilot simply delegate to `fix-bugs N` for bugs and loop over implement-feature for features? Or should autopilot handle the iteration itself for unified logging and error handling?
