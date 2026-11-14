-- =====================================================================
-- SUNRA Showroom Management System - Part 2 Dynamic Privilege Revocation Demo
-- File: database/scripts/02_revoke_demo.sql
-- Purpose: Demonstrate dynamic privilege enforcement in MySQL 8.4:
--          1. Baseline test: app_sales can SELECT customer
--          2. REVOKE SELECT on customer from app_sales
--          3. Test denial: app_sales gets ERROR 1142
--          4. GRANT SELECT on customer back to app_sales
--          5. Test recovery: app_sales can SELECT customer again
-- =====================================================================

-- ---------------------------------------------------------------------
-- STEP 1: Verify Baseline Access (Run as app_sales)
-- Command: mysql -u app_sales -pCHANGE_ME_sales sunra_db
-- ---------------------------------------------------------------------
-- EXPECTED: Query OK, returns customer rows
SELECT customer_id, first_name, last_name, phone FROM customer LIMIT 2;

-- ---------------------------------------------------------------------
-- STEP 2: Revoke Privilege (Run as root)
-- Command: mysql -u root -proot sunra_db
-- ---------------------------------------------------------------------
REVOKE SELECT ON sunra_db.customer FROM 'app_sales'@'localhost';
FLUSH PRIVILEGES;

-- Verify grant is removed:
SHOW GRANTS FOR 'app_sales'@'localhost';

-- ---------------------------------------------------------------------
-- STEP 3: Verify Denial Error (Run as app_sales)
-- Command: mysql -u app_sales -pCHANGE_ME_sales sunra_db
-- ---------------------------------------------------------------------
-- EXPECTED:
--   ERROR 1142 (42000): SELECT command denied to user 'app_sales'@'localhost' for table 'customer'
-- ACTUAL: (paste here when executed)
SELECT customer_id, first_name, last_name, phone FROM customer LIMIT 2;

-- ---------------------------------------------------------------------
-- STEP 4: Grant Privilege Back (Run as root)
-- Command: mysql -u root -proot sunra_db
-- ---------------------------------------------------------------------
GRANT SELECT ON sunra_db.customer TO 'app_sales'@'localhost';
FLUSH PRIVILEGES;

-- Verify grant is restored:
SHOW GRANTS FOR 'app_sales'@'localhost';

-- ---------------------------------------------------------------------
-- STEP 5: Verify Access Restored (Run as app_sales)
-- Command: mysql -u app_sales -pCHANGE_ME_sales sunra_db
-- ---------------------------------------------------------------------
-- EXPECTED: Query OK, customer records returned normally
-- ACTUAL: (paste here when executed)
SELECT customer_id, first_name, last_name, phone FROM customer LIMIT 2;
