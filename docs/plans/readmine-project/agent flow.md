Agent-Flow (aka ceos-agents) revize

What:

schopnost postupného zasazování do vývojového workflow "vedle" lidí - tj nelze předpokládat že půjde nasadit full-auto rovnou
to bude vyžadovat "zvýšení" schopnosti autonomní existence agenta - viz dále
oddělit definice
schopností agenta
workflow
tech-stack dovednosti
zaměřit se na observabilitu a fin-ops procesu s prioritami
náklady (tokeny) a jejich optimalizace
zde je třeba si uvědomit, že kompletní řízení celého flow LLM modelem může být velmi nákladné
=> buď outsourcovat do "levného" lokálního LLM
=> nebo zvážit zda neudělat flexibilní engine který to bude schopen orchestrovat (kombinace SW a LLM)
traceabilita/vizualizace od zadání k výsledku a naopak
auto improvement
detekce patternů přes všechny možné dimenze a jejich kombinace (user/project/time/agent/model/workflow)
schopnost navrhovat optimalizaci agenta, workflow i tech dovedností tak, aby to nerozbilo existující setup
dry run
simulace posledního/vybraného procesu
zvážit možnost injektáže temporary a/nebo přírůstkových úprav definice (rychlá kustomizace)
version control - viz rovněž #4
zvážit specifika agentic vývoje a mixování s lidským týmem: https://cmd.youtrack.cloud/projects/ACT/articles/ACT-A-1/AI-vyvoj-koncept
Why:

možnost škálovat na velký počet agentů, workflow, tech-stacků
udržet náklady na celé řešení pod kontrolou --> růst nákladů při škálování
v žádném případě nemůže růst rychleji než lineárně s počtem kroků WF ani agentů (v první fázi)
předchozí omezení (lineární závislost) je málo ambiciózní jako cílový stav - nelze plýtvat drahými tokeny na "jednoduchou" orchestraci s repetitivními patterny
postupné nasazování --> snadnější adopce v existujících týmech

User avatar
Milan Marťák
Commented 1 day ago
Přidávám odkaz na KB Article kde je shrnutí specifik AI Agentic vývoje s ohledem na sledování pracé v Issue Trackeru: https://cmd.youtrack.cloud/projects/ACT/articles/ACT-A-1/AI-vyvoj-koncept

User avatar
Milan Marťák
Commented 1 day ago

přidávám analýzu původního stavu, vznikla samozřejmě tak že jsem zadal co chci do Claude a tohle je výsledek
proběhlo několik iterací / doplňování
je to věc na debatu - cílem je směrovat ke kvalitnímu řešení
motivace pro vznik oponentury
při pokusu nasadit do našeho vývoje jsem narazil na nízkou flexibilitu
nasazování per-partes bude klíčové pro adopci kdekoliv
co ne/chceme:
ne: vše zahodit a předělat
ano: postupně iterovat a zlepšovat
ano: zapojit do interního vývoje
Milan Marťák
Updated 1 day ago
attachments:agent-process-separation.md, ceos-agents-comparison.md, ceos-agents-review-report.md, ceos-agents-market-analysis.md
