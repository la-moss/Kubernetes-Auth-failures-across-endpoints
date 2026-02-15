# Emergency Hints / Solutions (Use Only When Stuck)

This repo is designed to be solved via runtime signals and iterative changes.
This file exists for **emergencies**: broken local environment, confusing signals, or “I need a fast path back to a working baseline”.

It aims to be **helpful without requiring spoilers**. It focuses on recovery, debugging technique, and how to interpret the verification harness.

---

## Fast recovery (clean reset)

If anything feels “haunted” (stale outputs, half-applied manifests, unexpected kube context):

```bash
make down && make start
```

If you specifically want to re-apply the current challenge overlay:

```bash
make deploy-ch1
make deploy-ch2
make deploy-ch3
```

Always wait for rollouts before verifying:

```bash
make verify-ready
```

---

## “Verify is failing” checklist (90% of failures)

### 1) Confirm you’re looking at the right namespace

Everything runs in `incident-lab`:

```bash
kubectl -n incident-lab get pods,svc
```

### 2) Read the verification output like a contract

The runtime harness reports three metrics:

- `metric_a`: number of `401/403` responses seen (auth failures)
- `metric_b`: number of `5xx` responses seen (server errors)
- `metric_c`: average latency in ms

Depending on the profile, it enforces different thresholds (see `Makefile` and `scripts/verify/runtime_checks.sh`).

If you want more/less sampling while debugging, you can temporarily change the request count:

```bash
VERIFY_REQUESTS=50 make verify-ch1
```

(Don’t “solve” the incident by loosening thresholds — use this only to make symptoms reproducible.)

### 3) Check the obvious runtime signals

```bash
kubectl -n incident-lab get pods
kubectl -n incident-lab describe deploy papi
kubectl -n incident-lab describe deploy sobrain
kubectl -n incident-lab logs deploy/papi --tail=200
kubectl -n incident-lab logs deploy/sobrain --tail=200
```

### 4) Port-forward collisions (common locally)

Verify uses a port-forward to `svc/papi` on `18080` by default. If the verify script hangs or fails oddly:

- ensure no other process is using `18080`
- re-run `make verify-chX` after a clean reset

The port-forward logs are written to `/tmp/pf.log` during verify runs.

---

## Debugging manifests safely

### See exactly what kustomize will apply

```bash
kubectl kustomize manifests/overlays/challenge1
kubectl kustomize manifests/overlays/challenge2
kubectl kustomize manifests/overlays/challenge3
```

### Confirm what’s actually running in-cluster

```bash
kubectl -n incident-lab get configmap papi-config -o yaml
kubectl -n incident-lab get deploy papi -o yaml
kubectl -n incident-lab get deploy sobrain -o yaml
```

If you update a config map and don’t see behavior change, force a fresh rollout (the `deploy-chX` targets already do this for `papi`):

```bash
kubectl -n incident-lab rollout restart deploy/papi
kubectl -n incident-lab rollout status deploy/papi --timeout=180s
```

---

## Emergency “solutions” (non-spoiler patterns)

These are **solution patterns** you can apply without being told the exact answer:

### Don’t misclassify dependency timeouts as auth failures

If an upstream call is slow/unhealthy, the safe behavior is to surface it as a timeout / gateway error (e.g. `504`) rather than `401/403`.
Auth errors should mean “credential rejected”, not “dependency was slow”.

### Bound retries and avoid retry storms

Retries can turn a small slowdown into a large incident.
If you must retry:

- keep retries low and timeouts reasonable
- add backoff + jitter
- ensure the total worst-case time is bounded (client timeouts + retry budget)

### Make “good” the default

When in doubt, prefer:

- explicit, observable failures (timeouts / 5xx) over misleading auth failures
- stable latency over maximizing success rate through aggressive retries

---

## Rollback / baseline overlays

If you want a “known baseline” outside the challenge overlays:

```bash
make deploy-dev
make deploy-prod
```

Then ensure workloads are healthy:

```bash
make verify-ready
```

