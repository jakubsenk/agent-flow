# Phase 1: Research Questions — Final (Synthesized)

## Executive Summary

The rename from "ceos-agents" to "agent-flow" for the v1.0.0 public OSS release is a large-scope, multi-category change touching approximately 160+ source files across agents, skills, core, docs, tests, examples, metadata, and CI configuration. Three blocking decisions must be resolved before Phase 2 execution begins: (1) whether the `ceos-agents-block` webhook event is being deliberately renamed to `agent-flow-block` for this release (the user has confirmed yes — see Critical Items), (2) whether the `.ceos-agents/` runtime state directory is renamed immediately or preserved under an alias for one transitional version, and (3) what CHANGELOG strategy is adopted (clean v1.0.0 start vs. curated capability summary). Phase 2 must produce a complete per-file occurrence map, resolve all three blocking decisions, and verify the current state of cross-file invariants before any rename execution begins.

---

## Critical Items (Priority 1)

### CRITICAL-1: Webhook event rename — `ceos-agents-block` → `agent-flow-block` [DECISION ALREADY MADE]

**Status: DECISION FINAL — the user has explicitly decided to rename `ceos-agents-block` to `agent-flow-block`. This overrides the backward-compatibility note in CLAUDE.md §Webhook Payloads.**

**What needs investigation in Phase 2:**
- Which files contain the literal string `ceos-agents-block` (skills, agents, tests, CLAUDE.md)?
- Which test scenarios assert `ceos-agents-block` as a never-renamed contract (e.g., `regression-existing-events-preserved.sh`, `v6.9.0-bc-no-removed-webhook-event.sh`)?
- The CLAUDE.md §Webhook Payloads backward-compat note ("existing payload fields `pr-created` and `ceos-agents-block` are never renamed or removed") must be rewritten to state `agent-flow-block`.
- Per the versioning policy, renaming a contracted webhook field is a MAJOR change — but since this IS the v1.0.0 public launch (a clean-slate reset), no MAJOR bump beyond v1.0.0 is required. The old `ceos-agents-block` contract is voided at public launch. Phase 2 must confirm whether any consumer migration note is needed.
- Search: `grep -rn "ceos-agents-block" . --include="*.md" --include="*.sh" --include="*.json" | grep -v ".forge"`

---

### CRITICAL-2: `dispatch_witness` sha256 seeds embed `ceos-agents:<agent>|` strings

**What it is:** The dispatch witness is a cryptographic integrity check. The sha256 seed format is `ceos-agents:<agent>|<timestamp>|<issue_id>`. The `check_dispatch_witness` function in `core/lib/stage-invariant.sh` verifies this hash at runtime. If the plugin namespace changes to `agent-flow` but the EXPECTED_AGENT_NAME strings and seed format are not updated atomically, every pipeline step will produce hash mismatches and block execution.

**What Phase 2 must confirm:**
- Every occurrence of `EXPECTED_AGENT_NAME = "ceos-agents:<agent>"` in `skills/*/steps/*.md` and `skills/*/SKILL.md`
- Every occurrence of `sha256("ceos-agents:<agent>|...")` seed format in skill step files and `core/lib/stage-invariant.sh`
- The fixture files `tests/fixtures/v10-witness/state-a.json`, `state-b.json`, `state-c.json` — their `agent_name` fields must be updated in sync
- Search: `grep -rn "EXPECTED_AGENT_NAME\|dispatch_witness\|ceos-agents:" skills/ core/ tests/ --include="*.md" --include="*.sh" --include="*.json"`

---

### CRITICAL-3: Internal Gitea URL in plugin.json and marketplace.json must be removed

**What it is:** Both `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` contain `"repository": "https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git"` — a private internal hostname. A test scenario `v6.9.0-installation-md-no-internal-host.sh` already asserts this string must NOT appear in user-facing files. The value must be replaced with the public GitHub URL `https://github.com/fsabacky/agent-flow` (or the confirmed public URL).

**Phase 2 must confirm:**
- The exact current content of `plugin.json` and `marketplace.json` (all fields: name, version, description, repository, license, author, plugins[])
- All other files containing `gitea.internal.ceosdata.com` or `ceosdata.com` hostnames
- The confirmed target public GitHub URL (currently assumed `https://github.com/fsabacky/agent-flow`)
- Search: `grep -rn "gitea.internal.ceosdata.com\|ceosdata.com" --include="*.md" --include="*.json" --include="*.sh" . | grep -v ".forge"`

---

### CRITICAL-4: `[ceos-agents]` block comment marker is runtime-parsed for pipeline auto-resume

**What it is:** The literal string `[ceos-agents]` in block comment and triage checkpoint messages is machine-parsed by entry-point skills (`/fix-bugs`, `/implement-feature`, `/scaffold`) for auto-resume logic. It appears in all 17 agent definition files and multiple skill step files. If this string is renamed to `[agent-flow]` without updating the parser in the entry-point skills atomically, all existing in-flight pipelines will lose auto-resume capability.

**Phase 2 must confirm:**
- All files containing `[ceos-agents]` as a literal string
- The specific parser code in entry-point skills that matches this prefix
- Whether any test scenarios assert the exact `[ceos-agents]` string in comment output
- Search: `grep -rn "\[ceos-agents\]" . --include="*.md" --include="*.sh" | grep -v ".forge"`

---

### CRITICAL-5: Version number reset — plugin.json/marketplace.json currently show `"10.2.0"`

**What it is:** Both metadata files currently declare `"version": "10.2.0"`. Releasing this on a public GitHub repository with no prior public history would confuse users (jumping from nothing to v10). The public launch must start at `"1.0.0"`.

**Phase 2 must confirm:**
- All files that hardcode `"10.2.0"` or `"version": "10"` and need updating
- Whether docs/reference/ contains any version badges referencing 10.x
- The versioning policy impact: does resetting to 1.0.0 require any CHANGELOG/README entry to note this is a clean-slate public launch of a previously internal tool?

---

## Category 1: Rename Inventory

### R-1: Total count and file list for "ceos-agents" in all source directories
How many source files (excluding `.forge/`, `.forge.bak-*/`, `.forge.v*/`) contain the string "ceos-agents", broken down by directory (agents/, skills/, core/, docs/, examples/, checklists/, tests/, root)? What is the total occurrence count by semantic category: (a) `ceos-agents:` skill prefix in Task dispatch calls, (b) `[ceos-agents]` comment markers, (c) `.ceos-agents/` filesystem paths, (d) `"name": "ceos-agents"` JSON identity fields, (e) install command strings, (f) repository URLs, (g) human-readable prose?

### R-2: Skill namespace prefix occurrences (`ceos-agents:`)
In which files and on which lines does `ceos-agents:` appear as a skill prefix in Task dispatch calls (e.g., `subagent_type='ceos-agents:analyst'`, `/ceos-agents:fix-bugs`)? This is the `subagent_type` value passed to the Task tool at runtime — unrenamed prefixes mean the plugin cannot be invoked under the new name.

### R-3: `.ceos-agents/` runtime state directory path references
How many agent definition files and skill step files contain filesystem path references to `.ceos-agents/{ISSUE_ID}/state.json`, `.ceos-agents/pipeline.log`, `.ceos-agents/autopilot.log`, `.ceos-agents/pipeline-history.md`? What is the rename decision: rename to `.agent-flow/` immediately (breaking in-flight consumer state) or preserve as an alias for one transitional version?

### R-4: Install command strings across docs and README
Which files contain the install command `claude plugin install ceos-agents@ceos-agents` or the path `marketplaces/ceos-agents`? What is the exact new command string: `claude plugin install agent-flow@agent-flow`? Also covers README line 53 which contains an internal Windows path `C:/gitea_ceos-agents` as an install example.

### R-5: Case variants of "ceos-agents" (CEOS-AGENTS, Ceos-Agents)
Do any files contain uppercase `CEOS-AGENTS`, title-case `Ceos-Agents`, or other case variants that a case-sensitive bulk `sed` replace would miss? Confirmed occurrences exist in docs/plans/ internal notes; need to determine whether to rename or delete these files entirely.

### R-6: "ceos-agents" in tests/mock-project/CLAUDE.md and test scenario shell scripts
What text in `tests/mock-project/CLAUDE.md` and the 160+ test scenario `.sh` files directly references "ceos-agents" as a plugin name, skill prefix, or block comment marker? These must be updated for test scenarios to pass after rename.

### R-7: "ceos-agents" in GitHub/Gitea workflow YAML files
Does `.gitea/workflows/test.yaml` or any `.github/` file reference "ceos-agents" in install steps or badge URLs? CI workflows with old plugin names will fail post-rename.

### R-8: "ceos-agents" in issue/PR templates and byte-parity invariant
Do `.gitea/issue_template/bug_report.md`, `.gitea/pull_request_template.md`, `.github/ISSUE_TEMPLATE/bug_report.md`, `.github/PULL_REQUEST_TEMPLATE.md` contain "ceos-agents" as a label, prefix, or description string? After rename, both `.gitea/` and `.github/` template pairs must be updated identically to preserve the byte-parity cross-file invariant (CLAUDE.md §Cross-File Invariants #3). Confirmed changes needed: `about: Report a bug in agent-flow` (line 3) and `- agent-flow version:` (line 21) in both bug report templates.

### R-9: "ceos-agents" in example configs (examples/configs/) and custom-agent examples
In the 8+ example CLAUDE.md config files under `examples/configs/` and custom-agent examples under `examples/custom-agents/`, where does "ceos-agents" appear as a skill prefix in example `## Automation Config` sections? Example configs are copy-pasted by new users — unrenamed prefixes lead users to invoke a non-existent skill namespace.

### R-10: Binary files containing embedded "ceos-agents" text
Are there PNG, PDF, or PPTX files (e.g., `docs/plans/readmine-project/ACT-A-1_obrazek.png`) containing embedded "ceos-agents" text that cannot be replaced with text tools? These would require regeneration or removal before public release.

### R-11: `.vs/` Visual Studio solution file and .gitignore coverage
Does `.vs/gitea_ceos-agents.slnx/v18/DocumentLayout.json` contain "ceos-agents" as part of the solution name? Should the `.vs/` directory be in `.gitignore`? (Currently `.gitignore` has only 4 entries: `.vs/`, `nul`, `.claude/settings.local.json`, `.env`.)

---

## Category 2: Version References & Deletions

### V-1: v6.x version references in shipped content (agents/, skills/, core/, docs/reference/, checklists/)
Which files in agents/, skills/, core/, docs/reference/, docs/guides/, and checklists/ contain `v6.x.x` version strings (e.g., v6.8.0, v6.9.0, v6.9.1, v6.10.0)? Are these structural/contractual (test scenario names — keep) or incidental prose references (safe to remove)?

### V-2: v7.x–v8.x version references in shipped content
Which non-plan, non-superpowers files contain `v7.x.x` or `v8.x.x` version strings? The `migration-v7-to-v8.md` and `migration-v8-to-v9.md` guides need a deletion vs. retention decision — these are irrelevant to v1.0.0 users and contain internal development context.

### V-3: "v9.0.0+" and "v10.0.0+" in agent section headers
Which agent files contain "v9.0.0+" or "v10.0.0+" as inline labels in section headings (e.g., `## Output Contract (v9.0.0+, mandatory)` or `## Step Completion Invariants (v10.0.0+, mandatory)`)? The task calls for stripping version qualifiers to just "mandatory". Confirm exact form in each of the 17 agent files before bulk substitution.

### V-4: "v10.0.0 3-layer defense" prose in fixer.md, reviewer.md, publisher.md
Three agent files contain "v10.0.0 3-layer defense" in their Step Completion Invariants prose body (not section headers). Should this phrase be removed, changed to "3-layer defense", or left as a technical reference? The migration spec is silent on prose-level v10 references beyond section headers.

### V-5: Version-prefixed test scenario filenames (keep vs. rename vs. delete)
The tests/scenarios/ directory contains ~160 scenario files with version-stamped names (e.g., `v6.9.0-cross-file-invariants.sh`, `v9.3.0-metrics-html-escape.sh`). Decision needed: rename to remove version prefixes, or treat tests/ as a deleted artifact entirely along with docs/plans/?

### V-6: Version references in CLAUDE.md — contractual vs. incidental
CLAUDE.md contains ~19 version references (v6.8.0, v6.9.0, v6.9.1, v9.0.0+, v10.0.0+, v10.2.0). Which are forward-facing behavioral specs (keep) vs. historical change notes (remove/reframe as "since initial release")? This includes the versioning policy table's concrete examples (`## Output Contract (v9.0.0)`, `v8.0.0 agents`) and the webhook backward-compat notes (`v6.8.0`, `v6.9.0`).

### V-7: Version references in core/ contracts
14 files in core/ contain version references (v6–v10 found in initial scan). What are the specific version strings, and are they cross-references ("see v9.0.0 change") or structural labels? Core files define runtime behavior contracts — version-stamped cross-references are meaningless to external users.

### V-8: CHANGELOG.md strategy — clean v1.0.0 start vs. curated summary
CHANGELOG.md (199KB, v4.1.0 through v10.2.0) contains: BIFITO tracker IDs, Czech-language release notes, internal hostnames (gitea.internal.ceosdata.com), drmax project references, forge pipeline run IDs, and repeated author lines. Decision: replace with a single clean v1.0.0 entry? Or include a sanitized capability-evolution summary? The first 10 lines also contain a Czech-language note and a "Repo split note" explaining the ceos-agents-web extraction — both are irrelevant to OSS users.

### V-9: Deletion inventory — .forge.bak-*/ directories
How many `.forge.bak-*/` directories exist at the repo root (currently ~64 per observation)? Are any committed to git history (all observed as `??` untracked in git status)? Does the `.gitignore` glob `.forge.bak-*/` capture all naming variants including special-suffix variants? If any are tracked in git history, deletion alone is insufficient.

### V-10: Deletion inventory — .forge.v*/ directories
A directory named `.forge.v8.0.0` exists at root. Are there others (`.forge.v9.0.0`, `.forge.v10.0.0`)? The proposed `.gitignore` entry `.forge.v*/` must correctly match all instances. Confirm full set with `ls -d .forge.*`.

### V-11: Current .gitignore gaps and retroactive coverage
The current `.gitignore` has only 4 entries. Which proposed new entries (`.forge/`, `.forge.bak-*/`, `.forge.v*/`, `.agent-flow/` or `.ceos-agents/`, `*.stackdump`, `REVIEW-REPORT-*.md`, `docs/plans/`) are NOT currently ignored? If any of the to-be-deleted directories are already tracked in git, `git rm -r --cached` is required in addition to .gitignore updates.

### V-12: `skills/version-check/SKILL.md` deletion — dangling reference check
`skills/version-check/SKILL.md` is scheduled for deletion. Which other files reference `/ceos-agents:version-check` or `skills/version-check/` by path or name? Dangling references in docs or other skills would produce broken links in the public release after deletion.

### V-13: `nul` file and other Windows device artifact files
Does a file named `nul` actually exist at the repo root? Are there other Windows device artifacts (`con`, `prn`, `aux`)? Beyond `grep.exe.stackdump`, are there other `*.stackdump` files in the repository?

### V-14: docs/reference/ internal version annotations
Which specific docs/reference/ files (automation-config.md, agents.md, skills.md, pipeline.md, config.md) contain "added in v6.x" annotations or version-specific behavior descriptions? These are the primary user-facing documentation and will be read by public GitHub users first.

---

## Category 3: Documentation Rewrites

### D-1: README.md brand replacement scope
README.md contains ~20 "ceos-agents" occurrences (title, mermaid subgraph labels, install command `ceos-agents@ceos-agents`, skill namespace `/ceos-agents:*`, warning table). Which sections require mechanical brand replacement vs. full content rewrite? What OSS-grade content is entirely missing: a compelling one-paragraph hook, target audience statement, comparison with Copilot Workspace/Aider, contributor section?

### D-2: Dead links in README.md from guide deletions
README.md line 72 contains a link to `docs/guides/migration-v7-to-v8.md`. Is this file in scope for deletion? For a fresh v1.0.0 OSS release, the entire "Migrating from v7?" callout block should be removed. What other README links point to files in `docs/plans/` or `docs/guides/` that will be deleted?

### D-3: SECURITY.md additions for OSS readiness
SECURITY.md (16 lines) has the correct primary contact `filip.sabacky@ceosdata.com` but is missing: (1) GitHub Security Advisories as secondary contact, (2) an explicit "Supported versions: v1.0.0+" section. These two additions are required per the v1.0.0 spec. The file also contains one "ceos-agents" occurrence in the opening sentence.

### D-4: CONTRIBUTING.md rename and structure review
CONTRIBUTING.md (124 lines) is structurally OSS-ready. It has "ceos-agents" in the title (line 1) and opening line (line 3). The "Functional test scenarios — security expectations" section is excellent technical content — should it stay in the main file or move to `docs/guides/contributing-tests.md` for approachability?

### D-5: CLAUDE.md — `feedback_doc_completeness.md` reference removal
CLAUDE.md line 319 references `feedback_doc_completeness.md` as an internal discipline document. Does this file exist in the repo? If it does not exist, CLAUDE.md line 319 is a broken reference that must be removed. If it exists, it must be assessed as a public or internal-only artifact.

### D-6: CLAUDE.md — Automation Config section path defaults and block comment prefix
CLAUDE.md §Automation Config has three types of "ceos-agents" references that affect the plugin's consumer contract: (a) `.ceos-agents/autopilot.log` as the default `Log file` path in the Autopilot section (line 246), (b) `[ceos-agents]` block comment and triage checkpoint prefixes in §Block Comment Template (lines 283, 294, 297), (c) `ceos-agents-block` webhook field in §Webhook Payloads (line 264). All three must become `agent-flow` variants. The block comment template change is the most impactful as it affects runtime behavior and test scenarios.

### D-7: CLAUDE.md — §Plugin Composability namespace update
CLAUDE.md §Plugin Composability (line 167) explicitly states: "All skills are invoked as `/ceos-agents:<skill>`". This entire section must be updated to use `agent-flow:` namespace, including the check-setup example `/ceos-agents:check-setup`.

### D-8: CLAUDE.md — version-anchored descriptions (v6.8.0, v6.9.0, v9.0.0+, v10.0.0+)
19 version references exist in CLAUDE.md. References in the §Webhook Payloads section ("added in v6.8.0", "v6.9.0 circuit-breaker") should be reframed as present-tense behavioral specs or removed. The §Versioning Policy table uses `v8.0.0` and `v9.0.0` as concrete historical examples — these could be rewritten with abstract descriptions.

### D-9: docs/plans/roadmap.md — extractable content for docs/roadmap.md
The internal `docs/plans/roadmap.md` (2193 lines) contains mixed content. The VISION table (lines 2143–2159) and NOT PLANNED table (lines 2162–2183) are English-only and product-direction focused — clear candidates for the new public `docs/roadmap.md`. The BACKLOG section (lines 961–1922) and EXPLORING section (lines 1923–1989) contain substantial Czech text and BIFITO/drmax internal references — require sanitization or exclusion. The PLANNED release items (v10.3.0–v10.5.0) are in mixed Czech/English and require English-only rewrites. What is the minimum viable English-only, internal-reference-free content for a community-facing roadmap?

### D-10: docs/superpowers/specs/ content preservation decision
The `docs/superpowers/specs/` directory (9 files) contains brainstorm documents for companion projects (showcase web, dashboard, agent I/O contracts), a CEO presentation, and v8.0.0/v9.0.0 implementation design. The cleanup plan deletes this entire directory. Is there any content worth extracting to `docs/roadmap.md` or `docs/architecture.md` before deletion? Specifically: the public-release-readiness and agent-shape-design docs may contain architectural decisions relevant to OSS community documentation.

### D-11: Agent frontmatter description fields — version stamps in picker UI
Do any of the 17 agent files have version strings in their YAML frontmatter `description` fields (e.g., `description: "v10.0.0 analyst agent"`)? Frontmatter description fields appear in Claude Code's agent picker UI — version stamps there are visible to all public users.

### D-12: Confirmed target GitHub URL and namespace
The confirmed rename target is `agent-flow`. The target GitHub URL is assumed to be `https://github.com/fsabacky/agent-flow`. This must be verified/confirmed. The new skill invocation namespace is `/agent-flow:<skill>`. All 18 skill frontmatter descriptions, CLAUDE.md namespace references, README skill tables, and all issue/PR templates must use this namespace consistently.

---

## Category 4: Edge Cases & Cross-File Invariants

### E-1: Cross-file invariant 1 — License SPDX consistency post-rename
After the rename, `plugin.json:license`, `marketplace.json:plugins[0].license`, and the `LICENSE` first heading must all reference exactly `"MIT"`. The rename touches both JSON files; confirm the license field is not accidentally modified during the rename pass.

### E-2: Cross-file invariant 2 — Maintainer email consistency
`SECURITY.md`, `CODE_OF_CONDUCT.md`, and `CONTRIBUTING.md` must all reference `filip.sabacky@ceosdata.com` as the maintainer contact. Currently satisfied. The rename does not affect these files' email fields, but the CONTRIBUTING.md and CODE_OF_CONDUCT.md each contain "ceos-agents" in their text — confirm that updating the plugin name reference in those files does not accidentally alter the email field.

### E-3: Cross-file invariant 3 — .gitea/.github template byte-parity
After rename, both `.gitea/issue_template/bug_report.md` and `.github/ISSUE_TEMPLATE/bug_report.md` must be updated identically (and remain byte-identical). Same for feature_request.md and pull_request templates. Any divergence breaks the Phase 8 harness invariant check. Changes needed: `about: Report a bug in agent-flow` and `- agent-flow version:` in bug report templates.

### E-4: doc-count drift audit discipline — feedback_doc_completeness.md
CLAUDE.md line 319 references an internal discipline: "CLAUDE.md, README.md, docs/reference/automation-config.md, docs/reference/skills.md, docs/architecture.md count fields must be kept in sync." After deletions and renames, field counts across these five documents will change. Phase 2 must determine whether the `feedback_doc_completeness.md` file exists and whether the count-sync discipline needs to be documented publicly or removed from CLAUDE.md.

### E-5: Tests fixture files — v10-witness/state-a.json, state-b.json, state-c.json
The JSON fixture files in `tests/fixtures/v10-witness/` have `agent_name` fields containing `ceos-agents:` prefixes. If test scenarios do exact string comparison on these fixtures, they will fail post-rename unless updated atomically with the agent namespace change.

### E-6: docs/plans/ directory — internal URL leakage risk
`docs/plans/` (~90+ files) is slated for deletion. The directory contains confirmed references to internal infrastructure: `ceosdata.com` hostnames, Redmine/YouTrack project names, BIFITO tracker IDs. Before deletion, confirm no docs/plans/ content is cross-referenced from kept files (docs/reference/, docs/guides/) in a way that would leave broken links.

### E-7: CHANGELOG.md `ceos-agents-block` backward-compat documentation
The CHANGELOG contains the entry documenting "`ceos-agents-block` is never renamed or removed" as a contractual statement. With the decision to rename it to `agent-flow-block` at v1.0.0, this CHANGELOG entry either disappears (clean-start strategy) or must be explicitly superseded by a migration note. Phase 2 must assess how to handle this in the chosen CHANGELOG strategy.

### E-8: docs/reference/ version annotation strategy
docs/reference/ files are the primary user-facing documentation for the OSS plugin. Version-history annotations like "added in v6.8.0" or "changed in v9.0.0" are meaningless to users who start at v1.0.0. Phase 2 must determine whether these annotations are stripped entirely, rewritten as present-tense facts, or replaced with a single "since v1.0.0" annotation.

---

## Research Execution Plan

Phase 2 should execute the following investigations in this priority order:

1. **[BLOCKING] Confirm webhook rename scope** — `grep -rn "ceos-agents-block"` across all source files to identify every file that must be updated when `ceos-agents-block` → `agent-flow-block` (CRITICAL-1). Confirm no test scenario asserts backward-compat for the old name in a way that conflicts with the v1.0.0 clean slate.

2. **[BLOCKING] Confirm target GitHub URL** — Verify the exact public GitHub URL (`github.com/fsabacky/agent-flow`) and confirm it is already created/reserved, before updating any `repository` field references (CRITICAL-3, D-12).

3. **[HIGH] Full occurrence map** — Run the complete "ceos-agents" occurrence inventory (R-1) categorized by semantic type. This is the foundation for all subsequent rename work and must be produced as a structured artifact (file → line → category).

4. **[HIGH] dispatch_witness seed format audit** — Confirm all `EXPECTED_AGENT_NAME` and sha256 seed occurrences in skills/ and core/ (CRITICAL-2). These are the highest technical risk — a missed occurrence causes silent hash mismatches in production.

5. **[HIGH] plugin.json / marketplace.json exact content** — Read both files completely to capture all fields that need updating: name, version, repository, description, namespace (R-2 partially, CRITICAL-3, CRITICAL-5).

6. **[HIGH] .gitignore gap analysis** — Determine which to-be-deleted directories are tracked in git vs. untracked (V-9, V-10, V-11). If any are tracked, git rm --cached is required and must be in the execution plan.

7. **[MEDIUM] CHANGELOG.md strategy decision** — Read first 50 lines and last 100 lines; grep for BIFITO, ceosdata.com, Czech words. Confirm clean-start vs. summary approach (V-8, D-Q3 from Agent-3). This decision determines how much CHANGELOG rewrite work is needed.

8. **[MEDIUM] Version reference audit in agents/ and core/** — Enumerate all v9.0.0+ / v10.0.0+ section header occurrences (V-3), v10.0.0 prose in fixer/reviewer/publisher (V-4), and version refs in core/ contracts (V-7).

9. **[MEDIUM] CLAUDE.md internal reference audit** — Confirm existence of `feedback_doc_completeness.md` (D-5), map all 13+ "ceos-agents" occurrences to replacement type (D-6, D-7, D-8), and assess which v6-v10 version references are forward-facing vs. historical (D-8, V-6).

10. **[MEDIUM] docs/plans/roadmap.md extractable content** — Read lines 2143–2193 (VISION + NOT PLANNED) and spot-check lines 961–1060 (BACKLOG start) and 1923–1989 (EXPLORING with Czech text) to scope the public docs/roadmap.md content (D-9).

11. **[LOW] Cross-file invariants current state verification** — Re-verify all three invariants post-audit to confirm they are satisfied before any changes begin (E-1, E-2, E-3).

12. **[LOW] Binary file check** — Locate PNG/PDF/PPTX files and assess whether any contain embedded "ceos-agents" branding (R-10).

13. **[LOW] docs/superpowers/specs/ content review** — Quick read of public-release-readiness and agent-shape-design docs to determine if any content should be extracted to docs/roadmap.md or docs/architecture.md before deleting the directory (D-10).
