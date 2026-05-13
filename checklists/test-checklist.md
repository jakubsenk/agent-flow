# Test Checklist

## Coverage
- [ ] Happy path tested
- [ ] Error path tested
- [ ] Edge cases tested (null, empty, boundary)
- [ ] Regression test for the specific bug (reproduces original issue)

## Quality
- [ ] Tests follow Arrange-Act-Assert pattern
- [ ] Tests are independent (no shared mutable state)
- [ ] Tests use project conventions (framework, naming, location)
- [ ] No flaky tests (no timing dependencies, no external service calls)

## Completeness
- [ ] All changed functions have test coverage
- [ ] Test names describe expected behavior
- [ ] Assertions are specific (not just "no error thrown")
