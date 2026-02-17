# AI-Native Monorepo

A production-ready monorepo architected from the ground up for **human and AI agent collaboration**. It is not just a codebase — it is an environment where AI agents can autonomously read, reason, write code, remember context, and coordinate across services without stepping on each other.

---

## Table of Contents

- [Why This Exists](#why-this-exists)
- [Architecture at a Glance](#architecture-at-a-glance)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
  - [Option A — Docker (recommended)](#option-a--docker-recommended)
  - [Option B — Local dev without Docker](#option-b--local-dev-without-docker)
- [The Stack](#the-stack)
  - [Backend — FastAPI](#backend--fastapi)
  - [Frontend — Next.js](#frontend--nextjs)
  - [Shared Types Pipeline](#shared-types-pipeline)
  - [UI Library](#ui-library)
- [The Skills System](#the-skills-system)
  - [What Is a Skill?](#what-is-a-skill)
  - [Available Skills](#available-skills)
  - [When Agents Must Use Skills](#when-agents-must-use-skills)
- [Agent Memory — Local Vector Database](#agent-memory--local-vector-database)
  - [Why Agents Need Memory](#why-agents-need-memory)
  - [How It Works Under the Hood](#how-it-works-under-the-hood)
  - [Using Memory As a Developer](#using-memory-as-a-developer)
  - [Using Memory As an Agent](#using-memory-as-an-agent)
  - [Memory API Endpoints](#memory-api-endpoints)
- [Multi-Agent Coordination](#multi-agent-coordination)
  - [Zone Ownership](#zone-ownership)
  - [The Type Contract](#the-type-contract)
  - [Commit Conventions](#commit-conventions)
- [Context Versioning with Entire](#context-versioning-with-entire)
- [Docker](#docker)
  - [Services](#services)
  - [Docker Commands](#docker-commands)
  - [Connecting to Postgres](#connecting-to-postgres)
- [Backend Deep Dive](#backend-deep-dive)
  - [Configuration](#configuration)
  - [Structured Logging](#structured-logging)
  - [Database Layer](#database-layer)
  - [Adding an Endpoint](#adding-an-endpoint)
- [Frontend Deep Dive](#frontend-deep-dive)
- [Development Workflow](#development-workflow)
- [Environment Variables Reference](#environment-variables-reference)

---

## Why This Exists

Most monorepos are built for humans. This one is built for **both**.

When you give an AI agent access to a codebase, several things break immediately:
- The agent doesn't know *where* to put things
- The agent runs npm when it should run pnpm, pip when it should run uv
- After changing a backend schema, the frontend types silently go stale
- Two agents working in parallel clobber each other's changes
- The agent has no memory — every session starts from zero

This monorepo solves all of those problems explicitly:

| Problem | Solution |
|---------|---------|
| Where do things go? | `AGENTS.md` files in every zone, `CLAUDE.md` at the root |
| Wrong package manager | `dependency-add` skill enforces pnpm/uv |
| Stale types | `type-sync` skill is a mandatory trigger |
| Parallel agent conflicts | Zone ownership boundaries + file lock conventions |
| No memory between sessions | ChromaDB vector store via `memory` skill |
| Lost reasoning context | `checkpoint` skill + Entire CLI hooks |

---

## Architecture at a Glance

```
┌──────────────────────────────────────────────────────────────────────┐
│                        AI-Native Monorepo                            │
│                                                                      │
│  ┌─────────────────┐           ┌──────────────────────────────────┐  │
│  │   apps/web      │           │          apps/api                │  │
│  │                 │  HTTP/JSON│                                  │  │
│  │  Next.js 16     │◄─────────►│  FastAPI + Python 3.11           │  │
│  │  React 19       │           │  SQLAlchemy + Alembic            │  │
│  │  Tailwind 4     │           │  ChromaDB (vector memory)        │  │
│  │  App Router     │           │  Pydantic v2                     │  │
│  └────────┬────────┘           └──────────────┬───────────────────┘  │
│           │                                   │                      │
│           │ imports                           │ exports              │
│           ▼                                   ▼                      │
│  ┌────────────────────┐      ┌───────────────────────────────────┐   │
│  │ packages/ui        │      │  packages/shared-types            │   │
│  │                    │      │                                   │   │
│  │ React components   │      │  openapi.json (source of truth)   │   │
│  │ Shared across apps │      │  → TypeScript interfaces          │   │
│  └────────────────────┘      │  → Zod validation schemas         │   │
│                              └───────────────────────────────────┘   │
│                                                                      │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │  skills/  — Executable scripts for agents & humans            │   │
│  │                                                               │   │
│  │  type-sync  db-migrate  memory  checkpoint  dependency-add    │   │
│  │  openapi-gen  lint-fix  test-run                              │   │
│  └───────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Repository Structure

```
/
├── AGENTS.md                  # AI agent instructions (root level)
├── CLAUDE.md                  # Multi-agent coordination rules
├── README.md                  # This file
├── package.json               # Root workspace config
├── pnpm-workspace.yaml        # pnpm workspaces
├── turbo.json                 # Turborepo task pipeline
├── pyproject.toml             # Python workspace config
├── openapi.json               # Generated — do not edit manually
│
├── apps/
│   ├── api/                   # FastAPI backend
│   │   ├── AGENTS.md          # Backend agent instructions
│   │   ├── pyproject.toml     # Python dependencies (uv)
│   │   ├── alembic.ini        # Database migration config
│   │   ├── alembic/
│   │   │   └── versions/      # Migration files
│   │   └── app/
│   │       ├── main.py        # FastAPI app entry point
│   │       ├── api/routes/    # HTTP route handlers
│   │       ├── core/
│   │       │   ├── config.py  # Settings via Pydantic
│   │       │   ├── database.py# SQLAlchemy engine + session
│   │       │   └── logging.py # Structured logger
│   │       ├── models/        # SQLAlchemy ORM models
│   │       ├── schemas/       # Pydantic request/response schemas
│   │       ├── services/      # Business logic (incl. memory)
│   │       └── scripts/       # CLI utilities
│   │
│   └── web/                   # Next.js frontend
│       ├── AGENTS.md          # Frontend agent instructions
│       ├── package.json
│       └── src/app/           # App Router pages and layouts
│
├── packages/
│   ├── shared-types/          # Auto-generated TypeScript types
│   │   └── src/
│   │       ├── schemas.ts     # Zod schemas (manually maintained)
│   │       └── index.ts       # Re-exports everything
│   └── ui/                    # Shared React components
│       └── src/
│           ├── button.tsx
│           └── index.ts
│
└── skills/                    # Executable skill scripts
    ├── SKILLS_REGISTRY.md     # Master index of all skills
    ├── checkpoint/            # Versioned git snapshot
    ├── db-migrate/            # Alembic migration runner
    ├── dependency-add/        # Package installer (enforces pnpm/uv)
    ├── lint-fix/              # Linter + auto-fixer
    ├── memory/                # Agent save/recall memory
    ├── openapi-gen/           # OpenAPI spec exporter
    ├── test-run/              # Test suite runner
    └── type-sync/             # Pydantic → OpenAPI → TypeScript pipeline
```

---

## Getting Started

### Option A — Docker (recommended)

The fastest way to get a full working stack: FastAPI + PostgreSQL + ChromaDB, all containerised.

**Prerequisites:** [Docker Desktop](https://www.docker.com/products/docker-desktop/)

```bash
git clone https://github.com/whyujjwal/AgentOptimisedMonorepo.git
cd AgentOptimisedMonorepo

# Start everything
bash skills/docker/run.sh up

# Apply database migrations
bash skills/docker/run.sh migrate
```

That's it. Services available at:
- **API** → `http://localhost:8000`
- **Swagger UI** → `http://localhost:8000/docs`
- **PostgreSQL** → `localhost:5432` (user: `monorepo`, pass: `monorepo`, db: `monorepo`)

See the [Docker section](#docker) below for all available commands.

### Option B — Local dev without Docker

**Prerequisites:**

| Tool | Install |
|------|---------|
| Node 20+ | [nodejs.org](https://nodejs.org) |
| pnpm 10+ | `npm install -g pnpm` |
| Python 3.11+ | [python.org](https://python.org) |
| uv | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| Git | standard |

**1. Clone and install:**

```bash
git clone https://github.com/whyujjwal/AgentOptimisedMonorepo.git
cd AgentOptimisedMonorepo

# Install all JavaScript/TypeScript packages
pnpm install

# Install all Python packages
cd apps/api && uv sync && cd ../..
```

**2. Configure environment:**

```bash
cp apps/api/.env.example apps/api/.env
# Edit apps/api/.env — SQLite works out of the box, no Postgres config needed
```

**3. Start all dev servers:**

```bash
pnpm dev
```

This starts:
- **Frontend** at `http://localhost:3000`
- **Backend** at `http://localhost:8000`
- **API Docs** at `http://localhost:8000/docs`

**Or run backend only:**

```bash
cd apps/api && uv run uvicorn app.main:app --reload
```

---

## The Stack

### Backend — FastAPI

The backend is a **FastAPI** application using Python 3.11+.

**Key libraries:**
- `fastapi` — HTTP framework with automatic OpenAPI generation
- `pydantic v2` — Data validation and settings management
- `sqlalchemy 2.0` — ORM for relational data
- `alembic` — Database schema migrations
- `chromadb` — Local vector database for agent memory
- `uvicorn` — ASGI server

**Why FastAPI over Django/Flask?**
FastAPI automatically generates an OpenAPI spec from your Python type hints. This is the engine behind the entire type synchronization pipeline. Change a Pydantic model → the spec updates → TypeScript types update. Zero manual work.

### Frontend — Next.js

The frontend uses **Next.js 16** with the **App Router**.

**Key decisions:**
- **Server components by default** — only add `"use client"` when interactivity requires it. This keeps the bundle small and SSR fast.
- **`@repo/shared-types`** — Never write API response types manually. Import them from the shared package.
- **`@repo/ui`** — Look here before creating a new component.

### Shared Types Pipeline

This is the most important architectural feature. Here is how backend and frontend types stay in sync:

```
FastAPI Pydantic schemas
         │
         ▼
 openapi.json (generated)
         │
         ▼
 packages/shared-types
         │
         ▼
TypeScript interfaces + Zod schemas
         │
         ▼
 apps/web imports @repo/shared-types
```

**You never need to write TypeScript interfaces for API responses.** They are generated.

To trigger the full pipeline after a schema change:

```bash
bash skills/type-sync/run.sh
```

### UI Library

`packages/ui` is a shared React component library. Add components here when they are used by more than one app. Currently exports `<Button />`.

---

## The Skills System

### What Is a Skill?

A skill is a bash script that encodes a repeatable, multi-step operation into a single command. It is a shared playbook for both humans and AI agents.

Every skill lives in `skills/<name>/` and contains three files:

```
skills/my-skill/
├── manifest.json   # Machine-readable: name, trigger, inputs, risk level
├── README.md       # Human/agent-readable: when and why to use it
└── run.sh          # The actual executable, always run from repo root
```

Agents discover skills by reading `skills/SKILLS_REGISTRY.md` first. Skills replace the need to remember long command sequences.

### Available Skills

| Skill | Run Command | When to Use |
|-------|-------------|-------------|
| `type-sync` | `bash skills/type-sync/run.sh` | After changing any Pydantic schema |
| `db-migrate` | `bash skills/db-migrate/run.sh "message"` | After changing a SQLAlchemy model |
| `openapi-gen` | `bash skills/openapi-gen/run.sh` | To regenerate `openapi.json` alone |
| `docker` | `bash skills/docker/run.sh up\|down\|migrate` | Start/stop the full stack (API + Postgres) |
| `memory` | `bash skills/memory/run.sh save\|recall\|list` | Save or recall agent context |
| `checkpoint` | `bash skills/checkpoint/run.sh "message"` | At logical milestones (commits) |
| `dependency-add` | `bash skills/dependency-add/run.sh js\|py <pkg>` | Adding any new package |
| `lint-fix` | `bash skills/lint-fix/run.sh` | Before committing |
| `test-run` | `bash skills/test-run/run.sh` | After completing work |

### When Agents Must Use Skills

These triggers are **mandatory**, not optional:

```
Changed apps/api/app/schemas/**   →  bash skills/type-sync/run.sh
Changed apps/api/app/models/**    →  bash skills/db-migrate/run.sh "reason"
Need a new package                →  bash skills/dependency-add/run.sh <lang> <pkg>
Need the local stack running      →  bash skills/docker/run.sh up
Feature complete                  →  bash skills/checkpoint/run.sh "description"
Want to remember something        →  bash skills/memory/run.sh save "content"
```

---

## Agent Memory — Local Vector Database

### Why Agents Need Memory

An AI agent without memory is goldfish-like — every session, it starts from zero. It re-asks questions it has already answered, forgets user preferences it learned last week, re-investigates bugs it already traced.

Memory changes this. An agent can:
- Record a decision: *"We decided to use UUIDs for all primary keys"*
- Record a user preference: *"User always wants dark mode defaults"*
- Record a debugging discovery: *"The auth bug was caused by a missing await on the token refresh"*
- ...and recall any of this semantically in a future session

### How It Works Under the Hood

Memory uses **ChromaDB**, a local vector database that runs entirely in the repo directory. No external API. No account needed. No data leaves your machine.

When you save a memory:
1. ChromaDB **embeds** your text into a high-dimensional vector using a local embedding model
2. It stores the vector alongside the original text and any metadata in `.data/chromadb/`
3. The data persists on disk across sessions

When you search:
1. Your query gets embedded into the same vector space
2. ChromaDB finds the **nearest vectors** using cosine similarity
3. Returns results sorted by relevance score (0.0–1.0)

This is **semantic search** — not keyword matching. You can search for *"user UI preferences"* and find a memory that says *"the product owner wants a minimal, light interface"*, even though none of those words overlap.

```
┌─────────────────────────────────────────────────────────────────┐
│                    ChromaDB Vector Store                         │
│                                                                  │
│  Memory: "User prefers dark mode"                               │
│  Vector: [0.23, -0.87, 0.41, 0.12, ...]  (768 dimensions)      │
│  Tags:   ["user_42", "preferences"]                             │
│  Time:   2026-02-18T10:30:00                                    │
│                                                                  │
│  Memory: "Auth bug caused by missing await on token refresh"    │
│  Vector: [0.11, 0.34, -0.62, 0.88, ...]                        │
│  Tags:   ["bugs", "auth"]                                       │
│                                                                  │
│  Search: "why did auth break?"                                  │
│  → cosine similarity against all vectors                        │
│  → returns [auth bug memory, score: 0.92]                       │
└─────────────────────────────────────────────────────────────────┘
```

### Using Memory As a Developer

The memory service is importable directly in Python:

```python
from app.services.memory import MemoryService

svc = MemoryService()

# Save something
svc.add(
    "We use UUIDs for all primary keys across the API",
    tags=["architecture", "decisions"],
    metadata={"decided_by": "team", "date": "2026-02-18"},
)

# Recall semantically
results = svc.search("what type of IDs do we use?")
for r in results:
    print(f"[{r['score']:.0%}] {r['content']}")

# List by tag
user_prefs = svc.list_memories(tags=["user_42"])

# Delete
svc.delete(memory_id="abc-123")
```

### Using Memory As an Agent

Agents interact via the `memory` skill from anywhere in the repo:

```bash
# Save a memory (with optional comma-separated tags)
bash skills/memory/run.sh save "The user wants pagination on all list endpoints" "api,ux"

# Recall memories semantically
bash skills/memory/run.sh recall "what did we decide about lists?"

# List all memories tagged with a specific tag
bash skills/memory/run.sh list "api"
```

**Example output from `recall`:**

```
=== Recalling memories ===
Found 2 memories:

[94% match] The user wants pagination on all list endpoints
  ID: 7f3c1a2b | Tags: api,ux

[71% match] List endpoints should return total count alongside results
  ID: 9e2b8d4f | Tags: api
```

### Memory API Endpoints

The memory system is also exposed over HTTP for any service or tool to use:

```
POST /memory/add
Body: { "content": "string", "tags": ["string"], "metadata": {} }

POST /memory/search
Body: { "query": "string", "tags": ["string"], "limit": 10 }
```

---

## Multi-Agent Coordination

Multiple AI agents can work in this repo simultaneously. Without rules, they conflict. Here is the system:

### Zone Ownership

Each agent is assigned a zone. Within a zone, an agent operates freely. Crossing zones requires care.

| Zone | Path | What lives here |
|------|------|-----------------|
| Backend | `apps/api/` | FastAPI, Pydantic, SQLAlchemy, migrations |
| Frontend | `apps/web/` | Next.js pages, components, hooks |
| Shared Types | `packages/shared-types/` | Auto-generated — owned by `type-sync` |
| UI Library | `packages/ui/` | Shared React components |
| Skills | `skills/` | Skill scripts |

### The Type Contract

`openapi.json` and `packages/shared-types/src/api-types.ts` are **auto-generated files**. Do not edit them manually. They are owned by the `type-sync` skill.

The contract is simple:
- Backend agent changes a Pydantic schema → runs `type-sync`
- `type-sync` regenerates `openapi.json` and `api-types.ts`
- Frontend agent imports from `@repo/shared-types` — types are always up to date

### Commit Conventions

Use [Conventional Commits](https://www.conventionalcommits.org/) scoped to zones:

```
feat(api): add user authentication endpoint
fix(web): correct pagination on search results
chore(deps): bump fastapi to 0.116.0
docs(skills): update memory skill README
refactor(api): extract email validation to service layer
checkpoint: auth feature complete
```

---

## Context Versioning with Entire

[Entire](https://entire.dev) is a CLI that hooks into git and snapshots an AI agent's reasoning alongside every commit. This means you can look back at *why* a change was made, not just *what* changed.

The `checkpoint` skill wraps this:

```bash
# Creates a git commit + Entire context snapshot
bash skills/checkpoint/run.sh "finished user auth"
```

**Browse history:**
```bash
entire log              # List all checkpoints
entire diff <id>        # See what changed between checkpoints
```

---

## Backend Deep Dive

### Configuration

All configuration lives in `app/core/config.py` using **Pydantic Settings**. It reads from environment variables and `.env` files automatically.

```python
from app.core.config import settings

print(settings.DATABASE_URL)
print(settings.MEMORY_DB_PATH)
print(settings.DEBUG)
```

Never hardcode config values. Never use `os.environ.get()` directly. Always go through `settings`.

### Structured Logging

The logging system produces human-readable colored output in development and machine-parseable JSON in production.

```python
from app.core.logging import get_logger

logger = get_logger(__name__)

# Basic
logger.info("user signed up")

# With structured fields (show up as JSON keys in production)
logger.info("payment processed", user_id=42, amount_cents=1999, currency="USD")

# Warnings and errors
logger.warning("rate limit approaching", requests_remaining=5)
logger.error("payment failed", order_id="abc", exc_info=True)
```

**Never use `print()`**. It bypasses log levels and structured output.

Switch to JSON output in production by setting `LOG_JSON=true`.

### Database Layer

SQLAlchemy 2.0 with synchronous sessions (async can be added if needed).

**Defining a model:**

```python
# apps/api/app/models/user.py
from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base

class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True)
    name: Mapped[str] = mapped_column(String(100))
```

**Import it** in `app/models/__init__.py` so Alembic can discover it:

```python
from app.models.user import User  # noqa: F401
```

**Create the migration:**

```bash
bash skills/db-migrate/run.sh "add users table"
```

**Using the DB in routes:**

```python
from sqlalchemy.orm import Session
from fastapi import Depends
from app.core.database import get_db

@router.get("/users")
def list_users(db: Session = Depends(get_db)):
    return db.query(User).all()
```

### Adding an Endpoint

Here is the full workflow for a new endpoint:

**1. Define the Pydantic schemas** in `app/schemas/`:

```python
# app/schemas/user.py
from pydantic import BaseModel, EmailStr

class UserCreateRequest(BaseModel):
    email: str
    name: str

class UserResponse(BaseModel):
    id: int
    email: str
    name: str
```

**2. Add them to** `app/schemas/__init__.py`:

```python
from app.schemas.user import UserCreateRequest, UserResponse
__all__ = [..., "UserCreateRequest", "UserResponse"]
```

**3. Write the route** in `app/api/routes/users.py`:

```python
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.logging import get_logger
from app.schemas.user import UserCreateRequest, UserResponse
from app.models.user import User

logger = get_logger(__name__)
router = APIRouter(prefix="/users")

@router.post("/", response_model=UserResponse)
def create_user(req: UserCreateRequest, db: Session = Depends(get_db)):
    user = User(email=req.email, name=req.name)
    db.add(user)
    db.commit()
    logger.info("user created", email=req.email)
    return user
```

**4. Register the router** in `app/api/routes/__init__.py`:

```python
from app.api.routes import health, memory, users

api_router.include_router(users.router, tags=["users"])
```

**5. Sync the types:**

```bash
bash skills/type-sync/run.sh
```

Done. The frontend now has TypeScript types for `UserCreateRequest` and `UserResponse`.

---

## Frontend Deep Dive

The frontend follows Next.js 15+ App Router conventions.

**Use types from shared package:**

```typescript
import type { HealthResponse } from "@repo/shared-types";

async function fetchHealth(): Promise<HealthResponse> {
  const res = await fetch("http://localhost:8000/health");
  return res.json();
}
```

**Use components from UI library:**

```typescript
import { Button } from "@repo/ui";

export default function Page() {
  return <Button variant="primary">Click me</Button>;
}
```

**Pages go in** `src/app/` following App Router conventions:

```
src/app/
├── layout.tsx          # Root layout (html, body, providers)
├── page.tsx            # Home page (/)
├── users/
│   ├── page.tsx        # /users
│   └── [id]/page.tsx   # /users/:id
```

---

## Development Workflow

### Daily workflow for a feature

```bash
# 1. Start dev servers
pnpm dev

# 2. Make changes to backend schema
# edit apps/api/app/schemas/user.py

# 3. Sync types to frontend automatically
bash skills/type-sync/run.sh

# 4. Add a new package if needed
bash skills/dependency-add/run.sh py httpx
bash skills/dependency-add/run.sh js zod web

# 5. Save important decisions to agent memory
bash skills/memory/run.sh save "User endpoints use cursor-based pagination" "api,decisions"

# 6. Fix linting
bash skills/lint-fix/run.sh

# 7. Run tests
bash skills/test-run/run.sh

# 8. Commit and checkpoint
bash skills/checkpoint/run.sh "add user endpoints with pagination"
```

### Adding a migration

```bash
# After modifying any file in apps/api/app/models/
bash skills/db-migrate/run.sh "add email_verified column to users"
```

### Recalling past decisions

```bash
bash skills/memory/run.sh recall "pagination approach"
bash skills/memory/run.sh recall "why we use UUIDs"
bash skills/memory/run.sh list "decisions"
```

---

## Docker

The monorepo ships with a production-ready Docker setup. One command starts the entire stack.

### Services

| Service | Image | Port | Volume |
|---------|-------|------|--------|
| `api` | Built from `apps/api/Dockerfile` | 8000 | `chromadb_data:/app/.data/chromadb` |
| `postgres` | `postgres:16-alpine` | 5432 | `postgres_data:/var/lib/postgresql/data` |

Both services have health checks. The API waits for Postgres to be healthy before starting.

### Docker Commands

```bash
# Start everything (builds images if needed)
bash skills/docker/run.sh up

# Run Alembic migrations inside the API container
bash skills/docker/run.sh migrate

# Tail all logs
bash skills/docker/run.sh logs

# Tail logs for one service
bash skills/docker/run.sh logs api
bash skills/docker/run.sh logs postgres

# Stop containers (data volumes preserved)
bash skills/docker/run.sh down

# Rebuild images without starting
bash skills/docker/run.sh build

# Open an interactive shell inside the API container
bash skills/docker/run.sh shell

# ⚠ Destroy everything including volumes (all data gone)
bash skills/docker/run.sh reset
```

### Connecting to Postgres

**Via Docker:**
```bash
docker compose exec postgres psql -U monorepo -d monorepo
```

**From a local client (port 5432 is exposed):**
```
postgresql://monorepo:monorepo@localhost:5432/monorepo
```

To use a different database name or credentials, copy `.env.example` → `.env` and edit:
```bash
cp .env.example .env
# Then edit POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB
```

---

## Environment Variables Reference

**`apps/api/.env`** — for running the backend locally (copy from `apps/api/.env.example`):

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_NAME` | `AI-Native Monorepo API` | Displayed in API docs |
| `APP_VERSION` | `0.1.0` | Displayed in API docs |
| `DEBUG` | `false` | Enables SQLAlchemy query logging |
| `DATABASE_URL` | `sqlite:///./dev.db` | SQLAlchemy connection string |
| `MEMORY_DB_PATH` | `.data/chromadb` | Path for ChromaDB vector store |
| `LOG_LEVEL` | `INFO` | Logging threshold (DEBUG/INFO/WARNING/ERROR) |
| `LOG_JSON` | `false` | Set `true` in production for JSON log output |

**`.env`** — for Docker Compose (copy from `.env.example` at the repo root):

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_USER` | `monorepo` | Postgres username |
| `POSTGRES_PASSWORD` | `monorepo` | Postgres password |
| `POSTGRES_DB` | `monorepo` | Postgres database name |
| `LOG_LEVEL` | `INFO` | API log level inside Docker |
| `DEBUG` | `false` | API debug mode inside Docker |

For production `DATABASE_URL`:
```
DATABASE_URL=postgresql+psycopg2://user:pass@host:5432/dbname
```
