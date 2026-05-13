# Phase 2 Research Answers — Category C: Publisher & Newline Handling

**Agent:** agent-2
**Category:** C — Publisher & Newline Handling
**Files read:** `agents/publisher.md`, `skills/fix-ticket/SKILL.md`, `skills/implement-feature/SKILL.md`, `core/block-handler.md`, `core/post-publish-hook.md`

---

## C1: Does `agents/publisher.md` Step 6 give explicit encoding instruction for multi-line PR body?

**Answer: NO. Step 6 gives zero encoding guidance.**

### Evidence

**Step 6 (lines 58–71 of `agents/publisher.md`):**

```
6. **Create Pull Request**

   - **Title:** Use issue summary (from issue tracker), NOT the branch name. Format is mode-dependent:
     - Bug-fix mode: `[PROJ-123] Fix: {concise description}`
     - Feature mode: `[PROJ-123] Feat: {concise description}`
     - Scaffold mode: `[PROJ-123] Scaffold: {concise description}`
   - **Description:** Use PR Description Template from Automation Config (always English). Fill in ALL template sections:
     - Summary, Changes, Testing, Issue link
     - Bug-fix mode: include **Root Cause** section
     - Feature/scaffold mode: include **Objective** section (replaces Root Cause)
   - **Labels:** Add labels from Automation Config (PR Rules section). If Extra labels section exists, add those too.
     - **Label ID resolution:** Some MCP servers (e.g., Gitea) require numeric label IDs for PR creation but may not return IDs from the label listing tool. ...
   - **Base branch:** From Automation Config (Source Control section)
   - Use the source control MCP server corresponding to the Remote format (e.g., Gitea API for gitea instances, GitHub API for github.com) for PR creation.
```

**Key finding:** Step 6 instructs the publisher to fill a multi-line PR Description Template, but contains **no instruction about how to pass it to the MCP tool**. There is no mention of:
- Heredocs
- String escaping
- Newline encoding (`\n` vs literal)
- JSON serialization
- Any other formatting strategy

The PR description is inherently multi-line (it has sections: Summary, Changes, Testing, Issue link, Root Cause/Objective). This is a **vulnerability gap** — the publisher agent receives no guidance on how to safely encode this multi-line content when invoking the MCP tool.

**Constraints section (lines 88–103):** Also contains no encoding guidance. The only PR-description constraint is:

> Line 94: `- PR description always in English`
> Line 95: `- On failure: Block using the Block Comment Template:`

No mention of heredocs, escaping, or multi-line string handling anywhere in the Constraints.

---

## C2: Does `agents/publisher.md` Step 7 post multi-line or single-line content? Does Constraints section give encoding guidance for Block Comment Template?

**Answer: Step 7 posts single-line-safe content. Constraints show the Block Comment Template as a multi-line literal with NO encoding guidance.**

### Step 7 Analysis (lines 73–76)

```
7. **Update Issue Tracker**

   - Set issue state: "For Review" (or equivalent from Automation Config → State transitions)
   - Add comment to issue with PR link
```

**Content safety:** "Add comment to issue with PR link" — a PR link is a single URL (e.g., `https://gitea.example.com/owner/repo/pulls/42`). This is a single-line, plain-text value with no special characters. **This operation is safe from newline-encoding issues.**

However, Step 7 contains no further detail about what the comment body looks like (no template shown). It is plausible the agent adds context beyond just the URL, but no multi-line template is mandated here.

### Block Comment Template in Constraints (lines 95–103)

The Constraints section shows this template inline:

```
[ceos-agents] 🔴 Pipeline Block
Agent: publisher
Step: Publish
Reason: {reason}
Detail: {technical output — git error, API error}
Recommendation: {what the human should do}
```

**Key findings:**
1. The Block Comment Template is a **6-line multi-line string** — it contains literal newlines.
2. There is **no encoding instruction** attached to it — no mention of heredocs, `\n` escaping, or MCP parameter formatting.
3. This template is meant to be posted as a comment to the issue tracker via MCP. Passing it verbatim (with literal newlines) inside a JSON string or tool parameter without encoding would cause malformed requests.
4. This same encoding gap exists in **every other agent** that references the Block Comment Template, as the template is defined in CLAUDE.md and referenced as context instructions throughout the pipeline.

---

## C3: Do subtask issue description templates in `fix-ticket/SKILL.md` Step 4b-tracker and `implement-feature/SKILL.md` Step 5a have encoding guidance?

**Answer: NO. Both templates are multi-line and both lack any encoding guidance.**

### fix-ticket/SKILL.md — Step 4b-tracker (lines 369–383)

The "Issue Description Template" section is at lines 369–383:

```markdown
**Issue Description Template:**

```markdown
{subtask.scope}

Addresses: {subtask.maps_to[0]}, {subtask.maps_to[1]}, ...

Files: {subtask.files[0]}, {subtask.files[1]}, ...

Parent issue: {ISSUE_ID}
```

- If `maps_to` is empty, omit the "Addresses:" line.
- If `files` is empty, omit the "Files:" line.
- The "Parent issue:" line is always present.
```

**Content analysis:** This is a **4-section multi-line template** with blank-line separators. It will contain literal `\n` characters when rendered.

**MCP call context (lines 256–305):** The `issue_description` variable built from this template is passed directly to tracker-specific MCP tools:
- `description: issue_description` (YouTrack, Jira, Linear, Redmine)
- `body: issue_description` (GitHub, Gitea)

**Encoding guidance:** **None.** No heredoc pattern, no `\n` substitution, no JSON escape instruction is mentioned anywhere in Step 4b-tracker.

### implement-feature/SKILL.md — Step 5a (lines 415–429)

The "Issue Description Template" section is at lines 415–429:

```markdown
**Issue Description Template:**

```markdown
{subtask.scope}

Addresses: {subtask.maps_to[0]}, {subtask.maps_to[1]}, ...

Files: {subtask.files[0]}, {subtask.files[1]}, ...

Parent issue: {ISSUE_ID}
```

- If `maps_to` is empty, omit the "Addresses:" line.
- If `files` is empty, omit the "Files:" line.
- The "Parent issue:" line is always present.
```

**Finding:** The template in `implement-feature/SKILL.md` Step 5a is **byte-for-byte identical** to the one in `fix-ticket/SKILL.md` Step 4b-tracker (same lines 415–429 vs 369–383 respectively). The MCP call structure is also identical (lines 302–352 in implement-feature mirror lines 256–305 in fix-ticket).

**Encoding guidance:** **None.** Same gap — multi-line body passed to MCP with no encoding instruction.

### Summary for C3

Both templates are multi-line (4 sections with blank-line separators), both are passed to MCP tools as `description` or `body` parameters, and **neither has any encoding guidance**. This is the same vulnerability pattern as C1 and C2.

---

## C4: Does `core/block-handler.md` Steps 3-4 give newline encoding guidance? Does `core/post-publish-hook.md` use a heredoc pattern?

**Answer: block-handler.md has NO encoding guidance for the block comment. post-publish-hook.md DOES use a heredoc and explicitly explains why — this is the only encoding-aware pattern in the codebase.**

### core/block-handler.md — Steps 3–5

**Step 3 (lines 24–27):**
```
3. **On block action** (per config → Error Handling → On block; default: `comment`):
   - `comment`: post block comment only.
   - `close`: post block comment + close the issue.
   - Other value: interpret as a custom action; always post a block comment.
```

No encoding guidance.

**Step 4 (lines 28–36):**
```
4. **Post block comment** to the issue tracker:
   ```
   [ceos-agents] 🔴 Pipeline Block
   Agent: {agent_name}
   Step: {step_name}
   Reason: {reason}
   Detail: {detail}
   Recommendation: {recommendation}
   ```
```

**Key finding:** Step 4 shows the Block Comment Template as a 6-line multi-line literal. The instruction is simply "Post block comment to the issue tracker" — **zero guidance on how to encode the newlines** when passing this to the MCP tool. The MCP call is not shown at all; the agent is left to figure out the encoding on its own.

**Step 5 (lines 37–42) — Webhook:** The webhook `curl` command at line 39 uses an inline `-d` flag with a single-line JSON payload:
```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"issue-blocked","issue_id":"{issue_id}","agent":"{agent_name}","reason":"{reason}","timestamp":"{ISO8601}"}' \
  "{Webhook URL}"
```
This is single-line JSON (no multi-line body in the webhook payload), so no heredoc is needed here. The `reason` field is constrained to max 2 sentences, making it relatively safe.

### core/post-publish-hook.md — Heredoc Pattern

**Lines 17–23:**
```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  --data-binary @- "{Webhook URL}" <<EOF
{"event":"pr-created","issue_id":"${issue_id}","pr_url":"${pr_url}","timestamp":"${ISO8601}"}
EOF
```

Followed by the **explicit rationale at line 23:**
> `Note: Use a heredoc to pass the JSON body so that special characters (quotes, backslashes) in variable values do not break the shell command.`

**Key findings:**
1. `post-publish-hook.md` is the **only file in the codebase** that uses a heredoc for encoding and provides an explicit rationale for why.
2. The note on line 23 precisely identifies the problem: special characters in variable values break inline shell commands. This same problem applies to multi-line PR descriptions, block comments, and subtask descriptions — but only `post-publish-hook.md` addresses it.
3. However, the heredoc here is for a **`curl` shell command** (Bash), not for MCP tool calls. MCP tool calls are different — they pass parameters as structured tool inputs, not shell strings. The heredoc pattern here is the correct model for Bash-based calls but does not directly translate to MCP tool parameter encoding.
4. The PR description (C1), block comment (C2/C4), and subtask descriptions (C3) are all passed to **MCP tools** (not curl), where the encoding problem manifests differently: the agent must serialize multi-line strings into the tool's parameter format correctly.

---

## Cross-Cutting Summary

| Location | Multi-line content | Encoding guidance |
|----------|-------------------|-------------------|
| `agents/publisher.md` Step 6 — PR description | YES (multi-section template) | NONE |
| `agents/publisher.md` Step 7 — PR link comment | NO (single URL) | N/A (safe) |
| `agents/publisher.md` Constraints — Block Comment Template | YES (6-line template) | NONE |
| `core/block-handler.md` Step 4 — Block comment | YES (6-line template) | NONE |
| `core/block-handler.md` Step 5 — Webhook payload | NO (single-line JSON) | N/A (safe) |
| `skills/fix-ticket/SKILL.md` Step 4b-tracker — Issue Description Template | YES (4-section template) | NONE |
| `skills/implement-feature/SKILL.md` Step 5a — Issue Description Template | YES (4-section template, identical) | NONE |
| `core/post-publish-hook.md` — Webhook curl | NO (single-line JSON) | YES (heredoc + rationale) |

**Pattern:** The codebase has one encoding-aware pattern (`post-publish-hook.md` heredoc for curl) but it is applied only to a safe (single-line) case. All genuinely multi-line MCP payloads — PR descriptions, block comments, and subtask issue descriptions — have no encoding guidance whatsoever.

**The `post-publish-hook.md` heredoc with its explanatory note is the correct model** that could be generalized as guidance for multi-line MCP parameter passing, but it has not been applied elsewhere.
