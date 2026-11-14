# Contributing guide (read before coding)

## 1. Who owns what

Each part owns its own files. Don't edit another part's files. Ask the owner, or open a PR and tag them.

| Part | Area | Versioned migrations | Repeatable migration | Backend package | Frontend folder |
|---|---|---|---|---|---|
| 1 | Schema + integration lead | `V1_x__*.sql` | — | `common` | `src/layout`, `src/api`, `src/components`, `src/modules/system` |
| 2 | Auth + DB security | `V2_x__*.sql` | `R__02_security.sql` | `auth` | `src/modules/auth`, `src/modules/users` |
| 3 | Products + indexing | `V3_x__*.sql` | `R__03_product.sql` | `product` | `src/modules/products` |
| 4 | Inventory + stock movement | `V4_x__*.sql` | `R__04_inventory.sql` | `inventory` | `src/modules/inventory` |
| 5 | Suppliers + purchases | `V5_x__*.sql` | `R__05_purchase.sql` | `supplier` | `src/modules/purchases` |
| 6 | Customers | `V6_x__*.sql` | `R__06_customer.sql` | `customer` | `src/modules/customers` |
| 7 | Sales + transactions | `V7_x__*.sql` | `R__07_sales.sql` | `sales` | `src/modules/sales` |
| 8 | Invoices + documents | `V8_x__*.sql` | `R__08_invoice.sql` | `invoice` | `src/modules/invoices` |
| 9 | Reports + dashboard | `V9_x__*.sql` | `R__09_report.sql` | `report` | `src/modules/dashboard`, `src/modules/reports` |
| 10 | Audit + backup/recovery | `V10_x__*.sql` | `R__10_audit.sql` | `audit` | `src/modules/audit` |

Shared files (`App.jsx`, `modules/navigation.js`, `application.yml`, `pom.xml`, `package.json`): change only your own line, such as your route or your dependency, and mention it in your PR.

## 2. Database rules

All SQL lives in `database/migration/`. Flyway runs it automatically when the backend starts.

### Two kinds of migration file

**Versioned: `V<part>_<n>__<description>.sql`**, for tables, columns and indexes.
- Runs **once**, in version order. Example: `V3_1__product_indexes.sql`, then `V3_2__product_add_weight.sql`.
- **Never edit a V file after you've pushed it.** Other people's databases have already run it, so their backend will refuse to start (checksum mismatch). To change something, add the next file (`V3_2__...`).
- Use only your own part number, so two people never pick the same version.

**Repeatable: `R__<part>_<module>.sql`**, for stored procedures, functions, triggers, views and events.
- Runs again automatically whenever you change the file, after all V files.
- So every object must be dropped first. Template:

```sql
-- R__07_sales.sql  (Part 7)

DROP PROCEDURE IF EXISTS sp_create_sale;
DELIMITER $$
CREATE PROCEDURE sp_create_sale(
    IN p_customer_id INT UNSIGNED,
    IN p_items JSON
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    -- ...
    COMMIT;
END$$
DELIMITER ;

DROP VIEW IF EXISTS v_daily_sales;
CREATE VIEW v_daily_sales AS
SELECT ...;

DROP TRIGGER IF EXISTS trg_customer_after_update;
DELIMITER $$
CREATE TRIGGER trg_customer_after_update
AFTER UPDATE ON customer
FOR EACH ROW
BEGIN
    -- ...
END$$
DELIMITER ;
```

### Things that need root (not Flyway)

Flyway connects as `sunra_app`, which can't create MySQL users or run backups. Put those scripts in `database/scripts/` and run them by hand as root:

```bash
docker exec -i sunra-mysql mysql -uroot -proot sunra_db < database/scripts/02_create_db_users.sql
```

Examples: Part 2's `CREATE USER` / `GRANT` script, Part 10's backup and restore scripts.

### Project-wide rules

1. **Only stored procedures change stock.** Never `UPDATE inventory` from Java or another procedure. Call `sp_adjust_stock(...)` (Part 4).
2. **Business errors** inside procedures: `SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Clear message';`. The backend returns that message to the UI as HTTP 400.
3. **Who made the change:** at the start of every write transaction, call `dbSessionContext.setAppUser(userId)`. Triggers read `@app_user_id`.
4. **Hibernate never changes the schema.** `ddl-auto: validate` stays. If an entity doesn't match, fix the entity or add a migration.
5. **Naming:** tables `snake_case` singular; `pk_`, `fk_`, `uq_`, `chk_`, `idx_` for constraints and indexes; `sp_` procedures; `fn_` functions; `v_` views; `trg_<table>_<before|after>_<insert|update|delete>` triggers; `evt_` events.
6. Seed or test data for your part goes in your own V file (e.g. `V3_3__product_bulk_test_data.sql`), not in `V1_1`.

## 3. Git workflow

```bash
git checkout main
git pull
git checkout -b part3/product-crud        # part<N>/<short-description>

# ... work, then:
git add .
git commit -m "part3: add product CRUD endpoints"
git push -u origin part3/product-crud
```

Then open a Pull Request on GitHub into `main`. Part 1 reviews and merges.

Before opening a PR:
- `git pull origin main` into your branch and fix any conflicts.
- Reset your database (`docker compose down -v && docker compose up -d`) and start the backend, so you know all migrations run from scratch.
- The frontend still builds: `cd frontend && npm run build`.

Never push directly to `main`, and never commit `node_modules/`, `target/`, `.env` or database dumps.

## 4. Evidence for the report

Every part needs screenshots for its report section, so take them as you go:
- The SQL file in Cursor, and the object in MySQL (`SHOW CREATE PROCEDURE ...`, `SHOW TRIGGERS`).
- A test that proves it works, such as a CHECK or SIGNAL error firing, a rollback, `EXPLAIN` before and after an index, or access being denied.
- Save them in `docs/evidence/part<N>/`.
