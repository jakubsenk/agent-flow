# Review-1 — Run 2 Synthesis Quality Gate

**Datum:** 2026-04-26
**Reviewer role:** Senior synthesis quality gate (Tier 1 + Tier 3)
**Verdict:** PASS_WITH_REVISIONS
**Synthesis k posouzení:** synthesis.md (607 lines, 8,654 words)

---

## Verdict rationale

Synthesis je obsahově silný a strukturálně téměř úplný dokument. Všech 9 požadovaných sekcí je přítomno, komparativní matrice je 100% vyplněna (100/100 buněk), evidence trail je traceable, a 8 z 9 klíčových oprav Run 1 je explicitně zachyceno a verifikovatelné vůči source reportům. Verdikt PASS_WITH_REVISIONS (ne PASS) z důvodu tří identifikovaných MAJOR issues: (1) chybějící devátá oprava Run 1, která má přímý dopad na v8.0.0 design decision, (2) konfuze v počtu "klíčových oprav" deklarovaném vs doručeném (sekce 7 má 9 oprav, exec summary bullet 5 říká "dvě kritické"), a (3) drobná ale traceable inkonzistence v citaci superpowers star count v Anomaly 3 vs Claim C19, která může mást A.1 brainstorm spotřebitele. Žádný z těchto problémů není zásadně destruktivní — jsou opravitelné v jednom revision passu bez re-dispatchování synthesis agenta.

---

## Tier 1 — Structural completeness

### Sekce 1: Executive Summary
**PRESENT, COMPLIANT.** 10 bullets (zadání: 5–10). Všechny bullets jsou evidence-based, každý nese alespoň jednu Q-referenci. Délka odpovídá zadání.

### Sekce 2: Komparativní matrice
**PRESENT, FULLY FILLED.** 10 frameworků × 10 dimenzí = 100 buněk. Každá buňka obsahuje hodnotu + Q-referenci v závorce. Žádná buňka není prázdná ani označena jako N/A. Formát konzistentní (bold hodnota, kurzíva reference). Drobná výhrada: dimenze 8 ("Migration cost do ceos") má nejednotnou škálu — někde "HIGH/MEDIUM/LOW," někde textový popis. Toto je MINOR issue (viz níže).

### Sekce 3: Identifikace paradigmat
**PRESENT, COMPLIANT.** Revidovaný clustering je logicky vyargumentovaný. Run 1 5-cluster framework ověřen, 2 zpřesnění + 1 nový sub-cluster (Autonomous SaaS loop P3b) jsou jasně odůvodněny. Cross-paradigm tensions T1–T3 přidávají hodnotu. Cluster 5 reframe jako sub-pattern Cluster 4 je korektní a evidence-backed [Q18].

### Sekce 4: Doporučení paradigmatu (sekce 4.1–4.5)
**PRESENT, COMPLIANT.** Všech 5 sub-sekcí přítomno (4.1 Customization, 4.2 Pipeline config, 4.3 HITL, 4.4 Stateful/Stateless, 4.5 Single vs multi). Počet option scenarios: 4.1 = 4 options (A/B/C/D), 4.2 = 3 options, 4.3 = 4 options, 4.4 = 3 options, 4.5 = 3 options + task-type bifurcation table. Zadání požadovalo "2–4 distinct option scenarios" — všechny sub-sekce splňují. Každá option má pros + cons + evidence Q-refs + migration cost. Disclaimer "NIKOLI rozhodovací dokument" je explicitně uveden.

### Sekce 5: Evidence trail audit
**PRESENT, COMPLIANT.** 25 claims v lookup tabulce. Formát claim → Q-references → primární citace. URL jsou konkrétní. Tabulka pokrývá všechny major claims z sekcí 1–4. Drobná výhrada: C11 cituje "Q15 poznámka opravuje Run 1 claim" — Q15 je source report, nikoli Run 1 Q15. Terminologicky to může být matoucí (viz MINOR issues).

### Sekce 6: Anomálie status update
**PRESENT, COMPLIANT.** Všech 10 anomálií z Run 1 je adresováno. Status kategorie použity: VERIFIED AS REAL / NEDEEP-DIVED / PARTIALLY RESOLVED / VYŘEŠENO / CONFIRMED / REFRAMOVÁNO. Anomalies 2, 4, 5 jsou označeny "NEDEEP-DIVED" s vysvětlením proč (outside Top 10 shortlistu) — toto je transparentní a akceptovatelné.

### Sekce 7: Klíčové opravy / corrections of Run 1
**PRESENT, PARTIAL.** Sekce 7 doručuje 9 oprav (Oprava 1–9), což překračuje zadávací minimum 8+. ALE: Executive Summary bullet 5 říká "Run 2 opravuje dvě kritické Run 1 nepřesnosti" — interní inkonzistence. Dále: jedna oprava s přímým dopadem na v8.0.0 design je strukturálně podceněna (viz MAJOR issue #2).

### Sekce 8: Open questions for A.1 brainstorm
**PRESENT, COMPLIANT.** 8 otázek (OQ1–OQ8), zadání požadovalo 5–10. Každá otázka má Q-ref + "Proč důležité" odůvodnění. Otázky jsou architektonicky relevantní pro A.1 brainstorm. Kontext "pointer" na downstream spec je implicitní (v úvodu dokumentu), nikoli explicitní per-question — toto je přijatelné.

### Sekce 9: Lens disclosure
**PRESENT, COMPLIANT.** Primární závislosti (Q19, Q15, Q20, Q22) jsou pojmenovány s odůvodněním. Evidence gaps jsou transparentně deklarovány (opencode runtime, Cursor closed-source, Copilot sub-agent details, MAF Workflows.Declarative prerelease). Sekce řeší contradictions between reports (BMAD stars, superpowers stars).

**Tier 1 souhrnné hodnocení:** 8.5/9 sekcí FULLY COMPLIANT, 0.5/9 PARTIAL (sekce 7 — interní inkonzistence). Žádná sekce MISSING.

---

## Tier 3 — Research quality

### 3a. Source diversity

**Silná stránka.** Každý claim v evidence trail (sekce 5) má alespoň 1 citaci. Majority claims má 2–3 cross-lens references. Source types:
- Vendor primary: arxiv 2601.21233, Cognition blog, Microsoft devblog, Microsoft FY26 earnings, BMAD GH releases — přítomny
- OSS code: BMAD `customize.toml:13-15`, agent.ts:117-250, Piebald-AI repo — přítomny
- Community: GH issues #1559, #2003, GH marketplace pages — přítomny
- Academic: Kim et al. 2512.08296, Yin et al. 2511.00872, Stateless DPM 2604.20158, PayPal DSL 2512.19769 — přítomny
- Production/journalism: TechCrunch Goldman pilot, Microsoft earnings call, CNBC — přítomny

Lenses 5 (academic / production / OSS-code / community / vendor) jsou reprezentovány. Žádná sekce nespoléhá výlučně na jednu lens. Hodnocení: **GOOD**.

### 3b. Coverage breadth

**Komparativní matrice:** 100/100 buněk vyplněno. Jediná výhrada je nejednotná škála v dimenzi 8 (Migration cost), ale data jsou přítomna.

**Decision options v sekci 4:** Každá option má pros, cons, evidence Q-refs, migration cost. Všechny 4.1–4.5 sub-sekce splňují zadání. Sekce 4.5 přidává "task type bifurcation" jako extra evidence-layer pro Cognition/Anthropic tension — nadstandard.

**Anomalies coverage:** Všech 10 anomálií adresováno, 7 s plnou verifikací, 3 s "NEDEEP-DIVED" transparentním disclaimerem. Hodnocení: **GOOD**.

### 3c. Confidence calibration

**Silná stránka.** Contradikce jsou surfacovány honestly:
- Cognition "Don't Build Multi-Agents" vs Anthropic "+90.2%" jsou oba zachovány v sekci 4.5 s task-type bifurkací jako resolution
- Goldman defect data: "unverified" je explicitně deklarováno v Claim C13 a Opravě 5
- Cursor "4× faster" claim: evidence gap v sekci 9 ("metodologicky neverifikovatelný")
- BMAD GH issue #2003 "10-15× více času": zachováno jako community evidence, ne vendor fact

"No evidence found" je disklosováno u:
- Meta-gen: 0 production deployments (10/10 Run 2 frameworků)
- HITL optimal gate count: "no empirical user-trust data" [Q6 z Run 1]
- CC5 controversy z Run 1: "nepodařilo se verifikovat" (zachyceno implicitně v Cline HITL evolution)

**Bias check:** Synthesis nepropaguje viditelnou advocacy pro žádný konkrétní paradigm. Sekce 4 explicitně říká "NIKOLI rozhodovací dokument." Option D (Hybrid generic+TOML) dostává stejnou strukturu pros/cons jako ostatní tři options, bez preferenčního framing. Hodnocení: **VERY GOOD**.

### 3d. Section-readiness

**Synthesis je section-ready pro A.1 brainstorm.** Decision options jsou actionable (konkrétní architektonické varianty s migration costs). Evidence trail je traceable. OQ1–OQ8 jsou formulovány jako architektonické otázky, nikoli vague principy.

Slabší stránka: OQ3 (plugin permission restriction hooks) je klíčový blocking constraint pro v8.0.0 design, ale v Open Questions sekci dostává pouze střední pozornost — mohl by být prioritněji označen jako "BLOCKER" pro brainstorm facilitátora. Toto je MINOR issue.

Hodnocení: **GOOD, s jedním minor gap**.

### 3e. Verifikace klíčových oprav

Verifikace provedena empirickým čtením source reportů (agent-Q15, Q18, Q19, Q20, Q21, Q22).

| Oprava | Claim v synthesis | Stav | Lokace v synthesis.md + source verifikace |
|---|---|---|---|
| Q15: 31 hook events (ne 12) | Oprava 1, řádek 504 | **VERIFIED PRESENT** | Sekce 7 Oprava 1, C12 tabulka řádek 461; Q15 agent: "31 distinktních event typů" ověřeno na code.claude.com/docs/en/hooks |
| Q15: plugin permission restriction (hooks/mcpServers/permissionMode ignored) | Oprava 2, řádek 506 | **VERIFIED PRESENT** | Sekce 7 Oprava 2, matrice buňka Claude Code dim 8 "plugin agents nemohou použít..."; Q15 agent řádek 74, 321 explicitní |
| Q18: Magentic-One 38% GAIA (ne 92% dispatch rate) | Oprava 3, řádek 511 | **VERIFIED PRESENT** | Sekce 7 Oprava 3; Q18 agent tabulka "GAIA Overall 38.00%; 92% = human performance baseline" — explicitní clarifikace |
| Q19: BMAD v6.1.0 reverted YAML → markdown | Oprava 1 v sekci 4.2 + Anomaly 6/7 | **VERIFIED PRESENT** | Sekce 4.2 Option A pros bullet "BMAD v6.1.0 explicitně revertoval z YAML"; Q19 agent řádek 122–127 s primárním source URL |
| Q20: compound architecture inference, ne Cognition-published | Oprava 4, řádek 516 | **VERIFIED PRESENT** | Sekce 7 Oprava 4; Q20 agent řádek 40–41 "Tato dekompozice nemá primární source na cognition.ai" |
| Q20: Goldman 1.5-2× defect rate unverified | Oprava 5, řádek 521 | **VERIFIED PRESENT** | Sekce 7 Oprava 5; Claim C13; Q20 agent řádek 19, 280 explicitní unverified disclosure |
| Q21: 4.7M paid seats (ne 10M+) | Oprava 6, řádek 526 | **VERIFIED PRESENT** | Sekce 7 Oprava 6; matrice buňka Copilot dim 9 "4.7M paid subscribers"; Q21 agent řádek 23, 186 s Microsoft FY26 Q2 earnings source |
| Q22: 3.7M VSCode installs (ne 1M+) | Oprava 7, řádek 531 | **VERIFIED PRESENT** | Sekce 7 Oprava 7; matrice buňka Cline dim 9 "3.7M VSCode installs (ne '1M+' z Run 1)"; Q22 agent řádek 543 |
| Q15: Anthropic 6,973 token claim = sémantická self-description, real baseline 27-31k | Oprava 8, řádek 536 | **VERIFIED PRESENT** | Sekce 7 Oprava 8 (terminologicky pojmenována "5-tier vs 6-tier" ale text zahrnuje token claim); ALE POZOR: toto je PROBLEMATICKÉ — viz MAJOR issue #2 níže |

**Verifikace poznámka k Opravě 8:** Oprava 8 v synthesis.md je pojmenována "5-tier vs 6-tier Claude Code subagent priority" (řádek 536). Corrects terminologickou záměnu (Local tier neexistuje). ALE kritická oprava o 6,973 tokenech vs 27-31k baseline je obsažena v Anomaly 8 (řádek 479–483) jako samostatné vyřešení, nikoli jako "Oprava 9" v sekci 7. Zadávací prompt specifikoval tuto jako jednu z 9 klíčových oprav. Synthesis tedy tuto opravu NEZACHYCUJE v sekci 7 explicitně — je zachycena v Anomaly 8, ale ne v chronologicky očekávaném místě. To je MAJOR issue #2 (viz níže).

---

## MAJOR issues (must-fix před promote)

### MAJOR #1: Exec summary bullet 5 inkonzistentní s obsahem sekce 7

**Lokace:** Sekce 1 (Executive Summary), bullet 5, řádek 21: *"Run 2 opravuje dvě kritické Run 1 nepřesnosti."*

**Problém:** Sekce 7 doručuje 9 oprav, ne 2. Exec summary bullet 5 zmiňuje pouze hook events a Magentic-One GAIA jako "dvě kritické" — čímž implicitně podceňuje Opravu 2 (plugin permission restriction), Opravu 4 (Devin compound architecture inference), Opravu 5 (Goldman defect unverified), Opravu 6 (Copilot 4.7M), Opravu 7 (Cline 3.7M), a Opravu 8/9 (token count + tier count). Spotřebitel A.1 brainstormu čtoucí jen exec summary by nevěděl, že existuje 9 oprav.

**Recommended fix:** Přepsat bullet 5 na: *"Run 2 opravuje 9 Run 1 nepřesností — klíčové: plugin agents nemohou použít hooks/mcpServers/permissionMode frontmatter (Oprava 2, blocking constraint pro v8.0.0); Magentic-One GAIA = 38% ne 92% dispatch rate (Oprava 3); Goldman defect data jsou unverified (Oprava 5). Detailní opravy viz sekce 7."*

### MAJOR #2: Oprava "6,973 tokenů = sémantická self-description, reálný baseline 27-31k" schází v sekci 7

**Lokace:** Sekce 7 neobsahuje tuto opravu jako numbered entry. Je obsažena v Anomaly 8 (řádek 479–483) ale ne v sekci 7 (řádky 499–544).

**Problém:** Zadávací spec specifikuje tuto jako jednu z 9 klíčových oprav. Sekce 7 má 9 oprav ale Oprava 8 je "5-tier vs 6-tier" (terminologická) a Oprava 9 je "superpowers Anomaly 3 dezavuování" — tokenová oprava úplně schází. A.1 brainstorm consumer by při čtení sekce 7 chronologicky nenalezl tuto opravu — musí si ji hledat v sekci 6 sám.

**Recommended fix:** Přidat Opravu 10 (nebo přečíslovat Opravu 8 → "5-tier vs 6-tier terminologie" jako Oprava 9, a vložit tokenovou opravu jako Oprava 8): *"Oprava X: Anthropic 6,973 token claim = sémantická self-description (Q15). Run 1 claim: 'Claude Code systémový prompt = 6,973 tokenů.' Korekce: Q15 verifikoval — 6,973 je sémantická extrakce přes JustAsk interakci (Claude popsalo svůj prompt vlastními slovy), nikoliv přesné měření. Reálný baseline: 27,000–31,000 tokenů (core ~2,500 + tool defs 14–17k + konfigurace). Goldilocks guidance se vztahuje na system prompt body, ne tool definitions — contradiction je tedy zdánlivá [Q15]. Viz Anomaly 8."*

### MAJOR #3: Claim C11 v Evidence Trail cituje "Q15" ambiguně

**Lokace:** Evidence trail (sekce 5), tabulka, Claim C11, řádek 417: *"Q18 objasňuje: Magentic-One 38% GAIA overall, ne 92% dispatch rate... Q15 poznámka opravuje Run 1 claim."*

**Problém:** V Run 2, "Q15" je `agent-Q15-claudecode.md` (Claude Code source report). V Run 1, "Q15" by bylo jiné. Claim C11 cituje "Q15 poznámka" v kontextu Magentic-One korigace, ale agent-Q15-claudecode.md popisuje Magentic-One metriky v jednom krátkém textu, ne jako primární source. Primárním source pro Magentic-One 38% je agent-Q18. Citace "Q15 poznámka" je zavádějící a nelze ji verifikovat jako správnou opravu — agent-Q18 je správný zdroj.

**Recommended fix:** Claim C11 opravit na: *"Q18 objasňuje: Magentic-One 38% GAIA overall (vs human baseline 92%±3.1%, nikoliv dispatch rate). Primární: arxiv 2411.04468 (Fourney et al. 2024)."* Odstranit "Q15 poznámka" z C11 citace.

---

## MINOR issues (nice-to-have)

### MINOR #1: Dimenze 8 (Migration cost) v matrice — nejednotná škála

**Lokace:** Komparativní matrice (sekce 2), sloupec 8 "Migration cost (do ceos)".

**Problém:** Hodnoty jsou nejednotné — opencode "HIGH," Claude Code "LOW," ale GH Copilot "HIGH — SaaS + GitHub-specific; ale spec→plan→implement gate pattern + async PR primitiv přenositelné." Délka buněk kolísá 1 slovo vs 15 slov. Pro A.1 brainstorm čtenáře je matrice méně přehledná.

**Recommended fix:** Zkrátit dlouhé buňky na formát "HIGH (reason)" nebo "LOW-MEDIUM (přenositelný pattern)." Konzistentní max 10 slov per buňka v tomto sloupci.

### MINOR #2: OQ3 není označena jako BLOCKER

**Lokace:** Sekce 8 (Open questions), OQ3, řádek 558.

**Problém:** Plugin permission restriction (hooks/mcpServers/permissionMode frontmatter ignorovány) je identifikována v Opravě 2 jako "zásadní constraint pro v8.0.0 design," ale v OQ3 je formulována jako otevřená otázka bez prioritizačního signálu. A.1 brainstorm facilitátor nemusí poznat, že OQ3 je de facto BLOCKING constraint, nikoli exploratory question.

**Recommended fix:** Přidat "(BLOCKING CONSTRAINT)" tag k OQ3 titulu nebo do první věty.

### MINOR #3: Claim C19 superpowers stars — interní inkonzistence

**Lokace:** Evidence trail (sekce 5), Claim C19, řádek 425: *"superpowers 168k★ na obra/superpowers; 121k★ verifikováno April 2026."*

**Problém:** 121k★ je popsáno jako "verifikováno April 2026" ale Anomaly 3 (sekce 6) říká 121k★ = "peak measure March 2026 (pasqualepillitteri.it April 2026 report)." Tedy 121k★ je March 2026 číslo, ne April 2026 číslo — April 2026 číslo je 168k★. Drobná záměna dat vs. data reportu.

**Recommended fix:** Claim C19 opravit na: *"obra/superpowers = 168k★ (live WebFetch 2026-04-26). 121k★ = March 2026 číslo reportované v April 2026 článku (pasqualepillitteri.it)."*

### MINOR #4: Sekce 3.2 odkaz na "arxiv 2506.17208" — neexistující paper

**Lokace:** Sekce 3.2 (Cross-Paradigm Tensions, Tension T1), řádek 169: *"ceos-agents pipeline je 'scaffolded execution' v Martinez & Franch taxonomy (arxiv 2506.17208)."*

**Problém:** arxiv papery s číslováním 2506.xxxxx jsou z června 2025. Paper 2506.17208 není citován v žádném source reportu (agent-Q13 až Q22) ani v Run 1 final.md. Tato citace je buď inference synthesis agenta, nebo chyba čísla. Verifikovatelnost nelze potvrdit bez přístupu k arxiv.

**Recommended fix:** Označit jako "(neověřeno)" nebo nahradit citací, která se vyskytuje v source reportech. Pokud citace nemůže být verifikována, raději ji vynechat.

---

## What's strong (preserve in revisions)

1. **Komparativní matrice (sekce 2) je výborná.** 100/100 buněk s hodnotou + Q-referencí. Tabulka je přehledná, konzistentní v 9 z 10 sloupců. Jednoduché pro A.1 brainstorm spotřebitele k navigaci.

2. **Sekce 4 decision-space structure je modelová.** Každá sub-sekce (4.1–4.5) má jasné option labels (A/B/C/D), strukturované pros/cons, Q-refs, migration cost. "Sub-projekt B compatibility note" v sekci 4.3 je cenný mostek pro paralelní H ITL design stream. Tato sekce je přímo použitelná jako A.1 brainstorm vstup.

3. **Evidence calibration (Goldman defect, Cursor "4×", Copilot sub-agent architecture)** — synthesis explicitně deklaruje kde evidence je vendor-published bez třetí-stranné verifikace. Toto je high-integrity a zachovává důvěryhodnost dokumentu pro strategické rozhodnutí.

4. **Anomaly 9 reframe (Cognition vs Anthropic)** — "task type bifurkace, ne věcná kontradikce" je přesná analýza a řeší potenciálně nejmatoucí Run 1 finding. Výborně zpracováno.

5. **Sekce 9 (Lens disclosure) je transparentní.** Evidence gaps jsou jmenovány konkrétně (opencode runtime neznámý, Cursor closed-source, MAF Workflows prerelease). Tato úroveň transparence je nadstandardní pro synthesis dokumenty.

---

## Recommendation

**PASS_WITH_REVISIONS** — aplikuj MAJOR fixes #1, #2, #3, pak promote na final.md.

Revision scope:
1. Přepsat exec summary bullet 5 (MAJOR #1) — 2 věty
2. Přidat chybějící opravu tokenové klaime do sekce 7 (MAJOR #2) — 1 nový numbered entry, ~150 slov
3. Opravit citaci C11 v evidence trail (MAJOR #3) — 1 řádek

MINOR #1–#4 jsou volitelné pro revision pass; pokud revision agent má kapacitu, aplikuj všechny 4. Pokud ne, MINOR #4 (neexistující arxiv paper) je nejkritičtější z MINOR tier — doporučuji alespoň přidání "(citace neověřena v Run 2 source reportech)" tagu.

Po aplikaci MAJOR fixes je synthesis production-ready pro A.1 brainstorm bez potřeby review-2.
