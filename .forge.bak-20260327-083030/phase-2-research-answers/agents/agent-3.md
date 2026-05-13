# Research Answers — Agent 3

## RQ-09: Setup-validation gate before the feature loop

**Question:** At what point should a configuration validity gate run before the first implement-feature call?

**Answer:**

Currently, `commands/implement-feature.md` has a single validation gate: **Step 0 — MCP pre-flight check** (defined in `core/mcp-preflight.md`). This check fires before any pipeline operation and verifies only that the MCP tool for the configured tracker type is reachable and responds to a lightweight connectivity test. If unavailable, the pipeline stops with a prompt to run `/ceos-agents:check-setup`.

`commands/check-setup.md` performs a much broader validation (4 blocks: Automation Config structure, MCP server presence, live connectivity, Build & Test execution) but it is a standalone command — it is never called inline by `implement-feature`. The only link is that `commands/status.md` checks for a `.claude/setup-validated` marker and suggests running `check-setup` if it is absent, but this is advisory only — no command ever writes that marker or enforces it.

**Where a new gate should be inserted:**

A configuration validity gate should run **immediately after the MCP pre-flight check and before Step 1 (Set issue state)**, as a new **Step 0b: Config validity check**. This is the natural position because:

1. The MCP check (Step 0) already establishes that the tracker is reachable — connectivity is a prerequisite for config validation.
2. Steps 1 onward begin mutating issue state in the tracker and creating git branches — any config error discovered after that point causes partial side effects.
3. The gate can be lightweight: validate that all required Automation Config keys in `implement-feature.md` (Issue Tracker, Source Control, PR Rules, PR Description Template, Build & Test) are present and non-placeholder, without running build/test commands. This mirrors Block 1 of `check-setup.md` but without Blocks 3–4.

**What already exists vs. what is missing:**

| Validation | check-setup | implement-feature (current) |
|------------|-------------|----------------------------|
| Automation Config structure | Block 1 (full) | None |
| MCP tool present + responsive | Block 2+3 | Step 0 (MCP preflight only) |
| Build & test smoke | Block 4 | None |
| Plugin conflict detection | Block 5 | None |

A new gate at Step 0b needs only Automation Config structure validation (Block 1 equivalent). Build/test smoke is inappropriate pre-flight for every invocation; plugin conflict detection is optional.

**Confidence:** HIGH

**Relevant files:**
- `commands/implement-feature.md` lines 58–65 (Step 0, MCP pre-flight)
- `core/mcp-preflight.md` (full spec)
- `commands/check-setup.md` lines 14–46 (Block 1 — Automation Config)
- `commands/status.md` lines 47–49 (setup-validated marker reference)

---

## RQ-10: Cross-run parent/child relationship tracking in state schema

**Question:** Should a `parent_run_id` field be added to state schema for scaffold→feature lineage?

**Answer:**

**No `parent_run_id` field currently exists** in the state schema. `state/schema.md` defines the full schema (schema_version 1.0) and lists every top-level field; there is no `parent_run_id`, `origin_run_id`, `spawned_by`, or any cross-run reference. The schema is entirely self-contained within one run.

**What cross-run tracking currently exists:**

None at the state file level. The only cross-run artifact is the decomposition YAML written to `.claude/decomposition/{ISSUE-ID}.yaml` by `implement-feature`, but this is a per-issue artifact, not a cross-pipeline lineage record. `commands/metrics.md` does cross-run analysis by parsing `[ceos-agents]` issue tracker comments — it uses comment timestamps and PR links to reconstruct history, not state files.

The `run_id` field for scaffold pipelines uses format `scaffold-{timestamp}` (e.g., `scaffold-20260322-143000`). Feature runs use the Issue ID as `run_id`. There is no mechanism connecting a scaffold run to the feature runs it subsequently spawns (scaffold Step 9 creates issue tracker cards, but does not record the mapping in state).

**Should `parent_run_id` be added?**

Yes, with conditions. The use case is clear: when scaffold Step 7 (feature implementation loop) delegates to implement-feature, or when scaffold Step 9 creates issue tracker cards and those issues are later processed by implement-feature, there is a logical lineage. Recording it would enable:
- `/metrics` to attribute feature run success/failure back to the scaffold that originated the project
- `/resume-ticket` to surface scaffold context when resuming a stuck feature
- Future dashboard views showing scaffold→feature trees

However, this is a schema version change (currently `schema_version: "1.0"`). It is a backward-compatible addition (new optional field) so it would not require a MAJOR version bump under the versioning policy — it qualifies as MINOR. The field would be `null` for standalone runs and populated only when a run is spawned by another pipeline.

**Recommended field shape:**

```json
"parent_run_id": null
```

Type: `string | null`. Optional field. Set by the spawning command (scaffold, fix-bugs) when it initiates a child run. Default: `null`.

**Confidence:** HIGH — absence confirmed by full schema read. Recommendation is a design judgment.

**Relevant files:**
- `state/schema.md` lines 29–111 (full schema), lines 114–183 (field definitions)
- `core/state-manager.md` (write/read/resume contract — no cross-run logic)
- `commands/metrics.md` lines 39–56 (cross-run analysis via issue comments, not state)
- `commands/scaffold.md` lines 53, 302 (state initialization and writes — no parent_run_id)

---

## RQ-11: Scaffold-to-implement-feature delegation — pipeline stage delta

**Question:** Which stages would need skipping if scaffold delegated to implement-feature?

**Answer:**

**Scaffold Step 7 (inline feature loop) vs. implement-feature — side-by-side comparison:**

| Stage | scaffold Step 7 | implement-feature | Skip needed if delegating? |
|-------|-----------------|-------------------|---------------------------|
| MCP pre-flight | Not present (no tracker in Step 7) | Step 0 | YES — skip or suppress (no tracker in scaffold context) |
| State init | Reuses scaffold's state.json | Creates own state.json | YES — must not create new state file |
| Set issue state | Not present | Step 1 | YES — no issue exists during scaffold |
| Create branch | Not present | Step 2 | YES — scaffold manages git directly |
| spec-analyst | Not present (spec/ folder is used directly) | Step 3 | YES — spec already exists as spec/epics/*.md |
| Architect | Step 5 (inline, already ran) | Step 4 | YES — architect already produced task tree |
| Decomposition decision | Step 5 (inline, already decided) | Step 5 | YES — already processed |
| Pre-fix hook | Explicitly SKIPPED in scaffold (Step 7 note) | Step 6a | YES — no hooks during scaffold |
| Fixer | Step 7a (present) | Step 6b | NO — must run |
| Post-fix hook + custom agent | Explicitly SKIPPED in scaffold | Step 6c | YES |
| Reviewer | Step 7b (present) | Step 6d | NO — must run |
| Test-engineer | Step 7c (present) | Step 6e | NO — must run |
| E2E test (optional) | Step 8 (separate step after loop) | Step 6f | CONDITIONAL — scaffold handles separately |
| Acceptance gate | Not present in scaffold loop | Step 6g | YES — scaffold uses spec-reviewer --verify instead (Step 7b) |
| Commit subtask | Step 7d (present) | Step 6h | NO — must run |
| Integration step | Post-batch test (end of each batch) | Step 7 (after all subtasks) | CONDITIONAL — scaffold runs this per batch |
| Pre-publish hook | Not present | Step 8 | YES |
| Display result + PR prompt | Not applicable (no PR in scaffold) | Step 9 | YES |
| Publisher | Not present (scaffold does not create PR) | Step 10 | YES — mandatory skip |
| Post-publish hook + webhook | Not present | Step 10a | YES |
| Feature verification | Not applicable | Step 10b | YES |

**Summary of stages to skip:**

Mandatory skips (9): `mcp-preflight`, `set-issue-state`, `create-branch`, `spec-analyst`, `architect`, `decomposition`, `pre-fix-hook`, `post-fix-hook`, `acceptance-gate`, `pre-publish-hook`, `publisher`, `post-publish-hook`, `feature-verification`

Must keep (4): `fixer`, `reviewer`, `test-engineer`, `commit-subtask`

The profile-parser (`core/profile-parser.md`) only supports skipping: `triage`, `code-analyst`, `spec-analyst`, `test-engineer`, `e2e-test-engineer`, `reproducer`, `browser-verifier`. It explicitly disallows skipping `fixer`, `reviewer`, `publisher`. More critically, stages like `set-issue-state`, `create-branch`, `pre-fix-hook`, `post-fix-hook`, `pre-publish-hook`, `publisher`, and `feature-verification` are not in the profile-parser's valid stage name set at all — they cannot be skipped via profile mechanism.

**Conclusion:** The profile-parser skip mechanism is insufficient for scaffold delegation. Scaffold would need a dedicated internal delegation mode (e.g., a `--scaffold-delegate` flag or an internal `mode=scaffold-inline` parameter) that suppresses all issue-tracker and git-management steps while retaining the fixer→reviewer→test-engineer→commit loop. The current inline loop in scaffold Step 7 is effectively this mode — it is already a stripped-down re-implementation of implement-feature's core loop. Delegation via the existing profile system is not possible without schema extension.

**Confidence:** HIGH

**Relevant files:**
- `commands/scaffold.md` lines 339–403 (Step 7, inline feature loop)
- `commands/implement-feature.md` lines 58–326 (all steps)
- `core/profile-parser.md` lines 6–28 (valid skip stages, restrictions)

---

## RQ-12: docker-compose.yml ownership — scaffolder vs scaffold-add

**Question:** Should scaffolder generate docker-compose.yml for full-stack projects, or leave it to scaffold-add?

**Answer:**

**What scaffolder generates (Batch 4 — Ops):**
- `Dockerfile` (multi-stage if applicable, pinned base image)
- `.dockerignore`
- CI config (`.gitea/workflows/ci.yml` or `.github/workflows/ci.yml`)

`docker-compose.yml` is **not listed** in scaffolder's Batch 4. The scaffolder agent definition (`agents/scaffolder.md`, Batch 4) explicitly enumerates: Dockerfile, .dockerignore, CI config. No `docker-compose.yml`.

**What scaffold-add generates for the `docker` component:**
`commands/scaffold-add.md` lists the `docker` component as: "Dockerfile + .dockerignore + docker-compose.yml". This is explicitly stated in the Supported components table (line 16). The component delegates to the scaffolder agent with a restricted context ("Scaffolder generates ONLY the requested component").

**Current ownership:** `docker-compose.yml` is owned by `scaffold-add docker`, not by the scaffolder's baseline scaffold pass. Scaffolder produces a single-container Dockerfile; orchestration via compose is additive.

**Should this change?**

The current split is architecturally sound for the following reasons:

1. Scaffolder's stated goal is "minimal buildable skeleton" — docker-compose is not minimal; it implies multi-service orchestration (app + database + reverse proxy etc.) which belongs to the layer above.
2. The CI config generated by scaffolder uses service containers natively (the scaffolder adds health-checked service containers in CI config when a database is needed). This satisfies the "run dependencies in CI" use case without docker-compose.
3. For full-stack projects (app + DB + cache), the scaffolder generates `.env.example` and database config (Batch 2), but the developer decides whether to orchestrate with compose, Kubernetes, or cloud-native services. Prescribing compose in the baseline scaffold would be over-opinionated.
4. `scaffold-add docker` is the intentional escape hatch for teams that want compose. It is additive and opt-in.

**Recommendation:** Keep current ownership. Scaffolder should not generate `docker-compose.yml`. If a project needs it, `scaffold-add docker` is the correct entry point. However, if the scaffolder is running in scaffold v2 mode and the spec explicitly calls for multi-service deployment (e.g., spec mentions "PostgreSQL + Redis + app container"), the scaffolder could note this in the quality scorecard under a new "Compose" check row as: "WARN — multi-service stack detected, consider running `/scaffold-add docker`". This is informational only.

**Confidence:** HIGH — file contents are unambiguous. Recommendation is a design judgment.

**Relevant files:**
- `agents/scaffolder.md` lines 47–50 (Batch 4 — Ops, no docker-compose.yml)
- `commands/scaffold-add.md` lines 9–17 (Supported components table, docker entry)
