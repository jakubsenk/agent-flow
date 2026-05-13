# Phase 3 — Brainstorm

**SKIP** — Implementation approaches are dictated by existing patterns. No design decisions needed:
- New core contract: follow `core/config-reader.md` format (Purpose/Input/Output/Failure)
- New CLI flag: follow `--lang`, `--framework`, `--db` pattern in scaffold.md Flag Parsing
- New state field: follow existing field definitions in `state/schema.md`
- Canary-write: non-blocking warn pattern already exists in Step 0-MCP (downgrade flow)
- YOLO+no-MCP block: guard clause pattern already exists in implement-feature.md
