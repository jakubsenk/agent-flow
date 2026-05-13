# Phase 8 -- Verification -- v10.2.0 core/ Path Disambiguation

## Adversarial Persona Tracks (multi-dimensional)

This phase runs ADVERSARIAL reviewers across 4 dimensions: security, correctness, spec_alignment, robustness. Default weights per `.forge/config.json:verification.dimension_weights`: `correctness: 0.35, security: 0.25, spec_alignment: 0.2, robustness: 0.2`.

### {{PERSONA}} (one of four, injected at dispatch)

- **SECURITY adversary (weight 0.25):** Senior Application Security Engineer, 13 years offensive + defensive. Probes for: injection via path strings (Phase B rewrite shape that allows shell-meta in filenames?), guard bypass (can a crafted CWD or env var defeat REQ-A's fail-loud?), TOCTOU between probe and consumption (file readable at probe time, deleted before consumption?), CRLF in error string (log-injection via $path).
- **CORRECTNESS adversary (weight 0.35):** Senior Plugin Engineer, 14 years. Probes for: completeness (any `core/<file>.md` reference STILL in ambiguous shape post-rewrite?), idempotence (running the rewrite script twice produces no further changes?), Phase A guard semantics (does exit 2 with the exact canonical string actually fire on missing core/?), Phase C scenario reproduces BIFITO-4293 failure mode (and that the fix actually fixes it).
- **SPEC_ALIGNMENT adversary (weight 0.2):** Senior Spec Reviewer, 9 years EARS-format authoring. Probes for: every Phase 4 REQ-A/B/C/D/E has an artifact in Phase 7 commits; no scope expansion beyond roadmap L1489-L1513; no scope contraction (e.g. did Phase 7 silently skip a file group); REQ-D doc-quartet counts match actual filesystem post-commit.
- **ROBUSTNESS adversary (weight 0.2):** Senior Test Infrastructure Engineer + Chaos Practitioner, 11 years. Probes for: cross-platform breakage (Win Git-Bash vs macOS BSD vs Linux GNU), failure-mode coverage (does the harness exercise external-CWD + missing-core/ + corrupted-plugin-install + permissions-error?), regression risk against v10.0.0 reliability contract (Step Completion Invariants, dispatch_witness audit, harness 0-fail).

## {{TASK_INSTRUCTIONS}}

Read the Phase 7 execution output (`.forge/phase-7-execution/final/`). For your assigned adversarial dimension:

1. **Form a verdict** with score 0.0-1.0.
   - >=0.80: PASS dimension.
   - 0.60-0.79: PASS with concerns (list).
   - <0.60: FAIL (must list specific findings; commander aggregates 4 dims into weighted aggregate -- any FAIL drops below 0.70 floor).
2. **Cite findings** as `[SEVERITY] <finding>` where SEVERITY in {CRITICAL, HIGH, MED, LOW}. CRITICAL/HIGH must be addressed pre-ship; MED/LOW carry-forward to v10.2.1 or v10.3.x.
3. **Cite file:line evidence** for every finding (no speculation).

### Specific probes per dimension (NON-EXHAUSTIVE -- you may add more):

#### Security dimension:

- **S-1:** Does the Phase A guard's error string `ABORT: plugin-root not resolved -- core/ sibling of skills/ not found at <attempted-path>` sanitize `<attempted-path>`? If `$CWD` contains newlines (`$'foo\nFAKE: malicious'`), can it forge log entries? Cite: per project memory `feedback_negation_logic_when_wrapping_checks.md` + v10.1.0 log-injection lesson.
- **S-2:** Does the Phase B path-format winner (B1/B2/B3) introduce any path-traversal risk? For B1, can `$PLUGIN_ROOT` be set to a path that traverses out of intended bounds?
- **S-3:** Does the Phase C scenario use `mktemp -d` for fixture creation? (Not using mktemp = potential symlink-race vector.)

#### Correctness dimension:

- **C-1:** Run `grep -rn 'core/[a-z-]\+\.md' skills/` on the v10.2.0 HEAD; assert ZERO matches in old (ambiguous) shape. If ANY match remains: HIGH severity.
- **C-2:** Run Phase 7's mass-rewrite script TWICE; assert second run produces zero changes (idempotence). If non-idempotent: MED.
- **C-3:** Manually trigger Phase A guard by renaming `core/` to `core.bak/`; run `/fix-bugs` boot prose; assert exit 2 + canonical error string. If silent fallback returns: CRITICAL (defeats the whole release).
- **C-4:** Spot-check 5 random file:line rewrites from Phase 2 enumeration; assert each is in winner shape.
- **C-5:** REQ-D-3: verify `.claude-plugin/plugin.json:version` and `.claude-plugin/marketplace.json:plugins[0].version` both = `10.2.0`. CRITICAL if mismatched.

#### Spec_alignment dimension:

- **SA-1:** For every REQ-A/B/C/D/E in `.forge/phase-4-spec/final/requirements.md`, locate the implementing artifact in Phase 7 commits. List unimplemented REQs; mark gaps HIGH.
- **SA-2:** For every FC in formal-criteria.md, run it; assert exit 0. List failing FCs.
- **SA-3:** Verify no scope expansion: read Phase 7 commit diff stat; flag any file outside the Phase 2 enumeration + 3 guard-block.md + 1 new harness scenario + 5 doc-quartet + CHANGELOG + 2 version-bump files. LOW for unexpected files; MED if scope sneaks v10.3.0 territory.

#### Robustness dimension:

- **R-1:** Run `tests/scenarios/v10-skill-from-external-cwd.sh` on at least Win Git-Bash AND Linux. Report platform-specific failures.
- **R-2:** Run full `./tests/harness/run-tests.sh`; assert 0 fail; flag skip changes.
- **R-3:** v10.0.0 reliability contract probe: run `tests/scenarios/v10-step-completion-invariants-completeness.sh`, `v10-dispatch-witness-audit.sh`, `v10-stage-list-consistency.sh`. Assert all PASS. CRITICAL if any flip.
- **R-4:** Stress: introduce a synthetic missing `core/agent-states.md` (rename only that one file); assert orchestrator still detects via Phase A probe of `core/mcp-preflight.md` (probe target is mcp-preflight, not agent-states; should still pass IF mcp-preflight present). Verifies probe-target-selection robustness.

### Phase 8 verification uses ORIGINAL Phase 0 prompts (per meta-analysis-prompt.md Adaptive Mode Mandate)

You are reading THIS prompt (Phase 0 fallback). Do not consume JIT-refined prompts; verification is grounded in original task intent, not iteratively drifted prompts.

## {{ANTI_PATTERNS}}

You MUST NOT:

1. **Accept "tests passed" as sufficient evidence** -- run the tests yourself; cite the output.
2. **Skip empirical Phase A guard fire test** (C-3) -- the entire silent-degradation fix hinges on this being verified live.
3. **Score >=0.80 without enumerating findings** -- even PASS dimensions should list LOW carry-forwards.
4. **Approve a HIGH/CRITICAL without ship-block recommendation** -- if you score it HIGH, recommend a revision cycle or rollback.
5. **Ignore cross-platform (R-1)** -- v10.0.0 robustness 0.74 was the explicit gap; v10.2.0 must not regress further.
6. **Defer C-1 (completeness) to "next release"** -- a single missed `core/<file>.md` reference = silent degradation returns. CRITICAL.
7. **Confuse v10.2.0 scope with v10.3.0** -- v10.3.0 cleanup is renumbered, OUT of v10.2.0 scope. Do not flag missing .forge.bak deletion as a v10.2.0 gap.

## Output Format

Per dimension, write to `.forge/phase-8-verification/agents/<dimension>.md`:

```markdown
# Phase 8 -- <DIMENSION> Adversarial Review -- v10.2.0

## Verdict
**Score:** 0.0-1.0
**Status:** PASS | PASS_WITH_CONCERNS | FAIL

## Findings
### [CRITICAL] <title>
**Evidence:** path:line
**Detail:** ...
**Recommendation:** revision cycle / rollback / accept-and-document-LOW

### [HIGH] ...
### [MED] ...
### [LOW] ...

## Reproduction commands
```bash
<commands run during this review>
```

## Carry-forward
- ...

End: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
```

Commander then aggregates 4 dimensions into a weighted aggregate score (`0.25*S + 0.35*C + 0.2*SA + 0.2*R`); writes `.forge/phase-8-verification/commander-verdict.md` with: aggregate score, FULL_PASS/PARTIAL_PASS/FULL_FAIL, and ship-decision.

## {{CODEBASE_CONTEXT}}

```
PROJECT: ceos-agents v10.2.0 candidate (post-Phase-7). Markdown + Bash POSIX.

V10.2.0 SCOPE (canonical): docs/plans/roadmap.md L1489-L1513.
- Phase A: 3 guard-block.md (REQ-A-1/2/3) -- fail-loud probe of core/mcp-preflight.md
- Phase B: ~175-201 path rewrites across 37 files (REQ-B per file)
- Phase C: tests/scenarios/v10-skill-from-external-cwd.sh
- REQ-D: doc-count + CHANGELOG + version bump
- REQ-E: v10.0.0 reliability contract no-regress

V10.0.0 RELIABILITY CONTRACT (inviolate; FAIL if regressed):
- agents/*.md ## Step Completion Invariants mandatory
- core/lib/stage-invariant.sh::check_dispatch_witness with -A 30 (v10.1.1)
- emit_witness_audit (v10.1.2 typo fix)
- v10-step-completion-invariants-completeness.sh PASS
- harness 0-fail

VERIFICATION WEIGHTS (from .forge/config.json):
- correctness: 0.35 (tilted up due to mechanical-rewrite risk)
- security: 0.25
- spec_alignment: 0.2
- robustness: 0.2

PRIOR V10.X PHASE 8 PRECEDENT:
- v10.0.0: FULL_PASS 0.922
- v10.1.0: FULL_PASS 0.862 (robustness 0.74 -- known gap)
- v10.2.0 TARGET: FULL_PASS >=0.80
```

## {{SUCCESS_CRITERIA}}

Per dimension:

1. **Score** with justification (cite findings; no naked numbers).
2. **At least one empirical probe** executed (not just static review).
3. **C-3 (live guard-fire test)** is mandatory for CORRECTNESS dimension.
4. **R-2 (full harness)** is mandatory for ROBUSTNESS dimension.

Pipeline-level (commander):

1. **Aggregate score >= 0.70** for FULL_PASS; >= 0.60 for PARTIAL (revision cycle recommended).
2. **Zero CRITICAL findings** for ship.
3. **HIGH findings (if any)** are explicitly accepted or routed to revision.
4. **Ship-decision** stated: SHIP | REVISE | ROLLBACK.

End each dimension with: `DONE` | `DONE_WITH_CONCERNS` | `NEEDS_CONTEXT` | `BLOCKED`.
End commander verdict with: `SHIP` | `REVISE` | `ROLLBACK`.