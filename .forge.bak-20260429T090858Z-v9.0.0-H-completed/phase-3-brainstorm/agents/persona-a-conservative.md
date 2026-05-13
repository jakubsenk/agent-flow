# Persona A — The Conservative Maintainer: "Close the Coverage Gap, Don't Build a Schema Cathedral"

**Recommendation:** PARTIAL. Do **not** add `## Inputs`/`## Outputs` declaration sections to all 18 agents. Instead, (a) fix the three stale pre-v8 scenarios (`frontmatter-completeness.sh`, `section-order.sh`, `read-only-agents.sh`) so output-shape regressions are *detectable* against the existing de-facto contracts (the `## Triage Analysis`, `## Fix Report`, `## Code Review` headings already in agent bodies); (b) document the existing prose contract in `docs/reference/agents.md` as a "Conventions" subsection naming the canonical output headings per agent; (c) defer any new declaration sections until at least one Phase-2-class failure is attributable to output-section drift. Q1 confirms zero such failures across three forge cycles. Premature formalization is the actual risk here, not absent contracts.

**Schema language:** No schema. Typed prose list in `docs/reference/agents.md` (one row per agent listing its canonical output heading, e.g., `analyst --phase triage` -> `## Triage Analysis`). Agent prompts ARE consumed by an LLM, not a parser; prose with backtick-quoted headings is the natural-language form the LLM already follows.

**Contract location:** No new location in agent files. Existing runtime output sections (`## Fix Report`, `## Code Review`, etc.) remain the contract surface. Documentation lives in `docs/reference/agents.md` only.

**Validation mechanism:** Static lint via tests/harness only. Specifically: extend the three currently-broken scenarios to enumerate the live 18-agent set, and add one new scenario `agents-canonical-output-headings.sh` that greps each agent body for its declared canonical heading from a hardcoded mapping. No dispatcher changes, no LLM self-validation, no sidecar.

**Backward-compat strategy:** No change to agent files. No change to override injector. No change required for any v8.0.0 customization/* override file. Zero migration burden for consuming projects (Q7 confirms this is true even under heavier proposals; under this one it is trivially true).

**Versioning verdict:** No bump needed for the agent shape. The doc-only addition + 4 test scenario fixes is a PATCH (v8.0.1) — slot it into the already-queued v8.0.1 polish ticket alongside the 7 LOW items. The MEMORY allocation of v9.0.0 to "sub-projekt H" is reframed: v9.0.0 is freed for the pre-announced `.md` overlay hard removal + deprecated agent name hard errors (per Q7), which are real breaking changes. I/O contracts get a reserved v9.x.0 slot only if Phase 2 evidence shifts.

**Test strategy:** Four scenarios in `tests/scenarios/`:

1. `frontmatter-completeness.sh` — replace hardcoded 21-agent v7 list with a dynamic enumeration `for f in "$REPO_ROOT"/agents/*.md`. (Fix existing FAIL.)
2. `section-order.sh` — same fix; enumerate live agents, assert the existing 4-section order (Goal/Expertise/Process/Constraints). Do **not** add `## Inputs`/`## Outputs` to the asserted order.
3. `read-only-agents.sh` — replace silent `continue` on missing files with hard `fail` if any of the canonical read-only agent names are absent (closes Q1's silent-mask gap).
4. `agents-canonical-output-headings.sh` — NEW. Mapping table inline (agent name -> expected `## Heading`); for each agent file, `grep -qE '^## Triage Analysis'` etc.; SKIP-guard `exit 77` only for analyst's per-phase split. ~40 lines bash, mirrors `ac5-fixer-reviewer-token-constraints.sh` pattern (Q10).

## Defense (300-500 words)

The brainstorm prompt explicitly invites me to defend "do nothing" if the WHETHER question lacks a counter. Q1 is the counter that isn't there: zero output-shape failures across three forge cycles, with a per-failure taxonomy that attributes 62/62 forge-2026-04-25-001 failures to Windows portability bugs, undeployed test files, and one design.md omission. None to output-section drift. The Phase 2 synthesis honestly acknowledges this in its own "Both-sides argument" under Q1: "prevent a class of failure that has never occurred ... speculative ROI."

The strongest counter-argument is also in Q1: the harness has *zero coverage* to detect output-shape violations, so absence-of-evidence is partly evidence-of-absence-of-coverage. I accept this counter — and my proposal *resolves* it. Fixing the three stale scenarios (Q9 confirms only `section-order.sh` is structurally affected by new sections; the other two are simply broken on stale agent lists) plus adding one canonical-headings xref scenario gives us coverage for the existing de-facto contract without inventing a new contract surface. We get the detection that Q1 says is missing, at PATCH cost, with no agent file changes, no override risk, no policy amendment.

Q3 shows MCP `outputSchema` shipped optional in 2025-06-18 and CrewAI `output_pydantic` is `Optional[None]` by default — but those are *runtime-validated* contracts in Python frameworks where a parser exists. Q2 establishes that ceos-agents has no parser: the Task tool returns raw LLM output verbatim. Adopting MCP/CrewAI's *form* without their *enforcement* is cargo-cult formalization. We'd be adding the syntactic overhead (18 agent files, table format constraint per C2, per-mode duplication per C3) and getting only "the LLM may pay attention to a heading we wrote" — the same value we already get from existing `## Fix Report` / `## Code Review` headings in the agent bodies today.

Q8 calls out the version policy gap honestly: optional declaration sections do not fire the existing MAJOR clause ("structured output sections that Agent Overrides or external tooling **may parse**" — nothing parses these). The synthesis recommendation is a policy amendment to classify them MINOR. But amending the versioning policy to accommodate a feature with no demonstrated need is the textbook "premature formalization that locks in the wrong abstraction" — my pet peeve, named in the prompt. If we ship optional `## Inputs`/`## Outputs` and discover in v9.2.0 that we want a different shape (YAML block? frontmatter extension? sidecar?), Hyrum's Law (Persona B will invoke this) bites *us* because consumers will have started grepping the table format we shipped. Don't formalize what you don't yet need.

Finally: customization/ overrides. Q6 confirms the injector is structure-blind so additions are safe — but "safe" is not "free." Each new section is one more thing the maintainer must remember to update across 18 files, keep in sync across 4 docs files (per `feedback_doc_completeness.md` discipline), and propagate through the Phase 6 plan. The doc-count drift discipline is *already* a known maintenance tax; this proposal multiplies it.

**Prove necessity. Q1 didn't.**

## Failure modes I accept

1. **No protection against future output-shape drift in agents I haven't yet broken.** If a future fixer.md edit silently renames `## Fix Report` -> `## Fix Summary`, my canonical-headings scenario catches it for that one agent — but only because I hardcoded the mapping. A *new* polymorphic mode added to test-engineer with a *new* output heading I forgot to add to the mapping would not be caught. Mitigation: the mapping lives in `docs/reference/agents.md` and the scenario, both reviewable in the same PR.

2. **No machine-readable contract for the v10 Node.js Runtime / dashboard ingestion path.** Persona B will hammer this. My counter: v10 is in a separate repo, scope is explicitly "delegated to forge phase 1 research" (per MEMORY v9.2.0/v10.0.0 entries), and forge phase 1 is the *correct* place to design the contract surface for that consumer — not preemptively in v9.0.0 of the plugin. YAGNI applies until the consumer exists and tells us what shape it actually needs.

3. **No formal AC traceability beyond what architect's `maps_to` field already provides.** Persona C may push on operational ROI for AC fulfillment auditing. My counter: the AC fulfillment check already lives in reviewer's `## Code Review` output (per CLAUDE.md "AC Fulfillment section"); adding a redundant `## Outputs` declaration of "I emit AC fulfillment verdicts" doesn't audit anything the reviewer doesn't already audit, it just lets a future linter assert that reviewer's prompt *says* it audits. Self-attesting metadata is the least useful kind.

## Summary (under 80 words)

Fix what's actually broken (three stale scenarios that have been masking output-shape regressions for 5 weeks), document the de-facto contract that already exists in agent prose, and close the WHETHER question by waiting for Phase 2-class evidence before adding 18 agent file mutations + a versioning policy amendment + a doc-count drift multiplier. PATCH bump (v8.0.1 polish queue). v9.0.0 reserved for the pre-announced overlay/agent-name hard errors.
