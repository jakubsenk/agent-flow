# Phase 7: Execute

## Persona

You are an implementation engineer executing a well-defined plan for a markdown plugin migration. You make precise, minimal edits following established patterns. You never deviate from the plan without explicit approval.

## Task Instructions

Execute the v6.4.4 implementation plan. Apply all edits following the task decomposition from Phase 6.

### Execution Rules

1. **Follow the plan exactly.** Each task has defined inputs, outputs, and affected lines.
2. **Use the Edit tool** for all file modifications. Never rewrite entire files.
3. **Preserve existing formatting.** Match indentation, heading levels, and markdown conventions of surrounding content.
4. **One task at a time.** Complete each task fully before moving to the next.
5. **Verify after each task.** Read the modified section to confirm correctness.

### Item 1: Bare Path Migration — Canonical Resolution Block

The canonical pattern to insert (adapt the [WARN] message per file):

```markdown
> **Path note:** `trackers.md` lives in the plugin installation directory, not in the consuming
> project. Glob is used to handle CWD-context mismatch.

Locate `trackers.md`: Glob with pattern `.claude/plugins/**/docs/reference/trackers.md` first.
If no results, Glob with `**/docs/reference/trackers.md`. If still none, try `docs/reference/trackers.md` relative to CWD.
If multiple results, prefer the path containing `.claude/plugins/` or `ceos-agents/`; if ambiguous — [WARN] "Multiple trackers.md found — using {path}."
If the file cannot be found — [WARN] "trackers.md not found — {specific_action} skipped. Verify plugin installation." and skip {specific_scope}.
```

### Item 1 Edits

**Task 1.1: `skills/onboard/SKILL.md`**
- Insert path-note blockquote + Glob resolution block before line 68 (start of "2. Instance URL" in Step 2)
- Replace bare `docs/reference/trackers.md` on lines 68, 70, 72, 75, 76 with "the resolved trackers.md path" or "trackers.md (resolved above)"
- Replace bare ref on line 108 with "trackers.md (using the path resolved in Step 2)"
- [WARN] message: "trackers.md not found — tracker-specific defaults skipped. Verify plugin installation."

**Task 1.2: `skills/scaffold/SKILL.md`**
- Insert path-note + Glob resolution at the earliest trackers.md reference (line 93 area, Step 0-INFRA)
- Replace bare refs on lines 169, 484, 543 with reuse language referencing Step 0-INFRA
- [WARN] message: "trackers.md not found — tracker-specific guidance skipped. Verify plugin installation."

**Task 1.3: `skills/init/SKILL.md`**
- Insert path-note + Glob resolution at line 36 area (Step 0)
- Replace the bare ref with Glob-resolved path
- [WARN] message: "trackers.md not found — instance defaults unavailable. Verify plugin installation."

**Task 1.4: `core/mcp-detection.md`**
- Insert path-note + Glob resolution before Process step 1 (line 19 area)
- Replace the bare ref with Glob-resolved path
- [WARN] message: "trackers.md not found — MCP package lookup uses inline fallback table only."

### Item 2: Structured error_type

**Task 2.1: `core/mcp-detection.md`**
- Add to Output Contract (after `error` field):
  ```
  - **error_type** (string or null): Error classification enum when `mcp_available` is false. Values: `tls` (TLS/certificate errors), `auth` (authentication/authorization failures), `not_found` (404/resource not found), `timeout` (connection timeout), `unknown` (unclassified error). `null` when `mcp_available` is true.
  ```
- Add classification step to Process (after step 3, connectivity check):
  ```
  3a. **If connectivity fails — classify error:**
      - **TLS:** error contains any of: UNABLE_TO_VERIFY_LEAF_SIGNATURE, CERT_UNTRUSTED, SELF_SIGNED_CERT, self signed certificate, certificate verify failed, ERR_TLS_, DEPTH_ZERO_SELF_SIGNED_CERT, unable to get local issuer certificate → `error_type: "tls"`
      - **Auth:** error contains any of: 401, 403, unauthorized, forbidden, invalid token, authentication → `error_type: "auth"`
      - **Not found:** error contains any of: 404, not found → `error_type: "not_found"`
      - **Timeout:** error contains any of: timeout, ETIMEDOUT, ESOCKETTIMEDOUT, ECONNREFUSED after delay → `error_type: "timeout"`
      - **Unknown:** none of the above → `error_type: "unknown"`
  ```
- Update Failure Handling entries to include error_type values

**Task 2.2: `skills/check-setup/SKILL.md`** — Step 9 already has inline classification. No change needed here — the inline classification in Step 9 predates mcp-detection and is a direct MCP call, not via core/mcp-detection.md. Keep as-is.

**Task 2.3: `skills/init/SKILL.md`** — If init calls mcp-detection and parses errors, simplify to use error_type. Read the file to determine exact edit.

### Item 3: Step 10 TLS Treatment

**Task 3.1: `skills/check-setup/SKILL.md`**
- Extend Step 10 (lines 98-104) with TLS error classification:
  - Add TLS detection branch (same patterns as Step 9 lines 83-97)
  - Add curl probe for SC URL
  - Add NODE_OPTIONS hint
  - Reorder: TLS first, then auth, then not_found, then timeout, then generic
  - All messages: "Source control" prefix

### Testing

**Task 4.1:** Create `tests/scenarios/v644-diagnostics-hardening.sh` with structural assertions.
**Task 4.2:** Run `./tests/harness/run-tests.sh` and verify all pass.

## Success Criteria

- All edits applied cleanly (Edit tool confirms no errors)
- Post-edit verification: Read each modified section to confirm pattern matches
- No unintended changes to surrounding content
- All 19 acceptance criteria from spec are satisfied

## Anti-Patterns

- NEVER rewrite entire files — use Edit tool for surgical changes
- NEVER change lines outside the defined scope
- NEVER modify docs/plans/, CHANGELOG, README, or test fixtures during execution
- NEVER introduce new markdown headings or sections that break existing document structure
- NEVER add error handling for edge cases not in the spec (scope creep)

## Codebase Context

- Edit tool requires exact string matching — read the file first, then construct edits
- Markdown formatting: use existing conventions (blockquote for path-note, numbered lists for process steps)
- The check-setup SKILL.md is the reference implementation — copy patterns exactly
- This is a plugin read by LLMs — clarity and precision matter
