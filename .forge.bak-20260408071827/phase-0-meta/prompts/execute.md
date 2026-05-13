# Phase 7 — Execute

## Persona
{{PERSONA}}
You are an implementation engineer executing a well-defined bugfix plan on a pure markdown codebase. You make precise edits, preserve existing formatting conventions, and verify each change structurally.

## Task Instructions
{{TASK_INSTRUCTIONS}}

### Objective
Implement the three-task plan to fix the forgejo-mcp Windows download silent failure.

### File 1: skills/init/SKILL.md

**Edit A — Replace the auto-download section (lines 166-181)**

Replace the current auto-download steps with an enhanced version that includes:

1. Steps 1-4 remain the same (check installed, create dir, fetch tag, download)
2. NEW Step 5 — **Validate download:** After downloading, check file size:
   ```bash
   file_size=$(wc -c < ~/.claude/bin/{binary_name} | tr -d ' ')
   if [ "$file_size" -lt 1048576 ]; then
     rm -f ~/.claude/bin/{binary_name}
     echo "Download invalid (${file_size} bytes) — asset may not exist for this platform."
   fi
   ```
   - If validation fails (file deleted): on Windows → proceed to Go fallback; on Linux/macOS → fall back to manual path collection
3. NEW Step 5a (Windows only) — **Go-install fallback:**
   ```
   If platform is Windows AND download validation failed:
   1. Check if Go is available: `go version`
   2. If Go available:
      - Run: `GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp@{tag}`
      - Verify: check that ~/.claude/bin/forgejo-mcp.exe exists and size > 1 MB
      - Success → Display: "Built forgejo-mcp {tag} from source via go install"
      - Failure → Display error, fall to manual path collection
   3. If Go NOT available:
      - Display: "forgejo-mcp does not publish pre-built Windows binaries. To install automatically, install Go from https://go.dev/dl/ and re-run /ceos-agents:init. Alternatively, build manually: go install codeberg.org/goern/forgejo-mcp@{tag}"
      - Fall to manual path collection
   ```
4. Step 6 (was 5) — Set permissions (Linux/macOS only) — unchanged
5. Step 7 (was 6) — Verify download — update to reference the validated binary

**Important formatting rules:**
- Maintain the existing markdown style: numbered list items with bold labels and code blocks
- Keep the "Manual path collection" fallback section intact
- Do not renumber sections outside of the auto-download block

### File 2: docs/guides/mcp-configuration.md

**Edit B — Replace line 48**

Replace:
```
- **Windows install:** Download `forgejo-mcp-windows-amd64.exe`, save as `bin/forgejo-mcp.exe`
```

With:
```
- **Windows install:** Pre-built Windows binaries are not published upstream. Install Go (https://go.dev/dl/) and run: `GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp@latest`, then use `~/.claude/bin/forgejo-mcp.exe`. Alternatively, run `/ceos-agents:init` which handles this automatically.
```

### File 3: docs/guides/installation.md

**Edit C — Update Windows platform section (after line 70)**

After the line "The procedure described above is for Windows. Paths use `~/` notation (Git Bash / WSL).", add:

```
- Forgejo MCP server (for Gitea tracker): pre-built Windows binaries are not available upstream. Install Go from [go.dev/dl](https://go.dev/dl/) and run `go install codeberg.org/goern/forgejo-mcp@latest`. The `/ceos-agents:init` command handles this automatically when Go is available.
```

### Execution Order
1. Edit File 1 (SKILL.md) — largest change, critical path
2. Edit File 2 (mcp-configuration.md) — independent, small
3. Edit File 3 (installation.md) — independent, small

Steps 2 and 3 can be done in parallel after step 1.

### Post-Edit Verification
After all edits:
1. Read the modified sections of each file to confirm formatting
2. Verify step numbering consistency in SKILL.md
3. Verify no broken markdown links
4. Run `./tests/harness/run-tests.sh` to check for regressions

## Success Criteria
{{SUCCESS_CRITERIA}}
1. `skills/init/SKILL.md` contains download size validation with 1 MB threshold
2. `skills/init/SKILL.md` contains Windows Go-install fallback with error handling
3. `docs/guides/mcp-configuration.md` warns about missing Windows binary
4. `docs/guides/installation.md` documents Go requirement for Windows + Gitea
5. No formatting or numbering errors in modified files
6. Test suite passes (no regressions)

## Anti-Patterns
{{ANTI_PATTERNS}}
- DO NOT use `Edit` tool with non-unique old_string — always include enough context for uniqueness
- DO NOT change lines outside the specified sections
- DO NOT break the existing manual-path-collection fallback
- DO NOT introduce Windows-specific commands (use Git Bash compatible syntax)
- DO NOT add trailing whitespace or change line endings
- DO NOT modify the YAML frontmatter of SKILL.md

## Codebase Context
{{CODEBASE_CONTEXT}}
- `skills/init/SKILL.md`: ~220 lines. YAML frontmatter (lines 1-6), Steps 0-8. Target: Step 5 forgejo-mcp section (lines 150-193).
- `docs/guides/mcp-configuration.md`: ~156 lines. Target: line 48 (Windows install).
- `docs/guides/installation.md`: ~82 lines. Target: lines 68-72 (Windows platform notes).
- All files are UTF-8 markdown. Line endings are LF (Unix-style even on Windows).
