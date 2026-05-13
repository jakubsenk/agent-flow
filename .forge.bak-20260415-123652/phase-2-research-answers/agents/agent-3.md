# Research Agent 3 — Test Infrastructure & Roadmap Findings

## TI-1 / TI-2: mcp-newline-handling.sh Full Audit

File: `tests/scenarios/mcp-newline-handling.sh`

### 1. Exact MARKER string
```
NEVER use the literal characters
```

### 2. Exact VULNERABLE_FILES array
```bash
VULNERABLE_FILES=(
  "agents/publisher.md"
  "core/block-handler.md"
  "skills/fix-ticket/SKILL.md"
  "skills/implement-feature/SKILL.md"
  "skills/fix-bugs/SKILL.md"
)
```
5 files total.

### 3. Exact grep command used
```bash
if ! grep -q "$MARKER" "$f"; then
```
(quiet mode, checks for presence of MARKER string in each file)

### 4. Exact PASS/FAIL messages
- FAIL: `"$rel_path missing newline-handling instruction: '$MARKER'"`
- FAIL: `"File not found: $rel_path"`
- PASS: `"PASS: All 5 vulnerable files contain MCP newline-safe output instruction (T-013)"`

### 5. What needs to change for v6.6.0

**Current behavior:** The test checks that the MARKER string `NEVER use the literal characters` is present in each of the 5 vulnerable files directly (per-site instructions).

**Required changes for v6.6.0:**

#### Change A — Skill files: switch from MARKER to contract reference
After v6.6.0, the 5 skill/agent files will no longer contain the literal MARKER. Instead they will reference `core/mcp-body-formatting.md`. The VULNERABLE_FILES list for skill/agent files should be replaced with a check that each file contains the string `core/mcp-body-formatting.md` (a reference to the contract).

New marker for skill/agent files: `core/mcp-body-formatting.md`

Files that need the reference check (instead of MARKER check):
- `agents/publisher.md`
- `core/block-handler.md`
- `skills/fix-ticket/SKILL.md`
- `skills/implement-feature/SKILL.md`
- `skills/fix-bugs/SKILL.md`

#### Change B — NEW check: contract file itself contains the NEVER rule
A new separate check must verify that `core/mcp-body-formatting.md` itself contains the original MARKER string (`NEVER use the literal characters`). This ensures the contract file holds the actual rule.

**Summary of test changes needed:**
1. Replace the current single-marker check loop with TWO checks:
   - Loop over skill/agent files checking for `core/mcp-body-formatting.md` reference
   - Single check that `core/mcp-body-formatting.md` contains `NEVER use the literal characters`
2. Update the PASS message to reflect the new count/logic (6 files: 1 contract + 5 references, or similar)

---

## TI-3: xref-core-registry.sh Full Audit

File: `tests/scenarios/xref-core-registry.sh`

### 1. How it counts core files
Uses dynamic discovery — NOT a hardcoded list:
```bash
mapfile -t CORE_FILES < <(ls "$CORE_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | sort)
```
It lists all `*.md` files in `core/`, strips the `.md` extension, sorts alphabetically, and stores as an array. Count = `${#CORE_FILES[@]}`.

### 2. How it checks CLAUDE.md count
Extracts a number from the line in CLAUDE.md that mentions `core/` and "shared":
```bash
CLAIMED=$(grep '`core/`' "$CLAUDE_MD" | grep 'shared' | grep -oE '[0-9]+' | head -1)
```
Then compares: `if [ "$CLAIMED" -ne "$FS_COUNT" ]`

CLAUDE.md must contain a line matching the pattern:
`` `core/` — N shared pipeline pattern contracts ``

### 3. Whether adding a new core file requires test changes
**The test itself does NOT need code changes** — it is fully dynamic. However, two things must happen:

1. **CLAUDE.md must be updated**: The count in the line `` `core/` — 12 shared pipeline pattern contracts `` must be incremented to match the new filesystem count.
2. **The new core file must be referenced by at least one skill**: The test also verifies that every core file is referenced (by `core/{name}`) in at least one `skills/*/SKILL.md` file. A new core file with no skill reference will cause a FAIL.

Adding `core/mcp-body-formatting.md` for v6.6.0 therefore requires:
- Update CLAUDE.md count from 12 → 13
- Ensure at least one skill references `core/mcp-body-formatting.md`

---

## Core File Count Verification

**Actual files in `core/` (12 files):**
1. `agent-override-injector.md`
2. `block-handler.md`
3. `config-reader.md`
4. `decomposition-heuristics.md`
5. `fix-verification.md`
6. `fixer-reviewer-loop.md`
7. `mcp-detection.md`
8. `mcp-preflight.md`
9. `post-publish-hook.md`
10. `profile-parser.md`
11. `state-manager.md`
12. `status-verification.md`

**Count: 12. Matches CLAUDE.md claim of 12.**

Note: `core/mcp-body-formatting.md` does NOT yet exist — it is the new file to be created in v6.6.0. After creation, the count will be 13 and CLAUDE.md must be updated accordingly.

---

## Roadmap: v6.6.0 Section

**Current v6.6.0 content** (lines 521–538 in roadmap.md):

Theme: Complete the patterns started in v6.5.2 — extend status verification to all call sites, centralize MCP body formatting, add missing fix-bugs pipeline step.
Source: v6.5.2 deferred items (forge-2026-04-15-001).

### Three planned items:

#### 1. Status Verification — Remaining Call Sites
Wire `core/status-verification.md` into 4 remaining call sites:
- `skills/implement-feature/SKILL.md` Step 1
- `core/fix-verification.md` Step 6
- `skills/fix-bugs/SKILL.md` block handler
- `skills/scaffold/SKILL.md` Step 8b

Files: 4 skill/core files. Impact: PATCH.

#### 2. MCP Body Formatting Contract
Create `core/mcp-body-formatting.md` centralized contract for multi-line MCP tool parameters. Replace per-site NEVER instructions (added in v6.5.2) with single contract references. Prevents the entire class of `\n` literal bugs.
Files: new `core/mcp-body-formatting.md` + 5 files with reference updates. Impact: PATCH.

#### 3. fix-bugs "On start set" Step
Add "Set issue state to In Progress" step at the beginning of the per-issue loop in `skills/fix-bugs/SKILL.md`. Currently fix-bugs is the only pipeline skill that doesn't set issue state on start. Pre-existing functional gap, not a regression.
Files: `skills/fix-bugs/SKILL.md`. Impact: MINOR (drives version number).

### What needs updating post-implementation

After v6.6.0 is implemented, the roadmap entry must be:
1. **Moved** from `PLANNED` to `DONE — v6.6.0` section
2. **Updated** with actual file counts and any deviations from plan
3. **Source line updated** to include the forge run ID (forge-2026-04-15-002 or similar)
4. Any items that were deferred to v6.7.0+ should be noted

The v6.7.0 section (Pipeline Hardening) is already present and is unaffected by v6.6.0 implementation.
