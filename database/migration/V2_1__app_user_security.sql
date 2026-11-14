-- =====================================================================
-- Part 2: Login security columns for app_user
-- Adds failed_attempts (with non-negative check) and locked_until.
-- Note: last_login_at already exists in V1_0__schema.sql and is skipped.
-- =====================================================================

ALTER TABLE app_user
    ADD COLUMN failed_attempts INT NOT NULL DEFAULT 0,
    ADD COLUMN locked_until    DATETIME NULL,
    ADD CONSTRAINT chk_app_user_failed_attempts CHECK (failed_attempts >= 0);
