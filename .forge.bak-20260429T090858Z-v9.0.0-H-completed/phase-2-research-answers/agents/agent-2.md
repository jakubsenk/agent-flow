# Phase 2 Research Answers — Agent 2 (HOW: External Framework Precedents)

**Partition:** Q3, Q4, Q5
**Researcher:** agent-2
**Date:** 2026-04-28

---

## Q3 — MCP `inputSchema`/`outputSchema` and CrewAI `expected_output`/`output_pydantic` co-location pattern

**Question:** What structured output contract format do the Model Context Protocol (MCP) `inputSchema`/`outputSchema` fields and CrewAI `expected_output` / `output_pydantic` Task fields use — specifically: are contracts co-located with the agent/tool definition or in sidecar files, are they mandatory or optional, and what happened to backward compatibility when CrewAI added `output_json` / `output_pydantic` to existing crew definitions in v0.28?

**Finding:** Both MCP and CrewAI co-locate I/O contracts directly in the tool/task definition object; MCP's `inputSchema` is mandatory while `outputSchema` is optional (added in spec 2025-06-18); CrewAI's `expected_output` is required but `output_pydantic`/`output_json` are optional fields — all three frameworks use same-file co-location with zero sidecar pattern, and optional fields are backward-compatible by design.

**Evidence:**

- **MCP 2025-11-25 spec** (`modelcontextprotocol.io/specification/2025-11-25/server/tools`): Tool interface lists `inputSchema` as **MUST** ("MUST be a valid JSON Schema object — not null"), `outputSchema` as explicitly optional ("Optional JSON Schema defining expected output structure"). Both fields are inline JSON Schema within the tool's JSON object — no sidecar. Defaults to JSON Schema 2020-12 when no `$schema` field present. The `outputSchema` field was introduced in spec version 2025-06-18 (confirmed by smolagents docs: "The latest MCP specifications (2025-06-18+) include support for outputSchema"). Backward compat note in spec: "For backwards compatibility, a tool that returns structured content SHOULD also return the serialized JSON in a TextContent block."

- **MCP 2024-11-05 spec** (verified via `modelcontextprotocol.io/specification/2024-11-05/server/tools`): Only `inputSchema` was present; no `outputSchema` field in the 2024 release. This confirms `outputSchema` was an ADDITIVE, optional addition in a MINOR bump (2024→2025), not a breaking change.

- **CrewAI Task fields** (`docs.crewai.com/en/concepts/tasks`): `expected_output` type=`str`, **required**. `output_json` type=`Optional[Type[BaseModel]]`, default=None. `output_pydantic` type=`Optional[Type[BaseModel]]`, default=None. All three are inline fields of the `Task` class — no sidecar. A `TaskOutput` only populates `pydantic` or `json_dict` if the Task was configured with the corresponding field; otherwise output falls back to `raw` string. This makes the optional structured fields additive: omitting them leaves existing behavior unchanged.

- **CrewAI git history**: PR #746 (June 2024, `github.com/crewAIInc/crewAI/pull/746`) was a documentation-only PR adding `output_json` examples to Tasks.md, indicating the feature already existed in task.py before that PR. v0.30.4 (May 13, 2024) release notes mention "Improving json and pydantic output (works better with smaller models)" — confirming these fields were present by v0.30.4. The exact introduction version is pre-v0.30.4 but the exact commit is not in public changelogs. Critical point: the v0.28 reference in the research question cannot be verified as the introduction point from available sources — it may predate v0.28.

- **Backward compat pattern**: Both MCP and CrewAI chose the same pattern: add optional structured contract fields with `None`/absent defaults; existing definitions that omit them continue to work verbatim. CrewAI docs note validation prevents setting multiple output types simultaneously (mutual exclusion guard), but this is a runtime guard on new usage, not a migration burden on existing code.

**Confidence:** HIGH for co-location pattern and MCP field mandatory/optional split (two primary sources: MCP spec + smolagents docs confirming 2025-06-18 addition). MEDIUM for exact CrewAI introduction version (documentation confirms pre-v0.30.4, exact commit not publicly surfaced in changelogs).

**Disagreements:** None on the co-location pattern. Minor uncertainty on whether CrewAI's `output_pydantic` was introduced in v0.28 specifically (as the question asks) vs. earlier or later — available release notes do not confirm the exact version.

**Sources:**
- MCP 2025-11-25 spec: `https://modelcontextprotocol.io/specification/2025-11-25/server/tools`
- MCP 2024-11-05 spec: `https://modelcontextprotocol.io/specification/2024-11-05/server/tools`
- CrewAI Task concepts: `https://docs.crewai.com/en/concepts/tasks`
- CrewAI PR #746 (docs update for output_json): `https://github.com/crewAIInc/crewAI/pull/746`
- smolagents MCP structured output docs (confirms 2025-06-18): `https://huggingface.co/docs/smolagents/tutorials/tools`

**Phase 3 implication:** Both major frameworks converge on same-file co-location with optional fields and None defaults. For ceos-agents: new `## Inputs` / `## Outputs` sections should be optional (absent = uncontracted), mirroring MCP's `outputSchema` pattern. Adding them is structurally equivalent to MCP's MINOR spec bump from 2024-11-05 to 2025-06-18. This supports classifying the ceos-agents addition as MINOR if sections are optional.

---

## Q4 — JSON Schema 2020-12 `oneOf`/`if-then-else` vs typed-list table for polymorphic agents

**Question:** What is the minimal schema expressiveness actually needed to describe the I/O surface of polymorphic ceos-agents agents like `analyst` (`--phase triage` vs `--phase impact`) and `test-engineer` (`--e2e` variant) — and does JSON Schema 2020-12's `oneOf`/`if-then-else` add enough expressive power over a typed field list to justify the readability overhead in a file that must remain human-readable by a Claude model?

**Finding:** The analyst and test-engineer agents have genuinely polymorphic I/O (different input fields and different output section names per mode), which typed-list tables can describe adequately using mode-annotated rows; JSON Schema discriminated unions add machine-validation power but impose a readability cost that is prohibitive for a markdown file consumed by Claude models, and OpenAI's strict mode rejection of `oneOf` confirms the format has ecosystem-level compatibility problems.

**Evidence:**

- **analyst.md I/O surface** (read directly): Two distinct phases share the same file. `--phase triage` inputs: issue tracker ID, attachments; outputs: `## Triage Analysis` block with fields {Summary, Area, Severity, Reproduction, Attachments, Acceptance Criteria, Complexity, Reproduction steps (conditional)}. `--phase impact` inputs: triage analysis output + codebase; outputs: `## Impact Report` block with entirely different fields {Root cause location, Affected files, Callers at risk, Test coverage, Risk level, Historical context, Reproduction trace, Sanity check, Suggested approach}. The two output section names are different (`## Triage Analysis` vs `## Impact Report`) — this is a genuine discriminated union at the output level.

- **test-engineer.md I/O surface** (read directly): Default mode reads bug report + fixer output + impact report, writes `## Test Report`. `--e2e` flag replaces the unit test invocation with E2E framework. The output section name (`## Test Report`) is the SAME in both modes — only the test type and invocation differ. This is NOT a true discriminated union at the I/O contract level; it is a behavioral variant with identical output structure.

- **JSON Schema 2020-12 expressiveness**: `oneOf`/`if-then-else` can model analyst's polymorphism as a discriminated union on `phase` property. However: (a) `oneOf` was rejected by OpenAI strict mode (`"'oneOf' is not permitted"` error, community.openai.com/t/oneof-allof-usage-has-problems-with-strict-mode/966047), confirming this is an actively problematic construct in tooling; (b) `if-then-else` is supported in JSON Schema 2020-12 but requires embedding JSON in markdown, making the file unreadable to humans and reducing LLM comprehension; (c) JSON Schema inside markdown is not grep-parseable with `grep -qE` or `awk`, violating the test harness constraint from Q10.

- **Typed-list table expressiveness**: A markdown table with a `Mode` column (`triage` / `impact` / `all`) can describe all inputs and outputs without JSON. It is grep-parseable, human-readable, LLM-readable, and covers both true discriminated union cases (analyst) and behavioral variants (test-engineer). The limitation is that it cannot express cross-field constraints (e.g., "if phase=triage, then field X is required"). For ceos-agents' actual polymorphism surface, no cross-field constraints exist that need machine validation — the constraint is purely which output section name appears.

- **Per-mode separate sections**: A third option — separate `## Inputs (--phase triage)` and `## Inputs (--phase impact)` sections — mirrors the analyst.md's existing split structure (it already uses `## Process — Phase: triage` and `## Process — Phase: impact` headers). This is already the de-facto format in the agent files and is maximally readable.

**Concrete sketch — analyst polymorphism in three formats:**

### (a) JSON Schema 2020-12 with discriminated union (oneOf)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "oneOf": [
    {
      "properties": {
        "phase": { "const": "triage" },
        "inputs": {
          "type": "object",
          "properties": {
            "issue_id": { "type": "string", "required": true },
            "attachments": { "type": "array", "required": false }
          }
        },
        "outputs": {
          "type": "object",
          "properties": {
            "section": { "const": "## Triage Analysis" },
            "severity": { "enum": ["CRITICAL","HIGH","MEDIUM","LOW"] },
            "complexity": { "enum": ["XS","S","M","L"] },
            "acceptance_criteria": { "type": "array" }
          }
        }
      }
    },
    {
      "properties": {
        "phase": { "const": "impact" },
        "inputs": {
          "type": "object",
          "properties": {
            "triage_analysis": { "type": "string", "required": true },
            "codebase": { "type": "string", "required": true }
          }
        },
        "outputs": {
          "type": "object",
          "properties": {
            "section": { "const": "## Impact Report" },
            "risk_level": { "enum": ["LOW","MEDIUM","HIGH"] },
            "root_cause_confirmed": { "enum": ["YES","NO"] }
          }
        }
      }
    }
  ]
}
```

**Readability verdict:** Unreadable in a markdown file. Requires JSON block embedding. Grep-hostile. `oneOf` is rejected by OpenAI strict mode. Not viable.

---

### (b) Typed-list table (single section with Mode column)

```markdown
## Inputs

| Field | Type | Mode | Required |
|-------|------|------|----------|
| issue_id | string | triage | yes |
| attachments | array | triage | no |
| triage_analysis | string | impact | yes |
| codebase | string | impact | yes |

## Outputs

| Field | Type | Mode | Notes |
|-------|------|------|-------|
| section | const:`## Triage Analysis` | triage | machine-parseable heading |
| severity | enum:CRITICAL/HIGH/MEDIUM/LOW | triage | |
| complexity | enum:XS/S/M/L | triage | |
| acceptance_criteria | array | triage | 2-5 items |
| section | const:`## Impact Report` | impact | machine-parseable heading |
| risk_level | enum:LOW/MEDIUM/HIGH | impact | |
| root_cause_confirmed | enum:YES/NO | impact | |
```

**Readability verdict:** Readable, grep-parseable (`grep "## Triage Analysis"`), LLM-readable. Mode column handles discriminated union adequately. Does not express cross-field constraints but none are needed. Viable.

---

### (c) Per-mode separate sections (mirrors existing agent structure)

```markdown
## Inputs — Phase: triage

| Field | Type | Required |
|-------|------|----------|
| issue_id | string | yes |
| attachments | array | no |

## Outputs — Phase: triage

| Field | Value/Type | Notes |
|-------|-----------|-------|
| section_heading | `## Triage Analysis` | fixed |
| severity | CRITICAL / HIGH / MEDIUM / LOW | |
| complexity | XS / S / M / L | |
| acceptance_criteria | list, 2-5 items | |

## Inputs — Phase: impact

| Field | Type | Required |
|-------|------|----------|
| triage_analysis | string | yes |
| codebase | string | yes |

## Outputs — Phase: impact

| Field | Value/Type | Notes |
|-------|-----------|-------|
| section_heading | `## Impact Report` | fixed |
| risk_level | LOW / MEDIUM / HIGH | |
| root_cause_confirmed | YES / NO | |
```

**Readability verdict:** Most readable, matches the existing `## Process — Phase: triage` / `## Process — Phase: impact` split already in analyst.md. Grep-friendly for both heading and field names. LLM-friendly. The heading-per-mode format also extends naturally to test-engineer's `--e2e` variant as `## Outputs (default)` vs `## Outputs — E2E`. Verbose but zero ambiguity.

---

**Confidence:** HIGH — analyst.md and test-engineer.md read directly; JSON Schema constraints verified against primary sources (JSON Schema spec, OpenAI community forum, MCP spec).

**Disagreements:** None. All sources agree that `oneOf` has real-world compatibility problems; typed tables are universally readable.

**Sources:**
- `C:/gitea_ceos-agents/agents/analyst.md` (read directly)
- `C:/gitea_ceos-agents/agents/test-engineer.md` (read directly)
- JSON Schema 2020-12 conditional validation: `https://json-schema.org/understanding-json-schema/reference/conditionals`
- OpenAI strict mode oneOf rejection: `https://community.openai.com/t/oneof-allof-usage-has-problems-with-strict-mode/966047`
- JSON Schema combining: `https://json-schema.org/understanding-json-schema/reference/combining`

**Phase 3 implication:** Per-mode separate sections (option c) is the strongest format choice — it reuses the agent file's existing structural pattern, is grep-parseable, LLM-readable, and correctly handles both the analyst (true discriminated union) and test-engineer (behavioral variant) without JSON overhead. JSON Schema discriminated unions are not warranted given the test harness constraint and the real-world incompatibility of `oneOf` with OpenAI strict mode.

---

## Q5 — Advisory vs enforced schema: smolagents `output_type` and OpenAI `strict: true`

**Question:** In production agent frameworks, what has driven the choice between "advisory schema" and "enforced schema" — specifically, what was smolagents' rationale for making `output_type` advisory, and what did OpenAI's introduction of `strict: true` in function-calling (August 2024) reveal about failure modes that strict enforcement surfaces in previously-working tool definitions?

**Finding:** smolagents' `output_type` is declaration-mandatory but enforcement-advisory at runtime (the field must exist and be a valid type string, but the LLM's actual output is not schema-validated before return); OpenAI's `strict: true` (August 2024, gpt-4o-2024-08-06) revealed that 100% schema compliance requires a heavily restricted JSON Schema subset — blocking `oneOf`, `default` values, and requiring `additionalProperties: false` on all objects and all fields listed as `required` — which broke previously-working schemas and forced developers to rewrite tool definitions.

**Evidence:**

- **smolagents `output_type` enforcement** (`raw.githubusercontent.com/huggingface/smolagents/main/src/smolagents/tools.py`): `output_type: str` is a required class attribute on every `Tool` subclass. `validate_arguments()` raises `TypeError`/`ValueError` if absent or not in `AUTHORIZED_TYPES` = `["string","boolean","integer","number","image","audio","array","object","any","null"]`. Enforcement is via `__init_subclass__` wrapping `__init__` with `@validate_after_init` — instantiation fails at class creation time if missing. However: validation confirms the *declaration* exists and is a valid type name; it does NOT validate that the `forward()` method's actual return value matches the declared type at runtime. The enforcement is structural (declaration must exist, must be valid string), not semantic (return value need not conform).

- **smolagents advisory-at-runtime rationale**: Issue #483 (`github.com/huggingface/smolagents/issues/483`, opened Feb 3, 2025) proposes "strongly enforce types in tools" as a *new feature request*, citing that "agents will try calling a tool incorrectly despite the type hints, especially if the backbone [model] is weak." This is a feature request — meaning runtime type enforcement of `output_type` did NOT exist as of Feb 2025. The maintainer-acknowledged gap confirms the current design: `output_type` is a schema hint for the LLM's system prompt and MCP interop, not a runtime validator. The smolagents docs confirm: "the LLM will need to be given an API: name, tool description, input types and descriptions, output type" — framing `output_type` as model guidance, not validation gate.

- **smolagents MCPClient structured output**: As of docs v1.24.0, `MCPClient(structured_output=True)` enables `outputSchema` support. Critically: `structured_output` defaults to `False` "to maintain backwards compatibility." The docs state: "In a future release, the default value of `structured_output` will change from `False` to `True`." This is the clearest evidence of the advisory→enforced trajectory: structured output is currently opt-in advisory, with enforced-by-default planned for future. This is the exact same pattern proposed for ceos-agents.

- **OpenAI `strict: true` failure modes** (August 6, 2024, gpt-4o-2024-08-06 launch): The introduction required a restricted JSON Schema subset for 100% compliance. Specific constraints that broke previously-working schemas:
  1. `oneOf` is not permitted in strict mode (community.openai.com/t/oneof-allof-usage-has-problems-with-strict-mode/966047)
  2. `default` values are not permitted
  3. `additionalProperties` must be explicitly set to `false` on every object (was implicit in non-strict)
  4. All fields must be listed under `required` (optional fields require `anyOf: [{type: X}, {type: "null"}]` pattern instead of simply omitting from `required`)
  5. `anyOf` IS supported in strict mode as replacement for `oneOf` — but only with specific patterns

- **What these failures revealed**: Developers who had perfectly functional tool schemas in non-strict mode discovered their schemas violated the restricted subset when opting into `strict: true`. This is not a model regression — it is a revelation that their schemas contained constructs that the constrained decoding (used to guarantee 100% compliance) cannot handle. The practical impact: ~1% of responses still cut off mid-stream (token limit interaction with constrained decoding), and schema rewrite was required for any tool using `oneOf`, `default`, or implicit `additionalProperties`.

- **Advisory vs enforced production consensus**: The evidence shows a split pattern — enforcement is applied at the *declaration* level (you must declare a type) but not at the *output* level (actual LLM output is not validated). Both smolagents and OpenAI non-strict mode validate input schemas but return raw LLM text for outputs. Enforcement at output level (strict: true, or a runtime validation hook in the skill) requires accepting the restricted schema subset and the 1% truncation risk.

**Confidence:** HIGH for smolagents declaration enforcement and OpenAI strict mode restrictions (primary sources: tools.py source, OpenAI community forum, smolagents docs). MEDIUM for the exact smolagents rationale (Issue #483 is a feature request confirming the absence of runtime enforcement, not an explicit design rationale document).

**Disagreements:** smolagents' `validate_after_init` enforcement sounds strict but is advisory at the semantics level — this is a subtle distinction the primary source (tools.py) makes clear but secondary sources (tutorials) obscure by calling `output_type` a "required" field without clarifying it is required for declaration, not for output conformance.

**Sources:**
- smolagents tools.py (output_type enforcement): `https://raw.githubusercontent.com/huggingface/smolagents/main/src/smolagents/tools.py`
- smolagents tools tutorial (framing as model guidance): `https://huggingface.co/docs/smolagents/tutorials/tools`
- smolagents Issue #483 (runtime enforcement absent as of Feb 2025): `https://github.com/huggingface/smolagents/issues/483`
- OpenAI structured outputs announcement (Aug 2024): `https://openai.com/index/introducing-structured-outputs-in-the-api/`
- OpenAI strict mode oneOf failure reports: `https://community.openai.com/t/oneof-allof-usage-has-problems-with-strict-mode/966047`
- OpenAI structured outputs guide: `https://platform.openai.com/docs/guides/structured-outputs`
- smolagents structured_output backwards compat note: `https://huggingface.co/docs/smolagents/tutorials/tools` (structured output section)

**Phase 3 implication:** The production consensus is declaration-mandatory + runtime-advisory. For ceos-agents: `## Inputs` / `## Outputs` sections should be structurally required (lint-time enforcement, harness test fails if absent) but not runtime-enforced (no skill-level output validation that would block the pipeline). This mirrors smolagents' current posture and aligns with OpenAI's lesson that strict runtime enforcement requires accepting a narrow schema subset with real truncation risks — unacceptable for prose-generating agents producing multi-field markdown outputs.

---

## Summary (< 100 words)

Three convergent signals: (1) All major frameworks use **same-file co-location** with **optional structured output fields** (MCP `outputSchema` optional since 2025-06-18, CrewAI `output_pydantic` optional since pre-v0.30.4). (2) For polymorphic agents, **per-mode separate sections** beat JSON Schema discriminated unions on readability, grep-parsability, and ecosystem compatibility (`oneOf` is broken in OpenAI strict mode). (3) Production consensus is **declaration-mandatory + runtime-advisory** — smolagents enforces that `output_type` exists, not that outputs conform. ceos-agents should follow: lint-time mandatory sections, no hot-path validation.
