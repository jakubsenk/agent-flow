# Step Override Example

This directory shows how to override a specific pipeline step in your consuming project, without forking the entire plugin.

## Use case

You want to customize ONE step in the `fix-bugs` pipeline without modifying the plugin itself.

## How to override

1. Identify the step file in plugin: `skills/fix-bugs/steps/04-fixer-reviewer-loop.md`
2. Create the override at: `customization/steps/fix-bugs/04-fixer-reviewer-loop.md`
3. Copy plugin content as starting point, then modify
4. The plugin will detect your override at dispatch time and use yours instead of the default
5. The plugin emits `[INFO] Step override active: customization/steps/fix-bugs/04-fixer-reviewer-loop.md` to .agent-flow/pipeline.log

## Naming convention

Override filenames MUST EXACTLY match plugin step filenames (case-sensitive, zero-padded).

Example WRONG: `customization/steps/fix-bugs/4-fixer-reviewer-loop.md` (missing zero-pad)
The plugin will emit `[WARN] Possible misnamed step override: customization/steps/fix-bugs/4-fixer-reviewer-loop.md — did you mean 04-fixer-reviewer-loop.md?`

## Override scope

Override REPLACES the entire step body. Insert/before/after semantics are not supported in v8.0.0.

## See also

- `docs/guides/steps-decomposition.md` — full guide
- `docs/guides/toml-overlay-syntax.md` — TOML overlay (different from step override)
