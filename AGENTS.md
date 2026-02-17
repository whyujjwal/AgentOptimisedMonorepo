# Agent Steering Document — AI-Native Monorepo

## Repository Layout

```
/apps/web/          → Next.js frontend (App Router, TypeScript, Tailwind CSS)
/apps/api/          → FastAPI backend (Python 3.11+, Pydantic, SQLAlchemy)
/packages/shared-types/ → Auto-generated TypeScript API types & Zod schemas
/packages/ui/       → Shared React component library
```

## Rules for AI Agents

### 1. Package Managers
- Use **pnpm** for all Node/TypeScript dependencies.
- Use **uv** for all Python dependencies.
- Never use npm, yarn, pip, or poetry in this repo.

### 2. Project Locations
- The frontend lives in `/apps/web` and uses Next.js App Router.
- The backend lives in `/apps/api` and uses FastAPI with Pydantic models.

### 3. Type Synchronization (Critical)
Any changes to FastAPI Pydantic models **require** the following:
1. Regenerate the OpenAPI schema: `cd apps/api && python -m app.scripts.export_openapi`
2. Update TypeScript interfaces: `cd packages/shared-types && pnpm generate`
3. Verify the frontend still compiles: `pnpm build --filter=web`

### 4. Build Orchestration
- Use `pnpm build` at the root to build all JS/TS packages via Turborepo.
- Use `pnpm dev` at the root to start all dev servers.
- Use `uv run` inside `/apps/api/` for Python commands.

### 5. Environment Variables
- Never commit `.env` files. Use `.env.example` as a template.
- Backend config lives in `/apps/api/app/core/config.py` using Pydantic Settings.
- Frontend env vars must be prefixed with `NEXT_PUBLIC_` if client-accessible.

### 6. Database Migrations
- Alembic manages all database migrations in `/apps/api/alembic/`.
- After modifying SQLAlchemy models, run: `cd apps/api && uv run alembic revision --autogenerate -m "description"`
- Always review auto-generated migrations before applying.

### 7. Code Style
- Python: follow existing patterns in `/apps/api/app/`. Use type hints everywhere.
- TypeScript: strict mode is enabled. No `any` types.
- All new API endpoints must have Pydantic request/response models.

### 8. Logging
- Use the structured logger from `app.core.logging` — never use `print()`.
- Log levels: DEBUG for dev tracing, INFO for business events, WARNING for recoverable issues, ERROR for failures.

### 9. AI Memory
- Supermemory SDK is integrated for long-term semantic memory.
- See `/apps/api/app/services/memory.py` for the memory service.
