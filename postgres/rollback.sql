-- DESTRUCTIVE: removes data and tables created by schema.sql.
BEGIN;
DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS crawl_job;
DROP TABLE IF EXISTS source;
DROP TABLE IF EXISTS authorizations;
DROP TABLE IF EXISTS users;
COMMIT;
