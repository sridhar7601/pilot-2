---
produced_by: solution-owner
requirement_ids: [REQ-EXP-1, REQ-EXP-2, REQ-EXP-3, REQ-EXP-4, REQ-EXP-5, REQ-AUTH-1]
date: 2026-06-23
workspace: pilot
gate: G1 · solution-owner
sources:
  - "Design-Document_Final.pdf — Expense Management & Reimbursement Platform (June 2026)"
derivation: Scope baseline extracted from the design document's executive summary and scope section for the two-week pilot delivery.
confidence: high
verified_by:
---

# Scope Baseline — Expense Management & Reimbursement Platform (Pilot)

## Objective
Deliver an AI-native expense management platform where deterministic systems decide on money and
AI removes friction (extraction, explanation, drafting, and natural-language querying only).
Pilot delivered within a two-week window using the Agentic Delivery Model.

## In scope
- **Expense submission** (REQ-EXP-1): receipt upload (JPEG/PNG/PDF, ≤10MB), AI field pre-fill with
  per-field confidence scoring, duplicate detection, manual-entry fallback on low-confidence
  extraction, multi-line/multi-cost-centre expenses, multi-currency capture with submission-time
  conversion rate storage.
- **Approval workflow** (REQ-EXP-2): configurable multi-level approval chains, risk-sorted queue,
  batch approval restricted to unflagged items, mandatory self-approval block, mandatory rejection
  comment, return-for-edit with preserved history, SLA-based escalation (delegation-aware),
  reassignment on deactivated approver.
- **Policy-as-code enforcement** (REQ-EXP-3): versioned deterministic policy engine evaluated at
  submission (pass/warn/block), AI plain-language explanations layered on top of (never replacing)
  the deterministic verdict, submission-time policy version pinning for in-flight expenses,
  no-receipt declaration workflow above a configurable threshold, admin policy authoring with
  dry-run simulation against historical data.
- **Reimbursement status tracking** (REQ-EXP-4): event-sourced, append-only expense timeline,
  predicted (estimate-only) payout date, batch reimbursement marking, partial-reimbursement
  handling, reimbursement-failure/retry recording, employee-initiated dispute routing to finance.
- **Spend analytics and NL Q&A** (REQ-EXP-5): role-aware dashboard (spend by category/cost
  centre/team), anomaly alerts, guarded natural-language querying restricted to an allowlisted
  read-only SQL compiler with low-confidence fallback to canned reports; no write access via NL
  query under any circumstance.
- **Authentication and access control** (REQ-AUTH-1): SSO-first login via Microsoft Entra ID with
  roles sourced from identity-provider claims, role-scoped visibility (employee/approver/finance),
  session expiry handling, deactivated-account denial, a clearly marked demo auth fallback for
  pilot environments without a live Entra tenant.
- Gherkin-driven test suite intended to become the CI/UAT basis for the above.
- Docker Compose pilot deployment (packaging only; production infra is out of scope — see below).

## Out of scope (pilot de-scope order — first to drop if the two-week window is at risk)
1. Email-forwarding receipt intake (`receipts@` inbox ingestion).
2. Production-grade anomaly-detection ML models (pilot ships rule-based/heuristic alerts only;
   full ML anomaly detection is a post-pilot investment).
3. Full production SSO tenant integration and lifecycle (provisioning, conditional access,
   MFA policy) — pilot ships the demo auth fallback described above.
4. Multi-currency FX hedging or rate-locking beyond capturing the submission-time rate.
5. Automated bank-file generation/payment execution — reimbursement marking in this pilot is a
   status transition recorded by finance, not an integration with a payment rail.
6. Mobile native apps (pilot targets responsive web only).
7. Fine-grained delegation-of-authority editor beyond the single approver-level delegation used
   for SLA escalation.

## Assumptions
- Design-Document_Final.pdf is the authoritative source for pilot intent; no separate stakeholder
  interviews were available for this pilot workspace.
- "Finance" and "Approver" are treated as identity-provider role claims, not platform-managed
  roles, consistent with SSO-first authentication scope.
- Pilot demo data stands in for production expense history; no live financial ledger integration
  is assumed.

## Constraints
- Two-week delivery window (see `staging/artifacts/timeline-baseline.md` if produced separately;
  timeline in this workspace is out of scope for this gate unless requested).
- Deterministic systems are the sole authority over money-moving decisions; AI never approves,
  rejects, or authorises payment — enforced structurally, not just by convention.

## Acceptance
All Gherkin scenarios in `staging/requirements/expense-*.feature` are reviewed and accepted at
gate G1 as the testable basis for design (Architect) and downstream build/test work. Acceptance of
the platform itself is demonstrated when every scenario passes in CI and the pilot demo runs
end-to-end against the in-scope items above.

## RACI
| Area | Solution Owner | Architect | Developer | Tester | DevOps | Data Engineer |
|------|----------------|-----------|-----------|--------|--------|---------------|
| Requirements | A/R | C | I | C | I | C |
| Scope changes | A/R | C | I | I | I | I |
| Architecture | A | R | C | I | C | C |
| Implementation | A | C | R | C | C | R |
| Quality gate | A | I | C | R | I | C |
| Release | A | I | C | C | R | I |

## Change control
Any addition, removal, or reinterpretation of the items above is a scope change and must be
escalated to the Orchestrator, not silently absorbed into build. No item is de-scoped below the
line without recording the decision in `context/gates/gate-log.md`.
