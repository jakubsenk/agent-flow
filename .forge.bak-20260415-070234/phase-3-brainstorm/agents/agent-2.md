# Agent 2 — The Prompt Quality Advocate

## Position Statement

The format that the LLM comprehends best IS the correct format. Token cost is a real constraint, but it is a secondary constraint. The primary constraint is: does the LLM follow the instructions correctly? A 5% token saving that introduces even a 1% increase in instruction-following failures is a net negative in an automated pipeline where a single misinterpretation can cascade into a blocked issue, a rolled-back branch, and wasted human attention.

I take the Token Economist's concerns seriously. Token budgets are finite. Cost per run matters. But I will demonstrate, topic by topic, that the current markdown format is not merely "good enough" — it is the empirically optimal format for this specific use case, and that departing from it introduces comprehension risk that no token saving can justify.

---

## Topic 1: Agent Definitions — Markdown Body Sections

### The argument for markdown

The agent files in this plugin are not configuration. They are **programs written in natural language**, executed by an LLM. The fixer agent (`agents/fixer.md`) contains 96 lines of nuanced behavioral instructions: conditional mode switching ("Bug-fix mode (default — no `Mode:` prefix in context)"), an escape hatch with a specific signal format (NEEDS_DECOMPOSITION), a red-green-refactor TDD protocol, and a reviewer loop with iteration-dependent behavior ("If this is iteration 2 or later: Read the reviewer's feedback from the previous iteration FIRST").

This is not data. This is imperative prose. The LLM's ability to follow these instructions correctly depends on how closely the format matches the distribution of instructional text in its training data. And that distribution is overwhelmingly markdown.

### What YAML conversion would actually look like

Consider the fixer's Process step 5 (the TDD protocol). Currently it reads:

```
5. Implement the fix using red-green-refactor:
   - **RED:** Write a failing test. In bug-fix mode: the test reproduces the bug — run it, confirm it FAILS.
   - **GREEN:** Implement the minimal fix to make the failing test pass.
   - **REFACTOR:** If the fix introduced duplication or unclear code, clean up — but only within the changed scope.
   - **ESCAPE HATCH:** If during implementation you realize the fix requires changes across >=4 files...
```

Converting this to YAML would produce something like:

```yaml
process:
  - step: 5
    action: "Implement the fix using red-green-refactor"
    sub_steps:
      - name: RED
        instruction: "Write a failing test. In bug-fix mode: the test reproduces the bug — run it, confirm it FAILS."
      - name: GREEN
        instruction: "Implement the minimal fix to make the failing test pass."
      - name: ESCAPE_HATCH
        condition: "fix requires changes across >=4 files"
        instruction: "STOP coding immediately..."
```

This conversion does three harmful things:

1. **Strips contextual continuity.** In the markdown version, the escape hatch flows naturally from the implementation step — the LLM reads it as "while you are doing step 5, if this condition arises, do this instead." In YAML, the escape hatch becomes a discrete data entry in an array, disconnected from its parent context. The conditional relationship ("If during implementation you realize...") becomes a `condition:` field whose temporal relationship to the parent action is implicit, not explicit.

2. **Introduces quoting hell.** The instruction text contains em-dashes, colons, angle brackets (`>=4`), and markdown formatting (`**RED:**`). In YAML, every one of these is a potential parsing hazard. The YAML spec's handling of `:` after a key, `>` as a block scalar indicator, and `**` as literal text inside a quoted string all create failure modes that do not exist in markdown.

3. **Loses precisely 0 tokens that matter.** Phase 2 research confirmed: 87-93% of agent file content is narrative prose. The structural overhead (headings, bullets, bold markers) accounts for 7-13%. Converting structure from markdown to YAML replaces `## Process` with `process:` and `1.` with `- step: 1` — a token-count wash at best, and a net increase when you account for YAML's quoting requirements for complex string values.

### Engaging the Token Economist's concern

The Token Economist is right that every token has a cost. But the cost of a token is not uniform — a structural token that helps the LLM parse instructions correctly has a higher ROI than a content token that carries ambiguous information. The markdown heading `## Constraints` is not wasted overhead; it is a **semantic signal** that tells the LLM "everything that follows is a hard boundary on your behavior." This signal exists in millions of training documents. The YAML key `constraints:` exists in far fewer instructional contexts — it appears primarily in configuration files, where its semantics are "a list of validation rules to apply to data," not "behavioral limits on your agency."

The distinction matters. When the reviewer agent reads `## Constraints` followed by "NEVER modify code — feedback only," it interprets this as a personal behavioral restriction. When it reads `constraints: ["NEVER modify code — feedback only"]`, the framing shifts toward data description — a list of strings that happen to contain instructions. The probability of the LLM treating these as binding behavioral constraints is lower in the YAML case, because the YAML framing activates a different part of the model's learned distribution.

---

## Topic 2: Config Templates — Tables vs. Colon Notation

### Acknowledging the Token Economist's strongest argument

This is the one area where I concede the Token Economist has a legitimate point. The Phase 2 research found ~35% token savings (~1,250 tokens across all 8 templates, ~260 tokens/run in consuming projects) from converting `| Key | Value |` tables to `Key: Value` colon notation. That is a real, measurable saving.

But I argue it is still not worth the trade.

### Why tables are better for LLM comprehension

Consider the Issue Tracker section from `examples/configs/github-nextjs.md`:

```
### Issue Tracker
| Key | Value |
|------|---------|
| Type | github |
| Instance | `github.com` |
| Project | `<owner/repo>` |
| Bug query | `is:issue is:open label:bug` |
| State transitions | In Progress: `add label:in-progress`, Blocked: `add label:blocked` |
| On start set | `add label:in-progress` |
```

The table format provides three things that colon notation does not:

1. **Explicit column headers.** The `| Key | Value |` header row tells the LLM (and the config-reader contract) that this is a two-column mapping. With colon notation (`Type: github`), the LLM must infer from context that this is a key-value pair. For simple cases like `Type: github`, this inference is trivial. For complex cases like `State transitions: In Progress: add label:in-progress, Blocked: add label:blocked` — where the VALUE itself contains colons — the inference becomes ambiguous. Is `In Progress` a sub-key of `State transitions`? Is everything after the first colon the value? The table format eliminates this ambiguity entirely because column boundaries are explicit.

2. **Visual grouping under section headers.** The table visually belongs to its `### Issue Tracker` heading. With colon notation, the boundary between one section's key-value pairs and the next section's heading is a blank line — the same delimiter used between paragraphs of prose. The table's horizontal rules (`|------|---------|`) create an unambiguous visual boundary.

3. **Consistency with config-reader contract.** The `core/config-reader.md` contract explicitly specifies: "each is a `| Key | Value |` table under its `### {Section}` heading." Changing the template format means changing the config-reader contract, the scaffolder agent (which generates configs), the onboard skill, troubleshooting docs, architecture docs, and CLAUDE.md itself. Phase 2 research counted 12+ file changes for this migration. The 260 tokens/run saving does not justify this cross-cutting change.

### The real trade: 260 tokens/run vs. ambiguity risk in complex values

The `State transitions` key is the critical example. Its value is a structured mapping embedded inside a table cell: `In Progress: \`add label:in-progress\`, Blocked: \`add label:blocked\``. In table format, the cell boundary makes it unambiguous where the value ends. In colon notation:

```
State transitions: In Progress: `add label:in-progress`, Blocked: `add label:blocked`, For Review: `add label:for-review`, Done: `close`
```

This is a single line with four colons serving different semantic roles — section separator, sub-key separator (x3). An LLM can parse this, but it is working harder to do so, and the probability of a parsing error on an unusual value is higher than with the table format.

---

## Topic 3: Core Contracts — Narrative Process Sections

### The inline typing convention is already token-optimal

Phase 2 research made a critical finding that I want to amplify: the core contracts use an inline typing convention (`**field** (type, required): description`) that is MORE token-efficient than explicit YAML schema. From the research synthesis:

> "Migration would increase token cost by 40-60%."

This is not a marginal difference. The `core/decomposition-heuristics.md` Input Contract demonstrates this:

```markdown
| Field | Type | Notes |
|-------|------|-------|
| decompose_flag | enum | `FORCE` / `DISABLED` / `AUTO` — from `--decompose` / `--no-decompose` flags |
| code_analyst_output | object | Fields: `risk` (LOW/MEDIUM/HIGH), `affected_files` (integer), `estimated_diff_lines` (integer) |
```

The equivalent JSON Schema:

```json
{
  "decompose_flag": {
    "type": "string",
    "enum": ["FORCE", "DISABLED", "AUTO"],
    "description": "From --decompose / --no-decompose flags"
  },
  "code_analyst_output": {
    "type": "object",
    "properties": {
      "risk": { "type": "string", "enum": ["LOW", "MEDIUM", "HIGH"] },
      "affected_files": { "type": "integer" },
      "estimated_diff_lines": { "type": "integer" }
    }
  }
}
```

The JSON Schema version is roughly 2x the tokens for identical semantic content. And the LLM does not need JSON Schema to understand types — it reads `(integer)` and `(enum)` inline annotations just as reliably as formal schema declarations, because these annotations appear throughout documentation, API references, and README files in its training data.

### Process sections carry conditional logic that YAML cannot express naturally

The `core/state-manager.md` Write Process is a perfect example:

```
1. Read current state from `.ceos-agents/{RUN-ID}/state.json`
2. If file does not exist, initialize from schema template (see `state/schema.md`)
3. Set the value at the specified field_path
4. Update `updated_at` to current ISO-8601 timestamp
5. Append event to `.ceos-agents/{RUN-ID}/pipeline.log` (JSONL format)
6. Write to `.ceos-agents/{RUN-ID}/state.json.tmp`
7. Rename `.tmp` to `.json` (atomic on POSIX; best-effort on Windows)
8. If write fails: retry once. If second attempt fails: log warning, continue pipeline
```

Step 2 contains a conditional. Step 7 contains a platform-conditional parenthetical. Step 8 contains nested conditionals with different outcomes. These are natural-language control flow statements that the LLM interprets in the same way it interprets instructions in a tutorial or runbook.

Converting to YAML:

```yaml
write_process:
  - step: 1
    action: "Read current state"
    path: ".ceos-agents/{RUN-ID}/state.json"
  - step: 2
    condition: "file does not exist"
    action: "initialize from schema template"
    reference: "state/schema.md"
  ...
  - step: 8
    condition: "write fails"
    action: "retry once"
    fallback:
      condition: "second attempt fails"
      action: "log warning, continue pipeline"
```

The YAML version fragments a single coherent instruction ("If write fails: retry once. If second attempt fails: log warning, continue pipeline") into a tree of conditions and actions. The LLM must now reconstruct the sequential flow from a hierarchical data structure. This is cognitive overhead that adds tokens AND reduces comprehension.

---

## Topic 4: Skill Files — Sequential Instructions

### Numbered lists are the optimal format for LLM instruction-following

The skill files are the most critical files in the entire plugin. `skills/fix-bugs/SKILL.md` is 770+ lines of complex pipeline orchestration with conditional branching, parallel execution, state management, and error handling. The LLM must follow these instructions EXACTLY — a single misinterpretation can cause a wrong issue tracker state transition, a premature PR creation, or a silent data loss in state.json.

Markdown numbered lists are the format that LLMs follow most reliably for sequential instructions. This is not speculation — it is a direct consequence of the training data distribution. Stack Overflow answers, GitHub README files, tutorial blog posts, official documentation: the overwhelming majority of "do this, then do this, then do this" instructional content on the internet uses markdown numbered lists. LLMs have seen billions of examples of this format and have learned its semantics: numbers imply order, sub-bullets imply elaboration, bold text implies emphasis.

### The branching logic in fix-bugs proves the point

Consider the decomposition decision flow in `skills/fix-bugs/SKILL.md` (steps 3a-3b):

```markdown
### 3b. Decomposition decision (per-bug)

For each bug individually:

If `decompose_mode = DISABLED` -> skip to step 3d (pre-fix hook).
Update `state.json`: set `decomposition.status` to `"completed"`...

If `decompose_mode = FORCE` or `decompose_mode = AUTO`:

Evaluate the code-analyst output:
- `risk == HIGH` -> DECOMPOSE
- `affected_files >= 4` -> DECOMPOSE
- `estimated_diff_lines > 60 AND affected_files >= 3` -> DECOMPOSE
- `independent_changes >= 2` -> DECOMPOSE
- Otherwise and `decompose_mode = AUTO` -> SINGLE_PASS
```

This is imperative pseudocode written in markdown. The LLM reads it as a decision tree with explicit branch targets ("skip to step 3d"). Converting this to YAML would require inventing a control-flow DSL:

```yaml
step_3b:
  name: "Decomposition decision"
  scope: "per-bug"
  branches:
    - condition: "decompose_mode == DISABLED"
      action: "skip"
      target: "step_3d"
    - condition: "decompose_mode == FORCE OR decompose_mode == AUTO"
      evaluate:
        - condition: "risk == HIGH"
          result: "DECOMPOSE"
```

This YAML is not simpler. It is not more compact. It is not more precise. It is a custom DSL that the LLM has never seen before in its training data, dressed in YAML syntax. The LLM would need to learn this DSL's semantics on the fly, from a single example, with zero error tolerance. The markdown version leverages conventions the LLM already knows.

---

## Topic 5: Output Templates — Markdown Code Blocks

### The natural generation argument

When the fixer agent needs to produce its output, it generates:

```markdown
## Fix Report
- **Objective:** {root cause and what was wrong}
- **Approach:** {what was done and why}
- **Files changed:** {list}
- **Build:** PASS
- **Tests:** PASS
```

This is markdown generating markdown. The LLM's token-by-token generation process naturally produces markdown structures — headings, bold text, bullet lists. There is no mode switch, no escaping, no format translation. The output template in the agent definition looks exactly like the output the agent produces. This 1:1 correspondence between template and output minimizes the probability of format errors.

### JSON/YAML output schemas introduce real failure modes

If we required the fixer to output JSON:

```json
{
  "objective": "root cause and what was wrong",
  "approach": "what was done and why",
  "files_changed": ["file1.ts", "file2.ts"],
  "build": "PASS",
  "tests": "PASS"
}
```

Three failure modes immediately appear:

1. **Escaping.** If the `approach` field contains a quote character, a newline, or a backslash — all common in technical descriptions — the JSON becomes invalid. The LLM must correctly escape these characters inside a JSON string. This is a known failure mode for LLMs, especially when the content is long or contains code snippets.

2. **Structural rigidity.** The reviewer's output includes variable-length lists (issues, AC fulfillment). In markdown, adding another issue is trivially appending a numbered line. In JSON, it means maintaining valid array syntax with correct comma placement. Every model has a non-zero failure rate on trailing commas in JSON arrays.

3. **Downstream parsing complexity.** The orchestrating skills currently consume agent output as natural language — they look for tokens like `APPROVE`, `REQUEST_CHANGES`, `Quality gate: UNCLEAR`. These tokens exist in the markdown prose at predictable locations. If the output were JSON, the skills would need to parse JSON, handle malformed JSON gracefully, and extract fields from a structured object — all operations that are more complex and more failure-prone than string matching.

### The Machine Output question (addressing Phase 2's deferred item)

Phase 2 correctly identified that machine-readable tokens embedded in prose templates are fragile. I agree this is the highest-priority structural risk. But the solution is NOT to replace markdown output with JSON output. The solution — which Phase 2 also identified — is to ADD a `## Machine Output` section that provides a structured anchor ALONGSIDE the existing prose output, not instead of it.

This preserves the natural generation flow (the LLM still writes markdown) while adding a predictable extraction point for machine-readable signals. The `## Machine Output` section would itself be markdown:

```markdown
## Machine Output
- verdict: APPROVE
- ac_fulfillment: [FULFILLED, FULFILLED, PARTIALLY]
- issues_count: 3
```

Simple key-value pairs in a markdown list. No JSON escaping. No YAML parsing. The LLM generates it naturally. Skills extract it by heading anchor. Both worlds satisfied.

---

## Summary Position

| Topic | My verdict | Token cost of current format | Comprehension risk of alternative |
|-------|-----------|------------------------------|----------------------------------|
| Agent definitions | Keep markdown | ~2% overhead (630 tokens) | HIGH — degrades instruction-following on conditional logic, TDD protocol, reviewer loop |
| Config templates | Keep tables (defer migration) | ~260 tokens/run | MEDIUM — colon ambiguity on complex values like State transitions |
| Core contracts | Keep markdown + inline typing | Negative (YAML would cost 40-60% MORE) | HIGH — fragments conditional process logic into unfamiliar DSL |
| Skill files | Keep markdown | ~1,500 tokens across 28 skills | CRITICAL — 770-line pipeline orchestration with branching; markdown is the only format the LLM can follow reliably at this complexity |
| Output templates | Keep markdown code blocks | Negligible | HIGH — JSON/YAML introduces escaping failures, structural rigidity, and downstream parsing complexity |

The Token Economist is solving a real problem (cost), but optimizing the wrong variable. The right variable to optimize is **instruction-following reliability per token**. On that metric, markdown is not just competitive — it is dominant. Every departure from markdown trades a known-good comprehension baseline for speculative token savings, in a system where a single comprehension failure can cost more (in human time, pipeline reruns, and blocked issues) than thousands of saved tokens.

The only format change I would support is the additive `## Machine Output` section for agents that produce machine-readable signals — and even that should be markdown-formatted, not JSON or YAML.
