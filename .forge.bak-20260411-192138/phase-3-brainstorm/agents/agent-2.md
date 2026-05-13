# Phase 3 Brainstorm — Agent 2: DX Architect Perspective

**Focus:** Systemic patterns, reuse potential, diagnostic experience design
**Date:** 2026-04-11

---

## Issue 1: TLS Diagnostic (Block 3, Step 9)

### Problem Restatement

Node.js MCP processes reject TLS connections to servers running behind private CAs or self-signed
certificates with errors like `UNABLE_TO_VERIFY_LEAF_SIGNATURE` or `SELF_SIGNED_CERT`. The current
Step 9 only distinguishes auth errors from "unreachable" errors. TLS rejections get classified as
"unreachable", sending the user on a false trail to check if the server is running — when the server
IS running and the real fix is adding `NODE_OPTIONS: --use-system-ca` to `.mcp.json`.

### Approach A: Pattern-match-only (no curl probe)

**What it does:** Expand the error classification with explicit TLS pattern detection. If the error
string matches any known TLS pattern, emit the `--use-system-ca` recommendation immediately, without
a secondary network probe.

**Pros:**
- Simplest implementation — no additional tool invocation
- Fast: no extra network roundtrip
- Zero new tool dependencies (Bash already in `allowed-tools`)

**Cons:**
- False positive risk: if Node.js TLS error fires on a genuinely unreachable server (e.g., a
  misconfigured DNS alias that resolves but doesn't serve), the user gets "likely TLS" when the
  server is actually down
- The TLS pattern set needs to cover enough variants to avoid misses (UNABLE_TO_VERIFY_LEAF_SIGNATURE,
  CERT_UNTRUSTED, SELF_SIGNED_CERT, self signed certificate, certificate verify failed, ERR_TLS_*,
  DEPTH_ZERO_SELF_SIGNED_CERT, unable to get local issuer certificate)

### Approach B: TLS-detect then curl-probe (Phase 2 recommendation)

**What it does:** Detect TLS patterns first. When matched, run `curl -s -o /dev/null -w "%{http_code}"
--max-time 5 {Instance}`. If curl reaches the server (exit 0, HTTP code != 000), the server is
genuinely reachable → TLS diagnosis confirmed, emit `--use-system-ca` recommendation. If curl
cannot reach it → fall back to "server not reachable".

**Pros:**
- Eliminates false positives: the curl probe definitively distinguishes TLS rejection from genuine
  unreachability
- Precise diagnosis leads to precise recommendation
- curl probe is a single fast command; max-time 5 caps any delay

**Cons:**
- Adds one Bash invocation per TLS-pattern match; negligible overhead
- Requires curl to be available — almost universal but theoretically absent in minimal environments
- Step 9 prose expands from 4 lines to ~14 lines; more text for Claude to track

### Approach C: TLS-detect with an HTTP-only probe variant

**What it does:** Like Approach B, but instead of curl, use a Bash `nc -z -w 2 {host} {port}` TCP
reachability check. This avoids depending on curl by testing at the TCP layer only.

**Pros:**
- No curl dependency
- Still confirms whether the host is network-reachable at the TCP level

**Cons:**
- `nc` (netcat) is less universally available than curl on Windows environments
- TCP reachability check does not confirm HTTP service is actually running — a TLS-rejecting server
  and a port-open-but-not-HTTP server look the same at TCP layer
- More complex to parse (exit codes vs curl's %{http_code})
- On Windows (this repo runs on Windows 11 Pro), `nc` is often absent or behaves differently

### Recommendation: Approach B

The curl probe is the right investment. The false-positive risk in Approach A is real: corporate
environments commonly run servers that Node.js rejects for TLS reasons while the server itself is
fully operational, and these environments are precisely the ones most likely to have private CAs.
A wrong "server unreachable" message costs significant debugging time.

**Systemic note:** The TLS-detect + curl-probe pattern should be treated as a **reusable diagnostic
sub-flow**, not one-off check-setup logic. The same TLS misclassification problem will affect Step
10 (source control MCP connectivity) if the SC server runs behind a private CA. Consider extracting
a `## TLS Diagnostic Sub-flow` note to `core/mcp-detection.md`'s Failure Handling section so any
future caller inherits it. This is a low-cost documentation change (not a new core contract file),
but it signals to future implementers that the probe is the canonical pattern.

**Ordering note:** Match TLS patterns BEFORE auth patterns. Auth errors return HTTP codes; TLS errors
occur at the handshake layer before HTTP is established. If both pattern sets could theoretically
match the same error string (unlikely, but possible with custom error messages), TLS diagnosis is
more actionable — `NODE_OPTIONS` is a one-line fix, while "check your token" is less specific.

---

## Issue 2: read:user Scope Check (Step 10)

### Problem Restatement

Step 10 says "list repositories via MCP", implying a GitHub-style user-level enumeration call
(`list_my_repositories` or equivalent). Gitea's MCP does not expose such a tool. The `read:user`
scope is a GitHub concept; Gitea uses repository-scoped tokens. The real intent is: confirm that
the configured remote is accessible — which only requires `repository:read` scope and a single
targeted repo fetch.

The current phrasing has two independent problems:
1. **Wrong API call:** listing repositories vs. fetching one specific repository
2. **Wrong scope name in error message:** `read:user` vs. `repository:read`

These compound: a user with a Gitea token that has `repository:read` but not some non-existent
"user:read" scope would see a misleading FAIL directing them to a permission that doesn't exist.

### Approach A: Fix Step 10 in isolation (Phase 2 recommendation)

**What it does:** Replace "list repositories via MCP" with "fetch metadata for the specific
`Remote` value from Automation Config". Add per-error-type failure messages distinguishing
404 (wrong remote path) from 401/403 (wrong token) from unreachable (network/MCP issue).
Update the scope name in the auth error to `repository:read`.

**Pros:**
- Minimal, surgical change
- Directly fixes both problems (wrong API call + wrong scope name)
- The 404 branch adds real diagnostic value: if the user mistyped the owner/repo, they get a
  targeted message rather than a generic auth error

**Cons:**
- Step 10 remains structurally similar to Step 9 with per-branch messages; they will diverge
  further as TLS handling is added to Step 10 in a follow-up

### Approach B: Lift Step 10 error-branch logic into a shared sub-pattern

**What it does:** Both Step 9 (issue tracker) and Step 10 (source control) now have a parallel
structure: make a targeted MCP query, then classify the error into auth/TLS/404/unreachable. Rather
than duplicating this classification logic in two places, define a standard error classification
prose block (ordered pattern matching) once — either inline as a `## Connectivity Check Pattern`
note in check-setup or as a short addition to `core/mcp-detection.md`'s Failure Handling section.
Both Step 9 and Step 10 then reference it.

**Pros:**
- Single place to add TLS support to Step 10 in the future
- Reduces prose duplication; check-setup stays concise
- Alignment between Step 9 and Step 10 failure messages becomes enforced, not accidental

**Cons:**
- Indirection: an LLM executing check-setup would need to read or recall a referenced sub-section
- More changes in scope for this task (touches core/ as well)
- Core contracts are supposed to be inputs/outputs focused; a diagnostic classification table is
  slightly out of character for that layer

### Approach C: Rebuild Step 10 around core/mcp-detection.md

**What it does:** Step 10 already effectively duplicates what `core/mcp-detection.md` does:
it verifies connectivity for a specific service. Replace Step 10 prose with an explicit instruction
to run `core/mcp-detection.md` with `service_type: "sc"` and map its output (`mcp_available`,
`error` field) to the OK/FAIL messages. This is the same pattern scaffold uses for Step 0-MCP.

**Pros:**
- Step 10 becomes a 3-line delegation to an existing contract
- Future improvements to `mcp-detection.md` (e.g., TLS branch in failure handling) automatically
  flow to check-setup Step 10
- Consistent with how scaffold.SKILL.md Step 0-MCP already works

**Cons:**
- `core/mcp-detection.md` currently handles `service_type: "sc"` by "attempt to verify the declared
  remote exists" — it does not currently produce the 404-vs-401 distinction that check-setup needs.
  Adopting this approach requires expanding the mcp-detection output contract.
- Greater scope change; likely out of bounds for a targeted fix task

### Recommendation: Approach A for immediate fix; note Approach C as follow-up

Approach A is the right scope for this task. It directly fixes the wrong API call and wrong scope
name with minimal text change. The 404 branch addition improves the diagnostic quality meaningfully
for the common mistake of mistyping the owner/repo.

Approach B's shared sub-pattern idea is appealing but premature: the two steps are not yet similar
enough to share a pattern cleanly, and forcing that abstraction now would expand scope without
proportional benefit.

**Opportunity flag:** Approach C represents a genuine systemic improvement worth logging. Once
`core/mcp-detection.md` is extended with structured error classification output (TLS / auth / 404 /
unreachable), check-setup Step 9 and Step 10 can both delegate to it and collapse to ~3 lines each.
This is a clean v2 of the connectivity checks that emerges naturally once both TLS fixes land. Suggest
recording this as a roadmap item or follow-up task: "Consolidate Step 9 + Step 10 connectivity checks
into mcp-detection.md delegation".

**SC connectivity check improvement — bonus opportunity:**
The Phase 2 plan for Fix 2 also implicitly improves the diagnostic for a key real-world failure mode:
users who configure `Remote` as `gitea-org/project` but their Gitea instance uses a custom URL path.
A targeted repo fetch (vs. a user listing) returns 404 immediately and with high signal. This is
a genuine DX improvement worth calling out in the change message.

---

## Issue 3: Path Resolution (trackers.md)

### Problem Restatement

`docs/reference/trackers.md` is part of the plugin installation. When ceos-agents runs in a
consuming project's working directory (which is the normal case), the plugin files are NOT at
`docs/reference/trackers.md` relative to CWD. The current bare relative path works only when
Claude is run from within the plugin repository itself — the development case. This is a latent
failure in all 13+ references across the codebase.

In check-setup specifically, there are two references: Step 3a (tracker validation) and Step 7
(MCP server keyword detection). Both fail silently in the field because the LLM tries to Read
a non-existent path and may hallucinate or silently skip the validation.

### Approach A: Glob-based discovery with CWD fallback (Phase 2 recommendation)

**What it does:** Replace the bare path with a Glob call: `**/docs/reference/trackers.md`.
Take the first result. Fall back to CWD-relative path if Glob returns no results. Emit [WARN]
and skip validation if neither resolves.

**Pros:**
- Works in both consuming project context (plugin installed somewhere in the filesystem) and
  plugin development context (CWD is the plugin repo itself)
- No hardcoded path assumptions
- Glob is already in `allowed-tools` — no frontmatter change needed
- Graceful degradation: [WARN] + skip is better than silent failure

**Cons:**
- Glob may match a consumer project's own docs folder if they happen to have a `docs/reference/`
  subtree with a `trackers.md` — low probability but non-zero
- Two-step resolution adds prose lines
- Does not solve the problem for the 11+ other references outside check-setup

### Approach B: Embed the trackers.md lookup tables directly into core/mcp-detection.md

**What it does:** The MCP Server Detection table and Validation Rules table from trackers.md are
already partially duplicated in `core/mcp-detection.md` (Process step 1 has an inline lookup table).
Extend this to also embed the Validation Rules, Query Syntax, and State Transition tables.
Skills reference `core/mcp-detection.md` for MCP lookups — extend the contract to cover all
lookup operations currently requiring trackers.md.

**Pros:**
- Eliminates the path resolution problem entirely for MCP-related lookups (the majority of uses)
- Core contracts are loaded by skills at runtime and are path-safe (they're in the plugin root)
- Already partially done: core/mcp-detection.md has an inline MCP Server Detection table

**Cons:**
- Creates duplication between trackers.md and the core contract — now two sources of truth for
  the same data
- Maintenance burden: adding a new tracker requires updating both files
- Does not solve non-MCP references in trackers.md (onboard uses Query Syntax, State Transition,
  Instance Defaults tables — these are not in core/mcp-detection.md)
- Conflates the discovery contract (mcp-detection.md) with a data reference role

### Approach C: Plugin-relative path via CLAUDE.md metadata or env variable

**What it does:** When the plugin is installed, its installation path is known. If Claude Code
exposes an environment variable or metadata about the plugin path, skills could construct the
absolute path dynamically: `{plugin_install_path}/docs/reference/trackers.md`.

**Pros:**
- Solves the root cause: the path is always absolute and correct
- No filesystem search overhead

**Cons:**
- Plugin installation path exposure is not a documented Claude Code feature — this is speculative
- Fragile if the plugin path ever changes (reinstall, path rename)
- Requires knowledge of the Claude Code plugin runtime that may not be available

### Recommendation: Approach A (Glob-first) for check-setup; flag systemic issue for follow-up

Approach A is the correct fix for check-setup. It is practical, uses existing tooling, and
gracefully handles both the plugin-development and consuming-project contexts.

Approach B is architecturally appealing but introduces a maintenance duplication problem that will
compound as new trackers are added. The current partial duplication in `core/mcp-detection.md`
(which has its own inline MCP lookup table alongside the reference to trackers.md) is already a
liability; extending it would make this worse.

Approach C is speculative and should not be pursued until Claude Code explicitly documents plugin
path exposure.

**Critical systemic note:** The 13+ bare `docs/reference/trackers.md` references outside of
check-setup represent a systemic fragility. The out-of-scope note in Phase 2's final.md correctly
identifies this. The recommended fix pattern (Glob-then-fallback) should be:

1. Applied to check-setup now (in-scope)
2. Documented as a convention: "Always resolve plugin-relative paths with Glob before Read"
3. Applied to other skills in a follow-up task: `skills/onboard/SKILL.md` (5 references),
   `skills/scaffold/SKILL.md` (3 references), `skills/init/SKILL.md` (1 reference), and
   `core/mcp-detection.md` (1 reference to trackers.md in Process step 1 description text)

**The Glob convention should be documented in `core/` or in the plugin's CLAUDE.md instructions**
to prevent future references from using bare relative paths. A one-liner in the "When Editing"
section would suffice: "When referencing files in `docs/reference/`, always use Glob with pattern
`**/docs/reference/{file}.md` — never bare relative paths."

---

## Cross-Issue Systemic Improvements

### 1. Error Classification as a First-Class Pattern

All three fixes involve classifying MCP connectivity errors into categories. Currently each caller
defines its own pattern set. The recommended path forward:

- **Short term (this task):** Apply fixes as described to check-setup SKILL.md. Add a comment
  in `core/mcp-detection.md` Failure Handling noting that TLS errors are a known category
  and the curl-probe is the canonical confirmation method.
- **Medium term (follow-up):** Extend `core/mcp-detection.md` output contract with a structured
  `error_type` field: `"tls" | "auth" | "not_found" | "unreachable" | "unknown"`. Then check-setup
  Steps 9 and 10 become 3-line lookups that map `error_type` to a user message. This eliminates
  all inline pattern matching from check-setup.

### 2. Plugin-Relative Path Convention

Add a convention rule to the CLAUDE.md "When Editing Agent Definitions" or plugin-wide instructions:
"Files in `docs/reference/` are plugin-internal. Always locate them with Glob
(`**/docs/reference/{file}.md`) before Read. Never use bare relative paths."

This is a zero-code change that prevents recurrence.

### 3. SC Connectivity Check Alignment with Scaffold

`skills/scaffold/SKILL.md` Step 0-MCP already delegates to `core/mcp-detection.md` for both
tracker and SC connectivity. `skills/check-setup/SKILL.md` Step 10 implements its own ad-hoc SC
check. The long-term target is alignment: check-setup should eventually delegate to the same
core contract. The Fix 2 rewrite is a step in this direction (it makes Step 10's intent explicit
and precise), making the eventual migration to delegation easier.

### 4. TLS Fix Scope: Step 10 is a Follow-up, Not This Task

The Phase 2 out-of-scope note correctly flags Step 10 as a candidate for the same TLS treatment as
Step 9. This is valid but should remain a separate task. Combining it with this fix would expand
scope, complicate review, and risk introducing errors in a block that is already being rewritten.
The recommended sequencing: Fix 1/2/3 → commit → new task for Step 10 TLS + mcp-detection.md
extension.

### 5. Diagnostic Sequence Design

The three fixes collectively improve the diagnostic sequence for the most common real-world failures.
The optimal sequence from a user experience perspective:

```
Config valid? → MCP configured? → Token placeholder? → Connectivity OK?
                                                         ├─ Auth error   → token/scope guidance
                                                         ├─ TLS error    → NODE_OPTIONS guidance
                                                         └─ Unreachable  → server/URL guidance
```

This matches the current Block 1 → 2 → 3 structure. The fixes ensure Block 3 now cleanly maps
to the three failure modes users actually encounter, rather than collapsing TLS into unreachable.
The result is a diagnostic tool where every FAIL message has exactly one recommended action —
which is the gold standard for developer tooling.
