# Agent 2 — Research Questions: Publisher Literal `\n` in PR Body

**Scope:** Publisher agent flow, block comment posting, MCP body-accepting call sites, newline handling

---

## Q1: How does the publisher agent construct the PR description body — does it interpolate template variables as literal text or as a pre-built multi-line string passed to the MCP tool?

**Files to read:** `agents/publisher.md` (Step 6)

**Context:** Step 6 of `agents/publisher.md` says to fill the PR Description Template from Automation Config, including sections for Summary, Changes, Testing, Issue link, Root Cause / Objective. The instruction does not specify how the filled template string is passed to the MCP `create_pull_request` call — whether it is a single inline string value (where the LLM may emit `\n` escape sequences instead of real newlines), or a multi-line HEREDOC-style value. This is the primary source of Bug 2: if the LLM constructs the `body` parameter as an inline JSON string with literal `\n`, the Gitea/GitHub API will render those as two characters rather than line breaks.

**Research question:** Does Step 6 in `agents/publisher.md` provide any explicit instruction on how to pass the multi-line `body` parameter to the MCP tool — and does the Constraints section prohibit or allow inline escape sequences?

---

## Q2: Does the block comment template (as shown in `core/block-handler.md` Step 4) use literal newlines or escaped `\n` sequences — and is the comment posted via a MCP tool call where the same rendering bug could occur?

**Files to read:** `core/block-handler.md` (Steps 3–4)

**Context:** `core/block-handler.md` Step 4 shows the block comment as a multi-line fenced block inside the markdown spec. When the orchestrating skill or the block-handler dispatches an MCP `add_comment` / `create_issue_comment` call, the multi-line body of the comment must contain real newlines, not `\n` escape sequences — otherwise Gitea/GitHub/Redmine will render the block comment as a single run-on line. The same rendering bug reported for PR bodies could silently affect block comments across every tracker type.

**Research question:** Is there any explicit guidance in `core/block-handler.md` (or in the skills that call it) instructing the agent to pass real newlines to the MCP comment tool, or does it leave newline encoding up to the LLM? Do `fix-ticket` and `implement-feature` pass a raw multi-line string or construct one from template variables?

---

## Q3: For GitHub/Gitea tracker subtask creation, the `body` parameter of `create_issue` is constructed from a multi-line markdown template (`{subtask.scope}`, `Addresses:`, `Files:`, `Parent issue:`) — are there any inline-string pitfalls when the LLM fills this template?

**Files to read:** `skills/fix-ticket/SKILL.md` (Step 4b-tracker, "Issue Description Template"), `skills/implement-feature/SKILL.md` (Step 5a, "Issue Description Template")

**Context:** Both `fix-ticket` and `implement-feature` build a multi-line issue description from the subtask's scope text and metadata fields, then pass it as the `body` parameter to the GitHub/Gitea MCP `create_issue` tool. The template contains blank lines (paragraph separators) between the scope, Addresses, Files, and Parent issue lines. If the LLM assembles this as an inline string with `\n` separators, those separators will appear literally in the rendered issue body. This is structurally identical to the PR body bug.

**Research question:** Does the issue description template in step 4b-tracker / step 5a include any guidance on how to pass the multi-line `body` to the MCP tool (e.g., write to a temp file, use heredoc, pass as a JSON string)? Is the `body` construction delegated to the LLM with no encoding contract?

---

## Q4: The `post-publish-hook.md` webhook fires a JSON body via `curl --data-binary @-` with a heredoc — does this pattern guarantee real newlines, and is the same heredoc pattern used anywhere in the PR creation or comment posting paths?

**Files to read:** `core/post-publish-hook.md`, `agents/publisher.md` (Step 6), `core/block-handler.md` (Step 5)

**Context:** `core/post-publish-hook.md` explicitly uses a shell heredoc (`<<EOF`) to pass JSON to `curl`, with the comment: "Use a heredoc to pass the JSON body so that special characters … do not break the shell command." This pattern avoids the `\n` literal problem for webhook calls. However, PR creation and issue comment posting go through MCP tool calls (not raw curl), where the LLM supplies parameter values as strings. The question is whether the MCP tool layer handles newline encoding, or whether the LLM must supply the string with real newline characters in the tool call JSON.

**Research question:** Does any file in the plugin (publisher, block-handler, fix-ticket, implement-feature) instruct the agent to use a file-based or heredoc approach when passing multi-line text to MCP tools — or is the heredoc pattern used only for the webhook curl call, leaving MCP body parameters unguarded against `\n` literal output?

---

## Q5: Does Step 7 of `agents/publisher.md` (Update Issue Tracker — "Add comment to issue with PR link") use a MCP `add_comment` call with a plain single-line string or a multi-line markdown string — and could the same `\n` literal bug affect it?

**Files to read:** `agents/publisher.md` (Step 7), `core/block-handler.md` (Step 4)

**Context:** Step 7 says to "add comment to issue with PR link." This is likely a single-line or short comment, but the publisher's Constraints section includes a multi-line Block Comment Template (lines 95–103 of `publisher.md`) that the publisher must also produce when blocking. If the publisher constructs that multi-line block comment as an inline string for a MCP `add_comment` call, the `\n` bug applies there too. The renderer for Gitea issue comments uses the same markdown engine as PR bodies.

**Research question:** Does `agents/publisher.md` give any explicit encoding instruction for the Block Comment Template it must post (Constraints section, lines 95–103)? Is the PR link comment in Step 7 a single-line call (safe) or does it include markdown formatting (vulnerable)?

---

## Q6: What is the actual MCP tool parameter type for the Gitea `create_pull_request` body field — does the MCP server accept a string with real newlines, or does it require a pre-escaped value — and does the GitHub MCP tool behave the same way?

**Files to read:** Any MCP config or tool-schema files under `.ceos-agents/`, `examples/`, or `docs/` that document the Gitea/GitHub MCP tool signatures; also check `skills/init/SKILL.md` and `docs/reference/` for MCP server setup guidance.

**Context:** The root cause of Bug 2 may be either (a) the LLM emitting `\n` escape sequences as two characters when constructing the tool call JSON, or (b) the MCP server receiving a correctly-encoded string but the Gitea API requiring a different encoding. Understanding the MCP tool's parameter contract (string with embedded newlines vs. escaped string) determines whether the fix belongs in the agent prompt (instruct the LLM to use real newlines) or in a pre-processing step (normalize the string before passing to the tool).

**Research question:** Is there any documentation in the repo (examples, reference docs, init skill) that specifies how the Gitea or GitHub MCP server expects multi-line string parameters — specifically whether the `body` field of `create_pull_request` should contain real newline characters (`\n` as Unicode LF) or JSON-escaped sequences (`\\n` as two characters)? Does the Redmine MCP tool use the same or a different convention for its `description` field?
