# Phase 4 — Formal Acceptance Criteria for v7.0.0

Every AC is a single bash one-liner that exits 0 on PASS and non-zero on FAIL. ACs grouped by REQ. All grep-based ACs use `--exclude-dir=.forge --exclude-dir=".forge.bak-*" --exclude-dir=docs/plans --exclude-dir=docs/superpowers --exclude=CHANGELOG.md` to avoid false positives from forge artifacts and historical content.

Working directory for all commands: repo root.

---

## REQ-DEL-EXTRA-LABELS

### AC-DEL-EXTRA-LABELS-1 — No `Extra labels` references in active surfaces

Given the v7.0.0 head, when a recursive grep is run for `Extra labels`, then there shall be zero matches.

```bash
[ "$(grep -rn 'Extra labels' --include='*.md' --exclude-dir=.forge --exclude-dir='.forge.bak-*' --exclude-dir=docs/plans --exclude-dir=docs/superpowers --exclude=CHANGELOG.md . | wc -l | tr -d ' ')" = "0" ]
```

### AC-DEL-EXTRA-LABELS-2 — No `extra_labels` parse-rule artifact

Given the v7.0.0 head, when `core/config-reader.md` is grepped for the parse rule string, then no match is found.

```bash
! grep -q 'pr_rules\.extra_labels' core/config-reader.md
```

### AC-DEL-EXTRA-LABELS-3 — `agents/publisher.md` no longer mentions Extra labels

```bash
! grep -q 'Extra labels' agents/publisher.md
```

### AC-DEL-EXTRA-LABELS-4 — `OPTIONAL_SECTIONS` test arrays no longer contain Extra labels

```bash
! grep -q '"Extra labels"' tests/scenarios/config-reader-sections.sh && ! grep -q '"Extra labels"' tests/scenarios/v6.9.0-bc-no-renamed-section.sh
```

### AC-DEL-EXTRA-LABELS-5 — Mutation guard updated to 18

```bash
grep -q '\[ "${#OPTIONAL_SECTIONS\[@\]}" -eq 18 \]' tests/scenarios/v6.9.0-bc-no-renamed-section.sh
```

---

## REQ-PAUSE-LIMITS-DOC

### AC-PAUSE-LIMITS-DOC-1 — Used-By column lists fix-ticket and 5 more

Given the v7.0.0 head, when the Quick reference row for `Pause Limits` is read from `docs/reference/automation-config.md`, then the row contains `/fix-ticket` (and by inference the full 6-skill list, since the row was changed wholesale).

```bash
grep -E '^\| Pause Limits \| No \| /fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot, /resume-ticket \|' docs/reference/automation-config.md
```

### AC-PAUSE-LIMITS-DOC-2 — Old single-/autopilot row no longer present

```bash
! grep -E '^\| Pause Limits \| No \| /autopilot \|$' docs/reference/automation-config.md
```

---

## REQ-RENAME-STATUS

### AC-RENAME-STATUS-1 — `skills/status/` no longer exists

```bash
[ ! -d skills/status ]
```

### AC-RENAME-STATUS-2 — `skills/pipeline-status/` exists

```bash
[ -d skills/pipeline-status ] && [ -f skills/pipeline-status/SKILL.md ]
```

### AC-RENAME-STATUS-3 — Frontmatter `name: pipeline-status`

```bash
head -10 skills/pipeline-status/SKILL.md | grep -qE '^name: pipeline-status$'
```

### AC-RENAME-STATUS-4 — No stale `ceos-agents:status` references in active surfaces (workflow-router excluded)

The workflow-router file is excluded because its "Did you mean...?" fallback prose (design.md §5.3) intentionally references the deprecated identifier. Workflow-router presence is positively verified by AC-DOCS-COLLISION-WARN-WORKFLOW-1.

```bash
[ "$(grep -rn 'ceos-agents:status\b' --include='*.md' --exclude-dir=.forge --exclude-dir='.forge.bak-*' --exclude-dir=docs/plans --exclude-dir=docs/superpowers --exclude=CHANGELOG.md --exclude=skills/workflow-router/SKILL.md . | wc -l | tr -d ' ')" = "0" ]
```

### AC-RENAME-STATUS-5 — workflow-router intent table updated (deprecated mention restricted to "Deprecated names" section)

The intent table row at line 18 must be updated to `ceos-agents:pipeline-status`. The deprecated `ceos-agents:status` form is allowed to remain ONLY inside the new "Deprecated names" section (design.md §5.3); it must NOT appear in the intent table or Step 3/4 prose.

```bash
grep -q '`ceos-agents:pipeline-status`' skills/workflow-router/SKILL.md && ! grep -qE '^\| .*Show status.*\| `ceos-agents:status`' skills/workflow-router/SKILL.md && ! grep -qE 'NOT destructive.*\bstatus\b.*dashboard' skills/workflow-router/SKILL.md
```

### AC-RENAME-STATUS-6 — workflow-router Step 3 prose updated

```bash
grep -E 'NOT destructive.*pipeline-status' skills/workflow-router/SKILL.md
```

### AC-RENAME-STATUS-7 — README skill table updated

```bash
grep -q '`/pipeline-status`' README.md && ! grep -qE '^\| `/status` \|' README.md
```

---

## REQ-RENAME-INIT

### AC-RENAME-INIT-1 — `skills/init/` no longer exists

```bash
[ ! -d skills/init ]
```

### AC-RENAME-INIT-2 — `skills/setup-mcp/` exists

```bash
[ -d skills/setup-mcp ] && [ -f skills/setup-mcp/SKILL.md ]
```

### AC-RENAME-INIT-3 — Frontmatter `name: setup-mcp`

```bash
head -10 skills/setup-mcp/SKILL.md | grep -qE '^name: setup-mcp$'
```

### AC-RENAME-INIT-4 — No stale `ceos-agents:init` references in active surfaces (workflow-router excluded)

The workflow-router file is excluded for the same reason as AC-RENAME-STATUS-4 (design.md §5.3 deprecated-names prose). Workflow-router presence is positively verified by AC-DOCS-COLLISION-WARN-WORKFLOW-1.

```bash
[ "$(grep -rn 'ceos-agents:init\b' --include='*.md' --exclude-dir=.forge --exclude-dir='.forge.bak-*' --exclude-dir=docs/plans --exclude-dir=docs/superpowers --exclude=CHANGELOG.md --exclude=skills/workflow-router/SKILL.md . | wc -l | tr -d ' ')" = "0" ]
```

### AC-RENAME-INIT-5 — `core/mcp-preflight.md` references setup-mcp, not init

```bash
grep -q '/ceos-agents:setup-mcp' core/mcp-preflight.md && ! grep -q '/ceos-agents:init' core/mcp-preflight.md
```

### AC-RENAME-INIT-6 — `core/config-reader.md` references setup-mcp, not init

```bash
grep -q '/ceos-agents:setup-mcp' core/config-reader.md && ! grep -q '/ceos-agents:init\b' core/config-reader.md
```

### AC-RENAME-INIT-7 — README skill table updated

```bash
grep -q '`/setup-mcp`' README.md && ! grep -qE '^\| `/init` \|' README.md
```

---

## REQ-PUBLISH-AUTO-DETECT

### AC-PUBLISH-AUTO-DETECT-1 — Step 0 branch-parse prose present

Given the v7.0.0 head, when `skills/publish/SKILL.md` is read, then it contains a Step 0 (or equivalently-numbered first step) that parses the branch name BEFORE MCP pre-flight.

```bash
grep -E '^### Step 0' skills/publish/SKILL.md && grep -qE 'branch.*current|git branch --show-current' skills/publish/SKILL.md
```

### AC-PUBLISH-AUTO-DETECT-2 — `tracker_needed` gate documented

```bash
grep -q 'tracker_needed' skills/publish/SKILL.md
```

### AC-PUBLISH-AUTO-DETECT-3 — Canonical issue-ID extraction regex present (v7.0.0 form)

The rewritten `skills/publish/SKILL.md` must reference the canonical issue-ID extraction regex `^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)` (or its Bash-form character classes), which extracts issue IDs for all 6 supported tracker shapes (youtrack/jira/linear `PROJ-123`, github/gitea/redmine `123` or `#42`). The v6.8.1 dot-only path-traversal defense (`^\.+$`) is preserved as a defensive secondary check; this AC verifies BOTH the canonical extraction regex AND the dot-only defense are documented.

```bash
grep -qE '\[A-Za-z\]\[A-Za-z0-9_\]\*-\[0-9\]\+' skills/publish/SKILL.md && grep -qE '#\?\[0-9\]\+|\[0-9\]\+' skills/publish/SKILL.md && grep -qE '\^\\\.\+\$|\^\.\+\$' skills/publish/SKILL.md
```

### AC-PUBLISH-AUTO-DETECT-4 — Five error_type buckets enumerated

```bash
grep -q '"tls"' skills/publish/SKILL.md && grep -q '"auth"' skills/publish/SKILL.md && grep -q '"not_found"' skills/publish/SKILL.md && grep -q '"timeout"' skills/publish/SKILL.md && grep -q '"unknown"' skills/publish/SKILL.md
```

### AC-PUBLISH-AUTO-DETECT-5 — `unknown → FAIL` defensive default present

```bash
grep -E 'unknown.*FAIL|unknown.*FAIL tier|unknown".*FAIL' skills/publish/SKILL.md
```

### AC-PUBLISH-AUTO-DETECT-6 — Three Tracker: row strings present in publisher agent

```bash
grep -q 'Tracker: Updated → For Review' agents/publisher.md && grep -q 'Tracker: Skipped — issue ID' agents/publisher.md && grep -q 'Tracker: Skipped — no issue ID in branch name' agents/publisher.md
```

### AC-PUBLISH-AUTO-DETECT-7 — FAIL tier uses CLAUDE.md Block Comment Template format

```bash
grep -q '\[ceos-agents\] 🔴 Pipeline Block' skills/publish/SKILL.md && grep -E 'Skill: /ceos-agents:publish' skills/publish/SKILL.md
```

### AC-PUBLISH-AUTO-DETECT-8 — Three-mode fork prose present

```bash
grep -q 'full-publish' skills/publish/SKILL.md && grep -q 'pr-only-no-id' skills/publish/SKILL.md && grep -q 'pr-only-404' skills/publish/SKILL.md
```

### AC-PUBLISH-AUTO-DETECT-9 — Citations to core/mcp-detection.md preserved

```bash
grep -q 'core/mcp-detection.md' skills/publish/SKILL.md
```

### AC-PUBLISH-AUTO-DETECT-10 — Operator note (interactive-only / autopilot-for-headless)

```bash
grep -E 'interactive-only|autopilot' skills/publish/SKILL.md | grep -q autopilot
```

### AC-PUBLISH-AUTO-DETECT-11 — Branch-rename escape hatch documented in FAIL tier

```bash
grep -E 'rename.*branch|chore/' skills/publish/SKILL.md | grep -q rename
```

### AC-PUBLISH-AUTO-DETECT-12 — SC-7 404 WARN message present (single line, key tokens)

Given the v7.0.0 head, the rewritten `skills/publish/SKILL.md` shall contain the SC-7 404 WARN message tokens on a single line. The line must include `[ceos-agents][WARN]`, the phrase `contains issue ID pattern`, the phrase `no matching ticket was found`, and `Creating PR without tracker update`. The grep is a single-line match (no `-A`/`-B` context), enforcing the single-line emission.

```bash
grep -qE '\[ceos-agents\]\[WARN\].*contains issue ID pattern.*no matching ticket was found.*Creating PR without tracker update' skills/publish/SKILL.md
```

### AC-PUBLISH-AUTO-DETECT-13 — SC-8 no-issue-id INFO message present (single line, key tokens)

```bash
grep -qE '\[ceos-agents\]\[INFO\].*does not match the configured Branch naming pattern.*Creating PR without tracker contact' skills/publish/SKILL.md
```

### AC-PUBLISH-AUTO-DETECT-14 — SC-10 missing Branch naming INFO message present

When `Branch naming` config key is absent, the skill emits a single-line INFO. Verifies the message text exists in the skill file.

```bash
grep -qE '\[ceos-agents\]\[INFO\].*No Branch naming pattern configured.*PR-only mode' skills/publish/SKILL.md
```

### AC-PUBLISH-AUTO-DETECT-15 — SC-12 detached HEAD FAIL guard present

The skill must explicitly handle detached HEAD with a single-line INFO and exit non-zero. Verifies the diagnostic text and the FAIL/exit semantics are present in the skill prose.

```bash
grep -qE 'detached HEAD' skills/publish/SKILL.md && grep -qE 'Cannot determine branch.*detached HEAD' skills/publish/SKILL.md
```

### AC-PUBLISH-AUTO-DETECT-EXTRACTION-1 — Canonical regex extracts `PROJ-123` from `PROJ-123-fix-crash`

The branch-parse algorithm in `skills/publish/SKILL.md` Step 0d must use the canonical issue-ID extraction regex `^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)`, NOT a "split at first delimiter" approach. The skill prose must contain a worked example demonstrating that for branch `fix/PROJ-123-fix-crash` and template `fix/{issue-id}-{description}` the extracted issue_id equals `PROJ-123` (NOT `PROJ` and NOT `PROJ-123-fix-crash`). This AC verifies (1) the worked example input/output is documented, and (2) the canonical regex (or the equivalent BASH_REMATCH-based extractor pattern) appears in the skill prose. The runtime semantic is independently verified by the embedded bash check.

```bash
grep -qE 'PROJ-123-fix-crash' skills/publish/SKILL.md && grep -qE 'PROJ-123\b' skills/publish/SKILL.md && grep -qE '\[A-Za-z\]\[A-Za-z0-9_\]\*-\[0-9\]\+|BASH_REMATCH|canonical.*extraction.*regex' skills/publish/SKILL.md && bash -c 'residue="PROJ-123-fix-crash"; [[ "$residue" =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ]] && [[ "${BASH_REMATCH[1]}" == "PROJ-123" ]]'
```

### AC-PUBLISH-AUTO-DETECT-EXTRACTION-2 — `feature/PROJ-456` (no description) → `PROJ-456`

The skill prose must document the no-description path: for branch `feature/PROJ-456` and template `feature/{issue-id}` (no `{description}`), the canonical extraction regex consumes only `PROJ-456`. AC verifies BOTH the input example AND the asserted output value are present, plus an independent runtime check of the regex semantics.

```bash
grep -qE 'feature/PROJ-456' skills/publish/SKILL.md && grep -qE 'PROJ-456' skills/publish/SKILL.md && bash -c 'residue="PROJ-456"; [[ "$residue" =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ]] && [[ "${BASH_REMATCH[1]}" == "PROJ-456" ]]'
```

### AC-PUBLISH-AUTO-DETECT-EXTRACTION-3 — Non-matching prefix → `issue_id = null`

The skill prose must document that branch names not starting with the configured prefix yield `issue_id = null` (or empty string) and proceed to `pr-only-no-id` mode without tracker contact. Worked example: branch `chore/refactor-foo` and template `fix/{issue-id}-{description}` → branch does NOT start with `fix/` → `issue_id = null`. The independent bash check verifies the prefix-strip step.

```bash
grep -qE 'chore/refactor-foo|does NOT start with' skills/publish/SKILL.md && grep -qE 'issue_id\s*=\s*null|issue_id = null|issue_id=""' skills/publish/SKILL.md && bash -c 'branch="chore/refactor-foo"; prefix="fix/"; case "$branch" in "$prefix"*) r="${branch#$prefix}";; *) r="";; esac; [ -z "$r" ]'
```

### AC-PUBLISH-AUTO-DETECT-EXTRACTION-4 — Numeric-only ID (github/gitea/redmine): `fix/123-numeric-id` → `123`

The canonical extraction regex must handle numeric-only issue IDs used by github/gitea/redmine. For branch `fix/123-numeric-id` and template `fix/{issue-id}-{description}`, the regex matches `123` (numeric branch), and the trailing `-numeric-id` is discarded.

```bash
bash -c 'residue="123-numeric-id"; [[ "$residue" =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ]] && [[ "${BASH_REMATCH[1]}" == "123" ]]'
```

### AC-PUBLISH-AUTO-DETECT-EXTRACTION-5 — Hash-prefixed ID (github/gitea/redmine): `fix/#42-fix` → `#42`

The canonical extraction regex must handle hash-prefixed numeric issue IDs (`#42`). For branch `fix/#42-fix` and template `fix/{issue-id}-{description}`, the regex matches `#42`, and the trailing `-fix` is discarded.

```bash
bash -c 'residue="#42-fix"; [[ "$residue" =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ]] && [[ "${BASH_REMATCH[1]}" == "#42" ]]'
```

### AC-PUBLISH-AUTO-DETECT-ZERO-COMMITS — Zero-commits early-stop documented

Step 3a of the rewritten skill must document the early-stop case where `git log {base_branch}..HEAD` returns zero commits. Verifies the diagnostic message is documented in the skill.

```bash
grep -qE 'No changes to publish|zero commits|no commits above' skills/publish/SKILL.md
```

---

## REQ-DEL-CREATE-PR

### AC-DEL-CREATE-PR-1 — `skills/create-pr/` does not exist

```bash
[ ! -d skills/create-pr ]
```

### AC-DEL-CREATE-PR-2 — No `ceos-agents:create-pr` references in active surfaces (workflow-router excluded)

The workflow-router file is excluded for the same reason as AC-RENAME-STATUS-4 / AC-RENAME-INIT-4 (design.md §5.3 deprecated-names prose). Workflow-router presence is positively verified by AC-DOCS-COLLISION-WARN-WORKFLOW-1.

```bash
[ "$(grep -rn 'ceos-agents:create-pr\b' --include='*.md' --exclude-dir=.forge --exclude-dir='.forge.bak-*' --exclude-dir=docs/plans --exclude-dir=docs/superpowers --exclude=CHANGELOG.md --exclude=skills/workflow-router/SKILL.md . | wc -l | tr -d ' ')" = "0" ]
```

### AC-DEL-CREATE-PR-3 — README does not list `/create-pr`

```bash
! grep -qE '^\| `/create-pr` \|' README.md
```

### AC-DEL-CREATE-PR-4 — `docs/reference/skills.md` does not have `### /create-pr` section

```bash
! grep -qE '^### /create-pr$' docs/reference/skills.md
```

### AC-DEL-CREATE-PR-5 — `docs/reference/automation-config.md` PR Rules row no longer mentions `/create-pr`

```bash
! grep -E '^\| PR Rules \|' docs/reference/automation-config.md | grep -q '/create-pr'
```

### AC-DEL-CREATE-PR-6 — `docs/reference/automation-config.md` PR Description Template row no longer mentions `/create-pr`

```bash
! grep -E '^\| PR Description Template \|' docs/reference/automation-config.md | grep -q '/create-pr'
```

### AC-DEL-CREATE-PR-7 — workflow-router intent table no longer has create-pr row (deprecated mention restricted to "Deprecated names" section)

The intent table row at line 15 must be deleted. The deprecated `ceos-agents:create-pr` form is allowed to remain ONLY inside the new "Deprecated names" section (design.md §5.3). The negative grep below scopes to the intent-table format and to the destructive-list prose at Step 4.

```bash
! grep -qE '^\| .*Create a pull request.*\| `ceos-agents:create-pr`' skills/workflow-router/SKILL.md && ! grep -qE 'IS destructive.*create-pr,' skills/workflow-router/SKILL.md
```

### AC-DEL-CREATE-PR-8 — workflow-router Step 4 destructive list no longer mentions `create-pr,`

```bash
! grep -E 'IS destructive.*create-pr,' skills/workflow-router/SKILL.md
```

### AC-DEL-CREATE-PR-9 — Test scenarios no longer reference skills/create-pr/SKILL.md

```bash
! grep -q 'skills/create-pr/SKILL.md' tests/scenarios/no-mcp-jargon-errors.sh
```

### AC-DEL-CREATE-PR-10 — `EXPECTED_SKILLS` array no longer contains `create-pr`

```bash
! grep -E '"create-pr"|^\s*create-pr$' tests/scenarios/skills-directory-structure.sh
```

### AC-DEL-CREATE-PR-11 — `PIPELINE_SKILLS` array no longer contains `create-pr`

```bash
! grep -E '"create-pr"' tests/scenarios/skills-frontmatter-check.sh
```

---

## REQ-DOCS-COLLISION-WARN

### AC-DOCS-COLLISION-WARN-1 — README has explicit H2/H3 collision subsection

Given the v7.0.0 head, when `README.md` is grepped, then a heading at H2 or H3 level mentioning "collision" / "slash command" / "builtin" exists, AND the collision warning prose names both new identifiers. The heading-level check ensures REQ compliance ("explicit subsection, not a passing prose mention").

```bash
grep -qE '^#{2,3} .*([Ss]lash.*[Cc]ommand|[Cc]ollision|[Bb]uiltin)' README.md && grep -qE 'collide.*Claude Code|builtin' README.md && grep -q '/ceos-agents:pipeline-status' README.md && grep -q '/ceos-agents:setup-mcp' README.md
```

### AC-DOCS-COLLISION-WARN-2 — installation.md has explicit H2/H3 collision subsection

```bash
grep -qE '^#{2,3} .*([Ss]lash.*[Cc]ommand|[Cc]ollision|[Bb]uiltin)' docs/guides/installation.md && grep -qE 'collide.*Claude Code|builtin' docs/guides/installation.md && grep -q '/ceos-agents:pipeline-status' docs/guides/installation.md && grep -q '/ceos-agents:setup-mcp' docs/guides/installation.md
```

### AC-DOCS-COLLISION-WARN-3 — workflow-router has "Did you mean...?" prose for 3 deprecated names

```bash
grep -q 'ceos-agents:status' skills/workflow-router/SKILL.md && grep -q 'ceos-agents:init' skills/workflow-router/SKILL.md && grep -q 'ceos-agents:create-pr' skills/workflow-router/SKILL.md && grep -E 'did you mean|deprecated' skills/workflow-router/SKILL.md
```

### AC-DOCS-COLLISION-WARN-WORKFLOW-1 — Positive workflow-router check (deprecated names ARE present)

This AC asserts that the workflow-router file POSITIVELY contains all 3 deprecated identifiers in its "Did you mean...?" prose (design.md §5.3). It is the inverse of AC-RENAME-STATUS-4 / AC-RENAME-INIT-4 / AC-DEL-CREATE-PR-2 (which exclude the workflow-router file from the global ban). At least 3 hits are required (one per deprecated identifier).

```bash
[ "$(grep -E '(ceos-agents:status|ceos-agents:init|ceos-agents:create-pr)' skills/workflow-router/SKILL.md | wc -l | tr -d ' ')" -ge "3" ]
```

**Workflow-router exclusion contract (RESOLVED in Phase 4):** AC-RENAME-STATUS-4, AC-RENAME-INIT-4, AC-DEL-CREATE-PR-2 all use `--exclude=skills/workflow-router/SKILL.md` because the deprecated-names prose at design.md §5.3 intentionally references the deprecated identifiers. AC-RENAME-STATUS-5 and AC-DEL-CREATE-PR-7 are tightened to scope the prohibition to specific intent-table / destructive-list contexts (NOT the deprecated-names section). Design.md §8.2 Phase 8 grep commands also use the same exclusion. AC-DOCS-COLLISION-WARN-WORKFLOW-1 positively verifies presence. There is no Phase 7 deferral; the AC commands above are the binding form.

---

## REQ-CHANGELOG-MIGRATION

### AC-CHANGELOG-MIGRATION-1 — `## [7.0.0]` section exists

```bash
grep -qE '^## \[7\.0\.0\]' CHANGELOG.md
```

### AC-CHANGELOG-MIGRATION-2 — Migration subsection present

```bash
grep -qE '^### Migration from v6\.10\.x to v7\.0\.0' CHANGELOG.md
```

### AC-CHANGELOG-MIGRATION-3 — All 5 migration bullets present (key tokens from each)

```bash
grep -qE 'Extra labels.*PR Rules' CHANGELOG.md && grep -qE 'pipeline-status' CHANGELOG.md && grep -qE 'setup-mcp' CHANGELOG.md && grep -qE '/create-pr.*removed' CHANGELOG.md && grep -qE 'Pause Limits.*pipeline skills' CHANGELOG.md
```

### AC-CHANGELOG-MIGRATION-4 — Lost-agency disclosure present

```bash
grep -qE 'Lost agency|opt out.*tracker|branch-rename workaround|non-matching branch' CHANGELOG.md
```

### AC-CHANGELOG-MIGRATION-5 — Skill-not-found disclosure present

```bash
grep -qE 'skill-not-found|standard skill-not-found|no aliasing' CHANGELOG.md
```

### AC-CHANGELOG-MIGRATION-6 — State.json forward-compat note present

```bash
grep -qE 'state\.json.*unchanged|forward-compat|in-flight pipelines' CHANGELOG.md
```

### AC-CHANGELOG-MIGRATION-7 — `/check-setup` deprecated-config detector present and exit-neutral

Given the v7.0.0 head, when `skills/check-setup/SKILL.md` is read, then it contains both the `Extra labels` deprecated detection block and the WARN-not-fail semantic. The exit-code semantic is asserted by the absence of any FAIL/exit-1 line tied to the `Extra labels` warning.

```bash
grep -qE 'Deprecated.*config|deprecated v6\.x' skills/check-setup/SKILL.md && grep -qE '\[WARN\].*Extra labels' skills/check-setup/SKILL.md && ! grep -E '\[WARN\].*Extra labels' skills/check-setup/SKILL.md | grep -qE 'exit 1|FAIL|fail\(\)|return 1'
```

---

## REQ-COUNTS

### AC-COUNTS-1 — CLAUDE.md "28 skills"

```bash
grep -qF '28 skills' CLAUDE.md && ! grep -qE '\b29 skills\b' CLAUDE.md
```

### AC-COUNTS-2 — CLAUDE.md "18 optional"

```bash
grep -qF '18 optional config sections in total' CLAUDE.md && ! grep -qF '19 optional config sections in total' CLAUDE.md
```

### AC-COUNTS-3 — README.md "28 skills" + "18 optional sections"

```bash
grep -qF '28 skills' README.md && ! grep -qE '\b29 skills\b' README.md && grep -qF '18 optional sections' README.md && ! grep -qE '\b19 optional sections\b' README.md
```

### AC-COUNTS-4 — docs/reference/skills.md "28 skills"

```bash
grep -qE 'all 28 skills' docs/reference/skills.md && ! grep -qE '\ball 29 skills\b' docs/reference/skills.md
```

### AC-COUNTS-5 — docs/reference/automation-config.md "18 optional sections"

```bash
grep -qF '18 optional sections' docs/reference/automation-config.md && ! grep -qE '\b19 optional sections\b' docs/reference/automation-config.md
```

### AC-COUNTS-6 — docs/architecture.md `SKL[28 Skills]` mermaid label

```bash
grep -qF 'SKL[28 Skills]' docs/architecture.md && ! grep -qF 'SKL[29 Skills]' docs/architecture.md
```

### AC-COUNTS-7 — docs/getting-started.md "all 28 skills"

```bash
grep -qF 'all 28 skills' docs/getting-started.md && ! grep -qF 'all 29 skills' docs/getting-started.md
```

### AC-COUNTS-8 — Filesystem skill count is 28

```bash
[ "$(find skills -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')" = "28" ]
```

### AC-COUNTS-9 — Agent count unchanged at 21

```bash
[ "$(find agents -maxdepth 1 -mindepth 1 -name '*.md' | wc -l | tr -d ' ')" = "21" ]
```

### AC-COUNTS-10 — No empty directories under skills/ (Phase 3 R8)

```bash
[ "$(find skills -maxdepth 1 -mindepth 1 -type d -empty | wc -l | tr -d ' ')" = "0" ]
```

---

## REQ-INVARIANTS

### AC-INVARIANTS-1 — License SPDX consistent (plugin.json + marketplace.json + LICENSE)

```bash
grep -q '"license": "MIT"' .claude-plugin/plugin.json && grep -q '"license": "MIT"' .claude-plugin/marketplace.json && head -1 LICENSE | grep -qF 'MIT License'
```

### AC-INVARIANTS-2 — Maintainer email consistent (SECURITY.md + CODE_OF_CONDUCT.md + CONTRIBUTING.md)

```bash
grep -q 'filip.sabacky@ceosdata.com' SECURITY.md && grep -q 'filip.sabacky@ceosdata.com' CODE_OF_CONDUCT.md && grep -q 'filip.sabacky@ceosdata.com' CONTRIBUTING.md
```

### AC-INVARIANTS-3 — Issue/PR templates byte-identical (.gitea ↔ .github)

```bash
diff -q .gitea/issue_template/bug_report.md .github/ISSUE_TEMPLATE/bug_report.md && diff -q .gitea/issue_template/feature_request.md .github/ISSUE_TEMPLATE/feature_request.md && diff -q .gitea/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md
```

---

## REQ-NO-VERSION-BUMP

### AC-NO-VERSION-BUMP-1 — plugin.json `version` not modified by pipeline

```bash
[ "$(git diff main -- .claude-plugin/plugin.json | grep -E '^[+-].*"version"' | wc -l | tr -d ' ')" = "0" ]
```

### AC-NO-VERSION-BUMP-2 — marketplace.json `version` not modified by pipeline

```bash
[ "$(git diff main -- .claude-plugin/marketplace.json | grep -E '^[+-].*"version"' | wc -l | tr -d ' ')" = "0" ]
```

### AC-NO-VERSION-BUMP-3 — No v7.0.0 git tag created

```bash
[ "$(git tag -l v7.0.0 | wc -l | tr -d ' ')" = "0" ]
```

---

## Test scenario inventory ACs (per Phase 2 Q8 classification)

### UPDATE scenarios — assert post-v7.0.0 expected exit code is 0 (PASS)

#### AC-TEST-INVENTORY-1 — `regression-skill-count-29.sh` updated

```bash
grep -E '\-ne 28' tests/scenarios/regression-skill-count-29.sh && ! grep -qE '\-ne 29' tests/scenarios/regression-skill-count-29.sh
```

#### AC-TEST-INVENTORY-2 — `ac-v68-doc-skill-count-29.sh` polarity flipped

```bash
grep -qF '28 skills' tests/scenarios/ac-v68-doc-skill-count-29.sh && grep -qF '29 skills' tests/scenarios/ac-v68-doc-skill-count-29.sh
```

(both strings present — positive looks for "28 skills", negative rejects "29 skills")

#### AC-TEST-INVENTORY-3 — `v6.9.0-doc-count-drift.sh` 6-edit DISAGREEMENT D resolution

All 6 mandated edits per design.md Section 7 must be reflected in the file. Edits enumerated:
1. Lines 42-45 (positive flip 19 → 18): `'18 optional config sections in total'` is the asserted positive string.
2. Lines 55-58 (negative flip 18 → 19): `'19 optional config sections in total'` is the asserted negative string (must be present in the negative branch).
3. Line 72: `-eq 28` (was `-eq 29`).
4. Line 79: `-eq 18` (was `-eq 19`).
5. Line 84 (fallback prose 19 → 18): subsumed by edit 1 (same string updated).
6. Line 89 (PASS message): `'18 optional, 28 skills'` (was `'19 optional, 29 skills'`).

```bash
grep -qF '18 optional config sections in total' tests/scenarios/v6.9.0-doc-count-drift.sh && grep -qF '19 optional config sections in total' tests/scenarios/v6.9.0-doc-count-drift.sh && grep -qE '\beq 28\b' tests/scenarios/v6.9.0-doc-count-drift.sh && grep -qE '\beq 18\b' tests/scenarios/v6.9.0-doc-count-drift.sh && grep -qE '18 optional, 28 skills' tests/scenarios/v6.9.0-doc-count-drift.sh && ! grep -qE '19 optional, 29 skills' tests/scenarios/v6.9.0-doc-count-drift.sh
```

#### AC-TEST-INVENTORY-4 — `skills-directory-structure.sh` array updated

```bash
! grep -qE '"create-pr"' tests/scenarios/skills-directory-structure.sh && grep -qE '"setup-mcp"' tests/scenarios/skills-directory-structure.sh && grep -qE '"pipeline-status"' tests/scenarios/skills-directory-structure.sh
```

#### AC-TEST-INVENTORY-5 — `skills-frontmatter-check.sh` arrays updated; FC-5 count 11

```bash
! grep -qE '"create-pr"' tests/scenarios/skills-frontmatter-check.sh && grep -qE '"setup-mcp"' tests/scenarios/skills-frontmatter-check.sh && grep -qE '"pipeline-status"' tests/scenarios/skills-frontmatter-check.sh && grep -qE '11 pipeline' tests/scenarios/skills-frontmatter-check.sh
```

#### AC-TEST-INVENTORY-6 — `no-mcp-jargon-errors.sh` paths updated

```bash
! grep -qF 'skills/create-pr/SKILL.md' tests/scenarios/no-mcp-jargon-errors.sh && grep -qF 'skills/pipeline-status/SKILL.md' tests/scenarios/no-mcp-jargon-errors.sh && ! grep -qF 'skills/status/SKILL.md' tests/scenarios/no-mcp-jargon-errors.sh
```

#### AC-TEST-INVENTORY-7 — `config-reader-sections.sh` array no longer has Extra labels

```bash
! grep -qF '"Extra labels"' tests/scenarios/config-reader-sections.sh
```

#### AC-TEST-INVENTORY-8 — `v6.9.0-bc-no-renamed-section.sh` array updated; mutation guard 18

```bash
! grep -qF '"Extra labels"' tests/scenarios/v6.9.0-bc-no-renamed-section.sh && grep -qE '\-eq 18' tests/scenarios/v6.9.0-bc-no-renamed-section.sh
```

#### AC-TEST-INVENTORY-9 — `v6.9.0-arch-freshness-refresh-on-release.sh` polarity flipped

```bash
grep -qF 'SKL[28 Skills]' tests/scenarios/v6.9.0-arch-freshness-refresh-on-release.sh && grep -qF 'SKL[29 Skills]' tests/scenarios/v6.9.0-arch-freshness-refresh-on-release.sh
```

#### AC-TEST-INVENTORY-10 — `scaffold-mcp-checkpoint.sh` path updated

```bash
grep -qF 'skills/setup-mcp/SKILL.md' tests/scenarios/scaffold-mcp-checkpoint.sh && ! grep -qF 'skills/init/SKILL.md' tests/scenarios/scaffold-mcp-checkpoint.sh
```

#### AC-TEST-INVENTORY-11 — `v6.10.0-dispatch-hook-install-surface.sh` path updated

```bash
grep -qF 'skills/setup-mcp/SKILL.md' tests/scenarios/v6.10.0-dispatch-hook-install-surface.sh && ! grep -qF 'skills/init/SKILL.md' tests/scenarios/v6.10.0-dispatch-hook-install-surface.sh
```

#### AC-TEST-INVENTORY-12 — `v644-diagnostics-hardening.sh` 6 paths updated

```bash
[ "$(grep -cF 'skills/setup-mcp/SKILL.md' tests/scenarios/v644-diagnostics-hardening.sh)" = "6" ] && ! grep -qF 'skills/init/SKILL.md' tests/scenarios/v644-diagnostics-hardening.sh
```

### NO-CHANGE scenarios — assert presence + content unchanged from v6.10.0

#### AC-TEST-INVENTORY-13 — `ac-v68-doc-optional-sections-18.sh` regex unchanged (still accepts 18)

```bash
grep -qE '\(18\\\|19\) optional|\(18\|19\) optional' tests/scenarios/ac-v68-doc-optional-sections-18.sh
```

#### AC-TEST-INVENTORY-14 — `xref-command-count.sh` exists and uses dynamic count

```bash
[ -f tests/scenarios/xref-command-count.sh ] && grep -qE 'find skills' tests/scenarios/xref-command-count.sh
```

#### AC-TEST-INVENTORY-15 — `v6.9.0-cross-file-invariants.sh` exists and tests license/email/template

```bash
[ -f tests/scenarios/v6.9.0-cross-file-invariants.sh ] && grep -qE 'MIT|filip\.sabacky|template' tests/scenarios/v6.9.0-cross-file-invariants.sh
```

---

## Summary

- **REQ count:** 11 (all derived from 6 spec actions + 2 cross-cutting + 3 governance)
- **AC count:** 79 functional ACs + 15 test-scenario-inventory ACs = **94 total ACs** (revised in Phase 4 round 2 after extraction-regex critical fix)
  - REQ-DEL-EXTRA-LABELS: 5
  - REQ-PAUSE-LIMITS-DOC: 2
  - REQ-RENAME-STATUS: 7
  - REQ-RENAME-INIT: 7
  - REQ-PUBLISH-AUTO-DETECT: 21 (was 19 in r1; +2 in revision-2: AC-EXTRACTION-4 numeric, AC-EXTRACTION-5 hash-prefixed)
  - REQ-DEL-CREATE-PR: 11
  - REQ-DOCS-COLLISION-WARN: 4 (was 3; +1 in revision-1: AC-DOCS-COLLISION-WARN-WORKFLOW-1 positive check)
  - REQ-CHANGELOG-MIGRATION: 7
  - REQ-COUNTS: 10
  - REQ-INVARIANTS: 3
  - REQ-NO-VERSION-BUMP: 3
  - Test scenario inventory: 15 (UPDATE+NO-CHANGE)
- **All ACs are bash one-liners** — zero "code review confirms" verifications.
- **Every REQ has at least 1 AC** (most have 3+).
- **Phase 8 verification commands** (design.md §8) can be run as-is alongside these ACs to produce a comprehensive Phase 8 report.
- **Phase 3 open questions** all resolved via REQs and design.md sections (resolution map in requirements.md).
- **Workflow-router exclusion contract** is RESOLVED in Phase 4 (no Phase-7 deferral) — see AC-DOCS-COLLISION-WARN-WORKFLOW-1 and the binding `--exclude=skills/workflow-router/SKILL.md` flags in AC-RENAME-STATUS-4 / AC-RENAME-INIT-4 / AC-DEL-CREATE-PR-2.
