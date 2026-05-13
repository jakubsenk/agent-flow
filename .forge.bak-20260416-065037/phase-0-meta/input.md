Implement v6.7.1 (Contract & Schema Fixes + Hardening Follow-ups) — 7 items from audit + verification review.

### Item 1: config-reader Missing Key
Add `decomposition.create_tracker_subtasks` (default: `enabled`) to `core/config-reader.md` Decomposition section parsing. Currently used by 3 pipeline skills but not documented in the config-reader contract.
- Files: `core/config-reader.md`

### Item 2: Config Validity Gate in fix-bugs
Add Config Validity Gate (Step 0b) to fix-bugs for parity with fix-ticket and implement-feature. Currently fix-bugs is the only pipeline skill missing this gate.
- Files: `skills/fix-bugs/SKILL.md`
- Reference: copy Step 0b pattern from `skills/fix-ticket/SKILL.md`

### Item 3: State Schema Retry Limit Fields
Add `config.retry_limits.spec_iterations` and `config.retry_limits.root_cause_iterations` to `state/schema.md`. These limits exist in the Automation Config contract but not in the state schema.
- Files: `state/schema.md`

### Item 4: Code-analyst Before Architect in implement-feature
Add conditional code-analyst dispatch before architect in implement-feature for modification-heavy features. Heuristic: if existing files match the spec-analyst scope, run code-analyst first.
- Files: `skills/implement-feature/SKILL.md`

### Item 5: Marker Nesting Attack Mitigation
Add content escaping to `core/external-input-sanitizer.md`: escape any occurrence of marker strings (`--- EXTERNAL INPUT START ---` / `--- EXTERNAL INPUT END ---`) within the wrapped content before wrapping. Prevents attacker-controlled tracker content from injecting premature boundary termination.
- Files: `core/external-input-sanitizer.md`

### Item 6: State-Manager Graceful Degradation Documentation
Add explicit graceful degradation clause to `core/state-manager.md` for when `.claude-plugin/plugin.json` is unreadable (missing, malformed JSON, no `version` field). Default to `null` with no error.
- Files: `core/state-manager.md`

### Item 7: Extended NEVER Constraint Coverage
Extend external input marker NEVER constraint to 3 additional agents: acceptance-gate, architect, reproducer. Same constraint format as existing 5 agents (triage-analyst, code-analyst, fixer, reviewer, spec-analyst).
- Files: `agents/acceptance-gate.md`, `agents/architect.md`, `agents/reproducer.md`

### Post-implementation
1. Update roadmap.md — move v6.7.1 to DONE
2. Update CLAUDE.md if any counts change
3. Run tests and fix failures

Version: PATCH (v6.7.1). No new config contract keys.
