# Part 2: Security & Least-Privilege Test Execution Guide

This guide describes how to execute the Part 2 security test scripts, verify database denial constraints, and capture required evidence screenshots for the CS304.3 ADBMS report.

---

## 1. Prerequisites

Ensure the MySQL database container is running and healthy:
```bash
docker compose up -d
docker ps
```
The container `sunra-mysql` will be running on `localhost:3306` with database `sunra_db`.

---

## 2. Step 1: Create Accounts & Initial Grants

Execute `database/scripts/02_create_mysql_users.sql` as `root`:

### Using Docker:
```bash
docker exec -i sunra-mysql mysql -uroot -proot sunra_db < database/scripts/02_create_mysql_users.sql
```

### Using Local MySQL CLI:
```powershell
Get-Content database/scripts/02_create_mysql_users.sql | & "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -proot sunra_db
```

---

## 3. Step 2: Run Security Denial & Allowed Tests

File: `database/scripts/02_security_tests.sql`

### Test 1: Purchase Table Denial (Sales Staff)
Sales staff must not see wholesale supplier purchase data.
```bash
docker exec -it sunra-mysql mysql -uapp_sales -pCHANGE_ME_sales sunra_db -e "SELECT * FROM purchase;"
```
* **Expected Output**:
  ```text
  ERROR 1142 (42000) at line 1: SELECT command denied to user 'app_sales'@'localhost' for table 'purchase'
  ```

### Test 2: Customer Privacy Denial (Stock Staff)
Stock staff must not access customer personal data (NIC, phone numbers).
```bash
docker exec -it sunra-mysql mysql -uapp_stock -pCHANGE_ME_stock sunra_db -e "SELECT nic, phone FROM customer;"
```
* **Expected Output**:
  ```text
  ERROR 1142 (42000) at line 1: SELECT command denied to user 'app_stock'@'localhost' for table 'customer'
  ```

### Test 3: Direct Inventory Modification Denial (Rule 4)
Neither sales nor stock managers may UPDATE inventory directly.
```bash
docker exec -it sunra-mysql mysql -uapp_sales -pCHANGE_ME_sales sunra_db -e "UPDATE inventory SET quantity_on_hand = 999;"
docker exec -it sunra-mysql mysql -uapp_stock -pCHANGE_ME_stock sunra_db -e "UPDATE inventory SET quantity_on_hand = 999;"
```
* **Expected Output**:
  ```text
  ERROR 1142 (42000) at line 1: UPDATE command denied to user 'app_sales'@'localhost' for table 'inventory'
  ERROR 1142 (42000) at line 1: UPDATE command denied to user 'app_stock'@'localhost' for table 'inventory'
  ```

### Test 4: Password Hash Protection (Sales & Stock)
Direct query on `app_user` is denied to prevent extracting password hashes.
```bash
docker exec -it sunra-mysql mysql -uapp_sales -pCHANGE_ME_sales sunra_db -e "SELECT password_hash FROM app_user;"
```
* **Expected Output**:
  ```text
  ERROR 1142 (42000) at line 1: SELECT command denied to user 'app_sales'@'localhost' for table 'app_user'
  ```

### Test 5: Sanitized User View (Admin Access)
`app_admin` accesses safe public attributes through `v_user_public` with no password hashes.
```bash
docker exec -it sunra-mysql mysql -uapp_admin -pCHANGE_ME_admin sunra_db -e "SELECT id, username, full_name, email, role_name, is_active FROM v_user_public;"
```
* **Expected Output**:
  Returns table rows with usernames and roles without any password hash column.

### Test 6: Audit All Account Grants
Run as root to verify least-privilege grants:
```bash
docker exec -it sunra-mysql mysql -uroot -proot sunra_db -e "SHOW GRANTS FOR 'app_admin'@'localhost'; SHOW GRANTS FOR 'app_sales'@'localhost'; SHOW GRANTS FOR 'app_stock'@'localhost';"
```

---

## 4. Step 3: Run Dynamic Revocation Demo

File: `database/scripts/02_revoke_demo.sql`

This test demonstrates immediate privilege revocation and restoration without restarting MySQL:

1. **Check initial access (allowed)**:
   ```bash
   docker exec -it sunra-mysql mysql -uapp_sales -pCHANGE_ME_sales sunra_db -e "SELECT customer_id, first_name FROM customer LIMIT 1;"
   ```
2. **Revoke SELECT on customer (as root)**:
   ```bash
   docker exec -it sunra-mysql mysql -uroot -proot sunra_db -e "REVOKE SELECT ON sunra_db.customer FROM 'app_sales'@'localhost'; FLUSH PRIVILEGES;"
   ```
3. **Check revoked access (denied)**:
   ```bash
   docker exec -it sunra-mysql mysql -uapp_sales -pCHANGE_ME_sales sunra_db -e "SELECT customer_id, first_name FROM customer LIMIT 1;"
   ```
   *Output*: `ERROR 1142 (42000): SELECT command denied to user 'app_sales'@'localhost' for table 'customer'`
4. **Restore SELECT on customer (as root)**:
   ```bash
   docker exec -it sunra-mysql mysql -uroot -proot sunra_db -e "GRANT SELECT ON sunra_db.customer TO 'app_sales'@'localhost'; FLUSH PRIVILEGES;"
   ```
5. **Check restored access (allowed)**:
   ```bash
   docker exec -it sunra-mysql mysql -uapp_sales -pCHANGE_ME_sales sunra_db -e "SELECT customer_id, first_name FROM customer LIMIT 1;"
   ```

---

## 5. Report Evidence Checklist (Screenshots)

Save all screenshots into `docs/evidence/part2/`:

| Screenshot File | Description | Terminal Command / Action |
| :--- | :--- | :--- |
| `01_show_grants.png` | Output of `SHOW GRANTS` for all 3 accounts | `SHOW GRANTS FOR 'app_admin'@'localhost' ...` |
| `02_denial_purchase.png` | `app_sales` denied access to `purchase` | `SELECT * FROM purchase;` |
| `03_denial_customer_pii.png` | `app_stock` denied access to `customer` | `SELECT nic, phone FROM customer;` |
| `04_denial_inventory_update.png` | Direct `UPDATE inventory` denied | `UPDATE inventory SET quantity_on_hand = 999;` |
| `05_denial_app_user_hash.png` | `app_sales` denied access to `app_user` | `SELECT password_hash FROM app_user;` |
| `06_view_v_user_public.png` | `app_admin` querying `v_user_public` safely | `SELECT * FROM v_user_public;` |
| `07_revoke_demo.png` | Dynamic `REVOKE` &rarr; `ERROR 1142` &rarr; `GRANT` recovery | Commands from `02_revoke_demo.sql` |
