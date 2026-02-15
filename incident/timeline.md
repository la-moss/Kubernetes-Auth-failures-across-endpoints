# Timeline (simulated)

- T+00m: deploy `papi` change to prod
- T+05m: error rate increases; 401/403 spike
- T+08m: latency climbs; retries increase load on `sobrain`
- T+12m: responders suspect auth/IAM, but evidence is inconsistent
- T+18m: dependency timeouts correlate with “auth failures”
- T+25m: rollback considered; delivery pressure increases
