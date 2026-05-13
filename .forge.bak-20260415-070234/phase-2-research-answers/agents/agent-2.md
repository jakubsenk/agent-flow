# Phase 2 — Go/No-Go Decision: Format Changes in ceos-agents

## Decision Summary

**PARTIAL GO** — No format migration for agents/skills/core. Targeted non-format improvements proceed. Config notation is optional.

---

## Decision by Category

### Agents (21 files, ~31,800 tokens, 27% of budget)

**NO-GO for format change.**

87–93% of content is instructional prose. That prose is the program — it cannot be compressed by serialization change. The structured fraction (7–13%) is YAML frontmatter, which is already optimal and is a hard runtime requirement. Expected savings from any format change: ~2% per file on the prose body — approximately 630 tokens total across all 21 agents. That is not a meaningful gain. Changing the prose body to YAML or JSON would actively degrade LLM instruction-following fidelity with no offsetting benefit.

### Skills (28 files, ~75,500 tokens, 63% of budget)

**NO-GO for format change.**

Same structural argument as agents, amplified: skills are 63% of the total token budget because they contain complex pipeline logic, conditional branches, and agent invocation sequences. 90–96% of each file is procedural prose. Claude Code requires `.md` naming and YAML frontmatter — these are hard runtime constraints. The 4–10% structured fraction (frontmatter + a few inline tables) is already in its optimal format. Format migration would reduce this category's tokens by approximately 1,500 tokens total while meaningfully degrading the LLM's ability to follow complex multi-branch pipeline logic.

### Core (11 files, ~8,200 tokens, 7% of budget)

**NO-GO for format change.**

The current prose-with-inline-typing convention (`**field** (type, required): description`) is already more token-efficient than YAML schema syntax for contract documentation. Switching to YAML would make core files larger, not smaller. No change warranted.

### Config Templates (8 files, ~3,600 tokens, 3% of budget)

**OPTIONAL GO — low priority.**

This is the only category where a format change produces material per-category savings (~35% on the structured content, ~1,250 tokens total across all 8 templates). The `| Key | Value |` markdown table format costs ~40% more tokens than `Key: Value` colon notation.

However: this is 3% of the plugin's total token budget. The absolute saving is small. The human-editing benefit of markdown tables (visual alignment, familiar to CLAUDE.md maintainers) is real and non-trivial for a no-build-system plugin maintained by direct file editing.

**Recommendation:** Implement `Key: Value` colon notation in config templates only if a consuming project's CLAUDE.md is a demonstrated bottleneck in pipeline cost (it is read on every invocation). Do not migrate as a plugin-level priority. This is a PATCH-level optional improvement, not a pipeline requirement.

---

## Priority Ordering for Approved Changes

Ranking by: Impact × Frequency first, then Risk (lower = first), then Effort (less = first).

| Rank | Change | Category | Impact | Risk | Effort | Version Level |
|------|--------|----------|--------|------|--------|---------------|
| 1 | Add `## Machine Output` sections to triage-analyst, code-analyst, fixer, reviewer | Non-format quality | HIGH — prevents silent pipeline failures | LOW — additive only | LOW — 4 files, ~10 lines each | MAJOR (new output section in agent output format contract) |
| 2 | Fix scaffolder.md duplicate `4b` step numbering | Non-format quality | MEDIUM — eliminates LLM step-dependency ambiguity | LOW — wording change only | LOW — 1 file, <5 lines | PATCH |
| 3 | Add contributor note at top of fix-bugs/SKILL.md explaining atomic-write repetition pattern | Non-format quality | MEDIUM — reduces cognitive load, no functional change | NEGLIGIBLE | LOW — 1 file, ~3 lines | PATCH |
| 4 | Add explicit prose constraint to triage-analyst for Reproduction steps JSON format | Non-format quality | MEDIUM — reduces parse failures in browser-verifier/reproducer | LOW — Constraints section addition | LOW — 1 file, 1 line | PATCH |
| 5 | Remove or enforce `Issues found: {count}` field in reviewer.md | Non-format quality | LOW-MEDIUM — eliminates decorative inconsistency trap | LOW | LOW — 1 file, 1 line | PATCH |
| 6 | Config table `Key: Value` notation migration (optional) | Format change | LOW — 3% of budget, ~1,250 tokens total | LOW | MEDIUM — 8 template files + docs update | PATCH |

**Items 2–5 can be batched into a single PATCH commit. Item 1 requires a MAJOR version bump and should be a separate release.**

---

## Non-Format Improvements: Should the Pipeline Implement Them?

### Machine-readable token fragility — YES, implement (Priority 1)

This is the highest-risk structural problem in the plugin. Five machine-parsed tokens (`Quality gate: UNCLEAR`, `root cause confirmed: NO`, `## NEEDS_DECOMPOSITION`, `APPROVE/REQUEST_CHANGES/BLOCK`, `FULFILLED/PARTIALLY/NOT ADDRESSED`) control pipeline branching but are embedded in prose with no schema enforcement. Case variation or template deviation causes silent failures — the pipeline continues in the wrong state with no error signal.

The fix is a `## Machine Output` section appended to each affected agent's output template containing only the machine-parsed tokens as bare key-value pairs:

```
## Machine Output
verdict: APPROVE
ac_fulfilled_count: 3
```

This is additive, does not change the existing prose template consumed by downstream agents as context, and adds reliable grep-able parsing anchors for skill branching logic. It is strictly better than the current pattern.

**Version implication:** This adds new structured output sections to four agents' output format contract. Per the versioning policy, new output sections that external tooling may parse = MAJOR version bump. Plan for v7.0.0.

### Config table format (| Key | Value | vs Key: Value colon notation) — OPTIONAL, low priority

As analyzed above: real savings, small absolute impact, low risk. Implement opportunistically in consuming projects' CLAUDE.md. Do not block other work on this.

### Scaffolder duplicate 4b step numbering — YES, implement immediately (Priority 2)

Low effort, zero risk, immediate clarity improvement. Fix in the next PATCH release alongside other minor corrections.

### Large file decomposition (scaffold 925 lines, fix-bugs 770 lines) — DEFER, needs research first

File decomposition for Claude Code skill files requires confirming whether the runtime supports skill file includes or continuation loading. Phase 1 identified this as a research gap (Recommended Research item 2). Do not implement until that constraint is confirmed. If the runtime does not support includes, decomposition is a naming/organization change only (multi-file skill) and the dependency contracts between phases must be explicitly designed. This is a MINOR version change minimum, possibly MAJOR depending on whether skill structure changes affect the output format contract.

### Boilerplate repetition (atomic-write reminder ×15) — YES, add contributor note (Priority 3)

The repetition is correct for LLM clarity and must not be removed. The fix is a single contributor-facing comment block at the top of `skills/fix-bugs/SKILL.md` documenting the pattern intentionally. Low effort, zero risk, no version change.

---

## The One Non-Negotiable Constraint

Claude Code requires `.md` file naming and YAML frontmatter for all skills and agents. This is not a stylistic preference — it is a hard runtime requirement with evidence from `.agents-md/` tracking, plugin.json metadata, and frontmatter runtime directives (`disable-model-invocation`, `allowed-tools`, `argument-hint`) that have no meaning outside YAML frontmatter. Any format migration proposal that involves renaming files or removing frontmatter will silently break skill registration and agent discovery. This constraint closes the format migration question entirely.

---

## Most Important Insight

The plugin's token cost is an instructional prose cost — not a serialization overhead cost — and the only material risk in the current format is not inefficiency but silent branching failures from unschematized machine-readable tokens embedded in prose output templates.
