---
name: Bug Report
about: Something isn't working as expected
labels: ["bug", "needs-triage"]
---

<!--
BEFORE FILING: Search open AND closed issues first.
If your issue already exists, add a comment or reaction instead of opening a new one.
-->

- [ ] I searched existing issues and this is not a duplicate

## Environment

| Field | Value |
|-------|-------|
| agent-flow version | |
| Claude Code version | |
| OS + shell | |
| Model used | |
| Issue tracker type (youtrack/github/gitea/etc.) | |

## Is this an agent-flow issue or a Claude Code issue?

<!--
agent-flow is a plugin that orchestrates Claude Code agents. Some reported bugs
are actually Claude Code core issues or model behavior issues.

Try reproducing without agent-flow installed. If the problem persists, file with Anthropic instead.
-->

- [ ] I confirmed this issue does not occur without agent-flow installed

## What happened?

<!-- Be specific. "It doesn't work" is not a bug report. -->

## Steps to reproduce

1.
2.
3.

## Expected behavior

## Actual behavior

## Pipeline log / transcript

<!--
This is the single most helpful thing you can include.
Attach .agent-flow/pipeline.log or paste the relevant section below.
Redact any credentials, API keys, or internal URLs before posting.
-->

<details>
<summary>pipeline.log excerpt</summary>

```
paste here
```

</details>

## state.json snapshot (if relevant)

<!--
If the pipeline got stuck or produced wrong state, paste the relevant fields from
.agent-flow/{ISSUE_ID}/state.json (redact sensitive values).
-->

## Additional context

- [ ] I have reviewed this report for sensitive data before submitting
