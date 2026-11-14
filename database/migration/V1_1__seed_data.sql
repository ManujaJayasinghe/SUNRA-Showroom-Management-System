-- =====================================================================
-- Seed data (Part 1). SAMPLE DATA ONLY - replace product details with
-- the real showroom catalogue after the showroom visit.
-- Default logins (change before any demo to real users):
--   admin / Admin@123   sales1 / Sales@123   stock1 / Stock@123
-- =====================================================================

INSERT INTO role (role_id, role_name, description) VALUES
    (1, 'ADMIN',           'Manages users and views reports'),
    (2, 'SALES_ASSISTANT', 'Manages customers and sales'),
    (3, 'STOCK_MANAGER',   'Manages products and inventory');

INSERT INTO app_user (user_id, role_id, username, password_hash, full_name, email, phone) VALUES
    (1, 1, 'admin',  '$2a$10$nt1p1HY1jz4UrnLaEK4bR..ozKX4NFTWbKwfOE13pMuMl/5BRKP6a', 'System Administrator', 'admin@sunra-showroom.local', '0771234567'),
    (2, 2, 'sales1', '$2a$10$q7oadz2zKEIYhr07xfF3tuPaGDdhg2xvGHJflfgPiBH6/fCHTQHsW', 'Sample Sales Assistant', 'sales1@sunra-showroom.local', '0772345678'),
    (3, 3, 'stock1', '$2a$10$ylmV5T0z9jIDW6zzeq00duLFu1ie5kT6fmPb1s3D1yMf8Nn8dy1aa', 'Sample Stock Manager', 'stock1@sunra-showroom.local', '0773456789');

INSERT INTO product_category (category_id, name, description) VALUES
    (1, 'Electric Scooter',    'Step-through electric scooters'),
    (2, 'Electric Motorcycle', 'Higher-power electric motorcycles'),
    (3, 'Electric Bicycle',    'Pedal-assist electric bicycles');

INSERT INTO product (product_id, category_id, model_code, name, description, colour, motor_power_w, battery_type, battery_capacity, range_km, max_speed_kmh, unit_price, warranty_months) VALUES
    (1, 1, 'SMP-SC-01', 'Sample Scooter City',    'Sample entry-level city scooter',   'White', 1200, 'Lithium-ion', '60V 26Ah', 70,  45, 485000.00, 12),
    (2, 1, 'SMP-SC-02', 'Sample Scooter Plus',    'Sample scooter with larger battery', 'Black', 1500, 'Lithium-ion', '72V 32Ah', 90,  55, 595000.00, 12),
    (3, 2, 'SMP-MC-01', 'Sample Motorcycle Pro',  'Sample high-power motorcycle',      'Red',   3000, 'Lithium-ion', '72V 50Ah', 120, 80, 895000.00, 24),
    (4, 3, 'SMP-EB-01', 'Sample E-Bicycle Lite',  'Sample pedal-assist bicycle',       'Blue',  350,  'Lithium-ion', '48V 12Ah', 50,  25, 165000.00, 12);

INSERT INTO inventory (product_id, quantity_on_hand, reorder_level) VALUES
    (1, 8, 2),
    (2, 5, 2),
    (3, 3, 1),
    (4, 10, 3);

INSERT INTO stock_movement (product_id, movement_type, quantity_change, quantity_after, note, created_by) VALUES
    (1, 'INITIAL', 8,  8,  'Opening stock', 1),
    (2, 'INITIAL', 5,  5,  'Opening stock', 1),
    (3, 'INITIAL', 3,  3,  'Opening stock', 1),
    (4, 'INITIAL', 10, 10, 'Opening stock', 1);

INSERT INTO supplier (supplier_id, name, contact_person, phone, email, address) VALUES
    (1, 'Sample Main Distributor', 'Sample Contact', '0112345678', 'orders@sample-distributor.local', 'Colombo');

-- Sample customers (fake NICs in valid format)
INSERT INTO customer (customer_id, nic, first_name, last_name, phone, email, address, city) VALUES
    (1, '199512345678', 'Kasun',   'Perera',      '0711111111', 'kasun@example.com',   '12 Temple Road',    'Homagama'),
    (2, '987654321V',   'Nimali',  'Fernando',    '0722222222', 'nimali@example.com',  '45 Lake Drive',     'Kottawa'),
    (3, '200034567890', 'Tharindu','Silva',       '0753333333', NULL,                  '7 Station Lane',    'Maharagama');

INSERT INTO invoice_sequence (seq_year, last_number) VALUES (2026, 0);
