"""Centralized Redis key naming; no credentials or sensitive values here."""
def cache_key(resource: str, identifier: str) -> str:
    return f"darktrace:cache:{resource}:{identifier}"

def job_status_key(job_id: str) -> str:
    return f"darktrace:job:{job_id}:status"

def rate_limit_key(user_id: str, window: str) -> str:
    return f"darktrace:ratelimit:{user_id}:{window}"

def lock_key(name: str) -> str:
    return f"darktrace:lock:{name}"
