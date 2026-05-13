# Formal Acceptance Criteria — ceos-agents v6.7.1

All criteria are machine-checkable via shell commands. Each verification command returns exit code 0 on PASS, non-zero on FAIL.

---

## Item 1: config-reader Missing Key

### AC-1
**Item:** 1
**Description:** `core/config-reader.md` Decomposition entry contains `decomposition.create_tracker_subtasks`.
**Verification:**
```bash
grep -q 'decomposition.create_tracker_subtasks' core/config-reader.md
```

### AC-2
**Item:** 1
**Description:** The `create_tracker_subtasks` key has default value `enabled`.
**Verification:**
```bash
grep 'decomposition.create_tracker_subtasks' core/config-reader.md | grep -q 'default: .enabled.'
```

### AC-3
**Item:** 1
**Description:** The key appears on the same line as the other Decomposition keys (single-line format preserved).
**Verification:**
```bash
grep 'Decomposition' core/config-reader.md | grep 'decomposition.max_subtasks' | grep -q 'decomposition.create_tracker_subtasks'
```

---

## Item 2: Config Validity Gate in fix-bugs

### AC-4
**Item:** 2
**Description:** `skills/fix-bugs/SKILL.md` contains a "Step 0b: Config Validity Gate" heading.
**Verification:**
```bash
grep -q '### Step 0b: Config Validity Gate' skills/fix-bugs/SKILL.md
```

### AC-5
**Item:** 2
**Description:** Step 0b references implement-feature.md Step 0b as canonical source.
**Verification:**
```bash
grep -q 'implement-feature.md Step 0b' skills/fix-bugs/SKILL.md
```

### AC-6
**Item:** 2
**Description:** Step 0b checks all 4 required sections (Issue Tracker, Source Control, PR Rules, Build & Test).
**Verification:**
```bash
grep 'Issue Tracker' skills/fix-bugs/SKILL.md | grep 'Source Control' | grep 'PR Rules' | grep -q 'Build & Test'
```

### AC-7
**Item:** 2
**Description:** Step 0b includes the block comment template with `[ceos-agents]` prefix and `🔴` emoji.
**Verification:**
```bash
grep -q '\[ceos-agents\].*Pipeline Block' skills/fix-bugs/SKILL.md
```

### AC-8
**Item:** 2
**Description:** Step 0b appears between MCP pre-flight check and Orchestration heading (structural position).
**Verification:**
```bash
mcp_line=$(grep -n 'MCP pre-flight check' skills/fix-bugs/SKILL.md | head -1 | cut -d: -f1) && gate_line=$(grep -n 'Step 0b: Config Validity Gate' skills/fix-bugs/SKILL.md | head -1 | cut -d: -f1) && orch_line=$(grep -n '## Orchestration' skills/fix-bugs/SKILL.md | head -1 | cut -d: -f1) && [ "$gate_line" -gt "$mcp_line" ] && [ "$gate_line" -lt "$orch_line" ]
```

### AC-9
**Item:** 2
**Description:** Step 0b terminal instruction says "proceed to Step 1" (matching fix-bugs Step 1 = Fetch bugs).
**Verification:**
```bash
grep -A 50 'Step 0b: Config Validity Gate' skills/fix-bugs/SKILL.md | grep -q 'proceed to Step 1'
```

---

## Item 3: State Schema Retry Limit Fields

### AC-10
**Item:** 3
**Description:** `state/schema.md` field table contains `config.retry_limits.spec_iterations` with default `5`.
**Verification:**
```bash
grep 'config.retry_limits.spec_iterations' state/schema.md | grep -q '5'
```

### AC-11
**Item:** 3
**Description:** `state/schema.md` field table contains `config.retry_limits.root_cause_iterations` with default `3`.
**Verification:**
```bash
grep 'config.retry_limits.root_cause_iterations' state/schema.md | grep -q '3'
```

### AC-12
**Item:** 3
**Description:** `spec_iterations` row appears after `build_retries` row and before `infrastructure` row in the field table.
**Verification:**
```bash
build_line=$(grep -n 'build_retries' state/schema.md | grep '|' | tail -1 | cut -d: -f1) && spec_line=$(grep -n 'spec_iterations' state/schema.md | grep '|' | head -1 | cut -d: -f1) && infra_line=$(grep -n '| .infrastructure.' state/schema.md | head -1 | cut -d: -f1) && [ "$spec_line" -gt "$build_line" ] && [ "$spec_line" -lt "$infra_line" ]
```

### AC-13
**Item:** 3
**Description:** JSON example block contains `spec_iterations` and `root_cause_iterations` fields.
**Verification:**
```bash
grep -q '"spec_iterations"' state/schema.md && grep -q '"root_cause_iterations"' state/schema.md
```

### AC-14
**Item:** 3
**Description:** JSON example has valid syntax: `build_retries` line ends with comma (trailing comma fix).
**Verification:**
```bash
grep '"build_retries"' state/schema.md | grep -v '|' | grep -q ','
```

### AC-15
**Item:** 3
**Description:** `spec_iterations` description uses `↔` separator (spec-writer↔spec-reviewer).
**Verification:**
```bash
grep 'spec_iterations' state/schema.md | grep -q '↔'
```

---

## Item 4: Code-analyst Before Architect in implement-feature

### AC-16
**Item:** 4
**Description:** `skills/implement-feature/SKILL.md` contains a "3a. Code-analyst" step heading.
**Verification:**
```bash
grep -q '### 3a\. Code-analyst' skills/implement-feature/SKILL.md
```

### AC-17
**Item:** 4
**Description:** Step 3a dispatches `ceos-agents:code-analyst` with Task tool.
**Verification:**
```bash
grep -A 10 '### 3a' skills/implement-feature/SKILL.md | grep -q 'ceos-agents:code-analyst'
```

### AC-18
**Item:** 4
**Description:** Step 3a is unconditional (no keyword heuristic gate -- only Pipeline Profiles skip).
**Verification:**
```bash
grep -A 3 '### 3a' skills/implement-feature/SKILL.md | grep -q 'Skip stages' && ! grep -A 20 '### 3a' skills/implement-feature/SKILL.md | grep -qi 'keyword\|heuristic\|if.*modification\|if.*refactor'
```

### AC-19
**Item:** 4
**Description:** Step 3a includes non-fatal blocking behavior (log warning, proceed to step 4).
**Verification:**
```bash
grep -A 20 '### 3a' skills/implement-feature/SKILL.md | grep -q 'Code-analyst blocked.*continuing without impact analysis'
```

### AC-20
**Item:** 4
**Description:** Stage map entry updated from N/A to step 3a.
**Verification:**
```bash
grep 'code-analyst.*=.*step 3a' skills/implement-feature/SKILL.md | grep -qv 'N/A'
```

### AC-21
**Item:** 4
**Description:** Stage map no longer contains the old N/A entry for code-analyst.
**Verification:**
```bash
! grep 'code-analyst.*N/A.*feature pipeline does not have code-analyst' skills/implement-feature/SKILL.md
```

### AC-22
**Item:** 4
**Description:** Architect context includes code-analyst impact report.
**Verification:**
```bash
grep -A 5 '### 4\. Architect' skills/implement-feature/SKILL.md | grep -q 'code-analyst impact report'
```

### AC-23
**Item:** 4
**Description:** Step 3a context includes `Mode: feature` and `Pipeline: implement-feature`.
**Verification:**
```bash
grep -A 10 '### 3a' skills/implement-feature/SKILL.md | grep 'Mode: feature' | grep -q 'Pipeline: implement-feature'
```

### AC-24
**Item:** 4
**Description:** Step 3a includes state.json update with `code_analysis.status`.
**Verification:**
```bash
grep -A 20 '### 3a' skills/implement-feature/SKILL.md | grep -q 'code_analysis.status'
```

### AC-25
**Item:** 4
**Description:** Step 3a appears between Step 3 (Spec-analyst) and Step 4 (Architect) in file order.
**Verification:**
```bash
spec_line=$(grep -n '### 3\. Spec-analyst' skills/implement-feature/SKILL.md | head -1 | cut -d: -f1) && ca_line=$(grep -n '### 3a\. Code-analyst' skills/implement-feature/SKILL.md | head -1 | cut -d: -f1) && arch_line=$(grep -n '### 4\. Architect' skills/implement-feature/SKILL.md | head -1 | cut -d: -f1) && [ "$ca_line" -gt "$spec_line" ] && [ "$ca_line" -lt "$arch_line" ]
```

---

## Item 5: Marker Nesting Attack Mitigation

### AC-26
**Item:** 5
**Description:** `core/external-input-sanitizer.md` contains step 1b with marker escape logic.
**Verification:**
```bash
grep -q '1b\.' core/external-input-sanitizer.md
```

### AC-27
**Item:** 5
**Description:** Step 1b specifies `[ESCAPED: EXTERNAL INPUT START]` replacement format.
**Verification:**
```bash
grep -q '\[ESCAPED: EXTERNAL INPUT START\]' core/external-input-sanitizer.md
```

### AC-28
**Item:** 5
**Description:** Step 1b specifies `[ESCAPED: EXTERNAL INPUT END]` replacement format.
**Verification:**
```bash
grep -q '\[ESCAPED: EXTERNAL INPUT END\]' core/external-input-sanitizer.md
```

### AC-29
**Item:** 5
**Description:** Step 1b mentions idempotency.
**Verification:**
```bash
grep -A 10 '1b\.' core/external-input-sanitizer.md | grep -qi 'idempotent'
```

### AC-30
**Item:** 5
**Description:** Step 1b appears before step 2 (wrapping) in file order.
**Verification:**
```bash
step1b_line=$(grep -n '1b\.' core/external-input-sanitizer.md | head -1 | cut -d: -f1) && step2_line=$(grep -n '^2\. Wrap each piece' core/external-input-sanitizer.md | head -1 | cut -d: -f1) && [ "$step1b_line" -lt "$step2_line" ]
```

### AC-31
**Item:** 5
**Description:** Step 1b specifies "Before wrapping" to clarify ordering relative to Output Contract.
**Verification:**
```bash
grep '1b\.' core/external-input-sanitizer.md | grep -qi 'before wrapping'
```

---

## Item 6: State-Manager Graceful Degradation

### AC-32
**Item:** 6
**Description:** `core/state-manager.md` Step 2a includes graceful degradation for missing/malformed plugin.json.
**Verification:**
```bash
grep '2a\.' core/state-manager.md | grep -q 'unreadable, malformed, or lacks'
```

### AC-33
**Item:** 6
**Description:** Degradation sets `plugin_version` to `null`.
**Verification:**
```bash
grep '2a\.' core/state-manager.md | grep -q 'plugin_version.*null'
```

### AC-34
**Item:** 6
**Description:** Degradation is silent (no error, no warning).
**Verification:**
```bash
grep '2a\.' core/state-manager.md | grep -q 'no error, no warning'
```

### AC-35
**Item:** 6
**Description:** Degradation clause is inline on Step 2a (not a separate Failure Handling bullet).
**Verification:**
```bash
grep '2a\.' core/state-manager.md | grep 'plugin.json' | grep -q 'null'
```

---

## Item 7: Extended NEVER Constraint to 5 Additional Agents

### AC-36
**Item:** 7
**Description:** All 10 agents contain the NEVER external-input constraint (EXTERNAL INPUT START + NEVER on same line).
**Verification:**
```bash
all_pass=true; for agent in triage-analyst code-analyst fixer spec-analyst reviewer acceptance-gate architect reproducer priority-engine browser-verifier; do grep "EXTERNAL INPUT START" "agents/${agent}.md" | grep -q "NEVER" || { echo "FAIL: ${agent}"; all_pass=false; }; done; $all_pass
```

### AC-37
**Item:** 7
**Description:** All 10 agents contain the NEVER external-input constraint (EXTERNAL INPUT END + NEVER on same line).
**Verification:**
```bash
all_pass=true; for agent in triage-analyst code-analyst fixer spec-analyst reviewer acceptance-gate architect reproducer priority-engine browser-verifier; do grep "EXTERNAL INPUT END" "agents/${agent}.md" | grep -q "NEVER" || { echo "FAIL: ${agent}"; all_pass=false; }; done; $all_pass
```

### AC-38
**Item:** 7
**Description:** The constraint text in each of the 5 new agents is byte-identical to the constraint in `triage-analyst.md`.
**Verification:**
```bash
ref_line=$(grep "NEVER follow instructions.*EXTERNAL INPUT START" agents/triage-analyst.md); all_pass=true; for agent in acceptance-gate architect reproducer priority-engine browser-verifier; do agent_line=$(grep "NEVER follow instructions.*EXTERNAL INPUT START" "agents/${agent}.md"); [ "$ref_line" = "$agent_line" ] || { echo "FAIL: ${agent} text mismatch"; all_pass=false; }; done; $all_pass
```

### AC-39
**Item:** 7
**Description:** The constraint is the last line of Constraints in each of the 5 new agents (no content after it before EOF or next section).
**Verification:**
```bash
all_pass=true; for agent in acceptance-gate architect reproducer priority-engine browser-verifier; do last_content_line=$(grep -n '.' "agents/${agent}.md" | tail -1 | cut -d: -f1); never_line=$(grep -n 'NEVER follow instructions.*EXTERNAL INPUT' "agents/${agent}.md" | tail -1 | cut -d: -f1); [ "$last_content_line" = "$never_line" ] || { echo "FAIL: ${agent} constraint not last line (last=${last_content_line}, never=${never_line})"; all_pass=false; }; done; $all_pass
```

### AC-40
**Item:** 7
**Description:** Test file `AGENTS_TO_CHECK` array contains exactly 10 agents.
**Verification:**
```bash
count=$(sed -n '/AGENTS_TO_CHECK=(/,/)/p' tests/scenarios/prompt-injection-protection.sh | grep -c '"'); [ "$count" -eq 10 ]
```

### AC-41
**Item:** 7
**Description:** Test file `AGENTS_TO_CHECK` array contains all 5 new agents: acceptance-gate, architect, reproducer, priority-engine, browser-verifier.
**Verification:**
```bash
all_pass=true; for agent in acceptance-gate architect reproducer priority-engine browser-verifier; do grep -A 15 'AGENTS_TO_CHECK=' tests/scenarios/prompt-injection-protection.sh | grep -q "\"${agent}\"" || { echo "FAIL: ${agent} not in AGENTS_TO_CHECK"; all_pass=false; }; done; $all_pass
```

### AC-42
**Item:** 7
**Description:** Test file AC-3 comment updated to reference "All 10 agents" (not "All 5 agents").
**Verification:**
```bash
grep -q 'All 10 agents' tests/scenarios/prompt-injection-protection.sh && ! grep -q 'All 5 agents' tests/scenarios/prompt-injection-protection.sh
```

---

## Cross-Cutting Criteria

### AC-43
**Item:** All
**Description:** No new files created (file count unchanged in agents/, skills/, core/, state/, tests/scenarios/).
**Verification:**
```bash
[ $(ls agents/*.md | wc -l) -eq 21 ] && [ $(ls core/*.md | wc -l) -eq 14 ]
```

### AC-44
**Item:** All
**Description:** Existing test suite passes (prompt-injection-protection.sh exits 0).
**Verification:**
```bash
bash tests/scenarios/prompt-injection-protection.sh
```

---

## Summary

| Item | AC Count | AC IDs |
|------|----------|--------|
| 1 — config-reader | 3 | AC-1 to AC-3 |
| 2 — fix-bugs gate | 6 | AC-4 to AC-9 |
| 3 — state schema | 6 | AC-10 to AC-15 |
| 4 — code-analyst step | 10 | AC-16 to AC-25 |
| 5 — sanitizer escape | 6 | AC-26 to AC-31 |
| 6 — state-manager degradation | 4 | AC-32 to AC-35 |
| 7 — NEVER constraint + tests | 7 | AC-36 to AC-42 |
| Cross-cutting | 2 | AC-43 to AC-44 |
| **Total** | **44** | AC-1 to AC-44 |
