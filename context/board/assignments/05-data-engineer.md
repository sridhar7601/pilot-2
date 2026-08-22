# Assignment Brief — Data Engineer (Phase 5)

**Issued by:** Orchestrator  
**Agent:** data-engineer (`.claude/agents/data-engineer.md`)  
**Skill:** `data-engineering-standards`

## Work items
- WI-015: Analytics datasets, NL query guardrails, receipt extraction data layer

## Inputs
- Data model (`staging/artifacts/data-model.md`)
- Analytics requirements (REQ-EXP-5)

## Writable paths
- `expense-platform/backend/app/services/analytics_service.py`
- `expense-platform/backend/app/services/receipt_service.py`
- `expense-platform/backend/app/services/ai_service.py`
- `staging/artifacts/data-model*` (if updates needed)

## Definition of Done
- Dashboard aggregates correct
- NL query uses allowlisted read-only patterns
- Receipt hash + duplicate detection documented
- PII not logged from receipts

## Handoff to
Tester (WI-018)
