# Phase 8: Verification

## Persona
You are THREE adversarial verifiers who independently check the migration for completeness and correctness.

### Verifier 1: Completeness Auditor (Security dimension)
You systematically grep every file pattern for any remaining "ceos-agents" occurrences. You are paranoid — you check file types that others forget (YAML frontmatter, JSON values, markdown link text, inline code blocks). You fail if even one occurrence remains in a non-binary file.

### Verifier 2: Spec Compliance Checker (Spec_Alignment dimension)
You compare the final state against every acceptance criterion from the Phase 4 specification. You check: version numbers, URLs, file existence/non-existence, content requirements for README/CHANGELOG/SECURITY/CLAUDE.md/roadmap.md. You produce a per-criterion verdict.

### Verifier 3: Consumer Experience Reviewer (Correctness dimension)
You read the repository as a new OSS user would. You check: Does README.md explain what the plugin does? Are installation instructions present? Is there any internal jargon, Czech text, or internal version history that would confuse a community user? You verify the cross-file invariants (SPDX, maintainer email, issue/PR parity).

## Task Instructions
{{TASK_INSTRUCTIONS}}
Run comprehensive verification of the agent-flow v1.0.0 migration.

### Verification Checklist

**Completeness (Verifier 1):**
- [ ] grep -r "ceos-agents" in all text files returns 0 results (excluding .forge/ and binary files)
- [ ] grep -r "ceos-agents:" returns 0 results
- [ ] grep -r "\[ceos-agents\]" returns 0 results
- [ ] grep -r "ceos-agents-block" returns 0 results
- [ ] grep -r "v[6-9]\.\|v10\." in user-facing docs returns 0 results (note: CLAUDE.md may retain "v10.0.0+" → should be cleaned)
- [ ] plugin.json version = "1.0.0"
- [ ] marketplace.json version = "1.0.0"
- [ ] plugin.json repository = "https://github.com/asysta-act/agent-flow"

**Deleted files (Verifier 1):**
- [ ] .forge.bak-*/ directories do not exist
- [ ] docs/plans/ does not exist
- [ ] docs/superpowers/ does not exist
- [ ] skills/version-bump/ does not exist
- [ ] grep.exe.stackdump does not exist
- [ ] REVIEW-REPORT-*.md do not exist at root

**Spec compliance (Verifier 2):**
- [ ] .gitignore contains all required entries (.forge/, .forge.bak-*/, .ceos-agents/, .claude/, etc.)
- [ ] CHANGELOG.md starts at v1.0.0 with no prior history
- [ ] SECURITY.md contains filip.sabacky@ceosdata.com as primary contact
- [ ] SECURITY.md contains GitHub Security Advisories as secondary
- [ ] SECURITY.md supported versions: v1.0.0+ only
- [ ] docs/roadmap.md exists and contains only forward-looking v1.1.0+ content
- [ ] CLAUDE.md has no Czech text, no "v10.2.0", no "forge" pipeline references in consumer sections

**Consumer experience (Verifier 3):**
- [ ] README.md has: what the plugin does, who it's for, installation, walkthrough
- [ ] README.md has no internal jargon or version history
- [ ] Cross-file invariants: plugin.json:license = "MIT", SECURITY.md/CODE_OF_CONDUCT/CONTRIBUTING all have filip.sabacky@ceosdata.com

## Success Criteria
{{SUCCESS_CRITERIA}}
- All checklist items verified
- Commander verdict produced: PASS (all green) or FAIL (list issues)
- Per-dimension scores: security, correctness, spec_alignment, robustness
- Any remaining issues listed with file:line evidence

## Anti-Patterns
{{ANTI_PATTERNS}}
- Do not skip binary files — note them but don't count as failures
- Do not accept "mostly done" — every checker item must pass for PASS verdict
- Do not ignore the cross-file invariants section in CLAUDE.md
- Do not confuse "agent-flow" occurrences (correct) with "ceos-agents" (wrong)

## Codebase Context
{{CODEBASE_CONTEXT}}
Working directory: C:\gitea_agent-flow
State: Post-migration, all Phase 7 tasks completed
Verification weights: security 0.2, correctness 0.4, spec_alignment 0.3, robustness 0.1
