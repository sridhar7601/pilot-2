---
produced_by: tester
requirement_ids: [REQ-EXP-1, REQ-EXP-2, REQ-EXP-3, REQ-EXP-4, REQ-EXP-5, REQ-AUTH-1]
date: 2026-07-02
sources:
  - "Design-Document_Final.pdf — Edge-Case Coverage Matrix"
  - "staging/requirements/expense-*.feature"
  - "expense-platform/features/*.feature"
derivation: Matrix mapping design edge cases to Gherkin scenarios and automated tests (CR-1 update)
confidence: high
verified_by:
---

# Coverage Matrix — Expense Platform

| Edge case | Design response | Gherkin | Automated test | Agent |
|-----------|-----------------|---------|----------------|-------|
| Duplicate receipt | Hash + fuzzy match | expense-submission.feature | test_submission_steps.py | tester |
| Self-approval blocked | Chain resolver skip | expense-approval.feature | test_approval_steps.py | tester |
| Policy block over limit | Deterministic engine | expense-submission.feature | test_submission_steps.py, test_policy.py | tester |
| Policy warn near threshold | Warn verdict | expense-submission.feature | test_submission_steps.py | tester |
| Event timeline | Append-only log | expense-status.feature | test_status_steps.py | tester |
| Employee scope only | RBAC headers | expense-auth.feature | test_auth_steps.py | tester |
| Finance analytics access | Role guard 403 | expense-analytics.feature | test_analytics_steps.py | tester |
| Batch approve clean items | Workflow service | expense-approval.feature | test_approval_steps.py | tester |
| NL query guardrails | Allowlisted SQL | expense-analytics.feature | test_analytics_steps.py | tester |
| In-flight policy version | Version pin at submit | expense-policy.feature | test_policy_steps.py | tester |
| Editable fields after extraction | PATCH + UI persist | expense-submission.feature | test_patch_editable_fields_after_receipt | developer |
| PDF receipt upload | MIME validation | expense-submission.feature | test_upload_pdf_receipt, BDD Scenario Outline | developer/tester |
| DOCX receipt upload | MIME validation | expense-submission.feature | test_upload_docx_receipt, BDD Scenario Outline | developer/tester |
| Invalid receipt type rejected | Server-side guard | expense-submission.feature | test_reject_invalid_receipt_type | tester |

## Quality gate G3 / CR-1 criteria

- [x] Unit tests: policy engine
- [x] API integration tests: submit, block, approve, receipt formats
- [x] BDD: all 6 feature files (42 passed, 2 skipped pilot gaps)
- [x] Security: employee cannot access analytics (`test_analytics_steps.py`)
- [x] CR-1: PDF + DOCX receipt upload regression
- [ ] Dispute flow — backlog (pilot gap)
- [ ] SLA auto-escalation — backlog (pilot gap)

## Routed defects

None — CR-1 closed green.
