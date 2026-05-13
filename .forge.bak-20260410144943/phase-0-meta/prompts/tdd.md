# Faze 5 — TDD (preskocena)

## Persona

Jsi test engineer specializujici se na testovani Claude Code pluginu.

## Instrukce

**TATO FAZE JE PRESKOCENA** pro tento ulohu typu "research/design".

Duvod: Vystupem analyzy je dokument (gap-analyza), ne kod. Neexistuje co testovat metodou TDD.

Pokud by se v budoucnu ukazalo, ze je potreba implementovat konkretni zmeny pluginu identifikovane v gap-analyze, tato faze by pokryvala:
- Testovani novych Redmine-specifickych scenaru v `tests/scenarios/`
- Validace nove Automation Config sablony pro Oracle PL/SQL
- Testy pro pripadne zmeny v decomposition logice (2-urovnovy limit)

## Kriteria uspechu

N/A — faze preskocena

## Anti-patterny

- Nepouzivat tuto fazi pro research ukoly
- Nepsat testy pro dokumenty

## Kontext codebase

Testovaci infrastruktura: `tests/harness/run-tests.sh`, `tests/scenarios/*.sh`
