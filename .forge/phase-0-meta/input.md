Připravuji OSS plugin "agent-flow" na první veřejný GitHub release jako v1.0.0.

## Kontext

Jde o Claude Code plugin pro automatizaci bug-fix a feature workflows (issue tracker → fix → PR pipeline). Dosud byl vyvíjen interně pod názvem "ceos-agents" (verze v6.x–v10.2.0). Pro veřejný release jde o čistý restart jako v1.0.0.

Working directory: C:\gitea_agent-flow (kopie interního Gitea archivu)
Canonical GitHub repo: https://github.com/asysta-act/agent-flow

## Rozhodnutí (všechna finální, neměnit)

- Plugin name: ceos-agents → agent-flow
- Skill prefix: ceos-agents: → agent-flow:
- Verze: reset na 1.0.0
- Git historie: bude řešena orphan commitem při push (mimo scope tohoto tasku)

## Co je potřeba udělat

### Přejmenování (mechanické, ale rozsáhlé)
- ceos-agents → agent-flow ve všech souborech (plugin.json, marketplace.json, CLAUDE.md, všechny skill soubory, agents/, core/, docs/)
- skill prefix ceos-agents: → agent-flow: všude kde se vyskytuje
- [ceos-agents] v Block Comment Template → [agent-flow]
- ceos-agents-block webhook payload name → agent-flow-block
- plugin.json:repository → https://github.com/asysta-act/agent-flow
- plugin.json:version + marketplace.json:version → 1.0.0

### Smazat
- .forge.bak-*/ (všechny adresáře)
- .forge/ (aktuální run — po dokončení pipeline)
- docs/plans/ (celá složka)
- docs/superpowers/ (celá složka)
- skills/version-bump/ (interní nástroj, ne pro komunitu)
- grep.exe.stackdump
- nul
- REVIEW-REPORT-*.md (root level)

### Přidat do .gitignore
- .forge/
- .forge.bak-*/
- .forge.v*/
- .ceos-agents/
- .claude/
- *.stackdump
- nul
- REVIEW-REPORT-*.md
- docs/plans/

### Verze a changelog
- CHANGELOG.md: kompletně přepsat, začít čistě od v1.0.0
- Všechny výskyty starých verzí (v6.x, v7.x, v8.x, v9.x, v10.x) v souborech odstranit nebo nahradit neutrálním textem
- V agent souborech: "v9.0.0+, mandatory" / "v10.0.0+, mandatory" labely → nahradit "mandatory" bez verze

### Roadmapa
- Přesunout docs/plans/roadmap.md → docs/roadmap.md
- Kompletně přepsat pro komunitu

### README.md
- Přepsat jako marketing-grade OSS dokument

### SECURITY.md
- Primární kontakt: filip.sabacky@ceosdata.com
- Sekundární: GitHub Security Advisories
- Supported versions: jen v1.0.0+

### CLAUDE.md
- Sanitizovat: odstranit interní verze reference, forge poznámky

## Co zachovat beze změny
- agents/, skills/, core/ (obsah, jen rename prefix v textu)
- tests/, checklists/, state/, examples/, hooks/
- docs/guides/, docs/reference/, docs/architecture.md
- .gitea/, .github/
- LICENSE, CODE_OF_CONDUCT.md, CONTRIBUTING.md
