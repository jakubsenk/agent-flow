# Phase 4 Spec — Revision 2 (Surgical Polish) Notes

Applied 2026-04-17 in response to:
- `review-6-devilsadvocate.md` (round 2) — 1 MAJOR + 5 MINOR, verdict PASS
- `review-5-quality.md` (round 2) — 2 MINOR nits, verdict PASS

No Gate 1 or Round 1 decisions reopened. This revision is SURGICAL: no new files, no new requirements or ACs beyond the ones listed below.

---

## Fixes applied

### Fix A — DA round2-1 MAJOR: drop `cross-host-hint` sidecar

**Files touched:** `design.md` (§4.8 snippet, §3.6 docs row, §3.7 test list header), `requirements.md` (AUTOPILOT-R13, §8.2, NOT_IN_SCOPE §6.19)

**What changed:**
- Removed creation, cleanup, and reading of `$LOCK_DIR.cross-host-hint` entirely from the lock-acquisition bash snippet.
- Removed the `check_cross_host_warn` function. Replaced with a single `log_single_host_info` function that unconditionally prints an INFO line on every successful lock acquisition.
- Rewrote AUTOPILOT-R13 from a conditional "WARN when prior owner is a different host within 24h" into an informational always-on INFO line emitted on every lock acquire:
  `[autopilot][INFO] Running on host {hostname}. If another host is also running Autopilot against the same tracker, it MUST use a disjoint bug/feature query. See docs/guides/autopilot.md#single-host-operation.`
- Updated `docs/guides/autopilot.md` §3.6 row: disjoint-query coordination is the authoritative multi-host mitigation; no file-based hint. Plugin provides NO automated cross-host detection.
- §8.2 rewritten: clearly labels disjoint-query as authoritative; explicitly notes the sidecar was removed in revision 2 because its detection fired post-damage and added its own persistent-file race.
- §6.19 updated language to match.

**Why:** DA-round2-1 was right — the sidecar was never garbage-collected, had its own read/write race, fired only after a cross-host collision had already caused duplicate PRs, and leaked owner identity across unrelated single-host runs. An always-on INFO line is strictly better than a post-hoc WARN with its own state file.

### Fix B — DA round2-3 MINOR: compact `run_id` format

**Files touched:** `design.md` (Canonical Definitions, §4.3/§4.4/§4.5 examples, §3.7 webhook test regex), `requirements.md` (§8.1), `formal-criteria.md` (AC-10).

**What changed:**
- `run_id` format is now `{issue_id}_{YYYYMMDDTHHMMSSZ}` — compact basic-format ISO-8601, no colons, no dashes in time. Example: `PROJ-42_20260417T143000Z`.
- All three webhook payload JSON examples updated.
- AC-10 regex updated to `^[A-Z]+-[0-9]+_[0-9]{8}T[0-9]{6}Z$`.
- §8.1 documents the format explicitly as URL-safe, filename-safe (NTFS-compatible), shell-word-safe.

**Why:** ISO8601 with colons breaks on NTFS filenames and needs URL-encoding for dashboards (Grafana/Splunk/Datadog). The compact basic-form is the standard solution.

### Fix C — DA round2-2 MINOR: BusyBox `awk mktime` fallback

**Files touched:** `design.md` (§4.8 header note + snippet else-branch, §3.7 test list — new `autopilot-lock-stale-awk-missing.sh`).

**What changed:**
- Added a note in §4.8 header stating the 121-minute conservative fallback used when `awk mktime` is unavailable.
- Modified the snippet's else-branch: when `iso_to_epoch` returns empty (mktime absent), fall back to `find ... -mmin +121` wall-clock mtime check against `owner.json`. If stale by that check, recover; otherwise exit 2 with the clearer `awk mktime unavailable; mtime age < 121min` message.
- Added test `tests/scenarios/autopilot-lock-stale-awk-missing.sh` to §3.7 validating this path.
- Updated Canonical note: `awk mktime` available in gawk + BusyBox ≥ 1.30 + macOS awk.

**Why:** BusyBox < 1.30 (Alpine 3.9 and earlier, old embedded images) lacks `mktime` and the previous snippet would silently exit 2 with a misleading "unparseable acquired_at" message. Fallback path is deterministic and the error message is now diagnostic.

### Fix D — DA round2-4 MINOR: COST-R12 discovery test asserts known field-name set

**Files touched:** `requirements.md` (COST-R12), `design.md` (§3.7 row for the discovery test), `formal-criteria.md` (AC-38).

**What changed:**
- COST-R12 now requires the discovery test to assert the token-count field matches the allowlist `{total_tokens, input_tokens+output_tokens, tokens_estimated}`. Empty / absent / unknown → exit 1 with `DISCOVERED_FIELD=<UNKNOWN|ABSENT>`. Recognized → exit 0 with `DISCOVERED_FIELD={name}`.
- Design §3.7 row rewritten: discovery test is no longer "exits 0 either way"; it fails explicitly on shape drift or dispatch failure.
- AC-38 now asserts the structured summary line is emitted and grep's for the known field-name set in the test script.

**Why:** Previous spec had the discovery test exit 0 on any outcome, which meant Phase 7 implementers had no mechanical signal of shape drift; production code would silently write 0 tokens everywhere if the real Task tool returned an unexpected key. Explicit allowlist + structured output fixes this.

### Fix E — Quality round2 MINOR: AC-1 anchored grep

**Files touched:** `formal-criteria.md` (AC-1).

**What changed:**
- AC-1 now uses three separate anchored `grep -cE '^name: autopilot$' ...` checks (one per required frontmatter key), each asserting exactly `1` match.
- Prevents false positives from mentions of `name: autopilot` or `disable-model-invocation` in comments or documentation within SKILL.md.

**Why:** Previous open-ended `grep -E '^(name|disable-model-invocation|argument-hint):'` matched any frontmatter line starting with those keys regardless of value — e.g., `argument-hint: ""` or a future comment mentioning the word `name:` would have slipped through.

### Fix F — Quality round2 MINOR: AC-36 apostrophe literal

**Files touched:** `formal-criteria.md` (AC-36).

**What changed:**
- AC-36 rewritten to match the new always-on INFO line (consistent with simplified AUTOPILOT-R13 after Fix A). It now runs the autopilot-lock-acquire scenario and greps for the literal string `[autopilot][INFO] Running on host` using `grep -cF` (fixed-string, no regex), avoiding any wildcard-vs-apostrophe ambiguity. Separate fixed-string greps check for `single-host-operation` anchor and `disjoint bug/feature query` guidance in both SKILL.md and docs/guides/autopilot.md.

**Why:** The previous `'Multi-host coordination is the operator.s responsibility'` used `.` as a wildcard to match the apostrophe; switching to the new INFO line + `grep -F` eliminates the concern and better aligns with the simplified R13 semantics.

### Revision-header updates

- `design.md`, `requirements.md`, and `formal-criteria.md` now all declare "Revision 2" in their headers with a summary of this round's changes. Round 1 revision notes preserved verbatim.

---

## Skipped / not applied

DA round2 findings NOT applied (by instruction — out of scope for this surgical polish):
- **round2-5** (mitigation is post-hoc; add foreign-host host-compare + louder ERROR on mkdir-fail): documented as ACCEPTED trade-off. The simplified R13 already produces a more operator-visible INFO line on every run; adding a second host-compare branch would reintroduce complexity without preventing first-occurrence damage. Still NOT_IN_SCOPE (§6.19) per Gate 1.
- **round2-6** (trap body nested-quote quoting): NOT APPLIED. Low-probability trigger (path containing apostrophes). Acceptable to defer to implementation-time hardening in Phase 7 without spec churn. No contract impact.

---

## Resulting counts

- EARS requirements: unchanged (34 total; AUTOPILOT-R1..R13, WEBHOOK-R1..R8, COST-R1..R12, +3 = 13+8+12 = 33 — error check, see below).

  Count reconciliation: AUTOPILOT has 13 (R1–R13), WEBHOOK has 8 (R1–R8), COST has 12 (R1–R12). Total = 33. Revision 2 did not add or drop any EARS IDs; it rewrote AUTOPILOT-R13 in place and rewrote COST-R12 in place.
- Acceptance criteria: 38 total (AC-1..AC-38). Revision 2 did not add or drop any AC IDs; it rewrote AC-1, AC-10, AC-36, AC-38 in place.
- Scenarios in design.md §3.7: +1 (new `autopilot-lock-stale-awk-missing.sh`). Total scenario files: 18 → 19.
