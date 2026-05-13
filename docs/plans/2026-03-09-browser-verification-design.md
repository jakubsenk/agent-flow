# Browser-Based Bug Reproduction & Verification — Design Document

**Status:** APPROVED
**Date:** 2026-03-09
**Version:** v1.0
**Roadmap status:** PLANNED — implementation in `2026-03-09-browser-verification-plan.md`

---

## Research Summary (R1–R6)

### R1 — Playwright MCP Capabilities
**Confidence: HIGH**

- 33 tools total (22 always-on + 11 opt-in): `browser_navigate`, `browser_click`, `browser_fill_form`, `browser_snapshot` (accessibility tree), `browser_take_screenshot`, `browser_console_messages`, `browser_network_requests`, `browser_evaluate` (JS eval), `browser_run_code`
- Accessibility tree (`browser_snapshot`) is the primary read mechanism — preferred over screenshots for token efficiency
- JS eval IS available via `browser_evaluate` and `browser_run_code`
- Opt-in capability groups via `--caps`: vision, pdf, testing, tracing
- Limitations: no cross-request memory, `file://` URLs blocked by default

**Open unknowns:** Playwright CLI (`@playwright/cli`) may supersede MCP for coding agents.

---

### R2 — AI Bug Reproduction Patterns
**Confidence: MEDIUM**

- Reproduce-first is the emerging standard — SWE-agent and OpenHands use "fail-to-pass" methodology. F->P success rates reaching ~71.7%
- Devin has the most complete browser setup — sandboxed Chrome, processes video recordings
- OpenHands browser tooling is unreliable — frequent timeouts
- CLI/API reproduction works well; browser/UI reproduction is still fragile across all tools

**Open unknowns:** What % of bugs require browser vs. unit-test reproduction?

---

### R3 — LLM-Driven Exploratory Testing
**Confidence: MEDIUM-LOW**

- LLM agents are bad at exploration — WebArena: best GPT-4 agent 14.41% vs 78.24% human. Gemini 2.5 Pro reaches only 37.8%
- Agents are "more deterministic and focused" than humans — the opposite of what exploratory testing needs
- Failure modes: infinite loops, hallucinated tool arguments, non-deterministic results
- No production tool exists for "explore adjacent flows after a fix" — this would be novel
- Stopping criteria for exploration: unsolved problem

**Open unknowns:** How to handle auth/session state during exploration?

---

### R4 — Evidence Format for Fixer Context
**Confidence: HIGH**

- Accessibility tree snapshots are the clear winner — 93% less context than DOM dumps
- Structured JSON beats raw text. Optimal evidence bundle:
  ```json
  {
    "page_url": "...",
    "accessibility_snapshot": "...",
    "console_errors": [{"level": "error", "message": "...", "source": "..."}],
    "network_failures": [{"url": "...", "status": 500, "method": "POST"}],
    "screenshot_path": "(optional, only for visual bugs)"
  }
  ```
- More data is actively harmful — irrelevant context causes LLM to latch on to insignificant details
- Tiered delivery: structured text first, screenshot only if bug is visual

---

### R5 — Claude Code Integration Constraints
**Confidence: HIGH** ⚠️ HARD BLOCKER

- **Sub-agents CANNOT access MCP tools** — Known bug (#13605, #21560). Task tool sub-agents don't receive MCP tools. This blocks the planned MCP architecture
- MCP burns ~114K tokens per session. Screenshots trigger "context limit reached" at 25% usage. Per-call cap: 25K tokens
- **Playwright CLI is recommended over MCP** for coding agents — 4x token reduction (114K → 27K)
- Dev server lifecycle is manageable via `run_in_background` Bash tool
- MCP timeouts are unreliable — 16+ hour hangs documented

**Open unknowns:** Timeline for sub-agent MCP fix (marked high-priority, no ETA).

---

### R6 — Visual Testing Tools
**Confidence: MEDIUM-HIGH**

- AI-powered visual diffing is the standard (2026) — Applitools: ~0.001% false positive. Pixel comparison is outdated
- "Visual completeness" is partially solved — structural regressions detectable, subjective quality still needs human review or baselines
- Baseline management is the operational bottleneck — without baselines, visual testing degrades to "can the page render at all?"
- LLM as zero-shot visual checker (screenshot + AC text → verdict) could eliminate baseline need, but unproven at scale
- Playwright's built-in `toHaveScreenshot()` — free, pixel-level, higher false positive rate

---

## Architecture Decision

### Constraint-Driven Choice

The sub-agent MCP access bug (#13605) is a **hard blocker** for native Playwright MCP integration. Three viable approaches:

| Option | Description | Decision |
|--------|-------------|----------|
| **A: Hybrid Script** | Agent generates Playwright script → Bash executes → reads results from disk | ✅ **SELECTED** |
| **B: MCP in Main Thread** | Run Playwright MCP from main conversation | ❌ Breaks dispatch model |
| **C: Playwright CLI** | `@playwright/cli` — saves snapshots to disk | Future migration path when CLI matures |
| **D: Wait for MCP fix** | Native MCP when Anthropic resolves bug | Too uncertain |

**Decision: Hybrid Script approach for v1.** Agent generates a focused Playwright script, executes via Bash tool, reads structured results (JSON + optional screenshot). Migration to Playwright CLI (Option C) when it matures.

---

## Two New Agents

### Agent: `reproducer`
- **Model:** sonnet
- **Pipeline position:** After code-analyst, before fixer
- **Condition:** `Browser Verification` config exists AND bug is UI-related (inferred from triage tags or keywords)
- **Input:** Bug description + triage output (incl. reproduction_steps) + code-analyst impact report
- **Output:** Evidence bundle (structured JSON) + optional screenshot → passed to fixer as additional context

### Agent: `browser-verifier`
- **Model:** sonnet
- **Pipeline position:** After e2e-test-engineer, before acceptance-gate
- **Condition:** Same config gate as reproducer
- **Input:** Reproduction script from reproducer + fixer diff + AC list
- **Output:** Verification verdict (PASS/FAIL) + evidence bundle for PR comment

---

## Pipeline Position

```
Triage → Code-analyst → [REPRODUCER] → Fixer ↔ Reviewer
  → Test-engineer → [E2E-test-engineer] → [BROWSER-VERIFIER]
  → Acceptance-gate → Publisher
```

Both phases are **optional** and **independently configurable** via `On events: reproduce, verify`.

---

## Reproduction Phase Design

### Step 1 — Parse Reproduction Steps
Triage-analyst extended to output `reproduction_steps` field (ordered list of browser actions) when bug is UI-related.

### Step 2 — Script Generation
Reproducer agent generates a focused Playwright script:
```typescript
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('http://localhost:3000/login');
  await page.fill('[name="email"]', 'test@example.com');
  await page.click('button[type="submit"]');
  // Capture evidence at failure point
  const snapshot = await page.accessibility.snapshot();
  const consoleErrors = []; // collected via page.on('console')
  // ... save to .claude/reproduction-result.json
})();
```

### Step 3 — Execution
Bash tool runs the script. Results written to `.claude/reproduction-result.json`.

### Step 4 — Evidence Bundle
Agent reads result file and structures it for fixer context.

### Edge Case Handling

| Scenario | Behavior |
|----------|----------|
| No running app, no Start command | Skip, log warning, pipeline continues |
| No STR in bug report | Infer from title + affected files. If can't determine: skip |
| Flaky reproduction | Run 2x. "Could not reproduce" → continue without evidence |
| Evidence too large | Truncate to top 5 console errors, top 3 failed requests, accessibility snapshot of failure element only |

---

## Verification Phase Design

The `browser-verifier` agent runs in two sub-phases:

### Sub-phase A — Scoped Verification (Required)

Always runs when `Browser Verification` config exists. Deterministic, bounded, produces a binding PASS/FAIL verdict:

1. **Replay reproduction steps** — same script as reproducer, expect success (bug gone)
2. **Adjacent page check** — read fixer diff, navigate to 2–3 directly affected routes, verify no console errors
3. **Visual sanity check** — LLM examines screenshot against AC text (zero-shot, no baseline)

**Verdict Levels (binding):**

| Verdict | Meaning | Blocks? |
|---------|---------|---------|
| VERIFIED | Bug gone, adjacent pages clean | No |
| PARTIAL | Bug gone but adjacent issue found | No — reported to PR |
| FAILED | Bug still present | Yes — returns to fixer |
| SKIPPED | App not running, config missing, timeout | No |

### Sub-phase B — Guided Exploration (Optional)

Opt-in via `Exploration: enabled` in config. Runs only if sub-phase A verdict is VERIFIED or PARTIAL. Produces **soft evidence only** — never blocks, always informational.

**How it works:**
- Agent receives an "exploration brief" generated from: AC list + fixer diff + affected routes
- Brief defines: which areas to explore, what anomalies to look for, what to skip
- Agent navigates read-only (no form submissions, no destructive actions)
- Hard limits: max `Exploration max clicks` clicks, max `Timeout` seconds
- Output: annotated list of observations ("found broken layout on /settings", "console warning on /profile") — attached to PR comment

**Why it can't block:**
- Non-deterministic by design — two runs may find different things
- Agent may hallucinate observations or miss real issues
- False positives would create noise and erode trust in the pipeline
- Treat it like a junior tester's notes: useful signal, not ground truth

**Exploration brief format:**
```
Explore these areas based on the fix:
- Routes changed in diff: /login, /auth/callback
- AC mentions: "user sees success message after login"
- Look for: broken layouts, console errors, missing UI elements
- Skip: any forms with submit buttons, /admin routes, external links
- Stop after: {Exploration max clicks} clicks or {Timeout}s
```

### Combined Stopping Criteria

| Limit | Sub-phase A | Sub-phase B |
|-------|------------|------------|
| Max pages | 5 (hardcoded) | `Max pages` from config |
| Max clicks | N/A (scripted) | `Exploration max clicks` from config |
| Timeout | `Timeout` from config | `Timeout` from config |
| Form submission | Allowed (reproducing) | Never allowed |
| Blocks pipeline | Yes (FAILED verdict) | Never |

---

## Config Contract

New **optional** section (MINOR version bump — backward compatible):

```markdown
## Browser Verification

| Key | Value |
|-----|-------|
| Base URL | http://localhost:3000 |
| Start command | npm run dev |
| On events | reproduce, verify |
| Timeout | 60 |
| Max pages | 5 |
| Screenshot storage | .claude/screenshots |
| Exploration | enabled |
| Exploration max clicks | 20 |
```

**Key semantics:**
- `On events: reproduce` — only reproduction phase (before fixer)
- `On events: verify` — only verification phase (after test-engineer)
- `On events: reproduce, verify` — both phases
- `Exploration: enabled` — activates sub-phase B (guided exploration) within verification. Omit or set `disabled` to skip
- `Exploration max clicks` — hard cap for sub-phase B. Default: 20

**Interaction with existing `E2E Test` section:**
- `E2E Test` = scripted test generation (test-engineer writes Playwright tests as code artifacts)
- `Browser Verification` = runtime browser interaction (reproducer/verifier interact with live browser)
- Independent — can use both, either, or neither

---

## Failure Modes & Graceful Degradation

| Scenario | Behavior |
|----------|----------|
| Playwright not installed | Skip both phases, log info. Pipeline continues |
| `Browser Verification` config missing | Both phases disabled. Zero impact |
| App not running + no `Start command` | Skip, log warning. Fixer uses text description |
| App not running + `Start command` set | Agent starts dev server via Bash, health-check, proceed |
| Evidence too large for context | Truncate per rules above |
| Cannot reproduce bug | Note "not reproduced", continue pipeline |
| Verification FAILED (bug still present) | Block — return to fixer for another iteration |
| Verification timeout | Report partial results, don't block |

---

## Triage-Analyst Extension

The `triage-analyst` agent output needs one new field:

```markdown
## Triage Output (extended)
- Severity, Area, Complexity (existing)
- Acceptance criteria (existing)
- **Reproduction steps** (new, optional): structured list of browser actions when bug is UI-related
  - Format: `[{action: "navigate", target: "/login"}, {action: "fill", selector: "email", value: "test@example.com"}, ...]`
  - Only populated when: bug title/description contains UI keywords (button, page, screen, form, modal, etc.)
```

---

## Open Questions (Spike Required)

1. **Script generation reliability** — Can the agent generate correct Playwright scripts from bug descriptions? What's the failure rate? (~2h spike)
2. **Evidence bundle token cost** — What's the actual token cost of a reproduce-verify cycle? Does it help fixer produce better output? (~2h spike)
3. **Zero-shot visual judgment** — Does Claude's vision accurately determine "AC fulfilled?" from screenshot + AC text, without a baseline? (~1h spike)
4. **Dev server startup reliability** — Race conditions, port conflicts, startup time variance with `Start command`?
5. **Migration to Playwright CLI** — When Anthropic fixes sub-agent MCP access or CLI matures, what's the migration path?

---

## Spike Candidates (Recommended Order)

1. **Script Generation Spike** — 5 real bug reports with STR → measure script success rate, reproduction rate, token cost
2. **Evidence Bundle Spike** — Collect evidence from real app, feed to fixer, measure output quality improvement
3. **Zero-Shot Visual Judgment Spike** — 10 screenshots (5 with bugs, 5 without) + AC text → measure accuracy

---

## Implementation Notes

- Both agents follow existing agent definition format (frontmatter + Goal/Expertise/Process/Constraints)
- `reproducer` is read-code + write-script + execute + read-results (execution agent)
- `browser-verifier` is read-results + execute + read-results + output verdict (execution agent)
- Reproducer output is stored in `.claude/reproduction-result.json` (temp, not committed)
- Verifier output is stored in `.claude/verification-result.json` (temp, not committed)
- Screenshots stored in `{Screenshot storage}` path from config, referenced by PR comment
- Version bump: **MINOR** (new optional config section, 2 new agents, new triage output field)

---

## Recommended Direction

Two new agents (`reproducer` and `browser-verifier`) using the Hybrid Script approach: agents generate focused Playwright scripts, execute them via Bash, and read structured results from disk. This bypasses the current MCP sub-agent blocker, keeps token costs low, and produces reusable test artifacts. Reproduction phase ships first as higher-value; verification follows after reproduction is validated. Scoped verification (replay + adjacent page check) replaces open-ended exploration — research shows LLM exploration is too unreliable (14–37% success) for a production pipeline.
