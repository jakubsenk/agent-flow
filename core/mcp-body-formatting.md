# MCP Body Formatting

## Purpose

Prevent literal `\n` escape sequences from appearing in MCP tool parameters that accept
multi-line text. MCP tools receive parameter values as-is from the calling model --
escaped sequences like `\n` are rendered as the literal two-character sequence backslash-n,
not as actual newlines. This contract defines the required construction pattern.

## Applies To

All MCP tool calls where the parameter value contains multi-line content:
- PR description body (source control MCP: create_pull_request, create_pr)
- Issue comment body (tracker MCP: create_comment, add_comment)
- Issue/card description body (tracker MCP: create_issue, update_issue)
- Block comment fields (pipeline block protocol)
- Sub-issue description body (decomposition subtask creation)

## Process

1. Construct all multi-line strings with actual line breaks (real newlines in the source text).
2. Never interpolate or concatenate the string literal `\n` as a line separator.
3. Verify the constructed string contains Unicode U+000A newline characters between lines, not escape sequences.

## Constraints

- NEVER use `\n` as a line separator in any MCP parameter value
- NEVER concatenate field values with the string `"\n"` -- use actual newlines
- NEVER interpolate `\n` inside template strings passed to MCP tools

## Failure Mode

There is no runtime failure -- the MCP tool accepts the parameter and creates the
issue/comment/PR. The failure is visual: multi-line content appears as a single line
with literal `\n` characters visible to end users in the issue tracker or source control UI.
