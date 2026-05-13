# Phase 0 Input

Audit a oprava agent definic pro feature pipeline v ceos-agents pluginu.

KONTEXT: Agenti fixer, reviewer, test-engineer, e2e-test-engineer, rollback-agent
a core kontrakty (fixer-reviewer-loop, block-handler, decomposition-heuristics)
byly původně navrženy pro bug-fix pipeline. Teď se sdílejí mezi třemi hlavními
skilly: fix-ticket, implement-feature, scaffold. Problém je, že jejich definice
(role statements, process steps, constraints, guards) jsou bug-fix-centrické
a neošetřují feature kontext.

SCOPE — co zkontrolovat a opravit:
1. skills/implement-feature/SKILL.md — celý skill, jak předává kontext agentům,
   chybějící mode signál, chybějící NEEDS_DECOMPOSITION handler, smoke-check rollback gap
2. agents/fixer.md — frontmatter, role, Goal, Step 1 guard (hard Block na chybějící
   triage analysis), Step 5 TDD (reproduce the bug), Constraints
3. agents/reviewer.md — Step 1 (čte neexistující bug report/triage/impact), Step 2
   checklist (root cause check), AC Fulfillment
4. agents/test-engineer.md — Step 1 (čte bug report), Step 3 (regression test framing)
5. agents/e2e-test-engineer.md — Step 1 (čte bug report), Goal
6. core/fixer-reviewer-loop.md — Input Contract (code-analyst output), Failure Handling
   (NEEDS_DECOMPOSITION refs jen fix-ticket)
7. core/block-handler.md — rollback trigger list (chybí smoke-check)
8. agents/rollback-agent.md — trigger allowlist (chybí smoke-check)
9. core/decomposition-heuristics.md — scope anotace (bug-only)
10. state/schema.md — triage.acceptance_criteria dual provenance

POŽADOVANÉ ZMĚNY:
- Přidat mode-aware branching do sdílených agentů (fixer, reviewer, test-engineer,
  e2e-test-engineer) — Step 1 musí rozlišovat bug vs feature kontext
- Přidat Mode: feature-implementation prefix do implement-feature SKILL.md Step 6b/6d/6e
- Přidat NEEDS_DECOMPOSITION handler do implement-feature Step 6b
- Přidat smoke-check do rollback trigger listů (block-handler + rollback-agent)
- Aktualizovat fixer-reviewer-loop.md Input Contract na discriminated union (bug/feature)
- Aktualizovat decomposition-heuristics.md s explicitní scope anotací
- Aktualizovat state/schema.md s ac_source polem
- Aktualizovat fixer TDD step pro feature mode (ne "reproduce the bug")
- Aktualizovat reviewer checklist pro feature mode (ne "root cause check")
- Volitelně: acceptance-gate compensating requirement pro single-pass feature mode

OMEZENÍ:
- Změny NESMÍ rozbít bug-fix pipeline (fix-ticket/fix-bugs) — všechny edity musí
  být additivní (mode branch), ne destruktivní (nahrazení bug-fix jazyka)
- Změny NESMÍ rozbít scaffold pipeline
- Dodržet stávající agent definition format (frontmatter, Goal→Expertise→Process→Constraints)
- Žádné nové soubory pokud to není nutné — editovat existující
- Po dokončení spustit tests/harness/run-tests.sh

PŘEDCHOZÍ VÝZKUM: Kompletní audit report je v docs/plans/implement-feature-agent-audit-REVIEW.md
a v .forge.bak-20260413-083122/phase-2-research-answers/final.md — 12 CRQ, 4 BLOCKING + 4 HIGH + 4 MEDIUM,
vše CONFIRMED.
