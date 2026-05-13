# Agent 2 Research: Confirmation Inventory & YOLO Coverage

## Q4: Confirmation Inventory in `skills/implement-feature/SKILL.md`

Source file: `skills/implement-feature/SKILL.md`

### Complete Inventory of `[Y/n]` and `[y/N]` Prompts

| # | Line | Prompt Text | Step | YOLO Bypasses? | Appropriate? |
|---|------|-------------|------|----------------|--------------|
| 1 | 128 | `Create anyway? [y/N]` | Step 0c (Feature from Description — duplicate check) | Yes — "In YOLO mode: skip the duplicate check entirely" (line 130) | Yes — prevents accidental duplicate issue creation |
| 2 | 138 | `Create this card? [Y/n]` | Step 0c (Feature from Description — card preview confirmation) | Yes — "If confirmed (or --yolo)" (line 140) | Yes — gives user a final preview before a side-effecting MCP write |
| 3 | 213 | `Continue anyway? The unmapped criteria will not be explicitly addressed. [Y/n]` | Step 5 (Decomposition — AC coverage check) | No — YOLO causes a BLOCK instead (line 211-212) | Yes — YOLO correctly refuses to silently skip unaddressed AC |
| 4 | 231 | `Continue? [Y/n]` (inside the Decomposition Plan display block) | Step 5 (Decomposition — plan approval) | Yes — "If `--yolo` → auto-approve." (line 233) | Yes — standard plan approval gate before code generation begins |
| 5 | 347 | `Create PR? [Y/n]` | Step 9 (Display result — publish decision) | Yes — "If `--yolo` → auto-create PR." (line 347) | Yes — publish is a high-consequence action; YOLO opt-in is explicit |

### Detailed Notes Per Prompt

**Prompt 1 — Duplicate check (`[y/N]`, default NO):**
- Located at lines 123–130 (Step 0c, `--description` mode only)
- Guard: non-YOLO mode only. YOLO skips the entire duplicate search, not just the prompt.
- Default-deny is appropriate — an unexpected default-NO protects against data pollution.

**Prompt 2 — Card creation preview (`[Y/n]`, default YES):**
- Located at lines 131–140 (Step 0c, `--description` mode only)
- Guard: "If NOT --yolo mode" (line 131)
- Default-accept is appropriate — the user just provided the description; the preview is confirmatory.

**Prompt 3 — Unmapped AC continuation (`[Y/n]`, default YES):**
- Located at lines 208–212 (Step 5, AC coverage check inside decomposition)
- Unique behavior: in non-YOLO mode it's a soft warning with `[Y/n]`. In YOLO mode it becomes a hard BLOCK.
- This is the only prompt where YOLO is *stricter* than interactive mode. This is intentional — automated pipelines must not silently lose AC coverage.

**Prompt 4 — Decomposition plan approval (`[Y/n]`, default YES):**
- Located at lines 220–233 (Step 5, decomposition plan display)
- YOLO auto-approves (line 233).
- Appropriate — decomposition implies significant parallel work; human review is valuable but skippable in trusted CI contexts.

**Prompt 5 — PR creation (`[Y/n]`, default YES):**
- Located at lines 347–349 (Step 9)
- YOLO auto-creates PR (line 347).
- Appropriate — YOLO is documented as "auto-publish after successful pipeline" in fix-ticket; this matches the same contract.

---

## Q5: YOLO Coverage Gaps in `skills/implement-feature/SKILL.md`

### All `--yolo` Check Locations

| Location | Line(s) | What YOLO does |
|----------|---------|----------------|
| Step 0 (MCP pre-flight, description_mode=true) | 69–78 | Converts interactive "no tracker" fallback into a hard BLOCK (stricter) |
| Step 0c — duplicate check | 130 | Skips duplicate search entirely |
| Step 0c — card creation preview | 131, 140 | Skips card preview prompt, auto-creates |
| Step 5 — unmapped AC | 211–212 | Converts soft `[Y/n]` warning into hard BLOCK (stricter) |
| Step 5 — decomposition plan approval | 233 | Auto-approves plan, skips confirmation |
| Step 9 — PR creation | 347 | Auto-creates PR |

### Gaps: Prompts WITHOUT a `--yolo` Auto-Approve Branch

**None.** Every interactive confirmation prompt in implement-feature has either:
- A YOLO bypass (auto-approve), or
- A YOLO escalation to BLOCK (for the unmapped-AC case)

There are no confirmation prompts that silently proceed in non-YOLO mode but lack any YOLO handling.

### Potentially Problematic: YOLO checks that auto-approve things that SHOULD require confirmation

**No clear violations found.** Assessment per prompt:

- **Card preview**: Auto-approve is safe because the user provided `--description` explicitly. The content is deterministic from user input.
- **Duplicate check skip**: Potentially risky — in CI/batch contexts a duplicate could be created silently. However, `--description` mode is inherently interactive by design, making YOLO+description an unusual combination. This is an acceptable trade-off.
- **Decomposition plan**: Auto-approve is safe — the task tree is validated by the heuristics engine and architect agent before display.
- **PR creation**: Safe — PR creation is the documented purpose of `--yolo`.

### Asymmetry Note

The `--yolo` flag header comment in the argument-hint (line 6) does NOT mention the unmapped-AC BLOCK behavior. Users expecting YOLO to "skip all confirmations" may be surprised that it can block in Step 5. This is a documentation gap, not a logic bug.

---

## Q6: `fix-ticket` Confirmation Model

Source file: `skills/fix-ticket/SKILL.md`

### Confirmation Points in fix-ticket

| # | Line(s) | Prompt | Step | YOLO Bypasses? |
|---|---------|--------|------|----------------|
| 1 | 170–171 | Decomposition plan display + implicit `Continue?` | Step 4b | Yes — "If `--yolo` → auto-approve." |
| 2 | 180–182 | `Continue anyway? The unmapped criteria will not be explicitly addressed. [Y/n]` | Step 4b (AC coverage check) | Yes → BLOCK (stricter, same as implement-feature) |
| 3 | 334 | Implicit publish decision: "user decides about publishing" | Step 9 | Yes — "If `--yolo` → auto-publish." |

### Key Differences from implement-feature

| Dimension | implement-feature | fix-ticket |
|-----------|-------------------|------------|
| `--description` prompts | 2 prompts (duplicate check + card preview) | 0 — no `--description` mode |
| Decomposition plan approval | Explicit `Continue? [Y/n]` shown in formatted block | Mentioned inline: "display plan and wait for confirmation" (line 171) — no formatted prompt shown |
| Unmapped AC handling | YOLO → BLOCK, non-YOLO → `[Y/n]` | YOLO → BLOCK, non-YOLO → `[Y/n]` — **identical** |
| Publish decision | Step 9: `Create PR? [Y/n]`, YOLO auto-creates | Step 9: "user decides", YOLO auto-publishes — **equivalent** |
| YOLO documentation | In argument-hint only | Explicit paragraph in intro: "skip all user confirmations (decomposition plan approval, publish decision)" (line 16) |

### fix-ticket YOLO documentation (lines 16–17)

fix-ticket explicitly documents YOLO scope in the preamble:
> "activate YOLO mode: skip all user confirmations (decomposition plan approval, publish decision). Auto-approve decomposition. Auto-publish after successful pipeline."

This is more explicit than implement-feature, where YOLO behavior is only discoverable by reading each step.

### Pattern Comparison: Same Model, Different Verbosity

Both skills share the same confirmation model:
1. **Decomposition plan approval** — YOLO auto-approves
2. **Unmapped AC warning** — YOLO escalates to BLOCK (stricter)
3. **Publish decision** — YOLO auto-publishes

fix-ticket does NOT have the `--description` prompts (card preview, duplicate check) because it requires an existing Issue ID.

fix-ticket's decomposition plan section (lines 170–171) is less explicit about the prompt format — it references the behavior inline rather than showing the formatted `Continue? [Y/n]` block that implement-feature has. This is a minor documentation inconsistency between the two skills, not a behavioral bug.

---

## Summary

All confirmation prompts in implement-feature and fix-ticket have appropriate YOLO handling. The one notable design choice — YOLO being *stricter* (BLOCK) on unmapped AC rather than auto-approving — is intentional and correct for pipeline integrity. The main gap is that implement-feature's `--yolo` documentation (argument-hint line only) does not communicate this blocking behavior to users, while fix-ticket's inline documentation is more complete.
