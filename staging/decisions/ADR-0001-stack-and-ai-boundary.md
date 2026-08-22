---
produced_by: architect
requirement_ids: [REQ-EXP-1, REQ-EXP-3, REQ-EXP-5, REQ-AUTH-1]
date: 2026-06-23
sources:
  - "Design-Document_Final.pdf — Expense Management & Reimbursement Platform (June 2026)"
  - "staging/artifacts/sow-expense-platform.md"
derivation: "Decision derived from SOW technology section, pilot constraints, and regulatory/audit requirements for financial systems"
confidence: high
verified_by:
---

# ADR-0001: Technology Stack and AI Boundary

- **Status:** Proposed
- **Date:** 2026-06-23
- **Owner (agent):** Architect
- **Human approver:** _(required before status = Accepted)_
- **Requirements:** REQ-EXP-1, REQ-EXP-3, REQ-EXP-5, REQ-AUTH-1

---

## Context

The Expense Management Platform must be delivered within a two-week pilot window. It involves financial data, regulated reimbursement decisions, and AI-assisted workflows. Three key technology decisions interact:

1. **Backend framework** — the API layer must be async-capable (receipt OCR is async), self-documenting (OpenAPI contract required), and Python-based (team skill set and LLM SDK availability).
2. **Frontend framework** — the SPA must support 10 distinct screens, strict TypeScript, and fast iteration.
3. **AI boundary** — Claude API is used for receipt extraction, policy explanation, and NL→SQL. The platform handles real money. The regulatory and audit requirement is that no AI output may directly trigger a financial write, approval state change, or reimbursement action. This is not a preference — it is a hard control.

Key forces:
- Financial systems require deterministic, auditable control flows for money movement
- AI outputs (LLM) are probabilistic and non-deterministic; they cannot be the authorising agent for financial transactions
- The team must deliver 10 screens and 5 core backend engines in two weeks — framework DX matters
- OpenAPI spec must be auto-generated for the developer-tester contract (no manual spec drift)
- The pilot uses Docker Compose; the architecture must be Kubernetes-ready without reconfiguration

---

## Decision

### 1. Backend: FastAPI (Python 0.115.x) + PostgreSQL 16

FastAPI is chosen as the backend framework. PostgreSQL 16 is the primary datastore with Row-Level Security (RLS) enforced at the database layer.

### 2. Frontend: React 18 + TypeScript 5 + Vite

React 18 is chosen as the frontend framework with TypeScript for strict typing and Vite for fast DX.

### 3. AI Boundary Rule (non-negotiable, enforced by design)

> **Claude API outputs NEVER directly trigger a financial write, an approval state change, or a reimbursement action.**

The boundary is enforced architecturally:

| AI task | Claude output type | Who / what acts on it |
|---------|-------------------|----------------------|
| Receipt extraction | Structured field suggestions (JSON) | Employee confirms in UI → human submits form |
| Policy explanation | Plain-language text string | Displayed to user; no side effects |
| NL→SQL | SQL string | `NLQueryGuard` validates (SELECT-only, whitelisted tables) → executes under `analytics_reader` DB role |
| Anomaly detection | Flag + explanation text | Finance team investigates; no automated action |

There is no code path in which a `messages` API response is deserialized and used as a direct argument to a state-changing DB write or financial transaction without a human action or a deterministic rule evaluation in between.

---

## Alternatives Considered

### Backend alternatives

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| **FastAPI** | Native async, Pydantic validation, auto OpenAPI, Python (LLM SDK), high DX | Smaller ecosystem than Django | ✅ **Chosen** |
| Django REST Framework | Large ecosystem, mature auth | Sync-first (ASGI is bolted on), verbose, heavier | ✗ Rejected — async is first-class requirement |
| Node.js / Express | Fast startup, large ecosystem | Team skill set is Python; Anthropic SDK is Python-native | ✗ Rejected — team alignment |
| Go / Gin | High performance, low memory | No official Anthropic Go SDK; team skill gap; over-engineered for pilot | ✗ Rejected — pilot velocity |

### Frontend alternatives

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| **React 18 + TypeScript** | Mature, large component ecosystem, shadcn/ui, Vite | React complexity for simpler screens | ✅ **Chosen** |
| Next.js | SSR/SSG capabilities | SSR not required (auth-gated SPA); adds complexity | ✗ Rejected — YAGNI |
| Vue 3 | Simpler reactivity model | Smaller component library ecosystem; team less familiar | ✗ Rejected — ecosystem and team fit |
| Angular | Enterprise-grade, built-in DI | High ceremony, steep learning curve, slower iteration | ✗ Rejected — pilot velocity |

### Database alternatives

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| **PostgreSQL 16** | RLS, JSONB, ACID, mature, open-source | Operational overhead vs. managed services (irrelevant for pilot) | ✅ **Chosen** |
| MySQL | Wide adoption | No native RLS; JSON support weaker; less suitable for event sourcing | ✗ Rejected — RLS is mandatory |
| MongoDB | Flexible schema | No RLS; ACID across collections weaker; financial data needs strong consistency | ✗ Rejected — financial consistency requirement |
| SQLite | Zero-ops for pilot | Not suitable for concurrent multi-user; no RLS | ✗ Rejected — concurrency requirement |

### AI boundary alternatives

| Option | Description | Risk | Decision |
|--------|-------------|------|----------|
| **Human-in-loop + deterministic guard** (chosen) | AI suggests / explains; human or rule engine acts | Low — no automated financial action | ✅ **Chosen** |
| Agentic AI approval | Claude evaluates and approves expenses autonomously | High — LLM non-determinism in financial decisions; audit failure; regulatory risk | ✗ Rejected — unacceptable risk |
| AI with human override only | AI approves; human can veto | High — burden of proof reversal; audit and compliance exposure | ✗ Rejected — inverts accountability |

---

## Consequences

### Positive
- FastAPI auto-generates OpenAPI spec at `/openapi.json` — zero drift between implementation and contract; Tester and Developer share a single contract.
- Pydantic models enforce input validation at the API boundary — reduces injection surface.
- PostgreSQL RLS provides a defence-in-depth layer independent of application code — application-layer bugs cannot leak cross-user data.
- AI boundary rule creates a clear, auditable control: every financial action is traceable to a human or a deterministic rule evaluation. Audit and compliance teams can verify the control without reading LLM code.
- React 18 + TypeScript gives the Developer a well-understood component model with strong typing.

### Negative / trade-offs
- FastAPI requires explicit async discipline — blocking DB calls inside async routes cause subtle performance regressions. Mitigation: SQLAlchemy 2.x async engine + code review checklist.
- RLS configuration in PostgreSQL requires careful `SET LOCAL app.current_user_id` injection in the FastAPI DB session. Misconfiguration risk. Mitigation: integration tests verify role isolation before every deploy (EC-10 in architecture edge-case register).
- The AI boundary rule increases implementation surface for the NL→SQL guard and the receipt extraction confirmation step. Mitigation: these are pure-function modules with high test coverage.

### Follow-on work
- Developer must ensure all SQLAlchemy sessions inject `app.current_user_id` and `app.current_role` before any query.
- Tester must include a cross-role data isolation test suite.
- DevOps must configure PostgreSQL RLS enable flag in the init script.
- Admin UI must surface the AI boundary visually (confidence scores, confirmation steps) so users understand AI's advisory role.

---

## Traceability

- Implements: REQ-EXP-1 (receipt extraction boundary), REQ-EXP-3 (policy engine — deterministic), REQ-EXP-5 (NL→SQL guard), REQ-AUTH-1 (SSO + RLS)
- Affects contracts: `staging/artifacts/contracts/api-spec.yaml`
- Related ADRs: ADR-0002 (event-sourced lifecycle)
- Referenced by: `staging/artifacts/design/architecture.md` §3–5
