# Provenance header convention (data credibility)

Every artifact an agent stages should begin with a provenance block so that, once synced, its
origin and trustworthiness are self-describing. The integrity ledger then proves it hasn't changed
since sign-off. Copy this block to the top of staged Markdown artifacts:

```yaml
---
produced_by: <agent>            # e.g. architect
requirement_ids: [REQ-XXX]      # what this traces to
date: YYYY-MM-DD
sources:                        # where the facts came from (REQUIRED for external data)
  - "<system / document / URL / dataset + version>"
derivation: "<how it was produced — query, model, manual analysis>"
confidence: high | medium | low
verified_by: "<human or check>" # left blank until the gate sign-off fills it
---
```

## Rules
- **No unsourced external facts.** Any figure, claim, or dataset drawn from outside the repo must
  list its source. An artifact with external data and no `sources` is not gate-ready.
- **State derivation and confidence** so reviewers can judge credibility, not just correctness.
- `verified_by` is completed at the human gate; agents never self-verify.
- After sync, `/verify-integrity` proves the content matches what was signed.
