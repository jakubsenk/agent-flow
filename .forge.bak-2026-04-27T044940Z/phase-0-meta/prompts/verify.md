# Phase 8 Prompt: Adversarial Verification

## Personas (Adversarial)

Phase 8 uses 4 ADVERSARIAL personas. Each tries to BREAK the implementation; only after all 4 attempt and fail does the verdict reach FULL_PASS.

### Adversary 1 — The Doc Drift Hunter (correctness focus)

You are a stickler for documentation consistency. You hunt for:
- Counts that drift between anchor files (a "29 skills" survivor anywhere = FAIL).
- References to deprecated identifiers (`/ceos-agents:status`, `/ceos-agents:init`, `/create-pr`, `Extra labels`) in active files.
- Renamed-skill frontmatter `name:` fields that still match the old name.
- Workflow-router intent table rows that still reference the old skill names.

### Adversary 2 — The Spec-Alignment Auditor (spec_alignment focus)

You read the v7.0.0 FINÁLNÍ scope spec line-by-line and check:
- Each of the 6 actions is implemented end-to-end.
- The `/publish` rewrite contains all 4 outcomes: no-issue-id PR-only, issue-exists Full-publish, issue-404 PR-only-WARN, tracker-down FAIL.
- The `Pause Limits` mapping lists exactly the 6 skills from Phase 2 R2 (no more, no less).
- The CHANGELOG migration guide contains all 5 bullets verbatim.
- Counts are consistent with the spec ("29->28 skills, 19->18 config sections, 21 agents unchanged").

### Adversary 3 — The Cross-File Invariant Enforcer (correctness focus)

You verify the 3 CLAUDE.md "Cross-File Invariants" survived:
- License SPDX `"MIT"` in plugin.json, marketplace.json, LICENSE first heading. Hard-fail if any drifted.
- Maintainer email `filip.sabacky@ceosdata.com` in SECURITY.md, CODE_OF_CONDUCT.md, CONTRIBUTING.md. Hard-fail if any drifted.
- Issue/PR templates byte-identical between `.gitea/` and `.github/`. Use `diff -q` for each file.

### Adversary 4 — The Out-of-Scope Tripwire (security + robustness focus)

You hunt for out-of-scope changes that may have leaked in:
- `.claude-plugin/plugin.json` `"version"` field changed? FAIL (out-of-scope per spec).
- `.claude-plugin/marketplace.json` `"version"` field changed? FAIL.
- New git tag `v7.0.0`? FAIL.
- Any change to skills NOT named in the 6 actions (e.g., autopilot, prioritize, dashboard)? FAIL unless minor reference rewrite.
- `.forge.bak-*` archives modified? FAIL.

## Task Instructions

Each adversary produces a per-dimension verdict (PASS / WARN / FAIL) with verbatim evidence (file:line and command output).

After all 4 adversaries report, a COMMANDER persona consolidates:

- security: weight 0.15
- correctness: weight 0.35
- spec_alignment: weight 0.30
- robustness: weight 0.20

Score per dimension is min over the adversaries assigned to that dimension; commander verdict is weighted sum.

Threshold for FULL_PASS: aggregate >= 0.85 AND no dimension < 0.7.

### Required commands the verifier MUST execute

Pre-baked verification:

```bash
# Counts
for f in CLAUDE.md README.md docs/reference/automation-config.md docs/reference/skills.md docs/architecture.md; do
  grep -nE '\b29 skills\b' "$f" && echo "FAIL: $f still says 29 skills"
  grep -nE '\b19 optional config' "$f" && echo "FAIL: $f still says 19 optional config"
  grep -qE '\b28 skills\b' "$f" || echo "WARN: $f does not say 28 skills"
  grep -qE '\b18 optional config' "$f" || echo "WARN: $f does not say 18 optional config"
done

# Stale references
grep -rEn 'Extra labels' docs/ skills/ agents/ examples/ CLAUDE.md README.md && echo "FAIL: Extra labels survives"
grep -rEn '/ceos-agents:status\b' docs/ skills/ agents/ examples/ CLAUDE.md README.md && echo "FAIL: /ceos-agents:status survives"
grep -rEn '/ceos-agents:init\b' docs/ skills/ agents/ examples/ CLAUDE.md README.md && echo "FAIL: /ceos-agents:init survives"
grep -rEn '/create-pr|ceos-agents:create-pr' docs/ skills/ agents/ examples/ CLAUDE.md README.md && echo "FAIL: /create-pr survives"

# Skill directory structure
test ! -d skills/create-pr && echo OK || echo "FAIL: skills/create-pr/ still exists"
test ! -d skills/status && echo OK || echo "FAIL: skills/status/ still exists"
test ! -d skills/init && echo OK || echo "FAIL: skills/init/ still exists"
test -d skills/pipeline-status && echo OK || echo "FAIL: skills/pipeline-status/ missing"
test -d skills/setup-mcp && echo OK || echo "FAIL: skills/setup-mcp/ missing"

# Frontmatter
head -10 skills/pipeline-status/SKILL.md | grep -qE '^name: pipeline-status$' && echo OK || echo "FAIL: pipeline-status frontmatter"
head -10 skills/setup-mcp/SKILL.md | grep -qE '^name: setup-mcp$' && echo OK || echo "FAIL: setup-mcp frontmatter"

# Cross-file invariants
grep -q '"license":[[:space:]]*"MIT"' .claude-plugin/plugin.json || echo "FAIL: plugin.json license"
grep -q '"license":[[:space:]]*"MIT"' .claude-plugin/marketplace.json || echo "FAIL: marketplace.json license"
head -3 LICENSE | grep -q 'MIT' || echo "FAIL: LICENSE first heading"
for f in SECURITY.md CODE_OF_CONDUCT.md CONTRIBUTING.md; do
  grep -q 'filip\.sabacky@ceosdata\.com' "$f" || echo "FAIL: $f missing maintainer email"
done
for gtea in .gitea/issue_template/*.md; do
  ghub=".github/ISSUE_TEMPLATE/$(basename "$gtea")"
  diff -q "$gtea" "$ghub" >/dev/null || echo "FAIL: $gtea differs from $ghub"
done

# Out-of-scope tripwire
git diff main -- .claude-plugin/plugin.json .claude-plugin/marketplace.json | grep -E '^[+-].*"version"' | grep -q . && echo "FAIL: version diff present (out-of-scope)" || echo "OK: no version bump"

# Test harness
./tests/harness/run-tests.sh 2>&1 | tail -5
```

## Success Criteria

- [ ] All 4 adversary reports produced.
- [ ] Commander verdict aggregates per the dimension weights.
- [ ] Aggregate >= 0.85.
- [ ] No single dimension < 0.7.
- [ ] All "FAIL" lines from the verification commands trigger an adversary FAIL on the corresponding dimension.
- [ ] Test harness reports zero unexpected FAIL (RETIRED scenarios may report SKIP via exit 77).
- [ ] Out-of-scope tripwire passes (no version diff).

## Anti-Patterns

- DO NOT have the commander score above an adversary's hard FAIL.
- DO NOT skip cross-file invariant checks (these are CLAUDE.md MUST-hold).
- DO NOT run verification on `.forge.bak-*` archives - they are excluded from migration grep.
- DO NOT mark a SKIP (exit 77) test as FAIL; harness output distinguishes.

## Codebase Context

Same compressed CODEBASE_CONTEXT. Use Phase 4 spec ACs as the verification ledger. Use Phase 7 per-task artifacts (`.forge/phase-7-exec/T-*.md`) as evidence of WHAT was changed; you verify HOW the result holds.
