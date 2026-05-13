# Phase 0 Analysis

## Task Type Classification

**Type: MIGRATION**

This is a structural migration/refactor that merges two plugin codebases (forge and ceos-agents) into a single unified pipeline plugin. It involves:
- Restructuring the entire plugin directory layout
- Migrating 24 commands to a skill-based architecture
- Merging overlapping agent definitions
- Introducing a new unified `/build` entry point with mode detection
- Extracting shared infrastructure (pipeline engine, review loops, state management)
- Adding non-code modes (analysis, strategy, content) to the pipeline
- Maintaining backward compatibility with existing ceos-agents users

This is NOT a simple refactor — it is a cross-cutting migration that changes the plugin's public API, internal architecture, and agent roster simultaneously.

## Complexity Assessment

| Dimension | Score | Justification |
|-----------|-------|---------------|
| **Scope** | 5/5 | Affects every file in the repository (18 agents, 24 commands, 1 skill, plugin metadata, tests, docs, examples). Introduces new directory structure (core/, adapters/), new file types (skill definitions), and new concepts (mode adapters, pipeline engine). |
| **Ambiguity** | 4/5 | The brief provides a clear directional vision but leaves many design decisions open: exact mode adapter interfaces, which agent fields change during merges, how backward compatibility layers work for deprecated commands, how non-code modes (analysis/strategy/content) map to existing agent capabilities. |
| **Risk** | 5/5 | This changes the plugin's public API (commands → skills), the plugin identity (adding forge capabilities), agent definitions (merging/renaming), and the entire orchestration model (commands → pipeline engine + mode adapters). Breaking changes for existing users are near-certain without a careful migration strategy. The plugin has existing users who depend on the `ceos-agents:` namespace. |
| **Composite** | **4.7/5** | `(5 + 4 + 5) / 3 = 4.67` — This is a near-maximum complexity task. |

## Domain Identification

| Aspect | Value |
|--------|-------|
| **Language/Runtime** | Markdown (pure text plugin — no runtime code, no build system) |
| **Framework** | Claude Code plugin system (`.claude-plugin/`, skills, commands, agents with YAML frontmatter) |
| **Domain** | Developer tooling / AI agent orchestration / CI/CD pipeline design |
| **Specialty Concerns** | Plugin composability (namespace `ceos-agents:`), backward compatibility for existing users, Claude Code Task tool dispatching, MCP server integration patterns, pure-markdown constraint (no code generation), YAML frontmatter schema compliance, test harness (bash scripts for structural validation) |

## Codebase Context Assessment

### Patterns Identified

1. **2-Layer Architecture**: Commands (orchestration WHAT) dispatch Agents (specialists HOW) via Claude Code's Task tool. This is the core pattern being restructured.

2. **Agent Definition Pattern**: All 18 agents follow identical structure — YAML frontmatter (`name`, `description`, `model`, `style`) → Role statement → Goal → Expertise → Process (numbered) → Constraints (NEVER rules). This structure must be preserved in merged agents.

3. **Command Pattern**: Commands are markdown files with frontmatter (`description`, `allowed-tools`) containing step-by-step orchestration logic with Configuration → Flag Parsing → Pipeline Steps → Error Handling sections.

4. **Pipeline Patterns**: Three distinct pipelines (bug-fix, feature, scaffold) share common sub-patterns:
   - Fixer↔Reviewer loop (max N iterations)
   - Block/Rollback error handling
   - Hook integration points (pre-fix, post-fix, pre-publish, post-publish)
   - Agent Overrides (customization/ directory)
   - Pipeline Profiles (stage skipping)

5. **Config Contract**: Projects configure the plugin via `## Automation Config` in their CLAUDE.md using table format (`| Key | Value |`). This contract is versioned and changes require semver bumps.

6. **Block Comment Template**: Standardized failure reporting format with `[ceos-agents]` prefix for machine-parseable detection.

### Test Framework

- Bash script harness (`tests/harness/run-tests.sh`)
- 15 scenario scripts in `tests/scenarios/` doing structural validation (grep for patterns, check file existence, verify cross-references)
- No runtime tests (pure markdown plugin)
- Test scenarios verify: pipeline consistency, scaffold flows, browser verification skip logic, profile skip, happy paths

### Build System

- None. Pure markdown. No dependencies. No compilation.
- Version managed in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`

### Relevant Code Areas

| Area | Files | Migration Impact |
|------|-------|-----------------|
| **Agent definitions** | `agents/*.md` (18 files) | HIGH — merging spec-analyst+spec-writer→spec-writer, architect+planner→planner; all agents need frontmatter updates if skill co-location changes dispatch |
| **Command definitions** | `commands/*.md` (24 files) | CRITICAL — all commands migrated to skills; 3 pipeline commands (fix-ticket, fix-bugs, implement-feature) refactored into pipeline engine + mode adapters |
| **Skill definitions** | `skills/bug-workflow/skill.md` (1 file) | HIGH — routing skill rewritten for `/build` entry point + mode detection |
| **Plugin metadata** | `.claude-plugin/*.json` (2 files) | MEDIUM — version bump, description update, skill registry changes |
| **Tests** | `tests/scenarios/*.sh` (15 files) | HIGH — all structural validation tests must be updated for new directory layout |
| **Documentation** | `docs/**/*.md` (~10 files) | MEDIUM — architecture docs, reference docs, guides all need updates |
| **Checklists** | `checklists/*.md` (3 files) | LOW — content unchanged, paths may change |
| **Examples** | `examples/**` | LOW — config templates may need updates for new optional sections |

### Tech Debt

1. **Duplicated pipeline logic**: `fix-ticket.md`, `fix-bugs.md`, and `implement-feature.md` share ~60% identical orchestration logic (config reading, flag parsing, fixer↔reviewer loop, error handling). This is the primary motivation for extracting a shared pipeline engine.

2. **Inconsistent agent count references**: README and reference docs have had agent count discrepancies (recently fixed from 16/17 → 18).

3. **Documentation overhaul pending**: A 4-phase documentation overhaul was proposed but never started (status: PROPOSED in plans/README.md).

4. **Single routing skill**: Only one skill exists (`bug-workflow`), which is a simple intent→command router. The skill system is underutilized.

5. **No formal state management**: Commands manage pipeline state implicitly through sequential execution. The forge plugin's `.forge/` state directory with checkpoint/resume is more sophisticated.

## Confidence Scoring

| Question | Score | Reasoning |
|----------|-------|-----------|
| **Can I fully understand the task requirements?** | 0.75 | The high-level vision is clear (merge two plugins, unified `/build` command, mode detection). However, the non-code modes (analysis, strategy, content) are underspecified — how do they map to existing agents? What agents do they use? The adapter interface design is open. |
| **Can I identify all affected code areas?** | 0.90 | The repository is well-structured and fully auditable. All 152 markdown files are known. The only uncertainty is which forge plugin files need to be brought over vs. reimplemented. |
| **Can I predict likely implementation challenges?** | 0.80 | Key challenges are identifiable: backward compatibility (existing `ceos-agents:` command users), agent merge conflicts (different prompt structures), pipeline engine extraction (shared vs. mode-specific logic), test migration (all structural tests break with new layout). Unknown: how Claude Code handles skill migration at runtime, whether plugin.json schema supports the proposed structure. |
| **Composite** | **0.82** | `(0.75 + 0.90 + 0.80) / 3 = 0.817` — High confidence overall, with residual uncertainty around non-code mode design and Claude Code plugin system constraints. |

## Key Decisions for Downstream Phases

1. **Migration strategy**: The 5-phase approach (extract core → build /build → merge agents → non-code modes → deprecate old) is sound but needs detailed sequencing within each phase.

2. **Backward compatibility**: Existing commands MUST remain functional during migration (deprecation warnings, not immediate removal). The `ceos-agents:` namespace is preserved.

3. **Agent merge strategy**: Two confirmed merges (spec-analyst + forge-spec-writer → unified spec-writer; architect + forge-planner → unified planner). Other agents remain as-is but may need prompt updates.

4. **Pipeline engine design**: Must abstract the common orchestration pattern from fix-ticket/fix-bugs/implement-feature into a reusable pipeline engine that mode adapters can customize.

5. **Non-code modes**: analysis, strategy, and content modes are new territory — they need research into what pipeline phases apply and what agent roles are needed.

6. **Test strategy**: All 15 existing test scenarios will break. Need both migration of existing tests AND new tests for the unified pipeline.
