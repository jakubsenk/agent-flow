# Research Questions — Testing Patterns & Documentation Updates (Agent 3)

Focus: How to write the v6.7.0 test scenario and what CLAUDE.md changes are required.

---

### Q1: How does `xref-core-registry.sh` validate core file presence and CLAUDE.md count — and what must change for a 14th contract?

**Target files:**
- `tests/scenarios/xref-core-registry.sh`
- `tests/scenarios/core-include-refs.sh`
- `CLAUDE.md` (line containing `` `core/` — 13 shared pipeline pattern contracts ``)

**What to look for:**
- `xref-core-registry.sh` uses a dynamic `ls core/*.md` count and compares it to the number extracted from CLAUDE.md via `grep '`core/`' … | grep 'shared' | grep -oE '[0-9]+'`.
- `core-include-refs.sh` uses a **hardcoded** array `CORE_FILES=(…)` with 11 names (the test predates the 13-contract state) and also checks for 4 standard sections `## Purpose`, `## Input`, `## Output`, `## Failure` in each file.
- The new `core/external-input-sanitizer.md` file must satisfy both tests: it will be picked up automatically by the dynamic xref-core-registry test, but `core-include-refs.sh` will NOT pick it up unless its array is extended.

**Why it matters:**
- Adding `core/external-input-sanitizer.md` without updating `core-include-refs.sh`'s hardcoded array will cause `core-include-refs.sh` to pass silently while missing the new file's section validation.
- CLAUDE.md count must be bumped from 13 to 14 or `xref-core-registry.sh` will FAIL.
- The new core file must follow the standard 4-section format (`## Purpose`, `## Input Contract`, `## Output Contract`, `## Constraints` — note: existing contracts use slightly varied headings; need to confirm which exact heading strings `core-include-refs.sh` checks against).

---

### Q2: What is the exact pattern used by `section-order.sh` and `frontmatter-completeness.sh` to enumerate agents — and must these tests be updated when a NEVER constraint is added to existing agents?

**Target files:**
- `tests/scenarios/section-order.sh`
- `tests/scenarios/frontmatter-completeness.sh`
- `tests/scenarios/read-only-agents.sh`
- `agents/triage-analyst.md`, `agents/code-analyst.md`, `agents/fixer.md`, `agents/reviewer.md`, `agents/spec-analyst.md`

**What to look for:**
- Both `section-order.sh` and `frontmatter-completeness.sh` use a **hardcoded AGENTS array** of 21 names — if v6.7.0 does not add new agent files, these tests require no change.
- `read-only-agents.sh` checks that read-only agents have no write-tool phrases in their `## Process` section. It does NOT inspect `## Constraints` content. The new NEVER constraint for prompt-injection must go into `## Constraints`, not `## Process` — confirm this avoids false failures in `read-only-agents.sh`.
- Determine whether any existing test scans `## Constraints` sections for completeness or content patterns (there is no `constraints-completeness.sh` visible in scenarios/; the new test must create that coverage).

**Why it matters:**
- The new AC-E test scenario must validate that the NEVER constraint text appears in the `## Constraints` section of each of the 5 targeted agents. Without understanding what existing tests already cover for Constraints, the new test may duplicate or contradict them.
- If `read-only-agents.sh` were scanning Constraints (it does not), the new constraint wording would need to be carefully chosen to avoid triggering false positives.

---

### Q3: How do existing xref tests validate that skills reference a specific core contract — and what is the minimum reference pattern the new sanitizer test must assert?

**Target files:**
- `tests/scenarios/xref-core-registry.sh` (lines 36–43: the per-file reference scan)
- `tests/scenarios/core-include-refs.sh` (lines 44–63: `check_refs` function with minimum count thresholds)
- `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/resume-ticket/SKILL.md`, `skills/scaffold/SKILL.md`

**What to look for:**
- `xref-core-registry.sh` searches all `SKILL.md` files for the string `core/{name}` — a single occurrence in any skill is sufficient to pass. This is a broad registry check, not a per-skill check.
- `core-include-refs.sh`'s `check_refs` uses a minimum count per skill (e.g., `fix-ticket` must have `>= 7` core references). Adding `core/external-input-sanitizer` to the 5 listed skills will increase these counts — the minimum thresholds may need incrementing.
- The new AC-E test must assert per-skill presence (each of the 5 skills must individually reference `core/external-input-sanitizer`), not just that some skill references it.

**Why it matters:**
- The minimum-count thresholds in `core-include-refs.sh` for `fix-ticket` (7), `fix-bugs` (7), `implement-feature` (6), `scaffold` (3) will be violated if those files gain a new reference while the threshold stays the same — or conversely, the thresholds should be raised to enforce the new required reference. The new test scenario must decide whether to raise thresholds or add a targeted per-skill assertion.
- `resume-ticket` is not currently in `core-include-refs.sh`'s check list — adding a reference to `core/external-input-sanitizer` in `resume-ticket/SKILL.md` requires either adding it to that test or covering it in the new AC-E scenario.

---

### Q4: What sections does `state/schema.md` use, and how does `test-state-schema.sh` (or `sprint-state-schema.sh`) validate the schema — to understand what the `plugin_version` field addition must satisfy?

**Target files:**
- `state/schema.md`
- `tests/scenarios/state-schema.sh`
- `tests/scenarios/sprint-state-schema.sh`
- `core/state-manager.md`
- `skills/resume-ticket/SKILL.md`

**What to look for:**
- Read `state/schema.md` to identify the current top-level fields and section structure — specifically whether fields are declared in a table, a JSON example block, or free prose, and what the "optional fields" notation looks like.
- Read `tests/scenarios/state-schema.sh` to see how it validates field presence: does it grep for field names by string, check JSON structure, or only validate section headings? This determines whether adding `plugin_version` to the schema is sufficient to pass the test or whether the test also needs updating.
- In `core/state-manager.md`, the Write Process step 3 references `state/schema.md` — determine whether step 3's text must be amended to mention `plugin_version` explicitly, or whether the schema file alone is the authoritative source.
- In `skills/resume-ticket/SKILL.md`, look for how version comparison or WARN patterns are currently implemented (if at all) to understand what prose pattern the new WARN-on-major-mismatch instruction should follow.

**Why it matters:**
- Item 2 of v6.7.0 touches 3 files: `state/schema.md`, `core/state-manager.md`, and `skills/resume-ticket/SKILL.md`. If the state-schema test greps for explicit field names, omitting `plugin_version` from the grep list will cause a silent miss. Knowing the exact validation pattern determines whether the test needs a new assertion or whether schema + state-manager prose changes are sufficient.
