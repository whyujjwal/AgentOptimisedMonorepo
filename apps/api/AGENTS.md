# Agent Steering — Backend (/apps/api)

## Stack
- Python 3.11+, FastAPI, Pydantic v2, SQLAlchemy 2.0, Alembic
- Package manager: **uv** (never use pip)

## Commands
- `uv run uvicorn app.main:app --reload` — start dev server
- `uv run alembic upgrade head` — apply all migrations
- `uv run alembic revision --autogenerate -m "msg"` — create migration
- `uv run python -m app.scripts.export_openapi` — regenerate OpenAPI spec

## Project Structure
```
app/
├── main.py            → FastAPI app entry point
├── models/            → SQLAlchemy ORM models
├── schemas/           → Pydantic request/response schemas
├── api/routes/        → API route handlers
├── core/              → Config, logging, database setup
├── services/          → Business logic layer
└── scripts/           → CLI utilities (e.g., OpenAPI export)
```

## Rules
- Every endpoint must use Pydantic models for request and response.
- After changing any Pydantic schema, regenerate the OpenAPI spec and update shared-types.
- Use the structured logger from `app.core.logging` — never use `print()`.
- Use dependency injection via FastAPI's `Depends()` for DB sessions and services.
- All config comes from `app.core.config.Settings` (Pydantic Settings with env vars).
