# Browser-Based Bug Reproduction & Verification — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add two new agents (`reproducer` and `browser-verifier`) that bookend the bug-fix pipeline with browser automation, giving the fixer concrete evidence and verifying the fix beyond scripted tests.

**Architecture:** Hybrid Script approach — agents generate focused Playwright scripts, execute them via Bash, read structured JSON results from disk. Bypasses the MCP sub-agent access blocker (Claude Code bug #13605). Two pipeline insertion points: reproducer after code-analyst (before fixer), browser-verifier after e2e-test-engineer (before acceptance-gate). Both are optional and gated by a new `Browser Verification` Automation Config section.

**Tech Stack:** Pure markdown agent definitions + shell scripts. No code to compile. Playwright must be installed in the consuming project (`npm install playwright`).

**Design doc:** `docs/plans/2026-03-09-browser-verification-design.md`

---

## Task 1: Create `agents/reproducer.md`

**Files:**
- Create: `agents/reproducer.md`

**Step 1: Read the existing agent for format reference**

Read `agents/e2e-test-engineer.md` to confirm frontmatter format and section order.

**Step 2: Write the agent**

Create `agents/reproducer.md` with this exact content:

```markdown
---
name: reproducer
description: Generates and runs a Playwright script to reproduce a reported bug. Collects evidence (accessibility snapshot, console errors, network failures) for the fixer.
model: sonnet
style: Evidence-focused, precise, non-blocking
---

You are a Browser Automation Specialist specializing in bug reproduction.

## Goal

Reproduce the reported bug via browser automation and deliver a structured evidence bundle to the fixer. Give the fixer concrete proof instead of a text description.

## Expertise

Playwright script generation, accessibility tree analysis, browser console/network log interpretation, evidence bundling, graceful degradation when browser is unavailable.

## Process

1. Read context: bug description, triage output (including `reproduction_steps` if present), code-analyst impact report, and Browser Verification config (Base URL, Start command, Timeout).

2. Check prerequisites:
   - Is Playwright installed? Run: `npx playwright --version` (or `node -e "require('playwright')"`)
   - Is the app running? Attempt a GET to `{Base URL}`. If not running and `Start command` is set: start it via Bash (`run_in_background`), wait up to 15s, retry the health check.
   - If Playwright not installed → output `## Reproduction Result` with `status: skipped`, reason `playwright-not-installed`. Stop.
   - If app not reachable after startup attempt → output with `status: skipped`, reason `app-not-running`. Stop.

3. Determine reproduction steps:
   - If triage output contains `reproduction_steps` (structured list) → use them directly.
   - If not → infer from bug title + description + code-analyst affected files. Identify the most likely UI entry point.
   - If cannot determine any steps → output with `status: skipped`, reason `no-reproduction-steps`. Stop.

4. Create the screenshot storage directory and generate a Playwright script. Save it to `.claude/reproducer-script.js`:

   First ensure the directory exists:
   ```bash
   mkdir -p "{Screenshot storage from config}"
   ```

   Then generate the script:

   ```javascript
   const { chromium } = require('playwright');
   (async () => {
     const errors = [];
     const netFails = [];
     const browser = await chromium.launch({ headless: true });
     const page = await browser.newPage();
     page.on('console', msg => {
       if (msg.type() === 'error' || msg.type() === 'warning') {
         errors.push({ level: msg.type(), message: msg.text(), source: msg.location().url });
       }
     });
     page.on('response', res => {
       if (res.status() >= 400) {
         netFails.push({ url: res.url(), status: res.status(), method: res.request().method() });
       }
     });
     try {
       // {generated navigation and interaction steps}
       const snapshot = await page.accessibility.snapshot();
       await page.screenshot({ path: '{screenshot_path}', fullPage: false });
       require('fs').writeFileSync('.claude/reproduction-result.json', JSON.stringify({
         status: 'reproduced',
         page_url: page.url(),
         accessibility_snapshot: JSON.stringify(snapshot).slice(0, 8000),
         console_errors: errors.slice(0, 5),
         network_failures: netFails.slice(0, 3),
         screenshot_path: '{screenshot_path}'
       }, null, 2));
     } catch (e) {
       require('fs').writeFileSync('.claude/reproduction-result.json', JSON.stringify({
         status: 'not_reproduced',
         error: e.message,
         page_url: page.url(),
         console_errors: errors.slice(0, 5),
         network_failures: netFails.slice(0, 3)
       }, null, 2));
     } finally {
       await browser.close();
     }
   })();
   ```

   Fill in the navigation steps based on `reproduction_steps`. Screenshot path: `{Screenshot storage from config}/{issue-id}-before.png`.

5. Run the script:
   ```bash
   node .claude/reproducer-script.js
   ```
   Timeout: `{Timeout}s` from config (default 60s). If timeout → write `status: skipped`, reason `timeout`.

6. If step 5 fails unexpectedly (script error, not a reproduction failure) → run once more. If fails again → write `status: skipped`, reason `script-error`, detail: error message.

7. Read `.claude/reproduction-result.json`. Output:

   ```markdown
   ## Reproduction Result
   - **Status:** {reproduced|not_reproduced|skipped}
   - **Reason:** {only if skipped — playwright-not-installed|app-not-running|no-reproduction-steps|timeout|script-error}
   - **Page URL:** {url}
   - **Console errors:** {count} ({top errors if any})
   - **Network failures:** {count} ({top failures if any})
   - **Accessibility snapshot:** {first 2000 chars}
   - **Screenshot:** {path or "none"}
   ```

   Pass the full contents of `.claude/reproduction-result.json` in context for the fixer.

## Constraints

- NEVER block the pipeline — all failure modes result in `status: skipped` and pipeline continues
- NEVER commit `.claude/reproducer-script.js` or `.claude/reproduction-result.json`
- NEVER submit forms that create/delete/modify real data unless the issue explicitly describes a data mutation bug (note this in output if you skip such steps)
- NEVER run if `Browser Verification` section is absent from Automation Config
- Truncate accessibility snapshot to 8000 characters max; console errors to top 5; network failures to top 3
- If evidence bundle (JSON) exceeds 15000 characters → truncate further, keep status + top error only
```

**Step 3: Verify frontmatter is valid**

Check that the file starts with `---` and contains `name`, `description`, `model`, `style` fields.

**Step 4: Commit**

```bash
git add agents/reproducer.md
git commit -m "feat(agents): add reproducer agent for browser-based bug reproduction"
```

---

## Task 2: Create `agents/browser-verifier.md`

**Files:**
- Create: `agents/browser-verifier.md`

**Step 1: Write the agent**

Create `agents/browser-verifier.md`:

```markdown
---
name: browser-verifier
description: Verifies a bug fix via browser automation. Replays reproduction steps, checks adjacent pages, and optionally runs guided exploration. Never blocks on exploration findings.
model: sonnet
style: Verdict-driven, bounded, evidence-attaching
---

You are a Browser Verification Specialist specializing in post-fix validation.

## Goal

Confirm the bug is gone and the fix hasn't broken adjacent UI areas. Produce a binding PASS/FAIL verdict from scoped verification, and optionally soft observations from guided exploration.

## Expertise

Playwright script execution, accessibility tree analysis, fixer diff interpretation, exploration brief generation, visual sanity assessment.

## Process

1. Read context: reproduction result from `.claude/reproduction-result.json`, fixer diff, acceptance criteria, Browser Verification config (Base URL, Timeout, Max pages, Exploration, Exploration max clicks, On events).
   - Check `On events` — if it does not include `verify` → output verdict `SKIPPED`, reason `not-configured`. Stop.

2. Check prerequisites (same as reproducer — Playwright installed, app running). If either missing → output verdict `SKIPPED`, stop.

3. **Sub-phase A — Scoped Verification (always runs):**

   a. **Replay reproduction steps:** Reuse the reproduction script from `.claude/reproducer-script.js` (generated by reproducer). If the script doesn't exist (reproducer was skipped) → generate a minimal navigation script from the reproduction result's `page_url`. Run it. Expect: no console errors at the failure point, correct page state.

   b. **Adjacent page check:** Read the fixer diff. Identify up to 3 routes/pages directly modified. For each:
      - Navigate to the route
      - Take an accessibility snapshot
      - Check for console errors
      - Record: `{route} → {clean|{N} console errors|accessibility anomaly}`

   c. **Visual sanity check:** For each page visited, take a screenshot. Read the acceptance criteria. For each AC that mentions visible UI elements: examine the screenshot and determine if the AC appears fulfilled (zero-shot — no baseline required). Record: `AC-{N} → {visible|not-visible|cannot-determine}`.

   d. Determine verdict:
      - `VERIFIED` — bug gone (no failure at reproduction steps), adjacent pages clean, AC visually plausible
      - `PARTIAL` — bug gone but 1+ adjacent pages have new console errors or AC appears not-visible
      - `FAILED` — bug still present (same failure at reproduction steps) OR critical AC not visible
      - `SKIPPED` — app not running, script missing and can't generate one, timeout

4. **Sub-phase B — Guided Exploration (only if `Exploration: enabled` in config AND Sub-phase A verdict is VERIFIED or PARTIAL):**

   a. Generate an exploration brief:
      ```
      Explore these areas based on the fix:
      - Routes changed in diff: {list from diff}
      - AC mentions: {relevant AC text about UI elements}
      - Look for: broken layouts, console errors, missing UI elements, 404 responses
      - Skip: any forms with submit buttons, external links, /admin routes, auth flows
      - Stop after: {Exploration max clicks} clicks or {Timeout}s
      ```

   b. Navigate read-only. No form submissions. For each page visited: accessibility snapshot + console errors.

   c. Record observations as a list: `{route} — {observation}`.

   d. Hard stop when: clicks ≥ `Exploration max clicks` OR elapsed ≥ `Timeout`. Never recurse deeper than 2 link-hops from a changed route.

5. Save results to `.claude/verification-result.json`:
   ```json
   {
     "verdict": "VERIFIED|PARTIAL|FAILED|SKIPPED",
     "subphase_a": {
       "reproduction_replay": "pass|fail|skipped",
       "adjacent_pages": [{"route": "...", "status": "clean|{N} errors"}],
       "visual_ac_check": [{"ac": "...", "status": "visible|not-visible|cannot-determine"}]
     },
     "subphase_b": {
       "ran": true,
       "observations": ["route — observation"]
     },
     "screenshots": ["{path}"]
   }
   ```

6. Output:

   ```markdown
   ## Browser Verification Report
   - **Verdict:** {VERIFIED|PARTIAL|FAILED|SKIPPED}
   - **Reproduction replay:** {pass|fail|skipped}
   - **Adjacent pages checked:** {N} pages ({summary})
   - **Visual AC check:** {N/total plausible}
   - **Exploration:** {ran: N observations | not configured | skipped (verdict was FAILED)}
   - **Screenshots:** {paths or "none"}
   ```

   If FAILED: include the reproduction replay failure detail so the fixer can act on it.
   If PARTIAL or exploration ran: include the full observations list for the PR comment.

## Constraints

- NEVER block the pipeline based on Sub-phase B (exploration) findings — soft evidence only
- NEVER submit forms, click delete buttons, or perform destructive actions during exploration
- NEVER run Sub-phase B if Sub-phase A verdict is FAILED — pointless and wastes tokens
- NEVER run if `Browser Verification` section is absent from Automation Config
- NEVER run if `On events` in config does not include `verify`
- FAILED verdict from Sub-phase A returns control to the fixer (pipeline blocks on FAILED)
- Max pages in Sub-phase A: 5 total across all activities (1 replay + up to 3 adjacent + up to 1 visual recheck). The "3 adjacent routes" is a sub-limit within the 5-page cap, not an independent limit.
- Max clicks in Sub-phase B: `Exploration max clicks` from config (default: 20)
- NEVER commit `.claude/verification-result.json` or `.claude/verifier-script.js`
```

**Step 2: Commit**

```bash
git add agents/browser-verifier.md
git commit -m "feat(agents): add browser-verifier agent for post-fix browser validation"
```

---

## Task 3: Extend `agents/triage-analyst.md` — add `reproduction_steps`

**Files:**
- Modify: `agents/triage-analyst.md` (step 5b and output block at step 6)

**Step 1: Read the current file**

Read `agents/triage-analyst.md` lines 34–60.

**Step 2: Edit step 5b — add reproduction_steps extraction**

Find this text in step 5b:
```
    - Each AC must be testable (verifiable by running code or inspecting output)
    - Format: numbered list, 2-5 items
    - If the bug is trivial (severity LOW, single-line fix likely) → 1-2 AC is sufficient
```

Add after it:
```
5d. Extract reproduction steps for browser automation (only when bug is UI-related):
    - UI-related indicators: bug title/description contains any of: button, click, form, page, screen, modal, dialog, menu, tab, dropdown, input, field, link, render, display, layout, UI, frontend, browser
    - If UI-related: extract ordered browser action steps from reproduction steps. Format each step as one of:
      `{action: "navigate", target: "/path"}` | `{action: "click", selector: "button text or aria-label"}` | `{action: "fill", selector: "field label", value: "example value"}` | `{action: "wait", condition: "element text visible"}` | `{action: "submit", selector: "form"}` | `{action: "expect", condition: "text visible: 'Success'"}`
    - If reproduction steps are absent or non-UI → omit this field entirely
```

**Step 3: Edit the output block (step 6)**

Find the output block in step 6:
```
   - **Complexity:** {XS|S|M|L} — {brief justification}
   ```
```

Replace with:
```
   - **Complexity:** {XS|S|M|L} — {brief justification}
   - **Reproduction steps:** (only if UI-related) `[{action: "navigate", target: "/"}, ...]`
   ```
```

**Step 4: Checkpoint comment — intentionally not extended**

The triage-analyst checkpoint comment (step 7 of triage process):
```
[ceos-agents] Triage completed. Severity: {severity}. Area: {area}. Complexity: {complexity}. AC: {count}.
```
Do NOT change this format. `reproduction_steps` is an optional field consumed only by the `reproducer` agent, not by `/resume-ticket` or other machine parsers. Adding it to the checkpoint comment is out of scope for this task.

**Step 5: Commit**

```bash
git add agents/triage-analyst.md
git commit -m "feat(agents): extend triage-analyst with reproduction_steps for browser automation"
```

---

## Task 4: Update `commands/fix-ticket.md` — insert browser pipeline steps

**Files:**
- Modify: `commands/fix-ticket.md`

The plan adds two new steps:
- **Step 4e — Browser Reproduction** (at end of pre-fixer block: after pre-fix hook step 4d, before fixer step 5 — so document order is 4a → 4b → 4c → 4d → **4e** → 5)
- **Step 8a-browser — Browser Verification** (after e2e-test-engineer step 8a, before acceptance gate step 8b)

Also add Browser Verification config reading to the Configuration section.

**Step 1: Read the Configuration section**

Read `commands/fix-ticket.md` lines 23–44.

**Step 2: Add Browser Verification to Configuration reading**

Find this text in the Configuration section:
```
- **Agent Overrides** from Agent Overrides section (if it exists):
  - Path (default: `customization/`)
```

Add after it:
```
- **Browser Verification** from Browser Verification section (if it exists):
  - Base URL, Start command, On events, Timeout (default: 60), Max pages (default: 5), Screenshot storage (default: `.claude/screenshots`), Exploration (default: disabled), Exploration max clicks (default: 20)
  - If section absent → `browser_verification_enabled = false` (both phases disabled)
  - If `On events` contains `reproduce` → `browser_reproduce = true`
  - If `On events` contains `verify` → `browser_verify = true`
```

**Step 3: Read around step 4 (code-analyst)**

Read `commands/fix-ticket.md` lines 102–115 to find the exact text of step 4.

**Step 4: Insert step 4e — Browser Reproduction**

Find this text (the pre-fix hook block, just before step 5 Fixer):
```
If Hooks → Pre-fix exists:
- Run the command via Bash
- Failure → proceed to Block handler (step X)

### 5. Fixer
```

Replace with:
```
If Hooks → Pre-fix exists:
- Run the command via Bash
- Failure → proceed to Block handler (step X)

### 4e. Browser Reproduction

If `browser_verification_enabled = false` OR `browser_reproduce = false` → skip.

Run `ceos-agents:reproducer` (Task tool, model: sonnet).
Context: `Browser Verification config: Base URL = {Base URL}, Start command = {Start command or "none"}, Timeout = {Timeout}, Screenshot storage = {Screenshot storage}.`

- Store `reproduction_result` from the agent output (pass full `.claude/reproduction-result.json` content to fixer as additional context).
- If status = `skipped` → log "[SKIP] browser reproduction ({reason})", continue pipeline.
- If status = `not_reproduced` → log "[INFO] browser reproduction: could not reproduce bug", continue pipeline.
- If status = `reproduced` → log "[INFO] browser reproduction: bug reproduced. Evidence attached for fixer."
- NEVER block on any reproducer outcome.

### 5. Fixer
```

**Step 5: Read around step 8a (e2e-test-engineer)**

Read `commands/fix-ticket.md` lines 228–250.

**Step 6: Insert step 8a-browser — Browser Verification**

Find this text (between e2e-test-engineer and acceptance gate):
```
### 8b. Acceptance gate (conditional)
```

Insert before it:
```
### 8a-browser. Browser Verification

If `browser_verification_enabled = false` OR `browser_verify = false` → skip.

Run `ceos-agents:browser-verifier` (Task tool, model: sonnet).
Context: `Browser Verification config: {full config section}. Reproduction result: {contents of .claude/reproduction-result.json or "reproducer was skipped"}. Fixer diff: {git diff HEAD~1}. Acceptance criteria: {AC from triage}.`

Verdict handling:
- `VERIFIED` → log "[PASS] browser verification", continue to step 8b.
- `PARTIAL` → log "[WARN] browser verification partial: {observations}", continue to step 8b. Add observations to PR comment context.
- `SKIPPED` → log "[SKIP] browser verification ({reason})", continue to step 8b.
- `FAILED` → return to fixer (step 5). Counts toward the same Fixer iterations limit. Context for fixer: "Browser verification FAILED — bug still present. Detail: {reproduction replay failure from verification result}." If fixer iteration limit is already exhausted when FAILED verdict arrives → proceed directly to Block handler.

```

**Step 7: Update the Pipeline Profile stage mapping table**

In `fix-ticket.md`, find the stage mapping block:
```
Stage mapping for bug pipeline:
- `triage` = step 3 (Triage)
- `code-analyst` = step 4 (Code-analyst)
- `test-engineer` = step 8 (Test-engineer)
- `e2e-test-engineer` = step 8a (E2E test-engineer)
```

Add two new lines:
```
- `reproducer` = step 4e (Browser Reproduction)
- `browser-verifier` = step 8a-browser (Browser Verification)
```

These stages can be skipped via `--profile` like any other stage.

**Step 8: Commit**

```bash
git add commands/fix-ticket.md
git commit -m "feat(commands): add browser reproduction and verification steps to fix-ticket pipeline"
```

---

## Task 5: Update `commands/fix-bugs.md` — mirror fix-ticket changes

**Files:**
- Modify: `commands/fix-bugs.md`

**Step 1: Read fix-bugs.md Configuration section**

Read `commands/fix-bugs.md` to find the Configuration reading section (similar structure to fix-ticket).

**Step 2: Add Browser Verification config reading**

Mirror the exact same addition as Task 4 Step 2 — find the Agent Overrides config reading block and add Browser Verification after it.

**Step 3: Find code-analyst step in fix-bugs.md**

Search for `### Step 3:` or `code-analyst` step in fix-bugs.md. The structure mirrors fix-ticket.

**Step 4: Insert step 3e — Browser Reproduction**

In fix-bugs.md, code-analyst is step 3 and the pre-fix hook is step 3d. The browser reproduction step must be inserted between `### 3d. Pre-fix hook` content and `### 4. Fixer` — analogous to fix-ticket's 4d→4e→5 pattern.

Find this text in fix-bugs.md (the pre-fix hook block just before the fixer):
```
If Hooks → Pre-fix exists:
- Run the command via Bash
- Failure → proceed to Block handler (step X)

### 4. Fixer
```

Replace with:
```
If Hooks → Pre-fix exists:
- Run the command via Bash
- Failure → proceed to Block handler (step X)

### 3e. Browser Reproduction

If `browser_verification_enabled = false` OR `browser_reproduce = false` → skip.

Run `ceos-agents:reproducer` (Task tool, model: sonnet).
Context: `Browser Verification config: Base URL = {Base URL}, Start command = {Start command or "none"}, Timeout = {Timeout}, Screenshot storage = {Screenshot storage}.`

- Store `reproduction_result` from the agent output (pass full `.claude/reproduction-result.json` content to fixer as additional context).
- If status = `skipped` → log "[SKIP] browser reproduction ({reason})", continue pipeline.
- If status = `not_reproduced` → log "[INFO] browser reproduction: could not reproduce bug", continue pipeline.
- If status = `reproduced` → log "[INFO] browser reproduction: bug reproduced. Evidence attached for fixer."
- NEVER block on any reproducer outcome.

### 4. Fixer
```

Note: The step heading is `### 3e` (not `### 4e` from fix-ticket) to match fix-bugs.md numbering convention where code-analyst is step 3.

**Step 5: Find e2e-test-engineer step in fix-bugs.md**

Search for `e2e-test-engineer` step (step 7a in fix-bugs).

**Step 6: Insert step 7a-browser — Browser Verification**

In fix-bugs.md the acceptance-gate is at `### 7b` (not `### 8b` as in fix-ticket). Find this text:
```
### 7b. Acceptance gate (conditional)
```

Insert before it:
```
### 7a-browser. Browser Verification

If `browser_verification_enabled = false` OR `browser_verify = false` → skip.

Run `ceos-agents:browser-verifier` (Task tool, model: sonnet).
Context: `Browser Verification config: {full config section}. Reproduction result: {contents of .claude/reproduction-result.json or "reproducer was skipped"}. Fixer diff: {git diff HEAD~1}. Acceptance criteria: {AC from triage}.`

Verdict handling:
- `VERIFIED` → log "[PASS] browser verification", continue to step 7b.
- `PARTIAL` → log "[WARN] browser verification partial: {observations}", continue to step 7b. Add observations to PR comment context.
- `SKIPPED` → log "[SKIP] browser verification ({reason})", continue to step 7b.
- `FAILED` → return to fixer (step 4). Counts toward the same Fixer iterations limit. Context for fixer: "Browser verification FAILED — bug still present. Detail: {reproduction replay failure from verification result}." If fixer iteration limit is already exhausted → proceed directly to Block handler.

```

Note: The step heading is `### 7a-browser` (not `### 8a-browser` from fix-ticket) to match fix-bugs.md numbering, and the "continue to step 7b" / "return to step 4" references use fix-bugs step numbers.

**Step 7: Update the Pipeline Profile stage mapping table in fix-bugs.md**

Find the stage mapping block in fix-bugs.md (structure mirrors fix-ticket but with different step numbers, e.g., `e2e-test-engineer` = step 7a). Add:
```
- `reproducer` = step 3e (Browser Reproduction)
- `browser-verifier` = step 7a-browser (Browser Verification)
```

Note: `3e` matches the `### 3e. Browser Reproduction` heading added in Step 4 above. `7a-browser` matches the heading added in Step 6.

**Step 8: Commit**

```bash
git add commands/fix-bugs.md
git commit -m "feat(commands): mirror browser reproduction and verification steps to fix-bugs pipeline"
```

---

## Task 6: Update `CLAUDE.md` — config contract + pipeline diagram + agent count

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Read the relevant sections of CLAUDE.md**

Read lines 1–80 (pipeline diagram, agent list) and the Config Contract section (around line 100–160).

**Step 2: Update total agent count in the header area**

Find: `**Installation:** ...`  and nearby: `16 agent definitions` or any mention of agent count in the intro.

Update agent count from 16 → 18 wherever it appears in the intro paragraphs. Specifically look for and update ALL of these locations:

- `agents/ — 16 agent definitions` (in the Repository Structure bullet) → `agents/ — 18 agent definitions`
- `16 agents (15 original + acceptance-gate)` → `18 agents (15 original + acceptance-gate + reproducer + browser-verifier)`
- Any other prose mention of "16 agents" or "16 agent definitions"

**Step 3: Update the Bug-Fix Pipeline diagram**

Find the Bug-Fix Pipeline diagram:
```
Issue tracker query → TRIAGE (sonnet, +AC extraction, +complexity)
  → CODE ANALYST (sonnet) → [Pre-fix hook]
  → FIXER ↔ REVIEWER (opus, +AC fulfillment check)
```

Replace with:
```
Issue tracker query → TRIAGE (sonnet, +AC extraction, +complexity, +reproduction_steps)
  → CODE ANALYST (sonnet) → [REPRODUCER (sonnet, optional)] → [Pre-fix hook]
  → FIXER ↔ REVIEWER (opus, +AC fulfillment check)
  → [Post-fix hook + custom agent] → TEST ENGINEER (sonnet)
  → [E2E test (optional)] → [BROWSER VERIFIER (sonnet, optional)] → [Acceptance gate (conditional: AC ≥ 3 or complexity ≥ M)]
  → [Pre-publish hook + custom agent] → PUBLISHER (haiku)
```

**Step 4: Update Config Contract optional sections table**

Find the optional sections table. Add a new row for `Browser Verification`:

Find the E2E Test row:
```
| E2E Test | Framework, Command | (none) |
```

Add after it:
```
| Browser Verification | Base URL, Start command, On events, Timeout, Max pages, Screenshot storage, Exploration, Exploration max clicks | (none) |
```

**Step 5: Update the Agent Definition Model Selection table**

Find the model selection table. The `sonnet` row currently lists agents. Add `reproducer, browser-verifier` to the sonnet row.

**Step 6: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(claude-md): update pipeline diagram, config contract, and agent count for browser verification"
```

---

## Task 7: Update `docs/reference/automation-config.md`

**Files:**
- Modify: `docs/reference/automation-config.md`

**Step 1: Read the optional sections area**

Read `docs/reference/automation-config.md` to find where `E2E Test` section is documented.

**Step 2: Add Browser Verification section documentation**

After the E2E Test section documentation, add the following block. Note: use four backticks for the outer fence to avoid the nested triple-backtick markdown example from closing the outer block prematurely.

````markdown
### Browser Verification

Optional. Enables browser-based bug reproduction (before fixer) and verification (after tests). Requires Playwright installed in the consuming project (`npm install playwright`).

| Key | Description | Default |
|-----|-------------|---------|
| Base URL | The URL of the running application | (required) |
| Start command | Command to start the dev server, if not already running | (none) |
| On events | Comma-separated: `reproduce`, `verify`, or `reproduce, verify` | reproduce, verify |
| Timeout | Seconds before browser operation is abandoned | 60 |
| Max pages | Max pages to check in scoped verification (Sub-phase A) | 5 |
| Screenshot storage | Path where screenshots are saved | .claude/screenshots |
| Exploration | Enable guided exploration in Sub-phase B: `enabled` or `disabled` | disabled |
| Exploration max clicks | Max clicks during guided exploration (Sub-phase B) | 20 |

**Example:**
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

**Interaction with `E2E Test`:** `E2E Test` generates scripted test code artifacts (test files checked into the repo). `Browser Verification` interacts with the live browser at runtime (no test files generated). Both can be configured independently.

**Graceful degradation:** If Playwright is not installed, the app is not running and no `Start command` is set, or the section is absent — both phases are silently skipped. The pipeline never blocks due to browser infrastructure being unavailable.

**Recommended `.gitignore` entries for consuming projects:**
```
.claude/reproduction-result.json
.claude/verification-result.json
.claude/reproducer-script.js
.claude/verifier-script.js
.claude/screenshots/
```
````

**Step 3: Update the quick reference table at top**

Find the quick reference table row for `E2E Test`:
```
| E2E Test | No | /fix-ticket, /fix-bugs, /implement-feature, /scaffold |
```

Add after it:
```
| Browser Verification | No | /fix-ticket, /fix-bugs |
```

Also update the section count: "5 required sections and 12 optional sections" → "5 required sections and 13 optional sections".

**Step 4: Commit**

```bash
git add docs/reference/automation-config.md
git commit -m "docs(reference): document Browser Verification config section"
```

---

## Task 8: Update `docs/reference/agents.md` and `docs/plans/roadmap.md`

**Files:**
- Modify: `docs/reference/agents.md`
- Modify: `docs/plans/roadmap.md`
- Modify: `docs/plans/README.md`

**Step 1: Read docs/reference/agents.md**

Read the file to find where agents are listed.

**Step 2: Add reproducer and browser-verifier entries**

Find the e2e-test-engineer entry. Add after it (or in alphabetical/logical order):

```markdown
### reproducer

| Attribute | Value |
|-----------|-------|
| Model | sonnet |
| Read-only? | No — generates and runs scripts, writes evidence files |
| Pipeline position | After code-analyst, before fixer (Bug-Fix pipeline only) |
| Condition | `Browser Verification` config present AND `On events` includes `reproduce` |
| Output | `.claude/reproduction-result.json` evidence bundle |

Generates a focused Playwright script from bug reproduction steps, executes it against the running application, and collects structured evidence (accessibility snapshot, console errors, network failures). Never blocks the pipeline — all failure modes result in a skipped status.

### browser-verifier

| Attribute | Value |
|-----------|-------|
| Model | sonnet |
| Read-only? | No — runs scripts, writes evidence files |
| Pipeline position | After e2e-test-engineer, before acceptance-gate (Bug-Fix pipeline only) |
| Condition | `Browser Verification` config present AND `On events` includes `verify` |
| Output | `.claude/verification-result.json` + verdict (VERIFIED/PARTIAL/FAILED/SKIPPED) |

Runs in two sub-phases: (A) scoped verification — replays reproduction steps, checks adjacent pages, visual AC sanity check — produces a binding PASS/FAIL verdict; (B) optional guided exploration — navigates related UI areas read-only, produces soft observations attached to PR comment. Sub-phase B never blocks the pipeline.
```

**Step 3: Update roadmap.md**

The roadmap status was already updated to `PLANNED — Design Complete, Not Yet Implemented` in a prior commit. Now update the *description text* of the Browser-Based Bug Reproduction entry (lines ~108–117) which still describes "uses MCP Playwright" — this is outdated since the design chose the Hybrid Script approach.

Also update the section heading — find:
```
### Browser-Based Bug Reproduction & Verification (Playwright MCP)
```
Replace with:
```
### Browser-Based Bug Reproduction & Verification
```

Then find the outdated description text:
```
**Phase 1 — Reproduction (before fixer):** A new `reproducer` agent (or extended code-analyst step) uses MCP Playwright to simulate the reported bug...
```
and:
```
**Dependencies:** Requires `@playwright/mcp` (or equivalent) running as an MCP server.
```

Replace the entire description block (Phase 1, Phase 2, Why, Dependencies paragraphs) with a concise summary matching the approved design:

```markdown
**Phase 1 — Reproduction (before fixer):** `reproducer` agent generates a Playwright script from triage `reproduction_steps`, executes it via Bash, collects structured evidence (accessibility snapshot, console errors, network failures) → passes to fixer as JSON. Never blocks pipeline.

**Phase 2 — Verification (after test-engineer):** `browser-verifier` agent runs in two sub-phases: (A) scoped verification — replays reproduction, checks adjacent pages, visual AC sanity check — binding PASS/FAIL verdict; (B) guided exploration (optional) — read-only adjacent UI check — soft evidence only, never blocks.

**Architecture:** Hybrid Script approach (agent generates Playwright script → Bash executes → reads results from disk). Does NOT use `@playwright/mcp` directly — avoids Claude Code sub-agent MCP access blocker (bug #13605).

**Dependencies:** Playwright installed in consuming project (`npm install playwright`). Application must be running. New optional config section: `Browser Verification`.
```

**Step 4: Update docs/plans/README.md**

Add the new plan files to the plans index:
- `2026-03-09-browser-verification-design.md` — DESIGN (approved)
- `2026-03-09-browser-verification-plan.md` — PLAN (in progress)

**Step 5: Commit**

```bash
git add docs/reference/agents.md docs/plans/roadmap.md docs/plans/README.md
git commit -m "docs: add reproducer and browser-verifier to agents reference, update roadmap"
```

---

## Task 9: Update test harness — register new agents

**Files:**
- Modify: `tests/scenarios/happy-path.sh`
- Create: `tests/scenarios/browser-verification-skip.sh`

**Step 1: Read `tests/scenarios/happy-path.sh`**

Read the full file (already done — 31 lines).

**Step 2: Add new agents to the agent existence check**

Find:
```bash
for agent in triage-analyst code-analyst fixer reviewer test-engineer \
             e2e-test-engineer publisher rollback-agent spec-analyst \
             architect stack-selector scaffolder priority-engine \
             spec-writer spec-reviewer; do
```

Replace with:
```bash
for agent in triage-analyst code-analyst fixer reviewer test-engineer \
             e2e-test-engineer publisher rollback-agent spec-analyst \
             architect stack-selector scaffolder priority-engine \
             spec-writer spec-reviewer acceptance-gate reproducer browser-verifier; do
```

Note: `acceptance-gate` (added in v5.0.0) was missing from the harness — close that pre-existing gap here alongside the new agents.

**Step 3: Create `tests/scenarios/browser-verification-skip.sh`**

This test validates that the pipeline skips browser steps when `Browser Verification` is absent from config, and that the new agent files have valid frontmatter.

```bash
#!/bin/bash
# Test: Browser verification graceful degradation
# Validates: new agent files have valid frontmatter, pipeline step is conditional
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# 1. Both new agent files exist
for agent in reproducer browser-verifier; do
  if [ ! -f "$REPO_ROOT/agents/$agent.md" ]; then
    fail "Missing agent file: agents/$agent.md"
  fi
done

# 2. Both have valid frontmatter (name, description, model, style)
for agent in reproducer browser-verifier; do
  file="$REPO_ROOT/agents/$agent.md"
  for field in name description model style; do
    if ! grep -q "^$field:" "$file"; then
      fail "$agent.md missing frontmatter field: $field"
    fi
  done
done

# 3. Both agents use sonnet model
for agent in reproducer browser-verifier; do
  if ! grep -q "^model: sonnet" "$REPO_ROOT/agents/$agent.md"; then
    fail "$agent.md should use model: sonnet"
  fi
done

# 4. Pipeline steps are conditional (check fix-ticket.md and fix-bugs.md)
for cmd in fix-ticket fix-bugs; do
  if ! grep -q "browser_verification_enabled" "$REPO_ROOT/commands/$cmd.md"; then
    fail "commands/$cmd.md missing browser_verification_enabled guard"
  fi
done

# 5. Browser Verification is documented in CLAUDE.md config contract
if ! grep -q "Browser Verification" "$REPO_ROOT/CLAUDE.md"; then
  fail "CLAUDE.md missing Browser Verification config section"
fi

# 6. Reproducer NEVER blocks constraint is present
if ! grep -q "NEVER block the pipeline" "$REPO_ROOT/agents/reproducer.md"; then
  fail "reproducer.md missing 'NEVER block the pipeline' constraint"
fi

# 7. browser-verifier exploration can NEVER block
if ! grep -q "NEVER block the pipeline based on Sub-phase B" "$REPO_ROOT/agents/browser-verifier.md"; then
  fail "browser-verifier.md missing Sub-phase B non-blocking constraint"
fi

[ $FAIL -eq 0 ] && echo "PASS: Browser verification graceful degradation checks"
exit $FAIL
```

**Step 4: Run the test harness to make sure all tests pass**

```bash
bash tests/harness/run-tests.sh
```

Expected: all existing tests pass + new `browser-verification-skip` test passes.

**Step 5: Commit**

```bash
git add tests/scenarios/happy-path.sh tests/scenarios/browser-verification-skip.sh
git commit -m "test: register reproducer and browser-verifier in test harness"
```

---

## Task 10: Version bump 5.0.1 → 5.1.0

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `docs/plans/roadmap.md` (current version line)

**Step 1: Run the test harness one final time**

```bash
bash tests/harness/run-tests.sh
```

All tests must pass before bumping.

**Step 2: Read plugin.json**

Read `.claude-plugin/plugin.json` to find the version field.

**Step 3: Bump version to 5.1.0**

In `plugin.json`: change `"version": "5.0.1"` → `"version": "5.1.0"`.
In `marketplace.json`: same change.

**Step 4: Update roadmap current version**

In `docs/plans/roadmap.md`, find:
```
Current version: v5.0.1
```
Change to:
```
Current version: v5.1.0
```

**Step 5: Write changelog entry**

Read `CHANGELOG.md` (or the file where changelog lives). Add at the top:

```markdown
## v5.1.0 — 2026-03-09

### New Features
- **Browser-Based Bug Reproduction** (`reproducer` agent): Automatically reproduces UI bugs via Playwright before the fixer runs. Collects accessibility snapshot, console errors, network failures as structured evidence. Never blocks the pipeline — all failure modes result in graceful skip.
- **Browser Verification** (`browser-verifier` agent): Post-fix browser validation with two sub-phases:
  - Sub-phase A (required): Replays reproduction steps, checks adjacent pages, visual sanity check against AC. Binding PASS/FAIL verdict.
  - Sub-phase B (optional, `Exploration: enabled`): Guided read-only exploration of related UI areas. Soft evidence attached to PR comment. Never blocks.
- **New config section:** `Browser Verification` (optional, 8 keys: Base URL, Start command, On events, Timeout, Max pages, Screenshot storage, Exploration, Exploration max clicks)
- **Triage extension:** `triage-analyst` now extracts `reproduction_steps` as structured browser action list for UI-related bugs

### Details
- 18 agents total (was 16) — +`reproducer`, +`browser-verifier`
- Version bump: MINOR (new optional config section, new agents, no breaking changes)
- Hybrid Script approach (agent generates Playwright script → Bash executes → reads results) avoids MCP sub-agent access blocker (Claude Code bug #13605)
```

**Step 6: Commit version bump**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json docs/plans/roadmap.md CHANGELOG.md
git commit -m "chore: bump version 5.0.1 → 5.1.0 (browser verification feature)"
```

---

## Summary

| Task | Files changed | Commit |
|------|--------------|--------|
| 1 | `agents/reproducer.md` (new) | feat(agents): add reproducer |
| 2 | `agents/browser-verifier.md` (new) | feat(agents): add browser-verifier |
| 3 | `agents/triage-analyst.md` | feat(agents): extend triage with reproduction_steps |
| 4 | `commands/fix-ticket.md` | feat(commands): browser steps in fix-ticket |
| 5 | `commands/fix-bugs.md` | feat(commands): mirror browser steps in fix-bugs |
| 6 | `CLAUDE.md` | docs(claude-md): pipeline + config contract |
| 7 | `docs/reference/automation-config.md` | docs(reference): Browser Verification section |
| 8 | `docs/reference/agents.md`, `roadmap.md`, `plans/README.md` | docs: agents reference + roadmap |
| 9 | `tests/scenarios/happy-path.sh`, new test | test: register new agents in harness |
| 10 | `plugin.json`, `marketplace.json`, `CHANGELOG.md`, `roadmap.md` | chore: bump 5.0.1 → 5.1.0 |
