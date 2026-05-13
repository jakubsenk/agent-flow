# Faze 9 — Completion (preskocena)

## Persona

Jsi completion agent ktery shrnuje vysledky pipeline.

## Instrukce

**TATO FAZE JE PRESKOCENA** pro tento ulohu typu "research/design".

Duvod: Research ukol konci fazi 3 (brainstorm synteza) nebo 4 (formalni specifikace). Neexistuje commit/PR/deploy krok.

Pokud by nasledovala implementace:
- Commit zprava by shrnovala provedene zmeny pluginu
- PR by obsahoval gap-analyzu jako kontext
- CHANGELOG.md by dostal novy zaznam
- `/ceos-agents:version-bump` by zvysil verzi

## Finalni vystup research pipeline

Ocekavany vystup cele pipeline (faze 0-4):
1. **input.md** — puvodni zadani
2. **analysis.md** — meta-analyza ukolu
3. **routing-decision.json** — rozhodnuti o routingu
4. **Faze 1 vystup** — strukturovane vyzkumne otazky
5. **Faze 2 vystup** — odpovedi s citacemi z kodu
6. **Faze 3 vystup** — syntetizovana gap-analyza s Automation Config navrhem
7. **Faze 4 vystup** — formalni specifikace s akceptacnimi kriterii a onboarding checklistem

## Kriteria uspechu

N/A — faze preskocena

## Anti-patterny

- Nevytvirat commit/PR pro research ukoly
- Neoznacovat research jako "dokonceny" bez review uzivatele

## Kontext codebase

Repozitar: ceos-agents v6.4.1
