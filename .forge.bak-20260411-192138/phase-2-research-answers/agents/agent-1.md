# Phase 2 Research Answers — Agent 1: TLS Diagnostic in check-setup Block 3 Step 9

## 1. Current state of Block 3 step 9 (lines 71–77)

```markdown
9. Run the Bug query from Automation Config via MCP (limit 1 result):
   - Success → [OK] with the number of bugs found
   - Auth error → [FAIL] "MCP server configured but authentication failed — check your token in .mcp.json"
   - Timeout/connection refused → [FAIL] "MCP server configured but not reachable — verify the server is running and URL is correct"
10. Verify source control connectivity: list repositories via MCP
    - Success → [OK]
    - Failure → [FAIL] with specific error type (auth vs unreachable)
```

Only two failure buckets exist. TLS certificate errors (e.g. self-signed cert, corporate CA, private PKI) fall into the "Timeout/connection refused" bucket and produce the misleading recommendation "verify the server is running and URL is correct" — which is wrong when the server IS reachable via curl but Node.js rejects the TLS handshake.

---

## 2. Trigger condition — how to distinguish TLS from auth from timeout

### Pattern matching on MCP error text

| Error class | Error text patterns (case-insensitive) |
|-------------|----------------------------------------|
| Auth error  | `401`, `403`, `unauthorized`, `forbidden`, `invalid token`, `authentication` |
| TLS error   | `UNABLE_TO_VERIFY_LEAF_SIGNATURE`, `CERT_UNTRUSTED`, `SELF_SIGNED_CERT`, `self signed certificate`, `certificate verify failed`, `ERR_TLS_`, `SSL_ERROR`, `DEPTH_ZERO_SELF_SIGNED_CERT`, `unable to get local issuer certificate` |
| Timeout / unreachable | `ECONNREFUSED`, `ETIMEDOUT`, `ENOTFOUND`, `ECONNRESET`, `timeout`, `connection refused`, `network error` (and no TLS pattern matched) |

**Decision order:** check TLS patterns first, then auth patterns, then fall back to unreachable. TLS errors typically surface as Node.js `Error` objects with `code` matching one of the `ERR_TLS_*` / `CERT_*` constants or with message text containing "certificate".

---

## 3. Diagnostic curl probe

When the MCP call fails and the error matches a TLS pattern, run this curl probe to confirm the server is network-reachable:

```bash
curl -s -o /dev/null -w "%{http_code}" --max-time 5 {instance_url}
```

- `{instance_url}` = the `Instance` value from Automation Config (e.g. `https://redmine.internal.corp`).
- curl uses the OS/system CA store by default, so it succeeds even when Node.js (bundled Mozilla CA) rejects the certificate.
- The probe returns an HTTP status code. Any numeric response (including `000` for connection refused) distinguishes "server responded at the network layer" from "server not reachable at all".

**Interpretation:**

| curl exit code | HTTP code returned | Meaning |
|----------------|--------------------|---------|
| 0 | 2xx / 3xx / 4xx / 5xx | Server is reachable — TLS diagnosis confirmed |
| 0 | `000` | curl connected but got no HTTP response — treat as unreachable |
| Non-zero (7, 28, 35…) | n/a | Server truly unreachable (refused/timeout/DNS) |

Use `$?` (curl exit code) as the primary signal. Any exit code == 0 with a non-`000` HTTP code means the server answers HTTP — so Node.js failure is TLS-related, not network-related.

---

## 4. Three output strings

### Bucket A — server unreachable (existing, unchanged wording refined)
```
[FAIL] Issue tracker — server not reachable — verify the server is running and URL is correct
```

### Bucket B — NEW: server reachable, MCP failed (TLS)
```
[FAIL] Issue tracker — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json
```

### Bucket C — auth error (existing, unchanged wording refined)
```
[FAIL] Issue tracker — authentication failed — check your token in .mcp.json
```

---

## 5. Exact new logic for step 9

Replace the current step 9 block (lines 71–74) with the following text. The replacement is a drop-in — same bullet structure, same indentation, extended with sub-steps.

**Old text (lines 71–74):**
```markdown
9. Run the Bug query from Automation Config via MCP (limit 1 result):
   - Success → [OK] with the number of bugs found
   - Auth error → [FAIL] "MCP server configured but authentication failed — check your token in .mcp.json"
   - Timeout/connection refused → [FAIL] "MCP server configured but not reachable — verify the server is running and URL is correct"
```

**New text (replace lines 71–74 entirely):**
```markdown
9. Run the Bug query from Automation Config via MCP (limit 1 result):
   - Success → [OK] with the number of bugs found
   - Auth error (error contains: 401, 403, unauthorized, forbidden, invalid token) →
     [FAIL] "Issue tracker — authentication failed — check your token in .mcp.json"
   - TLS error (error contains: UNABLE_TO_VERIFY_LEAF_SIGNATURE, CERT_UNTRUSTED, SELF_SIGNED_CERT,
     self signed certificate, certificate verify failed, ERR_TLS_, DEPTH_ZERO_SELF_SIGNED_CERT,
     unable to get local issuer certificate) → run curl probe:
     `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {Instance}`
     - curl exit 0 and HTTP code != 000 →
       [FAIL] "Issue tracker — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json"
     - curl exit non-zero or HTTP code 000 →
       [FAIL] "Issue tracker — server not reachable — verify the server is running and URL is correct"
   - Any other error (ECONNREFUSED, ETIMEDOUT, ENOTFOUND, timeout, connection refused) →
     [FAIL] "Issue tracker — server not reachable — verify the server is running and URL is correct"
```

**Insertion point:** Lines 71–74 in `skills/check-setup/SKILL.md`. The replacement adds 10 lines in place of 4. Everything from line 75 onward shifts down but is otherwise unchanged.

---

## 6. Impact on the Output Format section

### Current output format (lines 88–112)

The Connectivity block example shows:
```
[OK]   Issue tracker — connection OK, project {PROJECT} found, X bugs
[FAIL] Source control — authentication failed (401 Unauthorized)
```

### Required updates

The Output Format section needs one new example line added to the Connectivity block to document the new TLS failure mode. The existing auth and unreachable lines remain valid.

**Add after the existing `[FAIL] Source control — authentication failed` example line:**
```
[FAIL] Issue tracker — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json
```

The full updated Connectivity block in the Output Format section becomes:
```
### Connectivity
[OK]   Issue tracker — connection OK, project {PROJECT} found, X bugs
[FAIL] Issue tracker — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json
[FAIL] Source control — authentication failed (401 Unauthorized)
```

No other changes to the Output Format section are needed. The Result line, Verdict block, and all other blocks are unaffected.

---

## 7. Summary of all file changes

| File | Change type | Lines affected |
|------|-------------|----------------|
| `skills/check-setup/SKILL.md` | Replace step 9 (4 lines → 14 lines) | 71–74 |
| `skills/check-setup/SKILL.md` | Add one example line to Output Format Connectivity block | ~104 (shifts after step 9 expansion) |

Both changes are in the same file. Total net addition: ~11 lines.

---

## 8. NODE_OPTIONS guidance (informational — not part of SKILL.md prose)

The fix recommended in the new [FAIL] string is:

Add to `.mcp.json` under the failing server's `env` block:
```json
"env": {
  "NODE_OPTIONS": "--use-system-ca"
}
```

`--use-system-ca` is a Node.js 20+ flag that instructs Node.js to trust the OS certificate store in addition to its bundled Mozilla CA bundle. It is the correct, secure solution for environments with private PKI, self-signed certificates, or corporate CAs. No other changes to the server or network are required.
