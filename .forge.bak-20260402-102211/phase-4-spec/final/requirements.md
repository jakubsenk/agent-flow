# Requirements: Commands-to-Skills Migration (v6.0.0)

## SPEC-1: File Migration Manifest

Every file moves from `commands/{name}.md` to `skills/{name}/SKILL.md`. No content changes inside the files -- only the frontmatter block is updated and the file is relocated.

### Phase 1: Read-only / Analysis skills (11 files)

These skills do NOT get `disable-model-invocation: true`.

| # | Source | Destination | Frontmatter |
|---|--------|-------------|-------------|
| 1 | `commands/analyze-bug.md` | `skills/analyze-bug/SKILL.md` | See SPEC-2 |
| 2 | `commands/check-setup.md` | `skills/check-setup/SKILL.md` | See SPEC-2 |
| 3 | `commands/status.md` | `skills/status/SKILL.md` | See SPEC-2 |
| 4 | `commands/dashboard.md` | `skills/dashboard/SKILL.md` | See SPEC-2 |
| 5 | `commands/metrics.md` | `skills/metrics/SKILL.md` | See SPEC-2 |
| 6 | `commands/estimate.md` | `skills/estimate/SKILL.md` | See SPEC-2 |
| 7 | `commands/prioritize.md` | `skills/prioritize/SKILL.md` | See SPEC-2 |
| 8 | `commands/template.md` | `skills/template/SKILL.md` | See SPEC-2 |
| 9 | `commands/scaffold-validate.md` | `skills/scaffold-validate/SKILL.md` | See SPEC-2 |
| 10 | `commands/version-check.md` | `skills/version-check/SKILL.md` | See SPEC-2 |
| 11 | `commands/discuss.md` | `skills/discuss/SKILL.md` | See SPEC-2 |

### Phase 2: Pipeline / Destructive skills (14 files)

These skills get `disable-model-invocation: true`.

| # | Source | Destination | Frontmatter |
|---|--------|-------------|-------------|
| 12 | `commands/fix-ticket.md` | `skills/fix-ticket/SKILL.md` | See SPEC-2 |
| 13 | `commands/fix-bugs.md` | `skills/fix-bugs/SKILL.md` | See SPEC-2 |
| 14 | `commands/implement-feature.md` | `skills/implement-feature/SKILL.md` | See SPEC-2 |
| 15 | `commands/scaffold.md` | `skills/scaffold/SKILL.md` | See SPEC-2 |
| 16 | `commands/publish.md` | `skills/publish/SKILL.md` | See SPEC-2 |
| 17 | `commands/create-pr.md` | `skills/create-pr/SKILL.md` | See SPEC-2 |
| 18 | `commands/onboard.md` | `skills/onboard/SKILL.md` | See SPEC-2 |
| 19 | `commands/init.md` | `skills/init/SKILL.md` | See SPEC-2 |
| 20 | `commands/scaffold-add.md` | `skills/scaffold-add/SKILL.md` | See SPEC-2 |
| 21 | `commands/check-deploy.md` | `skills/check-deploy/SKILL.md` | See SPEC-2 |
| 22 | `commands/resume-ticket.md` | `skills/resume-ticket/SKILL.md` | See SPEC-2 |
| 23 | `commands/changelog.md` | `skills/changelog/SKILL.md` | See SPEC-2 |
| 24 | `commands/version-bump.md` | `skills/version-bump/SKILL.md` | See SPEC-2 |
| 25 | `commands/migrate-config.md` | `skills/migrate-config/SKILL.md` | See SPEC-2 |

### Phase 3: Cross-reference updates (Batch A -- functional paths)

Update all test files, core files, and docs that use `commands/` as a functional path. See SPEC-4 for exact patterns.

### Phase 4: Cross-reference updates (Batch B -- CLAUDE.md)

Update CLAUDE.md. See SPEC-4 Section 6 for exact changes.

### Phase 5: Cross-reference updates (Batch C -- docs prose)

Update `docs/guides/mcp-configuration.md`. See SPEC-4 Section 7.

### Phase 6: Delete `commands/` directory

After all files are moved and all references updated:
```bash
rm -rf commands/
```

### Phase 7: Version bump

Update `plugin.json` and `marketplace.json` to version `6.0.0`.

---

## SPEC-2: Frontmatter Rules

### Read-only / Analysis skills (no `disable-model-invocation`)

**1. analyze-bug**
```yaml
---
name: analyze-bug
description: Analyzes a specific bug from the issue tracker (analysis only, no code changes)
allowed-tools: mcp__*, Read, Glob, Grep, Task
argument-hint: "<ISSUE-ID>"
---
```

**2. check-setup**
```yaml
---
name: check-setup
description: Validate Automation Config, MCP servers, and tokens
allowed-tools: mcp__*, Read, Glob, Grep, Bash
argument-hint: "[--skip-build]"
---
```

**3. status**
```yaml
---
name: status
description: Overview of in-progress issues -- pipeline state, branch, PR
allowed-tools: mcp__*, Read, Grep
---
```

**4. dashboard**
```yaml
---
name: dashboard
description: Generates an HTML dashboard with pipeline state -- issues, blocked, statistics
allowed-tools: mcp__*, Read, Glob, Grep, Bash, Write
argument-hint: "[--days <N>] [--output <path>] [--state <filter>] [--stage <filter>]"
---
```

**5. metrics**
```yaml
---
name: metrics
description: Generates pipeline analytics report -- success rate, per-agent effectiveness, failure patterns
allowed-tools: mcp__*, Read, Glob, Grep, Bash
argument-hint: "[--period <N>] [--output <path>] [--format <md|json>]"
---
```

**6. estimate**
```yaml
---
name: estimate
description: Estimates token usage and cost before running pipeline
allowed-tools: mcp__*, Read, Glob, Grep, Bash
argument-hint: "<ISSUE-ID> [--profile <name>]"
---
```

**7. prioritize**
```yaml
---
name: prioritize
description: Analyzes backlog and suggests fix order using AI prioritization
allowed-tools: mcp__*, Read, Glob, Grep, Task
argument-hint: "[--limit <N>] [--output <path>]"
---
```

**8. template**
```yaml
---
name: template
description: Generates Automation Config template for a given tech stack
allowed-tools: Read, Glob
argument-hint: "list | <stack-name>"
---
```

**9. scaffold-validate**
```yaml
---
name: scaffold-validate
description: Validates project -- build, tests, lint, CLAUDE.md structure
allowed-tools: Bash, Read, Glob, Grep
argument-hint: "[<path>]"
---
```

**10. version-check**
```yaml
---
name: version-check
description: Compares installed plugin version with the latest available
allowed-tools: Read, Bash
---
```

**11. discuss**
```yaml
---
name: discuss
description: Multi-agent discussion -- brings 2-3 agent perspectives into one conversation
allowed-tools: Task, Read, Glob, Grep
argument-hint: "<topic> [--agents <list>]"
---
```

### Pipeline / Destructive skills (with `disable-model-invocation: true`)

**12. fix-ticket**
```yaml
---
name: fix-ticket
description: Analyzes and fixes a specific ticket (in CWD, no worktree)
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
disable-model-invocation: true
argument-hint: "<ISSUE-ID> [--dry-run] [--profile <name>] [--yolo]"
---
```

**13. fix-bugs**
```yaml
---
name: fix-bugs
description: Automatically fixes N bugs from the issue tracker
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
disable-model-invocation: true
argument-hint: "<N> [--dry-run] [--profile <name>]"
---
```

**14. implement-feature**
```yaml
---
name: implement-feature
description: Implements a feature from the issue tracker -- spec, design, fix, review, test, publish
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
disable-model-invocation: true
argument-hint: "<ISSUE-ID> | --description \"<text>\" [--decompose] [--no-decompose] [--dry-run] [--profile <name>] [--yolo]"
---
```

**15. scaffold**
```yaml
---
name: scaffold
description: Creates a new project from scratch -- specification, tech stack, skeleton, feature implementation, validation, git init
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
disable-model-invocation: true
argument-hint: "<description> [--template <path>] [--spec <path>] [--issue <ID>] [--no-implement] [--infra tracker:<v>,sc:<v>]"
---
```

**16. publish**
```yaml
---
name: publish
description: Creates a PR and updates issue tracker states
allowed-tools: mcp__*, Bash, Read, Grep, Task
disable-model-invocation: true
---
```

**17. create-pr**
```yaml
---
name: create-pr
description: Creates a PR for the current branch
allowed-tools: mcp__*, Bash, Read, Grep
disable-model-invocation: true
---
```

**18. onboard**
```yaml
---
name: onboard
description: Interactive wizard for generating Automation Config
allowed-tools: Read, Glob, Write, Edit
disable-model-invocation: true
argument-hint: "[--fresh] [--update]"
---
```

**19. init**
```yaml
---
name: init
description: Configures developer environment -- MCP servers, tokens, and permissions
allowed-tools: Read, Glob, Write, Edit, Bash, mcp__*
disable-model-invocation: true
argument-hint: "[--update]"
---
```

**20. scaffold-add**
```yaml
---
name: scaffold-add
description: Adds a component to an existing project (claude-md, ci, docker, tests)
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
disable-model-invocation: true
argument-hint: "<component>"
---
```

**21. check-deploy**
```yaml
---
name: check-deploy
description: Check local deployment health -- start, stop, or verify app status
allowed-tools: Bash, Read, Glob, Grep, Task
disable-model-invocation: true
argument-hint: "[--start] [--stop]"
---
```

**22. resume-ticket**
```yaml
---
name: resume-ticket
description: Resumes pipeline from failure point without re-analysis
allowed-tools: mcp__*, Bash, Read, Write, Edit, Grep, Glob, Task
disable-model-invocation: true
argument-hint: "<ISSUE-ID>"
---
```

**23. changelog**
```yaml
---
name: changelog
description: Automatic changelog generation from merged PRs
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob
disable-model-invocation: true
---
```

**24. version-bump**
```yaml
---
name: version-bump
description: Bumps version in plugin.json and marketplace.json (patch/minor/major)
allowed-tools: Read, Edit, Glob, Bash
disable-model-invocation: true
argument-hint: "patch | minor | major"
---
```

**25. migrate-config**
```yaml
---
name: migrate-config
description: Detects Automation Config version and suggests upgrade to current
allowed-tools: Read, Edit, Glob
disable-model-invocation: true
---
```

### Frontmatter field summary

| Field | Required | Notes |
|-------|----------|-------|
| `name` | Yes | Filename without `.md`, matches the skill directory name |
| `description` | Yes | Copied verbatim from existing command frontmatter (with `—` replaced by `--` for YAML safety) |
| `allowed-tools` | Yes | Copied verbatim from existing command frontmatter |
| `disable-model-invocation` | Conditional | `true` for 14 pipeline/destructive skills; absent for 11 read-only skills |
| `argument-hint` | Optional | Added where the command documents arguments in `$ARGUMENTS`; absent for commands with no arguments |

### Fields NOT added in v6.0.0 (deferred)

- `context` -- deferred to follow-up
- `model` -- deferred to follow-up
- `paths` -- deferred to follow-up
- `hooks` -- deferred to follow-up

---

## SPEC-4: Cross-Reference Rules

### Rule Group A: Test files (22 scenarios)

Each test scenario uses `REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"` and then references commands. Below are the exact substitution patterns, grouped by pattern type.

#### Pattern A1: Direct file path `$REPO_ROOT/commands/{name}.md`

Replace with: `$REPO_ROOT/skills/{name}/SKILL.md`

Affected files and exact `old -> new` substitutions:

**tests/scenarios/core-include-refs.sh** (line 47):
```
OLD: local f="$REPO_ROOT/commands/${cmd}.md"
NEW: local f="$REPO_ROOT/skills/${cmd}/SKILL.md"
```

**tests/scenarios/browser-verification-skip.sh** (lines 34, 35, 61, 62, 64, 65):
```
OLD: if ! grep -q "browser_verification_enabled" "$REPO_ROOT/commands/$cmd.md"; then
NEW: if ! grep -q "browser_verification_enabled" "$REPO_ROOT/skills/$cmd/SKILL.md"; then

OLD: fail "commands/$cmd.md missing browser_verification_enabled guard"
NEW: fail "skills/$cmd/SKILL.md missing browser_verification_enabled guard"

OLD: if ! grep -q "reproducer.*step" "$REPO_ROOT/commands/$cmd.md"; then
NEW: if ! grep -q "reproducer.*step" "$REPO_ROOT/skills/$cmd/SKILL.md"; then

OLD: fail "commands/$cmd.md missing reproducer stage mapping"
NEW: fail "skills/$cmd/SKILL.md missing reproducer stage mapping"

OLD: if ! grep -q "browser-verifier.*step" "$REPO_ROOT/commands/$cmd.md"; then
NEW: if ! grep -q "browser-verifier.*step" "$REPO_ROOT/skills/$cmd/SKILL.md"; then

OLD: fail "commands/$cmd.md missing browser-verifier stage mapping"
NEW: fail "skills/$cmd/SKILL.md missing browser-verifier stage mapping"
```

**tests/scenarios/pipeline-hook-order.sh** (line 21):
```
OLD: local file="$REPO_ROOT/commands/$cmd.md"
NEW: local file="$REPO_ROOT/skills/$cmd/SKILL.md"
```

**tests/scenarios/pipeline-deploy-verifier.sh** (lines 11, 42):
```
OLD: CD="$REPO_ROOT/commands/check-deploy.md"
NEW: CD="$REPO_ROOT/skills/check-deploy/SKILL.md"

OLD: fail "commands/check-deploy.md does not exist"
NEW: fail "skills/check-deploy/SKILL.md does not exist"
```

**tests/scenarios/pipeline-state-writes.sh** (lines 19, 21, 36, 38, 52, 54, 64, 66):
```
OLD: FT="$REPO_ROOT/commands/fix-ticket.md"
NEW: FT="$REPO_ROOT/skills/fix-ticket/SKILL.md"

OLD: fail "commands/fix-ticket.md does not exist"
NEW: fail "skills/fix-ticket/SKILL.md does not exist"

OLD: IF="$REPO_ROOT/commands/implement-feature.md"
NEW: IF="$REPO_ROOT/skills/implement-feature/SKILL.md"

OLD: fail "commands/implement-feature.md does not exist"
NEW: fail "skills/implement-feature/SKILL.md does not exist"

OLD: SC="$REPO_ROOT/commands/scaffold.md"
NEW: SC="$REPO_ROOT/skills/scaffold/SKILL.md"

OLD: fail "commands/scaffold.md does not exist"
NEW: fail "skills/scaffold/SKILL.md does not exist"

OLD: CD="$REPO_ROOT/commands/check-deploy.md"
NEW: CD="$REPO_ROOT/skills/check-deploy/SKILL.md"

OLD: fail "commands/check-deploy.md does not exist"
NEW: fail "skills/check-deploy/SKILL.md does not exist"
```

**tests/scenarios/scaffold-canary-announcement.sh** (line 7):
```
OLD: SCAFFOLD_CMD="$REPO_ROOT/commands/scaffold.md"
NEW: SCAFFOLD_CMD="$REPO_ROOT/skills/scaffold/SKILL.md"
```

**tests/scenarios/scaffold-infra-flag-format.sh** (line 7):
```
OLD: SCAFFOLD_CMD="$REPO_ROOT/commands/scaffold.md"
NEW: SCAFFOLD_CMD="$REPO_ROOT/skills/scaffold/SKILL.md"
```

**tests/scenarios/scaffold-resume-infra-override.sh** (line 7):
```
OLD: SCAFFOLD_CMD="$REPO_ROOT/commands/scaffold.md"
NEW: SCAFFOLD_CMD="$REPO_ROOT/skills/scaffold/SKILL.md"
```

**tests/scenarios/scaffold-v2-happy-path.sh** (line 26):
```
OLD: SCAFFOLD_CMD="$REPO_ROOT/commands/scaffold.md"
NEW: SCAFFOLD_CMD="$REPO_ROOT/skills/scaffold/SKILL.md"
```

**tests/scenarios/scaffold-v2-input-conflicts.sh** (line 8):
```
OLD: SCAFFOLD_CMD="$REPO_ROOT/commands/scaffold.md"
NEW: SCAFFOLD_CMD="$REPO_ROOT/skills/scaffold/SKILL.md"
```

**tests/scenarios/scaffold-v2-no-implement.sh** (line 8):
```
OLD: SCAFFOLD_CMD="$REPO_ROOT/commands/scaffold.md"
NEW: SCAFFOLD_CMD="$REPO_ROOT/skills/scaffold/SKILL.md"
```

**tests/scenarios/scaffold-v2-spec-loop.sh** (line 8):
```
OLD: SCAFFOLD_CMD="$REPO_ROOT/commands/scaffold.md"
NEW: SCAFFOLD_CMD="$REPO_ROOT/skills/scaffold/SKILL.md"
```

**tests/scenarios/scaffold-v561-regression.sh** (line 7):
```
OLD: SCAFFOLD_CMD="$REPO_ROOT/commands/scaffold.md"
NEW: SCAFFOLD_CMD="$REPO_ROOT/skills/scaffold/SKILL.md"
```

**tests/scenarios/pipeline-agent-dispatch-models.sh** (lines 35, 37):
```
OLD: cmd_file="$REPO_ROOT/commands/$cmd.md"
NEW: cmd_file="$REPO_ROOT/skills/$cmd/SKILL.md"

OLD: fail "Missing command file: commands/$cmd.md"
NEW: fail "Missing skill file: skills/$cmd/SKILL.md"
```

**tests/scenarios/profile-skip.sh** (line 8):
```
OLD: CMD_FILE="$REPO_ROOT/commands/$cmd.md"
NEW: CMD_FILE="$REPO_ROOT/skills/$cmd/SKILL.md"
```

**tests/scenarios/pipeline-feature-step-order.sh** (lines 6, 12, 26):
```
OLD: CMD_FILE="$REPO_ROOT/commands/implement-feature.md"
NEW: CMD_FILE="$REPO_ROOT/skills/implement-feature/SKILL.md"

OLD: fail "commands/implement-feature.md not found"
NEW: fail "skills/implement-feature/SKILL.md not found"

OLD: fail "No step headings found in commands/implement-feature.md"
NEW: fail "No step headings found in skills/implement-feature/SKILL.md"
```

**tests/scenarios/pipeline-feature-agents.sh** (lines 10, 13):
```
OLD: IF="$REPO_ROOT/commands/implement-feature.md"
NEW: IF="$REPO_ROOT/skills/implement-feature/SKILL.md"

OLD: fail "commands/implement-feature.md does not exist"
NEW: fail "skills/implement-feature/SKILL.md does not exist"
```

**tests/scenarios/state-schema.sh** (lines 45, 55):
```
OLD: CMD_FILE="$REPO_ROOT/commands/${cmd}.md"
NEW: CMD_FILE="$REPO_ROOT/skills/${cmd}/SKILL.md"

OLD: RESUME="$REPO_ROOT/commands/resume-ticket.md"
NEW: RESUME="$REPO_ROOT/skills/resume-ticket/SKILL.md"
```

**tests/scenarios/verify-fail.sh** (lines 8, 16, 24):
```
OLD: if grep -q "Fix Verification" "$REPO_ROOT/commands/fix-ticket.md"; then
NEW: if grep -q "Fix Verification" "$REPO_ROOT/skills/fix-ticket/SKILL.md"; then

OLD: if grep -q "Fix Verification" "$REPO_ROOT/commands/fix-bugs.md"; then
NEW: if grep -q "Fix Verification" "$REPO_ROOT/skills/fix-bugs/SKILL.md"; then

OLD: if grep -q "Feature Verification" "$REPO_ROOT/commands/implement-feature.md"; then
NEW: if grep -q "Feature Verification" "$REPO_ROOT/skills/implement-feature/SKILL.md"; then
```

**tests/scenarios/xref-skip-stage-names.sh** (lines 41, 63):
```
OLD: CMD_FILE="$REPO_ROOT/commands/$cmd.md"
NEW: CMD_FILE="$REPO_ROOT/skills/$cmd/SKILL.md"
```

#### Pattern A2: Relative paths in arrays `"commands/{name}.md"`

Replace with: `"skills/{name}/SKILL.md"`

**tests/scenarios/no-mcp-jargon-errors.sh** (lines 13-22, 27-30, 76):
```
OLD: "commands/analyze-bug.md"
NEW: "skills/analyze-bug/SKILL.md"

OLD: "commands/changelog.md"
NEW: "skills/changelog/SKILL.md"

OLD: "commands/create-pr.md"
NEW: "skills/create-pr/SKILL.md"

OLD: "commands/dashboard.md"
NEW: "skills/dashboard/SKILL.md"

OLD: "commands/estimate.md"
NEW: "skills/estimate/SKILL.md"

OLD: "commands/metrics.md"
NEW: "skills/metrics/SKILL.md"

OLD: "commands/prioritize.md"
NEW: "skills/prioritize/SKILL.md"

OLD: "commands/status.md"
NEW: "skills/status/SKILL.md"

OLD: "commands/resume-ticket.md"
NEW: "skills/resume-ticket/SKILL.md"

OLD: "commands/scaffold-add.md"
NEW: "skills/scaffold-add/SKILL.md"

OLD: "commands/fix-bugs.md"
NEW: "skills/fix-bugs/SKILL.md"

OLD: "commands/publish.md"
NEW: "skills/publish/SKILL.md"

OLD: "commands/scaffold.md"
NEW: "skills/scaffold/SKILL.md"

OLD: "commands/implement-feature.md"
NEW: "skills/implement-feature/SKILL.md"

OLD: SCAFFOLD="$REPO_ROOT/commands/scaffold.md"
NEW: SCAFFOLD="$REPO_ROOT/skills/scaffold/SKILL.md"
```

#### Pattern A3: Directory-level references `$REPO_ROOT/commands` (as a directory)

These tests iterate over the `commands/` directory or check its existence.

**tests/scenarios/happy-path.sh** -- REWRITE required (lines 9-13):
```bash
# OLD:
cmd_count=$(ls "$REPO_ROOT/commands/"*.md 2>/dev/null | wc -l)
if [ "$cmd_count" -lt 24 ]; then
  echo "FAIL: Expected >= 24 command files, found $cmd_count in commands/"
  exit 1
fi

# NEW:
cmd_count=$(find "$REPO_ROOT/skills" -name SKILL.md -not -path "*/workflow-router/*" 2>/dev/null | wc -l)
if [ "$cmd_count" -lt 24 ]; then
  echo "FAIL: Expected >= 24 skill files, found $cmd_count in skills/"
  exit 1
fi
```
Also update echo on line 22:
```bash
# OLD:
echo "PASS: All command and agent files present ($cmd_count commands, $agent_count agents)"
# NEW:
echo "PASS: All skill and agent files present ($cmd_count skills, $agent_count agents)"
```

**tests/scenarios/config-required-keys.sh** -- REWRITE required (lines 8-9, 33-34, 38, 42):
```bash
# OLD:
COMMANDS_DIR="$REPO_ROOT/commands"
[ -d "$COMMANDS_DIR" ] || { echo "FAIL: commands/ directory not found"; exit 1; }

# NEW:
SKILLS_DIR="$REPO_ROOT/skills"
[ -d "$SKILLS_DIR" ] || { echo "FAIL: skills/ directory not found"; exit 1; }

# OLD (line 34):
  matches=$(grep -ril "$key" "$COMMANDS_DIR"/*.md 2>/dev/null || true)
# NEW:
  matches=$(find "$SKILLS_DIR" -name SKILL.md -exec grep -li "$key" {} + 2>/dev/null || true)

# OLD (line 36):
    echo "OK: required key '$key' referenced in: $(echo "$matches" | xargs -I{} basename {} | tr '\n' ' ')"
# NEW:
    echo "OK: required key '$key' referenced in: $(echo "$matches" | xargs -I{} dirname {} | xargs -I{} basename {} | tr '\n' ' ')"

# OLD (line 38):
    fail "required key '$key' not found in any command"
# NEW:
    fail "required key '$key' not found in any skill"

# OLD (line 42):
[ "$FAIL" -eq 0 ] && echo "PASS: all required config keys are consumed by at least one command"
# NEW:
[ "$FAIL" -eq 0 ] && echo "PASS: all required config keys are consumed by at least one skill"
```

**tests/scenarios/xref-command-count.sh** -- REWRITE required:

This test checks that CLAUDE.md count claims match filesystem counts. After migration:
- CLAUDE.md will no longer have a `commands/` line (it becomes `skills/`)
- The `commands/` section in CLAUDE.md is replaced by `skills/` with count 26

```bash
# OLD (lines 43-53):
# ---- commands/ ----
COMMANDS_FS=$(count_md "$REPO_ROOT/commands")
COMMANDS_CLAIMED=$(extract_claimed "commands")

if [ -z "$COMMANDS_CLAIMED" ]; then
  fail "Could not find a numeric count claim for commands/ in CLAUDE.md"
else
  if [ "$COMMANDS_CLAIMED" -ne "$COMMANDS_FS" ]; then
    fail "commands/: CLAUDE.md claims $COMMANDS_CLAIMED but filesystem has $COMMANDS_FS *.md files"
  fi
fi

# NEW:
# ---- skills/ ----
# Skills use directory structure: skills/{name}/SKILL.md
SKILLS_FS=$(find "$REPO_ROOT/skills" -name SKILL.md 2>/dev/null | wc -l)
SKILLS_CLAIMED=$(extract_claimed "skills")

if [ -z "$SKILLS_CLAIMED" ]; then
  fail "Could not find a numeric count claim for skills/ in CLAUDE.md"
else
  if [ "$SKILLS_CLAIMED" -ne "$SKILLS_FS" ]; then
    fail "skills/: CLAUDE.md claims $SKILLS_CLAIMED but filesystem has $SKILLS_FS SKILL.md files"
  fi
fi
```

Also update the `count_md` function (it is no longer used for commands, but keep it for agents/core). Update final echo:
```bash
# OLD:
[ "$FAIL" -eq 0 ] && echo "PASS: CLAUDE.md count claims match filesystem -- agents: $AGENTS_FS, commands: $COMMANDS_FS, core: $CORE_FS"
# NEW:
[ "$FAIL" -eq 0 ] && echo "PASS: CLAUDE.md count claims match filesystem -- agents: $AGENTS_FS, skills: $SKILLS_FS, core: $CORE_FS"
```

**tests/scenarios/xref-core-registry.sh** -- REWRITE required (lines 8, 17-19, 39, 41):
```bash
# OLD:
COMMANDS_DIR="$REPO_ROOT/commands"
...
if [ ! -d "$COMMANDS_DIR" ]; then
  fail "commands/ directory not found at $COMMANDS_DIR"
fi
...
  match_count=$(grep -rl "$ref" "$COMMANDS_DIR"/*.md 2>/dev/null | wc -l)
  if [ "$match_count" -eq 0 ]; then
    fail "core/$name.md is not referenced by any command in commands/ (searched for '$ref')"
  fi

# NEW:
SKILLS_DIR="$REPO_ROOT/skills"
...
if [ ! -d "$SKILLS_DIR" ]; then
  fail "skills/ directory not found at $SKILLS_DIR"
fi
...
  match_count=$(find "$SKILLS_DIR" -name SKILL.md -exec grep -l "$ref" {} + 2>/dev/null | wc -l)
  if [ "$match_count" -eq 0 ]; then
    fail "core/$name.md is not referenced by any skill in skills/ (searched for '$ref')"
  fi
```

Also update the check_refs helper and the final echo:
```bash
# OLD (lines 44-57):
check_refs() {
  local cmd="$1"
  local min="$2"
  local f="$REPO_ROOT/commands/${cmd}.md"
  ...
}
...
check_refs "fix-ticket" 7
...

# These are in core-include-refs.sh, not xref-core-registry.sh -- see core-include-refs.sh section
```

**tests/scenarios/core-include-refs.sh** -- update check_refs (lines 44-57):
```bash
# OLD:
check_refs() {
  local cmd="$1"
  local min="$2"
  local f="$REPO_ROOT/commands/${cmd}.md"
  if [ ! -f "$f" ]; then
    fail "${cmd}.md does not exist"
    return
  fi
  ...
}

# NEW:
check_refs() {
  local cmd="$1"
  local min="$2"
  local f="$REPO_ROOT/skills/${cmd}/SKILL.md"
  if [ ! -f "$f" ]; then
    fail "skills/${cmd}/SKILL.md does not exist"
    return
  fi
  ...
}
```

Also update final echo:
```bash
# OLD:
[ "$FAIL" -eq 0 ] && echo "PASS: Core pattern files exist with contracts, all 4 pipeline commands reference core/"
# NEW:
[ "$FAIL" -eq 0 ] && echo "PASS: Core pattern files exist with contracts, all 4 pipeline skills reference core/"
```

**tests/scenarios/pipeline-consistency.sh** -- REWRITE required (line 8):
```bash
# OLD:
CMDS="$REPO_ROOT/commands"
PIPELINE_FILES=$(grep -rl 'rollback-agent\|fixer.*Task tool' "$CMDS"/*.md 2>/dev/null | tr '\n' ' ')

# NEW:
SKILLS="$REPO_ROOT/skills"
PIPELINE_FILES=$(find "$SKILLS" -name SKILL.md -exec grep -l 'rollback-agent\|fixer.*Task tool' {} + 2>/dev/null | tr '\n' ' ')
```

Also update final echo:
```bash
# OLD:
echo "PASS: Pipeline consistency -- all patterns verified across $pipeline_count pipeline commands"
# NEW:
echo "PASS: Pipeline consistency -- all patterns verified across $pipeline_count pipeline skills"
```

### Rule Group B: Core files (3 files)

**core/fixer-reviewer-loop.md** (line 44):
```
OLD: - `NEEDS_DECOMPOSITION` -> returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md` and `commands/fix-ticket.md` step 5).
NEW: - `NEEDS_DECOMPOSITION` -> returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md` and `skills/fix-ticket/SKILL.md` step 5).
```

**core/decomposition-heuristics.md** (line 34):
```
OLD: | `DECOMPOSE` | Run architect agent, build task tree, execute per-subtask (see `commands/fix-ticket.md` steps 4b-4c) |
NEW: | `DECOMPOSE` | Run architect agent, build task tree, execute per-subtask (see `skills/fix-ticket/SKILL.md` steps 4b-4c) |
```

**core/mcp-detection.md** (line 7):
```
OLD: Referenced by: `commands/scaffold.md` (Step 0-MCP), `commands/init.md` (Steps 3, 7).
NEW: Referenced by: `skills/scaffold/SKILL.md` (Step 0-MCP), `skills/init/SKILL.md` (Steps 3, 7).
```

### Rule Group C: CLAUDE.md

**Section 6a: Repository Structure** (line 18):
```
OLD: - `commands/` -- 25 commands (slash commands)
NEW: - `skills/` -- 26 skills (25 migrated commands + workflow-router)
```

**Section 6a: Repository Structure** (line 19):
```
OLD: - `skills/` -- 1 routing skill (`workflow-router`) for natural language access
```
This line is REMOVED (merged into the new `skills/` line above).

**Section 6b: Architecture: 2-Layer System** (line 32):
```
OLD: **Commands** (orchestration -- WHAT to do): `/analyze-bug`, `/fix-ticket`, `/fix-bugs`, `/create-pr`, `/publish`, `/version-bump`, `/check-setup`, `/check-deploy`, `/resume-ticket`, `/status`, `/onboard`, `/init`, `/changelog`, `/version-check`, `/implement-feature`, `/scaffold`, `/scaffold-add`, `/scaffold-validate`, `/dashboard`, `/metrics`, `/estimate`, `/prioritize`, `/migrate-config`, `/template`, `/discuss`

NEW: **Skills** (orchestration -- WHAT to do): `/analyze-bug`, `/fix-ticket`, `/fix-bugs`, `/create-pr`, `/publish`, `/version-bump`, `/check-setup`, `/check-deploy`, `/resume-ticket`, `/status`, `/onboard`, `/init`, `/changelog`, `/version-check`, `/implement-feature`, `/scaffold`, `/scaffold-add`, `/scaffold-validate`, `/dashboard`, `/metrics`, `/estimate`, `/prioritize`, `/migrate-config`, `/template`, `/discuss`
```

**Section 6b: Architecture description** (line 35):
```
OLD: Commands read `## Automation Config` from the project's CLAUDE.md and dispatch agents. Commands contain zero project-specific logic.

NEW: Skills read `## Automation Config` from the project's CLAUDE.md and dispatch agents. Skills contain zero project-specific logic.
```

**Section 6c: Bug-Fix Pipeline** (line 50):
```
OLD: Each agent can **Block** the issue (set state, add comment using Block Comment Template, move on). On block from fixer/reviewer/test-engineer: **rollback-agent** reverts git state. Hooks and custom agents can be inserted at 4 points (see `commands/fix-bugs.md` for full pipeline).

NEW: Each agent can **Block** the issue (set state, add comment using Block Comment Template, move on). On block from fixer/reviewer/test-engineer: **rollback-agent** reverts git state. Hooks and custom agents can be inserted at 4 points (see `skills/fix-bugs/SKILL.md` for full pipeline).
```

**Section 6d: Plugin Composability** (lines 172-178):
```
OLD:
## Plugin Composability

ceos-agents uses the `ceos-agents:` namespace prefix on all commands. To ensure compatibility with other plugins:

- All commands are invoked as `/ceos-agents:<command>` (e.g., `/ceos-agents:fix-ticket`)
- Custom agents should follow a similar namespace convention (e.g., `my-plugin:agent-name`)
- Run `/ceos-agents:check-setup` to detect potential command name conflicts with other installed plugins

NEW:
## Plugin Composability

ceos-agents uses the `ceos-agents:` namespace prefix on all skills. To ensure compatibility with other plugins:

- All skills are invoked as `/ceos-agents:<skill>` (e.g., `/ceos-agents:fix-ticket`)
- Custom agents should follow a similar namespace convention (e.g., `my-plugin:agent-name`)
- Run `/ceos-agents:check-setup` to detect potential skill name conflicts with other installed plugins
```

**Section 6e: Block Comment Template** (line 182):
```
OLD: When an agent blocks an issue, commands instruct it to use this format:
NEW: When an agent blocks an issue, skills instruct it to use this format:
```

### Rule Group D: Docs (1 file)

**docs/guides/mcp-configuration.md** (line 147):
```
OLD: The command verifies configuration, connectivity, and displays a report. See [commands/check-setup.md](../../commands/check-setup.md).
NEW: The command verifies configuration, connectivity, and displays a report. See [skills/check-setup/SKILL.md](../../skills/check-setup/SKILL.md).
```

### Rule Group E: Exclusions (no changes needed)

The following files contain `commands/` references but are EXCLUDED from updates:

1. **CHANGELOG.md** -- Historical references only. No update.
2. **docs/plans/*.md** -- Architecture decision records are historical. No update.
3. **skills/workflow-router/SKILL.md** -- Uses `ceos-agents:{name}` namespace, not file paths. No path references to change.

### New test assertions (2 additions)

Add to an existing test or create `tests/scenarios/skill-frontmatter.sh`:

**Assertion 1: All 14 pipeline skills have `disable-model-invocation: true`**
```bash
PIPELINE_SKILLS=(
  fix-ticket fix-bugs implement-feature scaffold publish create-pr
  onboard init scaffold-add check-deploy resume-ticket changelog
  version-bump migrate-config
)
for skill in "${PIPELINE_SKILLS[@]}"; do
  file="$REPO_ROOT/skills/$skill/SKILL.md"
  if ! grep -q "^disable-model-invocation: true" "$file"; then
    fail "skills/$skill/SKILL.md missing disable-model-invocation: true"
  fi
done
```

**Assertion 2: All 11 read-only skills do NOT have `disable-model-invocation`**
```bash
READONLY_SKILLS=(
  analyze-bug check-setup status dashboard metrics estimate
  prioritize template scaffold-validate version-check discuss
)
for skill in "${READONLY_SKILLS[@]}"; do
  file="$REPO_ROOT/skills/$skill/SKILL.md"
  if grep -q "disable-model-invocation" "$file"; then
    fail "skills/$skill/SKILL.md should NOT have disable-model-invocation"
  fi
done
```
