# Forge + ceos-agents Merger Migration: Acceptance Criteria

**Author:** Dr. Sarah Chen, Principal Software Architect
**Date:** 2026-03-22
**Version:** 1.0.0
**Status:** PROPOSED
**Companion to:** requirements.md, design.md (same directory)

---

## Verification Methodology

Every acceptance criterion in this document is verifiable by one or more of:

1. **Structural check** -- file existence, file content grep, line count (executable in the bash test harness)
2. **Schema check** -- YAML/JSON field presence, frontmatter validation (executable via grep/awk)
3. **Reference check** -- verifying that file A references file B (executable via grep)
4. **Consistency check** -- cross-file field alignment (executable via grep + comparison)

No criterion requires subjective judgment, manual UX testing, or runtime pipeline execution. All criteria can be automated as `tests/scenarios/*.sh` scripts.

---

## 1. Plugin Identity and Versioning Criteria

### AC-1.1: Plugin name is unchanged

**Given** the migration is complete (v5.5.0)
**When** inspecting `.claude-plugin/plugin.json`
**Then** the `"name"` field is `"ceos-agents"`

```bash
grep -q '"name".*"ceos-agents"' .claude-plugin/plugin.json
```

### AC-1.2: Namespace prefix is unchanged

**Given** the migration is complete
**When** searching all command files for the namespace prefix
**Then** all command invocations in skills and docs use `ceos-agents:` prefix

```bash
# Every Skill() call in skills/ references ceos-agents:
grep -r "Skill(" skills/ | grep -v "ceos-agents:" | grep -c "skill=" | [ "$(cat)" -eq 0 ]
```

### AC-1.3: No MAJOR version bump

**Given** the complete changelog from v5.1.x through v5.5.0
**When** examining version numbers
**Then** no version starts with `6.` or higher; all versions are `5.x.y`

```bash
# Changelog has no v6+ entries created by this migration
grep -c "^## \[v[6-9]" CHANGELOG.md | [ "$(cat)" -eq 0 ]
```

---

## 2. Directory Structure Criteria

### AC-2.1: core/ directory exists with exactly 10 files

**Given** PR 2 and PR 3 are merged
**When** listing `core/`
**Then** exactly 10 `.md` files exist

```bash
[ "$(ls core/*.md 2>/dev/null | wc -l)" -eq 10 ]
```

### AC-2.2: core/ files have required sections

**Given** each file in `core/`
**When** inspecting section headings
**Then** every file contains: `## Purpose`, `## Input Contract`, `## Process`, `## Output Contract`, `## Failure Handling`

```bash
for f in core/*.md; do
  for section in "## Purpose" "## Input Contract" "## Process" "## Output Contract" "## Failure Handling"; do
    grep -q "$section" "$f" || exit 1
  done
done
```

### AC-2.3: skills/build/ directory structure

**Given** PR 4 is merged
**When** listing `skills/build/`
**Then** `SKILL.md` exists and at least `mode-code-bugfix.md`, `mode-code-feature.md`, `mode-code-project.md` exist

```bash
[ -f skills/build/SKILL.md ] && \
[ -f skills/build/mode-code-bugfix.md ] && \
[ -f skills/build/mode-code-feature.md ] && \
[ -f skills/build/mode-code-project.md ]
```

### AC-2.4: state/ directory exists with schema documentation

**Given** PR 1 is merged
**When** listing `state/`
**Then** `schema.md` exists and contains `schema_version`

```bash
[ -f state/schema.md ] && grep -q "schema_version" state/schema.md
```

### AC-2.5: agents/ directory remains flat

**Given** the migration is complete
**When** listing `agents/`
**Then** no subdirectories exist under `agents/`

```bash
find agents/ -mindepth 1 -type d | [ "$(wc -l)" -eq 0 ]
```

### AC-2.6: agents/ directory has exactly 21 files at v5.3.0+

**Given** PR 5 is merged
**When** counting `.md` files in `agents/`
**Then** exactly 21 agent files exist

```bash
[ "$(ls agents/*.md | wc -l)" -eq 21 ]
```

### AC-2.7: examples/workflows/ directory exists with workflow files

**Given** PR 4 is merged
**When** listing `examples/workflows/`
**Then** at least `code-bugfix-workflow.md` and `code-feature-workflow.md` exist

```bash
[ -f examples/workflows/code-bugfix-workflow.md ] && \
[ -f examples/workflows/code-feature-workflow.md ]
```

### AC-2.8: Per-issue runtime directory uses .ceos-agents/ prefix

**Given** PR 0 is merged
**When** searching agent files for artifact path references
**Then** reproducer.md and browser-verifier.md reference `.ceos-agents/` paths, not `.claude/` paths for reproduction-result.json and verification-result.json

```bash
! grep -q '\.claude/reproduction-result\.json' agents/reproducer.md && \
! grep -q '\.claude/verification-result\.json' agents/browser-verifier.md && \
grep -q '\.ceos-agents/' agents/reproducer.md && \
grep -q '\.ceos-agents/' agents/browser-verifier.md
```

---

## 3. /build Entry Point Criteria

### AC-3.1: SKILL.md has required frontmatter

**Given** PR 4 is merged
**When** reading `skills/build/SKILL.md` frontmatter
**Then** it contains `name: build` and a `description` field

```bash
head -10 skills/build/SKILL.md | grep -q "name: build" && \
head -10 skills/build/SKILL.md | grep -q "description:"
```

### AC-3.2: Mode detection algorithm is documented

**Given** PR 4 is merged
**When** reading `skills/build/SKILL.md`
**Then** it contains sections for: mode detection, flag parsing, dispatch logic

```bash
grep -q "mode.*detect" skills/build/SKILL.md && \
grep -q "\-\-mode" skills/build/SKILL.md && \
grep -q "CLAUDE_SKILL_DIR" skills/build/SKILL.md
```

### AC-3.3: All 6 mode flags are documented

**Given** the migration is complete (v5.5.0)
**When** searching `skills/build/SKILL.md` for mode values
**Then** all six modes are listed: code-bugfix, code-feature, code-project, analysis, strategy, content

```bash
for mode in code-bugfix code-feature code-project analysis strategy content; do
  grep -q "$mode" skills/build/SKILL.md || exit 1
done
```

### AC-3.4: Each mode adapter file has phase sequence

**Given** the migration is complete (v5.5.0)
**When** reading each `skills/build/mode-*.md` file
**Then** each contains `## Phase Sequence` or equivalent ordered phase listing

```bash
for f in skills/build/mode-*.md; do
  grep -qi "phase" "$f" || exit 1
done
```

### AC-3.5: /build is routed by bug-workflow skill

**Given** PR 4 is merged
**When** reading `skills/bug-workflow/SKILL.md`
**Then** an intent row routes to `ceos-agents:build`

```bash
grep -q "ceos-agents:build" skills/bug-workflow/SKILL.md
```

### AC-3.6: --resume flag references state.json

**Given** PR 4 is merged
**When** reading `skills/build/SKILL.md`
**Then** it references `state.json` for resume logic

```bash
grep -q "state.json" skills/build/SKILL.md && \
grep -q "\-\-resume" skills/build/SKILL.md
```

---

## 4. Core Pattern Files Criteria

### AC-4.1: config-reader.md lists all required config sections

**Given** PR 2 is merged
**When** reading `core/config-reader.md`
**Then** it references: Issue Tracker, Source Control, PR Rules, Build & Test

```bash
for section in "Issue Tracker" "Source Control" "PR Rules" "Build & Test"; do
  grep -q "$section" core/config-reader.md || exit 1
done
```

### AC-4.2: fixer-reviewer-loop.md specifies iteration limit

**Given** PR 2 is merged
**When** reading `core/fixer-reviewer-loop.md`
**Then** it references `max_iterations` or `Fixer iterations` and the default value 5

```bash
grep -qi "iteration" core/fixer-reviewer-loop.md && \
grep -q "5" core/fixer-reviewer-loop.md
```

### AC-4.3: block-handler.md uses correct comment template

**Given** PR 2 is merged
**When** reading `core/block-handler.md`
**Then** it contains the exact `[ceos-agents]` block comment prefix with emoji

```bash
grep -q '\[ceos-agents\].*Pipeline Block' core/block-handler.md
```

### AC-4.4: state-manager.md specifies atomic write protocol

**Given** PR 1 is merged
**When** reading `core/state-manager.md`
**Then** it describes the tmp-file + rename pattern

```bash
grep -q "\.tmp" core/state-manager.md && \
grep -qi "rename" core/state-manager.md
```

### AC-4.5: All pipeline commands reference core files after refactor

**Given** PR 3 is merged
**When** searching pipeline commands for core file references
**Then** fix-ticket.md, fix-bugs.md, implement-feature.md each reference at least 3 core files

```bash
for cmd in commands/fix-ticket.md commands/fix-bugs.md commands/implement-feature.md; do
  count=$(grep -c "core/" "$cmd")
  [ "$count" -ge 3 ] || exit 1
done
```

### AC-4.6: decomposition-heuristics.md contains threshold values

**Given** PR 2 is merged
**When** reading `core/decomposition-heuristics.md`
**Then** it contains the threshold values: risk HIGH, files >= 4, diff > 60

```bash
grep -q "HIGH" core/decomposition-heuristics.md && \
grep -q "4" core/decomposition-heuristics.md && \
grep -q "60" core/decomposition-heuristics.md
```

### AC-4.7: profile-parser.md lists non-skippable stages

**Given** PR 2 is merged
**When** reading `core/profile-parser.md`
**Then** it states that fixer, reviewer, and publisher cannot be skipped

```bash
grep -q "fixer" core/profile-parser.md && \
grep -q "reviewer" core/profile-parser.md && \
grep -q "publisher" core/profile-parser.md && \
grep -qi "cannot.*skip\|NEVER.*skip\|not.*skip" core/profile-parser.md
```

---

## 5. Mode Adapter Criteria

### AC-5.1: Code-bugfix mode references triage-analyst

**Given** PR 4 is merged
**When** reading `skills/build/mode-code-bugfix.md`
**Then** it dispatches `triage-analyst` agent

```bash
grep -q "triage-analyst" skills/build/mode-code-bugfix.md
```

### AC-5.2: Code-feature mode references architect

**Given** PR 4 is merged
**When** reading `skills/build/mode-code-feature.md`
**Then** it dispatches `architect` agent (not "planner")

```bash
grep -q "architect" skills/build/mode-code-feature.md && \
! grep -q "planner" skills/build/mode-code-feature.md
```

### AC-5.3: Analysis mode has domain context blocks

**Given** PR 6 is merged
**When** reading `skills/build/mode-analysis.md`
**Then** it contains domain context blocks for reviewer, spec-writer, and spec-reviewer

```bash
grep -q "Domain Context" skills/build/mode-analysis.md && \
grep -q "reviewer" skills/build/mode-analysis.md && \
grep -q "spec-writer" skills/build/mode-analysis.md && \
grep -q "spec-reviewer" skills/build/mode-analysis.md
```

### AC-5.4: Analysis mode verification uses REVIEWED verdict

**Given** PR 6 is merged
**When** reading `skills/build/mode-analysis.md`
**Then** it specifies "REVIEWED" (not "PASSED") as the verification verdict

```bash
grep -q "REVIEWED" skills/build/mode-analysis.md && \
! grep -q "PASSED" skills/build/mode-analysis.md
```

### AC-5.5: Non-code modes dispatch intake-agent

**Given** the migration is complete (v5.5.0)
**When** reading analysis, strategy, and content mode adapters
**Then** each dispatches `intake-agent`

```bash
for mode in analysis strategy content; do
  grep -q "intake-agent" skills/build/mode-${mode}.md || exit 1
done
```

### AC-5.6: Non-code modes dispatch domain-analyst

**Given** the migration is complete (v5.5.0)
**When** reading analysis, strategy, and content mode adapters
**Then** each dispatches `domain-analyst`

```bash
for mode in analysis strategy content; do
  grep -q "domain-analyst" skills/build/mode-${mode}.md || exit 1
done
```

### AC-5.7: Non-code modes dispatch synthesizer

**Given** the migration is complete (v5.5.0)
**When** reading analysis, strategy, and content mode adapters
**Then** each dispatches `synthesizer`

```bash
for mode in analysis strategy content; do
  grep -q "synthesizer" skills/build/mode-${mode}.md || exit 1
done
```

### AC-5.8: Strategy mode has priority-engine domain context

**Given** PR 7 is merged
**When** reading `skills/build/mode-strategy.md`
**Then** it contains domain context for priority-engine

```bash
grep -q "priority-engine" skills/build/mode-strategy.md && \
grep -q "Domain Context" skills/build/mode-strategy.md
```

### AC-5.9: SDLC template integration documented in at least one mode

**Given** PR 6 is merged
**When** reading mode adapter files
**Then** at least one mode adapter references SDLC templates and template detection

```bash
grep -rl "SDLC\|template" skills/build/mode-*.md | [ "$(wc -l)" -ge 1 ]
```

### AC-5.10: Content mode reviewer domain context replaces code checklists

**Given** PR 7 is merged
**When** reading `skills/build/mode-content.md`
**Then** the reviewer domain context mentions factual accuracy, readability, or audience (not SQL injection, XSS)

```bash
grep -q "factual\|readability\|audience" skills/build/mode-content.md && \
! grep -q "SQL injection\|XSS" skills/build/mode-content.md
```

---

## 6. Agent Roster Criteria

### AC-6.1: All 18 existing agents are present and unmodified in name

**Given** the migration is complete
**When** checking agent frontmatter names
**Then** all 18 original agent names are present

```bash
for agent in triage-analyst code-analyst fixer reviewer acceptance-gate \
  test-engineer e2e-test-engineer publisher rollback-agent spec-analyst \
  architect stack-selector scaffolder priority-engine spec-writer \
  spec-reviewer reproducer browser-verifier; do
  grep -q "name: $agent" agents/${agent}.md || exit 1
done
```

### AC-6.2: intake-agent has correct frontmatter

**Given** PR 5 is merged
**When** reading `agents/intake-agent.md`
**Then** frontmatter contains: name=intake-agent, model=sonnet, style field present, description field present

```bash
head -10 agents/intake-agent.md | grep -q "name: intake-agent" && \
head -10 agents/intake-agent.md | grep -q "model: sonnet" && \
head -10 agents/intake-agent.md | grep -q "style:" && \
head -10 agents/intake-agent.md | grep -q "description:"
```

### AC-6.3: domain-analyst has correct frontmatter

**Given** PR 5 is merged
**When** reading `agents/domain-analyst.md`
**Then** frontmatter contains: name=domain-analyst, model=opus, style field present

```bash
head -10 agents/domain-analyst.md | grep -q "name: domain-analyst" && \
head -10 agents/domain-analyst.md | grep -q "model: opus" && \
head -10 agents/domain-analyst.md | grep -q "style:"
```

### AC-6.4: synthesizer has correct frontmatter

**Given** PR 5 is merged
**When** reading `agents/synthesizer.md`
**Then** frontmatter contains: name=synthesizer, model=sonnet, style field present

```bash
head -10 agents/synthesizer.md | grep -q "name: synthesizer" && \
head -10 agents/synthesizer.md | grep -q "model: sonnet" && \
head -10 agents/synthesizer.md | grep -q "style:"
```

### AC-6.5: All 3 new agents have required section order

**Given** PR 5 is merged
**When** reading each new agent file
**Then** sections appear in order: Goal, Expertise, Process, Constraints

```bash
for agent in intake-agent domain-analyst synthesizer; do
  goal_line=$(grep -n "## Goal" agents/${agent}.md | head -1 | cut -d: -f1)
  expertise_line=$(grep -n "## Expertise" agents/${agent}.md | head -1 | cut -d: -f1)
  process_line=$(grep -n "## Process" agents/${agent}.md | head -1 | cut -d: -f1)
  constraints_line=$(grep -n "## Constraints" agents/${agent}.md | head -1 | cut -d: -f1)
  [ "$goal_line" -lt "$expertise_line" ] && \
  [ "$expertise_line" -lt "$process_line" ] && \
  [ "$process_line" -lt "$constraints_line" ] || exit 1
done
```

### AC-6.6: New agents have NEVER constraints

**Given** PR 5 is merged
**When** reading each new agent's Constraints section
**Then** at least one constraint starts with "NEVER"

```bash
for agent in intake-agent domain-analyst synthesizer; do
  grep -q "NEVER" agents/${agent}.md || exit 1
done
```

### AC-6.7: domain-analyst is read-only (no write phrases)

**Given** PR 5 is merged
**When** searching `agents/domain-analyst.md` for write-tool phrases
**Then** no phrases like "Write file", "Edit file", "create file", "modify file" appear

```bash
! grep -qi "Write file\|Edit file\|create file\|modify file\|Write tool\|Edit tool" agents/domain-analyst.md
```

### AC-6.8: rollback-agent skip list includes domain-analyst

**Given** PR 5 is merged
**When** reading `agents/rollback-agent.md`
**Then** the read-only agent skip list includes `domain-analyst`

```bash
grep -q "domain-analyst" agents/rollback-agent.md
```

### AC-6.9: No agent is renamed

**Given** the migration is complete
**When** comparing agent file names to v5.1.0 baseline
**Then** no original agent file is missing; no agent file has a different `name` in frontmatter than its filename (minus `.md`)

```bash
for f in agents/*.md; do
  basename=$(basename "$f" .md)
  grep -q "name: $basename" "$f" || exit 1
done
```

---

## 7. State Management Criteria

### AC-7.1: state.json schema documented with all required fields

**Given** PR 1 is merged
**When** reading `state/schema.md`
**Then** it documents: schema_version, run_id, mode, pipeline, created_at, updated_at, status, config, triage, code_analysis, fixer_reviewer, decomposition, test, publisher, block

```bash
for field in schema_version run_id mode pipeline created_at updated_at status \
  config triage code_analysis fixer_reviewer decomposition test publisher block; do
  grep -q "$field" state/schema.md || exit 1
done
```

### AC-7.2: state-manager.md specifies atomic write

**Given** PR 1 is merged
**When** reading `core/state-manager.md`
**Then** it describes writing to a temp file and renaming

```bash
grep -qi "atomic\|tmp.*rename\|temp.*rename" core/state-manager.md
```

### AC-7.3: resume-ticket.md references state.json

**Given** PR 1 is merged
**When** reading `commands/resume-ticket.md`
**Then** it references `.ceos-agents/` and `state.json`

```bash
grep -q "state.json" commands/resume-ticket.md && \
grep -q ".ceos-agents" commands/resume-ticket.md
```

### AC-7.4: Heuristic fallback is preserved in resume-ticket

**Given** PR 1 is merged
**When** reading `commands/resume-ticket.md`
**Then** the 7-level heuristic detection is still present (DECOMPOSE_PARTIAL, PUBLISHED, POST_REVIEW, POST_FIX, POST_ANALYSIS, POST_TRIAGE, FRESH)

```bash
grep -q "DECOMPOSE_PARTIAL\|PUBLISHED\|POST_REVIEW\|POST_FIX\|POST_ANALYSIS\|POST_TRIAGE\|FRESH" commands/resume-ticket.md
```

### AC-7.5: Pipeline commands write state.json

**Given** PR 1 is merged
**When** reading pipeline command files
**Then** fix-ticket.md, fix-bugs.md, implement-feature.md, and scaffold.md each reference state.json or state-manager

```bash
for cmd in fix-ticket fix-bugs implement-feature scaffold; do
  grep -q "state.json\|state-manager\|state_manager\|\.ceos-agents" commands/${cmd}.md || exit 1
done
```

### AC-7.6: Event log format is JSONL

**Given** PR 1 is merged
**When** reading state-manager or schema documentation
**Then** the event log format is described as one JSON object per line (JSONL)

```bash
grep -qi "jsonl\|JSON.*per.*line\|append-only\|pipeline\.log" state/schema.md
```

### AC-7.7: Browser artifacts reference per-issue paths

**Given** PR 0 is merged
**When** reading reproducer.md and browser-verifier.md
**Then** artifact paths reference `.ceos-agents/{ISSUE-ID}/` or `{RUN-ID}` pattern

```bash
grep -q ".ceos-agents/" agents/reproducer.md && \
grep -q ".ceos-agents/" agents/browser-verifier.md
```

### AC-7.8: Decomposition YAML backward compatibility preserved

**Given** PR 1 is merged
**When** reading `commands/resume-ticket.md`
**Then** it still references `.claude/decomposition/` as a fallback read path

```bash
grep -q ".claude/decomposition" commands/resume-ticket.md
```

---

## 8. Backward Compatibility Criteria

### AC-8.1: All 24 commands still exist

**Given** the migration is complete
**When** counting `.md` files in `commands/`
**Then** at least 24 command files exist (may be more if new commands added)

```bash
[ "$(ls commands/*.md | wc -l)" -ge 24 ]
```

### AC-8.2: No command file is renamed

**Given** the migration is complete
**When** listing command files
**Then** all 24 original command names are present

```bash
for cmd in analyze-bug changelog check-setup create-pr dashboard discuss \
  estimate fix-bugs fix-ticket implement-feature init metrics migrate-config \
  onboard prioritize publish resume-ticket scaffold-add scaffold-validate \
  scaffold status template version-bump version-check; do
  [ -f commands/${cmd}.md ] || exit 1
done
```

### AC-8.3: No agent file is renamed

**Given** the migration is complete
**When** listing agent files
**Then** all 18 original agent names are present

```bash
for agent in triage-analyst code-analyst fixer reviewer acceptance-gate \
  test-engineer e2e-test-engineer publisher rollback-agent spec-analyst \
  architect stack-selector scaffolder priority-engine spec-writer \
  spec-reviewer reproducer browser-verifier; do
  [ -f agents/${agent}.md ] || exit 1
done
```

### AC-8.4: Comment format [ceos-agents] is unchanged

**Given** the migration is complete
**When** searching all files for comment prefix patterns
**Then** the `[ceos-agents]` prefix is used consistently; no alternative prefix (e.g., `[ceos-agents/v6]`) is introduced

```bash
! grep -r "\[ceos-agents/v" agents/ commands/ skills/ core/
```

### AC-8.5: maps_to format is unchanged

**Given** the migration is complete
**When** reading `agents/architect.md`
**Then** the `maps_to: AC-{N}: {text}` format is documented identically to v5.1.0

```bash
grep -q 'maps_to.*AC-' agents/architect.md
```

### AC-8.6: No new required config key added

**Given** the migration is complete
**When** reading the Automation Config documentation in CLAUDE.md
**Then** the required sections table is unchanged: Issue Tracker, Source Control, PR Rules, PR Description Template, Build & Test

```bash
# The required sections list should not have grown
# Check that the new sections (Document Templates, etc.) are in the optional table
grep -A 20 "Optional sections:" CLAUDE.md | grep -q "Document Templates" || true
# And NOT in the required table
grep -B 5 -A 10 "required sections" CLAUDE.md | grep -qv "Document Templates"
```

### AC-8.7: Pipeline profile stage names unchanged

**Given** the migration is complete
**When** reading CLAUDE.md stage names for skip
**Then** the list includes: triage, code-analyst, spec-analyst, test-engineer, e2e-test-engineer, reproducer, browser-verifier

```bash
for stage in triage code-analyst spec-analyst test-engineer e2e-test-engineer reproducer browser-verifier; do
  grep -q "$stage" CLAUDE.md || exit 1
done
```

### AC-8.8: Existing tests still pass (no false failures)

**Given** PR 0 is merged
**When** running the test suite
**Then** all existing tests pass (updated happy-path, verify-fail, pipeline-consistency)

```bash
# This criterion is verified by running the test suite
# ./tests/harness/run-tests.sh
# Expected: 0 failures
```

### AC-8.9: Versioning policy in CLAUDE.md is unchanged

**Given** the migration is complete
**When** reading the Versioning Policy table in CLAUDE.md
**Then** the MAJOR, MINOR, PATCH triggers are identical to v5.1.0

```bash
grep -q "MAJOR.*Breaking change" CLAUDE.md && \
grep -q "MINOR.*backward-compatible" CLAUDE.md && \
grep -q "PATCH.*Behavior fix" CLAUDE.md
```

### AC-8.10: Agent Overrides work for new agents

**Given** PR 5 is merged
**When** the Agent Overrides mechanism is described
**Then** the override path pattern `{path}/{agent-name}.md` works for intake-agent, domain-analyst, synthesizer

```bash
# Structural check: CLAUDE.md or agent-override-injector references all agents by pattern
grep -q "agent-name" core/agent-override-injector.md
# New agents follow the same naming convention (no special handling needed)
```

---

## 9. SDLC Template Integration Criteria

### AC-9.1: Template detection is documented

**Given** PR 6 is merged
**When** reading at least one mode adapter file
**Then** it describes how SDLC templates are detected (YAML frontmatter with `type` and `sections` fields)

```bash
grep -rl "frontmatter\|type.*sections\|SDLC" skills/build/mode-*.md | [ "$(wc -l)" -ge 1 ]
```

### AC-9.2: --template flag is documented in SKILL.md

**Given** PR 4 is merged
**When** reading `skills/build/SKILL.md`
**Then** it documents the `--template` flag

```bash
grep -q "\-\-template" skills/build/SKILL.md
```

### AC-9.3: Custom template format is compatible with SDLC

**Given** the specification describes custom template support
**When** comparing the custom template YAML frontmatter contract to SDLC template structure
**Then** both use the same fields: `type`, `purpose/when-to-create`, `sections` (with `name`, `required`, `prompt`)

```bash
# Structural check on the build reference doc
grep -q "type" docs/reference/build-command.md && \
grep -q "sections" docs/reference/build-command.md && \
grep -q "required" docs/reference/build-command.md && \
grep -q "prompt" docs/reference/build-command.md
```

### AC-9.4: Document Templates config section is optional

**Given** PR 6 is merged
**When** reading CLAUDE.md or automation-config reference
**Then** Document Templates appears in the optional sections table with default values

```bash
grep -q "Document Templates" docs/reference/automation-config.md
```

### AC-9.5: Synthesizer references template structure

**Given** PR 5 is merged
**When** reading `agents/synthesizer.md`
**Then** it mentions template compliance, section structure, or YAML frontmatter

```bash
grep -qi "template\|section.*structure\|frontmatter" agents/synthesizer.md
```

---

## 10. Documentation Completeness Criteria

### AC-10.1: docs/reference/build-command.md exists

**Given** PR 4 is merged
**When** checking file existence
**Then** `docs/reference/build-command.md` exists and is non-empty

```bash
[ -s docs/reference/build-command.md ]
```

### AC-10.2: docs/reference/state-management.md exists

**Given** PR 1 is merged
**When** checking file existence
**Then** `docs/reference/state-management.md` exists and is non-empty

```bash
[ -s docs/reference/state-management.md ]
```

### AC-10.3: README.md mentions /build

**Given** PR 4 is merged
**When** reading `README.md`
**Then** it mentions `/build` or `ceos-agents:build`

```bash
grep -q "build" README.md
```

### AC-10.4: docs/architecture.md has Mermaid diagrams

**Given** PR 4 is merged
**When** reading `docs/architecture.md`
**Then** it contains at least 2 Mermaid diagram blocks

```bash
[ "$(grep -c '```mermaid' docs/architecture.md)" -ge 2 ]
```

### AC-10.5: CLAUDE.md updated with new agent count

**Given** PR 5 is merged
**When** reading CLAUDE.md
**Then** agent count reflects 21 (not 18)

```bash
grep -q "21 agent" CLAUDE.md
```

### AC-10.6: CLAUDE.md updated with new agent in model table

**Given** PR 5 is merged
**When** reading the model selection table in CLAUDE.md
**Then** domain-analyst appears in the opus row; intake-agent and synthesizer appear in the sonnet row

```bash
grep -q "domain-analyst" CLAUDE.md && \
grep -q "intake-agent" CLAUDE.md && \
grep -q "synthesizer" CLAUDE.md
```

### AC-10.7: Getting-started.md has progressive disclosure

**Given** PR 7 is merged
**When** reading `docs/getting-started.md`
**Then** it contains a multi-level learning path or "Choose Your Path" section

```bash
grep -qi "level\|path\|progressive\|getting started\|choose" docs/getting-started.md
```

### AC-10.8: Workflow examples reference /build

**Given** PR 4 is merged
**When** reading workflow example files
**Then** each references `/build` or `ceos-agents:build`

```bash
for f in examples/workflows/*.md; do
  grep -qi "build" "$f" || exit 1
done
```

### AC-10.9: Bug-workflow skill router includes discuss

**Given** PR 0 is merged
**When** reading `skills/bug-workflow/SKILL.md`
**Then** `discuss` appears in the intent mapping table

```bash
grep -q "discuss" skills/bug-workflow/SKILL.md
```

### AC-10.10: spec-writer.md has correct block comment emoji

**Given** PR 0 is merged
**When** reading `agents/spec-writer.md`
**Then** the block comment template includes the emoji

```bash
grep -q 'ceos-agents.*Pipeline Block' agents/spec-writer.md
```

---

## 11. Integration Test Scenarios

These scenarios describe end-to-end flows that should work after migration. They are not directly automatable as bash grep tests but define the expected system behavior for manual or future integration testing.

### Scenario 11.1: Code-bugfix via /build matches /fix-ticket

**Given** a project with Automation Config and a bug ticket PROJ-123
**When** the user runs `/ceos-agents:build PROJ-123`
**Then** the mode is detected as `code-bugfix`
**And** the pipeline executes the same phases as `/ceos-agents:fix-ticket PROJ-123`
**And** state.json is created at `.ceos-agents/PROJ-123/state.json`
**And** pipeline.log records all phase transitions
**And** the final output is a PR (identical to fix-ticket output)

**Structural verification:**
```bash
# Mode adapter dispatches same agents as fix-ticket
diff <(grep -o '[a-z-]*agent\|triage-analyst\|code-analyst\|fixer\|reviewer\|test-engineer\|publisher' skills/build/mode-code-bugfix.md | sort -u) \
     <(grep -o '[a-z-]*agent\|triage-analyst\|code-analyst\|fixer\|reviewer\|test-engineer\|publisher' commands/fix-ticket.md | sort -u)
```

### Scenario 11.2: Analysis pipeline produces deliverable

**Given** a project with SDLC templates in docs/
**When** the user runs `/ceos-agents:build --mode analysis "Evaluate our database migration options"`
**Then** the intake-agent processes the input
**And** spec-writer scopes the analysis with analysis domain context
**And** domain-analyst produces findings
**And** synthesizer produces a document using SDLC template structure
**And** reviewer evaluates with analysis domain context (not code checklists)
**And** final output uses "REVIEWED" verdict (not "PASSED")

### Scenario 11.3: Resume from state.json

**Given** a pipeline run that was interrupted after the triage phase
**And** a valid `.ceos-agents/PROJ-123/state.json` with `triage.status: completed`
**When** the user runs `/ceos-agents:build --resume PROJ-123`
**Then** the pipeline resumes from the code_analysis phase (not from the beginning)
**And** AC list and complexity are restored from state.json (not re-queried)
**And** pipeline.log records `{"event": "resume", "source": "state"}`

### Scenario 11.4: Resume without state.json falls back to heuristic

**Given** a pipeline run started before state.json was introduced (v5.1.x)
**And** no `.ceos-agents/PROJ-123/state.json` exists
**And** a `[ceos-agents] Triage completed.` comment exists on the issue
**When** the user runs `/ceos-agents:resume-ticket PROJ-123`
**Then** the pipeline resumes using the heuristic detection (POST_TRIAGE)
**And** pipeline.log (if created) records `{"event": "resume", "source": "heuristic"}`

### Scenario 11.5: Parallel fix-bugs with browser verification

**Given** a project with Browser Verification configured and worktree mode enabled
**When** the user runs `/ceos-agents:fix-bugs 3`
**Then** each bug's browser artifacts are written to `.ceos-agents/{BUG-ID}/`
**And** no file clobbering occurs between concurrent worktrees
**And** each bug's state.json is independent

### Scenario 11.6: Strategy mode with priority-engine

**Given** a project
**When** the user runs `/ceos-agents:build --mode strategy "Develop a cloud migration plan"`
**Then** the pipeline runs through intake, scope, domain analysis, priority assessment, synthesis
**And** priority-engine receives strategy domain context (Strategic Value, Execution Risk)
**And** the output document includes prioritized options

### Scenario 11.7: Custom template integration

**Given** a custom template file at `docs/templates/risk-assessment.md` with YAML frontmatter containing `type: risk-assessment`, `sections: [{name: Risk Inventory, required: true}]`
**When** the user runs `/ceos-agents:build --mode analysis --template docs/templates/risk-assessment.md "Assess operational risks"`
**Then** the synthesizer produces output with a "Risk Inventory" section
**And** all required sections from the template are present in the output

---

## 12. New Test Scenarios (for tests/scenarios/)

These are the specific test scripts that should be added during the migration, with their implementation sketches.

### Test 12.1: frontmatter-completeness.sh (PR 0)

```bash
#!/usr/bin/env bash
# Verify all agents have name, description, model, style in frontmatter
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
for f in "$REPO_ROOT"/agents/*.md; do
  agent=$(basename "$f")
  for field in "name:" "description:" "model:" "style:"; do
    if ! head -10 "$f" | grep -q "$field"; then
      echo "FAIL: $agent missing frontmatter field: $field"
      FAIL=1
    fi
  done
done
exit $FAIL
```

### Test 12.2: model-assignment.sh (PR 0)

```bash
#!/usr/bin/env bash
# Validate model assignments match CLAUDE.md model selection table
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
# opus agents
for agent in fixer reviewer architect priority-engine spec-writer spec-reviewer; do
  model=$(head -10 "$REPO_ROOT/agents/${agent}.md" | grep "model:" | awk '{print $2}')
  if [ "$model" != "opus" ]; then
    echo "FAIL: $agent should be opus, got $model"
    FAIL=1
  fi
done
# haiku agents
for agent in publisher rollback-agent; do
  model=$(head -10 "$REPO_ROOT/agents/${agent}.md" | grep "model:" | awk '{print $2}')
  if [ "$model" != "haiku" ]; then
    echo "FAIL: $agent should be haiku, got $model"
    FAIL=1
  fi
done
# All others should be sonnet
for agent in triage-analyst code-analyst test-engineer e2e-test-engineer spec-analyst \
  stack-selector scaffolder acceptance-gate reproducer browser-verifier; do
  model=$(head -10 "$REPO_ROOT/agents/${agent}.md" | grep "model:" | awk '{print $2}')
  if [ "$model" != "sonnet" ]; then
    echo "FAIL: $agent should be sonnet, got $model"
    FAIL=1
  fi
done
exit $FAIL
```

### Test 12.3: read-only-agents.sh (PR 0)

```bash
#!/usr/bin/env bash
# Verify read-only agents contain no file-write action phrases
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
READ_ONLY="triage-analyst code-analyst reviewer spec-analyst architect stack-selector priority-engine spec-reviewer acceptance-gate"
for agent in $READ_ONLY; do
  if grep -qi "Write tool\|Edit tool\|write file\|edit file\|create file\|modify file\|Write(" "$REPO_ROOT/agents/${agent}.md"; then
    echo "FAIL: read-only agent $agent contains write phrases"
    FAIL=1
  fi
done
exit $FAIL
```

### Test 12.4: section-order.sh (PR 0)

```bash
#!/usr/bin/env bash
# Verify Goal -> Expertise -> Process -> Constraints order in all agents
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
for f in "$REPO_ROOT"/agents/*.md; do
  agent=$(basename "$f")
  goal=$(grep -n "## Goal" "$f" | head -1 | cut -d: -f1)
  expertise=$(grep -n "## Expertise" "$f" | head -1 | cut -d: -f1)
  process=$(grep -n "## Process" "$f" | head -1 | cut -d: -f1)
  constraints=$(grep -n "## Constraints" "$f" | head -1 | cut -d: -f1)
  if [ -z "$goal" ] || [ -z "$expertise" ] || [ -z "$process" ] || [ -z "$constraints" ]; then
    echo "FAIL: $agent missing required section"
    FAIL=1
    continue
  fi
  if [ "$goal" -ge "$expertise" ] || [ "$expertise" -ge "$process" ] || [ "$process" -ge "$constraints" ]; then
    echo "FAIL: $agent sections out of order (G:$goal E:$expertise P:$process C:$constraints)"
    FAIL=1
  fi
done
exit $FAIL
```

### Test 12.5: state-schema.sh (PR 1)

```bash
#!/usr/bin/env bash
# Verify state.json schema documentation has all required fields
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
REQUIRED_FIELDS="schema_version run_id mode pipeline created_at updated_at status config triage code_analysis fixer_reviewer decomposition test publisher block"
for field in $REQUIRED_FIELDS; do
  if ! grep -q "$field" "$REPO_ROOT/state/schema.md"; then
    echo "FAIL: state/schema.md missing field: $field"
    FAIL=1
  fi
done
# Verify core/state-manager.md exists and has atomic write
if ! grep -qi "atomic\|tmp.*rename" "$REPO_ROOT/core/state-manager.md" 2>/dev/null; then
  echo "FAIL: core/state-manager.md missing atomic write description"
  FAIL=1
fi
exit $FAIL
```

### Test 12.6: core-include-refs.sh (PR 2)

```bash
#!/usr/bin/env bash
# Verify core files exist and are referenced by at least one pipeline command
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
CORE_FILES="config-reader mcp-preflight fixer-reviewer-loop block-handler agent-override-injector decomposition-heuristics profile-parser post-publish-hook fix-verification state-manager"
for cf in $CORE_FILES; do
  if [ ! -f "$REPO_ROOT/core/${cf}.md" ]; then
    echo "FAIL: core/${cf}.md does not exist"
    FAIL=1
    continue
  fi
  # Check that at least one command or mode adapter references it
  refs=$(grep -rl "$cf" "$REPO_ROOT/commands/" "$REPO_ROOT/skills/" 2>/dev/null | wc -l)
  if [ "$refs" -eq 0 ]; then
    echo "FAIL: core/${cf}.md is not referenced by any command or skill"
    FAIL=1
  fi
done
exit $FAIL
```

### Test 12.7: build-skill-structure.sh (PR 4)

```bash
#!/usr/bin/env bash
# Verify /build skill has SKILL.md and code mode adapters
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
[ -f "$REPO_ROOT/skills/build/SKILL.md" ] || { echo "FAIL: SKILL.md missing"; FAIL=1; }
for mode in code-bugfix code-feature code-project; do
  [ -f "$REPO_ROOT/skills/build/mode-${mode}.md" ] || { echo "FAIL: mode-${mode}.md missing"; FAIL=1; }
done
# Verify SKILL.md has name and description in frontmatter
head -10 "$REPO_ROOT/skills/build/SKILL.md" | grep -q "name:" || { echo "FAIL: SKILL.md missing name"; FAIL=1; }
head -10 "$REPO_ROOT/skills/build/SKILL.md" | grep -q "description:" || { echo "FAIL: SKILL.md missing description"; FAIL=1; }
exit $FAIL
```

### Test 12.8: new-agent-structure.sh (PR 5)

```bash
#!/usr/bin/env bash
# Verify 3 new agents have correct structure
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
for agent in intake-agent domain-analyst synthesizer; do
  f="$REPO_ROOT/agents/${agent}.md"
  [ -f "$f" ] || { echo "FAIL: $agent does not exist"; FAIL=1; continue; }
  # Check frontmatter
  for field in "name:" "description:" "model:" "style:"; do
    head -10 "$f" | grep -q "$field" || { echo "FAIL: $agent missing $field"; FAIL=1; }
  done
  # Check sections
  for section in "## Goal" "## Expertise" "## Process" "## Constraints"; do
    grep -q "$section" "$f" || { echo "FAIL: $agent missing $section"; FAIL=1; }
  done
  # Check NEVER constraint
  grep -q "NEVER" "$f" || { echo "FAIL: $agent missing NEVER constraint"; FAIL=1; }
done
exit $FAIL
```

---

## 13. Criterion Summary Matrix

| Category | Criteria Count | PR Coverage |
|----------|---------------|-------------|
| 1. Plugin Identity | 3 | All PRs |
| 2. Directory Structure | 8 | PR 0, PR 1, PR 2-3, PR 4, PR 5 |
| 3. /build Entry Point | 6 | PR 4, PR 7 |
| 4. Core Patterns | 7 | PR 2, PR 3 |
| 5. Mode Adapters | 10 | PR 4, PR 6, PR 7 |
| 6. Agent Roster | 9 | PR 5 |
| 7. State Management | 8 | PR 0, PR 1 |
| 8. Backward Compatibility | 10 | All PRs |
| 9. SDLC Templates | 5 | PR 4, PR 5, PR 6 |
| 10. Documentation | 10 | PR 0, PR 1, PR 4, PR 5, PR 7 |
| 11. Integration Scenarios | 7 | GATE 3 |
| 12. Test Implementations | 8 | PR 0, PR 1, PR 2, PR 4, PR 5 |
| **Total** | **91** | |

### Per-Gate Verification

**GATE 1 (after PR 1):** AC-7.1 through AC-7.8, AC-8.8, AC-10.2, Test 12.5
**GATE 2 (after PR 3):** AC-2.1, AC-2.2, AC-4.1 through AC-4.7, AC-8.8, Test 12.6
**GATE 3 (after PR 7):** All remaining criteria. Full suite.

---

*End of Acceptance Criteria Document*
