# Snippet — /metrics --format json output schema

Canonical JSON schema for `/agent-flow:metrics --format json` output. Cite this file from `skills/metrics/SKILL.md` rather than duplicating the schema inline.

```json
{
  "generated_at": "ISO-8601 timestamp",
  "period_days": 30,
  "project": "string (tracker project key, e.g. PROJ — NOT full project name; PII-scope-bound per state/schema.md Sensitive field exclusion contract)",
  "pipeline_overview": {
    "issues_attempted": 0,
    "issues_fixed": 0,
    "issues_blocked": 0,
    "success_rate": 0.0,
    "avg_time_to_fix_hours": 0.0
  },
  "token_cost": {
    "measured_issues": ["PROJ-42"],
    "estimated_issues": ["PROJ-37"],
    "measured_tokens": 0,
    "estimated_tokens": 0
  },
  "block_analysis": {
    "by_stage": [
      {"stage": "triage", "blocks": 0, "pct": 0.0}
    ],
    "top_reasons": [
      {"reason": "string (sanitized — block.detail content EXCLUDED per state/schema.md hard contract)", "count": 0}
    ]
  },
  "per_agent": [
    {
      "agent": "fixer",
      "invocations": 0,
      "blocks": 0,
      "success_rate": 0.0,
      "top_failure": "string"
    }
  ],
  "recommendations": ["string"]
}
```

**HARD CONTRACT cite:** `top_reasons[].reason` MUST use `block.reason` only (sanitized 2-sentence summary). `block.detail` is NEVER serialized — see `state/schema.md` Sensitive field exclusion contract table.

## Used by:
- `skills/metrics/SKILL.md` (citation marker `<!-- @snippet:metrics-json-schema -->` near schema definition section)

**Expected citation count:** 1 (verifier `tests/scenarios/v690-snippet-citation-counts.sh`).
