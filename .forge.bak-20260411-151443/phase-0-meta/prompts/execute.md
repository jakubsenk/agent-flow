# Phase 7 — Execute

## Instructions for Execution Agent

You are implementing a new Automation Config template for Oracle PL/SQL + Redmine stack. This is a markdown-only change with no runtime code.

### Task 1: Create `examples/configs/redmine-oracle-plsql.md`

Create the file following EXACTLY the format of `examples/configs/redmine-rails.md` (same Redmine tracker type) and the comprehensive optional sections pattern from `examples/configs/github-nextjs.md`.

**Content sources:**
- Required sections: adapt from `examples/configs/redmine-rails.md` with Oracle PL/SQL build/test commands
- Oracle-specific values: from `docs/plans/readmine-project/ceos-agents-gap-analysis.md` section 5 (generalize project-specific values into `<placeholder>` format)
- Optional sections: adapt from `examples/configs/github-nextjs.md` comment block pattern

**Critical format rules:**
- Table columns use `|------|---------|` separator (6 dashes, 9 dashes) — match redmine-rails.md exactly
- State transitions MUST include `Done: status:Closed` (test G-32 pattern)
- Placeholders use `<angle-bracket>` format
- Oracle-relevant optional sections (Local Deployment, Agent Overrides, Retry Limits, Decomposition) should be ACTIVE (not commented out)
- All other optional sections should be in `<!-- -->` HTML comments

**Build & Test commands:**
- Build: `bash db/scripts/deploy.sh`
- Test: `bash db/scripts/test.sh`

**Local Deployment section (Oracle-specific):**
- Type: docker
- Start command: `docker compose up -d oracle-xe`
- Stop command: `docker compose down`
- Health check URL: `localhost:1521` (Oracle listener port)
- Health check timeout: 60 (Oracle XE takes time to start)
- Ports: 1521

### Task 2: Update `skills/template/SKILL.md`

Add one row to the template table after the `redmine-rails` row:
```
| redmine-oracle-plsql | Oracle PL/SQL | Redmine |
```

### Verification

After both tasks complete, run:
```bash
./tests/harness/run-tests.sh
```

All tests must pass. The new template file should not affect any existing test.
