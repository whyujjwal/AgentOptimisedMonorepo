#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

ACTION="${1:-help}"

function show_help() {
    cat << 'EOF'
=== Docker Skill ===

Manage the full monorepo stack (API + PostgreSQL) via Docker Compose.

Usage:
  bash skills/docker/run.sh up        # Build images and start all services
  bash skills/docker/run.sh down      # Stop and remove containers
  bash skills/docker/run.sh restart   # Restart all services
  bash skills/docker/run.sh logs      # Tail logs from all services
  bash skills/docker/run.sh ps        # Show running containers and health
  bash skills/docker/run.sh build     # Rebuild images without starting
  bash skills/docker/run.sh reset     # ⚠ Destroy all containers + volumes
  bash skills/docker/run.sh migrate   # Run Alembic migrations inside the API container
  bash skills/docker/run.sh shell     # Open a bash shell inside the API container

Environment:
  Copy .env.example → .env in the repo root to customise Postgres credentials.
EOF
}

function ensure_env() {
    if [[ ! -f ".env" ]]; then
        echo "  No .env found — copying from .env.example"
        cp .env.example .env
    fi
}

case "$ACTION" in
    up)
        echo "=== docker: Starting all services ==="
        ensure_env
        docker compose up --build -d
        echo ""
        echo "Services:"
        echo "  API      → http://localhost:8000"
        echo "  API docs → http://localhost:8000/docs"
        echo "  Postgres → localhost:5432"
        ;;

    down)
        echo "=== docker: Stopping all services ==="
        docker compose down
        ;;

    restart)
        echo "=== docker: Restarting all services ==="
        docker compose restart
        ;;

    logs)
        SERVICE="${2:-}"
        if [[ -n "$SERVICE" ]]; then
            docker compose logs -f "$SERVICE"
        else
            docker compose logs -f
        fi
        ;;

    ps)
        echo "=== docker: Container status ==="
        docker compose ps
        ;;

    build)
        echo "=== docker: Building images ==="
        docker compose build
        ;;

    reset)
        echo "=== docker: ⚠ Resetting all containers and volumes ==="
        read -r -p "This will DELETE all Postgres and ChromaDB data. Continue? [y/N] " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            docker compose down -v --remove-orphans
            echo "Done. All volumes removed."
        else
            echo "Aborted."
        fi
        ;;

    migrate)
        echo "=== docker: Running Alembic migrations ==="
        docker compose exec api alembic upgrade head
        ;;

    shell)
        echo "=== docker: Opening shell in API container ==="
        docker compose exec api bash
        ;;

    help|--help|-h)
        show_help
        ;;

    *)
        echo "Error: Unknown action '$ACTION'"
        echo ""
        show_help
        exit 1
        ;;
esac
