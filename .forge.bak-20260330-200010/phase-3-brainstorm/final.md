# Phase 3 — Brainstorm Synthesis

## Design Decisions (3 personas: Conservative, Innovative, Skeptic)

### Decision 1: --infra Flag Format

**Consensus:** Change to `--infra tracker:ready,sc:later` (named key-value pairs).

| Aspect | Conservative | Innovative | Skeptic |
|--------|-------------|-----------|---------|
| Format | `tracker:ready,sc:later` | Same, order-independent, partial allowed | Same, but warns it's breaking |
| Backward compat | Clean break (flag is new, v5.3.0) | No shim | Deprecation notice or dual support |
| Shorthand | `--infra ready` / `--infra later` | No bare words; use `all:ready` grammar | Warns about parsing ambiguity |

**Recommendation:** Named key-value, order-independent. Support `--infra ready` and `--infra later` as shorthands (both set tracker+SC to same value). Clean break — flag is only 1 version old with no external users. Mention in changelog.

### Decision 2: Canary-Write Announcement

**Full consensus:** Always announce, never ask. Interactive gating is architecturally impossible (runs before mode selection).

**Recommended text:** `Checking write access — creating a temporary test item in {project}. It will be deleted immediately.`

**Placement:** In `commands/scaffold.md` before the `core/mcp-detection.md` call with `check_write = true`. The core contract stays unchanged.

### Decision 3: MCP Jargon Scope

| Approach | Conservative + Innovative | Skeptic |
|----------|--------------------------|---------|
| Scope | scaffold.md + resume-ticket.md only | All 15 files for consistency |
| Rationale | PATCH scope, minimize risk | Partial fix is worse than consistent jargon |

**Recommendation:** Fix all files that use the standard pre-flight MCP error pattern. The change is mechanical (find/replace) and low-risk. The skeptic is right that partial inconsistency is worse. However, scope it to the exact "MCP server for {Type} is not available" pattern only — don't rewrite other MCP references.

**Replacement pattern:** "Cannot connect to your {Type} tracker. Is the {Type} integration configured? Run /ceos-agents:check-setup for diagnostics."

**Important (from Skeptic):** Distinguish tracker vs SC services. "Cannot connect to your GitHub tracker" is wrong when GitHub is SC. Use: "Cannot connect to your {Type} issue tracker" for tracker, "Cannot connect to your {Type} repository" for SC.

### Decision 4: Resume --infra Override

| Aspect | Conservative | Innovative | Skeptic |
|--------|-------------|-----------|---------|
| Location | scaffold.md line 126 | Same | Same |
| Re-run MCP | Yes, always | Only for changed services | Warns about complexity |
| Downgrade | Not addressed | Allow with field nulling | Restrict to upgrades only |
| Display | Simple message | Diff-style change display | N/A |

**Recommendation:** Allow both upgrade (later→ready) and downgrade (ready→later). Re-run Step 0-MCP for services that changed to "ready". Display change summary. For downgrade: null out detail fields (instance, project, remote). Skeptic's concern about late-stage downgrade is valid but edge-case — the user is explicitly requesting it.

## Divergence Assessment

```json
{
  "divergence_class": "ALIGNED",
  "original_keywords": ["infra", "flag", "format", "canary", "announce", "MCP", "jargon", "error", "resume", "override"],
  "recommended_keywords": ["infra", "flag", "format", "canary", "announce", "tracker", "error", "resume", "override", "self-documenting"],
  "keyword_overlap_score": 0.85
}
```

All three personas agree on the fundamental approach for all 4 items. Disagreements are on scope (MCP jargon: 2 vs 15 files) and edge cases (downgrade handling), not on direction.
