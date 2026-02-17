# Agent Steering — Frontend (/apps/web)

## Stack
- Next.js (App Router) with TypeScript and Tailwind CSS
- Shared types from `@repo/shared-types`
- Shared UI components from `@repo/ui`

## Commands
- `pnpm dev` — start dev server
- `pnpm build` — production build
- `pnpm lint` — run ESLint

## Rules
- All pages go in `src/app/` using the App Router file conventions.
- Use server components by default; add `"use client"` only when necessary.
- API types come from `@repo/shared-types` — never define API response types locally.
- Use `@repo/ui` components before creating new ones.
- Environment variables visible to the browser must start with `NEXT_PUBLIC_`.
