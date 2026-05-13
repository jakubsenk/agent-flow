# Execution Prompt — Onboard Wizard Redesign

Paste this into a new Claude Code session:

---

```
Implement the onboard wizard redesign per the plan in docs/plans/2026-03-02-onboard-redesign-plan.md (design doc: docs/plans/2026-03-02-onboard-redesign-design.md).

Execute all 6 tasks in order. After completing ALL tasks, run a full cross-file code review:

1. Read every changed file and cross-reference against docs/reference/automation-config.md (normative spec) and CLAUDE.md (config contract)
2. Check: key names, profile definitions, section names, Feature query placement, table format, English-only output, no leftover Czech
3. Check: commands/onboard.md covers all 12 optional sections, both modes (fresh + update), $ARGUMENTS, bundles, Pipeline Profiles prominence, PR template preview
4. Check: examples/configs/*.md, tests/harness/fixtures/automation-config.md, tests/mock-project/CLAUDE.md all use identical key names as normative spec
5. Check: commands/check-setup.md lists PR Description Template as required, uses long-form key names

If review finds ANY issues → fix them, commit the fix, then re-run the full review. Repeat until review finds ZERO issues. Only then report completion.

Rules:
- Commit after each task (not at the end)
- All text in English (wizard questions, generated config, commit messages)
- Do NOT change the Automation Config contract (no new required keys, no renamed sections)
- Do NOT modify commands other than onboard.md and check-setup.md
- Do NOT modify agents/
- Do NOT bump version — that happens separately
```
