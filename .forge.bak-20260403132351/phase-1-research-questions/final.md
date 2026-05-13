# Phase 1: Research Questions — Synthesis

## RQ-1: YouTrack Sub-Issue Parent Parameter via MCP

**Finding:** `docs/reference/trackers.md` specifies `parent: {issue-id}` for YouTrack. Step 4e in scaffold says: "create sub-issue with parent set to epic issue ID using the tracker's native parent parameter". The instruction delegates to the reference table but does NOT hardcode the parameter name in the Step 4e text itself. This means the LLM executing Step 4e must look up the parameter name from `docs/reference/trackers.md` — which it may or may not do reliably.

**Root cause confirmed:** The instruction is too indirect. The LLM may create a regular issue and only mention the epic in the description text, rather than passing the `parent` MCP parameter. The fix should hardcode the parameter name inline in Step 4e for each tracker type, or at minimum provide an explicit example.

## RQ-2: YouTrack Cascade Close Behavior

**Finding:** Step 8b explicitly says: "For trackers with native sub-issues (YouTrack, Jira, Linear, Redmine): closing the parent epic typically cascades to children. Do NOT explicitly close story sub-issues." The word "typically" is wrong — YouTrack does NOT cascade-close children. Neither do most other trackers by default.

**Root cause confirmed:** The cascade assumption is factually incorrect. ALL story issues must be explicitly closed regardless of tracker type.

## RQ-3: Existing Implementation Comment Patterns

**Finding:** Neither fix-ticket nor implement-feature post an implementation summary comment. The only tracker comments are:
1. Block comments (`[ceos-agents] 🔴 Pipeline Block`) — on failure
2. Verification comments (optional, post-merge) — in `core/fix-verification.md`
3. PR link comment — publisher adds PR URL as a comment (unstructured)

The scaffold pipeline has NO PR creation (features are committed directly to main), so there's no PR-link comment either. A new "implementation summary" comment pattern is needed.

## RQ-4: Language Fidelity in Agent Definitions

**Finding:** Only `publisher.md` has explicit English-only rules (commit messages, PR descriptions). `onboard` has language rules for config keys. No agent has any instruction about preserving user's language locale or diacritics. When user input is in Czech, agents may produce Czech output but LLMs sometimes drop diacritics — there's no constraint preventing this.

**Root cause confirmed:** No language fidelity instruction exists anywhere. Agents that produce user-facing text (spec-writer, scaffolder creating README) need a diacritics preservation rule.

## RQ-5: Design System Patterns in Scaffold

**Finding:** Zero design/UI instructions exist anywhere in the scaffold pipeline:
- Scaffolder generates only structural files (build, test, lint, CI, Docker)
- Spec-writer asks no questions about design systems or UI quality
- Fixer receives no design context when implementing features
- No agent has any design awareness

**Root cause confirmed:** Web projects scaffolded through the pipeline will have minimal/no styling. The fix should add design system selection to spec-writer and design-aware instructions to scaffolder for web projects.
