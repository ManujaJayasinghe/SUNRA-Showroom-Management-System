-- =====================================================================
-- SUNRA Showroom Management System - Part 2 Database Security Script
-- File: database/scripts/02_create_mysql_users.sql
-- Purpose: Provision least-privilege MySQL accounts for app tiers
-- Target: MySQL 8.4 (InnoDB, utf8mb4)
-- Execution: Run manually as MySQL root user:
--   docker exec -i sunra-mysql mysql -uroot -proot sunra_db < database/scripts/02_create_mysql_users.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. User Creation with Placeholders
-- ---------------------------------------------------------------------
-- In production/demo, replace 'CHANGE_ME_*' with secure generated secrets.
-- These accounts connect from the local application backend tier.

CREATE USER IF NOT EXISTS 'app_admin'@'localhost' IDENTIFIED BY 'CHANGE_ME_admin';
CREATE USER IF NOT EXISTS 'app_sales'@'localhost' IDENTIFIED BY 'CHANGE_ME_sales';
CREATE USER IF NOT EXISTS 'app_stock'@'localhost' IDENTIFIED BY 'CHANGE_ME_stock';

-- ---------------------------------------------------------------------
-- 2. Administrator Account (app_admin)
-- ---------------------------------------------------------------------
-- RATIONALE & PRIVILEGE DECISION:
-- 1. app_admin represents the system administrator service account.
-- 2. Granted SELECT, INSERT, UPDATE, DELETE on all application tables (sunra_db.*).
-- 3. Granted EXECUTE on all stored routines in sunra_db to run administrative
--    procedures and system functions.
-- 4. WITHHELD: DDL privileges (CREATE, ALTER, DROP, TRUNCATE, INDEX) are strictly
--    withheld. Schema evolution is exclusively managed by Flyway migrations (sunra_app).
-- 5. WITHHELD: Administrative privileges (GRANT OPTION, SUPER, RELOAD, SHUTDOWN)
--    are withheld to prevent privilege escalation or rogue user creation.

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON sunra_db.* TO 'app_admin'@'localhost';

-- ---------------------------------------------------------------------
-- 2b. Part 2 Security Objects Explicit Grants (app_admin)
-- ---------------------------------------------------------------------
-- Explicit grants for Part 2 view and login procedures (covered also by
-- sunra_db.* above, highlighted here for audit and documentation):
GRANT SELECT ON sunra_db.v_user_public TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sunra_db.sp_get_login_user TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sunra_db.sp_record_login TO 'app_admin'@'localhost';

-- ---------------------------------------------------------------------
-- 3. Sales Staff Account (app_sales)
-- ---------------------------------------------------------------------
-- RATIONALE & PRIVILEGE DECISION:
-- 1. Least-privilege role for sales assistants and showroom point-of-sale.
-- 2. Operational DML (SELECT, INSERT, UPDATE):
--    - customer: Manage showroom customer profiles and contact details.
--    - sale, sale_item: Record point-of-sale customer orders.
--    - payment: Record customer cash/card/bank transfer transactions.
--    - invoice, document: Record and link customer billing documents.
-- 3. Read-Only (SELECT):
--    - product: View catalog, specifications, and retail prices.
--    - inventory: Check on-hand stock quantities before sales quotation.
-- 4. WITHHELD & RESTRICTIONS:
--    - NO UPDATE on inventory: Team Rule 4 strictly forbids direct inventory
--      modification. Stock deductions MUST execute via stored procedure sp_adjust_stock.
--    - NO DELETE on sale, sale_item, payment, invoice: Financial/transaction
--      records are permanent; cancellations must update the status enum, not delete.
--    - NO ACCESS to purchase, purchase_item, supplier: Sales staff have no
--      business need to inspect wholesale supplier costs, margin data, or supplier contracts.
--    - NO ACCESS to audit_log: Audit integrity cannot be viewed or manipulated by sales.
--    - NO ACCESS to app_user, role: Prevents credential snooping or account tampering.

GRANT SELECT, INSERT, UPDATE ON sunra_db.customer   TO 'app_sales'@'localhost';
GRANT SELECT, INSERT, UPDATE ON sunra_db.sale       TO 'app_sales'@'localhost';
GRANT SELECT, INSERT, UPDATE ON sunra_db.sale_item  TO 'app_sales'@'localhost';
GRANT SELECT, INSERT, UPDATE ON sunra_db.payment    TO 'app_sales'@'localhost';
GRANT SELECT, INSERT, UPDATE ON sunra_db.invoice    TO 'app_sales'@'localhost';
GRANT SELECT, INSERT, UPDATE ON sunra_db.document   TO 'app_sales'@'localhost';
GRANT SELECT                 ON sunra_db.product    TO 'app_sales'@'localhost';
GRANT SELECT                 ON sunra_db.inventory  TO 'app_sales'@'localhost';

-- ---------------------------------------------------------------------
-- 4. Stock Manager Account (app_stock)
-- ---------------------------------------------------------------------
-- RATIONALE & PRIVILEGE DECISION:
-- 1. Least-privilege role for warehouse managers and stock controllers.
-- 2. Operational DML (SELECT, INSERT, UPDATE):
--    - product, product_category: Maintain vehicle catalog, models, and specs.
--    - supplier: Manage showroom suppliers and vendor contact information.
--    - purchase, purchase_item: Create and record inbound stock purchase orders.
-- 3. Read-Only (SELECT):
--    - inventory: Inspect warehouse inventory levels and reorder thresholds.
--    - stock_movement: Review stock movement audit trail.
-- 4. WITHHELD & RESTRICTIONS:
--    - NO UPDATE on inventory: Team Rule 4 strictly forbids direct table update;
--      inbound stock receipt must be handled via sp_adjust_stock / sp_receive_purchase.
--    - NO ACCESS to customer: In compliance with data privacy principles (GDPR / PDPA),
--      warehouse personnel have no operational need for customer personal data (NIC, phone, address).
--    - NO ACCESS to app_user, role: Prevents user management or credential access.
--    - NO ACCESS to sale, sale_item, payment, invoice: Front-office retail sales
--      records are segregated from back-office inventory procurement.
--    - NO ACCESS to audit_log: Protected from unauthorized inspection or tampering.

GRANT SELECT, INSERT, UPDATE ON sunra_db.product          TO 'app_stock'@'localhost';
GRANT SELECT, INSERT, UPDATE ON sunra_db.product_category TO 'app_stock'@'localhost';
GRANT SELECT, INSERT, UPDATE ON sunra_db.supplier         TO 'app_stock'@'localhost';
GRANT SELECT, INSERT, UPDATE ON sunra_db.purchase         TO 'app_stock'@'localhost';
GRANT SELECT, INSERT, UPDATE ON sunra_db.purchase_item    TO 'app_stock'@'localhost';
GRANT SELECT                 ON sunra_db.inventory        TO 'app_stock'@'localhost';
GRANT SELECT                 ON sunra_db.stock_movement   TO 'app_stock'@'localhost';

-- ---------------------------------------------------------------------
-- 5. Stored Procedure Grants: Run again after Parts 4-8 are merged
-- ---------------------------------------------------------------------
-- Note: MySQL 8 throws ERROR 1305 if GRANT EXECUTE is executed on a routine
-- that does not yet exist. These stored procedures belong to peer parts:
--   - sp_adjust_stock       (Part 4 - Inventory)
--   - sp_receive_purchase   (Part 5 - Purchases)
--   - sp_search_customer    (Part 6 - Customers)
--   - sp_create_sale        (Part 7 - Sales)
--   - sp_generate_invoice   (Part 8 - Invoices)
--
-- Re-run this section as root once the respective R__ repeatable migrations
-- have been merged into database/migration/.
-- ---------------------------------------------------------------------

-- UNCOMMENT AND EXECUTE AFTER PARTS 4, 6, 7, 8 ARE MERGED:
-- GRANT EXECUTE ON PROCEDURE sunra_db.sp_create_sale        TO 'app_sales'@'localhost';
-- GRANT EXECUTE ON PROCEDURE sunra_db.sp_generate_invoice   TO 'app_sales'@'localhost';
-- GRANT EXECUTE ON PROCEDURE sunra_db.sp_search_customer    TO 'app_sales'@'localhost';
-- GRANT EXECUTE ON PROCEDURE sunra_db.sp_adjust_stock       TO 'app_sales'@'localhost';

-- UNCOMMENT AND EXECUTE AFTER PARTS 4, 5 ARE MERGED:
-- GRANT EXECUTE ON PROCEDURE sunra_db.sp_adjust_stock       TO 'app_stock'@'localhost';
-- GRANT EXECUTE ON PROCEDURE sunra_db.sp_receive_purchase   TO 'app_stock'@'localhost';

-- ---------------------------------------------------------------------
-- 6. Apply & Verify Privileges
-- ---------------------------------------------------------------------
FLUSH PRIVILEGES;

SHOW GRANTS FOR 'app_admin'@'localhost';
SHOW GRANTS FOR 'app_sales'@'localhost';
SHOW GRANTS FOR 'app_stock'@'localhost';

