# Shared Context Layer (gated)

This is the canonical, **signed** source of truth every agent reads on its next handoff. Agents do
**not** write here directly. They write proposals into `staging/`, a human signs off the gate, and
only then does `/sync-context` promote the work into the matching folder here.

> Human sign-off is mandatory **before** any data is synced to this layer. The `context-guard` hook
> blocks direct writes to the gated folders; `sync-context.sh` refuses to promote anything without a
> PASS sign-off (named human approver) in `gates/gate-log.md`. See `staging/README.md` and `CLAUDE.md` §4.

The `board/` and `gates/` folders are the Orchestrator's control plane and are written directly —
the gate log is what authorises a sync, so it cannot itself be gated.

| Folder | Purpose | Primary owners |
|--------|---------|----------------|
| `requirements/` | Validated requirements as Gherkin `.feature` files, tagged with `REQ-*`, plus acceptance criteria | Solution Owner |
| `decisions/` | Architecture Decision Records (`ADR-*.md`); use `ADR-template.md` | Architect |
| `artifacts/` | Designs, interface contracts, API docs, test reports, runbooks, release notes, data model | All |
| `telemetry/` | Coverage reports, test results, observability and data-quality metrics | Tester, DevOps, Data Engineer |
| `board/` | Backlog and work-item tracking (`backlog.md`) | Orchestrator, Solution Owner |
| `gates/` | Auditable gate & escalation log (`gate-log.md`) | Orchestrator |

## Traceability rule

Every artifact references the `REQ-*` ID(s) it satisfies, and every requirement links forward to its
design, code, and tests. No orphaned work items.

```
REQ-* (requirements/) → ADR + design + contract (decisions/, artifacts/) →
code (repo) → tests + coverage (artifacts/, telemetry/) → release (artifacts/) → gate (gates/)
```
