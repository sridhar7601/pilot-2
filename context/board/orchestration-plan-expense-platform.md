# Orchestration Plan — Expense Management Platform

> **Orchestrator-owned.** All work routes hub-and-spoke. No spoke-to-spoke handoffs.
> Initiative: Expense Management & Reimbursement Platform (Design Document, June 2026)

## Sequential delivery phases

```
ORCHESTRATOR
     │
     ├─► Phase 1  Solution Owner    WI-001, WI-002     Requirements, SOW, timeline
     │         │ gate G1 (scope sign-off)
     ├─► Phase 2  Architect         WI-003..008        Architecture, wireframes, ADRs, API
     │         │ gate G2 (design sign-off)
     ├─► Phase 3  DevOps             WI-009, WI-019     Scaffold, Docker, CI
     │         │
     ├─► Phase 4  Developer          WI-010..014, 016, 017   Backend + frontend
     │         │ (parallel safe after G2)
     ├─► Phase 5  Data Engineer       WI-015             Analytics, AI data layer
     │         │ gate G3 (quality gate)
     ├─► Phase 6  Tester             WI-018, WI-020     pytest-bdd, coverage matrix
     │         │ gate G4 (release readiness)
     ├─► Phase 7  DevOps             WI-022             Release notes, runbooks
     │         │ gate G5 (UAT / release)
     └─► Phase 8  Solution Owner      WI-021             UAT execution sheet
```

## Gate map

| Gate | Stage | Scope | Blocks |
|------|-------|-------|--------|
| G1 | 1 | Scope baseline (requirements + SOW) | Architect start |
| G2 | 1 | Architecture & contracts locked | Build phase |
| G3 | 2 | Quality gate (tests green, coverage met) | Release prep |
| G4 | 3 | Deployment readiness | UAT |
| G5 | 3 | UAT passed | Closeout |

## Current orchestration status (2026-06-23)

| Phase | Agent | Status | Agent session |
|-------|-------|--------|---------------|
| 1 | solution-owner | **done** — G1 synced | orchestrator-routed |
| 2 | architect | **done** — G2 synced | subagent:33a2f473 |
| 3 | devops | **attested** | devops-phase-3-attestation |
| 4 | developer | **attested** | developer-phase-4-attestation |
| 5 | data-engineer | **attested** | data-engineer-phase-5-attestation |
| 6 | tester | **done** — G3 | orchestrator-routed |
| 7 | devops | **done** — G4 synced | WI-022 release notes |
| 8 | solution-owner | **done** — G5 synced | WI-021 UAT closeout |

## Rework policy

Any defect from Tester → Orchestrator routes to Developer.
Any requirement change → Orchestrator routes to Solution Owner → Architect (if design impact).

## Assignment briefs

See `context/board/assignments/` — one brief per agent phase with WI, REQ, inputs, and DoD.
