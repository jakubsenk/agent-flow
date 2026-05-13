---
marp: true
theme: default
paginate: true
size: 16:9
style: |
  section { font-size: 22px; padding: 40px 60px; }
  h1 { font-size: 34px; color: #1a4d8f; }
  h2 { font-size: 30px; color: #1a4d8f; }
  strong { color: #c9302c; }
  table { font-size: 18px; }
  h3 { font-size: 20px; color: #666; margin-top: 24px; }
header: 'ceos-agents — komerční ekosystem · Filip Sabacký · 2026-04-23'
footer: 'Důvěrné — interní CEOS'
---

# ceos-agents — komerční ekosystem

**Prezentující:** Filip Sabacký
**Datum:** 2026-04-23
**Publikum:** CEO (jeden slot, dnes)
**Rozhodnutí:** do konce dne

---

## Slajd 1 — Žádost

**Teze: Chci tento měsíc publikovat ceos-agents jako komerční ekosystem. Potřebuji od tebe dnes toto rozhodnutí.**

- Zveřejnit plugin (MIT, už vydáno v6.9.1) a spustit 4komponentový hostovaný workspace na `ceos-agents.com`
- Ceník: Free / $19 Pro BYO / $29 Pro Hosted / $49 za seat Team / $25k+ Enterprise — žádná provize z marketplace
- Week-1 MVP (marketplace + composer happy path) za ~4 týdny fokusované práce
- Rozhodnutí dnes: firemní iniciativa nebo CEO krytí s founder equity (dva scénáře na slajdu 9)
- Odklad stojí reálné peníze — Anthropic s vysokou pravděpodobností (65-75 %) pustí vlastní autonomní composer do 12 měsíců

---

## Slajd 2 — Co už máme hotové (shippable dnes)

**Teze: Čtyři production-grade aktiva už existují. Otázka není "umíme to postavit" — otázka je "proč to neprodáváme".**

- **ceos-agents plugin v6.9.1** — 21 agentů, 29 skillů, 16 core kontraktů, 6 trackerů (YouTrack / Redmine / Gitea / Jira / Linear / GitHub), MIT licence, 184/184 testů, scaffold + autopilot + webhooky vše live
- **Claude-grade** — TypeScript eval engine pro kvalitu agentů, deterministické skórování, Vercel-ready, NPM publikace možná tento týden
- **Asysta** — prototyp kontextové vizualizace (NDJSON graph render) běžící na CEOS datasetu, re-skin na per-run view je ~1 týden práce
- **Agent-native tracker** — tvůj vlastní PoC existuje (strukturované AC + agent lineage + token-budget clock); poleštíme a rozšíříme jako moat
- Dohromady: ~3 roky akumulovaného IP, zatím nulový komerční výnos

---

## Slajd 3 — Ekosystem (jeden produkt, ne pět)

**Teze: Jeden uživatelský tok: klikneš prompt → composer naplánuje → běží v uživatelově Claude Code → commituje, založí tiket, sám se oskóruje.**

- **Marketplace** (`ceos-agents.com`) — katalog promptů / agentů / skillů / workflow, každá položka s Claude-grade odznakem
- **Composer** — autonomní planner; uživatel klikne Run, composer vybere agenty, dispatchne do jeho Claude Code session, streamuje progres
- **Claude-grade** — skóruje každou položku v marketplace + každý dokončený run; embeddable badge živí viral loop
- **Context Viz** — živý graf + usage chart pro každý run; standalone na `viz.ceos-agents.com` jako druhá viral plocha
- **Tracker + SC** — agent-native tikety (strukturované AC, token-budget clock, agent lineage) + extended-git (signed commits); obaluje GitHub/Gitea, nenahrazuje je

---

## Slajd 4 — Proč teď + konkurenční krajina

**Teze: Trh se pohnul, ale niku "ekosystem-package" nikdo nevlastní — a okno se zavírá do 12 měsíců.**

- Claude Code má 500k-2M platících seats (Phase 2 rozsah); plugin ekosystem je reálný a Anthropic jede zero take-rate
- Základní autonomie je komoditizovaná — Claude Code nativně dosahuje 87,6 % SWE-bench; Devin spadl z $500 na $20/měs
- Cursor / Copilot vlastní IDE vrstvu; Lovable / Bolt vlastní app-gen; Devin / Factory vlastní outcome-based autonomii
- **Nikdo nevlastní "ekosystem package"** — marketplace + composer + eval + agent-native tracker + niche trackery (YouTrack / Redmine / Gitea) — pro plugin vývojáře a enterprise týmy
- Strop ochoty platit jednotlivců je $20-80/měs; enterprise ACV beze změny — náš žebříček pokrývá obě skupiny

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

---

## Slajd 6 — Ekonomický insight, který to dělá funkčním

**Teze: Execution běží na straně klienta na uživatelově Claude Code předplatném. My nikdy neplatíme Anthropicu za jejich workflow — platí je oni. To nás mění z 25% resellera na 65-89% SaaS.**

- Composer *plánuje* na naší hostované službě (~10k tokenů/run, NAŠE náklady)
- Composer *spouští* přes deep-link do uživatelovy vlastní Claude Code session (jeho Anthropic předplatné to pokrývá)
- Střední run stojí Anthropic ~$6-12 v tokenech — **z toho platíme $0**
- Tím zabíjíme 90 % hosting COGS a obcházíme Anthropicův Managed Agents cenový boj
- Strukturálně odlišné od Devin (ACU billing proti jejich infra), Lovable (bundlované tokeny), Factory.ai (bundlované tokeny) — všichni žijí na 20-25% marži; my žijeme na 65-89 %

---

## Slajd 7 — Go-to-market + plán spuštění

**Teze: MVP za 4 týdny, placený tier live Day 1, Y1 cíl $100-150k ARR, Y2 cíl ~$400k.**

- **Týden 1:** marketplace + composer (jen prompty, Vercel preview, polling progres, 25 seeded A- promptů), Pro BYO + Pro Hosted live, GitHub OAuth, Stripe billing
- **30 dní:** live WebSocket Context Viz, privátní Claude-grade eval (Pro unlock), upload skillů autory s gate na statickou analýzu, prvních 100 Pro konverzí (~$2,5k MRR blended)
- **90 dní:** Team tier launch ($49/seat/měs, min 3), Clerk SSO/SCIM, Tracker full write UX, sandboxovaná exekuce composeru — 20 Team log @ 8 seats = ~$7,5k MRR ($90k ARR)
- **180 dní:** Enterprise Starter live (SAML/SCIM, 99,5 % SLA, 90d audit), první 2-3 design-partner dealy; agent-signed commits v SC vrstvě
- **Y1 cíl revenue:** $100-150k (40-60 Pro + 5 Team + 1 Enterprise Starter); **Y2 ARR cíl:** ~$400k

---

## Slajd 8 — Platform risk + mitigace

**Teze: Anthropic pustí 50 % tohohle nativně do 12-24 měsíců. Zde je, co se stane v každém scénáři — jsme strukturálně lépe pozicováni ve 3 ze 4 rizik.**

| Scénář | Pravděpodobnost × horizont | Naše reakce |
|---|---|---|
| Anthropic pustí placený marketplace s take-rate | M (30-45 %) / 12-24 měs | **Strukturálně neutrální** — už jedeme zero take-rate; to se stane naším diferenciátorem |
| Nativní Jira + Linear integrace | **H (60-70 %) / 12 měs** | **Lépe pozicováni** — monetizujeme YouTrack / Redmine / Gitea niche federaci (zone bez konkurence) |
| Nativní AGENTS.md skórování | M (30-45 %) / 12-24 měs | Free Claude-grade se stane tapetou; placený LLM-improve + privátní rubriky přežijí |
| Nativní autonomous composer | **H (65-75 %) / 12 měs** | **Reálná expozice.** Pro BYO přežije ($19 prodává orchestration depth, ne planner); Pro Hosted v riziku — shipujeme za 2 týdny vs. jejich 12 měsíců, vyhráváme first-mover + marketplace network |

---

## Slajd 9 — Co od tebe potřebuji

**Teze: Dvě varianty, obě nacenené, dnes vyber jednu.**

- **Varianta A — Firemní iniciativa (doporučeno).** 6 týdnů founder fokusu + ~$40k infra/tooling (Vercel Pro, Fly.io, Clerk, Pusher, Stripe) + ~$20k seed content (25 promptů + 10 agentů + 5 workflow, vše A- skóre). CEOS vlastní Claude-grade, Asystu i tracker PoC — žádné externí licencování. Revenue teče do CEOS; já vedu produkt.
- **Varianta B — CEO krytí, founder equity.** Part-time commitment ode mě při pokračování v CEOS povinnostech. CEOS si ponechává plné IP vlastnictví na Claude-grade / Asystě / trackeru. Marketingová podpora přes CEOS kanály. Já držím founder equity; CEOS dostává majority + revenue-share strukturu. Rychlejší právně než Varianta A.

---

## Slajd 10 — Co se stane, když to neuděláme

**Teze: Do 12 měsíců Anthropic pustí 50 % tohohle nativně, Cursor / Lovable expandují do ekosystem-packagingu a CEOS má 3 roky ceos-agents / Claude-grade / Asysta R&D s nulovým komerčním výnosem.**

- Anthropic H-pravděpodobnost (65-75 %) pustí nativní autonomous composer → zavírá se okno pro Pro Hosted
- Anthropic H-pravděpodobnost (60-70 %) pustí nativní Jira/Linear integraci → náš Jira/Linear klín se zužuje (niche trackery přežívají)
- Cursor + Factory.ai + Lovable expandují do ekosystem-packagingu; marketplace + eval + tracker se stanou komodita
- CEOS vlastní tři nemonetizovaná R&D aktiva navždy; plugin zůstává MIT, ale nikdy nevrátí investici
- Někdo jiný vlastní narrative "Claude Code ekosystem" — stáváme se interně-only tooling, nikdy product company

**Závěrečná věta: Publikace tento měsíc zajišťuje first-mover výhodu. Každý odložený měsíc přenáší hodnotu na konkurenci.**
