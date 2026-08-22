# Staging Layer — pre-sign-off workspace

This is where agents write their proposed artifacts. **Nothing here is part of the shared context
layer yet.** It is a holding area between an agent finishing work and a human approving it.

## The mandatory rule

> Human owners sign off at every gate **before** any data is synced to the context layer.
> Agents accelerate the work; they do not replace accountability.

Flow for every deliverable:

```
agent writes  →  staging/<area>/...        (proposed, unsigned)
                      │
                 human gate sign-off recorded in context/gates/gate-log.md
                      │
   /sync-context  →  context/<area>/...     (canonical, signed, the thing other agents read)
```

Promotion is performed only by `/sync-context` (which runs `.claude/hooks/sync-context.sh`). That
script **refuses to copy anything** unless it finds a matching PASS row with a human approver in
`context/gates/gate-log.md`. A `context-guard` hook independently blocks agents from writing
directly into the gated `context/` folders.

## Layout (mirrors the gated context folders)

```
staging/
├── requirements/   → promotes to context/requirements/
├── decisions/      → promotes to context/decisions/
├── artifacts/      → promotes to context/artifacts/
└── telemetry/      → promotes to context/telemetry/
```

## Not gated (control plane, written directly in context/)

`context/board/` and `context/gates/` are the Orchestrator's coordination and audit control plane.
They must stay continuously writable — the gate log is the very mechanism that authorises a sync,
so it cannot itself be gated. Everything that represents **delivered work** is gated.
