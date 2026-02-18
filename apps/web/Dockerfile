# syntax=docker/dockerfile:1
# Build context: repo root (required for pnpm workspace packages)

# ── Stage 1: Install dependencies ─────────────────────────────────────────────
FROM node:20-alpine AS deps
RUN corepack enable && corepack prepare pnpm@10.30.0 --activate
WORKDIR /app

# Copy workspace manifests first for better layer caching.
# pnpm needs the full workspace graph to resolve internal packages.
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/web/package.json                      ./apps/web/
COPY packages/shared-types/package.json         ./packages/shared-types/
COPY packages/ui/package.json                   ./packages/ui/

RUN pnpm install --frozen-lockfile

# ── Stage 2: Build ────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder
RUN corepack enable && corepack prepare pnpm@10.30.0 --activate
WORKDIR /app

# Copy installed node_modules from deps stage
COPY --from=deps /app/node_modules              ./node_modules
COPY --from=deps /app/apps/web/node_modules     ./apps/web/node_modules

# Copy full source (workspace packages + app code)
COPY . .

# NEXT_PUBLIC_* vars are baked into the JS bundle at build time — they must be
# passed as build args, not as Cloud Run env vars (which arrive too late).
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

RUN pnpm turbo run build --filter=web

# ── Stage 3: Production runtime ───────────────────────────────────────────────
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Run as non-root
RUN addgroup --system --gid 1001 nodejs \
 && adduser  --system --uid 1001 nextjs

# Next.js standalone output mirrors the monorepo directory structure.
# The server entrypoint ends up at apps/web/.next/standalone/apps/web/server.js
COPY --from=builder /app/apps/web/public                          ./apps/web/public
COPY --from=builder --chown=nextjs:nodejs \
     /app/apps/web/.next/standalone                               ./
COPY --from=builder --chown=nextjs:nodejs \
     /app/apps/web/.next/static                                   ./apps/web/.next/static

USER nextjs

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# server.js is at the monorepo-relative path inside standalone output
CMD ["node", "apps/web/server.js"]
