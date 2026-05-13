# Phase 2: Research Synthesis

## Persona
You are a **DevOps tooling specialist** synthesizing research findings from Phase 1 into actionable conclusions for fixing three issues in the `check-setup` skill.

## Task Instructions

Review the Phase 1 research answers and synthesize them into a coherent technical plan:

1. **TLS Diagnostic Design:** Based on Q1 findings, define the exact diagnostic flow for Block 3 step 9. Specify:
   - The trigger condition (what error text indicates "fetch failed" vs auth error vs timeout)
   - The curl diagnostic command and its interpretation
   - The exact output strings for each failure mode
   - Whether `NODE_OPTIONS: "--use-system-ca"` is the correct recommendation

2. **SC Connectivity Simplification:** Based on Q2 findings, decide:
   - Whether to remove the `read:user` scope check entirely or downgrade to [INFO]
   - How to reword step 10 to accurately describe what the pipeline does
   - Whether the output format section needs updating

3. **Path Resolution Strategy:** Based on Q3 findings, decide:
   - The exact path resolution mechanism to use
   - Whether to add a preamble note or modify each reference inline
   - How other skills handle the same problem (pattern reuse)

4. **Integration Check:** Verify that the three fixes are mutually compatible and don't create new inconsistencies with:
   - The output format section (lines 88-112)
   - The rules section (lines 127-132)
   - Other skills that reference check-setup output (e.g., `skills/status/SKILL.md`)

## Success Criteria
- Clear decision for each of the 3 issues with rationale
- Exact text for new/modified output strings
- No conflicts with existing output format or rules
- Path resolution approach validated against other skills in the repo

## Anti-Patterns
- Do NOT introduce new dependencies or file reads that would slow down check-setup
- Do NOT change the overall structure of the 5-block check-setup flow
- Do NOT add new blocks or fundamentally restructure the skill
- Do NOT recommend `NODE_TLS_REJECT_UNAUTHORIZED=0` -- this disables all TLS verification

## Codebase Context
- Target: `skills/check-setup/SKILL.md` -- 5 blocks (Automation Config, MCP servers, Connectivity, Build & Test, Plugin Composability)
- Output format has specific [OK]/[FAIL]/[WARN]/[SKIP] prefix convention
- Rules: read-only, read-only MCP queries, placeholder detection, safe for repeated execution
- The skill has `allowed-tools: mcp__*, Read, Glob, Grep, Bash` -- curl via Bash is available
