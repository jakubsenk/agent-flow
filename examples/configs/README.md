# Config Templates

Pre-built Automation Config templates for common tech stacks and issue tracker combinations.

## Heading-Extraction Contract

Every config file in `examples/configs/*.md` MUST start with `# Stack Name` as the first line (single H1 heading). This is required by the `/ceos-agents:onboard` Step 1 inline glob+extract logic, which reads the H1 heading to build the Available Templates table.

## Naming Convention

File names follow the pattern: `{tracker-prefix}-{stack-name}.md`

Tracker prefixes:
- `gitea-` — Gitea issue tracker
- `github-` — GitHub Issues
- `jira-` — Jira
- `redmine-` — Redmine
- `youtrack-` — YouTrack

## Available Templates

| File | Tracker | Stack |
|------|---------|-------|
| `github-nextjs.md` | GitHub | Next.js on GitHub Actions |
| `github-python-fastapi.md` | GitHub | Python FastAPI on GitHub Actions |
| `github-dotnet.md` | GitHub | .NET on GitHub Actions |
| `gitea-spring-boot.md` | Gitea | Spring Boot on Gitea Actions |
| `jira-react.md` | Jira | React with Jira tracker |
| `youtrack-python.md` | YouTrack | Python with YouTrack |
| `redmine-rails.md` | Redmine | Ruby on Rails with Redmine |
| `redmine-oracle-plsql.md` | Redmine | Oracle PL/SQL with Redmine |

## Usage

To use a template, run `/ceos-agents:onboard` — Step 1 lists available templates automatically via glob+extract. Select a template name to load it as pre-filled defaults, then adjust values in the wizard steps.
