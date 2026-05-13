# Research Questions — Agent 2: Plugin Version Tracking and State Management

Focus area: How to embed plugin version into state.json and expose it as a queryable core contract.

---

### Q1: Where should `plugin_version` live in state.json, and does the schema_version field set a precedent?

**Target files:**
- `state/schema.md` (top-level field definitions table, lines 139–157)
- `core/state-manager.md` (Write Process, step 2 — schema template initialization)

**What to look for:**
- How `schema_version` is defined (always `"1.0"`, purpose: "enables future schema evolution") and whether a parallel `plugin_version` field would follow the same top-level pattern
- Whether Write Process step 2 references the schema template by value or by file reference — i.e., how a new top-level field would be stamped at initialization time
- Whether any existing top-level field is populated from an external source (plugin.json, CLAUDE.md) at init time, establishing a precedent for reading `plugin.json` during state initialization

**Why it matters:**
Adding `plugin_version` requires a decision on whether it belongs at the top level alongside `schema_version` (clean precedent exists) or in `config` (already holds profile/flags/retry_limits). Wrong placement now means a MAJOR version bump later to move it.

---

### Q2: Does resume-ticket's state-file detection path already expose enough context for a version mismatch warning?

**Target files:**
- `skills/resume-ticket/SKILL.md` (State File Detection — Priority 0, steps 1–5, lines 16–32)
- `core/state-manager.md` (Resume Process, steps 1–2)

**What to look for:**
- Exactly which fields are read from state.json at resume time (`triage.acceptance_criteria`, `triage.complexity`, `fixer_reviewer.iterations`, `config.profile`, `config.flags`) — whether a `plugin_version` field would be naturally read at the same step, or whether a new explicit check would need to be inserted before step 4 ("Pass resume_point and restored context")
- Whether the Resume Output contract (`resume_point`, `resume_context`, `detection_method`) has a defined extension point, or whether version information would need to widen the `resume_context` object
- Whether the heuristic fallback path (no state.json) would simply skip version comparison, making the check state-file-only by design

**Why it matters:**
A version mismatch between the plugin version that started the run and the currently installed version could indicate a schema incompatibility. Resume-ticket is the natural enforcement point, but only if inserting a version check there doesn't require restructuring the existing detection logic.

---

### Q3: What is the correct core contract structure for a new `version-guard` contract, and where does it fit among existing contracts?

**Target files:**
- `core/config-reader.md` (full file — Purpose / Input Contract / Process / Output Contract / Failure Handling)
- `core/block-handler.md` (full file — same five-section structure)
- `core/mcp-preflight.md` (full file — same five-section structure, note delegation pattern via `core/mcp-detection.md`)

**What to look for:**
- The exact five-section template used by all three contracts: Purpose, Input Contract, Process (numbered steps), Output Contract, Failure Handling — confirm this is the canonical structure across all 13 contracts
- How `core/mcp-preflight.md` delegates to `core/mcp-detection.md` via `Follow core/X.md` instruction — whether a `version-guard` contract should similarly delegate to `state-manager.md` for the read step rather than duplicating state read logic
- How failure modes are expressed (BLOCK with formatted comment vs. log warning and continue) — whether a version mismatch should be a hard block or a soft warning, based on patterns in other contracts

**Why it matters:**
The new `version-guard` contract must match the established structure exactly to remain consistent with the 13 existing core contracts. The delegation pattern from `mcp-preflight` is a template for keeping the contract thin while reusing `state-manager` for the actual state read.

---

### Q4: How is plugin.json's `version` field currently consumed (or not consumed) by skills and agents, and are there gaps where version is not propagated?

**Target files:**
- `.claude-plugin/plugin.json` (version field — currently `"6.6.0"`)
- `skills/resume-ticket/SKILL.md` (full steps — check if plugin.json is ever referenced)
- `core/state-manager.md` (Write Process step 2 — schema template initialization)

**What to look for:**
- Whether any current skill or core contract reads `.claude-plugin/plugin.json` at all — if none do, `plugin_version` stamping at state initialization would be the first such reference, and a clear path for how to read the file must be defined in the contract
- Whether the `version` field in `plugin.json` uses semver consistently (`"6.6.0"`) — confirming the format that `plugin_version` in state.json should store and that version comparison logic (e.g., major-only mismatch vs. full semver mismatch) can be specified unambiguously
- Whether any existing state.json field is populated from a file outside the project's CLAUDE.md (confirming or denying precedent for reading `plugin.json` during pipeline initialization)

**Why it matters:**
If no skill currently reads `plugin.json`, the version-guard contract must define the read step explicitly. Knowing the exact format (`"6.6.0"` semver string) determines whether comparison logic needs a semver parser or can use simple string equality / major-version integer comparison.
