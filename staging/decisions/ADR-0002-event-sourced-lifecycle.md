---
produced_by: architect
requirement_ids: [REQ-EXP-2, REQ-EXP-4]
date: 2026-06-23
sources:
  - "Design-Document_Final.pdf — Expense Management & Reimbursement Platform (June 2026)"
  - "staging/requirements/expense-approval.feature"
  - "staging/requirements/expense-status.feature"
derivation: "Decision derived from Gherkin scenarios requiring full audit trail, return-for-edit history, and resubmission continuity"
confidence: high
verified_by:
---

# ADR-0002: Event-Sourced Expense Lifecycle

- **Status:** Proposed
- **Date:** 2026-06-23
- **Owner (agent):** Architect
- **Human approver:** _(required before status = Accepted)_
- **Requirements:** REQ-EXP-2, REQ-EXP-4

---

## Context

The expense lifecycle is non-trivial: an expense moves through `draft → submitted → in_approval → approved_final → reimbursement_paid`, but it can also be rejected, returned for edit, and resubmitted — with the requirement that history is preserved and resubmission restarts only the remaining chain steps (REQ-EXP-2 scenario 5). Additionally:

- Finance and approvers need a full, immutable audit trail of every state change with actor identity and timestamp (financial compliance requirement).
- The platform must project a "predicted payout date" based on the remaining approval steps and their SLAs (REQ-EXP-4).
- Concurrent approval actions must be detectable and rejected safely (two approvers acting simultaneously on the same step).
- Celery task retries for async operations (receipt extraction, notification dispatch) must be idempotent — re-running a task must not create duplicate events.

The core question: should the expense's current state be stored as a mutable column (`status = 'in_approval'`), or should it be derived from an append-only stream of events?

Key forces:
- **Audit requirement:** every state transition must be attributable (who, when, what payload) — mutable status columns lose history on update
- **Resubmission continuity:** "resubmission restarts only remaining chain steps" requires knowing which steps completed before the return — needs event history
- **Idempotent retries:** Celery retry storms must not double-count events
- **Predicted payout:** computed from remaining steps + SLAs — needs ordered event stream to know which steps are pending
- **Concurrency safety:** two approvers acting simultaneously must be detectable

---

## Decision

The expense lifecycle uses an **event-sourced pattern**: every state transition is recorded as an immutable `ExpenseEvent` row in the `expense_events` table. The current expense state (`expenses.status`) is a **projection** — a denormalised cache of the last computed state derived from the event stream.

### Event store contract

```
expense_events (
    id          UUID PRIMARY KEY,        -- client-generated UUID v4; idempotency key
    expense_id  UUID NOT NULL,           -- FK → expenses
    event_type  VARCHAR(100) NOT NULL,   -- see event type registry below
    actor_id    UUID,                    -- FK → employees; null for system events
    payload     JSONB,                   -- event-specific data
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
)

CONSTRAINT uq_expense_event_id UNIQUE (id)   -- idempotent insert
```

**Append-only enforcement:** RLS policy blocks `UPDATE` and `DELETE` on `expense_events` for the application role. Only a `superuser` migration role can delete (for GDPR anonymisation, with an audit record).

### Event type registry

| Event type | Triggered by | Key payload fields |
|------------|-------------|-------------------|
| `submitted` | Employee confirms submission | `{policy_snapshot_id, chain_id}` |
| `policy_evaluated` | Policy engine | `{verdict, triggered_rules[]}` |
| `submitted_to_approval` | Workflow engine | `{chain_id, first_step_id}` |
| `approved_by_step` | Approver | `{step_id, approver_id, comment}` |
| `rejected` | Approver | `{step_id, approver_id, comment}` |
| `returned_for_edit` | Approver | `{step_id, approver_id, comment}` |
| `resubmitted` | Employee | `{resuming_from_step_id}` |
| `approved_final` | Workflow engine (all steps complete) | `{chain_id}` |
| `reimbursement_initiated` | Finance | `{reimbursement_id, pay_run_id}` |
| `reimbursement_paid` | Finance | `{reimbursement_id, paid_date, reference}` |

### Projection rule

```python
def project_status(events: list[ExpenseEvent]) -> str:
    """Current status = event_type of the last event in temporal order."""
    terminal_map = {
        "submitted": "submitted",
        "policy_evaluated": "submitted",   # status unchanged; policy result in payload
        "submitted_to_approval": "in_approval",
        "approved_by_step": "in_approval", # until all steps complete
        "rejected": "rejected",
        "returned_for_edit": "returned_for_edit",
        "resubmitted": "in_approval",
        "approved_final": "approved_final",
        "reimbursement_initiated": "reimbursement_initiated",
        "reimbursement_paid": "reimbursement_paid",
    }
    return terminal_map[events[-1].event_type]
```

The `expenses.status` column is updated transactionally in the same DB transaction as the `INSERT INTO expense_events` — it is a write-through cache for query performance, not the source of truth.

### Optimistic concurrency control

`expenses.version` is incremented with every status projection update:

```sql
UPDATE expenses
SET status = :new_status, version = version + 1, updated_at = now()
WHERE id = :expense_id AND version = :expected_version;
```

If `rowcount == 0`, a concurrent modification occurred → HTTP 409 Conflict returned to caller.

### Idempotent event inserts

```sql
INSERT INTO expense_events (id, expense_id, event_type, actor_id, payload, occurred_at)
VALUES (:id, :expense_id, :event_type, :actor_id, :payload, now())
ON CONFLICT (id) DO NOTHING;
```

Celery tasks pass the client-generated `event_id` through the task payload. On retry, the duplicate insert is silently ignored — the projection is not re-run.

### Resubmission continuity

When an approver returns an expense for edit and the employee resubmits:
1. A `resubmitted` event is appended with `{resuming_from_step_id: <first_incomplete_step_id>}`.
2. The workflow engine replays the event stream to identify which `approved_by_step` events already exist.
3. Only steps without a corresponding `approved_by_step` event are re-activated — completed steps remain closed.

---

## Alternatives Considered

### Option A: Mutable status column only (no event store)

| Aspect | Assessment |
|--------|-----------|
| Implementation simplicity | ✅ Simple — just `UPDATE expenses SET status = 'approved'` |
| Audit trail | ✗ **Fatal** — history is lost on every update; no actor attribution without a separate log |
| Resubmission continuity | ✗ Cannot know which steps completed before return without additional tables |
| Idempotent retries | ✗ Requires separate deduplication logic |
| Predicted payout | ✗ Requires reconstructing remaining steps from a separate audit table (same complexity as event store) |

**Rejected** — does not satisfy audit and resubmission continuity requirements.

### Option B: Audit log table + mutable status

A separate `expense_audit_log` table records changes; `expenses.status` is mutable.

| Aspect | Assessment |
|--------|-----------|
| Audit trail | ✅ History preserved |
| Projection simplicity | ✅ Current state is the column value |
| Resubmission continuity | ✗ Requires correlating audit rows to step IDs — non-trivial |
| Single source of truth | ✗ Two sources can diverge; audit log and status can be inconsistent on partial failure |
| Idempotency | ✗ Still requires deduplication logic for the audit log |

**Rejected** — two sources of truth create reconciliation burden; event store subsumes both cleanly.

### Option C: Full event sourcing with no status cache

Pure event sourcing — no `status` column; state always projected from event stream on read.

| Aspect | Assessment |
|--------|-----------|
| Correctness | ✅ Single source of truth |
| Query performance | ✗ `SELECT status FROM expenses WHERE submitter_id = ?` would require a subquery aggregation on every load |
| Index efficiency | ✗ Cannot index status for queue listing without materialised views |

**Rejected** — unacceptable query performance for the approval queue listing (hot path). Write-through status cache is the correct trade-off.

---

## Consequences

### Positive
- Every state transition is attributable to a human actor with a timestamp — satisfies financial audit requirements without additional logging infrastructure.
- Resubmission continuity falls out naturally from event replay — no special-case logic required.
- Celery task idempotency is guaranteed by the `ON CONFLICT DO NOTHING` insert — retry storms are safe.
- `expenses.version` provides cheap optimistic concurrency without distributed locks.
- The event stream is the natural source for the approval timeline display (Screen 3) and the payout date projection.
- Future analytics can replay the event stream to reconstruct any historical state (time-travel queries).

### Negative / trade-offs
- Every state transition now requires a DB transaction that writes two rows (`expense_events` + `expenses` update) instead of one. Mitigation: both writes are in the same transaction; negligible overhead.
- Developers must not write raw `UPDATE expenses SET status = ...` — all status changes must go through the ledger module. Mitigation: the `Ledger` class is the only allowed write path; direct `status` updates are a code-review block item.
- Schema migration for new event types requires a deploy. Mitigation: `event_type` is a VARCHAR with no DB-level enum constraint — new event types are additive, not breaking.

### Follow-on work
- Developer must implement `Ledger.append_event()` as the single write path for all expense state changes.
- Developer must write a `project_status()` pure function covering all event types.
- Tester must include event idempotency tests: submit the same `event_id` twice; verify no duplicate state change.
- Tester must include concurrent approval test: two clients approve simultaneously; verify exactly one succeeds and one receives HTTP 409.
- DevOps must ensure `expense_events` table has no `UPDATE`/`DELETE` grants for the application DB role.

---

## Traceability

- Implements: REQ-EXP-2 (approval lifecycle, return-for-edit continuity), REQ-EXP-4 (reimbursement status tracking, payout date)
- Affects contracts: `staging/artifacts/contracts/api-spec.yaml` (event endpoints, `/expenses/{id}/events`)
- Related ADRs: ADR-0001 (stack — PostgreSQL chosen partly for ACID guarantees that make the two-row transaction safe)
- Referenced by: `staging/artifacts/design/architecture.md` §4.4 (Ledger / Event Store), `staging/artifacts/data-model.md` (ExpenseEvent entity)
