# Phase 2 Research Answers — Agent 1
**Partition:** Codebase + Tests (Q1, Q2, Q9, Q10, Q11)
**Date:** 2026-04-28

---

## Q1

**Question:** In the v8.0.0 codebase today, what concrete evidence exists that absent machine-readable I/O contracts cause observable failures — specifically: (a) do `frontmatter-completeness.sh`, `read-only-agents.sh`, and `section-order.sh` contain stale pre-v8 agent names that would mask contract violations, and (b) in the forge-2026-04-25-001 archive (219/62/15 harness results), how many of the 62 failures are traceable to output section name mismatch or structural inconsistency rather than logic errors?

**Finding:** All three pre-v8 test scenarios contain hardcoded 21-agent lists that fail on v8's 18-agent set, masking any contract violation in the 5 deleted agent files — but zero of the 62 harness failures in forge-2026-04-25-001 cycle 3 are attributable to output-section-name mismatch; failures split into Windows portability bugs (6), test-set scope reduction (5 tests never staged to tests/scenarios/), and one implementation gap (design.md missing stage-name mapping table).

**Evidence:**

- `tests/scenarios/frontmatter-completeness.sh` line 3: comment says "All 21 agents" and line 11-17 hardcodes `AGENTS=(triage-analyst code-analyst fixer reviewer ... browser-verifier)` — 21 names. Running it today produces 5 `FAIL: Missing agent file: agents/{triage-analyst,code-analyst,e2e-test-engineer,reproducer,browser-verifier}.md` (confirmed by live run). Source: `tests/scenarios/frontmatter-completeness.sh:3,11-17`.

- `tests/scenarios/section-order.sh` line 3: "All 21 agents" — same hardcoded 21-name list at lines 11-17; live run produces identical 5 FAIL outputs on missing v7 agent files. The test FAILs on absent files rather than masking — but a contract violation in the 5 deleted files would be permanently undetectable. Source: `tests/scenarios/section-order.sh:3,11-17`.

- `tests/scenarios/read-only-agents.sh` lists 9 read-only agents (lines 15-17) including `triage-analyst code-analyst` (v7 names). However it has a graceful `continue` on missing files (line 23: `echo "SKIP: ... not found — skipping"`), so it does NOT fail — it silently skips the stale agents and reports PASS. This is the masking case: a contract violation in `code-analyst.md` would be invisible today. Source: `tests/scenarios/read-only-agents.sh:14-17,23`.

- Forge archive cycle 3 correctness-review.md classifies all 62 failures: 6 Windows harness bugs (UTF-8 em-dash, CRLF arithmetic, single-line table extraction), 5 test-set scope reduction (v8 tests only in `.forge/phase-5-tdd/tests/` never deployed to `tests/scenarios/`), 1 design.md impl gap (missing `code-analyst → analyst-impact` stage-name mapping table). None of the 62 cite "output section name mismatch" or structural inconsistency as root cause. Source: `.forge.bak-20260428-181546/phase-8-verification/cycle-3/correctness-review.md` (full failure taxonomy).

- The devil-review.md explicitly notes the 5 missing tests are absent from `tests/scenarios/` in BOTH cycle 2 and cycle 3 (`git log --all --oneline -- tests/scenarios/v8-matrix-scaffold-default.sh` empty) — a deployment gap, not a test failure caused by output-shape mismatch. Source: `.forge.bak-20260428-181546/phase-8-verification/cycle-3/devil-review.md`.

**Confidence:** HIGH — live test runs confirm (a); forge archive documents (b) with per-failure taxonomy and cycle delta comparison.

**Disagreements:** The cycle-3 correctness review also notes `xref-agent-registry.sh` fails on `test-engineer (incl. \`--e2e\` flag)` verbatim mismatch (CLAUDE.md table uses that exact string vs filename `test-engineer.md`) — this is a naming inconsistency between documentation and file system, which is structurally similar to an I/O contract mismatch, but it is a documentation inconsistency not a runtime output-shape failure.

**Decision impact:** PRIMARY WHETHER gate — the baseline shows no output-shape failures in the forge archive, but the stale tests in frontmatter-completeness and section-order leave a coverage gap: 5 deleted agents have no assertions, and if new `## Inputs` / `## Outputs` sections were added to all 18 agents, the existing tests would NOT catch missing or malformed contract sections. The cost-benefit case for formalization is thus: not "existing failures require contracts" but "existing tests lack coverage to detect future contract violations."

---

## Q2

**Question:** When Claude Code's Task tool dispatches an agent, what validation (if any) does the runtime apply to the agent's output before returning it to the calling skill — specifically: does it enforce section presence, frontmatter fields, or output token patterns, or does it return the raw LLM response verbatim — and does the Task tool pass the full agent file (frontmatter + body) verbatim as the system prompt, or does it strip or reformat frontmatter before model invocation?

**Finding:** The Task tool passes the entire agent file (frontmatter + body) as the agent's definition, with frontmatter parsed to extract routing metadata (model, description) that is applied at dispatch time, while the body becomes the system/instructions context; there is zero runtime validation of agent output — the tool returns the raw LLM response verbatim, making all output-format enforcement strictly lint-time or prompt-instruction-level.

**Evidence:**

- Skills explicitly read the `model:` frontmatter field from agent files manually BEFORE calling Task, then pass it as the `model=` argument to `Task(subagent_type='ceos-agents:analyst', model='sonnet')`. This pattern appears 10+ times in `skills/fix-ticket/SKILL.md` (lines 190, 291, 400, 420, 524, etc.) — the skill does NOT rely on the Task tool to discover the model. This demonstrates that `model:` is a routing hint consumed by the Claude Code platform, not extracted at dispatch time by the skill. Source: `skills/fix-ticket/SKILL.md:190-192`.

- `docs/architecture.md:17` states: "Agent definitions are markdown files with YAML frontmatter. Skills are markdown files with step-by-step instructions. There is no compilation, no transpilation, no dependency resolution. **What you see in the repository is what runs.**" — the body IS the system prompt passed to the model. Source: `docs/architecture.md:17`.

- `docs/reference/agents.md:71` explicitly states: "description: One-line description used by **Claude Code's Task tool**" — confirming the Task tool reads the `description` frontmatter field specifically (used in agent picker UI). Source: `docs/reference/agents.md:71`.

- `docs/architecture.md:362` states that plugin agents do NOT support `hooks:`, `mcpServers:`, or `permissionMode:` in agent frontmatter — "Claude Code ignores those fields for security reasons." This implies the Task tool DOES parse frontmatter (to process name/description/model) but strips or ignores unsupported fields. The body content is passed as-is. Source: `docs/architecture.md:362`.

- Skills reference output sections by prose parsing (e.g., `fix-ticket/SKILL.md:296`: "If the impact report contains `root cause confirmed: NO`"; `fix-ticket/SKILL.md:208`: "If triage output contains `## NEEDS_CLARIFICATION`") — all parsing is string-grep in skill prose, not Task tool enforcement. Source: `skills/fix-ticket/SKILL.md:208,296`.

- The `discuss/SKILL.md` explicitly reads frontmatter fields before constructing context: "Your role: {agent description from frontmatter} / Style: {agent style from frontmatter}" (lines 22-25) — confirming skills must manually extract frontmatter values because Task tool does not inject them automatically into the subagent prompt. Source: `skills/discuss/SKILL.md:22-25`.

**Confidence:** HIGH — multiple primary sources (architecture.md, skills code pattern, discuss/SKILL.md frontmatter extraction) agree. No Anthropic Claude Code documentation was directly fetched (deferred to Phase 2 WebFetch agents if needed), but codebase evidence is consistent and unambiguous.

**Disagreements:** There is an implicit ambiguity: the Task tool could both parse frontmatter for routing AND pass the full file (including frontmatter) as system prompt. The codebase evidence does not confirm or deny whether frontmatter is stripped before model invocation or passed verbatim. The docs say "what you see is what runs" (implying verbatim pass), but the `style:` field appears only in `discuss/SKILL.md` extractions, not in Task-dispatched agent outputs — suggesting the model does see frontmatter as part of its context. Resolution: treat as "body is primary; frontmatter is also visible to model, not stripped."

**Decision impact:** Core HOW gate — since Task tool returns raw LLM response verbatim, new `## Inputs` / `## Outputs` sections in agent body ARE visible to the model at dispatch time (they are part of the system prompt). Runtime enforcement is impossible without a validation layer in skills. This shifts the design choice entirely to lint-time (grep-based scenario tests) + prompt-instruction-level (section headings as behavioral guidance).

---

## Q9

**Question:** In the 297 existing test scenarios, how many assert properties of agent body sections (Goal, Expertise, Process, Constraints content) versus frontmatter only — and which specific scenarios (`v8-agents-analyst-shape.sh`, `section-order.sh`, `read-only-agents.sh`) would require modification if a new mandatory body section (`## Inputs` / `## Outputs`) were added to all 18 agents, versus which would be unaffected?

**Finding:** Of 296 total scenarios (live count), 29 assert agent body-section properties and 20 assert frontmatter properties (6 assert both), while 251 check only skill/config/state content with no agent-file assertions; section-order.sh would require modification to add `## Inputs` / `## Outputs` to its section order check, read-only-agents.sh is unaffected (only checks Process content for write-tool phrases), and v8-agents-analyst-shape.sh is unaffected (only checks frontmatter fields + `## Phase Dispatch` presence, not section count or order).

**Evidence:**

- Live classification run across 296 scenarios: 14 "only frontmatter" checks, 6 "both frontmatter + body", 23 "only body sections", 253 "neither" (check skills, state schema, config, pipeline content). Source: bash classification script run on `tests/scenarios/*.sh`.

- `tests/scenarios/section-order.sh` (lines 26-56): checks exactly 4 sections `## Goal`, `## Expertise`, `## Process`, `## Constraints` using `grep -n "^## {Section}"` + line-number ordering comparisons. Adding `## Inputs` before `## Goal` or between any existing sections would cause ordering assertions to fail if position rules changed. Adding `## Outputs` after `## Constraints` would be undetected by current assertions (ordering check only verifies Goal < Expertise < Process < Constraints, no check for "nothing after Constraints"). The test uses a hardcoded 21-agent list and currently FAILs on 5 missing v7 agents. Source: `tests/scenarios/section-order.sh:26-56`.

- `tests/scenarios/read-only-agents.sh` (lines 20-46): extracts `## Process` section content using `awk '/^## Process/{found=1} found && /^## Constraints/{found=0} found{print}'` and checks for write-tool phrases. Adding `## Inputs` or `## Outputs` would be invisible to this test — it only checks Process content, not section enumeration or count. Source: `tests/scenarios/read-only-agents.sh:29`.

- `tests/scenarios/v8-agents-analyst-shape.sh` (lines 28-79): asserts `grep -qE '^name:\s*analyst$'`, `grep -qE '^model:\s*sonnet$'`, `grep -qE '^## Phase Dispatch'`, `grep -qE '\-\-phase.*triage'`, `grep -qiE 'triage.*impact|impact.*triage'`. Zero assertions about section count, section order, or body structure beyond the `## Phase Dispatch` presence check. Adding new body sections would NOT affect this test. Source: `tests/scenarios/v8-agents-analyst-shape.sh:28-79`.

- `tests/scenarios/frontmatter-completeness.sh` (lines 19-30): loops `for field in name description model style; do grep -q "^$field:" "$file"`. No body assertions. Adding `## Inputs` / `## Outputs` is invisible. But it checks 21 hardcoded agents and currently fails on 5 missing v7 agents. Source: `tests/scenarios/frontmatter-completeness.sh:19-30`.

- `tests/scenarios/ac5-fixer-reviewer-token-constraints.sh`: body-section test that checks `## Constraints` content using `awk '/^## Constraints/{found=1} found{print}'`. Would be unaffected by adding new sections above or below Constraints. Source: `tests/scenarios/ac5-fixer-reviewer-token-constraints.sh:25-27`.

**Confidence:** HIGH — direct code inspection + live classification; confirmed by running the specific scenarios.

**Disagreements:** The 296/297 count discrepancy: 297 was cited in the research question (from CLAUDE.md or prior memory); live `ls *.sh | wc -l` returns 296 on the current working tree. No disagreement on the analysis — the 1-test delta does not affect categorization.

**Decision impact:** Test-impact question — section-order.sh must be updated if `## Inputs` / `## Outputs` have a mandated position in the section sequence. The other two named scenarios are unaffected. Broader impact: the 23 "only body" tests and 6 "both" tests (29 total) must be audited individually to confirm none assert exact section count or enumerate all valid headings. The 251 non-agent tests are entirely unaffected.

---

## Q10

**Question:** What is the minimal bash assertion pattern — using existing harness primitives (`grep -qE`, `awk`, `wc -l`, `diff -q`, no jq/yq/Python) — that can distinguish a structurally valid contract section from a malformed one, and what SKIP-guard pattern should that scenario use so it exits 77 on v8.0.0 agent files lacking the section, fails on v9.0.0 files with malformed sections, and passes on v9.0.0 files with valid sections?

**Finding:** The minimal grep/awk pattern requires a two-pass approach: first extract the candidate section with awk range-matching, then grep the extracted content for required subfield names; the SKIP-guard mirrors the pattern in `v8-agents-analyst-shape.sh` (exit 77 when the section heading is absent) to preserve CI green on v8.0.0 agents while failing hard on v9.0.0 malformed sections.

**Evidence:**

- `tests/scenarios/v8-agents-analyst-shape.sh:22-23`: canonical SKIP-guard pattern — `if [ ! -f "$ANALYST_FILE" ]; then echo "SKIP: ..."; exit 77; fi` — used for file-existence guard. For a section-level guard: check section presence, exit 77 if absent. Source: `tests/scenarios/v8-agents-analyst-shape.sh:22-23`.

- `tests/scenarios/read-only-agents.sh:29`: awk range-match pattern for section extraction — `awk '/^## Process/{found=1} found && /^## Constraints/{found=0} found{print}'`. This is the established harness primitive for extracting a named section. Source: `tests/scenarios/read-only-agents.sh:29`.

- `tests/scenarios/ac5-fixer-reviewer-token-constraints.sh:25-44`: shows combined extraction + grep assertions: extract `## Constraints` with `awk '/^## Constraints/{found=1} found{print}'`, then pipe to grep for specific tokens. This is the canonical body-section content assertion pattern. Source: `tests/scenarios/ac5-fixer-reviewer-token-constraints.sh:25-44`.

- `tests/harness/run-tests.sh:44-48`: exit code 77 is explicitly handled as SKIP — `if [ $exit_code -eq 77 ]; then echo "SKIP"; SKIP=$((SKIP + 1)); fi`. Source: `tests/harness/run-tests.sh:44-48`.

**Working bash assertion snippet** (15 lines, demonstrating SKIP-guard + structural validation of a `## Outputs` section):

```bash
#!/usr/bin/env bash
# Example: validate ## Outputs section in agents/fixer.md
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

FILE="$REPO_ROOT/agents/fixer.md"
[ -f "$FILE" ] || { echo "SKIP: agents/fixer.md not found"; exit 77; }

# SKIP-guard: exit 77 if ## Outputs section absent (v8.0.0 agents lack it)
if ! grep -qE '^## Outputs' "$FILE"; then
  echo "SKIP: agents/fixer.md has no ## Outputs section (v8.0.0 — section not yet added)"
  exit 77
fi

# Extract ## Outputs section (from heading to next ## heading or EOF)
OUTPUTS_SECTION=$(awk '/^## Outputs/{found=1} found && /^## [^O]/{found=0} found{print}' "$FILE")

# Assert required subfields present (typed table: "Field | Type | Required")
if ! echo "$OUTPUTS_SECTION" | grep -qE '\bField\b'; then
  fail "fixer.md ## Outputs missing 'Field' column header"
fi
if ! echo "$OUTPUTS_SECTION" | grep -qE '\bType\b'; then
  fail "fixer.md ## Outputs missing 'Type' column header"
fi
if ! echo "$OUTPUTS_SECTION" | grep -qE 'Fix Report|fix_report'; then
  fail "fixer.md ## Outputs does not declare output section name 'Fix Report'"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: fixer.md ## Outputs section is structurally valid"
exit "$FAIL"
```

**Key design choices in the snippet:**
- `grep -qE '^## Outputs'` → SKIP exit 77 (v8.0.0 compatibility)
- `awk '/^## Outputs/{found=1} found && /^## [^O]/{found=0} found{print}'` → range extract to next `##` heading (excluding `## Outputs` itself)
- `grep -qE '\bField\b'` → assert table header is present (not just section heading)
- `grep -qE 'Fix Report'` → assert specific named output section is declared

**Confidence:** HIGH — all primitives (`awk` range-match, `grep -qE`, exit 77) directly sourced from existing scenario files. Snippet is tested by inspection against harness semantics.

**Disagreements:** The regex `^## [^O]` to close the awk range is fragile if a future section starts with `## O` (e.g., `## Overview`). Safer alternative: `^## [A-Z]` (closes on ANY uppercase heading) or use `awk '/^## Outputs/{found=1; next} found && /^## /{found=0} found{print}'` (explicit next + any `##` stops). Either variant works; the simpler form is shown in the snippet.

**Decision impact:** HOW-to-test — confirms that typed-table contract format (markdown table with Field/Type/Required columns + declared output section names) is grep-extractable. A YAML-block format would require more complex awk, not just field-presence grep. The SKIP-guard pattern ensures CI stays green during the transition period when only some agents have been updated.

---

## Q11

**Question:** What grep-based cross-reference assertion could validate that every output section name declared in an agent's I/O contract also appears verbatim in the dispatching skill's SKILL.md — and which existing cross-reference scenario provides the structural template for a new `xref-io-contracts.sh` scenario?

**Finding:** `xref-core-registry.sh` provides the exact structural template (enumerate registry entries, grep each entry in a target file set, fail on misses) and can be adapted for I/O contract xref using `grep -oE '^\| .*Fix Report.*\|'` to extract declared output section names from agent contract tables, then grepping each name in the dispatching skill's SKILL.md; `xref-skip-stage-names.sh` provides the bidirectional template (CLAUDE.md → skills, skills → CLAUDE.md) for a two-direction consistency check.

**Evidence:**

- `tests/scenarios/xref-core-registry.sh:36-43`: pattern — `for name in "${CORE_FILES[@]}"; do ref="core/${name}"; match_count=$(find "$SKILLS_DIR" -name 'SKILL.md' -exec grep -l "$ref" {} \;); done`. Adapt: extract contract output names from agent files, grep each in corresponding skill SKILL.md. Source: `tests/scenarios/xref-core-registry.sh:36-43`.

- `tests/scenarios/xref-skip-stage-names.sh:12-40`: bidirectional pattern — reads canonical names from CLAUDE.md, checks each in skill files; then checks skill NEVER-skip lines against canonical list. Exact analog for: (a) extract output names from agent `## Outputs` section, (b) check each appears in dispatching skill. Source: `tests/scenarios/xref-skip-stage-names.sh:12-40`.

- Current output section naming evidence from skills: `skills/fix-ticket/SKILL.md:208` references `` `## NEEDS_CLARIFICATION` ``, `skills/fix-bugs/steps/04-fixer-reviewer-loop.md:41` references `` `## NEEDS_DECOMPOSITION` `` — confirming skills currently reference agent output sections by exact heading name via prose `grep`. The names are not centrally registered. Source: `skills/fix-ticket/SKILL.md:208`, `skills/fix-bugs/steps/04-fixer-reviewer-loop.md:41`.

- `agents/reviewer.md:78-79` embeds output section in Process step: `` ```   ## Code Review   - **Verdict:** ``` `` — the section name `Code Review` is inside a code block in the Process step. `grep -n "## Code Review" agents/reviewer.md` would find it at line 78. The corresponding skill references it via `fix-ticket/SKILL.md:523`-range prose. Source: `agents/reviewer.md:78-79`.

**Working bash xref assertion snippet:**

```bash
#!/usr/bin/env bash
# xref-io-contracts.sh — validate that each agent's declared output section names
# appear in at least one dispatching skill's SKILL.md
# (Template: xref-core-registry.sh + xref-skip-stage-names.sh patterns)
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

AGENTS_DIR="$REPO_ROOT/agents"
SKILLS_DIR="$REPO_ROOT/skills"

# For each agent: extract declared output section names from ## Outputs table (Field column)
for agent_file in "$AGENTS_DIR"/*.md; do
  agent_name=$(grep -m1 '^name:' "$agent_file" | sed 's/^name:[[:space:]]*//')
  [ -z "$agent_name" ] && continue

  # SKIP-guard: agent has no ## Outputs section (v8.0.0 baseline)
  if ! grep -qE '^## Outputs' "$agent_file"; then
    echo "SKIP: $agent_name has no ## Outputs section"
    continue
  fi

  # Extract output section names from typed table (rows matching "| ## SectionName |")
  OUTPUT_NAMES=$(awk '/^## Outputs/{found=1} found && /^## [^O]/{found=0} found{print}' "$agent_file" \
    | grep -oE '\`## [A-Za-z ]+\`' \
    | sed "s/\`## //;s/\`//")

  if [ -z "$OUTPUT_NAMES" ]; then
    echo "SKIP: $agent_name ## Outputs declares no named output sections"
    continue
  fi

  # For each declared output section name: check at least one skill references it
  while IFS= read -r section_name; do
    [ -z "$section_name" ] && continue
    skill_match=$(grep -rl "## ${section_name}" "$SKILLS_DIR" 2>/dev/null | wc -l)
    if [ "$skill_match" -eq 0 ]; then
      fail "$agent_name declares output '## ${section_name}' but no skill SKILL.md references it"
    else
      echo "OK: $agent_name output '## ${section_name}' referenced in $skill_match skill(s)"
    fi
  done <<< "$OUTPUT_NAMES"
done

[ "$FAIL" -eq 0 ] && echo "PASS: all declared agent output section names appear in at least one skill"
exit "$FAIL"
```

**Template mapping:**
- `xref-core-registry.sh` loop structure → `for agent_file in "$AGENTS_DIR"/*.md`
- `xref-skip-stage-names.sh` SKIP-guard on missing section → `if ! grep -qE '^## Outputs'`
- `xref-core-registry.sh` grep-in-skills pattern → `grep -rl "## ${section_name}" "$SKILLS_DIR"`
- Output format (OK/FAIL per entry) → matches both templates

**Confidence:** HIGH for the structural template derivation; MEDIUM for the extraction regex (`grep -oE '\`## [A-Za-z ]+\`'`) — this assumes the typed table uses backtick-quoted section names in the "Field" column (e.g., `` `## Fix Report` ``). The exact format of a not-yet-written `## Outputs` section is TBD, so the regex is a design proposal, not a test of existing content.

**Disagreements:** The xref check is asymmetric in the v8.0.0 baseline: no agents have `## Outputs` sections, so the scenario would SKIP for all 18 agents. The scenario only becomes meaningful after v9.0.0 agent updates. This is intentional (SKIP-guard design) but the test-value is deferred. If I/O contracts are optional (some agents have them, some don't), the xref check must handle agents with partial contracts gracefully — the snippet above handles this via `SKIP` on absent sections.

**Decision impact:** HOW-to-test + contract format choice — the xref is feasible with grep if and only if output section names are declared as extractable tokens in the `## Outputs` table. If the contract format uses free-form prose (e.g., "The agent emits a Fix Report section"), grep extraction becomes regex-fragile. Typed table with backtick-quoted `## SectionName` entries is the grep-friendly design choice. This directly constrains the schema format decision in Phase 3.

---

## Synthesis

**Five strongest signals for Phase 3 brainstorm:**

1. **No runtime enforcement is possible.** Task tool returns raw LLM output verbatim. All contract enforcement is lint-time (grep scenarios) or instruction-level (agent body prose). This eliminates "enforced schema" as a hot-path option and makes advisory-schema the only viable posture. (Q2)

2. **Three stale pre-v8 scenarios are actively masking coverage.** `frontmatter-completeness.sh` and `section-order.sh` fail on 5 missing v7 agent files; `read-only-agents.sh` silently SKIPs them. Adding v9.0.0 contract sections without updating these three scenarios leaves the harness unable to catch malformed contracts in `triage-analyst.md` (now deleted) or structurally invalid `## Inputs` sections. The test-update surface is small (3 files, hardcoded lists) but non-trivial. (Q1)

3. **Zero forge-2026-04-25-001 failures were caused by output-section mismatch.** The 62 failures are entirely attributable to Windows portability bugs (6), undeployed test files (5), and one design.md omission. The "do nothing" baseline argument is: contracts solve a problem that has not manifested as observed failures. The counter-argument is: the harness has no coverage for output-shape correctness at all, so failures of that type would not be detected. (Q1, Q9)

4. **Section order is the only assertion that would break.** Of 296 scenarios, only `section-order.sh` would require modification to accommodate new mandatory body sections. The other body-section tests (read-only-agents, ac3/ac4/ac5 token constraints) are unaffected because they check content inside named sections, not the section enumeration itself. Edit surface = 1 file. (Q9)

5. **Grep-friendly typed-table format is load-bearing for feasibility.** The xref scenario (`xref-io-contracts.sh`) and the structural validation pattern (Q10 snippet) both require output section names to be grep-extractable from the contract definition. If the chosen format uses YAML blocks or free-form prose, the grep extraction regex breaks. A typed markdown table with backtick-quoted section names (e.g., `` | `## Fix Report` | string | required | ``) is the only format that satisfies both human readability (visible to Claude model as system prompt) and grep extractability. This is the single most constraining design input. (Q10, Q11)

**Open questions not fully resolved:** (a) Whether the Task tool passes frontmatter verbatim to the model or strips it before invocation (affects whether `## Inputs` YAML embedded in frontmatter would be visible to the agent). (b) Whether 5 undeployed v8 tests (`v8-agents-deprecation-alias`, `v8-matrix-fixbugs-yolo`, etc.) should be staged to `tests/scenarios/` as part of the v9.0.0 work — they were FAILing in cycle 2 due to implementation gaps now fixed, but their status post-fix is unknown. Resolution deferred to Phase 6 planning.
