# Design Documents Index

This directory contains all architecture decision records (ADRs) and design documents
for the ceos-agents plugin. Documents are listed in chronological order.

## Legend

| Status | Meaning |
|--------|---------|
| IMPLEMENTED | Design was approved and fully implemented in the listed version |
| SUPERSEDED | Design was replaced by a newer, consolidated document |
| APPROVED | Design was approved but implementation is tracked by a newer consolidated doc |
| PROPOSED | Design is under review; not yet implemented |
| ARCHIVE | Supporting document (review, sync doc, upgrade guide) — not a design |

---

## Roadmap

See [roadmap.md](roadmap.md) for current priorities and future direction.

## Documents

### Foundation (v1.0 era)

| Date | File | Title | Status | Version |
|------|------|-------|--------|---------|
| 2026-02-16 | `2026-02-16-commands-to-plugin-design.md` | Commands to Plugin Migration | APPROVED | v1.0 |
| 2026-02-19 | `2026-02-19-skills-vs-commands.md` | Skills vs Commands | APPROVED | v1.0 |
| 2026-02-19 | `2026-02-19-plugin-update-process.md` | Plugin Update Process | APPROVED | v1.0 |
| 2026-02-19 | `2026-02-19-agent-docs-audit.md` | Agent Docs Audit | APPROVED | v1.0 |
| 2026-02-24 | `2026-02-24-genericize-and-routing-skill.md` | Genericize Plugin + Routing Skill | APPROVED | v1.0 |

### v1.x–v2.x Designs (consolidated into v2.0.0 release)

| Date | File | Title | Status | Version |
|------|------|-------|--------|---------|
| 2026-02-25 | `2026-02-25-v1.2-installation-docs-design.md` | Installation Documentation | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v1.3-config-validation-design.md` | Config Validation (`/check-setup`) | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v1.4-linux-compatibility-design.md` | Linux Compatibility | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v1.5-pipeline-reporting-design.md` | Pipeline Reporting (Dry-Run + Summary) | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v1.6-pipeline-extension-design.md` | Pipeline Extension (Worktrees, Multi-tracker, Rollback) | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v1.7-reliability-design.md` | Reliability (E2E Tests, Retry Limits, Error Reporting) | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v1.8-pipeline-resume-design.md` | Pipeline Resume (`/resume-ticket`) | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v1.9-dx-commands-design.md` | DX Commands (`/status`, `/onboard`, `/changelog`) | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v2.0-extensibility-design.md` | Extensibility (Hooks + Custom Agents) | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v2.1-integrations-design.md` | Integrations (Webhook, `/version-check`, Token Estimation) | APPROVED | v2.0 |
| 2026-02-25 | `2026-02-25-v2.0-sync-document.md` | v2.0 Sync Document (conflict matrix + dependency graph) | ARCHIVE | v2.0 |
| 2026-02-25 | `2026-02-25-v2.0-implementation-plan.md` | v2.0 Implementation Plan | ARCHIVE | v2.0 |
| 2026-02-25 | `2026-02-25-bifito-v2.0-upgrade.md` | BIFITO v2.0 Upgrade Guide | ARCHIVE | v2.0 |
| 2026-02-25 | `2026-02-25-future-roadmap.md` | Future Roadmap (v2.0 era) | SUPERSEDED | v2.0 |

### v3.0 Designs (consolidated into v3.0.0 release)

| Date | File | Title | Status | Version |
|------|------|-------|--------|---------|
| 2026-02-27 | `2026-02-27-01-feature-pipeline-v3.0.md` | Feature Pipeline Design | SUPERSEDED | v3.0 |
| 2026-02-27 | `2026-02-27-02-decomposition-v3.1.md` | Task Decomposition Design | SUPERSEDED | v3.0 |
| 2026-02-27 | `2026-02-27-03-dashboard-v3.2.md` | Dashboard L1 Design | SUPERSEDED | v3.0 |
| 2026-02-27 | `2026-02-27-04-scaffold-plugin-v1.0.md` | Scaffold Plugin Design | SUPERSEDED | v3.0 |
| 2026-02-27 | `2026-02-27-01-feature-pipeline-v3.0-REVIEW.md` | Feature Pipeline Code Review | ARCHIVE | v3.0 |
| 2026-02-27 | `2026-02-27-02-decomposition-v3.1-REVIEW.md` | Task Decomposition Code Review | ARCHIVE | v3.0 |
| 2026-02-27 | `2026-02-27-03-dashboard-v3.2-REVIEW.md` | Dashboard L1 Code Review | ARCHIVE | v3.0 |
| 2026-02-27 | `2026-02-27-04-scaffold-plugin-v1.0-REVIEW.md` | Scaffold Plugin Code Review | ARCHIVE | v3.0 |
| 2026-02-28 | `2026-02-28-v3.0-unified-design.md` | v3.0 Unified Design Document | IMPLEMENTED | v3.0 |
| 2026-02-28 | `2026-02-28-v3.0-plan-review.md` | v3.0 Implementation Plan Review | ARCHIVE | v3.0 |
| 2026-02-28 | `2026-02-28-v3.0-implementation-plan.md` | v3.0 Implementation Plan | ARCHIVE | v3.0 |

### v3.1 Designs (consolidated into v3.1.0 release)

| Date | File | Title | Status | Version |
|------|------|-------|--------|---------|
| 2026-02-28 | `2026-02-28-v3.1-v5.0-roadmap-design.md` | v3.1–v5.0 Roadmap | SUPERSEDED | v3.1 |
| 2026-03-01 | `2026-03-01-v3.1-unified-design.md` | v3.1 Unified Release Design | IMPLEMENTED | v3.1 |
| 2026-03-01 | `2026-03-01-v3.1-implementation-plan.md` | v3.1 Implementation Plan | ARCHIVE | v3.1 |
| 2026-03-01 | `v3.1-scalability-assessment.md` | Pure Markdown Scalability Assessment | ARCHIVE | v3.1 |

### v3.2 Documentation Overhaul

| Date | File | Title | Status | Version |
|------|------|-------|--------|---------|
| 2026-03-02 | `2026-03-01-documentation-overhaul-design.md` | Documentation Overhaul — Full EN Rewrite | PROPOSED | v3.2 |
| 2026-03-02 | `2026-03-02-docs-overhaul-phase-1-plan.md` | Phase 1: Translation (CZ → EN) Plan | PROPOSED | v3.2 |
| 2026-03-02 | `2026-03-02-docs-overhaul-phase-2-plan.md` | Phase 2: Directory Restructure Plan | PROPOSED | v3.2 |
| 2026-03-02 | `2026-03-02-docs-overhaul-phase-3-plan.md` | Phase 3: New Documentation Plan | PROPOSED | v3.2 |
| 2026-03-02 | `2026-03-02-docs-overhaul-phase-4-plan.md` | Phase 4: README Rewrite Plan | PROPOSED | v3.2 |

### v4.0 Scaffold v2

| Date | File | Title | Status | Version |
|------|------|-------|--------|---------|
| 2026-03-06 | `2026-03-06-scaffold-v2-design.md` | Scaffold v2 — From Description to Working App | IMPLEMENTED | v4.0 |
| 2026-03-06 | `2026-03-06-scaffold-v2-design-REVIEW.md` | Scaffold v2 Design Review | ARCHIVE | v4.0 |
| 2026-03-06 | `2026-03-06-scaffold-v2-implementation-PLAN.md` | Scaffold v2 Implementation Plan Instructions | ARCHIVE | v4.0 |
| 2026-03-06 | `2026-03-06-scaffold-v2-implementation-plan.md` | Scaffold v2 Implementation Plan | ARCHIVE | v4.0 |
| 2026-03-06 | `2026-03-06-scaffold-v2-EXECUTE.md` | Scaffold v2 Execute & Review | ARCHIVE | v4.0 |

### Competitive Analysis & Quality Improvements

| Date | File | Title | Status | Version |
|------|------|-------|--------|---------|
| 2026-03-06 | `competitive-analysis.md` | Competitive Analysis — AI Plugin Landscape | ARCHIVE | — |
| 2026-03-07 | `quality-improvements-plan.md` | Quality & DX Improvement Plan — 12 items | IMPLEMENTED | v4.1.0 |

### Pipeline Improvements Discussions (AC-driven pipelines)

| Date | File | Title | Status | Version |
|------|------|-------|--------|---------|
| 2026-03-08 | `2026-03-08-bugfix-pipeline-discuss.md` | Bug-Fix Pipeline Improvements — AC extraction, verification, retrospectives | ARCHIVE | — |
| 2026-03-08 | `2026-03-08-feature-pipeline-discuss.md` | Feature Pipeline Improvements — AC traceability, acceptance gate | ARCHIVE | — |
| 2026-03-08 | `2026-03-08-scaffold-pipeline-discuss.md` | Scaffold Pipeline Improvements — spec compliance, E2E reliability | ARCHIVE | — |
| 2026-03-08 | `2026-03-08-ac-pipeline-evaluation.md` | Expert Evaluation — 22 proposals consolidated into 12 unified changes | APPROVED | v5.0 |
| 2026-03-08 | `2026-03-08-ac-pipeline-v5-plan.md` | AC-Driven Pipeline v5.0 Implementation Plan | APPROVED | v5.0 |
| 2026-03-09 | `2026-03-08-ac-pipeline-v5-plan-REVIEW.md` | AC-Driven Pipeline v5.0 Plan Review | ARCHIVE | v5.0 |
| 2026-03-09 | `2026-03-09-browser-verification-design.md` | Browser-Based Bug Reproduction & Verification — Design (research R1-R6 + brainstorm) | APPROVED | v5.1.0 |
| 2026-03-09 | `2026-03-09-browser-verification-plan.md` | Browser-Based Bug Reproduction & Verification — Implementation Plan (10 tasks) | IMPLEMENTED | v5.1.0 |
