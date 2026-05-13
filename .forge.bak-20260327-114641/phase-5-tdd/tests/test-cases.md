# Test Cases — Scaffold Infrastructure Integration (v5.5.0)

**Scope:** `commands/scaffold.md`, `CLAUDE.md`, `README.md`, `docs/architecture.md`,
`docs/reference/pipelines.md`, `docs/reference/commands.md`, `CHANGELOG.md`,
`tests/scenarios/scaffold-v2-happy-path.sh`, `tests/scenarios/scaffold-v2-no-implement.sh`,
`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`

**Total test cases:** 28 (T01–T28)

---

## Category 1: Removal Verification

### T01: Step 4b heading absent from scaffold.md
- **Priority:** P0
- **Category:** 1
- **Assertion:** `grep -q "Step 4b" commands/scaffold.md` → NO_MATCH
- **Scope exclusion:** CHANGELOG.md and docs/plans/ permitted to retain historical references
- **Rationale:** Step 4b (Tracker Configuration Auto-Finalize) was entirely removed and replaced by Step 0-INFRA. Any surviving heading indicates an incomplete removal.

### T02: Step 4b absent from all non-plan, non-changelog files
- **Priority:** P0
- **Category:** 1
- **Assertion:** `grep -rq "Step 4b" commands/ docs/ CLAUDE.md README.md tests/ --include="*.md" --include="*.sh"` → NO_MATCH
- **Scope exclusion:** CHANGELOG.md and docs/plans/ are excluded from this check
- **Rationale:** Ensures no reference leaks into doc files, pipelines reference tables, or test scripts.

### T03: Step 4c heading absent from scaffold.md
- **Priority:** P0
- **Category:** 1
- **Assertion:** `grep -q "Step 4c" commands/scaffold.md` → NO_MATCH
- **Scope exclusion:** CHANGELOG.md and docs/plans/ permitted
- **Rationale:** Step 4c (MCP Guidance) was removed and superseded by Step 0-MCP. A surviving heading would create a phantom step.

### T04: "Auto-Finalize" label absent from all non-plan files
- **Priority:** P1
- **Category:** 1
- **Assertion:** `grep -rq "Auto-Finalize" commands/ docs/ CLAUDE.md README.md tests/ --include="*.md" --include="*.sh"` → NO_MATCH
- **Scope exclusion:** CHANGELOG.md and docs/plans/ permitted
- **Rationale:** The subtitle "Tracker Configuration (Auto-Finalize)" must not appear anywhere outside historical records; even a partial match would confuse pipeline readers.

### T05: "MCP Guidance" as step label absent from all non-plan files
- **Priority:** P1
- **Category:** 1
- **Assertion:** `grep -rq "MCP Guidance" commands/ docs/ CLAUDE.md README.md tests/ --include="*.md" --include="*.sh"` → NO_MATCH
- **Scope exclusion:** CHANGELOG.md and docs/plans/ permitted
- **Rationale:** "MCP Guidance" was the old step name; Step 0-MCP is the replacement. Any lingering reference would be stale.

### T06: "Step 9: Issue Tracker" absent from all non-plan files
- **Priority:** P0
- **Category:** 1
- **Assertion:** `grep -rq "Step 9: Issue Tracker" commands/ docs/ CLAUDE.md README.md tests/ --include="*.md" --include="*.sh"` → NO_MATCH
- **Scope exclusion:** CHANGELOG.md and docs/plans/ permitted
- **Rationale:** Old Step 9 was the optional Issue Tracker step; it was removed entirely and replaced by Step 4e. Any survivor breaks the renumbered pipeline.

### T07: "Step 10" absent from all non-plan files
- **Priority:** P0
- **Category:** 1
- **Assertion:** `grep -rq "Step 10" commands/ docs/ CLAUDE.md README.md tests/ --include="*.md" --include="*.sh"` → NO_MATCH
- **Scope exclusion:** CHANGELOG.md and docs/plans/ permitted
- **Rationale:** The old Step 10 (Final Report) was renumbered to Step 9. Zero occurrences must survive in any living file — including "jump to Step 10" inline references inside scaffold.md (requirements 1.11, 1.12).

---

## Category 2: Addition Verification

### T08: Step 0-INFRA heading present in scaffold.md
- **Priority:** P0
- **Category:** 2
- **Assertion:** `grep -q "Step 0-INFRA: Infrastructure Declaration" commands/scaffold.md` → MATCH
- **Rationale:** Step 0-INFRA is the central new step collecting infrastructure state before any mode branch. Its heading must exist exactly as specified.

### T09: Step 0-MCP heading present in scaffold.md
- **Priority:** P0
- **Category:** 2
- **Assertion:** `grep -q "Step 0-MCP: MCP Verification" commands/scaffold.md` → MATCH
- **Rationale:** Step 0-MCP replaces the old Step 4c MCP Guidance block and must appear as an independent pre-mode step.

### T10: Step 4d heading present in scaffold.md
- **Priority:** P0
- **Category:** 2
- **Assertion:** `grep -q "Step 4d: Push to Remote" commands/scaffold.md` → MATCH
- **Rationale:** Step 4d handles pushing the new project to the remote after Git init. Its absence would leave the push behavior undefined.

### T11: Step 4e heading present in scaffold.md
- **Priority:** P0
- **Category:** 2
- **Assertion:** `grep -q "Step 4e: Create Tracker Issues" commands/scaffold.md` → MATCH
- **Rationale:** Step 4e replaces old Step 9 optional tracker issue creation and must be present immediately after 4d.

### T12: Step 0-INFRA appears before Step 0 in scaffold.md
- **Priority:** P0
- **Category:** 2
- **Assertion:** Line number of `Step 0-INFRA` < line number of `### Step 0: Mode Selection` in `commands/scaffold.md` → MATCH (ordering)
- **Rationale:** Infrastructure state must be collected before mode selection so all downstream branches can read the in-memory values. If 0-INFRA appears after Step 0, the --no-implement flow would miss infrastructure detection.

### T13: 0-MCP appears between 0-INFRA and Step 0 in scaffold.md
- **Priority:** P1
- **Category:** 2
- **Assertion:** Line number of `Step 0-MCP` > line number of `Step 0-INFRA` AND < line number of `### Step 0: Mode Selection` → MATCH (ordering)
- **Rationale:** MCP Verification depends on infrastructure state captured in 0-INFRA and must complete before mode branching begins.

### T14: pipelines.md stages table contains 0-INFRA and 0-MCP rows
- **Priority:** P0
- **Category:** 2
- **Assertion:** `grep -q "0-INFRA" docs/reference/pipelines.md && grep -q "0-MCP" docs/reference/pipelines.md` → MATCH
- **Rationale:** The stages table in pipelines.md is the authoritative cross-reference for all scaffold steps. Missing rows leave the reference doc out of sync.

### T15: pipelines.md stages table contains 4d and 4e rows
- **Priority:** P0
- **Category:** 2
- **Assertion:** `grep -q "4d" docs/reference/pipelines.md && grep -q "4e" docs/reference/pipelines.md` → MATCH
- **Rationale:** Steps 4d and 4e are new pipeline stages; their absence from the stages table means downstream users cannot discover them through the reference docs.

### T16: INFRA_DECL node present in pipelines.md Mermaid diagram
- **Priority:** P0
- **Category:** 2
- **Assertion:** `grep -q "INFRA_DECL" docs/reference/pipelines.md` → MATCH
- **Rationale:** The Mermaid diagram is the visual representation of the pipeline; the infrastructure node must appear as `INFRA_DECL[Infrastructure Declaration` per requirement 5.1.

### T17: MCP_CHECK node present in pipelines.md Mermaid diagram
- **Priority:** P0
- **Category:** 2
- **Assertion:** `grep -q "MCP_CHECK" docs/reference/pipelines.md` → MATCH
- **Rationale:** MCP_CHECK is the Mermaid node for Step 0-MCP; it must appear in the scaffold v2 diagram (formal criterion 3.4).

### T18: PUSH and CREATE_ISSUES nodes present in pipelines.md
- **Priority:** P0
- **Category:** 2
- **Assertion:** `grep -q "PUSH\[Push to Remote" docs/reference/pipelines.md && grep -q "CREATE_ISSUES\[Create Tracker Issues" docs/reference/pipelines.md` → MATCH
- **Rationale:** Steps 4d and 4e have corresponding Mermaid nodes. Their absence means the diagram does not reflect actual pipeline execution order.

---

## Category 3: Modification Verification

### T19: Step 4 heading updated to include "Auto-Config" in scaffold.md
- **Priority:** P1
- **Category:** 3
- **Assertion:** `grep -q "Step 4: Git Init" commands/scaffold.md` → MATCH
- **Rationale:** Requirement 1.4 modifies Step 4 to also handle CLAUDE.md auto-fill, .mcp.json.example generation, and .gitignore update. The heading change (adding "+ Auto-Config") signals this expansion to readers. A plain "Step 4: Git Init" heading (unchanged) would indicate the modification was not applied.

### T20: Step 9 heading is "Final Report" (not Step 10) in scaffold.md
- **Priority:** P0
- **Category:** 3
- **Assertion:** `grep -q "Step 9: Final Report" commands/scaffold.md` → MATCH
- **Rationale:** The Final Report step was renumbered from Step 10 to Step 9 after Step 9 Issue Tracker was removed. This heading must exist at exactly "Step 9" to make the numbering continuous.

### T21: scaffold.md "jump to Step 9" references use Step 9 (not 10)
- **Priority:** P0
- **Category:** 3
- **Assertion:** `grep -q "jump to Step 9" commands/scaffold.md` → MATCH AND `grep -q "jump to Step 10" commands/scaffold.md` → NO_MATCH
- **Rationale:** Requirements 1.11 and 1.12 explicitly change two "jump to Step 10" references inside Step 7 to "jump to Step 9". Both conditions must hold simultaneously.

### T22: Infrastructure status block present in Step 9 of scaffold.md
- **Priority:** P1
- **Category:** 3
- **Assertion:** `grep -A30 "Step 9: Final Report" commands/scaffold.md | grep -q "infrastructure"` → MATCH
- **Rationale:** Requirement 1.10 adds an infrastructure status display to the Final Report step. Without it the report output is incomplete.

### T23: "Infrastructure Declaration" node present in README.md Mermaid
- **Priority:** P0
- **Category:** 3
- **Assertion:** `grep -q "Infrastructure Declaration" README.md` → MATCH
- **Rationale:** Requirement 3.1 adds an Infra node to the README scaffold pipeline diagram. The README is often the first document a new user reads; an outdated diagram undermines trust in the whole pipeline description.

### T24: "Infrastructure Declaration" node present in docs/architecture.md
- **Priority:** P0
- **Category:** 3
- **Assertion:** `grep -q "Infrastructure Declaration" docs/architecture.md` → MATCH
- **Rationale:** Requirement 4.1 updates the architecture.md graph. The architecture doc must stay in sync with the scaffold command or architectural reviews will be based on stale information.

---

## Category 4: Cross-File Consistency

### T25: CLAUDE.md scaffold diagram references 0-INFRA and 0-MCP
- **Priority:** P0
- **Category:** 4
- **Assertion:** `grep -q "0-INFRA" CLAUDE.md && grep -q "0-MCP" CLAUDE.md` → MATCH
- **Rationale:** CLAUDE.md is the plugin's primary orientation document for Claude Code itself. Its scaffold pipeline diagram must include the new pre-mode steps or the assistant will have an incorrect mental model of the pipeline.

### T26: CLAUDE.md scaffold diagram references 4d and 4e
- **Priority:** P0
- **Category:** 4
- **Assertion:** `grep -q "4d" CLAUDE.md && grep -q "4e" CLAUDE.md` → MATCH
- **Rationale:** Formal criterion 5.3 requires both 4d (push) and 4e (tracker issues) labels in the CLAUDE.md diagram. Missing either entry means the diagram skips steps that consume infrastructure state.

### T27: commands.md /scaffold description mentions infrastructure declaration
- **Priority:** P1
- **Category:** 4
- **Assertion:** `grep -A5 "/scaffold" docs/reference/commands.md | grep -qi "infrastructure"` → MATCH
- **Rationale:** Requirement 6.1 updates the commands reference description. Users consulting the reference to understand what /scaffold does must see that infrastructure declaration is part of the process.

### T28: TRACKER node absent from pipelines.md Mermaid diagram
- **Priority:** P0
- **Category:** 4
- **Assertion:** `grep -q "TRACKER" docs/reference/pipelines.md` → NO_MATCH
- **Rationale:** Formal criterion 3.2 requires the TRACKER node (old Step 9 Mermaid representation) to be removed. Its presence would create a dangling diagram node with no corresponding step in scaffold.md.

---

## Category 5: Edge Cases

### T29: --no-implement legacy flow L5b present in scaffold.md
- **Priority:** P1
- **Category:** 5
- **Assertion:** `grep -q "L5b" commands/scaffold.md` → MATCH
- **Rationale:** Requirement 1.14 adds L5b (Push to Remote if SC=ready) to the --no-implement flow. Without it, projects scaffolded with --no-implement never push to the remote even when source control is configured.

### T30: --no-implement legacy flow L6 has conditional infrastructure language
- **Priority:** P1
- **Category:** 5
- **Assertion:** `grep -A10 "L6" commands/scaffold.md | grep -qi "infrastructure"` → MATCH
- **Rationale:** Requirement 1.15 makes L6 conditional on infrastructure status. The conditional language must appear in the --no-implement flow so users get differentiated guidance based on what was detected in Step 0-INFRA.

---

## Category 6: CHANGELOG

### T31: CHANGELOG has v5.5.0 entry
- **Priority:** P0
- **Category:** 6
- **Assertion:** `grep -q "## \[5.5.0\]" CHANGELOG.md` → MATCH
- **Rationale:** Every release must have a changelog entry before tagging. Its absence means the release is undocumented.

### T32: v5.5.0 CHANGELOG entry is labeled MINOR
- **Priority:** P1
- **Category:** 6
- **Assertion:** `grep -A3 "\[5.5.0\]" CHANGELOG.md | grep -qi "minor"` → MATCH
- **Rationale:** Per the versioning policy, adding new optional steps is a MINOR change. An incorrect MAJOR label would trigger unnecessary migration warnings for consumers.

### T33: plugin.json version is 5.5.0
- **Priority:** P0
- **Category:** 6
- **Assertion:** `grep '"version"' .claude-plugin/plugin.json | grep -q "5.5.0"` → MATCH
- **Rationale:** The plugin manifest must match the changelog version. A mismatch means the marketplace advertises the wrong version and consumers cannot detect the update.

### T34: marketplace.json version is 5.5.0
- **Priority:** P0
- **Category:** 6
- **Assertion:** `grep '"version"' .claude-plugin/marketplace.json | grep -q "5.5.0"` → MATCH
- **Rationale:** Same reason as T33; both manifest files must be in sync.

---

## Test Summary

| Priority | Count | Test IDs |
|----------|-------|----------|
| P0 | 20 | T01, T02, T03, T06, T07, T08, T09, T10, T11, T12, T14, T15, T16, T17, T18, T20, T21, T23, T24, T25, T26, T28, T31, T33, T34 |
| P1 | 9 | T04, T05, T13, T19, T22, T27, T29, T30, T32 |

| Category | Count | Test IDs |
|----------|-------|----------|
| 1 — Removal Verification | 7 | T01–T07 |
| 2 — Addition Verification | 11 | T08–T18 |
| 3 — Modification Verification | 6 | T19–T24 |
| 4 — Cross-File Consistency | 4 | T25–T28 |
| 5 — Edge Cases | 2 | T29–T30 |
| 6 — CHANGELOG | 4 | T31–T34 |
