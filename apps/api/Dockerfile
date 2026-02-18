# ─── Builder stage ────────────────────────────────────────────────────────────
FROM python:3.11-slim AS builder

# Install uv for fast dependency resolution
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

# Build context is repo root so uv.lock is available
COPY uv.lock pyproject.toml ./
COPY apps/api/ ./apps/api/

# Install all API deps — venv is created at /app/.venv (workspace root)
RUN uv sync --no-dev --all-packages

# ─── Runtime stage ────────────────────────────────────────────────────────────
FROM python:3.11-slim AS runtime

# curl for health check; psycopg2-binary bundles its own libpq so no libpq-dev needed
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the virtualenv from workspace root
COPY --from=builder /app/.venv /app/.venv

# Mirror the builder's path structure so editable install refs resolve
COPY apps/api/ ./apps/api/

# Make venv the active Python
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Work from the API subdir (matches uvicorn's import root)
WORKDIR /app/apps/api

# ChromaDB persists here; mount a volume at runtime
RUN mkdir -p .data/chromadb

EXPOSE 8000

CMD ["/app/.venv/bin/uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
