# Phase 2 Research Answers — Agent 2 (Senior Plugin Codebase Investigator)

Trait: breadth of coverage — surface adjacent files the questions didn't enumerate.

---

## Q1: How many of the 8 config templates actually contain "Extra labels"?

**Direct Answer:** Exactly 2 of the 8 templates contain `Extra labels`: `github-nextjs.md` and `redmine-oracle-plsql.md`. The remaining 6 have no `Extra labels` row.

**Evidence:**
```
examples/configs/github-nextjs.md:104:### Extra labels (optional)
examples/configs/redmine-oracle-plsql.md:182:### Extra labels (optional)
```
The other 6 (`github-python-fastapi.md`, `github-dotnet.md`, `gitea-spring-boot.md`, `jira-react.md`, `youtrack-python.md`, `redmine-rails.md`) returned zero matches on direct grep.

**Implication for v7.0.0:** Action 1 only needs to edit 2 config template files, not 8. Phase 7 executor must NOT modify the 6 templates that have no `Extra labels` row.

---

## Q2: Complete inventory of `Extra labels` references and undocumented consumers

**Direct Answer:** Every non-bak reference to `Extra labels` / `extra_labels` across the active codebase:

**Skills (consume `Extra labels` section):**
- `skills/fix-ticket/SKILL.md:47` — reads `Extra labels` from config; `SKILL.md:638` passes to publisher
- `skills/fix-bugs/SKILL.md:42` — reads `Extra labels` from config; `SKILL.md:783` passes to publisher
- `skills/implement-feature/SKILL.md:35` — reads `Extra labels`; `SKILL.md:599` passes to publisher
- `skills/onboard/SKILL.md:175` — enumerates `[12] Extra labels — additional PR labels`; `SKILL.md:204` mentions `Extra labels: Labels`
- `skills/migrate-config/SKILL.md:41` — enumerates `Extra labels` in its migration loop
- `skills/check-setup/SKILL.md:56` — enumerates `Extra labels` in its optional section list

**Agents:**
- `agents/publisher.md:69` — "If Extra labels section exists, add those too."

**Core:**
- `core/config-reader.md:31` — `### Extra labels` → `pr_rules.extra_labels` (default: none)

**Docs:**
- `docs/reference/automation-config.md:33` — table row: `| Extra labels | No | /fix-ticket, /fix-bugs, /implement-feature |`

**CLAUDE.md:**
- `CLAUDE.md:149` — `| Extra labels | Labels | (none) |` (optional sections table)
- `CLAUDE.md:160` — `There are 19 optional config sections in total.`

**Config templates (2 of 8):**
- `examples/configs/github-nextjs.md:104` — `### Extra labels (optional)`
- `examples/configs/redmine-oracle-plsql.md:182` — `### Extra labels (optional)`

**Tests:**
- `tests/scenarios/config-reader-sections.sh:25` — hardcoded `"Extra labels"` in `OPTIONAL_SECTIONS` array
- `tests/scenarios/v6.9.0-bc-no-renamed-section.sh:25` — hardcoded `"Extra labels"` in its OPTIONAL_SECTIONS array

**UNDOCUMENTED CONSUMERS (spec did NOT list these):**
- `skills/onboard/SKILL.md` — displays `Extra labels` in its interactive menu (item 12) and in its config summary output. Must be updated when the section is deleted.
- `skills/migrate-config/SKILL.md` — iterates over `Extra labels` by name in its migration loop. If the section is deleted, this loop item becomes dead code and should be removed.
- `skills/check-setup/SKILL.md` — validates `Extra labels` as a recognised optional section. Must remove from list.

**Implication for v7.0.0:** Action 1 affects 12+ locations total, not just the 5 listed in the spec. The critical ones to avoid breaking: `core/config-reader.md` (remove the `### Extra labels` parse rule), `agents/publisher.md` (remove the "if Extra labels section exists" branch), and three test files that hardcode the section name.

---

## Q3: Which 6 skills implement pause-on-NEEDS_CLARIFICATION, and does `analyze-bug` qualify?

**Direct Answer:** The 6 pause-emitting skills are `fix-ticket`, `fix-bugs`, `implement-feature`, `scaffold`, `autopilot`, and — per `core/agent-states.md:54` — the 6 webhook-firing sites are distributed across fix-ticket (2: triage + fixer), fix-bugs (2: triage + fixer), implement-feature (1: fixer), scaffold (1: fixer). `autopilot` handles paused pipelines by detecting `status == "paused"` in state.json and either skipping or auto-aborting them (Step 6 / 1a). `resume-ticket` implements the RESUME side only — it reads `state.json.status == "paused"` but does NOT emit a NEEDS_CLARIFICATION block itself.

`analyze-bug` is **interactive-only special case**: `skills/analyze-bug/SKILL.md:26-37` handles NEEDS_CLARIFICATION from triage-analyst by displaying a message and telling the user to re-run — no `state.json` write, no pipeline pause, no resume path. It explicitly does NOT write `state.json` or transition to `paused`.

**Evidence:**
- `core/agent-states.md:54`: "The four orchestrator skills (fix-ticket, fix-bugs, implement-feature, scaffold) inline this snippet at every NEEDS_CLARIFICATION detection site (6 total firing sites...)"
- `skills/analyze-bug/SKILL.md:26-37`: "interactive surface — no state.json, no pipeline pause"
- `skills/resume-ticket/SKILL.md:15-20`: Priority 0 checks if `state.json.status == "paused"` — only reads/resumes, never pauses
- `skills/autopilot/SKILL.md:315`: Step 1a reads `status == "paused"` before dispatch; `SKILL.md:400`: `paused` classified as a known non-error outcome

**Implication for v7.0.0:** The correct 6 for Action 2 doc fix are: `fix-ticket`, `fix-bugs`, `implement-feature`, `scaffold` (4 pause-emitters) + `autopilot` (pause-timeout enforcer) + `resume-ticket` (resume handler). The `docs/reference/automation-config.md` `Pause Limits` table at line 40 currently says `| Pause Limits | No | /autopilot |` — the "Used By" column should list all 6 (or more accurately all 5 pause-dispatch sites + autopilot + resume-ticket).

---

## Q4: Complete inventory of `/ceos-agents:status`, `/ceos-agents:init` references

**Direct Answer:** Active (non-forge, non-bak) files referencing these deprecated identifiers:

### `/ceos-agents:init` references

**Skills:**
- `skills/workflow-router/SKILL.md:20` — intent table row: `| Configure MCP/tokens/permissions | ceos-agents:init | Optional: --update | Yes |`
- `skills/status/SKILL.md:60,82` — user-facing table strings: `Not configured — run /ceos-agents:init`
- `skills/scaffold/SKILL.md:180,183,188,213,217,221,1068,1070,1076,1078,1098` — multiple user-facing output strings and inline instructions referencing `/ceos-agents:init`
- `skills/onboard/SKILL.md:242` — closing message: `Run /ceos-agents:init to configure MCP servers and permissions`
- `skills/init/SKILL.md:202,215,225,263,341` — self-references within the skill (will be renamed)
- `skills/implement-feature/SKILL.md:85` — recommendation string referencing `run /ceos-agents:init`
- `skills/create-backlog/SKILL.md:52` — block recommendation referencing `/ceos-agents:init`
- `skills/check-setup/SKILL.md:68,76` — user-facing failure messages referencing `/ceos-agents:init`

**Core:**
- `core/mcp-preflight.md:36` — Recommendation field: `or /ceos-agents:init to configure the {tracker_type} integration`
- `core/config-reader.md:57` — Recommendation field: `run /ceos-agents:init`

**Docs:**
- `docs/getting-started.md:115,125` — code block `/ceos-agents:init` and prose reference
- `docs/reference/skills.md:398-400,423,427` — syntax block under `### /init` section
- `docs/guides/installation.md:92` — prose referencing `/ceos-agents:init`
- `docs/guides/mcp-configuration.md:5,52` — references to `/ceos-agents:init`
- `docs/guides/troubleshooting.md:225` — recommendation referencing `/ceos-agents:init`

**No test scenarios reference `/ceos-agents:init`** (grep of `tests/**/*.sh` returned no matches).

### `/ceos-agents:status` references

**Skills:**
- `skills/workflow-router/SKILL.md:18` — intent table row: `| Show status/overview | ceos-agents:status | None | No |`
- `skills/status/SKILL.md` — self-references as the skill itself (will be renamed)

**Docs:**
- `docs/reference/skills.md:516,524` — under `### /status` section syntax block
- `docs/guides/troubleshooting.md:311` — recommendation referencing `/ceos-agents:status`

**No test scenarios reference `/ceos-agents:status`.**

**Implication for v7.0.0:** Actions 3 and 4 require edits to approximately 20+ file locations, including 2 core contract files (`core/mcp-preflight.md` and `core/config-reader.md`) that the spec does not enumerate. These core files are high-priority because they propagate via all pipeline skills.

---

## Q5: Exact structure of workflow-router intent table and prose for deprecated skills

**Direct Answer:** All three deprecated skills appear as distinct table rows only — they do NOT appear in the Step 3/4 prose lists. The prose at Step 3 uses category names ("analyze-bug, check-setup, version-check, status...") not the full `/ceos-agents:` prefix.

**Evidence — verbatim table rows** (`skills/workflow-router/SKILL.md:15-20`):

```
| Create a pull request | `ceos-agents:create-pr` | None | Yes |
| Publish (PR + issue state) | `ceos-agents:publish` | None | Yes |
| Show status/overview | `ceos-agents:status` | None | No |
| Configure MCP/tokens/permissions | `ceos-agents:init` | Optional: --update | Yes |
```

**Step 3 prose** (`SKILL.md:54`):
```
3. **If the operation is NOT destructive** (analyze-bug, check-setup, version-check, status, dashboard, metrics, estimate, prioritize, template, scaffold-validate, check-deploy without flags, autopilot --dry-run): invoke the command immediately
4. **If the operation IS destructive** (fix-ticket, fix-bugs, create-pr, publish, check-deploy --start/--stop, autopilot without --dry-run):
```

The Step 4 destructive list also contains `create-pr` as a bare name.

**Implication for v7.0.0:** Three surgical edits needed in workflow-router:
1. Delete the `create-pr` table row (line 15)
2. Replace `ceos-agents:status` → `ceos-agents:pipeline-status` (line 18)
3. Replace `ceos-agents:init` → `ceos-agents:setup-mcp` (line 20)
4. Remove `create-pr` from the Step 4 destructive inline list
5. Remove `status` from the Step 3 non-destructive inline list (since the new skill name changes)
Note: the Step 3 list says `status` as a bare word, not `/ceos-agents:status` — a strict grep for `/ceos-agents:status` would miss this.

---

## Q6: Exact current branch→issue-ID extraction logic in `/publish` and reference implementations

**Direct Answer:** The current `skills/publish/SKILL.md` Step 1 says simply "Determine the current branch and issue ID" without specifying extraction logic. This is intentionally vague — the issue ID is presumed known from context. Fix-ticket and fix-bugs create the branch explicitly via `git checkout -b {branch_naming}` and have the issue ID in scope; they pass it to publisher via Task context. For the auto-detect Action 5, the `Branch naming` pattern from Automation Config is the only parsing guidance.

**Evidence — publish/SKILL.md Steps 1-3:**
```
1. Determine the current branch and issue ID
2. Verify that the current branch has commits above the base branch...
3. Check whether an open PR already exists for the current branch.
```
No explicit regex. The issue ID is assumed available from the branch name but no extraction algorithm is specified.

**Reference implementation in fix-ticket/SKILL.md:** Branch is created at Step 2 as `git checkout -b {branch_naming} {base_branch}`. The issue ID is extracted from `$ARGUMENTS` (the input), not from the branch name. There is no branch→issue-ID reverse extraction in these skills — the issue ID flows forward from input to branch name, not backward.

**Branch naming format:** From `core/config-reader.md:17`, the config key is `source_control.branch_naming`. Common patterns in examples are `fix/{issue-id}-{slug}` or `{issue-id}-{slug}`. There are no capture groups specified — it is a template string, not a regex.

**For auto-detect (Action 5):** The publisher would need to: (a) run `git branch --show-current`, (b) extract the issue ID by stripping the known prefix/suffix of the `Branch naming` template (e.g., if pattern is `fix/{issue-id}-*`, strip `fix/` prefix and strip everything from the first `-` after the issue ID). This is a new parsing step with no existing reference implementation.

**Implication for v7.0.0:** Action 5 requires writing new branch→issue-ID extraction logic in `skills/publish/SKILL.md`. The Branch naming template uses `{issue-id}` as a literal placeholder; the extraction must find the position of `{issue-id}` in the template and extract the corresponding substring from the actual branch name.

---

## Q7: MCP tool names and error semantics per tracker for auto-detect

**Direct Answer:** `core/mcp-detection.md` documents tracker connectivity via "list 1 issue or list projects" — NOT single-issue fetch. There are no specific MCP tool names for fetching a single issue documented in any active file. The `error_type` classification IS documented with 4 error types that can distinguish 404 vs. timeout.

**Evidence — MCP tool prefixes** (`core/mcp-detection.md:27-34`):
```
| youtrack | @vitalyostanin/youtrack-mcp | mcp__youtrack__* |
| github   | @modelcontextprotocol/server-github | mcp__github__* |
| jira     | @modelcontextprotocol/server-atlassian | mcp__jira__* or mcp__atlassian__* |
| linear   | @modelcontextprotocol/server-linear | mcp__linear__* |
| gitea    | forgejo-mcp | mcp__gitea__* or mcp__forgejo__* |
| redmine  | mcp-server-redmine | mcp__redmine__* |
```

**No single-issue fetch tool documented.** The connectivity check uses "list 1 issue from the declared project" (`core/mcp-detection.md:39`). The existing fix-ticket and fix-bugs skills fetch the issue by ID using tracker MCP tools, but no canonical tool name is recorded in core contracts.

**Error semantics** (`core/mcp-detection.md:75-85`):
- `error_type: "not_found"` — 404, ENOTFOUND — maps to "issue not found OR hostname does not resolve"
- `error_type: "timeout"` — ETIMEDOUT, ECONNREFUSED — maps to "tracker unreachable"
- `error_type: "auth"` — 401, 403 — maps to "tracker up but credentials invalid"
- `error_type: "tls"` — certificate error
- `error_type: "unknown"` — all others

**The 3-way fork for auto-detect requires:**
1. `not_found` → issue doesn't exist (or tracker unreachable by DNS) → PR-only mode
2. `timeout` / `auth` / `tls` → tracker down/misconfigured → fail with guidance
3. success → full pipeline (PR + tracker update)

**Implication for v7.0.0:** The exact tool name (e.g., `mcp__youtrack__getIssue`) is NOT in core contracts. Action 5 implementation must use the same "attempt to fetch by ID and classify the error" pattern that fix-ticket already uses implicitly, or follow the mcp-detection.md error_type contract. The absence of documented per-tracker tool names is a gap the spec does not address — Phase 7 executor will need to look at actual MCP server documentation or infer from the "list issues" pattern already used by mcp-detection.md.

---

## Q8: Complete test scenario inventory — HARD-FAIL and false-positives after v7.0.0

**Direct Answer:** The following test scenarios will break or produce misleading results after v7.0.0 changes:

### HARD-FAIL scenarios (will exit non-zero):

1. **`tests/scenarios/regression-skill-count-29.sh`** — line 14: `if [ "$SKILL_COUNT" -ne 29 ]`. After deleting `create-pr/`, count = 28. **ACTION: UPDATE to 28.**

2. **`tests/scenarios/ac-v68-doc-skill-count-29.sh`** — line 15: `grep -nE '29 skills' CLAUDE.md`; line 21: `grep -nE '28 skills' CLAUDE.md` (must NOT have 28). After count update, CLAUDE.md will say 28 — this test must flip both assertions. **ACTION: UPDATE — invert both checks (must say 28, must NOT say 29).**

3. **`tests/scenarios/v6.9.0-doc-count-drift.sh`** — line 42-45: asserts `'19 optional config sections in total'`. Line 56-57: asserts NOT `'18 optional config sections in total'`. After deleting `Extra labels`, CLAUDE.md will say 18, which FAILS assertion 3 AND ALSO FAILS the negative assertion on line 56-57 (see DISAGREEMENT D below). **ACTION: Must be updated to assert 18 AND update the negative assertion to reject 17 (not 18).**

4. **`tests/scenarios/skills-directory-structure.sh`** — line 36: `create-pr` in `EXPECTED_SKILLS` array; line 24: `status` in expected list; line 53 (`init` in expected list). After renames and deletion, `create-pr` directory will not exist, `status/` and `init/` directories will not exist. **ACTION: UPDATE — replace `create-pr` with nothing, `status` with `pipeline-status`, `init` with `setup-mcp`. The FC-2 expected count (29 → 28) also needs updating.**

5. **`tests/scenarios/skills-frontmatter-check.sh`** — line 51: `create-pr` in `PIPELINE_SKILLS` array; line 95: `status` and line 97: `init` in `READONLY_SKILLS` array. After changes, `skills/create-pr/SKILL.md` will not exist. **ACTION: UPDATE — remove `create-pr` from PIPELINE_SKILLS (decrements count from 12 to 11), replace `status` with `pipeline-status`, replace `init` with `setup-mcp`.**

6. **`tests/scenarios/no-mcp-jargon-errors.sh`** — line 15: `"skills/create-pr/SKILL.md"` in `STANDARD_ERROR_FILES`. After deletion, `[ ! -f "$f" ]` fires the `fail "File not found: $rel_path"` path. **ACTION: UPDATE — remove `skills/create-pr/SKILL.md` from the list.**

7. **`tests/scenarios/v6.9.0-bc-no-renamed-section.sh`** — line 25: `"Extra labels"` in its section array. After deletion, CLAUDE.md will not contain `Extra labels`, causing failure. **ACTION: RETIRE (exit 77) if this test strictly validates v6.9.0 backward compat, or UPDATE to remove `Extra labels` from the expected set.**

8. **`tests/scenarios/config-reader-sections.sh`** — line 25: `"Extra labels"` in `OPTIONAL_SECTIONS` array. After deletion of the section, CLAUDE.md will not contain `Extra labels`. **ACTION: UPDATE — remove `Extra labels` from array (decrements count).**

### FALSE-POSITIVE scenarios (will silently PASS when they should flag issues):

9. **`tests/scenarios/ac-v68-doc-optional-sections-18.sh`** — line 14: `grep -nE '(18|19) optional' CLAUDE.md`. After dropping from 19 to 18, CLAUDE.md will say `18 optional config sections in total`, which matches the `(18|19)` regex — the test PASSES even though the count dropped. This is a false acceptance signal. The mutation guard on line 17 only rejects `17 optional`. **ACTION: UPDATE — tighten to `18 optional` only (drop `19` from the OR-pattern) once v7.0.0 is the floor.**

### Summary classification:

| Test | Classification | Action |
|------|---------------|--------|
| `regression-skill-count-29.sh` | HARD-FAIL | UPDATE (29→28) |
| `ac-v68-doc-skill-count-29.sh` | HARD-FAIL | UPDATE (invert 29↔28 assertions) |
| `v6.9.0-doc-count-drift.sh` | HARD-FAIL | UPDATE (19→18, shift negative assertion) |
| `skills-directory-structure.sh` | HARD-FAIL | UPDATE (remove create-pr, rename status/init) |
| `skills-frontmatter-check.sh` | HARD-FAIL | UPDATE (remove create-pr, rename status/init) |
| `no-mcp-jargon-errors.sh` | HARD-FAIL | UPDATE (remove create-pr from list) |
| `v6.9.0-bc-no-renamed-section.sh` | HARD-FAIL | UPDATE (remove Extra labels) or RETIRE |
| `config-reader-sections.sh` | HARD-FAIL | UPDATE (remove Extra labels) |
| `ac-v68-doc-optional-sections-18.sh` | FALSE-POSITIVE | UPDATE (tighten regex post-v7.0.0) |

---

## Q9: Exact line numbers in 5 anchor docs for "29 skills" and "19 optional"

**Direct Answer:**

### "29 skills" occurrences:

| File | Line | Current text |
|------|------|-------------|
| `CLAUDE.md:18` | `skills/ — 29 skills (slash commands, including workflow-router)` | → `28 skills` |
| `README.md:262` | `\| [Skills](docs/reference/skills.md) \| All 29 skills — syntax, flags, examples \|` | → `28 skills` |
| `docs/reference/skills.md:3` | `This reference covers all 29 skills in the ceos-agents plugin. All 29 ceos-agents skills are listed...` | → `28 skills` (both occurrences) |
| `docs/architecture.md:27` | `SKL[29 Skills]` (in mermaid diagram) | → `SKL[28 Skills]` |
| `docs/reference/automation-config.md` | No "29 skills" string found — ABSENT |

### "19 optional" occurrences:

| File | Line | Current text |
|------|------|-------------|
| `CLAUDE.md:160` | `There are 19 optional config sections in total.` | → `18 optional config sections in total` |
| `README.md:221` | `**19 optional sections** cover retry limits...` | → `**18 optional sections**` |
| `docs/reference/automation-config.md:9` | `There are 5 required sections and 19 optional sections.` | → `18 optional sections` |
| `docs/reference/skills.md` | No "19 optional" string found — ABSENT |
| `docs/architecture.md` | No "19 optional" string found — ABSENT |

### Plugin metadata (`.claude-plugin/`):

- `plugin.json` — contains only `name`, `description`, `version`, `author`, `repository`, `license`. No skill count or config section count. NO changes needed.
- `marketplace.json` — same structure, no count strings. NO changes needed.

### `examples/configs/` (grep for `ceos-agents:status`, `ceos-agents:init`, `create-pr`):

All 8 config templates returned no matches for these identifiers. Confirmed zero — examples do not contain deprecated skill invocations.

**Implication for v7.0.0:** The complete change list for counts:
- `CLAUDE.md:18` — `29 skills` → `28 skills`
- `CLAUDE.md:160` — `19 optional config sections in total` → `18 optional config sections in total`
- `README.md:221` — `**19 optional sections**` → `**18 optional sections**`
- `README.md:262` — `All 29 skills` → `All 28 skills`
- `docs/reference/skills.md:3` — two occurrences of `29 skills` → `28 skills`
- `docs/reference/automation-config.md:9` — `19 optional sections` → `18 optional sections`
- `docs/architecture.md:27` — `SKL[29 Skills]` → `SKL[28 Skills]`

Also: `docs/reference/automation-config.md:40` — remove the `Pause Limits | No | /autopilot` row (Q3's scope for Action 2 — "Used By" update), or update the "Used By" column to reflect all 6 skills.

---

## DISAGREEMENT A: How many templates reference `Extra labels`?

**Resolution: AGENT-3 IS CORRECT — only 2 files, not 8.**

Direct grep of all 8 files in `examples/configs/` confirmed:
```
examples/configs/github-nextjs.md:104:### Extra labels (optional)
examples/configs/redmine-oracle-plsql.md:182:### Extra labels (optional)
```
Zero matches in the other 6 files. The spec's claim of "8 config templates" was incorrect.

---

## DISAGREEMENT B: Does `resume-ticket` qualify as a "pause-emitting" skill?

**Resolution: NO — `resume-ticket` is RESUME-ONLY. It reads `status == "paused"` but never writes it.**

`skills/resume-ticket/SKILL.md` Priority 0 (Paused Detection) reads `clarification.question` from state.json, processes the `--clarification` answer, and sets status back to `running`. It contains no code that sets `status = "paused"` or emits `## NEEDS_CLARIFICATION`. `core/agent-states.md:54` explicitly names only 4 orchestrator skills as pause-emitters. The CLAUDE.md memory entry "fix-ticket, fix-bugs, implement-feature, scaffold, autopilot, resume-ticket as the presumed 6" conflates pause-emitters with pause-handlers.

**Corrected list for Action 2 doc fix:** The 4 pause-emitters are fix-ticket, fix-bugs, implement-feature, scaffold. Autopilot enforces Pause Limits (timeout auto-abort). Resume-ticket handles resumption. All 6 are relevant to the Pause Limits section, but for different reasons.

---

## DISAGREEMENT C: Does `Pause Limits` appear at multiple locations in `automation-config.md`?

**Resolution: AGENT-3 IS MORE CORRECT — Pause Limits appears at lines 40 AND 460-477 AND 628.**

Verified locations:
- `docs/reference/automation-config.md:40` — Quick reference table row: `| Pause Limits | No | /autopilot |`
- `docs/reference/automation-config.md:460-477` — Full section body: `### Pause Limits` with description, key table, example block, and link to `core/agent-states.md`
- `docs/reference/automation-config.md:628` — Inside the complete config example comment block: `### Pause Limits (optional, v6.9.0+)` followed by a table with `Pause timeout | 30 days`

**The section body at lines 460-477 does NOT say "/autopilot only".** It says the pipeline "enters the paused state when an agent emits a NEEDS_CLARIFICATION signal" — which is accurate (the 4 orchestrators emit it). The reference to `resume-ticket --clarification` in line 462 is correct. The ONLY inaccuracy is the Quick Reference table at line 40 where `Used By = /autopilot` is listed as the sole consumer.

**Action 2 fix scope:** Line 40 `Used By` column should be updated to list all 6 relevant skills (or a concise form). The section body at lines 460-477 is already accurate. The example block at line 628 needs no change.

---

## DISAGREEMENT D: Does `v6.9.0-doc-count-drift.sh` contain a NEGATIVE assertion that would reject "18 optional"?

**Resolution: AGENT-3 IS CORRECT — lines 55-58 assert the NEGATIVE of "18 optional config sections in total".**

From `tests/scenarios/v6.9.0-doc-count-drift.sh`:
```bash
echo "--- Assertion 5 (AC-064a NEGATIVE): no stale 18 optional ---"
if grep -qF '18 optional config sections in total' "$CLAUDE_MD"; then
  fail "AC-064a: CLAUDE.md still has stale '18 optional config sections in total'"
fi
```

This means: after v7.0.0 changes CLAUDE.md to say `18 optional config sections in total`, Assertion 3 (line 42-46) will FAIL (looking for 19) AND Assertion 5 (line 55-58) will ALSO FAIL (rejecting "18 optional" as "stale").

**Both failures are triggered simultaneously by the same change.** The test was written to enforce the v6.9.0 bump (17→18→19), making 18 the OLD state. Phase 7 executor MUST update this test:
- Change Assertion 3 to check for `18 optional config sections in total`
- Change Assertion 5 to reject `17 optional config sections in total` (not 18)
- Update the enumeration count assertion at line 79 from `[ "$optional_count" -eq 19 ]` to `[ "$optional_count" -eq 18 ]`
- Update the fallback prose assertion at line 84 from `'19 optional config sections in total'` to `'18 optional config sections in total'`
- Update the final PASS message at line 89 from `19 optional` to `18 optional`

---

## Additional Findings (NOT in original questions but discovered during research)

### F1: `docs/reference/automation-config.md` Quick Reference table references `/create-pr`

- **Discovery**: Line 19-20 of `docs/reference/automation-config.md` lists `/create-pr` as a consumer of PR Rules and PR Description Template in the Quick Reference table.
- **Evidence**: `docs/reference/automation-config.md:19`: `| PR Rules | Yes | /publish, /create-pr, publisher |` and line 20: `| PR Description Template | Yes | /publish, /create-pr, publisher |`
- **Implication**: After deleting `/create-pr`, these two rows must be updated to remove the `/create-pr` reference. The spec and prior agents did not flag this location.

### F2: `docs/reference/skills.md` has a cross-reference between `/create-pr` and `/publish`

- **Discovery**: The `/publish` section at `docs/reference/skills.md:363` says `**Related skills:** [/create-pr](#create-pr), [/fix-ticket](#fix-ticket)`. After deleting `/create-pr`, this related-skills link becomes a dead anchor.
- **Evidence**: `docs/reference/skills.md:363`: `**Related skills:** [/create-pr](#create-pr), [/fix-ticket](#fix-ticket)`
- **Implication**: Remove `/create-pr` reference from `/publish`'s Related skills, and remove the entire `/create-pr` section (lines 323-342). Also remove `/create-pr` from the skill index table at line 26.

### F3: `skills/create-backlog/SKILL.md` references `/ceos-agents:init`

- **Discovery**: `skills/create-backlog/SKILL.md:52` contains a block recommendation that references `/ceos-agents:init`.
- **Evidence**: `skills/create-backlog/SKILL.md:52`: `Recommendation: Run /ceos-agents:check-setup for diagnostics, or /ceos-agents:init to configure the {Type} integration.`
- **Implication**: This file was NOT in any prior agent's enumeration. After rename, it needs `/ceos-agents:init` → `/ceos-agents:setup-mcp`.

### F4: `skills/init/SKILL.md` self-references its own deprecated name in user-facing closing text

- **Discovery**: `skills/init/SKILL.md:341` closing message says `Tip: You can re-run /ceos-agents:init --update anytime to update your setup.`
- **Evidence**: `skills/init/SKILL.md:341`
- **Implication**: When this skill is renamed to `setup-mcp`, this self-reference must also update. There are 5+ self-references in this file at lines 202, 215, 225, 263, 341.

### F5: `docs/guides/installation.md` references `/ceos-agents:init` but has NO "Known Limitations" section for builtin collisions

- **Discovery**: `docs/guides/installation.md:92` references `/ceos-agents:init`. The file has no "Known Limitations" or "Caveats" section — Action 6 (doc warning about collisions) must ADD a new section here, not extend an existing one.
- **Evidence**: Read of `docs/guides/installation.md` first 60 lines shows sections: Prerequisites, Gitea Access, Plugin Installation, Project Setup. No limitations/caveats section.
- **Implication**: Action 6 (warnings about short-form collision) requires a NEW section in `installation.md`, not an extension. The executor should also update `installation.md:92` to say `/ceos-agents:setup-mcp` after the rename.

### F6: `core/agent-states.md:54` counts 6 webhook-firing sites but names only 4 orchestrator skills

- **Discovery**: `core/agent-states.md:54` says "6 total firing sites — fix-ticket has 2: triage + fixer; fix-bugs has 2: triage + fixer; implement-feature has 1: fixer; scaffold has 1: fixer." This is internally consistent but does NOT list resume-ticket or autopilot as Pause Limits consumers, which creates a gap in the Action 2 doc fix scope.
- **Evidence**: `core/agent-states.md:54`: exact quote above.
- **Implication**: The `docs/reference/automation-config.md` Quick Reference table row for Pause Limits should read `/fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot, /resume-ticket` or a shorter form like "pipeline skills + /autopilot". The current value `/autopilot` is incomplete.

### F7: `docs/reference/automation-config.md` CLAUDE.md also contains `### Autopilot` section list with `Pause Limits` note

- **Discovery**: `CLAUDE.md` line 160 (`There are 19 optional config sections in total`) is the primary count string, but there are two additional structural items in CLAUDE.md that reference `Extra labels`:
  - `CLAUDE.md:31` — Skills list: `/create-pr`, `/status`, `/init` all appear as plain `/status` and `/init` short forms (not the full `ceos-agents:` prefix). These are the CLAUDE.md canonical skill list entries and must be updated.
  - `CLAUDE.md:149` — `| Extra labels | Labels | (none) |` row in the optional sections table
- **Evidence**: `CLAUDE.md:31`: `**Skills** (orchestration — WHAT to do): /analyze-bug, /fix-ticket, /fix-bugs, /create-pr, ...  /status, ... /init, ...`
- **Implication**: CLAUDE.md:31 contains `/create-pr`, `/status`, `/init` as part of the skills enumeration list. These 3 items must be updated: remove `/create-pr`, rename `/status` to `/pipeline-status`, rename `/init` to `/setup-mcp`. Phase 7 executor must not miss this line.

### F8: `docs/reference/automation-config.md:33` `Extra labels` "Used By" column will be stale

- **Discovery**: `docs/reference/automation-config.md:33`: `| Extra labels | No | /fix-ticket, /fix-bugs, /implement-feature |` — this entire row must be DELETED when `Extra labels` is removed, not just updated.
- **Evidence**: `docs/reference/automation-config.md:33`
- **Implication**: Row deletion, not update. The row disappears entirely.

### F9: `core/snippets/` directory contains 5 snippets — none reference deprecated identifiers

- **Discovery**: Checked all 5 snippet files in `core/snippets/` (`webhook-curl.md`, `issue-id-validation.md`, `metrics-json-schema.md`, `pipeline-completion.md`, `architecture-freshness.md`). None contain references to `Extra labels`, `/create-pr`, `/ceos-agents:status`, or `/ceos-agents:init`.
- **Evidence**: Grep of `core/**/*.md` for all deprecated identifiers returned zero snippet matches.
- **Implication**: `core/snippets/` does NOT need editing. The 2 hits in `core/` are both in top-level files (`mcp-preflight.md`, `config-reader.md`).

### F10: `docs/reference/skills.md` "Skill Index" table references `create-pr`

- **Discovery**: `docs/reference/skills.md:26`: `| Publishing | [/create-pr](#create-pr) | Creates a PR for the current branch |` — this is an anchor link to the section that will be deleted.
- **Evidence**: `docs/reference/skills.md:26`
- **Implication**: The entire "Publishing" category row for `create-pr` must be deleted from the skill index table. The `### /create-pr` section body (lines 323-342) must also be deleted.

### F11: `CHANGELOG.md` references `create-pr` in historical entries — no action needed

- **Discovery**: `CHANGELOG.md:1204` references `create-pr` in a historical entry (`- **create-pr:** added PR Description Template usage...`). Also `README.md:148` has `| /create-pr | Create a PR for the current branch |` in the skill list table.
- **Evidence**: `CHANGELOG.md:1204`, `README.md:148`
- **Implication**: CHANGELOG entries are historical records and should NOT be edited. However, `README.md:148` is an active skill list and must have the `/create-pr` row removed.

### F12: `docs/guides/troubleshooting.md` references both `/ceos-agents:status` and `/ceos-agents:init`

- **Discovery**: `docs/guides/troubleshooting.md:225` references `/ceos-agents:init` (permissions recommendation); `docs/guides/troubleshooting.md:311` references `/ceos-agents:status` (pipeline stage check guidance).
- **Evidence**: Confirmed via grep of `docs/**/*.md`.
- **Implication**: Both references need updating. Neither was in the spec's explicit file list.
