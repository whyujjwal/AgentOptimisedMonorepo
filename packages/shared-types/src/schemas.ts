import { z } from "zod";

/**
 * Zod schemas that mirror the FastAPI Pydantic models.
 * Keep these in sync with /apps/api/app/models.py.
 * Run `pnpm generate` to regenerate api-types.ts from the OpenAPI spec.
 */

export const HealthResponseSchema = z.object({
  status: z.string(),
});

export type HealthResponse = z.infer<typeof HealthResponseSchema>;
