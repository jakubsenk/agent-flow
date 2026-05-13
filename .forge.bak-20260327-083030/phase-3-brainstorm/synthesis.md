# Phase 3 Brainstorm — Synthesis

**Judge-mediator:** Claude Opus 4.6
**Input:** 3 proposals from heterogeneous personas (Pragmatic Incrementalist, Systems Thinker, User Advocate)
**Date:** 2026-03-26

---

## 1. Scoring Table

| Persona | Creativity (0-5) | Feasibility (0-5) | Completeness (0-5) | Total (0-15) | Notes |
|---------|------------------|--------------------|---------------------|---------------|-------|
| **A: Pragmatic Incrementalist** | 3 | 5 | 4 | 12 | Strong grounding in existing patterns. Every idea is immediately buildable with clear file lists. Lacks architectural ambition — no idea addresses the scaffold-to-feature-loop continuity problem (stages 2-3). |
| **B: Systems Thinker** | 5 | 3 | 5 | 13 | Highest creativity — the lifecycle kernel (parent_run_id + phase registry) and scaffold --extend are genuinely novel contributions. Gateway contracts (Idea 1) are over-engineered for current needs. Completeness is excellent — state machines and invariants for every idea. Feasibility docked for Idea 3 (L effort, scaffold.md already 515 lines). |
| **C: User Advocate** | 4 | 4 | 5 | 13 | Best user journey mapping — the 5-journey friction analysis is the strongest framing of the problem space. The Composite (Idea 5) is the most holistic recommendation. Correctly identifies that the #1 problem is not missing features but missing guardrails between existing features. Slightly lower creativity because most ideas are recombinations of existing capabilities rather than new primitives. |

**Verdict:** B and C tie at 13, with different strengths — B excels at creative primitives, C at user-facing synthesis. A's feasibility anchor is essential for keeping the plan grounded.

---

## 2. Convergence Analysis

All three personas agree on the following:

### Universal Agreement (all 3 personas propose this independently)

1. **`/check-deploy` command is needed.** A (Idea 1), B (Idea 2 implies it), C (Idea 3) all conclude that a new command for deployment verification is the right surface. All agree it must be standalone (not an extension of check-setup), use `[OK]/[FAIL]/[SKIP]` output format, and follow the reproducer's `run_in_background` + health poll pattern. This confirms KF-5 and KF-7 from research.

2. **New optional `Local Deployment` config section.** All three personas independently propose the same config section with near-identical keys (Start/Compose command, Health URL, Timeout, Teardown). All agree this is a MINOR version bump following the Browser Verification precedent. Config format convergence is strong.

3. **Scaffold Final Report must mention `/onboard --update`.** A (Idea 4), B (Idea 4), C (Ideas 1 and 5) all identify the same gap: scaffold Step 10 lists "edit CLAUDE.md manually" but never mentions the existing `/onboard --update` command. This is a zero-effort fix with immediate UX impact. Confirms KF from RQ-08.

4. **Config validity gate in implement-feature (Step 0b).** B does not propose this explicitly, but A implicitly supports it (via check-deploy's pre-flight pattern), and C (Ideas 1 and 5) makes it a centerpiece. Research (RQ-09) independently validates it as high-impact. This is the "hard safety net" that catches config errors before irreversible side effects.

5. **Deployment-verifier agent uses reproducer pattern (sonnet, non-blocking).** All three agree the new agent should: use sonnet, follow the reproducer's background-start + health-poll pattern, never block the pipeline (failures produce SKIPPED/PARTIAL, not BLOCK), and always clean up the started process. This is the strongest architectural consensus.

### Strong Agreement (2 of 3 personas agree)

6. **Scaffold inline deploy check (Step 10.5).** A (Idea 2) and B (Idea 2, via scaffold step insertion) agree that scaffold should optionally verify the app starts. C defers this to a future release. Position: include it but make it dependent on Local Deployment config being present — zero overhead when config is absent.

7. **Status readiness mode for post-scaffold guidance.** C (Idea 4) proposes this in detail; B's lifecycle kernel (Idea 5) implies it via the phase registry powering `/status`. A does not address it. Position: strong idea that transforms `/status` from a passive display to an active guide.

---

## 3. Divergence Analysis

### Divergence 1: Agent vs. inline command logic for deployment verification

| Position | Persona | Argument |
|----------|---------|----------|
| **New deployment-verifier agent** | B, C | Reusable across scaffold and check-deploy; follows existing agent pattern; overridable via Agent Overrides for project-specific deploy logic |
| **Inline bash in check-deploy command** | A | Agent is overkill for "GET /health returns 200"; saves tokens; simpler implementation |

**Strongest position: Agent (B/C).** A's objection is valid for the trivial case, but the deployment verification problem has the same shape as browser verification: start background process, poll, run checks, collect evidence, produce structured verdict, clean up. This is exactly the abstraction boundary that agents serve. The agent also enables Agent Overrides (e.g., a project that needs to check Redis connectivity or run database migrations before the health check). The token cost of a sonnet agent for this task is negligible relative to the fixer/reviewer loops.

**Resolution:** Create the deployment-verifier agent. The check-deploy command dispatches it. This follows the established pattern (check-deploy is to deployment-verifier as fix-ticket is to fixer).

### Divergence 2: Lifecycle kernel (parent_run_id + phase registry) — when to build it

| Position | Persona | Argument |
|----------|---------|----------|
| **Build kernel first, then features on top** | B | Minimal cost (one schema field, one core file), enables all future composition, prevents ad-hoc state accumulation |
| **Build features first, extract kernel later** | A, C | Kernel alone delivers zero user value; "build the abstraction from concrete need" is a stronger pattern; risk of YAGNI |

**Strongest position: Defer but design (compromise).** B is right that `parent_run_id` is cheap and useful. A and C are right that a full phase registry is premature. The resolution: add `parent_run_id` to the state schema now (it is a single nullable field, backward-compatible, costs nothing), but defer the phase registry (`core/phase-registry.md`, gateway contracts) until there are at least 2 concrete consumers. This gives us the connective tissue without the governance overhead.

**Resolution:** Add `parent_run_id` to state schema in Phase 1. Defer phase registry to a future version when scaffold --extend or a workflow command needs it.

### Divergence 3: Scaffold-to-feature-loop continuity — how to address stages 2-3

| Position | Persona | Argument |
|----------|---------|----------|
| **`/scaffold --extend` flag** | B | Single command for new epics; reuses scaffold Step 7 infrastructure; no cross-command invocation needed |
| **Fix the handoff, not the pipeline** | A, C | The handoff (scaffold → manual config → implement-feature) is the actual pain point; once config works, running implement-feature N times is fine; --extend adds complexity to an already 515-line command |

**Strongest position: Fix the handoff (A/C), defer --extend.** The 5-journey analysis from C proves that the friction is in the *transition* between scaffold and implement-feature, not in the feature loop itself. A user who can successfully run one implement-feature invocation can run ten. The --extend idea is architecturally sound but solves a problem that does not yet cause user abandonment. Furthermore, scaffold.md at 515 lines is already at the "lost in middle" risk threshold — adding extend mode would push it past 700 lines.

**Resolution:** Phase 1 fixes the handoff (onboard mention, config gate, status readiness). --extend is deferred to a future version if users report friction with the implement-feature-per-card workflow.

### Divergence 4: Forge integration — now or later?

All three personas defer forge integration. This is unanimous. B mentions it only in the context of the kernel enabling it; A and C do not address it at all. Research (KF-3, KF-10) confirms cross-plugin Skill() calls are unvalidated and forge-plan output is structurally incompatible with implement-feature. This is correctly deferred — it requires NV-01 validation first.

**Resolution:** Forge integration is out of scope for this design cycle. Document the interface requirements (forge-plan → architect YAML translation layer with maps_to synthesis) and revisit when cross-plugin Skill() is empirically validated.

---

## 4. Synthesized Recommendation

### Phase 1: "The Guided Handoff" (MINOR version bump, effort: S)

**Goal:** Eliminate the post-scaffold cliff. Users who finish scaffold should never be stuck wondering "what now?"

**Changes:**

| # | Change | File(s) | Effort |
|---|--------|---------|--------|
| 1a | Add `/ceos-agents:onboard --update` to scaffold Final Report next-steps | `commands/scaffold.md` (Step 10) | XS |
| 1b | Add Step 0b (Config validity gate) to implement-feature — validate all required Automation Config keys are present and non-placeholder before Step 1 mutations | `commands/implement-feature.md` | XS |
| 1c | Add readiness mode to `/status` — detect post-scaffold state, show setup checklist with progressive TODO/DONE tracking, recommend next action | `commands/status.md` | S |
| 1d | Add scaffold pipeline type to resume-ticket — detect `.ceos-agents/scaffold-*/state.json`, allow resuming crashed scaffold runs | `commands/resume-ticket.md` | XS |

**Artifacts produced:** 0 new files. 4 files modified. 0 new agents. 0 new commands. 0 new config sections.

**Version impact:** MINOR (new behavior in existing commands, no config contract changes).

**User-visible result:** After scaffold, `/status` shows a checklist. Each step links to the exact command. `implement-feature` catches config errors before side effects. Scaffold crashes are resumable.

### Phase 2: "Local Deployment Verification" (MINOR version bump, effort: S-M)

**Goal:** Answer "does this thing actually start and respond?" for any project — scaffolded or existing.

**Changes:**

| # | Change | File(s) | Effort |
|---|--------|---------|--------|
| 2a | Create `deployment-verifier` agent (sonnet) — reproducer pattern: start app via `run_in_background`, poll health endpoint, optionally check key routes, collect evidence, structured verdict, always cleanup | `agents/deployment-verifier.md` (new) | S |
| 2b | Create `/check-deploy` command — reads `Local Deployment` config section, dispatches deployment-verifier, reports `[OK]/[FAIL]/[SKIP]` per check | `commands/check-deploy.md` (new) | S |
| 2c | Add optional `Local Deployment` config section to the config contract | `CLAUDE.md`, `docs/reference/automation-config.md` | XS |
| 2d | Add `parent_run_id` (nullable string) to state schema — scaffold writes its run_id, subsequent runs can reference it | `state/schema.md`, `core/state-manager.md` | XS |
| 2e | Add optional Step 10.5 to scaffold — if Local Deployment config exists in generated CLAUDE.md, dispatch deployment-verifier; add `Local run: [OK]/[FAIL]/[SKIP]` to Final Report | `commands/scaffold.md` | XS |
| 2f | Add routing entry for deploy-related intents to skill router | `skills/router.md` (or equivalent skill file) | XS |
| 2g | Update check-deploy in status readiness checklist (Phase 1's 1c) to detect Local Deployment config | `commands/status.md` | XS |

**Config section (optional, in consuming project's CLAUDE.md):**

```markdown
### Local Deployment

| Key | Value |
|-----|-------|
| Start command | `docker compose up -d` |
| Health URL | `http://localhost:3000/health` |
| Health timeout | `30` |
| Teardown command | `docker compose down` |
```

**Artifacts produced:** 2 new files (`agents/deployment-verifier.md`, `commands/check-deploy.md`). 5-6 files modified. 1 new agent (total: 19). 1 new command (total: 25). 1 new optional config section.

**Version impact:** MINOR (new optional config section, new command, new agent — follows Browser Verification v5.1.0 precedent exactly).

**User-visible result:** `/check-deploy` works for any project with Local Deployment config. Scaffold optionally verifies the app boots. State schema gains cross-run lineage via parent_run_id.

### Phase 3: "Extended Scaffolding" (deferred — not in current design cycle)

**Deferred items (tracked, not designed):**

| Item | Reason for deferral | Trigger to revisit |
|------|---------------------|-------------------|
| `/scaffold --extend` flag | scaffold.md already 515 lines; --extend adds ~200 more; needs Step-File Architecture first (roadmap item) | User reports show friction with per-card implement-feature workflow |
| Phase registry (`core/phase-registry.md`) | Zero consumers today; `parent_run_id` provides the connective tissue without the governance overhead | Second concrete consumer emerges (e.g., a lifecycle dashboard or cross-pipeline metrics) |
| Forge integration bridge | Cross-plugin Skill() unvalidated (NV-01); forge-plan → architect YAML translation is non-trivial (KF-3) | NV-01 validated empirically; user demand for forge-based decomposition |
| `/implement-features` (batch) | User who can run implement-feature once can run it N times; batch is convenience, not blocker | Multiple users report friction with serial feature implementation |
| Standalone machine automation | Requires all prior phases; fundamentally a deployment + monitoring concern | Local deployment verification proven; CI/CD integration designed |

---

## 5. Divergence Assessment

```json
{
  "divergence_class": "EVOLVED",
  "original_keywords": ["scaffold", "deployment", "tracker", "feature-loop", "forge-integration", "local-deployment", "standalone-machine"],
  "recommended_keywords": ["scaffold-handoff", "deployment-verification", "config-gate", "status-readiness", "deployment-verifier-agent", "local-deployment-config", "parent-run-id"],
  "keyword_overlap_score": 0.43,
  "rationale": "All three personas converge on solving scaffold-to-deployment as a 2-phase incremental plan (handoff fixes then deploy command) rather than the original 5-stage monolithic workflow; forge integration and standalone machine are unanimously deferred pending validation."
}
```

Explanation of classification:

- **Not ALIGNED** because the original 5-stage workflow (scaffold mode, feature loop, forge integration, local deployment, standalone machine) is not delivered as designed. Stages 3 and 5 are deferred entirely; stage 2 is reframed as a handoff problem rather than a new pipeline; only stage 4 gets a dedicated new feature.
- **Not PIVOTED** because the core goals are preserved — the design still delivers scaffold-to-deployment capability. The direction is the same; the ordering and scope are different.
- **EVOLVED** because the brainstorm revealed that the biggest ROI is not in the later stages (forge, standalone) but in the transition between existing stages (scaffold → feature loop) and in adding the missing deployment primitive. The approach shifts from "build all 5 stages" to "fix the handoff, add deploy verification, defer the rest."

---

## 6. Open Questions for User (Gate 1 Decisions)

These require user input before the specification phase can proceed:

### Q1: Phase 1 vs Phase 2 — ship together or separately?

Phase 1 (guided handoff) is effort S with 0 new files. Phase 2 (deployment verification) is effort S-M with 2 new files. They are independently valuable. Options:
- **(a)** Ship as a single MINOR release (v5.3.0) — more impactful changelog, one version bump
- **(b)** Ship Phase 1 first (v5.3.0), Phase 2 second (v5.4.0) — faster first delivery, lower risk per release

### Q2: Deployment-verifier scope — health check only, or route checking too?

The deployment-verifier agent can be:
- **(a)** Minimal: start app, poll health endpoint, report OK/FAIL — essentially a bash script wrapped in an agent (cheaper, simpler, covers 80% of cases)
- **(b)** Full: start app, poll health, then check key routes from spec/CLAUDE.md, collect response codes and console errors — richer verification but more token-intensive

### Q3: parent_run_id — include in Phase 2, or defer entirely?

B proposes `parent_run_id` as compositional infrastructure. It costs almost nothing (one nullable field in state schema) but delivers zero immediate user value. Options:
- **(a)** Include in Phase 2 — cheap insurance for future composability
- **(b)** Defer until a concrete consumer (scaffold --extend, lifecycle dashboard) is designed

### Q4: scaffold-add docker integration — should scaffold-add offer Local Deployment config?

When a user runs `/scaffold-add docker`, should it:
- **(a)** Also generate the `Local Deployment` config section in CLAUDE.md (pre-filling Start command, Health URL from the generated docker-compose.yml)
- **(b)** Only generate docker-compose.yml as today — user adds Local Deployment config manually if they want check-deploy

### Q5: Forge integration — validate NV-01 now or park it?

Cross-plugin Skill() calls are the prerequisite for forge integration. Options:
- **(a)** Run a quick empirical test (`Skill(skill='filip-superpowers:forge-status')`) during this design cycle to unblock forge integration design
- **(b)** Park forge integration entirely — revisit when there is active demand
