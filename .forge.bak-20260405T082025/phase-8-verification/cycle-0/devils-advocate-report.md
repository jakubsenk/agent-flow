# Devil's Advocate Report — v6.3.1 Fast-Track Changes

**Reviewer:** Devil's Advocate (Phase 8)
**Date:** 2026-04-05
**Scope:** UNCLEAR handler (analyze-bug, fix-bugs), cross-stack Playwright detection (scaffolder), test grep patterns (scaffolder-e2e-batch.sh)
**Pipeline mode:** Fast-track (Phases 1-5 skipped)

## Robustness Score: 0.72

---

## Failure Scenario 1: Triage-Analyst Signal Mismatch — "UNCLEAR" vs "Quality gate: incomplete"

**Likelihood:** HIGH (0.8)
**Impact:** HIGH — UNCLEAR bugs silently pass through triage, reaching fixer with no actionable information

### Problem

The analyze-bug skill (step 3a) triggers its UNCLEAR handler when "triage returns UNCLEAR (issue quality gate fails)". The fix-bugs skill (step 2) similarly branches on "Unclear". However, the **triage-analyst agent never outputs the word "UNCLEAR"**. Its documented output contract is:

- `Quality gate: PASS` — issue is clear
- `Quality gate: incomplete` — issue lacks information

The agent definition (`agents/triage-analyst.md`, lines 40-42) defines only these two outputs. There is no `Quality gate: UNCLEAR` signal. The agent's blocking section (lines 94-102) posts a Block Comment Template on incomplete issues but does not label the output as "UNCLEAR".

This creates an **undefined signal interface**: the skills expect to detect "UNCLEAR" in the triage output, but the agent produces "incomplete". The resolution depends entirely on how the LLM interprets the natural-language instruction "If triage returns UNCLEAR". If the model maps "Quality gate: incomplete" to "UNCLEAR", the handler fires correctly. If the model interprets "UNCLEAR" literally (looking for the exact string), it will never trigger.

**Critically**, fix-ticket (step 3, line 132) simply says `Unclear -> Block` without specifying the block comment template or the mechanism, relying on the block handler (step X). The new analyze-bug handler hardcodes the comment template inline (step 3a, lines 27-34). The new fix-bugs handler delegates to the Block Comment Template (step 2, line 108). These three skills use **three different mechanisms** for the same UNCLEAR path:

1. **analyze-bug:** Inline block comment template with hardcoded Reason ("Issue is unclear -- insufficient information to proceed with analysis")
2. **fix-bugs:** Delegates to Block Comment Template with dynamic Reason/Detail/Recommendation from triage output
3. **fix-ticket:** Says "Block" with no further detail about the mechanism

A research phase (Phase 2) would have surfaced this signal contract gap. A brainstorming phase (Phase 3) would have proposed standardizing the agent output vocabulary.

### Recommendation

Define an explicit output contract for triage-analyst that includes the word "UNCLEAR" as a top-level verdict (e.g., `Verdict: UNCLEAR`) alongside `Verdict: OK` and `Verdict: DUPLICATE`. Alternatively, update all three skills to match on `Quality gate: incomplete` instead of "UNCLEAR". Standardize the block mechanism across all three skills.

---

## Failure Scenario 2: Cross-Stack Playwright Detection Misses Java, .NET, Go, and PHP Stacks

**Likelihood:** MEDIUM (0.5)
**Impact:** MEDIUM — E2E test generation silently skipped for projects using Playwright via non-covered language bindings

### Problem

The scaffolder's Batch 7 cross-stack Playwright detection (`agents/scaffolder.md`, lines 71-75) checks exactly three ecosystems:

- **JS/TS:** `@playwright/test` in `package.json`
- **Python:** `pytest-playwright` in `pyproject.toml` / `requirements.txt`
- **Ruby:** `capybara-playwright-driver` in `Gemfile`

This omits several real-world Playwright usage patterns:

1. **Java:** `com.microsoft.playwright` in `pom.xml` or `build.gradle` — Playwright has official Java bindings (`playwright-java`), used in Spring Boot web applications
2. **.NET/C#:** `Microsoft.Playwright` in `.csproj` — official .NET bindings, commonly used in Blazor/ASP.NET projects
3. **Go:** `playwright-go` in `go.mod` — community binding for Go web applications
4. **PHP:** `php-playwright` — community packages exist
5. **Python alternative:** `playwright` (not `pytest-playwright`) in `requirements.txt` — users who use Playwright's sync/async API directly without the pytest plugin

The Batch 1 core build config list (`agents/scaffolder.md`, line 28) includes `go.mod`, `Cargo.toml`, and `*.csproj`, confirming these stacks are supported by the scaffolder. The Batch 6 web detection (`line 58`) explicitly lists `Go gin` as a non-web framework, but a Go project using `templ` or `htmx` templates would be a web project that could use `playwright-go`.

The test (`scaffolder-e2e-batch.sh`, lines 18-20) validates only the three implemented patterns, providing no coverage for the gap.

A research phase would have catalogued all official Playwright language bindings. The fast-track skip means this gap was not surfaced.

### Recommendation

Add detection rules for Java (`com.microsoft.playwright` in `pom.xml`/`build.gradle`), .NET (`Microsoft.Playwright` in `*.csproj`), and the bare Python `playwright` package. Document Go and PHP as out-of-scope with a comment explaining why (community bindings without stable Playwright test runner integration). Add a fallback message when a web project has no recognized Playwright binding: "Web project detected but no supported Playwright binding found in dependencies. Skipping E2E test generation. To enable, add a Playwright dependency for your stack."

---

## Failure Scenario 3: Test Grep Pattern `grep -A5 "Batch 7"` Is Fragile Against Reformatting

**Likelihood:** LOW-MEDIUM (0.35)
**Impact:** LOW — Test gives false failure, blocking CI; no production impact

### Problem

The test `scaffolder-e2e-batch.sh` (line 15) uses:

```bash
grep -A5 "Batch 7" "$SCAFFOLDER" | grep -q "Skip this batch entirely"
```

This pattern assumes "Skip this batch entirely" appears within 5 lines of the "Batch 7" heading. Currently this holds (the skip instruction is on line 68, the heading is on line 66 — a 2-line gap). However:

1. If a future edit adds a blank line or a comment between the heading and the skip instruction, `grep -A5` may miss it. The margin is only 3 lines (5 lines of context, 2 lines currently used).
2. The pattern `"Batch 7"` without anchoring also matches any future reference to "Batch 7" elsewhere in the file (e.g., in the scorecard section at line 142: `"E2E test setup: (web projects with Playwright only) playwright.config present?"`). However, `head -1` is used for the line number check (line 57), not for this grep, so a false match from a different section could satisfy the assertion incorrectly.
3. The batch ordering test (lines 57-61) uses `grep -n "Batch 7" | head -1` which is correct for now but would break if "Batch 7" appeared in a comment or reference before the actual heading.

Additionally, the test checks `grep -q "smoke" "$SCAFFOLDER"` (line 26), which matches on 41 occurrences across the file (Batch 3 smoke test, Batch 7 smoke test, scorecard, constraints). This assertion proves nothing specific about Batch 7 — it would pass even if Batch 7's smoke test reference were removed.

A Phase 4 (planning) review would have flagged these test quality issues and proposed section-bounded assertions (e.g., `sed -n '/Batch 7/,/Batch 8/p'` to extract only the Batch 7 section before grepping).

### Recommendation

Replace `grep -A5 "Batch 7"` with a section-bounded extraction: `sed -n '/^[[:space:]]*\*\*Batch 7/,/^[[:space:]]*\*\*Batch 8/p'` piped into grep. Replace the generic `grep -q "smoke"` with a Batch-7-bounded smoke check. These changes make the test resilient to reformatting.

---

## Overall Assessment

The changes are **functionally sound for the common case** but have a significant design-level gap in Scenario 1 (the UNCLEAR signal interface). This is the kind of issue that a full pipeline with research + brainstorming phases would catch, because it requires reading the agent's output contract alongside the skill's input expectations and noticing the vocabulary mismatch.

Scenario 2 is a genuine coverage gap but affects a smaller user population (Java/.NET/Go web projects with Playwright are less common in this plugin's target audience). The existing three-stack detection covers the majority of real-world Playwright usage.

Scenario 3 is a test quality concern that does not affect production but could cause false CI failures during future maintenance.

**Key risk from fast-track:** The UNCLEAR handler works today only because the LLM correctly interprets natural-language intent ("if triage returns UNCLEAR" maps to "Quality gate: incomplete"). There is no explicit contract enforcement. A model version change or a prompt that produces edge-case output (e.g., "Quality gate: PARTIALLY CLEAR" or "Quality gate: needs clarification") would bypass the handler silently, leaving UNCLEAR bugs to proceed through the pipeline without blocking.

| Dimension | Score | Notes |
|-----------|-------|-------|
| Correctness | 0.65 | Signal interface undefined between triage-analyst and consuming skills |
| Completeness | 0.70 | Missing Java/.NET Playwright detection; no test for UNCLEAR handler |
| Consistency | 0.60 | Three different UNCLEAR handling mechanisms across analyze-bug, fix-bugs, fix-ticket |
| Test coverage | 0.75 | Batch 7/8 well tested; UNCLEAR path has zero test coverage; grep fragility partially addressed |
| Resilience | 0.80 | Dry-run guard in fix-bugs is good; block comment template usage is consistent |
| **Overall** | **0.72** | Solid patch for common cases, but the UNCLEAR signal gap is a latent defect |
