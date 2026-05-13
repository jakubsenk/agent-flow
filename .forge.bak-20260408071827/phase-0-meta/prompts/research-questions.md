# Phase 1 — Research Questions

**SKIPPED** — Fast-track eligible. Root cause is known.

However, if research were needed, these questions would apply:

1. Does the upstream forgejo-mcp repository (codeberg.org/goern/forgejo-mcp) publish Windows binaries in any release?
2. What does the .goreleaser.yml in that repository target? (Answer from bug report: linux and darwin only)
3. Can forgejo-mcp be built from source with `go install`? What is the Go module path?
4. What is the typical size of a valid forgejo-mcp binary? (Needed for size-threshold validation)
5. Are there any open issues upstream requesting Windows support?
