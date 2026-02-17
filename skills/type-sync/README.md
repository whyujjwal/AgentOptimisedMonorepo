# type-sync

Keeps Pydantic backend schemas and TypeScript frontend types in sync.

## When to use
After modifying any file in `apps/api/app/schemas/`.

## What it does
1. Runs the OpenAPI export script to regenerate `openapi.json`
2. Runs `openapi-typescript` to regenerate `packages/shared-types/src/api-types.ts`
3. Builds the frontend to catch any type mismatches

## Usage
```bash
bash skills/type-sync/run.sh
```
