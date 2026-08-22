---
produced_by: devops
requirement_ids: [REQ-EXP-1, REQ-EXP-2, REQ-EXP-3, REQ-EXP-4, REQ-EXP-5, REQ-AUTH-1]
date: 2026-06-23
sources:
  - "expense-platform/docker-compose.yml"
  - ".github/workflows/expense-platform.yml"
derivation: Release notes compiled from implemented pilot scope and orchestration plan WI-022
confidence: high
verified_by:
---

# Release Notes — Expense Platform Pilot v1.0.0

**Release date:** 2026-06-23  
**Gate:** G4 (release readiness)  
**Orchestrator WI:** WI-022

## What's in this release

### Employee experience
- SSO-ready login (pilot: role selector)
- Dashboard with reimbursement summary cards
- AI receipt upload with confidence-scored fields
- Policy verdict (pass/warn/block) before submit
- Event-sourced expense timeline + predicted payout date

### Approver experience
- Risk-sorted approval queue
- Batch approve for clean items
- Review screen with policy + duplicate flags
- Self-approval guard enforced

### Finance & Admin
- Spend analytics dashboard with category bars
- Natural-language spend queries (guarded mock)
- Reimbursement batch processing
- Policy editor (read + version display)
- Approval chain builder (pilot UI)

### Platform
- FastAPI backend + React frontend
- Docker Compose (api, web, postgres, redis)
- GitHub Actions CI (lint + test + build)
- 8 automated tests (unit, API, BDD)

## Demo-ready

```bash
cd expense-platform/backend && source .venv/bin/activate && uvicorn app.main:app --reload
cd expense-platform/frontend && npm run dev
```

Or: `cd expense-platform && docker compose up`

## Deliberately out of scope (pilot)

- Production Entra ID SSO integration
- Email-forwarding intake (receipts@)
- Production Claude API (mock fallback included)
- Full pytest-bdd coverage (2 of 6 feature files)
- ECS/RDS production deployment

## Known limitations

- Demo auth via `X-User-Id` / `X-Role` headers
- SQLite default for local dev; PostgreSQL via Docker Compose
- NL analytics uses mock SQL compilation

## Productionisation gaps

1. Entra ID OAuth2 + JWT validation
2. S3 receipt storage with encryption at rest
3. RQ workers for SLA timers and notifications
4. Row-level security policies in PostgreSQL
5. Full BDD suite + security/load tests
6. Secrets management (Vault / AWS SM)
