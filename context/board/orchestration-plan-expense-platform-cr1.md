# Orchestration Plan — CR-1 Post-UAT Enhancements

> **Orchestrator change control** after G5 closeout. Hub-and-spoke only; no direct spoke edits.

## Change request

| Field | Value |
|-------|-------|
| CR ID | CR-1 |
| Trigger | UAT feedback — editable submission fields; PDF and DOCX receipt upload |
| Requirements | REQ-EXP-1 (submission & receipts) |
| Gate | G6-CR1 — change control (human sign-off before attestation sync) |

## Feature scope

| Capability | WI | Agent |
|------------|-----|-------|
| PATCH expense API + editable form persistence | WI-023 | developer |
| PDF receipt upload + mock extraction | WI-023 | developer |
| DOCX receipt upload + mock extraction | WI-023 | developer |
| API/BDD regression for receipt formats | WI-024 | tester |
| Contract + coverage + attestations | WI-023/024 | developer/tester |

## Sequential routing

| Step | Agent | WI | Deliverable |
|------|-------|-----|-------------|
| 1 | orchestrator | — | Decompose CR-1; issue assignments |
| 2 | developer | WI-023 | PATCH API; editable fields; PDF + DOCX upload validation |
| 3 | tester | WI-024 | BDD + API regression; coverage matrix |
| 4 | orchestrator | — | Attestations staged; request G6-CR1 |

## Dependency graph

```
orchestrator → developer (WI-023) → tester (WI-024) → orchestrator → human G6-CR1 → /sync-context
```

## Scope boundaries (enforced)

| Agent | May write |
|-------|-----------|
| developer | `expense-platform/backend/**`, `expense-platform/frontend/**`, `staging/artifacts/contracts/**` |
| tester | `expense-platform/backend/tests/**`, `staging/artifacts/coverage-matrix*` |
| orchestrator | `context/board/**` only |

## Status (2026-07-02)

| Step | Status |
|------|--------|
| WI-023 developer | **done** — editable + PDF + DOCX attested |
| WI-024 tester | **done** — 42 passed; attestations staged |
| G6-CR1 | **PASS** — synced | Ashwin Balasubramaniam |
