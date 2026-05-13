# Research Answer 2: Shared Pipeline Pattern Map

## Pattern Comparison Matrix

| Pattern | fix-ticket | fix-bugs | implement-feature | scaffold | Classification |
|---------|-----------|----------|-------------------|----------|---------------|
| 1. Config reading block | Present (lines 25–48) | Present (lines 16–41) | Present (lines 12–30) | Absent (no Automation Config read upfront; config read inline) | analogous |
| 2. MCP pre-flight check | Present (lines 73–78) | Present (lines 66–71) | Present (lines 58–63) | Present (lines 472–483) — conditional/deferred | analogous |
| 3. Pipeline profile parsing | Present (lines 50–71) | Present (lines 43–64) | Present (lines 41–56) | Absent | analogous |
| 4. Flag parsing | Partial — inline in header (lines 10–13) | Partial — inline in header (lines 10–12) | Full section (lines 33–39) | Full section (lines 12–22) + validation (lines 26–36) | divergent |
| 5. Fixer↔reviewer loop | Present (steps 5+7, lines 203–238) | Present (steps 4+6, lines 193–228) | Present (steps 6b+6d, lines 167–188) | Present (steps 7a+7b, lines 343–355) | analogous |
| 6. Block handler | Present — step X (lines 347–378) | Present — step X (lines 351–387) | Present — step X (lines 285–305) | Present — inline per step 7 (lines 370–384) | divergent |
| 7. Agent override injection | Present — Rules section (lines 405–407) | Present — Rules section (lines 484–485) | Present — Rules section (lines 313–314) | Present — Rules section (lines 488–490) | identical |
| 8. Post-publish hook + webhook | Present (steps 9a+9b, lines 301–314) | Present (steps 8a+8b, lines 290–304) | Present — step 10a (lines 261–266) | Absent (hooks explicitly skipped in scaffold, line 331) | divergent |
| 9. Fix verification (post-merge) | Present — step 9d (lines 324–346) | Present — step 8c (lines 306–320) | Present — step 10b (lines 268–283) | Absent | analogous |
| 10. Decomposition heuristics | Present — steps 4a+4b (lines 117–158) | Present — steps 3a+3b (lines 105–148) | Present — step 5 (lines 104–148) | Present — step 5 (lines 256–303), but inverted (always decomposes) | analogous |

---

## Pattern 1: Config Reading Block

### fix-ticket.md excerpt [source: lines 25–48]

```
Before starting the pipeline, read from Automation Config:
- **Type** from Issue Tracker (default: `youtrack`) — determines the MCP tool prefix
- **Retry limits** from Retry Limits section (if it exists):
  - Fixer iterations (default: 5)
  - Test attempts (default: 3)
  - Build retries (default: 3)
- **Hooks** from Hooks section (if it exists)
- **Custom Agents** from Custom Agents section (if it exists)
- **Notifications** from Notifications section (if it exists)
- **Decomposition** from Decomposition section (if it exists): ...
- **Error Handling** from Error Handling section (if it exists): ...
- **Extra labels** from Extra labels section (if it exists): ...
- **Agent Overrides** from Agent Overrides section (if it exists): ...
- **Browser Verification** from Browser Verification section (if it exists): ...
```

### fix-bugs.md excerpt [source: lines 16–41]

Structurally identical to fix-ticket. Adds one extra key:

```
- **Worktrees** from Worktrees section (if it exists; otherwise sequential CWD processing)
- **Error Handling** from Error Handling section (if it exists):
  - On block (default: `comment`)
  - Max blocked per run (default: `unlimited`) — after reaching the limit, stop processing remaining bugs
```

### implement-feature.md excerpt [source: lines 12–30]

Uses a different presentation — splits Required vs Optional:

```
Read Automation Config from CLAUDE.md section `## Automation Config`:

**Required:**
- Issue Tracker: Type, Instance, Project, State transitions, On start set
- Source Control: Remote, Base branch, Branch naming
- PR Rules: Labels
- PR Description Template
- Build & Test: Build command, Test command

**Optional:**
- Feature Workflow: Feature query, On start set (fallback: Issue Tracker → On start set)
- Retry Limits: Fixer iterations (default: 5), Test attempts (default: 3), Build retries (default: 3)
- Hooks: Pre-fix, Post-fix, Pre-publish, Post-publish
- Custom Agents: Post-fix agent, Pre-publish agent
- Notifications: Webhook URL, On events
- Decomposition: Max subtasks (default: 7), Fail strategy (default: fail-fast), Commit strategy (default: squash)
- Error Handling: On block (default: `comment`) ...
- Extra labels: Labels (default: none) ...
- Agent Overrides: Path (default: `customization/`)
```

Note: implement-feature does NOT read Browser Verification config. No Worktrees key.

### scaffold.md excerpt [source: no upfront config block]

scaffold.md has no dedicated upfront `## Configuration` section. Config is read inline:
- Spec iterations read during Step 1: `Read max_iterations from Automation Config → Retry Limits → Spec iterations (default 5). Note: On fresh scaffold, CLAUDE.md does not exist yet. Use default 5.` [source: lines 195–196]
- Decomposition config read during Step 5: `Read Decomposition config from generated CLAUDE.md` [source: lines 284–287]
- Build retries and test attempts passed inline in agent contexts at Step 7 [source: lines 344, 351, 358]
- Agent Overrides declared in Rules section only [source: lines 487–490]

### Classification: analogous

fix-ticket and fix-bugs are near-identical (bullet-list format, same keys). implement-feature uses Required/Optional split — same keys, different structure. scaffold reads config lazily and inline rather than upfront.

### Extraction difficulty: medium

The key list is the same across fix-ticket/fix-bugs/implement-feature. scaffold's absence of a block is notable — an extracted kernel would need a "config-absent" variant for scaffold-v2 fresh starts.

---

## Pattern 2: MCP Pre-flight Check

### fix-ticket.md excerpt [source: lines 73–78]

```
### 0. MCP pre-flight check

Before any pipeline operation, verify MCP tool availability:
- Read Type from Automation Config (Issue Tracker section)
- Check that at least one `mcp__*` tool matching the tracker type is accessible
- If not accessible → STOP with: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure."
```

### fix-bugs.md excerpt [source: lines 66–71]

```
### 0. MCP pre-flight check

Before any pipeline operation, verify MCP tool availability:
- Read Type from Automation Config (Issue Tracker section)
- Check that at least one `mcp__*` tool matching the tracker type is accessible
- If not accessible → STOP with: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure."
```

### implement-feature.md excerpt [source: lines 58–63]

```
### 0. MCP pre-flight check

Before any pipeline operation, verify MCP tool availability:
- Read Type from Automation Config (Issue Tracker section)
- Check that at least one `mcp__*` tool matching the tracker type is accessible
- If not accessible → STOP with: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure."
```

fix-ticket, fix-bugs, and implement-feature: **word-for-word identical** (copy-paste).

### scaffold.md excerpt [source: lines 472–483]

```
## MCP Pre-flight Check

MCP pre-flight check is only required when:
- `--issue` flag is used (Step 1 — reading issue description from tracker)
- Step 9 — creating cards in issue tracker (only when tracker is configured and user opts in)

For `--no-implement`, keep the same behavior as v3.x (MCP check before stack-selector).

Before any MCP operation, verify MCP tool availability:
- Read Type from Automation Config (Issue Tracker section)
- Check that at least one `mcp__*` tool matching the tracker type is accessible
- If not accessible → STOP with: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure."
```

scaffold is analogous: same error message and check body, but placed in a standalone section at the bottom with explicit conditionality (not always step 0 — only when MCP is actually needed).

### resume-ticket.md excerpt [source: lines 46–51]

```
### 0. MCP pre-flight check

Before any pipeline operation, verify MCP tool availability:
- Read Type from Automation Config (Issue Tracker section)
- Check that at least one `mcp__*` tool matching the tracker type is accessible
- If not accessible → STOP with: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure."
```

resume-ticket is also identical to fix-ticket/fix-bugs/implement-feature.

### Classification: analogous (identical body, divergent placement in scaffold)

### Extraction difficulty: easy

The body text is copy-paste identical across 4 of 5 files. Only scaffold diverges structurally (conditional, moved to bottom). Trivially extractable as a reusable block.

---

## Pattern 3: Pipeline Profile Parsing

### fix-ticket.md excerpt [source: lines 50–71]

```
## Pipeline profile parsing

If `--profile <name>` in $ARGUMENTS:
1. Read the `### Pipeline Profiles` section from Automation Config
2. Find the row with the matching profile
3. Extract the `Skip stages` and `Extra stages` columns
4. If the profile does not exist → error: "Profile '{name}' not found in Automation Config"

Stage mapping for bug pipeline:
- `triage` = step 3 (Triage)
- `code-analyst` = step 4 (Code-analyst)
- `test-engineer` = step 8 (Test-engineer)
- `e2e-test-engineer` = step 8a (E2E test-engineer)
- `reproducer` = step 4e (Browser Reproduction)
- `browser-verifier` = step 8a-browser (Browser Verification)

Skipping logic:
- Before each pipeline step, check whether the stage is in the `Skip stages` list
- If yes → skip the step, record "[SKIP] {stage} (profile: {name})"
- `Extra stages`: if it contains `e2e-test-engineer` → force step 8a even without the E2E Test config section

Restriction: NEVER skip fixer, reviewer, publisher — these stages are mandatory.
```

### fix-bugs.md excerpt [source: lines 43–64]

```
## Pipeline profile parsing

If `--profile <name>` in $ARGUMENTS:
1. Read the `### Pipeline Profiles` section from Automation Config
2. Find the row with the matching profile
3. Extract the `Skip stages` and `Extra stages` columns
4. If the profile does not exist → error: "Profile '{name}' not found in Automation Config"

Stage mapping for bug pipeline (fix-bugs):
- `triage` = step 2 (Triage)
- `code-analyst` = step 3 (Code-analyst)
- `test-engineer` = step 7 (Test-engineer)
- `e2e-test-engineer` = step 7a (E2E test-engineer)
- `reproducer` = step 3e (Browser Reproduction)
- `browser-verifier` = step 7a-browser (Browser Verification)

Skipping logic:
- Before each pipeline step, check whether the stage is in the `Skip stages` list
- If yes → skip the step, record "[SKIP] {stage} (profile: {name})"
- `Extra stages`: if it contains `e2e-test-engineer` → force step 7a even without the E2E Test config section

Restriction: NEVER skip fixer, reviewer, publisher — these stages are mandatory.
```

Identical logic and error message. Only differences: section header adds "(fix-bugs)", stage names map to different step numbers (step 2 vs step 3, etc.), and the forced E2E step number differs (7a vs 8a).

### implement-feature.md excerpt [source: lines 41–56]

```
## Pipeline profile parsing

If `--profile <name>` in $ARGUMENTS:
1. Read the `### Pipeline Profiles` section from Automation Config
2. Find the row with the matching profile
3. Extract the `Skip stages` and `Extra stages` columns
4. If the profile does not exist → error: "Profile '{name}' not found in Automation Config"

Stage mapping for feature pipeline:
- `spec-analyst` = step 3 (Spec-analyst)
- `code-analyst` = (N/A — feature pipeline does not have code-analyst)
- `triage` = (N/A — feature pipeline does not have triage)
- `test-engineer` = step 6e (Test-engineer)
- `e2e-test-engineer` = step 6f (E2E test-engineer)

Restriction: NEVER skip: fixer, reviewer, publisher.
```

Same header section, same 4-step lookup, same error message. Stage map diverges: no triage/code-analyst, no reproducer/browser-verifier. Skipping logic paragraph absent (it is implied by "Before each pipeline step, check..." being shared). Extra stages sentence absent.

### scaffold.md

Absent. scaffold.md has no `--profile` flag, no Pipeline profile parsing section.

### Classification: analogous

The 4-step lookup block and the error message are identical across all three commands that support it. The stage-to-step mapping is per-command. scaffold does not implement this pattern.

### Extraction difficulty: medium

Header + lookup logic extracts cleanly. Stage maps must remain per-command (different step numbering). The "Restriction: NEVER skip" sentence is near-identical (minor punctuation difference between fix-ticket/fix-bugs vs implement-feature).

---

## Pattern 4: Flag Parsing

### fix-ticket.md excerpt [source: lines 10–21]

Not a dedicated section — flags are declared in the command header and argument list:

```
If $ARGUMENTS contains `--dry-run`, activate dry-run mode (see Dry-run section below).
If $ARGUMENTS contains `--decompose` or `--no-decompose`, see Decompose flag parsing section.
If $ARGUMENTS contains `--profile <name>`, use the pipeline profile (see Pipeline profile parsing section).
If $ARGUMENTS contains `--yolo`, activate YOLO mode: skip all user confirmations ...

**Arguments:**
- `<ISSUE-ID>` — required, ticket ID in the issue tracker
- `--dry-run` — analysis without side effects (no git/issue tracker changes)
- `--decompose` — force decomposition into subtasks (even if heuristics say SINGLE_PASS)
- `--no-decompose` — disable decomposition (always SINGLE_PASS)
- `--profile <name>` — apply a pipeline profile from Automation Config
- `--yolo` — skip all confirmations, auto-approve and auto-publish
```

Decompose flag parsing is defined inline at step 4a [source: lines 117–122]:
```
### 4a. Decompose flag parsing
Parse `$ARGUMENTS` for decompose flags:
- `--decompose` (without `--no-decompose`): `decompose_mode = FORCE`
- `--no-decompose`: `decompose_mode = DISABLED`
- Neither: `decompose_mode = AUTO`
```

### fix-bugs.md excerpt [source: lines 10–12]

```
If $ARGUMENTS contains `--dry-run`, activate dry-run mode ...
If $ARGUMENTS contains `--decompose` or `--no-decompose`, see Decompose flag parsing section.
If $ARGUMENTS contains `--profile <name>`, apply the profile to EVERY bug ...
```

No `--yolo` flag in fix-bugs. Decompose flag parsing at step 3a [source: lines 105–110] — identical logic to fix-ticket step 4a.

### implement-feature.md excerpt [source: lines 33–39]

Full dedicated `## Flag parsing` section:

```
## Flag parsing

Parse `$ARGUMENTS`:
- Remove `--decompose`, `--no-decompose`, `--dry-run`, `--profile <name>`, `--yolo` from the arguments string
- Remainder = Issue ID
- `--decompose` (without `--no-decompose`): `decompose_mode = FORCE`
- `--no-decompose`: `decompose_mode = DISABLED`
- Neither: `decompose_mode = AUTO`
```

implement-feature combines removal + decompose logic into a single section upfront (no deferred step).

### scaffold.md excerpt [source: lines 12–22]

Full dedicated `## Flag Parsing` section (capitalized differently):

```
## Flag Parsing

Parse `$ARGUMENTS`:
- `--template <path>` → template_path
- `--spec <path>` → spec_path
- `--issue <ID>` → issue_id
- `--no-implement` → no_implement = true
- `--lang <value>` → preset language
- `--framework <value>` → preset framework
- `--db <value>` → preset database
- `--ci <value>` → preset CI provider
- `--brainstorm` → brainstorm = true
- Remainder after removing flags = project description (natural language)
```

scaffold also has a `## Flag Validation` section [source: lines 26–36] with mutual-exclusion checks — absent in all other commands.

### Classification: divergent

The decompose tri-state logic (FORCE/DISABLED/AUTO) is analogous across fix-ticket, fix-bugs, and implement-feature. But fix-ticket defers decompose parsing to a mid-pipeline step; implement-feature handles it upfront; fix-bugs defers it similarly to fix-ticket. scaffold's flags are entirely different and adds validation. No consistent section name or position.

### Extraction difficulty: hard

The decompose tri-state is extractable. The `--yolo` flag behavior differs (fix-ticket has it, fix-bugs does not, implement-feature has it, scaffold does not). The `--profile` flag is shared among fix-ticket/fix-bugs/implement-feature but absent from scaffold.

---

## Pattern 5: Fixer↔Reviewer Loop

### fix-ticket.md excerpt [source: lines 203–238, steps 5+7]

```
### 5. Fixer
Run `ceos-agents:fixer` (Task tool, model: opus).
Context: `Max build retries = {Build retries from config}. Block Comment Template: ... Acceptance criteria: {AC from triage}.`

### 7. Reviewer ⟲
Run `ceos-agents:reviewer` (Task tool, model: opus).
Context: `Max fixer iterations = {Fixer iterations from config}. Acceptance criteria: {AC from triage}.`
Fixer ↔ reviewer loop: max {Fixer iterations} iterations.
Iterations exhausted → proceed to Block handler (step X).
```

### fix-bugs.md excerpt [source: lines 193–228, steps 4+6]

```
### 4. Fixer
For each bug, run `ceos-agents:fixer` (Task tool, model: opus).
Context: `Max build retries = {Build retries from config}. Block Comment Template: ... Acceptance criteria: {AC from triage}.`

### 6. Reviewer ⟲
Run `ceos-agents:reviewer` (Task tool, model: opus).
Context: `Max fixer iterations = {Fixer iterations from config}. Acceptance criteria: {AC from triage}.`
Fixer ↔ reviewer loop: max {Fixer iterations} iterations.
Iterations exhausted → proceed to Block handler (step X).
```

fix-bugs adds "For each bug" scoping. Otherwise structurally identical to fix-ticket.

### implement-feature.md excerpt [source: lines 167–188, steps 6b+6d]

```
#### 6b. Fixer
Run the fixer agent (Task tool, model: opus):
- Context: architectural design + subtask scope + acceptance criteria
- After completion: run Build command

If build fails → fixer fixes it (max Build retries attempts).
If build still fails → proceed to step X.

#### 6d. Reviewer
Run the reviewer agent (Task tool, model: opus):
- Context: diff from fixer + acceptance criteria from spec-analyst

If reviewer returns APPROVE → continue.
If reviewer returns REQUEST_CHANGES → back to fixer with feedback (6b).
Max Fixer iterations cycles of fixer↔reviewer. If exceeded → step X.
```

Same loop logic. Context differs (architectural design vs code-analyst impact report). No explicit "`## NEEDS_DECOMPOSITION`" handling inside the loop in implement-feature.

### scaffold.md excerpt [source: lines 343–355, steps 7a+7b]

```
**7a. Fixer** (Task tool, model: opus):
    Context: subtask scope + acceptance criteria + architecture design + `Max build retries = {Build retries from CLAUDE.md, default 3}.`
    After completion: run Build command from generated CLAUDE.md
    If build fails → fixer fixes (max Build retries from CLAUDE.md, default 3)
    If still fails → Block handler

**7b. Reviewer** (Task tool, model: opus):
    Context: diff from fixer + acceptance criteria + `Max fixer iterations = {Fixer iterations from CLAUDE.md, default 5}.`
    If APPROVE → continue to 7c
    If REQUEST_CHANGES → back to fixer with feedback (max Fixer iterations, default 5)
    If BLOCK or max iterations exhausted → Block handler
```

Same loop. Key difference: config source is `generated CLAUDE.md` (not the parent project CLAUDE.md), and defaults are explicit (3, 5) since the config may not yet exist.

### Classification: analogous

All four commands run `ceos-agents:fixer` (opus) → `ceos-agents:reviewer` (opus) → REQUEST_CHANGES loops back → APPROVE continues. Max iteration limit from config. Exhausted → Block handler. Differences are: context content, step numbering, config source (generated vs parent CLAUDE.md in scaffold), and presence of `NEEDS_DECOMPOSITION` signal (fix-ticket and fix-bugs only).

### Extraction difficulty: medium

Loop logic extracts cleanly. Context strings are per-command and must remain parameterized.

---

## Pattern 6: Block Handler

### fix-ticket.md excerpt [source: lines 347–378, step X]

```
### X. Block handler

On block from fixer/reviewer/test-engineer/build/hook/custom agent:

1. **Rollback:** Run `ceos-agents:rollback-agent` (Task tool, model: haiku).
   Context: `Agent: {name}. Step: {step}. Reason: {reason}. Detail: {output}. Recommendation: {recommendation}. Execution context: CWD (no worktree).`
   - DO NOT rollback on block from triage/code-analyst — no git changes to revert

2. **Set issue state to Blocked** (State transitions → Blocked)

3. **On block action** (per Error Handling → On block):
   - `comment` (default): Add a Block comment to the issue tracker (see below)
   - `close`: Add a Block comment + close the issue
   - Other value: interpret as a custom action (always add a comment)

4. **Add Block comment** to the issue tracker:
   ```
   [ceos-agents] 🔴 Pipeline Block
   Agent: {agent name}
   Step: {pipeline step}
   Reason: {max 2 sentences}
   Detail: {error output}
   Recommendation: {what human should do}
   ```

5. **Webhook — issue-blocked:** If Notifications → Webhook URL exists and `issue-blocked` is in On events:
   ```bash
   curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
     -d '{"event":"issue-blocked","issue_id":"{issue}","agent":"{agent}","reason":"{reason}","timestamp":"{ISO8601}"}' \
     "{Webhook URL}"
   ```
```

### fix-bugs.md excerpt [source: lines 351–387, step X]

Identical steps 1–5. fix-bugs adds step 6 (absent in fix-ticket):

```
6. **Block counter:** Increment `block_count`. If `Max blocked per run` is not `unlimited` and `block_count >= Max blocked per run`:
   - Display: "Max blocked per run ({N}) reached. Remaining {M} bugs skipped."
   - Skip to step 9 (Summary) — DO NOT process remaining bugs.

7. Continue with next bug.
```

fix-bugs also has a minor context variant: `Execution context: {worktree_path if worktree mode} | CWD (if sequential).` vs fix-ticket's fixed `CWD (no worktree)`.

### implement-feature.md excerpt [source: lines 285–305, step X]

```
### X. Block handler

1. Run rollback-agent (Task tool, model: haiku) — revert git changes
2. Set issue state to Blocked (State transitions → Blocked)
3. **On block action** (per Error Handling → On block):
   - `comment` (default): Add a Block comment to the issue tracker (see below)
   - `close`: Add a Block comment + close the issue
   - Other value: interpret as a custom action (always add a comment)
4. Add Block comment to the issue tracker:
   [ceos-agents] 🔴 Pipeline Block
   Agent: {agent name}
   Step: {pipeline step}
   Reason: {max 2 sentences}
   Detail: {error output}
   Recommendation: {what human should do}
5. If Notifications → Webhook URL exists and On events contains `issue-blocked`:
   curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"issue-blocked","issue":"{issue_id}","agent":"{agent}","reason":"{reason}"}'
```

Same 5-step structure. Minor curl command difference: implement-feature uses shorter curl (no `--max-time 5 --retry 0`, uses `"issue"` not `"issue_id"`, no `"timestamp"`).

### scaffold.md excerpt [source: lines 370–384, inline in step 7]

```
**Block handler** (from 7a, 7b, or 7c):
  1. Run rollback-agent (Task tool, model: haiku) — revert to last successful commit
     Context: `"No issue tracker context — skip issue tracker updates."`
  2. Report block to stdout:
     ```
     [ceos-agents] 🔴 Pipeline Block
     Agent: {agent name}
     Step: {step}
     Reason: {reason}
     Detail: {output}
     Recommendation: {suggestion}
     ```
  3. Follow Fail strategy:
     - fail-fast → STOP pipeline, jump to Step 10 (report what was completed)
     - continue → skip subtask, proceed to next in batch
```

scaffold diverges significantly: no issue tracker state change, no webhook, output goes to stdout (not issue tracker), no `On block` config key, adds fail-strategy branching (fail-fast vs continue). The rollback-agent call is the only shared element.

### Classification: divergent

fix-ticket/fix-bugs/implement-feature share the same 5-step structure (rollback → set blocked state → On block action → block comment → webhook). fix-bugs adds a block counter. scaffold replaces the tracker steps with stdout output and fail-strategy logic. The Block comment template text is identical across all four.

### Extraction difficulty: hard

The common core (rollback-agent call + block comment template) is extractable. The outer steps diverge enough that a simple extraction would require parameterization for "has issue tracker" vs "no issue tracker" variants.

---

## Pattern 7: Agent Override Injection

### fix-ticket.md excerpt [source: lines 405–407, Rules section]

```
- Before dispatching any agent via Task tool, check if `{Agent Overrides path}/{agent-name}.md` exists.
  If yes, append its content to the agent's context as: "## Project-Specific Instructions\n{file content}".
```

### fix-bugs.md excerpt [source: lines 484–485, Rules section]

```
- Before dispatching any agent via Task tool, check if `{Agent Overrides path}/{agent-name}.md` exists.
  If yes, append its content to the agent's context as: "## Project-Specific Instructions\n{file content}".
```

### implement-feature.md excerpt [source: lines 313–314, Rules section]

```
- Before dispatching any agent via Task tool, check if `{Agent Overrides path}/{agent-name}.md` exists.
  If yes, append its content to the agent's context as: "## Project-Specific Instructions\n{file content}".
```

### scaffold.md excerpt [source: lines 488–490, Rules section]

```
- Before dispatching any agent via Task tool, check if `{Agent Overrides path}/{agent-name}.md` exists.
  If yes, append its content to the agent's context as: "## Project-Specific Instructions\n{file content}".
```

### Classification: identical

Word-for-word copy-paste in all four files. This is the only pattern that is fully identical across all four commands.

### Extraction difficulty: easy

Single-sentence extraction. The `{Agent Overrides path}` is already parameterized.

---

## Pattern 8: Post-publish Hook + Webhook

### fix-ticket.md excerpt [source: lines 301–314, steps 9a+9b]

```
### 9a. Post-publish hook

If the user chooses to publish and Hooks → Post-publish exists:
- Run after publisher
- Failure → warning only

### 9b. Webhook — PR created

If the user chooses to publish and Notifications → Webhook URL exists and `pr-created` is in On events:
```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"pr-created","issue_id":"{issue}","pr_url":"{url}","timestamp":"{ISO8601}"}' \
  "{Webhook URL}"
```
```

### fix-bugs.md excerpt [source: lines 290–304, steps 8a+8b]

```
### 8a. Post-publish hook

If Hooks → Post-publish exists:
- Run the command via Bash
- Failure → warning only (PR already exists, cannot rollback)

### 8b. Webhook — PR created

If Notifications → Webhook URL exists and `pr-created` is in On events:
```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"pr-created","issue_id":"{issue}","pr_url":"{url}","timestamp":"{ISO8601}"}' \
  "{Webhook URL}"
```
Failure → warning, must not stop the pipeline.
```

Curl command: **identical** between fix-ticket and fix-bugs. Failure explanation differs in wording.

### implement-feature.md excerpt [source: lines 261–266, step 10a]

```
#### 10a. Post-publish hook + webhook

If Hooks → Post-publish exists: run the command via Bash.
If Notifications → Webhook URL exists and On events contains `pr-created`:
```bash
curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"pr-created","issue":"{issue_id}","pr":"{pr_url}"}'
```
```

implement-feature combines hook + webhook into one step (not two). The curl command uses shorter format: no `--max-time 5 --retry 0`, uses `"issue"` (not `"issue_id"`), uses `"pr"` (not `"pr_url"`), no `"timestamp"`.

### scaffold.md

Explicitly absent. scaffold.md states at Step 7 [source: line 331]: "Note: Hooks (Pre-fix, Post-fix, Pre-publish, Post-publish) are not executed during scaffold because the project is being created from scratch..."

### Classification: divergent

Same concept (post-publish hook → webhook), but: fix-ticket/fix-bugs use two separate named steps and an identical, full curl command; implement-feature combines them and uses a shorter curl variant; scaffold skips the entire pattern.

### Extraction difficulty: medium

The hook logic (run → failure = warning) extracts cleanly. The webhook curl command has two variants (full vs abbreviated) — these differ in field names (`issue_id` vs `issue`, `pr_url` vs `pr`, presence of `timestamp`).

---

## Pattern 9: Fix Verification (Post-merge)

### fix-ticket.md excerpt [source: lines 324–346, step 9d]

```
### 9d. Fix Verification (optional)

If Build & Test → Verify exists in Automation Config:

1. Wait for PR merge (query via MCP server, max 5 attempts with 30s interval)
   - If PR is not merged after 5 attempts → display warning: "PR not merged yet. Run verify manually: {Verify command}"
   - If PR merged → continue
2. Checkout base branch and pull: `git checkout {base_branch} && git pull`
3. Run the Verify command from Automation Config
4. If verification OK → add a comment to the issue:
   [ceos-agents] ✅ Fix verified. Verify command: `{command}`. Output: {first 500 chars}.
5. If verification FAIL:
   - Add a comment to the issue: [ceos-agents] ❌ Fix verification failed. ...
   - If State transitions contains a key for re-open → set the state back
   - Display to the user: "Fix verification failed. Issue re-opened."
```

### fix-bugs.md excerpt [source: lines 306–320, step 8c]

```
### 8c. Fix Verification (optional, per-bug)

If Build & Test → Verify exists in Automation Config:

For EVERY successfully published bug in the current batch:
1. Wait for PR merge (query via MCP server, max 5 attempts with 30s interval)
   - If PR is not merged after 5 attempts → display warning: "PR not merged yet for {issue_id}. ..."
2. In the context of the given bug (worktree if parallel, CWD if sequential): checkout base branch and pull
3. Run the Verify command
4. If verification OK → add a comment to the issue: [ceos-agents] ✅ Fix verified. ...
5. If verification FAIL → add a comment and re-open the issue (see fix-ticket step 9d)

Run verification BEFORE processing the next batch (sequential mode) or BEFORE worktree cleanup (parallel mode).
```

fix-bugs adds the batch/worktree context and ordering note. The comment text is referenced back to fix-ticket rather than repeated.

### implement-feature.md excerpt [source: lines 268–283, step 10b]

```
### 10b. Feature Verification (optional)

If Build & Test → Verify exists in Automation Config:

1. Wait for PR merge (query via MCP server, max 5 attempts with 30s interval)
   - If PR is not merged after 5 attempts → display warning: "PR not merged yet. Run verify manually: {Verify command}"
2. Checkout base branch and pull: `git checkout {base_branch} && git pull`
3. Run the Verify command from Automation Config
4. If verification OK → add a comment to the issue:
   [ceos-agents] ✅ Feature verified. Verify command: `{command}`. Output: {first 500 chars}.
5. If verification FAIL:
   - Add a comment: [ceos-agents] ❌ Feature verification failed. ...
   - If State transitions contains a key for re-open → set the state back
   - Display to the user: "Feature verification failed. Issue re-opened."
```

implement-feature is structurally identical to fix-ticket. Only differences: step name ("Feature Verification" vs "Fix Verification"), comment text ("Feature verified" vs "Fix verified", "Feature verification failed" vs "Fix verification failed").

### scaffold.md

Absent. scaffold does not publish to a PR via publisher, and there is no post-merge verification step.

### Classification: analogous

fix-ticket and implement-feature are near-identical (5-step structure, same wait logic, same comment format, only text differs). fix-bugs is analogous but adds batch/worktree scoping. scaffold has no equivalent.

### Extraction difficulty: easy

Steps 1–5 extract to a template with parameters: `{verification_type}` = "Fix" | "Feature", `{issue_id}`, `{base_branch}`, `{Verify command}`, `{max_attempts}` = 5, `{interval}` = 30s.

---

## Pattern 10: Decomposition Heuristics

### fix-ticket.md excerpt [source: lines 117–158, steps 4a+4b]

```
### 4a. Decompose flag parsing
- `--decompose` → `decompose_mode = FORCE`
- `--no-decompose` → `decompose_mode = DISABLED`
- Neither → `decompose_mode = AUTO`

### 4b. Decomposition decision
If `decompose_mode = DISABLED` → skip to step 4d.
If `decompose_mode = FORCE` or `decompose_mode = AUTO`:

Evaluate the code-analyst output:
- `risk == HIGH` → DECOMPOSE
- `affected_files >= 4` → DECOMPOSE
- `estimated_diff_lines > 60 AND affected_files >= 3` → DECOMPOSE
- `independent_changes >= 2` → DECOMPOSE
- Otherwise and `decompose_mode = AUTO` → SINGLE_PASS
- Otherwise and `decompose_mode = FORCE` → DECOMPOSE
```

### fix-bugs.md excerpt [source: lines 105–148, steps 3a+3b]

```
### 3a. Decompose flag parsing
[identical tri-state logic]

### 3b. Decomposition decision (per-bug)
For each bug individually:
[identical 4 heuristic rules, identical SINGLE_PASS / FORCE logic]
```

fix-bugs adds "For each bug individually" scoping. The 4 heuristic thresholds are **word-for-word identical** to fix-ticket.

### implement-feature.md excerpt [source: lines 104–131, step 5]

```
### 5. Decomposition decision
If `decompose_mode = DISABLED` → single-pass (step 6 directly).
If `decompose_mode = FORCE` or `decompose_mode = AUTO` and architect indicates decomposition:

**Validate task tree:**
1. Check for cycles: go through all subtasks, find root (depends_on empty). If no root → cycle → Block.
2. Topological sort ...
3. Check max_subtasks limit.
4. Check: each subtask has title, scope, files, estimated_lines, acceptance_criteria.
```

implement-feature does NOT repeat the 4 code-analyst heuristics (risk/affected_files/estimated_diff_lines/independent_changes). The decision is delegated to the architect agent: "and architect indicates decomposition". implement-feature's step 5 instead focuses on task tree validation (cycle check, topological sort, field check) — absent in fix-ticket/fix-bugs.

### scaffold.md excerpt [source: lines 256–303, step 5]

```
### Step 5: Architecture & Decomposition
[...]
Read Decomposition config from generated CLAUDE.md:
  Max subtasks (default scaffold: 5 — lower than implement-feature's 7 ...)

Validate architect output:
  - Total subtasks <= Max subtasks
  - Dependencies form a DAG (no cycles)
  - Each subtask has: id, title, scope, files, estimated_lines, depends_on, acceptance_criteria
  If validation fails → Block.
```

scaffold always decomposes (the concept of SINGLE_PASS / DISABLED / AUTO tri-state is absent). No heuristic thresholds at all. Architect receives all epics and is instructed to decompose everything. The validation logic (DAG check + field check) is shared with implement-feature but not with fix-ticket/fix-bugs.

### AC Coverage Check sub-pattern

All four commands include an AC coverage check after decomposition:

fix-ticket [lines 149–158], fix-bugs [lines 139–148]: identical 4-step check (collect parent AC, collect maps_to, compute set difference, warn or block). YOLO behavior: fix-ticket uses `--yolo`, fix-bugs uses "if mode is YOLO".

implement-feature [lines 117–131]: same 4 steps, plus the AC matching algorithm is explicitly spelled out (index-based, text is informational).

scaffold [lines 295–303]: same 4 steps per-epic. "if mode is Full YOLO → Block" vs ask user.

### Classification: analogous (with divergent sub-patterns)

The tri-state flag parsing (FORCE/DISABLED/AUTO) and the 4 heuristic rules are identical between fix-ticket and fix-bugs. implement-feature delegates to architect rather than using explicit thresholds. scaffold uses no heuristics at all. Task tree validation (DAG + field check) is shared between implement-feature and scaffold but absent from fix-ticket/fix-bugs. AC coverage check is present in all four, nearly identical.

### Extraction difficulty: hard

Three distinct sub-patterns: (a) flag tri-state — easy to extract, (b) heuristic thresholds — only in fix-ticket/fix-bugs, (c) task tree validation — shared between implement-feature and scaffold. These would need to be composed selectively.

---

## resume-ticket Step Number References

resume-ticket maps checkpoints to step numbers in the commands it delegates to. All references are to fix-ticket and implement-feature steps:

| Checkpoint | Bug pipeline (→ fix-ticket) | Feature pipeline (→ implement-feature) |
|-----------|----------------------------|---------------------------------------|
| `DECOMPOSE_PARTIAL` | continue from next subtask per task tree | continue from next subtask per task tree |
| `FRESH` | full `/fix-ticket` flow | full `/implement-feature` flow |
| `POST_TRIAGE` | start from code-analyst (step 4) | start from architect (spec-analyst already done) |
| `POST_ANALYSIS` | start from fixer (step 5) | start from fixer (decomposition/architect already done) |
| `POST_FIX` | start from reviewer (step 7) | start from reviewer (step 7) |
| `POST_REVIEW` | start from test-engineer (step 8) | start from test-engineer (step 8) |
| `PUBLISHED` | display PR URL | display PR URL |

Source: resume-ticket.md lines 73–89.

Key observations:
- resume-ticket references step numbers from **fix-ticket** specifically (step 4 = code-analyst, step 5 = fixer, step 7 = reviewer, step 8 = test-engineer).
- fix-bugs uses different step numbers for the same agents (step 3 = code-analyst, step 4 = fixer, step 6 = reviewer, step 7 = test-engineer) — resume-ticket does NOT delegate to fix-bugs (single-ticket resume only).
- resume-ticket has no reference to scaffold — scaffold has no resume pathway.
- Pipeline type detection [source: lines 63–67]: presence of `[ceos-agents] Spec analysis completed.` comment → FEATURE; `[ceos-agents] Triage completed.` → BUG; default → BUG.

---

## Mode-Specific Logic (NOT shared)

### fix-ticket.md only

- Dry-run mode: three-step dry-run (steps 1, 3, 4 only), dry-run report format (single-issue Markdown block with severity/area/affected files). Source: lines 83–84, 379–395.
- NEEDS_DECOMPOSITION signal handling (at fixer step): authoritative revert + conditional re-decompose. Source: lines 208–213.
- Worktree: none — explicitly "Work in CWD, no worktrees". Source: line 399.
- Publisher is invoked at step 9 only if user chooses to publish (or --yolo). Source: lines 297–299.
- Token usage estimate is a single fixed block (~119,000 tokens). Source: lines 317–322.

### fix-bugs.md only

- Worktree processing: Variant A (parallel via git worktree) and Variant B (sequential CWD). Source: lines 389–434.
- Batch processing with cleanup. Source: lines 426–431.
- Block counter + Max blocked per run enforcement. Source: lines 383–386.
- Summary table (step 9) with per-bug status, PR, worktree, block reason. Source: lines 322–333.
- Pipeline-complete webhook event (`pipeline-complete`). Source: lines 342–349.
- Token estimate is calculated as N_issues × 119,000. Source: lines 336–340.
- Publisher runs automatically (no user gate) at step 8. Source: lines 285–288.

### implement-feature.md only

- Spec-analyst agent (step 3): reads feature spec, posts AC writeback to issue tracker. Source: lines 83–94.
- Architect agent (step 4): generates architectural design + task tree from spec. Source: lines 96–102.
- Feature Workflow config section (On start set fallback). Source: lines 75–77.
- Acceptance gate runs always within subtask loop for features (no conditional threshold). Source: lines 208–213.
- Integration step after all subtasks (squash commit for feat:). Source: lines 228–238.
- No browser reproduction or browser verification steps.

### scaffold.md only

- Brainstorming phase with anti-bias rules. Source: lines 149–172.
- State detection (empty dir / existing project without CLAUDE.md / existing with CLAUDE.md / git repo with uncommitted changes). Source: lines 40–47.
- Mode selection (Interactive / YOLO with checkpoint / Full YOLO). Source: lines 56–64.
- --no-implement legacy flow (v3.x): stack-selector → scaffolder → validate → move → git init → report. Source: lines 66–145.
- spec/ folder creation and spec-writer ↔ spec-reviewer loop. Source: lines 175–205.
- Spec Checkpoint (step 2) and Feature Plan Checkpoint (step 6). Source: lines 207–219, 304–327.
- Scaffolder generates into temp directory (`mktemp -d`) + safety check before rm -rf. Source: lines 78–82, 222–242.
- Spec Compliance Check via spec-reviewer --verify mode. Source: lines 391–402.
- Issue tracker card creation (Step 9): epics and sub-issues created from spec/epics/*.md. Source: lines 421–437.
- Block comments go to stdout (not issue tracker). Source: lines 374–381.
- No post-publish hook, no webhook, no publisher agent, no PR creation.
- Hooks are explicitly skipped during the entire scaffold pipeline. Source: line 331.
