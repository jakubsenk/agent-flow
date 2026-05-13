# Phase 3 Brainstorm — Judge Synthesis

## Proposals Evaluated

| # | Persona | Core Philosophy |
|---|---------|----------------|
| 1 | Contract Minimalist | Smallest possible contract surface; cut every section that lacks a runtime input/output |
| 2 | Defensive Pipeline Engineer | Every contract needs an enforcement test; explicit guards for every failure path |
| 3 | DX Advocate | Files must be readable in isolation; Constraints sections keep NEVER keywords for scanning |

---

## Decision 1: MCP Body Formatting Contract — Section Count and Publisher Constraints

### The Disagreement

- **Minimalist (Agent 1):** 4 sections — Purpose, Applies To, Process, Constraints. Cut Output Contract (no output), Input Contract (no input), Failure Mode (fold one sentence into Purpose).
- **Defensive (Agent 2):** Full 6 sections from Phase 2 PLUS a 7th Detection section (8 lines explaining how to spot violations post-hoc and remediate).
- **DX Advocate (Agent 3):** Accepts Phase 2 structure for the contract file itself, but dissents on Replacement 2 — keep a condensed NEVER rule in publisher.md Constraints alongside the contract reference.

### DECISION: 5 sections (Minimalist core + Failure Mode kept). Adopt DX Advocate's publisher Constraints hybrid.

**Contract file sections:** Purpose, Applies To, Process, Constraints, Failure Mode.

Reasoning:

1. **Cut Output Contract** (adopting Minimalist). Agent 1 is correct: a contract with no return value does not need an "Output Contract: N/A" section. The absence communicates the same thing. Every other core file with an Output Contract section actually defines structured output. This one does not. Remove it.

2. **Keep Failure Mode as a separate section** (rejecting Minimalist's fold-into-Purpose). Agent 1 proposed folding the failure explanation into Purpose as a closing sentence. But the failure mode of this contract is non-obvious (visual, not runtime) and is the primary motivation for the contract's existence. Burying it in Purpose reduces scanability. A contributor skimming the file should see "Failure Mode" as a heading and immediately understand the stakes. Two sentences in a dedicated section is worth the 4 extra lines.

3. **Reject Detection section** (rejecting Defensive). Agent 2's proposed Detection section describes how to spot violations and remediate. This is operational guidance for contributors, not a contract element. The 12 existing core files have no precedent for a Detection section. Adding one here creates a structural asymmetry that invites the question "why doesn't status-verification.md have a Detection section?" for every future core file. The remediation steps (edit the tracker item, find the MCP call, add the reference) are generic contributor workflow, not contract-specific. If this guidance is needed, it belongs in a contributor guide, not in a pipeline contract.

4. **Adopt DX Advocate's publisher.md Constraints hybrid** (adopting Agent 3, rejecting Agent 1's full DRY). Agent 3 makes the strongest argument in the entire brainstorm: Constraints sections use NEVER as a scanning convention (CLAUDE.md explicitly states "Constraints must start with NEVER or define hard limits"). Replacing a NEVER bullet with "Follow a contract" breaks that convention. The fix is simple: keep a one-sentence NEVER summary in publisher.md Constraints that points to the contract. This costs one line of minor duplication but preserves the scanning pattern that every agent definition relies on.

**Publisher.md Constraints replacement (revised from Phase 2 Replacement 2):**

```
- NEVER use `\n` as a line separator in MCP tool parameters -- use actual newlines. See `core/mcp-body-formatting.md` for the full formatting rule.
```

All other 6 replacements (Replacements 1, 3-7) use the Phase 2 reference-only phrases unchanged.

### REJECTED

| Idea | Source | Reason |
|------|--------|--------|
| 4-section contract (no Failure Mode) | Agent 1 | Failure mode is non-obvious and deserves its own heading for scanability |
| 7-section contract (+ Detection) | Agent 2 | No precedent in core/ files; operational guidance belongs elsewhere |
| Full DRY on publisher.md Constraints | Phase 2 research | Breaks the NEVER-scanning convention documented in CLAUDE.md |

---

## Decision 2: Status Verification Wiring — Pattern-Scanning Test

### The Disagreement

All three agents agree on the 4 insertion points and the uniform reference sentence. The only disagreement is whether to add a pattern-scanning test (`tests/scenarios/xref-status-verification.sh`) that automatically detects new status-set call sites missing the verification reference.

- **Defensive (Agent 2):** Add the test. ~35 lines. Prevents forgotten references on future call sites.
- **Minimalist (Agent 1):** Not proposed (silence = not needed).
- **DX Advocate (Agent 3):** Not proposed (silence = not needed).

### DECISION: Do NOT add the pattern-scanning test in v6.6.0.

Reasoning:

1. **False positive risk is real and under-estimated.** Agent 2 acknowledges the risk but dismisses it as "manageable." In a pure-markdown codebase where prose discusses "Set the state" in explanatory contexts (docs, comments, agent expertise sections), the heuristic of "mentions status-setting phrase AND mentions MCP" will fire on files that describe the pattern without executing it. Tuning the regex to avoid false positives requires ongoing maintenance of the test itself.

2. **The 7 call sites are now comprehensive.** After v6.6.0, every pipeline that performs a status-set MCP call will have the verification reference. New status-set call sites would only appear when a new pipeline or agent is added — a MINOR version event that naturally involves reviewing existing patterns. The drift risk is proportional to the rate of new pipeline creation, which is low (roughly 1-2 per major version).

3. **Scope discipline.** v6.6.0 is a PATCH release. Adding a new test file with pattern-scanning heuristics is feature work that belongs in a future version if drift actually occurs. The existing `xref-core-registry.sh` already verifies that every core file is referenced somewhere — this provides a baseline guard.

4. **Same reasoning applies to the dynamic scan (Check C) for MCP formatting.** Agent 2's proposed dynamic scan extension to `mcp-newline-handling.sh` has the same false-positive and maintenance concerns. The hardcoded Check A + Check B from Phase 2 is sufficient.

### REJECTED

| Idea | Source | Reason |
|------|--------|--------|
| `xref-status-verification.sh` pattern-scanning test | Agent 2 | False positive risk in prose-heavy markdown codebase; low drift rate; scope creep for PATCH |
| Dynamic scan (Check C) in `mcp-newline-handling.sh` | Agent 2 | Same false-positive concerns; hardcoded list is sufficient for 5 known files |

---

## Decision 3: fix-bugs "On Start Set" — Explicit Guard for Missing Config Key

### The Disagreement

All three agents agree on Step 1a placement (before triage), the "1a" label, worktree range update (2-8 to 1a-8), and the dry-run annotation. The disagreements:

- **Defensive (Agent 2):** Add explicit guard clause ("If Issue Tracker -> On start set is not configured -> skip this step silently") AND a failure note ("If the MCP call fails: log WARN, do not block").
- **Minimalist (Agent 1):** No guard needed; implicit skip matches fix-ticket behavior.
- **DX Advocate (Agent 3):** Match fix-ticket wording exactly; no additional guards.

### DECISION: Do NOT add the explicit guard clause or failure note. Match fix-ticket exactly.

Reasoning:

1. **Consistency is the strongest argument.** Agent 3 nails this: fix-ticket Step 1 has been shipping since v3.x without an explicit guard for missing "On start set" and works correctly. Adding the guard to fix-bugs Step 1a but not fix-ticket Step 1 creates an inconsistency that is worse than the implicit skip. Agent 2 acknowledges this ("diverges from fix-ticket Step 1") but accepts it. I do not — consistency across pipelines is a first-order design principle in this codebase.

2. **LLM inference handles this correctly.** "Set the state per Automation Config (Issue Tracker -> On start set)" is unambiguous for sonnet/opus: if the key does not exist in the config, there is nothing to set. This is the same pattern used across dozens of config-conditional instructions in the codebase. Adding an explicit guard here but nowhere else implies the other instructions need guards too.

3. **The WARN failure note duplicates status-verification.** The verification contract (`core/status-verification.md`) already handles MCP call failures with WARN-and-continue semantics. Adding a second failure note in the step text is redundant with the verification reference that immediately follows. The verification contract is the single source of truth for "what happens when a status-set call fails."

4. **Backporting the guard to fix-ticket would be scope creep.** Agent 2 explicitly rules out backporting to maintain scope, which means accepting the inconsistency. The cleaner path is: no guard in either file, consistent behavior, and if a future model misinterprets the instruction, add the guard to BOTH files as a separate PATCH.

### REJECTED

| Idea | Source | Reason |
|------|--------|--------|
| Explicit "skip silently" guard in Step 1a | Agent 2 | Creates inconsistency with fix-ticket Step 1; implicit skip works correctly |
| WARN failure note in Step 1a | Agent 2 | Redundant with status-verification contract referenced in the same step |

---

## Final Implementation Plan (post-synthesis)

All Phase 2 edits are confirmed with one modification:

| Item | Approach | Source |
|------|----------|--------|
| Status Verification Wiring (4 sites) | Phase 2 as-is: 4 identical one-sentence insertions | All 3 agents agree |
| MCP Contract file | 5 sections: Purpose, Applies To, Process, Constraints, Failure Mode (cut Output Contract from Phase 2) | Agent 1 (cut Output Contract) + Judge (keep Failure Mode) |
| MCP Replacement 2 (publisher Constraints) | Condensed NEVER + contract reference (DX hybrid) | Agent 3 |
| MCP Replacements 1, 3-7 | Phase 2 reference-only phrases unchanged | All 3 agents agree |
| MCP test update | Phase 2 Check A + Check B (hardcoded). No dynamic scan. | Phase 2 + Judge (reject Agent 2 Check C) |
| fix-bugs Step 1a | Phase 2 text exactly (no guard clause, no failure note) | Agent 1 + Agent 3 |
| fix-bugs worktree range | 2-8 -> 1a-8 per Phase 2 | All 3 agents agree |
| CLAUDE.md core count | 12 -> 13 per Phase 2 | All 3 agents agree |
| No new test files | No xref-status-verification.sh | Judge (reject Agent 2) |

### Revised MCP Contract File Content

```markdown
# MCP Body Formatting

## Purpose

Prevent literal `\n` escape sequences from appearing in MCP tool parameters that accept
multi-line text. MCP tools receive parameter values as-is from the calling model --
escaped sequences like `\n` are rendered as the literal two-character sequence backslash-n,
not as actual newlines. This contract defines the required construction pattern.

## Applies To

All MCP tool calls where the parameter value contains multi-line content:
- PR description body (source control MCP: create_pull_request, create_pr)
- Issue comment body (tracker MCP: create_comment, add_comment)
- Issue/card description body (tracker MCP: create_issue, update_issue)
- Block comment fields (pipeline block protocol)
- Sub-issue description body (decomposition subtask creation)

## Process

1. Construct all multi-line strings with actual line breaks (real newlines in the source text).
2. Never interpolate or concatenate the string literal `\n` as a line separator.
3. Verify the constructed string contains Unicode U+000A newline characters between lines, not escape sequences.

## Constraints

- NEVER use `\n` as a line separator in any MCP parameter value
- NEVER concatenate field values with the string `"\n"` -- use actual newlines
- NEVER interpolate `\n` inside template strings passed to MCP tools

## Failure Mode

There is no runtime failure -- the MCP tool accepts the parameter and creates the
issue/comment/PR. The failure is visual: multi-line content appears as a single line
with literal `\n` characters visible to end users in the issue tracker or source control UI.
```

### Revised Publisher.md Constraints Replacement (Replacement 2)

**old_string:**
```
- NEVER use the literal characters `\n` in any MCP tool parameter that accepts multi-line text (PR description, issue comments). Always construct multi-line strings with actual line breaks (real newlines). The MCP tool receives the parameter value as-is -- escaped sequences like `\n` are rendered literally, not as newlines.
```

**new_string:**
```
- NEVER use `\n` as a line separator in MCP tool parameters -- use actual newlines. See `core/mcp-body-formatting.md` for the full formatting rule.
```

All other edits (Replacements 1, 3-7, all 4 SV insertions, Step 1a, worktree range, CLAUDE.md, test update) remain exactly as specified in Phase 2.

**Total: 1 new file + 10 edits across 9 existing files. No new test files.**
