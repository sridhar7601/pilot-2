# Assignment Brief — Developer (CR-1)

**Issued by:** Orchestrator  
**Agent:** developer (`.claude/agents/developer.md`)  
**Skill:** `coding-standards`  
**Change request:** CR-1

## Work item
- **WI-023:** Editable submission fields + PDF + DOCX receipt support

## Requirements
- REQ-EXP-1 — expense submission with receipt capture

## Inputs
- `context/artifacts/contracts/api-spec.yaml` (PATCH `/expenses/{id}` already specified)
- `context/requirements/expense-submission.feature`
- UAT feedback from WI-021

## Writable paths
- `expense-platform/backend/**`
- `expense-platform/frontend/**`
- `staging/artifacts/contracts/**`

## Tasks
1. `PATCH /api/v1/expenses/{id}` — update merchant, category, amount on draft/returned expenses
2. Frontend: persist edited fields on blur and before submit; re-evaluate policy
3. `FileDropZone`: accept images, PDF, and DOCX; validate MIME/extension
4. Backend: allow PDF and DOCX in receipt upload; mock extraction tags `mock_pdf` / `mock_docx`
5. Update staged OpenAPI contract for supported receipt MIME types
6. Fix: `batch_approve` eager-load approval chain; resubmit reuses existing chain

## Definition of Done
- Merchant, amount, category editable after AI extraction
- PDF and DOCX uploads accepted end-to-end
- `pytest` green (including tester BDD suite)
- Attestation: `staging/artifacts/attestation/developer-cr1-attestation.md`

## Handoff to
Tester — WI-024
