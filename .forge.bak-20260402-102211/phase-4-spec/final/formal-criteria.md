# Formal Criteria: Commands-to-Skills Migration (v6.0.0)

Machine-checkable acceptance criteria. Each criterion includes the exact shell command to verify it.

---

## FC-1: `commands/` directory does not exist

```bash
[ ! -d "$REPO_ROOT/commands" ] && echo "PASS" || echo "FAIL"
```

---

## FC-2: `skills/` contains exactly 26 directories (25 migrated + workflow-router)

```bash
count=$(find "$REPO_ROOT/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)
[ "$count" -eq 26 ] && echo "PASS: $count skill directories" || echo "FAIL: expected 26, found $count"
```

The 26 directories are:
1. analyze-bug
2. changelog
3. check-deploy
4. check-setup
5. create-pr
6. dashboard
7. discuss
8. estimate
9. fix-bugs
10. fix-ticket
11. implement-feature
12. init
13. metrics
14. migrate-config
15. onboard
16. prioritize
17. publish
18. resume-ticket
19. scaffold
20. scaffold-add
21. scaffold-validate
22. status
23. template
24. version-bump
25. version-check
26. workflow-router

---

## FC-3: Each skill directory contains exactly 1 file named `SKILL.md`

```bash
FAIL=0
for dir in "$REPO_ROOT/skills"/*/; do
  count=$(find "$dir" -maxdepth 1 -name "SKILL.md" | wc -l)
  if [ "$count" -ne 1 ]; then
    echo "FAIL: $(basename "$dir") has $count SKILL.md files"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "PASS" || echo "FAIL"
```

---

## FC-4: Every SKILL.md has `name:` and `description:` in frontmatter

```bash
FAIL=0
for f in "$REPO_ROOT/skills"/*/SKILL.md; do
  if ! grep -q "^name:" "$f"; then
    echo "FAIL: $f missing name:"
    FAIL=1
  fi
  if ! grep -q "^description:" "$f"; then
    echo "FAIL: $f missing description:"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "PASS" || echo "FAIL"
```

---

## FC-5: 14 pipeline skills have `disable-model-invocation: true`

```bash
PIPELINE=(
  fix-ticket fix-bugs implement-feature scaffold publish create-pr
  onboard init scaffold-add check-deploy resume-ticket changelog
  version-bump migrate-config
)
FAIL=0
for skill in "${PIPELINE[@]}"; do
  f="$REPO_ROOT/skills/$skill/SKILL.md"
  if ! grep -q "^disable-model-invocation: true" "$f"; then
    echo "FAIL: $skill missing disable-model-invocation: true"
    FAIL=1
  fi
done
count=0
for skill in "${PIPELINE[@]}"; do
  f="$REPO_ROOT/skills/$skill/SKILL.md"
  grep -q "^disable-model-invocation: true" "$f" && ((count++))
done
[ "$count" -eq 14 ] && echo "PASS: $count pipeline skills with disable-model-invocation" || echo "FAIL: expected 14, found $count"
```

---

## FC-6: 11 read-only skills do NOT have `disable-model-invocation: true`

```bash
READONLY=(
  analyze-bug check-setup status dashboard metrics estimate
  prioritize template scaffold-validate version-check discuss
)
FAIL=0
for skill in "${READONLY[@]}"; do
  f="$REPO_ROOT/skills/$skill/SKILL.md"
  if grep -q "disable-model-invocation" "$f"; then
    echo "FAIL: $skill has disable-model-invocation but should not"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "PASS: 11 read-only skills without disable-model-invocation" || echo "FAIL"
```

---

## FC-7: No file in the repo contains `commands/` as a functional path (excluding CHANGELOG.md and docs/plans/)

"Functional path" means a reference used at runtime or in tests to locate a file. Historical references in CHANGELOG.md and architecture decision records in docs/plans/ are excluded.

```bash
matches=$(grep -r "commands/" "$REPO_ROOT" \
  --include="*.sh" --include="*.md" \
  -l \
  2>/dev/null \
  | grep -v "CHANGELOG.md" \
  | grep -v "docs/plans/" \
  | grep -v ".forge/" \
  | grep -v ".git/" \
  || true)
[ -z "$matches" ] && echo "PASS" || echo "FAIL: functional commands/ references remain in: $matches"
```

---

## FC-8: `./tests/harness/run-tests.sh` passes (all 37+ scenarios)

```bash
cd "$REPO_ROOT" && bash ./tests/harness/run-tests.sh
# Exit code 0 = PASS, non-zero = FAIL
```

Expected: 38 scenarios (37 existing + 1 new `skill-frontmatter.sh`), all PASS.

---

## FC-9: `plugin.json` version is `6.0.0`

```bash
version=$(grep '"version"' "$REPO_ROOT/.claude-plugin/plugin.json" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
[ "$version" = "6.0.0" ] && echo "PASS" || echo "FAIL: version is $version"
```

---

## FC-10: `marketplace.json` version is `6.0.0`

```bash
version=$(grep '"version"' "$REPO_ROOT/.claude-plugin/marketplace.json" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
[ "$version" = "6.0.0" ] && echo "PASS" || echo "FAIL: version is $version"
```

---

## Summary Table

| ID | Criterion | Automated? |
|----|-----------|-----------|
| FC-1 | `commands/` directory does not exist | Yes -- `[ ! -d ]` |
| FC-2 | `skills/` contains exactly 26 directories | Yes -- `find \| wc` |
| FC-3 | Each skill directory has exactly 1 SKILL.md | Yes -- `find \| wc` per dir |
| FC-4 | Every SKILL.md has `name:` and `description:` | Yes -- `grep` |
| FC-5 | 14 pipeline skills have `disable-model-invocation: true` | Yes -- `grep` |
| FC-6 | 11 read-only skills do NOT have `disable-model-invocation` | Yes -- `grep` |
| FC-7 | No functional `commands/` references (excl. CHANGELOG, plans) | Yes -- `grep -r` |
| FC-8 | Test harness passes (38 scenarios) | Yes -- `run-tests.sh` |
| FC-9 | `plugin.json` version is `6.0.0` | Yes -- `grep` |
| FC-10 | `marketplace.json` version is `6.0.0` | Yes -- `grep` |

All 10 criteria are machine-verifiable. An executor can run these checks after completing the migration to confirm completeness.
