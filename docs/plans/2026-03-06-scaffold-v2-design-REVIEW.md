# Design Review — Scaffold v2

> **Pro Claude:** Použij `superpowers:requesting-code-review` skill. Toto je iterativní review loop — opakuj dokud není ZERO findings CRITICAL/HIGH/MEDIUM.

---

## Co reviewuješ

Jeden soubor: `docs/plans/2026-03-06-scaffold-v2-design.md`

Toto je design dokument pro scaffold v2 — kompletní přestavba `/scaffold` commandu. NENÍ to kód, je to architektonický návrh. Reviewuj ho jako design, ne jako implementaci.

## Kontext

Přečti si tyto soubory pro kontext (NEMĚŇ je):

1. `CLAUDE.md` — architektura pluginu, config contract, agent format, versioning policy
2. `docs/plans/brainstorm/04-scaffold-completeness.md` — původní brainstorm s gap analýzou
3. `commands/scaffold.md` — současný scaffold command
4. `commands/implement-feature.md` — feature pipeline (scaffold v2 z něj přebírá agenty)
5. `agents/spec-analyst.md` — současný spec-analyst (scaffold v2 ho NEPOUŽÍVÁ, má nové agenty)
6. `agents/architect.md` — architect agent (scaffold v2 ho používá pro decomposition)
7. `agents/fixer.md` — fixer agent (scaffold v2 ho používá pro implementaci)
8. `agents/reviewer.md` — reviewer agent
9. `agents/scaffolder.md` — scaffolder agent
10. `agents/e2e-test-engineer.md` — e2e test agent

## Review kritéria

### K1: Konzistence s existující architekturou

- Respektuje 2-layer systém (commands = orchestrace, agents = specialisté)?
- Noví agenti (spec-writer, spec-reviewer) dodržují agent definition format (frontmatter + Goal/Expertise/Process/Constraints)?
- Model selection odpovídá konvencím (opus pro kritické rozhodování, sonnet pro analýzu, haiku pro mechanické)?
- Neporušuje existující config contract?

### K2: Pipeline konzistence

- Navazuje na existující pipeline patterns (fix-bugs, implement-feature)?
- Retry limity a failure handling jsou konzistentní s existujícími defaults?
- Block comment template se používá správně?
- Rollback-agent integrace je konzistentní?

### K3: Úplnost

- Jsou pokryty všechny edge cases? (prázdný popis, neplatný --spec, selhání uprostřed pipeline)
- Jsou definovány všechny vstupy a výstupy každého kroku?
- Chybí nějaký krok v pipeline?
- Jsou specifikační šablony kompletní (REQUIRED vs IF APPLICABLE)?

### K4: Technická proveditelnost

- Je pipeline realizovatelný v pure markdown architektuře (žádný runtime kód)?
- Jsou kontextová okna agentů zvládnutelná (spec-writer/reviewer s celou spec složkou)?
- Je Playwright MCP integrace realistická (krok 10)?
- Dávkování features — je batch size 2-3 dostatečný/přílišný?

### K5: Zpětná kompatibilita

- Existující `/scaffold` chování je zachováno (--no-implement)?
- `/scaffold-add` a `/scaffold-validate` nejsou rozbité?
- Versioning impact je správně posouzený (MAJOR bump)?

### K6: Spec šablona kvalita

- Jsou REQUIRED sekce opravdu nezbytné?
- Jsou IF APPLICABLE sekce správně kategorizované?
- Jsou acceptance criteria v epic šabloně dostatečně specifikované?
- Je folder layout (`spec/`) logický a škálovatelný?

### K7: YAGNI

- Není něco overengineered?
- Jsou future extensions správně odložené?
- Není v designu něco co vypadá užitečně ale reálně se nepoužije?

### K8: Chybějící rozhodnutí

- Jsou v dokumentu nevyřešené otázky které by měly být rozhodnuty?
- Existují implicitní předpoklady které nejsou explicitně uvedeny?
- Jsou hranice mezi kroky jasně definované (co je vstup/výstup)?

## Review proces

### R1: Přečti design dokument celý

Přečti `docs/plans/2026-03-06-scaffold-v2-design.md` od začátku do konce.

### R2: Přečti kontextové soubory

Přečti všech 10 kontextových souborů uvedených výše. Porovnej design s realitou codebase.

### R3: Zapiš findings

Pro KAŽDÝ finding zapiš:

```
### Finding F{N}

- **Sekce:** {která sekce designu}
- **Severity:** CRITICAL | HIGH | MEDIUM | LOW
- **Typ:** K{N} ({název kritéria})
- **Popis:** Co je špatně
- **Návrh opravy:** Konkrétní text/změna
```

Severity definice:
- **CRITICAL** — design je nerealizovatelný nebo fundamentálně rozporný
- **HIGH** — chybějící klíčový krok, nekonzistence s architekturou, selhání v edge case
- **MEDIUM** — nepřesnost, chybějící detail, slabé zdůvodnění
- **LOW** — kosmetické, formulace, formátování

### R4: Oprav CRITICAL a HIGH

Okamžitě oprav v design dokumentu. Nový commit: `fix: scaffold v2 design review — iteration {N}`.

### R5: Oprav MEDIUM

Oprav v design dokumentu. Commitni spolu s CRITICAL/HIGH opravami.

### R6: Opakuj od R1

Přečti opravený dokument znovu. Proveď review znovu se VŠEMI kritérii. Opakuj dokud iterace nenajde **ZERO findings CRITICAL/HIGH/MEDIUM**.

LOW findings zapiš ale neopravuj.

### R7: Finální report

```
## Design Review Complete

Review iterations: {počet}
Final findings: {počet} CRITICAL, {počet} HIGH, {počet} MEDIUM, {počet} LOW
All CRITICAL/HIGH/MEDIUM resolved: Yes

Status: DESIGN APPROVED — ready for implementation plan
```

## Pravidla

- NEMĚŇ kontextové soubory — pouze design dokument
- NEMĚŇ scope designu — nesmíš přidávat nové features
- Pokud najdeš fundamentální problém v designu který vyžaduje rozhodnutí vlastníka → zapiš ho jako CRITICAL finding s návrhem opravy, ale NEOPRAVUJ ho sám. Vypiš report a ZASTAV SE.
- Formátování: design dokument musí zůstat čitelný markdown (žádné rozbité tabulky, nekončící code bloky)
- Review MUSÍ být přísný — neschvaluj design jen proto že "vypadá dobře". Hledej díry.
