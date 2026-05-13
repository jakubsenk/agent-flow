# Phase 4 Review 3 — Devil's Advocate (Tier 3 Only)

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": true,
    "no_regressions": true,
    "lint_clean": true,
    "pass": true,
    "note": "DA scope: T3 only"
  },
  "tier_2": {
    "fail_to_pass": null,
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true,
    "note": "DA scope: T3 only"
  },
  "tier_3": {
    "correctness": 3,
    "completeness": 3,
    "security": 4,
    "maintainability": 3,
    "robustness": 2,
    "weighted_aggregate": 3.10,
    "pass": false
  },
  "overall_verdict": "FAIL",
  "confidence": 0.87,
  "findings": [
    {
      "id": "f-a1c2d3",
      "severity": "CRITICAL",
      "criterion": "correctness",
      "location": "design.md §3.1 Step 0c / REQ-PUBLISH-AUTO-DETECT EARS",
      "description": "Greedy regex consumes description into issue_id: for branch fix/PROJ-123-fix-crash, residue after stripping prefix is PROJ-123-fix-crash, and regex ^[A-Za-z0-9#._-]+ (with - in charset) matches the ENTIRE residue. issue_id becomes PROJ-123-fix-crash, not PROJ-123. Tracker lookup returns 404 for every standard branch. The full-publish mode is unreachable for any branch following the documented fix/{issue-id}-{description} naming convention.",
      "recommendation": "Spec must define delimiter extraction: parse the character immediately after {issue-id} in the Branch naming template (e.g., - from fix/{issue-id}-{description}), then truncate the regex match at the first occurrence of that delimiter in the residue. Alternatively, use a greedy-up-to-next-separator approach: match ^[A-Za-z0-9#.#]+(?=-[^A-Z0-9]|$) or similar. Add an AC that asserts issue_id extraction on input fix/PROJ-123-fix-crash returns PROJ-123, not PROJ-123-fix-crash."
    },
    {
      "id": "f-b2d4e5",
      "severity": "CRITICAL",
      "criterion": "correctness",
      "location": "formal-criteria.md AC-RENAME-STATUS-5 / AC-DEL-CREATE-PR-7 / AC-RENAME-STATUS-4 / AC-RENAME-INIT-4 / AC-DEL-CREATE-PR-2",
      "description": "Five ACs conflict with the Did you mean? prose inserted by design.md §5.3. AC-RENAME-STATUS-5 checks ! grep -qE '`ceos-agents:status`' skills/workflow-router/SKILL.md — but the Did you mean prose uses exactly that backtick-wrapped form. AC-DEL-CREATE-PR-7 checks ! grep -q '`ceos-agents:create-pr`' skills/workflow-router/SKILL.md — same conflict. AC-RENAME-STATUS-4, AC-RENAME-INIT-4, AC-DEL-CREATE-PR-2 grep the whole repo for deprecated identifiers without excluding skills/workflow-router/SKILL.md. If Phase 7 inserts the Did you mean prose as written (design §5.3 sample), all five ACs fail even with a correct implementation. These are false-positive ACs.",
      "recommendation": "The spec already identifies the resolution: formal-criteria.md must be updated NOW, in Phase 4, to add --exclude=skills/workflow-router/SKILL.md to AC-RENAME-STATUS-4, AC-RENAME-INIT-4, and AC-DEL-CREATE-PR-2; and to adjust AC-RENAME-STATUS-5 and AC-DEL-CREATE-PR-7 to use a tighter scope or marker-prefixed form. Leaving this to Phase 7 discretion with only an implementation note means Phase 8 ACs will be inconsistent with the implementation. The resolution must be mandated in formal-criteria.md, not deferred."
    },
    {
      "id": "f-c3e5f6",
      "severity": "HIGH",
      "criterion": "correctness",
      "location": "design.md §3.1 Step 0b-c / REQ-PUBLISH-AUTO-DETECT",
      "description": "Missing Branch naming not in config is unhandled. If user has no Source Control -> Branch naming key in Automation Config, design.md Step 0b reads nothing. Step 0c then tries to identify a prefix before {issue-id} from a null/empty template. Outcome is unspecified: a null prefix means every branch starts with an empty prefix, residue equals the entire branch name, regex matches it all, and issue_id becomes e.g. main or chore. Tracker lookup for main returns 404 (not not_found in the true sense — main is not an issue ID). The behavior should be: missing Branch naming → issue_id = null → mode = pr-only-no-id. The spec does not say this.",
      "recommendation": "Add to REQ-PUBLISH-AUTO-DETECT SC-1 or design §3.1 Step 0b: If Branch naming key is absent from Automation Config, treat as null and set issue_id = null immediately, proceeding to Step 3 in pr-only-no-id mode. Add an AC testing this path."
    },
    {
      "id": "f-d4f6g7",
      "severity": "HIGH",
      "criterion": "robustness",
      "location": "formal-criteria.md AC-TEST-INVENTORY-3 / design.md Section 7",
      "description": "AC-TEST-INVENTORY-3 verifies only 4 of the 6 required edits to v6.9.0-doc-count-drift.sh. It checks: '18 optional config sections in total' present, 'eq 28' present, 'eq 18' present. It does NOT check: (a) that line 55-58 was flipped from rejecting 18 optional to rejecting 19 optional, (b) that line 89 PASS message was updated. If Phase 7 forgets the line 55-58 negative-flip, the scenario itself (when run against updated CLAUDE.md) would catch it at runtime — but AC-TEST-INVENTORY-3 as a static file-content check would still pass, creating a Phase 8 false-pass on the AC while the scenario runtime fails.",
      "recommendation": "Add two more conditions to AC-TEST-INVENTORY-3: grep -qF '19 optional config sections in total' tests/scenarios/v6.9.0-doc-count-drift.sh (verifies old-stale string is now in the negative branch) and verify the PASS message at line 89 includes 28 and 18. The current AC is incomplete for the DISAGREEMENT D resolution."
    },
    {
      "id": "f-e5g7h8",
      "severity": "HIGH",
      "criterion": "correctness",
      "location": "requirements.md REQ-CHANGELOG-MIGRATION EARS / design.md §4.1 CHANGELOG template",
      "description": "CHANGELOG migration bullet 4 contains a semantic error. The spec states: Branch matches Branch naming AND issue is 404 → PR-only with [WARN]. But the branch-naming match is a PREFIX match (did the branch start with fix/?) combined with a valid issue-ID-shaped residue. It is NOT a full-branch-name match. The CHANGELOG bullet 4 says Branch matches Branch naming AND issue is 404 — which implies the Branch naming template is checked first as a pattern match. This is ambiguous: a user reading the CHANGELOG would not know that fix/PROJ-123-fix-crash is classified as matching (prefix fix/ matches), and might think fix/PROJ-123 is the required form. The lost-agency disclosure also uses chore/refactor-foo as the workaround example — but under the greedy-regex bug (Finding #1), chore/refactor-foo would produce issue_id = refactor-foo → 404, not pr-only-no-id as intended.",
      "recommendation": "Fix after resolving Finding #1 (greedy regex). Then update CHANGELOG bullet 4 to be precise about what matching means: the branch prefix matches the static prefix before {issue-id} in the Branch naming template, and the residue after stripping the prefix matches the issue-ID character class."
    },
    {
      "id": "f-f6h8i9",
      "severity": "MEDIUM",
      "criterion": "robustness",
      "location": "design.md §8.1 Invariant 2 comment / AC-INVARIANTS-2",
      "description": "design.md §8.1 Phase 8 verification comment states Expected: CONTRIBUTING.md: 2. Actual live count is 1 (only one occurrence of filip.sabacky@ceosdata.com in CONTRIBUTING.md). The AC-INVARIANTS-2 correctly uses grep -q (any occurrence) so it would PASS. But the Phase 8 human-readable verification output from the for-loop command would show CONTRIBUTING.md: 1 against the annotated expected 2, causing a Phase 8 reviewer to flag this as a failure. This is a false positive in the Phase 8 narrative verification.",
      "recommendation": "Update design.md §8.1 Invariant 2 comment to Expected: SECURITY.md: 1, CODE_OF_CONDUCT.md: 1, CONTRIBUTING.md: 1. The comment documents the wrong expected count."
    },
    {
      "id": "f-g7i9j0",
      "severity": "MEDIUM",
      "criterion": "correctness",
      "location": "requirements.md REQ-PUBLISH-AUTO-DETECT SC-7 / design.md §3.2 404 WARN tier",
      "description": "SC-7 in requirements.md mandates a single [ceos-agents][WARN] line. design.md §3.2 shows the 404 WARN tier as a 3-line block (line 1: [ceos-agents][WARN] Branch ... contains issue ID pattern ..., line 2: but no matching ticket was found in {tracker_type}., line 3: Creating PR without tracker update.). The prose below says Single line, WARN level but the sample IS multi-line. Phase 7 will implement from the sample, not the prose, and produce 3 echo calls. No AC tests the line count, so this quietly ships a multi-line WARN where SC-7 mandates a single line. This matters for log parsers and log-aggregation tools that tokenize on newline.",
      "recommendation": "Reconcile design.md §3.2 to show the 404 WARN tier as a literal single line (with line-wrapping only for display purposes in the spec). Or update SC-7 to allow up to 3 lines. Add a comment in the design sample: NOTE — this is one logical line; emit as single echo."
    },
    {
      "id": "f-h8j0k1",
      "severity": "MEDIUM",
      "criterion": "completeness",
      "location": "formal-criteria.md / REQ-PUBLISH-AUTO-DETECT",
      "description": "No AC tests the actual extraction behavior of the branch-parse algorithm. AC-PUBLISH-AUTO-DETECT-3 checks only that the regex string is present in the file (grep -q pattern). It does not verify the extraction produces the correct result for a representative input like fix/PROJ-123-fix-crash. This is a false-negative gap: Phase 7 could implement the exact spec text (greedy regex), Phase 8 ACs would all pass, and the implementation would silently 404 on every real branch. The gap is especially dangerous because the regex IS in the v6.8.1 codebase (at fix-ticket/SKILL.md:91) in a different context (validation, not extraction), lending false confidence.",
      "recommendation": "Add an AC that grep-checks for a design-mandated example extraction in the SKILL.md prose, e.g., assert that the file contains a worked example: branch fix/PROJ-123-fix-crash -> residue PROJ-123-fix-crash -> issue_id = PROJ-123 (with the delimiter logic applied). Alternatively, add a test scenario that validates the extraction pseudocode against example inputs."
    },
    {
      "id": "f-i9k1l2",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "formal-criteria.md / REQ-PUBLISH-AUTO-DETECT",
      "description": "No AC covers the zero-commits early-stop path (design §3.1 Step 3a). After Steps 0-2 run (possibly contacting the tracker), the skill discovers there are zero commits and stops. There is no AC asserting this INFO-level stop message is present in the skill. This is a false-negative gap for the edge case where the skill contacts the tracker, then refuses to continue — a potentially confusing user experience that is untested.",
      "recommendation": "Add AC: grep -E 'No changes to publish|zero commits|no commits above' skills/publish/SKILL.md. This ensures the early-stop path is documented in the rewritten skill."
    },
    {
      "id": "f-j0l2m3",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "design.md §3.1 Step 7 / REQ-PUBLISH-AUTO-DETECT SC-9",
      "description": "FAIL mode webhook behavior is unspecified. design.md Step 7 says pr-created event fires in all non-FAIL modes. Neither Step 7 nor any other step specifies what webhook event (if any) fires when /publish FAILs. Phase 3 brainstorm (Dimension 5) mentioned pipeline-completed with outcome: failed, but this did not make it into the final spec. An LLM-agent implementing the skill may or may not emit a webhook on FAIL depending on its interpretation of silence.",
      "recommendation": "Add to design §3.1 or SC-9: On FAIL, no pr-created event fires. Whether pipeline-completed with outcome: failed fires is deferred to v7.0.1+ (consistent with Phase 3 D5 tracker-down-webhook deferral). Add a one-line AC: ! grep -E 'pr-created.*FAIL|FAIL.*pr-created' skills/publish/SKILL.md or affirmative prose in the skill."
    },
    {
      "id": "f-k1m3n4",
      "severity": "MINOR",
      "criterion": "maintainability",
      "location": "design.md §4.1 CHANGELOG template",
      "description": "CHANGELOG template uses ## [7.0.0] — Unreleased but the project convention (observed from CHANGELOG.md current head) is ## [6.10.0] — 2026-04-24 — Quality Sprint + Security Consistency with an actual date and theme subtitle. The design-specified Unreleased token deviates from the keepachangelog.com convention the project actually uses. After /version-bump the date gets inserted, but the theme subtitle will be missing unless /version-bump handles it. This is cosmetic but creates a CHANGELOG entry that looks different from all prior entries.",
      "recommendation": "Change the template to ## [7.0.0] — Unreleased — Cleanup + Naming + Auto-detect Publish, matching the theme convention of prior entries. The Phase 7 author should know to include the theme."
    },
    {
      "id": "f-l2n4o5",
      "severity": "MINOR",
      "criterion": "correctness",
      "location": "requirements.md REQ-DEL-CREATE-PR EARS / design.md §1.1",
      "description": "EARS clause says rewritten to reference /ceos-agents:publish if a Related skills or alternative-skill mention, but design scope for docs/reference/skills.md:363 says REMOVE /create-pr reference from Related skills in /publish section — not REWRITE to /publish. These are internally inconsistent: the EARS says rewrite-to-publish but the explicit scope says remove. For this specific location (Related skills in /publish itself) removing is obviously correct (cannot be related to itself), but the inconsistency means Phase 7 must interpret which instruction wins. Other Related skills mentions of /create-pr in skills.md (if any exist beyond line 363) might be handled differently than intended.",
      "recommendation": "Clarify EARS wording: or rewritten to reference /ceos-agents:publish (if a Related skills or alternative-skill mention IN ANOTHER SKILL). Add a note that the /publish section's own Related skills entry for /create-pr is simply removed (not redirected to /publish)."
    }
  ]
}
```

---

## Adversarial Findings — Detailed Analysis

### Finding 1 — CRITICAL: Greedy regex makes full-publish mode unreachable

**Scenario:** User has `Branch naming: fix/{issue-id}-{description}` (the documented example). They run `/publish` from branch `fix/PROJ-123-fix-crash-on-login`.

**Execution trace under the spec's algorithm:**
1. `branch_name = "fix/PROJ-123-fix-crash-on-login"`
2. Template `"fix/{issue-id}-{description}"` → prefix `"fix/"`
3. Residue = `"PROJ-123-fix-crash-on-login"`
4. Apply `^[A-Za-z0-9#._-]+` to residue
5. The character class `[A-Za-z0-9#._-]` INCLUDES the hyphen `-`. The regex is greedy.
6. Result: the regex matches `"PROJ-123-fix-crash-on-login"` in its entirety (all characters are in the class)
7. `issue_id = "PROJ-123-fix-crash-on-login"` — not `"PROJ-123"`
8. Tracker lookup for `"PROJ-123-fix-crash-on-login"` → `not_found` (404)
9. Mode = `pr-only-404` — tracker never updated

**Why no AC catches this:** AC-PUBLISH-AUTO-DETECT-3 only checks that the regex string appears in the skill file. It does not verify extraction behavior. No test scenario provides a real branch name and asserts the extracted issue_id value.

**Severity:** CRITICAL — the feature's primary mode (full-publish) is unreachable for any branch following the standard naming convention. The only working path is a branch with NO description segment, e.g., `fix/PROJ-123` (bare issue ID after prefix). All real-world branches with descriptions silently fall through to 404-WARN mode.

**Proposed fix:** The spec must specify delimiter-aware extraction. The fix is straightforward: after finding the prefix before `{issue-id}` in the template, also find the character immediately AFTER `{issue-id}` (the separator, e.g., `-` in `fix/{issue-id}-{description}`). Then truncate the regex match at the first occurrence of that separator character in the residue:

```
prefix = "fix/"
separator_after_issue_id = "-"   # character after {issue-id} in template
residue = branch_name.removeprefix(prefix)   # "PROJ-123-fix-crash"
# Extract up to first separator:
issue_id = residue.split(separator_after_issue_id)[0]   # "PROJ-123"
```

If the template has no character after `{issue-id}` (e.g., `fix/{issue-id}` with nothing after), use the full residue with the regex as currently specified.

---

### Finding 2 — CRITICAL: Five ACs are false positives due to Did you mean? prose conflict

**Scenario:** Phase 7 implements the spec correctly: renames `status → pipeline-status`, renames `init → setup-mcp`, deletes `create-pr`, AND inserts the "Did you mean...?" prose in `skills/workflow-router/SKILL.md` per design.md §5.3. The prose contains:

```
- `ceos-agents:status` → did you mean `/ceos-agents:pipeline-status`?
- `ceos-agents:init` → did you mean `/ceos-agents:setup-mcp`?
- `ceos-agents:create-pr` → did you mean `/ceos-agents:publish`?
```

**Five ACs that FAIL on a correct implementation:**

| AC | Command (failing part) | Why it fails |
|----|----------------------|--------------|
| AC-RENAME-STATUS-4 | `grep -rn 'ceos-agents:status\b' ... | wc -l` == 0 | `\b` is a word boundary; `ceos-agents:status` in backtick context still has word boundary after `status` — matches in workflow-router |
| AC-RENAME-STATUS-5 | `! grep -qE '`ceos-agents:status`' skills/workflow-router/SKILL.md` | The Did you mean prose uses exactly `` `ceos-agents:status` `` — match fires |
| AC-RENAME-INIT-4 | `grep -rn 'ceos-agents:init\b' ... | wc -l` == 0 | Same as AC-RENAME-STATUS-4 |
| AC-DEL-CREATE-PR-2 | `grep -rn 'ceos-agents:create-pr\b' ... | wc -l` == 0 | Same pattern |
| AC-DEL-CREATE-PR-7 | `! grep -q '`ceos-agents:create-pr`' skills/workflow-router/SKILL.md` | Did you mean prose uses `` `ceos-agents:create-pr` `` — match fires |

**The spec author identified this** (formal-criteria.md line 323 implementation note) but deferred resolution to Phase 7, saying Phase 7 "should" add `--exclude=skills/workflow-router/SKILL.md` or use option (b) prefix markers. This is insufficient: the formal AC commands themselves in formal-criteria.md are the authority that Phase 8 runs. If Phase 7 only updates the SKILL.md but not the ACs, Phase 8 runs the original (broken) ACs and reports false failures.

**Resolution must happen in Phase 4:** Formal-criteria.md must be updated to add `--exclude=skills/workflow-router/SKILL.md` to AC-RENAME-STATUS-4, AC-RENAME-INIT-4, AC-DEL-CREATE-PR-2. AC-RENAME-STATUS-5 and AC-DEL-CREATE-PR-7 must be scoped to exclude the workflow-router file or must check that the deprecated name appears ONLY in a clearly-marked deprecated-names section (using a structural grep like `grep -A5 'Deprecated names' skills/workflow-router/SKILL.md | grep -q ceos-agents:status`).

---

### Finding 3 — HIGH: Missing Branch naming config key produces wrong behavior

**Scenario:** User is running a project that has an Automation Config without `Source Control → Branch naming` (older config, user never set it). They run `/publish` from branch `main`.

**Execution trace:**
1. design.md Step 0b: Read `Source Control → Branch naming` from Automation Config → returns null/empty
2. Step 0c: `"Identify the literal prefix before {issue-id} in the template"` → prefix = null/empty
3. `"If branch_name does NOT start with the prefix"` — every string starts with an empty prefix (vacuously true)
4. Residue = entire `branch_name` = `"main"`
5. Regex `^[A-Za-z0-9#._-]+` matches `"main"` → `issue_id = "main"`
6. `tracker_needed = true` — MCP pre-flight runs
7. Tracker lookup for `"main"` → `not_found` (404)
8. WARN: `"Branch 'main' contains issue ID pattern 'main' but no matching ticket was found"`
9. Mode = `pr-only-404`

**Expected behavior:** missing `Branch naming` → issue_id = null → mode = `pr-only-no-id` → no tracker contact.

**The WARN message is semantically wrong** — `main` is not "an issue ID pattern" in any meaningful sense. This misleads users into thinking their issue tracker doesn't have an issue named `main` rather than that no extraction was possible.

---

### Finding 4 — HIGH: AC-TEST-INVENTORY-3 verifies only 4 of 6 required changes

design.md Section 7 (Critical / Phase 2 DISAGREEMENT D) mandates 6 edits to `v6.9.0-doc-count-drift.sh`. AC-TEST-INVENTORY-3 verifies only 4:

| Edit | AC-TEST-INVENTORY-3 checks? |
|------|-----------------------------|
| Lines 42-45: flip positive to `'18 optional'` | Yes (grep -qF '18 optional config sections in total') |
| Lines 55-58: flip negative to reject `'19 optional'` | **No** |
| Line 72: `-eq 29` → `-eq 28` | Yes (grep -qE '\beq 28\b') |
| Line 79: `-eq 19` → `-eq 18` | Yes (grep -qE '\beq 18\b') |
| Line 84: fallback prose `'19 optional'` → `'18 optional'` | Partially (same grep as lines 42-45, could match either location) |
| Line 89: PASS message `19 optional, 29 skills` → `18 optional, 28 skills` | **No** |

The gap is not fatal (the test scenario EXECUTION against updated CLAUDE.md would catch a missed line-55-58 flip at runtime), but the AC provides a false sense of completeness for Phase 8 static verification. Phase 8 could report all ACs PASS while the test scenario fails at runtime.

---

### Finding 5 — HIGH: CHANGELOG bullet 4 semantic error (compounded by greedy regex bug)

The CHANGELOG migration item for `/create-pr` removal contains a semantic description that conflates "branch matches Branch naming" with "branch contains an issue ID that exists". The actual logic is:

1. Strip configured prefix from branch name
2. Regex-match the residue to get issue_id  
3. Lookup issue_id in tracker

Under Finding 1 (greedy regex), `fix/PROJ-123-fix-crash` → issue_id = `PROJ-123-fix-crash` → 404 → WARN mode, even though the issue PROJ-123 exists. The CHANGELOG says: "Branch matches Branch naming AND issue exists in tracker → full publish." Users would read this and expect full-publish, but get WARN mode. This is a documentation falsehood until Finding 1 is resolved.

Even after Finding 1 is fixed, the CHANGELOG wording "Branch matches Branch naming" is ambiguous — it should say "Branch starts with the configured prefix AND the residue contains a valid issue ID" to be precise.

---

### Finding 6 — MEDIUM: design.md §8.1 states wrong expected email count for CONTRIBUTING.md

design.md §8.1 Invariant 2 verification comment reads:
```
# Expected: SECURITY.md: 1, CODE_OF_CONDUCT.md: 1, CONTRIBUTING.md: 2
```

Live count in the actual codebase: `CONTRIBUTING.md` has exactly **1** occurrence of `filip.sabacky@ceosdata.com` (the markdown link at line 119). The for-loop command in design.md §8.1 will output `CONTRIBUTING.md: 1`, which contradicts the annotated `Expected: 2`. A Phase 8 reviewer following the script will flag this as a failure. AC-INVARIANTS-2 uses `grep -q` (any match) and passes correctly; the mismatch is only in the Phase 8 narrative script's annotation.

This will cause unnecessary confusion or, worse, a Phase 8 reviewer adding a second email address to CONTRIBUTING.md to satisfy the documented expected count.

---

### Finding 7 — MEDIUM: SC-7 "single line" vs design.md §3.2 three-line WARN sample

`REQ-PUBLISH-AUTO-DETECT SC-7` mandates: "the skill shall emit a **single** `[ceos-agents][WARN]` line."

`design.md §3.2` 404 WARN tier shows:
```
[ceos-agents][WARN] Branch '{branch}' contains issue ID pattern '{issue_id}'
but no matching ticket was found in {tracker_type}.
Creating PR without tracker update.
```

This is three lines in the sample. While design.md §3.2 below the sample says "Single line, WARN level," Phase 7 LLM agents implement from the sample template, not the prose clarification. The result will be three `echo` calls producing a three-line WARN that violates SC-7's single-line mandate.

No AC enforces the single-line constraint, so this ships silently. It matters for log aggregators and any tooling that parses `[ceos-agents][WARN]` prefixed output by line.

---

### Finding 8 — MEDIUM: No AC tests extraction correctness; regex presence check is insufficient

AC-PUBLISH-AUTO-DETECT-3 checks:
```bash
grep -q '\^\[A-Za-z0-9#\._-\]+' skills/publish/SKILL.md
```

This only asserts the regex STRING is present in the file. It does not verify that the extraction algorithm is correct. A Phase 7 implementation that uses the regex in a completely wrong context (e.g., applied to the full branch name instead of the residue after prefix stripping) would pass this AC.

Combined with Finding 1 (where the spec itself specifies a broken algorithm), this means AC-PUBLISH-AUTO-DETECT-3 provides a false sense of correctness verification for the most complex and novel piece of logic in v7.0.0.

---

### Finding 9 — MINOR: No AC for the zero-commits early-stop path

design.md Step 3a documents: "If zero commits → STOP with INFO: 'No changes to publish'". There is no AC verifying this message exists in the rewritten skill. A Phase 7 implementation that omits this check (or silently exits without message) would pass all 11 REQ-PUBLISH-AUTO-DETECT ACs.

---

### Finding 10 — MINOR: FAIL mode webhook behavior unspecified

design.md Step 7: "pr-created event fires in all non-FAIL modes." No statement about what fires on FAIL. Phase 3 brainstorm explicitly mentioned `pipeline-completed` with `outcome: failed` for the FAIL path, but this did not make it into the spec. Phase 7 will leave this implementation-defined. If different Phase 7 implementations make different choices, webhook consumers will see inconsistent behavior on tracker failures.

---

### Finding 11 — MINOR: CHANGELOG theme convention mismatch

Project convention: `## [6.10.0] — 2026-04-24 — Quality Sprint + Security Consistency`
design.md template: `## [7.0.0] — Unreleased`

Missing the theme subtitle `— Cleanup + Naming + Auto-detect Publish`. `keepachangelog.com` allows `Unreleased` as a status indicator, but the project always includes a theme. AC-CHANGELOG-MIGRATION-1 only checks `^## \[7\.0\.0\]` so the template inconsistency ships silently. Low impact (cosmetic), but the CHANGELOG entry will look inconsistent with every prior entry.

---

### Finding 12 — MINOR: EARS wording conflict on /create-pr Related skills treatment

`REQ-DEL-CREATE-PR` EARS clause states: "every active reference ... shall be either **removed** (if a self-contained row/example/array element) or **rewritten to reference /ceos-agents:publish** (if a 'Related skills' or alternative-skill mention)."

Explicit scope entry: `docs/reference/skills.md:363` — **remove** `/create-pr` reference from Related skills in `### /publish` section.

For this location: removing is correct (cannot be related to itself). But the EARS wording implies Related skills mentions SHOULD be rewritten to `/publish`, while the scope says REMOVE. If any other Related skills mentions of `/create-pr` exist beyond line 363 (not currently identified), Phase 7 would rewrite them to `/publish` per EARS, but for line 363 must remove per scope. The EARS–scope inconsistency creates ambiguity about the correct action for the general case.

---

## Spec-Author-Flagged Weak Spots — Verdict

### Weak Spot 1: AC-DOCS-COLLISION-WARN-3 / workflow-router deprecated-identifier sanity grep conflict

**CONFIRMED AND EXPANDED.** This is not just AC-DOCS-COLLISION-WARN-3 — it affects five ACs (see Finding 2). The implementation note in formal-criteria.md line 323 identifies the problem but provides only advisory guidance. The formal-criteria.md AC commands themselves must be fixed in Phase 4 before Phase 7 begins. Severity upgraded from "known weak spot" to CRITICAL because the five conflicting ACs will produce systematic Phase 8 false failures on a correct implementation.

### Weak Spot 2: AC-INVARIANTS-1 JSON shape assumption

**NOT A RISK.** Live verification confirms:
- `.claude-plugin/plugin.json:9` — `"license": "MIT"` ✓ (exact match for AC check)
- `.claude-plugin/marketplace.json:12` (inside `plugins[0]`) — `"license": "MIT"` ✓ (exact match)
- `LICENSE` line 1 — `MIT License` ✓

No v7.0.0 action touches these files (REQ-NO-VERSION-BUMP prohibits version changes; no content changes to license fields). AC-INVARIANTS-1 will pass correctly. This concern is closed.

---

## Summary

DONE — verdict=FAIL, adversarial_findings=12, false_negative_ACs=3 (AC-PUBLISH-AUTO-DETECT-3 misses extraction correctness; AC-TEST-INVENTORY-3 misses 2 of 6 required edits; zero ACs test zero-commit and missing-Branch-naming paths), false_positive_ACs=5 (AC-RENAME-STATUS-4, AC-RENAME-STATUS-5, AC-RENAME-INIT-4, AC-DEL-CREATE-PR-2, AC-DEL-CREATE-PR-7 all fail on correct implementation due to Did you mean? prose), REQ_conflicts=1 (REQ-DEL-CREATE-PR EARS says rewrite-to-publish for Related skills but scope says remove for skills.md:363).

**Blocker before Phase 7:** Finding 1 (greedy regex — CRITICAL correctness bug in the core feature) and Finding 2 (five false-positive ACs — CRITICAL test integrity failure) must be resolved in the spec before Phase 7 execution. The remaining findings are HIGH/MEDIUM/MINOR and can be addressed as spec amendments in the same revision cycle.
