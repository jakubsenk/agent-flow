# AI vývoj - koncept
## Zadání:

* jak by měla vypadat ideální struktura projektu a tasků v issue trackeru (Redmine) s tím že cílem je 
  * zachovat jednoduchost 
  * udržet přehlednost o stavu projektu a postupu vývojových prací 
  * zároveň udržovat flexibilitu pro úpravu/přidávání nových tasků
* Předpoklad:
  * iniciální vytvoření celé WBS provede (asistovaně) AI agent 
  * agenti budou schopni z issue trackeru (Redmine) odebírat tasky pro zpracování podle předem připravených dotazů

## Návrh řešení:

Klíčová myšlenka udržet **dvouúrovňovou hierarchii** (Epic → Task) místo složitých víceúrovňových stromů, přidání strojově čitelných identifikátorů pro agenty, a jasné oddělení "agent-ready" vs. "human-required" stavů.

![](obrazek.png){width=70%}

## Doporučená struktura — klíčové principy

**Hierarchie: jen 2 úrovně** Epic (milestone/modul) → Task. Žádné sub-tasky, žádné Stories jako mezistupeň. Agent potřebuje atomické, jednoznačně definované jednotky práce — ne stromový labyrint.

**Tři custom fields jsou základ:**

* `assignee_type` — hodnoty `agent | human | both`. Toto je hlavní filtr pro agent queue, bez něj se nedá selektivně přiřazovat práce.
* `context_file` — cesta k `CONTEXT.md` souboru v repozitáři, který agent přečte před zahájením práce. Sem patří architekturální rozhodnutí, konvence projektu, relevantní části kódu.
* `agent_session_id` — UUID session Claude Code, který task zpracovával. Klíčové pro dohledatelnost a debugování.

**Životní cyklus tasků:** `New → Ready → In Progress → In Review → Closed`

Přechod `New → Ready` je záměrný checkpoint — ověření, že jsou splněné závislosti a task má dostatečný popis pro agenta. Agent si vybírá pouze ze stavů `Ready`. `In Review` vždy projde člověkem, i když task zpracoval agent.

**Konvence pojmenování:** Název = akce + doméná + jasně definovaný výstup. Agent nemůže číst mezi řádky — "JWT stuff" nestačí, "Implement JWT refresh endpoint → returns 200 + new token pair" ano. V popisu pak acceptance criteria ve formátu Given/When/Then.

**Doporučené Redmine dotazy pro agenta:** Agent by měl mít předpřipravené 3 dotazy: (1) "dej mi práci" — Ready + assignee_type=agent, seřazeno priorita/stáří; (2) "co mám teď otevřeného" — In Progress + agent_session_id=`{current}`; (3) "co čeká na review po mně" — In Review s mými commity.

**Iniciální WBS generování Claudem:** Claude dostane dokument s požadavky + šablonu pro Redmine API a vygeneruje JSON pro hromadný import tasků přes `/issues.json`. Každý task hned dostane correct `assignee_type` na základě povahy práce (implementace = agent, architekturální rozhodnutí = human, testování = agent, code review = human).

## Klíčová myšlenka: Epic není kontejner na neomezené množství tasků 

Otázka/problém: 

* Jak se bude provádět rozpad Epic na Tasky
* Pokud bude Epic příliš rozsáhlý nebude v tom chaos? 
* Jaký je best-practice pro agentic development

Epic je **časový/tematický bucket s jasnou hranicí**. Chaos nastane ne kvůli počtu tasků, ale kvůli špatnému rozptylu granularity a chybějící struktuře pro agenta. Následuje příklad toho, jak správně dekomponovat Epic a jak by měl vypadat ideální task pro Claude Code.

![](obrazek1.png){width=70%}

## Best practices pro agentic dekompozici

**Tři vrstvy, ale jen dvě z nich jsou Redmine issues:**

Epic → Feature skupiny → atomické tasky. Feature skupiny jsou pouze organizační kategorií (Redmine verze nebo tag), nikoli issues. Jinak se z backlogu stane neprůhledný strom, kde agent neví, na jaké úrovni pracuje.

**Pravidlo 2–8 hodin:** Pod 2 hodiny je task příliš atomický — agent stráví více času načítáním kontextu než prací a ztrácíš přehlednost v Redmine. Nad 8 hodin agent pravděpodobně narazí na neočekávané rozhodnutí, ke kterému nemá oprávnění, nebo mu vyprší kontext Claude Code session. Vše nad 8h se rozpadá dál.

**Just-in-time dekompozice místo "big bang WBS":** Největší chyba v agentic projektech je nechat Clauda rozpadnout vše na začátku do posledního tasku. Realita: po prvním sprintu zjistíš, že architektura E03 závisí na rozhodnutích z E01, a polovina tasků E03 je špatně. Správně: Claude rozpadne podrobně vždy jen 1–2 epicy dopředu, zbytek drží na úrovni hrubého outlines s odhadem.

**Co musí každý agent task obsahovat (jinak agent halucinuje):** Název jako akce s jasným výstupem, odkaz na `CONTEXT.md` se strukturou projektu, explicitní acceptance criteria (ideálně testovatelná), seznam závislostí přes ID tasků, a technické omezení (`nesmí měnit DB schéma bez T-041`). Bez těchto informací agent buď splní task špatně nebo se zasekne a čeká na vstup.

**Limit počtu tasků na Epic:** reálně 10–20 tasků na Epic je optimum. Při více než 25 je to signál, že Epic je příliš rozsáhlý a měl by se rozdělit na dva.