-- =====================================================================
-- SUNRA Showroom Management System - Part 2 Security Repeatable Migration
-- File: database/migration/R__02_security.sql
-- Repeatable migration: procedures, functions, views, triggers.
-- Runs automatically on changes. Must DROP ... IF EXISTS before CREATE.
-- Engine: MySQL 8.4 (InnoDB, utf8mb4)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Restricted Public User View (v_user_public)
-- ---------------------------------------------------------------------
-- Exposes safe user attributes with resolved role name.
-- SECURITY: Strictly omits password_hash to prevent credential leakage.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_user_public;

CREATE VIEW v_user_public AS
SELECT
    u.user_id,
    u.user_id       AS id,
    u.username,
    u.full_name,
    u.email,
    u.phone,
    r.role_name,
    u.is_active,
    u.created_at,
    u.last_login_at
FROM app_user u
INNER JOIN role r ON u.role_id = r.role_id;

-- ---------------------------------------------------------------------
-- 2. Procedure: sp_get_login_user
-- ---------------------------------------------------------------------
-- Returns user credentials and security state for authentication check.
-- Used by Spring Security / UserDetailsService during login.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_get_login_user;

DELIMITER $$
CREATE PROCEDURE sp_get_login_user(
    IN p_username VARCHAR(50)
)
BEGIN
    SELECT
        u.user_id,
        u.user_id       AS id,
        u.username,
        u.password_hash,
        r.role_name,
        u.is_active,
        u.failed_attempts,
        u.locked_until
    FROM app_user u
    INNER JOIN role r ON u.role_id = r.role_id
    WHERE u.username = p_username
    LIMIT 1;
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- 3. Procedure: sp_record_login
-- ---------------------------------------------------------------------
-- Updates authentication state after a login attempt:
--   - Success: resets failed_attempts to 0, clears locked_until, updates last_login_at to NOW().
--   - Failure: increments failed_attempts. If failed_attempts >= 5, locks account for 15 minutes.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_record_login;

DELIMITER $$
CREATE PROCEDURE sp_record_login(
    IN p_user_id INT UNSIGNED,
    IN p_success BOOLEAN
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_success THEN
        UPDATE app_user
        SET failed_attempts = 0,
            locked_until    = NULL,
            last_login_at   = NOW()
        WHERE user_id = p_user_id;
    ELSE
        UPDATE app_user
        SET failed_attempts = failed_attempts + 1,
            locked_until    = CASE
                WHEN failed_attempts + 1 >= 5 THEN NOW() + INTERVAL 15 MINUTE
                ELSE locked_until
            END
        WHERE user_id = p_user_id;
    END IF;

    COMMIT;
END$$
DELIMITER ;
