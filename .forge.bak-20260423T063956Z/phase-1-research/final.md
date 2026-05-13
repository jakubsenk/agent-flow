# Phase 1 Final — Research Questions for v6.9.0

## Summary
30 questions across 7 categories (A–G). Key risks surfaced: internal hostname `gitea.internal.ceosdata.com` embedded in user-facing installation docs is a high-priority OSS blocker that breaks every external install; `docs/reference/skills.md` already publicly documents `--format json` for `/metrics` creating a pre-existing contract obligation; `docs/ARCHITECTURE.md` Mermaid diagram is already stale ("28 Skills") independent of v6.9.0 scope; and three NEEDS_CLARIFICATION dispatch sites (analyze-bug, scaffold, WEBHOOK-R8 interaction) were missed by the original draft. Security gap: 11 of 21 agents lack prompt-injection protection despite receiving tracker-originated content.

---

## Questions

### A — OSS Readiness

**Q-A-1.** What SPDX license identifier should replace `"UNLICENSED"` in `plugin.json`, and does `marketplace.json` need a `license` field added (it currently has none)? Enumerate MIT, Apache-2.0, and BSD-3-Clause on: (a) OSI approval, (b) patent-grant clause (Apache-2.0 only), (c) convention among pure-markdown Claude Code plugins — the sister plugin `filip-superpowers` uses `"MIT"`. Confirm whether marketplace.json inherits from plugin.json or must be patched separately.
- Target: `.claude-plugin/plugin.json` (line 9: `"license": "UNLICENSED"`), `.claude-plugin/marketplace.json` (no license field — verify schema), `/c/gitea_filip-superpowers/.claude-plugin/plugin.json` (MIT reference)
- Source: agent-1, agent-2, agent-3

**Q-A-2.** Has a public mirror URL (GitHub or public Gitea) been provisioned for the repository? `plugin.json.repository` currently points to `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git`. If no public URL exists, is the repository URL update a hard blocker for OSS go-live, or can it proceed with the internal URL temporarily while the mirror is provisioned?
- Target: `docs/plans/roadmap.md` (lines 754–762), `.claude-plugin/plugin.json`
- Source: agent-1, agent-3

**Q-A-3.** The internal hostname `gitea.internal.ceosdata.com` appears in user-facing files beyond `plugin.json`. Which specific occurrences in `docs/guides/installation.md`, `skills/onboard/SKILL.md`, `tests/mock-project/CLAUDE.md`, and `docs/reference/agents.md` are example/placeholder values (safe to redact to `<your-gitea-host>`) versus hard-coded assumptions that break external installs? Enumerate every line.
- Target: `docs/guides/installation.md` (lines 12–36), `skills/onboard/SKILL.md` (line 102), `tests/mock-project/CLAUDE.md`, `docs/reference/agents.md`
- Source: agent-2 (unique finding — highest-priority OSS blocker)

**Q-A-4.** Does the existing `CONTRIBUTING.md` Code of Conduct subsection (lines 103–108, four informal bullets) create a duplication or contradiction with the planned full Contributor Covenant 2.1 `CODE_OF_CONDUCT.md`? What exact change to `CONTRIBUTING.md` eliminates the duplication — remove the bullets and add a link, or leave them as a summary?
- Target: `CONTRIBUTING.md` (lines 97–109), `docs/plans/roadmap.md` (line 757)
- Source: agent-2, agent-3

**Q-A-5.** What minimum viable content must `SECURITY.md` include: (a) reporting channel (email vs GitHub Security Advisory), (b) response SLA, (c) supported version range? Does the existing `CONTRIBUTING.md` "Reporting Issues" section (lines 97–102) duplicate anything that SECURITY.md will cover, and should CONTRIBUTING.md be updated to link to SECURITY.md rather than duplicating?
- Target: `CONTRIBUTING.md` (lines 97–109), `README.md` (lines 278–282), `docs/plans/roadmap.md` (lines 755–756)
- Source: agent-2, agent-3

**Q-A-6.** Where should Gitea issue/PR templates live given that `.gitea/` exists (contains only `workflows/`) and `.github/` does NOT exist? Should `.github/ISSUE_TEMPLATE/` also be created now for future GitHub-mirror readiness, or only Gitea templates until the mirror is confirmed? What template types are minimally required (bug-report, feature-request, PR)?
- Target: `.gitea/` (current contents — workflows only), `docs/plans/roadmap.md` (line 758), `CONTRIBUTING.md` (lines 97–100)
- Source: agent-2, agent-3

**Q-A-7.** What does `README.md` "Author & License" section (lines 280–282) currently say about the license, and what updates are required after adding a LICENSE file and setting the SPDX identifier? Are there any other files that reference `"UNLICENSED"` or the internal Gitea URL that would become stale misinformation on a public mirror?
- Target: `README.md` (lines 278–285), `docs/guides/installation.md` (lines 12–36), `docs/reference/config.md` (SSRF v6.9.0 deferral note)
- Source: agent-1, agent-2

---

### B — v6.8.1 Polish

**Q-B-1.** What is the exact count and enumerated line numbers of `curl` invocations missing `--proto "=http,https"` across the three primary skill files? Agent-3 pre-verified: fix-ticket lines 106, 183 (2 sites); fix-bugs lines 119, 190, 236, 368, 429, 479, 511, 545, 573, 614, 651, 680, 741 (13 sites); implement-feature lines 108, 221, 535 (3 sites) — 18 total. Confirm this count is complete (no sites added after grep), and confirm `core/post-publish-hook.md` Section 3 and Section 4 already carry `--proto` (so the gap is skill-layer only).
- Target: `skills/fix-ticket/SKILL.md` (lines 106, 183), `skills/fix-bugs/SKILL.md` (lines 119–741), `skills/implement-feature/SKILL.md` (lines 108, 221, 535), `core/post-publish-hook.md` (Section 3 line 18, Section 4 line 120)
- Source: agent-1, agent-2, agent-3

**Q-B-2.** Does `tests/scenarios/v681-harness-exit-propagation.sh` currently have a `trap 'rm -f "$TMPSCEN"' EXIT INT TERM` guard for the temp file created at line 80? What is the canonical trap pattern used in `tests/scenarios/autopilot-trap-cleanup.sh` — is it `trap '...' EXIT` only, or `EXIT INT TERM`? Should the fix add `INT TERM` given that CI test runners may send SIGTERM?
- Target: `tests/scenarios/v681-harness-exit-propagation.sh` (lines 72–86), `tests/scenarios/autopilot-trap-cleanup.sh` (trap pattern reference)
- Source: agent-1, agent-2, agent-3

**Q-B-3.** In `core/block-handler.md` Step 5, does `jq -n` (pretty-print, multi-line) vs `jq -nc` (compact, single-line) matter for webhook consumers — is there any documented byte-equality parsing contract in `core/post-publish-hook.md`, `docs/guides/autopilot.md`, or `CLAUDE.md`? Confirm whether `jq -nc` is strictly required or merely advisory for alignment with WEBHOOK-R8 lenient-parsing guarantee.
- Target: `core/block-handler.md` (lines 41–55), `core/post-publish-hook.md` (lines 17–22, 100–126), `CLAUDE.md` (webhook payload BC section), `docs/guides/autopilot.md` (lines 288–296)
- Source: agent-1, agent-2, agent-3

**Q-B-4.** What is the exact current `issue_id` regex text across all four skill files (fix-ticket line 90, fix-bugs line 95, implement-feature line 92, resume-ticket line 86) — are they identical? Adding `.` to support Jira dotted keys like `PROJ.NAME-123`: does a single dot introduce any path-traversal risk given the anchored regex `^...$` and single-segment usage as `.ceos-agents/{id}/state.json`? Does dot in the ID break run_id format, decomposition YAML filenames, or any other downstream usage?
- Target: `skills/fix-ticket/SKILL.md` (line 90), `skills/fix-bugs/SKILL.md` (line 95), `skills/implement-feature/SKILL.md` (line 92), `skills/resume-ticket/SKILL.md` (line 86), `skills/autopilot/SKILL.md` (if regex present)
- Source: agent-1, agent-2, agent-3

**Q-B-5.** What is the exact AC-ITEM-3.2 false-positive in `core/block-handler.md` — specifically, what grep pattern in which test scenario file matches the prose counter-example `${var:1:-1}` on line 59, and what is the minimal fix (rephrase prose, move to fenced block, or restrict grep to non-prose lines) that resolves the false positive without weakening the test?
- Target: `core/block-handler.md` (lines 55–68), `tests/scenarios/` (search for AC-ITEM-3.2 grep pattern — likely `ac-v68-*` or `block-handler*`), `.forge.bak-20260419T184209Z/phase-5-tdd/tests-hidden/h-block-handler-heredoc.sh`
- Source: agent-1, agent-2, agent-3

---

### C — v6.8.0 Additions

**Q-C-1.** `docs/reference/skills.md` line 562 already documents `--format <md|json>` for `/ceos-agents:metrics` as a current flag, but `skills/metrics/SKILL.md` line 101 says "Output format is always markdown" and the frontmatter `argument-hint` omits `--format`. This is a pre-existing spec-impl gap. What exact JSON schema must `--format json` produce (top-level keys, types, source steps for each field)? Does the output go to stdout (respecting `--output`) or to a separate file? Was `--format json` added to the reference docs prematurely or always aspirational — confirm by checking CHANGELOG.md?
- Target: `skills/metrics/SKILL.md` (lines 1–12, 99–176), `docs/reference/skills.md` (lines 555–575), `CHANGELOG.md` (search for `--format json`)
- Source: agent-3 (unique finding — pre-existing contract obligation)

**Q-C-2.** In `skills/fix-ticket/SKILL.md`, at which exact line does `pipeline-completed` with `outcome: "success"` fire, and at which line does `outcome: "blocked"` fire? Where would `outcome: "failed"` need to fire for catastrophic exits (OOM, SIGKILL, uncaught error)? Is a bash `trap EXIT` achievable given the pure-markdown skill constraint (skill snippets run inside `claude -p`, not a persistent shell), and is `skills/fix-bugs/SKILL.md` and `skills/implement-feature/SKILL.md` consistent in this pattern?
- Target: `skills/fix-ticket/SKILL.md` (lines 504–545), `skills/fix-bugs/SKILL.md` (lines 680–690), `skills/implement-feature/SKILL.md` (outcome fire path), `core/post-publish-hook.md` (lines 82–100, WEBHOOK-R4 ordering rule)
- Source: agent-1, agent-2, agent-3

**Q-C-3.** What is the minimum-viable circuit breaker design for webhook delivery? `core/post-publish-hook.md` already has `--max-time 5 --retry 0` bounding each call. Should the circuit breaker (a) track in-memory failure count per pipeline run only (resets on restart), (b) persist a failure count in `.ceos-agents/circuit-breaker.json` across runs, or (c) skip all webhooks for the remainder of a run after 1 failure? What failure threshold and cooldown period are appropriate? Does circuit-breaker state need to be tracked per event type or globally?
- Target: `core/post-publish-hook.md` (lines 29–33, 100–126), `core/state-manager.md` (atomic write protocol reference), `state/schema.md` (to determine if circuit breaker state belongs in state.json or separate file)
- Source: agent-1, agent-2, agent-3

**Q-C-4.** What is the minimum-viable multi-host distributed lock design for Autopilot v6.9.0? The roadmap calls this "hardest item" and the current mkdir-based process-local lock (`.ceos-agents/autopilot.lock/`) is documented as insufficient for NFS in `skills/autopilot/SKILL.md` lines 350–353. Enumerate viable options: (a) `flock` advisory lock, (b) tracker-level lock issue, (c) HTTP lock service, (d) formalize disjoint-query pattern as explicit operator guidance and defer locking to v6.9.1. What prose changes in `skills/autopilot/SKILL.md` and `docs/guides/autopilot.md` are needed for option (d)?
- Target: `skills/autopilot/SKILL.md` (lines 28–35, 99–230, 350–394), `docs/guides/autopilot.md` (multi-host section), `docs/plans/roadmap.md` (lines 777–783)
- Source: agent-1, agent-2, agent-3

---

### D — NEEDS_CLARIFICATION

**Q-D-1.** How is `NEEDS_DECOMPOSITION` integrated end-to-end today — from `agents/fixer.md` output signal (lines 36–48) through detection in `skills/fix-ticket/SKILL.md` (line 328), `skills/fix-bugs/SKILL.md` (line 396), and `core/fixer-reviewer-loop.md` (line 21), to state.json `decomposition` object? Map the exact field names and status values that change when the signal fires — this is the precise template for NEEDS_CLARIFICATION integration.
- Target: `agents/fixer.md` (lines 36–48), `skills/fix-ticket/SKILL.md` (lines 323–340), `skills/fix-bugs/SKILL.md` (lines 393–410), `core/fixer-reviewer-loop.md` (lines 18–44), `state/schema.md` (decomposition object, lines 123–128)
- Source: agent-1, agent-2, agent-3

**Q-D-2.** What additive JSON shape in `state/schema.md` would represent a NEEDS_CLARIFICATION pause — proposed: top-level `clarification: { status, question, agent, step, run_id, answer }` parallel to `block`? Does the Step Status Enum (lines 449–461) need a new `"awaiting_clarification"` value or can `"blocked"` with a sub-type suffice? Confirm `schema_version: "1.0"` additive-field policy covers this without a version bump.
- Target: `state/schema.md` (lines 1–10 schema_version policy, lines 449–461 Step Status Enum, top-level field definitions), `core/state-manager.md` (additive field guidance)
- Source: agent-1, agent-2, agent-3

**Q-D-3.** How does `skills/resume-ticket/SKILL.md` currently resume from a paused state (lines 13–32, Priority 0: State File Detection)? For NEEDS_CLARIFICATION, what is the proposed mechanism: user provides answer via `--clarification "text"` argument, resume-ticket detects `status: "awaiting_clarification"`, reads the stored question from the `clarification` state object, and injects the answer into the agent's context on re-dispatch? At what step granularity does resume re-enter — entire blocked phase from scratch, or exact sub-step?
- Target: `skills/resume-ticket/SKILL.md` (lines 13–100, Priority 0 detection + Heuristic Detection table), `agents/fixer.md` (lines 66–78, context passing pattern), `state/schema.md`
- Source: agent-1, agent-2, agent-3

**Q-D-4.** Which skills dispatch fixer or triage-analyst and must therefore handle the NEEDS_CLARIFICATION output signal? Confirmed sites from agent-3 audit: fixer dispatched by fix-ticket (line 325), fix-bugs (line 393), implement-feature (line 347), AND scaffold (line 778). Triage-analyst dispatched by fix-ticket (line 161), fix-bugs (line 180), AND analyze-bug (line 24). The original draft missed analyze-bug (triage-analyst dispatch) and scaffold (fixer dispatch). Confirm both missed sites and define the minimum handling each requires.
- Target: `skills/analyze-bug/SKILL.md` (lines 24–35), `skills/scaffold/SKILL.md` (lines 773–800), `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`
- Source: agent-3 (unique finding — missed dispatch sites)

**Q-D-5.** If the pipeline pauses for NEEDS_CLARIFICATION (mid-run, neither completed nor blocked), should `pipeline-completed` webhook fire at all? WEBHOOK-R8 specifies lenient-parsing forward-compatibility — would adding `outcome: "clarification_pending"` as a new value be backward-compatible (consumers ignore unknown values), or should the event simply not fire until the pipeline resumes and terminates? What is the correct behavior to document in `core/post-publish-hook.md`?
- Target: `core/post-publish-hook.md` (lines 82–100, 147–150 WEBHOOK-R8), `CLAUDE.md` (webhook payload BC section), `docs/reference/skills.md` (resume-ticket docs)
- Source: agent-3 (unique finding — WEBHOOK-R8/NEEDS_CLARIFICATION interaction)

---

### E — pipeline-history.md Feedback Loop

**Q-E-1.** Where should `pipeline-history.md` live? The roadmap (lines 806–810) proposes `.claude/pipeline-history.md`, but `state/schema.md` uses `.ceos-agents/` for all plugin-managed state. Is `.claude/` gitignored in typical projects (settings.local.json is gitignored per project memory)? Does `.claude/pipeline-history.md` conflict with any Claude Code reserved files? What privacy risk exists if `block.detail` (which can contain source code excerpts) gets committed to a public OSS repo?
- Target: `docs/plans/roadmap.md` (lines 806–811), `state/schema.md` (lines 1–18, `.ceos-agents/` layout), `agents/fixer.md` (Step 1, where history read would be inserted)
- Source: agent-1, agent-2, agent-3

**Q-E-2.** What storage format — append-only flat markdown (one H2 per run) vs JSONL (one record per line) — is more practical for fixer and reviewer agents consuming the history via the `Read` tool? What minimum metadata set (issue ID, outcome, agent, step, block reason — excluding `block.detail` source excerpts) is useful without exposing sensitive content? What is the maximum retention (last N entries) to keep in-context without exceeding token budget?
- Target: `docs/plans/roadmap.md` (lines 806–811), `state/schema.md` (block object fields), `agents/fixer.md` (Step 1), `agents/reviewer.md` (Step 1)
- Source: agent-1, agent-2, agent-3

**Q-E-3.** At what pipeline step should the `pipeline-history.md` append fire — as a new Section 5 in `core/post-publish-hook.md` (after `pipeline-completed` webhook, inheriting behavior for all 4 pipeline skills) or inline in each skill's terminal step? For fix-bugs (per-bug loop): should each bug fix generate its own history entry, or only the final loop summary? Does the existing atomic write protocol (tmp + rename) in `core/state-manager.md` support append-only files?
- Target: `core/post-publish-hook.md` (Section 4 end, ~line 150), `skills/fix-bugs/SKILL.md` (per-bug loop structure), `core/state-manager.md` (atomic write protocol)
- Source: agent-1, agent-2, agent-3

---

### F — ARCHITECTURE.md Freshness

**Q-F-1.** `docs/ARCHITECTURE.md` currently exists in the repo. Its Mermaid diagram shows "28 Skills" — already stale since v6.8.0 added the 29th skill. Does this diagram appear in either `skills/fix-ticket/SKILL.md` or `skills/implement-feature/SKILL.md` today as a Module Docs reference? Where in each skill (before fixer dispatch, after code-analyst) should the staleness check be inserted as a `git log` advisory-only warning?
- Target: `docs/ARCHITECTURE.md` (Mermaid diagram, skill count), `skills/fix-ticket/SKILL.md` (insertion point), `skills/implement-feature/SKILL.md` (insertion point), `docs/plans/roadmap.md` (lines 812–817)
- Source: agent-1, agent-2, agent-3

**Q-F-2.** What is the correct git command to detect that `docs/ARCHITECTURE.md` is stale by N commits — agent-3 proposes `git rev-list HEAD...$(git log -1 --format="%H" -- docs/ARCHITECTURE.md) --count` (commits since last file edit) as more accurate than `git log --oneline docs/ARCHITECTURE.md | wc -l` (total commits to file). What default N threshold should trigger the soft warning? Should the warning also appear in the `pipeline-completed` webhook payload as an optional `warnings` array field (additive, MINOR-safe)?
- Target: `docs/plans/roadmap.md` (line 817: "soft warning"), `skills/fix-ticket/SKILL.md` (Step 1 or 2), `skills/implement-feature/SKILL.md` (same), `core/post-publish-hook.md` (pipeline-completed payload)
- Source: agent-1, agent-2, agent-3

---

### G — Cross-Cutting

**Q-G-1.** Enumerate every file that embeds a hardcoded count (agents, skills, core contracts, optional config sections, config templates) that will drift if v6.9.0 adds any new artifact. Agent-3 confirmed: `CLAUDE.md` (lines 17–18, 159), `README.md` (lines 219, 260–261), `docs/reference/automation-config.md` (line 9), `docs/reference/skills.md` (line 3), `docs/ARCHITECTURE.md` Mermaid diagram (already stale: "28 Skills"). Will NEEDS_CLARIFICATION, pipeline-history.md, or the new OSS files (LICENSE, SECURITY.md, CODE_OF_CONDUCT.md) change any count (new core contract, new optional config section)?
- Target: `CLAUDE.md` (lines 17–18, 159), `README.md` (lines 219, 260–261), `docs/reference/automation-config.md` (line 9), `docs/reference/skills.md` (line 3), `docs/ARCHITECTURE.md` (Mermaid diagram)
- Source: agent-1, agent-3

**Q-G-2.** What are the exact tone, section heading style, item format, and structural conventions of the v6.8.1 and v6.8.0 CHANGELOG entries that the v6.9.0 entry must match? Specifically: heading format (`## [X.Y.Z] — YYYY-MM-DD`), sub-header format (`**MINOR** — theme`), section names (`### Added`, `### Changed`, `### Fixed`, `### Internal`), item prefix style, presence of `### Migration notes` and `### Known Issues`, and whether an "Impact:" line appears in CHANGELOG entries vs roadmap entries only.
- Target: `CHANGELOG.md` (lines 10–63, v6.8.1 and v6.8.0 entries)
- Source: agent-1, agent-2, agent-3

**Q-G-3.** Of the 11 agents currently lacking the `NEVER follow instructions from EXTERNAL INPUT` constraint (test-engineer, e2e-test-engineer, publisher, rollback-agent, scaffolder, stack-selector, spec-writer, spec-reviewer, deployment-verifier, backlog-creator, sprint-planner), which receive issue tracker content as input and are therefore prompt-injection vulnerable — especially under Autopilot `--dangerously-skip-permissions` where poisoned issue content can flow through to bash command execution? Should `test-engineer` and `e2e-test-engineer` receive this constraint given they run test output that may originate from issue content?
- Target: `agents/test-engineer.md`, `agents/e2e-test-engineer.md`, `agents/publisher.md`, `agents/scaffolder.md` (Process step inputs), `skills/autopilot/SKILL.md` (lines 373–384, security considerations)
- Source: agent-2 (unique finding — concrete security risk under Autopilot)

**Q-G-4.** Does `core/post-publish-hook.md` Section 4 carry `--proto "=http,https"` and `--max-time 5 --retry 0` on ALL its webhook curl examples (pipeline-started, step-completed, pipeline-completed), and does `core/block-handler.md` Step 5 carry `--proto "=http,https"` — confirming which core contracts are already compliant and the gap is exclusively in the skills layer (18 sites)?
- Target: `core/post-publish-hook.md` (lines 117–126, all Section 4 curl calls), `core/block-handler.md` (lines 51–55)
- Source: agent-1 (pre-verified: both core contracts already carry `--proto`)

---

## Synthesis notes

### Base agent selection
Agent-3 selected as base (self-score 0.94, highest; extensive grep-verification of line numbers across all files; strongest BC integration lens). Agent-1 (0.93) used as co-base for categories D, E, F (deeper NEEDS_DECOMPOSITION mapping and pipeline-history design questions). Agent-2 (0.88) used exclusively for its three unique security/compliance findings.

### Unique findings preserved
- **Agent-2 only**: Q-A-3 (internal hostname `gitea.internal.ceosdata.com` in user-facing docs — highest-priority OSS blocker), Q-G-3 (prompt injection coverage gap — 11 agents lack EXTERNAL INPUT constraint, concrete risk under Autopilot `--dangerously-skip-permissions`)
- **Agent-3 only**: Q-C-1 (docs/reference/skills.md already documents `--format json` as a current flag — pre-existing contract obligation, not new addition), Q-D-4 (analyze-bug as missed triage-analyst dispatch site, scaffold as missed fixer dispatch site), Q-D-5 (WEBHOOK-R8/NEEDS_CLARIFICATION interaction — should `pipeline-completed` fire at all on pause?), Q-G-1 (docs/ARCHITECTURE.md Mermaid "28 Skills" is already stale, independent of v6.9.0)

### Conflicts resolved
1. **REPO_ROOT path bug (agents 1 and 3)**: Agent-1 framed this as a current codebase bug in `.forge.bak-*` files; agent-2 correctly noted `.forge/phase-5-tdd/` does not exist yet; agent-3 identified it as a generator concern for the TDD phase. Resolution: merged into Q-B-5 context (the hidden test template issue), noted as TDD phase concern — Phase 2 need not investigate the `.forge.bak-*` files specifically since they will be regenerated. The surface area for the fix is the forge pipeline's TDD phase template, not current repo files.
2. **jq -nc vs jq -n (all three agents)**: Agent-2 narrowed this to "is byte-equality parsing documented anywhere?" All three agents agree it is advisory. Q-B-3 asks the narrow, confirmatory question rather than treating it as a blocking concern.
3. **ARCHITECTURE.md scope (agents 1, 2, 3)**: Agent-1 asked whether `docs/ARCHITECTURE.md` even exists; agent-3 confirmed it exists with stale Mermaid count. Q-F-1 uses the confirmed-existence framing. The freshness staleness (28 vs 29 skills) is treated as a doc-drift fix for Phase 9 regardless of whether the warning feature is implemented.
4. **NEEDS_CLARIFICATION dispatch sites (agents 1, 2 vs agent-3)**: Agents 1 and 2 enumerated only fix-ticket, fix-bugs, implement-feature, resume-ticket as dispatch sites. Agent-3 additionally identified analyze-bug (triage-analyst) and scaffold (fixer) as missed sites. Q-D-4 uses agent-3's complete enumeration.

### Questions deferred to Phase 2 follow-up
- `.forge.bak-20260419T184209Z/phase-5-tdd/tests-hidden/` REPO_ROOT depth bug: the hidden test directory is a forge artifact not present in current HEAD; it will be regenerated by the TDD phase. Phase 2 (spec) should mandate `../../../` as a requirement for hidden tests placed under `.forge/phase-5-tdd/tests-hidden/`. This is a spec requirement, not a research question.
- Exact `git rev-list` command correctness (Q-F-2) versus `git log | wc -l`: both approaches are valid depending on intent; Phase 4 spec will select the approach. Phase 2 should answer which intent is desired (commits since last edit vs total commits to file).
- Whether `pipeline-history.md` context injection increases token costs enough to require an opt-in Automation Config key: this is a design decision for Phase 4 spec, not a factual research question.
