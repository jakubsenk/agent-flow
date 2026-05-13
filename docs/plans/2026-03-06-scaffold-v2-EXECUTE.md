# Execute & Review — Scaffold v2 Implementation

> **Pro Claude:** Použij `superpowers:executing-plans` skill. Toto je multi-step implementace schváleného plánu s iterativním review.

---

## Co děláš

Implementuješ schválený plán: `docs/plans/2026-03-06-scaffold-v2-implementation-plan.md`

Tento plán má 7 fází (Phase 0–6) a pokrývá 18 souborů. Tvým úkolem je:

1. **Implementovat VŠECHNY fáze** přesně podle plánu
2. **Provést self-review** po každé fázi
3. **Na konci provést kompletní cross-review** celého výsledku
4. **Opakovat review dokud není ZERO findings** CRITICAL/HIGH/MEDIUM

## Kontext

Přečti si tyto soubory (v tomto pořadí):

### Plán (HLAVNÍ VSTUP — řídí vše co děláš)
1. `docs/plans/2026-03-06-scaffold-v2-implementation-plan.md` — implementační plán (PŘEČTI CELÝ)

### Design (reference — ověřuj že implementace odpovídá designu)
2. `docs/plans/2026-03-06-scaffold-v2-design.md` — schválený design

### Existující soubory které se MĚNÍ (přečti PŘED úpravou)
3. `commands/scaffold.md` — současný command (BUDE PŘEPSÁN)
4. `agents/scaffolder.md` — scaffolder agent (BUDE UPRAVEN)
5. `CLAUDE.md` — config contract, architecture (BUDE UPRAVEN)
6. `docs/reference/agents.md` — agent reference (BUDE UPRAVEN)
7. `docs/reference/commands.md` — command reference (BUDE UPRAVEN)
8. `docs/reference/pipelines.md` — pipeline reference (BUDE UPRAVEN)
9. `docs/reference/automation-config.md` — config reference (BUDE UPRAVEN)
10. `.claude-plugin/plugin.json` — verze (BUDE UPRAVEN)
11. `.claude-plugin/marketplace.json` — verze (BUDE UPRAVEN)
12. `tests/README.md` — test docs (BUDE UPRAVEN)
13. `docs/plans/README.md` — plan index (BUDE UPRAVEN)
14. `skills/bug-workflow.md` — routing skill (BUDE UPRAVEN)

### Existující soubory jako VZOR (přečti pro kontext, NEMĚŇ)
15. `commands/implement-feature.md` — vzor pro orchestraci
16. `agents/spec-analyst.md` — vzor pro agent formát
17. `agents/architect.md` — architect (scaffold v2 ho používá)
18. `agents/fixer.md` — fixer (scaffold v2 ho používá)
19. `agents/reviewer.md` — reviewer (scaffold v2 ho používá)
20. `agents/e2e-test-engineer.md` — e2e test (scaffold v2 ho používá)
21. `agents/rollback-agent.md` — rollback (scaffold v2 ho používá)
22. `agents/stack-selector.md` — stack-selector (--no-implement mód)
23. `tests/scenarios/happy-path.sh` — vzor pro test scénáře

### Existující test infrastruktura (přečti pro pochopení konvencí)
24. `tests/harness/run-tests.sh` — test runner
25. `tests/harness/mock-mcp-server.sh` — mock server

---

## Implementační proces

### Krok 1: Přečti plán

Přečti `docs/plans/2026-03-06-scaffold-v2-implementation-plan.md` CELÝ. Pochop všech 7 fází, všech 18 souborů, všechny detaily v P3 (agenti) a P4 (command).

### Krok 2: Implementuj Phase 0 (Config Contract)

Proveď všechny tasky 0.1–0.6 z plánu. Soubor: `CLAUDE.md`.

**Po dokončení Phase 0:**
- Ověř: CLAUDE.md je validní markdown
- Ověř: Agent count je 15, ne 13
- Ověř: Retry Limits tabulka obsahuje Spec iterations
- Ověř: Model Selection tabulka obsahuje spec-writer, spec-reviewer
- Ověř: Scaffold Pipeline diagram odpovídá v2 designu
- Commitni: `feat: scaffold v2 — phase 0: config contract extension`

### Krok 3: Implementuj Phase 1 (Noví agenti)

Vytvoř `agents/spec-writer.md` a `agents/spec-reviewer.md` přesně podle P3 v plánu.

**Po dokončení Phase 1:**
- Ověř: Oba soubory mají správný frontmatter (name, description, model: opus)
- Ověř: Sekce jsou v pořadí Goal → Expertise → Process → Constraints
- Ověř: Process kroky jsou číslované
- Ověř: Constraints začínají NEVER nebo definují hard limity
- Ověř: spec-writer má Block Comment Template v Constraints
- Ověř: spec-reviewer má APPROVE/REVISE verdikt formát
- Porovnej s `agents/spec-analyst.md` a `agents/reviewer.md` jako vzory — je formát konzistentní?
- Commitni: `feat: scaffold v2 — phase 1: spec-writer and spec-reviewer agents`

### Krok 4: Implementuj Phase 2 (Scaffolder úpravy)

Uprav `agents/scaffolder.md` podle tasků 2.1–2.3.

**Po dokončení Phase 2:**
- Ověř: Scaffolder stále funguje pro --no-implement mód (podmínkový vstup)
- Ověř: Nové volitelné sekce v CLAUDE.md generaci (E2E Test, Decomposition, Retry Limits)
- Ověř: Nový constraint pro scaffold v2 mód
- Ověř: Frontmatter se nezměnil (name, description, model: sonnet)
- Commitni: `feat: scaffold v2 — phase 2: scaffolder agent updates`

### Krok 5: Implementuj Phase 3 (Command přestavba)

Přepiš `commands/scaffold.md` podle P4 v plánu. Toto je NEJVĚTŠÍ změna.

**Po dokončení Phase 3:**
- Ověř: Frontmatter má aktualizovaný description
- Ověř: Flag parsing pokrývá VŠECHNY nové flagy (--template, --spec, --issue, --no-implement)
- Ověř: Flag validation zachytí mutually exclusive kombinace
- Ověř: --no-implement shortcut vede na v3.x flow (přesně jako starý scaffold.md)
- Ověř: Všech 10 kroků (Step 0–10) je definováno s jasnými vstupy/výstupy
- Ověř: Mode selection nabízí 3 možnosti (Interactive, YOLO with checkpoint, Full YOLO)
- Ověř: Spec-writer ↔ spec-reviewer loop má max iterations z Retry Limits
- Ověř: Block handler v Step 7 volá rollback-agent a reportuje do stdout
- Ověř: Step 9 (issue tracker) je podmíněný na TODO markery v CLAUDE.md
- Ověř: Step 10 (report) obsahuje VŠECHNY položky z designu (sekce 6, Step 10)
- Porovnej s `commands/implement-feature.md` — jsou patterns konzistentní?
- Commitni: `feat: scaffold v2 — phase 3: scaffold command rewrite`

### Krok 6: Implementuj Phase 4 (Testy)

Vytvoř 4 test scénáře a aktualizuj tests/README.md podle P6 v plánu.

**Po dokončení Phase 4:**
- Ověř: Všechny 4 scénáře existují v tests/scenarios/
- Ověř: Scénáře mají stejnou strukturu jako tests/scenarios/happy-path.sh
- Ověř: tests/README.md obsahuje všech 12 scénářů (8 starých + 4 nové)
- Ověř: Tabulka scénářů je konzistentní s existujícím formátem
- Commitni: `test: scaffold v2 — phase 4: test scenarios`

### Krok 7: Implementuj Phase 5 (Dokumentace)

Aktualizuj VŠECHNY referenční dokumenty podle tasků 5.1–5.5 v plánu.

**POZOR: Toto je kritická fáze. Dokumentace musí být 100% konzistentní se VŠÍM co bylo implementováno v Phase 0–4.**

**Po dokončení Phase 5:**
- Ověř `docs/reference/agents.md`:
  - Agent count je 15
  - Agent Overview tabulka má spec-writer a spec-reviewer
  - Plné entry pro oba nové agenty s příklady outputu
  - Scaffolder entry aktualizovaný
  - Model selection rationale aktualizovaný

- Ověř `docs/reference/commands.md`:
  - /scaffold entry má VŠECHNY nové flagy
  - Popis odpovídá novému chování
  - Příklad je aktuální

- Ověř `docs/reference/pipelines.md`:
  - Scaffold Pipeline sekce přepsána pro v2
  - Mermaid diagram obsahuje CELÝ v2 pipeline (mode → spec → skeleton → arch → impl → e2e → report)
  - Stage tabulka pokrývá všech 10 kroků
  - --no-implement legacy mód je zmíněn
  - Bug-Fix a Feature pipeline sekce NEZMĚNĚNY

- Ověř `docs/reference/automation-config.md`:
  - Retry Limits tabulka obsahuje Spec iterations
  - Quick reference tabulka aktualizovaná

- Ověř `skills/bug-workflow.md`:
  - Scaffold v2 triggery přidány

- Commitni: `docs: scaffold v2 — phase 5: reference documentation update`

### Krok 8: Implementuj Phase 6 (Release)

Plans index update. **Version bump až po kompletním review** (Krok R4).

**Co udělat:**
- Aktualizuj docs/plans/README.md — statusy pro scaffold v2 záznamy (design → IMPLEMENTED, plány → ARCHIVE)
- Commitni: `docs: scaffold v2 — phase 6: plans index update`

**Version bump NEDĚLEJ teď** — až po cross-review (viz Krok R5).

---

## Cross-Review po implementaci

### Review kritéria

Po dokončení VŠECH fází proveď kompletní cross-review:

#### R1: Konzistence počtů
- [ ] CLAUDE.md říká 15 agentů
- [ ] docs/reference/agents.md říká 15 agentů
- [ ] agents/ adresář obsahuje 15 souborů
- [ ] CLAUDE.md říká 23 commandů (nezměněno — scaffold je stále 1 command)
- [ ] docs/reference/commands.md říká 23 commandů
- [ ] plugin.json a marketplace.json mají shodnou verzi (4.0.0 po Kroku R5)

#### R2: Agent konzistence
- [ ] spec-writer.md frontmatter: name=spec-writer, description neprázdné, model=opus
- [ ] spec-reviewer.md frontmatter: name=spec-reviewer, description neprázdné, model=opus
- [ ] Oba mají Goal → Expertise → Process → Constraints pořadí
- [ ] Oba jsou zmíněni v CLAUDE.md Model Selection tabulce (opus řádek)
- [ ] Oba jsou v docs/reference/agents.md Agent Overview tabulce
- [ ] Oba mají plné entries v docs/reference/agents.md s example output

#### R3: Command konzistence
- [ ] scaffold.md frontmatter: description aktualizovaný, allowed-tools nezměněné
- [ ] scaffold.md: --no-implement flow přesně odpovídá starému scaffold.md (kroky 1-6)
- [ ] scaffold.md: všech 10 kroků má jasné vstupy a výstupy
- [ ] scaffold.md: flag validation pokrývá VŠECHNY kombinace z designu sekce 3
- [ ] docs/reference/commands.md /scaffold entry odpovídá scaffold.md

#### R4: Pipeline konzistence
- [ ] docs/reference/pipelines.md Scaffold v2 pipeline odpovídá scaffold.md orchestraci
- [ ] Mermaid diagram v pipelines.md má VŠECHNY kroky z scaffold.md
- [ ] Stage tabulka v pipelines.md odpovídá agentům použitým v scaffold.md
- [ ] CLAUDE.md Scaffold Pipeline diagram odpovídá scaffold.md

#### R5: Config konzistence
- [ ] CLAUDE.md Config Contract → Retry Limits obsahuje Spec iterations: 5
- [ ] docs/reference/automation-config.md Retry Limits tabulka obsahuje Spec iterations
- [ ] scaffolder.md generuje Spec iterations v Retry Limits sekci
- [ ] scaffold.md čte Spec iterations z Retry Limits (default 5)

#### R6: Test konzistence
- [ ] 4 nové test scénáře existují
- [ ] tests/README.md obsahuje VŠECH 12 scénářů
- [ ] Scénáře odpovídají P6 z implementačního plánu

#### R7: Dokumentace úplnost
- [ ] ŽÁDNÝ soubor nezmiňuje "13 agentů" (musí být 15)
- [ ] Verze v plugin.json/marketplace.json je 4.0.0 (po Kroku R5)
- [ ] VŠECHNY nové flagy (--template, --spec, --issue, --no-implement) jsou zdokumentované v commands.md
- [ ] spec/ folder konvence je zmíněna v CLAUDE.md
- [ ] Brainstorm dokument `docs/plans/brainstorm/04-scaffold-completeness.md` se NEMĚNIL

#### R8: Formátování
- [ ] Žádné rozbité markdown tabulky
- [ ] Žádné nekončící code bloky
- [ ] Konzistentní heading hierarchie ve VŠECH souborech
- [ ] Mermaid diagramy jsou syntakticky validní

### Review proces

#### Krok R1: Proveď VŠECHNY checky z R1–R8

Pro KAŽDÝ neúspěšný check zapiš finding:

```
### Finding F{N}
- **Soubor:** {cesta}
- **Severity:** CRITICAL | HIGH | MEDIUM | LOW
- **Kategorie:** R{N}
- **Popis:** Co je špatně
- **Oprava:** Přesná změna
```

#### Krok R2: Oprav VŠECHNY CRITICAL, HIGH, MEDIUM findings

Proveď opravy. Commitni: `fix: scaffold v2 cross-review — iteration {N}`

#### Krok R3: Opakuj od R1

Přečti VŠECHNY změněné soubory znovu. Proveď review znovu se VŠEMI kritérii R1–R8.

**Opakuj dokud iterace nenajde ZERO findings CRITICAL/HIGH/MEDIUM.**

#### Krok R4: Finální report

```
## Implementation & Review Complete

Phases implemented: 7 (Phase 0–6)
Files created: {N}
Files modified: {N}
Commits: {N}
Review iterations: {N}
Final findings: {N} CRITICAL, {N} HIGH, {N} MEDIUM, {N} LOW
All CRITICAL/HIGH/MEDIUM resolved: Yes
```

#### Krok R5: Version bump

Až TEPRVE po úspěšném review (ZERO CRITICAL/HIGH/MEDIUM) spusť version bump:

```
/ceos-agents:version-bump major
```

Tím se verze zvedne na 4.0.0 v plugin.json i marketplace.json a vytvoří se commit + tag.

**Status po R5: v4.0.0 RELEASED**

---

## Pravidla

- Implementuj PŘESNĚ podle plánu — nepřidávej nic navíc, nevynechávej nic
- Každá fáze = 1 commit (celkem 7 implementačních commitů + N review commitů)
- NEMĚŇ soubory které nejsou v inventáři (P1) — pokud najdeš nesrovnalost, zapiš finding
- NEMĚŇ design dokument ani implementační plán — jsou read-only reference
- Pokud plán říká něco co nedává smysl nebo je v rozporu s designem — ZASTAV SE a reportuj
- Review musí být PŘÍSNÝ — hledej díry, nekonzistence, chybějící detaily
- LOW findings zapiš ale neopravuj (pokud je to čistě kosmetické)
- VŽDY čti soubor PŘED úpravou — nikdy neupravuj soubor který jsi nečetl v této session
