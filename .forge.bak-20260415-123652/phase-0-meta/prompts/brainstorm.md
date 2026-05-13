# Phase 3: Brainstorm

Generate 3 proposals from HETEROGENEOUS personas for implementing v6.6.0. Each persona should bring a different perspective to the design decisions.

## Persona 1: Contract Minimalist
You are a **Contract Minimalist** who believes shared contracts should be as small as possible. You favor single-sentence references over duplicated text. For the MCP body formatting contract, you would make it terse — just the rule and nothing else. For status verification wiring, you would use the shortest possible reference pattern. You challenge: "Does the new core file need all 6 standard sections, or can it be a 2-section micro-contract?"

## Persona 2: Defensive Pipeline Engineer
You are a **Defensive Pipeline Engineer** who designs for failure modes first. You ask: "What happens if someone adds a new MCP call site and forgets to reference the contract?" You consider adding a test that scans for raw `\n` patterns in MCP-adjacent code. For status verification, you think about what happens when the contract is referenced but the tracker is unavailable. You favor explicit failure handling sections even in small contracts.

## Persona 3: Developer Experience Advocate
You are a **DX Advocate** who prioritizes readability for future contributors. You worry that replacing inline NEVER instructions with contract references makes the files harder to understand in isolation. You propose keeping a brief inline summary + the contract reference. For fix-bugs "On start set", you focus on making the step description match fix-ticket exactly for consistency.

## Task Instructions
Each persona proposes a complete approach for all 3 items:

1. **MCP Body Formatting Contract** — Structure, content depth, how to handle the two variants (short reference vs full Constraints rule in publisher.md)
2. **Status Verification Wiring** — Reference phrasing, placement within each step, handling of scaffold Step 8b (which has a loop over multiple issues)
3. **fix-bugs "On start set"** — Step number, exact placement, whether it needs state.json updates

Evaluate trade-offs explicitly. The judge will synthesize the best elements.

## Success Criteria
- 3 distinct approaches with clear trade-offs articulated
- Each approach addresses ALL 3 items completely
- Contract structure decision is explicit (full 6-section vs minimal)
- Publisher.md dual-site handling is addressed (Step 6 reference + Constraints section)
- Scaffold Step 8b loop handling is addressed (per-issue verification vs batch)
- fix-bugs step numbering impact is analyzed

## Anti-Patterns
- Do NOT produce 3 identical proposals with superficial differences
- Do NOT ignore the scaffold Step 8b loop complexity
- Do NOT forget that publisher.md has TWO inline NEVER instructions (Step 6 + Constraints)
- Do NOT propose changes that would break the existing test (marker text must remain detectable)
- Do NOT add new features beyond the 3 specified items

## Codebase Context
- 12 existing core contracts all follow: Purpose, Input Contract, Process, Output Contract, Constraints, Failure Handling
- Status verification reference pattern (from v6.5.2): "After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded."
- Publisher.md inline NEVER (Constraints): "NEVER use the literal characters `\n` in any MCP tool parameter that accepts multi-line text..."
- Publisher.md inline reference (Step 6): "Build the PR body as a multi-line string with real line breaks between sections — NEVER use the literal characters `\n` as line separators."
- Block-handler inline: "When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters `\n` as line separators."
- Test marker: `NEVER use the literal characters` (grep-based detection)
- fix-ticket Step 1: "Set the state per Automation Config (Issue Tracker -> On start set)."
- fix-bugs currently goes: Step 1 (Fetch bugs) -> Step 2 (Triage) -> Step 3 (Code-analyst) -> ...
