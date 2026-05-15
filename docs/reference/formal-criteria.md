# Formal Criteria — Mode and Step Decomposition

This document specifies machine-checkable acceptance criteria for
mode selection (`--yolo` / default / `--step-mode`) and step decomposition
behaviors. Each AC is referenced by harness scenarios in `tests/scenarios/`.

---

## Step-mode escape switch

WHEN a pipeline running in `--step-mode` receives an escape command (user enters
`y` or `yolo` at any step prompt),
THEN the runtime SHALL log `[INFO] step-mode escape: switched to yolo for remaining steps`,
AND the pipeline SHALL continue without further per-step prompts (yolo behavior
for all remaining steps).

```bash
# Verify the contract message is documented in fix-bugs/SKILL.md
grep -qE 'step-mode escape|switched.*yolo|yolo.*remaining' skills/fix-bugs/SKILL.md
```

Verifying scenarios: (none currently active)

---

## Vague-description heuristic: brainstorm skipped for long technical descriptions

WHEN the scaffold description has word_count >= 20 AND contains at least one technical term,
THEN brainstorm SHALL be skipped automatically (description is classified as non-vague),
AND the pipeline SHALL proceed directly to spec-writer without asking for more details.

```bash
# Verify scaffold SKILL.md documents the heuristic thresholds
grep -qiE 'word.count.*20.*technical|>=.*20.*AND|technical.*>=.*20' skills/scaffold/SKILL.md
```

Verifying scenarios: (none currently active)

Source-of-truth substance: `skills/scaffold/SKILL.md:72-74` —
> "brainstorm triggers only for vague descriptions (heuristic: word count < 20 OR no technical term detected)... Long technical descriptions (>=20 words AND technical terms) skip brainstorm automatically."

---

## Override body REPLACES default step (replace-only semantics)

WHEN `customization/steps/fix-bugs/04-fixer-reviewer-loop.md` exists with content "OVERRIDE BODY MARKER 12345",
THEN the dispatched fixer-reviewer prompt SHALL contain ONLY the OVERRIDE BODY content.
The plugin-default step body SHALL NOT be present — the override replaces the default step
entirely. No merge, no append, no partial patch.

This is a **replace-only** contract: the OVERRIDE BODY is the complete step content; the
plugin default step file (`skills/fix-bugs/steps/04-fixer-reviewer-loop.md`) is bypassed
entirely when the override file is present.

```bash
# Verify design.md §4.2 documents replace-only semantics
grep -qiE 'replace.only|override.*replace|replaces.*default|replace.*default.*step' \
  docs/reference/pipeline.md
```

Verifying scenarios: (none currently active)
