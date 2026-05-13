# Phase 0: Meta-Agent Analysis

## 1. Task Type Classification

**Type:** `bugfix`

Three patch fixes to existing agent definitions, skill files, and test scripts. No new features, no new agents, no contract changes. Pure behavior fixes and test hardening.

## 2. Complexity Assessment

| Axis | Score | Rationale |
|------|-------|-----------|
| Scope | 2 | 6 files across agents/, skills/, tests/ — but all within one domain (triage + scaffold) |
| Ambiguity | 1 | Fully specified in roadmap with exact file lists, exact changes, exact patterns |
| Risk | 1 | No breaking changes — adds explicit tokens to agent output, extends detection, hardens tests |

**Composite:** max(2, 1, 1) = **2**

JIT Recommendation: `jit.enabled: false` (composite < 3)
Replanning Recommendation: defaults (low ambiguity)
Verification Weight Recommendation: `correctness: 0.4, security: 0.25, spec_alignment: 0.2, robustness: 0.15` (bugfix — correctness-critical)

## 2b. Fast-Track Eligibility Assessment

- Composite complexity: 2 (<=2: PASS)
- Confidence: 1.0 (>=0.9: PASS)
- `fast_track.enabled`: null (auto-detect: PASS)

All preconditions pass. Proceeding to security evaluation.

### Tier A: Deterministic Keyword/Regex Patterns

Scanned raw task input against all 9 categories (destructive_ops, credential_handling, irreversible_side_effects, elevated_privileges, ambiguous_scope, network_irreversibility, supply_chain_ops, billing_quota_ops, system_service_effects).

**Result: NO MATCHES.** Proceed to Tier B.

### Tier B: LLM-Assessed Semantic Evaluation

```json
{
  "security_evaluation": {
    "destructive_ops":           { "result": "pass", "evidence": "Task modifies markdown agent definitions and shell test scripts only — no file deletion or data destruction" },
    "credential_handling":       { "result": "pass", "evidence": "No credentials, secrets, API keys, or tokens are read, written, or transmitted in any of the target files" },
    "irreversible_side_effects": { "result": "pass", "evidence": "All changes are local markdown and shell script edits — no emails, notifications, or external API calls triggered" },
    "elevated_privileges":       { "result": "pass", "evidence": "No sudo, chmod, chown, or any elevated privilege operations — pure text file edits in user workspace" },
    "ambiguous_scope":           { "result": "pass", "evidence": "Scope is precisely bounded to 6 named files listed in the roadmap — no wildcard or unbounded operations" },
    "network_irreversibility":   { "result": "pass", "evidence": "No DNS, CDN, firewall, load balancer, or webhook modifications — entirely local file changes" },
    "supply_chain_ops":          { "result": "pass", "evidence": "No package publishing, container pushing, or registry operations — this is a plugin of markdown definitions" },
    "billing_quota_ops":         { "result": "pass", "evidence": "No cloud resource provisioning, subscription changes, or quota modifications involved" },
    "system_service_effects":    { "result": "pass", "evidence": "No systemd, cron, docker daemon, or firewall rule changes — only markdown and bash test script edits" }
  }
}
```

**Tier B result:** All nine categories PASS. Structural validation passes (all keys present, all evidence >= 15 chars).

**Fast-track: ACTIVATED.**

## 3. Domain Identification

- **Language/Runtime:** Markdown (agent definitions, skill definitions), Bash (test scripts)
- **Framework:** ceos-agents plugin system (pure markdown, no build system)
- **Domain:** DevOps tooling / AI agent orchestration
- **Specialty concerns:** Output contract consistency, cross-stack detection coverage, test robustness

## 4. Codebase Context Assessment

- **Repo structure:** `agents/` (19 agent .md files), `skills/` (26 skills as SKILL.md), `tests/scenarios/` (bash test scripts)
- **Agent format:** YAML frontmatter + markdown body (Goal, Expertise, Process, Constraints)
- **Skill format:** YAML frontmatter + markdown body with numbered steps
- **Test framework:** Bash scripts with `set -euo pipefail`, `fail()` function, `grep`/`sed` assertions, `PASS`/`FAIL` output
- **No build system, no dependencies** — pure markdown plugin
- **Key convention:** Block Comment Template format for pipeline blocks, `[ceos-agents]` prefix for machine-parseable comments
- **Existing patterns:** triage-analyst outputs "Quality gate: PASS" or "Quality gate: incomplete" but no explicit UNCLEAR token. Skills branch on "UNCLEAR" concept without a formal contract.

## 5. Confidence Scoring

| Question | Score | Rationale |
|----------|-------|-----------|
| Is the task well-defined? | 1.0 | Exact file lists, exact changes, exact patterns specified in roadmap |
| Does context support execution? | 1.0 | All target files read and understood, patterns clear |
| Within pipeline capabilities? | 1.0 | Pure text editing of markdown and bash scripts |

**Composite confidence:** min(1.0, 1.0, 1.0) = **1.0**

## 6. Routing Decision Output

```json
{
  "routing_decision": {
    "task_type": "bugfix",
    "secondary_types": [],
    "action": "full_pipeline",
    "target_skill": null,
    "confidence": 1.0,
    "reasoning": "Three well-specified patch fixes to agent definitions, skill files, and test scripts. Fast-track activated due to low complexity and high confidence.",
    "skip_profile": null
  }
}
```
