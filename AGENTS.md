# Agent Steering Document — AI-Native Monorepo

## Repository Layout

```
/apps/web/              → Next.js frontend (App Router, TypeScript, Tailwind CSS)
/apps/api/              → FastAPI backend (Python 3.11+, Pydantic, SQLAlchemy)
/packages/shared-types/ → Auto-generated TypeScript API types & Zod schemas
/packages/ui/           → Shared React component library
/skills/                → Executable agent skills (read SKILLS_REGISTRY.md first)
```

## Rules for AI Agents

### 1. Skills System (Read First)
Before performing common operations, read `/skills/SKILLS_REGISTRY.md`.
Each skill has a `manifest.json` with trigger conditions and a `run.sh` entry point.
Execute skills via: `bash skills/<name>/run.sh [args]`

**Mandatory triggers:**
- Changed `apps/api/app/schemas/` → run `type-sync` skill
- Changed `apps/api/app/models/` → run `db-migrate` skill
- Completed a feature → run `checkpoint` skill
- Need a package → run `dependency-add` skill (never run npm/pip directly)

### 2. Package Managers
- Use **pnpm** for all Node/TypeScript dependencies.
- Use **uv** for all Python dependencies.
- Never use npm, yarn, pip, or poetry in this repo.

### 3. Project Locations
- The frontend lives in `/apps/web` and uses Next.js App Router.
- The backend lives in `/apps/api` and uses FastAPI with Pydantic models.

### 4. Type Synchronization (Critical)
Any changes to FastAPI Pydantic models **require** running the `type-sync` skill:
```bash
bash skills/type-sync/run.sh
```

### 5. Build Orchestration
- Use `pnpm build` at the root to build all JS/TS packages via Turborepo.
- Use `pnpm dev` at the root to start all dev servers.
- Use `uv run` inside `/apps/api/` for Python commands.

### 6. Environment Variables
- Never commit `.env` files. Use `.env.example` as a template.
- Backend config lives in `/apps/api/app/core/config.py` using Pydantic Settings.
- Frontend env vars must be prefixed with `NEXT_PUBLIC_` if client-accessible.

### 7. Database Migrations
Run the `db-migrate` skill after modifying SQLAlchemy models:
```bash
bash skills/db-migrate/run.sh "add users table"
```

### 8. Code Style
- Python: follow existing patterns in `/apps/api/app/`. Use type hints everywhere.
- TypeScript: strict mode is enabled. No `any` types.
- All new API endpoints must have Pydantic request/response models.

### 9. Logging
- Use the structured logger from `app.core.logging` — never use `print()`.
- Log levels: DEBUG for dev tracing, INFO for business events, WARNING for recoverable issues, ERROR for failures.
- Supports kwargs: `logger.info("event", user_id=42, action="login")`

### 10. AI Memory (Supermemory)
- Long-term semantic memory via Supermemory SDK.
- Service: `/apps/api/app/services/memory.py` → `MemoryService` class.
- API endpoints: `POST /memory/add`, `POST /memory/search`.
- Use `container_tags` to namespace memories per agent or user.

### 11. Context Versioning (Entire CLI)
- Entire captures agent reasoning at every git commit via hooks.
- Run `bash skills/checkpoint/run.sh "description"` at logical milestones.
- Browse past context: `entire log`

### 12. Multi-Agent Coordination
- Stay within your assigned zone (see CLAUDE.md for boundaries).
- Do not manually edit auto-generated files (`openapi.json`, `api-types.ts`).
- Use conventional commits scoped to zones: `feat(api): add user endpoint`.
