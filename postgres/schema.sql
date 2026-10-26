-- DarkTrace initial PostgreSQL schema
-- Run only after reviewing and backing up the target database.
BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(254) NOT NULL,
    username VARCHAR(80) NOT NULL,
    password_hash TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT users_email_lowercase CHECK (email = LOWER(email)),
    CONSTRAINT users_email_nonempty CHECK (LENGTH(TRIM(email)) > 3),
    CONSTRAINT users_username_nonempty CHECK (LENGTH(TRIM(username)) > 0),
    CONSTRAINT users_email_unique UNIQUE (email),
    CONSTRAINT users_username_unique UNIQUE (username)
);

CREATE TABLE IF NOT EXISTS authorizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(32) NOT NULL DEFAULT 'analyst',
    granted_by UUID REFERENCES users(id) ON DELETE SET NULL,
    granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    CONSTRAINT authorizations_role_allowed CHECK (role IN ('admin', 'analyst', 'reviewer', 'readonly')),
    CONSTRAINT authorizations_expiry_valid CHECK (expires_at IS NULL OR expires_at > granted_at),
    CONSTRAINT authorizations_user_role_unique UNIQUE (user_id, role)
);

CREATE TABLE IF NOT EXISTS source (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(120) NOT NULL,
    source_type VARCHAR(32) NOT NULL,
    base_url TEXT,
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    config JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT source_name_nonempty CHECK (LENGTH(TRIM(name)) > 0),
    CONSTRAINT source_type_allowed CHECK (source_type IN ('forum', 'marketplace', 'paste_site', 'blog', 'feed', 'other')),
    CONSTRAINT source_config_object CHECK (jsonb_typeof(config) = 'object'),
    CONSTRAINT source_name_type_unique UNIQUE (name, source_type)
);

CREATE TABLE IF NOT EXISTS crawl_job (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id UUID NOT NULL REFERENCES source(id) ON DELETE RESTRICT,
    requested_by UUID REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'queued',
    priority SMALLINT NOT NULL DEFAULT 5,
    scheduled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    result_count INTEGER NOT NULL DEFAULT 0,
    error_code VARCHAR(80),
    error_summary VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT crawl_job_status_allowed CHECK (status IN ('queued', 'running', 'succeeded', 'failed', 'cancelled')),
    CONSTRAINT crawl_job_priority_range CHECK (priority BETWEEN 1 AND 10),
    CONSTRAINT crawl_job_result_nonnegative CHECK (result_count >= 0),
    CONSTRAINT crawl_job_timestamps_valid CHECK (
        (started_at IS NULL OR started_at >= scheduled_at)
        AND (finished_at IS NULL OR started_at IS NOT NULL)
        AND (finished_at IS NULL OR finished_at >= started_at)
    )
);

CREATE TABLE IF NOT EXISTS audit_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(80) NOT NULL,
    resource_id VARCHAR(128),
    outcome VARCHAR(20) NOT NULL DEFAULT 'success',
    ip_address INET,
    user_agent TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT audit_log_outcome_allowed CHECK (outcome IN ('success', 'denied', 'failure')),
    CONSTRAINT audit_log_metadata_object CHECK (jsonb_typeof(metadata) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_authorizations_user_id ON authorizations(user_id);
CREATE INDEX IF NOT EXISTS idx_authorizations_expiry ON authorizations(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_source_enabled ON source(is_enabled);
CREATE INDEX IF NOT EXISTS idx_crawl_job_status_scheduled ON crawl_job(status, scheduled_at);
CREATE INDEX IF NOT EXISTS idx_crawl_job_source_created ON crawl_job(source_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_actor_created ON audit_log(actor_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_metadata_gin ON audit_log USING GIN(metadata);

COMMIT;
