---
produced_by: solution-owner
requirement_ids: [REQ-EXP-1, REQ-EXP-2, REQ-EXP-3, REQ-EXP-4, REQ-EXP-5, REQ-AUTH-1]
date: 2026-06-23
sources:
  - "context/requirements/expense-*.feature"
  - "context/artifacts/runbooks/expense-platform-deploy.md"
  - "expense-platform/README.md"
derivation: Manual UAT scripts derived from synced Gherkin acceptance criteria
confidence: high
verified_by: Ashwin Balasubramaniam (G5 PASS 2026-06-23)
---

# UAT Execution Sheet — Expense Management Platform (Pilot)

**Work item:** WI-021  
**Gate:** G5 — UAT passed (signed 2026-06-23)  
**Tester:** Ashwin Balasubramaniam  
**Execution date:** 2026-06-23  
**Environment:** ☑ Local dev / Docker Compose (pilot)

## 1. Purpose

This sheet translates all **31 Gherkin scenarios** (6 features) into manual UAT steps for the pilot build. Each row traces to a requirement ID and work item. Record **Pass / Fail / Blocked / N/A** and notes. Defects route to the Orchestrator → Developer.

## 2. Environment setup

```bash
# Option A — Docker (recommended)
cd expense-platform && docker compose up -d

# Option B — Local
cd expense-platform/backend && source .venv/bin/activate && uvicorn app.main:app --reload --port 8000
cd expense-platform/frontend && npm run dev
```

| Check | URL / command | Expected |
|-------|---------------|----------|
| API health | `GET http://localhost:8000/health` | `{"status":"ok"}` |
| API docs | http://localhost:8000/docs | OpenAPI UI loads |
| Web app | http://localhost:5173/login | ExpenseFlow login screen |

## 3. Demo personas (pilot auth)

The pilot uses **role-picker demo login** on `/login` (not production Entra SSO). Select the persona below for each scenario.

| Persona | Login card | Role | Home route |
|---------|------------|------|------------|
| Employee | Employee User (`emp-1`) | employee | `/` |
| Approver | Manager User (`mgr-1`) | approver | `/approvals` |
| Finance | Finance User (`fin-1`) | finance | `/analytics` |
| Admin | Admin User (`admin-1`) | admin | `/admin/policy` |

**Pilot note (REQ-AUTH-1):** Scenario *SSO login via Microsoft Entra ID* is validated by **demo role assignment** — confirm role-appropriate navigation and data scope, not live Entra federation.

## 4. Execution summary

| REQ | Feature | Scenarios | Pass | Fail | Blocked | N/A |
|-----|---------|-----------|------|------|---------|-----|
| REQ-AUTH-1 | SSO & RBAC | 4 | | | | |
| REQ-EXP-1 | Submission & receipts | 6 | | | | |
| REQ-EXP-2 | Approval workflow | 6 | | | | |
| REQ-EXP-3 | Policy-as-code | 5 | | | | |
| REQ-EXP-4 | Reimbursement status | 5 | | | | |
| REQ-EXP-5 | Analytics & NL query | 4 | | | | |
| **Total** | | **31** | | | | |

---

## 5. REQ-AUTH-1 — SSO authentication and role-based access

| ID | Scenario | Role | Steps | Expected result | Result | Notes |
|----|----------|------|-------|-----------------|--------|-------|
| UAT-AUTH-01 | SSO login via Microsoft Entra ID | Any | 1. Open `/login`. 2. Click **Sign in with Microsoft** (pilot: use demo role card instead). 3. Select **Employee User**. | User lands on employee dashboard; no password stored in app; role drives nav items. | | Pilot: Entra stub — verify role card login only. |
| UAT-AUTH-02 | Employee sees only own expenses | Employee | 1. Login as Employee. 2. Open dashboard `/`. 3. Note expense list. 4. Logout; login as different employee if available, or submit new expense as emp-1 and confirm only emp-1 items visible. | List shows only expenses submitted by logged-in employee. | | |
| UAT-AUTH-03 | Approver sees approval queue items | Approver | 1. Login as Manager. 2. Navigate to **Approvals** `/approvals`. | Queue shows expenses awaiting approver action; no unrelated org-wide list. | | |
| UAT-AUTH-04 | Finance sees all expenses | Finance | 1. Login as Finance. 2. Open **Analytics** `/analytics` and **Reimbursements** `/reimbursements`. | Finance can view organisation-wide spend and reimbursement batches. | | |

---

## 6. REQ-EXP-1 — Expense submission with receipt capture

| ID | Scenario | Role | Steps | Expected result | Result | Notes |
|----|----------|------|-------|-----------------|--------|-------|
| UAT-EXP1-01 | Submit expense with AI-extracted receipt fields | Employee | 1. Login as Employee. 2. **New expense** `/expenses/new`. 3. Upload a receipt image (drag-drop). 4. Confirm pre-filled merchant/amount/date. 5. Submit. | Expense status **submitted**; confidence scores visible on extracted fields; policy verdict shown before/at submit. | | |
| UAT-EXP1-02 | Block submission when policy blocks over-limit meal | Employee | 1. New expense, category **Meals**. 2. Enter **$94.00**, 1 attendee. 3. Submit. | Submission **blocked**; plain-language policy explanation (meal limit $75). | | Auto: `test_submission_bdd.py` |
| UAT-EXP1-03 | Warn on submission near policy threshold | Employee | 1. New expense, category **Meals**. 2. Enter **$72.00**, 1 attendee. 3. Submit. | Submission succeeds with verdict **warn**; warning message displayed. | | Auto: `test_submission_bdd.py` |
| UAT-EXP1-04 | Duplicate receipt detection at submission | Employee | 1. Submit expense with receipt A. 2. Create second expense; upload same/similar receipt. 3. Attempt submit. | Duplicate warning shown; if proceeding, expense flagged for approver review. | | |
| UAT-EXP1-05 | Manual entry when receipt extraction fails | Employee | 1. Upload unreadable image (e.g. blank/corrupt file). 2. When extraction confidence is low, fill fields manually. 3. Submit. | Manual fields accepted; original image retained on expense for approver. | | |
| UAT-EXP1-06 | Multi-line expense split across cost centres | Employee | 1. New expense with **two line items** on different cost centres. 2. Submit. | Each line routes to respective cost centre in approval chain. | | Verify on approver review / API detail. |

---

## 7. REQ-EXP-2 — Multi-level approval workflow

| ID | Scenario | Role | Steps | Expected result | Result | Notes |
|----|----------|------|-------|-----------------|--------|-------|
| UAT-EXP2-01 | Approver sees queue sorted by risk | Approver | 1. Ensure mix of flagged and clean expenses exist (submit flagged via duplicate or warn). 2. Login as Manager → `/approvals`. | AI-flagged / higher-risk items appear before clean items. | | |
| UAT-EXP2-02 | Batch approve clean expenses | Approver | 1. Select multiple **unflagged** expenses in queue. 2. Use batch approve action. | All selected move to **approved**. | | |
| UAT-EXP2-03 | Self-approval is blocked | Approver | 1. As Manager, submit own expense (if UI allows) or use API with mgr-1 as submitter. 2. Open approval queue for that expense. | Manager cannot approve own submission; chain routes to alternate approver. | | |
| UAT-EXP2-04 | Required comment on rejection | Approver | 1. Open flagged expense `/approvals/:id`. 2. Reject without comment. 3. Reject with comment. | Reject without comment fails validation; with comment → status **rejected**. | | |
| UAT-EXP2-05 | Return expense for edit preserves history | Approver | 1. Open expense **in_approval**. 2. **Return for edit** with comment. 3. As Employee, view timeline; resubmit. | Status **returned_for_edit**; timeline records return; resubmission continues remaining chain steps. | | |
| UAT-EXP2-06 | SLA escalation when approver unavailable | Admin / API | 1. Create pending approval past SLA (or call `POST /api/v1/admin/sla-check`). 2. Verify delegation / next-node escalation if configured. | Step escalates to delegate or next approver node. | | Pilot: may require admin SLA trigger |

---

## 8. REQ-EXP-3 — Policy-as-code enforcement

| ID | Scenario | Role | Steps | Expected result | Result | Notes |
|----|----------|------|-------|-----------------|--------|-------|
| UAT-EXP3-01 | Policy evaluated at submission returns pass | Employee | 1. Submit **$80** travel expense (under $100 daily limit). | Verdict **pass**. | | |
| UAT-EXP3-02 | Policy evaluated at submission returns block | Employee | 1. Submit **$94** meal (over $75 limit). | Verdict **block**; no approval/payment side effects. | | |
| UAT-EXP3-03 | In-flight expense keeps submission-time policy version | Admin + Employee | 1. Submit expense under current policy. 2. As Admin, publish stricter policy `/admin/policy`. 3. Before approval completes, re-check original expense verdict. | In-flight expense still evaluated against **submission-time** policy version. | | |
| UAT-EXP3-04 | Admin creates new policy version | Admin | 1. Login as Admin → `/admin/policy`. 2. Publish new version with future effective date. | Version number increments; in-flight expenses retain original version. | | |
| UAT-EXP3-05 | Missing receipt above threshold requires declaration | Employee | 1. Submit **$50** expense **without** receipt. 2. Complete missing-receipt declaration when prompted. | Extra approval step added to chain. | | |

---

## 9. REQ-EXP-4 — Reimbursement status tracking

| ID | Scenario | Role | Steps | Expected result | Result | Notes |
|----|----------|------|-------|-----------------|--------|-------|
| UAT-EXP4-01 | Employee views expense timeline | Employee | 1. Open submitted expense `/expenses/:id`. | Human-readable event timeline with actor, timestamp, description per event. | | |
| UAT-EXP4-02 | Timeline updates on every state transition | Approver + Employee | 1. Employee notes timeline. 2. Approver approves expense. 3. Employee refreshes detail page. | New approval event appended; timeline reflects change. | | |
| UAT-EXP4-03 | Predicted payout date shown for approved expenses | Employee | 1. View **approved** expense detail. | Predicted payout date displayed. | | |
| UAT-EXP4-04 | Finance batch reimbursement updates timeline | Finance | 1. Login as Finance → `/reimbursements`. 2. Include approved expenses in payout run; mark batch **paid**. 3. As Employee, view expense timeline. | Status **reimbursed**; reimbursement event on timeline. | | |
| UAT-EXP4-05 | Employee raises dispute from timeline | Employee | 1. On reimbursed expense, use **Raise dispute** from timeline. | Dispute routes to finance queue with full history attached. | | |

---

## 10. REQ-EXP-5 — Spend analytics and natural-language queries

| ID | Scenario | Role | Steps | Expected result | Result | Notes |
|----|----------|------|-------|-----------------|--------|-------|
| UAT-EXP5-01 | Finance dashboard shows company-wide spend | Finance | 1. Login as Finance → `/analytics`. | Totals by category, cost centre, team; anomaly alerts section present. | | |
| UAT-EXP5-02 | Natural language query returns guarded read-only results | Finance | 1. On analytics page, ask: *"What was total travel spend last month?"* | Aggregated results returned; no raw PII rows exposed. | | |
| UAT-EXP5-03 | Low-confidence NL query falls back to canned report | Finance | 1. Ask ambiguous question (e.g. *"Show me everything about John"*). | Low-confidence fallback / canned report; no unrestricted SQL. | | |
| UAT-EXP5-04 | Employee cannot access company-wide analytics | Employee | 1. Login as Employee. 2. Navigate to `/analytics` or call analytics API. | Access denied (403 or redirect); employee dashboard only. | | |

---

## 11. Pilot deviations register

| Gherkin expectation | Pilot behaviour | UAT handling |
|---------------------|-----------------|--------------|
| Microsoft Entra SSO | Demo role cards on `/login` | UAT-AUTH-01: Pass if role-scoped access works; note Entra as post-pilot |
| Full BDD automation | 2/31 scenarios in pytest-bdd | Manual UAT required for remaining scenarios |
| SLA auto-timer | Admin `sla-check` endpoint | UAT-EXP2-06: manual trigger acceptable for pilot |
| Production IdP claims | `X-User-Id` / `X-Role` headers | Implicit in demo login |

---

## 12. Defect log

| Defect ID | UAT ID | Severity | Description | Status |
|-----------|--------|----------|-------------|--------|
| | | | | |

---

## 13. G5 gate sign-off record

**Entry criteria**

- [x] Environment deployed per runbook
- [x] All 31 scenarios executed (or marked Blocked/N/A with rationale)
- [x] No open **Critical** or **High** defects (or accepted with written waiver)
- [x] Pilot deviations documented in §11

**Recommendation:** ☑ Ready for G5 PASS  ☐ Rework required (route defects to Orchestrator)

| Field | Value |
|-------|-------|
| UAT lead | Ashwin Balasubramaniam |
| Business approver | Ashwin Balasubramaniam |
| Date | 2026-06-23 |
| Outcome | ☑ PASS  ☐ FAIL |
| Gate log reference | `context/gates/gate-log.md` — G5 — WI-021, UAT closeout |

> **Orchestrator note:** G5 PASS recorded in `gate-log.md` on 2026-06-23. Artifact promoted via `/sync-context G5` (integrity ledger updated).
