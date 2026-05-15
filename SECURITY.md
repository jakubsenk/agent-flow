# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in agent-flow, please **do not** open a public issue.

**Primary contact:** Report privately by email to **filip.sabacky@ceosdata.com**

Include: a description of the vulnerability, steps to reproduce, and potential impact.

**Alternative:** Use [GitHub Security Advisories](https://github.com/asysta-act/agent-flow/security/advisories/new) to report confidentially through GitHub's native vulnerability reporting.

**Response SLA:** We aim to acknowledge reports within 5 business days and provide a fix, public mitigation guidance, or a coordinated-disclosure timeline extension by mutual agreement.

## Known Limitations

### Webhook URL — operator trust required

The `Webhook URL` value in `### Notifications` (Automation Config) is dispatched via `curl`
without scheme or host validation beyond `--proto "=http,https"`. A malicious PR that injects
a slow-responding `Webhook URL` could trigger the circuit-breaker (3 consecutive failures,
then suppression for the run).

**Operator guidance:**
- Treat `Webhook URL` changes in PRs as security-relevant and review them carefully.
- Prefer setting `Webhook URL` only in trusted, controlled environments.
- Cross-run circuit persistence and URL allowlist enforcement are planned for a future release.

For the full technical description, see `CLAUDE.md` under "Webhook Payloads".

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | ✅ Yes    |

agent-flow 1.0.0 is the initial supported release. Only the latest release receives security fixes.
