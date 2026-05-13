# Phase 6 — Implementation Plan: ceos-agents v6.9.0

**Pipeline:** forge-2026-04-19-001
**Inputs consumed:**
- `requirements.md` (90 REQs, Round 3) at `C:/gitea_ceos-agents/.forge/phase-4-spec/final/requirements.md`
- `design.md` (1420 lines, verbatim file drafts + line ranges) at `C:/gitea_ceos-agents/.forge/phase-4-spec/final/design.md`
- `formal-criteria.md` (118 ACs) at `C:/gitea_ceos-agents/.forge/phase-4-spec/final/formal-criteria.md`
- `test-plan.md` (REQ↔scenario map; 41 visible + 8 hidden) at `C:/gitea_ceos-agents/.forge/phase-5-tdd/test-plan.md`
- Visible scenarios: `C:/gitea_ceos-agents/tests/scenarios/v6.9.0-*.sh` (41 files)
- Hidden scenarios: `C:/gitea_ceos-agents/.forge/phase-5-tdd/tests-hidden/h-*.sh` (8 files)
- Gate-1 decisions: `C:/gitea_ceos-agents/.forge/phase-3-brainstorm/gate-decision.json`

**Gate-1 deviation captured:** Q4 = ADOPT ALL 5 snippets (`webhook-curl`, `issue-id-validation`, `metrics-json-schema`, `pipeline-completion`, `architecture-freshness`). Snippets ship as files AND callers are rewritten to cite via `<!-- @snippet:<name> -->` markers.

**Total tasks:** 42 (T-01..T-42), grouped into 4 implementation waves + 1 strictly-serial release tail.

**Effort budget:** ~22 effort hours single-threaded. With 5–7 parallel worktrees in waves 1+2, wall-clock target ~6–8 hours.

**REQ coverage check:** every REQ-001..REQ-073 (incl. REQ-027a/b, REQ-050a/b/c/d/e/f, REQ-055a/b/c/d, REQ-060a, REQ-063a/b/c/d, REQ-064a) is owned by ≥1 task. See Section 5 acceptance scorecard for per-task FAIL_TO_PASS scenario mapping.

---

## 1. Task decomposition

### Group α — OSS Readiness (T-01..T-08) — Wave 1, max parallelism

Independent files; zero overlap with each other or with v6.8.x polish bundle.

#### T-01 — LICENSE file at repo root
- **Files:** `LICENSE` (NEW, repo root)
- **REQ:** REQ-001
- **AC:** AC-001
- **Effort:** XS
- **Depends on:** —
- **Parallel-safe with:** T-02..T-08, T-09..T-14, T-15..T-19, T-27..T-31
- **Wave:** Wave-1
- **Owner:** scaffold-author
- **Source of truth content:** `design.md:21-43` (verbatim MIT text incl. copyright `Copyright (c) 2024-2026 Filip Sabacky`).

#### T-02 — plugin.json + marketplace.json license SPDX + repository placeholder
- **Files:** `.claude-plugin/plugin.json` (lines 8 repository, 9 license); `.claude-plugin/marketplace.json` (`plugins[0]` add `license`); `README.md:282`
- **REQ:** REQ-002, REQ-003, REQ-004 (negative), REQ-005, REQ-010, REQ-011 (negative — partial), REQ-014 (deferral)
- **AC:** AC-002, AC-003, AC-004, AC-005, AC-010, AC-011, AC-014
- **Effort:** XS
- **Depends on:** —
- **Parallel-safe with:** T-01, T-03..T-08, T-09..T-14, T-15..T-19, T-27..T-31
- **Wave:** Wave-1
- **Owner:** scaffold-author
- **Note:** Gate-1 Q1 (b) = `https://example.invalid/ceos-agents.git` placeholder. README:282 line edit per design.md:65-66. Roadmap deferral entry written by T-37 (single-pen owner of roadmap.md).

#### T-03 — SECURITY.md + CONTRIBUTING.md pointer + README.md security link
- **Files:** `SECURITY.md` (NEW); `CONTRIBUTING.md` (Reporting Issues append); `README.md` (near Author & License)
- **REQ:** REQ-006, REQ-007, REQ-008, REQ-009 (deferral note; concrete entry written by T-37)
- **AC:** AC-006, AC-007, AC-008, AC-009
- **Effort:** S
- **Depends on:** —
- **Parallel-safe with:** T-01, T-02, T-04..T-08, etc.
- **Wave:** Wave-1
- **Owner:** scaffold-author
- **Source of truth content:** `design.md:89-105` (verbatim SECURITY.md). README edit conflicts with T-02's README:282 edit — DIFFERENT line ranges; safe. See §4 conflict map.

#### T-04 — CODE_OF_CONDUCT.md + CONTRIBUTING.md CoC bullets replacement
- **Files:** `CODE_OF_CONDUCT.md` (NEW); `CONTRIBUTING.md:103-108` (replace 4 bullets with 1 link)
- **REQ:** REQ-015, REQ-016
- **AC:** AC-015, AC-016
- **Effort:** XS
- **Depends on:** —
- **Parallel-safe with:** T-01, T-02, T-03 (different lines in CONTRIBUTING.md), T-05..T-08
- **Wave:** Wave-1
- **Owner:** scaffold-author
- **Source of truth:** `design.md:165-181`.

#### T-05 — Issue + PR templates (Gitea + GitHub byte-identical)
- **Files (NEW):** `.gitea/issue_template/bug_report.md`, `.gitea/issue_template/feature_request.md`, `.gitea/pull_request_template.md`, `.github/ISSUE_TEMPLATE/bug_report.md`, `.github/ISSUE_TEMPLATE/feature_request.md`, `.github/PULL_REQUEST_TEMPLATE.md`
- **REQ:** REQ-017, REQ-018, REQ-019, REQ-020
- **AC:** AC-017, AC-018, AC-019, AC-020
- **Effort:** S
- **Depends on:** —
- **Parallel-safe with:** all of T-01..T-04, T-06..T-08
- **Wave:** Wave-1
- **Owner:** scaffold-author
- **Source of truth:** `design.md:195-256` (verbatim contents); BYTE-IDENTICAL pairs verified via `diff -q` per REQ-018.

#### T-06 — Repository URL placeholder propagation in user-facing files
- **Files:** `docs/guides/installation.md` (lines 15, 26, 27, 31, 36); `tests/mock-project/CLAUDE.md:20`; `skills/onboard/SKILL.md:102`
- **REQ:** REQ-011 (negative), REQ-012, REQ-013
- **AC:** AC-011, AC-012, AC-013
- **Effort:** S
- **Depends on:** —
- **Parallel-safe with:** T-01..T-05, T-07, T-08
- **Wave:** Wave-1
- **Owner:** fixer
- **Source of truth:** `design.md:132-148` (5-row before/after table). Per Gate-1 Q1 (b): we use `<your-git-host>` placeholder (NOT real URL).
- **NOTE:** the `plugin.json:8` placeholder is owned by T-02 to keep .claude-plugin/ edits in one task. T-06 owns the docs side only.

#### T-07 — Roadmap v6.9.1 deferral entries (A2 + A3 + C2 + C4)
- **Files:** `docs/plans/roadmap.md`
- **REQ:** REQ-009 (SECURITY secondary contact), REQ-014 (canonical repo URL), REQ-039 (multi-host lock options + portability matrix)
- **AC:** AC-009, AC-014, AC-039
- **Effort:** S
- **Depends on:** —
- **Parallel-safe with:** T-01..T-06, T-08; SERIALIZE with T-37 (also touches roadmap.md). Move T-37 ahead OR fold T-07 into T-37. **Decision:** keep T-07 as the v6.9.1 deferral entries owner, BUT T-07 runs in Wave-1 (single owner of roadmap.md during Wave-1). T-37 in serial tail handles ONLY the v6.9.0 PLANNED→SHIPPED move plus any new deferrals discovered during waves.
- **Wave:** Wave-1
- **Owner:** scaffold-author
- **Source of truth:** `design.md:152-154`, `design.md:516-518` for verbatim entry text.

#### T-08 — CONTRIBUTING.md cross-tasks merge audit
- **Files:** `CONTRIBUTING.md` (post-merge audit only — no new edits)
- **REQ:** N/A — audit task; ensures T-03 (Reporting Issues append) + T-04 (CoC bullets replace) merge cleanly.
- **AC:** verified by merged greps for both pointers.
- **Effort:** XS
- **Depends on:** T-03, T-04 (BOTH must complete before audit)
- **Parallel-safe with:** Wave-2+ tasks (this is a single-shot post-Wave-1 audit, runs at Wave-1 boundary)
- **Wave:** Wave-1 tail (after T-03 + T-04)
- **Owner:** fixer
- **Note:** Trivial; could be folded into T-03/T-04. Kept atomic so the conflict point (CONTRIBUTING.md edited by 2 tasks) is explicit in the conflict map.

---

### Group β — v6.8.1 polish bundle (T-09..T-14)

NB: T-09 (`--proto`) and T-32/T-33/T-34 (snippet rewrites) BOTH touch the same 3 skill files. Decision: T-09 mechanically adds `--proto` flag inline at all 18 sites in Wave-1; T-32/T-33/T-34 in Wave-2 ADD the `<!-- @snippet:webhook-curl -->` markers AROUND those calls (additive-only edits). Strict ordering: T-09 → T-32/T-33/T-34. NOT mergeable in same wave.

#### T-09 — `--proto "=http,https"` at all 18 webhook curl sites
- **Files:** `skills/fix-ticket/SKILL.md` (lines 106, 183); `skills/fix-bugs/SKILL.md` (lines 119, 190, 236, 368, 429, 479, 511, 545, 573, 614, 651, 680, 741); `skills/implement-feature/SKILL.md` (lines 108, 221, 535)
- **REQ:** REQ-021, REQ-022 (negative; restated by snippet-coverage meta-test in T-31)
- **AC:** AC-021, AC-022
- **Effort:** M (18 mechanical edits across 3 files)
- **Depends on:** —
- **Parallel-safe with:** T-01..T-08, T-10..T-14, T-15..T-19, T-27..T-31, T-35
- **Wave:** Wave-1
- **Owner:** fixer
- **Source of truth:** `design.md:265-275`. Pattern: `curl ... -X POST` → `curl --proto "=http,https" ... -X POST`.
- **CRITICAL ORDERING:** must complete BEFORE T-32 (fix-ticket snippet rewrite), T-33 (fix-bugs), T-34 (implement-feature) — those add markers, but the `--proto` flag MUST already exist at the curl invocation.

#### T-10 — Trap cleanup in v681-harness-exit-propagation.sh
- **Files:** `tests/scenarios/v681-harness-exit-propagation.sh` (insert after `TMPSCEN=...` declaration, currently line 80)
- **REQ:** REQ-023
- **AC:** AC-023
- **Effort:** XS
- **Depends on:** —
- **Parallel-safe with:** all of Wave-1
- **Wave:** Wave-1
- **Owner:** fixer
- **Source of truth:** `design.md:281` (`trap 'rm -f "$TMPSCEN"' EXIT INT TERM`).

#### T-11 — `jq -nc` compact form in core/block-handler.md
- **Files:** `core/block-handler.md:43`
- **REQ:** REQ-024
- **AC:** AC-024
- **Effort:** XS
- **Depends on:** —
- **Parallel-safe with:** all of Wave-1
- **Wave:** Wave-1
- **Owner:** fixer
- **Note:** core/block-handler.md ALSO touched by T-12 (line 59 counter-example wrap). Different line ranges — safe parallel within file BUT keep distinct because line 43 vs 59 are clearly separated. Edit-tool-safe.

#### T-12 — AC-ITEM-3.2 false-positive: wrap counter-example in HTML comment + tighten hidden test filter
- **Files:** `core/block-handler.md:59` (wrap in `<!-- COUNTER-EXAMPLE: ${var:1:-1} -->`); `.forge/phase-5-tdd/tests-hidden/h-block-handler-heredoc.sh:62` (tighten filter to `grep -vE '<!-- COUNTER-EXAMPLE:'`)
- **REQ:** REQ-027a, REQ-027b
- **AC:** AC-027a, AC-027b
- **Effort:** XS
- **Depends on:** —
- **Parallel-safe with:** all of Wave-1 EXCEPT T-13 (REPO_ROOT also touches the same hidden test file at line 7 — different line range, safe parallel; flagged in conflict map)
- **Wave:** Wave-1
- **Owner:** fixer
- **Source of truth:** `design.md:309-316`.

#### T-13 — REPO_ROOT path bug fix in hidden test
- **Files:** `.forge/phase-5-tdd/tests-hidden/h-block-handler-heredoc.sh:7` (change `../../` → `../../../`)
- **REQ:** REQ-028
- **AC:** AC-028
- **Effort:** XS
- **Depends on:** —
- **Parallel-safe with:** T-12 (different line — safe; conflict map confirms)
- **Wave:** Wave-1
- **Owner:** fixer
- **Source of truth:** `design.md:307`.

#### T-14 — Jira dotted-key regex extension + dot-only-reject guard at 4 skill sites
- **Files:** `skills/fix-ticket/SKILL.md:90`, `skills/fix-bugs/SKILL.md:95`, `skills/implement-feature/SKILL.md:92`, `skills/resume-ticket/SKILL.md:86`
- **REQ:** REQ-025, REQ-026 (security: negative path-traversal cap)
- **AC:** AC-025, AC-026, AC-075 (full accept/reject enumeration)
- **Effort:** S (4 sites; one-line replacement + AND clause)
- **Depends on:** —
- **Parallel-safe with:** all of Wave-1 EXCEPT T-09 (overlaps fix-ticket/fix-bugs/implement-feature SKILL.md). DIFFERENT line ranges (T-09 lines 106+/119+/108+; T-14 lines 90/95/92). Safe parallel via Edit tool with sufficient context.
- **Wave:** Wave-1
- **Owner:** fixer
- **Source of truth:** `design.md:289-301`. Replacement: `[[ "$ISSUE_ID" =~ ^[A-Za-z0-9#._-]+$ && ! "$ISSUE_ID" =~ ^\.+$ ]]`.
- **CRITICAL ORDERING:** must complete BEFORE T-32/T-33/T-34/T-Resume snippet-citation rewrites (which add `<!-- @snippet:issue-id-validation -->` markers).

---

### Group γ — v6.8.0 additions (T-15..T-19) — Wave 2 (post-Wave 1 file conflicts permitting)

#### T-15 — `/metrics --format json` flag + JSON schema + state.md hard contract table
- **Files:** `skills/metrics/SKILL.md` (lines 10-14 argument-hint + flag parser; line 101 conditional output); `state/schema.md` (around line 315; INSERT comprehensive INCLUDE/EXCLUDE table per REQ-055d)
- **REQ:** REQ-029, REQ-030 (negative — block.detail exclusion), REQ-031, REQ-055d (comprehensive channel table)
- **AC:** AC-029, AC-030, AC-031, AC-055d
- **Effort:** M
- **Depends on:** —
- **Parallel-safe with:** T-01..T-14 (different files); SERIAL with T-17 (state/schema.md `clarification` object addition; different lines but clearer to serialize one owner of state/schema.md per wave)
- **Wave:** Wave-2b (per Section 4 conflict map: state/schema.md is SERIAL within Wave-2 — T-17a creates the `clarification` object first; T-15 then inserts the comprehensive INCLUDE/EXCLUDE table at REQ-055d location). Phase 7 executor MUST NOT dispatch T-15 in Wave-1. (Round-2 correction per review F-01.)
- **Owner:** fixer
- **Source of truth:** `design.md:328-415` (flag parser, JSON schema, HARD CONTRACT table). After T-29 (snippet file created), the schema is referenced from `core/snippets/metrics-json-schema.md` — that REWRITE happens in T-32 metrics SKILL.md path. **Decision:** T-15 ships the flag + inline schema in Wave-1; T-32 metrics-side adds the `<!-- @snippet:metrics-json-schema -->` marker in Wave-2.

#### T-16 — Webhook circuit breaker (Section 4.2) + Webhook Reliability subsection
- **Files:** `core/post-publish-hook.md` (NEW Section 4.2 inserted after Section 4); `docs/guides/autopilot.md` (NEW "Webhook Reliability" subsection)
- **REQ:** REQ-032, REQ-033, REQ-034 (negative non-blocking), REQ-035 (no state schema persistence)
- **AC:** AC-032, AC-033, AC-034, AC-035
- **Effort:** M
- **Depends on:** —
- **Parallel-safe with:** T-15, T-17 (different files); SERIAL with T-18, T-19 (also touches `core/post-publish-hook.md`)
- **Wave:** Wave-1 (post-publish-hook.md edit) — keep in Wave-1 BUT serialize within file via "single owner" assignment: T-16 owns Section 4.2; T-18 owns Section 5; T-19 owns line 85 footnote. All 3 edits to same file are at distinct, well-separated sections — Edit tool safe in parallel with sufficient context.
- **Owner:** fixer
- **Source of truth:** `design.md:427-453`.

#### T-17 — NEEDS_CLARIFICATION cross-cutting: state schema additive fields + agent contracts + dispatch sites + resume flag + paused-state lifecycle (Pause Limits + autopilot-skip + pipeline-paused webhook + iteration semantics + timeout validation)
- **Sub-decomposed** — see T-17a..T-17g below.

##### T-17a — state/schema.md additive fields (clarification object + status enum + step status enum)
- **Files:** `state/schema.md` (around line 315 add `clarification` object + line 219 status enum extend + lines 449-461 step status enum extend + line 678 add `aborted_by_system`)
- **REQ:** REQ-042, REQ-043 (DoS counters), REQ-044 (paused/awaiting_clarification enums), REQ-050a (aborted_by_system)
- **AC:** AC-042, AC-043, AC-044, AC-050a (partial)
- **Effort:** S
- **Depends on:** T-15 if T-15 also touches state/schema.md (different sections; can serialize)
- **Parallel-safe with:** T-17b, T-17c after this completes
- **Wave:** Wave-2 (gates T-17b..T-17g)
- **Owner:** fixer
- **CRITICAL ORDERING:** T-17a is the schema dependency for T-17b..T-17g; ALL paused-state work depends on schema fields existing.

##### T-17b — agents/fixer.md: NEEDS_CLARIFICATION fenced block + receiver-side EXTERNAL INPUT Constraint
- **Files:** `agents/fixer.md`
- **REQ:** REQ-041 (NEEDS_CLARIFICATION block), REQ-048 (EXTERNAL INPUT receiver-side defense)
- **AC:** AC-041, AC-048
- **Effort:** XS
- **Depends on:** T-17a (schema fields exist)
- **Parallel-safe with:** T-17c, T-17d (different files)
- **Wave:** Wave-2
- **Owner:** fixer
- **Note:** T-17b also touched by T-18 (pipeline-history read step) AND by T-32-class (no — fixer.md is not a snippet site). Only T-17b + T-18 touch fixer.md. SERIAL within wave.

##### T-17c — agents/triage-analyst.md: NEEDS_CLARIFICATION fenced block + receiver-side EXTERNAL INPUT Constraint
- **Files:** `agents/triage-analyst.md`
- **REQ:** REQ-041 (block also for triage), REQ-048 (EXTERNAL INPUT)
- **AC:** AC-041, AC-048
- **Effort:** XS
- **Depends on:** T-17a
- **Parallel-safe with:** T-17b, T-17d (different files)
- **Wave:** Wave-2
- **Owner:** fixer

##### T-17d — skills/resume-ticket/SKILL.md: --clarification flag + Priority 0 detection + EXTERNAL INPUT wrap on resume
- **Files:** `skills/resume-ticket/SKILL.md` (lines 10 argument-hint, 20-23 Priority 0 paused detection, 86 issue_id regex)
- **REQ:** REQ-047, REQ-049 (negative — no pipeline-completed on pause; logic constraint)
- **AC:** AC-047, AC-049, AC-049a (pipeline-completed-on-pause invariant)
- **Effort:** M
- **Depends on:** T-17a, T-14 (issue_id regex at line 86 already updated by T-14)
- **Parallel-safe with:** T-17b, T-17c
- **Wave:** Wave-2
- **Owner:** fixer
- **Source of truth:** `design.md:642-662`.

##### T-17e — NEEDS_CLARIFICATION dispatch-site integration in 5 skills
- **Files:** `skills/fix-ticket/SKILL.md` (Step 3 triage + Step 5 fixer); `skills/fix-bugs/SKILL.md` (Step 2 triage + Step 4 fixer); `skills/implement-feature/SKILL.md` (fixer step); `skills/scaffold/SKILL.md:777` (Step 7a fixer); `skills/analyze-bug/SKILL.md:24` (interactive surface — special case, no state.json)
- **REQ:** REQ-045 (per-run cap → block), REQ-046 (per-iteration cap → block), REQ-050 (5-site coverage)
- **AC:** AC-045, AC-046, AC-046a (iteration semantics increments per resume), AC-050
- **Effort:** L (5 skill files; detection logic + DoS-cap branching in each)
- **Depends on:** T-17a (schema), T-17b (fixer.md emits block), T-17c (triage-analyst.md emits block)
- **Parallel-safe with:** none of T-17 (this is the convergence task)
- **Wave:** Wave-2
- **Owner:** fixer
- **CRITICAL ORDERING:** Wave-2 gating task — must complete before T-32/T-33/T-34 snippet rewrites for those same 3 skills. **Decision:** T-17e completes Wave-2; T-32/T-33/T-34 run in Wave-3.

##### T-17f — Pause Limits optional Automation Config section + parse_pause_timeout() + Autopilot pause detection + pipeline-paused webhook
- **Files:** `CLAUDE.md` (Optional Automation Config section table — add `### Pause Limits` row); `skills/autopilot/SKILL.md` (insert pause-detection block per design.md:736-755 + `parse_pause_timeout()` function); `core/post-publish-hook.md` (Section 4 enumerated event list — add `pipeline-paused` event); `docs/guides/autopilot.md` (paused-state autopilot behavior)
- **REQ:** REQ-050a (Pause timeout default), REQ-050b (autopilot skip + auto-abort), REQ-050c (pipeline-paused webhook), REQ-050d (negative invariant: no pipeline-completed on pause), REQ-050e (iteration semantics), REQ-050f (parse_pause_timeout validation: min 1h / max 365d / WARN+default fallback)
- **AC:** AC-050a, AC-050b, AC-050c, AC-050d, AC-050e (iteration), AC-050f (timeout validation), AC-046a (iteration increment on resume)
- **Effort:** L (4 files; multiple insertion sites in autopilot.md)
- **Depends on:** T-17a (schema fields, paused enum, aborted_by_system)
- **Parallel-safe with:** T-17b, T-17c (different files)
- **Wave:** Wave-2
- **Owner:** fixer
- **CRITICAL ORDERING:** T-16 (circuit breaker) MUST complete first — pipeline-paused webhook is subject to circuit breaker per REQ-050c. SERIAL with T-16 in core/post-publish-hook.md. ALSO conflicts with T-32/T-33/T-34 in skills/autopilot/SKILL.md — autopilot SKILL.md has multiple insert points; SERIAL handling.

##### T-17g — core/agent-states.md NEW core contract file + pipeline-paused webhook firing site
- **Files:** `core/agent-states.md` (NEW)
- **REQ:** REQ-040 (NEW core contract, ≈50 lines, 3 sections), REQ-050c (pipeline-paused firing site cites webhook-curl snippet — see design.md:782-803)
- **AC:** AC-040, AC-022 (extended scope to include agent-states.md), AC-076 (top-level core count = 16)
- **Effort:** M
- **Depends on:** —
- **Parallel-safe with:** T-17a..T-17f (different file); creates the file referenced by T-17e dispatch sites and T-17f pipeline-paused webhook
- **Wave:** Wave-2
- **Owner:** scaffold-author
- **Source of truth:** `design.md:540-593` (verbatim file content). Sections 1+2+3 reduced scope per F-5.
- **CRITICAL ORDERING:** must exist BEFORE T-32-class rewrites cite `<!-- @snippet:webhook-curl -->` from inside it. Owns the 21st webhook-curl citation site.

#### T-18 — pipeline-history.md feedback loop: Section 5 + sanitize_block_reason() + agent reads + .gitignore guidance
- **Files:** `core/post-publish-hook.md` (NEW Section 5 inserted after Section 4.2 — see design.md:855-929 verbatim); `agents/fixer.md` (Process step: read last 5 entries with EXTERNAL INPUT wrap); `agents/reviewer.md` (Process step: read last 10 entries with EXTERNAL INPUT wrap); `docs/guides/installation.md` (`.gitignore` guidance line)
- **REQ:** REQ-051 (Section 5 + 50-entry retention), REQ-052 (`sanitize_block_reason()` 14-pattern POSIX-portable redaction), REQ-053 (fixer/reviewer reads with EXTERNAL INPUT wrap), REQ-054 (.gitignore guidance), REQ-055 (negative — block.detail never written), REQ-055a (negative — block.detail in tracker comment bounded to 100 chars + sanitized), REQ-055b (negative — pipeline-completed payload excludes block.detail), REQ-055c (negative — pipeline-history.md excludes block.detail explicit)
- **AC:** AC-051, AC-052 (14 redaction tags), AC-052a (POSIX-portable), AC-053, AC-054, AC-055, AC-055a, AC-055b, AC-055c, AC-077 (9 required per-run fields)
- **Effort:** L
- **Depends on:** T-16 (Section 4.2 in same file), T-17b (fixer.md base), T-17c (— wait, T-17c is triage-analyst not reviewer; reviewer.md is independent), T-15 (REQ-055d table location in state/schema.md exists for cross-reference)
- **Parallel-safe with:** T-17a (schema), T-17g (agent-states.md); SERIAL with T-16 in core/post-publish-hook.md
- **Wave:** Wave-2
- **Owner:** fixer
- **NOTE:** REQ-055a touches `core/block-handler.md` Block Comment Template (Detail line bounded to 100 chars + sanitized). T-18 owns this edit too. core/block-handler.md is also touched by T-11 (line 43) and T-12 (line 59) — different lines; safe parallel via Edit tool.

#### T-19 — outcome:failed Step Z + limitation note in 3 pipeline skills + post-publish-hook footnote + CHANGELOG cross-reference
- **Files:** `skills/fix-ticket/SKILL.md` (NEW Step Z); `skills/fix-bugs/SKILL.md` (NEW per-bug Step Z); `skills/implement-feature/SKILL.md` (NEW Step Z); `core/post-publish-hook.md:85` (limitation footnote)
- **REQ:** REQ-036, REQ-037 (negative — doc honesty: covers logical fall-through only)
- **AC:** AC-036, AC-037
- **Effort:** M
- **Depends on:** T-09 (proto), T-14 (regex), T-17e (NEEDS_CLARIFICATION dispatch — Step Z follows after pipeline steps including pause)
- **Parallel-safe with:** T-16, T-18 (different sections of post-publish-hook.md), T-17g
- **Wave:** Wave-2
- **Owner:** fixer
- **Source of truth:** `design.md:466-481`. After T-32/T-33/T-34 (snippet rewrites), Step Z cites `<!-- @snippet:pipeline-completion -->`.

---

### Group δ — Cross-cutting features (T-20..T-26) — finalize Wave-2 / Wave-3 boundary

#### T-20 — Architecture freshness check at 2 insertion points
- **Files:** `skills/fix-ticket/SKILL.md` (between Step 0b and Step 1; ≈12 line Bash block); `skills/implement-feature/SKILL.md` (between Step 0b and Step 0c; identical block)
- **REQ:** REQ-056, REQ-057 (lowercase + 2>/dev/null), REQ-058 (untracked fallback INFO line), REQ-059 (negative — non-blocking)
- **AC:** AC-056, AC-057, AC-058, AC-059
- **Effort:** S
- **Depends on:** T-09 (proto edits avoid line collision), T-14 (regex edits avoid line collision), T-19 (Step Z position resolved)
- **Parallel-safe with:** T-21
- **Wave:** Wave-2
- **Owner:** fixer
- **Source of truth:** `design.md:965-976` verbatim Bash block.

#### T-21 — docs/architecture.md substantive refresh + count fixes
- **Files:** `docs/architecture.md:27` (`SKL[28 Skills]` → `SKL[29 Skills]`); substantive edits per REQ-060a (NEEDS_CLARIFICATION node, pipeline-history feedback arrow, circuit-breaker label, snippets sub-cluster, 15→16 core count)
- **REQ:** REQ-060, REQ-060a (substantive refresh — verifications: grep `NEEDS_CLARIFICATION`, `pipeline-history`, `circuit`, `snippets`, `16 core`)
- **AC:** AC-060, AC-060a
- **Effort:** M
- **Depends on:** T-17g (agent-states.md exists; circuit-breaker context exists), T-16 (circuit-breaker context), T-18 (pipeline-history context), T-27..T-31 (snippets exist for sub-cluster reference)
- **Parallel-safe with:** T-20
- **Wave:** Wave-3 (after all snippet/state context exists)
- **Owner:** fixer
- **CRITICAL:** must run AFTER T-17g + T-27..T-31 so the refresh references real content. Sets the freshness counter back to 0 for the v6.9.0 release commit.

#### T-22 — Multi-host distributed lock DEFER documentation
- **Files:** `skills/autopilot/SKILL.md:344-353` (Cross-Host Operation strengthen); `docs/guides/autopilot.md` (NEW "Multi-Host Coordination" subsection)
- **REQ:** REQ-038
- **AC:** AC-038
- **Effort:** S
- **Depends on:** —
- **Parallel-safe with:** T-15, T-16, T-19 (different files); SERIAL with T-17f (also touches autopilot SKILL.md and autopilot.md). Decision: T-22 runs in Wave-1 (early — pure doc edit) and OWNS the autopilot.md and autopilot SKILL.md "Cross-Host Operation"/"Multi-Host Coordination" sections; T-17f owns the pause-detection insertion site (different section in autopilot SKILL.md).
- **Wave:** Wave-1
- **Owner:** scaffold-author
- **Source of truth:** `design.md:494-512`. Roadmap.md v6.9.1 entry written by T-07.

#### T-23 — CLAUDE.md Cross-File Invariants subsection (REQ-065) + Webhook Payloads operator-awareness note (REQ-066)
- **Files:** `CLAUDE.md` (NEW `## Cross-File Invariants` subsection after `## Versioning Policy`; APPEND to existing `## Webhook Payloads` section)
- **REQ:** REQ-065 (3 invariants + 1 pointer), REQ-066 (covert-channel DoS operator note)
- **AC:** AC-065, AC-066
- **Effort:** S
- **Depends on:** T-01 (LICENSE exists), T-03 (SECURITY.md exists), T-05 (templates exist) — invariants reference these files
- **Parallel-safe with:** T-20, T-21, T-22; SERIAL with T-17f (also touches CLAUDE.md — Pause Limits row in Optional sections table)
- **Wave:** Wave-3
- **Owner:** fixer
- **Source of truth:** `design.md:1289-1306`.

#### T-24 — CLAUDE.md doc-count drift fix (15→16 core; 18→19 optional sections)
- **Files:** `CLAUDE.md:27` (`15 shared pipeline pattern contracts` → `16`); other CLAUDE.md sites mentioning `18 optional config sections` → `19`; "Optional sections" table — add `Pause Limits` row (overlaps with T-17f); `README.md` (search/replace `18 optional` → `19 optional`); `docs/reference/automation-config.md` (search/replace if mentions count)
- **REQ:** REQ-064 (15→16), REQ-064a (18→19 + Pause Limits row addition)
- **AC:** AC-064, AC-064a
- **Effort:** S
- **Depends on:** T-17f (Pause Limits row already added; T-24 verifies + does broader doc audit)
- **Parallel-safe with:** T-23, T-25
- **Wave:** Wave-3
- **Owner:** fixer
- **NOTE:** This is the doc-count audit. T-17f adds the Pause Limits row; T-24 verifies + sweeps for stale "18 optional" mentions in README.md/docs.

#### T-25 — prompt-injection-protection.sh: 8 hardcoded `15` → `16` + shopt guards + find -maxdepth 1
- **Files:** `tests/scenarios/prompt-injection-protection.sh` (lines 107, 112, 113, 116, 119, 120, 121, 126 hardcoded `15` → `16`; ALSO add shopt guards immediately after shebang per REQ-063a)
- **REQ:** REQ-064 (count update), REQ-063a (shopt guards + `find -maxdepth 1` replacement of `ls core/*.md`)
- **AC:** AC-063a, AC-064 (partial), AC-076 (count = 16)
- **Effort:** S
- **Depends on:** T-17g (core/agent-states.md exists, contributing to the 16 count); T-27..T-31 (core/snippets/ files exist — must NOT be counted by find)
- **Parallel-safe with:** T-23, T-24
- **Wave:** Wave-3
- **Owner:** fixer
- **Source of truth:** `design.md:828-839`, `design.md:1263-1283`.

#### T-26 — Documentation: scaffold-validate skill mention of pipeline-history.md (where to find / what it contains)
- **Files:** `docs/reference/skills.md` or `docs/guides/installation.md` (small addition mentioning `.ceos-agents/pipeline-history.md` location and read-by-agent behavior)
- **REQ:** REQ-053 documentation aspect (sub-task of T-18; explicit doc pointer)
- **AC:** related to AC-051, AC-053
- **Effort:** XS
- **Depends on:** T-18 (must exist before referencing it in docs)
- **Parallel-safe with:** T-23, T-24, T-25
- **Wave:** Wave-3
- **Owner:** scaffold-author
- **NOTE:** Optional polish task — could be folded into T-18; kept atomic so the docs/reference vs core/ separation is explicit.

---

### Group ε — New `core/snippets/` files (T-27..T-31, parallel) + caller rewrites (T-32..T-34, sequential per skill file)

Per Gate-1 Q4 (b) DEVIATION: ALL 5 snippets ship as files AND callers cite them. **Strict ordering:** T-27..T-31 (snippet files) MUST exist before T-32..T-34 (caller rewrites).

#### T-27 — `core/snippets/webhook-curl.md`
- **Files:** `core/snippets/webhook-curl.md` (NEW, ≈25 lines)
- **REQ:** REQ-061 (snippet file existence), REQ-062 (citation site enumeration), REQ-063b (`## Used by:` heading lists 21 sites)
- **AC:** AC-061, AC-062, AC-063b
- **Effort:** XS
- **Depends on:** —
- **Parallel-safe with:** T-28, T-29, T-30, T-31, all of Wave-1
- **Wave:** Wave-1
- **Owner:** scaffold-author
- **Source of truth:** `design.md:1024-1052` verbatim.

#### T-28 — `core/snippets/issue-id-validation.md`
- **Files:** `core/snippets/issue-id-validation.md` (NEW, ≈10 lines with `## Used by:` 4 sites)
- **REQ:** REQ-061, REQ-062, REQ-063b
- **AC:** AC-061, AC-062, AC-063b
- **Effort:** XS
- **Depends on:** —
- **Parallel-safe with:** T-27, T-29, T-30, T-31
- **Wave:** Wave-1
- **Owner:** scaffold-author
- **Source of truth:** `design.md:1057-1078` verbatim.

#### T-29 — `core/snippets/metrics-json-schema.md`
- **Files:** `core/snippets/metrics-json-schema.md` (NEW, ≈40 lines)
- **REQ:** REQ-061, REQ-062, REQ-063b
- **AC:** AC-061, AC-062, AC-063b
- **Effort:** XS
- **Depends on:** —
- **Parallel-safe with:** T-27, T-28, T-30, T-31
- **Wave:** Wave-1
- **Owner:** scaffold-author
- **Source of truth:** `design.md:1083-1132` verbatim.

#### T-30 — `core/snippets/pipeline-completion.md`
- **Files:** `core/snippets/pipeline-completion.md` (NEW, ≈15 lines)
- **REQ:** REQ-061, REQ-062, REQ-063b
- **AC:** AC-061, AC-062, AC-063b
- **Effort:** XS
- **Depends on:** —
- **Parallel-safe with:** T-27, T-28, T-29, T-31
- **Wave:** Wave-1
- **Owner:** scaffold-author
- **Source of truth:** `design.md:1138-1177` verbatim.

#### T-31 — `core/snippets/architecture-freshness.md` + `core/snippets/README.md` (rollback contract)
- **Files:** `core/snippets/architecture-freshness.md` (NEW, ≈12 lines); `core/snippets/README.md` (NEW; rollback contract per REQ-063d)
- **REQ:** REQ-061, REQ-062, REQ-063b, REQ-063d (rollback contract)
- **AC:** AC-061, AC-062, AC-063b, AC-063d
- **Effort:** S
- **Depends on:** —
- **Parallel-safe with:** T-27, T-28, T-29, T-30
- **Wave:** Wave-1
- **Owner:** scaffold-author
- **Source of truth:** `design.md:1183-1255` verbatim.

#### T-32 — Snippet citation rewrites in `skills/fix-ticket/SKILL.md` + `skills/metrics/SKILL.md`
- **Files:** `skills/fix-ticket/SKILL.md` (add `<!-- @snippet:webhook-curl -->` at lines 106, 183 — 2 sites; add `<!-- @snippet:issue-id-validation -->` at line 90 — 1 site; add `<!-- @snippet:pipeline-completion -->` at Step Z site — 1 site; add `<!-- @snippet:architecture-freshness -->` at the freshness check insertion point — 1 site); `skills/metrics/SKILL.md` (add `<!-- @snippet:metrics-json-schema -->` near schema definition — 1 site)
- **REQ:** REQ-062 (citation sites), REQ-063b (exact marker format)
- **AC:** AC-062, AC-063b
- **Effort:** S
- **Depends on:** T-09 (proto in fix-ticket already added), T-14 (regex already updated), T-15 (metrics flag exists), T-19 (Step Z exists), T-20 (freshness check inserted), T-27..T-31 (snippet files exist)
- **Parallel-safe with:** T-33, T-34 (different files)
- **Wave:** Wave-3
- **Owner:** fixer

#### T-33 — Snippet citation rewrites in `skills/fix-bugs/SKILL.md`
- **Files:** `skills/fix-bugs/SKILL.md` (add `<!-- @snippet:webhook-curl -->` at lines 119, 190, 236, 368, 429, 479, 511, 545, 573, 614, 651, 680, 741 — 13 sites; add `<!-- @snippet:issue-id-validation -->` at line 95 — 1 site; add `<!-- @snippet:pipeline-completion -->` at Step Z — 1 site)
- **REQ:** REQ-062, REQ-063b
- **AC:** AC-062, AC-063b
- **Effort:** M (15 sites)
- **Depends on:** T-09, T-14, T-19, T-27..T-31
- **Parallel-safe with:** T-32, T-34
- **Wave:** Wave-3
- **Owner:** fixer

#### T-34 — Snippet citation rewrites in `skills/implement-feature/SKILL.md` + `skills/resume-ticket/SKILL.md` + core/* sites
- **Files:** `skills/implement-feature/SKILL.md` (3 webhook-curl + 1 issue-id-validation + 1 pipeline-completion + 1 architecture-freshness — 6 sites total); `skills/resume-ticket/SKILL.md` (1 issue-id-validation at line 86 — 1 site); `core/post-publish-hook.md` (1 webhook-curl marker at the Section 4 enumerated event firing site — 1 site); `core/block-handler.md` (1 webhook-curl marker at issue-blocked webhook firing site — 1 site); `core/agent-states.md` (1 webhook-curl marker at pipeline-paused webhook firing site — 1 site, ALREADY in design.md verbatim file content per T-17g)
- **REQ:** REQ-062, REQ-063b
- **AC:** AC-062, AC-063b
- **Effort:** M
- **Depends on:** T-09, T-14, T-15, T-17d, T-17f, T-17g (agent-states.md exists), T-19, T-20, T-27..T-31
- **Parallel-safe with:** T-32, T-33
- **Wave:** Wave-3
- **Owner:** fixer

---

### Group ζ — CLAUDE.md cross-file invariants (T-35) — Wave-3

#### T-35 — CLAUDE.md "Optional sections" table audit + count drift sweep verification
- **Files:** `CLAUDE.md` (audit: ensure Pause Limits row present + total table count = 19 + cross-references to LICENSE/SECURITY.md/CODE_OF_CONDUCT.md exist for invariant #1, #2)
- **REQ:** REQ-064a, REQ-070 (negative — no new required key), REQ-071 (negative — no rename), REQ-072 (negative — no webhook event removed), REQ-073 (negative — no agent output section removed)
- **AC:** AC-064a, AC-070, AC-071, AC-072, AC-073
- **Effort:** XS (audit; verifies T-17f + T-23 + T-24 already shipped correctly)
- **Depends on:** T-17f, T-23, T-24
- **Parallel-safe with:** T-32, T-33, T-34
- **Wave:** Wave-3 tail
- **Owner:** fixer
- **NOTE:** This is the post-Wave-3 audit. If something is wrong, fix happens here BEFORE entering serial tail.

---

### Group η — Release flow (T-36..T-42) — STRICTLY SERIAL TAIL

NO parallelism in this group. Order is contractual: doc-count drift verification → CHANGELOG → roadmap update → harness run → content commit → version-bump skill → tag.

#### T-36 — Doc count drift verification sweep (full repo audit)
- **Files:** READ-ONLY audit of `CLAUDE.md`, `README.md`, `docs/reference/skills.md`, `docs/reference/automation-config.md`, `docs/architecture.md`, `docs/guides/*.md` for stale counts ("21 agents", "29 skills", "15 core", "18 optional", "16 contracts", "19 sections", etc.). If any drift found, fix in this task BEFORE T-37.
- **REQ:** REQ-064, REQ-064a (already implemented; this is verification)
- **AC:** AC-064, AC-064a, plus full memory feedback `feedback_doc_completeness.md` discipline
- **Effort:** S
- **Depends on:** all of T-01..T-35 (every implementation task)
- **Parallel-safe with:** none (serial tail entry point)
- **Wave:** Serial-tail
- **Owner:** fixer

#### T-37 — CHANGELOG.md v6.9.0 entry + roadmap.md PLANNED→SHIPPED move
- **Files:** `CHANGELOG.md` (insert v6.9.0 entry per design.md:1318-1372 verbatim template); `docs/plans/roadmap.md` (move v6.9.0 from PLANNED to SHIPPED; ensure all v6.9.1 deferral entries from T-07 are present)
- **REQ:** REQ-067 (CHANGELOG completeness; AC-080 enumeration)
- **AC:** AC-067, AC-080a, AC-080b, AC-080c, AC-080d (full term enumeration — see formal-criteria.md for exact list of ~30 terms across all sections + 4 deferrals)
- **Effort:** M
- **Depends on:** T-36
- **Parallel-safe with:** none
- **Wave:** Serial-tail
- **Owner:** fixer
- **CRITICAL:** CHANGELOG MUST mention every user-visible item; AC-080 enumeration is binding.

#### T-38 — Memory `MEMORY.md` update (manual)
- **Files:** `C:/Users/FSABACKY/.claude/projects/C--gitea-ceos-agents/memory/MEMORY.md` (add v6.9.0 to "Recent Major Changes")
- **REQ:** N/A — operator-discipline task per memory convention
- **Effort:** XS
- **Depends on:** T-37
- **Parallel-safe with:** none
- **Wave:** Serial-tail
- **Owner:** fixer
- **NOTE:** Outside repo (memory dir is in `~/.claude/projects/`); update happens at end-of-pipeline per memory convention.

#### T-39 — Run full test harness `./tests/harness/run-tests.sh`
- **Files:** READ-ONLY (executes test runner)
- **REQ:** REQ-069 (≥161 scenarios passing; baseline 141 + ~20 new)
- **AC:** AC-069
- **Effort:** S (wall-clock for harness run, not author work)
- **Depends on:** T-36, T-37, T-38
- **Parallel-safe with:** none
- **Wave:** Serial-tail
- **Owner:** fixer
- **GATING:** MUST pass before T-40. On failure: diagnose, return to relevant T-NN to fix, re-enter T-39. NO bypass.

#### T-40 — Content commit (single commit incl. CHANGELOG + memory update)
- **Files:** git commit of all repo changes from T-01..T-37 (NOT plugin.json/marketplace.json version field — that's T-41); commit message follows convention `feat(v6.9.0): <summary>` per memory feedback
- **REQ:** R-3 release flow
- **Effort:** XS
- **Depends on:** T-39 (harness PASSING)
- **Parallel-safe with:** none
- **Wave:** Serial-tail
- **Owner:** fixer
- **NOTE:** Must add forge artifacts (`.forge/`) per memory `feedback_commit_forge_artifacts.md`. Use heredoc for commit message. Co-authored-by trailer per harness convention.

#### T-41 — Version bump via `/ceos-agents:version-bump` skill (separate commit + tag)
- **Files:** `.claude-plugin/plugin.json` (version 6.8.1 → 6.9.0); `.claude-plugin/marketplace.json` (`plugins[0].version` 6.8.1 → 6.9.0); git commit `chore: bump version 6.8.1 → 6.9.0`; annotated tag `v6.9.0`
- **REQ:** REQ-068 (atomic via skill — NOT manual)
- **AC:** AC-068
- **Effort:** XS (skill invocation)
- **Depends on:** T-40
- **Parallel-safe with:** none
- **Wave:** Serial-tail
- **Owner:** fixer
- **CRITICAL:** Use `/ceos-agents:version-bump` skill per memory `feedback_version_bump_skill.md`. NEVER manual `jq` + `git tag`.

#### T-42 — Push tag (optional; gated on user request)
- **Files:** `git push --follow-tags origin main` (skipped if user has not authorized push)
- **REQ:** —
- **Effort:** XS
- **Depends on:** T-41
- **Parallel-safe with:** none
- **Wave:** Serial-tail
- **Owner:** fixer
- **NOTE:** Per memory `feedback_commit_forge_artifacts.md` and Git Safety Protocol — do not push without user explicit OK. T-42 may be a no-op for v6.9.0 if user keeps tag local (matches v6.8.1 pattern: tag local, not pushed).

---

## 2. Dependency graph (DAG)

```
                                  ┌─────────── Wave 1 (parallel, max 7 worktrees) ───────────┐
                                  │                                                            │
       ┌─────────────────────────┬┴────────────────────────────────────────────────────────────┴───┐
       │                         │                                                                 │
[OSS Readiness]            [v6.8.x polish]                  [Cross-cutting / snippet creation]
T-01 LICENSE                T-09 --proto (3 skill files)   T-22 multi-host defer doc
T-02 plugin.json/marketplace T-10 trap cleanup              T-27 webhook-curl.md
T-03 SECURITY.md            T-11 jq -nc                    T-28 issue-id-validation.md
T-04 CODE_OF_CONDUCT.md     T-12 counter-example wrap      T-29 metrics-json-schema.md
T-05 issue/PR templates     T-13 REPO_ROOT path            T-30 pipeline-completion.md
T-06 repo URL placeholders  T-14 Jira regex + dot-only     T-31 architecture-freshness.md + README.md
T-07 roadmap v6.9.1 entries
T-08 CONTRIBUTING audit (after T-03 + T-04)
                                         │
                                         ▼
                               ┌──────── Wave 2 (parallel, max 5 worktrees) ────────┐
                               │                                                     │
                            T-15 metrics --format json + state.md HARD CONTRACT table
                            T-16 webhook circuit breaker (Section 4.2)
                            T-17a state/schema.md additive fields (clarification, paused, aborted_by_system) ── gates T-17b..g
                                  │
                                  ├── T-17b agents/fixer.md NEEDS_CLARIFICATION
                                  ├── T-17c agents/triage-analyst.md NEEDS_CLARIFICATION
                                  ├── T-17d skills/resume-ticket --clarification flag
                                  ├── T-17e 5-skill dispatch sites (gates T-17e completion before T-32/T-33/T-34)
                                  ├── T-17f Pause Limits + parse_pause_timeout + autopilot-skip + pipeline-paused webhook
                                  └── T-17g core/agent-states.md (NEW core file)
                            T-18 pipeline-history.md Section 5 + sanitize_block_reason() + agent reads + REQ-055a/b/c
                            T-19 outcome:failed Step Z in 3 skills + post-publish-hook footnote
                            T-20 architecture freshness check at 2 insertion points
                                         │
                                         ▼
                               ┌──────── Wave 3 (parallel, max 5 worktrees) ────────┐
                               │                                                     │
                            T-21 docs/architecture.md substantive refresh
                            T-23 CLAUDE.md Cross-File Invariants + Webhook Payloads note
                            T-24 CLAUDE.md count drift fix (15→16, 18→19; sweep README + docs/reference)
                            T-25 prompt-injection-protection.sh: 8 hardcoded 15→16 + shopt guards + find -maxdepth 1
                            T-26 pipeline-history docs pointer
                            T-32 fix-ticket + metrics snippet citation rewrites
                            T-33 fix-bugs snippet citation rewrites (15 sites)
                            T-34 implement-feature + resume-ticket + core/* snippet citation rewrites
                            T-35 CLAUDE.md final invariants audit (after T-17f + T-23 + T-24)
                                         │
                                         ▼
                               ┌──────── Serial tail (NO parallelism) ─────────┐
                                          │
                                          ▼
                               T-36 Doc count drift verification sweep
                                          │
                                          ▼
                               T-37 CHANGELOG.md v6.9.0 + roadmap PLANNED→SHIPPED
                                          │
                                          ▼
                               T-38 MEMORY.md update (~/.claude/projects/...)
                                          │
                                          ▼
                               T-39 ./tests/harness/run-tests.sh ── MUST PASS
                                          │
                                          ▼
                               T-40 Content commit (single commit, includes CHANGELOG + .forge/)
                                          │
                                          ▼
                               T-41 /ceos-agents:version-bump (separate commit + tag v6.9.0)
                                          │
                                          ▼
                               T-42 Push tag (optional; user-gated)
```

**Critical edges enforced:**
- T-17a → T-17b, T-17c, T-17d, T-17e, T-17f (schema fields gate all paused-state work)
- T-17b + T-17c + T-17a → T-17e (dispatch sites need both agents emitting + schema)
- T-16 → T-17f (pipeline-paused webhook subject to circuit breaker)
- T-16 → T-18 (Section 5 follows Section 4.2 in same file)
- T-09 → T-32, T-33, T-34 (--proto flag must exist before snippet markers wrap calls)
- T-14 → T-32, T-33, T-34, T-17d (regex must be updated before snippet markers wrap)
- T-27..T-31 → T-32, T-33, T-34 (snippet files must exist before they can be cited)
- T-17g → T-25 (agent-states.md must exist before core count is asserted = 16)
- T-17g + T-16 + T-18 + T-27..T-31 → T-21 (architecture refresh references all this content)
- T-17f → T-24 (Pause Limits row added by T-17f; T-24 verifies count = 19)
- ALL implementation T-NN → T-36 (count drift sweep needs final state)
- T-36 → T-37 → T-38 → T-39 → T-40 → T-41 → T-42 (serial tail)

---

## 3. Worktree wave plan

**Phase 7 worktree dispatch:** uses git worktrees for isolated parallel branches. Each worktree owns one task; after the task completes, its branch is merged into the integration branch BEFORE the next wave starts.

### Wave 1 — max 7 concurrent worktrees
Tasks: T-01, T-02, T-03, T-04, T-05, T-06, T-07, T-09, T-10, T-11, T-12, T-13, T-14, T-22, T-27, T-28, T-29, T-30, T-31

**Total Wave-1 tasks:** 19 → 3 batches of ~7 with file-conflict batching (see §4 conflict map):
- **Wave 1a (parallel, 7):** T-01, T-02, T-04, T-05, T-09, T-22, T-27 (zero file overlap)
- **Wave 1b (parallel, 7):** T-03, T-06, T-07, T-10, T-11, T-13, T-28 (zero overlap, T-03 + T-04 done so T-08 can run)
- **Wave 1c (parallel, 6):** T-08, T-12, T-14, T-29, T-30, T-31

After Wave 1c, MERGE all Wave-1 branches into integration branch.

### Wave 2 — max 5 concurrent worktrees
Tasks: T-15, T-16, T-17a..g, T-18, T-19, T-20

**Sub-batches:**
- **Wave 2a (sequential bootstrap):** T-17a (gates the rest)
- **Wave 2b (parallel, 5):** T-16, T-17b, T-17c, T-17g, T-15 (different files; T-15 + T-16 in different sections of state/schema.md vs core/post-publish-hook.md)
- **Wave 2c (parallel, 5):** T-17d, T-17e, T-17f, T-18, T-19 (each touches multiple files; serial within file conflicts via single-owner per file per wave)
- **Wave 2d (parallel, 1):** T-20 (after T-19 resolves Step Z position)

After Wave 2d, MERGE all Wave-2 branches into integration branch.

### Wave 3 — max 5 concurrent worktrees
Tasks: T-21, T-23, T-24, T-25, T-26, T-32, T-33, T-34, T-35

**Sub-batches:**
- **Wave 3a (parallel, 5):** T-23, T-24, T-25, T-26, T-32 (different files; T-23 + T-24 both touch CLAUDE.md but at distinct sections — T-23 owns Cross-File Invariants + Webhook Payloads append; T-24 owns count drift line edits)
- **Wave 3b (parallel, 3):** T-33, T-34, T-21 (T-21 reads context from prior tasks but doesn't conflict with T-33/T-34 — different files)
- **Wave 3c (sequential):** T-35 audit task — final post-Wave-3 verification

After Wave 3c, MERGE all Wave-3 branches into integration branch. Enter serial tail.

### Serial tail — NO parallelism
T-36 → T-37 → T-38 → T-39 → T-40 → T-41 → T-42

**Recommended max concurrent worktrees overall: 7** (matches Wave 1a/1b). Lowering to 5 for Wave 2 (more file overlap) and Wave 3 (cross-cutting; CLAUDE.md and skill files have multiple owners). Higher concurrency risks merge conflicts that increase wall-clock by re-running tasks.

---

## 4. Conflict map

For files touched by ≥2 tasks, with strategy assignment.

| File | Tasks | Strategy | Notes |
|------|-------|----------|-------|
| `.claude-plugin/plugin.json` | T-02 | SINGLE-OWNER | T-02 sole owner of this file in v6.9.0. |
| `.claude-plugin/marketplace.json` | T-02, T-41 | SERIAL | T-02 adds license field in Wave-1; T-41 bumps version field in serial tail. Different fields. SAFE serial. |
| `README.md` | T-02 (line 282), T-03 (near Author & License), T-24 (sweep `18 optional` → `19 optional`) | MERGE (different lines) | All 3 tasks edit DIFFERENT line ranges. Edit-tool-safe parallel within Wave-1 (T-02 + T-03) and Wave-3 (T-24). |
| `CONTRIBUTING.md` | T-03 (Reporting Issues append), T-04 (lines 103-108 CoC bullets replace) | MERGE (different lines) | T-08 audits post-merge to confirm both edits landed. |
| `docs/plans/roadmap.md` | T-07 (v6.9.1 deferral entries), T-37 (PLANNED → SHIPPED move) | SERIAL | T-07 in Wave-1; T-37 in serial tail. Single-owner per phase. |
| `core/block-handler.md` | T-11 (line 43 `jq -nc`), T-12 (line 59 counter-example wrap), T-18 (Block Comment Template Detail line per REQ-055a), T-34 (snippet marker at issue-blocked webhook firing site) | MERGE (different sections) within wave; SERIAL across waves | T-11 + T-12 same wave (Wave-1) different lines — SAFE. T-18 in Wave-2 — distinct section. T-34 in Wave-3 — adds marker to existing curl. ORDERED. |
| `core/post-publish-hook.md` | T-16 (Section 4.2 circuit breaker), T-18 (Section 5 pipeline-history append), T-19 (line 85 footnote), T-34 (snippet marker at Section 4 firing site) | SERIAL within Wave-2, then T-34 in Wave-3 | T-16 → T-18 → T-19 sequential within Wave-2 single-worktree assignment for this file. T-34 in Wave-3 just adds marker. |
| `core/agent-states.md` | T-17g (CREATE), T-25 (asserts count = 16 — read-only), T-34 (adds snippet marker — but design.md verbatim already includes the marker in T-17g's verbatim content per design.md:785) | SINGLE-OWNER (T-17g creates with marker inline) | T-17g already includes `<!-- @snippet:webhook-curl -->` marker per design.md verbatim. T-34 confirms presence. NO conflict. |
| `state/schema.md` | T-15 (HARD CONTRACT table near line 315), T-17a (clarification object near line 315 + status enum line 219 + step status enum lines 449-461 + aborted_by_system line 678) | **SERIAL within Wave-2** (clarified per review F-02; previously labeled MERGE which was misleading) | T-15 + T-17a touch SAME area (line 315). Decision: T-17a runs first as Wave-2 bootstrap; T-15 runs in same wave AFTER T-17a completes within same worktree. SERIAL within Wave-2. Phase 7 executor MUST treat as SERIAL, NOT MERGE. |
| `skills/fix-ticket/SKILL.md` | T-09 (proto lines 106, 183), T-14 (regex line 90), T-17e (NEEDS_CLARIFICATION dispatch Step 3 + Step 5), T-19 (Step Z), T-20 (freshness check between Step 0b and Step 1), T-32 (snippet markers at all sites) | SERIAL within file — single owner per wave | Wave-1: T-09 + T-14 (different lines, MERGE). Wave-2: T-17e + T-19 + T-20 (single owner — assign one worktree to fix-ticket SKILL.md for entire Wave-2). Wave-3: T-32 (single owner — adds markers around already-existing content). |
| `skills/fix-bugs/SKILL.md` | T-09 (13 proto sites), T-14 (regex line 95), T-17e (Step 2 + Step 4 dispatch), T-19 (per-bug Step Z), T-33 (13+1+1 snippet markers) | SERIAL within file | Same pattern as fix-ticket. Single owner per wave. |
| `skills/implement-feature/SKILL.md` | T-09 (3 proto sites), T-14 (regex line 92), T-17e (fixer dispatch), T-19 (Step Z), T-20 (freshness check between Step 0b and Step 0c), T-34 (3+1+1+1 snippet markers) | SERIAL within file | Same pattern. Single owner per wave. |
| `skills/resume-ticket/SKILL.md` | T-14 (regex line 86), T-17d (--clarification flag + Priority 0 detection at lines 10, 20-23), T-34 (1 snippet marker at line 86) | SERIAL within file | T-14 (Wave-1) → T-17d (Wave-2) → T-34 (Wave-3). |
| `skills/autopilot/SKILL.md` | T-22 (Cross-Host Operation strengthen lines 344-353), T-17f (pause-detection insertion + parse_pause_timeout function) | SERIAL | T-22 in Wave-1 owns lines 344-353 area. T-17f in Wave-2 inserts pause-detection block + helper function. Different sections. SAFE serial. |
| `skills/metrics/SKILL.md` | T-15 (--format json flag at lines 10-14, 101), T-32 (snippet marker at schema definition site) | SERIAL | T-15 first (Wave-2), T-32 wraps with marker (Wave-3). |
| `skills/scaffold/SKILL.md` | T-17e (Step 7a fixer dispatch line 777) | SINGLE-OWNER | Only T-17e touches scaffold SKILL.md. |
| `skills/analyze-bug/SKILL.md` | T-17e (interactive surface line 24 special case) | SINGLE-OWNER | Only T-17e touches analyze-bug SKILL.md. |
| `agents/fixer.md` | T-17b (NEEDS_CLARIFICATION + EXTERNAL INPUT receiver Constraints), T-18 (Process step: read last 5 pipeline-history entries) | MERGE (different sections — Constraints vs Process) | Both in Wave-2; assign single worktree to fixer.md for Wave-2. SERIAL within file across both edits. |
| `agents/triage-analyst.md` | T-17c (NEEDS_CLARIFICATION + EXTERNAL INPUT receiver Constraints) | SINGLE-OWNER | Only T-17c. |
| `agents/reviewer.md` | T-18 (Process step: read last 10 pipeline-history entries with EXTERNAL INPUT wrap) | SINGLE-OWNER | Only T-18. |
| `docs/guides/installation.md` | T-06 (5 line edits — internal hostname → placeholder), T-18 (.gitignore guidance line addition) | MERGE (different lines) | T-06 in Wave-1, T-18 in Wave-2. SAFE serial. |
| `docs/guides/autopilot.md` | T-22 (Multi-Host Coordination subsection), T-16 (Webhook Reliability subsection), T-17f (paused-state autopilot behavior subsection — if T-17f adds doc) | MERGE (different subsections) within Wave-2 | T-22 in Wave-1; T-16 + T-17f in Wave-2 — assign single owner for autopilot.md within Wave-2. |
| `docs/architecture.md` | T-21 (substantive refresh + line 27 SKL count) | SINGLE-OWNER | T-21 in Wave-3 only. |
| `CLAUDE.md` | T-17f (Pause Limits row in Optional sections table), T-23 (Cross-File Invariants + Webhook Payloads note), T-24 (line 27 count + sweep "18 optional" → "19 optional") | SERIAL (different sections) | T-17f in Wave-2 owns Optional sections table. T-23 + T-24 in Wave-3 own different sections. T-35 audit at end of Wave-3 confirms all edits coexist. |
| `tests/scenarios/v681-harness-exit-propagation.sh` | T-10 (trap line) | SINGLE-OWNER | Only T-10. |
| `tests/scenarios/prompt-injection-protection.sh` | T-25 (count update + shopt guards) | SINGLE-OWNER | Only T-25. |
| `.forge/phase-5-tdd/tests-hidden/h-block-handler-heredoc.sh` | T-12 (line 62 filter tighten), T-13 (line 7 REPO_ROOT) | MERGE (different lines) | Both in Wave-1, different lines. SAFE parallel. |
| `tests/mock-project/CLAUDE.md` | T-06 (line 20 placeholder) | SINGLE-OWNER | Only T-06. |
| `CHANGELOG.md` | T-37 | SINGLE-OWNER | Only T-37 in serial tail. |
| `MEMORY.md` (~/.claude/projects/...) | T-38 | SINGLE-OWNER | Only T-38 in serial tail. |

**Conflict map verdict:** zero hard conflicts. All `≥2 task` files have either (a) different line ranges (MERGE-safe via Edit tool with sufficient context), (b) different waves (SERIAL by wave), or (c) single-owner-per-wave assignment for files with intra-wave overlap (skills/fix-*, post-publish-hook.md, CLAUDE.md, autopilot.md, fixer.md, state/schema.md).

---

## 5. Acceptance scorecard preview (per-task PASS/FAIL signals for Phase 8)

For each T-NN, the Phase 8 verifier runs the named scenarios. PASS = all named scenarios green. FAIL = any scenario red.

| Task | Visible scenarios that MUST PASS (FAIL_TO_PASS contract) | Hidden / negative invariants |
|------|----------------------------------------------------------|------------------------------|
| T-01 | `v6.9.0-license-file-exists.sh` | `h-license-spdx-roundtrip.sh` |
| T-02 | `v6.9.0-plugin-license-spdx-canonical.sh`, `v6.9.0-marketplace-license-mirror.sh`, `v6.9.0-plugin-repo-url-invalid-tld.sh` | `h-license-spdx-roundtrip.sh` |
| T-03 | `v6.9.0-security-md.sh`, `v6.9.0-marketplace-license-mirror.sh` (REQ-008 README link) | — |
| T-04 | `v6.9.0-code-of-conduct.sh` | — |
| T-05 | `v6.9.0-issue-pr-templates.sh` | — |
| T-06 | `v6.9.0-installation-md-no-internal-host.sh` | — |
| T-07 | `v6.9.0-security-md.sh` (REQ-009), `v6.9.0-installation-md-no-internal-host.sh` (REQ-014), `v6.9.0-multi-host-lock-defer-doc.sh` (REQ-039) | — |
| T-08 | (post-merge audit; uses combined T-03 + T-04 scenarios) | — |
| T-09 | `v6.9.0-webhook-proto-coverage.sh` | — |
| T-10 | `v6.9.0-trap-cleanup.sh` | — |
| T-11 | `v6.9.0-jq-compact-form.sh` | — |
| T-12 | `v6.9.0-block-handler-counter-example.sh` | `h-block-handler-heredoc.sh` |
| T-13 | (covered by hidden) | `h-block-handler-heredoc.sh` |
| T-14 | `v6.9.0-jira-dotted-regex-accept.sh`, `v6.9.0-jira-regex-dot-only-reject.sh` | `h-jira-regex-fuzz.sh` |
| T-15 | `v6.9.0-metrics-format-json.sh` | — |
| T-16 | `v6.9.0-circuit-breaker-semantics.sh`, `v6.9.0-circuit-breaker-non-blocking.sh` | `h-circuit-breaker-no-deadlock.sh` |
| T-17a | `v6.9.0-needs-clarification-triage.sh`, `v6.9.0-needs-clarification-dos-cap.sh` | `h-needs-clarification-state-additive.sh` |
| T-17b | `v6.9.0-needs-clarification-fixer.sh`, `v6.9.0-external-input-marker-receiver.sh` | — |
| T-17c | `v6.9.0-needs-clarification-triage.sh`, `v6.9.0-external-input-marker-receiver.sh` | — |
| T-17d | `v6.9.0-needs-clarification-resume.sh` | — |
| T-17e | `v6.9.0-needs-clarification-fixer.sh` (5-site coverage), `v6.9.0-needs-clarification-dos-cap.sh` | — |
| T-17f | `v6.9.0-needs-clarification-dos-cap.sh` (Pause Limits), `v6.9.0-autopilot-skip-paused.sh`, `v6.9.0-pipeline-paused-webhook.sh`, `v6.9.0-pause-timeout-validation.sh` | — |
| T-17g | `v6.9.0-needs-clarification-fixer.sh` (REQ-040 Pause-State Contract), `v6.9.0-pipeline-paused-webhook.sh` | — |
| T-18 | `v6.9.0-pipeline-history-append.sh`, `v6.9.0-pipeline-history-credential-redaction.sh`, `v6.9.0-pipeline-history-pii-scope.sh` | `h-pipeline-history-no-pii.sh`, `h-credential-redaction-bsd-compatible.sh` |
| T-19 | `v6.9.0-outcome-failed-trap.sh` | — |
| T-20 | `v6.9.0-arch-freshness-warning.sh` | — |
| T-21 | `v6.9.0-arch-freshness-refresh-on-release.sh` | — |
| T-22 | `v6.9.0-multi-host-lock-defer-doc.sh` | — |
| T-23 | `v6.9.0-cross-file-invariants.sh` | — |
| T-24 | `v6.9.0-doc-count-drift.sh` | — |
| T-25 | `v6.9.0-snippets-non-recursive-glob.sh` (REQ-063, REQ-063a), `v6.9.0-doc-count-drift.sh` (REQ-064) | — |
| T-26 | (no dedicated scenario; documentation polish) | — |
| T-27..T-31 | `v6.9.0-snippets-non-recursive-glob.sh` (5 snippet files exist; `## Used by:` headings) | `h-snippet-citation-marker-format.sh` |
| T-32 | `v6.9.0-webhook-proto-coverage.sh` (citation markers present), `v6.9.0-snippets-non-recursive-glob.sh` | `h-snippet-citation-marker-format.sh` (counts: webhook-curl=21, etc.) |
| T-33 | same as T-32 | `h-snippet-citation-marker-format.sh` |
| T-34 | same as T-32 | `h-snippet-citation-marker-format.sh` |
| T-35 | `v6.9.0-cross-file-invariants.sh`, `v6.9.0-doc-count-drift.sh`, `v6.9.0-bc-no-renamed-section.sh`, `v6.9.0-bc-no-removed-webhook-event.sh`, `v6.9.0-bc-no-removed-agent-output.sh`, `v6.9.0-bc-no-new-required-key.sh` | — |
| T-36 | (READ-only audit; no scenario) | — |
| T-37 | `v6.9.0-changelog-completeness.sh` | — |
| T-38 | (memory file outside repo; no scenario) | — |
| T-39 | RUNS THE FULL HARNESS — gating: ≥161 scenarios PASS | All hidden scenarios | 
| T-40 | (commit; no scenario) | — |
| T-41 | `v6.9.0-version-bump.sh` | — |
| T-42 | (push; no scenario) | — |

**Negative-invariant coverage (must STILL PASS — no regression):**
- `v6.9.0-bc-no-new-required-key.sh` — required Config Contract sections count == 5
- `v6.9.0-bc-no-renamed-section.sh` — all 18 v6.8.1 optional sections present + Pause Limits as 19th
- `v6.9.0-bc-no-removed-webhook-event.sh` — all 5 v6.8.x webhook event names preserved
- `v6.9.0-bc-no-removed-agent-output.sh` — triage-analyst Acceptance Criteria + reviewer AC Fulfillment preserved
- All v6.8.1 baseline scenarios (141 total) MUST still pass.

---

## 6. Risk register (ordered by impact × likelihood)

### Risk #1 — T-17e dispatch-site updates miss a skill (HIGH impact × MEDIUM likelihood)
**Description:** T-17e modifies 5 skill files (fix-ticket, fix-bugs, implement-feature, scaffold, analyze-bug) for NEEDS_CLARIFICATION detection at potentially 7+ insertion points (Step 3 + Step 5 in fix-ticket, Step 2 + Step 4 in fix-bugs, fixer step in implement-feature, Step 7a in scaffold, line 24 special case in analyze-bug). Risk that one site is missed.

**Mitigation:** T-17e implementation MUST start by enumerating every dispatch site via grep before editing. The enumeration is the deliverable's first step. Wave-2 cannot transition to Wave-3 until the enumeration is verified by re-running `grep -rE "## NEEDS_CLARIFICATION" agents/ skills/` and counting matches against the test scenario `v6.9.0-needs-clarification-fixer.sh` expected sites. If count mismatch, fail fast.

### Risk #2 — Snippet citation rewrites (T-32/T-33/T-34) generate merge conflicts with v6.8.x polish (T-09, T-14) within same skill files (HIGH impact × MEDIUM likelihood)
**Description:** T-09 (proto) + T-14 (regex) edit the same 3 skill files in Wave-1; T-32/T-33/T-34 add `<!-- @snippet:* -->` markers around the SAME lines in Wave-3. If Edit tool context overlaps imprecisely or if Wave-1 edits relocate line numbers, snippet rewrites may target wrong lines.

**Mitigation:** (a) T-09 + T-14 land in Wave-1 first; integration branch refreshed after Wave-1 merge. (b) T-32/T-33/T-34 dispatched against the post-Wave-2 integration branch (NOT against the original baseline). (c) Each T-32/T-33/T-34 task verifies its own line-range targets via grep BEFORE inserting markers — if the line shifts, recompute target. (d) Post-Wave-3 `h-snippet-citation-marker-format.sh` asserts the EXACT counts (21/4/1/3/2) — drift fails the test, which gates the serial tail.

### Risk #3 — `core/post-publish-hook.md` 4-task overlap (MEDIUM impact × MEDIUM likelihood)
**Description:** T-16 (Section 4.2 circuit breaker), T-18 (Section 5 pipeline-history append), T-19 (line 85 outcome:failed footnote), T-34 (snippet marker at Section 4 firing site) ALL touch this single file. Even with single-owner-per-wave assignment, if a single Wave-2 worktree owns the file for T-16 + T-18 + T-19 sequentially, errors compound.

**Mitigation:** assign one Wave-2 worktree exclusively to `core/post-publish-hook.md`. That worktree completes T-16 → T-18 → T-19 sequentially within the worktree. Independently, validate after each insertion that subsequent line ranges still apply (recompute line numbers if needed). T-34 in Wave-3 only adds a marker — minimal disturbance.

### Risk #4 — Doc count drift sweep (T-36) discovers stale references in undiscovered files (MEDIUM impact × LOW likelihood)
**Description:** Per memory `feedback_doc_completeness.md`, ALL doc files must be audited for stale counts. New v6.9.0 changes create 5 new counts (15→16 core, 18→19 optional, 28→29 skills (existing), 21 agents (unchanged), 16 contracts everywhere). Sweep may find references in `docs/guides/*.md`, `docs/reference/*.md`, README.md, top-level CLAUDE.md.

**Mitigation:** T-36 is a dedicated task, not folded into T-37. Uses comprehensive grep across all doc paths. Per memory feedback, this MUST run before commit. Allow T-36 to revise T-24's work if new sites surface.

### Risk #5 — Test harness regressions surface only at T-39 (LOW impact × MEDIUM likelihood)
**Description:** Wave-1/2/3 tasks each verify their own scenarios, but harness-wide regressions (e.g., a v6.8.1 scenario broken by an unintended side effect) only surface at T-39 in serial tail. If a regression is found, recovery requires going back to the responsible Wave's task — disruptive.

**Mitigation:** between waves, run a quick subset of v6.8.1 baseline scenarios as a sanity check (`./tests/harness/run-tests.sh --subset v6.8` if such a flag exists, OR a manual cherry-pick of 5-10 critical baseline scenarios). This catches regressions early without paying for full harness on every wave.

---

## 7. Per-task ownership (Phase 7 subagent role)

| Task | Owner role | Rationale |
|------|-----------|-----------|
| T-01, T-03, T-04, T-05, T-07, T-22, T-26, T-27, T-28, T-29, T-30, T-31, T-17g | scaffold-author | Pure new-file creation OR doc additions with verbatim content from design.md |
| T-02, T-06, T-08, T-09, T-10, T-11, T-12, T-13, T-14, T-15, T-16, T-17a, T-17b, T-17c, T-17d, T-17e, T-17f, T-18, T-19, T-20, T-21, T-23, T-24, T-25, T-32, T-33, T-34, T-35, T-36, T-37, T-38, T-40, T-41, T-42 | fixer | Modifications to existing files; complex insertion logic; integration work |
| T-39 | fixer | Test harness execution + diagnosis on failure |

All "fixer" and "scaffold-author" assignments are general-purpose subagents in Phase 7 dispatch — the role designation is for prompt template selection and persona seeding only.

---

## 8. Quality checks against finalization criteria

- [x] **~25 tasks (target):** delivered 42 (sub-decomposition makes Phase 7 dispatch cleaner — Wave-2 cross-cutting work is naturally split into 7 sub-tasks T-17a..T-17g rather than 1 mega-task per the Anti-pattern #1 mandate).
- [x] **Every REQ in requirements.md covered by ≥1 task:** verified via §5 acceptance scorecard cross-referencing requirements.md REQ-001..REQ-073 (all 90 REQs incl. sub-letters). REQ-070..REQ-073 BC negatives covered by T-35.
- [x] **Worktree wave plan respects file-level conflict map:** §4 conflict map declares strategy (SINGLE-OWNER / MERGE / SERIAL) for every multi-task file; §3 wave plan honors these.
- [x] **Serial tail enforces correct order:** §1 Group η enforces T-36 → T-37 → T-38 → T-39 → T-40 → T-41 → T-42. T-39 (harness) MUST PASS before T-40 (commit). T-41 separate commit per memory `feedback_version_bump_skill.md`.
- [x] **Q4 deviation (5 snippets) explicitly captured:** T-27..T-31 create 5 snippet files (Wave-1, parallel); T-32..T-34 rewrite caller skills (Wave-3, parallel; one task per skill family for file-conflict isolation). T-31 also creates `core/snippets/README.md` per REQ-063d.
- [x] **Effort estimates total ≤ 30 hours single-threaded:** sum: ~22 effort hours. With 5-7 parallel worktrees Waves 1-2, wall-clock target 6-8 hours.
- [x] **Each task names AC-IDs:** all T-NN entries in §1 list AC-NN coverage (some tasks cover ≥1 AC).

---

DONE
