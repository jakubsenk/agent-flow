# Phase 1: Research Questions — Final (Synthesized)

## Meta
- Agent outputs reviewed: agent-1.md, agent-2.md, agent-3.md
- Total questions after merge: 16
- Decision: Agent-1 had the broadest cross-item coverage (11 Qs). Agent-2 had the deepest Item 5/6 focus (12 Qs, 4+3 for those items). Agent-3 had the strongest security framing for Item 2 (3 Qs) and clearest lock-timeout numeric discrepancy table. Merges: (a) A1-Q3+A2-Q9+A3-Q1+Q2+Q3 → 2 Qs (scope + character-set); (b) A1-Q4+A2-Q10+A3-Q4+Q5 → 2 Qs (gap identification + Section 3 precedent); (c) A1-Q5+A2-Q11+A3-Q6+Q7 → 2 Qs (numeric audit + guide phrasing); (d) A1-Q6+Q9+A2-Q2+Q3+Q4+A3-Q10 → 3 Qs (scenario template, gap, grep assertions); (e) A1-Q7+A2-Q5+Q6+Q7+A3-Q11 → 2 Qs (exit-code bug trace, CI/meta-test); (f) A1-Q1+Q2+Q11+A2-Q8+A3-Q8+Q9 → 3 Qs (template format, canonical key table, reference authority); (g) A1-Q10+A2-Q12+A3-Q12 → 1 Q (CHANGELOG/version-bump).

---

## Item 1: Config Template Autopilot Rows

### Q1.1: Optional-section format and Autopilot insertion position across all 8 templates
- **Files:** `examples/configs/github-nextjs.md` (full), `examples/configs/github-python-fastapi.md` (full), `examples/configs/github-dotnet.md` (full), `examples/configs/gitea-spring-boot.md` (full), `examples/configs/jira-react.md` (full), `examples/configs/youtrack-python.md` (full), `examples/configs/redmine-rails.md` (full), `examples/configs/redmine-oracle-plsql.md` (full)
- **Phase 2 must read:** All 8 files. Use `github-nextjs.md` as the canonical structural reference (Agent-3 identified it as having the HTML comment block pattern). Verify whether all 8 use `<!-- ... -->` comment blocks for optional sections, whether any (e.g., `gitea-spring-boot.md`, `youtrack-python.md`) have NO optional sections at all, and where the `### Autopilot` section sits in the ordering relative to sibling optional sections (e.g., after `### Notifications`, before or after `### Worktrees`). Confirm `### Autopilot` is currently absent from all 8.
- **Rationale:** Item 1 is a straightforward gap — 8 files need the same section added consistently. Phase 2 cannot write the fix without knowing (a) which files have a comment block to append to vs which need a block created from scratch, (b) the exact insertion position in sort order, and (c) whether the table header is `| Key | Value |` or `| Key | Default |`.

### Q1.2: Canonical 7-key Autopilot table format — what row content goes in templates?
- **Files:** `docs/reference/config.md` (Autopilot section), `docs/guides/autopilot.md` (lines 40–63), `CLAUDE.md` (Autopilot Config Keys table)
- **Phase 2 must read:** `docs/reference/config.md` full Autopilot section (verify the 7-key table exists with exact defaults). `docs/guides/autopilot.md` lines 40–63 (Agent-3 hypothesis: this has the canonical 7-row table with Type+Default columns). `CLAUDE.md` Autopilot Config Keys table (3 columns: Key | Default | Purpose). Determine which format is authoritative for the minimal config-template representation (`| Key | Value |` with literal defaults, NOT Type/Default/Purpose columns).
- **Rationale:** Templates use a minimal `| Key | Value |` table with default values pre-filled (Agent-1/Agent-2 finding). The row content for `On error` (`skip` vs `skip | stop`?) and `Dry run` (`false` vs `false | true`?) must be confirmed from the reference source. Phase 2 must know EXACTLY what to write in the 7 table rows.

### Q1.3: Does docs/reference/config.md have the Autopilot section already, and is it the table source?
- **Files:** `docs/reference/config.md` (lines 1–60)
- **Phase 2 must read:** The first ~60 lines to confirm (a) `### Autopilot` section exists with all 7 keys, (b) the table format used, (c) whether abbreviated or full descriptions are used compared to CLAUDE.md, (d) whether this is the authoritative copy Phase 4 implementers should treat as ground truth.
- **Rationale:** Agent-1 flagged this as the source of truth for template row values. If `docs/reference/config.md` is already correct and complete, Phase 2 simply mirrors it into templates. If it's missing or has a different key count, that is an additional defect to fix before the templates can be correctly populated.

---

## Item 2: issue_id Regex Gate (Path-Traversal Defense)

### Q2.1: Exact path-construction sites — where is issue_id used raw in a filesystem path?
- **Files:** `core/state-manager.md` (lines 22–35 Write Process; line ~167 failure handling), `skills/fix-ticket/SKILL.md` (lines 85–95), `skills/fix-bugs/SKILL.md` (lines 88–98), `skills/autopilot/SKILL.md` (Steps 5–6, lines ~282–322), `state/schema.md` (RUN-ID Determination section)
- **Phase 2 must read:** `core/state-manager.md` Write Process section to confirm whether the directory creation uses `{RUN-ID}` (which is `{issue_id}_{timestamp}`) or raw `{issue_id}`. `state/schema.md` RUN-ID Determination table (examples like `PROJ-42_20260418T133000Z`, `#123`). `skills/autopilot/SKILL.md` Steps 5–6 to determine whether autopilot constructs the path itself or passes `issue_id` to child skills. Enumerate ALL filesystem path construction sites across these files.
- **Rationale:** Agent-3 identified the attack surface clearly: if `issue_id` = `../../etc/passwd`, and it is used raw in `.ceos-agents/{issue_id}/state.json`, a path traversal is possible. The fix (a regex allowlist gate) must be placed at the earliest construction point. Phase 2 cannot locate the insertion point without reading these files.

### Q2.2: Per-tracker issue ID character sets — what is the safe allowlist?
- **Files:** `docs/reference/trackers.md` (if it exists), `state/schema.md` (example values in RUN-ID table), `core/external-input-sanitizer.md` (if it exists), `core/config-reader.md`
- **Phase 2 must read:** `state/schema.md` for documented example values per tracker type. Search `docs/reference/` for a trackers reference file. Search `core/` for any external-input-sanitizer. The goal is to produce a per-tracker character-set table: GitHub/Gitea (`#` + digits), YouTrack/Jira (`[A-Z]+-[0-9]+`), Redmine (integers), Linear (`[A-Z]+-[0-9]+` or UUID). Confirm no existing allowlist/regex is defined anywhere — establishing that the gate is genuinely new code.
- **Rationale:** The regex gate must accept all legitimate tracker IDs and reject shell metacharacters (`/`, `..`, `` ` ``, `$`, `"`, `'`). Phase 2 cannot draft the gate without knowing the full valid character set. Agent-3 noted `core/external-input-sanitizer.md` as a possible precedent — this must be confirmed or ruled out.

---

## Item 3: JSON-Encode Payload Interpolation Docs

### Q3.1: Section 3 vs Section 4 documentation gap in core/post-publish-hook.md
- **Files:** `core/post-publish-hook.md` (full file, ~137 lines)
- **Phase 2 must read:** Full file. Specifically: line 23 Section 3 note (Agent-3 hypothesis: "Use a heredoc to pass the JSON body so that special characters (quotes, backslashes) in variable values do not break the shell command" — quote verbatim). Section 4 (`pipeline-started`, `step-completed`, `pipeline-completed` events, lines ~56–113) — confirm that these new v6.8.0 events use bare `${variable}` interpolation in the heredoc with NO equivalent JSON-encoding note. Identify the exact insertion point for the new note in Section 4.
- **Rationale:** The gap is that Section 3 has a shell-quoting note but Section 4 does not document JSON-encoding requirements (i.e., if `${issue_id}` contains a double-quote or newline, the heredoc prevents shell breakage but does NOT prevent JSON structural corruption). The exact phrasing of the existing Section 3 note is needed so Section 4 can use consistent language — either extending it or adding a separate JSON-encoding note.

### Q3.2: Does block-handler.md or autopilot.md guide have an equivalent gap?
- **Files:** `core/block-handler.md` (lines 38–46 curl invocation), `docs/guides/autopilot.md` (lines 228–290 webhook payload section)
- **Phase 2 must read:** `core/block-handler.md` lines 38–46 to confirm whether its curl uses `-d` with inline variable substitution (not heredoc) — Agent-2 raised this as a possible second exposure site. `docs/guides/autopilot.md` lines 228–290 to confirm whether the guide's webhook payload section reproduces or references the encoding note from `core/post-publish-hook.md` Section 3 — or lacks it for the Section 4 events.
- **Rationale:** The fix scope for Item 3 may be larger than just `core/post-publish-hook.md`. If `block-handler.md` uses inline `-d` substitution it has the same gap and must also be patched. If `docs/guides/autopilot.md` is a user-facing doc that describes webhook payloads without encoding guidance, it needs a note too.

---

## Item 4: Lock-Timeout Text Alignment

### Q4.1: Complete numeric audit — all occurrences of 120/121/125 in SKILL.md and the ambiguity they create
- **Files:** `skills/autopilot/SKILL.md` (full file, ~395 lines)
- **Phase 2 must read:** Full file with grep for `120`, `121`, `125`. Agent-3 produced the definitive hypothesis for the discrepancy table: Line 52 (config default = 120), Line 101 (prose "older than Lock timeout minutes, default 120"), Line 127–128 (bash: `LOCK_TIMEOUT=120`, `LOCK_TIMEOUT_WITH_BUFFER=$((LOCK_TIMEOUT + 5))` → 125), Line 191 (BusyBox hardcode `find -mmin +121` — NOT +125), Line 238 (Invariant 6: "+5 minute buffer"), Line 368 (troubleshooting: "<120min old"). The BusyBox fallback uses `+121` while the primary path uses `+125` — both diverge from the config value of 120. Phase 2 must confirm these exact line numbers and determine the minimal prose fix that makes the relationship unambiguous.
- **Rationale:** A user reading Invariant 6 and the config table together cannot determine whether the stale threshold is 120, 121, or 125 minutes. The fix is a 1–2 sentence prose clarification, not a code change — but Phase 2 needs the exact line numbers and current text to write the diff.

### Q4.2: Guide phrasing — does docs/guides/autopilot.md already document the buffer, and is it consistent with SKILL.md?
- **Files:** `docs/guides/autopilot.md` (lines 340–380 troubleshooting section)
- **Phase 2 must read:** Lines 340–380. Agent-3 hypothesis: line ~350 says "120 minutes (plus a 5-minute NFS/CIFS skew buffer)" — if true, the guide IS partially correct but the SKILL.md line 191 BusyBox `+121` explanation is still missing and the invariant/troubleshooting lines in SKILL.md are inconsistent. Confirm whether the guide mentions the BusyBox path and whether both the primary-path (125) and BusyBox-path (121) are named anywhere in any file.
- **Rationale:** The fix must be applied consistently to both `skills/autopilot/SKILL.md` and `docs/guides/autopilot.md`. If the guide is already more complete than SKILL.md, Phase 2 can use the guide text as the model for the SKILL.md prose fix.

---

## Item 5: Fixer-Reviewer Crash-Recovery Regression Test

### Q5.1: Existing scenario skeleton conventions — what structure must the new scenario replicate exactly?
- **Files:** `tests/scenarios/ac-v68-cost-fixer-reviewer-cumulative.sh` (full), `tests/scenarios/ac5-fixer-reviewer-token-constraints.sh` (full), `tests/scenarios/pipeline-state-writes.sh` (full)
- **Phase 2 must read:** All three files. Extract: (a) shebang line, (b) `set` flags (is it `set -euo pipefail` or `set -uo pipefail`?), (c) `REPO_ROOT` derivation pattern, (d) `FAIL=0` / `fail()` helper pattern vs inline `((FAIL++))`, (e) final exit-code convention (`exit "$FAIL"` vs `exit 1`). Also determine the v6.8.1 test filename prefix — check whether any existing files use a `v681-` or `ac-v681-` prefix (cf. `v644-diagnostics-hardening.sh` prefix as a PATCH precedent).
- **Rationale:** All static scenarios must follow the same structural pattern to be picked up by the harness. Phase 2 cannot write the new scenario without knowing the exact skeleton. The filename prefix question is also here — Agent-1 and Agent-2 both flagged it, and `v644-diagnostics-hardening.sh` is the suggested precedent for PATCH-version naming.

### Q5.2: What does state/schema.md and core/fixer-reviewer-loop.md say about cumulative tokens_used, and what gap exists in crash-recovery semantics?
- **Files:** `state/schema.md` (lines 100–180 fixer_reviewer section), `core/fixer-reviewer-loop.md` (full), `core/state-manager.md` (Failure Handling section)
- **Phase 2 must read:** `core/fixer-reviewer-loop.md` in full — determine (a) which step writes `fixer_reviewer.tokens_used` (after each iteration or only at loop exit), (b) whether the write is described as atomic/immediate, (c) whether any crash-recovery or rollback path is documented. `state/schema.md` fixer_reviewer section — confirm current documentation says "cumulative across all iterations" (matching CHANGELOG v6.8.0 entry). `core/state-manager.md` Failure Handling — confirm the "retry once" atomic write rule and whether it is referenced in fixer-reviewer context.
- **Rationale:** This is the core gap the new test must fill. The test asserts doc-level properties (via grep against markdown sources), so Phase 2 needs to know EXACTLY what strings are currently in `core/fixer-reviewer-loop.md` and `state/schema.md` to write assertable grep patterns. If "atomic after each iteration" is not documented there, the fix adds that text AND adds a test that greps for it.

### Q5.3: What grep assertions can the new crash-recovery scenario make, based on current source text?
- **Files:** `core/fixer-reviewer-loop.md`, `core/state-manager.md`, `state/schema.md`, `tests/scenarios/ac-v68-cost-fixer-reviewer-cumulative.sh`
- **Phase 2 must read:** `ac-v68-cost-fixer-reviewer-cumulative.sh` in full (to understand what assertions the closest existing scenario makes). Then `core/fixer-reviewer-loop.md` and `state/schema.md` to identify grep-able strings that confirm: (a) tokens_used is written after each iteration (not only at loop exit), (b) the state-manager atomic-write rule covers this field, (c) `pipeline.total_tokens` accumulates from per-stage fields preserving partial data on crash. If these strings do NOT yet exist in the source, the fix must add them AND the test greps for the newly added text.
- **Rationale:** Static test scenarios in this repo are grep-based document checkers. Phase 2 must know what to grep for before it can write the scenario. This question bridges the "what the docs say" (Q5.2) with "what the test asserts" — a question neither agent posed as explicitly combined.

---

## Item 6: Test Harness Exit-Code Propagation

### Q6.1: Exact exit-code failure path — is the roadmap claim accurate and where does the leak occur?
- **Files:** `tests/harness/run-tests.sh` (full, 69 lines)
- **Phase 2 must read:** Full file. Agent-1 and Agent-3 both proposed the `((FAIL++))` hypothesis: when `FAIL=0`, `((FAIL++))` post-increments (result = 0 = false), returning exit code 1 from the arithmetic expression. Under `set -uo pipefail` WITHOUT `-e`, this does NOT abort the script — but in CI environments that use `set -e` wrappers or `bash -e run-tests.sh`, it may. Agent-3's framing is more precise: confirm `set -uo pipefail` (NOT `-e`) is present, which means `((FAIL++))` when FAIL=0 returns exit 1 from the expression but does NOT abort. Then confirm whether line 66–68 (`if [ $FAIL -gt 0 ]; then exit 1; fi`) is actually reached and exits 1. If the harness currently DOES exit 1 correctly, determine what the roadmap "exits 0 even when failures exist" claim refers to — possibly a specific edge case (e.g., `((PASS++))` or `((FAIL++))` when FAIL=1 causing a different issue, or a `|| true` somewhere).
- **Rationale:** The fix cannot be written without knowing exactly what is broken. If the exit-code propagation is already correct, the fix may be documentation/robustness (e.g., changing `((FAIL++))` to `FAIL=$((FAIL+1))` to avoid the arithmetic exit-code ambiguity), not a functional change.

### Q6.2: CI integration and meta-test coverage — is there a test for the harness itself?
- **Files:** `.gitea/workflows/*.yml` (if any exist), `tests/scenarios/test-fail.sh`, `tests/scenarios/verify-fail.sh`, `docs/guides/` (harness invocation docs)
- **Phase 2 must read:** `.gitea/workflows/` directory to confirm no active CI (CLAUDE.md memory: "CI runner not configured, all jobs cancelled"). `tests/scenarios/test-fail.sh` and `tests/scenarios/verify-fail.sh` to determine if any scenario tests the harness exit-code behavior itself. If these files exist and test harness exit propagation, their exact assertion pattern should be used as the template for the fix. If they don't exist, the fix may require a new meta-test scenario.
- **Rationale:** Agent-2 raised the CI-context question and the meta-test question as separate concerns. They are merged here because the answer to "what is the calling context" determines whether the fix is (a) the harness script itself, (b) a calling convention doc, or (c) a new meta-test. Phase 2 needs the full picture.

---

## Release Process (CHANGELOG + version-bump)

### Q7.1: CHANGELOG v6.8.0 structure, Known Issues section, and version-bump pre-flight guard
- **Files:** `CHANGELOG.md` (lines 1–47), `skills/version-bump/SKILL.md` (steps 6–11 or full)
- **Phase 2 must read:** `CHANGELOG.md` lines 1–47 for the v6.8.0 entry structure (Added / Changed / Migration notes / Known Issues / Internal — Agent-2 noted there is NO standalone "Fixed" section in v6.8.0). Quote the Known Issues line verbatim (Agent-3 hypothesis: it names the config-template Autopilot gap and possibly cites the 8 files by glob). `skills/version-bump/SKILL.md` steps 6–11 to confirm: (a) whether a pre-flight check requires `## [6.8.1]` heading in CHANGELOG.md before bumping (Agent-2 hypothesis), (b) whether CHANGELOG update is part of version-bump or must precede it, (c) that only `plugin.json` and `marketplace.json` are updated by version-bump (not CHANGELOG). Confirm the v6.8.1 entry must be authored in the CONTENT commit, before version-bump is run.
- **Rationale:** The CLAUDE.md memory states "content+CHANGELOG in one commit, version-bump as separate commit" — this must match what `skills/version-bump/SKILL.md` actually enforces. If there is a pre-flight guard for the CHANGELOG heading, Phase 4 implementers must know to write the CHANGELOG entry before running `/ceos-agents:version-bump`.

---

## Known Research Leads (carried from scouting)

- **Agent-1 hypothesis (Q7):** `((FAIL++))` when FAIL=0 returns exit code 1 from the arithmetic expression, but under `set -uo pipefail` (no `-e`) this does NOT abort early — meaning the exit-1 leak may only manifest in strict CI wrappers, not in a plain `bash run-tests.sh` invocation. Needs confirmation.
- **Agent-1 finding (Q3):** `state/schema.md` RUN-ID table shows `#123` as a GitHub/Gitea example — the `#` character is the highest-risk char (shell comment, URL fragment, directory-unsafe on some FSes). This should be explicitly named in the regex gate.
- **Agent-2 finding (Q6):** The harness single-scenario path (lines 25–31) correctly exits 1 on failure — any bug is in the FULL-RUN path only. This narrows Phase 2's search.
- **Agent-2 finding (Q3):** `core/fixer-reviewer-loop.md` may document token accumulation only at loop-exit (not per-iteration), which would make crash-mid-iteration unrecoverable at the doc level — meaning the fix adds a per-iteration write requirement AND the test greps for it.
- **Agent-3 finding (Q6 / Item 4):** BusyBox fallback uses `find -mmin +121` (120+1) while primary path computes 120+5=125 — these are DIFFERENT thresholds from the same config value, never reconciled in any prose. The canonical explanation must name both paths and why they differ (BusyBox `-mmin` resolution is 1-minute, so +121 is conservative; inotify-based primary uses +125 for clock skew). Phase 2 must verify this interpretation.
- **Agent-3 finding (Q2 / Item 2):** `core/external-input-sanitizer.md` was cited as a possible existing precedent for input sanitization — its existence (or absence) determines whether the regex gate is the FIRST sanitizer in the plugin or whether there is an existing pattern to follow.
- **Agent-3 finding (Q5 / Item 3):** `docs/guides/autopilot.md` lines 228–290 webhook section may describe payload fields without any JSON-encoding note — if so, this is a USER-FACING documentation gap in addition to the CORE contract gap, both needing fixes.
- **Cross-agent consensus:** All three agents agree the scenario filename prefix for v6.8.1 should follow the PATCH convention (`v681-` prefix, analogous to `v644-diagnostics-hardening.sh`) rather than the minor-version `ac-v68-` prefix. Phase 2 should confirm by reading the first line of `tests/scenarios/v644-diagnostics-hardening.sh`.
