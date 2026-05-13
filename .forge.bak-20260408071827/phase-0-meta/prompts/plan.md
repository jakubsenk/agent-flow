# Phase 6 — Implementation Plan

## Persona
{{PERSONA}}
You are a senior software engineer experienced in maintaining developer tooling plugins. You write precise, minimal diffs that fix the root cause without over-engineering. You understand that this codebase is pure markdown — changes are instructions, not code.

## Task Instructions
{{TASK_INSTRUCTIONS}}

### Objective
Create a step-by-step implementation plan for fixing the forgejo-mcp Windows download bug across 3 files.

### Task Graph

```
Task 1: Fix download validation in SKILL.md (CRITICAL PATH)
  ├── 1a: Add size-based validation after download step
  ├── 1b: Add Windows Go-install fallback section
  └── 1c: Update verify-download step to reference new validation

Task 2: Update mcp-configuration.md (INDEPENDENT)
  └── 2a: Rewrite Windows install line with warning + go install instructions

Task 3: Update installation.md (INDEPENDENT)
  └── 3a: Add forgejo-mcp Go build note to Windows platform section
```

**Parallelization:** Tasks 1, 2, and 3 are independent and can be executed in parallel. Within Task 1, subtasks are sequential (1a → 1b → 1c).

### Detailed Changes

#### Task 1a: Add download validation (skills/init/SKILL.md, after line ~177)
Insert a new step between "Download binary" (step 4) and "Set permissions" (step 5):
- New step: **Validate download** — check file size > 1 MB
- Use platform-appropriate size check:
  - Linux/macOS: `stat -f%z` or `wc -c < file`
  - Windows (Git Bash): `stat --format=%s` or `wc -c < file`
  - Universal: `wc -c < ~/.claude/bin/{binary_name}` works everywhere
- If size < 1048576 (1 MB): delete the file (`rm ~/.claude/bin/{binary_name}`), mark download as failed

#### Task 1b: Add Windows Go-install fallback (skills/init/SKILL.md, after validation step)
Insert a conditional section after validation failure on Windows:
- Check `go version` availability
- Run `GOBIN=$(cygpath -u "$USERPROFILE")/.claude/bin go install codeberg.org/goern/forgejo-mcp@{tag}` (use cygpath for Git Bash compatibility, or simpler: `GOBIN=~/.claude/bin go install ...`)
- Verify the go-built binary exists and passes size validation
- If Go unavailable or build fails: clear error message, then fall to manual path collection

#### Task 1c: Update verify step (skills/init/SKILL.md, line ~179)
Renumber steps. Update the existing verify step (was step 6) to reflect new flow.

#### Task 2a: Update mcp-configuration.md (line ~48)
Replace:
```
- **Windows install:** Download `forgejo-mcp-windows-amd64.exe`, save as `bin/forgejo-mcp.exe`
```
With a note explaining that Windows binaries are not published upstream and providing `go install` instructions.

#### Task 3a: Update installation.md (lines ~68-72)
Add to the Windows platform section a note about forgejo-mcp requiring Go to build from source, with the `go install` command.

### Risk Mitigation
- Keep the download attempt even on Windows (future-proofing)
- Preserve manual fallback as ultimate last resort
- Use `wc -c` for size check — most portable across all shells
- Test the renumbered steps for consistency

## Success Criteria
{{SUCCESS_CRITERIA}}
1. SKILL.md contains download validation with 1 MB threshold
2. SKILL.md contains Windows-specific Go fallback with clear error on Go absence
3. mcp-configuration.md warns about missing Windows binary
4. installation.md documents Go requirement for Windows forgejo-mcp
5. All existing functionality (Linux, macOS, manual fallback) unchanged
6. Step numbering in SKILL.md is consistent after insertions

## Anti-Patterns
{{ANTI_PATTERNS}}
- DO NOT refactor unrelated parts of SKILL.md — minimal diff principle
- DO NOT add Go as a prerequisite in Step 2 checks — it is only needed for Windows Gitea users
- DO NOT use Windows-specific commands (PowerShell, cmd) — Git Bash is the assumed shell
- DO NOT remove the curl download attempt on Windows — upstream may add Windows support later
- DO NOT change step numbering beyond what is necessary for the insertion

## Codebase Context
{{CODEBASE_CONTEXT}}
- `skills/init/SKILL.md`: 220+ line skill definition. Steps 1-8. The forgejo-mcp section is within Step 5 (lines 150-193). Steps are numbered with bold headers.
- `docs/guides/mcp-configuration.md`: ~156 lines. Gitea section at lines 45-51.
- `docs/guides/installation.md`: ~82 lines. Platform Notes section at lines 66-82.
- Convention: Skill instructions use numbered steps, bash code blocks, bold labels, and conditional branches clearly marked.
