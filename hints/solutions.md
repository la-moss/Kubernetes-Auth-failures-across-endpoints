# Emergency Hints + Solutions (Spoilers)

Use this file only if you are blocked and need a recovery path quickly.

## Fast recovery checklist

1. Deploy the challenge you are testing before verify:
   - `make deploy-ch1 && make verify-ch1`
   - `make deploy-ch2 && make verify-ch2`
   - `make deploy-ch3 && make verify-ch3`
2. Confirm pods are healthy:
   - `kubectl -n incident-lab get pods`
3. Check active `papi-config` values:
   - `kubectl -n incident-lab get configmap papi-config -o yaml`
4. If state looks stale, reset:
   - `make down && make start`

---

## Challenge 1 (auth failures)

### What is happening

- Profile 1 fails when `401/403` responses are seen.
- In this stack, dependency timeouts can be mapped to auth failures when:
  - `MAP_TIMEOUT_TO_AUTH: "true"`

### Hints

- Look at how `papi` handles exceptions from calls to `sobrain`.
- Confirm whether timeout errors are converted into auth responses.

### Solution (known-good)

Set this in `manifests/overlays/challenge1/papi-config-patch.yaml`:

```yaml
data:
  MAP_TIMEOUT_TO_AUTH: "false"
```

That keeps timeout/dependency issues from appearing as auth failures.

---

## Challenge 2 (success rate + no 5xx)

### What is happening

- Profile 2 requires:
  - success rate >= 95%
  - no 5xx responses
- `sobrain` baseline delay is ~800ms, but challenge2 timeout is too low (`0.2s`), so requests fail fast as 504.

### Hints

- Compare `TIMEOUT_S` against `sobrain` delay.
- Keep `MAP_TIMEOUT_TO_AUTH` disabled.

### Solution (known-good)

Set this in `manifests/overlays/challenge2/papi-config-patch.yaml`:

```yaml
data:
  RETRIES: "0"
  TIMEOUT_S: "1.2"
  BACKOFF_MS: "0"
  JITTER_MS: "0"
  MAP_TIMEOUT_TO_AUTH: "false"
```

This is enough to clear profile2 in the current simulation.

---

## Challenge 3 (latency budget)

### What is happening

- Profile 3 fails when average latency exceeds `1300ms`.
- Challenge3 injects slower `sobrain` responses (`DELAY_MS: "1200"`).
- A very high timeout can let latency drift over budget.

### Hints

- Keep retries bounded.
- Use timeout as a latency guardrail, not just a dependency wait limit.

### Solution (known-good)

Set this in `manifests/overlays/challenge3/papi-config-patch.yaml`:

```yaml
data:
  RETRIES: "0"
  TIMEOUT_S: "1.0"
  BACKOFF_MS: "0"
  JITTER_MS: "0"
  MAP_TIMEOUT_TO_AUTH: "false"
```

This bounds latency during degraded dependency behavior and satisfies profile3 in this lab.
