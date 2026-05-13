# Phase 3 Brainstorm — Judge Synthesis (Final Direction for v6.10.0)

Forge run: `forge-2026-04-23-002`
Synthesis method: **Judge-Mediated** (per `C:/gitea_filip-superpowers/skills/forge/synthesis-prompt.md`)
Anti-conformity pattern: **Free-MAD** — for every recommendation, the two alternatives' specific flaws are named, then the winner is constructed to avoid the worst failure of each.
Honored ground truth: Phase 2 `final.md` — 5 confirmed roadmap discrepancies, canonical source `agents/code-analyst.md:120`, Claude Code PostToolUse hook API NOT FOUND in-repo (MEDIUM confidence), test-engineer/e2e-test-engineer/backlog-creator EXTERNAL-INPUT claim empirically false (actual unpatched count is 11, not 8).

---

## Summary

**Chosen direction:** v6.10.0 ships as a **minimum-external-surface, maximum-internal-rigor** release. Track 1 adopts **T1-A1-conservative + T1-A2-innovative's `make_state_json()` + `require_jq()` + `setup_scratch()` DSL-lite helper trio** with T3-A1-skeptical's per-scenario security checklist as PR-review gate. Track 2 adopts **T2-A2-skeptical + T2-A1-conservative's Layer-1 prose + opt-in plugin-shipped `hooks/validate-dispatch.sh`** with T2-A4-skeptical's `dispatched_at` presence-check replacing the theater `tokens_used > 100` threshold (schema-additive, v6.10.0 doc-only, v6.11.0 runtime). Track 3 adopts **T3-A2-skeptical's 11-agent expansion** (scope = 11, not 8 — roadmap was empirically wrong) with T1-A2-innovative's enumeration-based `prompt-injection-protection.sh` rewrite and T3-A5-skeptical's explicit rejection of Persona 2's HTML-comment wrapper inheritance mechanism.

**Aggregate effort: 30–36 person-hours.** Tracked as READY FOR GATE 1.

**Release philosophy:** ship less than the roadmap committed in absolute count (defer 9 REWRITEs and Layer 2 runtime enforcement to v6.10.1), but ship every delivered item with defensible security posture and without `tokens_used > 100` theater. The roadmap's "Layers 1+2+4" is re-interpreted as: Layer 1 fully shipped; Layer 4 fully shipped as functional test; Layer 2 ships as plugin-reviewable opt-in hook with advisory (non-blocking) semantics + schema-additive `dispatched_at` field.

---

## Track 1: Test Discipline Overhaul

### Recommended approach

**`T1-HYBRID = T1-A1-conservative (base) + T1-A2-innovative (DSL-lite subset, 3 helpers) + T1-A3-skeptical (CONTRIBUTING.md security checklist as PR-review gate) + T1-A5-skeptical (enumeration-only Phase 9 upgrade)`**

Concrete scope:
- **RETIRE=5** via `exit 77` (from Phase 2 table `§ Test Scenario Inventory`): `v6.9.0-changelog-completeness`, `v6.9.0-plugin-repo-url-invalid-tld`, `v6.9.0-webhook-proto-coverage`, `ac-v692-autopilot-bash-dispatch`, and one more per Phase 2. (Phase 4 spec must freeze the exact list from Phase 2's 5-entry RETIRE classification.) [T1-A1-conservative]
- **EXTEND=8** in-place (from Phase 2 table): surgical additions only, no restructure. [T1-A1-conservative]
- **REWRITE=5 (top-5 only, NOT all 14)**: the 5 highest-value REWRITE targets from T1-A1-conservative's ranking: `v6.9.0-pause-timeout-validation.sh`, `v6.9.0-needs-clarification-dos-cap.sh`, `v6.9.0-circuit-breaker-semantics.sh`, `v6.9.0-pipeline-history-pii-scope.sh`, `v6.9.0-outcome-failed-trap.sh`. The remaining 9 REWRITEs **explicitly deferred to v6.10.1** with roadmap entry. [T1-A1-conservative]
- **Shared helpers (DSL-lite)**: `tests/lib/fixtures.sh` with EXACTLY 3 helpers extracted from `v6.9.0-needs-clarification-e2e.sh:72-126`: `make_state_json()` (jq-based canonical state.json builder), `setup_scratch()` (mktemp+trap wrapper), `require_jq()` (HAVE_JQ guard). NOT the full 8-helper DSL — the restraint is deliberate. Scenarios source it via `. "$(dirname "$0")/../lib/fixtures.sh"` — zero harness change. [T1-A2-innovative's DSL-lite]
- **Security-reviewed opt-in**: `CONTRIBUTING.md` gets a new section "Functional test scenarios — security expectations" enumerating the 7-item checklist from T1-A2-skeptical (no `$(...)` in fixture construction; no `eval`; no out-of-tree sourcing; `set -uo pipefail` mandatory; double-quoted filesystem ops; verbatim `trap 'rm -rf "$SCRATCH"' EXIT`; no `$TMPDIR`/`$HOME` references). Doc-only enforcement — honest about not having CI gates yet. [T1-A3-skeptical]
- **Phase 9 enumeration upgrade**: convert the 4 count-string anchors (19 optional sections, 16 core contracts, 21 agents, 29 skills) to enumeration-based assertions **inline in `v6.9.0-doc-count-drift.sh`** (EXTEND it; do NOT create a separate file). [T1-A5-skeptical + T1-A1-conservative]

### Rationale

Persona 1's T1-A1 has the flaw that 5 REWRITE scenarios still hand-copy ~40 lines of boilerplate (state builder + scratch dir + jq guard), burning ~3h of duplicate work across the 5 scenarios and any future REWRITEs in v6.10.1. Persona 2's T1-A1-innovative has the flaw that an 8-helper DSL + 30 net-new scenarios (52h effort) is unjustifiable release budget and creates a single-file blast radius that Persona 3 correctly flagged (T1-A4-skeptical). Persona 3's T1-A3-skeptical has the flaw that deferring ALL 14 REWRITEs ships "test discipline overhaul" in name only — the roadmap-headline deliverable is hollowed out.

The hybrid takes the top-5 REWRITE scope from P1 (shipping the roadmap headline with defensible breadth), the *3*-helper DSL-lite from P2 (not 8 — P3's blast-radius critique caps the abstraction surface at the minimum-useful), the CONTRIBUTING.md checklist from P3 (closes T1-ADV-1/2/3 at PR-review time without claiming CI enforcement we don't have), and P3's enumeration-only Phase 9 upgrade (closes the root v6.9.0 doc-count-drift failure mode). The 3-helper DSL is specifically chosen because those 3 helpers have ≥5 consumer scenarios each in this release alone (every REWRITE plus Track 2 Layer 4) — the ROI gate from P2's Cross-Track Infrastructure §X-5 is already met in v6.10.0. Helpers 4-8 from P2's full DSL would only have 1-2 consumers each and are deferred to v6.11.0.

### Rejected alternatives (with roadmap slot)

1. **T1-A1-innovative (full 8-helper DSL + 30 net-new scenarios, 22-28h).** REJECTED for v6.10.0. **Assigned to v6.11.0 "DSL Maturation"** as a roadmap entry — post-OSS-announcement, when telemetry on the 3-helper subset justifies expansion and the blast-radius concern (P3-T1-A4) can be mitigated with a formal review discipline. The 30 net-new scenarios are split: the state-machine suite (10 scenarios) becomes v6.11.0 "Autopilot Hardening" test coverage; the invariant suite (10 scenarios) becomes the v6.10.1 partition for the 9 remaining REWRITEs.

2. **T1-A3-skeptical (defer ALL 14 REWRITEs).** REJECTED as primary — accepted as **contingency fallback** if mid-sprint any of the 5 top-REWRITEs hits an unexpected complexity (e.g., awk extractor fails on a specific function). Documented in Phase 4 spec as the abort-lane. The 9 non-top-5 REWRITEs are already in v6.10.1.

### Adversarial pass/fail

| Scenario | Pass / Fail | Mitigation |
|---|---|---|
| **T1-ADV-1** (malicious `$(curl)` in fixture construction) | **PASS** (partial — relies on PR-review discipline) | CONTRIBUTING.md checklist item #1 explicitly forbids `$(...)` in fixture construction. **Theater-honest disclosure in Phase 4 spec:** no automated gate; depends on maintainer review. Accepted residual risk — scored LOWER than the false confidence of claiming CI enforcement. |
| **T1-ADV-2** (TOCTOU / symlink on `$SCRATCH`) | **PASS** | `setup_scratch()` helper implements the double-quoted trap verbatim per checklist item #6. Helper enforces what prose-only checklists can't. |
| **T1-ADV-3** (awk+source subshell as code-lift vector) | **PARTIAL PASS** | 3-helper DSL intentionally DOES NOT include an `extract_fn()` helper — the awk/source pattern remains inline per scenario. Only 2 of 5 REWRITEs (`v6.9.0-pause-timeout-validation.sh`, `v6.9.0-outcome-failed-trap.sh`) use the awk+source idiom. Each new use is PR-reviewed against checklist item #4. **Accepted residual risk** — this threat class is fully closed only when P3-T1-A3 is adopted (defer all REWRITEs). Phase 4 spec must explicitly disclose. |

### Effort

**18–22 person-hours** (midpoint: 20h).
- RETIRE=5 × 10min = 50min
- EXTEND=8 × 45min = 6h
- REWRITE=5 × ~1.5h/each (DSL-lite saves ~30min/scenario) = 7.5h
- `tests/lib/fixtures.sh` 3-helper implementation + port existing functional scenario as smoke = 3h
- CONTRIBUTING.md security section = 1.5h
- Phase 9 enumeration extension to `v6.9.0-doc-count-drift.sh` = 1h
- Naming/review pass + full harness run = 1h
- Buffer = 1h

---

## Track 2: Agent Dispatch Enforcement (layers 1+2+4)

### Recommended approach

**`T2-HYBRID = T2-A1-conservative (base: Layer 1 + plugin-shipped opt-in hook + Layer 4) + T2-A4-skeptical (dispatched_at presence-check replacing tokens_used>100) + T2-A5-skeptical (plain-text audit log, not JSON in hot path) + T2-A3-skeptical (log-and-warn, not block)`**

Concrete scope:
- **Layer 1**: Mechanical prose rewrite at all 42 sites per Phase 2 `§ Dispatch-Prose Enumeration`. Canonical imperative template: `You MUST invoke Task(subagent_type='ceos-agents:{name}', model='{model}'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` Files: `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md`, `core/fixer-reviewer-loop.md`. [T2-A1-conservative]
- **Layer 1 prerequisite**: update `tests/scenarios/pipeline-agent-dispatch-models.sh:92` grep pattern to match BOTH old and new prose (defensive + forward-compat) BEFORE running the Layer 1 sed. [Phase 2 Discrepancy #4]
- **Layer 2 (hook)**: ship `hooks/validate-dispatch.sh` in the plugin repository (reviewable in every PR). Script contract per T2-A3-skeptical + T2-A5-skeptical:
  - Hardcoded `STAGES=(triage code_analysis fixer_reviewer test publisher)` whitelist (no dynamic stage discovery per Phase 2 schema-stability invariant).
  - Presence-check on `{stage}.dispatched_at` ISO-8601 field, NOT `tokens_used > 100` (T2-A4-skeptical — the `>100` threshold is near-zero-signal theater per T2-ADV-2).
  - Zero `$(...)` / backticks; zero `eval`; `2>/dev/null` on every `jq` call; `jq -e` for validation.
  - **Exit 0 always** (advisory / log-and-warn mode, NOT blocking) — per T2-A3-skeptical, eliminates T2-ADV-4 privilege-escalation risk.
  - Plain-text 3-field append to `.ceos-agents/dispatch-audit.log`: `printf '%s %s %s\n' "$TIMESTAMP" "$stage" "$verdict"` — no JSON-parsing in hot path (T2-A5-skeptical).
  - NOT auto-installed by `/ceos-agents:init`. Operator copies from `hooks/validate-dispatch.sh` into their `~/.claude/settings.json` following `docs/guides/dispatch-enforcement.md`.
- **Layer 2 state schema extension**: add `dispatched_at` (ISO-8601 string, populated by Task-tool dispatch) to `state/schema.md` as OPTIONAL additive field. Schema version stays `"1.0"`. Phase 9 enumeration audit updated. No state contract break. [T2-A4-skeptical]
- **Layer 2 Phase 4 research gate**: external research on Claude Code PostToolUse hook API MUST complete with HIGH confidence before Layer 2 spec is frozen (Phase 2 Discrepancy #5, T2-Q6 MEDIUM). If research returns inconclusive, Layer 2 falls back to T2-A5-conservative (documentation-only, no shipped script) — an explicit abort-lane.
- **Layer 4 (functional test)**: `tests/scenarios/v6.10.0-skill-dispatch-enforcement.sh` built using Track 1's 3-helper DSL-lite. Assertions: (a) positive case — synthetic state.json with `dispatched_at` populated → PASS; (b) negative case — state.json with missing `dispatched_at` → FAIL with expected audit log line; (c) validator script exists at `hooks/validate-dispatch.sh`; (d) validator contains hardcoded STAGES whitelist. [T2-A1-conservative + Cross-Track §X-5]
- **`/ceos-agents:check-setup`** gets an advisory line item reporting PostToolUse hook installed or not. Does not error. [T2-A1-innovative §check-setup addition]
- **`docs/guides/dispatch-enforcement.md`** (new ~80 lines operator guide) + **`docs/reference/hooks.md`** (new ~60 lines — documents exit codes, `dispatched_at` schema, installation stanza, future extensibility). Neither is a CLAUDE.md change — pure operator opt-in surface. [T2-A1-conservative + T2-A1-innovative's docs positioning]

### Rationale

Persona 1's T2-A1-conservative has the flaw that the hook uses `tokens_used > 100` — Persona 3's T2-ADV-2 correctly demonstrates this is near-zero-signal theater (a single Read of a 2KB file crosses 100 tokens, so inline-executors trivially bypass). Persona 2's T2-A1-innovative has the flaw that JSON-event hot-path parsing opens attack surface (P3-T2-A5 — crafted deep nesting / jq CVE exposure on every tool-call). Persona 3's T2-A1-skeptical (Layer 1 only, drop Layer 2 and Layer 4) has the flaw that it ships only one of three roadmap-committed layers — the dispatch enforcement contract has no runtime anchor and no test coverage.

The hybrid takes P1's plugin-shipped opt-in positioning (reviewable, not auto-installed in `~/.claude/settings.json`, which closes T2-ADV-4 privilege-escalation), P3's `dispatched_at` presence-check (closes T2-ADV-2 theater), P3's exit-0-always advisory mode (closes T2-ADV-4 "broken hook = broken Claude Code" footgun), P3's plain-text append-only log (closes T2-ADV-5-analogue — no JSON in hot path), and P1's full Layer-4 functional test using Track 1's DSL-lite (ROI from §X-5 cross-track — 1.5h not 6-10h). Persona 2's JSON schema idea is NOT dropped — it is **inverted**: the hook writes plain text; offline consumers parse; the schema doc at `docs/reference/hooks.md` specifies that format so future observability tools can ingest `awk`-parseable logs without re-implementing. Net: all three roadmap layers ship, with defensible security + a roadmap entry for promoting advisory→blocking in v6.10.1 once the `dispatched_at` field is populated across the install base.

### Rejected alternatives (with roadmap slot)

1. **T2-A1-innovative (JSON-event-emitting hook with schema versioning, 14-18h).** REJECTED for v6.10.0 — JSON parsing in a hook that runs on every tool-call is an attack surface (P3-T2-A5). **Assigned to v6.11.0 "Autopilot Hardening + Observability"** as the cross-run circuit breaker work already ships structured events there; at that point plain-text → JSON conversion is a natural companion step and the offline parser runs out-of-hot-path.

2. **T2-A1-skeptical (Layer 1 only, drop Layer 2 and Layer 4 entirely).** REJECTED — ships only 1 of 3 committed layers. **Assigned as abort-lane fallback:** if Phase 4 external research on PostToolUse API returns inconclusive, fall back to this + Layer 4 (T2-A2-skeptical). Documented in Phase 4 spec abort-lane table.

3. **T2-A3-conservative (plugin-auto-installs hook via `/ceos-agents:init`).** REJECTED — T2-ADV-4 privilege-escalation risk (global `~/.claude/settings.json` scope means a malicious PR compromising the hook compromises every Claude Code project on operator's machine). Not assigned — permanently rejected.

### Adversarial pass/fail

| Scenario | Pass / Fail | Mitigation |
|---|---|---|
| **T2-ADV-1** (command injection via crafted state.json field values) | **PASS** | Hook uses hardcoded `STAGES` whitelist + `jq -e -r ".${stage}.dispatched_at // empty"` — stage names are never interpolated from state.json. No `$(...)` in any error-log line per static-review contract. |
| **T2-ADV-2** (`tokens_used > 100` theater — trivial bypass by context-read) | **PASS** | `dispatched_at` presence-check replaces `tokens_used > 100` entirely. Presence of a timestamp field is not bypassable by context-read alone — it requires the Task tool to write it. |
| **T2-ADV-3** (Autopilot Bash-subprocess bypass of PostToolUse hook) | **FAIL** (acknowledged) | Autopilot subprocess `claude -p ... --dangerously-skip-permissions` may not trigger hooks. **Phase 4 spec MUST** include an external research task on `--dangerously-skip-permissions` × PostToolUse interaction. If hook does not fire in autopilot-subprocess context, the audit log will simply not reflect autopilot runs — advisory-only semantics mean this is *degraded observability*, not a broken pipeline. **Accepted risk** with explicit v6.10.1 follow-up to resolve (tracked as roadmap item "Autopilot dispatch audit parity"). |
| **T2-ADV-4** (global `~/.claude/settings.json` privilege-escalation blast radius) | **PASS** | (a) Hook is NOT auto-installed by `/ceos-agents:init` — operator-copies from reviewable `hooks/validate-dispatch.sh`. (b) Exit 0 always — a malicious patch to the hook cannot *brick* Claude Code (worst case: audit log has garbage). (c) No global write surface — only append-only log to `.ceos-agents/` directory. |

### Effort

**10–14 person-hours** (midpoint: 12h).
- Layer 1 mechanical rewrites at 42 sites (sed + manual review) = 3h
- `pipeline-agent-dispatch-models.sh:92` grep update (pre-Layer-1 prerequisite) = 15min
- `hooks/validate-dispatch.sh` implementation (hardcoded STAGES, `dispatched_at` check, exit-0, plain-text log) = 2h
- `state/schema.md` additive `dispatched_at` field + Phase 9 enumeration update = 45min
- `docs/guides/dispatch-enforcement.md` operator guide = 1.5h
- `docs/reference/hooks.md` reference = 1h
- Layer 4 scenario via Track 1 DSL-lite = 1.5h
- `/ceos-agents:check-setup` advisory line = 30min
- Phase 4 external PostToolUse API research reconciliation (script contract matches returned API) = 1h
- Review + full harness run = 1h
- Buffer for external-API surprises = 1h

---

## Track 3: Prompt-injection Constraint

### Recommended approach

**`T3-HYBRID = T3-A2-skeptical (11-agent scope — roadmap was wrong) + T3-A2-conservative (defensive verbatim regression check on 10 existing) + T3-A1-innovative's enumeration-based test (REJECTED inheritance mechanism, kept enumeration-over-files pattern)`**

Concrete scope:
- **Scope = 11 agents** (not 8): the 8 roadmap targets (`spec-reviewer`, `spec-writer`, `rollback-agent`, `sprint-planner`, `scaffolder`, `stack-selector`, `deployment-verifier`, `publisher`) **PLUS** the 3 empirically-unpatched agents (`test-engineer`, `e2e-test-engineer`, `backlog-creator`). **Scope decision = 11. Do not defer the 3 to v6.10.1.** [T3-A2-skeptical + T3-A5-conservative reasoning]
- **Mechanical insertion**: single-line NEVER bullet at end of `## Constraints` section in each of 11 agent files, verbatim copy from `agents/code-analyst.md:120`, byte-identical. For sprint-planner + publisher (end with Block Comment Template fenced block per Phase 2 T3-Q3), the NEVER bullet appears AFTER the closing ` ``` ` as a plain bullet — matching the `reviewer.md:123-132` precedent exactly. [T3-A1-conservative]
- **Enumeration-based test**: rewrite `tests/scenarios/prompt-injection-protection.sh` to enumerate `agents/*.md` via `find agents -maxdepth 1 -name '*.md' -not -name 'README.md'` and assert each file contains the canonical NEVER bullet **AS BYTE-IDENTICAL TEXT** (grep -qF on the full canonical string from `code-analyst.md:120`). This replaces the hardcoded `AGENTS_TO_CHECK` array — every future new agent is automatically audited from the day its file lands in the directory. [T3-A1-innovative's enumeration pattern, T3-A2-conservative's byte-identical check]
- **Regression guard for 10 existing**: the byte-identical enumeration check now also fails if any of the 10 currently-patched agents (fixer, reviewer, triage-analyst, code-analyst, architect, acceptance-gate, spec-analyst, priority-engine, reproducer, browser-verifier — per Phase 2 `prompt-injection-protection.sh`) drifts from canonical. [T3-A2-conservative]
- **NO HTML-comment wrapper tag convention** (T3-A1-innovative's central idea). REJECTED per T3-A5-skeptical: inheritance = indirection = places where a future PR silently weakens the constraint by editing one file. Verbatim copy in every agent = PR-review visibility = the defense. [T3-A5-skeptical]
- **NO frontmatter schema change** (T3-A3-innovative). REJECTED per Persona 2's own self-rejection — CLAUDE.md "Versioning Policy" classifies frontmatter changes as potentially MAJOR; v6.10.0 is MINOR-only.
- **NO homoglyph defense in v6.10.0**: T3-ADV-2 (Cyrillic/zero-width marker forgery) is acknowledged as NOT CLOSED by prose constraints. Add subsection to `core/agent-states.md` titled "Tracker content normalization — deferred to v6.11.0" citing T3-ADV-2 as motivation. **Honest scope disclosure.** [T3-A4-skeptical]
- **NO producer-side marker-nesting defense in v6.10.0**: T3-ADV-1 (self-referential END-then-START forgery) is acknowledged as NOT CLOSED by prose constraints alone. T3-A3-skeptical's proposal to add a "markers do not nest" clause to 21 agent files is **REJECTED for v6.10.0** — it doubles the release's diff surface, relies on probabilistic LLM compliance, and has no test harness. Add to `core/agent-states.md` deferred-items subsection. [T3-A4-skeptical extension]
- **Roadmap correction**: `docs/plans/roadmap.md` v6.10.0 Track 3 line corrected from "8 agents" to "11 agents (Phase 2 research confirmed v6.9.0 patch claim on test-engineer/e2e-test-engineer/backlog-creator was empirically false)". [Phase 2 Discrepancy #2]
- **Canonical-source-pointer correction**: `docs/plans/roadmap.md` v6.10.0 Track 1 + Track 3 lines corrected from `agents/test-engineer.md` to `agents/code-analyst.md:120`. [Phase 2 Discrepancy #1]

### Rationale

Persona 1's T3-A1-conservative has the flaw that it holds the roadmap's scope=8 as a ceiling and leaves 3 verified-unpatched receivers exposed — "uneven defense is unacceptable for public release" (user's own words in MEMORY.md) is a stronger commitment device than the stale roadmap line. Persona 2's T3-A1-innovative has the flaw that the HTML-comment tag wrapper is inheritance indirection (P3-T3-A5 — future PR can weaken one file and affect all), AND the frontmatter variant (T3-A3-innovative) risks MAJOR versioning (P2 self-rejected). Persona 3's T3-A3-skeptical has the flaw that a "markers don't nest" clause doubles diff surface with only probabilistic LLM enforcement — real security value is marginal.

The hybrid takes P3's 11-agent scope (user's literal release intent trumps stale roadmap — Phase 2 empirically confirmed the 3 gaps), P2's enumeration-based test pattern (auto-audits every future new agent, closes the "whoops forgot to update the hardcoded list" drift class), P1's verbatim-copy discipline (PR-review visibility is the defense, not inheritance), P1's byte-identical regression check on the 10 already-patched agents (1-hour cost, catches accidental drift), and P3's honest deferral of T3-ADV-1/2 to v6.11.0 (homoglyph + marker-nesting defenses require eval harness + normalization layer, both out-of-scope for this mechanical release). Net: the release's actual security-posture delta is +11 patched agents (100% uniform coverage) + 1 auto-audit mechanism + 2 honestly-disclosed residual risks.

### Rejected alternatives (with roadmap slot)

1. **T3-A1-innovative (HTML-comment `<!-- external-input-boundary:start v1 -->` wrapper + convention doc, 4.5-6h).** REJECTED for v6.10.0 — inheritance indirection per P3-T3-A5. **NOT assigned to a future roadmap slot** — permanently rejected per the "canonical text lives only at `code-analyst.md:120`" discipline.

2. **T3-A3-skeptical ("markers do not nest" clause in 21 agents, 4-5h).** REJECTED for v6.10.0 — doubles diff surface with probabilistic LLM-enforcement-only value. **Assigned to v6.11.0 "Prompt-injection defense-in-depth"** WHERE IT IS PAIRED WITH a tracker-content normalization layer (T3-A4-skeptical's v6.11.0 deferral) and an LLM-eval harness.

3. **T3-A3-innovative (frontmatter `external_input: {mode, version}` field).** REJECTED — MINOR-only versioning guardrail violation. Not assigned.

### Adversarial pass/fail

| Scenario | Pass / Fail | Mitigation |
|---|---|---|
| **T3-ADV-1** (self-referential END-then-START marker forgery) | **FAIL (acknowledged)** | Prose constraints alone cannot close this deterministically — LLM behavior on forged nested markers is probabilistic. Defense-in-depth (producer-side sanitization + "markers don't nest" clause) deferred to v6.11.0 with explicit `core/agent-states.md` subsection. **Accepted residual risk** with explicit roadmap paper trail. |
| **T3-ADV-2** (homoglyph / zero-width character bypass) | **FAIL (acknowledged)** | Same as T3-ADV-1. Requires NFKC normalization + zero-width stripping at producer side — an implementation layer that does not exist. Deferred to v6.11.0. Phase 8 verification MUST NOT claim homoglyph defense closes this release. |
| **T3-ADV-3** (producer-side marker-stripping layer) | **FAIL (acknowledged)** | No producer-side contract exists guaranteeing markers are preserved across agent-to-agent forwarding. v6.11.0 "Prompt-injection defense-in-depth" roadmap entry addresses. |
| **T3-ADV-{new}** (uneven defense across 21 agents — public release externally-visible gap) | **PASS** | Scope = 11 patches bring coverage from 10/21 to 21/21. Enumeration-based test prevents future drift. |

Three acknowledged FAILs above are **not v6.10.0 blockers** — v6.10.0's Track 3 goal is *uniform coverage*, not *attack-resistant receiver semantics*. Phase 4 spec MUST explicitly disclose these 3 as residual open vulnerabilities. Phase 8 Commander MUST NOT score Track 3 as "prompt-injection closed"; correct framing is "prompt-injection receiver constraint uniformly applied".

### Effort

**3–4 person-hours** (midpoint: 3.5h).
- 11 agent-file NEVER bullet insertions × ~5min = 55min (sprint-planner + publisher take ~10min each for fenced-block positioning = +10min)
- Byte-identical regression check extension to 10 existing agents = 1h
- Rewrite `prompt-injection-protection.sh` to enumerate `find agents/*.md` + grep-qF canonical text = 1h
- Roadmap.md corrections (Discrepancy #1 + #2) + `core/agent-states.md` deferred-items subsection = 45min
- Harness full run + verification = 30min

---

## Decisions That Phase 4 Spec MUST Formalize

1. **Track 3 scope = 11 agents (NOT 8).** Phase 4 spec explicitly lists: spec-reviewer, spec-writer, rollback-agent, sprint-planner, scaffolder, stack-selector, deployment-verifier, publisher, test-engineer, e2e-test-engineer, backlog-creator. Roadmap.md corrected in same commit.

2. **Track 1 REWRITE scope = top-5 only.** Phase 4 spec freezes the 5-scenario list (pause-timeout-validation, needs-clarification-dos-cap, circuit-breaker-semantics, pipeline-history-pii-scope, outcome-failed-trap). Remaining 9 REWRITEs assigned to v6.10.1 roadmap entry (explicit list).

3. **Track 1 shared-helper scope = 3 helpers only.** Phase 4 spec specifies exact API surface of `tests/lib/fixtures.sh`: `make_state_json()`, `setup_scratch()`, `require_jq()`. NOT the 8-helper DSL. Full DSL + 30 net-new scenarios are v6.11.0 "DSL Maturation" roadmap items.

4. **Track 2 Layer 2 threshold = `dispatched_at` presence check, NOT `tokens_used > 100`.** Phase 4 spec freezes the hook contract: hardcoded STAGES whitelist, exit-0-always advisory mode, plain-text 3-field append-only log, zero JSON construction in hot path. `state/schema.md` gains additive `dispatched_at` field.

5. **Track 2 Layer 2 installation = plugin-shipped opt-in, NOT auto-installed by `/ceos-agents:init`.** Operator copies hook entry from `hooks/validate-dispatch.sh` per `docs/guides/dispatch-enforcement.md`. `/ceos-agents:check-setup` gains advisory line item. No `/ceos-agents:init` modification.

6. **Phase 4 external research tasks (MUST complete before Phase 5 begins):**
   - (a) Claude Code PostToolUse hook API: JSON schema, exit-code semantics, trigger conditions, hook entry format in `~/.claude/settings.json` (Phase 2 T2-Q6 — HIGHEST uncertainty).
   - (b) `--dangerously-skip-permissions` × PostToolUse hook interaction (T2-ADV-3). If hook does not fire in autopilot-subprocess context, degrade gracefully (documented in hooks.md; v6.10.1 follow-up "Autopilot dispatch audit parity").
   - Abort-lane: if (a) returns inconclusive with LOW confidence, Layer 2 falls back to documentation-only (T2-A5-conservative / T2-A2-skeptical hybrid). Phase 4 spec must include this fallback path explicitly.

7. **Track 3 residual risk disclosure.** Phase 4 spec + Phase 8 verification MUST explicitly disclose T3-ADV-1 (nested marker forgery), T3-ADV-2 (homoglyph bypass), T3-ADV-3 (producer-side stripping) as NOT CLOSED in v6.10.0. Roadmap.md v6.11.0 "Prompt-injection defense-in-depth" entry added with all three as motivation.

8. **Roadmap discrepancy corrections applied in Phase 4 spec (single unified commit):**
   - Canonical source `test-engineer.md` → `code-analyst.md:120` (Discrepancy #1).
   - v6.9.0 patched-3 claim removed, Track 3 scope corrected to 11 (Discrepancy #2).
   - v6.9.0-webhook-proto-coverage RETIRE added as Track 1 prerequisite (Discrepancy #3).
   - pipeline-agent-dispatch-models.sh grep update added as Track 2 prerequisite (Discrepancy #4).
   - PostToolUse API external-research gate added as Phase 4 explicit blocker (Discrepancy #5).

---

## Roadmap Discrepancies — Resolution

| # | Phase 2 Discrepancy | Resolution in recommendation |
|---|---|---|
| 1 | Canonical source wrong (`test-engineer.md` → `code-analyst.md:120`) | Track 3 scope uses `code-analyst.md:120`. Roadmap corrected in same PR. Decision #8. |
| 2 | False v6.9.0 patch claim on 3 agents | Track 3 scope = 11 (includes the 3). Roadmap corrected. Decision #1. |
| 3 | `v6.9.0-webhook-proto-coverage.sh` RETIRE missing from roadmap | Track 1 RETIRE=5 list includes it; exit 77 added BEFORE Track 2 Layer 1. Phase 4 spec makes prerequisite-ordering explicit. |
| 4 | `pipeline-agent-dispatch-models.sh:92` grep break not in roadmap | Track 2 prerequisite step: update grep pattern defensively (match both old + new prose) BEFORE Layer 1 sed. |
| 5 | Layer 2 API gap not in roadmap | Phase 4 external research gate (Decision #6). Abort-lane to documentation-only Layer 2 if research inconclusive. |

---

## Aggregate Effort & Risk

- **Total person-hours: 30–36 (midpoint 33h).**
  - Track 1: 18–22h (midpoint 20h)
  - Track 2: 10–14h (midpoint 12h)
  - Track 3: 3–4h (midpoint 3.5h)
  - Cross-track buffer (roadmap corrections unified commit, harness-full-run gates between tracks): +2h included in track subtotals.

- **Highest-risk element:** **Track 2 Layer 2** — Claude Code PostToolUse hook API is NOT documented in-repo (Phase 2 T2-Q6 MEDIUM confidence). Mitigation: (a) Phase 4 external research gate with explicit abort-lane to documentation-only fallback; (b) hook is plugin-shipped opt-in (not auto-installed), so an API-format error does not break operator installs; (c) exit-0-always semantics mean a broken hook logs garbage but does not block pipelines.

- **Second-highest risk:** **T2-ADV-3** (Autopilot Bash-subprocess bypass) — acknowledged FAIL, degraded-observability not broken-pipeline. Phase 4 task (b) resolves before Phase 5.

- **Third-highest risk:** **Track 3 T3-ADV-1/2/3** (nested markers, homoglyphs, producer-side stripping) — acknowledged FAILs, honestly disclosed in Phase 4 spec + Phase 8 Commander guidance. v6.11.0 "Prompt-injection defense-in-depth" roadmap entry addresses.

- **Release-cadence health:** 33h aggregate is ~4.1 workdays. v6.9.0 shipped in ~5M tokens; v6.10.0 forge pipeline can realistically target ~3-4M tokens (fewer new scenarios, more mechanical rewrites). No release-cadence blockers.

- **Go/no-go: READY FOR GATE 1.** All 5 Phase 2 roadmap discrepancies resolved. All 3 persona adversarial scenarios honored (passed or accepted with mitigation + roadmap slot). Scope decision 8-vs-11 resolved to **11** with cited rationale. Layer 2 abort-lane defined. DSL-lite scope defensibly minimal. Roadmap paper trail complete. No unassigned rejected alternatives.
