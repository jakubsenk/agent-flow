# Phase 4: Design — v6.8.1 PATCH

Architecture, file-by-file modification plan, and cross-item dependencies. Each section cites the source-file anchors confirmed by Phase 2 research (`.forge/phase-2-research-answers/final.md`).

## Meta
- PATCH release — zero Automation Config contract changes, zero new skills, zero new agents
- Pure-markdown plugin — no build system, no runtime compilation
- 19 files modified + 2 files created = 21 file operations
- Estimated diff: ~256 lines added/changed
- Test count: 140 baseline → 142 target (two new scenarios)

---

## Cross-Item Dependencies and Commit Ordering

The content commit contains all Item 1-6 changes AND the CHANGELOG entry. Within that commit, the following ordering constraints apply:

| Ordering | Reason |
|---------|--------|
| Item 5 loop-contract patch (`core/fixer-reviewer-loop.md` Step 10) MUST land before or in the same commit as `tests/scenarios/v681-fixer-reviewer-crash-recovery.sh` | The scenario greps for text that does not yet exist on HEAD; committing the scenario first would break the harness on the intermediate commit. |
| Item 6 harness fix (`tests/harness/run-tests.sh`) MUST land before or in the same commit as `tests/scenarios/v681-harness-exit-propagation.sh` | Same reason — the meta-test greps the patched harness for the absence of `((FAIL++))` etc. |
| Item 2 regex gate MAY land independently of Item 3 | Item 3's narrative cross-references the gate but does not grep for it; independence preserved for review granularity. |
| CHANGELOG entry for `[6.8.1]` MUST exist in `CHANGELOG.md` before `/ceos-agents:version-bump` runs | Enforced by version-bump Step 6 CHANGELOG guard. |
| Version-bump MUST be a separate commit following the content commit | Enforced by version-bump Step 7 uncommitted-changes guard and user memory preference. |

All Item 1-6 changes land in a single `content + CHANGELOG` commit. Version-bump produces a second commit plus tag.

---

## Item 1 — Config-Template Autopilot Rows

### Files modified (8)
All under `examples/configs/`:

| File | Current state | Action |
|------|--------------|--------|
| `github-nextjs.md` | Has `<!-- ... -->` block (lines 50-134) containing other optional sections, no `### Autopilot` | Insert `### Autopilot (optional)` block inside the existing comment block, after `### Metrics (optional)`, before the closing `-->` |
| `github-python-fastapi.md` | 47 lines, no comment block, no optional sections | Append full divider + comment block with only Autopilot inside |
| `github-dotnet.md` | 50 lines, no comment block | Same as above |
| `gitea-spring-boot.md` | 47 lines, no comment block | Same as above |
| `jira-react.md` | 46 lines, no comment block | Same as above |
| `youtrack-python.md` | 49 lines, no comment block | Same as above |
| `redmine-rails.md` | 48 lines, no comment block | Same as above |
| `redmine-oracle-plsql.md` | 181 lines, has active optional sections (lines 58-111) and separate comment block (lines 113-181) | Insert `### Autopilot` as active section (no `(optional)` suffix) after `### Decomposition` and before the `> **Uncomment...` divider at line 113 |

### Verbatim block for the 7 commented-style templates

For `github-nextjs.md` (insert inside existing block before closing `-->`):
```markdown
### Autopilot (optional)
| Key | Value |
|-----|-------|
| Max issues per run | 1 |
| Lock timeout | 120 |
| Log file | .ceos-agents/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | false |
```

For the 6 bare templates (append at end of file, producing a new divider + comment block):
```markdown

> **Uncomment and customize optional sections as needed.**

<!--
### Autopilot (optional)
| Key | Value |
|-----|-------|
| Max issues per run | 1 |
| Lock timeout | 120 |
| Log file | .ceos-agents/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | false |
-->
```

### Verbatim block for `redmine-oracle-plsql.md` (active-section style)
Insert after `### Decomposition` section at line ~111, before the comment-block divider at line 113:
```markdown
### Autopilot
| Key | Value |
|-----|-------|
| Max issues per run | 1 |
| Lock timeout | 120 |
| Log file | .ceos-agents/autopilot.log |
| Bug limit | 0 |
| Feature limit | 0 |
| On error | skip |
| Dry run | false |

```

### Design decisions
- **`Dry run | false`** matches `docs/reference/config.md:26-41` and `CLAUDE.md` Autopilot Config Keys as the canonical default. `docs/guides/autopilot.md:40-51` uses `true` as a safe-first-run recommendation but that is guide narrative, not template default.
- **Per-template placement choice** — for the 7 commented-style templates, the block is opt-in (hidden behind `<!-- -->`) so the templates remain copy-pasteable starter kits with Autopilot disabled by default. For `redmine-oracle-plsql.md`, the active-section placement signals Autopilot relevance to the high-compliance audience (SK kompenzace Oracle PL/SQL onboarding).
- **Key ordering** — exactly matches `CLAUDE.md` Autopilot Config Keys table top-to-bottom: Max issues per run, Lock timeout, Log file, Bug limit, Feature limit, On error, Dry run.

### Trade-offs considered
- Making the block active (uncommented) across all 8 templates — rejected because templates default to zero optional behavior; activating Autopilot would subtly change what copy-paste produces.
- Adding `(optional)` suffix in `redmine-oracle-plsql.md` active section — rejected because other active optional sections in that file do not use the suffix (consistency).

---

## Item 2 — issue_id Regex Gate

### Files modified (4 skills)

| File | Insertion anchor (current) | Step label |
|------|---------------------------|-----------|
| `skills/fix-ticket/SKILL.md` | Before line ~87 `Create .ceos-agents/{ISSUE-ID}/` | New Step 0 sub-step immediately after MCP pre-flight |
| `skills/fix-bugs/SKILL.md` | Before line ~90 `For each issue fetched in step 1: create .ceos-agents/{ISSUE-ID}/` | New step inside per-issue loop, positioned before directory creation |
| `skills/implement-feature/SKILL.md` | Before line ~89 `Create .ceos-agents/{ISSUE-ID}/` | New Step 0 sub-step after MCP pre-flight |
| `skills/resume-ticket/SKILL.md` | Before line ~17 `If .ceos-agents/{ISSUE-ID}/state.json exists` | New Step 0 |

### Verbatim gate block (identical in all 4 skills, adapted to local step numbering)

**Placement note:** For `fix-ticket`, `implement-feature`, `resume-ticket` (single-issue entry points), the gate is placed in Step 0 immediately AFTER `ISSUE_ID` is read from the skill argument and BEFORE any path construction. For `fix-bugs` (batch entry point), `ISSUE_ID` is only bound INSIDE the per-issue loop body (loop iterator from the Step 1 tracker batch query); the gate is therefore placed at the TOP of the per-issue loop body, immediately after `ISSUE_ID` is assigned and BEFORE the directory-creation line near line 90. The gate is NOT placed at outer Step 0 of `fix-bugs` (where `ISSUE_ID` does not yet exist).

```markdown
**issue_id validation (path-traversal defense):** Before constructing any filesystem path from `{ISSUE-ID}`, validate the raw issue ID against the allowlist:

```bash
if [[ ! "${ISSUE_ID}" =~ ^[A-Za-z0-9#_-]+$ ]]; then
  echo "[BLOCK] Invalid issue_id: ${ISSUE_ID}" >&2
  exit 1
fi
```

The bash built-in `[[ =~ ]]` operator matches the ENTIRE string (anchored to start and end of the whole value, not per-line). This is critical: a `grep -qE` pipeline on multi-line input would match ANY matching line and therefore be bypassable by a payload like `$'../../etc/passwd\nPROJ-42'`. The `[[ =~ ]]` form rejects any value containing an embedded newline or carriage return.

If validation fails: print to stderr and exit 1 (no state.json written, no lock acquired). Valid examples: `PROJ-42`, `#123`, `AUTH-1`, `42`. Reject examples: `../../etc/passwd`, `foo bar`, `proj$42`, `PROJ/42`, `$'good\nbad'` (multi-line).
```

### Design decisions
- **Gate placed in each affected skill, not in a shared helper** — there is no shared skill-entry contract to modify. `core/mcp-preflight.md` is the only shared Step-0 helper and it has a different responsibility (MCP server readiness). Extracting a new `core/issue-id-validator.md` helper for 4 callers is premature; inlining the ~8-line gate keeps the fix auditable as a PATCH.
- **Regex `^[A-Za-z0-9#_-]+$`** — accepts all legitimate tracker ID formats documented in `state/schema.md:287` (YouTrack `PROJ-45`, GitHub/Gitea `#123`, Redmine integers, Jira/Linear `KEY-NNN`) AND rejects all shell metacharacters and path separators. The `#` inclusion is mandatory for GitHub/Gitea; safe on Linux/macOS/NTFS filesystems and shell-comment-safe when interpolated inside quoted strings.
- **fix-bugs loop semantics** — gate failure skips the one offending issue (consistent with `On error: skip` batch semantics); other issues in the batch continue. In `fix-ticket`, `implement-feature`, `resume-ticket`, gate failure terminates the whole skill invocation (single-issue entry points).
- **Exit 1 with stderr log** — no BLOCK comment on tracker because a malformed issue_id may indicate an attack or tracker misconfiguration; posting a comment would potentially require unsafe interpolation itself.

### Trade-offs considered
- Widening the regex to include `.` or `/` for project-key formats observed in some Linear instances — rejected; Phase 2 research confirmed all documented examples match the narrow set.
- Adding the gate to `skills/autopilot/SKILL.md` — rejected; autopilot does NOT construct `.ceos-agents/{ISSUE-ID}/` paths. It delegates to fix-ticket/fix-bugs, which perform the gate themselves. The autopilot log path (`.ceos-agents/autopilot.log`) is operator-controlled (config `Log file`), not tracker-derived.
- Adding the gate to `core/state-manager.md` — rejected; state-manager is a contract document, not a runtime entry. The gate belongs at the caller boundary.

---

## Item 3 — JSON-Encode Payload Interpolation Docs

### Files modified (3)

| File | Location | Action |
|------|---------|--------|
| `core/post-publish-hook.md` | Section 4 (after line ~102) | Insert new "Field value safety" paragraph after the "Advisory failure" sentence and before the Section 4 close |
| `core/block-handler.md` | Step 5 (lines ~40-44) | Full rewrite: replace inline `-d '...'` with heredoc `--data-binary @-` pattern; add `--proto "=http,https"`; construct payload via `jq -n --arg` (POSIX-safe, no Bash 4.2+ substring trim) |
| `docs/guides/autopilot.md` | After line 286 | Append new "Payload field safety" paragraph |

### Verbatim insertions

**Fix 1 — `core/post-publish-hook.md` Section 4 (insert after line ~102):**
```markdown
**Field value safety:** The heredoc prevents shell-word-splitting and glob expansion, but a raw
`"${var}"` substitution inside a heredoc JSON literal does NOT JSON-encode field values. Any field
whose value originates from external input (e.g., `issue_id` read from the tracker, `pr_url` from
the SCM) MUST be safe for direct JSON string embedding — free of `"`, `\`, and control characters.
The `issue_id` regex gate (see issue_id validation in skills' Step 0, R-ITEM-2.1 through R-ITEM-2.6)
ensures `issue_id` and `run_id` contain only `[A-Za-z0-9#_-]` characters and are therefore safe to
interpolate directly. The `pr_url` field in `pipeline-completed` payloads SHOULD be percent-encoded
by the SCM tool before being written to state.json; implementers MUST NOT construct `pr_url` from
raw user-controlled input. For agent-generated free-form prose fields (e.g., `reason` in
`ceos-agents-block` events), use `jq -n --arg` structural payload construction (see
`core/block-handler.md` Step 5 for the canonical pattern) rather than interpolating variables into
a quoted JSON literal.
```

**Fix 2 — `core/block-handler.md` Step 5 (full replacement of existing block):**
```markdown
5. **Fire webhook** if config → Notifications → Webhook URL exists and `issue-blocked` is in On events:
   ```bash
   # Build the entire JSON payload structurally via jq — each variable is passed as --arg so jq
   # performs all string escaping. No inline interpolation into a quoted JSON literal.
   payload=$(jq -n \
     --arg event "issue-blocked" \
     --arg issue_id "${issue_id}" \
     --arg agent "${agent_name}" \
     --arg reason "${reason}" \
     --arg timestamp "${ISO8601}" \
     '{event:$event, issue_id:$issue_id, agent:$agent, reason:$reason, timestamp:$timestamp}')

   curl --proto "=http,https" --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
     --data-binary @- "${Webhook_URL}" <<EOF
   ${payload}
   EOF
   ```
   The `reason` field is agent-generated free-form prose (max 2 sentences) and MAY contain `"`, `\`,
   or newlines that would structurally break the JSON payload. Passing `reason` to `jq -n --arg`
   delegates all string escaping to `jq` — the resulting JSON string literal is guaranteed safe for
   embedding, with no shell-level substring trimming required (no Bash-specific `${var:1:-1}` or
   equivalent POSIX construct needed). The `--proto "=http,https"` flag restricts transport to
   HTTP/HTTPS only (blocks `file://`, `gopher://`, etc.). Advisory failure: log
   `[WARN] Webhook delivery failed: {error}` and continue pipeline. Never block on webhook delivery.

   **Why heredoc + `${payload}` is safe:** after `jq -n` encoding, literal newlines in any input
   become the two-character escape `\n` inside the JSON string. The heredoc body is therefore a
   single logical line of JSON. The heredoc terminator `EOF` can never appear as a standalone line
   inside the body.
```

**Fix 3 — `docs/guides/autopilot.md` (append after line 286):**
```markdown
**Payload field safety:** Field values embedded into webhook payloads must be safe for JSON
string encoding. The `issue_id` and `run_id` fields are constrained by an allowlist
(`[A-Za-z0-9#_-]`) at skill entry and are guaranteed free of JSON-hostile characters. The `pr_url`
field in `pipeline-completed` events must be a valid percent-encoded URL (as returned by the SCM
MCP tool) — do not construct it from raw user input. If you write a custom post-publish hook that
embeds agent output (e.g., `reason` text from a block event) into a webhook payload, construct the
payload with `jq -n --arg <field> "${value}" '{<field>:$<field>, ...}'` so that `jq` performs all
string escaping for you. Do NOT interpolate variables directly into a single-quoted JSON literal
or a heredoc that contains raw `"${var}"` substitutions for free-form text fields.
```

### Design decisions
- **Section 4 note is additive, not a replacement** — `core/post-publish-hook.md` Section 3 already has a shell-quoting/heredoc note and `--proto` justification; the new Section 4 note covers the orthogonal concern of JSON structural safety.
- **block-handler Step 5 full rewrite** — the existing `-d '...'` with inline `{variable}` substitution has three defects (no heredoc, no `--proto`, no JSON escaping for the free-form `reason` field); repairing them piecemeal is less readable than a single replacement block.
- **`jq -n --arg` structural payload generation** (chosen) — passes every dynamic field to `jq -n` as a `--arg <name> "${value}"` pair and constructs the JSON object with an object literal (`{event:$event, ...}`). This delegates ALL JSON string escaping to `jq` and requires NO Bash-specific parameter expansion (no `${var:1:-1}` substring trim). The approach is POSIX-safe — it works identically in `/bin/bash`, `/bin/sh`, BusyBox `ash`, and `dash`. Alternative (not chosen): `jq -Rs .` with `${encoded:1:-1}` substring trim — rejected in round-2 revision because `${var:1:-1}` requires Bash 4.2+ and does not work in POSIX `sh` / BusyBox / older macOS Bash 3.2. Alternative (not chosen): inline `-d '{"event":"issue-blocked","reason":"${reason}",...}'` — rejected as the original defect.

### Trade-offs considered
- Extracting webhook payload generation to a shared helper (`core/webhook-payload-builder.md`) — rejected; only three call sites, two-sentence prose is lower-cost than a new core file for a PATCH.
- Adding runtime validation (regex-checking `reason` at send time) — rejected; `jq -n --arg` is the correct layer and no test infrastructure validates runtime behavior in this pure-markdown repo.
- Using `jq -Rs .` followed by POSIX `sed 's/^"//;s/"$//'` to strip quotes — rejected; introduces an additional subprocess per field and is less readable than `jq -n --arg`, which scales naturally to N fields.

---

## Item 4 — Lock-Timeout Text Alignment

### Files modified (1)

| File | Line | Action |
|------|------|--------|
| `skills/autopilot/SKILL.md` | 368 | Replace the sentence fragment `<120min old` within the troubleshooting bullet |

### Current line 368 (verbatim)
```
- **`[autopilot][ERROR] Another Autopilot run in progress`** → check `.ceos-agents/autopilot.lock/owner.json` for the owning PID and host. If the owning process is gone but the lock is <120min old, wait for stale timeout or manually `rm -rf .ceos-agents/autopilot.lock/` (only after verifying no live process).
```

### Replacement line 368 (verbatim)
```
- **`[autopilot][ERROR] Another Autopilot run in progress`** → check `.ceos-agents/autopilot.lock/owner.json` for the owning PID and host. If the owning process is gone but the lock is less than the effective stale threshold (the configured `Lock timeout` value plus a 5-minute NFS/CIFS clock-skew buffer; default: 125 min on primary path, 121 min on BusyBox fallback), wait for stale auto-recovery or manually `rm -rf .ceos-agents/autopilot.lock/` (only after verifying no live process).
```

### Design decisions
- **One prose line, zero numeric changes** — Phase 2 audit confirmed 120/125/121 are all intentional values (config default, primary path with +5 clock-skew buffer, BusyBox path with +1 resolution buffer). Editing the bash or BusyBox sections would be a functional change.
- **`docs/guides/autopilot.md:350` unchanged** — already says `120 minutes (plus a 5-minute NFS/CIFS skew buffer)`, which is correct and serves as the verbatim model for the SKILL.md fix.

### Trade-offs considered
- Rewriting the bash `LOCK_TIMEOUT_WITH_BUFFER=$((LOCK_TIMEOUT + 5))` to make the relationship literal — rejected; the +5 buffer is runtime logic, not doc, and the roadmap item is explicitly a text alignment.

---

## Item 5 — Fixer-Reviewer Crash-Recovery Regression Test

### Files modified (1) + created (1)

| File | Action |
|------|--------|
| `core/fixer-reviewer-loop.md` | Step 10 (line 28): rewrite to add `tokens_used += iteration_tokens_used` accumulation language AND crash-recovery semantics sentence |
| `tests/scenarios/v681-fixer-reviewer-crash-recovery.sh` | NEW — regression scenario with 4 grep assertions |

### Current Step 10 (verbatim, line 28 of `core/fixer-reviewer-loop.md`)
```
10. After each iteration, update state.json: increment `fixer_reviewer.iterations`, set `fixer_reviewer.last_verdict`, update `fixer_reviewer.ac_fulfillment` from reviewer AC Fulfillment section, set `fixer_reviewer.status` to `"in_progress"`. Follow atomic write protocol from `core/state-manager.md`.
```

### Replacement Step 10 (verbatim)
```
10. After each iteration, update state.json atomically (see `core/state-manager.md` atomic write protocol): increment `fixer_reviewer.iterations`, set `fixer_reviewer.last_verdict`, update `fixer_reviewer.ac_fulfillment` from reviewer AC Fulfillment section, set `fixer_reviewer.status` to `"in_progress"`, and accumulate usage fields: `fixer_reviewer.tokens_used += iteration_tokens_used`, `fixer_reviewer.duration_ms += iteration_duration_ms`, `fixer_reviewer.tool_uses += iteration_tool_uses`. These cumulative writes ensure that if the pipeline crashes mid-loop, the state.json reflects the token cost of all completed iterations and can be used for cost reporting on resume.
```

### New file — `tests/scenarios/v681-fixer-reviewer-crash-recovery.sh`

Filename prefix precedent: `v644-diagnostics-hardening.sh` → `v681-fixer-reviewer-crash-recovery.sh` (PATCH-version convention, no `ac-` prefix).

```bash
#!/usr/bin/env bash
# Test: v6.8.1 Fixer-reviewer crash-recovery — cumulative tokens_used written per iteration
# Validates: core/fixer-reviewer-loop.md Step 10 documents tokens_used accumulation per-iteration
#            and that crash-mid-loop preserves completed-iteration cost data
# Traces: COST-R5 (cumulative), state-manager atomic write protocol
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

LOOP_CONTRACT="$REPO_ROOT/core/fixer-reviewer-loop.md"
STATE_MANAGER="$REPO_ROOT/core/state-manager.md"
SCHEMA="$REPO_ROOT/state/schema.md"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Guard: required files exist
for f in "$LOOP_CONTRACT" "$STATE_MANAGER" "$SCHEMA"; do
  if [ ! -f "$f" ]; then
    echo "FAIL: required file not found: $f"
    exit 1
  fi
done

# --- Assertion 1: core/fixer-reviewer-loop.md Step 10 documents tokens_used accumulation ---
if ! grep -qE 'tokens_used.*iteration|iteration.*tokens_used' "$LOOP_CONTRACT"; then
  fail "core/fixer-reviewer-loop.md Step 10 does not document per-iteration tokens_used accumulation (+=)"
fi

# --- Assertion 2: core/fixer-reviewer-loop.md mentions crash-recovery semantics ---
if ! grep -qiE 'crash|partial.*failure.*preserv|preserv.*partial' "$LOOP_CONTRACT"; then
  fail "core/fixer-reviewer-loop.md does not document crash-recovery semantics for cumulative tokens_used"
fi

# --- Assertion 3: state/schema.md already documents cumulative semantics ---
if ! grep -qiE 'cumulative|cumulat' "$SCHEMA"; then
  fail "state/schema.md does not document cumulative accumulation for fixer_reviewer (must be present)"
fi

# --- Assertion 4: core/state-manager.md already documents cumulative += write ---
if ! grep -qE 'tokens_used.*running total|cumulatively across iterations' "$STATE_MANAGER"; then
  fail "core/state-manager.md does not document cumulative running-total write for fixer_reviewer"
fi

# --- Negative: no per-iteration breakdown array in loop contract or schema ---
for file in "$LOOP_CONTRACT" "$SCHEMA"; do
  if grep -qE 'iteration_breakdown|per_iteration|iterations_detail' "$file"; then
    fail "$(basename "$file") contains per-iteration breakdown array language (must be absent)"
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: v6.8.1 fixer-reviewer crash-recovery — cumulative tokens_used documented per-iteration with crash-recovery semantics"
exit "$FAIL"
```

### Design decisions
- **Loop-contract patch must land in the SAME commit as the scenario** — otherwise the intermediate commit fails the harness. Implementers must stage `core/fixer-reviewer-loop.md` and `tests/scenarios/v681-fixer-reviewer-crash-recovery.sh` together.
- **Scenario is a static doc-check, not a runtime simulation** — this plugin has no runtime test harness for pipeline state; all scenarios are grep-based markdown validators. The crash-recovery "test" validates the documented contract that guarantees crash-recovery.
- **4 assertions + 1 negative** — assertions 3 and 4 verify that existing cumulative-semantics prose in `state/schema.md:344` and `core/state-manager.md:138-148` remain present (regression guard); they would catch accidental rollback of v6.8.0 contract in future edits.

### Trade-offs considered
- Using `ac-v681-` prefix instead of `v681-` — rejected; `ac-` is reserved for minor-version AC tests (e.g., `ac-v68-cost-fixer-reviewer-cumulative.sh`), and `v644-diagnostics-hardening.sh` is the PATCH precedent.
- Making the scenario execute a simulated crash — rejected; no test harness for runtime state, and the cost (setting up fake state.json + crash injection) vastly exceeds PATCH scope.

---

## Item 6 — Test Harness Exit-Code Propagation

### Files modified (1) + created (1)

| File | Action |
|------|--------|
| `tests/harness/run-tests.sh` | Lines 42, 48, 52: replace `((N++))` with `N=$((N+1))` for PASS, SKIP, FAIL counters |
| `tests/scenarios/v681-harness-exit-propagation.sh` | NEW — meta-test with grep assertions + functional single-scenario check |

### Current `tests/harness/run-tests.sh` counter lines (verbatim)
```bash
# Line 42 (PASS branch):
((PASS++))

# Line 48 (SKIP branch):
((SKIP++))

# Line 52 (FAIL branch):
((FAIL++))
```

### Replacement counter lines (verbatim)
```bash
# Line 42 (PASS branch):
PASS=$((PASS + 1))

# Line 48 (SKIP branch):
SKIP=$((SKIP + 1))

# Line 52 (FAIL branch):
FAIL=$((FAIL + 1))
```

### New file — `tests/scenarios/v681-harness-exit-propagation.sh`

```bash
#!/usr/bin/env bash
# Test: v6.8.1 — Harness exit-code propagation
# Validates: run-tests.sh uses $((N + 1)) form for PASS/FAIL/SKIP increments
#            (safe under bash -e wrappers; ((N++)) returns exit 1 when N=0)
# Functional: single-scenario mode exits nonzero on failure
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
HARNESS="$REPO_ROOT/tests/harness/run-tests.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Guard
if [ ! -f "$HARNESS" ]; then
  echo "FAIL: run-tests.sh not found at $HARNESS"
  exit 1
fi

# --- Assertion 1: FAIL increment uses safe $((FAIL + 1)) form (positive AND negative) ---
if grep -qE '\(\(FAIL\+\+\)\)' "$HARNESS"; then
  fail "run-tests.sh still uses ((FAIL++)) — replace with FAIL=\$((FAIL + 1)) to avoid exit-code 1 leak under bash -e wrappers"
fi
if ! grep -qE 'FAIL=\$\(\(FAIL \+ 1\)\)' "$HARNESS"; then
  fail "run-tests.sh does not contain FAIL=\$((FAIL + 1)) — safe counter form missing"
fi

# --- Assertion 2: PASS increment uses safe form (positive AND negative) ---
if grep -qE '\(\(PASS\+\+\)\)' "$HARNESS"; then
  fail "run-tests.sh still uses ((PASS++)) — replace with PASS=\$((PASS + 1)) to avoid exit-code 1 leak under bash -e wrappers"
fi
if ! grep -qE 'PASS=\$\(\(PASS \+ 1\)\)' "$HARNESS"; then
  fail "run-tests.sh does not contain PASS=\$((PASS + 1)) — safe counter form missing"
fi

# --- Assertion 3: SKIP increment uses safe form (positive AND negative) ---
if grep -qE '\(\(SKIP\+\+\)\)' "$HARNESS"; then
  fail "run-tests.sh still uses ((SKIP++)) — replace with SKIP=\$((SKIP + 1)) to avoid exit-code 1 leak under bash -e wrappers"
fi
if ! grep -qE 'SKIP=\$\(\(SKIP \+ 1\)\)' "$HARNESS"; then
  fail "run-tests.sh does not contain SKIP=\$((SKIP + 1)) — safe counter form missing"
fi

# --- Assertion 4: Functional smoke — single-scenario mode exits nonzero on failure ---
# Note: single-scenario mode was already correct pre-fix; this is a belt-and-suspenders regression
# guard. The PRIMARY validation of the ((N++)) -> N=$((N+1)) fix is Assertions 1-3 (static grep)
# combined with AC-ITEM-6.2 (full-run mode functional check).
TMPNAME="v681-meta-test-always-fail-$$"
TMPSCEN="$REPO_ROOT/tests/scenarios/$TMPNAME.sh"
printf '#!/usr/bin/env bash\nexit 1\n' > "$TMPSCEN"
chmod +x "$TMPSCEN"

bash "$HARNESS" "$TMPNAME" > /dev/null 2>&1
harness_exit=$?
rm -f "$TMPSCEN"

if [ "$harness_exit" -eq 0 ]; then
  fail "run-tests.sh single-scenario mode exited 0 for a failing scenario (exit-code propagation broken)"
else
  echo "OK: single-scenario mode correctly exits nonzero ($harness_exit) on failure"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: v6.8.1 harness exit-code propagation — safe increments and nonzero exit on failure"
exit "$FAIL"
```

### Design decisions
- **Filename `v681-harness-exit-propagation.sh`** — aligned with the PATCH-prefix precedent `v644-diagnostics-hardening.sh`. NOT `ac-v681-` (that prefix is reserved for minor-version AC tests; the Phase 2 research proposal that used `ac-v681-` was explicitly rejected in Phase 4). All references in `requirements.md`, `design.md`, `formal-criteria.md`, and the scenario file itself MUST use `v681-harness-exit-propagation.sh` with no `ac-` prefix.
- **`$((N+1))` form eliminates all three counter risks simultaneously** — the arithmetic-expression-returning-0 trap is not specific to FAIL; PASS and SKIP have the same latent issue when first reaching 0.
- **Assertion 4 writes a temp scenario to live `tests/scenarios/`** — unconventional but safe: `$$` PID suffix prevents collision, harness accepts the single-scenario argument, cleanup is unconditional. An alternative of stubbing SCENARIOS_DIR would require patching the harness to accept an override.
- **Harness lines 66-68 (`if [ $FAIL -gt 0 ]; then exit 1; fi`)** unchanged — already correct for R-ITEM-6.2/6.3.

### Validation chain — how the meta-test confirms the fix is effective

The fix's ACTUAL value is in full-run mode under a `bash -e` wrapper. Single-scenario mode was already correct pre-fix (see devil's-advocate review #6). The validation chain is therefore:

1. **Static grep (Assertions 1-3 + AC-ITEM-6.1a):** confirm the three fix-affected counter lines use `N=$((N+1))` form. Explicit new Assertion — the meta-test MUST grep for the literal pattern `PASS=\$\(\(PASS \+ 1\)\)`, `SKIP=\$\(\(SKIP \+ 1\)\)`, `FAIL=\$\(\(FAIL \+ 1\)\)` being PRESENT (AC-ITEM-6.1a) AND `\(\(PASS\+\+\)\)` etc. being ABSENT (AC-ITEM-6.1b / Assertions 1-3 of the meta-test). Together these lock in the fix.
2. **Full-run functional check (AC-ITEM-6.2):** verifies that when a failing scenario is present, `bash run-tests.sh` exits non-zero. Assumes the pre-change baseline is all-passing (enforced by R-RELEASE-3). Under a clean baseline, the only FAIL comes from the injected temp scenario, and rc ≠ 0 proves propagation works.
3. **Full-run pass check (AC-ITEM-6.3):** verifies that with no failing scenarios, exit 0.
4. **Single-scenario smoke (Assertion 4 of the meta-test):** runs the harness in single-scenario mode against an injected failing scenario and asserts non-zero exit. This is a belt-and-suspenders check that also validates the single-scenario exit path is not accidentally broken by the counter refactor.

Steps 1-3 together are the OPERATIVE validation that the `((N++))` → `N=$((N+1))` fix is effective. Step 4 is complementary (documented as single-scenario-mode-only by the review gap analysis).

### Assumptions and known scope limits

- **Clean baseline required for AC-ITEM-6.2:** AC-ITEM-6.2 cannot distinguish "harness exits 1 because of the injected temp scenario" from "harness exits 1 because some pre-existing scenario is broken." R-RELEASE-3 (full harness passes before content commit) makes the baseline clean; therefore any non-zero exit after injection is attributable to the temp. If R-RELEASE-3 fails, AC-ITEM-6.2 is not meaningful until the baseline is repaired.
- **Single-scenario mode (harness lines 25-31) was already correct** pre-fix — the fix does not affect that code path. Assertion 4 of the meta-test is therefore a smoke test, not a primary correctness check.

### Trade-offs considered
- Making Assertion 4 optional (static-only meta-test) — rejected; keeping it preserves regression coverage against accidental single-scenario-mode refactors, at low additional cost.

---

## Release — CHANGELOG + Version-Bump

### Files modified (1) + skill invocation (1)

| File | Action |
|------|--------|
| `CHANGELOG.md` | Prepend new `## [6.8.1] — 2026-04-18` block with `### Fixed` + `### Internal` subsections (matching v6.8.0 precedent at `CHANGELOG.md:44-46`) |
| `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` | Updated by `/ceos-agents:version-bump patch` in a separate commit |

### Verbatim CHANGELOG entry (top of file, above existing `## [6.8.0]`)

```markdown
## [6.8.1] — 2026-04-18

**PATCH** — Config template completeness, lock-timeout prose alignment, fixer-reviewer crash-recovery contract, test harness robustness, payload encoding documentation, issue_id path-traversal defense.

### Fixed
- **`examples/configs/*`** — `### Autopilot` section (7 keys) added to all 8 config templates. Closes Known Issue from v6.8.0. (v6.8.0 Known Issues cited `examples/config-templates/*`; corrected path is `examples/configs/*`.)
- **`skills/autopilot/SKILL.md:368`** — Troubleshooting prose corrected: `<120min old` replaced with effective stale threshold reference (`Lock timeout` + 5 min NFS/CIFS buffer = 125 min primary path; 121 min BusyBox fallback). Consistent with `docs/guides/autopilot.md:350`.
- **`skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/resume-ticket/SKILL.md`** — issue_id regex gate (`^[A-Za-z0-9#_-]+$`) added before all `.ceos-agents/{ISSUE-ID}/` filesystem path constructions. Prevents path-traversal via malformed tracker issue IDs.
- **`core/post-publish-hook.md` Section 4, `core/block-handler.md` Step 5, `docs/guides/autopilot.md`** — JSON-encoding safety note added for heredoc payloads. `core/block-handler.md` Step 5 converted from inline `-d '...'` to `--data-binary @-` heredoc with `--proto "=http,https"` and `jq -n --arg` structural payload construction for the free-form `reason` field (POSIX-safe; no Bash 4.2+ `${var:1:-1}` required).
- **`core/fixer-reviewer-loop.md` Step 10** — Token accumulation (`tokens_used += iteration_tokens_used` etc.) added to per-iteration state.json write instruction. Crash-recovery semantics documented: cumulative writes preserve completed-iteration cost on mid-loop pipeline crash.
- **`tests/harness/run-tests.sh`** — `((PASS++))`, `((SKIP++))`, `((FAIL++))` replaced with `PASS=$((PASS + 1))` etc. — eliminates spurious exit-code 1 from arithmetic expressions under `bash -e` CI wrappers.

### Internal
- **`tests/scenarios/v681-fixer-reviewer-crash-recovery.sh`** — regression scenario asserting cumulative-tokens prose and crash-recovery language in `core/fixer-reviewer-loop.md`.
- **`tests/scenarios/v681-harness-exit-propagation.sh`** — meta-test asserting safe counter form in `tests/harness/run-tests.sh` and functional non-zero exit on failure.
```

### Design decisions
- **`### Fixed` is the primary subsection** — this is a polish release; no new features.
- **`### Internal` subsection for the two new test scenarios** — the v6.8.0 CHANGELOG precedent at `CHANGELOG.md:44-46` places test-infrastructure artifacts under `### Internal` (not `### Added`); v6.8.1 matches that convention. `### Added` is reserved for user-visible additions (new skills, new config keys, new commands); v6.8.1 adds none.
- **Path correction noted explicitly** — the v6.8.0 Known Issues entry at `CHANGELOG.md:42` erroneously cited `examples/config-templates/*`. The v6.8.1 entry clarifies the actual path.
- **Commit sequence enforced by version-bump guards** — Step 6 of `skills/version-bump/SKILL.md` requires `## [6.8.1]` heading to exist in CHANGELOG before bump runs; Step 7 requires a clean working tree. Therefore content + CHANGELOG commit must precede version-bump invocation.

---

## File Inventory Summary

### Modified (19 files)
1. `examples/configs/github-nextjs.md`
2. `examples/configs/github-python-fastapi.md`
3. `examples/configs/github-dotnet.md`
4. `examples/configs/gitea-spring-boot.md`
5. `examples/configs/jira-react.md`
6. `examples/configs/youtrack-python.md`
7. `examples/configs/redmine-rails.md`
8. `examples/configs/redmine-oracle-plsql.md`
9. `skills/fix-ticket/SKILL.md`
10. `skills/fix-bugs/SKILL.md`
11. `skills/implement-feature/SKILL.md`
12. `skills/resume-ticket/SKILL.md`
13. `core/post-publish-hook.md`
14. `core/block-handler.md`
15. `docs/guides/autopilot.md`
16. `skills/autopilot/SKILL.md`
17. `core/fixer-reviewer-loop.md`
18. `tests/harness/run-tests.sh`
19. `CHANGELOG.md`

### Created (2 files)
1. `tests/scenarios/v681-fixer-reviewer-crash-recovery.sh`
2. `tests/scenarios/v681-harness-exit-propagation.sh`

### Updated by version-bump skill (separate commit)
1. `.claude-plugin/plugin.json`
2. `.claude-plugin/marketplace.json`
3. Git tag `v6.8.1`
