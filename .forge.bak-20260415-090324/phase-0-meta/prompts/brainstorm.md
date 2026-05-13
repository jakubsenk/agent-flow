# Phase 3: Brainstorm

## Personas

### Persona 1: Conservative API Integration Engineer
You are a veteran integration engineer who has maintained Redmine and Gitea APIs for 10+ years. You prioritize backward compatibility above all else. Your approach: change the minimum necessary, add fallbacks everywhere, never break existing configs. You distrust LLM reliability for format translation and prefer explicit, deterministic formats.

### Persona 2: Innovative Pipeline Architect
You are a pipeline automation architect who designs self-healing systems. You see Bug 1 as an opportunity to make ALL tracker integrations more robust, not just Redmine. Your approach: add verification-after-mutation as a universal pipeline pattern, not a Redmine-specific hack. For Bug 2, you want a systemic fix that prevents ALL MCP parameter formatting issues, not just newlines.

### Persona 3: Skeptical QA Engineer
You are a QA engineer who has seen many "simple fixes" break production. You question every assumption: What if the Redmine instance has custom statuses? What if `status_id` numbers differ between instances? What if the verification call itself fails? What if the publisher fix breaks other MCP tools that DO handle `\n` correctly? You focus on edge cases, failure modes, and unintended consequences.

## Task Instructions
Each persona independently proposes a solution for both bugs. Then a judge synthesizes the best elements.

**Bug 1: Redmine Status Transitions**
- How should `core/config-reader.md` parse both `status_id:22` and `status:In Progress`?
- Should the verification be Redmine-only or universal?
- How should `skills/onboard/SKILL.md` generate the new format?
- What happens when a legacy config with `status:In Progress` is used?
- Should `docs/reference/trackers.md` change its recommended format?

**Bug 2: Publisher Literal `\n`**
- Where exactly should the fix go — in the publisher agent definition or in the calling skills?
- Should there be a general "MCP parameter formatting" guideline?
- How do you prevent this from regressing?
- Does the fix need to cover block-handler comments too?

**Constraints for all personas:**
- This is a PATCH version — no config contract changes allowed
- Pure markdown plugin — no runtime code to add
- Changes must pass existing test suite (`tests/harness/run-tests.sh`)
- Backward compatibility with existing `status:In Progress` configs is mandatory

## Success Criteria
- Three distinct approaches with clear tradeoffs
- Edge cases identified (custom statuses, MCP tool failures, instance-specific IDs)
- Judge synthesis picks the pragmatic middle ground
- All 5 acceptance criteria are addressed by the final synthesis
- Backward compatibility strategy is explicit

## Anti-Patterns
1. All three personas converging on the same solution — they should disagree on scope and approach
2. Ignoring the "PATCH version" constraint and proposing config contract changes
3. Proposing runtime code (validation scripts, parsers) — this is a pure markdown plugin
4. Forgetting that the onboard wizard needs to change too (not just parsing and verification)
5. Over-engineering the verification: a simple `redmine_get_issue` check is sufficient
6. Ignoring that `core/fix-verification.md` also sets status (re-open on verify failure)

## Codebase Context
- Pure markdown plugin: all "code" is markdown instructions for LLM agents
- `core/config-reader.md` defines parsing contracts — agents follow these instructions
- `agents/publisher.md` is model: haiku — needs explicit, simple instructions
- `docs/reference/trackers.md` is the single source of truth for tracker formats
- Two Redmine config templates exist: `redmine-oracle-plsql.md`, `redmine-rails.md`
- Status-setting sites: fix-ticket step 1, implement-feature step 1, block-handler step 2, publisher step 7, fix-verification step 5
- The onboard wizard (step 2.6) generates state transitions using trackers.md defaults
- Existing validation rules in trackers.md: Redmine state transition format must match `status:{name}`
