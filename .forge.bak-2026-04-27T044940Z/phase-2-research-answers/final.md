# Phase 2 Final: Research Answers for v7.0.0 Cleanup

## Scoring

| Agent | Citation density | Coverage Q1-Q9+DISAGR | Factual consistency | New findings | Total |
|-------|-----------------|----------------------|---------------------|--------------|-------|
| Agent 1 | 5 (87 cites, file:line throughout) | 4 (missed README:221, got architecture.md) | 4 (minor DISAGREEMENT B nuance) | 2 (DISAGREEMENT D) | 15/20 |
| Agent 2 | 4 (good breadth, some line numbers imprecise) | 5 (found README:221, F1-F12 additional findings) | 5 (consistent) | 5 (12 new findings) | 19/20 |
| Agent 3 | 4 (solid, specialty MCP/tests strong) | 4 (missed README:221, v6.9.0-arch test) | 5 (consistent) | 3 (Phase 8 verification commands) | 16/20 |

**Base: Agent 2 (19/20)** — strongest breadth, found additional findings F1-F12 that spec missed.

**Merged from Agent 1:** DISAGREEMENT D resolution (exact line-by-line diff for v6.9.0-doc-count-drift.sh), Assertion 5 pass message at line 89. Agent 1's DISAGREEMENT D included line 89 update which Agent 2's resolution missed.

**Merged from Agent 3:** Phase 8 verification commands (bash one-liners), v6.9.0-arch-freshness-refresh-on-release.sh HARD-FAIL identification (another test that asserts `SKL[29 Skills]` — not in Agent 2's list), `ac-v68-doc-optional-sections-18.sh` classification (Agent 3 says PASS/no-change; Agent 2 says update/tighten — Agent 3 is correct per test logic: the `(18|19)` regex correctly accepts 18).

---

## Q1: How many config templates contain "Extra labels"?

**Direct Answer:** Exactly **2 of 8** templates contain `Extra labels`.

**Evidence (live grep confirmed):**
- `examples/configs/github-nextjs.md:104` — `### Extra labels (optional)`
- `examples/configs/redmine-oracle-plsql.md:182` — `### Extra labels (optional)`

Zero matches in: `github-python-fastapi.md`, `github-dotnet.md`, `gitea-spring-boot.md`, `jira-react.md`, `youtrack-python.md`, `redmine-rails.md`.

**Implication:** Action 1 edits only 2 config templates. The spec claim "8 config templates" was incorrect.

---

## Q2: Complete `Extra labels` reference inventory (non-.forge, non-bak)

**Direct Answer:** 17 active locations across core, skills, agents, docs, examples, and tests.

| File | Line(s) | Type |
|------|---------|------|
| `core/config-reader.md` | 31 | Parse rule `### Extra labels` → `pr_rules.extra_labels` |
| `agents/publisher.md` | 69 | "If Extra labels section exists, add those too." |
| `skills/fix-ticket/SKILL.md` | 47, 638 | Config read + publisher context string |
| `skills/fix-bugs/SKILL.md` | 42, 783 | Config read + publisher context string |
| `skills/implement-feature/SKILL.md` | 35, 599 | Config read + publisher context |
| `skills/check-setup/SKILL.md` | 56 | Optional section enumeration list |
| `skills/migrate-config/SKILL.md` | 41 | Migration loop enumeration |
| `skills/onboard/SKILL.md` | 175, 204 | Interactive menu item [12] + config summary |
| `docs/reference/automation-config.md` | 33, 332–339 | Quick reference table row + full section body |
| `CLAUDE.md` | 149, 160 | Optional sections table row + count string |
| `examples/configs/github-nextjs.md` | 104 | Section in config template |
| `examples/configs/redmine-oracle-plsql.md` | 182 | Section in config template |
| `tests/scenarios/config-reader-sections.sh` | 25 | OPTIONAL_SECTIONS array entry |
| `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` | 25, 47 | Array entry + mutation guard count |

**Unlisted consumers confirmed (spec missed these):** `skills/check-setup/SKILL.md`, `skills/migrate-config/SKILL.md`, `skills/onboard/SKILL.md`.

---

## Q3: Which skills implement pause-on-NEEDS_CLARIFICATION semantics?

**Direct Answer:** The 4 skills that **write** `status = "paused"` are: `fix-ticket`, `fix-bugs`, `implement-feature`, `scaffold`. `autopilot` enforces pause timeout (auto-abort) and detects paused state. `resume-ticket` reads and clears paused state. `analyze-bug` is interactive-only — no state.json, no pipeline pause.

**Evidence:**
- `skills/fix-ticket/SKILL.md:226,450` — `'.status = "paused"'` (2 sites: triage + fixer)
- `skills/fix-bugs/SKILL.md:248,505` — `'.status = "paused"'` (2 sites: triage + fixer)
- `skills/implement-feature/SKILL.md:413` — `'.status = "paused"'`
- `skills/scaffold/SKILL.md:819` — `'.status = "paused"'`
- `skills/analyze-bug/SKILL.md:26–30` — "interactive surface — no state.json, no pipeline pause"
- `skills/autopilot/SKILL.md:315,400` — pause detection + outcome classification
- `skills/resume-ticket/SKILL.md:15–33` — reads `paused`, writes `running`, fires `pipeline-resumed`
- `core/agent-states.md:54` — "The four orchestrator skills (fix-ticket, fix-bugs, implement-feature, scaffold) inline this snippet at every NEEDS_CLARIFICATION detection site (6 total firing sites)"
- `docs/reference/automation-config.md:40` — `| Pause Limits | No | /autopilot |` (THE BUG — only autopilot listed)

**For the doc fix (Action 2):** The "Used By" column at line 40 must list all 6 lifecycle participants. The section body at lines 460–477 is already accurate (does not restrict to autopilot). Line 628 is inside an HTML comment — optional consistency update only.

---

## Q4: Complete `/ceos-agents:status`, `/ceos-agents:init`, and `/create-pr` reference inventory

### `/ceos-agents:init` references (active non-forge files)

| File | Line(s) |
|------|---------|
| `core/config-reader.md` | 57 |
| `core/mcp-preflight.md` | 36 |
| `skills/check-setup/SKILL.md` | 68, 76 |
| `skills/status/SKILL.md` | 60, 82 |
| `skills/onboard/SKILL.md` | 242 |
| `skills/implement-feature/SKILL.md` | 85 |
| `skills/create-backlog/SKILL.md` | 52 |
| `skills/scaffold/SKILL.md` | 180, 183, 188, 213, 217, 221, 1068, 1070, 1076, 1078, 1098 |
| `skills/init/SKILL.md` | 202, 215, 225, 263, 341 (self-refs — renamed by directory rename) |
| `skills/workflow-router/SKILL.md` | 20 (intent table) |
| `docs/getting-started.md` | 115, 125 |
| `docs/reference/skills.md` | 391 (section heading `### /init`), 398–427 (examples) |
| `docs/guides/installation.md` | 92 |
| `docs/guides/mcp-configuration.md` | 5, 52 |
| `docs/guides/troubleshooting.md` | 225 |
| `README.md` | 164 (skill table row `\| /init \|`) |
| `CLAUDE.md` | 31 (skills enumeration) |

**Note:** `core/mcp-preflight.md` and `core/config-reader.md` were NOT in the spec's enumeration for Actions 3/4. These are high-priority because they are shared by all pipeline skills.

### `/ceos-agents:status` references (active non-forge files)

| File | Line(s) |
|------|---------|
| `skills/workflow-router/SKILL.md` | 18 (intent table), 54 (Step 3 non-destructive prose: bare word `status`) |
| `skills/status/SKILL.md` | self-refs — renamed by directory rename |
| `docs/reference/skills.md` | 33 (Skill Index table), 193 (Related skills in `/fix-bugs` section), 509 (section heading `### /status`), 516, 524 (examples), 555, 584 (Related skills refs) |
| `docs/guides/troubleshooting.md` | 311 |
| `README.md` | 153 (skill table row `\| /status \|`) |
| `CLAUDE.md` | 31 (skills enumeration) |

**Tests with path references (will HARD-FAIL after rename):**
- `tests/scenarios/no-mcp-jargon-errors.sh:20` — `"skills/status/SKILL.md"`

### `/create-pr` and `create-pr` references (active non-forge files)

| File | Line(s) |
|------|---------|
| `skills/workflow-router/SKILL.md` | 15 (intent table row), 55 (Step 4 destructive prose) |
| `skills/create-pr/SKILL.md` | entire file (to be deleted) |
| `docs/reference/automation-config.md` | 19, 20 (PR Rules + PR Description Template "Used By" columns — **SPEC MISSED THESE**) |
| `docs/reference/skills.md` | 26 (Skill Index table row), 323 (section heading `### /create-pr`), 330, 338 (examples), 363 (Related skills in `/publish` section) |
| `README.md` | 148 (skill table row `\| /create-pr \|`) |
| `CLAUDE.md` | 31 (skills enumeration) |
| `tests/scenarios/no-mcp-jargon-errors.sh` | 15 (STANDARD_ERROR_FILES) |
| `tests/scenarios/skills-directory-structure.sh` | 36 (EXPECTED_SKILLS array) |
| `tests/scenarios/skills-frontmatter-check.sh` | 51 (PIPELINE_SKILLS array) |

---

## Q5: workflow-router intent table and Step 3/4 prose

**Direct Answer:** All three deprecated identifiers appear in the intent table AND in Step 3/4 prose.

**Verbatim intent table rows (`skills/workflow-router/SKILL.md:15-20`):**
```
| Create a pull request | `ceos-agents:create-pr` | None | Yes |
| Publish (PR + issue state) | `ceos-agents:publish` | None | Yes |
| Show status/overview | `ceos-agents:status` | None | No |
| Configure MCP/tokens/permissions | `ceos-agents:init` | Optional: --update | Yes |
```

**Step 3/4 prose (exact, `SKILL.md:54-55`):**
```
3. **If the operation is NOT destructive** (analyze-bug, check-setup, version-check, status, dashboard, metrics, estimate, prioritize, template, scaffold-validate, check-deploy without flags, autopilot --dry-run): invoke the command immediately
4. **If the operation IS destructive** (fix-ticket, fix-bugs, create-pr, publish, check-deploy --start/--stop, autopilot without --dry-run):
```

**5 surgical edits needed in `skills/workflow-router/SKILL.md`:**
1. Line 15: DELETE the `create-pr` table row
2. Line 18: `ceos-agents:status` → `ceos-agents:pipeline-status`
3. Line 20: `ceos-agents:init` → `ceos-agents:setup-mcp`
4. Line 54: `status` → `pipeline-status` in the non-destructive list
5. Line 55: remove `create-pr,` from the destructive list

The `/publish` row (line 16) description "PR + issue state" remains accurate after auto-detect and needs no change.

---

## Q6: `/publish` branch-to-issue-ID extraction logic

**Direct Answer:** `skills/publish/SKILL.md` Steps 1-3 have no extraction logic — issue ID is assumed from pipeline context. There is no existing branch→issue-ID reverse extraction pattern documented.

**Evidence:**
- `skills/publish/SKILL.md:21` — `1. Determine the current branch and issue ID` (no extraction spec)
- `skills/fix-ticket/SKILL.md:169` — branch created with `git checkout -b {branch_naming} {base_branch}`
- `skills/fix-ticket/SKILL.md:91` — issue ID validated with `^[A-Za-z0-9#._-]+$` regex
- `docs/reference/automation-config.md:109-111` — `Branch naming | fix/{issue-id}-{description}` — template string, no capture groups

**Auto-detect implementation guidance for Action 5:** Parse the `Branch naming` template from Automation Config to find the position of `{issue-id}`. Apply the template as a pattern: strip the static prefix (e.g., `fix/`), extract the substring matching `^[A-Za-z0-9#._-]+` from the branch name after prefix removal. This is new parsing logic — no reference implementation exists. Use `core/mcp-detection.md` error classification for the 3-way fork.

---

## Q7: MCP tool names for single-issue fetch and error semantics

**Direct Answer:** The codebase uses **prefix-scan** (`mcp__youtrack__*`, etc.) — no hardcoded single-issue tool names exist in any core contract. The LLM discovers the exact tool at runtime. Error classification uses string-pattern matching, not HTTP status codes.

**Tool prefix table (`core/mcp-detection.md:28-34`):**
| Tracker | Prefix |
|---------|--------|
| youtrack | `mcp__youtrack__*` |
| github | `mcp__github__*` |
| jira | `mcp__jira__*` OR `mcp__atlassian__*` |
| linear | `mcp__linear__*` |
| gitea | `mcp__gitea__*` OR `mcp__forgejo__*` |
| redmine | `mcp__redmine__*` |

**Error classification (`core/mcp-detection.md:58-87`, priority order):**
| error_type | Trigger patterns |
|------------|-----------------|
| `"tls"` | UNABLE_TO_VERIFY_LEAF_SIGNATURE, CERT_UNTRUSTED, SELF_SIGNED_CERT, ERR_TLS_ |
| `"auth"` | 401, 403, unauthorized, forbidden, invalid token, authentication |
| `"not_found"` | 404, not_found, not found, ENOTFOUND, EAI_AGAIN |
| `"timeout"` | timeout, ETIMEDOUT, ECONNREFUSED, ECONNRESET |
| `"unknown"` | everything else |

**3-way fork for `/publish` auto-detect:**
1. Issue found → update tracker + create PR
2. `error_type == "not_found"` → PR-only mode, no tracker update
3. `error_type` is `timeout`, `auth`, or `tls` → FAIL with guidance citing `/ceos-agents:check-setup`

**Design intent (`core/mcp-detection.md:36`):** "Scan available tools for at least one tool matching the prefix." The `/publish` auto-detect prose should say: "Using the MCP tool prefix for {tracker_type}, locate the single-issue fetch tool (typically a `get_issue` or `getIssue` variant) and call it with `{issue_id}`. Classify the error per `core/mcp-detection.md` Classification Reference."

---

## Q8: Complete test scenario inventory for HARD-FAIL / false-positives after v7.0.0

### HARD-FAIL scenarios (must be updated)

| # | File | Line(s) | Failure reason | Required action |
|---|------|---------|---------------|-----------------|
| 1 | `tests/scenarios/regression-skill-count-29.sh` | 14 | `[ "$SKILL_COUNT" -ne 29 ]` fails when count drops to 28 | UPDATE: 29→28 |
| 2 | `tests/scenarios/ac-v68-doc-skill-count-29.sh` | 15, 21 | Positive check `'29 skills'` fails; negative check `'28 skills'` becomes false | UPDATE: flip both (positive→28, negative→29) |
| 3 | `tests/scenarios/v6.9.0-doc-count-drift.sh` | 42-45, 55-58, 72, 79, 89 | **Two simultaneous failures**: Assertion 3 looks for '19 optional' (FAIL); Assertion 5 rejects '18 optional' (FAIL) | UPDATE: see DISAGREEMENT D resolution for 5 specific changes |
| 4 | `tests/scenarios/skills-directory-structure.sh` | 36, 43, 54 | EXPECTED_SKILLS has `create-pr` (line 36), `init` (line 43), `status` (line 54); count 29 will be wrong | UPDATE: remove `create-pr`, rename `init`→`setup-mcp`, `status`→`pipeline-status` |
| 5 | `tests/scenarios/skills-frontmatter-check.sh` | 3, 43, 51, 82–98, 123 | `create-pr` in PIPELINE_SKILLS (line 51); `status`/`init` in READONLY_SKILLS (lines ~90,97); FC-5 comment "12 pipeline" | UPDATE: remove `create-pr`, update READONLY_SKILLS names, FC-5 count 12→11, FC-6 rename entries |
| 6 | `tests/scenarios/no-mcp-jargon-errors.sh` | 15, 20 | `"skills/create-pr/SKILL.md"` (line 15) — file deleted; `"skills/status/SKILL.md"` (line 20) — directory renamed | UPDATE: remove create-pr entry; update status path to pipeline-status |
| 7 | `tests/scenarios/config-reader-sections.sh` | 25 | `"Extra labels"` in OPTIONAL_SECTIONS array | UPDATE: remove `"Extra labels"` |
| 8 | `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` | 25, 47 | `"Extra labels"` in array; mutation guard `[ "${#OPTIONAL_SECTIONS[@]}" -eq 19 ]` | UPDATE: remove `"Extra labels"`, update guard 19→18, update success message |
| 9 | `tests/scenarios/v6.9.0-arch-freshness-refresh-on-release.sh` | 18-28 | Asserts `SKL[29 Skills]` (positive) AND rejects `SKL[28 Skills]` (negative) — both fire after architecture.md update | UPDATE: flip both assertions (positive→28, negative→29) |
| 10 | `tests/scenarios/scaffold-mcp-checkpoint.sh` | 7 | `INIT_SKILL="$REPO_ROOT/skills/init/SKILL.md"` path hardcoded | UPDATE: `init`→`setup-mcp` |
| 11 | `tests/scenarios/v6.10.0-dispatch-hook-install-surface.sh` | 17 | `INIT="$REPO_ROOT/skills/init/SKILL.md"` hardcoded | UPDATE: `init`→`setup-mcp` |
| 12 | `tests/scenarios/v644-diagnostics-hardening.sh` | 19, 36, 67, 109, 375, 378 | 6 references to `skills/init/SKILL.md` | UPDATE: all 6 `init`→`setup-mcp` |

### False-positive / no-change scenarios

| File | Classification | Reason |
|------|---------------|--------|
| `tests/scenarios/ac-v68-doc-optional-sections-18.sh` | PASS (no change) | `grep -nE '(18\|19) optional'` regex correctly accepts "18 optional" — test will still pass after drop to 18 |
| `tests/scenarios/xref-command-count.sh` | PASS (auto-update) | Uses dynamic filesystem count; will self-correct if CLAUDE.md updated consistently |
| `tests/scenarios/v6.9.0-cross-file-invariants.sh` | PASS (no change) | Tests invariant structure, not skill counts |

---

## Q9: Anchor docs — exact line numbers for "29 skills" and "19 optional"

### "29 skills" locations (live grep confirmed)

| File | Line | Current text |
|------|------|-------------|
| `CLAUDE.md` | 18 | `skills/ — 29 skills (slash commands, including workflow-router)` |
| `README.md` | 262 | `All 29 skills — syntax, flags, examples` |
| `docs/reference/skills.md` | 3 | `all 29 skills in the ceos-agents plugin. All 29 ceos-agents skills` |
| `docs/architecture.md` | 27 | `SKL[29 Skills]` (inside mermaid diagram) |

### "19 optional" locations (live grep confirmed)

| File | Line | Current text |
|------|------|-------------|
| `CLAUDE.md` | 160 | `There are 19 optional config sections in total.` |
| `README.md` | 221 | `**19 optional sections** cover retry limits, ...` |
| `docs/reference/automation-config.md` | 9 | `There are 5 required sections and 19 optional sections.` |

**docs/architecture.md:** Has `SKL[29 Skills]` at line 27 but NO "19 optional" string.

**Plugin metadata:** `plugin.json` and `marketplace.json` contain no count strings or skill-name references. No changes needed.

**`examples/configs/*.md`:** Zero matches for `ceos-agents:status`, `ceos-agents:init`, or `create-pr` in all 8 templates.

### Additional count-bearing location (from Agent 2 finding F7)

| File | Line | Current text |
|------|------|-------------|
| `docs/getting-started.md` | 219 | `Explore all 29 skills` |

---

## Validation Resolutions

### DISAGREEMENT A: 2 vs 8 config templates with `Extra labels`

**Verdict: 2 templates only.**

Live grep of all 8 files in `examples/configs/` confirms exactly 2 matches:
- `examples/configs/github-nextjs.md:104`
- `examples/configs/redmine-oracle-plsql.md:182`

The spec claim "8 config templates" was incorrect. Phase 7 must NOT touch the other 6.

---

### DISAGREEMENT B: Does `resume-ticket` qualify as a pause-emitting skill?

**Verdict: No — resume-ticket is RESUME-only. The correct list for Action 2 doc fix is all 6 lifecycle participants.**

`skills/resume-ticket/SKILL.md` does NOT write `status = "paused"` anywhere. It reads `state.json.status == "paused"` (Priority 0 — NEEDS_CLARIFICATION), processes the clarification answer, and writes `status = "running"`. It fires `pipeline-resumed` (not `pipeline-paused`).

The 4 pause-emitters: fix-ticket, fix-bugs, implement-feature, scaffold.
The autopilot enforces pause timeout and auto-aborts (but does not emit pause itself).
The resume-ticket is the resume handler.

**For Action 2 doc fix:** The "Used By" column at `docs/reference/automation-config.md:40` should list all 6 lifecycle participants: `/fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot, /resume-ticket`. This accurately reflects that all 6 are relevant to configuring/understanding Pause Limits behavior.

---

### DISAGREEMENT C: How many locations in `automation-config.md` say "/autopilot only"?

**Verdict: Only 1 location requires a mandatory fix (line 40). Line 628 is a low-priority consistency update inside an HTML comment.**

- `docs/reference/automation-config.md:40` — Quick reference table: `| Pause Limits | No | /autopilot |` — **MUST FIX** to list all 6 skills
- `docs/reference/automation-config.md:460` — Section heading `### Pause Limits` — body text accurately describes all-pipeline pause semantics. **No fix needed.**
- `docs/reference/automation-config.md:470` — Inside Example code block — shows section name only. **No fix needed.**
- `docs/reference/automation-config.md:628` — Inside `<!-- ... -->` HTML comment. **Optional consistency update only.**

---

### DISAGREEMENT D: Does `v6.9.0-doc-count-drift.sh` contain a negative assertion rejecting "18 optional"?

**Verdict: Confirmed — both a positive AND negative assertion fire simultaneously after updating CLAUDE.md to "18 optional".**

Reading `tests/scenarios/v6.9.0-doc-count-drift.sh` confirmed:

```bash
# Line 42-45 (Assertion 3 — POSITIVE): looks for "19 optional config sections in total"
if grep -qF '19 optional config sections in total' "$CLAUDE_MD"; then
  echo "OK"
else
  fail "AC-064a: CLAUDE.md missing '19 optional config sections in total'"  # FIRES after update

# Line 55-58 (Assertion 5 — NEGATIVE): rejects "18 optional config sections in total"
if grep -qF '18 optional config sections in total' "$CLAUDE_MD"; then
  fail "AC-064a: CLAUDE.md still has stale '18 optional config sections in total'"  # ALSO FIRES after update
fi
```

**Required changes to `v6.9.0-doc-count-drift.sh` in Phase 7:**
1. Line 42-45 (Assertion 3): change check from `'19 optional config sections in total'` → `'18 optional config sections in total'`
2. Line 55-58 (Assertion 5): flip the negative — check for `'19 optional config sections in total'` as stale (not `'18 optional'`)
3. Line 72: `[ "$skills_count" -eq 29 ]` → `[ "$skills_count" -eq 28 ]`
4. Line 79: `[ "$optional_count" -eq 19 ]` → `[ "$optional_count" -eq 18 ]`
5. Line 84 (fallback prose check): `'19 optional config sections in total'` → `'18 optional config sections in total'`
6. Line 89 (PASS message): `19 optional` → `18 optional`; `29 skills` → `28 skills`

---

## Canonical Change List (for Phase 6 planning)

### Action 1: Delete `Extra labels` config section

| File | Line | Current | New |
|------|------|---------|-----|
| `core/config-reader.md` | 31 | `### Extra labels` → `pr_rules.extra_labels` (default: none) | DELETE this parse rule |
| `agents/publisher.md` | 69 | `If Extra labels section exists, add those too.` | DELETE / rewrite: "Add labels from PR Rules section only." |
| `skills/fix-ticket/SKILL.md` | 47 | `**Extra labels** from Extra labels section (if it exists):` | DELETE this bullet |
| `skills/fix-ticket/SKILL.md` | 638 | `Extra labels: {Labels from Extra labels config, if they exist}.` | DELETE this segment from context string |
| `skills/fix-bugs/SKILL.md` | 42 | `**Extra labels** from Extra labels section (if it exists):` | DELETE this bullet |
| `skills/fix-bugs/SKILL.md` | 783 | `Extra labels: {Labels from Extra labels config, if they exist}.` | DELETE this segment |
| `skills/implement-feature/SKILL.md` | 35 | `Extra labels: Labels (default: none) — additional labels for the PR` | DELETE this line |
| `skills/implement-feature/SKILL.md` | 599 | `+ Extra labels (from Extra labels config, if they exist)` | DELETE this segment |
| `skills/check-setup/SKILL.md` | 56 | `..., Extra labels, Decomposition, ...` | REMOVE `Extra labels,` from the list |
| `skills/migrate-config/SKILL.md` | 41 | `..., Extra labels, Feature Workflow, ...` | REMOVE `Extra labels,` from the loop enumeration |
| `skills/onboard/SKILL.md` | 175 | `[12] Extra labels — additional PR labels` | DELETE this menu item |
| `skills/onboard/SKILL.md` | 204 | `Extra labels: Labels (default: none)` | DELETE this config summary line |
| `docs/reference/automation-config.md` | 33 | `\| Extra labels \| No \| /fix-ticket, /fix-bugs, /implement-feature \|` | DELETE entire row |
| `docs/reference/automation-config.md` | 332–339 | `### Extra labels` section body (heading + table) | DELETE entire section |
| `CLAUDE.md` | 149 | `\| Extra labels \| Labels \| (none) \|` | DELETE this table row |
| `CLAUDE.md` | 160 | `There are 19 optional config sections in total.` | `There are 18 optional config sections in total.` |
| `examples/configs/github-nextjs.md` | 104 | `### Extra labels (optional)` section | DELETE entire section |
| `examples/configs/redmine-oracle-plsql.md` | 182 | `### Extra labels (optional)` section | DELETE entire section |
| `tests/scenarios/config-reader-sections.sh` | 25 | `"Extra labels"` in OPTIONAL_SECTIONS array | REMOVE this array element |
| `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` | 25 | `"Extra labels"` in OPTIONAL_SECTIONS array | REMOVE this array element |
| `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` | 47 | `[ "${#OPTIONAL_SECTIONS[@]}" -eq 19 ]` | UPDATE to `-eq 18` |

---

### Action 2: Fix `Pause Limits` doc mapping

| File | Line | Current | New |
|------|------|---------|-----|
| `docs/reference/automation-config.md` | 40 | `\| Pause Limits \| No \| /autopilot \|` | `\| Pause Limits \| No \| /fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot, /resume-ticket \|` |

No other changes required for Action 2 (section body at lines 460–477 is accurate; line 628 in HTML comment is optional).

---

### Action 3: Rename `/ceos-agents:status` → `/ceos-agents:pipeline-status`

**Directory rename:** `skills/status/` → `skills/pipeline-status/`

| File | Line(s) | Current | New |
|------|---------|---------|-----|
| `skills/pipeline-status/SKILL.md` | frontmatter | `name: status` | `name: pipeline-status` |
| `skills/workflow-router/SKILL.md` | 18 | `\| Show status/overview \| ceos-agents:status \| None \| No \|` | `\| Show status/overview \| ceos-agents:pipeline-status \| None \| No \|` |
| `skills/workflow-router/SKILL.md` | 54 | `..., status, dashboard, ...` (bare word in Step 3 list) | `..., pipeline-status, dashboard, ...` |
| `docs/reference/skills.md` | 33 | `\| Monitoring \| [/status](#status) \| Overview of in-progress issues \|` | `\| Monitoring \| [/pipeline-status](#pipeline-status) \| Overview of in-progress issues \|` |
| `docs/reference/skills.md` | 193 | `[/status](#status)` (Related skills in fix-bugs section) | `[/pipeline-status](#pipeline-status)` |
| `docs/reference/skills.md` | 509 | `### /status` | `### /pipeline-status` |
| `docs/reference/skills.md` | 516, 524 | `/ceos-agents:status` examples | `/ceos-agents:pipeline-status` |
| `docs/reference/skills.md` | 555 | `[/status](#status)` (Related skills) | `[/pipeline-status](#pipeline-status)` |
| `docs/reference/skills.md` | 584 | `[/status](#status)` (Related skills) | `[/pipeline-status](#pipeline-status)` |
| `docs/guides/troubleshooting.md` | 311 | `/ceos-agents:status` | `/ceos-agents:pipeline-status` |
| `README.md` | 153 | `\| \`/status\` \| Overview of in-progress issues...\|` | `\| \`/pipeline-status\` \| Overview of in-progress issues...\|` |
| `CLAUDE.md` | 31 | `..., /status, ...` (in skills enumeration) | `..., /pipeline-status, ...` |
| `tests/scenarios/skills-directory-structure.sh` | 54 | `status` in EXPECTED_SKILLS array | `pipeline-status` |
| `tests/scenarios/skills-frontmatter-check.sh` | ~90 | `status` in READONLY_SKILLS array | `pipeline-status` |
| `tests/scenarios/no-mcp-jargon-errors.sh` | 20 | `"skills/status/SKILL.md"` | `"skills/pipeline-status/SKILL.md"` |

---

### Action 4: Rename `/ceos-agents:init` → `/ceos-agents:setup-mcp`

**Directory rename:** `skills/init/` → `skills/setup-mcp/`

| File | Line(s) | Current | New |
|------|---------|---------|-----|
| `skills/setup-mcp/SKILL.md` | frontmatter | `name: init` | `name: setup-mcp` |
| `skills/setup-mcp/SKILL.md` | 202, 215, 225, 263, 341 | `re-run /ceos-agents:init` / `re-run /ceos-agents:init --update` | `re-run /ceos-agents:setup-mcp` |
| `core/config-reader.md` | 57 | `run /ceos-agents:init.` | `run /ceos-agents:setup-mcp.` |
| `core/mcp-preflight.md` | 36 | `or /ceos-agents:init to configure the {tracker_type} integration` | `or /ceos-agents:setup-mcp to configure the {tracker_type} integration` |
| `skills/check-setup/SKILL.md` | 68, 76 | `Run /ceos-agents:init to create one.` / `Run /ceos-agents:init to set it up.` | `/ceos-agents:setup-mcp` |
| `skills/status/SKILL.md` (now `pipeline-status`) | 60, 82 | `run /ceos-agents:init` | `run /ceos-agents:setup-mcp` |
| `skills/onboard/SKILL.md` | 242 | `Run /ceos-agents:init to configure MCP servers and permissions` | `/ceos-agents:setup-mcp` |
| `skills/implement-feature/SKILL.md` | 85 | `run /ceos-agents:init` | `run /ceos-agents:setup-mcp` |
| `skills/create-backlog/SKILL.md` | 52 | `or /ceos-agents:init to configure the {Type} integration` | `/ceos-agents:setup-mcp` |
| `skills/scaffold/SKILL.md` | 180, 183, 188, 213, 217, 221, 1068, 1070, 1076, 1078, 1098 | `/ceos-agents:init` | `/ceos-agents:setup-mcp` |
| `skills/workflow-router/SKILL.md` | 20 | `ceos-agents:init` (intent table) | `ceos-agents:setup-mcp` |
| `docs/reference/skills.md` | 29 | `\| Config \| [/init](#init) \|` | `\| Config \| [/setup-mcp](#setup-mcp) \|` |
| `docs/reference/skills.md` | 387 | `[/init](#init)` (Related skills) | `[/setup-mcp](#setup-mcp)` |
| `docs/reference/skills.md` | 391 | `### /init` | `### /setup-mcp` |
| `docs/reference/skills.md` | 398–427 | `/ceos-agents:init` syntax block (5+ examples) | `/ceos-agents:setup-mcp` |
| `docs/getting-started.md` | 115, 125 | `/ceos-agents:init` | `/ceos-agents:setup-mcp` |
| `docs/guides/installation.md` | 92 | `/ceos-agents:init` | `/ceos-agents:setup-mcp` |
| `docs/guides/mcp-configuration.md` | 5, 52 | `/ceos-agents:init` | `/ceos-agents:setup-mcp` |
| `docs/guides/troubleshooting.md` | 225 | `/ceos-agents:init` | `/ceos-agents:setup-mcp` |
| `README.md` | 164 | `\| \`/init\` \| Developer environment setup...\|` | `\| \`/setup-mcp\` \| Developer environment setup...\|` |
| `CLAUDE.md` | 31 | `..., /init, ...` | `..., /setup-mcp, ...` |
| `tests/scenarios/skills-directory-structure.sh` | 43 | `init` in EXPECTED_SKILLS array | `setup-mcp` |
| `tests/scenarios/skills-frontmatter-check.sh` | ~97 | `init` in READONLY_SKILLS array | `setup-mcp` |
| `tests/scenarios/scaffold-mcp-checkpoint.sh` | 7 | `INIT_SKILL="$REPO_ROOT/skills/init/SKILL.md"` | `INIT_SKILL="$REPO_ROOT/skills/setup-mcp/SKILL.md"` |
| `tests/scenarios/v6.10.0-dispatch-hook-install-surface.sh` | 17 | `INIT="$REPO_ROOT/skills/init/SKILL.md"` | `INIT="$REPO_ROOT/skills/setup-mcp/SKILL.md"` |
| `tests/scenarios/v644-diagnostics-hardening.sh` | 19, 36, 67, 109, 375, 378 | `skills/init/SKILL.md` (6 occurrences) | `skills/setup-mcp/SKILL.md` |

---

### Action 5: `/publish` auto-detect rewrite + delete `/create-pr`

**DELETE: `skills/create-pr/` entire directory**

**Rewrite `skills/publish/SKILL.md` Steps 1-3** (current steps 1-3 say only "Determine the current branch and issue ID" / "Verify commits above base" / "Check whether open PR exists"):

Steps 1-3 replacement logic:
```
1. Determine the current branch name: `git branch --show-current` (or equivalent).
2. Extract the issue ID from the branch name:
   a. Read `Source Control → Branch naming` from Automation Config.
   b. Identify the static prefix before `{issue-id}` in the template (e.g., `fix/` → strip it).
   c. Extract the substring matching `^[A-Za-z0-9#._-]+` from the branch name after prefix removal.
   d. If extraction fails (no matching prefix or no valid issue-ID-shaped segment) → skip to Step 3 with issue_id = null.
3. If issue_id is not null: attempt to fetch the issue via the tracker MCP tool (using prefix-scan per core/mcp-detection.md):
   a. Issue found → proceed to full pipeline (PR + tracker state update)
   b. error_type == "not_found" → PR-only mode (skip tracker update, log INFO)
   c. error_type is "timeout", "auth", or "tls" → FAIL with guidance: "Tracker unreachable or misconfigured. Run /ceos-agents:setup-mcp to diagnose."
   If issue_id is null → PR-only mode directly (log INFO "No issue ID found in branch name").
4. Verify that the current branch has commits above the base branch...
5. Check whether an open PR already exists for the current branch.
```

**Reference updates for `/create-pr` deletion:**

| File | Line(s) | Change |
|------|---------|--------|
| `docs/reference/automation-config.md` | 19 | `\| PR Rules \| Yes \| /publish, /create-pr, publisher \|` → remove `/create-pr,` |
| `docs/reference/automation-config.md` | 20 | `\| PR Description Template \| Yes \| /publish, /create-pr, publisher \|` → remove `/create-pr,` |
| `docs/reference/skills.md` | 26 | DELETE `\| Publishing \| [/create-pr](#create-pr) \|` row from Skill Index table |
| `docs/reference/skills.md` | 323–342 | DELETE entire `### /create-pr` section |
| `docs/reference/skills.md` | 363 | `**Related skills:** [/create-pr](#create-pr), [/fix-ticket](#fix-ticket)` → remove `/create-pr` reference |
| `README.md` | 148 | DELETE `\| \`/create-pr\` \| Create a PR for the current branch \|` row |
| `CLAUDE.md` | 31 | Remove `/create-pr,` from skills enumeration |
| `skills/workflow-router/SKILL.md` | 15 | DELETE `create-pr` intent table row |
| `skills/workflow-router/SKILL.md` | 55 | Remove `create-pr,` from destructive list prose |
| `tests/scenarios/no-mcp-jargon-errors.sh` | 15 | REMOVE `"skills/create-pr/SKILL.md"` from STANDARD_ERROR_FILES |
| `tests/scenarios/skills-directory-structure.sh` | 36 | REMOVE `create-pr` from EXPECTED_SKILLS array |
| `tests/scenarios/skills-frontmatter-check.sh` | 51 | REMOVE `create-pr` from PIPELINE_SKILLS array; update FC-5 count comment 12→11 |

---

### Action 6: README + docs warnings about builtin collisions

**New section to INSERT in `README.md`** (before or after Installation section):

Content: Warning that `/status` and `/init` are deprecated; users must use `/ceos-agents:pipeline-status` and `/ceos-agents:setup-mcp`. Short forms `/status` and `/init` conflict with Claude Code built-in commands. Always use the `ceos-agents:` namespace prefix.

**New section to INSERT in `docs/guides/installation.md`** (Agent 2 finding F5 confirmed: no existing Limitations/Caveats section — this requires adding a NEW section, not extending an existing one):

Content: Same collision warning. Document that `/ceos-agents:status` was renamed to `/ceos-agents:pipeline-status` and `/ceos-agents:init` was renamed to `/ceos-agents:setup-mcp` in v7.0.0.

---

### Cross-Cutting: Doc count updates

| File | Line | Current | New |
|------|------|---------|-----|
| `CLAUDE.md` | 18 | `29 skills (slash commands, including workflow-router)` | `28 skills (slash commands, including workflow-router)` |
| `CLAUDE.md` | 31 | `..., /create-pr, ..., /status, ..., /init, ...` | remove `/create-pr,`; `/status`→`/pipeline-status`; `/init`→`/setup-mcp` |
| `CLAUDE.md` | 149 | `\| Extra labels \| Labels \| (none) \|` | DELETE row |
| `CLAUDE.md` | 160 | `There are 19 optional config sections in total.` | `There are 18 optional config sections in total.` |
| `README.md` | 148 | `\| \`/create-pr\` \| ...\|` | DELETE row |
| `README.md` | 153 | `\| \`/status\` \|` | `\| \`/pipeline-status\` \|` |
| `README.md` | 164 | `\| \`/init\` \|` | `\| \`/setup-mcp\` \|` |
| `README.md` | 221 | `**19 optional sections** cover ..., labels, ...` | `**18 optional sections** cover ...` (remove "labels" from list) |
| `README.md` | 262 | `All 29 skills — syntax, flags, examples` | `All 28 skills — syntax, flags, examples` |
| `docs/reference/skills.md` | 3 | `all 29 skills ... All 29 ceos-agents skills` | `all 28 skills ... All 28 ceos-agents skills` |
| `docs/architecture.md` | 27 | `SKL[29 Skills]` | `SKL[28 Skills]` |
| `docs/reference/automation-config.md` | 9 | `19 optional sections` | `18 optional sections` |
| `docs/getting-started.md` | 219 | `Explore all 29 skills` | `Explore all 28 skills` |

---

### Cross-Cutting: Test scenario updates

| File | Action | Detail |
|------|--------|--------|
| `tests/scenarios/regression-skill-count-29.sh` | UPDATE | Line 14: `-ne 29` → `-ne 28` |
| `tests/scenarios/ac-v68-doc-skill-count-29.sh` | UPDATE | Flip: positive check `28 skills`, negative check `29 skills` |
| `tests/scenarios/v6.9.0-doc-count-drift.sh` | UPDATE | 6 changes: see DISAGREEMENT D resolution |
| `tests/scenarios/skills-directory-structure.sh` | UPDATE | Remove `create-pr`; `status`→`pipeline-status`; `init`→`setup-mcp` in EXPECTED_SKILLS |
| `tests/scenarios/skills-frontmatter-check.sh` | UPDATE | Remove `create-pr` from PIPELINE_SKILLS; FC-5 comment 12→11; `status`→`pipeline-status`, `init`→`setup-mcp` in READONLY_SKILLS; update FC-6 comment |
| `tests/scenarios/no-mcp-jargon-errors.sh` | UPDATE | Remove `skills/create-pr/SKILL.md` (line 15); update `skills/status/SKILL.md` → `skills/pipeline-status/SKILL.md` (line 20) |
| `tests/scenarios/config-reader-sections.sh` | UPDATE | Remove `"Extra labels"` from OPTIONAL_SECTIONS array (line 25) |
| `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` | UPDATE | Remove `"Extra labels"` from array (line 25); update mutation guard 19→18 (line 47); update success message |
| `tests/scenarios/v6.9.0-arch-freshness-refresh-on-release.sh` | UPDATE | Flip both assertions: positive→`SKL[28 Skills]`, negative reject `SKL[29 Skills]` |
| `tests/scenarios/scaffold-mcp-checkpoint.sh` | UPDATE | Line 7: `skills/init/SKILL.md` → `skills/setup-mcp/SKILL.md` |
| `tests/scenarios/v6.10.0-dispatch-hook-install-surface.sh` | UPDATE | Line 17: `skills/init/SKILL.md` → `skills/setup-mcp/SKILL.md` |
| `tests/scenarios/v644-diagnostics-hardening.sh` | UPDATE | Lines 19, 36, 67, 109, 375, 378: `skills/init/SKILL.md` → `skills/setup-mcp/SKILL.md` |
| `tests/scenarios/ac-v68-doc-optional-sections-18.sh` | NO-CHANGE | `(18\|19) optional` regex correctly accepts 18 |
| `tests/scenarios/xref-command-count.sh` | NO-CHANGE | Dynamic count; auto-corrects if CLAUDE.md updated |
| `tests/scenarios/v6.9.0-cross-file-invariants.sh` | NO-CHANGE | Tests invariant structure, not counts |

---

## Phase 8 Verification Commands

```bash
# ─── Invariant 1: License SPDX consistency ───────────────────────────────────
grep -c '"MIT"' .claude-plugin/plugin.json
# Expected: 1
grep -c '"MIT"' .claude-plugin/marketplace.json
# Expected: 1
head -1 LICENSE | grep -qF 'MIT License' && echo "LICENSE: MIT OK" || echo "LICENSE: MIT FAIL"

# ─── Invariant 2: Maintainer email consistency ───────────────────────────────
for f in SECURITY.md CODE_OF_CONDUCT.md CONTRIBUTING.md; do
  echo "$f: $(grep -c 'filip.sabacky@ceosdata.com' "$f")"
done
# Expected: SECURITY.md: 1, CODE_OF_CONDUCT.md: 1, CONTRIBUTING.md: 2

# ─── Invariant 3: Issue/PR template parity ───────────────────────────────────
diff -q .gitea/issue_template/bug_report.md .github/ISSUE_TEMPLATE/bug_report.md \
  && echo "bug_report: IDENTICAL" || echo "bug_report: DIFFER (FAIL)"
diff -q .gitea/issue_template/feature_request.md .github/ISSUE_TEMPLATE/feature_request.md \
  && echo "feature_request: IDENTICAL" || echo "feature_request: DIFFER (FAIL)"
diff -q .gitea/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md \
  && echo "pull_request_template: IDENTICAL" || echo "pull_request_template: DIFFER (FAIL)"

# ─── Deprecated identifier sanity (must return 0) ────────────────────────────

# Extra labels removed everywhere (non-historical, non-forge)
grep -rn "Extra labels" \
  --include="*.md" \
  --exclude-dir=.forge \
  --exclude-dir=".forge.bak-*" \
  --exclude-dir=docs/plans \
  --exclude-dir=docs/superpowers \
  --exclude=CHANGELOG.md \
  . | wc -l
# Expected: 0

# No stale ceos-agents:status references (non-forge, active files only)
grep -rn "ceos-agents:status\b" \
  --include="*.md" \
  --exclude-dir=.forge \
  --exclude-dir=".forge.bak-*" \
  --exclude-dir=docs/plans \
  --exclude-dir=docs/superpowers \
  --exclude=CHANGELOG.md \
  . | wc -l
# Expected: 0

# No stale ceos-agents:init references
grep -rn "ceos-agents:init\b" \
  --include="*.md" \
  --exclude-dir=.forge \
  --exclude-dir=".forge.bak-*" \
  --exclude-dir=docs/plans \
  --exclude-dir=docs/superpowers \
  --exclude=CHANGELOG.md \
  . | wc -l
# Expected: 0

# No stale ceos-agents:create-pr references
grep -rn "ceos-agents:create-pr\b" \
  --include="*.md" \
  --exclude-dir=.forge \
  --exclude-dir=".forge.bak-*" \
  --exclude-dir=docs/plans \
  --exclude-dir=docs/superpowers \
  --exclude=CHANGELOG.md \
  . | wc -l
# Expected: 0

# ─── Skill directory sanity ──────────────────────────────────────────────────

[ ! -d skills/create-pr ] && echo "create-pr: DELETED OK" || echo "create-pr: STILL EXISTS (FAIL)"
[ ! -d skills/status ] && echo "skills/status: GONE OK" || echo "skills/status: STILL EXISTS (FAIL)"
[ -d skills/pipeline-status ] && echo "skills/pipeline-status: EXISTS OK" || echo "skills/pipeline-status: MISSING (FAIL)"
[ ! -d skills/init ] && echo "skills/init: GONE OK" || echo "skills/init: STILL EXISTS (FAIL)"
[ -d skills/setup-mcp ] && echo "skills/setup-mcp: EXISTS OK" || echo "skills/setup-mcp: MISSING (FAIL)"

SKILL_COUNT=$(find skills -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
[ "$SKILL_COUNT" -eq 28 ] && echo "skill count: 28 OK" || echo "skill count: $SKILL_COUNT (expected 28, FAIL)"

# ─── Doc count consistency ───────────────────────────────────────────────────

grep -qF '28 skills' CLAUDE.md && echo "CLAUDE.md 28 skills: OK" || echo "CLAUDE.md 28 skills: FAIL"
grep -qF '29 skills' CLAUDE.md && echo "CLAUDE.md stale 29: FAIL" || echo "CLAUDE.md stale 29: absent OK"
grep -qF '18 optional config sections in total' CLAUDE.md && echo "CLAUDE.md 18 optional: OK" || echo "CLAUDE.md 18 optional: FAIL"
grep -qF '19 optional config sections in total' CLAUDE.md && echo "CLAUDE.md stale 19: FAIL" || echo "CLAUDE.md stale 19: absent OK"

grep -qF '28 skills' README.md && echo "README 28 skills: OK" || echo "README 28 skills: FAIL"
grep -qF '18 optional sections' README.md && echo "README 18 optional: OK" || echo "README 18 optional: FAIL"

grep -qE 'all 28 skills' docs/reference/skills.md && echo "skills.md 28: OK" || echo "skills.md 28: FAIL"
grep -qF '18 optional sections' docs/reference/automation-config.md && echo "automation-config 18: OK" || echo "automation-config 18: FAIL"
grep -qF 'SKL[28 Skills]' docs/architecture.md && echo "architecture 28: OK" || echo "architecture 28: FAIL"

# ─── Pause Limits Used-By column updated ────────────────────────────────────

grep -A0 'Pause Limits.*No' docs/reference/automation-config.md | grep -q 'fix-ticket' \
  && echo "Pause Limits Used-By updated: OK" \
  || echo "Pause Limits Used-By still /autopilot only: FAIL"

# ─── Frontmatter names correct after renames ─────────────────────────────────

grep -q '^name: pipeline-status' skills/pipeline-status/SKILL.md \
  && echo "pipeline-status frontmatter: OK" || echo "pipeline-status frontmatter: FAIL"
grep -q '^name: setup-mcp' skills/setup-mcp/SKILL.md \
  && echo "setup-mcp frontmatter: OK" || echo "setup-mcp frontmatter: FAIL"
```

---

## Synthesis Notes

- **Base:** Agent 2 (19/20) — selected for strongest breadth, unique identification of findings F1-F12 (spec missed `docs/reference/automation-config.md:19-20` create-pr references, `docs/reference/skills.md` Related skills dead anchors, `core/mcp-preflight.md` and `core/config-reader.md` init references, README.md:221 "19 optional" string, skills.md multi-location status/init/create-pr refs)
- **Contributions merged from Agent 1:** DISAGREEMENT D resolution — exact lines 89 (PASS message) and line 84 (fallback prose) in `v6.9.0-doc-count-drift.sh` that Agent 2 omitted; DISAGREEMENT B full rationale (agents 1+2 ultimately agree)
- **Contributions merged from Agent 3:** Phase 8 verification commands (bash one-liners with pass/fail output); `v6.9.0-arch-freshness-refresh-on-release.sh` HARD-FAIL identification (test asserts `SKL[29 Skills]` and rejects `SKL[28 Skills]` — not in Agent 2's Q8 list); `ac-v68-doc-optional-sections-18.sh` classification (NO-CHANGE — Agent 3 correctly identifies the `(18|19)` regex accepts 18)
- **Disagreements:** All 4 resolved. No unresolved tensions.

**Spec corrections required for Phase 4 (spec author must update before Phase 7 execution):**
1. Spec Action 1 says "8 config templates reference Extra labels" → CORRECTED to 2 templates only
2. Spec Action 2 lists wrong consumer count for Pause Limits → CORRECTED: 6 lifecycle participants (4 pause-emitters + autopilot + resume-ticket)
3. Spec Action 5 does not address `docs/reference/automation-config.md:19-20` (`create-pr` in PR Rules and PR Description Template "Used By" columns) → MUST ADD to Action 5 change list
4. Spec Actions 3+4 do not list `core/mcp-preflight.md` and `core/config-reader.md` as containing `/ceos-agents:init` → MUST ADD to Action 4 change list
5. Spec does not address `v6.9.0-arch-freshness-refresh-on-release.sh` (asserts `SKL[29 Skills]`) → MUST ADD to test update list
6. Spec does not address `docs/getting-started.md:219` "Explore all 29 skills" count string → MUST ADD to cross-cutting count updates
