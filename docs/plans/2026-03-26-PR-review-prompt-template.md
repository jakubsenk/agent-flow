# PR Review & Integration Prompt Template

Use this prompt to review and integrate external PRs into the ceos-agents plugin.

---

## Prompt

```
Potřebuju zpracovat PR: {PR_URL}

Kontext:
- Autor: {jméno} (ne já)
- Plugin je klíčový, nesmí se rozbít
- PR může mít konflikty s aktuálním main

Úkoly (v tomto pořadí):

1. ANALÝZA PR
   - Stáhni PR metadata (Gitea API: /pulls/{N})
   - Stáhni diff (/pulls/{N}.diff)
   - Stáhni issue komentáře (/issues/{N}/comments)
   - Stáhni review komentáře (/pulls/{N}/reviews + /pulls/{N}/reviews/{id}/comments)
   - Identifikuj změněné soubory a rozsah změn

2. REVIEW KOMENTÁŘE
   - Projdi všechny review komentáře
   - Pro každý komentář ověř v diffu, zda byl adresován
   - Vytvoř tabulku: Finding → Status (FIXED / NOT FIXED / PARTIAL)

3. KONTROLA KOMPATIBILITY
   - Ověř že změny neporušují:
     a) Agent definition format (frontmatter, Goal/Expertise/Process/Constraints structure)
     b) Config Contract (required vs optional sections, table format)
     c) Versioning Policy (MAJOR/MINOR/PATCH triggers)
     d) Pipeline consistency (commands dispatch correct agents)
     e) Existing test suite passes

4. KONFLIKTY
   - Fetch PR branch, test-merge s main
   - Pro každý konflikt: identifikuj příčinu, navrhni řešení
   - Vyřeš konflikty

5. TESTY
   - Spusť ./tests/harness/run-tests.sh
   - Pokud failne: identifikuj příčinu a oprav

6. VÝSTUP
   - Ulož review report do docs/plans/
   - Commitni merge resolution
   - Pushni branch zpět na origin
   - NEMERGUJ do main — nech na manuální review

7. VERZE
   - Posouď zda PR vyžaduje MAJOR/MINOR/PATCH bump
   - Nový required config key = MAJOR
   - Nový optional config key/section = MINOR
   - Behavior fix = PATCH
```

---

## Pending PRs (as of 2026-03-26)

| PR | Title | Branch | Author | Mergeable | Notes |
|----|-------|--------|--------|-----------|-------|
| #1 | improved root cause/ticket analysis | analysis-improvements | vludwig | YES (resolved) | Review done, conflicts resolved, pushed |
| #2 | added codegraph examples | codegraph-examples | vludwig | YES | Likely small — new example files |
| #3 | added traceId to commands | trace-id | vludwig | NO (conflicts) | Commands changed since PR was created |
