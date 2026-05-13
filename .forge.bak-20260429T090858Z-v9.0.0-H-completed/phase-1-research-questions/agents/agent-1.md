# Phase 1 Research Questions — Agent 1

## Concern Coverage

- whether (Q1, Q2)
- how (Q3, Q4, Q5)
- backcompat (Q6, Q7)
- versioning (Q8)
- tests (Q9, Q10)

---

## Questions

### Q1

**Question:** What observable pain points in production agent-orchestration systems (LangChain, AutoGen, OpenAI Assistants) have been attributed specifically to *absent* explicit I/O contracts — and does the cited evidence involve prose-only agents or only typed-schema agents?

**Why it matters:** This is the "whether" gate. If production harm from implicit contracts is documented only for statically-typed/compiled agents, the ceos-agents case (pure markdown, Claude Code Task tool dispatch, no runtime schema enforcement) may be structurally different. The "do nothing" baseline needs a fair hearing — evidence of harm, or its absence, drives the decision.

**Source hint:** AutoGen design docs (microsoft/autogen repo), LangChain agent docs, Anthropic's own tool-use design rationale docs (docs.anthropic.com), OpenAI Assistants Function Calling spec.

---

### Q2

**Question:** In pure-markdown or pure-prompt agent systems with no runtime schema enforcement (i.e., no compiled type checker, no JSON Schema validator at dispatch time), what class of failures has been empirically caused by missing explicit I/O contracts — versus failures caused by prompt quality, model inconsistency, or orchestration logic?

**Why it matters:** Still the "whether" question, but from a failure-class angle. If empirical failure modes in prose-agent systems cluster around prompt quality rather than contract mismatch, formalizing I/O contracts addresses a non-root-cause and the "do nothing" baseline wins. If they cluster around inter-agent hand-off data loss, contracts are load-bearing.

**Source hint:** Anthropic prompt engineering guide, LangChain and AutoGen GitHub issue trackers (search "agent output parsing"), published postmortems on multi-agent pipelines.

---

### Q3

**Question:** How does the Anthropic Claude Code Task tool actually dispatch agents — specifically: does it pass the full agent file (frontmatter + body) verbatim as the system prompt, or only selected sections? If it parses/strips frontmatter, where does any added YAML block land in the model context?

**Why it matters:** The "how" decision on contract location (frontmatter YAML block vs. dedicated `## Inputs` / `## Outputs` body section vs. sidecar file) hinges entirely on what the Claude Code Task tool passes to the model. A frontmatter-embedded schema that the Task tool strips is invisible to the agent — effectively dead.

**Source hint:** Claude Code documentation (docs.anthropic.com/claude-code), `/agents` command reference, inspect existing agent dispatch in skills/fix-bugs/SKILL.md to see the Task tool call shape.

---

### Q4

**Question:** What is the minimal schema expressiveness actually needed to describe the I/O surface of a polymorphic ceos-agents agent like `analyst` (which has two modes — `--phase triage` / `--phase impact` — each with distinct input requirements and output sections)? Specifically: does JSON Schema 2020-12's `oneOf`/`if-then-else` add enough expressive power over a typed-list format (e.g., a markdown table of field name + type + required/optional) to justify the readability and tooling overhead?

**Why it matters:** This is the "how" schema-language choice. If the actual I/O surface of the most complex agents (analyst, test-engineer with `--e2e`) can be described adequately with a simple typed-list table, the complexity of embedding full JSON Schema (which must remain human-readable inside a markdown file) is not justified. Conversely, if mode-dispatch polymorphism genuinely requires discriminated-union schemas, the typed-list format is structurally insufficient.

**Source hint:** JSON Schema 2020-12 spec (json-schema.org), analyst.md `## Phase Dispatch` section, test-engineer.md for `--e2e` variant.

---

### Q5

**Question:** What validation mechanism do production agent-orchestration frameworks use for inter-agent output contracts that must remain human-readable AND machine-checkable — and specifically, how do they handle the latency and side-effect constraints of "validate at runtime in the hot path vs. validate statically at commit/CI time"?

**Why it matters:** The "how" validation-mechanism choice determines whether the bash harness (currently 297 purely static grep/find assertions) can carry the full validation load, or whether runtime validation by dispatching skills is required. Runtime validation adds latency and complexity; static-only validation is insufficient if field types matter at dispatch time. The existing harness pattern strongly favors static approaches — confirming whether that is an acceptable tradeoff for this contract surface requires external evidence.

**Source hint:** AutoGen `agent_io_contracts.py`, LangChain output parser docs, Semantic Kernel agent contract design, Pydantic v2 BaseModel approach in agent outputs.

---

### Q6

**Question:** In the Claude Code plugin extension model, when a skill appends `## Project-Specific Instructions` from an override file to an agent's Task context, does adding a new body section (e.g., `## Inputs` / `## Outputs`) to the base agent file change the parsing behavior or context structure that override injection produces — or is the override appended verbatim regardless of agent body structure?

**Why it matters:** This is the core backward-compat question. If the override-injector appends strictly verbatim (as documented in `core/agent-override-injector.md`), new `## Inputs` / `## Outputs` sections in agent bodies are additive and cannot break existing `customization/` files. But if any skill or tool inspects agent body structure before injection, the additive assumption fails. Confirming the append-only behavior is the hard backward-compat guarantee.

**Source hint:** `core/agent-override-injector.md` (read), `skills/fix-bugs/SKILL.md`, `skills/fix-ticket/SKILL.md` — check Task tool call site for how agent file + override are concatenated.

---

### Q7

**Question:** If a new `## Inputs` or `## Outputs` section is added to an existing agent body and a v8.0.0 project has a `customization/analyst.md` override that also defines its own `## Inputs` or `## Outputs` section, what does the model receive — a duplicate heading collision — and how do modern LLM context parsers handle duplicate markdown headings in their effective context?

**Why it matters:** This is the subtle backcompat failure mode: even if the override-injector appends verbatim, heading name collision between base agent contract sections and user override files could create ambiguous context for the model. The design must either reserve heading names (documenting them as forbidden in override files) or choose section names that are unlikely to collide.

**Source hint:** Anthropic prompt engineering docs on system prompt structure, Claude model behavior with duplicate headings (empirical test if possible), existing override examples in `examples/` directory.

---

### Q8

**Question:** Under the ceos-agents Versioning Policy (CLAUDE.md: "agent output format contract changes that external tooling/Agent Overrides may parse = MAJOR; adding optional config sections = MINOR"), does adding `## Inputs` / `## Outputs` sections to all 18 agent files constitute a "breaking change in agent output format contract" — or is it additive — and what is the correct version bump: v9.0.0 (MAJOR) or a MINOR release under v8.x?

**Why it matters:** This directly determines the version number and all associated doc/changelog/tag work. The answer hinges on a specific interpretation of "contract" in the policy: if `## Inputs` / `## Outputs` is purely additive (projects that don't read these sections are unaffected), it is MINOR; if it obligates downstream skills or external tooling to handle new required sections, it is MAJOR. The MEMORY allocates v9.0.0 to this sub-project H — verifying whether that allocation is semantically correct is a versioning gate.

**Source hint:** CLAUDE.md "Versioning Policy" section (read), git log for v7→v8 and v6→v7 version bump commits to understand prior precedent for what triggered MAJOR bumps.

---

### Q9

**Question:** What is the minimal bash assertion pattern — using only `grep -qE`, `wc -l`, and `diff -q` (the existing harness primitives) — that can distinguish a *structurally valid* `## Inputs` / `## Outputs` block (correct heading, required subfields present) from a *malformed* one (heading present but subfields absent or misspelled) in a test scenario file of the form `tests/scenarios/v9-agents-{name}-io-contracts.sh`?

**Why it matters:** This is the test-strategy question. New test scenarios must use the existing harness primitives (no new tooling allowed without a separate decision). Understanding the minimum expressiveness needed to assert contract structure — before knowing the final contract format — determines whether the bash harness can cover the contract at all, or whether a dedicated validator script is required as a harness companion.

**Source hint:** `tests/scenarios/v8-agents-analyst-shape.sh`, `tests/scenarios/frontmatter-completeness.sh` (read 1-2 existing scenarios for patterns), `tests/harness/run-tests.sh` (confirm no additional assertion primitives available).

---

### Q10

**Question:** In the 297 existing test scenarios, how many assert properties of the agent body sections (Goal, Expertise, Process, Constraints) versus frontmatter only — and which agent-shape tests would require modification if a new mandatory body section (`## Inputs` / `## Outputs`) were added to all 18 agents?

**Why it matters:** This is the test-impact question. Before deciding whether contracts go in frontmatter or body, knowing the edit surface of the existing test suite is necessary. If 80% of existing tests only grep frontmatter, adding body sections is low-impact. If tests assert exact section order or section count, adding `## Inputs` / `## Outputs` would break them — which inverts the backcompat constraint from the agent files themselves to the test suite.

**Source hint:** `tests/scenarios/` directory — glob for `v8-agents-*-shape.sh` patterns, inspect `read-only-agents.sh`, `frontmatter-completeness.sh`, `v8-agents-enumeration.sh` for body vs. frontmatter scope of assertions.
