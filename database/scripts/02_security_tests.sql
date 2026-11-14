-- =====================================================================
-- SUNRA Showroom Management System - Part 2 Database Security Tests
-- File: database/scripts/02_security_tests.sql
-- Purpose: Verify least-privilege access controls, denial constraints,
--          and allowed operations across app_admin, app_sales, and app_stock.
-- Target DB: sunra_db (MySQL 8.4)
-- =====================================================================

-- ---------------------------------------------------------------------
-- TEST 1: Purchase Table Isolation (Sales Segregation)
-- ACCOUNT: app_sales (password: CHANGE_ME_sales)
-- COMMAND: SELECT * FROM purchase;
-- EXPECTED:
--   ERROR 1142 (42000): SELECT command denied to user 'app_sales'@'localhost' for table 'purchase'
-- RATIONALE:
--   Sales staff must never see wholesale procurement costs, supplier agreements,
--   or inbound purchase orders.
-- ACTUAL: (paste here when executed against running MySQL)
-- ---------------------------------------------------------------------
-- Run as: mysql -u app_sales -pCHANGE_ME_sales sunra_db
SELECT * FROM purchase;


-- ---------------------------------------------------------------------
-- TEST 2: Customer Personal Data Protection (GDPR / PDPA Compliance)
-- ACCOUNT: app_stock (password: CHANGE_ME_stock)
-- COMMAND: SELECT nic, phone FROM customer;
-- EXPECTED:
--   ERROR 1142 (42000): SELECT command denied to user 'app_stock'@'localhost' for table 'customer'
-- RATIONALE:
--   Warehouse and stock personnel have no legitimate operational need to view
--   customer personally identifiable information (NIC, phone numbers, home addresses).
-- ACTUAL: (paste here when executed against running MySQL)
-- ---------------------------------------------------------------------
-- Run as: mysql -u app_stock -pCHANGE_ME_stock sunra_db
SELECT nic, phone FROM customer;


-- ---------------------------------------------------------------------
-- TEST 3A: Direct Inventory Modification Denial (Rule 4)
-- ACCOUNTS: app_sales and app_stock
-- COMMAND: UPDATE inventory SET quantity_on_hand = 999;
-- EXPECTED:
--   ERROR 1142 (42000): UPDATE command denied to user 'app_sales'@'localhost' for table 'inventory'
--   ERROR 1142 (42000): UPDATE command denied to user 'app_stock'@'localhost' for table 'inventory'
-- RATIONALE:
--   Team Rule 4: Only stored procedures change stock. Never UPDATE inventory
--   directly from any application account.
-- ACTUAL: (paste here when executed against running MySQL)
-- ---------------------------------------------------------------------
-- Run as: mysql -u app_sales -pCHANGE_ME_sales sunra_db
UPDATE inventory SET quantity_on_hand = 999;

-- Run as: mysql -u app_stock -pCHANGE_ME_stock sunra_db
UPDATE inventory SET quantity_on_hand = 999;


-- ---------------------------------------------------------------------
-- TEST 3B: Legitimate Stock Adjustment via Stored Procedure
-- ACCOUNTS: app_sales and app_stock
-- COMMAND: CALL sp_adjust_stock(1, -1, 'SALE', 'SALE', 1, 'Point of sale deduction');
-- EXPECTED:
--   Query OK (Allowed once Part 4 R__04_inventory.sql is merged and EXECUTE granted)
-- RATIONALE:
--   Stock modifications must be driven exclusively through validated business
--   logic encapsulated in sp_adjust_stock to guarantee stock_movement audit logging.
-- ACTUAL: (paste here when executed against running MySQL)
-- ---------------------------------------------------------------------
-- Run as: mysql -u app_sales -pCHANGE_ME_sales sunra_db
-- CALL sp_adjust_stock(1, -1, 'SALE', 'SALE', 1, 'POS sale');

-- Run as: mysql -u app_stock -pCHANGE_ME_stock sunra_db
-- CALL sp_adjust_stock(1, 10, 'PURCHASE', 'PURCHASE', 1, 'Inbound stock');


-- ---------------------------------------------------------------------
-- TEST 4: Credential and Password Hash Protection
-- ACCOUNT: app_sales (and app_stock)
-- COMMAND: SELECT password_hash FROM app_user;
-- EXPECTED:
--   ERROR 1142 (42000): SELECT command denied to user 'app_sales'@'localhost' for table 'app_user'
-- RATIONALE:
--   Regular application tiers must never have direct table access to app_user,
--   preventing exfiltration or brute-forcing of BCrypt password hashes.
-- ACTUAL: (paste here when executed against running MySQL)
-- ---------------------------------------------------------------------
-- Run as: mysql -u app_sales -pCHANGE_ME_sales sunra_db
SELECT password_hash FROM app_user;


-- ---------------------------------------------------------------------
-- TEST 5: Public View Access without Exposing Password Hashes
-- ACCOUNT: app_admin (password: CHANGE_ME_admin)
-- COMMAND: SELECT * FROM v_user_public;
-- EXPECTED:
--   Query returns rows (id, username, full_name, email, phone, role_name, is_active, created_at, last_login_at)
--   Strictly NO password_hash column present in the result set.
-- RATIONALE:
--   Administrative user listings rely on the sanitized view v_user_public.
-- ACTUAL: (paste here when executed against running MySQL)
-- ---------------------------------------------------------------------
-- Run as: mysql -u app_admin -pCHANGE_ME_admin sunra_db
SELECT * FROM v_user_public;


-- ---------------------------------------------------------------------
-- TEST 6: Privilege Audit & Grant Verification
-- ACCOUNT: Run as root
-- COMMAND: SHOW GRANTS FOR '...';
-- EXPECTED:
--   - app_admin: GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON sunra_db.*
--   - app_sales: SELECT/INSERT/UPDATE on customer, sale, sale_item, payment, invoice, document; SELECT on product, inventory
--   - app_stock: SELECT/INSERT/UPDATE on product, product_category, supplier, purchase, purchase_item; SELECT on inventory, stock_movement
-- ACTUAL: (paste here when executed against running MySQL)
-- ---------------------------------------------------------------------
-- Run as: mysql -u root -proot sunra_db
SHOW GRANTS FOR 'app_admin'@'localhost';
SHOW GRANTS FOR 'app_sales'@'localhost';
SHOW GRANTS FOR 'app_stock'@'localhost';
