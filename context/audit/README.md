# Audit trail (accountability)

Append-only record of everything that happened in every session, so any action is attributable to a
time, a session, an active role, and an operation. This is the **accountability** half of the
control environment (the **data-credibility** half is the integrity ledger in this folder).

Files:
- `audit-log.jsonl` — one JSON object per event (SessionStart, UserPromptSubmit, tool use,
  SubagentStop, Stop, SessionEnd, PreCompact). Written by `.claude/hooks/audit-log.sh`.
- `integrity-ledger.csv` — SHA-256 of every artifact synced into `context/`, with approver and gate
  reference. Written by `.claude/hooks/sync-context.sh`; verified by `/verify-integrity`.

## Keep it trustworthy
- Treat these as append-only. Commit them; never rewrite history.
- The audit log records actions; the gate log (`context/gates/gate-log.md`) records human decisions;
  the integrity ledger proves synced data has not changed since sign-off. Together they answer
  *who did what, who approved it, and is the data still exactly what was approved.*
- In hardened setups, ship these to an external WORM/SIEM store so they cannot be altered locally.
