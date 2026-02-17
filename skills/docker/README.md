# docker

Manages the full local stack (FastAPI API + PostgreSQL) via Docker Compose.

## Services

| Service | Container | Port | Description |
|---------|-----------|------|-------------|
| `api` | `monorepo_api` | 8000 | FastAPI backend |
| `postgres` | `monorepo_postgres` | 5432 | PostgreSQL 16 |

ChromaDB is embedded inside the `api` container and persists in the `chromadb_data` volume.

## Quick start

```bash
# 1. Start everything
bash skills/docker/run.sh up

# API is now at http://localhost:8000
# Swagger UI at http://localhost:8000/docs
# Postgres at localhost:5432 (user: monorepo, pass: monorepo, db: monorepo)

# 2. Run migrations
bash skills/docker/run.sh migrate

# 3. Tail logs
bash skills/docker/run.sh logs

# 4. Stop
bash skills/docker/run.sh down
```

## All commands

```bash
bash skills/docker/run.sh up          # Build + start
bash skills/docker/run.sh down        # Stop (volumes preserved)
bash skills/docker/run.sh restart     # Restart services
bash skills/docker/run.sh logs        # All logs
bash skills/docker/run.sh logs api    # API logs only
bash skills/docker/run.sh logs postgres
bash skills/docker/run.sh ps          # Container health
bash skills/docker/run.sh build       # Rebuild images only
bash skills/docker/run.sh migrate     # Apply Alembic migrations
bash skills/docker/run.sh shell       # bash inside API container
bash skills/docker/run.sh reset       # ⚠ Nuke everything including volumes
```

## Connecting to Postgres directly

```bash
# psql via Docker
docker compose exec postgres psql -U monorepo -d monorepo

# From a local client (port is exposed)
psql postgresql://monorepo:monorepo@localhost:5432/monorepo
```

## Environment customisation

Copy `.env.example` → `.env` at the repo root:

```bash
cp .env.example .env
```

Override any value:

```dotenv
POSTGRES_USER=myuser
POSTGRES_PASSWORD=supersecret
POSTGRES_DB=mydb
```

## When to use

- `up` — start a fresh dev environment
- `migrate` — after pulling changes that include new Alembic migrations
- `reset` — when you want a completely clean slate (all data gone)
- `shell` — to debug inside the container, inspect files, run one-off scripts
