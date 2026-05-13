# Discussion: Scaffold Pipeline Improvements

**Date:** 2026-03-08
**Agents:** spec-writer, scaffolder, architect
**Status:** PROPOSED

---

## spec-writer (Visionary, comprehensive, user-centric)

The biggest gap I see in the current pipeline is that my output -- the specification -- loses authority as it moves downstream. I generate acceptance criteria for every user story, but nobody checks at the end whether those criteria were actually met. The pipeline validates "does it build?" and "do tests pass?", but never asks "does it match what was specified?" Those are fundamentally different questions.

**On specification quality:** My constraint says "NEVER write vague acceptance criteria," but there is no structured enforcement of this. I propose a formal AC schema -- every acceptance criterion must have three fields: `given` (precondition), `when` (action), `then` (observable outcome). This Given/When/Then format is mechanically verifiable by spec-reviewer. If an AC does not parse into these three parts, it is automatically a BLOCK issue. This would eliminate the gray area where criteria like "user can manage their profile" slip through -- technically it is "testable" but practically it is too vague for the fixer to implement deterministically.

**On end-of-pipeline verification:** I strongly advocate for a new pipeline step -- call it "spec-verifier" or reuse spec-reviewer in a different mode. After all features are implemented and tests pass, this step reads every `spec/epics/*.md`, extracts each AC, and cross-references it against the codebase and test results. Output: a compliance matrix showing PASS/FAIL/PARTIAL for each criterion. This is the missing feedback loop. Without it, we are shipping projects where 80% of the spec is implemented but nobody knows which 20% was dropped.

**On iteration after scaffold:** The spec should be a living document. When the developer gives feedback post-scaffold, the feedback should flow back through spec-writer to update the spec, then the delta should be re-processed through the pipeline. This is not "out of scope" -- it is the natural lifecycle. But it should be a separate command, something like `/scaffold-iterate`, rather than complicating the already long `/scaffold` command. The key insight: re-running the full pipeline is wasteful. We need delta-aware processing -- only re-implement changed epics.

**On template quality:** The scaffolder generates linting config and CI, but spec-writer should define quality expectations in `spec/verification.md`. I should be writing: "Code coverage target: 80%. Linting: zero warnings on commit. CI pipeline must include: lint, test, build, type-check." This gives the scaffolder a contract to fulfill rather than relying on its defaults.

## scaffolder (Efficient, convention-following, minimal)

I will be direct: my job is to produce a skeleton that builds, tests, and lints. Adding more responsibilities to my phase is the wrong approach. Let me explain what actually goes wrong and what would fix it.

**On scaffold quality audit:** I already verify build + test + lint. Adding a separate "quality audit" step is redundant if we improve what I check. The real problem is that my validation is binary -- pass or fail. What I should do instead is produce a **quality scorecard**: dependency freshness (are pinned versions current?), Dockerfile best practices (multi-stage? non-root user? .dockerignore coverage?), CI completeness (lint + test + build + type-check?), and gitignore coverage. This is a checklist I can self-audit against before reporting, not a new agent. Adding agents adds latency and token cost. My validation in step 4 of my process should expand from 3 checks to 8 checks, all within my existing execution.

**On E2E reliability:** This is where I have strong opinions. The E2E failures on scaffolded projects are almost always my fault, not the e2e-test-engineer's. I generate a smoke test and a basic server setup, but I do not generate proper test infrastructure -- no test fixtures for database seeding, no port allocation strategy (hardcoded 3000 everywhere), no health-check endpoint that E2E can wait on. Concrete fix: I should generate a `test/setup.ts` (or equivalent) that handles random port allocation, database setup/teardown, and a `/health` endpoint. This eliminates the top 3 infrastructure failures: port conflicts, database state leaks, and timing issues from missing health checks.

**On the manual checkpoint idea:** I support an optional `--review` flag that pauses after my scaffold phase and opens the project in the user's editor. But this should be lightweight -- just a pause point, not a new agent or review protocol. The user looks, gives thumbs up or specific feedback, and we continue. If feedback requires changes, I re-run with the feedback appended to my context. Maximum one re-scaffold iteration at this point.

**On spec verification at the end:** I agree with the need, but it must not be my responsibility. I generate boilerplate. The verification agent (whoever it is) should compare the final codebase against `spec/`. My concern is scope creep -- if every agent starts checking spec compliance, we get redundant work. One agent, one responsibility, at the end.

**On iteration:** Post-scaffold iteration is explicitly out of my scope. My skeleton is intentionally minimal. Once features are implemented, re-scaffolding would destroy them. The iteration loop belongs to fixer/reviewer, not to me. What could work: a `/scaffold-feedback` command that takes user feedback, identifies which epics need rework, and dispatches only those epics back through fixer/reviewer.

## architect (Strategic, systems-thinking, trade-off aware)

Let me address these proposals through the lens of system design and trade-offs, because several of the ideas here have hidden costs that need to be surfaced.

**On spec verification -- the critical missing piece:** I agree this is the highest-impact improvement. But the implementation matters enormously. A naive "check each AC against the codebase" approach will be unreliable -- how do you verify "POST /auth/login returns 200 with JWT" without actually running the endpoint? The verification must be layered: (1) static verification -- does the route exist? does the test file reference this endpoint? (2) test-based verification -- is there a test that exercises this exact AC? (3) runtime verification -- does the E2E test cover this flow? The compliance matrix should show which layer verified each AC. This is more useful than a binary pass/fail because it reveals coverage depth. I would implement this as a new mode for spec-reviewer: `spec-reviewer --verify` that reads the implemented codebase, test results, and E2E results alongside the spec.

**On decomposition quality:** Today I decompose epics into subtasks, but I have no feedback on whether my decomposition was good. If a subtask blocks because the scope was wrong (too many files, unclear boundaries), I never learn. Proposal: after the implementation loop, collect metrics -- which subtasks blocked? which needed the most fixer iterations? which had the biggest diff delta from my estimate? This data should feed into the final report so humans can spot patterns. Eventually it could feed back into my decomposition heuristics.

**On the manual checkpoint:** I see three distinct checkpoint needs, and conflating them is a design mistake. (1) Spec checkpoint -- already exists, works well. (2) Architecture checkpoint -- I propose adding this after my decomposition step. The developer should see the task tree and batch plan before implementation starts. This already exists as Step 6, but it should be more detailed: show estimated total implementation time, highlight high-risk subtasks, and flag subtasks that touch the most files. (3) Post-implementation checkpoint -- this is the new one. After Step 7, before E2E tests, pause and let the developer do a smoke test. This is where the "visual check, UX review" happens. Three checkpoints, three different purposes.

**On the pipeline's structural weakness:** The current pipeline is strictly linear. This is the root cause of several problems. If epic 3 fails, we roll back epic 3 but epics 1 and 2 are committed. But what if epic 3's failure reveals that epic 1's architecture was wrong? We have no mechanism for cross-epic rework. My proposal: after each batch completes, run a lightweight integration check -- not just "do tests pass" but "do the interactions between features work?" This requires the architect (me) to define integration acceptance criteria at the batch level, not just the subtask level. This is a medium-complexity change but addresses a real failure mode.

**On template quality vs. scaffolder responsibility:** The scaffolder should not be the quality gatekeeper. It generates a minimal skeleton. Quality standards should be defined in the spec (spec-writer's domain) and verified at the end (spec-reviewer's domain). The scaffolder fills in the template. If we want better linting config, better CI, better dependency hygiene -- those should be spec-level requirements, not scaffolder heuristics. This keeps the separation of concerns clean: spec defines what, scaffolder implements the skeleton, architect plans features, fixer implements them.

## Synthesis

**Key agreements:**
- All three agents agree that end-of-pipeline spec verification is the highest-priority missing piece.
- All three agree that E2E infrastructure failures originate in the scaffolder phase and should be fixed there.
- All three agree that post-scaffold iteration should be a separate command, not embedded in `/scaffold`.

**Key disagreements:**
- Spec-writer wants a new agent or agent mode for verification; architect wants to extend spec-reviewer; scaffolder wants it to be someone else's problem but explicitly not a new agent. Resolution: extend spec-reviewer with a `--verify` mode (architect's proposal) -- this reuses an existing agent, avoids a new agent, and keeps the token cost lower.
- Scaffolder wants to expand internal validation (self-audit scorecard); architect argues quality standards belong in the spec. Resolution: both -- spec-writer defines quality targets in `spec/verification.md`, scaffolder validates against them.
- On checkpoints: architect wants three distinct checkpoints; scaffolder wants one lightweight pause. Resolution: keep existing two checkpoints (spec, feature plan), add one post-implementation checkpoint before E2E.

**Concrete proposals:**

| # | What | Why | Impact on success rate | Complexity | New config keys | Agent changes |
|---|------|-----|----------------------|------------|-----------------|---------------|
| 1 | **Spec compliance verification step** -- run spec-reviewer in `--verify` mode after Step 7 (implementation loop). Reads spec/epics/*.md ACs, cross-references against codebase + test files + E2E results. Outputs compliance matrix (PASS/FAIL/PARTIAL per AC). | Today we validate build+tests but not spec alignment. 20% of ACs can be silently dropped. | +15-20% -- catches missing features before delivery | Medium | None | spec-reviewer gains verify mode: reads codebase + test output alongside spec |
| 2 | **Given/When/Then AC schema enforcement** -- spec-writer generates all ACs in Given/When/Then format. Spec-reviewer treats any AC not in this format as a BLOCK issue. | Eliminates vague ACs like "user can manage profile". Makes ACs mechanically parseable for verification step. | +10% -- reduces ambiguity-caused implementation errors | Low | None | spec-writer: AC format constraint. spec-reviewer: format validation rule |
| 3 | **Scaffolder test infrastructure generation** -- scaffolder generates `test/setup.{ext}` with random port allocation, database setup/teardown helpers, and `/health` endpoint. | Top 3 E2E failures are port conflicts, DB state leaks, timing issues. All originate from missing test infrastructure. | +20-25% E2E reliability improvement | Low | None | scaffolder: add test infrastructure to Batch 3 (Quality) |
| 4 | **Post-implementation checkpoint** -- new optional Step 7.5 between implementation loop and E2E tests. Pauses for developer smoke test/UX review. Only in Interactive and YOLO-checkpoint modes. | Developer catches visual/UX issues that automated tests miss. Prevents wasted E2E effort on fundamentally wrong output. | +5-10% -- catches UX issues early | Low | `Scaffold checkpoints` in config (optional, values: `spec,plan,review` -- default all three for interactive, `spec,plan` for yolo-checkpoint) | None (command-level change only) |
| 5 | **Scaffolder quality scorecard** -- expand scaffolder self-validation from 3 checks to 8: add dependency freshness, Dockerfile best practices, CI completeness, gitignore coverage, type-check presence. Report as scorecard in Scaffold Report. | Binary pass/fail misses quality issues that cause problems downstream. Scorecard gives visibility without blocking. | +5% -- prevents downstream quality debt | Low | None | scaffolder: expanded validation in Process step 4 |
| 6 | **Batch-level integration acceptance criteria** -- architect defines integration ACs for each batch (cross-feature interactions). Verified after each batch completes in Step 7. | Linear pipeline has no cross-epic validation. Epic 3 can fail due to epic 1's architecture without detection. | +10% -- catches integration issues between batches | Medium | None | architect: new output field `batch_integration_criteria` in task tree |
| 7 | **`/scaffold-iterate` command** -- takes developer feedback, identifies affected epics, re-runs only changed epics through fixer/reviewer/test-engineer. Does not re-scaffold. | Today scaffold is one-shot. Iteration requires manual work or full re-run. Delta-aware processing saves 60-80% of re-run cost. | +10% -- enables refinement without full rebuild | High | None | New command. No new agents -- reuses existing fixer/reviewer/test-engineer |

**Recommended implementation order:** 2 (low effort, immediate quality gain) → 3 (low effort, high E2E impact) → 1 (medium effort, highest overall impact) → 5 and 4 (low effort polish) → 6 (medium effort) → 7 (high effort, new command).
