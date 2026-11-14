-- =====================================================================
-- Part 2: Seed roles (ADMIN, SALES, STOCK) and demo users
-- Demo users: admin, sales1, stock1 with cost-10 BCrypt hashes.
-- Uses ON DUPLICATE KEY UPDATE to handle existing seed data safely.
-- =====================================================================

INSERT INTO role (role_name, description) VALUES
    ('ADMIN', 'Manages users and views reports'),
    ('SALES', 'Manages customers and sales'),
    ('STOCK', 'Manages products and inventory')
ON DUPLICATE KEY UPDATE
    description = VALUES(description);

INSERT INTO app_user (
    username,
    role_id,
    password_hash,
    full_name,
    email,
    phone,
    is_active,
    failed_attempts
)
SELECT
    'admin',
    role_id,
    '$2a$10$BLXb19x8jqR5G3cd6JJAA.JWzRyFASow8Bhfc4R3N45zBcNyJoom2',
    'System Administrator',
    'admin@sunra-showroom.local',
    '0771234567',
    TRUE,
    0
FROM role
WHERE role_name = 'ADMIN'
ON DUPLICATE KEY UPDATE
    role_id         = VALUES(role_id),
    password_hash   = VALUES(password_hash),
    full_name       = VALUES(full_name),
    email           = VALUES(email),
    phone           = VALUES(phone),
    is_active       = VALUES(is_active),
    failed_attempts = VALUES(failed_attempts);

INSERT INTO app_user (
    username,
    role_id,
    password_hash,
    full_name,
    email,
    phone,
    is_active,
    failed_attempts
)
SELECT
    'sales1',
    role_id,
    '$2a$10$hZ3OpORaeiUYWCm/gVHmZeMFuY8i/UfdCrUbaNKPAhkfi/TdqNrFS',
    'Sample Sales Assistant',
    'sales1@sunra-showroom.local',
    '0772345678',
    TRUE,
    0
FROM role
WHERE role_name = 'SALES'
ON DUPLICATE KEY UPDATE
    role_id         = VALUES(role_id),
    password_hash   = VALUES(password_hash),
    full_name       = VALUES(full_name),
    email           = VALUES(email),
    phone           = VALUES(phone),
    is_active       = VALUES(is_active),
    failed_attempts = VALUES(failed_attempts);

INSERT INTO app_user (
    username,
    role_id,
    password_hash,
    full_name,
    email,
    phone,
    is_active,
    failed_attempts
)
SELECT
    'stock1',
    role_id,
    '$2a$10$n/pydScyHLMrh7qMQTz/VOR9BLAm.JZyrxgUtkWFt8dPRSY.i6HGW',
    'Sample Stock Manager',
    'stock1@sunra-showroom.local',
    '0773456789',
    TRUE,
    0
FROM role
WHERE role_name = 'STOCK'
ON DUPLICATE KEY UPDATE
    role_id         = VALUES(role_id),
    password_hash   = VALUES(password_hash),
    full_name       = VALUES(full_name),
    email           = VALUES(email),
    phone           = VALUES(phone),
    is_active       = VALUES(is_active),
    failed_attempts = VALUES(failed_attempts);
