# Sub-projekt B — Human-in-the-Loop: Design Spec (v8.0.0)

**Verze:** B.1 brainstorm output
**Datum:** 2026-04-27
**Cílový release:** v8.0.0 (společně s A — viz `2026-04-26-A-agent-shape-design.md`)
**Status:** Design spec připravený k validaci uživatelem; po schválení vstupuje do v8.0.0 forge pipeline společně s A spec

---

## 1. Context

Sub-projekt B z roadmapu (řádky 1009–1019) — Human-in-the-Loop pipelines. Cíl: konfigurovatelné approval gates + per-step diskuze.

**Klíčové zjištění brainstorm fáze (2026-04-27):**

A.1 design spec (sub-projekt A) **vyřešil core HITL story** přes mode framework:
- `--yolo` (zero gates, existující)
- default (strategic conditional gates, existující)
- `--step-mode` (NEW — per-agent prompts po každém step v `steps/*.md`)
- NEEDS_CLARIFICATION (ortogonální feature, existující v6.9.0 — tracker async pro ambiguity events)
- pipeline-history.md audit trail (existující v6.9.0)

→ Public-release safety story je kompletní bez dalšího sub-projektu B práce.

**Z 6 původně plánovaných B items (B1–B6) zůstává v scope v8.0.0 jen B6.** Ostatní (B1, B3, B4, B5) jsou polish vyřešený v A.1 nebo forge phase 4 detail; B2 přesunut do roadmap BACKLOG bez verze (post-launch reactive).

### 1.1 Out of scope (explicitně)

- **B2 — Event-driven gate detection** ("smoke alarm" pro default mode, fixer iter > N + same-issue detection): přesunut do `docs/plans/roadmap.md` BACKLOG sekce bez verze. Trigger = reálná autopilot data ukazující stuck-pattern frequency > 5%.
- **B1 — Revize default strategic gates**: A.1 zachovává current gate inventory beze změny; revize je polish, ne blocker.
- **B3 — Configurable thresholds**: závisí na B2; bez B2 není co konfigurovat.
- **B4 — `--step-mode` UX wording**: A.1 OQ-A.7 explicitně předáno forge phase 4 spec (wording "Continue / Skip remaining gates / Abort", state persistence při abort).
- **B5 — NEEDS_CLARIFICATION rozšíření** (multi-question batches, multi-agent chains): funguje od v6.9.0, žádný reportovaný pain.

### 1.2 Vztah k A.1

A.1 deklaruje **mode flags contract**: `--yolo`, default, `--step-mode`. B6 **rozšiřuje tento kontrakt na scaffold pipeline** (kde A.1 nechal scaffold beze změny).

---

## 2. Rozhodnutí (1 dimenze)

### B6 — Scaffold Mode Harmonizace

**Rozhodnutí:** Sjednotit scaffold mode selection s mode flags z A.1 (`--yolo`, default, `--step-mode`) napříč všemi 3 pipelines (fix-bugs, implement-feature, scaffold).

#### 2.1 Současný stav scaffold (verifikováno `skills/scaffold/SKILL.md` 2026-04-26)

Scaffold má **3 mode selection na začátku** (Step ~1):

| Dnešní scaffold mode | Co dělá |
|---|---|
| (a) Interactive | brainstorm if vague (Step ~1) + Spec Checkpoint (Step 2) + Feature Plan Checkpoint (Step 6) + průběžné prompts |
| (b) YOLO with checkpoint | pouze 2 mandatory checkpoints (Spec, Feature Plan); skip brainstorm |
| (c) Full YOLO | zero gates; všechno autonomous |

Scaffold tedy používal **separátní HITL koncept** od fix-bugs / implement-feature, které mají flag-based mode (`--yolo` flag).

#### 2.2 Cílový stav (po B6)

| Dnešní scaffold mode | Nový stav v v8.0.0 | Behavior |
|---|---|---|
| (a) Interactive | **default** (žádný flag) | Brainstorm if vague + Spec Checkpoint + Feature Plan Checkpoint (jako dnes) |
| (b) YOLO with checkpoint | **default** (sloučeno s (a)) | Stejné jako (a) — brainstorm pouze triggers při vague description, jinak skip; jediný reálný rozdíl mezi (a) a (b) byl "skip brainstorm", což default zvládne automaticky |
| (c) Full YOLO | **`--yolo` flag** | Zero gates, žádný brainstorm, autonomous |
| **NEW** | **`--step-mode` flag** | Per-agent pauzy (parita s fix/feat A.1) |

**Praktický důsledek pro uživatele:**

```
DNES:
/scaffold "popis"           → interactive prompt "Choose mode: (a) Interactive / (b) YOLO-checkpoint / (c) Full YOLO"

PO B6:
/scaffold "popis"           → default mode (brainstorm if vague + 2 checkpointy)
/scaffold "popis" --yolo    → fully autonomous, žádné checkpointy
/scaffold "popis" --step-mode → po každém agentovi pauza
```

#### 2.3 Důvody

1. **Konzistence napříč 3 pipelines.** Uživatel se učí 1 koncept (flag-based mode) místo 2 (mode selection prompt + flag). Public-release safety driver primary.
2. **(a) a (b) byly z velké části duplikát.** Reálný rozdíl byl pouze "skip brainstorm". Default mode to zvládne automaticky (brainstorm triggers při vague description, jinak skip — již existující logika v Step ~1).
3. **`--step-mode` parita.** Dnes scaffold nemá per-agent pause option; B6 ji přidává jako konzistentní s fix/feat.

#### 2.4 Co se ztratí (transparent)

- **Power users závislí na (b) YOLO-with-checkpoint** explicitně skip-brainstorm musí napsat dostatečně non-vague description (>20 slov, technical terms — current trigger heuristic). Ostatní edge case = `--no-brainstorm` flag, který **NENÍ v B6 scope** (může vzniknout post-v8.0.0 pokud je reportovaný pain).

#### 2.5 Migration impact (breaking change)

- Existing scripts používající interactive mode prompt selhají (mode selection prompt je odstraněn)
- Migration helper: pokud uživatel pustí `/scaffold` bez flag a description je vague, default mode triggeruje brainstorm (= equivalent staré (a) Interactive)
- Pokud uživatel chtěl (b) YOLO-with-checkpoint, default mode dělá ekvivalent
- Pokud uživatel chtěl (c) Full YOLO, použije `--yolo` flag

#### 2.6 Evidence

- Run 2 Q22 (Cline) — `--yolo` mode formalizován jako flag pattern, ne mode selection prompt [Q22]
- Run 2 Q16 (Cursor) — flag-based mode (sync diff review default + YOLO) [Q16]
- A.1 D3 contract — 3 mode flags napříč fix/feat pipeline; B6 extends to scaffold pro konzistenci

---

## 3. Documentation Requirements

Per `project_v8_doc_requirements.md` HIGH PRIORITY: B6 scaffold mode change vyžaduje:

- `docs/guides/migration-v7-to-v8.md` — sekce "Scaffold mode migration" s konkrétními příklady (před/po command syntax + mode equivalence table)
- `docs/reference/skills.md` — `/scaffold` skill description aktualizovat (3 modes → 3 flags)
- `docs/reference/automation-config.md` — pokud existuje sekce o scaffold, aktualizovat
- `examples/configs/*.md` — všech 8 templates aktualizovat scaffold examples (žádný mention "Interactive / YOLO-checkpoint / Full YOLO")
- `README.md` — scaffold examples updated
- `CHANGELOG.md` — breaking change entry s konkrétním migration path

---

## 4. Open Questions for Implementation Phase (forge)

**OQ-B.1: Brainstorm trigger heuristic v default mode.** Současná logika "vague description: <20 slov, no technical terms → brainstorm". Forge phase 4 spec: validovat že tato heuristika je dostatečně robustní pro odstranění (b) YOLO-with-checkpoint mode.

**OQ-B.2: `--no-brainstorm` flag escape hatch.** Měl by `--yolo` implicitně skip-brainstorm (yes, per design), ale co když user chce default mode bez brainstormu? `--no-brainstorm` flag = post-v8.0.0 add pokud reportovaný pain; v8.0.0 explicit out-of-scope.

**OQ-B.3: Mode flag parsing v scaffold SKILL.md.** A.1 OQ-A.7 už řeší pro fix/feat. B6 přidá identický pattern do scaffold/SKILL.md — implementační pattern reuse.

---

## 5. References

- A.1 design spec: `docs/superpowers/specs/2026-04-26-A-agent-shape-design.md` (D3 mode framework)
- Run 1 final.md: `.forge/2026-04-26-A-research-run1/phase-2-research-answers/final.md` (Q6 HITL evidence)
- Run 2 final.md: `.forge/2026-04-26-A-research-run2/phase-2-research-answers/final.md` (Q22 Cline timeline, Q16 Cursor flag pattern)
- Roadmap: `docs/plans/roadmap.md` BACKLOG sekce — B2 deferral entry
- Memory: `project_v8_doc_requirements.md` (HIGH PRIORITY docs)

---

## 6. Next Steps

1. **User reviews B.1 spec** (this document) — feedback / approval
2. **A + B spec consolidation:** A spec + B spec → input do v8.0.0 forge phase 4 spec (forge sám dělá consolidation v phase 4)
3. **v8.0.0 forge run:** Phase 4 spec → 5 TDD → 6 plan → 7 execute → 8 verify → 9 completion (po dokončení v7.0.0 forge runu paralelně)
