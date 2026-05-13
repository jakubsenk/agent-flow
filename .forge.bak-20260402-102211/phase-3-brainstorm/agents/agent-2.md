# Agent 2 — Skill Architecture Purist
## Position Paper: Commands-to-Skills Migration (v6.0.0)

### Decision 1: Frontmatter Strategy

Two distinct profiles, applied strictly by safety category.

**Pipeline/destructive skills** (fix-ticket, fix-bugs, implement-feature, scaffold, publish, create-pr, onboard, init, scaffold-add, check-deploy, resume-ticket, changelog, version-bump, migrate-config):
```yaml
disable-model-invocation: true
argument-hint: "<ticket-id> [--flags]"
context: fork
model: sonnet
paths: [agents/, commands/, core/, checklists/]
```
`disable-model-invocation: true` is non-negotiable — these rewrite code, push PRs, publish versions. Never auto-invoke. `context: fork` isolates state so a mid-pipeline crash does not corrupt the caller session.

**Analysis/read-only skills** (analyze-bug, check-setup, status, dashboard, metrics, estimate, prioritize, template, scaffold-validate, version-check, discuss):
```yaml
disable-model-invocation: false
argument-hint: "[--flags]"
context: fork
model: sonnet
paths: [agents/, core/]
```
`disable-model-invocation: false` enables semantic discovery — users can say "show pipeline status" and Claude routes correctly. `context: fork` still applies because even read-only skills invoke sub-agents via Task.

### Decision 2: File Splitting Strategy

Files >200 lines go into skill directories. The SKILL.md holds orchestration logic only (≤150 lines). Heavy reference content moves to co-located files:

```
skills/fix-bugs/
  SKILL.md          # orchestration — pipeline steps, hook wiring
  pipeline.md       # full pipeline diagram + retry logic
  config-ref.md     # Automation Config keys consumed by this skill
```

Naming convention: `pipeline.md` for flow documentation, `config-ref.md` for config contracts, `examples.md` for usage examples. SKILL.md references these with `<!-- see pipeline.md -->` comments so the split is navigable.

### Decision 3: Cross-Reference Update Strategy

Update in this order, atomically per file:
1. `core/` — pipeline contracts (3 files) replace `commands/` path references
2. `CLAUDE.md` — repository structure section, architecture diagram, config contract table
3. `docs/reference/` — command reference doc becomes skill reference doc
4. `skills/workflow-router/SKILL.md` — intent routing table paths

No file gets a partial update. Each file is either fully migrated or untouched.

### Decision 4: Test Migration Approach

The 25 tests referencing `commands/` paths need mechanical path substitution plus behavioral re-verification:

1. Update path assertions: `commands/fix-ticket.md` → `skills/fix-ticket/SKILL.md`
2. Add frontmatter assertions: each test verifies `disable-model-invocation` value matches safety profile
3. Add `paths` coverage tests: verify declared paths exist on disk
4. Keep scenario logic unchanged — the orchestration behavior does not change, only location

Run `./tests/harness/run-tests.sh` after each batch of 5 skill migrations to catch regressions early.

### Decision 5: Migration Ordering

1. **Read-only skills first** (11 skills) — zero destructive risk, validates directory structure and frontmatter tooling
2. **Publisher + changelog** — mechanical/haiku-tier, low risk
3. **Pipeline entry points** (fix-ticket, implement-feature, scaffold) — highest complexity, migrated last with full test coverage already in place from steps 1-2
4. **workflow-router** — always last, updated after all targets exist

Never migrate the router before its targets exist. Never migrate a destructive skill before its test is updated.
