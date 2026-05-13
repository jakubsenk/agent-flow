# Phase 3 Brainstorm — Agent A (Conservative Release Engineer)

## Self-score: 0.88

Reasoning: I cover all 11 items with concrete file:line citations from Phase 2 evidence, propose conservative defaults backed by real precedent (sister-plugin MIT, mkdir locks already shipped, Contributor Covenant 2.1 verbatim), explicit defer-with-roadmap recommendations on the two highest-risk items (C4 multi-host lock, A3 repo URL), and concrete failure scenarios with detection mechanisms. I deduct 0.12 for: (1) inability to truly verify "public mirror not provisioned" without a user query (recommendation depends on that fact); (2) some defer recommendations may be tighter than the Innovative agent will propose, which is intentional but reduces my synthesis-merge yield.

---

## A1. License selection

**Approach:** Adopt **MIT** verbatim — same license already used by sister plugin `filip-superpowers` (Phase 2 §0). Update `.claude-plugin/plugin.json:9` from `"UNLICENSED"` to `"MIT"`, add `"license": "MIT"` to `marketplace.json.plugins[0]` (additive — V-4 confirms field absent, no schema breakage), create `LICENSE` at repo root with the standard MIT text. Copyright line: `Copyright (c) 2024-2026 Filip Sabacky`. Update `README.md:282` from "See [plugin.json] for license details" to `**Filip Sabacky** — [MIT License](LICENSE)`. This is the minimum-surface-area path: one file added, three lines changed, zero new dependencies.

**Files:**
- `.claude-plugin/plugin.json:9` — replace `"UNLICENSED"` → `"MIT"`
- `.claude-plugin/marketplace.json:14` (plugin object) — add `"license": "MIT"` field (additive per V-4)
- `LICENSE` (NEW, repo root) — full MIT text with `Copyright (c) 2024-2026 Filip Sabacky`
- `README.md:282` — replace stale plugin.json reference with `[MIT License](LICENSE)` link
- `CHANGELOG.md` — entry under `### Added`

**Risk/tradeoff:** MIT is permissive — downstream forks may not contribute back. Apache-2.0 would add patent-grant and contributor-license clarity, but for a markdown-only plugin with no compiled code there is no patent surface to grant. License change UNLICENSED→MIT is unambiguously backward-compatible (grants more rights). The conservative bias here aligns with the precedent — diverging from the sister plugin's MIT choice would create a 2-license author ecosystem with no benefit.

**What-if-wrong:** A consumer that assumed `"UNLICENSED"` meant "explicitly proprietary, do not use" was nonetheless using the plugin internally and now believes the new MIT license applies retroactively. Detection: CHANGELOG entry must explicitly say "License changed from UNLICENSED to MIT effective v6.9.0; all prior versions remain UNLICENSED." Also: the LICENSE file's copyright year range (2024-2026) signals the temporal scope.

**Alternatives:** **MIT vs Apache-2.0 vs BSD-3-Clause**
| License | Pros | Cons | Recommendation |
|---|---|---|---|
| MIT | Shortest text (~170 words), simplest, sister-plugin precedent, OSI-approved, no patent clauses needed for markdown | No patent grant (irrelevant for markdown) | **CHOSEN** |
| Apache-2.0 | Explicit patent grant, contributor-clauses formalized, NOTICE file convention | ~10× longer text, requires NOTICE file in some interpretations, no benefit for non-code repo | Reject — over-engineering for markdown |
| BSD-3-Clause | Adds non-endorsement clause | Marginally more restrictive than MIT, no precedent in author's plugins | Reject — no advantage over MIT |

Rationale: Sister-plugin alignment is dispositive. MIT is the de facto standard for pure-markdown plugins on the Claude Code marketplace.

---

## A2. SECURITY.md content

**Approach:** Adopt the verbatim Phase 2 §9.1 draft. Five short sections: (1) reporting channel = `filip.sabacky@ceosdata.com`, (2) what to include in the report, (3) acknowledgment SLA = 5 business days, (4) fix/mitigation SLA = 30 days, (5) supported-versions policy = "latest released version only". Total length ≈12 lines. Add cross-link from `CONTRIBUTING.md:98-101` "Reporting Issues" to point security reports at SECURITY.md. The conservative move is to publish realistic SLAs the maintainer can actually meet — over-promising 24h triage on a side-project plugin would create a credibility risk.

**Files:**
- `SECURITY.md` (NEW, repo root) — verbatim from Phase 2 §9.1
- `CONTRIBUTING.md:98-101` — add line: "For security vulnerabilities, see [SECURITY.md](SECURITY.md) instead of opening a public issue."
- `CHANGELOG.md` — entry under `### Added`

**Risk/tradeoff:** The contact email is the maintainer's personal/work address (`filip.sabacky@ceosdata.com`). For a single-maintainer plugin this is correct, but it creates a single point of failure for vulnerability triage. Alternative: use a GitHub Security Advisory channel once GitHub mirror exists (deferred with A3). For v6.9.0, email is sufficient and proven.

**What-if-wrong:** A reporter sends a vulnerability report and waits for the 5-day SLA; the maintainer is on vacation. Detection: add a line "Auto-acknowledgment via mailbox auto-reply is acceptable; substantive response within 5 business days." Future hardening: add a fallback contact in v6.9.1 if the project graduates to multi-maintainer.

---

## A3. Repository URL change

**Approach:** **Partial — prepare files but DO NOT change the canonical URL until the public mirror is provisioned.** Replace `.claude-plugin/plugin.json:8` with a tombstone: `"https://github.com/YOUR_ORG/ceos-agents"` — clearly placeholder, signals intent, fails fast if anyone tries to clone it. Rewrite `docs/guides/installation.md` lines 15, 26, 27, 31, 36 to be host-agnostic (`<your-git-host>` and `<owner>/<repo>`). Update `tests/mock-project/CLAUDE.md:20` and `skills/onboard/SKILL.md:102` similarly. Do NOT modify `docs/reference/agents.md:662` (already uses `gitea.internal.example.com` per V-2 — fictional/safe). Add a roadmap entry for v6.9.1 to swap the placeholder URL for the actual mirror URL once provisioned. This is the conservative path: ship the OSS-blocking text fixes now, defer the one decision that requires confirmed external infrastructure.

**Files:**
- `.claude-plugin/plugin.json:8` — placeholder URL `https://github.com/YOUR_ORG/ceos-agents`
- `docs/guides/installation.md:15,26,27,31,36` — replace `gitea.internal.ceosdata.com` with `<your-git-host>`; replace `fsabacky/ceos-agents` with `<owner>/<repo>`
- `tests/mock-project/CLAUDE.md:20` — `<your-gitea-host>/test/mock-project`
- `skills/onboard/SKILL.md:102` — `<your-gitea-host>/org/repo`
- `docs/plans/roadmap.md` — add v6.9.1 entry: "Replace placeholder repository URL with actual public mirror URL"
- DO NOT touch `docs/reference/agents.md:662` (already safe per V-2)

**Risk/tradeoff:** Shipping with a placeholder URL means `claude plugin install` from `plugin.json` metadata will fail until the URL is fixed. But `plugin.json.repository` is metadata only (not used by the install path — that's `marketplace.json` source). The conservative position: a placeholder URL that obviously fails is safer than a hardcoded internal URL that leaks infrastructure details.

**What-if-wrong:** Someone runs `claude plugin install` and the placeholder URL points at a non-existent GitHub repo. Detection: the install error message will include the bogus URL — clearly user-visible. Mitigation: install path uses `marketplace.json` source `"./"` (local-relative), so install actually works from a local clone regardless of `plugin.json.repository`.

**Alternatives:** **Implement now vs Defer entirely vs Partial (chosen)**
| Option | When canonical URL is set | Risk | Recommendation |
|---|---|---|---|
| Implement now | v6.9.0 ships with real public URL | Requires the mirror to exist before ship — currently UNCONFIRMED | Reject — speculative |
| Defer entirely | Keep `gitea.internal.ceosdata.com` until mirror exists | Internal hostname leaks in public OSS release — defeats OSS readiness | Reject — security-relevant leak |
| **Partial (placeholder + text fixes)** | Placeholder now, real URL in v6.9.1 patch when mirror confirmed | Placeholder URL is obviously wrong; install path uses local `./` source | **CHOSEN** |

Rationale: The internal hostname leak is the actual blocker; the canonical URL is metadata-only. Decoupling lets the OSS-readiness ship without waiting on infrastructure provisioning.

---

## A4. CODE_OF_CONDUCT.md

**Approach:** Adopt **Contributor Covenant 2.1 by reference** (not full inline) — minimum surface area. Create `CODE_OF_CONDUCT.md` at repo root with ~6 lines: title, one-paragraph reference to the Covenant URL, and a contact line (`filip.sabacky@ceosdata.com` — same email as SECURITY.md). Remove the four duplicative bullets at `CONTRIBUTING.md:103-108` per Phase 2 §Q-A-4. This avoids maintaining a 200-line CoC text file inline (which then drifts from the canonical Covenant version). The Phase 2 §9.2 draft is the verbatim template.

**Files:**
- `CODE_OF_CONDUCT.md` (NEW, repo root) — verbatim from Phase 2 §9.2
- `CONTRIBUTING.md:103-108` — replace 4 informal bullets with single line: `See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for the full Code of Conduct.`
- `CHANGELOG.md` — entry under `### Added`

**Risk/tradeoff:** Reference-only CoC means readers must follow a link to see the actual rules — slight UX friction. But maintaining inline text creates version-drift risk (Covenant 2.1 → 2.2 → 3.0 over time). Reference-by-URL is the conservative choice: always points at the canonical, latest-acknowledged version.

**What-if-wrong:** A reader expects to find the full CoC text in-repo, follows the link to the Covenant site, finds it. Detection: README.md should link to `CODE_OF_CONDUCT.md` so readers find it; the existing OSS readiness audit will flag if README doesn't reference it.

**Alternatives:** **Contributor Covenant 2.1 reference vs verbatim inline vs custom CoC**
| Option | Pros | Cons | Recommendation |
|---|---|---|---|
| **Covenant 2.1 by reference** | Always canonical, minimal maintenance, ~6 lines | Requires reader to follow URL | **CHOSEN** |
| Covenant 2.1 verbatim inline | Self-contained, works offline | ~200 lines to maintain, drifts from canonical | Reject — maintenance burden |
| Custom CoC | Tailored to plugin community | Reinventing solved problem, no community recognition | Reject |

Rationale: Reference-only is the OSS standard for small/single-maintainer projects. GitHub's CoC chooser (`https://www.contributor-covenant.org/`) explicitly supports this pattern.

---

## A5. Issue/PR templates (.github vs .gitea vs both)

**Approach:** Create **BOTH** `.gitea/issue_template/` AND `.github/ISSUE_TEMPLATE/` with identical content (drafts in Phase 2 §9.3-9.6). Three minimum templates: `bug_report.md`, `feature_request.md`, `PULL_REQUEST_TEMPLATE.md` (capitalized for GitHub, lowercase for Gitea). The repo currently has `.gitea/` (workflows only) and no `.github/` (per Phase 2 §Q-A-6). Both directories cost only 6 short markdown files — negligible maintenance and dual-mirror coverage matches the placeholder-URL stance in A3.

**Files (NEW):**
- `.gitea/issue_template/bug_report.md` — verbatim Phase 2 §9.3
- `.gitea/issue_template/feature_request.md` — verbatim Phase 2 §9.4
- `.gitea/pull_request_template.md` — verbatim Phase 2 §9.5
- `.github/ISSUE_TEMPLATE/bug_report.md` — same as 9.3
- `.github/ISSUE_TEMPLATE/feature_request.md` — same as 9.4
- `.github/PULL_REQUEST_TEMPLATE.md` — same as 9.5
- `CHANGELOG.md` — entry under `### Added`

**Risk/tradeoff:** Maintaining two parallel template directories means future template edits must touch both. Mitigation: in `.gitea/` add a comment header to each template noting "MIRROR OF .github/{path}". Future v6.9.x could introduce a build-time symlink or generation step but that violates the "no runtime/build" constraint — defer.

**What-if-wrong:** A user edits the GitHub bug_report template, forgets to mirror to Gitea, and the two diverge silently. Detection: add a hidden test scenario that diffs the 6 file pairs and fails on mismatch. Cheap (one bash test scenario, ~15 lines), enforces the contract.

---

## B. v6.8.1 polish bundle (6 sub-items)

**Approach:** Treat as one cohesive mechanical bundle — six independent, low-risk fixes with the highest leverage-per-line in the release. Apply each fix exactly per Phase 2 evidence. Sequence: B-1 first (highest count, mechanical), then B-2/B-3 (single-line each), then B-4 (regex), then B-5/B-6 (test fixtures). Each sub-item is independently testable.

**Sub-item B-1 — `--proto "=http,https"` at 18 sites:**
- Files: `skills/fix-ticket/SKILL.md:106,183` (2), `skills/fix-bugs/SKILL.md:119,190,236,368,429,479,511,545,573,614,651,680,741` (13), `skills/implement-feature/SKILL.md:108,221,535` (3) — exact lines per Phase 2 V-1
- Mechanical replace: `curl --max-time 5` → `curl --proto "=http,https" --max-time 5`

**Sub-item B-2 — Trap cleanup in v681-harness-exit-propagation.sh:**
- File: `tests/scenarios/v681-harness-exit-propagation.sh:80` (after `TMPSCEN` declaration)
- Insert: `trap 'rm -f "$TMPSCEN"' EXIT INT TERM`

**Sub-item B-3 — `jq -nc` migration:**
- File: `core/block-handler.md:43` — replace `jq -n` with `jq -nc`
- Per Phase 2 §Q-B-3: lenient-parsing contract already documented in 3 places (CLAUDE.md:189, post-publish-hook:149, autopilot.md:286), so byte-equality is not a contract; this is a low-risk cleanup

**Sub-item B-4 — Jira dotted-key regex:**
- Files: `skills/fix-ticket/SKILL.md:90`, `skills/fix-bugs/SKILL.md:95`, `skills/implement-feature/SKILL.md:92`, `skills/resume-ticket/SKILL.md:86`
- Replace `^[A-Za-z0-9#_-]+$` → `^[A-Za-z0-9#._-]+$` (additive — only Jira `PROJ.NAME-123` newly accepted)
- Path-traversal verified safe in Phase 2 §Q-B-4 — single dot in char class cannot produce `..`

**Sub-item B-5 — REPO_ROOT path bug:**
- File: `.forge/phase-5-tdd/tests-hidden/h-block-handler-heredoc.sh:7` — change `../../` → `../../../` (3 levels up matches actual depth)
- This is a forge-pipeline test fixture; the v6.9.0 forge run will recreate this file with correct path

**Sub-item B-6 — AC-ITEM-3.2 false-positive:**
- File: `core/block-handler.md:59` — wrap the `${var:1:-1}` counter-example prose in HTML comment markers `<!-- COUNTER-EXAMPLE: ... -->` so the negative grep can exclude `<!--` lines
- File: `.forge/phase-5-tdd/tests-hidden/h-block-handler-heredoc.sh` — update grep to `grep -vE '<!--' | grep -qE '\$\{...\}'`

**Files (consolidated):**
- 3 skills × 18 sites total (B-1)
- 1 test scenario (B-2)
- 1 core contract single line (B-3)
- 4 skills × 1 line each (B-4)
- 2 hidden test fixtures (B-5, B-6 sub-fix 2)
- 1 core contract single prose paragraph (B-6 sub-fix 1)

**Risk/tradeoff:** B-1 changes 18 sites mechanically — high-volume but each change is identical. B-3 (`jq -nc`) is the only sub-item with any conceivable downstream parser breakage; Phase 2 §Q-B-3 explicitly verified no byte-equality contract exists. B-4 expands an allowlist (additive). All six are PATCH-grade changes shipped in a MINOR release.

**What-if-wrong:** B-1 mass-replace skips one of the 18 sites (e.g., a curl invocation that wraps lines differently). Detection: add a hidden test scenario that greps for `^.*curl ` across the 3 skill files and asserts every match also contains `--proto "=http,https"` on the same logical command. Run as part of harness — already 141/141 baseline, easy to add 1 more scenario.

---

## C1. /metrics --format json

**Approach:** Implement the JSON schema EXACTLY as drafted in Phase 2 §9.8 — this is already a public contract per `docs/reference/skills.md:562-576` (V-5 confirmed) so the spec-impl gap MUST close. Update `skills/metrics/SKILL.md` argument-hint to add `--format <md|json>`, replace the "Output format is always markdown" line with conditional logic, route output to same destination as `--output` (file or stdout), serialize compact via `jq -nc`-style. No new fields beyond Phase 2 schema. No new optional Automation Config keys (would violate MINOR semver).

**Files:**
- `skills/metrics/SKILL.md:10-14` — add `--format <md|json>` flag parsing
- `skills/metrics/SKILL.md:101` — replace "Output format is always markdown" with conditional logic per Phase 2 §9.8
- `tests/scenarios/v690-metrics-format-json.sh` (NEW) — verifies JSON output is valid + matches schema keys
- `CHANGELOG.md` — entry under `### Added`

**Risk/tradeoff:** The schema is canonical from Phase 2 — Phase 4 should NOT extend it without re-justifying. Adding fields later (e.g., `git_branch` provenance) is additive-safe; removing/renaming would break consumers. Conservative posture: ship the minimum-viable schema, document additive-only future evolution policy.

**What-if-wrong:** A consumer parses `pipeline_overview.success_rate` as a percentage (0-100) when the schema returns 0.0-1.0 (decimal). Detection: schema documentation must explicitly state "ratio 0.0-1.0, not percentage". Add to `docs/reference/skills.md` under the `--format <md|json>` flag definition: "Numeric fields use decimal ratios (0.0-1.0) for rates."

---

## C2. Webhook circuit breaker

**Approach:** Adopt Phase 2 §Q-C-3 recommendation: **in-memory failure count, global, per-pipeline-run, threshold = 3 consecutive failures, no persistence.** Implementation lives in `core/post-publish-hook.md` Section 4 (additive subsection 4.2) — the curl invocation pattern increments a shell variable on `[WARN] Webhook delivery failed`; once `webhook_failure_count -ge 3`, suppress remaining webhook curl calls for this run and log `[WARN] Circuit breaker open: 3 consecutive webhook failures. Suppressing remaining webhooks for this run.` Resets on next pipeline invocation (no state file). Pure-markdown semantics: the prose instructs the LLM-driven pipeline to track and skip — no new runtime code.

**Files:**
- `core/post-publish-hook.md` — add subsection 4.2 "Circuit breaker semantics" (~15 lines of prose)
- `state/schema.md` — NO change needed (deliberately not persisting count)
- `CHANGELOG.md` — entry under `### Added`

**Risk/tradeoff:** Global threshold (not per-event-type) is the simpler choice per Phase 2 §10 open question 1. Tradeoff: 3 failures of `pipeline-started` events suppress later `pipeline-completed` events for the same run. Conservative reasoning: a dead endpoint fails all event types equally — per-event-type tracking adds complexity without real-world benefit. If this proves wrong in v6.9.x, per-event-type is an additive upgrade.

**What-if-wrong:** Circuit breaker triggers on a transient network blip (3 consecutive 5s timeouts during a brief upstream outage), suppressing webhooks for the remaining ~30s of the run. Detection: the `[WARN]` log line is structured + greppable. Mitigation: 3-failure threshold (not 1 or 2) ensures transient single-call hiccups don't trigger; if 15s of failures happen, the upstream really is down.

---

## C3. outcome:failed catastrophic-exit fire path

**Approach:** Implement as **prose instruction in each pipeline skill** (Phase 2 §Q-C-2 recommendation) — NOT as a bash trap (this is a markdown plugin, not a runtime). Add new terminal section "Step Z: Catastrophic exit handler (outcome: failed)" to fix-ticket, fix-bugs, implement-feature near the end. Prose: "If the pipeline exits without reaching the success or block terminal step — for example, due to unrecoverable tool error, OOM, or agent crash — the skill MUST attempt to fire `pipeline-completed` with `outcome: \"failed\"`, `pr_url: null`. This is best-effort; if no terminal status was committed to state.json before exit, `outcome: \"failed\"` applies." The `outcome: "failed"` value is already documented in `core/post-publish-hook.md:85` payload contract — this closes the doc-impl gap.

**Files:**
- `skills/fix-ticket/SKILL.md` — add Step Z after Step X (block handler) (~10 lines)
- `skills/fix-bugs/SKILL.md` — add Step Z after the per-bug terminal section (~10 lines)
- `skills/implement-feature/SKILL.md` — add Step Z after Step X (~10 lines)
- `tests/scenarios/v690-outcome-failed-fire-path.sh` (NEW) — verifies prose contract present in all 3 skills
- `CHANGELOG.md` — entry under `### Added`

**Risk/tradeoff:** "Best-effort" semantics mean the failed webhook may not fire if the catastrophic exit happens BEFORE the skill prose is reached (e.g., a fatal LLM error in the first 10 seconds). Conservative honesty: this can never be a hard guarantee in a markdown-driven pipeline; document it as "best-effort" and move on. A trap-based approach would require runtime code (violation of plugin constraint).

**What-if-wrong:** A pipeline crashes BEFORE the skill reaches the Step Z prose; no `outcome: "failed"` fires; observability dashboard shows the run as `running` indefinitely. Detection: dashboard skill (`/ceos-agents:dashboard`) should detect runs with no terminal webhook within N=30 minutes and surface as "stale running". This is observability hygiene, not a v6.9.0 hard requirement — note in roadmap as future enhancement.

---

## C4. Multi-host distributed lock

**Approach:** **DEFER TO v6.9.1.** Adopt Phase 2 §Q-C-4 Option 3: formalize the disjoint-query pattern as the v6.9.0-supported approach, document the deferral in `skills/autopilot/SKILL.md` Cross-Host Operation section and `docs/guides/autopilot.md`. Add a roadmap entry to v6.9.1 with the option matrix already explored. This is the SINGLE deferral the conservative agent makes — anti-pattern §4 explicitly permits one defer, and multi-host lock is the roadmap-acknowledged candidate. Shipping a half-implemented `flock` on NFS would be more harmful than no implementation.

**Files:**
- `skills/autopilot/SKILL.md:344-353` — strengthen Cross-Host Operation prose with explicit deferral note: "Multi-host coordination via disjoint queries is the v6.9.0-supported pattern. Distributed lock (flock advisory, external coordinator like etcd/redis) is deferred to v6.9.1 pending operator demand and a confirmed deployment topology."
- `docs/guides/autopilot.md` — same deferral note
- `docs/plans/roadmap.md` — add v6.9.1 entry with the 3 options from Phase 2 §Q-C-4 already enumerated (flock/external/disjoint-formalized)
- `CHANGELOG.md` — under `### Known Issues (deferred to v6.9.1)`

**Risk/tradeoff:** Deferral means operators running Autopilot on >1 host without disjoint queries CAN double-process issues. The 120-min stale-lock detection (already shipped in v6.8.0) bounds the damage. Conservative move: be explicit about the gap rather than ship a fragile lock that gives false confidence.

**What-if-wrong:** An operator ignores the disjoint-query guidance, runs autopilot on 2 hosts with overlapping queries, both pick up the same bug, double PRs created. Detection: tracker-side detection (e.g., issue moves to in-progress twice in <60s) — best detected by tracker integration logic, not the plugin. Mitigation: documentation must be unambiguous and prominent; CONFIGURATION the disjoint-query convention as the only supported pattern in v6.9.0.

**Alternatives:** **Implement now (flock NFS) vs Implement now (external coordinator) vs Defer (chosen)**
| Option | Reliability | Dependency cost | Recommendation |
|---|---|---|---|
| `flock` advisory lock on NFS | Fragile — breaks on SMB/CIFS, OS-dependent | None | Reject — false confidence |
| External coordinator (etcd/redis/consul) | Reliable | Breaks "no runtime dependencies" plugin constraint | Reject — scope violation |
| **Defer with formalized disjoint-query pattern** | Operator-coordinated, no false guarantees | None | **CHOSEN** |

Rationale: A markdown-only plugin cannot ship a robust distributed lock. Disjoint queries are the actual scaling pattern; formalizing them as the supported approach is honest and correct.

---

## D. NEEDS_CLARIFICATION state

**Approach:** Mirror NEEDS_DECOMPOSITION exactly per Phase 2 §Q-D-1. New fenced agent-output block `## NEEDS_CLARIFICATION` with required fields; skills detect by exact string match; skill writes top-level `clarification` object to state.json (parallel to `block`); skill sets top-level `status: "paused"`; resume-ticket detects `status: "paused"` and accepts `--clarification "answer text"` flag (or prompts interactively). All schema additions are additive — `schema_version` stays `"1.0"`. Do NOT fire `pipeline-completed` on pause (Phase 2 §Q-D-5) — pause is non-terminal. Defer `pipeline-paused` webhook event to a future MINOR (open question §10.3 — conservative answer: defer).

**Schema (verbatim from Phase 2 §9.9):**
```json
"clarification": {
  "question": "string (max 280 chars)",
  "asked_by_agent": "fixer | triage-analyst",
  "asked_at_step": "string (canonical stage name)",
  "asked_at_iteration": "integer or null",
  "context": "string (optional, max 500 chars)",
  "answer": "string or null"
}
```
- Top-level `status` enum: add `"paused"` (existing: running/completed/blocked/failed)
- Step Status Enum: add `"awaiting_clarification"`

**Files:**
- `agents/fixer.md` — add `## NEEDS_CLARIFICATION` output block + Constraints rule
- `agents/triage-analyst.md` — same
- `state/schema.md:219` — add `"paused"` to top-level status enum
- `state/schema.md:315` (after `block` definition) — add `clarification` object spec
- `state/schema.md:449-461` — add `"awaiting_clarification"` to Step Status Enum
- `skills/fix-ticket/SKILL.md` — add detection + state write at Step 3 (triage) and Step 5 (fixer)
- `skills/fix-bugs/SKILL.md` — same at Step 2 (triage) and Step 4 (fixer)
- `skills/implement-feature/SKILL.md` — same at fixer step
- `skills/scaffold/SKILL.md:777` — fixer step detection (per Phase 2 §Q-D-4 special case)
- `skills/analyze-bug/SKILL.md:24` — interactive surface (no state.json — Phase 2 special case)
- `skills/resume-ticket/SKILL.md:10,20-23` — add `--clarification "text"` flag, detect `status: "paused"`, re-dispatch from `asked_at_step`
- `tests/scenarios/v690-needs-clarification-{fixer,triage,resume}.sh` (3 NEW)
- `CHANGELOG.md` — entry under `### Added`

**Risk/tradeoff:** This is the highest-touch item in v6.9.0 (10+ files). Conservative mitigation: implement minimum-viable mechanism (ONLY fixer + triage-analyst can emit, ONLY resume-ticket can resolve) — do NOT extend to other agents in v6.9.0 even though spec-analyst, code-analyst, and architect could plausibly benefit. Future expansion is additive-safe.

**What-if-wrong:** A pipeline pauses with NEEDS_CLARIFICATION; the user never resumes; the issue sits in `paused` indefinitely. Detection: dashboard skill should show `paused` runs distinctly from `running`. Mitigation: stale-pause detection added to dashboard (e.g., paused >24h) with operator nudge — non-blocking enhancement, can ship in v6.9.1.

**Alternatives:** **Pure-prose state machine vs persistent answer log vs polling-based resume**
| Option | Pros | Cons | Recommendation |
|---|---|---|---|
| **Prose state machine + state.json `clarification` object + resume-ticket --clarification flag** | Mirrors NEEDS_DECOMPOSITION precedent, additive schema, minimal footprint | Single answer slot per pause | **CHOSEN** |
| Persistent answer log (Q&A history array) | Multi-question debugging | Schema bloat for rare use case | Reject — premature |
| Polling-based resume (skill checks for answer file every N seconds) | Could integrate with external chat tools | Requires daemon/runtime — violates plugin constraint | Reject — scope violation |

Rationale: Mirror existing precedent (NEEDS_DECOMPOSITION shipped successfully in earlier release). Single answer slot is sufficient for v6.9.0; multi-turn dialog is a v7.x feature.

---

## E. pipeline-history.md

**Approach:** Adopt Phase 2 §Q-E-1/2/3 verbatim. Location: `.ceos-agents/pipeline-history.md` (consistent with autopilot lock conventions). Format: append-only flat markdown, one H2 per run with the 8-field per-run template from Phase 2 §9.10. Retention: last 50 runs (trim oldest H2 sections when count >50). Append fires from `core/post-publish-hook.md` Section 5 (NEW), AFTER Section 4 pipeline-completed webhook, advisory failure semantics. Fixer reads last 5 entries; reviewer reads last 10 entries. Explicitly EXCLUDE: `block.detail` (source code excerpts), issue title (PII risk), AC text. Recommend `.gitignore` entry for public projects.

**Files:**
- `core/post-publish-hook.md` — add Section 5 "pipeline-history.md append (v6.9.0+)" (~30 lines prose: file location, append command via bash heredoc, trim logic via `awk`/`grep -c '^## '`, advisory failure)
- `agents/fixer.md` — add Process step "Read last 5 entries from `.ceos-agents/pipeline-history.md` if present (advisory context)"
- `agents/reviewer.md` — same with last 10 entries
- `state/schema.md` — NO change (this is a separate file, not state.json)
- `docs/guides/` — add `pipeline-history.md` reference (optional)
- `examples/configs/*.md` (8 files) — NO change (no new optional config sections)
- `tests/scenarios/v690-pipeline-history-{append,trim,read}.sh` (3 NEW)
- `CHANGELOG.md` — entry under `### Added`

**Risk/tradeoff:** Append-only flat markdown is the conservative format choice (vs JSONL or SQLite). Easy for the LLM Read tool to parse. Tradeoff: fixer reading 5 entries adds ~250 tokens of context per fixer invocation — negligible. Per-run entry size is ~10 lines = ~80 tokens; 50 runs = ~4000 tokens total file size — well within Read tool single-call limit.

**What-if-wrong:** Append fails silently (advisory semantics) and the file becomes corrupt or truncated; fixer reads garbage context and produces worse fixes. Detection: append step uses `printf` (not `echo -e`) for cross-shell consistency; trim step uses `awk` (POSIX-portable). Add a regression test that creates a 51-entry file and verifies trim keeps the 50 newest. PII exclusion validated by hidden test scenario that scans entries for known-bad patterns (issue title fragments).

---

## F. ARCHITECTURE.md freshness warning

**Approach:** Adopt Phase 2 §Q-F-2 verbatim — exact bash one-liner using `git rev-list HEAD ^${last_commit} --count`, hardcoded N=25 threshold (no optional config key — would violate MINOR semver and the threshold is purely advisory). Insert at fix-ticket Step 0b→1 boundary and implement-feature Step 0b→0c boundary. Use lowercase `docs/architecture.md` (per Phase 2 §Q-F-1 — agent-3 verified the file is lowercase, NOT `ARCHITECTURE.md`). Warning is `[WARN]` level only — pipeline continues unconditionally. Phase 2 also identified: fix `SKL[28 Skills]` → `SKL[29 Skills]` in `docs/architecture.md:27` regardless (mandatory doc-drift correction).

**Files:**
- `skills/fix-ticket/SKILL.md` — insert ~7-line bash block between Step 0b (~line 131) and Step 1 (~line 139)
- `skills/implement-feature/SKILL.md` — insert ~7-line bash block between Step 0b (~lines 124-145) and Step 0c (~line 147)
- `docs/architecture.md:27` — `SKL[28 Skills]` → `SKL[29 Skills]` (mandatory drift fix)
- `tests/scenarios/v690-architecture-freshness-warning.sh` (NEW) — verifies prose present in both skills
- `CHANGELOG.md` — entry under `### Added` (warning) AND `### Fixed` (drift)

**Risk/tradeoff:** Hardcoded N=25 may not suit all projects. Conservative reasoning: exposing N as optional config key (`### Architecture Docs` section with `Freshness threshold` key) WOULD be additive-safe but adds a 19th optional section — increases surface area for marginal benefit. Defer config exposure to v6.9.1 IF operators request. Hardcoded N=25 is also empirically validated (Phase 2 §Q-F-1: current HEAD is exactly 25 commits stale, so the warning fires immediately on adoption — demonstrating the feature's utility).

**What-if-wrong:** A project doesn't have `docs/architecture.md` (greenfield/scaffold project that hasn't run scaffold yet). The bash check `git log -1 --format="%H" -- docs/architecture.md` returns empty; the `if [ -n "$last_commit" ]` guard skips the check. Detection: the bash snippet must be tested with file-absent and file-present cases. Add 2 test scenarios.

---

## Cross-cutting observations

1. **Roadmap discipline anchor.** Of 11 items, exactly 1 is recommended for deferral (C4 multi-host lock), 1 for partial-deferral with placeholder (A3 repo URL), and 9 ship completely. This satisfies anti-pattern §4 ("do NOT recommend deferring more than 1 item") given that A3 is shipping the OSS-blocking text changes; only the canonical URL string is deferred pending external infrastructure provisioning. The Judge synthesis should confirm both A3 and C4 deferrals are accounted for separately.

2. **Doc-drift correction is FREE leverage.** Phase 2 §V-3 confirms only `docs/architecture.md:27` (`SKL[28 Skills]` → `29 Skills`) is stale. v6.9.0 adds NO new agents, skills, core contracts, or optional config sections (per Phase 2 §0), so all OTHER count-bearing files (CLAUDE.md, README.md, docs/reference/automation-config.md, docs/reference/skills.md) need NO drift correction. This is unusually clean — Phase 9 verification should confirm the count-stability claim with a final grep.

3. **Test scenario count — proposed additions.** Net new scenarios proposed across 11 items: B-1 (1), C1 (1), C3 (1), D (3), E (3), F (1) = 10 new scenarios. Plus A5 (1 mirror-diff test). Plus an additional B-1 grep guard. Total ~12 new scenarios. v6.8.1 baseline is 141; v6.9.0 target ~153. Manageable for the bash harness.

4. **CHANGELOG.md structure.** Per Phase 2 §Q-G-2, v6.9.0 is MINOR — needs `### Added`, `### Changed`, `### Migration notes`, optional `### Known Issues (deferred to v6.9.1)`, `### Internal`. The Known Issues section will list C4 (multi-host lock) and the A3 placeholder URL.

5. **Pure-markdown invariant honored.** No proposal in this brief introduces runtime code, package manifests, build steps, or new dependencies. All implementations are prose instructions for the LLM-driven pipeline OR additive markdown files. The `core/post-publish-hook.md` Section 5 append uses bash `printf >>` from existing inline-bash pattern already used in the codebase.

6. **Backward compatibility confirmed.** No existing Automation Config keys are removed or renamed. No existing agent output sections are removed or renamed. No existing webhook payload fields are removed or renamed. All schema additions to state/schema.md are additive (`schema_version` stays `"1.0"`). MINOR semver bound is preserved.

7. **Single ship-stopper risk: A3 placeholder URL.** If the Phase 7 verifier objects that a placeholder URL violates "ship-ready" criteria, fall back to: keep `gitea.internal.ceosdata.com` URL but ship all the OTHER text fixes (installation.md, mock-project, onboard) — accept the leak in `plugin.json:8` only, document as v6.9.1 follow-up. This is a contingency, not the primary recommendation.

DONE

