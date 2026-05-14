#!/usr/bin/env bash
# TOML overlay 3-tier merge utility for agent-flow
#
# Usage (sourcing):
#   source skills/setup-agents/lib/toml-merge.sh
#
#   # Parse overlay:
#   json=$(parse_toml_overlay "customization/reviewer.toml") || exit 1
#
#   # Apply merge:
#   merged_json=$(apply_3tier_merge "$defaults_json" "$json")
#
#   # Validate overlay keys for agent 'reviewer':
#   validate_overlay_keys "$json" "reviewer" "customization/reviewer.toml" || exit 1
#
#   # Log provenance:
#   log_overlay_provenance "reviewer" "toml" "customization/reviewer.toml"
#
# Requirements:
#   - python3 (3.11+) must be available on PATH for TOML parsing (tomllib stdlib).
#   - POSIX bash; no GNU-only extensions used (compatible with bash 3.2, Git Bash, BusyBox).
#
# Provenance log destination: .agent-flow/pipeline.log (append mode).

set -euo pipefail

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# _toml_merge_error: emit [ERROR] to stderr and return non-zero.
_toml_merge_error() {
    printf '[ERROR] %s\n' "$*" >&2
    return 1
}

# _toml_merge_warn: emit [WARN] to stderr (advisory, continues).
_toml_merge_warn() {
    printf '[WARN] %s\n' "$*" >&2
}

# _require_python3: check python3 availability; emit [ERROR] and return 1 if absent.
_require_python3() {
    if ! command -v python3 >/dev/null 2>&1; then
        _toml_merge_error "python3 required for TOML parsing. Install Python 3.11+ and retry."
        return 1
    fi
}

# ---------------------------------------------------------------------------
# parse_toml_overlay
#
# Parse a TOML overlay file and output its contents as a JSON string on stdout.
# Uses python3 tomllib (Python 3.11+ stdlib).
#
# Arguments:
#   $1  — absolute or relative path to the .toml file
#
# Outputs:
#   JSON object on stdout (keys match TOML keys; arrays of tables become JSON arrays)
#
# Errors:
#   Returns 1 on:
#     - python3 not available
#     - file does not exist or is not readable
#     - TOML 1.0 syntax error in the file
#   Error messages include the file path and, where available, the line number.
# ---------------------------------------------------------------------------
parse_toml_overlay() {
    local file="$1"
    _require_python3 || return 1

    if [ ! -f "$file" ]; then
        _toml_merge_error "TOML overlay file not found: ${file}"
        return 1
    fi
    if [ ! -r "$file" ]; then
        _toml_merge_error "TOML overlay file not readable: ${file}"
        return 1
    fi

    # Use python3 tomllib (3.11+ stdlib). Emit JSON; include line number in error if available.
    python3 - "$file" <<'PYEOF'
import sys, json

file_path = sys.argv[1]

try:
    import tomllib
except ImportError:
    # Python < 3.11 — try tomli (third-party backport)
    try:
        import tomli as tomllib
    except ImportError:
        sys.stderr.write(
            "[ERROR] python3 tomllib not available. Requires Python 3.11+ or pip install tomli.\n"
        )
        sys.exit(1)

try:
    with open(file_path, "rb") as fh:
        data = tomllib.load(fh)
    print(json.dumps(data))
except tomllib.TOMLDecodeError as exc:
    # Include line number if present in exception message
    msg = str(exc)
    sys.stderr.write(
        f"[ERROR] TOML overlay validation failed: syntax error in {file_path}: {msg}\n"
    )
    sys.exit(1)
except OSError as exc:
    sys.stderr.write(f"[ERROR] Cannot read TOML overlay file {file_path}: {exc}\n")
    sys.exit(1)
PYEOF
}

# ---------------------------------------------------------------------------
# apply_3tier_merge
#
# Apply 3-tier merge semantics to combine plugin defaults with
# a TOML overlay. Both arguments are JSON objects (as produced by parse_toml_overlay
# or a plugin-defaults JSON builder).
#
# Merge rules:
#   Tier 1 — scalar keys (model, style): overlay value wins; plugin default discarded.
#   Tier 2 — array of tables ([[process_additions]], [[constraints]]): plugin-default
#             entries appear BEFORE project additions (append semantics; order preserved).
#   Tier 3 — tables ([limits]): key-by-key union; overlay key wins; absent keys
#             inherited from plugin default. Recursive into nested tables.
#   [meta]  — free-form table; overlay value replaces plugin default in full (no deep-merge
#             validation applied).
#
# Arguments:
#   $1  — plugin_defaults_json  (JSON string)
#   $2  — overlay_json          (JSON string, output of parse_toml_overlay)
#
# Outputs:
#   Merged JSON object on stdout.
#
# Errors:
#   Returns 1 if python3 unavailable or JSON is malformed.
# ---------------------------------------------------------------------------
apply_3tier_merge() {
    local plugin_defaults_json="$1"
    local overlay_json="$2"
    _require_python3 || return 1

    python3 - "$plugin_defaults_json" "$overlay_json" <<'PYEOF'
import sys, json

defaults = json.loads(sys.argv[1])
overlay  = json.loads(sys.argv[2])

# Tier 2 array-of-tables keys (append semantics)
ARRAY_APPEND_KEYS = {"process_additions", "constraints"}

# Tier 3 table keys (deep-merge semantics)
TABLE_DEEP_MERGE_KEYS = {"limits"}

def deep_merge_tables(base, overlay):
    """Recursively merge overlay dict into base dict (overlay wins per key)."""
    result = dict(base)
    for k, v in overlay.items():
        if k in result and isinstance(result[k], dict) and isinstance(v, dict):
            result[k] = deep_merge_tables(result[k], v)
        else:
            result[k] = v
    return result

merged = dict(defaults)

for key, value in overlay.items():
    if key in ARRAY_APPEND_KEYS:
        # Tier 2: append overlay entries AFTER plugin defaults
        base_list = defaults.get(key, [])
        if not isinstance(base_list, list):
            base_list = []
        if not isinstance(value, list):
            value = []
        merged[key] = base_list + value
    elif key in TABLE_DEEP_MERGE_KEYS:
        # Tier 3: deep merge tables; absent keys inherited from default
        base_table = defaults.get(key, {})
        if not isinstance(base_table, dict):
            base_table = {}
        if not isinstance(value, dict):
            value = {}
        merged[key] = deep_merge_tables(base_table, value)
    else:
        # Tier 1: scalar override (or [meta] free-form — overlay wins entirely)
        merged[key] = value

print(json.dumps(merged))
PYEOF
}

# ---------------------------------------------------------------------------
# validate_overlay_keys
#
# Validate that all keys in a parsed overlay JSON are in the allowed set for
# the given agent. Halts with [ERROR] and returns 1 on first
# unknown key. [meta] sub-keys are EXEMPT from validation.
#
# Arguments:
#   $1  — overlay_json     (JSON string, output of parse_toml_overlay)
#   $2  — agent_name       (e.g., "reviewer")
#   $3  — overlay_path     (file path, for error messages)
#
# Known allowed top-level keys for ALL agents:
#   model, style, process_additions, constraints, limits, meta
#
# Known allowed sub-keys in [[process_additions]] entries:
#   step, instruction
#
# Known allowed sub-keys in [[constraints]] entries:
#   rule
#
# [limits] allowed keys are agent-specific but this function validates the
# shared superset. Phase 8 verification can layer agent-specific checks.
#
# Errors:
#   Returns 1 on unknown key; writes [ERROR] to stderr.
# ---------------------------------------------------------------------------
validate_overlay_keys() {
    local overlay_json="$1"
    local agent_name="$2"
    local overlay_path="$3"
    _require_python3 || return 1

    python3 - "$overlay_json" "$agent_name" "$overlay_path" <<'PYEOF'
import sys, json

overlay      = json.loads(sys.argv[1])
agent_name   = sys.argv[2]
overlay_path = sys.argv[3]

# Allowed top-level keys for all agents
ALLOWED_TOP_LEVEL = {
    "model", "style",
    "process_additions",  # [[process_additions]] — TOML array of tables
    "constraints",        # [[constraints]] — TOML array of tables
    "limits",             # [limits] — TOML table (deep-merge)
    "meta",               # [meta] — free-form table, sub-keys EXEMPT
}

# Allowed sub-keys inside each [[process_additions]] entry
ALLOWED_PROCESS_ADDITION_KEYS = {"step", "instruction"}

# Allowed sub-keys inside each [[constraints]] entry
ALLOWED_CONSTRAINT_KEYS = {"rule"}

# Superset of allowed [limits] keys across all agents
# (agent-specific enforcement is a future enhancement)
ALLOWED_LIMITS_KEYS = {
    "max_review_iterations", "max_diff_lines", "max_iterations",
    "max_test_attempts", "max_build_retries", "max_spec_iterations",
    "max_root_cause_iterations", "max_files_reported", "max_decomposition_depth",
    "max_pr_retries", "max_pages", "exploration_max_clicks",
    "ac_threshold", "complexity_threshold", "test_framework",
}

errors = []

for key in overlay:
    if key not in ALLOWED_TOP_LEVEL:
        errors.append(
            f"[ERROR] TOML overlay validation failed for {agent_name}: "
            f"unknown key '{key}' (file: {overlay_path})"
        )

# Validate [[process_additions]] entries
if "process_additions" in overlay:
    entries = overlay["process_additions"]
    if not isinstance(entries, list):
        errors.append(
            f"[ERROR] TOML overlay validation failed for {agent_name}: "
            f"[[process_additions]] must be an array of tables (file: {overlay_path})"
        )
    else:
        for i, entry in enumerate(entries):
            if not isinstance(entry, dict):
                continue
            for k in entry:
                if k not in ALLOWED_PROCESS_ADDITION_KEYS:
                    errors.append(
                        f"[ERROR] TOML overlay validation failed for {agent_name}: "
                        f"unknown key '{k}' in [[process_additions]] entry {i+1} (file: {overlay_path})"
                    )
            if "step" not in entry:
                errors.append(
                    f"[ERROR] TOML overlay validation failed for {agent_name}: "
                    f"[[process_additions]] entry {i+1} missing required key 'step' (file: {overlay_path})"
                )
            if "instruction" not in entry:
                errors.append(
                    f"[ERROR] TOML overlay validation failed for {agent_name}: "
                    f"[[process_additions]] entry {i+1} missing required key 'instruction' (file: {overlay_path})"
                )

# Validate [[constraints]] entries
if "constraints" in overlay:
    entries = overlay["constraints"]
    if not isinstance(entries, list):
        errors.append(
            f"[ERROR] TOML overlay validation failed for {agent_name}: "
            f"[[constraints]] must be an array of tables (file: {overlay_path})"
        )
    else:
        for i, entry in enumerate(entries):
            if not isinstance(entry, dict):
                continue
            for k in entry:
                if k not in ALLOWED_CONSTRAINT_KEYS:
                    errors.append(
                        f"[ERROR] TOML overlay validation failed for {agent_name}: "
                        f"unknown key '{k}' in [[constraints]] entry {i+1} (file: {overlay_path})"
                    )
            if "rule" not in entry:
                errors.append(
                    f"[ERROR] TOML overlay validation failed for {agent_name}: "
                    f"[[constraints]] entry {i+1} missing required key 'rule' (file: {overlay_path})"
                )

# Validate [limits] keys (sub-keys of [meta] are EXEMPT — not checked)
if "limits" in overlay:
    limits_table = overlay["limits"]
    if not isinstance(limits_table, dict):
        errors.append(
            f"[ERROR] TOML overlay validation failed for {agent_name}: "
            f"[limits] must be a table (file: {overlay_path})"
        )
    else:
        for k in limits_table:
            if k not in ALLOWED_LIMITS_KEYS:
                errors.append(
                    f"[ERROR] TOML overlay validation failed for {agent_name}: "
                    f"unknown key '{k}' in [limits] (file: {overlay_path})"
                )

if errors:
    for err in errors:
        sys.stderr.write(err + "\n")
    sys.exit(1)
PYEOF
}

# ---------------------------------------------------------------------------
# log_overlay_provenance
#
# Emit a provenance log line to .agent-flow/pipeline.log (append mode) and
# to stderr as [INFO] for visibility.
#
# Format: agent={name} overlay_source={toml|md|none} overlay_path={path}
#
# Written exactly once per agent dispatch (called by dispatching skill).
# All three branches (toml / md / none) MUST call this function.
#
# Arguments:
#   $1  — agent_name    (e.g., "reviewer")
#   $2  — source_type   (one of: toml | md | none)
#   $3  — source_path   (file path, or "(none)" when source_type=none)
#
# Log destination: .agent-flow/pipeline.log (relative to project root / CWD).
# ---------------------------------------------------------------------------
log_overlay_provenance() {
    local agent_name="$1"
    local source_type="$2"
    local source_path="$3"

    local log_line="agent=${agent_name} overlay_source=${source_type} overlay_path=${source_path}"
    local log_dir=".agent-flow"
    local log_file="${log_dir}/pipeline.log"

    # Ensure log directory exists (non-fatal; warn if creation fails)
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir" 2>/dev/null || {
            printf '[WARN] Cannot create %s for provenance log; logging to stderr only\n' "$log_dir" >&2
            printf '[INFO] Provenance: %s\n' "$log_line" >&2
            return 0
        }
    fi

    # Append to pipeline.log (append mode — never truncate)
    printf '%s\n' "$log_line" >> "$log_file" 2>/dev/null || {
        printf '[WARN] Cannot write to %s; provenance logged to stderr only\n' "$log_file" >&2
    }

    # Also emit to stderr as [INFO] for real-time visibility
    printf '[INFO] Provenance: %s\n' "$log_line" >&2
}

# ---------------------------------------------------------------------------
# resolve_overlay
#
# High-level helper: resolve overlay type for an agent and apply accordingly.
# Handles backwards compat for legacy .md overlays.
#
# Returns 0 on success (overlay applied or none found).
# Returns 1 on TOML parse/validation error (halts dispatch).
#
# Arguments:
#   $1  — agent_name        (e.g., "reviewer")
#   $2  — customization_dir (path to customization/ directory)
#   $3  — defaults_json     (JSON string of plugin defaults for this agent)
#
# Outputs on stdout:
#   Merged JSON string (for toml overlay), defaults JSON (for md/none — caller appends raw md text separately),
#   OR defaults JSON unchanged when overlay_source=none.
#
# Sets exported variable OVERLAY_SOURCE (toml|md|none) and OVERLAY_PATH for use by caller.
# ---------------------------------------------------------------------------
resolve_overlay() {
    local agent_name="$1"
    local customization_dir="$2"
    local defaults_json="$3"

    local toml_path="${customization_dir}/${agent_name}.toml"
    local md_path="${customization_dir}/${agent_name}.md"

    if [ -f "$toml_path" ]; then
        # Primary: .toml overlay
        if [ -f "$md_path" ]; then
            # Both present: .toml wins; warn about ignored .md
            _toml_merge_warn "Legacy .md overlay ignored; .toml takes precedence"
        fi

        # Parse + validate + merge
        local overlay_json
        overlay_json=$(parse_toml_overlay "$toml_path") || return 1
        validate_overlay_keys "$overlay_json" "$agent_name" "$toml_path" || return 1
        local merged_json
        merged_json=$(apply_3tier_merge "$defaults_json" "$overlay_json") || return 1

        log_overlay_provenance "$agent_name" "toml" "$toml_path"
        OVERLAY_SOURCE="toml"
        OVERLAY_PATH="$toml_path"
        printf '%s' "$merged_json"

    else
        # No overlay for this agent
        log_overlay_provenance "$agent_name" "none" "(none)"
        OVERLAY_SOURCE="none"
        OVERLAY_PATH="(none)"
        printf '%s' "$defaults_json"
    fi
}

# Export functions for use by sourcing scripts
export -f parse_toml_overlay 2>/dev/null || true
export -f apply_3tier_merge  2>/dev/null || true
export -f validate_overlay_keys 2>/dev/null || true
export -f log_overlay_provenance 2>/dev/null || true
export -f resolve_overlay 2>/dev/null || true
