# Persona 3: DX Advocate

**Perspective:** I prioritize readability for future contributors. Every file should be understandable in isolation, even at the cost of minor duplication. When we replace inline explanations with contract references, we must ask: will a contributor reading this file for the first time understand what is happening and why? A reference is only useful if the reader knows when to follow it and what they will miss if they do not.

---

## Item 1: Status Verification Wiring (4 sites)

### The Reference Sentence

The established pattern from v6.5.2 is:

> After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

This already appears in three places (publisher.md Step 7, block-handler.md Step 2, fix-ticket Step 1). The research proposes adding it to four more sites with the same wording.

### Trade-off: Uniform Pattern vs. Contextual Help

**Option A: Identical sentence everywhere (research proposal).** Every site gets the exact same reference sentence. Pros: maximum consistency, grep-friendly, easy to audit. Cons: the sentence tells you WHAT to do but not WHY it matters at that specific site, and some sites have unique contextual concerns.

**Option B: Reference sentence + brief inline context at select sites.** Add a parenthetical hint at sites where the context is non-obvious. Cons: inconsistency, harder to machine-grep, higher maintenance burden.

### My Recommendation: Option A (uniform pattern)

The reference sentence is already self-documenting. It says "follow X to verify the transition succeeded" -- that is both the WHAT and the WHY in one clause. Adding site-specific context would create a maintenance problem: every time the verification contract changes, you would need to update not just the contract file but also the contextual hints sprinkled across call sites.

The four new sites are:

1. **implement-feature Step 1** -- Identical context to fix-ticket Step 1 (both set "On start set"). No additional context needed.

2. **fix-verification Step 6** -- This one is the most tempting candidate for extra context because the verification fires on a failure path (re-opening after verify failure). But the surrounding sentence already says "set the issue state back" and "Fix verification failed. Issue re-opened." A contributor reading this will understand the re-open is the status transition being verified. Extra context would be redundant with the enclosing paragraph.

3. **fix-bugs block handler Step 2** -- This is an inline expansion of `core/block-handler.md`. The block-handler contract already has the verification line at its own Step 2. Adding the same line to the fix-bugs inline expansion is just maintaining parity. Any contributor reading fix-bugs will see the same structure as the core contract, which reinforces the pattern rather than creating confusion.

4. **scaffold Step 8b items 3a/3b** -- These are dense inline items where the verification sentence is appended as a continuation clause. The research proposes adding it after each "Transition the epic/story issue to Done..." sentence. This is the right call. The items already describe the MCP call context (Done transition, State transitions syntax). The verification sentence adds clarity about what happens after the call.

**Verdict for Item 1:** Use the uniform reference sentence at all 4 sites. No site needs extra inline context. The sentence is already readable in isolation. Consistency across 7 total sites (3 existing + 4 new) will establish it as a recognizable codebase pattern that future contributors learn once and recognize everywhere.

### One concern about scaffold 8b

The research appends the verification sentence to items 3a and 3b, making those lines notably long. Current item 3a is already 100+ characters. After the append, it will exceed 200 characters as a single sentence. This is fine for LLM-directed markdown (these files are consumed by models, not rendered in narrow terminals), but worth noting: if a future contributor reformats for readability, they should preserve the verification clause as part of the same logical instruction, not split it into a separate numbered item (which would disrupt the 3a/3b/3c/3d numbering).

---

## Item 2: MCP Body Formatting Contract

### The Core DX Question

When a contributor reads `publisher.md` and encounters:

> Follow `core/mcp-body-formatting.md` when constructing multi-line MCP tool parameters (PR description, issue comments).

...will they understand WHY newlines matter without opening the contract file?

Currently, publisher.md's Constraints section says:

> NEVER use the literal characters `\n` in any MCP tool parameter that accepts multi-line text (PR description, issue comments). Always construct multi-line strings with actual line breaks (real newlines). The MCP tool receives the parameter value as-is -- escaped sequences like `\n` are rendered literally, not as newlines.

This is three sentences. It explains the WHAT (never use `\n`), the HOW (use real newlines), and the WHY (MCP renders them literally). A contributor reading this for the first time immediately understands the problem and the solution without leaving the file.

### Option A: Full DRY (research proposal)

Replace all 7 occurrences with a short reference phrase. The contract file becomes the single source of truth.

**Pros:**
- Single maintenance point
- Consistent reference pattern across 5 files
- Contract file has the full explanation including "Applies To" list

**Cons:**
- Publisher.md's Constraints section loses its self-contained explanation
- A contributor encountering the constraint for the first time must open a separate file to understand it
- The "NEVER" keyword disappears from the agent file -- Constraints sections in this codebase use NEVER as a signaling convention (see CLAUDE.md: "Constraints must start with NEVER or define hard limits")

### Option B: DRY for Process steps, keep brief summary in Constraints

Replace the 5 Process-step occurrences (Step 6 sub-bullet in publisher, Step 4 in block-handler, Step 4b in fix-ticket, Step 5a in implement-feature, Steps 3b/X in fix-bugs) with the short reference phrase. But keep a condensed version in publisher.md's Constraints section:

```
- NEVER use `\n` as a line separator in MCP tool parameters -- use actual newlines. See `core/mcp-body-formatting.md` for the full construction rule.
```

**Pros:**
- Process steps stay DRY (contract reference only)
- Constraints section retains the NEVER convention and a one-sentence explanation
- A contributor reading publisher.md understands the rule without opening another file
- The contract file remains the authoritative source for the full rule and "Applies To" list

**Cons:**
- Minor duplication: one sentence in publisher.md overlaps with the contract
- One file (publisher.md) has a different pattern than the other 4 files

### Option C: Keep inline everywhere (no contract)

Do not create the contract file. Keep the existing inline text.

**Pros:** Maximum in-context readability.
**Cons:** 7 copies to maintain. Violates the DRY direction the codebase has been moving toward (core/ contracts were introduced specifically to centralize repeated patterns).

### My Recommendation: Option B (DRY steps + brief Constraints summary)

Here is my reasoning:

1. **Process steps are procedural.** When the LLM is executing Step 6 of publisher.md, it follows instructions sequentially. A reference to `core/mcp-body-formatting.md` is perfectly adequate -- the model will open the file and follow it. Process steps do not need to be self-contained for human readability; they are execution instructions.

2. **Constraints sections are reference material.** A contributor (or the LLM on first read) scans Constraints to understand the agent's hard limits. Constraints that say "Follow file X" without explaining what the constraint actually IS are opaque. The NEVER convention exists precisely so that a reader can scan the Constraints section and immediately see the hard boundaries. Replacing a NEVER rule with "Follow a contract" breaks that scanning pattern.

3. **The overhead is minimal.** One condensed sentence in one file (publisher.md) is not a maintenance burden. The contract file is authoritative; the Constraints summary is a signpost. If the rule changes, you update the contract file. The Constraints summary ("do not use `\n` in MCP parameters") is stable enough that it is unlikely to diverge.

4. **Precedent in the codebase.** Look at how `core/status-verification.md` is referenced. Process steps say "follow `core/status-verification.md`" but the Constraints section of status-verification.md itself spells out the NEVER rules. The agent files that call it do NOT lose their own NEVER rules about blocking, retrying, etc. The pattern is: detailed rules live in the contract, process steps reference the contract, but agent-level constraints remain stated at the agent level when they are hard limits.

### Concrete Proposal for publisher.md Constraints

**Current (Constraint bullet 5):**
```
- NEVER use the literal characters `\n` in any MCP tool parameter that accepts multi-line text (PR description, issue comments). Always construct multi-line strings with actual line breaks (real newlines). The MCP tool receives the parameter value as-is — escaped sequences like `\n` are rendered literally, not as newlines.
```

**Proposed:**
```
- NEVER use `\n` as a line separator in MCP tool parameters — use actual newlines. See `core/mcp-body-formatting.md` for the full formatting rule.
```

This preserves the NEVER signaling, states the constraint in one sentence, and points to the contract for the full explanation. The other 4 files (block-handler, fix-ticket, implement-feature, fix-bugs) use the reference-only phrase from the research, which is correct because those are all Process-step contexts, not Constraints sections.

### Impact on the Test

The test `mcp-newline-handling.sh` needs updating either way. The research proposal (Check A: contract contains NEVER rule + Check B: 5 files reference contract) works for both Option A and Option B. Under Option B, publisher.md would match both checks (it references the contract AND contains a condensed NEVER). The test logic from the research is compatible.

---

## Item 3: fix-bugs "On Start Set" Step

### The Consistency Imperative

fix-ticket Step 1 says:

```
### 1. Set issue tracker

Set the state per Automation Config (Issue Tracker → On start set). Read Type for the correct MCP server.

After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

*In dry-run: skip this step.*
```

The research proposes adding Step 1a to fix-bugs with nearly identical wording:

```
### 1a. Set issue tracker

Set the state per Automation Config (Issue Tracker → On start set). Read Type for the correct MCP server.

After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

*In dry-run: skip this step.*
```

### Why "1a" Is the Right Label

The research resolved this correctly. Using "1a" avoids renumbering existing steps, which would cascade into the stage mapping table, the worktree range, all "Block handler (step X)" references, and potentially resume-ticket's step references. The cost of renumbering is high; the cost of "1a" is that it looks slightly unusual. But this codebase already uses sub-step labels (3a, 3b, 3c, 3d, 3e, 5a, 5b, 6a, 7a, 7b, 7c, 7d, 7e, 8a, 8b, 8c). A "1a" fits the convention perfectly.

### My Recommendation: Match fix-ticket Exactly

The research proposal has the right wording. I want to highlight three things that matter for DX:

**1. Heading consistency.** fix-ticket uses `### 1. Set issue tracker`. fix-bugs should use `### 1a. Set issue tracker`. The heading text ("Set issue tracker") is identical. A contributor who knows fix-ticket will immediately recognize the pattern. This is the right call.

**2. No Feature Workflow fallback.** fix-ticket does not mention Feature Workflow because it is a bug pipeline. fix-bugs is also a bug pipeline. The research correctly omits the Feature Workflow fallback from the step text. implement-feature's Step 1 says "Feature Workflow -> On start set (fallback: Issue Tracker -> On start set)" because it IS a feature pipeline. fix-bugs says "Issue Tracker -> On start set" because it processes bugs. This distinction is semantically correct and should not be normalized.

**3. Worktree range update.** The research proposes changing "steps 2-8" to "steps 1a-8" in the worktree parallel execution section. This is correct. Step 1a must run per-bug inside each Task because each bug needs its own status transition. The worktree section dispatches Tasks that execute the per-bug pipeline, so the range must include 1a.

**4. Dry-run prose range.** The research notes that the dry-run prose says "steps 1-3, no side effects: no issue tracker state changes." Step 1a makes an issue tracker state change and is therefore implicitly skipped by the "no issue tracker state changes" clause. The research is right that no change to "steps 1-3" text is needed because 1a is numerically within that range AND the prose explicitly excludes state changes. A future contributor reading the dry-run section will see "no issue tracker state changes" and correctly infer that 1a is skipped.

### One Concern: Step Placement Within the Per-Bug Loop

The research says Step 1a fires "per-bug within the processing loop, before triage." This means in the sequential variant (no worktrees), the flow is: Step 1 fetches all bugs, then for each bug: Step 1a sets state, Step 2 triages, etc. The step is inserted between Step 1 (Fetch bugs) and Step 2 (Triage) in the file's section order, but in the Variant B (sequential) execution, Step 1a runs inside the per-bug iteration.

The current file structure does not have an explicit "per-bug loop starts here" marker for the sequential variant. Variant B says "For each bug: run steps 2-8." With the range update to "steps 1a-8," this becomes implicit. A contributor reading the sequential variant will see "steps 1a-8" and know that 1a is inside the loop.

However, for Variant A (worktrees), the parallel section says "Run the pipeline (steps 1a-8) for EVERY bug in the batch IN PARALLEL." This is clear. Each Task gets the full 1a-8 range.

Both variants handle the new step correctly after the range update. No additional prose is needed.

---

## Summary of Recommendations

| Item | Recommendation | Key Trade-off |
|------|---------------|---------------|
| 1: Status Verification | Uniform reference sentence at all 4 sites | Consistency wins over per-site context; sentence is already self-documenting |
| 2: MCP Formatting | DRY for Process steps; keep condensed NEVER summary in publisher.md Constraints | Constraints sections must remain scannable; one-sentence summary is not a maintenance burden |
| 3: fix-bugs On Start Set | Match fix-ticket wording exactly; use "1a" label; update worktree range | Identical wording across pipelines is the strongest DX signal for pattern recognition |

### Dissent from Research on Item 2

The research proposes full DRY for all 7 replacements (Option A). I disagree on replacement #2 (publisher.md Constraints). My Option B keeps a condensed NEVER rule in the Constraints section. This is a minor disagreement -- the contract file is created either way, and the other 6 replacements are identical. The only difference is whether publisher.md's Constraints section retains a one-sentence summary or becomes a pure reference.

If the judge prefers full DRY consistency (Option A), I will not object strongly. The readability cost is real but not severe -- a contributor reading publisher.md's Constraints will see "Follow `core/mcp-body-formatting.md`..." and can open the file. My concern is that this breaks the NEVER-scanning convention, but the convention is a style preference, not a hard requirement.

### Agreement with Research on All Other Points

The research's edit strings, insertion points, file inventory, test updates, and CLAUDE.md core count update (12 -> 13) are all correct and well-specified. I have no modifications to propose for Items 1 or 3 beyond confirming the approach.
