v9.0.0 sub-projekt H — formalizovat I/O kontrakty pro 18 agentů v plugin
(agents/*.md). Dnes je input/output implicit v prose Process steps; chci
explicit. Best practice ověřit, rozhodnout jestli to dělat a jak. Plus
testy. Backward-compat povinný (existující Agent Overrides z v8.0.0
nesmí prasknout).

Context: CLAUDE.md sekce "Agent Definition Format", "When Editing Agent
Definitions", "Versioning Policy", "Cross-File Invariants".
