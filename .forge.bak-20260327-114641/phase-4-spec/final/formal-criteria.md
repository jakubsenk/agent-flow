# Formal Criteria — Post-Implementation Consistency Checks

These checks MUST pass after all implementation changes are applied. Run each check and fix any violations before considering the implementation complete.

---

## 1. Removed Step References

### 1.1 No remaining "Step 4b" references

```bash
grep -rn "Step 4b" commands/ docs/ CLAUDE.md README.md tests/ --include="*.md" --include="*.sh"
```

**Expected:** Zero matches across all files.
**Exception:** `CHANGELOG.md` and `docs/plans/` may reference Step 4b in historical context.

### 1.2 No remaining "Step 4c" references

```bash
grep -rn "Step 4c" commands/ docs/ CLAUDE.md README.md tests/ --include="*.md" --include="*.sh"
```

**Expected:** Zero matches across all files.
**Exception:** `CHANGELOG.md` and `docs/plans/` may reference Step 4c in historical context.

### 1.3 No remaining "Step 9: Issue Tracker" references

```bash
grep -rn "Step 9: Issue Tracker" commands/ docs/ CLAUDE.md README.md tests/ --include="*.md" --include="*.sh"
```

**Expected:** Zero matches.
**Exception:** `CHANGELOG.md` and `docs/plans/` only.

### 1.4 No remaining "Step 10" references

```bash
grep -rn "Step 10" commands/ docs/ CLAUDE.md README.md tests/ --include="*.md" --include="*.sh"
```

**Expected:** Zero matches across all files.
**Exception:** `CHANGELOG.md` and `docs/plans/` may reference Step 10 in historical context.

**Note:** `commands/scaffold.md` itself must have zero "Step 10" matches. The heading is now "Step 9: Final Report" and all "jump to Step 10" references are updated to "jump to Step 9".

---

## 2. Removed Label References

### 2.1 No remaining "Tracker Configuration (Auto-Finalize)" references

```bash
grep -rn "Auto-Finalize" commands/ docs/ CLAUDE.md README.md tests/ --include="*.md" --include="*.sh"
```

**Expected:** Zero matches.
**Exception:** `CHANGELOG.md` and `docs/plans/` only.

### 2.2 No remaining "MCP Guidance" as step name

```bash
grep -rn "MCP Guidance" commands/ docs/ CLAUDE.md README.md tests/ --include="*.md" --include="*.sh"
```

**Expected:** Zero matches.
**Exception:** `CHANGELOG.md` and `docs/plans/` only.

---

## 3. Mermaid Diagram Consistency

### 3.1 All Mermaid diagrams include infrastructure node

Check each file that contains a scaffold pipeline Mermaid diagram:

| File | Expected Node Name | Check Command |
|------|--------------------|---------------|
| `README.md` | `Infra["Infrastructure Declaration` | `grep -q "Infrastructure Declaration" README.md` |
| `docs/architecture.md` | `A2[Infrastructure Declaration]` | `grep -q "Infrastructure Declaration" docs/architecture.md` |
| `docs/reference/pipelines.md` | `INFRA_DECL[Infrastructure Declaration` | `grep -q "INFRA_DECL" docs/reference/pipelines.md` |

**Expected:** All three greps succeed.

### 3.2 No remaining TRACKER node in pipelines.md diagram

```bash
grep -n "TRACKER" docs/reference/pipelines.md
```

**Expected:** Zero matches. The TRACKER node (old Step 9 in Mermaid) has been removed and replaced with direct `E2E --> REPORT` edge.

### 3.3 All Mermaid diagrams include Push/Issues nodes

| File | Check |
|------|-------|
| `README.md` | Contains `Push["Push to Remote` |
| `docs/reference/pipelines.md` | Contains `PUSH[Push to Remote` AND `CREATE_ISSUES[Create Tracker Issues` |

### 3.4 pipelines.md diagram has MCP_CHECK node

```bash
grep -q "MCP_CHECK" docs/reference/pipelines.md
```

**Expected:** Match found.

---

## 4. Stage Table Consistency

### 4.1 pipelines.md stages table matches scaffold.md step headings

Verify that every step heading in `commands/scaffold.md` has a corresponding row in the `docs/reference/pipelines.md` stages table:

| scaffold.md Heading | Expected pipelines.md Step Column |
|---------------------|-----------------------------------|
| `### Step 0-INFRA: Infrastructure Declaration` | `0-INFRA` |
| `### Step 0-MCP: MCP Verification` | `0-MCP` |
| `### Step 0: Mode Selection` | `0` |
| `### Step 1: Specification Phase` | `1` |
| `### Step 2: Spec Checkpoint` | `2` |
| `### Step 3: Scaffold Skeleton` | `3` |
| `### Step 4: Git Init + Auto-Config` | `4` |
| `### Step 4d: Push to Remote` | `4d` |
| `### Step 4e: Create Tracker Issues` | `4e` |
| `### Step 5: Architecture & Decomposition` | `5` |
| `### Step 6: Feature Plan Checkpoint` | `6` |
| `### Step 7: Feature Implementation Loop` | `7` |
| `### Step 8: E2E Tests` | `8` |
| `### Step 9: Final Report` | `9` |

**Steps NOT in stages table (internal sub-steps):** Step 0b (Brainstorming), Step 7b (Spec Compliance Check). These are sub-steps within their parent stages and do not have their own row.

### 4.2 No "Issue Tracker" row in stages table

```bash
grep -n "Issue Tracker" docs/reference/pipelines.md | grep -v "^#" | grep -v "Cards"
```

**Expected:** No match in the stages table rows. The term "Issue Tracker" may appear in Mermaid node labels for other pipelines (bug-fix, feature) but NOT in the scaffold stages table.

### 4.3 Stage count: 14 rows in scaffold stages table

Count table body rows (exclude header and separator):

```bash
awk '/^\| Step \| Stage/,/^$/' docs/reference/pipelines.md | grep "^\|" | grep -v "Step \| Stage" | grep -v "---" | wc -l
```

**Expected:** 14 rows (0-INFRA, 0-MCP, 0, 1, 2, 3, 4, 4d, 4e, 5, 6, 7, 8, 9).

---

## 5. CLAUDE.md Diagram Consistency

### 5.1 CLAUDE.md scaffold diagram includes 0-INFRA

```bash
grep -q "0-INFRA" CLAUDE.md
```

**Expected:** Match found.

### 5.2 CLAUDE.md scaffold diagram includes 0-MCP

```bash
grep -q "0-MCP" CLAUDE.md
```

**Expected:** Match found.

### 5.3 CLAUDE.md scaffold diagram includes 4d and 4e

```bash
grep -q "4d: push" CLAUDE.md && grep -q "4e: tracker issues" CLAUDE.md
```

**Expected:** Both match.

### 5.4 CLAUDE.md --no-implement line includes infrastructure

```bash
grep "no-implement" CLAUDE.md | grep -q "0-INFRA"
```

**Expected:** Match found (the --no-implement description line mentions 0-INFRA).

---

## 6. Internal Cross-References in scaffold.md

### 6.1 No "Step 9" references that point to Issue Tracker

```bash
grep -n "Step 9" commands/scaffold.md
```

**Expected:** Only matches for `### Step 9: Final Report` heading and possibly "jump to Step 9" references. Zero matches containing "Issue Tracker".

### 6.2 All "jump to Step" references point to Step 9

```bash
grep -n "jump to Step" commands/scaffold.md
```

**Expected:** All matches say "jump to Step 9" (not "jump to Step 10").

### 6.3 MCP Pre-flight does not reference Step 9 as issue tracker

```bash
grep -A5 "MCP Pre-flight" commands/scaffold.md | grep -v "Step 9"
```

Or inversely:

```bash
grep -A20 "MCP Pre-flight" commands/scaffold.md | grep "Step 9"
```

**Expected:** No mention of "Step 9" in the MCP Pre-flight section.

### 6.4 In-memory variable blocks present at consumption points

Each of these steps must contain the text "Required in-memory values from Step 0-INFRA":

```bash
for step in "Step 0-MCP" "Step 4:" "Step 4d:" "Step 4e:" "Step 9: Final Report" "L5b" "L6. Report"; do
  grep -q "Required in-memory values" <(awk "/$step/,/^###/" commands/scaffold.md) && echo "OK: $step" || echo "MISSING: $step"
done
```

**Expected:** OK for Step 0-MCP, Step 4, Step 4d, Step 4e, Step 9 (Final Report), L5b, L6.

---

## 7. Test File Assertions

### 7.1 Happy path test has new step assertions

```bash
grep -q "Infrastructure Declaration" tests/scenarios/scaffold-v2-happy-path.sh && \
grep -q "0-MCP" tests/scenarios/scaffold-v2-happy-path.sh && \
grep -q "Push to Remote" tests/scenarios/scaffold-v2-happy-path.sh && \
grep -q "Create Tracker Issues" tests/scenarios/scaffold-v2-happy-path.sh
```

**Expected:** All four greps succeed.

### 7.2 Happy path test has regression guards

```bash
grep -q '! grep -q "Step 4b"' tests/scenarios/scaffold-v2-happy-path.sh && \
grep -q '! grep -q "Step 4c"' tests/scenarios/scaffold-v2-happy-path.sh && \
grep -q '! grep -q "Step 9: Issue Tracker"' tests/scenarios/scaffold-v2-happy-path.sh
```

**Expected:** All three greps succeed.

### 7.3 Happy path test has ordering assertion

```bash
grep -q "INFRA_LINE" tests/scenarios/scaffold-v2-happy-path.sh
```

**Expected:** Match found.

### 7.4 No-implement test has 0-INFRA assertion

```bash
grep -q "Infrastructure Declaration" tests/scenarios/scaffold-v2-no-implement.sh
```

**Expected:** Match found.

### 7.5 No-implement test has L5b assertion

```bash
grep -q "L5b" tests/scenarios/scaffold-v2-no-implement.sh
```

**Expected:** Match found.

---

## 8. Version Consistency

### 8.1 plugin.json version is 5.5.0

```bash
grep '"version"' .claude-plugin/plugin.json | grep -q "5.5.0"
```

### 8.2 marketplace.json version is 5.5.0

```bash
grep '"version"' .claude-plugin/marketplace.json | grep -q "5.5.0"
```

### 8.3 CHANGELOG has v5.5.0 entry

```bash
grep -q "## \[5.5.0\]" CHANGELOG.md
```

---

## 9. Sync Safety

### 9.1 scaffold.md Step 0-MCP references trackers.md

```bash
grep -A30 "Step 0-MCP" commands/scaffold.md | grep -q "docs/reference/trackers.md"
```

**Expected:** Match found. Step 0-MCP must reference the trackers.md file by path, not embed the lookup table.

### 9.2 scaffold.md Step 0-MCP has sync comment

```bash
grep -q "Keep in sync" commands/scaffold.md
```

**Expected:** Match found. The sync comment `<!-- Replicates init.md Steps 3-7 detection logic. Keep in sync. -->` is present.

### 9.3 No "/init now?" offer in Step 0-MCP

```bash
grep -A50 "Step 0-MCP" commands/scaffold.md | grep -i "run.*init.*now"
```

**Expected:** Zero matches. The "Run /init now?" offer has been removed.

---

## 10. Files That Must NOT Be Changed

Verify these files are unmodified (git status check):

- All files in `agents/`
- `commands/init.md`
- All files in `checklists/`, `core/`, `state/`, `examples/`
- All files in `docs/guides/`
- `tests/scenarios/scaffold-v2-input-conflicts.sh`
- `tests/scenarios/scaffold-v2-spec-loop.sh`
- `tests/harness/run-tests.sh`

```bash
git diff --name-only | grep -E "^(agents/|commands/init\.md|checklists/|core/|state/|examples/|docs/guides/|tests/scenarios/scaffold-v2-input-conflicts|tests/scenarios/scaffold-v2-spec-loop|tests/harness/)" | wc -l
```

**Expected:** 0 changed files in these paths.
