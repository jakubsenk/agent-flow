# Phase 1 Research Questions — Agent 1 (Rename Inventory Focus)

## Focus Area
Rename inventory and occurrence mapping

## Research Questions

### Q1: How many source files (excluding .forge/ artifacts and .forge.bak-*/) contain the string "ceos-agents"?
**Question:** What is the exact count and complete list of source files — agents/, skills/, core/, docs/, examples/, checklists/, tests/, root .md/.json/.sh — that contain "ceos-agents", broken down by directory and file type?
**Why it matters:** Sets the scope of the rename task and prevents missing any occurrence that would leave a broken reference or wrong branding in the published OSS release.
**Search method:** `grep -rl "ceos-agents" . --include="*.md" --include="*.json" --include="*.sh" --include="*.yaml" | grep -v '\.forge' | grep -v '\.forge\.bak'`

---

### Q2: What is the exact current content of .claude-plugin/plugin.json and .claude-plugin/marketplace.json?
**Question:** What are the exact values of `name`, `description`, `version`, `repository`, `license`, `author`, and all `plugins[]` fields in both JSON metadata files?
**Why it matters:** These two files define the plugin identity visible in the Claude Code marketplace — both `name` fields must change from `"ceos-agents"` to `"agent-flow"` and the `repository` URL must be updated to the new GitHub URL; mismatches break install resolution.
**Search method:** `cat .claude-plugin/plugin.json` and `cat .claude-plugin/marketplace.json`

---

### Q3: Where does the skill namespace prefix "ceos-agents:" appear in skill invocation strings?
**Question:** In which files and on which lines does the string `ceos-agents:` appear as a skill prefix (e.g., `/ceos-agents:fix-bugs`, `Task(subagent_type='ceos-agents:analyst'`, `Run /ceos-agents:`)?
**Why it matters:** The skill namespace prefix is user-facing (appears in Tab completion, docs, and error messages) and is also the `subagent_type` value passed to the Task tool at runtime — an unrenamed prefix means the plugin cannot be invoked under the new name.
**Search method:** `grep -rn "ceos-agents:" . --include="*.md" --include="*.sh" --include="*.json" | grep -v '\.forge' | grep -v '\.forge\.bak'`

---

### Q4: Where does the "[ceos-agents]" block comment marker appear, and is it a runtime-parsed string?
**Question:** In how many agents and skill step files does the literal string `[ceos-agents]` appear as the prefix for triage checkpoint comments, pipeline block comments, and spec-analysis comments — and are any test scenarios asserting this exact string?
**Why it matters:** The CLAUDE.md contract states both the block comment format (`[ceos-agents] 🔴 Pipeline Block`) and triage format (`[ceos-agents] Triage completed.`) are machine-parsed by entry-point skills (`/fix-bugs`, `/implement-feature`, `/scaffold`) for auto-resume; renaming it is a breaking change unless tests and agents are updated atomically.
**Search method:** `grep -rn "\[ceos-agents\]" . --include="*.md" --include="*.sh" | grep -v '\.forge' | grep -v '\.forge\.bak'`

---

### Q5: Where does the webhook payload event name "ceos-agents-block" appear, and which test scenarios guard it as a backward-compat contract?
**Question:** Which files reference `ceos-agents-block` as a webhook event name, and specifically which test scenarios (`regression-existing-events-preserved.sh`, `v6.9.0-bc-no-removed-webhook-event.sh`) assert that this exact string must be present — making it a versioning constraint?
**Why it matters:** CLAUDE.md §Webhook Payloads explicitly states "`pr-created` and `ceos-agents-block` are never renamed or removed"; renaming the plugin without updating or retiring these guards will cause test failures, and renaming the event itself is a MAJOR breaking change requiring a v11.0.0 bump or a documented migration.
**Search method:** `grep -rn "ceos-agents-block" . --include="*.md" --include="*.sh" --include="*.json" | grep -v '\.forge' | grep -v '\.forge\.bak'`

---

### Q6: Where does the ".ceos-agents/" state directory path appear in agents and skills?
**Question:** How many agent definition files and skill step files contain filesystem path references to `.ceos-agents/{ISSUE_ID}/state.json`, `.ceos-agents/pipeline.log`, `.ceos-agents/autopilot.log`, or `.ceos-agents/pipeline-history.md`?
**Why it matters:** This directory is created at runtime in the consuming project's working directory — if renamed to `.agent-flow/`, every existing consumer project with in-progress state files will lose resume capability; if kept as-is, the directory name contradicts the plugin's new identity.
**Search method:** `grep -rn "\.ceos-agents/" . --include="*.md" --include="*.sh" --include="*.json" | grep -v '\.forge' | grep -v '\.forge\.bak'`

---

### Q7: Where does "ceos-agents" appear in the EXPECTED_AGENT_NAME and dispatch_witness sha256 seed strings in skill step files?
**Question:** In each of the `skills/fix-bugs/steps/`, `skills/implement-feature/steps/`, `skills/scaffold/steps/`, and `skills/create-backlog/SKILL.md` files, where is `EXPECTED_AGENT_NAME = "ceos-agents:<agent>"` set and where is `sha256("ceos-agents:<agent>|...")` used as the dispatch witness seed?
**Why it matters:** The dispatch witness is a cryptographic integrity check computed from the agent name — if the plugin is renamed but the EXPECTED_AGENT_NAME strings are not updated, the `check_dispatch_witness` function in `core/lib/stage-invariant.sh` will produce hash mismatches and block every pipeline step.
**Search method:** `grep -rn "EXPECTED_AGENT_NAME\|dispatch_witness.*ceos" skills/ --include="*.md" --include="*.sh"`

---

### Q8: Are there case variants of "ceos-agents" (CEOS-AGENTS, Ceos-Agents) in any source files?
**Question:** Do any files in agents/, skills/, core/, docs/, or root contain uppercase `CEOS-AGENTS`, title-case `Ceos-Agents`, or any other case variation that would be missed by a case-sensitive `sed` replace?
**Why it matters:** A case-sensitive bulk rename would leave residual references if mixed-case forms exist; confirmed occurrences are in docs/plans/ internal notes (e.g., `CEOS-AGENTS vs ACT IDENTITA`, `Ceos-agents is for...`) — these need a decision whether to rename or delete.
**Search method:** `grep -rni "CEOS-AGENTS" . --include="*.md" --include="*.json" | grep -v '\.forge' | grep -v '\.forge\.bak' | grep -iv "ceos-agents"` (find non-lowercase variants)

---

### Q9: Where does "ceos-agents" appear in the install command strings in docs and README?
**Question:** Which files contain the install command `claude plugin install ceos-agents@ceos-agents` or the marketplace add command path `marketplaces/ceos-agents`, and what is the exact new command string that should replace it?
**Why it matters:** The install command is the first thing a new user runs — it must reference the new plugin name; the `@ceos-agents` part is the marketplace registration key that Claude Code uses to look up the plugin, so both the marketplace name and the plugin name part must match the new identity.
**Search method:** `grep -rn "plugin install ceos-agents\|marketplaces/ceos-agents\|plugin marketplace add" . --include="*.md" | grep -v '\.forge' | grep -v '\.forge\.bak'`

---

### Q10: Where does "ceos-agents" appear in the repository URL field and what is the target GitHub URL?
**Question:** What is the current `repository` field value in `plugin.json` (`https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git`) and what occurrences of the internal Gitea URL or the `gitea.internal.ceosdata.com` hostname exist in any user-facing file?
**Why it matters:** The internal Gitea URL is a private hostname that must not appear in any file published to GitHub; `v6.9.0-installation-md-no-internal-host.sh` test asserts this negative condition, so failing to replace it will cause a test failure post-rename.
**Search method:** `grep -rn "gitea.internal.ceosdata.com\|ceosdata.com/fsabacky" . --include="*.md" --include="*.json" --include="*.sh" | grep -v '\.forge' | grep -v '\.forge\.bak'`

---

### Q11: Where does "ceos-agents" appear in test fixture JSON files (state-a.json, state-b.json, state-c.json)?
**Question:** In `tests/fixtures/v10-witness/state-a.json`, `state-b.json`, and `state-c.json`, how many `agent_name` field values contain the `ceos-agents:` prefix, and do any test scenarios assert these fixture values by exact string match?
**Why it matters:** These JSON fixtures are consumed by `core/lib/stage-invariant.sh` self-test and scenario harness — if the `agent_name` values are not updated in sync with the agent namespace rename, the v10 witness verification tests will fail on exact hash comparison.
**Search method:** `grep -rn "agent_name.*ceos-agents" tests/fixtures/ --include="*.json"`

---

### Q12: Where does "ceos-agents" appear in the tests/mock-project/CLAUDE.md and test scenario shell scripts?
**Question:** What specific text in `tests/mock-project/CLAUDE.md` and the 157+ lines of test scenario `.sh` files directly reference "ceos-agents" as a plugin name, skill prefix, or block comment marker that must be updated for test scenarios to pass after rename?
**Why it matters:** The test harness validates the renamed plugin — if `tests/mock-project/CLAUDE.md` still refers to the old plugin name in its `## Automation Config`, test scenarios that read config will fail; similarly, test scenarios that grep for `ceos-agents:` skill invocations must be updated.
**Search method:** `grep -rn "ceos-agents" tests/ --include="*.sh" --include="*.md" --include="*.json" | grep -v '\.forge'`

---

### Q13: Does "ceos-agents" appear in any GitHub/Gitea workflow YAML files or CI configuration?
**Question:** Does `.gitea/workflows/test.yaml` or any `.github/` directory file reference the "ceos-agents" string, plugin name, or install command in a way that would break CI after rename?
**Why it matters:** CI workflows that reference the old plugin name in install steps or badge URLs will fail or produce incorrect results after the rename — these need updating before or simultaneously with the rename.
**Search method:** `grep -rn "ceos-agents" .gitea/ .github/ --include="*.yaml" --include="*.yml" --include="*.md" --include="*.json"`

---

### Q14: Does "ceos-agents" appear in the .gitea or .github issue/PR templates as machine-parseable markers?
**Question:** Do `/.gitea/issue_template/bug_report.md`, `/.gitea/pull_request_template.md`, `/.github/ISSUE_TEMPLATE/bug_report.md`, and `/.github/PULL_REQUEST_TEMPLATE.md` contain "ceos-agents" as a label, prefix, or instruction string — and are the pairs byte-identical as required by the cross-file invariant?
**Why it matters:** The CLAUDE.md cross-file invariant 3 requires `.gitea/` and `.github/` template pairs to be byte-identical; if one template is updated and the other is not, the invariant test will fail; additionally, issue templates mentioning the plugin name by the old name affect contributor UX.
**Search method:** `grep -rn "ceos-agents" .gitea/ .github/ --include="*.md"` then `diff -q .gitea/issue_template/bug_report.md .github/ISSUE_TEMPLATE/bug_report.md`

---

### Q15: Where does "ceos-agents" appear in the CHANGELOG.md — specifically in entries that reference backward-compat contracts that must be preserved?
**Question:** Within `CHANGELOG.md`, which entries contain references to "ceos-agents" as part of a user-facing contract statement (e.g., webhook event names, install commands, state path defaults) that must either be preserved verbatim, updated with a migration note, or superseded by a new entry at rename time?
**Why it matters:** CHANGELOG entries that document contracted behavior (e.g., "`pr-created` and `ceos-agents-block` are never renamed or removed") become historical record; the rename changelog entry must address what changes and what is preserved to avoid consumer confusion.
**Search method:** `grep -n "ceos-agents" CHANGELOG.md | grep -i "never\|contract\|backward\|preserved\|removed\|unchanged"`

---

### Q16: Where does "ceos-agents" appear in the docs/guides/ and docs/reference/ user-facing documentation files?
**Question:** Which specific files in `docs/guides/` (e.g., `installation.md`, `autopilot.md`, `troubleshooting.md`, `migration-v7-to-v8.md`, `migration-v8-to-v9.md`) and `docs/reference/` (e.g., `skills.md`, `agents.md`, `automation-config.md`, `pipeline.md`) contain "ceos-agents" as a user-facing plugin name, command prefix, or example string?
**Why it matters:** User-facing documentation is what OSS users read first — any occurrence of "ceos-agents" in these files produces confusion about the plugin name and breaks copy-paste command examples; these files have the highest UX impact.
**Search method:** `grep -rn "ceos-agents" docs/guides/ docs/reference/ --include="*.md"`

---

### Q17: Where does "ceos-agents" appear in example configs (examples/configs/) and custom-agent examples?
**Question:** In the 8+ example CLAUDE.md config files under `examples/configs/` and the custom-agent examples under `examples/custom-agents/`, where does "ceos-agents" appear as a skill prefix in example `## Automation Config` sections or in skill invocation examples?
**Why it matters:** Example configs are copy-pasted by new users to bootstrap their own projects — unrenamed "ceos-agents:" prefixes in examples will lead users to invoke the wrong (non-existent) skill namespace.
**Search method:** `grep -rn "ceos-agents" examples/ --include="*.md"`

---

### Q18: Does "ceos-agents" appear in any binary or non-text file (PNG, PDF, PPTX) that cannot be updated with text tools?
**Question:** Are there any binary files in the repository (e.g., `.png` files like `ACT-A-1_obrazek.png` in `docs/plans/readmine-project/`, or any PDF/PPTX presentation files) that contain embedded "ceos-agents" text that cannot be replaced with `sed` or a text editor?
**Why it matters:** Binary files with embedded old names are invisible to grep but visible to users who open them; if such files exist and are committed, the OSS release will contain inconsistent branding; they may need to be regenerated or removed.
**Search method:** `find . -name "*.png" -o -name "*.pdf" -o -name "*.pptx" | grep -v '\.forge'` then assess whether each can be renamed; `strings <file> | grep -i ceos` for text extraction from binaries.

---

### Q19: Does "ceos-agents" appear in the .vs/ Visual Studio solution file, and should it be in the published repository?
**Question:** Does `.vs/gitea_ceos-agents.slnx/v18/DocumentLayout.json` contain "ceos-agents" as part of the solution name or file references — and should the `.vs/` directory be included in `.gitignore` to prevent IDE artifacts from reaching the public GitHub repository?
**Why it matters:** The `.vs/` directory is a Visual Studio IDE artifact containing the developer's workspace layout — it should not be in a published OSS repository; its presence also contains the old name in the solution filename `gitea_ceos-agents.slnx` which would be misleading to GitHub contributors.
**Search method:** `cat ".vs/gitea_ceos-agents.slnx/v18/DocumentLayout.json"` and `cat .gitignore` to check if `.vs/` is excluded.

---

### Q20: What is the total occurrence count of "ceos-agents" broken down by context type (skill prefix vs. block marker vs. state path vs. plugin name vs. install command) to size the rename effort?
**Question:** Across all source files (excluding .forge/ and .forge.bak-*/), how many occurrences of "ceos-agents" fall into each category: (a) `ceos-agents:` skill prefix in skill invocations and Task calls, (b) `[ceos-agents]` block/triage comment markers, (c) `.ceos-agents/` filesystem paths, (d) `"name": "ceos-agents"` JSON plugin identity fields, (e) install command strings, (f) repository URLs, (g) human-readable prose?
**Why it matters:** Categorizing occurrences by type enables parallel work streams and risk assessment — category (c) `.ceos-agents/` paths carry migration risk (in-flight state), category (e) `ceos-agents-block` webhook event carries backward-compat risk (MAJOR bump decision), while categories (a), (d), (e), (f) are straightforward mechanical renames.
**Search method:** `grep -rc "ceos-agents:" . --include="*.md" --include="*.sh" | grep -v '\.forge'` and similar per-pattern counts across the five distinct pattern classes.

---

## Summary

The rename from "ceos-agents" to "agent-flow" affects approximately 160+ source files across all major repository directories. The occurrence inventory spans at least seven distinct semantic categories: (1) the `ceos-agents:` skill namespace prefix used in ~90 Task dispatch calls across 30+ skill step files and core contracts; (2) the `[ceos-agents]` block comment marker embedded in all 17 agent definition files and parsed at runtime for pipeline auto-resume; (3) the `.ceos-agents/` runtime state directory path referenced by all 17 agents and multiple core contracts; (4) the `"name": "ceos-agents"` JSON identity in plugin.json and marketplace.json; (5) the `ceos-agents-block` webhook event name that is explicitly contracted as "never renamed or removed" in CLAUDE.md and guarded by two regression test scenarios; (6) install command strings in docs and README; and (7) the internal `gitea.internal.ceosdata.com` repository URL which a test scenario already asserts must not appear in user-facing files. The research phase must produce a complete per-file occurrence map, a decision on whether `ceos-agents-block` webhook event requires a MAJOR version bump, and clarity on whether the `.ceos-agents/` state directory is renamed (breaking in-flight consumer state) or preserved under an alias for one transitional version.
