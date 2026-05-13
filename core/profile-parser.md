# profile-parser

## Purpose

Parse a pipeline profile from Automation Config and determine which stages to skip or add.

## Input Contract
- `config` — Automation Config (Pipeline Profiles section)
- `pipeline_name` — name of the current pipeline (e.g., `fix-bugs`, `implement-feature`)
- `profile_name` — value from `--profile <name>` argument

## Process
1. If `--profile <name>` is not provided → return empty skip_stages and extra_stages (no-op).
2. Read the `### Pipeline Profiles` section from Automation Config.
3. Find the row matching `profile_name`. If not found → error: "Profile '{name}' not found in Automation Config".
4. Extract `Skip stages` column (comma-separated list) and `Extra stages` column.
5. Validate skip list: stages `fixer`, `reviewer`, `publisher` CANNOT be skipped. If any appear → BLOCK with error: "Profile '{name}' attempts to skip mandatory stage '{stage}'. Fixer, reviewer, and publisher cannot be skipped."
6. Validate each stage name against v9 canonical stage names: `triage`, `analyst-impact`, `spec-analyst`, `test-engineer`, `test-engineer-e2e`, `browser-agent-reproduce`, `browser-agent-verify`. Invalid names → log warning "[WARN] Unknown stage '{name}' in profile — ignored", skip that entry.
7. Return validated skip_stages and extra_stages lists.

## Output Contract
- `skip_stages: string[]` — stages to skip in the pipeline
- `extra_stages: string[]` — stages to force-enable (e.g., `test-engineer-e2e` without E2E config)

## Failure Handling
- Profile not found → hard error, stop pipeline.
- Attempt to skip `fixer`, `reviewer`, or `publisher` → BLOCK with error message.
- Unknown stage name in skip list → log warning, ignore the entry, continue.
