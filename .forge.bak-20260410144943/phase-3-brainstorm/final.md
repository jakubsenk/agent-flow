# Fáze 3 — Syntéza brainstormu

**Pipeline:** forge-2026-04-10-001
**Perspektivy:** Konzervativní, Inovativní, Skeptická

---

## Shoda napříč perspektivami

### Všichni souhlasí:
1. **Onboarding je proveditelný** — 3 soubory v projektu, 0 nutných změn v pluginu
2. **Redmine integrace funguje** — query, state transitions, sub-issues nativně
3. **Build/Test je agnostické** — deploy.sh/test.sh fungují jako shell stringy
4. **Agent Overrides stačí** — Oracle specifika bez změny agent definic
5. **Agent-process separation NENÍ blocker**
6. **CEO prezentaci zakládat na hotových výsledcích**, ne na živé ukázce

### Klíčový spor: tempo nasazení

| Perspektiva | Doporučené tempo | Timeline do prvního výsledku |
|-------------|-----------------|------------------------------|
| Konzervativní | Suchý běh → 1 ticket → 3-5 ticketů → prezentace | 7-10 dní |
| Inovativní | Quick win demo → postupná adopce 4 fází | 1-2 dny |
| Skeptická | Fáze A (bez pluginu) → B (analyze-bug) → C (pipeline) | 3-4 týdny |

### Doporučený kompromis:
**2 fáze:**
1. **Příprava + dry-run** (2-3 dny): Template, CLAUDE.md, Agent Overrides, check-setup, analyze-bug na 2-3 ticketech
2. **Kontrolovaný ostrý běh** (2-3 dny): fix-ticket na 3-5 jednoduchých bugech s lidským review

Skeptikovy obavy (Docker nestabilita, MCP spolehlivost, PL/SQL chyby) adresovat **přípravnou fází** — ne odkládáním celého onboardingu.

---

## Opravená matice mezer (po diskuzi s uživatelem)

| Gap | Původní závažnost | Opravená závažnost | Důvod |
|-----|-------------------|--------------------|-------|
| Custom fields (assignee_type) | Kritická | **VYŘEŠENO** | `assigned_to_id=me` v Bug query |
| Stav „Ready" | Vysoká | **VYŘEŠENO** | Namapovat na reálné Redmine stavy |
| Agent-process separation | Vysoká | **NEPOTŘEBNÉ** | Future enhancement |
| Status name→ID mapování | Kritická | Střední | Agent Override s explicitním mapováním |
| Token tracking | Vysoká | Vysoká | Zůstává — heuristiky ±50% |
| Hard cost ceiling | Vysoká | Střední | Retry limity jako proxy + konzervativní nastavení |
| NEEDS_DECOMPOSITION v subtask | Vysoká | Nízká | Nepoužívat decomposition na začátku |
| Standalone agents | Vysoká | Střední | /analyze-bug jako entry point |

---

## Konkrétní úkoly (výstup pro Phase 4)

### Úkol 1: Nová šablona v pluginu
- Soubor: `examples/configs/redmine-oracle-plsql.md`
- Aktualizace: `skills/template/SKILL.md` — přidat řádek do tabulky
- Verze: MINOR bump (v6.5.0) pokud se přidá

### Úkol 2: Příprava projektu SK kompenzace
- Repo: `C:\gitea_drmax-readmine-test`
- Soubory: CLAUDE.md, customization/fixer.md, customization/test-engineer.md
- Postup: `/ceos-agents:template redmine-oracle-plsql` → ruční úprava

### Úkol 3: Infrastrukturní prerekvizity
- Docker uživatel bez sudo
- MCP server Redmine nakonfigurovaný + ověřený
- Vzorové utPLSQL testy v repo

### Úkol 4: Validace (dry-run)
- `/ceos-agents:check-setup`
- `/ceos-agents:analyze-bug` na 2-3 ticketech
- Ověřit state transitions na Redmine instanci

### Úkol 5: Formální analýza pro CEO
- Strukturovaný dokument s matricí kompatibility, gap analýzou, roadmapou
- = Phase 4 tohoto pipeline

---

## Klíčová čísla pro CEO prezentaci (z inovativní perspektivy)

- **15 minut** od ticketu k PR (na jednoduchém bugu)
- **8x ROI** konzervativní odhad za 3 měsíce
- **70-90%** úspěšnost na XS/S bugech
- **$2-8** za typický bug fix (API náklady)
- **6 trackerů, 19 agentů, 26 skills** — enterprise-ready

## Rizika pro CEO prezentaci (ze skeptické perspektivy)

- **40-60%** pravděpodobnost selhání živé ukázky → mít fallback (předtočené demo)
- **$7-26** za ticket (ne $2-8) při reálném běhu s iteracemi
- **31 hodin** realistický čas na rozjezd (ne „pár hodin")
- **70%+ chybovost** na složitých PL/SQL features → začít s jednoduchými bugy
