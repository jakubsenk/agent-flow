# core/snippets/ — sub-namespace introduction

Canonical snippet files cited by skill orchestration via `<!-- @snippet:<name> -->` markers. The `core/snippets/` sub-namespace does NOT count toward the top-level core-contracts count (verified non-recursive by `tests/scenarios/prompt-injection-protection.sh` per REQ-063 + REQ-063a).

## Citation format (REQ-063b)

Every citation site uses the exact marker form:
```
<!-- @snippet:<snippet-name> -->
```
where `<snippet-name>` is the basename without extension (e.g., `webhook-curl`, `issue-id-validation`, `metrics-json-schema`, `pipeline-completion`, `architecture-freshness`).

The marker is parseable by tooling. The cited content MAY remain inline immediately after the marker — LLM orchestrators read the snippet at execution time; the marker is the load-bearing referent.

## Validity test (REQ-063c)

`tests/scenarios/v690-snippet-citation-counts.sh` greps `<!-- @snippet:<name> -->` markers across the repository and asserts the count matches the expected count documented in each snippet's `## Used by:` heading:

| Snippet | Expected citation count |
|---------|-------------------------|
| webhook-curl | 31 |
| issue-id-validation | 5 |
| metrics-json-schema | 1 |
| pipeline-completion | 3 |
| architecture-freshness | 2 |

Drift (over-cite or under-cite) FAILS the test.

## Rollback contract (REQ-063d)

If a snippet is found broken in production (e.g., regex typo propagated to all callers), the operator MUST revert the snippet's content inline at every citation site BEFORE deleting or modifying the snippet file. Pure citation form has no fallback — the snippet IS the source of truth for the cited content.

**Recovery procedure:**
1. `git show <release-tag>:core/snippets/<name>.md` — retrieve canonical content from a known-good release tag.
2. For each `<!-- @snippet:<name> -->` site, re-inline the canonical content immediately after the marker (or remove the marker if reverting fully to inline-only).
3. Only then delete or fix the snippet file.

This is operator action; no spec automation needed.
