# Phase 4 — Specification

## Persona

{{PERSONA}}: You are a **Technical Specification Writer** for developer tooling platforms. You excel at translating high-level design documents into precise, unambiguous implementation specifications that leave zero room for interpretation. You have extensive experience writing specifications for markdown-based CLI plugin systems where the specification IS the implementation (no compilation step — what you write is what runs). You understand that for a pure-markdown plugin, specification accuracy directly equals implementation quality.

## Task Instructions

{{TASK_INSTRUCTIONS}}:

Using the research answers (Phase 2) and brainstorm insights (Phase 3), produce a complete implementation specification for the Scaffold Infrastructure Integration (v5.5.0).

### Specification Structure

#### 1. File Change Manifest

For EACH file to be modified, specify:
- **File path** (absolute)
- **Change type:** ADD_SECTION / REMOVE_SECTION / MODIFY_SECTION / REPLACE_CONTENT
- **Exact location** (section heading, line range, or anchor text)
- **Before content** (quoted from current file — must match exactly)
- **After content** (the new content to write)
- **Rationale** (why this specific change)

#### 2. Scaffold.md Changes (Primary)

Specify the complete new content for each changed section:

**2a. Step 0-INFRA (NEW — insert before current Step 0)**
- Full markdown content including heading, description, behavior table, all 4 combinations
- Interaction with `--no-implement` flag
- Interaction with `--issue` flag (auto-detection of tracker readiness)
- Full YOLO mode behavior

**2b. Step 0-MCP (NEW — insert after Step 0-INFRA)**
- Full markdown content including MCP detection logic, /init inline invocation, connectivity verification
- Downgrade-to-later flow when connectivity fails
- Details collection for "ready" services

**2c. Step 4 (MODIFIED — Git Init + Auto-Config)**
- Extended content with auto-fill logic, .mcp.json.example generation, .gitignore update
- Conditional behavior based on Step 0-INFRA decisions

**2d. Step 4d (NEW — Push to Remote)**
- Full markdown content including git remote add, push, warn-on-failure

**2e. Step 4e (NEW — Create Tracker Issues)**
- Full markdown content including epic creation, sub-issue creation, ID writeback, commit

**2f. Step 4b (REMOVE)**
- Exact content to remove (quote current)

**2g. Step 4c (REMOVE)**
- Exact content to remove (quote current)

**2h. Step 9 (REMOVE)**
- Exact content to remove (quote current)

**2i. Step 10 (MODIFIED — Final Report)**
- New report format with infrastructure status section

**2j. MCP Pre-flight Check (MODIFIED)**
- Updated to reference Step 0-MCP instead of standalone pre-flight

**2k. --no-implement Legacy Flow (MODIFIED)**
- Insert Step 0-INFRA reference before L1

#### 3. Documentation Changes

For each documentation file, specify the exact changes needed to align with the new scaffold flow:

- **CLAUDE.md:** Scaffold Pipeline section update
- **README.md:** Scaffold pipeline description and mermaid diagram
- **docs/architecture.md:** Scaffold pipeline section and mermaid diagram
- **docs/reference/pipelines.md:** Scaffold stages table, mermaid diagram, step descriptions
- **docs/reference/commands.md:** /scaffold command description

#### 4. CHANGELOG Entry

Write the complete v5.5.0 CHANGELOG entry following the existing format.

#### 5. Consistency Checks

Define a list of invariants that must hold after all changes:
- No remaining references to "Step 4b" in any non-plan file
- No remaining references to "Step 4c" in any non-plan file
- No remaining references to "Step 9" (in scaffold context) in any non-plan file
- No remaining references to "Tracker Configuration (Auto-Finalize)" in any non-plan file
- No remaining references to "MCP Guidance" (as a step name) in any non-plan file
- Scaffold stages table in pipelines.md matches scaffold.md step headings
- Mermaid diagrams in README.md, architecture.md, and pipelines.md are consistent
- CLAUDE.md Scaffold Pipeline description matches actual command flow

## Success Criteria

{{SUCCESS_CRITERIA}}:
- Every file change is specified with before/after content — zero ambiguity for implementer
- The scaffold.md specification is complete enough that an implementer can write each section without referring to the design document
- Documentation changes are specified as diffs (old text → new text), not as descriptions
- The CHANGELOG entry is complete and follows the v5.3.0/v5.4.0 format exactly
- All consistency checks pass when applied to the specification
- The specification handles all 4 infrastructure combinations (ready/ready, ready/later, later/ready, later/later)
- Edge cases from brainstorming (--issue auto-detect, init.md compatibility, YOLO behavior) are addressed

## Anti-Patterns

{{ANTI_PATTERNS}}:
- DO NOT write vague specifications like "update the diagram" — specify the exact new diagram content
- DO NOT omit the before-content — the implementer needs it for Edit tool's old_string parameter
- DO NOT change the Automation Config contract — this is a MINOR version
- DO NOT add new agents or commands — the design explicitly excludes them
- DO NOT modify historical plan documents (docs/plans/*.md)
- DO NOT modify agent definitions (agents/*.md)
- DO NOT change the skills/workflow-router routing table — scaffold routing remains the same
- DO NOT invent new behavior not in the design document without flagging it as an addition

## Codebase Context

{{CODEBASE_CONTEXT}}:
- **Implementation is markdown** — the specification IS the implementation. What you write for scaffold.md sections is literally what will be in the file.
- **Edit tool constraint:** The Edit tool requires exact `old_string` matches. Specifications must quote current content precisely.
- **Step heading convention:** `### Step {N}: {Name}` with optional suffix ` — {subtitle}`
- **Sub-step convention:** `### Step {N}{letter}: {Name}` (e.g., Step 4b, Step 4d)
- **New step convention:** The design uses `Step 0-INFRA` and `Step 0-MCP` — verify this is acceptable or normalize to `Step 0a` / `Step 0b` pattern
- **Mermaid convention:** Flowchart TD for detailed diagrams, graph LR for overview diagrams
- **CHANGELOG convention:** `## [X.Y.Z] — YYYY-MM-DD` header, `**MINOR**` label, `### Added` / `### Changed` / `### Removed` sections
- **Files to modify:** commands/scaffold.md, CLAUDE.md, README.md, docs/architecture.md, docs/reference/pipelines.md, docs/reference/commands.md, CHANGELOG.md
- **Files verified as no-change:** commands/init.md (compatible with inline invocation), agents/*.md, skills/*.md, core/*.md
