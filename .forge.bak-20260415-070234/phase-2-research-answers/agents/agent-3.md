# Phase 2 — Implementation Scope Definition

## Agent Role

This document converts Phase 1 research findings into a concrete, bounded implementation plan. For each proposed improvement, it answers: feasibility, file change count, regression risk, and verification strategy. It then issues a clear IN SCOPE / DEFERRED verdict with rationale.

---

## Improvement 1: Machine-Readable Output Tokens — Add ## Machine Output sections

### What Phase 1 Found

Four agents produce tokens that orchestrating skills parse for branching decisions:
- `triage-analyst.md`: `Quality gate: UNCLEAR` → consumed by fix-bugs step 2, fix-ticket, analyze-bug
- `code-analyst.md`: `root cause confirmed: NO` → consumed by fix-bugs step 3
- `fixer.md`: `## NEEDS_DECOMPOSITION` heading → consumed by fix-bugs step 4, implement-feature
- `reviewer.md`: `Verdict: APPROVE / REQUEST_CHANGES / BLOCK` and `FULFILLED / PARTIALLY / NOT ADDRESSED` → consumed by fixer loop control and acceptance-gate input

All are currently embedded in prose templates with no isolation. Case variation or surrounding punctuation causes silent parse failures.

### Feasibility Assessment

**Technically feasible.** The fix is additive: append a `## Machine Output` subsection to the output template in each agent's Process section. The existing prose template is preserved unchanged. No skill changes are required — skills can continue parsing prose tokens while the new section offers a reliable fallback.

**Version implication — this is a MAJOR version trigger.** CLAUDE.md states:

> MAJOR (X.0.0): breaking change in agent output format contract (new/modified structured output sections that Agent Overrides or external tooling may parse). Example: new output section in triage-analyst.

Adding `## Machine Output` to triage-analyst, code-analyst, fixer, and reviewer is exactly this case. External tooling and Agent Overrides may parse these sections. This means the version bump for this improvement is MAJOR (7.0.0), not MINOR or PATCH.

**Critical design question not yet answered:** The current skills parse the prose tokens directly. If `## Machine Output` is added to agent definitions, must skills be updated to prefer the new section, or is the new section purely supplemental documentation? Phase 1 recommends it as a "reliable parsing anchor" — but if skills don't use it, the section is inert documentation with no reliability improvement. If skills are updated to use it, that changes parsing logic in at minimum fix-bugs/SKILL.md, implement-feature/SKILL.md, and fix-ticket/SKILL.md.

**File changes required (minimum viable):**
- `agents/triage-analyst.md` — add `## Machine Output` to output template
- `agents/code-analyst.md` — add `## Machine Output` to output template
- `agents/fixer.md` — add `## Machine Output` to output template
- `agents/reviewer.md` — add `## Machine Output` to output template
- **If skills are updated to parse the new section:** `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/fix-ticket/SKILL.md`, `skills/analyze-bug/SKILL.md` — 4 more files
- **Version bump:** `plugin.json`, `marketplace.json`, CHANGELOG.md — 3 more files

Minimum: 4 files. With skill updates: 11 files.

**Regression risk:** MEDIUM-HIGH. The fixer loop and reviewer branching in fix-bugs and implement-feature are the most complex logic in the plugin. Any change to how skills parse verdict tokens risks breaking the loop termination conditions. The `reviewer-reject.sh` test verifies `APPROVE` and `REQUEST_CHANGES` are present in reviewer.md — it would need updating. No tests currently verify the exact parse path or that `## Machine Output` sections are used.

**Verification:**
- Existing test `reviewer-reject.sh` — must still pass, may need token presence assertion updated
- New test: verify `## Machine Output` section exists and contains correct tokens for all 4 agents
- Manual: trace fix-bugs skill parsing logic against updated agent output template to confirm no parse regression

### Verdict: DEFERRED — Requires separate MAJOR version

**Rationale:** This improvement requires a MAJOR version bump (7.0.0) per CLAUDE.md versioning policy, a design decision on whether skills parse the new section (not yet made), and touches the most regression-sensitive branching logic in the plugin. It is high-value but not appropriate to bundle with lower-risk improvements. Recommend as the primary focus of a dedicated v7.0.0 planning session after this forge run. The design question — "do skills use the new section or is it supplemental?" — must be resolved before implementation can begin.

---

## Improvement 2: Config Template Format — Switch examples/configs/ from tables to YAML-style colon notation

### What Phase 1 Found

The `| Key | Value |` markdown table format costs ~35% more tokens than `Key: Value` colon notation for config files. There are 8 config templates in `examples/configs/`. The total saving is ~1,250 tokens across all 8 files. The more meaningful saving is in consuming projects' CLAUDE.md, which is read on every pipeline invocation (~260 tokens/run compounding).

### Feasibility Assessment

**NOT FEASIBLE without a contract change.** Phase 1 identified this as a token saving opportunity, but the research also reveals why it cannot be done in isolation:

1. `core/config-reader.md` line 15 explicitly states: "Parse required sections — each is a `| Key | Value |` table under its `### {Section}` heading." The config-reader contract is built around table parsing. Changing the format of config templates while leaving config-reader unchanged would create a mismatch between examples and the parsing contract they demonstrate.

2. `agents/scaffolder.md` line 138 instructs: "All config sections MUST use table format (`| Key | Value |`), NOT bullet-point lists." The scaffolder generates new projects' CLAUDE.md files in table format. Changing examples while leaving the scaffolder's constraint unchanged means generated configs would differ from the examples.

3. `skills/onboard/SKILL.md` line 205, line 298 explicitly enforces table format during onboarding.

4. `docs/architecture.md` documents the `| Key | Value |` format as an enforced standard.

5. `docs/guides/troubleshooting.md` instructs users to use `| Key | Value |` tables.

**File changes required to fully implement this improvement:**
- `examples/configs/*.md` — 8 files
- `core/config-reader.md` — update the parse contract
- `agents/scaffolder.md` — update the constraint
- `skills/onboard/SKILL.md` — update the enforcement
- `CLAUDE.md` — update the Config Contract section
- `docs/architecture.md` — update the documentation
- `docs/getting-started.md` — update examples (uses `| Key | Value |` format)
- `docs/guides/troubleshooting.md` — update the troubleshooting guidance
- Potentially `skills/migrate-config/SKILL.md` — currently detects "bullet-point format instead of table format"

This is at minimum 12 files across 5 distinct areas of the codebase. Additionally:

**Version implication:** Changing the config contract is a MAJOR version change (CLAUDE.md: "Breaking change in Automation Config contract"). Changing the notation for config sections would break every existing consuming project's CLAUDE.md on the day they update the plugin.

**Regression risk:** CRITICAL. Every consuming project has configs in `| Key | Value |` format. Changing the format to `Key: Value` colon notation would break all existing installations unless a migration path is provided. The `config-required-keys.sh` and `config-reader-sections.sh` tests parse config files and would need comprehensive updates.

### Verdict: DEFERRED — Cross-cutting MAJOR change, inappropriate scope for this run

**Rationale:** This improvement requires 12+ file changes across agents, skills, core, docs, and examples. It triggers a MAJOR version bump and breaks all existing consumer configs without a migration. The token savings are real but modest (~1,250 tokens for the plugin files themselves). The improvement is not wrong — it is simply the wrong scope for this pipeline run. Recommend as a separate MAJOR version discussion, potentially paired with a migration guide and `migrate-config` skill update.

---

## Improvement 3: Step Numbering Fixes — scaffolder.md duplicate 4b labels

### What Phase 1 Found

`agents/scaffolder.md` has two sections labeled `4b`. Step 4 (line 143) is "Verify the skeleton builds and tests pass" and step `4b` (line 149) is "Generate quality scorecard" — a second `4b` after an already-numbered `4`. This creates LLM step-dependency ambiguity.

### Feasibility Assessment

**Fully feasible.** This is a single-file edit with no downstream dependencies.

**Exact diagnosis from the file:**
- Step 3: CLAUDE.md generation checklist
- Step 4: Verify the skeleton builds (lines 143–147)
- Step `4b`: Generate quality scorecard (lines 149–164) ← the duplicate/out-of-order label
- Step 5: Output (line 165)

The `scaffold/SKILL.md` uses `4b-replaced` and `4c-replaced` labels for the scaffold skill's steps 4b and 4c — these are in the skill file, not the agent, and have a comment explaining the collision: "Step numbering: 0-INFRA and 0-MCP use label suffixes to avoid collision with existing Step 0b. Steps 4d and 4e use letter suffixes per standard convention." The `agents/scaffolder.md` file has no such collision justification — the `4b` label appears to be an error from when the scorecard step was added without renumbering.

**Correct fix:** Renumber `agents/scaffolder.md` step `4b` to step `5`, and the current step `5` (Output) to step `6`. This is a clean sequential scheme: 1, 2, 3, 4, 5 (scorecard), 6 (output).

**File changes required:**
- `agents/scaffolder.md` — change `4b.` to `5.` and `5.` to `6.` (2 line changes, same file)

**Regression risk:** VERY LOW. The scaffolder agent reads its own Process steps. Renaming step labels does not change the logic — it only clarifies the sequence. No tests reference internal step numbers of scaffolder.md. The only risk is if the scaffold skill or another file cross-references "step 4b of scaffolder" by name — a grep check below confirms this is not the case.

**Cross-reference check:** `skills/scaffold/SKILL.md` dispatches the scaffolder agent via Task tool but does not reference its internal step numbers. No test scenario file references scaffolder step 4b.

**Verification:**
- `frontmatter-completeness.sh` — must still pass (agents list, model assignments)
- `scaffold-v2-spec-loop.sh` — must still pass
- Manual inspection: confirm sequential numbering 1–6 after the change

### Verdict: IN SCOPE

**Rationale:** Single-file, 2-line change, zero downstream dependencies, no version bump required (behavior fix without contract change = PATCH), very low regression risk, and directly addresses a documented LLM ambiguity from Phase 1.

---

## Improvement 4: Boilerplate Reduction — "Follow atomic write protocol" repetition in fix-bugs

### What Phase 1 Found

The phrase "Follow atomic write protocol from `core/state-manager.md`" appears 16 times in `skills/fix-bugs/SKILL.md` (confirmed by grep count: 16). Phase 1 characterizes this as a contributor readability problem, while acknowledging the repetition is intentional for LLM clarity (each relevant step independently reminds the LLM to follow the protocol).

### Feasibility Assessment

**Feasible with careful scoping.** Phase 1 explicitly states: "A contributor-facing note at the top of the file explaining the repetition pattern would reduce cognitive load without removing any functional content." This is the minimal, safe intervention.

The alternative — removing the repetition and replacing with a single top-level declaration — is risky. LLMs process long documents in context windows and do not reliably apply top-level rules to specific sub-steps without local reminders. The current repetition is a deliberate LLM design pattern. Removing it would change functional behavior (reduce the LLM's compliance with the atomic write requirement at individual steps).

**Proposed change:** Add a single `<!-- Contributor note: "Follow atomic write protocol" appears at each state.json write step intentionally — this is LLM-directed repetition for reliable compliance, not accidental duplication. Do not consolidate. -->` HTML comment near the top of fix-bugs/SKILL.md, just before the first state.json write reference.

**File changes required:**
- `skills/fix-bugs/SKILL.md` — add 1 HTML comment (1 line insertion)

**Regression risk:** VERY LOW. HTML comments in skill files are processed by Claude but are low-signal — they provide context without issuing commands. The test suite does not check for absence of HTML comments. No existing test parses the file for this content.

**Verification:**
- `pipeline-consistency.sh` — must still pass
- `happy-path.sh` — must still pass
- No new test needed (the change is documentation-only)

### Verdict: IN SCOPE

**Rationale:** Single-file, 1-line addition. No functional change, no version bump (PATCH at most). Directly addresses the contributor readability concern identified in Phase 1 while preserving the intentional LLM design pattern. No regression risk.

---

## Improvement 5: File Decomposition — scaffold/SKILL.md (925 lines) and fix-bugs/SKILL.md (770 lines)

### What Phase 1 Found

Both files exceed safe LLM working memory for complex edits. `scaffold/SKILL.md` at 925 lines has cross-file dependency between Step 4 (line ~600) and Step 0-INFRA (line 60) that is invisible across that distance. `fix-bugs/SKILL.md` at 770 lines has repeated boilerplate that contributes to size.

### Feasibility Assessment

**NOT FEASIBLE for this pipeline run.** File decomposition for skills requires answering the following questions that were flagged as "Recommended Research for Phase 2" by Phase 1 but have not been answered:

1. **Does the Claude Code runtime support skill file includes or continuation loading?** If skills must be a single `SKILL.md` file per directory, decomposition into phase files is not loadable by the runtime. Without confirming runtime support, decomposition would break skill registration.

2. **What are the inter-phase dependency contracts?** Scaffold's Step 0-INFRA stores in-memory variables (`tracker_type`, `sc_remote`, etc.) used by Steps 4, 4d, 4e. These must be explicitly defined as phase input/output contracts if the file is split.

3. **Version implications:** Decomposing a skill file likely requires a MINOR version bump (new skill structure). The changelog, plugin metadata, and tests would all need updating.

**File changes required for full decomposition:**
- `skills/scaffold/SKILL.md` → split into 4 phase files (infra-setup, spec-phase, implementation-phase, finalization) — 4 new files + removal/rewrite of original
- `skills/fix-bugs/SKILL.md` → split into 3–4 phase files — 3–4 new files + removal/rewrite of original
- Update skill loading in plugin metadata (if needed)
- Update all tests that reference these files by path
- CHANGELOG + version bump

Minimum: ~10 files, with high risk of runtime incompatibility if Claude Code does not support multi-file skill loading.

**Regression risk:** HIGH. Both files are core pipeline logic. The test suite has `pipeline-consistency.sh`, `happy-path.sh`, `pipeline-feature-step-order.sh`, `test-step-placement.sh` — all of which would need updating. Runtime incompatibility is an untested risk that would silently break all pipeline executions.

### Verdict: DEFERRED — Requires runtime capability research first

**Rationale:** The prerequisite question (does Claude Code support multi-file skill loading?) is unanswered. Without that answer, implementing decomposition risks breaking skill registration entirely. This improvement needs a dedicated Phase 1 investigation scoped specifically to Claude Code's runtime capabilities for skill files. Recommend as a separate forge research task before any implementation.

---

## Summary Table

| # | Improvement | Verdict | Reason |
|---|---|---|---|
| 1 | Machine-readable output tokens (`## Machine Output` sections) | DEFERRED | MAJOR version trigger, design question unresolved, high regression risk in branching logic |
| 2 | Config template format (tables → colon notation) | DEFERRED | MAJOR version + breaks all existing consumer configs, 12+ file cross-cutting change |
| 3 | Step numbering fix (scaffolder.md duplicate 4b) | IN SCOPE | Single file, 2-line change, PATCH-level, zero downstream dependencies |
| 4 | Boilerplate reduction (atomic write protocol comment) | IN SCOPE | Single file, 1-line addition, documentation-only, no functional change |
| 5 | File decomposition (scaffold + fix-bugs) | DEFERRED | Runtime capability unknown, high regression risk, 10+ file change |

---

## In-Scope Implementation Plan

### Change A: Fix scaffolder.md step numbering

**File:** `agents/scaffolder.md`

**Edit:**
- Line 149: Change `4b. Generate quality scorecard:` to `5. Generate quality scorecard:`
- Line 165: Change `5. Output:` to `6. Output:`

**Test verification:**
```
./tests/harness/run-tests.sh frontmatter-completeness
./tests/harness/run-tests.sh scaffold-v2-spec-loop
```

**Version:** PATCH (behavior fix, no contract change)

---

### Change B: Add contributor note to fix-bugs/SKILL.md

**File:** `skills/fix-bugs/SKILL.md`

**Edit:** Add an HTML comment on the first line that precedes the first state.json write instruction in the file, explaining that the "Follow atomic write protocol" repetition is intentional LLM design.

Locate the first occurrence of "Follow atomic write protocol" (line ~459 based on grep context) and insert the comment one line above the step containing it, or alternatively insert a contributor-facing note in the file header section after the frontmatter.

**Test verification:**
```
./tests/harness/run-tests.sh pipeline-consistency
./tests/harness/run-tests.sh happy-path
```

**Version:** PATCH (no contract change, documentation addition only)

---

## Deferred Items — Recommended Next Steps

| Item | Prerequisite Before Implementing |
|---|---|
| Machine Output sections | (1) Decide: do skills parse `## Machine Output` or is it supplemental? (2) Plan as v7.0.0 MAJOR |
| Config notation change | (1) Design migration path for existing consumer configs (2) Plan as MAJOR with `migrate-config` update |
| File decomposition | (1) Research Claude Code runtime: does multi-file skill loading work? (2) Define inter-phase contracts for in-memory variables |

---

## Risk Register for In-Scope Changes

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Skill referencing scaffolder step "4b" by name breaks | Very Low | Medium | Confirmed by grep: no skill or test references scaffolder internal step numbers by label |
| HTML comment in SKILL.md changes LLM behavior | Very Low | Low | HTML comments are informational; do not issue commands; runtime does not execute them |
| Tests fail after step renumber | Very Low | Low | Tests check agent list, model, frontmatter — not internal step labels |
