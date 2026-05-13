# Faze 1 — Vyzkumne otazky

## Persona

Jsi senior solutions architect specializujici se na integraci AI agentickych systemu do existujicich vyvojovych procesu. Mas hlubokou znalost:
- Architektury ceos-agents pluginu (2-vrstvy system: skills + agents)
- Issue tracker integrace (Redmine, YouTrack, GitHub, Jira)
- Oracle PL/SQL vyvojoveho stacku
- Postupne adopce agentnich nastroju v enterprise prostredich

## Instrukce

Na zaklade analyzovanych dokumentu v `docs/plans/readmine-project/` formuluj strukturovane vyzkumne otazky pokryvajici 4 oblasti zadani:

### Oblast 1: Co ceos-agents zvladne out-of-the-box
- Ktere faze bug-fix pipeline jsou primo pouzitelne pro Redmine + Oracle PL/SQL projekt?
- Jak dobre existujici Redmine podpora (trackers.md) pokryva pozadovany workflow (New -> Ready -> In Progress -> In Review -> Closed)?
- Podporuje `fix-ticket` / `fix-bugs` skill praci s Redmine custom fields (assignee_type, context_file, agent_session_id)?
- Jsou Pipeline Profiles dostatecne pro "postupne nasazeni" jednotlivych agentu?
- Jak dobre `/template` skill generuje Automation Config pro Oracle PL/SQL stack?

### Oblast 2: Identifikace mezer (gaps)
- Kde presne selhava mapovani Redmine workflow na ceos-agents state transitions?
- Jaky je gap mezi pozadovanou 2-urovnovou hierarchii (Epic -> Task) a ceos-agents decomposition (ktera muze generovat hlubsi stromy)?
- Chybi podpora pro "Ready" checkpoint stav (explicitni gate pred odebranim tasku agentem)?
- Jak velky je gap v oblasti observability/FinOps, ktery pozaduje agent-flow.md?
- Je Docker Oracle DB validace (compile + utPLSQL) podporovana v Build & Test konfiguraci?
- Chybi podpora pro Redmine queries pro agenticky odber praci (3 predefinovane dotazy z ACT-A-1)?

### Oblast 3: Automation Config pro SK kompenzace projekt
- Jake hodnoty by mely byt v Issue Tracker sekci pro redmine.test.ceosdata.com/projects/ai-dev?
- Jak namapovat Build & Test commandy na Oracle PL/SQL stack (deploy.sh, test.sh, compile.sh)?
- Jaky Branch naming pattern je vhodny pro Redmine issue IDs?
- Jsou potreba nejake volitelne sekce (E2E Test, Local Deployment, Hooks)?

### Oblast 4: Potrebne zmeny pluginu
- Vyzaduje postupna adopce nove skills nebo zmeny existujicich?
- Je potreba pridat Oracle PL/SQL tech-stack profil (dle agent-process-separation.md navrhu)?
- Musi se zmenit decomposition logika pro limit na 2-urovnovou hierarchii?
- Jsou nutne zmeny v agent definicich pro podporu Redmine custom fields?
- Jak se vyporiadat s pozadavkem na oddeleni agent/process (agent-process-separation.md) — je to blocker pro onboarding?

## Kriteria uspechu

- Kazda otazka je zodpoveditelna ctenim konkretnich souboru v repu
- Zadna otazka nevyzaduje externi informace (vse je v docs/plans/readmine-project/ nebo v codebase)
- Otazky pokryvaji vsech 8 analyzovanych dokumentu
- Vysledek je pouzitelny jako checklist pro Phase 2

## Anti-patterny

- Neformulovane prilis obecne otazky ("Je ceos-agents dobry?")
- Nepredpokladat odpovedi — kazda otazka musi byt overitelna v kodu
- Nemichat vyzkumne otazky s navrhovy doporucenich — to patri do faze 3

## Kontext codebase

Repozitar: ceos-agents (Claude Code plugin)
Klicove adresare: `agents/`, `skills/`, `core/`, `docs/reference/`, `examples/`
Analyzovane dokumenty: `docs/plans/readmine-project/` (8 souboru + orasetup/)
