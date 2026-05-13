# Agent 4 Research: Design Document Validation and Edge Cases

**Research Angle:** Area 4+5 — Design Document Validation and Edge Cases
**Sources read:** `commands/scaffold.md`, `docs/plans/2026-03-27-scaffold-infrastructure-design.md`, `commands/init.md`

---

## Design Validation

### Q18: Ambiguities or contradictions between the design doc and current scaffold.md

**Finding: Step 9 conflict (partial — implicit)**

The design document lists "Step 9 (Issue Tracker Optional) → REMOVED — replaced by Step 4e". However, `scaffold.md` still contains Step 9 in full ("Issue Tracker (Optional)"). The design document is a PROPOSED design, so this is not a contradiction per se — but it is important to note that the design removal of Step 9 is incomplete: Step 9 also handles the interactive prompt ("Create cards in issue tracker for implemented features? [Y/n]") and Full YOLO skip logic. Step 4e in the design does not replicate this prompt — it only runs if tracker was declared "ready" at Step 0-INFRA. This is intentional and consistent, but an implementor must explicitly remove Step 9 when applying the design.

**Finding: Step 4b/4c replacement is non-ambiguous but incompletely specified for YOLO mode**

The design says "Step 4b (Tracker Configuration) → replaced by Step 0-INFRA + Step 4 auto-fill". In the current `scaffold.md`, Step 4b explicitly has "Full YOLO → skip this step (cannot guess tracker URLs in unattended mode)". The design says "In Full YOLO mode, Step 0-INFRA question is still asked (it cannot be skipped)". This is a semantic shift: Full YOLO users who previously skipped Step 4b entirely now face an interactive infrastructure question at Step 0-INFRA. The design document handles this consciously but the distinction is not highlighted as a behavior change — it could surprise Full YOLO users.

**Finding: Ambiguity in "auto-fill" under Modified Step 4**

The design's "Modified Step 4: Git Init + Auto-Config" says: "for 'ready' services, fill values automatically from Step 0-MCP data (no TODO markers)". But `init.md` Step 6 generates `.mcp.json` from templates in `examples/mcp-configs/{type}.json`, asking the user for tokens interactively. The design does not specify whether the inline `/init` invocation in Step 0-MCP is the same multi-step wizard or a streamlined subset. This is ambiguous — see Q20 for detail.

**Finding: `.mcp.json` generation in Modified Step 4 vs. init.md's structure**

The design says "Generate `.mcp.json` for the new project directory — derive from detected MCP servers in session, tokens: use `<YOUR_*>` placeholders". The `init.md` wizard asks for actual tokens interactively (Step 4), then generates both `.mcp.json` (with real tokens) and `.mcp.json.example` (with placeholders). The design's Step 4 only generates `.mcp.json.example` with placeholders (tokens never copied). This means the scaffold's `.mcp.json` output always has placeholder tokens — the new project still requires manual token fill before use. The design is internally consistent on this point but it differs from what `init.md` produces in a standalone run.

**Finding: "Spec Phase Questions" section is not contradicted but is orphaned**

The design includes a "Spec Phase Questions" section stating: "When using `--issue` flag, spec-reviewer questions are handled in the chat, not posted to the tracker." Current `scaffold.md` has no tracker-comment mechanism for `--issue` at all — spec-reviewer is just run via Task tool. This section of the design resolves a question that was never an issue in `scaffold.md`, suggesting it was preemptively written. No contradiction, but it's dead text relative to the current codebase.

---

### Q19: Where exactly does Step 0-INFRA insert — before or after State Detection?

**Finding: The design says "before Mode Selection" but is silent on State Detection.**

The design document states: "Replaces the current Step 4b and Step 4c. Moves to the **very beginning** of scaffold, before Mode Selection."

The current `scaffold.md` flow order is:
1. Flag Parsing
2. Flag Validation
3. **State Detection** (checks target directory — empty, existing, git repo with changes)
4. **Step 0 (Mode Selection)**
5. Step 0b (Brainstorming)
6. Step 1+ ...

The design says Step 0-INFRA goes "before Mode Selection" — but does not mention State Detection. "Very beginning" could mean before or after State Detection. There is genuine ambiguity here.

**Recommended interpretation:** Step 0-INFRA should insert **after State Detection** and **before Step 0 (Mode Selection)**.

Rationale:
- State Detection determines whether a full scaffold is even appropriate (if directory has existing project, scaffold may be declined). Asking about infrastructure before knowing if we're even proceeding is premature.
- State Detection is a guard gate — it can STOP the command entirely if the user does not confirm. There is no value in collecting infrastructure credentials before this gate.
- The design's "Impact on Existing Steps" table shows: "Step 0 (Mode Selection) → Moves after Step 0-INFRA and Step 0-MCP". This implies only Mode Selection shifts, not the entire pre-Step 0 area.
- The `--no-implement` flow exits from Step 0 before reaching Step 0-INFRA in the current Step 0 position. The design says "Step 0-INFRA is added before L1 [the legacy flow]" — which is consistent with inserting after State Detection (State Detection exits early for --no-implement's context) but does mean --no-implement users also see Step 0-INFRA. (See Q23 for --no-implement interaction.)

**Conclusion:** Insertion point = after State Detection, after Flag Validation, before Step 0 (Mode Selection).

---

### Q20: How should "run `/init` inline" in Step 0-MCP work technically given init.md's structure?

**Finding: `init.md` is a 9-step multi-part wizard — it cannot be trivially embedded inline.**

`init.md` requires:
- **Step 1:** Read Automation Config from CLAUDE.md (which does NOT yet exist during scaffold)
- **Step 2:** Detect existing `.mcp.json` in CWD (which is the scaffold target, not the new project)
- **Step 3:** Determine needed MCP servers (from tracker type already known at Step 0-MCP)
- **Step 4:** Collect tokens interactively
- **Step 5:** Platform-specific handling (binary paths for Gitea/Redmine)
- **Step 6:** Generate `.mcp.json` into CWD
- **Step 7:** Validate connectivity
- **Step 8:** Permission setup for `.claude/settings.json`
- **Step 9:** Closing message

Running `/init` at Step 0-MCP has a fundamental problem: **CLAUDE.md does not exist yet** (it is generated in Step 3: Scaffold Skeleton). `init.md` Step 1 requires CLAUDE.md with Automation Config. This means a literal "run /init inline" would fail at Step 1.

**What "run `/init` inline" must actually mean in practice:**

The scaffold command cannot dispatch the full `/init` wizard. Instead, it must replicate the relevant subset of `init.md` logic inline:
1. The tracker type is already known from Step 0-INFRA (user declared it)
2. Use the tracker type to determine the MCP package (same table as `init.md` Step 3)
3. Skip Steps 1-2 (no CLAUDE.md yet, no existing .mcp.json in new project dir)
4. Execute Steps 3-7 of `init.md` directly (determine server, collect tokens, platform handling, generate `.mcp.json` into session CWD or temp location, verify connectivity)
5. Skip `init.md` Step 8 (permission setup) — that is a developer environment concern, not scaffold's job
6. The MCP tools detected in the current session are used for verification — the new project's `.mcp.json` is generated as `.mcp.json.example` only (per design's Modified Step 4)

**Alternative interpretation:** "Run `/init` inline" means: invoke `/ceos-agents:init` as a skill/command invocation (via the Claude Code command dispatch mechanism) but only for the MCP server detection portion. This would require `/init` to support a flag like `--mcp-only` or `--service {tracker|sc}` to skip the CLAUDE.md dependency. Currently no such flag exists.

**Conclusion:** The design's "run `/init` inline" is underspecified. The implementation must either (a) replicate the relevant `init.md` subset inline within scaffold's Step 0-MCP, or (b) extend `/init` with a `--mcp-only` mode that skips the CLAUDE.md requirement. Option (a) is simpler; option (b) avoids code duplication.

---

## Edge Cases

### Q21: How does `--issue` flag interact with Step 0-INFRA? Should auto-detect apply?

**Finding: `--issue` implies tracker readiness — but Step 0-INFRA still prompts.**

The `--issue` flag causes scaffold to read the issue description from the tracker via MCP (Step 1). If `--issue` is provided, the user demonstrably has:
- A tracker project (they have an issue ID)
- MCP connectivity (otherwise reading the issue would fail)

The design document does not address this case. Step 0-INFRA asks "Issue tracker: (a) ready / (b) later" — but if `--issue` is provided, asking this question is redundant and potentially confusing. The user has already implicitly answered "ready".

**Recommended behavior:** When `--issue` is provided:
- Auto-set tracker = "ready" (skip the tracker question in Step 0-INFRA)
- Display: "Detected issue tracker from --issue flag: auto-configuring."
- Proceed directly to Step 0-MCP tracker verification
- Still ask the SC question (SC readiness cannot be inferred from `--issue`)

This is consistent with the Flag Parsing design principle of reducing friction when information is already provided.

**Ambiguity in the design:** The design's "Impact on Existing Steps" table says "Step 1 (Specification): No change — `--issue` input source works as before". This suggests `--issue` behavior at Step 1 is preserved, but the new Step 0-MCP would verify tracker MCP before Step 1 even runs. If the user skips Step 0-MCP (declares "later" despite providing `--issue`), Step 1 would fail when trying to read the issue. The design needs a consistency rule: `--issue` must force tracker = "ready".

---

### Q22: If tracker is "ready" but MCP fails — does "downgrade to later" need explicit handling?

**Finding: The design mentions "downgrade" but leaves implementation details unspecified.**

The design says: "If missing [MCP server] → offer: 'Run `/init` now? [Y/n]' — N → downgrade to 'later' (revert to option b for this service)". The connectivity FAIL path says: "'Connectivity failed. Fix now / Continue without {service} / Abort'" but does not explicitly say "Continue without" = downgrade to "later".

**What explicit handling is needed:**

1. **State flag:** A variable like `tracker_status = "ready" | "later" | "downgraded"` must track the effective state after Step 0-MCP, separate from what the user declared at Step 0-INFRA.

2. **Downstream cascade:** If tracker is downgraded to "later":
   - Step 4 auto-fill must use TODO markers for tracker keys (same as "later" path)
   - Step 4e must not run (no tracker issues created)
   - Step 9 (if retained during transition period) must be skipped
   - Step 10 report must show "Tracker: ⏳ Not configured" (downgraded path)

3. **`--issue` flag conflict:** If user provided `--issue` and tracker MCP then fails, the downgrade means Step 1 cannot read the issue. The command must abort or ask: "Cannot read issue — MCP unavailable. Continue without --issue (provide description manually)? [Y/n]"

4. **SC downgrade:** Same cascade applies to SC — downgraded SC means Step 4d (push) does not run, auto-fill uses TODO for Remote.

**Conclusion:** "Downgrade to later" is not self-handling. It requires an explicit effective-status variable and must propagate to Steps 4, 4d, 4e, and 10. The design document assumes this but does not spell it out. This is a gap that the implementation spec must address.

---

### Q23: How should Step 4e handle --no-implement flow (spec/epics don't exist)?

**Finding: The design explicitly addresses --no-implement but with a residual ambiguity.**

The design states: "The `--no-implement` flow (L1-L6) remains unchanged. Step 0-INFRA is added before L1 but the legacy flow does not create tracker issues (no spec/epics to create from)."

This means Step 4e simply does not run in --no-implement mode. The `--no-implement` legacy flow exits via `EXIT pipeline` at Step 0 before reaching any Step 4x. If Step 0-INFRA is inserted before Mode Selection (which is the first thing in Step 0), then the `--no-implement` exit happens after Step 0-INFRA and Step 0-MCP run.

**Practical implications:**

1. **Step 0-INFRA still runs for --no-implement.** User will be asked "Issue tracker ready? / SC ready?" even though --no-implement generates no spec/epics. If tracker is declared "ready", Step 4e would have no spec/epics/* to iterate over. This is handled by the design: "legacy flow does not create tracker issues (no spec/epics to create from)".

2. **Step 4e guard:** Step 4e must check: if `no_implement = true` → skip entirely. If spec/epics/ does not exist or is empty → skip. This guard is not written into the design's Step 4e definition.

3. **SC interaction is useful for --no-implement:** Even without spec/epics, Step 4d (push to remote) is valuable for the legacy flow — the scaffolded skeleton can still be pushed. The design does not specify whether Step 4d runs for --no-implement. Given the design only says "tracker issues not created", SC push should be inferred as applicable.

**Recommendation:** Step 4e should explicitly guard: `if no_implement OR spec/epics/ does not exist → skip`. Step 4d (push to remote if SC ready) should run for both --no-implement and full flows.

---

### Q24: Does --brainstorm flag interact with Step 0-INFRA?

**Finding: No interaction — but ordering matters.**

`--brainstorm` sets `brainstorm = true` and triggers Step 0b (Brainstorming Phase) which runs after Mode Selection. Step 0b only runs in Interactive mode (YOLO modes do not brainstorm). Step 0-INFRA runs before Mode Selection.

There is no direct semantic interaction between `--brainstorm` and Step 0-INFRA:
- Step 0-INFRA asks about tracker/SC infrastructure — this is independent of whether the project description is being refined through brainstorming.
- Step 0b enriches the project description BEFORE it is passed to spec-writer (Step 1). The infrastructure state determined at Step 0-INFRA is not affected by brainstorming output.

**One indirect ordering consideration:** If the user provides `--brainstorm` without a project description, Step 0-INFRA will be asked before the project description is known. This is fine because infrastructure questions are independent of project content. However, the user experience may feel odd: "Tell me about your infrastructure" before "Tell me about your project." The design does not address this UX sequence issue.

**Flag validation interaction:** The current `scaffold.md` Flag Validation checks `--brainstorm AND --spec → Error`. No new interaction with Step 0-INFRA is needed since --brainstorm does not affect infrastructure setup.

**Conclusion:** `--brainstorm` has no functional interaction with Step 0-INFRA. The only consideration is UX ordering: infrastructure questions precede the brainstorming phase, which may feel counterintuitive but is logically sound (infrastructure is a prerequisite decision, as the design states for Full YOLO).

---

## Summary of Key Gaps in the Design Document

| # | Gap | Severity |
|---|-----|----------|
| G1 | "Run `/init` inline" requires CLAUDE.md which doesn't exist yet — underspecified | High |
| G2 | `--issue` flag implies tracker=ready — design doesn't specify auto-detect | Medium |
| G3 | "Downgrade to later" requires explicit effective-status variable and cascade — not spelled out | Medium |
| G4 | Step 4e has no guard for --no-implement or missing spec/epics/ | Low |
| G5 | Step 0-INFRA insertion point relative to State Detection is ambiguous ("very beginning" vs "before Mode Selection") | Medium |
| G6 | Full YOLO behavior shift: Step 4b was skipped, Step 0-INFRA is not skippable — implicit breaking UX change not flagged | Low |
| G7 | "Spec Phase Questions" section in design resolves a non-issue (scaffold.md has no tracker-comment mechanism) | Cosmetic |
