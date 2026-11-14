# TEAM RULES

1. Never edit V1_0__schema.sql, V1_1__seed_data.sql or any pushed V file. My table/column changes go in database/migration/V2_<n>__<desc>.sql.
2. Procedures, functions, views, triggers go in ONE repeatable file: database/migration/R__02_security.sql, using DROP ... IF EXISTS then CREATE.
3. Root-only scripts (MySQL users and GRANTs) go in database/scripts/ and are run by hand as root.
4. Only stored procedures change stock. Never UPDATE inventory directly. Sales/stock accounts get EXECUTE on sp_adjust_stock.
5. At the start of each write transaction the backend calls dbSessionContext.setAppUser(userId) so audit/stock triggers know the user.
6. Naming: tables snake_case singular (users table is app_user), procedures sp_, functions fn_, views v_, triggers trg_<table>_<timing>_<event>.
7. Git: work on branch part2/auth-security, small commits, never push to main.
8. Backend package: auth (and user). Frontend: src/modules/auth and src/modules/users.
9. Never commit real secrets. Use environment variables or placeholders.
10. Never invent table/procedure names. Verify against the repo. Use MySQL 8 syntax.
11. Run what can be run and report real results. Never claim something works without running it.

## Scope
My Part 2 scope: three MySQL accounts (app_admin, app_sales, app_stock) with least-privilege GRANTs (sales cannot touch purchase tables; stock cannot read customer details); EXECUTE on procedures instead of direct table UPDATE; restricted view v_user_public without the password hash; denial tests (GRANT/REVOKE and "access denied" errors); Spring Security with JWT and BCrypt and role checks; React login page, admin-only user management page, role-based menu hiding.
