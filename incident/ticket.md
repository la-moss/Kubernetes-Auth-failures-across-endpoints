# Ticket — SEV-2: Auth failures across endpoints

**Customer impact:** intermittent 401/403 responses and elevated latency  
**Environment:** prod  
**Constraint:** do not disable auth globally; keep safe-by-default behavior

## Observations

- Auth failures spike during peak load.
- No corresponding IAM changes.
- Downstream dependency `sobrain` shows sporadic slow responses.
- Pipelines are blocked due to runtime verification failures introduced in a recent change.

## Task

Restore safe delivery by fixing the stack so that:
- dependency degradation does not appear as auth failures
- retry/timeout behavior is bounded and production-safe
- runtime checks pass
