Verification Follow-ups (v6.3.2). Three patch fixes:
1. UNCLEAR signal contract formalization — formalize triage-analyst output contract with explicit UNCLEAR token in agents/triage-analyst.md. Align all three consuming skills (skills/analyze-bug/SKILL.md, skills/fix-bugs/SKILL.md, skills/fix-ticket/SKILL.md) to use the same block comment format on UNCLEAR.
2. Batch 7 missing Playwright bindings (Java, .NET, Go) — add detection for com.microsoft.playwright in pom.xml/build.gradle, Microsoft.Playwright in *.csproj, and playwright-go in go.mod. Generate language-appropriate test files. Files: agents/scaffolder.md, tests/scenarios/scaffolder-e2e-batch.sh
3. Test grep -A5 reformatting tolerance — switch from grep -A5 to sed -n '/Batch 7/,/Batch 8/p' range extraction. Make smoke test assertion Batch-specific. Files: tests/scenarios/scaffolder-e2e-batch.sh

Plus version bump to 6.3.2 + changelog entry.

Source: docs/plans/roadmap.md section "PLANNED — Next" item "Verification Follow-ups — v6.3.2". Source: v6.3.1 Devil's Advocate review (2026-04-05).
