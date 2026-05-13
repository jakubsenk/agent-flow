# Phase 3 — Specification

## Persona
{{PERSONA}}
You are a senior DevOps engineer specializing in cross-platform CLI tooling, binary distribution, and developer environment setup automation. You have deep experience with Go toolchain, curl-based binary downloads, and platform-specific installation quirks.

## Task Instructions
{{TASK_INSTRUCTIONS}}

### Objective
Write a precise specification for fixing the silent forgejo-mcp download failure on Windows in the ceos-agents init skill.

### Requirements

**REQ-1: Download Validation (skills/init/SKILL.md)**
After step 4 (download binary) and before step 6 (verify download), add a new validation step that checks the downloaded file is a legitimate binary:
- Check file size is greater than 1 MB (`stat` or `wc -c` depending on platform)
- If size check fails: delete the invalid file, proceed to Windows fallback (REQ-2) or manual fallback (existing)

**REQ-2: Windows Go-Install Fallback (skills/init/SKILL.md)**
When download validation fails AND platform is Windows:
1. Check if Go is available: `go version`
2. If Go is available: run `GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp@{tag}`
3. Rename resulting binary if needed (Go produces `forgejo-mcp.exe` in GOBIN)
4. Verify the Go-built binary exists and passes size check
5. If Go is NOT available OR go install fails: display clear error message with manual instructions:
   - "forgejo-mcp does not publish Windows binaries. Install Go (https://go.dev/dl/) and run: go install codeberg.org/goern/forgejo-mcp@latest"
   - Then fall back to manual path collection

**REQ-3: Documentation — mcp-configuration.md**
Update the Windows install line (~line 48) to warn that Windows binary is not officially available and recommend `go install` as the installation method.

**REQ-4: Documentation — installation.md**
Add a note under the Windows platform section explaining that forgejo-mcp requires building from source on Windows via `go install`.

### Constraints
- All changes are markdown only — no runtime code
- Preserve existing fallback-to-manual behavior as ultimate last resort
- Do not remove Linux/macOS download paths — those work correctly
- The `go install` fallback should use the same tag fetched in step 3, not `@latest`, for version consistency
- Size threshold of 1 MB is conservative — real Go binaries are 10-30 MB

## Success Criteria
{{SUCCESS_CRITERIA}}
1. After applying the fix, running /ceos-agents:init on Windows with Gitea tracker will NOT silently save a 10-byte error page as forgejo-mcp.exe
2. If Go is installed on Windows, forgejo-mcp will be built from source automatically
3. If Go is NOT installed on Windows, user gets a clear, actionable error message
4. Documentation accurately reflects that Windows has no prebuilt binary
5. Linux and macOS download paths remain unchanged and functional

## Anti-Patterns
{{ANTI_PATTERNS}}
- DO NOT use `file` command for binary validation — it may not be available on Windows (Git Bash)
- DO NOT assume Go is always installed — it must be a checked fallback, not a hard requirement
- DO NOT change the download URL or remove the download attempt — it should still try first (future-proofing for when upstream adds Windows)
- DO NOT add complex PE header parsing — size check is sufficient and portable
- DO NOT break the existing manual-path-collection fallback — it must remain as the ultimate fallback

## Codebase Context
{{CODEBASE_CONTEXT}}
- **Repository:** ceos-agents — pure markdown plugin for Claude Code
- **File 1:** `skills/init/SKILL.md` — declarative skill definition that Claude Code interprets and executes. Steps are numbered instructions with embedded bash code blocks. Lines 150-193 contain the forgejo-mcp download logic.
- **File 2:** `docs/guides/mcp-configuration.md` — reference doc for MCP server setup. Line 48 has incorrect Windows install instructions.
- **File 3:** `docs/guides/installation.md` — getting-started guide. Lines 68-82 have platform notes section.
- **Architecture:** Skills contain instructions (WHAT to do); Claude Code reads and executes them. Changes must be clear, unambiguous markdown instructions with bash code blocks where needed.
