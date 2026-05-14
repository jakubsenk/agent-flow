<!-- Fixture: malformed-truncated.md — opening tag present, body content, NO closing tag -->
<stage_allowlist>
required: triage, code_analysis, fixer_reviewer
optional: smoke_check
<!-- file ends here; no </stage_allowlist> closing tag — awk reads body to EOF -->
