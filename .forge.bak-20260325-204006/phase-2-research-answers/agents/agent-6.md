# Research Answer 6: Agent Capabilities for Non-Code Modes

## Agent 1: spec-writer

### Current Capabilities [source: agents/spec-writer.md]

- **Model:** opus
- **Style:** Visionary, comprehensive, user-centric
- **Role:** Senior Product Architect specializing in software specification writing
- **Goal:** Generate a complete, implementable *project specification* from user input. Every section must be specific enough to implement without further clarification.
- **Expertise declared:** Requirements engineering, product specification, user story writing, acceptance criteria definition, tech stack evaluation, scope management, YAGNI enforcement.
- **Process steps:**
  1. Read input (direct text, custom template, flags --lang/--framework/--db/--ci, mode: interactive/yolo-checkpoint/yolo)
  2. In interactive mode: ask clarifying questions (max 10, one at a time, prefer multiple-choice) about purpose, target users, core features, technical constraints, tech stack
  3. Generate specification into a fixed 4-file folder structure: `spec/README.md`, `spec/architecture.md`, `spec/verification.md`, `spec/epics/NN-name.md`
  4. Fill every REQUIRED section completely; explicitly note why IF APPLICABLE sections do not apply
  5. Write testable acceptance criteria in GWT format (behavioral) or rule-oriented format (NFRs/constraints)
  6. Tech stack: incorporate flag constraints as fixed choices with rationale; make decisive choices for unconstrained categories
  7. Write all spec files to the `spec/` directory in the target project
  8. Output a structured **Spec Writer Report** (mode, input source, files generated, tech stack, AC count)
- **Constraints (hard limits):**
  - NEVER skip REQUIRED sections
  - NEVER write vague acceptance criteria
  - NEVER generate more than 7 epics (merge or recommend phased delivery if larger)
  - In interactive mode: one question at a time, max 10 questions
  - Must provide rationale for every tech stack choice
  - Every epic must have Dependencies and Priority fields (must/should/could)
  - On failure: Block via Block Comment Template (output to stdout when no tracker)

### Current Inputs/Outputs [source: commands/scaffold.md]

**Inputs received from scaffold command:**
- Natural language project description (direct text, or from `--issue` via MCP, or from `--template` path)
- Mode: interactive, yolo-checkpoint, or yolo
- Tech stack constraint flags: --lang, --framework, --db, --ci
- Optional: user-supplied spec (passed to spec-reviewer for gap analysis, then spec-writer fills gaps)
- Brainstorm enrichment: if brainstorm phase ran, receives enriched 200-400 word description

**Outputs produced:**
- Written files: `spec/README.md`, `spec/architecture.md`, `spec/verification.md`, `spec/epics/NN-name.md`
- Structured report block (Spec Writer Report) consumed by scaffold for checkpoint display

**Iteration context:** Runs in a spec-writer ↔ spec-reviewer loop (max 5 iterations by default) until spec-reviewer returns APPROVE.

### Mode Adaptability Assessment

**What translates directly to non-code modes:**
- Structured document generation from user input — the core mechanic (read input → ask questions → produce structured output) is domain-independent
- Interactive questioning pattern (max 10 questions, one at a time) works identically for analysis briefs or strategy inputs
- GWT-style criteria writing maps cleanly to testable conclusions in analysis/strategy (e.g., "Given this market condition, when competitor X acts, then our position is...")
- YAGNI enforcement / scope management is applicable to any deliverable (strategy docs, research reports)
- The REQUIRED vs IF APPLICABLE section discipline works for any document template

**What is hardcoded to software:**
- The fixed 4-file output structure (`spec/README.md`, `spec/architecture.md`, `spec/verification.md`, `spec/epics/*.md`) is entirely software-project-specific
- Section names: "Tech Stack", "Data Flow", "Data Model", "API", "NFR" are software concepts
- The tech stack constraint flags (--lang, --framework, --db, --ci) have no non-code equivalent
- The 7-epic limit is sized for software projects; analysis/strategy deliverables have different decomposition granularity
- "Every epic must have Dependencies and Priority fields" is inherited from software decomposition thinking
- The `spec/` directory convention as downstream pipeline input (architect, fixer, etc.) is a software-pipeline coupling

**What would need to change:**
- Output structure: configurable document templates replacing the fixed 4-file spec layout
- Terminology: replace "epics/user stories" with domain-appropriate terms (findings/recommendations for analysis; workstreams/initiatives for strategy)
- Acceptance criteria format: GWT format has no direct analog for content outputs; replace with "verification criteria" (how to tell if a strategy recommendation is sound)
- Constraints: "max 7 epics" needs a domain-calibrated equivalent
- The tech stack expertise section is irrelevant; replace with domain expertise declaration

---

## Agent 2: spec-reviewer

### Current Capabilities [source: agents/spec-reviewer.md]

- **Model:** opus
- **Style:** Critical, feasibility-focused, consistency-checking
- **Role:** Senior Technical Reviewer specializing in specification quality assurance
- **Goal:** Ensure specification is complete, consistent, feasible, and specific enough to drive architecture and implementation without ambiguity.
- **Expertise declared:** Requirements validation, acceptance criteria quality assessment, consistency checking, scope analysis, YAGNI detection, feasibility assessment, specification standards.
- **Process steps (review mode):**
  1. Read the entire `spec/` directory (all 4 files + all epic files)
  2. Completeness check: every REQUIRED section present and filled
  3. Quality check: every AC must be testable, specific, measurable, correctly formatted (GWT or rule-oriented)
  4. Consistency check: tech stack matches architecture assumptions; API in epics matches architecture; dependencies form a valid DAG; NFR targets realistic for chosen stack
  5. Feasibility check: features achievable within tech stack; NFR targets realistic; scope bounded
  6. Scope check: YAGNI violations, premature optimization, excessive epic count
  7. Output: **Spec Review** block (Verdict: APPROVE/REVISE, Issues list with BLOCK/WARN severity, Summary)
- **Verify mode (--verify):**
  - Reads spec/ AND searches implemented codebase (max 20 source files, 10 test files)
  - For each AC: searches for implementation evidence (function names, API endpoints, test assertions)
  - For each NFR: checks implementation compliance
  - Output: **Spec Compliance Report** (Verdict: PASS/PARTIAL/FAIL, coverage %, per-AC evidence, NFR compliance)
- **Constraints:**
  - NEVER modify the specification — read-only
  - NEVER approve with missing REQUIRED sections
  - NEVER approve vague AC
  - NEVER approve internal contradictions
  - Must flag overengineered requirements (YAGNI enforcement)
  - APPROVE only when zero BLOCK issues remain
  - User-supplied specs (--spec flag): validate against same criteria but accept different section names as long as key concepts are covered (vision, features with AC, tech stack)
  - In --verify mode: NEVER modify code; search evidence systematically

### Current Inputs/Outputs [source: commands/scaffold.md]

**Inputs received:**
- In review mode: `spec/` directory contents (all 4 file types)
- In --verify mode: `spec/` directory + codebase access (Grep/Glob/Read tools)
- Optionally: user-supplied spec at a custom path (--spec flag)

**Outputs produced:**
- Review mode: Spec Review block with APPROVE/REVISE verdict and BLOCK/WARN issue list
- Verify mode: Spec Compliance Report with PASS/PARTIAL/FAIL verdict and per-AC evidence

**Iteration context:** Runs in loop with spec-writer; on REVISE, passes feedback back to spec-writer. Also runs post-implementation as compliance gate (Step 7b of scaffold).

### Mode Adaptability Assessment

**What translates directly to non-code modes:**
- The document quality review mechanic (completeness, consistency, feasibility, scope) is fully domain-independent
- BLOCK vs WARN severity distinction is reusable for any document review
- YAGNI/scope discipline applies to any deliverable
- The loop-with-writer pattern (reviewer → writer → reviewer) works for analysis/strategy docs
- The --verify mode concept (compare specification against actual output) has a direct analog: compare a strategy document against actual implementation results
- Explicit constraint "accept different section names/organization as long as key concepts are covered" (for user-supplied specs) shows the agent already has some structural flexibility
- Criteria quality check (testable, specific, measurable) is reusable for any claim-based output

**What is hardcoded to software:**
- All REQUIRED section names are software-specific (spec/README.md sections: Vision & Goals, Users & Personas, Tech Stack, Out of Scope; spec/architecture.md: High-Level Overview, Data Flow, NFR; spec/verification.md: Test Strategy, Definition of Done, Risks & Assumptions)
- The consistency check "tech stack in README matches architecture assumptions" and "API endpoints in epics match architecture API design" are software-specific
- The feasibility check "features achievable within the tech stack" and "NFR targets realistic for chosen stack" have no non-code analog
- In --verify mode: evidence search against code (function names, API endpoints, test assertions) is entirely software-specific
- "Dependencies between epics form a valid DAG" is software-decomposition-specific

**What would need to change:**
- REQUIRED section checklist: must be configurable per document type (analysis report has different required sections than strategy playbook)
- Consistency checks: replace software-specific cross-checks with domain-appropriate ones (e.g., "recommendations align with the stated objective")
- Feasibility checks: replace tech stack feasibility with domain-specific feasibility (e.g., "is this strategy achievable given stated constraints?")
- In --verify mode: evidence source changes from codebase to real-world outcomes or implemented deliverables (no code search)
- The "accept different section names" constraint (already present for user-supplied specs) should be the default, not the exception

---

## Agent 3: spec-analyst

### Current Capabilities [source: agents/spec-analyst.md]

- **Model:** sonnet
- **Style:** Requirements-focused, clarity-driven, structured
- **Role:** Senior Product Analyst specializing in feature specification
- **Goal:** Transform feature requests into actionable, structured specifications with clear acceptance criteria. Extract WHAT needs to be built, not HOW.
- **Expertise declared:** Requirements analysis, acceptance criteria definition, scope identification, ambiguity detection, feature decomposition into testable outcomes, epic vs story distinction.
- **Process steps:**
  1. Read feature details from issue tracker (summary, description, comments, custom fields, images via MCP)
  2. Download attachments — save to temp dir, use Read tool for images (multimodal)
  3. Assess feature size: single feature (3-7 AC) vs epic/large feature (independent outcomes, "and also"/"additionally"/"phase 1/2/3" signals) — analyze each sub-feature individually up to 5; block if >5 independent outcomes
  4. Validate clarity: outcome clear? measurable AC inferable? scope bounded? Block if confidence < 50%
  5. Extract structured specification: Summary, Type, Area, Acceptance Criteria, Scope (IN/OUT), Dependencies, Constraints, Attachments
  6. Post checkpoint comment to issue tracker: `[ceos-agents] Spec analysis completed. Area: {area}. Criteria: {count}.`
  7. Post full acceptance criteria as separate issue tracker comment for human stakeholder visibility
- **Constraints:**
  - MUST post AC to issue tracker as separate comment (pipeline observability, human review before implementation)
  - NEVER modify code — read-only analysis
  - NEVER design architecture or suggest implementation
  - NEVER guess missing requirements — Block if too vague
  - If request is actually a bug report: flag it and recommend bug-fix pipeline

### Current Inputs/Outputs [source: commands/implement-feature.md]

**Inputs received:**
- Issue details from issue tracker via MCP (all fields, comments, attachments)
- Automation Config (Issue Tracker Type, Instance, Project)

**Outputs produced:**
- Structured Feature Specification block (Summary, Type, Area, AC list, Scope IN/OUT, Dependencies, Constraints, Attachments)
- Two issue tracker comments (checkpoint + full AC list)
- `acceptance_criteria` stored by implement-feature command for passing to all downstream agents (architect, fixer, reviewer, acceptance-gate)

**Dispatch context:** Step 3 of implement-feature; result drives architect (step 4), then cascades through fixer → reviewer → test-engineer → acceptance-gate.

### Mode Adaptability Assessment

**What translates directly to non-code modes:**
- The core extraction mechanic (read input → assess size → validate clarity → produce structured spec) is completely domain-independent
- The single-feature vs epic/large-feature size assessment maps to: single analysis question vs multi-part research agenda; single strategy objective vs multi-workstream plan
- The clarity validation (outcome clear? measurable? scope bounded?) is universally applicable
- The IN/OUT scope distinction is valuable for analysis and strategy work
- The "confidence < 50% → Block" rule applies to any domain
- Epic-detection signals ("and also", "additionally", "phase 1/2/3") are domain-independent language patterns
- Multimodal input (images via Read tool) is reusable for analysis inputs (charts, diagrams, screenshots)
- The WHAT-not-HOW discipline is directly applicable: extract what analysis is needed, not how to do it

**What is hardcoded to software:**
- Input source is exclusively the issue tracker via MCP (no other input sources)
- The "Area" field is software-module-specific (identifies which module/component is affected)
- Bug report detection and redirect to bug-fix pipeline is software-specific
- Checkpoint and AC comments posted to issue tracker — assumes issue tracker context always exists
- The dependency field assumes software library/service dependencies
- "Never design architecture" constraint is software-specific; in non-code modes, the equivalent separation might be "never define the research methodology"

**What would need to change:**
- Input source: must accept non-tracker inputs (documents, URLs, conversation, uploaded files)
- The "Area" field: replace with domain-appropriate field (e.g., "Domain" for analysis, "Workstream" for strategy)
- Issue tracker comment posting: not applicable in non-tracker contexts; output must go to appropriate sink (file, stdout, conversation)
- Bug redirect: software-specific; in non-code contexts, replace with: "if this is already a detailed plan, route to a different pipeline"
- The dependency field: generalize from software dependencies to any prerequisite information/data/decision

---

## Agent 4: priority-engine

### Current Capabilities [source: agents/priority-engine.md]

- **Model:** opus
- **Style:** Data-driven, impact-focused, objective
- **Role:** Backlog Analyst specializing in cross-issue prioritization
- **Goal:** Analyze an entire bug/feature backlog and produce a ranked list with recommended fix order, based on impact, risk, effort, and inter-issue dependencies.
- **Expertise declared:** Impact assessment, risk analysis, effort estimation, dependency graph construction, cost-benefit optimization.
- **Process steps:**
  1. Receive list of open issues (ID, title, description, state, labels, comments)
  2. For each issue, assess 4 dimensions:
     - Impact (1-5): user/module reach; labels like "critical"/"blocker" increase score; duplicate count increases score
     - Risk (1-5): criticality of affected code area (core business logic = 5, cosmetic = 1); historical data from metrics or [ceos-agents] comments factors in recurring-bug areas
     - Effort (1-5): implementation complexity (1 = trivial, 5 = multi-file refactoring); use description length, area size, prior analysis as signals
     - Dependencies: which issues block/depend on other issues
  3. Calculate priority score: `score = (Impact × 2 + Risk × 1.5) / (Effort × 1) + dependency_bonus` (dependency_bonus: +2 if blocks 2+ issues, +1 if blocks 1 issue)
  4. Sort by score descending
  5. Group into tiers: P0 (score ≥ 8 or labeled critical/blocker), P1 (score ≥ 5), P2 (score < 5)
  6. Output: **Backlog Prioritization** with P0/P1/P2 tables (Issue, Impact, Risk, Effort, Score, Rationale), Dependencies section, Recommendations section (suggested batch, estimated cost)
- **Constraints:**
  - NEVER modify code or issues — read-only
  - Max 50 issues per analysis; if larger, analyze first 50 (by creation date) and note limitation
  - Vague issues → Effort = 3 (medium), note "insufficient data"
  - Score formula is fixed and transparent — always show formula and per-dimension scores for auditability
  - Note: dimension scores are assessed by reasoning, may vary between runs
  - Backlog empty → report "No open issues found" and exit without table
  - On failure: report what was analyzed, Block via Block Comment Template

### Current Inputs/Outputs [source: commands/prioritize.md]

**Inputs received:**
- List of open issues from MCP (Bug query + optionally Feature query from Automation Config)
- Optional: metrics report from `./reports/metrics.md` for historical failure patterns and success rates
- `--limit <N>` flag (default 20) from command
- `--output <path>` flag (stdout or file)

**Outputs produced:**
- Prioritized backlog tables (P0/P1/P2) with per-issue dimension scores and rationale
- Dependencies graph (textual: issue_A → blocks → issue_B)
- Recommendations section (suggested batch for next /fix-bugs run, estimated cost if data available)

**Dispatch context:** Step 3 of /prioritize command (read-only pipeline, no state changes to issue tracker).

### Mode Adaptability Assessment

**What translates directly to non-code modes:**
- The 4-dimension assessment framework (impact, risk, effort, dependency) is domain-independent and directly applicable to prioritizing: research questions, strategy options, content pieces, stakeholder requests
- The fixed scoring formula (`score = (Impact × 2 + Risk × 1.5) / (Effort × 1) + dependency_bonus`) is mathematical and domain-agnostic
- The P0/P1/P2 tiering with named thresholds is reusable for any prioritization context
- The dependency graph construction (blocking relationships) works for any type of work item
- The "max 50 items" limit is a practical constraint, not a software constraint
- Vague items → default Effort = 3 with note is a sound fallback for any domain
- Transparency requirement (always show formula + per-dimension scores) is domain-independent good practice
- Historical data enrichment (reading prior metrics/patterns) has a non-code analog (reading prior research outcomes, past strategy results)

**What is hardcoded to software:**
- Input source is exclusively MCP-fetched issues (labels like "critical"/"blocker", issue state, comments)
- The Risk dimension definition is software-specific: "How critical is the affected code area? Core business logic = 5, cosmetic = 1" — in non-code modes, "affected code area" has no meaning
- Effort dimension signals: "description length, affected area size, multi-file refactoring" are software signals
- The dependency_bonus specifically accounts for software issue blocking relationships
- Historical data source is `[ceos-agents]` pipeline comments and metrics.md (software pipeline artifacts)
- Recommendations section "suggested batch for next /fix-bugs run" is pipeline-specific
- The "estimated cost" metric assumes software development cost estimation

**What would need to change:**
- Input source: generalize from MCP issues to any list of items (research questions, decisions, content pieces, strategy options) from any source
- Risk dimension: redefine for domain (e.g., for strategy: "How critical is this to the primary objective?"; for content: "How much damage does missing this cause?")
- Effort signals: replace "multi-file refactoring" signals with domain-appropriate complexity signals
- Dependency detection: currently relies on issue links and code area overlap; for non-code domains, need different dependency signals (logical prerequisite relationships)
- Recommendations: replace "batch for /fix-bugs" with domain-appropriate next-action advice
- Historical data: replace `[ceos-agents]` comment parsing with domain-appropriate history

**Key finding:** The scoring formula and tiering structure require NO changes for non-code modes. Only the dimension definitions and I/O plumbing need adaptation.

---

## Agent 5: reviewer (bonus analysis)

### Current Capabilities [source: agents/reviewer.md]

- **Model:** opus
- **Style:** Adversarial, evidence-driven, thorough
- **Role:** Senior Code Reviewer acting as quality gate
- **Goal:** Ensure the fix addresses root cause, follows project conventions, introduces no regressions.
- **Expertise declared:** Root cause vs symptom detection, security vulnerabilities, over-engineering detection, convention compliance, performance impact assessment.
- **Process steps:**
  1. Read bug report, triage analysis, impact report, and fixer output (changed files, approach, reasoning)
  2. Read actual code changes (every changed file via Read tool)
  3. Pre-judgment reasoning: does the approach make sense? Is there a simpler approach? Highest-risk aspects?
  4. Adversarial review checklist: root cause, completeness, conventions, regressions, security (SQL injection, XSS, auth bypass, information leakage), performance (N+1 queries, unnecessary loops), over-engineering, AC fulfillment per criterion (FULFILLED/PARTIALLY/NOT ADDRESSED)
  5. Edge case analysis for every changed file: null/undefined/empty, empty collections, zero/negative/overflow, type coercion, race conditions, early returns, error handler paths
  6. Issue count gate: MUST identify at least 3 specific issues per review; if fewer, re-examine for architectural violations, missing documentation, integration risks, dependency concerns; may approve with fewer only with per-checklist-item justification
  7. Output: Code Review block (Verdict: APPROVE/REQUEST_CHANGES/BLOCK, Issues list with HIGH/MEDIUM/LOW, AC Fulfillment section)
- **Reviewer loop:** Iterative with fixer (max 5 iterations); in iteration 2+, first verify prior issues addressed; do NOT raise new issues on already-approved code; after max iterations on unresolved Critical → BLOCK
- **Constraints:**
  - NEVER modify code
  - NEVER run build or test commands
  - NEVER approve with zero findings without per-checklist justification (minimum 7 checklist items)
  - NEVER block a correct fix for style nitpicks
  - BLOCK only for: fix fundamentally wrong, security vulnerability, zero changed files, max iterations on Critical issue

### Mode Adaptability Assessment

**What translates to non-code modes:**
- The adversarial review stance and "assume problems exist" mindset applies to any content review
- The issue severity framework (HIGH/MEDIUM/LOW with defined meaning per tier) is reusable
- The "minimum 3 issues" gate with escalating re-examination is a quality discipline that applies to any review
- AC fulfillment tracking (FULFILLED/PARTIALLY/NOT ADDRESSED) is directly reusable for non-code content against stated objectives
- Over-engineering detection maps to: unnecessary complexity in analysis, scope creep in strategy docs
- The iterative loop (reviewer ↔ writer/fixer) is a universal content refinement pattern

**What is hardcoded to software:**
- The review inputs are code-specific (changed files, diff, triage analysis, impact report)
- Security vulnerability checklist (SQL injection, XSS, auth bypass) is code-specific
- Performance checklist (N+1 queries, blocking calls) is code-specific
- Edge case analysis is code-specific (null/undefined, type coercion, race conditions)
- Convention compliance references project coding style from CLAUDE.md

**What would need to change:**
- Replace security/performance/edge-case checklists with domain-appropriate quality criteria (e.g., for analysis: logical consistency, source reliability, causal validity; for strategy: feasibility, stakeholder alignment, measurability)
- Replace "code changes / changed files" as input with the appropriate artifact (analysis report draft, strategy document, content piece)
- Convention compliance: replace coding style check with domain style guide adherence

---

## Agent 6: code-analyst (bonus analysis)

### Current Capabilities [source: agents/code-analyst.md]

- **Model:** sonnet
- **Style:** Methodical, detail-oriented, risk-aware
- **Role:** Senior Software Engineer specializing in codebase impact analysis
- **Goal:** Map the complete impact zone of a bug fix — affected files, callers, dependencies, test coverage gaps, risk level.
- **Expertise declared:** Call hierarchy tracing, dependency analysis, test coverage assessment, risk classification.
- **Process steps:**
  1. Read triage analysis (summary, area, reproduction steps)
  2. Find relevant source files (Grep by keywords, Glob by name)
  3. Trace call hierarchy — find all callers of affected function/method; assess risk per caller
  4. Identify dependencies: database entities, services, UI components, APIs
  5. Check test coverage: find test files for affected module, assess coverage
  6. Analyze relevant history: last 10 commits per affected file (git log), [ceos-agents] comments on related issues, recurring patterns (off-by-one, null pointer, race conditions, recent refactoring)
  7. Output: Impact Report (root cause location, affected files max 5, callers at risk, test coverage, risk level LOW/MEDIUM/HIGH, historical context, suggested approach)
- **Constraints:**
  - NEVER modify code — read-only
  - Max 5 affected files; if more → HIGH RISK flag, list 5 most critical
  - Risk levels: LOW = isolated, 1-2 callers; MEDIUM = 3-10 callers; HIGH = >10 callers or public API or cross-module
  - Historical context is supplementary; never block on missing history
  - On failure: report findings so far, Block

### Mode Adaptability Assessment

**What translates to non-code modes:**
- The methodical decomposition of "what does this touch?" is domain-independent
- Risk classification framework (LOW/MEDIUM/HIGH with defined criteria) is reusable
- Historical pattern detection (recurring issues in same area) applies to any knowledge domain
- The "suggested approach" (high-level direction, not implementation) is domain-agnostic
- The max-5-items discipline prevents analysis paralysis

**What is hardcoded to software:**
- All mechanics assume a software codebase: Grep/Glob file search, call hierarchy tracing, function/method callers, test file detection, git log history
- Risk criteria defined in terms of callers, public APIs, cross-module impact
- The dependency types are software-specific (database entities, services, UI components, APIs)
- "Test coverage" assumes software tests exist

**What would need to change for non-code modes:**
- This agent has the highest degree of software coupling of all six. Its core mechanics (file search, call tracing, test coverage) are software-specific by design. For non-code modes, an "impact analyst" would look entirely different: mapping information dependencies, source quality, logical chains — not call hierarchies.
- Conclusion: code-analyst is NOT a viable reuse candidate for non-code modes without a near-complete rewrite. It would be a different agent that shares only the risk-classification vocabulary.

---

## Capability Gap Matrix

| Capability Needed | analysis mode | strategy mode | content mode | Covered by existing agent? | Which? |
|-------------------|:------------:|:------------:|:-----------:|:-------------------------:|--------|
| Ingest unstructured input and extract structured spec | Yes | Yes | Yes | Partially | spec-analyst (but MCP-only input; needs generalized input) |
| Validate document completeness and quality | Yes | Yes | Yes | Partially | spec-reviewer (but REQUIRED sections are software-specific) |
| Generate structured document from user brief | Yes | Yes | Yes | Partially | spec-writer (but output template is software-specific) |
| Prioritize a list of items by impact/effort/risk | Yes | Yes | Yes | Yes (with redefinition of dimension semantics) | priority-engine |
| Assess size and decompose into sub-tasks | Yes | Yes | Yes | Partially | spec-analyst (feature-size logic is domain-independent) |
| Adversarial quality review of a produced artifact | Yes | Yes | Yes | Partially | reviewer (but security/edge-case checklists are code-specific) |
| Detect scope creep / YAGNI violations | Yes | Yes | Yes | Yes | spec-reviewer (YAGNI enforcement is domain-independent) |
| Verify output against stated objectives (compliance check) | Yes | Yes | Yes | Yes | spec-reviewer --verify mode (conceptually reusable; evidence source changes) |
| Iterative refinement loop (writer ↔ reviewer) | Yes | Yes | Yes | Yes | spec-writer + spec-reviewer loop pattern is fully reusable |
| Interactive clarification with user | Yes | Yes | Yes | Yes | spec-writer interactive mode (one question at a time, max 10) |
| Domain expertise: data analysis / statistics | Yes | No | No | No | None |
| Domain expertise: competitive / market analysis | No | Yes | No | No | None |
| Domain expertise: content strategy / SEO / editorial | No | No | Yes | No | None |
| Assess logical consistency / causal validity of claims | Yes | Yes | No | No | No (reviewer checks code correctness; no claim-logic checker exists) |
| Detect contradictions in non-code documents | Yes | Yes | Yes | Partially | spec-reviewer consistency check, but reoriented |
| Ingest non-tracker inputs (URL, file, paste, conversation) | Yes | Yes | Yes | No | None (spec-analyst is MCP-only; spec-writer accepts text but via scaffold) |
| Source reliability / citation quality assessment | Yes | No | No | No | None |
| Stakeholder / audience analysis | No | Yes | Yes | No | None |
| ROI / business case evaluation | No | Yes | No | No | None |
| SEO / readability / style adherence | No | No | Yes | No | None |
| Risk assessment for non-software decisions | No | Yes | No | Partially | priority-engine Risk dimension (but defined for software areas) |
| Feasibility assessment for non-software plans | No | Yes | No | No | None (spec-reviewer does feasibility but for software tech stacks) |
| Track completion against non-code criteria | Yes | Yes | Yes | Yes | spec-reviewer --verify mode (concept is reusable) |

---

## True Gaps (not coverable by existing agents)

The following capabilities are genuinely absent from the existing 18-agent roster and cannot be achieved through mode parameters alone. Each requires new agent definitions with distinct expertise, process, and output formats.

### Gap 1: Flexible Input Ingestion

All existing agents assume either (a) a software codebase on disk or (b) an issue tracker via MCP as the input source. No agent can ingest: a URL, a PDF, a pasted document, a set of uploaded files, or a free-form conversation transcript as its primary input artifact.

For non-code modes to be viable, a new intake capability is needed that accepts arbitrary input sources and normalizes them into a structured brief. This could be a new agent or a command-level normalization step, but the capability does not exist.

### Gap 2: Domain Expertise — Analysis Mode

The existing agents collectively possess software engineering expertise (spec-writer, spec-analyst, architect), requirements validation expertise (spec-reviewer), and prioritization mathematics (priority-engine). None possesses analytical domain knowledge: how to assess statistical claims, identify methodological flaws in research, evaluate data quality, distinguish correlation from causation, or structure an analysis from hypothesis through evidence to conclusion.

spec-writer's "visionary, comprehensive" style and spec-analyst's "requirements-focused, clarity-driven" style are both oriented toward building things. Analysis mode needs an agent oriented toward understanding and explaining things — a fundamentally different epistemic posture.

### Gap 3: Domain Expertise — Strategy Mode

No existing agent understands strategy-specific concepts: competitive landscape analysis, stakeholder mapping, scenario planning, options appraisal, decision criteria weighting, SWOT/PESTLE frameworks, or business case construction. priority-engine scores issues on impact/risk/effort but does not reason about strategic trade-offs, long-term positioning, or organizational feasibility.

### Gap 4: Domain Expertise — Content Mode

No existing agent understands content-specific quality dimensions: audience fit, readability, editorial voice, SEO considerations, information hierarchy, call-to-action effectiveness, or publication format requirements. spec-reviewer checks AC testability and consistency; it has no notion of "does this content serve its audience?"

### Gap 5: Logical/Causal Validity Checking

spec-reviewer checks internal consistency (do the tech stack choices match the architecture?) and feasibility (are NFR targets realistic?). These are structural and factual checks. No agent checks whether the reasoning is valid — whether stated conclusions follow from the evidence presented, whether causal claims are supported, whether arguments contain logical fallacies.

This is a genuine new capability needed for analysis and strategy modes where the core output is not a list of implementation tasks but an argued position or recommendation.

### Gap 6: Feasibility Assessment for Non-Software Plans

spec-reviewer does feasibility assessment, but it is defined as: "Are the features achievable within the tech stack? Are NFR targets realistic?" This is feasibility-as-technical-constraint. Strategy mode requires a different feasibility assessment: can this organization actually execute this plan given its resources, culture, and market position? This requires new reasoning — spec-reviewer cannot be meaningfully parameterized to cover it.

### Non-Gaps (previously might have seemed like gaps)

- **Document quality review loop:** Covered by spec-reviewer adapted with domain-appropriate REQUIRED sections. No new agent needed.
- **Prioritization engine:** Covered by priority-engine with redefined dimension semantics. No new agent needed.
- **Structured output generation:** Covered by spec-writer with configurable output template. No new agent needed; a mode parameter and template injection suffice.
- **Iterative refinement:** The spec-writer ↔ spec-reviewer loop pattern is fully reusable for any writer ↔ reviewer pair. No new orchestration agent needed.
- **Scope management:** YAGNI enforcement in spec-reviewer and the 7-epic cap in spec-writer are both domain-independent when the limits are configurable. No new agent needed.
