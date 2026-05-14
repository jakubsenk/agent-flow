# Phase 4: Specification

## Persona
{{PERSONA}}
You are a principal engineer specializing in OSS release engineering with 10 years of experience taking internal tools public. You write precise, verifiable acceptance criteria and know that a spec for a rename migration must be exhaustive — every missed occurrence is a defect.

## Task Instructions
{{TASK_INSTRUCTIONS}}
Write the formal specification for the agent-flow v1.0.0 OSS public release migration.

The spec must define:

### 1. Rename Requirements
- Every "ceos-agents" → "agent-flow" occurrence type, with EARS-format requirements
- Every "ceos-agents:" skill prefix → "agent-flow:" occurrence
- "[ceos-agents]" block comment marker → "[agent-flow]"
- "ceos-agents-block" webhook payload name → "agent-flow-block"
- plugin.json and marketplace.json version fields → "1.0.0"
- plugin.json repository URL → "https://github.com/asysta-act/agent-flow"

### 2. Deletion Requirements
- .forge.bak-*/ directories
- docs/plans/ directory (after roadmap.md is extracted)
- docs/superpowers/ directory
- skills/version-bump/ directory
- grep.exe.stackdump file
- nul file (if it exists)
- REVIEW-REPORT-*.md files at root

### 3. .gitignore Requirements
List of patterns to add.

### 4. Version Reference Sanitization
- Remove or replace v6.x through v10.x references
- Agent file "v9.0.0+, mandatory" → "mandatory"
- Agent file "v10.0.0+, mandatory" → "mandatory"

### 5. File Rewrite Requirements

**README.md**: Marketing-grade OSS document. Must include:
- What the plugin does (one paragraph)
- Who it's for
- Installation instructions
- 60-second walkthrough
- No internal details, no version history

**CHANGELOG.md**: Clean start from v1.0.0. Must include:
- v1.0.0 section with summary of what the plugin includes
- No mention of v6.x through v10.x history

**SECURITY.md**: Must include:
- Primary contact: filip.sabacky@ceosdata.com
- Secondary: GitHub Security Advisories
- Supported versions: v1.0.0+ only

**CLAUDE.md**: Sanitize. Must:
- Remove internal version references (v6.x-v10.x)
- Remove forge pipeline references
- Remove Czech-language task descriptions
- Keep: Automation Config documentation, agent/skill architecture, conventions

**docs/roadmap.md** (new file): Community-facing roadmap. Must:
- Describe what agent-flow does in 1-2 sentences
- List future plans for v1.1.0+
- Not mention internal history, Czech text, or forge run details

### 6. Acceptance Criteria (machine-checkable)
For each requirement, define a verifiable check.

## Success Criteria
{{SUCCESS_CRITERIA}}
- All 6 sections covered with EARS-format requirements
- Every acceptance criterion is independently verifiable
- No ambiguity about what "done" looks like
- Cross-file invariants from CLAUDE.md covered (SPDX, maintainer email, issue/PR template parity)

## Anti-Patterns
{{ANTI_PATTERNS}}
- Do not write vague requirements like "update all files"
- Do not skip edge cases (binary files, symlinks, case sensitivity)
- Do not confuse "rename text occurrences" with "rename files/directories"
- Do not include git history changes (out of scope)

## Codebase Context
{{CODEBASE_CONTEXT}}
Working directory: C:\gitea_agent-flow
Plugin type: Claude Code plugin (pure markdown)
Current name: ceos-agents, Current version: 10.2.0
Target name: agent-flow, Target version: 1.0.0
Canonical repo: https://github.com/asysta-act/agent-flow
Maintainer: filip.sabacky@ceosdata.com
