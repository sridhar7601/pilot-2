---
produced_by: devops
requirement_ids: [REQ-EXP-1..5, REQ-AUTH-1]
date: 2026-06-23
sources:
  - "expense-platform/docker-compose.yml"
  - "expense-platform/README.md"
derivation: Operational runbook for pilot deployment
confidence: high
verified_by:
---

# Runbook — Expense Platform Pilot Deployment

## Prerequisites
- Docker 24+ and Docker Compose v2
- Node 20+ (local frontend dev)
- Python 3.12+ (local backend dev)

## Docker Compose (recommended demo)

```bash
cd expense-platform
docker compose up -d
```

| Service | URL |
|---------|-----|
| API | http://localhost:8000/docs |
| Web | http://localhost:5173 |
| PostgreSQL | localhost:5432 (user: expense) |
| Redis | localhost:6379 |

## Local development

```bash
# Backend
cd expense-platform/backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000

# Frontend
cd expense-platform/frontend
npm install && npm run dev
```

## Health checks
- `GET /health` → `{"status":"ok"}`
- Demo users: emp-1, mgr-1, fin-1, admin-1 (login screen)

## CI
- Workflow: `.github/workflows/expense-platform.yml`
- Triggers on `expense-platform/**` changes

## Rollback
- `docker compose down -v` (destroys volumes — pilot only)
- Redeploy previous image tag when using registry

## Observability (pilot)
- API logs: `docker compose logs -f api`
- No APM wired in pilot — add Datadog/OpenTelemetry for production

## Secrets
- Set `ANTHROPIC_API_KEY` in `.env` for live Claude API (optional)
- Never commit `.env` files
