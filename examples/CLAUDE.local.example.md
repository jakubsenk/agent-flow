# CLAUDE.local.md — per-developer overrides (example)

Copy this file to **`CLAUDE.local.md`** next to your project's `CLAUDE.md` and edit the values you want
to change. `CLAUDE.local.md` is **gitignored** — your changes stay on your machine and are never
committed. It is merged **over** `CLAUDE.md` (local wins) before any pipeline runs, per
`core/config-reader.md` Step 0.

**Rules**
- **Sparse:** include only the `### Section` / `| Key | Value |` rows you want to change. Everything you
  omit inherits the committed `CLAUDE.md` default.
- A key with an **empty value** clears the committed value; to inherit, just omit the key.
- Multi-value keys (`On events`, `Labels`, `Ports`, `State transitions`) are replaced as a whole unit.
- Add to `.gitignore`:
  ```gitignore
  CLAUDE.local.md
  !CLAUDE.local.example.md
  ```

---

## Automation Config

### Browser Verification

| Key | Value |
|-----|-------|
| Enabled | false |

<!--
`Enabled: false` skips browser reproduce/verify on your machine without removing the shared
`### Browser Verification` section from CLAUDE.md. Or override just the URL instead:

| Base URL | http://localhost:5173 |
-->

### Issue Tracker

| Key | Value |
|-----|-------|
| Bug query | `assignee: me state: Open` |

<!--
Override only the keys you need — the rest of Issue Tracker (Type, Instance, Project, …) inherits
from CLAUDE.md. Anything not listed here is unchanged.
-->
