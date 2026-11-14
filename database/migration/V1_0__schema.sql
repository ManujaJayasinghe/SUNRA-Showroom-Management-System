-- =====================================================================
-- SUNRA Showroom Management System - Core schema (Part 1)
-- CS304.3 Advanced DBMS - Group AE
-- Owner: Part 1 (schema architect). Do NOT edit after it has been
-- pushed: add a new versioned migration instead (see CONTRIBUTING.md).
-- Normalized to 3NF. Engine InnoDB, charset utf8mb4.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Part 2: users and roles
-- ---------------------------------------------------------------------
CREATE TABLE role (
    role_id      TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    role_name    VARCHAR(30)      NOT NULL,
    description  VARCHAR(255)     NULL,
    CONSTRAINT pk_role PRIMARY KEY (role_id),
    CONSTRAINT uq_role_name UNIQUE (role_name)
) ENGINE = InnoDB;

-- Named app_user because USER is a MySQL keyword
CREATE TABLE app_user (
    user_id        INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    role_id        TINYINT UNSIGNED NOT NULL,
    username       VARCHAR(50)      NOT NULL,
    password_hash  CHAR(60)         NOT NULL,          -- BCrypt
    full_name      VARCHAR(100)     NOT NULL,
    email          VARCHAR(100)     NOT NULL,
    phone          VARCHAR(15)      NULL,
    is_active      BOOLEAN          NOT NULL DEFAULT TRUE,
    last_login_at  DATETIME         NULL,
    created_at     DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_app_user PRIMARY KEY (user_id),
    CONSTRAINT uq_app_user_username UNIQUE (username),
    CONSTRAINT uq_app_user_email UNIQUE (email),
    CONSTRAINT fk_app_user_role FOREIGN KEY (role_id) REFERENCES role (role_id),
    CONSTRAINT chk_app_user_username CHECK (CHAR_LENGTH(username) >= 4)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Part 6: customers
-- ---------------------------------------------------------------------
CREATE TABLE customer (
    customer_id  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    nic          VARCHAR(12)   NOT NULL,
    first_name   VARCHAR(50)   NOT NULL,
    last_name    VARCHAR(50)   NOT NULL,
    phone        VARCHAR(10)   NOT NULL,
    email        VARCHAR(100)  NULL,
    address      VARCHAR(255)  NULL,
    city         VARCHAR(50)   NULL,
    is_active    BOOLEAN       NOT NULL DEFAULT TRUE,  -- soft delete
    created_at   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_customer PRIMARY KEY (customer_id),
    CONSTRAINT uq_customer_nic UNIQUE (nic),
    CONSTRAINT uq_customer_phone UNIQUE (phone),
    -- Old NIC: 9 digits + V/X. New NIC: 12 digits.
    CONSTRAINT chk_customer_nic CHECK (REGEXP_LIKE(nic, '^([0-9]{9}[VvXx]|[0-9]{12})$')),
    -- Sri Lankan mobile/landline: 10 digits starting with 0
    CONSTRAINT chk_customer_phone CHECK (REGEXP_LIKE(phone, '^0[0-9]{9}$'))
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Part 3: product catalogue
-- ---------------------------------------------------------------------
CREATE TABLE product_category (
    category_id  SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name         VARCHAR(50)       NOT NULL,
    description  VARCHAR(255)      NULL,
    CONSTRAINT pk_product_category PRIMARY KEY (category_id),
    CONSTRAINT uq_product_category_name UNIQUE (name)
) ENGINE = InnoDB;

CREATE TABLE product (
    product_id        INT UNSIGNED      NOT NULL AUTO_INCREMENT,
    category_id       SMALLINT UNSIGNED NOT NULL,
    model_code        VARCHAR(30)       NOT NULL,
    name              VARCHAR(100)      NOT NULL,
    description       TEXT              NULL,
    colour            VARCHAR(30)       NULL,
    motor_power_w     SMALLINT UNSIGNED NULL,
    battery_type      VARCHAR(30)       NULL,
    battery_capacity  VARCHAR(30)       NULL,          -- e.g. 72V 32Ah
    range_km          SMALLINT UNSIGNED NULL,
    max_speed_kmh     SMALLINT UNSIGNED NULL,
    unit_price        DECIMAL(12, 2)    NOT NULL,       -- LKR
    warranty_months   TINYINT UNSIGNED  NOT NULL DEFAULT 12,
    is_active         BOOLEAN           NOT NULL DEFAULT TRUE,
    created_at        DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_product PRIMARY KEY (product_id),
    CONSTRAINT uq_product_model_code UNIQUE (model_code),
    CONSTRAINT fk_product_category FOREIGN KEY (category_id) REFERENCES product_category (category_id),
    CONSTRAINT chk_product_price CHECK (unit_price > 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Part 4: inventory and stock movement
-- ---------------------------------------------------------------------
CREATE TABLE inventory (
    inventory_id       INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    product_id         INT UNSIGNED  NOT NULL,
    quantity_on_hand   INT           NOT NULL DEFAULT 0,
    reorder_level      INT           NOT NULL DEFAULT 2,
    updated_at         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_inventory PRIMARY KEY (inventory_id),
    CONSTRAINT uq_inventory_product UNIQUE (product_id),   -- one stock row per product (single showroom)
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) REFERENCES product (product_id),
    CONSTRAINT chk_inventory_qty CHECK (quantity_on_hand >= 0),
    CONSTRAINT chk_inventory_reorder CHECK (reorder_level >= 0)
) ENGINE = InnoDB;

CREATE TABLE stock_movement (
    movement_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    product_id       INT UNSIGNED    NOT NULL,
    movement_type    ENUM('PURCHASE', 'SALE', 'ADJUSTMENT', 'RETURN', 'INITIAL') NOT NULL,
    quantity_change  INT             NOT NULL,
    quantity_after   INT             NOT NULL,
    reference_type   VARCHAR(20)     NULL,            -- e.g. SALE, PURCHASE
    reference_id     INT UNSIGNED    NULL,
    note             VARCHAR(255)    NULL,
    created_by       INT UNSIGNED    NULL,
    created_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_stock_movement PRIMARY KEY (movement_id),
    CONSTRAINT fk_stock_movement_product FOREIGN KEY (product_id) REFERENCES product (product_id),
    CONSTRAINT fk_stock_movement_user FOREIGN KEY (created_by) REFERENCES app_user (user_id),
    CONSTRAINT chk_stock_movement_change CHECK (quantity_change <> 0),
    CONSTRAINT chk_stock_movement_after CHECK (quantity_after >= 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Part 5: suppliers and purchases
-- ---------------------------------------------------------------------
CREATE TABLE supplier (
    supplier_id     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    name            VARCHAR(100)  NOT NULL,
    contact_person  VARCHAR(100)  NULL,
    phone           VARCHAR(15)   NOT NULL,
    email           VARCHAR(100)  NULL,
    address         VARCHAR(255)  NULL,
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_supplier PRIMARY KEY (supplier_id),
    CONSTRAINT uq_supplier_name UNIQUE (name)
) ENGINE = InnoDB;

CREATE TABLE purchase (
    purchase_id     INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    purchase_no     VARCHAR(20)    NOT NULL,           -- e.g. PO-2026-000001
    supplier_id     INT UNSIGNED   NOT NULL,
    purchase_date   DATE           NOT NULL,
    total_amount    DECIMAL(14, 2) NOT NULL DEFAULT 0,
    status          ENUM('RECEIVED', 'CANCELLED') NOT NULL DEFAULT 'RECEIVED',
    note            VARCHAR(255)   NULL,
    created_by      INT UNSIGNED   NOT NULL,
    created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_purchase PRIMARY KEY (purchase_id),
    CONSTRAINT uq_purchase_no UNIQUE (purchase_no),
    CONSTRAINT fk_purchase_supplier FOREIGN KEY (supplier_id) REFERENCES supplier (supplier_id),
    CONSTRAINT fk_purchase_user FOREIGN KEY (created_by) REFERENCES app_user (user_id),
    CONSTRAINT chk_purchase_total CHECK (total_amount >= 0)
) ENGINE = InnoDB;

CREATE TABLE purchase_item (
    purchase_item_id  INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    purchase_id       INT UNSIGNED   NOT NULL,
    product_id        INT UNSIGNED   NOT NULL,
    quantity          INT            NOT NULL,
    unit_cost         DECIMAL(12, 2) NOT NULL,
    line_total        DECIMAL(14, 2) GENERATED ALWAYS AS (quantity * unit_cost) STORED,
    CONSTRAINT pk_purchase_item PRIMARY KEY (purchase_item_id),
    CONSTRAINT uq_purchase_item UNIQUE (purchase_id, product_id),
    CONSTRAINT fk_purchase_item_purchase FOREIGN KEY (purchase_id) REFERENCES purchase (purchase_id) ON DELETE CASCADE,
    CONSTRAINT fk_purchase_item_product FOREIGN KEY (product_id) REFERENCES product (product_id),
    CONSTRAINT chk_purchase_item_qty CHECK (quantity > 0),
    CONSTRAINT chk_purchase_item_cost CHECK (unit_cost >= 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Part 7: sales and payments
-- ---------------------------------------------------------------------
CREATE TABLE sale (
    sale_id          INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    sale_no          VARCHAR(20)    NOT NULL,          -- e.g. SL-2026-000001
    customer_id      INT UNSIGNED   NOT NULL,
    sale_date        DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    subtotal         DECIMAL(14, 2) NOT NULL DEFAULT 0,
    discount_amount  DECIMAL(14, 2) NOT NULL DEFAULT 0,
    total_amount     DECIMAL(14, 2) NOT NULL DEFAULT 0,
    status           ENUM('COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'COMPLETED',
    created_by       INT UNSIGNED   NOT NULL,
    created_at       DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sale PRIMARY KEY (sale_id),
    CONSTRAINT uq_sale_no UNIQUE (sale_no),
    CONSTRAINT fk_sale_customer FOREIGN KEY (customer_id) REFERENCES customer (customer_id),
    CONSTRAINT fk_sale_user FOREIGN KEY (created_by) REFERENCES app_user (user_id),
    CONSTRAINT chk_sale_amounts CHECK (subtotal >= 0 AND discount_amount >= 0 AND discount_amount <= subtotal),
    CONSTRAINT chk_sale_total CHECK (total_amount = subtotal - discount_amount)
) ENGINE = InnoDB;

CREATE TABLE sale_item (
    sale_item_id  INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    sale_id       INT UNSIGNED   NOT NULL,
    product_id    INT UNSIGNED   NOT NULL,
    quantity      INT            NOT NULL,
    unit_price    DECIMAL(12, 2) NOT NULL,             -- price at time of sale
    line_total    DECIMAL(14, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    CONSTRAINT pk_sale_item PRIMARY KEY (sale_item_id),
    CONSTRAINT uq_sale_item UNIQUE (sale_id, product_id),
    CONSTRAINT fk_sale_item_sale FOREIGN KEY (sale_id) REFERENCES sale (sale_id) ON DELETE CASCADE,
    CONSTRAINT fk_sale_item_product FOREIGN KEY (product_id) REFERENCES product (product_id),
    CONSTRAINT chk_sale_item_qty CHECK (quantity > 0),
    CONSTRAINT chk_sale_item_price CHECK (unit_price >= 0)
) ENGINE = InnoDB;

CREATE TABLE payment (
    payment_id      INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    sale_id         INT UNSIGNED   NOT NULL,
    payment_method  ENUM('CASH', 'CARD', 'BANK_TRANSFER') NOT NULL,
    amount          DECIMAL(14, 2) NOT NULL,
    reference_no    VARCHAR(50)    NULL,              -- card slip / bank ref
    paid_at         DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_payment PRIMARY KEY (payment_id),
    CONSTRAINT fk_payment_sale FOREIGN KEY (sale_id) REFERENCES sale (sale_id),
    CONSTRAINT chk_payment_amount CHECK (amount > 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Part 8: invoices and documents
-- ---------------------------------------------------------------------
CREATE TABLE invoice_sequence (
    seq_year     SMALLINT UNSIGNED NOT NULL,
    last_number  INT UNSIGNED      NOT NULL DEFAULT 0,
    CONSTRAINT pk_invoice_sequence PRIMARY KEY (seq_year)
) ENGINE = InnoDB;

CREATE TABLE invoice (
    invoice_id    INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    invoice_no    VARCHAR(20)    NOT NULL,             -- e.g. INV-2026-000123
    sale_id       INT UNSIGNED   NOT NULL,
    issued_at     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount  DECIMAL(14, 2) NOT NULL,
    status        ENUM('ISSUED', 'VOID') NOT NULL DEFAULT 'ISSUED',
    CONSTRAINT pk_invoice PRIMARY KEY (invoice_id),
    CONSTRAINT uq_invoice_no UNIQUE (invoice_no),
    CONSTRAINT uq_invoice_sale UNIQUE (sale_id),          -- one invoice per sale
    CONSTRAINT fk_invoice_sale FOREIGN KEY (sale_id) REFERENCES sale (sale_id),
    CONSTRAINT chk_invoice_total CHECK (total_amount >= 0)
) ENGINE = InnoDB;

CREATE TABLE document (
    document_id      INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    document_type    ENUM('INVOICE', 'PURCHASE', 'OTHER') NOT NULL,
    invoice_id       INT UNSIGNED  NULL,
    purchase_id      INT UNSIGNED  NULL,
    customer_id      INT UNSIGNED  NULL,
    file_name        VARCHAR(150)  NOT NULL,
    file_path        VARCHAR(255)  NOT NULL,
    mime_type        VARCHAR(50)   NOT NULL DEFAULT 'application/pdf',
    file_size_bytes  INT UNSIGNED  NOT NULL,
    checksum_sha256  CHAR(64)      NOT NULL,
    uploaded_by      INT UNSIGNED  NULL,
    created_at       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_document PRIMARY KEY (document_id),
    CONSTRAINT uq_document_path UNIQUE (file_path),
    CONSTRAINT fk_document_invoice FOREIGN KEY (invoice_id) REFERENCES invoice (invoice_id),
    CONSTRAINT fk_document_purchase FOREIGN KEY (purchase_id) REFERENCES purchase (purchase_id),
    CONSTRAINT fk_document_customer FOREIGN KEY (customer_id) REFERENCES customer (customer_id),
    CONSTRAINT fk_document_user FOREIGN KEY (uploaded_by) REFERENCES app_user (user_id),
    CONSTRAINT chk_document_invoice_link CHECK (document_type <> 'INVOICE' OR invoice_id IS NOT NULL)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Part 9: reporting summary table (filled by a scheduled EVENT)
-- ---------------------------------------------------------------------
CREATE TABLE sales_daily_summary (
    summary_date  DATE           NOT NULL,
    product_id    INT UNSIGNED   NOT NULL,
    units_sold    INT            NOT NULL DEFAULT 0,
    revenue       DECIMAL(14, 2) NOT NULL DEFAULT 0,
    refreshed_at  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sales_daily_summary PRIMARY KEY (summary_date, product_id),
    CONSTRAINT fk_sales_daily_summary_product FOREIGN KEY (product_id) REFERENCES product (product_id)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Part 10: audit log (no FK on changed_by, so audit rows survive)
-- ---------------------------------------------------------------------
CREATE TABLE audit_log (
    audit_id    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    table_name  VARCHAR(50)     NOT NULL,
    action      ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    record_id   INT UNSIGNED    NOT NULL,
    old_values  JSON            NULL,
    new_values  JSON            NULL,
    changed_by  INT UNSIGNED    NULL,               -- from @app_user_id
    changed_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_audit_log PRIMARY KEY (audit_id)
) ENGINE = InnoDB;
