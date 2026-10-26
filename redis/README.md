# Redis database files and conventions

Redis is a key-value store, not a SQL database: there are no `CREATE TABLE` migrations. These conventions support the app's Celery jobs, cache, temporary status, and rate limiting.

## Suggested logical DBs
- DB 0: cache and temporary job status
- DB 1: rate-limit counters / short-lived throttling state
- Celery broker: preferably a dedicated Redis instance or a separately configured logical DB (do not share a DB index with application cache keys).

## Key patterns
- `darktrace:cache:<resource>:<id>` — cache; set TTL.
- `darktrace:job:<job_uuid>:status` — short-lived status mirror; PostgreSQL is authoritative.
- `darktrace:ratelimit:<user_id>:<window>` — counters; set TTL atomically.
- `celery` / `celery:*` — Celery broker keys; let Celery manage them.
- `darktrace:lock:<name>` — short-lived distributed lock; use atomic SET NX EX and a unique token.

Use TTLs for cache and rate limits. Do not put credentials or sensitive scraped content into Redis unless there is a documented need and access controls are in place. Avoid logging full Redis URLs because they may contain credentials.

## Example commands
```bash
# Inspect server (avoid exposing secrets in screenshots/logs)
redis-cli PING

# Set an expiring cache value
redis-cli SET darktrace:cache:health api-ok EX 60

# Read the value
redis-cli GET darktrace:cache:health

# Delete a temporary key
redis-cli DEL darktrace:cache:health
```

For production, require authentication/ACLs, TLS, private networking, monitoring, and a defined backup/restore policy. The included `redis.conf` is a development baseline, not a complete production hardening profile.
