# Phase 2 Synthesis — Research Answers for v9.0.0 sub-projekt H

**Synthesized:** 2026-04-28
**Partition sources:** agent-1.md (Q1, Q2, Q9, Q10, Q11), agent-2.md (Q3, Q4, Q5), agent-3.md (Q6, Q7, Q8)

---

## Executive Summary

- **No runtime enforcement is possible** — the Claude Code Task tool returns raw LLM output verbatim; all contract enforcement must be lint-time (grep-based scenarios) or instruction-level (section headings as behavioral guidance). This eliminates enforced-schema as a hot-path option.
- **Zero forge-2026-04-25-001 failures were caused by output-section mismatch** — the 62 failures split into Windows portability bugs, undeployed test files, and one design.md omission. The "do nothing" baseline is legitimate; the counter-argument is that the harness has no coverage to detect output-shape violations at all.
- **Industry consensus is declaration-mandatory + runtime-advisory** — MCP `outputSchema` is optional since 2025-06-18 (MINOR bump), CrewAI `output_pydantic` is optional, smolagents enforces declaration presence but not output conformance. All frameworks use same-file co-location with no sidecars.
- **Per-mode separate sections beat JSON Schema discriminated unions** — typed markdown tables with a Mode column, or separate `## Inputs — Phase: X` headings, are grep-parseable, LLM-readable, and avoid the `oneOf` incompatibility that breaks OpenAI strict mode.
- **MAJOR vs MINOR is a genuine policy gap** — the current CLAUDE.md Versioning Policy does not cover agent body *declaration sections* (as opposed to agent runtime *output sections*); optional contracts = MINOR (v8.1.0), mandatory/enforced contracts = MAJOR (v9.0.0); the policy must be amended before committing agent files.

---

## Answers

### Q1: Concrete evidence that absent I/O contracts cause observable failures

**Answer:** No runtime failures attributable to output-section-name mismatch exist in the forge-2026-04-25-001 archive (62 failures break down as 6 Windows portability bugs, 5 undeployed test files, 1 design.md omission); however, `read-only-agents.sh` silently skips stale v7 agent names (masking case), and `frontmatter-completeness.sh` plus `section-order.sh` actively fail on 5 deleted v7 agent files — meaning the harness has zero coverage to detect future output-shape violations in the 18 current agents.

**Sources:**
- `tests/scenarios/frontmatter-completeness.sh:3,11-17` — hardcoded 21-agent list, fails on 5 missing v7 files
- `tests/scenarios/section-order.sh:3,11-17` — same 21-name list, same 5 FAILs
- `tests/scenarios/read-only-agents.sh:14-17,23` — graceful `continue` on missing files = silent masking
- `.forge.bak-20260428-181546/phase-8-verification/cycle-3/correctness-review.md` — per-failure taxonomy (no output-shape cause in any of 62)
- `.forge.bak-20260428-181546/phase-8-verification/cycle-3/devil-review.md` — 5 missing tests never deployed to `tests/scenarios/`

**Confidence:** HIGH — live test runs confirm (a); forge archive documents (b) with per-failure taxonomy.

**Both-sides argument:**
- *For formalization:* The harness has no coverage for output-shape correctness; failures of that type would be undetected, not absent. The three stale scenario files represent a coverage gap, not evidence of absence.
- *Against formalization:* Three full forge cycles produced zero output-shape failures. The cost-benefit case is "prevent a class of failure that has never occurred," which is a speculative ROI.

**See also:** Q9 (test coverage impact directly follows from the absent failure evidence), Q10 (the detection gap is what new scenarios would close)

---

### Q2: Task tool validation behavior — what reaches the model, what is returned

**Answer:** The Claude Code Task tool passes the full agent file (frontmatter + body) as agent definition context, extracts `model:` and `description:` frontmatter fields for routing and UI display respectively, and returns the raw LLM response verbatim with zero validation of output structure — making all output-format enforcement strictly lint-time or instruction-level.

**Sources:**
- `skills/fix-ticket/SKILL.md:190-192` — skills manually extract `model:` before calling Task; pattern appears 10+ times
- `docs/architecture.md:17` — "What you see in the repository is what runs" (body IS the system prompt)
- `docs/reference/agents.md:71` — `description:` is "used by Claude Code's Task tool" (UI picker field)
- `docs/architecture.md:362` — plugin agents do not support `hooks:`/`mcpServers:`/`permissionMode:` (Task tool parses frontmatter but ignores unsupported fields; body passed as-is)
- `skills/fix-ticket/SKILL.md:208,296` — output parsing is string-grep in skill prose, not Task tool enforcement
- `skills/discuss/SKILL.md:22-25` — skills must manually extract frontmatter values; Task tool does not inject them into subagent prompt

**Confidence:** HIGH — multiple primary sources agree; no Anthropic Task tool primary docs fetched (deferred), but codebase evidence is unambiguous.

**Note:** Frontmatter may be visible verbatim to the model (the "what you see is what runs" principle) — treat as "body is primary; frontmatter is also visible, not stripped."

**See also:** Q5 (advisory vs enforced verdict follows from this: if Task returns raw output, enforcement must be lint-time), Q10 (since no runtime validation exists, new sections in agent body are prompt-instruction-level only)

---

### Q3: MCP `inputSchema`/`outputSchema` and CrewAI `expected_output`/`output_pydantic` co-location pattern

**Answer:** Both MCP and CrewAI co-locate I/O contracts directly in the tool/task definition object (no sidecar files); MCP's `inputSchema` is mandatory while `outputSchema` is optional (added in spec 2025-06-18 as a MINOR additive bump); CrewAI's `expected_output` is required but `output_pydantic`/`output_json` are optional — all three use absent-equals-uncontracted defaults and are backward-compatible by design.

**Sources:**
- MCP 2025-11-25 spec (`modelcontextprotocol.io/specification/2025-11-25/server/tools`) — `inputSchema` MUST, `outputSchema` optional
- MCP 2024-11-05 spec (`modelcontextprotocol.io/specification/2024-11-05/server/tools`) — `outputSchema` absent in 2024 release; confirms additive MINOR pattern
- CrewAI Task concepts (`docs.crewai.com/en/concepts/tasks`) — `output_json`/`output_pydantic` both `Optional[Type[BaseModel]]`, default=None
- smolagents MCP docs (`huggingface.co/docs/smolagents/tutorials/tools`) — confirms 2025-06-18 `outputSchema` introduction

**Confidence:** HIGH for co-location pattern and MCP mandatory/optional split; MEDIUM for exact CrewAI version of introduction (confirmed pre-v0.30.4, exact commit not publicly surfaced).

**See also:** Q8 (same pattern — optional MINOR addition — is the external precedent for classifying ceos-agents I/O contracts as MINOR when optional)

---

### Q4: JSON Schema `oneOf`/`if-then-else` vs typed-list table for polymorphic agents

**Answer:** Typed-list markdown tables (with a Mode column or per-mode separate section headings) are adequate for the actual polymorphism surface of analyst and test-engineer and are grep-parseable, LLM-readable, and ecosystem-compatible; JSON Schema discriminated unions via `oneOf` add no net expressiveness for ceos-agents' actual constraints while imposing prohibitive readability overhead and real-world incompatibility with OpenAI strict mode.

**Sources:**
- `agents/analyst.md` (read directly) — `--phase triage` emits `## Triage Analysis`; `--phase impact` emits `## Impact Report`; genuinely different output section names per phase
- `agents/test-engineer.md` (read directly) — default and `--e2e` both emit `## Test Report`; behavioral variant, not true discriminated union at I/O contract level
- OpenAI strict mode: `community.openai.com/t/oneof-allof-usage-has-problems-with-strict-mode/966047` — `oneOf` is rejected; `anyOf` required instead
- JSON Schema 2020-12 conditionals: `json-schema.org/understanding-json-schema/reference/conditionals`

**Three format options evaluated:**
- **(a) JSON Schema `oneOf`:** Machine-validatable, grep-hostile, unreadable in markdown, `oneOf` rejected by OpenAI strict mode. **Not viable.**
- **(b) Typed-list table (single section, Mode column):** Readable, grep-parseable, LLM-readable. **Viable.**
- **(c) Per-mode separate sections** (e.g., `## Inputs — Phase: triage`): Most readable, matches existing `## Process — Phase: triage/impact` split already in analyst.md, grep-friendly per heading and field name. **Preferred.**

**Confidence:** HIGH — agent files read directly; JSON Schema constraints verified against primary sources.

**See also:** Q10 (format choice directly determines grep-extractability of output section names for xref assertions), Q11 (per-mode headings are the grep-friendly contract format that makes xref feasible)

---

### Q5: Advisory vs enforced schema — smolagents `output_type` and OpenAI `strict: true`

**Answer:** Production consensus is declaration-mandatory + runtime-advisory: smolagents enforces that `output_type` is declared and is a valid type string (instantiation fails if absent), but does not validate that the `forward()` method's actual return value conforms at runtime; OpenAI's `strict: true` (August 2024) revealed that 100% output compliance requires a heavily restricted JSON Schema subset — blocking `oneOf`, `default` values, and requiring `additionalProperties: false` — which broke previously-working tool definitions and surfaces a 1% mid-stream truncation risk.

**Sources:**
- `raw.githubusercontent.com/huggingface/smolagents/main/src/smolagents/tools.py` — `output_type` enforced via `__init_subclass__` at class creation time; `AUTHORIZED_TYPES` list; no return-value validation
- smolagents Issue #483 (`github.com/huggingface/smolagents/issues/483`, Feb 3 2025) — runtime type enforcement of `output_type` proposed as a *new feature request* (confirming it does not exist)
- smolagents docs: `structured_output` defaults to `False` "to maintain backwards compatibility" — opt-in advisory, enforced-by-default is future planned
- OpenAI structured outputs announcement (Aug 2024, gpt-4o-2024-08-06): `openai.com/index/introducing-structured-outputs-in-the-api/`
- OpenAI strict mode restrictions: `platform.openai.com/docs/guides/structured-outputs`

**Confidence:** HIGH for smolagents declaration enforcement and OpenAI strict mode restrictions (primary sources). MEDIUM for smolagents' explicit design rationale (Issue #483 confirms absence of enforcement, not the reasoning behind the design choice).

**See also:** Q2 (no Task tool runtime enforcement is possible — smolagents and OpenAI precedent confirms lint-time only is the correct posture), Q8 (declaration-mandatory = MINOR; runtime enforcement = MAJOR is the external framework analogy)

---

### Q6: Agent override injector mechanism — append-only, heading collision behavior

**Answer:** `core/agent-override-injector.md` is strictly append-only and verbatim — it reads override file contents and returns them as a string; no skill inspects agent body structure before or after injection; new `## Inputs`/`## Outputs` sections are therefore mechanically safe to add without affecting any existing override file's injection.

**Sources:**
- `core/agent-override-injector.md:18-21` — Process step 5: appends as `## Project-Specific Instructions / {file contents}`; no body inspection
- `core/agent-override-injector.md` Process steps 3-4 — reads file verbatim, returns as string; no parsing or heading collision detection
- `skills/fix-bugs/SKILL.md:81-83` — delegates entirely to `core/agent-override-injector.md`; zero body inspection
- `skills/fix-ticket/SKILL.md:741` — same delegation pattern
- `examples/agent-overrides/codegraph/architect.md:1-10` — real override file uses free-form prose, no section headings; no `## Inputs` or `## Outputs` present
- `examples/customization/reviewer-strict-security.toml:1-26` — TOML overlays use `[[process_additions]]`/`[[constraints]]` blocks; no markdown heading structure
- `docs/guides/migration-v7-to-v8.md:86-92` — v8.0.0 still accepts `.md` overlays with `[WARN]`; hard removal documented for v9.0.0

**On heading collision:** The injector places override content after all base sections, wrapped as `## Project-Specific Instructions`. If an override `.md` contained `## Inputs`, the model would see it twice — once in base agent, once inside the wrapper. The wrapping provides semantic distance (reduces but does not eliminate ambiguity). This window is bounded: v9.0.0 hard-removes `.md` overlays anyway, so TOML-only overrides (which have no markdown heading structure) eliminate the collision risk entirely by the time v9.0.0 ships.

**Design constraint:** Avoid naming new sections `## Project-Specific Instructions` (reserved by the wrapper). `## Inputs` and `## Outputs` are safe — no existing override example file uses those headings.

**Confidence:** HIGH for injector mechanism. MEDIUM for heading collision LLM behavior (no Anthropic primary source; inference from general prompt engineering behavior).

**See also:** Q7 (injector append-only behavior is the foundation for the zero-touch migration conclusion)

---

### Q7: Minimal migration action — v8 to v9 for consuming projects

**Answer:** The minimal migration action for consuming projects upgrading from v8 to v9 is **zero modification to override files** for any I/O contract addition (optional or mandatory) — the injector's append-only verbatim mechanism guarantees passthrough regardless of new base agent sections; the only mandatory v9.0.0 migration action (`.md` overlay hard removal + deprecated agent name hard errors) is pre-announced, independent of I/O contracts, and already documented.

**Sources:**
- `core/agent-override-injector.md:1-36` — append-only; injector does not read base agent file at all
- `docs/guides/migration-v7-to-v8.md:445-454` — v9.0.0 hard-removes `.md` overlays; "plugin will reject `.md` overlays with `[ERROR]`"
- `docs/guides/migration-v7-to-v8.md:448-451` — deprecated agent names (`triage-analyst`, `code-analyst`, etc.) become hard errors in v9.0.0
- `skills/fix-bugs/SKILL.md:54-62` — v8 `.md` legacy fallback explicit; "will be removed in v9.0.0"
- User MEMORY (project_bifito_autopilot_test, project_drmax_readmine_test) — neither project is noted as having unusual override structure

**Optionality impact:** The migration answer is the same regardless of whether contracts are optional or mandatory. For consuming projects, the distinction matters zero — in both cases, override files work unmodified. The difference is internal to the plugin: mandatory contracts require all 18 agent files to be updated before v9.0.0 ships; optional contracts allow phased rollout.

**Migration guide implication:** A `docs/guides/migration-v8-to-v9.md` is required (per `feedback_docs_coverage.md` discipline), but its I/O contract section is trivial: "No action required — override files are forward-compatible." The primary content covers the pre-announced `.md` overlay removal and deprecated agent name hard errors.

**Confidence:** HIGH for injector backward compat. MEDIUM for BIFITO/drmax-readmine-test specific override file status (no direct project repo inspection possible).

**See also:** Q6 (append-only injector is the mechanism that makes this conclusion certain), Q8 (zero consumer migration cost supports MINOR classification from the consuming-project perspective)

---

### Q8: MAJOR vs MINOR versioning verdict for adding `## Inputs`/`## Outputs`

**Answer:** The current CLAUDE.md Versioning Policy has a genuine gap for agent body *declaration sections* (as opposed to agent runtime *output sections*); under a strict reading of the existing text, optional `## Inputs`/`## Outputs` sections map to MINOR (v8.1.0) because they are not runtime output sections and no existing tooling parses agent file bodies for these headings; mandatory sections enforced by test scenarios map to MAJOR (v9.0.0) only if enforcement would cause v8.0.0 agent files to fail validation in a consuming project's test suite; a policy amendment is required before Phase 6 can commit agent files.

**Sources:**
- `CLAUDE.md` Versioning Policy table (lines 240-247): MAJOR trigger covers "new/modified structured output sections that Agent Overrides or external tooling may parse"; MINOR covers "new optional key, new command/agent"
- `CLAUDE.md` MAJOR example: "new output section in analyst" — a section the analyst *emits at runtime*, not a static declaration section
- `agents/fixer.md:74-82` — `## Fix Report` is a runtime output section (appears in agent's prose output); `## Inputs`/`## Outputs` would be static metadata sections
- LangChain v0.2.0 CHANGELOG (github.com/langchain-ai/langchain) — additive optional field = MINOR; required enforcement = MAJOR
- LangGraph state schema migration (langchain-ai/langgraph) — additive TypedDict field = MINOR; removal/rename = MAJOR

**Policy gap analysis:**
- The MAJOR clause: "Agent Overrides or external tooling **may parse**" — the override injector does not parse agent body sections; no external tooling today parses `## Inputs`/`## Outputs`. Literal text does NOT fire MAJOR for new declaration sections.
- The MINOR clause: "new optional key, new command/agent" — the example references Automation Config optional sections, not agent body sections; the analogy is imprecise but directionally correct for optional additions.

**Resolution recommendation** (policy amendment text):
> Adding new static declaration sections to agent definition files (`## Inputs`, `## Outputs`) that do not appear in runtime agent output and are not enforced at runtime = MINOR. Making such sections mandatory (enforced by harness test scenarios) = MAJOR if and only if the enforcement would cause v8.0.0 agent files (lacking the sections) to fail validation in a consuming project's test suite.

**Version number decision:** The MEMORY allocation "v9.0.0 = sub-projekt H" is semantically correct ONLY for the mandatory/enforced path. Optional contracts should be v8.1.0 to avoid a semver lie. Phase 3 MUST decide optional vs mandatory before Phase 6 plans commits.

**Confidence:** HIGH for policy gap identification (primary source: CLAUDE.md text). MEDIUM for LangChain/LangGraph precedent (secondary sources only). HIGH for resolution recommendation logic.

**See also:** Q3 (MCP's MINOR `outputSchema` addition is the strongest external precedent for optional = MINOR), Q5 (smolagents declaration-mandatory = MINOR analogy), Q7 (zero consuming-project migration cost supports MINOR from that perspective)

---

### Q9: Test scenario impact analysis — which scenarios require modification for new mandatory body sections

**Answer:** Of 296 total scenarios (live count), 29 assert agent body-section properties and 20 assert frontmatter only; only `section-order.sh` would require modification if `## Inputs`/`## Outputs` have a mandated position in the section sequence — `read-only-agents.sh` is unaffected (only checks Process content for write-tool phrases), `v8-agents-analyst-shape.sh` is unaffected (only checks frontmatter fields + `## Phase Dispatch` presence, not section count or order), and `frontmatter-completeness.sh` is unaffected but already failing on 5 stale v7 agent names.

**Sources:**
- Live classification across 296 scenarios: 14 frontmatter-only, 6 both frontmatter+body, 23 body-only, 253 neither
- `tests/scenarios/section-order.sh:26-56` — checks exactly 4 sections (Goal, Expertise, Process, Constraints) with line-number ordering; new section at a mandated position would require assertion updates
- `tests/scenarios/read-only-agents.sh:29` — awk extracts `## Process` content only; adding `## Inputs`/`## Outputs` is invisible
- `tests/scenarios/v8-agents-analyst-shape.sh:28-79` — asserts frontmatter fields + `## Phase Dispatch` presence; zero assertions about section count or order beyond that
- `tests/scenarios/frontmatter-completeness.sh:19-30` — no body assertions; unaffected by new sections
- `tests/scenarios/ac5-fixer-reviewer-token-constraints.sh:25-44` — checks `## Constraints` content; unaffected by new sections above or below

**Note:** The 296/297 count discrepancy — the research question cited 297 (from prior CLAUDE.md or MEMORY); live `ls *.sh | wc -l` returns 296 on current working tree. One-test delta does not affect categorization.

**See also:** Q1 (three stale pre-v8 scenarios mask contract violation coverage), Q10 (section-order.sh modification pattern and SKIP-guard approach)

---

### Q10: Minimal bash assertion pattern for structural contract validation with SKIP-guard

**Answer:** A two-pass awk+grep pattern — first extract the candidate section with awk range-matching to next `##` heading, then grep the extracted content for required table column headers and declared output section names — is the minimal viable pattern; the SKIP-guard uses `exit 77` when the section heading is absent, preserving CI green on v8.0.0 agents while failing hard on v9.0.0 agents with malformed sections.

**Sources:**
- `tests/scenarios/v8-agents-analyst-shape.sh:22-23` — canonical file-existence SKIP-guard pattern (`exit 77`)
- `tests/scenarios/read-only-agents.sh:29` — awk range-match section extraction primitive
- `tests/scenarios/ac5-fixer-reviewer-token-constraints.sh:25-44` — combined extraction + grep assertions (canonical body-section content assertion pattern)
- `tests/harness/run-tests.sh:44-48` — exit code 77 explicitly handled as SKIP

**Canonical pattern (15-line reference implementation):**
```bash
# SKIP-guard: exit 77 if ## Outputs section absent (v8.0.0 agents lack it)
if ! grep -qE '^## Outputs' "$FILE"; then
  echo "SKIP: $agent.md has no ## Outputs section (v8.0.0)"; exit 77
fi
# Extract section (from heading to next ## heading or EOF)
OUTPUTS_SECTION=$(awk '/^## Outputs/{found=1} found && /^## [^O]/{found=0} found{print}' "$FILE")
# Assert required table structure
echo "$OUTPUTS_SECTION" | grep -qE '\bField\b'    || fail "missing Field column"
echo "$OUTPUTS_SECTION" | grep -qE '\bType\b'     || fail "missing Type column"
echo "$OUTPUTS_SECTION" | grep -qE 'Fix Report'   || fail "missing declared output section name"
```

**Format constraint:** The typed-table format with backtick-quoted section names (e.g., `` | `## Fix Report` | string | required | ``) is the only format that satisfies both human/LLM readability and grep-extractability. YAML blocks or free-form prose would require more complex awk and make the xref fragile. This directly constrains the Phase 3 schema format decision.

**Confidence:** HIGH — all primitives directly sourced from existing scenario files. Pattern tested by inspection against harness semantics.

**See also:** Q11 (xref scenario feasibility depends on the same grep-extractability requirement established here)

---

### Q11: Grep-based cross-reference assertion for agent output section names vs skill references

**Answer:** `xref-core-registry.sh` provides the structural loop template (enumerate items from a source, grep each in a target file set, fail on misses) and `xref-skip-stage-names.sh` provides the SKIP-guard pattern for absent sections; adapting these for I/O contract cross-reference requires extracting declared output section names from agent `## Outputs` tables (via `grep -oE '\`## [A-Za-z ]+\`'`), then verifying each appears in at least one dispatching skill's SKILL.md.

**Sources:**
- `tests/scenarios/xref-core-registry.sh:36-43` — template loop: `for name in ...; do grep -l "$ref" skills/**; done`
- `tests/scenarios/xref-skip-stage-names.sh:12-40` — bidirectional pattern: canonical names from CLAUDE.md → grep in skills; skill NEVER-skip lines → grep against canonical list
- `skills/fix-ticket/SKILL.md:208` — skill references `` `## NEEDS_CLARIFICATION` `` (agent output section name) by exact heading in prose
- `skills/fix-bugs/steps/04-fixer-reviewer-loop.md:41` — references `` `## NEEDS_DECOMPOSITION` `` (same pattern)
- `agents/reviewer.md:78-79` — `## Code Review` section name embedded in Process step code block

**Template mapping:**
- `xref-core-registry.sh` loop structure → `for agent_file in "$AGENTS_DIR"/*.md`
- `xref-skip-stage-names.sh` SKIP-guard → `if ! grep -qE '^## Outputs'` → `continue` (not `exit 77`, since multi-agent loop)
- `xref-core-registry.sh` grep-in-skills → `grep -rl "## ${section_name}" "$SKILLS_DIR"`

**Key asymmetry:** In the v8.0.0 baseline, no agents have `## Outputs` sections, so the xref scenario would SKIP/continue for all 18 agents. The scenario only becomes meaningful after v9.0.0 agent updates. This is intentional — SKIP-guard design preserves CI green during the transition period.

**Extraction regex note:** `grep -oE '\`## [A-Za-z ]+\`'` assumes the typed table uses backtick-quoted section names in the Field column. This is a design proposal for the contract format, not a test of existing content. Confidence for extraction regex is MEDIUM; confidence for the structural template derivation is HIGH.

**Confidence:** HIGH for structural template derivation. MEDIUM for extraction regex (format TBD in Phase 3).

**See also:** Q4 (per-mode separate section headings are the format that makes this xref grep feasible), Q10 (the same typed-table format constraint applies to both structural validation and xref extraction)

---

## Phase 3 Brainstorm Inputs

The following constraints are load-bearing for the brainstorm phase. Phase 3 must address each explicitly.

**Architecture constraints (non-negotiable):**

- **C1 — No runtime enforcement is possible.** Task tool returns raw LLM output verbatim. All enforcement is lint-time (grep scenarios) or instruction-level (section headings as behavioral guidance). Any design that assumes a validation layer in the hot path is infeasible without adding a new skill-level wrapper — a MAJOR scope expansion. (Q2)

- **C2 — Typed markdown table with backtick-quoted section names is the only grep-friendly contract format.** Both the structural validation pattern (Q10) and the xref cross-reference scenario (Q11) require output section names to be extractable via `grep -oE '\`## [A-Za-z ]+\`'`. YAML blocks, JSON Schema, and free-form prose all fail this constraint. Format choice is not optional. (Q10, Q11)

- **C3 — Per-mode separate section headings beat a Mode column for polymorphic agents.** analyst.md already uses `## Process — Phase: triage/impact` splits. Mirroring this with `## Inputs — Phase: triage` / `## Outputs — Phase: triage` is the zero-friction convention extension. JSON Schema `oneOf` is disqualified by OpenAI strict mode incompatibility. (Q4)

- **C4 — Override injector is append-only and structure-blind.** New `## Inputs`/`## Outputs` sections in base agent files are invisible to the injector. `## Inputs` and `## Outputs` are safe heading names (no existing override example uses them). Heading `## Project-Specific Instructions` is reserved and must not be reused. (Q6)

**Versioning and scope constraints:**

- **C5 — Optional contracts = MINOR (v8.1.0); mandatory/enforced contracts = MAJOR (v9.0.0).** The CLAUDE.md Versioning Policy has a gap for agent body declaration sections. The policy must be amended before Phase 6 commits agent files. The MEMORY "v9.0.0 = sub-projekt H" allocation is correct only for mandatory/enforced. (Q8)

- **C6 — Industry default is optional with absent=uncontracted.** MCP `outputSchema` is optional (MINOR addition in 2025-06-18), CrewAI `output_pydantic` is optional, smolagents `structured_output` defaults False. All frameworks use same-file co-location. Optional = backward-compatible by design, no migration burden. (Q3, Q5)

- **C7 — v8→v9 consuming project migration is zero-touch for I/O contracts.** The only mandatory v9.0.0 migration action (`.md` overlay hard removal + deprecated agent name hard errors) is pre-announced and independent of contracts. A `migration-v8-to-v9.md` is required by `feedback_docs_coverage.md` discipline, but its I/O contract section is one sentence. (Q7)

**Test harness constraints:**

- **C8 — Only `section-order.sh` requires modification for new mandatory body sections.** Of 296 scenarios, only section-order.sh asserts section position ordering. The other 28 body-section tests are unaffected. Three pre-v8 scenarios (`frontmatter-completeness.sh`, `section-order.sh`, `read-only-agents.sh`) have stale 21-agent hardcoded lists — these must be updated as part of v9.0.0 test work regardless of I/O contracts. (Q1, Q9)

- **C9 — SKIP-guard at section level (exit 77 when `## Outputs` absent) is the correct CI transition pattern.** Mirrors existing `v8-agents-analyst-shape.sh` file-existence SKIP. Allows CI to stay green during the rollout period when only some agents have been updated. (Q10)

**Open questions for Phase 3 to resolve:**

- **OQ1 — Optional vs mandatory (the version number gate).** Phase 3 must produce a recommendation. All other constraints are settled. This is the single remaining binary that determines v8.1.0 vs v9.0.0.
- **OQ2 — Phased rollout vs all-18-at-once.** If mandatory, do all 18 agents receive `## Inputs`/`## Outputs` in a single PR, or are high-traffic agents (fixer, reviewer, analyst) prioritized first? The SKIP-guard pattern (C9) enables phased rollout even under mandatory semantics.
- **OQ3 — Whether 5 undeployed v8 tests** (`v8-agents-deprecation-alias`, `v8-matrix-fixbugs-yolo`, etc.) should be staged to `tests/scenarios/` as part of v9.0.0 work. Their post-fix status is unknown. This is independent of I/O contracts but is a test-health debt item.
