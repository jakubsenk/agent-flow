# Agent 1: Conservative Incrementalist — Implementation Analysis

**Role:** Senior DevOps Platform Engineer (15 years, CLI tools)
**Mantra:** "The safest change is the smallest change that works."

---

## 1. Implementation Ordering

**Recommended file modification order (8 files, strict sequence):**

| Order | File | Rationale |
|-------|------|-----------|
| 1 | `commands/scaffold.md` | Single source of truth. Every other file mirrors it. Get the canonical text right first. |
| 2 | `tests/scenarios/scaffold-v2-happy-path.sh` | Write assertions against the canonical text immediately. Run tests to confirm scaffold.md is internally consistent. |
| 3 | `tests/scenarios/scaffold-v2-no-implement.sh` | Extend with Step 0-INFRA assertion. Run full test harness to gate before touching docs. |
| 4 | `docs/reference/pipelines.md` | Highest-fidelity documentation — Stages table and Mermaid diagram. Must match scaffold.md exactly. |
| 5 | `CLAUDE.md` | ASCII text diagram. Plugin's own instructions must reflect the new flow. |
| 6 | `docs/architecture.md` | Mermaid `graph LR` update. |
| 7 | `README.md` | Public-facing Mermaid `flowchart TD` update. |
| 8 | `docs/reference/commands.md` | Prose-only update — one or two sentences. Lowest risk. |

**Why scaffold.md first, not documentation first:** The documentation files are all derivative of the command definition. If you write docs first, you are writing against an imagined state. If scaffold.md changes during implementation (wording adjustments, heading tweaks), every doc written earlier becomes stale. Scaffold.md is the single source of truth — lock it down, test it, then propagate outward.

**Changelog + version bump are last** (order 9-10), as per the project's established convention: content first, changelog in the same or next commit, version bump as a separate commit.

---

## 2. Step 0-INFRA Placement

**After State Detection, before Step 0 (Mode Selection).** The research document (Decision 3) is correct and I agree with the rationale.

**Why not before State Detection:** State Detection (L38-L47) can halt the entire command ("Existing project with CLAUDE.md -> use /implement-feature"). Asking infrastructure questions before that halt wastes the user's time and is confusing UX. State Detection is a cheap, zero-interaction gate. It must run first.

**Why not after Mode Selection:** The mode (Interactive/YOLO/Full YOLO) does not affect what infrastructure questions are asked — it only affects downstream behavior (confirmations, skips). Infrastructure declaration is mode-independent. Placing it after Mode Selection would mean the `--no-implement` early exit (which fires at Step 0) would bypass 0-INFRA entirely, defeating the purpose for the legacy flow.

**Interaction with `--no-implement` early exit:** The current `--no-implement` exit at Step 0 (L55-L56) fires after Step 0-INFRA and Step 0-MCP. This is correct: the legacy flow (L1-L6) benefits from knowing SC status (for the proposed L5b push). The exit still happens before Mode Selection, Brainstorming, and Specification — no wasted work.

**Confirmed order:**
```
Flag Parsing -> Flag Validation -> State Detection
  -> Step 0-INFRA -> Step 0-MCP
  -> Step 0 (Mode Selection, --no-implement exits here)
  -> Step 0b (Brainstorm) -> Step 1 ...
```

---

## 3. init.md Inline Invocation — MCP Detection Strategy

**Option A is the only viable option. init.md cannot be called inline.** I fully agree with the research resolution.

The blocker is init.md Step 1's unconditional hard gate: it reads Automation Config from CLAUDE.md and errors if absent. During scaffold, CLAUDE.md does not exist until Step 3 (skeleton generation) at the earliest. There is no bypass parameter, and adding one would be a contract change to init.md (touching a file outside the design scope, increasing risk).

**My recommended approach for Step 0-MCP:**

1. **Do not call `/init`.** Do not modify `commands/init.md`.
2. **Replicate only the MCP detection subset** in scaffold.md's Step 0-MCP prose:
   - Accept tracker type from Step 0-INFRA in-memory state.
   - Use the lookup table (from `docs/reference/trackers.md` / init.md Step 3) to determine the expected MCP package name.
   - Scan for `mcp__*` tools matching the tracker type.
   - If found: verify connectivity with a minimal query.
   - If not found: offer guidance, allow downgrade to "later".
3. **For `.mcp.json.example` generation** (Step 4 extension): replicate the template structure from `examples/mcp-configs/{type}.json` with `<YOUR_*>` placeholders. Never write real tokens.

**Key constraint:** The replication must be clearly documented as "derived from init.md Steps 3-7" so that future init.md changes prompt a reviewer to check scaffold.md for drift. A comment in scaffold.md's Step 0-MCP section should say: `<!-- Replicates init.md Steps 3-7 detection logic. Keep in sync. -->`

---

## 4. Documentation Update Strategy

**Three-pass approach to ensure all references are caught:**

**Pass 1 — Automated search (before any edits):**
Run these searches against the entire repo to build a hit list:
- `grep -r "Step 9"` (excluding the plan file itself) — every match is a candidate for update or removal
- `grep -r "Step 10"` — every match must become "Step 9"
- `grep -r "Step 4b"` — every match must be removed
- `grep -r "Step 4c"` — every match must be removed
- `grep -r "Issue Tracker.*Optional"` — catches heading text of old Step 9
- `grep -r "Tracker Configuration.*Auto-Finalize"` — catches heading text of old Step 4b

**Pass 2 — Diagram audit (after scaffold.md is finalized):**
For each file containing a Mermaid or ASCII diagram referencing scaffold:
- `README.md` (flowchart TD)
- `docs/architecture.md` (graph LR)
- `docs/reference/pipelines.md` (flowchart TD + Stages table)
- `CLAUDE.md` (ASCII text)

Manually verify that every node in the diagram has a corresponding `### Step` heading in scaffold.md, and vice versa. No orphaned nodes, no missing steps.

**Pass 3 — Post-edit verification (after all edits):**
Run the full test suite (`./tests/harness/run-tests.sh`). Then:
- `grep -r "Step 10" commands/` — must return zero matches
- `grep -r "Step 4b" commands/` — must return zero matches
- `grep -r "Step 4c" commands/` — must return zero matches
- `grep -rn "Step 9" commands/scaffold.md` — must return exactly one match (the renamed Final Report heading)

---

## 5. Step Numbering — "0-INFRA" / "0-MCP" Consistency

**The naming is consistent with existing conventions.** Here is the evidence:

| Existing Step | File | Convention |
|---|---|---|
| `Step 0b` | scaffold.md (Brainstorming) | Alphanumeric suffix on Step 0 |
| `Step 0b` | implement-feature.md (Config Validity Gate) | Same pattern |
| `Step 0c` | implement-feature.md (Feature from Description) | Same pattern |
| `Step 4b` | scaffold.md (Tracker Config, being removed) | Alphanumeric suffix on Step 4 |
| `Step 4c` | scaffold.md (MCP Guidance, being removed) | Same pattern |
| `Step 7b` | scaffold.md (Spec Compliance Check) | Same pattern |
| `Step 6b` | status.md (Configuration Readiness) | Same pattern |

The project consistently uses `{N}{letter}` for sub-steps of step N. The proposed `0-INFRA` and `0-MCP` use a different convention: `{N}-{LABEL}` instead of `{N}{letter}`.

**This is an intentional departure, and I consider it acceptable because:**

1. `0a` and `0b` would collide with the existing `0b` (Brainstorming). The sequence would be `0a (INFRA) -> 0-MCP -> 0 (Mode) -> 0b (Brainstorm)` which is confusing since `0b` already exists.
2. The hyphen-label format (`0-INFRA`, `0-MCP`) is self-documenting in grep output, test assertions, and state.json. Readers do not need to look up what "Step 0a" means.
3. The pattern parallels `4d` and `4e` (which follow the existing convention because no collision exists).

**Minor concern:** The coexistence of two naming conventions (`0-INFRA` label-style and `4d` letter-style) in the same command could confuse contributors. I would suggest adding a one-line comment in scaffold.md's Orchestration section: `<!-- Step numbering: 0-INFRA and 0-MCP use label suffixes to avoid collision with existing Step 0b. Steps 4d and 4e use letter suffixes per standard convention. -->`

---

## 6. Testing Strategy

The project uses structural-only tests (grep assertions against markdown file content). There is no runtime, no build step, no dynamic execution. This limits testing to:

**What can be tested (and should be):**

1. **Presence assertions** — new step headings exist in scaffold.md:
   - `grep -q "Infrastructure Declaration"` (Step 0-INFRA)
   - `grep -q "0-MCP"` (Step 0-MCP)
   - `grep -q "Push to Remote"` (Step 4d)
   - `grep -q "Create Tracker Issues"` (Step 4e)

2. **Absence assertions** — removed steps are gone:
   - `! grep -q "Step 4b"` (old Tracker Configuration removed)
   - `! grep -q "Step 4c"` (old MCP Guidance removed)
   - `! grep -q "Step 9: Issue Tracker"` (old Issue Tracker Optional removed)

3. **Regression guards** — existing content not broken:
   - All existing assertions in happy-path and no-implement tests continue to pass (research confirmed these are safe)
   - `grep -q "Step 9: Final Report"` (renamed from Step 10 — verifies renumbering happened)

4. **Cross-file consistency** — new assertion idea:
   - In happy-path, assert that `Step 10` does NOT appear in scaffold.md: `! grep -q "Step 10" "$SCAFFOLD_CMD"`
   - In happy-path, assert pipelines.md Stages table row count is consistent (count lines matching `| [0-9]`)

**What cannot be tested structurally:**
- Correct ordering of steps (grep cannot verify that Step 0-INFRA appears before Step 0)
- In-memory state propagation (there is no runtime to test)
- MCP connectivity behavior
- Mermaid diagram correctness (no renderer in the test suite)

**Recommendation:** Add the assertions specified in the research document (section 3, Note 3) plus the two additional cross-file consistency checks above. Run `./tests/harness/run-tests.sh` after each file is modified (not just at the end) to catch regressions incrementally.

---

## 7. Risk Mitigation

### Top 3 Implementation Risks (Ranked)

**Risk #1: Stale internal references after step removal/renumbering (LIKELIHOOD: HIGH, IMPACT: HIGH)**

Scaffold.md is 567 lines with at least 6 internal cross-references ("jump to Step 10" at L443, L449; "Step 9" at L544; etc.). Removing 3 steps and renumbering 1 creates a cascade where every "Step N" reference for N >= 9 must be audited. Missing even one creates a command that instructs Claude to jump to a nonexistent step, which would silently break pipeline execution.

**Mitigation:** After all scaffold.md edits, run: `grep -n "Step [0-9]" commands/scaffold.md` and verify every match. There must be zero occurrences of "Step 10" and exactly one "Step 9" (the renamed Final Report heading). The MCP Pre-flight Check section at the bottom of the file is the most likely place to miss.

**Risk #2: MCP Pre-flight Check section forgotten (LIKELIHOOD: MEDIUM-HIGH, IMPACT: HIGH)**

The MCP Pre-flight Check is a policy section at the tail of scaffold.md (L540-L551), visually separated from the step definitions. It is easy to edit all the numbered steps and declare victory without scrolling to the bottom. The current text references "Step 9" as an MCP trigger — leaving it unchanged creates a direct contradiction with the new flow.

**Mitigation:** The implementation checklist must include "Rewrite MCP Pre-flight Check section" as a mandatory item, not an afterthought. The post-edit `grep -n "Step 9"` verification from Risk #1 will also catch this (if "Step 9" appears in the pre-flight section, it is the old reference).

**Risk #3: In-memory state concept lost in translation (LIKELIHOOD: MEDIUM, IMPACT: MEDIUM)**

Steps 4d and 4e depend on values collected at Step 0-INFRA being "carried in memory" — but this is a markdown command definition, not executable code. The concept of "in-memory state" must be expressed as prose instructions to Claude. If the prose is ambiguous or insufficiently explicit, Claude may re-read CLAUDE.md at Step 4d (which still has TODO markers) instead of using 0-INFRA values, causing silent failures.

**Mitigation:** Each of Steps 4, 4d, and 4e must include a bolded instruction: **"Use the infrastructure values collected at Step 0-INFRA (tracker_type, tracker_instance, sc_remote, etc.). Do NOT re-read Automation Config from CLAUDE.md — it may still contain TODO markers."** The same instruction must appear in the rewritten MCP Pre-flight Check section.

---

## One Concern the Design Missed

**The design does not address the `--issue` + `--no-implement` combination's interaction with Step 0-INFRA.**

Flag Validation (L26-31) rejects `--no-implement AND any of (--spec, --template, --issue)` with an error. This means `--issue` and `--no-implement` cannot coexist. However, the research document (Decision 2) describes `--issue` auto-detecting tracker as "ready" at Step 0-INFRA, and Decision 5 describes `--no-implement` passing through Step 0-INFRA. These are mutually exclusive paths due to the flag validation gate, so there is no actual conflict — but the design document never explicitly acknowledges this. An implementer reading Decision 2 and Decision 5 in isolation might think they need to handle the combined case.

**More importantly:** The design says Step 0-INFRA runs for `--no-implement`, and the legacy flow's L5 should get an L5b (push to remote if SC=ready). But the legacy flow's L6 Report (L127-L147) lists "Create issues in your issue tracker" as a next step. If the user declared tracker="ready" at Step 0-INFRA in a `--no-implement` run, Step 4e does not run (no epics exist), but the user just told us their tracker is ready. The L6 report should adapt its "Next steps" based on the declared infrastructure status:
- If tracker=ready: "Your tracker is connected. Use `/implement-feature` with an issue ID."
- If tracker=later: "Create issues in your issue tracker" (current text, appropriate for "later")

This conditional in L6 is not called out in the design or the research. It is a small change but without it, the L6 report will give stale advice to users who declared tracker=ready.

---

## GO/NO-GO Recommendation

**GO** — with one mandatory pre-condition and two advisories.

**Mandatory pre-condition:**
- Add the L6 Report conditional for `--no-implement` + infrastructure status (the missed concern above). This is a ~5 line addition to the legacy flow's L6 section and does not change the overall design or increase scope meaningfully.

**Advisory 1:** Before starting implementation, run the full Pass 1 search (section 4 above) and save the hit list. After completing all edits, re-run the same searches and verify every hit was addressed. This is the single most effective risk mitigation for this change.

**Advisory 2:** Implement scaffold.md as a single atomic editing session. Do not interleave scaffold.md edits with documentation edits. The reason: if you edit scaffold.md, then edit README.md, then return to scaffold.md for a wording change, the README.md Mermaid diagram may already be stale. Lock down scaffold.md completely, run tests, then propagate to docs.

**Rationale for GO:** The design is thorough. The research resolved all ambiguous decisions. The change is a net simplification (3 steps removed, 4 added, but the new steps are earlier and more useful). The risk profile is manageable with the mitigations described. The version increment (MINOR) is correct — no breaking changes to the Automation Config contract. The test strategy is adequate for a structural-only test suite.
