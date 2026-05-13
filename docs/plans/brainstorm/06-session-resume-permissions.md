# 06 — Session resume permission prompty

## Aktualni stav

### Problem

Kdyz uzivatel prerusi session a vrati se pres `claude -c` (continue), Claude Code se zacne ptat na povoleni pro kazdy tool call (Read, Write, Bash, MCP, atd.) — i kdyz v predchozi session byly tyto nastroje povoleny.

### Analyza: Plugin nebo platforma?

**Toto je chovani Claude Code platformy, ne pluginu.**

Dukazy:
1. CLAUDE-agents je ciste markdown plugin — nema runtime kod, hooks, ani permission management
2. Claude Code permission system je session-scoped (nebo file-scoped pres `.claude/settings.json`)
3. Plugin commands pouzivaji `allowed-tools` v frontmatter — ale to definuje KTERE tools jsou dostupne, ne zda jsou auto-approved
4. Zadny command ani agent v CLAUDE-agents nemanipuluje s permissions

### Jak Claude Code resi permissions

Claude Code ma 3 urovne trvaleho permission managementu plus 1 scope mechanismus:

1. **Session permissions** — docasne, plati jen pro aktualni session. Pri `claude -c` se session **obnovi**, ale permission state se muze resetovat (zavisi na verzi Claude Code)

2. **Project settings** (`.claude/settings.json`) — trvale per-project. Zde lze nastavit auto-approval pro nastroje.

   > **Poznamka:** Presny JSON format (`permissions.allow`, `permissions.deny`) je odvozeny z pozorovaneho chovani Claude Code a muze se lisit mezi verzemi platformy. Overujte aktualni dokumentaci Claude Code.

   Prikladova struktura (muze se lisit podle verze Claude Code):
   ```json
   {
     "permissions": {
       "allow": ["Read", "Write", "Edit", "Glob", "Grep", "Bash", "mcp__*"],
       "deny": []
     }
   }
   ```

3. **Global settings** (`~/.claude/settings.json`) — trvale globalni, plati pro vsechny projekty.

**Scope mechanismus (neni permission management):**

4. **`allowed-tools` ve frontmatter** — definuje scope dostupnych nastroju pro command, ale **neovlivnuje auto-approval**. Toto je omezeni pluginu, ne nastaveni pro uzivatele.

### Doporuceni: Global vs. Project-level settings

| Pouziti | Doporucena uroven | Duvod |
|---------|-------------------|-------|
| Jeden projekt s CLAUDE-agents | Project (`.claude/settings.json`) | Permissions specificke pro projekt |
| Vice projektu s CLAUDE-agents | Global (`~/.claude/settings.json`) | Sdilene nastaveni, neni treba opakovat per-project |
| Mix pluginu s ruznymi pozadavky | Project + Global | Global pro zakladni tools, project pro specificke MCP |

Pro uzivatele, kteri pouzivaji CLAUDE-agents across multiple projects, je **globalni nastaveni praktictejsi** — staci nakonfigurovat jednou.

### Proc se po resume pta znovu

Mozne priciny:
- **Session permission cache reset** — Claude Code pri resume nacte kontext, ale ne permission state
- **Tool approval je per-invocation** — kazdy tool call vyzaduje schvaleni, pokud neni v allowlist
- **MCP tools** (`mcp__*`) mohou mit jiny permission model nez built-in tools

---

## Co muze plugin udelat

### Moznost 1: Nic (dokumentovat)

Plugin nemuze ovlivnit permission management Claude Code. Muze ale dokumentovat, jak si uzivatel nastavi trvale permissions.

**Pridat do `docs/guides/troubleshooting.md`:**

```markdown
## Permission prompts after session resume

When resuming a session with `claude -c`, you may be prompted for tool
permissions again. This is Claude Code platform behavior.

### Fix: Configure permanent permissions

Add to `.claude/settings.json` (project-level) or `~/.claude/settings.json`
(global) — exact format may vary by Claude Code version:

{
  "permissions": {
    "allow": [
      "Read", "Write", "Edit", "Glob", "Grep", "Bash",
      "mcp__youtrack__*", "mcp__gitea__*"
    ]
  }
}

Or use the CLI: `claude config set permissions.allow '["Read","Write","Edit","Glob","Grep","Bash","mcp__*"]'`
```

**Effort:** S
**Impact:** Resi problem pro informovane uzivatele

### Moznost 2: Onboard wizard generuje `.claude/settings.json`

Rozsirit onboard o Step 8b (MCP setup v doc 02 zabira Step 8a):

> **Konzistence s doc 02:** Onboard wizard ma 10 kroku (Step 0–9). Doc 02 navrhuje Step 8a pro MCP token setup. Permission setup by logicky nasledoval jako Step 8b — po vygenerovani Automation Config (Step 8) a `.mcp.json` (Step 8a).

```
"Would you like to configure permanent tool permissions?
This prevents permission prompts when resuming sessions. [Y/n]"
```

Pokud ano, vygeneruje `.claude/settings.json` s allowlistem odpovidajicim zvolenym MCP serverum.

Vztah k doc 02: Toto je DOPLNEK k doc 02 (MCP token setup), ne alternativa. Doc 02 generuje `.mcp.json` (MCP server konfigurace), Step 8b generuje `.claude/settings.json` (tool auto-approval). Jsou to dva ruzne soubory s ruznym ucelem.

**Effort:** M
**Impact:** Preventivni — novy uzivatel nebude mit problem

### Moznost 3: Check-setup validuje permissions

Pridat do `check-setup.md` novy blok:

```markdown
### Block 6: Permission Settings

14. Check `.claude/settings.json` for permission configuration
    - If file exists + permissions.allow contains required tools -> [OK]
    - If file exists but missing some tools -> [WARN] "Missing permissions for: {list}.
      Session resume may prompt for each tool."
    - If file does not exist -> [INFO] "No permanent permissions configured.
      Consider adding .claude/settings.json for smoother session resume."
```

Podotknutí: Check-setup uz podporuje `--skip-build` flag. Pro konzistenci by mel existovat i `--skip-permissions` flag, pokud by tento blok byl pridan.

**Effort:** S-M
**Impact:** Diagnosticky

### Moznost 4: Report upstream

Pokud `claude -c` by mel zachovat permission state ale nezachovava, to je bug v Claude Code. Nahlasit na https://github.com/anthropics/claude-code/issues.

**Effort:** S (report)
**Impact:** Systemovy fix, ale zavisi na Anthropic

---

## Resume-ticket: konkretni dopady a navrhy

### Umisteni upozorneni v resume-ticket

`resume-ticket.md` zacina checkpoint detekci (step 1–6), ktera vyzaduje MCP pristup k issue trackeru (cteni stavu, komentaru). Pokud MCP permissions nejsou pre-approved, uzivatel bude promptovan PRED jakoukoli uzitecnou praci.

**Navrzene umisteni:** Nova sekce v `## Rules` na konci `resume-ticket.md`:

```markdown
- Detection requires MCP access to the issue tracker — if MCP permissions
  are not pre-approved in `.claude/settings.json`, the user will be prompted
  for each MCP tool call before checkpoint detection can proceed.
```

### Feature pipeline resume

`resume-ticket.md` (radek 57) pouziva marker `[CLAUDE-agents] Spec analysis completed.` k detekci FEATURE pipeline. Pokud MCP permissions selzou pri cteni komentaru z issue trackeru, ovlivni to:

1. **Checkpoint detekci** — resume-ticket nevi, zda je to BUG nebo FEATURE pipeline
2. **Fallback** — bez komentaru se pouzije default BUG pipeline, coz muze byt spatne pro feature tickety

Toto je dalsi argument pro pre-approved MCP permissions — zvlast pri resume flow.

### MCP pre-flight check pro resume-ticket

Resume-ticket je obzvlast citlivy na MCP dostupnost, protoze CELA jeho logika zavisi na cteni z issue trackeru (komentare, stav, branch). Na rozdil od fix-ticket, kde pipeline zacina od zacatku a selhani na MCP je okamzite viditelne, resume-ticket muze tichy selhat pri checkpoint detekci a pouzit spatny checkpoint.

**Navrh:** Pridat pre-flight check na zacatek resume-ticket (pred step 1):

```markdown
### 0. MCP availability check

Verify that MCP tools for the configured Issue Tracker type are accessible:
- Attempt a minimal MCP call (e.g., read issue state)
- If MCP unavailable -> display actionable error:
  "MCP tools for {type} are not accessible. Configure permanent permissions
  in .claude/settings.json or approve the tools when prompted.
  See docs/guides/troubleshooting.md#permission-prompts-after-session-resume"
- Continue only after MCP access is confirmed
```

### Worktree paralelni mod

`fix-bugs.md` podporuje paralelni zpracovani pres worktrees (Variant A). Pri session resume s worktrees je permission problem nasobeny:

- Kazdy paralelni Task (step 3 ve Variant A) muze vyzadovat samostatne schvaleni MCP tools
- Pri `batch_size = 3` to znamena az 3x vice permission promptu
- Worktree Tasks pouzivaji Task tool, ktery dedi permission state z parent session — ale pokud parent session nema pre-approved permissions, kazdy child Task muze promptovat samostatne

**Doporuceni:** Pro uzivatele s worktree konfiguraci je `.claude/settings.json` s pre-approved permissions de facto **nutnost**, ne volba. Toto by melo byt zdurazneno v dokumentaci (troubleshooting.md i worktree sekci).

---

## Doporuceni

**Kombinace: Moznost 1 (dokumentace) + Moznost 2 (onboard) + Moznost 4 (upstream report)**

1. **Ihned (S):** Pridat do troubleshooting.md sekci o permissions
2. **Minor release (M):** Onboard generuje `.claude/settings.json` jako Step 8b (po doc 02 Step 8a pro MCP setup)
3. **Paralelne:** Overit, zda je to ocekavane chovani Claude Code, pripadne reportovat

### Proc NE Moznost 3

Check-setup sice uz kontroluje platformovou konfiguraci (`.mcp.json`, tokeny, MCP konektivitu), takze permission checking by typove zapadal. Klicovy rozdil je vsak v dopadu na pipeline: absence `.mcp.json` nebo nefunkcni MCP konektivita pipeline **primo blokuje** — pipeline nemuze cist tickety ani vytvaret PR. Absence `.claude/settings.json` s pre-approved permissions pipeline **neblokuje** — pipeline pobezi, jen bude uzivatel opetovne promptovan k manualnimu schvaleni nastroju. Proto check-setup spravne validuje jen blocking zavislosti, a permission setup je UX vylepseni, ne prerequisite.

---

## Bezpecnostni uvahy

Auto-approval VSECH nastroju (`"allow": ["*"]`) je bezpecnostni riziko. Doporucit specificke allowlisty:

| Potreba | Doporuceny allowlist |
|---------|---------------------|
| Read-only analyza | `Read, Glob, Grep, mcp__*` |
| Plna pipeline | `Read, Write, Edit, Glob, Grep, Bash, mcp__*` |
| Minimalni | `Read, Glob, Grep` + per-tool approval |

**Pozor na MCP wildcard:** `mcp__*` povoli VSECHNY MCP servery vcetne serveru z jinych pluginu, nejen z CLAUDE-agents. Pro vyssi bezpecnost pouzijte specificke prefixy: `mcp__youtrack__*`, `mcp__gitea__*`, `mcp__github__*`.

CLAUDE-agents commands maji `allowed-tools` ve frontmatter, ale to je scope omezeni, ne auto-approval. Uzivatel by mel v `.claude/settings.json` povolit jen to, co odpovida `allowed-tools` nejnarocnejsiho commandu, ktery pouziva.

---

## Rozhodovaci otazky

1. **Je priorita tohoto fixu patch (jen docs) nebo minor (onboard rozsireni)?** A pokud minor — ma se onboard rozsireni (Step 8b) spojit do jednoho releasu s doc 02 (Step 8a pro MCP token setup)?

2. **Chces, aby onboard generoval `.claude/settings.json`?** Pokud ano, s jakym defaultnim allowlistem? Toto je DOPLNEK k doc 02 `.mcp.json` generovani (doc 02 Step 8a resi MCP server konfiguraci, doc 06 Step 8b resi tool auto-approval).

3. **Chces reportovat upstream?** Pokud `claude -c` by mel zachovat permissions — je to bug nebo design decision? Konkretni reprodukcni kroky: (1) spustit `claude`, (2) povolit nastroje, (3) ukoncit session, (4) spustit `claude -c`, (5) pozorovat, zda se znovu pta na povoleni.

4. **Jak resit MCP wildcard permissions?** `mcp__*` povoli VSECHNY MCP servery vcetne serveru z jinych pluginu. Ma onboard generovat specificke (`mcp__youtrack__*`, `mcp__gitea__*`) nebo wildcard?

5. **Ma `resume-ticket` detekovat nedostupne MCP nastroje a zobrazit actionable error PRED spustenim pipeline?** (Pre-flight check analogicky k checkpoint detekci, ale zamereny na MCP dostupnost — viz sekce "MCP pre-flight check pro resume-ticket" vyse.)

---

