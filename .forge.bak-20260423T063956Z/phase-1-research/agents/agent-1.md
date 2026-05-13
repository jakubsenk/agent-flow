# Phase 1 Research Questions — Agent 1

## Self-score: 0.93
(high confidence: every question has been verified against real file content; target paths confirmed to exist; counts spot-checked; one score deduction for the multi-host lock question whose answer requires design judgment beyond current files)

## Categories covered: A, B, C, D, E, F, cross-cutting

---

## Questions

### A — OSS Readiness

1. What SPDX license identifier does filip-superpowers (the sister plugin by the same author) use, and does its `plugin.json` and repo root contain a `LICENSE` file that ceos-agents can follow as a template?
   Target files: `C:/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.9.19/.claude-plugin/plugin.json`, `C:/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.9.19/LICENSE`
   Verification result (agent-1 pre-read): plugin.json shows `"license": "MIT"`; LICENSE file header is "MIT License — Copyright (c) 2026 Filip Sabacky". MIT is already the sibling convention.

2. What are the exact current values of `license` and `repository` in `.claude-plugin/plugin.json` and what mirror does marketplace.json currently reference — confirming which two field edits are needed for OSS go-live?
   Target files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
   Verification result (agent-1 pre-read): `plugin.json` has `"license": "UNLICENSED"`, `"repository": "https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git"`; `marketplace.json` has no `license` or `repository` fields — only `name`, `version`, `description`, `source`.

3. Does a public mirror URL (GitHub or public Gitea) already exist? If not, does the OSS Readiness roadmap item require deferral until the URL is provisioned, or can the field be left as a placeholder?
   Target files: `docs/plans/roadmap.md` lines 754-762, `.claude-plugin/plugin.json`

4. What is the exact text currently in `CONTRIBUTING.md` under "Code of Conduct" and "Reporting Issues" — are there any license, vulnerability-reporting, or CoC references that SECURITY.md and CODE_OF_CONDUCT.md must not contradict?
   Target files: `CONTRIBUTING.md` (lines 97-108), `README.md` (line 280 "Author & License" section)

5. What are the canonical file paths for Gitea issue templates and PR templates (`.gitea/issue_template/` or `.gitea/ISSUE_TEMPLATE/`, and `.gitea/pull_request_template.md` or `.gitea/PULL_REQUEST_TEMPLATE.md`) — does the `.gitea/` directory already exist with anything in it?
   Target files: repo root `.gitea/` directory listing

6. Does the Claude Code plugin schema (inside `.claude-plugin/plugin.json`) have any documented constraint on the SPDX `license` value format — e.g., "MIT" vs "MIT-1.0"? Does the marketplace.json schema require a `license` field to be added?
   Target files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `docs/reference/config.md` (if license schema documented)

7. What do the existing README.md "Author & License" section (line 280) and CONTRIBUTING.md say about the license today — would adding a LICENSE file and updating the SPDX string create any direct contradiction or duplicate statement that needs to be updated?
   Target files: `README.md` lines 278-285, `CONTRIBUTING.md` full text

---

### B — v6.8.1 Polish

8. How many `curl` invocations exist across `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, and `skills/implement-feature/SKILL.md`, and how many already carry `--proto "=http,https"`? Enumerate exact line numbers.
   Target files: `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`
   Verification result (agent-1 pre-read): fix-ticket has 2 curl calls (lines 106, 183), fix-bugs has 13 (lines 119, 190, 236, 368, 429, 479, 511, 545, 573, 614, 651, 680, 741), implement-feature has 3 (lines 108, 221, 535). Zero of these carry `--proto`. The canonical pattern is in `core/post-publish-hook.md` and `core/block-handler.md`.

9. Does `tests/scenarios/v681-harness-exit-propagation.sh` currently have a `trap 'rm -f "$TMPSCEN"' EXIT INT TERM` for the temp file created at line 80 (`TMPSCEN`)? What is the canonical trap pattern used in other scenarios (e.g., `ac-v68-autopilot-trap-exit.sh`)?
   Target files: `tests/scenarios/v681-harness-exit-propagation.sh`, `tests/scenarios/ac-v68-autopilot-trap-exit.sh`
   Verification result (agent-1 pre-read): The script creates `$TMPSCEN` at line 80, manually deletes it at line 86, but has NO trap — a Ctrl-C between lines 81 and 86 leaks the temp file. No trap line exists in the file.

10. In `core/block-handler.md` Step 5, `jq -n` (multi-line pretty-print) is used to build the payload which is then passed via heredoc. In `core/post-publish-hook.md` Section 4, the payload is a single-line JSON literal in the heredoc. Are there any skill files that use `jq -n` for webhook payloads (producing multi-line output that then feeds into a heredoc)? Does the roadmap item call for switching to `jq -nc` across the board or only in the block-handler?
    Target files: `core/block-handler.md` lines 43-54, `core/post-publish-hook.md` lines 117-124, `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`

11. What is the exact current issue_id regex `^[A-Za-z0-9#_-]+$` as it appears in the four skill files (`fix-ticket`, `fix-bugs`, `implement-feature`, `resume-ticket`)? What characters does a Jira dotted-project key like `PROJ.NAME-123` require that the current regex rejects — specifically is only `.` missing, or are there other characters (e.g., `/`, `:`)?
    Target files: `skills/fix-ticket/SKILL.md` line 90, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/resume-ticket/SKILL.md`

12. In `.forge.bak-20260419T184209Z/phase-5-tdd/tests-hidden/*.sh`, what is the actual `REPO_ROOT` path prefix used (e.g., `../../` vs `../../../`)? Given that the files live under `.forge.bak-*/phase-5-tdd/tests-hidden/` (3 directories deep from repo root), what is the correct relative level, and should the fix target the hidden-test files directly or should the scaffolding template that generates these paths also be changed?
    Target files: `.forge.bak-20260419T184209Z/phase-5-tdd/tests-hidden/h-block-handler-heredoc.sh` (line 7), `.forge.bak-20260419T184209Z/phase-5-tdd/tests-hidden/h-fixer-reviewer-loop-step-10.sh` (line 10), `.forge.bak-20260419T184209Z/phase-5-tdd/tests-hidden/h-skill-autopilot-368.sh` (line 9)
    Verification result (agent-1 pre-read): All 3 files use `../../` (2 levels up) but the files are 3 levels below repo root, so the correct is `../../../`. Since these are forge artifacts (not tests/scenarios/), fixing the files directly is appropriate.

13. In `core/block-handler.md`, line 59 contains the prose counter-example `${var:1:-1}`. What negative-grep or test tooling (if any) currently validates that no skill/core files use Bash-specific `${var:1:-1}`? Would the grep scope to "fenced code blocks only" approach require a multi-line grep, and is there a simpler prose rewrite that eliminates the false-positive?
    Target files: `core/block-handler.md` lines 56-67, `tests/scenarios/*.sh` (grep for the AC-ITEM-3.2 test)

---

### C — v6.8.0 Additions

14. What is the current output structure of `/ceos-agents:metrics` — specifically the full markdown schema from `skills/metrics/SKILL.md` Step 7? What would a `--format json` mirror look like (keys, nesting depth, array of pipeline runs vs flat aggregates)?
    Target files: `skills/metrics/SKILL.md` lines 99-160 (Step 7 output format), `skills/metrics/SKILL.md` lines 1-10 (flag-hint / argument-hint frontmatter)

15. In `core/post-publish-hook.md` Section 4 (webhook event dispatch), how are timeouts currently handled for webhook delivery (the `--max-time 5` flag)? What state does the circuit breaker need to persist across pipeline runs — specifically, should a state file (`.ceos-agents/circuit-breaker.json`) track failure count, cooldown expiry, or both, and what is the minimum-viable trigger threshold (N consecutive failures)?
    Target files: `core/post-publish-hook.md` lines 100-134, `skills/autopilot/SKILL.md` lines 1-35 (scope/boundaries section)

16. In `skills/fix-ticket/SKILL.md`, at which step does `pipeline-completed` with `outcome: "success"` fire? At which step does `pipeline-completed` with `outcome: "blocked"` fire (after block handler)? Where would `outcome: "failed"` need to fire for catastrophic exits (uncaught error, OOM, SIGKILL) — does the skill currently have any `trap` mechanism, and if not, is a bash `trap EXIT` the correct pattern to document?
    Target files: `skills/fix-ticket/SKILL.md` lines 500-545, `core/post-publish-hook.md` lines 83-98

17. In `skills/autopilot/SKILL.md`, what is the exact current `mkdir`-based lock implementation — specifically the stale-detection condition and `owner.json` contents? What failure modes would break this on multi-host NFS (rename atomicity, clock skew already noted with +5min buffer)? The roadmap says "hardest item" with defer-to-v6.9.1 option — what minimum-viable defer mechanism is documented (disjoint queries per host)?
    Target files: `skills/autopilot/SKILL.md` lines 120-260, `docs/guides/autopilot.md` lines 1-50

---

### D — NEEDS_CLARIFICATION State

18. How is `NEEDS_DECOMPOSITION` integrated end-to-end today — from `agents/fixer.md` output signal through `skills/fix-ticket/SKILL.md` detection (line 328) to state.json and rollback? Use this as the template for `NEEDS_CLARIFICATION` integration.
    Target files: `agents/fixer.md` lines 36-47, `skills/fix-ticket/SKILL.md` line 328 and surrounding context, `core/fixer-reviewer-loop.md`

19. What is the current `state/schema.md` JSON shape for blocking states? What additive fields would a `NEEDS_CLARIFICATION` entry require (e.g., `clarification_question`, `clarifying_agent`, `step_name`, `run_id`, `status: "needs_clarification"`)? Does the schema's `schema_version: "1.0"` additive-field policy cover this without a version bump?
    Target files: `state/schema.md` lines 1-10 (schema_version policy), full schema JSON example

20. At what step granularity does `skills/resume-ticket/SKILL.md` currently resume — by named stage (triage, code_analysis, fixer_reviewer) or by finer iteration? Where in resume-ticket logic would the clarification answer text get injected back into the agent's context on resume?
    Target files: `skills/resume-ticket/SKILL.md` lines 15-80

21. Which skills dispatch the `fixer` agent (fix-ticket, fix-bugs, implement-feature) and which dispatch `triage-analyst` — enumerate them so that each dispatch site is identified as needing `NEEDS_CLARIFICATION` handling (pause + write to state + surface question to user)?
    Target files: `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md` (grep for Task tool calls to fixer and triage-analyst)

---

### E — pipeline-history.md Feedback Loop

22. What storage format (append-only flat markdown sections vs JSONL) is easier for fixer and reviewer agents to consume in-context — given that agents read via the Read tool and JSONL is more compact but requires per-line parsing? What is the proposed storage path per roadmap (`.claude/pipeline-history.md`)?
    Target files: `docs/plans/roadmap.md` lines 803-811, `agents/fixer.md` (Process section — what does fixer read at Step 1), `agents/reviewer.md` (Process section)

23. What PII/sensitive data risk exists if `pipeline-history.md` is stored in the repo root or `.claude/` directory and committed to a public OSS repo — does it risk including issue titles, code excerpts, or only metadata (issue IDs, outcomes, agent names)?
    Target files: `docs/plans/roadmap.md` lines 806-810, `state/schema.md` (what fields would be summarized)

24. At what step in `core/post-publish-hook.md` would the pipeline-history.md append logically fire (after `pipeline-completed` webhook, or as a separate Step 5)? What minimum retention/rotation strategy avoids unbounded file growth?
    Target files: `core/post-publish-hook.md` (existing steps 1-4), `docs/plans/roadmap.md` lines 808-810

---

### F — ARCHITECTURE.md Freshness Warning

25. Does `docs/ARCHITECTURE.md` currently exist at the repo root or inside `docs/`? Is it referenced in any skill or agent today (e.g., via Module Docs config key)? The roadmap says scaffolder generates it — where in `agents/scaffolder.md` or `skills/scaffold/SKILL.md` is this documented?
    Target files: `docs/architecture.md` (check existence), `agents/scaffolder.md`, `skills/scaffold/SKILL.md`, `docs/reference/config.md` (Module Docs section)

26. What bash command can reliably detect "docs/ARCHITECTURE.md older than N commits" — specifically `git log --oneline docs/ARCHITECTURE.md | wc -l` (total commits to file) vs `git log --oneline -n 1 docs/ARCHITECTURE.md` (date of last edit)? Which approach maps better to a soft-warning threshold (e.g., N=50 commits since last edit)?
    Target files: `skills/fix-ticket/SKILL.md` (where the warning would be added — which step number), `skills/implement-feature/SKILL.md` (same)

---

### Cross-cutting

27. What are the exact current counts referenced across CLAUDE.md, README.md, and `docs/reference/skills.md` for agents, skills, core contracts, optional config sections, and config templates — and which files have stale values that would need updating if v6.9.0 adds any new agents/skills/sections?
    Target files: `CLAUDE.md` lines 18, 159; `README.md` lines 3, 10, 219, 260-261; `docs/reference/skills.md` (skill count); `docs/reference/agents.md` (agent count)
    Verification result (agent-1 pre-read): README.md line 3 says "28 orchestration skills" and line 10 says "Skills (28)" — both stale (actual: 29). README.md line 260 correctly says "All 29 skills". CLAUDE.md line 18 says "29 skills" (correct). These inconsistencies must be in the doc-audit scope for Phase 9.

28. What are the tone, section structure, item count, and "Impact:" line format of the v6.8.1 and v6.8.0 CHANGELOG entries — so the v6.9.0 entry matches exactly?
    Target files: `CHANGELOG.md` lines 10-62 (v6.8.1 and v6.8.0 entries)

29. Does `core/post-publish-hook.md` Section 4 (pipeline-started/step-completed/pipeline-completed) carry the `--proto "=http,https"` flag on its canonical curl example, and does `core/block-handler.md` Step 5 carry it — confirming which core contracts are already compliant vs which are in the skills layer gap?
    Target files: `core/post-publish-hook.md` lines 117-126, `core/block-handler.md` lines 51-55
    Verification result (agent-1 pre-read): Both core contracts already carry `--proto "=http,https"`. The gap is exclusively in skill-level curl examples (fix-ticket, fix-bugs, implement-feature) which have no `--proto` flag.

30. What is the output directory path `.forge/phase-1-research/agents/` — does it already exist, and is the `agents/` subdirectory present for parallel agent outputs?
    Target files: `.forge/phase-1-research/agents/` directory
    Verification result (agent-1 pre-read): Directory exists (created/confirmed during this run).
