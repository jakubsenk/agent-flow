# Research Answers: Agent 3 — RQ-9, RQ-10, RQ-11

---

### RQ-9: How do xref-core-registry.sh and core-include-refs.sh validate core files?

**Finding:** The two scripts use complementary strategies. `xref-core-registry.sh` is fully dynamic — it discovers core files from disk, verifies each is referenced by at least one skill, and cross-checks the claimed count in CLAUDE.md. `core-include-refs.sh` is partially hardcoded — it checks a fixed list of 11 core files and enforces per-skill minimum reference counts.

**Evidence:**

**(a) How core count is extracted from CLAUDE.md** — `xref-core-registry.sh` lines 47–57:
```bash
# Line 47: FS_COUNT="${#CORE_FILES[@]}"
# Line 50: CLAIMED=$(grep '`core/`' "$CLAUDE_MD" | grep 'shared' | grep -oE '[0-9]+' | head -1)
# Line 55: if [ "$CLAIMED" -ne "$FS_COUNT" ]; then
#   fail "CLAUDE.md claims $CLAIMED core files but core/ contains $FS_COUNT files (${CORE_FILES[*]})"
```
It greps for the backtick-quoted `` `core/` `` on a line containing "shared", extracts the first integer with `-oE '[0-9]+'`, and compares it against the live filesystem count.

**(b) Whether the array is hardcoded or dynamic:**

- `xref-core-registry.sh` lines 28: **fully dynamic** — `mapfile -t CORE_FILES < <(ls "$CORE_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | sort)` — enumerates real files from disk.
- `core-include-refs.sh` lines 12–24: **hardcoded array** — lists 11 specific names:
  ```bash
  CORE_FILES=(
    config-reader mcp-preflight mcp-detection fixer-reviewer-loop
    block-handler agent-override-injector decomposition-heuristics
    profile-parser post-publish-hook fix-verification state-manager
  )
  ```
  Note: the script comment on line 11 says "All 10 core files exist" but the array contains **11 entries** — a stale comment mismatch.

**(c) Minimum reference counts per skill** — `core-include-refs.sh` lines 60–63:
```bash
check_refs "fix-ticket"         7
check_refs "fix-bugs"           7
check_refs "implement-feature"  6
check_refs "scaffold"           3
```
Only 4 pipeline skills are checked. The `check_refs` function (lines 44–56) counts `grep -c 'core/'` matches in the skill's SKILL.md and fails if the count is below the minimum.

**Surprise/Note:** `xref-core-registry.sh` does NOT check that core files have any internal structure — it only checks that a reference string like `core/{name}` exists somewhere in any skill file. `core-include-refs.sh` also checks that each core file has all 4 standard sections (## Purpose, ## Input, ## Output, ## Failure), which `xref-core-registry.sh` does not. The hardcoded array in `core-include-refs.sh` is the brittle path — adding a new core file to disk will not automatically add it to the validation unless the array is updated manually.

---

### RQ-10: What test patterns exist for validating agent Constraints sections?

**Finding:** There are three tiers of Constraints validation. `section-order.sh` only checks that the ## Constraints section *exists* and appears after ## Process — it never reads the content. `read-only-agents.sh` checks the *Process* section for write-tool phrases (not the Constraints section). The dedicated AC tests (ac3, ac4, ac5) are the only tests that actually parse and validate Constraints *content*, and they do so for specific named agents only (triage-analyst, code-analyst, fixer, reviewer).

**Evidence:**

**(a) Whether any test scans Constraints content:**

- `section-order.sh` lines 26–56: only extracts line numbers of section headings and checks ordering — no content inspection:
  ```bash
  constraints_line=$(grep -n "^## Constraints" "$file" | head -1 | cut -d: -f1)
  # ...
  if [ "$process_line" -ge "$constraints_line" ]; then
    fail "$agent.md: ## Process must come before ## Constraints (lines $process_line vs $constraints_line)"
  fi
  ```

- `read-only-agents.sh` lines 28–45: scans the **Process section only** (not Constraints) for write-tool phrases using `awk '/^## Process/{found=1} found && /^## Constraints/{found=0} found{print}'`. The Constraints section itself is not inspected.

- `ac3-triage-token-constraints.sh` lines 18–43: **does** read Constraints content — uses `awk '/^## Constraints/,/^## [^C]/'` to extract the section, then checks for MUST-based rules with specific tokens (PASS, UNCLEAR, "quality gate", "reproduction steps", "json array").

- `ac4-codeanalyst-token-constraints.sh` lines 18–56: **does** read Constraints content — checks for MUST rules for "root cause confirmed" (YES/NO) and "risk level" (LOW/MEDIUM/HIGH).

- `ac5-fixer-reviewer-token-constraints.sh` lines 24–83: **does** read Constraints content — checks fixer.md for a MUST rule containing "NEEDS_DECOMPOSITION", and reviewer.md for MUST rules covering Verdict tokens (APPROVE/REQUEST_CHANGES/BLOCK) and AC fulfillment tokens (FULFILLED/PARTIALLY/NOT ADDRESSED).

**(b) What patterns exist for per-agent validation:**

The AC constraint tests all follow the same pattern:
1. Extract Constraints section with `awk '/^## Constraints/{found=1} found{print}'`
2. Check for imperative keywords (MUST, NEVER) combined with specific token strings using piped `grep`
3. Validate both the *keyword* (MUST) and the *token values* are present on the same line (using `grep "MUST" | grep "TOKEN"`)
4. Report exact failure messages identifying which agent, which rule, and which token is missing

Coverage is narrow: only 4 agents have Constraints content tests (triage-analyst, code-analyst, fixer, reviewer). The remaining 17 agents have no content-level Constraints validation.

**Surprise/Note:** `read-only-agents.sh` (lines 13–18) lists 9 agents but scans only the Process section for write-tool phrases, not the Constraints section. This is intentional (the architectural rule is about what Process *instructs* the agent to do) but creates a gap — a Constraints section could say "Write tool is allowed" without any test catching it.

---

### RQ-11: How does state-schema.sh validate the schema?

**Finding:** There are two separate state schema test files: `state-schema.sh` (infrastructure-level validation) and `test-state-schema.sh` (field-level TDD test). `state-schema.sh` validates structural presence (schema_version, atomic-write semantics, state.json references in skills) but does NOT validate individual field definitions. `test-state-schema.sh` validates specific field content (tracker_issue_id in Subtask Object Fields with correct type).

**Evidence:**

**(a) How field presence is validated:**

`state-schema.sh` validates at the infrastructure level only:

- Lines 20–22: checks `schema_version` string exists in the file:
  ```bash
  if ! grep -q "schema_version" "$REPO_ROOT/state/schema.md"; then
    fail "state/schema.md does not contain 'schema_version' field"
  fi
  ```

- Lines 35–41: checks `core/state-manager.md` has `.tmp` and `rename` (atomic write protocol):
  ```bash
  if ! grep -q "\.tmp" "$STATE_MGR"; then
    fail "core/state-manager.md missing .tmp atomic write pattern"
  fi
  if ! grep -qi "rename" "$STATE_MGR"; then
    fail "core/state-manager.md missing rename step in atomic write protocol"
  fi
  ```

- Lines 44–51: checks all 4 pipeline skills reference `state.json` or `state-manager` at least 5 times each.

- Lines 54–62: checks `resume-ticket/SKILL.md` has `state.json` and `fall.back|fallback` language.

`test-state-schema.sh` adds field-level validation for `tracker_issue_id`:

- Lines 22–24: checks field name exists anywhere in schema.md:
  ```bash
  if ! grep -q 'tracker_issue_id' "$SCHEMA" 2>/dev/null; then
    fail "FC-7: 'tracker_issue_id' field not found in state/schema.md"
  fi
  ```

- Lines 30–38: validates positional placement — `tracker_issue_id` must appear on a line *after* the "Subtask Object Fields" section header.

- Lines 44–48: validates the row contains `string.*null|null.*string` (type "string or null").

- Lines 55–59: validates no bare `tracker_id` field definition exists (field naming contract, FC-17).

**(b) What must change for plugin_version:**

`state-schema.sh` checks only for the string `schema_version` in schema.md (line 20). It does not check for `plugin_version` at all. The `state/schema.md` Top-Level Field Definitions table (lines 140–238) also contains no `plugin_version` field — the schema example (lines 34–136) has `schema_version` but no `plugin_version`.

To add `plugin_version` to the schema, three changes would be needed:
1. Add `plugin_version` to the JSON example block in `state/schema.md`
2. Add a row for `plugin_version` to the Top-Level Field Definitions table in `state/schema.md`
3. Update `state-schema.sh` to grep for `plugin_version` (currently it only checks `schema_version`)

Neither `state-schema.sh` nor `test-state-schema.sh` would catch a missing `plugin_version` field because neither test mentions that string.

**Surprise/Note:** `sprint-state-schema.sh` exists as a third schema test but it only validates sprint/backlog RUN-ID formats and the presence of `schema_version` — no field-level checks. The `test-state-schema.sh` file has a header comment saying "TDD red phase: expects FAIL on pre-implementation codebase" (line 5), indicating it was written as a TDD red test and then the implementation was added — it is currently expected to pass.
