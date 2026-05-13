# Phase 1 Research Questions — Agent 1

## Question 1: Autopilot section placement and format within each config template

**Target files:**
- `examples/configs/github-nextjs.md` (lines 48–134, comment block)
- `examples/configs/redmine-oracle-plsql.md` (lines 112–181, comment block)
- `examples/configs/github-python-fastapi.md`
- `examples/configs/github-dotnet.md`
- `examples/configs/gitea-spring-boot.md`
- `examples/configs/jira-react.md`
- `examples/configs/youtrack-python.md`
- `examples/configs/redmine-rails.md`

**Question:** In each of the 8 config templates, what is the EXACT structure of the optional-section comment block — specifically: (a) Are optional sections placed inside `<!-- ... -->` HTML comments or inline? (b) What header format is used for optional sections (e.g., `### Autopilot (optional)` vs `### Autopilot`)? (c) Where in the section ordering should `### Autopilot` be inserted (before/after which sibling section, and does position differ per template)? (d) What is the canonical 7-row `| Key | Value |` table body that must appear, and where can Phase 2 copy the authoritative default values from (`docs/reference/config.md` Autopilot table lines 11–29)?

---

## Question 2: Config reference — does docs/reference/config.md already document Autopilot with the right 7 keys?

**Target files:**
- `docs/reference/config.md` (lines 1–60 approximately)

**Question:** Does `docs/reference/config.md` already contain a `### Autopilot` section with all 7 canonical keys (`Max issues per run`, `Lock timeout`, `Log file`, `Bug limit`, `Feature limit`, `On error`, `Dry run`) and their defaults? Is this table the authoritative source Phase 4 should instruct implementers to copy verbatim into each template? Confirm exact line numbers and whether any key description needs to be shortened for template usage (templates typically abbreviate versus full docs).

---

## Question 3: issue_id character-set — what characters do trackers produce and where is the path constructed?

**Target files:**
- `skills/fix-ticket/SKILL.md` (lines 87–89: `.ceos-agents/{ISSUE-ID}/` directory creation and `run_id` generation)
- `skills/fix-bugs/SKILL.md` (lines 90–98: same path construction)
- `state/schema.md` (lines 20–30: RUN-ID Determination table — examples: `PROJ-42_20260418T133000Z`, `#123`)
- `core/state-manager.md` (lines 1–35: write process `run_id` parameter)
- `skills/autopilot/SKILL.md` (lines 282–284: `Skill(ceos-agents:fix-ticket, arguments={ISSUE-ID})`)

**Question:** When `skills/fix-ticket/SKILL.md` constructs `.ceos-agents/{ISSUE-ID}/state.json`, the raw ISSUE-ID argument is used directly as a filesystem path segment. What characters can a tracker-supplied ISSUE-ID contain — specifically: (a) GitHub/Gitea produce `#123` (hash + digits); does the `#` appear in the filesystem path or is it stripped before path construction? (b) YouTrack/Jira produce `PROJ-42` (letters + hyphen + digits — filesystem-safe); (c) Redmine produces integer IDs; (d) Linear produces `{TEAM}-{N}` or UUID formats. Is there any existing sanitization step (regex gate, character allowlist) before the `mkdir .ceos-agents/{ISSUE-ID}/` call, or is path construction raw? The roadmap says item 2 is "issue_id regex gate in state.json path derivation (path-traversal defense-in-depth)" — confirm the exact lines where path is constructed with zero sanitization today.

---

## Question 4: JSON payload interpolation — what is the actual injection risk and what already exists in the curl heredoc pattern?

**Target files:**
- `core/post-publish-hook.md` (lines 17–23: Section 3 pr-created curl heredoc; lines 56–113: Section 4 new events)
- `docs/reference/config.md` (Notifications section — webhook operator trust note)
- `CLAUDE.md` (lines mentioning SSRF / injection / operator trust)

**Question:** The `pr-created` payload in `core/post-publish-hook.md` Section 3 uses a bash heredoc to pass JSON, with this comment: "Use a heredoc to pass the JSON body so that special characters (quotes, backslashes) in variable values do not break the shell command." Section 4 events (`pipeline-started`, `step-completed`, `pipeline-completed`) use the same pattern. What injection scenario is NOT yet documented: specifically, if `${issue_id}` contains a double-quote or newline, does the heredoc protect against JSON structural corruption, or does an attacker-controlled `issue_id` containing `","event":"injected` still break the JSON structure? Where exactly is the documentation gap — is there a prose note in Section 4 that says "values MUST be JSON-string-escaped" or equivalent, or is the only documentation the Section 3 heredoc comment? Confirm whether `run_id` (which includes raw `issue_id` as prefix) has the same exposure.

---

## Question 5: Lock-timeout text alignment — all occurrences of "120" and "125" and the +5 buffer across docs

**Target files:**
- `skills/autopilot/SKILL.md` (lines 101, 127–128, 191, 208, 238: stale detection text + bash snippet)
- `docs/guides/autopilot.md` (lines containing "120", "125", "skew", "buffer" — confirmed at line 350)
- `docs/reference/config.md` (lines 18, 45, 58: Lock timeout table rows)

**Question:** Enumerate ALL occurrences of the numeric values "120" and "121" and "125" across the three files above. For each occurrence: (a) Does it refer to the user-facing config value ("120 min threshold") or the implementation detail ("120 + 5 = 125 min internal check")? (b) Is the +5 minute NFS/CIFS clock-skew buffer explicitly named and explained in prose, or only present as a bash variable comment (`# +5min NFS/CIFS skew buffer`)? (c) In `docs/guides/autopilot.md` line ~350, does the text say "120 minutes (plus a 5-minute NFS/CIFS skew buffer)" (already partially documented) or a different phrasing? (d) What prose addition is needed in `skills/autopilot/SKILL.md` and/or `docs/guides/autopilot.md` to make the buffer canonical and unambiguous — specifically in the Invariants section (line 238: "Stale threshold carries a +5 minute buffer to absorb NFS/CIFS clock skew") and the Troubleshooting section (line 368: says "<120min old, wait for stale timeout" — does this mention the buffer)?

---

## Question 6: Existing crash-recovery / mid-iteration test scenarios — pattern inventory

**Target files:**
- `tests/scenarios/ac-v68-cost-fixer-reviewer-cumulative.sh` (full file — AC-17 cumulative accumulation)
- `tests/scenarios/pipeline-state-writes.sh` (full file — state write assertions pattern)
- `tests/scenarios/ac5-fixer-reviewer-token-constraints.sh` (full file — fixer/reviewer constraints)
- `tests/scenarios/test-partial-failure.sh` (full file — partial failure recovery pattern)
- `state/schema.md` (lines 140–180: fixer_reviewer section with `iterations`, `tokens_used` fields)

**Question:** What is the exact structure of the existing scenario `ac-v68-cost-fixer-reviewer-cumulative.sh` — specifically what grep patterns does it use, what does it assert, and what is its PASS/FAIL boundary condition? The new v6.8.1 scenario must cover "fixer-reviewer crash mid-iteration → cumulative tokens_used integrity". What fields in `state/schema.md` must the new scenario assert on (e.g., `fixer_reviewer.tokens_used` must be non-negative even if `fixer_reviewer.iterations` is mid-value)? Is there an existing `test-partial-failure.sh` scenario that can serve as structural template for the new crash-recovery test?

---

## Question 7: Test harness exit-code propagation — is there actually a bug?

**Target files:**
- `tests/harness/run-tests.sh` (full file, 69 lines)

**Question:** The harness has `set -uo pipefail` (line 5) and `if [ $FAIL -gt 0 ]; then exit 1; fi` (lines 66–68). The roadmap says "harness currently exits 0 even when test failures exist". Where exactly is the exit-0 leak? Possible candidates: (a) The `((FAIL++))` arithmetic expression — in bash, `((expr))` returns exit code 1 when the expression evaluates to 0 (i.e., when FAIL was 0 and becomes 1, the expression `((FAIL++))` evaluates to the POST-increment value 0, which causes `set -e` to trigger an early exit 0 before line 66 is reached). Confirm: does `set -uo pipefail` + `((FAIL++))` cause the script to exit 0 early on the FIRST test failure because `((0++))` returns exit 1 which triggers pipefail? (b) If so, `FAIL` never reaches line 66, and the script exits via `set -e` trap with exit code... what? Trace the exact failure path and confirm what exit code the harness actually returns today when one test fails.

---

## Question 8: Test scenario file naming conventions for v6.8.1

**Target files:**
- `tests/scenarios/` (directory listing — 141 files)
- `tests/scenarios/ac-v68-cost-fixer-reviewer-cumulative.sh` (filename pattern for v6.8.0 tests)
- `tests/scenarios/ac-v68-autopilot-stale-lock-120min.sh` (filename pattern)

**Question:** What filename prefix convention should v6.8.1 test scenarios use? Existing v6.8.0 scenarios use `ac-v68-` prefix (e.g., `ac-v68-autopilot-stale-lock-120min.sh`, `ac-v68-cost-fixer-reviewer-cumulative.sh`). Should v6.8.1 scenarios use `ac-v681-` or `v6.8.1-` or another pattern? Are there precedents for PATCH-version test naming (check for any `v671-` or `v644-` prefixed scenarios)? Confirm the exact prefix used by `tests/scenarios/v644-diagnostics-hardening.sh` to establish the naming convention for non-minor patch tests.

---

## Question 9: state/schema.md fixer_reviewer section — cumulative tokens_used semantics

**Target files:**
- `state/schema.md` (lines 100–180 approximately: fixer_reviewer section)
- `skills/fix-ticket/SKILL.md` (fixer_reviewer loop state write instructions)
- `core/fixer-reviewer-loop.md`

**Question:** In `state/schema.md`, what is the exact current documentation for `fixer_reviewer.tokens_used` — is it documented as "cumulative across all iterations" or as "per-iteration"? Does the CHANGELOG v6.8.0 entry (line 17: "Fixer-reviewer tokens accumulated cumulatively across iterations") match what is currently written in `state/schema.md`? What does `core/fixer-reviewer-loop.md` say about per-iteration vs cumulative token accumulation? The new crash-recovery test scenario (item 5) needs to assert that `tokens_used` is ≥ 0 after a mid-iteration crash — what exact field path does it need to check (`fixer_reviewer.tokens_used` or `pipeline.total_tokens`)?

---

## Question 10: version-bump skill atomicity — does it update CHANGELOG?

**Target files:**
- `skills/version-bump/SKILL.md` (full file — Steps 1–12)

**Question:** Does `/ceos-agents:version-bump` update `CHANGELOG.md` as part of its atomic commit, or does it only update `plugin.json` and `marketplace.json`? Confirm by reading the full step list (lines 28–47 confirmed: Steps 8–11 only write plugin.json, marketplace.json, commit, tag — no CHANGELOG step). If CHANGELOG is NOT updated by version-bump, confirm the release convention: CHANGELOG entry must be authored manually as part of the content commit BEFORE version-bump is run. Confirm that CLAUDE.md memory ("content+CHANGELOG in one commit, version-bump as separate commit") is consistent with what version-bump SKILL.md actually does.

---

## Question 11: Autopilot section row format in docs/reference/config.md vs CLAUDE.md — which is canonical for templates?

**Target files:**
- `docs/reference/config.md` (lines 1–50: Autopilot section with 7-key table)
- `CLAUDE.md` (Autopilot config section in the Config Contract table — lines describing 7 keys)

**Question:** `docs/reference/config.md` documents the Autopilot section as a `| Key | Value |` table with 7 rows (confirmed at lines 33–40). `CLAUDE.md` documents the same 7 keys in the Config Contract table with 3 columns (`Key | Default | Purpose`). Which format exactly should the template use — the `| Key | Value |` table with literal default values (like `| Max issues per run | 1 |`)? Confirm the exact row content for all 7 keys as they should appear in a config template comment block, especially the `On error` row (should it show `skip` or `skip | stop`?) and the `Dry run` row (`false` or `false | true`?).

---

## Summary

- Item coverage:
  - Item 1 (config-templates Autopilot section) → Q1, Q2, Q11
  - Item 2 (issue_id regex gate / path-traversal defense) → Q3, Q4
  - Item 3 (JSON-encode payload field interpolation docs) → Q4
  - Item 4 (lock-timeout 120 vs 125 / clock-skew buffer) → Q5
  - Item 5 (fixer-reviewer crash-recovery regression test) → Q6, Q8, Q9
  - Item 6 (test harness exit-code propagation) → Q7, Q8
  - Cross-cutting (version-bump, CHANGELOG release convention) → Q10

- Files to be read by Phase 2:
  - `examples/configs/github-nextjs.md` (lines 48–134)
  - `examples/configs/redmine-oracle-plsql.md` (lines 112–181)
  - `examples/configs/github-python-fastapi.md` (full)
  - `examples/configs/github-dotnet.md` (full)
  - `examples/configs/gitea-spring-boot.md` (full)
  - `examples/configs/jira-react.md` (full)
  - `examples/configs/youtrack-python.md` (full)
  - `examples/configs/redmine-rails.md` (full)
  - `docs/reference/config.md` (lines 1–60)
  - `skills/autopilot/SKILL.md` (lines 97–130, 230–245, 368–395)
  - `docs/guides/autopilot.md` (lines 340–360)
  - `skills/fix-ticket/SKILL.md` (lines 85–95)
  - `skills/fix-bugs/SKILL.md` (lines 88–98)
  - `state/schema.md` (lines 20–30, 140–180)
  - `core/post-publish-hook.md` (lines 17–30, 100–115)
  - `core/fixer-reviewer-loop.md` (full)
  - `tests/harness/run-tests.sh` (full, 69 lines)
  - `tests/scenarios/ac-v68-cost-fixer-reviewer-cumulative.sh` (full)
  - `tests/scenarios/pipeline-state-writes.sh` (full)
  - `tests/scenarios/test-partial-failure.sh` (full)
  - `tests/scenarios/v644-diagnostics-hardening.sh` (first 5 lines — filename convention check)
  - `skills/version-bump/SKILL.md` (full)
  - `CHANGELOG.md` (lines 1–46: v6.8.0 entry format)
