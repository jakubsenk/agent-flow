# Phase 0 Input

## User's Task Description (verbatim)

Sloučení forge + ceos-agents do jednoho univerzálního pipeline pluginu s příkazem /build.

Key points from the brief:
- Unified command: /build "task description" [--mode code|analysis|strategy|content] [--new-project] [flags...]
- Auto-detection: git repo with code → "feature" workflow (forge), no git repo → "project" workflow (scaffold)
- Mode detection: code (default for technical), analysis, strategy, content
- Unified 10-phase pipeline adapted per mode
- Project mode adds Phase -1 (stack selection + scaffold + git init)
- Shared core: pipeline-engine, review-loop, approval-gate, synthesis, state-schema, context-handoff
- Mode adapters: code-feature, code-project, analysis, strategy, content
- Commands→Skills migration (co-located prompts)
- Agent merges: forge spec-writer + ceos spec-analyst → one spec-writer, forge planner + ceos architect → one planner
- Keep ceos-agents plugin name (has existing users)
- Keep .forge/ state directory (backward compat)
- Migration phases: 1) Extract shared core, 2) Build /build skill, 3) Merge agents, 4) Non-code modes, 5) Deprecate old
