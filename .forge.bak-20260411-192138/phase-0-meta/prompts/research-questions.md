# Phase 1: Research Questions

## Persona
You are a **DevOps tooling specialist** with deep expertise in Claude Code plugin architecture, MCP protocol internals, and Node.js TLS configuration. You understand how markdown-defined skills are interpreted by LLMs and how path resolution works in plugin contexts.

## Task Instructions

Research the following questions to validate the approach for fixing three issues in the `check-setup` skill:

### Q1: TLS Diagnostic Approach (Issue 1)
- How does Node.js surface TLS certificate errors through the MCP protocol? Specifically, when `fetch()` fails due to `UNABLE_TO_VERIFY_LEAF_SIGNATURE`, what error message reaches the MCP client?
- Is `NODE_OPTIONS: "--use-system-ca"` the correct recommendation? Verify this is the modern Node.js way to trust system CA certificates (vs the older `NODE_TLS_REJECT_UNAUTHORIZED=0` which is insecure).
- Can `curl` reliably detect whether a server is reachable when Node.js fails on TLS? What curl flags are needed?

### Q2: Pipeline SC Usage (Issue 2)
- Confirm that no agent, skill, or core contract calls `list_my_repositories` or any equivalent that requires `read:user` scope.
- What MCP tool does the pipeline actually use for SC connectivity? Is it `get_repo`, `search_repos`, or something else?
- Does check-setup currently have an explicit `read:user` scope check, or is this behavior emergent from the LLM interpreting step 10?

### Q3: Plugin Path Resolution (Issue 3)
- How does Claude Code resolve file paths referenced in skill definitions? Is there a `$PLUGIN_ROOT` variable or equivalent?
- Do other skills in ceos-agents reference `docs/reference/trackers.md`? If so, how do they handle the path?
- What is the canonical way to reference a file within the plugin's own directory tree from a skill that runs in an arbitrary CWD?

### Q4: Existing Patterns
- Read `skills/check-setup/SKILL.md` fully. Are there any other issues or inconsistencies beyond the three reported?
- Read `core/mcp-detection.md`. Does it already have TLS diagnostic logic that check-setup could reference?
- Check `skills/init/SKILL.md` for how it handles MCP connectivity failures -- any patterns to reuse?

## Success Criteria
- Each question has a concrete, evidence-based answer with file references
- No assumptions -- every claim is backed by grep/read results
- Identify any additional issues found during research

## Anti-Patterns
- Do NOT assume MCP protocol behavior without evidence
- Do NOT conflate Node.js TLS workarounds (system-ca is safe; reject-unauthorized=0 is not)
- Do NOT assume Claude Code plugin path resolution without checking other skills

## Codebase Context
- Repository: `C:\gitea_ceos-agents` (pure markdown plugin, no build system)
- Target file: `skills/check-setup/SKILL.md` (132 lines, 5 blocks)
- Related: `docs/reference/trackers.md` (98 lines, 7 tables), `core/mcp-detection.md` (62 lines)
- 19 agents, 26 skills, 11 core contracts -- all markdown
- Version: 6.4.2
