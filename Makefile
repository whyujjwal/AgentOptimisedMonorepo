# ── AI-Native Monorepo — Local Dev Entrypoint ─────────────────────────────────
# Run `make help` to see all available targets.
#
# Package managers: pnpm (JS/TS), uv (Python) — never npm/pip directly.
# See CLAUDE.md for conventions and skills/SKILLS_REGISTRY.md for skill docs.

# GCP config — override per invocation: make deploy-api GCP_PROJECT=my-project
GCP_PROJECT  ?= $(shell gcloud config get-value project 2>/dev/null || echo "")
GCP_REGION   ?= us-central1
GAR_LOCATION ?= us-central1
GAR_REPO     ?= monorepo
IMAGE_TAG    ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "dev")

UV      := /opt/homebrew/bin/uv
PNPM    := pnpm
TURBO   := $(PNPM) turbo

.DEFAULT_GOAL := help
.PHONY: help setup dev build test lint \
        docker-up docker-down docker-logs docker-ps docker-reset \
        migrate migrate-gen type-sync \
        deploy-api deploy-web \
        clean

# ── Help ───────────────────────────────────────────────────────────────────────
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\033[1mUsage:\033[0m make \033[36m<target>\033[0m\n\n\033[1mTargets:\033[0m\n"} \
	/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# ── Setup ──────────────────────────────────────────────────────────────────────
setup: ## First-time setup: copy .env files and install all dependencies
	@echo "==> Copying .env files (skipping existing)..."
	@[ -f .env ]              || cp .env.example .env
	@[ -f apps/api/.env ]     || cp apps/api/.env.example apps/api/.env
	@[ -f apps/web/.env.local ] || cp apps/web/.env.example apps/web/.env.local
	@echo "==> Installing JS dependencies..."
	$(PNPM) install
	@echo "==> Installing Python dependencies (including dev)..."
	cd apps/api && $(UV) sync --dev
	@echo ""
	@echo "✓ Setup complete. Edit .env files with your config before running \`make dev\`."

# ── Development ────────────────────────────────────────────────────────────────
dev: ## Start full local stack: Postgres+API via Docker, web via Next.js dev server
	@echo "==> Starting Docker stack (API + Postgres)..."
	bash skills/docker/run.sh up
	@echo "==> Starting web dev server..."
	$(TURBO) run dev --filter=web

build: ## Build all packages via Turborepo
	$(TURBO) run build

# ── Testing & Linting ──────────────────────────────────────────────────────────
test: ## Run all tests (Python pytest + JS build check)
	bash skills/test-run/run.sh

test-api: ## Run Python tests only
	cd apps/api && $(UV) run pytest -v

test-web: ## Run Next.js build check (smoke test until JS tests are added)
	NEXT_PUBLIC_API_URL=http://localhost:8000 $(TURBO) run build --filter=web

lint: ## Lint and auto-fix all code (Python ruff + JS eslint)
	bash skills/lint-fix/run.sh

lint-check: ## Lint check only, no auto-fix (used in CI)
	cd apps/api && $(UV) run ruff check app/
	cd apps/api && $(UV) run ruff format --check app/
	$(TURBO) run lint

type-check: ## Run TypeScript type-checking across all packages
	$(TURBO) run type-check

# ── Docker ─────────────────────────────────────────────────────────────────────
docker-up: ## Start Docker stack (API + Postgres)
	bash skills/docker/run.sh up

docker-down: ## Stop Docker stack
	bash skills/docker/run.sh down

docker-logs: ## Tail Docker logs (SERVICE=api|postgres to filter)
	bash skills/docker/run.sh logs $(SERVICE)

docker-ps: ## Show container status
	bash skills/docker/run.sh ps

docker-reset: ## Destroy all containers AND volumes — data loss!
	bash skills/docker/run.sh reset

# ── Database ───────────────────────────────────────────────────────────────────
migrate: ## Apply all pending Alembic migrations (local)
	cd apps/api && $(UV) run alembic upgrade head

migrate-gen: ## Generate a new migration (MSG="description" required)
	@[ -n "$(MSG)" ] || (echo "Error: MSG is required. Usage: make migrate-gen MSG=\"add users table\"" && exit 1)
	bash skills/db-migrate/run.sh "$(MSG)"

migrate-down: ## Roll back the last Alembic migration (local)
	cd apps/api && $(UV) run alembic downgrade -1

# ── Type Sync ──────────────────────────────────────────────────────────────────
type-sync: ## Regenerate TypeScript types from Pydantic schemas
	bash skills/type-sync/run.sh

# ── Deployment ─────────────────────────────────────────────────────────────────
deploy-api: ## Deploy API to Cloud Run (requires gcloud auth)
	GCP_PROJECT=$(GCP_PROJECT) GCP_REGION=$(GCP_REGION) \
	GAR_LOCATION=$(GAR_LOCATION) GAR_REPO=$(GAR_REPO) IMAGE_TAG=$(IMAGE_TAG) \
	bash skills/deploy/run.sh api

deploy-web: ## Deploy Web to Cloud Run (requires gcloud auth, API must be deployed)
	GCP_PROJECT=$(GCP_PROJECT) GCP_REGION=$(GCP_REGION) \
	GAR_LOCATION=$(GAR_LOCATION) GAR_REPO=$(GAR_REPO) IMAGE_TAG=$(IMAGE_TAG) \
	bash skills/deploy/run.sh web

deploy: ## Deploy both API and Web sequentially to Cloud Run
	GCP_PROJECT=$(GCP_PROJECT) GCP_REGION=$(GCP_REGION) \
	GAR_LOCATION=$(GAR_LOCATION) GAR_REPO=$(GAR_REPO) IMAGE_TAG=$(IMAGE_TAG) \
	bash skills/deploy/run.sh all

# ── Cleanup ────────────────────────────────────────────────────────────────────
clean: ## Remove build artifacts and caches
	$(TURBO) run clean --if-present || true
	find . -type d -name __pycache__ -not -path './.venv/*' -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.pyc" -not -path './.venv/*' -delete 2>/dev/null || true
	rm -rf apps/web/.next apps/web/out
	rm -rf packages/shared-types/dist packages/ui/dist
	@echo "✓ Clean complete."
