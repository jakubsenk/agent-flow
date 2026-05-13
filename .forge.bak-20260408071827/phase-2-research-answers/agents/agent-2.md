# Research: forgejo-mcp as npm/npx Alternative

## Question
Does `forgejo-mcp` exist on npm, and can `npx forgejo-mcp` work as a drop-in replacement for the upstream binary on Windows?

---

## Findings

### 1. Package Exists on npm

**Package:** `forgejo-mcp`
**URL:** https://www.npmjs.com/package/forgejo-mcp
**Latest version:** 1.2.0 (published April 9, 2025; alpha 1.2.1-alpha.1 on April 15, 2025)
**Maintainer:** Christoph Görn (christoph@goern.name) — mirrors the Codeberg-canonical `goern/forgejo-mcp`
**License:** GPL-3.0-or-later

### 2. It Is a TypeScript/Node.js Package

The npm package is a **TypeScript rewrite** of the Go-based upstream. It is distinct from the primary `goern/forgejo-mcp` Codeberg project (which is Go, 93% of code). The npm package's `main` is `build/index.js` and it depends on `@modelcontextprotocol/sdk ^1.8.0`, `axios`, `yargs`, and `dotenv`.

### 3. Critical Issue: No `bin` Field

The `package.json` has **no `bin` field**. This means:

- `npx forgejo-mcp` will download the package but **will not execute anything** — there is no registered executable entry point.
- The package exposes only `npm start` (runs `node build/index.js`) and `npm run start:http` as runtime commands.
- `npx forgejo-mcp` is **not a usable drop-in** in an MCP config's `command`/`args` block.

### 4. Workaround: node + npx with explicit path

Because there is no bin entry, any npx-based invocation would require a workaround such as:

```json
{
  "command": "node",
  "args": ["./node_modules/forgejo-mcp/build/index.js"]
}
```

This requires a local install first and is **not consistent** with the pattern used by other MCP servers (GitHub, YouTrack, Jira, Linear), which use `npx -y <package>` directly.

### 5. Alternative: `@ric_/forgejo-mcp`

A separate scoped npm package `@ric_/forgejo-mcp` is referenced in community MCP configs with:

```json
{
  "command": "npx",
  "args": ["@ric_/forgejo-mcp"],
  "env": {
    "FORGEJO_URL": "https://your-instance.com",
    "FORGEJO_TOKEN": "your-token"
  }
}
```

This package's npm registry status was not confirmed during research (no direct registry fetch succeeded), but community documentation (LobeHub, mcpservers.org) treats it as the preferred npx-invocable variant.

### 6. Official Gitea MCP

Gitea maintains `gitea/gitea-mcp` (at gitea.com/gitea/gitea-mcp). This is a Go binary, not on npm — same Windows availability problem as the upstream forgejo-mcp binary.

---

## Summary Table

| Option | On npm | Has bin | npx works | Windows-safe | Notes |
|---|---|---|---|---|---|
| `forgejo-mcp` (goern) | Yes | No | No | Partial | No bin entry; node-based but not npx-invocable |
| `@ric_/forgejo-mcp` | Unconfirmed | Likely yes | Likely yes | Likely yes | Community docs show npx usage pattern |
| `goern/forgejo-mcp` (binary) | No | — | No | No | Go binary; no Windows pre-built |
| `raohwork/forgejo-mcp` | No | — | No | No | Go binary + Docker only |
| `gitea/gitea-mcp` | No | — | No | No | Go binary |

---

## Recommendation

`npx forgejo-mcp` (the goern npm package) **does not work** as a drop-in replacement — no bin entry.

The `@ric_/forgejo-mcp` scoped package is the most promising npm-based alternative with reported npx support, but its registry status and maintenance need verification before recommending it for ceos-agents documentation.

If confirmed functional, the MCP config would be:

```json
{
  "mcpServers": {
    "forgejo": {
      "command": "npx",
      "args": ["-y", "@ric_/forgejo-mcp"],
      "env": {
        "FORGEJO_URL": "https://your-instance.com",
        "FORGEJO_TOKEN": "your-token"
      }
    }
  }
}
```

This would be consistent with the other MCP server integrations in ceos-agents.

---

## Sources

- [forgejo-mcp on npm](https://www.npmjs.com/package/forgejo-mcp)
- [goern/forgejo-mcp on Codeberg](https://codeberg.org/goern/forgejo-mcp)
- [goern/forgejo-mcp GitHub mirror](https://github.com/goern/forgejo-mcp)
- [raohwork/forgejo-mcp GitHub](https://github.com/raohwork/forgejo-mcp)
- [forgejo-mcp on LobeHub (shows @ric_ config)](https://lobehub.com/mcp/squarecows-forgejo-mcp)
- [forgejo-mcp on mcpservers.org](https://mcpservers.org/servers/goern/forgejo-mcp)
