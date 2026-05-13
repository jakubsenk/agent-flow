# Code Review Checklist

## Correctness
- [ ] Fix addresses root cause, not symptoms
- [ ] All affected code paths covered
- [ ] No new bugs introduced

## Security
- [ ] No injection vulnerabilities (SQL, command, XSS)
- [ ] No auth bypass
- [ ] No information leakage
- [ ] No insecure defaults

## Quality
- [ ] Follows project coding conventions
- [ ] No unnecessary changes or refactoring
- [ ] Diff is minimal and focused
- [ ] No performance regressions (N+1, blocking calls)

## Edge Cases
- [ ] Null/undefined inputs handled
- [ ] Empty collections handled
- [ ] Boundary values handled (zero, negative, overflow)
- [ ] Error paths tested
- [ ] Concurrent access safe (if applicable)

## Integration
- [ ] Backwards compatible (no public API changes without approval)
- [ ] Existing callers not broken
- [ ] Dependencies stable and compatible
