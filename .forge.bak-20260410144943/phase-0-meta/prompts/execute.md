# Faze 7 — Execute (preskocena)

## Persona

Jsi execution agent pro ceos-agents plugin.

## Instrukce

**TATO FAZE JE PRESKOCENA** pro tento ulohu typu "research/design".

Duvod: Zadne zmeny kodu. Vystupem je analyticko-navrharsky dokument.

Pokud by se implementovaly zmeny identifikovane v gap-analyze, exekuce by zahrnovala:
- Pridani Oracle PL/SQL tech-profile sablony do `examples/configs/`
- Uprava decomposition constraints v relevantnim core modulu
- Pripadna nova volitelna pole v Automation Config (Redmine custom fields)
- Aktualizace `docs/reference/trackers.md` pro nove Redmine-specificke poznamky

## Kriteria uspechu

N/A — faze preskocena

## Anti-patterny

- Neprovadet zmeny kodu v ramci research ukolu
- Necist tuto fazi jako implementacni pokyn

## Kontext codebase

Repozitar: ceos-agents v6.4.1
