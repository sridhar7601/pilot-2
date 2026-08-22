---
produced_by: architect
requirement_ids: [REQ-EXP-1, REQ-EXP-3, REQ-EXP-5, REQ-AUTH-1]
date: 2026-06-23
sources:
  - "context/requirements/expense-submission.feature"
  - "context/requirements/expense-policy.feature"
  - "context/requirements/expense-analytics-access.feature"
  - "context/requirements/expense-auth.feature"
derivation: "Decision derived from the signed Gherkin scenarios requiring a deterministic policy authority, a guarded NL query path, and SSO-first auth, plus the pilot's two-week delivery constraint"
confidence: high
verified_by:
---

# ADR-0001: Technology Stack and AI Boundary

- **Status:** Proposed
- **Date:** 2026-06-23
- **Owner (agent):** Architect
- **Human approver:** _(required before status = Accepted)_
- **Requirements:** REQ-EXP-1, REQ-EXP-3, REQ-EXP-5, REQ-AUTH-1

## Context

The platform handles real reimbursement money and must be delivered as a short pilot. Three
requirement-driven forces converge on this decision:

1. **REQ-EXP-3** requires "the deterministic policy engine is the sole authority for the verdict"
   and explicitly states "the LLM does not approve or move money." This is a hard, testable
   scenario, not a preference.
2. **REQ-EXP-1** and **REQ-EXP-5** use Claude for receipt field extraction and NL→SQL translation —
   both probabilistic outputs that must be validated or confirmed before they have any effect.
3. **REQ-AUTH-1** requires SSO-first login with roles sourced from the identity provider claims,
   with no password storage in the platform, plus a demo-auth fallback for the pilot environment
   when no production Entra ID tenant is configured.

The backend must be async-capable (OCR and NL pipelines are I/O-bound and long-running), expose an
auto-generated contract to avoid spec drift between Architect, Developer, and Tester, and fit a
two-week delivery window with a Python-native LLM SDK.

## Decision

### 1. Backend: FastAPI (Python) + PostgreSQL 16 with Row-Level Security

FastAPI is chosen for async-first request handling and automatic OpenAPI generation from Pydantic
models — the generated spec and `staging/artifacts/contracts/api-spec.yaml` must stay in lock-step.
PostgreSQL 16 is the primary store; Row-Level Security enforces role-scoped visibility
(REQ-AUTH-1) at the database layer so an application bug cannot leak cross-employee data.

### 2. Frontend: React 18 + TypeScript

Chosen for strict typing across the employee/approver/finance/admin screen set and fast iteration
via Vite.

### 3. AI boundary rule (non-negotiable, enforced by design — not by prompt)

> Claude API outputs never directly trigger a financial write, an approval state change, or a
> reimbursement action. Every AI output is a suggestion, an explanation, or a translation that a
> human confirms or a deterministic guard validates before any state-changing write occurs.

| AI task | Output type | Who/what acts on it | Requirement |
|---------|-------------|----------------------|-------------|
| Receipt field extraction | Structured JSON + confidence scores | Employee confirms in UI before submit | REQ-EXP-1 |
| Policy plain-language explanation | Text string | Displayed only; verdict itself comes from the deterministic policy engine | REQ-EXP-3 |
| NL→SQL translation | SQL string | `NLQueryGuard` parses and validates SELECT-only against an allowlist before execution under a restricted DB role | REQ-EXP-5 |

There is no code path where a Claude `messages` response is deserialised and used directly as an
argument to a state-changing DB write, an approval transition, or a payment instruction.

### 4. Auth: Entra ID OIDC, with an explicit demo-auth fallback for the pilot

Production auth is Microsoft Entra ID via OIDC; roles come from IdP claims. Because the pilot
environment may have no production tenant configured, a demo-auth fallback is included that maps a
fixed set of pilot accounts to roles and visibly marks the session as non-production
(REQ-AUTH-1 "Demo auth fallback" scenario). This is a pilot-only path — it must not exist as a
silent option in a production deployment profile.

## Alternatives considered

### Backend
| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| FastAPI | Native async, Pydantic validation, auto-OpenAPI, Python (Anthropic SDK native) | Smaller ecosystem than Django | Chosen |
| Django REST Framework | Mature auth/admin tooling | Sync-first; ASGI is bolted on; heavier for a 2-week pilot | Rejected |
| Node/Express | Fast startup | Team skill and Anthropic SDK ergonomics favour Python | Rejected |

### AI boundary
| Option | Risk | Decision |
|--------|------|----------|
| Human-in-loop + deterministic guard (chosen) | Low — no automated financial action from AI | Chosen |
| Agentic AI approval (Claude approves autonomously) | High — violates REQ-EXP-3 directly; non-deterministic financial decisions; audit failure | Rejected |
| AI-approves-with-human-veto | High — inverts burden of proof; still an AI-initiated financial action pending veto | Rejected |

### Auth fallback
| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Demo-auth fallback, clearly marked (chosen) | Unblocks pilot without a production tenant; testable per REQ-AUTH-1 | Must be excluded from production build config | Chosen |
| Require production Entra tenant before any pilot login | Fully production-representative | Blocks the pilot timeline entirely | Rejected |

## Consequences

**Positive**
- FastAPI's auto-generated OpenAPI gives Developer and Tester a single, drift-free contract.
- The AI boundary rule gives auditors a single architectural fact to verify rather than reviewing
  every prompt: no LLM output reaches a financial write undetected.
- RLS is a defence-in-depth layer independent of application code correctness.

**Negative / trade-offs**
- The NL→SQL guard and the receipt-confirmation UI both add implementation surface directly
  because of the boundary rule. Mitigation: both are pure/isolated modules with focused unit tests
  (Developer/Tester follow-on).
- The demo-auth fallback is an extra code path that must be explicitly disabled outside the pilot
  profile. Mitigation: DevOps gates it behind an environment flag, off by default.

**Follow-on work**
- Developer: implement `NLQueryGuard` as a pure validate-then-execute module; implement receipt
  confirmation as a required UI step before submit.
- Tester: add a negative test asserting no code path lets a Claude response write directly to
  `expenses`/`expense_events`/reimbursement tables.
- DevOps: gate the demo-auth fallback behind an env flag; ensure it is off in any non-pilot profile.

## Traceability

- Implements: REQ-EXP-1 (extraction confirmation), REQ-EXP-3 (deterministic verdict authority),
  REQ-EXP-5 (NL→SQL guard), REQ-AUTH-1 (SSO + demo fallback + RLS)
- Affects contracts: `staging/artifacts/contracts/api-spec.yaml`
- Referenced by: `staging/artifacts/design/architecture.md` §1, §4.1–4.6, §5
