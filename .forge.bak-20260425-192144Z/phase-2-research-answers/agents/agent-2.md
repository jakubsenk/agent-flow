# Phase 2 Research Answers — Track 2: Agent Dispatch Enforcement (Agent 2)

Generated: 2026-04-23
Scope: Track 2 questions T2-Q1 through T2-Q13 (13 questions total)

---

## T2-Q1 Answer

**Q1 Answer:** The complete enumeration of permissive dispatch prose lines across all four in-scope pipeline skills and the core loop contract follows. The current form is `ceos-agents:{name} (Task tool, model: {model})` or bare `Run {name} (Task tool, model: {model})`. Total distinct dispatch sites: **42 lines** across 5 files (fix-ticket: 13, fix-bugs: 13, implement-feature: 12, scaffold: ~4 inline + 10 template-style, fixer-reviewer-loop: 2). Agents appearing at dispatch sites: triage-analyst (×2), code-analyst (×2), architect (×2), fixer (×6), reviewer (×4), test-engineer (×4), deployment-verifier (×4), e2e-test-engineer (×4), browser-verifier (×2), acceptance-gate (×2), publisher (×2), reproducer (×2), spec-analyst (×1), stack-selector (×1), scaffolder (×2), spec-writer (×1), spec-reviewer (×3), rollback-agent (×1), backlog-creator (×1).

**Evidence:**
- `C:/gitea_ceos-agents/skills/fix-ticket/SKILL.md` lines 179, 280, 311, 349, 351, 352, 353, 389, 409, 499-500, 513, 537, 554, 573, 586, 611, 637 (grep `Task tool, model:`)
- `C:/gitea_ceos-agents/skills/fix-bugs/SKILL.md` lines 182, 294, 347, 382, 384, 385, 386, 427, 463, 552-553, 576, 603, 636, 673, 702, 741, 782
- `C:/gitea_ceos-agents/skills/implement-feature/SKILL.md` lines 227, 253, 268, 366, 452, 456, 485, 505, 526, 543, 583, 598
- `C:/gitea_ceos-agents/skills/scaffold/SKILL.md` lines 284, 299, 446, 462, 472, 522, 606, 613, 696, 777, 852, 873, 902, 931, 949, 962
- `C:/gitea_ceos-agents/core/fixer-reviewer-loop.md` lines 20, 24

**Confidence:** HIGH

**Residual Uncertainty:** The scaffold skill has both inline (`Run scaffolder agent`) and template-style dispatch blocks. Phase 4 spec must enumerate scaffold separately because some dispatch lines are inside `{if}` conditional blocks (making mechanical count unreliable from grep alone).

---

## T2-Q2 Answer

**Q2 Answer:** The roadmap prescribes a SINGLE canonical template string for Layer 1 prose rewrites at `docs/plans/roadmap.md` line 919. The exact quoted form is:

> `"You MUST invoke Task(subagent_type='ceos-agents:fixer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator."`

This template includes: (a) imperative `You MUST invoke Task(...)` verb, (b) `subagent_type='ceos-agents:{name}'` parameter, (c) `model='{model}'` parameter, (d) `DO NOT inline-execute` explicit prohibition, (e) `CONTRACT VIOLATION` warning phrase, (f) reference to `post-skill validator`. The roadmap presents this as an illustrative example for `fixer` — Phase 4 must generalize it as a template for all dispatch sites, substituting `{agent_name}` and `{model}`. It is NOT just an illustrative structure — the roadmap uses quoted literal form, indicating this IS the intended canonical string.

**Evidence:**
- `C:/gitea_ceos-agents/docs/plans/roadmap.md` line 919 (Layer 1 bullet, verbatim quoted form)

**Confidence:** HIGH

**Residual Uncertainty:** Whether `subagent_type=` uses single quotes `'...'` or double quotes in the actual Task tool call format. The roadmap uses single-quote Python-style notation which may differ from Claude Code Task tool actual parameter syntax. Phase 4 spec should confirm Claude Code Task tool parameter quoting convention.

---

## T2-Q3 Answer

**Q3 Answer:** The roadmap section "Agent Dispatch Enforcement → v6.10.0" uses a numbered 5-layer list where each item is labeled by function. "Layer 2" refers EXCLUSIVELY to the **PostToolUse hook + `validate-dispatch.sh` script** (`~/.claude/settings.json` hook that fires after every Skill invocation and reads `state.json`). The roadmap's "Recommended v6.10.0 scope" line (line 929) says: `Layers 1 + 2 + 4 (~12h total)`. In the list, Layer 2 = item #2 (PostToolUse hook + validator), and Layer 4 = item #4 (functional dispatch enforcement test). There is NO per-skill pre-dispatch checklist item anywhere in the Layer 2 description. The phrase "per-skill dispatch checklists" does NOT appear in the roadmap at all — this appears to be a Phase 1 research question framing artifact. Layer 2 deliverables are precisely: (a) a `validate-dispatch.sh` script, (b) a `~/.claude/settings.json` PostToolUse hook entry wiring that script, (c) documentation for operators to install it.

**Evidence:**
- `C:/gitea_ceos-agents/docs/plans/roadmap.md` lines 917-929 (5-layer list + recommended scope line)
- `C:/gitea_ceos-agents/docs/plans/roadmap.md` line 921 (Layer 2 verbatim description)

**Confidence:** HIGH

**Residual Uncertainty:** Whether the PostToolUse hook ships INSIDE the plugin (as a file at e.g. `hooks/validate-dispatch.sh`) or is purely documentation-driven. See T2-Q4.

---

## T2-Q4 Answer

**Q4 Answer:** `validate-dispatch.sh` does NOT exist anywhere in the repository. No `hooks/` directory exists at the top level. Confirmed by filesystem check: `find C:/gitea_ceos-agents -name "validate-dispatch.sh"` returns empty; `ls C:/gitea_ceos-agents/hooks/` returns "NO HOOKS DIR". The roadmap describes the script as a `~/.claude/settings.json` PostToolUse hook — operator-installed, NOT shipped in the plugin. The `/ceos-agents:init` skill (`skills/init/SKILL.md`) generates `.claude/settings.json` with permission entries (Step 8), but it generates NO PostToolUse hook entries — the settings.json template only contains `permissions.allow` array (lines 287-297). Neither `/ceos-agents:check-setup` nor any other skill references `validate-dispatch.sh` or PostToolUse hooks. This confirms: the script is a **net-new artifact** that does not exist in v6.9.2. Phase 4 must specify: (a) where the script file ships (plugin `hooks/` dir vs operator-generated by `/ceos-agents:init`), (b) the exact `~/.claude/settings.json` hook stanza format, (c) whether `/ceos-agents:init` is updated to install it.

**Evidence:**
- `C:/gitea_ceos-agents/skills/init/SKILL.md` lines 285-297 (settings.json generation — no PostToolUse hook present)
- `C:/gitea_ceos-agents/docs/plans/roadmap.md` line 921 (Layer 2 description — `~/.claude/settings.json` hook)
- NOT FOUND IN REPO: `validate-dispatch.sh`, `hooks/` directory

**Confidence:** HIGH

**Residual Uncertainty:** The Claude Code PostToolUse hook API format is not documented anywhere in this repository. See T2-Q6 for the gap analysis.

---

## T2-Q5 Answer

**Q5 Answer:** For a `fix-ticket` run, the validator needs to assert on these `state.json` stage keys (from `state/schema.md` full schema example and per-stage field definitions):
- `triage.tokens_used` (model: sonnet)
- `code_analysis.tokens_used` (model: sonnet)
- `fixer_reviewer.tokens_used` (model: opus, cumulative across iterations)
- `test.tokens_used` (model: sonnet)
- `publisher.tokens_used` (model: haiku)

Optional stages (conditional on config): `reproduction.tokens_used` (sonnet), `browser_verification.tokens_used` (sonnet), `acceptance_gate.tokens_used` (sonnet), `deployment.tokens_used` (sonnet), `e2e_test.tokens_used` (sonnet).

The `> 100` threshold cited in the roadmap (line 921: "asserts each expected stage has `tokens_used > 100`") is the ROADMAP-CANONICAL threshold — not merely illustrative. It appears in the roadmap as a concrete value, not surrounded by hedging language like "e.g." or "approximately". However, `fixer_reviewer.tokens_used` is cumulative across ALL fixer+reviewer iterations — for a 1-iteration run with inline execution, parent-context tokens could appear in the parent, not in the stage field, making the `> 100` assertion the detection heuristic: a real dispatched Task call always consumes more than 100 tokens.

**Evidence:**
- `C:/gitea_ceos-agents/state/schema.md` lines 71-84 (triage stage fields), 86-97 (code_analysis), 110-122 (fixer_reviewer), 129-140 (test), 174-183 (publisher)
- `C:/gitea_ceos-agents/docs/plans/roadmap.md` line 921 (`tokens_used > 100` threshold — canonical per roadmap)

**Confidence:** HIGH

**Residual Uncertainty:** Whether `fixer_reviewer.tokens_used` accumulates BOTH fixer and reviewer tokens (confirmed by fixer-reviewer-loop.md step 10: "accumulate usage fields: `fixer_reviewer.tokens_used += iteration_tokens_used`") or only fixer tokens. Confirmed: it's cumulative for both in a single `fixer_reviewer` bucket. The validator cannot separate fixer from reviewer token attribution.

---

## T2-Q6 Answer

**Q6 Answer:** The Claude Code PostToolUse hook API format is NOT documented anywhere in this repository. The relevant brainstorm file `docs/plans/brainstorm/06-session-resume-permissions.md` describes the `~/.claude/settings.json` `permissions.allow` array but makes NO mention of PostToolUse hooks. The `docs/guides/troubleshooting.md` documents `.claude/settings.json` only for `permissions.allow` (lines 223-237). No file in the repository contains the strings "PostToolUse", "post-tool-use", or "hookEvent". This is a **documentation gap** — the repo has no Claude Code hook API specification.

What CAN be inferred from the roadmap description (line 921): "hook fires after every `Skill` invocation... On violation: emit `[FATAL] Skill orchestration violation: $stage did not dispatch agent` and **halt**." The roadmap uses "halt" — implying exit code non-zero blocks the skill. The brainstorm file documents that `.claude/settings.json` format `may vary by Claude Code version` (line 27). The settings.json generated by `/ceos-agents:init` uses only `permissions.allow` — no hook entries (confirmed from `skills/init/SKILL.md` lines 285-297).

NOT FOUND IN REPO: PostToolUse hook API documentation, exit-code semantics specification, JSON input schema for hooks.

**Evidence:**
- `C:/gitea_ceos-agents/docs/plans/brainstorm/06-session-resume-permissions.md` lines 26-37 (settings.json format — no hook entries)
- `C:/gitea_ceos-agents/docs/guides/troubleshooting.md` lines 223-237 (settings.json permissions — no hook entries)
- `C:/gitea_ceos-agents/skills/init/SKILL.md` lines 285-297 (generated settings.json — no hook entries)
- `C:/gitea_ceos-agents/docs/plans/roadmap.md` line 921 (only description of hook behavior in the whole repo)

**Confidence:** MEDIUM (gap confirmed; inferred exit-code semantics from roadmap prose "halt")

**Residual Uncertainty:** Phase 4 spec MUST include a research task to determine Claude Code PostToolUse hook API: (a) JSON input schema (does it receive tool call name, output, timestamp?), (b) exact exit code semantics (0=allow, 2=block, other=warn?), (c) whether it fires after `Task` tool specifically vs all tools, (d) how to wire it in `~/.claude/settings.json` vs `.claude/settings.json`. This is the HIGHEST residual uncertainty for the entire Track 2.

---

## T2-Q7 Answer

**Q7 Answer:** The `v6.9.0-needs-clarification-e2e.sh` functional test pattern to reuse for the dispatch enforcement scenario:

**Reusable jq+bash idioms (from that file):**
1. **`jq -n` synthetic state.json builder** (lines 72-98): `jq -n --arg field "value" --argjson numfield 1 '{schema_version: "1.0", run_id: ..., status: ..., stage: {...}}' > "$STATE"` — builds complete state.json from scratch with all required fields.
2. **`SCRATCH="$(mktemp -d ...)"` + `trap 'rm -rf "$SCRATCH"' EXIT`** (lines 37-38): temp dir pattern for test artifacts.
3. **`HAVE_JQ=0; if command -v jq >/dev/null 2>&1; then HAVE_JQ=1; fi`** (lines 31-33): jq availability guard enabling graceful degradation.
4. **`(set +u; . "$SCRIPT"; function_call)` subshell-isolation** (lines 323-378): source a function from a file in a subshell to avoid polluting test environment.
5. **`jq --arg ... '. | .field = $value' "$STATE" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"`** (lines 240-243): atomic state.json mutation pattern.
6. **`jq -r '.field // empty' "$STATE"`** (lines 100, 245): safe nullable field read.

**For the dispatch enforcement scenario** (`tests/scenarios/v6.10.0-skill-dispatch-enforcement.sh`), the new scenario should:
- Use pattern #1 to build a **mock state.json** with pre-populated stage records (hand-crafted, NOT a real subprocess dispatch).
- The "synthetic" in the roadmap (line 925) means option (c) from T2-Q12: hand-crafted state.json inspected by jq assertions.
- The existing doc-grep baseline `pipeline-agent-dispatch-models.sh` greps `Task tool, model:` strings (line 92). The new scenario MUST NOT duplicate this — it tests RUNTIME state, not doc-prose.

The existing `pipeline-agent-dispatch-models.sh` uses grep pattern `Task tool, model:` (line 92). If Layer 1 rewrites change this to imperative form, this test BREAKS — see T2-Q11.

**Evidence:**
- `C:/gitea_ceos-agents/tests/scenarios/v6.9.0-needs-clarification-e2e.sh` lines 31-38, 72-98, 240-243, 323-378
- `C:/gitea_ceos-agents/tests/scenarios/pipeline-agent-dispatch-models.sh` lines 41-44, 92-95
- `C:/gitea_ceos-agents/state/schema.md` lines 71-184 (stage key names)
- `C:/gitea_ceos-agents/docs/plans/roadmap.md` line 925 (Layer 4 description)

**Confidence:** HIGH

**Residual Uncertainty:** Whether the dispatch enforcement test should also verify `model` field per stage (testing model-per-role optimization compliance) or only `tokens_used > 100` (testing dispatch vs inline). Roadmap line 925 says "distinct models per stage" — Phase 4 spec should confirm this means both checks.

---

## T2-Q8 Answer

**Q8 Answer:** The v6.9.2 Autopilot Bash subprocess dispatch (`claude -p "Run ${TARGET_SKILL} ${ISSUE_ID}" --dangerously-skip-permissions`) is a **COMPLIANT and orthogonal** dispatch pattern that Layer 1 rewrites MUST NOT break. Rationale:

1. Layer 1 rewrites target the prose INSIDE pipeline skills (`skills/fix-ticket/SKILL.md` etc.) — these tell the skill's execution context (Claude itself) how to dispatch agents. Autopilot (`skills/autopilot/SKILL.md` Step 6, lines 382-386) dispatches an ENTIRE SKILL via Bash subprocess, not an agent via Task tool. These are two different dispatch levels.

2. The `disable-model-invocation: true` flag in pipeline skill frontmatter (confirmed at `skills/fix-ticket/SKILL.md` line 5: `disable-model-invocation: true`) blocks the Skill tool dispatch path — hence autopilot uses `claude -p` as a bypass workaround (roadmap line 389: "resolves upstream Claude Code #26251 — pipeline skills have `disable-model-invocation: true` in their frontmatter").

3. Agent files (`agents/fixer.md`, etc.) do NOT have `disable-model-invocation: true` in their frontmatter — this flag only appears on pipeline skill frontmatter. Agents are dispatched via Task tool INSIDE skills, which is the target of Layer 1 rewrites. Autopilot dispatches SKILLS (which then dispatch agents) — Layer 1 does not touch autopilot.

4. Layer 1 applies to all 21 agents dispatched via Task tool inside the four pipeline skills AND the `core/fixer-reviewer-loop.md` contract.

**Evidence:**
- `C:/gitea_ceos-agents/skills/autopilot/SKILL.md` lines 367-389 (Step 6 rationale and bash code)
- `C:/gitea_ceos-agents/skills/fix-ticket/SKILL.md` line 5 (`disable-model-invocation: true` in frontmatter)
- `C:/gitea_ceos-agents/core/fixer-reviewer-loop.md` lines 20, 24 (agent dispatch inside loop contract)

**Confidence:** HIGH

**Residual Uncertainty:** None for backward-compat question. Autopilot Step 6 is entirely unaffected by Layer 1 prose rewrites inside skills.

---

## T2-Q9 Answer

**Q9 Answer:** There is NO existing mechanism in `/ceos-agents:init` or `/ceos-agents:check-setup` that generates or validates `~/.claude/settings.json` PostToolUse hook entries. The `/ceos-agents:init` skill generates `.claude/settings.json` with only `permissions.allow` arrays (confirmed from `skills/init/SKILL.md` lines 285-297 — three permission levels: full pipeline, read-only, minimal). No PostToolUse stanza is present in any generated template. The `/ceos-agents:check-setup` skill (`skills/check-setup/SKILL.md`) validates Automation Config, MCP servers, and tokens — it has no Block checking settings.json for PostToolUse hooks. The `docs/guides/troubleshooting.md` "Configure permanent permissions" section (lines 223-237) documents settings.json but only for `permissions.allow`.

The Layer 2 hook installation would be a **net-new documentation and tooling step**. Two implementation options exist: (a) add hook installation to `/ceos-agents:init` Step 8 (currently generates settings.json), (b) create a standalone installation guide section in `docs/guides/`. Phase 4 must choose.

**Evidence:**
- `C:/gitea_ceos-agents/skills/init/SKILL.md` lines 285-297 (generated settings.json — permissions only)
- `C:/gitea_ceos-agents/skills/check-setup/SKILL.md` lines 55-59 (optional sections validated — no hook check)
- `C:/gitea_ceos-agents/docs/guides/troubleshooting.md` lines 223-237 (settings.json docs — permissions only)

**Confidence:** HIGH

**Residual Uncertainty:** Whether `/ceos-agents:init` Step 8 already asks about hooks in a future version. Confirmed it does NOT in v6.9.2.

---

## T2-Q10 Answer

**Q10 Answer:** Layer 3 (pre-flight subagent_type assertion at Step 0a of pipeline skills) is explicitly labeled item #3 in the roadmap's 5-layer list. The roadmap line 923 says: "Pre-flight subagent_type assertion (~4-6h, depends on plugin introspection API availability)" and the "Recommended v6.10.0 scope" line (929) says "Layers 1 + 2 + 4" — Layer 3 is **excluded from v6.10.0 scope** (deferred, not merged). No existing Step 0a or 0b in `fix-ticket` or `implement-feature` constitutes a Layer 3 implementation.

In `fix-ticket`, Step 0 is `MCP pre-flight check` (checking issue tracker MCP availability, not agent subagent_type registration). Step 0b is `Config Validity Gate` (checking that CLAUDE.md Automation Config has no TODOs). Neither touches subagent_type registration or plugin introspection. The existing Step 0b Config Validity Gate serves a DIFFERENT dispatch-validation role (config completeness) — it must be preserved unchanged. Layer 3 defers pending Claude Code plugin introspection API availability.

**Evidence:**
- `C:/gitea_ceos-agents/skills/fix-ticket/SKILL.md` lines 83-114 (Step 0: MCP pre-flight check), lines 115-130 (Step 0b: Config Validity Gate)
- `C:/gitea_ceos-agents/skills/implement-feature/SKILL.md` lines 71-116 (Steps 0 and MCP pre-flight)
- `C:/gitea_ceos-agents/docs/plans/roadmap.md` lines 917-929 (5-layer list: item 3 = Layer 3, scope = Layers 1+2+4)

**Confidence:** HIGH

**Residual Uncertainty:** None. Layer 3 scope question is definitively answered by roadmap line 929.

---

## T2-Q11 Answer

**Q11 Answer:** YES — the existing test `tests/scenarios/pipeline-agent-dispatch-models.sh` WILL BREAK if Layer 1 rewrites change the prose from the current `Task tool, model:` form to the new imperative form.

The test uses this exact grep pattern at line 92:
```bash
done < <(grep "Task tool, model:" "$cmd_file" || true)
```

If Layer 1 rewrites change `Run ceos-agents:triage-analyst (Task tool, model: sonnet)` to `You MUST invoke Task(subagent_type='ceos-agents:triage-analyst', model='sonnet'). DO NOT inline-execute...`, the string `"Task tool, model:"` will no longer appear in the dispatch lines. The grep at line 92 will produce empty output, all dispatch entries will be silently skipped, and the test will pass vacuously (no assertions = no failures). This is a **false-positive regression** — the test would pass while providing zero coverage.

Phase 4 spec must include: update `pipeline-agent-dispatch-models.sh` line 92 grep pattern to match the new imperative prose form (e.g., `grep -E "Task\(subagent_type=|Task tool, model:"` to cover both old and new), OR retire/rewrite the test as part of Track 1 Test Discipline Overhaul.

The new imperative replacement form from the roadmap (line 919) would match: `grep -oE "Task\(subagent_type='ceos-agents:[a-z-]+', model='[a-z]+'"`

**Evidence:**
- `C:/gitea_ceos-agents/tests/scenarios/pipeline-agent-dispatch-models.sh` line 92 (current grep pattern `Task tool, model:`)
- `C:/gitea_ceos-agents/tests/scenarios/pipeline-agent-dispatch-models.sh` lines 41-44 (extraction logic using `Task tool, model:` pattern)
- `C:/gitea_ceos-agents/docs/plans/roadmap.md` line 919 (new imperative form — no `Task tool, model:` substring)

**Confidence:** HIGH

**Residual Uncertainty:** The exact imperative replacement form may retain some portion of `model:` in a different position. Phase 4 must confirm final prose form and update the test grep accordingly.

---

## T2-Q12 Answer

**Q12 Answer:** The roadmap Layer 4 functional test description (line 925: "runs synthetic skill against mock issue, asserts: each stage has nonzero distinct `tokens_used`, sequential timestamps (not parallel-parent-context), distinct models per stage") means option **(c): hand-crafted state.json inspected by jq assertions** — NOT actual subprocess dispatch. This is confirmed by the established precedent in `v6.9.0-needs-clarification-e2e.sh` which uses `jq -n` to construct a synthetic state.json and then runs assertions against it (lines 72-98). Option (b) ("actual invocation of `fix-ticket` with `--dry-run`") is ruled out because `fix-ticket` has `disable-model-invocation: true` in its frontmatter — it cannot run as a subcommand inside a test scenario without a full Claude session.

The "synthetic skill" in the roadmap means: the test SCRIPT itself acts as the synthetic skill, writing a mock state.json with the correct shape, then the validator (or jq assertions in the test) reads it to verify structural compliance. This is a documentation test with a functional jq layer — the same hybrid pattern as `v6.9.0-needs-clarification-e2e.sh`.

**Evidence:**
- `C:/gitea_ceos-agents/docs/plans/roadmap.md` line 925 (Layer 4 description)
- `C:/gitea_ceos-agents/tests/scenarios/v6.9.0-needs-clarification-e2e.sh` lines 72-98 (jq -n synthetic state.json pattern — established precedent)
- `C:/gitea_ceos-agents/skills/fix-ticket/SKILL.md` line 5 (`disable-model-invocation: true` — rules out option b)

**Confidence:** HIGH

**Residual Uncertainty:** Whether `validate-dispatch.sh` itself should be sourced and tested functionally (like `sanitize_block_reason()` in Bug 6 of v6.9.0-needs-clarification-e2e.sh lines 316-378) or whether the scenario simply uses jq directly. If `validate-dispatch.sh` is shipped in the plugin, it should be sourced and tested functionally.

---

## T2-Q13 Answer

**Q13 Answer:** Adding Layer 1 prose rewrites (changing `Run ceos-agents:fixer (Task tool, model: opus)` to `You MUST invoke Task(subagent_type='ceos-agents:fixer', model='opus'). DO NOT inline-execute.`) does NOT constitute a breaking change to the agent output format contract and therefore does NOT trigger a MAJOR version bump.

Per CLAUDE.md `## Versioning Policy`:
- MAJOR trigger: "Breaking change in Automation Config contract — new required key, renamed section — OR breaking change in agent output format contract (new/modified structured output sections that Agent Overrides or external tooling may parse)"
- The Layer 1 changes are in `skills/*/SKILL.md` files (orchestration instructions to Claude), NOT in `agents/*.md` files
- Agent output format contracts are defined in `agents/*.md` structured output sections (e.g., triage-analyst's checkpoint comment format, reviewer's AC Fulfillment section, architect's maps_to field)
- SKILL.md prose rewrites change HOW Claude is instructed to dispatch agents — this is prompt-input hardening analogous to the EXTERNAL INPUT Constraint batch (per research-answers.md persona anti-pattern #7: "DO NOT treat agent-prompt changes as agent-output-contract changes")
- The Agent Overrides path remains unchanged — `.md` override files continue to work
- No Automation Config required keys are added
- The roadmap entry (line 817-820) classifies this as a quality sprint / refactor bundled in a MINOR release

Per roadmap line 820: "2. **Agent Dispatch Enforcement** (bundled with Test Discipline)" — the containing version is v6.10.0 (MINOR bump from 6.9.2). No MAJOR-version statement appears anywhere in the roadmap's v6.10.0 section.

**Evidence:**
- `C:/gitea_ceos-agents/CLAUDE.md` §"Versioning Policy" (MAJOR trigger definition — output format contract, not SKILL.md prose)
- `C:/gitea_ceos-agents/docs/plans/roadmap.md` lines 817-820 (v6.10.0 classification as quality sprint / MINOR)
- `C:/gitea_ceos-agents/docs/plans/roadmap.md` line 919 (Layer 1 description — SKILL.md prose change, not agent output format)

**Confidence:** HIGH

**Residual Uncertainty:** None. SKILL.md prose is definitively not agent output format contract per CLAUDE.md versioning policy and per anti-pattern #7 in research-answers.md.

---

## § Dispatch-prose enumeration

Complete table of current permissive dispatch prose across all in-scope files, with proposed imperative replacements.

### skills/fix-ticket/SKILL.md

| file | approx line | current prose | proposed imperative replacement |
|------|-------------|--------------|--------------------------------|
| fix-ticket/SKILL.md | 179 | `Run \`ceos-agents:triage-analyst\` (Task tool, model: sonnet).` | `You MUST invoke Task(subagent_type='ceos-agents:triage-analyst', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` |
| fix-ticket/SKILL.md | 280 | `Run \`ceos-agents:code-analyst\` (Task tool, model: sonnet).` | `You MUST invoke Task(subagent_type='ceos-agents:code-analyst', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` |
| fix-ticket/SKILL.md | 311 | `Run the architect agent (Task tool, model: opus):` | `You MUST invoke Task(subagent_type='ceos-agents:architect', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` |
| fix-ticket/SKILL.md | 349 | `Run fixer (Task tool, model: opus).` | `You MUST invoke Task(subagent_type='ceos-agents:fixer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` |
| fix-ticket/SKILL.md | 351 | `Run reviewer (Task tool, model: opus).` | `You MUST invoke Task(subagent_type='ceos-agents:reviewer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` |
| fix-ticket/SKILL.md | 352 | `Run test-engineer (Task tool, model: sonnet).` | `You MUST invoke Task(subagent_type='ceos-agents:test-engineer', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` |
| fix-ticket/SKILL.md | 353 | `run deployment-verifier (Task tool, model: sonnet, action: start).` | `You MUST invoke Task(subagent_type='ceos-agents:deployment-verifier', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` |
| fix-ticket/SKILL.md | 389 | `Run \`ceos-agents:reproducer\` (Task tool, model: sonnet).` | `You MUST invoke Task(subagent_type='ceos-agents:reproducer', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` |
| fix-ticket/SKILL.md | 409 | `Run \`ceos-agents:fixer\` (Task tool, model: opus).` | `You MUST invoke Task(subagent_type='ceos-agents:fixer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` |
| fix-ticket/SKILL.md | 499-500 | `Run as Task with the model from the agent's frontmatter` | `You MUST invoke Task(subagent_type='{custom_agent_type}', model='{model_from_frontmatter}'). DO NOT inline-execute.` (custom agent — no CONTRACT VIOLATION phrase; model read at runtime) |
| fix-ticket/SKILL.md | 513 | `Run \`ceos-agents:reviewer\` (Task tool, model: opus).` | `You MUST invoke Task(subagent_type='ceos-agents:reviewer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` |
| fix-ticket/SKILL.md | 537 | `Run \`ceos-agents:test-engineer\` (Task tool, model: sonnet).` | `You MUST invoke Task(subagent_type='ceos-agents:test-engineer', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` |
| fix-ticket/SKILL.md | 554 | `Run \`ceos-agents:deployment-verifier\` (Task tool, model: sonnet).` | `You MUST invoke Task(subagent_type='ceos-agents:deployment-verifier', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` |
| fix-ticket/SKILL.md | 573 | `Run \`ceos-agents:e2e-test-engineer\` (Task tool, model: sonnet)` | `You MUST invoke Task(subagent_type='ceos-agents:e2e-test-engineer', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` |
| fix-ticket/SKILL.md | 586 | `Run \`ceos-agents:browser-verifier\` (Task tool, model: sonnet).` | `You MUST invoke Task(subagent_type='ceos-agents:browser-verifier', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` |
| fix-ticket/SKILL.md | 611 | `Run \`ceos-agents:acceptance-gate\` (Task tool, model: sonnet):` | `You MUST invoke Task(subagent_type='ceos-agents:acceptance-gate', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` |
| fix-ticket/SKILL.md | 637 | `run \`ceos-agents:publisher\` (Task tool, model: haiku).` | `You MUST invoke Task(subagent_type='ceos-agents:publisher', model='haiku'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator.` |

### skills/fix-bugs/SKILL.md

Same agents as fix-ticket — parallel dispatch sites. Key differences: dispatches use `For each bug, run` prefix. All need the same imperative replacement. Complete table:

| file | approx line | current prose | proposed imperative replacement |
|------|-------------|--------------|--------------------------------|
| fix-bugs/SKILL.md | 182 | `For each bug, run \`ceos-agents:triage-analyst\` (Task tool, model: sonnet).` | `For each bug, you MUST invoke Task(subagent_type='ceos-agents:triage-analyst', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| fix-bugs/SKILL.md | 294 | `For each OK bug, run \`ceos-agents:code-analyst\` (Task tool, model: sonnet).` | `For each OK bug, you MUST invoke Task(subagent_type='ceos-agents:code-analyst', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| fix-bugs/SKILL.md | 347 | `Run the architect agent (Task tool, model: opus):` | `You MUST invoke Task(subagent_type='ceos-agents:architect', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| fix-bugs/SKILL.md | 382 | `Run fixer (Task tool, model: opus).` | `You MUST invoke Task(subagent_type='ceos-agents:fixer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| fix-bugs/SKILL.md | 384 | `Run reviewer (Task tool, model: opus).` | `You MUST invoke Task(subagent_type='ceos-agents:reviewer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| fix-bugs/SKILL.md | 385 | `Run test-engineer (Task tool, model: sonnet).` | `You MUST invoke Task(subagent_type='ceos-agents:test-engineer', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| fix-bugs/SKILL.md | 386 | `run deployment-verifier (Task tool, model: sonnet, action: start).` | `You MUST invoke Task(subagent_type='ceos-agents:deployment-verifier', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| fix-bugs/SKILL.md | 427 | `Run \`ceos-agents:reproducer\` (Task tool, model: sonnet).` | `You MUST invoke Task(subagent_type='ceos-agents:reproducer', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| fix-bugs/SKILL.md | 463 | `For each bug, run \`ceos-agents:fixer\` (Task tool, model: opus).` | `For each bug, you MUST invoke Task(subagent_type='ceos-agents:fixer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| fix-bugs/SKILL.md | 552-553 | `Run as Task with the model from the agent's frontmatter` | Same as fix-ticket custom agent note above |
| fix-bugs/SKILL.md | 576 | `Run \`ceos-agents:reviewer\` (Task tool, model: opus).` | `You MUST invoke Task(subagent_type='ceos-agents:reviewer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| fix-bugs/SKILL.md | 603 | `Run \`ceos-agents:test-engineer\` (Task tool, model: sonnet).` | `You MUST invoke Task(subagent_type='ceos-agents:test-engineer', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| fix-bugs/SKILL.md | 636 | `Run \`ceos-agents:deployment-verifier\` (Task tool, model: sonnet).` | `You MUST invoke Task(subagent_type='ceos-agents:deployment-verifier', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| fix-bugs/SKILL.md | 673 | `Run \`ceos-agents:e2e-test-engineer\` (Task tool, model: sonnet)` | `You MUST invoke Task(subagent_type='ceos-agents:e2e-test-engineer', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| fix-bugs/SKILL.md | 702 | `Run \`ceos-agents:browser-verifier\` (Task tool, model: sonnet).` | `You MUST invoke Task(subagent_type='ceos-agents:browser-verifier', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| fix-bugs/SKILL.md | 741 | `Run \`ceos-agents:acceptance-gate\` (Task tool, model: sonnet):` | `You MUST invoke Task(subagent_type='ceos-agents:acceptance-gate', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| fix-bugs/SKILL.md | 782 | `Run \`ceos-agents:publisher\` (Task tool, model: haiku).` | `You MUST invoke Task(subagent_type='ceos-agents:publisher', model='haiku'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |

### skills/implement-feature/SKILL.md

| file | approx line | current prose | proposed imperative replacement |
|------|-------------|--------------|--------------------------------|
| implement-feature/SKILL.md | 227 | `Run the spec-analyst agent (Task tool, model: sonnet):` | `You MUST invoke Task(subagent_type='ceos-agents:spec-analyst', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| implement-feature/SKILL.md | 253 | `Run \`ceos-agents:code-analyst\` (Task tool, model: sonnet).` | `You MUST invoke Task(subagent_type='ceos-agents:code-analyst', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| implement-feature/SKILL.md | 268 | `Run the architect agent (Task tool, model: opus):` | `You MUST invoke Task(subagent_type='ceos-agents:architect', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| implement-feature/SKILL.md | 366 | `Run the fixer agent (Task tool, model: opus):` | `You MUST invoke Task(subagent_type='ceos-agents:fixer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| implement-feature/SKILL.md | 452 | `If Custom Agents → Post-fix agent exists: run via Task tool.` | `If Custom Agents → Post-fix agent exists: you MUST dispatch via Task(subagent_type='{agent_type}', model='{model}'). DO NOT inline-execute.` |
| implement-feature/SKILL.md | 456 | `Run the reviewer agent (Task tool, model: opus):` | `You MUST invoke Task(subagent_type='ceos-agents:reviewer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| implement-feature/SKILL.md | 485 | `Run the test-engineer agent (Task tool, model: sonnet):` | `You MUST invoke Task(subagent_type='ceos-agents:test-engineer', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| implement-feature/SKILL.md | 505 | `Run \`ceos-agents:deployment-verifier\` (Task tool, model: sonnet).` | `You MUST invoke Task(subagent_type='ceos-agents:deployment-verifier', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| implement-feature/SKILL.md | 526 | `Run the e2e-test-engineer agent (Task tool, model: sonnet).` | `You MUST invoke Task(subagent_type='ceos-agents:e2e-test-engineer', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| implement-feature/SKILL.md | 543 | `Run \`ceos-agents:acceptance-gate\` (Task tool, model: sonnet):` | `You MUST invoke Task(subagent_type='ceos-agents:acceptance-gate', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| implement-feature/SKILL.md | 583 | `If Custom Agents → Pre-publish agent exists: run via Task tool.` | `If Custom Agents → Pre-publish agent exists: you MUST dispatch via Task. DO NOT inline-execute.` |
| implement-feature/SKILL.md | 598 | `Run the publisher agent (Task tool, model: haiku):` | `You MUST invoke Task(subagent_type='ceos-agents:publisher', model='haiku'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |

### skills/scaffold/SKILL.md

| file | approx line | current prose | proposed imperative replacement |
|------|-------------|--------------|--------------------------------|
| scaffold/SKILL.md | 284 | `Run the stack-selector agent (Task tool, model: sonnet):` | `You MUST invoke Task(subagent_type='ceos-agents:stack-selector', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| scaffold/SKILL.md | 299 | `Run the scaffolder agent (Task tool, model: sonnet):` | `You MUST invoke Task(subagent_type='ceos-agents:scaffolder', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| scaffold/SKILL.md | 446 | `Run spec-reviewer (Task tool, model: opus) to validate spec_path.` | `You MUST invoke Task(subagent_type='ceos-agents:spec-reviewer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| scaffold/SKILL.md | 462 | `Run spec-writer (Task tool, model: opus):` | `You MUST invoke Task(subagent_type='ceos-agents:spec-writer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| scaffold/SKILL.md | 472 | `Run spec-reviewer (Task tool, model: opus) to review spec/` | `You MUST invoke Task(subagent_type='ceos-agents:spec-reviewer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| scaffold/SKILL.md | 522 | `Run scaffolder agent (Task tool, model: sonnet):` | `You MUST invoke Task(subagent_type='ceos-agents:scaffolder', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| scaffold/SKILL.md | 606+613 | `Dispatch backlog-creator agent via Task tool (model: sonnet...)` / `Dispatch \`backlog-creator\` agent (sonnet) in task mode via Task tool.` | `You MUST invoke Task(subagent_type='ceos-agents:backlog-creator', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| scaffold/SKILL.md | 696 | `Run architect agent (Task tool, model: opus):` | `You MUST invoke Task(subagent_type='ceos-agents:architect', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| scaffold/SKILL.md | 777 | `**7a. Fixer** (Task tool, model: opus):` | `**7a. Fixer:** You MUST invoke Task(subagent_type='ceos-agents:fixer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| scaffold/SKILL.md | 852 | `**7b. Reviewer** (Task tool, model: opus):` | `**7b. Reviewer:** You MUST invoke Task(subagent_type='ceos-agents:reviewer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| scaffold/SKILL.md | 873 | `**7c. Test-engineer** (Task tool, model: sonnet):` | `**7c. Test-engineer:** You MUST invoke Task(subagent_type='ceos-agents:test-engineer', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| scaffold/SKILL.md | 902 | `Run rollback-agent (Task tool, model: haiku)` | `You MUST invoke Task(subagent_type='ceos-agents:rollback-agent', model='haiku'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| scaffold/SKILL.md | 931 | `Run spec-reviewer in verify mode (Task tool, model: opus):` | `You MUST invoke Task(subagent_type='ceos-agents:spec-reviewer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| scaffold/SKILL.md | 949 | `Run \`ceos-agents:deployment-verifier\` (Task tool, model: sonnet).` | `You MUST invoke Task(subagent_type='ceos-agents:deployment-verifier', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| scaffold/SKILL.md | 962 | `Run e2e-test-engineer agent (Task tool, model: sonnet):` | `You MUST invoke Task(subagent_type='ceos-agents:e2e-test-engineer', model='sonnet'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |

### core/fixer-reviewer-loop.md

| file | line | current prose | proposed imperative replacement |
|------|------|--------------|--------------------------------|
| core/fixer-reviewer-loop.md | 20 | `Dispatch \`ceos-agents:fixer\` (Task tool, model: opus) with context + any previous reviewer feedback.` | `You MUST invoke Task(subagent_type='ceos-agents:fixer', model='opus') with context + any previous reviewer feedback. DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |
| core/fixer-reviewer-loop.md | 24 | `Dispatch \`ceos-agents:reviewer\` (Task tool, model: opus) with fixer's changes + AC list.` | `You MUST invoke Task(subagent_type='ceos-agents:reviewer', model='opus') with fixer's changes + AC list. DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION.` |

**IMPORTANT NOTE for Phase 4 fixer:** The `core/fixer-reviewer-loop.md` already uses `Dispatch` verb (lines 20, 24) rather than `Run`. The contract form `Dispatch ceos-agents:X (Task tool, model: Y)` is slightly different from the SKILL.md form `Run ceos-agents:X (Task tool, model: Y)`. Both must be replaced with imperative form.

---

## § `validate-dispatch.sh` inventory + PostToolUse hook contract

### Inventory

`validate-dispatch.sh` — **NOT FOUND IN REPO**

Searched: `find C:/gitea_ceos-agents -name "validate-dispatch.sh"` — empty result.
No `hooks/` directory exists at `C:/gitea_ceos-agents/hooks/`.

This script is a **Phase 4 creation target** — it does not exist in v6.9.2.

### PostToolUse hook contract (inferred + confirmed gaps)

**What IS documented in the repo:**

The repo documents `~/.claude/settings.json` structure only for `permissions.allow`:
```json
{
  "permissions": {
    "allow": ["Read", "Write", "Edit", "Glob", "Grep", "Bash", "mcp__*"]
  }
}
```
Source: `C:/gitea_ceos-agents/skills/init/SKILL.md` lines 287-297; `C:/gitea_ceos-agents/docs/guides/troubleshooting.md` lines 228-237; `C:/gitea_ceos-agents/docs/plans/brainstorm/06-session-resume-permissions.md` lines 29-37.

The brainstorm file notes at line 27: "Presny JSON format (`permissions.allow`, `permissions.deny`) je odvozeny z pozorovaneho chovani Claude Code a muze se lisit mezi verzemi platformy." (Exact JSON format is derived from observed Claude Code behavior and may differ between versions.)

**What the roadmap says about PostToolUse behavior:**

From `C:/gitea_ceos-agents/docs/plans/roadmap.md` line 921:
> "PostToolUse hook + validate-dispatch.sh script (~3h) — `~/.claude/settings.json` hook fires after every `Skill` invocation. Script reads `.ceos-agents/state.json`, asserts each expected stage has `tokens_used > 100` (real agent dispatched). On violation: emit `[FATAL] Skill orchestration violation: $stage did not dispatch agent` and halt."

From this we can infer:
- Hook type: PostToolUse (fires AFTER a tool is used, not before)
- Trigger: Fires after every `Skill` invocation (i.e., after each ceos-agents pipeline skill completes)
- Script interface: reads `.ceos-agents/state.json` (standard path) — no explicit argument or stdin specification
- Violation output: `[FATAL] Skill orchestration violation: $stage did not dispatch agent` to stderr
- Exit code on violation: "halt" — implies non-zero exit

**NOT FOUND IN REPO — gaps Phase 4 must resolve externally:**
1. JSON schema for PostToolUse hook entry in `~/.claude/settings.json` (what key, what value)
2. Whether PostToolUse receives tool output on stdin or as a file
3. Exact exit-code semantics: does 0=allow, 2=block, other=warn? Or is it just 0=pass, non-zero=halt?
4. Whether "after every Skill invocation" means after the skill's TOOL CALL or after the skill's COMPLETE EXECUTION
5. Whether the hook fires in pipeline context where state.json would already be populated

**Proposed `validate-dispatch.sh` detection heuristic** (Phase 4 spec target):
```bash
# validate-dispatch.sh — PostToolUse hook for dispatch enforcement
ISSUE_ID="${1:-}"  # passed as argument or read from tool output on stdin
STATE_FILE=".ceos-agents/${ISSUE_ID}/state.json"
[ -f "$STATE_FILE" ] || exit 0  # no state = not a pipeline skill call, skip

EXPECTED_STAGES="triage code_analysis fixer_reviewer test"
for stage in $EXPECTED_STAGES; do
  tokens=$(jq -r ".${stage}.tokens_used // 0" "$STATE_FILE" 2>/dev/null)
  if [ "${tokens:-0}" -le 100 ]; then
    echo "[FATAL] Skill orchestration violation: ${stage} did not dispatch agent (tokens_used=${tokens})" >&2
    exit 2  # halt
  fi
done
exit 0
```

---

## § Layer boundary disambiguation

| Layer | Scope | v6.10.0 status | Description |
|-------|-------|----------------|-------------|
| Layer 1 | SKILL.md prose (orchestrator-facing) | IN SCOPE | Replace permissive `Run X (Task tool, model: Y)` with imperative `You MUST invoke Task(subagent_type=...)`. ~30 min. Addresses the root instruction ambiguity. |
| Layer 2 | PostToolUse hook + `validate-dispatch.sh` (operator-installed) | IN SCOPE | `~/.claude/settings.json` hook that fires after each Skill invocation, reads state.json, asserts `tokens_used > 100` per stage. ~3h. Provides post-hoc deterministic detection. |
| Layer 3 | Pre-flight subagent_type assertion at Step 0a of pipeline skills | EXCLUDED from v6.10.0 | Verifies that `ceos-agents:*` subagent_types are registered at runtime. Deferred — depends on Claude Code plugin introspection API availability. |
| Layer 4 | Functional dispatch enforcement test scenario | IN SCOPE | `tests/scenarios/v6.10.0-skill-dispatch-enforcement.sh` — hand-crafted mock state.json + jq assertions. ~6-10h. CI-time catch. |

**What was Layer 3?** Layer 3 = "Pre-flight subagent_type assertion" — Step 0a in pipeline skills that would verify all required `ceos-agents:*` subagent_types are registered in the Claude Code runtime. It is NOT merged into any other layer; it is DEFERRED pending plugin introspection API availability. No existing Step 0a exists in any pipeline skill (confirmed by reading fix-ticket and implement-feature Steps 0-0c).

**Roadmap citation:** `C:/gitea_ceos-agents/docs/plans/roadmap.md` lines 917-929, specifically:
- Line 923: Layer 3 definition ("Pre-flight subagent_type assertion (~4-6h, depends on plugin introspection API availability)")
- Line 929: "Recommended v6.10.0 scope: Layers 1 + 2 + 4 (~12h total)." — Layer 3 explicitly absent from recommended scope.

---

## § Functional dispatch-enforcement test scenario skeleton

```bash
#!/usr/bin/env bash
# tests/scenarios/v6.10.0-skill-dispatch-enforcement.sh
# Functional dispatch enforcement test — validates state.json structural
# compliance for post-dispatch agent records.
#
# Pattern: Uses jq -n to build synthetic state.json (from v6.9.0-needs-clarification-e2e.sh)
# Does NOT invoke actual pipeline skills (disable-model-invocation: true blocks that).
#
# AC-1: Positive case — distinct model per stage → validator PASS
# AC-2: Negative case — tokens_used == 0 in critical stage → validator FAIL (exit 2)
# AC-3: Negative case — single model for all stages (inline-execution smell) → detector fires
# AC-4: Sequential timestamps (started_at < completed_at per stage)
#
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Pre-flight
HAVE_JQ=0
command -v jq >/dev/null 2>&1 && HAVE_JQ=1
SCRATCH="$(mktemp -d 2>/dev/null || mktemp -d -t 'v610dispatch')"
trap 'rm -rf "$SCRATCH"' EXIT

# ===== AC-1: Positive case — dispatched agents, distinct models, nonzero tokens =====
echo "--- AC-1 (positive): all stages dispatched with distinct models and nonzero tokens ---"

if [ "$HAVE_JQ" = "1" ]; then
  STATE_POS="$SCRATCH/state_positive.json"
  jq -n '{
    schema_version: "1.0",
    run_id: "PROJ-1_20260423T120000Z",
    status: "completed",
    triage: {
      status: "completed", model: "sonnet", tokens_used: 12500,
      started_at: "2026-04-23T12:00:00Z", completed_at: "2026-04-23T12:00:45Z"
    },
    code_analysis: {
      status: "completed", model: "sonnet", tokens_used: 18200,
      started_at: "2026-04-23T12:01:00Z", completed_at: "2026-04-23T12:02:02Z"
    },
    fixer_reviewer: {
      status: "completed", model: "opus", tokens_used: 201000,
      started_at: "2026-04-23T12:02:30Z", completed_at: "2026-04-23T12:11:15Z"
    },
    test: {
      status: "completed", model: "sonnet", tokens_used: 15800,
      started_at: "2026-04-23T12:11:30Z", completed_at: "2026-04-23T12:12:18Z"
    },
    publisher: {
      status: "completed", model: "haiku", tokens_used: 3200,
      started_at: "2026-04-23T12:12:30Z", completed_at: "2026-04-23T12:12:42Z"
    }
  }' > "$STATE_POS"

  # Each stage: tokens_used > 100
  for stage in triage code_analysis fixer_reviewer test publisher; do
    tokens=$(jq -r ".${stage}.tokens_used // 0" "$STATE_POS")
    if [ "${tokens:-0}" -gt 100 ]; then
      echo "OK (AC-1): ${stage}.tokens_used=${tokens} > 100 (dispatched)"
    else
      fail "AC-1: ${stage} tokens_used=${tokens} — NOT dispatched (inline execution smell)"
    fi
  done

  # Models are DISTINCT across execution stages (not all identical)
  models=$(jq -r '[.triage.model, .code_analysis.model, .fixer_reviewer.model, .test.model, .publisher.model] | unique | length' "$STATE_POS")
  if [ "$models" -gt 1 ]; then
    echo "OK (AC-1): $models distinct models across stages (expected 3: sonnet/opus/haiku)"
  else
    fail "AC-1: only 1 distinct model — inline execution smell (all stages running same model)"
  fi
fi

# ===== AC-2: Negative case — tokens_used == 0 in critical stage → FAIL =====
echo "--- AC-2 (negative): critical stage tokens_used == 0 → validator must detect ---"

if [ "$HAVE_JQ" = "1" ]; then
  STATE_NEG="$SCRATCH/state_negative_zero_tokens.json"
  jq -n '{
    schema_version: "1.0",
    run_id: "PROJ-2_20260423T120000Z",
    status: "completed",
    triage: { status: "completed", model: "sonnet", tokens_used: 0,
      started_at: "2026-04-23T12:00:00Z", completed_at: "2026-04-23T12:00:45Z" },
    code_analysis: { status: "completed", model: "sonnet", tokens_used: 0,
      started_at: "2026-04-23T12:01:00Z", completed_at: "2026-04-23T12:01:01Z" },
    fixer_reviewer: { status: "completed", model: "sonnet", tokens_used: 0,
      started_at: "2026-04-23T12:01:05Z", completed_at: "2026-04-23T12:01:06Z" },
    test: { status: "completed", model: "sonnet", tokens_used: 0,
      started_at: "2026-04-23T12:01:10Z", completed_at: "2026-04-23T12:01:11Z" },
    publisher: { status: "completed", model: "sonnet", tokens_used: 0,
      started_at: "2026-04-23T12:01:15Z", completed_at: "2026-04-23T12:01:16Z" }
  }' > "$STATE_NEG"

  # Validator must fire on zero tokens
  violations=0
  for stage in triage code_analysis fixer_reviewer test publisher; do
    tokens=$(jq -r ".${stage}.tokens_used // 0" "$STATE_NEG")
    if [ "${tokens:-0}" -le 100 ]; then
      violations=$((violations + 1))
    fi
  done
  if [ "$violations" -ge 1 ]; then
    echo "OK (AC-2): detected $violations stages with tokens_used <= 100 (validator would fire [FATAL])"
  else
    fail "AC-2: negative case not detected — zero-token stages not caught"
  fi

  # All-same-model smell detection
  distinct=$(jq -r '[.triage.model, .fixer_reviewer.model, .publisher.model] | unique | length' "$STATE_NEG")
  if [ "$distinct" -le 1 ]; then
    echo "OK (AC-2): all stages have identical model (inline execution smell CONFIRMED)"
  else
    fail "AC-2: model-distinctness assertion misclassified inline execution negative case"
  fi
fi

# ===== AC-3: Validator script existence (Phase 4 deliverable check) =====
echo "--- AC-3: validate-dispatch.sh must ship in plugin after v6.10.0 ---"

VALIDATE_SCRIPT="$REPO_ROOT/hooks/validate-dispatch.sh"
if [ -f "$VALIDATE_SCRIPT" ]; then
  echo "OK (AC-3): hooks/validate-dispatch.sh exists"
  # AC-3b: script exits 2 on violation (not 1 or other)
  # Source and test: create zero-tokens state and verify exit code
  if [ "$HAVE_JQ" = "1" ]; then
    test_exit=$(bash "$VALIDATE_SCRIPT" "PROJ-2" "$STATE_NEG" 2>/dev/null; echo $?)
    if [ "${test_exit:-0}" -eq 2 ]; then
      echo "OK (AC-3b): validate-dispatch.sh exits 2 on violation"
    else
      fail "AC-3b: validate-dispatch.sh exit code=${test_exit} (expected 2)"
    fi
  fi
else
  # NOT FOUND is expected in v6.9.2 — this assertion targets post-v6.10.0
  echo "INFO (AC-3): hooks/validate-dispatch.sh NOT YET created (v6.10.0 deliverable)"
fi

# ===== Final =====
[ "$FAIL" -eq 0 ] && echo "PASS: v6.10.0 dispatch enforcement functional test (jq-functional $([ "$HAVE_JQ" = "1" ] && echo "ENABLED" || echo "DEGRADED"))"
exit "$FAIL"
```

**Cross-track reuse from Agent 1 (T1-Q4 pattern):** The `jq -n` builder (lines 72-98 of v6.9.0-needs-clarification-e2e.sh), `mktemp -d` + `trap EXIT` (lines 37-38), and `HAVE_JQ` guard (lines 31-33) are direct copies of the v6.9.0 established pattern.

---

## § Backward-compat analysis

**Layer 1 prose rewrites do NOT break v6.9.2 Autopilot Bash subprocess dispatch.** Detailed analysis:

Autopilot Step 6 (`C:/gitea_ceos-agents/skills/autopilot/SKILL.md` lines 382-386):
```bash
claude -p "Run ${TARGET_SKILL} ${ISSUE_ID}" \
  --dangerously-skip-permissions \
  > ".ceos-agents/${ISSUE_ID}/dispatch-stdout.log" \
  2> ".ceos-agents/${ISSUE_ID}/dispatch-stderr.log"
```

This dispatches SKILLS (`/ceos-agents:fix-ticket`, `/ceos-agents:implement-feature`) as separate `claude -p` Bash subprocesses. It does NOT use the Task tool. Layer 1 rewrites change prose INSIDE skills that tells Claude how to dispatch agents — this is entirely internal to the child session created by `claude -p`. The parent autopilot loop (which writes the `claude -p` invocation) is unchanged.

Explicit rationale at lines 367-389: "pipeline skills have `disable-model-invocation: true` in their frontmatter, which blocks the Skill tool dispatch path; plain-text headless invocation via `claude -p` is the only reliable workaround."

**The two dispatch levels are orthogonal:**
- Autopilot → Skill: via `claude -p` Bash subprocess (unaffected by Layer 1)
- Skill → Agent: via Task tool (TARGET of Layer 1 rewrites)

Layer 1 rewrites making the Skill→Agent dispatch more imperative have no effect on the Autopilot→Skill Bash subprocess dispatch.

**Evidence:**
- `C:/gitea_ceos-agents/skills/autopilot/SKILL.md` lines 367-389 (Step 6 — Bash subprocess dispatch with rationale)
- `C:/gitea_ceos-agents/skills/fix-ticket/SKILL.md` line 5 (`disable-model-invocation: true`)
- `C:/gitea_ceos-agents/docs/plans/roadmap.md` line 819-820 (v6.10.0 scope — "same class of bug as test-discipline")

---

## Summary Table: Track 2 Question Confidence Distribution

| Question | Confidence | Key Finding |
|----------|------------|-------------|
| T2-Q1 | HIGH | 42 dispatch sites across 5 files; complete enumeration above |
| T2-Q2 | HIGH | Canonical template confirmed at roadmap:919 |
| T2-Q3 | HIGH | Layer 2 = PostToolUse hook only; no per-skill checklists |
| T2-Q4 | HIGH | NOT FOUND IN REPO — Phase 4 creation target |
| T2-Q5 | HIGH | 5 required stages; `> 100` threshold is roadmap-canonical |
| T2-Q6 | MEDIUM | PostToolUse API not documented in repo; gap confirmed |
| T2-Q7 | HIGH | Option (c): hand-crafted state.json; jq pattern from v6.9.0-e2e |
| T2-Q8 | HIGH | Autopilot fully backward-compat — orthogonal dispatch levels |
| T2-Q9 | HIGH | Net-new documentation step — init/check-setup don't cover it |
| T2-Q10 | HIGH | Layer 3 deferred; no existing Step 0a; Step 0b unaffected |
| T2-Q11 | HIGH | pipeline-agent-dispatch-models.sh WILL BREAK on Layer 1 |
| T2-Q12 | HIGH | Option (c): hand-crafted state.json inspected by jq assertions |
| T2-Q13 | HIGH | NOT a MAJOR trigger — SKILL.md prose is not agent output contract |

HIGH: 12/13 (92%). MEDIUM: 1/13 (8%). LOW: 0/13.
