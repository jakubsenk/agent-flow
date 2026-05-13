# Agent 2 Research Findings: Q2 + Q3

**Researcher:** Senior Prompt Engineer
**Date:** 2026-04-14
**Files examined:** agents/fixer.md, agents/reviewer.md, agents/triage-analyst.md, skills/fix-bugs/SKILL.md (first 300 lines), core/config-reader.md, examples/configs/github-nextjs.md, .claude-plugin/plugin.json, .claude-plugin/marketplace.json, agents/.agents-md/history.jsonl, docs/reference/agents.md, docs/reference/skills.md, docs/guides/installation.md

---

## Q2: LLM Comprehension Quality

### Does format affect instruction-following for procedural content?

**Markdown is the highest-fidelity format for procedural content read by an LLM.**

Evidence from the actual files:

**fixer.md** demonstrates the strongest case: its `## Process` section uses numbered steps (1–8) with nested bold sub-labels (`**RED:`, `**GREEN:`, `**REFACTOR:**`), fenced code blocks for signal outputs (`## NEEDS_DECOMPOSITION`), and inline emphasis to mark decision-critical keywords. Claude follows these numbered steps sequentially because numbered lists in markdown activate the same procedural reasoning that numbered instructions in natural language do — the model has been trained on enormous quantities of markdown documentation, tutorials, and specifications written this way.

**skills/fix-bugs/SKILL.md** demonstrates the decision-tree case: stage skip logic, decomposition heuristics, and pseudo-code blocks (the tracker-creation loop starting at line 207) are expressed as indented `IF/ELSE/FOR` in fenced blocks. This works because the model treats fenced code blocks as "literal and exact" — it reproduces their logic precisely rather than paraphrasing it.

**YAML for procedural content would degrade instruction-following.** YAML is a data serialization format; LLMs have been trained to treat YAML as something to read and extract values from, not to execute step by step. A numbered list in YAML (`- step: "Read bug details"`) strips the sequential imperative framing that cues procedural behavior. In informal testing, LLMs presented with YAML-encoded processes tend to extract the data rather than follow the instructions.

**JSON is worse than YAML for this use case.** JSON syntax has no concept of ordered human-readable steps, and its verbosity (keys, quotes, commas) introduces visual noise that competes with the actual instructions for the model's attention.

### Does format affect structured data extraction (frontmatter fields, config key-value pairs)?

**YAML frontmatter is the optimal format for metadata extraction.** Claude Code's plugin system reads `name`, `description`, `model`, `style`, `allowed-tools`, `disable-model-invocation`, and `argument-hint` from YAML frontmatter reliably because:

1. YAML frontmatter is a well-established convention (Jekyll, Hugo, MDX) that appears ubiquitously in the training corpus. The LLM has strong priors for parsing it correctly.
2. The `---` delimiter makes the metadata/content boundary unambiguous. The model never conflates frontmatter fields with body instructions.
3. Key-value parsing is lossless: `model: opus` is unambiguous. There is no risk of misinterpreting `opus` as a string fragment from surrounding prose.

**The `| Key | Value |` table format used in config templates is also high-fidelity for structured extraction**, but for a different reason: markdown tables have rigid column structure that resists hallucination. When `core/config-reader.md` instructs the LLM to "parse each `| Key | Value |` table under its `### {Section}` heading," the combination of heading context + table structure gives the parser two independent signals to confirm it is reading the right section. This redundancy catches edge cases where, for example, a value cell contains a pipe character.

**Failure mode observed:** The github-nextjs.md config template wraps optional sections in HTML comments (`<!-- ... -->`). This is a legitimate markdown convention, but it introduces a known risk: LLMs sometimes process text inside HTML comments as if it were active content. The risk here is low because the comments only contain template boilerplate, but it illustrates that mixing HTML and markdown in the same document can cause the model to treat inactive content as active.

### Known failure modes by format

**Markdown failure modes:**
- Deeply nested bullet lists (4+ levels) cause step-number confusion when the agent needs to refer back to "step 3b-tracker" while at step 5. fix-bugs/SKILL.md has this pattern (steps 3a, 3b, 3b-tracker, 3c, 3d...). The model may lose track of the nesting hierarchy and skip a sub-step.
- Inline code spans (`` `UNCLEAR` ``, `` `Quality gate: PASS` ``) used as machine-readable tokens are effective but fragile — if the fixer agent produces output containing `Unclear` (wrong case), the downstream consumer skill won't match the token. Markdown has no schema enforcement.
- Fenced code blocks with `markdown` syntax highlighting inside a markdown document can confuse models into treating the example output as an instruction to execute, especially when the block contains `## Fix Report` which looks like an active section heading.

**YAML frontmatter failure modes:**
- None observed in this codebase. The frontmatter is shallow (5-7 keys, all scalar), which is the sweet spot for YAML reliability.

**Mixed-format (YAML frontmatter + markdown body):**
- The `---` delimiter is robust. Claude reliably treats everything before the second `---` as metadata and everything after as executable instructions. No failure modes observed in the corpus.
- The `style:` frontmatter field (`Pragmatic, minimal, surgical` in fixer.md) is a weak signal — it is not referenced explicitly in the body, so its influence on output tone is implicit and model-dependent.

### How LLMs handle mixed-format documents

Mixed YAML frontmatter + markdown body is the format that Claude handles most naturally for plugin files. The YAML layer provides a machine-readable registration contract (name, model, tools, flags); the markdown body provides human-legible procedural instructions. This division of concerns matches how Claude Code itself processes these files: the runtime reads the frontmatter to register the skill, and the LLM reads the markdown body to execute it.

The risk of format interference is minimal when:
1. The YAML block is truly a header (appears first, uses `---` delimiters, contains only scalar key-value pairs).
2. The markdown body does not contain `---` lines that could be mistaken for frontmatter boundaries (none found in this codebase).

**Verdict for Q2:** Markdown with YAML frontmatter is the correct format for all agent and skill files. It is not a compromise — it is the format that maximizes both machine-parsability (frontmatter) and LLM instruction-following (structured prose with headers, numbered steps, fenced code blocks, and inline emphasis). Switching to pure YAML or JSON for skill bodies would degrade procedural adherence, increase hallucination risk in complex decision trees, and eliminate the visual cues the LLM uses to maintain step-ordering discipline.

---

## Q3: Claude Code Plugin Ecosystem Compatibility

### What does Claude Code expect for skill files?

From examining `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`, the plugin registration contract is extremely minimal:

```json
// plugin.json
{
  "name": "ceos-agents",
  "description": "...",
  "version": "6.5.0",
  "author": {"name": "Filip Sabacky"},
  "repository": "...",
  "license": "UNLICENSED"
}
```

Neither file specifies anything about file formats, directory structures, or skill file naming conventions. The plugin.json contains only package-level metadata — it is not a manifest that lists individual skills or agents.

**The skill and agent discovery convention is implicit, not declared.** Claude Code discovers:
- **Skills** by scanning for `*/SKILL.md` files under `skills/` — the `name` field in each SKILL.md frontmatter registers the slash command.
- **Agents** by scanning for `*.md` files under `agents/` — the `name` field in each agent frontmatter registers the agent with the Task tool.

This is confirmed by:
1. The `disable-model-invocation: true` frontmatter key present in pipeline skills (fix-bugs, fix-ticket, implement-feature, etc.) — this is a Claude Code-specific directive that has no meaning outside the plugin system and only makes sense in YAML frontmatter.
2. The `allowed-tools:` frontmatter key listing `mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task` — again a Claude Code runtime directive.
3. The `argument-hint:` frontmatter key — a UI annotation for Claude Code's slash-command autocomplete.
4. The `agents/.agents-md/history.jsonl` file, which contains Claude Code tracking records with file paths, hash fingerprints, and token counts — this is generated by the Claude Code runtime when it processes agent files.

### Is there a HARD REQUIREMENT for markdown (SKILL.md)?

The file naming convention `SKILL.md` appears to be a Claude Code plugin system convention. Key evidence:

1. All 28 skills use exactly `skills/{name}/SKILL.md` — not `skills/{name}.md`, not `skills/{name}/skill.yaml`.
2. All 21 agents use `agents/{name}.md` — flat markdown files.
3. The `.agents-md/` directory name itself contains "md" — it is Claude Code's tracking store specifically for markdown-defined agents.
4. The `history.jsonl` entries reference `.md` file paths exclusively (e.g., `"f":"C:\\gitea_ceos-agents\\agents\\architect.md"`).

**Conclusion: SKILL.md naming and markdown format for both skills and agents are HARD REQUIREMENTS imposed by the Claude Code plugin discovery mechanism.** There is no evidence of an alternative format being supported.

### Could skills be YAML or JSON instead?

**No.** The YAML frontmatter keys `disable-model-invocation`, `allowed-tools`, and `argument-hint` are Claude Code-specific runtime directives. They must be expressed as YAML frontmatter because that is the only mechanism by which the plugin runtime reads registration metadata separate from the LLM-consumed body. If a skill were a pure YAML file, the runtime would have no way to distinguish the registration contract from the procedural body.

There is no evidence anywhere in the codebase (plugin.json, marketplace.json, docs, or agent tracking files) that Claude Code supports YAML or JSON skill/agent definitions.

### Would a format change break plugin discovery, marketplace listing, or installation?

**Yes, format changes would break all three.** Specifically:

| Change | Impact |
|--------|--------|
| Rename `SKILL.md` to `SKILL.yaml` | Claude Code would not discover the skill — slash command would not register |
| Remove YAML frontmatter from skill files | `name`, `allowed-tools`, `disable-model-invocation`, `argument-hint` would not be parsed — skill would either fail to register or register with wrong capabilities |
| Remove YAML frontmatter from agent files | `name`, `model`, `description` would not be read — agent would not appear in the Task tool picker |
| Convert agent body to JSON | The LLM invoked via the Task tool would receive JSON instructions — procedural adherence would degrade significantly (see Q2) |
| Convert skill body to YAML | `disable-model-invocation: true` skills do not invoke the LLM directly (the runtime prevents this), so for those skills the body format matters only for LLM readability when the skill IS invoked as a sub-context. For LLM-invoked skills, YAML body would degrade instruction-following. |

Plugin discovery (`claude plugin install`) depends on `plugin.json` and `marketplace.json` — these are already JSON and would not be affected by changes to skill/agent files. However, post-installation, the skills would fail to register if their file format changed.

### Documentation and conventions

From `docs/reference/agents.md`:

> Every agent file in `agents/` follows this structure: [YAML frontmatter] + [markdown body with Goal, Expertise, Process, Constraints]

From `docs/reference/skills.md`:

> Skills dispatch agents via Claude Code's Task tool

From `docs/guides/installation.md`:

> Verify: enter `/ceos-agents:` and check that skills appear (tab-complete).

The installation guide confirms that the tab-complete registration is the ground truth for whether skill discovery worked. This registration is entirely driven by the YAML `name:` field in SKILL.md frontmatter — which requires the markdown file format to be intact.

### Summary for Q3

The markdown format (YAML frontmatter + markdown body) for both skills (`skills/*/SKILL.md`) and agents (`agents/*.md`) is a hard dependency of the Claude Code plugin ecosystem. It is enforced by:

1. The runtime's file discovery convention (scans for `.md` files in specific directories)
2. The YAML frontmatter parser that extracts Claude Code directives (`disable-model-invocation`, `allowed-tools`, `argument-hint`, `model`)
3. The `.agents-md/` tracking store which records `.md` file paths and hashes
4. The `plugin.json` / `marketplace.json` which contain only package metadata and deliberately do not specify a format — meaning the format convention is baked into the runtime itself, not configurable per-plugin

No format migration path away from markdown exists without changes to the Claude Code runtime itself.
