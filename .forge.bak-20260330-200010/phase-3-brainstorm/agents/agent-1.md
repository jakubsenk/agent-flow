# Phase 3 Brainstorm — Agent 1: Conservative Design Proposals
# v5.6.1 UX Polish — Four Design Questions

Scope: `commands/scaffold.md` (primary), `commands/resume-ticket.md` (MCP jargon only).
`core/mcp-detection.md` is a pure contract — no user-facing strings — no changes recommended.

---

## Item 1: --infra Flag Format Change

**Question: Backward compatibility with old `ready,later` positional format, or clean break?**

### Recommendation: CLEAN BREAK — no backward compatibility shim

**Rationale:**

The old format `--infra ready,later` has two failure modes as a user-facing API:

1. Positional ambiguity — `--infra ready,later` vs `--infra later,ready` requires remembering which slot is tracker and which is SC. Users will get it wrong silently.
2. No existing adoption to protect — this is a PATCH release targeting UX polish. The flag was introduced in v5.3.0 (recent) and there are zero external tests validating it. Clean break cost is near zero.

**Against a compatibility shim:**

A dual-parser (`tracker:ready` OR `ready` positional) makes the validation regex more complex and creates an ambiguous case: `--infra ready` could mean "both ready" (shorthand, see Item 1b) or an unfinished positional form. Shimming both old and new formats multiplies this ambiguity.

**Concrete format decision:**

New canonical format: `--infra tracker:{ready|later},sc:{ready|later}`

- Key-value pairs: self-documenting, order-independent
- Separator: comma between the two pairs (consistent with existing style in other config)
- Case-insensitive for the keys `tracker` and `sc`, case-sensitive for values `ready`/`later` (matches existing validation)

**Updated validation message (scaffold.md line 37):**
```
→ Error: "Invalid --infra format. Expected: --infra tracker:ready,sc:later — use 'ready' or 'later' for each."
```

**Updated error message for --issue conflict (scaffold.md line 40):**
```
→ Error: "--issue requires tracker access. Use --infra tracker:ready,sc:{value} with --issue, or remove --issue."
```

---

## Item 1b: --infra Shorthands

**Question: Support `--infra ready` (both ready) and `--infra later` (both later)?**

### Recommendation: YES — support two shorthands, reject all other single-token forms

**Rationale:**

The dominant use cases are the two symmetric ones:
- Testing locally with nothing set up: `--infra later` (both later)
- CI/CD automation where everything is configured: `--infra ready` (both ready)

The asymmetric cases (tracker:ready,sc:later or tracker:later,sc:ready) require explicit disambiguation — there is no sensible shorthand for asymmetry.

**Parsing rule (updated Flag Validation section):**

```
If `--infra` provided:
  - If value is exactly `ready`  → expand to tracker=ready, sc=ready (shorthand)
  - If value is exactly `later`  → expand to tracker=later, sc=later (shorthand)
  - If value matches `tracker:{ready|later},sc:{ready|later}` → parse normally
  - Otherwise → Error: "Invalid --infra format. Use: --infra ready, --infra later, or --infra tracker:ready,sc:later"
```

Display after shorthand expansion:
```
Infrastructure preset: --infra {value} expanded to tracker={tracker}, SC={sc}
```

This keeps the display message informative without being condescending.

**Anti-pattern to avoid:** Do NOT silently expand `--infra ready,later` (old positional) to the new format. If someone passes the old positional form, fail visibly — the clean break from Item 1 must hold.

---

## Item 2: Canary-Write Announcement

**Question: Always announce, or ask in interactive mode? (Architecturally blocked — runs before mode selection)**

### Recommendation: ALWAYS announce — no ask, no interactive gate, brief and factual

**Rationale:**

The architecture constraint is real and non-negotiable: Step 0-MCP runs before Step 0 (mode selection). The mode is not known at announcement time. Implementing an interactive gate here would require either:
(a) Moving Step 0-MCP after mode selection — a structural change, out of scope for PATCH
(b) Delaying the canary write to after mode selection — breaks the sequential dependency (mode selection needs to know if tracker is working)

Neither is appropriate for v5.6.1.

**What "always announce" means in practice:**

The announcement must be brief and non-alarming. The user has already told us their tracker is "ready" — they expect the system to test it. A factual one-liner is sufficient:

```
Checking write access to your {tracker_type} tracker — creating and deleting a temporary test item.
```

This is inserted in `scaffold.md` Step 0-MCP, between the `check_write = true` line (current line 143) and the result-handling block (current line 165). Specifically, add a bullet point to the `check_write = true` call block:

```
- `check_write` = `true` (for tracker only — SC does not need write check)
- Before calling core/mcp-detection.md with check_write: true: Display:
  `Checking write access to your {tracker_type} tracker — creating and deleting a temporary test item.`
```

**What NOT to add:**
- No "Do you want to proceed? [Y/n]" — this is a standard connectivity check, not a destructive action
- No explanation of what a "canary item" is — internal jargon, not user language
- No "this may take a few seconds" — patronizing filler

**Scope constraint:** The announcement goes in `scaffold.md` only. `core/mcp-detection.md` must not be modified (pure contract, as specified in research constraints).

---

## Item 3: MCP Jargon Replacement

**Question: Fix only scaffold.md + resume-ticket.md, or also the 13 other command files?**

### Recommendation: FIX ONLY THE TWO SPECIFIED FILES — no scope creep

**Rationale:**

This is a PATCH release. The 13 other command files are out of scope. Touching them risks:
1. Unintended behavioral changes from copy-edit errors
2. A larger diff that needs more review
3. Drift from the stated scope of v5.6.1

The research confirmed that the two target files contain all the instances of the exact pattern `"MCP server for {Type} is not available"` that appear in user-facing output. Other commands may use similar phrasing, but fixing them is a separate task for a future MINOR or a targeted PATCH.

**Replacement mapping for scaffold.md:**

| Current (user-facing) | Replacement |
|---|---|
| `MCP server for {type} not detected in current session.` (line 146) | `Cannot connect to your {type} tracker — connection not available in this session.` |
| `MCP server for "{tracker_type}" is not available.` (line 159, inside block comment Detail) | `Cannot connect to your {tracker_type} tracker.` |
| `MCP for {type} not available — downgrading to "later".` (line 163) | `Cannot connect to your {type} tracker — downgrading to "not now".` |
| `MCP server for {Type} is not available. Run /ceos-agents:check-setup...` (line 751) | `Cannot connect to your {Type} tracker. Run /ceos-agents:check-setup for diagnostics or /ceos-agents:init to configure.` |

**Replacement for resume-ticket.md:**

| Current | Replacement |
|---|---|
| `MCP server for {Type} is not available. Run /ceos-agents:check-setup...` (line 72) | `Cannot connect to your {Type} tracker. Run /ceos-agents:check-setup for diagnostics or /ceos-agents:init to configure.` |

**Consistency rule:** The phrase "Cannot connect to your {type} tracker" is the canonical form. All instances in both files must use this exact wording — do not introduce variations like "Unable to reach" or "Connection failed".

**Internal jargon in non-user-facing contexts (do NOT change):**

- `mcp_available: false` — this is an internal variable name in code-like blocks, not a display string
- `check_write = true` — internal flag, not displayed to users
- Comments like `<!-- MCP detection logic: see core/mcp-detection.md -->` — developer documentation, not user-facing
- `core/mcp-detection.md` error fields (`error: "No MCP tool matching prefix..."`) — these are contract output fields returned to callers, not displayed directly

---

## Item 4: Resume --infra Override

**Question: When --infra overrides stale state, should it re-run Step 0-MCP?**

### Recommendation: YES — re-run Step 0-MCP when --infra overrides stale state

**Rationale:**

If the user is passing `--infra` on a resume invocation, they are almost certainly correcting an infrastructure state that was wrong or stale — they set up their tracker MCP since the first run, or they changed their mind about which services are "ready". In both cases, the previously stored MCP verification result is invalid. Re-running Step 0-MCP is the only safe choice.

Not re-running Step 0-MCP after an override would leave a logical contradiction: in-memory variables say `tracker_effective_status = "ready"` but the MCP was never verified in this session.

**How to implement the override clause in scaffold.md line 126:**

Replace:
```
**On resume:** If `state.json` exists with `infrastructure` populated, restore in-memory variables from state instead of re-asking. Display: `Resumed infrastructure state from previous run.`
```

With:
```
**On resume:** If `state.json` exists with `infrastructure` populated:
- If `--infra` flag was also provided (infra_preset is set):
  - Parse `--infra` value using the same rules as the initial run (shorthand expansion + validation)
  - Override `tracker_effective_status` and `sc_effective_status` with the new preset values
  - For any service newly set to `"ready"`: collect the required details (tracker type/URL/project or SC remote/branch) interactively — these cannot be inferred from the old state if the user changed services
  - For any service that remains unchanged: restore detail values from state (no need to re-ask)
  - Display: `--infra override applied: tracker={tracker}, SC={sc}. Previous state overridden.`
  - Proceed to Step 0-MCP (re-verify the overridden services — previous MCP check is stale)
- If `--infra` flag was NOT provided:
  - Restore all in-memory variables from state (current behavior)
  - Display: `Resumed infrastructure state from previous run.`
  - Skip Step 0-MCP (MCP was already verified in the previous run — state.json reflects post-MCP state due to the state update at Step 0-MCP completion)
```

**Scope clarification:** This change is confined to `scaffold.md` Step 0-INFRA "On resume" block. No changes to `resume-ticket.md` — as confirmed by research, resume-ticket.md does not handle the scaffold pipeline. The scaffold self-resume is entirely within scaffold.md.

**Edge case — --infra later on resume:** If the user resumes with `--infra later` (both later), this means they want to proceed without any external services. Override correctly sets both statuses to "later", skips Step 0-MCP entirely (nothing to verify), and continues from the last checkpoint. This is valid and requires no special handling beyond the rule above.

---

## Summary of Changes Per File

| File | Lines Affected | Change Type |
|------|---------------|-------------|
| `commands/scaffold.md` | 22 | Update --infra flag format description |
| `commands/scaffold.md` | 36-37 | Update format validation + error message (new format + shorthands) |
| `commands/scaffold.md` | 39-40 | Update --issue conflict error message (new format reference) |
| `commands/scaffold.md` | 60-66 | Update Step 0-INFRA preset handling (new format parsing) |
| `commands/scaffold.md` | 143 (add) | ADD canary-write announcement before check_write delegation |
| `commands/scaffold.md` | 146 | Replace MCP jargon |
| `commands/scaffold.md` | 158-163 | Replace MCP jargon in block comment Detail + auto-downgrade display |
| `commands/scaffold.md` | 126 | Extend On resume block with --infra override clause |
| `commands/scaffold.md` | 751 | Replace MCP jargon in standard error message |
| `commands/resume-ticket.md` | 72 | Replace MCP jargon in standard error message |

**Total: 10 edit locations across 2 files.**
`core/mcp-detection.md` — NO CHANGES.

---

## Risk Assessment

| Change | Backward compat risk | Behavioral change |
|--------|---------------------|-------------------|
| --infra format (clean break) | LOW — flag is recent, no external tests | Yes — old positional format now errors |
| --infra shorthands | NONE — additive | Yes — new valid inputs |
| Canary announcement | NONE — display-only | No — same operations, more transparency |
| MCP jargon replacement | NONE — display-only | No — same logic |
| Resume --infra override | NONE — new opt-in path | Yes — users who pass --infra on resume get different behavior (intended) |

No MAJOR version bump required — no Automation Config contract changes, no agent output contract changes. All changes are PATCH-level.
