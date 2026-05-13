# Sub-projekt F — Read-Only Dashboard: Brainstorm

**Datum:** 2026-04-27
**Cílový release:** v9.1.0 (samostatná MINOR pro F read-only; přečíslováno z v9.0.0 Volbou C 2026-04-27 — E + F rozsekány do oddělených minor releases per CLAUDE.md versioning policy)
**Status:** Brainstorm output, čeká user review
**Předchůdci:** v8.0.0 sub-projekty A.1 (mode framework) + B.1 (HITL scaffold harmonizace) — HOTOVO 2026-04-27 forge FULL_PASS 0.863; v9.0.0 E (showcase web) — bez tvrdé závislosti, F nepotřebuje E hotový
**Následník:** v10.0.0 Node.js Runtime + interaktivní F ("klik = spusť pipeline" interactive controller)

---

## Post-brainstorm user decisions (2026-04-27)

Tyto rozhodnutí padla po dokončení brainstormu — overrideují constraints/scope diskutované níže:

- **Mobile = deprioritized pro v9.0.0.** User explicit: "mobil me asi ted moz nezajima". CLI-first user base = dashboard je primárně desktop tool. → Cílit **desktop-first**, žádný mobile fallback UX (sekce 7.4 OQ-F.10 → škrtnuto), žádný touch-target ≥44px constraint. Bundle size constraint ↓ ~150 KB (možno odstranit responsive grid logic). Revisit v v9.0.x pokud usage data ukáží mobile traffic.
- **WCAG AA = aspirational, ne blocking.** Sémantický HTML + keyboard nav + alt text + contrast — best effort. Phase 8 verify NEBUDE blokovat na axe-core violations. Manual audit recommendation v PR description.
- **Existing `/dashboard` skill merge/rename (OQ-F.1) = NOT brainstorm decision.** User explicit: "to by pak melo byt asi soucasti research ne? ted nevim. musi se to posoudit i z hlediska best practise jinde." → Otázka přesunuta do **forge phase 1 research** (až v8.0.0 forge doběhne). Research scope: jak řeší jiné CI/CD/observability tooly přechod CLI report → web UI (GitHub Actions, CircleCI, Allure, pytest-html, Sentry, BMAD-METHOD). Žádný Judge default — rozhodne research evidence.
- **Data ingestion = hybrid (CLI export primary + drag-drop fallback).** User confirmed 2026-04-27 (Volba A). Tržní precedenty: Allure / pytest-html / Lighthouse jedou CLI-export self-contained HTML; Playwright trace viewer kombinuje CLI export + drag-drop (oba); Chrome DevTools profiler = drag-drop. Pro ceos-agents hybrid optimální: (a) CLI export = konzistentní UX se zbytkem pluginu (`/fix-bugs`, `/setup-agents`, `/dashboard --export-html`), zero friction, offline; (b) drag-drop fallback = užitečný pro debug cizí pipeline (kolega pošle state.json), porovnání dvou runů, edge cases. Marginal cost drag-drop ~50 řádků JS nad CLI parser code. Sdílený parser modul `src/lib/file-import.ts` (bridge na E spec post-brainstorm decision — stejná infrastruktura).
- **Stack volby = NON-BINDING brainstorm preferences, ne hard requirement** (rozhodnuto 2026-04-27). User explicit: "nema toto zvolit pak forge?" → Brainstorm v sekcích 2-7 fixoval konkrétní stack (Preact + plain CSS + uPlot + Vite) jako Judge default. Tyto volby jsou **direction signal** pro forge phase 1 research, NE hard contract. Forge phase 1 ověří na evidence (Allure / pytest-html / Lighthouse / Playwright trace viewer / Sentry stack analýza), phase 4 spec finalizuje. Důvody pro relaxaci: (a) sdílená infrastruktura s E (file-import.ts) → stack musí být kompatibilní; (b) charting library volba vyžaduje benchmark na real datech (~50 runů × per-agent metriky); (c) bundle-size constraint (self-contained HTML s embedded daty) je real, ale optimální stack vyžaduje měření. Co zůstává binding z brainstormu: **pure FE (žádný backend)**, **read-only (žádné akce, ne approve gate, ne abort)**, **3 views: run list / run detail / trends**, **hybrid data ingestion (CLI export + drag-drop)**, **time-series charting capability** (knihovna ne fixed).
- **Sekce 3 views (run list / run detail / trends) = brainstorm scope, finalní layout řeší forge spec** (rozhodnuto 2026-04-27). 3 views jsou MUST-HAVE z brainstormu (čisté UX). Detaily — jaké sloupce v list view, jaké widgety v detail view, jaké metriky v trends — řeší forge phase 4 spec na základě reálných state.json a pipeline-history.md sample dat (nepředpokládat strukturu, ověřit).
- **Sekce 4 charting scope = NEEDS_RESEARCH** (rozhodnuto 2026-04-27). Které trend grafy: success rate over time? avg cost per run? token consumption per agent? per-agent duration percentile? → Forge phase 1 research scope: jak Allure/Sentry/Datadog dashboardy vybírají hlavní metriky pro CI/CD observability, co user reálně potřebuje vidět denně. Brainstorm guess (success rate + cost + token breakdown) je startovní bod, ne contract.

Internal mentions "mobile-friendly" / "WCAG AA" / merge-vs-rename / specific stack v sekcích 2-7 zůstávají jako historie brainstormu — neřešit jako requirement.

---

## 1. Context

Sub-projekt F z roadmap (řádek 1041) — read-only dashboard jako **statický HTML/JS web** vizualizující existující pipeline artefakty. Žádný backend, žádná modifikace state, žádné akce. Pure FE = GitHub Pages compatible.

### 1.1 Co F MUSÍ ukázat

- **Run list:** posledních N pipeline runů z `.ceos-agents/pipeline-history.md` (50 retention, append-only)
- **Live run view:** pro běžící pipeline → aktuální fáze, který agent jede, tokens spotřebované zatím (parse `state.json` snapshot)
- **Done run view:** pro hotovou pipeline → outcome (completed/blocked/failed/paused/aborted_by_system), wall-clock time, total tokens, model breakdown z `pipeline.summary_table`
- **Per-agent metriky:** tokens, duration_ms, tool_uses, model, started_at, completed_at (z `state.json` per-stage usage fields, v6.8.0+)
- **Filter/search:** by date range, outcome enum, agent (block_agent), issue ID
- **Trend grafy:** success rate over time, avg cost per run, token consumption per agent (aggregate napříč 50-run window)

### 1.2 Co F EXPLICITNĚ NEDĚLÁ (out of scope, → v10.0.0)

- Žádné akce: žádný "approve gate" button, žádný "abort run", žádný "retry", žádný "spusť pipeline na issue X"
- Žádný realtime push (SSE / websockets potřebují backend → v10.0.0 Node.js Runtime)
- Žádná modifikace `state.json` ani `pipeline-history.md`
- Žádný auth, žádný multi-user, žádné sdílení (operator-controlled local artifacts)
- Žádné posílání dat ven (offline-first, žádný telemetrie endpoint)

### 1.3 Vztah k A.1 + B.1

A.1 přidal `--step-mode` flag + 3 mode framework + audit trail v pipeline-history (B.1 = scaffold mode harmonizace). F **vizualizuje** výstupy A.1/B.1, **nemodifikuje** je. Konkrétní deps:

- F číst `state.json` schema v8.0.0 (additivní `mode_flags` field z A.1; pokud A.1 přidá clarification trail expansion, F musí parsovat)
- F číst `pipeline-history.md` v9.0.0 schema (předpokládáme: identický s v6.9.0+ formátem; viz `core/post-publish-hook.md` Section 5)
- F NESMÍ čekat na live update z A.1 step-mode (každá pauza je read-only render z disk snapshotu)

### 1.4 Data ingestion challenge (zásadní)

Pure FE neumí číst lokální soubor bez user interakce. Možnosti:

| Mechanism | Pros | Cons |
|---|---|---|
| (a) Drag-drop zone | Universal, browser-portable, žádný extra CLI step | User musí manuálně dropnout 1-2 soubory pokaždé; live runs neaktualizují |
| (b) FileSystem Access API | Watch directory, auto-update | Chrome/Edge only (no Firefox/Safari), permission prompt každý load |
| (c) CLI-generated bundled HTML | Zero upload step, self-contained, archivable | Snapshot-only (musí znova spustit CLI po každém run); trend grafy potřebují re-export |
| (d) Tiny self-hosted server | Always-fresh, polling | Porušuje pure-FE constraint — pak je to v10.0.0 territory |
| (e) Hybrid: CLI export + drag-drop fallback | Best of both | 2 paths to maintain |

→ Klíčové rozhodnutí v Judge sekci 3.

### 1.5 Tržní precedenty

- **GitHub Actions runs view** — timeline + logs + per-job breakdown; má backend, ale UX vzor použitelný
- **CircleCI / Jenkins dashboards** — multi-pipeline orchestration; backend
- **Sentry / Datadog logs explorer** — filter-heavy UX, paid SaaS
- **pytest-html, Allure** — static HTML test reports, generated by CLI; **nejbližší precedent F** (snapshot-only, pure-FE)
- **datasette** — SQLite-backed JSON explorer, pure-FE varianta `datasette-lite` přes WASM
- **BMAD-METHOD** — CLI-only status reporting, žádný web (= co dnes ceos-agents má v `/dashboard` skill)

### 1.6 Constraints

- Pure FE (žádný backend; Node.js stays in v10.0.0)
- Funguje offline po prvním načtení (no CDN deps at runtime — bundle nebo cache-first)
- Mobile-friendly (responsive grid, touch-target ≥44px)
- WCAG AA accessibility (keyboard nav, semantic landmarks, alt text, contrast ≥4.5:1)
- Žádný runtime auth proti tracker (ten by byl backend)
- Bundle ≤500 KB gzipped (loadable on slow connections)

---

## 2. Tři proposal varianty

### Proposal A — Conservative: Drag-drop static report

**Pattern:** Allure / pytest-html — single static HTML page. User dropne 1-2 soubory (pipeline-history.md + jeden state.json) do drop zone, FE parsuje a renderuje.

**Architektura:**
- Single-page HTML (≈200 KB gzipped: vanilla JS nebo Preact, žádný build pipeline)
- Drop zone akceptuje:
  - `.md` (pipeline-history.md) — povinné, řídí Run list view
  - `.json` (state.json) — volitelné, řídí Detail view pro selected run
  - Multi-file drop: 1× .md + N× .json (N×) → multi-run detail
- Parser:
  - Markdown H2 split (`## {run_id}`) → array of {run_id, date, pipeline, outcome, agents_touched, block_*, complexity, duration_s}
  - JSON parse state.json per schema v6.10.0+ (additive backward-compat reads)
- Views:
  1. Run list (table, sortable, filterable by outcome/date/agent/issue ID)
  2. Run detail (selected from list; requires state.json drop)
  3. Trends (computed from pipeline-history; agent-level metrics graphs)
- Charting: chart.js (35 KB gzipped) nebo žádné (raw HTML tables + sparkline SVG inline)

**Distribution:**
- Hosted na GitHub Pages: `https://<owner>.github.io/ceos-agents-dashboard/`
- Source v repo: `dashboard/` (separate from skill)
- Versioning: Pages auto-deploys main branch; in `dashboard/index.html` link na specific tag for offline copy

**User flow:**
1. User otevře URL (online) nebo offline downloaded HTML
2. Otevře project repo, najde `.ceos-agents/pipeline-history.md`
3. Drag-drop do dashboard
4. Pro detail: drag-drop konkrétní `.ceos-agents/{run-id}/state.json`

**Pros:**
- Universal browser support
- Žádný build step v ceos-agents repo (pure markdown plugin → pure FE web; clean separation)
- Funguje na mobilu (drop přes file picker)
- Refresh = re-drop (jednoduchý mental model)

**Cons:**
- User musí manuálně dropnout pokaždé — žádný "watch directory" pro live runs
- Trend grafy potřebují celý pipeline-history každý load
- 2 separate artifact uploads (history + per-run state) je kognitivní zátěž
- Live run sledování = user pollne dashboard manuálně, redrop, reread

**Scope:** 3 views, ~600 LOC vanilla JS, ~2-3 dní implementace, 0 BE.

---

### Proposal B — Innovative: CLI-generated bundled HTML

**Pattern:** Generate single self-contained `.html` file s embedded JSON via existing `/ceos-agents:dashboard` skill (které už existuje! viz `skills/dashboard/SKILL.md`). Rozšířit skill o `--export-html` flag, který:
- Read all `.ceos-agents/{run-id}/state.json` v repo
- Read `.ceos-agents/pipeline-history.md`
- Inline JSON jako `<script type="application/json" id="data">{ ... }</script>`
- Inline FE bundle (100 KB minified JS + CSS)
- Output: `pipeline-dashboard-{YYYYMMDD-HHMMSS}.html` v cwd

**Architektura:**
- CLI integration: `/ceos-agents:dashboard --export-html-v2` (nový flag, ne breaking)
- Současný `/dashboard` skill (HTML output) zůstává; v9.0.0 přidá interactive bundle
- FE bundle žije v `dashboard/dist/bundle.html` v repo, skill ho čte at generate time
- Skill responsibility: scan `.ceos-agents/`, JSON-encode, inline, write
- FE bundle responsibility: render UI, žádný fetch, žádný drop (data už embedded)
- Versioning: bundle ships as part of plugin release; `plugin_version` field embedded into output for traceability

**User flow:**
1. User pustí `/ceos-agents:dashboard --export-html-v2` v project repo
2. Skill vygeneruje `pipeline-dashboard-2026-04-27-1450.html` (≈800 KB pro 50 runs)
3. User otevře soubor v prohlížeči (file:// protocol or share)
4. Pro fresh data: re-run skill

**Pros:**
- Zero upload step pro user (CLI dělá ingestion)
- Self-contained file = sharable (commit do issue tracker, e-mail, attachment)
- Archivable — snapshot v čase (post-mortem of past run)
- Live runs: user pustí command znova, dostane fresh export
- Reuse existing skill (≈80% logiky se nemění; nové: data inlining)
- File:// works offline by default

**Cons:**
- Snapshot-only — žádný "watch" mode (musí re-run command)
- HTML soubor může být velký (50 runs × průměr 3 state.json kompletních = ~3-5 MB pre-gzip → po inline gzip ~800 KB, na hraně mobile-friendly)
- file:// protocol má restrikce: žádný localStorage persistence napříč soubory (každý export = fresh state)
- 2 paths v plugin: existing `/dashboard` (server-side render) vs nový `--export-html-v2` (client-side render with inlined data)
- Nutí Plugin maintainerovi udržovat FE bundle (build step → CI artifact, ne pure markdown plugin)

**Scope:** 1 skill rozšíření + bundled FE (`dashboard/dist/`), ~800 LOC FE + ~150 LOC skill changes, ~4-5 dní implementace + bundle build setup.

---

### Proposal C — Skeptical: Challenge premises

**Otázka 0: Potřebujeme dashboard vůbec?**

Současný `/ceos-agents:dashboard` skill **už existuje** (viz `skills/dashboard/SKILL.md`) a generuje HTML report z tracker data + state.json. Co reálně chybí, čím by F-rework přidal hodnotu?

| Současný stav | Reálný gap |
|---|---|
| `/dashboard` čte tracker přes MCP, parsuje `[ceos-agents]` comments | Vyžaduje MCP runtime, není offline-friendly, nečte pipeline-history.md |
| Output je single HTML s issue list + state | Nemá trend grafy, nemá per-agent breakdown, nemá filter UI |
| Static (žádný interactive view) | Nemá filter/sort, vše inline |

**Otázka 1: Není stačící lepší CLI output?**

Operators ceos-agents jsou primárně CLI-first developers. `/metrics` skill už dává JSON + human-readable summary. Co kdyby F bylo jen:
- Rozšíření `/metrics` o per-agent breakdown table
- Rozšíření `/pipeline-status` o last-N runs sparkline (ASCII chart in terminal)
- TUI varianta (Textual, Rich)? — ale to už je Python deps, nepatří do plugin

**Otázka 2: YAGNI test — kdo ten dashboard reálně používá?**

Hypotéza: ceos-agents user base je single-developer per project, runs in personal terminal. Web dashboard má smysl pro:
- Manager/PM observability (multiple devs, multiple projects) → out of v9.0.0 scope, vyžaduje multi-tenant backend
- Post-mortem analysis (jeden dev, jeden run) → existuje state.json, manual jq dotaz funguje
- Trend analysis (jeden dev, mnoho runs) → toto je skutečný F use case, ale **kolik developerů má 50+ runs měsíčně?**

Pokud je answer "minorita early adopters", F = pre-optimization. Public-release polish (sub-projekt G v9.0.1) je lepší investice času.

**Otázka 3: Mobile-friendly — kdo dashboard otevírá na mobilu?**

CLI-first plugin user pravděpodobně **nikdy** neotevře dashboard na mobilu. Constraint "mobile-friendly" by mohl jít. Pokud projde, bundle size constraint se uvolní (-200 KB pro responsive CSS + touch handlers).

**Otázka 4: WCAG AA — kdo to validuje?**

Žádný auto-WCAG checker není v ceos-agents pipeline. Constraint je dobrý cíl, ale vyžaduje manual audit (axe-core) v Phase 8 verify. Bez toho je "WCAG AA" jen marketing claim.

**Otázka 5: Offline-first — proč?**

Public-release scenario: dev v letadle / on-call s flaky síti. Reálná potřeba? Plugin už je offline-friendly (žádný external API call kromě tracker MCP). Offline-first **dashboard** je nice-to-have, ne blocker.

**Otázka 6: Co když se F vrátí jako "klik = spusť pipeline"?**

v10.0.0 je explicitně Node.js Runtime ("klik = spusť pipeline" je tam alokováno). F je read-only. Pokud user F začne používat na trend analysis a pak chce klikat actions, jsme v upgrade-path-pain. Lepší: F je explicitně dead-end, s migration guide do v10.0.0.

**Otázka 7: Jaký je scope v9.0.0 celkově?**

Per memory: v9.0.0 = D + E + F (B blocked by A; G odštěpeno do v9.0.1). E + F = pure FE. Pokud F je "static report only", **nesdílí žádný kód s E** (web onboarding) → to nejsou economy of scale, jsou to dva samostatné FE projekty. Možná lepší: shipping E v v9.0.0, F deferred to v9.0.x patch (nebo zrušen ve prospěch CLI improvement v9.0.1).

**Skeptik vote:** Pokud F prosadit, vybrat **minimum viable**: snapshot-only (Proposal A varianta), žádné trends, 1 view (run list + run detail tabbed), ~1 den implementace, žádný build pipeline.

---

## 3. Judge synthesis

**Neutral analyst — vážení proposals:**

### 3.1 YAGNI defense (vs Proposal C)

C má pravdu, že:
- Současný `/dashboard` skill pokrývá basic use case
- Mobile constraint je sporný (CLI-first user base)
- Multi-tenant je out of scope pro v9.0.0

Ale:
- pipeline-history.md (v6.9.0+) je novější artefakt, který současný `/dashboard` nečte → real gap
- Per-agent breakdown (tokens/duration/model) v6.8.0+ státním schema NENÍ surfacený v current `/dashboard` → real gap
- Trend grafy přes 50-run window jsou hodnota navíc, kterou CLI tabulka neuhrne čitelně
- v9.0.0 je public-release vehicle — "dashboard" je legitimate marketing/showcase deliverable (npx demo, README screenshot)

→ **F ZŮSTÁVÁ V SCOPE v9.0.0**, ale s **redukovaným scope** per C otázky 3+4.

### 3.2 Data ingestion mechanism — ROZHODNUTÍ

Proposal A drag-drop vs Proposal B CLI-export:

| Kritérium | A (drag-drop) | B (CLI-export) |
|---|---|---|
| User effort per view | Vyšší (manual drop) | Nižší (1 command) |
| Artifact archivability | Nízká (data live, drop session) | Vysoká (single .html ke commitu) |
| Live run sledování | Manual repoll | Manual re-export |
| Maintainer effort | Nízký (vanilla JS) | Vyšší (build pipeline) |
| Sharing | Drop ne-portable | HTML soubor portable |
| Plugin character | Pure markdown stays | Build step introduced |

**ROZHODNUTÍ: Hybrid (varianta e) s priorizací B jako primary path:**

1. **Primary: CLI-export** (`/ceos-agents:dashboard --export-html-v2`) — generates self-contained HTML; nejlepší pro post-mortem, sharing, archivu, mobilu (file:// download na phone)
2. **Secondary: Drag-drop fallback** — same FE bundle hostovaný na GitHub Pages, akceptuje user-dropped pipeline-history.md + state.json files; pro user kteří nechtějí spouštět CLI nebo chtějí ad-hoc viewing artifacts z jiného repo

Stejný FE bundle (`dashboard/dist/bundle.{js,css}`) servuje oba paths:
- Embedded mode: bundle inline + JSON inline → ready
- Hosted mode: bundle z Pages + drag-drop ingestion → ready
- Detection: presence of `<script type="application/json" id="data">` → embedded, else → drag-drop UI

→ Vyřeší ingestion challenge (sekce 1.4): A pro flexibility, B pro convenience, single bundle, ne 2 codebases.

### 3.3 Framework + styling + charting — ROZHODNUTÍ

| Volba | Doporučení | Důvod |
|---|---|---|
| FE framework | **Preact** (3 KB) nebo **vanilla JS** (0 KB) | React je overkill, build complexity bez benefitu pro 3 views |
| Styling | **Plain CSS + CSS Grid** (žádný Tailwind) | Bundle size ≤50 KB CSS budget; semantic HTML první |
| Charting | **uPlot** (~30 KB gzipped) nebo **vanilla SVG sparklines** | Chart.js je 35 KB gzipped, ale uPlot je rychlejší a lehčí; pokud trend grafy = sparklines + 1 area chart → vlastní SVG stačí |
| Build | **esbuild** (jednorázový) | esbuild bundle 1× při release, output committed do `dashboard/dist/` (deterministic) |
| TypeScript | **JS s JSDoc types** | Žádný TS toolchain; JSDoc hint je dostatečný |
| Test | **Playwright** smoke 3 user flows (drop, embedded, mobile) | E2E sufficient; unit tests pro parser separately (vitest, ~20 testů) |

### 3.4 Scope: kolik views, jaké filtry, trend grafy ano/ne

**3 views (mandatory):**
1. **Run list** (default landing) — table sortable: run_id, date, pipeline, outcome, duration_s, complexity, block_agent
2. **Run detail** (modal nebo tab) — per-stage timeline, tokens/duration/model breakdown, sanitized block.reason (NEVER block.detail per state schema), AC fulfillment if present
3. **Trends** (aggregate) — 3 graphs: success rate (line, 7-day rolling), avg cost per run (area), tokens per agent (stacked bar)

**Filtry (run list view):**
- Date range (from/to picker)
- Outcome enum (multi-select chips: completed, blocked, failed, paused, aborted_by_system)
- Agent filter (search input matching block_agent)
- Issue ID filter (substring match na run_id prefix)

**Trend grafy:** ANO ale **3 grafy max**, žádný interactive drill-down (tooltip on hover OK). Pokud user chce hlubší analýzu → CLI `/metrics --format json` + jq.

**Mobile constraint:** RELAX. Optimize pro tablet (≥768 px); phone (≤480 px) = degraded view (jen Run list table, no charts). Bundle size ↓ ~150 KB.

**WCAG AA:** ASPIRATIONAL. Dělat semantic HTML + keyboard nav + alt text + contrast 4.5:1, ale NEVALIDOVAT jako blocking gate v Phase 8. Manual axe-core audit recommendation v PR description, ne CI fail.

**Offline-first:** Embedded mode je inherently offline (file://). Hosted mode = service worker pre-cache (extra 5 KB), nice-to-have, defer to v9.0.x patch pokud user pain.

### 3.5 Bundle target

- JS bundle (Preact + parser + view + uPlot lazy): ≤180 KB gzipped
- CSS: ≤30 KB gzipped
- Inline JSON (50 runs avg): ≤400 KB pre-gzip → ≤120 KB gzipped
- **Total embedded HTML:** ≤350 KB gzipped (~800 KB pre-gzip)

→ Pod původní 500 KB budget i s 50-run worst case.

### 3.6 Co NEDĚLÁME v F (zopakování + nové z C feedback)

- Žádný interactive controller (klik = action) → v10.0.0
- Žádný realtime push → v10.0.0
- Žádné multi-project view → v10.0.0
- Žádný auth → v10.0.0
- Žádný service-worker offline-first (jen file:// inherent) → v9.0.x patch
- Žádný `--watch` mode pro CLI export → ne v scope
- Žádný PDF/CSV export → ne v scope (jq + raw JSON stačí)
- Žádný custom theme / skin → ne v scope (1 default theme respektující prefers-color-scheme)
- **Žádný integration s `/dashboard` skill se mažou** — ten zůstává pro tracker-based view (současné chování); F přidává `--export-html-v2` jako další flag se stejným skill name (ALTERNATE: nový skill `/dashboard-v2`?). → OQ-F.7

### 3.7 Skill count impact

v9.0.0: 28 skills (z v7.0.0/v8.0.0 plánu) → **28 skills** (rozšíření existing `/dashboard` o flag, žádný nový skill). Pokud Judge rozhodne nový skill `/export-dashboard` → 29 skills. → OQ-F.7.

---

## 4. Open questions for spec phase (forge phase 4)

**OQ-F.1: Existing `/dashboard` skill rename / merge.**
Současný skill čte tracker přes MCP. Nový `--export-html-v2` čte `.ceos-agents/` artefakty (žádný tracker). Volby:
- (a) Rozšířit existing skill o flag (1 skill, 2 modes — možná zmatené)
- (b) Nový skill `/dashboard-v2` (29 skills, jasné rozdělení)
- (c) Deprecate existing → v9.0.0 pouze nový (1 skill, breaking change)

Forge phase 4 musí vybrat. Kritérium: jak často user reálně používá tracker-based view? Pokud rarely → (c); jinak (a).

**OQ-F.2: Bundle distribution mechanism.**
- (a) Committed `dashboard/dist/bundle.html` v ceos-agents repo (deterministic, audit-friendly, +100 KB k repo size)
- (b) GitHub Release artifact (download at install) — vyžaduje plugin install hook pro fetch
- (c) GitHub Pages CDN deploy — hosted mode primary, embedded mode CLI fetches Pages při generate

Forge phase 4 musí rozhodnout. Pure markdown plugin char = (a) preferable; (b) + (c) zavádí runtime deps.

**OQ-F.3: Pipeline-history.md schema stability guarantee.**
F parser čte pipeline-history.md format definovaný v `core/post-publish-hook.md` Section 5. Pokud A.1 nebo B.1 přidá pole (např. `mode_flags: ["--step-mode"]`), F musí gracefully ignorovat unknown fields. Spec musí explicitně zakázat schema breaking change v pipeline-history bez major bump.

**OQ-F.4: state.json access — relative path or absolute?**
Run detail view potřebuje `.ceos-agents/{run-id}/state.json`. V embedded mode (CLI export): all states inlined → ne issue. V hosted mode (drag-drop): user musí dropnout konkrétní state.json. Multi-state drop UX: jak prezentovat "drop 5 state.json files at once"?

**OQ-F.5: Trend graph data sources — pipeline-history vs state.json vs both?**
- Outcome trend → pipeline-history (50 runs, has outcome field)
- Tokens per agent → vyžaduje state.json (pipeline-history nemá agent-level breakdown)
- Avg cost per run → pipeline-history má `duration_s` ale ne `tokens` → potřebuje state.json

Implication: trend grafy v drag-drop mode vyžadují user dropnout VŠECHNY state.json (ne realistické). → Buď omezit trends na metric, který je v pipeline-history (duration_s, success rate), nebo jen-embedded-mode trends (CLI dělá heavy aggregation).

**OQ-F.6: Sanitization layer.**
state.json `block.detail` může obsahovat credentials (per state schema "INCLUDE — full text, operator-controlled location"). Když F renderuje state.json data, musí F:
- (a) Zobrazit `block.detail` raw (operator-controlled, dashboard runs locally) → riziko share-with-screen-recording
- (b) Sanitizovat přes JS port `sanitize_block_reason()` (18 patterns) → safer ale duplicate code
- (c) Nikdy nezobrazit `block.detail`, pouze `block.reason` (matches webhook/history exclude posture)

Doporučení Judge: **(c)** pro consistency s ostatními channels (state schema enumerace v9.0.0 přidá "F dashboard render" jako EXCLUDE row).

**OQ-F.7: Skill name + count delta.**
Per OQ-F.1 rozhodnutí — pokud nový skill, počet 28→29 (nebo 30 pokud A.1 přidá `/setup-agents`). Spec musí finalizovat skill count budget pro v9.0.0.

**OQ-F.8: Browser support matrix.**
Hosted mode FileSystem Access API (varianta 1.4 b) je Chrome/Edge only. Drag-drop varianta universal. Spec musí decidovat: F support FS Access API jako progressive enhancement (auto-watch directory in Chrome) nebo žádný opt-in pro tu API surface (jednodušší code, full portability)?

**OQ-F.9: Versioning + plugin_version embedding.**
Embedded HTML obsahuje `plugin_version` z `state.json`. Když user otevře 6-month-old export v dashboard built proti newer schema — backward-compat read MUSÍ fungovat. F parser MUSÍ tolerantní vůči missing additivních polí (per state schema "Reading v6.7.x state.json under v6.8.0" pattern).

**OQ-F.10: Mobile fallback UX wording.**
≤480 px viewport: hide trend graphs, show jen run list. Wording fallback: "Trends require ≥768 px viewport. Switch to tablet/desktop for full view." → Nebo žádný wording, jen graceful hide? Spec rozhodne.

---

## 5. References

- **B.1 spec:** `docs/superpowers/specs/2026-04-27-B-hitl-design.md` (mode framework, audit trail surface)
- **A.1 spec:** `docs/superpowers/specs/2026-04-26-A-agent-shape-design.md` (D3 mode flags; F renderuje mode info)
- **State schema:** `state/schema.md` (per-stage usage fields, pipeline accumulator, sensitive field exclusion contract — F musí respektovat EXCLUDE rows)
- **pipeline-history format:** `core/post-publish-hook.md` Section 5 (markdown H2 split, retention 50, sanitize_block_reason)
- **Existing dashboard skill:** `skills/dashboard/SKILL.md` (tracker-based current state — F doplňuje, ne nahrazuje)
- **Roadmap allocation:** `docs/plans/roadmap.md` row 1041 (F definition), row 1166 ("klik = spusť pipeline" → v10.0.0)
- **Memory:** v9.0.0 = D+E+F, F = pure FE static, blocked by v8.0.0 A+B
- **Tržní precedenty:** Allure, pytest-html (snapshot HTML reports); datasette-lite (WASM-based pure FE explorer); GitHub Actions runs view (timeline UX vzor)
- **Doc requirements:** `project_v8_doc_requirements.md` HIGH PRIORITY pattern aplikuje i na v9.0.0 — F vyžaduje migration guide v9-to-v10 (poukázat že interactive controller je v10.0.0), `docs/reference/skills.md` update, `docs/reference/automation-config.md` (žádné nové config keys očekávány), README screenshots, CHANGELOG v9.0.0 entry s F deliverable note.

---

## 6. Next Steps

1. **User reviews F.1 brainstorm** (this document) — feedback / approval
2. **Otevřené otázky vyřešit s userem nebo posunout do forge phase 4 spec** — zejména OQ-F.1 (skill rename/merge) a OQ-F.2 (bundle distribution) jsou strategické
3. **F spec consolidation:** F brainstorm → forge v9.0.0 phase 4 spec (společně s D + E specs jakmile vzniknou)
4. **v9.0.0 forge run blocked by v8.0.0 completion** (per memory + roadmap; F depends on B.1 pipeline-history schema)
5. **Coordination s sub-projekt E:** pokud E (web onboarding) sdílí FE bundle infrastruktura, koordinovat build pipeline + GitHub Pages deploy v jednom shot
