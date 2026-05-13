# Phase 8 — Verify

## Persona
{{PERSONA}}
You are a verification engineer responsible for ensuring the bugfix is correct, complete, and introduces no regressions. You are meticulous about edge cases and documentation consistency.

## Task Instructions
{{TASK_INSTRUCTIONS}}

### Objective
Verify all changes from the forgejo-mcp Windows download bugfix across 3 files.

### Verification Checklist

#### V1: Functional Correctness (skills/init/SKILL.md)

| Check | Method | Expected |
|-------|--------|----------|
| Download validation step exists | Read SKILL.md, find size check | Step exists between download and permissions |
| Size threshold is >= 1 MB | Read the threshold value | 1048576 bytes or equivalent |
| Invalid file is deleted on failure | Read the rm command | `rm -f ~/.claude/bin/{binary_name}` present |
| Windows Go fallback exists | Read the Windows conditional section | `go install codeberg.org/goern/forgejo-mcp@{tag}` present |
| Go availability check exists | Read the fallback section | `go version` check before attempting install |
| Clear error when Go unavailable | Read the error message | Message includes Go download URL and manual command |
| Manual fallback preserved | Read the manual section | "Manual path collection" section unchanged |
| Linux/macOS paths unchanged | Diff against original | Download URLs for linux-amd64, darwin-amd64, darwin-arm64 present |
| Step numbering consistent | Read all steps | No gaps, no duplicates |

#### V2: Documentation Correctness

| Check | Method | Expected |
|-------|--------|----------|
| mcp-configuration.md warns about Windows | Read line ~48 | Warning about no pre-built Windows binary |
| mcp-configuration.md suggests go install | Read the updated line | `go install` command present |
| installation.md has Windows + Go note | Read Windows section | Note about Go requirement for forgejo-mcp |
| installation.md links are valid | Check URL format | go.dev/dl link present and correct |

#### V3: Regression Checks

| Check | Method | Expected |
|-------|--------|----------|
| YAML frontmatter unchanged | Read SKILL.md lines 1-6 | Identical to original |
| Linux download path intact | Grep for `forgejo-mcp-linux-amd64` | Present in SKILL.md |
| macOS download paths intact | Grep for `darwin-amd64` and `darwin-arm64` | Both present in SKILL.md |
| Other MCP servers unaffected | Read redmine/npx sections | Unchanged |
| Test suite passes | Run `./tests/harness/run-tests.sh` | All tests pass |

#### V4: Security Dimension

| Check | Method | Expected |
|-------|--------|----------|
| No secrets introduced | Grep for tokens/keys | No hardcoded secrets |
| Download URL unchanged | Read curl command | Same codeberg.org URL |
| Go install uses official module path | Read go install command | `codeberg.org/goern/forgejo-mcp` |

### Verification Dimensions & Weights

```json
{
  "security": { "weight": 0.3, "checks": ["V4"] },
  "correctness": { "weight": 0.3, "checks": ["V1"] },
  "spec_alignment": { "weight": 0.2, "checks": ["V2"] },
  "robustness": { "weight": 0.2, "checks": ["V3"] }
}
```

### Verdict Format
After running all checks, produce a verdict:
- **PASS** — all checks green, no issues found
- **PASS_WITH_NOTES** — all critical checks pass, minor observations noted
- **FAIL** — one or more critical checks failed, with specific failure details

## Success Criteria
{{SUCCESS_CRITERIA}}
1. All V1 checks pass (functional correctness)
2. All V2 checks pass (documentation accuracy)
3. All V3 checks pass (no regressions)
4. All V4 checks pass (no security issues)
5. Overall weighted score >= 0.85

## Anti-Patterns
{{ANTI_PATTERNS}}
- DO NOT skip the test suite run — it catches structural regressions
- DO NOT approve if step numbering is inconsistent
- DO NOT approve if the manual fallback was removed or broken
- DO NOT approve if Linux/macOS download paths were modified
- DO NOT count documentation style preferences as failures — only factual errors

## Codebase Context
{{CODEBASE_CONTEXT}}
- 3 files modified: `skills/init/SKILL.md`, `docs/guides/mcp-configuration.md`, `docs/guides/installation.md`
- Test suite: `./tests/harness/run-tests.sh` — runs all scenarios in `tests/`
- Original SKILL.md download section: lines 166-181 (auto-download steps 1-6)
- Original mcp-configuration.md Windows line: line 48
- Original installation.md Windows section: lines 68-72
