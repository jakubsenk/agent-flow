# Agent 3: Skeptical Brainstorm

**Perspective:** Adversarial skeptic — challenges assumptions, identifies hidden risks, proposes mitigations.

---

## Issue 1: Design Quality (No design/UI instructions for web projects)

### Challenge

The fundamental premise here is flawed. Adding prompt instructions like "use a design system" or "pick a color palette" will NOT produce good design. LLMs do not have visual taste. They can generate syntactically correct Tailwind config or MUI theme objects, but they cannot make aesthetic judgments — they will produce generic, template-like output indistinguishable from a default theme.

The research confirmation says "scaffolded projects have no design tokens file, no base CSS/theme, no component library setup." But having a *bad* design tokens file is arguably worse than having none, because it gives false confidence that design was addressed.

### Risks

1. **Taste illusion:** The scaffolder generates a theme that looks "professional" to the LLM but is actually generic Bootstrap-tier defaults (gray/blue palette, 16px body, 1.5 line-height). Users get a false sense of completeness.
2. **Scope creep into the plugin:** Design system selection is a product decision, not a scaffolding concern. Adding it to the spec-writer means the spec-writer now needs to "know about" Tailwind vs MUI vs shadcn/ui — more surface area for hallucination.
3. **Maintenance burden:** Design frameworks change rapidly. If we hardcode knowledge of specific component libraries, the instructions become stale within months.
4. **Non-web projects:** Adding design sections that only apply to frontend stacks creates noise for backend/CLI/library projects. The conditional logic ("if frontend stack, then...") adds complexity to already long agent prompts.

### Mitigations

1. **Do NOT generate design tokens or themes.** Instead, have spec-writer include a "Design System" section in `spec/README.md` that simply records the user's choice (or "TBD") and links to the chosen library's docs. The scaffolder then installs the package and creates the *official starter template* config (e.g., `npx create-next-app` defaults, `npx shadcn-ui init` defaults) rather than inventing one.
2. **Treat design as a user input, not an LLM output.** Add an optional `Design System` key to Automation Config. If present, the scaffolder uses the library's CLI init command. If absent, skip entirely — no guessing.
3. **Limit scope to infrastructure only:** The scaffolder should set up the *tooling* (PostCSS config, Tailwind config pointing to content dirs, theme provider wrapper) but NEVER pick colors, typography, or spacing scales. Those are human decisions.

### Verdict

Fixable, but only if scoped very narrowly to tooling setup, not aesthetic decisions. The research recommends too much ("base design config") — pare it down to "install + init the design framework the user chose, nothing more."

---

## Issue 2: Story Linking (Step 4e parent parameter indirection)

### Challenge

The research partially refuted this — the information exists in `docs/reference/trackers.md`. The proposed fix is to inline the parameter name in `SKILL.md:533`. But here is the deeper question: **will inlining actually help?**

The LLM executing Step 4e is an opus or sonnet model processing a ~800-line skill file. Inlining `parent: {issue-id}` for YouTrack into line 533 means the model sees it in context when it reaches that step. This IS more reliable than cross-file lookup. But the real failure mode is not "LLM doesn't know the parameter name" — it is "LLM constructs the MCP tool call incorrectly."

### Risks

1. **MCP tool schema mismatch:** Even if the instruction says `parent: {issue-id}`, the actual MCP tool's parameter name could differ from what we document. Our `trackers.md` says `parent: {issue-id}` for YouTrack, but the actual `@vitalyostanin/youtrack-mcp` tool might accept `parentIssue` or `subtaskOf` or something else entirely. We are documenting *conventions*, not verified API contracts.
2. **Multi-tracker divergence:** Inlining the parameter for all 4 native-sub-issue trackers (YouTrack, Jira, Linear, Redmine) in one instruction line makes that line very long and hard to parse. The LLM might grab the wrong tracker's parameter.
3. **False fix:** If the real reason linking fails is that the MCP tool silently ignores the parent parameter (returns success but doesn't create the link), inlining the name won't help at all. We would need a verification step.

### Mitigations

1. **Inline with per-tracker conditional blocks** rather than cramming all 4 into one line. Use a format like:
   ```
   - YouTrack: pass `parent: {epic-issue-id}`
   - Jira: pass `parent: {epic-issue-id}` and `issuetype: "Sub-task"`
   - Linear: pass `parentId: {epic-issue-id}`
   - Redmine: pass `parent_issue_id: {epic-issue-id}`
   ```
   This is unambiguous per tracker.
2. **Add a verification sub-step:** After creating the sub-issue, read it back and confirm the parent field is set. If not, log a warning. This catches silent MCP failures.
3. **Keep the cross-reference in `trackers.md` too** — do not remove it. The inline is a reliability improvement, not a replacement.

### Verdict

Low risk fix, but the inline alone is insufficient. The real value comes from the verification sub-step. Without verification, we are optimizing the wrong thing — we are making the instruction clearer when the actual failure might be in the MCP tool itself.

---

## Issue 3: Story Closing (Step 8b cascade close assumption)

### Challenge

The research confirmed this is a real bug. The fix seems obvious: always close story sub-issues explicitly. But there are real risks with "always close everything."

### Risks

1. **Double-close API errors:** If a tracker DOES have cascade close configured (some YouTrack projects do), and we also explicitly close child issues, we will attempt to close already-closed issues. What happens?
   - **YouTrack:** Applying `State: Done` to an already-Done issue is a no-op (idempotent). Safe.
   - **Jira:** Calling `transition:Done` on an already-Done issue returns an error ("No valid transition from Done to Done"). This WILL cause WARN logs and potentially a perceived failure.
   - **Linear:** Setting `state:Done` on an already-Done issue is idempotent. Safe.
   - **Redmine:** Setting `status:Closed` on an already-Closed issue depends on workflow configuration — may fail if "Closed -> Closed" transition is not allowed.
   - **GitHub/Gitea:** `close` on an already-closed issue is idempotent. Safe.
2. **Rate limiting:** For a large scaffold with 5 epics x 5 stories = 25 story issues, explicitly closing all 25 hits the tracker API 25 times in rapid succession. YouTrack and Jira have rate limits that could throttle or block us.
3. **Partial close state:** If closing story 12 of 25 fails (API timeout, rate limit), we have an inconsistent state. Some stories closed, some not. The current "skip on error" behavior (line 744: `On failure: WARN, continue`) handles this, but the user sees a mix.

### Mitigations

1. **Wrap each close in a try-catch equivalent** (already done per line 744). But additionally: if the error message indicates the issue is already in the target state (e.g., Jira's "no valid transition"), treat it as success, not a warning.
2. **Add a note in the instruction** acknowledging idempotency: "If the issue is already in the Done state, skip without warning." This prevents noisy logs.
3. **Do NOT add a `Cascade close` config key.** The research suggested this as an alternative, but it shifts complexity to the user. Users do not know whether their YouTrack project has cascade rules. The correct behavior is: always close explicitly, handle already-closed gracefully. One code path, not two.
4. **Consider batching:** If the tracker MCP tool supports batch operations (Jira does via bulk transition), use it. Otherwise, sequential with per-issue error handling is fine.

### Verdict

Correct fix direction. The risk is not in the fix logic but in error handling for already-closed issues. The instruction must explicitly say: treat already-in-target-state as success. Without this, Jira and Redmine users will see spurious warnings.

---

## Issue 4: No Comments (No implementation summary posted to tracker)

### Challenge

The research says "developers browsing YouTrack/Jira after a scaffold run see bare issues with no activity trail." True. But the deeper question is: **what comment would actually be useful?**

Generic comments like "Implementation completed. See PR #42." are noise. They tell the developer nothing they couldn't find by looking at the PR. The issue tracker becomes a wall of bot comments that people learn to ignore.

### Risks

1. **Comment fatigue:** If every scaffold run dumps 10-25 comments (one per epic + one per story), the issue tracker fills with automation noise. Developers stop reading comments entirely.
2. **Stale information:** A comment saying "Implemented in branch `scaffold/my-project`" becomes misleading if the branch is later deleted or rebased. Comments are permanent; branch state is not.
3. **What content is actually available?** At Step 8b/9, the pipeline has: branch name, list of implemented features (from architect decomposition), list of blocked features, and possibly a PR link. It does NOT have: lines of code changed, test coverage, or detailed implementation notes. So the comment will necessarily be high-level.
4. **Comment permission failures:** Some tracker configurations restrict bot comments. If the MCP tool lacks comment permission, we get a block or warning on what should be a non-critical step.

### Mitigations

1. **One comment per epic, not per story.** Aggregate the information. An epic-level comment saying "5/5 stories implemented, branch: `scaffold/foo`, PR: #42" is useful. 5 individual story comments saying "Implemented" are not.
2. **Make comments structured and scannable:**
   ```
   [ceos-agents] Scaffold implementation complete
   Stories: 5/5 implemented
   Branch: scaffold/my-project
   PR: https://...
   Blocked: none
   ```
   This is machine-parseable (for future `/status` or `/resume-ticket` use) and human-scannable.
3. **Make it optional with a sensible default.** Add it as default-on behavior but allow `Post comments: false` in Automation Config for teams that prefer quiet trackers. Actually, scratch that — the plugin already has a pattern of posting checkpoint comments (triage, spec-analyst). This is consistent with that pattern. Keep it mandatory.
4. **Fail gracefully:** If the comment post fails, WARN and continue. Never block the pipeline over a comment failure.

### Verdict

Useful fix, but only if the comment contains genuinely new information (aggregated story status + PR link) and is posted at the epic level only. Per-story comments are pure noise.

---

## Issue 5: Diacritics (Agents drop diacritics from non-ASCII input)

### Challenge

This is the hardest issue to fix reliably. The research recommends adding a constraint like "NEVER transliterate or remove diacritics." But LLMs do not drop diacritics because of a missing instruction — they drop them because of tokenization artifacts, training data biases (English-dominant), and the tendency to "normalize" text during reformulation.

Adding "preserve diacritics" to an agent prompt is like adding "don't make mistakes" — the model already "knows" it should preserve text, but it fails because the failure is not a policy problem, it is a capability problem.

### Risks

1. **Instruction ignored under pressure:** When the model is processing a long pipeline step with many sub-instructions, a single-line constraint like "preserve diacritics" is easily deprioritized. The model's attention budget is finite.
2. **Partial preservation:** The model might preserve diacritics in titles (visible, short) but drop them in longer description text where it paraphrases. The instruction does not distinguish between verbatim copying and content generation.
3. **Over-correction:** If we tell the model to "preserve original encoding," it might become overly literal — refusing to translate or summarize Czech text into English where English IS the correct output (e.g., PR descriptions, which must be in English per publisher constraints).
4. **Testing difficulty:** How do we verify this works? There is no automated test in `tests/` that can check whether an LLM preserved diacritics. It is a non-deterministic quality property.
5. **Scope of affected agents:** The research says to fix triage-analyst, spec-analyst, spec-writer, and publisher. But the fixer, architect, reviewer, and scaffolder also process user-provided text (issue titles, feature descriptions). The fix needs to be broader.

### Mitigations

1. **Be specific about WHAT to preserve.** Instead of "preserve diacritics," say: "When copying text from issue tracker fields (titles, descriptions, comments) into your output, preserve the EXACT original characters including diacritics (e.g., c, r, z, s, e, u, a, n, o). NEVER transliterate non-ASCII characters to ASCII equivalents."
2. **Distinguish copy vs generate.** The instruction should clarify: "This applies to TEXT COPIED from user input. When GENERATING new text (e.g., synthesizing acceptance criteria, writing summaries), use the same language as the source material."
3. **Add to ALL agents that read from or write to tracker, not just 4.** The research under-scopes this. At minimum: triage-analyst, spec-analyst, spec-writer, publisher, code-analyst, fixer (commit messages may reference issue titles), architect (task descriptions), acceptance-gate.
4. **Add to a shared preamble, not individual files.** If this constraint needs to be in 8+ agents, it should be in a shared location. But — this plugin has no shared preamble mechanism. Each agent is standalone markdown. So we either: (a) duplicate the instruction in each file, or (b) add it to a core contract file that agents reference. Option (a) is ugly but reliable (the instruction is in context). Option (b) requires agents to read another file (same cross-reference problem as Issue 2).
5. **Accept imperfection.** Even with the instruction, LLMs will occasionally drop diacritics. The instruction reduces frequency but does not eliminate the problem. Document this as a known limitation.

### Verdict

The fix will help but is not a complete solution. The instruction must be specific (list actual characters), scoped correctly (copy vs generate), and applied broadly (8+ agents, not just 4). Even then, expect occasional failures. The alternative — mechanically preserving text via non-LLM code — is not possible in this pure-markdown plugin architecture.

---

## Cross-Cutting Risks

### Risk: Prompt length inflation
Adding instructions for diacritics (Issue 5) and design systems (Issue 1) to multiple agents increases prompt length. For agents already near context limits (scaffolder is 132 lines, spec-writer is 95 lines), additional instructions compete for attention with existing ones.

**Mitigation:** Keep new instructions surgically short. One constraint line per agent, not a paragraph.

### Risk: Config contract creep
Issues 1 and 4 might suggest new optional config keys (`Design System`, `Post comments`). Each new key is maintenance burden and documentation debt.

**Mitigation:** Issue 1 should NOT add a config key — design system choice goes in the spec, not the config. Issue 4 should NOT add a config key — always post comments, fail gracefully.

### Risk: Version level disagreement
Issue 1 (design system) is arguably a MINOR version feature. Issues 2, 3, 4, 5 are bug fixes (PATCH). Shipping them together in one release muddles the version semantics.

**Mitigation:** Ship issues 2-5 as a PATCH release. Ship issue 1 as a separate MINOR release, or defer it entirely.

---

## Summary: Priority-Ordered Recommendations

| Issue | Skeptic's Risk Level | Fix Viable? | Key Condition for Success |
|-------|---------------------|-------------|--------------------------|
| 3 (Cascade close) | Medium | Yes | Must handle already-closed issues as success, not warning |
| 5 (Diacritics) | High | Partially | Must be specific (list chars), broad (8+ agents), and accept imperfection |
| 4 (Comments) | Low | Yes | Must be epic-level only, structured, and fail-graceful |
| 2 (Story linking) | Low | Yes | Inline helps, but add verification sub-step for real reliability |
| 1 (Design quality) | High | Barely | Only viable if scoped to tooling init, not aesthetic choices |
