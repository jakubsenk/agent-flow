# Phase 1: Research Questions — Synthesis

## Item 1: Prompt Injection Protection (D2)

### RQ-1: What is the exact injection surface for each of the 5 pipeline skills that read from trackers?
**Target files:** `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/resume-ticket/SKILL.md`, `skills/scaffold/SKILL.md`
**What to look for:** At which step does each skill fetch issue content via MCP? What data fields are extracted (title, description, comments, custom fields)? Is there any wrapper or trust-boundary annotation before passing to agents?
**Why it matters:** Determines WHERE the sanitizer wrapping must be inserted in each skill.

### RQ-2: How does external content propagate from triage-analyst through the pipeline to downstream agents?
**Target files:** `agents/triage-analyst.md` (Process step 1), `skills/fix-ticket/SKILL.md` (Steps 3, 5, 7), `agents/fixer.md`, `agents/reviewer.md`
**What to look for:** Triage-analyst reads raw issue data and outputs structured AC, severity, complexity. Skills then interpolate AC literally into fixer/reviewer context strings. Is there any escaping or reframing?
**Why it matters:** AC propagation is the primary vector — injected instructions in AC reach the code-writing agents (fixer) and quality gate (reviewer).

### RQ-3: Does resume-ticket make control-flow decisions based on unverified issue tracker comments?
**Target files:** `skills/resume-ticket/SKILL.md` (Heuristic Detection), `agents/triage-analyst.md` (Step 10)
**What to look for:** Comment prefix matching (`[ceos-agents]`), pipeline type detection from comment content, block comment parsing. Is there authenticity verification?
**Why it matters:** An attacker posting comments could manipulate pipeline skip/resume behavior.

### RQ-4: How does implement-feature pass raw issue content to spec-analyst, including the --description two-stage path?
**Target files:** `skills/implement-feature/SKILL.md` (Steps 0c, 3), `agents/spec-analyst.md`
**What to look for:** Raw issue content passed as "issue details", --description text stored then re-read. Spec-analyst output (AC) flows to architect and fixer.
**Why it matters:** Two-stage injection path where developer-pasted content reaches spec-analyst unsanitized.

### RQ-5: What is the exact core contract structure pattern to follow for the new external-input-sanitizer?
**Target files:** `core/config-reader.md`, `core/block-handler.md`, `core/mcp-preflight.md`
**What to look for:** Five-section structure (Purpose, Input Contract, Process, Output Contract, Failure Handling), delegation pattern via `Follow core/X.md`.
**Why it matters:** New contract must match canonical structure exactly.

### RQ-6: What existing Constraints patterns do agents use, and do any mention external content handling?
**Target files:** All 5 target agents' `## Constraints` sections
**What to look for:** NEVER rule format, existing trust boundary mentions, pattern for adding new constraints.
**Why it matters:** The new NEVER constraint must follow the existing style and not conflict with other constraints.

## Item 2: Plugin Version Tracking (D12)

### RQ-7: Where should plugin_version live in state.json, and what precedent does schema_version set?
**Target files:** `state/schema.md`, `core/state-manager.md` (Write Process step 2)
**What to look for:** schema_version is top-level alongside run_id, issue_id etc. State init doesn't read any external metadata today. plugin.json version = "6.6.0" (semver string).
**Why it matters:** Clean precedent for top-level field; must define read step explicitly since no skill currently reads plugin.json.

### RQ-8: How does resume-ticket's state-file detection work and where should version comparison be inserted?
**Target files:** `skills/resume-ticket/SKILL.md` (State File Detection — Priority 0, steps 1-5)
**What to look for:** Currently reads 5 specific fields. Version check must go before step 4 (Pass resume_point). Heuristic fallback (no state.json) naturally skips version check.
**Why it matters:** Version comparison must not restructure existing detection logic.

## Testing

### RQ-9: How do xref-core-registry.sh and core-include-refs.sh validate core files and references?
**Target files:** `tests/scenarios/xref-core-registry.sh`, `tests/scenarios/core-include-refs.sh`
**What to look for:** Dynamic count (xref) vs hardcoded array (include-refs). CLAUDE.md count extraction. Minimum reference count thresholds per skill.
**Why it matters:** New core file must satisfy both tests. CLAUDE.md count 13→14. core-include-refs.sh array may need extension.

### RQ-10: What test patterns exist for validating agent Constraints sections?
**Target files:** `tests/scenarios/section-order.sh`, `tests/scenarios/read-only-agents.sh`, `tests/scenarios/frontmatter-completeness.sh`
**What to look for:** No existing test scans Constraints content. read-only-agents.sh only checks Process section. New test must fill the gap.
**Why it matters:** AC-E test scenario must validate NEVER constraint presence in 5 specific agents.

### RQ-11: How does state-schema.sh validate the schema, and what must change for plugin_version?
**Target files:** `tests/scenarios/state-schema.sh`, `state/schema.md`
**What to look for:** How field presence is validated — string grep, JSON parsing, or section headings only.
**Why it matters:** Determines whether test needs updating alongside the schema.
