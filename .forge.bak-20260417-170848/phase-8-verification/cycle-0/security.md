# Security Review — v6.7.2

**Reviewer:** security-reviewer (automated)
**Scope:** core/tracker-subtask-creator.md extraction, skill refactoring (fix-ticket, fix-bugs, implement-feature), webhook format alignment, block handler inline removal, documentation fixes
**Date:** 2026-04-16

## 1. Prompt Injection — External Tracker Content

### 1a. External Input Sanitizer References (PASS)

All 6 skills that process tracker data reference `core/external-input-sanitizer.md`:

| Skill | Line | Reference |
|-------|------|-----------|
| fix-ticket | 119 | Present |
| fix-bugs | 131 | Present |
| implement-feature | 170 | Present |
| resume-ticket | 85 | Present |
| analyze-bug | 23 | Present |
| scaffold | 412 | Present |

**Verdict:** No regressions. All skills that read external tracker content (title, description, comments) and pass it to agents continue to reference the sanitizer contract with the correct marker format.

### 1b. Tracker Subtask Creator — External Content Handling (OBSERVATION — LOW RISK)

`core/tracker-subtask-creator.md` does NOT reference `core/external-input-sanitizer.md`. However, this contract is a **write-only** contract — it creates issues in the tracker, it does not read external content and pass it to agents. The input it consumes (`subtask_list`) originates from the architect agent (internal), not from external tracker content.

**One edge case:** Lines 137-147 (GitHub/Gitea checklist) read `parent_body` via `MCP get_issue({issue_id}).body` and append to it. This is a write-back operation (updating the issue body), not an agent dispatch. The content read is used only to check for a sentinel and to preserve existing body text. No agent receives this content as prompt input. **Risk: negligible.**

The `subtask.title` and `subtask.scope` fields used in `build_description()` (lines 57-63) originate from the architect's task tree, which is an internal output, not directly from user-controlled tracker text. The architect itself receives sanitized external content (per the calling skill's sanitizer reference at the point of initial issue read). **No injection vector here.**

**Verdict:** PASS — no prompt injection risk from the extraction.

### 1c. Sentinel Injection in GitHub/Gitea Checklist (OBSERVATION — LOW RISK)

Lines 138-140: The sentinel `<!-- ceos-agents:decomposition-checklist:{issue_id} -->` uses `issue_id` which comes from the issue tracker. If an attacker could control the issue ID format (unlikely — IDs are system-generated), they could potentially inject HTML comments. However:
- Issue IDs are system-generated in all 6 supported trackers
- The sentinel check is `CONTAINS`, which is a read operation
- Even if the sentinel were forged in the existing body, the result would be a skip (no-op), not code execution

**Verdict:** PASS — acceptable risk.

## 2. Webhook Security — curl Flags

### 2a. Core Contracts (PASS)

| Location | `--max-time` | `--retry 0` | Format |
|----------|-------------|-------------|--------|
| core/post-publish-hook.md L18 | `--max-time 5` | `--retry 0` | heredoc (`--data-binary @-`) |
| core/block-handler.md L41 | `--max-time 5` | `--retry 0` | `-d` inline JSON |

Both core webhook contracts use proper timeout (5s) and no retry (0), preventing webhook calls from hanging the pipeline.

### 2b. Skill-Level Webhooks (PASS)

| Location | `--max-time` | `--retry 0` | Notes |
|----------|-------------|-------------|-------|
| fix-bugs/SKILL.md L478 (pipeline-complete) | `--max-time 5` | `--retry 0` | Correct |
| publish/SKILL.md L31 (pr-created) | `--max-time 5` | `--retry 0` | Correct |

### 2c. Webhook Format Alignment (PASS)

The v6.7.2 changes aligned webhook handling:
- `implement-feature` step 10a now delegates to `core/post-publish-hook.md` (line 441) — no inline curl
- `fix-bugs` step 8a delegates to `core/post-publish-hook.md` (line 426) — no inline curl
- `fix-bugs` step 8b says "Handled by `core/post-publish-hook.md` (invoked in step 8a above). No additional action needed." — correct delegation
- The pipeline-complete webhook in fix-bugs step 9a (line 478) remains inline — this is correct because it is a different event type not covered by the post-publish-hook core contract

**Verdict:** PASS — all webhook calls use proper security flags.

### 2d. Sprint-Plan curl Commands (OUT OF SCOPE — pre-existing)

The sprint-plan skill (lines 254-259) uses curl without `--max-time` for REST API fallback calls. This is a pre-existing pattern not changed in v6.7.2, and these are direct API calls (not webhooks) where the user expects synchronous completion. Noted but not scored.

## 3. MCP Body Formatting Reference (PASS)

### 3a. Core Contract Internal Reference

`core/tracker-subtask-creator.md` line 194: `Follow core/mcp-body-formatting.md when constructing multi-line MCP tool parameters.`

This reference is correctly placed at the end of the Issue Description Template section, ensuring multi-line descriptions sent to MCP tools use real newlines, not escaped `\n`.

### 3b. Caller-Side References

All 3 refactored skills maintain a dual reference (both the core contract delegation AND an explicit mcp-body-formatting reminder):

| Skill | Step | Reference Text |
|-------|------|---------------|
| fix-ticket | 4b-tracker (L209) | `Follow core/tracker-subtask-creator.md. Follow core/mcp-body-formatting.md when constructing multi-line MCP tool parameters.` |
| fix-bugs | 3b-tracker (L226) | Same |
| implement-feature | 5a (L268) | Same |

The dual reference (core contract + explicit formatting reminder) is a belt-and-suspenders approach. Since the core contract itself references mcp-body-formatting, the caller reference is redundant but harmless and adds clarity.

**Verdict:** PASS — mcp-body-formatting references preserved in both core contract and all callers.

### 3c. Block Handler mcp-body-formatting Reference

`core/block-handler.md` line 38: `Follow core/mcp-body-formatting.md when constructing the comment string.`

Present and correct. Block comments posted to tracker use proper multi-line formatting.

## 4. Block Handler Inline Removal (PASS)

The implement-feature skill's step X now delegates to `core/block-handler.md` (line 463-464):
```
Follow `core/block-handler.md` for the block protocol.
```

The core block-handler.md includes:
1. Conditional rollback (only for fixer/reviewer/test-engineer/e2e-test-engineer/smoke-check — not for read-only agents)
2. Status verification after state transition
3. Block comment via mcp-body-formatting
4. Webhook with proper curl flags
5. State.json update

This is a security improvement — the previous inline block handler in implement-feature reportedly had issues (unconditional rollback even for read-only agents, missing status-verification, old curl format, no mcp-body-formatting reference). Delegating to the core contract fixes all of these.

**Verdict:** PASS — security improvement over previous inline implementation.

## 5. Additional Security Observations

### 5a. git add -A in Tracker Subtask Creator (OBSERVATION — pre-existing)

Line 153-154: `git add -A` followed by a commit. This is a pre-existing pattern (existed in the inline versions before extraction). It adds all files, which could theoretically commit sensitive files. However, this commit only happens after YAML file updates (tracker issue ID linkage), and the working directory should be clean except for the YAML changes. The risk is the same as before extraction.

### 5b. Idempotency Protection (PASS)

Lines 39-54: The dual-store idempotency check (YAML-first, state.json fallback) prevents duplicate tracker issue creation on pipeline resume. This is a positive security/reliability feature preserved from the inline implementations.

### 5c. No Secrets in Committed Files (PASS)

The tracker-subtask-creator only writes `tracker_issue_id` values (public issue IDs) to YAML and state.json. No tokens, credentials, or sensitive data are persisted.

## Score

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Prompt injection | 0.95 | All sanitizer references preserved. Core contract is write-only so no new injection surface. Minor: GitHub/Gitea checklist reads parent_body but does not pass to agents. |
| Webhook security | 1.0 | All curl calls use --max-time 5 --retry 0. Format aligned to core contracts. |
| MCP body formatting | 1.0 | References preserved in core contract AND all 3 callers. |
| External input sanitizer | 1.0 | All 6 skills that process tracker data maintain their references. |
| Block handler | 1.0 | Delegation to core contract is a security improvement. |

**Overall Security Score: 0.95**

The 0.05 deduction is for the theoretical (but negligible) observation that the GitHub/Gitea checklist in tracker-subtask-creator reads `parent_body` from the tracker without sanitizer wrapping. Since this content is only used for string concatenation (appending a checklist) and never passed to an agent as prompt input, the actual risk is negligible. No action required.
