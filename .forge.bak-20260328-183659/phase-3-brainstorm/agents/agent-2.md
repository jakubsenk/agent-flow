# Agent 2 Brainstorm: The Architect — Plugin Ecosystem Reusability

**Position:** version-check should be a TEMPLATE that any plugin author can copy. The identifier should be derived from the command's own plugin metadata, not hardcoded.

---

## Addressing the Five Design Questions

### Q1: Where does version-check get its identity if it can't read CWD's plugin.json?

The command runs inside Claude Code's plugin execution environment. When Claude Code loads a plugin from the cache, every command and agent in that plugin is resolved relative to `installPath`. The command file itself lives at `{installPath}/commands/version-check.md`. Therefore:

**The command's own identity lives at `{installPath}/.claude-plugin/plugin.json`.**

But here is the fundamental tension: the command is a markdown file with no runtime API. It cannot call `__dirname` or inspect its own file path. It is executed by Claude Code as a prompt, and Claude Code does not inject an `$INSTALL_PATH` environment variable or any plugin-context metadata into the prompt.

**Resolution:** The command must use `installed_plugins.json` as both registry AND identity source. The approach:

1. Read `~/.claude/plugins/installed_plugins.json`.
2. Scan all entries. For each entry, check if its `installPath` contains a `.claude-plugin/plugin.json` whose `name` field matches the command's own plugin. But this is circular — we need the name to find the name.

**The honest answer:** In the current Claude Code architecture, a markdown command has no intrinsic way to discover which plugin it belongs to. The command MUST contain its own plugin name as a constant. The question is whether that constant is a hardcoded string scattered across 5+ locations, or a single clearly-marked declaration at the top of the file.

**Recommended pattern for template reusability:**

```markdown
## Plugin Identity

| Key | Value |
|-----|-------|
| Plugin name | ceos-agents |

All steps below use the Plugin name from this table.
```

A plugin author copying this template changes ONE value in ONE place. This is not runtime derivation, but it is the minimum viable genericity given the constraints of markdown-as-code.

### Q2: How to derive the `{plugin}@{marketplace}` identifier format?

The `installed_plugins.json` key format is `{plugin-name}@{marketplace-name}`. The marketplace name is NOT always identical to the plugin name — consider `superpowers@claude-plugins-official`.

Since the command cannot derive the marketplace name from any plugin-local file (neither `plugin.json` nor `marketplace.json` contains a self-referential "my marketplace key is X" field), the full identifier must also be declared:

```markdown
| Plugin identifier | ceos-agents@ceos-agents |
```

However, there is a pragmatic fallback: scan `installed_plugins.json` for any key that STARTS WITH `{plugin-name}@`. If exactly one match is found, use it. If zero or multiple matches are found, report the ambiguity.

**Recommended approach:** Declare plugin name only. Use prefix-scan of `installed_plugins.json` to find the full key. This reduces the template surface to a single name and handles marketplace name differences automatically.

### Q3: Should version-check accept an optional argument for plugin name?

**Yes, absolutely.** This is the single most impactful change for ecosystem reusability.

```
/ceos-agents:version-check              → checks ceos-agents (from Plugin Identity table)
/ceos-agents:version-check superpowers  → checks superpowers plugin
```

The argument overrides the Plugin Identity declaration. This means:
- The zero-argument case is convenient for checking the plugin that provides the command.
- The one-argument case makes it a general-purpose plugin health checker.
- Any plugin author who copies this template gets both behaviors for free.

### Q4: How to make the legacy cleanup step generic (or remove it)?

**Remove it entirely from the template.** Legacy cleanup (checking for `CLAUDE-agents` directory) is a personal migration artifact from one specific author's rename history. It has zero relevance to any other plugin and actively confuses the command's purpose.

If the author wants to keep it for the ceos-agents-specific version, add it as a separate section clearly marked as non-template:

```markdown
### Part C: ceos-agents-Specific Cleanup (NOT part of the generic template)
```

For a truly generic template, Part C should instead be: **Orphaned Cache Cleanup** — scan `~/.claude/plugins/cache/{marketplace}/{plugin}/` for version directories that do NOT match the `installPath` in `installed_plugins.json`. Report them as "orphaned snapshots, safe to delete." This is universally useful for ALL plugins.

### Q5: How to handle the `repository` field being absent?

**Graceful degradation with explicit messaging.** The research (phase 2) confirmed that `repository` is present only for true git-repo plugins, not MCP wrappers or Anthropic internal plugins.

When `repository` is absent:
1. Skip the remote version comparison entirely.
2. Report: "Remote version check skipped — no `repository` field in plugin.json. The installed version is {installed_version}."
3. Do NOT fall back to any hardcoded URL. Ever.

This means the command output has two modes:
- **Full mode** (repository present): installed vs remote vs repo comparison.
- **Reduced mode** (repository absent): installed version only, with repo comparison if CWD matches.

---

## Top 3 Risks

### Risk 1: The Identity Bootstrap Problem (Severity: HIGH)

**What:** A markdown command has no runtime introspection. It cannot programmatically discover which plugin it belongs to. Any "derivation" approach ultimately requires either (a) a hardcoded constant somewhere in the file, or (b) Claude Code injecting plugin context into the execution environment — which it does not do today.

**Impact:** If the template says "derive your identity," and the mechanism is fragile (e.g., relies on CWD, or on scanning installed_plugins.json with heuristics), it will silently produce wrong results when the user has multiple plugins with similar names, or when run from unexpected directories.

**Mitigation:** Accept the constraint. Use a single, clearly-marked Plugin Identity table at the top of the command. Document that plugin authors MUST update this table when copying the template. This is explicit, auditable, and cannot silently break.

### Risk 2: Prefix-Scan Collision in installed_plugins.json (Severity: MEDIUM)

**What:** The proposed prefix-scan approach (`{name}@*`) to find the full identifier can collide. Consider: a plugin named `agent` would match `agent@marketplace-a` AND `agent-pro@marketplace-b` if the scan is naive. Even an exact prefix scan (`agent@`) could match multiple entries if the same plugin name is registered under different marketplaces.

**Impact:** The command reports the wrong plugin's version, or errors out with an ambiguity message when the user expected a clean result.

**Mitigation:** The scan must use exact prefix `{name}@` (not substring). If multiple matches are found, list them all and ask the user to specify the full identifier. The optional argument (Q3) becomes the escape hatch.

### Risk 3: Version String Comparison is Undefined in Markdown (Severity: MEDIUM)

**What:** The current command says "compare" installed_version and remote_version using `<`, `==`, `>` — but these are string comparisons. `"5.10.0" < "5.9.0"` lexicographically. The command relies on Claude's LLM reasoning to do semver comparison correctly, which is probabilistic, not deterministic.

**Impact:** The command reports "up to date" when an update is available, or "update available" when the installed version is actually newer. This is especially dangerous for a version-check command whose entire purpose is accurate version reporting.

**Mitigation:** The command must include an explicit bash step for version comparison:
```bash
printf '%s\n' "$installed_version" "$remote_version" | sort -V | head -1
```
If the output equals `$installed_version` and the two are not equal, then remote is newer. This delegates comparison to `sort -V` (GNU coreutils), which handles semver correctly.

---

## Recommended Approach

### Structure: Single Plugin Identity Declaration + Optional Argument Override + Bash-Based Semver

```markdown
---
description: Compares installed plugin version with the latest available
allowed-tools: Read, Bash
---

# Version Check

## Plugin Identity

| Key | Value |
|-----|-------|
| Plugin name | ceos-agents |

> Template authors: change the Plugin name above to match your plugin's
> `name` field in `.claude-plugin/plugin.json`. All steps below reference
> this value automatically.

## Input

Optional argument: `[plugin-name]` — overrides Plugin Identity for checking
a different installed plugin. Example: `/ceos-agents:version-check superpowers`

## Steps

### Step 0: Resolve Plugin Name

- If an argument was provided, use it as `plugin_name`.
- Otherwise, use the Plugin name from the Plugin Identity table above.

### Part A: Installed Plugin Status (always runs)

1. Read `~/.claude/plugins/installed_plugins.json`.
   - If file does not exist → report "Claude Code plugin registry not found"
     and STOP.
   - Scan all keys for entries starting with `{plugin_name}@`.
   - If zero matches → report "{plugin_name} is not installed" and STOP.
   - If multiple matches → list them and ask user to re-run with full
     identifier.
   - Extract `version` and `installPath`. Store as `installed_version`.

2. Verify installPath exists on disk.

3. Determine remote version:
   - Read `repository` from `{installPath}/.claude-plugin/plugin.json`.
   - If absent → report "Remote check skipped — no repository field" and
     skip to step 4.
   - Run: git ls-remote --tags {repo} 'refs/tags/v*' | grep -v '\^{}' |
     sort -t/ -k3 -V | tail -1
   - Extract version. Store as `remote_version`.

4. Compare using bash sort -V, not string comparison.

### Part B: Repo Comparison (conditional)

5. Check if `.claude-plugin/plugin.json` exists in CWD.
   - If yes, read its `name` field.
   - If name does NOT match `plugin_name` → skip Part B.
   - If name matches → compare repo version with installed version.

### Part C: (removed from generic template)
```

This approach:
- Fixes all 9 defects from the research (DEF-1 through DEF-9).
- Is copyable by any plugin author with a single-field change.
- Handles the absent-repository case gracefully.
- Uses deterministic bash-based semver comparison.
- Eliminates all hardcoded URLs and legacy cleanup.

---

## One Thing the Current Fix Missed

**The `installed_plugins.json` might not exist at all.**

The current command (and the v5.5.1 fix that was applied) assumes `~/.claude/plugins/installed_plugins.json` always exists. It does not guard against the file being absent — which happens on a fresh Claude Code installation before any plugin is installed, or if the user has a non-standard `$HOME`. DEF-3 in the research flagged this as P0, but the current command has no guard for it.

The command should start with an existence check:
```
1. Read `~/.claude/plugins/installed_plugins.json`.
   - If file does not exist → report "Claude Code plugin registry not found
     at ~/.claude/plugins/installed_plugins.json — is Claude Code installed
     and has at least one plugin been installed?" and STOP.
```

This is a silent failure mode: without the guard, the Read tool returns an error, Claude tries to interpret the error message as JSON, and produces unpredictable output — sometimes hallucinating a version number from the error text. For a command whose purpose is deterministic version reporting, this is unacceptable.
