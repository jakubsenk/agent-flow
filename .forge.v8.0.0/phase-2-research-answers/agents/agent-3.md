# Phase 2 Research Answers — Agent 3 (Senior Test Engineer + MCP Specialist)

Specialty: Q7 (MCP tool names + error semantics), Q8 (test scenario classification), Q9 (anchor doc change list + Phase 8 verification commands). Q1–Q6 answered with citations; effort concentrated on specialty areas.

---

## Q1: How many config templates actually contain "Extra labels"?

**Direct answer:** Exactly **2** of the 8 config templates contain `Extra labels`. The spec claim that all 8 templates reference it is wrong.

**Evidence:**
```
examples/configs/github-nextjs.md:104:### Extra labels (optional)
examples/configs/redmine-oracle-plsql.md:182:### Extra labels (optional)
```
grep of all 8 files in `examples/configs/` returns only these 2 hits. The other 6 (`github-python-fastapi.md`, `github-dotnet.md`, `gitea-spring-boot.md`, `jira-react.md`, `youtrack-python.md`, `redmine-rails.md`) contain no `Extra labels` row.

**Implication for v7.0.0:** Action 1 edits only 2 example templates (not 8). Phase 7 executor must not touch the other 6.

---

## Q2: Which exactly 6 skills implement pause-on-NEEDS_CLARIFICATION semantics?

**Direct answer:** The 6 skills that write `status = "paused"` and fire `pipeline-paused` webhook are: **fix-ticket, fix-bugs, implement-feature, scaffold, autopilot (skip logic), resume-ticket (resume logic)**. `analyze-bug` is interactive-only (no state.json pause). `resume-ticket` does NOT pause — it *reads* a paused state and transitions it back to `running`. The CLAUDE.md list "fix-ticket, fix-bugs, implement-feature, scaffold, autopilot, resume-ticket" is accurate only if understood as "6 skills involved in the NEEDS_CLARIFICATION lifecycle", not "6 skills that emit the pause".

**Evidence (dispatch sites that write `.status = "paused"`):**
- `skills/fix-ticket/SKILL.md:226`: `'.status = "paused" | .clarification = {...}'`
- `skills/fix-ticket/SKILL.md:450`: second pause site (after fixer)
- `skills/fix-bugs/SKILL.md:248`: `'.status = "paused"'` (after triage, per bug)
- `skills/fix-bugs/SKILL.md:505`: second pause site (after fixer, per bug)
- `skills/implement-feature/SKILL.md:413`: `'.status = "paused"'` (after fixer)
- `skills/scaffold/SKILL.md:819`: `'.status = "paused"'` (after scaffold-fixer)
- `skills/analyze-bug/SKILL.md:26–30`: interactive-only — "no state.json, no pipeline pause" confirmed by comment text
- `skills/autopilot/SKILL.md:315–364`: pause-*detection* only; transitions to `aborted_by_system` on timeout; does not write `paused`
- `skills/resume-ticket/SKILL.md:17–65`: reads paused state and resumes; writes `running`; does NOT write `paused`

**Implication for v7.0.0:** The `Pause Limits` doc fix (Action 2) should list the 4 emitting skills (fix-ticket, fix-bugs, implement-feature, scaffold) as the "pause-capable" dispatch sites, with autopilot and resume-ticket noted as lifecycle participants. See DISAGREEMENT B below.

---

## Q3: Which 6 skills for Pause Limits, and where in automation-config.md to fix?

**Direct answer:** `docs/reference/automation-config.md:40` has `| Pause Limits | No | /autopilot |`. This must become a list of all 6+ skills. There are **4 separate `Pause Limits` occurrences** (lines 40, 460, 470, 628). The section body at line 462 already says "A pipeline enters the paused state when an agent emits a NEEDS_CLARIFICATION signal" — this is correct, but line 40's "Used By" column is "/autopilot only" which misleads.

**Evidence:**
```
docs/reference/automation-config.md:40:  | Pause Limits | No | /autopilot |
docs/reference/automation-config.md:460:  ### Pause Limits
docs/reference/automation-config.md:470:  ### Pause Limits   (inside the Example block)
docs/reference/automation-config.md:628:  ### Pause Limits (optional, v6.9.0+)   (inside HTML comment — template example)
```
Lines 460–477: section body describes the pause mechanic correctly (not "/autopilot only"). Line 628 is inside an HTML comment.

**Implication for v7.0.0:** Only line 40's "Used By" column needs changing from `/autopilot` to `/fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot`. Lines 460+ are accurate. Line 628 is in a comment — update it too for consistency.

---

## Q4: Complete `ceos-agents:status` / `ceos-agents:init` / `create-pr` reference inventory (active, non-historical files)

**Direct answer:** The live (non-plans/, non-CHANGELOG) files referencing these identifiers:

### `/ceos-agents:init` references (active)
| File | Line | Text |
|------|------|------|
| `core/config-reader.md` | 57 | `run /ceos-agents:init.` |
| `core/mcp-preflight.md` | 36 | `or /ceos-agents:init to configure the {tracker_type}...` |
| `skills/status/SKILL.md` | 60 | `run /ceos-agents:init` |
| `skills/status/SKILL.md` | 82 | `run /ceos-agents:init` |
| `skills/init/SKILL.md` | 202 | `re-run /ceos-agents:init` |
| `skills/init/SKILL.md` | 215 | `re-run /ceos-agents:init.` |
| `skills/init/SKILL.md` | 225 | `Install it and re-run /ceos-agents:init.` |
| `skills/init/SKILL.md` | 263 | `Re-run /ceos-agents:init to fix the path.` |
| `skills/init/SKILL.md` | 341 | `re-run /ceos-agents:init --update` |
| `skills/check-setup/SKILL.md` | 68 | `Run /ceos-agents:init to create one.` |
| `skills/check-setup/SKILL.md` | 76 | `Run /ceos-agents:init to set it up.` |
| `docs/reference/skills.md` | 398–427 | Section heading + 5 example invocations |
| `docs/getting-started.md` | 115, 125 | `ceos-agents:init` (2 occurrences) |
| `docs/guides/mcp-configuration.md` | 5 | `/ceos-agents:init` |
| `docs/guides/troubleshooting.md` | 225 | `/ceos-agents:init` |
| `README.md` | 164 | `\| /init \|` (short form) |
| `workflow-router/SKILL.md` | 20 | `ceos-agents:init` (intent table) |
| `CLAUDE.md` | implicit — skills/ lists 29 skills including `init` |

### `/ceos-agents:status` references (active)
| File | Line | Text |
|------|------|------|
| `skills/workflow-router/SKILL.md` | 18 | `ceos-agents:status` (intent table) |
| `docs/reference/skills.md` | 516, 524 | `/ceos-agents:status` (examples) |
| `docs/guides/troubleshooting.md` | 311 | `/ceos-agents:status` |
| `README.md` | 153 | `\| /status \|` (short form) |

### `/create-pr` references (active)
| File | Line | Text |
|------|------|------|
| `skills/workflow-router/SKILL.md` | 15 | `ceos-agents:create-pr` (intent table) |
| `skills/workflow-router/SKILL.md` | 55 | `create-pr` (destructive list) |
| `skills/create-pr/SKILL.md` | 2 | `name: create-pr` (will be deleted) |
| `docs/reference/skills.md` | 26 | `[/create-pr](#create-pr)` |
| `docs/reference/skills.md` | 323 | `### /create-pr` |
| `docs/reference/skills.md` | 330, 338 | `/ceos-agents:create-pr` (examples) |
| `docs/reference/skills.md` | 363 | `**Related skills:** [/create-pr]` |
| `README.md` | 148 | `\| /create-pr \|` |
| `agents/publisher.md` | (references `create-pr` via `create_pull_request` — no literal "create-pr") |
| `tests/scenarios/no-mcp-jargon-errors.sh` | 15 | `"skills/create-pr/SKILL.md"` |
| `tests/scenarios/skills-directory-structure.sh` | 36 | `create-pr` (EXPECTED_SKILLS array) |
| `tests/scenarios/skills-frontmatter-check.sh` | 51 | `create-pr` (PIPELINE_SKILLS array) |

**Implication:** core/mcp-preflight.md and core/config-reader.md are NOT in the spec's enumeration for Actions 3/4 — these MUST be added to the Phase 7 change list.

---

## Q5: workflow-router intent table rows for deprecated names

**Direct answer:** All three deprecated identifiers appear as explicit rows in the intent table AND in Step 4 prose.

**Evidence (verbatim from `skills/workflow-router/SKILL.md`):**

Intent table rows:
```
| Create a pull request | `ceos-agents:create-pr` | None | Yes |
| Show status/overview | `ceos-agents:status` | None | No |
| Configure MCP/tokens/permissions | `ceos-agents:init` | Optional: --update | Yes |
```

Step 4 prose (line 55):
```
4. **If the operation IS destructive** (fix-ticket, fix-bugs, create-pr, publish, ...)
```

Step 3 prose (line 54):
```
3. **If the operation is NOT destructive** (analyze-bug, check-setup, version-check, status, ...)
```

**Implication:** After v7.0.0: (a) delete `create-pr` row from intent table; remove `create-pr` from Step 4 destructive list; (b) rename `status` row to `pipeline-status`; rename in Step 3 non-destructive list; (c) rename `init` row to `setup-mcp`; remove from Step 4 destructive list (if `setup-mcp` is non-destructive — but current `init` is marked "Yes"/"Confirm", which should be revisited).

---

## Q6: publish/SKILL.md current Step 1 and issue_id extraction

**Direct answer:** `skills/publish/SKILL.md` Step 1 currently says "Determine the current branch and issue ID" with no explicit extraction logic — it relies on the running context. fix-ticket, fix-bugs, implement-feature all use the issue ID passed as `$ARGUMENTS`, so the branch already carries the issue ID by naming convention.

**Evidence:**
- `skills/publish/SKILL.md:21`: `1. Determine the current branch and issue ID`
- fix-ticket passes `$ARGUMENTS` as issue ID; the publisher agent reads branch naming from config to construct the branch name
- No regex extraction exists in publish — the issue ID flows down from the invoking skill

**Implication:** Auto-detect in `/publish` must parse the branch name against `Branch naming` pattern from config, extract the issue ID substring, then try `getIssue(issue_id)`. The exact extraction pattern depends on each project's `Branch naming` config value — see Q7 for the MCP call.

---

## Q7: MCP Tool Names — Per-Tracker Issue Fetch + Error Semantics (R3)

**Direct answer:** The ceos-agents codebase does NOT document per-tracker specific tool names for single-issue fetch (e.g., `mcp__youtrack__get_issue` vs `mcp__youtrack__getIssue`). The system uses the tool prefix and lets the LLM discover the exact tool name at runtime. However, the error *classification* is fully documented in `core/mcp-detection.md`.

### Tool Prefix Table (from `core/mcp-detection.md:28` + `docs/reference/trackers.md:77`)

| Tracker | Package | Tool prefix (pattern) | Single-issue fetch (inferred) |
|---------|---------|----------------------|-------------------------------|
| youtrack | `@vitalyostanin/youtrack-mcp` | `mcp__youtrack__*` | Tool name NOT explicitly documented — LLM discovers by prefix scan |
| github | `@modelcontextprotocol/server-github` | `mcp__github__*` | Not documented explicitly |
| jira | `@modelcontextprotocol/server-atlassian` | `mcp__jira__*` OR `mcp__atlassian__*` | Not documented explicitly |
| linear | `@modelcontextprotocol/server-linear` | `mcp__linear__*` | Not documented explicitly |
| gitea | `forgejo-mcp` | `mcp__gitea__*` OR `mcp__forgejo__*` | Not documented explicitly |
| redmine | `mcp-server-redmine` | `mcp__redmine__*` | Not documented explicitly |

**Key finding:** The codebase uses the pattern "scan available tools for prefix, then use the discovered tool" — it does NOT hardcode individual tool names like `get_issue` or `getIssue`. Evidence:

- `core/mcp-detection.md:36`: "Scan available tools for at least one tool matching the prefix."
- `core/mcp-detection.md:39`: "attempt to list 1 issue from the declared project (or list projects if no project specified)" — this is the connectivity check, not a specific `get_issue` call
- `core/external-input-sanitizer.md:22`: uses generic reference: "get_issue, get_comments, list_comments, etc."
- `core/tracker-subtask-creator.md:76`: uses `MCP get_issue({issue_id})` as pseudocode — no tracker-specific tool name
- `core/status-verification.md:17`: "call the tracker's get-issue MCP tool" — no specific tool name per tracker

**Design intent confirmed:** The agents read the tracker type from config, identify the prefix, then invoke whichever specific tools they find. This makes the system resilient to MCP package version differences.

### Error Shape for 404 vs 5xx vs Timeout (from `core/mcp-detection.md:58–87`)

The classification is string-pattern-based on the returned error message, not on HTTP status codes:

| error_type | Trigger patterns (priority order) |
|------------|----------------------------------|
| `"tls"` | UNABLE_TO_VERIFY_LEAF_SIGNATURE, CERT_UNTRUSTED, SELF_SIGNED_CERT, certificate verify failed, ERR_TLS_, etc. |
| `"auth"` | 401, 403, unauthorized, forbidden, invalid token, authentication |
| `"not_found"` | **404**, not_found, not found, ENOTFOUND, EAI_AGAIN |
| `"timeout"` | timeout, ETIMEDOUT, **ECONNREFUSED**, ECONNRESET |
| `"unknown"` | Everything else |

**Critical note for `/publish` auto-detect:** The 3-way fork described in the spec requires:
1. Issue found → update tracker + create PR
2. Issue NOT found (404) → `error_type == "not_found"` → PR only, no tracker update
3. Tracker unreachable (5xx/timeout) → `error_type == "timeout"` or `"auth"` → fail with guidance

However, the codebase does NOT currently document a single-issue-fetch tool call. The `/publish` auto-detect will need to use the discovered `get_issue`-equivalent tool (whatever the MCP package exposes for the detected prefix) and handle errors using the classification from `core/mcp-detection.md`. **There is no per-tracker explicit tool name documented — the LLM must discover it at runtime.**

**Implication for Action 5:** The auto-detect prose in `/publish` should say: "Using the MCP tool prefix for {tracker_type}, locate the single-issue fetch tool (typically a `get_issue` or `getIssue` variant) and call it with `{issue_id}`. Classify the error per `core/mcp-detection.md` Classification Reference. If `error_type == not_found` → PR-only mode. If `error_type` is `timeout`, `auth`, or `tls` → fail with guidance."

---

## Q8: Test Scenario Classification (R8)

### Test Discovery Method

`tests/harness/run-tests.sh` uses **auto-discovery** (lines 35–55): `for scenario in "$SCENARIOS_DIR"/*.sh` — it globs all `.sh` files. No explicit list. Exit code 77 = SKIP. No other skip mechanism.

### Scenarios That Will HARD-FAIL After v7.0.0

#### 1. `tests/scenarios/regression-skill-count-29.sh`
**Classification: UPDATE**
- `line 14`: `if [ "$SKILL_COUNT" -ne 29 ]` — will fail when count drops to 28 after deleting `create-pr`
- Change: update assertion to `-ne 28`, update message string "expected exactly 29" → "expected exactly 28"

#### 2. `tests/scenarios/ac-v68-doc-skill-count-29.sh`
**Classification: UPDATE**
- `line 15`: `grep -nE '29 skills' CLAUDE.md` — will fail after count changes to 28
- `line 20`: `grep -nE '28 skills' CLAUDE.md` — negative assertion currently checking old count; after v7.0.0 this becomes a POSITIVE assertion that would accept the new value but the check at line 15 blocks
- Change: flip: positive check for "28 skills", negative check for "29 skills"; also update `docs/reference/skills.md` check

#### 3. `tests/scenarios/v6.9.0-doc-count-drift.sh`
**Classification: UPDATE — with DISAGREEMENT D resolution (see below)**
- `line 41–46` (Assertion 3): `grep -qF '19 optional config sections in total'` — will HARD-FAIL when CLAUDE.md is updated to "18 optional"
- `line 55–58` (Assertion 5 NEGATIVE): `grep -qF '18 optional config sections in total'` followed by `fail` — THIS IS THE NEGATIVE ASSERTION. Currently it FAILs if "18 optional" is found in CLAUDE.md. After v7.0.0, CLAUDE.md will say "18 optional" → this assertion fires → test FAILS.
- `line 72`: `[ "$skills_count" -eq 29 ]` — will fail when skills dir count drops to 28
- Change: Update Assertion 3 to check for "18 optional"; flip Assertion 5 to check for "19 optional" as the stale value; update skills count check from 29 to 28; update the optional section table row count check from 19 to 18

#### 4. `tests/scenarios/skills-directory-structure.sh`
**Classification: UPDATE**
- `line 25–59`: EXPECTED_SKILLS array hardcodes all 29 skill names including `create-pr`, `status`, `init`
- `line 67–69`: count check `expected_count=${#EXPECTED_SKILLS[@]}` (29) will fail
- `line 71–75`: "skills/ directory count: expected 29, found 28" will fail
- Change: Remove `create-pr` from EXPECTED_SKILLS; rename `status` → `pipeline-status`; rename `init` → `setup-mcp`; expected_count will become 28 automatically

#### 5. `tests/scenarios/skills-frontmatter-check.sh`
**Classification: UPDATE**
- `line 51`: PIPELINE_SKILLS array includes `create-pr`; if the file is deleted, `[ ! -f "$f" ]` fires → `fail`
- `line 82–98`: READONLY_SKILLS array includes `status` and `init`; if directories are renamed, `[ ! -f "$f" ]` fires → `fail`
- `line 43`: "FC-5: 12 pipeline skills have disable-model-invocation: true" — after deleting `create-pr`, only 11 remain
- `line 82`: "FC-6: 13 non-pipeline skills" — after renaming status/init, same count if new names are listed; but the array must be updated with new names
- Change: Remove `create-pr` from PIPELINE_SKILLS; update count comments ("11 pipeline skills"); rename `status` → `pipeline-status` and `init` → `setup-mcp` in READONLY_SKILLS

#### 6. `tests/scenarios/no-mcp-jargon-errors.sh`
**Classification: UPDATE (partial — create-pr deletion)**
- `line 15`: STANDARD_ERROR_FILES array includes `"skills/create-pr/SKILL.md"` — if file is deleted, `[ ! -f "$f" ]` → `fail`
- Change: Remove the `create-pr` entry from STANDARD_ERROR_FILES

#### 7. `tests/scenarios/config-reader-sections.sh`
**Classification: UPDATE**
- `line 25`: OPTIONAL_SECTIONS array includes `"Extra labels"` — after deletion, both the CLAUDE.md check (line 36) and config-reader.md check (line 47) will fail if the section no longer exists in either file
- Change: Remove `"Extra labels"` from OPTIONAL_SECTIONS array

#### 8. `tests/scenarios/v6.9.0-bc-no-renamed-section.sh`
**Classification: UPDATE**
- `line 25`: OPTIONAL_SECTIONS array includes `"Extra labels"` — this test enumerates all 19 optional sections by name; after deletion it becomes a test of 18 sections
- `line 47`: `[ "${#OPTIONAL_SECTIONS[@]}" -eq 19 ]` — mutation guard fires when array shrinks to 18
- Change: Remove `"Extra labels"` from the array; update mutation guard from 19 to 18; update success message

#### 9. `tests/scenarios/ac-v68-doc-optional-sections-18.sh`
**Classification: PASS (no change needed) — false-positive risk is ACCEPTABLE**
- `line 15`: `grep -nE '(18|19) optional' CLAUDE.md` — will PASS when CLAUDE.md is updated to "18 optional" (matches the `18` branch)
- `line 20`: `grep -nE '17 optional' CLAUDE.md` — negative; still passes
- This test will silently pass, which is the correct behavior — it was written to accept 18 or 19. No change needed.

#### 10. `tests/scenarios/xref-command-count.sh`
**Classification: UPDATE**
- Uses dynamic filesystem count vs CLAUDE.md claim — will auto-detect the new counts IF CLAUDE.md is updated to "28 skills". No hardcoded numbers. This test will PASS automatically after both CLAUDE.md and filesystem are updated consistently.

### Scenarios That Will Continue PASSING

- `tests/scenarios/v6.9.0-cross-file-invariants.sh` — tests Cross-File Invariants section existence + content; unaffected by v7.0.0 changes
- All `v6.9.0-*` and `v6.10.0-*` scenarios focused on specific features (not counts/names)
- `tests/scenarios/pipeline-consistency.sh` — checks `git add .` patterns; no skill name references

---

## Q9: Anchor Doc Change List + Cross-Metadata Audit (R6)

### Complete Change List (file:line:current → new)

| # | File | Line | Current text | New text |
|---|------|------|--------------|----------|
| 1 | `CLAUDE.md` | 18 | `29 skills (slash commands, including workflow-router)` | `28 skills (slash commands, including workflow-router)` |
| 2 | `CLAUDE.md` | 149 | `\| Extra labels \| Labels \| (none) \|` | DELETE this row |
| 3 | `CLAUDE.md` | 160 | `There are 19 optional config sections in total.` | `There are 18 optional config sections in total.` |
| 4 | `README.md` | 148 | `\| \`/create-pr\` \| Create a PR for the current branch \|` | DELETE this row |
| 5 | `README.md` | 153 | `\| \`/status\` \| Overview of in-progress issues...\|` | `\| \`/pipeline-status\` \| Overview of in-progress issues...\|` |
| 6 | `README.md` | 164 | `\| \`/init\` \| Developer environment setup...\|` | `\| \`/setup-mcp\` \| Developer environment setup...\|` |
| 7 | `README.md` | 221 | `**19 optional sections** cover...` | `**18 optional sections** cover...` (and remove "labels" from the list) |
| 8 | `README.md` | 262 | `All 29 skills — syntax, flags, examples` | `All 28 skills — syntax, flags, examples` |
| 9 | `docs/reference/automation-config.md` | 9 | `5 required sections and 19 optional sections` | `5 required sections and 18 optional sections` |
| 10 | `docs/reference/automation-config.md` | 33 | `\| Extra labels \| No \| /fix-ticket...\|` | DELETE this row |
| 11 | `docs/reference/automation-config.md` | 40 | `\| Pause Limits \| No \| /autopilot \|` | `\| Pause Limits \| No \| /fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot \|` |
| 12 | `docs/reference/automation-config.md` | 332–338 | `### Extra labels` section + body | DELETE entire section |
| 13 | `docs/reference/skills.md` | 3 | `all 29 skills in the ceos-agents plugin. All 29 ceos-agents skills` | `all 28 skills in the ceos-agents plugin. All 28 ceos-agents skills` |
| 14 | `docs/reference/skills.md` | 26 | `\| Publishing \| [/create-pr](#create-pr) \| Creates a PR for the current branch \|` | DELETE this row |
| 15 | `docs/reference/skills.md` | 323–363 | `### /create-pr` section + body | DELETE entire section |
| 16 | `docs/reference/skills.md` | 398–427 | `/ceos-agents:init` section | Rename to `/ceos-agents:setup-mcp` (section heading + all examples) |
| 17 | `docs/reference/skills.md` | 516, 524 | `/ceos-agents:status` (examples) | `/ceos-agents:pipeline-status` |
| 18 | `docs/getting-started.md` | 219 | `Explore all 29 skills` | `Explore all 28 skills` |
| 19 | `docs/architecture.md` | (no count strings found — no change needed) | — | — |

### plugin.json / marketplace.json

Both files contain `"license": "MIT"` and `"version": "6.10.0"` — no count strings, no skill name references. No changes needed for Actions 1–5 (version bump is done separately per project convention).

### examples/configs/ — skill name references

grep of all 8 config templates for `ceos-agents:status`, `ceos-agents:init`, `create-pr` returned **0 hits**. No changes needed in examples/configs/ for Actions 3/4/5.

`Extra labels` changes needed only in:
- `examples/configs/github-nextjs.md:104` — DELETE `### Extra labels (optional)` section
- `examples/configs/redmine-oracle-plsql.md:182` — DELETE `### Extra labels (optional)` section

---

## DISAGREEMENT A: 2 vs 8 templates with "Extra labels"

**RESOLVED: 2 templates.** Live grep of all 8 files in `examples/configs/` found matches in exactly 2 files:
- `examples/configs/github-nextjs.md:104`
- `examples/configs/redmine-oracle-plsql.md:182`

Agent-1's claim ("all 8 templates") is incorrect. The spec is wrong here. Phase 7 must only edit 2 templates.

---

## DISAGREEMENT B: Does `resume-ticket` qualify as one of the 6 "pause-implementing" skills?

**RESOLVED: No, with nuance.**

`skills/resume-ticket/SKILL.md` does NOT write `status = "paused"` anywhere. It READS a paused state (`status == "paused"`) at Priority 0, injects the clarification answer, then writes `status = "running"`. It also does NOT increment `clarifications_consumed` — the code explicitly says "DO NOT increment" (line 32). It fires `pipeline-resumed` (not `pipeline-paused`) webhook.

Therefore: `resume-ticket` is a **lifecycle participant** (resume side) but is NOT a "pause-emitting" skill. The 4 skills that emit `pipeline-paused` are: fix-ticket, fix-bugs, implement-feature, scaffold. Autopilot enforces pause timeout (auto-abort) but does not emit pause itself.

**For the `Pause Limits` doc fix (Action 2):** The "applies to" list should be "fix-ticket, fix-bugs, implement-feature, scaffold" for the pause emission, plus "autopilot" for the timeout enforcement. resume-ticket should be noted as the resume mechanism, not a pause consumer.

---

## DISAGREEMENT C: Pause Limits at lines 40, 460, 470, AND 628 — which need fixing?

**RESOLVED:**

- `line 40`: Quick reference table — "Used By" column says `/autopilot` only → **MUST FIX** to add all 4+ pipeline skills
- `line 460`: Section heading `### Pause Limits` — this is the section definition, correctly describes the pause mechanic (not "/autopilot only"). The section body at 462 says "A pipeline enters the paused state when an agent emits a NEEDS_CLARIFICATION signal" — this is accurate and does NOT restrict to autopilot. **No fix needed in body text.**
- `line 470`: Inside an Example code block (`### Pause Limits` as a markdown heading within a code fence) — this is just showing the section name as it appears in user's config. **No change needed.**
- `line 628`: Inside an HTML comment (`<!-- ### Autopilot ... -->`). This shows `### Pause Limits (optional, v6.9.0+)` as a commented example. **Update for consistency** — but this is low priority.

**Net: 1 mandatory fix (line 40), 1 optional for consistency (line 628).**

---

## DISAGREEMENT D: `v6.9.0-doc-count-drift.sh` negative assertion at lines 56–57

**RESOLVED: Agent-3's concern is confirmed and critical.**

Reading `tests/scenarios/v6.9.0-doc-count-drift.sh:55–58`:

```bash
echo "--- Assertion 5 (AC-064a NEGATIVE): no stale 18 optional ---"
if grep -qF '18 optional config sections in total' "$CLAUDE_MD"; then
  fail "AC-064a: CLAUDE.md still has stale '18 optional config sections in total'"
fi
```

This is a **hard negative assertion**: if CLAUDE.md contains "18 optional config sections in total", the test FAILS. After v7.0.0, CLAUDE.md will be updated from 19 → 18, so this assertion will FIRE and the test will HARD-FAIL.

**Additionally:** line 72 asserts `skills_count -eq 29` — will also fail when count drops to 28.

**Resolution for Phase 7:** This test needs a comprehensive UPDATE:
1. Assertion 3 (line 41–46): change from checking "19 optional" → "18 optional"
2. Assertion 5 (lines 55–58): flip the logic — now check that CLAUDE.md does NOT have "19 optional config sections in total" (the OLD stale value)
3. Line 72: change skills count check from 29 → 28
4. Line 79: change optional table row count from 19 → 18
5. Line 89: update the PASS message

---

## Phase 8 Verification Commands

Copy-paste-ready bash commands for each cross-file invariant and renamed identifier sanity check.

### Invariant 1: License SPDX Consistency

```bash
# Verify all three files contain exactly "MIT" (case-sensitive SPDX form)
grep -c '"MIT"' .claude-plugin/plugin.json .claude-plugin/marketplace.json
head -1 LICENSE | grep -qF 'MIT License' && echo "LICENSE: MIT OK" || echo "LICENSE: MIT FAIL"
# Expected: plugin.json: 1, marketplace.json: 1, LICENSE first line: "MIT License"
```

### Invariant 2: Maintainer Email Consistency

```bash
# All three files must reference filip.sabacky@ceosdata.com
grep -c 'filip.sabacky@ceosdata.com' SECURITY.md CODE_OF_CONDUCT.md CONTRIBUTING.md
# Expected: SECURITY.md: 1, CODE_OF_CONDUCT.md: 1, CONTRIBUTING.md: 2 (link + text)
```

### Invariant 3: Issue/PR Template Parity

```bash
# Issue templates: gitea vs github must be byte-identical
diff -q .gitea/issue_template/bug_report.md .github/ISSUE_TEMPLATE/bug_report.md \
  && echo "bug_report: IDENTICAL" || echo "bug_report: DIFFER"
diff -q .gitea/issue_template/feature_request.md .github/ISSUE_TEMPLATE/feature_request.md \
  && echo "feature_request: IDENTICAL" || echo "feature_request: DIFFER"
# PR templates:
diff -q .gitea/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md \
  && echo "pull_request_template: IDENTICAL" || echo "pull_request_template: DIFFER"
```

### Post-v7.0.0 Renamed Identifier Sanity Checks

```bash
# Verify create-pr skill directory is GONE
[ ! -d skills/create-pr ] && echo "create-pr: DELETED OK" || echo "create-pr: STILL EXISTS (FAIL)"

# Verify status skill directory is RENAMED
[ ! -d skills/status ] && echo "skills/status: GONE OK" || echo "skills/status: STILL EXISTS (FAIL)"
[ -d skills/pipeline-status ] && echo "skills/pipeline-status: EXISTS OK" || echo "skills/pipeline-status: MISSING (FAIL)"

# Verify init skill directory is RENAMED
[ ! -d skills/init ] && echo "skills/init: GONE OK" || echo "skills/init: STILL EXISTS (FAIL)"
[ -d skills/setup-mcp ] && echo "skills/setup-mcp: EXISTS OK" || echo "skills/setup-mcp: MISSING (FAIL)"

# Verify skill count is now 28
SKILL_COUNT=$(find skills -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
[ "$SKILL_COUNT" -eq 28 ] && echo "skill count: 28 OK" || echo "skill count: $SKILL_COUNT (expected 28, FAIL)"

# Verify CLAUDE.md updated counts
grep -qF '28 skills' CLAUDE.md && echo "CLAUDE.md 28 skills: OK" || echo "CLAUDE.md 28 skills: FAIL"
grep -qF '18 optional config sections in total' CLAUDE.md && echo "CLAUDE.md 18 optional: OK" || echo "CLAUDE.md 18 optional: FAIL"
grep -qF '19 optional config sections in total' CLAUDE.md && echo "CLAUDE.md stale 19: FAIL" || echo "CLAUDE.md stale 19: absent OK"

# Verify Extra labels removed from CLAUDE.md
grep -qF 'Extra labels' CLAUDE.md && echo "Extra labels still in CLAUDE.md: FAIL" || echo "Extra labels removed: OK"

# Verify no stale references to old skill names in active files (exclude plans/ and CHANGELOG)
grep -rn 'ceos-agents:status\b' docs/reference/ docs/guides/ core/ skills/ README.md CLAUDE.md \
  | grep -v 'pipeline-status' \
  && echo "Stale ceos-agents:status refs FOUND (FAIL)" || echo "No stale ceos-agents:status refs: OK"

grep -rn 'ceos-agents:init\b' docs/reference/ docs/guides/ core/ skills/ README.md CLAUDE.md \
  | grep -v 'setup-mcp' \
  && echo "Stale ceos-agents:init refs FOUND (FAIL)" || echo "No stale ceos-agents:init refs: OK"

# Verify Pause Limits quick-reference table updated
grep -A1 'Pause Limits' docs/reference/automation-config.md | grep -q 'fix-ticket' \
  && echo "Pause Limits Used-By updated: OK" || echo "Pause Limits Used-By still /autopilot only: FAIL"

# Verify docs/reference/skills.md updated
grep -qE 'all 28 skills' docs/reference/skills.md && echo "skills.md 28: OK" || echo "skills.md 28: FAIL"

# Verify README.md updated
grep -qF '**18 optional sections**' README.md && echo "README 18 optional: OK" || echo "README 18 optional: FAIL"
grep -qF 'All 28 skills' README.md && echo "README 28 skills: OK" || echo "README 28 skills: FAIL"
```

---

## Summary Table: Test Scenario Classification

| Scenario file | Status | Why | Change summary |
|--------------|--------|-----|----------------|
| `regression-skill-count-29.sh` | UPDATE | line 14: `-ne 29` → `-ne 28` | Count 29→28 |
| `ac-v68-doc-skill-count-29.sh` | UPDATE | lines 15+20: positive/negative flip for 28/29 | Flip assertions |
| `v6.9.0-doc-count-drift.sh` | UPDATE | lines 41–46 (19→18), 55–58 (flip), 72 (29→28), 79 (19→18) | Multi-location update |
| `skills-directory-structure.sh` | UPDATE | lines 36,29–59: EXPECTED_SKILLS array | Remove create-pr, rename status/init |
| `skills-frontmatter-check.sh` | UPDATE | lines 51,82–98: PIPELINE/READONLY arrays; FC-5 count 12→11 | Remove create-pr, rename |
| `no-mcp-jargon-errors.sh` | UPDATE | line 15: remove `create-pr` from STANDARD_ERROR_FILES | Remove create-pr entry |
| `config-reader-sections.sh` | UPDATE | line 25: remove `"Extra labels"` from array | Remove one entry |
| `v6.9.0-bc-no-renamed-section.sh` | UPDATE | lines 25,47: remove Extra labels; mutation guard 19→18 | Remove Extra labels, update count |
| `ac-v68-doc-optional-sections-18.sh` | PASS (no change) | `(18\|19) optional` regex will match "18 optional" correctly | No action |
| `xref-command-count.sh` | PASS (auto-update) | Dynamic filesystem count; will self-correct if CLAUDE.md is updated | No action if CLAUDE.md updated |
| `v6.9.0-cross-file-invariants.sh` | PASS (no change) | Tests invariant structure, not counts | No action |
