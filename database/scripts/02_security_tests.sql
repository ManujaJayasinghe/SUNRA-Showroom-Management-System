-- =====================================================================
-- SUNRA Showroom Management System - Part 2 Database Security Tests
-- File: database/scripts/02_security_tests.sql
-- Purpose: Verify least-privilege access controls, denial constraints,
--          and allowed operations across app_admin, app_sales, and app_stock (@'%').
-- Target DB: sunra_db (MySQL 8.4)
--
-- HOW TO RUN THESE TESTS:
-- Option A (From MySQL Workbench):
--   1. Create a Connection in Workbench:
--      - Hostname: 127.0.0.1
--      - Port: <mapped_port> (e.g. 3306 or 3307)
--      - Username: app_sales, app_stock, or app_admin
--      - Password: CHANGE_ME_sales, CHANGE_ME_stock, or CHANGE_ME_admin
--      - Default Schema: sunra_db
--   2. Open a SQL Query tab and execute each test query.
--
-- Option B (From Terminal via Docker CLI):
--   docker exec -it sunra-mysql mysql -uapp_sales -p sunra_db
--   docker exec -it sunra-mysql mysql -uapp_stock -p sunra_db
--   docker exec -it sunra-mysql mysql -uapp_admin -p sunra_db
-- =====================================================================

-- ---------------------------------------------------------------------
-- TEST 1: Purchase Table Isolation (Sales Segregation)
-- ACCOUNT: app_sales (password: CHANGE_ME_sales)
-- RUN VIA WORKBENCH: Connect as app_sales and run query below.
-- RUN VIA TERMINAL: docker exec -it sunra-mysql mysql -uapp_sales -p sunra_db
-- COMMAND: SELECT * FROM purchase;
-- EXPECTED:
--   ERROR 1142 (42000): SELECT command denied to user 'app_sales'@'%' for table 'purchase'
-- RATIONALE:
--   Sales staff must never see wholesale procurement costs, supplier agreements,
--   or inbound purchase orders.
-- ACTUAL: (paste here when executed against running MySQL)
-- ---------------------------------------------------------------------
SELECT * FROM purchase;


-- ---------------------------------------------------------------------
-- TEST 2: Customer Personal Data Protection (GDPR / PDPA Compliance)
-- ACCOUNT: app_stock (password: CHANGE_ME_stock)
-- RUN VIA WORKBENCH: Connect as app_stock and run query below.
-- RUN VIA TERMINAL: docker exec -it sunra-mysql mysql -uapp_stock -p sunra_db
-- COMMAND: SELECT nic, phone FROM customer;
-- EXPECTED:
--   ERROR 1142 (42000): SELECT command denied to user 'app_stock'@'%' for table 'customer'
-- RATIONALE:
--   Warehouse and stock personnel have no legitimate operational need to view
--   customer personally identifiable information (NIC, phone numbers, home addresses).
-- ACTUAL: (paste here when executed against running MySQL)
-- ---------------------------------------------------------------------
SELECT nic, phone FROM customer;


-- ---------------------------------------------------------------------
-- TEST 3A: Direct Inventory Modification Denial (Rule 4)
-- ACCOUNTS: app_sales and app_stock
-- RUN VIA WORKBENCH / DOCKER CLI: Execute under app_sales, then under app_stock.
-- COMMAND: UPDATE inventory SET quantity_on_hand = 999;
-- EXPECTED:
--   ERROR 1142 (42000): UPDATE command denied to user 'app_sales'@'%' for table 'inventory'
--   ERROR 1142 (42000): UPDATE command denied to user 'app_stock'@'%' for table 'inventory'
-- RATIONALE:
--   Team Rule 4: Only stored procedures change stock. Never UPDATE inventory
--   directly from any application account.
-- ACTUAL: (paste here when executed against running MySQL)
-- ---------------------------------------------------------------------
-- Run as app_sales:
UPDATE inventory SET quantity_on_hand = 999;

-- Run as app_stock:
UPDATE inventory SET quantity_on_hand = 999;


-- ---------------------------------------------------------------------
-- TEST 3B: Legitimate Stock Adjustment via Stored Procedure
-- ACCOUNTS: app_stock (and app_sales via sp_create_sale)
-- COMMAND: CALL sp_adjust_stock(1, -1, 'SALE', 'SALE', 1, 'Point of sale deduction');
-- EXPECTED:
--   Query OK (Allowed once Part 4 R__04_inventory.sql is merged and EXECUTE granted)
-- RATIONALE:
--   Stock modifications must be driven exclusively through validated business
--   logic encapsulated in sp_adjust_stock to guarantee stock_movement audit logging.
-- ACTUAL: (paste here when executed against running MySQL)
-- ---------------------------------------------------------------------
-- Run as app_stock:
-- CALL sp_adjust_stock(1, 10, 'PURCHASE', 'PURCHASE', 1, 'Inbound stock');


-- ---------------------------------------------------------------------
-- TEST 3C: Sales Procedure Execution (sp_create_sale)
-- ACCOUNT: app_sales (password: CHANGE_ME_sales)
-- RUN VIA WORKBENCH / DOCKER CLI as app_sales
-- COMMAND: CALL sp_create_sale(1, '[{"productId":1,"quantity":1,"unitPrice":485000}]');
-- EXPECTED:
--   - Before Part 7 R__07_sales.sql merge: ERROR 1370 / ERROR 1305 (routine does not exist / denied)
--   - After Part 7 merge & GRANT: Query OK (creates sale, deducts stock via DEFINER)
-- ACTUAL: (paste here when executed against running MySQL)
-- ---------------------------------------------------------------------
-- CALL sp_create_sale(1, '[{"productId":1,"quantity":1,"unitPrice":485000}]');


-- ---------------------------------------------------------------------
-- TEST 3D: Purchase Receipt Procedure Execution (sp_receive_purchase)
-- ACCOUNT: app_stock (password: CHANGE_ME_stock)
-- RUN VIA WORKBENCH / DOCKER CLI as app_stock
-- COMMAND: CALL sp_receive_purchase(1, 1, 5, 'Received showroom shipment');
-- EXPECTED:
--   - Before Part 5 R__05_purchase.sql merge: ERROR 1370 / ERROR 1305 (routine does not exist / denied)
--   - After Part 5 merge & GRANT: Query OK (updates purchase item, increases stock via DEFINER)
-- ACTUAL: (paste here when executed against running MySQL)
-- ---------------------------------------------------------------------
-- CALL sp_receive_purchase(1, 1, 5, 'Received showroom shipment');


-- ---------------------------------------------------------------------
-- TEST 4: Credential and Password Hash Protection
-- ACCOUNT: app_sales (and app_stock)
-- RUN VIA WORKBENCH / DOCKER CLI as app_sales
-- COMMAND: SELECT password_hash FROM app_user;
-- EXPECTED:
--   ERROR 1142 (42000): SELECT command denied to user 'app_sales'@'%' for table 'app_user'
-- RATIONALE:
--   Regular application tiers must never have direct table access to app_user,
--   preventing exfiltration or brute-forcing of BCrypt password hashes.
-- ACTUAL: (paste here when executed against running MySQL)
-- ---------------------------------------------------------------------
SELECT password_hash FROM app_user;


-- ---------------------------------------------------------------------
-- TEST 5: Public View Access without Exposing Password Hashes
-- ACCOUNT: app_admin (password: CHANGE_ME_admin)
-- RUN VIA WORKBENCH / DOCKER CLI as app_admin
-- COMMAND: SELECT * FROM v_user_public;
-- EXPECTED:
--   Query returns rows (id, username, full_name, email, phone, role_name, is_active, created_at, last_login_at)
--   Strictly NO password_hash column present in the result set.
-- RATIONALE:
--   Administrative user listings rely on the sanitized view v_user_public.
-- ACTUAL: (paste here when executed against running MySQL)
-- ---------------------------------------------------------------------
SELECT * FROM v_user_public;


-- ---------------------------------------------------------------------
-- TEST 6: Privilege Audit & Grant Verification
-- ACCOUNT: Run as root
-- RUN VIA DOCKER CLI: docker exec -it sunra-mysql mysql -uroot -proot sunra_db
-- COMMAND: SHOW GRANTS FOR '...';
-- EXPECTED:
--   - app_admin: GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON sunra_db.* TO `app_admin`@`%`
--   - app_sales: SELECT/INSERT/UPDATE on customer, sale, sale_item, payment, invoice, document; SELECT on product, inventory TO `app_sales`@`%`
--   - app_stock: SELECT/INSERT/UPDATE on product, product_category, supplier, purchase, purchase_item; SELECT on inventory, stock_movement TO `app_stock`@`%`
-- ACTUAL: (paste here when executed against running MySQL)
-- ---------------------------------------------------------------------
SHOW GRANTS FOR 'app_admin'@'%';
SHOW GRANTS FOR 'app_sales'@'%';
SHOW GRANTS FOR 'app_stock'@'%';
