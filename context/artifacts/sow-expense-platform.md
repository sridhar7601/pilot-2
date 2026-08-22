---
produced_by: solution-owner
requirement_ids: [REQ-EXP-1, REQ-EXP-2, REQ-EXP-3, REQ-EXP-4, REQ-EXP-5, REQ-AUTH-1]
date: 2026-06-23
sources:
  - "Design-Document_Final.pdf — Expense Management & Reimbursement Platform (June 2026)"
derivation: Scope baseline extracted from overall design document executive summary and scope section
confidence: high
verified_by:
---

# Statement of Work — Expense Management & Reimbursement Platform

## Objectives
Deliver an AI-native expense management platform where deterministic systems decide on money and AI removes friction. Pilot delivery within a two-week window using the Agentic Delivery Model.

## In scope
- Expense submission with receipt upload, AI pre-fill, confidence scoring, duplicate detection
- Configurable multi-level approval hierarchies with graph-based workflow engine
- Policy-as-code enforcement at submission (pass/warn/block) with AI plain-language explanations
- Event-sourced reimbursement status tracking with predicted payout date
- Role-aware spend analytics dashboard with NL Q&A (guarded text-to-SQL)
- Admin policy editor and approval chain builder
- SSO-first authentication (Entra ID) with RBAC
- Gherkin-driven test suite and Docker Compose pilot deployment

## Out of scope (pilot de-scope order)
1. Email-forwarding intake (receipts@)
2. Production anomaly-detection ML models
3. Full production SSO tenant integration (demo auth fallback included)

## Acceptance
All Gherkin scenarios in `staging/requirements/expense-*.feature` pass in CI; wireframes implemented per `staging/artifacts/design/wireframes.md`.

## RACI
| Area | Solution Owner | Architect | Developer | Tester | DevOps | Data Engineer |
|------|----------------|-----------|-----------|--------|--------|---------------|
| Requirements | A/R | C | I | C | I | C |
| Architecture | A | R | C | I | C | C |
| Implementation | A | C | R | C | C | R |
| Quality gate | A | I | C | R | I | C |
| Release | A | I | C | C | R | I |
