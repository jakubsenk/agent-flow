# Phase 2 Research Answers — Agent 1 (Categories A, B, C)

## Self-score: 0.93

---

### A — OSS Readiness

**A-A-1.** SPDX identifier to replace `"UNLICENSED"` and marketplace.json licensing.

- Evidence:
  - `.claude-plugin/plugin.json:9`: `"license": "UNLICENSED"`
  - `.claude-plugin/marketplace.json:1-14`: No `license` field anywhere in the file; schema contains only `name`, `owner`, `plugins[].name`, `plugins[].source`, `plugins[].description`, `plugins[].version`.
  - `/c/gitea_filip-superpowers/.claude-plugin/plugin.json:9`: `"license": "MIT"` — sister plugin uses MIT.
- Inference: `marketplace.json` has no `license` field and likely has no defined schema requiring one; however, for OSS go-live consistency it should receive an additive `license` field matching `plugin.json`.
- Recommendation: **MIT**. Rationale: (1) Sister plugin filip-superpowers already uses MIT; consistent convention across the same author's plugins avoids confusion. (2) MIT is the simplest OSI-approved permissive license — no patent-grant complexity (Apache-2.0 is only needed if patent-grant is specifically desired), no additional conditions beyond attribution (BSD-3-Clause adds a non-endorsement clause that MIT omits without loss). For a pure-markdown plugin with no compiled code, MIT's minimal friction is the right fit.
- Action: Set `plugin.json:"license": "MIT"`. Add `"license": "MIT"` to `marketplace.json.plugins[0]` (additive, no schema breakage).

---

**A-A-2.** Public mirror URL status.

- Evidence:
  - `.claude-plugin/plugin.json:8`: `"repository": "https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git"` — internal hostname, not publicly reachable.
  - `docs/plans/roadmap.md:756`: "Repository URL — `plugin.json.repository` currently points at internal `gitea.internal.ceosdata.com`; update to public mirror (GitHub / public Gitea) once the repo is mirrored."
  - `docs/plans/roadmap.md:762`: "Impact: MINOR (additive files + metadata change)."
- Inference: No public mirror has been provisioned (the roadmap says "once the repo is mirrored" — conditional future tense). There is no evidence of a GitHub URL anywhere in the repo.
- Recommendation: The URL update is NOT a hard blocker for the v6.9.0 commit itself — the plugin functions without a publicly reachable `repository` field (it is metadata only). However, `docs/guides/installation.md` describes Gitea-specific SSH/HTTPS setup and WILL be broken for external users until rewritten. Recommend: (a) update `plugin.json.repository` to a placeholder `"https://github.com/YOUR_ORG/ceos-agents"` to indicate intent; (b) rewrite `docs/guides/installation.md` to be host-agnostic (clone from any git URL); (c) raise as **Q-USER-2** (deferred until mirror is provisioned).

---

**A-A-3.** Internal hostname occurrences in user-facing files.

- Evidence:
  - `docs/guides/installation.md:15`: `"The plugin is hosted on \`gitea.internal.ceosdata.com\`."` — prose assumption, breaks external users.
  - `docs/guides/installation.md:26-27`: SSH config block hardcodes `Host gitea.internal.ceosdata.com` / `HostName gitea.internal.ceosdata.com`.
  - `docs/guides/installation.md:31`: `git ls-remote git@gitea.internal.ceosdata.com:fsabacky/ceos-agents.git` — exact command with internal hostname.
  - `docs/guides/installation.md:36`: `git ls-remote https://<TOKEN>@gitea.internal.ceosdata.com/fsabacky/ceos-agents.git` — exact command with internal hostname.
  - `skills/onboard/SKILL.md:102`: `"Remote hostname + owner/repo (e.g. \`gitea.internal.ceosdata.com/org/repo\`)"` — example value, safe to redact to `<your-git-host>/org/repo`.
  - `tests/mock-project/CLAUDE.md:20`: `| Remote | \`gitea.internal.ceosdata.com/test/mock-project\` |` — test fixture, example/placeholder value, safe.
- Inference: `docs/guides/installation.md` lines 15, 26-27, 31, 36 are hard-coded assumptions that break external installs (highest-priority OSS blocker). The `skills/onboard` and `tests/mock-project` occurrences are illustrative examples that are safe as-is or should simply be redacted to `<your-git-host>`.
- Action: Rewrite `docs/guides/installation.md` to be git-host-agnostic: replace all `gitea.internal.ceosdata.com` references with `<your-git-host>` and `fsabacky/ceos-agents` with `<owner>/<repo>`.

---

**A-A-4.** CONTRIBUTING.md Code of Conduct duplication.

- Evidence:
  - `CONTRIBUTING.md:103-108`: Four informal bullets: "Be respectful and constructive…", "Focus on technical merit…", "Welcome newcomers…", "Disagree constructively — critique ideas, not people."
  - `docs/plans/roadmap.md:757`: "CODE_OF_CONDUCT.md — soft requirement; standard for community projects (Contributor Covenant 2.1 is the common choice)."
- Inference: The four bullets are a loose informal summary, not the full Contributor Covenant text. Adding a formal `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1) creates mild duplication but NOT contradiction.
- Recommendation: Remove the four bullet items from `CONTRIBUTING.md:105-108` and replace with a single link: `See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for the full Code of Conduct.` This eliminates duplication without losing substance.

---

**A-A-5.** SECURITY.md minimum viable content.

- Evidence:
  - `CONTRIBUTING.md:98-101`: "Reporting Issues" section covers bugs, feature requests, questions — generic tracker issues, NOT vulnerability disclosures.
  - `README.md:280-282`: "Author & License — Filip Sabacky — See plugin.json for license details." No security contact.
  - `docs/plans/roadmap.md:755-756`: "SECURITY.md — reporting channel for vulnerabilities + expected response time. 3-5 lines minimum."
- Inference: No existing file covers private vulnerability disclosure. `CONTRIBUTING.md` "Reporting Issues" is for general bugs (public tracker), not security vulns.
- Recommendation: Create `SECURITY.md` at repo root. Proposed verbatim content:

```markdown
# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in ceos-agents, please **do not** open a public issue.

Report it privately by email to: **filip.sabacky@ceosdata.com**

Include: a description of the vulnerability, steps to reproduce, and potential impact.

**Response SLA:** We aim to acknowledge reports within 5 business days and provide a fix or mitigation within 30 days.

## Supported Versions

Only the latest released version receives security fixes.
```

Update `CONTRIBUTING.md` "Reporting Issues" to add: "For security vulnerabilities, see [SECURITY.md](SECURITY.md) instead of opening a public issue."

---

**A-A-6.** Gitea/GitHub template locations and minimum required types.

- Evidence:
  - `.gitea/` directory: contains only `workflows/` (CI workflows). No `issue_template/` or `pull_request_template.md` exist.
  - `.github/` directory: does NOT exist.
  - `docs/plans/roadmap.md:758`: "Issue / PR templates — `.github/ISSUE_TEMPLATE/` or `.gitea/issue_template/` + PR template."
  - `CONTRIBUTING.md:98-100`: Mentions bug reports, feature requests, questions — confirms all three template types are relevant.
- Inference: `.gitea/` exists (so Gitea is the primary host); `.github/` does not exist. For future GitHub-mirror readiness, both should be created now to avoid a separate PR later.
- Recommendation: Create BOTH `.gitea/issue_template/` (Gitea-native) AND `.github/ISSUE_TEMPLATE/` (GitHub-native) with identical content. Also create `.gitea/pull_request_template.md` and `.github/PULL_REQUEST_TEMPLATE.md`. Minimum three types: `bug_report.md`, `feature_request.md`, and `PULL_REQUEST_TEMPLATE.md`.

Draft skeletons:

`.gitea/issue_template/bug_report.md` / `.github/ISSUE_TEMPLATE/bug_report.md`:
```markdown
---
name: Bug report
about: Report a bug in ceos-agents
labels: bug
---

## Description
<!-- Clear description of the bug -->

## Steps to reproduce
1.
2.

## Expected behavior

## Actual behavior

## Environment
- ceos-agents version:
- Claude Code version:
- OS:
```

`.gitea/issue_template/feature_request.md` / `.github/ISSUE_TEMPLATE/feature_request.md`:
```markdown
---
name: Feature request
about: Propose a new feature or improvement
labels: enhancement
---

## Use case
<!-- What problem does this solve? -->

## Proposed solution

## Alternatives considered
```

`.gitea/pull_request_template.md` / `.github/PULL_REQUEST_TEMPLATE.md`:
```markdown
## Summary
<!-- What does this PR change and why? -->

## Changes
-

## Test plan
- [ ] Tests added or updated
- [ ] `./tests/harness/run-tests.sh` passes

## Related issues
Closes #
```

---

**A-A-7.** README.md "Author & License" section and stale reference audit.

- Evidence:
  - `README.md:280-282`: `"## Author & License\n\n**Filip Sabacky** — See [plugin.json](.claude-plugin/plugin.json) for license details."`
  - `.claude-plugin/plugin.json:9`: `"license": "UNLICENSED"` — currently UNLICENSED, will change to MIT.
  - `docs/guides/installation.md:15,26-27,31,36`: All contain `gitea.internal.ceosdata.com` (see A-A-3 above).
- Inference: README.md delegates to plugin.json — once plugin.json is updated to `"MIT"`, the README link remains valid without further change. However, the README does not display the license name inline. Adding `MIT License` inline would remove the need to follow the link.
- Recommendation: Update `README.md:282` to: `**Filip Sabacky** — [MIT License](LICENSE)`. This links to the newly-created `LICENSE` file directly and is self-contained. Update `docs/guides/installation.md` as described in A-A-3. No other files contain `"UNLICENSED"` (only `plugin.json` which is being changed).

---

### B — v6.8.1 Polish

**A-B-1.** `--proto "=http,https"` coverage — exact count and enumeration.

- Evidence (direct grep results):
  - `skills/fix-ticket/SKILL.md`: curl at lines **106** and **183** — neither has `--proto`.
  - `skills/fix-bugs/SKILL.md`: curl at lines **119, 190, 236, 368, 429, 479, 511, 545, 573, 614, 651, 680, 741** — 13 sites, none has `--proto`.
  - `skills/implement-feature/SKILL.md`: curl at lines **108, 221, 535** — 3 sites, none has `--proto`.
  - `core/post-publish-hook.md:18`: `curl --proto "=http,https" --max-time 5 --retry 0 ...` — COMPLIANT (Section 3 pr-created).
  - `core/post-publish-hook.md:120`: `curl --proto "=http,https" --max-time 5 --retry 0 ...` — COMPLIANT (Section 4 example).
  - `core/post-publish-hook.md:126`: "All Section 3 and Section 4 curl webhook invocations MUST include this flag." — mandate documented.
  - `core/block-handler.md:51`: `curl --proto "=http,https" --max-time 5 --retry 0 ...` — COMPLIANT.
- Total gap: **18 curl sites** across 3 skill files (2 + 13 + 3). Core contracts are already compliant. The gap is exclusively in the skills layer.
- Note: `skills/fix-bugs/SKILL.md:741` is the `pipeline-complete` batch webhook (different event name `pipeline-complete` vs `pipeline-completed` — separate issue, not scoped here). All 18 sites need `--proto "=http,https"` added immediately after `curl`.

---

**A-B-2.** Trap cleanup in `v681-harness-exit-propagation.sh`.

- Evidence:
  - `tests/scenarios/v681-harness-exit-propagation.sh:79-86`: Creates `$TMPSCEN` at line 80 (`TMPSCEN="$REPO_ROOT/tests/scenarios/$TMPNAME.sh"`), writes it at line 81, runs harness at line 85, cleans up `rm -f "$TMPSCEN"` at line 86. **No trap is registered** — if the script exits abnormally between lines 81 and 86 (e.g., SIGTERM from CI runner), `$TMPSCEN` leaks.
  - `tests/scenarios/autopilot-trap-cleanup.sh:23`: Checks `if ! grep -qE 'trap .*EXIT' "$SKILL"` — verifies SKILL.md documents `trap ... EXIT`. Uses only `EXIT` (not `INT TERM`) in its grep pattern.
  - `tests/scenarios/autopilot-trap-cleanup.sh:2`: `set -euo pipefail` — `set -e` means an unexpected failure mid-script exits without cleanup.
- Inference: The canonical autopilot scenario tests for `trap ... EXIT` in prose only (no script-level trap). The v681 scenario is a functional test script that needs its own temp file trap.
- Recommendation: Add after line 80 (declaration of `TMPSCEN`):
  ```bash
  trap 'rm -f "$TMPSCEN"' EXIT INT TERM
  ```
  Use `EXIT INT TERM` — `EXIT` covers normal and `set -e` exits; `INT` covers Ctrl-C; `TERM` covers CI runner SIGTERM. This matches the roadmap description exactly: `trap 'rm -f "$TMPSCEN"' EXIT INT TERM`.
  The `rm -f "$TMPSCEN"` at line 86 remains as an explicit cleanup for clarity (idempotent with the trap).

---

**A-B-3.** `jq -nc` vs `jq -n` — compact vs pretty-print and byte-equality contract.

- Evidence:
  - `core/block-handler.md:43`: `payload=$(jq -n \` — uses `jq -n` (pretty-print multi-line).
  - `CLAUDE.md:189`: "Webhook payloads are forward-compatible — additive fields may be added in future MINOR versions without a schema version bump. Consumers MUST use lenient JSON parsing (ignore unknown fields)."
  - `core/post-publish-hook.md:149`: "Webhook payloads are forward-compatible — additive fields may be added in future MINOR versions. Consumers should use lenient JSON parsing (ignore unknown fields)."
  - `docs/guides/autopilot.md:286`: "Webhook payloads are forward-compatible — additive fields may appear in future MINOR versions. Use lenient JSON parsing (ignore unknown fields)."
  - `docs/plans/roadmap.md:770`: "Webhook payload compact vs pretty-print (`jq -n` emits multi-line; downstream consumers parsing byte-equality may break) — consider `jq -nc` if compatibility is required."
- Inference: No byte-equality parsing contract exists anywhere in the codebase. All three copies of the forward-compatibility note specify **lenient** JSON parsing (ignore unknown fields), which implies whitespace-tolerance as well. RFC 8259 §2 makes whitespace irrelevant to JSON semantics.
- Recommendation: `jq -nc` is **advisory** — it makes payloads smaller (single line) and is slightly more curl-friendly for debug inspection. It is NOT strictly required. However, switching from `jq -n` to `jq -nc` in `core/block-handler.md:43` is a low-risk improvement that aligns with the `--data-binary @-` heredoc pattern (where a compact single-line JSON is marginally simpler to reason about). Recommended change: `payload=$(jq -nc \` in Step 5.

---

**A-B-4.** `issue_id` regex — exact text, Jira dotted-key support, path-traversal analysis.

- Evidence:
  - `skills/fix-ticket/SKILL.md:90`: `` if [[ ! "${ISSUE_ID}" =~ ^[A-Za-z0-9#_-]+$ ]]; then ``
  - `skills/fix-bugs/SKILL.md:95`: `` if [[ ! "${ISSUE_ID}" =~ ^[A-Za-z0-9#_-]+$ ]]; then ``
  - `skills/implement-feature/SKILL.md:92`: `` if [[ ! "${ISSUE_ID}" =~ ^[A-Za-z0-9#_-]+$ ]]; then ``
  - `skills/resume-ticket/SKILL.md:86`: `` if [[ ! "${ISSUE_ID}" =~ ^[A-Za-z0-9#_-]+$ ]]; then ``
  - All four are identical: `^[A-Za-z0-9#_-]+$`.
- Path-traversal analysis for `.` addition: The regex is anchored `^...$` and applied to the entire string via `[[ =~ ]]` (not `grep`). A dot `.` in a path segment is safe — it does not introduce `..` (two dots) unless the input contains `..`, which requires two consecutive dots. The character class `[A-Za-z0-9#._-]` with a single `.` cannot produce `..` because it allows only single characters per position. Path construction is `.ceos-agents/{id}/state.json` — a dot in `id` (e.g., `PROJ.NAME-123`) yields `.ceos-agents/PROJ.NAME-123/state.json`, which is a valid safe path. `run_id` format is `{ISSUE_ID}_{timestamp}` — a dot in `ISSUE_ID` is URL-safe and filename-safe. Decomposition YAML filenames use `{issue_id}` similarly — a dot is safe.
- Recommendation: Replace `^[A-Za-z0-9#_-]+$` with `^[A-Za-z0-9#._-]+$` in all four skill files. The change is additive — only Jira dotted IDs like `PROJ.NAME-123` are newly accepted; all existing valid IDs remain valid. No path-traversal risk introduced.

---

**A-B-5.** AC-ITEM-3.2 false-positive — exact identification and fix.

- Evidence:
  - `core/block-handler.md:59`: `"embedding, with no shell-level substring trimming required (no Bash-specific \`\${var:1:-1}\` or"` — the prose explicitly names `${var:1:-1}` as a counter-example of what NOT to use.
  - `.forge.bak-20260419T184209Z/phase-5-tdd/tests-hidden/h-block-handler-heredoc.sh:62`: The NEGATIVE check is: `if grep -qE '\$\{[A-Za-z_][A-Za-z0-9_]*:[0-9]+:-[0-9]+\}' "$BLOCK_HANDLER"` — this regex matches ANY occurrence of `${var:N:-N}` pattern in the file, INCLUDING the prose counter-example on line 59.
  - `h-block-handler-heredoc.sh:63`: `fail "AC-ITEM-3.2: core/block-handler.md contains POSIX-unsafe Bash 4.2+ substring trim \${var:N:-N}"` — this FAIL fires on the prose mention.
  - `h-block-handler-heredoc.sh:7`: `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"` — uses `../../` (2 levels up from `tests-hidden/`), resolving to `.forge.bak-.../phase-5-tdd/`, NOT the repo root. This is the REPO_ROOT path bug — should be `../../../` (3 levels: `tests-hidden/ → phase-5-tdd/ → .forge.bak-.../ → repo-root`).
- Recommendation: Two separate fixes needed:
  1. **AC-ITEM-3.2 false-positive**: In the hidden test `h-block-handler-heredoc.sh`, scope the negative grep to fenced code blocks only. Change the grep to exclude backtick-wrapped prose by checking the match is within a `bash` code fence. Simplest fix: rephrase `core/block-handler.md:59` to move `${var:1:-1}` inside a backtick inline-code span that is clearly labeled as a negative example, then restrict the grep pattern to match only unquoted occurrences (outside backtick spans). Alternatively: rephrase line 59 to use a different notation that avoids triggering the regex, e.g. `${ var colon N colon -N }` (spelled out). Recommended: change the prose from `` `${var:1:-1}` `` to `Bash-specific substring trim syntax (e.g., \`\${var:1:-1}\`)` and restrict the negative grep to lines NOT inside backtick code spans — or simply accept that the prose counter-example must be phrased so the substring-trim pattern does not appear verbatim. Cleanest fix: wrap the counter-example in a `<!-- COUNTER-EXAMPLE -->` comment and exclude HTML-comment lines from the grep: `grep -vE '<!--' | grep -qE '\$\{[A-Za-z_]...\}'`.
  2. **REPO_ROOT path bug**: The phase-5-tdd hidden test generator must use `../../../` not `../../`. This is a spec requirement for Phase 4: hidden tests placed under `.forge/phase-5-tdd/tests-hidden/` are 3 levels below the repo root, so REPO_ROOT computation must be `$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)`.

---

### C — v6.8.0 Additions

**A-C-1.** `--format json` for `/ceos-agents:metrics` — spec-impl gap and JSON schema.

- Evidence:
  - `skills/metrics/SKILL.md:1-5` (frontmatter): `argument-hint: "[--period <N>] [--output <path>]"` — `--format` is absent from argument-hint.
  - `skills/metrics/SKILL.md:10-14` (Flag parsing section): Only `--period N` and `--output path` are documented. `--format` is NOT handled.
  - `skills/metrics/SKILL.md:101`: `"Output format is always markdown."` — explicit prose contradicting the reference docs.
  - `docs/reference/skills.md:562-568`: Documents `--format <md|json>` as a current flag with example `/ceos-agents:metrics --period 14 --format json --output metrics.json`.
  - `CHANGELOG.md` search: No entry for `--format json` in metrics — confirmed by searching v6.8.0 entry (lines 30-62), v6.7.2 (lines 64-80), and prior — `--format json` was never shipped.
- Inference: `docs/reference/skills.md:562-568` documented `--format json` prematurely (aspirationally) without a corresponding implementation in `skills/metrics/SKILL.md`. This is a pre-existing spec-impl gap that v6.9.0 must close.
- JSON schema for `--format json` output (draft):
  ```json
  {
    "generated_at": "ISO-8601 timestamp",
    "period_days": 30,
    "project": "string",
    "pipeline_overview": {
      "issues_attempted": 0,
      "issues_fixed": 0,
      "issues_blocked": 0,
      "success_rate": 0.0,
      "avg_time_to_fix_hours": 0.0
    },
    "token_cost": {
      "measured_issues": ["PROJ-42"],
      "estimated_issues": ["PROJ-37"],
      "measured_tokens": 0,
      "estimated_tokens": 0
    },
    "block_analysis": {
      "by_stage": [
        {"stage": "triage", "blocks": 0, "pct": 0.0}
      ],
      "top_reasons": [
        {"reason": "string", "count": 0}
      ]
    },
    "per_agent": [
      {
        "agent": "fixer",
        "invocations": 0,
        "blocks": 0,
        "success_rate": 0.0,
        "top_failure": "string"
      }
    ],
    "recommendations": ["string"]
  }
  ```
- Output routing: When `--format json` is supplied, output goes to the same destination as `--output` (file if specified, stdout otherwise) — same routing as markdown. No separate file.
- Recommendation: Update `skills/metrics/SKILL.md`: add `--format <md|json>` to argument-hint and Flag parsing section; replace "Output format is always markdown" with conditional logic. When `--format json`: serialize the exact fields above (compact JSON, `jq -nc`-style). When `--format md` or omitted: existing markdown report.

---

**A-C-2.** `outcome: "failed"` catastrophic-exit fire path — feasibility and insertion point.

- Evidence:
  - `skills/fix-ticket/SKILL.md:508`: "Fire `pipeline-completed` webhook (WEBHOOK-R4): After terminal state is committed, fire `pipeline-completed` with `outcome: \"success\"`" — success path at Step 9 publisher.
  - `skills/fix-ticket/SKILL.md:542`: "Fire `pipeline-completed` webhook (WEBHOOK-R4): After terminal `status: blocked` is committed, fire `pipeline-completed` with `outcome: \"blocked\"`" — block path at Step X.
  - `skills/fix-bugs/SKILL.md:680-685`: Same dual-path pattern. `pipeline-completed` fires at Step 8 (success) and Step X (block).
  - `skills/implement-feature/SKILL.md:533-540`, `569`: Same pattern.
  - `core/post-publish-hook.md:85`: `"outcome" is one of: "success", "blocked", "failed"` — `"failed"` is documented in the payload contract but has no implementation path.
- Constraint: Skills are pure-markdown orchestration prose run inside `claude -p` — there is no persistent shell wrapper. A bash `trap EXIT` in a traditional sense is not applicable; the skill itself is the "script" and Claude Code's agent harness manages execution lifecycle.
- Recommendation: Implement `outcome: "failed"` as a documented prose instruction at the skill level. Add a new terminal step to each pipeline skill: "**Step Z. Catastrophic exit handler (outcome: failed):** If the pipeline exits without reaching Step 9 (success) or Step X (block handler) — for example, due to an unrecoverable tool error, OOM, or agent crash — the skill MUST attempt to fire `pipeline-completed` with `outcome: \"failed\"`, `pr_url: null`. Insertion point: document this as a Step Z after Step X in fix-ticket, fix-bugs, and implement-feature. The prose instructs the skill to fire this webhook as a best-effort operation if it detects it is terminating abnormally (no state.json terminal status committed). This is achievable in pure-markdown because the `pipeline-completed` webhook fire is already conditional on state.json commit — if no terminal status was committed before exit, `outcome: "failed"` applies."

---

**A-C-3.** Circuit breaker design for slow/hung webhooks.

- Evidence:
  - `core/post-publish-hook.md:100-102`: "Transport, curl invocation, and failure handling are identical to Section 3. Use the same `curl --max-time 5 --retry 0` pattern." — `--max-time 5` already bounds each call to 5 seconds. `--retry 0` means no automatic retry.
  - `core/post-publish-hook.md:102`: "Advisory failure: log `[WARN] Webhook delivery failed: {error}` and continue pipeline. Never block."
  - `state/schema.md:1-6`: `schema_version: "1.0"`, additive fields permitted. No circuit-breaker state exists.
  - `core/state-manager.md:6-7`: Atomic write via tmp + rename — supports but does not mandate circuit-breaker state.
  - `docs/plans/roadmap.md:779-782`: "Circuit breaker for slow/hung webhooks (debounce / batch — deferred from v6.8.0)."
- Inference: With `--max-time 5 --retry 0`, each webhook call is already bounded. The primary concern is N sequential calls in a pipeline where N=18+ (all stages fire step-completed), each timing out at 5s = 90s of webhook overhead for a completely dead endpoint.
- Recommendation: Option (a) — in-memory failure count per pipeline run. After 3 consecutive webhook delivery failures (`[WARN] Webhook delivery failed`), suppress all remaining webhooks for the current run and log `[WARN] Circuit breaker open: 3 consecutive webhook failures. Suppressing remaining webhooks for this run.` This resets on next pipeline invocation (no persistent state). Rationale: (1) No new state file needed (`.ceos-agents/circuit-breaker.json` adds complexity for an advisory feature); (2) 3-failure threshold with 5s timeout = max 15s overhead before suppression — acceptable; (3) Tracking globally (not per event type) is simpler and sufficient. Per-event-type tracking adds complexity without clear benefit since a dead endpoint fails all types equally. Persistence across runs (option b) requires file I/O and race condition handling — defer to v6.9.1.

---

**A-C-4.** Multi-host distributed lock for Autopilot — options and recommendation.

- Evidence:
  - `skills/autopilot/SKILL.md:29-31`: "Process-local lock — `.ceos-agents/autopilot.lock/` guards ONE host / filesystem. Multi-host deployments MUST coordinate via DISJOINT `Bug query` / `Feature query` filters per host, or run Autopilot from exactly one host."
  - `skills/autopilot/SKILL.md:344-353`: Full Cross-Host Operation section. "Tracker-level distributed lock is NOT_IN_SCOPE for v6.8.0 and is deferred to v6.9.0+."
  - `docs/guides/autopilot.md:1-22`: Operator guide confirms process-local lock, disjoint-query mitigation.
  - `docs/plans/roadmap.md:777-782`: "Multi-host distributed lock for Autopilot (currently process-local; v6.8.0 workaround = disjoint queries across hosts)."
- Options:
  1. **`flock` advisory lock on NFS**: Works for NFSv4 with proper server config; fragile on SMB/CIFS (locking not reliable); adds OS dependency; not portable to all CI environments.
  2. **External coordinator (etcd/redis/consul)**: Reliable distributed lock; adds significant infrastructure dependency; breaking the "no dependencies" plugin convention.
  3. **Formalize disjoint-query pattern as explicit operator guidance and defer distributed lock to v6.9.1**: Zero new dependency; works today; the pattern is already documented and used.
- Recommendation: **Option 3 — defer to v6.9.1** with explicit prose improvements. Add to `skills/autopilot/SKILL.md` Cross-Host Operation section: "Multi-host coordination via disjoint queries is the v6.9.0-supported pattern. Distributed lock (e.g., flock advisory lock, external coordinator) is deferred to v6.9.1 pending operator demand." Add to `docs/guides/autopilot.md` multi-host section: same note. Add a roadmap entry: "v6.9.1: Distributed lock for Autopilot — flock (NFSv4) or external coordinator (redis/etcd) options — pending operator demand signal." Rationale: the disjoint-query pattern is already sufficient for the documented use case (one Autopilot host OR per-host disjoint queries), the plugin's "no dependencies" convention rules out etcd/redis for MINOR, and flock's NFS fragility makes it an incomplete solution. Deferring to v6.9.1 with a clear upgrade path is the correct MINOR-safe choice.

---
