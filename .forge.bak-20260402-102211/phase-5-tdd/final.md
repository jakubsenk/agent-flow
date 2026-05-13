# Phase 5 TDD: Test Suite Updates for Commands-to-Skills Migration (v6.0.0)

Generated: 2026-04-01
Spec source: `.forge/phase-4-spec/final/requirements.md` + `formal-criteria.md`

---

## 1. Change Classification Table

Every test file in `tests/scenarios/` is listed with its change classification.

| # | File | Change Type | Commands/ refs | Summary |
|---|------|-------------|---------------|---------|
| 1 | `browser-verification-skip.sh` | PATH_SWAP | 6 | `commands/$cmd.md` → `skills/$cmd/SKILL.md` |
| 2 | `config-required-keys.sh` | DIR_VAR + GUARD | 2 | `COMMANDS_DIR` var + guard message |
| 3 | `core-include-refs.sh` | PATH_SWAP | 1 | `commands/${cmd}.md` → `skills/${cmd}/SKILL.md` |
| 4 | `fixer-retry.sh` | NONE | 0 | No changes needed |
| 5 | `frontmatter-completeness.sh` | NONE | 0 | No changes needed |
| 6 | `happy-path.sh` | COUNT + PATH_SWAP | 2 | ls glob → find SKILL.md; count ≥ 24 → ≥ 25 |
| 7 | `model-assignment.sh` | NONE | 0 | No changes needed |
| 8 | `no-mcp-jargon-errors.sh` | PATH_SWAP (bulk) | 15 | All `commands/{name}.md` → `skills/{name}/SKILL.md` |
| 9 | `pipeline-agent-dispatch-models.sh` | PATH_SWAP | 2 | `commands/$cmd.md` → `skills/$cmd/SKILL.md` |
| 10 | `pipeline-consistency.sh` | NONE | 0 | No changes needed |
| 11 | `pipeline-deploy-verifier.sh` | PATH_SWAP | 3 | `commands/check-deploy.md` → `skills/check-deploy/SKILL.md` |
| 12 | `pipeline-feature-agents.sh` | PATH_SWAP | 2 | `commands/implement-feature.md` → `skills/implement-feature/SKILL.md` |
| 13 | `pipeline-feature-step-order.sh` | PATH_SWAP | 3 | `commands/implement-feature.md` → `skills/implement-feature/SKILL.md` |
| 14 | `pipeline-hook-order.sh` | PATH_SWAP | 1 | `commands/$cmd.md` → `skills/$cmd/SKILL.md` |
| 15 | `pipeline-state-writes.sh` | PATH_SWAP | 8 | All individual command paths + loop |
| 16 | `profile-skip.sh` | PATH_SWAP | 1 | `commands/$cmd.md` → `skills/$cmd/SKILL.md` |
| 17 | `publish-success.sh` | NONE | 0 | No changes needed |
| 18 | `read-only-agents.sh` | NONE | 0 | No changes needed |
| 19 | `reviewer-reject.sh` | NONE | 0 | No changes needed |
| 20 | `scaffold-canary-announcement.sh` | PATH_SWAP | 1 | `commands/scaffold.md` → `skills/scaffold/SKILL.md` |
| 21 | `scaffold-infra-flag-format.sh` | PATH_SWAP | 1 | `commands/scaffold.md` → `skills/scaffold/SKILL.md` |
| 22 | `scaffold-resume-infra-override.sh` | PATH_SWAP | 1 | `commands/scaffold.md` → `skills/scaffold/SKILL.md` |
| 23 | `scaffold-v2-happy-path.sh` | PATH_SWAP | 1 | `commands/scaffold.md` → `skills/scaffold/SKILL.md` |
| 24 | `scaffold-v2-input-conflicts.sh` | PATH_SWAP | 1 | `commands/scaffold.md` → `skills/scaffold/SKILL.md` |
| 25 | `scaffold-v2-no-implement.sh` | PATH_SWAP | 1 | `commands/scaffold.md` → `skills/scaffold/SKILL.md` |
| 26 | `scaffold-v2-spec-loop.sh` | PATH_SWAP | 1 | `commands/scaffold.md` → `skills/scaffold/SKILL.md` |
| 27 | `scaffold-v561-regression.sh` | PATH_SWAP | 1 | `commands/scaffold.md` → `skills/scaffold/SKILL.md` |
| 28 | `section-order.sh` | NONE | 0 | No changes needed |
| 29 | `state-schema.sh` | PATH_SWAP | 2 | Loop + `commands/resume-ticket.md` |
| 30 | `test-fail.sh` | NONE | 0 | No changes needed |
| 31 | `triage-block.sh` | NONE | 0 | No changes needed |
| 32 | `verify-fail.sh` | PATH_SWAP | 3 | Three explicit command paths |
| 33 | `xref-agent-registry.sh` | NONE | 0 | No changes needed |
| 34 | `xref-command-count.sh` | CONCEPT_RENAME | 5 | Full rename: commands → skills, count method change |
| 35 | `xref-core-registry.sh` | DIR_VAR + GREP | 3 | `COMMANDS_DIR` var + grep pattern + error messages |
| 36 | `xref-skip-stage-names.sh` | PATH_SWAP | 2 | `commands/$cmd.md` → `skills/$cmd/SKILL.md` |
| 37 | `config-reader-sections.sh` | NONE | 0 | No changes needed |
| **NEW** | `skills-frontmatter-check.sh` | NEW | — | FC-4 + FC-5 + FC-6 |
| **NEW** | `skills-directory-structure.sh` | NEW | — | FC-1 + FC-2 + FC-3 |

**Change types:**
- `PATH_SWAP` — replace `commands/{name}.md` with `skills/{name}/SKILL.md`
- `DIR_VAR` — rename directory variable (`COMMANDS_DIR` → `SKILLS_DIR`)
- `COUNT` — update count assertion and glob method
- `CONCEPT_RENAME` — rename "command" concept throughout to "skill"
- `NONE` — no changes needed
- `NEW` — brand new test file

---

## 2. Exact Find→Replace Patterns Per File

### 2.1 GROUP A — Simple `SCAFFOLD_CMD` files (identical change, 8 files)

Files: `scaffold-canary-announcement.sh`, `scaffold-infra-flag-format.sh`,
`scaffold-resume-infra-override.sh`, `scaffold-v2-happy-path.sh`,
`scaffold-v2-input-conflicts.sh`, `scaffold-v2-no-implement.sh`,
`scaffold-v2-spec-loop.sh`, `scaffold-v561-regression.sh`

Each file contains exactly one line like:
```bash
SCAFFOLD_CMD="$REPO_ROOT/commands/scaffold.md"
```

Replace with:
```bash
SCAFFOLD_CMD="$REPO_ROOT/skills/scaffold/SKILL.md"
```

No other changes required in these files.

---

### 2.2 GROUP B — Simple `$cmd` loop files (identical change, 5 files)

Files: `browser-verification-skip.sh`, `pipeline-hook-order.sh`,
`pipeline-agent-dispatch-models.sh`, `profile-skip.sh`, `xref-skip-stage-names.sh`

Each file contains a loop-variable reference:
```bash
"$REPO_ROOT/commands/$cmd.md"
```

Replace with:
```bash
"$REPO_ROOT/skills/$cmd/SKILL.md"
```

Error message strings that contain `commands/$cmd.md` should also be updated:
```bash
fail "commands/$cmd.md missing ..."
# becomes:
fail "skills/$cmd/SKILL.md missing ..."

fail "Missing command file: commands/$cmd.md"
# becomes:
fail "Missing skill file: skills/$cmd/SKILL.md"
```

---

### 2.3 `browser-verification-skip.sh` — Full changes

```
FIND:    "$REPO_ROOT/commands/$cmd.md"
REPLACE: "$REPO_ROOT/skills/$cmd/SKILL.md"

FIND:    fail "commands/$cmd.md missing browser_verification_enabled guard"
REPLACE: fail "skills/$cmd/SKILL.md missing browser_verification_enabled guard"

FIND:    fail "commands/$cmd.md missing reproducer stage mapping"
REPLACE: fail "skills/$cmd/SKILL.md missing reproducer stage mapping"

FIND:    fail "commands/$cmd.md missing browser-verifier stage mapping"
REPLACE: fail "skills/$cmd/SKILL.md missing browser-verifier stage mapping"
```

---

### 2.4 `core-include-refs.sh` — Full changes

```
FIND:    local f="$REPO_ROOT/commands/${cmd}.md"
REPLACE: local f="$REPO_ROOT/skills/${cmd}/SKILL.md"

FIND:    fail "${cmd}.md does not exist"
REPLACE: fail "skills/${cmd}/SKILL.md does not exist"
```

Also update the comment on the function:
```
FIND:    # 3. Pipeline commands reference core/ files
REPLACE: # 3. Pipeline skills reference core/ files
```

---

### 2.5 `verify-fail.sh` — Full changes

```
FIND:    if grep -q "Fix Verification" "$REPO_ROOT/commands/fix-ticket.md"; then
REPLACE: if grep -q "Fix Verification" "$REPO_ROOT/skills/fix-ticket/SKILL.md"; then

FIND:    echo "FAIL: fix-ticket missing Fix Verification step"
         (no change to error text — step name is correct)

FIND:    if grep -q "Fix Verification" "$REPO_ROOT/commands/fix-bugs.md"; then
REPLACE: if grep -q "Fix Verification" "$REPO_ROOT/skills/fix-bugs/SKILL.md"; then

FIND:    if grep -q "Feature Verification" "$REPO_ROOT/commands/implement-feature.md"; then
REPLACE: if grep -q "Feature Verification" "$REPO_ROOT/skills/implement-feature/SKILL.md"; then
```

---

### 2.6 `pipeline-feature-agents.sh` — Full changes

```
FIND:    IF="$REPO_ROOT/commands/implement-feature.md"
REPLACE: IF="$REPO_ROOT/skills/implement-feature/SKILL.md"

FIND:    fail "commands/implement-feature.md does not exist"
REPLACE: fail "skills/implement-feature/SKILL.md does not exist"
```

---

### 2.7 `pipeline-feature-step-order.sh` — Full changes

```
FIND:    CMD_FILE="$REPO_ROOT/commands/implement-feature.md"
REPLACE: CMD_FILE="$REPO_ROOT/skills/implement-feature/SKILL.md"

FIND:    fail "commands/implement-feature.md not found"
REPLACE: fail "skills/implement-feature/SKILL.md not found"

FIND:    fail "No step headings found in commands/implement-feature.md"
REPLACE: fail "No step headings found in skills/implement-feature/SKILL.md"
```

---

### 2.8 `pipeline-deploy-verifier.sh` — Full changes

```
FIND:    CD="$REPO_ROOT/commands/check-deploy.md"
REPLACE: CD="$REPO_ROOT/skills/check-deploy/SKILL.md"

FIND:    # 4. commands/check-deploy.md exists
REPLACE: # 4. skills/check-deploy/SKILL.md exists

FIND:    fail "commands/check-deploy.md does not exist"
REPLACE: fail "skills/check-deploy/SKILL.md does not exist"
```

---

### 2.9 `pipeline-state-writes.sh` — Full changes

```
FIND:    FT="$REPO_ROOT/commands/fix-ticket.md"
REPLACE: FT="$REPO_ROOT/skills/fix-ticket/SKILL.md"

FIND:    fail "commands/fix-ticket.md does not exist"
REPLACE: fail "skills/fix-ticket/SKILL.md does not exist"

FIND:    IF="$REPO_ROOT/commands/implement-feature.md"
REPLACE: IF="$REPO_ROOT/skills/implement-feature/SKILL.md"

FIND:    fail "commands/implement-feature.md does not exist"
REPLACE: fail "skills/implement-feature/SKILL.md does not exist"

FIND:    SC="$REPO_ROOT/commands/scaffold.md"
REPLACE: SC="$REPO_ROOT/skills/scaffold/SKILL.md"

FIND:    fail "commands/scaffold.md does not exist"
REPLACE: fail "skills/scaffold/SKILL.md does not exist"

FIND:    CD="$REPO_ROOT/commands/check-deploy.md"
REPLACE: CD="$REPO_ROOT/skills/check-deploy/SKILL.md"

FIND:    fail "commands/check-deploy.md does not exist"
REPLACE: fail "skills/check-deploy/SKILL.md does not exist"
```

---

### 2.10 `state-schema.sh` — Full changes

```
FIND:    CMD_FILE="$REPO_ROOT/commands/${cmd}.md"
REPLACE: CMD_FILE="$REPO_ROOT/skills/${cmd}/SKILL.md"

FIND:    RESUME="$REPO_ROOT/commands/resume-ticket.md"
REPLACE: RESUME="$REPO_ROOT/skills/resume-ticket/SKILL.md"
```

---

### 2.11 `no-mcp-jargon-errors.sh` — Full changes

```
FIND:    "commands/analyze-bug.md"
REPLACE: "skills/analyze-bug/SKILL.md"

FIND:    "commands/changelog.md"
REPLACE: "skills/changelog/SKILL.md"

FIND:    "commands/create-pr.md"
REPLACE: "skills/create-pr/SKILL.md"

FIND:    "commands/dashboard.md"
REPLACE: "skills/dashboard/SKILL.md"

FIND:    "commands/estimate.md"
REPLACE: "skills/estimate/SKILL.md"

FIND:    "commands/metrics.md"
REPLACE: "skills/metrics/SKILL.md"

FIND:    "commands/prioritize.md"
REPLACE: "skills/prioritize/SKILL.md"

FIND:    "commands/status.md"
REPLACE: "skills/status/SKILL.md"

FIND:    "commands/resume-ticket.md"
REPLACE: "skills/resume-ticket/SKILL.md"

FIND:    "commands/scaffold-add.md"
REPLACE: "skills/scaffold-add/SKILL.md"

FIND:    "commands/fix-bugs.md"
REPLACE: "skills/fix-bugs/SKILL.md"

FIND:    "commands/publish.md"
REPLACE: "skills/publish/SKILL.md"

FIND:    "commands/scaffold.md"
REPLACE: "skills/scaffold/SKILL.md"

FIND:    "commands/implement-feature.md"
REPLACE: "skills/implement-feature/SKILL.md"

FIND:    SCAFFOLD="$REPO_ROOT/commands/scaffold.md"
REPLACE: SCAFFOLD="$REPO_ROOT/skills/scaffold/SKILL.md"
```

Note: The variable `$rel_path` is used as a relative path for constructing `$REPO_ROOT/$rel_path`.
After the above replacements, file access via `"$REPO_ROOT/$rel_path"` will resolve correctly to
`$REPO_ROOT/skills/{name}/SKILL.md`. The `$f` assignments do not need separate changes.

---

### 2.12 `pipeline-agent-dispatch-models.sh` — Full changes

```
FIND:    cmd_file="$REPO_ROOT/commands/$cmd.md"
REPLACE: cmd_file="$REPO_ROOT/skills/$cmd/SKILL.md"

FIND:    fail "Missing command file: commands/$cmd.md"
REPLACE: fail "Missing skill file: skills/$cmd/SKILL.md"
```

---

### 2.13 `pipeline-hook-order.sh` — Full changes

```
FIND:    local file="$REPO_ROOT/commands/$cmd.md"
REPLACE: local file="$REPO_ROOT/skills/$cmd/SKILL.md"

FIND:    [ -f "$file" ] || { fail "$cmd.md not found"; return; }
REPLACE: [ -f "$file" ] || { fail "skills/$cmd/SKILL.md not found"; return; }
```

---

### 2.14 `profile-skip.sh` — Full changes

```
FIND:    CMD_FILE="$REPO_ROOT/commands/$cmd.md"
REPLACE: CMD_FILE="$REPO_ROOT/skills/$cmd/SKILL.md"

FIND:    [ -f "$CMD_FILE" ] || { echo "FAIL: $cmd.md not found"; exit 1; }
REPLACE: [ -f "$CMD_FILE" ] || { echo "FAIL: skills/$cmd/SKILL.md not found"; exit 1; }
```

---

### 2.15 `xref-skip-stage-names.sh` — Full changes

```
FIND:    CMD_FILE="$REPO_ROOT/commands/$cmd.md"   (appears twice, in two loops)
REPLACE: CMD_FILE="$REPO_ROOT/skills/$cmd/SKILL.md"
```

---

### 2.16 `config-required-keys.sh` — Full changes (DIR_VAR type)

```
FIND:    COMMANDS_DIR="$REPO_ROOT/commands"
REPLACE: SKILLS_DIR="$REPO_ROOT/skills"

FIND:    [ -d "$COMMANDS_DIR" ] || { echo "FAIL: commands/ directory not found"; exit 1; }
REPLACE: [ -d "$SKILLS_DIR" ] || { echo "FAIL: skills/ directory not found"; exit 1; }

FIND:    # Search all commands/*.md for the key (case-insensitive)
REPLACE: # Search all skills/*/SKILL.md for the key (case-insensitive)

FIND:    matches=$(grep -ril "$key" "$COMMANDS_DIR"/*.md 2>/dev/null || true)
REPLACE: matches=$(grep -ril "$key" "$SKILLS_DIR"/*/SKILL.md 2>/dev/null || true)

FIND:    echo "OK: required key '$key' referenced in: $(echo "$matches" | xargs -I{} basename {} | tr '\n' ' ')"
REPLACE: echo "OK: required key '$key' referenced in at least one skill"

FIND:    [ "$FAIL" -eq 0 ] && echo "PASS: all required config keys are consumed by at least one command"
REPLACE: [ "$FAIL" -eq 0 ] && echo "PASS: all required config keys are consumed by at least one skill"
```

Note on the `OK:` line: `xargs -I{} basename {}` produces just the filename (`SKILL.md`) for every
match, which is not informative. Replace with a simpler message that still prints which key matched.

---

### 2.17 `xref-core-registry.sh` — Full changes (DIR_VAR + GREP type)

```
FIND:    COMMANDS_DIR="$REPO_ROOT/commands"
REPLACE: SKILLS_DIR="$REPO_ROOT/skills"

FIND:    if [ ! -d "$COMMANDS_DIR" ]; then
           fail "commands/ directory not found at $COMMANDS_DIR"
REPLACE: if [ ! -d "$SKILLS_DIR" ]; then
           fail "skills/ directory not found at $SKILLS_DIR"

FIND:    match_count=$(grep -rl "$ref" "$COMMANDS_DIR"/*.md 2>/dev/null | wc -l)
REPLACE: match_count=$(grep -rl "$ref" "$SKILLS_DIR"/*/SKILL.md 2>/dev/null | wc -l)

FIND:    fail "core/$name.md is not referenced by any command in commands/ (searched for '$ref')"
REPLACE: fail "core/$name.md is not referenced by any skill in skills/ (searched for '$ref')"

FIND:    [ "$FAIL" -eq 0 ] && echo "PASS: All $FS_COUNT core files are referenced by at least one command, and CLAUDE.md count matches"
REPLACE: [ "$FAIL" -eq 0 ] && echo "PASS: All $FS_COUNT core files are referenced by at least one skill, and CLAUDE.md count matches"
```

Also update the `COMMANDS_DIR` variable everywhere it appears (including the `exit` check).

---

### 2.18 `xref-command-count.sh` — Full changes (CONCEPT_RENAME type)

This file's entire `commands/` block is replaced. The new concept counts SKILL.md files under `skills/`.

```
FIND (whole block, lines 43–51):
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

REPLACE WITH:
# ---- skills/ ----
SKILLS_FS=$(find "$REPO_ROOT/skills" -name "SKILL.md" | wc -l | tr -d ' ')
SKILLS_CLAIMED=$(extract_claimed "skills")

if [ -z "$SKILLS_CLAIMED" ]; then
  fail "Could not find a numeric count claim for skills/ in CLAUDE.md"
else
  if [ "$SKILLS_CLAIMED" -ne "$SKILLS_FS" ]; then
    fail "skills/: CLAUDE.md claims $SKILLS_CLAIMED but filesystem has $SKILLS_FS SKILL.md files"
  fi
fi
```

Also update the final PASS message:

```
FIND:    [ "$FAIL" -eq 0 ] && echo "PASS: CLAUDE.md count claims match filesystem — agents: $AGENTS_FS, commands: $COMMANDS_FS, core: $CORE_FS"
REPLACE: [ "$FAIL" -eq 0 ] && echo "PASS: CLAUDE.md count claims match filesystem — agents: $AGENTS_FS, skills: $SKILLS_FS, core: $CORE_FS"
```

And the script's comment header:

```
FIND:    # Test: Numeric count claims in CLAUDE.md match actual filesystem counts for agents/, commands/, core/
REPLACE: # Test: Numeric count claims in CLAUDE.md match actual filesystem counts for agents/, skills/, core/
```

Note: The `count_md` helper function (which counts `*.md` files) is NOT used for skills anymore.
The new `SKILLS_FS` count uses `find ... -name "SKILL.md"` which is the correct method — there is
one SKILL.md per skill directory, not arbitrary `*.md` files.

The `extract_claimed` helper still works for `skills` if CLAUDE.md contains a line like:
`` `skills/` — 26 skill definitions ``
(which the migration will add). No change to the helper function itself is needed.

---

## 3. New Test Scripts

### 3.1 `skills-frontmatter-check.sh`

Verifies FC-4, FC-5, FC-6.

Source: see `.forge/phase-5-tdd/tests/scenarios/skills-frontmatter-check.sh`

### 3.2 `skills-directory-structure.sh`

Verifies FC-1, FC-2, FC-3.

Source: see `.forge/phase-5-tdd/tests/scenarios/skills-directory-structure.sh`

---

## 4. Test Count Summary

| Category | Count |
|----------|-------|
| Existing tests with NO changes | 13 |
| Existing tests updated (PATH_SWAP, DIR_VAR, CONCEPT_RENAME) | 24 |
| New tests added | 2 |
| **Total after migration** | **39** |

The FC-8 criterion in `formal-criteria.md` states "Expected: 38 scenarios". This plan produces 39
because it adds 2 new scripts (not 1). The FC-8 check text should be treated as a minimum — the
harness counts whatever `.sh` files exist in `tests/scenarios/`. Both new tests will PASS after
the migration is complete, so the harness exit code will be 0.

### Breakdown of existing 37 tests:

| Status | Files |
|--------|-------|
| NONE (no changes) | `fixer-retry.sh`, `frontmatter-completeness.sh`, `model-assignment.sh`, `pipeline-consistency.sh`, `publish-success.sh`, `read-only-agents.sh`, `reviewer-reject.sh`, `section-order.sh`, `test-fail.sh`, `triage-block.sh`, `xref-agent-registry.sh`, `config-reader-sections.sh` |
| Updated | All other 25 files listed in section 2 |

---

## 5. FC-7 Compliance Note

After all PATH_SWAP changes are applied to the test files, no `commands/` functional path references
will remain in `tests/scenarios/*.sh`. The FC-7 grep check excludes `.forge/` so this document's
references to `commands/` are safe. The CHANGELOG.md and `docs/plans/` exclusions also cover
historical references in those locations.

---

## 6. CLAUDE.md Changes Required (for xref-command-count.sh to pass)

After migration, CLAUDE.md must be updated so that `extract_claimed "skills"` finds the count.
The Repository Structure section must change:

```
FIND:    - `commands/` — 25 commands (slash commands)
REPLACE: - `skills/` — 26 skill definitions (25 migrated commands + workflow-router)
```

The `extract_claimed` function in `xref-command-count.sh` greps for lines containing
`` `skills/` `` and extracts the first number — so "26" will be found correctly.

This CLAUDE.md change is part of Phase 3/4 of the migration (cross-reference updates), not of
the test suite itself. It is documented here because `xref-command-count.sh` will fail without it.
