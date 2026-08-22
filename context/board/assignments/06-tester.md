# Assignment Brief — Tester (Phase 6)

**Issued by:** Orchestrator  
**Agent:** tester (`.claude/agents/tester.md`)  
**Skill:** `testing-standards`

## Work items
- WI-018: pytest-bdd suite from Gherkin
- WI-020: Edge-case coverage matrix

## Inputs
- `expense-platform/features/*.feature`
- `staging/requirements/expense-*.feature`
- Running backend (for integration tests)

## Writable paths
- `expense-platform/tests/**` (if using top-level tests dir per scope manifest)
- `expense-platform/backend/tests/**` (bdd steps)
- `staging/artifacts/coverage-matrix.md`

## Definition of Done
- pytest-bdd step definitions for all Gherkin scenarios
- Coverage matrix maps edge cases to tests
- Quality gate G3 criteria met (suite green)
- Defects routed to Orchestrator → Developer

## Handoff to
DevOps (WI-022) after G3
