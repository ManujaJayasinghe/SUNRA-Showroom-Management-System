# SUNRA Showroom Management System

CS304.3 Advanced Database Management Systems, Group AE, NSBM Green University.

A web app for one SUNRA electric-bike showroom: sales, inventory, customers, digital invoices and reports.

| Layer | Tech |
|---|---|
| Frontend | React 19 + Vite (`/frontend`) |
| Backend | Java 21 + Spring Boot 3.5 (`/backend`) |
| Database | MySQL 8.4 in Docker, migrations by Flyway (`/database/migration`) |

Read **[CONTRIBUTING.md](CONTRIBUTING.md)** before you write any code. It says which files you own and how database changes work.

---

## 1. Install the tools (once)

| Tool | Mac | Windows |
|---|---|---|
| Docker Desktop | https://www.docker.com/products/docker-desktop/ (pick Apple Silicon or Intel) | Same link, Windows installer. Accept the WSL 2 prompt and restart. |
| Java 21 (JDK) | `brew install openjdk@21` | https://adoptium.net (Temurin 21, tick "Set JAVA_HOME") |
| Node.js 22 LTS | `brew install node@22` | https://nodejs.org (LTS installer) |
| Git | `brew install git` | https://git-scm.com |

Check everything:

```bash
docker --version
docker compose version
java -version     # 21.x
node -v           # v22.x (or v20.19+)
git --version
```

Open Docker Desktop once after installing and wait until it shows **Engine running**. It must be running whenever you work on the project.

## 2. Get the code

```bash
git clone https://github.com/<owner>/sunra-showroom.git
cd sunra-showroom
```

## 3. Start the database

```bash
docker compose up -d
```

The first run downloads MySQL (about 200 MB). Check that it's running:

```bash
docker ps
```

You should see `sunra-mysql` with status `Up ... (healthy)`. Then:

```bash
docker exec -it sunra-mysql mysql -usunra_app -psunra_pass -e "SELECT VERSION();"
```

This should print `8.4.x`.

| Setting | Value |
|---|---|
| Host / port | `localhost` / `3306` |
| Database | `sunra_db` |
| App user | `sunra_app` / `sunra_pass` |
| Root user | `root` / `root` |

You can connect MySQL Workbench or Cursor's database extension with these settings.

## 4. Start the backend

```bash
cd backend
./mvnw spring-boot:run          # Mac
mvnw.cmd spring-boot:run        # Windows
```

On first start Flyway creates all tables and loads the seed data. Look for this in the log:

```
Successfully applied N migrations to schema `sunra_db`
Started SunraShowroomApplication
```

Check http://localhost:8080/api/health. It should show `"status":"UP"` and the list of migrations.

## 5. Start the frontend

In a second terminal:

```bash
cd frontend
npm install        # first time, and whenever package.json changes
npm run dev
```

Open http://localhost:5173 and go to **System Status**. It should show status UP, database `sunra_db` and MySQL 8.4.

## Sample logins (seed data)

| Username | Password | Role |
|---|---|---|
| admin | Admin@123 | ADMIN |
| sales1 | Sales@123 | SALES |
| stock1 | Stock@123 | STOCK |

Login works once Part 2 is done.

## Daily commands

| Task | Command |
|---|---|
| Start the database | `docker compose up -d` |
| Stop the database (data is kept) | `docker compose stop` |
| See database logs | `docker logs sunra-mysql` |
| Open a MySQL shell | `docker exec -it sunra-mysql mysql -uroot -proot sunra_db` |
| Run a SQL file as root | `docker exec -i sunra-mysql mysql -uroot -proot sunra_db < database/scripts/<file>.sql` |
| **Reset the database** (deletes all data, migrations re-run on next backend start) | `docker compose down -v` then `docker compose up -d` |

## Troubleshooting

| Problem | Fix |
|---|---|
| `Cannot connect to the Docker daemon` | Open Docker Desktop and wait for "Engine running". |
| `port is already allocated` on 3306 | A local MySQL is running. Stop it (Mac: `brew services stop mysql`; Windows: stop the MySQL service), or change `"3306:3306"` to `"3307:3306"` in `docker-compose.yml` and start the backend with `DB_URL=jdbc:mysql://localhost:3307/sunra_db?serverTimezone=Asia/Colombo&useSSL=false&allowPublicKeyRetrieval=true`. |
| `Communications link failure` when the backend starts | The database isn't running. Run `docker compose up -d` and wait for `(healthy)`. |
| `Validate failed: Migrations have failed validation` / `checksum mismatch` | Someone edited a `V...` file that had already run. Never edit those (see CONTRIBUTING). To get going locally, reset the database. |
| `Schema-validation: missing table/column` | Your JPA entity doesn't match the schema. Fix the entity or add a migration. Don't change `ddl-auto`. |
| Frontend says "Backend not reachable" | The backend isn't running on port 8080. |
