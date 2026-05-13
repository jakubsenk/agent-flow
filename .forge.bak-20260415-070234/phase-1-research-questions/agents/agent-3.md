# Phase 1 Research — Agent 3 Findings
## Questions: Q5 (Human Maintainability), Q6 (Specific Problem Areas), Q7 (Output Format Templates)

---

## Q5: Human Maintainability

### Summary Verdict

Markdown is the clearly superior format for this plugin. The comparison below is concrete, not theoretical — it is grounded in what contributors actually do when editing these files.

### Format Comparison for Manual Editing

**Markdown (current format)**

Strengths:
- Natural reading flow. A contributor opening `agents/fixer.md` immediately sees the agent's role, goal, process steps, and constraints as prose. No decoding of structure is required.
- Headings (`## Goal`, `## Process`, `## Constraints`) act as visual anchors. A contributor who needs to add a process step finds the right place in under five seconds.
- Fenced code blocks (` ``` `) let contributors embed output templates and block comment templates directly in context. There is no escaping problem.
- Lists and numbered steps (e.g., the 11-step Process in `agents/code-analyst.md`) are trivially editable — add a line, renumber if needed. No bracket or indentation error is possible.
- Diff readability: a markdown diff shows exactly which sentence or bullet changed. A reviewer can read the diff in GitHub without a rendered preview.

Weaknesses:
- The `| Key | Value |` table format in config files requires manual column alignment for readability. Misaligned pipes are syntactically valid but visually degraded.
- There is no schema enforcement. A contributor can misspell a heading (e.g., `## Constrants`) and the LLM will either skip the section or misinterpret it. No tooling catches this.
- Frontmatter YAML (4 keys: name, description, model, style) is minimal and low-risk, but any contributor unfamiliar with YAML might add a colon in the `description` value without quoting it and introduce a parse error.

**YAML (hypothetical full-YAML format)**

Weaknesses for this use case:
- Process steps with nested sub-items (like scaffolder's 8-batch generation plan) require multi-level nesting. YAML indentation errors are silent — the structure parses but maps to the wrong parent.
- Embedding multi-line prose (agent instructions, conditional logic descriptions) requires either literal block scalars (`|`) or folded scalars (`>`). Both are unfamiliar to contributors who are not YAML specialists.
- Embedding fenced code blocks inside YAML string values requires careful quoting and escaping of backticks or indented content — error-prone even for experienced editors.
- Diff readability degrades significantly. A change to one sentence in a long `|`-scalar block shows the entire block as modified in most diff tools.

**JSON (hypothetical full-JSON format)**

Weaknesses for this use case:
- JSON has no comments. The current codebase relies heavily on inline comments for context (e.g., `<!-- MCP detection logic: see core/mcp-detection.md -->`). All of these would be lost.
- No multi-line string support — embedded code blocks would require `\n`-encoded strings, making them unreadable to human editors.
- Trailing comma rule errors are the most common JSON editing mistake. With no linter, contributors would introduce silent failures.
- Diff readability: every closing `}` or `]` appears on its own line, creating noisy diffs.

### Error Rate Assessment

For this plugin's specific editing patterns (adding a bullet to a process, modifying a constraint rule, adjusting a retry count in a config table):

- **Markdown tables:** Low error rate. The `| Key | Value |` pattern is simple. The most common error (misaligned pipes) does not break parsing by an LLM — it only affects visual readability.
- **YAML frontmatter (4 keys):** Very low error rate for 4 flat keys. Error rate would rise sharply if frontmatter were expanded to contain process steps.
- **YAML body for process steps:** High error rate. The current 11-step process in `code-analyst.md` with nested sub-steps, embedded pseudocode, and inline tables would be extremely difficult to maintain as YAML without tooling.
- **JSON:** Highest error rate for human editing without a linter.

### Diff Readability

Markdown wins unambiguously. Adding a constraint to `agents/reviewer.md` produces a single-line diff showing exactly the added text. The same change in YAML would add one line but potentially require reindenting adjacent lines. In JSON it would require adding a comma to the previous item (a separate line change) and the new value.

### Conclusion for Q5

The current format (markdown body + 4-key YAML frontmatter) is the right choice for a no-build-system, no-linter plugin. The risk of silent formatting errors is lowest with markdown. The only genuine pain point is the `| Key | Value |` table format in config sections, which does not self-validate but is not error-prone enough to justify switching to YAML (which would introduce its own class of indentation errors).

---

## Q6: Specific Problem Areas in Current Format

### `examples/configs/github-nextjs.md` — Config Table Analysis

File: `examples/configs/github-nextjs.md`

The `| Key | Value |` tables work well for simple key-value pairs. Specific observations:

**What works:**
- Simple sections (Issue Tracker, Source Control, PR Rules, Build & Test) are clean and readable. Each section is 4–6 rows, easy to scan.
- The separator `|------|---------|` has slightly unequal column widths (6 vs 9 dashes) but this is cosmetically harmless.

**Pain points found:**

1. **State transitions value is a compound string inside a single table cell.**
   ```
   | State transitions | In Progress: `add label:in-progress`, Blocked: `add label:blocked`, For Review: `add label:for-review`, Done: `close` |
   ```
   This value encodes a key→value map as a comma-separated string inside a pipe-delimited table cell. It is visually dense and hard to edit without introducing syntax errors. A contributor who needs to add a new transition must parse the embedded format mentally. There is no clear delimiter between the transition name and its action — the colon is overloaded (used in the label name AND as the separator between name and action).

2. **PR Description Template breaks the table metaphor.**
   The PR Description Template section is a multi-line template, NOT a key-value table. It sits inside `## Automation Config` as free markdown after the `### PR Description Template` heading. This inconsistency is intentional (the config reader special-cases it) but is not obvious to a first-time contributor — they might attempt to put it in a table.

3. **Pipeline Profiles table has a 3-column layout.**
   ```
   | Profile | Skip stages | Extra stages |
   |--------|-------------|-------------|
   | fast | triage, code-analyst, test-engineer | — |
   ```
   The separator row has asymmetric dash counts (8, 13, 13 columns). This is valid but visually inconsistent with 2-column `| Key | Value |` tables. A contributor adding a new profile row must manually maintain column widths.

4. **Commented-out optional sections create noise.**
   All optional sections are wrapped in an HTML comment block (`<!-- ... -->`). This is a valid documentation pattern but means contributors must uncomment sections to use them — and must not accidentally leave the `-->` inside the config block. There is no clear visual separator between the active config and the commented template section.

**No quoting or escaping issues** were found. Values with backticks (e.g., `` `npm run build` ``) are handled correctly and display well in rendered markdown.

---

### `agents/scaffolder.md` — Scale Analysis (15KB)

File: `agents/scaffolder.md`

**Structure clarity at 15KB:**
The file is long but well-organized. The 8-batch generation plan (lines 27–114) is the heaviest section. Each batch is a bold label followed by a bulleted file list. This works at the current scale.

**Pain points found:**

1. **Step numbering is inconsistent and non-sequential.**
   Steps go: 1, 2 (with Batch 1–8 sub-items), 3, 4, **4b**, **4b** again (labeled `4b. Generate quality scorecard`), 5. The file has TWO sections labeled `4b` — one for CLAUDE.md generation (labeled step 3 in the text but contextually step 4b) and one for the quality scorecard (explicitly labeled `4b`). This would confuse a contributor trying to find a specific step. More critically, the LLM reading this file may misinterpret step dependencies.

2. **Conditional logic embedded in prose.**
   Batch 6 and Batch 7 have multi-paragraph conditionals (detect web project, detect Playwright across 6 stacks). This is a wall of prose with bold sub-headings. It is functional but difficult to audit — it is easy to miss a case in the cross-stack detection table. A structured decision table would be cleaner here, but markdown tables with multi-line cells are not supported.

3. **The quality scorecard template (step 4b) is a markdown table inside a fenced code block inside a list item.** This is valid but creates 3 levels of nesting that is visually hard to edit. Any change to a scorecard row requires correct pipe placement while inside a code block.

4. **Config Contract checklist uses `- [ ]` task syntax inside a numbered step.** This is a creative use of markdown but creates visual ambiguity — the checkboxes are documentation (not interactive), and contributors might wonder if they are expected to tick them.

---

### `skills/scaffold/SKILL.md` — Manageability at 925 Lines

File: `skills/scaffold/SKILL.md` (925 lines, ~49KB)

This is the largest single file in the plugin. The question of whether markdown is adequate at this scale has a nuanced answer.

**What works:**
- Step headings (`### Step 0-INFRA`, `### Step 0-MCP`, `### Step 0`, etc.) provide clear navigation anchors. A contributor looking for MCP verification logic can jump to `### Step 0-MCP` directly.
- The use of HTML comments (`<!-- Step numbering rationale: ... -->`) to explain non-obvious decisions is effective and invisible to the LLM when rendered.
- The `| Variable | Value |` table (lines 113–121) for in-memory state is clear.

**Pain points found:**

1. **The file is too long to hold in working memory while editing.** At 925 lines, a contributor making a change in Step 4 (around line 600) cannot easily verify that they have not broken a dependency mentioned in Step 0-INFRA (line 60). This is not a format problem — it is a scale problem. No serialization format solves it; only file decomposition does.

2. **Step 0-INFRA contains a deeply nested conditional tree.** The `--infra` flag parsing section (lines 39–88) uses prose with bold labels (`**Interactive mode**`, `**If tracker = "ready"`**`) to represent branching logic. The nesting goes 4 levels deep (infra flag → tracker choice → MCP result → write access result) as prose with `**If...**` headers. This is difficult to audit for completeness — it is easy to miss a branch. A flowchart or structured pseudocode would be clearer, but markdown does not support flowcharts natively.

3. **Pseudocode blocks for MCP downgrade logic** (lines 182–244) mix bash-style variable assignments (`SET x = y`), prose descriptions, and markdown headings inside a continuous prose section. The block is not fenced as code, so it renders as prose with bold labels. This is ambiguous: is it pseudocode the LLM should follow procedurally, or descriptive prose? The inconsistency between fenced pseudocode (e.g., the `--no-implement` git commands at line 321) and prose pseudocode (Step 0-MCP downgrade logic) creates reading uncertainty.

4. **`--infra` format validation (lines 39–46) has 4 conditional cases embedded in a list.** Each case uses a different trigger condition. There is no explicit else/default case marked — a contributor adding a new flag format must infer where to add it.

**Would a different format help?**
For the 925-line scale: splitting into multiple files would help more than format changes. The core orchestration logic in scaffold could be split into phase files (infra-setup, spec-phase, implementation-phase, finalization). This is a structural problem, not a serialization problem. Markdown is adequate for the content type; the issue is volume.

---

### `skills/fix-bugs/SKILL.md` — Manageability at 770 Lines

File: `skills/fix-bugs/SKILL.md` (770 lines, ~38KB)

**What works well:**
- The pipeline steps (`### 0.`, `### 1.`, `### 2.`, ...) are consistently numbered and named. Navigation is straightforward.
- The `### X. Block handler` at the end is a clear sink that all steps reference. The pattern `→ proceed to Block handler (step X)` is consistent and machine-parseable.
- State.json update instructions after each step (the `Update .ceos-agents/{ISSUE-ID}/state.json:` pattern) are consistently formatted and easy to locate.

**Pain points found:**

1. **Step 3b-tracker contains pseudocode in a fenced code block (lines 208–343).** This pseudocode mixes markdown list items, bold labels, and inline code. At ~130 lines, it is the longest single prose block in the file. The pseudocode syntax (`SET x = y`, `FOR EACH`, `TRY:`, `CATCH:`) is consistent, which is good, but it is an invented DSL that only works because the LLM understands it as procedural instructions. There is no formalization.

2. **The tracker-specific parameters table** (lines 346–355) is a 7-column table with multi-word values in some cells. The column widths are unequal and the table is difficult to edit in a plain text editor — adding a new tracker row requires manually counting pipe positions.

3. **Step numbering has lettered sub-steps** (3a, 3b, 3b-tracker, 3c, 3d, 3e). This is logically sound but the `3b-tracker` suffix is non-standard and visually breaks the alphabetical pattern (3a, 3b, 3b-tracker, 3c). A contributor looking for "what runs between triage and fixer?" must scan through 5 step variants. The naming convention is not documented.

4. **State.json update instructions are repeated verbatim** for every step. The phrase "Follow atomic write protocol from `core/state-manager.md`" appears at least 15 times in the file. This repetition is correct for clarity (the LLM needs the reminder each time) but adds ~200 lines of boilerplate that a contributor must mentally skip when reading for pipeline logic.

---

### `core/config-reader.md` — Input/Output Contract Analysis

File: `core/config-reader.md` (60 lines)

**What works well:**
- The file is short and well-structured. The three sections (Input Contract, Process, Output Contract) map to the standard function signature pattern.
- Process step 3 (optional sections) uses consistent format: section name → dot-notation keys → defaults in parentheses. This is easy to extend.
- Failure handling section at the end covers all failure modes explicitly.

**Pain points found:**

1. **The optional sections list (step 3) is a dense prose block.** Each section is one bullet with parenthesized defaults embedded inline. For sections with many keys (e.g., `### Browser Verification` has 8 keys, `### Sprint Planning` has 8 keys), the bullet line exceeds 200 characters. In a plain text editor, this wraps awkwardly.

2. **The `### Local Deployment` section description** (line 38) is the most complex entry: it explicitly documents the raw Key names AND the mapped dot-notation names (`Type` → `local_deployment.type`). This dual-name mapping is found only in this section — other sections map Key names directly. This asymmetry is not explained and could confuse a contributor who needs to add a new key to this section.

3. **The Output Contract section** (lines 44–45) is deliberately brief ("A config object with all parsed values..."). This is appropriate for a no-runtime plugin — there is no actual object, just a contract the LLM follows. But the brevity means contributors cannot verify what the output looks like without tracing it through consuming skills.

---

### Cross-File Pattern: Ambiguous Structure Indicators

Across all files examined, one consistent ambiguity surfaced: the use of `**bold text**` as a structural signal. Bold is used for:
- Section labels within steps (e.g., `**Batch 1 — Core:**`)
- Conditional branches (e.g., `**If tracker = "ready":**`)
- Important constraints (e.g., `**HARD REQUIREMENT**`)
- Term definitions (e.g., `**CRITICAL:**`)
- Sub-step labels (e.g., `**RED:**`, `**GREEN:**`, `**REFACTOR:**`)

These roles are contextually distinguishable but there is no formatting convention to differentiate them. A new contributor or a different LLM model might treat a conditional branch label the same as a definition label.

---

## Q7: Output Format Templates

### Finding: Templates Are Defined as Fenced Markdown Code Blocks

All four agents use the same pattern: a ` ```markdown ` fenced code block inside the Process section, immediately before the Constraints section. The template text contains `{placeholder}` tokens for variable substitution.

---

### `agents/triage-analyst.md` — Triage Analysis Template

Location: Process step 9 (lines 74–86)

Template structure:
```
## Triage Analysis
- **Summary:** {one-line description}
- **Area:** {module/component}
- **Severity:** {CRITICAL|HIGH|MEDIUM|LOW} — {brief justification}
- **Reproduction:** {numbered steps}
- **Attachments:** {what was found in screenshots/logs, or "none"}
- **Acceptance Criteria:**
  1. {testable criterion}
  2. {testable criterion}
- **Complexity:** {XS|S|M|L} — {brief justification}
- **Reproduction steps:** (only if UI-related) `[{action: "navigate", target: "/"}, ...]`
```

**Observation:** The `Reproduction steps` field has a dual structure — it is described as a JSON array literal embedded in a markdown bullet. The format is `[{action: "navigate", target: "/"}, ...]` — a JSON-like array where each item is an object with two keys. This is clearly structured data that downstream agents (browser-verifier, reproducer) must parse.

The consistency risk here is real: if the LLM omits the outer `[...]` brackets or uses prose instead of the object format, the reproducer agent will fail to parse the steps. The field format is documented with one example but no formal constraint.

**Would a YAML/JSON schema help?**
For this specific field (`Reproduction steps`), yes. If the triage-analyst output specified:
```yaml
reproduction_steps:
  - action: navigate
    target: /
  - action: click
    selector: "Submit button"
```
...downstream agents would have a reliably parseable structure. However, the entire triage output is markdown prose consumed by the next agent as context — switching the reproduction steps field to embedded YAML would create a hybrid format that is harder to parse than either pure format. The practical alternative is a clearer prose constraint: "MUST output as a JSON array literal, not prose".

---

### `agents/code-analyst.md` — Impact Report Template

Location: Process step 11 (lines 77–95)

Template structure:
```
## Impact Report
- **Root cause location:** {file:line — CONFIRMED}
- **Affected files:** {list, max 5}
- **Callers at risk:** ...
- **Test coverage:** ...
- **Risk level:** {LOW|MEDIUM|HIGH} — {justification}
- **Historical context:** (4 sub-bullets)
- **Reproduction trace (MANDATORY):**
  - Step 1: {repro step} → system state: {data} → code: {method} → input: {args} → output: {result}
  - Step N: ... → root cause confirmed: {YES / NO}
- **Sanity check:** "If I fix {root cause}..." → {YES/NO + explanation}
- **Suggested approach:** ...
```

**Observation:** The Reproduction trace field is the most structurally complex. Each trace step has 5 sub-fields separated by `→` arrows. This is a fixed-position format where field order matters but is enforced only by example.

The file also includes a "Consistency rule" note (lines 97–98): "The `root cause confirmed` value in the Reproduction trace (step N) and the Sanity check verdict MUST be identical." This is a cross-field consistency constraint. The LLM can violate it, and the current format provides no enforcement beyond the prose instruction.

**Would a YAML/JSON schema help?**
The `Reproduction trace` section specifically would benefit from structure. The `root cause confirmed: YES/NO` token is machine-read by `fix-bugs` (line 133: "If the impact report contains `root cause confirmed: NO` → proceed to Block handler"). This is a critical signal. If the LLM outputs "root cause confirmed: Not certain" or buries it in a different section, the skill logic breaks silently.

A minimal improvement would be a dedicated machine-readable output block:
```
root_cause_confirmed: YES
```
As a separate line outside the prose, making it grep-able. This is a targeted intervention, not a full schema switch.

---

### `agents/fixer.md` — Fix Report Template

Location: Process step 8 (lines 58–64)

Template structure:
```
## Fix Report
- **Objective:** {mode-dependent description}
- **Approach:** {what was done and why}
- **Files changed:** {list with descriptions}
- **Build:** PASS
- **Tests:** PASS / {note about pre-existing failures}
```

**Observation:** This is the simplest and most consistently outputted template in the plugin. Five fields, all prose except Build and Tests which are fixed-value (`PASS` or a note string).

The `## Fix Report` heading is the machine-readable signal consumed by `fix-bugs` step 6 (Reviewer reads "fixer's output") and by the reviewer agent (Process step 1). The heading functions as a section delimiter, not a strict schema.

**Would a YAML/JSON schema help?**
No. This template is consumed by the reviewer agent as narrative context — the reviewer reads "Approach" and "Files changed" to understand what the fixer did. Converting to YAML would not improve output consistency (all fields are prose) and would make reviewer processing harder (prose fields in YAML are less natural to reason about than prose fields in markdown).

The one reliability concern is `## NEEDS_DECOMPOSITION` — an alternative output that replaces Fix Report. The skill checks for the presence of this heading (fix-bugs line 434: "If fixer output contains `## NEEDS_DECOMPOSITION`"). This string-match approach is fragile if the LLM outputs `## Needs Decomposition` (different capitalization) or wraps it differently. A more explicit trigger (e.g., a standalone token on its own line) would be more robust than a heading match.

---

### `agents/reviewer.md` — Code Review Template

Location: Process step 7 (lines 69–79)

Template structure:
```
## Code Review
- **Verdict:** {APPROVE | REQUEST_CHANGES | BLOCK}
- **Issues found:** {count}
- **Issues:**
  1. [HIGH] {description} — {specific fix recommendation}
  2. [MEDIUM] {description} — {specific fix recommendation}
  3. [LOW] {description} — {specific fix recommendation}
- **AC Fulfillment:**
  1. {AC text} → {FULFILLED|PARTIALLY|NOT ADDRESSED} — {evidence}
```

**Observation:** This template has the highest machine-parsing dependency of any agent output in the plugin.

The `fix-bugs` skill reads the reviewer verdict to decide fixer loop iteration. The AC Fulfillment section is read by the acceptance-gate and by downstream skills. The `[HIGH]`, `[MEDIUM]`, `[LOW]` severity tags are structural tokens.

**Current reliability risks:**

1. **`Verdict:` is a prose field.** The skill must parse "APPROVE", "REQUEST_CHANGES", or "BLOCK" from a bullet point. If the LLM outputs `**Verdict:** Approve with conditions`, the skill logic may misread it.

2. **The `Issues found: {count}` field** is decorative (the skill counts issues from the list, not from this field) but creates a consistency trap — a reviewer that lists 3 issues but writes `Issues found: 2` creates a subtly wrong output.

3. **`AC Fulfillment` is conditional** (only output when AC were provided). The constraints section says "If acceptance criteria were provided in context, MUST include AC Fulfillment section." If the LLM omits this section when AC exist, the acceptance-gate receives no input. There is no fallback behavior defined.

**Would a YAML/JSON schema help?**
For the `Verdict` field specifically, yes. A structured output for the machine-readable fields would increase reliability:

```yaml
verdict: APPROVE
issues_count: 3
ac_fulfillment:
  - criterion: "Login button submits form"
    verdict: FULFILLED
    evidence: "...
```

However, this creates a hybrid document where the machine-readable block is separate from the prose justifications (issue descriptions, evidence text). The current design conflates machine-readable tokens (APPROVE, FULFILLED) with prose into a single markdown list, which works because the LLM understands the template but is fragile if output deviates from the template.

The most practical intervention short of a full schema change: add explicit machine-readable sentinels. For example:

```
VERDICT: APPROVE
```

As a standalone line before the full review text. The skill can reliably parse a line that starts with `VERDICT:` regardless of surrounding prose formatting.

---

### Cross-Agent Finding: The Machine-Readable Token Problem

Across all four agents, the same structural tension appears: output templates serve two audiences simultaneously — the next agent in the pipeline (which reads them as context prose) and the orchestrating skill (which parses specific tokens to make branching decisions).

The tokens that must be machine-parsed are:
- `Quality gate: UNCLEAR` (triage-analyst → fix-bugs step 2 branch)
- `root cause confirmed: NO` (code-analyst → fix-bugs step 3 branch)
- `## NEEDS_DECOMPOSITION` (fixer → fix-bugs step 4 branch)
- `APPROVE / REQUEST_CHANGES / BLOCK` (reviewer → fixer loop control)
- `FULFILLED / PARTIALLY / NOT ADDRESSED` (reviewer → acceptance-gate)

These tokens are embedded in prose-formatted markdown. They work reliably with claude-opus-4.x (which follows templates faithfully) but are fragile at the format level — case sensitivity, surrounding punctuation, and template deviation all create potential parse failures.

A targeted fix that preserves the current format would be to add a `## Machine Output` section at the end of each affected agent's output template, containing only the machine-parsed tokens as bare key-value pairs. The prose sections remain for human and agent readability; the machine section provides reliable parsing anchors. This is a smaller change than adopting YAML schemas and would address the actual reliability gap.
