# Agent Steering — Backend (/apps/api)

## Stack
- Python 3.11+, FastAPI, Pydantic v2, SQLAlchemy 2.0, Alembic
- Package manager: **uv** (never use pip)
- AI Memory: Supermemory SDK

## Commands
- `uv run uvicorn app.main:app --reload` — start dev server
- `uv run alembic upgrade head` — apply all migrations
- `uv run alembic revision --autogenerate -m "msg"` — create migration
- `uv run python -m app.scripts.export_openapi` — regenerate OpenAPI spec

## Prefer Skills
Instead of running commands directly, use skills from `/skills/`:
- Schema changed → `bash skills/type-sync/run.sh`
- Model changed → `bash skills/db-migrate/run.sh "msg"`
- Need a package → `bash skills/dependency-add/run.sh py <package>`

## Project Structure
```
app/
├── main.py            → FastAPI app entry point + lifespan
├── core/
│   ├── config.py      → Pydantic Settings (.env)
│   ├── database.py    → SQLAlchemy engine + session + get_db dependency
│   └── logging.py     → StructuredLogger (never use print)
├── models/            → SQLAlchemy ORM models (import all in __init__.py)
├── schemas/           → Pydantic request/response schemas
├── api/routes/        → API route handlers (one file per domain)
├── services/          → Business logic (incl. memory.py for Supermemory)
└── scripts/           → CLI utilities (OpenAPI export)
```

## Rules
- Every endpoint must use Pydantic models for request and response.
- After changing any Pydantic schema, run the `type-sync` skill.
- Use the structured logger: `from app.core.logging import get_logger`
- Use dependency injection via `Depends(get_db)` for DB sessions.
- All config via `app.core.config.settings` (reads `.env` automatically).
- New ORM models must be imported in `app/models/__init__.py` for Alembic discovery.

## Memory Service
```python
from app.services.memory import MemoryService

svc = MemoryService()
svc.add("user prefers dark mode", tags=["user_42"])
results = svc.search("user preferences", tags=["user_42"])
```

## API Endpoints
| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| POST | `/memory/add` | Store a memory |
| POST | `/memory/search` | Search memories |
