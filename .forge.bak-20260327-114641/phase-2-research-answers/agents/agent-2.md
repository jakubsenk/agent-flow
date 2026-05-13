# Agent 2: Forensic Search — All Scaffold Step References

**Scope:** Complete search across all `.md` files in the repository for scaffold step references that are candidates for update or removal. Results classified by action required.

**Classification key:**
- **MUST UPDATE** — active reference docs: `commands/scaffold.md`, `docs/reference/pipelines.md`, `docs/reference/agents.md`, `docs/architecture.md`, `README.md`, `CLAUDE.md`
- **DO NOT UPDATE** — historical plans (`docs/plans/*.md`), brainstorms, CHANGELOG entries (frozen record)
- **MAYBE UPDATE** — tests, examples, roadmap items, state/core docs

---

## Search 1: "Step 4b"

### Non-forge matches only (active files)

| File | Line | Content | Classification |
|------|------|---------|----------------|
| `commands/scaffold.md` | 263 | `### Step 4b: Tracker Configuration (Auto-Finalize) — Full YOLO skips this step` | **MUST UPDATE** — this heading must be REMOVED |
| `CHANGELOG.md` | 58 | `**Scaffold auto-finalize (Steps 4b/4c):** After skeleton generation...` | DO NOT UPDATE — historical entry |
| `docs/plans/roadmap.md` | 142 | `**Files:** \`commands/scaffold.md\` (Steps 4b, 4c)` | MAYBE UPDATE — roadmap item marking v5.3.0 as IMPLEMENTED |
| `docs/plans/2026-03-27-scaffold-infrastructure-design.md` | multiple | Problem description and migration table | DO NOT UPDATE — design plan for this very feature |

**All other "Step 4b" matches** are in `.forge/` work directories or `.forge.bak-*/` — DO NOT UPDATE.

---

## Search 2: "Step 4c"

### Non-forge matches only (active files)

| File | Line | Content | Classification |
|------|------|---------|----------------|
| `commands/scaffold.md` | 265 | `If mode is Full YOLO → skip to Step 4c (TODOs remain — cannot guess tracker URLs in unattended mode).` | **MUST UPDATE** — line must be REMOVED (Step 4c no longer exists) |
| `commands/scaffold.md` | 272 | `If \`incomplete_keys\` is empty → skip to Step 4c (no TODOs to fill).` | **MUST UPDATE** — line must be REMOVED |
| `commands/scaffold.md` | 300 | `### Step 4c: MCP Guidance` | **MUST UPDATE** — entire section (lines 300–307) must be REMOVED |
| `commands/scaffold.md` | 302 | `If Issue Tracker Instance was filled in Step 4b:` | **MUST UPDATE** — part of Step 4c block, removed with section |
| `CHANGELOG.md` | 58 | `**Scaffold auto-finalize (Steps 4b/4c):**...` | DO NOT UPDATE — historical entry |
| `docs/plans/2026-03-27-scaffold-infrastructure-design.md` | multiple | Design plan references | DO NOT UPDATE |

---

## Search 3: "Step 9" (scaffold context vs. other commands)

### Non-forge matches (active files) — classified by context

| File | Line | Content | Context | Classification |
|------|------|---------|---------|----------------|
| `commands/scaffold.md` | 481 | `### Step 9: Issue Tracker (Optional)` | Scaffold | **MUST UPDATE** — section must be REMOVED |
| `commands/scaffold.md` | 544 | `- Step 9 — creating cards in issue tracker (only when tracker is configured and user opts in)` | Scaffold (MCP pre-flight) | **MUST UPDATE** — reference must be updated to Step 4e |
| `commands/init.md` | 195 | `## Step 9: Closing message` | init wizard — unrelated | DO NOT UPDATE — different command entirely |
| `commands/onboard.md` | 212 | `### Step 9: Closing Message` | onboard wizard — unrelated | DO NOT UPDATE — different command |
| `docs/reference/pipelines.md` | 280 | `\| 9 \| Issue Tracker \| (command) \| N/A \| Optional — create cards from spec/epics/ \|` | Scaffold pipeline table | **MUST UPDATE** — row must be REMOVED (Step 9 gone) |
| `docs/plans/2026-03-27-scaffold-infrastructure-design.md` | 13, 109, 128, 130 | Design plan for removal | DO NOT UPDATE |
| `docs/plans/2026-03-06-scaffold-v2-*.md` | multiple | Historical plan references | DO NOT UPDATE |
| `CHANGELOG.md` | 71 | `**Scaffold Step 10 (Final Report):**...` | Different step | DO NOT UPDATE |

---

## Search 4: "Tracker Configuration"

### Non-forge matches (active files)

| File | Line | Content | Classification |
|------|------|---------|----------------|
| `commands/scaffold.md` | 263 | `### Step 4b: Tracker Configuration (Auto-Finalize) — Full YOLO skips this step` | **MUST UPDATE** — removed with Step 4b |
| `docs/plans/2026-03-27-scaffold-infrastructure-design.md` | 9, 107 | Design plan | DO NOT UPDATE |

No matches in `docs/reference/`, `docs/guides/`, `docs/architecture.md`, `CLAUDE.md`, `README.md`, `agents/`, `tests/`, `examples/`.

---

## Search 5: "MCP Guidance"

### Non-forge matches (active files)

| File | Line | Content | Classification |
|------|------|---------|----------------|
| `commands/scaffold.md` | 300 | `### Step 4c: MCP Guidance` | **MUST UPDATE** — removed with Step 4c |
| `docs/plans/2026-03-27-scaffold-infrastructure-design.md` | 9, 108 | Design plan | DO NOT UPDATE |

No matches in `docs/reference/`, `docs/architecture.md`, `README.md`, `CLAUDE.md`, `agents/`, `tests/`, `examples/`, `docs/guides/`.

---

## Search 6: "Issue Tracker.*Optional" (case-insensitive)

### Non-forge matches (active files)

| File | Line | Content | Classification |
|------|------|---------|----------------|
| `commands/scaffold.md` | 481 | `### Step 9: Issue Tracker (Optional)` | **MUST UPDATE** — removed with Step 9 |
| `docs/reference/pipelines.md` | 280 | `\| 9 \| Issue Tracker \| (command) \| N/A \| Optional — create cards from spec/epics/ \|` | **MUST UPDATE** — row removed; Step 4e row added |
| `docs/architecture.md` | 147 | `Required sections (Issue Tracker, Source Control...) must be present...` | Context is optional config sections — NOT scaffold-specific, DO NOT UPDATE |
| `CHANGELOG.md` | 293 | Historical changelog entry | DO NOT UPDATE |
| `commands/onboard.md` | 264 | Onboard command — unrelated | DO NOT UPDATE |
| `docs/plans/2026-03-06-scaffold-v2-*.md` | multiple | Historical plans | DO NOT UPDATE |
| `docs/reference/agents.md` | 332 | Agent description for priority-engine — unrelated context | DO NOT UPDATE |

---

## Search 7: "auto-finalize" / "Auto-Finalize" (case-insensitive)

### Non-forge matches (active files)

| File | Line | Content | Classification |
|------|------|---------|----------------|
| `commands/scaffold.md` | 263 | `### Step 4b: Tracker Configuration (Auto-Finalize) — Full YOLO skips this step` | **MUST UPDATE** — removed with Step 4b |
| `CHANGELOG.md` | 55 | `scaffold-to-deployment workflow: auto-finalize, config validity gate...` | DO NOT UPDATE — historical |
| `CHANGELOG.md` | 58 | `**Scaffold auto-finalize (Steps 4b/4c):**...` | DO NOT UPDATE — historical |
| `docs/plans/roadmap.md` | 138 | `### Scaffold Auto-Finalize` (section heading for v5.3.0 item) | MAYBE UPDATE — roadmap section should be reclassified from PLANNED to SUPERSEDED/REMOVED once the new design is implemented |

---

## Search 8: "Step 10" in scaffold context

### Non-forge matches (active files)

| File | Line | Content | Classification |
|------|------|---------|----------------|
| `commands/scaffold.md` | 443 | `- fail-fast → STOP pipeline, jump to Step 10 (report what was completed)` | MAYBE UPDATE — Step 10 still exists (Final Report), but its line numbers may shift after removal of Step 9 |
| `commands/scaffold.md` | 449 | `If still failing → STOP and jump to Step 10 (report)` | MAYBE UPDATE — same as above; references remain valid if Step 10 is renumbered to Step 9 |
| `commands/scaffold.md` | 503 | `### Step 10: Final Report` | **MUST UPDATE** — heading must change to `### Step 9: Final Report` (Step 9 removed, Step 10 becomes Step 9) |
| `CHANGELOG.md` | 70 | `**Scaffold Step 10 (Final Report):**...` | DO NOT UPDATE — historical entry |
| `docs/reference/pipelines.md` | 281 | `\| 10 \| Final Report \| (command) \| N/A \| Summary with features, tests, TODOs \|` | **MUST UPDATE** — row number changes from 10 to 9 |
| `docs/plans/2026-03-27-scaffold-infrastructure-design.md` | 131, 133 | Design plan | DO NOT UPDATE |

**Note on Step 10 renumbering:** The design document (`docs/plans/2026-03-27-scaffold-infrastructure-design.md`) states Step 9 is REMOVED and replaced by Step 4e. This means Final Report (currently Step 10) must be renumbered to Step 9, and internal jump references (`jump to Step 10`) must also update.

---

## Search 9: "Step 0-INFRA" / "0-INFRA"

### Non-forge matches (active files)

| File | Line | Content | Classification |
|------|------|---------|----------------|
| `docs/plans/2026-03-27-scaffold-infrastructure-design.md` | 28, 55, 103, 107, 119, 125, 166, 173 | Design specification — authoritative source | DO NOT UPDATE |

**Conclusion:** "Step 0-INFRA" appears ONLY in the design plan. It does NOT yet exist in `commands/scaffold.md`, `docs/reference/pipelines.md`, `README.md`, `CLAUDE.md`, or any other active file. It must be **ADDED** during implementation — it is not a stale reference to remove, but a new step to create.

---

## Search 10: Mermaid diagrams containing scaffold content

### Mermaid blocks in non-forge active files

| File | Line | Scaffold-related? | Classification |
|------|------|-------------------|----------------|
| `README.md` | 112–124 | YES — Scaffold Pipeline flowchart | MAYBE UPDATE — the mermaid diagram shows `Git["Git Init + Commit"]` without Step 0-INFRA or Step 4d/4e nodes. After the new design, the diagram should be updated to reflect infrastructure declaration upfront and push/tracker issue steps after Git Init |
| `docs/reference/pipelines.md` | 208–? | Scaffold pipeline | **MUST UPDATE** — the stage table at line 280 references Step 9 and Step 10; the mermaid diagram above it should also be checked |
| `docs/architecture.md` | 21, 80, 99, 118, 163 | Multiple diagrams | MAYBE UPDATE — check if any diagram shows scaffold-specific steps |

### README.md mermaid (lines 112–124) — exact content:
```
flowchart TD
    Desc["Project Description<br/><i>natural language</i>"] --> Mode["Mode Selection<br/><i>Interactive · YOLO · Full YOLO</i>"]
    Mode --> Spec["Spec Writer ↔ Spec Reviewer<br/><i>opus · up to 5 iterations</i>"]
    Spec --> Scaffolder["Scaffolder<br/><i>sonnet</i>"]
    Scaffolder --> Git["Git Init + Commit"]
    Git --> Arch["Architect<br/><i>opus</i>"]
    Arch --> Impl["Fixer ↔ Reviewer<br/><i>opus · per subtask</i>"]
    Impl --> Test["Test Engineer + E2E<br/><i>sonnet</i>"]
    Test --> Report["Final Report ✓"]
```
**Does not show:** Step 0-INFRA, Step 0-MCP, Step 4d (Push to Remote), Step 4e (Create Tracker Issues). After implementation, this diagram needs new nodes.

---

## Search 11: "Step 0:" / "Mode Selection" in scaffold context

### Non-forge matches (active files)

| File | Line | Content | Classification |
|------|------|---------|----------------|
| `commands/scaffold.md` | 51 | `### Step 0: Mode Selection` | **MUST UPDATE** — in new design, Step 0 becomes Step 0: Infrastructure Declaration, then Step 0-MCP, then Step 0-MCP (Mode Selection). The heading text and step number must change. |
| `docs/reference/pipelines.md` | 271 | `\| 0 \| Mode Selection \| (command) \| N/A \| Interactive / YOLO with checkpoint / Full YOLO \|` | **MUST UPDATE** — new rows for Step 0-INFRA and Step 0-MCP must be inserted; Step 0 row updated |
| `README.md` | 114 | `Mode["Mode Selection<br/><i>Interactive · YOLO · Full YOLO</i>"]` | MAYBE UPDATE — mermaid node should include new pre-steps |

---

## Search 12: "Step 4d" / "Step 4e" — existing references

### Non-forge matches (active files)

| File | Line | Content | Classification |
|------|------|---------|----------------|
| `docs/plans/2026-03-27-scaffold-infrastructure-design.md` | 83, 94, 109, 127, 128, 130 | Design spec — defines Step 4d (Push to Remote) and Step 4e (Create Tracker Issues) | DO NOT UPDATE |
| `docs/plans/2026-03-09-browser-verification-plan.md` | 350 | `Step 4e — Browser Reproduction` in fix-ticket context (different pipeline!) | DO NOT UPDATE — different command, different pipeline |

**Conclusion:** Step 4d and Step 4e do NOT yet exist in `commands/scaffold.md`. They must be **ADDED** — they are not stale references but new steps to implement. The `docs/plans/2026-03-09-browser-verification-plan.md` reference is unrelated (fix-ticket pipeline uses Step 4e for browser reproduction; scaffold Step 4e is tracker issue creation — different step, different command).

---

## Consolidated MUST UPDATE File List

| Priority | File | Lines | Action Required |
|----------|------|-------|-----------------|
| CRITICAL | `commands/scaffold.md` | 263–307 | Remove Steps 4b and 4c entirely (lines 263–307) |
| CRITICAL | `commands/scaffold.md` | 265, 272 | Remove "skip to Step 4c" references (inside Step 4b) — already covered by 4b removal |
| CRITICAL | `commands/scaffold.md` | 481–501 | Remove Step 9: Issue Tracker (Optional) entirely |
| CRITICAL | `commands/scaffold.md` | 503 | Rename `### Step 10: Final Report` → `### Step 9: Final Report` |
| CRITICAL | `commands/scaffold.md` | 443, 449 | Update jump references from "Step 10" → "Step 9" |
| CRITICAL | `commands/scaffold.md` | 544 | Update "Step 9" reference in MCP pre-flight to "Step 4e" |
| CRITICAL | `commands/scaffold.md` | 51 | Insert new steps before Step 0 (Step 0-INFRA and Step 0-MCP sections) |
| CRITICAL | `commands/scaffold.md` | — | ADD Step 4d (Push to Remote) and Step 4e (Create Tracker Issues) between Step 4 and Step 5 |
| CRITICAL | `docs/reference/pipelines.md` | 271 | Update Step 0 row to reflect Mode Selection now comes after infrastructure steps |
| CRITICAL | `docs/reference/pipelines.md` | 280 | Remove Step 9 (Issue Tracker) row |
| CRITICAL | `docs/reference/pipelines.md` | 281 | Renumber Step 10 → Step 9 (Final Report) |
| CRITICAL | `docs/reference/pipelines.md` | — | ADD rows for Step 0-INFRA, Step 0-MCP, Step 4d, Step 4e |
| MAYBE | `README.md` | 112–124 | Update Scaffold Pipeline mermaid diagram to show new infrastructure steps |
| MAYBE | `CLAUDE.md` | 63–73 | Update Scaffold Pipeline summary (currently does not mention Steps 4b/4c, but also missing new steps) |
| MAYBE | `docs/plans/roadmap.md` | 138–142 | Mark "Scaffold Auto-Finalize" v5.3.0 item as SUPERSEDED (replaced by new design) |

---

## Files With Zero Impact (confirmed clean)

The following active files have NO references to scaffold step labels being removed or added — no changes needed:

- `docs/reference/agents.md` — no scaffold step references
- `docs/architecture.md` — no scaffold step references (one "Issue Tracker" mention is config context)
- `docs/guides/` (all files) — no scaffold step references
- `agents/` (all files) — no scaffold step references
- `commands/` (all files except `scaffold.md`) — Step 9 in init.md and onboard.md is unrelated
- `tests/` (all files) — no scaffold step references
- `examples/` (all files) — no scaffold step references
- `checklists/` — no scaffold step references
- `state/` — no scaffold step references
- `core/` — no scaffold step references

---

## Summary Statistics

- **Files MUST UPDATE:** 2 (`commands/scaffold.md`, `docs/reference/pipelines.md`)
- **Files MAYBE UPDATE:** 3 (`README.md`, `CLAUDE.md`, `docs/plans/roadmap.md`)
- **Files DO NOT UPDATE:** all `docs/plans/`, `CHANGELOG.md`, `.forge/`, `.forge.bak-*/`
- **Steps to REMOVE from scaffold.md:** Step 4b (lines 263–307), Step 4c (lines 300–307), Step 9 (lines 481–501)
- **Steps to ADD to scaffold.md:** Step 0-INFRA, Step 0-MCP, Step 4d, Step 4e
- **Steps to RENUMBER in scaffold.md:** Step 10 Final Report → Step 9
- **Stale internal jump references:** "jump to Step 10" at lines 443, 449 → must become "Step 9"
- **Stale MCP pre-flight reference:** "Step 9" at line 544 → must become "Step 4e"
