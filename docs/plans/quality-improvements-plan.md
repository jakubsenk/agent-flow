# BMAD Adoption Plan — Implementace vylepsheni z konkurencni analyzy

**Datum:** 2026-03-06
**Zdroj:** `docs/plans/bmad-comparison-analysis.md`
**Cil:** Chirurgicke zmeny do ceos-agents pluginu adoptujici nejhodnotnejsi koncepty z BMAD-METHOD

---

## Bod 1: Adversarialni review

- **Priorita:** P0
- **Dotcene soubory:** `agents/reviewer.md`
- **Dopad na Automation Config:** zadny
- **Zavislosti:** zadne

### Navrh zmen

**`agents/reviewer.md`** — upravit Process krok 4 a pridat nove Constraints:

Nahradit radky 25-46 (puvodni krok 4 a 5) za:

```markdown
4. **Adversarial review — find what's wrong:**
   You are an ADVERSARIAL reviewer. Assume problems exist and find them. Adopt a cynical stance — the fixer may have missed edge cases, introduced subtle bugs, or taken shortcuts.

   Apply review checklist:
   - **Root cause:** Does the fix address the actual root cause, not just symptoms?
   - **Completeness:** Are all affected paths covered (from impact report)?
   - **Conventions:** Does it follow project coding style (from CLAUDE.md)?
   - **Regressions:** Could this break existing callers (from impact report)?
   - **Security:** Any new vulnerabilities? Check for: injection (SQL, command, XSS), auth bypass, information leakage, insecure defaults
   - **Performance:** Could this introduce performance regression? (N+1 queries, unnecessary loops, blocking calls)
   - **Over-engineering:** Is the fix minimal or does it do unnecessary work?

5. **Edge case analysis:**
   For every changed file, systematically trace each branching path and boundary condition. Report any unhandled:
   - Null / undefined / empty inputs
   - Empty collections (zero-length arrays, empty maps)
   - Zero, negative, or overflow numeric values
   - Type coercion edge cases (string-to-number, falsy values)
   - Race conditions or timing issues in concurrent code
   - Early returns and guard clauses that bypass validation
   - Error handler paths that swallow or mishandle exceptions

6. **Issue count gate:**
   You MUST identify at least 3 specific issues per review. If after steps 4-5 you have fewer than 3 findings, re-examine the code for:
   - Architectural violations (coupling, responsibility leaks)
   - Missing documentation for non-obvious behavior
   - Integration risks with untested callers
   - Dependency version or compatibility concerns

   If you genuinely cannot find 3 issues after exhaustive re-examination, you may approve with fewer — but you MUST include a detailed explanation of why this fix is exceptionally clean, covering each checklist item explicitly.

7. Output review:

   ```markdown
   ## Code Review
   - **Verdict:** {APPROVE | REQUEST_CHANGES | BLOCK}
   - **Issues found:** {count}
   - **Issues:**
     1. [HIGH] {description} — {specific fix recommendation}
     2. [MEDIUM] {description} — {specific fix recommendation}
     3. [LOW] {description} — {specific fix recommendation}
   ```

   Issue severity tiers:
   - **HIGH:** Fix is incorrect, introduces a bug, or creates a security vulnerability. MUST be fixed before merge.
   - **MEDIUM:** Fix works but has a significant issue (missed edge case, convention violation, potential regression). SHOULD be fixed.
   - **LOW:** Minor improvement opportunity. Can be ignored without blocking.

   Verdict rules:
   - Any HIGH issue → REQUEST_CHANGES (or BLOCK if fundamental)
   - Only MEDIUM/LOW issues → APPROVE with listed issues (fixer may address in next iteration)
```

**Constraints** — pridat na radek 62 (pred stav. NEVER block a correct fix):

```markdown
- NEVER approve with zero findings unless you provide an explicit per-checklist-item justification (minimum 7 checklist items addressed)
```

**Odhadovany rozsah:** +30 radku v Process, +1 radek v Constraints. Celkova delka reviewer.md: ~74 → ~105 radku.

### Rizika a trade-offs

- **Risk:** Vynuceni 3 nalezu muze vest k umelym/irelevantnim nalezum u trivialnich oprav (1-radkovy typo fix)
- **Mitigace:** Klauzule "genuinely cannot find 3 issues" s povinnym zduvodnenim — neni to hard block, ale defaultni ocekavani
- **Trade-off:** Delsi review cykly (vice iteraci fixer↔reviewer), ale vyssi kvalita

---

## Bod 2: Edge case hunter

- **Priorita:** P0
- **Dotcene soubory:** `agents/reviewer.md`
- **Dopad na Automation Config:** zadny
- **Zavislosti:** zahrnut v Bodu 1 (krok 5 v reviewer Process)

### Navrh zmen

Integrovano primo do Bodu 1 jako novy Process krok 5 "Edge case analysis". Neni treba samostatny agent ani soubor — edge case analza je pod-krok revieweru.

Viz Bod 1, krok 5 vyse.

**Odhadovany rozsah:** 0 dodatecnych radku (uz zahrnuto v Bodu 1).

### Rizika a trade-offs

- **Risk:** Reviewer strávi vice tokenu na systematicke trasovani cest
- **Mitigace:** Krok je fokusovany na *zmenene soubory*, ne na celou codebase
- **Trade-off:** Vyssi naklady na review vs. mene post-merge regresi

---

## Bod 3: TDD-first pristup ve fixeru

- **Priorita:** P1
- **Dotcene soubory:** `agents/fixer.md`
- **Dopad na Automation Config:** zadny
- **Zavislosti:** zadne

### Navrh zmen

**`agents/fixer.md`** — nahradit Process krok 5 (radky 27-31) za:

```markdown
5. Implement the fix using red-green-refactor:
   - **RED:** Write a test that reproduces the bug. Run it — confirm it FAILS. If the test passes, your test does not capture the actual bug; rewrite it.
   - **GREEN:** Implement the minimal fix to make the failing test pass. Target root cause, not symptoms. Smallest possible change. Follow existing code conventions exactly. No unrelated cleanup or refactoring.
   - **REFACTOR:** If the fix introduced duplication or unclear code, clean up — but only within the changed scope.
   - If the project has no test infrastructure (no test framework, no test directory), skip the RED phase and implement the fix directly. Note "No test infrastructure — TDD skipped" in your output.
```

**Odhadovany rozsah:** Krok 5 roste z 5 radku na 6 radku. Celkova zmena: +1 radek.

### Rizika a trade-offs

- **Risk:** Nekteré projekty nemaji testovaci infrastrukturu — fixer by se zasekl na psani testu bez frameworku
- **Mitigace:** Explicitni fallback "skip RED phase if no test infrastructure"
- **Risk:** Reprodukcni test pro nekteré bugy je obtizne napsat (UI bugy, race conditions)
- **Mitigace:** Fixer ma stale moznost vysvetlit v outputu proc test nebyl mozny
- **Trade-off:** Mirne pomalejsi fix (psani testu nejdriv), ale vyssi spolehlivost oprav

---

## Bod 4: Brainstorming faze pro scaffold

- **Priorita:** P1
- **Dotcene soubory:** `commands/scaffold.md`
- **Dopad na Automation Config:** zadny
- **Zavislosti:** zadne (vyuziva existujici `superpowers:brainstorming` skill)

### Navrh zmen

**`commands/scaffold.md`** — pridat novy flag do Flag Parsing (radek 12) a novy krok pred Step 1:

Flag Parsing — pridat radek:
```markdown
- `--brainstorm` → brainstorm = true
```

Flag Validation — pridat radek po "--no-implement" validaci (radek 29):
```markdown
If --brainstorm AND --spec:
  Error: "--brainstorm is for exploring ideas. Use --spec when you already have a specification."
```

Pridat novy krok pred Step 1: Specification Phase (vlozit pred radek 145):

```markdown
### Step 0b: Brainstorming Phase (optional)

If `brainstorm = true` OR (mode is Interactive AND project description is vague — fewer than 20 words, no technical terms):

1. Tell the user: "Let's explore your idea before writing a spec. I'll ask a few questions to clarify the vision."
2. Ask up to 5 divergent questions:
   - "Who is the primary user? What problem are they solving today without this tool?"
   - "What does success look like in 3 months? What's the one metric that matters?"
   - "What's explicitly OUT of scope for v1?"
   - "Are there existing tools/competitors? What do they get wrong?"
   - "What's the riskiest technical assumption?"
3. After each answer, synthesize and probe deeper if needed (max 2 follow-ups per question).
4. Synthesize all answers into an enriched project description (200-400 words) that replaces the original description for spec-writer input.
5. Display the enriched description: "Here's what I understood. Continue with this? [Yes / Edit / Abort]"

If mode is not Interactive → skip (YOLO modes do not brainstorm).
```

**Odhadovany rozsah:** +3 radky v Flag Parsing, +2 radky v Flag Validation, +18 radku novy krok. Celkem: +23 radku.

### Rizika a trade-offs

- **Risk:** Pridani dalsich otazek zpomaluje scaffold workflow pro uzivatele, kteri vi co chteji
- **Mitigace:** Brainstorming je opt-in (--brainstorm flag) nebo auto-triggered jen pro vagne popisy v Interactive modu
- **Trade-off:** Delsi cas do prvniho vystupu vs. vyrazne lepsi specifikace

---

## Bod 5: Agent customizace

- **Priorita:** P1
- **Dotcene soubory:** `CLAUDE.md` (dokumentace konvence), `commands/fix-ticket.md`, `commands/fix-bugs.md`, `commands/implement-feature.md`, `commands/scaffold.md`
- **Dopad na Automation Config:** novy optional key `Agent Overrides` (cesta k adresari)
- **Zavislosti:** zadne

### Navrh zmen

**Konvence:** Konzumujici projekt muze mit adresar `customization/` (nebo jinou cestu nakonfigurovanou v Automation Config) s markdownovymi soubory pojmenovanymi po agentech. Obsah se pripoji k promptu agenta jako "## Project-Specific Instructions".

**`CLAUDE.md`** — pridat novou optional section do Config Contract tabulky (za Extra labels):

```markdown
| Agent Overrides | Path | customization/ |
```

A popis do textu pod tabulkou:

```markdown
### Agent Overrides

Optional directory with per-agent customization files. For each agent (e.g., `reviewer`, `fixer`, `test-engineer`), create a file `{path}/{agent-name}.md` with additional instructions. Contents are appended to the agent's prompt as `## Project-Specific Instructions`.

Example: `customization/reviewer.md` with content "Always check for SQL injection in all database queries" will add this instruction to every reviewer invocation.

Files that don't match any agent name are ignored. This allows project-specific tuning without forking the plugin.
```

**`commands/fix-ticket.md`**, **`commands/fix-bugs.md`**, **`commands/implement-feature.md`**, **`commands/scaffold.md`** — pridat do Configuration sekce:

```markdown
- **Agent Overrides** from Agent Overrides section (if it exists):
  - Path (default: `customization/`)
```

A pridat instrukci ke kazdemu Task tool call v orchestraci:

```markdown
Before dispatching any agent via Task tool, check if `{Agent Overrides path}/{agent-name}.md` exists.
If yes, append its content to the agent's context as: "## Project-Specific Instructions\n{file content}".
```

Toto je 1 radek v Configuration + 2 radky instrukce v kazdem commandu = ~12 radku celkem.

**Odhadovany rozsah:** ~5 radku v CLAUDE.md, ~3 radky v kazdem ze 4 commandu = ~17 radku celkem.

### Rizika a trade-offs

- **Risk:** Uzivatelske customizace mohou byt v konfliktu s agentuv core procesem (napr. "preskoc review checklist")
- **Mitigace:** Customizace se pridavaji jako *doplnek* (appended), ne nahrada — core instrukce maji prednost
- **Risk:** Slozitejsi debugging kdyz se agent chova neocekavane
- **Mitigace:** Customizacni soubory jsou citelne a verzovane v repozitari
- **Trade-off:** Mirne vetsi kontextove okno per agent vs. flexibilita per projekt

---

## Bod 6: Inteligentni guidance ve /status

- **Priorita:** P1
- **Dotcene soubory:** `commands/status.md`
- **Dopad na Automation Config:** zadny
- **Zavislosti:** zadne

### Navrh zmen

**`commands/status.md`** — pridat novy krok 7 za stav. krok 6 (radek 37):

```markdown
7. **Recommended next steps:**

   Analyze the project state and display context-aware recommendations:

   a. If no CLAUDE.md exists in CWD:
      → "No CLAUDE.md found. Run `/ceos-agents:onboard` to configure this project."

   b. If CLAUDE.md exists but Automation Config has TODO markers (`<!-- TODO:`):
      → "Automation Config has incomplete sections: {list}. Fill them in or run `/ceos-agents:template`."

   c. If Automation Config is complete but `/ceos-agents:check-setup` was never run (no `.claude/setup-validated` marker):
      → "Run `/ceos-agents:check-setup` to validate your configuration."

   d. Based on issue states:
      - If blocked > 0: "**{N} blocked issues** need human attention. Run `/ceos-agents:analyze-bug <ID>` to investigate."
      - If in_progress > 0 and no recent commits on their branches (>24h): "**{N} stale in-progress issues** — consider `/ceos-agents:resume-ticket <ID>`."
      - If for_review > 0: "**{N} PRs awaiting review.**"
      - If no active issues: "No active issues. Run `/ceos-agents:fix-bugs <N>` to pick up new bugs or `/ceos-agents:prioritize` to analyze the backlog."

   e. If Feature Workflow → Feature query exists and has unstarted features:
      → "**{N} features in backlog.** Run `/ceos-agents:implement-feature <ID>` or `/ceos-agents:prioritize` for recommendations."

   Display as:
   ```
   ### Recommended Next Steps
   1. {most urgent recommendation}
   2. {second recommendation}
   ```
   Maximum 3 recommendations. Most urgent first.
```

**Odhadovany rozsah:** +22 radku. Celkova delka status.md: 44 → ~66 radku.

### Rizika a trade-offs

- **Risk:** Doporuceni mohou byt nepresna pokud issue tracker neni dostupny (MCP offline)
- **Mitigace:** Doporuceni se zobrazuji az po uspesnem query — pokud query selze, sekce se preskoci
- **Trade-off:** Mirne pomalejsi /status (vice dotazu), ale vyrazne lepsi DX

---

## Bod 7: Step-file architektura

- **Priorita:** P2 (odlozit dokud nebude dukaz o degradaci kontextu)
- **Dotcene soubory:** `commands/fix-bugs.md` (414r), `commands/scaffold.md` (443r)
- **Dopad na Automation Config:** zadny
- **Zavislosti:** zadne

### Navrh zmen

**Struktura:** Rozdelit kazdy velky command na adresář se step soubory:

```
commands/fix-bugs/
  index.md          ← entry point (config parsing, flag parsing, fetch bugs, mode selection) ~80r
  step-triage.md    ← triage + code-analyst + decomposition decision ~80r
  step-fix.md       ← fixer + build + hooks + custom agents ~60r
  step-review.md    ← reviewer loop ~30r
  step-test.md      ← test-engineer + e2e ~30r
  step-publish.md   ← publisher + hooks + webhooks + verification ~70r
  step-block.md     ← block handler ~40r
  step-worktree.md  ← worktree processing variant ~50r

commands/scaffold/
  index.md          ← entry point (flag parsing, state detection, mode selection) ~70r
  step-spec.md      ← spec-writer ↔ spec-reviewer loop + checkpoint ~50r
  step-skeleton.md  ← scaffolder + validation + move + git init ~60r
  step-plan.md      ← architect + decomposition + checkpoint ~50r
  step-implement.md ← feature implementation loop ~80r
  step-finalize.md  ← e2e tests + issue tracker + final report ~60r
  legacy.md         ← --no-implement flow ~50r
```

**Orchestracni mechanismus:** Kazdy `index.md` obsahuje:
```markdown
## Step Loading

Process steps sequentially. For each step:
1. Read the step file content
2. Execute the instructions in the step file
3. Proceed to the next step (or the step indicated by the current step's "Next" directive)

NEVER load more than one step file at a time.
```

Kazdy step soubor konci s:
```markdown
## Next
→ Proceed to `step-{next}.md`
```

**Zpetna kompatibilita:** Puvodni `commands/fix-bugs.md` a `commands/scaffold.md` se nahradi symlinky na `fix-bugs/index.md` resp. `scaffold/index.md`, nebo se nahrazuji jednorádkovym redirectem.

**Odhadovany rozsah:** ~420 radku (fix-bugs) + ~420 radku (scaffold) — celkový pocet radku se nezmeni, jen se redistribuuje. Plus ~20 radku orchestracni boilerplate v kazdem index.md.

### Rizika a trade-offs

- **Risk:** Claude Code zatim nepodporuje "nacti step soubor a pokracuj" nativne — museli bychom to simulovat Read tool calls
- **Mitigace:** Testovat na jednoduchém command nejdrive (napr. scaffold --no-implement flow)
- **Risk:** Debugging slozitejsi — chyba muze byt v jakemkoli step souboru
- **Mitigace:** Kazdy step je samostatny a testovatelny
- **Trade-off:** Vyssi pocet souboru vs. lepsi sprava kontextu
- **DOPORUCENI:** Odlozit na P2 — implementovat az kdyz budou dukazy o degradaci kontextu u 400+ radkovych commandu

---

## Bod 8: Sablony a checklisty

- **Priorita:** P2
- **Dotcene soubory:** nove soubory v `checklists/`, `agents/reviewer.md`, `agents/test-engineer.md`
- **Dopad na Automation Config:** zadny
- **Zavislosti:** Bod 1 (reviewer zmeny)

### Navrh zmen

**Nove soubory:**

**`checklists/review-checklist.md`:**
```markdown
# Code Review Checklist

## Correctness
- [ ] Fix addresses root cause, not symptoms
- [ ] All affected code paths covered
- [ ] No new bugs introduced

## Security
- [ ] No injection vulnerabilities (SQL, command, XSS)
- [ ] No auth bypass
- [ ] No information leakage
- [ ] No insecure defaults

## Quality
- [ ] Follows project coding conventions
- [ ] No unnecessary changes or refactoring
- [ ] Diff is minimal and focused
- [ ] No performance regressions (N+1, blocking calls)

## Edge Cases
- [ ] Null/undefined inputs handled
- [ ] Empty collections handled
- [ ] Boundary values handled (zero, negative, overflow)
- [ ] Error paths tested
- [ ] Concurrent access safe (if applicable)

## Integration
- [ ] Backwards compatible (no public API changes without approval)
- [ ] Existing callers not broken
- [ ] Dependencies stable and compatible
```

**`checklists/test-checklist.md`:**
```markdown
# Test Checklist

## Coverage
- [ ] Happy path tested
- [ ] Error path tested
- [ ] Edge cases tested (null, empty, boundary)
- [ ] Regression test for the specific bug (reproduces original issue)

## Quality
- [ ] Tests follow Arrange-Act-Assert pattern
- [ ] Tests are independent (no shared mutable state)
- [ ] Tests use project conventions (framework, naming, location)
- [ ] No flaky tests (no timing dependencies, no external service calls)

## Completeness
- [ ] All changed functions have test coverage
- [ ] Test names describe expected behavior
- [ ] Assertions are specific (not just "no error thrown")
```

**`checklists/publish-checklist.md`:**
```markdown
# Publish Checklist

- [ ] All tests pass
- [ ] Build succeeds
- [ ] Branch is up to date with base branch
- [ ] PR description follows template
- [ ] PR has correct labels
- [ ] No untracked files left behind
- [ ] Issue tracker state updated
```

**Agent reference:** Pridat do `agents/reviewer.md` a `agents/test-engineer.md`:
```markdown
Reference checklist: `checklists/{name}-checklist.md` — use as validation gate.
```

**Odhadovany rozsah:** 3 nove soubory (~80 radku celkem), +1 radek ve 2 agentech.

### Rizika a trade-offs

- **Risk:** Checklisty mohou byt ignorovany agentem pokud nejsou nacteny do kontextu
- **Mitigace:** Agent referuje checklist — command musi checklist precist a predat jako kontext
- **Trade-off:** Vice souboru k udrzovani vs. explicitni a auditovatelne kvalitativni brany

---

## Bod 9: YOLO rezim pro vsechny prikazy

- **Priorita:** P2
- **Dotcene soubory:** `commands/fix-ticket.md`, `commands/implement-feature.md`
- **Dopad na Automation Config:** zadny
- **Zavislosti:** zadne

### Navrh zmen

**`commands/fix-ticket.md`** — pridat `--yolo` flag:

Flag parsing (radek 13):
```markdown
If $ARGUMENTS contains `--yolo`, activate YOLO mode: skip all user confirmations (decomposition plan approval, publish decision). Auto-approve decomposition. Auto-publish after successful pipeline.
```

Zmeny v orchestraci:
- Krok 3b (Decomposition decision, radek 134): "Display plan and wait for confirmation" → "If `--yolo` → auto-approve. Otherwise display plan and wait for confirmation."
- Krok 9 (Result, radek 226-228): "the user decides about publishing" → "If `--yolo` → auto-publish. Otherwise the user decides."

**`commands/implement-feature.md`** — pridat `--yolo` flag:

Flag parsing (radek 8):
```markdown
Input: `$ARGUMENTS` = Issue ID (required) + optional flags (`--decompose`, `--no-decompose`, `--dry-run`, `--profile <name>`, `--yolo`)
```

Zmeny v orchestraci:
- Krok 5 (Decomposition decision, radek 127): "Wait for confirmation" → "If `--yolo` → auto-approve. Otherwise wait for confirmation."
- Krok 9 (Display result, radek 222-223): "Create PR? [Y/n]" → "If `--yolo` → auto-create PR. Otherwise ask."

**Odhadovany rozsah:** +5 radku v kazdem commandu = +10 radku celkem.

### Rizika a trade-offs

- **Risk:** YOLO mod snizuje bezpecnost — uzivatel nevidí decomposition plan pred implementaci
- **Mitigace:** YOLO je explicitni opt-in flag; uzivatel si ho musi vedomne zapnout
- **Risk:** Auto-publish bez kontroly muze vest k PR s problemy
- **Mitigace:** Pipeline stale prochazi review + test stages — reviewer a test-engineer jsou quality gates
- **Trade-off:** Rychlost vs. kontrola — vhodne pro power uzivatele a CI/CD prostredi

---

## Bod 10: Osobnost agentu

- **Priorita:** P2
- **Dotcene soubory:** vsech 15 souboru v `agents/`
- **Dopad na Automation Config:** zadny
- **Zavislosti:** zadne

### Navrh zmen

Pridat `style` field do frontmatteru kazdeho agenta. Toto pole je popisne, ne direktivni — pomaha uzivateli identifikovat agenta a nastavuje ton.

```yaml
# agents/reviewer.md
---
name: reviewer
description: Senior code reviewer and quality gate. Ensures root cause fix, convention compliance, no regressions. Read-only — provides feedback only.
model: opus
style: Adversarial, evidence-driven, thorough
---

# agents/fixer.md
style: Pragmatic, minimal, surgical

# agents/triage-analyst.md
style: Analytical, systematic, concise

# agents/code-analyst.md
style: Methodical, detail-oriented, risk-aware

# agents/test-engineer.md
style: Defensive, coverage-focused, precise

# agents/e2e-test-engineer.md
style: User-journey focused, resilient, thorough

# agents/publisher.md
style: Mechanical, checklist-driven, cautious

# agents/rollback-agent.md
style: Swift, safety-first, minimal

# agents/architect.md
style: Strategic, systems-thinking, trade-off aware

# agents/spec-analyst.md
style: Requirements-focused, clarity-driven, structured

# agents/spec-writer.md
style: Visionary, comprehensive, user-centric

# agents/spec-reviewer.md
style: Critical, feasibility-focused, consistency-checking

# agents/scaffolder.md
style: Efficient, convention-following, minimal

# agents/stack-selector.md
style: Decisive, opinionated, rationale-driven

# agents/priority-engine.md
style: Data-driven, impact-focused, objective
```

**Odhadovany rozsah:** +1 radek v kazdem z 15 souboru = +15 radku celkem.

### Rizika a trade-offs

- **Risk:** `style` field nema runtime efekt pokud ho agent neco nepouzije
- **Mitigace:** Claude Code zobrazuje frontmatter v agent pickeru — style pridava kontext
- **Trade-off:** Minimalni naklady na implementaci; potencialne zadny meritelny vliv na kvalitu, ale zlepsi DX a identifikaci agentu
- **POZNAMKA:** Na rozdil od BMAD *nedavame agentum jmena* (Mary, Winston...) — to by bylo v rozporu s nasi funkcni architekturou. `style` je subtilni hint, ne persona.

---

## Bod 11: Anti-bias protokoly v brainstormingu

- **Priorita:** P2
- **Dotcene soubory:** `commands/scaffold.md` (v ramci Bodu 4)
- **Dopad na Automation Config:** zadny
- **Zavislosti:** Bod 4 (brainstorming faze)

### Navrh zmen

Integrovano do Bodu 4 — pri brainstormingove fazi pridat anti-bias instrukce:

Pridat na konec Step 0b (viz Bod 4):

```markdown
   **Anti-bias rules for brainstorming:**
   - Do NOT lead with your own suggestions first — ask the user BEFORE proposing solutions
   - Present at least 2 contrasting approaches for any architectural decision
   - Explicitly name trade-offs for each approach (not just pros)
   - If the user anchors on a specific technology early, challenge it: "What would this look like with {alternative}?"
   - Avoid confirmation bias: after synthesizing, ask "What am I missing? What feels wrong?"
```

**Odhadovany rozsah:** +6 radku v scaffold.md (jako soucast Bodu 4).

### Rizika a trade-offs

- **Risk:** Anti-bias pravidla mohou zpomalit brainstorming zbytecnym zpochybnovanim rozhodnuti
- **Mitigace:** Pravidla jsou navrhova, ne blocking — agent je muze pouzit s uvazenim
- **Trade-off:** Delsi brainstorming vs. robustnejsi specifikace

---

## Bod 12: Party mode

- **Priorita:** P2 (low — experimentální koncept)
- **Dotcene soubory:** novy command `commands/discuss.md`
- **Dopad na Automation Config:** zadny
- **Zavislosti:** zadne

### Navrh zmen

**Novy soubor `commands/discuss.md`:**

```markdown
---
description: Multi-agent discussion — brings 2-3 agent perspectives into one conversation
allowed-tools: Task, Read, Glob, Grep
---

# Discuss

Input: `$ARGUMENTS` = topic or question + optional `--agents <list>` (comma-separated agent names)

## Steps

1. Parse `$ARGUMENTS`:
   - `--agents reviewer,fixer,architect` → agent_list
   - Default agent_list: `reviewer,fixer,architect` (if not specified)
   - Remainder = topic
   - Max 3 agents per discussion

2. For each agent in agent_list (in parallel):
   Run agent via Task tool with context:
   ```
   You are participating in a multi-agent discussion about: {topic}
   Your role: {agent description from frontmatter}
   Style: {agent style from frontmatter}

   Provide your perspective on this topic in 100-200 words.
   Focus on concerns and insights specific to YOUR expertise.
   Be opinionated — disagree with conventional wisdom if your expertise suggests otherwise.
   ```

3. Collect all agent responses.

4. Display as structured discussion:
   ```
   ## Discussion: {topic}

   ### {agent-1 name} ({agent-1 style})
   {agent-1 perspective}

   ### {agent-2 name} ({agent-2 style})
   {agent-2 perspective}

   ### {agent-3 name} ({agent-3 style})
   {agent-3 perspective}

   ### Synthesis
   {synthesize key agreements, disagreements, and recommended approach}
   ```

5. Ask: "Follow up on any perspective? [agent name / done]"
   If user picks an agent → run that agent again with the full discussion context for deeper exploration.

## Rules

- Max 3 agents per discussion
- Read-only — no code changes
- Each agent response: 100-200 words max
- Discussion is for exploration, not decisions — no pipeline side effects
```

**Odhadovany rozsah:** ~50 radku, 1 novy soubor. Novy command = MINOR version bump.

### Rizika a trade-offs

- **Risk:** Umelé "diskuze" mezi agenty mohou byt povrchni — kazdy agent bezi izolované, neni to skutecna konverzace
- **Mitigace:** Format "perspektivy + synteza" je uzitecnejsi nez simulovana konverzace
- **Risk:** Dalsi command k udrzovani
- **Trade-off:** Nízka priorita, ale unikatni feature ktery zadny jiny CI/CD plugin nenabizi

---

## Implementacni plan

### Faze 1: Okamzite zmeny (S scope, 1 session)

| Porad | Bod | Soubor(y) | Zmena | ~Radku |
|-------|-----|-----------|-------|--------|
| 1.1 | 1+2 | `agents/reviewer.md` | Adversariální review + edge case hunter | +30 |
| 1.2 | 3 | `agents/fixer.md` | TDD red-green-refactor v Process krok 5 | +1 |
| 1.3 | 10 | `agents/*.md` (15 souboru) | `style` field ve frontmatteru | +15 |

**Celkem Faze 1:** ~46 radku zmen, 16 souboru dotcenych. **Scope: S**

### Faze 2: Stredni zmeny (M scope, 1-2 sessions)

| Porad | Bod | Soubor(y) | Zmena | ~Radku |
|-------|-----|-----------|-------|--------|
| 2.1 | 6 | `commands/status.md` | Inteligentni guidance "co dal" | +22 |
| 2.2 | 4+11 | `commands/scaffold.md` | Brainstorming faze + anti-bias | +29 |
| 2.3 | 5 | CLAUDE.md + 4 commands | Agent customizace konvence | +17 |
| 2.4 | 9 | 2 commands | --yolo flag pro fix-ticket, implement-feature | +10 |

**Celkem Faze 2:** ~78 radku zmen, 7 souboru dotcenych. **Scope: M**

### Faze 3: Vetsi zmeny (L scope, odlozeno)

| Porad | Bod | Soubor(y) | Zmena | ~Radku |
|-------|-----|-----------|-------|--------|
| 3.1 | 8 | `checklists/` (3 nove soubory) | Sablony checklistu | +80 |
| 3.2 | 12 | `commands/discuss.md` | Party mode multi-agent diskuze | +50 |
| 3.3 | 7 | `commands/fix-bugs/`, `commands/scaffold/` | Step-file architektura | ~840 (redistribuce) |

**Celkem Faze 3:** ~130 novych radku + redistribuce. **Scope: L**

### Poradi implementace

```
Faze 1 (P0+quick wins) ──→ Faze 2 (P1) ──→ Faze 3 (P2, on demand)
     ↓                          ↓                    ↓
  1.1 Reviewer adversarial   2.1 Status guidance   3.1 Checklists
  1.2 Fixer TDD             2.2 Brainstorm         3.2 Discuss command
  1.3 Agent styles           2.3 Agent overrides    3.3 Step-file (evidence-based)
                             2.4 YOLO flags
```

### Verze

- **Faze 1:** Patch (v4.0.2) — zmeny v existujicich agentech, zadne nove features/keys
- **Faze 2:** Minor (v4.1.0) — novy optional key `Agent Overrides`, nove flagy `--yolo` a `--brainstorm`
- **Faze 3:** Minor (v4.2.0) — novy command `/discuss`, nove soubory v `checklists/`

### Co NEADOPTUJEME z BMAD

1. **Multi-IDE support** — vyzaduje runtime kod (CLI instaler), je v rozporu s "pure markdown" architekturou. Pokud bude demand, udela se jako samostatny tool, ne soucast pluginu.
2. **Pojmenovane persony** (Mary, Winston) — v rozporu s funkcni architekturou ceos-agents. Subtilni `style` field je dostatecny.
3. **Sprint planning/tracking** — ceos-agents neni project management tool; issue tracking delegujeme na externi trackery.
4. **Modulovy ekosystem (npm)** — vyzaduje runtime. Hooks + custom agents + agent overrides pokryvaji 80% customizacnich potreb.
5. **PRD / UX design workflow** — prilis velky scope; nase spec-writer ↔ spec-reviewer smycka pokryva zakladni potrebu. Lze doplnit v budoucnosti.
