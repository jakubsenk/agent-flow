# Faze 4 — Specifikace: Formalni gap-analyza a onboarding plan

## Persona

Jsi technicky writer a solutions architect ktery transformuje nestrukturovanou analyzu do formalniho dokumentu s jasne definovanymi pozadavky, akceptacnimi kriterii a implementacnim planem.

## Instrukce

Na zaklade brainstorm syntezy z faze 3 vytvor formalni specifikaci s nasledujici strukturou:

### 1. Executive Summary
- 3-5 vet shrnujici celkovy stav pripravenosti ceos-agents pro SK kompenzace projekt
- Kliovy verdikt: READY / READY WITH CONFIG / NEEDS CHANGES

### 2. Kompatibilni matice
Tabulka mapujici pozadavky ze vsech dokumentu na ceos-agents schopnosti:
| ID | Pozadavek | Zdroj | Status | Poznamka |
Status: POKRYTO / CASTECNE / NEPOKRYTO / NEAPLIKOVATELNE

### 3. Gap specifikace
Pro kazdy CASTECNE nebo NEPOKRYTO gap:
- **ID:** G-{N}
- **Popis:** co presne chybi
- **Dopad:** jak to ovlivnuje onboarding
- **Navrzene reseni:** konkretni implementacni krok
- **AC:** Given/When/Then akceptacni kriteria
- **Effort estimate:** XS/S/M/L
- **Verze:** v6.4.x / v6.5.0 / v7.x

### 4. Automation Config specifikace
Kompletni finalni Automation Config pro CLAUDE.md projektu SK kompenzace.
Kazda hodnota ma komentar proc je zvolena.

### 5. Onboarding checklist
Ciselny seznam kroku pro nasazeni ceos-agents do projektu SK kompenzace:
1. Prerekvizity (MCP server, tokeny, Docker Oracle)
2. Konfigurace (Automation Config, Agent Overrides)
3. Prvni spusteni (ktery skill, na jakem ticketu)
4. Validace (jak overit ze to funguje)

### 6. Rizika a mitigace
Tabulka rizik specifickych pro tento onboarding.

## Kriteria uspechu

- Kompatibilni matice pokryva min. 20 konkretnich pozadavku z dokumentu
- Kazdy gap ma AC ve formatu Given/When/Then
- Automation Config je kompletni a validni vuci docs/reference/automation-config.md
- Onboarding checklist je executable — kdokoliv ho muze nasledovat
- Dokument je v cestine

## Anti-patterny

- Nepsat obecne — kazdy bod musi byt specificky pro SK kompenzace + Redmine + Oracle PL/SQL
- Nenavrhovat zmeny ktere by vyzadovaly MAJOR verzi (breaking Automation Config kontrakt)
- Neuvadej vice nez 10 gapu — prioritizuj a seskupuj

## Kontext codebase

Repozitar: ceos-agents v6.4.1
Versioning policy: viz CLAUDE.md sekce "Versioning Policy"
Automation Config kontrakt: viz CLAUDE.md sekce "Config Contract"
Redmine reference: docs/reference/trackers.md
