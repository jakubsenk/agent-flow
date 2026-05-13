# Agent 1 — Contract Minimalist Proposal

**Perspective:** Shared contracts should be as small as possible. Single-sentence references beat duplicated text. Every new abstraction must justify its weight. 15+ years designing interface contracts where each extra field is a future breaking-change liability.

---

## Item 1: Status Verification Wiring (4 sites)

### Philosophy

The reference phrase from Phase 2 research is already minimal: `After the status-set MCP call, follow core/status-verification.md to verify the transition succeeded.` That is one sentence, zero ambiguity, no semantic duplication. I agree with the Phase 2 approach -- it is already contract-minimalist.

### Assessment of the 4 insertion points

**1a. implement-feature Step 1** — Clean insertion. Step 1 is a two-sentence prose paragraph. Adding a third sentence as a standalone paragraph is the right granularity. The reference phrase is identical to the one already wired in fix-ticket Step 1 and publisher Step 7. Consistency wins.

**Trade-off:** None. The alternative -- inlining the verification logic -- would be worse (duplicating the 55-line contract into prose). One sentence reference is optimal.

**1b. fix-verification Step 6** — Inline insertion within a conditional clause. The sentence goes after "set the issue state back" and before the Display line. This is the correct spot: verification happens immediately after the MCP call, before the pipeline reports the outcome.

**Trade-off:** The sentence makes a long line even longer. But breaking Step 6 into sub-steps would be over-engineering for a single conditional path. Accept the long line.

**1c. fix-bugs block handler Step 2** — The fix-bugs SKILL.md re-expands the block protocol inline (steps 1-8) rather than delegating to `core/block-handler.md`. This means we must add the verification line in *both* places. The core file already has it (v6.5.2). The inline expansion needs it for readability consistency.

**Trade-off: Should the inline expansion just delegate to core/block-handler.md instead?** No. The inline expansion exists because fix-bugs has worktree-aware orchestration that needs the block steps visible in context. Replacing 8 inline steps with "follow core/block-handler.md" would lose that visibility. Accept the duplication -- it is intentional and documented (the `<!-- Contributor note -->` pattern already exists in this file for similar cases).

**1d. scaffold Step 8b items 3a + 3b** — Two insertions within the same numbered list item. Each transition call (epic, then per-story) gets its own verification tail. This is correct: they are independent MCP calls that can independently fail.

**Trade-off:** The lines get noticeably long (3a goes from ~100 chars to ~170 chars). Alternative: break 3a/3b into sub-bullets. But every other core reference in the codebase uses inline continuation, not sub-bullets. Consistency wins over local readability. Accept long lines.

### My verdict on Item 1

**Agree fully with Phase 2 approach. No modifications needed.** The reference phrase is already the minimum viable contract reference. Four edits, four identical one-sentence insertions. Zero new sections, zero new files, zero new abstractions.

Estimated diff: +5 lines across 4 files (one line per insertion, plus the worktree range fix in fix-bugs which is a separate edit but same file).

---

## Item 2: MCP Body Formatting Contract

### The central question: Does this need all 6 standard core sections?

The 12 existing core files use this structure:

| Section | Count of files using it | Required? |
|---------|------------------------|-----------|
| Purpose | 12/12 | Yes -- every contract explains why it exists |
| Input Contract | 11/12 | Most -- but `status-verification` uses a table, `fix-verification` uses bullets |
| Process | 12/12 | Yes -- numbered steps |
| Output Contract | 12/12 | Yes -- what the caller gets back |
| Constraints | 6/12 | Optional -- only when NEVER rules exist |
| Failure Handling | 10/12 | Optional -- only when failures are meaningful |

Now evaluate MCP Body Formatting against each section:

**Purpose** -- YES. Must explain why `\n` breaks MCP parameters. This is the non-obvious part that justifies the contract's existence.

**Input Contract** -- NO. This contract has no inputs. It is not called with parameters. It is a construction rule applied inline by the caller before building a string. Adding an "Input Contract" section with "N/A" or inventing phantom inputs adds noise.

**Process** -- YES, but minimal. Three rules: (1) use real newlines, (2) never concatenate `\n`, (3) verify U+000A. The Phase 2 proposal has exactly this. Correct.

**Output Contract** -- CHALLENGE. Phase 2 says "No return value. Callers apply the rule inline before constructing MCP tool parameters." That is one sentence saying "there is no output." I would cut this section entirely. A contract with no output does not need an Output Contract section. The absence communicates the same thing with zero bytes.

**Constraints** -- YES. The NEVER rules are the core value of this contract. Three bullets. Concise.

**Applies To** -- Phase 2 adds this non-standard section. I agree with it -- it replaces the Input Contract with something more useful: a list of contexts where the rule applies. This is better than a fake Input Contract table.

**Failure Mode** -- Phase 2 adds this non-standard section. I would rename it to "Failure Handling" for consistency with other core files. Content is correct: the failure is visual, not runtime. One paragraph. Keep it.

### My proposed structure (4 sections instead of 6)

```
# MCP Body Formatting

## Purpose
{why \n breaks MCP -- 3 sentences max}

## Applies To
{bullet list of MCP call contexts}

## Process
{3 numbered rules}

## Constraints
{3 NEVER bullets}
```

**Cut:** Input Contract (no inputs), Output Contract (no outputs), Failure Mode (move the one-sentence explanation into Purpose as a closing remark: "The failure is visual: literal \n characters appear in the tracker UI.").

**Trade-off:** Cutting Failure Handling means callers do not know what happens on violation. But this is not a callable contract -- it is a style rule. The "failure" is that the user sees broken formatting. That belongs in Purpose ("here is why we care"), not in a separate Failure Handling section.

**Counter-argument:** Other core files with Failure Handling describe *pipeline* failure modes (MCP timeout, permission error). This contract has no pipeline failure mode -- the MCP call succeeds either way. The asymmetry justifies cutting the section.

### Proposed contract content

```markdown
# MCP Body Formatting

## Purpose

Prevent literal `\n` escape sequences in MCP tool parameters that accept multi-line text.
MCP tools receive parameter values as-is -- escaped sequences like `\n` are rendered as the
literal two-character string backslash-n, not as actual newlines. The failure is visual:
multi-line content appears as a single line with `\n` visible to end users.

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
```

**Delta from Phase 2 proposal:** Removed Output Contract section (1 line), removed Failure Mode section (3 lines), folded the failure explanation into Purpose (1 added sentence). Net: -6 lines from the contract file. Same information, tighter.

### The 7 replacements

I agree with all 7 replacement strings from Phase 2. Two canonical forms:
- "Follow `core/mcp-body-formatting.md` when constructing multi-line MCP tool parameters." (for sub-issue/PR contexts)
- "Follow `core/mcp-body-formatting.md` when constructing the comment string." (for block comments)

Plus the two publisher-specific variants (inline continuation and full-bullet).

**Trade-off on publisher.md's two occurrences:** Phase 2 replaces both Step 6 sub-bullet and Constraints bullet. The Constraints bullet currently has a 3-sentence explanation. Replacing it with a 1-sentence reference loses the "why" from the agent's constraint section. But the "why" now lives in the contract file's Purpose section. Any agent reading the reference will find the explanation one hop away. This is the correct DRY trade-off.

**Alternative considered: Keep the Constraints explanation, only extract the Process steps.** This would mean the Constraints section still says "NEVER use `\n`..." with the full explanation, while Step 6 says "follow core/mcp-body-formatting.md". Inconsistent -- if we extract, we extract fully. Reject this alternative.

### Test scenario update

Agree with Phase 2: replace the single-marker grep with two checks (contract exists + references exist). The T-013 tag is preserved. The PASS message updates to reflect the new structure.

**One refinement:** The contract file check should grep for the *constraint* text specifically (the NEVER rule), not just file existence. Phase 2 already does this: `grep -q "NEVER use" "$CONTRACT"`. Correct.

---

## Item 3: fix-bugs "On start set" Step

### Step label and placement

**Step 1a** between Step 1 (Fetch bugs) and Step 2 (Triage). Using "1a" avoids renumbering all 9 existing steps. This is the standard pattern in ceos-agents (see scaffold's step numbering: 0-INFRA, 0-MCP, 0a, 0b, etc.).

**Trade-off: Why not Step 1b?** No prior Step 1a exists, so "1a" is correct. "1b" would imply an existing "1a". Simple.

**Trade-off: Why not renumber to Step 2 and shift everything?** Because:
1. The stage mapping table (`triage=step 2, code-analyst=step 3, ...`) would need updating
2. Resume-ticket might have indirect references (Phase 2 confirmed it does not, but renumbering increases risk)
3. Profile parser stage mappings hardcode step numbers
4. "1a" is zero-impact on all downstream numbering

### Timing: Before vs. after triage

Phase 2 resolved this as "before triage (optimistic)." I agree but want to explicitly state the trade-off:

**Risk of optimistic "On start set":** If the bug is a DUPLICATE, we set it to "In Progress" and then immediately need to handle it differently (close it). The state transitions become: Idle -> In Progress -> Closed (duplicate). This is a no-op waste of one MCP call, plus it may confuse issue tracker audit logs.

**Why accept this risk:** fix-ticket already does exactly the same thing (sets state before triage). If we put "On start set" after triage in fix-bugs but before triage in fix-ticket, the inconsistency is worse than the wasted MCP call. Consistency across pipelines is worth more than one extra API call per duplicate.

**Alternative: After triage, before code-analyst (Step 2.5).** This avoids setting state on duplicates. But fix-ticket does not do this. Reject for inconsistency.

### Full step text

```markdown
### 1a. Set issue tracker

Set the state per Automation Config (Issue Tracker -> On start set). Read Type for the correct MCP server.

After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

*In dry-run: skip this step.*
```

**Note:** This step also wires status verification (Item 1), making it a natural 2-for-1: one insertion handles both the missing "On start set" and one of the 4 verification wiring sites.

Wait -- this is a *fifth* verification wiring site that Phase 2 did not count separately because it is created as part of Item 3, not Item 1. The verification line is built into the new step text. No additional edit needed.

### Worktree range update

Current: `steps 2-8`. New: `steps 1a-8`. Phase 2 provides exact old/new strings. Agree.

**Trade-off:** Step 1a makes an MCP call. In worktree-parallel mode, multiple bugs will call "On start set" concurrently. MCP calls are serialized by the Claude Code runtime (Task tool runs in separate contexts), so there is no race condition. Each bug talks to the tracker about its own issue ID. No concern.

### Dry-run annotation

Phase 2 says the dry-run prose range "steps 1-3" does not need updating since 1a is numerically within [1,3] and the prose explicitly says "no side effects: no issue tracker state changes." Step 1a is an issue tracker state change, so it is correctly excluded by the prose. Agree -- no change needed.

---

## Summary: Contract Minimalist Deltas from Phase 2

| Item | Phase 2 Proposal | My Delta | Rationale |
|------|------------------|----------|-----------|
| 1: SV wiring (4 sites) | 4 one-sentence insertions | None | Already minimal |
| 2: MCP contract structure | 6 sections (Purpose, Applies To, Process, Output Contract, Constraints, Failure Mode) | 4 sections (Purpose, Applies To, Process, Constraints) | No inputs, no outputs, no runtime failure = cut Input/Output/Failure sections; fold failure explanation into Purpose |
| 2: MCP replacements (7x) | 7 exact edit strings | None | Already minimal reference phrases |
| 2: Test update | Two-check replacement | None | Already correct |
| 3: Step 1a text | 5-line block with verification | None | Already minimal |
| 3: Worktree range | 2-8 -> 1a-8 | None | Already correct |

**Net difference from Phase 2:** The contract file is ~6 lines shorter (27 lines vs. 33 lines). Everything else is identical. The minimalism philosophy validates Phase 2's approach -- it was already lean. The only fat to cut was ceremonial sections in a contract that has no inputs, no outputs, and no runtime failures.

### Total change footprint

- 1 new file: `core/mcp-body-formatting.md` (~27 lines)
- 10 edits across 9 files (same as Phase 2)
- CLAUDE.md core count: 12 -> 13
- Net lines added across all files: ~20 (new contract) + ~10 (insertions) - ~15 (replaced verbose inline text) = ~15 net new lines

This is a small, clean changeset with high DRY payoff.
