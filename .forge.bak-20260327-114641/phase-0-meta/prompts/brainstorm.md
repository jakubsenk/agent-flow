# Phase 3 — Brainstorming

## Personas

Three heterogeneous expert personas will evaluate the implementation approach:

### Persona 1: The Conservative Incrementalist

{{PERSONA_1}}: You are a **Senior DevOps Platform Engineer** with 15 years of experience maintaining CLI tools used by thousands of developers. You prioritize backward compatibility, minimal diff size, and zero regression risk above all else. You are skeptical of any change that touches more than 3 files and always ask "what breaks if we miss something?" You favor surgical, scoped changes over sweeping rewrites. Your mantra: "The safest change is the smallest change that works."

### Persona 2: The Innovative UX Designer

{{PERSONA_2}}: You are a **Developer Experience Architect** who designs CLI workflows for maximum ergonomics and delight. You think about the user's mental model first and implementation second. You see the scaffold infrastructure gap as a fundamental UX failure — the user creates a project and immediately hits a wall of broken connections. You favor bold redesigns that eliminate friction entirely, even if they require touching many files. Your mantra: "If the user has to run a second command, we failed."

### Persona 3: The Skeptical Systems Thinker

{{PERSONA_3}}: You are a **Distributed Systems Architect** who evaluates designs for hidden coupling, failure mode coverage, and state management correctness. You are skeptical that MCP verification during scaffold will work reliably across all 6 tracker types and 3 operating systems. You focus on what happens when things go wrong — network failures, missing tokens, partial states. You probe for edge cases the design document did not address. Your mantra: "Show me your error paths."

## Task Instructions

{{TASK_INSTRUCTIONS}}:

Using the research findings from Phase 2, each persona independently evaluates the implementation approach for the Scaffold Infrastructure Integration (v5.5.0). The task involves:

1. Adding Step 0-INFRA (infrastructure declaration) and Step 0-MCP (MCP verification) before Mode Selection
2. Modifying Step 4 (Git Init) to auto-fill CLAUDE.md from MCP data and generate .mcp.json.example
3. Adding Step 4d (push to remote) and Step 4e (create tracker issues)
4. Removing Steps 4b, 4c, and 9
5. Modifying Step 10 (Final Report) to show infrastructure status
6. Updating all documentation files that reference scaffold steps

### Each Persona Must Address

1. **Implementation ordering** — In what order should files be modified? Should scaffold.md be done first or documentation first?
2. **Step 0-INFRA placement** — The design says "before Mode Selection". Should it go before or after State Detection? What about the `--no-implement` early exit?
3. **init.md inline invocation** — How should scaffold invoke /init? Task tool? Embedded logic? Partial init?
4. **Documentation update strategy** — How to ensure all references are caught and updated consistently?
5. **Step numbering** — The new steps use "0-INFRA" and "0-MCP" naming. Is this consistent with existing conventions (0, 0b) or does it introduce a new pattern?
6. **Testing** — How to verify the changes are correct given the test harness is structural only?
7. **Risk mitigation** — What is the most likely thing to go wrong?

### Deliverable Per Persona

Each persona produces:
- A ranked list of implementation risks (top 3)
- A recommended file modification order
- One specific concern or improvement the design missed
- A GO/NO-GO recommendation for proceeding to specification

## Success Criteria

{{SUCCESS_CRITERIA}}:
- All three personas produce substantively different perspectives (not minor variations)
- At least one persona identifies a risk or gap not in the original design document
- The file modification order accounts for documentation consistency
- The init.md inline invocation question gets three different proposed solutions
- Each persona's recommendation is actionable (not just "be careful")

## Anti-Patterns

{{ANTI_PATTERNS}}:
- DO NOT let all three personas agree on everything — disagreement is the point
- DO NOT ignore the documentation update challenge — it is the hardest part of this task
- DO NOT propose changes to agents or the Automation Config contract — those are explicitly out of scope
- DO NOT suggest creating new files beyond what the design specifies (no new agents, no new commands)
- DO NOT skip the init.md compatibility analysis — it is a critical design decision
- DO NOT forget that `docs/plans/*.md` are historical and MUST NOT be modified

## Codebase Context

{{CODEBASE_CONTEXT}}:
- **Scope:** ~8 files modified (scaffold.md primary, 6-7 documentation files, CHANGELOG.md)
- **Constraint:** Pure markdown — no runtime code, no tests to run, no build to break
- **Convention:** Step numbering uses integers (0, 1, 2...) with letter suffixes for sub-steps (0b, 4b, 4c, 4d, 4e)
- **Risk area:** Cross-file documentation consistency — scaffold step references appear in CLAUDE.md, README.md, docs/architecture.md, docs/reference/pipelines.md, docs/reference/commands.md
- **Safe area:** agents/, skills/, core/, examples/ — no changes needed
- **Design spec:** `docs/plans/2026-03-27-scaffold-infrastructure-design.md` — approved, detailed, explicit
- **CHANGELOG convention:** MINOR releases use "### Added" and "### Changed" sections with bold item titles
