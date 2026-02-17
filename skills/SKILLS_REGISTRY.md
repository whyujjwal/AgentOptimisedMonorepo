# Skills Registry

This file is the **central index** of all available skills in this monorepo.
AI agents should read this file to discover what skills exist, what they do,
and when to use them. Each skill is a self-contained directory under `/skills/`.

---

## How Skills Work

Each skill directory contains:
- `manifest.json` — Machine-readable metadata (trigger conditions, commands, inputs/outputs)
- `README.md` — Human/agent-readable explanation of when and how to use the skill
- `run.sh` — Executable entry point (always run from repo root)

Agents should:
1. Read this registry to find relevant skills for their current task.
2. Read the skill's `manifest.json` to understand inputs, outputs, and commands.
3. Execute via `bash skills/<skill-name>/run.sh [args]` from the repo root.

---

## Available Skills

| Skill | Trigger | Description |
|-------|---------|-------------|
| `type-sync` | Pydantic model changed | Regenerates OpenAPI spec → TypeScript types → validates frontend build |
| `db-migrate` | SQLAlchemy model changed | Creates and applies Alembic migration |
| `openapi-gen` | Any schema change | Exports OpenAPI JSON from FastAPI app |
| `lint-fix` | Before commit / on demand | Runs linters and auto-fixes across the monorepo |
| `test-run` | After code changes | Runs test suites for affected packages |
| `dependency-add` | Need to add a package | Adds dependency using correct package manager (pnpm or uv) |

---

## Skill Trigger Rules

Agents MUST check these trigger conditions after making changes:

1. **Modified a file in `apps/api/app/schemas/`** → Run `type-sync`
2. **Modified a file in `apps/api/app/models/`** → Run `db-migrate`
3. **Modified any Python or TypeScript file** → Run `lint-fix`
4. **Finished a feature or fix** → Run `test-run`
5. **Need a new library** → Run `dependency-add` (never run npm/pip directly)
