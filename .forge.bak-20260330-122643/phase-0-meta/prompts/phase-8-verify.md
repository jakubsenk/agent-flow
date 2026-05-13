# Phase 8 — Verify

## Context

v5.6.0 — Scaffold Infrastructure Polish has been implemented. All changes are markdown files in a pure markdown plugin. Verification focuses on structural correctness and cross-reference integrity.

## Verification Steps

### 1. Run test suite

```bash
cd /path/to/ceos-agents
./tests/harness/run-tests.sh
```

All tests must pass. If any fail, diagnose and fix.

### 2. New file existence check

Verify `core/mcp-detection.md` exists and contains these required headings:
- `# MCP Detection`
- `## Purpose`
- `## Input Contract`
- `## Process`
- `## Output Contract`
- `## Failure Handling`

### 3. Cross-reference integrity

Verify these references resolve to actual content:

| Source file | Reference | Must exist |
|------------|-----------|------------|
| `commands/scaffold.md` | `core/mcp-detection.md` | Yes (new file) |
| `commands/init.md` | `core/mcp-detection.md` | Yes (new file) |
| `core/mcp-detection.md` | `docs/reference/trackers.md` | Yes (existing) |
| `commands/scaffold.md` | `core/state-manager.md` (infrastructure write) | Yes (existing) |
| `state/schema.md` | `infrastructure` field | Yes (new field) |

### 4. Structural consistency

- `state/schema.md` Full Schema Example JSON is valid JSON (can be parsed)
- `commands/scaffold.md` Flag Parsing includes `--infra`
- `commands/scaffold.md` Flag Validation includes `--infra` format check
- `commands/scaffold.md` Step 0-INFRA mentions `--infra` preset
- `commands/scaffold.md` Step 0-INFRA mentions state persistence
- `commands/scaffold.md` Step 0-MCP mentions `core/mcp-detection.md`
- `commands/scaffold.md` Step 0-MCP mentions canary-write
- `commands/scaffold.md` Step 0-MCP mentions YOLO + --issue block
- `commands/scaffold.md` Step 4e mentions `tracker_write_available`
- `commands/init.md` has Step 1b heading
- `commands/init.md` Step 3 mentions `core/mcp-detection.md`
- `commands/init.md` Step 7 mentions `core/mcp-detection.md`
- `commands/implement-feature.md` Step 0 mentions --yolo + --description MCP block

### 5. Version consistency

- `CHANGELOG.md` has `[5.6.0]` entry
- `docs/plans/roadmap.md` has `DONE — v5.6.0` section
- Core contracts count is 11 in `CLAUDE.md`

### 6. No regressions

- `commands/scaffold.md` still has all original steps (0-INFRA, 0-MCP, 0, 0b, 1-9)
- `commands/init.md` still has all original steps (1-9)
- `commands/implement-feature.md` still has all original steps (0, 0b, 0c, 1-10)
- `core/mcp-preflight.md` is unchanged (different contract — pre-flight vs detection)
- `state/schema.md` still has all existing fields (no removals)

### 7. Semantic correctness

- `--infra` flag does NOT auto-fill tracker type/instance/project — it only pre-answers the ready/later questions
- Canary-write check is NON-BLOCKING — warn + downgrade, never halt
- YOLO + --issue block is BLOCKING — stops scaffold entirely
- `.mcp.json.example` detection in init.md has graceful fallback (no error if file missing)
- Infrastructure state field is OPTIONAL (null default, only scaffold writes it)

## Expected test output

All existing tests pass. If the test suite includes structural checks for:
- Core file headings → `core/mcp-detection.md` must pass
- Cross-references → all new references must resolve
- Flag parsing → `--infra` must appear in scaffold flag list
