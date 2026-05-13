# Format Evaluation: Markdown vs YAML vs JSON for ceos-agents

**Status:** COMPLETED (2026-04-14)
**Forge run:** forge-2026-04-14-002
**Verdict:** PARTIAL GO — markdown stays, small PATCH fixes implemented

## Executive Summary

Research across 7 dimensions concluded that the current YAML-frontmatter + markdown-body format is not a compromise — it is the correct and near-optimal choice for every file category. The plugin's token cost is driven by instructional prose complexity, not serialization format overhead.

## Research Findings

### Token Economics
- Total corpus: ~119,100 tokens; skills 63%, agents 27%, core 7%, configs 3%
- YAML frontmatter is already optimal — JSON is 35-51% larger for same metadata
- Prose contract notation beats YAML by 22% and JSON by 36% for key-value mappings with descriptions
- Only `| Key | Value |` tables in config templates show ~35% YAML advantage

### LLM Comprehension Quality
- Markdown numbered lists activate sequential procedural reasoning; YAML/JSON do not
- `## Constraints` heading activates behavioral-restriction semantics from training data
- `| Key | Value |` tables resist hallucination due to rigid column structure

### Ecosystem Compatibility
- Claude Code REQUIRES `.md` files for skills and agents — hard runtime constraint
- Frontmatter keys (`disable-model-invocation`, `allowed-tools`) only work as YAML frontmatter
- `agents/.agents-md/history.jsonl` confirms runtime scans for `.md` files specifically

### Hybrid Format Viability
| Category | Structured % | Hybrid Viable? |
|----------|-------------|----------------|
| agents/ | 7-13% | No |
| skills/ | 4-10% | No |
| core/ | 15-25% | No (prose already more efficient) |
| configs/ | 85-92% | Yes (but only 3% of budget) |

### Human Maintainability
- Markdown best for no-linter, no-build-system plugin
- YAML indentation errors are silent and catastrophic without tooling
- JSON cannot hold comments or multi-line strings without escaping

## Permanently Rejected

- YAML body for agent definitions
- JSON for any file category
- Full YAML for skill files
- Config template hard cutover to colon notation

## Future Work

1. **v7.0.0:** `## Machine Output` sections — explicit machine-readable token format in agent output templates
2. **v6.6.0:** Dual-format config support (accept both tables and colon notation)
3. **TBD:** File decomposition for large skills (blocked on runtime research)
