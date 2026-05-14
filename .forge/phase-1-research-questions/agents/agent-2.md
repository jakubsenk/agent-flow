# Phase 1 Research Questions — Agent 2 (Version Refs & Deletion Inventory)

## Focus Area
Internal version references, deletion inventory, .gitignore state

## Research Questions

### Q1: Complete inventory of v6.x version references outside docs/plans/ and docs/superpowers/
**Question:** Which files in agents/, skills/, core/, docs/reference/, docs/guides/, checklists/, and tests/ contain `v6.x.x` version strings (e.g., v6.9.0, v6.10.0), and are those references structural/contractual (must be kept as test scenario names) or incidental prose references (safe to remove)?
**Why it matters:** v6.x era references in shipped content pollute the public release with internal development history that external users have no context for.
**Search method:** `grep -r "v6\.[0-9]\+\.[0-9]\+" agents/ skills/ core/ docs/reference/ docs/guides/ checklists/ --include="*.md" --include="*.sh" -l`

---

### Q2: Complete inventory of v7.x–v8.x version references in shipped content
**Question:** Which non-plan, non-superpowers files contain `v7.x.x` or `v8.x.x` version strings, and what is the nature of each reference (migration guide title, prose description, test scenario name, agent section label)?
**Why it matters:** Migration guides for v7→v8 and v8→v9 exist in docs/guides/ — these will need a decision: delete entirely, or sanitize version numbers from prose while keeping conceptual content?
**Search method:** `grep -rn "v7\.[0-9]\+\.[0-9]\+\|v8\.[0-9]\+\.[0-9]\+" agents/ skills/ core/ docs/reference/ docs/guides/ --include="*.md" -l`

---

### Q3: Files containing "v9.0.0+" or "v10.0.0+" in section headers
**Question:** Which agent files contain "v9.0.0+" or "v10.0.0+" as inline labels in section headings (e.g., `## Output Contract (v9.0.0+, mandatory)` or `## Step Completion Invariants (v10.0.0+, mandatory)`)?
**Why it matters:** The task calls for stripping these version qualifiers to just "mandatory". Confirming their exact form in each agent file is required before bulk substitution.
**Search method:** `grep -rn "v9\.0\.0+\|v10\.0\.0+" agents/ --include="*.md"`

---

### Q4: "v10.0.0 3-layer defense" prose references in agents
**Question:** Three agent files (fixer.md, reviewer.md, publisher.md) contain the phrase "v10.0.0 3-layer defense" in their Step Completion Invariants prose. Should this specific phrase be removed, changed to "3-layer defense", or left as a technical reference?
**Why it matters:** These are not section headers (already searched and found no `v9.0.0+, mandatory` pattern) — they are prose inside the invariants body. The migration spec is silent on prose-level v10 references beyond section headers.
**Search method:** `grep -n "v10\.0\.0" agents/fixer.md agents/reviewer.md agents/publisher.md`

---

### Q5: Version references in test scenario filenames (keep vs rename)
**Question:** The tests/scenarios/ directory contains ~160 scenario files with version-stamped names (e.g., `v6.9.0-cross-file-invariants.sh`, `v9.3.0-metrics-html-escape.sh`). Should these filenames be renamed to remove version prefixes, or are they treated as opaque test artifacts that are deleted entirely (along with `docs/plans/`)?
**Why it matters:** If tests/ is a kept artifact, renaming ~160 scenario files is a large mechanical change. If only specific versions are stripped from prose, filenames may stay as-is. The scope decision determines rename effort.
**Search method:** `ls tests/scenarios/ | grep -c "^v[0-9]"` (count version-prefixed scenarios)

---

### Q6: Version references in CLAUDE.md (the project instructions file kept as-is or updated)
**Question:** CLAUDE.md contains multiple references to v6.x through v10.x (e.g., "v6.8.0", "v6.9.0", "v9.0.0+", "v10.0.0+", "v10.2.0"). Which of these are contractual (versioning policy table, webhook backcompat notes) vs incidental, and does the migration spec call for updating CLAUDE.md at all?
**Why it matters:** CLAUDE.md is the authoritative plugin documentation for users and the harness. Leaving internal version references in it exposes development history. But some references (versioning policy examples, backcompat notices) may be deliberately historical.
**Search method:** `grep -n "v[6-9]\.[0-9]\+\.[0-9]\+\|v10\.[0-9]\+\.[0-9]\+" CLAUDE.md`

---

### Q7: Version references in CHANGELOG.md — scope of changes
**Question:** CHANGELOG.md (199KB) documents every version from v1.x to v10.2.0. Should the entire CHANGELOG be deleted, truncated to only show v1.0.0 as the public starting point, or kept verbatim? Does it contain internal hostnames or credentials?
**Why it matters:** A 199KB changelog exposing 50+ internal versions and internal Gitea URLs would be confusing/embarrassing on a public GitHub repo. The deletion scope matters for the migration.
**Search method:** Read first 100 lines and last 50 lines of CHANGELOG.md; grep for internal hostnames like `ceosdata.com`, `gitea.internal`

---

### Q8: Exact count of .forge.bak-*/ directories to delete
**Question:** How many `.forge.bak-*/` directories exist at the repo root, and do any of them have naming patterns beyond the expected ISO timestamp format (e.g., `.forge.bak-20260429T090858Z-v9.0.0-H-completed`, `.forge.bak-20260416-070200-aborted`)?
**Why it matters:** The deletion inventory mentions ".forge.bak-*/ directories (multiple)" — the exact count (currently ~64 visible) and the special-suffix variants need confirmation to ensure the .gitignore glob pattern `'.forge.bak-*/'` captures all of them.
**Search method:** `ls -d .forge.bak-*/ | wc -l` and `ls -d .forge.bak-*/`

---

### Q9: Does .forge.v8.0.0/ directory exist and what pattern should cover it?
**Question:** A directory named `.forge.v8.0.0` was observed at the root. Is this a single instance or could there be others (`.forge.v9.0.0`, `.forge.v10.0.0`)? The proposed .gitignore includes `.forge.v*/` — does this pattern correctly match it?
**Why it matters:** If only `.forge.bak-*/` is in .gitignore but not `.forge.v*/`, the `.forge.v8.0.0` directory would still be committed. Confirming the full set of `.forge.*` directories ensures comprehensive .gitignore coverage.
**Search method:** `ls -d .forge.*` (list all .forge.* prefixed directories)

---

### Q10: Current .gitignore content and what is already covered
**Question:** The current .gitignore contains only 4 entries: `.vs/`, `nul`, `.claude/settings.local.json`, and `.env`. Which of the proposed new entries (.forge/, .forge.bak-*/, .ceos-agents/, *.stackdump, REVIEW-REPORT-*.md, docs/plans/) are actually NOT currently ignored, and would adding them retroactively affect already-tracked files?
**Why it matters:** If any of the directories-to-delete are already tracked in git (not just untracked), adding them to .gitignore alone is insufficient — they must also be git-removed (`git rm -r --cached`).
**Search method:** `git ls-files .forge.bak-2026-04-29T210550Z/ .ceos-agents/ docs/plans/ 2>/dev/null | head -5` and `cat .gitignore`

---

### Q11: Are the .forge.bak-*/ directories tracked in git or only untracked?
**Question:** Git status shows the `.forge.bak-*/` dirs listed under `??` (untracked). Are ALL `.forge.bak-*` directories untracked, or are any committed to git history? If committed, deletion alone won't remove them from git history.
**Why it matters:** If backup directories are in git history, the public repo would expose them via `git log` even after deletion, requiring either git history rewriting or accepting their presence in history.
**Search method:** `git log --oneline -- .forge.bak-20260325-204006/ | head -3` and `git ls-files --others --exclude-standard .forge.bak-*/`

---

### Q12: Does a "nul" file exist at the repo root and what does it contain?
**Question:** `.gitignore` contains `nul` as an entry (Windows NUL device artifact). Does an actual file named `nul` exist at the repo root, and if so, what are its contents (likely empty, size 0)?
**Why it matters:** `nul` on Windows is the null device — a file named `nul` in the repo would be an accidental Windows artifact that should be deleted before public release.
**Search method:** `ls -la nul` and `stat nul` (to check file size and whether it is a real file or device)

---

### Q13: What files reference the internal repository URL (gitea.internal.ceosdata.com)?
**Question:** plugin.json and marketplace.json both reference `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git` as the repository URL. How many other files (docs, guides, skills) contain this internal URL and need to be updated to the public GitHub URL?
**Why it matters:** Shipping files with internal Gitea URLs would break installation instructions and reveal internal infrastructure to public users.
**Search method:** `grep -rn "gitea.internal.ceosdata.com\|ceosdata.com" --include="*.md" --include="*.json" --include="*.sh" . | grep -v ".forge"`

---

### Q14: Version references in docs/reference/ files that will stay in the public release
**Question:** Which specific docs/reference/ files (automation-config.md, agents.md, skills.md, pipeline.md, config.md, etc.) contain internal version references (v6–v10), and what is the nature of each occurrence — section heading, "added in v6.x" annotation, or version-specific behavior description?
**Why it matters:** docs/reference/ files are the primary user-facing documentation for the plugin and will be read by public GitHub users. Internal version history annotations would confuse them.
**Search method:** `grep -n "v[6-9]\.[0-9]\+\.[0-9]\+\|v10\.[0-9]\+\.[0-9]\+" docs/reference/*.md`

---

### Q15: Does docs/guides/migration-v7-to-v8.md and migration-v8-to-v9.md need deletion or retention?
**Question:** Two migration guides exist in docs/guides/: `migration-v7-to-v8.md` and `migration-v8-to-v9.md`. Since public users start at v1.0.0, these guides are irrelevant. Should they be deleted outright, or is their content (which may contain platform-agnostic guidance) worth keeping under renamed titles?
**Why it matters:** Keeping internal migration guides in a public release creates confusion about the plugin's version history. Deletion is cleaner but may lose useful content if the guides discuss generic concepts (TOML overlays, dispatch enforcement patterns).
**Search method:** Read first 20 lines of each migration guide to assess content type; check if any other docs link to them via `grep -r "migration-v7\|migration-v8" --include="*.md"`

---

### Q16: Are there version references in agent YAML frontmatter?
**Question:** Do any of the 17 agent files in agents/ have version strings in their YAML frontmatter (name, description, model, style fields), such as `description: "v10.0.0 analyst agent"` or similar?
**Why it matters:** Frontmatter description fields appear in Claude Code's agent picker UI. Internal version stamps there would be visible to all public users in the picker dropdown.
**Search method:** Read first 6 lines of each agents/*.md file; grep frontmatter sections for version patterns: `grep -A5 "^---" agents/*.md | grep "v[0-9]"`

---

### Q17: What version references appear in core/ contracts and snippets (files that ship with the plugin)?
**Question:** 14 files in core/ contain version references (v6–v10 found in initial scan). What are the specific version strings, in which core contracts do they appear, and are they cross-references to other contracts ("see v9.0.0 change") or structural labels?
**Why it matters:** core/ files define the runtime behavior contracts shipped with the plugin. Version-stamped cross-references are meaningless to external users who have no access to the internal changelog.
**Search method:** `grep -n "v[6-9]\.[0-9]\+\.[0-9]\+\|v10\.[0-9]\+\.[0-9]\+" core/*.md core/**/*.md core/lib/*.sh`

---

### Q18: What version references exist in the skills/version-check/SKILL.md scheduled for deletion?
**Question:** The `skills/version-check/SKILL.md` file is scheduled for deletion. What version references does it contain, and does any other skill or agent reference it by path or name that would leave dangling references after deletion?
**Why it matters:** If other files reference `/ceos-agents:version-check` or `skills/version-check/`, they will produce broken references in the public release after the skill is deleted.
**Search method:** `cat skills/version-check/SKILL.md` and `grep -r "version-check\|version_check" skills/ agents/ docs/ --include="*.md" -l`

---

### Q19: What is the full list of "nul" and stackdump files matching deletion patterns?
**Question:** Beyond `grep.exe.stackdump`, are there other `*.stackdump` files anywhere in the repository? Is `nul` the only Windows device artifact file, or are there others (e.g., `con`, `prn`, `aux`)?
**Why it matters:** The .gitignore entry `*.stackdump` should cover all stackdump variants, but confirming no other Windows device artifacts exist ensures complete cleanup.
**Search method:** `find . -name "*.stackdump" -o -name "nul" -o -name "con" -o -name "aux" 2>/dev/null | grep -v ".git"` and `ls -la *.stackdump nul 2>/dev/null`

---

### Q20: What is the version string in plugin.json/marketplace.json and what should it become for the v1.0.0 public release?
**Question:** Both plugin.json and marketplace.json currently show version `"10.2.0"`. Does the v1.0.0 public release require changing this to `"1.0.0"` in these files, and are there any other files that hardcode `"10.2.0"` or `"version": "10"` that would also need updating?
**Why it matters:** Releasing as version `10.2.0` on a public GitHub repo that has no prior public history would confuse users — jumping from non-existent to v10. The public launch presumably starts at v1.0.0.
**Search method:** `grep -rn "\"version\".*10\.2\.0\|version.*10\.2\.0" --include="*.json" --include="*.md" . | grep -v ".forge"` and check docs/reference for version badges

---

## Summary

This focus area covers three interrelated concerns for the public OSS release. First, **version reference removal**: internal version strings (v6.x through v10.x) appear across agents (3 files with v10.0.0 prose), skills (19 files), core (14 files), docs/reference and docs/guides, tests/scenarios (169 files with version-stamped names), and the root CLAUDE.md. The key distinction between "structural" references (test scenario filenames, contractual behavior descriptions) and "incidental" prose references determines the extent of changes needed. Second, **deletion inventory**: approximately 64+ `.forge.bak-*/` directories exist (all currently untracked per git status), plus one `.forge.v8.0.0` directory, the `skills/version-bump/` directory, `grep.exe.stackdump`, a `nul` file artifact, and the single `REVIEW-REPORT-v3.1.0.md` at root. The `docs/plans/` directory (~90+ files) and `docs/superpowers/` directory (~9 files) are also slated for deletion. Third, **the .gitignore** currently has only 4 entries and requires expansion to prevent these artifacts from reappearing. The critical risk is that `docs/plans/` may contain cross-references to internal infrastructure (ceosdata.com hostnames, Redmine/YouTrack project names) that would leak if any plans files were accidentally left in place, and that the plugin's version number in plugin.json/marketplace.json (currently 10.2.0) likely needs resetting to 1.0.0 for the public launch.
