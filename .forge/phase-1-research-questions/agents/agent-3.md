# Phase 1 Research Questions — Agent 3 (Doc Rewrites & Community Readiness)

## Focus Area
Documentation rewrites, content preservation, community readiness

## Research Questions

### Q1: What is the scope of the README.md rewrite needed for OSS?
**Question:** The current README.md is structurally solid (Mermaid diagrams, skills table, agents table, pipeline flowcharts) but contains "ceos-agents" branding throughout (title, mermaid subgraph labels, skill namespace examples, install commands, Quick Start). What specific sections require brand replacement vs. full content rewrite, and what marketing-grade content is missing entirely (e.g., a compelling one-paragraph hook, target audience statement, comparison with Copilot Workspace/Aider, contributor section)?
**Why it matters:** The README is the first impression for OSS users on GitHub; it must be renamed, de-branded from "ceos-agents", and upgraded to marketing-grade without losing technical accuracy.
**Search method:** `Read C:/gitea_agent-flow/README.md` (already done); count occurrences of "ceos-agents" string (83 found in CHANGELOG; ~20 in README based on grep).

---

### Q2: Does the README reference docs/guides/migration-v7-to-v8.md which will be deleted?
**Question:** Line 72 of README.md reads: `> **Migrating from v7?** See [migration guide](docs/guides/migration-v7-to-v8.md)...`. The v10.3.0 cleanup plan deletes `docs/plans/` but what about `docs/guides/`? Is `docs/guides/migration-v7-to-v8.md` in scope for deletion? For a fresh v1.0.0 OSS release, is a migration guide from v7 meaningful to new users?
**Why it matters:** Dead links in README would immediately undermine credibility for new OSS users; migration history from private development is irrelevant to v1.0.0 users.
**Search method:** `ls C:/gitea_agent-flow/docs/guides/` to check if migration-v7-to-v8.md exists; assess whether the entire "Migrating from v7?" callout should be deleted.

---

### Q3: What is the current CHANGELOG.md history depth and what must NOT carry over?
**Question:** The current CHANGELOG.md documents history from v4.1.0 through v10.2.0, contains references to internal tracker IDs (BIFITO-4293), internal Czech-language release notes, internal hostnames (gitea.internal.ceosdata.com), drmax project references, forge pipeline run IDs, and per-author commit-level entries (`Filip Sabacky <filip.sabacky@ceosdata.com>` repeated ~20+ times as per-version author lines). For the v1.0.0 public launch, should the CHANGELOG be a clean start (only v1.0.0 entry) or should it carry some summary of prior capability evolution?
**Why it matters:** A CHANGELOG with BIFITO tracker IDs, Czech text, and internal hostnames would immediately signal private/internal origins to OSS evaluators; a clean v1.0.0 start is the standard practice for forked or renamed OSS projects.
**Search method:** `Read C:/gitea_agent-flow/CHANGELOG.md` — full file needed to assess total contamination; internal refs confirmed by grep (BIFITO, drmax, ceosdata.com, gitea.internal).

---

### Q4: Does SECURITY.md currently satisfy the v1.0.0 requirements?
**Question:** The current SECURITY.md has: primary contact `filip.sabacky@ceosdata.com` (correct), no secondary contact (GitHub Security Advisories not mentioned), and supported versions section that says "Only the latest released version receives security fixes" without specifying v1.0.0+. The task spec requires: primary: `filip.sabacky@ceosdata.com`, secondary: GitHub Security Advisories, supported: v1.0.0+. What additions are needed vs. what exists?
**Why it matters:** SECURITY.md is a trust signal for OSS adopters and is enforced by the cross-file invariant in CLAUDE.md §Cross-File Invariants (maintainer email must be consistent across SECURITY.md, CODE_OF_CONDUCT.md, CONTRIBUTING.md).
**Search method:** `Read C:/gitea_agent-flow/SECURITY.md` (already done); the file is 16 lines — full content confirmed; gaps identified: no GitHub Security Advisories link, no version range specification.

---

### Q5: What Czech-language text exists in CLAUDE.md that needs to be removed for OSS?
**Question:** The CLAUDE.md in this repo serves as the plugin's own CLAUDE.md (not a consumer project's), and it documents the `## Automation Config` contract for consuming projects. Grep for Czech text reveals that CLAUDE.md itself has no Czech language (confirmed — 0 Czech words in grep output). However, does CLAUDE.md contain internal cross-references like `feedback_doc_completeness.md` (line 319), `forge` pipeline references (v10.0.0 reliability contract mentions `core/lib/stage-invariant.sh`), or version-specific change notes that are internal development artifacts rather than public documentation?
**Why it matters:** CLAUDE.md is checked into the public repo and consumed by Claude Code when users install the plugin; internal references to development tooling or internal discipline files would confuse OSS users.
**Search method:** `Read C:/gitea_agent-flow/CLAUDE.md` — confirmed: line 319 references `feedback_doc_completeness.md` (internal discipline doc); `## Versioning Policy` section references v8.0.0 and v9.0.0 as historical examples; `## Cross-File Invariants` references internal Gitea issue template paths.

---

### Q6: What "forge" pipeline references in CLAUDE.md need removal or sanitization?
**Question:** CLAUDE.md line 106 references `tests/scenarios/v10-step-completion-invariants-completeness.sh` as a harness scenario that validates mandatory agent sections. It also references `core/lib/stage-invariant.sh::check_dispatch_witness` (a runtime helper). The `## Block Comment Template` section uses `[ceos-agents]` prefix which must become `[agent-flow]`. The `## Plugin Composability` section explicitly uses the `ceos-agents:` namespace. How many total references to the old plugin name/namespace appear in CLAUDE.md and what is the pattern of replacement needed?
**Why it matters:** CLAUDE.md is the canonical documentation that Claude Code reads when working in consuming projects; incorrect namespace references would cause confusion and errors.
**Search method:** `grep -n "ceos-agents" C:/gitea_agent-flow/CLAUDE.md` — confirmed occurrences at lines 7, 10, 25, 167, 246, 264, 268, 272, 274, 276, 283, 294, 297 (13+ lines); full replacement mapping required.

---

### Q7: What internal version references (v6-v10 history) in CLAUDE.md should be removed vs. kept?
**Question:** CLAUDE.md's `## Versioning Policy` section uses `## Output Contract (v9.0.0)` and `v8.0.0 agents` as concrete examples of what triggers MAJOR vs. MINOR bumps. The `## Step Completion Invariants` note says `v10.0.0+, mandatory`. The `## Webhook Payloads` section references `v6.8.0`, `v6.9.0`, `v6.9.1` as version-specific behavior anchors. Are these version references meaningful to OSS users (as historical anchors for backward-compat decisions) or do they read as confusing internal development history?
**Why it matters:** OSS users encountering "v6.8.0 added X" in CLAUDE.md will wonder why the current version is v1.0.0, creating confusion; references must be either removed or reframed as "since initial release".
**Search method:** `grep -n "v6\.\|v7\.\|v8\.\|v9\.\|v10\." C:/gitea_agent-flow/CLAUDE.md` — 19 matches confirmed; need to assess which are forward-facing behavioral specs (keep) vs. historical change notes (remove).

---

### Q8: What content in docs/plans/roadmap.md is valuable for a community-facing roadmap?
**Question:** The current roadmap.md (2193+ lines) contains: (a) DONE history from v4.1.0 through v10.2.0 with full implementation details — NOT for public roadmap; (b) PLANNED v10.3.0 (GitHub cleanup), v10.4.0 (public polish), v10.5.0 (Direct Mode) — partially relevant; (c) BACKLOG section with designed features awaiting slots; (d) EXPLORING section with research directions; (e) VISION table with big ideas; (f) NOT PLANNED table with evaluated-and-rejected ideas. What subset should appear in the new `docs/roadmap.md` for OSS users?
**Why it matters:** The EXPLORING section contains large blocks of Czech-language text and references to BIFITO/drmax internal projects which must not appear in the public roadmap; the VISION and NOT PLANNED sections are genuinely useful for OSS users.
**Search method:** `Read C:/gitea_agent-flow/docs/plans/roadmap.md` lines 1923-2193 (EXPLORING, VISION, NOT PLANNED sections) — confirmed Czech text in EXPLORING section lines 1928, 1932-1944, 1957-1987 with heavy internal project references.

---

### Q9: Does docs/plans/roadmap.md contain Czech text in the PLANNED and BACKLOG sections that must be sanitized before extraction?
**Question:** The Release Allocation table in the EXPLORING section (lines 1944-1987) documents every release from v7.0.0 through v10.5.0, with most entries written in mixed Czech/English. The BACKLOG section (starting at line 961) contains detailed feature designs. Are the PLANNED items (v10.3.0, v10.4.0, v10.5.0) written in Czech or English? Can the BACKLOG section be cleanly extracted for the public roadmap?
**Why it matters:** Any Czech text appearing in the public `docs/roadmap.md` would immediately signal this was not designed for an international OSS audience and undermine the professional quality of the release.
**Search method:** `Read C:/gitea_agent-flow/docs/plans/roadmap.md` offset 961 — BACKLOG section start; grep for Czech words (potřebujeme, přidat, smazat, řádků, souborů) in lines 961-1923.

---

### Q10: What is in docs/superpowers/specs/ and does any content need preservation?
**Question:** The `docs/superpowers/specs/` directory contains 9 files including brainstorm documents for sub-projects E (showcase web), F (dashboard), A (agent shape), B (HITL), a CEO presentation, and an agent I/O contracts brief. These are internal design artifacts for the ceos-agents-web companion project and the v8.0.0/v9.0.0 implementation. The v10.3.0 cleanup plan deletes this entire directory. Is there any content in these files that should be extracted to docs/roadmap.md or docs/architecture.md before deletion?
**Why it matters:** The CEO presentation and brainstorm documents contain architectural decisions and competitive analysis that may have value as community-facing architecture documentation.
**Search method:** `ls C:/gitea_agent-flow/docs/superpowers/specs/` (done — 9 files); `Read` the public-release-readiness and agent-shape-design docs to assess extractable content.

---

### Q11: Are the cross-file invariants currently satisfied and what breaks during rename?
**Question:** CLAUDE.md §Cross-File Invariants specifies three invariants: (1) License SPDX `"MIT"` consistent across plugin.json, marketplace.json, LICENSE; (2) maintainer email `filip.sabacky@ceosdata.com` consistent across SECURITY.md, CODE_OF_CONDUCT.md, CONTRIBUTING.md; (3) .gitea/issue_template/ and .github/ISSUE_TEMPLATE/ must be byte-identical. All three are currently satisfied (confirmed by reading files). After renaming "ceos-agents" → "agent-flow", which invariants break and require re-verification?
**Why it matters:** The cross-file invariants are asserted by Phase 8 verification scenarios in the test harness; if they break during the rename, the harness will report failures.
**Search method:** Confirmed invariant 1: MIT in both JSON files. Confirmed invariant 2: `filip.sabacky@ceosdata.com` in all three files. Confirmed invariant 3: .gitea and .github bug_report.md, feature_request.md, and PR templates are byte-identical pairs. The rename to "agent-flow" will break invariant 3 content (bug report says "Report a bug in ceos-agents") and plugin metadata files.

---

### Q12: What is the complete list of "ceos-agents" string occurrences across the four doc files being rewritten?
**Question:** README.md contains "ceos-agents" ~20 times (plugin title, mermaid labels, install command `ceos-agents@ceos-agents`, skill namespace `/ceos-agents:*`, warning table). CHANGELOG.md contains 83 occurrences. SECURITY.md contains 1 occurrence ("ceos-agents" in the first sentence). CLAUDE.md contains 13+ occurrences (plugin name, namespace, block comment prefix, webhook payload field name `ceos-agents-block`). For the CHANGELOG, the `ceos-agents-block` webhook payload field name is documented as a never-renamed field — does renaming to `agent-flow-block` constitute a breaking contract change?
**Why it matters:** The webhook payload field `ceos-agents-block` is documented as "never renamed or removed" in CLAUDE.md §Webhook Payloads; changing it would be a MAJOR version bump per the versioning policy, creating tension with the clean v1.0.0 start.
**Search method:** `grep -n "ceos-agents-block" C:/gitea_agent-flow/CLAUDE.md` and related webhook skills; assess whether renaming the webhook field requires a MAJOR bump or whether v1.0.0 is itself a clean-slate reset.

---

### Q13: What does the CONTRIBUTING.md need for OSS community readiness?
**Question:** The current CONTRIBUTING.md documents: fork workflow, coding standards, agent format, command format, config templates, custom agent examples, MCP config examples, test scenario security expectations, issue reporting, and maintainer contact. It references `ceos-agents` in the title and opening line. It includes a "Functional test scenarios — security expectations" section with detailed bash security rules (no eval, no awk+source, mktemp hygiene) — is this level of technical detail appropriate for a community CONTRIBUTING.md or is it too internal?
**Why it matters:** A well-crafted CONTRIBUTING.md is a key OSS community signal; the test security section is excellent technical documentation but may need to be moved to a dedicated `docs/guides/contributing-tests.md` to keep the main file approachable.
**Search method:** `Read C:/gitea_agent-flow/CONTRIBUTING.md` (done); 124 lines, "ceos-agents" appears in line 1 title and line 3; overall quality is good, structure is already OSS-ready.

---

### Q14: What installation command changes are needed throughout docs for the GitHub public URL?
**Question:** The README Quick Start (line 53) uses `claude plugin marketplace add <path-to-repo>  # e.g. C:/gitea_ceos-agents` — an internal Windows path. The plugin.json `repository` field is `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git` — an internal Gitea URL. The install command `claude plugin install ceos-agents@ceos-agents` references the old plugin name. For the public release, the install command should be `claude plugin marketplace add fsabacky/agent-flow` (or the new GitHub repo URL) and `claude plugin install agent-flow@agent-flow`. Are there any other files besides README.md and plugin.json that contain the internal Gitea URL?
**Why it matters:** A single internal URL leaking into the public docs would fail the OSS release quality bar and confuse users trying to install the plugin.
**Search method:** `grep -rn "gitea.internal\|ceosdata.com\|C:/gitea" C:/gitea_agent-flow/*.md C:/gitea_agent-flow/.claude-plugin/` — confirmed: plugin.json line 8 has `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git`; README line 53 has `C:/gitea_ceos-agents`; CHANGELOG line 613 documents this as a historical change (immutable).

---

### Q15: What is the "feedback_doc_completeness.md" referenced in CLAUDE.md line 319?
**Question:** CLAUDE.md line 319 says: "See `feedback_doc_completeness.md` for the doc-count drift audit discipline (CLAUDE.md, README.md, docs/reference/automation-config.md, docs/reference/skills.md, docs/architecture.md count fields must be kept in sync)." Does this file exist in the repo? Is it a tracked discipline file that consumers need, or is it an internal development artifact that should be removed from the CLAUDE.md reference?
**Why it matters:** Referencing a non-existent or internal-only file in the public CLAUDE.md would confuse OSS plugin consumers who read it to understand development conventions.
**Search method:** `ls C:/gitea_agent-flow/feedback_doc_completeness.md` — check existence; if it exists, assess whether it belongs in the public repo; if it doesn't exist, CLAUDE.md line 319 is a broken reference that must be removed.

---

### Q16: Does the CLAUDE.md "## Automation Config" section need sanitization or is it purely generic?
**Question:** The Automation Config documentation in CLAUDE.md is the canonical contract for consumers. It defines 18 optional sections with pure generic examples (github, my-org/my-repo, label:bug state:open). However, some Automation Config section descriptions contain version-specific notes: Autopilot section references `.ceos-agents/autopilot.log` as the default log path — this path embeds the old plugin name. The block comment template uses `[ceos-agents]` prefix. The `ceos-agents-block` webhook payload field is documented as a never-renamed field. What config-contract references must change to `agent-flow` and what can stay as-is?
**Why it matters:** The Automation Config documentation is the primary reference for plugin consumers; any "ceos-agents" references in examples, path defaults, or block comment prefixes must be consistently renamed to "agent-flow".
**Search method:** `grep -n "ceos-agents" C:/gitea_agent-flow/CLAUDE.md` — confirmed: `.ceos-agents/autopilot.log` at line 246, `[ceos-agents]` block comment prefix at lines 283/294/297, `ceos-agents-block` webhook field at line 264.

---

### Q17: What is the correct target GitHub repository URL and namespace for the rename?
**Question:** The docs/plans/2026-04-29-public-release-plan.md specifies the GitHub URL as `github.com/fsabacky/ceos-agents`. But this forge pipeline is performing a rename to "agent-flow" for public OSS release. The new repository name should be `agent-flow`, suggesting the URL becomes `github.com/fsabacky/agent-flow`. The plugin namespace in all skill invocations (`/ceos-agents:fix-bugs`) will become `/agent-flow:fix-bugs`. This touches: plugin.json name field, marketplace.json name fields, all 18 skill frontmatter descriptions, CLAUDE.md namespace references, README skill tables, and all issue/PR templates. What is the confirmed new namespace and GitHub URL?
**Why it matters:** The namespace `agent-flow:` will appear in every user-facing command example across all documentation; getting it wrong means users cannot invoke skills.
**Search method:** Review the forge pipeline task specification (this document's preamble); confirmed rename target is "agent-flow" — all skill invocations become `/agent-flow:<skill>`.

---

### Q18: Does the CHANGELOG.md "Language note" and "Repo split note" need to be removed?
**Question:** Lines 8-10 of CHANGELOG.md contain: (1) a language note explaining Czech-to-English translation history across pre-v3.0.0 entries, and (2) a "Repo split note (2026-04-28)" explaining that sub-project E (showcase web) was extracted to a separate `ceos-agents-web` repo. For a clean v1.0.0 CHANGELOG, both notes are irrelevant to OSS users. However, the repo split note contains architectural context about the web companion project separation. Should this context appear in docs/architecture.md or docs/roadmap.md instead?
**Why it matters:** The CHANGELOG intro notes reference internal project history that OSS users have no context for; for a clean v1.0.0 start the entire pre-v1.0.0 history is replaced with a single entry, making both notes moot.
**Search method:** `Read C:/gitea_agent-flow/CHANGELOG.md` lines 1-11 (done); confirmed both notes exist and reference internal project split history.

---

### Q19: What version-specific references in the issue and PR templates require updating?
**Question:** The bug report templates (.gitea/issue_template/bug_report.md and .github/ISSUE_TEMPLATE/bug_report.md) both reference "ceos-agents version:" in the Environment section and say "Report a bug in ceos-agents" in the `about` frontmatter field. They are currently byte-identical (invariant 3 satisfied). After rename, both must be updated identically to maintain the cross-file parity invariant. What is the full diff needed on each template?
**Why it matters:** Breaking byte-parity between .gitea and .github templates violates the cross-file invariant documented in CLAUDE.md and asserted by Phase 8 test scenarios.
**Search method:** `Read .gitea/issue_template/bug_report.md` and `.github/ISSUE_TEMPLATE/bug_report.md` (done — both identical, 24 lines); changes needed: line 3 `about: Report a bug in agent-flow`, line 21 `- agent-flow version:`.

---

### Q20: What is the minimum viable docs/roadmap.md structure for community readiness?
**Question:** The new `docs/roadmap.md` should be extracted from `docs/plans/roadmap.md` content but sanitized for public consumption. The VISION table (lines 2143-2159) and NOT PLANNED table (lines 2162-2183) are the clearest candidates for extraction — they are written in English and discuss product direction without internal project references. The BACKLOG section (961-1922) and EXPLORING section (1923-1989) contain substantial Czech text and internal references. What is the minimal English-only, internal-reference-free subset of roadmap content that would make sense as a community-facing roadmap?
**Why it matters:** A community roadmap signals product maturity and invites contribution; extracting only English sections from the 2193-line internal roadmap produces a focused, credible OSS roadmap without exposing development process artifacts.
**Search method:** `Read C:/gitea_agent-flow/docs/plans/roadmap.md` lines 961-1060 (BACKLOG start) and 2143-2193 (VISION + NOT PLANNED) to assess English-only extractable content; PLANNED items (v10.3.0-v10.5.0) in the release table are mixed Czech/English and require English-only rewrites.

---

## Summary

The documentation rewrite scope for the "ceos-agents" → "agent-flow" v1.0.0 OSS release is substantial but well-defined. The core challenge is not structural (the docs are well-organized) but content sanitization: removing approximately 83 "ceos-agents" occurrences in CHANGELOG alone, stripping internal project references (BIFITO, drmax, gitea.internal.ceosdata.com), removing Czech-language text concentrated in CHANGELOG per-version notes and the EXPLORING section of the roadmap, and updating the internal Gitea URL and plugin namespace throughout. The cross-file invariants (SPDX license, maintainer email, template parity) are all currently satisfied and must be preserved through the rename. The SECURITY.md requires two additions (GitHub Security Advisories as secondary contact, explicit v1.0.0+ supported version range). CLAUDE.md itself contains no Czech text but embeds 13+ old namespace references, an internal file reference (`feedback_doc_completeness.md`), and version-anchored descriptions that need either removal or reframing as forward-facing contracts. The biggest single decision is the CHANGELOG strategy: a clean v1.0.0 start vs. a curated summary of capability evolution — the 2193-line internal roadmap and 83-occurrence CHANGELOG both strongly favor the clean-start approach for credible OSS positioning.
