# db-migrate

Creates and applies Alembic database migrations.

## When to use
After modifying any SQLAlchemy model in `apps/api/app/models/`.

## What it does
1. Auto-generates an Alembic migration by diffing current models against the DB
2. Applies the migration to bring the DB up to date

## Usage
```bash
bash skills/db-migrate/run.sh "add users table"
```

## Warning
Always review the generated migration file before deploying to production.
