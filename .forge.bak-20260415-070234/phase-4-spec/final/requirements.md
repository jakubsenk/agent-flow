# Requirements Specification — v6.5.1 PATCH: Format Evaluation Fixes

## Scope

### What Changes

Five independent PATCH-level fixes addressing correctness issues and machine-token fragility identified during the format evaluation (phases 1-3). All changes are additive or corrective — no format migration, no new features, no contract changes.

| # | Change | File(s) | Category |
|---|--------|---------|----------|
| C1 | Fix duplicate step `4b` numbering | `agents/scaffolder.md` | Correctness |
| C2 | Add contributor note about intentional atomic-write repetition | `skills/fix-bugs/SKILL.md` | Documentation |
| C3 | Add machine-token-spelling constraint to triage-analyst | `agents/triage-analyst.md` | Robustness |
| C4 | Add machine-token-spelling constraint to code-analyst | `agents/code-analyst.md` | Robustness |
| C5 | Add machine-token-spelling constraints to fixer and reviewer | `agents/fixer.md`, `agents/reviewer.md` | Robustness |

### What Does NOT Change

- No YAML/JSON migration for any file category (permanently rejected).
- No config template format changes (deferred to future MINOR).
- No `## Machine Output` sections (deferred to v7.0.0 MAJOR).
- No skill file decomposition or restructuring.
- No changes to core contracts, examples, docs, checklists, tests, or plugin metadata.

---

## C1 — Fix scaffolder.md Duplicate Step Numbering

### Problem

`agents/scaffolder.md` Process section has steps numbered 1, 2, 3, 4, **4b**, 5. Step `4b` is not a substep of step 4 — it is an independent sequential step (quality scorecard generation). The `4b` label is a numbering error that breaks the clean sequential scheme.

### Requirement

Renumber step `4b` to `5` and step `5` to `6` so the Process section follows a clean 1-6 sequential numbering.

### Before (lines 149, 165)

```markdown
4b. Generate quality scorecard:
    Items 1 (Build) and 2 (Tests) are **hard requirements** — ...
    ...

5. Output:
```

### After

```markdown
5. Generate quality scorecard:
   Items 1 (Build) and 2 (Tests) are **hard requirements** — ...
   ...

6. Output:
```

### Compatibility

No downstream references to internal step labels. Verified by grep — no file references "step 4b" or "step 5" of scaffolder by number.

---

## C2 — Add Contributor Note to fix-bugs/SKILL.md

### Problem

`skills/fix-bugs/SKILL.md` contains 16 occurrences of the phrase `Follow atomic write protocol from core/state-manager.md`. This repetition is intentional LLM-directed design — each state-write step needs the explicit instruction for reliable per-step compliance. A future contributor could mistake this for accidental duplication and consolidate, breaking reliable state management.

### Requirement

Insert one HTML comment near the first occurrence of the phrase (line 89) explaining that the repetition is intentional and must not be consolidated.

### Before (line 88-89)

```markdown
For each issue fetched in step 1: create `.ceos-agents/{ISSUE-ID}/` directory and initialize `state.json` following the schema in `state/schema.md` with `status: "running"`, `mode: "code-bugfix"`, `pipeline: "fix-bugs"`, `run_id: "{ISSUE-ID}"`. Follow atomic write protocol from `core/state-manager.md`.
```

### After

```markdown
<!-- Contributor note: "Follow atomic write protocol from core/state-manager.md" appears at each state.json write step intentionally. This is LLM-directed repetition for reliable per-step compliance — not accidental duplication. Do not consolidate. -->
For each issue fetched in step 1: create `.ceos-agents/{ISSUE-ID}/` directory and initialize `state.json` following the schema in `state/schema.md` with `status: "running"`, `mode: "code-bugfix"`, `pipeline: "fix-bugs"`, `run_id: "{ISSUE-ID}"`. Follow atomic write protocol from `core/state-manager.md`.
```

### Compatibility

HTML comment is invisible to the LLM runtime and does not affect skill behavior. No functional change.

---

## C3 — Add Machine-Token-Spelling Constraint to triage-analyst

### Problem

`agents/triage-analyst.md` outputs machine-readable tokens (`PASS`, `UNCLEAR`, severity values `CRITICAL|HIGH|MEDIUM|LOW`, complexity values `XS|S|M|L`) that downstream skills parse via string matching. The `UNCLEAR` token is already documented inline (line 44) but no explicit Constraints rule enforces exact spelling. Token drift (e.g., "Insufficient", "Incomplete") would cause silent pipeline failures.

Additionally, the `Reproduction steps` field (step 8) outputs JSON-like action objects but has no constraint enforcing JSON array literal format, which can cause parse failures in browser-verifier/reproducer.

### Requirement

Add two Constraints lines to the `## Constraints` section:

1. A constraint enforcing exact token spelling for `Quality gate` values.
2. A constraint enforcing JSON array literal format for `Reproduction steps`.

### Before (end of Constraints section, line 108-113)

```markdown
## Constraints

- NEVER modify code — read-only analysis
- NEVER guess missing information — Block if unclear
- MUST search for duplicate issues before proceeding with full triage
- MUST store downloaded attachments in system temp directory only, organized by issue ID
- If issue tracker MCP server is unreachable: report error to chat, do not proceed
- On failure: Block using the Block Comment Template above, move on
```

### After

```markdown
## Constraints

- NEVER modify code — read-only analysis
- NEVER guess missing information — Block if unclear
- MUST search for duplicate issues before proceeding with full triage
- MUST store downloaded attachments in system temp directory only, organized by issue ID
- MUST use exactly `PASS` or `UNCLEAR` as the Quality gate value. No variations (not "incomplete", "insufficient", "fail", or other synonyms).
- MUST output Reproduction steps as a JSON array literal (e.g., `[{action: "navigate", target: "/"}]`), not as prose or numbered list. Omit the field entirely if not UI-related.
- If issue tracker MCP server is unreachable: report error to chat, do not proceed
- On failure: Block using the Block Comment Template above, move on
```

### Compatibility

Additive constraint. Does not change the agent's output format — only makes the existing implicit requirement explicit. Existing correct outputs already comply.

---

## C4 — Add Machine-Token-Spelling Constraint to code-analyst

### Problem

`agents/code-analyst.md` outputs machine-readable tokens in its Impact Report: `root cause confirmed: YES / NO` and risk level `LOW|MEDIUM|HIGH`. These values are consumed by downstream pipeline logic. No explicit Constraints rule enforces exact spelling.

### Requirement

Add one Constraints line enforcing exact token spelling for the `root cause confirmed` field.

### Before (end of Constraints section, lines 101-117)

```markdown
## Constraints

- NEVER modify code — read-only analysis
- If the bug report names a specific method/file as the cause, treat it as a HINT, not a fact. ...
- Max 5 affected files in output — ...
- Risk level criteria: LOW = isolated change, 1-2 callers. MEDIUM = multiple callers (3-10). HIGH = >10 callers, public API, or cross-module impact.
- If codebase is too large to fully explore: ...
- Historical context is SUPPLEMENTARY — ...
- On failure: report findings so far, Block using the Block Comment Template:
  ```
  ...
  ```
```

### After

```markdown
## Constraints

- NEVER modify code — read-only analysis
- If the bug report names a specific method/file as the cause, treat it as a HINT, not a fact. ...
- Max 5 affected files in output — ...
- Risk level criteria: LOW = isolated change, 1-2 callers. MEDIUM = multiple callers (3-10). HIGH = >10 callers, public API, or cross-module impact.
- MUST use exactly `YES` or `NO` as the `root cause confirmed` value. No variations (not "confirmed", "unconfirmed", "partial", or other synonyms).
- MUST use exactly one of `LOW`, `MEDIUM`, `HIGH` as the Risk level value. No variations.
- If codebase is too large to fully explore: ...
- Historical context is SUPPLEMENTARY — ...
- On failure: report findings so far, Block using the Block Comment Template:
  ```
  ...
  ```
```

### Compatibility

Additive constraint. Does not change the agent's output format.

---

## C5 — Add Machine-Token-Spelling Constraints to fixer and reviewer

### Problem — fixer

`agents/fixer.md` can signal `NEEDS_DECOMPOSITION` (step 5, escape hatch) which is consumed by the orchestrating skill to trigger decomposition. If the token drifts (e.g., "NEEDS DECOMPOSITION", "decomposition needed"), the skill misses the signal and the pipeline continues with an incomplete fix.

### Problem — reviewer

`agents/reviewer.md` outputs a `Verdict` value (`APPROVE`, `REQUEST_CHANGES`, `BLOCK`) that controls pipeline branching. The orchestrating skill string-matches this value. Token drift (e.g., "APPROVED", "CHANGES_REQUESTED", "BLOCKED") causes silent pipeline failure — the skill cannot determine whether to loop, proceed, or block.

The reviewer also outputs AC fulfillment verdicts (`FULFILLED`, `PARTIALLY`, `NOT ADDRESSED`) that are consumed by the acceptance gate.

### Requirement — fixer

Add one Constraints line to `agents/fixer.md` enforcing exact spelling of the `NEEDS_DECOMPOSITION` token.

### Before (fixer Constraints, lines 79-95)

```markdown
## Constraints

- NEEDS_DECOMPOSITION may be signaled at most ONCE per ticket. If the decomposed subtasks also exceed limits, Block.
- NEVER signal NEEDS_DECOMPOSITION to avoid a hard problem — only when scope genuinely exceeds limits.
- NEVER change more than necessary — no drive-by refactoring
- NEVER modify public APIs without explicit approval
- Diff MUST NOT exceed 100 lines. ...
- Build MUST pass before declaring success
- On failure: revert changes, Block using the Block Comment Template:
  ...
```

### After

```markdown
## Constraints

- NEEDS_DECOMPOSITION may be signaled at most ONCE per ticket. If the decomposed subtasks also exceed limits, Block.
- NEVER signal NEEDS_DECOMPOSITION to avoid a hard problem — only when scope genuinely exceeds limits.
- MUST use the exact string `NEEDS_DECOMPOSITION` when signaling decomposition need. No variations (not "NEEDS DECOMPOSITION", "needs_decomposition", "decomposition needed", or other forms).
- NEVER change more than necessary — no drive-by refactoring
- NEVER modify public APIs without explicit approval
- Diff MUST NOT exceed 100 lines. ...
- Build MUST pass before declaring success
- On failure: revert changes, Block using the Block Comment Template:
  ...
```

### Requirement — reviewer

Add two Constraints lines to `agents/reviewer.md` enforcing exact spelling of the `Verdict` value and the AC fulfillment verdicts.

### Before (reviewer Constraints, lines 103-120)

```markdown
## Constraints

- NEVER modify code — feedback only
- NEVER run build or test commands — ...
- NEVER approve with zero findings unless ...
- NEVER block a correct fix for style nitpicks — ...
- If fixer produced zero changed files, BLOCK with reason ...
- Verdict = BLOCK only for: ...
- If acceptance criteria were provided in context, MUST include AC Fulfillment section in output. ...
- On BLOCK: Block using the Block Comment Template:
  ...
```

### After

```markdown
## Constraints

- NEVER modify code — feedback only
- NEVER run build or test commands — ...
- NEVER approve with zero findings unless ...
- NEVER block a correct fix for style nitpicks — ...
- If fixer produced zero changed files, BLOCK with reason ...
- Verdict = BLOCK only for: ...
- MUST use exactly one of: `APPROVE`, `REQUEST_CHANGES`, `BLOCK` as the Verdict value. No variations, no additional qualifiers (not "APPROVED", "CHANGES_REQUESTED", "BLOCKED", or other forms).
- MUST use exactly one of: `FULFILLED`, `PARTIALLY`, `NOT ADDRESSED` for each AC fulfillment verdict. No variations.
- If acceptance criteria were provided in context, MUST include AC Fulfillment section in output. ...
- On BLOCK: Block using the Block Comment Template:
  ...
```

### Compatibility

Additive constraints. Do not change agent output formats — only make existing implicit requirements explicit. Existing correct outputs already comply.
