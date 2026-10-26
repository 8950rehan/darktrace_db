# DarkTrace Database Migration Pack

This pack provides PostgreSQL migration SQL plus Redis configuration and key conventions for the DarkTrace monitoring backend.

## Contents
- `postgres/schema.sql` — PostgreSQL initial schema.
- `postgres/rollback.sql` — drops the objects created by the initial schema (destructive).
- `redis/redis.conf` — secure baseline Redis configuration for a private application network.
- `redis/README.md` — Redis usage, key naming, TTL guidance, and example commands.
- `redis/redis_keys.py` — optional Python helpers for consistent Redis key names.
- `docker-compose.yml` — local PostgreSQL + Redis services for development.
- `.env.example` — sample environment variable names only; do not commit real secrets.

## PostgreSQL migration
Back up the database first. Review the schema and test against a staging database before applying.

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f postgres/schema.sql
```

Rollback is destructive and removes the listed tables:
```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f postgres/rollback.sql
```

The schema uses PostgreSQL. Passwords are stored only as `password_hash`; hash passwords in the application with Argon2id or bcrypt. Never store plaintext passwords or API secrets in these tables.

## Redis
Redis is for ephemeral data such as Celery queues, short-lived cache entries, rate limits, and temporary job status. PostgreSQL remains the system of record. Do not store plaintext passwords, long-lived secrets, or authoritative audit records in Redis.

Redis is not a relational database and does not use SQL `CREATE TABLE` schemas. Use key namespaces and expiration policies instead. The provided Redis config binds to localhost for local use and requires authentication via ACL. Set a strong secret in `.env`; for production, use a managed Redis service/private network and TLS.
