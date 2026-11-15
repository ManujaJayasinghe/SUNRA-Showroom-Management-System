-- =====================================================================
-- SUNRA Showroom Management System - Part 2 Dynamic Privilege Revocation Demo
-- File: database/scripts/02_revoke_demo.sql
-- Purpose: Demonstrate dynamic privilege enforcement in MySQL 8.4:
--          1. Baseline test: app_sales can SELECT customer
--          2. REVOKE SELECT on customer from app_sales (@'%')
--          3. Test denial: app_sales gets ERROR 1142
--          4. GRANT SELECT on customer back to app_sales (@'%')
--          5. Test recovery: app_sales can SELECT customer again
--
-- HOW TO RUN THIS DEMO:
-- Method A (From MySQL Workbench):
--   - Open a tab connected as app_sales (Host: 127.0.0.1, mapped port) for Steps 1, 3, 5.
--   - Open a tab connected as root (Host: 127.0.0.1, mapped port) for Steps 2, 4.
--
-- Method B (From Terminal via Docker CLI):
--   - Connect as app_sales: docker exec -it sunra-mysql mysql -uapp_sales -p sunra_db
--   - Connect as root:      docker exec -it sunra-mysql mysql -uroot -proot sunra_db
-- =====================================================================

-- ---------------------------------------------------------------------
-- STEP 1: Verify Baseline Access (Run as app_sales)
-- ---------------------------------------------------------------------
-- EXPECTED: Query OK, returns customer rows
SELECT customer_id, first_name, last_name, phone FROM customer LIMIT 2;

-- ---------------------------------------------------------------------
-- STEP 2: Revoke Privilege (Run as root)
-- ---------------------------------------------------------------------
REVOKE SELECT ON sunra_db.customer FROM 'app_sales'@'%';
FLUSH PRIVILEGES;

-- Verify grant is removed:
SHOW GRANTS FOR 'app_sales'@'%';

-- ---------------------------------------------------------------------
-- STEP 3: Verify Denial Error (Run as app_sales)
-- ---------------------------------------------------------------------
-- EXPECTED:
--   ERROR 1142 (42000): SELECT command denied to user 'app_sales'@'%' for table 'customer'
-- ACTUAL: (paste here when executed)
SELECT customer_id, first_name, last_name, phone FROM customer LIMIT 2;

-- ---------------------------------------------------------------------
-- STEP 4: Grant Privilege Back (Run as root)
-- ---------------------------------------------------------------------
GRANT SELECT ON sunra_db.customer TO 'app_sales'@'%';
FLUSH PRIVILEGES;

-- Verify grant is restored:
SHOW GRANTS FOR 'app_sales'@'%';

-- ---------------------------------------------------------------------
-- STEP 5: Verify Access Restored (Run as app_sales)
-- ---------------------------------------------------------------------
-- EXPECTED: Query OK, customer records returned normally
-- ACTUAL: (paste here when executed)
SELECT customer_id, first_name, last_name, phone FROM customer LIMIT 2;
