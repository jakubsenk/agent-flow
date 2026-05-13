# Phase 5 — Test Plan

## Note
This is a pure markdown plugin with no runtime code. Tests are structural checks (automatable via grep) and manual verification scenarios.

## T1: Structural Checks (automatable)

| ID | Check | Command |
|----|-------|---------|
| T1.1 | SKILL.md contains `--fail` in curl command | `grep -c '\-\-fail' skills/init/SKILL.md` → ≥ 1 |
| T1.2 | SKILL.md contains size validation with `wc -c` | `grep -c 'wc -c' skills/init/SKILL.md` → ≥ 1 |
| T1.3 | SKILL.md contains `go install` fallback | `grep -c 'go install' skills/init/SKILL.md` → ≥ 1 |
| T1.4 | SKILL.md contains `GOBIN` env var | `grep -c 'GOBIN' skills/init/SKILL.md` → ≥ 1 |
| T1.5 | SKILL.md preserves manual fallback | `grep -c 'Manual path collection' skills/init/SKILL.md` → ≥ 1 |
| T1.6 | SKILL.md contains `/v2@` in go install path | `grep -c 'forgejo-mcp/v2@' skills/init/SKILL.md` → ≥ 1 |
| T1.7 | mcp-configuration.md warns about Windows | `grep -ci 'not.*available\|not.*published\|go install' docs/guides/mcp-configuration.md` → ≥ 1 |
| T1.8 | installation.md mentions Go for Windows | `grep -ci 'go.*install\|Go toolchain' docs/guides/installation.md` → ≥ 1 |

## T2: Manual Scenarios

| ID | Scenario | Expected Result |
|----|----------|----------------|
| T2.1 | Windows + Go + Gitea tracker | Download fails, Go install succeeds, binary in ~/.claude/bin/ |
| T2.2 | Windows + no Go + Gitea tracker | Download fails, clear error message, manual fallback offered |
| T2.3 | Linux + Gitea tracker | Download succeeds (curl --fail + size check pass), no Go fallback triggered |
| T2.4 | macOS + Gitea tracker | Download succeeds, same as Linux |
| T2.5 | Windows + existing valid binary | Reuse existing, skip download entirely |

## T3: Edge Cases

| ID | Edge Case | Expected Result |
|----|-----------|----------------|
| T3.1 | Upstream adds Windows binary in future | curl --fail succeeds, size check passes, Go fallback not triggered |
| T3.2 | Codeberg returns 200 with error page | Size check catches (< 100KB), falls to Go install |
| T3.3 | go install fails (network error) | Falls through to manual path collection with error message |
