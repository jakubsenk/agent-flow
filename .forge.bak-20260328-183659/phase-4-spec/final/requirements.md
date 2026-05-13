# Requirements — version-check Fix (v5.5.1 Patch)

## Change Inventory

### 1. `commands/version-check.md` — Complete Rewrite (PRIMARY)

**Scope:** Delete all existing content and replace with the new generic version.

**What changes:**
- Add Plugin Identity table after frontmatter (single source for plugin name + marketplace name)
- Part A: Rewrite steps 1-4 to read `installed_plugins.json`, find `{plugin}@{marketplace}` entry, derive remote URL from `repository` field in cached `plugin.json` (no hardcoded fallback)
- Part B: Add name-match guard — only run when CWD's `.claude-plugin/plugin.json` `name` field matches Plugin Identity
- Part C: Remove entirely (legacy `CLAUDE-agents` cleanup is author-specific artifact)
- Add 10 explicit error paths with distinct messages
- Add `timeout 10` and `grep -v '\^{}'` to git ls-remote pipeline
- Add `2>/dev/null` to suppress git stderr
- Add semver comparison instruction (conceptual + `sort -V` implementation)
- Rules section made generic (no hardcoded plugin names)

**Defects addressed:** DEF-1 (P0), DEF-2 (P1), DEF-3 (P0), DEF-4 (P1), DEF-5 (P2), DEF-6 (P1), DEF-7 (P1), DEF-8 (P1), DEF-9 (P2) — all 9 defects from the registry.

### 2. `docs/reference/commands.md` — Update /version-check Section

**Scope:** Lines 621-639 (the /version-check section).

**What changes:**
- Update "What it does" description to reflect the new 2-part structure (Part A + Part B, no Part C)
- Mention that it reads `installed_plugins.json` as the authoritative source
- Mention graceful degradation when repository field is absent or remote unreachable
- No syntax change (still zero arguments)

### 3. `CHANGELOG.md` — Update v5.5.1 Entry

**Scope:** Lines 10-17 (the [5.5.1] section).

**What changes:**
- Update summary line to mention: generic plugin identity, removed hardcoded URL, full error handling, semver comparison fix
- Update Fixed bullet points:
  - Remove mention of Part C (it no longer exists)
  - Add: removed hardcoded fallback URL
  - Add: proper semver comparison (sort -V)
  - Add: annotated tag filtering
  - Add: timeout on git ls-remote
  - Add: 10 distinct error paths
  - Add: Plugin Identity table for genericity

### 4. Files NOT Changed (confirmed no-change needed)

| File | Reason |
|------|--------|
| `CLAUDE.md` | Line 32 lists `/version-check` by name only (no description change needed). Line 206 uses it as a MINOR version example — still accurate. |
| `README.md` | Line 156: `Compare installed plugin version against latest available` — still accurate, no change. |
| `skills/workflow-router/SKILL.md` | Intent mapping uses command name only, description unchanged. |
| `docs/guides/troubleshooting.md` | References `/version-check` as a troubleshooting step — still valid. |
| `.claude-plugin/plugin.json` | `repository` field already present. Version already 5.5.1. No change. |
| `tests/` | Test harness tests command markdown structure, not runtime behavior. Existing structure tests still pass with new format. |

## Dependency Graph

```
commands/version-check.md  (primary — complete rewrite)
    ↓
docs/reference/commands.md (secondary — description update only)
    ↓
CHANGELOG.md               (secondary — entry update only)
```

No circular dependencies. All three changes are independent and can be applied in any order.

## Contract Impact

**None.** This is a PATCH-level change:
- No new Automation Config keys (required or optional)
- No new commands or agents
- No changed agent output format
- No changed command syntax or flags
- The command still takes zero arguments and produces text output
