# Phase 6 — Implementation Plan

## Task Graph

```
task-001: Fix SKILL.md download logic [CRITICAL PATH]
  ├── Depends on: none
  ├── Files: skills/init/SKILL.md
  ├── Changes: Replace Auto-download section (lines 166-181)
  │   - Add --fail flag to curl (-sfL instead of -sL)
  │   - Add file size validation step (wc -c, threshold 102400 bytes)
  │   - Insert Windows Go install fallback (steps 8a-8c)
  │   - Add non-Windows failure fallback (step 9)
  │   - Preserve manual path collection unchanged
  └── AC: AC-1, AC-2, AC-3

task-002: Update mcp-configuration.md [PARALLEL with task-001]
  ├── Depends on: none
  ├── Files: docs/guides/mcp-configuration.md
  ├── Changes: Replace line 48 (Windows install instruction)
  │   - Remove: "Download forgejo-mcp-windows-amd64.exe, save as bin/forgejo-mcp.exe"
  │   - Add: Warning about no upstream Windows binary + go install command
  └── AC: AC-4

task-003: Update installation.md [PARALLEL with task-001]
  ├── Depends on: none
  ├── Files: docs/guides/installation.md
  ├── Changes: Add paragraph to Windows platform section (after line 70)
  │   - Note: forgejo-mcp requires Go on Windows
  │   - Command: go install codeberg.org/goern/forgejo-mcp/v2@latest
  └── AC: AC-5
```

## Parallelization

All three tasks are independent and CAN be executed in parallel:
- task-001 modifies `skills/init/SKILL.md`
- task-002 modifies `docs/guides/mcp-configuration.md`
- task-003 modifies `docs/guides/installation.md`

No shared files, no sequential dependencies.

## Exact Edits per Task

### task-001: skills/init/SKILL.md

**Replace** the "Auto-download (default behavior)" section (lines 166-181) with the new 9-step flow:
1. Check if already installed (unchanged)
2. Create bin directory (unchanged)
3. Fetch latest release tag (unchanged)
4. Download binary with `curl -sfL` (add `--fail` via `-f` flag)
5. Validate file size: `FILESIZE=$(wc -c < file 2>/dev/null || echo 0)`, threshold 102400
6. Set permissions (unchanged)
7. Verify download (updated to reference size validation)
8. Go install fallback (Windows only) — check `command -v go`, run `GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest`
9. Non-Windows failure → manual fallback

### task-002: docs/guides/mcp-configuration.md

**Replace** line 48:
```
- **Windows install:** Download `forgejo-mcp-windows-amd64.exe`, save as `bin/forgejo-mcp.exe`
```
→
```
- **Windows install:** Pre-built Windows binaries are not reliably published upstream. Use Go to install:
  ```bash
  GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest
  ```
  Requires Go installed (https://go.dev/dl/). The binary will be placed at `~/.claude/bin/forgejo-mcp.exe`.
```

### task-003: docs/guides/installation.md

**Add** after line 70 ("Paths use `~/` notation (Git Bash / WSL)."):
```
**forgejo-mcp note:** Pre-built Windows binaries for forgejo-mcp are not reliably available from the upstream repository. The `/ceos-agents:init` skill will automatically attempt `go install` as a fallback. Ensure Go is installed (`go version`) before running init. Install Go from https://go.dev/dl/ if needed.
```

## Post-Implementation Verification

Run the existing test suite: `./tests/harness/run-tests.sh`
Run structural T1 checks from Phase 5 test plan.
