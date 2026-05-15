# Step 04 — Fixer ↔ Reviewer Loop (project override example)
#
# HOW TO USE THIS EXAMPLE:
# Copy to: customization/steps/fix-bugs/04-fixer-reviewer-loop.md
# The plugin will use this file instead of its default step 04 for every fix-bugs run.
#
# This override REPLACES the entire step. Start by copying the full default step from:
#   skills/fix-bugs/steps/04-fixer-reviewer-loop.md
# then add your project-specific changes below.
#
# This example adds ONE project-specific constraint to the reviewer role.
# Everything else follows the standard plugin protocol (see core/fixer-reviewer-loop.md).

Follow the standard fixer ↔ reviewer loop protocol from `../../../core/fixer-reviewer-loop.md`.

## Project-specific reviewer constraint

The reviewer MUST write all comments and the final verdict in **Czech**.
This is a project requirement — English-only PRs are not accepted by this team.

All other reviewer behavior (AC fulfillment check, APPROVED / REQUEST_CHANGES verdict,
block conditions, state.json writes) follows the plugin default.
