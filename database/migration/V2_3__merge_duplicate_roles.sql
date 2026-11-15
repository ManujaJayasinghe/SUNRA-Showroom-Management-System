-- =====================================================================
-- Migration: V2_3__merge_duplicate_roles.sql
-- Purpose: Consolidate duplicate roles to maintain single canonical role names:
--          - SALES_ASSISTANT -> SALES
--          - STOCK_MANAGER   -> STOCK
-- Execution order: 1. Ensure target roles exist (INSERT/UPDATE)
--                  2. Migrate referencing tables (app_user.role_id)
--                  3. Delete obsolete role rows (DELETE)
-- Safe for both fresh and existing databases.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Ensure canonical target roles exist
-- ---------------------------------------------------------------------
INSERT INTO role (role_name, description) VALUES
    ('SALES', 'Manages customers and sales'),
    ('STOCK', 'Manages products and inventory')
ON DUPLICATE KEY UPDATE
    description = VALUES(description);

-- ---------------------------------------------------------------------
-- 2. Move referencing user records to the canonical role IDs
-- Note: In the schema, app_user is the only table with a foreign key to role.
-- ---------------------------------------------------------------------
UPDATE app_user u
JOIN role r_old ON u.role_id = r_old.role_id AND r_old.role_name = 'SALES_ASSISTANT'
JOIN role r_new ON r_new.role_name = 'SALES'
SET u.role_id = r_new.role_id;

UPDATE app_user u
JOIN role r_old ON u.role_id = r_old.role_id AND r_old.role_name = 'STOCK_MANAGER'
JOIN role r_new ON r_new.role_name = 'STOCK'
SET u.role_id = r_new.role_id;

-- ---------------------------------------------------------------------
-- 3. Delete obsolete legacy roles once all references are cleared
-- ---------------------------------------------------------------------
DELETE FROM role
WHERE role_name IN ('SALES_ASSISTANT', 'STOCK_MANAGER');
