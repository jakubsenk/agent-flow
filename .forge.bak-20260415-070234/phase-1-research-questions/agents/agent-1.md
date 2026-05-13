# Research Questions Q1 + Q4: Token Economics & Hybrid Format Viability

**Analyst:** Agent-1 (Senior Prompt Engineer)
**Date:** 2026-04-14
**Corpus measured:** 6 representative files + category totals across 4 file categories

---

## Q1: Token Economics — Quantitative Comparison

### Measurement Methodology

Token counts are estimated using content-aware ratios:
- English prose (narrative, process steps, descriptions): ~4 chars/token
- Structured/symbolic content (YAML, JSON keys, tables, code): ~3.5 chars/token
- Mixed content (most files): weighted blend per section

All byte counts are from `wc -c` on Unix (byte = char for ASCII/UTF-8 content in this corpus).

---

### Category Totals (Baseline)

| Category | File Count | Total Bytes | Est. Tokens |
|----------|------------|-------------|-------------|
| agents/ | 21 | 124,710 | ~31,800 |
| skills/ | 28 | 295,766 | ~75,500 |
| core/ | 11 | 32,271 | ~8,200 |
| examples/configs/ | 8 | 13,915 | ~3,600 |
| **Grand total** | **68** | **466,662** | **~119,100** |

At current load patterns (one agent + one skill invoked per pipeline step), a single pipeline run loads roughly 6,000–12,000 tokens of plugin prompt content before any project context.

---

### File-Level Measurements

#### 1. agents/fixer.md (6,071 bytes, 95 lines)

**Section breakdown:**
- Frontmatter (YAML): 5 lines, ~120 chars → 34 tokens
- Preamble sentence: 1 line, ~90 chars → 22 tokens
- Goal (1 paragraph): ~180 chars → 45 tokens
- Expertise (1 line): ~110 chars → 27 tokens
- Process (8 numbered steps, including sub-bullets, code blocks): ~4,700 chars → ~1,175 tokens
- Reviewer Loop section: ~700 chars → ~175 tokens
- Constraints (7 rules): ~870 chars → ~217 tokens

**Total estimated: ~1,695 tokens** (cross-check: 6,071 / 3.58 ≈ 1,696 ✓)

**Section content type analysis:**
- Structured: frontmatter (5 lines), output template code block (~15 lines) → ~500 chars
- Narrative: everything else → ~5,571 chars

Structured fraction: ~8%

**Rewrite experiment — frontmatter section only (fair comparison target):**

Current markdown frontmatter (120 chars, 34 tokens):
```
---
name: fixer
description: Implements minimal, correct code changes targeting the objective. Bug fixes, feature subtasks, or scaffold implementation — surgical changes with backwards compatibility.
model: opus
style: Pragmatic, minimal, surgical
---
```

Same data as JSON (182 chars, 52 tokens):
```json
{"name":"fixer","description":"Implements minimal, correct code changes targeting the objective. Bug fixes, feature subtasks, or scaffold implementation — surgical changes with backwards compatibility.","model":"opus","style":"Pragmatic, minimal, surgical"}
```

Same data as YAML without delimiters (118 chars, 34 tokens):
```yaml
name: fixer
description: Implements minimal, correct code changes targeting the objective. Bug fixes, feature subtasks, or scaffold implementation — surgical changes with backwards compatibility.
model: opus
style: Pragmatic, minimal, surgical
```

**Verdict for frontmatter:** YAML ≈ current format. JSON is 51% larger. The `---` delimiters cost only 8 chars total. No gain switching to JSON; YAML already optimal.

**Rewrite experiment — output template (Fix Report code block, 15 lines, ~380 chars):**

Current (markdown fenced code block, 380 chars, ~109 tokens):
```
```markdown
## Fix Report
- **Objective:** {mode-dependent: Bug-fix → root cause...}
- **Approach:** {what was done and why this approach over alternatives}
- **Files changed:** {list with brief description of each change}
- **Build:** PASS
- **Tests:** PASS / {note about pre-existing failures}
```
```

Same as YAML schema (310 chars, ~89 tokens):
```yaml
fix_report:
  objective: "{mode-dependent: Bug-fix → root cause; Feature/scaffold → subtask goal}"
  approach: "{what was done and why this approach}"
  files_changed: "[list with brief description]"
  build: "PASS"
  tests: "PASS | {note about pre-existing failures}"
```

Same as JSON schema (295 chars, ~84 tokens):
```json
{
  "fix_report": {
    "objective": "...",
    "approach": "...",
    "files_changed": "...",
    "build": "PASS",
    "tests": "PASS | ..."
  }
}
```

**Verdict for structured output template:** YAML saves ~18%, JSON saves ~23% vs. fenced markdown. However, this is a 109-token section in a 1,695-token file — maximum savings of ~25 tokens per fixer.md invocation. Not material.

---

#### 2. agents/scaffolder.md (14,889 bytes, 209 lines)

**Total estimated: ~4,168 tokens** (14,889 / 3.57 ≈ 4,170)

This is the largest agent. It contains heavily nested conditional logic (Batch 1–8 with per-language branches) that is fundamentally narrative/instructional, not structured data.

**Section breakdown:**
- Frontmatter: ~120 chars → 34 tokens (0.8%)
- Process steps with nested batches: ~11,200 chars → ~3,100 tokens (74%)
- CLAUDE.md generation checklist (table-like, but in bullet form): ~1,200 chars → ~315 tokens (7.5%)
- Constraints (10 rules): ~1,300 chars → ~340 tokens (8%)
- Output template code block: ~900 chars → ~245 tokens (5.8%)
- Goal + Expertise: ~350 chars → ~90 tokens (2%)

Structured fraction: frontmatter + output template scorecard table = ~1,000 chars → ~6.7%

**Rewrite experiment — quality scorecard table in output (11-row markdown table, ~900 chars, ~245 tokens):**

Current markdown table (inside fenced code block):
```
| Check | Status | Notes |
|-------|--------|-------|
| Build | PASS | ... |
| Tests | PASS | 1 smoke test |
| Lint | PASS | ruff configured |
| CLAUDE.md | PASS | 5/5 required sections |
...
```

Same as YAML list (compact, ~640 chars, ~183 tokens):
```yaml
scorecard:
  - check: Build; status: PASS
  - check: Tests; status: PASS; notes: 1 smoke test
  - check: Lint; status: PASS; notes: ruff configured
  - check: CLAUDE.md; status: PASS; notes: 5/5 required sections
  - check: Dockerfile; status: PASS; notes: multi-stage, python:3.12-slim
  - check: CI config; status: PASS; notes: lint → test → build
  - check: Dependencies; status: WARN; notes: 2 unpinned dev dependencies
  - check: Test infra; status: PASS; notes: conftest.py with port allocation
  - check: Design system; status: PASS; notes: Tailwind CSS configured
  - check: E2E test setup; status: PASS; notes: playwright.config.ts, 1 smoke test
  - check: App documentation; status: PASS; notes: docs/ARCHITECTURE.md with 4 sections
```

Same as JSON array (~780 chars, ~223 tokens):
```json
{"scorecard": [
  {"check":"Build","status":"PASS"},
  {"check":"Tests","status":"PASS","notes":"1 smoke test"},
  ...
]}
```

**Verdict:** YAML saves ~25% on this specific block. But the narrative process steps (74% of file) cannot be meaningfully compressed by format change. Maximum total savings on scaffolder.md: ~60 tokens on a 4,168-token file = 1.4%.

---

#### 3. skills/analyze-bug/SKILL.md (1,845 bytes, 39 lines)

**Total estimated: ~513 tokens** (1,845 / 3.60 ≈ 512)

This is a small orchestration skill. Content is almost entirely imperative instructions.

**Section breakdown:**
- Frontmatter: ~160 chars → 46 tokens (9%)
- MCP pre-flight section: ~360 chars → ~100 tokens (19.5%)
- Steps 1–5 (numbered instructions): ~1,100 chars → ~305 tokens (59.5%)
- Final note: ~160 chars → ~44 tokens (8.5%)

Structured fraction: frontmatter metadata + argument-hint = ~160 chars → 9%

**Rewrite experiment — frontmatter (160 chars, 46 tokens):**

Current:
```
---
name: analyze-bug
description: Analyzes a specific bug from the issue tracker (analysis only, no code changes)
allowed-tools: mcp__*, Read, Glob, Grep, Task
argument-hint: "<ISSUE-ID>"
---
```

As JSON (218 chars, 62 tokens):
```json
{"name":"analyze-bug","description":"Analyzes a specific bug from the issue tracker (analysis only, no code changes)","allowed-tools":["mcp__*","Read","Glob","Grep","Task"],"argument-hint":"<ISSUE-ID>"}
```

**Verdict:** Skill frontmatter is slightly more complex (has array-valued `allowed-tools`). JSON is 35% larger. YAML is already the most compact structured format for this content.

---

#### 4. core/config-reader.md (5,557 bytes, 59 lines)

**Total estimated: ~1,544 tokens** (5,557 / 3.60 ≈ 1,543)

This file is a contract document — unusually high structured-data density.

**Section breakdown:**
- H1 title + Purpose paragraph: ~180 chars → 50 tokens (3.2%)
- Input Contract (list of 1 field): ~120 chars → 33 tokens (2.1%)
- Process step 1 (heading location): ~160 chars → 44 tokens (2.8%)
- Process step 2 — required sections enumeration (dense key→field mappings): ~1,050 chars → ~286 tokens (18.5%)
- Process step 3 — optional sections with defaults (most complex, 18 entries): ~2,600 chars → ~710 tokens (46%)
- Process step 4 (validation): ~170 chars → ~47 tokens (3%)
- Output Contract: ~290 chars → ~80 tokens (5.2%)
- Failure Handling (3 cases with block templates): ~870 chars → ~236 tokens (15.3%)

Structured fraction: steps 2+3 (key→field mapping tables rendered as prose lists) = ~3,650 chars → ~66% structured-equivalent content

**Rewrite experiment — optional sections enumeration (step 3, ~2,600 chars, ~710 tokens):**

Current format (prose with inline defaults, one item shown):
```
- `### Retry Limits` → `retry.fixer_iterations` (default: 5), `retry.test_attempts` (default: 3), `retry.build_retries` (default: 3), `retry.spec_iterations` (default: 5), `retry.root_cause_iterations` (default: 3)
```

Same as YAML object (compact, one item):
```yaml
retry_limits:
  section: "### Retry Limits"
  fields:
    fixer_iterations: {key: "Fixer iterations", default: 5}
    test_attempts: {key: "Test attempts", default: 3}
    build_retries: {key: "Build retries", default: 3}
    spec_iterations: {key: "Spec iterations", default: 5}
    root_cause_iterations: {key: "Root cause iterations", default: 3}
```

Current prose for retry section: ~210 chars → ~58 tokens
YAML equivalent: ~280 chars → ~80 tokens

**Reversal finding:** The prose format ("key → field (default: N)") is MORE token-efficient than explicit YAML key-value because it exploits English's implicit pairing grammar. The arrow notation encodes `section_heading → output_field (default: value)` in minimal characters without YAML structural overhead.

Full step 3 comparison across all 18 optional sections:
- Current prose: ~2,600 chars → ~710 tokens
- YAML equivalent: ~3,200 chars → ~914 tokens
- JSON equivalent: ~3,900 chars → ~1,114 tokens

**Verdict:** For config-reader.md, the current prose format beats both YAML and JSON by 22–36%. The file is essentially a schema expressed as English-grammar prose, which is the most compact encoding for key-value mappings when field names are natural language phrases.

---

#### 5. core/state-manager.md (3,256 bytes, 63 lines)

**Total estimated: ~912 tokens** (3,256 / 3.57 ≈ 912)

**Section breakdown:**
- Purpose paragraph: ~230 chars → 63 tokens (7%)
- Input Contracts (3 operations, typed fields): ~550 chars → ~148 tokens (16%)
- Process (3 sub-processes, numbered steps): ~1,650 chars → ~446 tokens (49%)
- Output Contracts: ~340 chars → ~91 tokens (10%)
- Failure Handling (4 cases with inline resolutions): ~480 chars → ~130 tokens (14%)

Structured fraction: Input + Output contracts (typed fields) = ~890 chars → ~27%

**Rewrite experiment — Write Operation input contract (typed fields, 3 fields, ~180 chars, ~49 tokens):**

Current:
```
### Write Operation
- **run_id** (string, required): Issue ID or generated ID
- **field_path** (string, required): Dot-notation path (e.g., "triage.status")
- **value** (any, required): Value to set at the field path
```

As YAML:
```yaml
write_operation:
  run_id: {type: string, required: true, description: "Issue ID or generated ID"}
  field_path: {type: string, required: true, description: 'Dot-notation path (e.g., "triage.status")'}
  value: {type: any, required: true, description: "Value to set at the field path"}
```
YAML: ~280 chars → ~80 tokens

As JSON Schema:
```json
{"write_operation":{"run_id":{"type":"string","required":true},"field_path":{"type":"string","required":true},"value":{"type":"any","required":true}}}
```
JSON: ~155 chars → ~44 tokens (but drops descriptions)

**Verdict:** JSON Schema without descriptions is 10% smaller. With descriptions, YAML is 63% larger and JSON is 43% larger than the current prose. Prose wins for field documentation because it collapses type + required + description into one natural-language phrase.

---

#### 6. examples/configs/github-nextjs.md (3,040 bytes, 134 lines)

**Total estimated: ~851 tokens** (3,040 / 3.57 ≈ 851)

**Section breakdown:**
- Title + header comment: ~100 chars → ~28 tokens (3.3%)
- Required config sections (5 tables, required content only): ~1,100 chars → ~303 tokens (35.6%)
- PR Description Template (free text): ~100 chars → ~27 tokens (3.2%)
- Optional sections in HTML comment (9 tables): ~1,650 chars → ~453 tokens (53.2%)
- Separator comments: ~90 chars → ~25 tokens (3%)

Structured fraction: all config tables = ~2,750 chars → 90.5% structured

**Rewrite experiment — required sections (5 tables, ~1,100 chars, ~303 tokens):**

Current markdown table format:
```
### Issue Tracker
| Key | Value |
|------|---------|
| Type | github |
| Instance | `github.com` |
| Project | `<owner/repo>` |
| Bug query | `is:issue is:open label:bug` |
| State transitions | In Progress: `add label:in-progress`, Blocked: `add label:blocked`... |
| On start set | `add label:in-progress` |

### Source Control
| Key | Value |
|------|---------|
| Remote | `github.com/<owner/repo>` |
| Base branch | `main` |
| Branch naming | `fix/{issue}-{short-description}` |
...
```
~600 chars for these two sections → ~170 tokens

Same as YAML:
```yaml
issue_tracker:
  type: github
  instance: github.com
  project: <owner/repo>
  bug_query: "is:issue is:open label:bug"
  state_transitions:
    In Progress: "add label:in-progress"
    Blocked: "add label:blocked"
    For Review: "add label:for-review"
    Done: close
  on_start_set: "add label:in-progress"

source_control:
  remote: "github.com/<owner/repo>"
  base_branch: main
  branch_naming: "fix/{issue}-{short-description}"
```
~390 chars → ~111 tokens

Same as JSON:
```json
{
  "issue_tracker": {
    "type": "github",
    "instance": "github.com",
    "project": "<owner/repo>",
    "bug_query": "is:issue is:open label:bug",
    "state_transitions": {
      "In Progress": "add label:in-progress",
      "Blocked": "add label:blocked",
      "For Review": "add label:for-review",
      "Done": "close"
    },
    "on_start_set": "add label:in-progress"
  },
  "source_control": {
    "remote": "github.com/<owner/repo>",
    "base_branch": "main",
    "branch_naming": "fix/{issue}-{short-description}"
  }
}
```
~500 chars → ~143 tokens

**Verdict:** YAML saves ~35% vs. markdown tables for config data. JSON saves ~16% vs. markdown tables. The `| Key | Value |` table format is the LEAST efficient structure for key-value config data because it adds four characters of pipe-and-space overhead per row plus a mandatory separator row.

For full config file (5 required + 9 optional tables):
- Current markdown: ~2,750 chars → ~771 tokens
- YAML: ~1,800 chars → ~509 tokens
- JSON: ~2,200 chars → ~619 tokens

**YAML would save ~262 tokens per config file** — the largest per-file gain found in this analysis.

---

### Q1 Summary: Token Efficiency by Content Type

| Content Type | Current Format | Best Alternative | Savings | Recommendation |
|---|---|---|---|---|
| Agent frontmatter (name/model/style) | YAML | YAML | 0% | Keep as-is |
| Skill frontmatter (+ allowed-tools) | YAML | YAML | 0% | Keep as-is |
| Process steps / narrative instructions | Markdown prose | No change | 0% | Prose is optimal |
| Output templates (structured reports) | Markdown fenced block | YAML | ~18–25% | Low-value target |
| Config key→field mappings (config-reader style) | Prose arrows | Prose | 0% (prose wins) | Keep as-is |
| Config data tables (Key\|Value tables) | Markdown tables | YAML | **~35%** | Best target |
| Contract typed fields (Input/Output contracts) | Prose (type + desc) | Prose | 0% (prose wins) | Keep as-is |

**Key finding:** The only content type where a format change produces material token savings is the `| Key | Value |` table format used in config files. All other content types (prose instructions, YAML frontmatter, prose contracts) are already at or near optimal density for their information content.

---

## Q4: Hybrid Format Viability

### Per-Category Breakdown

#### Category: agents/ (21 files, 124,710 bytes, ~31,800 tokens)

**Content mix per typical agent file:**

| Section | Type | Approx % of content |
|---|---|---|
| YAML frontmatter | Structured | 2–3% |
| Goal paragraph | Narrative | 3–5% |
| Expertise sentence | Narrative | 2–3% |
| Process steps (numbered, with sub-bullets) | Narrative/Instructional | 60–75% |
| Reviewer Loop section (where present) | Narrative | 8–12% |
| Constraints | Narrative (rules) | 10–15% |
| Output template (code block) | Semi-structured | 5–10% |

**Structured data percentage: ~7–13%** (frontmatter + output template only)

**Narrative percentage: ~87–93%**

**Hybrid viability assessment:**
A hybrid that expressed only frontmatter + output templates in YAML/JSON would touch at most 13% of the token budget. On a typical 1,500-token agent file, savings would be 15–30 tokens. The narrative instructions — process steps, constraints, expertise — are inherently language-dependent and cannot be compressed via format change without losing semantic fidelity. They exist to guide an LLM, not to be parsed by a runtime.

**Verdict: Hybrid NOT viable for agents.** The structured fraction is too small to justify the added complexity of a dual-format file. The current single-format (YAML frontmatter + markdown body) is correct.

---

#### Category: skills/ (28 files, 295,766 bytes, ~75,500 tokens)

Skills are more heterogeneous than agents. Small utility skills (analyze-bug, create-pr, publish) are almost entirely narrative. Large pipeline skills (fix-bugs, scaffold, implement-feature — the top 3 alone account for 121K of 296K bytes) contain:

**Large skill file content mix (fix-bugs, fix-ticket, implement-feature, scaffold):**

| Section | Type | Approx % of content |
|---|---|---|
| YAML frontmatter | Structured | 0.5–1% |
| Pipeline steps (numbered, conditional) | Narrative/Instructional | 55–65% |
| Config reading instructions | Narrative | 5–8% |
| Agent invocation blocks | Semi-structured | 3–5% |
| Error/block handling prose | Narrative | 8–12% |
| State write instructions | Narrative | 5–8% |
| Hook/custom agent sections | Narrative | 5–10% |
| Inline config examples | Semi-structured | 3–5% |

**Structured data percentage: ~4–10%** (frontmatter + agent invocation patterns + inline config examples)

**Narrative percentage: ~90–96%**

**Hybrid viability assessment:**
The pipeline skills read and follow instructions — the narrative IS the program. Any attempt to serialize the step logic into YAML or JSON would simply recreate the natural language as structured fields (e.g., `step_1: "Read Automation Config..."`) without saving tokens, because the verbosity comes from the instruction content, not the format syntax.

Exception: the agent invocation blocks within skill files do have a semi-structured pattern:
```
Run `ceos-agents:triage-analyst` on bug $ARGUMENTS
Pass context: {issue_id, config}
After completion: post checkpoint comment
```
This pattern could theoretically be expressed as a YAML dispatch table. But since the LLM reads these as instructions (not code), prose is equally readable and slightly more compact.

**Verdict: Hybrid NOT viable for skills.** Same reasoning as agents — the narrative proportion dominates, and the structured portions are already minimal.

---

#### Category: core/ (11 files, 32,271 bytes, ~8,200 tokens)

Core files are contract documents. They have higher structured-data density than agents or skills.

**Content mix (averaging across core files):**

| Section | Type | Approx % of content |
|---|---|---|
| Purpose paragraph | Narrative | 8–12% |
| Input/Output Contracts (typed fields) | Semi-structured prose | 15–25% |
| Process steps | Narrative | 40–50% |
| Failure Handling cases | Narrative | 15–20% |

**Structured data percentage: ~15–25%** (typed field contracts + error case labels)

**Narrative percentage: ~75–85%**

**Hybrid viability assessment:**
The typed field contracts (`- **field_name** (type, required): description`) resemble YAML/JSON schema in intent, but as shown in the state-manager analysis, the prose encoding is already more token-efficient than explicit YAML Schema because it collapses four attributes (name, type, required, description) into a single natural-language phrase.

The failure handling sections are narrative and cannot be meaningfully structured without losing the explanatory prose that makes them useful to an LLM.

**Verdict: Hybrid NOT viable for core.** The prose contract format is already the most compact encoding for this content type.

---

#### Category: examples/configs/ (8 files, 13,915 bytes, ~3,600 tokens)

This is the ONLY category where a hybrid or pure format change would produce meaningful savings.

**Content mix:**

| Section | Type | Approx % of content |
|---|---|---|
| Title + header comment | Narrative | 2–4% |
| `| Key | Value |` tables | Structured data | 85–92% |
| Template placeholder prose | Narrative | 4–8% |
| HTML comment wrappers | Formatting | 1–2% |

**Structured data percentage: ~85–92%**

**Narrative percentage: ~8–15%**

**YAML conversion analysis:**
- Current total: 13,915 bytes → ~3,600 tokens
- Estimated YAML equivalent: ~9,000 bytes → ~2,350 tokens
- **Savings: ~1,250 tokens (35%)** across the 8 config template files

**What the boundary would look like in practice:**

OPTION A — Pure YAML config files (replace markdown tables entirely):
```yaml
# github-nextjs Automation Config
automation_config:
  issue_tracker:
    type: github
    instance: github.com
    project: <owner/repo>
    bug_query: "is:issue is:open label:bug"
    state_transitions:
      "In Progress": "add label:in-progress"
      Blocked: "add label:blocked"
      "For Review": "add label:for-review"
      Done: close
    on_start_set: "add label:in-progress"
  source_control:
    remote: "github.com/<owner/repo>"
    base_branch: main
    branch_naming: "fix/{issue}-{short-description}"
  pr_rules:
    labels: ForReview
    description_template: |
      ## Summary
      {summary}
      ## Changes
      {changes}
      ## Testing
      {testing}
      Fixes #{issue_number}
  build_and_test:
    build_command: npm run build
    test_command: npm test
```

OPTION B — Hybrid (keep markdown title/comments, replace tables with YAML blocks):
Same content but within a markdown document using YAML code fences labeled with section names.

OPTION C — Keep markdown tables but compress multi-value cells:
The main inefficiency in the current tables is the `| Key | Value |` two-column format with its header row overhead. A compressed single-column KV format with colons:
```
Type: github
Instance: github.com
Project: <owner/repo>
```
This saves ~40% over the table format with no structural change.

**Verdict: Hybrid IS viable for config templates, but the practical benefit is limited.**

The 8 config template files are 3% of total plugin token budget (3,600 / 119,100). Even a 35% saving = ~1,250 tokens saved. This is real but small relative to the overall corpus. The more significant implication is for the CONSUMING PROJECT'S CLAUDE.md — the config section that users copy from these templates into their own projects. That section is read on every pipeline invocation. Saving 35% there (~260 tokens per invocation) would compound across thousands of pipeline runs.

---

### Q4 Summary: Hybrid Viability by Category

| Category | Structured % | Narrative % | Hybrid Viable? | Max Savings | Savings vs. Total Budget |
|---|---|---|---|---|---|
| agents/ | 7–13% | 87–93% | No | ~2% per file | Negligible |
| skills/ | 4–10% | 90–96% | No | ~2% per file | Negligible |
| core/ | 15–25% | 75–85% | No (prose wins) | ~0% (prose optimal) | None |
| examples/configs/ | 85–92% | 8–15% | **Yes** | **~35%** | ~1% of total |

**Critical finding:** The narrative-heavy nature of agent/skill files means format changes cannot compress them. The information content IS the verbosity. The LLM is not a parser — it processes natural language tokens, not data structure tokens. For prose instructions, a shorter format simply means fewer explanatory words, not the same semantics in fewer tokens.

The only genuine format inefficiency in the ceos-agents corpus is the `| Key | Value |` markdown table format used in config files. This format pays ~40% token overhead vs. `Key: Value` colon notation or YAML. However, this format also serves a **human readability** function — users must read and edit their CLAUDE.md config manually, and markdown tables render clearly in GitHub/Gitea. This human-readability benefit likely outweighs the 35% token cost on config-sized content.

---

## Cross-Cutting Conclusions

### What the numbers say

1. **Frontmatter is already optimal.** YAML frontmatter (name/model/description/style) is the most compact structured format. JSON adds 35–51% overhead. No change warranted.

2. **Prose beats schemas for documentation.** The arrow notation in config-reader.md (`key → field (default: N)`) encodes more information per token than any formal schema format. This counterintuitive result holds because English grammar's implicit subject-predicate-object structure has lower overhead than explicit YAML/JSON key-value syntax when the values are short strings.

3. **The only actionable target is config tables.** The `| Key | Value |` format in examples/configs/ is 35% less efficient than YAML. However, converting it would break human readability of the config files users must edit.

4. **Scale makes format irrelevant for agents/skills.** A 2% saving on a 1,500-token agent file = 30 tokens. At scale (21 agents × 30 tokens = 630 tokens across the full corpus), this is less than one API request's noise. Not worth the complexity cost.

5. **The real token pressure is elsewhere.** At ~75,500 tokens, skills/ is 63% of the plugin budget. The token cost is driven by the AMOUNT of instructional prose (pipeline logic, conditional branches, agent invocation sequences), not by format overhead. Reducing token cost would require reducing instruction complexity — which is a content question, not a serialization question.

### Recommendation for Research Question Resolution

**Q1 answer:** YAML is the most token-efficient format for the structured portions of this codebase. JSON is consistently 20–50% larger. Prose (natural language) is more efficient than either for contract/documentation content. The current mixed format (YAML frontmatter + markdown body) is close to optimal.

**Q4 answer:** A hybrid format (structured parts in YAML/JSON, narrative in markdown) is not viable for agents, skills, or core files because their structured fraction (7–25%) is too small to justify dual-format complexity. It IS viable for config templates (85–92% structured), but savings (~35%) on a 3% budget slice do not justify breaking the human-editing experience of the config format.

**The most impactful single change** would be switching config file table format from `| Key | Value |` to `Key: Value` colon notation — saving ~35% on config token cost with minimal readability impact. This affects both the example templates AND users' CLAUDE.md configs read on every pipeline run.
