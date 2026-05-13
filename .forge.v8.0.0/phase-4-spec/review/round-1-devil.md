# Phase 4 Spec — Devil's Advocate Review (Round 1)

**Reviewer role:** Adversarial — find logical bugs, semantic gaps, dangerous undefined behaviour
**Date:** 2026-04-27
**Artifacts reviewed:**
- `.forge/phase-4-spec/final/requirements.md`
- `.forge/phase-4-spec/final/design.md`
- `.forge/phase-4-spec/final/formal-criteria.md`

---

## Verdict

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": true,
    "no_regressions": true,
    "lint_clean": true,
    "pass": true
  },
  "tier_2": {
    "fail_to_pass": null,
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true
  },
  "tier_3": {
    "correctness": 3,
    "completeness": 3,
    "security": 3,
    "maintainability": 3,
    "robustness": 2,
    "weighted_aggregate": 2.95,
    "pass": false
  },
  "overall_verdict": "FAIL",
  "confidence": 0.82,
  "findings": [
    {
      "id": "f-a1b2c3",
      "severity": "BLOCKER",
      "criterion": "correctness",
      "location": "requirements.md REQ-OVR-003 + design.md Section 2.1",
      "description": "TOML circular/cross-agent overlay reference is unspecified. The spec defines per-agent overrideable keys but nowhere states that one agent's TOML file CANNOT reference another agent's file or CANNOT include any TOML 'include' directive. More critically: the spec schema in design.md Section 2.1 includes a top-level [meta] table with key `priority_label`. This key is NOT listed as overrideable in any per-agent schema table (Section 2.2 lists only `[limits]` and `[meta]` as table keys but the `[meta]` column values in 2.2 are just '[meta]' — no sub-keys enumerated). REQ-OVR-004 says to halt on 'a key not in the per-agent overrideable set'. But the overrideable set for [meta] is never enumerated. Phase 6 implementor will not know if `[meta].priority_label` is a valid key to accept or reject. This is an unimplementable REQ as written.",
      "recommendation": "Either explicitly enumerate [meta] sub-keys in the per-agent table (Section 2.2) or explicitly declare [meta] as a free-form table (all sub-keys accepted, no validation). One of these two paths must be chosen and stated in REQ-OVR-003."
    },
    {
      "id": "f-b3c4d5",
      "severity": "BLOCKER",
      "criterion": "robustness",
      "location": "requirements.md REQ-MODE-007 + design.md Section 5.2",
      "description": "The --step-mode prompt says 'Step {NN}/{total} completed'. But 'total' is the total number of steps in the pipeline. For fix-bugs that is 7 steps (01..07), so 'total=7'. However REQ-STEPS-002 specifies that step override path resolution happens at dispatch time — meaning a step MIGHT be conditionally skipped (e.g., 03-reproduce.md is 'optional, conditional dispatch' per design.md Section 4.1). If step 03 is skipped, does the counter show '3/7' for step 04 or '3/6'? The spec is silent on whether 'total' means 'all physical step files' or 'steps actually dispatched in this run'. This is not a cosmetic issue: the 's' escape output (Section 5.2) says 'Skip remaining gates' — but if 3 of remaining 4 steps are already conditional-not-triggered, what does 'skip' accomplish semantically? The user may think they are skipping something meaningful when 3 of 4 steps would have been skipped anyway. The spec needs to define 'total' precisely.",
      "recommendation": "Define 'total' in REQ-MODE-007 as either (a) physical file count (predictable, consistent) or (b) planned dispatch count for this run (dynamic, contextually accurate). State the definition explicitly. Add a note that conditional steps not triggered do not appear in the step-mode counter."
    },
    {
      "id": "f-c5d6e7",
      "severity": "BLOCKER",
      "criterion": "robustness",
      "location": "requirements.md REQ-STEPS-002 + design.md Section 4.2 item 2",
      "description": "Step override resolution uses 'exact {NN-name}.md string match'. The spec says 'Mismatched name = no override (silent fall-through to default)'. This is a silent failure mode: if a user creates `customization/steps/fix-bugs/4-fixer-reviewer-loop.md` (one digit, not two: '4' vs '04') the override is silently ignored and no warning is emitted. REQ-STEPS-003 only specifies logging when an override IS active, not when a near-miss override file exists but does not match. The spec should require a fuzzy-match warning for files that look like intended overrides but fail exact-match.",
      "recommendation": "Add a REQ (or amend REQ-STEPS-003) specifying: WHEN a file exists under `customization/steps/{skill}/` that does NOT exactly match any step filename but matches a step filename after case-normalization or zero-padding correction, THE plugin SHALL emit [WARN] 'Possible misnamed step override: {file} — did you mean {canonical-name}?'. Without this, silent misconfiguration is a real failure mode that will waste user debugging time."
    },
    {
      "id": "f-d7e8f9",
      "severity": "MAJOR",
      "criterion": "correctness",
      "location": "requirements.md REQ-SETUP-004 + design.md Section 1.4",
      "description": "/setup-agents idempotent regen conflict: spec says 'IF the existing file's first line matches ^# generated: THEN re-generate'. But REQ-SETUP-005 says 'BEFORE writing ANY TOML file, THE /setup-agents skill SHALL display a preview diff AND SHALL prompt the user with options Apply / Skip / Abort UNLESS the --yolo flag is supplied'. These two REQs contradict each other on the user experience path for idempotent regen: REQ-SETUP-004 implies automatic regen (no prompt needed, it is 'safe'), but REQ-SETUP-005 says ANY file write requires a preview prompt. The resolution — does the user get prompted for a generated-header file regen? The design.md flowchart (Section 1.4 step 4) shows: 'elif existing exists AND not # generated: header: SKIP + WARN' BUT does NOT show the preview-then-prompt step for the generated-header regen case. The flow in design.md appears to show auto-write without preview for the generated-header case, while REQ-SETUP-005 says otherwise.",
      "recommendation": "Resolve the contradiction explicitly: either (a) REQ-SETUP-004 idempotent-regen STILL triggers the preview-diff prompt per REQ-SETUP-005 (user sees what changed), or (b) idempotent-regen is exempt from the preview prompt (auto-overwrite when header matches). Both are defensible but must be explicit. The current conflict will cause Phase 6 implementor to make a guess."
    },
    {
      "id": "f-e9f0a1",
      "severity": "MAJOR",
      "criterion": "correctness",
      "location": "requirements.md REQ-MIG-002 step 3 + REQ-MIG-003",
      "description": "Migration merging ambiguity for the test-engineer case: REQ-MIG-002 step 3 says 'For each agent rename in REQ-AGT-001 mapping, rename the source customization/ file to the new name AND archive the old name's content to a [[process_additions]] block.' But the test-engineer case is NOT a rename — the v7 'test-engineer' name is KEPT in v8.0.0 (REQ-AGT-003 says 'merged test-engineer agent'). So if a project has `customization/test-engineer.md` (a legitimate v7 file targeting the old unit-only test-engineer), what does the migration do? It cannot 'rename' because the name did not change. It cannot 'archive old content' because the file name is the same. The spec's migration logic assumes all 3 merges are pure renames, but the test-engineer merge is an EXTENSION (same name, new --e2e capability). REQ-AGT-006 lists 'test-engineer-e2e alias if any' and 'e2e-test-engineer' as deprecated names but does NOT address a project that had a legitimate `customization/test-engineer.md` targeting unit-only behavior — does migration touch it at all?",
      "recommendation": "Add explicit migration handling for the test-engineer non-rename case: `customization/test-engineer.md` (if present) should be converted to `customization/test-engineer.toml` per normal .md→.toml conversion (REQ-MIG-003) WITHOUT any rename or phase-split logic. And `customization/e2e-test-engineer.md` (if present) should be converted to a `customization/test-engineer.toml` `[[process_additions]]` entry tagged for `--e2e=true` phase context. This distinction is currently unspecified."
    },
    {
      "id": "f-f1a2b3",
      "severity": "MAJOR",
      "criterion": "completeness",
      "location": "requirements.md REQ-AGT-006 + design.md Section 3.1",
      "description": "The deprecation alias matrix is missing the state.json reader compatibility path. REQ-AGT-007 says old keys (triage_completed_at, code_analyst_completed_at) ARE STILL WRITTEN in v8.0.0 for legacy /pipeline-status consumers. But /pipeline-status itself is being RENAMED from /status in v7.0.0 (per MEMORY.md v7.0.0 scope). The spec does not address the interaction between the /pipeline-status rename happening in v7.0.0 and the v8.0.0 state.json transitional alias keys. Specifically: does the v8.0.0 /pipeline-status skill read BOTH old keys AND new keys from state.json, or only new keys? If it reads both, what does it do with duplicate completion timestamps (e.g., `triage_completed_at` == `analyst_triage_completed_at`)? The display logic is undefined.",
      "recommendation": "Add a REQ clarifying /pipeline-status skill state.json reading logic in v8.0.0: either (a) reads only v8 keys (new names) and ignores v7 alias keys (clean break), or (b) reads both and deduplicates by preferring v8 keys. Also cross-reference that the v7.0.0 skill rename (/status → /pipeline-status) is assumed complete BEFORE v8.0.0 execution."
    },
    {
      "id": "f-c4d5e6",
      "severity": "MAJOR",
      "criterion": "correctness",
      "location": "requirements.md REQ-MIG-006 + formal-criteria.md AC-MIG-005",
      "description": "Pipeline Profiles migration writes 'Skip stages: [analyst-impact]' and adds a comment `// migrated v7→v8 by /migrate-config`. But the Pipeline Profiles section of Automation Config uses table format per CLAUDE.md ('All sections use table format | Key | Value |'). A '// comment' line is NOT valid in a Markdown table — it would corrupt the table structure. AC-MIG-005 verifies the resulting CLAUDE.md SHALL contain the string '// migrated v7→v8 by /migrate-config' but doesn't verify the table remains parseable. The spec for migration comment injection into a Markdown table is inherently broken.",
      "recommendation": "Change the migration comment injection to use either (a) a standard Markdown comment `<!-- migrated v7→v8 by /migrate-config -->` placed ABOVE the table (not inside it), or (b) an additional `| Migration note | migrated v7→v8 by /migrate-config |` row in the table. Update REQ-MIG-002 step 4 and AC-MIG-005 accordingly."
    },
    {
      "id": "f-d6e7f8",
      "severity": "MAJOR",
      "criterion": "robustness",
      "location": "requirements.md REQ-MODE-008 + design.md Section 5.3",
      "description": "Ctrl+C / SIGTERM during --step-mode is unspecified. REQ-MODE-008 specifies state persistence when user selects 'a' (Abort) through the prompt. But what happens when the user hits Ctrl+C mid-step (not at the per-agent pause prompt, but while an agent is actually running inside a step dispatch)? The state.json may be in a partially-written state. The spec says 'exit gracefully with code 0' for the 'a' choice, but a SIGTERM/Ctrl+C would cause a different exit code and potentially leave state.json inconsistent. The v6.9.0 spec (referenced via NEEDS_CLARIFICATION) does not cover this case either. The issue is compounded because /resume-ticket reads last_completed_step — if the step was partially executed when Ctrl+C happened, that step is NOT in state.json and /resume-ticket will re-execute it from scratch, potentially causing a double-dispatch of an agent (e.g., double fixer invocation).",
      "recommendation": "Add a REQ specifying state.json write atomicity for --step-mode: WHEN a step is dispatched AND process receives SIGTERM or equivalent, THE skill SHALL NOT update last_completed_step for the in-flight step (i.e., the interrupted step is treated as not-completed and will be re-run on resume). This is the safe default. Document that re-running a step is idempotent by design (the fixer will see the same codebase state)."
    },
    {
      "id": "f-e8f9a0",
      "severity": "MAJOR",
      "criterion": "completeness",
      "location": "requirements.md REQ-DOC-005 + REQ-DOC-006",
      "description": "REQ-DOC-005 enumerates 18 agent names in a specific ORDER. REQ-DOC-006 requires skill enumeration. But the CLAUDE.md itself (which is one of the 5 files in REQ-INV-004) is NOT listed as a documentation UPDATE target in Section 3.7 (Documentation Deliverables). REQ-DOC-005 updates docs/reference/agents.md, but CLAUDE.md contains the 'Architecture: 2-Layer System' section that lists 21 agents in its pipeline descriptions. The pipeline diagram in CLAUDE.md will become stale post-v8.0.0 — it explicitly names 'triage-analyst', 'code-analyst', 'e2e-test-engineer', 'reproducer', 'browser-verifier' in the Bug-Fix Pipeline and Feature Pipeline sections. REQ-INV-004 covers enumeration parity but REQ-INV-004 is a VERIFICATION req, not an update req. No REQ mandates that CLAUDE.md ITSELF be updated to replace old agent names in its pipeline text. Phase 6 may update the count but leave stale agent names in the pipeline description text.",
      "recommendation": "Add an explicit REQ-DOC-014 (or amend REQ-DOC-012 scope) specifying: CLAUDE.md SHALL be updated to replace all 6 deprecated agent names in its pipeline description sections (Bug-Fix Pipeline, Feature Pipeline, Scaffold Pipeline) with v8.0.0 consolidated names. The agent list in the Architecture section SHALL be updated from 21 to 18 with full enumeration. The skills count in the Architecture section SHALL be updated from 28 to 29. This REQ must exist separately from REQ-INV-004 which is a verification-only REQ."
    },
    {
      "id": "f-f0a1b2",
      "severity": "MAJOR",
      "criterion": "completeness",
      "location": "requirements.md REQ-MODE-009 + formal-criteria.md AC-MODE-009",
      "description": "The '20-word / technical term' brainstorm heuristic is specified in REQ-MODE-009 but its detection logic is a blackbox. REQ-MODE-009 says 'vague-description heuristic auto-skips brainstorm when description is technical and >= 20 words'. AC-MODE-009 tests this with 'a long technical description with at least 20 words and concrete tech terms'. However: (a) what counts as a 'technical term'? The spec does not define the term set. (b) What happens with a 20-word description that has no technical terms — is brainstorm triggered? (c) What about a 5-word description with 3 technical terms? The spec says 'technical AND >= 20 words' (conjunction) but the OQ-B.1 resolution only says 'empirically validated in production scaffold runs (BIFITO, drmax)' — those are internal projects not visible to Phase 5 TDD agent. The heuristic is described in natural language only, which means Phase 6 implementor will make assumptions that may not match what Phase 5 TDD writes test cases for.",
      "recommendation": "The heuristic must be formally defined in requirements.md, not just referenced as 'current trigger without modification'. Minimum spec: 'A description is NON-VAGUE iff (a) word_count >= 20 AND (b) it contains at least one of the following patterns: [version number, command syntax, file extension, framework/language keyword list OR a token matching \\b(API|SDK|OAuth|REST|GraphQL|Docker|Kubernetes|React|TypeScript|Python|Java|Rust|Go|PostgreSQL|Redis|Nginx|CI/CD|JWT|WebSocket)\\b].' Any spec is better than none. Phase 5 TDD cannot write reliable tests for an unspecified heuristic."
    },
    {
      "id": "f-a2b3c4",
      "severity": "MAJOR",
      "criterion": "correctness",
      "location": "requirements.md REQ-DOC-009",
      "description": "REQ-DOC-009 says 'THE existing docs/reference/pipeline.md SHALL be created or rewritten'. The word 'existing' contradicts 'created' — it cannot both exist and need to be created. But more importantly: design.md Section 8 (Documentation Deliverable Map) lists docs/reference/pipeline.md as 'UPDATE', implying it exists. The AC for this (AC-DOC-009) says 'THE file docs/reference/pipeline.md SHALL exist AND SHALL document...' — checked by grep + scenario. If this file does NOT currently exist (i.e., it is a NEW file), then Phase 8 AC-DOC-009 file existence check would fail if Phase 6 names it differently. The spec should verify whether this file exists right now and choose definitively: CREATE (new file) or UPDATE (existing file). This ambiguity will trip up Phase 6 plan agent.",
      "recommendation": "Verify whether docs/reference/pipeline.md currently exists. If it does not, change REQ-DOC-009 to say 'THE plugin repository SHALL contain a NEW file docs/reference/pipeline.md' (parallel to REQ-DOC-001..004 pattern). If it does exist, change to 'THE existing file... SHALL be rewritten'. Either way, remove the contradictory 'created or rewritten' phrasing."
    },
    {
      "id": "f-b4c5d6",
      "severity": "MAJOR",
      "criterion": "correctness",
      "location": "formal-criteria.md AC-INV-EMAIL-001",
      "description": "The maintainer email verification uses a negative grep heuristic: 'SHALL NOT contain any other email address in a maintainer-contact context (heuristic: emails matching pattern [a-z]+.[a-z]+@(ceosdata|anthropic|gmail).com other than filip.sabacky@ceosdata.com)'. This regex has a critical flaw: the domain list is hardcoded to (ceosdata|anthropic|gmail).com only. If SECURITY.md references any contact email at a domain NOT in this list (e.g., proton.me, outlook.com, gitea.io), the check passes even if another person's email is listed as a maintainer contact. The email_regex also does not handle subdomains (e.g., support@sub.ceosdata.com). More practically: CODE_OF_CONDUCT.md by Contributor Covenant 2.1 typically includes an enforcement email — if the enforcement email differs from filip.sabacky@ceosdata.com and is on a non-listed domain, the check silently passes with a stale enforcement contact.",
      "recommendation": "Replace the domain-allowlist negative grep with a whitelist approach: 'The ONLY email address present in each file for the maintainer-contact role SHALL be filip.sabacky@ceosdata.com. Verify by extracting all email-like tokens (regex: [\\w.+-]+@[\\w-]+\\.[\\w.]+) from the file and asserting the ONLY match is filip.sabacky@ceosdata.com OR the email appears in an unambiguously-non-maintainer context (e.g., a link to IANA example.com).' This is stricter but correct."
    },
    {
      "id": "f-c6d7e8",
      "severity": "MAJOR",
      "criterion": "completeness",
      "location": "requirements.md Section 3.7 (REQ-DOC-*) — scope gap",
      "description": "The A.1 spec Section 5 explicitly listed 'docs/reference/pipeline.md (NEW or rewrite)' as a documentation deliverable and also 'examples/configs/*.md — all 8 templates updated with TOML overlay examples (not just mention)'. The B.1 spec Section 3 explicitly listed 'docs/reference/skills.md — /scaffold skill description updated (3 modes → 3 flags)'. REQ-DOC-006 covers skills.md update. However, nowhere in REQ-DOC-006 is the /scaffold skill's description update (B6 modes → flags change) explicitly required. REQ-DOC-006 says 'contains exactly 29 skill names' and 'new /setup-agents row links to guide'. It does NOT require that /scaffold's own row description in skills.md be updated to reflect the removal of the interactive 3-mode prompt. Phase 6 could add the /setup-agents row and claim REQ-DOC-006 satisfied while leaving /scaffold description stale.",
      "recommendation": "Amend REQ-DOC-006 to add: 'The /ceos-agents:scaffold row description SHALL NOT reference the interactive mode selection prompt (a/b/c); it SHALL describe the --yolo, default, and --step-mode flags.' This pins down the specific B6 content update that must happen to the scaffold row."
    },
    {
      "id": "f-d8e9f0",
      "severity": "MINOR",
      "criterion": "correctness",
      "location": "requirements.md REQ-NF-003 + formal-criteria.md Section 6",
      "description": "REQ-NF-003 says agent files SHALL NOT contain hooks/mcpServers/permissionMode keys in YAML frontmatter 'anywhere'. The grep pattern in formal-criteria.md AC-INV-PERM-001 is '^(hooks|mcpServers|permissionMode):' with the note 'after stripping the YAML frontmatter delimiter ---'. But the grep pattern is line-anchored to the START of line (^), which is correct for frontmatter key detection. However: the grep is run as `grep -E '^(hooks|mcpServers|permissionMode):' agents/*.md` WITHOUT first extracting the YAML frontmatter block. If one of these key names appears in a markdown HEADING (e.g., '## hooks') or in a code block (e.g., ``` hooks: value ```), the regex would NOT match because the ^ anchor checks for the pattern at line start with the key followed by ':'. A markdown heading would be '## hooks' (not 'hooks:') so headings are fine. BUT if a code block in the agent file contains 'hooks: somevalue' as the first token on a line, the grep WOULD match and trigger a false positive failure. More importantly: the note says 'after stripping the YAML frontmatter delimiter ---' but the grep command shown does NOT strip frontmatter — it runs directly on *.md files. The implementation note and the verification command are inconsistent.",
      "recommendation": "Make the grep command consistent with the note: either (a) strip frontmatter first and only grep the body, or (b) only grep the frontmatter block (lines 2..N where line 1 is '---' and stop at the second '---'). Option (b) is the correct approach for this invariant. The bash scenario tests/scenarios/v8-invariant-plugin-perm-constraint.sh must implement frontmatter-only extraction."
    },
    {
      "id": "f-e0f1a2",
      "severity": "MINOR",
      "criterion": "maintainability",
      "location": "requirements.md REQ-STEPS-001 + formal-criteria.md AC-STEPS-001",
      "description": "REQ-STEPS-001 says SKILL.md entry point SHALL be <= 150 lines. But AC-STEPS-001 also says <= 150 lines. The design.md Section 1.1 shows the entry SKILL.md as '~100 lines'. The phase 4 spec says 150 in the AC but the source A.1 spec says '~100 lines'. These are inconsistent. Also: design.md Section 4.1 shows scaffold/SKILL.md at '~120 lines (mode flag parsing + brainstorm-if-vague)'. If scaffold/SKILL.md is expected to be ~120 lines and the line limit is 150, that's fine — but the spec text says 150 in two places (REQ and AC) while the design says 100. The design should be authoritative here: if the design says 100-120 then the test threshold of 150 gives a 25-50% headroom that could allow implementation drift. Similarly, REQ-STEPS-001 says '5-8 step files per pipeline' but design.md Section 4.1 shows scaffold with EXACTLY 8 step files and fix-bugs with EXACTLY 7. Phase 5 TDD must know: is 8 the maximum or is it OK to have 9?",
      "recommendation": "Align the line-count limits: set the AC threshold to 120 to match the design intent (buffer is fine but 150 is too loose). Confirm '8' is a hard maximum in REQ-STEPS-001 ('between 5 and 8 inclusive' is unambiguous)."
    },
    {
      "id": "f-f2a3b4",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "requirements.md REQ-OVR-007 + formal-criteria.md traceability index",
      "description": "REQ-OVR-007 requires logging overlay provenance to pipeline.log. Its primary ACs in the traceability index are 'AC-STEPS-003 (logging style example), AC-OVR-001 (provenance log inferred)'. Neither AC-STEPS-003 nor AC-OVR-001 explicitly tests that pipeline.log receives the entry 'agent={name} overlay_source={toml|md|none} overlay_path={path}'. AC-OVR-001 tests the merged model directive in the prompt, not the pipeline.log entry. AC-STEPS-003 tests a step override log line, not an overlay provenance log line. There is NO dedicated AC for REQ-OVR-007. The traceability index says 'inferred' which is a non-answer.",
      "recommendation": "Add AC-OVR-008: WHEN a reviewer is dispatched AND customization/reviewer.toml exists, THEN .ceos-agents/pipeline.log SHALL contain a line matching 'agent=reviewer overlay_source=toml overlay_path=customization/reviewer.toml'. VERIFIED BY bash scenario tests/scenarios/v8-overlay-provenance-log.sh (grep on pipeline.log after pipeline run)."
    },
    {
      "id": "f-a4b5c6",
      "severity": "MINOR",
      "criterion": "correctness",
      "location": "requirements.md REQ-AGT-006 — third bullet",
      "description": "REQ-AGT-006 says the plugin shall accept deprecated agent names in 'a tracker comment block referenced by /resume-ticket'. This means that if a pipeline was BLOCKED (block comment format: '[ceos-agents] Pipeline Block Agent: {name}...') with the old agent name (e.g., 'Agent: triage-analyst') and /resume-ticket reads that block comment to determine where the pipeline was blocked, the old name must be recognized. The spec says 'THE plugin SHALL accept it for one major version (v8.0.0) AND SHALL emit [WARN]'. But this raises a question: does /resume-ticket attempt to map 'triage-analyst' to 'analyst --phase triage' when re-dispatching? Or does it just log the WARN and proceed with the original agent name? If it proceeds with 'triage-analyst' as agent name, dispatch will fail (the file agents/triage-analyst.md no longer exists). The spec does not specify the re-dispatch mapping behavior for /resume-ticket.",
      "recommendation": "Add a sentence to REQ-AGT-006: 'WHEN a deprecated agent name is encountered in a tracker comment block during /resume-ticket dispatch, THE plugin SHALL map it to the corresponding v8 merged agent name per REQ-AGT-001 mapping table AND emit the WARN log, THEN dispatch the v8 merged agent.' This makes the alias functional, not merely logged."
    },
    {
      "id": "f-b6c7d8",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "requirements.md REQ-DOC-011 + formal-criteria.md AC-DOC-011",
      "description": "REQ-DOC-011 specifies 4 files for examples/customization/: reviewer-strict-security.toml, fixer-no-tests.toml, analyst-monorepo.toml, and step-override-example.md. The fourth file is 'step-override-example.md' — a README-style explanation. But design.md Section 2.3 provides TOML example content for the first three files. There is NO corresponding design example for step-override-example.md — the spec just says 'pointing to a sibling customization/steps/fix-bugs/04-fixer-reviewer-loop.md placeholder'. This 'sibling placeholder' would require ALSO creating customization/steps/fix-bugs/04-fixer-reviewer-loop.md in the examples directory, otherwise the example.md references a file that does not exist. But REQ-DOC-011 only lists 4 files, not this fifth file. AC-DOC-011 checks for 'AT LEAST these 4 files' which leaves the sibling placeholder creation unspecified.",
      "recommendation": "Either (a) add the sibling placeholder file to the REQ-DOC-011 file list (5 files minimum instead of 4), or (b) clarify that step-override-example.md should show the placeholder content INLINE (no separate sibling file needed). As written, Phase 6 implementor may or may not create the sibling file and both outcomes satisfy the AC."
    },
    {
      "id": "f-c8d9e0",
      "severity": "MINOR",
      "criterion": "maintainability",
      "location": "formal-criteria.md AC-CT-002",
      "description": "AC-CT-002 verifies skill count via 'find skills -maxdepth 2 -name SKILL.md -type f | wc -l'. After steps decomposition, skills/{skill}/steps/*.md files are inside skills/ subdirectories. The maxdepth 2 finds SKILL.md at depth 2 (skills/fix-bugs/SKILL.md). The steps/*.md files are at depth 3. So the count would correctly return 29. HOWEVER: if steps decomposition creates additional SKILL.md files for sub-skills (unlikely per spec, but not explicitly forbidden by the spec), the count would over-count. More practically: this AC uses maxdepth 2 but new /setup-agents skill creates skills/setup-agents/SKILL.md (depth 2 = OK). The concern is: will Phase 6 create skills/fix-bugs/steps/ directory without placing any SKILL.md inside it? Yes, per design. The AC should be fine as written — but the find command should explicitly exclude steps/ subdirectories for robustness.",
      "recommendation": "Amend AC-CT-002 find command to: `find skills -maxdepth 2 -name 'SKILL.md' -not -path '*/steps/*' -type f | wc -l`. This makes the invariant robust against future accidental SKILL.md placement inside steps/."
    },
    {
      "id": "f-d1e2f3",
      "severity": "MINOR",
      "criterion": "correctness",
      "location": "design.md Section 5.1 — mode flag parsing",
      "description": "The bash pattern for mutual exclusion check shown in design.md Section 5.1 uses the pseudocode 'if (--yolo + --step-mode both present)'. The corresponding advisory note says 'bash getopts insufficient for long-only flags; ad-hoc loop or getopt --longoptions preferred'. But the ad-hoc loop pattern shown does NOT actually enforce mutual exclusion at parse time — the loop sets MODE to whatever was last seen. If user passes '--step-mode --yolo', the loop sets MODE=yolo (last wins), no error is emitted. The SEPARATE mutual exclusion check (the if statement) must run AFTER the loop. The design pattern as written shows the if-check AFTER the loop, which IS correct. However the condition 'if (--yolo + --step-mode both present)' is never formally defined as 'if MODE was set by BOTH --yolo and --step-mode during parsing' — a separate boolean flag must track each. The pseudocode is misleading and may cause Phase 6 implementor to implement a subtly broken mutual exclusion (last-wins silently instead of error).",
      "recommendation": "Clarify design.md Section 5.1 pseudocode: use explicit flags (GOT_YOLO=false; GOT_STEP_MODE=false; set them in the loop; check after the loop 'if GOT_YOLO && GOT_STEP_MODE then error'). This is advisory for Phase 6 but the current pseudocode actively misleads."
    },
    {
      "id": "f-e3f4a5",
      "severity": "NIT",
      "criterion": "correctness",
      "location": "requirements.md REQ-OVR-004 — 'line number (if available)'",
      "description": "REQ-OVR-004 says the ERROR log SHALL include 'line number (if available)'. The qualifier 'if available' is appropriate because different TOML parsers report errors differently (some give line numbers, some do not). However, AC-OVR-004 only checks for 'non-zero exit code' and '[ERROR] log entry containing the file path'. The line number requirement from REQ-OVR-004 has no corresponding AC check. This is a minor traceability gap — the 'line number' part of REQ-OVR-004 is untested.",
      "recommendation": "Either (a) drop 'line number (if available)' from REQ-OVR-004 since it is unverifiable and implementation-dependent, or (b) add to AC-OVR-004: 'WHEN the TOML parser reports a line number, the [ERROR] log entry SHALL include it.' The current state is technically correct (if available = optional assertion) but the AC should be explicit about testing the optional case."
    },
    {
      "id": "f-a6b7c8",
      "severity": "NIT",
      "criterion": "correctness",
      "location": "requirements.md REQ-AGT-001 table + formal-criteria.md AC-AGT-001",
      "description": "Count arithmetic: REQ-AGT-001 says '21 - 3 = 18 via 3 paired merges'. The math is 21 agents - 6 old agents + 3 new agents = 18. But the table in REQ-AGT-001 shows 6 old agent rows mapping to 3 new agents, with the NOTE '(merged into above; secondary file deleted)' for code-analyst, e2e-test-engineer, browser-verifier. If the math is 21 - 3 = 18 then it assumes 3 net removals. But 3 paired merges means: merge A (2→1 = -1), merge B (2→1 = -1), merge C (2→1 = -1). Total: -3. 21 - 3 = 18. Correct. HOWEVER: in v7.0.0 context, 'test-engineer' already exists as one of the 21. The merge of 'test-engineer + e2e-test-engineer → test-engineer' keeps the name test-engineer. So the count goes from 21 to (21 - 1) = 20? No: e2e-test-engineer is DELETED and test-engineer is kept (extended). That IS -1 net. The math works. But design.md Section 3.1 says '(merged into above; secondary file deleted)' for e2e-test-engineer — the 'secondary' is e2e-test-engineer. This is correct. The NIT is that REQ-AGT-001 phrasing '21 → 18 via 3 paired merges' is technically ambiguous about whether it's '21 - 6 + 3 = 18' or '21 - 3 = 18' — both give 18 but through different mental models. The spec should state the formula explicitly.",
      "recommendation": "Add a parenthetical to REQ-AGT-001: 'via 3 paired merges: each merge eliminates 1 net agent (2 old agents → 1 new agent = -1 per merge × 3 = -3 total; 21 - 3 = 18).' This avoids any ambiguity for Phase 6 implementor counting agents."
    }
  ]
}
```

---

## Czech Adversarial Elaboration (≤350 slov)

Spec je technicky propracovaný a v mnoha aspektech výborný — Full EARS formality, 87 ACs, bidirectional traceability. Nicméně jsem identifikoval **3 BLOCKER** a **9 MAJOR** problémů, které dělají spec neimplementovatelným jako-je nebo nebezpečně nejednoznačným.

**Kritické (BLOCKERy):**

1. **[meta] tabulka s nedefinovanými klíči (f-a1b2c3):** Design.md 2.1 ukazuje `[meta]` jako validní TOML blok, ale Section 2.2 ho nezadefinovává. REQ-OVR-004 říká "halt on unknown key" — ale co je "known" klíč pro [meta]? Implementátor nemá odpověď.

2. **--step-mode `{total}` je ambiguous (f-b3c4d5):** U podmíněně přeskakovaných stepů (03-reproduce.md je optional) specifikace neříká, co "total" je. Ovlivňuje UX i semantiku 's' escape option.

3. **Silent step override miss (f-c5d6e7):** Překlep v filename (04 vs 4) tiše zahodí override bez jakéhokoli varování. Uživatel bude mít dojem, že override funguje, ale nebude. Tohle je failure mode, který garantovaně nastane v praxi.

**Zbylé MAJORy v kostce:**

- `/setup-agents` idempotent regen vs preview prompt jsou v přímém rozporu (f-d7e8f9) — REQ-SETUP-004 implikuje auto-write, REQ-SETUP-005 vyžaduje prompt pro JAKÝKOLI write.
- Migration tooling nezpracovává test-engineer non-rename case (f-e9f0a1) — jméno zůstává, ale merge semantika je odlišná od ostatních dvou párů.
- `// migrated` comment injection do Markdown tabulky by ji rozbil (f-c4d5e6) — tabulky neakceptují `//` komentáře.
- CLAUDE.md samotný nemá update REQ (f-e8f9a0) — REQ-INV-004 je verification-only; žádný REQ neříká "update CLAUDE.md pipeline descriptions to replace old agent names."
- Brainstorm heuristic je funkčně nespecifikovaná (f-f0a1b2) — Phase 5 TDD nemůže psát testy pro černou skříňku.

**Doporučení:** Spec potřebuje revision pass — zejména 3 BLOCKERy jsou blokující pro Phase 6 plan. Doporučuji revizi Phase 4 před Gate 2 (user approval).
