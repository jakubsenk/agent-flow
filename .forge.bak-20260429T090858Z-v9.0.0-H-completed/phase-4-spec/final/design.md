# Phase 4 — Design (architecture + concrete content)
# v9.0.0 sub-projekt H — Agent I/O Contracts

**Companion to:** `requirements.md` (EARS), `formal-criteria.md` (machine-checkable AC)
**Purpose:** Translate REQ-H-001..H-102 into concrete enumerated content the Phase 6 plan + Phase 7 implementation can execute without re-deriving design choices.

---

## Section 1 — Output Contract format spec

### 1.1 Canonical structure

Every agent file gains a single mandatory section between `## Process` and `## Constraints`:

```markdown
## Output Contract

### Inputs

| Section | Source | Required |
|---------|--------|----------|
| {field name as the agent expects to find it} | {dispatching skill prompt; agent frontmatter; CWD file at path; pipeline-history.md} | yes / no |

### Outputs

| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## {Heading the agent emits}` | always / `--phase X` / on {SENTINEL} / on Block | semicolon-separated list of bullet sub-fields the agent must populate |
```

### 1.2 Polymorphic shape (REQ-H-010)

For analyst, test-engineer, browser-agent, spec-reviewer:

```markdown
## Output Contract

### Output Contract — Phase: {phase-A-name}

#### Inputs
| Section | Source | Required |
|---------|--------|----------|
| ... | ... | ... |

#### Outputs
| Section produced | When | Required fields |
|------------------|------|-----------------|
| ... | ... | ... |

### Output Contract — Phase: {phase-B-name}

#### Inputs
... (same shape)

#### Outputs
... (same shape)
```

The single `## Output Contract` heading is preserved (so `section-order.sh` and `v9-output-contract-position.sh` see one match); per-phase splits use H3 sub-headings.

### 1.3 Positive example (analyst — phase triage)

```markdown
## Output Contract

### Output Contract — Phase: triage

#### Inputs

| Section | Source | Required |
|---------|--------|----------|
| `--phase triage` flag | dispatching skill prompt | yes |
| Issue ID | dispatching skill prompt | yes |
| Issue tracker context | Automation Config: Issue Tracker section (Type, Instance, Project) | yes |
| `Module Docs` Path | Automation Config: Module Docs section | no |

#### Outputs

| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Triage Analysis` | always | Summary; Area; Severity; Reproduction; Attachments; Acceptance Criteria; Complexity; Reproduction steps (UI-only) |
| `## NEEDS_CLARIFICATION` | on ambiguous repro | Question (≤280 chars); Context (≤500 chars) |
| `Quality gate: PASS` | on complete issue | (literal sentinel inside ## Triage Analysis body) |
| `Quality gate: UNCLEAR` | on incomplete issue | (literal sentinel; followed by per-question feedback) |
| `[ceos-agents] Triage completed. Severity: {s}. Area: {a}. Complexity: {c}. AC: {n}.` | on PASS — posted as tracker comment | severity; area; complexity; AC count |
| `[ceos-agents] 🔴 Pipeline Block` | on Block | Agent; Step; Reason; Detail; Recommendation |
```

### 1.4 Negative example (would FAIL lint)

```markdown
## Output Contract

This agent emits a Fix Report when complete and may signal NEEDS_DECOMPOSITION.

The Fix Report has these fields: Objective, Approach, Files changed.
```

Why it fails:
- No Inputs table — `v9-output-contract-shape.sh` `grep -qE '^### Inputs'` returns false.
- No Outputs table — `grep -qE '^### Outputs'` returns false.
- `Fix Report` is not backtick-quoted — `v9-xref-outputs-skill-references.sh` cannot extract via `grep -oE '\`## [A-Za-z][A-Za-z _-]*\`'`.
- `NEEDS_DECOMPOSITION` is mentioned in prose but not enumerated as a row in the Outputs table.

---

## Section 2 — Per-agent Output Contract content (all 18, then deletion of stack-selector)

This section enumerates the de-facto contract content for every agent. Phase 6 plans tasks against this. Phase 7 fixers produce verbatim content. Backtick-quoting and table column names are NORMATIVE.

### 2.1 acceptance-gate (read-only, sonnet)
**Source:** agents/acceptance-gate.md:37-50

#### Inputs
| Section | Source | Required |
|---------|--------|----------|
| Acceptance criteria list | upstream agent output (analyst --phase triage in bug-fix mode; spec-analyst in feature mode) | yes |
| Fixer's changed files | fixer output (Files changed list) | yes |

#### Outputs
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Acceptance Gate Report` | always | Verdict (APPROVE / REQUEST_CHANGES); AC counts (fulfilled/total/partial/not_addressed); Details (per-AC verdict + file:line + test name); Summary |

### 2.2 analyst (read-only, sonnet, polymorphic)
**Source:** agents/analyst.md (full file)

Polymorphic split per REQ-H-011: phase `triage`, phase `impact`.

#### Phase: triage
**Inputs:** `--phase triage` flag (skill prompt, required); Issue ID (skill prompt, required); Issue Tracker section of Automation Config (required); `Module Docs` path (optional).

**Outputs:**
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Triage Analysis` | always | Summary; Area; Severity (CRITICAL/HIGH/MEDIUM/LOW); Reproduction; Attachments; Acceptance Criteria (2-5 items); Complexity (XS/S/M/L); Reproduction steps (UI-only, JSON array) |
| `## NEEDS_CLARIFICATION` | on ambiguous repro | Question (≤280 chars); Context (≤500 chars) |
| `Quality gate: PASS` literal | on complete issue | (sentinel inside ## Triage Analysis) |
| `Quality gate: UNCLEAR` literal | on incomplete issue | (sentinel + per-question feedback) |
| `[ceos-agents] Triage completed.` checkpoint comment | on PASS | severity; area; complexity; AC count |
| `[ceos-agents] 🔴 Pipeline Block` | on Block | Agent: analyst; Step: Triage; Reason; Detail; Recommendation |

#### Phase: impact
**Inputs:** `--phase impact` flag (skill prompt, required); triage analysis (upstream, required); affected codebase (CWD, required); `Module Docs` path (optional); Retry Limits → Root cause iterations (optional, default 3).

**Outputs:**
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Impact Report` | always | Root cause location; Affected files (max 5); Callers at risk; Test coverage; Risk level (LOW/MEDIUM/HIGH); Historical context; Reproduction trace; Sanity check; Suggested approach |
| `Partial analysis` sub-block inside `## Impact Report` | on root cause unconfirmed | Completed steps; Traced up to; Boundary hit; Candidates not confirmed; Secondary defects found; Next steps for human |
| `[ceos-agents] 🔴 Pipeline Block` | on Block | Agent: analyst; Step: Impact Analysis; Reason; Detail; Recommendation |

### 2.3 architect (read-only, opus)
**Source:** agents/architect.md:75-86

#### Inputs
| Section | Source | Required |
|---------|--------|----------|
| Specification or impact report | upstream (spec-analyst output for features; analyst --phase impact for bugs) | yes |
| `Module Docs` path | Automation Config | no |
| Decomposition config | Automation Config: Decomposition section (Max subtasks default 7) | no |

#### Outputs
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Architecture Design` | always | Architecture (2-3 sentences); Approach rationale; Files affected; Risk assessment (LOW/MEDIUM/HIGH); Decomposition (YES/NO + count + strategy); Task tree (YAML if decomposed) |
| `decomposition:` YAML block | on decomposition needed | strategy (sequential/parallel/mixed); reason; subtasks[] with id/title/scope/files/estimated_lines/depends_on/maps_to/acceptance_criteria |
| `[ceos-agents] 🔴 Pipeline Block` | on Block | Agent: architect; Step: Architecture Design; Reason; Detail; Recommendation |

### 2.4 backlog-creator (read-only, sonnet)
**Source:** agents/backlog-creator.md:54-83

#### Inputs
| Section | Source | Required |
|---------|--------|----------|
| Specification documents OR architect task tree | dispatching skill (create-backlog or scaffold) | yes |
| Mode hint (spec / task) | inferred from input shape (presence of `### Story` or `### Task` triggers task mode) | yes |

#### Outputs
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Backlog Summary` | always | table with columns # / Epic / AC / Size / SP / Dependencies |
| `## {Epic Title}` | once per epic (max 10) | Type; Size; Dependencies; Scope; Acceptance Criteria; Verification (Unit/Integration/E2E) |
| `**maps_to:** AC-N: text` field | task mode only | reference to architect parent AC |
| `WARNING: Only {N} AC could be inferred...` | on AC < 2 | (informational, not Block) |
| `[ceos-agents] 🔴 Pipeline Block` | on Block | Agent: backlog-creator; Step: Spec Parsing; Reason; Detail; Recommendation |

### 2.5 browser-agent (execution, sonnet, polymorphic)
**Source:** agents/browser-agent.md (full file)

Polymorphic split per REQ-H-013: phase `reproduce`, phase `verify`.

#### Phase: reproduce
**Inputs:** `--phase reproduce` flag (default if absent); bug description + triage output (upstream, required); `Browser Verification` config block (required: Base URL, Start command, Timeout, Screenshot storage).

**Outputs:**
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Reproduction Result` | always | Status (reproduced / not_reproduced / skipped); Reason (skipped only); Page URL; Console errors; Network failures; Accessibility snapshot (≤2000 chars); Screenshot path |
| `.ceos-agents/{ISSUE-ID}/reproducer-script.js` | always (when not skipped) | Playwright script literal |
| `.ceos-agents/{ISSUE-ID}/reproduction-result.json` | always | status; page_url; accessibility_snapshot; console_errors; network_failures; screenshot_path |

#### Phase: verify
**Inputs:** `--phase verify` flag (skill prompt, required); reproducer JSON from reproduce phase (CWD file, optional — falls back to SKIPPED); fixer diff (upstream, required); acceptance criteria (upstream, required); `Browser Verification` config block including On events (required) + Exploration (optional) + Exploration max clicks (optional).

**Outputs:**
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Browser Verification Report` | always | Verdict (VERIFIED / PARTIAL / FAILED / SKIPPED); Reproduction replay; Adjacent pages checked; Visual AC check; Exploration; Screenshots |
| `.ceos-agents/{ISSUE-ID}/verification-result.json` | when not SKIPPED | verdict; subphase_a (reproduction_replay/adjacent_pages/visual_ac_check); subphase_b (ran/observations); screenshots[] |

### 2.6 deployment-verifier (execution, sonnet)
**Source:** agents/deployment-verifier.md:91-100

#### Inputs
| Section | Source | Required |
|---------|--------|----------|
| Action (check / start / stop) | dispatching skill prompt | yes |
| `Local Deployment` section | Automation Config (Type, Ports, Health check URL, Health check timeout, Start/Stop commands) | yes (else verdict SKIPPED) |

#### Outputs
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Deployment Verification Report` | always | Verdict (HEALTHY / UNHEALTHY / PORT_CONFLICT / START_FAILED / SKIPPED); Type (docker / native); Ports summary; Health check; Containers (docker only); Issues |
| `.ceos-agents/deploy/{timestamp}/result.json` | when not SKIPPED | verdict; type; health_url; ports[]; started_at; verified_at; error; containers[] |

### 2.7 fixer (execution, opus)
**Source:** agents/fixer.md:73-82, :48-66

#### Inputs
| Section | Source | Required |
|---------|--------|----------|
| Mode hint | dispatching skill (`Mode: feature` / `Mode: scaffold` for those modes; absent in bug-fix mode) | no (defaults to bug-fix) |
| Triage analysis + impact report | upstream analyst (bug-fix mode) | yes in bug-fix mode |
| Spec + architect subtask | upstream spec-analyst + architect (feature/scaffold modes) | yes in feature/scaffold mode |
| Reviewer feedback (iter ≥ 2) | prior reviewer output | yes when iteration > 1 |
| pipeline-history.md last 5 entries | `.ceos-agents/pipeline-history.md` (CWD file) | no |
| Build & Test commands | Automation Config: Build & Test section | yes |

#### Outputs
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Fix Report` | on success | Objective; Approach; Files changed; Build (PASS); Tests (PASS / pre-existing-failures note) |
| `## NEEDS_DECOMPOSITION` | on scope > limits (max once per ticket) | Reason; Estimated scope (N files, ~M lines); Suggested split (2-3 subtasks); Work done so far |
| `## NEEDS_CLARIFICATION` | on ambiguity (max 3 per run, max 1 per iteration) | Question (≤280 chars); Context (≤500 chars) |
| `[ceos-agents] 🔴 Pipeline Block` | on Block | Agent: fixer; Step: Fix Implementation; Reason; Detail; Recommendation |

### 2.8 priority-engine (read-only, opus)
**Source:** agents/priority-engine.md:35-60

#### Inputs
| Section | Source | Required |
|---------|--------|----------|
| Open issue list (ID, title, description, state, labels, comments) | dispatching skill (prioritize) | yes |
| Historical metrics (optional) | `/ceos-agents:metrics` output or pipeline-history | no |

#### Outputs
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Backlog Prioritization` | on ≥1 issue | Three tier sub-tables: P0 — Fix Now, P1 — Fix Next, P2 — Backlog (each with # / Issue / Impact / Risk / Effort / Score / Rationale); Dependencies; Recommendations |
| `No open issues found — backlog is empty` literal | on 0 issues | (terminal sentinel; no Block) |
| `[ceos-agents] 🔴 Pipeline Block` | on Block | Agent: priority-engine; Step: Backlog Prioritization; Reason; Detail; Recommendation |

### 2.9 publisher (execution, haiku)
**Source:** agents/publisher.md:81-93

#### Inputs
| Section | Source | Required |
|---------|--------|----------|
| Mode (full-publish / pr-only-404 / pr-only-no-id) | dispatching skill prompt | yes |
| Source Control config | Automation Config (Remote, Base branch, Branch naming) | yes |
| PR Rules + PR Description Template | Automation Config | yes |
| Issue Tracker config (Type, State transitions) | Automation Config | yes (skipped only in pr-only-* modes) |

#### Outputs
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Publish Report` | on success | Branch; Commits (count); PR (URL); Issue updated; Tracker (mode-dependent row) |
| Tracker row variants | mode-dependent | `Tracker: Updated → For Review` (full-publish) / `Tracker: Skipped — issue ID '{id}' not found in {tracker_type}` (pr-only-404) / `Tracker: Skipped — no issue ID in branch name` (pr-only-no-id) |
| `[ceos-agents] 🔴 Pipeline Block` | on Block | Agent: publisher; Step: Publish; Reason; Detail; Recommendation |

### 2.10 reviewer (read-only, opus)
**Source:** agents/reviewer.md:77-98

#### Inputs
| Section | Source | Required |
|---------|--------|----------|
| Mode hint | dispatching skill (`Mode: feature` / `Mode: scaffold` / absent for bug-fix) | no |
| Bug report + triage + impact | upstream (bug-fix mode) | yes in bug-fix mode |
| Spec + architect task tree | upstream (feature/scaffold) | yes in those modes |
| Fixer's output + changed files | upstream fixer | yes |
| Acceptance criteria | upstream (analyst --phase triage / spec-analyst / architect) | no (skip AC Fulfillment if absent) |
| pipeline-history.md last 10 entries | CWD file | no |
| Iteration number + previous reviewer feedback | dispatching skill (when iter ≥ 2) | conditional |

#### Outputs
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Code Review` | always | Verdict (APPROVE / REQUEST_CHANGES / BLOCK); Issues found (count); Issues (numbered, severity-tagged with HIGH/MEDIUM/LOW); AC Fulfillment (per-AC verdict FULFILLED/PARTIALLY/NOT ADDRESSED + evidence) |
| `[ceos-agents] 🔴 Pipeline Block` | on BLOCK verdict | Agent: reviewer; Step: Code Review; Reason; Detail; Recommendation |

### 2.11 rollback-agent (execution, haiku)
**Source:** agents/rollback-agent.md:74-84

#### Inputs
| Section | Source | Required |
|---------|--------|----------|
| Blocking-agent name + step + reason + detail + recommendation | dispatching skill (Block handler) | yes |
| Source Control: Base branch | Automation Config | yes |
| Issue Tracker config | Automation Config | yes (skipped in scaffold pipeline contexts where no tracker is configured) |

#### Outputs
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Rollback Report` | always | Context (worktree / CWD); Base branch; Rollback (completed / skipped); Stash; Issue (state transition); Comment (posted) |
| `No rollback needed — blocking agent ({name}) made no code changes.` literal | on read-only blocking agent | (terminal sentinel) |
| `No rollback needed — publisher block requires manual cleanup (check for existing PR/branch).` literal | on publisher block | (terminal sentinel) |
| `No rollback needed — scaffolder block handled by scaffold command.` literal | on scaffolder block | (terminal sentinel) |
| `[ceos-agents] 🔴 Pipeline Block` | always (posted as tracker comment) | Agent (passed-in name); Step; Reason; Detail; Recommendation |

### 2.12 scaffolder (execution, sonnet)
**Source:** agents/scaffolder.md:165-192

#### Inputs
| Section | Source | Required |
|---------|--------|----------|
| Tech stack (from `spec/README.md` Tech Stack section in v2 mode; from skill-supplied flags in --no-implement mode) | scaffold skill prompt or spec/ folder | yes |
| Mode hint (scaffold v2 / --no-implement) | dispatching skill | yes |
| Build & Test commands | inferred from stack OR Automation Config (post-generation) | yes |

#### Outputs
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Scaffold Report` | always | Stack (one-line); Files generated (count + list); Automation Config status; Verification (Build/Tests/Linter/Test infra); Quality Scorecard table (11-row markdown table for web+Playwright projects, fewer for non-web) |
| `## Quality Scorecard` table inside Scaffold Report | always | Check / Status / Notes — at minimum 4 rows: Build, Tests, Lint, CLAUDE.md |

### 2.13 spec-analyst (read-only, sonnet)
**Source:** agents/spec-analyst.md:50-79

#### Inputs
| Section | Source | Required |
|---------|--------|----------|
| Issue ID | dispatching skill (implement-feature) | yes |
| Issue tracker context | Automation Config: Issue Tracker section | yes |

#### Outputs
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Feature Specification` | always | Summary; Type (single feature / epic with sub-features count); Area; Acceptance Criteria; Scope (IN/OUT); Dependencies; Constraints |
| `Quality gate: PASS` literal | on complete issue | (sentinel in spec output) |
| `Quality gate: incomplete` literal | on incomplete issue | (sentinel + per-question feedback) |
| `[ceos-agents] Spec analysis completed. Area: {a}. Criteria: {n}.` checkpoint | on PASS | area; criteria count |
| `[ceos-agents] Acceptance Criteria:` separate tracker comment | on PASS | numbered AC list |
| `[ceos-agents] 🔴 Pipeline Block` | on Block | Agent: spec-analyst; Step: Spec Analysis; Reason; Detail; Recommendation |

### 2.14 spec-reviewer (read-only, opus, polymorphic)
**Source:** agents/spec-reviewer.md (full file)

Polymorphic split per REQ-H-014: default review mode, `--verify` mode.

#### Default (review mode)
**Inputs:** `spec/README.md`, `spec/architecture.md`, `spec/verification.md`, `spec/epics/*.md` (CWD files, all required).

**Outputs:**
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Spec Review` | always | Verdict (APPROVE / REVISE); Issues (numbered, severity BLOCK/WARN); Summary |

#### --verify mode
**Inputs:** `--verify` flag (skill prompt, required); spec/ folder (CWD, required); implemented codebase (CWD, required).

**Outputs:**
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Spec Compliance Report` | always | Verdict (PASS / PARTIAL / FAIL); Coverage (N/M AC + percentage); Details (per-epic per-AC verdict IMPLEMENTED/PARTIALLY/MISSING + evidence); NFR compliance (per-NFR verdict RESPECTED/VIOLATED/UNTESTABLE); Summary |

### 2.15 spec-writer (execution, opus)
**Source:** agents/spec-writer.md:73-84

#### Inputs
| Section | Source | Required |
|---------|--------|----------|
| Project description | scaffold skill prompt (direct text or issue tracker card) | yes |
| Mode (interactive / yolo-checkpoint / yolo) | dispatching skill | yes |
| Tech stack flags (--lang, --framework, --db, --ci) | dispatching skill | no |
| Custom template (--template) | dispatching skill | no |

#### Outputs
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Spec Writer Report` | always | Mode; Input source; Files generated (spec/README.md, spec/architecture.md, spec/verification.md, spec/epics/*); Tech stack (one-line); Acceptance criteria (total count) |
| `spec/README.md` file | always | Vision & Goals; Users & Personas; Tech Stack; Design & UX (web only); Out of Scope |
| `spec/architecture.md` file | always | High-Level Overview; Data Flow; NFR |
| `spec/verification.md` file | always | Test Strategy; Definition of Done; Risks & Assumptions |
| `spec/epics/NN-name.md` files | always | Description; User Stories with AC (GWT or rule-oriented); Dependencies; Priority |
| `[ceos-agents] 🔴 Pipeline Block` | on Block | Agent: spec-writer; Step: Specification Generation; Reason; Detail; Recommendation |

### 2.16 sprint-planner (read-only, sonnet)
**Source:** agents/sprint-planner.md:79-115

#### Inputs
| Section | Source | Required |
|---------|--------|----------|
| Priority-engine output | upstream priority-engine `## Backlog Prioritization` | yes |
| Sprint Planning config | Automation Config: Sprint Planning section | yes |
| Triage checkpoint comments (optional, for complexity precedence) | issue tracker | no |
| `--all` mode flag | dispatching skill prompt | no |

#### Outputs
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Sprint Plan: {sprint_name}` | always | Duration; Capacity (with velocity_source); Selected Issues table; Overflow table |
| `### Selected Issues` sub-table | always | columns # / Issue / Tier / Effort / SP / Dependencies / Flags |
| `### Overflow` sub-table | always (may be empty if all fit) | columns # / Issue / Tier / SP / Reason |
| `### Dependency Warnings` | when at-risk dependencies exist | bulleted list |
| `### Cold Start Warnings` | when velocity_source != "historical" | (advisory text) |
| `### Release Summary` | on `--all` mode | columns Sprint / Issues / unit / Notable |
| `[ceos-agents] 🔴 Pipeline Block` | on Block | Agent: sprint-planner; Step: Sprint Planning; Reason; Detail; Recommendation |

### 2.17 stack-selector (read-only, sonnet) — DELETED in v9.0.0

**Status:** REQ-H-080 deletes `agents/stack-selector.md`. The de-facto contract documented here is for traceability only — Phase 7 deletes the file. No `## Output Contract` is added to a file scheduled for deletion.

**Source (for record):** agents/stack-selector.md:42-54 declared `## Stack Selection` output with Stack summary / Rationale / Project structure / Key dependencies. **Zero actual dispatches** in `skills/**/*.md` — the scaffolder agent in scaffold v2 mode reads the Tech Stack from `spec/README.md` directly (agents/scaffolder.md:22-24), and the legacy `--no-implement` flow text in `skills/scaffold/SKILL.md:91` is the orphan reference.

### 2.18 test-engineer (execution, sonnet, polymorphic)
**Source:** agents/test-engineer.md (full file)

Polymorphic split per REQ-H-012: default (no flag) for unit/integration; `--e2e` for end-to-end.

#### Default (no flag — unit/integration tests)
**Inputs:** Mode hint (`Mode: feature` / `Mode: scaffold` / absent for bug-fix) — dispatching skill prompt; bug report + fixer output + impact report (bug-fix mode); spec-analyst output + architect subtask + fixer output (feature/scaffold modes); Build & Test commands from Automation Config.

**Outputs:**
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Test Report` | always | Existing tests (PASS count / total); New tests (per-test entry: file_path::test_name — what it verifies) |
| `[ceos-agents] 🔴 Pipeline Block` | on Block | Agent: test-engineer; Step: Test Writing; Reason; Detail; Recommendation |

#### Phase: --e2e
**Inputs:** `--e2e` flag (skill prompt, required); E2E Test config (Framework, Command — Automation Config, required); spec acceptance criteria (upstream, required for scaffold mode).

**Outputs:**
| Section produced | When | Required fields |
|------------------|------|-----------------|
| `## Test Report` | always | Existing tests (PASS count / total); New tests (E2E framework-specific paths — playwright.spec / pytest e2e / capybara spec / etc.) |
| `[ceos-agents] 🔴 Pipeline Block` | on Block | Agent: test-engineer; Step: E2E Test Writing; Reason; Detail; Recommendation |

---

## Section 3 — Lint scenarios spec

Each new scenario at `tests/scenarios/v9-*.sh`. All scenarios:
- Set `REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"` (existing pattern, REQ-H-031).
- Guard against `.forge/` staging path (existing pattern from `v8-agents-analyst-shape.sh:10-13`).
- Define `fail() { echo "FAIL: $1" >&2; FAIL=1; }`.
- Exit 0=PASS, 77=SKIP, anything else=FAIL.

### 3.1 `v9-output-contract-shape.sh`

**Purpose:** For each agent file under `agents/*.md`, if it contains a `^## Output Contract` heading, assert the section is well-formed: contains both an Inputs table header (`Section | Source | Required`) and an Outputs table header (`Section produced | When | Required fields`), AND at least one Outputs table row backtick-quotes a `## Heading`.

**SKIP-guard:** `exit 77` if `grep -qE '^## Output Contract' "$FILE"` returns false (transition window — REQ-H-032).

**Per-agent assertion logic in plain English:**
1. Extract section content from `## Output Contract` line up to next `^## ` line (awk range).
2. For polymorphic agents: extract each `### Output Contract — Phase: X` sub-block; assertions apply per sub-block.
3. Assert section contains literal `Section | Source | Required` (Inputs table header).
4. Assert section contains literal `Section produced | When | Required fields` (Outputs table header).
5. Assert at least one line matches `\| \`## [A-Za-z][A-Za-z _-]*\` \|` (a backtick-quoted heading row in the Outputs column).

### 3.2 `v9-output-contract-completeness.sh`

**Purpose:** Hard enforcement gate — every agent file under `agents/*.md` MUST have a `## Output Contract` section. No SKIP-guard. After Phase 7, this scenario PASSES on the v9.0.0 codebase.

**Assertion logic:**
1. Enumerate `agents/*.md` (post-stack-selector-deletion = 17 files).
2. For each file, assert `grep -qE '^## Output Contract' "$FILE"` returns true.
3. FAIL with the agent name if missing.

This scenario directly enforces REQ-H-001 + REQ-H-033.

### 3.3 `v9-output-contract-position.sh`

**Purpose:** Assert positional invariant — when `## Output Contract` is present, it sits between `## Process` and `## Constraints` (REQ-H-002).

**SKIP-guard:** `exit 77` per file if `## Output Contract` absent.

**Assertion logic:**
1. For each agent: extract `^## Process` line number (process_line), `^## Output Contract` line number (oc_line), `^## Constraints` line number (cons_line).
2. Assert `process_line < oc_line < cons_line`. FAIL with line numbers if order violates.

### 3.4 `v9-output-contract-polymorphic-split.sh`

**Purpose:** For the 4 polymorphic agents (analyst, test-engineer, browser-agent, spec-reviewer), assert per-phase sub-blocks exist.

**SKIP-guard:** `exit 77` if `## Output Contract` absent in the agent under test.

**Per-agent expected sub-block headings (REQ-H-011..H-014):**
- `analyst`: `### Output Contract — Phase: triage` AND `### Output Contract — Phase: impact`.
- `test-engineer`: `### Output Contract — Default (no flag)` AND `### Output Contract — Phase: --e2e`.
- `browser-agent`: `### Output Contract — Phase: reproduce` AND `### Output Contract — Phase: verify`.
- `spec-reviewer`: `### Output Contract — Default (review mode)` AND `### Output Contract — Phase: --verify`.

**Assertion logic:**
1. For each of the 4 polymorphic agent names, extract content of `## Output Contract` section.
2. Assert both expected H3 sub-block headings appear (literal grep).

### 3.5 `v9-xref-outputs-skill-references.sh`

**Purpose:** Operational-ROI center. Implements the new Cross-File Invariant (REQ-H-060). For every backtick-quoted `## Heading` in any agent's Outputs table, assert it appears in at least one `skills/**/SKILL.md` or `skills/**/steps/*.md` file.

**No SKIP-guard.** If zero declarations exist, scenario reports `0 declarations, 0 references checked` and PASSES.

**Assertion logic:**
1. For each agent file: extract `## Output Contract` section content.
2. Within that, extract every backtick-quoted heading via `grep -oE '\`## [A-Za-z][A-Za-z _-]*\`'`.
3. Strip backticks → produce a literal heading like `## Fix Report`.
4. For each extracted heading, run `grep -rl -F "$heading" skills/`. If no match: FAIL with `{agent}: declared {heading} not referenced in any skill`.

**Known intentional exclusions:** Headings starting with `## NEEDS_` (NEEDS_CLARIFICATION, NEEDS_DECOMPOSITION) and `## Output Contract` itself are EXCLUDED from the xref requirement — they are agent-internal signal sentinels, the latter is a metadata heading. The scenario filters these via `grep -v '^\`## NEEDS_\|^\`## Output Contract\`'` before running the xref grep.

### 3.6 `v9-agents-must-be-dispatched.sh`

**Purpose:** Prevent future orphan agents (REQ-H-035). Resolves the stack-selector orphan defect at the lint level.

**No SKIP-guard.** If the agents directory is empty, FAIL.

**Assertion logic:**
1. Enumerate every `agents/*.md` file. Extract `name:` frontmatter value.
2. For each agent name, run `grep -rl -F "subagent_type='ceos-agents:${name}'" skills/`. If no match: FAIL with `agent {name} is not dispatched by any skill — orphan`.
3. After REQ-H-080 + REQ-H-090 implementation, all 17 remaining agents PASS this scenario.

### 3.7 Updates to existing scenarios (REQ-H-036..H-038)

**`tests/scenarios/section-order.sh`:**
- Replace `AGENTS=(...)` array with the post-v9 17-name array: `acceptance-gate analyst architect backlog-creator browser-agent deployment-verifier fixer priority-engine publisher reviewer rollback-agent scaffolder spec-analyst spec-reviewer spec-writer sprint-planner test-engineer`.
- After current section-order check (Goal → Expertise → Process → Constraints), add an OPTIONAL position assertion: if `## Output Contract` line exists, assert `process_line < output_contract_line < constraints_line`.

**`tests/scenarios/frontmatter-completeness.sh`:** replace `AGENTS=(...)` with the same 17-name array.

**`tests/scenarios/read-only-agents.sh`:** replace `READ_ONLY_AGENTS=(...)` with: `analyst reviewer spec-analyst architect priority-engine spec-reviewer acceptance-gate backlog-creator sprint-planner` (9 agents — drops triage-analyst, code-analyst, stack-selector; adds analyst). Update header comment + final PASS message accordingly.

---

## Section 4 — stack-selector resolution (REQ-H-080)

**Decision:** delete `agents/stack-selector.md` AND clean up the `skills/scaffold/SKILL.md:91` legacy-flow text.

**Justification:**
1. **Zero actual dispatches** in `skills/**/*.md`. The grep `subagent_type='ceos-agents:stack-selector'` returns no matches across all skill files. The agent has been orphaned since the scaffold v2 transition.
2. **scaffolder subsumes the function.** `agents/scaffolder.md:22-24` reads Tech Stack directly from `spec/README.md` in scaffold v2 mode. No agent-level stack selection is performed.
3. **The `--no-implement` flow** (legacy v3.x behavior) referenced in `skills/scaffold/SKILL.md:91` mentions `stack-selector` in prose but does not invoke it via `Task(subagent_type=...)`. The fix: rewrite line 91 to reference scaffolder-direct invocation in `--no-implement` mode (scaffolder reads stack from skill-supplied flags or from a minimal user prompt).
4. **rollback-agent skip list** (`agents/rollback-agent.md:25`) currently lists `stack-selector` among read-only blocking agents that don't need rollback. After deletion, the entry is removed.
5. **Lint scenario** `v9-agents-must-be-dispatched.sh` (REQ-H-081) prevents recurrence.

**Phase 7 task list:**
- Delete `agents/stack-selector.md`.
- Edit `skills/scaffold/SKILL.md:91` — replace the prose `stack-selector → scaffolder → ...` chain with `scaffolder (with stack flags) → validate → ...`.
- Edit `agents/rollback-agent.md:25` — remove `stack-selector` from the read-only-blocking-agent skip list.
- Update `agents/scaffolder.md:22-24` — clarify behavior when `spec/` is absent (fallback to skill-supplied flags); no functional change, just documentation.
- Update CLAUDE.md agent enumeration (line 35) — list 17 agents.
- Update `docs/reference/agents.md` (if it enumerates 18) and `docs/architecture.md` agent count to 17.

---

## Section 5 — Dual dispatch idiom harmonization (REQ-H-090)

**Decision:** Harmonize all skill-side agent dispatches to the strict idiom `Task(subagent_type='ceos-agents:{name}', model='{tier}')`. Remove the prose form `Run ceos-agents:{name} (Task tool, model: {tier})` everywhere it occurs.

**Justification:**
1. **PostToolUse hook validation surface.** The PostToolUse hook validates the strict idiom. The 4 prose-idiom skills (`create-backlog`, `prioritize`, `sprint-plan`, plus `scaffold-add` and `check-deploy` and `publish` per Phase 3 grep) are NOT validated — drift goes undetected.
2. **Idiom variance is cognitive load.** Two idioms in the same plugin = downstream skill authors guess which is "correct."
3. **Backward-compat preserved either way** (gate-decision `phase_4_spec_mandate[9]`). Choosing strict is the cleanup path.

**Phase 7 grep targets (lines identified during Phase 4 inventory):**

| File | Current line | Target rewrite |
|------|--------------|----------------|
| `skills/check-deploy/SKILL.md:66,79` | `Dispatch ceos-agents:deployment-verifier (Task tool, model: sonnet)` | `Task(subagent_type='ceos-agents:deployment-verifier', model='sonnet')` |
| `skills/create-backlog/SKILL.md:103,326` | `Run ceos-agents:backlog-creator (Task tool, model: sonnet)` and `Run the architect agent (Task tool, model: opus)` | strict-idiom equivalents |
| `skills/sprint-plan/SKILL.md:119,137` | `Run ceos-agents:priority-engine ...`, `Run ceos-agents:sprint-planner ...` | strict-idiom equivalents |
| `skills/prioritize/SKILL.md:38` | `Run ceos-agents:priority-engine (Task tool, model: opus)` | `Task(subagent_type='ceos-agents:priority-engine', model='opus')` |
| `skills/scaffold-add/SKILL.md:58` | `Run the scaffolder agent (Task tool, model: sonnet)` | strict-idiom equivalent |
| `skills/publish/SKILL.md:208` | ``Run `ceos-agents:publisher` (Task tool, model: `haiku`)`` | strict-idiom equivalent |

After Phase 7: `grep -rE 'Run \`?ceos-agents:[a-z-]+\`?\s*\(Task tool' skills/` returns ZERO matches.

---

## Section 6 — CLAUDE.md amendments (verbatim text)

### 6.1 Versioning Policy amendment (REQ-H-050, REQ-H-051)

**Edit target:** `CLAUDE.md:239-247` (the existing Versioning Policy section).

**Old MAJOR row text:**
> Breaking change in Automation Config contract — new required key, renamed section — OR breaking change in agent output format contract (new/modified structured output sections that Agent Overrides or external tooling may parse)

**New MAJOR row text:**
> Breaking change in Automation Config contract — new required key, renamed section — OR breaking change in agent output format contract (new/modified structured output sections that Agent Overrides or external tooling may parse) — OR introduction of a mandatory new structured contract section in agent definition files that v8.0.0 agents would fail validation against

**New MAJOR row examples cell:**
> New required key in Issue Tracker; new output section in analyst; mandatory `## Output Contract` (v9.0.0)

**Append immediately AFTER the table** (new paragraph, after the existing `Key rule:` line):

> Adding new static declaration sections to agent definition files (`## Output Contract`, `## Inputs`, `## Outputs`, or similar metadata blocks) that are not enforced at runtime classifies as MINOR when the section is OPTIONAL (consuming-project agent files without it remain valid against the harness) and MAJOR when the section is MANDATORY (agent files without it fail at least one harness scenario). The override injector at `core/agent-override-injector.md` is structure-blind and is not "external tooling that parses" agent body sections — its append-only behavior does not fire the MAJOR clause on its own.

### 6.2 Cross-File Invariants amendment (REQ-H-060, REQ-H-061)

**Edit target:** `CLAUDE.md:249-257` (the existing 3-invariant Cross-File Invariants section).

**Insert after invariant 3, before the `See \`feedback_doc_completeness.md\` ...` paragraph:**

> 4. **Agent Output Contract ↔ skill xref consistency** — every backtick-quoted `## Heading` declared in any agent's `## Output Contract` Outputs table (e.g., `` `## Fix Report` ``, `` `## Code Review` ``, `` `## Triage Analysis` ``) MUST be referenced literally (modulo backticks) in at least one file under `skills/**/SKILL.md` or `skills/**/steps/*.md`. Verify via `tests/scenarios/v9-xref-outputs-skill-references.sh`. Headings starting with `## NEEDS_` (sentinel signals) and `## Output Contract` itself are excluded from this requirement.

### 6.3 "Agents (specialists — HOW to do it):" enumeration update

**Edit target:** `CLAUDE.md:35`.

**Old line text** (current):
> **Agents** (specialists — HOW to do it): acceptance-gate, analyst, architect, backlog-creator, browser-agent, deployment-verifier, fixer, priority-engine, publisher, reviewer, rollback-agent, scaffolder, spec-analyst, spec-reviewer, spec-writer, sprint-planner, stack-selector, test-engineer

**New line text** (delete stack-selector):
> **Agents** (specialists — HOW to do it): acceptance-gate, analyst, architect, backlog-creator, browser-agent, deployment-verifier, fixer, priority-engine, publisher, reviewer, rollback-agent, scaffolder, spec-analyst, spec-reviewer, spec-writer, sprint-planner, test-engineer

### 6.4 Agent count drift updates (NFR-DOC-001)

Same 18 → 17 update propagates to:
- `README.md` (any agent count or enumeration)
- `docs/reference/agents.md`
- `docs/architecture.md` (agent count fields)
- `docs/reference/automation-config.md` (any agent count cross-reference)
- `docs/reference/skills.md` (skills still 29; if it cross-references agents → 17)

The exact line locations are inventoried in Phase 6 plan tasks.

---

## Section 7 — `docs/guides/migration-v8-to-v9.md` content (REQ-H-070..H-074)

```markdown
# Migration Guide: v8.0.0 → v9.0.0

## Overview

v9.0.0 is a MAJOR release bundling three deliverables:

1. **Sub-projekt H — Agent I/O Contracts** (this release's headline change). Every agent definition under `agents/*.md` now declares its inputs and outputs in a mandatory `## Output Contract` section between `## Process` and `## Constraints`. The contract documents the de-facto section headings and signal sentinels skills already grep against today (e.g., `## Fix Report`, `## NEEDS_DECOMPOSITION`, `## Triage Analysis`); it does not change agent runtime behavior. Validation is author-time lint only via `tests/scenarios/v9-output-contract-*.sh` — there is no runtime schema validator, no JSON Schema sidecar, no LLM self-validation.
2. **Pre-announced `.md` agent overlay hard removal.** Per `docs/guides/migration-v7-to-v8.md:445-454`, v8.0.0 emitted `[WARN]` on `customization/{agent}.md` overlays. v9.0.0 emits `[ERROR]` and refuses dispatch — TOML-only is the supported override format.
3. **Pre-announced deprecated agent name hard errors.** Dispatching `ceos-agents:triage-analyst|code-analyst|e2e-test-engineer|reproducer|browser-verifier` returns `[ERROR]` instead of `[WARN]`. Use the v8 consolidated names: `analyst`, `test-engineer`, `browser-agent`.

The agent count moves from 18 → 17 in v9.0.0 — `agents/stack-selector.md` is deleted as a dead-code cleanup. Stack selection is now performed entirely by the scaffolder agent (which reads Tech Stack from `spec/README.md` in scaffold v2 mode or from skill-supplied flags in `--no-implement` mode).

## Breaking Changes

1. **Mandatory `## Output Contract` section in every agent file.** Plugin-internal change. Consuming projects do not need to modify any file.
2. **`.md` agent overlays no longer dispatched.** If your `customization/` directory still contains `{agent}.md` files, they are now ignored with `[ERROR]`. Migrate to TOML overlays per `docs/guides/migration-v7-to-v8.md`.
3. **Deprecated agent names hard-fail.** If your project's CLAUDE.md, hooks, or custom skills reference `triage-analyst`, `code-analyst`, `e2e-test-engineer`, `reproducer`, or `browser-verifier`, rename them now to: `analyst`, `analyst`, `test-engineer` (use `--e2e` flag), `browser-agent` (use `--phase reproduce`), `browser-agent` (use `--phase verify`) respectively.
4. **`agents/stack-selector.md` deleted.** If your project's CLAUDE.md, hooks, or custom skills reference `ceos-agents:stack-selector`, remove the reference. The scaffolder agent now subsumes stack selection.

## Migration Steps

### Step 1 — Override files (zero-touch)
Your `customization/{agent}.md` files keep working unchanged. The override injector at `core/agent-override-injector.md` is append-only and structure-blind — it appends override content as `## Project-Specific Instructions` regardless of new sections in the base agent file.

If you want to **inspect** for accidental heading collisions:

```bash
grep -lE '^## (Output Contract|Project-Specific Instructions)' customization/*.md 2>/dev/null && echo "WARN: heading collision risk" || echo "OK: no collision"
```

(See "Compatibility Check" below.) A collision does not block injection; it only creates a duplicate-section visual artifact in the resolved agent context. Resolve by renaming the override section to a project-specific heading (e.g., `## My Project Override`).

### Step 2 — Hooks and custom skills (rename + delete)

Search your project's CLAUDE.md, `customization/`, and any custom skill files for the deprecated tokens:

```bash
grep -rE 'ceos-agents:(triage-analyst|code-analyst|e2e-test-engineer|reproducer|browser-verifier|stack-selector)' .
```

For each match:
- `triage-analyst` or `code-analyst` → replace with `analyst` (add `--phase triage` or `--phase impact` accordingly).
- `e2e-test-engineer` → replace with `test-engineer` and add `--e2e` flag.
- `reproducer` → replace with `browser-agent` and add `--phase reproduce` flag.
- `browser-verifier` → replace with `browser-agent` and add `--phase verify` flag.
- `stack-selector` → delete the reference (the scaffolder handles stack selection).

### Step 3 — TOML overlay migration (if `.md` overlays exist)

If `ls customization/*.md` returns files (other than the skip — README.md, etc.), migrate each to TOML:
1. Create `customization/{agent}.toml` with the equivalent content using the `[[process_additions]]` and `[[constraints]]` block format documented in `examples/customization/reviewer-strict-security.toml`.
2. Delete the `.md` file (or move to backup).
3. Re-run `/ceos-agents:check-setup` — it should report no `[ERROR]` overlays.

### Step 4 — Optional: external parsers of agent body content

If your project parses agent body content externally (rare — most projects only use the override injector), expect a `## Output Contract` section between `## Process` and `## Constraints` in every agent file. The section content is documented in `docs/reference/agents.md` (per-agent contract).

## Compatibility Check

Run this before upgrading to confirm your project is migration-ready:

```bash
# Test 1 — no .md overlays remaining
ls customization/*.md 2>/dev/null | grep -v README.md && \
  echo "FAIL: .md overlays found — migrate to .toml first" || \
  echo "OK: no .md overlays"

# Test 2 — no deprecated agent name references
grep -rE 'ceos-agents:(triage-analyst|code-analyst|e2e-test-engineer|reproducer|browser-verifier|stack-selector)' . \
  --include='*.md' --include='*.toml' && \
  echo "FAIL: deprecated agent names found — rename per Step 2" || \
  echo "OK: no deprecated agent names"

# Test 3 — heading collision check on overrides
grep -lE '^## (Output Contract|Project-Specific Instructions)' customization/*.md 2>/dev/null && \
  echo "WARN: heading collision risk — see Step 1" || \
  echo "OK: no collision"
```

All three should output OK before running `/ceos-agents:version-bump 9.0.0`.
```

---

## Section 8 — Backward-compatibility verification protocol (NFR-COMPAT-002)

**Goal:** Empirically confirm that the override injector flow against a v9.0.0 agent file produces semantically-identical behavior to v8.0.0, except for the additional `## Output Contract` section being visible to the model.

**Protocol — repeatable test:**

1. **Take fixture.** `examples/customization/reviewer-strict-security.toml` (TOML overlay, ~26 lines) and `examples/agent-overrides/codegraph/architect.md` (markdown overlay, free prose).
2. **Simulate injection — v8.0.0 baseline.** Apply `core/agent-override-injector.md` Process steps 1-5 against the v8.0.0 reviewer.md. Capture the resolved agent context as `bc-fixture-v8-reviewer.txt`.
3. **Simulate injection — v9.0.0 candidate.** Apply the same injector Process steps against the v9.0.0 reviewer.md (same content + new `## Output Contract` section between Process and Constraints). Capture as `bc-fixture-v9-reviewer.txt`.
4. **Diff.** `diff -u bc-fixture-v8-reviewer.txt bc-fixture-v9-reviewer.txt`. Expected diff = exactly the `## Output Contract` section content; everything else (Goal, Expertise, Process, Constraints, appended `## Project-Specific Instructions`) byte-identical.
5. **Repeat for `architect.md` overlay.** Same expected diff: only the new `## Output Contract` section in architect, no other change.

**Pass criterion:** The diff contains lines added in the `## Output Contract` block ONLY. The `## Project-Specific Instructions` block is byte-identical pre/post. No content from the v8 base agent body is removed.

**Phase 7 implementation note:** This protocol is documented as a manual check in `docs/guides/migration-v8-to-v9.md` (REQ-H-074 Compatibility Check) but does NOT need a dedicated bash scenario — the injector is provably append-only by code inspection (`core/agent-override-injector.md:18-22`). The protocol is the audit trail.

---

## Section 9 — Decomposition guidance for Phase 6 plan

Phase 6 should decompose this spec into the following task tiers (atomic units the fixer can implement in ≤100 line diffs each):

### Tier A — Foundation (no agent-file changes; can run in parallel)

- **A1.** Edit `CLAUDE.md` Versioning Policy section per design.md §6.1.
- **A2.** Edit `CLAUDE.md` Cross-File Invariants per design.md §6.2.
- **A3.** Edit `CLAUDE.md:35` agent enumeration per design.md §6.3.
- **A4.** Update doc-count drift fields in README.md, docs/reference/agents.md, docs/architecture.md, docs/reference/automation-config.md, docs/reference/skills.md (NFR-DOC-001) — 5 separate file edits.
- **A5.** Create `docs/guides/migration-v8-to-v9.md` per design.md §7.

### Tier B — Test infrastructure (depends on Tier A for invariant text references)

- **B1.** Update `tests/scenarios/section-order.sh` per REQ-H-036 (post-v9 17-name array + optional position assertion).
- **B2.** Update `tests/scenarios/frontmatter-completeness.sh` per REQ-H-037.
- **B3.** Update `tests/scenarios/read-only-agents.sh` per REQ-H-038.
- **B4.** Create `tests/scenarios/v9-output-contract-shape.sh`.
- **B5.** Create `tests/scenarios/v9-output-contract-completeness.sh`.
- **B6.** Create `tests/scenarios/v9-output-contract-position.sh`.
- **B7.** Create `tests/scenarios/v9-output-contract-polymorphic-split.sh`.
- **B8.** Create `tests/scenarios/v9-xref-outputs-skill-references.sh`.
- **B9.** Create `tests/scenarios/v9-agents-must-be-dispatched.sh`.

After B5 runs, the harness will fail until Tier C completes — that's expected (TDD red phase).

### Tier C — Per-agent Output Contract additions (parallelizable)

One task per agent (17 tasks; stack-selector is deleted in Tier D not added):
- **C1.** acceptance-gate.md — add `## Output Contract` per design.md §2.1.
- **C2.** analyst.md — add polymorphic `## Output Contract` per design.md §2.2.
- **C3.** architect.md — design.md §2.3.
- **C4.** backlog-creator.md — design.md §2.4.
- **C5.** browser-agent.md — polymorphic per design.md §2.5.
- **C6.** deployment-verifier.md — design.md §2.6.
- **C7.** fixer.md — design.md §2.7.
- **C8.** priority-engine.md — design.md §2.8.
- **C9.** publisher.md — design.md §2.9.
- **C10.** reviewer.md — design.md §2.10.
- **C11.** rollback-agent.md — design.md §2.11.
- **C12.** scaffolder.md — design.md §2.12.
- **C13.** spec-analyst.md — design.md §2.13.
- **C14.** spec-reviewer.md — polymorphic per design.md §2.14.
- **C15.** spec-writer.md — design.md §2.15.
- **C16.** sprint-planner.md — design.md §2.16.
- **C17.** test-engineer.md — polymorphic per design.md §2.18.

Each is a strict additive edit between Process and Constraints sections — fixer's 100-line diff limit is comfortable (typical Output Contract is 15-30 lines per agent).

### Tier D — Cleanup (REQ-H-080..H-083, REQ-H-090)

- **D1.** Delete `agents/stack-selector.md`.
- **D2.** Edit `skills/scaffold/SKILL.md:91` to remove stack-selector reference.
- **D3.** Edit `agents/rollback-agent.md:25` to remove `stack-selector` from skip list.
- **D4.** Harmonize 4-6 prose dispatch idiom occurrences to strict idiom across `skills/check-deploy/`, `skills/create-backlog/`, `skills/sprint-plan/`, `skills/prioritize/`, `skills/scaffold-add/`, `skills/publish/` (REQ-H-090).

### Tier E — Release (depends on Tier A-D complete + tests green)

- **E1.** Add CHANGELOG.md v9.0.0 entry per REQ-H-041.
- **E2.** Update `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` `version: 9.0.0` (executed via `/ceos-agents:version-bump 9.0.0`).
- **E3.** Run full `tests/harness/run-tests.sh` — assert all v9 scenarios PASS, all v8 scenarios PASS, no regressions.
- **E4.** Tag commit as `v9.0.0`.

### Parallelization opportunities

- Tier A items A1-A5 are independent — run in parallel (5-way).
- Tier B items B1-B9 are independent — run in parallel (9-way).
- Tier C items C1-C17 are independent — run in parallel (17-way).
- Tier D items D1-D4 are independent — run in parallel (4-way).

Critical path: A → C → E (or B → C → E if test-first), with D inserted before E. Pipeline phase plan can fan-out 17 fixer worktrees for Tier C if forge-execute is invoked, then merge-and-validate.
