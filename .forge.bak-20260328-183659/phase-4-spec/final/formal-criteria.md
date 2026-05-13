# Formal Acceptance Criteria — version-check Fix (v5.5.1)

## Criteria

### AC1: No hardcoded plugin name outside Plugin Identity table

**Requirement:** The string `ceos-agents` must NOT appear anywhere in `commands/version-check.md` except:
1. Inside the Plugin Identity table's Value column (exactly 2 occurrences: Plugin and Marketplace rows)

**Verification:** `grep -c 'ceos-agents' commands/version-check.md` returns exactly 2. Both matches are inside the Plugin Identity table.

---

### AC2: No hardcoded URLs anywhere

**Requirement:** The string `https://gitea.internal.ceosdata.com` (or any other literal URL) must NOT appear in `commands/version-check.md`.

**Verification:** `grep -c 'https\?://' commands/version-check.md` returns 0.

---

### AC3: Running from /tmp produces correct installed version

**Requirement:** When CWD is `/tmp` (no `.claude-plugin/` present), Part A executes fully (reads installed_plugins.json, determines installed version, optionally checks remote). Part B is silently skipped.

**Verification:** The steps explicitly state Part B is skipped when `.claude-plugin/plugin.json` is not present in CWD. Part A has no CWD dependency.

---

### AC4: Running from plugin repo produces both installed + repo version

**Requirement:** When CWD is the ceos-agents repository (has `.claude-plugin/plugin.json` with `name: ceos-agents`), both Part A and Part B execute. Part B compares repo version against installed version.

**Verification:** Step 5 checks for `.claude-plugin/plugin.json`, reads `name`, confirms it matches `{plugin}`, then reads `version`. Step 6 compares and displays.

---

### AC5: Missing installed_plugins.json produces clear error message

**Requirement:** When `~/.claude/plugins/installed_plugins.json` does not exist, the command outputs a message containing "not found" or "No plugins installed" and STOPs. It does NOT proceed to check remote versions or repo versions.

**Verification:** Step 1 explicitly guards: "If the file does not exist -> report ... and STOP."

---

### AC6: Missing repository field produces graceful skip of remote check

**Requirement:** When the plugin entry exists in `installed_plugins.json` but `{install_path}/.claude-plugin/plugin.json` has no `repository` field, the command:
1. Reports that remote check is skipped with a clear reason
2. Shows the installed version
3. Continues to Part B if applicable

It does NOT attempt `git ls-remote` with an empty or hardcoded URL.

**Verification:** Step 3 explicitly guards: "If ... the `repository` field is missing or empty -> report: 'Remote version check skipped' ... Skip to step 4."

---

### AC7: Annotated tags filtered

**Requirement:** The `git ls-remote` pipeline includes `grep -v '\^{}'` to filter out annotated tag dereference lines (e.g., `v5.5.1^{}`). Only the tag reference itself is used for version extraction.

**Verification:** The bash pipeline in step 3 contains `grep -v '\^{}'` between `git ls-remote` and `sort`.

---

### AC8: Semver comparison correct for 5.10.0 > 5.9.0

**Requirement:** The version comparison logic handles multi-digit version components correctly. Specifically, `5.10.0` must be recognized as newer than `5.9.0` (not the other way around, as string comparison would produce).

**Verification:** Step 4 includes both:
1. Conceptual instruction: "split each on `.` and compare each component ... as integers — NOT as strings"
2. Bash implementation: `printf '%s\n' "$installed_version" "$remote_version" | sort -V | head -1`

Both methods produce the correct result for `5.10.0` vs `5.9.0`.

---

### AC9: docs/reference/commands.md updated if needed

**Requirement:** The /version-check section in `docs/reference/commands.md` accurately describes the new behavior. It must:
1. Not mention Part C
2. Mention `installed_plugins.json` as the source
3. Mention graceful degradation when remote is unreachable

**Verification:** The section at lines 621-639 is updated to reflect the 2-part structure.

---

### AC10: CHANGELOG.md v5.5.1 entry accurate

**Requirement:** The v5.5.1 changelog entry accurately reflects all changes made:
1. Mentions removal of hardcoded URL
2. Mentions Plugin Identity table / genericity
3. Mentions removal of Part C (legacy cleanup)
4. Mentions semver comparison fix
5. Mentions annotated tag filtering
6. Mentions error handling improvements
7. Does NOT mention Part C as a feature (since it was removed)

**Verification:** Read the [5.5.1] section and confirm all 7 sub-requirements are met.

---

## Summary Table

| AC | Short Name | Criticality | Automated Check Possible |
|----|-----------|-------------|--------------------------|
| AC1 | No hardcoded plugin name | HIGH | YES — grep count |
| AC2 | No hardcoded URLs | HIGH | YES — grep count |
| AC3 | Works from /tmp | HIGH | Manual — step walkthrough |
| AC4 | Works from plugin repo | HIGH | Manual — step walkthrough |
| AC5 | Missing registry error | HIGH | Manual — step walkthrough |
| AC6 | Missing repository graceful | MEDIUM | Manual — step walkthrough |
| AC7 | Annotated tags filtered | MEDIUM | YES — grep for `\^{}` |
| AC8 | Semver multi-digit | HIGH | YES — grep for `sort -V` |
| AC9 | Docs updated | LOW | Manual — read section |
| AC10 | Changelog accurate | LOW | Manual — read section |
