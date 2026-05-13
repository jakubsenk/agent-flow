# Phase 8 — Verification

You are the verification agent. Your job is to independently verify that the Phase 7 execution was correct and complete. You are adversarial — assume the execution might have missed something.

## Context

- Repository: `C:\gitea_ceos-agents`
- The fix targeted `commands/version-check.md` (remove hardcoded URL, ensure genericity)
- Secondary changes to `docs/reference/commands.md` and `CHANGELOG.md`

## Verification Checklist

### V1: File Content Verification

Read each modified file and verify:

#### V1.1: `commands/version-check.md`

Read the full file. Check:
- [ ] No hardcoded URLs anywhere (search for `http://`, `https://`, `.git`, `gitea`, `github.com`)
- [ ] No hardcoded internal hostnames (search for `ceosdata`, `internal`)
- [ ] The 3-part structure is intact (Part A, Part B, Part C)
- [ ] Step 3 has a graceful fallback when `repository` is missing
- [ ] Step 3 still uses `git ls-remote` for remote version check (correct approach)
- [ ] The Rules section correctly states that `installed_plugins.json` is authoritative
- [ ] The frontmatter has `allowed-tools: Read, Bash` (the only tools version-check needs)
- [ ] Plugin cache directories are described as "snapshots" not "git repos"
- [ ] No `git pull` or `git fetch` on cache directories

#### V1.2: `docs/reference/commands.md`

Read the version-check section. Check:
- [ ] Description mentions working from any directory
- [ ] Description mentions `installed_plugins.json`
- [ ] Description does not mention hardcoded URLs
- [ ] Syntax is still `/ceos-agents:version-check` (no arguments)

#### V1.3: `CHANGELOG.md`

Read the latest entry. Check:
- [ ] Mentions the hardcoded URL removal
- [ ] Mentions genericity improvement
- [ ] Version number is consistent with plugin.json

### V2: Behavioral Verification (CRITICAL)

#### V2.1: Simulate version-check from OUTSIDE the repo

```bash
# Simulate what version-check would do from a non-repo directory
cd /tmp

# Step 1: Can we read installed_plugins.json?
cat ~/.claude/plugins/installed_plugins.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
plugins = data.get('plugins', {})
key = 'ceos-agents@ceos-agents'
if key in plugins:
    entries = plugins[key]
    latest = entries[-1] if isinstance(entries, list) else entries
    print(f'Installed version: {latest.get(\"version\", \"unknown\")}')
    print(f'Install path: {latest.get(\"installPath\", \"unknown\")}')
else:
    print(f'Plugin {key} not found')
" 2>/dev/null || echo "Cannot parse installed_plugins.json"

# Step 2: Can we read repository URL from install path?
INSTALL_PATH=$(cat ~/.claude/plugins/installed_plugins.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
entries = data['plugins']['ceos-agents@ceos-agents']
latest = entries[-1] if isinstance(entries, list) else entries
print(latest['installPath'])
" 2>/dev/null)
if [ -f "$INSTALL_PATH/.claude-plugin/plugin.json" ]; then
    REPO_URL=$(python3 -c "
import json
with open('$INSTALL_PATH/.claude-plugin/plugin.json') as f:
    data = json.load(f)
    print(data.get('repository', 'MISSING'))
")
    echo "Repository URL: $REPO_URL"
    if [ "$REPO_URL" != "MISSING" ]; then
        # Step 3: Can we reach the remote?
        git ls-remote --tags "$REPO_URL" 'refs/tags/v*' 2>/dev/null | sort -t/ -k3 -V | tail -1 || echo "Remote unreachable"
    fi
else
    echo "Install path plugin.json not found"
fi

# Step 5 (Part B): Should be skipped - no .claude-plugin/plugin.json in CWD
[ -f ".claude-plugin/plugin.json" ] && echo "UNEXPECTED: Part B would trigger in /tmp" || echo "OK: Part B correctly skipped (not in plugin repo)"

# Step 7 (Part C): Legacy check
[ -d "$HOME/.claude/plugins/marketplaces/CLAUDE-agents" ] && echo "Legacy remnant found" || echo "No legacy remnant"
```

#### V2.2: Simulate version-check from INSIDE the repo

```bash
cd C:\gitea_ceos-agents

# Same as V2.1 Steps 1-3, plus:

# Step 5 (Part B): Should trigger
[ -f ".claude-plugin/plugin.json" ] && echo "OK: Part B triggers (in plugin repo)" || echo "UNEXPECTED: Part B should trigger"

# Read repo version
python3 -c "
import json
with open('.claude-plugin/plugin.json') as f:
    data = json.load(f)
    print(f'Repo version: {data[\"version\"]}')
"
```

### V3: Regression Verification

```bash
cd C:\gitea_ceos-agents

# Full T1 + T3 test suite
echo "=== Structural Tests ==="
! grep -q 'gitea.internal.ceosdata.com' commands/version-check.md && echo "T1.1 PASS: No hardcoded URLs" || echo "T1.1 FAIL"
! grep -qi 'git pull' commands/version-check.md && echo "T1.5 PASS: No git pull" || echo "T1.5 FAIL"
grep -q 'installed_plugins.json' commands/version-check.md && echo "T1.6 PASS: References installed_plugins.json" || echo "T1.6 FAIL"
grep -q 'Cannot determine remote' commands/version-check.md && echo "T1.7 PASS: Graceful fallback" || echo "T1.7 FAIL"

echo "=== Regression Guards ==="
! grep -q 'marketplaces/ceos-agents' commands/version-check.md && echo "T3.1a PASS: No old marketplace path" || echo "T3.1a FAIL"
! grep -q 'git -C.*pull' commands/version-check.md && echo "T3.1b PASS: No git-C pull" || echo "T3.1b FAIL"
! grep -q 'git -C.*fetch' commands/version-check.md && echo "T3.1c PASS: No git-C fetch" || echo "T3.1c FAIL"

echo "=== Version Consistency ==="
PLUGIN_V=$(grep '"version"' .claude-plugin/plugin.json | head -1 | sed 's/.*"\([0-9][0-9.]*\)".*/\1/')
MARKET_V=$(grep '"version"' .claude-plugin/marketplace.json | sed 's/.*"\([0-9][0-9.]*\)".*/\1/')
echo "plugin.json: $PLUGIN_V | marketplace.json: $MARKET_V"
[ "$PLUGIN_V" = "$MARKET_V" ] && echo "T3.2 PASS: Versions match" || echo "T3.2 FAIL"
```

### V4: Cross-Reference Verification

Check that no other files were broken by the change:

```bash
cd C:\gitea_ceos-agents

# Check that files referencing version-check still make sense
grep -n 'version-check' commands/init.md
grep -n 'version-check' skills/workflow-router/SKILL.md
grep -n 'version-check' docs/guides/troubleshooting.md
```

Verify these references are still accurate (they should not need changes since we only changed internal behavior, not the command's interface).

### V5: Genericity Test

The ultimate test: could another team fork this plugin, rename it to `my-agents`, and have version-check work?

Check:
- [ ] The command reads the plugin identifier from a known location (or uses the plugin's own name)
- [ ] The command reads the remote URL from the plugin's own `plugin.json` `repository` field
- [ ] The only ceos-agents-specific content is the legacy `CLAUDE-agents` check in Part C (acceptable — it's a historical cleanup, clearly commented)
- [ ] No other team-specific or infrastructure-specific values exist in the file

## Verdict

After running all checks, produce a verdict:

### Result: PASS / FAIL

If PASS:
- List all verification checks that passed
- Note any minor observations that don't block

If FAIL:
- List exactly which checks failed
- Provide the exact fix needed for each failure
- Phase 7 must re-execute with corrections
