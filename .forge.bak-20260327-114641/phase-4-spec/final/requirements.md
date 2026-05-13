# Requirements — Scaffold Infrastructure Redesign v5.5.0

## File Change Matrix

### 1. `commands/scaffold.md` (CRITICAL)

| # | Change Type | Location | Description |
|---|-------------|----------|-------------|
| 1.1 | ADD | After line 47 ("If state is not 1..."), before `## Orchestration` | Add `### Step 0-INFRA: Infrastructure Declaration` section |
| 1.2 | ADD | After Step 0-INFRA, before `### Step 0: Mode Selection` | Add `### Step 0-MCP: MCP Verification` section |
| 1.3 | ADD | Inside `## Orchestration`, before `### Step 0: Mode Selection` | Add step numbering comment: `<!-- Step numbering: ... -->` |
| 1.4 | MODIFY | `### Step 4: Git Init` (L251-L261) | Extend with auto-fill CLAUDE.md, .mcp.json.example generation, .gitignore update |
| 1.5 | REMOVE | `### Step 4b: Tracker Configuration (Auto-Finalize)` (L263-L298) | Entire section removed — replaced by Step 0-INFRA |
| 1.6 | REMOVE | `### Step 4c: MCP Guidance` (L300-L307) | Entire section removed — replaced by Step 0-MCP |
| 1.7 | ADD | After modified Step 4 | Add `### Step 4d: Push to Remote` section |
| 1.8 | ADD | After Step 4d | Add `### Step 4e: Create Tracker Issues` section |
| 1.9 | REMOVE | `### Step 9: Issue Tracker (Optional)` (L481-L501) | Entire section removed — replaced by Step 4e |
| 1.10 | MODIFY | `### Step 10: Final Report` (L503-L538) | Rename to `### Step 9: Final Report`, add infrastructure status display |
| 1.11 | MODIFY | Step 7 block handler (L443) | Change "jump to Step 10" to "jump to Step 9" |
| 1.12 | MODIFY | Step 7 batch failure (L449) | Change "jump to Step 10" to "jump to Step 9" |
| 1.13 | MODIFY | `## MCP Pre-flight Check` (L540-L551) | Complete rewrite — reference Step 0-MCP, remove Step 9 reference |
| 1.14 | MODIFY | `### --no-implement Legacy Flow` L5 (L116-L125) | Add L5b: Push to Remote if SC=ready |
| 1.15 | MODIFY | `### --no-implement Legacy Flow` L6 (L127-L147) | Add conditional next steps based on infrastructure status |
| 1.16 | MODIFY | `## Rules` section (L553-L567) | Update scaffolder CLAUDE.md rule to reference Step 0-INFRA in-memory state |
| 1.17 | MODIFY | `### Step 0: Mode Selection` (L51-L66) | Move `--no-implement` exit to after 0-INFRA/0-MCP have run |

### 2. `CLAUDE.md`

| # | Change Type | Location | Description |
|---|-------------|----------|-------------|
| 2.1 | MODIFY | `## Scaffold Pipeline` (lines 63-76) | Update ASCII diagram to include 0-INFRA, 0-MCP, 4d, 4e |

### 3. `README.md`

| # | Change Type | Location | Description |
|---|-------------|----------|-------------|
| 3.1 | MODIFY | Scaffold Pipeline mermaid diagram (lines 112-124) | Add Infra node between Desc and Mode; add Push+Issues nodes after Git |

### 4. `docs/architecture.md`

| # | Change Type | Location | Description |
|---|-------------|----------|-------------|
| 4.1 | MODIFY | Scaffold Pipeline `graph LR` (lines 118-127) | Add Infrastructure Declaration node; add Push + Issues nodes after Git init |

### 5. `docs/reference/pipelines.md`

| # | Change Type | Location | Description |
|---|-------------|----------|-------------|
| 5.1 | MODIFY | Scaffold v2 Mermaid diagram (lines 208-265) | Add INFRA_DECL node; add PUSH/CREATE_ISSUES nodes; remove TRACKER node |
| 5.2 | MODIFY | Scaffold Stages table (lines 269-281) | Add 0-INFRA, 0-MCP, 4d, 4e rows; remove Step 9 row; renumber Step 10 to 9 |

### 6. `docs/reference/commands.md`

| # | Change Type | Location | Description |
|---|-------------|----------|-------------|
| 6.1 | MODIFY | `/scaffold` "What it does" paragraph (line 219) | Add infrastructure declaration mention; note --issue auto-detect behavior |

### 7. `CHANGELOG.md`

| # | Change Type | Location | Description |
|---|-------------|----------|-------------|
| 7.1 | ADD | Before `## [5.4.1]` entry | Add complete v5.5.0 entry |

### 8. `tests/scenarios/scaffold-v2-happy-path.sh`

| # | Change Type | Location | Description |
|---|-------------|----------|-------------|
| 8.1 | ADD | After existing assertions | Add assertions for Step 0-INFRA, 0-MCP, 4d, 4e presence |
| 8.2 | ADD | After existing assertions | Add regression guards: Step 4b, 4c, "Step 9: Issue Tracker" absent |
| 8.3 | ADD | After existing assertions | Add ordering assertion: 0-INFRA before Mode Selection |

### 9. `tests/scenarios/scaffold-v2-no-implement.sh`

| # | Change Type | Location | Description |
|---|-------------|----------|-------------|
| 9.1 | ADD | After existing assertions | Add assertion for Step 0-INFRA presence |

### 10. `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json`

| # | Change Type | Location | Description |
|---|-------------|----------|-------------|
| 10.1 | MODIFY | `"version"` field | Bump 5.4.1 to 5.5.0 |

## Files Confirmed Unchanged

- All 19 agent files in `agents/`
- `commands/init.md` (no changes — scaffold replicates MCP subset inline)
- `checklists/`, `core/`, `state/`, `examples/`, `docs/guides/`
- `docs/plans/` (historical — read-only)
- `tests/scenarios/scaffold-v2-input-conflicts.sh` (no step-specific assertions affected)
- `tests/scenarios/scaffold-v2-spec-loop.sh` (no step-specific assertions affected)
- `tests/harness/run-tests.sh` (auto-discovers scenarios)
