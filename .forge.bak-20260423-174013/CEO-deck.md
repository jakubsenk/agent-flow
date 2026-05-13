# CEO Deck — ceos-agents komerční ekosystem

**Prezentující:** Filip Sabacký · **Datum:** 2026-04-23 · **Publikum:** CEO (jeden slot, dnes) · **Rozhodnutí:** do konce dne

---

## Slajd 1 — Žádost

**Teze: Chci tento měsíc publikovat ceos-agents jako komerční ekosystem. Potřebuji od tebe dnes toto rozhodnutí.**

- Zveřejnit plugin (MIT, už vydáno v6.9.1) a spustit 4komponentový hostovaný workspace na `ceos-agents.com`
- Ceník: Free / $19 Pro BYO / $29 Pro Hosted / $49 za seat Team / $25k+ Enterprise — žádná provize z marketplace
- Week-1 MVP (marketplace + composer happy path) za ~4 týdny fokusované práce
- Rozhodnutí dnes: firemní iniciativa nebo CEO krytí s founder equity (dva scénáře na slajdu 9)
- Odklad stojí reálné peníze — Anthropic s vysokou pravděpodobností (65-75 %) pustí vlastní autonomní composer do 12 měsíců

### Poznámky pro prezentujícího

Začneš rovnou ASKem — CEO nemá čas na rozehrávku. Řekni doslova: "Mám hotové produkty za tři roky práce, potřebuju od tebe do konce dne rozhodnutí, jestli to publikujeme jako firemní iniciativu nebo s tvým krytím a mojí founder equity." Pokud CEO řekne "proč teď" — odpověz: Phase 2 research ukazuje, že Anthropic má 65-75% pravděpodobnost, že do 12 měsíců pustí vlastní autonomous composer. Každý měsíc odkladu je transfer hodnoty konkurenci. Pokud řekne "proč ty" — řekni: plugin jsem postavil já, v184/184 testech a v6.9.1 shipnutém pod MIT, což není demo, to je produkt. Nedělej pitch, dělej rozhodovací meeting.

---

## Slajd 2 — Co už máme hotové (shippable dnes)

**Teze: Čtyři production-grade aktiva už existují. Otázka není "umíme to postavit" — otázka je "proč to neprodáváme".**

- **ceos-agents plugin v6.9.1** — 21 agentů, 29 skillů, 16 core kontraktů, 6 trackerů (YouTrack / Redmine / Gitea / Jira / Linear / GitHub), MIT licence, 184/184 testů, scaffold + autopilot + webhooky vše live
- **Claude-grade** — TypeScript eval engine pro kvalitu agentů, deterministické skórování, Vercel-ready, NPM publikace možná tento týden
- **Asysta** — prototyp kontextové vizualizace (NDJSON graph render) běžící na CEOS datasetu, re-skin na per-run view je ~1 týden práce
- **Agent-native tracker** — tvůj vlastní PoC existuje (strukturované AC + agent lineage + token-budget clock); poleštíme a rozšíříme jako moat
- Dohromady: ~3 roky akumulovaného IP, zatím nulový komerční výnos

### Poznámky pro prezentujícího

Toto je tvůj nejsilnější slide — nech ho sednout. Když CEO řekne "počkej, tohle všechno už máme?", odpověz klidně "ano, a to je přesně ten bod". Pokud se zeptá "proč to nikdo neví" — protože jsme to drželi interně jako nástroje pro CEOS delivery, ne jako komerční produkty. Pokud namítne "kolik z toho je opravdu hotové" — ceos-agents je shipnutý pod MIT s 184 zelenými testy, Claude-grade běží jako CLI a má stabilní API, Asysta má prototyp grafu, agent-native tracker je tvůj PoC, který rozšíříme. Nepoužívej slovo "nápad" — používej "aktivum". Rámec: tři roky R&D, nula komerčního výnosu, teď máme okno.

---

## Slajd 3 — Ekosystem (jeden produkt, ne pět)

**Teze: Jeden uživatelský tok: klikneš prompt → composer naplánuje → běží v uživatelově Claude Code → commituje, založí tiket, sám se oskóruje.**

- **Marketplace** (`ceos-agents.com`) — katalog promptů / agentů / skillů / workflow, každá položka s Claude-grade odznakem
- **Composer** — autonomní planner; uživatel klikne Run, composer vybere agenty, dispatchne do jeho Claude Code session, streamuje progres
- **Claude-grade** — skóruje každou položku v marketplace + každý dokončený run; embeddable badge živí viral loop
- **Context Viz** — živý graf + usage chart pro každý run; standalone na `viz.ceos-agents.com` jako druhá viral plocha
- **Tracker + SC** — agent-native tikety (strukturované AC, token-budget clock, agent lineage) + extended-git (signed commits); obaluje GitHub/Gitea, nenahrazuje je

### Poznámky pro prezentujícího

Nečti tabulku — vyprávěj jednu cestu. "Honza najde na HN prompt 'Android kalorické tabulky', klikne Run, za 12 sekund ho pustí GitHub OAuth modal, za pět minut má běžící app na Vercel preview, repo na GitHubu, tiket v trackeru a Claude-grade A- badge, který může embednout do readme." To je celý ekosystém v jedné větě. Pokud CEO řekne "to je moc komponent, příliš složité" — odpověz: pro uživatele je to jeden login, jeden workspace, jedna cena. Pro nás je to pět služeb za stejnou cenovkou, což nám dává cenotvorbu a obranu. Pokud se zeptá na integraci — plugin neposílá calls přímo do marketplace, všechno jde přes webhooks + MCP, takže offline-proti-bare-git kontrakt zůstává.

---

## Slajd 4 — Proč teď + konkurenční krajina

**Teze: Trh se pohnul, ale niku "ekosystem-package" nikdo nevlastní — a okno se zavírá do 12 měsíců.**

- Claude Code má 500k-2M platících seats (Phase 2 rozsah); plugin ekosystem je reálný a Anthropic jede zero take-rate
- Základní autonomie je komoditizovaná — Claude Code nativně dosahuje 87,6 % SWE-bench; Devin spadl z $500 na $20/měs
- Cursor / Copilot vlastní IDE vrstvu; Lovable / Bolt vlastní app-gen; Devin / Factory vlastní outcome-based autonomii
- **Nikdo nevlastní "ekosystem package"** — marketplace + composer + eval + agent-native tracker + niche trackery (YouTrack / Redmine / Gitea) — pro plugin vývojáře a enterprise týmy
- Strop ochoty platit jednotlivců je $20-80/měs; enterprise ACV beze změny — náš žebříček pokrývá obě skupiny

### Poznámky pro prezentujícího

Pokud CEO řekne "Cursor/Lovable to zabije" — odpověz, že Cursor je IDE vrstva (náš uživatel tam zůstává, my jsme orchestration nad tím), Lovable je app-gen (jednorázový výstup, žádný tracker, žádný follow-up loop). Náš moat jsou niche trackery — YouTrack/Redmine/Gitea — protože Anthropic podle Phase 2 H-pravděpodobně (60-70%) pustí nativní Jira/Linear, ale NIKDY nepodpoří české/evropské niche trackery. To je zero-competition zóna. Pokud se zeptá "kdo to kupuje" — prosumeři a dev týmy v enterprise, které používají YouTrack/Redmine a mají Claude Code Max předplatné. Pokud řekne "trh je přesycený" — ano, ale žádný z hráčů nedoručuje celý balíček; každý má jeden kus.

---

## Slajd 5 — Business model (commitnutý ceník)

**Teze: Pět tierů, BYO úniková cesta na každé úrovni, nulová provize z marketplace, zabudované upgrade spouštěče.**

| Tier | Cena | Co odemyká upgrade | Hrubá marže |
|---|---|---|---|
| Free | $0 | 2 composer runy/měs, veřejný marketplace, read-only Claude-grade | CAC |
| Pro BYO | **$19/měs** | Neomezené runy (uživatelův Anthropic klíč), privátní namespace, privátní eval | **~89 %** |
| Pro Hosted | **$29/měs** | Hostovaný planner token pool, Context Viz sync, LLM-improve tok | **~65 % s cache** |
| Team | **$49/seat** (min 3) | Google SSO, sdílený pool, multi-tracker federace ×2 | **70-83 %** |
| Enterprise Starter | **$25k/rok** | SAML/SCIM, 99,5 % SLA, 90denní audit, ≤25 seats | ~80 % |
| Enterprise | $50-150k/rok | On-prem/Bedrock, 99,9 % SLA, dedikovaný CSM, 40h custom vývoj | 65-75 % |

### Poznámky pro prezentujícího

Pokud CEO tlačí na "proč dva Pro tiery" — dual-SKU Pro není redundance. Prosumer s Claude Code Max ($200/mo) má neomezené tokeny, bere Pro BYO za $19 (my prodáváme software layer, 89% marže). Convenience-first kupec bere Pro Hosted za $29 (my prodáváme hosted planner pool a Context Viz sync, 65% marže). Segmentuje to WTP správně a eliminuje "co mi to odemkne" nejasnost. Pokud se zeptá na take-rate na marketplace — NULA, protože Anthropic běží zero take-rate a cokoliv nad nulu je mrtvé; marketplace je distribuce, ne výnos. Y2 cílová ARR je ~$400k (5 Enterprise Starter + 2 Enterprise + 20 Team + 100 Pro) — Colinův konzervativní model.

---

## Slajd 6 — Ekonomický insight, který to dělá funkčním

**Teze: Execution běží na straně klienta na uživatelově Claude Code předplatném. My nikdy neplatíme Anthropicu za jejich workflow — platí je oni. To nás mění z 25% resellera na 65-89% SaaS.**

- Composer *plánuje* na naší hostované službě (~10k tokenů/run, NAŠE náklady)
- Composer *spouští* přes deep-link do uživatelovy vlastní Claude Code session (jeho Anthropic předplatné to pokrývá)
- Střední run stojí Anthropic ~$6-12 v tokenech — **z toho platíme $0**
- Tím zabíjíme 90 % hosting COGS a obcházíme Anthropicův Managed Agents cenový boj
- Strukturálně odlišné od Devin (ACU billing proti jejich infra), Lovable (bundlované tokeny), Factory.ai (bundlované tokeny) — všichni žijí na 20-25% marži; my žijeme na 65-89 %

### Poznámky pro prezentujícího

Toto je wow-slide, nech ho vyznít. Řekni pomalu: "Devin, Factory.ai a Lovable platí Anthropic za každý token uživatele. My ne. Jejich workflow běhá u uživatele, na jeho Claude Code předplatném. My platíme jen za plánování — zhruba deset tisíc tokenů na run. Strukturálně jsme SaaS, ne API reseller." Pokud CEO řekne "to zní moc dobře, co je háček" — háček je, že nevidíme do runu a nemůžeme optimalizovat token routing, což je proč máme Pro Hosted jako doplněk (hosted planner pool pro ty, kdo nechtějí řešit klíče). Pokud řekne "nemůže to Anthropic zavřít" — Claude Code má veřejný plugin + Skill/Task tool API, MCP je jejich sanctioned protokol; pokud deprecate pluginy, sjedeme na MCP variantu, kterou máme v roadmapě (Aravinda §9).

---

## Slajd 7 — Go-to-market + plán spuštění

**Teze: MVP za 4 týdny, placený tier live Day 1, Y1 cíl $100-150k ARR, Y2 cíl ~$400k.**

- **Týden 1:** marketplace + composer (jen prompty, Vercel preview, polling progres, 25 seeded A- promptů), Pro BYO + Pro Hosted live, GitHub OAuth, Stripe billing
- **30 dní:** live WebSocket Context Viz, privátní Claude-grade eval (Pro unlock), upload skillů autory s gate na statickou analýzu, prvních 100 Pro konverzí (~$2,5k MRR blended)
- **90 dní:** Team tier launch ($49/seat/měs, min 3), Clerk SSO/SCIM, Tracker full write UX, sandboxovaná exekuce composeru — 20 Team log @ 8 seats = ~$7,5k MRR ($90k ARR)
- **180 dní:** Enterprise Starter live (SAML/SCIM, 99,5 % SLA, 90d audit), první 2-3 design-partner dealy; agent-signed commits v SC vrstvě
- **Y1 cíl revenue:** $100-150k (40-60 Pro + 5 Team + 1 Enterprise Starter); **Y2 ARR cíl:** ~$400k

### Poznámky pro prezentujícího

Pokud CEO řekne "4 týdny je moc agresivní" — strip-down MVP je jeden prompt → funkční Android app → sdílená URL → embeddable A- badge; všechno ostatní je v2 nebo později. Ilana to detailně rozepsala v synthesis §6. Pokud se zeptá "co když Y1 target netrefí" — $100k Y1 je v nejhorším případě 40 Pro userů za $25 blended ARPU × 12 měsíců; 40 userů za rok pro produkt, který dělá demo "Android app za 5 minut", je velmi dosažitelný cíl. Colin v pricing-stress-testu uvádí konverzní benchmark 0.5-3% z Elastic/PostHog/dbt dat; my sázíme na 1.5%. Pokud tlačí na "proč BYO Pro první den" — protože prosumeři s Claude Code Max si jinak vytvoří sockpuppet účty; BYO je legitimní escape valve, která udržuje free tier nezabitý.

---

## Slajd 8 — Platform risk + mitigace

**Teze: Anthropic pustí 50 % tohohle nativně do 12-24 měsíců. Zde je, co se stane v každém scénáři — jsme strukturálně lépe pozicováni ve 3 ze 4 rizik.**

| Scénář | Pravděpodobnost × horizont | Naše reakce |
|---|---|---|
| Anthropic pustí placený marketplace s take-rate | M (30-45 %) / 12-24 měs | **Strukturálně neutrální** — už jedeme zero take-rate; to se stane naším diferenciátorem |
| Nativní Jira + Linear integrace | **H (60-70 %) / 12 měs** | **Lépe pozicováni** — monetizujeme YouTrack / Redmine / Gitea niche federaci (zone bez konkurence) |
| Nativní AGENTS.md skórování | M (30-45 %) / 12-24 měs | Free Claude-grade se stane tapetou; placený LLM-improve + privátní rubriky přežijí |
| Nativní autonomous composer | **H (65-75 %) / 12 měs** | **Reálná expozice.** Pro BYO přežije ($19 prodává orchestration depth, ne planner); Pro Hosted v riziku — shipujeme za 2 týdny vs. jejich 12 měsíců, vyhráváme first-mover + marketplace network |

### Poznámky pro prezentujícího

Pokud CEO řekne "platform risk je moc velký" — ano, a proto je důležité shipovat TEĎ, ne za půl roku. Náš obranný příběh: klientská execution + niche-tracker moat + zero take-rate nás strukturálně chrání proti 3 ze 4 scénářů. Jediná reálná expozice je autonomous composer, a i tam máme 2-týdenní ship vs. Anthropicův odhad 12 měsíců, což je 50-násobná časová výhoda pro first-mover + marketplace network effects. Pokud tlačí "co když ship Anthropic native tracker" — nepustí YouTrack/Redmine/Gitea, garantuju. Pokud se zeptá "co když koupí Cursor nebo Lovable" — Cursor je IDE vrstva, Lovable je app-gen; ani jeden neřeší ekosystém + tracker federation. Naše hedge je MCP servery — pokud Anthropic deprecate plugin API, sjedeme na MCP variantu (Aravinda §9).

---

## Slajd 9 — Co od tebe potřebuji

**Teze: Dvě varianty, obě nacenené, dnes vyber jednu.**

- **Varianta A — Firemní iniciativa (doporučeno).** 6 týdnů founder fokusu + ~$40k infra/tooling (Vercel Pro, Fly.io, Clerk, Pusher, Stripe) + ~$20k seed content (25 promptů + 10 agentů + 5 workflow, vše A- skóre). CEOS vlastní Claude-grade, Asystu i tracker PoC — žádné externí licencování. Revenue teče do CEOS; já vedu produkt.
- **Varianta B — CEO krytí, founder equity.** Part-time commitment ode mě při pokračování v CEOS povinnostech. CEOS si ponechává plné IP vlastnictví na Claude-grade / Asystě / trackeru. Marketingová podpora přes CEOS kanály. Já držím founder equity; CEOS dostává majority + revenue-share strukturu. Rychlejší právně než Varianta A.

### Poznámky pro prezentujícího

Nečti options doslova, dej CEO vybrat. Pokud váhá, nabídni: "Můžeš se rozhodnout do večera, ale potřebuju binární odpověď a do zítřka to dáváme na agendu právního oddělení." Pokud řekne "chci čas" — odpověz, že každý měsíc odkladu je transfer hodnoty konkurenci a že Anthropic H-pravděpodobně pustí native composer do 12 měsíců. Pokud tlačí na Variantu A ale chce škrtat rozpočet — $40k infra je nespornitelný minimum (Vercel Pro + Fly + Clerk Enterprise + Pusher + Stripe); $20k seed content lze škrtnout na $10k, pokud obsah napíšu sám bez copywritera. Pokud jde na Variantu B — klíčové je definovat founder equity / revenue-share split ZÍTRA, ne za měsíc; nabízím startovní pozici 80/20 ve prospěch CEOS s earn-out na 70/30 po $500k kumulativního ARR. Varianta A je moje doporučení (rychlejší go-to-market, CEOS drží plnou hodnotu); Varianta B je bezpečnostní verze, pokud firma nechce zatížit P&L.

---

## Slajd 10 — Co se stane, když to neuděláme

**Teze: Do 12 měsíců Anthropic pustí 50 % tohohle nativně, Cursor / Lovable expandují do ekosystem-packagingu a CEOS má 3 roky ceos-agents / Claude-grade / Asysta R&D s nulovým komerčním výnosem.**

- Anthropic H-pravděpodobnost (65-75 %) pustí nativní autonomous composer → zavírá se okno pro Pro Hosted
- Anthropic H-pravděpodobnost (60-70 %) pustí nativní Jira/Linear integraci → náš Jira/Linear klín se zužuje (niche trackery přežívají)
- Cursor + Factory.ai + Lovable expandují do ekosystem-packagingu; marketplace + eval + tracker se stanou komodita
- CEOS vlastní tři nemonetizovaná R&D aktiva navždy; plugin zůstává MIT, ale nikdy nevrátí investici
- Někdo jiný vlastní narrative "Claude Code ekosystem" — stáváme se interně-only tooling, nikdy product company

**Závěrečná věta: Publikace tento měsíc zajišťuje first-mover výhodu. Každý odložený měsíc přenáší hodnotu na konkurenci.**

### Poznámky pro prezentujícího

Toto je FOMO slide, ale drž tón věcný, ne dramatický. CEO pozná manipulaci; data nepozná. Řekni: "V Phase 2 researchi jsme identifikovali čtyři platformní scénáře; dva z nich jsou H-pravděpodobné do 12 měsíců. To není spekulace, to je current trajectory Anthropicu." Pokud řekne "možná to Anthropic nepustí" — odpověz, že v dubnu 2026 už spustili Managed Agents a native pipeline je logický další krok. Pokud tlačí "raději počkáme a uvidíme" — každý měsíc čekání je ztráta first-mover advantage a marketplace network efektu; po Anthropicově shipu už nikdo nebude hledat třetí marketplace. Poslední věta je tvoje zavíračka — řekni ji pomalu a pak mlč. Nenech se vtáhnout do dalších 20 minut diskuse; rozhodovací moment je TEĎ.

---

*Konec decku — 10 slajdů, ~2100 slov včetně českých poznámek pro prezentujícího. Ready to present.*
