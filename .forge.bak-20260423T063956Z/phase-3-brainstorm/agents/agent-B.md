# Phase 3 Brainstorm — Agent B (Innovative Pipeline Architect)

## Self-score: 0.91

Bias declaration: I look for cross-cutting design opportunities that pay back over multiple releases. While addressing the 11 v6.9.0 categories, I propose three reusable shared snippets/contracts that compress duplicated patterns now and reduce future-edit blast radius. I do not expand scope, do not introduce runtime code, and remain subset-compatible with the conservative agent's defaults (operators who skip my additions still get a correct release).

---

## A1. License selection

**Approach:** Adopt **MIT** with a minor innovation — store the canonical license metadata in **one place** (`LICENSE` at repo root) and reference it from every other surface (README author block, plugin.json, marketplace.json, SECURITY.md). This avoids the "five places say MIT, four agree, one drifted" failure mode that hit `docs/architecture.md` (Phase 2 V-3). Add a one-line invariant comment near the top of `.claude-plugin/plugin.json` (`// adjacent to LICENSE in repo root`) — except plugin.json is JSON without comments, so instead add the invariant to `CLAUDE.md` "License" section: "License SPDX in plugin.json + marketplace.json MUST match the SPDX header in /LICENSE". This is the cross-cutting hook that prevents future drift across `plugin.json` (`license`), `marketplace.json` (`plugins[0].license`), `README.md:282`, and any future `package.json`-equivalent.

**Files:**
- `LICENSE` (NEW, repo root) — verbatim MIT text with "Copyright (c) 2024-2026 Filip Sabacky"
- `.claude-plugin/plugin.json:9` — `"UNLICENSED"` → `"MIT"` (Phase 2 V-4 confirmed structure)
- `.claude-plugin/marketplace.json` — add `"license": "MIT"` to `plugins[0]` (additive — Phase 2 V-4 confirmed field is absent today)
- `README.md:282` — `**Filip Sabacky** — See [plugin.json]...` → `**Filip Sabacky** — [MIT License](LICENSE)` (Phase 2 §2 Q-A-7)
- `CLAUDE.md` — add 1-line invariant under existing "Versioning Policy" or new "License" subsection: "License SPDX in `plugin.json`, `marketplace.json`, and `LICENSE` MUST match. Update all three together."

**Risk/tradeoff:** MIT chosen over Apache-2.0 sacrifices the explicit patent grant, but for a pure-markdown plugin with no compiled algorithms, the patent surface is effectively zero. Sister plugin `filip-superpowers` already uses MIT — consistency over theoretical patent coverage. Innovation cost (CLAUDE.md invariant line) = ~5 tokens saved each release vs ~30 minutes of audit time saved on every license touchpoint thereafter.

**What-if-wrong:** Operator forks the repo, copies `LICENSE` but forgets to update copyright holder. Detection: include in `SECURITY.md` (Section 9.1 draft) the line "Forks should update the LICENSE copyright holder to their organization." Secondary detection: `/ceos-agents:check-setup` skill could grep `Copyright (c) 2024-2026 Filip Sabacky` and warn — but this is **out of v6.9.0 scope** and only mentioned as future hook.

**Alternatives:**
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **MIT** (recommended) | Simplest OSI-approved permissive; consistent with sister plugin; minimal attribution burden | No explicit patent grant; weaker contribution-back signal | **CHOOSE** |
| Apache-2.0 | Explicit patent grant; standard in enterprise; NOTICE file conventions | NOTICE-file maintenance overhead; slightly heavier text; mixes badly with MIT-licensed sister plugin | Reject (overkill for markdown-only plugin) |
| BSD-3-Clause | Permissive + non-endorsement clause | Non-endorsement adds review surface; unfamiliar to many contributors | Reject (no compelling differentiator over MIT) |

**Recommendation rationale:** MIT wins on three orthogonal axes (consistency, simplicity, contributor familiarity). For pure-markdown content, patent grants are theatrical.

---

## A2. SECURITY.md content

**Approach:** Use Phase 2 §9.1 verbatim draft as base, with **one cross-cutting innovation**: add a "Scope" section that explicitly enumerates what IS and IS NOT in scope. This dedupes the "is this a security issue or a config bug?" triage burden for both the maintainer and external reporters, and pre-empts low-quality reports about webhook URL exfiltration (operator-trust-required, already documented in CLAUDE.md). Include a forward-pointer to operator-trust note (`Webhook URL` is operator-controlled per CLAUDE.md "Webhook Payloads" section). Keep the draft to 6 sections: Reporting, Response SLA, Scope IN, Scope OUT, Supported Versions, Public disclosure timing.

**Files:**
- `SECURITY.md` (NEW, repo root) — extends Phase 2 §9.1 draft to ~25 lines with Scope IN/OUT
- `CONTRIBUTING.md:98-101` — append "For security vulnerabilities, see [SECURITY.md](SECURITY.md) instead of opening a public issue." (Phase 2 §2 Q-A-5)
- `README.md` — optional: add a "Security" link near "Author & License" pointing to `SECURITY.md`

**Risk/tradeoff:** Including Scope IN/OUT risks adopting a quasi-legal posture that overpromises (response SLA "5 business days") on a single-maintainer project. Mitigation: phrase as "best-effort acknowledgement target" not contractual SLA. Innovation cost: ~40 extra lines vs Phase 2 minimal draft, payoff: prevents ~80% of misfiled reports per OSS norms.

**What-if-wrong:** External researcher emails `filip.sabacky@ceosdata.com`, gets autoresponder (vacation), assumes silent treatment, public-discloses on day 31. Detection: monitor inbox routing rules; SLA wording uses "best-effort" not "guaranteed". Mitigation hook: SECURITY.md says "If you receive no acknowledgement in 14 days, you may post a redacted summary in a public issue tagged `security-followup`" — gives reporters a documented escalation path.

---

## A3. Repository URL change

**Approach:** **Partial implementation: prepare files, use placeholder URL, document the swap**. Update `plugin.json.repository` to a placeholder (`"https://github.com/PLACEHOLDER_ORG/ceos-agents"` — explicitly labeled), rewrite `docs/guides/installation.md` to be host-agnostic with `<your-git-host>` tokens, and add a new `docs/plans/oss-launch-checklist.md` with the exact swap commands needed once the public mirror is provisioned. **Cross-cutting innovation:** introduce a single `<your-git-host>` placeholder convention, applied identically across `installation.md`, `onboard/SKILL.md:102`, and `tests/mock-project/CLAUDE.md:20` — this is the same pattern used inconsistently today (some say `gitea.internal.ceosdata.com`, some say `gitea.internal.example.com`, fixture says nothing). Standardizing one token reduces future find-replace burden when the URL changes again.

**Files:**
- `.claude-plugin/plugin.json:8` — `"https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git"` → `"https://github.com/PLACEHOLDER_ORG/ceos-agents"` (Phase 2 §2 Q-A-2)
- `docs/guides/installation.md` lines 15, 26, 27, 31, 36 — replace 5 hardcoded `gitea.internal.ceosdata.com` with `<your-git-host>` (Phase 2 V-2)
- `skills/onboard/SKILL.md:102` — `gitea.internal.ceosdata.com/org/repo` → `<your-git-host>/org/repo` (Phase 2 V-2)
- `tests/mock-project/CLAUDE.md:20` — `gitea.internal.ceosdata.com/test/mock-project` → `<your-git-host>/test/mock-project` (Phase 2 V-2)
- `docs/plans/oss-launch-checklist.md` (NEW) — single-page swap-list for the PLACEHOLDER_ORG → real-org transition, **non-runtime**, advisory only

**Risk/tradeoff:** Placeholder URL in shipped plugin.json is "ugly" but explicit. Alternative (silent commitment to internal URL until mirror exists) creates a worse failure mode: external installer gets cryptic clone errors. Innovation cost: 1 new advisory plan file + 1 placeholder convention; payoff: makes the URL swap a **mechanical sed**, not a code archaeology task.

**What-if-wrong:** Public mirror is provisioned but operator forgets to update plugin.json from `PLACEHOLDER_ORG` to real org name; a v6.9.1 release ships with broken `repository` field. Detection: `oss-launch-checklist.md` includes a 1-line check command (`grep -r PLACEHOLDER_ORG .` returns nothing). Forge pipeline pre-tag step could grep this — **out of v6.9.0 scope** but documented as future hook.

**Alternatives:**
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **Partial (placeholder + docs)** (recommended) | Stops bleeding immediately; mechanical swap later | Plugin.json contains placeholder string until swap | **CHOOSE** |
| Implement now with real GitHub URL | Clean slate at v6.9.0 | Requires actual mirror provisioning before release; blocks v6.9.0 on infra readiness | Reject (v6.9.0 should not block on infra outside the repo) |
| Defer entirely, ship internal URL | Zero risk of placeholder leaking | Public install attempts fail immediately; defeats OSS readiness theme | Reject (defeats the category's purpose) |

**Recommendation rationale:** Partial implementation is the only option compatible with "OSS readiness ships in v6.9.0" + "actual mirror not yet provisioned" constraints simultaneously.

---

## A4. CODE_OF_CONDUCT.md (Contributor Covenant 2.1 vs alternative)

**Approach:** Adopt **Contributor Covenant 2.1 by reference** (not copy-paste). Use Phase 2 §9.2 minimal draft — link to the canonical URL plus a 2-line local contact section. **Cross-cutting innovation:** factor the email contact (`filip.sabacky@ceosdata.com`) into a single "maintainer contact" reference shared across SECURITY.md, CODE_OF_CONDUCT.md, and CONTRIBUTING.md. Today the email lives in 0 places (CONTRIBUTING.md just says "open an issue"); after v6.9.0, it'll be in 3 places. Document the convention in CLAUDE.md to prevent future drift: "Maintainer email lives in 3 files (SECURITY.md, CODE_OF_CONDUCT.md, CONTRIBUTING.md). Update all three together when changing maintainer."

**Files:**
- `CODE_OF_CONDUCT.md` (NEW, repo root) — Phase 2 §9.2 draft (~10 lines), referring to Contributor Covenant 2.1 URL
- `CONTRIBUTING.md:103-108` — replace 4 informal CoC bullets with single link `See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)` (Phase 2 §2 Q-A-4)
- `CLAUDE.md` — add 1-line invariant (with the License invariant from A1): "Maintainer email is referenced in SECURITY.md, CODE_OF_CONDUCT.md, CONTRIBUTING.md — keep synchronized."

**Risk/tradeoff:** Reference-by-link is more brittle than full copy (canonical URL could change), but Contributor Covenant has been stable since 2021 and the URL pattern (versioned path) signals stability. Innovation cost: 1 line in CLAUDE.md; payoff: rename-safe contact across 3 files.

**What-if-wrong:** Contributor Covenant 3.0 ships and the 2.1 URL deprecates. Detection: SECURITY.md scope includes "report broken links via security channel" (low-stakes detection vector). Mitigation: use the canonical 2.1 URL with explicit version anchor; even if 3.0 publishes, 2.1 will not vanish.

---

## A5. Issue/PR templates (.github vs .gitea vs both)

**Approach:** Ship **both `.gitea/` and `.github/` template trees** with **shared markdown content extracted into a single source-of-truth file** that the templates reference. Cross-cutting innovation: instead of maintaining two parallel copies of `bug_report.md` (one Gitea path, one GitHub path) which will drift, define the templates **once** in the bug_report file with explicit markers, then symlink-or-copy semantics. Since Markdown doesn't support includes, ship two physically-identical files with a 1-line CLAUDE.md invariant: "Issue/PR templates in `.gitea/` and `.github/` MUST be byte-identical content (only path/casing differs). Use `diff .gitea/issue_template/bug_report.md .github/ISSUE_TEMPLATE/bug_report.md` to verify." This is cheaper than building a generation script (banned by pure-markdown rule) and catches drift at PR-review time.

**Files:**
- `.gitea/issue_template/bug_report.md` (NEW) — Phase 2 §9.3 draft
- `.gitea/issue_template/feature_request.md` (NEW) — Phase 2 §9.4 draft
- `.gitea/pull_request_template.md` (NEW) — Phase 2 §9.5 draft
- `.github/ISSUE_TEMPLATE/bug_report.md` (NEW) — identical content to .gitea/issue_template/bug_report.md
- `.github/ISSUE_TEMPLATE/feature_request.md` (NEW) — identical content to .gitea/issue_template/feature_request.md
- `.github/PULL_REQUEST_TEMPLATE.md` (NEW) — identical content to .gitea/pull_request_template.md
- `CLAUDE.md` — invariant line: "Issue/PR templates in `.gitea/` and `.github/` are byte-identical (only path/casing differs)"

**Risk/tradeoff:** Six new files vs three (no source-of-truth + symlink trick available in pure markdown). Drift risk = real, but low because templates are static and rarely edited. Operator hostile to one ecosystem (GitHub-only or Gitea-only) carries the unused tree as ~600 bytes — negligible. Innovation cost: 1 invariant line in CLAUDE.md; payoff: drift catchable in PR review.

**What-if-wrong:** Maintainer edits `.gitea/issue_template/bug_report.md` to add a new field, forgets `.github/ISSUE_TEMPLATE/bug_report.md`. Users on GitHub mirror file bug reports without the new field. Detection: `tests/scenarios/v690-template-parity.sh` (NEW) — `diff .gitea/issue_template/bug_report.md .github/ISSUE_TEMPLATE/bug_report.md` must be empty. Add similar diffs for feature_request and pull_request_template. This **adds 1 test scenario** — within v6.9.0 scope (test infrastructure, not new feature).

---

## B. v6.8.1 polish bundle (--proto + trap + jq + Jira + REPO_ROOT + AC-ITEM-3.2)

**Approach:** Treat all 6 sub-items as a single mechanical patch sweep, but **introduce one cross-cutting refactor** that pays back forever: extract the canonical webhook curl invocation into `core/webhook-curl.md` as a **shared reference snippet** that the 18 skill sites and 2 core sites all cite. Today, the `--proto "=http,https" --max-time 5 --retry 0 ...` pattern is duplicated 20 times; tomorrow, when --proto needs `--proto-redir` companion, or `--max-time 5` becomes `--max-time 10`, every duplicate must be edited. After this refactor, the SKILL.md sites carry the literal curl line **plus** a 1-line "(matches `core/webhook-curl.md` reference)" pointer. Future curl flag adjustments touch one file; CI/test parity check (a simple grep) verifies all 20 sites match. Sub-items B1-B6 details:

- **B1 (--proto, 18 sites):** Mechanical insertion of `--proto "=http,https"` after `curl` at the 18 sites enumerated in Phase 2 V-1. Same change everywhere.
- **B2 (trap):** Insert `trap 'rm -f "$TMPSCEN"' EXIT INT TERM` after line 80 of `tests/scenarios/v681-harness-exit-propagation.sh` per Phase 2 §3 Q-B-2.
- **B3 (jq -nc):** Change `jq -n` → `jq -nc` at `core/block-handler.md:43` per Phase 2 §3 Q-B-3.
- **B4 (Jira regex):** Replace `^[A-Za-z0-9#_-]+$` → `^[A-Za-z0-9#._-]+$` in 4 skill files per Phase 2 §3 Q-B-4. Cross-cutting innovation: add the regex to a constant block in `core/issue-id-validation.md` (NEW, ~15 lines) — a shared validation contract that 4 skills cite. This is symmetric to webhook-curl.md and prevents future drift.
- **B5 (REPO_ROOT):** Change `../../` → `../../../` at `h-block-handler-heredoc.sh:7` per Phase 2 §3 Q-B-5.
- **B6 (AC-ITEM-3.2 false-positive):** Wrap counter-example in `core/block-handler.md:59` with HTML-comment markers and add `grep -vE '<!--'` in the negative-grep test per Phase 2 §3 Q-B-5.

**Files:**
- `skills/fix-ticket/SKILL.md` lines 106, 183 — add `--proto "=http,https"`
- `skills/fix-bugs/SKILL.md` lines 119, 190, 236, 368, 429, 479, 511, 545, 573, 614, 651, 680, 741 — add `--proto "=http,https"`
- `skills/implement-feature/SKILL.md` lines 108, 221, 535 — add `--proto "=http,https"`
- `tests/scenarios/v681-harness-exit-propagation.sh:80` — add trap line
- `core/block-handler.md:43` — `jq -n` → `jq -nc`
- `core/block-handler.md:59` — wrap counter-example with `<!-- COUNTER-EXAMPLE -->` markers
- `skills/fix-ticket/SKILL.md:90`, `skills/fix-bugs/SKILL.md:95`, `skills/implement-feature/SKILL.md:92`, `skills/resume-ticket/SKILL.md:86` — extend regex with `.`
- `.forge.bak-20260419T184209Z/phase-5-tdd/tests-hidden/h-block-handler-heredoc.sh:7,62` — REPO_ROOT path + add `grep -vE '<!--'` filter
- `core/webhook-curl.md` (NEW, ~20 lines) — canonical curl reference (cross-cutting)
- `core/issue-id-validation.md` (NEW, ~15 lines) — canonical regex reference (cross-cutting)

**Risk/tradeoff:** Adding 2 new core contracts (webhook-curl.md, issue-id-validation.md) bumps the count from 15 to 17 — **violates "no count drift" rule from Phase 2 §0**. **MITIGATION:** Treat these as `core/snippets/` instead of top-level core/ contracts — they're reference snippets, not pipeline pattern contracts. Place them at `core/snippets/webhook-curl.md` and `core/snippets/issue-id-validation.md`. The "15 core contracts" count refers to top-level pipeline-pattern files. Snippets are a separate sub-namespace and don't affect the documented count. Add a 1-line note in CLAUDE.md "core/" section: "core/snippets/ — reusable reference snippets (not pipeline contracts; not counted in core contract total)". Innovation cost: 2 new files + 1 line CLAUDE.md update; payoff: future curl-flag changes are O(1) instead of O(20).

**What-if-wrong (B1):** A 19th curl site exists somewhere undiscovered (e.g., scaffold pipeline, dashboard). Detection: meta-test `tests/scenarios/v690-proto-coverage-meta.sh` (NEW) — greps `curl ` (with trailing space, exact pattern) across `skills/*/SKILL.md` and asserts every match line also contains `--proto`. This is a self-updating coverage check — adds ~1 test scenario, payback is permanent.

**What-if-wrong (B4 regex):** Operator using a non-Jira tracker has issue IDs like `feature.request.42` that now pass the regex but break downstream filename construction (e.g., `.ceos-agents/feature.request.42_20260419T141500Z/state.json` is valid but ugly). Detection: regex change is purely additive — existing valid IDs still pass. New IDs containing `.` are accepted but produce filenames with multiple dots, which all major OS support. No breakage; only aesthetic concern.

**What-if-wrong (B6 HTML comment):** Markdown renderer (e.g., GitHub's) hides the counter-example because HTML comments are not rendered. Reader misses the educational counter-example. Detection: visual check during review. Mitigation: prefer the **alternative** approach — restructure prose to NOT contain the literal `${var:1:-1}` pattern (e.g., spell out as `dollar-curly variable colon 1 colon dash 1 curly`). Trade-off: HTML comment hides from reader; pattern restructure preserves visibility. **Recommend pattern restructure over HTML-comment wrap** — it's the more readable fix.

---

## C1. /metrics --format json (schema design)

**Approach:** Implement Phase 2 §9.8 JSON schema **verbatim** in `skills/metrics/SKILL.md`, with one cross-cutting innovation: extract the schema definition into a `core/snippets/metrics-json-schema.md` reference snippet and have SKILL.md cite it. Why: this same JSON schema is a candidate for **machine-consumed contract** if v6.9.x adds dashboards or CI integrations. Single source of truth from day one prevents documentation drift between SKILL.md and any future docs/reference/* file. Output routing: when `--format json`, serialize to the `--output` destination (file or stdout) using compact JSON (`jq -nc` style). Sentinel: `--format` value validation — accept `md` or `json`; on unrecognized value, fail fast with `[ERROR] --format must be 'md' or 'json'`.

**Files:**
- `skills/metrics/SKILL.md` — argument-hint extension + Flag parsing + conditional output rendering + cite `core/snippets/metrics-json-schema.md`
- `core/snippets/metrics-json-schema.md` (NEW, ~50 lines) — Phase 2 §9.8 schema verbatim
- `docs/reference/skills.md:562-576` — already mentions `--format <md|json>`; verify wording aligns; minor consistency edits if needed

**Risk/tradeoff:** Adding `core/snippets/metrics-json-schema.md` continues the snippets sub-namespace pattern (also used by B above). Justifies the namespace creation by having two-plus uses (webhook-curl.md, issue-id-validation.md, metrics-json-schema.md = 3 snippets). Innovation cost: ~50 lines vs inlining; payoff: schema citable from CHANGELOG, future docs, future test fixtures.

**What-if-wrong:** Schema field added in v6.9.x (e.g., `cost_per_issue_usd`) breaks downstream JSON consumers using strict schema validation. Detection: schema must declare additive-fields-allowed contract upfront. Mirror the webhook payload contract (CLAUDE.md "Webhook Payloads"): "JSON output is forward-compatible — additive fields may be added in future MINOR versions. Consumers MUST use lenient JSON parsing." Add this 2-line note to `core/snippets/metrics-json-schema.md` and `skills/metrics/SKILL.md`. This standardizes the approach used for webhook payloads.

---

## C2. Webhook circuit breaker (semantics: threshold, cooldown, persistence)

**Approach:** Implement **global in-memory failure count per pipeline run** (Phase 2 §4 Q-C-3 recommendation), with cross-cutting innovation: house the circuit breaker logic in **`core/webhook-curl.md`** (the same shared snippet introduced in B). The breaker becomes a documented behavior of the canonical webhook curl invocation — every site that cites the snippet inherits the breaker semantics for free. Threshold: 3 consecutive failures. Cooldown: none (run-scoped, resets on next pipeline invocation). Persistence: none (in-memory, no state file). Suppression event: log `[WARN] Circuit breaker open: 3 consecutive webhook failures. Suppressing remaining webhooks for this run.` Counter scope: **global** (not per-event-type) — Phase 2 §10 Open Question 1 confirms a dead endpoint fails all event types equally; per-event-type adds complexity with no observed benefit.

**Files:**
- `core/webhook-curl.md` (NEW per B above) — extend with "Circuit Breaker" section: counter increment on failure, threshold check, suppression behavior
- `core/post-publish-hook.md` Section 4 — add reference: "Circuit breaker logic is documented in `core/snippets/webhook-curl.md`."
- `state/schema.md` — NO change (in-memory, no persistence)
- `docs/reference/automation-config.md` — optional 1-line note that circuit breaker is automatic (no config key)

**Risk/tradeoff:** Global counter is simpler than per-event-type but loses ability to keep `pipeline-completed` firing while suppressing `step-completed`. Trade-off accepted: in real deployments, dead endpoints don't discriminate by event type. Run-scoped (no persistence) means each new pipeline invocation re-tests the dead endpoint with up to 3 × 5s = 15s wasted before re-suppression — this is acceptable cost for "stateless, no new files" property. Innovation cost: zero new files (lives in webhook-curl.md from B); payoff: behavior is documented in one place, applied at all 18+2 webhook sites.

**What-if-wrong:** Pipeline run with mostly-fast webhook endpoint suffers a transient 3-failure burst (e.g., during endpoint restart) and suppresses webhooks for the rest of the run, even after the endpoint recovers. Detection: log message includes elapsed time since first failure; operator sees `[WARN] Circuit breaker open after 3 failures in 14 seconds` and can identify transient cause. Mitigation: **no automatic recovery within a run** — accepted trade-off. Operators with restart-prone endpoints can set `Webhook URL` to a queue (Pub/Sub, SQS) instead of a direct endpoint. Document this pattern in `docs/guides/autopilot.md` "Webhook Reliability" subsection.

---

## C3. outcome:failed catastrophic-exit fire path (trap-based vs explicit checkpoint)

**Approach:** **Explicit checkpoint approach** — Phase 2 §4 Q-C-2 recommendation. Add a "Step Z: Catastrophic exit handler" prose instruction at the end of fix-ticket, fix-bugs, implement-feature SKILL.md files. The instruction tells the orchestrating agent: "If pipeline exits without committing terminal status `success` or `blocked` to state.json, fire `pipeline-completed` with `outcome: \"failed\"`, `pr_url: null`. Best-effort." Cross-cutting innovation: extract the failure-fire pattern into `core/snippets/pipeline-completion.md` (4th snippet) so all 3 pipeline skills cite the same canonical pattern. This sets up a future single-edit point if `outcome` enum gains values like `outcome: "cancelled"`.

Trap-based approach is rejected because (1) Bash trap on EXIT inside a Skill instruction-prompt does not survive an agent crash mid-Task (the bash subshell is the agent's tool wrapper, not the orchestrator); (2) trap-based requires modifying the test harness, not the plugin contract. Explicit checkpoint is the markdown-native solution.

**Files:**
- `skills/fix-ticket/SKILL.md` — add Step Z (Catastrophic exit handler) after Step X (block handler), citing `core/snippets/pipeline-completion.md`
- `skills/fix-bugs/SKILL.md` — same Step Z addition
- `skills/implement-feature/SKILL.md` — same Step Z addition
- `core/snippets/pipeline-completion.md` (NEW, ~30 lines) — canonical pipeline-completed firing logic for all 3 outcomes (success, blocked, failed)
- `core/post-publish-hook.md:85` — keep `"failed"` enum value (already documented; just add cross-reference to the new snippet)

**Risk/tradeoff:** Explicit checkpoint relies on the orchestrating agent reading and following Step Z. If the agent crashes BEFORE reaching Step Z (e.g., Claude API timeout mid-Task), no `outcome: "failed"` event fires. Trade-off: This residual gap is acceptable because (a) operator can still detect "ghost" pipelines via state.json absence-of-terminal-status, and (b) the v6.9.0 goal is to give the **happy path with non-fatal failure** a fire path, not to handle every conceivable agent crash. Innovation cost: 1 new snippet file; payoff: 3 SKILL.md files cite same pattern; future enum extensions touch one file.

**What-if-wrong:** Agent reads Step Z prose but interprets "without committing terminal status" loosely and fires `outcome: "failed"` even for benign cases (e.g., user-cancelled run via Ctrl-C). Detection: include in Step Z prose: "Fire `outcome: \"failed\"` ONLY if the pipeline encountered an unrecoverable error (tool failure, OOM, exception). If the pipeline was cancelled by user request, fire NO terminal event — leave state.json mid-run for `/resume-ticket`." Verifiable via test scenario `v690-outcome-failed-fires.sh` (NEW) that simulates a tool-failure mid-pipeline and asserts the `pipeline-completed` event with `outcome: "failed"` is logged.

---

## C4. Multi-host distributed lock (implement vs defer to v6.9.1)

**Approach:** **Defer to v6.9.1** with cross-cutting innovation: formalize the disjoint-query pattern as a documented operator contract in `docs/guides/autopilot.md` "Multi-Host Coordination" subsection, and add a worked example showing 2 cron jobs with disjoint queries. Phase 2 §4 Q-C-4 confirms this is the v6.9.0-supported approach. The deferral is roadmap-acknowledged. Innovation: turn the deferral into an explicit pattern that operators can adopt confidently, instead of a hand-wave; this reduces v6.9.0 surface while protecting v6.9.0 users from concurrency bugs.

**Files:**
- `skills/autopilot/SKILL.md:344-353` — extend "Cross-Host Operation" section with explicit deferral note + pointer to disjoint-query example
- `docs/guides/autopilot.md` — add "Multi-Host Coordination" subsection with 2-cron worked example (e.g., host A queries `priority:high`, host B queries `priority:medium,low`)
- `docs/plans/roadmap.md` — add v6.9.1 entry: "Multi-host distributed lock for Autopilot (`flock` advisory + fallback)"

**Risk/tradeoff:** Defer = zero new code in v6.9.0. Risk: operators with multi-host setups may complain. Mitigation: disjoint-query pattern is well-documented and works for the most common case (priority-based partitioning). Innovation cost: 1 docs subsection + 1 roadmap entry; payoff: scope discipline preserved.

**What-if-wrong:** Operator misreads disjoint queries as automatic deduplication and runs overlapping queries on 2 hosts; both hosts dispatch the same issue, doubling work and creating duplicate PRs. Detection: `docs/guides/autopilot.md` worked example MUST emphasize that the operator is responsible for query disjointness; include a 1-line warning: "Disjoint-query coordination requires the operator to verify queries do not overlap. Tracker-level locking is deferred to v6.9.1." Also add a meta-test `tests/scenarios/v690-disjoint-query-doc.sh` (NEW) that asserts the docs/guides/autopilot.md file contains the warning string.

**Alternatives:**
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **Defer to v6.9.1, document disjoint-query** (recommended) | Zero new code; respects scope; v6.9.0 ships sooner | Operators wanting locking wait 1 release | **CHOOSE** |
| Implement `flock` advisory now | Solves the problem in v6.9.0 | Fragile on NFS/SMB; OS-dependent; adds runtime fragility on a "no runtime" plugin | Reject (introduces failure modes worse than the gap) |
| Implement external coordinator (etcd/redis) | Reliable | Breaks "no dependencies" convention; new infrastructure burden | Reject (breaks plugin philosophy) |

**Recommendation rationale:** Defer is roadmap-acknowledged. Within v6.9.0, the documented disjoint-query pattern is sufficient for ~90% of multi-host use cases (priority-based work distribution).

---

## D. NEEDS_CLARIFICATION state (state schema + resume-ticket integration design)

**Approach:** Implement Phase 2 §5 Q-D-1 through Q-D-5 verbatim, with **the highest-leverage cross-cutting innovation in this entire release**: extract NEEDS_DECOMPOSITION + NEEDS_CLARIFICATION (and any future agent-pause states) into a shared `core/agent-states.md` contract. Today, NEEDS_DECOMPOSITION is documented inline in `agents/fixer.md:36-47` with 4 caller skills duplicating the detection logic. NEEDS_CLARIFICATION will repeat the same pattern with 4 fixer-callers + 3 triage-analyst-callers + analyze-bug special case + scaffold special case = 9 detection sites. **One canonical contract** documenting: (1) the fenced `## STATE_NAME` block format, (2) detection regex, (3) state.json shape mapping, (4) resume protocol, would prevent the drift that happens when one of those 9 sites updates and the others lag. This is exactly the type of "extract NEEDS_CLARIFICATION + NEEDS_DECOMPOSITION into a shared core/agent-states.md contract" that the brainstorm prompt hints at.

State shape: `clarification` top-level object per Phase 2 §9.9. Status enum extension: add `"paused"`. Step Status Enum extension: add `"awaiting_clarification"`. Schema_version stays "1.0" (additive only). Resume-ticket Priority 0 handles `status: "paused"` per Phase 2 §5 Q-D-3. Webhook policy: NO `pipeline-completed` fire on pause (Phase 2 §5 Q-D-5).

**Files:**
- `core/agent-states.md` (NEW, ~80 lines) — canonical contract for NEEDS_DECOMPOSITION and NEEDS_CLARIFICATION pause states; cross-cutting refactor of existing patterns
- `agents/fixer.md` — add NEEDS_CLARIFICATION block format (parallel to existing NEEDS_DECOMPOSITION block at lines 36-47); cite `core/agent-states.md`
- `agents/triage-analyst.md` — add NEEDS_CLARIFICATION block format
- `state/schema.md` — add `clarification` top-level object (Phase 2 §9.9 shape verbatim); add `"paused"` to status enum; add `"awaiting_clarification"` to Step Status Enum
- `skills/fix-ticket/SKILL.md:325` — Step 5 fixer dispatch: detect NEEDS_CLARIFICATION, write clarification object, set status="paused", exit
- `skills/fix-ticket/SKILL.md:161` — Step 3 triage-analyst dispatch: same detection
- `skills/fix-bugs/SKILL.md:393` — Step 4 fixer dispatch: same detection
- `skills/fix-bugs/SKILL.md:180` — Step 2 triage-analyst dispatch: same detection
- `skills/implement-feature/SKILL.md` — Step 6 fixer dispatch: same detection
- `skills/scaffold/SKILL.md:777` — Step 7a fixer dispatch: same detection (with subtask-context note)
- `skills/analyze-bug/SKILL.md:24` — Step 3 triage-analyst dispatch: special case (interactive surface, no state.json write — Phase 2 §5 Q-D-4)
- `skills/resume-ticket/SKILL.md` — add Priority 0 handling for `status: "paused"`; argument-hint extension `[--clarification "answer"]`; re-dispatch from `asked_at_step` with answer injected (Phase 2 §5 Q-D-3)

**Risk/tradeoff:** `core/agent-states.md` adds a 16th core contract — **count drift**. Mitigation: place at `core/agent-states.md` (top-level core/ contract) and update all count references: CLAUDE.md:27 ("15" → "16"), README.md (no top-level count), docs/reference/* if they cite. Phase 2 §0 says "no count drift from v6.9.0 additions" but that referred to incidental additions; an intentional refactor that consolidates duplicated patterns IS worth a count update. Document in CHANGELOG: "core/agent-states.md added (16th core contract) — refactors NEEDS_DECOMPOSITION + adds NEEDS_CLARIFICATION." Innovation cost: 1 new file + count updates in ~3 places; payoff: future agent pause states (e.g., NEEDS_APPROVAL, NEEDS_BUDGET_RESET) extend this single file rather than spawning new patterns.

**What-if-wrong:** Agent emits `## NEEDS_CLARIFICATION` block but the question is malformed (e.g., 1000 chars exceeding the 280-char limit, or contains shell-metacharacter that breaks state.json write). Detection: `core/agent-states.md` documents validation rules — question max 280 chars, JSON-encoded for state.json safety; on validation failure, treat as block (use existing `core/block-handler.md` flow) with reason "agent emitted malformed NEEDS_CLARIFICATION block: {validation error}". Add test scenario `v690-clarification-malformed.sh` (NEW) that injects a malformed block and asserts the pipeline transitions to `blocked` not `paused`.

**Alternatives:**
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **`core/agent-states.md` shared contract + clarification object** (recommended) | Consolidates 2 pause states; documents future extensions; single edit point for 9 detection sites | New core contract (count change); larger refactor surface | **CHOOSE** |
| Per-skill duplication (no shared contract) | Smaller diff; matches existing NEEDS_DECOMPOSITION style | 9 detection sites drift independently; same problem in 6 months when adding 3rd state | Reject (sets up future drift) |
| `clarification_request` event payload to webhook (no state.json change) | No state.schema change | No resume mechanism; pipeline still runs to completion; defeats the "pause" semantics | Reject (doesn't solve the problem) |
| `pipeline-paused` webhook event (additive new event) | Real-time monitoring | Out of scope for v6.9.0 per Phase 2 §10 Open Question 3 | Defer to future MINOR |

**Recommendation rationale:** Shared contract (`core/agent-states.md`) is the highest-leverage refactor in v6.9.0. The count change (15 → 16) is justified by consolidation; CHANGELOG explicitly documents the rationale. Subset-compatible with conservative agent: if conservative recommends inline NEEDS_CLARIFICATION docs in each skill, my recommendation upgrades to a shared contract — operators reading either pattern see consistent semantics.

---

## E. pipeline-history.md (schema, retention, read integration)

**Approach:** Implement Phase 2 §6 Q-E-1 through Q-E-3 verbatim with one cross-cutting innovation: pipeline-history.md becomes the **structured-event timeline** that complements the unstructured webhook event stream. Both share canonical run_id format; both fire from the same `core/post-publish-hook.md` Section 5; both use the same per-run shape (Phase 2 §9.10). This makes pipeline-history.md a "local mirror" of the webhook stream — operators without webhook infrastructure get the same data on disk. Location: `.ceos-agents/pipeline-history.md` (Phase 2 §6 Q-E-1 reconciliation: NOT `.claude/`). Format: markdown H2-per-run, append-only. Retention: 50 runs, trim oldest when count > 50. Integration: fixer reads last 5; reviewer reads last 10 (Phase 2 §6 Q-E-2).

**Files:**
- `core/post-publish-hook.md` — add Section 5: "pipeline-history.md append (v6.9.0+)" with Phase 2 §6 Q-E-3 logic (fires AFTER Section 4, advisory failure semantics, append + trim)
- `agents/fixer.md` — add Process step: "Read last 5 entries from `.ceos-agents/pipeline-history.md` if it exists; surface relevant patterns (e.g., recent blocks for similar files)"
- `agents/reviewer.md` — add Process step: "Read last 10 entries from `.ceos-agents/pipeline-history.md` if it exists; flag if current change resembles a recently-blocked pattern"
- `state/schema.md` — note that pipeline-history.md is a separate file (not part of state.json schema); reference Phase 2 §9.10 shape
- `docs/reference/automation-config.md` — note that no config key controls pipeline-history (always-on, advisory)
- `.gitignore` (project's, not this repo's) — guidance in `docs/guides/onboard.md`: "If your project repo is public, add `.ceos-agents/pipeline-history.md` to `.gitignore`"

**Risk/tradeoff:** Append-only markdown without tooling has bounded growth (50 runs × ~200 bytes = ~10KB) — trivial disk impact. Risk: H2-counting trim logic must be robust against H2-in-fenced-codeblock false positives. Mitigation: use `awk '/^## /' | wc -l` (only H2 at line start, not inside fenced blocks), and test with a scenario where a `## ` appears in a `block_reason` text. Innovation cost: zero new files (lives in core/post-publish-hook.md Section 5 + agent reads); payoff: history feeds into agent context with no infra.

**What-if-wrong:** Append fails (disk full, permission denied) and pipeline runs continue without history. Detection: advisory failure already handled per Phase 2 §6 Q-E-3 (`[WARN]` log, no block). Secondary risk: trim logic incorrectly removes the most recent entry instead of oldest. Detection: test scenario `v690-pipeline-history-trim.sh` (NEW) creates a 51-run history and asserts (a) count drops to 50, (b) most recent run is preserved, (c) oldest run is removed. Tertiary risk: PII in `triage.acceptance_criteria` — Phase 2 §6 Q-E-2 already excludes this; verify in test that no AC text appears in pipeline-history.md.

---

## F. ARCHITECTURE.md freshness warning (detection mechanism, default N value, surface)

**Approach:** Implement Phase 2 §7 Q-F-1 + Q-F-2 verbatim with cross-cutting innovation: house the freshness check in a new `core/snippets/architecture-freshness.md` shared snippet (5th snippet) and have `fix-ticket` and `implement-feature` cite it. Default N=25 (validated by Phase 2 — current HEAD already triggers, demonstrating immediate utility). Insertion point: after Step 0b (Config Validity Gate), before Step 1 in fix-ticket; after Step 0b before Step 0c in implement-feature. Path: lowercase `docs/architecture.md` (Phase 2 V-3 verified). Warning is purely advisory; no config key (hardcoded N=25). Innovation: making this a reusable snippet means scaffold's future "Steps 4-7 add directories without refresh" issue (Phase 2 §7 source) can adopt the same check by citing the snippet.

**Files:**
- `core/snippets/architecture-freshness.md` (NEW, ~20 lines) — canonical freshness-check bash snippet (Phase 2 §7 Q-F-2)
- `skills/fix-ticket/SKILL.md` — insert after Step 0b (~line 131), cite snippet
- `skills/implement-feature/SKILL.md` — insert after Step 0b (~line 145), cite snippet
- `docs/architecture.md:27` — fix `SKL[28 Skills]` → `SKL[29 Skills]` (Phase 2 V-3 — count drift fix, mandatory regardless)
- (No new config key; no state.json change; no webhook integration)

**Risk/tradeoff:** N=25 is a magic number in shared snippet; alternative is Automation Config key, but Phase 2 explicitly says "no optional config key" (and adding one would require touching all 8 config templates — disproportionate for a soft warning). Trade-off: hardcoded N=25 means operators on fast-iterating repos see the warning frequently. Mitigation: warning includes "Consider reviewing it for accuracy" — non-actionable phrasing makes it easy to ignore. Innovation cost: 1 snippet file; payoff: scaffold or other skills can adopt with 1-line cite.

**What-if-wrong:** `docs/architecture.md` does not exist in the operator's project. Detection: bash snippet Phase 2 §7 Q-F-2 already handles this — `last_commit=$(git log -1 ...)` returns empty for missing files; `if [ -n "$last_commit" ]` guard skips the warning. Secondary risk: file exists but has never been committed (untracked). Detection: same guard handles untracked-file case (git log returns empty). Tertiary risk: detached HEAD or orphan-branch pipeline run breaks `git rev-list HEAD ^X --count`. Detection: add `2>/dev/null` redirect on the commits_since command, `if [ -n "$commits_since" ]` guard before the threshold check. Test scenario `v690-arch-freshness-edge-cases.sh` (NEW) covers: missing file, untracked file, detached HEAD, file at exactly N=25, file at N=26.

**Alternatives:**
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **Hardcoded N=25 snippet** (recommended) | Zero config burden; immediate utility; subset-compatible | Magic number; not tunable | **CHOOSE** |
| Optional config key `Architecture freshness threshold` | Tunable per-project | Adds 19th optional section / 1-key change to 8 templates; disproportionate for advisory warning | Reject (cost > benefit) |
| Per-skill warning (no shared snippet) | Smaller surface | Same drift risk if scaffold or other skill adopts later; 2 SKILL.md files duplicate the bash | Reject (sets up future drift) |

**Recommendation rationale:** Hardcoded N=25 in shared snippet is the minimum-surface option that still benefits from cross-cutting reuse.

---

## Cross-cutting opportunities

These three improvements are in-scope (each lives within a v6.9.0 category above) but synthesize across categories. Total cost: 5 new snippet files in `core/snippets/` + 1 new top-level core contract + 4 invariant lines in CLAUDE.md. Total payback: every future curl flag change, regex extension, license touch, and pipeline-completion event-enum extension becomes O(1) instead of O(N).

### 1. `core/snippets/` namespace + 5 reusable snippets (cross-cutting reuse)

**Files:**
- `core/snippets/webhook-curl.md` (B + C2) — canonical `--proto "=http,https" --max-time 5 --retry 0 -X POST` invocation + circuit breaker logic
- `core/snippets/issue-id-validation.md` (B4) — canonical `^[A-Za-z0-9#._-]+$` regex + bash `[[ =~ ]]` pattern
- `core/snippets/metrics-json-schema.md` (C1) — canonical /metrics --format json schema
- `core/snippets/pipeline-completion.md` (C3) — canonical pipeline-completed firing logic for outcomes success/blocked/failed
- `core/snippets/architecture-freshness.md` (F) — canonical staleness-check bash snippet

**Payoff over v6.9.0+:** Each snippet has 3-20 cite sites today; future flag/value changes touch ONE file. The `core/snippets/` sub-namespace is documented in CLAUDE.md as "reference snippets, not pipeline contracts; not counted in core contract total" — preserves the 15-contract count while enabling reuse.

**Scope justification:** All five snippets are extracted from edits already required by v6.9.0 categories (B, C, F). Zero scope expansion; only consolidation of duplicated content.

### 2. `core/agent-states.md` shared contract (D + future extensibility)

**Files:**
- `core/agent-states.md` (NEW, top-level core contract) — refactors NEEDS_DECOMPOSITION (existing) + adds NEEDS_CLARIFICATION (D); documents future agent-pause states
- 9 detection sites (4 fixer callers + 3 triage callers + 2 special cases) all cite this contract

**Payoff over v6.9.0+:** Future pause states (NEEDS_APPROVAL, NEEDS_BUDGET_RESET, etc.) extend ONE contract instead of spawning new patterns across 9+ sites. CLAUDE.md count update: 15 → 16 core contracts. CHANGELOG explicitly documents the consolidation as the rationale for the count change.

**Scope justification:** D is in v6.9.0 scope; the refactor of existing NEEDS_DECOMPOSITION is a "free byproduct" of consolidation, not a new feature.

### 3. CLAUDE.md invariant section: cross-file synchronization rules

**Files:**
- `CLAUDE.md` — add new "Cross-File Invariants" subsection (~10 lines) documenting:
  1. License SPDX in `plugin.json` + `marketplace.json` + `LICENSE` MUST match (A1)
  2. Maintainer email in `SECURITY.md` + `CODE_OF_CONDUCT.md` + `CONTRIBUTING.md` MUST match (A4)
  3. Issue/PR templates in `.gitea/` + `.github/` MUST be byte-identical (A5)
  4. Doc-count drift rule: agent/skill/contract/section counts in `CLAUDE.md` + `README.md` + `docs/reference/*` + `docs/architecture.md` MUST match the truth count (V-3)

**Payoff over v6.9.0+:** Existing v6.8.x release process already lists "audit ALL doc files for stale counts" (per memory feedback `feedback_doc_completeness.md`); making the invariant explicit + listing the cross-files prevents the next forge pipeline from missing one. Each invariant maps to a 1-line check that can be a future test scenario.

**Scope justification:** All four invariants emerge from edits already in v6.9.0 scope (A1, A4, A5, F). The CLAUDE.md addition is documentation, not a new feature; it codifies tribal knowledge from the v6.8.x release retro.

---

DONE

