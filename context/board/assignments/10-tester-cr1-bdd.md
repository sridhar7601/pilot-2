# Assignment Brief — Tester (CR-1)

**Issued by:** Orchestrator  
**Agent:** tester (`.claude/agents/tester.md`)  
**Skill:** `testing-standards`  
**Change request:** CR-1

## Work item
- **WI-024:** BDD coverage + receipt-format regression for CR-1

## Requirements
- REQ-EXP-1..5, REQ-AUTH-1 (all 6 feature files)

## Inputs
- `expense-platform/features/*.feature`
- Developer handoff WI-023 (PATCH API, PDF, DOCX, editable fields)

## Writable paths
- `expense-platform/backend/tests/**`
- `expense-platform/features/**`
- `staging/artifacts/coverage-matrix-expense-platform.md`

## Tasks
1. pytest-bdd step definitions for all 6 Gherkin feature files
2. Add API tests: DOCX upload, PDF upload, invalid type rejection
3. Extend submission BDD for PDF/DOCX receipt attachment types
4. Update coverage matrix — editable fields, PDF, DOCX rows
5. Confirm `pytest -q` green

## Definition of Done
- BDD suite green
- Receipt format regression covered (image, PDF, DOCX)
- Coverage matrix updated in `staging/`
- Attestation: `staging/artifacts/attestation/tester-cr1-attestation.md`

## Handoff to
Orchestrator — G6-CR1 gate readiness
