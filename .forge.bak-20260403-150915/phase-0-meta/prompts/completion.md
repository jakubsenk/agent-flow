# Phase 9 — Completion

You are finalizing the design awareness feature implementation and preparing it for merge.

## Context

Read:
- `.forge/phase-8-verify/report.md` — verification report (must show PASS verdict)
- `.forge/phase-7-execute/execution-log.md` — execution summary
- `.forge/phase-4-spec/spec.md` — specification
- `CLAUDE.md` — current plugin version and conventions

## Completion Checklist

### 1. Verification Passed
- [ ] All tests passing (full suite)
- [ ] Specification compliance: all requirements IMPLEMENTED
- [ ] No CRITICAL issues in verification report
- [ ] Backward compatibility confirmed

### 2. Changelog Entry

Create a changelog entry following the project's conventions. Read `CHANGELOG.md` for the existing format.

The entry should include:
- Version bump (determined by versioning policy analysis in spec)
- Summary of what was added
- List of files changed
- Any new agents, skills, or config sections

### 3. Version Bump

If the feature warrants a version bump (check spec for recommendation):
- Update version in `.claude-plugin/plugin.json`
- Update version in `.claude-plugin/marketplace.json`
- Ensure CHANGELOG.md entry matches

### 4. Documentation Updates

Verify these are complete (should have been done in execution phase):
- [ ] CLAUDE.md — agent count, architecture description, config contract
- [ ] docs/reference/ — any affected reference docs
- [ ] README.md — if the feature is user-visible enough to mention

### 5. Final Commit

Stage all changes and create the final commit:
```bash
git add -A
git status  # verify no unexpected files
git commit -m "feat(scaffold): add design awareness for web projects

- {list key changes}
- Version: {old} -> {new}

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

### 6. Summary Report

Display to the user:

```
## Feature Complete: Scaffold Design Awareness

**Version:** {old} -> {new}
**Type:** {PATCH|MINOR|MAJOR}

### What Changed
- {bullet list of key changes}

### Files Modified
- {list with brief description}

### New Files (if any)
- {list}

### Test Results
- {N} new tests added
- {M} total tests passing
- {0} regressions

### Next Steps
1. Review the changes: `git diff HEAD~1`
2. Run full test suite: `bash tests/harness/run-tests.sh`
3. Tag the release: `git tag v{version}`
4. Test with a real web project scaffold to validate end-to-end
```

## Output

Save the completion report to `.forge/phase-9-completion/report.md`.
