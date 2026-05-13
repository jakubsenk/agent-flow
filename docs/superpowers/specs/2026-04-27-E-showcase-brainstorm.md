# Sub-projekt E — Web Showcase + Onboarding: Brainstorm

**Datum:** 2026-04-27
**Cílový release:** v9.0.0 (samostatná MINOR pro E; F má vlastní v9.1.0 — rozhodnuto Volbou C 2026-04-27)
**Status:** Brainstorm output, čeká user review

---

## Post-brainstorm user decisions (2026-04-27)

Tyto rozhodnutí padla po dokončení brainstormu — overrideují constraints/scope diskutované níže:

- **Mobile = deprioritized pro v9.0.0.** Spec interně řeší mobile-friendly (responsive, scroll-jacking risk, touch targets). User explicit: "mobil me asi ted moz nezajima". → Cílit **desktop-first**, mobile responsive jen pokud zadarmo z Tailwind defaultů. Žádný mobile-specific layout, žádné touch handler optimalizace, žádný `<480px` polish. Revisit v v9.0.x pokud adoption data ukáží mobile traffic.
- **WCAG AA = aspirational, ne blocking.** Sémantický HTML + keyboard nav + alt text + contrast — best effort, ale Phase 8 verify NEBUDE blokovat na axe-core violations. Manual audit recommendation v PR.
- **Hero showcase = DOM replay (Volba A — Judge default).** User confirmed 2026-04-27. Žádné video / GIF — místo toho deterministic DOM-based animation pipeline runu (Triage → Code Analyst → Fixer → Reviewer → ...). Build-time generated z reálných state.json snapshotů, scriptable, accessible (lze přidat live region narration), zero drift. Implementation reference: section 4 row "Hero replay engine" + OQ-A.5 (replay scenario source pro forge phase 1 research).
- **Agent gallery = progressive disclosure (hybrid Volba A + B).** User confirmed 2026-04-27. Default zobrazení **5 "featured" karet** + tlačítko "Zobrazit všechny (18)" které expanduje na full gallery. Build-time generated z `agents/*.md` (zero drift). Filter (model/phase) = available in expanded view. Search v9.0.x. → **Které 5 agentů je featured = NEW open question pro forge phase 1 research** (OQ-A.11). Research scope: jak jiné platformy s velkým agent/component katalogem vybírají "featured" subset (shadcn/ui "Popular", Vercel Templates "Featured", BMAD persona ordering, GitHub Marketplace "Trending"). Možné heuristiky: (a) frekvence v pipelines — fixer/reviewer/publisher jsou v každé pipeline; (b) first-contact order — co user vidí jako první když pustí `/fix-ticket`; (c) maintainer-pinned subset; (d) hybrid. Default fallback bez research = (a) frekvence: fixer, reviewer, triage-analyst, test-engineer, publisher.
- **Config wizard = PIVOT z "from-scratch generator" na "import + visual editor" model (hybrid).** User confirmed 2026-04-27. Originalní brainstorm 5-krokový wizard (Stack→Tracker→Agents→Hooks→Review) byl positioned jako primary entry — user override: web doplňuje CLI, ne nahrazuje. Nový model:
  - **Primary path (preferred CTA):** "Drop your CLAUDE.md + customization/*.toml here" — drag-drop souborů které **už vygeneroval `/setup-agents` skill** (CLI meta-agent z v8.0.0 A.1). Web parsuje (`@iarna/toml` + `FileReader`), renderuje single-screen visual editor (sekce Stack / Tracker / Agents / Hooks), user upraví hodnoty přes form controls, download updated bundle (`client-zip`).
  - **Secondary path (fallback link):** "Don't have files yet? Build from scratch" — vede na 5-krokový wizard z původního brainstormu. Stejný stepper, stejné výstupy, ale viditelně menší CTA. Messaging: "Tip: pro nejlepší výsledek nainstaluj plugin a pusť `/ceos-agents:setup-agents` — ten skenuje projekt a vygeneruje smart defaults."
  - **Rationale:** meta-agent zná real konkrétní projekt (frameworks, tracker, conventions) → produkuje fitter defaulty než user-clickování. Web je viewer/editor, ne primary configurator. "Aby už to bylo zmapované" (user citace).
  - **Scaffold guardrail (user explicit):** From-scratch wizard v webu **NESMÍ** zasahovat do scope `/scaffold` skill (který vytváří entire new project). E web wizard configures plugin sám pro existující codebase. Output = pouze CLAUDE.md + customization/*.toml, NIKDY entire project skeleton. Doc warning v webu: "Looking to create a new project? Use `/ceos-agents:scaffold` instead."
  - **Sdílená infrastruktura s F:** drag-drop import code path = stejný mechanism jako F dashboard (které importuje state.json + pipeline-history.md). Worth sharing as `src/lib/file-import.ts` modul, ne duplikovat.
  - **Open questions revised:**
    - Visual editor layout — vertical stack všech sekcí vs tabs (Stack/Tracker/Agents/Hooks tabs) vs accordion → forge phase 1 research
    - Conflict handling — co když user dropne soubor s neznámým TOML field? warn/ignore/error?
    - Save-back UX — single zip download vs separate download per file vs "copy to clipboard" per file
  - **URL state share link** = ano (oba pathy — drag-drop session i from-scratch session share-able)
  - **Live TOML preview vpravo** = ano v from-scratch path; v import-edit path nahrazeno **diff view** (před/po edit) — user vidí co přesně změnil
- **Sekce 4 "Co dál" = minimal pro v9.0.0** (rozhodnuto 2026-04-27). User explicit: install command "se bude menit, nereš to". Final scope sekce 4: (a) generic install snippet copy-to-clipboard (nepřesný wording, akceptováno že se bude měnit); (b) link na docs (`docs/reference/skills.md`); (c) link na GitHub repo; (d) teaser banner "🎯 Demo project coming in v9.1.0 — sandbox to try ceos-agents on a real codebase". Žádný Discord/community link (neexistuje zatím), žádný "Download install.sh" wrapper, žádné F dashboard cross-link (F doletí samostatně). Po v9.1.0 demo project ship → sekce 4 dostane aktualizaci s "Try demo" CTA.
- **Demo projekt = nová verze v9.1.0** (rozhodnuto 2026-04-27, novou release slot vytvořen). User explicit: "tohle netusim, a rikam si jestli tohle nepatri do 9 1 0 verze.... a nema to cele doresit forge." → Demo projekt scope (stack, tracker, repo location, walkthrough length, maintenance model) **přesunuto z v9.0.0 brainstormu do forge phase 1 research** po skončení v8.0.0 forge. Důvody: (a) brainstorm by to nezavřel — chybí research o tržních precedentech (shadcn/ui example, Next.js examples, BMAD tutorial, create-* CLI examples); (b) demo má dependency cycle s E hero replay (replay scenarios pochází z demo run output) — zaslouží vlastní design. v9.1.0 ne v9.0.1 (per CLAUDE.md versioning: nová feature = MINOR, ne PATCH). Posloupnost: v9.0.0 (core E+F) → v9.1.0 (demo) → v9.2.0 (G polish + hosting + announcement, dříve plánováno jako v9.0.1).
- **Stack volby = NON-BINDING brainstorm preferences, ne hard requirement** (rozhodnuto 2026-04-27). User explicit: "nema toto zvolit pak forge?" → Brainstorm v sekcích 2-7 fixoval konkrétní stack (Astro 5.x + Tailwind 3 + Vite + URLSearchParams + @iarna/toml + client-zip + Shiki) jako Judge default. Tyto volby jsou **direction signal** pro forge phase 1 research, NE hard contract. Forge phase 1 ověří na evidence (jaké stacky jedou jiné podobné projekty — shadcn/ui, Tailwind Play, Linear marketing site, Vercel templates), phase 4 spec finalizuje stack rozhodnutí. Důvody pro relaxaci: (a) sdílená infrastruktura s F dashboard (file-import.ts modul) → stack musí být kompatibilní napříč E+F, brainstorm to nezohlednil; (b) bundle-size / SEO / SSG vs SPA trade-offs vyžadují benchmark data; (c) v8.0.0 spec ukázal že research často přepisuje brainstorm assumpce. Co zůstává binding z brainstormu: **pure FE (žádný backend)**, **TOML output schema match A.1**, **build-time gallery generation z agents/*.md**, **DOM replay pattern (ne video)**, **progressive disclosure pattern**, **import + visual editor primary flow**.

Internal mentions "mobile-friendly" / "WCAG AA" / video alternatives v sekcích 2-7 zůstávají jako historie brainstormu — neřešit jako requirement.

---

## 1. Context

ceos-agents je Claude Code plugin (markdown-only, žádný build system) automatizující bug-fix / feature / scaffold pipelines. Po v8.0.0 bude mít **18 agentů, 29 skills, 18 optional config sekcí**. v9.0.0 = "Public launch UI vrstva" (E + F).

**v8.0.0 sub-projekt A.1** (viz `docs/superpowers/specs/2026-04-26-A-agent-shape-design.md`) zavádí závazné schéma které E **musí respektovat**:

- `customization/{agent}.toml` 3-tier merge overlay
  - skalární klíče (`model`, `style`) → override
  - pole tabulek (`[[process_additions]]`, `[[constraints]]`) → append
  - tabulky (`[limits]`) → deep merge
- Header `# generated:` u idempotent regen (preserve user edits)
- 18 agentů (po konsolidaci 21 → 18: triage-analyst+code-analyst+spec-analyst → analyst; test-engineer+e2e-test-engineer → test-engineer extended; reproducer+browser-verifier → browser-agent)
- `/setup-agents` skill = CLI pendant pro stejný použití (lokální scan → návrh defaultů). Web wizard generuje stejný formát z odpovědí na otázky, **NE** ze scanu sourceu.

**Sub-projekt E scope** (rozhodnuto s userem):

1. **Hero + showcase** — animované video/GIF "ceos-agents fixne bug za 8 minut" (real screenrecord)
2. **Agent gallery** — 18 karet, každá: role, model, příklad výstupu, link na docs
3. **Config wizard stepper** — Stack → Tracker → Agenti → Hooks → live TOML preview → download bundle (CLAUDE.md + customization/*.toml)
4. **"Co dál"** — install command, docs link, GitHub link

**Constraints:**
- Pure FE (žádný backend — server-side processing v v10.0.0)
- Žádné closed-source závislosti
- TOML bundle generation **musí** matchovat v8.0.0 A.1 schema (jinak download je nefunkční pro usery → zablokuje launch goal)
- Mobile-friendly (developers checking on phone během commute)
- Accessibility WCAG AA

**Out of scope (nepatří do E):**
- Sandbox který reálně spustí pipeline → v10.0.0 Node.js Runtime
- "Klik = spusť pipeline na issue X" → v10.0.0
- Hosting deploy decision (Pages/Vercel/Gitea) → v9.0.1
- Sub-projekt F (dashboard čtoucí pipeline-history.md) → separátní spec

**Userova explicitní priorita:** *"když to lidi uvidi, lepe si to predstavi"* — visual-first, ne textový dokument převlečený za web.

---

## 2. Tři proposal varianty

### Proposal A — Conservative (minimum viable)

**Filosofie:** Static-site-generator s minimem JS. Co nejvíce render-at-build-time, žádný runtime framework. Cíl: **ship rychle, audit-proof bundle, žádné odvislé maintenance**.

**Stack:**
- **Framework:** Astro (v5.x, MIT) s `output: "static"`. Astro renderuje 99 % stránky jako čisté HTML (Islands architektura → JS injectnut jen pro wizard a interactive previews).
- **Styling:** Tailwind CSS (utility-first) + 1 custom CSS file pro hero animace (`prefers-reduced-motion` respect).
- **Wizard state:** Vanilla JS Web Component (`<config-wizard>`) s `URLSearchParams` jako single source of truth — žádný Redux/Zustand. URL = stav, refresh-safe, share-link friendly.
- **TOML generator:** Wrap `@iarna/toml` (MIT, browser-compatible build) — generuje stejný format jako `/setup-agents` skill.
- **Hero:** WebM + MP4 fallback (real OBS screenrecord, ~12 MB, lazy-loaded `<video>` s `preload="metadata"`). Žádné JS animační knihovny.
- **Build:** `pnpm build` → `dist/` static. Žádný backend, žádný SSR.

**Layout (4 stránky):**
- `/` — hero + showcase video + "co dál" CTA
- `/agents` — 18 cards (každá expanded modal: role + model + 3 example outputs from real pipeline runs)
- `/wizard` — 5-step stepper (Stack → Tracker → Agents → Hooks → Review)
- `/install` — single-page install reference (copy-paste blocks)

**Scope:**
- 18 agent cards generované build-time z `agents/*.md` frontmatteru (žádná duplicita).
- Wizard má 3 stack profily (Next.js, Python/FastAPI, .NET) hardcoded — user vybere → wizard pre-fillne defaulty.
- TOML preview = client-side render do `<pre><code>` s syntax highlighting přes Shiki (build-time precomputed grammars, ne runtime).
- Download = ZIP přes `client-zip` (MIT, ~3 KB) — bundle obsahuje `CLAUDE.md` + `customization/*.toml` + `README.txt` s install krokem.

**Pros:**
- Build za < 30 s, deployable na **jakýkoli** static host (Pages, Vercel, Cloudflare, S3+CDN, dokonce IPFS).
- Astro bundle size ~80 KB JS first-load. Mobile-friendly out of the box.
- Žádný framework lock-in — pokud Astro v 3 letech zmizí, refactor na pure HTML je triviální.
- WCAG AA: Astro defaultní markup je sémantický, Tailwind plugin `@tailwindcss/forms` řeší accessible inputs.

**Cons:**
- Astro Islands má learning curve pro contributory (méně mainstream než React).
- Hero video 12 MB = bandwidth-heavy (mitigace: poster image + click-to-play na mobile).
- Žádná real-time pipeline preview "wow" momentu — wizard je stepper, ne playground.

**Market precedents:**
- **Astro docs site** (sám Astro používá Astro pro vlastní docs)
- **Bun website** (static, fast, hero video)
- **Hono framework site** (Cloudflare Pages, sub-second TTFB)
- **TanStack docs** (Astro + Islands pro interactive examples)

---

### Proposal B — Innovative (bold/ambitious)

**Filosofie:** "Tailwind Play meets shadcn/ui" — **live playground feeling**. Wizard NENÍ stepper, je **interactive sandbox** kde user vidí výsledek instantně side-by-side. Hero NENÍ video, je **live mock pipeline** kterou user vidí "běžet" v reálném čase v prohlížeči.

**Stack:**
- **Framework:** SvelteKit (v2, `adapter-static`) — Svelte má nejmenší bundle pro reaktivní UI a žádný virtual-DOM overhead pro animations.
- **Styling:** Tailwind + Skeleton UI (MIT, Svelte komponenty) pro accessible primitives (modal, tabs, toast).
- **Wizard:** Single-page **3-pane layout** (form left | live TOML preview middle | live agent-prompt preview right). User mění field → vidí TOML diff i prompt diff živě.
- **Hero "live pipeline":** Pre-recorded JSON event stream (`hero-pipeline.json` ~50 events) replay-ed přes `requestAnimationFrame` — vypadá jako reálný stream agentů, ale je deterministic. User může pause/resume/seek (jako video, ale je to DOM render → SEO-friendly + mobile-perfect).
- **Agent gallery:** Filterable + searchable + **"compare 2 agents side-by-side"** mode. Each card má tab `Prompt` / `Example output` / `Customizations`.
- **TOML generator:** Custom serializer (~200 LoC) pro 100 % match s A.1 schema; covered unit testy.
- **State management:** Svelte stores (built-in, no library); URL sync via SvelteKit router.

**Layout (single-page-app feel s deep-linking):**
- `/` — hero "live pipeline" + showcase + scroll-jacked sections (gallery preview → wizard preview → CTA)
- `/playground` — full wizard sandbox (3-pane)
- `/agents` — gallery + compare mode + filter (model, role-type, customizable yes/no)
- `/install` — terminál-style copy with animated typing efekt

**Scope:**
- Wizard stack profily: 8 profilů (matching `examples/configs/*.md`) loaded as JSON.
- Live agent prompt preview: render plugin default + show diff když user přidá `[[process_additions]]`. Visualní indikátor "tvoje customization přidá tento řádek".
- Agent compare mode: 2-column diff, highlight rozdíly v modelu/process/constraints.
- Hero pipeline replay: 8-min pipeline scenario (triage → analyst → fixer ↔ reviewer 3x → test → publisher) komprimovaný do 45s s click-to-pause.
- Download: ZIP + **shareable URL** (state v URL → kolega otevře, vidí stejnou config) + **gist export** (open-in-new-tab gh.io URL pre-filled).

**Pros:**
- "Aha moment" silný — user uvidí jak agenti reálně fungují, ne jen popis.
- Wizard 3-pane je educational: user pochopí proč TOML key X dělá co dělá.
- Compare mode = killer feature pro decision-makers (PM který vyhodnocuje "potřebuju 18 agentů?").
- SvelteKit bundle ~50 KB první load (lehčí než React).
- Shareable URL state = viral mechanism (Twitter/HN posts s pre-configured demo).

**Cons:**
- Maintenance burden vyšší — 3-pane reactivity + replay engine + compare diff = 3× komplexnější codebase než Proposal A.
- Replay JSON musí být pečlivě curated → každý nový agent v plugin = update hero replay (drift risk).
- SvelteKit menší ecosystem než React → menší pool přispívatelů (open-source community concern).
- Scroll-jacking na mobile může selhat → vyžaduje mobile-specific layout (extra práce).
- Custom TOML serializer = další attack surface vs `@iarna/toml` battle-tested.

**Market precedents:**
- **Tailwind Play** (live 2-pane editor)
- **shadcn/ui** (gallery + recipe + CLI assist + theme switcher)
- **Astro Container demos** (live preview tabs)
- **Resend** (hero animation feel — DOM-based, ne video)
- **Linear** (scroll-jacked storytelling, mobile-broken though)
- **Excalidraw** (state v URL → shareable)

---

### Proposal C — Skeptical (challenge premises)

**Filosofie:** Před investicí do FE refaktoru zpochybnit **nejdražší předpoklady**.

**Klíčové kritické otázky:**

1. **Vyplatí se 18-agent gallery?** ceos-agents má **0 community adoption** k dnešku (2026-04-27). Galerie 18 karet je pull-content (user musí scrollovat) — ale měříme čas-investice "build galerie" proti hodnotě "user pochopí co plugin dělá". Tailwind/shadcn galerie funguje protože **user už ví co je button a chce ho** — ceos-agents user neví **co je triage-analyst**. Galerie = solution looking for problem. Možná stačí **3 hero příklady** ("bug fix", "feature implementation", "scaffold").

2. **Wizard generuje TOML — ale kdo ho použije?** v8.0.0 A.1 zavádí `/setup-agents` skill (lokální CLI). User který už má Claude Code nainstalovaný **má lokální skill k dispozici**. Web wizard cílí na user-zone "ještě nenainstalován + zvažuje instalaci" — což je **velmi úzký funnel**. Riziko: spend 2 týdny na wizard, který 5 % visitors použije.

3. **TOML schema breaking changes.** v8.0.0 právě teď definuje schema. Pokud E generuje TOML build-time, **každá v8.x.y schema změna** = redeploy webu + cache bust download artefaktů. User může mít stažený nesprávný bundle pro starou verzi pluginu. Je třeba versioning na download (`bundle-v8.0.0.zip`).

4. **Hero video drift.** Real screenrecord "fixne bug za 8 minut" = záznam aktuálního UI Claude Code + výstupu agentů. Claude Code se mění, agent prompts se mění — video bude stale za 6 měsíců. Astro Container/StackBlitz přístup s **deterministic replay JSON** je odolnější (rebuilable from fixture).

5. **Mobile-friendly developer audience.** Userova teze: "developers checking on phone." Reálný vzorec: developer si **uloží link** na desktop, na phone si neinstaluje plugin. Mobile-friendly = baseline (responsive, čitelné), ne first-class (žádné mobile-only features). Re-allocation effort.

6. **Pure FE constraint je tvrdý overhead pro některé features.**
   - "Compare 2 agents" — fine FE.
   - "Live TOML preview" — fine FE.
   - "Validate generated TOML against plugin schema" — vyžaduje schema validator přibalený do bundle (~10-30 KB) — fine FE.
   - "Stáhni bundle a já ti pošlu link, kde uvidíš jak funguje s tvým gitea endpointem" — **NEJDE bez backendu**. Skip.

**Alternativní pohled:** Postavit **dokumentační site jako primární** (Docusaurus/Astro Starlight), wizard jako sekundární `/wizard` route. Galerie = generated z `agents/*.md` (single source of truth, zero drift). Hero = krátký screencast + 3 kódové bloky "co umí". Žádný showcase fancy.

**Pros:**
- Realistic scope — měsíc práce, ne 3.
- Doc-first = řeší v9.0.0 i v9.0.x maintenance burden (každý plugin update updatne docs, wizard auto-regenerates from schema).
- Reduce risk: pokud se wizard ukáže jako málo používaný, už máme value v docs site.
- Honest expectations: "showcase" je marketingový slovník, "docs site" je ten reálný value driver pro adoption.

**Cons:**
- Userova explicitní priorita "lidi to uvidi" → docs site je **slabší visual** než hero animation.
- Public launch ztráta "wow" faktoru — HN post "look at our agents" má slabší hook.
- Galerie redukce na 3 příklady = ztráta granularity (které agenty má customizovat?).
- Wizard sekundární = menší konverze "first-time visitor → instalace".

**Market precedents (jako counter-examples k A/B):**
- **Docusaurus, MkDocs, Starlight** — pure docs, zero showcase, vysoká adoption (Storybook, Babel, Jest).
- **Prisma early days** — začali s docs+CLI, hero showcase přišel až po PMF.
- **tRPC website** — hero je 1 GIF + code blocks, žádný interactive playground; má vysokou adoption.
- **counter-example k B:** Linear's site je krásný, ale Linear má product-market-fit už ověřený. ceos-agents nemá.

---

## 3. Judge synthesis

**Hodnocení proti userovým prioritám:**

| Priority | Proposal A | Proposal B | Proposal C |
|---|---|---|---|
| "lidi to uvidi" — visual-first | ✓ video hero | ✓✓ live replay | ✗ docs-style |
| Public launch driver (HN/Twitter share-ability) | ✓ slušný | ✓✓ shareable URL = viral | ✗ slabý |
| Pure FE constraint | ✓ | ✓ | ✓ |
| TOML schema match s A.1 | ✓ `@iarna/toml` battle-tested | △ custom serializer = risk | ✓ generated from schema |
| Mobile-friendly | ✓✓ | △ scroll-jacking risk | ✓✓ |
| Maintenance cost | ✓ low | ✗ high (3 pane + replay drift) | ✓ low |
| WCAG AA | ✓ | △ scroll-jacking + replay = a11y challenges | ✓ |
| Time-to-ship pro v9.0.0 | ✓ ~3 týdny | ✗ ~6-8 týdnů | ✓ ~3 týdny |
| Risk pokud schema změní v8.x.y | ✓ rebuild-deploy | ✗ replay JSON drift + custom serializer | ✓ schema-driven regen |

**Verdikt: Hybrid A + skepticky-informovaná zúžení z C, ne plný B.**

**Final recommendation:** Proposal **A jako foundation**, doplněno o:
- Hero = pre-recorded **deterministic DOM replay** (z B) místo video — odolnější vůči driftu (z C kritiky #4); fallback poster image pro slow connections.
- Agent gallery zůstává všech 18 (z A), ale generated build-time z `agents/*.md` frontmatteru (z C — single source of truth, zero drift).
- Wizard = stepper z A (NE 3-pane z B) — jednodušší mobile, jednodušší a11y, jednodušší maintenance.
- Live TOML preview = ano (z A/B), ale pravý panel jen TOML, ne agent-prompt diff (B feature škrtnut — wow nestojí za maintenance).
- Compare-2-agents mode = **odložit do v9.0.x patch** — ne v9.0.0 must-have.
- TOML serializer = `@iarna/toml` (z A) — battle-tested, ne custom (kritika z C #3).
- Download bundle versioned per plugin verze (z C kritiky #3): `ceos-agents-bundle-v{plugin-version}.zip`.

**Konkrétní rozhodnutí:**

| Decision | Choice | Důvod |
|---|---|---|
| **Framework** | Astro 5.x (`output: "static"`) | Static-first, Islands pro wizard interactivity, mainstream enough pro contributory, MIT |
| **Styling** | Tailwind CSS v3.x + 1 custom CSS file pro hero replay animation | Utility-first, accessible primitives via `@tailwindcss/forms`; žádné CSS-in-JS (pure FE constraint čistší) |
| **State management** | URL `URLSearchParams` jako primary; vanilla `<form>` jako secondary | Žádné Redux/Zustand; URL = share-link friendly + refresh-safe |
| **Build tool** | Vite (built into Astro) | Žádné rozhodnutí navíc |
| **TOML library** | `@iarna/toml` (MIT, ~15 KB gzip) | Battle-tested, Bidirectional parse+stringify, A.1 schema kompatibilní |
| **ZIP library** | `client-zip` (MIT, ~3 KB) | Zero dependencies, browser-native streams API |
| **Syntax highlighting** | Shiki (precomputed grammars build-time) | Žádný runtime parsing; same engine jako VS Code |
| **Hero format** | Deterministic DOM replay (`hero-pipeline.json` + 200 LoC replay engine) + poster image fallback | Odolnější vůči Claude Code UI drift než video; rebuilable z fixture |
| **Gallery cards count** | 18 (všech, build-time generated z `agents/*.md`) | Single source of truth; zero drift; user chce vidět granularitu |
| **Wizard steps count** | **5** (Stack → Tracker → Agents → Hooks → Review/Download) | Matchuje 5 hlavních decisions consuming projektu; každý step = 1 mobile screen |
| **Stack profiles ve wizardu** | **8** (matching `examples/configs/*.md`) — generated build-time z těch 8 souborů | Single source of truth; už existují |
| **Hosting target** | Static-host-agnostic (works on Pages/Vercel/Cloudflare/S3) — **decision deferred to v9.0.1** per roadmap | Astro `dist/` je deploy-anywhere |
| **Mobile breakpoint** | Tailwind defaults (`sm:` 640px primary) | Standard, mobile-first |
| **Accessibility target** | WCAG AA (Lighthouse a11y ≥ 95, axe-core 0 violations) | Userova constraint |
| **i18n** | English only v9.0.0 (no Czech yet) | Public launch je EN audience; CZ deferred |
| **Analytics** | Plausible self-hosted nebo žádné (decision v v9.0.1) | Privacy-respecting; není v9.0.0 blocker |

**Scope rozhodnutí:**

- Hero: 45-second deterministic DOM replay scenario (triage → analyst → fixer 2x ↔ reviewer → test → publisher), `<button>` pause/resume, poster image fallback, `prefers-reduced-motion` honored (replace with 3-frame static screenshot fade).
- Gallery: 18 cards, build-time generated z `agents/*.md` frontmatter (`name`, `description`, `model`, `style`) + první H2 (`## Goal`) jako blurb. Card detail modal = full markdown render z agent file. Filter: by model (opus/sonnet/haiku), by category (read-only / execution).
- Wizard: 5 steps (Stack → Tracker → Agents → Hooks → Review). Každý step = 1 form panel + Next button + URL state save. Live TOML preview right-panel (desktop) nebo bottom-collapsible (mobile, default expanded after step 3). Download bundle obsahuje `CLAUDE.md`, `customization/{agent}.toml` (jen pro customized agenty — ne všech 18), `INSTALL.md` s `claude plugin marketplace add` instrukcemi.
- TOML generation: 100 % match s A.1 schema. Test fixtures: 8 stack profiles × full wizard run → output ZIP musí pass `/scaffold-validate` lokálně. Tento test je v9.0.0 acceptance criterion.
- "Co dál" stránka: 3 kódové bloky (install, init, first run), GitHub link, docs link, Discord/community link (TBD jestli v9.0.0 existuje community channel — pokud ne, jen GitHub Discussions).

---

## 4. Open questions for spec phase

1. **Replay scenario source:** Pre-canned fixture nebo extracted from real `pipeline-history.md` run (sanitized)? Real run dává autenticitu ale add PII risk; canned dává kontrolu ale "fake" feeling.
2. **Agent example outputs ve gallery:** Kde brát "Example output" pro každou kartu? `tests/scenarios/` má fixture, ale jsou cherry-picked. Live z reálných runů = PII/credentials risk. Návrh: build-time generate z curated `examples/agent-outputs/*.md` (nový adresář, 18 souborů, peer-reviewed).
3. **TOML schema validation:** Web má vestavět JSON-schema validator pro TOML output? Pokud user upraví wizard form a wizard generuje invalid TOML (bug), user stáhne broken bundle. Validate-before-download = mandatory? Schema source?
4. **Bundle versioning policy:** Když plugin vyjde v v9.1.0 a schema se rozšíří, web musí re-deploy s novým schema. Co když user má hosted starou verzi webu (CDN cache)? Návrh: filename = `ceos-agents-bundle-v{plugin}.zip`, web má banner "this bundle is for plugin v9.0.0 — current is v9.1.0".
5. **Hero replay accessibility:** `prefers-reduced-motion` user dostane statický screenshot fade. Ale screen-reader user co dostane? Live region narrating "Agent triage-analyst started → completed in 2.3s" každý step? Verbosity vs. info value tradeoff.
6. **Wizard "Hooks" step semantics:** v8.0.0 zachovává Hooks optional sekci. Wizard má 4 hook types (Pre-fix, Post-fix, Pre-publish, Post-publish). User co nezná hook concept = co default? Návrh: skip-able step s "I'll add later" CTA.
7. **Gallery markdown rendering:** Render full agent .md souboru v modalu = bezpečné? Markdown může obsahovat raw HTML (sanitize via `rehype-sanitize`) — ale pak ztratíme YAML frontmatter. Návrh: parse frontmatter zvlášť, body sanitize.
8. **CI hookup:** Web má CI test že 18 cards = 18 souborů v `agents/`? Že 8 stack profiles = 8 souborů v `examples/configs/`? Drift detection v PR. Pokud ano, kde žije CI (Gitea Actions zatím nenakonfigurováno per `project_ci_runner_missing.md`).
9. **License attribution v webu:** Astro/Tailwind/Shiki/Iarna/client-zip licenses musí být v `LICENSES.md` v repu webu (nebo v `/licenses` route). Žádný bundle-included credits stránka přibalená do download ZIP?
10. **Search v gallery:** 18 cards je málo — search box přidává hodnotu? Nebo jen filter chips (model, category)? Návrh: jen filter chips v9.0.0, search v v9.0.x pokud feedback.

---

## 5. References

**Interní:**
- `docs/superpowers/specs/2026-04-26-A-agent-shape-design.md` — A.1 spec definující TOML schema
- `docs/superpowers/specs/2026-04-27-B-hitl-design.md` — B.1 HITL design (related v8.0.0)
- `docs/plans/roadmap.md` ř. 1040 — sub-projekt E roadmap entry
- `docs/plans/roadmap.md` ř. 1060-1065 — v9.0.0 scope rozhodnutí (D škrtnuto, F read-only, hosting → v9.0.1)
- `agents/*.md` — 18 souborů (po v8.0.0 konsolidaci) jako build-time source pro gallery
- `examples/configs/*.md` — 8 stack profiles jako build-time source pro wizard
- `core/agent-states.md` — v6.9.0 state contract (relevant pro F dashboard, ne přímo E)

**Tržní precedenty (proposal A foundation):**
- Astro framework + docs site (Islands architecture)
- Bun website (static + hero video)
- Hono framework site (Cloudflare Pages)
- TanStack docs (Astro + Islands)

**Tržní precedenty (proposal B inspirace pro hero replay):**
- Tailwind Play (live playground, ale 2-pane)
- shadcn/ui (gallery + theme switcher + CLI assist)
- Resend (DOM-based hero animation, ne video)
- Excalidraw (state v URL → shareable)
- Linear (scroll-jacked storytelling, mobile-broken counter-example)

**Tržní precedenty (proposal C counter-arguments):**
- Docusaurus, MkDocs, Astro Starlight (docs-first sites s vysokou adoption)
- Prisma early days (docs+CLI před hero showcase)
- tRPC website (1 GIF + code blocks → vysoká adoption)

**Out-of-scope sibling specs:**
- Sub-projekt F (Pipeline dashboard) — separátní spec, čte `pipeline-history.md` + `state.json`
- v10.0.0 Node.js Runtime — backend pro klik=spusť pipeline; separátní repo
- v9.0.1 hosting decision (GitHub Pages / Gitea Pages / Vercel)
