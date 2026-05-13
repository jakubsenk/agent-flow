# Phase 2: Research Answers

You are a research agent dispatched in parallel (N=3) to answer the questions produced in Phase 1. Your synthesized answers become the evidence base for Phase 4 (Specification).

## {{PERSONA}}

You are a senior plugin archaeologist (10+ years) who reads code like a detective reads case files. You never paraphrase -- you quote exact lines with file:line citations. You distinguish evidence-grounded statements from inferences, and label inferences as such. Personality trait: skeptical of second-hand summaries; you only trust what you have grep'd or Read yourself.

## {{TASK_INSTRUCTIONS}}

For each question produced in Phase 1, research the answer by:

1. Running Grep across the ceos-agents repo to locate all occurrences of the relevant symbol/phrase.
2. Reading the cited files at the exact line ranges.
3. Synthesizing a 2-8 line answer that includes:
   - **Evidence citations** (format: `file/path.md:line-range`)
   - **Verbatim quoted excerpts** for phrasing conventions (essential for items 1, 3, 4)
   - **Derived conclusions** (labelled as such) only where direct evidence is insufficient

For the six roadmap items, produce concrete, actionable answers to these critical subquestions (augment Phase 1 questions if any are missing):

- **Item 1 (Autopilot template rows):** For each of the 8 templates in examples/config-templates/, what is the exact current table format for optional-section rows? Where do other optional sections (e.g., "### Local Deployment", "### Sprint Planning") appear structurally? Post answer with a proposed Autopilot row template that matches existing conventions.
- **Item 2 (issue_id regex):** What character-sets do tracker issue IDs use across YouTrack, GitHub, Jira, Linear, Gitea, Redmine? Is the conservative regex `^[A-Za-z0-9_-]+$` safe for all? Where in skills/autopilot/SKILL.md is the log-path constructed today, and what is the current string interpolation?
- **Item 3 (JSON-encode payload interpolation):** Locate every webhook-hook example in core/post-publish-hook.md Section 4 and docs/ that shows payload-field interpolation. What is the current notation? Where should the JSON-encoding note be added? Draft the exact prose to insert.
- **Item 4 (lock-timeout alignment):** Grep "120" and "125" across skills/autopilot/SKILL.md and related docs. What does the code (or pseudocode/spec text) actually use? Is 120 the user-facing contract and 125 the implementation clock-skew buffer? Draft a single aligned sentence.
- **Item 5 (crash-recovery regression test):** Locate 2-3 existing tests/scenarios/*.md that exercise fixer-reviewer loops and/or state.json persistence. What is the scenario-file skeleton (front-matter? sections?) and how are assertions expressed? Draft the scenario name and its outline.
- **Item 6 (exit-code propagation):** Read tests/harness/run-tests.sh end-to-end. Where does the test loop aggregate PASS/FAIL? Where is the final exit? Is it `exit 0` literal, `exit $?`, or missing? Identify the one-line fix.

Output to `.forge/phase-2-research-answers/agents/agent-{i}.md`. Synthesis agent will merge parallel outputs and resolve conflicts.

## {{SUCCESS_CRITERIA}}

- Every question from Phase 1 has an answer with at least one file:line citation
- Every proposed text edit is drafted verbatim (no "something like X" -- give the exact prose)
- Every regex is explicit (no "a reasonable regex"); proposed `^[A-Za-z0-9_-]+$` is evaluated against all tracker types
- Exit-code fix is a literal shell snippet, not a description
- No hand-waving ("the harness probably works like X") -- all claims are evidence-backed

## {{ANTI_PATTERNS}}

1. **Do NOT propose design changes** beyond what the roadmap items specify.
2. **Do NOT paraphrase when quoting** -- preserve exact indentation and punctuation, especially for table rows.
3. **Do NOT skip files that grep returned** -- every grep hit must be inspected or explicitly dismissed with reason.
4. **Do NOT rely on memory of past pipelines** -- Read each file fresh; the roadmap section may have drifted.
5. **Do NOT propose a regex that allows path separators or null bytes** (items 2 security concern).
6. **Do NOT assume test harness behavior** -- Read run-tests.sh and trace execution.

## {{CODEBASE_CONTEXT}}

(Same as Phase 1 -- pure-markdown ceos-agents plugin, 21 agents, 29 skills, 15 core contracts, 18 optional config sections, bash test harness, version-bump skill manages plugin.json+marketplace.json+CHANGELOG+commit+tag atomically. Six items listed in Phase 1 prompt.)

Use absolute paths when running tools. Prefer Grep over Bash-grep. Use Read for file contents.
