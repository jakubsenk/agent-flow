# Agent 2 Research Findings

## RQ-3: Existing Implementation Comment Patterns

### fix-ticket/SKILL.md — Post-Implementation Comments

**Fix Verification (Step 9d):** `fix-ticket` has a conditional "Fix Verification" step after PR merge. It calls `core/fix-verification.md`, which posts two comment patterns:

- **On success** (line 21 of core/fix-verification.md):
  ```
  [ceos-agents] ✅ Fix verified. Verify command: `{command}`. Output: {first 500 chars}.
  ```
- **On failure** (lines 26-29 of core/fix-verification.md):
  ```
  [ceos-agents] ❌ Fix verification failed.
  Command: `{command}`
  Output: {first 500 chars}
  ```

This step is **optional** — only fires when `Build & Test → Verify` exists in Automation Config. It is invoked post-merge (after PR is merged).

**Block handler (Step X):** fix-ticket posts a block comment to the issue tracker via `core/block-handler.md` whenever any pipeline step fails:
```
[ceos-agents] 🔴 Pipeline Block
Agent: {agent name}
Step: {pipeline step}
Reason: {max 2 sentences}
Detail: {error output}
Recommendation: {what human should do}
```

**No implementation-summary comment:** fix-ticket does NOT post a comment summarizing what was implemented after the fix. The only tracker comments are: (a) the triage checkpoint comment, (b) the block comment if blocked, (c) the verification comment post-merge (from fix-verification.md), and (d) the PR link comment added by the publisher (Step 9 → publisher agent → Step 7: "Add comment to issue with PR link").

### implement-feature/SKILL.md — Post-Implementation Comments

**Feature Verification (Step 10b):** implement-feature has the exact same post-merge verification pattern, quoting from the skill itself (lines 376-380):

- **On verification OK** (line 376-377):
  ```
  [ceos-agents] ✅ Feature verified. Verify command: `{command}`. Output: {first 500 chars}.
  ```
- **On verification FAIL** (lines 379-380):
  ```
  [ceos-agents] ❌ Feature verification failed. Command: `{command}`. Output: {first 500 chars}.
  ```

**Block handler (Step X):** Same `[ceos-agents] 🔴 Pipeline Block` pattern.

**No implementation-summary comment:** Like fix-ticket, implement-feature does NOT post a comment to the tracker summarizing what was implemented. Publisher adds the PR link comment.

### publisher.md — Comment Patterns

**Step 7 of publisher.md** (line 67-68):
> "Set issue state: "For Review" (or equivalent from Automation Config → State transitions)"
> "Add comment to issue with PR link"

The publisher posts a **PR link comment** to the issue tracker. The exact format of this comment is not prescribed in publisher.md — only that it includes the PR link. This is the primary post-implementation tracker comment in the normal (non-blocked) flow.

### publish/SKILL.md — Comment Patterns

**Step 7** (line 27):
> "Comment in issue tracker with PR link"

The standalone publish skill also adds a PR link comment. No further format detail is given.

### Summary for RQ-3

| Pipeline | Comment Type | Format | Condition |
|----------|-------------|--------|-----------|
| fix-ticket + implement-feature | Block comment | `[ceos-agents] 🔴 Pipeline Block` | On any pipeline failure |
| fix-ticket + implement-feature | Verification pass | `[ceos-agents] ✅ Fix/Feature verified.` | Post-merge, if Verify configured |
| fix-ticket + implement-feature | Verification fail | `[ceos-agents] ❌ Fix/Feature verification failed.` | Post-merge, if Verify configured and fails |
| publisher (all pipelines) | PR link comment | Unspecified format, contains PR URL | Always, after PR creation |
| triage (fix-ticket only) | Triage checkpoint | `[ceos-agents] Triage completed. Severity: ...` | After successful triage |

**Key finding:** Neither pipeline posts a structured "implementation summary" comment after implementation is done. The only implementation-context comment is the PR link from the publisher. A scaffold pipeline that wants to post a completion summary to the tracker (e.g., "project was created, here is the Gitea repo link") would be introducing a NEW comment pattern not present in fix-ticket or implement-feature.

---

## RQ-4: Language Fidelity in Agent Definitions

### skills/onboard/SKILL.md — "Language Rules" Section

Exact text found at lines 191-196 of `skills/onboard/SKILL.md`:

```
Language rules:
1. All keys in English — exactly per `docs/reference/automation-config.md`
2. All identifier values in English (State transitions, Branch naming, Labels, Profile names)
3. User-provided values preserved as-is (URLs, project names, commands)
4. Table format always (`| Key | Value |`) — never bullet-point lists
5. PR Description Template section headings always in English
```

This is a config generation rule for the onboard wizard — it specifies that the Automation Config KEYS and identifier VALUES must be in English, but user-provided strings (URLs, names, commands) are preserved verbatim.

### agents/*.md — Language/Locale Mentions

Searching all agent definitions for language/locale/English/Czech:

**publisher.md** — Two explicit English language requirements:
- Line 46: `"Commit with message: concise English summary referencing issue ID"`
- Line 58: `"**Description:** Use PR Description Template from Automation Config (always English)."`
- Line 86 (Constraints): `"PR description always in English"`

**scaffolder.md** — Programming language references only (not output language):
- Line 33: `".gitignore (language-specific)"` — refers to programming language
- Line 129: `"NEVER deviate from language-specific directory conventions (Python: src/{package}/, Node: src/, Go: cmd/ + internal/, etc.)"` — refers to programming language

**stack-selector.md** — Programming language references only:
- Line 17: `"Programming language ecosystems..."` — expertise descriptor
- Line 24: `"Language and framework preference"` — input from user
- Line 29: `"If critical information is missing (language or project type unclear)..."` — programming language
- Line 33: `"**Language + version:** specific stable version..."` — tech stack selection

**test-engineer.md** — Programming language reference only:
- Line 32: `"create the test file following language conventions (e.g., tests/test_{module}.py for Python, {module}.test.ts for TypeScript)"` — programming language

**All other agents (19 total):** No language, locale, Czech, or English mentions found.

### skills/scaffold/SKILL.md — Language Handling

All "language" references in scaffold/SKILL.md are about programming language (tech stack), not output language:
- Line 11: `"project description (natural language)"` — user input
- Line 20: `"--lang <value> → preset language"` — programming language flag
- Line 265: `"Output: structured decision (language, framework, database, testing, linting, CI, containerization)"` — tech stack
- Lines 312, 486: `"Stack: {language} + {framework}"` — tech stack display

No output-language or locale instructions exist in scaffold/SKILL.md.

### core/*.md — Language Instructions

No matches found for language, locale, Czech, or English in any of the 11 core files:
- `agent-override-injector.md`
- `block-handler.md`
- `config-reader.md`
- `decomposition-heuristics.md`
- `fix-verification.md`
- `fixer-reviewer-loop.md`
- `mcp-detection.md`
- `mcp-preflight.md`
- `post-publish-hook.md`
- `profile-parser.md`
- `state-manager.md`

### Repo-Wide Language Pattern Summary

The search across the entire repo (with `-i` flag) found:

1. **Active output language rules** (in current skills/agents):
   - `publisher.md`: PR description always in English; commit messages in English
   - `onboard/SKILL.md`: Automation Config keys and identifier values always in English
   - `CLAUDE.md` (plugin root): "PR descriptions always in English" (line in Key Conventions)

2. **Historical Czech references** (in CHANGELOG.md, docs/plans/, REVIEW-REPORT-v3.1.0.md):
   - The plugin was originally written in Czech and was fully translated to English in v3.0.0 (CHANGELOG line 554: "Full English translation: all 53 agent, command, test, config, and documentation files translated from Czech to English")
   - CHANGELOG.md line 8: "Language note: From version 3.0.0 onward, entries are in English"
   - Translation plan docs exist in `docs/plans/2026-03-02-docs-overhaul-phase-1-plan.md`

3. **Programming-language references** (NOT output language):
   - Multiple agents and scaffold skill reference "language" meaning programming language (Python, TypeScript, Go, etc.)
   - These are distinct from human output language instructions

### Key Finding for RQ-4

There are **no language/locale instructions in agent definitions** governing WHAT LANGUAGE agents should communicate in (other than publisher.md requiring English for PR descriptions and commit messages). There is no agent that explicitly instructs itself to respond in Czech, use diacritics, or adapt to user locale. The CLAUDE.md project conventions note (in MEMORY.md) that the convention is "Czech for user communication, English for all code/file content" — but this is a meta-level user preference, not encoded in any agent definition. Agents themselves are silent on output language except where English is explicitly required (publisher).
