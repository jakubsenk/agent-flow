# Agent 3 — Scaffold Documentation Audit

**Task:** Find every scaffold-related section in all documentation files. Quote exact content with line numbers. Note which files mention removed steps (4b, 4c, 9), which have mermaid diagrams, and what changes are needed.

---

## 1. CLAUDE.md

**File:** `CLAUDE.md`

### Scaffold Pipeline section (lines 63–77)

```
63: ## Scaffold Pipeline
64:
65: ```
66: User description → [Mode selection] → SPEC-WRITER ↔ SPEC-REVIEWER (opus)
67:   → [Spec checkpoint] → SCAFFOLDER (sonnet, +test infrastructure, +scorecard)
68:   → Validate → Git init
69:   → ARCHITECT (opus, +maps_to) → [Feature plan checkpoint]
70:   → FIXER ↔ REVIEWER (opus) → TEST ENGINEER (sonnet)
71:   → [Spec compliance check (spec-reviewer --verify)]
72:   → E2E-TEST-ENGINEER (sonnet) → Final report
73: ```
74:
75: With `--no-implement`: `STACK-SELECTOR (sonnet) → SCAFFOLDER (sonnet) → Validate → Git init` (v3.x behavior).
76:
77: In scaffold v2 mode, the specification is saved as a `spec/` folder in the project root (spec/README.md, spec/architecture.md, spec/verification.md, spec/epics/*.md). This folder is the single source of truth for all downstream agents.
```

**Assessment:**
- Does NOT mention steps 4b, 4c, or 9 — uses an abstract pipeline diagram
- No mermaid diagram — plain text ASCII diagram
- The diagram omits the infrastructure steps entirely (4b, 4c, 9). After the design change these steps are removed; the diagram would need no step-level changes, but it also does not mention the new Step 0-INFRA / Step 0-MCP
- **Change needed:** The abstract pipeline text is still accurate at a high level, but after the design removes steps 4b/4c/9 and adds 0-INFRA/0-MCP/4d/4e, the line `→ Git init` now implicitly includes more sub-steps. No mandatory change, but an optional note about infrastructure steps at Step 4 would improve accuracy.

---

## 2. README.md

**File:** `README.md`

### Scaffold Pipeline mermaid diagram (lines 110–128)

```
110: ### Scaffold Pipeline
111:
112: ```mermaid
113: flowchart TD
114:     Desc["Project Description<br/><i>natural language</i>"] --> Mode["Mode Selection<br/><i>Interactive · YOLO · Full YOLO</i>"]
115:     Mode --> Spec["Spec Writer ↔ Spec Reviewer<br/><i>opus · up to 5 iterations</i>"]
116:     Spec --> Scaffolder["Scaffolder<br/><i>sonnet</i>"]
117:     Scaffolder --> Git["Git Init + Commit"]
118:     Git --> Arch["Architect<br/><i>opus</i>"]
119:     Arch --> Impl["Fixer ↔ Reviewer<br/><i>opus · per subtask</i>"]
120:     Impl --> Test["Test Engineer + E2E<br/><i>sonnet</i>"]
121:     Test --> Report["Final Report ✓"]
122:     style Desc fill:#fff8f0,stroke:#c47a20
123:     style Report fill:#e0ffe0,stroke:#00cc00
124: ```
125:
126: With `--no-implement`: Stack Selector → Scaffolder → Validate → Git Init (v3.x skeleton only).
127:
128: Hook integration points (pre-fix, post-fix, pre-publish, post-publish) and pipeline profiles are supported. See [Pipeline Reference](docs/reference/pipelines.md) for full details.
```

### What it does section referencing scaffold (lines 42–45)

```
42: - **Project scaffolding (v2)** — Describe a project in natural language. Get a specification, buildable skeleton, and fully implemented features with tests.
...
44: - **Scaffold v2** — Describe a project → get a specification, skeleton, and fully implemented features with tests. Three modes: Interactive, YOLO with checkpoint, Full YOLO.
```

### Commands table scaffold entry (line 140)

```
140: | `/scaffold` | Create a new project — specification, skeleton, feature implementation, git init |
```

**Assessment:**
- Does NOT mention steps 4b, 4c, or 9 explicitly — uses high-level node names
- Has a mermaid flowchart diagram (`flowchart TD`)
- The `Git["Git Init + Commit"]` node does not reflect the new infrastructure sub-steps (0-INFRA, 0-MCP, 4d, 4e)
- The diagram omits Step 0-INFRA (Infrastructure Declaration) and Step 0-MCP (MCP Verification), which now precede Mode Selection
- **Change needed:**
  1. Add `InfraDecl["Infrastructure Declaration<br/><i>tracker · source control</i>"]` node before `Mode` node
  2. `Mode["Mode Selection..."]` should follow `InfraDecl`
  3. `Git["Git Init + Commit"]` node label or a successor node should reflect Push + Create Issues
  4. The diagram currently flows `Desc → Mode`, but with the design change it should be `Desc → InfraDecl → Mode`

---

## 3. docs/architecture.md

**File:** `docs/architecture.md`

### Scaffold Pipeline section (lines 114–135)

```
114: ### Scaffold Pipeline
115:
116: The scaffold pipeline creates a new project from scratch. In v2 mode (default), it generates a specification, builds the skeleton, and implements all features:
117:
118: ```mermaid
119: graph LR
120:   A[User description] --> B[Mode selection]
121:   B --> C[SPEC-WRITER ↔ SPEC-REVIEWER<br/>opus]
122:   C --> D[SCAFFOLDER<br/>sonnet]
123:   D --> E[Git init]
124:   E --> F[ARCHITECT<br/>opus]
125:   F --> G[FIXER ↔ REVIEWER<br/>opus]
126:   G --> H[TEST + E2E<br/>sonnet]
127: ```
128:
129: Key characteristics:
130: - Three modes: Interactive (Q&A), YOLO with checkpoint (autonomous + approval), Full YOLO (fully autonomous)
131: - Spec-writer ↔ spec-reviewer loop refines the specification (max 5 iterations)
132: - Scaffolder reads tech stack from spec/README.md (v2 mode) or stack-selector (--no-implement)
133: - Architect decomposes epics into dependency-aware batches
134: - Features are implemented per-subtask with fixer/reviewer/test-engineer
135: - With `--no-implement`: stack-selector → scaffolder → validate → git init (v3.x behavior)
```

**Assessment:**
- Does NOT mention steps 4b, 4c, or 9 by name — uses abstract node labels
- Has a mermaid diagram (`graph LR`)
- The `A[User description] --> B[Mode selection]` flow is now inaccurate: the design inserts Step 0-INFRA and Step 0-MCP before Mode Selection
- The `D --> E[Git init]` node omits the new infrastructure steps that run after/during Git init (auto-fill config, `.mcp.json` generation, push to remote, create tracker issues)
- Key characteristics bullet points do not mention infrastructure declaration
- **Change needed:**
  1. Add node between `A[User description]` and `B[Mode selection]`: e.g. `A --> A2[Infrastructure Declaration] --> B[Mode selection]`
  2. Expand `E[Git init]` to reflect that Git init now also auto-fills config, generates `.mcp.json`, and optionally pushes/creates issues
  3. Add bullet to Key characteristics: "Infrastructure declaration (tracker + SC) at start — verified before Mode Selection"

---

## 4. docs/reference/pipelines.md

**File:** `docs/reference/pipelines.md`

### Scaffold Pipeline section heading (line 202–204)

```
202: ## Scaffold Pipeline
203:
204: The scaffold pipeline creates a new project from scratch. In v2 mode (default), it generates a specification, builds the skeleton, and implements all features. It is invoked by `/ceos-agents:scaffold`.
```

### Scaffold v2 Pipeline mermaid diagram (lines 206–265)

```
206: ### Scaffold v2 Pipeline (default)
207:
208: ```mermaid
209: flowchart TD
210:     START([Start]) --> DETECT{Detect<br/>Directory State}
211:     DETECT -->|Empty| MODE{Mode<br/>Selection}
212:     DETECT -->|Has project, no CLAUDE.md| SUGGEST_ADD["Suggest /scaffold-add"]
213:     DETECT -->|Has CLAUDE.md| SUGGEST_FEATURE["Suggest /implement-feature"]
214:     DETECT -->|Uncommitted changes| WARN[Warn User]
215:
216:     MODE -->|Interactive| SPEC_INTERACTIVE[Spec Phase<br/>Interactive Q&A]
217:     MODE -->|YOLO checkpoint| SPEC_YOLO[Spec Phase<br/>Autonomous]
218:     MODE -->|Full YOLO| SPEC_FULL[Spec Phase<br/>Autonomous]
219:
220:     SPEC_INTERACTIVE --> SPEC_LOOP{spec-writer ↔<br/>spec-reviewer}
221:     SPEC_YOLO --> SPEC_LOOP
222:     SPEC_FULL --> SPEC_LOOP
223:
224:     SPEC_LOOP -->|APPROVE| CHECKPOINT_SPEC{Spec<br/>Checkpoint}
225:     SPEC_LOOP -->|MAX ITER| USER_DECIDE[User Decides]
226:
227:     CHECKPOINT_SPEC -->|Skip in Full YOLO| SCAFFOLD
228:     CHECKPOINT_SPEC -->|Approve| SCAFFOLD
229:     CHECKPOINT_SPEC -->|Abort| STOP([Stopped])
230:
231:     SCAFFOLD[Generate Skeleton<br/>scaffolder] --> VALIDATE{Validate<br/>Build + Test + Lint}
232:     VALIDATE -->|PASS| GIT_INIT[Git Init + Commit]
233:     VALIDATE -->|FAIL| RETRY_S{Retries?}
234:     RETRY_S -->|YES| SCAFFOLD
235:     RETRY_S -->|NO| FAIL_REPORT([Report Failure])
236:
237:     GIT_INIT --> ARCHITECT[Architecture<br/>architect]
238:     ARCHITECT --> CHECKPOINT_PLAN{Feature Plan<br/>Checkpoint}
239:
240:     CHECKPOINT_PLAN -->|Skip in Full YOLO| IMPL
241:     CHECKPOINT_PLAN -->|Approve| IMPL
242:     CHECKPOINT_PLAN -->|Abort| STOP
243:
244:     subgraph IMPL [Feature Implementation Loop]
245:         direction TB
246:         FIXER[Fix<br/>fixer] --> REVIEWER{Review<br/>reviewer}
247:         REVIEWER -->|APPROVE| TEST[Test<br/>test-engineer]
248:         REVIEWER -->|REQUEST_CHANGES| FIXER
249:         TEST --> COMMIT[Commit Subtask]
250:     end
251:
252:     IMPL --> BATCH_TEST{Batch Tests<br/>Pass?}
253:     BATCH_TEST -->|YES| E2E[E2E Tests<br/>e2e-test-engineer]
254:     BATCH_TEST -->|NO| FIXER_REPAIR[Fixer Repairs]
255:
256:     E2E --> TRACKER{Issue Tracker<br/>Cards?}
257:     TRACKER --> REPORT([Final Report])
258:
259:     style FAIL_REPORT fill:#EF4444,color:#fff
260:     style REPORT fill:#22C55E,color:#fff
261:     style STOP fill:#6B7280,color:#fff
262:     style SUGGEST_ADD fill:#F59E0B,color:#000
263:     style SUGGEST_FEATURE fill:#F59E0B,color:#000
264:     style WARN fill:#F59E0B,color:#000
265: ```
```

### Stages table (lines 268–282)

```
268: ### Stages
269:
270: | Step | Stage | Agent | Model | Notes |
271: |------|-------|-------|-------|-------|
272: | 0 | Mode Selection | (command) | N/A | Interactive / YOLO with checkpoint / Full YOLO |
273: | 1 | Specification | spec-writer ↔ spec-reviewer | opus | Loop up to Spec iterations (default 5) |
274: | 2 | Spec Checkpoint | (command) | N/A | Skip in Full YOLO; user approves or aborts |
275: | 3 | Skeleton Generation | scaffolder | sonnet | Reads tech stack from spec/README.md; generates E2E Test + Decomposition config |
276: | 4 | Git Init | (command) | N/A | Commits both spec/ and skeleton |
277: | 5 | Architecture | architect | opus | Decomposes epics into dependency-aware batches |
278: | 6 | Feature Plan Checkpoint | (command) | N/A | Skip in Full YOLO; user approves batch plan |
279: | 7 | Feature Implementation | fixer ↔ reviewer + test-engineer | opus/sonnet | Per-subtask loop with block handler + rollback |
280: | 8 | E2E Tests | e2e-test-engineer | sonnet | Covers critical user flows from spec |
281: | 9 | Issue Tracker | (command) | N/A | Optional — create cards from spec/epics/ |
282: | 10 | Final Report | (command) | N/A | Summary with features, tests, TODOs |
```

### Legacy Mode section (lines 283–294)

```
283: ### Legacy Mode (--no-implement)
284:
285: With `--no-implement`, the scaffold pipeline falls back to v3.x behavior: stack-selector → scaffolder → validate → git init → report. No specification phase, no feature implementation.
286:
287: | Stage | Agent | Model | Notes |
288: |-------|-------|-------|-------|
289: | Directory Detection | (command) | N/A | Guards against overwriting existing projects |
290: | Stack Selection | stack-selector | sonnet | Picks one option per category; respects `--lang`, `--framework`, `--db`, `--ci` flags |
291: | Skeleton Generation | scaffolder | sonnet | Writes to temp directory; includes CLAUDE.md with Automation Config |
292: | Validation | (command) | N/A | Build + test + lint + CLAUDE.md structure check; max 3 retries |
293: | Copy to Target | (command) | N/A | Copies validated skeleton to target directory |
294: | Git Init | (command) | N/A | `git init` + initial commit |
```

**Assessment:**
- **Step 9 is explicitly present** at line 281: `| 9 | Issue Tracker | (command) | N/A | Optional — create cards from spec/epics/ |`
- The mermaid diagram at line 256 has a `TRACKER{Issue Tracker<br/>Cards?}` node after E2E — this represents the old Step 9 behavior
- Steps 4b and 4c are NOT shown in the stages table or diagram (they exist only in `commands/scaffold.md`, not in this doc)
- **Changes needed:**
  1. **Mermaid diagram:** Remove `TRACKER{Issue Tracker<br/>Cards?}` node and its edge. Add a new `INFRA_DECL[Infrastructure Declaration]` node at the start (before `DETECT`). Add new Step 4 sub-nodes: `PUSH[Push to Remote]` and `CREATE_ISSUES[Create Tracker Issues]` after `GIT_INIT`.
  2. **Stages table:**
     - Add new rows before Step 0: `0-INFRA | Infrastructure Declaration | (command) | N/A | Tracker + SC readiness; collects details` and `0-MCP | MCP Verification | (command) | N/A | Verify connectivity for declared services`
     - Update Step 4 row: add sub-steps 4d (Push to Remote) and 4e (Create Tracker Issues) as new rows, or expand Step 4 Notes
     - **Remove Step 9 row** (`| 9 | Issue Tracker | ...`)
  3. Flow change: the `E2E --> TRACKER --> REPORT` chain becomes `E2E --> REPORT` (Step 9 removed from end of pipeline)

---

## 5. docs/reference/commands.md

**File:** `docs/reference/commands.md`

### /scaffold command section (lines 194–229)

```
194: ### /scaffold
195:
196: > Creates a new project from scratch — specification, tech stack, skeleton, feature implementation, validation, git init.
197:
198: **Syntax:**
199:
200: ```
201: /ceos-agents:scaffold <description> [--template <path>] [--spec <path>] [--issue <ID>] [--no-implement] [--lang <language>] [--framework <framework>] [--db <database>] [--ci <provider>]
202: ```
203:
204: **Arguments:**
205: - `<description>` — Required (unless --spec, --template, or --issue provided). Natural language description of the project.
206:
207: **Flags:**
208: - `--template <path>` — Use a custom specification template
209: - `--spec <path>` — Use a ready specification (skip spec-writer, spec-reviewer validates)
210: - `--issue <ID>` — Read project description from issue tracker card
211: - `--no-implement` — Skeleton only, no specification or feature implementation (v3.x behavior)
212: - `--lang <language>` — Preset language (e.g., `python`, `typescript`)
213: - `--framework <framework>` — Preset framework (e.g., `fastapi`, `express`)
214: - `--db <database>` — Preset database (e.g., `postgresql`, `mongodb`)
215: - `--ci <provider>` — Preset CI provider (e.g., `github`, `gitea`)
216:
217: **Input source flags** (`--spec`, `--template`, `--issue`) are mutually exclusive. Tech stack flags (`--lang`, `--framework`, `--db`, `--ci`) are compatible with all input sources.
218:
219: **What it does:** In v2 mode (default), the user selects a mode (Interactive, YOLO with checkpoint, Full YOLO), then spec-writer generates a project specification with spec-reviewer quality gate, scaffolder generates the skeleton, and the feature pipeline (architect → fixer/reviewer/test-engineer) implements all features from the spec. With `--no-implement`, falls back to v3.x behavior: stack-selector → scaffolder → skeleton only.
220:
221: **Example:**
222:
223: ```
224: /ceos-agents:scaffold "REST API for user management with auth and roles" --lang python
225: ```
226:
227: **Note:** Use `--no-implement` for v3.x skeleton-only behavior without specification or feature implementation.
228:
229: **Related commands:** [/scaffold-add](#scaffold-add), [/scaffold-validate](#scaffold-validate), [/implement-feature](#implement-feature)
```

**Assessment:**
- Does NOT mention steps 4b, 4c, or 9 — describes only at a high level
- No mermaid diagram
- The "What it does" description (line 219) says: "the user selects a mode (Interactive, YOLO with checkpoint, Full YOLO), then spec-writer generates..." — this is now inaccurate; Infrastructure Declaration comes before Mode Selection
- **Change needed:** Update "What it does" paragraph to mention infrastructure declaration first: "First, the user declares infrastructure readiness (issue tracker + source control). Then the user selects a mode..."

---

## 6. docs/getting-started.md

**File:** `docs/getting-started.md`

Scaffold is mentioned only as part of feature descriptions and command references. No scaffold pipeline step details are present.

### Relevant references (lines 43, 196, 198, 224)

```
43:  - **Project scaffolding (v2)** — (in prerequisites, not detailed steps)
196: ## Step 5: Implement Your First Feature
...
198: /ceos-agents:implement-feature PROJ-50
...
224: - **[Command Reference](reference/commands.md)** — Explore all 25 commands...
```

No scaffold pipeline steps, mermaid diagrams, or step number references (4b, 4c, 9) appear in this file.

**Assessment:**
- No changes needed regarding removed steps.

---

## 7. docs/guides/installation.md

**File:** `docs/guides/installation.md`

Scaffold is not mentioned. The file covers SSH/HTTPS access, plugin installation, and project setup steps (`.mcp.json`, `check-setup`).

**Assessment:**
- No scaffold content.
- No changes needed.

---

## 8. docs/guides/mcp-configuration.md

**File:** `docs/guides/mcp-configuration.md`

Scaffold is not mentioned. The file covers MCP server configuration for YouTrack, Gitea/Forgejo, GitHub, Jira, Linear, and Redmine.

**Assessment:**
- No scaffold content.
- No changes needed.

---

## 9. Other docs/guides/ files

### docs/guides/custom-agents.md (line 64)

```
64: **Execution agents** modify code, create files, or interact with external systems. Built-in execution agents: fixer, test-engineer, e2e-test-engineer, publisher, scaffolder, rollback-agent.
```

Only mentions `scaffolder` as an agent name — no pipeline step references.

**Assessment:**
- No changes needed.

### docs/guides/cross-platform.md, tokens.md, troubleshooting.md

Searched — no scaffold pipeline step references found.

---

## 10. commands/scaffold.md (source of truth for current implementation)

**File:** `commands/scaffold.md`

This is the actual command implementation. It contains the full pipeline with all step numbers.

### Steps present in current implementation:
- Step 0: Mode Selection (line 51)
- Step 0b: Brainstorming Phase (line 151)
- Step 1: Specification Phase (line 177)
- Step 2: Spec Checkpoint (line 212)
- Step 3: Scaffold Skeleton (line 226)
- Step 4: Git Init (line 251)
- **Step 4b: Tracker Configuration (Auto-Finalize)** (line 263) — MARKED FOR REMOVAL
- **Step 4c: MCP Guidance** (line 303) — MARKED FOR REMOVAL
- Step 5: Architecture & Decomposition (line 309)
- Step 6: Feature Plan Checkpoint (line 359)
- Step 7: Feature Implementation Loop (line 384)
- Step 7b: Spec Compliance Check (line 451)
- Step 8: E2E Tests (line 464)
- **Step 9: Issue Tracker (Optional)** (lines 481–498) — MARKED FOR REMOVAL
- Step 10: Final Report (line 503)

**Assessment:**
- Steps 4b, 4c, and 9 are all present in this file
- This file requires the heaviest changes per the design doc:
  - Remove Step 4b (lines 263–298)
  - Remove Step 4c (lines 303–307)
  - Remove Step 9 (lines 481–498)
  - Add Step 0-INFRA before Step 0
  - Add Step 0-MCP after Step 0-INFRA
  - Extend Step 4 with auto-fill, `.mcp.json` generation
  - Add Step 4d (Push to Remote)
  - Add Step 4e (Create Tracker Issues)
  - Update Step 10 Final Report to show infrastructure status

---

## 11. docs/plans/2026-03-27-scaffold-infrastructure-design.md (NEW — untracked)

**File:** `docs/plans/2026-03-27-scaffold-infrastructure-design.md`
**Git status:** Untracked (new file, not yet committed)

This is the design document for the proposed changes. It defines what needs to be changed.

### Key sections:

**Removed Steps (lines 105–109):**
```
105: ### Removed Steps
106:
107: - **Step 4b** (Tracker Configuration) → replaced by Step 0-INFRA + Step 4 auto-fill
108: - **Step 4c** (MCP Guidance) → replaced by Step 0-MCP inline `/init`
109: - **Step 9** (Issue Tracker Optional) → replaced by Step 4e (moved before implementation)
```

**Impact table (lines 117–131):**
```
117: ## Impact on Existing Steps
118:
119: | Step | Change |
120: |------|--------|
121: | Step 0 (Mode Selection) | Moves after Step 0-INFRA and Step 0-MCP |
122: | Step 0b (Brainstorming) | No change |
123: | Step 1 (Specification) | No change — `--issue` input source works as before |
124: | Step 2 (Spec Checkpoint) | No change |
125: | Step 3 (Scaffold Skeleton) | No change |
126: | Step 4 (Git Init) | Extended with auto-fill + `.mcp.json` generation |
127: | Step 4b | **REMOVED** — replaced by Step 0-INFRA |
128: | Step 4c | **REMOVED** — replaced by Step 0-MCP |
129: | Step 4d | **NEW** — Push to remote |
130: | Step 4e | **NEW** — Create tracker issues (moved from Step 9) |
131: | Step 5-8 | No change |
132: | Step 9 | **REMOVED** — replaced by Step 4e |
133: | Step 10 (Report) | Updated to show infrastructure status |
```

---

## Summary Table

| File | Has Scaffold Section | Has Mermaid | Mentions 4b | Mentions 4c | Mentions Step 9 | Changes Required |
|------|---------------------|-------------|-------------|-------------|-----------------|------------------|
| `CLAUDE.md` | Yes (lines 63–77) | No (ASCII) | No | No | No | Optional: note infrastructure at Git init |
| `README.md` | Yes (lines 110–128) | Yes (flowchart TD) | No | No | No | Add 0-INFRA node before Mode; expand Git Init node |
| `docs/architecture.md` | Yes (lines 114–135) | Yes (graph LR) | No | No | No | Add INFRA node before Mode; expand Git init |
| `docs/reference/pipelines.md` | Yes (lines 202–294) | Yes (flowchart TD) | No | No | **YES (line 281)** | Remove Step 9 row + TRACKER node; add 0-INFRA/0-MCP steps; add 4d/4e rows |
| `docs/reference/commands.md` | Yes (lines 194–229) | No | No | No | No | Update "What it does" paragraph |
| `docs/getting-started.md` | Minimal mention only | No | No | No | No | No changes needed |
| `docs/guides/installation.md` | No | No | No | No | No | No changes needed |
| `docs/guides/mcp-configuration.md` | No | No | No | No | No | No changes needed |
| `commands/scaffold.md` | Full implementation | No | **YES (line 263)** | **YES (line 303)** | **YES (line 481)** | Primary change target — remove 4b/4c/9, add 0-INFRA/0-MCP/4d/4e |

---

## Files Requiring Mermaid Diagram Updates

### README.md — lines 112–124
Current flow: `Desc → Mode → Spec → Scaffolder → Git Init → Arch → Impl → Test → Report`
Required change: Insert `InfraDecl` node before `Mode`. Optionally add Push/CreateIssues after Git Init.

### docs/architecture.md — lines 118–127
Current flow: `A[User description] → B[Mode selection] → C[SPEC-WRITER] → D[SCAFFOLDER] → E[Git init] → F[ARCHITECT] → G[FIXER] → H[TEST]`
Required change: Insert `A2[Infrastructure Declaration]` between `A` and `B`.

### docs/reference/pipelines.md — lines 208–265
Current flow includes: `E2E --> TRACKER{Issue Tracker Cards?} --> REPORT`
Required changes:
1. Remove `TRACKER` node and its edges (Step 9 removal)
2. Replace `E2E --> TRACKER --> REPORT` with `E2E --> REPORT`
3. Add `INFRA_DECL[Infrastructure Declaration]` between `DETECT -->|Empty|` and `MODE`
4. Add nodes after `GIT_INIT`: `GIT_INIT --> PUSH[Push to Remote<br/>(if SC ready)]` and `GIT_INIT --> CREATE_ISSUES[Create Tracker Issues<br/>(if tracker ready)]` before `ARCHITECT`

### docs/reference/pipelines.md — Stages table (lines 270–282)
Required changes to stages table:
- **Remove** row: `| 9 | Issue Tracker | (command) | N/A | Optional — create cards from spec/epics/ |`
- **Add** new rows before Step 0:
  - `| 0-INFRA | Infrastructure Declaration | (command) | N/A | User declares tracker + SC readiness; collects details |`
  - `| 0-MCP | MCP Verification | (command) | N/A | Verify connectivity for declared services; inline /init offer |`
- **Update** Step 0 row to clarify it follows after 0-INFRA and 0-MCP
- **Update** Step 4 row or add sub-rows:
  - `| 4 | Git Init + Auto-Config | (command) | N/A | Commits spec/ + skeleton; auto-fills CLAUDE.md; generates .mcp.json |`
  - `| 4d | Push to Remote | (command) | N/A | Only if SC declared ready; WARN on failure |`
  - `| 4e | Create Tracker Issues | (command) | N/A | Only if tracker declared ready; creates epics + sub-issues |`
