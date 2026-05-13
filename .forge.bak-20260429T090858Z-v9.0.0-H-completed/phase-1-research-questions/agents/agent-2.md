# Phase 1: Research Questions — Agent 2
# Focus: Production-System Case Studies (LangChain, AutoGen, OpenAI Assistants, MCP, smolagents)

---

## 1. How does LangChain's Pydantic-based tool schema evolve across versions when input/output contracts change — what is its breaking-change policy?

**Question:** In LangChain's tool/agent contract system (e.g., `BaseTool`, `StructuredTool`, `@tool` decorator with Pydantic v1/v2), what constitutes a breaking change in tool input/output schemas, and how has LangChain communicated and versioned those breaks in practice (e.g., the v0.1→v0.2 migration, the `invoke` vs `run` output contract split)?

**Why it matters:** ceos-agents must decide whether formalizing agent I/O contracts triggers a MAJOR bump under its versioning policy ("agent output format contract changes that external tooling/Agent Overrides may parse = MAJOR"). LangChain is the highest-volume production reference for this exact problem. Understanding where they drew the MAJOR line — and how they enforced backward compatibility at the schema boundary — directly informs the MAJOR vs. MINOR decision in Phase 3 brainstorm.

**Source hint:** LangChain changelog (github.com/langchain-ai/langchain), migration guides (`docs/langchain/migrations/`), LangChain v0.2 breaking-change announcement blog post (May 2024), Pydantic v2 migration impact on LangChain tool schemas.

---

## 2. What structured output contract does the Model Context Protocol (MCP) use for tool definitions, and how does it handle tool schema versioning in practice?

**Question:** MCP's tool-call specification (as of the 2024-11 schema) defines `inputSchema` (JSON Schema) for tool inputs. Does MCP specify an `outputSchema` for tool results, and if so in what format? How do MCP server implementations (e.g., the official TypeScript SDK, Python SDK, or third-party servers) handle versioning when a tool's input or output schema changes — do they use semver, schema version fields, or capability negotiation?

**Why it matters:** MCP is the closest structural analog to ceos-agents: markdown-described "agents" (tools) that are dispatched by an orchestrator (Claude Code). If MCP has already solved the "machine-readable I/O contract in a markdown-adjacent spec" problem, ceos-agents can adopt or adapt that approach rather than invent a new one. This directly informs the HOW (schema language and location) decision in Phase 3.

**Source hint:** MCP specification at `modelcontextprotocol.io/specification`, MCP TypeScript SDK source (github.com/modelcontextprotocol/typescript-sdk), `schema/2024-11-05/schema.json` in the MCP spec repo, MCP Python SDK `server.py` tool registration pattern.

---

## 3. In OpenAI Assistants API function-calling, what happens at runtime when a tool's JSON Schema definition is changed between runs — and what has that taught practitioners about "schema as contract" stability?

**Question:** OpenAI Assistants API stores tool definitions per-assistant. When developers update a tool's `parameters` JSON Schema (e.g., rename a field, add a required property, change a type), what runtime behavior occurs — does the assistant silently accept the new schema, raise an error, or require re-creation? What documented patterns have emerged (e.g., in OpenAI community forums, cookbooks) for evolving tool schemas without breaking in-flight runs?

**Why it matters:** The "do nothing" baseline argument for ceos-agents is that agent I/O contracts are prose-only and work fine (analyst outputs `## Triage Analysis`, skills grep for it). The OpenAI Assistants experience surfaces what actually breaks in production when implicit contracts are relied on across versions — this gives the brainstorm phase concrete evidence for or against formalizing contracts at all (the WHETHER question).

**Source hint:** OpenAI Assistants API docs (platform.openai.com/docs/assistants), OpenAI community forum threads on tool schema migrations, OpenAI Cookbook `assistants_tool_updates.ipynb` if available, developer blog posts on Assistants v1→v2 migration.

---

## 4. How does AutoGen's `FunctionCall` / `Tool` contract handle multi-modal agent outputs (text + structured data) — and does it use schema validation at dispatch time or post-hoc parsing?

**Question:** AutoGen (Microsoft, 0.4.x) defines agents that exchange `FunctionCall` and `FunctionExecutionResult` messages. For agents that return mixed content (e.g., a string verdict plus a JSON payload — analogous to ceos-agents analyst returning `## Triage Analysis` markdown plus a JSON `Reproduction steps` array), does AutoGen validate the result against a declared schema at dispatch time, or does the calling agent parse the result post-hoc? What is AutoGen's pattern for agents with polymorphic outputs (like ceos-agents' `--phase triage` vs `--phase impact`)?

**Why it matters:** ceos-agents has the same multi-modal output problem: analyst emits a markdown structure with an embedded JSON array (`Reproduction steps`) and plain-text fields. Phase 3 must decide whether the I/O contract covers both the markdown sections and the inline JSON, or only one layer. AutoGen's approach to this exact problem provides a concrete design reference. This informs the HOW decision.

**Source hint:** AutoGen 0.4.x source (github.com/microsoft/autogen), `autogen_agentchat/messages.py`, `autogen_core/tools/_function_tool.py`, AutoGen documentation on `FunctionTool` and `ToolAgent`.

---

## 5. What contract format does smolagents use for agent tool definitions, and does it enforce output schema at runtime or treat agent outputs as unvalidated strings?

**Question:** HuggingFace smolagents (2025) uses a `Tool` class with `inputs` (typed dict) and `output_type` (string, image, number, etc.) declared as class attributes. At runtime, does smolagents validate that the tool's return value conforms to `output_type`, or is it advisory only? For tools that return structured objects (dicts with multiple fields), how is the nested schema declared and whether it survives LLM-mediated invocation (the LLM may hallucinate output)?

**Why it matters:** smolagents is the most recent production framework with explicit `output_type` contracts — directly analogous to the ceos-agents problem of declaring what an agent returns. Its choice between "advisory schema" vs "runtime enforcement" is the same axis ceos-agents must decide. If smolagents made output_type advisory for good reasons (LLM non-determinism), that strengthens the "do nothing" baseline or the "optional contract" design option. This covers the WHETHER question from a current-generation system perspective.

**Source hint:** smolagents source (github.com/huggingface/smolagents), `smolagents/tools.py` `Tool` base class, smolagents documentation (huggingface.co/docs/smolagents), smolagents blog post "Building agents with smolagents" (HuggingFace, Jan 2025).

---

## 6. In production LangGraph deployments, how do graph node input/output schemas evolve — and what is the pattern for backward-compatible additions vs. breaking changes to a node's TypedDict schema?

**Question:** LangGraph (LangChain's stateful agent orchestration layer) defines node I/O via TypedDict state schemas. When a LangGraph workflow adds a new field to the state schema (analogous to adding a new field to a ceos-agents agent output section), is the addition automatically backward-compatible (old workflows still function) or does it break serialized checkpoints? What is the documented migration strategy for LangGraph state schema changes in production?

**Why it matters:** ceos-agents agent outputs are pipeline-state-like: analyst output feeds fixer, fixer output feeds reviewer. LangGraph's checkpointing + state schema evolution is the closest architectural analog for understanding whether additive I/O contract changes (new optional fields in `## Triage Analysis`) require a MAJOR bump or qualify as MINOR backward-compatible additions. Directly answers the versioning question for Phase 3.

**Source hint:** LangGraph docs (langchain-ai.github.io/langgraph), LangGraph persistence and checkpointing guide, LangGraph `StateGraph` class, community discussions on state schema migration (GitHub issues/discussions in langchain-ai/langgraph repo).

---

## 7. Does the "do nothing" baseline hold in production? What observable failure modes arise when agent output contracts are implicit (prose-only) in large-scale agent pipeline deployments?

**Question:** Across documented production deployments of agent pipelines (e.g., LangChain case studies, AutoGen enterprise deployments, internal engineering blogs from companies using multi-agent systems), what are the most common failure modes traced directly to implicit/undeclared agent output contracts — as opposed to logic errors, LLM hallucination, or infra failures? Are there quantified case studies showing that adding explicit contracts reduced a measurable failure rate?

**Why it matters:** The "do nothing" baseline (current ceos-agents: prose-only contracts, skills grep for `## Triage Analysis`) must be given a fair hearing in Phase 3 brainstorm. This question provides the adversarial evidence: if production systems rarely break due to implicit contracts, the cost of formalizing is unwarranted. If implicit contracts are a documented failure mode, that validates the investment. This is the core WHETHER question backed by production evidence.

**Source hint:** LangChain blog "Lessons from production" articles, AutoGen research paper (Wu et al., 2023) on failure mode taxonomy, Anthropic's agent reliability research (if public), practitioner post-mortems on agent pipeline breakages (e.g., Simon Willison blog, Eugene Yan agent reliability posts).

---

## 8. How do agent frameworks with markdown-defined agents (Crew AI, agency-swarm) declare and validate I/O contracts — and what is the effect on backward compatibility when they introduce structured schema?

**Question:** CrewAI and agency-swarm define agents in Python/YAML but allow natural-language task descriptions and expected outputs (analogous to ceos-agents' prose-embedded markdown). When CrewAI added the `output_json` / `output_pydantic` structured output fields to Task definitions (v0.28+), was the change backward-compatible with existing crew definitions, or did existing agents need modification? What was the adoption pattern — did users opt in or was it required?

**Why it matters:** ceos-agents is considering adding structured I/O contract sections to existing agent markdown files (18 agents, 297 tests). CrewAI's experience adding structured output declarations to an existing natural-language-first framework is a direct analog: it reveals whether such a change can be made additive/optional (MINOR) or inevitably breaks existing definitions (MAJOR), and whether the ecosystem actually adopts optional structured schema. This informs both the backcompat strategy and the versioning decision.

**Source hint:** CrewAI changelog (github.com/crewAIInc/crewAI), `crewai/task.py` `output_json` and `output_pydantic` fields, CrewAI migration guide for v0.28, agency-swarm source (github.com/VRSEN/agency-swarm) agent response handling.

---

## 9. What bash-testable assertion patterns are used in production agent framework test suites to validate I/O contract shape without executing the LLM — and how do they handle non-deterministic outputs?

**Question:** In agent framework test suites that validate agent I/O contracts via static/structural checks (not live LLM calls) — such as LangChain's integration tests, AutoGen's unit tests, or MCP server conformance tests — what specific assertion patterns are used? Do they use JSON Schema validation against fixture outputs, regex matching on section headings, AST comparison, or schema diff tools? How do they handle agents whose output structure varies conditionally (like ceos-agents analyst which includes `Reproduction steps` only for UI bugs)?

**Why it matters:** ceos-agents tests run in bash (`tests/harness/run-tests.sh`), use `grep -qE`, `find`, `wc -l`, `diff -q`, and must not call an LLM. The new I/O contract tests must follow the same pattern. This question provides production examples of what bash-compatible (or bash-adaptable) static contract validation looks like in real agent frameworks — directly informing the test strategy for Phase 3.

**Source hint:** LangChain `tests/unit_tests/tools/` in langchain-ai/langchain repo, AutoGen `test/` directory in microsoft/autogen repo, MCP conformance test suite (if available), pytest-jsonschema or jsonschema CLI usage patterns in CI pipelines.

---

## 10. When OpenAI's function-calling / tool-use spec introduced `strict: true` mode (2024), what backward-compatibility strategy did they use — and what does that teach about making schema validation opt-in vs. mandatory?

**Question:** In mid-2024, OpenAI introduced `strict: true` in function-calling tool definitions, which enforces that the LLM output exactly matches the declared JSON Schema (no additional properties, all required fields present). This was added as an opt-in flag alongside existing non-strict tool definitions. What was the technical rationale for opt-in vs. mandatory enforcement, and what failure modes did `strict: true` surface in tools previously working under non-strict mode? Were there cases where strict mode required schema changes to pre-existing tools?

**Why it matters:** ceos-agents must decide whether new I/O contracts are mandatory for all 18 agents (risks breaking v8.0.0 Agent Overrides) or opt-in/additive (agents without contracts continue working). OpenAI's `strict: true` design is the canonical production example of exactly this tradeoff at scale. The opt-in decision rationale directly maps to ceos-agents' backcompat constraint: v8.0.0 `customization/` overrides must work unmodified. This covers the backcompat AND whether questions simultaneously.

**Source hint:** OpenAI structured outputs announcement blog (August 2024), OpenAI API reference `tools[].function.strict`, OpenAI cookbook on structured outputs migration, community discussion on `strict: true` edge cases (OpenAI developer forum).

---

## 11. What is the ceos-agents v8.0.0 baseline failure rate attributable to output section name mismatch or structural inconsistency in agent outputs — as observable from the existing test scenarios and forge run archives?

**Question:** In the v8.0.0 forge run archive (forge-2026-04-25-001, FULL_PASS 0.863, 219/62/15 harness results), how many of the 62 failures or 15 skips were traceable to agent output format inconsistency (e.g., wrong section heading, missing field, unexpected output in a non-primary mode)? Separately, in `tests/scenarios/`, which existing test scenarios currently assert output section names or structure (e.g., `v8-agents-analyst-shape.sh`) — and do those assertions cover the embedded JSON `Reproduction steps` array format?

**Why it matters:** Before adding formal I/O contracts, Phase 3 needs to know whether the implicit contracts are already breaking in practice within the existing codebase. If the 62 failures in the v8 forge run are unrelated to output shape, the "do nothing" baseline is stronger. If output-shape failures are present but untested, the case for formalization is concrete and quantifiable. This is a codebase-inspection question (not requiring an LLM call) that grounds the WHETHER decision in measurable evidence from the actual project.

**Source hint:** `.forge/` archive for forge-2026-04-25-001 (if retained in repo), `tests/scenarios/v8-agents-analyst-shape.sh`, `tests/scenarios/frontmatter-completeness.sh`, `tests/scenarios/read-only-agents.sh`, ceos-agents v8.0.0 commit history.

---

## 12. What JSON Schema features are routinely omitted or restricted in agent framework tool schemas — and which subset is realistically expressible in a markdown YAML frontmatter block?

**Question:** Production agent frameworks (LangChain, AutoGen, OpenAI, MCP) each use a subset of JSON Schema 2020-12 for tool input schemas. Across these frameworks, which JSON Schema keywords are consistently absent from tool definitions in practice (e.g., `$ref`, `allOf`, `patternProperties`, `if/then/else`) — and which minimal subset (e.g., `type`, `properties`, `required`, `enum`, `items`) is sufficient to express the contracts that ceos-agents agents actually produce? Given that ceos-agents agent files use YAML frontmatter, which of these schema constructs are safely expressible in YAML without ambiguity?

**Why it matters:** The HOW decision (schema language and location) depends on what expressiveness is needed. If the minimal subset covers 18 agent contracts, a simpler schema language (typed field list, not full JSON Schema) may be preferable and more maintainable. If complex schemas are needed, JSON Schema in a sidecar file is better than YAML frontmatter. This question bounds the schema complexity requirement from real-world data rather than theoretical completeness, directly informing the schema language choice in Phase 3.

**Source hint:** LangChain `StructuredTool` Pydantic field types in use, OpenAI function calling examples across the cookbook, MCP `inputSchema` patterns in published MCP servers (github.com/modelcontextprotocol/servers), AutoGen tool definition examples, JSON Schema 2020-12 spec section on vocabularies.

---

## Summary

These 12 questions target the five required areas through the lens of production agent systems: whether (Q3, Q7, Q11), how (Q2, Q4, Q5, Q12), backcompat (Q8, Q10), versioning (Q1, Q6), and tests (Q9). The angle is deliberately empirical — each question asks what production systems *actually did* rather than what theory suggests. Questions Q1-Q10 draw on LangChain, MCP, OpenAI Assistants, AutoGen, smolagents, LangGraph, CrewAI, and OpenAI strict mode as primary sources, while Q11-Q12 ground the research in ceos-agents' own measurable baseline. Together they provide Phase 2 researchers with concrete, citation-ready evidence to support or challenge every major design decision in Phase 3.
