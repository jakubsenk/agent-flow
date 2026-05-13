# Phase 8 — Verify

## Verification Checklist

### File Existence
- [ ] `examples/configs/redmine-oracle-plsql.md` exists
- [ ] File count in `examples/configs/` is now 8 (was 7)

### Template Format Compliance
- [ ] H1 heading matches pattern: `# Oracle PL/SQL + Redmine — Automation Config Template`
- [ ] Blockquote instruction: `> Copy the section below into your project's CLAUDE.md`
- [ ] `## Automation Config` H2 heading present

### Required Sections Present
- [ ] `### Issue Tracker` with Type = redmine
- [ ] `### Source Control` with placeholders
- [ ] `### PR Rules` with Labels
- [ ] `### PR Description Template` with Oracle-relevant fields
- [ ] `### Build & Test` with Oracle commands

### Oracle-Specific Optional Sections (Active)
- [ ] `### Local Deployment` with Docker/Oracle XE config
- [ ] `### Agent Overrides` with Path = `customization/`
- [ ] `### Retry Limits` with conservative values
- [ ] `### Decomposition` with sensible defaults

### Redmine Consistency
- [ ] State transitions include `Done:` with `status:Closed` (matches G-32 test pattern)
- [ ] Bug query uses Redmine format (`project_id=`, `status_id=`, `tracker_id=`)

### Template Catalog
- [ ] `skills/template/SKILL.md` contains `redmine-oracle-plsql` row
- [ ] Table has 8 rows (was 7)
- [ ] Row format matches existing: `| redmine-oracle-plsql | Oracle PL/SQL | Redmine |`

### Test Suite
- [ ] `./tests/harness/run-tests.sh` passes all scenarios
- [ ] No regressions in existing tests

### No Unintended Changes
- [ ] No files modified outside of `examples/configs/redmine-oracle-plsql.md` (new) and `skills/template/SKILL.md` (modified)
- [ ] No changes to agent definitions, core modules, or other skills
