# The Token Economist — Brainstorm Position Paper

## Identity

I argue for maximum token reduction. Every token is cost. Structured formats are preferable wherever they demonstrably save tokens. I am skeptical of "it's fine as-is" arguments — but I am honest about constraints that block optimization.

---

## Topic 1: Agent Definitions (agents/*.md)

### My strongest case for YAML body

21 files, ~31,800 tokens, 27% of total budget. That is not trivial. If I could shave 10% off agent definitions, that is 3,180 tokens saved per pipeline context load. Across a day of 20 pipeline runs, that is 63,600 tokens — real money.

Consider `triage-analyst.md` (114 lines). The Process section contains numbered steps with nested bullet points, inline tables (the Quality Gate table), and code blocks. A YAML representation could collapse the frontmatter + body into a single structured document:

```yaml
name: triage-analyst
model: sonnet
goal: Transform vague bug reports into actionable specs
process:
  - read_issue: "Read bug details from issue tracker..."
  - download_attachments: "Download attachments if any..."
  - check_duplicates:
      - "Search open and recently resolved issues"
      - "Compare reproduction steps"
  - quality_gate:
      questions:
        - "Do I know what is wrong?"
        - "Do I know how to reproduce it?"
```

### Why I concede this point

The research is unambiguous and I cannot dispute it: **87-93% of agent content is instructional prose**. The prose IS the program. YAML encodes process steps as data structures, but LLMs follow numbered markdown steps with higher fidelity than YAML sequences. The Phase 2 research scored YAML body at 2/5 for LLM comprehension versus 5/5 for markdown.

More critically: the Claude Code runtime hard-requires `.md` file extension and YAML frontmatter. Even if I restructured the body, the file must remain `.md`. I would be embedding YAML inside a markdown file — gaining nothing from tooling and losing prose readability.

The expected savings are approximately 630 tokens across all 21 agents (~2%). That is 0.5% of total budget. The research is right: this is not worth pursuing. The instructional prose is load-bearing and cannot be compressed by serialization change.

**Verdict: NO-GO. I concede.**

But I register one protest: the output template sections (the `## Fix Report`, `## Triage Analysis` code blocks) ARE structured data wearing a prose costume. These specific sections — not the full body — could be defined as compact schemas. I return to this under Topic 5.

---

## Topic 2: Config Templates (examples/configs/*.md)

### My strongest case — and this one I do not concede

8 files, ~3,600 tokens in the plugin, 3% of budget. The research calls this "modest." I call it the wrong framing. The plugin templates are copied once. The consuming project's CLAUDE.md is read on EVERY SINGLE pipeline invocation. That is where the compounding happens.

**Concrete measurement from the files:**

Take the Issue Tracker section from `github-nextjs.md`:

```
| Key | Value |
|------|---------|
| Type | github |
| Instance | `github.com` |
| Project | `<owner/repo>` |
| Bug query | `is:issue is:open label:bug` |
| State transitions | In Progress: `add label:in-progress`... |
| On start set | `add label:in-progress` |
```

That is 342 bytes for 6 data rows. The colon equivalent is 277 bytes. That is 19% overhead just on pipes, separator rows, and header rows — and the 19% is LOWER than the research's 35% figure because that section has long values that dilute the fixed-cost overhead. Sections with short values (Retry Limits, Error Handling, PR Rules) have proportionally HIGHER overhead because the fixed table chrome dominates.

**Per-section breakdown of pure waste:**

Each `| Key | Value |` table contributes:
- 1 header row (`| Key | Value |`) = ~16 tokens of pure overhead per table
- 1 separator row (`|------|---------|`) = ~8 tokens of pure overhead per table
- Per data row: `| ` prefix + ` | ` separator + ` |` suffix = ~7 characters of overhead per row

Across all 8 templates: 59 header rows, 61 separator rows, 115 data rows. That is approximately:
- 59 headers x 16 chars = 944 chars overhead
- 61 separators x 18 chars = 1,098 chars overhead  
- 115 data rows x 7 chars = 805 chars overhead
- **Total pure overhead: ~2,847 characters = ~710 tokens wasted on table chrome**

The `redmine-oracle-plsql.md` alone has 19 header rows, 20 separator rows, and 39 data rows — over 1,200 characters of pure formatting waste.

**The compounding argument:**

A consuming project with a full config (say, 15 sections, comparable to the Oracle PL/SQL template) reads approximately 260 surplus tokens on EVERY pipeline call. At 20 pipeline runs per day:
- Daily: 5,200 wasted tokens
- Monthly: 156,000 wasted tokens
- Per year: ~1.9 million wasted tokens per consuming project

For a team running 3 projects, that is 5.7 million tokens per year burned on pipe characters and separator dashes. This is not "modest." This is a systematic tax on every user.

**The colon notation is strictly superior for this use case:**

```
### Issue Tracker
Type: github
Instance: github.com
Project: <owner/repo>
Bug query: is:issue is:open label:bug
State transitions: In Progress: add label:in-progress, Blocked: add label:blocked
On start set: add label:in-progress
```

- Fewer tokens (19-35% reduction depending on value length)
- Easier to edit (no pipe alignment)
- Unambiguous (the `State transitions` value currently competes with pipe delimiters inside table cells — this is a real parsing fragility)
- Claude parses `Key: Value` natively — this is how YAML works, which is already the frontmatter format

### The ecosystem constraint and my response

Agent 3 in Phase 2 identified that the format is enforced in 5 places: `core/config-reader.md`, `agents/scaffolder.md`, `skills/onboard/SKILL.md`, `docs/architecture.md`, `docs/guides/troubleshooting.md`. This makes it a 12+ file cross-cutting change.

I acknowledge this scope. But I argue the research misclassifies the version impact. Changing config EXAMPLES from tables to colon notation does NOT break existing consumer configs. The LLM reads both formats natively. The "breaking change" only occurs if we REMOVE support for table format. The correct migration path is:

1. **Phase 1 (MINOR):** Update `core/config-reader.md` to accept BOTH formats. Update examples to colon notation. Update `scaffolder.md` to generate colon notation for new projects. Leave existing table configs working.
2. **Phase 2 (optional, never):** Deprecate table format. This step may never be needed — supporting both formats costs nothing at runtime because the LLM handles both.

This makes it a MINOR version change, not MAJOR. The research's "MAJOR" classification assumes a hard cutover that removes table support. I am not proposing that. I am proposing dual-format acceptance with a canonical preference for the more efficient notation.

**Verdict: STRONG GO. This is the highest ROI change available.**

---

## Topic 3: Core Contracts (core/*.md)

### My case for YAML contracts

11 files, ~8,200 tokens, 7% of budget. The core contracts contain Input/Output sections with typed fields. Surely `**field** (type, required): description` is less efficient than:

```yaml
input:
  context:
    type: string
    required: true
    description: Mode-dependent input
  max_iterations:
    type: integer
    default: 5
```

### Why the evidence crushes me here

I measured it. The current inline convention from `core/fixer-reviewer-loop.md`:

```
| context | string | required | Mode-dependent input... |
```

That is one line encoding field name, type, requiredness, and description. The YAML equivalent:

```yaml
context:
  type: string
  required: true
  description: "Mode-dependent input..."
```

That is 4 lines for the same information. Even accounting for YAML's lack of pipe overhead, the 4-line schema is 40-60% MORE tokens than the inline convention. The research's numbers are correct: the prose arrow notation and inline typing ARE more token-efficient than explicit schema.

The core contracts are 7% of budget. Even if I could save 20% (which I cannot — I would INCREASE cost), that would be 1,640 tokens. But the actual direction is negative: migration would ADD ~3,000-5,000 tokens.

**Verdict: NO-GO. The current format is already near-optimal. I concede completely.**

---

## Topic 4: Skill Files (skills/*/SKILL.md)

### My case for optimization

28 files, ~75,500 tokens, 63% of the ENTIRE budget. This is the elephant in the room. Even a 5% reduction here saves 3,775 tokens. The top 4 files alone are 153,409 bytes:

| File | Lines | Bytes |
|------|-------|-------|
| scaffold/SKILL.md | 925 | 49,249 |
| fix-bugs/SKILL.md | 770 | 38,246 |
| implement-feature/SKILL.md | 658 | 33,515 |
| fix-ticket/SKILL.md | 633 | 32,399 |

These four files are ~52% of the skills budget and ~33% of the total plugin token budget.

The research identifies that "Follow atomic write protocol from core/state-manager.md" appears 16 times in fix-bugs/SKILL.md alone. That is ~160 tokens of repetition for a single instruction. Across all skills, the boilerplate repetition (state.json instructions, config reading patterns, error handling templates) likely totals 2,000-3,000 tokens.

### Why format change does not solve this

The skill content is 90-96% procedural prose with conditional branches. This IS the pipeline logic. Converting `if triage output contains "Quality gate: UNCLEAR" then BLOCK` to YAML does not save tokens — it makes the conditional harder to express AND harder for the LLM to follow.

The research is right: the token cost driver is instructional complexity, not serialization overhead. The 4-10% structured content (frontmatter, occasional inline tables) is already minimal.

### What I argue for instead

The savings here come from CONTENT restructuring, not FORMAT change:

1. **Repeated boilerplate extraction:** The 16x "Follow atomic write protocol" repetitions, the config reading patterns duplicated across fix-ticket/fix-bugs/implement-feature, and the error handling templates could be extracted into core contracts referenced once. Estimated saving: 2,000-3,000 tokens (3-4% of skills budget). The research estimates 5,000-8,000 tokens (7-11%) through more aggressive restructuring.

2. **File decomposition:** The top 4 files exceed comfortable LLM working memory. If the Claude Code runtime supports multi-file skill loading, splitting scaffold/SKILL.md into 4 phase files would reduce per-invocation context by loading only the relevant phase. A pipeline run touching only the spec phase would load ~230 lines instead of 925 — a 75% reduction for that invocation. But this requires runtime research first.

3. **Machine Output sections (Topic 5):** Adding structured output parsing anchors could allow skills to be shorter by removing the defensive prose that currently explains how to parse agent output tokens embedded in narrative.

**Verdict: NO-GO on format change. STRONG GO on content restructuring. The estimated 5,000-8,000 token savings from content work dwarfs any format savings achievable in other categories.**

---

## Topic 5: Output Templates

### My strongest argument in this entire paper

The output templates embedded in agent definitions are structured data masquerading as markdown code blocks. Consider the fixer's output template:

```markdown
## Fix Report
- **Objective:** {mode-dependent: Bug-fix -> root cause...}
- **Approach:** {what was done and why...}
- **Files changed:** {list with brief description}
- **Build:** PASS
- **Tests:** PASS / {note about pre-existing failures}
```

And the reviewer parses this prose output looking for embedded tokens like `APPROVE`, `REQUEST_CHANGES`, `BLOCK`, `FULFILLED`, `PARTIALLY`, `NOT ADDRESSED`. These tokens are machine-readable signals controlling pipeline branching — but they are defined only by example in prose templates with no schema enforcement.

A JSON schema would be more compact AND more reliable:

```json
{"verdict": "APPROVE|REQUEST_CHANGES|BLOCK", "ac_fulfillment": [{"ac": 1, "status": "FULFILLED|PARTIALLY|NOT_ADDRESSED"}], "issues_count": 0}
```

That is 130 characters defining the ENTIRE machine-parseable output contract. The current prose template for the reviewer's output is approximately 400-500 characters of markdown that encodes the same information less precisely.

**Token savings from schema-defined output:** Across the 4 agents that produce machine-parsed tokens (triage-analyst, code-analyst, fixer, reviewer), replacing the prose output templates with compact JSON schemas would save approximately 200-400 tokens while INCREASING parsing reliability.

### The constraint I must acknowledge

The research's Phase 2 conclusion is that this is a MAJOR version change (v7.0.0) because it adds new structured output sections that external tooling may parse. The versioning policy is clear on this. The design question is also unresolved: do orchestrating skills actively parse `## Machine Output` or is it supplemental?

I argue strongly for active parsing. If the section is supplemental, it adds tokens without improving reliability — the worst outcome. If skills actively prefer the structured section, the reliability improvement justifies the token addition AND eventually allows removing the defensive prose that currently explains how to parse embedded tokens, creating a net token reduction.

### My concrete proposal for the brainstorm

The `## Machine Output` section should be defined as a compact key-value block (not JSON, not full YAML — just flat `key: value` pairs, the same format I advocate for config templates):

```
## Machine Output
verdict: APPROVE
ac_fulfilled: 3/4
issues_count: 0
```

This is:
- 4 lines / ~60 tokens for the entire machine-readable contract
- Grep-parseable by skills (simple `## Machine Output` heading anchor + line-by-line key extraction)
- Strictly additive (existing prose template preserved for human readability and LLM context)
- The skills should be updated to PREFER this section over prose parsing, with prose as fallback

The token cost is small (adding ~60 tokens to 4 agents = ~240 tokens). But it ENABLES future token reduction: once skills reliably parse the structured section, the verbose prose explanations of how to format machine tokens can be shortened, saving more than 240 tokens in skill files.

**Verdict: STRONG GO for v7.0.0. This is the second-highest ROI change after config notation, and the highest-impact change for pipeline reliability.**

---

## Summary: The Token Economist's Priority Ranking

| Rank | Change | Token Impact | Version | Confidence |
|------|--------|-------------|---------|------------|
| 1 | Config templates: tables to colon notation (dual-format, MINOR) | -260 tokens/run in consumers; -710 tokens in plugin templates; compounds to ~1.9M tokens/year per project | MINOR (not MAJOR — dual-format acceptance) | HIGH |
| 2 | Machine Output sections in 4 agents (active parsing) | +240 tokens now; enables -500 to -1,000 token reduction in skills long-term | MAJOR (v7.0.0) | MEDIUM-HIGH |
| 3 | Content restructuring in top 4 skill files (boilerplate extraction) | -5,000 to -8,000 tokens (4-7% of total budget) | MINOR | MEDIUM (depends on runtime research for decomposition) |
| 4 | Agent definitions: full YAML body | Not recommended — net negative | N/A | HIGH (against) |
| 5 | Core contracts: YAML schema | Not recommended — increases tokens by 40-60% | N/A | HIGH (against) |

### Key insight from the Token Economist

The research killed my instinct that structured formats always win. They do not. When the content is instructional prose for an LLM, prose IS the most efficient format — both in tokens and in execution fidelity. The token savings available in this plugin come from two sources only:

1. **Eliminating formatting waste in structured data** (config tables — Topic 2). This is real, compounding, and achievable as a MINOR change.
2. **Reducing content duplication** (skill boilerplate — Topic 4). This requires content work, not format work.

Format migration for agents, skills, and core is a dead end. I will not argue for it further. But I will argue loudly and repeatedly that the config table format is burning 260 tokens per pipeline run across every consuming project, and that is money left on the table (pun intended, and the table should be removed).
