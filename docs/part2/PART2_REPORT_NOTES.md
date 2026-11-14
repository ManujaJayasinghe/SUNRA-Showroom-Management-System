# University Project Report Notes
## Part 2: Authentication and Database Security
**Module:** CS304.3 Advanced Database Management Systems (ADBMS)  
**Project:** SUNRA Showroom Management System  
**Group:** Group AE  
**Author / Contributor:** [YOUR NAME]  
**Branch:** `part2/auth-security`  
**Target RDBMS:** MySQL 8.4 (InnoDB, `utf8mb4`)  
**Backend Framework:** Spring Boot 3.5.6 (Java 21, Spring Security 6)  
**Frontend Framework:** React 19 (Vite, React Router v7)  

---

## 1. Purpose and Design Decisions

Part 2 establishes an end-to-end, multi-layered security architecture for the SUNRA Showroom Management System, combining database-level privilege segregation, stored-routine encapsulation, cryptographic password storage, and stateless token-based authorization.

```
+-------------------------------------------------------------------------------+
|                             DEFENSE-IN-DEPTH LAYERS                           |
+-------------------------------------------------------------------------------+
| Layer 1: Client UI Routing     | ProtectedRoute, role-filtered navigation menu|
| Layer 2: API Gateway / Filter  | JwtAuthenticationFilter, stateless sessions  |
| Layer 3: Method Authorization  | Spring Security @PreAuthorize (ROLE_*)       |
| Layer 4: Audit & Session Hook  | dbSessionContext.setAppUser(userId)          |
| Layer 5: Data Abstraction View | v_user_public (password hash strictly hidden)|
| Layer 6: Stored Procedures     | sp_get_login_user, sp_record_login, sp_adjust|
| Layer 7: MySQL Account Grants  | app_admin, app_sales, app_stock (least priv) |
+-------------------------------------------------------------------------------+
```

### 1.1 Principle of Least Privilege (PoLP)
In conventional three-tier applications, the application backend connects to MySQL using a single high-privileged account (often `root` or a database owner with full DDL/DML access). If a SQL injection vulnerability exists or backend credentials leak, the entire database is compromised.

To mitigate this, Part 2 implements strict least-privilege segregation by defining distinct MySQL service accounts:
1. **`app_admin`**: Full operational DML on application data and EXECUTE on stored routines, but **no DDL** (cannot DROP, ALTER, or TRUNCATE tables) and **no administrative grants** (no `GRANT OPTION`, `SUPER`, `RELOAD`, or user administration). Schema evolution is exclusively preserved for automated Flyway migrations (`sunra_app`).
2. **`app_sales`**: Restriced strictly to front-office showroom operations (customers, sales, sale items, payments, invoices, documents) and read-only access to products and stock. **Denied access** to wholesale purchases, supplier contracts, audit logs, and user credentials.
3. **`app_stock`**: Restricted to warehouse and procurement operations (products, categories, suppliers, purchases, purchase items, stock movements). **Denied access** to customer personal data (PII) to comply with data protection regulations (GDPR / PDPA), and denied access to sales revenues, invoices, and user credentials.

### 1.2 EXECUTE on Procedures instead of Table UPDATE (Team Rule 4)
A critical business rule in the SUNRA Showroom Management System is: **"Only stored procedures change stock. Never UPDATE inventory directly."**
- Neither `app_sales` nor `app_stock` has the `UPDATE` privilege on the `inventory` table.
- Stock changes must execute through the stored procedure `sp_adjust_stock`.
- **Architectural Rationale**: Direct table updates can bypass business rules, create negative quantities, or fail to record audit trails. By encapsulating inventory mutations inside `sp_adjust_stock`, the database guarantees transactional integrity, validates non-negative stock invariants, and writes an immutable record to `stock_movement` within the same transaction.

### 1.3 Password Hash Concealment via Database View (`v_user_public`)
- The `app_user` table contains sensitive credentials (`password_hash`).
- General application queries, user listings, and frontend tables must never query `app_user` directly.
- The view `v_user_public` projects only safe columns: `id`, `username`, `full_name`, `email`, `phone`, `role_name` (via an `INNER JOIN` on `role`), `is_active`, `created_at`, and `last_login_at`.
- Even if an administrator or backend endpoint queries `SELECT * FROM v_user_public`, the `password_hash` column does not exist in the view's schema, eliminating accidental credential leakage in API responses or logs.

### 1.4 Cryptographic Standards: BCrypt Hashing
- User passwords are never stored in plaintext.
- BCrypt with an adaptive work factor (cost 10) is utilized for password hashing.
- BCrypt natively incorporates a 128-bit cryptographically secure random salt into each hash string, neutralizing rainbow table attacks and making offline brute-force attacks computationally prohibitive.

### 1.5 Stateless Authentication: JSON Web Tokens (JWT)
- **Token Format**: HMAC-SHA256 (HS256) signed JWTs.
- **Payload**: Subject (`username`), `userId`, granted authority (`ROLE_<NAME>`), `iat` (issued at), and `exp` (expiration set to 8 hours).
- **Stateless Session Management**: `SessionCreationPolicy.STATELESS` ensures the backend does not store HTTP session state in memory. Each incoming request is authenticated independently via the `Authorization: Bearer <token>` header, allowing seamless horizontal scaling and zero session affinity requirements.

### 1.6 Stored Procedure Execution Security: DEFINER vs. INVOKER
MySQL stored routines operate under one of two execution contexts specified by the `SQL SECURITY` characteristic:
- **`SQL SECURITY DEFINER` (Default)**: The routine executes with the privileges of the account that created/defined it (the migration user `sunra_app` or `root`). When `app_sales` or `app_stock` is granted `EXECUTE` on the procedure, the caller can execute the encapsulated logic (such as adjusting inventory balances or recording stock movements) **without possessing direct table-level privileges** on `inventory`. This enables strict adherence to **Team Rule 4** (*"Only stored procedures change stock. Never UPDATE inventory directly"*).
- **`SQL SECURITY INVOKER`**: The routine executes with the privileges of the user invoking it. Under `INVOKER`, calling accounts (`app_sales`, `app_stock`) would require direct `UPDATE` privileges on `inventory` and `INSERT` privileges on `stock_movement`; otherwise, calling the procedure fails with `ERROR 1142 (42000): UPDATE command denied`. Granting direct table privileges to callers would undermine least-privilege security and violate Rule 4.
- **Guidance for Peer Module Owners (Parts 4, 5, 7)**: The authors of `sp_adjust_stock`, `sp_receive_purchase`, and `sp_create_sale` must either explicitly specify `SQL SECURITY DEFINER` or omit the clause (as `DEFINER` is the MySQL default). They must **never** specify `SQL SECURITY INVOKER`.

---

## 2. Account and Privilege Matrix

The following matrix represents the **real grants** implemented and verified in `database/scripts/02_create_mysql_users.sql`:

| Database Object | Object Type | `app_admin` | `app_sales` | `app_stock` | Architectural & Security Rationale |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`customer`** | Table | `SELECT, INSERT, UPDATE, DELETE` | `SELECT, INSERT, UPDATE` | **DENIED (No Access)** | Sales creates/updates customer profiles. Stock denied access to protect Customer PII (NIC, phone, address). |
| **`sale`** | Table | `SELECT, INSERT, UPDATE, DELETE` | `SELECT, INSERT, UPDATE` | **DENIED (No Access)** | Sales creates orders; DELETE denied to maintain financial permanence. Stock segregated from retail sales. |
| **`sale_item`** | Table | `SELECT, INSERT, UPDATE, DELETE` | `SELECT, INSERT, UPDATE` | **DENIED (No Access)** | Order line items tied to customer sales. Stock staff denied. |
| **`payment`** | Table | `SELECT, INSERT, UPDATE, DELETE` | `SELECT, INSERT, UPDATE` | **DENIED (No Access)** | Cash/card receipt recording. Stock personnel have no cashier privileges. |
| **`invoice`** | Table | `SELECT, INSERT, UPDATE, DELETE` | `SELECT, INSERT, UPDATE` | **DENIED (No Access)** | Digital customer invoices. Stock staff cannot view retail billing. |
| **`document`** | Table | `SELECT, INSERT, UPDATE, DELETE` | `SELECT, INSERT, UPDATE` | **DENIED (No Access)** | Receipts and contracts linked to customers and sales. |
| **`product`** | Table | `SELECT, INSERT, UPDATE, DELETE` | `SELECT` (Read-Only) | `SELECT, INSERT, UPDATE` | Sales inspects vehicle specifications and pricing. Stock updates inventory catalog and vehicle models. |
| **`product_category`**| Table | `SELECT, INSERT, UPDATE, DELETE` | **DENIED (No Access)** | `SELECT, INSERT, UPDATE` | Managed exclusively by warehouse and stock management. |
| **`supplier`** | Table | `SELECT, INSERT, UPDATE, DELETE` | **DENIED (No Access)** | `SELECT, INSERT, UPDATE` | Wholesale vendor contacts. Sales denied to protect supplier relationships. |
| **`purchase`** | Table | `SELECT, INSERT, UPDATE, DELETE` | **DENIED (No Access)** | `SELECT, INSERT, UPDATE` | Inbound procurement orders. Sales denied to prevent wholesale cost/margin disclosure. |
| **`purchase_item`**| Table | `SELECT, INSERT, UPDATE, DELETE` | **DENIED (No Access)** | `SELECT, INSERT, UPDATE` | Procurement item breakdown. Sales denied. |
| **`inventory`** | Table | `SELECT, INSERT, UPDATE, DELETE` | `SELECT` (Read-Only) | `SELECT` (Read-Only) | **Rule 4: NO direct UPDATE for sales or stock.** Changes must execute via `sp_adjust_stock`. |
| **`stock_movement`** | Table | `SELECT, INSERT, UPDATE, DELETE` | **DENIED (No Access)** | `SELECT` (Read-Only) | Warehouse reviews stock movement audit trail. Sales denied. |
| **`audit_log`** | Table | `SELECT, INSERT, UPDATE, DELETE` | **DENIED (No Access)** | **DENIED (No Access)** | Tamper-proof audit logs; regular operational accounts cannot view or manipulate logs. |
| **`app_user`** | Table | `SELECT, INSERT, UPDATE, DELETE` | **DENIED (No Access)** | **DENIED (No Access)** | Prevents unauthorized credential dumping or account escalation. |
| **`role`** | Table | `SELECT, INSERT, UPDATE, DELETE` | **DENIED (No Access)** | **DENIED (No Access)** | RBAC role definitions protected from modification. |
| **`v_user_public`** | View | `SELECT` | **DENIED (No Access)** | **DENIED (No Access)** | Sanitized view omitting `password_hash` for admin user management. |
| **`sp_get_login_user`**| Procedure | `EXECUTE` | **DENIED (No Access)** | **DENIED (No Access)** | Authentication credential loader called only during authentication. |
| **`sp_record_login`** | Procedure | `EXECUTE` | **DENIED (No Access)** | **DENIED (No Access)** | Records login successes, failures, and locks accounts. |
| **`sp_adjust_stock`** | Procedure | `EXECUTE` | `EXECUTE` *(Post-merge)* | `EXECUTE` *(Post-merge)* | Sole authorized mechanism to adjust stock on-hand and write `stock_movement`. |
| **`sp_create_sale`** | Procedure | `EXECUTE` | `EXECUTE` *(Post-merge)* | **DENIED (No Access)** | Atomic sale creation and stock deduction procedure. |
| **`sp_generate_invoice`**| Procedure | `EXECUTE` | `EXECUTE` *(Post-merge)* | **DENIED (No Access)** | Generates digital invoice numbers and totals. |
| **`sp_search_customer`**| Procedure | `EXECUTE` | `EXECUTE` *(Post-merge)* | **DENIED (No Access)** | Customer search procedure for sales showroom workflows. |
| **`sp_receive_purchase`**| Procedure| `EXECUTE` | **DENIED (No Access)** | `EXECUTE` *(Post-merge)* | Inbound warehouse shipment receiving procedure. |

---

## 3. Authentication & Authorization Flow

### 3.1 Numbered Execution Description
1. **Login Submission**: The user submits credentials (`username`, `password`) via the React login form to `POST /api/auth/login`.
2. **Credential Loading via Stored Procedure**: The Spring Boot `AuthService` invokes stored procedure `sp_get_login_user(p_username)`. The procedure queries `app_user` and `role`, returning: `user_id`, `username`, `password_hash`, `role_name`, `is_active`, `failed_attempts`, and `locked_until`.
3. **Lockout & Activation Verification**:
   - If `locked_until` is in the future, the backend immediately aborts and throws `AccountLockedException` (HTTP 423 Locked).
   - If `is_active = FALSE`, the backend throws `AccountDeactivatedException` (HTTP 403 Forbidden).
4. **BCrypt Verification**:
   - `BCryptPasswordEncoder.matches(rawPassword, storedHash)` evaluates the password.
5. **Login Outcome Recording via `sp_record_login`**:
   - **On Failure**: `sp_record_login(user_id, FALSE)` increments `failed_attempts`. If failed attempts reach 5, it automatically sets `locked_until = NOW() + INTERVAL 15 MINUTE`. The API returns a generic `"Invalid username or password"` (HTTP 401 Unauthorized) to prevent account enumeration.
   - **On Success**: `sp_record_login(user_id, TRUE)` resets `failed_attempts = 0` and updates `last_login_at = NOW()`.
6. **JWT Generation**:
   - The backend signs a JWT token using HS256 containing `sub` (username), `userId`, `role` (e.g. `ROLE_ADMIN`), issued timestamp, and 8-hour expiry.
7. **Client Token Storage**:
   - React stores the JWT in `localStorage` and provides it to the React `AuthContext`.
8. **Request Interception**:
   - On every subsequent HTTP request, the Axios interceptor injects the header `Authorization: Bearer <token>`.
9. **Spring Security Filter Validation**:
   - `JwtAuthenticationFilter` intercepts the request, validates the signature using `JwtTokenProvider`, parses claims, constructs a `UserPrincipal`, and populates the `SecurityContextHolder`.
10. **Role & Method Security Check**:
    - Spring Security evaluates `@PreAuthorize("hasRole('ADMIN')")` or `@PreAuthorize("hasAnyRole('ADMIN', 'SALES')")` before executing the controller method.
11. **Database Session Context Hook (Team Rule 5)**:
    - At the start of write transactions, the backend invokes `dbSessionContext.setAppUser(currentUserId)` to ensure database audit triggers record the real authenticated user.

### 3.2 Authentication Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor User as User / Browser
    participant React as React Frontend (AuthContext)
    participant AuthCtrl as Spring Boot AuthController
    participant AuthSvc as AuthService
    participant MySQL as MySQL Database (sunra_db)

    User->>React: Enter username & password
    React->>AuthCtrl: POST /api/auth/login {username, password}
    AuthCtrl->>AuthSvc: login(username, password)
    
    AuthSvc->>MySQL: CALL sp_get_login_user(p_username)
    MySQL-->>AuthSvc: id, username, password_hash, role_name, is_active, failed_attempts, locked_until
    
    alt Account is Locked (locked_until > NOW())
        AuthSvc-->>AuthCtrl: Throw AccountLockedException
        AuthCtrl-->>React: HTTP 423 Locked ("Account temporarily locked")
    else Account is Inactive (is_active == false)
        AuthSvc-->>AuthCtrl: Throw AccountDeactivatedException
        AuthCtrl-->>React: HTTP 403 Forbidden ("Account has been deactivated")
    else Invalid Password
        AuthSvc->>MySQL: CALL sp_record_login(user_id, FALSE)
        Note over MySQL: Increment failed_attempts;<br/>Lock 15m if attempts >= 5
        AuthSvc-->>AuthCtrl: Throw BadCredentialsException
        AuthCtrl-->>React: HTTP 401 Unauthorized ("Invalid username or password")
    else Valid Password
        AuthSvc->>MySQL: CALL sp_record_login(user_id, TRUE)
        Note over MySQL: Reset failed_attempts = 0;<br/>Set last_login_at = NOW()
        AuthSvc->>AuthSvc: Generate JWT (HS256, 8 hours, ROLE_*)
        AuthSvc-->>AuthCtrl: AuthResponseDto (token, user details, role)
        AuthCtrl-->>React: HTTP 200 OK {token, user: {id, username, role}}
        React->>React: Store token in localStorage; Update AuthContext
        React-->>User: Redirect to Role-specific Dashboard
    end
```

---

## 4. Role-to-Endpoint Matrix

| Module | Endpoint Route | HTTP Method | Authorized Roles | Access Control Rationale & Policy |
| :--- | :--- | :--- | :--- | :--- |
| **Auth** | `/api/auth/login` | `POST` | `permitAll()` (Public) | Authenticates credentials and issues signed JWT. |
| **Auth** | `/api/auth/me` | `GET` | Authenticated (Any Role) | Returns current authenticated user profile and role. |
| **Auth** | `/api/auth/change-password` | `POST` | Authenticated (Any Role) | Self-service password change; enforces 8+ character minimum. |
| **System** | `/api/health` | `GET` | `permitAll()` (Public) | Liveness probe for MySQL connection, table count, and Flyway status. |
| **Users** | `/api/users` | `GET` | `ADMIN` only | Lists users from `v_user_public` with search/role filters. |
| **Users** | `/api/users/{id}` | `GET` | `ADMIN` only | Retrieves single user details (excluding password hash). |
| **Users** | `/api/users` | `POST` | `ADMIN` only | Creates new user; hashes initial password with BCrypt; sets app user context. |
| **Users** | `/api/users/{id}` | `PUT` | `ADMIN` only | Updates user full name, email, and phone. |
| **Users** | `/api/users/{id}/role` | `PUT` | `ADMIN` only | Modifies user role; self-demotion blocked. |
| **Users** | `/api/users/{id}/status` | `PATCH` | `ADMIN` only | Soft activates/deactivates user; self-deactivation blocked. |
| **Users** | `/api/users/{id}/reset-password`| `POST` | `ADMIN` only | Admin resets user password (minimum 8 chars). |
| **Customers** | `/api/customers/**` | `GET, POST, PUT` | `ADMIN`, `SALES` | Customer profile management; stock staff blocked to prevent PII exposure. |
| **Products** | `/api/products/**` | `GET` | `ADMIN`, `SALES`, `STOCK` | Read-only catalog view for showroom sales and warehouse search. |
| **Products** | `/api/products/**` | `POST, PUT, DELETE`| `ADMIN`, `STOCK` | Vehicle catalog modifications; sales staff denied. |
| **Inventory** | `/api/inventory/**` | `GET` | `ADMIN`, `SALES`, `STOCK` | On-hand quantity inspection before quotation or reorder. |
| **Inventory** | `/api/inventory/**` | `POST` (`sp_adjust_stock`)| `ADMIN`, `SALES`, `STOCK` | **Rule 4**: Invokes stored procedure `sp_adjust_stock`; direct table UPDATE denied. |
| **Suppliers** | `/api/suppliers/**` | `GET, POST, PUT` | `ADMIN`, `STOCK` | Supplier agreements and vendor data; sales staff denied. |
| **Purchases** | `/api/purchases/**` | `GET, POST, PUT` | `ADMIN`, `STOCK` | Procurement orders; sales staff denied to prevent cost/margin inspection. |
| **Sales** | `/api/sales/**` | `GET, POST` | `ADMIN`, `SALES` | Point-of-sale checkout (calls `sp_create_sale`); stock staff denied. |
| **Invoices** | `/api/invoices/**` | `GET, POST` | `ADMIN`, `SALES` | Invoice generation and PDF download; stock staff denied. |
| **Reports** | `/api/reports/**` | `GET` | `ADMIN` only | Business intelligence, revenue dashboards, and financial summaries. |
| **Audit Log** | `/api/audit/**` | `GET` | `ADMIN` only | Immutable audit log inspection across system changes. |

---

## 5. Security Denial Tests & Verification

These tests correspond to the validation suite in `database/scripts/02_security_tests.sql` and `database/scripts/02_revoke_demo.sql`.

| Test ID | Test Name & Target | MySQL Account | Executed Command | Expected Result | Evidence Placeholder |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **SEC-01** | Wholesale Purchase Isolation | `app_sales` | `SELECT * FROM purchase;` | `ERROR 1142 (42000): SELECT command denied to user 'app_sales'@'%' for table 'purchase'` | `[screenshot here: sec01_purchase_denied.png]` |
| **SEC-02** | Customer PII Protection | `app_stock` | `SELECT nic, phone FROM customer;` | `ERROR 1142 (42000): SELECT command denied to user 'app_stock'@'%' for table 'customer'` | `[screenshot here: sec02_customer_pii_denied.png]` |
| **SEC-03A**| Direct Inventory UPDATE Denial | `app_sales` | `UPDATE inventory SET quantity_on_hand = 999;` | `ERROR 1142 (42000): UPDATE command denied to user 'app_sales'@'%' for table 'inventory'` | `[screenshot here: sec03a_sales_inventory_update_denied.png]` |
| **SEC-03B**| Direct Inventory UPDATE Denial | `app_stock` | `UPDATE inventory SET quantity_on_hand = 999;` | `ERROR 1142 (42000): UPDATE command denied to user 'app_stock'@'%' for table 'inventory'` | `[screenshot here: sec03b_stock_inventory_update_denied.png]` |
| **SEC-04** | Credential Table Protection | `app_sales` | `SELECT password_hash FROM app_user;` | `ERROR 1142 (42000): SELECT command denied to user 'app_sales'@'%' for table 'app_user'` | `[screenshot here: sec04_app_user_denied.png]` |
| **SEC-05** | Public View Hash Concealment | `app_admin` | `SELECT * FROM v_user_public;` | Query succeeds; columns returned omit `password_hash`. | `[screenshot here: sec05_v_user_public_success.png]` |
| **SEC-06** | Privilege Grant Audit | `root` | `SHOW GRANTS FOR 'app_sales'@'%';` | Displays only explicit least-privilege table grants. | `[screenshot here: sec06_show_grants_sales.png]` |
| **RVK-01** | Baseline Access Before Revocation | `app_sales` | `SELECT customer_id FROM customer LIMIT 1;` | Query OK (Customer records returned). | `[screenshot here: rvk01_baseline_allowed.png]` |
| **RVK-02** | Privilege Revocation Test | `app_sales` | `REVOKE SELECT ...; SELECT * FROM customer;` | `ERROR 1142 (42000): SELECT command denied to user 'app_sales'@'%' for table 'customer'` | `[screenshot here: rvk02_revocation_denied.png]` |
| **RVK-03** | Privilege Restoration Test | `app_sales` | `GRANT SELECT ...; SELECT * FROM customer;` | Query OK (Access restored). | `[screenshot here: rvk03_restoration_allowed.png]` |

---

## 6. How to Run and Verify the System

### Step 1: Start MySQL Database
Launch the MySQL container via Docker Compose:
```bash
docker compose up -d
```

### Step 2: Apply Flyway Database Migrations
Run the backend or execute Maven Flyway plugin to apply migrations (`V1_0`, `V1_1`, `V2_1`, `V2_2`, and `R__02_security.sql`):
```bash
cd backend
./mvnw.cmd compile
```
*Note: Spring Boot automatically executes pending Flyway migrations on application startup.*

### Step 3: Provision Least-Privilege MySQL Users (Run Once as Root)
Execute the user creation script as the MySQL root user:
```bash
docker exec -i sunra-mysql mysql -uroot -proot sunra_db < database/scripts/02_create_mysql_users.sql
```

### Step 4: Configure Environment Variables
Set the environment variables before starting the backend (or configure them in your local IDE run configuration):
```bash
# Windows PowerShell
$env:JWT_SECRET="YourVeryLongSuperSecretKeyThatMeetsHS256SecurityRequirementOf256BitsMinimum"
$env:SPRING_DATASOURCE_URL="jdbc:mysql://localhost:3306/sunra_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"
$env:SPRING_DATASOURCE_USERNAME="sunra_app"
$env:SPRING_DATASOURCE_PASSWORD="sunra_pass"
```

### Step 5: Start the Backend Service
Run Spring Boot:
```bash
cd backend
./mvnw.cmd spring-boot:run
```
Run backend security tests to confirm green status:
```bash
cd backend
./mvnw.cmd test
```

### Step 6: Start the Frontend Application
```bash
cd frontend
npm install
npm run dev
```
Open `http://localhost:5173` in your browser.

### 6.1 Demo Accounts for Evaluation
The seed migration (`database/migration/V2_2__seed_roles_users.sql`) provisions three demo personas with predefined roles:

| Username | System Role | Assigned Permissions & Intended Workflow |
| :--- | :--- | :--- |
| **`admin`** | `ADMIN` | Full system administration, user management (`/users`), system status, reports, audit logs. |
| **`sales1`** | `SALES` | Showroom sales assistant; access to `/customers`, `/sales`, `/invoices`, and `/products` (read-only). |
| **`stock1`** | `STOCK` | Warehouse inventory manager; access to `/products`, `/inventory`, and `/purchases`. |

*(Note: Real passwords are never committed to version control. Passwords configured during seeding follow the documented local demonstration credentials).*

---

## 7. Limitations and Future Improvements

While Part 2 delivers robust database security and application authorization, the following enhancements represent viable next steps for production hardening:

1. **JWT Invalidation & Refresh Tokens**:
   - *Current Limitation*: JWTs are stateless and remain cryptographically valid until the 8-hour expiry elapses, meaning immediate token invalidation upon administrative user deactivation requires waiting for expiration.
   - *Improvement*: Implement dual-token authentication (short-lived 15-minute access tokens paired with revocable refresh tokens persisted in an in-memory Redis cache).
2. **Multi-Factor Authentication (MFA / 2FA)**:
   - *Current Limitation*: Authentication relies exclusively on single-factor username and password.
   - *Improvement*: Introduce Time-Based One-Time Password (TOTP) support via Google Authenticator or SMS verification for administrative and financial operations.
3. **Password Policy & Complexity Rules**:
   - *Current Limitation*: Password validation currently requires a minimum length of 8 characters.
   - *Improvement*: Enforce mandatory complexity policies (uppercase, lowercase, numerals, special characters), password expiration intervals, and history checks preventing reuse of recent passwords.
4. **API Rate Limiting & Brute-Force Throttling**:
   - *Current Limitation*: Account lockout occurs in the database after 5 failed attempts per username, but an attacker could attempt high-volume requests across multiple usernames (distributed credential stuffing).
   - *Improvement*: Implement IP-level rate limiting using Bucket4j / Spring Cloud Gateway to throttle brute-force attacks at the network boundary.
5. **Row-Level Multi-Branch Isolation (RLS)**:
   - *Current Limitation*: Sales personnel have access to all customer records across the entire business.
   - *Improvement*: If SUNRA expands to multiple geographical showrooms, implement row-level filtering based on the user's assigned branch ID (`branch_id`).
