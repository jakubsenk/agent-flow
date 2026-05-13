# Phase 0 Analysis — ceos-agents v6.8.0 (Autopilot + Observability)

## Task Type Classification

**Primary type:** `feature`
**Secondary types:** `["migration"]` (state.json schema additions are backward-compatible but touch a cross-cutting contract)

Rationale: Three bundled, scoped items, all additive:
1. **Autopilot skill** — brand-new `/ceos-agents:autopilot` thin dispatcher + optional `### Autopilot` config section + lock file mechanism. Net-new capability.
2. **Observability Hooks (D10)** — extend existing webhook system with three new events (`pipeline-started`, `step-completed`, `pipeline-completed`). Additive to `core/post-publish-hook.md` / `core/block-handler.md` and the pipeline skills.
3. **Real-Time Cost Visibility** — add per-stage `tokens_used` / `duration_ms` / `tool_uses` / `model` fields to state.json (mirrors forge.json 1:1), add top-level `pipeline` accumulator, emit a summary table at pipeline end, aggregate in `/metrics`.

No breaking Automation Config changes. All three items ship together because Autopilot is the primary consumer of both webhook events and cost data. This is `feature` not `migration`: state-schema additions are new optional fields on existing stages, not a rename or semantic change.

## Complexity Assessment

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Scope | 4 | Three bundled deliverables spanning 4 pipeline skills (fix-ticket, fix-bugs, implement-feature, scaffold), 2 utility skills (metrics, dashboard), 3 core contracts (post-publish-hook, block-handler, state-manager), state/schema.md, CLAUDE.md config contract doc, 1 brand-new skill directory, version-bump, changelog, docs/reference/skills.md. Likely 12-18 files touched. |
| Ambiguity | 2 | Roadmap specifies target files, field names, event names, structural mapping table (forge.json<->state.json), Autopilot config keys (7 of them with defaults), lock-file path/format, and error semantics. Two genuine open questions: (a) exact `step-completed` payload shape (which stages fire the event — only top-level, or also inner loops like fixer<->reviewer iteration?), (b) how Autopilot two-query classification interacts with per-project Feature Workflow config when Feature query is absent. Devin Q1 is well-defined overall. |
| Risk | 3 | Pure-markdown changes, but Observability Hooks change a *documented public surface* (Notifications `On events` enum). Adding three new webhook event identifiers does not break existing consumers (they filter), but **payload schema** for `pipeline-started`/`step-completed`/`pipeline-completed` is a new contract that external consumers will depend on — must get it right on first ship. Real-Time Cost Visibility changes state.json schema (v1.0 -> v1.1) which `/resume-ticket` reads; backward-compatible reads must be preserved. Autopilot runs headless with `--dangerously-skip-permissions` — lock file must be correct to prevent runaway/concurrent invocations. Memory note "Never blindly trust specs" applies here; the roadmap is detailed but still requires research/validation. |
| **Composite** | **4** | max(4, 2, 3) = 4 — drives maximum-agent scaling, default models (no downgrade), default/higher review rounds. |

## Fast-Track Eligibility Assessment

### Preconditions

- Composite complexity: **4** (fails `<= 2`)
- Confidence: **0.88** (fails `>= 0.9`)
- `fast_track.enabled`: `null` (auto-detect — not forced)
- task_type: `feature` (not in statically-ineligible list)

**Verdict: NOT ELIGIBLE.** Composite complexity 4 and confidence 0.88 both fail fast-track preconditions. Tier B semantic evaluation is still produced below for traceability and to satisfy the output-artifact contract.

### Tier A: Keyword scan of raw input (informational only)

Scanned raw `input.md` against the nine hardcoded keyword/pattern categories. No matches in any category. Autopilot `--dangerously-skip-permissions` is a Claude CLI flag, not `sudo`; `.credentials.json` is mentioned as a future-deployment open question, not an instruction to read/write credentials.

Tier A: NO MATCH.

### Tier B: Semantic evaluation

```json
{
  "security_evaluation": {
    "destructive_ops":           { "result": "pass", "evidence": "Pure markdown edits plus new markdown skill; no deletion/truncation/overwrite of user data. Autopilot lock file is created/removed by the skill itself under .ceos-agents/, not a user artifact." },
    "credential_handling":       { "result": "pass", "evidence": "Task discusses credential-file portability as an open question for future deployment docs; implementation does not read, write, transmit, or log any credential, token, or secret. Webhook events carry issue IDs, durations, and token counts only." },
    "irreversible_side_effects": { "result": "pass", "evidence": "New webhook events are OUTBOUND notifications to a user-configured URL; they are opt-in (optional Notifications section) and failure is advisory. No emails, no third-party API calls, no payment, no package publish triggered by this task." },
    "elevated_privileges":       { "result": "pass", "evidence": "No sudo/root/chmod/chown. Autopilot runs with --dangerously-skip-permissions by design, but that is a CLAUDE CLI flag, not OS privilege escalation — it skips Claude Code permission prompts, not OS ACLs." },
    "ambiguous_scope":           { "result": "pass", "evidence": "Scope is explicitly bounded by roadmap PLANNED — v6.8.0 section: three named items with enumerated target files. Autopilot dispatches only to existing fix-ticket/implement-feature skills, not arbitrary scripts." },
    "network_irreversibility":   { "result": "pass", "evidence": "No DNS records, CDN config, firewall, or load balancer changes. Outbound webhook calls use curl with --max-time 5 --retry 0 per existing post-publish-hook pattern — bounded, reversible." },
    "supply_chain_ops":          { "result": "pass", "evidence": "Version bump creates a git tag locally via /ceos-agents:version-bump. No npm publish / pip publish / docker push / cargo publish in scope. Git push, if any, is to the project own remote as a normal PR flow." },
    "billing_quota_ops":         { "result": "pass", "evidence": "No cloud provisioning, no subscription changes, no quota modifications. Token counting is INFORMATIONAL display only — it does not purchase tokens or change any billing state." },
    "system_service_effects":    { "result": "pass", "evidence": "No systemctl, cron, crontab, docker daemon, or firewall edits. Autopilot is invoked as a short-lived claude -p process; lock file is plain text at a path inside the project, not a system-level lock or service." }
  }
}
```

Tier B semantic outcome: all nine PASS with >=15-char evidence. Structural validation passes. Fast-track remains **NOT ELIGIBLE** because preconditions (complexity, confidence) fail upstream of Tier B.

## Domain Identification

- **Language/Runtime:** None (pure markdown plugin). Consumers run Node.js/Python/.NET/etc. — irrelevant to this task.
- **Framework:** Claude Code plugin system (`.claude-plugin/plugin.json`, `skills/*/SKILL.md`, `agents/*.md`, `core/*.md`).
- **Domain:** Developer-tooling / CI-automation / orchestration plugin. Meta-project — ceos-agents defines pipelines that other repos consume.
- **Specialty concerns:**
  - **Contract stability** — Automation Config and state.json schema are documented public surfaces consumed by external projects and by `/resume-ticket`.
  - **Security** — Autopilot runs headless with skipped permission prompts; lock-file correctness is load-bearing. Webhook URLs are user-configured; payload schema must not leak sensitive data (avoid putting raw user prompts, raw code, or PII in webhook payloads).
  - **Forge parity** — cost-tracking mechanism must mirror `filip-superpowers/forge` forge.json 1:1 (per the user explicit reference).
  - **Observability** — the three new webhook events exist to power real-time external dashboards; payload design is the deliverable.
  - **Backward compatibility** — `/resume-ticket` must continue to read state.json written by v6.7.x plugin versions.

## Codebase Context Assessment

**Repository type:** Pure markdown Claude Code plugin, no build system, no runtime dependencies.

**Test framework:** Bash-based harness at `tests/harness/run-tests.sh` — MUST run before every commit per user memory. Scenario scripts in `tests/scenarios/` validate structural integrity and CLAUDE.md template compliance.

**Build / version policy:**
- Version in `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json`. Current: v6.7.2.
- MINOR bump (v6.7.2 -> v6.8.0) because all additions are optional (new skill, new optional config section, new optional webhook events, additive schema fields).
- Release via `/ceos-agents:version-bump` skill (per user memory: never do manual version bump + tag). CHANGELOG entry is mandatory and part of the same commit as content changes; version-bump is a separate commit; tag is created by the skill.
- Commit order: (1) content changes + CHANGELOG entry, (2) version-bump separate commit, (3) tag.

**Key existing patterns (relevant to this task):**

1. **Webhook delivery pattern** (`core/post-publish-hook.md` Step 3): uses curl with `--max-time 5 --retry 0`, heredoc JSON body, `{event, issue_id, pr_url, timestamp}` payload for `pr-created`. Failures are advisory (`[WARN]` log, never block). Same pattern MUST apply to the three new events for consistency.

2. **Block-handler webhook** (`core/block-handler.md`): fires `ceos-agents-block` event (currently the only non-PR event). This gives the second existing event alongside `pr-created` — matches the roadmap "beyond current 2 events" claim.

3. **State file location:** `.ceos-agents/{RUN-ID}/state.json` per `state/schema.md`. Written atomically via `core/state-manager.md`. Schema version field currently `"1.0"`; adding usage fields is a MINOR schema change — bump to `"1.1"` and document backward-compat reads.

4. **State-manager write protocol:** atomic tmp+rename (already documented in `state/schema.md` and `core/state-manager.md`). Unchanged — only new field paths are written.

5. **Per-stage structure in state.json:** each stage (`triage`, `code_analysis`, `fixer_reviewer`, `test`, `e2e_test`, `browser_verification`, `publisher`, etc.) currently has `status` and domain fields. Need to ADD `tokens_used`, `duration_ms`, `tool_uses`, `model`, `started_at`, `completed_at` to each. For `fixer_reviewer`: cumulative across iterations (existing `iterations` counter reused).

6. **Forge reference pattern:** `forge.json` phases each have `tokens_estimated`, `duration_ms`, `tool_uses`, `started_at`, `completed_at`. Accumulator at top-level `metrics.total_tokens_estimated`, `metrics.total_duration_ms`. ceos-agents state.json mirrors 1:1 with the structural mapping in the roadmap.

7. **Optional config section format:** table-based `| Key | Value |` per CLAUDE.md spec. Autopilot config will follow this — 7 keys: `Max issues per run`, `Lock timeout`, `Log file`, `Bug limit`, `Feature limit`, `On error`, `Dry run`.

8. **Skill directory structure:** `skills/{skill-name}/SKILL.md` with YAML frontmatter (`name`, `description`, `disable-model-invocation` for pipeline skills). Autopilot is a user-invokable dispatcher -> does NOT set `disable-model-invocation` (it is an entry point, not an internal pipeline step).

9. **Namespace prefix:** all skills invoked as `/ceos-agents:{name}`. Autopilot will be `/ceos-agents:autopilot`.

10. **Documentation surfaces that need updates:**
    - `CLAUDE.md` (project root) — add `### Autopilot` row to optional-sections table.
    - `docs/reference/skills.md` — add `/ceos-agents:autopilot` row; update skill count (28 -> 29).
    - `docs/reference/config.md` (if exists) — document Autopilot 7 keys.
    - `docs/guides/` — possibly a headless-deployment guide.
    - `state/schema.md` — add usage fields per stage + new `pipeline.*` accumulator.
    - `CHANGELOG.md` — entry for v6.8.0.
    - Memory note "Doc completeness before commit" applies: grep entire repo for skill counts (`28 skills`, `28`, `total: 28`) to find stale references.

11. **v6.7.2 continuity:** the most recent forge run aligned webhooks and extracted tracker-subtask to a core contract. Webhook-alignment work sets up the ground for this task — the webhook delivery code is already consolidated in `core/post-publish-hook.md`, so adding three new events is a focused edit rather than scattered.

**Compressed `{{CODEBASE_CONTEXT}}` (for all downstream prompts):**

> Pure-markdown Claude Code plugin. Test framework: `./tests/harness/run-tests.sh` (bash). Version via `/ceos-agents:version-bump`. Skills at `skills/{name}/SKILL.md` (YAML frontmatter), agents at `agents/{name}.md`, core contracts at `core/{name}.md`, state schema at `state/schema.md`. Config contract in project CLAUDE.md -> `## Automation Config` (table format). Webhook pattern: `core/post-publish-hook.md` (curl --max-time 5, heredoc JSON, advisory on failure). State writes: `core/state-manager.md` (atomic tmp+rename, schema v1.0). Forge parity: per-phase tokens/duration/tool_uses mirrors forge.json. Three v6.8.0 items: (1) `/ceos-agents:autopilot` headless dispatcher + lock file + `### Autopilot` config section; (2) three new webhook events (`pipeline-started`, `step-completed`, `pipeline-completed`); (3) per-stage usage fields + pipeline accumulator + summary table + `/metrics` aggregation. All additive, no breaking changes. Current plugin version: v6.7.2 -> v6.8.0 (MINOR).

## Confidence Scoring (Devin Pattern)

| Question | Score | Rationale |
|----------|-------|-----------|
| Q1. Is the task well-defined enough to execute? | 0.90 | Roadmap enumerates target files, config keys, event names, field names, and provides the forge.json<->state.json structural mapping. Two minor open questions: step-completed event granularity (only top-level stages, or inner iterations?), and Feature query fallback behavior in Autopilot. Both are resolvable in Phase 1-2 research. |
| Q2. Does the available context support execution? | 0.88 | All 12+ target files are in-repo and readable. Forge reference files live in sister repo `filip-superpowers/forge` for cross-reference. One gap: roadmap mentions "external review 2026-04-08" D10 source but no standalone review document exists in `docs/plans/` — the roadmap section is the ground truth (acceptable but reduces Q2 slightly). |
| Q3. Is the task within the pipeline capabilities? | 0.92 | Pure-markdown edits are exactly what the forge pipeline handles best. No code compilation, no runtime execution, no external integrations to test. Test suite is bash — forge can run it in verification. |
| **Composite** | **0.88** | min(0.90, 0.88, 0.92) = 0.88 |

Compared against `meta_agent.confidence_threshold = 0.7` (default): **0.88 > 0.7**, so **proceed with noted assumptions** (no clarification protocol). Note the two open questions for Phase 1 research.

## Open Questions Flagged for Phase 1 (Research Questions)

1. **step-completed event granularity** — does the event fire for every internal retry (fixer iteration 2 of 5), or only for top-level stages (triage, code-analysis, fix&review aggregate, test, publish)? Affects webhook volume at external consumers.
2. **Feature query absence in Autopilot** — if `Feature Workflow` section is not in Automation Config, does Autopilot run bug-only mode silently, warn, or block? User expects graceful default; exact behavior must be specified.
3. **state.json schema version bump** — current `schema_version: "1.0"`. Adding usage fields is backward-compatible for writers but readers on older plugin versions may log warnings. Bump to "1.1" and document read-compat expectations.
4. **Autopilot lock-file on Windows** — lock file format (timestamp + hostname) is trivial, but stale-lock cleanup (120min) and atomic creation on Windows need verification. Same atomic tmp+rename pattern as state-manager should work.
5. **Token count source** — the Task/Agent tool usage metadata field names (`total_tokens` vs `input_tokens + output_tokens`) must match what the current harness actually returns. Requires reading one or two existing forge.json artifacts to confirm.

None of these block Phase 1; they are research targets.

## Pipeline Configuration Recommendations

| Setting | Recommended | Reason |
|---------|-------------|--------|
| `pipeline_mode` | `adaptive` (default) | Default is right. Adaptive JIT refinement helps on a medium-ambiguity task. |
| `jit.enabled` | `true` | Composite complexity 4 >= 3 -> JIT recommended. |
| `replanning.enabled` | `true` (default) | Default. |
| `replanning.max_cycles` | `2` | Ambiguity 2 is low — bump default `1` to `2` to allow one replan on step-completed granularity or Feature-query absence discovery, but no more. |
| `replanning.divergence_threshold` | `0.3` (default) | Risk 3 medium — default. |
| `verification.dimension_weights` | defaults `security 0.3, correctness 0.3, spec_alignment 0.2, robustness 0.2` | Spec-heavy feature with detailed requirements -> use defaults per meta-agent-prompt rule. No security-specific bump needed (Tier B all-pass, no credential/auth changes). |
| `fast_track.enabled` | `null` (auto, ineligible) | Explicit provenance record. |
| `routing.enabled` | `null` (default auto) | Feature routes to full_pipeline regardless. |
| `approval_gates` | `[3, 4, 6]` (default) | Brainstorm / Spec / Plan gates — appropriate for a feature with public-contract impact. |
| `review.triage_enabled` | `false` (default) | Default sufficient. |
| `tdd.mutation_threshold` | `70` (default) | Default. |
| `oracle.enabled` | `true` (default) | Default. |

## Template Auto-Selection

`routing.auto_select_template == false` in pre-merged config -> **skip** template selection protocol. Record:

```json
{
  "template_selection": {
    "selected": null,
    "confidence": 0,
    "rationale": "routing.auto_select_template is false in pre-merged config; selection protocol not executed."
  }
}
```
