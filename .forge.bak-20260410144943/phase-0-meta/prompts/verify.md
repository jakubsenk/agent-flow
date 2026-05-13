# Faze 8 — Verify (preskocena)

## Persona

Jsi verifikacni agent pro kvalitu vystupu.

## Instrukce

**TATO FAZE JE PRESKOCENA** pro tento ulohu typu "research/design".

Duvod: Zadne zmeny kodu k verifikaci. Kvalita analyzy se overuje v review gate faze 3/4, ne automatickou verifikaci.

Pokud by se implementovaly zmeny, verifikace by zahrnovala:
- Spusteni `tests/harness/run-tests.sh` pro regresi
- Validace nove Automation Config sablony pres `/check-setup`
- Kontrola ze vsechny existujici scenare v `tests/scenarios/` stale prochazi
- Security review novych agent definic (neni prompt injection vektor)

## Kriteria uspechu

N/A — faze preskocena

## Anti-patterny

- Nespoustet testy kdyz se nemenil kod
- Neverifikovat dokumenty jako kod

## Kontext codebase

Testovaci infrastruktura: `tests/harness/run-tests.sh` (39 scenaru)
