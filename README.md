# Agentic Delivery Framework — Claude Code Embedded Delivery Lifecycle

A reusable base framework that realises the **Agentic Delivery Model** as governed Claude Code
sessions. It encodes a hub-and-spoke mesh of role-specialised agents — one **Orchestrator** plus
six specialists — whose scope is strictly bounded by role contracts, and runs them across a
three-stage delivery lifecycle with human sign-off gates and automated quality gates.

This is a **base framework only**: all seven agents, their contracts, the governance, hooks,
commands, and the shared-context/lifecycle scaffolding — with no domain content seeded. Drop your
codebase in and start delivering.

## The agents (hub-and-spoke)

```
                         ┌─────────────────────────────┐
                         │       ORCHESTRATOR          │
                         │  assigns · gates · routes   │
                         │  handoff order: 1 → … → 6   │
                         └──────────────┬──────────────┘
        ┌───────────┬───────────┬───────┼───────┬───────────┬───────────┐
        ▼           ▼           ▼               ▼           ▼           ▼
   ① Solution   ② Architect ③ Developer    ④ Tester   ⑤ DevOps    ⑥ Data
      Owner                                                          Engineer
        └───────────┴──────── SHARED CONTEXT LAYER (context/) ───────┴──────┘
```

Every specialist communicates **only** with the Orchestrator — never with each other. Each agent's
full role contract (responsibilities, in/out of scope, inputs, outputs, definition of done) lives
in `.claude/agents/`.

## What's in the box

```
.
├── CLAUDE.md                     # the project AI constitution — loaded into every session
├── .claude/
│   ├── settings.json             # permissions (allow/deny/ask), full hook lifecycle, hardening
│   ├── scope-manifest.json       # exclusive per-agent write ownership (enforced)
│   ├── agents/                   # 7 role-contract subagents (orchestrator + 6 specialists)
│   ├── skills/                   # 7 standards skills — one per agent (the "how", to global best-practice)
│   ├── commands/                 # 12 slash commands incl. /act-as, /sync-context, /verify-integrity, /governance-check
│   └── hooks/                    # quality-gate, safety-rail, scope, gated-context, audit & integrity scripts
├── .mcp.json                     # governed external tools (project-scoped, least-privilege)
├── staging/                      # where agents write proposals (pre sign-off, not yet shared)
├── context/                      # GATED shared context layer — entered only after human sign-off
│   └── audit/                    # append-only audit trail + tamper-evident SHA-256 integrity ledger
├── lifecycle/                    # the three delivery stages, each with a README + exit gate
└── docs/                         # orchestration, lifecycle, role-contracts, governance, configuration
```

This framework is **domain-agnostic** — software, data, content, or ops. Only the repo-code globs in
the scope manifest and the toolchain in the hooks need tailoring to your stack; see
`docs/configure-for-your-use-case.md`. The governance core does not change.

### Gated context layer — sign-off before sync

A human owner signing off at the gate is **mandatory before any data is synced to the context
layer**. Agents write deliverables to `staging/`; the `context-guard` hook blocks direct writes to
the gated `context/` folders; and `/sync-context` promotes staged work only after it finds a PASS
row with a named human approver in `context/gates/gate-log.md`. Agents accelerate the work — they do
not replace accountability.

## How the Claude Code capabilities map

| Capability | Where it lives |
|------------|----------------|
| CLAUDE.md governance (the AI constitution) | `CLAUDE.md` |
| Plan Mode review (human sign-off before writes) | `permissions.defaultMode: plan` + gate commands |
| Hooks & automation (format / type / test) | `.claude/hooks/*` wired in `.claude/settings.json` |
| Custom slash commands (repeatable ops) | `.claude/commands/*` |
| Agentic, full-codebase code generation | Developer/Data Engineer agents + repo context |
| Role expertise (Skills) | `.claude/skills/` — one standards skill per agent (global best-practice, with house-style overrides) |
| Permissions & safety rails | `.claude/settings.json` allow/deny/ask + `gate-guard.sh` |
| Strict role/scope adherence (enforced) | `scope-manifest.json` + `scope-guard.sh` + `/act-as` |
| Sign-off before sync (mandatory gate) | `staging/` + `context-guard.sh` + `sync-context.sh` + `/sync-context` |
| Accountability (full audit trail) | `audit-log.sh` on every lifecycle event → `context/audit/audit-log.jsonl` |
| Data credibility (provenance + tamper-evidence) | provenance headers + SHA-256 `integrity-ledger.csv` + `/verify-integrity` |
| MCP governance & self-check | `.mcp.json` least-privilege + `/governance-check` |

## Getting started

1. **Place the framework at your repo root** (so `CLAUDE.md` and `.claude/` sit alongside your code).
2. Make the hooks executable: `chmod +x .claude/hooks/*.sh`
3. Open the repo in Claude Code. `CLAUDE.md` loads automatically; the agents and commands are
   discovered from `.claude/`.
4. Start the lifecycle with the Orchestrator:
   - `/act-as <role>` whenever you focus a session on one specialist → scope-guard then enforces
     that role's lane (clear it to return to an unrestricted Orchestrator session).
   - `/orchestrate <your initiative>` → builds the dependency-aware backlog
   - `/intake-requirements <need>` → Solution Owner writes Gherkin requirements
   - `/design-review <feature>` → Architect produces design + contracts + ADRs
   - build with the Developer / Data Engineer agents → `/generate-tests` → `/release-readiness`
   - `/gate-check <1|2|3>` at each stage boundary; after a human signs off, `/sync-context <scope>`
     promotes the staged artifacts into `context/`. Close out with `/ai-usage-summary`.

## Tooling assumptions

Hooks and permissions are **polyglot (Node + Python)**: they auto-detect file type and run the
matching toolchain (prettier/eslint/tsc/jest|vitest for Node; ruff/black/mypy/pytest for Python).
Any tool that isn't installed is skipped, so the framework runs cleanly on a fresh repo and tightens
automatically as you add a stack.

## The non-negotiables

- Hub-and-spoke only; agents stay strictly in their contracted scope — **enforced** by `scope-guard`
  against an exclusive ownership manifest, not just documented. Out-of-lane work goes back to the
  Orchestrator, never to another agent.
- Plan before writing; humans sign off at every gate (no self-certification).
- **Human sign-off is mandatory before anything is synced to the context layer** (stage → gate → sync).
- Hooks and gates are never bypassed.
- Everything is traceable: board → requirements → design → code → tests → release.
- Every action is on the record (audit trail); every synced datum is sourced and hash-verified.
- `/governance-check` confirms the control environment is intact at any time.

See `docs/` for the detailed orchestration, lifecycle, and role-contract references.
