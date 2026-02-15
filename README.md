# Week A — Production Incident Game (Kind + Kubernetes)

This is a live production-style incident simulation.

You deploy a stack into a local Kubernetes cluster, observe runtime signals, and resolve failures under delivery pressure.

No static guardrails.  
No lint puzzles.  
Only runtime truth.

---

## The Objective

Clear all three production scenarios by making runtime verification pass:

- `make verify-ch1`
- `make verify-ch2`
- `make verify-ch3`

Each challenge represents a distinct failure pattern seen in real systems.

---

## The Rules

- Treat each challenge like a real SEV-2 in a production namespace.
- Start with runtime signals (`kubectl`, logs, rollout status, HTTP responses).
- Form a hypothesis before making changes.
- Patch manifests/config, redeploy, and re-verify.
- Success is defined by live system behaviour — not green YAML.

No spoilers are included.

---

## The Environment

- Local Kubernetes via Kind
- Shared base workload
- Scenario-specific overlays
- Runtime-only verification harness in `scripts/verify/`

---

## Repository Layout

```text
incident/                  # ticket + timeline context
kind/                      # local cluster configuration
manifests/
  base/                    # shared workloads and services
  overlays/
    challenge1/            # scenario-specific patch set
    challenge2/
    challenge3/
scripts/
  verify/                  # runtime-only verification
Makefile                   # game commands
```

## Prerequisites

- Docker
- kind
- kubectl
- curl

For first-time setup and pre-flight checks, see `FIRST_TIMERS.md`.

## Standard game loop

1) Quick start (cluster up + first challenge deployed + pods ready)

```bash
make start
```

2) Run verification

```bash
make verify-ch1
```

3) Investigate, patch manifests, redeploy, and re-run verify until green

4) Repeat for challenge 2 and challenge 3

```bash
make deploy-ch2 && make verify-ch2
make deploy-ch3 && make verify-ch3
```

5) Tear down cluster

```bash
make down
```

## Common workflow rules

- Always run the matching deploy before each verify (`deploy-chX` then `verify-chX`).
- When switching challenges, redeploy the target challenge first.
- If outputs look stale, redeploy the same challenge and verify again.
- Check pod health before verify:

```bash
kubectl -n incident-lab get pods
```

- If the environment gets messy, reset cleanly:

```bash
make down && make start
```

## Useful commands during triage

```bash
kubectl -n incident-lab get pods
kubectl -n incident-lab get svc
kubectl -n incident-lab describe deploy papi
kubectl -n incident-lab logs deploy/papi --tail=100
kubectl -n incident-lab logs deploy/sobrain --tail=100
```

## Win condition

All challenge verify targets pass in a clean run:

```bash
make verify-ch1
make verify-ch2
make verify-ch3
```
