# Security Review — Phase 8 Verification, Cycle 0

**Reviewer role:** Security  
**Files reviewed:**
- `skills/init/SKILL.md`
- `docs/guides/mcp-configuration.md`
- `docs/guides/installation.md`

---

## Score: 0.92

---

## Findings

### 1. curl flags — PASS

`skills/init/SKILL.md` Step 5 uses:
```bash
curl -sfL -o ~/.claude/bin/{binary_name} "https://..."
```
- `-s` (silent), `-f` (--fail: exits non-zero on HTTP 4xx/5xx), `-L` (follow redirects) are all correct.
- The tag-fetch command uses `-sL` only (no `-f`), which is acceptable — it feeds into a grep/cut pipeline and a parse failure would result in an empty tag, which the subsequent download URL construction would make obviously wrong rather than silently dangerous.
- No injection risk: the URL is constructed from the hardcoded Codeberg base URL plus the tag extracted via `grep -o '"tag_name":"[^"]*"' | head -1 | cut -d'"' -f4`. The tag value is used only in a quoted shell string. No user-controlled input flows into the URL.

### 2. `go install` module path — PASS

```bash
GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest
```
- Module path `codeberg.org/goern/forgejo-mcp/v2` matches the Codeberg source repository already referenced throughout the skill and in `docs/guides/mcp-configuration.md`.
- `@latest` resolves via Go module proxy (sum.golang.org checksum verification is on by default), providing supply chain integrity.
- No user-controlled input flows into the module path — it is hardcoded.
- Minor note: `@latest` will always pull the newest release, which is standard practice for CLI tools in install flows. Acceptable risk.

### 3. `rm -f` on invalid file — PASS

```bash
rm -f ~/.claude/bin/{binary_name}
```
- `{binary_name}` is determined earlier in Step 5 from `uname -s`/`uname -m` output through a fixed lookup table (`forgejo-mcp.exe`, `forgejo-mcp-linux-amd64`, etc.). It is not derived from user input.
- No path traversal risk: the path is `~/.claude/bin/` + a fixed string from a closed set.
- `-f` (force, no error if absent) is appropriate here — the file may or may not exist at cleanup time.

### 4. URLs in docs — PASS

All URLs checked:
- `https://codeberg.org/goern/forgejo-mcp/releases` — legitimate upstream Codeberg project
- `https://codeberg.org/api/v1/repos/goern/forgejo-mcp/releases/latest` — Codeberg REST API, correct format
- `https://go.dev/dl/` — official Go download page
- `https://nodejs.org/` — official Node.js download page
- `https://github.com/yonaka15/mcp-server-redmine` — referenced package source in mcp-configuration.md
- All npm packages (`@vitalyostanin/youtrack-mcp`, `@modelcontextprotocol/server-github`, etc.) are the same packages already in use throughout the plugin

No URL changes that could redirect to a malicious source were detected.

### 5. Credential exposure — PASS

- `skills/init/SKILL.md` Rule section: "NEVER write tokens into CLAUDE.md — only into .mcp.json" and "NEVER commit .mcp.json to git — always add to .gitignore" — explicit and correct.
- `.mcp.json.example` creation strips all tokens to `<YOUR_*>` placeholders — safe for git tracking.
- Step 4 (token collection) offers skip option with placeholder — no forced exposure.
- `docs/guides/installation.md` HTTPS example: `git ls-remote https://<TOKEN>@gitea...` uses a placeholder, not an actual token.
- No real credentials appear in any of the three files.

### 6. Minor observation (non-blocking)

The `go install ... @latest` fallback in Step 5.8b does not pin to a specific version. While Go module checksums provide integrity guarantees, a pinned version (e.g., `@v2.x.y`) would be more reproducible. This is a common trade-off in install scripts and does not constitute a security defect — rated informational only.

---

## Verdict: PASS

All security-relevant changes are sound. curl uses `--fail`, no injection vectors exist, the `rm -f` path is not user-controlled, all URLs point to legitimate sources, and credential hygiene is explicitly enforced.
