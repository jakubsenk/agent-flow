# v9-overlay Test Fixtures

Fixture directory for the 3 replacement overlay runtime coverage scenarios added in v9.2.0.

## Directory Layout

```
v9-overlay/
├── README.md           — this file
├── toml/
│   └── analyst.toml   — R1: TOML overlay payload (triggers OVERLAY_SOURCE="toml")
├── none/
│   └── .gitkeep       — R2: empty-dir marker (triggers OVERLAY_SOURCE="none")
├── md-rejected/
│   └── analyst.md     — R3: markdown-only overlay (triggers OVERLAY_SOURCE="md_rejected")
└── expected/
    ├── toml.log        — expected provenance line for R1
    ├── none.log        — expected provenance line for R2
    └── md-rejected.log — expected provenance line for R3
```

## Contract

Each fixture scenario drives `resolve_overlay()` in `skills/setup-agents/lib/toml-merge.sh` to produce a specific `OVERLAY_SOURCE` value. The `expected/*.log` files contain the exact provenance line emitted by `log_overlay_provenance()`.

## Scenarios

- Replace 3 deleted overlay-source runtime coverage scenarios
- TOML fixture (R1 input)
- empty-dir fixture (R2 input)
- md-rejected fixture (R3 input)
- expected provenance lines
