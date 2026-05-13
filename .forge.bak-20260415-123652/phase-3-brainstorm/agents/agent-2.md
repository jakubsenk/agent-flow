# Agent 2 — The Defensive Pipeline Engineer

## Position Statement

The Phase 2 research answers are precise and well-researched. The edit strings are correct. The file inventory is complete. My job is not to second-guess the research but to stress-test the implementation plan against failure modes that only surface months later, when someone adds the 8th MCP call site without knowing the contract exists, or when a Redmine instance returns a 500 on the "On start set" transition and the pipeline silently eats it.

My philosophy: **every contract that is not enforced by a test will eventually be violated.** The Phase 2 plan creates two new contracts (status-verification wiring and MCP body formatting). Both are "reference this file" patterns. Reference patterns are inherently fragile -- they depend on the author of the next call site knowing about the contract and remembering to add the reference. I want to close that gap with detection tests, explicit failure handling, and defensive dry-run guards.

I endorse the Phase 2 plan in its entirety. My additions are purely additive: tests, failure handling, and guard clauses that make the implementation robust against future drift.

---

## Item 1: Status Verification Wiring (4 sites)

### What Phase 2 Gets Right

The four insertion points are correctly identified. The reference phrase ("After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded") is consistent with the existing three wired sites. The edit strings are exact and non-overlapping.

### Failure Mode: Forgotten Reference on New Call Sites

**The problem.** Today there are 7 status-set call sites (3 already wired, 4 being wired now). In v6.7.0, someone adds an 8th site in a new skill. They write the MCP call but forget the verification reference. The contract exists but is silently bypassed. No test catches this.

**My recommendation: a new test `tests/scenarios/xref-status-verification.sh`.**

This test would:

1. Scan all `skills/*/SKILL.md`, `core/*.md`, and `agents/*.md` files for status-set indicators (patterns like `Set the state`, `Transition the .* issue to`, `Set issue state to`, `status-set MCP call`).
2. For each file that matches, verify it also contains `core/status-verification.md`.
3. PASS if every file with a status-set indicator also references the verification contract. FAIL otherwise.

**Trade-off analysis:**

| Approach | Pros | Cons |
|----------|------|------|
| No test (Phase 2 as-is) | Zero overhead, no false positives | Silent drift guaranteed over time |
| Hardcoded file list test | Simple, no false positives | Must be manually updated for each new call site -- same "forgetting" problem |
| Pattern-scanning test (recommended) | Self-healing -- catches new call sites automatically | Risk of false positives if prose mentions "status" without a real MCP call |

I favor the pattern-scanning approach. False positives are manageable: the pattern can be tuned to require at least two of the indicators in the same file. A file that mentions "Set the state" AND "MCP" but does NOT reference `core/status-verification.md` is almost certainly a gap.

**Proposed test structure:**

```bash
#!/usr/bin/env bash
# Test: All status-set MCP call sites reference core/status-verification.md (T-NEW)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CONTRACT="core/status-verification.md"
FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# Check that the contract file itself exists
if [ ! -f "$REPO_ROOT/$CONTRACT" ]; then
  fail "$CONTRACT does not exist"
  exit 1
fi

# Scan for files that perform status-set MCP calls
# Heuristic: file contains a status-setting phrase AND mentions MCP or tracker
STATUS_PATTERNS='Set the state|Set issue state|Transition the .* issue to|status-set MCP'
MCP_INDICATORS='MCP|mcp__|issue tracker'

for f in $(find "$REPO_ROOT/skills" "$REPO_ROOT/core" "$REPO_ROOT/agents" -name '*.md' 2>/dev/null); do
  rel="${f#$REPO_ROOT/}"
  # Skip the contract file itself
  [ "$rel" = "$CONTRACT" ] && continue
  
  has_status=$(grep -cE "$STATUS_PATTERNS" "$f" 2>/dev/null || true)
  has_mcp=$(grep -ciE "$MCP_INDICATORS" "$f" 2>/dev/null || true)
  
  if [ "$has_status" -gt 0 ] && [ "$has_mcp" -gt 0 ]; then
    if ! grep -q "core/status-verification.md" "$f"; then
      fail "$rel performs status-set MCP call(s) but does not reference $CONTRACT"
    fi
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: All status-set MCP call sites reference $CONTRACT (T-NEW)"
exit "$FAIL"
```

**Scope decision:** This test is v6.6.0 scope. It is a direct consequence of the wiring work -- the contract is only useful if it is enforced. Adding 4 reference lines without a guard is half-measures.

### Failure Mode: Verification Itself Fails (Tracker Unavailable)

This is already handled well by `core/status-verification.md` (all failure modes produce WARN, never block). No change needed. But I want to call out that the scaffold Step 8b site has a subtlety: items 3a/3b use verification, but item 3d is the existing WARN-on-failure handler. The research correctly identifies that verification failure flows into 3d's WARN path. This is correct behavior -- double-WARN (one from verification, one from 3d) is better than silent failure.

### My Verdict on Item 1

Accept Phase 2 edits as-is. Add `tests/scenarios/xref-status-verification.sh` as a guard against future drift. Total: 4 edits + 1 new test file.

---

## Item 2: MCP Body Formatting Contract

### What Phase 2 Gets Right

The contract file structure is solid: Purpose, Applies To, Process, Output Contract, Constraints, Failure Mode. All 7 replacements are exact and tested against the current file contents. The test update plan for `mcp-newline-handling.sh` is correct.

### Should the Contract Have a "Detection" Section?

**Yes.** The current contract explains WHAT to do (use real newlines) and WHY (MCP passes values as-is). It does not explain HOW TO DETECT a violation. In a pure-markdown plugin where there is no linter, detection is human-only: someone reads a PR body in the tracker and sees literal `\n` characters.

I propose adding a `## Detection` section to `core/mcp-body-formatting.md`:

```markdown
## Detection

Violations are not caught at MCP call time. They manifest as:
- Literal `\n` characters visible in issue tracker comments, PR descriptions, or issue bodies
- Single-line rendering of content that should span multiple lines

If detected post-publication:
1. Edit the affected tracker item manually to fix rendering
2. Search the skill/agent file for the MCP call that produced the output
3. Verify it references this contract; if not, add the reference and update the test
```

**Trade-off:** This adds 8 lines to the contract. The benefit is that a developer who encounters the symptom has a clear remediation path. The cost is minimal -- 8 lines of prose in a file that already exists. I favor inclusion.

### Should the Test Catch New MCP Call Sites That Lack the Reference?

**Yes, absolutely.** The Phase 2 test update (Check A: contract exists, Check B: 5 files reference it) is good but has the same hardcoded-list problem as Item 1. If someone adds a 6th file with MCP multi-line calls, the test still passes.

I propose extending Check B to be dynamic, similar to my Item 1 proposal:

**Extended test approach:**

```bash
# Check B (hardcoded): known vulnerable files reference the contract
REFERENCE_MARKER="core/mcp-body-formatting.md"
KNOWN_FILES=(
  "agents/publisher.md"
  "core/block-handler.md"
  "skills/fix-ticket/SKILL.md"
  "skills/implement-feature/SKILL.md"
  "skills/fix-bugs/SKILL.md"
)
for f in "${KNOWN_FILES[@]}"; do
  if ! grep -q "$REFERENCE_MARKER" "$REPO_ROOT/$f"; then
    fail "$f missing reference to $REFERENCE_MARKER"
  fi
done

# Check C (dynamic): scan for files that construct MCP multi-line content
# without referencing the contract
MULTILINE_PATTERNS='multi-line string|line breaks between|line separator|\\\\n.*MCP|MCP.*\\\\n'
for f in $(find "$REPO_ROOT/skills" "$REPO_ROOT/core" "$REPO_ROOT/agents" -name '*.md' 2>/dev/null); do
  rel="${f#$REPO_ROOT/}"
  [ "$rel" = "core/mcp-body-formatting.md" ] && continue
  
  has_multiline=$(grep -ciE "$MULTILINE_PATTERNS" "$f" 2>/dev/null || true)
  if [ "$has_multiline" -gt 0 ]; then
    if ! grep -q "$REFERENCE_MARKER" "$f"; then
      fail "$rel discusses MCP multi-line content but does not reference $REFERENCE_MARKER"
    fi
  fi
done
```

**Trade-off analysis:**

| Approach | Pros | Cons |
|----------|------|------|
| Hardcoded list only (Phase 2) | No false positives, simple | Silent drift on new files |
| Hardcoded + dynamic scan (recommended) | Catches new files automatically | Slightly more complex, possible false positives |
| Dynamic scan only | Maximum coverage | Loses the "known files" assertion (weaker) |

I favor hardcoded + dynamic: the hardcoded list is the regression guard (these specific files MUST reference the contract), and the dynamic scan is the drift guard (new files SHOULD reference it too).

### Full 6-Section Contract Structure

The Phase 2 contract has 6 sections: Purpose, Applies To, Process, Output Contract, Constraints, Failure Mode. With my proposed Detection section, it becomes 7. This matches the pattern of `core/status-verification.md` which has: Purpose, Input Contract, Process, Output Contract, Constraints, Failure Handling. The parallel structure is:

| status-verification.md | mcp-body-formatting.md |
|------------------------|------------------------|
| Purpose | Purpose |
| Input Contract | Applies To |
| Process | Process |
| Output Contract | Output Contract |
| Constraints | Constraints |
| Failure Handling | Failure Mode |
| -- | Detection (new) |

The "Detection" section is unique to mcp-body-formatting because its failure mode is visual/post-hoc, unlike status-verification where failure is immediate and logged. This asymmetry is justified.

### My Verdict on Item 2

Accept Phase 2 contract and 7 replacements as-is. Add a `## Detection` section (8 lines) to the contract. Extend the test with a dynamic scan (Check C) alongside the hardcoded list (Check B). Total: 1 new file (with detection section), 7 edits, 1 test edit (with extended logic).

---

## Item 3: fix-bugs "On Start Set" Step

### What Phase 2 Gets Right

Step 1a placement (between Fetch and Triage), wording (matching fix-ticket), dry-run annotation, worktree range update (2-8 to 1a-8), and the decision to NOT update step number references elsewhere. All correct.

### Failure Mode: "On Start Set" State Does Not Exist in Tracker Config

**The scenario.** A user's Automation Config has `Issue Tracker -> Type: redmine` and `State transitions -> In Progress: status_id:2, Blocked: status_id:5, Done: status_id:3`. But they do not have an `On start set` key because their workflow does not require it. Step 1a reads "Set the state per Automation Config (Issue Tracker -> On start set)" -- but the key is absent.

**Current fix-ticket behavior:** fix-ticket Step 1 says "Set the state per Automation Config (Issue Tracker -> On start set)." It does NOT have an explicit guard for missing key. This means the LLM must infer that "no key = no action." This works in practice because sonnet/opus interpret "Set X per config Y" as "if Y exists, set X; otherwise skip" -- but it is implicit.

**My recommendation: add an explicit guard clause.**

The step text should read:

```
### 1a. Set issue tracker

If Issue Tracker -> On start set is not configured -> skip this step silently.

Set the state per Automation Config (Issue Tracker -> On start set). Read Type for the correct MCP server.

After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

*In dry-run: skip this step.*
```

**Trade-off analysis:**

| Approach | Pros | Cons |
|----------|------|------|
| Implicit skip (Phase 2) | Shorter text, matches fix-ticket | Depends on LLM inference; no explicit contract |
| Explicit guard (recommended) | Clear failure path; no ambiguity for any model | One extra line; diverges from fix-ticket Step 1 |
| Explicit guard + backport to fix-ticket | Full consistency | Extra edit in fix-ticket (scope creep) |

I favor the explicit guard in step 1a WITHOUT backporting to fix-ticket. Reason: fix-ticket has been shipping since v6.5.2 without the guard and works fine. Adding it to the new step 1a costs one line and prevents a class of errors where a less capable model (or a future haiku-class model used for cost optimization) misinterprets the instruction. The inconsistency between fix-ticket Step 1 and fix-bugs Step 1a is acceptable -- fix-ticket can be aligned later as a separate PATCH.

### Failure Mode: MCP Call Fails

**The scenario.** The tracker is temporarily unavailable. The "On start set" MCP call returns an error (timeout, 500, auth failure).

**What happens with the Phase 2 plan:** Step 1a makes the MCP call, then follows `core/status-verification.md`. But verification only runs AFTER a successful MCP call returns. If the call itself throws an error (not a silent wrong-state, but an actual MCP tool error), verification never fires.

**Current pipeline behavior for MCP failures:** The MCP pre-flight check (Step 0) verifies that the tracker MCP server is accessible. If it passes, subsequent MCP failures are transient. The existing pattern across all skills is: if an MCP call fails mid-pipeline, the LLM sees the error and either retries or blocks. There is no explicit "on MCP call failure" handler for status-set calls -- only for critical path operations (create issue, create PR).

**My recommendation: add a failure note to step 1a.**

```
If the MCP call fails (error response, timeout): log `[WARN] Could not set On start set state for {issue_id}: {error}. Continuing.` Do not block.
```

**Rationale:** Setting "On start set" is optimistic housekeeping, not a critical path operation. The bug will still be triaged and fixed even if the state transition fails. Blocking the entire pipeline because the tracker had a 2-second hiccup on a non-critical state change is disproportionate. This matches the philosophy of `core/status-verification.md` (always WARN, never block).

**Trade-off:**

| Approach | Pros | Cons |
|----------|------|------|
| No failure note (Phase 2) | Shorter; LLM decides | Inconsistent with status-verification philosophy; risk of spurious blocks |
| WARN + continue (recommended) | Explicit; matches verification philosophy | One more sentence |
| WARN + continue + retry once | More resilient | Adds complexity; retry logic is not worth it for a non-critical call |

### Failure Mode: Dry-Run Guard Bypass

**The scenario.** The dry-run section says "steps 1-3, no side effects: no issue tracker state changes." Step 1a carries `*In dry-run: skip this step.*` This is correct. But what if a developer restructures the dry-run prose and changes the range? The step annotation is the true guard, and it is already there.

**My recommendation: no change.** The dual guard (prose range "1-3" + per-step annotation) is sufficient. The per-step annotation is authoritative. If the prose range changes, the annotation still prevents execution. This is defense in depth that already exists.

### Worktree Range: A Subtle Correctness Concern

Phase 2 updates the worktree parallel range from "steps 2-8" to "steps 1a-8." This is correct for functionality but has a subtle implication: step 1a (set issue state) now runs INSIDE each parallel Task. This means for a batch of 3 bugs processed in parallel, 3 "On start set" MCP calls fire simultaneously. This is fine -- MCP calls to different issues are independent. But it is worth noting that the parallel execution means all 3 bugs transition state at the same time, which could produce a burst of tracker activity. For Redmine or Jira instances with rate limiting, this could cause transient failures.

**My recommendation: no change to the plan, but add this as a known limitation note.** The status-verification contract already handles transient MCP failures with WARN. If rate limiting causes a failure, the WARN fires and the pipeline continues. This is acceptable.

### My Verdict on Item 3

Accept Phase 2 step 1a text and worktree range update with two modifications:

1. Add explicit guard: "If Issue Tracker -> On start set is not configured -> skip this step silently."
2. Add failure note: "If the MCP call fails (error response, timeout): log `[WARN] Could not set On start set state for {issue_id}: {error}. Continuing.` Do not block."

Revised step 1a text:

```
### 1a. Set issue tracker

If Issue Tracker -> On start set is not configured -> skip this step silently.

Set the state per Automation Config (Issue Tracker -> On start set). Read Type for the correct MCP server.

After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded. If the MCP call itself fails (error response, timeout): log `[WARN] Could not set On start set state for {issue_id}: {error}. Continuing.` Do not block.

*In dry-run: skip this step.*
```

---

## Cross-Cutting Concerns

### Test Budget

My proposals add:
- 1 new test file: `tests/scenarios/xref-status-verification.sh` (Item 1)
- 1 extended test edit: `tests/scenarios/mcp-newline-handling.sh` (Item 2, dynamic scan addition)

Phase 2 already accounts for 1 test edit (mcp-newline-handling.sh). My extension adds a Check C to the same file. The new test file is incremental -- it does not touch any existing test.

### CLAUDE.md Impact

Phase 2 requires one CLAUDE.md edit: core count 12 -> 13. My proposals do not change this. The new test file does not affect CLAUDE.md (test count is not tracked in CLAUDE.md).

### Version Classification

All changes remain PATCH (v6.6.0). No new required config keys. No new agents. No breaking changes. The new test and contract additions are internal quality improvements.

---

## Summary: Defensive Additions Over Phase 2

| Addition | Item | Type | Lines | Justification |
|----------|------|------|-------|---------------|
| `tests/scenarios/xref-status-verification.sh` | 1 | New test | ~35 | Prevents forgotten verification references on new status-set call sites |
| `## Detection` section in mcp-body-formatting.md | 2 | Contract addition | ~8 | Gives developers a remediation path for post-hoc failure detection |
| Dynamic scan (Check C) in mcp-newline-handling.sh | 2 | Test extension | ~15 | Catches new MCP multi-line files that lack the contract reference |
| Explicit guard clause in step 1a | 3 | Step text modification | +1 line | Handles missing "On start set" config key without LLM inference |
| Failure note in step 1a | 3 | Step text modification | +1 sentence | Matches status-verification WARN philosophy for non-critical MCP failures |

**Total incremental cost:** ~60 lines across 3 files. **Risk reduction:** prevents 3 classes of silent drift (forgotten status verification, forgotten MCP formatting reference, ambiguous "On start set" handling).
