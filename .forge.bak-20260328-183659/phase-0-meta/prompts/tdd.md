# Phase 5 — Test Design (TDD)

You are a test engineer designing verification tests for the version-check fix. This is CRITICAL: the original bug was discovered because version-check was never tested from outside the repo directory.

## Context

- The ceos-agents plugin is pure markdown — no executable code, no unit test framework
- Testing means running the actual `/ceos-agents:version-check` command and verifying its output
- The test harness is at `tests/harness/run-tests.sh` (bash-based scenario runner)
- We need to verify behavior from TWO different working directories

## Test Categories

### T1: Structural Tests (can run without Claude Code)

These validate the markdown file itself:

```bash
# T1.1: No hardcoded URLs in version-check.md
! grep -q 'gitea.internal.ceosdata.com' commands/version-check.md
echo "PASS: No hardcoded URLs found"

# T1.2: No hardcoded plugin identifiers that assume ceos-agents name
# (ceos-agents@ceos-agents is acceptable since this command ships with this plugin,
#  but verify it's used as a lookup key, not a display string)
grep -c 'ceos-agents@ceos-agents' commands/version-check.md
# Expected: appears in step 1 as the lookup key — this is acceptable

# T1.3: File has required sections
grep -q '## Steps' commands/version-check.md && echo "PASS: Has Steps section"
grep -q '### Part A' commands/version-check.md && echo "PASS: Has Part A"
grep -q '### Part B' commands/version-check.md && echo "PASS: Has Part B"
grep -q '### Part C' commands/version-check.md && echo "PASS: Has Part C"
grep -q '## Rules' commands/version-check.md && echo "PASS: Has Rules section"

# T1.4: Frontmatter is valid
head -4 commands/version-check.md | grep -q 'allowed-tools: Read, Bash'
echo "PASS: Frontmatter has correct allowed-tools"

# T1.5: No git pull references (the original bug)
! grep -qi 'git pull' commands/version-check.md
echo "PASS: No git pull references"

# T1.6: References installed_plugins.json as authoritative source
grep -q 'installed_plugins.json' commands/version-check.md
echo "PASS: References installed_plugins.json"

# T1.7: Has graceful fallback when repository field is missing
grep -q 'repository.*missing\|Cannot determine remote' commands/version-check.md
echo "PASS: Has fallback for missing repository field"
```

### T2: Behavioral Tests (require Claude Code runtime — manual verification)

These test the actual command execution. Write them as step-by-step manual test procedures.

#### T2.1: Version check from INSIDE the ceos-agents repo

```
Working directory: C:\gitea_ceos-agents
Command: /ceos-agents:version-check

Expected output includes:
- Installed version number (from installed_plugins.json)
- Remote version comparison (from git ls-remote on repository URL)
- Repo version comparison (Part B triggered — .claude-plugin/plugin.json found in CWD)
- Legacy marketplace check result (Part C)

Verify:
- [ ] Part A shows installed version
- [ ] Part A shows remote comparison (or skip message if network unavailable)
- [ ] Part B shows repo version vs installed version comparison
- [ ] Part C shows legacy marketplace status
- [ ] No errors or tracebacks
```

#### T2.2: Version check from OUTSIDE the ceos-agents repo

```
Working directory: C:\Users\FSABACKY (or any non-plugin directory)
Command: /ceos-agents:version-check

Expected output includes:
- Installed version number (from installed_plugins.json)
- Remote version comparison
- NO repo comparison (Part B skipped — no .claude-plugin/plugin.json in CWD)
- Legacy marketplace check result (Part C)

Verify:
- [ ] Part A shows installed version
- [ ] Part A shows remote comparison (or skip message)
- [ ] Part B is SKIPPED (not mentioned or explicitly noted as skipped)
- [ ] Part C shows legacy marketplace status
- [ ] No errors about missing files or wrong paths
```

#### T2.3: Edge case — missing repository field

```
Setup: Temporarily remove the `repository` field from the installed plugin's plugin.json
Command: /ceos-agents:version-check

Expected:
- Installed version shown correctly
- Remote check: "Cannot determine remote repository URL" or similar skip message
- No crash, no hardcoded URL used

Teardown: Restore the repository field
```

#### T2.4: Edge case — network failure

```
Setup: Disconnect network or use a firewall rule to block git protocol
Command: /ceos-agents:version-check

Expected:
- Installed version shown correctly
- Remote check: "Failed to determine remote version" warning
- Part B and Part C still work (no network dependency)
```

### T3: Regression Guards

```bash
# T3.1: version-check.md should NOT contain any of these old/broken patterns
! grep -q 'marketplaces/ceos-agents' commands/version-check.md
echo "PASS: No reference to old marketplace path"

! grep -q 'git -C.*pull' commands/version-check.md
echo "PASS: No git pull on cache directories"

! grep -q 'git -C.*fetch' commands/version-check.md
echo "PASS: No git fetch on cache directories"

# T3.2: Version numbers are consistent
PLUGIN_VERSION=$(grep '"version"' .claude-plugin/plugin.json | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/')
MARKETPLACE_VERSION=$(grep '"version"' .claude-plugin/marketplace.json | sed 's/.*"version": *"\([^"]*\)".*/\1/')
[ "$PLUGIN_VERSION" = "$MARKETPLACE_VERSION" ] && echo "PASS: Versions match ($PLUGIN_VERSION)"
```

## Test Execution Plan

### Phase 1: Automated structural tests
Run all T1 and T3 tests via bash. These can be scripted and run in CI.

### Phase 2: Manual behavioral tests
Run T2.1 and T2.2 manually using Claude Code. These require the actual plugin runtime.

### Phase 3: Edge case tests
Run T2.3 and T2.4 if time permits. These are lower priority since they test defensive paths.

## Pass Criteria

- ALL T1 tests pass (structural)
- ALL T3 tests pass (regression guards)
- T2.1 passes (inside repo)
- T2.2 passes (outside repo) — THIS IS THE CRITICAL TEST that caught the original bug
- T2.3 and T2.4: best-effort

## Output

Provide a test results table:

| Test | Status | Notes |
|------|--------|-------|
| T1.1 | PASS/FAIL | ... |
| ... | ... | ... |
