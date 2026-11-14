# Role-Endpoint Security Matrix

This document defines the Role-Based Access Control (RBAC) authorization matrix across all backend endpoints in the SUNRA Showroom Management System (CS304.3 Group AE).

---

## 1. System Roles

| Role Code | Authority Prefix | Target Persona | Description |
| :--- | :--- | :--- | :--- |
| **`ADMIN`** | `ROLE_ADMIN` | System Administrator / Owner | Full administrative oversight, user management, financial reports, and audit logs. |
| **`SALES`** | `ROLE_SALES` | Sales Assistant / Cashier | Showroom sales operations, customer profiles, point-of-sale quotations, invoices. |
| **`STOCK`** | `ROLE_STOCK` | Stock Manager / Warehouse | Inbound inventory procurement, stock adjustments, supplier management, vehicle catalog. |

---

## 2. Global Endpoint Authorization Matrix

| Module | Endpoint Pattern | HTTP Methods | Authorized Roles | Architectural Rationale & Controls |
| :--- | :--- | :--- | :--- | :--- |
| **Auth** | `/api/auth/login` | `POST` | `permitAll()` (Public) | Authenticates credentials and issues JWT token. |
| **Auth** | `/api/auth/me` | `GET` | Authenticated (Any role) | Returns profile of the logged-in user. |
| **Auth** | `/api/auth/change-password` | `POST` | Authenticated (Any role) | Allows current user to update their own password (min 8 chars). |
| **System** | `/api/health` | `GET` | `permitAll()` (Public) | Spring Boot & database connectivity health probe. |
| **Users** | `/api/users/**` | `GET, POST, PUT, PATCH` | `ADMIN` only | User management (create, update, status toggle, reset password, change role). |
| **Customers** | `/api/customers/**` | `GET, POST, PUT` | `ADMIN`, `SALES` | Customer profile management. Stock staff denied to prevent PII exposure. |
| **Products** | `/api/products/**` | `GET` (Read) | `ADMIN`, `SALES`, `STOCK` | Product catalog viewing for showroom sales and warehouse lookup. |
| **Products** | `/api/products/**` | `POST, PUT, DELETE` (Write) | `ADMIN`, `STOCK` | Catalog management, vehicle specifications, pricing adjustments. |
| **Inventory** | `/api/inventory/**` | `GET` | `ADMIN`, `STOCK`, `SALES` | Inventory check before sales quotation; stock inspection. |
| **Inventory** | `/api/inventory/**` | `POST` (Calls `sp_adjust_stock`) | `ADMIN`, `STOCK`, `SALES` | **Rule 4**: No direct table update; modifications must invoke `sp_adjust_stock`. |
| **Suppliers** | `/api/suppliers/**` | `GET, POST, PUT` | `ADMIN`, `STOCK` | Supplier contracts and vendor management. Sales staff denied. |
| **Purchases** | `/api/purchases/**` | `GET, POST, PUT` | `ADMIN`, `STOCK` | Inbound purchase orders and procurement receipts. Sales staff denied. |
| **Sales** | `/api/sales/**` | `GET, POST` | `ADMIN`, `SALES` | Point-of-sale order creation (calls `sp_create_sale`). Stock staff denied. |
| **Invoices** | `/api/invoices/**` | `GET, POST` | `ADMIN`, `SALES` | Digital invoice generation (calls `sp_generate_invoice`) and PDF download. |
| **Reports** | `/api/reports/**` | `GET` | `ADMIN` only | Sensitive business intelligence, revenue summaries, and margin analytics. |
| **Audit Log** | `/api/audit/**` | `GET` | `ADMIN` only | System change logs and regulatory audit trail inspection. |

---

## 3. Enforcement Layers

1. **Spring Security URL Authorization**:
   Configured in `SecurityConfig.java` with stateless JWT sessions.
2. **Spring Method Security**:
   Annotated with `@PreAuthorize("hasRole('ADMIN')")`, `@PreAuthorize("hasAnyRole('ADMIN', 'SALES')")` at the controller and service boundaries.
3. **Database Privilege Segregation**:
   Backed by least-privilege MySQL accounts (`app_admin`, `app_sales`, `app_stock`) configured in `database/scripts/02_create_mysql_users.sql`.
