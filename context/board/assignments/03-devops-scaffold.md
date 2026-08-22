# Assignment Brief — DevOps (Phase 3 — Scaffold)

**Issued by:** Orchestrator  
**Agent:** devops (`.claude/agents/devops.md`)  
**Skill:** `devops-standards`

## Work items
- WI-009: Monorepo scaffold, Docker Compose
- WI-019: CI pipeline

## Inputs
- Locked API contract (`staging/artifacts/contracts/api-spec.yaml`)
- Architecture stack decision (ADR-0001)

## Writable paths
- `expense-platform/docker-compose.yml`
- `expense-platform/**/Dockerfile*`
- `.github/workflows/expense-platform.yml`

## Definition of Done
- `docker compose up` provisions api/web/postgres/redis
- CI runs lint + test on push to `expense-platform/**`
- Runbook stub in `staging/artifacts/runbooks/`

## Handoff to
Developer (WI-010) — scaffold ready
