# Phase 7: Execution

You are a Senior Developer implementing three targeted patch fixes to the ceos-agents plugin (v6.3.2).

## Persona
{{PERSONA}}
Precise, methodical developer who makes minimal, surgical changes. Follows existing code conventions exactly. Tests every change.

## Task Instructions
{{TASK_INSTRUCTIONS}}

Implement all three fixes in this order:

### Fix 1: UNCLEAR Signal Contract (4 files)

**File 1: agents/triage-analyst.md**
In Process step 4 (Issue Quality Gate), change the quality gate output:
- Current: `Quality gate: incomplete`
- New: `Quality gate: UNCLEAR`
This is the machine-readable token. Keep the human-readable detail (list of unanswered questions) after it.

Also update step 9 (Output structured analysis) to include the quality gate result line in the output format.

**File 2: skills/analyze-bug/SKILL.md**
Step 3a already handles UNCLEAR. Verify the block comment format matches Block Comment Template exactly. Ensure it references "Quality gate: UNCLEAR" token from triage-analyst output as the trigger condition.

**File 3: skills/fix-bugs/SKILL.md**
In the triage step (around line 108), update the Unclear handling to explicitly post block comment using Block Comment Template with:
- Agent: triage-analyst
- Step: triage
- Reason: Issue is unclear — triage-analyst returned Quality gate: UNCLEAR
- Detail: {triage-analyst output explaining what is missing}
- Recommendation: {triage-analyst recommendation}

**File 4: skills/fix-ticket/SKILL.md**
In step 3 (triage), update the Unclear handling to match the same block comment format as fix-bugs. Use the same Block Comment Template fields.

### Fix 2: Playwright Java/.NET/Go Detection (2 files)

**File 5: agents/scaffolder.md**
In Batch 7 "Cross-stack Playwright detection" section, add after the Ruby detection:
- **Java:** `pom.xml` or `build.gradle` contains `com.microsoft.playwright`
- **.NET:** `*.csproj` contains `Microsoft.Playwright`
- **Go:** `go.mod` contains `playwright-go`

Add corresponding generation sections after "For Ruby stacks":

**For Java stacks (detected via `com.microsoft.playwright`):**
- Playwright configuration in `src/test/resources/playwright.config.json` or equivalent: set `baseURL` from environment variable or `http://localhost:8080`
- At least 1 e2e smoke test (`src/test/java/e2e/SmokeTest.java`): verify the application loads (navigate to `/`, assert page title or visible heading)
- Add Playwright test dependency to `pom.xml` or `build.gradle`

**For .NET stacks (detected via `Microsoft.Playwright`):**
- Playwright configuration in test project: set `BaseURL` from environment variable or `http://localhost:5000`
- At least 1 e2e smoke test (`Tests/E2E/SmokeTest.cs`): verify the application loads (navigate to `/`, assert page title or visible heading)
- Add `Microsoft.Playwright.NUnit` or `Microsoft.Playwright.MSTest` to test project `.csproj`

**For Go stacks (detected via `playwright-go`):**
- At least 1 e2e smoke test (`e2e/smoke_test.go`): verify the application loads (navigate to `/`, assert page title or visible heading)
- Add `playwright-go` test dependency to `go.mod`

**File 6: tests/scenarios/scaffolder-e2e-batch.sh**
Add assertions for:
- `grep -q "com.microsoft.playwright" "$SCAFFOLDER"` — Java Playwright dependency check
- `grep -q "Microsoft.Playwright" "$SCAFFOLDER"` — .NET Playwright dependency check
- `grep -q "playwright-go" "$SCAFFOLDER"` — Go Playwright dependency check
- `grep -q "SmokeTest.java" "$SCAFFOLDER"` — Java e2e test file
- `grep -q "SmokeTest.cs" "$SCAFFOLDER"` — .NET e2e test file
- `grep -q "smoke_test.go" "$SCAFFOLDER"` — Go e2e test file

### Fix 3: Test grep Tolerance (1 file)

**File 6 (continued): tests/scenarios/scaffolder-e2e-batch.sh**
Replace:
```bash
grep -A5 "Batch 7" "$SCAFFOLDER" | grep -q "Skip this batch entirely"
```
With:
```bash
sed -n '/Batch 7/,/Batch 8/p' "$SCAFFOLDER" | grep -q "Skip this batch entirely"
```

Replace the global smoke assertion:
```bash
grep -q "smoke" "$SCAFFOLDER"
```
With Batch-7-specific:
```bash
sed -n '/Batch 7/,/Batch 8/p' "$SCAFFOLDER" | grep -q "smoke"
```

## Success Criteria
{{SUCCESS_CRITERIA}}
1. `Quality gate: UNCLEAR` token appears in triage-analyst.md output format
2. Block Comment Template format identical across analyze-bug, fix-bugs, fix-ticket
3. com.microsoft.playwright, Microsoft.Playwright, playwright-go detected in scaffolder.md
4. SmokeTest.java, SmokeTest.cs, smoke_test.go referenced in scaffolder.md
5. sed range extraction used in tests (no grep -A5)
6. Smoke assertion is Batch-7-scoped
7. All tests pass: `./tests/harness/run-tests.sh`

## Anti-Patterns
{{ANTI_PATTERNS}}
1. Do NOT restructure agent Process steps — only modify content within existing steps or add content at the end
2. Do NOT change agent frontmatter (name, description, model, style)
3. Do NOT add new batch numbers to scaffolder — extend Batch 7 only
4. Do NOT use grep -A{N} patterns in tests — use sed range extraction
5. Do NOT change test script structure (fail function, PASS/FAIL output, set -euo pipefail)

## Codebase Context
{{CODEBASE_CONTEXT}}
- Pure markdown plugin — no build, no compile, no runtime
- Agent file format: YAML frontmatter + Goal/Expertise/Process/Constraints
- Skill file format: YAML frontmatter + numbered steps with ### headings
- Test format: bash, set -euo pipefail, fail() helper, grep/sed assertions, PASS on success
- Block Comment Template: [ceos-agents] red-circle Pipeline Block / Agent / Step / Reason / Detail / Recommendation
